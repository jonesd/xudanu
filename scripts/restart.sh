#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_RUST="$ROOT/original-code/xanadugold/src-rust"
WEB_APP="$ROOT/web/app"
BIN_DIR="$ROOT/target"
DATA_DIR="$SRC_RUST/data"

echo "==> Xudanu Development Server"
echo ""

# ── Stop existing processes ──────────────────────────────────────────────
echo "==> Stopping existing processes..."
lsof -ti :8080 2>/dev/null | xargs kill 2>/dev/null || true
lsof -ti :5173 2>/dev/null | xargs kill 2>/dev/null || true
sleep 1

# Verify ports are free
if lsof -ti :8080 >/dev/null 2>&1; then
  echo "    Port 8080 still in use — force killing..."
  lsof -ti :8080 2>/dev/null | xargs kill -9 2>/dev/null || true
  sleep 1
fi
if lsof -ti :5173 >/dev/null 2>&1; then
  echo "    Port 5173 still in use — force killing..."
  lsof -ti :5173 2>/dev/null | xargs kill -9 2>/dev/null || true
  sleep 1
fi

# ── Start backend ────────────────────────────────────────────────────────
BACKEND_BIN=""
if [ -x "$BIN_DIR/release/xudanu-server" ]; then
  BACKEND_BIN="$BIN_DIR/release/xudanu-server"
  echo "==> Starting backend (release binary, port 8080)..."
elif [ -x "$BIN_DIR/debug/xudanu-server" ]; then
  BACKEND_BIN="$BIN_DIR/debug/xudanu-server"
  echo "==> Starting backend (debug binary, port 8080)..."
else
  echo "==> No pre-built binary found. Building (this may take a while)..."
  (cd "$SRC_RUST" && cargo build --features server --bin xudanu-server)
  BACKEND_BIN="$BIN_DIR/debug/xudanu-server"
  echo "==> Starting backend (fresh build, port 8080)..."
fi

cd "$SRC_RUST"
"$BACKEND_BIN" run 127.0.0.1:8080 "$DATA_DIR" &
BACKEND_PID=$!
cd "$ROOT"

# Wait for backend to be ready
echo -n "==> Waiting for backend..."
ATTEMPTS=0
while [ $ATTEMPTS -lt 30 ]; do
  if curl -sf http://127.0.0.1:8080/health >/dev/null 2>&1; then
    echo " ready!"
    break
  fi
  echo -n "."
  sleep 1
  ATTEMPTS=$((ATTEMPTS + 1))
done
if [ $ATTEMPTS -eq 30 ]; then
  echo " FAILED!"
  echo "    Backend did not start. Check for errors above."
  kill $BACKEND_PID 2>/dev/null || true
  exit 1
fi

# ── Start frontend ───────────────────────────────────────────────────────
echo "==> Starting frontend (Vite dev server, port 5173)..."
(cd "$WEB_APP" && npm run dev) &
FRONTEND_PID=$!

# ── Cleanup on exit ──────────────────────────────────────────────────────
trap "echo ''; echo '==> Shutting down...'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit" INT TERM

echo ""
echo "==> Xudanu is running:"
echo "    Frontend:  http://localhost:5173/"
echo "    Backend:   http://localhost:8080/health"
echo "    Data dir:  $DATA_DIR"
echo ""
echo "    Press Ctrl+C to stop both servers"
echo ""

wait
