# FR-50: Performance & Complexity Verification

Status: draft · Date: 2026-08-29
Builds on: FR-43 (capacity robots — session-sweep tooling, honesty
alarms), FR-34 (enfilade-native: subtree crums, chunk diff, splay,
tumbler bridge — the operations whose complexity we verify), FR-36
(chunk GC safety — soak interactions), bench.test.ts (frontend),
transport_sweep (all 294 wire ops).

## Why

The web app reads as a basic notepad; the interesting machinery is
all behind it. FR-43 exercised one dimension (concurrent sessions,
N=5..130, p95 1ms at 20k deltas — all pass). But no run has ever:

1. **Verified the Big-O claims.** FR-34's design promises specific
   complexities (subtree-crum equality O(1), chunk diff proportional
   to change, splay amortized, migration linear in edits). These are
   asserted in prose, never measured as curves. If an operation has
   silently degraded to O(N²) at scale, nothing today would notice.
2. **Found the capacity cliff.** "How many users / how large a
   document / how deep a compound before the system falls over on a
   small instance" has no number. The demo runs on the smallest AWS
   box — the answer matters for every self-hoster.
3. **Soaked the lifecycle.** Hours of create/edit/archive/GC churn
   expose leaks and WAL/GC pathologies that minutes never will.

## Principle

**Expected-O is part of the interface.** Each core operation carries
a documented complexity (from the FR-34 series). A performance run
is a *test*: measured curve vs expected order, verdict recorded. A
regression in order is a bug, not a statistic. Runs are scripted and
repeatable — the same harness produces the capacity matrix every
release.

**Never on the demo server.** xudanu.com is a public artefact with
real identities. Performance work runs (a) locally during harness
development, (b) on a dedicated throwaway instance of the same
hardware class for official numbers.

## Mechanism inventory and expected complexity (Phase 0 output)

| Operation | Expected | Source |
|---|---|---|
| Subtree crum equality | O(1) per node pair | FR-34 (BLAKE3 Merkle) |
| Chunk-level diff | O(changed), not O(document) | FR-34 |
| O-tree insert/delete at position | O(log N) amortized | space algebra design |
| Splay exposure at Edition level | amortized O(log N) | FR-34 |
| Span migration over a delta | O(spans hit), not O(all spans) | migration design |
| attribution_query (plain) | O(spans in range) | server.rs |
| attribution_query_resolved | O(spans + nesting) | 2026-08-29 materialization fix |
| Inline transclusion resolution | O(depth × spans), depth ≤ 32 | compound design |
| Tumbler resolve (doc position ↔ tumbler) | O(depth) | FR-34 Phase D–F |
| Checkpoint / restore | O(chunks dirty), not O(state) | FR-36/design backlog note |
| WAL append | O(1); replay O(log) | persist design |

Phase 0 verifies this table against the code and design docs — the
table itself is the assertion baseline. Where docs and code
disagree, that's a finding.

## First findings (2026-08-29, harness rev 0, in-process release build, M-series Mac)

| N | build µs | ins-mid µs | del-mid µs | attr-q µs |
|---|---|---|---|---|
| 1k | 6,351 | 47,860 | 50,364 | 411 |
| 4k | 19,212 | 675,814 | 716,435 | 853 |
| 16k | 54,534 | 11,634,572 | 11,075,968 | 4,828 |
| 64k | 333,177 | (capped) | (capped) | 19,423 |
| 256k | 1,264,083 | (capped) | (capped) | 78,611 |

Empirical exponents: build ~1.0 (linear, expected); **insert/delete
~2.0 (QUADRATIC — 11.6 s per single-character edit at 16k)**;
attribution ~1.0 with a single span where O(spans) was expected.

**Profile (sample, 16k insert):** hot path is
`crdt_apply_text_delta → OtreeCrdtManager::apply_text_delta →
try_migrate_span_multi → Mapping::of_region → XnRegion::union/intersect`
with heavy per-element allocation. Root cause: **three whole-document
operations per keystroke** — `same_content` comparison (otree_crdt.rs
:1197), `build_merge_mapping` for span migration (:1203), and a second
`build_merge_mapping` for `last_author_mapping` (:1224) — all O(N)+
with fingerprint matching, for a one-character positional edit in the
common solo-typist case.

