# Xudanu: What's New Since Udanax Gold

A summary of features and capabilities added to the Xudanu reimplementation that go beyond the original Udanax Gold system.

---

## Cryptographic Provenance

Every edit is signed with Ed25519. Each element carries `ElementProvenance` with author public key, display name, timestamp, and server ID. The signature covers `BLAKE3(fingerprint || author_key || timestamp || server_id)` with domain separation. An append-only SHA-256 hash-chained transparency log records every provenance signature, making forgery detectable after the fact.

Gold had no cryptographic attribution — authorship was asserted, not proven.

## Three Author Types

The system distinguishes Human (green), LLM (purple), and Historical (amber) authorship. LLM-generated text is tagged with the model name. Historical authors (Shakespeare, Austen, etc.) are registered with a generic `external_ids` field for authority database lookups, and receive server-signed attestations. VIAF and LoC both expose free public APIs that return stable IDs from an author name, but these are not yet wired into the import wizard.

## Three-Way Merge for Collaborative Editing

O-tree elements are merged directly — not flattened text. Uses BLAKE3 fingerprint alignment, segment classification (Unchanged/OnlyA/OnlyB/Conflict/Insert), and composable position mappings. Collaborative edits preserve transclusions, overlays, data bindings, and attribution. Gold was single-user only.

## Content-Addressed Chunk Store

Document content is stored as individually addressable `.xchunk` files in hex-sharded directories, each verified by BLAKE3 hash. Checkpoints write only changed chunks, not the entire state. LRU cache (capacity 1024) for hot chunks. Atomic writes via tmp+rename. Off-site backup via `backup-chunks.sh` syncs immutable chunks + manifests to a remote server via rsync/SSH. Blobs and server keys are intentionally excluded — blobs need separate sync, keys need out-of-band transfer.

Gold used in-memory Smalltalk object storage with no persistence.

## Modern Web Frontend

React SPA with TypeScript, real-time collaborative editing via WebSocket, canvas-based attribution overlays, virtualized rendering for documents over 100K characters, side-by-side comparison with bridge curves connecting transcluded regions, source text import wizard, and annotation system with keyboard shortcuts.

Gold had a terminal/Motif UI.

## Historical Author and Source Import

Pattern-based detection for Project Gutenberg, Internet Archive, and plain text. Registry for non-digital authors with external IDs. Content boundary detection to skip header/footer boilerplate. Source works are permanently frozen — no edits allowed. Content matching on paste automatically attributes provenance to historical authors.

## LLM Integration

Multi-backend support (Ollama for local, OpenRouter/GitHub Models for cloud). Diff narration ("summarize changes"), auto-title generation, and on-demand writing feedback. All LLM output is cryptographically tagged in the provenance system.

## Club-Based Identity

Personal "clubs" with Ed25519 keypairs encrypted at rest (Argon2id key derivation + ChaCha20-Poly1305 AEAD). Rate-limited login (10 attempts per 5 minutes per club). Argon2id password hashing with PHC-string format. GitHub and Google OAuth2 login with session cookies.

## Federation with Byzantine Fault Tolerance

Encrypted peer channels (X25519 + ChaCha20-Poly1305). OrSet and LwwRegister CRDTs for state reconciliation. PBFT governance for membership and policy decisions. Cross-server transclusion queries.

## Security

CSRF token protection for WebSocket connections. SHA-256 chained tamper-evident audit log. Threat-level classification for security events. HttpOnly session cookies. Server key encryption at rest.

## Wire Protocol

110+ operation codes covering sessions, clubs, works, editions, links, transclusion, blobs, overlays, labels, retrieval, attribution, search, shared content, range queries, versioning, recorders, crypto, endorsements, federation, membership, governance, and CRDT sync. Dual codec: binary (LEB128 + postcard) and JSON.

---

# Classic Xanadu Features Not Yet Implemented

Features from Ted Nelson's original vision that remain to be built.

## Live Transclusion Rendering

Content is *found* (BackfollowEngine, TransclusionIndex work) but not rendered in-place with live updates. No resolution engine or rendering pipeline for showing transcluded fragments inline with visible markers.

## Compound Documents (Compositional Transclusion)

`CompoundResolve` opcode and `CompoundSpan`/`CompoundElement` stubs exist in `src/edition/compound.rs` but there is no resolution engine or UI. This was Nelson's central feature — documents assembled from live pieces of other documents, not copies.

## Trails and Guided Paths

No trail builder UI or data model for curated paths through multiple documents (guided reading sequences). Envisioned by both Nelson and Vannevar Bush.

## Inter-Span Links

Links operate at work-level granularity. No `(work, edition, start_position, end_position)` targeting — i.e., "this sentence responds to that paragraph." `HyperRef::Single` has an optional excerpt field but the protocol doesn't expose span-level targeting.

