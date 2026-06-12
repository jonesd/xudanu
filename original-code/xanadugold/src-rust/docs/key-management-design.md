# Xudanu Key Management Design

## Status: Draft

## Problem

Xudanu's core value is **link integrity and document authenticity**. If signing keys are compromised, an attacker can impersonate users, inject false documents, and sever authentic transclusions — destroying the hypertext graph's trust chain.

The current key management has two modes:

1. **Plaintext**: Server key stored as JSON on disk. Auto-restart works. Disk theft = total compromise.
2. **Password-derived**: Key encrypted with Argon2id + ChaCha20-Poly1305. Requires `--key-passphrase` at boot. Secure but manual restart required.

Neither is suitable for production alone.

## Threat Model

| Threat | Impact | Current Mitigation |
|---|---|---|
| Disk theft (server off) | Attacker reads all keys | Password encryption (if enabled) |
| OS compromise (server running) | Attacker reads keys from memory | None — keys in cleartext RAM |
| OS compromise (server off) | Attacker reads encrypted key file | Password encryption |
| Insider with root access | Copies key file, impersonates server | None |
| Key rotation needed | Must re-encrypt all wrapped keys | Manual process |
| Lost passphrase | Permanent data loss (key irrecoverable) | None — no escrow |

## Current Architecture

```
Server Identity Key (Ed25519)
├── Stored in: data/server.key
├── Format: plaintext JSON or encrypted (Argon2id + ChaCha20-Poly1305)
├── Used for: server authentication, key wrapping
└── Loaded at: startup (plaintext) or after passphrase input

Club Signing Keys (Ed25519, per-user)
├── Stored in: encrypted within club structure
├── Format: encrypted with club password (Argon2id + ChaCha20-Poly1305 + BLAKE3)
├── Used for: document signing, attribution, identity
└── Loaded at: session authentication

Storage Keys (none currently)
├── Chunks: content-addressed, no encryption
├── Manifest: plaintext JSON
└── Blobs: plaintext binary
```

## Proposed: Tiered Key Architecture

### Principle

**Separate the trust boundaries:**

- **Storage keys** protect data at rest → can be auto-unwrapped for availability
- **Signing keys** prove identity and authenticity → require explicit authorization
- **Root of trust** protects the key hierarchy → hardware-bound when possible

### Key Hierarchy

