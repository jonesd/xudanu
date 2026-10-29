#!/bin/bash
# federation-adversarial-tests.sh — randomized fault injection
# against the 4-node docker federation cluster.
#
# Usage:  ./scripts/federation-adversarial-tests.sh [SEED] [SCENARIOS]
# Needs:  docker compose cluster UP (docker/docker-compose.yml, from
#         the workspace root: `docker compose -f docker/docker-compose.yml
#         up --build -d`), passphrases in docker/.env, node + python3.
#
# Strictly nastier than federation-governance-tests.sh:
#   docker pause  — process freeze with NO FIN: connections go silent
#                   (half-open sockets, heartbeats vanish) — the worst
#                   liveness case a real network can produce short of
#                   partitioning
#   docker kill   — SIGKILL hard crash (kernel closes sockets)
#   strike timing — faults land 0-900 ms after a propose returns,
#                   racing pre-prepare/prepare/commit propagation
#   flapping      — repeated pause/unpause cycles mid-round
#
# Scenarios (seeded, reproducible via SEED):
#   A1 freeze-leader    pause the proposing leader mid-round
#   A2 freeze-replica   pause a random replica mid-round
#   A3 dual-freeze      pause leader + one replica (G3 with half-open
#                       sockets instead of FINs)
#   A4 crash-leader     docker kill the leader mid-round
#   A5 catch-up race    kill leader, restart, propose the moment
#                       health returns (races state transfer)
#   A6 flapper          pause/unpause one node 5x during the round
#
# Invariants after every scenario:
#   I1 survivors of a single strike seal the round (3-of-4 quorum)
#      or halt safely below quorum — never fork, never regress
#   I2 after healing (plus a re-propose when a round was halted)
#      ALL four nodes converge to the same sequence
#   I3 sealed-batch digests identical across all four nodes (no fork,
#      ever — including batches sealed while nodes were frozen out)
#   I4 lifecycle unified (v=4 p=4 q=3 m=1) once healed

set -u
cd "$(dirname "$0")/../../../.."   # workspace root (src-rust/scripts → 4 up)

SEED="${1:-20261028}"
COUNT="${2:-6}"
COMPOSE="docker compose -f docker/docker-compose.yml"
DRIVE="$PWD/scripts/gov-drive.mjs"
ENV_FILE="docker/.env"

[ -f "$DRIVE" ] || { echo "Error: gov-drive.mjs not found at $DRIVE"; exit 1; }
[ -f "$ENV_FILE" ] || { echo "Error: $ENV_FILE missing (admin passphrases)"; exit 1; }

# Extract per-key rather than `source <(grep ...)`: macOS /bin/bash
# 3.2 (what the shebang resolves to) silently drops assignments read
# from a process-substitution fd, leaving PASS[] empty, while newer
# bash 5.x (used interactively and under `bash -x`) is unaffected.
pass_from_env() { # node-number -> passphrase
    grep -E "^NODE${1}_ADMIN_PASSPHRASE=" "$ENV_FILE" \
        | head -n1 | cut -d= -f2- | tr -d '\r'
}
PASS[1]="$(pass_from_env 1)"; PASS[2]="$(pass_from_env 2)"
PASS[3]="$(pass_from_env 3)"; PASS[4]="$(pass_from_env 4)"
for i in 1 2 3 4; do
    [ -n "${PASS[$i]}" ] || {
        echo "Error: NODE${i}_ADMIN_PASSPHRASE missing from $ENV_FILE"
        exit 1
    }
done

PASS_N=0; FAIL_N=0
ok()   { echo "  [PASS] $1"; PASS_N=$((PASS_N+1)); }
bad()  { echo "  [FAIL] $1"; FAIL_N=$((FAIL_N+1)); }
info() { echo "  [..]  $1"; }

port() { echo $((8080 + $1)); }
ws()   { echo "ws://127.0.0.1:$(port "$1")/xudanu?format=json&version=2"; }

health_ok() { curl -sf -m 2 "http://127.0.0.1:$(port "$1")/health" >/dev/null 2>&1; }

seq_of() {   # prints sequence, or DOWN
    health_ok "$1" || { echo DOWN; return; }
    node "$DRIVE" "$(ws "$1")" "${PASS[$1]}" sequence 2>/dev/null || echo DOWN
}

digests_of() {
    health_ok "$1" || { echo DOWN; return; }
    node "$DRIVE" "$(ws "$1")" "${PASS[$1]}" digests 2>/dev/null || echo DOWN
}

