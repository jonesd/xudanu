# TLS / HTTPS Setup Guide

Xudanu supports TLS for encrypted HTTPS and WSS (WebSocket Secure) connections. This is required for:
- Remote access over the internet
- Browser features that require a secure context (Safari requires HTTPS for WebSocket)
- Production deployments

## Security Warning

**TLS only encrypts the connection -- it does not control who can access the server.**

The server's built-in Club-based access control (clubs, read/edit permissions, admin roles, user accounts) is **not yet fully implemented** for production use. Without additional protection, anyone who can reach the server can read, edit, and delete all documents.

**Before exposing to the internet, add an authentication layer.** The recommended approach:

- **Caddy** with HTTP Basic Auth (see below -- easiest, handles both TLS and auth)
- **nginx** with HTTP Basic Auth or OAuth2 proxy
- **Cloudflare Tunnel** with Access policies
- **Tailscale / WireGuard** for private network access

## Overview

There are four ways to run with TLS and/or auth:

| Method | Use case | TLS | Auth | Effort |
|--------|----------|-----|------|--------|
| Plain HTTP | Local dev only | No | No | None |
| Caddy reverse proxy | **Recommended for internet** | Yes | Yes | Low |
| Self-signed certificate | Testing, internal | Yes | No | Low |
| Let's Encrypt + certbot | Production (no Caddy) | Yes | No | Medium |

## 1. Plain HTTP (Local Development)

```bash
./target/debug/xudanu-server run 127.0.0.1:8090 /tmp/xudanu-data --static-dir ./static
```

Works in Firefox. Safari may refuse WebSocket connections to non-HTTPS endpoints depending on version.

## 2. Caddy Reverse Proxy (Recommended)

Caddy provides HTTPS + password protection + WebSocket proxying in a single binary. This is the **recommended approach** for any server accessible beyond localhost.

### Install

```bash
brew install caddy          # macOS
sudo apt install caddy      # Ubuntu/Debian
```

### Local Development

Start Xudanu and Caddy together:

```bash
./scripts/caddy.sh
```

This gives you `https://localhost:8443` with HTTP Basic Auth. Default credentials: `admin` / `changeme`.

### Production

1. Point your domain's DNS to your server IP.
2. Uncomment the production block in `Caddyfile` and set your domain.
3. Change the password hash:

```bash
caddy hash-password --plaintext 'your-secure-password'
# Replace the hash in Caddyfile
```

4. Start:

```bash
./scripts/caddy.sh production
```

Caddy will automatically obtain a Let's Encrypt certificate and handle renewal. No certbot needed.

### How It Works

```
Browser --HTTPS--> Caddy (:443) --HTTP--> Xudanu (:8090)
              Basic Auth         No TLS needed
```

Xudanu runs plain HTTP on localhost. Caddy terminates TLS and enforces Basic Auth before proxying requests through. WebSocket connections are upgraded automatically.

## 3. Self-Signed Certificate (Testing)

Generate a certificate valid for `localhost` and `127.0.0.1`:

```bash
openssl req -x509 -newkey rsa:2048 \
  -keyout key.pem -out cert.pem \
  -days 365 -nodes \
  -subj '/CN=localhost' \
  -addext 'subjectAltName=DNS:localhost,IP:127.0.0.1'
```

Start the server:

```bash
./target/debug/xudanu-server run 0.0.0.0:443 /tmp/xudanu-data \
  --tls-cert cert.pem --tls-key key.pem
```

Connect at `https://localhost`. Your browser will warn about the untrusted certificate -- accept it to proceed. This is fine for testing.

## 4. Let's Encrypt (Production)

Let's Encrypt provides free, trusted TLS certificates. Each server operator gets their own certificate for their own domain -- there is no conflict between different people running Xudanu servers.

### Prerequisites

