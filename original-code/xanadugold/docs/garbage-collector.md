# Garbage Collector Algorithm

## Overview

The GC (`gc_orphaned_chunks`) runs after every checkpoint (every 30 seconds).
It identifies and deletes chunks on disk that are no longer referenced by any
live data structure.

## When It Runs

```
checkpoint_to_store()
  ├── write manifest to disk (dual-slot, atomic)
  ├── save key history
  ├── gc_orphaned_chunks()     ← runs here
  └── wal.truncate()           ← WAL cleared after checkpoint
```

GC runs every ~30 seconds via `auto_checkpoint()`. It also runs on explicit
`checkpoint_to_store()` calls.

## Algorithm

### Step 1: Build the `referenced` set

Collect every chunk hash that is still needed:

**A. In-memory works** — For each work in `self.works`, walk its edition's
chunk reference tree (`collect_work_hashes`) and add all reachable chunk hashes.

**B. Manifest hash fields** — Read `manifest.json` from disk and add these
chunk hashes:
- `historical_authors_hash`
- `blob_metas_hash`
- `content_address_hash`
- `links_hash`
- `annotations_hash`
- `fossil_snapshots_hash`

> **Safety fix (v0.7.5):** If the manifest cannot be read, GC returns `Ok(0)`
> immediately. It does NOT proceed without manifest protection. Previously,
> the GC would silently skip adding these hashes, causing it to delete valid
> chunks (including link data).

**C. In-memory clubs** — For each club, collect hashes from the club's work
reference tree.

**D. In-memory standalone editions** — For each standalone edition, collect
hashes from the edition reference tree.

**E. Backup manifests** — Scan for `manifest_v*.json` files in the data
directory. For each backup manifest, collect hashes from:
- Work entries
- Club entries
- Standalone edition entries

This protects chunks that older manifest versions reference, in case of
rollback to a previous checkpoint.

### Step 2: List all chunks on disk

```
all_chunks = chunk_store.all_chunk_hashes()
```

### Step 3: Delete unreferenced chunks

For each chunk hash in `all_chunks` that is NOT in `referenced`:

```
chunk_store.delete_chunk(hash)
```

### Step 4: Log results

```
Chunk GC: removed N orphaned chunks (M referenced, T total on disk)
```

## Chunk Store Write Path (Why Corruption Is Rare)

Chunks use the gold-standard durable write pattern:

1. Write data to `hash.tmp` (temp file)
2. `f.sync_all()` — fsync the data to disk
3. `fs::rename(tmp, final)` — atomic rename
4. `dir_file.sync_all()` — fsync the directory entry

A crash at any point leaves either the old state or the new state.
Partial writes are impossible because the atomic rename is the commit point.

## Checkpoint Write Path

1. Build manifest in memory (all state serialized)
2. Write to dual-slot file (`manifest_b.json`)
3. Rotate backups (`manifest.json.1` → `.2` → `.3`)
4. Atomic rename `manifest_b.json` → `manifest.json`
5. Write versioned backup (`manifest_v{seq}.json`) with fsync
6. Save key history
7. **Run GC** (see above)
8. Truncate WAL

## The Bug We Fixed (v0.7.5)

**Before:** When the GC couldn't read the manifest, it silently skipped
adding manifest hash fields to the `referenced` set. The GC then saw the
links chunk, annotations chunk, etc. as "orphaned" and deleted them.

**After:** If manifest read fails, GC returns `Ok(0)` — it does not run.
Stale chunks may accumulate temporarily, but valid data is never deleted.

```
// BEFORE (buggy):
let manifest = read_manifest(path);
if let Ok(m) = manifest {
    // add hashes to referenced...
}
// GC proceeds even if manifest read failed!

// AFTER (safe):
let manifest = read_manifest(path);
match manifest {
    Ok(m) => m,
    Err(e) => {
        warn!("GC: skipping to avoid deleting valid chunks");
        return Ok(0);  // GC does not run
    }
}
```

## Inline Links Fallback (v0.7.5)

As additional protection, the manifest now stores links inline
(`links: Vec<LinkEntry>`) alongside the `links_hash` chunk reference:

- **Primary path:** Restore reads the chunk via `links_hash`
- **Fallback path:** If the chunk is missing or corrupt, restore falls back
  to `manifest.links` (inline data)

This means even if the GC somehow deletes the links chunk, the link data
survives in the manifest JSON itself.

## WAL Journaling (v0.7.5)

Links are now written to the WAL on creation, providing crash recovery within
the 30-second checkpoint window:

1. `create_link()` → `wal.append_create_link(...)`
2. Server crashes before checkpoint
3. On restart: WAL replay reconstructs the link
4. After checkpoint: WAL is truncated, manifest has the link inline + in chunk

## File Locations

| Component | File | Key Function |
|---|---|---|
| GC | `src/server/server.rs:10193` | `gc_orphaned_chunks()` |
| Checkpoint | `src/server/server.rs:9731` | `checkpoint_to_store()` |
| Auto-checkpoint | `src/server/server.rs:5157` | `auto_checkpoint()` |
| Chunk store | `src/persist/chunk_store.rs:265` | `write_chunk_durable()` |
| Manifest | `src/persist/manifest.rs` | `read_manifest()`, `write_manifest()` |
| WAL | `src/persist/wal.rs` | `WalLog`, `replay_entries()` |
| Restore | `src/server/server.rs:4373` | `restore_from_data_dir()` |
