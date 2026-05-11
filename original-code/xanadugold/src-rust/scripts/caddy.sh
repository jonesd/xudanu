#!/bin/bash
# Start Xudanu behind Caddy reverse proxy with HTTP Basic Auth + HTTPS.
#
# Usage:
#   ./scripts/caddy.sh                    # local dev (localhost:8443)
#   ./scripts/caddy.sh production        # production (your domain)
#
# Default credentials: admin / changeme
# To change: run `caddy hash-password --plaintext 'newpass'`
#            and update the Caddyfile

set -e

cd "$(dirname "$0")/.."

ADDR="127.0.0.1:8090"
DATA_DIR="${XUDANU_DATA_DIR:-}"

PIDS=()
cleanup() {
    echo ""
    echo "Shutting down..."
    for pid in "${PIDS[@]}"; do
        kill "$pid" 2>/dev/null || true
    done
    wait 2>/dev/null
    echo "Done."
}
trap cleanup EXIT INT TERM

echo "Building xudanu-server..."
cargo build --features server --bin xudanu-server 2>/dev/null

if [ -n "$DATA_DIR" ]; then
    if [ ! -d "$DATA_DIR" ]; then
        echo "Initializing data directory: $DATA_DIR"
        cargo run --features server --bin xudanu-server -- init "$DATA_DIR"
    fi
    echo "Starting xudanu server on $ADDR (data: $DATA_DIR)"
    cargo run --features server --bin xudanu-server -- run "$ADDR" "$DATA_DIR" --static-dir ./static &
else
    echo "Starting xudanu server on $ADDR (in-memory)"
    cargo run --features server --bin xudanu-server -- run "$ADDR" --static-dir ./static &
fi
PIDS+=($!)

sleep 1

MODE="${1:-local}"
if [ "$MODE" = "production" ]; then
    echo "Starting Caddy (production mode)..."
    echo ""
    echo "  Web UI:           https://yourdomain.com"
    echo "  Health:           https://yourdomain.com/health"
    echo "  Credentials:      admin / (see Caddyfile)"
    echo ""
    caddy run --config Caddyfile --env PRODUCTION=1 &
else
    echo "Starting Caddy (local dev mode)..."
    echo ""
    echo "  Web UI:           https://localhost:8443"
    echo "  Health:           https://localhost:8443/health"
    echo "  Credentials:      admin / changeme"
    echo ""
    caddy run --config Caddyfile &
fi
PIDS+=($!)

wait
