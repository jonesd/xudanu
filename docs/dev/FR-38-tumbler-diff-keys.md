# FR-38: Tumbler-Stable Diff Keys

## Overview

Give spans an address that survives renumbering. Today every diff,
compare, and link endpoint is expressed in **char offsets**, which
invalidate on any insert before them. Gold's answer was tumblers —
transfinite hierarchical addresses, stable forever. This FR ports
that property to xudanu as a **span-key layer** over the existing
tumbler bridge, without re-numbering the enfilade itself.

**Status**: Specification
**Depends on**: FR-34 Phase F (tumbler bridge — landed), FR-37 (K1/K2
diff tiers — landed)
**Unblocks**: native moved-passage matching in crum_diff (retiring
FR-37's fingerprint tier), stable permalinks across edits, federated
span references
**Effort**: 4–6 days (S1 keys, S2 diff integration, S3 consumers)

## Background

### The instability problem

Char offsets shift on every earlier edit. Consequences today:

- `crum_diff` matched ranges are valid only for the compared
  revisions; nothing about a match can be recorded durably
- Links store `start_position`/`end_position` that require migration
  logic when the source moves
- FR-37's "moved passage" detection needs the position-independent
  fingerprint tier — an explicit workaround for lacking stable keys
- Cross-server refs carry a tumbler **string** already, but locally
  we cannot resolve it to a moving span

### What Gold had

Tumblers: hierarchical addresses of the form `2.4.17.3` where each
component is a transfinite ( surreal-integer-like) number. Inserting
between `2.4` and `2.5` creates `2.4.1` — **no existing address ever
changes**. Every byte had one forever; links and comparisons were
expressed in them.

### What we have

The FR-34 bridge maps Sequence positions ⇄ tumbler strings for
display, permalinks, and cross-server refs. But span *identity* in
storage is still char offsets. The bridge is a formatter; this FR
makes it a key space.

## Design

### S1 — Span keys (the core)

A **span key** is the canonical tumbler interval for a range,
assigned at creation and never recomputed:

```rust
pub struct SpanKey {
    /// Tumbler interval in canonical string form: "2.4.1:2.4.2".
    pub canonical: String,
    /// Interior path components (parsed), for ordering.
    path: SmallVec<[u128; 4]>,
    start: Tumbler,
    end: Tumbler,
}
```

Allocation rule (Gold's rule, adapted): when content is **created**
(work import, paste, transclusion placement), it receives a tumbler
interval under its parent context. When content is **inserted
between** existing intervals, it receives a fresh sub-interval
(`between(a, b)` → one level deeper, e.g. `2.4` / `2.5` → `2.4.1`).
Existing keys are never mutated. Char offsets remain the working
coordinate system; span keys are the durable identity carried
alongside.

Storage: an entry-side map `char_offset → SpanKey` maintained by the
same code paths that maintain positions today (apply_edits,
transclusion placement). Chunk-persisted as part of WorkState
(FR-36's tree: a `span_keys_hash` section).

### S2 — Diff integration

- `CrumDiff` gains span-key coordinates for every matched range
  (`matched_keys: Vec<(SpanKey, SpanKey)>`)
- Moved-passage detection becomes: unmatched span in A whose
  **content-span-key tuple** reappears in B → moved, not added+
  deleted. The fingerprint tier drops to a fallback
- Revisions of one work: crum_diff over editions of the same work
  compares by span key directly — a revision's diff is then
  position-stable across its whole history

### S3 — Consumers

1. **Permalinks**: `?work=0x..&span=2.4.1:2.4.2` resolves through
   the key map regardless of later edits (today's `#char=` links rot)
2. **Link ends**: `HyperRef.start/end` migrate from positions to
   span keys (read-side compatibility shim for stored links)
3. **Federation**: cross-server refs resolve locally by key without
   the current text-search fallback

## What this is NOT

- Not native tumbler positions inside the Loaf — entry `i64`
  positions and crum position-sensitivity stay as they are (that is
  a separate, larger phase paired with federation sync)
- Not a replacement for char offsets in the editor/UI

## Test Plan

1. `span_key_stable_under_prefix_insert` — insert before a keyed
   span; its key is unchanged, its char offset shifts
2. `span_key_between_allocation` — insert between two keyed spans;
   new key orders correctly and neither neighbor changes
3. `crum_diff_reports_keys` — matched ranges carry resolvable keys
4. `moved_passage_via_keys` — move a keyed span; crum_diff reports
   one move (today: two divergences + fingerprint-tier recovery)
5. `permalink_resolves_after_edits` — span link resolves pre/post
   heavy editing of the target work
6. Property test (256 cases): random edit sequences never mutate an
   existing key; keys remain strictly ordered

## Sequencing

After the editor-polish feedback cycle (B/C/D iteration) and before
federation hardening resumes — federation is the biggest consumer of
stable keys, and Roger's structural-transclusion review benefits
from moved-passage fidelity.
