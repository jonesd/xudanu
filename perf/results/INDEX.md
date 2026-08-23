# Xudanu Performance Results — Long-Lived Record

Each run directory: `perf/results/YYYY-MM-DD/<git-short>[-<label>]/`
containing `report.json` (raw), `summary.md` (human), and optionally
`metrics.csv`. Index below is append-only — add a row per run, never
edit history. Budgets live in `perf/budgets.json` (ratchet-only).

Machine context matters: results are only comparable within the same
runner. CI runs record the GitHub runner image; local runs record
the host. Cross-machine comparisons use RATIOS vs. that machine's
baseline, not absolute numbers.

| Date | Commit | Runner | Profile | N | p95 keystroke | Alarms | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| 2026-08-22 | 3f26ddb | barton-m4-local | baseline | 3W/1R/1L | 1ms | 0 | PASS | floor established |
| 2026-08-22 | dce6b2f | barton-m4-local | sweep | 5W/2R/1L | 1ms | 1 err | PASS | |
| 2026-08-22 | dce6b2f | barton-m4-local | sweep | 10W/3R/2L | 1ms | 2 err | PASS | |
| 2026-08-22 | dce6b2f | barton-m4-local | sweep | 20W/5R/3L | 1ms | 4 err | PASS | |
| 2026-08-22 | dce6b2f | barton-m4-local | sweep | 50W/10R/5L | 1ms | 7 err | PASS | create p95 75ms |
| 2026-08-22 | dce6b2f | barton-m4-local | sweep | 100W/20R/10L | 1ms | 13 err | PASS | create p95 101ms — 20k deltas |
