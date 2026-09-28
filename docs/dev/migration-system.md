# Migration & Upgrade System

**Status:** core shipped with auto-migrate default (September 2026) — see [FR-82-data-migration.md](FR-82-data-migration.md) for the requirement-level spec
**Requirement:** a user upgrading between versions must never lose or
mangle content. Migration must be solid before the first external user.

## User Experience

```bash
# Default: the user just starts the server after upgrading the binary.
./xudanu-server run 127.0.0.1:8080 ./data
# (log) [migrate] data at format v3 < binary v4 — auto-migrating
#        (backup → migrate → verify → stamp)
# ...server boots on migrated data.

# Operators who want explicit control:
./xudanu-server run --no-auto-migrate 127.0.0.1:8080 ./data
ERROR: DATA FORMAT UPGRADE NEEDED: data directory is format v3
(written by xudanu v1.14.3), current is v4.
Run: ./xudanu-server upgrade ./data

# The explicit upgrade command (scripts, CI, recovery):
./xudanu-server upgrade ./data

  Data version: 1.14.3 (format v3), binary: 1.15.0 (format v4)
  Backed up to ./backup-20260927-140522.
  Migrated format v3 → v4 (1 step(s)).
  Verified: 47 works, 156 links, 4 trails — all OK
  Stamped: v1.15.0 (format v4)
  Upgrade complete. Start the server normally.

# If verification fails (either door):
  ERROR: verification found restore errors: work 0x1234 …
  Rolling back from ./backup-20260927-140522...
  Rollback complete. Original data intact.
```

## Design Principles

1. **Auto-migrate by default, never auto-downgrade** — startup runs
   the full safety pipeline on older data and boots; newer data
   always refuses. `--no-auto-migrate` restores explicit-only.
2. **One pipeline, two doors** — the `upgrade` command and startup
   auto-migration run the identical backup → migrate → verify →
   stamp code (src/server/upgrade.rs).
3. **Backup first, always** — a full copy of the data directory
   precedes any migration step.
4. **Verify after migration** — every work is opened, every checksum
   checked, every link resolved. If ANYTHING fails, the backup is
   restored.
5. **Exclusive while migrating** — a PID-keyed MIGRATION.lock stops
   concurrent servers from racing a half-migrated directory; stale
   locks from crashed migrations are stolen.
6. **Idempotent** — running upgrade on already-current data is a no-op
   with a clear message.
7. **Rollback guaranteed** — if any step fails, the data directory is
   restored from backup. The user's data is never in a half-migrated
   state.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│ Version Stamping                                        │
│                                                         │
│ root_manifest.json: {                                   │
│   format_version: 4,       ← chunk format schema       │
│   server_version: "1.14.4" ← which binary wrote this  │
│ }                                                       │
│                                                         │
│ data/VERSION (sidecar):                                 │
│   format_version=4                                      │
│   server_version=1.14.4                                 │
│   upgraded_at=2026-09-27T14:05:22Z                     │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ Migration Steps                                         │
│                                                         │
│ Each step: transform all chunks of a given type         │
│ from format N to format N+1. Steps are sequential.      │
│                                                         │
│ struct MigrationStep {                                  │
│   from_format: u32,                                     │
│   to_format: u32,                                       │
│   description: &str,                                    │
│   transform: fn(&ChunkStore) -> Result<(), Error>,     │
│ }                                                       │
│                                                         │
│ Steps are registered in a static list. Adding a new    │
│ step = bump format version + register the transform.    │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ Upgrade Command (xudanu-server upgrade <data-dir>)     │
│                                                         │
│ 1. Read current version stamp                           │
│ 2. If already current: exit 0 with message              │
│ 3. Backup data dir → data-backup-<timestamp>/           │
│ 4. For each migration step (from → to):                │
│    a. Apply transform to all chunks                    │
│    b. Rebuild root manifest                            │
│    c. Checkpoint                                       │
│ 5. Verification pass:                                  │
│    - Open every work, read full text                   │
│    - Check every work's BLAKE3 content hash            │
│    - Resolve every link's far end                      │
│    - Open every trail, count stops                     │
│ 6. On success: write new version stamp                 │
│ 7. On failure: restore backup, exit 1                  │
└─────────────────────────────────────────────────────────┘
```

## Forward Compatibility Rules

| Change | Safe? | Migration needed? |
|---|---|---|
| Add a field (with serde default) | ✅ | No |
| Remove a field | ✅ (old data ignored) | No |
| Rename a field | ❌ | Yes — rename_field() |
| Change a field's type | ❌ | Yes — custom transform |
| Change chunk layout | ❌ | Yes — custom transform |
| Add a new chunk type | ✅ | No |
| Change serialization format | ❌ | Bump format version |

## Implementation Checklist

- [x] Version stamp: `server_version` + format version in data/VERSION sidecar
- [x] Startup check: refuse to start if format_version doesn't match (both directions)
- [x] `xudanu-server upgrade <dir>`: full backup → migrate → verify → stamp
- [x] Verification pass: restore all works, count links and trails, fail on restore errors
- [x] Rollback: restore from backup on any failure
- [ ] Register first migration step (v1 → v2, when we need one)
- [ ] Dedicated tests for the two startup-refusal messages
- [ ] Integration test: create data with format N, upgrade to N+1, verify
- [ ] CI: run upgrade test on every release
- [ ] Document the migration step authoring guide (FR-82 §Authoring)
