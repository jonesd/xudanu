# Cryptographic Attribution + Transparency Log — Implementation Plan

**Status:** Planning
**Scope:** Single server and federation scenarios
**Approach:** Per-span provenance, ~15% storage overhead

---

## 1. Design Overview

### What We're Building

Every time content is written to a work (via grab/release or CRDT), the server:
1. Identifies contiguous spans of text, each authored by one user
2. Signs each span with the author's Ed25519 club signing key
3. Records the signature in a hash-chained transparency log
4. Attaches provenance metadata to the edition

Any party can later verify:
- **Who** authored a specific span (public key → club → display name)
- **When** it was authored (timestamp)
- **Which server** witnessed it (server verifying key)
- **That the log is intact** (hash chain verification)

### Why Per-Span, Not Per-Character

The O-tree edition model stores one element per character. A 500-character paragraph = 500 elements. Putting a 136-byte `Provenance` on each would multiply edition storage by 14x.

Instead, we group consecutive elements by author into **spans** and store provenance once per span. A typical collaborative revision has 5-10 spans (not 500), keeping overhead to ~15%.

### Trust Model

**Single server:** Server holds user keys, signs on their behalf, records in transparency log. Forgery is detectable (log proves server misattributed).

**Federation:** Server A wraps user-level provenance in a federation frame signed with its server key. Server B verifies both layers. Federation governance (PBFT) can expel a server caught forging.

---

## 2. Data Model

### 2.1 New Struct: `Provenance`

**File:** `src/edition/provenance.rs` (new)

```
Provenance {
    author_public_key: [u8; 32],   // Ed25519 verifying key of the author's club
    signature: [u8; 64],           // Ed25519 signature over the span
    timestamp: u64,                // Unix epoch seconds at creation
    server_id: [u8; 32],           // Server verifying key that witnessed creation
}
```

Signature domain: `b"xudanu/v1/provenance"` as AAD, payload is:
```
BLAKE3(span_content_fingerprints || author_public_key || timestamp || server_id)
```

Where `span_content_fingerprints` is the concatenation of each element's `content_fingerprint()` within the span. This binds the signature to both the content and the identity.

### 2.2 New Struct: `SpanProvenance`

**File:** `src/edition/provenance.rs` (same file)

```
SpanProvenance {
    start: i64,                    // Inclusive start position
    end: i64,                      // Exclusive end position
    provenance: Provenance,
}
```

A sorted list of these lives on the edition.

### 2.3 Modification: `EditionSnapshot`

**File:** `src/edition/persistent.rs`

The serialization format. Currently:
```
EditionSnapshot {
    entries: Vec<(i64, RangeElement)>,
    default: Option<RangeElement>,
    domain_start: Option<i64>,
    domain_infinite_above: bool,
}
```

Becomes:
```
EditionSnapshot {
    entries: Vec<(i64, RangeElement)>,
    default: Option<RangeElement>,
    domain_start: Option<i64>,
    domain_infinite_above: bool,
    #[serde(default)]
    span_provenance: Vec<SpanProvenance>,
}
```

`#[serde(default)]` ensures backward compatibility — old chunks without provenance deserialize as empty vec.

### 2.4 Modification: `Edition`

**File:** `src/edition/edition.rs`

Add a field:
```
pub(crate) span_provenance: Vec<SpanProvenance>,
```

Not serialized directly — flows through `EditionSnapshot` for chunk storage. In-memory, the `Edition` carries it so queries like `AttributionQuery` can access it without re-reading chunks.

### 2.5 No Change to `Carrier` or `RangeElement`

The `Carrier` and `RangeElement` structs are unchanged. Provenance lives at the edition level, not per-element. This avoids the 14x storage blowup.

---

## 3. Storage Budget

### Per-Span Overhead

| Component | Size |
|-----------|------|
| `Provenance` struct (in edition) | 136 bytes |
| Transparency log entry (JSON) | ~200 bytes |
| `SpanProvenance` header (start + end) | 16 bytes |
| **Total per span** | **~350 bytes** |

### Per-Edition Overhead

| Scenario | Spans | Provenance Size | Edition Size (500 chars) | Overhead |
|----------|-------|-----------------|--------------------------|----------|
| Solo author | 1 | 152 bytes | ~5 KB | ~3% |
| 2 authors, light collab | 5 | 760 bytes | ~5 KB | ~15% |
| 5 authors, heavy collab | 20 | 3 KB | ~5 KB | ~60% |

### Scaling Projections

