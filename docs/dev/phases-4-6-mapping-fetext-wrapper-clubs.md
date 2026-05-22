# Phases 4-6: Mapping Algebra, FeText, FeWrapper, and Club Hierarchy

## Overview

This document covers Phases 4-6 of the Xudanu implementation, adding text manipulation operations, type wrappers with certification, and the full club-based permission hierarchy.

## Phase 4: Mapping Algebra and FeText Operations

### Mapping Algebra (`src/edition/mapping.rs`)

The Mapping algebra provides position transformation between coordinate spaces. A Mapping represents a set of (domain, range) position pairs that retarget edition positions.

#### Types

```rust
pub enum Mapping {
    Empty,                                          // maps nothing
    Simple { offset: i64, region: XnRegion },       // shifts positions in region by offset
    Composite(Vec<Mapping>),                        // union of sub-mappings
}
```

#### Core Operations

| Operation | Description |
|-----------|-------------|
| `of(pos) -> Option<i64>` | Transform a single position |
| `of_region(region) -> XnRegion` | Transform an entire region |
| `inverse() -> Mapping` | Swap domain/range pairs |
| `combine(other) -> Mapping` | Union of two mapping pair-sets |
| `restrict(region) -> Mapping` | Limit domain to region |
| `shift_range(offset) -> Mapping` | Shift all range positions by offset |
| `domain() -> XnRegion` | Get the domain region |
| `range() -> XnRegion` | Get the range region |

#### XnRegion::compactor()

Added to `XnRegion`, the `compactor()` method maps disjoint regions to contiguous zero-based positions. For example, region `[3,7) ∪ [10,15)` produces a mapping that sends:
- 3→0, 4→1, 5→2, 6→3
- 10→4, 11→5, 12→6, 13→7, 14→8

#### Edition::transformed_by_mapping()

Applies a Mapping to an Edition's positions, retargeting each entry:

```
{ <k2, label, value> | <k1, label, value> in self and <k1, k2> in mapping }
```

### FeText (`src/edition/fetext.rs`)

FeText wraps an Edition with a contiguous, zero-based integer domain and provides text manipulation operations.

#### Operations

| Operation | Description |
|-----------|-------------|
| `insert(position, text)` | Insert text at position |
| `extract(region)` | Extract and compact a region |
| `delete(region)` | Remove a region |
| `move_range(pos, region)` | Move a region to a new position |
| `replace(dest, other)` | Replace a region with other text |

All operations are **immutable** — they return new FeText instances. They decompose into `transformed_by_mapping()` and `combine()` calls on the underlying Edition.

#### Insert Algorithm

Insert splits the original text into two parts:
1. Positions before `position` stay in place (identity mapping)
2. Positions at/after `position` shift right by `text.count()`

The inserted text is shifted to start at `position`. All three parts are combined.

#### Delete Algorithm

Delete = extract the complement of the deleted region, which compacts the remaining content.

#### Move Algorithm

Move = extract the region + delete the region + insert at new position.

## Phase 5: FeWrapper System

### Wrapper Spec and Registry (`src/edition/wrapper.rs`)

The wrapper system provides type certification and endorsement for Editions. Each wrapper type has:
- A **checker** function that validates Edition structure
- An **endorsement** token that stamps certified Editions
- A **spec** that manages the check/certify/wrap lifecycle

#### Built-in Types

| Type | Token | Check |
|------|-------|-------|
| Text | 1 | Contiguous, zero-based domain |
| Set | 2 | Finite edition |
| Path | 3 | Contiguous zero-based domain, all Label elements |
| HyperLink | 4 | Non-empty edition |
| HyperRef | 5 | Always passes (structural checks in subclasses) |

#### Certification Flow

```
WrapperSpec::check(edition)     // validate structure
WrapperSpec::certify(endorsements)  // stamp endorsement set
WrapperRegistry::certify_as(edition, endorsements, "Text")
```

Endorsements use `(WRAPPER_CLUB_ID=1, token_id)` pairs, integrating with the existing EndorsementSet from Phase 3.

### FeSet

FeSet wraps a finite Edition as an unordered set of RangeElements. Operations work by element value (not position):

| Operation | Description |
|-----------|-------------|
| `with(value)` | Add element |
| `without(value)` | Remove element |
| `includes(value)` | Check membership |
| `intersect(other)` | Elements in both |
| `minus(other)` | Elements in self but not other |
| `union_with(other)` | All elements from both |

## Phase 6: Club Hierarchy Completion

### Expanded Club (`src/server/club.rs`)

Club now supports full membership hierarchy:

| Feature | Description |
|---------|-------------|
| `members` | Direct member club IDs |
| `sponsored_works` | Works sponsored by this club |
| `endorsements` | EndorsementSet from Phase 3 |
| `transitive_super_club_ids()` | All clubs this club transitively belongs to |
| `transitive_member_ids()` | All transitively contained clubs |
| `can_be_read_by(keymaster)` | Permission check |
| `can_be_edited_by(keymaster)` | Permission check |

#### Membership Direction

- **Members**: Clubs contained in this club (subordinate)
- **Super clubs**: Clubs that contain this club (superior)

Authority flows **upward**: a KeyMaster for club C has authority over all clubs that C transitively belongs to.

### Expanded KeyMaster (`src/server/keymaster.rs`)

KeyMaster now supports hierarchy-aware authority:

| Feature | Description |
|---------|-------------|
| `update_authority(all_clubs)` | Recompute actual authority from login clubs using transitive super clubs |
| `has_signature_authority(club, all_clubs)` | Check if user can sign for a club (has authority over its signature club) |

#### Authority Computation

When `update_authority()` is called, the KeyMaster computes:

```
actual_authority = ∪ (for each login_id: transitive_super_club_ids(login_id))
```

This means logging in as a member of a sub-club grants authority over all parent clubs.

### Work Endorsements

Work now has an integrated EndorsementSet:

| Method | Description |
|--------|-------------|
| `endorsements()` | Get current endorsements |
| `endorse(additional)` | Add endorsements |
| `retract(removed)` | Remove endorsements |

## Test Coverage

- **Mapping**: 17 tests (creation, of, inverse, combine, restrict, shift_range, domain/range, compactor)
- **FeText**: 26 tests (insert, extract, delete, move, replace, chaining, compaction)
- **Wrapper**: 21 tests (registry, certification, FeSet operations)
- **Club**: 18 tests (members, sponsors, endorsements, transitive relationships, permissions)
- **KeyMaster**: 10 tests (authority, hierarchy, signature authority)
- **Work**: Added endorsement tests
- **Integration**: All 74 existing integration tests still pass
- **Stress**: All 13 ignored tests still pass
- **Total**: 974 unit + 74 integration + 13 stress = 1061 tests