## Three-Way Visual Diff UI

Backend has `three_way_diff()` and `three_way_merge()` with full conflict detection. No visual character-level diff UI. Nelson considered showing exactly what changed between versions essential.

## Royalty/Micropayment System

Data structures exist (`StorageCost`, `CostMethod`, `RoyaltyEntry`, `RoyaltyType`) and the `cost()` method on editions is fully implemented. But no payment flow, billing system, or micropayment infrastructure. Nelson's Rule 9: "Royalty at Any Granularity."

## Adaptive Storage Tiering

No hot/cold storage migration. All data lives in the local filesystem. Nelson's Rule 13: physical storage appropriate to access frequency.

## Geographic Replication

Crash-safe checkpoint with tmp+rename exists. Off-site backup script (`backup-chunks.sh`) syncs immutable chunks + manifests via rsync/SSH, but excludes blobs and server keys. Federation transport exists but data sync is incomplete — once finished, it would provide automatic multi-node replication. Nelson's Rule 14: redundant storage.

## Export / Interchange Format

No way to export a work or web of works to a portable format. Nelson wanted documents universally portable.

## Version Genealogy UI

API operations exist (`version_is_before`, `version_ancestors`, `version_descendants`) but no UI visualizing the version tree or ancestry graph.

## Non-Destructive Archive

`WorkIrrevocablyUnpublish` is destructive and permanent. Nelson was fanatical that nothing should ever be truly deleted, only hidden. No `is_archived` flag or soft-delete mechanism.

## Mobile/Responsive Layout

Desktop-only. No breakpoints for mobile devices.

## Global Dark Mode

Only the debug panel is dark. No global theme toggle.

## Full-Text Search

`find_text_transcluders` does transclusion-oriented search by fingerprint. No general inverted-index search across all works.

## Verified User Names in Collaborative Editing

`crdt_awareness_update` accepts `user_name` from the client without server-side verification. Any connected user can impersonate any other user.

## Write Lock Serialization

The server uses `Arc<RwLock<Server>>`, allowing concurrent reads via `with_server_ref` (health checks, blob reads, session lookups). Gold was single-threaded with no concurrency at all. However, mutations acquire an exclusive write lock via `with_server`, serializing edits and saves — the bottleneck for write-heavy workloads.

---

# Gold Features Not Yet in Xudanu

Features present in the Udanax Gold C++ codebase that have no equivalent in Xudanu.

## Tumbler / Sequence Addressing

Gold had full `Sequence` positions (variable-length integer tuples like `1.2.3.4`) with `SequenceSpace`, interval regions, prefix queries, and `SequenceMapping` with shift+translation. `SequenceRegion` had three edge types: `INCLUSIVE`, `EXCLUSIVE`, `PREFIX`. Xudanu's `Sequence` uses simple `Vec<i64>` with no hierarchical tumbler addressing or prefix-bounded queries. Core Xanadu concept (Rule 5).

## Multi-Dimensional Coordinate Spaces

Gold had `CoordinateSpace` (base), `IntegerSpace`, `RealSpace`, `SequenceSpace`, `IDSpace`, `CrossSpace`, `FilterSpace`. `CrossSpace` supported multi-axis coordinates for endorsements. Xudanu has `src/space/` with partial implementations — `RealSpace` is stubbed, `FilterSpace` is minimal, `CrossSpace` is partial. Core Xanadu concept.

## CrossRegion Endorsements

Gold stored endorsements as `CrossRegion` over `IDSpace × EndorsementSpace` — multi-dimensional sets with `boxes()`, `projection()`, `isBox()` operations. Xudanu uses flat `BTreeSet<Endorsement>` — no cross-space operations. Gold also supported per-region endorsements within an edition (`endorse(CrossRegion)`, `retract(CrossRegion)`); Xudanu's `EndorsementSet` is edition-wide only.

## Work Sponsors

Gold had `Work::sponsor(IDRegion clubs)` — a separate relationship from read/edit clubs. Sponsors vouched for a work's existence. Xudanu has no sponsor concept — only `read_club`, `edit_club`.

## Work History Club

Gold had a separate `historyClub` controlling access to revision history, distinct from read/edit access. Xudanu exposes history to anyone with read access.

## Club Recursive Membership

Gold's `ClubDescription` contained a `Set` of member clubs. Clubs could contain other clubs with recursive membership resolution. Xudanu's clubs are flat — no nesting, no delegation of authority.

## KeyMaster Authority Delegation

Gold's `KeyMaster` accumulated authority from multiple logins and could `incorporate(KeyMaster other)` to merge authorities or `removeLogins(IDRegion)` to revoke. Xudanu's `KeyMaster` checks `has_authority()` but cannot merge or delegate authority.

## ID Space with Batch Allocation

