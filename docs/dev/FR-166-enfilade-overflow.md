# FR-166: Enfilade Overflow — Spill Safety and Fault-In

**Status:** Phase 1 landed (PRs #248–#251); Phase 2 parked
**Created:** 2026-11-08
**Depends on:** FR-34 (enfilade-native substrate), FR-142 (storage durability)
**Siblings:** FR-76 (epoch-structured enfilade — epochs persist the tree over time; this FR moves cold branches out of RAM without losing them)
**Author:** David Jones

---

## The problem

Content moves between the enfilade in RAM and the chunk store in two
directions, and a crash can interrupt either one at any point:

1. **OUT** — a branch leaves RAM: `evict` spills the encoded branch to a
   backend, then replaces the entry with a stub.
2. **IN** — a stub faults back: `fault_in` fetches bytes, decodes them,
   verifies the contents hash, and re-materializes the branch.

The core concern is interruption: something breaks halfway through
either movement. This FR's claim is that **every window has a defined
outcome, and no window loses committed data or yields wrong data.**
Two outcomes are permitted: clean retry, or a typed miss that triggers
re-derivation. Nothing dangles; nothing corrupts silently.

## The central decision: the spill store is a cache

The spill store is a cache over re-derivable state, never the system of
record. The evidence, from the code rather than preference:

- Every document edit is WAL-logged with a per-op fsync before the
  server applies it (`persist::wal::WalLog::append` → `sync_all`;
  `server.rs` `append_work_revise` et al.), and restore rebuilds from
  canonical chunks plus WAL replay.
- The ent layer the spill store serves is itself derived: dagwood
  metadata rebuilds from work (`edition::backfollow`), and
  `BranchStore` restores from snapshots.
- Nothing in `server/` touches `BranchStore` today (the wiring is
  Phase 2).

Consequence: losing an un-flushed spill is an **availability** event —
`BranchError::SpillMiss` on fault-in, then rebuild — never data loss.
This is why `spill()` is admission (an insert into a pending map,
~2 µs) and `flush_pending()` is the barrier (one pack chunk fsynced by
`write_chunk`, then all locator lines appended in one write + fsync).
The pre-barrier design (PR #249's per-spill fsync, ~4.2 ms/op) was
buying durability this layer never needed.

## Interruption ledger — moving OUT (RAM → store)

| # | Crash point | State after restart | Outcome |
|---|---|---|---|
| W1 | before `spill()` returns | branch still Materialized; no stub | nothing happened |
| W2 | `spill()` itself errors | evict aborts; branch stays Materialized | clean retry (Gold's "should this ensure that the flock is not dirty?", shephx.cxx 127, answered structurally) |
| W3 | spill admitted, not yet flushed (crash skips Drop) | stub present, pending bytes gone | fault-in → `SpillMiss` → re-derive. **The documented loss window** — availability, never correctness; bounded by the pending caps (a spill that crosses a cap commits the batch first; defaults 65,536 entries / 32 MiB, `with_limits`) |
| W4 | during the flush's pack write | torn or absent pack; no locator lines appended yet | orphan chunk, harmless and GC-able; no dangling locator. Chunks land via tmp + atomic rename, so no partial file ever exists at a final path; stale `.tmp` files are swept at store open |
| W5 | during the flush's journal append (one multi-line write + fsync) | torn final line | replay drops the incomplete last line and truncates the file so appends land on clean boundaries; a complete line missing only its newline is accepted; an unparsable **interior** line remains fatal (real corruption should not be silently skipped) |
| W6 | after the journal fsync | pack and locators both durable | committed |
| W7 | flush errors after the pack write (e.g. journal sync fails) | pending map retained untouched | retry is safe: a retry appends superseding lines; replay is later-line-wins and compaction eventually removes the dead lines |

**Ordering invariant:** a chunk is made durable *before* any locator
naming it is appended (pack `write_chunk` fsync → then journal lines +
fsync). A crash can orphan a chunk; it can never dangle a locator.

## Interruption ledger — moving IN (store → RAM)

| # | Failure | Behaviour |
|---|---|---|
| W8 | locator absent / backend lost (spill dir wiped, snapshot restored elsewhere) | typed `SpillMiss`; never wrong data |
| W9 | chunk tampered on disk | cold reads re-verify BLAKE3 → typed error. Hot entries are served from the 1024-entry read cache unverified, so detection is late (cold/post-restart), not absent |
| W10 | right chunk, wrong entry | the spill key is `(BranchId << 32) \| contents_hash`, and `fault_in` re-derives and compares the contents hash — fault-in is **total**. Two independent integrity layers: chunk BLAKE3, ent contents hash |
| W11 | bytes decode but are malformed | `decode_branch` rejects (format version, kind discriminant, lengths) |
| W12 | crash mid-fault | fault-in is read-only with respect to persistent state; the stub is replaced only after decode + verify succeed. Retry is idempotent |

## Landed state

- **PR #248** — ent `getReal()` fault-in: `BranchSpill` trait,
  `InMemorySpill`/`FileSpill`, evict/fault/materialize; the stub carries
  the *contents* hash (total fault-in); spill-before-stub with
  failed-spill-aborts-evict.
- **PR #249** — `ChunkStoreSpill`: dedicated `ChunkStore` instance,
  append-only locator journal, manifest-verify isolation.
- **PR #250** — admission/barrier durability, packs with a sorted key
  directory (binary-search fetch), torn-tail tolerance, legacy
  solo-chunk fallback.
- **PR #251** — spill GC (the `dismantle()` role: deletes chunk files the
  journal no longer references; runs at open) and pending caps (a spill
  that would cross a cap commits the batch first, bounding W3 by
  configuration at unchanged amortized cost).

### Measured (P7, 5k branches, APFS external SSD)

| Backend | evict | flush barrier | fault |
|---|---|---|---|
| InMemory (machinery floor) | 2.2 µs | n/a | 1.8 µs |
| File | 89 µs | n/a | 27 µs |
| ChunkStore lazy | 1.9 µs | 10.6 µs amortized | 10.1 µs |
| ChunkStore eager (per-op barrier) | ~4–12 ms | per-op | 64 µs |

Lazy admission is ~2,160× faster than the per-spill-fsync design; the
barrier amortizes two fsyncs across the whole batch; pack faults cost
~3× a solo-chunk fault (directory probe). The first pack format used a
linear scan and measured **470 µs/fault** — the sorted directory exists
because of that number.

## Decision ledger — Gold principle vs Xudanu divergence

| Decision | Source | Note |
|---|---|---|
| Stub replaces the object; identity stays stable | Gold principle | `becomeStub`, shephx.cxx 121-131 |
| The stub caches a hash | Gold principle, divergent content | Gold cached the identity hash (`hashForEqual`) for cheap equality; Xudanu caches the *contents* hash so fault-in is total |
| Failed spill aborts evict | Gold's open question, made structural | the "dirty flock" note (shephx.cxx 127) gets a typed answer |
| Locator invalidation states | Divergence | Gold's `FlockInfo` (shephx.hxx 312-326) tracked "state of this flock wrt disk"; content addressing derives the locator, so there is no state to drift |
| Batched disk writes | Gold principle, briefly lost | the packer wrote flocks in sweeps; #249 diverged (per-spill fsync), #250 returns to the batched shape via packs |
| Durability lives above the spill layer | Gold principle | the original's commit discipline; Xudanu's form is the per-op-fsync WAL, with the spill store explicitly a cache |
| Granularity: per-branch today | Divergence, scale-bounded | Gold spilled flocks (subtrees); packs make subtree grouping a policy choice, parked for Phase 2 |
| Spill garbage collection | Gold had it (`dismantle()`, shephx.cxx 143+) | landed (PR #251): `gc()` runs at store open; failure is tidiness-loss, never availability-loss |

## Phase 2 (parked)

- **Residency**: who calls evict, flush cadence at checkpoint
  boundaries, op-boundary interactions, async wiring (the adapter is
  synchronous `std::fs`; a tokio host must `spawn_blocking`).
- **Subtree-locality packs** (the full flock model — group evictions by
  enfilade subtree for locality-aligned packs).
- **Audit coverage**: the spill dir is outside the chained security log
  today; acceptable while it is a re-derivable cache, revisited if it
  ever becomes load-bearing.

Sequencing: hardening landed first (GC + caps, PR #251); residency is
next — it defines the cadence everything else plugs into and is the
step that wires `ChunkStoreSpill` into the live server behind a flag;
subtree-locality packs and audit coverage follow once something live
is evicting.

## Test coverage map

| Window | Test |
|---|---|
| W3 | `crash_before_flush_loses_pending` (via `mem::forget`, which is what a crash does to Drop) |
| W5 | `torn_journal_tail_tolerated` (drop + truncate + clean post-recovery appends) |
| W7 | `respill_across_flushes_compacts` (superseding lines, later-wins, compaction) |
| W8 | `lost_backend_after_evict_is_spill_miss` |
| W9 | `tampered_pack_fails_cold_fetch` |
| W10 | ent `fault_in` hash-mismatch tests (PR #248) |
| barrier semantics | `flush_pending_is_the_durability_barrier`, `pending_coalesces_last_wins`, `fetch_serves_pending_before_flush` |
| W3 bounds | `pending_entry_cap_auto_flushes`, `pending_byte_cap_auto_flushes` (crossing a cap commits the batch; window never exceeds the cap) |
| W4 cleanup / GC | `gc_removes_orphaned_packs`, `gc_runs_on_reopen` (orphaned chunks deleted, live keys still fetch; open is the GC cadence) |
| pack format at scale | `large_pack_binary_search` (1000 entries after reopen) |
| round trip | `chunkstore_spill_roundtrip`, `reopen_finds_spilled_entries` |
