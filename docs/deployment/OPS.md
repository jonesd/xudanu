# Server Operations Guide

## Server Details

| Item | Value |
|------|-------|
| Provider | Hetzner Cloud |
| Server | CX23 (2 vCPU, 4GB RAM, 40GB SSD) |
| Location | Falkenstein, Germany (fsn1) |
| IPv4 | 178.105.99.41 |
| IPv6 | 2a01:4f8:c013:28b3::/64 |
| OS | Ubuntu 26.04 |
| Domain | xudanu.com |

Store the following in a password manager (NOT in this file):
- Server root password (or SSH key location)
- Xudanu key passphrase
- DNS provider credentials (Porkbun)

## Access

```bash
ssh root@178.105.99.41
```

## Architecture

```
Internet → Caddy (HTTPS, Let's Encrypt, :80/:443)
             → Xudanu (HTTP, :8080, Docker internal)
```

- Caddy: auto-renews TLS certificates
- Xudanu: serves the app + WebSocket + public API
- Data: Docker volume `xudanu_xudanu-data` at `/data` in container

## Daily Operations

### Check server health
```bash
curl https://xudanu.com/health
docker compose ps
```

### View logs
```bash
cd /opt/xudanu
docker compose logs -f xudanu    # Xudanu server logs
docker compose logs -f caddy      # Caddy/proxy logs
```

### Restart services
```bash
cd /opt/xudanu
docker compose restart
```

### Check disk space
```bash
df -h
docker system df    # Docker storage usage
```

## Updates

### Update Xudanu to latest version
```bash
cd /opt/xudanu/repo
git pull
docker build -t xudanu:latest .
cd /opt/xudanu
docker compose up -d
```

### Update Caddy
```bash
cd /opt/xudanu
docker compose pull caddy
docker compose up -d
```

### Update OS
```bash
apt update && apt upgrade -y
```

Reboot if kernel updated:
```bash
reboot
```

## Backups

### Automated (daily at 3am)
Cron job backs up the data volume to `/opt/backups/`, keeps 7 days:
```bash
ls -la /opt/backups/
```

### Manual backup
```bash
cd /opt/xudanu
docker run --rm -v xudanu_xudanu-data:/data -v /opt/backups:/backup \
  ubuntu tar czf /backup/xudanu-manual-$(date +%Y%m%d-%H%M).tar.gz /data
```

### Off-site backup (to your Mac)
```bash
scp root@178.105.99.41:/opt/backups/xudanu-latest.tar.gz ~/Backups/
```

### Restore from backup
```bash
cd /opt/xudanu
docker compose down
docker run --rm -v xudanu_xudanu-data:/data -v /opt/backups:/backup \
  ubuntu bash -c "rm -rf /data/* && tar xzf /backup/xudanu-YYYYMMDD.tar.gz -C /"
docker compose up -d
```

## Security

### Firewall
```bash
ufw status
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP (Caddy redirect)
ufw allow 443/tcp   # HTTPS
```

### Fail2ban (brute-force protection)
```bash
fail2ban-client status
fail2ban-client status sshd
```

### SSH hardening (recommended)
Edit `/etc/ssh/sshd_config`:
```
PermitRootLogin prohibit-password
PasswordAuthentication no
```
Then: `systemctl restart sshd`
(Only do this after confirming SSH key login works)

## Monitoring

### Check running containers
```bash
docker compose ps
```

### Check resource usage
```bash
htop              # CPU/RAM
docker stats      # Container stats
```

### Check Xudanu health endpoint
```bash
curl -s https://xudanu.com/health | python3 -m json.tool
```

Key fields:
- `status: "ok"` — server healthy
- `works` — document count
- `clubs` — user count
- `chain_valid: true` — security log intact
- `restore_errors: null` — no data corruption

## Troubleshooting

### Server won't start
```bash
docker compose logs xudanu | tail -30
```

### Caddy certificate issues
```bash
docker compose logs caddy | tail -30
```

Caddy auto-renews 30 days before expiry. If DNS is correct, it just works.

### WebSocket not connecting
- Check `ufw status` allows port 443
- Check Caddy is running: `docker compose ps`
- Check Xudanu is running: `curl http://localhost:8080/health` from inside the container

### Out of disk space
```bash
docker system prune -a    # Remove unused images/containers
rm /opt/backups/xudanu-*.tar.gz   # Clear old backups manually
```

## DNS Management

DNS is at Porkbun. Records:
```
A    xudanu.com        178.105.99.41
A    www.xudanu.com    178.105.99.41
```

After changing IP, update DNS and wait 5-10 minutes for propagation.

## Disaster Recovery

If the server is destroyed:
1. Create new Hetzner server
2. Install Docker (see PRODUCTION.md)
3. Restore backup to new server
4. Update DNS to new IP
5. Caddy auto-obtains new certificate

The server's Ed25519 keypair is in the backup (encrypted with passphrase). Without it, the server gets a new identity and all TOFU pins/tumblers break.
