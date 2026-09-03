# FR-37: Crum-Based Comparison

## Overview

Replace flat, pairwise, recomputed-every-time comparison with
structural comparison over the enfilade — the mechanism Gold used.
Two editions are compared by walking their loaves: equal node crums
mean entire subtrees are identical (skip in O(1)); unequal crums
descend. The result is *largest shared subtrees* rather than per-entry
runs, computed in O(depth × divergences) instead of O(n·m) over
flattened text.

**Status**: Specification
**Depends on**: FR-34 Phases F–J (crums, splay, tumbler bridge — all landed)
**Pairs with**: FR-35 (Bloom federation consumes the same crum sets),
Beams view (Design D), Origin panel (Design C)
**Effort**: 3–4 days (K1: 1–2d, K2: 1d, K3: 0.5d)

## Background

### Current mechanism (what we replace)

`find_shared_regions` (server.rs) merges two sources:

1. `find_content_shared_regions` (edition.rs) — per-entry
   `content_fingerprint()` hash-join with greedy run extension over
   **flattened** `cached_entries()`. Entry-level, ignores the tree.
2. `find_text_shared_regions` — character-diff backstop over current
   text.

`MultiEndCompare` (frontend) calls this **O(n²) pairwise** for an
n-way comparison, recomputed from scratch on every open. Nothing is
cached; the enfilade structure contributes nothing.

### What Gold did

Comparison fell out of the data structure: walking two enfilades,
crums identified matching subtrees wholesale (the FR-34 Phase J note:
*"uses crums to identify matching subtrees"*). Tumbler stability kept
positions meaningful across revisions. The same crum identity powered
combine, dedup, and transclusion matching — one structure, many
features.

### Primitives already in place

| Primitive | Location | Status |
|---|---|---|
| Root crum, cached O(1) | `OrglRoot::crum()` | Active |
| Node crums | `Loaf::compute_crum()` (orgl.rs) | Available |
| Range crums | `Edition::range_crum(start, end)` | Available |
| Content fingerprints | `RangeElement::content_fingerprint()` | Active (current compare tier) |
| Splay / tumbler bridge | FR-34 G/F | Active |

## Design

### K1 — Crum-diff walk (structural, pairwise)

```rust
/// Gold-style structural diff of two editions.
/// Returns matched subtrees (largest-first) and per-side divergences.
pub fn crum_diff(
    &self,
    other: &Edition,
) -> CrumDiff;
```

Algorithm (in `edition.rs`, over `OrglRoot`/`Loaf`):

1. If root crums equal → whole editions identical, one match.
2. Walk both loaves in lockstep, tracking entry-index ranges:
   - `Leaf × Leaf`: entry-range comparison via content fingerprints
     (leaf granularity; short-circuits when leaf crums already match)
   - `Split × Split`: recurse into children whose crums differ;
     children with equal crums become matched subtrees
   - `Dsp × _`: peel the offset (dsp crum includes it), compare child
   - Mismatched shapes (`Leaf × Split`, etc.): descend the split side,
     fingerprint-match the leaf side — structural alignment without
     forcing isomorphic trees
3. Merge adjacent matched ranges (splay-adjacent subtrees that are
   coalesced in the other tree).

```rust
pub struct CrumDiff {
    /// Matched regions, largest first: (a_start, a_end, b_start, b_end).
    pub matched: Vec<(i64, i64, i64, i64)>,
    /// Runs unique to each side (position ranges).
    pub only_a: Vec<(i64, i64)>,
    pub only_b: Vec<(i64, i64)>,
    /// Subtree skips: matched node crums (for cache/debug/bloom reuse).
    pub matched_crum_count: usize,
}
```

Existing `find_content_shared_regions` stays as the **moved-passage
tier**: crum-diff catches same-content-at-same-position wholesale;
fingerprints catch content that *moved* (Gold's tumbler algebra
handled repositioning; our two-tier approach approximates it).

### K2 — Crum-set registry and n-way compare

Per work, maintain the set of subtree crums at a fixed granularity
(e.g. leaf + split-nodes above size threshold):

- Keyed by `(work_id, revision)` — **editions are immutable per
  revision**, so entries never invalidate; bounded LRU eviction.
- Server op: `shared_crum_regions(work_ids: [u64; 2..=8])` →
  per-work regions classified by *how many* of the works share each
  passage (superset coloring the frontend already renders), plus
  per-pair detail for pair-colors when n ≤ 4.
- O(n) set intersections instead of O(n²) text diffs; one pass per
  work regardless of comparison width.
- The same sets feed FR-35 Bloom filters and dedup — compute once.

### K3 — Frontend integration

`MultiEndCompare` switches to `shared_crum_regions`:

- matched regions render with the existing shared/unique view modes
- pair-colors derive from the pair detail (n ≤ 4) or count-buckets
- pairwise `findSharedRegions` remains as fallback (old server,
  single-pair quick view)
- Connections ⇄ flow unchanged — ends arrive as `workIds` either way

## Test Plan

Unit (edition.rs):

1. `crum_diff_identical` — same edition twice → single whole-match,
   zero divergences, matched_crum_count > 0
2. `crum_diff_disjoint_insert` — insert at end → one matched subtree
   covering the prefix, one `only_a` run
3. `crum_diff_middle_edit` — edit middle → two matched subtrees
   (before/after), one divergence pair
4. `crum_diff_moved_passage` — passage moved: structural diff reports
   divergence at both sites; fingerprint tier still reports the move
   (integration test through `find_shared_regions` compatibility path)
5. `crum_diff_shape_mismatch` — leaf vs split at aligned position
   produces sane ranges (no panics, monotonic ranges)
6. Property test (proptest, 256 cases): matched ranges are
   non-overlapping, ordered, and the fingerprint tier finds ⊇ the
   structural matches

Registry (server):

7. `crum_set_cached_per_revision` — second call for same
   (work, revision) hits cache; after edit (new revision) recomputes
8. `shared_crum_regions_n_way` — 3 works sharing a passage: all three
   report it, count = 3; pair detail present for n ≤ 4

E2E:

9. Existing compare e2e suite passes unchanged (K3 fallback path)

## Future (out of scope)

- Tumbler-stable diff keys (positions that survive renumbering)
- Streaming crum-diff for federation sync (FR-35 follow-on)
- Revision-range diff chains (crum-diff across history)

## Relationship to Other FRs

- FR-34 Phase K in spirit: the comparison payoff of the enfilade work
- FR-35: consumes the same crum sets (compute-once economy)
- Demo story: Beams (D) shows connections, Origin (C) shows
  provenance, crum-compare shows *what is shared* — the three-sided
  transclusion story Roger would recognize
