#!/bin/bash
# Restart xudanu server + Vite dev server.
#
# Usage:
#   ./scripts/restart.sh                           # default: 8080, ./data
#   ./scripts/restart.sh 9090 /tmp/my-data         # custom port and data dir
#   LAN=1 ./scripts/restart.sh                     # bind 0.0.0.0 for LAN access
#   NO_VITE=1 ./scripts/restart.sh                 # skip Vite dev server

set -e

cd "$(dirname "$0")/.."

PORT="${1:-8080}"
DATA_DIR="${2:-./data}"
VITE_PORT=5173
LOG_DIR="/tmp"

if [ "${LAN:-0}" = "1" ]; then
    ADDR="0.0.0.0:${PORT}"
else
    ADDR="127.0.0.1:${PORT}"
fi

VITE_DIR=""
for candidate in ../../../web/app ../../web/app ../web/app; do
    if [ -d "$candidate" ] && [ -f "$candidate/package.json" ]; then
        VITE_DIR="$(cd "$candidate" && pwd)"
        break
    fi
done

BINARY="target/debug/xudanu-server"
if [ ! -f "$BINARY" ]; then
    BINARY="../target/debug/xudanu-server"
fi
if [ ! -f "$BINARY" ]; then
    BINARY="../../target/debug/xudanu-server"
fi
if [ ! -f "$BINARY" ]; then
    BINARY="../../../target/debug/xudanu-server"
fi

# --- Stop anything running ---

stop_port() {
    local port=$1 name=$2
    local pids=$(lsof -ti:"${port}" 2>/dev/null | sort -u || true)
    if [ -z "$pids" ]; then
        echo "  ${name}: no process on :${port}"
        return
    fi
    echo "  ${name}: stopping (pids $(echo $pids | tr '\n' ' '))..."
    echo "$pids" | xargs kill 2>/dev/null || true
    for i in $(seq 1 40); do
        if ! lsof -ti:"${port}" 2>/dev/null; then break; fi
        sleep 0.5
    done
    local remaining=$(lsof -ti:"${port}" 2>/dev/null | sort -u || true)
    if [ -n "$remaining" ]; then
        echo "  ${name}: force killing..."
        echo "$remaining" | xargs kill -9 2>/dev/null || true
        sleep 1
    fi
    if lsof -ti:"${port}" 2>/dev/null; then
        echo "  ERROR: ${name} port :${port} still in use after kill"
        exit 1
    fi
    echo "  ${name}: stopped"
}

echo "Stopping existing processes..."
stop_port "${PORT}" "Server"
if [ "${NO_VITE:-0}" != "1" ]; then
    stop_port "${VITE_PORT}" "Vite"
fi

# --- Build ---

echo ""
echo "Building Rust server..."
cargo build --features server --bin xudanu-server 2>&1 | grep -E '^(error|   Compiling|   Finished)' || true

# Re-locate binary after build
for candidate in target/debug/xudanu-server ../target/debug/xudanu-server ../../target/debug/xudanu-server ../../../target/debug/xudanu-server; do
    if [ -f "$candidate" ]; then
        BINARY="$candidate"
        break
    fi
done

if [ ! -f "$BINARY" ]; then
    echo "ERROR: xudanu-server binary not found. Build may have failed."
    exit 1
fi

# --- Init data dir if needed ---

if [ ! -d "$DATA_DIR" ]; then
    echo "Initializing data directory: ${DATA_DIR}"
    "$BINARY" init "$DATA_DIR"
fi

if [ ! -d "$DATA_DIR" ]; then
    echo "ERROR: data directory ${DATA_DIR} does not exist after init"
    exit 1
fi

# --- Start server ---

ORIGIN_FLAGS=(
    --allowed-origin "http://localhost:${PORT}"
    --allowed-origin "http://127.0.0.1:${PORT}"
    --allowed-origin "http://localhost:${VITE_PORT}"
    --allowed-origin "http://127.0.0.1:${VITE_PORT}"
)

