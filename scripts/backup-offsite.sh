#!/usr/bin/env bash
set -uo pipefail

# ═══════════════════════════════════════════════════════════════════════════
#
#  Xudanu Offsite Backup (hardened 2026-09-08)
#
#  Nelson's rule: never only one copy. This script moves a data
#  directory to one or more off-machine destinations via rsync.
#  Content-addressed chunks deduplicate naturally (same hash = same
#  file = rsync skips), so repeated runs are incremental.
#
#  Usage:
#    backup-offsite.sh <data_dir> <dest1> [dest2] ... [--dry-run]
#
#  Destinations: local path or user@host:/path (rsync over ssh).
#
#  Error surfacing (all three, pick what you monitor):
#    1. <data_dir>/backup-status.json — written EVERY run (success or
#       fail); the server's /health exposes it as `backup` so any
#       uptime monitor sees staleness.
#    2. stderr + non-zero exit on failure (cron mails it if configured).
#    3. Optional dead-man switch: set XUDANU_BACKUP_PING_URL (e.g. a
#       healthchecks.io ping URL); success pings <url>, failure pings
#       <url>/fail. A dead cron stops pinging entirely — the switch
#       notices THAT too.
#
#  Security notes (see docs/dev/offsite-backup.md for the full model):
#    - Transit is SSH-encrypted; the destination should be a
#      dedicated, restricted account (forced-command rsync key),
#      never a general login.
#    - server.key is passphrase-encrypted at rest and stays so in the
#      backup. The passphrase is NOT in any backup — it lives in your
#      password manager or the deploy compose file, nothing else.
#    - Snapshot-capable destinations (Hetzner Storage Box, ZFS recv,
#      versioned S3) give point-in-time recovery against accidental
#      deletion and ransomware on the primary.
#
# ═══════════════════════════════════════════════════════════════════════════

DATA_DIR=""
DRY_RUN=false
DESTS=()

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=true ;;
        -*) echo "Unknown option: $1" >&2; exit 2 ;;
        *)
            if [ -z "$DATA_DIR" ]; then DATA_DIR="$1"; else DESTS+=("$1"); fi
            ;;
    esac
    shift
done

