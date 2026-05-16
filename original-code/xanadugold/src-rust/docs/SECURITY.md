# Xudanu Security

This document catalogs the security architecture, cryptographic mechanisms, and operational practices in Xudanu.

## Threat Model

Xudanu assumes a network-level adversary that can observe, intercept, and modify traffic between clients and servers, and between federated servers. It does **not** defend against a compromised server operator — the server holds decrypted keys in memory during operation.

**In scope:**
- Eavesdropping on client-server and server-server communication
- Man-in-the-middle attacks on transport and federation links
- Brute-force authentication attacks
- Session hijacking via ID prediction
- CRDT edit forgery and repudiation

**Out of scope:**
- Server-side key exfiltration by a compromised operator
- Side-channel attacks on the host machine
- Compromised client devices

---

## Cryptographic Libraries

| Crate | Version | Purpose |
|-------|---------|---------|
| `chacha20poly1305` | 0.10 | AEAD encryption (ChaCha20-Poly1305) |
| `x25519-dalek` | 2.0 | Diffie-Hellman key exchange (X25519) |
| `ed25519-dalek` | 2.1 | Digital signatures (Ed25519) |
| `blake3` | 1 | Fast cryptographic hashing |
| `sha2` | 0.10 | SHA-256 (HKDF internals) |
| `hkdf` | 0.12 | Domain-separated key derivation (HKDF-SHA256) |
| `argon2` | 0.5 | Password hashing and key envelope encryption (Argon2id) |
| `subtle` | 2.5 | Constant-time comparison |
| `rand` | 0.8 | CSPRNG via `OsRng` |
| `zeroize` | 1.8 | Secure memory wiping on `Drop` |
| `rustls` | 0.23 | TLS (with `ring` backend) |

---

## 1. Transport Security

### TLS

Optional TLS termination via `rustls` + `ring` for HTTPS/WSS. Configured with `--tls-cert` and `--tls-key` CLI flags. Supports TLS 1.2 and 1.3. No client certificate authentication.

**Code:** `src/bin/xudanu-server.rs` (TLS setup)

### WebSocket Limits

- Max frame size: 16 MiB
- Max message size: 64 MiB

**Code:** `src/server/transport/handler.rs:105-107`

### Path Traversal Prevention

Static file serving checks `file_path.starts_with(dir)` before serving.

**Code:** `src/server/transport/handler.rs:85-86`

---

## 2. Authentication

### Password Authentication

Clubs can be password-protected using Argon2id hashes in PHC format.

- **Parameters:** 19,456 KiB memory, 2 iterations, parallelism 1
- **Password limits:** 1–256 bytes
- **Comparison:** Constant-time via `subtle::ConstantTimeEq`

**Code:** `src/crypto/password.rs`, `src/server/lock.rs:138-173`

### Public Key / Challenge-Response

X25519-based challenge-response: server creates ephemeral DH with stored public key, encrypts a challenge with ChaCha20-Poly1305, client must decrypt and return it.

**Code:** `src/server/lock.rs:90-136, 283-328`

### Lock Types

| Lock | Behavior |
|------|----------|
| `MatchLock` | Argon2id password verification |
| `ChallengeLock` | X25519 DH challenge-response |
| `BooLock` | No-op (public clubs) |
| `WallLock` | Always reject (no-access clubs) |
| `MultiLock` | Named sub-locks for multiple auth methods |

**Code:** `src/server/lock.rs`

### Two-Step Authentication Flow

Authentication uses a two-step flow to prevent self-validating lock attacks:

1. `login(session, club)` — creates a lock from stored credentials, stores it on session as `pending_lock`
2. `authenticate_with_pending(session, credential)` — validates credential against the pending lock

The server never trusts a client-provided lock — it always validates against the stored credential.

**Code:** `src/server/identity.rs`

---

## 3. Rate Limiting and Brute-Force Protection

### Per-Club Login Rate Limiting

Tracks failed login attempts per club ID (not per session or IP — prevents bypass via new sessions).

- **Threshold:** 10 attempts per 300-second window
- **Window reset:** After 300 seconds of inactivity
- **Lockout lift:** Successful login clears the tracker

**Code:** `src/server/identity.rs:24-27, 340-360`

### Transport SecurityMonitor

Per-session and per-IP sliding window threat detection.

| Metric | Limit |
|--------|-------|
| Auth failures per minute | 10 |
| Protocol violations per minute | 20 |
| Requests per second | 100 |
| Sessions per IP | 50 |
| Permission denials per minute | 30 |
| Grab conflicts per minute | 15 |

Threat levels: Normal → Elevated → High → Critical. Sessions at Critical level are disconnected.

**Code:** `src/server/transport/audit.rs`

---

## 4. Session Management

### CSPRNG Session IDs

Session IDs are not sequential. On first connect, a 64-bit secret is generated from `OsRng`. Each session ID is computed as `counter ^ (secret * 0x5851F42D4C957F2D)`, preventing sequential enumeration.

**Code:** `src/server/server.rs:295-305`

### Session Expiration

