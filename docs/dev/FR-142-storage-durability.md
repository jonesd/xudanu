# FR-142 — Storage Durability: the acked-⇒-present contract

> **Status:** Implemented (2026-10-06). Test instruments shipped with
> it; two of the four fixed mechanisms were found by those
> instruments during development.
>
> **Related:** `docs/dev/persistence-map.md` (the per-kind map),
> `tests/durability.rs` (deterministic suite),
> `tests/durability_chaos.rs` (chaos harness), FR-52 (manifest
> format), FR-83 (lazy restore), FR-43 (dispatch metrics).

## Motivation

Data loss recurred roughly weekly in development: trails vanished
repeatedly, most recently on 2026-10-06 when a server swap restored
a WIP-written data directory with a main-line binary and
checkpointed the result. Each incident was treated as a bug to find
after the fact. FR-142 turns durability into a contract with
instruments that enforce it before merge.

## The contract

**Acked ⇒ present after recovery.** If the server returned `Ok`
for a mutation, that fact must be observable after *any* legal
failure:

1. **Crash before checkpoint** — the WAL is the only recovery;
2. **Checkpoint, then restart** — the manifest is the only recovery;
3. **Checkpoint, then more mutations, then crash** — manifest plus
   post-checkpoint WAL replay.

A fourth, hostile case: **a torn or corrupted final WAL entry** —
legal because only the entry being written at crash-instant can be
damaged; earlier entries were fsync'd before their acks.

## The layers (see persistence-map for the full table)

- **Chunks** — content-addressed, immutable, BLAKE3-verified. The
  safest layer; nothing rewrites them.
- **Manifests** — the pointer table, rewritten at checkpoint. The
  layer where a *wrong* checkpoint loses state; hence rotation now
  archives (`archive/manifests/`) instead of deleting.
- **WAL** — append-only, fsync-per-entry, replayed at restore. Now
  rotated (`wal.log.1..3`) instead of truncated to zero, so it
  remains recovery material after a bad checkpoint.
- **Sidecars** — `trails.json`, `detectors.json`: save-on-mutation,
  atomic tmp+rename, independent of checkpoint machinery. The
  trails sidecar now *merges* at restore (resurrects lost trails,
  never drops manifest trails).

## How the tests fleshed out the mechanisms

The instruments were not written after the fixes; the fixes were
iteratively *driven* by them. The sequence, honestly recorded:

1. **Deterministic suite first.** One test per op class × the three
   scenarios. It failed immediately on `trail_publish` — which had
   no WAL coverage at all. Fixed; test green. This is the intended
   workflow: the suite defines "done".

2. **Chaos v1 — and a lesson in physics.** The first harness tore
   the WAL at a *random byte*, which can damage entries that were
   fully fsync'd and acked — physically impossible after `sync_all`
   precedes every `Ok`. It failed; the failure was in the model,
   not the server. Corrected: only the final entry may tear or
   corrupt, and the model prunes the final fact when legal damage
   occurs.

3. **Chaos v2 found the big one.** With correct physics, every seed
   failed with *works going missing* across restores — exposing
   **torn-tail poisoning**: `WalLog::open` appended after a torn
   line, so every subsequent write was fenced off from replay
   forever. One hard crash planted the seed; the next crash
   harvested everything written since. Fix: `open` sanitizes to the
   last valid entry boundary before appending.

4. **Extending to all classes found two more.** Widening the suite
   to kind/title/archive/annotations/rename produced two immediate
   failures: `trail_rename` was WAL'd but **never replayed**, and
   `work_kind_set` had no WAL at all. Both fixed with append +
   replay + tests.

5. **The sidecar tests forced the merge.** Testing the sidecar as a
   last-resort layer revealed its restore was replace-if-bigger — a
   stale-but-larger sidecar would *wipe* newer manifest trails,
   making the recovery layer itself a loss vector. Rewritten as a
   merge; both directions now tested.

6. **Binary skew, closed by construction.** The incident class
   behind the 2026-10-06 trail loss cannot be tested as a crash;
   it is a *writer* problem. `build.rs` stamps every manifest with
   a writer fingerprint (git hash + profile + dirty), and restore
   refuses foreign writers unless `XUDANU_ALLOW_FOREIGN_WRITER=1`.
   The gate is unit-tested at its seam.

## What the instruments enforce today

| Instrument | Scope | Cadence |
|---|---|---|
| `tests/durability.rs` (20 tests) | every op class × 3 scenarios, sidecar rescue both directions, writer gate | every CI run |
| `tests/durability_chaos.rs` | 14 op classes × crash/checkpoint/torn/corrupt, model-checked, seeded | explicit (`--ignored`); marathon before releases |
| WAL module tests (47) | append/replay/rotate/sanitize units | every CI run |

A failure in any of these is a data-loss bug by definition — not a
flake to rerun.

## Deliberately out of scope (follow-ups)

- Per-entry WAL checksums (needs a WAL format version bump; noted
  in the H7 fix comment).
- Concurrent-session chaos (harness is single-session sequential).
- The recovery-manager subcommand orchestrating the layers
  (designed in persistence-map.md).
- Extending the checkpoint sanity gate to refuse persisting a
  state that drops trails/detectors below last-known counts.
