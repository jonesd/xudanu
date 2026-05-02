# Path Navigation

## Overview

Paths are sequences of labels used to navigate through nested editions. A `Path`
descends through a hierarchy of labelled positions, resolving nested editions at
each step until it reaches the final element.

This implements the Gold model's `FePath::follow()` — see `nlinksx.cxx:969-995` in
the original C++ source.

## Core Types

### `Path`

```rust
use xudanu::edition::{Path, RangeElement};

// Create a path from labels
let path = Path::new(vec![
    RangeElement::label(1, RangeElement::edition(100)),
    RangeElement::label(2, RangeElement::text("target")),
]);

// Or build incrementally
let path = Path::empty()
    .with_label(RangeElement::label(1, RangeElement::edition(100)))
    .with_label(RangeElement::label(2, RangeElement::text("target")));
```

### `EditionResolver`

To follow paths through nested editions (where a label contains an
`Edition` element), you need a resolver that maps edition IDs to `Edition`
objects:

```rust
use xudanu::edition::{EditionResolver, HashMapResolver};

// Simple HashMap-based resolver
let mut resolver = HashMapResolver::new();
resolver.insert(100, inner_edition);
resolver.insert(200, leaf_edition);

// Or use the builder pattern
let resolver = HashMapResolver::new()
    .with(100, inner_edition)
    .with(200, leaf_edition);
```

For server integration, implement the `EditionResolver` trait against your
storage backend.

## Usage

### Basic single-step follow

```rust
let edition = Edition::from_text_elements(&[
    RangeElement::text("before"),
    RangeElement::label(1, RangeElement::text("found")),
    RangeElement::text("after"),
]);

let path = Path::new(vec![RangeElement::label(1, RangeElement::text("found"))]);
let result = path.follow(&edition);
assert_eq!(result.unwrap().as_text(), Some("found"));
```

### Multi-step follow with resolver

```rust
let inner = Edition::from_text_elements(&[
    RangeElement::label(2, RangeElement::text("deep")),
]);
let outer = Edition::from_text_elements(&[
    RangeElement::label(1, RangeElement::edition(100)),
]);

let resolver = HashMapResolver::new().with(100, inner);
let path = Path::new(vec![
    RangeElement::label(1, RangeElement::edition(100)),
    RangeElement::label(2, RangeElement::text("deep")),
]);
let result = path.follow_with_resolver(&outer, &resolver).unwrap();
assert_eq!(result.as_text(), Some("deep"));
```

### Finding labelled positions (without following)

```rust
// Get the region of positions with a specific label
let region = edition.positions_labelled(label_id);

// Get position + inner element for a single label
if let Some((pos, element)) = edition.fetch_labelled(label_id) {
    // pos is the i64 position, element is the unwrapped inner value
}
```

### Finding positions for a path's first label

```rust
let region = path.follow_region(&edition);
// Returns an XnRegion of all positions matching the path's first label
```

## Error Handling

`follow_with_resolver()` returns `Result<RangeElement, FollowError>`:

| Error | When |
|-------|------|
| `EmptyPath` | Path has no labels |
| `LabelNotFound { step, label_id }` | No position matches label at step |
| `MultiplePositions { step, label_id, count }` | Label found at >1 position (Gold requires exactly one) |
| `EditionNotFound { step, edition_id }` | Nested edition ID not in resolver |
| `UnexpectedType { step, position }` | Element at position can't be traversed |

`follow()` returns `Option<RangeElement>` — `None` for any error.

## How It Works

1. Start with the root edition's entries
2. For each label in the path:
   - Find positions where a `Label` element with matching `label_id` exists
   - Require exactly one match (Gold model constraint)
   - Extract the inner value from the label
   - If this is the last label, return the inner value
   - If the inner value is an `Edition`, resolve it via the resolver and continue
3. Return the final element

Labels are matched by `label_id` (the `u64` in `RangeElement::Label { label_id, inner }`),
not by the inner value. This allows different labels with the same inner content.

## Missing Parts / Future Work

- **Server integration**: The server's `standalone_editions` map should be
  exposed as an `EditionResolver`. This is a simple wrapper but not yet implemented.
- **Path serialization**: No Serde support for `Path` yet (labels are
  `Vec<RangeElement>` which already has Serde, so this is straightforward).
- **FePath construction from Edition**: The C++ code constructs a Path from an
  Edition wrapper. Our `Path::new()` takes labels directly — this is simpler but
  doesn't enforce the Gold model's endorsement/wrapper pattern.
- **Performance**: Currently collects `all_entries()` at each step. For deep
  nesting this could be optimized with lazy iteration.

---

