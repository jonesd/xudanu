#!/bin/bash
# pattern-scan.sh — detect suspicious code patterns that have caused
# data-loss bugs in this codebase. Each pattern is documented in
# docs/dev/pattern-registry.md with the bug it caused.
#
# Usage: ./scripts/pattern-scan.sh [--check]
#   --check  Exit 1 if new suspicious patterns found (CI mode)
#
# The whitelist (scripts/pattern-whitelist.txt) lists known-safe
# instances. New violations fail CI until triaged.
set -o pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/../original-code/xanadugold/src-rust/src"
WHITELIST="$HERE/pattern-whitelist.txt"
CHECK_MODE="${1:-}"
VIOLATIONS=0
OUTPUT=""

# Color output (disabled in CI)
if [ -t 1 ] && [ -z "$CHECK_MODE" ]; then
  C_RED="\033[0;31m"; C_YEL="\033[0;33m"; C_GRN="\033[0;32m"; C_RST="\033[0m"
else
  C_RED=""; C_YEL=""; C_GRN=""; C_RST=""
fi

is_whitelisted() {
  local pattern="$1" file="$2" line="$3"
  grep -q "^${pattern}|${file}|${line}$" "$WHITELIST" 2>/dev/null
}

report() {
  local severity="$1" pattern="$2" file="$3" line="$4" detail="$5"
  local key="${pattern}|${file#*$SRC/}|${line}"
  if is_whitelisted "$pattern" "${file#*$SRC/}" "$line"; then
    OUTPUT="${OUTPUT}\n  ${C_GRN}○${C_RST} [whitelisted] $pattern at ${file#*$SRC/}:$line"
    return
  fi
  OUTPUT="${OUTPUT}\n  ${C_RED}✗${C_RST} [$severity] $pattern at ${file#*$SRC/}:$line — $detail"
  VIOLATIONS=$((VIOLATIONS + 1))
}

echo "── Pattern Scan: $(date '+%Y-%m-%d %H:%M:%S') ──"
echo ""

# ── Pattern 1: Silent I/O failure (let _ = on Result-returning I/O) ───
echo "Pattern 1: Silent I/O failure (let _ = on persistence calls)"
echo "  Caused: WAL entries silently lost (C4), server directory silently lost"
echo ""

# Only scan non-test code for DATA-PERSISTENCE calls (not cleanup deletes)
rg -n "let _ = " "$SRC/server/server.rs" "$SRC/server/detectors.rs" \
  "$SRC/server/transport/shared.rs" "$SRC/bin/" \
  --type rust 2>/dev/null | \
  grep -v "#\[test\]" | \
  grep -v "//" | \
  grep -v "remove_dir_all\|remove_file\|drop(" | \
  grep -E "wal\.append|fs::write|fs::read|fs::rename|persist|sidecar|checkpoint|server_directory_save|save_detectors|save_trails|content_set" | \
  while IFS=: read -r file line text; do
    report "CRITICAL" "silent-io" "$file" "$line" "$(echo "$text" | xargs)"
  done
echo ""

# ── Pattern 2: warn! + empty default (silent restore fallback) ────────
echo "Pattern 2: Silent restore fallback (warn! without restore_errors)"
echo "  Caused: Social chunk loss (H4), links chunk loss (H5), etc."
echo ""

while IFS=: read -r file line text; do
  [[ "$text" == *"tracing::warn"* ]] || continue
  # Check if it's a restore/read path that falls back to a default
  if echo "$text" | grep -qE \
    "chunk.*fail|chunk.*error|restore.*fail|read.*fail|parse.*error|sidecar.*unreadable"; then
    # Check if restore_errors is pushed nearby (within 5 lines after)
    local_context=$(sed -n "${line},$((line + 5))p" "$file" 2>/dev/null)
    if ! echo "$local_context" | grep -q "restore_errors"; then
      report "HIGH" "silent-restore" "$file" "$line" "$text"
    fi
  fi
done < <(rg -n "tracing::warn" "$SRC" --type rust | grep -v "test\|//\|cargo" | head -500)
echo ""

# ── Pattern 3: Serialized field without round-trip test ──────────────
echo "Pattern 3: Serialized field without round-trip test"
echo "  Caused: link types lost (H1), compound segments lost (H2), etc."
echo ""

