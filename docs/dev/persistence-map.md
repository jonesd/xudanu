# The Persistence Map

Every kind of durable state in Xudanu: how it is written, how it is
loaded, how it can be recovered, and where it can be lost. Written
2026-10-06 after the trail-loss incident; the deterministic suite
(`tests/durability.rs`) enforces the contract row by row — **acked
⇒ present after recovery** — and the chaos harness
(`tests/durability_chaos.rs`) hunts the unusual paths.

The layers, in one sentence each:

- **Chunks** — content-addressed, immutable, never rewritten. The
  safest layer; corruption is detectable (BLAKE3), deletion is the
  only hazard (GC archives before reaping, grace period applies).
- **Manifests** — the pointer table (works → chunk refs, clubs,
  links, trails, admin state). Written at checkpoint, dual-slot
  (`manifest.json` + numbered `manifest_v*.json` history, short
  window). **The layer that gets rewritten** — and therefore the
  layer where state is lost when a checkpoint is wrong.
- **WAL** (`wal.log`) — append-only, fsync-per-entry, replayed on
  restore. The recovery path for everything acked since the last
  checkpoint. **Truncated unconditionally after every checkpoint** —
  currently destroys the good copy whenever the checkpoint is the
  bad one.
- **Sidecars** — `trails.json`, `detectors.json`,
  `ticket_nonces.json`, `key_history.json`, `server.key`:
  save-on-mutation, atomic tmp+rename, independent of the
  checkpoint machinery.

## The map

