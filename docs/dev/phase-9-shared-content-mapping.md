# Phase 9: Shared Content Mapping

## Overview

This phase completes the shared content detection and mapping system. While many pieces were built in earlier phases (positional `shared_region`, `shared_with`, `not_shared_with`, `map_shared_to`, `find_content_shared_regions`, `ContentAddressIndex`, `TransclusionIndex`), Phase 9 adds **content-fingerprint-based** detection (not just positional matching) and proper mapping types for shared content relationships.

## What Was Already Built (Earlier Phases)

| Method | Type | Description |
|--------|------|-------------|
| `shared_region(&other)` | Positional | Positions where both Editions have identical content at the same position |
| `shared_with(&other)` | Positional | Edition containing only shared entries |
| `not_shared_with(&other)` | Positional | Edition containing only non-shared entries |
| `map_shared_to(&other)` | Positional | BTreeMap from self positions to other positions with same content |
| `find_content_shared_regions(&other, min_run)` | Content-based | Finds runs of shared content between Editions |
| `ContentAddressIndex` | Index | Content-addressable element lookup by fingerprint |
| `TransclusionIndex` | Index | Finds transcluders and works for given content |

## New in Phase 9

### Content-Fingerprint-Based Shared Detection

The existing `shared_region()` is **positional** — it only finds matches at the same position in both Editions. The new `content_shared_region()` is **content-based** — it finds positions in self whose *content* (by BLAKE3 fingerprint) appears anywhere in the other Edition.

```rust
// Positional: only matches at same position
let region = a.shared_region(&b);

// Content-based: matches at any position
let region = a.content_shared_region(&b);
```

**Example:**
```
Edition A: [0:"x", 1:"y", 2:"z"]
Edition B: [0:"a", 1:"y", 2:"b", 3:"z"]

Positional shared_region: {1}       // only position 1 has same content at same position
Content shared_region:   {1, 2}     // y at pos 1, z at pos 2 (z is at pos 3 in B, but content matches)
```

### SharedMapping Type

A new type for representing arbitrary position-to-position shared content mappings:

```rust
pub struct SharedMapping {
    pairs: Vec<(i64, i64)>,
}
```

Supports `domain()`, `range()`, `of(pos)`, `len()`, `is_empty()`, `pairs()`.

### Content Map Shared To

`content_map_shared_to()` maps each position in self to **all** positions in other with matching content. This can produce multiple mappings for a single source position.

### Content Map Shared Onto

`content_map_shared_onto()` is the **injective** version — each target position is mapped at most once. This is the C++ `mapSharedOnto` operation (which was actually `NOT_YET_IMPLEMENTED` in the original code).

The injective property means:
- No two source positions map to the same target position
- Suitable as an argument to `transformedBy`
- Represents the minimal transformation needed to make the shared part of `other` from self

### PositionsOf Server Op

The `positions_of()` method already existed on Edition but had no server operation. Now exposed as op `0x0e04`.

## Server Protocol

### Operations

| Op Code | Name | Description |
|---------|------|-------------|
| `0x0e01` | `content_shared_region` | Content-fingerprint-based shared region between two works |
| `0x0e02` | `content_map_shared_to` | All shared position mappings between two works |
| `0x0e03` | `content_map_shared_onto` | Injective shared position mappings between two works |
| `0x0e04` | `positions_of` | All positions where an element appears in a work |

### content_shared_region

**Request:**
```json
{
  "op": "content_shared_region",
  "payload": {"work_a": 42, "work_b": 43}
}
```

**Response:**
```json
{
  "type": "shared_region_result",
  "value": {"region": {"starts_inside": false, "transitions": [1, 2, 2, 3]}}
}
```

### content_map_shared_to / content_map_shared_onto

**Request:**
```json
{
  "op": "content_map_shared_to",
  "payload": {"work_a": 42, "work_b": 43}
}
```

**Response:**
```json
{
  "type": "shared_mapping_result",
  "value": {"pairs": [[0, 1], [1, 3], [2, 5]]}
}
```

### positions_of

**Request:**
```json
{
  "op": "positions_of",
  "payload": {"work_id": 42, "element": {"Text": {"text": "a"}}}
}
```

**Response:**
```json
{
  "type": "positions_of_result",
  "value": {"region": {"starts_inside": false, "transitions": [0, 1, 2, 3]}}
}
```

## C++ Reference Mapping

| C++ Method | Rust Equivalent | Notes |
|------------|-----------------|-------|
| `FeEdition::sharedRegion(other)` | `Edition::shared_region(&other)` | Built earlier (positional) |
| `FeEdition::sharedWith(other)` | `Edition::shared_with(&other)` | Built earlier |
| `FeEdition::notSharedWith(other)` | `Edition::not_shared_with(&other)` | Built earlier |
| `FeEdition::mapSharedTo(other)` | `Edition::map_shared_to(&other)` | Built earlier (BTreeMap) |
| `FeEdition::mapSharedOnto(other)` | `Edition::content_map_shared_onto(&other)` | New — injective mapping |
| `FeEdition::positionsOf(value)` | `Edition::positions_of(&value)` | Built earlier, now has server op |
| Content-based shared detection | `Edition::content_shared_region(&other)` | New — fingerprint-based |
| Content-based mapping | `Edition::content_map_shared_to(&other)` | New — returns SharedMapping |

## Files

### Library
- `src/edition/shared_mapping.rs` — SharedMapping type, content-based algorithms, 12 unit tests
- `src/edition/edition.rs` — New methods: content_shared_region, content_map_shared_to, content_map_shared_onto

### Server
- `src/server/transport/protocol.rs` — Op codes 0x0e01–0x0e04, WireRequest/ResponseValue variants
- `src/server/transport/codec.rs` — JSON codec for new operations
- `src/server/transport/dispatch.rs` — Dispatch handlers
- `src/server/server.rs` — Server methods

### Tests
- `src/edition/shared_mapping.rs` (mod tests) — 12 unit tests
- `tests/integration.rs` — 5 integration tests

## Test Summary

| Category | Count |
|----------|-------|
| Unit tests (shared_mapping) | 12 |
| Integration tests | 5 |
| **Total new** | **17** |
| **Total project** | **1183** (1090 unit + 93 integration) |