# Find all struct fields in persist/ that are pub and serialized
for field in $(rg -o "pub \w+:.*" "$SRC/persist/" --type rust 2>/dev/null | \
  grep -oE "pub \w+:" | sed 's/pub //;s/://' | sort -u | head -30); do
  # Check if there's a round-trip test for this field
  if ! rg -q "${field}.*roundtrip\|roundtrip.*${field}" "$SRC" --type rust 2>/dev/null; then
    # Check if the field appears in any test at all
    if ! rg -q "$field" "$SRC/server/server.rs" --type rust 2>/dev/null | grep -q "test\|assert"; then
      report "MEDIUM" "no-roundtrip-test" "persist/" "?" "field '$field' has no round-trip test"
    fi
  fi
done
echo ""

# ── Pattern 4: unwrap() in restore path (panic on corrupt data) ───────
echo "Pattern 4: unwrap() in restore path (panics on corrupt data)"
echo "  Caused: server crash-loop on corrupted chunk"
echo ""

while IFS=: read -r file line text; do
  [[ "$file" == *"restore"* ]] || [[ "$file" == *"root_chunk"* ]] || [[ "$file" == *"manifest"* ]] || continue
  [[ "$text" == *".unwrap()"* ]] || continue
  # Skip test files
  [[ "$file" == *"test"* ]] && continue
  # Skip type conversion unwraps that are safe
  echo "$text" | grep -qE "as_u64\(\)|as_str\(\)|to_str\(\)|into_iter" && continue
  report "MEDIUM" "unwrap-in-restore" "$file" "$line" "$text"
done < <(rg -n "\.unwrap\(\)" "$SRC/persist/" --type rust | head -200)
echo ""

# ── Pattern 5: Flag set but potentially never consumed ────────────────
echo "Pattern 5: Flag set without verified consumer"
echo "  Caused: checkpoint_in_flight wedge (C2)"
echo ""

# This is harder to detect statically — flag boolean assignments that
# are followed by no read within 20 lines in the same function
while IFS=: read -r file line text; do
  [[ "$text" == *"= true"* ]] || continue
  # Skip test files and common patterns
  [[ "$file" == *"test"* ]] && continue
  echo "$text" | grep -qE "enabled|requested|flag|in_flight|dirty|pending" || continue
  # Check if the flag is read within the next 20 lines of the same function
  context=$(sed -n "$((line - 5)),$((line + 20))p" "$file" 2>/dev/null)
  flag_name=$(echo "$text" | grep -oE "self\.\w+" | head -1 | sed 's/self\.//')
  if [ -n "$flag_name" ] && ! echo "$context" | grep -q "self\.$flag_name" | grep -v "$line"; then
    report "MEDIUM" "flag-lifecycle" "$file" "$line" "flag '$flag_name' set — verify it has a consumer"
  fi
done < <(rg -n "= true;" "$SRC/server/" --type rust | grep -v "test\|//" | head -300)
echo ""

# ── Summary ────────────────────────────────────────────────────────────
echo "── Scan Summary ──"
echo -e "$OUTPUT"  # Print buffered findings

if [ "$VIOLATIONS" -gt 0 ]; then
  CRITICALS=$(echo -e "$OUTPUT" | grep -c "CRITICAL" || true)
  HIGHS=$(echo -e "$OUTPUT" | grep -c "\[HIGH\]" || true)
  MEDIUMS=$(echo -e "$OUTPUT" | grep -c "MEDIUM" || true)

  echo ""
  echo "  CRITICAL: $CRITICALS  HIGH: $HIGHS  MEDIUM: $MEDIUMS"

  if [ "$CHECK_MODE" = "--check" ]; then
    BLOCKING=$((CRITICALS + HIGHS))
    if [ "$BLOCKING" -gt 0 ]; then
      echo -e "${C_RED}$BLOCKING blocking issue(s) — CI FAIL${C_RST}"
      echo "Fix the code or add to scripts/pattern-whitelist.txt"
      exit 1
    else
      echo -e "${C_GRN}No blocking issues${C_RST} ($MEDIUMS medium — informational)"
      exit 0
    fi
  else
    echo -e "${C_YEL}$VIOLATIONS total finding(s)${C_RST}"
  fi
else
  echo -e "${C_GRN}No suspicious patterns found${C_RST}"
fi
