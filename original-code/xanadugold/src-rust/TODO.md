# TODO

## Must-fix before initial GitHub release

### ~~Non-atomic checkpoint writes~~ ✅ Fixed

`write_versioned_snapshot()` in `src/server/transport/snapshot.rs:337` already writes
to a `.tmp` file then `std::fs::rename()` — the atomic write pattern.

### Auto-checkpoint blocks request processing

**Severity:** Medium  
**File:** `src/server/server.rs:902-912`

`auto_checkpoint` runs synchronously inside `bump_operation`, which is called from the
main request dispatch path. It serializes the entire server state to JSON and writes to
disk, blocking all other request processing for the duration. For a large state, this
could cause noticeable latency spikes every 50th operation.

**Fix:** Spawn the checkpoint write on a background thread using `std::thread::spawn`
or tokio task. Use a `Mutex` or `RwLock` to avoid writing during concurrent mutations.
Alternatively, snapshot the state (clone the serializable parts) and write asynchronously.

### Content notifications only delivered when client sends a message

**Severity:** Low  
**File:** `src/server/transport/handler.rs`

Content match notifications are drained after every incoming message (requests,
heartbeats, subscribes, unsubscribes). However, a completely idle client that sends
no messages at all will not receive notifications until it sends something.

**Fix:** Implement a server-push mechanism (e.g. periodic ping/flush, or a
notification channel per session) so notifications are delivered promptly even
for completely idle clients.

### No notification persistence on disconnect

**Severity:** Low
**File:** `src/server/transport/handler.rs`, `src/server/server.rs`

If a client disconnects, any pending content notifications in the server's queue are
silently lost. On reconnect, the client has no way to replay missed notifications and
may miss content matches that occurred while offline.

**Fix:** Buffer pending notifications per-session (keyed by fossil_id). On reconnect,
the client re-subscribes and the server replays any buffered notifications that haven't
been acknowledged. A TTL or max-buffer-size prevents unbounded growth. Alternatively,
store the last-seen revision per fossil in the subscription state and re-query on
reconnect to catch up.

### Stop words are English-only

**Severity:** Medium
**File:** `src/edition/edition.rs` (`is_stop_word`)

The content watch Jaccard similarity filter uses an English stop word list (NLTK 179
words). For non-English documents, common function words will not be filtered, reducing
match quality. The stop word list should be language-aware.

**Fix:** Detect document language (e.g. via a simple heuristic or configurable setting)
and select the appropriate stop word list. Consider using a compact multilingual stop
word library or embedding stop word lists for the top N languages.

## Roadmap: O-tree Merge Algorithm (Enfilade-Based Collaborative Editing)

**Priority:** Long-term
**Related:** `src/server/crdt_manager.rs`, `src/edition/orgl.rs`

The current CRDT system uses the external `yrs` crate (Yjs Rust port) which only
handles plain text. Collaborative edits are materialized into O-tree Editions via
`Edition::from_text()`, which loses all rich structure (transclusions, overlays,
labels, data elements, blob references, work references).

The ideal path forward is to build a merge algorithm **on top of the O-tree**
(enfilade) so collaborative edits preserve the full data model:

- **Transclusions survive collaborative editing** — work references within a
  document aren't flattened to text when another user edits concurrently
- **Overlays survive collaborative editing** — layered edits on blob/media
  content remain intact through merges
- **Attribution is per-element, not per-text-span** — each transclusion,
  overlay, or data element carries its own provenance, not just text ranges
- **No data loss at the materialization boundary** — the CRDT→Edition bridge
  currently discards everything except plain text; an O-tree merge would
  preserve the complete hypertext structure

This is what would make Xudanu genuinely different from Google Docs. The
current collaborative editor is functionally equivalent to Google Docs with
cryptographic attribution. Building the merge algorithm on enfilades would
make it a **collaborative editor that preserves hypertext structure**.

Not urgent — the current system works. But this is the direction that moves
Xudanu from reimplementing existing tools to building something new.

## Roadmap: O-tree Merge — Next Steps

### ~~Multi-user relay for O-tree CRDT~~ ✅ Done (Phase 5)

Multi-user relay is live. `dispatch()` now pushes `CrdtTextUpdate` events to
other subscribed sessions. `Share` button sets edit permissions via
`public_club_id`. Tested with 2 concurrent users.

### ~~LLM integration~~ ✅ Done (Phase 6)

Narration (snapshot-based diff), auto-title on work creation, GitHub Models
and Ollama backends. See `docs/llm-integration.md`.

Xudanu preserves the valuable Xanadu infrastructure, not the zigzag UI:

- **Content-addressed storage** (no linkrot)
- **Bidirectional links** (visible from both ends)
- **Signed attribution** (who wrote what)
- **Versioned editions** (full history)
- **Access controls** (publish/unpublish, read/edit clubs)

The Nelson rules worth following are the engineering principles (unique IDs,
access controls, bidirectional visibility, publication semantics), not the
business model rules (micropayments, royalty mechanisms).
