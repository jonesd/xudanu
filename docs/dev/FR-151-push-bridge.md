# FR-151: Push Bridge — APNs / FCM for the Mobile App

- **ID:** FR-151
- **Status:** Design (2026-10-20). Implementation gated behind the
  FR-149 Phase 3 shell; server-side prerequisite (FR-91b detectors)
  can start now.
- **Depends on:** FR-91b (detector event surface — the watch feed),
  FR-149 Phase 3 (Capacitor shell + bundle ID + paid Apple account),
  always-on exploration (`enfilade-mobile-always-on.md` — the wake
  protocol this bridge triggers)

## 1. Shape

A small always-on sender that turns server events into platform
pushes. Two hosting options, decided at implementation:

| Option | Pros | Cons |
|---|---|---|
| **In-server** (feature-gated module of xudanu-server) | one process, detectors are in-process | server binary grows platform SDK concerns |
| **Companion process** (subscribes to detector events) | server stays clean; bridge restartable independently | second thing to run |

Leaning companion — matches the server-never-handles-platform-secrets
instinct, and a crashed bridge must never take the server down.

## 2. Payload design (decide now, cheap; change later, expensive)

- **Opaque payloads only**: `{v: 1, kind, tumbler, hint}` where kind
  ∈ {cited, watch, presence-digest, search-match} and hint is an
  optional crum prefix. NO content, NO titles — notification privacy
  is a property of the wire, not a policy setting.
- **Silent (content-available) pushes by default** for anything the
  wake protocol can fetch; **visible pushes only** where the user
  opted into showing content in notifications (default off).
- iOS `apns-collapse-id` = tumbler+kind (stack notifications per
  passage); FCM `collapse_key` likewise. TTL short (1h) — stale
  pushes are worse than missed ones.
- The phone's job on wake is the crum wake protocol (already
  specced): root crum compare → subtree crums → delta chunks.

## 3. Credentials & ops

- **APNs**: token-based auth (.p8 key) — no cert expiry. Requires
  the paid Apple Developer account + App ID with Push capability +
  the app's bundle ID (decide the bundle ID EARLY; it names
  everything).
- **FCM**: HTTP v1 API (legacy API is dead) via a Firebase project
  (free to create; can be done today) — service-account JSON.
- Device token lifecycle: client registers
  `(platform, token, account)` with its authenticated session;
  bridge stores per-user device lists; APNs feedback / FCM
  invalid-token responses prune dead tokens nightly.
- Self-hosted caveat (inherited, documented): pushes flow only
  while the user's server (and bridge) is up.

## 4. What can start NOW vs what waits

**Now (no Apple account needed):**
1. FR-91b: detector registration API + persistent watchers
   (pure server work, benefits non-mobile clients too)
2. Firebase project + FCM v1 credentials (free)
3. Payload schema + bridge protocol spec (this card §2, refined)
4. Decide bundle ID (`info.dgjones.xudanu`? — everything keys off it)

**Gated (after shell exists):**
5. Bridge implementation (a2 crate for APNs, reqwest+JWT for FCM)
6. Capacitor push plugin wiring + token registration op
7. End-to-end: cited-you push → crum wake → delta fetch → deep link

## 5. Efficiency notes (the "use it efficiently" question)

- The bridge is a *level translator*, not a worker: detectors do the
  watching; the bridge forwards. One event → one push per device
  token, collapsed by tumbler.
- Rate-limit per user (digest bursts): N events in M minutes on the
  same work → one "several updates" push. The crum protocol makes
  the digest honest ("3 paragraphs changed") without the push
  carrying content.
- Nightly BGProcessingTask prefetch (reading streams) reduces the
  need for daytime pushes at all — the quietest notification is the
  one already on the device when you wake up.
