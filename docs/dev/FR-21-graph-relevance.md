# FR-21: Relevance-Filtered Document Graph

> The mini graph in the workspace left rail currently shows every
> work on the server with every edge type weighted equally. This
> makes the graph noisy and hard to use for navigation. This spec
> defines a scoring algorithm that surfaces the most relevant works
> relative to the currently open document, plus edge styling that
> makes the relationship type immediately readable.

## Decision Question

When a user opens a work in the workspace, what should the mini
graph in the left rail show?

- **Today:** Every work on the server, every edge type, force-directed
  layout. Result: a soup of mostly-grey nodes with no clear focal
  point.
- **Desired:** The current work at the center, surrounded by the
  10–20 most relevant other works, with edges colored by relationship
  type so the user can immediately see *why* each node is there.

The answer shapes whether the graph is a navigation tool (good) or
just a decorative visualization (current state).

## Decision

**Add a relevance-scoring pass to `work_graph`** that, given a
`current_work_id`, scores every other work and returns only the top N.
Add edge-type-aware rendering so the user can read the graph at a
glance.

Scoring is cheap (sub-100ms for typical servers, sub-second for
10,000+ works) and uses data we already compute. No new infrastructure.

## Scoring Algorithm

For each candidate work `W` (relative to current work `C`), compute
a score `S(W, C)` as the sum of these signals:

| Signal | Score | Source | Rationale |
|---|---|---|---|
| Transclusion link `C ↔ W` (either direction) | +5 | `RangeElement::Transclusion` in editions | Strongest possible relationship — actual content reuse |
| Typed link `C ↔ W` (Comment / Reference / Disagreement / Quotation / See Also / Web) | +3 | `HyperLink` storage | Explicit authorial connection |
| Cross-server transclusion ref | +4 | `CrossServerRef` storage | Strong connection, just remote |
| Shared author (≥ 25% of both works attributed to same identity) | +2 | `attribution_log` | Same voice/concern |
| High-weight similarity match (≥ 80%) | +2 | `backfollow` content fingerprints | Substantial content overlap |
| Medium-weight similarity (50–80%) | +1 | `backfollow` content fingerprints | Topic adjacent |
| Low-weight similarity (< 50%) | +0.5 | `backfollow` content fingerprints | Loose connection |
| Shared backlink (a third work links to both C and W) | +1 | backlinks index | Triadic closure — related via third party |
| Same collection | +1 | `WorkMeta.collection_path` (when shipped) | Curated relatedness |
| Same category (trail category, tag) | +0.5 | `TrailPayload.categories` | Topical grouping |
| Recent co-editing (same identity edited both in last 30 days) | +1 | `attribution_log` timestamps | Live collaboration signal |

A score of 0 means "no relationship found" — these nodes are excluded
unless `include_disconnected: true` is set.

### Top-N selection

Default `max_nodes = 15`. The algorithm returns:
1. The current work (always)
2. The top N-1 works by score, ties broken by recency

For servers with fewer than `max_nodes` total works, all are returned
(no filtering needed).

### Edge weighting for layout

The force-directed simulation uses edge weights to determine how
strongly two nodes attract. We map score contributions to weights:

| Edge type | Layout weight |
|---|---|
| Transclusion | 0.008 (strong attractor) |
| Cross-server transclusion | 0.007 |
| Typed link | 0.005 |
| Similarity (high) | 0.003 |
| Similarity (medium/low) | 0.001 |
| Shared author / shared backlink | 0.0008 (weak — these are contextual, not direct) |

This makes transclusion-linked works cluster tightly, similarity-linked
works sit at medium distance, and shared-author works float nearby
without dominating the layout.

## Edge Styling (Visual)

Each edge is colored by type so the user can read relationships
without hovering:

| Edge type | Stroke | Width | Dash |
|---|---|---|---|
| Transclusion | `#3b82f6` (blue) | 2.5px | solid |
| Cross-server transclusion | `#0ea5e9` (sky blue) | 2px | solid |
| Typed: Comment | `#58a6ff` (light blue) | 1.5px | solid |
| Typed: Disagreement | `#f85149` (red) | 1.5px | solid |
| Typed: Quotation | `#a371f7` (purple) | 1.5px | solid |
| Typed: Reference / See Also | `#3fb950` (green) | 1.5px | solid |
| Typed: Web | `#39d2c0` (teal) | 1.5px | solid |
| Similarity | `#94a3b8` (grey) | 1px | `4 4` dashed |
| Shared author (off-graph edge) | n/a — reflected in node fill, not drawn | | |
| Shared backlink (off-graph edge) | n/a — reflected in node position, not drawn | | |

Edges that affect scoring but aren't drawn (shared author, shared
backlink) still influence the layout via weight, but don't add visual
clutter.

## Node Sizing and Coloring

Nodes are sized by their **score relative to the current work**, not
by absolute connectivity:

