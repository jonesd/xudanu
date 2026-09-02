#!/usr/bin/env bash
# clear-build-cache.sh — reclaim disk from cargo build caches.
# Safe: only derived caches are removed; cargo rebuilds on demand.
#   target/debug/incremental  — the usual multi-GB hog
#   target/llvm-cov-target    — coverage artifacts
#   target/release            — stale release builds (rebuild via rebuild.sh)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo "Before: $(df -h / | tail -1 | awk '{print $4}') free"
rm -rf "$ROOT/target/debug/incremental" 2>/dev/null || true
rm -rf "$ROOT/target/llvm-cov-target" 2>/dev/null || true
rm -rf "$ROOT/target/release" 2>/dev/null || true
echo "After:  $(df -h / | tail -1 | awk '{print $4}') free"
