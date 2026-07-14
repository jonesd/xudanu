#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
cargo build --release --features server --bin xudanu-server
echo "==> Done. Run ~/code/xu-gold-2026/scripts/restart.sh to start."
