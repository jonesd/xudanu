# FR-8: True Position-Based CRDT

## Status: Design Document
## Target: v0.10.0+
## Priority: High — core architecture

## Motivation

The current O-tree CRDT (v0.9.x) uses server-side three-way merge with
sequential character positions. This works for non-overlapping concurrent
edits but has limitations:

1. **Position shift**: When user A inserts text, user B's delta positions
   become stale (mitigated by per-session base tracking in v0.9.2, but
   not fully resolved)
2. **LWW data loss**: When two users edit the same region, the earlier
   edit is lost
3. **No offline editing**: Clients cannot edit without a server connection
4. **No peer-to-peer**: All edits must flow through a single server

A true position-based CRDT eliminates these limitations by using immutable
position identifiers instead of sequential character indices.

## Design

### Core Principle

Each character in the document has an immutable **O-tree position** assigned
at creation time. Operations reference positions, not sequential indices.
Positions never change when other characters are inserted or deleted.

```
Current (v0.9.x):   Retain { count: 18 }, Insert { text: " world" }
FR-8:              Retain { positions: [p1..p18] }, Insert { after: p18, text: " world" }
```

### Wire Protocol Changes

#### New operation format

```json
{
  "op": "crdt_position_delta",
  "payload": {
    "work_id": 1060,
    "base_revision": 5,
    "ops": [
      { "type": "retain", "positions": [[0,0], [0,1], [0,2]] },
      { "type": "insert", "after": [0,2], "text": "hello", "origin": "session-42" },
      { "type": "delete", "positions": [[0,5], [0,6]] }
    ]
  }
}
```

Positions are O-tree region coordinates (e.g., `[branch, offset]`).

#### Delete = Tombstone

Deleted characters are marked as tombstones, not removed. This preserves
position stability for other clients that may still reference them.

Tombstones are invisible in the rendered text but present in the data model.
Periodic compaction removes tombstones that no client references.

### Data Model Changes

#### O-tree entries

Each entry gains a permanent identifier:

```rust
struct OtreeEntry {
    position: XnPosition,      // immutable, assigned at creation
    element: RangeElement,
    origin_session: SessionId, // who created this entry
    origin_timestamp: u64,     // when (for causal ordering)
    is_tombstone: bool,        // deleted but not removed
    tombstone_after: Option<u64>, // revision when deleted
}
```

#### Causal ordering

Each operation carries a **vector clock** — a map of `{session_id: operation_count}`.
This enables:
- Detecting concurrent operations
- Ordering operations deterministically
- Supporting offline sync (operations queue and apply in causal order)

### Client Changes

The client maintains a **position map** alongside the text buffer:

```typescript
interface PositionEntry {
  position: number[];     // O-tree position
  isTombstone: boolean;
  originSession: number;
}

class PositionAwareBuffer {
  private text: string;
  private positions: PositionEntry[];
  
  applyInsert(after: number[], text: string, origin: number): void {
    // Find position in local array
    // Insert text and position entries
    // Position is deterministic: [parent_position, timestamp, origin]
  }
  
  applyDelete(positions: number[][]): void {
    // Mark entries as tombstone
    // Update visible text
  }
  
  toDelta(): PositionDelta {
    // Convert local changes to position-based delta
  }
}
```

### Server Changes

The server becomes a **relay and compaction engine**:

1. Receive position-based delta from client
2. Apply to O-tree using immutable positions (no merge needed)
3. Relay to other subscribers
4. Periodically compact tombstones

No three-way merge needed — operations are commutative by construction.

### Federation Support

Position-based operations are naturally distributable:

1. Server A accepts edit from client
2. Server A relays to Server B via federation sync
3. Server B applies to its replica
4. Both replicas converge — guaranteed by CRDT properties

This enables true multi-server editing — the Xanadu docuverse vision.

### Compaction

Tombstones accumulate over time. Compaction removes them:

1. **Trigger**: When tombstone ratio exceeds 30% of total entries
2. **Process**: Create new edition without tombstones
3. **Position remap**: Build mapping from old positions to new
4. **Client notification**: Send `crdt_compacted` event with remap table
5. **Safety**: Only compact tombstones older than N revisions (ensures
   all clients have seen the delete)

### Convergence Guarantees

**Theorem**: Given any two replicas that have received the same set of
operations (in any order), the rendered text is identical.

**Proof sketch**: 
- Insert operations are uniquely identified by `(position, origin, timestamp)`
- Delete operations are idempotent (tombstone marking)
- Retain operations preserve order
- Operations commute because positions are immutable

## Implementation Plan

### Phase 1: Position Protocol (4-6 weeks)

- [ ] Define position-based wire protocol (`crdt_position_delta`)
- [ ] Implement `PositionAwareBuffer` on client
- [ ] Implement position-based apply on server
- [ ] Migrate from sequential deltas (backward compatible)
- [ ] Test convergence with 2+ clients

### Phase 2: Offline Support (2-3 weeks)

- [ ] Local operation queue (IndexedDB)
- [ ] Causal ordering via vector clocks
- [ ] Sync protocol (request missing operations)
- [ ] Conflict-free convergence test suite

### Phase 3: Tombstone Compaction (2 weeks)

- [ ] Tombstone tracking
- [ ] Compaction trigger and process
- [ ] Client position remap
- [ ] Automated compaction scheduling

### Phase 4: Federation Sync (4-6 weeks)

- [ ] Cross-server operation relay
- [ ] Causal ordering across servers
- [ ] Anti-entropy gossip protocol
- [ ] Partition recovery

## Comparison: v0.9.x vs FR-8

| Dimension | v0.9.x (Three-way merge) | FR-8 (Position CRDT) |
|-----------|--------------------------|----------------------|
| Position format | Sequential index | Immutable O-tree position |
| Conflict resolution | LWW (may lose data) | Conflict-free (never loses) |
| Merge algorithm | Three-way fingerprint | None needed |
| Offline editing | Not supported | Fully supported |
| Peer-to-peer | Not supported | Supported |
| Memory overhead | None | Tombstones + position metadata |
| Network overhead | Small deltas | Larger (positions) but compressible |
| Client complexity | Low (sequential) | Medium (position tracking) |
| Server complexity | Medium (merge logic) | Low (relay + apply) |
| Convergence proof | Empirical | Mathematical |

## Compatibility

FR-8 is designed to coexist with v0.9.x:
- Clients that support position deltas send `crdt_position_delta`
- Clients that don't send `work_revise_delta` (sequential)
- Server translates between formats
- Gradual migration — no flag day

## Risks

1. **Position metadata size**: Each position is ~8-16 bytes. For a 100K
   document, that's 800KB-1.6MB of metadata. Mitigation: compression,
   position pooling.

2. **Tombstone accumulation**: Without compaction, deleted text remains
   forever. Mitigation: automatic compaction at 30% tombstone ratio.

3. **Client complexity**: Tracking positions adds client-side complexity.
   Mitigation: provide a `PositionAwareBuffer` library that handles this
   transparently.

4. **Protocol migration**: Running both protocols simultaneously increases
   server load. Mitigation: feature detection + gradual rollout.

## Success Criteria

- [ ] Two clients editing the same paragraph simultaneously — both edits
      preserved (no data loss)
- [ ] Client disconnects, edits offline for 10 minutes, reconnects —
      edits sync without conflict
- [ ] Two servers accept edits independently, sync converges to identical
      state
- [ ] 10 concurrent users editing a 10K-word document — no data loss,
      sub-second latency
- [ ] Mathematical convergence proof (all replicas eventually identical)

## References

- Shapiro et al., "A comprehensive study of Convergent and Commutative
  Replicated Data Types" (2011) — theoretical foundation
- Yjs (yjs.dev) — production CRDT library for collaborative editing
- Automerge (automerge.org) — JSON CRDT with offline support
- Figma engineering blog — multiplayer CRDT at scale
- Original Udanax-Gold enfilade theory — immutable position heritage
