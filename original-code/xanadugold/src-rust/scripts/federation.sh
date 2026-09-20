#!/bin/bash
# federation.sh — operate a local federated xudanu cluster.
#
# Usage:
#   ./scripts/federation.sh start [N] [DATA_BASE]   # default: 4 nodes, /tmp/xudanu-federation
#   ./scripts/federation.sh stop  [DATA_BASE]       # graceful stop (SIGTERM + checkpoint wait)
#   ./scripts/federation.sh status [DATA_BASE]      # per-node health + validator lifecycle
#   ./scripts/federation.sh logs N [DATA_BASE]      # tail node N's log
#
# N defaults to 4 — the BFT minimum (3f+1). The governance plane
# refuses rounds below 4 validators; 3-node clusters are legacy.
#
# Each node is genesis-pinned: on first start this script extracts
# every node's verifying key (generated at init), generates per-node
# OFFLINE recovery keys, writes pinned-members.json, and starts every
# server with --pin-members. Peer admission is strict (no TOFU) and
# the validator set is unified from the first round.
#
# Coexistence: a federation cluster is JUST N independent xudanu
# servers. They happily run alongside a single-player server (e.g.
# the dev server on 8080) as long as ports and data dirs differ.
#
# Logs: per-node console log at $DATA_BASE/logs/node-N.log (tee'd),
# plus each node's structured security/audit log under its data dir
# ($DATA_BASE/node-N/security.log.<date>).

set -e

cd "$(dirname "$0")/.."

CMD="${1:-start}"
N="${2:-4}"
DATA_BASE="${3:-/tmp/xudanu-federation}"

