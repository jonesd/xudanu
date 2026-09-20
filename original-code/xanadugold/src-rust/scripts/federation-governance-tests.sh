#!/bin/bash
# federation-governance-tests.sh — functional governance-level fault
# tests against a real genesis-pinned 4-node federation cluster.
#
# Usage:  ./scripts/federation-governance-tests.sh [BASE_PORT] [DATA_BASE]
#
# Scenarios:
#   G1. healthy propose → PBFT round seals on ALL nodes with
#       IDENTICAL digests (no fork via real sockets)
#   G2. leader SIGKILLed mid-round → the round STILL seals on the
#       survivors (f=1 quorum resilience in action)
#   G3. leader + one replica down → governance HALTS safely
#       (nothing seals, survivors healthy); after both return, a new
#       propose seals
#   G4. network partition via pf/dummynet — requires passwordless
#       sudo; SKIPPED with the ready-to-run recipe when unavailable
#       (process-level equivalents are covered by G2/G3 and the
#       fault-injection suite)
#
# View-change note: a true mid-round stall→NewView needs frame-level
# delivery control that correct quorum math makes unreachable via
# external socket faults at n=4 (any 3 live voters complete a round;
# fewer than 3 live cannot assemble a view-change quorum — halting
# safely is the CORRECT behavior). That path is covered by the
# in-process mesh harness (mesh_leader_crash_mid_round_recovers_via_
# view_change) and the 25-seed reordering fuzz.

set -u
cd "$(dirname "$0")/.."

BASE_PORT="${1:-9181}"
DATA_BASE="${2:-/tmp/xudanu-govtest}"
N=4
ADMIN_PASS="gov-test-passphrase"
LOG_DIR="$DATA_BASE/logs"
PID_FILE="$DATA_BASE/test.pids"
DRIVE="$PWD/../../../scripts/gov-drive.mjs"
[ -f "$DRIVE" ] || { echo "Error: gov-drive.mjs not found at $DRIVE"; exit 1; }