**Fix plan:** (A) positional fast-path — when base≡current and the
delta is positional, the mapping is arithmetic (`Mapping::Simple`);
compose `last_author_mapping` by shift instead of rebuild. Expected:
keystroke → O(spans straddling the edit). (B) epoch/cache the
same-content check. (C) the Gold-shaped endgame: spans hang off the
O-tree nodes, edits update affected spans bottom-up with crums
(FR-34's design). The bench is the regression test for all three.

The capacity robots (FR-43) never caught this: their documents stayed
small. Any future capacity claim must pair session count with
document size.

## After fixes A + B (2026-08-29, harness rev 1)

| N | ins-mid µs | del-mid µs | vs pre-fix A |
|---|---|---|---|
| 1k | 75 | 54 | 638× / 942× |
| 4k | 234 | 135 | 2,890× / 5,310× |
| 16k | 634 | 340 | 18,350× / 32,580× |
| 64k | 5,558 | 3,986 | (was unmeasurable) |
| 256k | 31,086 | 25,664 | (was unmeasurable) |

Insert/delete exponent: 2.0 → ~1.0-1.3 (linear-ish; the residual is
the per-keystroke edition rebuilds and whole-doc clones —
apply_text_delta_to_edition, merged/pending clones — i.e. fix C
territory: structural, not surgical). At 256k chars a keystroke now
costs ~31ms — usable; pre-fix it extrapolated to ~48 minutes.

Fix B (O(1) base-is-current origin marker) banked a further ~20%;
same_content remains the multi-session fallback.

**Still open (finding 2):** attribution_query ~O(N) (73ms @ 256k,
polled every 30s per open client). Next target.

## Finding 2 fixed (2026-08-29)

`attribution_query` read three O(N) paths per call — `all_entries()`
cloned the entry Vec, a cumulative HashMap rebuilt, and each span's
fingerprints were re-hashed from text. The edition's memoized cache
(entries, char-starts) now also carries per-entry fingerprints, built
once per edition state and carried across the CRDT fast-path splices;
the query indexes the parallel slices by binary search.

| N | attr-q before | attr-q after |
|---|---|---|
| 256k | 73 ms | 21 ms (3.5×) |

Residual is per-query signature verification over the pathological
single-whole-document span (imported content shape); real many-span
documents verify small lists. Full verification-result caching per
edition state is the follow-up if the import case matters.

## All findings status

| Finding | Status |
|---|---|
| Quadratic keystroke | FIXED (A+B): 11.6s → 634µs @ 16k |
| Attribution O(N) | FIXED: 73ms → 21ms @ 256k |
| Per-keystroke edition rebuilds/clones | PART 1 SHIPPED: O(1) transclusion-migration skip (scales with work count). REMAINING — fix C pt 2: assemble_fast_result's full-Vec splice rebuild (~35% of keystroke per profile) + destructor churn (~14%) + late-function clones. Needs persistent/window-shared entry structure — a design change, not a patch |
| Verification caching per edition state | OPEN — matters only for whole-doc spans |

## Fix C part 1 (2026-08-29)

Profile of the post-A+B keystroke: ~35% assembling the fast-path
result (full entry-Vec rebuild of Arc clones), ~14% edition
destructors (same churn on free), ~10% `migrate_inline_transclusions
_for_delta` — which scanned EVERY entry of EVERY work per keystroke.
Shipped the O(1) skip (has_transclusions flag in the edition cache).
Effect scales with work count, not document size — the single-work
bench fixture cannot show it; a multi-work fixture variant is owed to
the harness.

## Phase 1 — micro-harness (Big-O curves)

A `xudanu-bench` binary (or `xudanu-robots bench` subcommand):

- For each operation: sizes N ∈ {1k, 4k, 16k, 64k, 256k} (documents)
  and depth ∈ {1, 4, 8, 16, 32} (compound nesting), K repetitions,
  warm caches, wall-clock + instruction-approximate timing.
- Curve fitting: compute the empirical exponent between consecutive
  sizes (log(t₂/t₁)/log(N₂/N₁)); verdict per operation:
  **matches / degrades / fails** vs the table.
- Output: `perf-matrix.json` (machine) + a rendered table (human).
- Key traps to design around: first-touch effects (warmup runs),
  checkpoint pauses polluting timings (quiesce between phases),
  and CRDT materialization laziness (force materialize before
  timing, separately measure materialization itself).

## Phase 2 — capacity load (the cliff)

Extend `xudanu-robots`:

- Persona mix: typists (CRDT deltas at human and burst rates),
  readers (attribution/text-range queries), linkers (link create +
  backlink queries), compound builders (transclusion place +
  resolve), and an archiver (create/edit/archive churn).
- Ramp: step N up until p95 response exceeds 250ms for 5 minutes, or
  RSS exceeds a stated budget (small instance: 1 GB), or checkpoint
  stall exceeds 5s. Record the N where each threshold trips — that
  is the capacity number per persona mix.
- Report: p50/p95/p99 per op, throughput, RSS curve over time,
  checkpoint durations, WAL size, GC reaps — one table per mix.

## Phase 3 — soak

- 4–24h runs of the mixed personas + churn on the dedicated
  instance; watch RSS slope (leaks), WAL growth vs checkpoint
  cadence, honesty alarms, attribution ledger growth rate.
- Success: flat RSS within budget, no alarm, ledger growth
  proportional to real writes.

## Phase 4 — standing methodology

- Scripts + thresholds committed (`scripts/perf/`); official numbers
  re-taken per release on the dedicated instance; perf-matrix.json
  diffed release-over-release — an order regression blocks release
  the way a failing test does.
- Optional CI smoke: one small-N run of the micro-harness with
  generous thresholds, so gross regressions surface in PRs.

## Success criteria

- Every row of the mechanism table has a measured curve and a
  verdict; no "fails".
- A stated capacity number: "N mixed users / document size X /
  nesting depth D on a t3-small-class instance at p95 < 250ms".
- Soak of ≥ 4h flat-RSS.
- The harness is one command, documented, and was actually run for
  the v1.9.0 release notes.

## Open questions

- Do we publish the capacity matrix publicly (self-hoster sizing
  guide)? Recommendation: yes — it is exactly what r/selfhosted
  readers ask.
- Criterion (the Rust bench framework) vs hand-rolled timing:
  criterion gives statistics but fights the server's async runtime;
  recommendation: hand-rolled inside the robots binary, criterion
  only for pure library-level ops (edition, space algebra).
- Where warm/cold cache boundaries matter most (checkpoint restore
  after restart = the real self-hoster experience) — restore-time
  benchmarks deserve their own row.
