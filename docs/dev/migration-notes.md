# Migration Notes: Udanax Gold C++ → Xudanu Rust

## Phase 2: Edition / XnRegion / RangeElement

### What was implemented

Three new modules under `src/edition/`:

| Module | C++ Original | Rust Implementation |
|---|---|---|
| `xn_region.rs` | `IntegerRegion` (integerx.hxx) | `XnRegion` — transition-array encoding of integer sets |
| `range_element.rs` | `FeRangeElement` hierarchy (nkernelx.hxx) | `RangeElement` enum with Data, Text, Edition, Label, PlaceHolder, IDHolder, Work |
| `edition.rs` | `FeEdition` / `BeEdition` (nkernelx.hxx, brange3x.hxx) | `Edition` — wraps `OrglRoot` O-tree |

### Design decisions

1. **XnRegion uses transition arrays** (same as Gold's `IntegerRegion`): `(starts_inside: bool, transitions: Vec<i64>)`. This gives O(log n) `contains()` via binary search and clean set operations via sorted-merge.

2. **RangeElement is an enum**. Gold uses a deep class hierarchy (FeDataHolder, FeEdition, FePlaceHolder, FeLabel, FeIDHolder, FeWork). Rust's enum is more natural and avoids heap allocation.

3. **Carrier pairs element + optional label**. Mirrors Gold's `BeCarrier` which pairs a `BeRangeElement` with an optional `BeLabel`.

## Foundation Hardening: O-tree Implementation

### What was implemented

A fourth module under `src/edition/`:

| Module | C++ Original | Rust Implementation |
|---|---|---|
| `orgl.rs` | `OrglRoot` / `Loaf` / `InnerLoaf` / `OExpandingLoaf` (orootx.hxx, loavesx.hxx) | `OrglRoot` (Empty/Actual) + `Loaf` enum (Leaf/Split) with splay algorithm |

### O-tree architecture

The O-tree is Gold's persistent splay tree for Edition content. Our Rust port:

- **Loaf** is a Rust enum: `Leaf { region, entries }` or `Split { split, in_child, out_child }`
  - `Leaf` stores sorted `(i64, Arc<Carrier>)` pairs with a domain `XnRegion`
  - `Split` partitions space by a `XnRegion` into in/out children
  - Leaves auto-split when they exceed `MAX_LEAF_SIZE` (16384, matching Gold's `tableSegmentMaxSize`)
- **OrglRoot** wraps a `Loaf` (or is Empty), providing the Edition-level API
- **Splay algorithm** (9-case transformation table from SplitLoaf::actualSplay) is fully implemented:
  - `splay(region)` restructures the tree so the region is at/near the root
  - Returns `SplayResult::Outside / Partial / FullyContained`
  - Handles rotate-right, rotate-left, interleave, and swap operations

### Edition now uses OrglRoot internally

`Edition` was rewritten to wrap `OrglRoot` instead of `BTreeMap`:

- `fetch()` now returns `Option<RangeElement>` (owned) instead of `Option<&RangeElement>` (borrowed)
- All mutation methods (`with`, `without`, `replace`) use structural sharing via the O-tree
- Auto-splits leaves when they exceed 16384 entries
- Stress test: 50,000 positions in ~38 seconds including splay operations

### Simplifications from Gold's O-tree

| Gold Feature | Rust Status |
|---|---|
| DspLoaf (transform wrapper) | Done — `Loaf::Dsp` variant, `transformed_by` returns O(1) Dsp |
| OPartialLoaf (placeholder with TrailBlazer) | Simplified: Leaf stores explicit entries |
| OVirtualLoaf (backed by SharedData) | Simplified: Leaf stores explicit entries |
| RegionLoaf (points to BeRangeElement) | Simplified: Leaf stores explicit entries |
| H-tree (history/version tracking) | Not yet; needed for transclusion backfollow |
| Sensor crum / Bert crum (canopy indices) | Not yet; needed for transclusion queries |
| In-place mutation (placement new) | Rust enum variant replacement instead |

### Portability gaps (Gold features not yet in Rust)

| Gap | Gold Feature | Rust Status | Plan |
|---|---|---|---|
| Infinite-domain Editions | Editions can map infinite regions (e.g., `above(5) → constant`) | Done — Leaf default + tombstone entries | Complete |
| H-tree / history tracking | Version tracking parallel to O-tree for backfollow | Done — `HUpperCrumData` with canopy integration | Complete |
| Sensor crum / Bert crum (canopy indices) | Canopy trees for filtering transclusion queries | Done — `BertCanopy`/`SensorCanopy` with flag propagation | Complete |
| CoordinateSpace abstraction | Generic Position/Region across IntegerSpace, RealSpace, SequenceSpace, CrossSpace | Only integer positions (i64) | Add when needed; integer is the dominant case |
| Stepper / retrieve | `edition->stepper(region, order)` for filtered iteration | `iter()` only, no region filter | Add `iter_in_region()` method |
| Bundle retrieval | `retrieve()` returns Array/Element/PlaceHolder bundles | Not implemented | Add when needed for bulk reads |
| Fe/Be split | FrontEnd (session) / BackEnd (persistent) object split | Done — `BeRangeElement` trait + `InMemoryBeStorage` | Disk backing in Phase 6 |
| Admin API | `FeAdminer` — acceptConnections, shutdown, grants, activeSessions | Done — `AdminState` + wire ops | GateLockSmith in Phase 11 |
| Handshake | `SetCommProtocol` / `BootPlan` — version negotiation | Done — `HandshakeResponse` at WS start | Sufficient for v1 |
| Detector wire | `CommXxxDetector` + `DetectorEvent` — push events to client | Partial — subscription tracking + event push | Per-type filtering + queuing |
| Work (mutable container) | `FeWork` holds current edition + revision history | Done — `Work` with revise/history/clubs/sponsors | Complete |
| GrandMap (ID registry) | `BeGrandMap` bidirectional ID ↔ BeRangeElement | Done — `GrandMap` with IdSpace, assign_id, fetch | Complete |
| Content Pool | Content-addressed storage for RangeElements | Done — `ContentPool` with hash-based store/retrieve/find | Complete |
| Transclusion queries | `transcluders()`, `works()`, `rangeTranscluders()` | Done — `BackfollowEngine` orchestrates full query pipeline | Complete |
| Permissions / endorsements | `BertProp`, `SensorProp`, endorsement/permission spaces | Done — flag-based props with endorsement bit allocation | Complete |
| Canopy tree (Bert/Sensor) | `CanopyCrum`, `BertCrum`, `SensorCrum` | Done — Rc<RefCell<>> balanced binary tree with flag propagation | Complete |
| H-tree (version tracking) | `HistoryCrum`, `HUpperCrum`, `HBottomCrum` | Done — HUpperCrumData with delayed_store_backfollow walk | Complete |
| Backfollow engine | `RecorderFossil`, `ResultRecorder`, `Matcher`, `TrailBlazer` | Done — synchronous in-memory BackfollowEngine | Complete |
| Label propagation | `positionsLabelled()`, `rebind()`, label identity tracking | Label exists on Carrier but no propagation API | Add in future phase |
| DspLoaf (transform wrapper) | Lazy displacement without rebuilding tree | Done — `Loaf::Dsp` variant | Complete |

### Enhancement ideas for future phases

1. **yrs/CRDT as transport layer**: The Edition model maps naturally to yrs `Doc` with `Text` sequences. An Edition could be materialized into a yrs document for real-time sync, while maintaining the Gold partial ordering for conflict preservation.

2. **Content-addressed storage**: Done — `ContentPool` implements hash-based store/retrieve/find_by_content.

3. **Compressed transition arrays**: For very large regions, run-length encoding with 32-bit deltas could reduce memory usage.

4. **DspLoaf for lazy transforms**: Done — `Loaf::Dsp` wraps child with offset. Splay materializes back to concrete nodes.

5. **Parallel region operations**: `merge_transitions` could be parallelized for large regions using rayon.

6. **Fe/Be trait boundary**: Done — `BeRangeElement` trait with identity, owner, clone_boxed. `InMemoryBeStorage` (HashMap-backed) with `Clone` for GrandMap integration.

7. **Identity-based shared_region**: Done — `Edition::identity_shared_region(other, id_eq)` compares by identity (be_id) instead of value (PartialEq).foundation for transclusion.

### Gold test cases ported

- **Region**: 6 canonical example regions × 10 unary checks + 15 pairs × 8 binary checks = all Gold RegionTester checks pass
- **Edition**: 14 test cases from `makeEditionTestOn`, `editionTestOn`, and `compareTestOn` in nkernelt.cxx
- **O-tree**: 22 tests for Loaf/OrglRoot (splay, split, combine, copy, domain, fetch, etc.)
- **Stress**: 50K position edition, 10K splay operation
- **Total**: 212 tests (114 ent + 98 edition), all passing

### Test history

| Phase | Tests | Notes |
|---|---|---|
| Phase 2 initial | 189 | BTreeMap-based Edition |
| Foundation hardening | 212 | O-tree based Edition, all Gold tests preserved |
| DspLoaf + Infinite + Fe/Be | 245 | DspLoaf lazy transforms, infinite domains, backend traits |
| Phase 3: GrandMap/Work/Pool | 285 | GrandMap, Work, ContentPool, identity-based shared_region |
| Phase 4: Transclusion | 367 | Props, Canopy, H-tree, TransclusionIndex, BackfollowEngine, EditionMeta |
| Phase 5: Links | 401 | HyperLink, HyperRef (Single/Multi), Path, link-aware transclusion queries |
| Phase 6: Persistence | 477 | Abraham/Shepherd → Persistent trait, SnarfStorage, Counter, Transaction, PersistentWork/Edition round-trip |

## Phase 6: Persistence Layer

### What was implemented

A complete persistence layer faithful to Gold's architecture, ported to Rust idioms:

| Module | C++ Original | Rust Implementation |
|---|---|---|
| `persist/persistent.rs` | Abraham/FlockInfo/FlockLocation (shephx.hxx, flkinfox.hxx) | `FlockId`, `FlockInfo` (bitflags), `FlockLocation`, `FlockState` enum |
| `persist/traits.rs` | Abraham base class + Heaper hierarchy | `Persistent` trait (flock_id, flock_info, type_tag, to_bytes), `PersistentRef<T>`, `PersistentRegistry`, `TypeRegistry` (category/recipe dispatch), `encode_flock`/`decode_flock` |
| `persist/engine.rs` | DiskManager abstract interface | `StorageEngine` trait (store_new, disk_update, remember, forget, destroy, dismantle, begin/end_transaction, commit, rollback) |
| `persist/memory.rs` | In-memory stub for testing | `InMemoryStorage` — full StorageEngine impl with transaction support and rollback |
| `persist/snarf.rs` | SnarfHandler/SnarfInfoHandler (snfinfox.hxx) | `Snarf` (faithful on-disk layout: header + map table + flock data), `SnarfStore` (multi-snarf management with forwarding) |
| `persist/packer.rs` | SnarfPacker (packerx.hxx) | `SnarfStorage` — full StorageEngine with type-tagged serialization, forwarding on resize, destroy processing |
| `persist/counter.rs` | Counter/BatchCounter/SingleCounter (counterx.hxx) | `Counter`, `BatchCounter` (batch pre-allocation), `SingleCounter` |
| `persist/transaction.rs` | BEGIN_CONSISTENT/END_CONSISTENT macros | `Transaction` guard (RAII, auto-rollback on drop) |
| `edition/persistent.rs` | BeWork/BeEdition serialization (brange2x, brange3x) | `PersistentWork`, `PersistentEdition` with serde-based snapshot serialization |

### Architecture decisions

1. **`Persistent` trait replaces Abraham** — No inheritance. Rust trait with `type_tag()` + `to_bytes()` for serialization, `as_any()`/`as_any_mut()` for downcasting.

2. **TypeRegistry replaces Cookbook/Recipe** — Gold's category/recipe system maps to a `HashMap<&'static str, DeserializerFn>`. Each concrete type registers its deserializer at startup. On-disk format: `[tag_len: u16][tag: utf8][payload: bytes]`.

3. **Edition snapshots, not O-tree serialization** — `EditionSnapshot` captures the flat entry list + default + domain. The O-tree is reconstructed on deserialization. This mirrors Gold's approach (the tree is an in-memory optimization; persistent storage is the logical content).

4. **Snarf layout is faithful** — Same header + map table + flock data layout as Gold. Map cells use bit 25 for forwarded/forgotten flags (matching `Flag = 1 << 25`). Flock data grows from the end of the snarf toward the front.

5. **Transaction is RAII** — `Transaction::begin(engine)` returns a guard. `commit()` ends the transaction. Drop without commit triggers rollback. New objects registered during a rolled-back transaction are unregistered.

6. **Rollback unregisters new objects** — Both `InMemoryStorage` and `SnarfStorage` track `new_in_transaction` / `new_flocks` and unregister them on rollback. Gold uses exception-based bomb cleanup; Rust uses Drop.

7. **Serde for serialization, but gated** — The `Persistent` trait's `to_bytes()` uses `serde_json` internally. The `edition/persistent` module is behind `#[cfg(feature = "serde")]`. The core `persist` module works without serde (InMemoryStorage path).

### Portability gaps from Gold

| Gap | Gold Feature | Rust Status | Plan |
|---|---|---|---|
| Urdi (raw disk I/O) | Memory-mapped file with atomic commit | SnarfStore operates on in-memory Vec<u8> | Add file-backed Urdi (mmap or buffered I/O) |
| Turtle bootstrap | SimpleTurtle writes boot heaper + protocol info to first data snarf | Not yet; SnarfStorage bootstraps from empty | Add for production use |
| Purger (memory management) | Converts clean shepherds to stubs, evicts from RAM | Not needed yet; everything in-memory | Add when disk-backed |
| Stub system (stubble codegen) | Placement new replaces shepherd with lightweight stub | Rust enum variants instead; no codegen needed | Not applicable |
| Agenda (persistent work queue) | Deferred work processed at endConsistent | Not yet | Add for production |
| Cross-server ID export/import | IDs reference objects on other servers | Single-server IDs only | Add for federation |
| Full BeRangeElement hierarchy | BeDataHolder, BeIDHolder, BeLabel, BePlaceHolder with detector hooks | Simplified BeRangeElement in backend.rs | Expand in Phase 7 |

### Enhancement ideas

1. **File-backed Urdi**: Replace `Vec<u8>` snarfs with memory-mapped files. Use `memmap2` crate. Atomic commit via write-ahead log or shadow paging.

2. **Columnar flock format**: For large Editions, store entries in a columnar format (sorted position array + sorted element array) instead of JSON. More compact, faster to reconstruct.

3. **Parallel commit**: Flocks in different snarfs can be written in parallel using rayon.

4. **Compression**: Snarf-level LZ4/Zstd compression for flocks that haven't changed recently.

## Phase 7: Server API Surface

### What was implemented

A new `src/server/` module with 7 files:

| Module | C++ Original | Rust Implementation |
|---|---|---|
| `error.rs` | ExceptionRecord + problem codes | `ServerError` enum (NotAuthorized, NotFound, NotGrabbed, AlreadyGrabbed, etc.) |
| `detector.rs` | FeFillDetector, FeStatusDetector, FeRevisionDetector | `Event` enum + `Detector` trait + `FnDetector` callback wrapper |
| `club.rs` | FeClub (extends FeWork) | `Club` — wraps Work with signature_club and name |
| `keymaster.rs` | FeKeyMaster (nkernelx.hxx:307-434) | `KeyMaster` — holds login/actual authority (HashSet<BeId>), incorporate/remove |
| `lock.rs` | Lock hierarchy + LockSmith hierarchy (nadminx.hxx) | `Lock` trait + BooLock, WallLock, ChallengeLock, MatchLock, MultiLock + LockSmith trait + smith implementations |
| `session.rs` | FeSession (nadminx.hxx:666-746) | `Session` — connection context with KeyMaster, connect time, login state |
| `server.rs` | FeServer (nkernelx.hxx:2161-2457) | `Server` — owns GrandMap, works, clubs, sessions, detectors; all operations are permission-checked methods on Server |

### Key design decisions

1. **All operations on Server** — Instead of Gold's Fe* wrapper objects (FeWork, FeEdition), all operations are methods on the `Server` struct. The Server takes a `SessionId` parameter for authentication context. This avoids Rust's borrow checker issues with split borrows across wrapper objects.

2. **Club wraps Work** — In Gold, Club IS a Work (C++ inheritance). In Rust, `Club` contains a `Work` internally. The Club adds `signature_club`, `name`, and identity-group semantics.

3. **Lock trait + LockCredential enum** — Gold uses virtual dispatch on Lock subclasses. Rust uses `Lock` trait with `try_open(&LockCredential)`. The `LockCredential` enum dispatches: `Boo`, `ChallengeResponse(Vec<u8>)`, `Password(Vec<u8>)`, `Named { name, credential }` for MultiLock.

4. **Detector is callback-based** — `Detector` trait with `on_event(&Event)`. `FnDetector<F>` wraps closures. Events are an enum: WorkGrabbed, WorkReleased, WorkRevised, RangeFilled, ElementFilled, Done.

5. **System clubs created at startup** — `Server::new()` creates 4 system clubs (public, admin, access, empty) with appropriate ownership. Public club is boo-lockable; admin/access are more restricted.

6. **Grab/release is per-Work** — `WorkState` tracks grabber (SessionId), status detectors, and revision detectors. Grab requires edit authority; release requires being the grabber. Disconnect auto-releases all grabs.

7. **Permission checks** — `check_read_permission()` and `check_edit_permission()` compare the session's KeyMaster authority against the Work's read/edit club. Public club grants open access.

### Portability gaps from Gold

| Gap | Gold Feature | Rust Status | Plan |
|---|---|---|---|
| Wire protocol | Binary2 over TCP with PromiseManager | In-process only; no network | Add in Phase 8 |
| Promise/Future system | XuPromise with lazy evaluation | Synchronous Result<T, ServerError> | Add async runtime |
| Fluid variables | Thread-local CurrentServer, CurrentAuthor, etc. | Explicit session_id parameters | Sufficient for single-threaded |
| Shepherd/Stub paging | In-place replacement with stub when memory pressure | All objects always in-memory | Add when disk-backed |
| Detectors over wire | CommDetector sends events to client | In-process only; fires locally | Add in wire protocol phase |
| XuServer static methods | Connect, login, get, assignID are class methods | Instance methods on Server | Close enough |
| Category-based RTTI | XuCategory hierarchy for wire type checking | Rust's trait + enum dispatch | No need without wire protocol |
| Request dispatch table | 470+ request handlers indexed by number | Direct method calls | Add in wire protocol phase |

### Enhancement ideas

1. **Async runtime**: Make Server methods async. Use tokio channels for detector event dispatch. This would enable serving multiple concurrent sessions.

2. **Arc<Mutex<Server>>**: For multi-session access, wrap Server in Arc<Mutex<>> or use per-Work locks (RwLock per work) for finer-grained concurrency.

3. **Observer pattern with channels**: Replace Detector trait with tokio::sync::broadcast channels. Clients subscribe to events they care about.

4. **Permission caching**: Cache permission check results and invalidate when clubs change. Currently checks are O(1) HashSet lookups but could be optimized for complex transitive authority.

5. **Rate limiting**: Add rate limiting per session to prevent abuse. Not needed in Gold (trusted local connections).

6. **Audit log**: Record all mutations (create, revise, grab, release) with session and timestamp. Gold doesn't have this explicitly but the revision history captures some of it.

## Phase 8: WebSocket Transport Layer

### What was implemented

A new `src/server/transport/` module with 7 files, gated behind the `server` feature:

| Module | Purpose |
|---|---|
| `varint.rs` | LEB128 varint encoding/decoding (replaces Gold's humber encoding) |
| `protocol.rs` | Wire types: `WireRequest`, `ResponseValue`, `WireEvent`, `OperationCode`, `ErrorCode`, `EditionPayload`, `WireFrame`, `SubscribeRequest`, `DetectorType`, `EventPayload` |
| `codec.rs` | `WireCodec` trait + `BinaryCodec` (postcard) + `JsonCodec` (serde_json) — dual format support |
| `shared.rs` | `AppState`, `ServerHandle` (Arc<Mutex<Server>>), `SharedState` |
| `channel.rs` | `ChannelDetector` — bridges sync Detector trait to async mpsc channel |
| `dispatch.rs` | `dispatch()` — maps WireRequest variants to Server method calls |
| `handler.rs` | axum WS upgrade handler, read/write loops, subscription management |

Plus `src/bin/xudanu-server.rs` — the standalone server binary entry point.

### Key design decisions

1. **Dual-format WireCodec**: The `WireCodec` trait abstracts serialization. `BinaryCodec` uses a 4-byte header + LEB128 varint + postcard binary encoding (compact). `JsonCodec` uses human-readable JSON text frames (easy for third-party integrations). Selection happens at WebSocket upgrade time via `?format=json` query parameter.

2. **Arc<Mutex<Server>>**: The synchronous Server is wrapped in `std::sync::Mutex` (not tokio's async Mutex). Since all Server methods are synchronous with no await points, std Mutex prevents lock-held-across-yield bugs and has lower overhead.

3. **Single writer task**: All outgoing messages (responses, events, heartbeats) flow through a single `mpsc::unbounded_channel` to a dedicated writer task that owns the WS sender. This avoids split-borrow issues and ensures ordered message delivery.

4. **ChannelDetector bridge**: The sync `Detector` trait sends events through an `mpsc::UnboundedSender<EventMessage>`. The writer task receives and encodes them for the wire.

5. **Operation codes**: Numeric for binary (`0x0303` = WorkRevise), string for JSON (`"work_revise"`). Both map to the same `OperationCode` enum which drives the dispatch.

6. **EditionPayload**: Editions are serialized as either `Text(String)`, `Entries(Vec<(i64, RangeElement)>)`, or `Empty`. This avoids serializing the O-tree directly — only the logical content crosses the wire.

7. **All new deps optional**: tokio, axum, postcard, futures-util, tracing, tracing-subscriber are all behind the `server` feature flag. The core crate remains WASM-friendly.

### Binary frame layout

```
[1B version][1B msg_type][2B request_id BE][payload...]

REQUEST:  [varint op_code][varint payload_len][postcard payload]
RESPONSE: [varint payload_len][postcard ResponseValue]
ERROR:    [1B error_code][varint msg_len][UTF-8 message]
EVENT:    [varint payload_len][postcard WireEvent]
SUBSCRIBE:[varint payload_len][postcard SubscribeRequest]
```

### JSON frame layout

```json
{"v":1,"type":"request","id":42,"op":"work_revise","payload":{"work_id":123,"edition":{...}}}
{"v":1,"type":"response","id":42,"value":{"type":"humber","value":2}}
{"v":1,"type":"error","id":42,"code":"not_grabbed","message":"work 123 not grabbed"}
{"v":1,"type":"event","id":7,"event":{"type":"work_revised","payload":{...}}}
```

### Running the server

```bash
cargo run --features server --bin xudanu-server
# listens on 127.0.0.1:8080

cargo run --features server --bin xudanu-server 0.0.0.0:3000
# custom address
```

Connect with any WebSocket client:
- `ws://127.0.0.1:8080/xudanu` — binary protocol
- `ws://127.0.0.1:8080/xudanu?format=json` — JSON protocol

### Test counts

- Without `server` feature: 513 pass, 0 fail
- With `server` feature: 553 pass, 0 fail (+40 new transport tests)

### Portability gaps from Gold

| Gap | Gold Feature | Rust Status | Plan |
|---|---|---|---|
| Custom binary protocol | Binary2 over raw TCP with humber encoding | WebSocket + postcard or JSON | More accessible; same semantic coverage |
| Promise/future system | XuPromise with lazy evaluation | Synchronous dispatch; Result<T> | Add async client SDK |
| Wire request numbering | 470+ numbered message handlers | ~40 OperationCode variants | Expand as needed |
| MultiLock auth over wire | Full auth protocol | Simplified; BooLock/MatchLock/ChallengeLock supported | Add complete auth flow |
| Subprotocol negotiation | WS subprotocol header | Query parameter `?format=json` | Add subprotocol support |
| TLS | Not in original (trusted network) | Not yet | Add with `axum-server` + rustls |
| Connection multiplexing | Single TCP connection for all ops | Single WS per client | Sufficient for Phase 8 |

### Enhancement ideas

1. **Integration tests with real WS client**: Add `tokio-tungstenite` as a dev-dependency for end-to-end tests that spin up the server and exercise the full JSON and binary protocol.

2. **REST API**: Add HTTP routes on the same axum Router for read-only queries (`GET /works/{id}`, `GET /clubs`). Useful for monitoring and tooling.

3. **TLS**: Add `axum-server` with rustls for `wss://` support.

4. **Subprotocol negotiation**: Use `Sec-WebSocket-Protocol` header instead of query parameter for format selection.

5. **Auth tokens**: After login, issue a session token that can be passed in WS upgrade headers for reconnection.

6. **Heartbeat timeout**: Close connections that don't send heartbeats within a configurable interval.

## Phase 9: File-Backed Persistence

### What was implemented

Four new modules under `src/persist/` and server integration:

| Module | C++ Original | Rust Implementation |
|---|---|---|
| `persist/urdi.rs` | `Urdi` / `UrdiView` / `SnarfHandle` (urdix.hxx) | `UrdiFile` — file-backed snarf read/write with guard records |
| `persist/file_storage.rs` | `SnarfPacker` + `Turtle` (packerx.hxx, turtlex.hxx) | `FileBackedStorage` — combines SnarfStorage + UrdiFile with meta record |
| `snarf.rs` extensions | `SnarfHandler::commitWrite()` (snfinfox.hxx) | Dirty tracking + `flush_to_urdi`/`load_from_urdi` on SnarfStore |
| `server/server.rs` additions | `FromDiskPlan::connection()` + `DiskConnection` (diskmanx.hxx) | `Server::to_snapshot()`/`from_snapshot()` + `checkpoint_to_file()`/`restore_from_file()` |
| `bin/xudanu-server.rs` | `BuildUrdiFile` + server main (buildx.cxx) | CLI with `init`/`run`/`verify` subcommands + graceful shutdown |

### On-disk format (`.xu` file)

```
┌──────────────────────────────────────┐
│ File Header (32 bytes)                │
│   magic: "XUD1" | version: 1         │
│   snarf_size, snarf_count            │
│   stage_count, data_start             │
│   header_crc (FNV-1a)                │
├──────────────────────────────────────┤
│ Meta Snarf 0 (guard + data)           │  MetaRecord: counters + flock index
│ Reserved Snarf 1                      │  Future: Turtle root object
├──────────────────────────────────────┤
│ Data Snarf 0 (guard + data)           │  Flock data
│ Data Snarf 1                          │
│ ...                                   │
├──────────────────────────────────────┤
│ Stage Area (stage_count snarfs)       │  Future: double-buffer
└──────────────────────────────────────┘
```

Each snarf has a 32-byte guard record: magic, snarf_id, cycle, data_len, data_hash (FNV-1a), flags, guard_crc. Guards detect partial writes and corruption.

### Server snapshot format

The server state is serialized as JSON to `<data-dir>/server.json`:

```json
{
  "grand_map_id_counter": 1005,
  "session_counter": 2,
  "operation_counter": 42,
  "system_clubs": { "public_club": 1000, "admin_club": 1001, ... },
  "works": [
    { "work": { "be_id": 1004, "current": { "entries": [...], ... }, ... }, "grabber": null, ... }
  ],
  "clubs": [...],
  "standalone_editions": [...]
}
```

Works and editions use the existing `WorkSnapshot`/`EditionSnapshot` types from `edition/persistent.rs`.

### Key design decisions

1. **Buffered I/O, not mmap** — `UrdiFile` uses `std::fs::File` with seek+read+write. Simpler, more portable, no page fault surprises. mmap can be added later as an optimization.

2. **Guard records per snarf** — 32-byte header with FNV-1a hash, magic `XNSR`, snarf ID, cycle counter. Detects partial writes and corruption on each individual snarf.

3. **SnarfStore offset from UrdiFile** — The first `DATA_SNARF_OFFSET` (2) UrdiFile slots are reserved for system use (meta, turtle). SnarfStore snarfs are offset by this amount. This prevents the SnarfStore's info snarfs from colliding with the meta record.

4. **Meta record replaces Turtle** — A `MetaRecord` struct stores the hash/token counters and flock index (FlockId → FlockLocation + FlockFlags). This serves the same role as Gold's Turtle for v1. A full Turtle object graph can be added later.

5. **Lazy loading in FileBackedStorage** — `fetch()` first checks the in-memory registry, then falls through to reading from the snarf store. Objects are deserialized on first access, not all at startup. This avoids requiring type registration before opening.

6. **Server snapshot is JSON, not flock-based** — The server state is serialized as a single JSON file, not as individual flocks in the storage engine. This is simpler for v1. A future phase can migrate to per-object persistence using FileBackedStorage.

7. **Grabs not preserved across restart** — Sessions are ephemeral. `WorkState.grabber` is always set to `None` during restore. Any work that was grabbed at checkpoint time is released on restart.

8. **Rollback wipes snarf cells** — Fixed a gap where `SnarfStorage::rollback()` previously only removed metadata for new flocks. Now also wipes the actual snarf cell data, preventing leaked space.

9. **CLI subcommands** — `xudanu-server init <dir>` creates a new data directory, `xudanu-server run [addr] [dir>` starts the server with optional persistence, `xudanu-server verify <dir>` checks snapshot integrity. SIGINT triggers a checkpoint before exit.

### Portability gaps from Gold

| Gap | Gold Feature | Rust Status | Plan |
|---|---|---|---|
| Staging area double-buffer | Write to staging snarfs, then atomically swap | Guard records provide crash detection but no double-buffer | Add staging area for stronger atomicity |
| Full Turtle object graph | Turtle holds boot category + cookbook + protocol | MetaRecord stores counters + flock index | Add Turtle for complex boot scenarios |
| Purger | Converts clean shepherds to stubs, evicts from RAM | Everything in-memory, no stubs | Add when memory-constrained |
| Agenda | Persistent work queue processed at endConsistent | Not yet | Add for production |
| Per-object disk persistence | Each Work/Edition is a separate flock on disk | Single JSON snapshot for entire server | Migrate to per-object persistence |
| Write-ahead log | Ongoing operations logged for crash recovery | Checkpoint-based (write+sync) | Add WAL for sub-second recovery |
| Urdi device partition | Raw disk device access | Regular file I/O | Not needed for modern systems |
| Endian detection | Multi-endian guard records | Little-endian only | Add if cross-platform needed |

### Enhancement ideas for future phases

1. **Per-object persistence**: Store each Work/Edition as a separate flock in FileBackedStorage instead of a single JSON blob. Enables incremental checkpointing and lower memory usage on load.

2. **Write-ahead log**: Log each mutation before applying it. On crash, replay the WAL to recover. Sub-second recovery instead of losing the last checkpoint interval.

3. **mmap optimization**: Replace `std::fs::File` with `memmap2` for snarf access. Avoids explicit read/write syscalls for frequently accessed snarfs.

4. **Incremental checkpoint**: Only write changed objects since last checkpoint. Reduces I/O for large stores with frequent checkpoints.

5. **Compression**: Snarf-level LZ4/Zstd compression for flocks that haven't changed recently.

6. **File locking**: Use `flock(2)` or `fcntl(F_SETLK)` to prevent multiple server instances from opening the same data directory.

### Test counts

| Phase | Tests | Notes |
|---|---|---|
| Phase 8 | 567 unit + 37 integration | WebSocket transport + audit |
| Phase 9 | 603 unit + 37 integration | File-backed persistence |
| Phase 10 | 612 unit + 47 integration | Admin API, handshake |
| Phase 11 | 612 unit + 53 integration | Client, links, transclusion, work listing |
| **Total** | **665** | All passing, 14 ignored |

## Phase 10: Wire-Protocol Detector Events & Admin API

### What was implemented

Five new modules and extensions across the server and transport layers:

| Module | C++ Original | Rust Implementation |
|---|---|---|
| `server/admin.rs` | `FeAdminer` (sysadmx.hxx) | `AdminState` — server state management, accept/reject connections, shutdown, ID grants |
| `transport/handler.rs` additions | `BootPlan`/`SetCommProtocol` (bootplnx.hxx, negoci8x.hxx) | `HandshakeResponse` — version negotiation at WebSocket connection start |
| `transport/handler.rs` subscribe tracking | `PromiseManager` subscription tracking (promanx.hxx) | `subscriptions` HashMap + `SUBSCRIPTION_COUNTER` — proper subscription ID tracking |
| `transport/channel.rs` additions | `CommXxxDetector` + `DetectorEvent` hierarchy (comdtctr.hxx) | `subscription_id` on `EventMessage` — events carry subscription IDs |
| `transport/protocol.rs` additions | `handlrsx.hxx` dispatch table | `OperationCode` admin ops, `ResponseValue` admin types, `HandshakeRequest/Response`, `ServerInfoPayload`, `SessionInfoPayload`, `GrantPayload` |

### New protocol operations

| Op Code | Operation | C++ Equivalent |
|---|---|---|
| 0x0501 | `AdminAcceptConnections` | `FeAdminer::acceptConnections` |
| 0x0502 | `AdminIsAcceptingConnections` | `FeAdminer::isAcceptingConnections` |
| 0x0503 | `AdminActiveSessions` | `FeAdminer::activeSessions` |
| 0x0504 | `AdminShutdown` | `FeAdminer::shutdown` |
| 0x0505 | `AdminGrant` | `FeAdminer::grant` |
| 0x0506 | `AdminRevokeGrant` | New (Gold had grants() only) |
| 0x0507 | `AdminGrants` | `FeAdminer::grants` |
| 0x0508 | `AdminServerInfo` | New (combines stats + state) |
| 0x0601 | `ServerStats` | New (non-admin version of server info) |

### Handshake protocol

At connection start, the server sends a `HandshakeResponse`:

```json
{
  "type": "handshake",
  "v": 2,
  "payload": {
    "server_version": 2,
    "negotiated_version": 2,
    "server_id": "xudanu-0.1.0",
    "server_capabilities": ["json", "binary", "detector_events", "admin"]
  }
}
```

The client's requested version is passed as `?version=N` query parameter. If the version is outside `[MIN_SUPPORTED_VERSION, PROTOCOL_VERSION]`, an error is sent and the connection is closed.

### Admin authority model

Admin operations require the session to hold authority for either the `admin_club` or `access_club`. The admin club's `read_club` is set to the public club, so any logged-in session can escalate to admin authority by:

1. Looking up the admin club ID via `club_id_by_name("admin")`
2. Logging in via `session_login` with that club ID (returns a BooLock since read_club is public)
3. Authenticating via `session_authenticate` with `Boo` credential

This mirrors Gold's `FeAdminer::make()` which requires a KeyMaster with System Admin authority.

### Connection gating

When `AdminState.accepting_connections` is `false` or `shutdown_requested` is `true`:
- New WebSocket connections are immediately closed with `not_accepting_connections` error
- Existing connections check `is_shutdown_requested()` on each request and close if true

### ID grants

The `AdminState` tracks `IdGrant` records mapping `(club_id, XnRegion)`. These grants give clubs authority to assign global IDs in specific regions. Multiple grants per club are supported (additive, not replacing).

### Subscription tracking

The handler now tracks subscriptions in a `HashMap<u16, (DetectorType, BeId)>`. Each subscribe operation returns a unique subscription ID via an `AtomicU16` counter. Events carry the subscription ID so clients can correlate them.

### Protocol version bump

`PROTOCOL_VERSION` is now `0x02` (was `0x01`). `MIN_SUPPORTED_VERSION` is `0x01`. The handshake negotiates the version.

### Portability gaps from Gold

| Gap | Gold Feature | Rust Status | Plan |
|---|---|---|---|
| FeArchiver | Archive/restore Works to secondary storage | Not yet | Add in Phase 13 |
| GateLockSmith | Configurable lock for invalid logins | Not yet | Add in Phase 11 |
| Full detector wire protocol | CommFillDetector, CommRevisionDetector, etc. | Subscription tracking + event push | Add per-type filtering |
| Protocol negotiation | SetCommProtocol/SetDiskProtocol at boot | Version query param + handshake | Sufficient for v1 |
| Execute commands | FeAdminer::execute(PrimIntArray) | Not yet | Add for production |
| Detector event queuing | PromiseManager queues events between requests | Events pushed immediately | Add queuing for ordered delivery |

### Enhancement ideas for future phases

1. **Per-type detector subscriptions**: Allow subscribing to specific event types (grab, release, revise) on a work, not just status/revision/fill.

2. **Detector event queuing**: Queue events between requests (like Gold's PromiseManager) to ensure ordered delivery.

3. **Admin command execution**: Add `admin_execute` for batch configuration commands.

4. **Gate lock configuration**: Allow setting a custom LockSmith for invalid login attempts via the wire protocol.

5. **WebSocket subprotocol negotiation**: Use axum's subprotocol support instead of query parameter for format selection.

## Phase 11: Make It Usable — Client, Links, Transclusion, Work Listing

### What was implemented

Six work items completed, making the system demonstrable end-to-end:

| Item | Description |
|---|---|
| Work listing | `WorkList`, `WorkListByOwner` operations + `list_works()` server methods |
| Link storage & wire ops | `LinkCreate`, `LinkGet`, `LinkUpdate`, `LinkDelete`, `LinkListForWork` |
| Transclusion queries | `FindTranscluders`, `FindWorksForContent` — search for content across works |
| CLI client | `xudanu-cli` binary with REPL and subcommand modes |
| Web UI | Served at `/` — browser-based client for interactive use |
| Demo script | `examples/demo.sh` — automated walkthrough |

### New protocol operations

| Op Code | Operation | Notes |
|---|---|---|
| 0x030E | `WorkList` | List all works with owner, revision count, grab status |
| 0x030F | `WorkListByOwner` | Filter works by owner BeId |
| 0x0701 | `LinkCreate` | Create bidirectional link between two works |
| 0x0702 | `LinkGet` | Get link details (origin, destination, refs) |
| 0x0703 | `LinkUpdate` | Update link endpoint references |
| 0x0704 | `LinkDelete` | Remove a link |
| 0x0705 | `LinkListForWork` | List all links involving a work |
| 0x0801 | `FindTranscluders` | Find editions/works that contain given content |
| 0x0802 | `FindWorksForContent` | Find works containing given content by BeId |

### CLI client (`xudanu-cli`)

Two modes:
- **Subcommand**: `xudanu-cli <url> create-work "hello"` — one-shot, for scripting
- **REPL**: `xudanu-cli <url> repl` — interactive session

Commands: `login`, `login-admin`, `create-work`, `get-work`, `list-works`, `grab`, `revise`, `release`, `history`, `fetch-revision`, `create-link`, `get-link`, `list-links`, `delete-link`, `find-content`, `club-create`, `club-list`, `info`, `quit`

### Web UI

Served at the root URL (`/`). Dark-themed browser client that auto-connects via WebSocket, logs in, and provides a command input. Same commands as the CLI.

### Link model

Links are stored in `Server.links: HashMap<BeId, LinkState>` where `LinkState` holds:
- `origin: BeId` — source work
- `destination: BeId` — target work  
- `link: HyperLink` — with `LeftEnd` and `RightEnd` HyperRefs

Links are persisted in server snapshots as `LinkSnapshot { link_id, origin, destination }`.

### Transclusion queries

The server currently implements content search by scanning all work editions linearly. For each work/edition, it checks if any entry's element matches the target BeId. This is O(n) but sufficient for v1.

Future phases will integrate the full `BackfollowEngine` with `TransclusionIndex` for O(log n) lookups via the canopy/HTree structures.

### Demo

```bash
cd src-rust
cargo build --features server --bins
./examples/demo.sh
```

This creates documents, edits them, creates links, lists works, creates clubs, and shows server info.

### Test counts

| Phase | Tests | Notes |
|---|---|---|
| Phase 10 | 612 unit + 47 integration | Admin API, handshake, detector subscription |
| Phase 11 | 612 unit + 53 integration | +6 integration (work-list, links, transclusion) |

## Phase 14: Space/CoordinateSpace Types

### What was implemented

A new `src/space/` module with 8 files implementing Gold's CoordinateSpace hierarchy:

| Module | C++ Original | Rust Implementation |
|---|---|---|
| `traits.rs` | `Space`/`Position`/`XnRegion`/`Dsp`/`OrderSpec` (spacex.hxx) | `Space`/`Position`/`Region`/`Dsp`/`OrderSpec` traits with circular associated types |
| `integer.rs` | `IntegerSpace`/`IntegerPos`/`IntegerRegion` (integerx.hxx) | `IntegerSpace`, `IntegerPos`, `IntegerRegion` (wraps `XnRegion`), `IntegerDsp`, `IntegerAscending`/`IntegerDescending` |
| `real.rs` | `RealSpace`/`RealPos`/`RealRegion` (realx.hxx) | `RealSpace`, `RealPos`, `RealRegion`, `RealDsp`, `RealAscending`/`RealDescending` |
| `sequence.rs` | `SequenceSpace`/`Sequence`/`SequenceRegion`/`SequenceMapping` (sequencex.hxx) | `SequenceSpace`, `Sequence` (Vec<i64> + shift), `SequencePos`, `SequenceRegion`, `SequenceDsp`, `SequenceAscending`/`SequenceDescending` |
| `cross.rs` | `CrossSpace`/`Tuple`/`CrossRegion`/`CrossMapping` (crossx.hxx) | `CrossSpace2<A,B>`, `Tuple2<A,B>`, `CrossRegion2<R1,R2>`, `CrossDsp2<D1,D2>`, `CrossOrder2` |
| `filter.rs` | `FilterSpace`/`Filter`/`FilterPosition`/`Joint`/`RegionDelta` (filterx.hxx) | `FilterSpace`, `FilterPosition`, `Filter` enum (Full/Empty/Subset/Superset/Intersection/NotSubset/NotSuperset/And/Or), `Joint`, `RegionDelta` |
| `mapping.rs` | `SimpleMapping`/`CompositeMapping`/`ConstantMapping`/`EmptyMapping` (spacep.hxx) | `SimpleMapping<S>`, `CompositeMapping<S>`, `ConstantMapping<S>`, `EmptyMapping<S>` with `MappingSpace` trait |
| `order.rs` | `ReverseOrder`/`ChainedOrder` (spacep.hxx) | `ReverseOrder<P>`, `ChainedOrder<P>` |

### Key design decisions

1. **Circular associated types**: `Position<Region=R>` and `Region<Position=P>` where `P::Region=R` and `R::Position=P`. This preserves the type-level relationship between positions, regions, and displacements without inheritance.

2. **IntegerRegion wraps XnRegion**: The existing `XnRegion` transition-array implementation is reused as the storage for `IntegerRegion`. This avoids duplication and maintains compatibility with the Edition layer.

3. **CrossSpace2 is generic over two axes**: `CrossSpace2<A: Space, B: Space>` avoids heterogeneous type erasure for the common 2D case. Higher dimensions can be supported by nesting (e.g., `CrossSpace2<CrossSpace2<X, Y>, Z>`).

4. **FilterSpace is standalone** (does NOT implement the Space trait): Filter positions are regions from another space, which can't be captured by the circular associated type pattern. Uses tag-based `Filter` enum with u64 tags instead of actual region comparison.

5. **Mapping types use a separate `MappingSpace` trait**: Because the main `Region`/`Dsp` traits' method names (`contains`, `is_empty`) conflict with the mapping layer's own traits when both are in scope. Tests use fully-qualified `Region::contains(...)` calls.

6. **ReverseOrder::compare() reverses ordering** by swapping args AND reversing the result via `.reverse()`. Manual Debug/PartialEq/Eq/Hash implementations since `Box<dyn OrderSpec>` doesn't impl Clone/Hash/Eq.

### RealRegion bug: edge-flag model vs simple flip model

**Root cause**: The original implementation used an edge-flag model where each transition stored both a `value: f64` and an `included: bool` flag. The `included` flag indicated whether the point at exactly that value was inside the region. This works for simple (non-merged) intervals but breaks when the merge algorithm produces same-value transition pairs.

**How the bug manifested**: The `merge_real_regions` function produces same-value pairs like `[(3.0, false), (3.0, true)]` to represent the transition "not inside at 3.0, but inside just past 3.0". The `contains_value` method used flip counting: walk transitions with value <= v, flipping the inside state for each one. Two transitions at the same value flip twice (net zero), so `contains_value(4.0)` would see: flip at 3.0 -> true, flip at 3.0 -> false (back to false), then 5.0 > 4.0 so return false. But 4.0 IS in the region `(3.0, 5.0)`.

**The fundamental tension**: The edge-flag model conflates two pieces of information:
- The "at" state (the `included` flag at exact boundary values)
- The "between" state (flipped by each transition)

For simple intervals these are aligned. For merged intervals they conflict: same-value pairs represent a real state change ("not at 3.0, but yes past 3.0") that flip counting treats as zero change (two flips cancel).

**Failed attempts**:
1. Counting distinct-value groups instead of individual transitions -- works for point regions but breaks for merged intervals
2. Using even/odd group sizes -- ambiguous: a group of 2 could mean 1 flip (false->true) or 0 flips (true->false->true->false)
3. Linear scan with per-edge flips -- same double-flip problem
4. `normalize_edges` that removes even-count groups -- removes the pair entirely, losing the real state change

**Solution adopted**: Drop the `included` flag entirely. Use a simple flip model where transitions are just `Vec<f64>` values (like `XnRegion`/`IntegerRegion`). All intervals are internally half-open `[start, stop)`. Open/closed boundary distinctions from the API are mapped to half-open at construction time:
- `interval(1.0, 5.0, false, false)` -> effective `[1.0+e, 5.0)` where e = `1.0.next_up() - 1.0`
- `interval(1.0, 5.0, true, true)` -> effective `[1.0, 5.0+e)`
- `above(10.0, false)` -> transition at `10.0.next_up()` instead of `10.0`
- `below(10.0, true)` -> transition at `10.0.next_up()` instead of `10.0`

This makes `contains_value` a simple flip count: count transitions with value <= v. The merge becomes a standard sorted-merge of transition arrays with no edge-flag logic, no `normalize_edges`, and no same-value ambiguity.

**Trade-off**: We lose the ability to distinguish `[3.0, 5.0]` from `[3.0, 5.0)` at exact float values. For f64, `v.next_up() - v` is on the order of 10^-16, so this distinction is negligible for practical use. All existing tests pass with the half-open mapping.

**Impact on the codebase**:
- `RealEdge` struct removed entirely (was only used internally)
- `RealRegion.transitions` changed from `Vec<RealEdge>` to `Vec<f64>`
- `contains_value` simplified from 17 lines to 7 lines
- `merge_real_regions` simplified from 60 lines to 30 lines
- `complement` simplified from 8 lines to 4 lines (just flip `starts_inside`)
- `normalize_edges`, `count_distinct_flips`, `count_net_flips` helper functions all removed
- Manual `PartialEq`/`Eq`/`Hash` impls for `RealRegion` (since `Vec<f64>` doesn't impl them)

### SequenceDsp inverse bug: shift not adjusted on leading-zero trim

**Root cause**: `Sequence::from_numbers_with_shift` trimmed leading zeros from the numbers array but didn't adjust the `shift` field, so the first non-zero value ended up at the wrong index.

**How the bug manifested**: `SequenceDsp::inverse()` computed `inv_translation = Sequence::zero().minus(&self.translation).shifted(-self.shift)`. The `minus` operation produced `[0, 0, 5]` at shift=-2, meaning 5 is at index 0. But `from_numbers_with_shift([0, 0, 5], -2)` trimmed the leading zeros to `[5]` while keeping shift=-2, incorrectly placing 5 at index -2 instead of index 0. This caused `inv.of(d.of(x))` to produce `{ shift: -2, numbers: [5] }` instead of `{ shift: 0, numbers: [5] }`.

**The fix was one line**: increment `shift` for each leading zero removed:

```rust
while numbers.first() == Some(&0) {
    numbers.remove(0);
    shift += 1;  // was missing
}
```

**Additional change**: `Sequence::from_numbers()` was decoupled from `from_numbers_with_shift` because they have different semantics:
- `from_numbers([0, 0, 3, 7])` -> trim and reindex to start at 0 (user-facing, padding removal)
- `from_numbers_with_shift(result, start)` -> trim and adjust shift to preserve actual indices (internal, for plus/minus)

**The inverse formula itself was correct**: `inverse_transform(seq) = seq.minus(&self.translation).shifted(-self.shift)` undoes the forward `transform(seq) = seq.shifted(self.shift).plus(&self.translation)` correctly. The bug was entirely in the index bookkeeping of `from_numbers_with_shift`.

### Enhancement ideas for future phases

1. **yrs/CRDT as transport layer**: The Edition model maps naturally to yrs `Doc` with `Text` sequences. An Edition could be materialized into a yrs document for real-time sync, while maintaining the Gold partial ordering for conflict preservation.

2. **Compressed transition arrays**: For very large regions, run-length encoding with 32-bit deltas could reduce memory usage.

3. **Parallel region operations**: `merge_transitions` could be parallelized for large regions using rayon.

4. **RealRegion epsilon-aware API**: Expose the half-open mapping to callers who need exact boundary control. Could add `interval_half_open(start, stop)` constructor.

5. **SequenceRegion: drop edge-flag model**: SequenceRegion uses the same edge-flag pattern as the old RealRegion and may have the same merge/contains bug. Consider adopting the same simple flip model.

### Test counts

| Phase | Tests | Notes |
|---|---|---|
| Phase 13 | 612 unit + 54 integration | Arc<Mutex> refactor |
| Phase 14 (space types) | 686 unit + 54 integration | +74 new space tests |
| **Total** | **740** | All passing, 11 ignored |
