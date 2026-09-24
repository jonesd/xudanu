#!/bin/bash
set -euo pipefail

# xudanu server deployment (Hetzner/AWS/any Ubuntu box).
# Run ON the server as root (or with sudo). Idempotent.
#
#   curl -fsSL https://raw.githubusercontent.com/jonesd/xudanu/main/scripts/deploy-aws.sh | bash
#
# or with options:
#   VERSION=v1.13.1 DOMAIN=xudanu.com bash deploy-aws.sh
#
# Data survives upgrades (/var/lib/xudanu is never touched). The admin
# passphrase lives in /opt/xudanu/xudanu.env (created on first run
# with a random value — SAVE IT; it is never printed again by design).

DOMAIN="${1:-${DOMAIN:-xudanu.com}}"
VERSION="${VERSION:-v1.14.0}"
RELEASE="xudanu-${VERSION}-x86_64-unknown-linux-musl.tar.gz"
URL="https://github.com/jonesd/xudanu/releases/download/${VERSION}/${RELEASE}"
INSTALL_DIR="/opt/xudanu"
DATA_DIR="/var/lib/xudanu"
ENV_FILE="${INSTALL_DIR}/xudanu.env"

echo "=== xudanu ${VERSION} deployment for ${DOMAIN} ==="

# ── Backup data before touching anything (upgrades are safe, but
# belt-and-braces: this box may hold live user works) ──────────────
if [ -d "${DATA_DIR}" ]; then
  BACKUP="/root/xudanu-backup-$(date +%Y%m%d-%H%M%S).tgz"
  echo "Backing up ${DATA_DIR} -> ${BACKUP}"
  tar czf "${BACKUP}" -C "$(dirname "${DATA_DIR}")" "$(basename "${DATA_DIR}")"
fi

# Install dependencies
sudo apt-get update -qq
sudo apt-get install -y -qq curl debian-keyring debian-archive-keyring apt-transport-https

# Install Caddy (TLS termination) if absent
if ! command -v caddy >/dev/null 2>&1; then
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
  sudo apt-get update -qq
  sudo apt-get install -y -qq caddy
fi

# Download and install xudanu
echo "Downloading ${RELEASE}..."
curl -fLO "${URL}"
sudo mkdir -p "${INSTALL_DIR}" "${DATA_DIR}"
sudo tar -xzf "${RELEASE}" -C "${INSTALL_DIR}"
rm "${RELEASE}"
sudo chmod +x "${INSTALL_DIR}/xudanu-server"

# Create data symlink
sudo ln -sf "${DATA_DIR}" "${INSTALL_DIR}/data"

# Admin passphrase env file: created with a random value on FIRST
# run only. NEVER commit this file; NEVER pass the passphrase on the
# command line (visible in ps). If lost, delete the file and re-run —
# but note the old admin club credential is then replaced.
if [ ! -f "${ENV_FILE}" ]; then
  PASS=$(openssl rand -hex 24)
  printf 'XUDANU_ADMIN_PASSPHRASE=%s\n' "${PASS}" | sudo tee "${ENV_FILE}" >/dev/null
  sudo chmod 600 "${ENV_FILE}"
  echo ""
  echo "=== NEW ADMIN PASSPHRASE CREATED (${ENV_FILE}) ==="
  echo "Copy it into your password manager NOW; it is not shown again:"
  echo ""
  sudo cat "${ENV_FILE}"
  echo ""
  read -r -p "Press Enter once you have saved it..." < /dev/tty || true
else
  sudo chmod 600 "${ENV_FILE}"
  echo "Using existing ${ENV_FILE}"
fi

# Create systemd service
sudo tee /etc/systemd/system/xudanu.service > /dev/null <<EOF
[Unit]
Description=xudanu server
After=network.target

[Service]
Type=simple
WorkingDirectory=${INSTALL_DIR}
EnvironmentFile=${ENV_FILE}
ExecStart=${INSTALL_DIR}/xudanu-server run 127.0.0.1:8080 --static-dir dist --data-dir ${DATA_DIR} --allowed-origin https://${DOMAIN}
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
sleep 3
sudo systemctl restart caddy

echo ""
echo "=== Done ==="
echo "  xudanu:  http://localhost:8080 (internal)"
echo "  public:  https://${DOMAIN}"
echo "  data:    ${DATA_DIR}"
echo "  health:  curl -s http://127.0.0.1:8080/health"
echo ""
echo "If this was a major-version upgrade from an old data dir and the"
echo "server reports a legacy manifest, run the migration binary:"
echo "  ${INSTALL_DIR}/migrate_manifest ${DATA_DIR}"
echo ""
echo "Logs:"
echo "  sudo journalctl -u xudanu -f"
echo "  sudo journalctl -u caddy -f"
