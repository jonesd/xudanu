# FR-167: Spill Residency — Policy, Cadence, and Async Wiring

**Status:** design draft
**Created:** 2026-11-08
**Revised:** 2026-11-08 — policy set to K-generation retention + entry-count ceiling (was budget+age; moved to considered alternatives)
**Depends on:** FR-166 (spill mechanism + the eviction invariant), FR-142 (storage durability), FR-36 (chunk GC safety)
**Siblings:** FR-76 (epoch-structured enfilade — persistence over time; this FR decides memory residency of the live tree)
**Author:** David Jones

---

## The problem

FR-166 landed the mechanism: evict (1.9 µs), barrier (~10 µs amortized),
fault (10 µs warm), GC at open, caps bounding the crash window. Nothing
in the running server uses it. The server keeps every branch of every
loaded work in RAM for its lifetime; the entire spill machinery sits
idle behind an unset backend. Residency is the policy + wiring that
makes eviction a behavior the live server has:

1. **Who calls evict** — the policy: K-generation retention, the
   entry-count ceiling, and the never-evict set.
2. **When flush happens** — the cadence: checkpoint boundaries, off-lock.
3. **How faults ride tokio** — the wiring: what may block, what may not.
4. **The invariant proof** — FR-166's named requirement: every evictable
   branch must have a re-derivation path. This doc discharges it.

Everything below is grounded in code as of `d6e6ef79`; file:line refs
are live anchors, to be re-verified at implementation time.

## Ground truth from the code

- **One store, not per-work.** The residency target is a single
  server-wide `BranchStore`: `Server.backfollow` → `BackfollowEngine.dagwood`
  (backfollow.rs:182) → `DagWood.branches` (dagwood.rs:23). One policy
  point, one spill directory, one flush.
- **Sharing model.** `Server` lives in `Arc<RwLock<Server>>`
  (`ServerHandle.inner`, shared.rs:197). Dispatch is `with_server`
  (write lock) / `with_server_ref` (read). Health uses `try_read`.
  Any `&mut BranchStore` work happens under the *write* lock.
- **The proven async pattern.** `checkpoint_async` (shared.rs:328):
  sliced short lock holds (batches of 4–8), `spawn_blocking` for the
  fsync-heavy persist, an atomic in-flight guard against overlap, and
  an off-lock background GC sweep (`gc_snapshot` → `spawn_blocking` →
  `gc_sweep`). Residency rides this shape; it does not invent a new one.
- **Cadence hooks that already exist.** Autosave tick 5 s (drains
  lattice, prunes sessions), checkpoint on op-count/self-heal triggers,
  OTS anchor 60 s, log checkpoints 60 s (xudanu-server.rs:1612–1659).
- **Edits touch the dagwood.** `work_revise` flows through
  `backfollow.update_work_with_parent` (server.rs:5696) — so the
  branches an editing session touches are exactly the hot ones. Each
  edit stamps the current generation, protecting them by
  construction; the editing hot path and the eviction candidate set
  are near-disjoint.
- **The re-derivation record exists.** Checkpoints persist the engine:
  `backfollow_snapshot_hash` in the manifest (server.rs:30830), restore
  imports the snapshot + replays the recorder journal (server.rs:17150+
  and the checkpoint→restore→backfollow test at 49826). The works the
  dagwood derives from are, as always, canonical chunks + WAL.

## The invariant proof (FR-166's gate)

**Claim:** at a committed checkpoint boundary, every dagwood branch is
re-derivable independently of the spill store.

Evidence chain for a branch `b` of work `w`:

1. `w`'s editions are in the record (chunks + per-op-fsync WAL).
2. The checkpoint persists the backfollow snapshot + recorder journal
   to the chunk store; restore rebuilds the engine from it, or from
   the works themselves when the snapshot is absent.
3. `b` is a function of (1) and (2) — the dagwood is derived state,
   never a source.

