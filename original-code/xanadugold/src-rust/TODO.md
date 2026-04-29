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
