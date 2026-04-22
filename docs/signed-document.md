# Signed Document: Cryptographic Provenance

## Overview

Xudanu provides **non-repudiation** for collaborative edits: every change is cryptographically signed with the author's Ed25519 private key, and receivers verify the signature against the author's registered public key before integrating the change.

This is the core security feature that distinguishes Xudanu from other CRDT systems (Yjs, Automerge, etc.) which have no built-in notion of cryptographic identity or proof of authorship.

## Threat Model

### What this protects against

| Attack | Protection |
|--------|-----------|
| **Forged edits** — someone claims Alice wrote text she didn't | Ed25519 signature on the change blob proves only Alice's private key could have produced it |
| **Tampered updates** — someone modifies a change in transit | `verify_strict()` on the serialized payload detects any bit-level modification |
| **Impersonation** — Eve signs a change claiming to be Alice | Alice's public key is registered out-of-band; Eve's signature won't verify against it |
| **Replay attacks** — re-sending an old signed change | Change IDs are content-hashed; duplicates are detected by `change_dag` |

### What this does NOT protect against (by design)

| Limitation | Reason |
|-----------|--------|
| **Compromised private keys** | If Alice's key is stolen, the attacker can sign as Alice. Key rotation via `KeyStore` mitigates this. |
| **Encrypted transport** | Signatures prove authorship, not confidentiality. Use TLS/noise for encryption. |
| **Access control** | This is a proof system, not a permission system. Authorization is a separate layer. |
| **Per-character attribution** | Signatures cover change batches (yrs update blobs), not individual characters. Character-level attribution uses the `__author` formatting attribute. |

## Architecture

### Key Components

```
┌─────────────────────────────────────────────────────────────┐
│  SignedDocument                                             │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────────────┐  │
│  │ Signer      │  │ Document    │  │ known_keys         │  │
│  │ (Ed25519)   │  │ (yrs::Doc)  │  │ AuthorId → VerifyK │  │
│  └─────────────┘  └─────────────┘  └────────────────────┘  │
│                                                             │
│  commit_signed_change()  → Signer.sign_change() → output   │
│  integrate_signed_change() → verify → Document.apply()     │
└─────────────────────────────────────────────────────────────┘
```

### Key Flow

```
Alice's machine                          Bob's machine
─────────────────                        ─────────────────
1. insert(0, "Hello")
2. commit_signed_change()
   ├── Document.commit_change()
   │   └── yrs encode_diff_v1() → update_bytes
   └── Signer.sign_change()
       └── Ed25519 sign(update_bytes + metadata) → signature
3. Send SignedChange over wire ──────────▶ 4. integrate_signed_change()
                                            ├── lookup(change.actor) → VerifyingKey
                                            ├── verify_strict(payload, signature)
                                            ├── if VALID: Document.integrate_change()
                                            └── if INVALID: return VerificationError
```

## SignedDocument API

### Construction

```rust
let signer = Signer::generate("Alice".to_string());
let site = SiteId::from_author(signer.author());
let mut doc = SignedDocument::new(doc_id, signer, site);
```

The signer's public key is automatically registered in the `known_keys` map.

### Registering remote authors

Before accepting changes from another author, their public key must be registered:

```rust
let bob = Signer::generate("Bob".to_string());
doc.register_author(bob.author());
```

This stores Bob's `VerifyingKey` indexed by his `AuthorId` (his Ed25519 public key bytes). The key must be obtained through a trusted channel — this is an out-of-band operation.

### Signing outgoing changes

```rust
doc.insert(0, "Hello ");
let signed_change: SignedChange = doc.commit_signed_change().unwrap();
// signed_change.change.signature is Some(Ed25519Signature)
```

### Verifying and integrating incoming changes

```rust
match doc.integrate_signed_change(&signed_change) {
    Ok(()) => { /* change applied */ },
    Err(VerificationError::UnknownAuthor(id)) => { /* register them first */ },
    Err(VerificationError::MissingSignature(id)) => { /* reject unsigned change */ },
    Err(VerificationError::InvalidSignature(hash)) => { /* tampered or forged */ },
    Err(VerificationError::AuthorRevoked(id)) => { /* key was revoked */ },
}
```

## What Gets Signed

The signature covers the **signing payload**, which is a deterministic serialization of all change fields:

```rust
pub fn signing_payload(&self) -> Vec<u8> {
    bincode::serialize(&(
        &self.id,           // SHA-256 content hash
        &self.actor,        // Ed25519 public key (32 bytes)
        &self.site,         // SiteId (32 bytes)
        &self.deps,         // parent change hashes
        &self.operations,   // legacy ops (empty with yrs)
        &self.update_bytes, // yrs serialized update blob
        &self.timestamp,    // hybrid logical timestamp
        &self.lamport,      // logical clock
    ))
}
```

The `update_bytes` field is the yrs v1-encoded update blob, containing all block inserts, deletes, and formatting changes since the last commit. This is the substantive content.

The `id` is computed as SHA-256 of the same fields (minus signature), providing content-addressing.

## Verification Errors

### `UnknownAuthor(AuthorId)`

The change's `actor` field contains an `AuthorId` that is not in the receiver's `known_keys` map. The receiver must call `register_author()` with the sender's public key before accepting their changes.

