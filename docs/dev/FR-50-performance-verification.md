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
| Per-keystroke edition rebuilds/clones | C pt 1 SHIPPED (transclusion-migration skip). C pt 2 DEFERRED — see decision above; reopen only on Phase 2 capacity data |
## A1/A3/A3b cleared (2026-08-30)

- **A1 annotations:** five armor tests; found the update loop took
  `intervals.first()` only — the exact mapping's split images (insert
  inside an annotation) DROPPED fragments; annotations shrank instead
  of growing. Fixed to the full hull. (Annotations had silently
  inherited finding 7's mis-mapping pre-fix-A; the positional mapping
  made them precise, which exposed the fragment-drop.)
- **A3 char_len:** O(entries) per call → O(1) from the cache tail.
  attr-q 256k 21ms → 14ms; insert exponents sub-linear at scale.
- **A3b carried-starts tail (found BY the O(1) read):** append-at-end
  inserts hit the carry cursor's out-of-bounds else-branch — appended
  entries got start 0 instead of the previous total. Pre-existing,
  masked while nothing read the tail. Fixed; append-at-end shape in
  the alignment armor.

Fourth armor session in a row where writing the tests found real
bugs: fragment-drop, tail-start. The method is the deliverable.

## Finding 9 (A6): nested transclusion resolution silently collapses (2026-08-30)

The A6 nesting fixture (chain of live Transclusion elements, depths
1/4/16/32) exposed a CORRECTNESS bug in the flagship feature:

`element_insert` pins placement integrity with a BLAKE3 hash of the
source's RAW excerpt (server.rs ~15655) — and raw text renders nested
transclusion elements as EMPTY. At resolve time, the source resolves
RECURSIVELY (expanded view); the hash mismatches; FR-26's revision-
retrieval path substitutes the pinned RAW slice with only an info
log. **Result: any transclusion whose source itself contains a
transclusion resolves to its placement-time raw text — nesting
beyond depth 1 cannot work through the standard placement path.**
The "32-level recursive resolution" feature is unreachable in
practice. Single-level transclusions are unaffected (raw == resolved)
— which is why every test and the demo shipped green.

Fix direction (needs design care — FR-26 is a security feature):
placement should hash the RESOLVED slice (recursive resolve at
placement), or the pin must be view-marked and resolution
view-aware. NOT hot-patched; next session opens with this.

Severity: correctness, flagship feature, exactly the audit's named
class — our modern addition (FR-26) breaking Gold-lineage resolution.

| **Link-span migration per edit** | **OPEN — finding 5, quadratic (1.3s/keystroke @ 16k with 32 links). Same disease as pre-fix-A spans; fix next session** |
| Three-way merge on divergent rewrites | OPEN — finding 6: garbled mix; fingerprint anchoring |
| build_merge_mapping soundness | EXPOSED — finding 7: can mis-map plain inserts; fix A removed its use from the keystroke path |
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

## Fix C pt 2 — DEFERRED (decision, 2026-08-29)

Keystroke cost after A/B/C1: ~1ms @ 16k, ~27ms @ 256k (book-sized) —
imperceptible for humans; large pastes are single deltas, not N
keystrokes. C pt 2 (persistent/window-shared entry structure to kill
the splice rebuild + clone churn, ~50% of remaining keystroke cost)
touches every cached_entries consumer (~68 sites) for a gain nobody
can feel at realistic document sizes. Complexity high, gain low:
deferred.

REOPEN CONDITION: Phase 2's capacity ramp shows p95 degradation at
realistic persona loads on large documents (>100k chars). The data
makes the case or closes it — not intuition.

## Finding 5: link-span migration is quadratic per keystroke (2026-08-29, harness rev 2)

Extrapolation from the earlier findings — "per-op work proportional
to total state, invisible in dimensions the fixture lacks" — pointed
at links: the flat fixture had none. Rev 2 adds 32 typed links spread
across the document:

| N | keystroke unlinked | keystroke +32 links |
|---|---|---|
| 1k | 75 µs | 11–18 ms (150–240×) |
| 4k | 234 µs | 107–193 ms |
| 16k | 634 µs | **1.1–1.3 s** (exponent ~1.6–1.7) |
| 64k+ | ~7 ms | unmeasurable |

