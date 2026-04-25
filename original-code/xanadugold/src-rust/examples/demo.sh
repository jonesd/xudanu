#!/bin/bash
# xudanu demo script
# Starts the server, runs through a complete demo, then shuts down.

set -e

CLI="cargo run --features server --bin xudanu-cli --"
SERVER="cargo run --features server --bin xudanu-server --"
ADDR="127.0.0.1:18080"
URL="ws://$ADDR"

echo "=== xudanu Demo ==="
echo ""

# Build first
echo "Building..."
cargo build --features server --bins 2>/dev/null

# Start server in background
echo "Starting server on $ADDR..."
$SERVER run $ADDR &
SERVER_PID=$!
sleep 2

cleanup() {
    echo ""
    echo "Shutting down server..."
    kill $SERVER_PID 2>/dev/null || true
    wait $SERVER_PID 2>/dev/null || true
    echo "Done."
}
trap cleanup EXIT

echo "=== 1. Connect and login ==="
$CLI $URL login

echo ""
echo "=== 2. Create two documents ==="
DOC1=$($CLI $URL create-work "Hello from document one!")
echo "  Document 1 ID: $DOC1"

DOC2=$($CLI $URL create-work "Hello from document two!")
echo "  Document 2 ID: $DOC2"

echo ""
echo "=== 3. List all works ==="
$CLI $URL list-works

echo ""
echo "=== 4. Edit document 1 (grab -> revise -> release) ==="
$CLI $URL grab $DOC1
$CLI $URL revise $DOC1 "Updated: Hello from document one, revised!"
$CLI $URL release $DOC1

echo ""
echo "=== 5. View revision history ==="
$CLI $URL history $DOC1
$CLI $URL fetch-revision $DOC1 0

echo ""
echo "=== 6. Create a link between documents ==="
LINK=$($CLI $URL create-link $DOC1 $DOC2)
echo "  Link ID: $LINK"

echo ""
echo "=== 7. List links for document 1 ==="
$CLI $URL list-links $DOC1

echo ""
echo "=== 8. Get link details ==="
$CLI $URL get-link $LINK

echo ""
echo "=== 9. Create a club ==="
CLUB=$($CLI $URL club-create editors)
echo "  Club ID: $CLUB"

echo ""
echo "=== 10. List clubs ==="
$CLI $URL club-list

echo ""
echo "=== 11. Server info ==="
$CLI $URL info

echo ""
echo "=== Demo complete! ==="
echo "The xudanu server is still running at $ADDR"
echo "Open http://$ADDR in a browser for the web UI."
echo "Press Ctrl+C to stop the server."
wait $SERVER_PID
