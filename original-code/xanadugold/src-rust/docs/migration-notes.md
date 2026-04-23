# Migration Notes: Udanax Gold C++ → Xudanu Rust

## Phase 2: Edition / XnRegion / RangeElement

### What was implemented

Three new modules under `src/edition/`:

| Module | C++ Original | Rust Implementation |
|---|---|---|
| `xn_region.rs` | `IntegerRegion` (integerx.hxx) | `XnRegion` — transition-array encoding of integer sets |
| `range_element.rs` | `FeRangeElement` hierarchy (nkernelx.hxx) | `RangeElement` enum with Data, Text, Edition, Label, PlaceHolder, IDHolder, Work |
| `edition.rs` | `FeEdition` / `BeEdition` (nkernelx.hxx, brange3x.hxx) | `Edition` — immutable `BTreeMap<i64, Carrier>` |

### Design decisions

1. **XnRegion uses transition arrays** (same as Gold's `IntegerRegion`): `(starts_inside: bool, transitions: Vec<i64>)`. This gives O(log n) `contains()` via binary search and clean set operations via sorted-merge.

2. **Edition uses BTreeMap, not O-tree**. Gold uses the O-tree (OrglRoot → Loaf → InnerLoaf/OExpandingLoaf) for persistent, disk-based editions. We use a simpler `BTreeMap<i64, Carrier>` for the initial implementation. The O-tree can be added in Phase 6 (persistence) if needed for performance.

3. **RangeElement is an enum**. Gold uses a deep class hierarchy (FeDataHolder, FeEdition, FePlaceHolder, FeLabel, FeIDHolder, FeWork). Rust's enum is more natural and avoids heap allocation.

4. **Carrier pairs element + optional label**. Mirrors Gold's `BeCarrier` which pairs a `BeRangeElement` with an optional `BeLabel`.

### Portability gaps (Gold features not yet in Rust)

| Gap | Gold Feature | Rust Status | Plan |
|---|---|---|---|
| Infinite-domain Editions | Editions can map infinite regions (e.g., `above(5) → constant`) | Edition only stores finite entries | Future: lazy/functional representation for infinite domains |
| O-tree / OrglRoot | Persistent splay-tree structure for editions | Simple BTreeMap | Phase 6 if needed; BTreeMap is sufficient for in-memory use |
| CoordinateSpace abstraction | Generic Position/Region across IntegerSpace, RealSpace, SequenceSpace, CrossSpace | Only integer positions (i64) | Add when needed; integer is the dominant case |
| Stepper / retrieve | `edition->stepper(region, order)` for filtered iteration | `iter()` only, no region filter | Add `iter_in_region()` method |
| Bundle retrieval | `retrieve()` returns Array/Element/PlaceHolder bundles | Not implemented | Add when needed for bulk reads |
| Fe/Be split | FrontEnd (session) / BackEnd (persistent) object split | Single unified struct | Phase 3-6 when adding GrandMap and persistence |
| Work (mutable container) | `FeWork` holds current edition + revision history | Not yet implemented | Phase 3 (GrandMap) |
| Transclusion queries | `transcluders()`, `works()`, `rangeTranscluders()` | Not yet implemented | Phase 4 (Transclusion) |
| Permissions / endorsements | `BertProp`, `SensorProp`, endorsement/permission spaces | Not yet implemented | Phase 5 or later |
| Label propagation | `positionsLabelled()`, `rebind()`, label identity tracking | Label exists on Carrier but no propagation API | Add in Phase 4-5 |

### Enhancement ideas for future phases

1. **yrs/CRDT as transport layer**: The Edition model maps naturally to yrs `Doc` with `Text` sequences. An Edition could be materialized into a yrs document for real-time sync, while maintaining the Gold partial ordering for conflict preservation.

2. **Content-addressed storage**: RangeElements with identical content should be deduplicated via content hashing (like Git's blob storage). This is the foundation for transclusion.

3. **Compressed transition arrays**: For very large regions, run-length encoding with 32-bit deltas could reduce memory usage.

4. **Copy-on-Write structural sharing**: When Editions are derived from each other via `with`/`without`/`replace`, they could share the underlying BTreeMap via `im::OrdMap` or similar persistent data structure, avoiding full clones.

5. **Parallel region operations**: `merge_transitions` could be parallelized for large regions using rayon.

### Gold test cases ported

- **Region**: 6 canonical example regions × 10 unary checks + 15 pairs × 8 binary checks = all Gold RegionTester checks pass
- **Edition**: 14 test cases from `makeEditionTestOn`, `editionTestOn`, and `compareTestOn` in nkernelt.cxx
- **Total**: 189 tests (114 ent + 75 edition), all passing