Every edit re-migrates/revalidates link spans at cost proportional to
document size. This is the pre-fix-A disease in the link dimension —
solo typing on a linked document is quadratic. Fix next session:
locate the per-edit link migration path (likely same shape as span
provenance pre-A: whole-state rebuild per keystroke) and apply the
positional-mapping treatment. The bench guards the regression.

## Behavioral armor + findings 6 and 7 (2026-08-29)

Writing behavior tests for the perf fixes surfaced two more latent
issues (the tests are doing their job):

- **Finding 6 — three-way merge garbles divergent rewrites.** After an
  external rewrite, a session edit merges to a fingerprint-anchored
  mix ("external rewrite body" + session inserts → "exteronalMS
  rewrite body"). Pre-existing, not caused by fix B (which only
  selects the path). Same anchor-ambiguity root as finding 7.
- **Finding 7 — build_merge_mapping can mis-map trivially.** On real
  delta-path edition pairs, the fingerprint mapping has been observed
  mapping position 10 to 29 for a plain insert-at-10. It is not a
  sound oracle for equivalence testing, and pre-fix-A span migration
  inherited this hazard. Fix A's positional mapping (derived from the
  ops) eliminates the class; tests pin exact expectations instead.

Armor shipped (6 tests): positional mapping exact-expectations across
delta shapes; entry-crossing delete refinement; parallel cache
alignment through 25 fast-path splice edits (entries/starts/
fingerprints index-locked); has-transclusions flag tracks live
transclusions through edits (flag set widened to match the migration
filter: Transclusion + StructuralTransclusion, never Virtual —
Virtual is deliberately revision-pinned and skipped); origin-guard
fallback takes the merge path with session edits landing.

Suite: 3,225 green.

## Findings 8 and 8b: link spans never migrated on insert-only deltas (2026-08-30)

Written per rule 3 (armor for the finding-5 window guard), the tests
immediately exposed two latent CORRECTNESS bugs in span migration —
the heuristic-vs-exact class, severity-correctness:

- **Finding 8:** `map_span_through_delta` built its mapping from
  retained parts only. Insert-only deltas — `[Retain(k), Insert]`
  with no trailing retain, the common client shape — had all-zero
  retained offsets, hit the identity shortcut, and mapped every span
  to itself. **Links after a plain insert never shifted.** Fixed:
  the tail beyond the last op carries the final displacement.
- **Finding 8b:** multi-ended links homed to a single work appear
  once per end in `work_to_links`; the migration loop processed them
  twice — double-shifting spans the moment 8 was fixed (the two bugs
  masked each other). Fixed: dedupe.

Both shipped with the four armor tests that caught them (outside/
before/inside window behavior + shared-content unregister
preservation). Suite 3,229.

**The pattern, third occurrence:** writing the armor for a
performance fix found correctness bugs the functional suite never
saw. Rule 3 is now empirically load-bearing, not just doctrine.

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

## The standing audit plan (2026-08-29, after findings 1–7)

### Preamble: what this codebase is

Xudanu fits more independent inventions into one application than
almost any codebase: a CRDT, a three-way merge, cryptographic
provenance, an enfilade document model, tumblers, a content-reuse
index, compound resolution, federation, a wire protocol — each sound
alone, composed at scale. **We should expect, permanently, to
re-verify that we understand the code, that tests pin its behavior,
and that composition has not degraded the characteristics any one
layer was designed for.** One evening of measurement found seven
findings; the audit has begun, not ended.

### Where today's findings lived — and the suspicion rule

Every finding lived in Xudanu-original code; where we kept Gold's
architecture (space algebra, enfilade, crums) it held. But the
deepest bugs sat exactly at the SEAMS — our code operating ON Gold
structures (spans over editions, links over positions, queries over
entries). **Suspicion ranking:**

1. HIGHEST — Xudanu per-op handlers that touch Gold structures:
   anything iterating `cached_entries()`, rebuilding editions,
   walking spans/links per keystroke or per query
2. HIGH — Xudanu-only machinery under composition load: merge,
   CRDT convergence, materialization, provenance verification
3. MEDIUM — Gold-inherited concepts reimplemented by us with
   shortcuts (scans where Gold had indexes — backfollow, tumblers)
4. LOWEST — Gold structures themselves, exercised as designed