| Server Size | Users | Revisions/day | Spans/day | Edition overhead/day | Log growth/day |
|-------------|-------|---------------|-----------|---------------------|----------------|
| Small | 10 | 200 | 600 | 90 KB | 120 KB |
| Medium | 100 | 3,000 | 15,000 | 2.3 MB | 3 MB |
| Large | 1,000 | 30,000 | 150,000 | 23 MB | 30 MB |

**Yearly (medium server):** ~850 MB edition overhead + ~1.1 GB log = **~2 GB/year**. Negligible.

### GC Impact

`collect_edition_hashes()` currently collects root + entry chunk hashes. Provenance is stored inline in the entry chunks (part of `EditionSnapshot`), so no new chunks to track. GC does not need changes.

---

## 4. Implementation Phases

### Phase 1: Data Model (no behavioral change)

**Files:** `src/edition/provenance.rs` (new), `src/edition/persistent.rs`, `src/edition/edition.rs`

1. Create `Provenance` and `SpanProvenance` structs with serde derives
2. Add `span_provenance: Vec<SpanProvenance>` to `EditionSnapshot` with `#[serde(default)]`
3. Add `span_provenance: Vec<SpanProvenance>` to `Edition` (in-memory)
4. Update `EditionSnapshot::from_edition()` to extract span_provenance from Edition
5. Update `EditionSnapshot::to_edition()` to populate Edition's span_provenance
6. Update `Edition::new_inner()` to accept span_provenance (default empty vec for backward compat)
7. Unit tests: round-trip serialization with and without provenance

**Test:** Existing 1832 tests must still pass (backward compat). New tests verify provenance survives snapshot round-trip.

### Phase 2: Verified User Names (standalone, no dependency on Phase 1)

**File:** `src/server/transport/dispatch.rs`

In the `CrdtAwarenessUpdate` handler (line 1266):
1. After `ensure_logged_in(session_id)`, look up session's personal club
2. Override `state.user_name` with `club.display_name().unwrap_or("anonymous")`
3. Pass the modified state to `crdt_update_awareness`

**Test:** Integration test — two users with different display names edit the same work, verify each sees the other's verified name in awareness state.

### Phase 3: Span Extraction and Signing

**Files:** `src/server/server.rs`, `src/server/crdt_manager.rs`

#### 3a: Non-CRDT path (`work_revise`)

In `revise_work()` (line 535), after constructing the edition:
1. Get the session's club signing key and verifying key
2. Call `build_span_provenance(edition, signing_key, verifying_key_bytes, server_id, timestamp)`
3. Set `edition.span_provenance` before storing

`build_span_provenance()`:
- Walk all entries in the edition
- Since this is a single-author revision, all elements belong to one author
- Create one `SpanProvenance` covering the entire edition
- Compute span fingerprint: BLAKE3 of concatenated element fingerprints
- Sign with Ed25519
- Return `Vec<SpanProvenance>`

**Scope:** ~50 lines in server.rs + ~40 lines in provenance.rs for the signing helper.

#### 3b: CRDT path (`materialize_edition`)

Currently `materialize_edition()` calls `text_to_edition(text)` which calls `Edition::from_text(text)` — it throws away the `__author` attributes.

Modify `materialize_edition()`:
1. Walk the CRDT text with `yrs::TextRef::diff()` or iterate chunks to get per-character `__author` attributes
2. Group consecutive characters by author into spans
3. For each span, look up the author's signing key from `wd.author_keys`
4. Build `SpanProvenance` for each span
5. Set `edition.span_provenance` before returning

This is the most complex part — yrs's API for per-character attributes needs investigation. The `__author` attribute is stored as `Any::String` on each item in the yrs TextRef. We need to iterate the text items (not just get the string) to extract attributes.

**Scope:** ~100 lines in crdt_manager.rs. Requires understanding yrs's `TextRef::diff()` or chunk iteration API.

#### 3c: Graceful degradation

- If a session has no signing key (public login, no personal club), produce no provenance
- If CRDT characters lack `__author` attributes, treat as anonymous (no provenance for that span)
- Old editions with empty `span_provenance` work fine — queries return "no attribution available"

### Phase 4: Transparency Log

**Files:** `src/server/transport/attribution_log.rs` (new), `src/server/server.rs`

1. Create `AttributionLog` wrapping the existing `ChainedLogWriter` pattern from `chained_log.rs`
2. Log file: `data/attribution.log` (daily-rotating, same as security.log)
3. Seed: `data/attribution.log.seed`
4. Each entry (one line): `{seq, timestamp, author_pk_hex, span_fp_hex, signature_hex, server_id_hex, work_id, revision}`
5. Call from `revise_work()` after provenance is set — one log entry per span
6. CLI command: `xudanu-server verify-attribution-log <data-dir>`

