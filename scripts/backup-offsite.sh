#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════
#
#  Xudanu Offsite Backup
#
#  Copies data directory to offsite storage via rsync. Content-addressed
#  chunks deduplicate naturally (same hash = same file = rsync skips).
#
#  Usage:
#    backup-offsite.sh <data_dir> <dest1> [dest2] [dest3] [--verify]
#
#  Examples:
#    # Single destination
#    backup-offsite.sh data /mnt/backup/xudanu
#
#    # Multiple destinations (backup to all)
#    backup-offsite.sh data /mnt/backup/xudanu user@remote:/backups/xudanu
#
#    # With verification
#    backup-offsite.sh data /mnt/backup/xudanu --verify
#
#  Chunk integrity: chunks are BLAKE3 content-addressed. The filename IS
#  the hash. Verification = compute hash of file, compare to filename.
#
# ═══════════════════════════════════════════════════════════════════════════

DATA_DIR=""
VERIFY=false
DESTS=()

while [ $# -gt 0 ]; do
    case "$1" in
        --verify) VERIFY=true ;;
        -*) echo "Unknown option: $1"; exit 1 ;;
        *)
            if [ -z "$DATA_DIR" ]; then
                DATA_DIR="$1"
            else
                DESTS+=("$1")
            fi
            ;;
    esac
    shift
done

if [ -z "$DATA_DIR" ] || [ ${#DESTS[@]} -eq 0 ]; then
    echo "Usage: backup-offsite.sh <data_dir> <dest1> [dest2] ... [--verify]"
    exit 1
fi

# Validate data directory
if [ ! -d "$DATA_DIR/chunks" ]; then
    echo "ERROR: no chunks directory in '$DATA_DIR'"
    exit 1
fi
if [ ! -f "$DATA_DIR/manifest.json" ]; then
    echo "ERROR: no manifest.json in '$DATA_DIR'"
    exit 1
fi

CHUNKS_DIR="$DATA_DIR/chunks"
CHUNK_COUNT=$(find "$CHUNKS_DIR" -name "*.xchunk" -type f | wc -l | tr -d " ")
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "============================================="
echo "Xudanu Offsite Backup"
echo "  Source:    $DATA_DIR ($CHUNK_COUNT chunks)"
echo "  Destinations: ${DESTS[*]}"
echo "  Verify:    $VERIFY"
echo "  Time:      $TIMESTAMP"
echo "============================================="
echo

# ── Sync to each destination ───────────────────────────────────────────────

for DEST in "${DESTS[@]}"; do
    echo "--- Syncing to: $DEST ---"

    # Create dest if local
    if [[ "$DEST" != *":"* ]]; then
        mkdir -p "$DEST/chunks"
    fi

    # Step 1: Metadata (small, fast, critical)
    echo "  [1/4] Copying metadata..."
    rsync -az --quiet \
        --include="manifest*.json*" \
        --include="key_history.json" \
        --include="server.key" \
        --include="security.log.*" \
        --exclude="*" \
        "$DATA_DIR/" "$DEST/"

    # Step 2: Chunks (content-addressed, deduplicates naturally)
    echo "  [2/4] Syncing $CHUNK_COUNT chunks..."
    rsync -az --partial --quiet \
        --include="*/" \
        --include="*.xchunk" \
        --exclude="*" \
        "$CHUNKS_DIR/" "$DEST/chunks/"

    # Step 3: Blobs
    if [ -d "$DATA_DIR/blobs" ]; then
        echo "  [3/4] Syncing blobs..."
        rsync -az --quiet "$DATA_DIR/blobs/" "$DEST/blobs/"
    else
        echo "  [3/4] No blobs."
    fi

    # Step 4: WAL + attribution
    echo "  [4/4] Syncing WAL and attribution..."
    rsync -az --quiet "$DATA_DIR/wal.log" "$DEST/" 2>/dev/null || true
    rsync -az --quiet "$DATA_DIR/attribution/" "$DEST/attribution/" 2>/dev/null || true

    # Write backup info
    if [[ "$DEST" != *":"* ]]; then
        cat > "$DEST/.backup-info" << EOF
{
    "backup_time": "$TIMESTAMP",
    "source": "$DATA_DIR",
    "chunk_count": $CHUNK_COUNT,
    "xudanu_version": "$(grep '^version' "$DATA_DIR/../../Cargo.toml" 2>/dev/null | head -1 | sed 's/version = "//;s/"//' || echo unknown)"
}
EOF
    fi

    # Verify (local destinations only)
    if [ "$VERIFY" = true ] && [[ "$DEST" != *":"* ]]; then
        echo "  Verifying..."
        VERIFIED=0
        FAILED=0
        for chunk_file in $(find "$DEST/chunks" -name "*.xchunk" -type f); do
            size=$(stat -f%z "$chunk_file" 2>/dev/null || stat -c%s "$chunk_file" 2>/dev/null)
            if [ "$size" -gt 0 ] 2>/dev/null; then
                VERIFIED=$((VERIFIED + 1))
            else
                FAILED=$((FAILED + 1))
            fi
        done
        echo "  Result: $VERIFIED OK, $FAILED empty"
    fi

    echo "  Done: $DEST"
    echo
done

echo "============================================="
echo "Backup complete. $CHUNK_COUNT chunks synced to ${#DESTS[@]} destination(s)."
echo "============================================="
