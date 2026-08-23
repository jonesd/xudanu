# FR-43: Capacity Estimation & Performance Regression Gate

Status: draft · Date: 2026-08-22
Builds on: ws_stress.rs (existing WS harness), #140 (attribution
honesty), #141 (lock-held IO — prerequisite), FR-41 (cross-server
ops under load), FR-42 (posture: personal vs team).

## Why

We fixed #140 only after a live false alarm; #141 froze a server
twice in one day. Both would have been caught by robots before
humans. Beyond bug gates: we don't know how many users a node
serves, where the first background mechanism degrades, or what our
per-op latency floor is. Before promoting Xudanu (video, beta
users), we need a capacity card AND a regression tripwire that runs
on every release.

## Principle

Capacity = min(user count where p95 keystroke round-trip > 150ms,
user count where any background mechanism fails or lies). A fast
server that poisons locks or cries "unsigned" is not serving users —
honesty alarms are first-class criteria, not observability niceties.

## Personas (robots as humans)

| Robot | Behavior | Exercises |
|---|---|---|
| Writer (70%) | 80–150wpm bursts, 2–8s pauses, backspace runs, mid-paragraph self-edits | delta path, save loop, attribution split/re-sign (#140 regression) |
| Editor | span selects, bullet/heading toggles, list typing | contenteditable churn, span splitting |
| Reader/Searcher (15%) | doc opens, network search q30–60s, remote views | fan-out cost, SSRF guards, rate-limit ceiling (~10/min/session) |
| Linker (10%) | typed links + mentions q1min, occasional multi-end | work_to_links growth, backlink notify, Connections queries |
| Transcluder (5%) | remote span pull q2–5min | cross-server IO (#141 regression — must not freeze) |

Scenarios: steady mix spread across documents; collab sprint (5
Writers in ONE doc — CRDT relay + materialization contention);
personal-instance profile (1 Writer, heavy read/transclude, long
soak); team profile (full mix).

## Instrumentation

- Per-op dispatch latency histograms (p50/p95/p99) from the existing
  `dispatch` tracing span → metrics sink
- Robot-measured keystroke send→ack (user-felt number)
- Background vitals: checkpoint duration/stall, WAL depth,
  attribution verify time, lock-wait depth, awareness relay fan-out,
  RSS
- Honesty tripwires: lock poisoning (any), "unsigned" on
  robot-owned spans (any), delta rejections, text resurrection,
  save-ack timeouts

## Method

1. Baseline: 1 of each robot, 10 min — floors + memory baseline
2. Sweep: N = 2/5/10/20/50 concurrent robots, 15 min/level, ramped
3. Collab spike: 5 Writers + mix in one doc, 15 min
4. Soak: highest clean N, 2–4h — leaks, WAL growth, decay
5. Chaos overlay at clean N: Node 2 kill/restart mid-run, 500ms
   peer delay, one flooding robot — alarms must stay silent

## Deliverables

- `xudanu-robots` CLI (benches/robots): `--writers N --readers N
  --duration S --profile team|personal --report json` driving a real
  server over real WS; persona cadences as pure testable functions
- Capacity card: "1 node serves ~N active users / M docs; first
  degradation at mechanism X; hard failure at Y" — per posture
- CI perf gate (see below)
- Perf FR backlog: first three mechanisms to fall over, ranked

## Release gate (the regression tripwire)

- **Every release** (release.yml, pre-tag): full sweep at N=10 +
  collab spike + 10-min soak, budgeted: p95 keystroke < 150ms, zero
  honesty alarms, RSS delta < threshold vs. last release's recorded
  baseline (stored as artifact, compared by job)
- **Every PR** (ci.yml): smoke tier — 5 robots, 90s, assertions on
  honesty alarms only (no latency budgets on shared runners beyond
  gross-regression sanity)
- Budget files in-repo (`perf/budgets.json`), ratcheted downward
  only by deliberate PR — the same discipline as the conformance
  matrix


## Long-lived results record

Performance history is a first-class artifact, checked into the repo
(not ephemeral CI logs):

- `perf/results/YYYY-MM-DD/<commit>[-label>/report.json` — raw run
  output, validated by `perf/report.schema.json` (schema is the
  contract: meta/latency/honesty/vitals/verdict; any nonzero
  honesty counter fails the run regardless of latency)
- `perf/results/YYYY-MM-DD/<commit>/summary.md` — human-readable
  narrative for that run (what degraded, why, links to issues)
- `perf/results/INDEX.md` — append-only comparison table (date,
  commit, runner, profile, N, p95, alarms, verdict); history is
  never edited
- `perf/budgets.json` — current release budgets, ratcheted only by
  deliberate PR with a results-run justification

Comparability rules: absolute numbers only compare within the same
runner (CI runner image or named local host, recorded in
meta.runner). Cross-machine comparisons use ratios against that
machine's own baseline run. CI archives the report as a workflow
artifact AND commits it back to perf/results in the release job, so
the record lives in git history with the code it measured.

## Sequencing

1. #141 (lock-held IO) — hard prerequisite; Transcluder robot
   otherwise re-freezes and every number is noise
2. Metrics sink + robot CLI (~1 day)
3. Baselines + sweep (~half day)
4. Soak + chaos, publish capacity card
5. Wire the two CI tiers; record initial budgets
