#!/bin/bash
# test-cross-server-network.sh — FR-40 cross-server link delivery under
# network stress on the 3-node Docker network.
#
# Covers the sender-feedback contract end to end:
#   1. Healthy delivery: node1 -> node2 link, receiver accepts
#   2. Receiver DOWN (docker stop): fast refusal, understandable error
#   3. Receiver BLACKHOLED (docker pause): bounded latency (<= ~7s),
#      understandable error — no multi-minute SYN stall
#   4. Rejection: valid node, nonexistent work -> HTTP 404 reason
#   5. Recovery: node2 unpaused/restarted -> accepted again
#   6. Persistence: restart node1 -> outcome survives restore
#
# Usage: ./docker/test-cross-server-network.sh
# Prereq: docker compose -f docker/docker-compose.yml up --build -d

set -u
cd "$(dirname "$0")"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAILED=1; }
info() { echo -e "${YELLOW}[TEST]${NC} $1"; }
FAILED=0

NODE1_WS="ws://localhost:8081/xudanu?format=json&version=2"
NODE2_ADDR="node2:8080"   # docker-internal address, resolved by node1
PROBE="node ws-link-probe.mjs"

# Health gate
for i in 1 2 3; do
  curl -sf "http://localhost:808$i/health" > /dev/null || { echo "node$i not healthy — run: docker compose up --build -d"; exit 1; }
done

# A real work on node2 to target (fetch its id via a probe create+list is
# complex; instead use the well-known seeded works? Simplest: create one
# via a one-off node script inline.)
WORK_HEX=$(node -e '
const WebSocket = require("ws");
const ws = new WebSocket("ws://localhost:8082/xudanu?format=json&version=2");
let id = 1;
const req = (op, payload) => new Promise((res, rej) => {
  const rid = id++;
  const to = setTimeout(() => rej(new Error("timeout " + op)), 15000);
  ws.send(JSON.stringify({ v: 2, type: "request", id: rid, op, payload: payload ?? {} }));
  ws.on("message", function h(d) {
    const f = JSON.parse(d);
    if (f.id === rid) { ws.off("message", h); clearTimeout(to); res(f.value); }
  });
});
const val = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);
(async () => {
  await new Promise(r => ws.once("open", r));
  await req("session_connect");
  await req("session_login_public");
  const w = val(await req("work_create", { edition: { text: "network test target" } }));
  console.log(val(w).toString(16));
  process.exit(0);
})().catch(e => { console.error(e.message); process.exit(1); });
') || fail "could not create target work on node2"

info "target work on node2: 0x$WORK_HEX"

probe() { # label expected_accepted error_substring
  local label="$1" expect="$2" substr="$3"
  local out
  out=$($PROBE "$NODE1_WS" "$NODE2_ADDR" "$WORK_HEX" "$label" 2>&1)
  echo "  $out"
  local accepted error ms
  accepted=$(echo "$out" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{console.log(JSON.parse(s).accepted)}catch{console.log("parse-error")}})')
  error=$(echo "$out" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{console.log(JSON.parse(s).error||"")}catch{console.log("")}})')
  ms=$(echo "$out" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{console.log(JSON.parse(s).create_ms)}catch{console.log("-1")}})')
  if [ "$accepted" = "$expect" ]; then
    pass "$label (accepted=$accepted, ${ms}ms)"
  else
    fail "$label: expected accepted=$expect, got accepted=$accepted"
  fi
  if [ -n "$substr" ] && ! echo "$error" | grep -qi "$substr"; then
    fail "$label: error message not understandable, expected '$substr', got: '$error'"
  fi
}

echo ""
info "1. healthy delivery (node2 up)"
probe healthy true ""

info "4. receiver rejection (nonexistent work)"
REJECT_OUT=$($PROBE "$NODE1_WS" "$NODE2_ADDR" "ffffee" reject 2>&1)
echo "  $REJECT_OUT"
REJ_ACC=$(echo "$REJECT_OUT" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{console.log(JSON.parse(s).accepted)}catch{console.log("parse-error")}})')
REJ_ERR=$(echo "$REJECT_OUT" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{console.log(JSON.parse(s).error||"")}catch{console.log("")}})')
if [ "$REJ_ACC" = "false" ] && echo "$REJ_ERR" | grep -qi "404\|not found"; then
  pass "reject: accepted=false, reason: $REJ_ERR"
else
  fail "reject: got accepted=$REJ_ACC err='$REJ_ERR'"
fi

echo ""
info "2. receiver down (docker stop node2) — expect fast refusal"
docker compose -f docker-compose.yml stop node2 > /dev/null 2>&1
sleep 1
DOWN_OUT=$($PROBE "$NODE1_WS" "$NODE2_ADDR" "$WORK_HEX" down 2>&1)
echo "  $DOWN_OUT"
DOWN_ACC=$(echo "$DOWN_OUT" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{console.log(JSON.parse(s).accepted)}catch{console.log("parse-error")}})')
DOWN_ERR=$(echo "$DOWN_OUT" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{console.log(JSON.parse(s).error||"")}catch{console.log("")}})')
DOWN_MS=$(echo "$DOWN_OUT" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{console.log(JSON.parse(s).create_ms)}catch{console.log("-1")}})')
if [ "$DOWN_ACC" = "false" ] && echo "$DOWN_ERR" | grep -qi "reach\|connect\|refus"; then
  pass "down: accepted=false in ${DOWN_MS}ms, reason: $DOWN_ERR"
