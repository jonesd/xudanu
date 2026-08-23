# FR-41: Network Demo Foundation — cross-server content discovery, secure retrieval, network transclusion, and realtime coordination

Status: draft · Date: 2026-08-21
Builds on: FR-6 (linked independent servers), FR-31 (cross-server
sharing), FR-35 (Bloom federation), FR-26 (content-addressed
transclusion), FR-40 (link constructs).
Demo goal: a 3-minute narrative on the Docker 3-node cluster
(xudanu.com-adjacent) that shows the full Xudanu network model
working end to end, with humans in a browser.

## Why

The strategic priority is a visible, demonstrable splash before the
window closes. The pieces exist — network model, text search,
content-addressed retrieval, transclusion, typed links — but no
single flow demos them as ONE system. This FR assembles the missing
connective tissue into a demo that Xanadu-literate viewers will
recognize as the original pitch, working:

> find content anywhere on the network, pull it in by reference
> (never by copy), quote it live into your own document, and talk
> about it with other people on the network — with cryptographic
> proof of who wrote what and that nothing changed in transit.

Nothing on the web does the middle of that sentence. That is the
demo's one job: make the transclusion-by-reference moment land.

## The demo narrative (target state)

Stage: `docker compose up` 3-node cluster (Alice/Bob/Carol), each
node with TLS, browser on Node 1. ~3 minutes, single continuous
story:

1. **Write** — Alice writes an essay on Node 1; pulls a passage
   from her second document as a local transclusion; attribution
   underline visible; she edits the *source* and the essay updates
   live. (Works today; polish only.)
2. **Search the network** — Alice hits search; Node 1 fans the
   query out to the directory (Bob, Carol); results arrive merged,
   each marked with origin server; she opens Carol's document
   preview rendered from Node 3's public API.
3. **Pull by reference** — Alice selects a passage in Carol's
   document and transcludes it into her essay: tumbler + BLAKE3
   content hash travel with it, provenance chain shows Carol as
   origin author, the passage renders inline on Node 1. This is the
   money shot. (FR-31.6 MVP exists; needs live-refresh + polish.)
4. **Carol edits her source** — the transcluded passage in Alice's
   essay updates (or flags source-changed). Live cross-server
   transclusion, not a copy. (Partially exists; gap story S3.)
5. **Network chat** — Alice opens the network chat panel; Bob and
   Carol join from their nodes; messages flow across the cluster in
   realtime. Alice quotes a chat message *by reference* into her
   essay — a chat message is just a small document, and quoting it
   is just a transclusion. (New — stories S5-S6.)
6. **Security curtain call** — one screen showing what protected
   every step: Ed25519 provenance on spans, BLAKE3 hash
   verification badges, the tamper-evident chained security log,
   TLS everywhere, signed identity exchange. (Exists; needs the
   "show it" surface — story S7.)

Non-goal: performance at scale, >3 nodes, WAN deployment. The demo
runs on one machine in Docker. Honesty: the chat overlay is
poll/push over existing links, not a new transport.

## Current state (measured)

- **Cluster**: docker-compose 3 nodes + `test-network.sh` (5
  connectivity checks) + FR-40 cross-server suite
  (`test-cross-server-network.sh`: healthy/down/blackhole/reject/
  recover/persist). Docker daemon currently blocked; suite ready.
- **Search**: `global_text_search` (local) + `federated_search`
  (0x0F08) exist server-side; no frontend surface merges and
  displays remote results with origin badges.
- **Cross-server retrieval**: `/api/public/work/{id}` +
  `/api/public/work/{id}/{start}/{end}` + signed
  `/api/public/identity` (FR-31); `CrossServerRef` persisted,
  BLAKE3-verified; `resolve_cross_server_ref` server-side.
- **Network transclusion**: FR-31.6 MVP — fetch-and-inline; spans
  recorded; FR-26 content addressing underneath. Live re-fetch on
  source change + UI placement polish are open.
- **Chat**: nothing. Nearest primitives: annotations (private
  option), presence/awareness, CRDT text sync, backlink-notify
  transport pattern (HTTP push with rate limits + SSRF guards).
- **Security layers** (all shipped, mostly invisible):
  TLS (rustls, per-node certs, `tests/tls.rs`), Ed25519 span
  provenance + key history, BLAKE3 content hashes, signed identity
  exchange w/ freshness windows, SSRF guards on all outbound fetch,
  rate limiting per IP/server, 8KB body caps, CSRF, chained
  security log, server-directory trust levels.

## Stories

### S1 — Search surface with network fan-out (frontend + verify)
- SearchOverlay gains a "search the network" toggle; on, the query
  runs `global_text_search` locally + `federated_search` via the
  directory; results merged, deduped by tumbler, each row badged
  with origin server (color per server), excerpt + license.
- Clicking a remote result opens a read-only preview pane fetching
  from the origin's public API (existing endpoints).
- Acceptance: on the 3-node cluster, a term present only on Node 3
  is found from Node 1 and previewable with a "Node 3 (Carol)"
  badge; remote-only and local results visually distinct.

### S2 — Pull-by-reference from preview (frontend + server verify)
- In a remote preview, text selection offers "Transclude into this
  document"; the flow captures tumbler + content hash + span,
  creates the CrossServerRef-backed transclusion at the cursor
  (reusing the local TransclusionBadge placement UX), and renders
  the passage inline with a cross-server provenance underline.
- Server re-verifies BLAKE3 hash at placement (already the case on
  resolve; keep it enforced at insert).
- Acceptance: end-to-end on the cluster — select in Carol's doc on
  Node 3's preview, passage appears in Alice's essay on Node 1 with
  Carol's attribution; hash badge shows verified.

