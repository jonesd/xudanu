#!/usr/bin/env bash
set -euo pipefail

# ── Xudanu Chunk Verification ─────────────────────────────────────────────
#
# Verifies data directory integrity:
# - All chunks on disk are non-empty and well-formed
# - Manifest references match chunks on disk
# - No orphaned chunks (on disk but not referenced)
# - No missing chunks (referenced but not on disk)
#
# Usage:
#   ./scripts/verify-chunks.sh <data_dir> [--fix] [--report <file>]
#
# Examples:
#   ./scripts/verify-chunks.sh data
#   ./scripts/verify-chunks.sh data --report verification.txt
#   ./scripts/verify-chunks.sh data --fix  (removes orphaned chunks)

DATA_DIR="${1:?Usage: verify-chunks.sh <data_dir> [--fix] [--report <file>]}"
shift

FIX=false
REPORT_FILE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --fix) FIX=true ;;
        --report) REPORT_FILE="$2"; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

CHUNKS_DIR="$DATA_DIR/chunks"
MANIFEST="$DATA_DIR/manifest.json"

if [ ! -d "$CHUNKS_DIR" ]; then
    echo "ERROR: no chunks directory in '$DATA_DIR'"
    exit 1
fi

if [ ! -f "$MANIFEST" ]; then
    echo "ERROR: no manifest.json in '$DATA_DIR'"
    exit 1
fi

echo "=========================================="
echo "Xudanu Chunk Verification"
echo "  Data dir: $DATA_DIR"
echo "  Fix mode: $FIX"
echo "=========================================="

# ── 1. Count and verify chunks on disk ────────────────────────────────────

echo ""
echo "Step 1: Scanning chunks on disk (BLAKE3)..."

if ! python3 -c "import blake3" 2>/dev/null; then
    echo "  WARNING: pip3 install blake3 for full hash verification"
fi

DISK_CHUNKS=0
EMPTY_CHUNKS=0
CORRUPT_CHUNKS=0

