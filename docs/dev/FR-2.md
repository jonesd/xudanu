# FR-2: Account Verification & Edit Gate

- **ID:** FR-2
- **Status:** Draft (not yet implemented)
- **Date:** 2026-06-29
- **Owner:** backend + frontend
- **Depends on / relates to:** re-introduces the edit-protection gate reverted in
  `revert: drop edit-protection signing-key gate` (see §7).

## 1. Overview

Close the signup-veracity gap: today anyone can create an identity with only a
display name + password, no proof of identity. FR-2 introduces **account
verification** so that editing requires a **verified account**, while anonymous
**reading** remains open (browse → motivates signup).

## 2. Background — the gap and the reverted gate

- Signup is open and unverified (`create_personal_club(..., None, None)`).
- A prior "edit protection" gate (commit `01901728`) required a signing key to
  edit but (a) was never reconciled with the test suite (~93 failures) and (b)
  gated on key *presence*, not account *veracity*. It was reverted to restore CI.
- FR-2 re-introduces an edit gate, but gated on **verified status**, with the
  test suite updated to use verified accounts.

## 3. Goals / Non-goals

**Goals**
- A trustworthy signal that an account belongs to a real, reachable user.
- Edit (and other authoring actions) restricted to verified accounts.
- Keep anonymous/public **reading** open.

**Non-goals (for v1)**
- Full KYC / identity-proofing.
- A built-in mailbox; we send via a provider.
- Moderation tooling beyond rate-limits (deferred; see FR-1 §10 abuse note).

## 4. Account states & lifecycle

```
anonymous ──signup (email)──▶ unverified ──verify (click/token/OAuth)──▶ verified
                                  │                                          │
                                  └─ can READ, cannot EDIT ─┘   can READ + EDIT
```

- **unverified**: identity created; may read; **cannot edit**; may be purged
  after N days if never verified.
- **verified**: may edit.
- **OAuth (GitHub/Google)**: created **verified** directly — the IdP asserts a
  verified email, so we trust it.

## 5. Verification methods

1. **Email verification (primary).** At signup, user provides an email; server
   issues a single-use, expiring token and emails a link. Clicking marks the
   account verified.
2. **OAuth (existing, fastest path).** `--github-client-id` / `--google-client-id`
   already exist; OAuth sign-ins create a verified account automatically via the
   IdP's verified email. **Recommend surfacing "Sign in with GitHub/Google" as
   the primary signup path** — minimal infra, strong veracity.
3. **Invite-only / admin approval (optional bootstrap).** An admin or existing
   member invites a user by email/handle; invitees are verified on redeem. No
   email-sending infra required — good for early/controlled rollouts.

A deployment picks one or more (OAuth + email, or invite-only, etc.).

## 6. Functional requirements

### FR-2.1 Data model
- `Club` gains: `email: Option<String>`, `verified: bool`
  (or `verified_at: Option<DateTime>`), and a verification token store
  (`token_hash -> (club_id, expires_at)`, hashed at rest).
- Migration: existing clubs default to `verified = false` (or a flag-day
  amnesty — see §10).

### FR-2.2 Signup with email
- `create_personal_club` accepts an optional email; if provided, account starts
  `unverified` and a verification email is sent.
- Email syntax validation + normalization (lowercase, trim).

### FR-2.3 Verify endpoint
- `GET /verify?token=...` → looks up token hash → marks `verified`, invalidates
  token, redirects to the app with success/failure.
- Tokens: 256-bit, single-use, short TTL (e.g. 24h), hashed at rest.

### FR-2.4 OAuth = verified
- `create_personal_club_from_oauth` sets `verified = true` when the IdP returns
  a verified email; else leaves unverified and falls back to email verify.

### FR-2.5 Edit gate (the re-introduction)
- Edit/authoring operations require the session's active club to be `verified`.
- Implemented in `ensure_can_edit` (or at the transport boundary — see §8) by
  checking `club.verified`, **not** merely `signing_key` presence.
- Anonymous/public reading untouched (`ensure_can_read`).

### FR-2.6 UX
- Signup form adds email field; "Verify your email to start editing" banner on
  unverified accounts; resend-verification link.
- Identity panel shows verification status (verifies the §4 lifecycle is
  visible).

## 7. What this suggests for the reverted edit-protection

- The reverted gate was **right to exist, wrong to gate on key presence**. The
  faithful version gates on **`verified`**.
- The 93-test breakage is resolved by making the editing test helper create
  **verified** accounts (e.g. `setup_editing_session` marks the club verified),
  not by weakening the gate.
- Recommended placement: gate at the **transport boundary** (WS/HTTP dispatch
  for edit ops) so core unit tests test *capability* and the policy lives at the
  edge — unless core enforcement is preferred, in which case tests use verified
  clubs.

## 8. Implementation details

### 8.1 Backend — dedicated `verification` module
Verification logic lives in its own module (not smeared across `identity.rs` /
`oauth.rs` / `server.rs`). The *data* stays on `Club`; the *machinery* is isolated:

```
src/server/verification/
  mod.rs        public API: mark_verified, is_verified, issue_token, verify_email
  token.rs      VerificationTokenStore (hash-at-rest, TTL, single-use)
  provider.rs   EmailProvider trait + DevProvider (logs link) + ResendProvider (later)
  handler.rs    axum handlers: POST /signup, GET /verify?token=, POST /resend-verification
```

- `Club` (`club.rs`): adds `email: Option<String>` + `verified: bool` fields +
  getters/setters (data only, no logic).
- `ClubSnapshot` (`server.rs`): adds the two fields with `#[serde(default)]` and
  the to/from-snapshot mappings (backward-compatible with existing manifests).
