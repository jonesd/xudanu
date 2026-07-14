# Security Testing Tool

## Overview

The `security-test` command tests the public API security controls on a running
xudanu server. It verifies rate limiting, input validation, size caps, CORS
headers, and backlink notification handling.

## Quick Start

```sh
# Build the CLI
cd original-code/xanadugold/src-rust
./rebuild.sh

# Run against a running server
./target/release/xudanu-cli security-test http://localhost:8080
```

Or via cargo:
```sh
cargo run --release --features server --bin xudanu-cli -- security-test http://localhost:8080
```

## What It Tests

| # | Test | What it checks | Expected |
|---|------|---------------|----------|
| 1 | Health endpoint | Server is alive | 200 |
| 2 | Well-known identity | Server identity published | 200 + server_id |
| 3 | Valid work ID | Hex IDs accepted | 200 or 404 |
| 4 | Invalid work ID | Non-hex rejected | 400 |
| 5 | Rate limiting | 130 rapid requests | 429 after 120 |
| 6 | Backlink notify | Valid accepted, invalid rejected | 200 / 400 |
| 7 | Size cap | 10KB payload | 413 |
| 8 | CORS headers | Access-Control-Allow-Origin present | header exists |
| 9 | Range cap | 2M char range | 400 |

## Sample Output

```
=== Xudanu Security Test ===
Target: http://localhost:8080

[1] Health endpoint
  [PASS] health returns 200 - status: 200

[2] Well-known identity
  [PASS] well-known returns 200 - status: 200
  [PASS] has server_id - server identity present

[5] Rate limiting (flooding 130 requests)
    Rate limited at request #121
  [PASS] rate limit triggers - last status: 429
    Waiting 60s for rate limit reset...

=== Summary ===
  Passed:   13
  Failed:   0
  Warnings: 0
```

## Current Protection Limits

| Protection | Limit |
|-----------|-------|
| GET rate limit | 120/min per IP |
| Backlink rate limit | 30/hour per IP + per server |
| Backlink body size | 8KB max |
| Range request size | 1M chars max |
| Content fetch size | 5MB max (existing) |
| Work ID format | Hex, max 8 chars |
| Content hash format | 64 hex chars |
| Tumbler format | Domain or numeric, max 256 chars |

## Advanced Attack Patterns (Manual)

### DDoS Simulation (rate limit bypass attempt)

```sh
for i in $(seq 1 200); do
  curl -s -o /dev/null -w "%{http_code}\n" \
    -H "User-Agent: bot-$i" \
    http://localhost:8080/api/public/work/0001
done
```
Expected: 200s for first 120, then 429s.

### Backlink Spam (per-server limit)

```sh
for i in $(seq 1 35); do
  curl -s -o /dev/null -w "%{http_code}\n" \
    -X POST http://localhost:8080/api/backlink-notify \
    -H "Content-Type: application/json" \
    -d "{\"target_work_id\":\"0001\",\"origin_server_address\":\"evil.com\",\"origin_server_name\":\"evil\",\"origin_work_id\":\"0002\",\"origin_work_title\":\"spam\",\"excerpt\":\"$i\",\"link_type\":\"spam\"}"
done
```
Expected: 200s for first 30, then 429s.

### Injection Attempt

```sh
# Path traversal in work ID
curl -s -o /dev/null -w "%{http_code}\n" \
  http://localhost:8080/api/public/work/..%2F..%2Fetc%2Fpasswd
# Expected: 400

# XSS in backlink
curl -s -X POST http://localhost:8080/api/backlink-notify \
  -H "Content-Type: application/json" \
  -d '{"target_work_id":"0001","origin_server_address":"evil.com","origin_server_name":"<script>alert(1)</script>","origin_work_id":"0002","origin_work_title":"test","excerpt":"test","link_type":"ref"}'
# Expected: 200 (stored as text, not rendered as HTML)
```

### Large Payload Attack

```sh
# 1MB backlink body
curl -s -o /dev/null -w "%{http_code}\n" \
  -X POST http://localhost:8080/api/backlink-notify \
  -H "Content-Type: application/json" \
  -d "$(python3 -c 'print("x"*1000000)')"
# Expected: 413
```

### Tumbler Validation

```sh
curl -s -o /dev/null -w "%{http_code}\n" \
  "http://localhost:8080/api/public/work/0001?tumbler=';DROP TABLE"
# Expected: 400 or 404
```

## What's NOT Protected Yet

- **Backlink signature verification** - the POST endpoint accepts any JSON.
  Ed25519 signature verification is planned (origin server signs the
  notification with its key).
- **Rate limit persistence** - rate limits reset on server restart (in-memory
  only).
- **Per-user rate limits** - only per-IP and per-server limits exist.

## CORS Policy

CORS behavior depends on server mode:

### Dev Mode (`--dev` flag)

```sh
xudanu-server run 127.0.0.1:8080 data --dev
```

All endpoints return `Access-Control-Allow-Origin: *`. Use for local
development when testing from a browser on a different port.

### Production Mode (default, no `--dev`)

| Endpoint | CORS Header | Why |
|----------|-------------|-----|
| `GET /.well-known/xudanu-server.json` | `*` | Public discovery data |
| `GET /api/public/work/{id}` | `*` | Public read-only content |
| `GET /api/public/work/{id}/range/*` | `*` | Public read-only content |
| `POST /api/backlink-notify` | None | Server-to-server only, no browser |
| `WS /xudanu` | Origin check | Via `--allowed-origin` flags |

### restart.sh

`restart.sh` runs without `--dev` (production mode). For local development
with browser testing, add `--dev`:

```sh
# Edit restart.sh or run manually:
xudanu-server run 127.0.0.1:8080 data --dev
```

## Audit Log

All security events are logged to the server's tracing output:

```
SECURITY:rate_limited_get - public API rate limit exceeded
SECURITY:backlink_rate_ip - backlink rate limit (IP) exceeded
SECURITY:backlink_rate_server - backlink rate limit (server) exceeded
SECURITY:oversized_backlink - backlink notify body too large
CROSS_SERVER:backlink_received - successful backlink (with IP + origin + work)
```

These appear in the server's stdout/stderr and the chained security log
(`data/security.log.*`).
