# Production Deployment Guide — xudanu.com

## Server: Hetzner CX32 (4 vCPU, 8GB RAM, 80GB SSD)

### 1. Create Server

1. Sign up at hetzner.com
2. Create server:
   - **Type:** CX32 (4 vCPU, 8GB RAM, 80GB)
   - **Location:** Germany (Falkenstein or Helsinki)
   - **OS:** Ubuntu 24.04
   - **SSH Key:** Add your public key
3. Note the server IP address

### 2. DNS Setup

Point `xudanu.com` to your server:

```
A    xudanu.com    <SERVER_IP>    3600
A    www.xudanu.com    <SERVER_IP>    3600
```

Do this at your DNS provider (Cloudflare, Namecheap, etc.)

### 3. Initial Server Setup (SSH in)

```bash
ssh root@<SERVER_IP>

# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh

# Install security tools
apt install -y fail2ban ufw

# Firewall: only allow SSH, HTTP, HTTPS
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Create app directory
mkdir -p /opt/xudanu
cd /opt/xudanu
```

### 4. Deploy

Copy these files to `/opt/xudanu/`:
- `docker-compose.prod.yml` (below)
- `Caddyfile` (below)

Then:
```bash
cd /opt/xudanu
docker compose -f docker-compose.prod.yml up -d
```

### 5. Verify

```bash
# Health check
curl http://localhost:8080/health

# HTTPS (after DNS propagates, ~5 minutes)
curl https://xudanu.com/health
```

Open `https://xudanu.com` in your browser.

### Maintenance

```bash
# View logs
docker compose -f docker-compose.prod.yml logs -f

# Restart
docker compose -f docker-compose.prod.yml restart

# Update (after git pull + docker build)
docker compose -f docker-compose.prod.yml up -d --build

# Backup data
docker run --rm -v xudanu-data:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/xudanu-backup-$(date +%Y%m%d).tar.gz /data
```