- A **domain name** pointing to your server's public IP (e.g., `xudanu.example.com`)
- Port **80** and **443** open in your firewall
- Your server reachable from the internet (Let's Encrypt verifies domain ownership)

### Step 1: DNS Setup

Point your domain's A record to your server's public IP:

```
xudanu.example.com.  A  203.0.113.50
```

Wait for DNS propagation (usually minutes, sometimes up to 48 hours). Verify with:

```bash
dig xudanu.example.com
```

### Step 2: Install Certbot

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install certbot

# macOS
brew install certbot

# Other: https://certbot.eff.org/
```

### Step 3: Obtain a Certificate

Stop any service using port 80, then run:

```bash
sudo certbot certonly --standalone -d xudanu.example.com
```

Certbot will:
1. Verify you control the domain (via HTTP challenge on port 80)
2. Issue a certificate valid for 90 days
3. Store files in `/etc/letsencrypt/live/xudanu.example.com/`

### Step 4: Run Xudanu with TLS

```bash
./target/debug/xudanu-server run 0.0.0.0:443 /path/to/data \
  --tls-cert /etc/letsencrypt/live/xudanu.example.com/fullchain.pem \
  --tls-key /etc/letsencrypt/live/xudanu.example.com/privkey.pem
```

Connect at `https://xudanu.example.com` -- no browser warnings.

### Step 5: Auto-Renewal

Let's Encrypt certificates expire after 90 days. Certbot installs a renewal timer by default. Test it:

```bash
sudo certbot renew --dry-run
```

Set up automatic restart after renewal. Create a deploy hook:

```bash
sudo tee /etc/letsencrypt/renewal-hooks/deploy/restart-xudanu.sh << 'EOF'
#!/bin/bash
systemctl restart xudanu
EOF
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/restart-xudanu.sh
```

### Running as a Systemd Service

Create `/etc/systemd/system/xudanu.service`:

```ini
[Unit]
Description=Xudanu Server
After=network.target

[Service]
Type=simple
User=xudanu
WorkingDirectory=/opt/xudanu
ExecStart=/opt/xudanu/xudanu-server run 0.0.0.0:443 /opt/xudanu/data \
  --tls-cert /etc/letsencrypt/live/xudanu.example.com/fullchain.pem \
  --tls-key /etc/letsencrypt/live/xudanu.example.com/privkey.pem \
  --static-dir /opt/xudanu/static
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo useradd -r -s /bin/false xudanu
sudo mkdir -p /opt/xudanu/data
sudo cp target/release/xudanu-server /opt/xudanu/
sudo cp -r static /opt/xudanu/
sudo chown -R xudanu:xudanu /opt/xudanu

# Let the xudanu user read TLS certs
sudo usermod -aG ssl-cert xudanu

sudo systemctl daemon-reload
sudo systemctl enable xudanu
sudo systemctl start xudanu
```

## Multi-Domain Certificates

To serve multiple domains (e.g., `xudanu.example.com` and `docs.example.com`) with one certificate:

```bash
sudo certbot certonly --standalone \
  -d xudanu.example.com \
  -d docs.example.com
```

Use the same `--tls-cert` and `--tls-key` paths. The certificate will be valid for both domains.

## Firewall Configuration

```bash
# Allow HTTPS and HTTP (for Let's Encrypt challenges)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# If also running on plain HTTP locally
sudo ufw allow 8090/tcp
```

## Troubleshooting

**Safari won't connect to localhost over HTTPS:**
- Safari requires the certificate to include `127.0.0.1` in Subject Alternative Names (SAN)
- The self-signed cert command above includes this
- For local testing, Firefox is more forgiving

**Certificate not trusted in browser:**
- Self-signed certs are never automatically trusted -- click through the warning
- Let's Encrypt certs are trusted by all major browsers automatically

**certbot fails with "Connection refused":**
- Ensure port 80 is open and no other service is using it
- Check your DNS points to the correct IP: `dig yourdomain.com`

**Permission denied reading TLS certs:**
- Let's Encrypt certs are readable by root only by default
- Add the xudanu user to the `ssl-cert` group: `sudo usermod -aG ssl-cert xudanu`
- Or copy certs to a readable location (less secure)

## Rate Limits

Let's Encrypt has rate limits per account:
- **50 certificates per registered domain per week**
- **5 duplicate certificates per week**
- **10 registrations per IP address per 3 hours**

These limits apply to your account, not to Xudanu. Different server operators each have their own Let's Encrypt accounts and domains, so there is no interference between Xudanu instances.

For testing, use the Let's Encrypt **staging environment** (no rate limits, but certs aren't publicly trusted):

```bash
sudo certbot certonly --standalone -d xudanu.example.com --test-cert
```

## Multiple Independent Servers

Each person running their own Xudanu server needs:
1. Their own domain name (e.g., `alice.example.com`, `bob.example.org`)
2. Their own Let's Encrypt certificate for that domain
3. Their own server.json data directory

There is no shared state or conflict. This works the same way as running multiple nginx or Apache servers -- each domain gets its own certificate.
