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
