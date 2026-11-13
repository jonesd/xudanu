#!/bin/bash
# deploy.sh — update xudanu.com to latest main.
#
# RUN FROM THE LAPTOP: the script drives the server over ssh from
# this machine (build, flip, and verify all happen remotely). Do not
# run it on the server itself — the laptop-side steps get skipped
# and you get a misleading partial run.
#
# TOPOLOGY (the part that bit us once): production is a HOST SYSTEMD
# SERVICE (xudanu.service → /opt/xudanu/xudanu-server on 127.0.0.1:8080,
# data at /var/lib/xudanu) behind a HOST CADDY owning 80/443. The
# docker compose stack in /opt/xudanu is NOT in the serving path —
# the image is used as a BUILD TOOL only. Never `compose up` here.
# Full map: /opt/xudanu/ARCHITECTURE-NOTES.md on the server.

set -e

SERVER="root@178.105.99.41"
REMOTE_DIR="/opt/xudanu"

echo "=== Deploying to xudanu.com (systemd topology) ==="

echo "1. Backing up live data (/var/lib/xudanu)..."
ssh $SERVER "tar czf /root/xudanu-live-backup-\$(date +%F).tgz -C /var/lib/xudanu . && echo '   backup: ok'"

echo "2. Pulling latest + building image (build tool only)..."
ssh $SERVER "cd $REMOTE_DIR/repo && git pull --ff-only -q && docker build -q -t xudanu:latest . >/dev/null && echo '   build: ok'"

echo "3. Extracting binary + static dist + swapping under systemd..."
ssh $SERVER "set -e
CID=\$(docker create xudanu:latest)
docker cp \$CID:/usr/local/bin/xudanu-server $REMOTE_DIR/xudanu-server.new
docker cp \$CID:/app/dist $REMOTE_DIR/dist.new
docker rm \$CID >/dev/null
systemctl stop xudanu
cp $REMOTE_DIR/xudanu-server $REMOTE_DIR/xudanu-server.pre-\$(date +%s)
cp $REMOTE_DIR/xudanu-server.new $REMOTE_DIR/xudanu-server
# The systemd unit serves --static-dir dist (relative to /opt/xudanu):
# refresh it from the same image the binary came from, or the
# frontend stays stale after every deploy (found 2026-11-12:
# production /classic/index.html was an empty file from a half-old
# tree while the binary was current).
rm -rf $REMOTE_DIR/dist.pre-\$(date +%s)
[ -d $REMOTE_DIR/dist ] && mv $REMOTE_DIR/dist $REMOTE_DIR/dist.pre-\$(date +%s)
mv $REMOTE_DIR/dist.new $REMOTE_DIR/dist
systemctl start xudanu
echo '   swap: ok'"

echo "4. Waiting for startup..."
sleep 4

echo "5. Health checks..."
HEALTH=$(ssh $SERVER "curl -s http://127.0.0.1:8080/health" 2>/dev/null || echo "failed")
if echo "$HEALTH" | grep -q '"status":"ok"'; then
    echo "   Local: OK ($(echo "$HEALTH" | grep -o '"version":"[^"]*"' | head -1))"
else
    echo "   Local: CHECK NEEDED — rolling back is: cp \$REMOTE_DIR/xudanu-server.pre-* back + systemctl restart xudanu"
    echo "   Response: $HEALTH"
    exit 1
fi

PUBLIC=$(curl -s https://xudanu.com/health 2>/dev/null || echo "failed")
if echo "$PUBLIC" | grep -q '"status":"ok"'; then
    echo "   Public HTTPS: OK"
else
    echo "   Public HTTPS: CHECK NEEDED (caddy/DNS may need a moment)"
    echo "   Response: $PUBLIC"
    exit 1
fi

WK=$(curl -s https://xudanu.com/.well-known/xudanu-server.json 2>/dev/null || echo "failed")
echo "   Identity: $(echo "$WK" | grep -o '"server_version":"[^"]*"' | head -1), $(echo "$WK" | grep -o '"public_address":"[^"]*"' | head -1)"

echo ""
echo "=== Deploy complete — https://xudanu.com ==="
