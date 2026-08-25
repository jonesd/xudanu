# FR-45: Admin Console & Server Maintenance

Status: draft · Date: 2026-08-25
Builds on: FR-42 (posture: personal vs public deployments), #142
(archive-first GC — deletion semantics), the network/external-link
toggles (2026-08-25), AdminDashboard (existing read-only health
surface).

## Why

The Admin Dashboard today is a health monitor: metrics, checks, two
links. Every *administrative* capability exists somewhere — CLI flags
at startup, wire ops with no UI, scattered Settings toggles — but an
operator facing a live incident (abusive content on a public-sandbox
deployment, a stuck session, "what did the server just do?") has no
path from the UI. The gap that matters most: **content moderation**. A
public-sandbox server can receive a 10 MB hostile paste (no text-size
cap existed), and the operator's only response is CLI surgery. That
makes public deployments indefensible — which blocks the demo-instance
plans in FR-42.

Separately: untrusted-content hardening (external links locked down,
2026-08-25) raised the natural question "what else can document
content or strangers do to my server?" This FR is the answer's admin
half: see everything, act on anything, prove what happened.

## Principle

**One admin surface.** Server-wide policy belongs in the Admin
Console, not scattered across Settings (user prefs) and CLI flags
(set-once-at-boot). Every admin action is: admin-gated on the wire,
recorded in the security log, visible in the audit view. **Read-only
by default** — viewers (sessions, audit) change nothing; mutators
(archive, delete, kick, policy) are explicit and confirmed.

## Deletion semantics (decision)

Archive remains the default remediation (#142: recoverable for 50
checkpoint generations). **Hard delete is a distinct admin action**:
archive → drop from the works map → checkpoint; chunk reclamation is
left to the existing GC grace path. No direct chunk deletion anywhere
in the admin path — the GC's own safety rules stay load-bearing.
Delete requires typing the work id (no accidental nukes).

## Phases

### P1 — Content moderation (+ abuse ceiling)
- Backend: `char_count` on WorkListEntry; `work_delete_admin`
  (admin-gated, archive-then-drop as above); **1 MB per-revision text
  cap** on create/revise/delta paths (blob cap's sibling; ~500k words
  — no legitimate document is close).
- UI: Admin → Content tab. Table: title, id, author/owner club, size,
  revisions, public/private, updated. Search filter. Actions: Archive
  / Restore / Delete (typed confirmation). Row click opens the work.

### P2 — Policy (consolidation)
- Backend: `admin_edit_policy_set` (owner-only | public-sandbox) +
  current policy in health JSON (network_enabled and
  external_links_enabled already report).
- UI: Admin → Policy tab: edit policy, Xudanu network, external
  links. Settings keeps user-level prefs only.

### P3 — Sessions & Audit (visibility)
- Backend: `admin_session_kick` (drop session, close its WS);
  `admin_audit_tail` (last ~200 lines of current security.log +
  chain-validity flag; read-only — the CLI verify remains the
  authoritative check).
- UI: Sessions tab (id, identity, authority, connected-at, Kick) and
  Audit tab (monospace tail, refresh, chain badge).

### P4 — Identity/club management
- UI-first (backend ops exist): Identities tab — clubs, verified
  state, works owned; grant/revoke edit access; grant admin
  authority. Lowest urgency: owner-only deployments barely need it.

## Non-goals

- No content *filtering* (size caps + moderation + audit cover the
  threat; opinion filtering is out of scope).
- No admin mutation of document text — moderation is
  archive/delete, never editing others' words.
- MFA/login hardening (separate FR if public deployments demand it).

## Tests

Per phase: backend ops (admin-gating, effect, persistence), frontend
rendering. P1 additionally: text-cap enforcement on all three write
paths; delete leaves chunks to GC (verified via the recovery drill
pattern).
