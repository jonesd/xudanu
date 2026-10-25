# FR-152 — Chunk Archive Recovery: operator's guide to the #142 archive tier

**Status:** shipped (feature is #142 archive-first GC, live since the
persistence hardening); this FR documents the recovery surface and
positioning so operators have one reference instead of source-diving.

**Heritage:** the 1984 Xanadu System Proposal, §8i — storage that
accretes must have an explicit, safe reclamation story. Xudanu's
translation: reclamation converts "possibly harmful" deletion into
"definitely recoverable" archiving, with a bounded undo horizon.

## Why

Chunk GC runs at checkpoint time and moves unreferenced chunks out of
the live store. An operator who sees this line —

```
INFO persist_snapshot: Chunk GC: archived 10 orphaned chunk(s), reaped 7 expired from archive (grace 50 gens, gen 3827), 9017 referenced, 9027 total on disk
```

— needs to know: what was archived, whether it can come back, how,
and what the risks are. This FR answers that in one place.

## Guarantees (the contract)

1. **Archive-first, never delete-first.** Orphaned chunks are MOVED
   to the archive tier (`<data-dir>/chunks/archive/` in the chunk
   store's base dir), not deleted. Hard deletion happens only after
   the grace horizon.
2. **Bounded undo horizon.** A chunk archived at generation N is
   recoverable until generation N+50, then permanently reaped. The
   `.gen` sidecar stamp (`<hash>.gen`) records the archive
   generation; `reap_expired_archive(current_gen, 50)` enforces it.
3. **Content-addressed safety.** Chunks are keyed by BLAKE3 hash —
   a restored chunk cannot alias or corrupt anything. Worst case it
   is an unreferenced blob.
4. **Idempotent restore.** Restore COPIES back to the live store
   (the archive original is kept) — re-running is always safe.
5. **Self-healing.** A restored chunk the current manifest still
   does not reference is simply re-archived by the next GC cycle
   (the re-archive path is explicit in the code). No manual cleanup,
   no permanent bloat — only a temporary space increase.
6. **Fail-safe GC.** If reference collection fails for any input,
   the sweep skips entirely rather than risking deletion of valid
   chunks.

## Mechanism — the `recover` subcommand

Run with the server **stopped** (offline recovery operates directly
on the data directory):

```sh
# Inspect: manifest roots, readability report, archive count, hints
xudanu-server recover <data-dir> --list

# Restore ALL archived chunks to the live store (idempotent copies)
xudanu-server recover <data-dir> --unarchive

# Roll the manifest back to a specific root chunk
xudanu-server recover <data-dir> --rollback <root-hash>

# Same, overriding the rollback safety check (know what you are doing)
xudanu-server recover <data-dir> --force-rollback <root-hash>
```

`--list` prints the archive tier size and the exact commands for
both recovery paths. `verify` (`xudanu-server verify <data-dir>`)
also surfaces the archive count in its report.

Code map: `persist/chunk_store.rs` (`move_chunk_to_archive`,
`restore_archived_chunk`, `restore_all_archived`,
`reap_expired_archive`, `archived_chunk_count`),
`server/server.rs` (`gc_orphaned_chunks`, the `GcInputs` snapshot),
`bin/xudanu-server.rs` (`cmd_recover`).

## Positioning: what recovery actually means

Restoring chunks is **necessary but not sufficient** — a chunk only
matters if a *manifest* references it. The two meaningful recovery
scenarios:

1. **Manifest rollback** (the companion operation): restore to an
   older manifest root (`--rollback`), then `--unarchive` so the
   chunks that root references are live again. Order matters when
   in doubt: unarchive first is harmless (guarantee 5), rollback
   first is fine too since `--list` shows both.
2. **Reachability-walk bug**: a GC bug that archived chunks still
   referenced by the current manifest. `--unarchive` restores
   everything; the next GC re-archives only true orphans.

There is no scenario where unarchiving alone recovers user-visible
content — it feeds rollback and bug remediation, not day-to-day ops.

## Risks

| Risk | Reality |
|---|---|
| Restoring corrupts the store | Cannot — content-addressed; wrong restore is inert |
| Restored chunks accumulate | No — next GC re-archives unreferenced ones |
| Reaped chunks recoverable | No — past the 50-gen horizon deletion is permanent; only `backup-offsite.sh` remains |
| Running while server live | Don't — `recover` is an offline command; a running server's next checkpoint would race the restore |
| Losing data by NOT restoring | No — the archive tier is write-only from the GC's perspective; nothing touches it until reap |

## Environment flag (danger)

`XUDANU_GC_AGGRESSIVE=1` disables the archive tier and restores
immediate-delete behavior, intended for space-constrained test runs.
Never set it on real data directories — it voids every guarantee
above.

## Future extensions

- **Selective restore**: the library has single-hash
  `restore_archived_chunk(hash)` but no CLI flag exposes it; a
  `--unarchive <hash>` variant is a small, natural addition when a
  partial-recovery case actually arises.
- **Archive inspection**: `--list` reports a count; a per-chunk
  listing (hash, archived-at generation, reaps-at generation) would
  make the horizon auditable.

## Test plan

Shipped behavior is covered in `server.rs` tests: orphan-then-
archive, restore-then-read, idempotent restore, re-orphan-after-
restore, and grace-window expiry (see the `#142` test block around
`gc_orphaned_chunks`). This FR adds no new behavior — it documents
the existing surface.
