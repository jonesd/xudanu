# Phase 7: Label System + Identity Unification

## Overview

This phase implements two critical features from the Udanax Gold model:

1. **Label System** — Identity tags attached to RangeElements within Editions
2. **Identity Unification** — The ability to merge two RangeElement identities into one

These correspond to the C++ `FeLabel`/`BeLabel`/`BeCarrier` classes and the `makeIdentical()`/`makeRangeIdentical()` family of operations.

## Label System

### C++ Reference

- `FeLabel` — A RangeElement subclass representing an identity attached to a RangeElement within an Edition
- `BeLabel` — The backend (persistent) form, essentially a unique server-assigned ID
- `BeCarrier` — Combines a `BeRangeElement` + optional `BeLabel` — what Editions store internally
- `FeEdition` stores `myLabel` (FeLabel) propagated to derived editions
- `FeLabel::fake()` — Creates a lazy label (allocated on demand via `getOrMakeBe()`)
- `FeLabel::make()` — Creates a new unique label immediately

### Rust Implementation

The Rust implementation is in `src/edition/label.rs` with these key types:

#### `LabelId` and `Label`

```rust
pub struct LabelId(pub u64);  // Unique label identifier
pub struct Label { pub id: LabelId }
```

Labels are created with auto-incrementing IDs via `AtomicU64`. The `Label::new()` and `Label::fake()` methods both create unique labels.

#### `LabelledCarrier`

Wraps a `Carrier` with an optional `LabelId`, representing the combination of element + label at a position:

```rust
pub struct LabelledCarrier {
    pub label: Option<LabelId>,
    pub carrier: Carrier,
}
```

#### `LabelledEdition`

A high-level wrapper combining an `Edition` with a `Label`, matching the C++ `FeEdition(myBeEdition, myLabel)` pattern:

```rust
pub struct LabelledEdition {
    pub edition: Edition,
    pub label: Label,
}
```

**Key operations:**
- `relabelled()` — Returns same edition with different label
- `rebind()` — Replaces edition at position but preserves old label (matches C++ `FeEdition::rebind()`)
- `positions_labelled()` — Finds positions with a given label ID
- `with()` — Adds/replaces position with optional label
- `combine()`, `replace()`, `copy()` — Propagate the receiver's label to the result

### Label Propagation Rules (from C++)

| Operation | Label Source |
|-----------|-------------|
| `combine()` | Receiver's label |
| `replace()` | Receiver's label |
| `copy()` | Receiver's label |
| `with()` | Value argument's label |
| `rebind()` | Old label at position preserved |
| `relabelled()` | New label argument |

## Identity Unification

### C++ Reference

- `FeRangeElement::makeIdentical()` — Change identity of this object to another
- `FeRangeElement::canMakeIdentical()` — Check if unification is possible
- `FeRangeElement::isIdentical()` — Check if two elements have same server identity
- `FeEdition::makeRangeIdentical()` — Batch unify elements at matching positions
- `FeEdition::canMakeRangeIdentical()` — Check which positions can be unified
- `BePlaceHolder::makeIdentical()` — Core implementation: redirects O-tree pointers and session objects

### Unification Rules

The C++ code defines these rules for when unification is allowed:

| Source Type | Target Type | Allowed? |
|-------------|-------------|----------|
| PlaceHolder | Any | Yes (always) |
| Any | PlaceHolder | Yes (always) |
| Text | Text (same content) | Yes |
| Text | Text (different content) | No |
| Data | Data (same content) | Yes |
| Edition | Edition (same ID) | Yes |
| Work | Work (same ID) | Yes |
| Blob | Blob (same content_hash) | Yes |
| Label | Label (same label_id + same inner) | Yes |
| Text | Data | No (different type) |

### Rust Implementation

#### `can_make_identical()`

```rust
pub fn can_make_identical(source: &RangeElement, target: &RangeElement) -> CanMakeIdenticalResult
```

Returns `Yes`, `DifferentType`, `DifferentContent`, or `NotOwned`.

Key rules:
- PlaceHolders can be unified with anything (pure identity containers)
- Data/Text require same content
- Editions/Works require same ID
- Blobs require same content_hash
- Cross-type unification is always rejected

#### `make_range_identical()`

```rust
pub fn make_range_identical(
    source: &Edition,
    target: &Edition,
    region: Option<&XnRegion>,
) -> MakeRangeIdenticalResult
```

Batch unification across matching positions. Returns:
- `AllUnified` — Every position was successfully unified
- `PartiallyUnified { failed_positions }` — Some positions failed, with reasons

The failed positions are also returned as an `Edition` containing the un-unified elements (matching the C++ return value which is the subset that did NOT get unified).

#### `IdentityMap`

```rust
pub struct IdentityMap {
    mappings: HashMap<u64, u64>,
}
```

Tracks identity redirections with transitive resolution. When element A is unified with element B, the map records `A -> B`. Subsequent lookups via `resolve()` follow the chain.

## Integration Points

### Existing Code Already Supporting Labels

The existing `Carrier` struct already has a `label: Option<RangeElementId>` field, and `Edition::positions_labelled()` / `Edition::fetch_labelled()` were implemented in Phase 1. The new `label.rs` module provides a higher-level abstraction layer.

### Areas Not Migrated (Replaced by Rust)

| C++ Feature | Rust Replacement |
|-------------|-----------------|
| `BeLabel` (persistent server-side label) | `LabelId` (simple u64) |
| `BeCarrier` (BeRangeElement + BeLabel) | `LabelledCarrier` (Carrier + LabelId) |
| `FeLabel::getOrMakeBe()` lazy allocation | `Label::new()` eager allocation |
| `BePlaceHolder::makeIdentical()` O-tree pointer redirection | `make_range_identical()` with `IdentityMap` |
| `FeRangeElement::isIdentical()` (async, server-mediated) | `can_make_identical()` (synchronous, content-based) |
| Per-element ownership checks in `makeIdentical` | `CanMakeIdenticalResult::NotOwned` (deferred to server layer) |

## Test Coverage

50 new tests covering:

- **Labels**: Unique ID generation, labelled carriers, labelled edition CRUD
- **LabelledEdition**: combine, replace, copy, with/without, rebind, relabelled, positions_labelled
- **can_make_identical**: All type combinations (placeholder, text, data, edition, work, blob, id_holder, label, cross-type)
- **make_range_identical**: All match, partial mismatch, with region filter, missing positions, placeholder-to-text, different types, empty editions
- **IdentityMap**: Basic, transitive, resolve, overwrite, no-mapping

## Files Changed

| File | Change |
|------|--------|
| `src/edition/label.rs` | **NEW** — Label, LabelId, LabelledCarrier, LabelledEdition, identity unification |
| `src/edition/mod.rs` | Added `pub mod label` and re-exports |

## Test Results

```
running 50 tests
test result: ok. 50 passed; 0 failed; 0 ignored

Full suite: 1024 passed; 0 failed; 13 ignored
```
