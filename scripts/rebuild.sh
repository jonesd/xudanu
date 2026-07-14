#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_RUST="$ROOT/original-code/xanadugold/src-rust"

echo "==> Building xudanu-server (release)..."
cd "$SRC_RUST"
cargo build --release --features server --bin xudanu-server
echo "==> Done. Run ./scripts/restart.sh to start."
