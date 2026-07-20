# FR-22: Work Categorization, Concept Works, and LLM Tagging

> Adds the missing "type" dimension to Xudanu works (Document,
> Fragment, Person, Concept, Collection, Commentary), introduces
> concept-works as first-class addressable entities (Ted Nelson's
> vision), and uses the existing Ollama runtime to auto-categorize
> works on first save. Visual: larger graph nodes with type icons;
> "Related concepts" panel under the mini graph.

## Decision Question

How does Xudanu represent the *type* of a work, surface *concepts*
as first-class addressable entities, and let authors find what's
related — without turning into a flat tag cloud?

The answer shapes:
- Whether the graph can show meaningful icons per node
- Whether concepts are tags (cheap, flat) or works (rich, addressable)
- Whether authors have to categorize manually or get AI assistance
- How "Related concepts" in the workspace left rail gets populated

## Decision

**Three connected pieces:**

1. **`WorkKind` field** on every work: Document, Fragment, Person, Concept, Collection, Commentary (the 6 from the original design). Defaults to Document; authors can change.

2. **Concept-as-work pattern.** When you tag a work "hypertext," the server checks for a Concept work named "Hypertext." If it exists, create a typed link to it. If not, create the Concept work first, then link. Tags become addressable.

3. **LLM auto-categorization via existing Ollama runtime.** Trigger once on first save. Manual "Re-categorize" button for later. Cached by content hash. Author approves suggestions before they're applied.

## Background: What We Have Today

### Work metadata

Currently stored on each work:
- `work_id`, `owner`, `revision_count`, `title`, `read_club`, `edit_club`
- `is_starred`, `is_source`, `updated_at`
- `content_start_line`, `content_end_line`, `source_author_id`, `source_edition_info`

**Missing:** any field for "kind" or "type." Everything is implicitly a "Document."

### Ollama runtime (already integrated)

`src/server/ollama.rs` provides:
- `LlmClient` with `narrate()`, `writing_feedback()`, `suggest_title()`
- `LlmUsageTracker` for accounting
- `llm_enabled()` check
- Configurable base URL and model
- Existing wire ops: `LLMFeatures` (status), `WorkNarrate`, `WorkWritingFeedback`

**Missing:** categorization prompt, concept extraction, related-concepts query.

### Graph rendering

Per FR-21, the workspace left rail shows a relevance-filtered graph
with edges colored by type. Nodes are currently small dots sized by
score. Per the original mockup, nodes should be larger and show a
type icon.

### Trail infrastructure

Per FR-20, trails exist as ordered collections of stops across works.
Concept-works integrate naturally: a "concept trail" is just a trail
through concept-works, e.g., "Ted Nelson's core ideas" links
*Hypertext* → *Transclusion* → *Non-linear writing*.

## WorkKind

### Definition

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum WorkKind {
    Document,
    Fragment,
    Person,
    Concept,
    Collection,
    Commentary,
}

impl Default for WorkKind {
    fn default() -> Self { WorkKind::Document }
}
```

### Semantic meaning

| Kind | What it represents | Example |
|---|---|---|
| `Document` | A standalone work (essay, article, chapter) | "On the Nature of Hypertext" |
| `Fragment` | A passage that exists as its own work for citation | A famous quotation extracted |
| `Person` | An author or figure (biographical page) | "Ted Nelson" |
| `Collection` | A grouping of other works | "Xanadu Collection" |
| `Concept` | An addressable concept (Ted's vision) | "Hypertext" |
| `Commentary` | A review or commentary on another work | Per FR-19 Marginalia comments |

### Storage

Add to `WorkMeta`:

```rust
pub struct WorkMeta {
    // ...existing fields...
    pub kind: WorkKind,  // default Document
}
```

Backward compatible: existing works deserialize as `Document`.

### Wire ops

```
0x0B01  WorkKindGet(work_id) -> WorkKind
0x0B02  WorkKindSet(work_id, kind) -> Void
0x0B03  WorkListByKind(kind) -> Vec<WorkMeta>
```

`WorkListByKind` powers the "Related concepts" panel: it returns all
Concept-kind works, sorted by link count.

### Icons

Map kind to icon for graph + work header:

| Kind | Icon (emoji for now) | Color |
|---|---|---|
| Document | 📄 | neutral grey |
| Fragment | ✂ | amber |
| Person | 👤 | rose |
| Concept | 💡 | purple |
| Collection | 📚 | green |
| Commentary | 💬 | blue |

The graph node renders the emoji inside a colored circle (per FR-21
sizing, but enlarged to fit the icon). Backend returns the kind
alongside other graph node fields.

## Concept-as-Work Pattern

### Why concepts are works, not tags

In Ted Nelson's design, concepts are not labels — they're first-class
addressable entities. "Hypertext" should be as citable as any essay.
You should be able to:

- Read what "Hypertext" means (the Concept work's body)
- See who has linked to it (backlinks)
- Cite it from another server (`xan://alice.concept.5`)
- Include it in trails (FR-20)
- Transclude its definition elsewhere

