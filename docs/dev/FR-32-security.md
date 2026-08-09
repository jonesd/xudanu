# FR-32: Security Model

## Overview

Xudanu's cross-server security is built in layers. Each layer addresses
specific threats. The design follows Nelson's Rule 8 ("permission to link
is granted by publication") and Rule 16 ("transactions are secure and
auditable") while adding modern cryptographic verification that Gold
never had.

## Threat Model

### What we protect against

| Threat | Mitigation | FR |
|--------|-----------|-----|
| Content tampering in transit | BLAKE3 hash verification | 32.1 |
| Server impersonation | Ed25519 signature enforcement | 32.2 |
| Key compromise (stolen private key) | Key rotation + revocation | 32.3 |
| First-connection MITM | TOFU + signed introductions | 32.4 |
| DNS rebinding attack | DNS resolution guard | 32.5 |
| Private network scanning (SSRF) | Lexical + DNS IP blocking | 32.6 |
| Cloud metadata exfiltration | Metadata endpoint blocklist | 32.6 |
| Signature brute-force | Consecutive failure tracking + quarantine | 32.7 |
| Rotation-based DoS | Rate limiting (3/hour/server) | 32.8 |
| Signature stripping (HTTP) | Unsigned responses rejected when key pinned | 32.2 |
| Rotation replay attack | Signed payload key must match response key | 32.3 |
| XSS from remote content | React text rendering + sanitize module | 32.9 |
| Path traversal (work ID) | Character whitelist on URL construction | 32.9 |
| Protocol injection | Dangerous protocol blocking (javascript:, data:) | 32.9 |
| Clickjacking | X-Frame-Options: DENY header | 32.10 |
| MIME sniffing | X-Content-Type-Options: nosniff header | 32.10 |
| CSP bypass | Content-Security-Policy header | 32.10 |

### What we don't protect against (known limitations)

| Gap | Impact | Future Fix |
|-----|--------|------------|
| Private key theft (no rotation performed) | Full impersonation until rotated | User education + monitoring |
| First-connection MITM (no introductions available) | Attacker's key pinned | Out-of-band fingerprint verification |
| HTTP fallback (no HTTPS pinned) | Transport metadata exposed | Self-signed TLS + cert TOFU (FR-35) |
| No anomaly detection on introduction patterns | Malicious server could vouch for many fakes | Reputation scoring (FR-38) |

## Layer 1: Content Integrity (BLAKE3)

Every piece of content has a BLAKE3 hash. When Server B fetches from
Server A, the hash is computed on the fetched text and compared against
the expected hash (embedded in the tumbler reference).

```rust
let content_hash = blake3::hash(text.as_bytes());
if content_hash != expected_hash {
    return Err("content hash mismatch — possible tampering");
}
```

**Properties:**
- 256-bit security against collisions
- Hash is permanent (embedded in tumblers on other servers)
- Content can't be silently altered after linking
- If source edits the work, the hash changes — old transclusions
  still serve from cache with correct hash

**Code:** `server.rs` — content hash verification in `resolve_cross_server_ref`
and `fetch_remote_work`.

## Layer 2: Server Authenticity (Ed25519)

Every response from a remote server includes:
- `server_signature` — Ed25519 signature over `hash|server_id|revision`
- `server_public_key` — the signing key (hex)

**Verification flow:**
1. Parse signature and public key from response
2. Verify signature against the payload
3. Check signed payload's `new_signing_key` matches response key
   (replay protection)
4. If verification fails → reject content, record failure

**Code:** `server.rs:verify_signed_response()` — extracted as testable
function, 11 unit tests + 12 property-based tests.

## Layer 3: TOFU Key Pinning

On first verified interaction, the server's Ed25519 public key is
pinned in the directory entry (`pinned_key` field).

**Subsequent connections:**
- Response key compared against pinned key
- Match → accept, update trust metrics
- Mismatch → check for key rotation (Layer 4)
- No rotation proof → reject with clear error

**Properties:**
- Prevents silent key substitution after first contact
- Pinned key persisted in `server_directory.json` (survives restart)
- Pinning is automatic (no user action needed)
- TOFU reset: untrust + re-trust clears the pin

**Limitation:** First-connection MITM can pin attacker's key. Mitigated
by signed introductions (Layer 5).

## Layer 4: Key Rotation (Recovery from Compromise)

When a server's private key is compromised, the operator rotates:
1. Generate new keypair
2. Old key signs the transition (`KeyRotationPayload`)
3. Rotation proof published in `/.well-known/xudanu-server.json`
4. Other servers verify the chain

**Multi-hop chain verification:**
- Server publishes full `rotation_chain` array (all proofs)
- Verifier walks chain from pinned key to current key
- Each hop independently verified (signature + replay protection)
- Example: K0→K1→K2→K3, pinned K0, reaches K3

**Replay protection:**
- Signed payload contains `new_signing_key` field
- This field is decoded and compared against the response key
- Attacker can't replay a valid proof with a different key
- If payload key ≠ response key → "rotation replay detected"

**Code:** `server.rs:verify_key_rotation()`, `verify_rotation_chain()`,
`verify_one_hop()` — 14 unit tests.

## Layer 5: Signed Introductions (Web of Trust)

When Server A trusts Server B:
- A automatically signs B's identity (target_id + key + address + timestamp)
- Signature published at `GET /api/introductions`
- Server C verifies A's signature using A's pinned key
- C can add B without direct first-connection risk

