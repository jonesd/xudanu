# TODO

## v0.1.2 (near-term)

### Publish to crates.io

Publish the `xudanu` library and `xudanu-server` binary crate so users can install with:
```bash
cargo install xudanu-server --features server
```

Steps:
1. Add crates.io metadata to `Cargo.toml` (description, repository, license, readme, keywords, categories)
2. Create crates.io account and API token
3. Test with `cargo publish --dry-run`
4. Publish with `cargo publish`
5. Optionally set up CI auto-publish on tag push

Also publish a Docker image to GitHub Container Registry for users who prefer container deployment.

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

## v0.2 (medium-term)

### Club-based access control

Wire up the existing Club/KeyMaster infrastructure for production use:
- Admin bootstrap via CLI (set admin password at init)
- Enforce read_club/edit_club on all operations
- User account system with login
- Remove the `grant_admin_authority` backdoor

### Scalable storage backend

Replace the single `server.json` file with a proper storage engine:
- SQLite for structured queries and atomic writes
- Or append-only log with compaction
- Blob storage for large binary content (currently inline in JSON)
- Incremental checkpointing instead of full state serialization

### CI: ARM Linux and Windows builds

- ARM Linux musl: use `cross` tool or different approach for `aws-lc-sys` cross-compilation
- Windows: verify the PowerShell fix works for the packaging step