# Original Context / Frozen Snapshots

## Overview

When a `HyperRef` is created, it can capture an **original context** — a frozen
snapshot of the source document at that moment. This allows the link to always
show what the document looked like when the link was made, even if the document
is later revised.

This implements the Gold model's `FeHyperRef::withOriginalContext()` — see
`nlinksx.cxx:371-385` in the original C++ source.

## Core Types

### `Snapshot`

An immutable record of a Work's state at a point in time:

```rust
use xudanu::edition::{Snapshot, Work, Edition};

let work = Work::new(1, Edition::from_text("hello"));
let snapshot = Snapshot::from_work(&work);
// snapshot.edition() == "hello"
// snapshot.source_work_id() == 1
// snapshot.frozen_at_revision() == 0
```

### `SnapshotStore`

Manages snapshots with auto-incrementing IDs:

```rust
use xudanu::edition::SnapshotStore;

let mut store = SnapshotStore::new();
let snapshot_id = store.freeze(&work);

// Retrieve
let edition = store.get_edition(snapshot_id);
let frozen_work = store.get_frozen_work(snapshot_id);

// List snapshots for a specific work
let snapshots = store.snapshots_for_work(work_id);
```

### Frozen Works

A frozen Work has `edit_club == Some(0)` (sentinel value). This prevents editing:

```rust
use xudanu::edition::{is_frozen, freeze_work, validate_not_frozen_for_edit};

let frozen = freeze_work(&work, new_be_id);
assert!(is_frozen(&frozen));

// Frozen works reject revisions
let result = frozen.try_revise(new_edition); // Returns Err(SnapshotError::CannotEditFrozen)
```

## Usage

### Creating a snapshot when making a link

```rust
let mut store = SnapshotStore::new();

// When creating a link, freeze the source work
let context_id = store.freeze(&source_work);

// Use context_id as the original_context in a HyperRef
let href = HyperRef::single(
    Some(excerpt),
    Some(source_work.be_id()),
    Some(context_id),
    Some(path),
);
```

### Freezing at a specific revision

```rust
// Freeze revision 5 (not the current)
let snapshot_id = store.freeze_at_revision(&work, 5);
```

### Snapshot independence

Snapshots are deep copies — revising the original work doesn't affect them:

```rust
let snapshot = Snapshot::from_work(&work);
work.revise(Edition::from_text("modified"));
// snapshot.edition().to_text() == "original" (unchanged)
```

## Error Handling

| Error | When |
|-------|------|
| `SnapshotError::NotFrozen { work_id }` | Tried to use a non-frozen work as original context |
| `SnapshotError::CannotEditFrozen { work_id }` | Tried to revise a frozen work |

## How It Works

1. `Snapshot::from_work(work)` clones the work's current edition
2. `to_frozen_work()` creates a new Work with the copied edition and `edit_club = Some(0)`
3. `Work::try_revise()` checks for the frozen sentinel before allowing edits
4. `Work::revise()` (the existing method) does NOT check — it remains available
   for internal use (e.g., server recovery)

The frozen sentinel is `edit_club == Some(0)`. The C++ code uses
`fetchEditClub() != NULL` — in our model, `edit_club == None` means "anyone can
edit" and `edit_club == Some(id)` means "only club members can edit". Using
`Some(0)` as the frozen sentinel means "nobody can edit" — club 0 doesn't exist.

## Missing Parts / Future Work

- **Server integration**: `SnapshotStore` is standalone. The server should use it
  to automatically freeze contexts when links are created.
- **Persistence**: `SnapshotStore` is in-memory only. Needs checkpoint/restore
  integration with the server's persistence layer.
- **Original context in protocol**: The wire format has `original_context: Option<u64>`
  in `HyperRefPayload`, but dispatch doesn't create snapshots yet.
- **Garbage collection**: No mechanism to clean up unreferenced snapshots.
- **Diff snapshots**: Could store deltas instead of full copies for large editions.

---

# Endorsement System

## Overview

Endorsements are `(club_id, token_id)` pairs that certify an Edition or Work as
belonging to a particular type. They are the Gold model's type system — rather
than having rigid class hierarchies, any entity can be endorsed with any number
of type certificates, and queries can filter by endorsements.

This implements the Gold model's `BeEdition::endorse()`, `BeEdition::retract()`,
and `BeEdition::endorsements()` — see `brange3x.cxx:504-619` in the original
C++ source.

## Core Types

### `Endorsement`

A single `(club_id, token_id)` pair:

```rust
use xudanu::edition::Endorsement;

let e = Endorsement::new(1, 42);  // club 1, token 42
assert_eq!(e.club_id(), 1);
assert_eq!(e.token_id(), 42);
```

