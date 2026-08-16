# PERF-PLAN: Gold Enfilade Performance Pipeline

Branch: `perf/gold-enfilade-pipeline`
Created: 2026-08-16
Companion doc: `FR-34-enfilade-native.md`

## Stage status

| Stage | Status | Commit | Measured result |
|---|---|---|---|
| S0 Instrumentation | **Done** | `0f79c8b` | baselines captured |
| S1 Non-blocking checkpoint | **Done** | `8135474` | sliced prepare; dispatch interleaves |
| S2 Incremental crums | **Done** | `f71e98a` | `with()` 363ms -> 9ms @100k; stress test unblocked |
| S6 Linear merge mapping | **Done** | `29e7743` | 6.4s -> ~100ms @9k (87x) |
| S8 Documentation (first pass) | **Done** | `a754ab7` | FR-34 updated; #90 closed |
| S4 Stable positions | **Done** | `af4b923` | gap allocator; audit pinned by tests; dense layouts load unchanged |
| S5 Arc tree sharing | **Done** | `527b656` | `with()` flat 1.8ms @100k; copy/combine O(1) |
| S5 Tree-native deltas | **Done** | `68513fa` + `e543f78` | steady 1-char edit: fragmented 100k 21->4.8ms, batched 9k 25->0.45ms |
| S8 Documentation (final) | **Done** | `201ffd6` | numbers above |
| S3 Splay activation | **Done — not justified** | `cb3bdb7` | honest measurement: no win (assembly already localizes); caught + fixed a latent splay content-loss bug |
| S7 Linear merge | **Done** | `7ef0707` | both-sides merge 207s -> 3.87s @100k (53x): patience alignment, set-based claiming, lockstep assembly |
| Gold comparison | **Done** | this commit | `GOLD-VS-XUDANU.md` |

**Pipeline complete.** All stages landed or honestly closed.

Investigation addendum (S6): the dominant per-edit cost was not the
combine fold but the fingerprint matcher rescanning used positions on
duplicate-heavy text. Fixed with provably-equivalent per-key cursors.

Stage 5 addendum: finer segmentation surfaced three latent merge bugs,
now fixed and regression-tested — conflict resolution dropped one side
of concurrent inserts (now: both sides emitted, identical changes
deduped), trailing inserts misanchored when the preceding entry was
not in an Unchanged run (now: nearest-anchor scan), and
EditionPayload::Text leaked the dense-layout assumption over the wire
(now: content-level check). One stash mishap during development was
recovered via `git fsck` unreachable-commit search — no work lost.

## Goal

Close the remaining performance gap to the original Gold enfilade design,
in a sequence of independently shippable stages. Each stage lands with
full test coverage (`cargo test --features server --lib`, clippy, fmt),
benchmarks where applicable, and an updated FR-34 work log entry.

The sequence is ordered so that each stage is a prerequisite or
amplifier for the next. Nothing below rewrites the CRDT model —
every stage is additive or localized.

## Investigation findings (2026-08-16)

### Issue #90 — checkpoint stalls edits

The disk-write phase is ALREADY off-thread
(`checkpoint_async` -> `spawn_blocking(checkpoint_persist)`,
shared.rs:226). The remaining stall is in the **prepare phase**,
which runs under the exclusive server write lock (`with_server`):

1. `materialize_all_pending()` — revises every dirty CRDT work
   (`revise_work` deep path per work) — server.rs:6583
2. `checkpoint_prepare()` — deep-clones every dirty
   `Work` (`ws.work.clone()`), serializes annotations, blob metas,
   content-address table, historical authors to JSON (`tag_json`),
   clones links/trails/compounds — server.rs:17297
3. While this lock is held, ALL dispatch blocks: writes wait on the
   write lock; reads wait too (RwLock is write-preferring).

Dirty tracking is already correct: `mark_dirty()` clears `chunk_ref`
and bumps `dirty_gen` (server.rs:158); commit installs refs only when
`dirty_gen` is unchanged (server.rs:17552). Incremental checkpointing
is therefore safe to build.

### Per-keystroke hidden costs (edit path)

- `build_merge_mapping` (three_way.rs:1122) — O(n) HashMap build over
  all entries, run (twice) on every `apply_text_delta`, mostly to
  migrate a handful of annotations.
- `OrglRoot::with`/`without` -> `from_loaf` -> `compute_crum()` — an
  O(n) full-tree BLAKE3 walk on EVERY single tree op, eagerly, even
  when nobody reads the crum (orgl.rs:884).
- `apply_text_delta_to_edition` (otree_crdt.rs:322) — flatten/walk/
  rebuild O(n), plus renumbering to contiguous 0..n positions.

