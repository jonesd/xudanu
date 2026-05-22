# Phase 10: Full Transclusion Queries + Bundle Stepper

## Overview

Phase 10 adds full range-based transclusion queries and an ordered bundle stepper with merge-sort for the O-tree. These features enable querying which editions/works contain content from a specific region of an edition, and retrieving edition contents in sorted order directly from the O-tree structure.

## What Was Built

### 1. Range Transclusion Queries (`src/edition/range_transclusion.rs`)

**RangeTransclusionQuery** — A query builder for region-scoped transclusion lookups:

```rust
let query = RangeTransclusionQuery::new()
    .with_region(XnRegion::interval(0, 10))
    .direct_only(true)
    .local_present_only(false);
```

**`range_transcluders()`** — Finds all editions/works that contain content from a given edition's region. Unlike the existing `find_transcluders()` which operates on a single element, this walks all elements within a region and collects transclusion results with deduplication.

**`range_works()`** — Finds all works containing content from a given edition's region.

**`walk_otree_shared()`** — O-tree-aware shared content detection. Compares entries from two editions within a region using sorted merge (O(n+m) complexity), matching the C++ `sharedRegion()` pattern for leaf nodes.

**`collect_unique_elements()`** — Extracts unique elements from an edition within a region, using content fingerprints for deduplication.

**`count_transclusion_depth()`** — Counts the transclusion depth of an element (how many levels of transclusion exist above it), with a configurable max depth to prevent infinite recursion.

**`find_deeply_transcluded()`** — Finds all elements in an edition that are transcluded at or above a minimum depth threshold, useful for identifying widely-shared content.

### 2. Bundle Stepper with Merge-Sort (`src/edition/bundle_stepper.rs`)

**BundleStepper** — A cursor over bundles extracted from edition entries. Groups consecutive identical elements into `Bundle::Array` bundles and single elements into `Bundle::Element` bundles.

**MergeBundleStepper** — A merge-sort stepper that interleaves two bundle steppers by position, maintaining sorted order. This is the Rust equivalent of the C++ `MergeBundlesStepper` used for ordered retrieval from Split nodes.

**`loaf_bundle_stepper()`** — Creates a `BundleStepper` by collecting entries from a Loaf subtree within a region. Handles all three Loaf variants (Leaf, Split, Dsp).

**`loaf_merge_stepper()`** — Creates a `MergeBundleStepper` that walks the O-tree structure recursively, using merge-sort at Split nodes and displacement at Dsp nodes. This preserves position ordering throughout the tree.

### 3. Edition Methods (`src/edition/edition.rs`)

New methods on Edition:

- **`ordered_bundles(region)`** — Returns position-ordered bundles from the O-tree using the flat bundle stepper.
- **`ordered_merge_bundles(region)`** — Returns position-ordered bundles using the merge-sort stepper, which properly handles the O-tree's Split/Dsp structure.
- **`range_transcluders(region, direct_only, index)`** — Finds transcluders of all content in a region.
- **`range_works(region, index)`** — Finds works containing all content in a region.
- **`transclusion_depth(position, index, max_depth)`** — Gets the transclusion depth at a position.
- **`deeply_transcluded_elements(region, index, min_depth)`** — Finds elements transcluded at or above a depth threshold.

### 4. Server Integration

Four new operations added to the wire protocol (opcodes 0x0f01-0x0f04):

| Operation | Opcode | Request | Response |
|-----------|--------|---------|----------|
| `range_transcluders` | 0x0f01 | work_id, region?, direct_only? | edition_ids, work_ids, region |
| `range_works` | 0x0f02 | work_id, region? | work_ids, region |
| `ordered_bundles` | 0x0f03 | work_id, region? | bundles[] |
| `transclusion_depth` | 0x0f04 | work_id, position, max_depth? | depth |

Full integration path: protocol.rs (opcodes, WireRequest, ResponseValue) → codec.rs (JSON deserialization) → dispatch.rs (routing) → server.rs (methods).

## C++ Equivalence

| C++ Method | Rust Equivalent |
|------------|-----------------|
| `FeEdition::rangeTranscluders()` | `range_transcluders()` + server `RangeTranscluders` op |
| `FeEdition::rangeWorks()` | `range_works()` + server `RangeWorks` op |
| `SplitLoaf::bundleStepper()` | `loaf_merge_stepper()` with `MergeBundleStepper` |
| `MergeBundlesStepper` | `MergeBundleStepper` |
| `DspLoaf::bundleStepper()` | Dsp handling in `loaf_merge_stepper()` |
| `RegionLoaf::bundleStepper()` | Leaf handling in `loaf_bundle_stepper()` |
| `OExpandingLoaf::sharedRegion()` | `walk_otree_shared()` |

## Design Decisions

1. **Simplified Loaf types**: The C++ has distinct RegionLoaf, OPartialLoaf, and OVirtualLoaf types. The Rust uses a single `Loaf::Leaf` with optional default, which covers all three cases. This keeps the O-tree simpler while still supporting identity-based sharing at the Edition layer.

2. **Merge-sort without BinaryHeap**: The initial implementation used `BinaryHeap<OrderedBundle>` which required `Eq` on `Bundle`. Since `Bundle` contains `RangeElement` (which can't easily derive `Eq` due to `Arc<Carrier>`), the `MergeBundleStepper` was redesigned to use a two-stream merge approach with `peek_start()` comparisons instead.

3. **Combined edition_ids + work_ids in results**: The `range_transcluders` result returns both edition IDs and work IDs, because the server registers both editions (via `store_edition`) and works (via `create_work`) in the transclusion index.

## Tests

- **33 new unit tests**: 21 for bundle_stepper, 12 for range_transclusion
- **11 new integration tests**: Covering all 4 new server operations with various inputs
- **Total: 1227 tests passing** (1123 unit + 104 integration)