**Implementation:** Reuse `ChainedLogWriter<W>` directly. The attribution log writer is a thin wrapper that formats entries as JSON lines and feeds them to `ChainedLogWriter`.

**Scope:** ~80 lines for attribution_log.rs, ~10 lines in server.rs to call it.

### Phase 5: Protocol Queries

**Files:** `src/server/transport/protocol.rs`, `src/server/transport/codec.rs`, `src/server/transport/dispatch.rs`, `src/server/server.rs`

#### Operation 1: `AttributionQuery` (0x0D01)

Given a work and optional position range, return provenance for matching spans.

Request: `{ work_id: BeId, start: Option<i64>, end: Option<i64> }`
Response: `{ spans: Vec<AttributionSpan> }`

```
AttributionSpan {
    start: i64,
    end: i64,
    author_public_key: [u8; 32],
    author_display_name: Option<String>,
    author_club_id: Option<BeId>,
    signature_valid: bool,
    timestamp: u64,
    server_id: [u8; 32],
}
```

Server method: look up the work's current edition, find spans overlapping the requested range, verify each signature, look up author club for display name.

#### Operation 2: `AttributionVerify` (0x0D02)

Pure cryptographic verification of a provided Provenance against a content fingerprint.

Request: `{ provenance: Provenance, content_fingerprint_hex: String }`
Response: `{ valid: bool }`

No DB lookup needed — just Ed25519 signature verification.

#### Operation 3: `AttributionLogStatus` (0x0D03)

Return summary info about the transparency log.

Request: `{}` (no params)
Response: `{ entry_count: u64, log_file_count: u32, chain_valid: bool, last_sequence: u64 }`

Runs `ChainedLogWriter::verify_log()` on the current log file to check chain integrity.

**Scope:** ~200 lines total across the 4 files.

### Phase 6: Persistence Compatibility

**Files:** `src/persist/edition_chunks.rs`

1. `EntryChunk` is unchanged — it stores `(i64, RangeElement)`, no provenance
2. `EditionRootChunk` gains an optional `span_provenance_chunk_hash: Option<[u8; 32]>` pointing to a provenance chunk (if any spans exist)
3. If `span_provenance` is non-empty, serialize to a separate chunk and store the hash in the root
4. If `span_provenance` is empty, the field is `None` — old format, zero overhead
5. On read: if `span_provenance_chunk_hash` is missing (old chunks), `span_provenance` defaults to empty vec

**Why a separate chunk?** Provenance can be large for heavily collaborative editions. Keeping it separate means editions without provenance (the majority, initially) have zero overhead. And the entry chunks (the bulk of storage) are completely unchanged.

**GC:** `collect_edition_hashes()` needs to also collect the provenance chunk hash when present.

**Scope:** ~30 lines in edition_chunks.rs.

### Phase 7: Federation Propagation

**Files:** `src/server/federation.rs`, `src/server/transport/federation_handler.rs`, `src/server/server.rs`

#### 7a: Content sync

Extend `SyncWorkEntry`:
```
SyncWorkEntry {
    origin_server_id: String,
    work_id: u64,
    edition_payload: EditionPayload,
    span_provenance: Vec<SpanProvenance>,  // NEW
}
```

When Server A pushes content to Server B:
- Include the edition's `span_provenance` directly in the sync entry
- The federation frame is already signed with Server A's server key
- Server B receives: server signature (trust Server A) + span provenance (Server A claims Alice wrote this)

#### 7b: CRDT federation sync

Extend `CrdtWorkUpdate`:
```
CrdtWorkUpdate {
    work_id: BeId,
    update_bytes: Vec<u8>,
    span_provenance: Vec<SpanProvenance>,  // NEW — from last materialization
}
```

When applying a federated CRDT update on Server B:
1. Verify the `SignedUpdate` signature (server-level trust)
2. Store the `span_provenance` alongside the materialized edition
3. Do NOT re-sign with Server B's keys — preserve the original attribution

#### 7c: Cross-server attribution queries

When Server B receives an `AttributionQuery` for content that originated on Server A:
- The edition already carries `span_provenance` (received via sync)
- The `author_public_key` maps to Server A's user, not Server B's
- Display name resolution: Server B can query Server A via `FederatedTransclusionQuery` extended with `include_attribution: bool`
- Or: Server B stores a cache of `{public_key -> (display_name, server_id)}` from sync entries

#### 7d: Governance integration

No changes to governance. `RoyaltyRecord` already tracks `origin_server_id` and `content_fingerprint_hex`. The span provenance enriches the royalty data with specific author identity, but the governance transaction format is unchanged.