else
  fail "down: got accepted=$DOWN_ACC err='$DOWN_ERR' (${DOWN_MS}ms)"
fi
if [ "$DOWN_MS" -gt 10000 ] 2>/dev/null; then
  fail "down: refusal took ${DOWN_MS}ms — should be fast (connection refused)"
fi

echo ""
info "3. receiver blackholed (docker pause node2) — expect bounded latency"
docker compose -f docker-compose.yml start node2 > /dev/null 2>&1
sleep 2
docker compose -f docker-compose.yml pause node2 > /dev/null 2>&1
sleep 1
PAUSE_OUT=$($PROBE "$NODE1_WS" "$NODE2_ADDR" "$WORK_HEX" blackhole 2>&1)
echo "  $PAUSE_OUT"
PAUSE_ACC=$(echo "$PAUSE_OUT" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{console.log(JSON.parse(s).accepted)}catch{console.log("parse-error")}})')
PAUSE_ERR=$(echo "$PAUSE_OUT" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{console.log(JSON.parse(s).error||"")}catch{console.log("")}})')
PAUSE_MS=$(echo "$PAUSE_OUT" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{console.log(JSON.parse(s).create_ms)}catch{console.log("-1")}})')
docker compose -f docker-compose.yml unpause node2 > /dev/null 2>&1
if [ "$PAUSE_ACC" = "false" ] && echo "$PAUSE_ERR" | grep -qi "reach\|connect\|timeout"; then
  pass "blackhole: accepted=false in ${PAUSE_MS}ms, reason: $PAUSE_ERR"
else
  fail "blackhole: got accepted=$PAUSE_ACC err='$PAUSE_ERR' (${PAUSE_MS}ms)"
fi
if [ "$PAUSE_MS" -gt 10000 ] 2>/dev/null; then
  fail "blackhole: took ${PAUSE_MS}ms — SYN stall not bounded (expected <= ~7s)"
else
  pass "blackhole latency bounded: ${PAUSE_MS}ms"
fi

echo ""
info "5. recovery (node2 unpaused)"
sleep 2
probe recovered true ""

echo ""
info "6. sender restart persistence (restart node1)"
docker compose -f docker-compose.yml restart node1 > /dev/null 2>&1
for i in $(seq 1 30); do
  curl -sf "http://localhost:8081/health" > /dev/null && break
  sleep 1
done
PERSIST_OUT=$(node -e '
const WebSocket = require("ws");
const ws = new WebSocket("ws://localhost:8081/xudanu?format=json&version=2");
let id = 1;
const req = (op, payload) => new Promise((res, rej) => {
  const rid = id++;
  const to = setTimeout(() => rej(new Error("timeout " + op)), 15000);
  ws.send(JSON.stringify({ v: 2, type: "request", id: rid, op, payload: payload ?? {} }));
  ws.on("message", function h(d) {
    const f = JSON.parse(d);
    if (f.id === rid) { ws.off("message", h); clearTimeout(to); res(f.value); }
  });
});
const val = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);
(async () => {
  await new Promise(r => ws.once("open", r));
  await req("session_connect");
  await req("session_login_public");
  await req("work_create", { edition: { text: "restart persistence check" } });
  const links = val(await req("link_list_for_work", { work_id: 0, offset: 0, limit: 1000 }));
  // fall back: scan recent links via link_get on ids 1..8
  let found = null;
  for (let lid = 1; lid <= 8 && !found; lid++) {
    try {
      const l = val(await req("link_get", { link_id: lid }));
      if (l && l.cross_server_notify_accepted !== undefined) found = l;
    } catch {}
  }
  if (!found) { console.log(JSON.stringify({ found: false })); process.exit(0); }
  console.log(JSON.stringify({ found: true, accepted: found.cross_server_notify_accepted, error: found.cross_server_notify_error ?? null }));
  process.exit(0);
})().catch(e => { console.log(JSON.stringify({ found: false, error: e.message })); process.exit(0); });
')
echo "  $PERSIST_OUT"
if echo "$PERSIST_OUT" | grep -q '"found":true'; then
  if echo "$PERSIST_OUT" | grep -q '"accepted":true'; then
    pass "notify outcome survives sender restart"
  else
    fail "notify outcome survived restart but shows not-accepted: $PERSIST_OUT"
  fi
else
  fail "no cross-server link found after restart — outcome not persisted"
fi

echo ""
if [ "$FAILED" = "0" ]; then
  echo -e "${GREEN}  ALL NETWORK TESTS PASSED${NC}"
else
  echo -e "${RED}  NETWORK TESTS FAILED${NC}"
fi
exit $FAILED