**Introduction payload (signed by introducer):**
```
target_server_id | target_verifying_key | target_address | introduced_by | timestamp
```

**Trust metrics included:**
- `known_since` — when introducer first added the target
- `successful_resolutions` — count of verified interactions

This mitigates TOFU's first-connection gap: if you trust Alice, and
Alice vouches for Bob, you can add Bob with reduced MITM risk.

## Layer 6: SSRF Prevention

### Lexical check (`is_ssrf_address`)
Blocks known-private addresses by string inspection:
- `localhost`, `127.0.0.1`, `::1`, `0.0.0.0`
- Private ranges: `10.x`, `172.16-31.x`, `192.168.x`
- Link-local: `169.254.x` (cloud metadata)
- Hex-encoded IPs: `0x7f000001`

### DNS resolution check (`resolve_and_verify_host`)
Resolves hostname via `ToSocketAddrs`, then checks every resolved IP:
- All private/loopback/link-local IPs blocked
- CGNAT range (100.64.0.0/10) blocked
- IPv6 ULA (fc00::/7) and link-local (fe80::/10) blocked
- `--allow-loopback` flag bypasses for testing only

**Why both checks:** Lexical check catches IP literals. DNS check catches
hostnames that resolve to private IPs (DNS rebinding attacks).

**Code:** `server.rs:is_ssrf_address()`, `resolve_and_verify_host()` —
wired into `http_get_json`, `http_get_json_https`, `http_post_json`.
17 unit tests.

## Layer 7: Attack Detection

### Consecutive signature failure tracking
- `CrossServerSecurityTracker` tracks failures per server
- Alert at 5 consecutive failures (`SIG_FAILURE_THRESHOLD`)
- Alert resets on any success

### Quarantine enforcement
- At threshold: server directory entry marked `quarantined = true`
- All future resolutions blocked immediately
- Quarantine persisted (survives restart)
- Cleared by: untrust → re-trust

### Rotation rate limiting
- Max 3 rotation attempts per server per hour
- Prevents rotation-based DoS
- Time-window reset

### Security event logging
All events use `tracing` with `target: "xudanu::security"`:

| Event | When | Level |
|-------|------|-------|
| `SECURITY:sig_failed` | Signature verification fails | WARN |
| `SECURITY:sig_stripping` | Unsigned response with pinned key | WARN |
| `SECURITY:brute_force_alert` | 5+ consecutive failures | ERROR |
| `SECURITY:rotation_failed` | Rotation verification fails | WARN |
| `SECURITY:rotation_rate_exceeded` | Too many rotation attempts | WARN |
| `SECURITY:wk_fetch_failed` | Well-known endpoint unreachable | WARN |
| `SECURITY:quarantine_block` | Resolution to quarantined server | WARN |
| `SECURITY:server_quarantined` | Server quarantined | WARN |
| `SECURITY:ws_origin_rejected` | WebSocket origin not allowed | WARN |
| `SECURITY:rate_limited_get` | Public API rate limited | WARN |

**Code:** `server.rs:CrossServerSecurityTracker`,
`handle_security_alert()` — 9 unit tests.

## Layer 8: Frontend Security

### Remote content sanitize module (`security/remote-content.ts`)
- `sanitizeAddress()` — rejects private IPs, localhost, metadata endpoints
- `buildRemoteWorksUrl()` / `buildRemoteWorkUrl()` — path traversal prevention
- `validateRemoteWorksResponse()` / `validateRemoteWorkResponse()` — schema validation
- `sanitizeRemoteText()` / `sanitizeRemoteTitle()` — control char stripping, truncation
- `sanitizeHref()` — blocks javascript:, data:, vbscript: protocols

108 frontend tests.

### XSS prevention
- All remote content rendered as React text nodes (auto-escaped)
- `dangerouslySetInnerHTML` only used with `escapeHtml()` (consolidated utility)
- CSP header blocks inline scripts

### Security headers (middleware)
Applied to all HTTP responses:
- `X-Frame-Options: DENY`
- `X-Content-Type-Options: nosniff`
- `Content-Security-Policy: default-src 'self'; script-src 'self'; ...`
- `Permissions-Policy: camera=(), microphone=(), geolocation=(), payment=()`
- `Cross-Origin-Embedder-Policy: require-corp`
- `Cross-Origin-Opener-Policy: same-origin`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Strict-Transport-Security: max-age=31536000; includeSubDomains`

## Verification Results

| Tool | Result |
|------|--------|
| OWASP ZAP | 0 FAIL, 61 PASS |
| cargo-audit | 0 CVEs |
| Semgrep | 0 real findings (all false positives) |
| CodeQL | 0 open alerts |
| Property tests | 12 properties × 256 cases, all pass |
| Fuzz tests | 24 edge cases, no panics |
| Adversarial tests | 5 attack scenarios, all rejected |

## What Gold Had vs What We Built

Gold had **no cross-server transport** and **no cryptographic verification**.
Content authenticity relied on trust in the server operator.

Xudanu adds defense-in-depth: content integrity (BLAKE3), server
authenticity (Ed25519), key management (TOFU + rotation), attack
detection (quarantine), and frontend hardening (sanitize module +
security headers).

The security model is designed so that **compromise of a single server
does not compromise the network**. Content is hash-pinned, attribution
is cryptographically signed, and trust is managed per-server with
quarantine available for bad actors.
