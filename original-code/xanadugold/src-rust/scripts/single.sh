#!/bin/bash
# Start a single non-federated xudanu server.
#
# Usage:
#   ./scripts/single.sh                    # default: 127.0.0.1:8080, in-memory
#   ./scripts/single.sh 9090               # custom port, in-memory
#   ./scripts/single.sh 9090 /tmp/my-data  # custom port, persistent data dir

set -e

cd "$(dirname "$0")/.."

ADDR="127.0.0.1:${1:-8080}"
DATA_DIR="${2:-}"

echo "Building xudanu-server..."
cargo build --features server --bin xudanu-server 2>/dev/null

PIDS=()
cleanup() {
    echo ""
    echo "Shutting down..."
    for pid in "${PIDS[@]}"; do
        kill "$pid" 2>/dev/null || true
    done
    wait 2>/dev/null
    echo "Done."
}
trap cleanup EXIT INT TERM

if [ -n "$DATA_DIR" ]; then
    if [ ! -d "$DATA_DIR" ]; then
        echo "Initializing data directory: $DATA_DIR"
        cargo run --features server --bin xudanu-server -- init "$DATA_DIR"
    fi
    echo "Starting xudanu server on $ADDR (data: $DATA_DIR)"
    cargo run --features server --bin xudanu-server -- run "$ADDR" "$DATA_DIR" &
else
    echo "Starting xudanu server on $ADDR (in-memory)"
    cargo run --features server --bin xudanu-server -- run "$ADDR" &
fi
PIDS+=($!)

echo ""
echo "  Client WebSocket: ws://$ADDR/xudanu"
echo "  Federation:       ws://$ADDR/federation (disabled)"
echo "  Health:           http://$ADDR/health"
echo "  Web UI:           http://$ADDR"
echo ""

wait
