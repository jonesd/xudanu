# Xudanu Feature Status

> **Last updated:** 2026-05-31
> **Version:** 0.3.0
> **Tests:** 1799 passing, 0 failing, 38 ignored (stress tests)
>
> This document tracks every feature from Ted Nelson's Xanadu vision, the
> Udanax Gold C++ implementation, and Xudanu's own additions. Status emojis:
>
> | Symbol | Meaning |
> |--------|---------|
> | ✅ | Fully implemented |
> | ⚠️ | Partially implemented or has known gaps |
> | ❌ | Not yet implemented |
> | 🔧 | API exists but no UI |
> | 🆕 | Xudanu addition (not in original Xanadu/Udanax Gold) |

---

## Table of Contents

1. [Nelson's 17 Rules](#nelsons-17-rules)
2. [Core Xanadu Concepts](#core-xanadu-concepts)
3. [Udanax Gold Data Structures](#udanax-gold-data-structures)
4. [Wire Protocol & Server](#wire-protocol--server)
5. [Frontend / User Interface](#frontend--user-interface)
6. [Security & Cryptography](#security--cryptography)
7. [Persistence & Storage](#persistence--storage)
8. [Federation](#federation)
9. [Xudanu-Exclusive Features](#xudanu-exclusive-features)
10. [Feature Roadmap Summary](#feature-roadmap-summary)

---

## Nelson's 17 Rules

*Nelson's original 17 rules that every Xanadu server must satisfy.*

| # | Rule | Status | Notes |
|---|------|:------:|-------|
| 1 | Every server is uniquely and securely identified | ✅ | Ed25519 keypair per server, persistent identity |
| 2 | Every server can operate independently or in a network | ⚠️ | Standalone works; federation transport exists but not production-ready |
| 3 | Every user is uniquely and securely identified | ✅ | Cryptographic identity: personal clubs with Ed25519 signing keys, Argon2 passwords |
| 4 | Every user can search, retrieve, create, and store documents | ✅ | Full CRUD: `work_create`, `work_grab`, `work_revise`, `work_release`, `work_list` |
| 5 | Every document can consist of any number of parts of any data type | ⚠️ | Text, blobs, editions (nested). No video/structured-data as first-class parts yet |
| 6 | Every document can contain links including virtual copies (transclusions) | ✅ | Bidirectional links, TransclusionIndex, ContentAddressIndex, BLAKE3 fingerprinting |
| 7 | Links are visible and can be followed from all endpoints | ✅ | Canvas overlay markers, link sidebar, bidirectional navigation |
| 8 | Permission to link is granted by the act of publication | ✅ | Publication model via read_club semantics; unpublished works are private |
| 9 | Every document can contain a royalty mechanism at any granularity | ❌ | Data structures exist (`StorageCost`, `CostMethod`, `RoyaltyEntry`) but no payment flow |
| 10 | Every document is uniquely and securely identified | ✅ | Content-addressed via BeIds in GrandMap; BLAKE3 fingerprints |
| 11 | Every document can have secure access controls | ✅ | Club-based read_club/edit_club; enforced in dispatch layer |
| 12 | Every document can be rapidly searched/stored/retrieved transparently | ✅ | Server abstracts storage; content-addressed blobs; work IDs |
| 13 | Every document is automatically moved to appropriate physical storage | ❌ | No adaptive storage tiering; all data in local filesystem |
| 14 | Every document is redundantly stored for disaster recovery | ⚠️ | Crash-safe checkpoint with tmp+rename; no geographic replication |
| 15 | Every service provider can charge users at any rate | ❌ | Cost model structures exist; no billing/payment infrastructure |
| 16 | Every transaction is secure and auditable only by the parties | ⚠️ | Encrypted federation channels; hash-chained audit log; no per-transaction E2E encryption |
| 17 | The client-server protocol is an openly published standard | ✅ | WebSocket JSON protocol documented; 110+ operations enumerated in `protocol.rs` |

**Summary: 8 fully implemented, 5 partial, 4 not yet.**

---

## Core Xanadu Concepts

*Features central to Ted Nelson's hypertext vision.*

### Transclusion

| Feature | Status | Details |
|---------|:------:|---------|
| Content-addressed identity (BLAKE3) | ✅ | `RangeElement::content_fingerprint()` produces 32-byte BLAKE3 hashes |
| TransclusionIndex (fingerprint → works) | ✅ | Reverse index from content to containing editions/works |
| ContentAddressIndex (fingerprint → BeIds) | ✅ | Bidirectional mapping, content-addressed deduplication |
| Find transcluders of content | ✅ | `find_transcluders()`, `find_works_for_content()` |
| Find shared regions between documents | ✅ | `content_shared_region()`, `content_map_shared_to/onto()` |
| Transclusion depth counting | ✅ | `count_transclusion_depth()`, `find_deeply_transcluded()` |
| Range-based transclusion queries | ✅ | `range_transcluders()`, `range_works()` |
| Live transclusion rendering | ❌ | Content is found but not rendered in-place with live updates |
| Compound documents (compositional transclusion) | 🔧 | `CompoundResolve` opcode exists; no composition UI or resolution engine |
| Transclusion markers in editor | ✅ | Canvas overlay draws colored sidebar bars for transcluded regions |
| Transclusion workflow (select → navigate → place) | ✅ | Frontend workflow: select text, navigate to target, click to place |

### Bidirectional Links

| Feature | Status | Details |
|---------|:------:|---------|
| Multi-ended links (HyperLink) | ✅ | Named ends (LeftEnd, RightEnd, arbitrary names), link type IDs |
| HyperRef with excerpts | ✅ | `HyperRefKind::Single` with optional excerpt edition |
| Composite references (Multi) | ✅ | `HyperRefKind::Multi` with nested refs |
| Provenance chains on links | ✅ | `ProvenanceHop` chain tracking copy lineage through multiple works |
| Link CRUD operations | ✅ | Create, Get, Update, Delete, ListForWork |
| Bidirectional link tracking | ✅ | Links tracked from both endpoints |
| Inter-span links (within-document) | ❌ | Links operate at work level; no span-level targeting yet |
| Link context / self-explaining links | ⚠️ | `HyperRef` has `work_context`/`original_context`/`path_context` fields but not fully wired through protocol |

### Versioning

| Feature | Status | Details |
|---------|:------:|---------|
| Full revision history | ✅ | `BTreeMap<u64, Edition>` per work; `fetch_revision(n)` |
| DagWood partial ordering | ✅ | `is_le(a, b)` for version ancestry; binary-tree branching |
| Version ancestry queries | ✅ | `version_ancestors()`, `version_descendants()`, `version_ancestors_transitive()` |
| Trace position | ✅ | `(BranchId, u32)` for precise version locating |
| Snapshots / freezing | ✅ | Immutable snapshots; published works are frozen |
| Three-way diff | ✅ | `three_way_diff()` and `three_way_merge()` with conflict detection |
| Three-way visual comparison (UI) | ❌ | Backend primitives exist; no visual diff UI |
| Version genealogy UI | 🔧 | API operations exist (`version_is_before`, ancestors, descendants); no UI |

### Back-Following

| Feature | Status | Details |
|---------|:------:|---------|
| BackfollowEngine | ✅ | Core reverse-navigation engine (1400+ lines) |
| Canopy-filtered H-tree traversal | ✅ | Flag-bit pruning for O(log n) queries |
| BertCanopy (permission/endorsement filtering) | ✅ | Binary tree with upward flag propagation |
| SensorCanopy (recorder installation) | ✅ | Recorder installation tree |
| Recursive back-following through versions | ✅ | `delayed_store_backfollow()` via H-tree traversal |
| Federated transclusion entries | ✅ | Entries from remote servers indexed locally |

### Publication & Access Control

| Feature | Status | Details |
|---------|:------:|---------|
| Publication model (Rule 8) | ✅ | `publish()` / `unpublish()` / `irrevocably_unpublish()` |
| Read-club / edit-club semantics | ✅ | Per-work `read_club` and `edit_club` fields |
| Club membership management | ✅ | `add_member`, `remove_member`, `members` |
| Default read/edit clubs | ✅ | `default_read_club`, `default_edit_club` on clubs |
| Public/private visibility toggle | ✅ | Frontend toggle; pub/priv badges in sidebar |
| Share/unshare (edit access) | ✅ | Share to public club or restrict to owner |
| Soft delete (archiving) | ❌ | `irrevocably_unpublish` is destructive; no archive/restore |
| Non-destructive model (Nelson's "nothing deleted") | ⚠️ | Revision history preserves all versions; but `irrevocably_unpublish` is destructive |

### Enfilade / O-Tree Data Model

| Feature | Status | Details |
|---------|:------:|---------|
| Ent (top-level entity) | ✅ | Wraps DagWood, delegates trace operations |
| DagWood (partial ordering) | ✅ | Binary-tree branching, `is_le()` ordering, navigation cache |
| HTree (history tree) | ✅ | Version ancestry tracking, canopy propagation |
| Branch / TracePosition | ✅ | BranchId, BranchKind (Root/Trunk/Version), BranchStore |
| Content assertions | ✅ | 2500+ line assertion engine: CreateNode, CreateSpan, SetSpanText, etc. |
| GrandMap (ID space manager) | ✅ | Maps BeIds to content elements |

---

## Udanax Gold Data Structures

*Structures from the original C++ codebase, faithfully ported to Rust.*

| Structure | Status | Rust Location | Notes |
|-----------|:------:|---------------|-------|
| **Edition** | ✅ | `src/edition/edition.rs` | Ordered immutable `(i64, Carrier)` collection |
| **RangeElement** | ✅ | `src/edition/range_element.rs` | 9 variants: Text, Data, Blob, Edition, Label, PlaceHolder, IDHolder, Work, Overlay |
| **Carrier** | ✅ | `src/edition/range_element.rs` | RangeElement + optional Provenance |
| **Work** | ✅ | `src/edition/work.rs` | Mutable document with revision history, access clubs, endorsements |
| **Club** | ✅ | `src/server/club.rs` | Identity/principal: members, credentials, signing keys |
| **XnRegion** | ✅ | `src/edition/xn_region.rs` | Interval-based position sets with set algebra |
| **Mapping** | ✅ | `src/edition/mapping.rs` | Affine transforms (shift, compose, invert) |
| **OrglRoot (O-tree)** | ✅ | `src/edition/orgl.rs` | BTree-based storage, core data structure |
| **Label / LabelledCarrier** | ✅ | `src/edition/label.rs` | Label addressing, identity maps |
| **Bundle** | ✅ | `src/edition/bundle.rs` | Element/Array/PlaceHolder bundles with retrieve() and cost() |
| **HyperLink / HyperRef** | ✅ | `src/edition/links.rs` | Bidirectional link system with set operations |
| **Path** | ✅ | `src/edition/links.rs` | Navigation through nested editions with resolver |
| **Wrapper types** | ✅ | `src/edition/wrapper.rs` | Text, Set, Path, HyperLink, HyperRef classification |
| **Canopy** | ✅ | `src/edition/canopy.rs` | Binary tree filtering with flag propagation |
| **ContentPool** | ✅ | `src/edition/pool.rs` | Hash-indexed deduplication pool |
| **BlobStore** | ✅ | `src/edition/blob_store.rs` | Content-addressed binary storage with filesystem backend |
| **TransclusionIndex** | ✅ | `src/edition/transclusion.rs` | Fingerprint-based reverse index |
| **BackfollowEngine** | ✅ | `src/edition/backfollow.rs` | Reverse navigation with canopy filtering |
| **Recorder / Fossil** | ✅ | `src/edition/recorder.rs` | Content-watch monitoring with sensor canopy |
| **BeStorage / InMemoryBeStorage** | ✅ | `src/edition/backend.rs` | Persistent storage trait |

---

## Wire Protocol & Server

### Protocol

| Feature | Status | Details |
|---------|:------:|---------|
| Binary codec (compact) | ✅ | LEB128 varints + postcard serialization |
| JSON codec (human-readable) | ✅ | JSON frames for easy debugging/integration |
| WebSocket transport | ✅ | With optional TLS (rustls) |
| Protocol version negotiation | ✅ | v1-v2 supported |
| Frame types | ✅ | Handshake, Request, Response, Error, Event, Subscribe, Unsubscribe, Heartbeat |
| CSRF token | ✅ | Fetched from `/csrf-token` endpoint |

### Operation Groups (110+ operations)

| Range | Group | Status | Operations |
|-------|-------|:------:|------------|
| 0x00xx | Session | ✅ | Connect, Disconnect, Login, LoginByName, Authenticate, LoginPublic |
| 0x01xx | Entity retrieval | ✅ | GetById, GetByBeId |
| 0x02xx | Club | ✅ | Create, CreateNamed, Get, ByName, IdByName, NameById, Names, SetPassword, ClearCredential, CreatePersonal, WhoAmI, AddMember, RemoveMember, Members, SetDefaultReadClub, SetDefaultEditClub |
| 0x03xx | Work | ✅ | Create, GetEdition, Revise, Grab, Release, SaveAndRelease, ForceRelease, IsGrabbed, Grabber, RequestGrab, CancelGrabRequest, GrabWaiters, CanRead, CanRevise, SetReadClub, SetEditClub, ReadClub, EditClub, RevisionCount, FetchRevision, FetchRevisionRange, Sponsor, Unsponsor, Sponsors, Owner, Publish, Unpublish, IrrevocablyUnpublish, IsPublished, List, ListByOwner, ReviseDelta, DiffNarration, WritingFeedback |
| 0x04xx | Edition | ✅ | Store, Get |
| 0x05xx | Admin | ✅ | AcceptConnections, IsAcceptingConnections, ActiveSessions, Shutdown, Grant, RevokeGrant, Grants, ServerInfo |
| 0x06xx | Stats | ✅ | ServerStats |
| 0x07xx | Links | ✅ | Create, Get, Update, Delete, ListForWork, FindExcerptPositions |
| 0x08xx | Transclusion | ✅ | FindTranscluders, FindWorksForContent, FindTextTranscluders, FindSharedRegions, ProvenanceAncestry, CompoundResolve |
| 0x09xx | Blobs | ✅ | Upload, Get, GetPreview, Exists, Info, Stats |
| 0x0Axx | Overlays | ✅ | Apply, Get |
| 0x0Bxx | Labels | ✅ | Create, GetPositions, Relabel, Rebind, CanMakeIdentical, MakeRangeIdentical, IdentityUnify, IdentityResolve |
| 0x0Cxx | Retrieval | ✅ | Retrieve, Cost |
| 0x0Dxx | Attribution/Search | ✅ | AttributionQuery, AttributionVerify, AttributionLogStatus, WorkTextRange, WorkOutline, WorkSearch, WorkGoto, HistoricalAuthorRegister/Get/Search/List, ImportSourceWork, SourceDetect, SourcePatternList, WorkListByAuthor |
| 0x0Exx | Shared Content | ✅ | ContentSharedRegion, ContentMapSharedTo, ContentMapSharedOnto, PositionsOf |
| 0x0Fxx | Range Queries | ✅ | RangeTranscluders, RangeWorks, OrderedBundles, TransclusionDepth |
| 0x10xx | Versioning | ✅ | VersionIsBefore, VersionAncestors, VersionDescendants, VersionTracePosition |
| 0x11xx | Recorders | ✅ | AdminRecorderCreate, Record, List, Get, ServerHealth |
| 0x12xx | Crypto | ✅ | GetPublicKey, SignData, VerifySignature, KeyRotation, KeyHistory |
| 0x13xx | Endorsements | ✅ | WorkEndorse/Retract/Endorsements, EditionEndorse/Retract/Endorsements/VisibleEndorsements/TotalEndorsements |
| 0x14xx | Federation | ✅ | FederationInfo, FederationPeers |
| 0x17xx | Federated Content | ✅ | FederatedTransclusionQuery, FederatedContentFetch |
| 0x18xx | Endorsement Sync | ✅ | EndorsementSync, Add, Retract, Query, StateSync, StateAlternatives |
| 0x19xx | Membership | ✅ | JoinRequest/Response, EndorseOffer/Accept, Sync/SyncResult, Leave, List, Verify |
| 0x1Bxx | Governance | ✅ | Propose, Prepare, Commit, Seal, Log, Status |
| 0x1Cxx | CRDT | ✅ | SyncOpen/Close/Update/Diff/FullState/Materialize/SubscriberCount/Text, AwarenessUpdate/Get, RegisterAuthor |

### Server Infrastructure

| Feature | Status | Details |
|---------|:------:|---------|
| Session management | ✅ | Login state tracking, authority, active sessions |
| Event subscription | ✅ | Detector/subscription-based event delivery |
| Grab/release locking | ✅ | Cooperative edit locks with waiters queue |
| Auto-checkpoint | ✅ | Time-based with tmp+rename atomic writes |
| Graceful shutdown | ✅ | Checkpoint on shutdown signal |
| Panic containment | ✅ | `catch_unwind` in dispatch; mutex poison recovery |
| Admin controls | ✅ | Connection gating, shutdown, grants |
| Static file serving | ✅ | `--static-dir` for custom frontends |

---

## Frontend / User Interface

### React Application (Primary UI)

| Feature | Status | Component |
|---------|:------:|-----------|
| Document list sidebar | ✅ | `WorkspacePage` — filterable, pub/priv badges, revision counts |
| Collaborative editor | ✅ | `CollaborativeEditor` — contentEditable with canvas overlay |
| Virtualized editor (large docs) | ✅ | `VirtualizedEditor` — windowed rendering for >100K chars |
| Attribution overlay | ✅ | Canvas overlay with per-author coloring (human green, LLM purple, historical amber) |
| Transclusion markers | ✅ | Colored sidebar bars, hover tooltips, click navigation |
| Transclusion workflow | ✅ | Select → navigate → place with TransclusionBadge |
| Links sidebar | ✅ | Outgoing/incoming with arrows, excerpts, provenance badges |
| Search within document | ✅ | `SearchPanel` — case-sensitive, prev/next, Ctrl+F |
| Document outline | ✅ | `OutlinePanel` — heading-based navigation |
| Attribution panel | ✅ | `AttributionPanel` — proportional bar, per-author breakdown, chain validity |
| Awareness indicators | ✅ | `AwarenessIndicators` — colored user pills, typing pulse |
| Identity panel | ✅ | `IdentityPanel` — create/login/logout |
| Import wizard | ✅ | `ImportWizard` — 6-step: paste → detect → author → preview → import → done |
| Source detection | ✅ | Project Gutenberg, Internet Archive, plain text patterns |
| Historical authors tab | ✅ | Expandable author list with works |
| Debug panel | ✅ | `DebugPanel` — assertions and branches tables |
| LLM features menu | ✅ | "Summarize Changes" (diff narration), "Writing Feedback" |
| Hash deep-linking | ✅ | `#L<line>` and `#C<char>` fragment navigation |
| Auto-reconnect | ✅ | 3-second exponential reconnect with credential replay |
| Read-only mode | ✅ | Greyed background when not authenticated |
| Boilerplate toggle | ✅ | Show/hide header/footer for imported works |
| Content watch | ✅ | "Watch" button for content match subscriptions |

### Static HTML Client (Emergency Fallback)

| Feature | Status | Details |
|---------|:------:|---------|
| Work CRUD | ✅ | Create, select, edit, delete |
| Revision slider | ✅ | Browse and restore past revisions |
| Link management | ✅ | Create, view, navigate links |
| Transclusion panel | ✅ | Find shared content, view transcluders |
| Blob upload | ✅ | Drag-and-drop images |
| Session management | ✅ | Login public, login by name, create identity |
| Dark/light theme | ✅ | Theme toggle |

### Missing / Planned UI

| Feature | Status | Details |
|---------|:------:|---------|
| Global dark mode | ❌ | Only debug panel is dark; no global toggle |
| Mobile/responsive | ❌ | Desktop-only layout, no breakpoints |
| Compound document editor | ❌ | No UI for compositional transclusion |
| Visual diff view | ❌ | Three-way comparison UI not built |
| Trail builder | ❌ | No guided-path creation UI |
| Annotations | ❌ | No margin notes / highlights UI |

---

## Security & Cryptography

| Feature | Status | Details |
|---------|:------:|---------|
| Ed25519 signing/verification | ✅ | `src/crypto/sign.rs` |
| X25519 key exchange | ✅ | `src/crypto/kex.rs` |
| ChaCha20-Poly1305 AEAD | ✅ | `src/crypto/aead.rs` |
| HKDF key derivation | ✅ | `src/crypto/kdf.rs` with domain separation |
| Argon2 password hashing | ✅ | `src/crypto/password.rs` with PHC string format |
| Server key rotation | ✅ | `KeyHistory` with signed rotations |
| Club signing keys | ✅ | Encrypted at rest, decrypted on login |
| Five lock types | ✅ | BooLock, WallLock, ChallengeLock, MatchLock, MultiLock |
| Identity management | ✅ | 1115-line module: rate limiting, encrypted keys, session authority |
| Hash-chained audit log | ✅ | SHA-256 chained, tamper-evident |
| Hash-chained attribution log | ✅ | Append-only provenance record |
| TLS support | ✅ | rustls-based with configurable certs |
| CSRF protection | ✅ | Token-based for WebSocket connections |
| Panic containment | ✅ | `catch_unwind` at dispatch; mutex poison recovery |

---

## Persistence & Storage

| Feature | Status | Details |
|---------|:------:|---------|
| URDI file format | ✅ | Custom format with XUD1 magic, FNV-1a checksums |
| Snarf storage | ✅ | Fixed-size allocation blocks |
| Chunk store | ✅ | Content-chunked storage for editions/works |
| Manifest (v3) | ✅ | JSON-serialized: works, clubs, links, blobs, federation, governance |
| File-backed storage | ✅ | Filesystem-based persistent backend |
| Transaction support | ✅ | Atomic transaction support |
| Crash-safe writes | ✅ | tmp+rename atomic writes |
| Data compaction (packer) | ✅ | Storage compaction |
| Verification | ✅ | Data integrity verification |
| Startup verification | ❌ | No auto-detect/recover from corrupted data |
| fsync before rename | ❌ | Not yet implemented; writes may not be durable on crash |
| Async checkpoint | ❌ | Checkpoint runs synchronously, blocks dispatch |
| Adaptive storage tiering | ❌ | All data in local filesystem |

---

## Federation

| Feature | Status | Details |
|---------|:------:|---------|
| Federation foundation | ✅ | `FederationConfig`, `FederationState`, `PeerAddress` |
| PBFT governance | ✅ | `GovernanceProposal`, `PbftPhase` (PrePrepare/Prepare/Commit), sealed batches |
| Membership management | ✅ | Join requests, endorsements, verification |
| CRDT endorsement sync | ✅ | `OrSet<T>`, `LwwRegister<T>`, state reconciliation |
| Federated transclusion query | ✅ | Cross-server content lookup |
| Federated content fetch | ✅ | Cross-server content retrieval |
| Royalty tracking (data structures) | ✅ | `RoyaltyEntry`, `RoyaltyType` |
| Federation transport (encrypted) | ✅ | X25519 key exchange, ChaCha20-Poly1305 channels |
| Federation integration tests | ❌ | Unit tests exist; no multi-server E2E tests |
| Automatic peer discovery | ❌ | Peers must be manually configured |
| Automatic reconnection | ❌ | Not implemented |
| Production-ready federation | ❌ | Transport works; data sync incomplete |

---

## Xudanu-Exclusive Features

*Features that were NOT part of the original Ted Nelson Xanadu or Udanax Gold C++ implementation.*

### 🆕 LLM Integration

| Feature | Status | Details |
|---------|:------:|---------|
| Multi-backend LLM client | ✅ | Ollama (local), OpenRouter (cloud), GitHub Models (GPT-4o-mini) |
| Diff narration | ✅ | "Summarize Changes" — LLM describes document changes |
| Writing feedback | ✅ | LLM-generated writing critique |
| Auto-title generation | ✅ | Automatic document title from content |
| Usage tracking | ✅ | `LlmUsageTracker` — requests, tokens, per-feature stats |
| LLM attribution | ✅ | LLM text colored purple (#7c4dff), tagged with model name |
| Find related content | 🔧 | Stub defined, not connected |
| Link suggestion | 🔧 | Stub defined, not connected |

### 🆕 Cryptographic Provenance

| Feature | Status | Details |
|---------|:------:|---------|
| Per-element provenance (ElementProvenance) | ✅ | Author public key, display name, timestamp, author type |
| Span-level signatures | ✅ | Ed25519 over blake3(fingerprint + author + timestamp + server) |
| Historical author attestation | ✅ | Server-signed attestations for non-digital authors |
| Attribution transparency log | ✅ | Hash-chained append-only log for all provenance signatures |
| Attribution query | ✅ | `AttributionQuery` — look up author by content fingerprint |
| Attribution verification | ✅ | `AttributionVerify` — verify signature validity |
| Three author types | ✅ | Human (green), LLM (purple), Historical (amber) |

### 🆕 Collaborative Editing (CRDT)

| Feature | Status | Details |
|---------|:------:|---------|
| Yjs CRDT integration | ✅ | Full Yjs-based collaborative editing with signed updates |
| OTree CRDT (custom) | ✅ | Alternative custom CRDT with three-way merge |
| Awareness (cursors, typing) | ✅ | Real-time cursor positions, selection ranges, typing indicators |
| Author registration | ✅ | Public key + display name per CRDT author |
| Delta sync | ✅ | Client sends retain/delete/insert ops via common prefix/suffix diffing |
| Auto-save / materialization | ✅ | 3-second debounce; CRDT → Work revision |
| Signed updates | ✅ | Each edit signed by author's Ed25519 key |

### 🆕 Historical Author System

| Feature | Status | Details |
|---------|:------:|---------|
| Historical author registry | ✅ | Name, display name, birth/death years, external IDs (VIAF, LoC) |
| Source import pipeline | ✅ | Import historical texts with author attribution |
| Source format detection | ✅ | Pattern-based: Gutenberg, Internet Archive, plain text |
| Content boundary detection | ✅ | Skip header/footer boilerplate on import |
| Separate ID namespace | ✅ | Offset 1,000,000,000,000 for historical author IDs |

### 🆕 Source Content System

| Feature | Status | Details |
|---------|:------:|---------|
| Source works (immutable) | ✅ | `is_source: true`; rejected by revise/grab |
| Source pattern matching | ✅ | Configurable patterns with metadata extraction |
| Import wizard UI | ✅ | Multi-step: paste → detect → author → preview → import |

### 🆕 Modern Infrastructure

| Feature | Status | Details |
|---------|:------:|---------|
| Panic containment | ✅ | `catch_unwind` prevents crash cascades |
| Mutex poison recovery | ✅ | `unwrap_or_else` on all mutex operations |
| WebSocket JSON protocol | ✅ | Human-readable alternative to binary codec |
| React SPA frontend | ✅ | Modern TypeScript + Vite build chain |
| WASM compilation target | ⚠️ | Feature-gated; basic support exists |
| CSRF token protection | ✅ | WebSocket CSRF mitigation |

---

## Feature Roadmap Summary

*Prioritized from `docs/feature-roadmap.md`. Check off items as they're completed.*

### Tier A: Immediate (Low Effort, High Impact)

| # | Feature | Status |
|---|---------|--------|
| 1 | Cryptographic author attribution | ✅ Done |
| 2 | Verified user names in collaborative editing | ⚠️ Partial (server should override `user_name`) |
| 3 | Visible backlinks (always-on) | ❌ Not started |
| 4 | Annotations protocol surface | ❌ Not started |
| 5 | Link context / self-explaining links | ❌ Not started |
| 6 | Paginated list operations | ❌ Not started |
| 7 | Server-enforced awareness identity | ❌ Not started |

### Tier B: Near-Term (Medium Effort, Core Features)

| # | Feature | Status |
|---|---------|--------|
| 8 | Three-way visual comparison | ❌ Not started |
| 9 | Live transclusion rendering | ❌ Not started |
| 10 | Trails and guided paths | ❌ Not started |
| 11 | Permanent attribution on every fragment | ✅ Done |
| 12 | Real-time notification push | ⚠️ Partial (events buffered, not pushed immediately) |
| 13 | Inter-span links | ❌ Not started |
| 14 | Non-destructive archive | ❌ Not started |
| 15 | Export / interchange format | ❌ Not started |

### Tier C: Medium-Term (Larger Efforts)

| # | Feature | Status |
|---|---------|--------|
| 16 | Compound documents | 🔧 API stub only |
| 17 | Full-text search across all works | ❌ Not started |
| 18 | RwLock or sharded concurrency | ❌ Single global mutex |
| 19 | Unbounded resource limits (DoS hardening) | ⚠️ Some limits exist (max_works, max_blob_count) |
| 20 | BackfollowEngine duplicate elimination | ❌ Not started |
| 21 | Async checkpoint | ❌ Not started |
| 22 | Image preview generation | ❌ `generate_image_preview()` returns `None` |
| 23 | Federation integration tests | ❌ Not started |

---

## How to Update This Document

When completing a feature:

1. Find the relevant row(s) in the tables above
2. Update the status symbol (❌ → ⚠️ → ✅, or 🔧 for API-only)
3. Update the "Last updated" date at the top
4. If a roadmap item is completed, move it to ✅ in the Tier table
5. If adding a new feature, add rows to the relevant section and tag with 🆕 if it's Xudanu-exclusive
6. Update the "17 Rules" summary counts if any rule status changes

---

## Statistics

| Metric | Value |
|--------|-------|
| Rust source files | ~90+ |
| Total OperationCodes | 110+ |
| Total tests | 1799 passing |
| Frontend components | 16 (12 active, 4 legacy) |
| Frontend hooks | 2 (`useCrdtSync`, `useTransclusion`) |
| Crypto modules | 8 |
| Persistence modules | 15 |
| Edition sub-modules | 28 |
| Ent (enfilade) modules | 6 |
| Nelson's 17 rules: fully implemented | 8 |
| Nelson's 17 rules: partial | 5 |
| Nelson's 17 rules: not yet | 4 |
| Roadmap Tier A items done | 2 / 7 |
| Roadmap Tier B items done | 1 / 8 |
| Roadmap Tier C items done | 0 / 8 |
