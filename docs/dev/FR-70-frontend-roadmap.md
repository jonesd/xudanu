# FR-70 — Frontend roadmap: hardening, deliberation, positioning

Consolidated from the 2026-09-16/17 sessions. The web side trails
the Rust side (3507 tests, proven recovery); this document is the
finish line. GitHub issues should mirror the actionable rows.

## A. Resilience finish (closes FR-69)

1. **S2 determinism** — remaining race suspects, in order:
   - S-1: sendTextDelta catch ROLLS BACK this.text on push failure
     (reverts the reconnect merge; the "server never got it" shape)
   - S-2: crdt_register_author is fire-and-forget; deltas before
     registration may be rejected → triggers S-1
   - S-3: onOpen fires connectionListeners(true) twice → effects
     run twice per reconnect → re-select interleave
   - S-4: pendingServerText applies unconditionally after ack,
     including over unsynced edits during the open push window
   Fix order: S-1 (guard the rollback for the initial-open push),
   then S-3 (single listener fire). Then 3x consecutive green S2.
2. **Banner honesty** — liveness-aware (never "reconnecting" into a
   dead frontend; probe /health), banner on welcome view, attempt
   cap with a prominent Reload offer.
3. **Scenarios S3–S5** — rapid cycling x5; 20 clients + RSS trend;
   SIGKILL mid-edit-stream (WAL vs acknowledged edits).
4. **Guard audit test** — 100 sequential connect/fail cycles never
   wedge (connecting/disposed/generation flags).

## B. Deliberation machinery (the multi-user resolution build-out)

The seeded four-party + Phase 2 demos prove the substrate; these
make it a usable mechanism:

1. **Claims ledger panel** — Links tab as grouped sections
   (DISAGREEMENTS (2) / COMMENTS / EVIDENCE), rows with author +
   excerpt; same grouping as the hover ledger (design locked,
   mockup 09).
2. **Status line at the join point** — "Revised in response · 1
   dispute standing · synthesis linked" derived from the record
   (history-resolved vs standing disputes, revision count, see-also
   to duplicates). Verdict-free by construction.
3. **Resolution affordances** — mark a dispute retired/superseded
   (already representable via deletion + history; needs UI), and
   the generation prompt: "upstream revised since incorporation"
   (source_changed) for downstream documents.
4. **Trace-mode connectors** — hover the right gutter → all elbows
   faintly (specced, unbuilt).
5. **Scenario templates** — multi-work scaffold duplication (the
   "duplicate set" extension), so a group can instantiate the
   deliberation structure per problem.

## C. Safety for a public crowd

1. **Runtime edit-policy toggle** — admin op + button: flip
   owner-only / public-sandbox WITHOUT restart (today it is a
   startup flag: --edit-policy).
2. **Identity-creation lock** — freeze new signups under load or
   attack (server op + admin UI).
3. **Rate limits** — link/document creation per identity per minute
   (server-side; protects the corpus from agent floods too).

## D. Positioning and documentation debt (not-a-notepad)

1. Docs needed for recent work: rendering redesign chapter
   (ribbons/chips/pill/ledger + palette rule), deliberation
   scenario guide (T1-T10 walkthrough), Phase 2 decision-chain
   explanation, authorship feature, FR-69 harness usage. Markdown
   (technical); one fancy HTML overview possible later.
2. Regenerate showcase captures (chips + authored ledgers) — the
   current set predates three redesigns.
3. The demo front door: Connection Atlas as the canonical first
   link for newcomers (it teaches the ladder in one document).

## E. Tier-1 leftovers (from the 24)

#178 duplicate-works UI, #173 search, #180 flicker, #176 blank
page, #188 wizard progression, #184 compare UX, #185 end count,
#194 descriptor hover.

## Ops note (not frontend)

xudanu.com deploy of v1.13+ remains blocked on the Hetzner machine
password reset (recovery console, done once before). After reset:
pull pre-built image (issue #191), reseed demos, --static-dir.

## Priority order

A1 → C1/C2 (cheap insurance before any crowd) → A2 → B1/B2 (the
deliberation story) → D1/D2 (positioning) → A3 → B3-B5 → E.
