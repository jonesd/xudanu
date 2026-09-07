# Provenance Flow and Claim Strength

How an edit becomes a cryptographically signed fact in Xudanu, and —
critically — exactly how strong each claim is when said out loud to
a client. The flow first, then the claims table, then the landscape.

## 1. The flow: keystroke → signed span

```
user edits (CRDT ops)
   │
   ▼
materialize_with_provenance        [server.rs:3562]
   collects every author session that contributed to the work
   resolves each author's Ed25519 club signing key
   (key was generated at identity creation; password login
    decrypts it into the session — login_decrypts_signing_key)
   │
   ├── sign_element  (per text element)          [provenance.rs:1040]
   │     payload = BLAKE3( "xudanu/v1/element-provenance"
   │                       ‖ element_content_fingerprint
   │                       ‖ author_pubkey ‖ timestamp ‖ server_id )
   │     signature = Ed25519(author_key, payload)
   │
   └── sign_span  (per span, e.g. revision)      [provenance.rs:1468]
         payload = BLAKE3( "xudanu/v1/provenance"
                           ‖ fold(all element fingerprints)
                           ‖ author_pubkey ‖ timestamp ‖ server_id )
         signature = Ed25519(author_key, payload)
   │
   ▼
revise_work stores the edition; appends to the
ATTRIBUTION LOG — hash-CHAINED (each entry carries prev_hash,
genesis seeded from security.log.seed), entries carry
author_pk_hex ‖ span_fp_hex ‖ signature ‖ server_id ‖ work ‖ rev
   │
   ▼
notarize_range (on demand)                    [notarize.rs:19]
   server-signed receipt: work_id ‖ range ‖ range_crum (fold of
   covered entry crums) ‖ root_crum (edition state) ‖ excerpt_hash
   ‖ timestamp → Ed25519(server_key, ·)
```

Key identities: sessions WITHOUT a personal key (public sandbox)
fall back to the **server keypair** — attribution then names the
server, honestly, not a person.

## 2. Verification states (what the UI's ✓ means)

`attribution_query` returns three states (server.rs:5015–5040):

| state | meaning |
|---|---|
| `verified` | stored Ed25519 signature checks out against the CURRENT content fingerprints — the text is bit-identical to what was signed |
| `author_maintained` | stored signature fails (the author's own later edits regrouped the span), but the author's key is available and re-signing the current content with the SAME key succeeds — still genuinely that author's contribution |
| `unsigned` | no verifiable signature — content exists without proof of who wrote it |

## 3. Claim strength — the honest table

### Claims you CAN make (cryptographically backed)

1. **"This exact text was signed by this key at this time on this
   server."** Ed25519 over a domain-separated BLAKE3 payload. If the
   content is presented and the signature verifies, the text has not
   changed by one character since signing.
2. **"This passage existed in this work, in this state, at this
   time."** The notarization receipt proves it to anyone holding the
   server's public key — **without access to the document**
   (excerpt_hash + range_crum + root_crum).
3. **"The attribution record has not been edited since."** Hash
   chain; any retroactive edit breaks every subsequent link.
4. **"Alice wrote this passage"** — WHEN Alice holds a personal
   signing key (password-created identity) AND the key→Alice binding
   is trusted (below).
5. **"The quote in document B derives from document A"** —
   transclusion carries provenance across documents; the ancestry
   walker (`provenance_ancestry`) returns the chain.

### Claims that are CONDITIONAL (server is the trust root)

- **Key→identity binding.** The server's club registry + key history
  binds "key K = Alice." The server is its own CA. A compromised or
  malicious server can mint keys and attribute content to anyone.
  Mitigations that exist: key rotation with signed rotation proofs
  (`key_history`), the chained log (retroactive rewriting breaks the
  chain), and client-side key receipts (a user who saved their
  public key elsewhere can prove the server-side "Alice key" isn't
  theirs).
- **Timestamps.** The timestamp is inside the signed payload, but
  the clock is the server's. A signature proves "not created AFTER
  verification time unless the signer lied about the clock." No
  external anchoring yet (see roadmap).
- **Anonymous sessions.** Server-key-signed spans prove content
  integrity, not human authorship. Say so plainly in demos.

### Known gaps (say these before a client discovers them)

- No external timestamp anchoring (OpenTimestamps / RFC 3161)
- No key revocation UX beyond rotation proofs
- Cross-org trust is manual (server directory + trust levels);
  verification across organizations works cryptographically but
  discovering/trusting the other org's keys is operator-driven

## 4. Landscape — what's out there (checked Sept 2026)

| System | Granularity | Crypto | Text? | Verdict |
|---|---|---|---|---|
| C2PA / Content Credentials (Adobe, MSFT, BBC…) | whole asset | yes, signed manifests | media; text not at span level | The standard — but asset-level. **Xudanu is the sub-asset text gap.** Complement, not competitor. |
| Git blame / GitHub | line-at-commit | none on content; history mutable | yes | Attribution, but forgeable and reorderable |
| Word / Google Docs track changes | passage | none | yes | Forgeable; the thing enterprises use today |
| W3C PROV | dataset/process | none (model only) | n/a | Interop standard — Xudanu already ships a PROV-JSON validator; **export to PROV is the bridge** |
| OpenTimestamps / file notarization | whole file hash | yes (Bitcoin anchor) | n/a | Anchors blobs, not spans — natural upgrade path for our timestamps |
| WikiWho & attribution research | passage | none (reconstructed) | yes | Computational attribution, no signatures |
| Data lineage (OpenLineage, Palantir) | dataset/process | varies | no | Different problem |
| AI watermarking / detection sector | whole output | statistical | yes | Detection ≠ provenance; complementary |

**Defensible uniqueness claim** (use exactly this form): *"per-span
Ed25519 author signatures over collaboratively-edited text, where
provenance travels with the passage across documents."* Every
individual piece has neighbors; the combination does not. Do not
claim "unbreakable" or "tamper-proof" — claim *"tamper-evident with
per-passage cryptographic attribution."*

## 5. Cheap upgrades that strengthen the claims

1. **OpenTimestamps anchoring of attribution-log chain heads** —
   upgrades timestamps from server-asserted to externally verifiable;
   ~1 day of work, closes the weakest claim.
2. **PROV-JSON export of a work's provenance** — validator exists;
   makes the machinery interoperable with enterprise lineage tools.
3. **C2PA manifest embedding for exported documents** — position as
   the text-span layer under the asset-level standard.
4. **Key receipt export** ("verify my identity binding against this
   server") — a user-side check on the server-as-CA weakness.
