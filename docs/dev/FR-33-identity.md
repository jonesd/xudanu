# FR-33: Identity Attestation

## Overview

Addresses Nelson's Rule 3: "Every user is uniquely and securely identified."

Xudanu uses a **home server attestation** model. Your home server holds
your private signing key. Other servers verify your identity by asking
your home server. The private key never leaves the home server.

This is similar to how email works: your identity is `david@xudanu.com`,
and other servers verify by asking xudanu.com. No central identity
provider needed.

## Design Decision: Why Not Browser-Side Keys?

We considered storing the user's Ed25519 private key in browser
localStorage for portable identity. We rejected this approach:

| Concern | localStorage Keys | Home Server Attestation |
|---------|-------------------|----------------------|
| XSS attack | Private key stolen → full impersonation | Private key safe on server |
| Browser extensions | Can read localStorage | Not accessible |
| Physical access | Key extractable via DevTools | Not in browser |
| Key rotation | Must re-distribute to all browsers | Rotate once on home server |
| Multiple devices | Must sync key between devices | Just log in to home server |

**Decision:** Private keys stay server-side. Browser only ever sees
public verifying keys.

## How It Works

### Account Creation (on Home Server)

1. User creates account on Server A (e.g., xudanu.com)
2. Server generates Ed25519 keypair
3. Private key encrypted with user's password (Argon2id + envelope)
4. Public key stored on the Club (visible via public API)
5. User's name + key registered in `club_names` mapping

### Cross-Server Content Attribution

When Server B fetches content from Server A:

1. Content includes `span_provenance` with author's signing key
2. Server B sees the key but doesn't know the name
3. Server B can query Server A: "Who has this key?"
4. Server A responds: "David G Jones, club_id 0x3ec"
5. Server B stores this as an `IdentityAttestation`
6. Attribution panel shows "David G Jones (via Alice)" instead of key hash

### Identity Attestation Data

```rust
pub struct IdentityAttestation {
    pub display_name: String,
    pub verifying_key: String,       // hex Ed25519 public key
    pub home_server_id: u64,
    pub home_server_name: String,
    pub home_server_address: String,
    pub club_id: u64,                // local BeId on home server
    pub verified_at: u64,            // timestamp
}
```

Stored in `identity_attestations: HashMap<String, IdentityAttestation>`
keyed by verifying key.

## Public API

### GET /api/public/identity?q=name

Returns identity info for a named user (only personal clubs):

```json
{
  "api_version": 1,
  "implementation": "xudanu",
  "identity": {
    "display_name": "David G Jones",
    "verifying_key": "064063c5...",
    "club_id": 1004
  }
}
```

Rate-limited, CORS-enabled, unauthenticated. Only returns public keys —
no private data.

### Wire op: fetch_remote_identity (0x0F0D)

```
fetch_remote_identity {
    server_id: String,    // home server in directory
    club_name: String,    // name to look up
}
```

Server fetches the identity from the home server's public API, verifies
the response, and stores the attestation locally.

## Security Properties

- **Private key never leaves home server** — browser XSS cannot steal it
- **Public key is cryptographically unique** — 256-bit Ed25519
- **Name resolution goes through trusted directory** — only trusted
  home servers are queried
- **Attestations cached locally** — repeated lookups are instant
- **Home server compromise only affects its own users** — other servers'
  attestations remain valid (cached)

## Comparison with Other Systems

| System | How identity works | Private key location |
|--------|-------------------|---------------------|
| Email | name@domain | Server (SMTP) |
| ActivityPub | name@instance | Server |
| SSH | username@host | Client (key pair) |
| PGP | Key fingerprint | Client (or smartcard) |
| **Xudanu** | **name@home_server** | **Home server (encrypted at rest)** |

Xudanu's model is closest to email/ActivityPub: identity is tied to a
home server, verified through the server directory's trust relationship.

## Current Implementation Status

| Component | Status |
|-----------|--------|
| `IdentityAttestation` struct | ✅ Done |
| `fetch_remote_identity()` | ✅ Done |
| Public identity endpoint | ✅ Done |
| `resolve_identity_by_key()` | ✅ Done |
| Wire op registered in JSON codec | ✅ Done |
| Frontend API client method | ✅ Done |
| Attribution spans show key hash | ✅ Done |
| Attribution resolves to name via attestation | 🔨 Needs wiring |
| Identity panel shows home server | 📋 Planned |

## What This Enables

1. **Cross-server authorship:** "David G Jones (via xudanu.com)" appears
   consistently across all servers that have attested your identity

2. **Authoritative attribution:** content provenance traces back to a
   cryptographically verified key, with a human-readable name attached

3. **No account needed on every server:** you have one home server,
   your identity follows you via attestation

4. **Foundation for trust scoring:** servers can weight content by the
   author's reputation (future: FR-38 trust scoring)

## Relationship to Gold

Gold had no cross-server identity. Each server's users were isolated.
The `historical_author_register` was a local-only feature for recording
authors of imported texts (e.g., "Mark Twain, 1835-1910").

Xudanu extends this concept across the network: your identity is
globally resolvable through your home server, without requiring a
central identity provider.
