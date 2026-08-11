#!/bin/bash
# ship.sh — Push to GitHub + deploy to xudanu.com in one command
#
# Usage:
#   ./scripts/ship.sh                    # push + deploy
#   ./scripts/ship.sh "fix: my change"   # commit + push + deploy
#
# From your Mac. Takes ~25 min (tests + Docker build).

set -e

SERVER="root@178.105.99.41"
SSH_KEY="$HOME/.ssh/id_hetzner"
REMOTE_DIR="/opt/xudanu"

cd "$(dirname "$0")/.."

# 1. Commit if message provided
if [ -n "$1" ]; then
  echo "=== Committing ==="
  git add -u
  git commit -m "$1" --no-gpg-sign
fi

# 2. Push to GitHub
echo "=== Pushing to GitHub (runs pre-push checks, ~10 min) ==="
git push github main

# 3. Deploy to server
echo "=== Deploying to xudanu.com ==="
SSH_CMD="ssh -i $SSH_KEY -o StrictHostKeyChecking=no $SERVER"
SCP_CMD="scp -i $SSH_KEY -o StrictHostKeyChecking=no"

echo "Pulling code..."
$SSH_CMD "cd $REMOTE_DIR/repo && git pull"

echo "Building Docker image (~15 min)..."
$SSH_CMD "cd $REMOTE_DIR/repo && docker build -t xudanu:latest ."

echo "Restarting..."
$SSH_CMD "cd $REMOTE_DIR && docker compose down && docker compose up -d"

# 4. Health check
echo "=== Health check ==="
sleep 5
HEALTH=$(curl -s https://xudanu.com/health 2>/dev/null || echo "failed")
if echo "$HEALTH" | grep -q '"status":"ok"'; then
  echo "Live: https://xudanu.com ✓"
else
  echo "Waiting for HTTPS..."
  sleep 15
  curl -s https://xudanu.com/health | grep -q '"status":"ok"' && echo "Live: https://xudanu.com ✓" || echo "Check needed: ssh $SERVER 'docker compose logs xudanu'"
fi
