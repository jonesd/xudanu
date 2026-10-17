#!/usr/bin/env bash
# video-assemble.sh — builds docs/videos/xudanu-demo.mp4 from the
# existing clip library in VIDEO-SCRIPT.md beat order, with title
# cards between sections. Gaps are reported, not fatal.
set -euo pipefail
cd "$(dirname "$0")/.."
V=docs/videos
OUT="$V/xudanu-demo.mp4"
FONT="/System/Library/Fonts/Helvetica.ttc"
SIZE="1440:900"
SIZE_LAVFI="1440x900"
FPS=30

card() { # card <output> <png> [duration]
  local out="$1" png="$2" dur="${3:-2.2}"
  ffmpeg -y -loglevel error -loop 1 -t "$dur" -i "$V/$png" \
    -vf "fps=${FPS},scale=${SIZE}:force_original_aspect_ratio=decrease,pad=${SIZE}:(ow-iw)/2:(oh-ih)/2:color=0x0d1117" \
    -c:v libx264 -pix_fmt yuv420p "$out"
}

norm() { # norm <input> <output> — scale/pad to canvas, uniform fps/pixfmt
  ffmpeg -y -loglevel error -i "$1" -vf "scale=${SIZE}:force_original_aspect_ratio=decrease,pad=${SIZE}:(ow-iw)/2:(oh-ih)/2:color=#0d1117,fps=${FPS}" \
    -c:v libx264 -pix_fmt yuv420p -an "$2"
}

BEATS=(
  "V0-cold-open.mp4|COLD: A quotation, live"
  "V3-1-typing.webm|Xudanu — a document"
  "V1-first-link.webm|Connect anything"
  "V3-2-link-wizard.webm|Typed connections"
  "V3-3-hover-navigate.webm|Links go both ways"
  "V3-multi-ended.webm|Many-ended connections"
  "V2-provenance.webm|Authorship travels with content"
  "V3-4-collab-A.webm|Live, together"
  "V5-docuverse.webm|The docuverse"
  "V4-onboarding.webm|Welcome"
)

CONCAT="$V/concat.txt"; : > "$CONCAT"
GAPS=()
i=0
for entry in "${BEATS[@]}"; do
  clip="${entry%%|*}"; label="${entry##*|}"
  i=$((i+1))
  if [ -f "$V/$clip" ]; then
    norm "$V/$clip" "$V/.n$i.mp4"
    echo "file '.n$i.mp4'" >> "$CONCAT"
    echo "  + $clip"
  else
    GAPS+=("$clip")
    echo "  − MISSING: $clip"
  fi
  card "$V/.c$i.mp4" ".c$i.png"
  echo "file '.c$i.mp4'" >> "$CONCAT"
done

card "$V/.close.mp4" ".close.png" 4
echo "file '.close.mp4'" >> "$CONCAT"

ffmpeg -y -loglevel error -f concat -safe 0 -i "$CONCAT" -c copy "$OUT"
rm -f "$V"/.n*.mp4 "$V"/.c*.mp4 "$V"/.close.mp4 "$CONCAT"

echo ""
echo "✓ $OUT ($(du -h "$OUT" | cut -f1))"
if [ ${#GAPS[@]} -gt 0 ]; then
  echo "gaps to shoot: ${GAPS[*]}"
else
  echo "no gaps — full coverage"
fi
