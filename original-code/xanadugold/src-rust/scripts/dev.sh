#!/bin/bash
# Start full dev environment: Rust server (auto-rebuild on changes) + Vite dev server.
#
# Usage:
#   ./scripts/dev.sh                     # default: server 8080, vite 5173
#   ./scripts/dev.sh 9090                # custom server port
#
# Rust changes: auto-rebuild and restart via cargo-watch.
# Web changes:  hot-reloaded instantly by Vite.
#
# Press Ctrl+C to stop both.

set -e

cd "$(dirname "$0")/.."

PORT="${1:-8080}"
DATA_DIR="${2:-./data}"
ADDR="127.0.0.1:${PORT}"
WEB_DIR="../../../web/app"

STATIC_DIR=""
for candidate in ../../../web/app/dist ../web/app/dist ../../web/app/dist ./web/app/dist; do
    if [ -d "$candidate" ]; then
        STATIC_DIR="$candidate"
        break
    fi
done

STATIC_FLAGS=""
if [ -n "$STATIC_DIR" ]; then
    STATIC_FLAGS="--static-dir $STATIC_DIR"
fi

cleanup() {
    echo ""
    echo "Stopping..."
    [ -n "$WATCH_PID" ] && kill "$WATCH_PID" 2>/dev/null || true
    [ -n "$VITE_PID" ] && kill "$VITE_PID" 2>/dev/null || true
    PID=$(lsof -ti:"${PORT}" 2>/dev/null || true)
    if [ -n "$PID" ]; then
        echo "  Server: sending SIGTERM, waiting for checkpoint..."
        kill "$PID" 2>/dev/null || true
        for i in $(seq 1 30); do
            if ! kill -0 "$PID" 2>/dev/null; then break; fi
            sleep 0.5
        done
        if kill -0 "$PID" 2>/dev/null; then
            echo "  Server: force killing (checkpoint may not have completed)"
            kill -9 "$PID" 2>/dev/null || true
        fi
    fi
    exit 0
}
trap cleanup INT TERM

PIDS=$(lsof -ti:"${PORT}" 2>/dev/null || true)
if [ -n "$PIDS" ]; then
    echo "Stopping existing server(s) on ${PORT}..."
    echo "$PIDS" | xargs kill 2>/dev/null || true
fi

echo "Waiting for port ${PORT} to be free..."
for i in $(seq 1 20); do
    PIDS=$(lsof -ti:"${PORT}" 2>/dev/null || true)
    if [ -z "$PIDS" ]; then
        break
    fi
    if [ "$i" -eq 10 ]; then
        echo "Force killing..."
        echo "$PIDS" | xargs kill -9 2>/dev/null || true
    fi
    sleep 0.5
done

PIDS=$(lsof -ti:"${PORT}" 2>/dev/null || true)
if [ -n "$PIDS" ]; then
    echo "ERROR: Port ${PORT} still in use after 10s. Aborting."
    exit 1
fi
echo "Port ${PORT} is free."

if [ ! -d "$DATA_DIR" ]; then
    echo "Initializing data directory: ${DATA_DIR}"
    cargo run --features server --bin xudanu-server -- init "$DATA_DIR"
fi

echo "Starting Rust server with auto-rebuild (cargo-watch)..."
echo "  Watching src/ for changes..."
cargo watch -x "run --features server --bin xudanu-server -- run $ADDR $DATA_DIR --otree-crdt $STATIC_FLAGS --allowed-origin http://localhost:5173 --allowed-origin http://localhost:8080 --allowed-origin http://127.0.0.1:8080" &
WATCH_PID=$!

sleep 3

echo "Starting Vite dev server..."
(cd "$WEB_DIR" && npx vite --host) &
VITE_PID=$!

echo ""
echo "  Rust server:  http://${ADDR}  (auto-rebuild on src/ changes)"
echo "  Vite (web):   http://localhost:5173  (hot reload)"
echo "  WebSocket:    ws://${ADDR}/xudanu"
echo "  O-tree CRDT:  enabled"
echo ""
echo "  Press Ctrl+C to stop both."
echo ""

wait