### The four bug shapes to grep for

1. **Per-op work ∝ total state** — a per-keystroke/per-query handler
   walking all entries, all links, all works (findings 1, 3, 5)
2. **Re-derivation over memoization** — re-hashing/recomputing what a
   cache or the ops already state (finding 2; fix A's lesson: the
   delta ops ARE the mapping)
3. **Whole-object rebuild where incremental exists** — clone/splice
   entire editions per op (finding 4, deferred; Gold edited in place)
4. **Heuristic where exact is available** — fingerprint content-
   matching where arithmetic/index gives truth (findings 6, 7) —
   these are CORRECTNESS hazards, worse than slow

### Unmeasured paths — ranked checklist

| # | Path | Suspected shape | Fixture needed |
|---|---|---|---|
| A1 | Annotation span migration | **DONE** — armor found fragment-drop; hull fix |
| A2 | backfollow register/unregister per link op | O(content) churn inside finding 5's loop | links fixture (exists) + profile |
| A3 | `char_len()` | **DONE** — O(1); also exposed A3b |
| A4 | WAL fsync per append | latency floor, not scaling | timing row |
| A5 | Checkpoint duration + blocking window | shape 3 at interval scale | checkpoint row (id lists exist) |
| A6 | resolve_inline_transclusions per read | shape 1 over nesting | nesting-depth fixture |
| A7 | provenance_ancestry + enrich per query | graph walk every 30s/client | multi-link fixture |
| A8 | multi-work servers, any scan left | shape 1 | multi-work fixture (owed) |
| A9 | Frontend: delta apply, editor re-render, overlay redraw at 100k+ | the new bottleneck | browser fixture |
| A10 | same_content O(N) per multi-session keystroke | residual from fix B | multi-session fixture |

### Standing governance (the rules that made today work)

1. **Expected-O is part of the interface** — a perf regression in
   order is a bug, blocked like a failing test; the bench runs per
   release and the matrix diffs.
2. **Profile before fixing; fix before shipping; fixture guards the
   regression.** No blind patches, no unmeasured claims.
3. **Every perf change ships behavioral armor** — tests pinning the
   exact semantics touched (today's six are the template), because
   "semantics unchanged" is a claim, not a fact, until pinned.
4. **Every new dimension of suspicion gets a fixture dimension** —
   the bug hides where the fixture doesn't look.
5. **Heuristic-vs-exact findings are severity-correctness, not
   severity-performance** (findings 6/7 outrank any µs).
6. **At the seams (our code on Gold structures), write the test
   first and expect the bug.**

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

## Results ledger (2026-08-30)

The registry this FR kept asking for now exists:
`docs/bench/results.jsonl` — append-only, committed, one JSONL
record per scenario per run (`xudanu-bench` appends automatically;
`xudanu-bench report` prints side-by-side engine/variant
comparisons, trends, and the XPI). Seeded with the recorded
findings-history (F1/F2/F5 pre/post-fix) and the FR-51 lattice
pre/post-LiveIndex runs, so look-back starts populated rather than
at zero.

- **Record**: ts/git/env/harness_rev/engine/variant/scenario/ref_n/
  points/steps/max_exp/us_at_ref/proj_1m. `env` distinguishes
  dev-mac (directional) from aws-official (governance comparisons).
- **XPI** (blended index): per engine+variant, geometric mean
  across scenarios of the projected 1M-char cost
  `mean(ins,del)@ref_n × (1M/ref_n)^max(0, max_exp)` — flat curves
  project unchanged, non-flat extrapolate their measured exponent.
  The penalty is explicit; per-scenario rows remain the regression
  surface, XPI is the headline.
- **Variants are the trade-off axis**: the same engine appears
  under multiple variants (otree/fingerprint vs posmap; lattice/
  hashmap-sort vs liveindex) — the ledger is how "which way of
  using the Gold infrastructure pays off where" gets decided with
  numbers instead of intuition.
- Harness contract unchanged (rev 2); scenario labels follow what
  rev-2 actually measures (otree edits at n≤16k run WITH 32 links —
  recorded as keystroke-linked-32, not keystroke-flat).
- Planned (P4 slice 2): the dual-engine run — one process, one
  traffic stream, O-tree and lattice shadow both timed per op;
  official numbers on the AWS instance.

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