# Allow `stop/status/logs <data_base>` (path in the N slot) as well as
# the positional `start N <data_base>` form.
case "$N" in
/*) DATA_BASE="$N"; N=4 ;;
esac
BASE_PORT=8081
PID_FILE="$DATA_BASE/federation.pids"
LOG_DIR="$DATA_BASE/logs"

case "$CMD" in
stop)
    if [ ! -f "$PID_FILE" ]; then
        echo "No PID file at $PID_FILE — cluster not started via this script?"
        echo "Fallback: pkill -f \"xudanu-server run 127.0.0.1:$BASE_PORT\""
        exit 1
    fi
    echo "Stopping federation cluster ($(wc -l < "$PID_FILE" | tr -d ' ') nodes)..."
    while read -r pid; do
        kill "$pid" 2>/dev/null || true
    done < "$PID_FILE"
    echo "  Waiting for graceful checkpoints (SIGTERM)..."
    while read -r pid; do
        for i in $(seq 1 30); do
            kill -0 "$pid" 2>/dev/null || break
            sleep 0.5
        done
        if kill -0 "$pid" 2>/dev/null; then
            echo "  Force killing $pid"
            kill -9 "$pid" 2>/dev/null || true
        fi
    done < "$PID_FILE"
    rm -f "$PID_FILE"
    echo "Stopped."
    ;;

status)
    if [ -f "$PID_FILE" ]; then
        echo "PID file: $(cat "$PID_FILE" | tr '\n' ' ')"
        alive=0
        while read -r pid; do
            kill -0 "$pid" 2>/dev/null && alive=$((alive + 1))
        done < "$PID_FILE"
        echo "Alive: $alive"
    else
        echo "No PID file (cluster stopped or started elsewhere)."
    fi
    echo ""
    for i in $(seq 1 "$N"); do
        PORT=$((BASE_PORT + i - 1))
        INFO=$(curl -sf -m 2 "http://127.0.0.1:$PORT/health" 2>/dev/null | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    g = d.get("governance_lifecycle") or {}
    print("status=%s works=%s validators=%s pool=%s quorum=%s margin=%s" % (
        d.get("status"), d.get("works"),
        g.get("validators"), g.get("pool"), g.get("quorum"), g.get("margin")))
except Exception:
    print("DOWN")' 2>/dev/null || echo "DOWN")
        echo "  node-$i :$PORT -> $INFO"
    done
    ;;

logs)
    NODE="$N"
    tail -f "$LOG_DIR/node-$NODE.log"
    ;;

diagnose)
    # Health + lifecycle consistency + log-pattern scan. Exit nonzero
    # if any CHECK fails; WARNs are advisory.
    FAILS=0; WARNS=0
    say_fail() { echo "[FAIL] $1"; FAILS=$((FAILS+1)); }
    say_warn() { echo "[WARN] $1"; WARNS=$((WARNS+1)); }
    say_ok()   { echo "[ ok ] $1"; }

    echo "=== Federation diagnostics ($DATA_BASE) ==="
    echo ""

    # 1. Node health + lifecycle consistency
    PREV=""
    for i in $(seq 1 "$N"); do
        PORT=$((BASE_PORT + i - 1))
        INFO=$(curl -sf -m 2 "http://127.0.0.1:$PORT/health" 2>/dev/null | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    g = d.get("governance_lifecycle") or {}
    print("%s %s %s %s %s" % (d.get("status"), g.get("validators"),
        g.get("pool"), g.get("quorum"), g.get("margin")))
except Exception:
    print("DOWN - - - -")' 2>/dev/null || echo "DOWN - - - -")
        set -- $INFO
        STATUS=$1; VAL=$2; POOL=$3; QRM=$4; MGN=$5
        if [ "$STATUS" = "DOWN" ]; then
            say_fail "node-$i :$PORT is DOWN"
        elif [ "$STATUS" != "ok" ]; then
            say_fail "node-$i :$PORT status=$STATUS"
        else
            KEY="$VAL/$POOL/$QRM"
            if [ -n "$PREV" ] && [ "$KEY" != "$PREV" ]; then
                say_fail "node-$i lifecycle ($KEY) differs from prior node ($PREV) — validator sets diverged"
            fi
            PREV="$KEY"
            if [ "$MGN" -lt 0 ] 2>/dev/null; then
                say_fail "node-$i governance HALTED (margin=$MGN): voting pool below quorum"
            elif [ "$MGN" = "0" ]; then
                say_warn "node-$i at ZERO fault-tolerance margin (pool=$POOL quorum=$QRM) — renew/rotate keys"
            else
                say_ok "node-$i :$PORT healthy, validators=$VAL pool=$POOL quorum=$QRM margin=$MGN"
            fi
        fi
    done

    # 2. Log pattern scan
    if [ -d "$LOG_DIR" ]; then
        echo ""
        echo "--- Log scan ($LOG_DIR) ---"
        TOFU=$(grep -c "not in trusted peers list" "$LOG_DIR"/*.log 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')
        [ "$TOFU" -gt 0 ] && say_warn "$TOFU peer-trust rejections — check --pin-members/--peer wiring" || say_ok "no peer-trust rejections"
        ZERO=$(grep -c "ZERO fault-tolerance margin" "$LOG_DIR"/*.log 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')
        [ "$ZERO" -gt 0 ] && say_warn "$ZERO zero-margin events logged" || true
        VC=$(grep -c "view-change quorum" "$LOG_DIR"/*.log 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')
        [ "$VC" -gt 0 ] && say_warn "$VC view changes fired (leader stalls or slow rounds)" || say_ok "no view changes needed"
        ERR=$(grep -c "ERROR" "$LOG_DIR"/*.log 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')
        [ "$ERR" -gt 0 ] && say_warn "$ERR ERROR lines in logs — inspect: grep ERROR $LOG_DIR/*.log" || say_ok "no ERROR lines"
    else
        say_warn "no log dir at $LOG_DIR (cluster never started here?)"
    fi

    # 3. Disk space on the data base
    FREE_KB=$(df -k "$DATA_BASE" 2>/dev/null | awk "NR==2 {print \$4}")
    if [ -n "$FREE_KB" ] && [ "$FREE_KB" -lt 1048576 ] 2>/dev/null; then
        say_fail "low disk: ${FREE_KB}KB free under $DATA_BASE (checkpoints will fail)"
    elif [ -n "$FREE_KB" ]; then
        say_ok "$((FREE_KB / 1024))MB free under $DATA_BASE"
    fi

    echo ""
    echo "=== Result: $FAILS fail(s), $WARNS warning(s) ==="
    [ "$FAILS" -eq 0 ]
    ;;

start)
    if [ "$N" -lt 4 ]; then
        echo "Error: BFT governance needs 4+ servers (3f+1). Use 4 or 5."
        exit 1
    fi
    if [ -f "$PID_FILE" ]; then
        echo "Cluster already running (PID file exists): $PID_FILE"
        echo "Run '$0 stop $DATA_BASE' first, or '$0 status $DATA_BASE'."
        exit 1
    fi

    echo "Building xudanu-server..."
    cargo build --features server --bin xudanu-server 2>/dev/null
    BIN="target/debug/xudanu-server"

    mkdir -p "$LOG_DIR"
    PIDS=()
    DIRS=()

    cleanup() {
        echo ""
        echo "Shutting down $N servers..."
        for pid in "${PIDS[@]}"; do
            kill "$pid" 2>/dev/null || true
        done
        echo "  Waiting for checkpoints..."
        for pid in "${PIDS[@]}"; do
            for i in $(seq 1 30); do
                kill -0 "$pid" 2>/dev/null || break
                sleep 0.5
            done
            kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null || true
        done
        rm -f "$PID_FILE"
        echo "Done."
    }
    trap cleanup EXIT INT TERM

    # ── Phase 1: init fresh nodes and collect their verifying keys ──
    for i in $(seq 1 "$N"); do
        DIR="$DATA_BASE/node-$i"
        DIRS+=("$DIR")
        if [ ! -f "$DIR/key_history.json" ]; then
            echo "Initializing node $i -> $DIR"
            "$BIN" init "$DIR" 2>/dev/null
        fi
    done

    PIN_FILE="$DATA_BASE/pinned-members.json"
    if [ ! -f "$PIN_FILE" ]; then
        echo "Generating genesis pinned-members.json (keys extracted from init)..."
        python3 - "$DATA_BASE" "$N" "$PIN_FILE" <<'PYGEN'
import json, os, sys, hashlib

base, n, out_path = sys.argv[1], int(sys.argv[2]), sys.argv[3]
members = []
for i in range(1, n + 1):
    kh = json.load(open(os.path.join(base, f"node-{i}", "key_history.json")))
    vk = bytes(kh["entries"][0]["verifying_key_bytes"]).hex()
    # Demo offline recovery key: deterministic per node, stored next to
    # the data dir so rotation demos can sign with it.
    rec_seed = hashlib.sha256(f"{base}/node-{i}/recovery".encode()).digest()
    rec_hex = rec_seed.hex()[:64]
    with open(os.path.join(base, f"node-{i}-recovery.hex"), "w") as f:
        f.write(rec_hex + "\n")
    members.append({
        "server_id": kh["server_id"],
        "verifying_key_hex": vk,
        "recovery_key_hex": rec_hex,
    })
json.dump(members, open(out_path, "w"), indent=2)
print(f"  pinned {len(members)} members -> {out_path}")
PYGEN
    fi

    echo ""
    echo "Starting $N genesis-pinned federated servers (logs: $LOG_DIR/node-N.log)..."
    echo ""

    # ── Phase 2: run every node with peers + pinning + log capture ──
    for i in $(seq 1 "$N"); do
        PORT=$((BASE_PORT + i - 1))
        DIR="${DIRS[$((i - 1))]}"
        ADDR="127.0.0.1:$PORT"

        PEER_FLAGS=""
        for j in $(seq 1 "$N"); do
            if [ "$j" -ne "$i" ]; then
                PEER_PORT=$((BASE_PORT + j - 1))
                PEER_FLAGS="$PEER_FLAGS --peer 127.0.0.1:$PEER_PORT"
            fi
        done

        echo "  Node $i: $ADDR (peers: $((N - 1)), pinned)"
        "$BIN" run "$ADDR" "$DIR" \
            $PEER_FLAGS --pin-members "$PIN_FILE" 2>&1 \
            | tee "$LOG_DIR/node-$i.log" | sed "s/^/[node-$i] /" &
        PIDS+=($!)
    done
    printf '%s\n' "${PIDS[@]}" > "$PID_FILE"

    echo ""
    echo "=== Federation cluster ready (genesis-pinned, BFT active) ==="
    echo ""
    echo "  PID file:    $PID_FILE"
    echo "  Stop:        ./scripts/federation.sh stop $DATA_BASE"
    echo "  Status:      ./scripts/federation.sh status $N $DATA_BASE"
    echo "  Tail logs:   ./scripts/federation.sh logs 1 $DATA_BASE"
    echo ""
    for i in $(seq 1 "$N"); do
        PORT=$((BASE_PORT + i - 1))
        echo "  Node $i:  http://127.0.0.1:$PORT  (health: /health, UI: /)"
    done
    echo ""
    echo "Validator lifecycle on every node should show:"
    echo "  validators=$N  pool=$N  quorum=$((2 * (N - 1) / 3 + 1))"
    echo ""

    wait
    ;;

*)
    echo "Usage: $0 {start|stop|status|logs|diagnose} [N] [DATA_BASE]"
    echo "  start  [N=4] [DATA_BASE=/tmp/xudanu-federation]"
    echo "  stop   [DATA_BASE]"
    echo "  status [N=4] [DATA_BASE]"
    echo "  logs   <node#> [DATA_BASE]"
    exit 1
    ;;
esac
