#!/usr/bin/env bash
#
# backup-chunks.sh — Off-site backup for Xudanu chunk storage
#
# Usage:
#   ./backup-chunks.sh /path/to/xudanu/data user@offsite:/backup/xudanu
#
# Environment variables:
#   RSYNC_RSH  — override the remote shell (default: ssh -o BatchMode=yes)
#   XUDANU_PORT — SSH port for remote (default: 22)
#
# This script syncs:
#   - chunks/         (content-addressed .xchunk files)
#   - manifest.json   (current manifest)
#   - manifest_v*.json (versioned backups)
#
# It does NOT sync:
#   - blobs/          (large binary objects, sync separately if needed)
#   - *.tmp           (temporary/incomplete files)
#   - keys/           (server key material — handle with care)
#
set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <data-dir> <remote-destination>" >&2
    echo "  e.g. $0 ./data user@offsite:/backup/xudanu" >&2
    exit 1
fi

DATA_DIR="$1"
REMOTE="$2"
PORT="${XUDANU_PORT:-22}"
SSH_CMD="ssh -o BatchMode=yes -p $PORT"

if [ ! -d "$DATA_DIR/chunks" ]; then
    echo "Error: $DATA_DIR/chunks/ not found. Is this a Xudanu data directory?" >&2
    exit 1
fi

echo "Backing up Xudanu chunks from $DATA_DIR -> $REMOTE"

rsync -avz --delete \
    --include='*.xchunk' \
    --include='*/' \
    --exclude='*.tmp' \
    --exclude='README.md' \
    -e "$SSH_CMD" \
    "$DATA_DIR/chunks/" "$REMOTE/chunks/"

echo "Backing up manifest files..."

rsync -avz \
    --include='manifest.json' \
    --include='manifest_v*.json' \
    --exclude='*' \
    -e "$SSH_CMD" \
    "$DATA_DIR/" "$REMOTE/"

echo "Backup complete."
echo ""
echo "Verify with: rsync -avzn --delete -e '$SSH_CMD' '$DATA_DIR/chunks/' '$REMOTE/chunks/'"
