# Migration Notes: Udanax Gold C++ → Xudanu Rust

## Phase 2: Edition / XnRegion / RangeElement

### What was implemented

Three new modules under `src/edition/`:

| Module | C++ Original | Rust Implementation |
|---|---|---|
| `xn_region.rs` | `IntegerRegion` (integerx.hxx) | `XnRegion` — transition-array encoding of integer sets |
| `range_element.rs` | `FeRangeElement` hierarchy (nkernelx.hxx) | `RangeElement` enum with Data, Text, Edition, Label, PlaceHolder, IDHolder, Work |
| `edition.rs` | `FeEdition` / `BeEdition` (nkernelx.hxx, brange3x.hxx) | `Edition` — wraps `OrglRoot` O-tree |

### Design decisions

1. **XnRegion uses transition arrays** (same as Gold's `IntegerRegion`): `(starts_inside: bool, transitions: Vec<i64>)`. This gives O(log n) `contains()` via binary search and clean set operations via sorted-merge.

2. **RangeElement is an enum**. Gold uses a deep class hierarchy (FeDataHolder, FeEdition, FePlaceHolder, FeLabel, FeIDHolder, FeWork). Rust's enum is more natural and avoids heap allocation.

3. **Carrier pairs element + optional label**. Mirrors Gold's `BeCarrier` which pairs a `BeRangeElement` with an optional `BeLabel`.

## Foundation Hardening: O-tree Implementation

### What was implemented

A fourth module under `src/edition/`:

| Module | C++ Original | Rust Implementation |
|---|---|---|
| `orgl.rs` | `OrglRoot` / `Loaf` / `InnerLoaf` / `OExpandingLoaf` (orootx.hxx, loavesx.hxx) | `OrglRoot` (Empty/Actual) + `Loaf` enum (Leaf/Split) with splay algorithm |

### O-tree architecture

The O-tree is Gold's persistent splay tree for Edition content. Our Rust port:

- **Loaf** is a Rust enum: `Leaf { region, entries }` or `Split { split, in_child, out_child }`
  - `Leaf` stores sorted `(i64, Arc<Carrier>)` pairs with a domain `XnRegion`
  - `Split` partitions space by a `XnRegion` into in/out children
  - Leaves auto-split when they exceed `MAX_LEAF_SIZE` (16384, matching Gold's `tableSegmentMaxSize`)
- **OrglRoot** wraps a `Loaf` (or is Empty), providing the Edition-level API
- **Splay algorithm** (9-case transformation table from SplitLoaf::actualSplay) is fully implemented:
  - `splay(region)` restructures the tree so the region is at/near the root
  - Returns `SplayResult::Outside / Partial / FullyContained`
  - Handles rotate-right, rotate-left, interleave, and swap operations

### Edition now uses OrglRoot internally

`Edition` was rewritten to wrap `OrglRoot` instead of `BTreeMap`:

- `fetch()` now returns `Option<RangeElement>` (owned) instead of `Option<&RangeElement>` (borrowed)
- All mutation methods (`with`, `without`, `replace`) use structural sharing via the O-tree
- Auto-splits leaves when they exceed 16384 entries
- Stress test: 50,000 positions in ~38 seconds including splay operations

### Simplifications from Gold's O-tree

| Gold Feature | Rust Status |
|---|---|
| DspLoaf (transform wrapper) | Not yet; `transformed_by` rebuilds the tree |
| OPartialLoaf (placeholder with TrailBlazer) | Simplified: Leaf stores explicit entries |
| OVirtualLoaf (backed by SharedData) | Simplified: Leaf stores explicit entries |
| RegionLoaf (points to BeRangeElement) | Simplified: Leaf stores explicit entries |
| H-tree (history/version tracking) | Not yet; needed for transclusion backfollow |
| Sensor crum / Bert crum (canopy indices) | Not yet; needed for transclusion queries |
| In-place mutation (placement new) | Rust enum variant replacement instead |

### Portability gaps (Gold features not yet in Rust)

| Gap | Gold Feature | Rust Status | Plan |
|---|---|---|---|
| Infinite-domain Editions | Editions can map infinite regions (e.g., `above(5) → constant`) | Edition only stores finite entries | Future: lazy/functional representation for infinite domains |
| H-tree / history tracking | Version tracking parallel to O-tree for backfollow | Not implemented | Phase 4 (Transclusion) |
| CoordinateSpace abstraction | Generic Position/Region across IntegerSpace, RealSpace, SequenceSpace, CrossSpace | Only integer positions (i64) | Add when needed; integer is the dominant case |
| Stepper / retrieve | `edition->stepper(region, order)` for filtered iteration | `iter()` only, no region filter | Add `iter_in_region()` method |
| Bundle retrieval | `retrieve()` returns Array/Element/PlaceHolder bundles | Not implemented | Add when needed for bulk reads |
| Fe/Be split | FrontEnd (session) / BackEnd (persistent) object split | Single unified struct | Next tranche |
| Work (mutable container) | `FeWork` holds current edition + revision history | Not yet implemented | Phase 3 (GrandMap) |
| Transclusion queries | `transcluders()`, `works()`, `rangeTranscluders()` | Not yet implemented | Phase 4 (Transclusion) |
| Permissions / endorsements | `BertProp`, `SensorProp`, endorsement/permission spaces | Not yet implemented | Phase 5 or later |
| Label propagation | `positionsLabelled()`, `rebind()`, label identity tracking | Label exists on Carrier but no propagation API | Add in Phase 4-5 |
| DspLoaf (transform wrapper) | Lazy displacement without rebuilding tree | `transformed_by` rebuilds | Add when needed for performance |

### Enhancement ideas for future phases

1. **yrs/CRDT as transport layer**: The Edition model maps naturally to yrs `Doc` with `Text` sequences. An Edition could be materialized into a yrs document for real-time sync, while maintaining the Gold partial ordering for conflict preservation.

2. **Content-addressed storage**: RangeElements with identical content should be deduplicated via content hashing (like Git's blob storage). This is the foundation for transclusion.

3. **Compressed transition arrays**: For very large regions, run-length encoding with 32-bit deltas could reduce memory usage.

4. **DspLoaf for lazy transforms**: Instead of rebuilding the entire tree on `transformed_by`, wrap the root in a DspLoaf that applies the offset lazily. This is how Gold does it.

5. **Parallel region operations**: `merge_transitions` could be parallelized for large regions using rayon.

6. **Fe/Be trait boundary**: Define `BeRangeElement` trait with identity, owner, stub/materialize protocol. Keep everything in-memory with `InMemoryBeStorage` (HashMap-backed). The disk serialization layer plugs in later.

### Gold test cases ported

- **Region**: 6 canonical example regions × 10 unary checks + 15 pairs × 8 binary checks = all Gold RegionTester checks pass
- **Edition**: 14 test cases from `makeEditionTestOn`, `editionTestOn`, and `compareTestOn` in nkernelt.cxx
- **O-tree**: 22 tests for Loaf/OrglRoot (splay, split, combine, copy, domain, fetch, etc.)
- **Stress**: 50K position edition, 10K splay operation
- **Total**: 212 tests (114 ent + 98 edition), all passing

### Test history

| Phase | Tests | Notes |
|---|---|---|
| Phase 2 initial | 189 | BTreeMap-based Edition |
| Foundation hardening | 212 | O-tree based Edition, all Gold tests preserved |
