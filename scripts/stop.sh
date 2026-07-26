#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Stopping Xudanu servers..."

# ── Stop backend (port 8080) ──────────────────────────────────────────────
BACKEND_PIDS=$(lsof -ti :8080 2>/dev/null || true)
if [ -n "$BACKEND_PIDS" ]; then
  echo "==> Sending SIGTERM to backend (PIDs: $(echo "$BACKEND_PIDS" | tr '\n' ' '))..."
  echo "$BACKEND_PIDS" | xargs kill 2>/dev/null || true

  # Wait up to 10 seconds for clean shutdown (checkpoint)
  for i in $(seq 1 10); do
    if ! lsof -ti :8080 >/dev/null 2>&1; then
      echo "    Backend stopped cleanly."
      break
    fi
    sleep 1
  done

  # Force kill if still running
  if lsof -ti :8080 >/dev/null 2>&1; then
    echo "    Backend did not stop in 10s — force killing..."
    lsof -ti :8080 2>/dev/null | xargs kill -9 2>/dev/null || true
    sleep 1
  fi
else
  echo "    Backend not running."
fi

# ── Stop frontend (port 5173) ─────────────────────────────────────────────
FRONTEND_PIDS=$(lsof -ti :5173 2>/dev/null || true)
if [ -n "$FRONTEND_PIDS" ]; then
  echo "==> Stopping frontend (PIDs: $(echo "$FRONTEND_PIDS" | tr '\n' ' '))..."
  echo "$FRONTEND_PIDS" | xargs kill 2>/dev/null || true
  sleep 2
  if lsof -ti :5173 >/dev/null 2>&1; then
    lsof -ti :5173 2>/dev/null | xargs kill -9 2>/dev/null || true
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
