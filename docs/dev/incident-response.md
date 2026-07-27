# Data Integrity Incident Response & Recovery

> **When the alert fires:** Follow this document step by step.
> The alert means the server detected a potential data integrity issue.
> Stay calm — the system is designed to prevent silent data loss.

## Alert Triggers

The UI shows a red warning banner when any of these are true:

| Alert | Meaning | Severity |
|---|---|---|
| **Security log chain broken** | Tamper-evident log hash chain is invalid | Critical — possible tampering or disk corruption |
| **Restore errors detected** | Server could not load some data from disk at startup | High — data may be missing or corrupt |
| **Data verification failed** | Chunks are corrupt, missing, or deserialization errors at startup | High — disk failure or data corruption |

---

## Step 1: Assess the Situation

### Check the server health endpoint

```sh
curl -s http://127.0.0.1:8080/health | python3 -m json.tool
```

Look for:
- `status` — should be `"ok"`, `"degraded"` means problems
- `restore_errors` — list of data loading failures
- `chain_valid` — should be `true`

### Check the server logs

```sh
# Most recent server output
tail -100 /tmp/xudanu-server.log

# Search for errors
grep -i "error\|warn\|fail\|corrupt\|broken\|tamper" /tmp/xudanu-server.log | tail -50
```

### Run the verification tool

```sh
cd src-rust
cargo run --features server --bin xudanu-cli -- verify data
```

This checks:
- Security log chain integrity (hash-linked, seeded)
- Attribution log chain integrity
- Content hashes match (BLAKE3)
- All spans have valid signatures (Ed25519)
- No unsigned or modified content

Output will show PASS/FAIL for each check with specific details.

---

## Step 2: Identify the Problem Type

### A. Disk / Hardware Failure

**Symptoms:**
- `restore_errors` mention "chunk not found", "I/O error", "No such file"
- Data verification reports "missing chunks" or "deserialization errors"
- Server logs show filesystem errors

**Investigation:**
```sh
# Check disk health
diskutil info / | grep "Free Space"
smartctl -a /dev/disk0  # if smartmontools installed

# Check for missing chunk files
ls data/chunks/ | wc -l  # compare with expected count
find data/chunks/ -name "*.tmp"  # look for incomplete writes

# Check manifest integrity
python3 -c "import json; m=json.load(open('data/manifest.json')); print('works:', len(m.get('works',[])), 'checksum:', m.get('checksum','?')[:16])"
```

**Recovery:**
1. Stop the server
2. Restore from backup (if available)
3. If no backup: the server auto-suppresses checkpointing when restore errors exist, preventing further data loss. Run `xudanu-cli rebuild-manifest data` to attempt recovery
4. Replace failing hardware
5. Restart and verify

### B. Flaky Disk (Intermittent Errors)

**Symptoms:**
- Errors come and go — some chunks load, some fail randomly
- Server sometimes starts fine, sometimes reports errors
- Corrupt chunks with valid filenames but invalid content

**Investigation:**
```sh
# Check which chunks are corrupt
cargo run --features server --bin xudanu-cli -- verify data 2>&1 | grep "corrupt\|invalid"

# Check filesystem consistency
fsck -n /dev/disk0s1  # read-only check (macOS)

# Monitor disk errors over time
iostat -x 5 10  # watch for error rates
```

**Recovery:**
1. Copy the entire `data/` directory to known-good hardware immediately
2. Run `xudanu-cli verify` on the copy
3. If specific chunks are corrupt, check if they're referenced by critical works
4. Consider restoring from backup for affected works
5. Decommission the flaky drive

### C. Suspected Tampering / Attack