while IFS= read -r chunk_file; do
    DISK_CHUNKS=$((DISK_CHUNKS + 1))

    size=$(stat -f%z "$chunk_file" 2>/dev/null || stat -c%s "$chunk_file" 2>/dev/null)
    if [ "$size" = "0" ] 2>/dev/null; then
        EMPTY_CHUNKS=$((EMPTY_CHUNKS + 1))
        echo "  EMPTY: $(basename "$chunk_file")"
        if [ "$FIX" = true ]; then
            rm "$chunk_file"
        fi
        continue
    fi

    # BLAKE3 hash check: filename = expected hash
    if python3 -c "import blake3" 2>/dev/null; then
        expected=$(basename "${chunk_file%.xchunk}")
        actual=$(python3 -c "
import blake3
with open('$chunk_file', 'rb') as f:
    print(blake3.blake3(f.read()).hexdigest())
" 2>/dev/null)
        if [ "$actual" != "$expected" ]; then
            CORRUPT_CHUNKS=$((CORRUPT_CHUNKS + 1))
            echo "  CORRUPT: $expected"
            if [ "$FIX" = true ]; then
                rm "$chunk_file"
            fi
        fi
    fi

    if [ $((DISK_CHUNKS % 500)) -eq 0 ]; then
        echo "  Scanned $DISK_CHUNKS..."
    fi
done < <(find "$CHUNKS_DIR" -name "*.xchunk" -type f)

echo "  Total on disk: $DISK_CHUNKS"
echo "  Empty:         $EMPTY_CHUNKS"
echo "  Corrupt:       $CORRUPT_CHUNKS"

# ── 2. Check manifest references ──────────────────────────────────────────

echo ""
echo "Step 2: Checking manifest references..."

if command -v python3 &>/dev/null; then
    python3 - "$MANIFEST" "$CHUNKS_DIR" "$FIX" << 'PYEOF'
import json
import os
import sys

manifest_path = sys.argv[1]
chunks_dir = sys.argv[2]
fix_mode = sys.argv[3] == "true"

with open(manifest_path) as f:
    manifest = json.load(f)

# Collect all chunk hashes referenced by manifest
# Hash fields are stored as arrays of bytes (integers 0-255)
referenced = set()
hash_fields = [
    "works_hash", "clubs_hash", "links_hash",
    "annotations_hash", "historical_authors_hash", "blob_metas_hash",
    "fossil_snapshots_hash", "content_address_hash",
]

for field in hash_fields:
    h = manifest.get(field)
    if h and isinstance(h, list) and len(h) == 32:
        hex_str = ''.join(f'{b:02x}' for b in h)
        referenced.add(hex_str)
    elif h and isinstance(h, str) and len(h) >= 32:
        referenced.add(h)

# Check nested structures (works may have edition chunk hashes)
for work in manifest.get("works", []):
    for field in ["edition_chunk_hash", "history_chunk_hash"]:
        h = work.get(field)
        if h:
            if isinstance(h, list) and len(h) == 32:
                hex_str = ''.join(f'{b:02x}' for b in h)
                referenced.add(hex_str)
            elif isinstance(h, str) and len(h) >= 32:
                referenced.add(h)

# Check standalone editions
for ed in manifest.get("standalone_editions", []):
    h = ed.get("chunk_hash") if isinstance(ed, dict) else None
    if h:
        if isinstance(h, list) and len(h) == 32:
            hex_str = ''.join(f'{b:02x}' for b in h)
            referenced.add(hex_str)
        elif isinstance(h, str) and len(h) >= 32:
            referenced.add(h)

# Check if referenced chunks exist
missing = []
for h in referenced:
    # Chunks are stored as XX/XX...XX.xchunk (first 2 chars = subdir)
    subdir = h[:2]
    path = os.path.join(chunks_dir, subdir, h + ".xchunk")
    if not os.path.exists(path):
        missing.append(h)

print(f"  Manifest references: {len(referenced)} chunk hashes")
print(f"  Missing from disk:   {len(missing)}")

if missing:
    for h in missing[:20]:
        print(f"    MISSING: {h}")
    if len(missing) > 20:
        print(f"    ... and {len(missing) - 20} more")

    if fix_mode:
        print("  Cannot fix missing chunks — restore from backup")

# Check for orphaned chunks
disk_hashes = set()
for root, dirs, files in os.walk(chunks_dir):
    for fname in files:
        if fname.endswith(".xchunk"):
            disk_hashes.add(fname[:-7])  # Remove .xchunk

orphans = disk_hashes - referenced
print(f"  Orphaned (not in top-level manifest): {len(orphans)}")
print(f"  Note: edition chunks are referenced indirectly through work_ref,")

if orphans and fix_mode:
    removed = 0
    for h in orphans:
        subdir = h[:2]
        path = os.path.join(chunks_dir, subdir, h + ".xchunk")
        if os.path.exists(path):
            os.remove(path)
            removed += 1
    print(f"  Removed {removed} orphaned chunks")
elif orphans:
    for h in list(orphans)[:10]:
        print(f"    ORPHAN: {h}")
    if len(orphans) > 10:
        print(f"    ... and {len(orphans) - 10} more")

# Summary
status = "OK" if not missing and not orphans else "ISSUES FOUND"
print(f"\n  Status: {status}")
PYEOF
else
    echo "  python3 not available — skipping manifest verification"
fi

# ── 3. Check dual manifest slots ──────────────────────────────────────────

echo ""
echo "Step 3: Checking dual manifest slots..."

PRIMARY=$(python3 -c "
import json
with open('$MANIFEST') as f:
    m = json.load(f)
print(m.get('manifest_slot', '?'))
" 2>/dev/null || echo "?")

echo "  Active slot: $PRIMARY"

for slot_file in "$DATA_DIR"/manifest_v*.json "$DATA_DIR"/manifest.json.bak; do
    if [ -f "$slot_file" ]; then
        size=$(stat -f%z "$slot_file" 2>/dev/null || stat -c%s "$slot_file" 2>/dev/null)
        echo "  Backup: $(basename "$slot_file") ($size bytes)"
    fi
done

# ── 4. Summary ────────────────────────────────────────────────────────────

echo ""
echo "=========================================="
echo "Verification complete"
echo "  Disk chunks:   $DISK_CHUNKS"
echo "  Empty:         $EMPTY_CHUNKS"
echo "  Orphaned:      (see above)"
echo "  Missing:       (see above)"
echo "=========================================="

if [ "$EMPTY_CHUNKS" -gt 0 ]; then
    exit 1
fi
