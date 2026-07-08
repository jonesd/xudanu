#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_RUST="$ROOT/original-code/xanadugold/src-rust"
WEB_APP="$ROOT/web/app"

echo "==> Stopping existing processes..."
lsof -ti :8080 2>/dev/null | xargs kill 2>/dev/null || true
lsof -ti :5173 2>/dev/null | xargs kill 2>/dev/null || true
sleep 1

echo "==> Starting backend (port 8080)..."
(cd "$SRC_RUST" && cargo run --features server --bin xudanu-server -- run 127.0.0.1:8080 data) &
BACKEND_PID=$!

echo "==> Starting frontend (port 5173)..."
(cd "$WEB_APP" && npm run dev) &
FRONTEND_PID=$!

trap "kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit" INT TERM

echo ""
echo "==> Xudanu running:"
echo "    Frontend:  http://localhost:5173/"
echo "    Backend:   http://localhost:8080/health"
echo "    Press Ctrl+C to stop"
echo ""

wait