PASS=0; FAIL=0; SKIP=0
ok()   { echo "  [PASS] $1"; PASS=$((PASS+1)); }
bad()  { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
info() { echo "  [..]  $1"; }
skip() { echo "  [SKIP] $1"; SKIP=$((SKIP+1)); }

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
ws()   { echo "ws://127.0.0.1:$(port "$1")/xudanu?format=json&version=2"; }

start_node() {
    local i=$1
    local p; p=$(port "$i")
    local dir="$DATA_BASE/node-$i"
    local peers=""
    for j in $(seq 1 "$N"); do
        [ "$j" != "$i" ] && peers="$peers --peer 127.0.0.1:$(port "$j")"
    done
    XUDANU_ADMIN_PASSPHRASE="$ADMIN_PASS" "$BIN" run "127.0.0.1:$p" "$dir" $peers \
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

wait_healthy() {
    local i=$1 t=${2:-60}
    for _ in $(seq 1 "$t"); do
        [ "$(lifecycle "$i")" != "DOWN" ] && return 0
        sleep 1
    done
    return 1
}

seq_of()   { node "$DRIVE" "$(ws "$1")" "$ADMIN_PASS" sequence; }
view_of()  { node "$DRIVE" "$(ws "$1")" "$ADMIN_PASS" view 2>/dev/null; }
digests_of(){ node "$DRIVE" "$(ws "$1")" "$ADMIN_PASS" digests 2>/dev/null; }
propose_on(){ node "$DRIVE" "$(ws "$1")" "$ADMIN_PASS" propose "${2:-gov}"; }

wait_seq() { # node expected_seq [timeout_s]
    local i=$1 want=$2 t=${3:-30}
    for _ in $(seq 1 "$t"); do
        [ "$(seq_of "$i")" = "$want" ] && return 0
        sleep 1
    done
    return 1
}

check_unified() {
    local want="v=4 p=4 q=3 m=1" all_ok=1
    for i in $(seq 1 "$N"); do
        local lc; lc=$(lifecycle "$i")
        [ "$lc" != "$want" ] && { bad "$1: node-$i lifecycle '$lc'"; all_ok=0; }
    done
    [ $all_ok -eq 1 ] && ok "$1: lifecycle unified ($want)"
}

echo "=================================================================="
echo " Federation governance fault tests"
echo "   ports $BASE_PORT-$((BASE_PORT + N - 1)), data $DATA_BASE"
echo "=================================================================="

echo "Building server..."
cargo build --features server --bin xudanu-server 2>/dev/null || { echo "build failed"; exit 1; }
TARGET_DIR=$(cargo metadata --format-version 1 --no-deps 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["target_directory"])' 2>/dev/null)
BIN="$TARGET_DIR/debug/xudanu-server"
[ -f "$BIN" ] && [ -x "$BIN" ] || { echo "Error: binary not found at $BIN"; exit 1; }

# ── Fresh pinned cluster ──────────────────────────────────────────
rm -rf "$DATA_BASE"; mkdir -p "$LOG_DIR"
echo "[setup] init + pin + start $N nodes (admin passphrases installed)"
for i in $(seq 1 "$N"); do "$BIN" init "$DATA_BASE/node-$i" >/dev/null 2>&1; done
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

> "$PID_FILE"; PIDS=()
for i in $(seq 1 "$N"); do
    pid=$(start_node "$i"); PIDS+=("$pid"); echo "$pid" >> "$PID_FILE"
done
for i in $(seq 1 "$N"); do
    wait_healthy "$i" 90 || { bad "setup: node-$i never healthy"; exit 1; }
done
check_unified "setup"

# Identify the view-0 leader (sorted server_ids, deterministic).
LEADER=$(python3 - "$DATA_BASE" <<'PYGEN'
import json, sys, os
base = sys.argv[1]
ids = {}
for i in range(1, 5):
    kh = json.load(open(os.path.join(base, f"node-{i}", "key_history.json")))
    ids[kh["server_id"]] = i
leader_id = sorted(ids)[0]
print(ids[leader_id])
PYGEN
)
info "view-0 leader is node-$LEADER"
[ "$(node "$DRIVE" "$(ws "$LEADER")" "$ADMIN_PASS" leader 2>/dev/null)" = "LEADER" ] \
    && ok "leader identification confirmed via governance_status" \
    || bad "node-$LEADER does not report as leader"

# ── G1: healthy propose → seals everywhere, identical digests ────
echo ""
echo "[G1] propose on leader → PBFT seals on all nodes"
OUT=$(propose_on "$LEADER" g1)
echo "$OUT" | grep -q "PROPOSED" && ok "propose accepted ($OUT)" || bad "propose refused: $OUT"
SEALED=1
for i in $(seq 1 "$N"); do
    wait_seq "$i" 1 30 || { bad "G1: node-$i sequence did not advance"; SEALED=0; }
done
[ $SEALED -eq 1 ] && ok "sequence advanced to 1 on all nodes"
D0=$(digests_of 1)
DFORK=1
for i in 2 3 4; do
    [ "$(digests_of "$i")" = "$D0" ] || { bad "G1: node-$i digests differ — FORK"; DFORK=0; }
done
[ $DFORK -eq 1 ] && ok "sealed digests identical across all nodes (no fork)"
check_unified "G1"

# ── G2: leader killed mid-round → round still seals ──────────────
echo ""
echo "[G2] leader SIGKILL mid-round → survivors still seal (f=1)"
OUT=$(propose_on "$LEADER" g2)
echo "$OUT" | grep -q "PROPOSED" && ok "propose accepted ($OUT)" || bad "propose refused: $OUT"
kill -9 "${PIDS[$((LEADER-1))]}" 2>/dev/null
info "leader node-$LEADER killed immediately after propose"
sleep 2
SEALED=1
for i in $(seq 1 "$N"); do
    [ "$i" = "$LEADER" ] && continue
    wait_seq "$i" 2 30 || { bad "G2: survivor node-$i sequence did not advance"; SEALED=0; }
done
[ $SEALED -eq 1 ] && ok "round sealed on survivors despite leader death (quorum 3-of-4)"
# Restart the leader: catches up via state transfer.
PIDS[$((LEADER-1))]=$(start_node "$LEADER"); echo "${PIDS[$((LEADER-1))]}" >> "$PID_FILE"
wait_healthy "$LEADER" 90 && ok "leader restarted healthy" || bad "leader failed to restart"
wait_seq "$LEADER" 2 150 && ok "leader caught up (sequence 2 via state transfer)" \
    || bad "leader did not catch up (seq=$(seq_of "$LEADER"))"
D2=$(digests_of 1)
[ "$(digests_of "$LEADER")" = "$D2" ] && ok "rejoined leader has identical log (no fork)" \
    || bad "rejoined leader log differs — FORK"
check_unified "G2"

# ── G3: leader + one replica down → halt safely, recover ─────────
echo ""
echo "[G3] two nodes down → governance halts safely; recovery on return"
VICTIM=$(( LEADER % N + 1 ))
kill -9 "${PIDS[$((LEADER-1))]}" "${PIDS[$((VICTIM-1))]}" 2>/dev/null
info "killed node-$LEADER (leader) and node-$VICTIM"
sleep 2
OUT=$(propose_on 1 g3 2>/dev/null || echo "ERR-unreachable-or-refused")
echo "$OUT" | grep -q "PROPOSED" && bad "G3: propose unexpectedly accepted without quorum" \
    || ok "propose correctly refused/unavailable while below quorum"
sleep 1
HALT_OK=1
for i in $(seq 1 "$N"); do
    [ "$i" = "$LEADER" ] || [ "$i" = "$VICTIM" ] && continue
    [ "$(seq_of "$i")" = "2" ] || { bad "G3: node-$i sequence changed during halt"; HALT_OK=0; }
    lifecycle "$i" | grep -q DOWN && { bad "G3: survivor node-$i down"; HALT_OK=0; }
done
[ $HALT_OK -eq 1 ] && ok "halted safely: sequence frozen at 2, survivors healthy"
# Bring both back.
PIDS[$((LEADER-1))]=$(start_node "$LEADER"); echo "${PIDS[$((LEADER-1))]}" >> "$PID_FILE"
PIDS[$((VICTIM-1))]=$(start_node "$VICTIM"); echo "${PIDS[$((VICTIM-1))]}" >> "$PID_FILE"
wait_healthy "$LEADER" 90 && wait_healthy "$VICTIM" 90 && ok "both nodes returned healthy" \
    || bad "nodes failed to return"
OUT=$(propose_on "$LEADER" g3-retry)
echo "$OUT" | grep -q "PROPOSED" && ok "post-recovery propose accepted ($OUT)" || bad "post-recovery propose refused: $OUT"
# Both nodes' dialers may still be in reconnect backoff (≤30s each)
# and the victim may need a state-transfer round before it can vote —
# allow a generous window.
SEALED=1
for i in $(seq 1 "$N"); do
    wait_seq "$i" 3 150 || { bad "G3: node-$i did not seal post-recovery (seq=$(seq_of "$i"))"; SEALED=0; }
done
[ $SEALED -eq 1 ] && ok "governance resumed: sequence 3 on all nodes"
check_unified "G3"

# ── G4: pf/dummynet partition shaping (needs passwordless sudo) ──
echo ""
echo "[G4] network partition shaping via pf"
if sudo -n true 2>/dev/null; then
    VP=$(( BASE_PORT + VICTIM - 1 ))
    info "blocking all traffic to/from node-$VICTIM (port $VP)"
    echo "block drop proto tcp from any to 127.0.0.1 port $VP" | sudo pfctl -ef - >/dev/null 2>&1
    echo "block drop proto tcp from 127.0.0.1 port $VP to any" | sudo pfctl -f - >/dev/null 2>&1 || true
    sleep 2
    OUT=$(propose_on "$LEADER" g4)
    echo "$OUT" | grep -q "PROPOSED" && ok "propose accepted under 1-node partition ($OUT)" || bad "propose refused: $OUT"
    SEALED=1
    for i in $(seq 1 "$N"); do
        wait_seq "$i" 4 30 || SEALED=0
    done
    [ $SEALED -eq 1 ] && ok "round sealed with node-$VICTIM partitioned (quorum without it)"
    sudo pfctl -d >/dev/null 2>&1
    info "partition lifted"
    wait_healthy "$VICTIM" 60 && ok "node-$VICTIM healthy after unblock" || bad "node-$VICTIM unhealthy after unblock"
    wait_seq "$VICTIM" 4 90 && ok "node-$VICTIM caught up post-partition" || bad "node-$VICTIM did not catch up"
    check_unified "G4"
else
    skip "pf/dummynet shaping needs passwordless sudo. Recipe (run as root):"
    echo '         echo "block drop proto tcp from any to 127.0.0.1 port <NODE_PORT>" | sudo pfctl -ef -'
    echo "         ... exercise propose (must seal without the partitioned node) ..."
    echo "         sudo pfctl -d    # lift partition, verify catch-up"
    echo "       Process-level equivalents (kill/freeze) are covered by G2/G3 and"
    echo "       scripts/federation-fault-tests.sh."
fi

# ── Summary ───────────────────────────────────────────────────────
echo ""
echo "=================================================================="
echo "  RESULT: $PASS passed, $FAIL failed, $SKIP skipped"
echo "=================================================================="
[ "$FAIL" -eq 0 ]
