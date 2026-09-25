#!/bin/bash
# assemble-reel.sh — concat reel scenes + title cards into the final mp4.
# Expects docs/videos/reel/S{1..6}-*.webm from capture-reel.mjs.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$HERE/docs/videos/reel"
BG="color=c=0x161b22:s=1440x900:r=30"
PART="$DIR/parts"
mkdir -p "$PART"

# Title cards: rendered as PNGs by Chromium (see render-reel-cards.mjs)
node "$HERE/scripts/render-reel-cards.mjs"

card() { # name duration pngfile
  local name="$1" dur="$2" png="$3"
  ffmpeg -y -loglevel error -loop 1 -t "$dur" -i "$PART/$png" \
    -vf "fps=30,format=yuv420p" -c:v libx264 -preset medium -an "$PART/$name.mp4"
  echo "  ✓ card $name"
}

echo "── title cards"
card intro 2.4 intro.png
card c-lobby 1.8 c-lobby.png
card c-spectrum 1.8 c-spectrum.png
card c-window 1.8 c-window.png
card c-drafts 1.8 c-drafts.png
card c-fiveway 1.8 c-fiveway.png
card outro 3.0 outro.png

echo "── normalizing scenes"
for f in "$DIR"/S*-*.webm; do
  b="$(basename "$f" .webm)"
  ffmpeg -y -loglevel error -i "$f" \
    -vf "fps=30,scale=1440:900:force_original_aspect_ratio=decrease,pad=1440:900:(ow-iw)/2:(oh-ih)/2,format=yuv420p" \
    -c:v libx264 -preset medium -crf 22 -an "$PART/$b.mp4"
  echo "  ✓ $b"
done

echo "── concat"
: > "$PART/list.txt"
for n in intro c-lobby S1-lobby c-spectrum S2-spectrum c-window S3-livewindow c-drafts S4-twodrafts c-fiveway S5-fiveway S6-welcome outro; do
  echo "file '$PART/$n.mp4'" >> "$PART/list.txt"
done
ffmpeg -y -loglevel error -f concat -safe 0 -i "$PART/list.txt" -c copy -movflags +faststart "$DIR/xudanu-reel.mp4"

echo "── result"
ffprobe -v quiet -show_entries format=duration,size -of default=nw=1 "$DIR/xudanu-reel.mp4"
