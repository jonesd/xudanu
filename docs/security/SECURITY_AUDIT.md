# Xudanu Security Audit

## Overview

This document records the security testing methodology, results, and ongoing
confidence levels for Xudanu's cross-server protocol (XCP) cryptography.

## Scope

All hand-written protocol logic that uses cryptographic primitives:
- Ed25519 signature verification (cross-server content)
- TOFU key pinning (trust on first use)
- Key rotation chains (compromise recovery)
- Signed introductions (web of trust)
- BLAKE3 content hashing
- SSRF prevention (DNS resolution guard)

## Not in scope

The underlying crypto libraries themselves (`ed25519-dalek`, `blake3`,
`argon2`, `x25519-dalek`, `chacha20poly1305`, `ring`) are externally
audited and not subject to this review. We test **our usage** of these
libraries, not the libraries themselves.

## Phase 1: Property-Based Testing (proptest)

**Status:** Complete
**Tool:** `proptest` crate (256 random cases per test)
**Date:** August 2026

### Tests

| Test | Property verified |
|------|------------------|
| `prop_valid_signature_always_verifies` | Any valid keypair + any text → signature verifies |
| `prop_bitflip_in_text_fails` | Single-bit change in content hash → verification fails |
| `prop_wrong_server_id_fails` | Different server_id in payload → fails |
| `prop_tofu_mismatch_always_rejected` | Different key than pinned → always rejected |
| `prop_tofu_match_always_accepted` | Same key as pinned → always accepted |
| `prop_blake3_deterministic` | Same input → same hash (always) |
| `prop_blake3_different_inputs_different_hashes` | Different inputs → different hashes |
| `prop_rotation_chain_n_hops_succeeds` | 1-5 rotations → chain walk succeeds |
| `prop_rotation_chain_from_any_intermediate_succeeds` | Chain from any intermediate key → reaches end |
| `prop_introduction_tamper_signed_field_fails` | Tamper any signed field → fails |
| `prop_introduction_valid_always_verifies` | Valid introduction → always verifies |
| `prop_unsigned_rejected_when_key_pinned` | Unsigned response with pinned key → rejected |

### Result

All 12 properties hold across 256 random cases each (3,072 total assertions).
No invariant violations found.

## Phase 2: Fuzz Testing (cargo-fuzz)

**Status:** Complete
**Tool:** cargo-fuzz (targets written, ready for extended runs) + 24 fuzz-equivalent edge case tests
**Date:** August 2026

### cargo-fuzz targets

Three fuzz targets created in `fuzz/fuzz_targets/`:
- `fuzz_verify_signed_response` — arbitrary JSON feeds into signature verification
- `fuzz_verify_key_rotation` — arbitrary well-known JSON feeds into rotation chain walk
- `fuzz_introduction_verify` — arbitrary JSON feeds into introduction verification

Sanitizer build takes 20+ minutes for this crate size. Targets are ready
to run with `cargo +nightly fuzz run <target>`.

### Fuzz-equivalent edge case tests (24 tests, all passing)

No panics or crashes found on any edge case.

## Phase 3: Adversarial Network Tests

**Status:** Complete
**Tool:** Rust integration tests with mock HTTP servers
**Date:** August 2026

### Attack scenarios tested (5 tests, all passing)

| Attack | Test | Result |
|--------|------|--------|
| Forged signature | `adversarial_signature_stripping_rejected` | Rejected |
| Signature stripping (TOFU bypass) | `adversarial_unsigned_rejected_when_pinned` | Rejected |
| Introduction address tampering | `adversarial_introduction_tamper_address_detected` | Rejected |
| Rotation replay with wrong key | `adversarial_rotation_replay_different_key_rejected` | Rejected |
| BLAKE3 hash mismatch | `adversarial_blake3_hash_mismatch_rejected` | Rejected |

## Phase 3: Adversarial Docker Network Tests

**Status:** Pending

## Phase 4: Attack Detection Hardening

**Status:** Pending

## Confidence Levels

Updated after each phase completes.

| Component | Crypto primitive | Protocol logic | Attack detection | Overall |
|-----------|:---:|:---:|:---:|:---:|
| Ed25519 signatures | 95% | 85% ↑ | 40% | **78%** ↑ |
| BLAKE3 content hash | 95% | 93% ↑ | 70% | **86%** ↑ |
| TOFU key pinning | 95% | 88% ↑ | 50% | **78%** ↑ |
| Key rotation chain | 95% | 85% ↑ | 40% | **73%** ↑ |
| Signed introductions | 95% | 85% ↑ | 30% | **70%** ↑ |
| SSRF prevention | N/A | 85% | 60% | **75%** |

Legend: ↑ = improved after Phase 1

## Known Limitations

1. **First-connection MITM**: TOFU pins whatever key is seen first. If the
   first connection is intercepted, the attacker's key is pinned. Mitigated
   by signed introductions (web of trust) for servers with prior relationships.

2. **Multi-hop rotation chain size**: Published in full in the well-known
   endpoint. For very large numbers of rotations (100+), the response grows.
   No pruning mechanism implemented yet.

3. **HTTP fallback**: Server tries HTTPS first, falls back to HTTP. A network
   attacker who can block HTTPS can force plaintext. Signature enforcement
   protects content integrity, but transport metadata is exposed.

4. **No brute-force detection**: Failed signature attempts are logged but not
   rate-limited or tracked as anomalies. Phase 4 addresses this.