Tags don't give you this. Tags are flat strings; Concept works are
addressable knowledge.

### Tag → Concept work flow

When an author types a tag "hypertext" in the work editor:

1. **Lookup:** server searches for an existing Concept work with a
   normalized name "Hypertext" (case-insensitive, hyphen-normalized)
2. **If found:** create a typed link `See Also` from the current work
   to the Concept work
3. **If not found:** create a new Concept work with title "Hypertext"
   and empty body, then create the link
4. **UI:** the tag appears in the work's tag list, indistinguishable
   from a flat tag. But clicking it opens the Concept work.

This means tags and concept-works are the same thing, just different
UI presentations.

### Concept work lifecycle

- Created automatically when first referenced (lazy creation)
- Body starts empty; the first author to care can fill it in
- Multiple authors can edit (per edit club)
- Has its own tumbler, revisions, attribution
- Can be deleted if no works link to it (otherwise protected)

### "Related concepts" panel

In the workspace left rail, below the mini graph:

```
RELATED CONCEPTS
─────────────────
Hypertext              213
Transclusion           128
Non-linear writing      67
Computer-supported      97
Linked documents        86
[Show more…]
```

Implementation:
- `WorkListByKind(Concept)` returns all Concept works
- For each, count inbound `See Also` links
- Sort by count, descending
- Click to open the Concept work

This is the Ted Nelson version of a tag cloud — but every entry is
a real addressable work.

## LLM Auto-Categorization

### Trigger policy

