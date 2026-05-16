#!/bin/bash
# Restart xudanu server with security features on port 8080.
#
# Usage:
#   ./scripts/restart.sh                     # default: 8080, ./data
#   ./scripts/restart.sh 9090 /tmp/my-data   # custom port and data dir

set -e

cd "$(dirname "$0")/.."

PORT="${1:-8080}"
DATA_DIR="${2:-./data}"
ADDR="127.0.0.1:${PORT}"

PID=$(lsof -ti:"${PORT}" 2>/dev/null || true)
if [ -n "$PID" ]; then
    echo "Stopping existing server on ${PORT} (pid ${PID})..."
    kill "$PID" 2>/dev/null || true
    sleep 1
    PID2=$(lsof -ti:"${PORT}" 2>/dev/null || true)
    if [ -n "$PID2" ]; then
        echo "Force killing..."
        kill -9 "$PID2" 2>/dev/null || true
        sleep 1
    fi
    echo "Stopped."
else
    echo "No existing server on ${PORT}."
fi

if [ ! -d "$DATA_DIR" ]; then
    echo "Initializing data directory: ${DATA_DIR}"
    cargo run --features server --bin xudanu-server -- init "$DATA_DIR"
fi

echo "Building..."
cargo build --features server --bin xudanu-server 2>/dev/null

echo "Starting xudanu server on ${ADDR} (data: ${DATA_DIR})"
echo ""
echo "  Client WebSocket: ws://${ADDR}/xudanu"
echo "  Health:           http://${ADDR}/health"
echo "  Web UI:           http://${ADDR}"
echo "  Security:         origin check + CSRF tokens"
echo ""

cargo run --features server --bin xudanu-server -- \
    run "$ADDR" "$DATA_DIR" \
    --allowed-origin "http://localhost:${PORT}" \
    --csrf-token