| Data | Saved | Loaded | Recovered if… | Failure modes |
|---|---|---|---|---|
| **Works + editions** | O-tree CRDT state → chunks at checkpoint; WAL: `work_create`, `work_revise` | restore reads manifest refs; WAL replays creates/revises; lazy mode defers chunk reads to first use | crash before checkpoint: WAL replay ✓; bad checkpoint: prior manifest (if still in window) + WAL | binary skew writing unrecognized editions; chunk GC before grace expiry; lazy-read of missing chunk (fixed: tmp-race #197) |
| **Revisions/history** | every revision chunked with history refs; WAL `work_revise` | `work_fetch_revision` by number | same as works | revision *counter* resets on WAL replay (cosmetic; content intact — see suite) |
| **Clubs / identities** | club chunks + manifest `club_refs`; WAL `club_upsert` | eager at restore | WAL replay ✓ | password/credential changes checkpoint-only |
| **Links** | manifest `links` (+ `links_hash` chunk); WAL: `create_link`, `delete`, `set_types`, ends add/remove, `endorse`/`unendorse`, `responds_to` | restore from manifest; WAL replay | crash: WAL ✓ | gathered-end complexity; none known open |
| **Trails** | manifest `TrailManifestEntry` at checkpoint; WAL: `create`, `rename`, `delete`, `add_stop`, `remove_stop`, **`publish` (added 2026-10-06)**; sidecar `trails.json` save-on-mutation | restore: manifest → sidecar belt-and-braces → WAL replay | any single layer suffices — the only triple-covered kind | `trail_publish` had no WAL until 2026-10-06 (fixed + tested); checkpoint-truncate still destroys WAL after a bad checkpoint |
| **Annotations** | annotations chunk at checkpoint; WAL `annotation_create`/`delete` | restore | WAL ✓ | — |
| **Stars / pins** | SocialSection chunk at checkpoint; WAL `star`/`unstar`/`pin`/`unpin` | restore | WAL ✓ | — |
| **Per-work license / kind** | `WorkEntry` fields at checkpoint; WAL `work_license_set` (added 2026-10-06) | restore | WAL ✓ (license); kind still checkpoint-only | license was checkpoint-only until 2026-10-06 (fixed + tested); **`work_set_kind` remains a gap** |
| **Admin state** (edit policy, network/external-links toggles, grants) | `AdminEntry` at checkpoint | restore | checkpoint only | **gap: checkpoint-only** — toggle changes revert on crash-before-checkpoint |
| **Detectors / watches** | sidecar `detectors.json` save-on-mutation (atomic rename) | restore reads sidecar | sidecar ✓ | no WAL; no fsync verified on rename; crash mid-write leaves the previous sidecar (atomicity saves it) |
| **Security audit log** | append-only `security.log.*` + checkpoints; hash-chained | restore + verify | append-only by design; checkpoints bound it | rotation edge; verification exists (`verify-security-log`) |
| **Keys** | `server.key`; `key_history.json` (rotations) | restore (passphrase-gated) | sidecar copy | passphrase loss = unrecoverable by design |
| **Blobs** | `blobs/` content-addressed, immutable | on demand | immutable; re-upload by hash | — |
| **Session tickets** | `ticket_nonces.json` sidecar | restore | sidecar ✓ | — |
| **Search index** | in-memory only | rebuilt on first query | derived data — nothing to recover | — |
| **Attribution / provenance** | `attribution/` + checkpoint entries | restore | checkpoint + log | — |

## Cross-cutting risks (the incident class)

0. **Torn-tail WAL poisoning (found by the chaos harness,
    2026-10-06 — FIXED).** A crash mid-append left a partial final
    line; `read_entries` correctly stopped replay there, but
    `WalLog::open` appended new entries *after* the tear — so every
    subsequently fsync'd, acked write became permanently unreachable.
    One hard crash poisoned the log; the next crash harvested
    everything written since. Almost certainly the mechanism behind
    the recurring weekly losses. Fix: `open` now truncates to the
    last valid entry boundary before appending, loudly. Regression
    coverage: the chaos harness's torn-WAL events.
1. **WAL truncate-after-checkpoint is unconditional.** The design
   assumes checkpoint ⊇ WAL. When a checkpoint drops state (binary
   skew, misparse), truncate destroys the only good copy. *Fix
   queued: rotate (`wal.log.N`, retain K) instead of truncate.*
2. **Replay silently skips unrecognized entries.** A WAL written by
   a different build dissolves without warning. *Fix queued: count
   + log skipped entries, surface in `/health`.*
3. **Manifest history window is short** (a handful of numbered
   files). *Fix queued: archive rotated manifests into `archive/`,
   never unlink.*
4. **No writer fingerprint.** Nothing records which build wrote a
   data dir; nothing refuses a foreign build opening it. *Fix
   queued: version+git-hash+dirty stamp in every manifest; restore
   refuses on mismatch without `--force`.*

## The recovery manager (design)

One orchestrated path instead of operator improvisation. Extends
the existing `xudanu-server recover <data-dir>` subcommand:

1. **Assess** — read version stamp, writer fingerprint, enumerate
   manifests (history window + archive), sidecars, WAL length,
   chunk counts. Classify: same-build / foreign-build / unknown.
2. **Guard** — foreign fingerprint requires `--force`; before
   proceeding under force, snapshot manifests + sidecars +
   `wal.log` into `recovery-<timestamp>/` inside the data dir.
3. **Restore chain, newest-valid-first** — validate each manifest
   in reverse order; first one that parses and passes
   `verify_store_with_manifest` wins. Then overlay sidecars
   (trails, detectors — newer mtime wins). Then replay WAL,
   **counting applied and skipped entries**.
4. **Verify** — chunk-store verification, security-log chain walk,
   sanity gate comparing work/trail/detector counts against the
   last known checkpoint. Refuse to *write* anything if the
   prospective state is gutted (the existing checkpoint gate,
   extended to trails and detectors).
5. **Report** — a recovery record appended to the security log
   (tamper-evident: recoveries are audit events), and a human
   summary: what was restored from which layer, what was skipped
   and why.

The manager turns "we lost data, which copy is good?" into a
command with a report — and, with the fingerprint guard, refuses to
be the instrument of the loss in the first place.

## Enforcement

- `tests/durability.rs` — deterministic, per-op, three scenarios
  (crash-before-checkpoint / checkpoint-restart /
  checkpoint-then-mutate-then-crash). **A failure here is a
  data-loss bug by definition.**
- `tests/durability_chaos.rs` — seeded random op sequences with
  random interruptions (crash, checkpoint, torn WAL, corrupted WAL
  byte), model-checked after every recovery. Run with
  `XUDANU_CHAOS_SEED=<n> XUDANU_CHAOS_ITERS=<n> cargo test
  --features server --test durability_chaos -- --ignored`.
