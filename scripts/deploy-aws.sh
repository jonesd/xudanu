#!/bin/bash
set -euo pipefail

DOMAIN="${1:-xudanu.com}"
VERSION="v0.6.3"
RELEASE="xudanu-${VERSION}-x86_64-unknown-linux-musl.tar.gz"
URL="https://github.com/jonesd/xudanu/releases/download/${VERSION}/${RELEASE}"
INSTALL_DIR="/opt/xudanu"
DATA_DIR="/var/lib/xudanu"

echo "=== xudanu ${VERSION} deployment for ${DOMAIN} ==="

# Install dependencies
sudo apt-get update -qq
sudo apt-get install -y -qq curl debian-keyring debian-archive-keyring apt-transport-https curl

# Install Caddy
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt-get update -qq
sudo apt-get install -y -qq caddy

# Download and install xudanu
echo "Downloading ${RELEASE}..."
curl -LO "${URL}"
sudo mkdir -p "${INSTALL_DIR}" "${DATA_DIR}"
sudo tar -xzf "${RELEASE}" -C "${INSTALL_DIR}"
rm "${RELEASE}"
sudo chmod +x "${INSTALL_DIR}/xudanu-server"

# Create data symlink
sudo ln -sf "${DATA_DIR}" "${INSTALL_DIR}/data"

# Create systemd service
sudo tee /etc/systemd/system/xudanu.service > /dev/null <<EOF
[Unit]
Description=xudanu server
After=network.target

[Service]
Type=simple
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/xudanu-server run 127.0.0.1:8080 --static-dir dist --data-dir ${DATA_DIR}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Configure Caddy
sudo tee /etc/caddy/Caddyfile > /dev/null <<EOF
${DOMAIN} {
    reverse_proxy 127.0.0.1:8080
}
EOF

# Start services
sudo systemctl daemon-reload
sudo systemctl enable xudanu caddy
sudo systemctl restart xudanu
sleep 2
sudo systemctl restart caddy

echo ""
echo "=== Done ==="
echo "  xudanu:  http://localhost:8080 (internal)"
echo "  public:  https://${DOMAIN}"
echo "  data:    ${DATA_DIR}"
echo ""
echo "Next steps:"
echo "  1. Make sure DNS for ${DOMAIN} points to this instance"
echo "  2. Open ports 80 and 443 in the security group"
echo "  3. Visit https://${DOMAIN} and create an account"
echo ""
echo "Logs:"
echo "  sudo journalctl -u xudanu -f"
echo "  sudo journalctl -u caddy -f"
