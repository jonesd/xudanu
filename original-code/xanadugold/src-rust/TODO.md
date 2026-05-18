# TODO

## Must-fix before initial GitHub release

### Non-atomic checkpoint writes

**Severity:** Medium  
**File:** `src/server/server.rs:1538-1543`

`checkpoint_to_file` does `std::fs::write(path, json.as_bytes())` directly. If the
process crashes or loses power during the write, the checkpoint file could be left
partially-written, making restoration impossible. This is amplified by auto-checkpoint
running every 50 operations.

**Fix:** Write to a temp file (e.g. `server.json.tmp`) then `std::fs::rename()` to the
final path. Rename is atomic on most filesystems (POSIX guarantee on same filesystem).

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