if [ -z "$DATA_DIR" ] || [ ${#DESTS[@]} -eq 0 ]; then
    echo "Usage: backup-offsite.sh <data_dir> <dest1> [dest2] ... [--dry-run]" >&2
    exit 2
fi

STATUS_FILE="$DATA_DIR/backup-status.json"
LOCK_FILE="/tmp/xudanu-backup.$(echo "$DATA_DIR" | md5sum 2>/dev/null | cut -c1-8 || echo lock).lock"
RSYNC_OPTS=(-az --partial --quiet)
[ "$DRY_RUN" = true ] && RSYNC_OPTS+=(--dry-run)

# ── Validation ────────────────────────────────────────────────────────────
if [ ! -d "$DATA_DIR/chunks" ]; then
    echo "ERROR: no chunks directory in '$DATA_DIR'" >&2
    exit 1
fi
if [ ! -f "$DATA_DIR/root_manifest.json" ] && [ ! -f "$DATA_DIR/manifest.json" ]; then
    echo "ERROR: no root_manifest.json/manifest.json in '$DATA_DIR'" >&2
    exit 1
fi

# ── Single-instance lock (overlap = two rsyncs racing) ───────────────────
if [ -f "$LOCK_FILE" ] && kill -0 "$(cat "$LOCK_FILE" 2>/dev/null)" 2>/dev/null; then
    echo "ERROR: another backup is still running (lock $LOCK_FILE)" >&2
    exit 3
fi
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

write_status() {
    # write_status <overall-status> <detail>
    local status="$1" detail="$2" dest_results="$3"
    local ts chunk_count
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    chunk_count=$(find "$DATA_DIR/chunks" -name "*.xchunk" -type f 2>/dev/null | wc -l | tr -d " ")
    cat > "$STATUS_FILE" << EOF
{
  "last_run": "$ts",
  "status": "$status",
  "detail": "$detail",
  "chunk_count": $chunk_count,
  "destinations": $dest_results
}
EOF
}

ping_switch() {
    if [ -n "${XUDANU_BACKUP_PING_URL:-}" ]; then
        curl -fsS -m 10 --retry 1 "${XUDANU_BACKUP_PING_URL}$1" >/dev/null 2>&1 || true
    fi
}

CHUNK_COUNT=$(find "$DATA_DIR/chunks" -name "*.xchunk" -type f | wc -l | tr -d " ")
echo "Xudanu offsite backup: $DATA_DIR ($CHUNK_COUNT chunks) -> ${DESTS[*]}"

DEST_RESULTS="[]"
OVERALL=ok
OVERALL_DETAIL=""

for DEST in "${DESTS[@]}"; do
    DEST_STATUS=ok
    DEST_DETAIL=""
    echo "--- destination: $DEST"

    run_step() {
        # run_step <label> <rsync args...>
        local label="$1"; shift
        if ! rsync "${RSYNC_OPTS[@]}" "$@"; then
            DEST_STATUS=fail
            DEST_DETAIL="$DEST_DETAIL $label"
            echo "  FAILED: $label" >&2
        fi
    }

    [ "$DEST" != *":"* ] && mkdir -p "$DEST/chunks" 2>/dev/null

    # Bootstrap file FIRST — without root_manifest.json a restore
    # cannot find the root chunk (this was missing before 2026-09-08).
    run_step "bootstrap+manifests" \
        --include="root_manifest.json" --include="manifest*.json*" \
        --include="key_history.json" --include="ticket_nonces.json" \
        --exclude="*" "$DATA_DIR/" "$DEST/"

    # Content-addressed chunks — natural dedup.
    run_step "chunks" \
        --include="*/" --include="*.xchunk" --exclude="*" \
        "$DATA_DIR/chunks/" "$DEST/chunks/"

    # Blobs (images/imported media).
    [ -d "$DATA_DIR/blobs" ] && run_step "blobs" "$DATA_DIR/blobs/" "$DEST/blobs/"

    # Attribution log + OTS anchoring receipts — the provenance story
    # must survive with the content it attests to.
    [ -d "$DATA_DIR/attribution" ] && run_step "attribution" "$DATA_DIR/attribution/" "$DEST/attribution/"
    [ -d "$DATA_DIR/anchoring" ] && run_step "anchoring" "$DATA_DIR/anchoring/" "$DEST/anchoring/"

    # Security logs + WAL + archive.
    run_step "security-logs" \
        --include="security.log*" --exclude="*" "$DATA_DIR/" "$DEST/"
    [ -f "$DATA_DIR/wal.log" ] && run_step "wal" "$DATA_DIR/wal.log" "$DEST/"
    [ -d "$DATA_DIR/archive" ] && run_step "archive" "$DATA_DIR/archive/" "$DEST/archive/"

    # Encrypted server key LAST and separately — it is the one file
    # whose loss is catastrophic and whose exposure is sensitive.
    run_step "server-key" \
        --include="server.key" --exclude="*" "$DATA_DIR/" "$DEST/"

    if [ "$DEST_STATUS" = ok ]; then
        DEST_RESULTS=$(echo "$DEST_RESULTS" | python3 -c "
import json,sys
r=json.load(sys.stdin); r.append({'dest':'$DEST','status':'ok'}); print(json.dumps(r))" 2>/dev/null || echo "[{\"dest\":\"$DEST\",\"status\":\"ok\"}]")
    else
        OVERALL=fail
        OVERALL_DETAIL="$OVERALL_DETAIL [$DEST:$DEST_DETAIL]"
        DEST_RESULTS=$(echo "$DEST_RESULTS" | python3 -c "
import json,sys
r=json.load(sys.stdin); r.append({'dest':'$DEST','status':'fail','failed':'$DEST_DETAIL'}); print(json.dumps(r))" 2>/dev/null || echo "[{\"dest\":\"$DEST\",\"status\":\"fail\"}]")
    fi
done

write_status "$OVERALL" "${OVERALL_DETAIL:-all destinations ok}"

if [ "$OVERALL" = ok ]; then
    echo "Backup complete: $CHUNK_COUNT chunks -> ${#DESTS[@]} destination(s)."
    ping_switch ""
    exit 0
else
    echo "BACKUP FAILED:$OVERALL_DETAIL" >&2
    ping_switch "/fail"
    exit 1
fi
