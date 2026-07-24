#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Stopping Xudanu servers..."

# ── Stop backend (port 8080) ──────────────────────────────────────────────
BACKEND_PID=$(lsof -ti :8080 2>/dev/null || true)
if [ -n "$BACKEND_PID" ]; then
  echo "==> Sending SIGTERM to backend (PID $BACKEND_PID)..."
  kill "$BACKEND_PID" 2>/dev/null || true

  # Wait up to 10 seconds for clean shutdown (checkpoint)
  for i in $(seq 1 10); do
    if ! kill -0 "$BACKEND_PID" 2>/dev/null; then
      echo "    Backend stopped cleanly."
      break
    fi
    sleep 1
  done

  # Force kill if still running
  if kill -0 "$BACKEND_PID" 2>/dev/null; then
    echo "    Backend did not stop in 10s — force killing..."
    kill -9 "$BACKEND_PID" 2>/dev/null || true
    sleep 1
  fi
else
  echo "    Backend not running."
fi

# ── Stop frontend (port 5173) ─────────────────────────────────────────────
FRONTEND_PID=$(lsof -ti :5173 2>/dev/null || true)
if [ -n "$FRONTEND_PID" ]; then
  echo "==> Stopping frontend (PID $FRONTEND_PID)..."
  kill "$FRONTEND_PID" 2>/dev/null || true
  sleep 1
  if kill -0 "$FRONTEND_PID" 2>/dev/null; then
    kill -9 "$FRONTEND_PID" 2>/dev/null || true
  fi
  echo "    Frontend stopped."
else
  echo "    Frontend not running."
fi

# ── Verify ports are free ─────────────────────────────────────────────────
if lsof -ti :8080 >/dev/null 2>&1; then
  echo "    WARNING: Port 8080 still in use."
else
  echo "    Port 8080 is free."
fi
if lsof -ti :5173 >/dev/null 2>&1; then
  echo "    WARNING: Port 5173 still in use."
else
  echo "    Port 5173 is free."
fi

echo ""
echo "==> All servers stopped."
