# Migration & Upgrade System

**Status:** building (September 2026)
**Requirement:** a user upgrading between versions must never lose or
mangle content. Migration must be solid before the first external user.

## User Experience

```bash
# What a user sees when upgrading:
./xudanu-server run 127.0.0.1:8080 ./data

# If data is from an older version, the server REFUSES to start:
ERROR: data directory was written by xudanu v1.14.3 (format v3).
Current version: v1.15.0 (format v4).
Run: ./xudanu-server upgrade ./data

# The upgrade command:
./xudanu-server upgrade ./data

  Backing up to ./data-backup-20260927-140522/... done (42 MB)
  Migrating format v3 → v4... done (3 steps)
  Verifying 47 works, 156 links, 4 trails... all OK
  Stamping version: v1.15.0 (format v4)
  Upgrade complete. Start the server normally.

# If verification fails:
  ERROR: work 0x1234 checksum mismatch after migration.
  Rolling back from backup... done.
  Upgrade FAILED — original data intact, no changes made.
```

## Design Principles

1. **Refuse to open, don't auto-migrate** — the server refuses to
   start on data from a different format version. This prevents a new
   binary from silently mangling old data.

2. **Backup first, always** — the upgrade command creates a full copy
   of the data directory before any migration step.

3. **Verify after migration** — every work is opened, every checksum
   checked, every link resolved. If ANYTHING fails, the backup is
   restored.

4. **Idempotent** — running upgrade on already-current data is a no-op
   with a clear message.

5. **Rollback guaranteed** — if any step fails, the data directory is
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

- [ ] Version stamp: add `server_version` to root manifest + data/VERSION sidecar
- [ ] Startup check: refuse to start if format_version doesn't match
- [ ] `xudanu-server upgrade <dir>`: full backup → migrate → verify → stamp
- [ ] Verification pass: open all works, check hashes, resolve links
- [ ] Rollback: restore from backup on any failure
- [ ] Register first migration step (v3 → v4, when we need one)
- [ ] Integration test: create data with format N, upgrade to N+1, verify
- [ ] CI: run upgrade test on every release
- [ ] Document the migration step authoring guide