wait_healthy() { # node [timeout_s]
    local i=$1 t=${2:-90}
    for _ in $(seq 1 "$t"); do health_ok "$i" && return 0; sleep 1; done
    return 1
}

wait_seq() { # node expected [timeout_s]
    local i=$1 want=$2 t=${3:-150}
    for _ in $(seq 1 "$t"); do
        [ "$(seq_of "$i")" = "$want" ] && return 0
        sleep 1
    done
    return 1
}

# Propose on whichever node currently leads; echoes the proposer node
# number, or nothing if every node refused.
propose_anywhere() {
    local tag="$1" out i
    for i in 1 2 3 4; do
        health_ok "$i" || continue
        out=$(node "$DRIVE" "$(ws "$i")" "${PASS[$i]}" propose "$tag" 2>/dev/null) || continue
        if echo "$out" | grep -q "PROPOSED"; then echo "$i"; return 0; fi
    done
    return 1
}

svc() { echo "node$1"; }   # compose service name

freeze()  { $COMPOSE pause "$(svc "$1")" >/dev/null 2>&1; }
thaw()    { $COMPOSE unpause "$(svc "$1")" >/dev/null 2>&1; }
crash()   { $COMPOSE kill "$(svc "$1")" >/dev/null 2>&1; }
revive()  { $COMPOSE start "$(svc "$1")" >/dev/null 2>&1; }

ensure_all_healthy() {
    local i
    for i in 1 2 3 4; do wait_healthy "$i" 120 || bad "node-$i never became healthy"; done
}

check_no_fork() {
    local d1 d2 i
    d1=$(digests_of 1)
    [ "$d1" = "DOWN" ] && { bad "no-fork check: node-1 unreachable"; return 1; }
    for i in 2 3 4; do
        d2=$(digests_of "$i")
        if [ "$d2" != "$d1" ]; then
            bad "no-fork check: node-$i digests differ from node-1"
            info "node-1: ${d1:0:96}…"
            info "node-$i: ${d2:0:96}…"
            return 1
        fi
    done
    return 0
}

# After healing: if the strike-halted round left any node behind,
# drive one more propose; then ALL nodes must reach the same seq.
# A stalled round stays pending for ~10-15s (round timeout +
# view-change poll) and `propose` is refused while one is open, so
# retry across that window.
converge_all() { # expected_seq_after_seal
    local target="$1" i s have_all=1
    for i in 1 2 3 4; do
        if ! wait_seq "$i" "$target" 180; then have_all=0; break; fi
    done
    if [ $have_all -eq 0 ]; then
        info "round halted by the strike — driving a convergence propose"
        local got=""
        for attempt in 1 2 3; do
            got=$(propose_anywhere "converge") && break
            info "propose refused (stalled round still pending?) — retry $attempt"
            sleep 15
        done
        [ -n "$got" ] || bad "convergence propose refused on all nodes"
        target=$((target + 1))
        for i in 1 2 3 4; do
            wait_seq "$i" "$target" 180 || bad "node-$i did not converge (seq=$(seq_of "$i"), want $target)"
        done
    fi
    check_no_fork
    s=$(seq_of 1); info "cluster converged at seq=$s"
}

echo "=================================================================="
echo " Federation adversarial fault tests (docker, seed=$SEED, n=$COUNT)"
echo "=================================================================="

# ── Preflight ─────────────────────────────────────────────────────
for i in 1 2 3 4; do
    health_ok "$i" || { echo "Error: node-$i unhealthy — is the compose cluster up?"; exit 1; }
done
# Wait out the post-boot federation sync storm: the recurring mesh
# sync (works + membership OR-set) can starve client WS requests
# behind the server lock for minutes, while HTTP /health answers
# throughout. Gate on the lifecycle signal first (cheap, HTTP), then
# confirm one governance-status read per node.
info "waiting for governance lifecycle to unify (post-boot sync storm)"
for i in 1 2 3 4; do
    ready=0
    for _ in $(seq 1 120); do
        lc=$(curl -sf -m 3 "http://127.0.0.1:$(port "$i")/health" 2>/dev/null | python3 -c '
import json,sys
try:
    g = json.load(sys.stdin)["governance_lifecycle"]
    print("v=%s p=%s q=%s m=%s" % (g["validators"], g["pool"], g["quorum"], g["margin"]))
except Exception:
    print("DOWN")' 2>/dev/null || echo DOWN)
        [ "$lc" = "v=4 p=4 q=3 m=1" ] && { ready=1; break; }
        sleep 3
    done
    [ $ready -eq 1 ] || { echo "Error: node-$i lifecycle never unified (last: $lc)"; exit 1; }
done
info "lifecycle unified — confirming governance status answers"
for i in 1 2 3 4; do
    ready=0
    for _ in $(seq 1 10); do
        case "$(seq_of "$i")" in ''|DOWN) sleep 3 ;; *) ready=1; break ;; esac
    done
    [ $ready -eq 1 ] || { echo "Error: node-$i governance status unavailable"; exit 1; }
