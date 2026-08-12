# FR-34: Enfilade-Native CRDT

## Overview

The enfilade (orgl.rs) is Xudanu's core data structure, ported from the
Udanax Gold C++ codebase. It is a balanced tree (Loaf/Split/Dsp) that
supports efficient point lookup, region extraction, lazy displacement,
and content-addressed subtree hashing.

Currently the CRDT treats the enfilade as a dumb array: flatten the tree
to a Vec at every operation, walk the Vec, then rebuild the tree from
scratch. This document describes the plan to make the CRDT operate ON
the tree directly, using the enfilade's structural properties.

## Design Principles

- **Crum-first** -- use subtree hashes (crums) to skip identical regions
- **Position-model-agnostic** -- Phase B/C work with any position type
- **Tumbler layering** -- add SequenceSpace addressing alongside IntegerSpace
- **Incremental delivery** -- each phase is independently shippable
- **Non-breaking** -- existing serialized data continues to work

## Architecture Context

### What the enfilade already provides

| Capability | Status | Used in CRDT? |
|---|---|---|
| `Loaf::compute_crum()` | Shipped (P0) | Yes -- Phase A fast-path |
| `OrglRoot::with(pos, carrier)` | Production | No -- CRDT rebuilds from Vec |
| `OrglRoot::without(pos)` | Production | No |
| `OrglRoot::copy(region)` | Production | No |
| `OrglRoot::combine(other)` | Production (disjoint only) | No |
| `OrglRoot::splay(region)` | Tested, dormant | No |
| `transformed_by(offset)` (Dsp) | Production | No |
| `shared_region(other)` | Production | No |

### What the space algebra provides (unused)

| Module | Lines | Purpose |
|---|---|---|
| `space/sequence.rs` | 1248 | Tumbler positions (hierarchical, infinitely insertable) |
| `space/integer.rs` | 726 | Integer positions (what enfilade uses now) |
| `space/cross.rs` | 413 | CrossSpace: combines two spaces (document x character) |
| `space/arrangement.rs` | 115 | Mappings between spaces (transclusion coordinates) |
| `space/traits.rs` | 187 | Space, Position, Region, Dsp traits |
| `space/order.rs` | 132 | Ordering specifications |

### What we lost by choosing i64 positions

1. **Infinite insertability** -- with tumblers, inserting between 3 and 4
   creates 3.1; no renumbering. With integers, everything above shifts.
2. **Cross-document addressing** -- tumblers span documents natively;
   integers are local to one edition.
3. **Hierarchical operations** -- tumbler prefixes enable section-level
   extraction and comparison; integers require a separate index.
4. **Arrangement transforms** -- the arrangement module maps between
   spaces for transclusion coordinates; this is not connected.

### What we keep by staying i64 for now

1. **Simplicity** -- every developer understands position 42.
2. **Performance** -- i64 comparison is one instruction; tumbler
   comparison loops over a Vec.
3. **Memory** -- 8 bytes vs 24+ bytes per position.
4. **Compatibility** -- all serialized data uses integer positions.

## Phases

### Phase A: Crum Fast-Path -- DONE

**Committed**: `945f01a`

Check root crums before doing any work in `three_way_diff`. When all
three editions (base, A, B) have matching crums, return immediately.

| Scenario | Before | After |
|---|---|---|
| No concurrent edits (most common) | O(n) | **O(1)** |
| One side unchanged | O(n) | O(n) |
| Both sides changed | O(n) | O(n) |

### Phase B: Subtree Structural Diff

Walk all three trees in parallel. Where subtree crums match across all
three, skip that subtree entirely. Only descend into differing subtrees.

**Algorithm**:
```
structural_diff(base, a, b):
  if base.crum == a.crum and base.crum == b.crum:
    return Unchanged  -- O(1) skip
  if base.crum == a.crum:
    return diff_base_vs_b(base, b)  -- only B changed
  if base.crum == b.crum:
    return diff_base_vs_a(base, a)  -- only A changed
  -- all three differ -- descend
  if all are Split nodes with compatible structure:
    recurse into in_child and out_child triples
  else:
    fallback to entry-level alignment (existing code, small region only)
```

**Challenge**: The three trees may have different split points and
depths. Walk in position space, not by matching tree nodes. Find
"change boundaries" where crums diverge, skip between them.

| Scenario | Before | After |
|---|---|---|
| Both edit different paragraphs | O(n) | **O(log n x k)** k=changed regions |
| Both edit same paragraph | O(n) | O(leaf_size) |
| Complete rewrite | O(n) | O(n) (degenerates) |

**Estimated effort**: 1-2 days

### Phase C: Tree-Native Merge Assembly

Build the merged edition using `orgl.copy()` for unchanged regions
instead of `from_bulk_entries()` for the entire result.

**Current**:
```
assemble_merge_lww -> Vec<(pos, carrier)> -> from_bulk_entries -> O(n) rebuild
```

**Phase C**:
```
unchanged regions -> orgl.copy(region)    -> O(log n) per region
changed regions   -> from_entries(small)  -> O(k) for changed only
combined          -> orgl.combine()        -> O(log n)
final renumber    -> single pass           -> O(n) but no alignment
```

**Position renumbering**: After assembly, positions must be sequential.
Options:
- Single-pass renumber (O(n) but simple, no alignment cost)
- Dsp nodes (O(1) per shift, but creates chains)
- Periodic compaction (renumber on save)

