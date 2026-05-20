# Xudanu Feature Roadmap

Prioritized features across three dimensions: **Xanadu Vision** (what Ted Nelson would expect), **Security/Hardening** (production readiness), and **Performance** (scalability).

---

## Priority Matrix

| # | Feature | Nelson Vision | User Benefit | Security | Effort | Tier |
|---|---------|:---:|:---:|:---:|:---:|:---:|
| 1 | Cryptographic Author Attribution | Critical | High | High | Medium | A |
| 2 | Verified User Names in Collaborative Editing | Medium | Very High | High | Low | A |
| 3 | Visible Backlinks (Always-On) | High | Very High | Low | Low | A |
| 4 | Annotations Protocol Surface | Medium-High | Very High | Low | Low | A |
| 5 | Link Context / Self-Explaining Links | Medium | High | Low | Low | A |
| 6 | Paginated List Operations | Low | Very High | Medium | Low | A |
| 7 | Server-Enforced Awareness Identity | Medium | High | High | Low | A |
| 8 | Three-Way Visual Comparison | Critical | Very High | Low | Medium | B |
| 9 | Live Transclusion Rendering | Critical | High | Low | Medium | B |
| 10 | Trails and Guided Paths | High | High | Low | Low-Med | B |
| 11 | Permanent Attribution on Every Fragment | High | High | Medium | Medium | B |
| 12 | Real-Time Notification Push | Low | High | Low | Medium | B |
| 13 | Inter-Span Links (Protocol) | High | High | Low | Medium | B |
| 14 | Non-Destructive Archive | High | Medium | Low | Low | B |
| 15 | Export / Interchange Format | Medium | High | Low | Medium | B |
| 16 | Compound Documents (Compositional Transclusion) | Critical | High | Low | High | C |
| 17 | Full-Text Search Across All Works | Medium | Very High | Low | Medium | C |
| 18 | RwLock or Sharded Concurrency | Low | High | Low | High | C |
| 19 | Unbounded Resource Limits (DoS Hardening) | Low | Medium | High | Low-Med | C |
| 20 | BackfollowEngine Duplicate Data Elimination | Low | Medium | Low | High | C |
| 21 | Async Checkpoint (Background Thread) | Low | High | Medium | Medium | C |
| 22 | Image Preview Generation | Low | Medium | Low | Low-Med | C |
| 23 | Federation Integration Tests | Low | Medium | High | Medium | C |

---

## Tier A: Immediate (Low Effort, High Impact)

### 1. Cryptographic Author Attribution

**Problem:** Content fingerprints identify *what* content is (BLAKE3 hash), but not *who* created it. There is no cryptographically strong binding between an authored span and the identity of its creator. The royalty ledger tracks `content_fingerprint` and `origin_server_id`, but has no author signature.

**Identity Model: Server-Managed Keys + Transparency Log**

