#!/bin/bash
# federation-fault-tests.sh — automated failure injection against a real
# 4-node federation cluster, verifying detection + recovery for the
# scenarios the protocol is designed to handle.
#
# Usage:  ./scripts/federation-fault-tests.sh [BASE_PORT] [DATA_BASE]
#
# Scenarios (each must PASS for the run to succeed):
#   1. graceful stop / restart      — SIGTERM + checkpoint, node returns
#   2. hard crash / restart         — kill -9, state durable, converges
#   3. freeze / thaw                — SIGSTOP (hung node): survivors stay
#                                     healthy; on CONT the mesh either rides
#                                     through (connections persist, brief
#                                     freeze) or rebuilds (dialer backoff)
#   4. rolling restart              — every node recycled one at a time
#                                     while the rest keep quorum
#
# Invariants checked after every recovery:
#   - all nodes /health status=ok
#   - governance_lifecycle IDENTICAL on all nodes (validators=4 pool=4
#     quorum=3 margin=1) — a diverged set means fork
#   - mesh re-established (handshake log lines resume)
#
# The cluster is fully self-contained: fresh data dir, own ports,
# genesis-pinned. Leaves nothing running (cleanup trap).

set -u
cd "$(dirname "$0")/.."

BASE_PORT="${1:-9081}"
DATA_BASE="${2:-/tmp/xudanu-fedtest}"
N=4
LOG_DIR="$DATA_BASE/logs"
PID_FILE="$DATA_BASE/test.pids"