**Estimated effort**: 1 day

### Phase D: Tumbler Layer

Add `SequenceSpace` (tumbler) addressing alongside the existing
`IntegerSpace`. Use tumblers for cross-document features where they
provide the most value; keep integers for document-level editing.

**What tumblers enable**:

1. **O(1) insertions** -- inserting between positions 3 and 4 creates
   position 3.1. No renumbering. Eliminates the position problem that
   makes enfilade-native delta application difficult.

2. **Cross-document addressing** -- tumbler `doc_id.5.3` references
   document doc_id, section 5, character 3. Native transclusion
   coordinates without side tables.

3. **Prefix-based section operations** -- "all content under section
   1.2" is a prefix query. `orgl.copy(prefix_region(1.2))` extracts
   a section in O(log n). Section-level crums compare two documents
   section-by-section.

4. **Arrangement transforms** -- the arrangement module maps between
   spaces, enabling transclusion coordinate transforms: "show document
   B's chars 10-20 at position 5 in document A."

**Architecture**:
```
Document enfilade:    IntegerSpace (i64 positions)     -- existing, unchanged
Cross-doc addressing: SequenceSpace (tumbler positions) -- new layer
Compound enfilade:    CrossSpace(Seq, Int)             -- future
Transclusion map:     Arrangement                       -- connects spaces
```

**Migration approach** (layered, not replacement):
- Keep i64 positions for document-level editing
- Add SequenceSpace for cross-document features
- Use Arrangement to map between them
- Existing serialized data continues to work

**Estimated effort**: 3-5 days

### Phase E: Enfilade-Native Delta Application

With tumbler infrastructure in place, replace the flatten-walk-rebuild
delta path with direct tree operations.

**Current**:
```
apply_text_delta_to_edition:
  flatten tree to Vec  -> O(n)
  walk ops on Vec      -> O(ops)
  rebuild tree         -> O(n)
  coalesce             -> O(n)  [eliminated in P1]
  Total: ~2x O(n)
```

**Phase E**:
```
apply_delta_to_orgl:
  map char positions to entry positions (walk touched entries only)
  for each delete: orgl.without(pos)    -> O(log n)
  for each insert: orgl.with(pos, carrier) -> O(log n)
  for each split:  without + two withs   -> O(log n)
  Total: O(k log n) where k = touched entries
```

| Scenario | Before | After |
|---|---|---|
| Single char edit in 10K doc | O(10000) | **O(log 10000) ~ 14** |
| Delete a paragraph | O(n) | O(s log n) s=paragraph size |
| Paste 5 pages | O(n) | O(n log n) -- regression, use batch path |

**Mitigation for large pastes**: detect large inserts (> threshold), fall
back to batch `from_entries()` path. Best of both worlds.

**Position management with tumblers**: O(1) insertions, no Dsp chains,
no renumbering. This is the key advantage of having the tumbler layer.

**Estimated effort**: 2-3 days (after Phase D)

## Performance Summary

| Operation | Before | Phase A-C | Phase D-E |
|---|---|---|---|
| Merge: no concurrent edits | O(n) | **O(1)** | O(1) |
| Merge: small concurrent edits | O(n) | **O(log n x k)** | O(log n x k) |
| Delta: single char edit | O(n) | O(n) | **O(log n)** |
| Delta: large paste | O(n) | O(n) | O(n) batch fallback |
| Equality check | O(n) | **O(1)** | O(1) |
| Cross-document transclusion | Side table | Side Table | **Native (tumbler)** |

## Completed Work

| Date | Commit | Phase | Description |
|---|---|---|---|
| 2025-08-11 | `47404c7` | Enfilade-merge 1 | Eliminate text flattening from hot paths |
| 2025-08-11 | `6c66d4b` | Enfilade-merge 2 | Provenance preservation through merges |
| 2025-08-11 | `f289ad2` | Enfilade-merge 3 | Span provenance migration through deltas |
| 2025-08-11 | `e62cc7f` | Enfilade-merge 4 | Provenance lifecycle verification tests |
| 2025-08-11 | `f12b850` | Enfilade-merge 5 | Property tests + merge fuzzing |
| 2025-08-11 | `1ff205b` | P0 | Subtree crums (Merkle hashing) |
| 2025-08-11 | `2892265` | P0 tests | Expanded crum test coverage (24 tests) |
| 2025-08-11 | `9d819f1` | P1 | Inline coalesce during delta application |
| 2025-08-11 | `945f01a` | Phase A | Crum fast-path for three-way diff |

## Relationship to Original Xanadu Concepts

The enfilade was designed by Ted Nelson's team for exactly this purpose:
efficient document editing with content-addressed subtrees, structural
operations, and lazy position management.

- **Crums** = Xanadu "OC" (original crum) -- content-addressed subtree hashes
- **Splay** = core restructuring operation for spatial locality
- **Dsp** = lazy displacement node for position shifts
- **Tumblers** = hierarchical addressing (1.2.3.4) for cross-document referencing
- **Arrangement** = coordinate transform between spaces (transclusion mapping)
- **CrossSpace** = combining document-level and character-level addressing

Making the CRDT enfilade-native is using the enfilade as designed, rather
than treating it as a storage container.
