# Phase 8: Bundle Retrieval + Storage Cost

## Overview

This phase implements the fundamental retrieval operation and storage cost accounting for Editions. These are core to how clients read content from the document store and understand resource usage.

## Bundle System

### What is a Bundle?

A Bundle is an association between a region of positions in an Edition and the content at those positions. Instead of returning individual position-value pairs, `retrieve()` groups them into Bundles for efficiency.

### Bundle Types

Three bundle types mirror the C++ FeBundle hierarchy:

| Type | Description | When Used |
|------|-------------|-----------|
| **Element** | A region where every position holds the same RangeElement | Uniform content (e.g., all placeholders, repeated text) |
| **Array** | A region with ordered heterogeneous RangeElements | Mixed content runs |
| **PlaceHolder** | A region where each position has a distinct placeholder | Placeholder regions |

### Retrieval Algorithm

```
retrieve_bundles(entries, region, flags):
  1. Filter entries to the requested region (or all if no region)
  2. Walk entries sequentially:
     a. If current element is PlaceHolder → group consecutive placeholders → PlaceHolderBundle
     b. If all same element → ElementBundle (single element for whole region)
     c. If mixed elements → ArrayBundle (ordered list of elements)
  3. Return list of bundles
```

### RetrieveFlags

| Flag | Effect |
|------|--------|
| `ignore_total_ordering` | Allow non-contiguous regions to be grouped, bundles in any order |
| `ignore_array_ordering` | ArrayBundle elements can be reordered |
| `separate_owners` | Each bundle has a single owner |

## Storage Cost

### CostMethod

Three methods for accounting shared material (matching C++ constants):

| Method | Behavior |
|--------|----------|
| `OmitShared` | Shared material not counted at all |
| `ProrateShared` | Shared material divided among sharing Editions |
| `TotalShared` | Entire cost counted for each Edition (default) |

### StorageCost Structure

```rust
pub struct StorageCost {
    pub total_bytes: u64,      // Raw byte total
    pub unique_bytes: u64,     // Non-shared bytes
    pub shared_bytes: u64,     // Bytes shared with other Editions
    pub share_count: u64,      // Number of Editions sharing
    pub method: CostMethod,    // Which accounting method
}
```

The `billed_bytes()` method returns the cost according to the selected method.

### Byte Size Calculation

Element sizes are estimated:
- **Text**: base size + UTF-8 byte length
- **Data**: base size + byte length
- **Blob**: base size + declared byte_size
- **Edition**: base size + 16 bytes (reference overhead)
- **Label**: base size + inner element size

## Server Protocol

### Operations

| Op Code | Name | Description |
|---------|------|-------------|
| `0x0c01` | `edition_retrieve` | Retrieve bundles from a work's edition |
| `0x0c02` | `edition_cost` | Get storage cost for a work's edition |

### edition_retrieve

**Request:**
```json
{
  "op": "edition_retrieve",
  "payload": {
    "work_id": 42,
    "region": {"starts_inside": false, "transitions": [2, 5]},
    "flags": {"ignore_total_ordering": false, "ignore_array_ordering": false, "separate_owners": false}
  }
}
```

**Response:**
```json
{
  "type": "bundle_results",
  "value": {
    "bundles": [
      {
        "type": "array",
        "region": {"starts_inside": false, "transitions": [2, 5]},
        "elements": [
          {"Text": {"text": "c"}},
          {"Text": {"text": "d"}},
          {"Text": {"text": "e"}}
        ]
      }
    ]
  }
}
```

Both `region` and `flags` are optional. Without a region, the entire edition is retrieved.

### edition_cost

**Request:**
```json
{
  "op": "edition_cost",
  "payload": {
    "work_id": 42,
    "method": "total_shared"
  }
}
```

**Response:**
```json
{
  "type": "storage_cost_result",
  "value": {
    "total_bytes": 128,
    "unique_bytes": 128,
    "shared_bytes": 0,
    "share_count": 0,
    "billed_bytes": 128,
    "method": "totalshared"
  }
}
```

Method values: `"omit_shared"`, `"prorate_shared"`, `"total_shared"` (default).

## C++ Reference Mapping

| C++ Class | Rust Equivalent |
|-----------|-----------------|
| `FeBundle` | `Bundle` (enum) |
| `FeArrayBundle` | `Bundle::Array` |
| `FeElementBundle` | `Bundle::Element` |
| `FePlaceHolderBundle` | `Bundle::PlaceHolder` |
| `FeEdition::retrieve()` | `Edition::retrieve()` → `Vec<Bundle>` |
| `FeEdition::cost()` | `Edition::cost()` → `StorageCost` |
| `BeEdition::retrieve()` | Server dispatches to `Edition::retrieve()` |
| Bundle stepper (O-tree walk) | Simplified: `retrieve_bundles()` on flattened entries |
| `OMIT_SHARED` / `PRORATE_SHARED` / `TOTAL_SHARED` | `CostMethod` enum |

## Files

### Library
- `src/edition/bundle.rs` — Bundle types, retrieve algorithm, storage cost calculation

### Server
- `src/server/transport/protocol.rs` — Op codes, WireRequest/ResponseValue variants, payload types
- `src/server/transport/codec.rs` — JSON codec for new operations
- `src/server/transport/dispatch.rs` — Dispatch handlers
- `src/server/server.rs` — Server methods: `edition_retrieve()`, `edition_cost()`

### Tests
- `src/edition/bundle.rs` (mod tests) — 16 unit tests
- `tests/integration.rs` — 7 integration tests

## Test Summary

| Category | Count |
|----------|-------|
| Unit tests (bundle) | 16 |
| Integration tests | 7 |
| **Total new** | **23** |
