# Phase 12: Modern Encryption

## Overview

Phase 12 replaces the original Udanax Gold placeholder crypto (`NoEncrypter`/`NoScrambler`) with production-grade modern cryptography. The system uses Ed25519 for identity and signing, X25519 for key exchange, ChaCha20-Poly1305 for authenticated encryption, HKDF-SHA256 for key derivation, and Argon2id for password hashing. Key rotation with signed chain history is built in from day one.

## What Was Built

### 1. Crypto Primitives Module (`src/crypto/`)

Seven modules, all gated behind the `server` feature:

**`aead.rs`** — ChaCha20-Poly1305 AEAD with:
- `SessionCipher` — monotonic nonce counter per session, separate direction labels
- `SealedEnvelope` — versioned wire format with `version`, `key_id`, `counter`, `ciphertext`
- Domain-separated AAD (direction label + user AAD)
- `NonceOverflow` error when counter exhausts (signals re-key)
- `zeroize` on drop for session keys

**`sign.rs`** — Ed25519 signing and verification:
- `sign_bytes()` / `verify_signature()` — thin wrappers
- `generate_signing_key()` — secure random key generation with zeroize

**`kex.rs`** — X25519 key exchange:
- `EphemeralKeyPair` — single-use ephemeral keys
- `key_exchange_simple()` — double-DH (static + ephemeral) shared secret
- `build_transcript()` — BLAKE3 hash of both ephemeral public keys
- `sign_handshake()` / `verify_handshake_signature()` — transcript binding
- `SharedSecret` — zeroizes on drop

**`kdf.rs`** — HKDF-SHA256 with domain separation:
- `DomainLabel` constants: `xudanu/v1/handshake`, `xudanu/v1/aead/client-to-server`, `xudanu/v1/aead/server-to-client`, `xudanu/v1/document-key`, `xudanu/v1/challenge-key`
- `SessionKeys` — separate inbound/outbound keys, zeroizes on drop
- `derive_session_keys()` — derives two keys from shared secret + handshake hash

**`password.rs`** — Argon2id password hashing:
- OWASP-recommended parameters: 19456 KiB memory, 2 iterations, 1 lane
- PHC-formatted hash strings (`$argon2id$v=19$...`)
- `constant_time_eq()` via `subtle` crate

**`keys.rs`** — Server identity and key rotation:
- `ServerKeyPair` — Ed25519 signing key + X25519 static key, with `key_id`, `not_before`, `not_after`, `is_active`
- `ServerIdentity` — public-only view for sharing
- `KeyHistory` — ordered list of key entries with signed rotation proofs
- `SignedKeyRotation` — old key signs the new key's public keys + timestamp
- `verify_rotation_chain()` — validates the entire history from genesis key
- `is_key_valid_at()` — time-based key validity checking
- All private keys zeroize on drop

**`protocol.rs`** — Versioned message envelopes:
- `EnvelopeVersion` — currently `V1`
- `AuthenticatedMessage` — includes `version`, `key_id`, `message_type`, `payload`, `signature`
- `signing_input()` — deterministic serialization for signature verification

### 2. Lock System Security Upgrade

| Lock | Before | After |
|------|--------|-------|
| `MatchLock` | Plaintext `==` comparison | Argon2id PHC hash + verify (constant-time) |
| `MatchLockSmith` | Stored raw password | `from_password()` hashes with Argon2id; `from_phc_hash()` accepts existing hash |
| `ChallengeLockSmith` | Placeholder `vec![0u8; 32]` | Real X25519 ECDH → HKDF → ChaCha20-Poly1305 challenge encryption |

The `ChallengeLockSmith.create_challenge()` flow:
1. Generate ephemeral X25519 key pair
2. ECDH with peer's static public key → shared secret
3. HKDF derive AEAD key with domain label `xudanu/v1/challenge-key`
4. Encrypt challenge data with ChaCha20-Poly1305
5. Return `ephemeral_public_key || ciphertext`

### 3. Server Integration

Server now holds `server_keypair: ServerKeyPair` and `key_history: KeyHistory`:
- `server_identity()` — returns public-only identity
- `sign_data()` / `verify_server_signature()` — sign/verify with current key
- `rotate_server_keys()` — generates new keypair, signs with old key, updates history
- Both `new()` and `from_snapshot()` initialize crypto state

### 4. Wire Protocol (opcodes 0x1201–0x1205)

