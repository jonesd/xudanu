#!/bin/bash
# deploy.sh — Update xudanu.com to latest code
# Usage: ./deploy.sh
# Run from your Mac

set -e

SERVER="root@178.105.99.41"
REMOTE_DIR="/opt/xudanu"

echo "=== Deploying to xudanu.com ==="

echo "1. Pulling latest code..."
ssh $SERVER "cd $REMOTE_DIR/repo && git pull"

echo "2. Building Docker image (10-15 min)..."
ssh $SERVER "cd $REMOTE_DIR/repo && docker build -t xudanu:latest ."

echo "3. Restarting services..."
ssh $SERVER "cd $REMOTE_DIR && docker compose down && docker compose up -d"

echo "4. Waiting for startup..."
sleep 5

echo "5. Health check..."
HEALTH=$(ssh $SERVER "curl -s http://localhost/health" 2>/dev/null || echo "failed")
if echo "$HEALTH" | grep -q '"status":"ok"'; then
    echo "   Server: OK"
else
    echo "   Server: CHECK NEEDED"
    echo "   Response: $HEALTH"
fi

PUBLIC=$(curl -s https://xudanu.com/health 2>/dev/null || echo "failed")
if echo "$PUBLIC" | grep -q '"status":"ok"'; then
    echo "   Public HTTPS: OK"
else
    echo "   Public HTTPS: Checking (DNS/SSL may need a moment)..."
    sleep 10
    PUBLIC=$(curl -s https://xudanu.com/health 2>/dev/null || echo "failed")
    if echo "$PUBLIC" | grep -q '"status":"ok"'; then
        echo "   Public HTTPS: OK"
    else
        echo "   Public HTTPS: CHECK NEEDED"
    fi
fi

echo ""
echo "=== Deploy complete ==="
echo "Live at: https://xudanu.com"
echo ""
echo "Logs: ssh $SERVER 'cd $REMOTE_DIR && docker compose logs -f xudanu'"