### `EndorsementSet`

An ordered, deduplicated set of endorsements with set operations:

```rust
use xudanu::edition::EndorsementSet;

let set = EndorsementSet::from_endorsements(vec![
    Endorsement::new(1, 10),
    Endorsement::new(2, 20),
]);

// Set operations
let union = a.union(&b);
let intersection = a.intersect(&b);
let diff = a.difference(&b);

// Club-level queries
let club_ids = set.club_ids();           // {1, 2}
let tokens = set.tokens_for_club(1);    // {10}
```

### `Endorseable`

A mixin for entities that carry endorsements:

```rust
use xudanu::edition::Endorseable;

let mut e = Endorseable::new();
e.endorse_one(1, 10);                   // Add single endorsement
e.endorse(&some_set);                    // Add multiple
e.retract_one(1, 10);                   // Remove single
e.retract(&some_set);                    // Remove multiple

assert!(e.is_endorsed_by(1, 10));        // Check specific pair
assert!(e.has_club_endorsement(1));      // Check any from club
```

### `EndorsementFilter`

A composable filter for matching endorsement sets:

```rust
use xudanu::edition::EndorsementFilter;

// Simple filters
let any = EndorsementFilter::any();           // Matches everything
let none = EndorsementFilter::none();         // Matches nothing
let club = EndorsementFilter::club(1);        // Has any endorsement from club 1

// Set-based filters
let all_of = EndorsementFilter::all_of(required_set);   // Has ALL of these
let any_of = EndorsementFilter::any_of(candidates);     // Has ANY of these

// Composable
let complex = EndorsementFilter::and(vec![
    EndorsementFilter::not(EndorsementFilter::club(4)),  // NOT from club 4
    EndorsementFilter::or(vec![                           // AND (club 1 OR club 2)
        EndorsementFilter::club(1),
        EndorsementFilter::club(2),
    ]),
]);

// Matching
assert!(complex.matches(&my_endorsement_set));
```

## Usage

### Endorsing an Edition

```rust
let mut endoseable = Endorseable::new();
endoseable.endorse_one(CLUB_TEXT, TOKEN_UTF8);
endoseable.endorse_one(CLUB_LINK, TOKEN_BIDIRECTIONAL);

let endorsements = endoseable.endorsements();
```

### Filtering by endorsements (e.g., backfollow)

```rust
let filter = EndorsementFilter::all_of(
    EndorsementSet::single(CLUB_LINK, TOKEN_BIDIRECTIONAL)
);
for work in works {
    if work_endorseable.matches_filter(&filter) {
        // This work has the right endorsements
    }
}
```

### Converting to/from GrandMap IDs

```rust
use xudanu::edition::{endorsements_from_ids, endorsement_ids_to_grandmap};

// From raw pairs
let set = endorsements_from_ids(&[(1, 10), (2, 20)]);

// To GrandMap Ids (for Canopy/Props integration)
let ids = endorsement_ids_to_grandmap(&set);
```

## How It Works

1. `Endorsement` is a simple `(u64, u64)` pair — club ID and token ID
2. `EndorsementSet` uses a `BTreeSet` for ordered, deduplicated storage
3. `Endorseable` wraps an `EndorsementSet` with endorse/retract mutations
4. `EndorsementFilter` supports AND/OR/NOT composition for complex queries
5. Filtering is done via `matches_filter()` which recursively evaluates the
   filter tree against an endorsement set

The C++ model stores endorsements as `CrossRegion` in the `BertProp` — our
implementation is simpler and standalone, using native Rust types. The
`endorsement_ids_to_grandmap()` function bridges to the existing `BertProp`
system when needed.

## Missing Parts / Future Work

- **Authority validation**: The C++ code requires `CurrentKeyMaster` to hold
  signature authority for the club. Our implementation has no auth checking —
  anyone can endorse with any club ID. This is intentional for standalone use;
  the server should add auth validation.
- **Endorsement on Edition/Work**: `Endorseable` is a standalone struct, not
  integrated into `Edition` or `Work` yet. The server would add an `endorsements`
  field or use `Endorseable` as a component.
- **Retraction history**: The C++ model plans to keep retracted endorsements as
  "struck out" for audit purposes. Our `retract()` simply removes.
- **Canopy integration**: `BertProp.endorsements` uses `Vec<Id>`, while our
  `EndorsementSet` uses `BTreeSet<Endorsement>`. A bridge is needed for full
  Canopy/Props integration.
- **Serde**: `Endorsement` and `EndorsementSet` have Serde derives (behind
  feature flag), but `EndorsementFilter` does not — it's not typically serialized.