### Phase I blocker

Positions are contiguous i64 (0..n). Any insertion renumbers every
following entry, so tree-native edits cannot beat O(n) until positions
become stable. The doc comment at edition.rs:651 already names this:
renumbering stays "until tumbler positions arrive".

## Stages

### Stage 0 — Instrumentation (half day)

- [ ] `tracing` timing spans around: checkpoint prepare lock hold,
      checkpoint persist, dispatch write-lock wait, apply_text_delta,
      build_merge_mapping.
- [ ] A repeatable micro-benchmark harness (tests mirroring
      `benchmark_*` style in three_way.rs/edition.rs) for:
      dispatch latency during concurrent checkpoint, per-edit cost at
      1k/10k/100k entries, tree-op cost on large editions.
- Purpose: every later stage cites before/after numbers from the same
  harness. No behavior change.

### Stage 1 — Non-blocking checkpoint (#90) (2-3 days)

Goal: dispatch never stalls behind checkpoint work.

- [ ] 1a. Move all `tag_json` serialization from `checkpoint_prepare`
      into `checkpoint_persist` (already off-thread). Prepare should
      only clone cheap Vecs/payloads, never serialize.
- [ ] 1b. Slice the lock: instead of one long `with_server` block that
      clones ALL dirty works, loop per work (or batches of K): acquire
      write lock, snapshot ONE dirty work + its dirty_gen, release,
      repeat. Edits interleave between slices. Same pattern for
      `materialize_all_pending`.
- [ ] 1c. Keep the existing safety rails: `checkpoint_in_flight`
      suppresses concurrent checkpoints; `dirty_gen` comparison at
      commit already discards stale snapshots; a work edited mid-
      snapshot simply stays dirty for the next checkpoint.
- [ ] 1d. Confirm crash-safety story unchanged: checkpoint atomicity
      comes from the root-chunk swap (root_chunk.rs), WAL truncate
      happens only at commit.
- [ ] 1e. Tests: (i) concurrent-edit-during-checkpoint test — all
      edits present after restore; (ii) latency guard test — dispatch
      during a large checkpoint completes within a small bound;
      (iii) existing tests 33095/33119/33138/33156 keep passing.
- Acceptance: benchmark shows no dispatch stall > a few ms attributable
  to checkpoint; issue #90 closable.

### Stage 2 — Incremental crums (Gold: bottom-up recomputation) (1-2 days)

Goal: tree ops cost O(log n), not O(n) hashing.

- [ ] 2a. Thread crum recomputation up the recursion in `Loaf::with`/
      `without`/`copy` instead of invalidating and re-walking the
      whole tree from `OrglRoot::from_loaf`. A changed leaf recomputes
      only the O(log n) crums on its path to the root. Same for
      `domain()` on the path.
- [ ] 2b. Property test: incremental crum == eager `compute_crum()`
      for arbitrary op sequences.
- [ ] 2c. Benchmark: 10k-entry edition, `with` before/after.
- This is how Gold maintained crums (OCs updated on edit). It is also
  the honesty prerequisite for Stage 5's O(k log n) claim.

### Stage 3 — Splay activation (finish Phase G) (2 days)

Goal: repeated edits to the same region hit shallow subtrees.

- [ ] 3a. Post-edit splay: after `apply_text_delta` (or materialize),
      splay `current_edition` around the edited region.
- [ ] 3b. Gate the splay (e.g. only after N edits within the same
      region) — splay restructures the tree, which changes crums and
      can cause Phase A merge fast-path misses. Measure before/after
      on `benchmark_merge_*`.
- [ ] 3c. Optional pre-merge splay around the crum-divergence region —
      only if 3a/3b measurements justify it.
- Acceptance: same-region repeated-edit benchmark improves; merge
  benchmarks do not regress.

### Stage 4 — Stable positions: tumbler/gap migration (4-6 days, riskiest)

Goal: an edit never renumbers unrelated entries. This is the Phase I
enabler and the deepest change in the pipeline.

Design: gap-based order maintenance over the existing i64 positions
(the pragmatic modern equivalent of Gold tumblers; XnRegion and the
wire protocol stay untouched).

- [ ] 4a. New `space/position_allocator.rs`: allocate a position
      between neighbors via midpoint; on local gap exhaustion re-space
      a window with doubled spacing (amortized O(1) relabels per
      insert — classic order-maintenance/list-labeling).
