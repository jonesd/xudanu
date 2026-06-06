# Deploying xudanu

This directory contains configuration for running xudanu in production with HTTPS, WSS, and basic auth.

## Prerequisites

- A Linux server (Ubuntu 22.04+ recommended) with a public IP
- A domain name with DNS A records pointing to your server's IP
- Ports 80 and 443 open in your server's firewall
- A xudanu release binary for your architecture (download from [Releases](https://github.com/jonesd/xudanu/releases))

## Quick Start

### 1. Install the binary

```bash
# Download the latest release (adjust version and architecture)
wget https://github.com/jonesd/xudanu/releases/latest/download/xudanu-v0.4.2-x86_64-linux-musl.tar.gz
tar -xzf xudanu-v0.4.2-x86_64-linux-musl.tar.gz
sudo mv xudanu-server /usr/local/bin/
sudo chmod +x /usr/local/bin/xudanu-server
```

### 2. Create a data directory

```bash
sudo mkdir -p /var/lib/xudanu
sudo chown $USER:$USER /var/lib/xudanu
```

### 3. Install Caddy

```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

### 4. Configure Caddy

Copy and edit the Caddyfile:

```bash
sudo cp Caddyfile /etc/caddy/Caddyfile
```

Edit `/etc/caddy/Caddyfile` and make these changes:

1. Replace `example.com` and `www.example.com` with your actual domain
2. Generate a hashed password for basic auth:

```bash
caddy hash-password --plaintext 'your-secure-password'
```

3. Replace `$2a$14$REPLACE_WITH_HASHED_PASSWORD` with the output from above

4. Reload Caddy:

```bash
sudo systemctl reload caddy
```

Caddy will automatically provision a Let's Encrypt TLS certificate for your domain within seconds. No certbot or manual certificate management needed.

### 5. Configure the xudanu service

Copy and edit the systemd unit:

```bash
sudo cp xudanu-server.service /etc/systemd/system/xudanu-server.service
```

Edit `/etc/systemd/system/xudanu-server.service` and update:

- `--allowed-origin https://example.com` — your actual domain (must include `https://`)
- `--static-dir` — path to the frontend `dist/` directory from the release tarball
- Paths to binary and data directory if you changed them

Then enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable xudanu-server
sudo systemctl start xudanu-server
```

### 6. Set up the frontend

The release tarball includes a `dist/` directory with the built frontend:

```bash
mkdir -p ~/xudanu-src/web/app
mv dist ~/xudanu-src/web/app/dist
```

Make sure the `--static-dir` path in the systemd service matches.

### 7. Verify

```bash
# Check the service is running
systemctl status xudanu-server

# Check HTTPS is working
curl -sI https://your-domain.com/

# Check the WebSocket endpoint (should hold connection open)
curl --http1.1 -H "Upgrade: websocket" -H "Connection: Upgrade" \
     -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: dGVzdA==" \
     https://your-domain.com/xudanu?format=json
```

Then open `https://your-domain.com/` in a browser.

## How It Works

```
Browser
  │
  ├── HTTPS (static pages) ──► Caddy :443 ──► xudanu :8080
  │     └─ basic auth required
  │
  └── WSS (WebSocket)    ──► Caddy :443 ──► xudanu :8080
        └─ no proxy auth (server handles its own auth)
```

- **Caddy** handles TLS termination via Let's Encrypt (auto-provisioned, auto-renewed)
- **Caddy** proxies both static HTTP and WebSocket upgrade requests to xudanu
- **xudanu** serves static files and handles WebSocket connections on port 8080
- Basic auth protects static pages; the `/xudanu` WebSocket path skips proxy auth so browsers can connect without an auth dialog blocking the upgrade

## Configuration Reference

### Caddyfile

| Setting | Purpose |
|---------|---------|
| Domain names | Replace `example.com` with your domain. Caddy uses these to provision certs. |
| `@ws path /xudanu` | Matches WebSocket upgrade requests. Must skip `basicauth` or browsers can't connect. |
| `basicauth` | Protects static pages. Remove the `handle` block with `basicauth` if you want open access. |
| `reverse_proxy localhost:8080` | Points to xudanu. Change port if you run xudanu on a different port. |

### xudanu-server CLI flags

```
xudanu-server run <bind_addr> <data_dir> [options]

Options:
  --static-dir <path>         Serve frontend static files from this directory
  --allowed-origin <url>      Allowed WebSocket origin (repeatable, use https:// URL)
  --key-passphrase <pass>     Encrypt the server key file
```

## Troubleshooting

### "Connection refused" or empty page

Check the xudanu service is running:
```bash
sudo systemctl status xudanu-server
sudo journalctl -u xudanu-server --since "5 min ago"
```

### WebSocket won't connect (browser console shows errors)

1. Make sure `--allowed-origin` includes your exact `https://` domain
2. Make sure the Caddyfile has the `@ws` handler that skips basic auth for `/xudanu`
3. Check Caddy is passing the upgrade — look for 101 responses:
   ```bash
   sudo journalctl -u caddy --since "5 min ago"
   ```

### Certificate not provisioning

Caddy needs ports 80 and 443 open to complete the Let's Encrypt HTTP-01 challenge:
```bash
# Check ports are open
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

Also verify your DNS A record points to this server's IP:
```bash
dig +short your-domain.com
```

### "Password mismatch" on login

The admin club password is set the first time you configure the server. If you forget it, you can reset by deleting the data directory and starting fresh:
```bash
sudo systemctl stop xudanu-server
rm -rf /var/lib/xudanu/*
sudo systemctl start xudanu-server
```

### Checking server version

```bash
xudanu-server --version
```

## Security Notes

- The basic auth on Caddy protects the **static pages** only — it is not the xudanu authentication system
- xudanu has its own club-based authentication for WebSocket sessions
- For production, consider adding `fail2ban` for SSH and repeated failed login attempts
- The server key file (`server.key`) is unencrypted by default — use `--key-passphrase` for production