| Trigger | Action |
|---|---|
| First save of new work | Auto-categorize once (if LLM enabled and author hasn't tagged) |
| Subsequent saves | Track content delta; if > 30% changed, suggest re-categorize |
| Manual button | Always available ("Re-categorize") |
| Cache hit (same content hash) | Skip |

**Token budget per work over its lifetime:** 2–5 calls typically.
First save + a few major revisions. Not a burden.

### Per-call minimization

- Truncate input to ~4000 chars (~1000 tokens) — categorization doesn't need the full document
- Default model: small (llama3.2:3b or qwen2.5:3b) — fast, good enough for tagging
- Strict JSON output, one-shot prompt
- Cache by content hash

### Prompt design

```rust
pub fn build_categorization_prompt(content: &str, existing_concepts: &[String]) -> String {
    let truncated = if content.len() > 4000 { &content[..4000] } else { content };
    let existing = if existing_concepts.is_empty() {
        "none".to_string()
    } else {
        existing_concepts.join(", ")
    };
    format!(
        r#"You are categorizing a document for a hypertext system.

Document:
{truncated}

Existing tags: {existing}

Suggest:
1. The document kind: one of "document", "fragment", "person", "concept", "collection", "commentary"
2. 3-7 concept tags relevant to the document's main topics

Respond as JSON only:
{{"kind": "<one of the six>", "concepts": ["tag1", "tag2", ...], "confidence": 0.0-1.0}}"#
    )
}
```

### Wire op

```
0x0B10  WorkAutoCategorize(work_id) -> CategorizationResult
0x0B11  WorkAcceptCategorization(work_id, result_id) -> Void
0x0B12  WorkCategorizationHistory(work_id) -> Vec<CategorizationResult>
```

`WorkAutoCategorize` returns suggestions without applying them. The
author reviews and calls `WorkAcceptCategorization` to actually
create the Concept works and links.

### Storage

```rust
pub struct CategorizationResult {
    pub result_id: u64,
    pub work_id: WorkId,
    pub suggested_kind: WorkKind,
    pub concepts: Vec<String>,
    pub confidence: f32,
    pub model: String,
    pub categorized_at: DateTime<Utc>,
    pub content_hash: String,
    pub accepted: bool,
    pub accepted_at: Option<DateTime<Utc>>,
}
```

Stored in a new manifest section `CategorizationsSection`. Each
categorization is preserved for audit (provenance: was this concept
LLM-suggested or human-added?).

### Provenance and trust

- LLM-suggested tags are marked with the model name and timestamp
- Author must accept before they become Concept works
- Author can reject individual suggestions (keep some, drop others)
- Manual tags have no LLM provenance — just the author identity
- Future: signed LLM provenance (model + prompt hash) for verifiability

### Privacy

- Ollama runs locally — no data leaves the server
- For multi-user servers: only the work owner can trigger auto-categorize
- Author's content never sent to third-party APIs without explicit opt-in

## Visual: Larger Nodes with Icons

### Graph node sizing (updated per FR-21)

| Score range | Radius | Icon size |
|---|---|---|
| Current work | 24 | 16px emoji |
| Score ≥ 5 | 20 | 14px emoji |
| Score 3–5 | 18 | 12px emoji |
| Score 1–3 | 16 | 11px emoji |
| Score < 1 | 12 | 9px emoji |

Larger nodes accommodate emoji icons inside the circle. The kind
lookup uses `WorkKind` from the backend (defaults to Document).

### Rendering

SVG `<g>` per node:
- `<circle>` for the background color (per FR-21 fill rules)
- `<text>` for the emoji icon centered on the circle
- `<text>` for the label below (when shown)

The emoji is set via `kind` lookup from a fixed map:

```typescript
const KIND_ICON: Record<WorkKind, string> = {
  document: "📄",
  fragment: "✂",
  person: "👤",
  concept: "💡",
  collection: "📚",
  commentary: "💬",
};
```

### Work header

In the workspace document header, show the work's kind icon next to
its title:

```
📄 On the Nature of Hypertext    [Follow] [Cite] [⋯]
```

Click the icon to change kind (small dropdown).

## Implementation Phases

### Phase 1: WorkKind backend (1 day)

- Add `WorkKind` enum to manifest
- Add field to `WorkMeta`
- Add wire ops: `WorkKindGet`, `WorkKindSet`, `WorkListByKind`
- Include `kind` in `GraphNode` payload
- Unit tests

### Phase 2: WorkKind frontend (1 day)

- Larger nodes in DocumentMapPanel with emoji icons
- Kind indicator in workspace document header
- Kind picker (small dropdown)
- Filter graph by kind (optional)

### Phase 3: Concept-as-work (2 days)

- "Add tag" UI in document header
- Server-side: lookup-or-create Concept work, create typed link
- "Related concepts" panel in workspace left rail
- Click concept opens the Concept work
- Concept work lifecycle (delete if no inbound links)

### Phase 4: LLM categorization (2–3 days)

- `build_categorization_prompt` in ollama.rs
- Wire op `WorkAutoCategorize`
- Storage for `CategorizationResult`
- Frontend: "Auto-categorize" button in workspace
- Suggestion review UI (accept/reject individual tags)
- First-save trigger (configurable)

### Phase 5: Polish (1 day)

- Categorization history view (right panel)
- Manual re-categorize button
- Confidence display (suggestions below threshold marked as low-confidence)
- Token usage tracker integration

**Total: ~7–8 days for full feature.** Each phase independently
shippable.

## Alternatives Considered

### Alternative A: Pure tags (no Concept works)

Just store tags as `Vec<String>` on each work. Simpler.

- **Pro:** Half the implementation effort. Familiar to users.
- **Con:** Tags aren't addressable. Can't cite "Hypertext" as a
  work. Can't have provenance on the tag itself. Loses Ted's vision.
- **Verdict:** Rejected. The extra effort for Concept-as-work is
  worth it for the addressability.

### Alternative B: Manual categorization only

Don't use LLM. Author tags works by hand.

- **Pro:** No new infrastructure. Author in full control.
- **Con:** Most works end up uncategorized. Discovery suffers.
- **Verdict:** Rejected as sole mechanism. LLM suggestions reduce
  friction; author still approves.

### Alternative C: External LLM API (OpenAI/Anthropic)

Use a remote API instead of local Ollama.

- **Pro:** Better model quality. No local compute.
- **Con:** Real per-token cost. Privacy concerns (data leaves
  server). Dependency on external service.
- **Verdict:** Rejected as default. Local-first is a Xudanu value.
  Could add as optional provider later.

### Alternative D: Auto-apply LLM suggestions without review

Skip the accept step. LLM tags are applied immediately.

- **Pro:** Zero-friction.
- **Con:** Author loses control. Bad suggestions stick. Provenance
  becomes harder to track (was this tag LLM or author?).
- **Verdict:** Rejected. Always give author the chance to approve.

## Open Questions

1. **Concept name collisions.** If two authors independently create
   "Hypertext" Concept works on different servers, do they merge?
   **Recommendation: no — they're different works on different
   servers. Cross-server concept reconciliation is future work.**

2. **Concept work permissions.** Who can edit a Concept work's body?
   **Recommendation: public edit by default (anyone logged in).
   Concepts are communal knowledge. Server admin can lock if needed.**

3. **LLM model selection.** Should the user pick which model runs
   categorization? **Recommendation: server admin picks via config
   (`--llm-categorization-model`). Per-user selection is overkill.**

4. **Concept versioning.** When a Concept work is revised, do its
   backlinks change? **Recommendation: no — backlinks point at the
   current state of the Concept work, which evolves over time. Same
   as any other link.**

5. **Multi-language concepts.** "Hypertext" vs "Hipertexto" — same
   concept? **Recommendation: no automatic reconciliation. Authors
   can create links between them (`See Also`) if they want.**

6. **Tagging via @-mention.** Should `@hypertext` in document body
   auto-tag? **Recommendation: no for v1. Tags are added via UI, not
   inline. Inline would conflict with content.**

## Ties to Other Designs

| Feature | Relationship |
|---|---|
| **FR-18 Workspace** | WorkKind shown in document header; Related concepts panel in left rail |
| **FR-19 Marginalia** | Review comments become Commentary-kind works |
| **FR-20 Trails** | Concept trails = trails through Concept works |
| **FR-21 Graph relevance** | Larger icon nodes use kind for the icon |
| **Existing Ollama** | Extended with categorization prompt |
| **`versioning-design.md`** | Concept works get revisions like any other work |
| **`cross-server-resolution.md`** | Concept works addressable cross-server |

## Success Criteria

- Every work has a `kind` (defaults to Document; author can change).
- The mini graph shows larger nodes with kind icons.
- Tagging a work "hypertext" creates or links to a Concept work.
- "Related concepts" panel shows Concept works sorted by link count.
- LLM auto-categorize produces sensible suggestions for ≥70% of new works.
- Authors always approve suggestions before they're applied.
- Per-work LLM token cost stays under 5 calls over the work's lifetime.
- Concept works are first-class addressable entities with their own
  tumblers, revisions, and provenance.

## Metrics

- % of works with non-default kind (target: > 50% after 3 months)
- % of works with at least 3 tags (target: > 70%)
- % of tags auto-suggested vs manual (target: 50/50 mix — both
  pathways used)
- LLM suggestion acceptance rate (target: > 50%)
- Concept work reuse (avg inbound links per Concept: target > 5)
- Token usage per work over time (target: < 5 calls lifetime)

## References

- `src/server/ollama.rs` — existing LLM runtime
- `src/server/transport/protocol.rs:519` — existing Ollama prompt builders
- `web/app/src/components/DocumentMapPanel.tsx` — graph rendering
- Ted Nelson, *Literary Machines* (1980) — original Concept-as-work
  vision
- Vannevar Bush, *As We May Think* (1945) — associative trails
- Maggie Appleton's pattern library — concept-as-node visual pattern
