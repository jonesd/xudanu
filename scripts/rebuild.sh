#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_RUST="$ROOT/original-code/xanadugold/src-rust"
WEB_APP="$ROOT/web/app"

# Frontend first: the release binary embeds web/app/dist at compile
# time — building cargo before the frontend freezes whatever stale
# dist/ was lying around (the v1.9.0-embedded-binary bug).
if [ ! -f "$WEB_APP/dist/index.html" ] || [ "$WEB_APP/src" -nt "$WEB_APP/dist/index.html" ]; then
  echo "==> Building frontend (dist is stale or missing)..."
  (cd "$WEB_APP" && npm run build)
else
  echo "==> Frontend dist up to date."
fi

echo "==> Building xudanu-server (release)..."
cd "$SRC_RUST"
cargo build --release --features server --bin xudanu-server
echo "==> Done. Run ./scripts/restart.sh to start."
