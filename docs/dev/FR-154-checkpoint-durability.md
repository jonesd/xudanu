# FR-154 — Checkpoint durability: self-healing bookkeeping + visible health

**Status:** proposed — root-caused live (2026-10-26 debugging session); implementation pending.
**Found in the wild:** the dev data dir has run with **53+ consecutive checkpoint
failures and zero successes** — `manifest.json` untouched since
**2026-08-15**. Every write since then survived on WAL replay alone.

**Builds on:** FR-45 (admin console — the notification surface this FR
fills in), FR-82 (verify/migration machinery), FR-152 (archive-tier
durability discipline).

## The incident (why this FR exists)

A stale covering checkpoint for `security.log.2026-08-05` ("expected 0
entries, tracking 8" — `log_checkpoint.rs:343`) made every checkpoint
attempt fail. Because the failure was WARN-level only, the server ran
in silently degraded durability for over two months. User-visible
symptom, much later: annotations (heading/code_block formatting)
vanished after work switches — the server re-materialized work state
from stale chunks because no checkpoint had ever landed the newer
state. The debugging trail that found it: server-side canary
annotations dying without any client delete frame → checkpoint log →
the mismatch.

Two compounding defects:

1. **Fragile bookkeeping.** Per-file entry counts are *derived* state;
   the hash chain is the integrity guarantee. A count mismatch with a
   cryptographically valid chain is drift, not tampering — yet the
   code treats it as fatal, permanently. There is no recovery path,
   so one drift event stalls checkpointing forever.
2. **Invisible failure.** No surface exposed checkpoint health:
   `/health` returns OK, `AdminServerHealth` reports counters
   (operation_count, blob_count, link_count, uptime_secs) but nothing
   about durability, the admin console shows no banner, startup logs
   WARN not ERROR, and `preflight` does not check it. Fifty-three
   consecutive failures produced zero human-visible signal.

## Design

### S1 — Self-healing checkpoint bookkeeping

On count mismatch (`entries != cp.entries`), before failing:

1. Verify the file's chain (`verify_log`) against the prior head.
2. **Chain valid** → rewrite the covering checkpoint to the recomputed
   counts, emit `WARN` + a chained-log audit entry naming the healed
   file, continue the checkpoint. Bookkeeping is derived state; the
   chain vouches for the content.
3. **Chain invalid** → fail closed (current behavior) — that IS
   tampering/corruption, and FR-152-style recovery applies.

### S2 — Visible health (the notification system IS the app)

- `/health` gains a durability section:
  `last_checkpoint_success_at`, `consecutive_failures`,
  `manifest_age_days`, `healed_bookkeeping_count`.
- `AdminServerHealth` (wire) gains the same fields; the admin console
  renders a **durability banner** when degraded ("Checkpoint failures
  since {date} — edits may not survive a restart"). For self-hosted
  deployments there is no ops team; the workspace UI is the pager.
- Startup escalates to `ERROR` when the manifest is staler than a
  threshold (default: 7 days).

### S3 — Preflight gate

`preflight` fails on checkpoint ill-health: consecutive failures > 0
or manifest age past threshold. Deploy scripts inherit the gate.

### S4 — Regression test

Build the exact incident state in a temp data dir: rotated security
log + stale covering checkpoint (counts disagree) + valid chain.
Assert: checkpoint self-heals, succeeds, audit entry recorded, and a
second run is clean. Variant: broken chain still fails closed.

## Repair runbook (the live dev data dir)

1. Back up the data dir (scripts/backup-offsite.sh or a plain copy).
2. `xudanu-server verify-security-log <dir>` — confirm the chain
   verifies (expected: valid; the mismatch is counts, not hashes).
3. Apply S1 (or manually correct the covering checkpoint for
   `security.log.2026-08-05` to 8 entries).
4. Watch a checkpoint land — first manifest write since Aug 15 — and
   confirm annotations survive a work switch + server restart.

## Non-goals

- Restructuring the checkpoint bookkeeping model (the self-heal makes
  drift recoverable; redesign is not required to fix the class).
- Push notifications beyond the app surfaces (banner/health/preflight
  cover self-hosted reality; external alerting can key off `/health`).

## Related

- FR-45 — admin console (surfaces the new health fields)
- FR-82 — the verify-before-stamp discipline this extends to
  checkpoint state
- FR-152 — the archive tier: reclamation with an undo horizon; this
  FR is its durability-side sibling (persistence with a heartbeat)