**Mechanical gate (Stage A):** a branch is evictable only if its work
was included in the last *committed* checkpoint — i.e. the work's
`dirty_gen` at eviction time equals its committed gen (the checkpoint
machinery already tracks per-work `dirty_gen`; shared.rs uses it to
discard stale snapshots). Dirty-since-checkpoint works are not
evictable, full stop. This makes the proof a comparison, not an
argument. WAL-replay reasoning could widen the evictable set (a dirty
branch is still re-derivable — the WAL is the record), but Stage A
does not need it; noted under open questions.

**Standing consequence:** if the gate is violated — some evicted
branch lacks a derivation path — spill GC flips to data-loss class and
FR-166's parked audit-coverage item becomes mandatory. The gate is the
contract that keeps `gc()` tidiness-loss.

## Policy

**K-generation retention with an entry-count ceiling.** Resident =
touched this generation or the last K−1. The generation counter is the
checkpoint sequence (one number, already maintained); a touch stamps
the current generation into the entry.

- `last_touch_gen: u32` per entry — stamped on `get_mut`,
  `materialize`, `install_branch`, and by
  `backfollow.update_work_with_parent` for edited works. A fault-in
  also stamps: a branch faulted back cannot be re-evicted for K
  generations — retention carries its own hysteresis; no 90%-style
  band needed.
- `--spill-retain-gens K` (default 2): a branch is evictable when its
  `last_touch_gen` is K or more generations old AND its work passed
  the dirty-gen gate. No ordering, no age arithmetic — one comparison.
- `--spill-max-resident N` (absent/0 = residency off; default off):
  hard ceiling in *entries*, not bytes. Branches are broadly similar
  in magnitude, and counting entries needs no per-entry size
  accounting — the budget+age variant's `size_bytes` question dies
  here. Under the ceiling, evict oldest-generation-first.
- **Never evicts:** branches of works in `pending_crdt_work_ids()` or
  mid-`materialize`, and any work currently being checkpointed.
- Batch cap `--spill-evict-batch` (default 128): at 1.9 µs/evict one
  batch is ~250 µs of work under one write-lock hold — sliced like
  `MATERIALIZE_BATCH`, interleaving with dispatch between batches.

What this buys over the finer alternatives: no byte accounting, no LRU
sort, no idle-threshold tuning. What it costs: the ceiling is coarser
(entries, not MB), and a genuinely cold corpus re-read pays one fault
burst per K-generation idle period (R7) whose fault locality is
time-batched packs at their worst (the subtree-locality packs item in
FR-166 Phase 2 is the eventual fix). Budget+age remains the Stage C
refinement for operators who want MB-denominated control (considered
alternatives, below).

## Cadence

**Evict: at the generation boundary — post-checkpoint-commit.** The
evict pass runs inside the checkpoint flow after commit returns (and
after the materialize phases, so R6 sequencing holds by construction):
sliced batches under `with_server`, oldest generations first, until
nothing older than K remains. All map work, no fsync — spill admission
is the ~2 µs insert. The autosave tick (5 s) carries only a ceiling
check — one counter compare; only when exceeded does it run the same
sliced pass between checkpoints. GC of orphaned packs stays at open
(FR-166, landed) — no runtime GC in Stage A.

**Flush: at checkpoint commit, two-phase, off-lock.** The naive
`flush_spill()` under one write hold puts two fsyncs on the dispatch
path — the exact stall `checkpoint_async` exists to avoid. Split the
barrier:

1. *Take* (under write lock): drain `pending` (keys + bytes) out of
   the spill store — a memcpy, no I/O.
2. *Write* (on `spawn_blocking`, no lock): pack chunk write + fsync,
   journal lines + fsync — the existing `flush_pending` body.
3. *Install* (under write lock): move locators into the live index.

