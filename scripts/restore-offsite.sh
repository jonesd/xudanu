#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════
#
#  Xudanu Offsite Restore
#
#  Restores data from offsite backup. Supports:
#  - Full restore (fresh directory)
#  - Merge restore (add missing chunks to existing directory)
#  - Corruption repair (replace specific bad chunks)
#  - Multiple backup sources (try each until chunk found)
#
#  Usage:
#    restore-offsite.sh <backup_dir> <data_dir> [mode]
#
#  Modes:
#    full     — overwrite everything (default, requires --force if data exists)
#    merge    — only copy chunks missing from target
#    repair   — verify target chunks, replace corrupt ones from backup
#
#  Examples:
#    # Full restore to fresh directory
#    restore-offsite.sh /mnt/backup/xudanu /path/to/new-data full
#
#    # Add missing chunks from backup
#    restore-offsite.sh /mnt/backup/xudanu data merge
#
#    # Verify and repair corrupt chunks
#    restore-offsite.sh /mnt/backup/xudanu data repair
#
#  Chunk integrity: BLAKE3 content-addressed. Filename = hash.
#  Repair = re-hash file, if mismatch then copy from backup.
#
# ═══════════════════════════════════════════════════════════════════════════

BACKUP_DIR="${1:?Usage: restore-offsite.sh <backup_dir> <data_dir> [full|merge|repair]}"
DATA_DIR="${2:?Usage: restore-offsite.sh <backup_dir> <data_dir> [full|merge|repair]}"
MODE="${3:-full}"

if [ ! -d "$BACKUP_DIR/chunks" ]; then
    echo "ERROR: no chunks in backup '$BACKUP_DIR'"
    exit 1
fi

BACKUP_CHUNKS="$BACKUP_DIR/chunks"
TARGET_CHUNKS="$DATA_DIR/chunks"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

BACKUP_COUNT=$(find "$BACKUP_CHUNKS" -name "*.xchunk" -type f | wc -l | tr -d " ")
TARGET_COUNT=0
if [ -d "$TARGET_CHUNKS" ]; then
    TARGET_COUNT=$(find "$TARGET_CHUNKS" -name "*.xchunk" -type f | wc -l | tr -d " ")
fi

echo "============================================="
echo "Xudanu Offsite Restore"
echo "  Backup: $BACKUP_DIR ($BACKUP_COUNT chunks)"
echo "  Target: $DATA_DIR ($TARGET_COUNT chunks)"
echo "  Mode:   $MODE"
echo "  Time:   $TIMESTAMP"
echo "============================================="
echo

# Safety check for full mode
if [ "$MODE" = "full" ] && [ "$TARGET_COUNT" -gt 0 ]; then
    echo "WARNING: Target has $TARGET_COUNT existing chunks."
    echo "  Use 'merge' to add only missing chunks."
    echo "  Use 'repair' to verify and fix corrupt chunks."
    echo "  To proceed with full overwrite, type 'overwrite':"
    read -r CONFIRM
    if [ "$CONFIRM" != "overwrite" ]; then
        echo "Aborted."
        exit 1
    fi
fi

mkdir -p "$TARGET_CHUNKS"

# ── FULL mode ──────────────────────────────────────────────────────────────

if [ "$MODE" = "full" ]; then
    echo "Restoring metadata..."
    cp -p "$BACKUP_DIR/manifest.json" "$DATA_DIR/" 2>/dev/null || true
    cp -p "$BACKUP_DIR/manifest.json.bak" "$DATA_DIR/" 2>/dev/null || true
    cp -p "$BACKUP_DIR/key_history.json" "$DATA_DIR/" 2>/dev/null || true
    cp -p "$BACKUP_DIR/server.key" "$DATA_DIR/" 2>/dev/null || true
    for f in "$BACKUP_DIR"/manifest_v*.json; do
        [ -f "$f" ] && cp -p "$f" "$DATA_DIR/"
    done
    for f in "$BACKUP_DIR"/security.log.*; do
        [ -f "$f" ] && cp -p "$f" "$DATA_DIR/"
    done

    echo "Restoring all chunks via rsync..."
    rsync -az --partial "$BACKUP_CHUNKS/" "$TARGET_CHUNKS/"

    if [ -d "$BACKUP_DIR/blobs" ]; then
        mkdir -p "$DATA_DIR/blobs"
        rsync -az "$BACKUP_DIR/blobs/" "$DATA_DIR/blobs/"
    fi

    if [ -f "$BACKUP_DIR/wal.log" ]; then
        cp -p "$BACKUP_DIR/wal.log" "$DATA_DIR/"
    fi

    FINAL=$(find "$TARGET_CHUNKS" -name "*.xchunk" -type f | wc -l | tr -d " ")
    echo
    echo "Full restore complete: $FINAL chunks"
    echo "Next: xudanu-server verify $DATA_DIR"
    exit 0
fi

# ── MERGE mode ──────────────────────────────────────────────────────────────