**This is the most common error during initial sync** — peers must exchange public keys before collaborating.

### `MissingSignature(AuthorId)`

The change has `signature: None`. All changes must be signed. An unsigned change could come from:
- A buggy client that forgot to sign
- A malicious actor stripping the signature
- A change constructed outside the `SignedDocument` API

### `InvalidSignature(ChangeHash)`

The signature does not verify against the registered public key for the claimed author. This indicates:
- The change was tampered with after signing (any bit flipped in the payload)
- The change was re-signed by a different private key (forgery attempt)
- The signing payload was computed differently (version mismatch)

### `AuthorRevoked(AuthorId)`

The author's key has been revoked via the `KeyStore`. This is reserved for key rotation scenarios.

## Key Management

### Key Generation

```rust
let signer = Signer::generate("Alice".to_string());
// Generates random Ed25519 keypair using OsRng
// Derives Author identity from public key
```

### Key Storage

```rust
let stored = StoredKey::from_signer(&signer);
let bytes = stored.serialize();  // bincode, for disk storage
let restored = StoredKey::deserialize(&bytes)?.load()?;
```

### Key Rotation

```rust
let mut keystore = KeyStore::new();
keystore.register_author(old_signer.author(), timestamp);
keystore.register_author(new_signer.author(), timestamp);
keystore.revoke_key(old_signer.author_id(), new_signer.author_id(), timestamp)?;
```

The `KeyStore` maintains a revocation log and key chain, supporting identity continuity across key rotations.

## Cryptographic Primitives

| Component | Algorithm | Library |
|-----------|-----------|---------|
| Signing | Ed25519 (RFC 8032) | `ed25519-dalek` v2 |
| Verification | Ed25519 `verify_strict()` | `ed25519-dalek` v2 |
| Content hashing | SHA-256 | `sha2` |
| Serialization | bincode v1 | `bincode` |
| CRDT updates | lib0 v1 encoding | `yrs` internal |

### Why `verify_strict()` instead of `verify()`

`verify_strict()` rejects non-canonical Ed25519 signatures (where `S >= prime order L`). While both verify valid signatures, `verify_strict` provides a stronger guarantee: it ensures signature malleability is not possible, meaning there's only one valid signature for any given message. This prevents an attacker from creating a different valid signature for the same message without knowing the private key.

### Why Ed25519 and not another algorithm

- **Small keys**: 32-byte public keys fit in our `AuthorId = [u8; 32]` type
- **Small signatures**: 64 bytes, reasonable overhead per change
- **Fast verification**: ~50μs per signature on modern hardware
- **WASM support**: `ed25519-dalek` compiles to WASM via `getrandom` crate
- **Well-audited**: Dalek cryptography libraries are widely used and audited

## Security Considerations for Deployment

### 1. Key Distribution

The biggest operational challenge: how do peers learn each other's public keys?

Options:
- **Pre-shared**: Exchange keys out-of-band before collaboration
- **Server-mediated**: A trusted server distributes public keys
- **Web of Trust**: Sign each other's keys (PGP model)
- **Decentralized identity**: DIDs, key events (KERI model)

Xudanu does not mandate a specific approach. The `register_author()` method is the integration point.

### 2. Key Storage on Client

Private keys must be protected at rest. Options:
- Encrypted on disk with a passphrase
- Stored in OS keychain (Keychain Access, Credential Manager, libsecret)
- Hardware-backed (YubiKey, TPM) — requires different signing API

### 3. Clock Skew

The `HybridTimestamp` includes both a logical component (Lamport clock) and wall-clock time. Lamport clocks are monotonically increasing within a document and don't depend on synchronized clocks. Wall-clock times are informational and not used for security decisions.

### 4. Forward Secrecy

Ed25519 signatures do not provide forward secrecy. If a private key is compromised, all past signatures can be forged. Key rotation + revocation (via `KeyStore`) mitigates this but does not eliminate it. This is acceptable for our threat model (non-repudiation, not confidentiality).

## Test Coverage

Seven tests specifically cover the signing integration:

| Test | What it verifies |
|------|-----------------|
| `sign_and_verify_roundtrip` | End-to-end: sign on A, verify on B, text matches |
| `reject_tampered_change` | Flipping bits in `update_bytes` after signing |
| `reject_unsigned_change` | Stripping the `signature` field |
| `reject_unknown_author` | Change from unregistered author |
| `reject_forged_signature` | Eve re-signs Alice's change with Eve's key |
| `signed_two_way_convergence` | Both sides sign and verify, text converges |
| `signed_attribution_works` | Author identity preserved through signed sync |

All 7 tests pass. The full test suite has 128 tests, all passing.

## Files

| File | Purpose |
|------|---------|
| `crates/core/src/signed_doc.rs` | `SignedDocument` + `VerificationError` |
| `crates/core/src/doc.rs` | Underlying `Document` (yrs wrapper) |
| `crates/signing/src/signer.rs` | `Signer` — Ed25519 signing operations |
| `crates/signing/src/key_store.rs` | `KeyStore` — key registration and revocation |
| `crates/types/src/change.rs` | `Change`, `SignedChange` types with signature fields |
| `crates/types/src/author.rs` | `Author`, `AuthorId`, `SiteId` types |
| `crates/core/tests/signing_integration.rs` | 7 integration tests |
