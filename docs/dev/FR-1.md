# FR-1: Signature Verification Tool

- **ID:** FR-1
- **Status:** Draft (not yet implemented)
- **Date:** 2026-06-29 (revised)
- **Owner:** frontend + backend

## 1. Overview

A standalone tool to cryptographically verify an Ed25519 signature against a
public verifying key — answering "was this signed data really produced by the
holder of this public key?" Defaults to the current user's key for
convenience, but its real purpose is verifying **someone else's** signed data
with **their** key.

Lives behind a new **left-rail entry** (its own surface), not in the Identity
popup.

## 2. Background — how xudanu signs

Verification needs the *exact* signed bytes. Signing surfaces today:

| Artifact | Signed bytes | Source |
|---|---|---|
| CRDT/o-tree update | `update_text.as_bytes()` (raw text) | `otree_crdt.rs:1264` |
| Attribution (edit) | text bytes (per edit) | attribution path |
| Endorsement | structured, domain-prefixed transcript | `server.rs:11591` |
| Provenance | `b"xudanu/v1/provenance"` + payload | `provenance.rs:6` |
| Audit/security log | signed by the **server keypair** | `server.rs:10501, 11591` |

Primitive: `verify_signature(vk, message, sig)` (`sign.rs:28`), Ed25519
(`ed25519-dalek`). Note `verify_signed_update` also requires the signer's key
to be in a `known_keys` set (`otree_crdt.rs:1278`).

**Implication:** signed-byte layouts differ by artifact type and several are
not hand-pasteable. v1 is therefore **raw-bytes** verification; artifact-type
verification arrives via partial 4 (§5.4).

## 3. Scope decision

| Item | v1 | Deferred |
|---|---|---|
| Raw-bytes verify (paste key+msg+sig) | ✅ | |
| Input validation (length/format) | ✅ #1 | |
| Directory key pre-check (wrong-key) | ✅ #2 | |
| Honest result taxonomy | ✅ #3 | |
| Artifact-by-id verify (ground truth) | ◐ partial #4 | |
| Signature export (typed envelope) | ◐ partial | |
| Signed `{msg_hash, fp}` header (diagnose fully-external paste) | | ⏳ v2 |
| Server-key / audit-log verification | | ⏳ v2 |
| Client-side verify (privacy for external content) | | ⏳ eval |

## 4. The disambiguation limit (recorded)

