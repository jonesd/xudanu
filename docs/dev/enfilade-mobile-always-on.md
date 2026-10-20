# Always-On Mobile — What the Enfilade Buys

- **Status:** Exploration (2026-10-20), companion to FR-148/149.
- **Question:** what do the enfilade and the existing server machinery
  enable for an always-on mobile app — notifications, background
  work, offline queues?

## 1. The constraint that shapes everything

Mobile OSes forbid always-on apps. iOS: no background sockets;
you get push notifications (server-initiated), ~30s background
refresh windows, and nightly processing tasks. Android: similar,
plus foreground services at a battery/UX cost. Therefore "always-on
mobile" = **the server watches; the phone gets woken and does a
small, bounded job.** The entire question is how cheap we can make
the wake.

## 2. The wake protocol — where the enfilade dominates

A wake gives the app seconds and metered bytes. The existing
structures compose into a protocol where a full sync decision costs
~tens of bytes:

1. Wake (silent push: opaque payload — a tumbler and nothing else)
2. Fetch the home server's current **root crum** (32 bytes — BLAKE3
   of the top subtree; "did ANYTHING I cache change?")
3. Compare against the locally cached crum. Same → done, go back to
   sleep. Total traffic: one hash.
4. Different → walk cached **subtree crums** (each 32 bytes) to
   localize what changed — binary-search style, log-sized — then
   fetch **only the new content-addressed chunks** covering the
   delta
5. Apply to the local enfilade (chunk store + FR-76 freeze make
   partial application always-valid), update stored crums, post the
   user-visible notification with a **tumbler deep link** (opens
   the app at the exact passage)

A conventional app re-pulls documents and diffs text. The enfilade
skips to "these three chunks, verified by hash, done." The wake
budget goes from marginal to comfortable — this is the same
compare-crum/fetch-delta property FR-91 noted for servers, relocated
to the pocket.

## 3. What the server already has (the watching side)

| Existing component | Always-on use |
|---|---|
| **Backlink notifications (signed)** | a ready-made push event: "someone cited your passage" with cryptographically verified origin — maps 1:1 to a notification |
| **Detectors (Gold machinery; FR-91b)** | server-side watchers on watched works/passages — the server watches so the phone doesn't poll |
| **Awareness/presence (remoteCursors)** | collaborator activity digests on wake ("Robin edited §3 while you were away") |
| **O-tree CRDT** | offline edit queue on device; background-refresh windows flush queued ops opportunistically |
| **Trails / reading streams (FR-147)** | nightly prefetch of followed streams → offline morning reading (BGProcessingTask) |
| **Bloom-routed search (FR-91a)** | server-side saved queries: poll peers for me, push when a match appears — phone never polls the network itself |
| **Tumblers** | every notification addresses its target exactly and stably — deep links that survive any amount of change |

## 4. The missing piece: a push bridge

APNs/FCM require a server-side sender with platform credentials.
Minimal design: a small component of the home server (or a companion
process) holding APNs/FCM keys, subscribing to detector/backlink
events, and emitting opaque payloads (tumbler + event kind — NO
content, preserving notification-privacy: content is fetched at wake
by the phone's own authenticated session).

## 5. Honest limits

- **Presence while closed is impossible on iOS** (no background
  socket). "Who's editing now" works only with the app open. Don't
  fight this.
- **Push depends on your server being up** — self-hosted caveat
  inherited from the whole architecture (and consistent with it).
- **Notification privacy**: keep payloads opaque; the OS sees
  "activity in a document," not document text.
- **Nightly prefetch is the battery-friendliest channel** — anything
  that can be a digest should be a digest.

## 6. Feature ladder (cheapest first)

1. **Cited-you pushes** (backlink notify → push, signed origin shown)
2. **Watched-work updates** (detector → crum-delta summary: "3
   paragraphs changed in *Brief*")
3. **Offline edit flush** on wake (CRDT ops buffered locally)
4. **Reading-stream nightly prefetch** (offline morning reading)
5. **Saved-search alerts** (server polls via bloom routing, pushes
   matches)

Each step is the same wake protocol with a different watcher — no new
client machinery per feature.
