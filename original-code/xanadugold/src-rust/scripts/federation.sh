#!/bin/bash
# Start a federated xudanu cluster with N servers.
#
# Usage:
#   ./scripts/federation.sh            # 3 servers on ports 8081-8083
#   ./scripts/federation.sh 5          # 5 servers on ports 8081-8085
#   ./scripts/federation.sh 3 /tmp/fed # custom data base dir
#
# Each server knows about all other servers as federation peers.
# No maximum on cluster size — any number of servers can join.
#
# Architecture:
#   Clients connect to exactly one server (pinned, no roaming).
#   Servers replicate content to each other via /federation WebSocket.
#   Grab/release is per-server (no cross-server locking).

set -e

cd "$(dirname "$0")/.."

N="${1:-3}"
DATA_BASE="${2:-/tmp/xudanu-federation}"

if [ "$N" -lt 2 ]; then
    echo "Error: need at least 2 servers for federation"
    exit 1
fi

echo "Building xudanu-server..."
cargo build --features server --bin xudanu-server 2>/dev/null

BASE_PORT=8081
PIDS=()
DIRS=()

cleanup() {
    echo ""
    echo "Shutting down $N servers..."
    for pid in "${PIDS[@]}"; do
        kill "$pid" 2>/dev/null || true
    done
    for pid in "${PIDS[@]}"; do
        wait "$pid" 2>/dev/null || true
    done
    echo "Done."
}
trap cleanup EXIT INT TERM

for i in $(seq 1 "$N"); do
    PORT=$((BASE_PORT + i - 1))
    DIR="$DATA_BASE/node-$i"
    DIRS+=("$DIR")

    if [ ! -f "$DIR/server.json" ]; then
        echo "Initializing node $i -> $DIR"
        cargo run --features server --bin xudanu-server -- init "$DIR" 2>/dev/null
    fi
done

echo ""
echo "Starting $N federated servers..."
echo ""

for i in $(seq 1 "$N"); do
    PORT=$((BASE_PORT + i - 1))
    DIR="${DIRS[$((i - 1))]}"
    ADDR="127.0.0.1:$PORT"

    PEER_FLAGS=""
    for j in $(seq 1 "$N"); do
        if [ "$j" -ne "$i" ]; then
            PEER_PORT=$((BASE_PORT + j - 1))
            PEER_FLAGS="$PEER_FLAGS --peer 127.0.0.1:$PEER_PORT"
        fi
    done

    echo "  Node $i: $ADDR (peers: $((N - 1)))"
    cargo run --features server --bin xudanu-server -- run "$ADDR" "$DIR" $PEER_FLAGS 2>&1 | sed "s/^/[node-$i] /" &
    PIDS+=($!)
done

echo ""
echo "=== Federation cluster ready ==="
echo ""
for i in $(seq 1 "$N"); do
    PORT=$((BASE_PORT + i - 1))
    echo "  Node $i:"
    echo "    Client WS:  ws://127.0.0.1:$PORT/xudanu"
    echo "    Federation:  ws://127.0.0.1:$PORT/federation"
    echo "    Health:      http://127.0.0.1:$PORT/health"
    echo "    Web UI:      http://127.0.0.1:$PORT"
    echo ""
done
echo "Press Ctrl+C to stop all servers."
echo ""

wait