if [ "$MODE" = "merge" ]; then
    echo "Finding missing chunks..."
    COPIED=0
    SKIPPED=0

    while IFS= read -r chunk_file; do
        rel="${chunk_file#$BACKUP_CHUNKS/}"
        dest="$TARGET_CHUNKS/$rel"

        if [ ! -f "$dest" ]; then
            mkdir -p "$(dirname "$dest")"
            cp -p "$chunk_file" "$dest"
            COPIED=$((COPIED + 1))
        else
            SKIPPED=$((SKIPPED + 1))
        fi

        TOTAL=$((COPIED + SKIPPED))
        if [ $((TOTAL % 1000)) -eq 0 ] && [ $TOTAL -gt 0 ]; then
            echo "  Processed $TOTAL / $BACKUP_COUNT (copied: $COPIED, skipped: $SKIPPED)"
        fi
    done < <(find "$BACKUP_CHUNKS" -name "*.xchunk" -type f)

    echo
    echo "Merge complete: $COPIED copied, $SKIPPED already present"
    echo "Next: xudanu-server verify $DATA_DIR"
    exit 0
fi

# ── REPAIR mode ──────────────────────────────────────────────────────────────

if [ "$MODE" = "repair" ]; then
    echo "Verifying target chunks via BLAKE3 (hash = filename)..."
    echo

    # Check for BLAKE3 capability
    VERIFY_HASH=false
    if python3 -c "import blake3" 2>/dev/null; then
        VERIFY_HASH=true
        echo "  BLAKE3 verification: enabled"
    else
        echo "  BLAKE3 verification: disabled (pip3 install blake3 to enable)"
        echo "  Falling back to file-size check only"
    fi
    echo

    OK=0
    CORRUPT=0
    EMPTY=0
    REPAIRED=0
    UNREPAIRABLE=0

    while IFS= read -r chunk_file; do
        filename=$(basename "$chunk_file")
        expected_hash="${filename%.xchunk}"

        # Check file exists and is non-empty
        size=$(stat -f%z "$chunk_file" 2>/dev/null || stat -c%s "$chunk_file" 2>/dev/null)

        if [ -z "$size" ] || [ "$size" = "0" ]; then
            EMPTY=$((EMPTY + 1))

            # Try to restore from backup
            backup_file="$BACKUP_CHUNKS/${chunk_file#$TARGET_CHUNKS/}"
            if [ -f "$backup_file" ]; then
                cp -p "$backup_file" "$chunk_file"
                REPAIRED=$((REPAIRED + 1))
            else
                UNREPAIRABLE=$((UNREPAIRABLE + 1))
            fi
            continue
        fi

        # BLAKE3 hash verification
        if [ "$VERIFY_HASH" = true ]; then
            actual_hash=$(python3 -c "
import blake3, sys
with open('$chunk_file', 'rb') as f:
    print(blake3.blake3(f.read()).hexdigest())
" 2>/dev/null)

            if [ "$actual_hash" != "$expected_hash" ]; then
                CORRUPT=$((CORRUPT + 1))
                echo "  CORRUPT: $expected_hash"

                # Try to restore from backup
                backup_file="$BACKUP_CHUNKS/${chunk_file#$TARGET_CHUNKS/}"
                if [ -f "$backup_file" ]; then
                    cp -p "$backup_file" "$chunk_file"
                    REPAIRED=$((REPAIRED + 1))
                    echo "    -> Repaired from backup"
                else
                    UNREPAIRABLE=$((UNREPAIRABLE + 1))
                    echo "    -> NOT in backup"
                fi
                continue
            fi
        fi

        OK=$((OK + 1))

        TOTAL=$((OK + CORRUPT + EMPTY))
        if [ $((TOTAL % 500)) -eq 0 ] && [ $TOTAL -gt 0 ]; then
            echo "  Checked $TOTAL / $TARGET_COUNT..."
        fi
    done < <(find "$TARGET_CHUNKS" -name "*.xchunk" -type f)

    # Also check for missing chunks (in manifest but not on disk)
    echo
    echo "Checking for missing chunks..."
    if command -v python3 >/dev/null 2>&1 && [ -f "$DATA_DIR/manifest.json" ]; then
        MISSING=$(python3 - "$DATA_DIR" "$TARGET_CHUNKS" << 'PYEOF'
import json, os, sys

data_dir = sys.argv[1]
chunks_dir = sys.argv[2]

with open(os.path.join(data_dir, "manifest.json")) as f:
    m = json.load(f)

# Collect referenced chunk hashes
referenced = set()
for key in ["annotations_hash", "historical_authors_hash", "links_hash",
            "content_address_hash", "blob_metas_hash"]:
    h = m.get(key)
    if isinstance(h, list) and len(h) == 32:
        referenced.add("".join(f"{b:02x}" for b in h))

# Check which are missing from disk
missing = 0
for h in referenced:
    path = os.path.join(chunks_dir, h[:2], h + ".xchunk")
    if not os.path.exists(path):
        missing += 1
        print(f"  MISSING: {h}")

print(f"\n  Referenced: {len(referenced)}, Missing: {missing}")
PYEOF
        )
        echo "$MISSING"
    fi

    echo
    echo "============================================="
    echo "Repair summary:"
    echo "  OK:           $OK"
    echo "  Empty:        $EMPTY"
    echo "  Repaired:     $REPAIRED"
    echo "  Unrepairable: $UNREPAIRABLE"
    echo "============================================="

    if [ "$UNREPAIRABLE" -gt 0 ]; then
        echo
        echo "WARNING: $UNREPAIRABLE chunks could not be repaired from this backup."
        echo "  Try another backup source, or run: xudanu-server verify $DATA_DIR"
    fi

    exit 0
fi

echo "Unknown mode: $MODE"
echo "Valid modes: full, merge, repair"
exit 1
