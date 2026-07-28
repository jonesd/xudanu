#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/../../../target/debug/xudanu-server"

if [ ! -x "$BIN" ]; then
  echo "Error: xudanu-server not found at $BIN"
  echo "Run: cargo build --features server --bin xudanu-server"
  exit 1
fi

PORT1=8091
PORT2=8092
PORT3=8093

mkdir -p "$ROOT/data-node1" "$ROOT/data-node2" "$ROOT/data-node3"

echo "Starting 3-node cross-server test environment..."
echo "  Node Alpha: http://localhost:$PORT1"
echo "  Node Beta:  http://localhost:$PORT2"
echo "  Node Gamma: http://localhost:$PORT3"
echo ""

# Node 1
OLLAMA_BASE_URL=http://localhost:11434 OLLAMA_MODEL=qwen2.5:1.5b \
"$BIN" run 127.0.0.1:$PORT1 "$ROOT/data-node1" \
  --public-address "localhost:$PORT1" \
  --server-name "Node Alpha" \
  --server-description "Test node 1" \
  --allowed-origin "http://localhost:$PORT1" \
  --allowed-origin "http://localhost:$PORT2" \
  --allowed-origin "http://localhost:$PORT3" \
  --allowed-origin "http://127.0.0.1:$PORT1" \
  > /tmp/xudanu-node1.log 2>&1 &
PID1=$!
echo "  Node 1 PID: $PID1"

sleep 3

# Node 2
OLLAMA_BASE_URL=http://localhost:11434 OLLAMA_MODEL=qwen2.5:1.5b \
"$BIN" run 127.0.0.1:$PORT2 "$ROOT/data-node2" \
  --public-address "localhost:$PORT2" \
  --server-name "Node Beta" \
  --server-description "Test node 2" \
  --allowed-origin "http://localhost:$PORT1" \
  --allowed-origin "http://localhost:$PORT2" \
  --allowed-origin "http://localhost:$PORT3" \
  --allowed-origin "http://127.0.0.1:$PORT2" \
  > /tmp/xudanu-node2.log 2>&1 &
PID2=$!
echo "  Node 2 PID: $PID2"

sleep 3

# Node 3
OLLAMA_BASE_URL=http://localhost:11434 OLLAMA_MODEL=qwen2.5:1.5b \
"$BIN" run 127.0.0.1:$PORT3 "$ROOT/data-node3" \
  --public-address "localhost:$PORT3" \
  --server-name "Node Gamma" \
  --server-description "Test node 3" \
  --allowed-origin "http://localhost:$PORT1" \
  --allowed-origin "http://localhost:$PORT2" \
  --allowed-origin "http://localhost:$PORT3" \
  --allowed-origin "http://127.0.0.1:$PORT3" \
  > /tmp/xudanu-node3.log 2>&1 &
PID3=$!
echo "  Node 3 PID: $PID3"

echo ""
echo "All nodes started. Logs:"
echo "  Node 1: /tmp/xudanu-node1.log"
echo "  Node 2: /tmp/xudanu-node2.log"
echo "  Node 3: /tmp/xudanu-node3.log"
echo ""
echo "Press Ctrl+C to stop all nodes."

trap "kill $PID1 $PID2 $PID3 2>/dev/null; echo 'Nodes stopped.'" EXIT

wait