**Scope:** ~100 lines in federation.rs, ~50 lines in federation_handler.rs.

---

## 5. Execution Order

```
Phase 1: Data model ─────────────────────────┐
                                              │
Phase 2: Verified user names ──── independent ─┤
                                              │
Phase 3a: Non-CRDT signing ──── depends P1 ───┤
Phase 3b: CRDT signing ──────── depends P1 ───┤
                                              │
Phase 4: Transparency log ───── depends P3 ───┤
                                              │
Phase 5: Protocol queries ───── depends P3,P4 ┤
Phase 6: Persistence ────────── depends P1 ───┤
                                              │
Phase 7: Federation ─────────── depends P5,P6 ─┘
```

**Phases 1 and 2 can be done in parallel.** Phase 2 is ~10 lines and immediately useful.

Recommended start: **Phase 2** (verified user names, standalone), then **Phase 1** (data model), then **Phase 3a** (non-CRDT signing — simpler), then **Phase 3b** (CRDT signing — needs yrs API research), then Phase 4-7 in order.

---

## 6. Test Plan

### Phase 1 Tests
- `Provenance` sign/verify roundtrip
- `SpanProvenance` serialization roundtrip
- `EditionSnapshot` roundtrip with provenance
- `EditionSnapshot` roundtrip without provenance (backward compat)
- Old chunk deserialization (empty span_provenance vec)

### Phase 2 Tests
- Integration test: user A and user B edit same work, verify awareness shows correct names
- Integration test: user tries to spoof name in awareness update, server overrides it
- Integration test: public user (no personal club) gets "anonymous" name

### Phase 3a Tests
- Unit test: `build_span_provenance()` produces valid signatures
- Unit test: signature verification succeeds for correct content
- Unit test: signature verification fails for modified content
- Integration test: `work_revise` → `AttributionQuery` → valid provenance
- Integration test: revise without signing key → no provenance (graceful degradation)

### Phase 3b Tests
- Unit test: CRDT with 2 authors produces 2 spans
- Unit test: CRDT with author edit within another's span produces correct fragments
- Integration test: 2 users edit collaboratively → materialize → verify multi-author spans

### Phase 4 Tests
- Unit test: attribution log append + verify chain
- Unit test: detect tampering in attribution log
- Integration test: revise work → check attribution log has entry → verify chain

### Phase 5 Tests
- Integration test: `AttributionQuery` returns correct spans for a work
- Integration test: `AttributionQuery` for position range returns only matching spans
- Integration test: `AttributionVerify` succeeds for valid provenance
- Integration test: `AttributionVerify` fails for tampered content
- Integration test: `AttributionLogStatus` returns correct counts

### Phase 6 Tests
- Unit test: edition with provenance → chunks → read back → provenance preserved
- Unit test: edition without provenance → chunks → read back → empty vec
- Integration test: checkpoint + restore preserves provenance

### Phase 7 Tests (federation integration, Tier C)
- Sync work entry carries provenance across servers
- CRDT sync carries provenance across servers
- Cross-server attribution query resolves author identity
- Tampered provenance from remote server is detected

---

## 7. Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| yrs API doesn't expose per-character attributes easily | Medium | Fallback to per-revision signing for CRDT path; per-span for non-CRDT path still works |
| Transparency log grows faster than expected | Low | Daily rotation already limits file size. Compaction is straightforward to add later. |
| Provenance serialization breaks old clients | Low | `#[serde(default)]` on span_provenance ensures old data loads fine. New data with empty provenance is also fine. |
| Signing overhead slows revision path | Low | 5-10 spans × 50μs per Ed25519 signature = ~0.5ms. Negligible vs disk I/O for checkpoint. |
| Federation sync grows with provenance data | Low | 5-10 spans × 152 bytes = ~1.5 KB per work. Trivial vs edition content itself. |

---

## 8. Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Signing granularity | Per-span | 15% overhead vs 14x for per-element, captures collaborative attribution |
| Provenance location | Edition-level (`Vec<SpanProvenance>`) | Avoids per-Carrier duplication, matches serialization model |
| Identity model | Server-managed keys + transparency log | Simple UX, forgery detectable, aligns with Rule 16 |
| Storage format | Separate provenance chunk in edition_chunks | Zero overhead for editions without provenance |
| Log format | Hash-chained JSON lines (reuse ChainedLogWriter) | Proven pattern, daily rotation, CLI verification |
| Federation trust | Server vouches for user, auditable via log | Matches PKI transparency model, governance can expel bad actors |