done
# Warm-up round: prove the mesh can actually seal BEFORE fault
# injection starts (also gives the digest baseline a non-empty log).
BASE=$(seq_of 1)
WARM=$((BASE + 1))
info "warm-up propose (seq $WARM) — proving the healthy mesh seals"
W=$(propose_anywhere "warmup") || { echo "Error: warm-up propose refused on all nodes"; exit 1; }
for i in 1 2 3 4; do
    wait_seq "$i" "$WARM" 150 || { echo "Error: node-$i never sealed the warm-up round (seq=$(seq_of "$i"))"; exit 1; }
done
check_no_fork || { echo "Error: warm-up round forked"; exit 1; }
ok "warm-up round sealed on all nodes (seq=$WARM)"
BASE_DIGESTS=$(digests_of 1)
[ "$BASE_DIGESTS" != "DOWN" ] || { echo "Error: node-1 digests unavailable"; exit 1; }
for i in 2 3 4; do
    [ "$(digests_of "$i")" = "$BASE_DIGESTS" ] || {
        echo "Error: node-$i has a different sealed log BEFORE testing (pre-existing fork?)."
        echo "       Reset volumes (docker compose down -v) and re-bootstrap, or investigate."
        exit 1
    }
done
ok "preflight: 4 nodes healthy, sealed log consistent (seq=$WARM)"

# ── Deterministic schedule ────────────────────────────────────────
SCHEDULE=$(python3 - "$SEED" "$COUNT" <<'PYGEN'
import random, sys
seed, count = int(sys.argv[1]), int(sys.argv[2])
rng = random.Random(seed)
scenarios = ["A1", "A2", "A3", "A4", "A5", "A6"]
for k in range(count):
    s = scenarios[k % len(scenarios)] if count <= len(scenarios) else rng.choice(scenarios)
    victim = rng.randint(1, 4)
    delay_ms = rng.randint(0, 900)
    print(f"{s} {victim} {delay_ms}")
PYGEN
)
echo ""
echo "Schedule:"
echo "$SCHEDULE" | sed 's/^/  /'
echo ""

trap 'for i in 1 2 3 4; do thaw "$i"; revive "$i"; done' EXIT INT TERM