- [ ] 4b. Audit every contiguity assumption (rg: `entries.len() as
      i64`, `pos + 1`, `interval(0,`, `.0 + 1`): `from_entries`
      region build, three_way diff/assembly, blob char positions,
      transclusion entry ranges, wire positions, chunk serialization.
      Char-based APIs (annotations, blob positions) are cumulative
      over char_len — verify they never read raw positions.
- [ ] 4c. New Edition constructors that preserve given positions;
      delta path stops renumbering (bulk path keeps working — it just
      allocates positions instead of 0..n).
- [ ] 4d. Old data loads unchanged: contiguous 0..n is a valid (dense)
      layout; first insert into a dense neighborhood triggers the
      local window re-space.
- [ ] 4e. Bridge: allocated positions -> `XudanuTumbler` display
      addresses via the existing DocumentArrangement/Sequence bridge
      (Phase D/F machinery) so permalinks keep working.
- [ ] 4f. Property tests: strictly-increasing positions; untouched
      entries keep their positions across unrelated edits; re-space
      windows bounded; no i64 overflow under adversarial midpoint
      sequences.
- Acceptance: property test (4f) green; full suite green. This stage
  can sit behind a flag initially if any consumer resists migration.

### Stage 5 — Phase I: tree-native delta application (3-4 days)

Goal: single-char edit cost independent of document size.

- [ ] 5a. Fast path in `apply_text_delta_to_edition`: binary-search
      char offset -> entry over a cached char-start index; untouched
      prefix/suffix shared via `orgl.copy()`; touched region rebuilt
      entry-by-entry with `with`/`without` at allocated positions;
      coalesce applied to the dirty neighborhood only (same
      provenance/label rule as the bulk path).
- [ ] 5b. Batch fallback: if touched entries exceed a threshold
      (~20% of doc) use the bulk path (now also non-renumbering).
- [ ] 5c. Equivalence tests: fast path vs bulk path — same text AND
      same entry segmentation; property test over random delta
      sequences on random docs (mixed text/data elements, splits at
      all boundaries, unicode).
- [ ] 5d. Benchmarks: 1-char edit at 1k/10k/100k entries — flat
      before/after; update FR-34 performance table.
- Depends on Stage 2 (cheap tree ops) and Stage 4 (stable positions).

### Stage 6 — Incremental merge mapping (1 day)

Goal: kill the per-keystroke O(n) `build_merge_mapping`.

- [ ] 6a. For the no-merge path (base == current): construct the
      mapping directly from the delta ops in O(k) (identity outside
      the edit, shift inside).
- [ ] 6b. Cache mapping by (base crum) for the merged path if
      measurements warrant.
- [ ] 6c. Tests: annotation/link migration identical to today across
      the property-test delta corpus from 5c.

### Stage 7 — Structural merge assembly (finish Phase J) (2-3 days)

Goal: merges stop rebuilding from flattened Vecs.

- [ ] 7a. Replace flat-Vec assembly with: `copy()` shared subtrees +
      small replacement subtree for changed region + combine. With
      Stage 4's stable positions, `combine_overlapping` resolves
      per-position correctly; with Stage 2, the crum bookkeeping is
      cheap.
- [ ] 7b. Benchmarks: `benchmark_merge_both_sides_changed` approaches
      O(log n x k); fast-path hit rate reported.
- Depends on Stages 2+4.

### Stage 8 — Documentation (half day)

- [ ] Update FR-34: Phase I marked complete with honest numbers,
      work-log rows for every stage, refreshed performance and
      feature-activation tables.
- [ ] Close issue #90 with benchmark evidence.
- [ ] Update AGENTS.md strategic priorities if the perf backlog
      shifts.

## Sequencing and risk

```
S0 -> S1 (#90)  -- user-visible fix, ships first
S2              -- orgl internals, no API change
S3              -- optional, measurement-gated
S4 -> S5        -- the big migration; flag-guarded rollout
S6, S7          -- harvest the wins S2+S4 unlocked
S8              -- always
```

- S4 is the only stage that can change serialized behavior (positions
  become non-contiguous). The chunk format itself does not change
  (positions are already arbitrary i64 in the snapshot); the audit in
  4b is where the risk lives.
- Every stage must keep the full suite green; the pre-push hook's
  six checks remain the gate.
- If S4 stalls, S1-S3 + S6 still deliver real wins independently.

## Definition of done (pipeline)

- Dispatch latency independent of checkpoint activity (S1).
- Single tree op O(log n) incl. crum maintenance (S2).
- Single-char edit independent of document size (S5), demonstrated at
  1k/10k/100k entries.
- Both-sides-changed merge approaching Gold's O(log n x k) (S7).
- FR-34 performance table updated with measured numbers and test names.