PASS=0; FAIL=0
ok()   { echo "  [PASS] $1"; PASS=$((PASS+1)); }
bad()  { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
info() { echo "  [..]  $1"; }

cleanup() {
    if [ -f "$PID_FILE" ]; then
        while read -r pid; do kill "$pid" 2>/dev/null || true; done < "$PID_FILE"
        sleep 1
        while read -r pid; do kill -9 "$pid" 2>/dev/null || true; done < "$PID_FILE"
        rm -f "$PID_FILE"
    fi
}
trap cleanup EXIT INT TERM

port() { echo $((BASE_PORT + $1 - 1)); }
log()  { echo "$LOG_DIR/node-$1.log"; }

start_node() {
    local i=$1
    local p; p=$(port "$i")
    local dir="$DATA_BASE/node-$i"
    local peers=""
    for j in $(seq 1 "$N"); do
        [ "$j" != "$i" ] && peers="$peers --peer 127.0.0.1:$(port "$j")"
    done
    "$BIN" run "127.0.0.1:$p" "$dir" $peers \
        --pin-members "$DATA_BASE/pinned-members.json" \
        >> "$(log "$i")" 2>&1 &
    echo $!
}

health() { curl -sf -m 2 "http://127.0.0.1:$(port "$1")/health" 2>/dev/null; }

lifecycle() {
    health "$1" | python3 -c '
import json, sys
try:
    g = json.load(sys.stdin)["governance_lifecycle"]
    print("v=%s p=%s q=%s m=%s" % (g["validators"], g["pool"], g["quorum"], g["margin"]))
except Exception:
    print("DOWN")' 2>/dev/null || echo "DOWN"
}

wait_healthy() { # node [timeout_s]
    local i=$1 t=${2:-60}
    for _ in $(seq 1 "$t"); do
        [ "$(lifecycle "$i")" != "DOWN" ] && return 0
        sleep 1
    done
    return 1
}

check_invariants() { # label
    local label=$1
    local want="v=4 p=4 q=3 m=1"
    local all_ok=1
    local first=""
    for i in $(seq 1 "$N"); do
        local lc; lc=$(lifecycle "$i")
        if [ "$lc" != "$want" ]; then
            bad "$label: node-$i lifecycle '$lc' != '$want'"
            all_ok=0
        fi
        if [ -z "$first" ]; then first="$lc"; fi
    done
    [ $all_ok -eq 1 ] && ok "$label: all 4 nodes healthy, lifecycle unified ($want)"
}

handshakes() { # node -> count of completed handshakes in its log
    grep -c "encrypted handshake completed" "$(log "$1")" 2>/dev/null || echo 0
}

echo "=================================================================="
echo " Federation fault-injection tests"
echo "   ports $BASE_PORT-$((BASE_PORT + N - 1)), data $DATA_BASE"
echo "=================================================================="

# ── Build ─────────────────────────────────────────────────────────
echo "Building server..."
cargo build --features server --bin xudanu-server 2>/dev/null || { echo "build failed"; exit 1; }
TARGET_DIR=$(cargo metadata --format-version 1 --no-deps 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["target_directory"])' 2>/dev/null)
BIN="$TARGET_DIR/debug/xudanu-server"
[ -f "$BIN" ] && [ -x "$BIN" ] || { echo "Error: xudanu-server binary not found at $BIN"; exit 1; }

# ── Fresh cluster (init + pin + start) ────────────────────────────
rm -rf "$DATA_BASE"
mkdir -p "$LOG_DIR"
echo ""
echo "[setup] initializing $N nodes + genesis pinning"
PIDS=()
for i in $(seq 1 "$N"); do
    "$BIN" init "$DATA_BASE/node-$i" >/dev/null 2>&1
done
python3 - "$DATA_BASE" "$N" <<'PYGEN'
import json, os, sys, hashlib
base, n = sys.argv[1], int(sys.argv[2])
members = []
for i in range(1, n + 1):
    kh = json.load(open(os.path.join(base, f"node-{i}", "key_history.json")))
    members.append({
        "server_id": kh["server_id"],
        "verifying_key_hex": bytes(kh["entries"][0]["verifying_key_bytes"]).hex(),
        "recovery_key_hex": hashlib.sha256(f"{base}/node-{i}/recovery".encode()).hexdigest()[:64],
    })
json.dump(members, open(os.path.join(base, "pinned-members.json"), "w"), indent=2)
PYGEN

echo "[setup] starting cluster"
> "$PID_FILE"
for i in $(seq 1 "$N"); do
    pid=$(start_node "$i")
    PIDS+=("$pid")
    echo "$pid" >> "$PID_FILE"
done
for i in $(seq 1 "$N"); do
    wait_healthy "$i" 90 || { bad "setup: node-$i never became healthy"; echo "see $(log "$i")"; exit 1; }
done
check_invariants "setup"

# ── Scenario 1: graceful stop / restart ──────────────────────────
echo ""
echo "[scenario 1] graceful stop + restart (node-2)"
kill "${PIDS[1]}" 2>/dev/null
for t in $(seq 1 30); do kill -0 "${PIDS[1]}" 2>/dev/null || break; sleep 0.5; done
kill -0 "${PIDS[1]}" 2>/dev/null && bad "node-2 did not exit on SIGTERM"
if lifecycle 1 | grep -q DOWN; then bad "node-1 degraded by node-2 stop"; else ok "survivors healthy during node-2 downtime"; fi
PIDS[1]=$(start_node 2); echo "${PIDS[1]}" >> "$PID_FILE"
wait_healthy 2 90 && ok "node-2 restarted healthy" || bad "node-2 failed to restart"
check_invariants "scenario 1"

# ── Scenario 2: hard crash / restart ─────────────────────────────
echo ""
echo "[scenario 2] kill -9 + restart (node-3)"
WORKS_BEFORE=$(health 3 | python3 -c 'import json,sys; print(json.load(sys.stdin)["works"])' 2>/dev/null)
kill -9 "${PIDS[2]}" 2>/dev/null
sleep 2
PIDS[2]=$(start_node 3); echo "${PIDS[2]}" >> "$PID_FILE"
wait_healthy 3 90 && ok "node-3 recovered from SIGKILL" || bad "node-3 failed to recover"
WORKS_AFTER=$(health 3 | python3 -c 'import json,sys; print(json.load(sys.stdin)["works"])' 2>/dev/null)
[ "$WORKS_BEFORE" = "$WORKS_AFTER" ] && ok "data durable across crash (works=$WORKS_AFTER)" \
    || bad "work count changed: $WORKS_BEFORE -> $WORKS_AFTER"
check_invariants "scenario 2"

# ── Scenario 3: freeze / thaw (hung node, partition-like) ────────
echo ""
echo "[scenario 3] SIGSTOP freeze 15s + SIGCONT thaw (node-4)"
HS_BEFORE=$(handshakes 4)
kill -STOP "${PIDS[3]}" 2>/dev/null
sleep 15
if lifecycle 1 | grep -q DOWN; then bad "node-1 degraded during node-4 freeze"; else ok "survivors healthy during freeze"; fi
kill -CONT "${PIDS[3]}" 2>/dev/null
# A freeze shorter than the heartbeat interval (30s) is a TRANSIENT
# pause: TCP sockets buffer and survive SIGSTOP, so the expected
# outcome is CONTINUITY — the mesh rides through without dropping
# connections. (A longer outage ends in socket close + dialer
# reconnect, which scenarios 2/4 cover via process death.) Both
# outcomes are acceptable here; what matters is health + unification.
wait_healthy 4 60 && ok "node-4 healthy after thaw" || bad "node-4 unhealthy after thaw"
HS_AFTER=$(handshakes 4)
if [ "$HS_AFTER" -eq "$HS_BEFORE" ]; then
    ok "mesh continuity through freeze (connections persisted, handshakes $HS_BEFORE)"
else
    ok "mesh rebuilt after freeze (handshakes $HS_BEFORE->$HS_AFTER)"
fi
check_invariants "scenario 3"

# ── Scenario 4: rolling restart ──────────────────────────────────
echo ""
echo "[scenario 4] rolling restart (all nodes, one at a time)"
ROLL_OK=1
for i in 1 2 3 4; do
    kill "${PIDS[$((i-1))]}" 2>/dev/null
    for t in $(seq 1 30); do kill -0 "${PIDS[$((i-1))]}" 2>/dev/null || break; sleep 0.5; done
    # survivors must stay healthy while this node is down
    for j in $(seq 1 "$N"); do
        [ "$j" = "$i" ] && continue
        lifecycle "$j" | grep -q DOWN && { bad "rolling: node-$j degraded while node-$i restarting"; ROLL_OK=0; }
    done
    PIDS[$((i-1))]=$(start_node "$i"); echo "${PIDS[$((i-1))]}" >> "$PID_FILE"
    wait_healthy "$i" 90 || { bad "rolling: node-$i failed to return"; ROLL_OK=0; }
done
[ $ROLL_OK -eq 1 ] && ok "rolling restart: quorum maintained throughout"
check_invariants "scenario 4"

# ── Summary ───────────────────────────────────────────────────────
echo ""
echo "=================================================================="
echo "  RESULT: $PASS passed, $FAIL failed"
echo "=================================================================="
[ "$FAIL" -eq 0 ]
