# Phase 18: DagWood Reconciliation and Mutable State

## Overview

Phase 18 implements the Reconciliation Plane of the Three Planes of Consensus
architecture. When two servers independently revise the same work, both editions
coexist as alternatives. Endorsements propagate across servers via CRDT merge.
No silent resolution -- pure Xanadu.

## Key Invariant

DagWood's `AlternativeSet` means concurrent edits from different servers are
**always preserved**. The system never picks a winner. All alternatives are
queryable and visible.

## Architecture

### Three Planes of Consensus (recap)

| Plane | Mechanism | Phase |
|-------|-----------|-------|
| Content | G-Set CRDT + BLAKE3 | Phase 16 |
| **Reconciliation** | **OR-Set CRDT + LWW-Register + DagWood AlternativeSet** | **Phase 18** |
| Governance | PBFT | Phase 19 |

### CRDT Data Structures

#### OrSet<T> -- Observed-Remove Set CRDT

**File:** `src/server/federation.rs`

Semantics:
- `add(value, unique_tag)`: inserts (value, tag) into the add set. Tag must be
  globally unique (server_id + counter).
- `remove(value, tag)`: moves specific (value, tag) to tombstone set.
- `remove_value(value)`: tombstones ALL entries for a value.
- `merge(other)`: union of add sets minus union of tombstone sets.
- Tombstoned tags cannot be re-added (silent rejection).

Properties: commutative, associative, idempotent.

Used for: endorsement propagation across servers.

#### LwwRegister<T> -- Last-Writer-Wins Register CRDT

**File:** `src/server/federation.rs`

Semantics:
- `set(value, timestamp, server_id)`: overwrites if (timestamp, server_id) is
  strictly greater than current.
- `merge(other)`: takes the higher (timestamp, server_id).
- Tiebreaker: server_id compared lexicographically.

Properties: commutative, associative, idempotent.

Used for: "current edition" pointer within a ReconcileState.

### Reconciliation State

#### AlternativeEdition

A single edition from a specific server at a specific revision:

```rust
pub struct AlternativeEdition {
    pub origin_server_id: String,
    pub revision_number: u64,
    pub edition_payload: EditionPayload,
    pub timestamp: u64,
}
```

Globally identified by `(origin_server_id, revision_number)`.

#### ReconcileState

Per-work reconciliation state:

```rust
pub struct ReconcileState {
    pub work_fingerprint: String,           // BLAKE3 hash of edition content
    pub alternatives: HashMap<String, AlternativeEdition>,  // all known editions
    pub current: LwwRegister<String>,       // points to current alternative key
    pub endorsements: OrSet<EndorsementEntry>,  // CRDT-merged endorsements
}
```

Key methods:
- `add_alternative(edition)`: adds a new concurrent edition
- `set_current(key, timestamp, server_id)`: updates the LWW current pointer
- `current_edition()`: returns the edition the LWW register points to
- `all_alternatives()`: returns all editions (for conflict inspection)
- `merge(other)`: unions alternatives, LWW-merges current, OR-Set merges endorsements
- `has_alternatives()`: true when multiple editions exist (conflict detected)

#### ReconcileStore

Global store mapping work fingerprint to ReconcileState:

```rust
pub struct ReconcileStore {
    states: HashMap<String, ReconcileState>,
}
```

Key methods:
- `get_or_create(...)`: creates state on first access
- `merge_remote(...)`: merges remote state, creating if needed
- `fingerprints()`: lists all tracked works

### Server Integration

The `Server` struct has two new fields:
- `reconcile_store: ReconcileStore` -- global reconciliation state
- `reconcile_counter: u64` -- monotonic counter for unique tags

Reconciliation is automatically triggered on:
- `create_work()` -- records initial edition
- `work_revise()` -- records each revision
- `edition_set_single()` -- records element-level edits

#### Server Methods

| Method | Purpose |
|--------|---------|
| `reconcile_record_local_revision(work_id, edition, timestamp)` | Record a local work revision |
| `reconcile_merge_remote(remote_state)` | Merge remote ReconcileState |
| `reconcile_export_all()` | Export all states for sync |
| `reconcile_get(work_fingerprint)` | Get state for a work |
| `reconcile_alternatives(work_fingerprint)` | Get all alternative editions |
| `reconcile_endorse(work_fp, club_id, token_id, tag)` | Add endorsement via OR-Set |
| `reconcile_retract(work_fp, club_id, token_id, tag)` | Retract endorsement via OR-Set |
| `reconcile_next_tag()` | Generate unique OrSetTag |
| `reconcile_export_endorsements()` | Export all endorsement OR-Sets |
| `reconcile_merge_endorsements(entries)` | Merge remote endorsement OR-Sets |