| Score range | Radius | Fill |
|---|---|---|
| Current work | 16 | `#4361ee` (bright blue) with white document icon |
| Score ≥ 5 | 12 | `#3b82f6` (blue — primary connections) |
| Score 3–5 | 10 | `#10b981` (green — strong secondary) |
| Score 1–3 | 8 | `#6366f1` (indigo — moderate) |
| Score < 1 | 6 | `#cbd5e1` (light grey — weak) |
| Starred by user (any score) | +2 radius boost | amber ring around base color |
| Source work (any score) | +2 radius boost | `#f59e0b` (amber) base |

The current work's node also has a subtle pulsing animation so the
eye is drawn to it.

## API Changes

### Wire op extension

`work_graph` currently takes no parameters. Extend it to optionally
accept:

```json
{
  "current_work_id": 1101,         // optional BeId
  "max_nodes": 15,                 // optional, default = no limit
  "min_score": 1.0,                // optional, default 0
  "include_disconnected": false    // optional, default false
}
```

When `current_work_id` is absent, behavior is unchanged (full graph,
no scoring) for backward compatibility.

Response includes per-node score so the frontend can render without
recomputing:

```typescript
interface GraphNode {
  work_id: number;
  title: string;
  is_starred: boolean;
  is_source: boolean;
  revision_count: number;
  author_type?: string;
  score?: number;            // NEW — relevance to current_work_id
  shared_authors?: number;   // NEW — count of identities on both works
}

interface GraphEdge {
  source: number;
  target: number;
  edge_type: string;         // existing — but normalized values (see below)
  weight: number;
  relationship?: string;     // NEW — primary relationship type for styling
}
```

`edge_type` is normalized to one of:
- `"transclusion"`
- `"cross_server_transclusion"`
- `"link_comment"`, `"link_disagreement"`, `"link_quotation"`,
  `"link_reference"`, `"link_see_also"`, `"link_web"`
- `"similarity_high"`, `"similarity_medium"`, `"similarity_low"`
- `"shared_author"`
- `"shared_backlink"`

The frontend uses these to pick stroke color/width/dash.

### Endpoint parity

The HTTP API (`/api/public/graph`) mirrors the wire op for
cross-server consumption. Same parameters, same response shape.

## Implementation Phases

### Phase 1: Backend scoring + edge typing (1–2 days)

1. Extend `WireRequest::WorkGraph` with optional parameters
2. Implement scoring function in `server.rs`:
   ```rust
   fn score_work_pair(
       &self,
       current: BeId,
       candidate: BeId,
       edges: &[(GraphEdge, BeId, BeId)],
   ) -> ScoreBreakdown
   ```
3. Aggregate scores across all signals
4. Filter to top-N when `max_nodes` is set
5. Normalize `edge_type` values in response
6. Unit tests for scoring (each signal in isolation, combinations)

### Phase 2: Frontend rendering (half day)

1. Pass `current_work_id` and `max_nodes: 15` from embedded map
2. Use `score` field for node sizing/color
3. Use `edge_type` for stroke styling
4. Update legend with new color scheme
5. Add subtle pulse animation on current-work node

### Phase 3: Polish (half day)

1. Hover on a node shows its score breakdown ("why is this here?")
2. Click a node's edge type filter chip to hide/show that type
3. "Show all" toggle switches to unfiltered view
4. Performance: memoize layout per (current_work_id, max_nodes) combo

## Cost Analysis

**Per query:**

For a server with N works and E edges:

- Edge lookup: O(E) — we already have edges in memory
- Author overlap: O(A) per candidate, where A is attribution count
  per work — typically small (1–10 authors per work)
- Similarity lookup: O(1) per edge (already indexed)
- Backlink intersection: O(B_C + B_W) where B = backlink count —
  typically small
- Total: O(N × avg_signals_per_node) ≈ O(N × 10)

For N = 80: ~800 operations. Effectively free.
For N = 10,000: ~100,000 operations. Still sub-100ms.

**Memory:**

We hold the full graph in memory anyway for the current implementation.
No new persistent state. Score breakdown is computed per query and
discarded.

**Caching:**

Optional: cache the top-N results per current_work_id, invalidated on
any edit. Not needed for v1 (queries are cheap) but worth adding if
servers get large.

## Test Cases

These should be unit tests on the scoring function:

1. **Transclusion:** C and W share a transclusion link → score ≥ 5
2. **Typed link:** C and W have a Comment link → score ≥ 3
3. **Shared author 100%:** both works by same identity → +2
4. **Shared author 30%:** → +2 (above threshold)
5. **Shared author 10%:** → 0 (below threshold)
6. **Similarity 90%:** → +2
7. **Similarity 60%:** → +1
8. **Similarity 30%:** → +0.5
9. **Shared backlink:** third work Z links to both C and W → +1
10. **No relationship:** → score 0
11. **Combined:** transclusion + shared author → score = 7 (5 + 2)
12. **Top-N selection:** 100 works, scores 0–10, max_nodes=15 →
    returns top 15 by score
