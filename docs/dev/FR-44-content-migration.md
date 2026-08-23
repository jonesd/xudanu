# FR-44: Automated Hands-Off Content Migration

Status: draft · Date: 2026-08-23
Builds on: FR-36 (chunk GC safety, #142 archive-first), FR-40
(named_ends/home_document fields), FR-43 (robots as test harness).
Trigger: self-hosting push — the README promises "snapshot migration
ensures your data survives upgrades" (README.md:107); that promise
must be machinery, not aspiration.

## Why

Users are about to store real content in Xudanu data dirs. Every
release may change schemas (just happened: FR-40 added
`named_ends`/`home_document`/`cross_server_notify` to LinkEntry).
The migration skeleton exists and runs on every boot — but it has
**zero real migration steps, zero round-trip tests, and no chunk
format versioning**. The gap between "skeleton works on synthetic
data" and "a stranger's notes survive every upgrade, forever" is
the work of this FR.

The invariant we owe self-hosters:

> **Any data dir written by any released version opens, migrates
> silently, and loses nothing on any later version — without user
> action, with a backup, with a way back.**

## Current state (measured, with code refs)

- `CURRENT_MANIFEST_VERSION = 4` (persist/manifest.rs:6) — v4
  baseline, no steps yet
- `read_manifest` (manifest.rs:~895): detects old version →
  **backs up manifest file** (`manifest.json.v3.bak`) → calls
  `migrate_manifest_to_latest` → **atomic tmp+rename write** →
  re-reads. Live code path, empty ladder.
- `migrate_manifest_to_latest` (persist/migrations.rs): returns
  input unchanged below v4; error above; helpers `rename_field`,
  `wrap_in_array` exist but are unused
- Newer-than-current rejected (`InvalidVersion`) — no downgrade
- Checksum tolerance for new default fields ("SCHEMA DRIFT...
  self-heal") — working, tested by every boot since the field
  additions
- Recovery tools exist: `verify`, `rebuild-manifest`,
  `verify-security-log` subcommands
- Root chunks have `format_version` (root_chunk.rs:8, value 1) —
  marker present, no migration story
- Edition chunks (edition_chunks.rs): postcard-serialized via
  registered type tags (chunk_store.rs `register_type`) — no
  version field, relies on serde defaults for forward-compat

## Stories

### S1 — The v4→v5 migration (first real step)
- FR-40's LinkEntry fields are the occasion: bump
  `CURRENT_MANIFEST_VERSION` to 5; the migration materializes
  `named_ends: []`, `home_document: null`, `cross_server_notify:
  null` on every stored link (and root-chunk registry equivalents)
- Exercises the entire live path on real data: backup, transform,
  atomic write, checksum self-heal
- Acceptance: a v4 data dir created by v1.7.0 opens in the next
  release, all FR-40 fields populated correctly, backup file
  present, no data loss — verified by S2's suite

### S2 — Migration test suite (the rigor)
For every migration step v(N)→v(N+1), a test that:
1. Writes a minimal **golden data dir fixture** in the OLD format
   (checked into `tests/fixtures/migration/v4/` etc., containing
   links, works, chunks — tiny but complete)
2. Runs `read_manifest` (the boot path — not a special API; we
   test what users actually hit)
3. Asserts: every field survives with value equality; backup file
   created and byte-identical to input; manifest version bumped;
   server starts and serves content from the migrated dir
4. Round-trip: migrating an already-current dir is a no-op
   (idempotence)
5. Rejection: a future-version dir (v6 against a v5 build) fails
   with a clear error naming both versions
- Acceptance: suite runs in CI on every push; adding a migration
  without a fixture fails the build (a checklist-style test
  enumerates steps and requires fixture + test per step)

### S3 — Golden data dirs in CI (the canary)
- `tests/fixtures/migration/` holds one dir per released format
  version (v4 = the v1.7.0 format)
- A CI job (or lib-test block) opens each fixture dir with the
  current build, boots a server against it in-memory-copied to
  tmp, runs the robots' reader persona against it for a smoke read
- Acceptance: CI proves "every released format opens today" on
  every push — a regression against any old format is caught
  before release, not by a user

### S4 — Chunk format versioning
- Root chunks already carry `format_version`; edition chunks gain a
  version marker inside the postcard payload (bump-able without
  breaking the chunk-store tag system)
- `preflight` subcommand extended: reports manifest version, root
  chunk version, edition chunk version range found in the store,
  and whether migrations will run
- Document the invariant: chunk format changes must be
  backward-compatible reads (serde defaults) or ship with a chunk
  migration step registered in a `chunk_migrations` table
- Acceptance: `preflight` on a v4 dir shows "manifest v4 → v5
  will run"; on current shows clean

### S5 — Automated upgrade test (end-to-end)
- A test that simulates the user journey: create data dir with
  version N binary format → run migration → upgrade → edit content
  → checkpoint → verify all pre-upgrade content still present and
  linked (backlinks intact, transclusions resolve, provenance
  verifies)
- Uses the FR-43 robots to generate realistic pre-upgrade content
  (links + revisions + transclusions), not just hand-written
  fixtures
- Acceptance: content created before an upgrade is fully navigable
  after, including link ends and span migration

### S6 — Escape hatch (the way back)
- `xudanu-server migrate <data-dir>` subcommand: applies all
  pending migrations explicitly (same code path as boot), prints a
  report (steps applied, backups written, content counts before/
  after)
- The per-step backup files (S1) are the documented rollback:
  `cp manifest.json.v4.bak manifest.json` restores the old format
  for downgrade-to-previous-binary scenarios; document this in the
  self-hosting README section
- Acceptance: `migrate` on a v4 dir produces the same result as
  boot migration; docs describe the rollback procedure

## Non-goals

- Chunk data rewriting for its own sake — serde-default forward
  compatibility plus version markers is the strategy; bulk rewrites
  are a last resort
- Export/import between Xudanu instances (separate concern;
  `rebuild-manifest` + volume copy covers most moves today)
- Migrating the WAL format (it is by design transient; replay
  compatibility is covered by the existing WAL tests)

## Sequencing

1. S2's test harness + S3's v4 fixture first (proves the
   skeleton works *before* relying on it)
2. S1 (v4→v5) — first real step, exercised by the harness
3. S6 (migrate subcommand + rollback docs)
4. S4 (chunk versioning) — marker now, discipline for future
5. S5 (robots-driven end-to-end) once FR-43 robots mature

## Heritage note

The 1984 proposal's §8i warns exactly about this class of risk
(already filed as #142 for GC): storage that accretes must have
explicit, safe evolution paths. Migration is the schema-evolution
half of that promise.
