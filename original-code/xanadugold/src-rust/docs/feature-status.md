# Xudanu Feature Status

> **Last updated:** 2026-08-06
> **Version:** 1.2.0
> **Tests:** 2764+ Rust lib tests, 271 integration tests, 548 frontend tests (~3583 total)
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

| # | Rule | Status | Notes |
|---|------|:------:|-------|
| 1 | Every server is uniquely and securely identified | ✅ | Ed25519 keypair per server, persistent identity, `/.well-known/xudanu-server.json` |
| 2 | Every server can operate independently or in a network | ✅ | Standalone works; FR-6 cross-server via XCP; FR-3 cluster federation (optional) |
| 3 | Every user is uniquely and securely identified | ✅ | Cryptographic identity: personal clubs with Ed25519 signing keys, Argon2 passwords, 7-day rolling session tickets |
| 4 | Every user can search, retrieve, create, and store documents | ✅ | Full CRUD: `work_create`, `work_grab`, `work_revise`, `work_release`, `work_list`, `global_text_search` |
| 5 | Every document can consist of any number of parts of any data type | ✅ | Text, blobs (images), editions (nested), inline transclusions, inline images |
| 6 | Every document can contain links including virtual copies (transclusions) | ✅ | Bidirectional typed links, inline transclusion rendering, span migration, provenance chains |
| 7 | Links are visible and can be followed from all endpoints | ✅ | Canvas overlay markers, connections panel, bidirectional navigation, backfollow panel |
| 8 | Permission to link is granted by the act of publication | ✅ | Publication model via read_club semantics; publish button in UI |
| 9 | Every document can contain a royalty mechanism at any granularity | ⚠️ | Royalty ledger tracks obligations; no payment flow |
| 10 | Every document is uniquely and securely identified | ✅ | Content-addressed via BeIds in GrandMap; BLAKE3 fingerprints; domain-based tumblers |
| 11 | Every document can have secure access controls | ✅ | Club-based read_club/edit_club; enforced in dispatch layer; server directory trust management |
| 12 | Every document can be rapidly searched/stored/retrieved transparently | ✅ | Server abstracts storage; content-addressed blobs; work IDs; global text search |
| 13 | Every document is automatically moved to appropriate physical storage | ❌ | No adaptive storage tiering; all data in local filesystem |
| 14 | Every document is redundantly stored for disaster recovery | ⚠️ | Crash-safe checkpoint with tmp+fsync+rename; no geographic replication |
| 15 | Every service provider can charge users at any rate | ⚠️ | Cost model structures exist; royalty ledger tracks obligations; no billing infrastructure |
| 16 | Every transaction is secure and auditable only by the parties | ✅ | Encrypted federation channels; hash-chained audit log; per-transaction Ed25519 signatures |
| 17 | The client-server protocol is an openly published standard | ✅ | WebSocket JSON protocol documented; 140+ operations; XCP cross-server spec published |

**Summary: 10 fully implemented, 4 partial, 3 not yet.**

---

## Core Xanadu Concepts

### Transclusion