13. **Tie-breaking:** two works with same score, different recency →
    more recent wins
14. **Self:** score(C, C) is undefined (current work is always
    included by convention, not by scoring)

## Open Questions

1. **Score normalization.** Should scores be normalized to 0–100 for
   display? Or raw? **Recommendation: raw, but display as a
   tooltip on hover.**

2. **Historical decay.** Should old signals (e.g., shared edits from
   5 years ago) count less than recent ones? **Recommendation: no
   for v1. Simplicity wins. Revisit if the graph feels stale.**

3. **Adversarial signals.** Should disagreement links count as
   positive relevance (they're still a connection) or as a different
   signal? **Recommendation: positive — disagreement is a strong
   authorial relationship; the edge color tells the user it's
   adversarial.**

4. **Cross-server scoring.** If a candidate work is on another
   server, can we score it? **Recommendation: not in v1. Cross-server
   scoring requires fetching remote attribution data, which is
   expensive. Defer.**

5. **User-tunable weights.** Should the user be able to adjust the
   weights (e.g., "I care more about shared authors than similarity")?
   **Recommendation: no for v1. Sensible defaults beat configuration.**

6. **Clustering.** Should we run community detection (Louvain) to
   group related nodes visually? **Recommendation: no for v1. With
   only 15 nodes, manual positioning via force-directed layout is
   fine. Clustering adds complexity for marginal value.**

## Future Extensions

### Time-aware graph

Show only works edited in the last X days. Useful for "what's been
happening lately" view.

### Author-centric graph

Instead of work-centric, show an author-centric graph: current author
at center, connected to co-authors and works they've touched. Different
navigation paradigm.

### Collection-centric graph

For a work in a collection, show the collection's other works as the
primary cluster, with cross-collection connections as secondary.

### Trail-aware graph

Works that share stops in a published trail get a small score boost.
Helps users discover related works through curated paths.

### Federated graph

If cluster federation is enabled (FR-3), include works from peer
servers in the graph. Edges show as cross-server style. Requires
gossip protocol to share graph data — non-trivial.

## Alternatives Considered

### Alternative A: No filtering, show everything

Status quo.

- **Pro:** No new code
- **Con:** Graph is unusable for navigation at scale (>50 works)
- **Verdict:** Rejected — doesn't meet the navigation goal

### Alternative B: Filter by edge count only

Show works with the most connections to current work, ignoring
edge type and author overlap.

- **Pro:** Simplest possible scoring
- **Con:** Misses qualitative differences (transclusion vs similarity)
- **Verdict:** Rejected — too lossy

### Alternative C: Manual curation

Let the user mark "related works" manually. Show only those.

- **Pro:** Maximum signal quality
- **Con:** High user burden; defeats the point of automatic surfacing
- **Verdict:** Rejected as primary mechanism; could add as "pinned
   related works" later

### Alternative D: PageRank / eigenvector centrality

Compute global graph centrality, show most-central works.

- **Pro:** Standard graph algorithm, well-understood
- **Con:** Surfaces globally-important works, not works relevant to
  what the user is reading. Wrong problem.
- **Verdict:** Rejected for relevance scoring; could add as a
  "discover" mode later

## Ties to Other Designs

| Feature | Relationship |
|---|---|
| **FR-18 Workspace** | This is the workspace's left rail graph |
| **`cross-server-resolution.md`** | Cross-server transclusions get their own edge type |
| **`FR-20-trails.md`** | Future: trail co-occurrence could be a scoring signal |
| **`FR-19-marginalia.md`** | Future: review comments could surface as edge type |
| **Existing `work_graph` op** | Extended, not replaced |
| **`backfollow.rs`** | Source of similarity fingerprint data |
| **`attribution_log`** | Source of author-overlap data |

## Success Criteria

- Opening a work shows a graph of 10–20 meaningfully-related works,
  not 80 disconnected nodes.
- Each visible edge is colored by type; user can tell transclusion
  from similarity at a glance.
- Each visible node has a clear reason for being there (score > 0).
- Hovering shows the score breakdown.
- Performance: graph renders in under 100ms after work opens,
  even on a server with thousands of works.
- User can navigate to a related work in under 5 seconds (vs. the
  current "scroll the library list" pattern).

## Metrics

- Graph renders within 100ms of work open (target: 95th percentile)
- Average nodes shown per open: 12–18 (sweet spot — not too sparse,
  not too dense)
- Click-through rate from graph node to work open (target: > 10% of
  sessions)
- Score distribution (are most nodes 1–3, or 5+? Tuning signal)

## References

- `src/server/server.rs::work_graph` — current implementation
- `src/edition/backfollow.rs` — content fingerprint source
- `src/server/attribution_log.rs` — author attribution source
- `web/app/src/components/DocumentMapPanel.tsx` — frontend rendering
- `web/app/src/api/crdt_sync.ts::workGraph()` — client API
- Maggie Appleton's pattern library — graph-of-ideas visual patterns
