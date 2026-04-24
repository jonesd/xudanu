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