The server generates and holds user Ed25519 keypairs (encrypted at rest with the user's password, decrypted on login). This is the current model — simple UX (password login), no client-side key management. To prevent undetectable forgery, we add an **append-only transparency log**:

- Every signature the server produces on behalf of a user is recorded in a hash-chained log
- Log entries: `{ sequence, timestamp, author_pubkey, content_hash, signature, prev_hash }`
- Chain integrity is verifiable by anyone (each entry's hash includes the previous)
- Users (or their tools) can audit: "did I actually sign everything attributed to me?"
- Forgery is **detectable and provable** after the fact, even though the server holds the keys
- Regular users see no change — transparency is infrastructure, not UI
- Builds on the existing `security.log` hash-chain pattern (`chain=<sha256(prev_hash + line)>`)
- Storage cost: ~200 bytes per signature, periodic compaction via signed checkpoints

This gets 90% of client-held-key integrity benefits with 0% of the UX complexity. Leaves the door open for optional client-held keys later.

**Design:**
- Extend `RangeElement` or its carrier with an optional `Provenance` field:
  ```
  Provenance {
      author_public_key: [u8; 32],  // Ed25519 verifying key of the author's club
      signature: [u8; 64],          // Ed25519 signature over (fingerprint + author_key)
      timestamp: u64,               // Unix epoch seconds at creation
      server_id: [u8; 32],          // Server verifying key that witnessed the creation
  }
  ```
- Signature covers `BLAKE3(content_fingerprint || author_public_key || timestamp || server_id)`
- Each provenance signature is appended to the transparency log
- The author's Ed25519 signing key already exists on personal clubs (encrypted at rest, decrypted on login). It is already used for CRDT signed updates. This extends the same key to edition-level attribution.
- Verification: any party can verify the signature with the public key. The public key maps to a club, which has a `display_name`. This gives **cryptographically attributable authorship** that survives transclusion, revision, and federation.
- The `Provenance` is set during `revise_work` when the session has a decrypted signing key. It is preserved through `edition_chunks` serialization.
- **Nelson alignment:** Rule 3 (every user uniquely and securely identified), Rule 16 (transactions secure and auditable only by the parties).

**Existing infrastructure:**
- `Club` has encrypted Ed25519 signing keys (`crypto/club_keys.rs`)
- `Session` holds decrypted signing key after login
- `AuthorIdentity` already has `public_key` field in CRDT manager
- `content_fingerprint()` already produces `[u8; 32]` BLAKE3 hashes
- `crypto/sign.rs` has Ed25519 sign/verify utilities
- `security.log` already uses hash-chained append-only pattern

**Scope:** Add `Provenance` struct, populate during revision, persist through chunk storage, expose via protocol queries, add transparency log for attribution signatures.

### 2. Verified User Names in Collaborative Editing

**Problem:** The `crdt_awareness_update` operation accepts an `AwarenessState` from the client that includes `user_name`. The client can claim any name — there is no server-side verification. Any connected user can impersonate any other user.

**Design:**
- The server should **ignore** the `user_name` field sent by the client in `crdt_awareness_update`.
- Instead, populate `user_name` from the session's authenticated identity:
  1. Look up the session's personal club (set during `login`)
  2. Use `club.display_name()` (falls back to `club.name()`)
  3. Override the `state.user_name` with this verified name
- The dispatch handler (`dispatch.rs:1266-1272`) already calls `ensure_logged_in(session_id)`. After that check, look up the session's personal club and override `user_name` before passing to `crdt_update_awareness`.
- This connects the collaborative editing UI to the same cryptographic identity used for authentication, CRDT signing, and (future) provenance.

**Existing infrastructure:**
- `Session` tracks `personal_club` after login
- `Club.display_name()` already exists with fallback to `name()`
- Frontend `AwarenessIndicators` component already renders `user_name`

**Scope:** ~10 lines in `dispatch.rs` to override `user_name` before passing to CRDT manager.

### 3. Visible Backlinks (Always-On)

**Problem:** The `BackfollowEngine` can find what documents share content with a given work, but there's no simple `BacklinksForWork` protocol operation that returns "everything that links to or transcludes this work." In the hypertext community, backlinks are table stakes — every wiki has them.

**Design:**
- Add `OperationCode::WorkBacklinks` (0x031E)
- `WireRequest::WorkBacklinks { work_id }`
- `ResponseValue::WorkBacklinksResult { links: Vec<BacklinkEntry> }`
- `BacklinkEntry { source_work_id: BeId, source_edition_id: Option<u64>, link_type: BacklinkType, shared_content_count: u64 }`
- `BacklinkType` enum: `Transclusion`, `Hyperlink`, `SharedRegion`
- Server method uses existing `BackfollowEngine::find_transcluders_for_work()` plus `find_links_referencing_edition()` (already implemented)
- Requires `ensure_can_read(session_id, work_id)` — same as other work read ops
- Only returns backlinks to works the requesting session can also read (permission filter)

**Existing infrastructure:**
- `BackfollowEngine` has all the query methods
- `find_links_from_work()`, `find_links_referencing_edition()` already exist
- `TransclusionIndex::find_by_work_id()` already exists

### 4. Annotations Protocol Surface

**Problem:** The Ent system (`src/ent/content.rs`) fully supports `CreateAnnotation`, `AttachAnnotationToNode`, `AttachAnnotationToSpan`, and `DeleteAnnotation`. But there are **no protocol operations** to create or query annotations through the wire protocol. Annotations are one of Nelson's key concepts — marginalia, highlights, comments attached to specific content.

**Design:**
- Add operations:
  - `AnnotationCreate { work_id, annotation_id, kind, payload }` (0x0C03)
  - `AnnotationAttachToNode { work_id, node_id, annotation_id }` (0x0C04)
  - `AnnotationAttachToSpan { work_id, span_id, annotation_id }` (0x0C05)
  - `AnnotationDelete { work_id, annotation_id }` (0x0C06)
  - `AnnotationGet { work_id, annotation_id }` (0x0C07)
  - `AnnotationsForNode { work_id, node_id }` (0x0C08)
  - `AnnotationsForSpan { work_id, span_id }` (0x0C09)
- These map directly to existing `AssertionPayload` variants
- Require edit permission on the work (annotations are mutations)
- Read operations require read permission

**Existing infrastructure:**
- All assertion types already exist in `src/ent/content.rs`
- `materialize_annotation_indexed()` already works
- Edition resolver already handles annotations in materialization

### 5. Link Context / Self-Explaining Links

**Problem:** `HyperRef` already carries `work_context`, `original_context`, and `path_context` fields. But `LinkCreate` and `LinkGet` don't expose these through the protocol. Nelson envisioned links that explain themselves — "this link exists because author A was responding to author B's argument."

**Design:**
- Extend `LinkCreate` protocol operation to accept optional `context: String` field
- Store it in `HyperRef.work_context` (already exists)
- Include it in `LinkGet` and `LinkListForWork` responses
- No new data structures needed — just wire through existing fields

**Existing infrastructure:**
- `HyperRef.work_context: Option<Edition>` already exists
- `HyperRef.original_context: Option<Edition>` already exists
- Just needs codec + dispatch wiring

### 6. Paginated List Operations

**Problem:** `WorkList`, `WorkListByOwner`, `ClubNames`, `LinkListForWork` return complete result sets. At production scale, these become OOM vectors and O(works × permission_checks) CPU hogs.

**Design:**
- Add optional `offset: Option<u64>` and `limit: Option<u64>` to each list request
- Default limit: 100 if not specified
- Max limit: 1000
- Return `total_count: u64` in response so clients know how many total results exist
- Permission filtering happens before slicing (correct semantics)
- `has_more: bool` in response for convenience

**Scope:** Modify 4 wire request types, 4 dispatch handlers, 4 response types.

### 7. Server-Enforced Awareness Identity

**Problem:** Related to #2 but broader. Currently `AwarenessState` includes `session_id` which is an opaque number. There's no way for other users to verify that session 42 is actually "Alice" without the server vouching for it. The awareness relay just passes through whatever the client claims.

**Design:**
- When relaying awareness to other sessions, the server should attach a signed identity assertion:
  ```
  AwarenessState (server-enriched) {
      session_id: u64,
      user_name: String,          // from verified club identity
      club_id: BeId,              // personal club ID
      author_public_key: [u8; 32], // Ed25519 verifying key
      cursor: Option<CursorPosition>,
      selection: Option<SelectionRange>,
      is_typing: bool,
  }
  ```
- The `author_public_key` lets clients verify CRDT edits against the awareness identity
- The `club_id` lets clients query the club for more info (avatar, bio, etc.)
- This creates a chain: authenticated session → club → display name + signing key → awareness + CRDT edits

---

## Tier B: Near-Term (Medium Effort, Core Xanadu Features)

### 8. Three-Way Visual Comparison

**Problem:** Nelson was obsessed with showing exactly what changed between versions and where content moved. The system has `content_shared_region()` and `content_map_shared_onto()` primitives, but no high-level "diff these two editions" operation.

**Design:**
- Add `EditionDiff { work_id_a, edition_id_a, work_id_b, edition_id_b }` (0x0403)
- Response: `EditionDiffResult { unchanged: Vec<SharedSpan>, added: Vec<Span>, removed: Vec<Span>, moved: Vec<MovedSpan> }`
- `SharedSpan { content_fingerprint_hex: String, position_a: i64, position_b: i64, length: usize }`
- `MovedSpan { content_fingerprint_hex: String, from_position: i64, to_position: i64 }`
- Implementation composes existing `content_shared_region()` + `content_map_shared_onto()`
- For three-way: accept three edition IDs, compute pairwise diffs, present merged view

**Existing infrastructure:**
- `shared_mapping.rs` has all the primitives
- `content_shared_region()`, `content_map_shared_to()`, `content_map_shared_onto()`
- Transclusion index already maps fingerprints to positions

### 9. Live Transclusion Rendering

**Problem:** The system can find transcluders and map shared content, but there's no way to render a document with transcluded fragments shown in-place with visible markers showing provenance.

**Design:**
- Add `RenderTransclusions { work_id, edition_id: Option<u64> }` (0x0404)
- Response: `RenderedTransclusions { elements: Vec<RenderedElement> }`
- `RenderedElement { position: i64, content: RangeElement, provenance: Option<Vec<SourceRef>> }`
- `SourceRef { work_id: BeId, edition_id: u64, author_club_id: Option<BeId>, author_public_key: Option<[u8; 32]> }`
- For each element in the edition, query the transclusion index for other works containing the same content
- This powers "see where this text came from" in the UI

**Existing infrastructure:**
- `TransclusionIndex` maps fingerprints to editions
- `ContentAddressIndex` maps fingerprints to works
- `BackfollowEngine` already has the full query stack

### 10. Trails and Guided Paths

**Problem:** Nelson and Vannevar Bush both envisioned trails — curated paths through multiple documents, like a guided reading sequence.

**Design:**
- A trail is an ordered list of stops: `Vec<TrailStop>`
- `TrailStop { work_id: BeId, edition_id: Option<u64>, span_start: Option<i64>, span_end: Option<i64>, annotation: Option<String> }`
- Modeled as a special `HyperLink` with ordered named ends ("stop_1", "stop_2", ...) plus metadata
- Add `TrailCreate { name, stops }` (0x0710), `TrailGet`, `TrailList`, `TrailFollow`
- `TrailFollow` returns the ordered list of stops with resolved edition content
- Trails are stored as works with a special flag (`is_trail: bool` on `WorkState`)
- Trails can be published, transcluded, and linked to — they're first-class documents

### 11. Permanent Attribution on Every Fragment (Cryptographic)

**Problem:** This extends #1 to be truly granular. Nelson's vision was that every quoted/transcluded fragment carries permanent, irrevocable attribution that survives all transformations. The current `content_fingerprint` identifies content but not authorship.

**Design:**
- When `Provenance` (from #1) is attached to spans, the transclusion index also indexes the provenance
- When content is found via `FindTranscluders`, the response includes the original author's public key
- A new `AttributionQuery { content_fingerprint_hex }` operation returns:
  ```
  AttributionResult {
      original_author_club_id: Option<BeId>,
      original_author_public_key: Option<[u8; 32]>,
      signature_valid: bool,
      first_seen_work: BeId,
      first_seen_edition: u64,
      first_seen_timestamp: u64,
      server_id: [u8; 32],
  }
  ```
- The `first_seen_*` fields are derived from the earliest edition in the transclusion index containing this fingerprint
- Signature verification uses the stored `Provenance.signature` and `Provenance.author_public_key`
- This makes attribution **cryptographically verifiable** — not just "the server says Alice wrote this" but "Alice's Ed25519 key signed this content at this time, and here's the proof"

### 12. Real-Time Notification Push

**Problem:** Content watch notifications are only delivered when the client sends a message. Idle clients never learn about changes. The TODO.md already documents this.

**Design:**
- Use the existing WebSocket connection to push events immediately
- The `handler.rs` event loop already receives events from the `ChannelDetector`
- Currently it buffers them and delivers on next client message
- Change: deliver buffered events immediately via `tokio::spawn` to the WebSocket sender
- Add a small event queue per session (cap at 100 events, drop oldest on overflow)
- This also fixes the `content_match` delivery for content watch

### 13. Inter-Span Links (Protocol)

**Problem:** `HyperLink` supports multi-ended links with excerpts, but the protocol operations only work at work-level granularity. There's no way to create a link targeting `(work, edition, start_position, end_position)`.

**Design:**
- Extend `LinkCreate` to accept `Vec<LinkEnd>` instead of just work IDs
- `LinkEnd { work_id: BeId, edition_id: Option<u64>, start_position: Option<i64>, end_position: Option<i64>, label: Option<String> }`
- The `HyperRef::Single` already has `excerpt: Option<Edition>` — populate from the specified range
- `LinkGet` returns resolved span ranges, not just work IDs
- Enables "this sentence responds to that paragraph" granularity

### 14. Non-Destructive Archive

**Problem:** `WorkIrrevocablyUnpublish` is destructive. Nelson was fanatical: nothing should ever be truly deleted, only hidden.

**Design:**
- Add `WorkArchive` operation: sets `is_archived: bool` on `WorkState`
- Archived works are hidden from `WorkList` and `WorkListByOwner` by default
- Add `include_archived: bool` parameter to list operations (admin only)
- Archived works remain discoverable via transclusion queries (content persists)
- Add `WorkUnarchive` to restore visibility
- `is_archived` is a soft delete — all data, revisions, and links are preserved

### 15. Export / Interchange Format

**Problem:** No way to export a work or a web of works to a portable format. Nelson wanted documents universally portable.

**Design:**
- Add `WorkExport { work_id, include_history: bool, include_links: bool, resolve_transclusions: bool }`
- Response: `WorkExportResult { format: String, data: Vec<u8> }`
- Formats: JSON (self-contained, with all editions, links, and provenance), HTML (rendered with transclusion markers)
- `resolve_transclusions: true` replaces transcluded spans with inline content + source markers
- Import counterpart: `WorkImport` accepts the same JSON format

---

## Tier C: Medium-Term (Larger Efforts)

### 16. Compound Documents (Compositional Transclusion)

**Problem:** Currently a work contains one edition at a time. Nelson's vision was documents assembled from pieces of other documents — not copies, but live references. This is the hardest Xanadu feature and the one that would make this system genuinely novel.

**Design:**
- A `CompoundEdition` contains `Vec<CompoundSpan>` instead of regular elements
- `CompoundSpan { source_work: BeId, source_edition: Option<u64>, source_range: (i64, i64), live: bool }`
- When `live: true`, the compound document resolves the source at render time (sees updates)
- When `live: false`, it's a snapshot of the source at the time of composition
- Resolution uses the existing transclusion infrastructure
- Requires lazy resolution engine and caching layer
- This is the feature that distinguishes Xanadu from all other document systems

### 17. Full-Text Search Across All Works

**Problem:** `find_text_transcluders` does transclusion-oriented search (finding shared content). There's no general "search all works for this text" operation.

**Design:**
- Build an inverted index on top of the existing `ContentAddressIndex`
- Index each edition's text elements by word (truncated fingerprints as tokens)
- Support prefix search and phrase search
- Permission-filtered: only returns results from works the session can read
- Add `SearchWorks { query, limit, offset }` operation
- Consider BM25 ranking for relevance ordering

### 18. RwLock or Sharded Concurrency

**Problem:** The entire server is behind a single `Arc<Mutex<Server>>`. Every request acquires this mutex. Only one request can be processed at a time. This is the most critical performance bottleneck.

**Design options:**
- **Option A (RwLock):** Replace `Mutex` with `RwLock`. Read operations (get edition, search, list) take read locks. Write operations take write locks. Requires auditing every `&mut self` method.
- **Option B (Sharded):** Shard works across N `Mutex<WorkShard>` instances. Club/session/global state behind a separate lock. Reduces contention by factor of N.
- **Option C (Actor model):** Each work gets its own tokio task with a message channel. Global state in a separate actor. Maximum concurrency but requires significant refactoring.
- Recommendation: Start with Option A (RwLock), measure, then consider B if contention persists.

### 19. Unbounded Resource Limits (DoS Hardening)

**Problem:** Several data structures have no size limits, enabling resource exhaustion attacks:
- `standalone_editions: HashMap<BeId, Edition>` — unbounded
- `links: HashMap<BeId, LinkState>` — unbounded
- `grab_waiters: Vec<GrabWaiter>` per work — unbounded
- Content address index grows to 1M entries before capping (configurable but not enforced gracefully)
- Login attempt map grows with unique targeted club IDs

**Design:**
- Add configurable limits to each unbounded structure
- `max_standalone_editions` (default: 10,000)
- `max_links_per_work` (default: 1,000)
- `max_grab_waiters` (default: 50)
- Return `ResourceExhausted` error when limits are hit
- Already have `max_works = 100,000` and `max_blob_count = 10,000` as precedent

### 20. BackfollowEngine Duplicate Data Elimination

**Problem:** `BackfollowEngine` maintains a DUPLICATE of all work, edition, and link data (`work_storage`, `edition_storage`, `link_storage`) in addition to what `Server` holds. This roughly doubles memory usage.

**Design:**
- Replace the duplicate storage with references/IDs
- `BackfollowEngine` should hold only the transclusion index and canopy structures
- On query, resolve through the `Server`'s data via a trait or callback
- Requires refactoring the engine to accept a `dyn EditionResolver` instead of owning copies

### 21. Async Checkpoint (Background Thread)

**Problem:** Auto-checkpoint runs synchronously inside `bump_operation`, serializing the entire server state to JSON and writing to disk while holding the mutex. This blocks all request processing every 10 operations.

**Design:**
- Clone the serializable state (or snapshot it)
- Spawn a `std::thread::spawn` or `tokio::spawn_blocking` to write to disk
- The main server continues processing requests
- Use `RwLock` or a snapshot mechanism to avoid writing during concurrent mutations
- The dirty-only checkpoint system already reduces the serialization cost; async writing eliminates the I/O latency

### 22. Image Preview Generation

**Problem:** `generate_image_preview()` in `blob_store.rs` returns `None` unconditionally. The blob pipeline works but there are no thumbnails.

**Design:**
- Use the `image` crate for server-side thumbnail generation
- Generate previews on blob upload, store alongside the blob
- Default preview size: 256x256 (configurable)
- Support JPEG and PNG input formats
- Fallback: return `None` for unsupported formats (no error)

### 23. Federation Integration Tests

**Problem:** 100+ unit tests exist for federation CRDTs, reconciliation, governance, and membership. But there are zero integration tests that spin up multiple servers and test cross-server operations end-to-end.

**Design:**
- Create a test harness that starts 2-3 `xudanu-server` instances on different ports
- Test scenarios:
  - Federated transclusion query (server A finds content on server B)
  - Content replication (server A fetches content from server B)
  - Membership join with endorsement (server C joins A+B federation)
  - Governance consensus (PBFT commit across 3 servers)
  - CRDT federation sync (concurrent edits on different servers converge)
  - Royalty recording via governance
- Use the existing `integration.rs` test infrastructure as a template

---

## Appendix: Nelson's 17 Rules Compliance

Current compliance (from `docs/xanadu-17-rules.md`):

| Rule | Status | Roadmap Item |
|------|--------|-------------|
| 1. Unique server ID | **Done** | — |
| 2. Independent or networked | Partial | #23 |
| 3. Unique user ID | Partial | **#1, #2, #7** |
| 4. Search/retrieve/create/store | **Done** | — |
| 5. Any data type parts | Partial | #22 |
| 6. Links + transclusions | **Done** | — |
| 7. Visible bidirectional links | **Done** | #3 |
| 8. Publication = permission to link | **Done** | — |
| 9. Royalty at any granularity | No | #11 |
| 10. Unique document ID | **Done** | — |
| 11. Secure access controls | Partial | #19 |
| 12. Transparent storage | **Done** | — |
| 13. Adaptive storage tiering | No | Future |
| 14. Redundant storage | Partial | #21 |
| 15. Charge at any rate | No | Future |
| 16. Secure auditable transactions | Partial | **#1, #11** |
| 17. Open protocol | **Done** | — |

---

## Appendix: Security Review Findings

Issues identified during code review that should be tracked:

| Issue | Severity | Status | Notes |
|-------|----------|--------|-------|
| Arithmetic overflow in revision range | Medium | **Fixed** | Checked arithmetic + MAX_RANGE=100 |
| No range size limit (DoS) | Medium | **Fixed** | MAX_RANGE=100 cap |
| `toggleWatch` stale closure | Low | **Fixed** | Ref-based state |
| Client-set `user_name` in awareness | Medium | Open | **#2** |
| Unbounded edition storage | Medium | Open | **#19** |
| Unbounded link storage | Medium | Open | **#19** |
| Unbounded grab waiter queue | Medium | Open | **#19** |
| `contentMatches` unbounded growth | Low | **Fixed** | MAX_CONTENT_MATCHES=200 |
| Single global mutex | Critical | Open | **#18** |
| No pagination on list ops | High | Open | **#6** |
| Auto-checkpoint blocks dispatch | Medium | Open | **#21** |
| Non-atomic checkpoint writes | Medium | **Fixed** | tmp+rename (prior work) |
| Duplicate BackfollowEngine data | Medium | Open | **#20** |
