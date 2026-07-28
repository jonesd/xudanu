# Xudanu Chunk Store

This directory contains content-addressed storage chunks.

## File Format

- **Extension:** `.xchunk`
- **Filename:** 64-character BLAKE3 hash (hex-encoded)
- **Directory layout:** `chunks/{first-2-hex-chars}/{full-hash}.xchunk`
- **Example:** `chunks/a3/a3f7b2...e1c4.xchunk`

## Do Not Modify

Chunk files are write-once and integrity-checked via BLAKE3 hash.
Renaming, editing, or deleting chunks will corrupt the data store.

## Backup

Use rsync or similar to back up the `chunks/` directory:

```bash
rsync -avz --delete \
  /path/to/data/chunks/ user@offsite:/backup/xudanu/chunks/
```

Also back up `manifest.json` and `manifest_v*.json` from the data directory.
See `examples/backup-chunks.sh` in the source tree for a complete script.