| Operation | Opcode | Auth | Request | Response |
|-----------|--------|------|---------|----------|
| `crypto_get_public_key` | 0x1201 | None | — | key_id, signing_key[32], kex_key[32], server_id |
| `crypto_sign_data` | 0x1202 | Admin | data | signature[64], key_id |
| `crypto_verify_signature` | 0x1203 | None | data, signature | valid (bool) |
| `crypto_key_rotation` | 0x1204 | Admin | — | new_key_id |
| `crypto_key_history` | 0x1205 | None | — | server_id, current_key_id, entries[] |

### 5. Dependencies

All from the RustCrypto project (pure Rust, no C dependencies):

| Crate | Version | Purpose |
|-------|---------|---------|
| `chacha20poly1305` | 0.10 | AEAD authenticated encryption |
| `x25519-dalek` | 2.0 | Curve25519 Diffie-Hellman key exchange |
| `ed25519-dalek` | 2.1 | Ed25519 digital signatures |
| `sha2` | 0.10 | SHA-256 for HKDF |
| `hkdf` | 0.12 | HKDF-SHA256 key derivation |
| `argon2` | 0.5 | Argon2id password hashing |
| `subtle` | 2.5 | Constant-time comparison |
| `zeroize` | 1.8 | Secure memory zeroization |
| `rand` | 0.8 | Secure random number generation |
| `proptest` | 1 (dev) | Property-based testing |

## C++ Equivalence

| C++ Component | Rust Equivalent |
|---------------|-----------------|
| `NoEncrypter` (stub) | Real ChaCha20-Poly1305 AEAD |
| `NoScrambler` (stub) | Real Argon2id password hashing |
| `Encrypter::make()` factory | `ServerKeyPair::generate()` |
| `MatchLock::encryptedPassword()` | `MatchLockSmith` with Argon2id PHC |
| `ChallengeLock` (stub) | Real X25519 ECDH + AEAD challenge |
| `FeKeyMaster` public key distribution | `crypto_get_public_key` operation |
| `FeServer::publicKey()` | `ServerIdentity` with Ed25519 + X25519 |
| Snefru S-boxes | BLAKE3 content fingerprints (existing) |

## Security Design

### What's protected

- **Passwords**: Argon2id with OWASP parameters, PHC format storage, constant-time verify
- **Transport**: Challenge-response with X25519 ECDH, HKDF-derived keys, AEAD-encrypted challenges
- **Signatures**: Ed25519 for server identity, data signing, key rotation proofs
- **Documents**: ChaCha20-Poly1305 with monotonic nonces, separate direction keys
- **Key material**: `zeroize` on drop for all secret types

### Domain separation

All HKDF derivations use `xudanu/v1/` prefixed labels. Session keys are split into separate inbound/outbound keys. AEAD AAD includes the direction label.

### Key rotation from day one

- `KeyHistory` stores the full chain from genesis key
- Each rotation is signed by the previous key
- `verify_rotation_chain()` validates the complete history
- Time-based validity (`not_before`/`not_after`) on each key entry
- Admin-triggered rotation via `crypto_key_rotation` (auto-rotation can be added later)

### What's NOT included yet (future)

- **TLS termination**: Recommend Caddy (built-in Let's Encrypt) or nginx + certbot as reverse proxy
- **Federation protocol**: Crypto primitives support server-to-server encryption, but the actual federation communication layer is a separate effort
- **Post-quantum**: Architecture supports plugging in ML-KEM (Kyber) via the KEM abstraction
- **Encrypted key storage at rest**: Keys are currently in memory only (snapshot does not persist crypto state)
- **Proptest fuzzing**: Dependency added but property-based tests not yet written

## Tests

- **62 crypto unit tests**: AEAD roundtrip/tamper/wrong-key/wrong-aad/empty/large, signing roundtrip/tamper/wrong-key, KDF determinism/domain-separation/session-keys, Argon2id roundtrip/PHC-format/unicode, key generation/identity/rotation/history-chain/transcript
- **6 integration tests**: `crypto_get_public_key`, `crypto_sign_and_verify`, `crypto_verify_rejects_tampered`, `crypto_key_rotation`, `crypto_key_history`, `crypto_sign_requires_admin`
- **`cargo audit`**: Clean — no known vulnerabilities in dependencies
- **Total: 1317 tests passing** (1202 unit + 115 integration)

## Security Tooling

- **`cargo audit`** — Installed and run. Scans Cargo.lock against RustSec advisory database. Zero vulnerabilities found.
- **`proptest`** — Added as dev-dependency for future property-based fuzzing of crypto operations.