Sessions auto-expire after 1 hour. All API calls check `is_valid()` which requires active AND not expired. Expired sessions are rejected.

**Code:** `src/server/session.rs:11, 84-88`

### Session Cleanup

On disconnect, the session clears its decrypted club signing key and KeyMaster authority.

**Code:** `src/server/session.rs:85-88`

---

## 5. Identity and Clubs

### Approach C: Dual-Purpose Clubs

- **Personal clubs** (with credentials) = user accounts
- **Group clubs** (with members) = collectives

Each session can have at most one personal club. Server-wide cap of 10,000 personal clubs.

**Code:** `src/server/identity.rs`, `src/server/club.rs`

### Club Keypairs

Personal clubs with passwords get an Ed25519 signing keypair. The signing key is:

1. Generated on password creation
2. Encrypted with Argon2id-derived key via ChaCha20-Poly1305 envelope encryption
3. Stored encrypted at rest in the Club struct
4. Decrypted on successful login and held in the Session
5. Zeroized on session end or credential clearing

When the password is changed, the existing signing key is re-encrypted with the new password (same key preserved). When the credential is cleared, the encrypted key and all session copies are removed.

**Code:** `src/crypto/club_keys.rs`, `src/server/identity.rs`

### Transitive Authority

Club membership is transitive. Membership in a sub-club grants authority in all parent clubs via BFS resolution.

**Code:** `src/server/club.rs:235-271`

---

## 6. Encryption and Key Management

### AEAD Encryption (ChaCha20-Poly1305)

All encrypted channels use ChaCha20-Poly1305 with:
- 32-byte keys
- 12-byte nonces from monotonic counters
- 16-byte authentication tags
- Direction-separated AAD labels (prevents cross-direction decryption)
- Counter overflow detection (forces re-keying)
- Key zeroization on `Drop`

**Code:** `src/crypto/aead.rs`

### Key Derivation (HKDF-SHA256)

Domain-separated key derivation with labeled info strings:

| Domain Label | Purpose |
|-------------|---------|
| `xudanu/v1/handshake` | Session key agreement |
| `xudanu/v1/aead/client-to-server` | Client encryption key |
| `xudanu/v1/aead/server-to-client` | Server encryption key |
| `xudanu/v1/document-key` | Document encryption |
| `xudanu/v1/challenge-key` | Challenge-response keys |
| `xudanu/v1/federation/handshake` | Federation session keys |
| `xudanu/v1/federation/aead/server-to-server` | Federation outbound |
| `xudanu/v1/federation/aead/server-from-server` | Federation inbound |

**Code:** `src/crypto/kdf.rs`

### Server Keypair

Ed25519 signing key + X25519 kex key. Key ID is blake3 hash of verifying key (truncated to 8 bytes). Stored on disk with `0o600` permissions via atomic write (temp file + rename).

**Code:** `src/crypto/keys.rs`

### Key Rotation

Cryptographic chain of key rotations with Ed25519 signature proofs. Old key signs a `KeyRotationPayload` binding old → new identity. The entire chain can be verified. Keys have optional validity windows (`not_before`, `not_after`).

**Code:** `src/crypto/keys.rs:91-106, 173-185, 221-238`

---

## 7. CRDT Signing and Author Attribution

### Author Identity

Each CRDT session is associated with an `AuthorIdentity { public_key, display_name }`. The public key is the real Ed25519 verifying key from the club's signing keypair (or zero-padded BeId as fallback).

**Code:** `src/server/crdt_manager.rs:52-56`

### Signed Updates

CRDT updates can be signed with Ed25519 for non-repudiation. `SignedUpdate` carries the update bytes, signature, and signer public key. Verification checks against known author keys.

**Code:** `src/server/crdt_manager.rs:58-63, 516-524`

### Author Attribution

Inserted text carries a `__author` attribute in Yjs with the hex-encoded Ed25519 public key, enabling per-character attribution.

**Code:** `src/server/crdt_manager.rs:227-231`

---

## 8. Federation Security

### Federation Handshake

Mutual authenticated key exchange in three phases:

1. **Hello:** Exchange ephemeral X25519 public keys (unencrypted)
2. **Signature:** Exchange Ed25519 signatures over the DH transcript, verifying keys, and static kex keys
3. **Ready:** Confirm encrypted channel establishment

Unknown peer verifying keys are rejected. Transcript includes both ephemeral keys to bind the session.

**Code:** `src/server/transport/federation_handler.rs:142-332`

### Encrypted Federation Channel

All post-handshake traffic is encrypted with ChaCha20-Poly1305 using direction-separated keys. Unencrypted frames are rejected after handshake.

**Code:** `src/server/transport/federation_handler.rs:759-793`

### Peer Allowlist

Only pre-registered peer verifying keys can establish federation connections. Default mode is "closed" (known peers only).

**Code:** `src/server/federation.rs:257-266`

### Identity Binding

Federation operations validate that the claimed `server_id` matches the authenticated peer identity from the handshake.

**Code:** `src/server/transport/federation_handler.rs` (throughout)

### Membership and Governance