## Wire Protocol

### Client Operations (via /xudanu WebSocket)

| Opcode | Operation | Payload | Response |
|--------|-----------|---------|----------|
| `0x1801` | `endorsement_sync` | `{work_fingerprint}` | Endorsement list |
| `0x1802` | `endorsement_add` | `{work_fingerprint, club_id, token_id}` | `{tag_server_id, tag_counter}` |
| `0x1803` | `endorsement_retract` | `{work_fingerprint, club_id, token_id}` | `{}` |
| `0x1804` | `endorsement_query` | `{work_fingerprint}` | Endorsement list |
| `0x1805` | `state_sync` | `{work_fingerprints: []}` (empty = all) | ReconcileState list |
| `0x1806` | `state_alternatives` | `{work_fingerprint}` | Alternative list + current key |

All operations require federation to be enabled.

### Server-to-Server Frames (via /federation WebSocket)

| Frame | Direction | Purpose |
|-------|-----------|---------|
| `EndorsementSyncPush` | Initiator → Responder | Push endorsement OR-Sets |
| `EndorsementSyncResult` | Responder → Initiator | Return merged endorsements |
| `StateSyncPush` | Initiator → Responder | Push ReconcileStates |
| `StateSyncResult` | Responder → Initiator | Return merged states |

These frames are encrypted with ChaCha20Poly1305 (part of the existing
federation encrypted channel).

## Test Coverage

### Unit Tests (29 new)

**OR-Set CRDT (17 tests):**
- add and contains, idempotent add, same value different tags
- remove specific tag, remove all tags, remove nonexistent
- merge union, merge tombstones, merge commutative, merge idempotent
- tombstone prevents re-add, different tag survives tombstone
- import entries, import tombstone removes existing
- tag display, serialize roundtrip, three-way merge converges

**LWW-Register CRDT (12 tests):**
- new and read, set higher/lower timestamp, tiebreak
- same timestamp same server rejected, merge higher timestamp
- merge commutative, merge idempotent, snapshot roundtrip
- serialize roundtrip, value_eq, three-way merge converges

**ReconcileState (12 tests):**
- new, current edition text, add alternative, add duplicate ignored
- set current LWW, set current lower rejected
- merge union alternatives, merge LWW current, merge endorsements
- all alternatives, serialize roundtrip

**ReconcileStore (8 tests):**
- new empty, get or create, get or create idempotent, get
- merge remote creates new, merge remote adds alternatives
- fingerprints, three-way merge converges, serialize roundtrip

**EndorsementEntry (2 tests):**
- new, hash and equality

**Server Reconcile Methods (7 tests):**
- records on create work, records on revise
- merge remote adds alternatives, endorse via OR-Set
- retract via OR-Set, export and merge endorsements, next tag unique

### Integration Tests (5 new)

- `endorsement_add_returns_tag` -- wire protocol add endorsement
- `endorsement_query_returns_added_endorsements` -- wire protocol query
- `state_sync_returns_reconcile_states` -- wire protocol state sync
- `state_alternatives_returns_editions` -- wire protocol alternatives
- `reconcile_merge_across_servers` -- cross-server merge via direct API

## Files Changed

| File | Changes |
|------|---------|
| `src/server/federation.rs` | OrSet, LwwRegister, AlternativeEdition, ReconcileState, ReconcileStore, EndorsementEntry, OrSetTag, OrSetEntry, LwwSnapshot + 29 unit tests |
| `src/server/server.rs` | reconcile_store + reconcile_counter fields, reconcile_* methods, hooks in create_work/work_revise/edition_set_single + 7 unit tests |
| `src/server/mod.rs` | Updated re-exports for new types |
| `src/server/transport/protocol.rs` | OperationCodes 0x1801-0x1806, WireRequest variants, ResponseValue variants |
| `src/server/transport/dispatch.rs` | Dispatch handlers for 6 new operations |
| `src/server/transport/codec.rs` | JSON codec entries for 6 new operations |
| `src/server/transport/federation_handler.rs` | EndorsementSyncPush/Result, StateSyncPush/Result frames + handlers |
| `tests/integration.rs` | 5 new integration tests |

## Future Work (Phase 19+)

- **Persistence**: ReconcileState serialization in server snapshots
- **Endorsement persistence**: Endorsement OR-Sets serialized to disk
- **3-server concurrent edit test**: Full end-to-end with federation transport
- **DagWood branch merge**: Creating cross-server merge positions in the DagWood
- **AlternativeSet materialization**: Rendering AlternativeSet in client API
- **Governance**: PBFT for membership operations
