# Club & Identity Adversarial Review

*Working notes — the same mutation-driven method applied to identity
structures rather than documents. Companion to
`adversarial-resilience.md`.*

---

## Scope

What an attacker can reach when club/identity data crosses a trust
boundary: remote identity fetch (federation), membership sync,
persisted club restore, and the identity unification graph.

## Findings

### C1 — Remote identity fetch accepts unvalidated key material
**Severity: HIGH.** `fetch_remote_identity` (server.rs:2799) stores
whatever `verifying_key` string a peer serves — no hex-decode, no
32-byte length check, no format validation. A hostile directory
entry (or MITM, see C2) can plant arbitrary strings as identity
keys; they then flow into `identity_attestations` and anything that
resolves identity by key.

**Fix:** validate `verifying_key` as 64 hex chars decoding to 32
bytes before storing; reject otherwise.

### C2 — Identity fetch over plain HTTP
**Severity: HIGH.** The URL is `http://{address}:{port}/...` — no
TLS, no signature on the response. Anyone on the path can impersonate
identities wholesale. Federation trust is only as strong as its
weakest transport.

**Fix:** require `https://` for directory entries (with an escape
hatch for loopback test clusters), and/or verify a response signature
against the directory's registered server key — the key is already
in the directory entry; it is simply not used here.

### C3 — Unbounded display_name from peers
**Severity: MEDIUM.** `display_name` has no length cap before being
stored in the attestation table. Memory exhaustion and UI rendering
attacks (giant names in rosters) are cheap.

**Fix:** cap at ~120 chars (matches our local title conventions).

### C4 — club_id silently defaults to 0
**Severity: LOW.** A malformed/missing `club_id` becomes 0 rather
than an error. Harmless today (0 is never a valid club) but silently
accepting wrong-shaped data invites future bugs.

**Fix:** reject responses missing a valid club_id.

### C5 — Password verify parses attacker-influenced PHC strings
**Severity: LOW (defense in depth).** `verify_password` parses the
stored `phc_hash` with `PasswordHash::new`. Hashes are locally
generated today, but restore-from-backup and any future import path
put attacker-shaped strings there. PHC parsing failures are handled
(error, not panic) — good — but Argon2 cost parameters inside a
tampered hash would be honored, enabling CPU-exhaustion via crafted
restore files.

**Fix:** on restore, re-encode with server-chosen parameters or
clamp m/t/p within our constants.

### C6 — identity_unify has no cycle guard at the API surface
**Severity: LOW.** `identity_unify` delegates to the grand map's
unify. Cycles are the classic corruption of union-find structures.
Local callers pass sane ids; a wire-reachable path must validate
`source != target` and guard against unifying into a cycle.

## What is already solid

- `club_set_password` enforces min 10 / max 256 bytes
- Personal-club creation is authenticated and single-per-session
- Governance key registration is PBFT-gated (a peer can't rotate
  another server's keys without quorum)
- Password verification failures are rate-limited per club
  (`MAX_CLUB_LOGIN_ATTEMPTS`) and security-logged

## Method note

This review took the document-gate lessons and applied them in an
afternoon: map the boundary, read the deserialization/parse sites,
ask "what does this accept without validating?" The two HIGH
findings (C1, C2) are both at *seams* again — data crossing from
"another server" into "our trusted structures" without re-running
the checks local data passes. The pattern from
`adversarial-resilience.md` held: seams, not layers, are where the
bugs live.