if [ "${LAN:-0}" = "1" ]; then
    LAN_IP=$(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')
    if [ -n "$LAN_IP" ]; then
        ORIGIN_FLAGS+=(--allowed-origin "http://${LAN_IP}:${PORT}")
    fi
fi

echo ""
echo "Starting server..."
RUST_LOG=${RUST_LOG:-info} nohup "$BINARY" \
    run "$ADDR" "$DATA_DIR" \
    "${ORIGIN_FLAGS[@]}" \
    --csrf-token \
    > "${LOG_DIR}/xudanu-server.log" 2>&1 &
SRV_PID=$!

# Wait for server to actually be listening
echo -n "  Waiting for server on :${PORT}"
OK=0
for i in $(seq 1 30); do
    if ! kill -0 "$SRV_PID" 2>/dev/null; then
        echo ""
        echo "ERROR: server crashed. Last log lines:"
        tail -20 "${LOG_DIR}/xudanu-server.log"
        exit 1
    fi
    if lsof -ti:"${PORT}" 2>/dev/null | head -1 | grep -q .; then
        OK=1
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

if [ "$OK" -ne 1 ]; then
    echo "ERROR: server did not start listening on :${PORT} within 30s"
    echo "  PID $SRV_PID is still running. Log:"
    tail -20 "${LOG_DIR}/xudanu-server.log"
    kill "$SRV_PID" 2>/dev/null || true
    exit 1
fi

echo "  Server:           http://${ADDR} (pid ${SRV_PID})"
echo "  Health:           http://${ADDR}/health"
echo "  Server log:       ${LOG_DIR}/xudanu-server.log"

# --- Start Vite ---

VITE_PID=""

cleanup() {
    echo ""
    echo "Shutting down..."
    if [ -n "$VITE_PID" ] && kill -0 "$VITE_PID" 2>/dev/null; then
        kill "$VITE_PID" 2>/dev/null || true
        echo "  Vite stopped"
    fi
    if kill -0 "$SRV_PID" 2>/dev/null; then
        echo "  Server: waiting for checkpoint..."
        kill "$SRV_PID" 2>/dev/null || true
        for i in $(seq 1 30); do
            if ! kill -0 "$SRV_PID" 2>/dev/null; then break; fi
            sleep 0.5
        done
        if kill -0 "$SRV_PID" 2>/dev/null; then
            echo "  Server: force killing (checkpoint may not have completed)"
            kill -9 "$SRV_PID" 2>/dev/null || true
        fi
        echo "  Server stopped"
    fi
    exit 0
}
trap cleanup SIGINT SIGTERM

if [ "${NO_VITE:-0}" != "1" ] && [ -n "$VITE_DIR" ]; then
    echo ""
    echo "Starting Vite dev server..."
    nohup npm run dev --prefix "$VITE_DIR" -- --port "${VITE_PORT}" \
        > "${LOG_DIR}/xudanu-vite.log" 2>&1 &
    VITE_PID=$!

    echo -n "  Waiting for Vite on :${VITE_PORT}"
    VITE_OK=0
    for i in $(seq 1 30); do
        if ! kill -0 "$VITE_PID" 2>/dev/null; then
            echo ""
            echo "ERROR: Vite crashed. Log:"
            tail -20 "${LOG_DIR}/xudanu-vite.log"
            kill "$SRV_PID" 2>/dev/null || true
            exit 1
        fi
        if lsof -ti:"${VITE_PORT}" 2>/dev/null | head -1 | grep -q .; then
            VITE_OK=1
            break
        fi
        echo -n "."
        sleep 1
    done
    echo ""

    if [ "$VITE_OK" -ne 1 ]; then
        echo "WARNING: Vite did not start on :${VITE_PORT} within 30s"
        echo "  Falling back to server-only mode on http://${ADDR}"
        echo "  Vite log: ${LOG_DIR}/xudanu-vite.log"
        VITE_PID=""
    else
        echo "  Vite:             http://localhost:${VITE_PORT} (pid ${VITE_PID})"
        echo "  Vite log:         ${LOG_DIR}/xudanu-vite.log"
    fi
fi

# --- Summary ---

echo ""
echo "==========================================="
if [ -n "$VITE_PID" ]; then
    echo "  Open: http://localhost:${VITE_PORT}"
else
    echo "  Open: http://${ADDR}"
fi
echo "  Logs: ${LOG_DIR}/xudanu-server.log"
if [ -n "$VITE_PID" ]; then
    echo "        ${LOG_DIR}/xudanu-vite.log"
fi
echo "  Ctrl+C to stop"
echo "==========================================="
echo ""

wait