This needs a small API addition to `ChunkStoreSpill` (prepare/complete
split of `flush_pending`); the crash windows it introduces are all
W-ledger equivalents (crash after take, before install = the pack is
written but unindexed, or pending lost entirely → `SpillMiss` →
re-derive; never wrong data — see the R-ledger below). Ordering
within the checkpoint: commit → evict pass → flush → the existing
background GC sweep spawn. Commit first keeps the record durable
before the cache claims anything; flushing right after the evict pass
lands that generation's admissions in one barrier (their W3 window is
bounded at a single generation); sweep-last is hygiene (the sweep
reads the canonical store, not the spill dir, but keep it tidy
anyway). Shutdown: explicit flush beside the final checkpoint;
`Drop` remains the best-effort backstop.

**Fault: synchronous under the dispatch write lock, Stage A.** A warm
fault is 10 µs — noise. A cold fault (pack read + BLAKE3 + decode)
is ~100 µs–few ms on SSD; the retention gate makes it rare by
construction (we only evicted what nothing touched for K
generations). Stage A
accepts this tail with measurement (below) rather than building
speculative machinery. If p99 dispatch regresses: Stage B pre-faults
known-heavy op key sets on the blocking pool before taking the lock
(the `gc_snapshot` → sweep shape). Faults hold the write lock through
I/O — bounded, rare, measured — never the read lock, never two at
once (`&mut` ownership serializes them already).

## The IsStub audit (correctness centerpiece)

Once eviction is live, every `&self`-path into `BranchStore` can meet
a stub — and the store answers honestly: `get()` returns typed
`BranchError::IsStub` (branch.rs:455–470), never silent wrong data.
The audit obligation: enumerate every consumer of `branches()` /
`&BranchStore` (dagwood.rs TraceView, trace-position machinery,
profile/tooling walkers) and classify each:

- **(a) fault-routed** — rewrite through `get_mut`/`materialize` under
  `&mut` (the store-wide write lock is already held by dispatch);