- Edit gate: `ensure_can_edit` (or transport) calls `verification::is_verified(club_id)`.
- OAuth success: calls `verification::mark_verified(club_id)` and stores the IdP email.
- Email sending: pluggable via env (`XUDANU_EMAIL_PROVIDER`); **DevProvider** is the
  default and logs the verification link to the server log (works at home, no infra).
- Endpoints (slice 2): `POST /signup`, `GET /verify?token=`, `POST /resend-verification`.
- Persistence: **no new datastore.** All auth metadata lives in the **manifest
  snapshot** (`ServerSnapshot`), checkpointed atomically with clubs/works — not
  in standalone JSON files, and not in the (content-addressed, document-only)
  chunk store. Specifically:
  - `key_history` (server public keys + rotation proofs) → **manifest-only**;
    drop the redundant `key_history.json` mirror (it's already in the snapshot).
  - `OAuth links` (provider↔club) → **new section in the snapshot**. This also
    fixes a latent gap: links are currently in-memory only and lost on restart,
    so OAuth-verified accounts don't survive a restart. Persisting them is a
    prerequisite for FR-2's OAuth-verified path in production.
  - `verification tokens` → **new section in the snapshot** (hashed at rest,
    TTL, single-use, **atomic redeem** under a lock so concurrent clicks can't
    double-spend).
  - `email` / `verified` → on `Club`, already snapshot-persisted.
- Durability: the manifest checkpoints every few seconds, so a token issued
  moments before a crash could be lost (user re-requests — acceptable). For
  instant durability, write through the existing **WAL** (`persist/wal.rs`) —
  not a new store, the one already there.

### 8.2 Frontend
- Signup form: email field + password; calls `/signup`.
- Unverified banner + resend link; gate the Write toggle / editor on verified
  state (show "Verify your email to edit" instead of a read-only cursor).
- Identity panel: verification badge + email.

### 8.3 Anti-abuse
- Rate-limit signups + resend per IP and per email (reuse the existing login
  rate-limiter pattern, `identity.rs` `login_attempts`).
- Token TTL + single-use; email canonicalization to avoid trivial dupes.
- Honeypot/CAPTCHA deferred.

## 9. Security considerations
- Tokens hashed at rest (not plaintext); single-use; short TTL.
- Edit gate is the security control; read stays open.
- OAuth trust is bounded by the IdP — only treat emails the IdP marks
  `verified` as verified.
- Email is PII — store minimal, don't log full addresses in audits beyond what's
  needed.
- The private signing key story is unchanged (server-side only).

## 10. Migration / rollout
- Existing clubs: either default `verified = false` (forces re-verification) or
  a one-time amnesty (`verified = true`) to avoid locking out current users.
  Recommend amnesty for personal clubs that already hold a signing key, with a
  cutover date announced.
- Deploy behind configured OAuth/email; invite-only mode if no email provider.

## 11. Acceptance criteria
1. Signup with email creates an **unverified** account that can read but not edit.
2. Clicking the verification link marks the account **verified**.
3. Verified accounts can edit; unverified/anonymous cannot (clear error).
4. OAuth signup yields a verified account when the IdP email is verified.
5. Tokens are single-use, expire, and are stored hashed.
6. Signup/resend are rate-limited per IP/email.
7. Identity panel shows verification status + email.
8. The 93-test suite passes with editing tests using verified clubs.

## 12. Out of scope / future
- Email change/re-verification flows.
- 2FA / passkeys.
- Admin moderation UI, reports, bans.
- Decentralized/federated identity verification across xudanu peers.
- "Verified" badges as a social signal (separate from edit permission).

## 13. Domain reputation & email deliverability

**Status of xudanu.com (checked 2026-06-29):**
- Resolves to `13.59.70.71` (AWS, us-east-2); HTTPS is configured and working from home.
- **Not on any major spam blocklist** — Spamhaus DBL, SURBL, Barracuda, SpamRATS all return clean.
- Domain is **new (registered only weeks ago)** → low sender reputation and inside the
  **Newly Registered Domain (NRD)** window.

**Two consequences of being a new domain:**
1. **Corporate web filters** (Cisco Umbrella, Palo Alto, Zscaler, Fortinet) auto-block NRDs
   by default as anti-phishing — this is why the domain is blocked at some workplaces, *not*
   a spam listing. Fixes: IT allowlist; submit the domain to the filter vendor for
   categorization (Business/Education); self-resolves as the domain ages (~30 days).
2. **Email sent from xudanu.com** risks being spam-filtered until the domain is warmed up,
   which directly undermines verify-by-email (if the email lands in spam, users can't verify).

**Prerequisites before xudanu.com sends email:**
- DNS authentication records: **SPF**, **DKIM** (keys from the provider), **DMARC**.
- A **transactional provider** (Resend / Postmark / SendGrid / SES) sending from warmed IPs.
- **Warmup** — ramp volume over weeks.
- Optional **subdomain** (`mail.xudanu.com`) to isolate sender reputation.
- DMARC should start at `p=none` (monitor) and tighten once flows are observed.

**Sequencing (the answer to "what can we do now"):**
- **OAuth-first** needs *no* email from xudanu — GitHub/Google verify the email themselves.
  This is the path to ship verified signup immediately while the domain ages.
- Defer **email-from-xudanu** until the domain is categorized + DNS auth configured + a
  provider chosen + warmed. Build the email-verification backend now with a **dev/no-op
  provider** (logs the verification link to the server console) so it's switch-on ready.

## 14. Recommendation

Land **OAuth-first** (already built, auto-verifies, lowest infra), wire the
**edit gate on `verified`** at the transport boundary, and add **email
verification** as the self-service path. This re-introduces edit protection
correctly (the reverted gate's intent) and closes the veracity gap you flagged,
without re-breaking the test suite.
