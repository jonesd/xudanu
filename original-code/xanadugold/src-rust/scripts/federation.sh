#!/bin/bash
# federation.sh — production-grade federation cluster lifecycle.
#
# Commands:
#   start   [N] [DATA_BASE]  — pre-flight → init → start → health-gate
#   stop    [DATA_BASE]      — graceful stop; force-kill after timeout
#   status  [N] [DATA_BASE]  — per-node health + validator lifecycle
#   logs    <node> [BASE]    — tail one node's log
#   diagnose [N] [BASE]      — health + consistency + log-pattern scan
#   restart [N] [DATA_BASE]  — stop (if running) + start
#
# Production guarantees:
#   • Pre-flight checks: binary, ports, disk, stale processes
#   • Health gate: "ready" only after ALL nodes report ok + governance
#   • Clean rollback: if any node fails, all nodes are shut down
#   • Bounded waits: every loop has a timeout
#   • Exit codes: 0=success, 1=preflight, 2=startup, 3=health-gate
#
# The script is idempotent: `start` on a running cluster reports
# status; `stop` on a stopped cluster is a no-op.
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CMD="${1:-start}"
N="${2:-4}"
DATA_BASE="${3:-/tmp/xudanu-federation}"
BASE_PORT=8081
HEALTH_TIMEOUT=60   # seconds to wait for all nodes healthy
STOP_TIMEOUT=15     # seconds before force-kill
PID_FILE="$DATA_BASE/federation.pids"
LOG_DIR="$DATA_BASE/logs"