**Symptoms:**
- Security log chain is broken (hash chain doesn't validate)
- Attribution log chain is broken
- Content hashes don't match what was signed
- Unexpected sessions or login attempts in the audit trail

**Investigation:**

#### Trace the security log breach
```sh
# The security log is hash-chained. Each entry's hash includes the previous entry's hash.
# A broken chain means an entry was inserted, modified, or deleted.

# Check the security log files
ls -la data/security.log.*
cat data/security.log.seed  # the initial seed (64 bytes hex)

# Examine recent security events
grep "SECURITY:" /tmp/xudanu-server.log | tail -30

# Look for suspicious activity:
grep -E "login_failed|rate_limited|csrf_invalid|origin_rejected|backlink_rate" /tmp/xudanu-server.log
```

#### Identify modified documents
```sh
# Run full verification — this checks every work's content hash and signatures
cargo run --features server --bin xudanu-cli -- verify data

# The output will show:
# - Which works have unsigned spans (content without valid attribution)
# - Which works have hash mismatches (content was modified after signing)
# - Which spans have invalid signatures
```

#### Trace the action to a user/session
The security log records these events with session IDs and IP addresses:

| Event | What it tells you |
|---|---|
| `SECURITY:login_succeeded` | Who logged in and when (club_id, session_id, timestamp) |
| `SECURITY:login_failed` | Failed login attempts (possible brute force) |
| `SECURITY:login_rate_limited` | Rate limiting triggered (automated attack) |
| `SECURITY:ws_csrf_invalid` | Invalid CSRF token (possible session hijacking) |
| `SECURITY:ws_origin_rejected` | WebSocket from unapproved origin (possible CSRF) |
| `SECURITY:backlink_rate_ip` | Cross-server backlink flood (possible DoS) |
| `SECURITY:federation_identity_mismatch` | Federation peer identity mismatch |
| `SECURITY:ticket_redeemed` | Session ticket used for auto-login |

```sh
# Find all actions by a specific session
grep "session=<SUSPECT_SESSION_ID>" /tmp/xudanu-server.log

# Find all logins from a specific IP
grep "remote.*<SUSPECT_IP>" /tmp/xudanu-server.log

# Check the attribution log for who modified a specific work
# The attribution log records span-level provenance:
#   author_public_key, char range, signature, timestamp
ls data/attribution/
```

#### Check the attribution log
The attribution log is ALSO hash-chained and records every text edit:
- **Author public key** — who made the edit
- **Character range** — what part of the document changed
- **Ed25519 signature** — cryptographic proof of authorship
- **Server signature** — server co-signed the edit
- **Timestamp** — when the edit was made

```sh
# Verify the attribution log chain
cargo run --features server --bin xudanu-cli -- verify data --attribution-only
```

If the attribution log chain is intact but the security log chain is broken,
the attacker modified the security log but couldn't forge attribution
(requires the server's private key).

If BOTH chains are broken, the attacker may have access to the server's key file
(`server.key`). Check:
```sh
ls -la data/server.key data/key_history.json
# Check if the key file was modified
stat data/server.key  # compare modification time with known-good time
```

**Recovery from tampering:**
1. **Stop the server immediately**
2. **Preserve evidence** — copy the entire `data/` directory before any recovery
3. **Rotate the server key** — run with `--rotate-keys` to generate a new key pair
4. **Check all sessions** — force re-authentication for all users
5. **Revoke session tickets** — delete the ticket nonces from the manifest
6. **Audit affected works** — use the attribution log to identify legitimately modified content
7. **Restore from backup** if the tampering is extensive
8. **Patch the vulnerability** that allowed the attack

---

## Step 3: Recovery Actions

### Rebuild the manifest
If the manifest is corrupt but chunks are intact:
```sh
cargo run --features server --bin xudanu-cli -- rebuild-manifest data
```

### Force verification
Full integrity check with details:
```sh
cargo run --features server --bin xudanu-cli -- verify data --verbose
```

### Restore from backup
```sh
# Stop server first
./scripts/stop.sh

# Backup current (potentially corrupt) state
cp -r data/ data.corrupt.$(date +%Y%m%d)/

# Restore from backup
cp -r data.backup/ data/

# Verify the restore
cargo run --features server --bin xudanu-cli -- verify data

# Restart
./scripts/start-llm.sh
```

### Clear restore errors (after investigation)
If you've investigated and resolved the restore errors, clear them to
re-enable auto-checkpointing:
```sh
# Via the admin API (requires admin session)
# Or restart the server — restore errors are cleared on successful startup
```

---

## Log File Locations

| File | Purpose |
|---|---|
| `/tmp/xudanu-server.log` | Server runtime output (tracing) |
| `data/security.log.seed` | Initial hash for the security log chain |
| `data/security.log.YYYY-MM-DD` | Daily rotated security log (hash-chained) |
| `data/attribution/` | Attribution log files (hash-chained, per-work provenance) |
| `data/manifest.json` | Work/club/edition index with checksum |
| `data/manifest_v*.json.bak` | Manifest backups (rotated) |
| `data/chunks/` | Content-addressed chunk store (BLAKE3 hashed) |
| `data/key_history.json` | Server key rotation history |
| `data/server.key` | Server Ed25519 signing key |

## Preventive Measures

1. **Regular backups** — schedule `cp -r data/ data.backup.$(date +%F)/` daily
2. **Regular verification** — schedule `xudanu-cli verify data` weekly
3. **Monitor disk health** — use SMART monitoring
4. **Keep the server key secure** — protect `data/server.key`
5. **Enable TLS** — use `--tls-cert/--tls-key` for production
6. **Monitor the health endpoint** — alert on `status != "ok"` or `chain_valid == false`

## Audit Trail Summary

The system maintains three layers of audit:

1. **Security log** (tamper-evident, hash-chained) — login/logout, CSRF, rate limiting, all security-relevant events. Seeded by `security.log.seed`, rotated daily.

2. **Attribution log** (tamper-evident, hash-chained) — every text edit with author public key, character range, Ed25519 signature, server co-signature, and timestamp. Stored per-work.

3. **Content hashes** (BLAKE3) — every chunk is content-addressed. Modifying content changes the hash, breaking the reference. Signed spans include the content hash in the signature.

An attacker would need to break Ed25519, SHA-256 hash chains, AND BLAKE3 content addressing to forge a document without detection.
