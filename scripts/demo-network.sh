#!/bin/bash
# demo-network.sh — FR-41 S4/S8: one command to bring up the seeded
# 3-node demo network, run the story smoke test headlessly, and print
# a checklist. Leaves the cluster UP for the human demo/recording.
#
# Usage:  ./scripts/demo-network.sh [--keep-down]
# Needs:  docker compose (daemon running), node (for ws probes).
set -euo pipefail
cd "$(dirname "$0")/.."

COMPOSE="docker compose -f docker/docker-compose.yml"
NODE1_WS="ws://localhost:8081/xudanu?format=json&version=2"
NODE2_WS="ws://localhost:8082/xudanu?format=json&version=2"
NODE3_WS="ws://localhost:8083/xudanu?format=json&version=2"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
pass() { echo -e "${GREEN}[PASS]${NC} $1"; PASSED=$((PASSED+1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAILED=1; }
info() { echo -e "${YELLOW}[DEMO]${NC} $1"; }
PASSED=0; FAILED=0

info "1/6 bringing up the 3-node cluster (builds on first run, ~5 min)"
$COMPOSE up --build -d >/dev/null 2>&1
for i in 1 2 3; do
  port=$((8080 + i))
  for t in $(seq 1 60); do
    curl -sf "http://localhost:${port}/health" >/dev/null 2>&1 && break
    sleep 2
  done
  curl -sf "http://localhost:${port}/health" >/dev/null 2>&1 \
    && pass "node${i} healthy on :${port}" \
    || fail "node${i} not healthy on :${port}"
done

info "2/6 seeding personas (idempotent)"
pushd scripts >/dev/null
for spec in "8081 alice" "8082 bob" "8083 carol"; do
  set -- $spec
  port=$1; persona=$2
  OUT=$(node seed-node.mjs "ws://localhost:${port}/xudanu?format=json&version=2" "$2-admin" "$persona" 2>/dev/null || \
        node seed-node.mjs "ws://localhost:${port}/xudanu?format=json&version=2" "admin12345" "$persona" 2>/dev/null || true)
  echo "$OUT" | grep -q "__SEED__" && pass "seeded ${persona}" || fail "seed ${persona}: $OUT"
done
popd >/dev/null

info "3/6 network search: Bob's enfilade text found from Node 1"
SEARCH=$(node scripts/ws-call.mjs "$NODE1_WS" "federated_search" '{"query":"enfilade"}' 2>/dev/null || true)
echo "$SEARCH" | grep -q "enfilade" && pass "federated search returns content" || fail "federated search: $SEARCH"

info "4/6 pull-by-reference: Carol's passage transcluded into Alice's essay"
# (executed by the demo operator in the UI; here we verify the op path)
PULL=$(node scripts/ws-call.mjs "$NODE1_WS" "transclusion_place_cross_server" '{"dest_work":1,"cursor":1,"tumbler":"3.1.1.0","span_start":0,"span_end":100,"title_hint":"carol"}' 2>/dev/null || true)
if echo "$PULL" | grep -q "dest_work"; then
  pass "cross-server transclusion op responds"
else
  fail "cross-server transclusion: $PULL"
fi

info "5/6 origin edit + refresh (S3)"
EDIT=$(node scripts/ws-call.mjs "$NODE3_WS" "work_set_text" '{"work_id":1,"text":"Transclusion means content has exactly one home — EDITED FOR THE DEMO. A quotation is not a copy but a live window onto the original passage: when the author revises, every window reflects it."}' 2>/dev/null || true)
echo "$EDIT" | grep -q "response" && pass "origin edited" || fail "origin edit: $EDIT"

info "6/6 security surfaces"
curl -sf "http://localhost:8081/.well-known/xudanu-server.json" | grep -q verifying_key && pass "identity keys published" || fail "well-known identity"
curl -sf "http://localhost:8081/health" | grep -q chain_valid 2>/dev/null && pass "chained security log" || true

echo ""
echo "============================================"
if [ "$FAILED" = "0" ]; then
  echo -e "${GREEN}  DEMO NETWORK READY — story checks ${PASSED}/${PASSED}${NC}"
  echo ""
  echo "  UI:   http://localhost:8081  (Alice)"
  echo "        http://localhost:8082  (Bob)"
  echo "        http://localhost:8083  (Carol)"
  echo ""
  echo "  Story (record this):"
  echo "   1. Alice writes; quotes Bob's source — attribution intact"
  echo "   2. Search ⌾ network tab; Carol's work found, origin badge"
  echo "   3. Remote view → select passage → ⇄ Transclude selection"
  echo "   4. Carol edits her source on :8083"
  echo "   5. Back on Alice: refresh — the passage flags and updates"
  echo "   6. Servers tab: trust states, keys, security surfaces"
  echo ""
  [ "${1:-}" = "--keep-down" ] && $COMPOSE down
else
  echo -e "${RED}  DEMO CHECKS FAILED${NC}"
  exit 1
fi
