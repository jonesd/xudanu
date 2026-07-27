#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

OLLAMA_BASE_URL=http://localhost:11434 \
OLLAMA_MODEL=qwen2.5:1.5b \
"$ROOT/../../../target/debug/xudanu-server" \
  run 127.0.0.1:8080 "$ROOT/data" \
  --allowed-origin http://localhost:5173 \
  --allowed-origin http://127.0.0.1:5173 \
  --csrf-token
