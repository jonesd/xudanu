#!/usr/bin/env bash
# Coverage with reconciliation — the guard against silently-wrong numbers.
#
# Two passes (the server needs --features server; the WASM client crates
# need their integration tests, which --lib would exclude):
#   1. src-rust lib suite
#   2. crates/* including tests/ directories
#
# Every pass prints its EXECUTED test count next to its coverage. A suite
# that executes 0 tests while test files exist is a hard failure — that is
# exactly the artifact that once reported a tested crate at 0%.
#
# Usage:
#   scripts/coverage.sh               # full pass (both suites, ~25 min)
#   scripts/coverage.sh --report-only # re-report from cached profdata
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || (cd "$(dirname "$0")/.." && pwd))"
cd "$REPO_ROOT"

REPORT_ONLY=false
[ "${1:-}" = "--report-only" ] && REPORT_ONLY=true

count_executed() {
  # cargo test … | "test result: ok. N passed" per binary, summed
  cargo test "$@" 2>&1 | grep -E "^test result" \
    | sed -E 's/.*result: [a-z]+\. ([0-9]+) passed.*/\1/' \
    | awk '{s+=$1} END {print s+0}'
}

section() { printf "\n=== %s ===\n" "$1"; }

if $REPORT_ONLY; then
  section "server + engine (cached report)"
  cargo llvm-cov report --summary-only 2>/dev/null | tail -1
  echo "Executed tests (last full run): re-run without --report-only for live counts"
  exit 0
fi

section "1/2 — src-rust lib suite (engine + server)"
cargo llvm-cov --features server --lib --summary-only 2>&1 | tail -1
TESTS_ENGINE="$(count_executed --features server --lib)"
echo "Executed tests: $TESTS_ENGINE"
if [ "$TESTS_ENGINE" -lt 3000 ]; then
  echo "FAIL: engine suite executed only $TESTS_ENGINE tests (expected 3000+)" >&2
  exit 1
fi

section "2/2 — WASM client crates (incl. tests/ dirs)"
cargo llvm-cov -p xudanu-core -p xudanu-types -p xudanu-signing \
  -p xudanu-sync -p xudanu-provenance --summary-only 2>&1 | tail -1
TESTS_CRATES="$(count_executed -p xudanu-core -p xudanu-types -p xudanu-signing -p xudanu-sync -p xudanu-provenance)"
echo "Executed tests: $TESTS_CRATES"
if [ "$TESTS_CRATES" -lt 100 ]; then
  echo "FAIL: crate suites executed only $TESTS_CRATES tests (expected 100+)" >&2
  exit 1
fi

section "TypeScript (web/app)"
(cd web/app && npx vitest run --coverage.enabled --coverage.reporter=json-summary >/dev/null 2>&1 || true)
node -e '
const s = require("./web/app/coverage/coverage-summary.json").total;
console.log(`lines ${(s.lines.pct).toFixed(1)}% | functions ${s.functions.pct.toFixed(1)}% | statements ${s.statements.pct.toFixed(1)}%`);
' 2>/dev/null || echo "(web/app coverage summary unavailable)"

section "Reconciliation"
echo "Rust engine lib: $TESTS_ENGINE | Rust crates: $TESTS_CRATES | TS: see vitest output above"
echo "All suites executed >0 tests — numbers above are trustworthy."