### S3 — Live cross-server refresh (server + frontend)
- `source_changed` detection (exists for local spans) extended to
  cross-server spans: on doc open (and on manual refresh button),
  re-fetch the span range from origin, re-verify hash; if changed,
  mark the span and offer "update"/"show diff" (reuse FR-23
  revisions UI vocabulary).
- Acceptance: Carol edits the source on Node 3; Alice's view on
  Node 1 shows the changed flag within one refresh cycle and can
  pull the update; hash re-verifies.
- Honest scoping: no push from origin (that's FR-35 territory);
  pull-on-open + manual refresh is the demo contract.

### S4 — Transclusion stability gate (pre-demo hardening)
- The standing known edges — padding newlines, position migration
  on source edit, overlapping regions in the DOM builder — get
  regression tests before any recording. This is the demo's
  credibility floor; it's also the Roger-Gregory gate.
- Acceptance: existing transclusion test suite green plus new
  cases for each edge; a written smoke script (the demo's exact
  steps) passes twice in a row on the cluster.

### S5 — Network chat: transport (server)
- `chat_send { room, text }` over WS: message stored as a
  small frozen document on the sender's server (owner = sender),
  then forwarded to directory peers over the existing
  backlink-notify-style HTTP push (rate-limited, size-capped,
  SSRF-guarded — same hardened path FR-40 just bounded).
- `chat_log { room, since }` returns merged local + cached remote
  messages ordered by (origin server id, local seq) — no global
  clock claims; per-server ordering only, documented.
- Rooms are namespaced by tumbler prefix (a room IS an address);
  bootstrapping: the demo uses one fixed room tumbler.
- Acceptance: on the cluster, Bob's message typed on Node 2
  appears for Alice on Node 1 within ~2s; messages survive node
  restart (they're documents); offline node catches up on rejoin
  via `chat_log` pull.

### S6 — Network chat: panel + quote-by-reference (frontend)
- Right-panel Chat tab: room picker (demo: one room), message list
  (author chip, origin-server badge, timestamp), input box.
- Hovering a message offers "Quote into document" — inserts a
  transclusion of that message-document into the current work at
  the cursor, attribution intact. Chat-as-links made visible:
  a message can also be "linked" (typed Comment link) to a
  passage, both ends navigable.
- Acceptance: three browsers on three nodes chat in realtime
  (demo-wireless LAN feel); a quoted message renders in the essay
  with the sender's provenance; a Comment link from message to
  passage appears in both ends' Connections (FR-40 UI).

### S7 — Security curtain-call surface (frontend, small)
- One "Network security" panel (or a final demo slide in-app)
  rendering live data: this node's key fingerprint, directory
  trust levels per peer, last verified content hashes, security-log
  chain tip + "verified" badge, TLS status per connection.
- Acceptance: panel renders real values on the cluster; killing
  the demo mid-way and showing the log chain verifying is a
  bonus beat.

### S8 — Demo orchestration (tooling)
- `scripts/demo-network.sh`: one command — compose up, seed
  fixture documents + users on each node (deterministic tumblers),
  run the S4 smoke script headlessly (against the WS API, like
  ws-link-probe.mjs), print the story-step checklist with PASS
  marks, and leave the cluster up for the human demo.
- Acceptance: fresh machine → `demo-network.sh` → green checklist
  → manual demo works; also usable as CI gate later.

## Security layers (explicit, for the demo's curtain call)

1. **Transport**: TLS per node (rustls; self-signed dev certs,
   Let's Encrypt/Caddy in prod), HTTP public API + WS.
2. **Identity**: Ed25519 server keys (`/.well-known/`), signed
   identity exchange with freshness windows; per-user keys.
3. **Content integrity**: BLAKE3 hashes on every cross-server
   span, verified at fetch and at placement; content-addressed
   storage underneath (FR-26).
4. **Attribution**: Ed25519 span provenance — who wrote what,
   verifiable independently of the serving server; key history for
   rotation.
5. **Audit**: tamper-evident chained security log per server.
6. **Abuse resistance**: rate limits per IP and per peer server,
   payload caps, SSRF/loopback guards on all outbound fetches,
   bounded connect timeouts (FR-40), CSRF on state-changing HTTP.
7. **Trust scoping**: server directory trust levels; untrusted
   servers are searchable-but-flagged, not auto-fetched into
   composition (decision surfaced in UI).

## Sequencing ( Dependencies)

- S4 first (stability gate — everything rests on it).
- S1 → S2 → S3 (search → pull → refresh: the core narrative).
- S5 → S6 in parallel with S1-S3 where hands are free (chat is
  independent of the transclusion path).
- S7 anytime after S1 (reads existing state).
- S8 last (orchestrates all).

## Non-goals

- Push-based live sync from origin servers (FR-35 gossip stays
  the future path; demo uses pull-on-open).
- Global causal ordering for chat (per-server ordering stated
  honestly; vector clocks would be a follow-up FR).
- >3 nodes, WAN latency simulation, mobile clients.
- Chat transport reuse for arbitrary apps — noted as the future
  "network-wide applications" layer (this FR's chat is its first
  occupant, proving the pattern).

## Heritage note

The demo narrative is deliberately the Xanadu pitch: transclusion
by reference across a docuverse of independent servers, two-way
links visible from both ends, quotation with attribution and
micropayment-ready licensing (Transcopyright badges already ship).
Chat-as-documents is LM 93.1's Mail/Comment-Doc lineage viewed
through 2026 eyes. Gold's transpointing windows get their cameo in
the FR-40 Compare view when Alice compares her essay, Carol's
source, and the chat quote side by side.
