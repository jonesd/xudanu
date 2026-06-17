#!/usr/bin/env bash
# Pre-push validation: mirrors exactly what GitHub CI + Release workflows check.
# Matches .github/workflows/ci.yml and .github/workflows/release.yml.
#
# Usage:
#   ./scripts/pre-push.sh           # full check (all tests + frontend build)
#   ./scripts/pre-push.sh --quick   # skip integration tests and vite build
#   ./scripts/pre-push.sh --release # also verify --release compiles
set -euo pipefail

QUICK=false
RELEASE=false
for arg in "$@"; do
    case "$arg" in
        --quick)   QUICK=true ;;
        --release) RELEASE=true ;;
    esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_RUST="$REPO_ROOT/original-code/xanadugold/src-rust"
WEB_APP="$REPO_ROOT/web/app"

PASSED=0; SKIPPED=0

step() { echo ""; echo "=== $1 ==="; }
ok()   { echo "OK"; PASSED=$((PASSED + 1)); }
skip() { echo "SKIP: $1"; SKIPPED=$((SKIPPED + 1)); }

# ── 1. cargo fmt --check (ci.yml: fmt job) ──────────────────────────────────
step "1/6. cargo fmt --check"
cd "$SRC_RUST"
if cargo fmt --check 2>&1; then ok; else
    echo ""; echo "FAIL: Run 'cargo fmt' to fix."; exit 1
fi

# ── 2. cargo clippy (ci.yml: clippy job) ────────────────────────────────────
step "2/6. cargo clippy --features server"
if cargo clippy --features server -- -W clippy::all \
    -A clippy::large-enum-variant \
    -A clippy::manual-range-contains \
    -A clippy::borrowed-box \
    -A clippy::unnecessary-sort-by \
    -A clippy::indexing_slicing 2>&1; then ok
else
    echo ""; echo "FAIL: Clippy errors."; exit 1
fi
echo "(warnings above are informational — CI does not fail on them)"

# ── 3. cargo test --lib (ci.yml + release.yml) ──────────────────────────────
step "3/6. cargo test --features server --lib"
if cargo test --features server --lib 2>&1; then ok; else
    echo ""; echo "FAIL: Lib tests failed."; exit 1
fi

# ── 4. cargo test --test integration (stricter than CI) ─────────────────────
if [ "$QUICK" = true ]; then
    step "4/6. cargo test --features server --test integration"
    skip "(--quick mode)"
else
    step "4/6. cargo test --features server --test integration"
    if cargo test --features server --test integration 2>&1; then ok; else
        echo ""; echo "FAIL: Integration tests failed."; exit 1
    fi
fi

# ── 5. TypeScript type check (release.yml: tsc -b) ───────────────────────────
step "5/6. TypeScript type check (tsc -b)"
cd "$WEB_APP"
if npx tsc -b 2>&1; then ok; else
    echo ""; echo "FAIL: TypeScript errors. These WILL fail the release build."; exit 1
fi

# ── 6. Frontend build (release.yml: vite build) ─────────────────────────────
if [ "$QUICK" = true ]; then
    step "6/6. Frontend build (vite build)"
    skip "(--quick mode)"
else
    step "6/6. Frontend build (vite build)"
    if npx vite build 2>&1; then ok; else
        echo ""; echo "FAIL: Vite build failed. This WILL fail the release build."; exit 1
    fi
fi

# ── Optional: Release build check ───────────────────────────────────────────
if [ "$RELEASE" = true ]; then
    step "7. cargo build --release --features server"
    cd "$SRC_RUST"
    if cargo build --release --features server 2>&1; then ok; else
        echo ""; echo "FAIL: Release build failed."; exit 1
    fi
fi

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  PASSED: $PASSED   SKIPPED: $SKIPPED"
echo "=========================================="
echo "  All checks passed. Safe to push."
