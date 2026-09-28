# FR-82 — Data Migration: upgrades must never lose user content

**Status:** core shipped (September 2026), auto-migrate default; first real migration step pending format v2
**Heritage:** Xanadu's permanent-document discipline — a docuverse where
content outlives binaries. The inverse framing: binaries are ephemeral,
data directories are the user's property. This FR governs what happens
when a user upgrades (or downgrades) the binary that opens their data.
Design doc: [migration-system.md](migration-system.md).

## Why

Every release risks a schema change silently mangling an older data
directory. The persistence audit (September 2026) found thirteen bugs
of the class "write path and read path diverged"; version skew is that
class generalized across time. A user who upgrades `xudanu-server`
must never lose works, links, trails, or detectors — and must never be
left in a half-migrated state. Migration must be solid **before the
first external user**, because after that point old data exists in the
wild.

## Guarantees (the contract)

1. **Auto-migrate by default, refuse-to-guess always.** Startup on
   older-format data runs the full safety pipeline (below) and boots
   on success — zero-friction upgrades (the away-for-six-months
   user). Operators can restore refuse-and-instruct behavior with
   `--no-auto-migrate` or `XUDANU_NO_AUTO_MIGRATE=1`; the explicit
   `xudanu-server upgrade` command always exists for scripts.
2. **Never auto-downgrade.** Data newer than the binary always
   refuses, in every mode — an older binary must not "helpfully"
   rewrite newer data.
3. **Backup before touch.** Every migration (auto or explicit) copies
   the entire data directory before any step runs.
4. **Verify before stamp.** After migration, every work, link, and
   trail is restored and checked. Any restore error rolls the entire
   upgrade back from the backup.
5. **Exclusive while migrating.** A `MIGRATION.lock` (PID-keyed,
   stale locks stolen) prevents concurrent servers from racing a
   half-migrated directory.
6. **Idempotent.** Upgrading already-current data is a no-op that
   refreshes the stamp.
7. **Fail closed on unknown provenance.** An upgrade from a version
   with no registered step chain is an error, never a guess.

## Mechanism

### The VERSION sidecar

`data/VERSION` — a JSON sidecar beside the root chunk:

```json
{
  "format_version": 1,
  "server_version": "1.14.4",
  "upgraded_at": "2026-09-27T14:05:22+00:00"
}
```

It is a sidecar (not a field in the root chunk) because the root chunk
is postcard — positional bytes; embedding a version there would break
every older binary's ability to read the chunk at all, defeating the
purpose.

Write points:
- `init` (fresh data dir: stamped from the first boot)
- every `checkpoint_completed` (the stamp always reflects the binary
  that last wrote the snapshot)
- `upgrade` (the authoritative stamp refresh)

Read points:
- startup version check (below)
- `upgrade` command (below)

`format_version` tracks `ROOT_CHUNK_FORMAT_VERSION` (currently 1 — the
baseline). Chunk-level formats carry their own guards in addition:
each chunk type (root, manifest v4, edition chunks, WAL v1) checks its
own embedded version and refuses *newer-than-supported* with an
"upgrade xudanu-server" message. The sidecar is the fast, whole-dir
gate; the per-chunk checks are defense in depth.

### Startup version check

`restore_from_data_dir` (src/server/server.rs) reads the sidecar (or
infers the stampless era) before restoring:

- `data_format > binary` → refuse (never auto-downgrade):
  `DATA FORMAT MISMATCH: data directory is format vN (written by
  xudanu X), but this binary supports vM. Upgrade xudanu-server to
  open this data.`
- `data_format < binary` → the gate decides:
  - default → **auto-migrate**: run the shared pipeline
    (`xudanu::server::upgrade::run_upgrade` — backup → migrate →
    verify → stamp, rollback on failure), then boot. A failure
    refuses boot with `AUTO-MIGRATION FAILED: …` and the original
    data intact.
  - `--no-auto-migrate` / `XUDANU_NO_AUTO_MIGRATE=1` → refuse with
    `DATA FORMAT UPGRADE NEEDED: … Run: xudanu-server upgrade <dir>`.
  - the pipeline's own verification restore → proceeds (the stamp is
    written only after verify passes; a thread-local guard makes the
    re-entrancy explicit).
- **no stamp, no manifest** → open normally; the restore fails
  naturally if the directory is not real data.
- **no stamp + manifest** → the pre-sidecar (v1.14.4) era: baseline
  format, gated the same way once formats advance past v1.

### The upgrade command

`xudanu-server upgrade <data-dir>` — offline, explicit:

```
xudanu upgrade — checking ./data
  Data version: 1.14.4 (format v1), binary: 1.15.0 (format v2)
  Backing up to ./backup-20260927-140522...
  Migrating format v1 → v2...  Applied N migration step(s).
  Verifying data integrity...
  Verified: 47 works, 156 links, 4 trails — all OK
  Stamped: v1.15.0 (format v2)
  Upgrade complete. Start the server normally.
```

Order of operations (src/bin/xudanu-server.rs `cmd_upgrade`):

1. Read the stamp (missing = format 0, "very old data").
2. Already current → refresh the stamp, exit 0.
3. Data newer than binary → refuse, exit 1.
4. Backup: full recursive copy to a sibling
   `backup-<YYYYMMDD-HHMMSS>/` directory.
5. `apply_migration_steps(dir, from_version)` — the registered step
   chain, one step per format bump, sequential.
6. Verification: full `restore_from_data_dir` + work/link/trail
   counts; any entry in `restore_errors` fails the upgrade.
7. Stamp the new version.
8. Any failure at steps 5–6: delete the migrated directory, rename the
   backup back, exit 1 — original data intact, no changes made.

### Authoring a migration step

Steps are plain data in a registry (src/persist/migrations.rs):

```rust
pub struct MigrationStep {
    pub from_format: u32,
    pub to_format: u32,
    pub description: &'static str,
    pub transform: fn(&Path) -> Result<(), MigrationError>,
}
```

To ship a format bump: bump `ROOT_CHUNK_FORMAT_VERSION`, append a
`MigrationStep` to the static `MIGRATION_STEPS` list, write the
transform (a plain fn over the data dir). Helpers exist: `copy_dir`,
`rename_field`, `wrap_in_array`. JSON sidecars migrate with
serde_json transforms; postcard chunks are rewritten whole
(deserialize with `#[serde(default)]` compat → re-serialize at the
new version).

**Custom steps**: library embedders and tests pass their own chain
to `apply_steps_with(dir, from, target, steps)` — the same walker
`upgrade` uses over the production registry.

**Multi-revision walks** (the away-for-six-months case): the walker
applies every intermediate step in format order — data at v1 under a
v4 binary runs v1→v2, v2→v3, v3→v4. Data already at a middle
revision skips the steps behind it (re-running an old step could
corrupt what the next step expects to transform). A gap in the chain
is `NoStep` — fail closed, roll back — never a guess.

Serialization rules that keep future steps cheap (learned from the
persistence audit):
- never `skip_serializing_if` in postcard structs (positional —
  skipping misaligns following bytes)
- new fields need `#[serde(default)]`
- renaming or retyping a field is exactly the case that forces a step

## Layered version map (current)

| Layer | Constant | Value |
|---|---|---|
| Whole-dir gate | `ROOT_CHUNK_FORMAT_VERSION` (root_chunk.rs) | 1 |
| Manifest | `CURRENT_MANIFEST_VERSION` (manifest.rs) | 4 |
| Edition chunks | `EDITION_CHUNK_FORMAT_VERSION` (edition_chunks.rs) | 1 |
| WAL | `WAL_VERSION` (wal.rs) | 1 |

Only a change that old binaries cannot read safely bumps the root
format; additive serde-compatible changes do not.

## Exit criteria

- [x] VERSION sidecar written on init and every checkpoint (sync and async paths)
- [x] Startup check refuses mismatched data in both directions
- [x] Missing sidecar opens normally (v1.14.4-era dirs upgrade cleanly)
- [x] `upgrade` command: backup → migrate → verify → stamp, rollback on failure
- [x] Idempotent re-run on current data
- [x] Migration helpers with unit tests (rename_field, wrap_in_array)
- [x] Step registry + chain walker (`apply_steps_with`): custom steps,
      multi-revision walks, middle-revision skips, fail-closed gaps
- [x] Tests: startup refusals (newer always; older when opted out),
      auto-migrate boot through a chain, auto-migrate failure rollback,
      concurrent-lock blocking, corrupt stamp degradation, re-stamp on
      checkpoint, CLI upgrade paths (happy/idempotent/refuse/rollback/
      non-data-dir), multi-revision chains over real server data
      (tests/migration_cli.rs, src/persist/migrations.rs)
- [ ] First real step (v1 → v2) in the production registry
- [ ] CI job: create data at format N, upgrade, verify (release gate)

## Out of scope

- Auto-refresh of stale backups (retention is the operator's business).
- Migrating **between servers** (replication/federation covers that).
- Downgrade migration (refused; restore from a backup instead).
- Content-set reseeds (curated reset script is a separate mechanism —
  see the release checklist's three constitutional guarantees).
