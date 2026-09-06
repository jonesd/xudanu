#!/usr/bin/env bash
# demo-links-reset.sh — one command to a fresh links demo: stops the
# demo server, wipes its data dir, restarts (public-sandbox), and runs
# every links seed (corpus, course, playground, gallery works).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT=8081
DATA="$ROOT/data-link-demo"
BIN="$ROOT/target/debug/xudanu-server"

echo "==> stopping any demo server on :$PORT"
pkill -f "xudanu-server run 127.0.0.1:$PORT" 2>/dev/null || true
sleep 1

echo "==> wiping $DATA"
rm -rf "$DATA"

echo "==> starting demo server (public-sandbox, dev admin, static build)"
nohup "$BIN" run 127.0.0.1:$PORT "$DATA" \
  --static-dir "$ROOT/web/app/dist" \
  --edit-policy public-sandbox \
  --dev > /tmp/xudanu-link-demo.log 2>&1 &
disown

for i in $(seq 1 20); do
  curl -sf "http://127.0.0.1:$PORT/health" >/dev/null 2>&1 && break
  sleep 1
done
curl -sf "http://127.0.0.1:$PORT/health" >/dev/null || { echo "server failed to start"; exit 1; }
echo "    server up"

cd "$ROOT/scripts"
node demo-links-seed.mjs        # report / analysis / notes corpus
node demo-links-course.mjs      # five lessons + sandbox + published trail
node demo-links-playground.mjs  # the interactive playground
node demo-links-gallery.mjs     # one-clean-link + showcase (gallery frames)

echo ""
echo "==> READY: http://127.0.0.1:$PORT — start at 'Links Lesson 1'"
