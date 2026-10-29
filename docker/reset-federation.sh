#!/bin/bash
# reset-federation.sh — wipe the docker federation test bed and
# re-bootstrap it with fresh keys.
#
# Why this exists: a `docker compose down -v` wipes the named volumes,
# so every node generates a NEW Ed25519 identity on next boot. The
# compose file pins genesis trust via --pin-members /data/pinned-members.json,
# and the old pin file lists server ids that no longer exist — with an
# empty endorsement pool nobody can endorse the first joiner, so the
# mesh never forms. Regenerating the pin file from the new keys breaks
# that chicken-and-egg (same flow scripts/federation.sh uses natively).
#
# Flow:
#   1. down -v                     (containers + named volumes gone)
#   2. placeholder pin file, up    (nodes boot, generate keys, log them)
#   3. read key_history.json out of each container, regenerate the pin file
#   4. down + up --build           (volumes persist: same keys, now pinned)
#   5. health gate: all nodes up, governance lifecycle unified at n=4
#
# Passphrases come from docker/.env (XUDANU_ADMIN_PASSPHRASE is wired
# per-node in docker-compose.yml and installed at every boot).
#
# Usage:  ./reset-federation.sh          (from the docker/ directory)
set -euo pipefail
cd "$(dirname "$0")"

NODES=4
BASE_PORT=8081

# --- fail fast: the suite needs admin login on every node -----------
[ -f .env ] || { echo "Error: docker/.env not found (admin passphrases live there)"; exit 1; }
for i in $(seq 1 "$NODES"); do
    grep -q "^NODE${i}_ADMIN_PASSPHRASE=" .env || {
        echo "Error: NODE${i}_ADMIN_PASSPHRASE missing from docker/.env"
        exit 1
    }
done

echo "== stopping cluster and wiping volumes"
docker compose down -v

echo "== phase 1: boot with empty pins (nodes generate fresh keys)"
echo '[]' > pinned-members.json
docker compose up -d --no-build

echo "== phase 2: waiting for key generation"
for i in $(seq 1 "$NODES"); do
    ok=""
    for _ in $(seq 1 60); do
        cid=$(docker compose ps -q "node$i")
        [ -n "$cid" ] && docker exec "$cid" test -f /data/key_history.json 2>/dev/null && {
            ok=1
            break
        }
        sleep 1
    done
    [ -n "$ok" ] || { echo "Error: node$i never wrote /data/key_history.json"; exit 1; }
    echo "   node$i: keys ready"
done

echo "== phase 3: regenerating pinned-members.json"
python3 - <<'PYGEN'
import json, subprocess, sys

members = []
for i in range(1, 5):
    cid = subprocess.check_output(
        ["docker", "compose", "ps", "-q", f"node{i}"], text=True
    ).strip()
    kh = json.loads(subprocess.check_output(["docker", "exec", cid, "cat", "/data/key_history.json"]))
    vk = bytes(kh["entries"][0]["verifying_key_bytes"]).hex()
    if kh["server_id"] != vk[:16]:
        sys.exit(f"node{i}: server_id {kh['server_id']} != key prefix {vk[:16]}")
    members.append({
        "server_id": kh["server_id"],
        "verifying_key_hex": vk,
        "recovery_key_hex": "",
    })
with open("pinned-members.json", "w") as f:
    json.dump(members, f, indent=2)
print("   pinned:", ", ".join(m["server_id"] for m in members))
PYGEN

echo "== phase 4: restart pinned (volumes persist, so keys are stable)"
docker compose down
docker compose up -d --build

echo "== phase 5: health gate"
for i in $(seq 1 "$NODES"); do
    port=$((BASE_PORT + i - 1))
    ok=""
    for _ in $(seq 1 60); do
        curl -sf -m 2 "http://127.0.0.1:$port/health" >/dev/null 2>&1 && { ok=1; break; }
        sleep 1
    done
    [ -n "$ok" ] || { echo "Error: node$i (:$port) never became healthy"; exit 1; }
    echo "   node$i (:$port) healthy"
done

# Governance needs the post-boot sync to settle before lifecycle unifies
# (WS may starve during the sweep; HTTP /health answers throughout).
ok=""
for _ in $(seq 1 120); do
    n=$(curl -sf -m 2 "http://127.0.0.1:$BASE_PORT/health" 2>/dev/null \
        | python3 -c 'import json,sys; print(json.load(sys.stdin)["governance_lifecycle"]["validators"])' 2>/dev/null || echo 0)
    [ "$n" = "$NODES" ] && { ok=1; break; }
    sleep 1
done
[ -n "$ok" ] || { echo "Error: governance lifecycle never unified at n=$NODES"; exit 1; }
echo "   governance lifecycle unified (validators=$NODES)"
echo "== reset complete"
