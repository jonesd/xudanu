#!/usr/bin/env bash
#
# setup-xudanu-demo.sh — Install and run Xudanu on a fresh Linux instance
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/jonesd/xudanu/main/scripts/setup-demo.sh | bash
#
# Or:
#   git clone https://github.com/jonesd/xudanu.git
#   cd xudanu
#   bash scripts/setup-demo.sh
#
# Environment variables:
#   XUDANU_PORT    — port to listen on (default: 8080)
#   XUDANU_DOMAIN  — domain for Caddy HTTPS (optional, enables HTTPS)
#   XUDANU_USER    — admin username for Caddy basic auth (default: admin)
#   XUDANU_PASS    — admin password for Caddy basic auth (default: xudanu-demo)
#
set -euo pipefail

PORT="${XUDANU_PORT:-8080}"
DOMAIN="${XUDANU_DOMAIN:-}"
AUTH_USER="${XUDANU_USER:-admin}"
AUTH_PASS="${XUDANU_PASS:-xudanu-demo}"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="/opt/xudanu/data"
INSTALL_DIR="/opt/xudanu"

echo "=== Xudanu Demo Setup ==="
echo "Port: ${PORT}"
echo "Data: ${DATA_DIR}"
echo "Domain: ${DOMAIN:-<none, HTTP only>}"
echo ""

# --- Detect architecture ---
ARCH=$(uname -m)
echo "[1/6] Detected architecture: ${ARCH}"

# --- Install system dependencies ---
echo "[2/6] Installing system dependencies..."
if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq build-essential pkg-config libssl-dev curl git
elif command -v dnf &>/dev/null; then
    sudo dnf install -y -q gcc gcc-c++ make openssl-devel curl git
elif command -v yum &>/dev/null; then
    sudo yum install -y -q gcc gcc-c++ make openssl-devel curl git
else
    echo "Warning: unsupported package manager, skipping system deps"
fi

# --- Install Rust ---
echo "[3/6] Installing Rust..."
if ! command -v cargo &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi
echo "  Rust: $(rustc --version)"

# --- Install Node.js ---
echo "[4/6] Installing Node.js..."
if ! command -v node &>/dev/null || [ "$(node -major)" -lt 18 ]; then
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - 2>/dev/null && \
        sudo apt-get install -y -qq nodejs 2>/dev/null || {
        # Fallback: use nvm
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        source "$HOME/.nvm/nvm.sh"
        nvm install 22
    }
fi
echo "  Node: $(node --version)"

# --- Build Xudanu ---
echo "[5/6] Building Xudanu..."
if [ ! -d "${REPO_DIR}/original-code/xanadugold/src-rust" ]; then
    echo "  Cloning repository..."
    git clone https://github.com/jonesd/xudanu.git /tmp/xudanu-build
    REPO_DIR="/tmp/xudanu-build"
fi

# Build server binary
echo "  Building server (release)..."
cd "${REPO_DIR}/original-code/xanadugold/src-rust"
cargo build --release --features server 2>&1 | tail -1

# Build React frontend
echo "  Building frontend..."
cd "${REPO_DIR}/web/app"
npm ci --quiet 2>&1 | tail -1
npm run build 2>&1 | tail -1

# --- Install ---
echo "[6/6] Installing to ${INSTALL_DIR}..."
sudo mkdir -p "${INSTALL_DIR}/bin" "${INSTALL_DIR}/frontend" "${DATA_DIR}"

sudo cp "${REPO_DIR}/original-code/xanadugold/src-rust/target/release/xudanu-server" \
    "${INSTALL_DIR}/bin/xudanu-server"
sudo cp -r "${REPO_DIR}/web/app/dist/"* "${INSTALL_DIR}/frontend/"
sudo cp "${REPO_DIR}/LICENSE" "${INSTALL_DIR}/" 2>/dev/null || true

# Initialize data directory
if [ ! -f "${DATA_DIR}/manifest.json" ]; then
    sudo "${INSTALL_DIR}/bin/xudanu-server" init "${DATA_DIR}"
fi

# Create systemd service
echo "Creating systemd service..."
sudo tee /etc/systemd/system/xudanu.service > /dev/null <<EOF
[Unit]
Description=Xudanu Hypertext Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/bin/xudanu-server run 0.0.0.0:${PORT} ${DATA_DIR} --static-dir ${INSTALL_DIR}/frontend
Restart=on-failure
RestartSec=5
Environment=ROCKET_ENV=production

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable xudanu
sudo systemctl restart xudanu

echo ""
echo "=== Xudanu is running ==="
echo "  Internal: http://localhost:${PORT}"
echo "  Data:   ${DATA_DIR}"
echo "  Logs:   journalctl -u xudanu -f"
echo "  Stop:   sudo systemctl stop xudanu"
echo "  Restart: sudo systemctl restart xudanu"
echo ""

# --- Always install Caddy with basic auth ---
echo "Setting up Caddy reverse proxy with basic auth..."
if ! command -v caddy &>/dev/null; then
    sudo apt-get install -y -qq debian-keyring debian-archive-keyring apt-transport-https
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
    sudo apt-get update -qq
    sudo apt-get install -y -qq caddy
fi

# Bind Xudanu to localhost only (Caddy proxies public traffic)
sudo sed -i "s/0\.0\.0\.0:${PORT}/${DATA_DIR}/; s/0\.0\.0\.0:${PORT}/127.0.0.1:${PORT}/" /etc/systemd/system/xudanu.service
sudo systemctl daemon-reload
sudo systemctl restart xudanu

PUBLIC_PORT=80
CADDY_SITE=":${PUBLIC_PORT}"

if [ -n "${DOMAIN}" ]; then
    CADDY_SITE="${DOMAIN}"
    PUBLIC_PORT=443
fi

HASHED_PASS=$(caddy hash-password --plaintext "${AUTH_PASS}")
sudo tee /etc/caddy/Caddyfile > /dev/null <<EOF
${CADDY_SITE} {
    reverse_proxy localhost:${PORT}
    basicauth * {
        ${AUTH_USER} ${HASHED_PASS}
    }
}
EOF

sudo systemctl restart caddy

PUBLIC_IP=$(hostname -I | awk '{print $1}')
if [ -n "${DOMAIN}" ]; then
    echo "  URL:    https://${DOMAIN}"
else
    echo "  URL:    http://${PUBLIC_IP}"
fi
echo "  Auth:   ${AUTH_USER} / ${AUTH_PASS}"
echo ""
echo "  Change password: caddy hash-password --plaintext 'new-pass'"
echo "  Then update /etc/caddy/Caddyfile and: sudo systemctl restart caddy"

echo ""
echo "Done."
