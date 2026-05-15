# CRDT Collaborative Editing

## Overview

Xudanu uses [yrs](https://crates.io/crates/yrs) v0.25.0 — the Rust port of
[Yjs](https://yjs.dev/) — as its CRDT engine for real-time collaborative
editing. Multiple users can edit the same document simultaneously without
locks, conflicts, or data loss.

## What is CRDT?

**Conflict-free Replicated Data Types** (CRDTs) are data structures that can
be replicated across multiple systems and merged automatically without
coordination. The key property: no matter what order updates arrive in, all
replicas converge to the same state.

For text editing, the CRDT tracks each character insertion and deletion as an
immutable operation. When two users type at the same position concurrently,
both insertions are preserved — the CRDT decides deterministically which comes
first based on a logical clock, not on wall-clock timestamps.

The specific algorithm used by yrs/Yjs is **YATA** (Yet Another Transformation
Approach), which maintains a doubly-linked list of character items, each tagged
with an origin that tracks what the document looked like when the item was
inserted. This allows correct interleaving even for out-of-order delivery.

## Architecture

```
┌──────────────────────────────────────────────────┐
│  Browser (Preact UI)                             │
│  ├── contentEditable div                         │
│  ├── computeDelta() → TextDeltaOp (retain/ins/del)│
│  ├── 1.5s auto-save debounce                     │
│  └── 2s CRDT poll (crdt_sync_text)              │
├──────────────────────────────────────────────────┤
│  WebSocket (JSON protocol)                       │
├──────────────────────────────────────────────────┤
│  Server                                          │
│  ├── CrdtManager (per-work yrs::Doc instances)   │
│  │   ├── yrs::TextRef "main" per work            │
│  │   ├── subscriber map (SessionId → SyncId)     │
│  │   └── awareness state per session             │
│  ├── work_revise_delta → CRDT path (when active) │
│  ├── Materialization: yrs text → Edition         │
│  └── revise_work → O-tree revision + events      │
├──────────────────────────────────────────────────┤
│  Federation (binary CRDT update blobs)           │
└──────────────────────────────────────────────────┘
```

## How It Works

### Session Lifecycle

1. User opens a document → `crdt_sync_open` creates a CRDT session
2. If no CRDT doc exists for this work, one is created from the current
   edition text
3. If a CRDT doc already exists (another user is editing), the new session
   joins it and receives the current CRDT text
4. Any pending (unmaterialized) changes are materialized before the new
   session joins, ensuring the latecomer sees the latest state

### The Edit Loop

1. User types in the contentEditable div
2. After 1.5 seconds of inactivity, `computeDelta()` computes the diff
   between the last saved text and the current editor text as a sequence of
   `TextDeltaOp` operations: `{type:"retain",count:N}`,
   `{type:"insert",text:"..."}`, `{type:"delete",count:N}`
3. The delta is sent as `work_revise_delta` over WebSocket
4. **If a CRDT session is active** for this work, the server applies the
   delta directly to the yrs `TextRef`, merges it with concurrent edits from
   other users, and immediately materializes the result as a new Edition
5. **If no CRDT session is active** (single user, no `crdt_sync_open` called),
   the old path applies the delta to the edition directly

### Sync Between Tabs

There is no server-push to other tabs. Instead:

- Each tab polls `crdt_sync_text` every 2 seconds to fetch the current CRDT
  text
- The poll only updates the editor if the user has no unsaved local changes
  (`currentTextRef === lastSavedRef`), preventing mid-typing overwrites
- When a `WorkRevised` event fires (from materialization), the existing
  subscription mechanism delivers it to all tabs, triggering an edition
  re-fetch

### Materialization

Materialization is the process of converting the CRDT text back into an
`Edition` (the O-tree representation) and persisting it as a new revision.

Materialization happens:

- **Immediately** on every `work_revise_delta` through the CRDT path (the
  client already debounces at 1.5s)
- **On session join** if pending changes exist (so latecomers see latest text)
- **On session close** if pending changes exist (preventing data loss when
  navigating away)

The materialization process:

1. Read the merged text from `yrs::TextRef`
2. Convert to `Edition` via `Edition::from_text()`
3. Call `revise_work()` which stores the new O-tree revision and fires
   `WorkRevised` events

### Session Closure

When a user navigates away from a document, `crdt_sync_close` is called:

1. Any pending CRDT changes are materialized and saved
2. The session is removed from the subscriber map
3. If this was the last subscriber, the CRDT doc is destroyed (all changes
   have been materialized, so nothing is lost)

## Impact on the Edition Model

The CRDT layer sits **above** the Edition layer. Editions are materialized
snapshots of the CRDT state:

```
CRDT (yrs::TextRef) ──materialize──→ Edition (O-tree) ──revise──→ Revision
```

### What is Preserved

- **Text content**: all character-level edits are merged correctly
- **Revision history**: each materialization creates a proper O-tree revision
- **Content addressing**: the GrandMap still deduplicates text fragments
- **Transclusion**: `find_text_transcluders` searches both CRDT text (for
  active sessions) and edition text (for materialized works)
- **Federation**: binary CRDT update blobs can be exchanged between servers

### What is Lost (Currently)

When text passes through the CRDT layer and back, only the `Text` element type
survives the round-trip:

| Element | Survives CRDT? | Reason |
|---------|---------------|--------|
| `Text` | Yes | Plain text is what yrs stores |
| `Data` | No | No CRDT equivalent |
| `Blob` | No | Image/file references not tracked |
| `Overlay` | No | Derived images not tracked |
| `Label` | No | Labels not part of text content |
| `Work` (transclusion) | No | Inter-doc links not tracked |

This means the CRDT path is **text-only** for now. Blob markers (`[img:...]`,
`[overlay:...]`) embedded in text will survive as literal text strings, but
their structured meaning is lost until we extend the CRDT to support rich
elements.

### Revision Density

Each auto-save (1.5s after the user stops typing) creates one revision. This
is more granular than the previous grab/edit/save/release workflow, which
created one revision per explicit save. Users can use the revision slider to
navigate through this finer-grained history.

## UTF-16 Position Handling

yrs uses **UTF-16 code unit offsets** internally (for JavaScript
compatibility). The JavaScript client naturally produces UTF-16 positions
(`String.length` and `charCodeAt` are UTF-16-based), and the Rust server
must advance cursor positions using UTF-16 lengths, not byte lengths:

```rust
fn utf16_len(s: &str) -> usize {
    s.chars().map(|c| c.len_utf16()).sum()
}
```

For ASCII text, UTF-16 length equals byte length. For emoji and multi-byte
characters, they differ:

| Character | UTF-8 bytes | UTF-16 units | `String.length` (JS) |
|-----------|------------|-------------|---------------------|
| `a` | 1 | 1 | 1 |
| `é` | 2 | 1 | 1 |
| `🌍` | 4 | 2 | 2 |
| `👨‍👩‍👧‍👦` | 25 | 11 | 11 |

The `apply_text_delta` method uses `utf16_len()` after inserts to maintain
correct position tracking with yrs.

## Wire Protocol

CRDT operations use the `0x1Cxx` opcode range in the binary protocol, and
snake_case operation names in the JSON protocol:

| Opcode | Name | Purpose |
|--------|------|---------|
| 0x1C01 | `crdt_sync_open` | Join CRDT session for a work |
| 0x1C02 | `crdt_sync_close` | Leave CRDT session |
| 0x1C03 | `crdt_sync_update` | Apply raw yrs update blob |
| 0x1C04 | `crdt_sync_diff` | Get incremental diff since state vector |
| 0x1C05 | `crdt_sync_full_state` | Get complete CRDT state |
| 0x1C06 | `crdt_sync_materialize` | Force materialization now |
| 0x1C07 | `crdt_sync_subscriber_count` | Query active editors |
| 0x1C08 | `crdt_awareness_update` | Update cursor/presence state |
| 0x1C09 | `crdt_awareness_get` | Query all presence states |
| 0x1C0A | `crdt_sync_text` | Get current merged text (polling) |

The primary path for the embedded UI is `work_revise_delta` (existing opcode)
which is routed through the CRDT layer when a session is active. The CRDT
opcodes above are used for advanced clients (WASM, React app) that manage
their own yrs Document instances.

## Federation

CRDT updates can be exchanged between federated servers:

- `extract_update_for_federation()` produces a binary diff since last
  materialization
- `apply_federation_update()` applies incoming updates using a synthetic
  `SessionId(u64::MAX)` that never appears in subscriber lists
- Federation frames carry `CrdtWorkUpdate` structs with the work ID and
  binary update bytes
- Server authentication validates the `server_id` claim against the
  authenticated peer

## Awareness

Awareness (cursors, typing indicators, user presence) is stored per-session
in the CRDT manager, not using the yrs Awareness type. This is a simple
last-write-wins model:

- Each session maintains its own `AwarenessState` (cursor position,
  selection range, typing flag)
- Updates are relayed to other subscribers via the `relay_to` mechanism
- Awareness is cleaned up on session close

## Key Files

| File | Purpose |
|------|---------|
| `src/server/crdt_manager.rs` | `CrdtManager`, `WorkDoc`, sync sessions, text delta application |
| `src/server/server.rs` | Server wrappers: `crdt_open_session`, `crdt_close_session`, `crdt_apply_text_delta`, materialization hooks |
| `src/server/transport/dispatch.rs` | Request routing: CRDT path for `work_revise_delta`, `crdt_sync_text` |
| `src/server/transport/protocol.rs` | Operation codes, `TextDeltaOp`, response types |
| `src/server/transport/codec.rs` | Binary + JSON codec for CRDT operations |
| `src/server/federation.rs` | `CrdtWorkUpdate`, `CrdtSyncResult` for cross-server sync |
| `static/index.html` | Embedded Preact UI with auto-save, CRDT poll, sync status indicator |

## Dependencies

```toml
[dependencies]
yrs = "0.25"   # CRDT engine (Yjs Rust port, MIT license)
```

## References

- [yrs crate](https://crates.io/crates/yrs) — Rust implementation
- [y-crdt GitHub](https://github.com/y-crdt/y-crdt) — Source and documentation
- [Yjs](https://yjs.dev/) — JavaScript original
- [YATA paper](https://www.researchgate.net/publication/310212186) — The CRDT
  algorithm behind Yjs
- [CRDTs: The Hard Problems](https://jakelazaroff.com/words/the-hard-problems-in-collaborative-editing/) — Practical challenges in CRDT editors