Gold had `IDSpace::global()` / `IDSpace::unique()`, `Counter` / `BatchCounter` for preallocating ID ranges on disk, and `GrantTable` for club-scoped ID allocation. Xudanu uses simple sequential `u64` IDs with no batch preallocation or grants.

## PlaceHolder / FillDetector

Gold's `PlaceHolder` was a `RangeElement` representing a slot to be filled later. `FillDetector` fired when a PlaceHolder became a real element. This was the async mechanism for background transclusion resolution and template filling. Xudanu has `PlaceHolder` in the `RangeElement` enum but never creates them — no fill detection, no template slots.

## Edition Structural Operations

Gold had `Edition::combine(Edition)`, `Edition::replace(Edition)` for structural merge at the Edition level. `Edition::stepper(Region, OrderSpec)` for ordered iteration with custom sort. `Edition::isRangeIdentical()` / `makeRangeIdentical()` for explicit identity unification. `Edition::mapSharedOnto()` / `sharedWith()` / `notSharedWith()` for structural comparison. Xudanu has `with()`/`without()` for single-position ops, `three_way_diff()` for text comparison, but no structural Edition-level merge, ordered iteration, or identity unification.

## RangeElement Recursive Transclusion (`again()`)

Gold's `RangeElement::again()` returned the element this element is a transclusion of, supporting recursive transclusion chains. No equivalent in Xudanu.

## Persistent Agenda / Task Queue

Gold's `Agenda` / `AgendaItem` was a persistent task queue that survived crashes — `AgendaItem::step()` was called repeatedly until it returned false. `Sequencer` composed agenda items in order. Used for deferred operations like background transclusion resolution. Xudanu has no equivalent — all operations are synchronous.

## Disk Subsystem (SnarfPacker, Turtle, FlockManager)

Gold had a full disk abstraction: `SnarfPacker` mapping persistent objects (shepherds) to disk blocks (snarfs), `DiskManager` for flock lifecycle, `Turtle` as the root persistent object, `Purgeror`/`LiberalPurgeror` for LRU cache eviction. Xudanu uses a simpler content-addressed chunk store with BLAKE3 verification, which is a different (and better) approach for its use case, but lacks Gold's object-level persistence granularity.

## Comm Protocol (Portal, Recipe, Negotiator)

Gold's comm layer had `Portal` for bidirectional communication channels, `Recipe` for protocol message construction, `Negotiator` for protocol version negotiation, and `BootPlan` for connection setup. Xudanu uses a single WebSocket protocol with no version negotiation or multi-transport support.

## Link Type Sets and Named Ends

Gold's `HyperLink` had a `Set` of link types and named ends (`endNames()` returning a `SequenceRegion`). `MultiRef` supported multi-ended references with set operations (`intersect`, `minus`, `unionWith`). Links were endorsed wrappers. Xudanu's links have no type sets, no named ends, and no `MultiRef`.

## Overlays

Gold had overlays as compositional layers on editions. `RangeElement::Overlay` exists in Xudanu's enum but is not fully implemented — no overlay resolution or rendering pipeline.

## IDHolder (Inter-Document References in Content)

Gold's `IDHolder` was a `RangeElement` wrapping an ID, allowing editions to contain pointers to other objects (works, clubs) inline in their content. Xudanu has `WorkRef` and `EditionRef` variants but they are not first-class RangeElements usable anywhere in an Edition.

---

# Nelson's 17 Rules: Implementation Status

| # | Rule | Status |
|---|------|--------|
| 1 | Every document consists of arbitrarily many portions | Done — O-tree elements |
| 2 | Every portion can be transcluded | Partial — backend finds, no live rendering |
| 3 | Permission is required to transclude | Done — club-based ACLs |
| 4 | Permission is required to quote | Done — source import + attribution |
| 5 | Tumbler addressing | Partial — Id/IdSpace, no full tumbler paths |
| 6 | Bidirectional links | Done — HyperLink/HyperRef |
| 7 | Visible on both sides | Partial — backlinks exist, no always-visible UI |
| 8 | Identical content is stored once | Done — GrandMap + BLAKE3 |
| 9 | Royalty at any granularity | Partial — data structures exist, no payments |
| 10 | Mix of royalty-bearing and free content | Partial — endorsement types exist |
| 11 | Data is available from any server | Partial — federation transport, incomplete sync |
| 12 | Connection by any protocol | Partial — WebSocket only |
| 13 | Adaptive storage tiering | Not started |
| 14 | Redundant storage | Partial — local checkpoint + off-site backup script for chunks/manifests. Federation transport exists but content sync incomplete |
| 15 | Charge users at any rate | Not started |
| 16 | Handle any data type | Partial — 9 element types, no structured editing UI |
| 17 | Portable front-end | Partial — web SPA, no mobile |