- **(b) stub-tolerant** — skip stubs and mark the result partial
  (trace views over cold corpora may legitimately report "N branches
  resident"); or
- **(c) never-evict** — pin the branch class (e.g. roots the walker
  always needs).

Deliverable in the implementation PR: the audited table, plus a
debug-mode walker assert that a full pass with eviction enabled
reaches zero unhandled `IsStub`. `BranchStore::len()` counts stubs and
materialized alike — residency metrics must report the split
(materialized / stubbed / resident vs ceiling / last-pass evictions /
faults warm:cold), surfaced through the existing metrics snapshot path.

## Residency failure ledger (new windows the policy introduces)

| # | Window | Outcome |
|---|---|---|
| R1 | evict a branch mid-traversal | prevented: traversals stamp the generation; candidates need K-old stamps |
| R2 | cold fault under write lock | bounded stall (~ms), rare by the retention gate; measured, Stage B pre-fault if p99 regresses |
| R3 | two-phase flush crash between take and install | pending lost or pack orphaned → `SpillMiss` → re-derive (W3/W4 equivalents); never wrong data |
| R4 | fault/evict ping-pong | self-hysteresis: fault-in stamps the current generation, so a faulted-back branch is unevictable for K generations |
| R5 | spill dir wiped/lost while serving | mass `SpillMiss` → re-derive storm; backpressure: bounded concurrent re-derivations, ops queue behind them; cost measured in the bench |
| R6 | evict pass vs checkpoint materialize overlap | sequenced: the pass runs post-commit, after materialization; the tick's ceiling check skips `pending_crdt_work_ids()` works |
| R7 | generation cliff — cold corpus re-read | one burst of cold faults (R5 shape); the accepted cost of the policy, paid once per K-generation idle period; measured in the bench |

## Measurement plan (extends FR-166's P7 bench)

- evict-pass slice hold time (target < 500 µs per 128-batch)
- cold-fault dispatch p99 delta with residency on vs off
- two-phase flush: lock occupancy vs the one-hold baseline
- R7 generation cliff: time to re-warm a fully evicted generation on
  re-read (the policy's accepted cost; feeds any future K adaptation)
- R5 disaster case: spill dir wiped under 5k-branch corpus — time to
  full service recovery, and whether re-derivation backpressure holds
- steady-state: faults warm:cold ratio at default K=2
  (target: cold faults ≈ 0 per hour at demo load)

## Rollout

- **Stage A** — flag-gated, off by default. `--spill-max-resident`
  wires `ChunkStoreSpill` at `<data>/spill` into the dagwood store at
  server construction (`set_spill`), runs the evict pass at
  checkpoint commit (two-phase flush after it), and carries the
  ceiling check on the autosave tick. Dogfood on a demo server with
  the ceiling set.
- **Stage B** — default-on for the demo-network scripts; pre-fault for
  heavy ops if measurements demand; consider WAL-reasoning to widen
  the evictable set past the committed-checkpoint gate.
- **Stage C** — per-work byte budgets (the budget+age refinement,
  considered alternatives below); subtree-locality packs (FR-166
  Phase 2 folds in here — and becomes the fix for generational fault
  scatter, R7); audit coverage revisit if any of this ever makes
  spilled state load-bearing.

## Considered alternatives

Condensed option map. The chosen line is the simplest thing that
keeps the `&mut` ownership model and rides patterns the server
already has (sliced locks, `spawn_blocking`, checkpoint cadence);
heavier variants are staged behind measurement triggers rather than
rejected on principle.

| Axis | Chosen | Rejected / deferred (reason) |
|---|---|---|
| Unit | server-wide store | per-work stores (N backends and journals; Stage C per-work budgets get the win cheaper); per-session (the server has no work open/close lifecycle to hook) |
| Trigger | K-generation retention + entry ceiling | budget+age LRU (finer control, but costs `size_bytes` accounting, an LRU sort, and idle-threshold tuning — Stage C refinement); clock-idle only (no RAM bound; untestable, clock-jump-prone); pure LRU (fault/evict ping-pong); plain generational *without* retention (the cliffs: no hard ceiling, evicts without memory pressure, sharp thrash boundary at the generation edge, policy hitched to checkpoint heuristics); explicit/admin-only (no behavior until operators exist); size-first (evicts the substantial branches first) |
| Cadence | commit → evict → two-phase flush → sweep | one-phase flush under the lock (two fsyncs on the dispatch path); cap-driven-only flush (the strongest rejected contender — zero cadence code since the landed caps already auto-flush, but flush moments become uncorrelated with record durability); reset-at-checkpoint instead of flushing (the cache would survive exactly one interval — the degenerate proof the spill layer is optional); decoupled periodic tick (no gain over cap-driven) |
| Fault | synchronous under the write lock, Stage A | pre-fault batches on the blocking pool (Stage B if p99 regresses); BranchStore behind its own lock or an actor (restructures ent ownership away from `&mut`-serializes-everything; two-lock reasoning everywhere); fail-cold + background fault + client retry (availability hiccup on the user path of a system whose point is instant following) |
| IsStub | audited call sites + debug assert | compiler-checked stub-aware view type (open question 1); fault-all-before-walk (mass faults per walk; tolerable only for rare offline walkers); class pinning (sticky pins quietly shrink the evictable set) |

## Open questions

1. `branches()` ergonomics: keep raw `&BranchStore` + audited call
   sites, or introduce a stub-aware view type the compiler can check.
2. Federation sync walks all works — confirm it routes through
   fault-tolerant paths (R5 interaction).
3. Should K adapt from the observed cold-fault rate (raise K when
   cliffs recur), or stay operator-set?
4. Generation counter source: the checkpoint sequence number, or a
   dedicated u64 on Server — the former is one less counter, the
   latter decouples residency from any future checkpoint-scheme change.
5. Does anything besides backfollow construct `DagWood` instances at
   runtime (tooling, tests aside)? If yes, each needs its own policy
   decision or explicit never-evict.
