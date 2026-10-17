#!/usr/bin/env bash
# video-catalog.sh — inventory the clip library: duration + resolution
# + a mid-frame thumbnail per named clip, written to
# docs/videos/CATALOG.md so beats can be assigned to real content
# instead of guesswork.
set -euo pipefail
cd "$(dirname "$0")/.."
V=docs/videos
MD="$V/CATALOG.md"
mkdir -p "$V/catalog"
echo "# Clip catalog — $(date +%Y-%m-%d)" > "$MD"
echo "" >> "$MD"
echo "| clip | seconds | size | notes |" >> "$MD"
echo "|---|---|---|---|" >> "$MD"
for f in "$V"/V*.webm "$V"/V*.mp4; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f" | cut -d. -f1)
  dim=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$f")
  ffmpeg -y -loglevel error -ss $((dur / 2)) -i "$f" -frames:v 1 "$V/catalog/${name%.*}.png"
  echo "| $name | ${dur}s | ${dim} | (watch + annotate) |" >> "$MD"
done
echo "" >> "$MD"
echo "Thumbnails in docs/videos/catalog/. Fill the notes column by
watching each clip, then assign beats in scripts/video-assemble.sh." >> "$MD"
echo "✓ $MD ($(grep -c '^| V' "$MD") clips)"