```
┌─────────────────────────────────────────────┐
│  Tier 3: Hardware Root of Trust (TPM 2.0)   │
│  ┌─────────────────────────────────────────┐ │
│  │  Storage Master Key (wrapped by TPM)    │ │
│  │  ┌─────────────────────────────────────┐│ │
│  │  │  Data Encryption Key (DEK)          ││ │
│  │  │  - Encrypts manifest, chunks, blobs ││ │
│  │  │  - Auto-unwrapped at startup        ││ │
│  │  └─────────────────────────────────────┘│ │
│  └─────────────────────────────────────────┘ │
│                                               │
│  Tier 2: Password-Derived (manual unlock)    │
│  ┌─────────────────────────────────────────┐ │
│  │  Signing Key Encryption Key (SKEK)      │ │
│  │  - Derived from admin passphrase        │ │
│  │  - Wraps all club signing keys          │ │
│  │  - Must be explicitly unlocked          │ │
│  │  ┌─────────────────────────────────────┐│ │
│  │  │  Club Signing Keys (per-user)       ││ │
│  │  │  - Ed25519, used for attribution    ││ │
│  │  │  - Unwrapped only during sessions   ││ │
│  │  └─────────────────────────────────────┘│ │
│  └─────────────────────────────────────────┘ │
│                                               │
│  Tier 1: Session Keys (ephemeral)            │
│  ┌─────────────────────────────────────────┐ │
│  │  Session Token Keys                     │ │
│  │  - Ephemeral per-connection             │ │
│  │  - Derived from handshake               │ │
│  │  - Never persisted                      │ │
│  └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### Tier 1: Session Keys (current behavior)

No changes needed. Session tokens are already ephemeral and derived from the WebSocket handshake. Never persisted.

### Tier 2: Signing Keys (password-derived, manual unlock)

**Goal:** Club signing keys are never unwrapped without explicit authorization.

**Changes:**

1. **Locked/Unlocked server state**
   - Server starts in `locked` mode
   - Read-only operations work (browse, search, read documents)
   - Write operations that require signing (edit, create, revise) return `ServerLocked` error
   - Admin calls `server_unlock` with passphrase
   - Server transitions to `unlocked` mode
   - Signing keys are held in memory until `server_lock` or shutdown

2. **Unlock command**
   ```
   POST /xudanu
   { "op": "server_unlock", "passphrase": "..." }
   ```
   Or via CLI:
   ```bash
   xudanu-server unlock --passphrase "..."  # sends unlock to running server
   ```

3. **Auto-lock timeout**
   - Configurable (default: 1 hour of inactivity, or never)
   - Clears signing keys from memory on timeout
   - Server returns to `locked` state

4. **Multi-admin unlock**
   - For production: require N-of-M admin passphrase inputs
   - Prevents single-admin compromise from unlocking signing keys
   - Threshold can be configured (default: 1-of-1 for dev, 2-of-3 for production)

### Tier 3: Storage Encryption (TPM-wrapped)

**Goal:** Data at rest is encrypted. Server can auto-restart without manual intervention.

**Changes:**

1. **Data Encryption Key (DEK)**
   - Random 256-bit key generated at `init`
   - Encrypts: `manifest.json`, `manifest_v*.json`, chunk files, blobs
   - Stored wrapped (encrypted) by the Storage Master Key

2. **Storage Master Key (SMK)**
   - RSA-2048 key pair generated at `init`
   - Private key wraps/unwraps the DEK
   - Private key is itself wrapped by one of:
     - **TPM 2.0** (preferred): bound to the server's TPM, never leaves hardware
     - **Password-derived**: fallback for development / no TPM available
     - **Cloud KMS**: for cloud deployments (AWS KMS, GCP KMS, Azure Key Vault)

3. **Encryption scheme**
   - Chunks: XChaCha20-Poly1305 with per-chunk nonce (hash-derived)
   - Manifest: XChaCha20-Poly1305 with random nonce
   - Blobs: XChaCha20-Poly1305 with random nonce
   - Key rotation: generate new DEK, re-encrypt all data, re-wrap DEK

4. **Startup flow with TPM**
   ```
   1. Server reads wrapped DEK from disk
   2. Sends wrapped DEK to TPM for unwrapping
   3. TPM verifies binding to this machine, returns plaintext DEK
   4. DEK held in memory for data encryption/decryption
   5. Server is "read-ready" — can serve data immediately
   6. Signing keys remain locked until manual unlock (Tier 2)
   ```

5. **Startup flow without TPM (fallback)**
   ```
   1. Server reads wrapped DEK from disk
   2. Prompts for passphrase (or reads XUDANU_STORAGE_PASSPHRASE)
   3. Derives SMK from passphrase via Argon2id
   4. Unwraps DEK using derived SMK
   5. DEK held in memory
   6. Server is "read-ready"
   ```

### Implementation Phases

#### Phase A: Server Lock/Unlock State (Tier 2)

**Scope:** Signing keys require manual authorization. Server starts locked.

- Add `ServerState` enum: `Locked`, `Unlocked`
- Add `server_unlock` / `server_lock` wire operations
- Gate signing operations behind `Unlocked` state
- Add auto-lock timeout
- Add `/health` endpoint reporting lock state
- Estimated effort: 2-3 days

#### Phase B: Data Encryption at Rest (Tier 3, password mode)

**Scope:** Encrypt manifest, chunks, and blobs with DEK. Password-derived fallback.

- Generate DEK at `init`
- Implement `EncryptedChunkStore` wrapper over `ChunkStore`
- Encrypt manifest on write, decrypt on read
- Store wrapped DEK alongside manifest
- Add `XUDANU_STORAGE_PASSPHRASE` env var for automated unlock
- Migration: re-encrypt existing plaintext data on first startup
- Estimated effort: 3-5 days

#### Phase C: TPM 2.0 Binding (Tier 3, hardware mode)

**Scope:** Bind Storage Master Key to TPM for auto-restart without passphrase.

- Use `tss-esapi` crate for TPM 2.0 interaction
- Generate SMK in TPM at `init`
- Wrap DEK with TPM-bound key
- Auto-unwrap DEK at startup via TPM
- Fallback to password mode if TPM unavailable
- Platform support: Linux (full), macOS (Secure Enclave via `Security.framework`), Windows (TPM via TBS)
- Estimated effort: 5-7 days

#### Phase D: Multi-Admin Unlock (Tier 2, enhanced)

**Scope:** Require N-of-M admin passphrases to unlock signing keys.

- Shamir's Secret Sharing for SKEK
- Admin registration at `init`
- Collect N shares via `server_unlock_share` from M admins
- Reconstruct SKEK from shares, unwrap signing keys
- Share rotation on admin change
- Estimated effort: 3-5 days

#### Phase E: Cloud KMS Support (Tier 3, cloud mode)

**Scope:** Use cloud KMS to wrap DEK instead of TPM.

- AWS KMS via `aws-sdk-kms`
- GCP KMS via `google-cloud-kms`
- Azure Key Vault via `azure_security_keyvault`
- Auto-detected via environment variables
- Estimated effort: 3-5 days

### CLI Changes

```bash
# Initialize with tiered security
xudanu-server init --security tiered --tpm /data

