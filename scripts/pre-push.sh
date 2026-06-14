#!/usr/bin/env bash
# Pre-push validation: runs the same checks as GitHub CI + Release
# Usage: ./scripts/pre-push.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_RUST="$REPO_ROOT/original-code/xanadugold/src-rust"
WEB_APP="$REPO_ROOT/web/app"

echo "=== 1/4 cargo fmt --check ==="
cd "$SRC_RUST"
if ! cargo fmt --check 2>&1; then
    echo ""
    echo "FAIL: Formatting issues found. Run 'cargo fmt' to fix."
    exit 1
fi
echo "OK"

echo ""
echo "=== 2/4 cargo clippy ==="
cargo clippy --features server -- -W clippy::all \
    -A clippy::large-enum-variant \
    -A clippy::manual-range-contains \
    -A clippy::borrowed-box \
    -A clippy::unnecessary-sort-by \
    -A clippy::indexing_slicing 2>&1
echo "OK (warnings above are informational, CI does not fail on them)"

echo ""
echo "=== 3/4 cargo test --features server --lib ==="
if ! cargo test --features server --lib 2>&1; then
    echo ""
    echo "FAIL: Tests failed."
    exit 1
fi

echo ""
echo "=== 4/4 tsc --noEmit (TypeScript type check) ==="
cd "$WEB_APP"
if ! npx tsc -b 2>&1; then
    echo ""
    echo "FAIL: TypeScript errors found. These WILL fail the release build."
    exit 1
fi

echo ""
echo "=== All checks passed. Safe to push. ==="
