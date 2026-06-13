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

STATIC_DIR=""
for candidate in ../../../web/app/dist ../web/app/dist ../../web/app/dist ./web/app/dist; do
    if [ -d "$candidate" ]; then
        STATIC_DIR="$candidate"
        break
    fi
done

echo "Building xudanu-server..."
cargo build --features server --bin xudanu-server 2>/dev/null

PIDS=()
cleanup() {
    echo ""
    echo "Shutting down..."
    for pid in "${PIDS[@]}"; do
        kill "$pid" 2>/dev/null || true
    done
    echo "  Waiting for checkpoint..."
    for pid in "${PIDS[@]}"; do
        for i in $(seq 1 30); do
            if ! kill -0 "$pid" 2>/dev/null; then break; fi
            sleep 0.5
        done
        if kill -0 "$pid" 2>/dev/null; then
            echo "  Force killing pid $pid (checkpoint may not have completed)"
            kill -9 "$pid" 2>/dev/null || true
        fi
    done
    echo "Done."
}
trap cleanup EXIT INT TERM

STATIC_FLAGS=()
if [ -n "$STATIC_DIR" ]; then
    STATIC_FLAGS=(--static-dir "$STATIC_DIR")
fi

if [ -n "$DATA_DIR" ]; then
    if [ ! -d "$DATA_DIR" ]; then
        echo "Initializing data directory: $DATA_DIR"
        cargo run --features server --bin xudanu-server -- init "$DATA_DIR"
    fi
    echo "Starting xudanu server on $ADDR (data: $DATA_DIR)"
    cargo run --features server --bin xudanu-server -- run "$ADDR" "$DATA_DIR" --otree-crdt "${STATIC_FLAGS[@]}" &
else
    echo "Starting xudanu server on $ADDR (in-memory)"
    cargo run --features server --bin xudanu-server -- run "$ADDR" --otree-crdt "${STATIC_FLAGS[@]}" &
fi
PIDS+=($!)

echo ""
echo "  Client WebSocket: ws://$ADDR/xudanu"
echo "  Federation:       ws://$ADDR/federation (disabled)"
echo "  Health:           http://$ADDR/health"
echo "  Web UI:           http://$ADDR"
echo "  O-tree CRDT:      enabled"
if [ -n "$STATIC_DIR" ]; then
    echo "  Static dir:       $STATIC_DIR"
fi
echo ""

wait