A single Ed25519 verify cannot tell wrong-key from tampered-message — the three
inputs are entangled and there is no ground truth. Ed25519 has **no public-key
recovery** (that's an ECDSA feature), so that route is closed. Disambiguation
in v1 comes from **ground truth we already hold** (directory key; stored
artifacts), not from the crypto.

## 5. Functional Requirements

### FR-1.1 Left-rail entry
New "Verify" button (`LeftRail.tsx`) with a shield-check icon + tooltip;
opens the Verify panel; disabled when not connected.

### FR-1.2 Signer (public key) input — three modes
1. **Myself (default)** — prefilled from `WhoAmIEntry.verifying_key`.
2. **Lookup by name/club-id** — resolved to a key via `club_public_key_hex`
   (public data). Shows the resolved owner name.
3. **Paste any key** — manual 64-hex input for external keys; labelled
   **"unverified key binding"** (we verify the crypto, not that the key
   belongs to a claimed person).

### FR-1.3 Message input
Text area + **Text/Hex toggle**. Text → UTF-8 bytes; Hex → raw decoded octets.
Show resulting byte length + encoding.

### FR-1.4 Signature input
Hex (128 chars = 64 bytes). Tolerant of whitespace/`0x`; validated as 64 bytes.

### FR-1.5 Verification + result taxonomy (the #3 honest messaging)
Result states, each visually distinct:
- `malformed key` / `malformed signature` — wrong length (#1).
- `key mismatch` — provided key ≠ directory key for the resolved signer (#2),
  **including key history** (see §7).
- `does not verify for this key` — signature invalid (cannot say *why*).
- `valid` — green ✓ + key fingerprint + message length.
Artifact-mode (#4) adds: `message ≠ stored`, `key ≠ stored`,
`signature corrupted`.

### FR-1.6 Input validation (#1)
Client-side: key = 32 bytes, signature = 64 bytes, message non-empty; UTF-8
validity in text mode. Malformed → input error, no backend call.

### FR-1.7 Directory key pre-check (#2)
When signer is resolved by name/id, fetch the directory key(s) and compare to
the key in the signature/field. Mismatch → `key mismatch` **before** crypto.
Must check **key history**, not just the current key (§7).

### FR-1.8 Signature export — typed envelope (partial)
The tool is useless without inputs. Add a "copy for verification" action on the
attribution panel (and later endorsement/provenance views) that emits a
self-describing JSON envelope:
```
{
  kind: "attribution" | "endorsement" | "provenance" | "crdt_update" | "raw",
  public_key: <hex>,
  message: <exact signed bytes, hex>,
  signature: <hex>,
  source: { work_id?, author?, revision?, exported_at? }   // display-only
}
```
**Constraint:** `kind`/`source` are wrapper metadata — never appended to the
signed message (would break verification). `message` stays byte-identical to
what was signed. The verifier reads `kind`/`source` to label results.

### FR-1.9 Artifact-mode verification (partial #4, when feasible)
Verify a real xudanu artifact **by id** against ground truth the server
already stores (canonical `message, signature, key`). Because ground truth
exists, the server can pinpoint which input differs — true per-field
diagnosis with **no new signing, no protocol change**, only a read+compare+
verify endpoint. Scope to attribution first; endorsement/provenance later.

## 6. Design decisions & rationale

- **Any public key is cryptographically safe** to accept — verification
  involves no secret. The only risk is *key authenticity* (is this really
  Alice's key?), which the tool does not assert for pasted keys. Directory-
  resolved keys carry the server's club→key binding; pasted keys are labelled
  "unverified binding."
- **Server-side verify by default** (consistent ed25519-dalek, no JS crypto
  dep). **Privacy caveat:** the pasted message is sent to the server. For
  verifying *private* content against an external key, prefer a future
  client-side mode (`@noble/ed25519`, ~6KB). Flagged for evaluation, not v1.
- **Disambiguation** comes from ground truth (directory/stored artifact), not
  from the signature. Fully-external pastes remain indistinguishable until v2's
  signed header.

## 7. Security considerations

- **Key rotation / history (vital).** xudanu is a provenance system — old
  attributions must remain verifiable after a user rotates their key (password
  change). The directory pre-check (#2) must accept **any key in the user's
  key history**, not only the current key. Data exists (`key_history.json`);
  needs a server accessor `club_key_history_hex(club_id)`. Without this, every
  key rotation would make prior signatures look like "wrong key."
- **Revocation** — out of scope: the tool verifies *cryptography*, not
  revocation status. A revoked-but-cryptographically-valid signature still
  reports `valid`. Document this explicitly in the UI for resolved keys.
- **No secret handling** anywhere; public keys/messages/signatures are
  non-secret.
- **Stateless, side-effect-free** — no logging of what users verify, no
  persistence of pasted keys.
- Verify endpoint is a public oracle; Ed25519 verify is cheap (DoS low), but
  can sit behind login for consistency.

## 8. Implementation Details

### 8.1 Backend
- `verify_signature_public(public_key: &[u8], message: &[u8], signature: &[u8])
   -> Result<bool, VerifyError>` — wraps `sign::verify_signature`;
  `VerifyError` for malformed length (bad input) vs `Ok(false)` (genuine
  invalid) — distinguish "bad input" from "valid crypto, wrong key."
- `club_public_key_hex(club_id) -> Option<String>` — any club's *current*
  public key (public; safe to expose to logged-in sessions).
- `club_key_history_hex(club_id) -> Vec<String>` — all keys ever held (for
  rotation handling in #2).
- Wire request `VerifySignature { public_key, message, signature }` →
  `VerifyResult { valid: bool, error: Option<String> }` (new opcode, e.g.
  `0x0212`; dispatch in both wire + JSON paths). No auth required (pure public
  crypto); `ClubPublicKey`/`ClubKeyHistory` require `ensure_logged_in`.
- Artifact mode (#4): `verify_attribution(work_id, range, ...) -> VerifyReport`
  comparing against stored ground truth. Shape TBD against attribution storage.

### 8.2 Frontend
- **Left rail** (`LeftRail.tsx`): `ICONS.verify` + `RailButton` → opens panel
  (new state in `AppShell`).
- **`VerifySignaturePanel.tsx`** — props: `defaultPublicKey?`, `clientRef`,
  `connected`, `onClose`. State: `signerMode`, `lookupQuery`, `publicKey`,
  `message`, `messageEncoding`, `signature`, `result`.
  - Prefill `publicKey` from current identity on open.
  - Lookup (debounced) → `client.clubPublicKey(nameOrId)` → fill key; run
    pre-check against key history (#2).
  - Encode message: text → `TextEncoder`; hex → hex-decode.
  - Validate lengths before submit (#1).
  - Submit → `client.verifySignature(...)` → render taxonomy (#3).
- **Export action** on attribution panel → copies typed envelope JSON (#8).
- **Client methods** (`crdt_sync.ts`): `verifySignature(pk, msg, sig)`,
  `clubPublicKey(nameOrId)`, `clubKeyHistory(nameOrId)`.

### 8.3 Data flow
```
signer ── self ──→ own verifying_key
       ── lookup → clubPublicKey + history → pre-check (#2)
       ── paste ──→ user hex (label: unverified binding)
message ── TextEncoder / hex-decode ──→ bytes      [#1 validate]
signature ── hex-decode ──→ bytes                   [#1 validate]
                 │
        verifySignature(pub,msg,sig) → backend ed25519
                 │
   { valid | malformed | mismatch | invalid } → render [#3]
```

## 9. Acceptance criteria
1. "Verify" entry in left rail opens the panel.
2. Public key defaults to the current user's verifying key.
3. A known user's key resolves by name or club-id.
4. Any 32-byte hex key can be pasted (labelled "unverified binding").
5. Message input supports Text and Hex.
6. Correct (key, msg, sig) → **valid**.
7. Wrong key / tampered message / wrong sig → **does not verify** (no false
   claim about which).
8. Malformed key/sig lengths → input error, no crash, no backend call.
9. Directory-resolved wrong key → **key mismatch** (checked against history).
10. Pasted-key results clearly say "unverified key binding."
11. Attribution panel can "copy for verification" → typed envelope JSON.

## 10. Out of scope / future
- **Signed header** `{message_hash, signer_fingerprint}` emitted at signing
  time → diagnose fully-external pastes (v2; protocol change).
- **Server-key / audit-log** verification (different use case).
- **Client-side verify** for private content (privacy).
- **Batch verify** of exported provenance bundles.
- **Revocation** status display.
- **Key fingerprint UX** (QR / known-fingerprint matching).