SCENARIO=0
while read -r name victim delay_ms; do
    SCENARIO=$((SCENARIO+1))
    BASE=$(seq_of 1)
    case "$BASE" in ''|DOWN)
        bad "scenario $name: cluster status unavailable"
        continue ;;
    esac
    WANT=$((BASE + 1))
    echo "────────────────────────────────────────────────────────"
    case "$name" in
        A1) echo "[$name] freeze leader mid-round (victim=$victim delay=${delay_ms}ms) base_seq=$BASE";;
        A2) echo "[$name] freeze replica mid-round (victim=$victim delay=${delay_ms}ms) base_seq=$BASE";;
        A3) echo "[$name] dual freeze: proposer + node-$victim (delay=${delay_ms}ms) base_seq=$BASE";;
        A4) echo "[$name] crash leader mid-round (victim=$victim delay=${delay_ms}ms) base_seq=$BASE";;
        A5) echo "[$name] catch-up race on node-$victim base_seq=$BASE";;
        A6) echo "[$name] flapper node-$victim (delay=${delay_ms}ms) base_seq=$BASE";;
    esac

    case "$name" in
        A1|A2|A4)
            LEADER=$(propose_anywhere "$name-$SCENARIO")
            [ -n "$LEADER" ] || { bad "$name: propose refused on all nodes"; continue; }
            # A1/A4 strike the proposer; A2 strikes a non-proposing
            # replica (fall back to the next node if the dice picked
            # the proposer).
            STRIKE=$LEADER
            if [ "$name" = "A2" ]; then
                STRIKE=$victim
                [ "$STRIKE" = "$LEADER" ] && STRIKE=$(( (LEADER % 4) + 1 ))
            fi
            info "proposed on node-$LEADER; striking node-$STRIKE in ${delay_ms}ms"
            sleep "$(python3 -c "print($delay_ms/1000)")"
            if [ "$name" = "A4" ]; then crash "$STRIKE"; else freeze "$STRIKE"; fi
            # Single strike: the three live voters form a quorum, so
            # survivors either seal (WANT) or halt safely (BASE) — and
            # must agree with each other in either case.
            sleep 8
            LIVE_OK=1
            for i in 1 2 3 4; do
                [ "$i" = "$STRIKE" ] && continue
                s=$(seq_of "$i")
                case "$s" in
                    "$BASE"|"$WANT") ;;
                    *) bad "$name: survivor node-$i at seq=$s (want $BASE or $WANT)"; LIVE_OK=0 ;;
                esac
            done
            [ $LIVE_OK -eq 1 ] && ok "$name: survivors sealed or halted safely"
            if [ "$name" = "A4" ]; then revive "$STRIKE"; else thaw "$STRIKE"; fi
            wait_healthy "$STRIKE" 120 && ok "$name: node-$STRIKE healed" || bad "$name: node-$STRIKE failed to heal"
            converge_all "$WANT"
            ;;
        A3)
            LEADER=$(propose_anywhere "$name-$SCENARIO")
            [ -n "$LEADER" ] || { bad "$name: propose refused on all nodes"; continue; }
            SECOND=$victim
            [ "$SECOND" = "$LEADER" ] && SECOND=$(( (LEADER % 4) + 1 ))
            info "proposed on node-$LEADER; freezing node-$LEADER + node-$SECOND in ${delay_ms}ms"
            sleep "$(python3 -c "print($delay_ms/1000)")"
            freeze "$LEADER"; freeze "$SECOND"
            sleep 3
            # Below quorum: survivors must not advance beyond WANT.
            for i in 1 2 3 4; do
                [ "$i" = "$LEADER" ] || [ "$i" = "$SECOND" ] && continue
                s=$(seq_of "$i")
                if [ "$s" != "DOWN" ] && [ "$s" -gt "$WANT" ] 2>/dev/null; then
                    bad "$name: survivor node-$i advanced past expected ceiling (seq=$s)"
                fi
            done
            ok "$name: halted safely below quorum"
            thaw "$LEADER"; thaw "$SECOND"
            wait_healthy "$LEADER" 120 && wait_healthy "$SECOND" 120 \
                && ok "$name: both healed" || bad "$name: heal failed"
            converge_all "$WANT"
            ;;
        A5)
            crash "$victim"
            info "node-$victim crashed; restarting"
            revive "$victim"
            wait_healthy "$victim" 120 || { bad "$name: node-$victim failed to restart"; continue; }
            # Propose immediately — races its state-transfer catch-up.
            LEADER=$(propose_anywhere "$name-$SCENARIO")
            [ -n "$LEADER" ] || { bad "$name: propose refused during catch-up race"; continue; }
            info "racing propose accepted on node-$LEADER"
            converge_all "$WANT"
            ;;
        A6)
            LEADER=$(propose_anywhere "$name-$SCENARIO")
            [ -n "$LEADER" ] || { bad "$name: propose refused on all nodes"; continue; }
            info "proposed on node-$LEADER; flapping node-$victim"
            for _ in 1 2 3 4 5; do
                freeze "$victim"; sleep 2; thaw "$victim"; sleep 1
            done
            wait_healthy "$victim" 120 || bad "$name: node-$victim unhealthy after flapping"
            converge_all "$WANT"
            ;;
    esac

    # End-of-scenario invariants.
    ensure_all_healthy
    L=$(for i in 1 2 3 4; do
            curl -sf -m 3 "http://127.0.0.1:$(port "$i")/health" | python3 -c '
import json,sys
try: g=json.load(sys.stdin)["governance_lifecycle"]; print("v=%s p=%s q=%s m=%s"%(g["validators"],g["pool"],g["quorum"],g["margin"]))
except Exception: print("DOWN")'
        done | sort -u | wc -l | tr -d ' ')
    [ "$L" = "1" ] && ok "$name: lifecycle unified" || bad "$name: lifecycle diverged"
    check_no_fork
done <<< "$SCHEDULE"

echo ""
echo "=================================================================="
echo "  RESULT: $PASS_N passed, $FAIL_N failed (seed=$SEED)"
echo "=================================================================="
[ "$FAIL_N" -eq 0 ]
