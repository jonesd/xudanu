#!/bin/bash
# Restart xudanu server with security features on port 8080.
#
# Usage:
#   ./scripts/restart.sh                           # default: 8080, ./data, auto-detect web
#   ./scripts/restart.sh 9090 /tmp/my-data         # custom port and data dir
#   ./scripts/restart.sh 8080 /tmp/data ./web/dist # explicit static dir

set -e

cd "$(dirname "$0")/.."

PORT="${1:-8080}"
DATA_DIR="${2:-./data}"
STATIC_DIR="${3:-}"
ADDR="127.0.0.1:${PORT}"

if [ -z "$STATIC_DIR" ]; then
    for candidate in ../web/app/dist ../../web/app/dist ./web/app/dist; do
        if [ -d "$candidate" ]; then
            STATIC_DIR="$candidate"
            break
        fi
    done
fi

PIDS=$(lsof -ti:"${PORT}" 2>/dev/null | sort -u || true)
if [ -n "$PIDS" ]; then
    echo "Stopping existing server on ${PORT} (pids $(echo $PIDS | tr '\n' ' '))..."
    echo "$PIDS" | xargs kill 2>/dev/null || true
    for i in $(seq 1 10); do
        if ! lsof -ti:"${PORT}" 2>/dev/null; then
            break
        fi
        sleep 0.5
    done
    REMAINING=$(lsof -ti:"${PORT}" 2>/dev/null | sort -u || true)
    if [ -n "$REMAINING" ]; then
        echo "Force killing..."
        echo "$REMAINING" | xargs kill -9 2>/dev/null || true
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

STATIC_FLAGS=()
if [ -n "$STATIC_DIR" ] && [ -d "$STATIC_DIR" ]; then
    echo "  Web UI:           http://${ADDR} (static: ${STATIC_DIR})"
    STATIC_FLAGS=(--static-dir "$STATIC_DIR")
else
    echo "  Web UI:           http://${ADDR} (no static dir)"
fi

echo "  Security:         origin check + CSRF tokens"
echo ""

RUST_LOG=${RUST_LOG:-info} cargo run --features server --bin xudanu-server -- \
    run "$ADDR" "$DATA_DIR" \
    --allowed-origin "http://localhost:${PORT}" \
    --allowed-origin "http://127.0.0.1:${PORT}" \
    --csrf-token \
    "${STATIC_FLAGS[@]}"
