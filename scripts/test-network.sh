#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/target/release/xudanu-server"
FRONTEND="$ROOT/web/app/dist"

# Clean up any previous test data
rm -rf /tmp/xudanu-test-node1 /tmp/xudanu-test-node2
mkdir -p /tmp/xudanu-test-node1 /tmp/xudanu-test-node2

echo "==> Starting Node 1 (Alice) on :8081..."
$BIN run 127.0.0.1:8081 /tmp/xudanu-test-node1 \
  --static-dir "$FRONTEND" \
  --server-name "Alice's Server" \
  --server-description "Test node 1" \
  --server-namespace-id 1 \
  --public-address 127.0.0.1:8081 \
  &
NODE1_PID=$!

echo "==> Starting Node 2 (Bob) on :8082..."
$BIN run 127.0.0.1:8082 /tmp/xudanu-test-node2 \
  --static-dir "$FRONTEND" \
  --server-name "Bob's Server" \
  --server-description "Test node 2" \
  --server-namespace-id 2 \
  --public-address 127.0.0.1:8082 \
  &
NODE2_PID=$!

trap "kill $NODE1_PID $NODE2_PID 2>/dev/null; exit" INT TERM

echo ""
echo "==> Waiting for servers to start..."
sleep 3

echo ""
echo "==> Testing well-known endpoints..."
echo ""
echo "--- Node 1 well-known ---"
curl -s http://127.0.0.1:8081/.well-known/xudanu-server.json | python3 -m json.tool 2>/dev/null || echo "FAILED"
echo ""
echo "--- Node 2 well-known ---"
curl -s http://127.0.0.1:8082/.well-known/xudanu-server.json | python3 -m json.tool 2>/dev/null || echo "FAILED"

echo ""
echo "==> Both servers running:"
echo "    Node 1: http://localhost:8081 (Alice, namespace_id=1)"
echo "    Node 2: http://localhost:8082 (Bob, namespace_id=2)"
echo ""
echo "==> Manual test steps:"
echo "    1. Open http://localhost:8081 — create identity, create document, write text, publish"
echo "    2. Open http://localhost:8082 — create identity, create document"
echo "    3. On Node 2: select text, click Link, choose 'Link to a remote server'"
echo "    4. Enter tumbler: \"127.0.0.1:8081\".5.3.0.0 (replace 5 with actual work ID)"
echo "    5. Get the content hash from: curl http://127.0.0.1:8081/api/public/work/0005"
echo "    6. Enter the hash in the remote link form"
echo "    7. Click 'Create Remote Link'"
echo "    8. The link should resolve and show Alice's content on Bob's server"
echo ""
echo "==> Press Ctrl+C to stop both servers"
echo ""

wait