- **Join:** Servers must be endorsed by `min_endorsements` (default: 2) existing members
- **Governance:** PBFT consensus (tolerates `f = (n-1)/3` Byzantine faults, quorum `2f+1`)
- **Transactions:** Admit, Expel, KeyRegister, RoyaltyRecord

**Code:** `src/server/federation.rs:1080-1787`

---

## 9. Secure Memory Handling

Sensitive key material is wiped from memory using `zeroize` on `Drop`:

| Location | What's Zeroized |
|----------|----------------|
| `crypto/sign.rs:42` | Signing key seed bytes after construction |
| `crypto/kex.rs:24-26` | `SharedSecret` on Drop |
| `crypto/kex.rs:74,130` | Combined DH output after hashing |
| `crypto/keys.rs:64,117` | `ServerKeyPair` kex and signing bytes on Drop |
| `crypto/kdf.rs:25-35` | `SessionKeys` on Drop |
| `crypto/kdf.rs:52-62` | `FederationSessionKeys` on Drop |
| `crypto/aead.rs:142-145` | `SessionCipher` key on Drop |
| `server/session.rs:85-88` | Club signing key on session end |

---

## 10. Security Logging

### Event Journal

All security-relevant events are logged to a dedicated daily-rotating file (`security.log`) in the data directory, separate from general server logs.

### Log Target

Security events use the `xudanu::security` tracing target, making them easy to filter:

```
grep "xudanu::security" server.log
grep "SECURITY:" server.log
```

### Logged Events

| Event | Level | When |
|-------|-------|------|
| `SECURITY:login_succeeded` | INFO | Successful authentication |
| `SECURITY:login_failed` | WARN | Failed authentication (includes attempt count + error) |
| `SECURITY:login_rate_limited` | WARN | Rate limit triggered |
| `SECURITY:credential_cleared` | INFO | Password/key removed from club |
| `SECURITY:signing_key_decrypt_failed` | WARN | Key envelope decryption failure |

### Transport Audit Events

The transport layer also logs audit events via `SecurityMonitor`:

| Event | Severity |
|-------|----------|
| `AuthSuccess` | INFO |
| `AuthFailure` | WARN |
| `PermissionDenied` | WARN |
| `ProtocolViolation` | WARN |
| `RateLimit` | WARN |
| `ResourceExhaustion` | ERROR |
| `SuspiciousPattern` | ERROR |
| `StateCorruption` | ERROR |

**Code:** `src/server/transport/audit.rs`

### Operational: Reviewing Security Logs

```bash
# All security events from the security log file
cat data/security.log

# Filter for a specific club
grep "club_id" data/security.log

# Failed logins only
grep "SECURITY:login_failed" data/security.log

# Rate-limited attempts (likely attack)
grep "SECURITY:login_rate_limited" data/security.log
```

---

## 11. Configuration Parameters

| Parameter | Default | Location | Purpose |
|-----------|---------|----------|---------|
| Session timeout | 3600s (1hr) | `session.rs:11` | Session expiration |
| Max login attempts per club | 10 | `identity.rs:26` | Brute-force protection |
| Login attempt window | 300s (5min) | `identity.rs:27` | Attempt counting window |
| Max password length | 256 bytes | `identity.rs:24` | DoS prevention |
| Min password length | 1 byte | `identity.rs:25` | Input validation |
| Max personal clubs | 10,000 | `server.rs:215` | Resource limit |
| Argon2id memory | 19,456 KiB | `password.rs:6` | Hash hardness |
| Argon2id iterations | 2 | `password.rs:7` | Hash hardness |
| Argon2id parallelism | 1 | `password.rs:8` | Hash hardness |
| Federation handshake timeout | 30s | `federation_handler.rs:19` | DoS prevention |
| Federation frame max | 64 MiB | `federation_handler.rs:343-346` | Frame size limit |
| WS max frame size | 16 MiB | `handler.rs:105` | Frame size limit |
| WS max message size | 64 MiB | `handler.rs:106` | Message size limit |
| Max sessions per IP | 50 | `audit.rs:199` | Connection flood protection |

---

## 12. Resolved Limitations

| Limitation | Resolution |
|-----------|-----------|
| Persistence data loss | All club fields (is_personal, credential, encrypted_signing_key, display_name, members, sponsored_works) now survive restart. `personal_club_count` reconstructed from persisted data. Manifest version bumped to 3. |
| No CSRF protection on WebSocket | Origin checking via `--allowed-origin` flag (repeatable). CSRF token mode via `--csrf-token` flag with `/csrf-token` endpoint. Both approaches available, can be combined. |
| Security log integrity | Hash-chained log entries. Each line includes `chain=<sha256(prev_hash + line)>`. Verification via `xudanu-server verify-security-log <data-dir>`. Seed in `security.log.seed`. |

## 13. Known Limitations

- **Server operator trust:** The server holds decrypted signing keys in memory. A compromised server can forge edits.
- **No forward secrecy for stored keys:** Club signing keys are encrypted at rest with the user's password. If the password is compromised, all historical encrypted keys can be decrypted.
