# Server Concurrency Plan

## Current State

The server uses a single `std::sync::Mutex<Server>` protecting ALL state for ALL users.
Every request — read or write — acquires this exclusive lock, serializing all operations.

```
User A ──WS──► tokio task ──► dispatch() ──┐
User B ──WS──► tokio task ──► dispatch() ──┤──► std::sync::Mutex<Server>
User C ──WS──► tokio task ──► dispatch() ──┘
```

### Key Bottlenecks

| Bottleneck | Location | Impact |
|-----------|----------|--------|
| Single global mutex | `shared.rs:101` | All users contend on one lock |
| Checkpoint under lock | `server.rs:3995-4018` | fsync blocks all users ~100ms+ |
| CRDT materialization under lock | `server.rs:2689-2711` | Crypto + edition clone blocks all |
| Synchronous blob I/O under lock | `blob_store.rs`, `chunk_store.rs` | File reads/writes block all |
| No RwLock for reads | N/A | Read queries block other reads |

### Well-Designed Areas (keep these patterns)

| Area | Location | Why it's good |
|------|----------|---------------|
| LLM operations | `dispatch.rs:55-213` | Lock released during LLM calls |
| WebSocket writer task | `handler.rs:403-445` | Separate tokio task, no lock |
| Event relay | `channel.rs` | Non-blocking mpsc channels |
| Session sender registry | `shared.rs:49-77` | Separate mutex, short holds |

---

## Phase 1: Quick Wins

### 1a: Background Checkpoints (not yet implemented)

Move `auto_checkpoint()` out of the dispatch path:

- Set a dirty flag during mutations (fast, under write lock)
- Background tokio task checks every 30s
- Acquires read lock briefly to snapshot dirty data
- Releases lock, does serialization + fsync
- Re-acquires write lock briefly to clear dirty flag

### 1b: Mutex → RwLock (implemented here)

Replace `std::sync::Mutex<Server>` with `std::sync::RwLock<Server>`:

- Read operations take read lock (concurrent with other reads)
- Write operations take write lock (exclusive, as before)
- ~40% of operations are read-only → immediate concurrency win

**Read-only operations** (read lock):
- WorkList, WorkListByOwner, WorkListByAuthor
- WorkGetEdition, WorkFetchRevision
- WorkOwner, WorkRevisionCount, WorkIsGrabbed, WorkGrabber
- WorkCanRead, WorkCanRevise, WorkReadClub, WorkEditClub, WorkSponsors
- ServerStats, ServerGetById, ServerGetByBeId
- ClubGet, ClubByName, ClubIdByName, ClubNameById, ClubNames, ClubMembers
- WorkTextRange, WorkOutline, WorkSearch, WorkGoto
- AttributionQuery, AttributionLogStatus, AttributionVerify
- HistoricalAuthorGet, HistoricalAuthorSearch, HistoricalAuthorList
- SourcePatternList, SourceDetect
- ContentMatch, FindSharedRegions, FindExcerptPositions
- BlobGet, BlobGetPreview, BlobExists, BlobInfo, BlobStats
- LinkGet, LinkListForWork
- VersionIsBefore, VersionAncestors, VersionDescendants, ProvenanceAncestry
- CompoundResolve, RangeTranscluders, TransclusionDepth, OrderedBundles, RangeWorks
- CryptoGetPublicKey, CryptoKeyHistory
- ClubWhoAmI

**Write operations** (write lock):
- SessionConnect, SessionDisconnect, SessionLogin, SessionLoginPublic, SessionAuthenticate
- WorkCreate, WorkRevise, WorkReviseDelta
- WorkGrab, WorkRelease, WorkSaveAndRelease, WorkForceRelease
- WorkSetReadClub, WorkSetEditClub, WorkSponsor, WorkUnsponsor
- WorkPublish, WorkUnpublish, WorkIrrevocablyUnpublish
- ClubCreate, ClubCreateNamed, ClubCreatePersonal
- ClubAddMember, ClubRemoveMember, ClubSetPassword, ClubClearCredential
- CrdtSyncOpen, CrdtSyncClose, CrdtSyncUpdate, CrdtSyncDiff, CrdtSyncFullState
- CrdtSyncMaterialize, CrdtSyncSubscriberCount, CrdtSyncText
- BlobUpload, OverlayApply
- LinkCreate, LinkDelete
- ImportSourceWork, WorkApplySourceAttribution, WorkApplyTransclusionAttribution
- HistoricalAuthorRegister
- EditionStore, EditionGet
- BlobExists (writes to cache), BlobInfo (writes to cache)
- All admin operations
- All federation/governance/membership operations

### 1c: Async Blob/Chunk I/O (deferred)

- Replace `std::fs` with `tokio::fs` in ChunkStore and BlobStore
- Deferred because it requires async dispatch path (Phase 3) or snapshot pattern
- Phase 1a addresses the heaviest I/O (checkpoints) without this change

---

## Phase 2: Per-Work Sharding (future)

- Each work gets its own `RwLock<WorkState>`
- Operations on Work 5 don't block operations on Work 6
- Global lock only for cross-work operations (work_list, clubs, checkpoint)
- CRDT manager gets per-document locks

## Phase 3: Async Dispatch (future)

- Switch to `tokio::sync::RwLock<Server>`
- Dispatch becomes fully async — tokio serves other connections while one waits
- Requires refactoring `with_server` from `FnOnce` closure to async method
- Enables async I/O throughout

---

## Rust Concurrency Reference

### Lock Types

| Type | Thread-safe | Blocks runtime | Use case |
|------|------------|----------------|----------|
| `std::sync::Mutex` | Yes | Yes | Short synchronous critical sections |
| `std::sync::RwLock` | Yes | Yes | Read-heavy synchronous workloads |
| `tokio::sync::Mutex` | Yes | No (yields) | Must hold across .await |
| `tokio::sync::RwLock` | Yes | No (yields) | Async read-heavy workloads |

### Golden Rules

1. Never hold `std::sync` locks across `.await` points
2. Keep `std::sync` lock hold times short (< 1ms ideal)
3. When in doubt about read vs write, use write lock
4. `std::sync::RwLock` can suffer writer starvation — keep writes fast
5. Prefer fine-grained locks over coarse-grained

### Why std::sync over tokio::sync for our case

Our dispatch uses `FnOnce` closures (not async), so we can't use `tokio::sync` locks.
`std::sync::RwLock` is the right choice until we refactor dispatch to be async (Phase 3).