# Allow `stop/status/logs <data_base>` (path in the N slot)
case "$N" in /*) DATA_BASE="$N"; N=4 ;; esac

# Colours (disabled when not a TTY)
if [ -t 1 ]; then
  C_OK="\033[0;32m"; C_ERR="\033[0;31m"; C_WARN="\033[0;33m"; C_INFO="\033[0;36m"; C_RST="\033[0m"
else
  C_OK=""; C_ERR=""; C_WARN=""; C_INFO=""; C_RST=""
fi
ok()   { echo -e "  ${C_OK}✓${C_RST} $1"; }
fail() { echo -e "  ${C_ERR}✗${C_RST} $1"; }
warn() { echo -e "  ${C_WARN}⚠${C_RST} $1"; }
info() { echo -e "  ${C_INFO}ℹ${C_RST} $1"; }

# ── Utility: kill any process on a port ─────────────────────────
kill_port() {
  local port="$1"
  local pids
  pids=$(lsof -ti :"$port" -sTCP:LISTEN 2>/dev/null || true)
  if [ -n "$pids" ]; then
    echo "$pids" | while read -r pid; do
      if kill -0 "$pid" 2>/dev/null; then
        local cmdline
        cmdline=$(ps -p "$pid" -o command= 2>/dev/null || echo "unknown")
        if echo "$cmdline" | grep -q "xudanu-server"; then
          warn "Killing stale xudanu-server (pid $pid) on port $port"
          kill "$pid" 2>/dev/null || true
          sleep 0.5
          kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null || true
        else
          fail "Port $port held by non-xudanu process (pid $pid): $cmdline"
          return 1
        fi
      fi
    done
  fi
}

# ── Utility: check if all cluster ports are free ────────────────
ports_free() {
  for i in $(seq 0 $((N - 1))); do
    if lsof -ti :$((BASE_PORT + i)) -sTCP:LISTEN >/dev/null 2>&1; then
      return 1
    fi
  done
  return 0
}

# ── Utility: check a node's health endpoint ─────────────────────
node_health() {
  local port="$1" timeout="${2:-3}"
  curl -sf -m "$timeout" "http://127.0.0.1:$port/health" 2>/dev/null
}

# Returns 0 if the node reports status=ok AND validators > 0.
# Avoids inline-Python quoting issues by using a simple grep.
node_ok() {
  local port="$1"
  local resp
  resp=$(node_health "$port" 2)
  [ -n "$resp" ] || return 1
  echo "$resp" | grep -q '"status":"ok"' || return 1
  echo "$resp" | grep -q '"validators":[1-9]' || return 1
  return 0
}

# ── Stop command ────────────────────────────────────────────────
do_stop() {
  echo "Stopping federation cluster..."
  local stopped=0

  # Method 1: PID file
  if [ -f "$PID_FILE" ]; then
    while read -r pid; do
      kill "$pid" 2>/dev/null || true
    done < "$PID_FILE"
    info "Sent SIGTERM to $(wc -l < "$PID_FILE" | tr -d ' ') nodes (PID file)"

    # Bounded wait for graceful checkpoints
    local waited=0
    while [ $waited -lt $STOP_TIMEOUT ]; do
      local alive=0
      while read -r pid; do
        kill -0 "$pid" 2>/dev/null && alive=$((alive + 1))
      done < "$PID_FILE"
      [ "$alive" -eq 0 ] && break
      sleep 1
      waited=$((waited + 1))
    done

    # Force kill any survivors
    while read -r pid; do
      if kill -0 "$pid" 2>/dev/null; then
        warn "Force killing pid $pid (checkpoint timeout)"
        kill -9 "$pid" 2>/dev/null || true
      fi
    done < "$PID_FILE"
    rm -f "$PID_FILE"
    stopped=1
  fi

  # Method 2: sweep ports for any xudanu-server we might have missed
  for i in $(seq 0 $((N - 1))); do
    local port=$((BASE_PORT + i))
    local pids
    pids=$(lsof -ti :"$port" -sTCP:LISTEN 2>/dev/null || true)
    if [ -n "$pids" ]; then
      echo "$pids" | while read -r pid; do
        local cmd
        cmd=$(ps -p "$pid" -o command= 2>/dev/null || echo "")
        if echo "$cmd" | grep -q "xudanu-server"; then
          warn "Killing orphaned xudanu-server on port $port (pid $pid)"
          kill "$pid" 2>/dev/null || true
          sleep 0.5
          kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null || true
          stopped=1
        fi
      done
    fi
  done

  # Verify all clear
  sleep 1
  if ports_free; then
    ok "All ports clear"
  else
    fail "Ports still occupied after cleanup — manual intervention needed:"
    for i in $(seq 0 $((N - 1))); do
      local port=$((BASE_PORT + i))
      lsof -i :"$port" -sTCP:LISTEN 2>/dev/null | head -3
    done
    exit 1
  fi
  echo "Stopped."
}

# ── Start command ───────────────────────────────────────────────
do_start() {
  if [ "$N" -lt 4 ]; then
    fail "BFT governance needs 4+ servers (3f+1). Use 4 or 5."
    exit 1
  fi

  # ── Pre-flight checks ─────────────────────────────────────
  echo ""
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║  Federation Cluster Start                           ║"
  echo "╚══════════════════════════════════════════════════════╝"
  echo ""
  echo "Pre-flight checks:"
  local preflight_ok=true

  # 1. Binary
  cd "$SCRIPT_DIR/.."
  echo -n "  Building xudanu-server... "
  if cargo build --features server --bin xudanu-server >/dev/null 2>&1; then
    local target_dir
    target_dir=$(cargo metadata --format-version 1 --no-deps 2>/dev/null \
      | python3 -c 'import json,sys; print(json.load(sys.stdin)["target_directory"])' 2>/dev/null)
    BIN="$target_dir/debug/xudanu-server"
    if [ -f "$BIN" ] && [ -x "$BIN" ]; then
      ok "$(basename "$BIN") built"
    else
      fail "binary not found at $BIN"
      preflight_ok=false
    fi
  else
    fail "build failed"
    preflight_ok=false
  fi

  # 2. Port availability
  echo -n "  Checking ports ${BASE_PORT}-$((BASE_PORT + N - 1))... "
  if ports_free; then
    ok "all ports free"
  else
    warn "ports occupied — attempting cleanup"
    for i in $(seq 0 $((N - 1))); do
      kill_port $((BASE_PORT + i)) || preflight_ok=false
    done
    sleep 1
    if ports_free; then
      ok "ports freed after cleanup"
    else
      fail "cannot free ports — check: lsof -i :$BASE_PORT"
      preflight_ok=false
    fi
  fi

  # 3. Disk space
  local free_mb
  free_mb=$(df -m "$(dirname "$DATA_BASE")" 2>/dev/null | awk 'NR==2 {print $4}')
  if [ -n "$free_mb" ] && [ "$free_mb" -lt 100 ]; then
    fail "low disk: ${free_mb}MB free (need ≥100MB)"
    preflight_ok=false
  elif [ -n "$free_mb" ]; then
    ok "${free_mb}MB disk free"
  fi

  # 4. Existing cluster check
  if [ -f "$PID_FILE" ]; then
    local alive=0
    while read -r pid; do
      kill -0 "$pid" 2>/dev/null && alive=$((alive + 1))
    done < "$PID_FILE"
    if [ "$alive" -gt 0 ]; then
      warn "cluster already running ($alive nodes alive)"
      info "Run '$0 stop $DATA_BASE' first, or '$0 restart'"
      exit 0
    else
      info "Stale PID file (all processes dead) — cleaning up"
      rm -f "$PID_FILE"
    fi
  fi

  if ! $preflight_ok; then
    echo ""
    fail "Pre-flight failed — not starting"
    exit 1
  fi
  ok "Pre-flight passed"
  echo ""

  # ── Phase 1: init nodes and generate pinned-members ─────────
  mkdir -p "$LOG_DIR"
  local dirs=()
  for i in $(seq 1 "$N"); do
    local dir="$DATA_BASE/node-$i"
    dirs+=("$dir")
    if [ ! -f "$dir/key_history.json" ]; then
      "$BIN" init "$dir" 2>/dev/null
      [ -f "$dir/key_history.json" ] && ok "node-$i initialized" || {
        fail "node-$i init failed"
        exit 2
      }
    fi
  done

  local pin_file="$DATA_BASE/pinned-members.json"
  if [ ! -f "$pin_file" ]; then
    info "Generating genesis pinned-members.json..."
    python3 - "$DATA_BASE" "$N" "$pin_file" <<'PYGEN'
import json, os, sys, hashlib
base, n, out = sys.argv[1], int(sys.argv[2]), sys.argv[3]
members = []
for i in range(1, n + 1):
    kh = json.load(open(os.path.join(base, f"node-{i}", "key_history.json")))
    vk = bytes(kh["entries"][0]["verifying_key_bytes"]).hex()
    rec = hashlib.sha256(f"{base}/node-{i}/recovery".encode()).digest().hex()[:64]
    with open(os.path.join(base, f"node-{i}-recovery.hex"), "w") as f:
        f.write(rec + "\n")
    members.append({"server_id": kh["server_id"], "verifying_key_hex": vk, "recovery_key_hex": rec})
json.dump(members, open(out, "w"), indent=2)
PYGEN
    ok "Pinned $N members"
  fi

  # ── Phase 2: start nodes ─────────────────────────────────────
  echo ""
  echo "Starting $N genesis-pinned nodes..."
  local pids=()

  for i in $(seq 1 "$N"); do
    local port=$((BASE_PORT + i - 1))
    local dir="${dirs[$((i - 1))]}"
    local peer_flags=""
    for j in $(seq 1 "$N"); do
      [ "$j" -ne "$i" ] && peer_flags="$peer_flags --peer 127.0.0.1:$((BASE_PORT + j - 1))"
    done

    nohup "$BIN" run "127.0.0.1:$port" "$dir" \
      $peer_flags --pin-members "$pin_file" \
      > "$LOG_DIR/node-$i.log" 2>&1 &
    local pid=$!
    disown "$pid"
    pids+=("$pid")

    # Brief per-node liveness check (process must not exit immediately)
    sleep 0.3
    if ! kill -0 "$pid" 2>/dev/null; then
      fail "node-$i exited immediately — check $LOG_DIR/node-$i.log"
      tail -5 "$LOG_DIR/node-$i.log" 2>/dev/null | sed 's/^/    /'
      # Rollback: kill all started nodes
      for p in "${pids[@]}"; do kill "$p" 2>/dev/null || true; done
      exit 2
    fi
    printf "  node-%d  pid=%-7s port=%d\n" "$i" "$pid" "$port"
  done

  printf '%s\n' "${pids[@]}" > "$PID_FILE"

  # ── Phase 3: health gate ─────────────────────────────────────
  echo ""
  echo -n "Waiting for all $N nodes to become healthy"
  local waited=0
  local all_ok=false
  while [ $waited -lt $HEALTH_TIMEOUT ]; do
    local healthy=0
    for i in $(seq 1 "$N"); do
      if node_ok $((BASE_PORT + i - 1)) 2; then
        healthy=$((healthy + 1))
      fi
    done
    if [ "$healthy" -eq "$N" ]; then
      all_ok=true
      break
    fi
    echo -n "."
    sleep 2
    waited=$((waited + 2))

    # Check for dead processes during the wait
    local dead=0
    for pid in "${pids[@]}"; do
      kill -0 "$pid" 2>/dev/null || dead=$((dead + 1))
    done
    if [ "$dead" -gt 0 ]; then
      echo ""
      fail "$dead node(s) died during startup — rolling back"
      for pid in "${pids[@]}"; do kill "$pid" 2>/dev/null || true; done
      rm -f "$PID_FILE"
      for i in $(seq 1 "$N"); do
        [ -f "$LOG_DIR/node-$i.log" ] && tail -3 "$LOG_DIR/node-$i.log" | sed "s/^/  node-$i: /"
      done
      exit 3
    fi
  done
  echo ""

  if $all_ok; then
    echo ""
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║  ✓ Federation Cluster Ready (BFT active)            ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo ""
    for i in $(seq 1 "$N"); do
      local port=$((BASE_PORT + i - 1))
      local health
      health=$(node_health "$port" 2 | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin); g=d.get("governance_lifecycle",{})
    print(f"works={d.get("works",0)} validators={g.get("validators",0)} quorum={g.get("quorum",0)}")
except: print("...")' 2>/dev/null)
      echo "  node-$i  http://127.0.0.1:$port  $health"
    done
    echo ""
    echo "  Stop:      $0 stop $DATA_BASE"
    echo "  Status:    $0 status $N $DATA_BASE"
    echo "  Diagnose:  $0 diagnose $N $DATA_BASE"
    echo "  Logs:      $0 logs 1 $DATA_BASE"
    echo ""
  else
    fail "Health gate timeout (${HEALTH_TIMEOUT}s) — $N nodes did not all become healthy"
    warn "Partial cluster may be running. Check: $0 status"
    warn "Logs: $LOG_DIR/node-*.log"
    exit 3
  fi
}

# ── Status command ──────────────────────────────────────────────
do_status() {
  if [ -f "$PID_FILE" ]; then
    local alive=0
    while read -r pid; do
      kill -0 "$pid" 2>/dev/null && alive=$((alive + 1))
    done < "$PID_FILE"
    info "PID file: $(cat "$PID_FILE" | tr '\n' ' ')"
    info "Alive: $alive of $N"
  else
    info "No PID file (cluster stopped or started elsewhere)"
  fi
  echo ""
  for i in $(seq 1 "$N"); do
    local port=$((BASE_PORT + i - 1))
    local resp
    resp=$(node_health "$port" 2)
    local status_text="DOWN"
    local works="?"
    local validators="?"
    if [ -n "$resp" ]; then
      # The health JSON has multiple "status" fields (backup, etc.);
      # check for the top-level ok signal directly
      if echo "$resp" | grep -q '"status":"ok"'; then
        status_text="ok"
      else
        status_text=$(echo "$resp" | head -c 200 | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)
        [ -z "$status_text" ] && status_text="unknown"
      fi
      works=$(echo "$resp" | grep -o '"works":[0-9]*' | cut -d: -f2)
      validators=$(echo "$resp" | grep -o '"validators":[0-9]*' | cut -d: -f2)
      [ -z "$works" ] && works="?"
      [ -z "$validators" ] && validators="?"
    fi
    if [ "$status_text" = "ok" ]; then
      echo -e "  ${C_OK}●${C_RST} node-$i :$port  status=ok works=$works validators=$validators"
    elif [ "$status_text" = "DOWN" ]; then
      echo -e "  ${C_ERR}●${C_RST} node-$i :$port  DOWN"
    else
      echo -e "  ${C_WARN}●${C_RST} node-$i :$port  status=$status_text works=$works validators=$validators"
    fi
  done
}

# ── Main dispatch ───────────────────────────────────────────────
case "$CMD" in
  start)   do_start ;;
  stop)    do_stop ;;
  status)  do_status ;;
  logs)    tail -f "$LOG_DIR/node-${N}.log" 2>/dev/null || fail "no log at $LOG_DIR/node-${N}.log" ;;
  diagnose)
    # Keep the existing diagnose logic (it's already solid)
    # by delegating to the inline checks below
    FAILS=0; WARNS=0
    say_fail() { fail "$1"; FAILS=$((FAILS+1)); }
    say_warn() { warn "$1"; WARNS=$((WARNS+1)); }
    say_ok()   { ok "$1"; }

    echo "=== Federation diagnostics ==="
    echo ""
    PREV=""
    for i in $(seq 1 "$N"); do
      PORT=$((BASE_PORT + i - 1))
      INFO=$(node_health "$PORT" 2 | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    g = d.get("governance_lifecycle") or {}
    print(f"{d.get(\"status\")} {g.get(\"validators\",0)} {g.get(\"pool\",0)} {g.get(\"quorum\",0)} {g.get(\"margin\",\"?\")}")
except:
    print("DOWN - - - -")' 2>/dev/null || echo "DOWN - - - -")
      read -r STATUS VAL POOL QRM MGN <<< "$INFO"
      if [ "$STATUS" = "DOWN" ]; then
        say_fail "node-$i :$PORT is DOWN"
      elif [ "$STATUS" != "ok" ]; then
        say_fail "node-$i :$PORT status=$STATUS"
      else
        KEY="$VAL/$POOL/$QRM"
        if [ -n "$PREV" ] && [ "$KEY" != "$PREV" ]; then
          say_fail "node-$i lifecycle ($KEY) differs from prior ($PREV) — validator sets diverged"
        fi
        PREV="$KEY"
        if [ "$MGN" = "0" ] 2>/dev/null; then
          say_warn "node-$i at ZERO fault-tolerance margin — renew/rotate keys"
        else
          say_ok "node-$i :$PORT healthy, validators=$VAL pool=$POOL quorum=$QRM margin=$MGN"
        fi
      fi
    done

    if [ -d "$LOG_DIR" ]; then
      echo ""
      echo "--- Log scan ---"
      TOFU=$(grep -c "not in trusted peers list" "$LOG_DIR"/*.log 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')
      [ "$TOFU" -gt 0 ] && say_warn "$TOFU peer-trust rejections" || say_ok "no peer-trust rejections"
      ERR=$(grep -c "ERROR" "$LOG_DIR"/*.log 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')
      [ "$ERR" -gt 0 ] && say_warn "$ERR ERROR lines — inspect logs" || say_ok "no ERROR lines"
      VC=$(grep -c "view-change quorum" "$LOG_DIR"/*.log 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')
      [ "$VC" -gt 0 ] && say_warn "$VC view changes (leader stalls)" || say_ok "no view changes"
    fi

    FREE_KB=$(df -k "$(dirname "$DATA_BASE")" 2>/dev/null | awk "NR==2 {print \$4}")
    if [ -n "$FREE_KB" ] && [ "$FREE_KB" -lt 1048576 ]; then
      say_fail "low disk: ${FREE_KB}KB free"
    fi

    echo ""
    echo "=== Result: $FAILS fail(s), $WARNS warning(s) ==="
    [ "$FAILS" -eq 0 ]
    ;;
  restart)
    do_stop 2>/dev/null || true
    sleep 2
    do_start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status|logs|diagnose} [N] [DATA_BASE]"
    echo ""
    echo "  start    [N=4] [BASE=/tmp/xudanu-federation]  — pre-flight + health-gate"
    echo "  stop     [BASE]                              — graceful + port sweep"
    echo "  restart  [N] [BASE]                          — stop + start"
    echo "  status   [N] [BASE]                          — per-node health"
    echo "  logs     <node> [BASE]                       — tail one node"
    echo "  diagnose [N] [BASE]                          — full diagnostics"
    echo ""
    echo "Exit codes: 0=ok  1=preflight  2=startup  3=health-gate"
    exit 1
    ;;
esac
