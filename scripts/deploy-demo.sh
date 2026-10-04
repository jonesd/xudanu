#!/bin/bash
# deploy-demo.sh — stand up the public sandbox demo at demo.xudanu.com
#
# Companion to deploy.sh (which updates the main xudanu.com service).
# Creates an INDEPENDENT container with its own data volume running
# the seeded Links Course in public-sandbox mode. Wiping it loses
# nothing: docker compose -p xudanu-demo down -v && re-run.
#
# Prereqs (once, by hand):
#   DNS: A record  demo.xudanu.com -> 178.105.99.41
#
# Usage: ./scripts/deploy-demo.sh
# Run from your Mac.

set -e

SERVER="root@178.105.99.41"
REMOTE_DIR="/opt/xudanu-demo"

echo "=== Deploying demo sandbox to demo.xudanu.com ==="

echo "1. Writing demo compose on server..."
ssh $SERVER "mkdir -p $REMOTE_DIR && cat > $REMOTE_DIR/docker-compose.yml << 'EOF'
# Managed by scripts/deploy-demo.sh — disposable public sandbox.
services:
  xudanu-demo:
    image: xudanu:latest
    restart: unless-stopped
    ports:
      - \"127.0.0.1:8081:8080\"
    volumes:
      - demo-data:/data
    command:
      - run
      - 0.0.0.0:8080
      - /data
      - --edit-policy
      - public-sandbox
      - --seed-links-demo
      - --server-name
      - Xudanu Demo Sandbox
    healthcheck:
      test: [\"CMD-SHELL\", \"wget -qO- http://127.0.0.1:8080/health || exit 1\"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s
volumes:
  demo-data:
EOF"

echo "2. Building/pulling image if needed and starting demo container..."
ssh $SERVER "cd $REMOTE_DIR && (docker image inspect xudanu:latest >/dev/null 2>&1 || (cd /opt/xudanu/repo && docker build -t xudanu:latest .)) && docker compose -p xudanu-demo up -d"

echo "3. Health check (local port)..."
sleep 5
HEALTH=$(ssh $SERVER "curl -s http://127.0.0.1:8081/health" 2>/dev/null || echo "failed")
if echo "$HEALTH" | grep -q '"status":"ok"'; then
    echo "   Demo container: OK ($(echo $HEALTH | grep -o '"works":[0-9]*'))"
else
    echo "   Demo container: CHECK NEEDED"
    echo "   Response: $HEALTH"
    exit 1
fi

echo "4. Reverse proxy for demo.xudanu.com..."
# Detect the proxy layer instead of assuming.
if ssh $SERVER "command -v caddy >/dev/null 2>&1 || docker ps --format '{{.Names}}' | grep -qi caddy"; then
    echo "   Caddy detected. Ensure /etc/caddy/Caddyfile (or the caddy container's) has:"
    echo ""
    echo "     demo.xudanu.com {"
    echo "         reverse_proxy 127.0.0.1:8081"
    echo "     }"
    echo ""
    echo "   then reload: ssh $SERVER 'systemctl reload caddy' (or: docker exec <caddy> caddy reload --config /etc/caddy/Caddyfile)"
else
    echo "   No Caddy detected. Whatever fronts xudanu.com (nginx/traefik/cloudflare) needs:"
    echo "     demo.xudanu.com -> 127.0.0.1:8081"
    echo "   The demo container is bound to 127.0.0.1:8081 on the server."
fi

echo ""
echo "=== Demo deploy complete ==="
echo "Container:  running on the server at 127.0.0.1:8081"
echo "Public URL: https://demo.transclusion.org  (once DNS + proxy step above are done)"
echo "Reset:      ssh $SERVER 'cd $REMOTE_DIR && docker compose -p xudanu-demo down -v' && ./scripts/deploy-demo.sh"
echo "Logs:       ssh $SERVER 'cd $REMOTE_DIR && docker compose -p xudanu-demo logs -f'"
