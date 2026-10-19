# FR-148: Mobile Enfilade — The Docuverse in Your Pocket

- **ID:** FR-148
- **Status:** Proposed (2026-10-19), queued behind v1.20.0 and the
  FR-91a follow-ups. Grew out of `enfilade-mobile-notes.md`.
- **Depends on:** FR-88 (engine extraction — the enfilade must be a
  crate before it can be a mobile crate), FR-76 (freeze/eviction —
  shipped; the mobile memory story is built on it), FR-91a (bloom
  routing — the ask-little/fetch-less network posture)
- **Closes:** "can the docuverse live on a phone" — read-first, with
  a credible path to light authoring

## 1. The thesis

Mobile is usually treated as a thin client problem: a browser, an
API, and a prayer about connectivity. The enfilade inverts that.
Because **the tree is simultaneously index and container**, a phone
doesn't need a secondary index layer, a local database, or an offline
sync engine — the data structure already IS those things. The
hypothesis worth testing: a mobile device holding a *partial*
enfilade cache behaves like a first-class docuverse citizen, not a
degraded client.

## 2. Why the enfilade is unusually phone-shaped

| Mobile constraint | Enfilade answer |
|---|---|
| Little RAM | index+container in one structure; O(log N) with no secondary indexes; splay keeps the hot reading path near the root |
| Slow/expensive radio | subtree crums (BLAKE3): 32 bytes settles "do we agree?" — sync is compare-crum, fetch-delta-by-subtree, never re-download |
| Flash wear / battery | content-addressed chunks are immutable — reads never rewrite; dedup is structural, not a background job |
| Offline stretches | FR-76 freeze/eviction gives transparent RAM→disk spill; a partial cache serves reads with zero app-level logic |
| Metered discovery | FR-91a bloom routing: ask peers that might know, fetch capped excerpts — the network posture is already mobile-shaped |
| Trust on hostile networks | every chunk carries its hash; crums verify subtrees; server docs are signed (FR-91a trust ladder) — a phone can verify everything it's told |

## 3. The hard problems (be honest)

1. **Wasm maturity of the engine crate** — the `wasm` feature
   scaffold exists but the enfilade/chunk-store/crum paths have
   never been exercised in a browser runtime. Boundaries around
   file I/O (chunk store → IndexedDB or OPFS) are unproven.
2. **Splay write amplification** — splaying mutates tree nodes; on
   flash + battery that costs. Mobile likely wants *deferred splay*
   (batch rotations on interaction boundaries) or read-only splay
   with a local overlay. Needs measurement, not guesswork.
3. **Touch-native transpointing windows** — FR-143's windows are
   pointer-centric; phones need edge-panes, long-press destinations,
   and link-following gestures. This is real UI design, not a port.
4. **The authoring cliff** — full O-tree CRDT authoring on-device is
   a different league from reading. Don't promise it in v1; grow it
   (comments → annotations → links → text).

## 4. Sub-FRs (ranked by cost/benefit)

| Sub-FR | What it proves | Size | Depends |
|---|---|---|---|
| FR-148a: wasm engine build | enfilade + chunk store + crum verify compile and run under wasm (headless tests) | small-medium | FR-88 |
| FR-148b: read-only viewer | browse works, resolve transclusions, verify content/crums in a WebView shell | medium | 148a |
| FR-148c: crum-settled partial sync | offline cache + delta fetch by subtree; reconnect = crum compare | medium | 148b |
| FR-148d: mobile transpointing windows | touch-native windows (long-press follow, edge panes) | medium-large | 148b, FR-143 |
| FR-148e: light authoring | annotations/comments first (server-anchored CRDT, modest merge surface) | large | 148c |
| FR-148f: battery/bandwidth harness | CI-scale instrumentation: Joules per read, bytes per session, cache hit rate | small | 148b |

## 5. Sequencing

1. **FR-148a + FR-148f first** — prove the runtime and get the
   measurement harness in before any UI exists ("no UI without a
   budget").
2. FR-148b (viewer) — the demo that changes minds.
3. FR-148c (sync) — the feature that changes usage.
4. FR-148d (windows) and FR-148e (authoring) as independent tracks.

## 6. Distribution & monetization (revised 2026-10-19)

**App Store is the primary commercial path.** This aligns with the
hard design rule (server never handles money): Apple takes payment,
the shell gates capability, servers stay clean.

- Free tier: read-only viewer (FR-148a/b) — the audience builder
- Pro subscription (IAP): offline sync + partial caches (148c),
  light authoring (148e), later windows (148d)
- Paid features exist only in the Store build (entitlement-gated);
  the free web build simply omits them — no server paywall, no
  meaningful piracy surface
- Shell: Capacitor or Tauri v2 wrapping the SAME wasm + TS codebase
  (days, not a fork); PWA remains the free web tier
- Honest ledger: 15–30% Apple cut, review-gated releases, Store
  discovery is its own effort

## 7. Non-goals (v1)

- Full mobile editing (O-tree authoring stays server-side until
  148e proves itself)
- Background mesh participation — a phone is a citizen, not a peer

## 8. Test plan sketch

- wasm: same known-value tests as native (crum trees, freeze
  round-trips, chunk dedup) — the engine must be bit-identical
  across targets
- sync: offline→online crum reconciliation on mutated subtrees;
  adversarial: server presents wrong crum → detected, subtree
  refetched
- harness: battery/bandwidth budgets asserted in CI on recorded
  interaction traces
