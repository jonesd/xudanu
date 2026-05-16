#!/bin/bash
# Run the xudanu test suite.
#
# Usage:
#   ./scripts/run-tests.sh           # all tests (lib + integration + TLS)
#   ./scripts/run-tests.sh lib       # lib tests only
#   ./scripts/run-tests.sh fast      # lib + integration (no TLS)

set -e

cd "$(dirname "$0")/.."

extract_counts() {
    grep -oE '[0-9]+ passed' | head -1 | grep -oE '[0-9]+' || echo "0"
}

echo "Building..."
cargo build --features server --bin xudanu-server 2>&1 | grep -E "^error" && exit 1

TOTAL=0

echo ""
echo "=== Lib tests ==="
OUTPUT=$(cargo test --lib --features server 2>&1)
echo "$OUTPUT" | tail -1
LIB=$(echo "$OUTPUT" | extract_counts)
TOTAL=$((TOTAL + LIB))

echo ""
echo "=== Integration tests ==="
OUTPUT=$(cargo test --test integration --features server 2>&1)
echo "$OUTPUT" | tail -1
INT=$(echo "$OUTPUT" | extract_counts)
TOTAL=$((TOTAL + INT))

if [ "${1:-all}" = "all" ]; then
    echo ""
    echo "=== TLS tests ==="
    OUTPUT=$(cargo test --test tls --features server 2>&1)
    echo "$OUTPUT" | tail -1
    TLS=$(echo "$OUTPUT" | extract_counts)
    TOTAL=$((TOTAL + TLS))
else
    TLS=0
fi

echo ""
echo "=== Summary ==="
printf "  Lib:           %5s tests\n" "$LIB"
printf "  Integration:   %5s tests\n" "$INT"
if [ "${1:-all}" = "all" ]; then
    printf "  TLS:           %5s tests\n" "$TLS"
fi
echo "  ---------------------"
printf "  Total:         %5s tests\n" "$TOTAL"
echo ""
echo "Done."