| Feature | Status | Details |
|---------|:------:|---------|
| Content-addressed identity (BLAKE3) | ✅ | `RangeElement::content_fingerprint()` produces 32-byte BLAKE3 hashes |
| TransclusionIndex (fingerprint to works) | ✅ | Reverse index from content to containing editions/works |
| ContentAddressIndex (fingerprint to BeIds) | ✅ | Bidirectional mapping, content-addressed deduplication |
| Find transcluders of content | ✅ | `find_transcluders()`, `find_works_for_content()` — wired to UI backfollow panel |
| Find shared regions between documents | ✅ | `content_shared_region()`, `content_map_shared_to/onto()` |
| Transclusion depth counting | ✅ | `count_transclusion_depth()`, `find_deeply_transcluded()` |
| Range-based transclusion queries | ✅ | `range_transcluders()`, `range_works()` — wired to "Where is this used?" panel |
| Live transclusion rendering | ✅ | Inline rendering via `buildTransclusionDom`, zero-width CRDT elements, \n stripping |
| Compound documents (compositional transclusion) | ✅ | Compound Builder UI, `resolveInlineTransclusions`, recursive resolution (32 levels), cycle detection |
| Transclusion markers in editor | ✅ | Canvas overlay draws colored sidebar bars; inline blue bars with navigation |
| Transclusion workflow (select to navigate to place) | ✅ | Frontend workflow: select text, navigate to target, click to place |
| Reading vs authoring mode | ✅ | Toggle: reading hides markers; authoring shows all markers |
| Source-changed detection | ✅ | BLAKE3 hash comparison, FR-26 revision pinning, "source changed" badge |
| Cross-server transclusion | ✅ | Domain-based tumblers, public content API, BLAKE3 verification, cache |
| Provenance chain (Gold's again()) | ✅ | `workTransclusionChain` walks 32 levels deep, cycle-guarded; UI displays chain |
| Selection across transclusion boundaries | ✅ | Unified position mapper, `selection-segments.ts`, multi-source selection |

### Bidirectional Links

| Feature | Status | Details |
|---------|:------:|---------|
| Multi-ended links (HyperLink) | ✅ | Named ends (LeftEnd, RightEnd, arbitrary names), link type IDs |
| HyperRef with excerpts | ✅ | `HyperRefKind::Single` with optional excerpt edition |
| Composite references (Multi) | ✅ | `HyperRefKind::Multi` with nested refs |
| Provenance chains on links | ✅ | `ProvenanceHop` chain tracking copy lineage through multiple works |
| Link CRUD operations | ✅ | Create, Get, Update, Delete, ListForWork |
| Bidirectional link tracking | ✅ | Links tracked from both endpoints |
| Typed links (5 built-in types) | ✅ | Comment, Reference, Disagreement, Quotation, See Also |
| Link filtering by type | ✅ | UI filter buttons in Connections panel |
| Link descriptions (margin notes) | ✅ | Resolvable/unresolvable descriptions with edit UI |
| Span migration | ✅ | Links survive edits via space algebra displacement tracking |
| Cross-server backlinks | ✅ | Automatic backlink notifications between servers |
| Link context / self-explaining links | ✅ | `work_context`/`original_context`/`path_context` fields, provenance chain on links |

### Versioning

| Feature | Status | Details |
|---------|:------:|---------|
| Full revision history | ✅ | `BTreeMap<u64, Edition>` per work; `fetch_revision(n)` |
| DagWood partial ordering | ✅ | `is_le(a, b)` for version ancestry; binary-tree branching |
| Version ancestry queries | ✅ | `version_ancestors()`, `version_descendants()`, `version_ancestors_transitive()` |
| Trace position | ✅ | `(BranchId, u32)` for precise version locating |
| Snapshots / freezing | ✅ | Immutable snapshots; published works are frozen |
| Three-way diff | ✅ | `three_way_diff()` and `three_way_merge()` with conflict detection |
| Three-way visual comparison | ✅ | `ComparePanel`, `ThreeWayDiffPanel` with merge UI |
| Revision timeline UI | ✅ | Notable revisions, descriptions, rollback, version genealogy |
| Auto-save with revision | ✅ | Save button marks notable revisions; auto-save indicator |

### Back-Following

| Feature | Status | Details |
|---------|:------:|---------|
| BackfollowEngine | ✅ | Core reverse-navigation engine (1400+ lines) |
| Canopy-filtered H-tree traversal | ✅ | Flag-bit pruning for O(log n) queries |
| BertCanopy (permission/endorsement filtering) | ✅ | Binary tree with upward flag propagation |
| SensorCanopy (recorder installation) | ✅ | Recorder installation tree |
| Recursive back-following through versions | ✅ | `delayed_store_backfollow()` via H-tree traversal |
| Federated transclusion entries | ✅ | Entries from remote servers indexed locally |
| Backfollow UI ("Where is this used?") | ✅ | Connections panel: click Find, see all reusing documents |

### Publication & Access Control

| Feature | Status | Details |
|---------|:------:|---------|
| Publication model (Rule 8) | ✅ | `publish()` / `unpublish()` / `irrevocably_unpublish()`; publish button in UI |
| Read-club / edit-club semantics | ✅ | Per-work `read_club` and `edit_club` fields |
| Club membership management | ✅ | `add_member`, `remove_member`, `members` |
| Default read/edit clubs | ✅ | `default_read_club`, `default_edit_club` on clubs |
| Public/private visibility toggle | ✅ | Publish button; public content API |
| Share/unshare (edit access) | ✅ | Share to public club or restrict to owner |
| Server directory | ✅ | Add/remove/trust servers; auto-discovery via well-known endpoint |
| License enforcement | ✅ | 5 license types (ARR, Transcopyright, CC-BY, CC-BY-SA, PD); ARR warning on transclusion |
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
| O-tree CRDT | ✅ | Custom O-tree CRDT with space algebra (region/displacement); not Yjs |

---

## Udanax Gold Data Structures

| Structure | Status | Rust Location | Notes |
|-----------|:------:|---------------|-------|
| **Edition** | ✅ | `src/edition/edition.rs` | Ordered immutable `(i64, Carrier)` collection |
| **RangeElement** | ✅ | `src/edition/range_element.rs` | 9 variants: Text, Data, Blob, Edition, Label, PlaceHolder, IDHolder, Work, Transclusion |
| **Carrier** | ✅ | `src/edition/range_element.rs` | RangeElement + optional Provenance |
| **Work** | ✅ | `src/edition/work.rs` | Mutable document with revision history, access clubs, endorsements |
| **Club** | ✅ | `src/server/club.rs` | Identity/principal: members, credentials, signing keys |
| **XnRegion** | ✅ | `src/edition/xn_region.rs` | Interval-based position sets with set algebra |
| **Mapping** | ✅ | `src/edition/mapping.rs` | Affine transforms (shift, compose, invert) |
| **OrglRoot (O-tree)** | ✅ | `src/edition/orgl.rs` | BTree-based storage, core data structure |
| **Label / LabelledCarrier** | ✅ | `src/edition/label.rs` | Label addressing, identity maps |
| **Bundle** | ✅ | `src/edition/bundle.rs` | Element/Array/PlaceHolder bundles with retrieve() and cost() |
| **HyperLink / HyperRef** | ✅ | `src/edition/links.rs` | Bidirectional link system with set operations, CrossServerRef |
| **Path** | ✅ | `src/edition/links.rs` | Navigation through nested editions with resolver |
| **Wrapper types** | ✅ | `src/edition/wrapper.rs` | Text, Set, Path, HyperLink, HyperRef classification |
| **Canopy** | ✅ | `src/edition/canopy.rs` | Binary tree filtering with flag propagation |
| **ContentPool** | ✅ | `src/edition/pool.rs` | Hash-indexed deduplication pool |
| **BlobStore** | ✅ | `src/edition/blob_store.rs` | Content-addressed binary storage with filesystem backend, preview generation |
| **TransclusionIndex** | ✅ | `src/edition/transclusion.rs` | Fingerprint-based reverse index |
| **BackfollowEngine** | ✅ | `src/edition/backfollow.rs` | Reverse navigation with canopy filtering |
| **Recorder / Fossil** | ✅ | `src/edition/recorder.rs` | Content-watch monitoring with sensor canopy |
| **BeStorage / InMemoryBeStorage** | ✅ | `src/edition/backend.rs` | Persistent storage trait |
| **Tumbler** | ✅ | `src/edition/tumbler.rs` | Domain-based hierarchical addressing for cross-server refs |

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
| CSRF token | ✅ | Optional token-based for WebSocket connections |

### Operation Groups (140+ operations)

| Range | Group | Status | Operations |
|-------|-------|:------:|------------|
| 0x00xx | Session | ✅ | Connect, Disconnect, Login, LoginByName, Authenticate, LoginPublic, TicketIssue, TicketRedeem |
| 0x01xx | Entity retrieval | ✅ | GetById, GetByBeId |
| 0x02xx | Club | ✅ | Create, CreateNamed, Get, ByName, IdByName, NameById, Names, WhoAmI, SetPassword, ClearCredential, CreatePersonal, AddMember, RemoveMember, Members |
| 0x03xx | Work | ✅ | Create, GetEdition, Revise, ReviseDelta, Grab, Release, SaveAndRelease, IsGrabbed, RevisionCount, FetchRevision, SetReadClub, SetEditClub, Publish, Unpublish, List, Star/Unstar, Goto |
| 0x04xx | Edition | ✅ | Store, Get |
| 0x05xx | Admin | ✅ | AcceptConnections, IsAcceptingConnections, ActiveSessions, Shutdown, Grant, RevokeGrant |
| 0x06xx | Stats | ✅ | ServerStats |
| 0x07xx | Links | ✅ | Create, Get, Update, Delete, ListForWork, FindExcerptPositions |
| 0x08xx | Transclusion | ✅ | FindTranscluders, FindWorksForContent, FindTextTranscluders, ProvenanceAncestry |
| 0x09xx | Blobs | ✅ | Upload, Get, GetPreview, Exists, Info, Stats, ListForWork |
| 0x0Cxx | Retrieval | ✅ | Retrieve, Cost |
| 0x0Dxx | Attribution/Search | ✅ | AttributionQuery, AttributionLogStatus, WorkSearch, WorkGoto, HistoricalAuthor, ImportSourceWork |
| 0x0Exx | Shared Content | ✅ | ContentSharedRegion, ContentMapSharedTo, ContentMapSharedOnto |
| 0x0Fxx | Range Queries | ✅ | RangeTranscluders, RangeWorks, CrossServerResolve |
| 0x10xx | Versioning | ✅ | VersionIsBefore, VersionAncestors, VersionDescendants |
| 0x12xx | Crypto | ✅ | GetPublicKey, SignData, VerifySignature |
| 0x13xx | Endorsements | ✅ | WorkEndorse/Retract/Endorsements |
| 0x14xx | Federation | ✅ | FederationInfo, FederationPeers |
| 0x17xx | Federated Content | ✅ | FederatedTransclusionQuery, FederatedContentFetch, BlobGet |
| 0x19xx | Membership | ✅ | JoinRequest/Response, Endorse, Sync, Verify |
| 0x1Bxx | Governance | ✅ | Propose, Prepare, Commit, Seal (PBFT) |
| 0x1Cxx | CRDT | ✅ | SyncOpen/Close/Update/Diff, AwarenessUpdate, RegisterAuthor |
| 0x1Exx | Inline Transclusion | ✅ | ResolveInlineTransclusions, ElementInsert/Update, TransclusionChain |
| 0x0349+ | Social | ✅ | Annotation CRUD, Trail CRUD, Star/Pin, Server Directory |

### Server Infrastructure

| Feature | Status | Details |
|---------|:------:|---------|
| Session management | ✅ | Login state tracking, authority, active sessions, 7-day rolling tickets |
| Event subscription | ✅ | Detector/subscription-based event delivery |
| Grab/release locking | ✅ | Cooperative edit locks with waiters queue |
| Auto-checkpoint | ✅ | Time-based with tmp+fsync+rename atomic writes; async checkpoint |
| Graceful shutdown | ✅ | Checkpoint on shutdown signal |
| Panic containment | ✅ | `catch_unwind` in dispatch; mutex poison recovery |
| Admin controls | ✅ | Connection gating, shutdown, grants |
| Static file serving | ✅ | `--static-dir` for custom frontends |
| Server directory | ✅ | Auto-discovery via `/.well-known/xudanu-server.json`, trust management |
| Public content API | ✅ | `/api/public/work/{id}`, range fetch, backlink notification |
| Signing key cache | ✅ | In-memory cache restores provenance signing key on ticket reconnect |

---

## Frontend / User Interface

### React Application (Primary UI)

| Feature | Status | Component |
|---------|:------:|-----------|
| Workspace shell | ✅ | `WorkspaceShell` — 3-column layout, collapsible panels |
| Document list sidebar | ✅ | Recent list, starred section, search, sort |
| Collaborative editor | ✅ | `CollaborativeEditor` — contentEditable with canvas overlay |
| Inline transclusion rendering | ✅ | `editor-dom-utils.ts` — `buildTransclusionDom`, zero-width elements |
| Inline image rendering | ✅ | `insertInlineImages` — images as CRDT elements at char positions |
| Image resize + deletion guard | ✅ | Horizontal resize handle, confirmation on delete |
| Attribution overlay | ✅ | Canvas overlay with per-author coloring |
| Transclusion markers | ✅ | Colored sidebar bars, hover tooltips, click navigation |
| Transclusion workflow | ✅ | Select to navigate to place with TransclusionBadge |
| Compound Builder | ✅ | Searchable source picker, section numbering, word count, placement modes |
| Connections panel | ✅ | Outgoing links, backlinks, transclusions, "Where used?", provenance chain |
| Link filtering | ✅ | Filter by type in Connections panel |
| Link descriptions | ✅ | Resolvable margin notes with edit UI |
| Revision timeline | ✅ | Notable revisions, descriptions, rollback |
| Three-way comparison | ✅ | ComparePanel, ThreeWayDiffPanel with merge |
| Trails | ✅ | TrailsPanel, trail creation, ordered stops, categories |
| Annotations | ✅ | AnnotationDialog, AnnotationPanel, private annotations |
| Document map | ✅ | Force-directed graph with pre-warmed layout, tamed animation |
| Search | ✅ | Global search overlay, in-document search |
| Attribution panel | ✅ | Proportional bar, per-author breakdown, chain validity, identity resolution |
| Awareness indicators | ✅ | Cursor positions, selections, typing indicators |
| Identity panel | ✅ | Create/login/logout, club details, public key |
| Import wizard | ✅ | 6-step: paste to detect to author to preview to done |
| Historical authors | ✅ | Registry, search, import with attribution |
| LLM features | ✅ | Summarize changes, writing feedback, auto-title, auto-tag |
| Reading/authoring mode | ✅ | Toggle: reading hides markers; authoring shows all |
| Auto-save indicator | ✅ | Saving/Saved/Error states in document header |
| Publish button | ✅ | Make work accessible from other servers |
| Remote link fetch | ✅ | Enter server URL + work ID, auto-populate cross-server ref |
| Auto-reconnect | ✅ | Tiered: 200ms, 500ms, 1s, then exponential backoff |
| Session tickets | ✅ | 7-day rolling renewal, localStorage persistence |
| Docker deployment | ✅ | docker-compose.yml, multi-stage Dockerfile, 3-node demo |
| Identity badge | ✅ | Avatar, name, color, click for details |
| Hash deep-linking | ✅ | `?work=0xID`, `#L<line>`, `#C<char>` |

### Missing / Planned UI

| Feature | Status | Details |
|---------|:------:|---------|
| Global dark mode | ✅ | Light/dark/auto theme support with picker |
| Mobile/responsive | ⚠️ | Basic responsive layout; not fully mobile-optimized |
| Spatial document layout | ❌ | No multi-zone page layout for content placement |
| Awareness bar | ❌ | Presence bar removed during UI consolidation |

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
| Club signing keys | ✅ | Encrypted at rest, decrypted on login, cached for ticket reconnect |
| Five lock types | ✅ | BooLock, WallLock, ChallengeLock, MatchLock, MultiLock |
| Identity management | ✅ | Rate limiting, encrypted keys, session authority |
| Hash-chained audit log | ✅ | SHA-256 chained, tamper-evident |
| Hash-chained attribution log | ✅ | Append-only provenance record |
| TLS support | ✅ | rustls-based with configurable certs |
| CSRF protection | ✅ | Optional token-based for WebSocket connections |
| OAuth2 | ✅ | GitHub, Google providers |
| SSRF protection | ✅ | `is_ssrf_address` guards cross-server fetches |

---

## Persistence & Storage

| Feature | Status | Details |
|---------|:------:|---------|
| URDI file format | ✅ | Custom format with XUD1 magic, FNV-1a checksums |
| Snarf storage | ✅ | Fixed-size allocation blocks |
| Chunk store | ✅ | Content-chunked storage for editions/works |
| Manifest (v4) | ✅ | JSON-serialized: works, clubs, links, blobs, federation, social, governance |
| File-backed storage | ✅ | Filesystem-based persistent backend |
| Transaction support | ✅ | Atomic transaction support |
| Crash-safe writes | ✅ | tmp+fsync+rename atomic writes |
| Data compaction (packer) | ✅ | Storage compaction |
| Verification | ✅ | Data integrity verification |
| Startup verification | ✅ | Preflight check before server start |
| fsync before rename | ✅ | Hardened persistence with fsync |
| Async checkpoint | ✅ | Non-blocking checkpoint via spawn_blocking |
| WAL (Write-Ahead Log) | ✅ | Annotation, trail, star, pin operations journaled |
| Dual manifest slots | ✅ | A/B rotation for crash recovery |
| Ticket nonce sidecar | ✅ | Lightweight file for session ticket nonces |
| Image preview generation | ✅ | `generate_image_preview()` with image crate (PNG/JPEG/GIF/WebP/BMP) |
| Adaptive storage tiering | ❌ | All data in local filesystem |

---

## Federation

### FR-6: Linked Independent Servers (Default)

| Feature | Status | Details |
|---------|:------:|---------|
| Server identity | ✅ | `/.well-known/xudanu-server.json` with server_namespace_id |
| Public content API | ✅ | `/api/public/work/{id}`, range fetch |
| Server directory | ✅ | Add/remove/trust, auto-discovery via well-known |
| Cross-server resolve | ✅ | `resolve_cross_server_ref` with BLAKE3 verification, SSRF guards |
| Cross-server backlinks | ✅ | `/api/backlink-notify`, bidirectional |
| Domain-based tumblers | ✅ | `"alice.example.com".5.3.10.7` |
| XCP protocol | ✅ | Published spec (v1.0 deployed, v1.1 drafted) |

### FR-3: Cluster Federation (Optional)

| Feature | Status | Details |
|---------|:------:|---------|
| Federation foundation | ✅ | `FederationConfig`, `FederationState`, `PeerAddress` |
| PBFT governance | ✅ | `GovernanceProposal`, `PbftPhase` (PrePrepare/Prepare/Commit), sealed batches |
| Membership management | ✅ | Join requests, endorsements, verification |
| CRDT endorsement sync | ✅ | `OrSet<T>`, `LwwRegister<T>`, state reconciliation |
| Federated transclusion query | ✅ | Cross-server content lookup |
| Federated content fetch | ✅ | Cross-server content retrieval, blob sharing |
| Royalty tracking | ✅ | `RoyaltyEntry`, `RoyaltyType` in governance transactions |
| Federation transport (encrypted) | ✅ | X25519 key exchange, ChaCha20-Poly1305 channels |
| Federation integration tests | ✅ | Content replication, membership convergence, cross-server transclusion |
| Outbound dialer | ✅ | Exponential backoff reconnect, PeerPool management |
| Production-ready federation | ⚠️ | Transport works; data sync functional; operational friction (pre-shared keys) |

---

## Xudanu-Exclusive Features

### 🆕 LLM Integration

| Feature | Status | Details |
|---------|:------:|---------|
| Multi-backend LLM client | ✅ | Ollama (local), OpenRouter (cloud), GitHub Models (GPT-4o-mini) |
| Diff narration | ✅ | "Summarize Changes" — LLM describes document changes |
| Writing feedback | ✅ | LLM-generated writing critique |
| Auto-title generation | ✅ | Automatic document title from content |
| Auto-tag concepts | ✅ | Automatic concept extraction and linking |
| Usage tracking | ✅ | `LlmUsageTracker` — requests, tokens, per-feature stats |
| LLM attribution | ✅ | LLM text colored purple, tagged with model name |

### 🆕 Cryptographic Provenance

| Feature | Status | Details |
|---------|:------:|---------|
| Per-element provenance (ElementProvenance) | ✅ | Author public key, display name, timestamp, author type |
| Span-level signatures | ✅ | Ed25519 over blake3(fingerprint + author + timestamp + server) |
| Historical author attestation | ✅ | Server-signed attestations for non-digital authors |
| Attribution transparency log | ✅ | Hash-chained append-only log for all provenance signatures |
| Attribution query | ✅ | Look up author by content fingerprint; identity-based name resolution |
| Attribution verification | ✅ | Verify signature validity |
| Three author types | ✅ | Human (green), LLM (purple), Historical (amber) |
| Signing key cache | ✅ | In-memory cache ensures provenance survives reconnects |
| W3C PROV-JSON export | ✅ | Federation provenance bundles, PROV-JSON validator |

### 🆕 Collaborative Editing (O-tree CRDT)

| Feature | Status | Details |
|---------|:------:|---------|
| Custom O-tree CRDT | ✅ | Position-based CRDT using space algebra (region/displacement) |
| Real-time collaboration | ✅ | Multi-user concurrent editing, automatic convergence |
| Awareness (cursors, typing) | ✅ | Real-time cursor positions, selection ranges, typing indicators |
| Author registration | ✅ | Public key + display name per CRDT author |
| Delta sync | ✅ | Client sends retain/delete/insert ops via common prefix/suffix diffing |
| Auto-save / materialization | ✅ | Debounced; CRDT to Work revision with provenance stamping |
| Signed updates | ✅ | Each edit signed by author's Ed25519 key |

### 🆕 Images as CRDT Elements

| Feature | Status | Details |
|---------|:------:|---------|
| Images as RangeElement::Blob | ✅ | First-class CRDT elements with char positions, span migration |
| Content-addressed blob store | ✅ | BLAKE3 hash deduplication, preview generation |
| Inline rendering | ✅ | `insertInlineImages` walks text nodes, inserts at positions |
| Image resize | ✅ | Horizontal drag resize handle with live size label |
| Deletion guard | ✅ | Confirmation dialog on Backspace/Delete near images |

### 🆕 License Enforcement

| Feature | Status | Details |
|---------|:------:|---------|
| 5 license types | ✅ | ARR, Transcopyright, CC-BY, CC-BY-SA, Public Domain |
| License metadata | ✅ | Per-work license field, UI picker |
| ARR warning | ✅ | Confirmation dialog when transcluding ARR content |
| Compliance badges | ✅ | Transclusion compliance indicators |
| License help | ✅ | Modal explaining each license type |

### 🆕 Modern Infrastructure

| Feature | Status | Details |
|---------|:------:|---------|
| Docker deployment | ✅ | Multi-stage Dockerfile, docker-compose for 3-node demo |
| Panic containment | ✅ | `catch_unwind` prevents crash cascades |
| Mutex poison recovery | ✅ | `unwrap_or_else` on all mutex operations |
| WebSocket JSON protocol | ✅ | Human-readable alternative to binary codec |
| React SPA frontend | ✅ | TypeScript + Vite, 30+ components, 548 tests |
| WASM compilation target | ⚠️ | Feature-gated; basic support exists |
| Vite HMR compatible | ✅ | Editor DOM utils separated for Fast Refresh |

---

## Feature Roadmap Summary

### Tier A: Immediate (Low Effort, High Impact)

| # | Feature | Status |
|---|---------|--------|
| 1 | Cryptographic author attribution | ✅ Done |
| 2 | Verified user names in collaborative editing | ✅ Done |
| 3 | Visible backlinks (always-on) | ✅ Done |
| 4 | Annotations protocol surface | ✅ Done |
| 5 | Link context / self-explaining links | ✅ Done |
| 6 | Paginated list operations | ✅ Done |
| 7 | Server-enforced awareness identity | ✅ Done |

### Tier B: Near-Term (Medium Effort, Core Features)

| # | Feature | Status |
|---|---------|--------|
| 8 | Three-way visual comparison | ✅ Done |
| 9 | Live transclusion rendering | ✅ Done |
| 10 | Trails and guided paths | ✅ Done |
| 11 | Permanent attribution on every fragment | ✅ Done |
| 12 | Real-time notification push | ✅ Done |
| 13 | Inter-span links | ✅ Done |
| 14 | Non-destructive archive | ❌ Not started |
| 15 | Export / interchange format | ❌ Not started |

### Tier C: Medium-Term (Larger Efforts)

| # | Feature | Status |
|---|---------|--------|
| 16 | Compound documents | ✅ Done |
| 17 | Full-text search across all works | ✅ Done |
| 18 | RwLock or sharded concurrency | ❌ Single global mutex |
| 19 | Unbounded resource limits (DoS hardening) | ⚠️ Some limits exist |
| 20 | BackfollowEngine duplicate elimination | ✅ Done |
| 21 | Async checkpoint | ✅ Done |
| 22 | Image preview generation | ✅ Done |
| 23 | Federation integration tests | ✅ Done |

---

## Statistics

| Metric | Value |
|--------|-------|
| Rust source files | ~100+ |
| Total OperationCodes | 140+ |
| Total tests | ~3583 (2764+ Rust lib, 271 integration, 548 frontend) |
| Frontend components | 30+ |
| Frontend hooks | 4 (`useCrdtSync`, `useTransclusion`, `useCompoundEdition`, `useDraggable`) |
| Crypto modules | 8 |
| Persistence modules | 15+ |
| Edition sub-modules | 30+ |
| Nelson's 17 rules: fully implemented | 10 |
| Nelson's 17 rules: partial | 4 |
| Nelson's 17 rules: not yet | 3 |
| Roadmap Tier A items done | 7 / 7 |
| Roadmap Tier B items done | 6 / 8 |
| Roadmap Tier C items done | 7 / 8 |