# Initialize with password fallback (no TPM)
xudanu-server init --security tiered /data

# Initialize with legacy plaintext (development only)
xudanu-server init --security plaintext /data

# Run server (auto-unwraps storage via TPM, signing keys remain locked)
xudanu-server run 0.0.0.0:8080 /data

# Unlock signing keys (separate step)
xudanu-server unlock --passphrase "..." /data
# or via API after connecting

# Lock signing keys (clear from memory)
xudanu-server lock /data

# Rotate DEK (re-encrypts all data)
xudanu-server rotate-keys /data

# Check server state
xudanu-server status /data
# Output: state=locked, storage=encrypted(tpm), signing=locked, uptime=2h
```

### Wire Protocol Changes

| Op Code | Name | Direction | Description |
|---|---|---|---|
| 0x0E01 | `ServerUnlock` | Client → Server | Unlock signing keys with passphrase |
| 0x0E02 | `ServerLock` | Client → Server | Lock signing keys, clear from memory |
| 0x0E03 | `ServerStatus` | Client → Server | Query lock state, encryption status |
| 0x0E04 | `ServerUnlockShare` | Client → Server | Submit N-of-M share for multi-admin unlock |

New error code:

| Code | Name | Description |
|---|---|---|
| 0xF001 | `ServerLocked` | Operation requires signing keys but server is in locked state |

### Configuration

```json
{
  "security": {
    "mode": "tiered",
    "storage_encryption": "tpm",
    "signing_key_policy": "manual_unlock",
    "auto_lock_timeout_seconds": 3600,
    "multi_admin_threshold": {
      "required": 2,
      "total": 3
    }
  }
}
```

### Backward Compatibility

- Existing plaintext deployments continue to work unchanged
- Existing password-encrypted deployments continue to work unchanged
- `--security tiered` is opt-in at `init` time
- Migration from plaintext/password to tiered: `xudanu-server migrate-security --security tiered /data`

### Dependencies

| Crate | Purpose | Phase |
|---|---|---|
| `tss-esapi` | TPM 2.0 interaction | C |
| `chacha20poly1305` | XChaCha20-Poly1305 AEAD | B |
| `argon2` | Already used for key derivation | B |
| `shamir-secret-sharing` | SSS for multi-admin | D |
| `aws-sdk-kms` | AWS KMS support | E |

### Testing Strategy

- **Unit tests**: Key wrapping/unwrapping, encryption/decryption, lock state transitions
- **Integration tests**: Full startup → locked → unlock → sign → lock cycle
- **Chaos tests**: Kill server during re-encryption, verify recovery
- **Hardware tests**: TPM binding on Linux CI (requires TPM emulator: `swtpm`)
- **Performance tests**: Chunk encryption overhead benchmark (target: <5% throughput degradation)

### Open Questions

1. **Chunk encryption granularity**: Encrypt each chunk individually (high overhead) or encrypt at the filesystem level (e.g., LUKS)? Recommendation: per-chunk for portability, with optional filesystem-level encryption as defense-in-depth.

2. **Key escrow for recovery**: Should there be a mechanism to recover signing keys if all admins are lost? Risk: escrow = backdoor. Recommendation: optional recovery key printed at `init`, stored offline.

3. **Federation implications**: How do signing key states affect federated peers? A locked server can still serve read requests to peers. Peer authentication uses the server identity key (Tier 3, auto-unwrapped), not club signing keys.

4. **Memory locking**: Should unlocked signing keys be locked in RAM (`mlock`) to prevent swap? Recommendation: yes, use `mlockall` on unlock, `munlock` on lock.
