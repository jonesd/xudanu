# Changelog

All notable changes to **xudanu** — a hypertext document store (Rust server + React frontend). Items are summarized from the commit history; the date beside each version is when that tag was created (some are approximate). Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

GitHub releases: https://github.com/jonesd/xudanu/releases

---

## [v0.9.7] — 2026-07-20

### Workspace Shell (FR-18) — new UI at /explore
- **feat(workspace):** New `WorkspaceShell` component with 4-zone layout (top bar, left rail with graph + concepts, document surface, right panel with tabs). Route at `/explore` alongside existing AppShell at `/`.
- **feat(theme):** Six palette themes (Midnight, OLED Black, Slate, GitHub Light, Solarized, Paper) with picker dropdown in TopBar. Persisted to localStorage.
- **feat(graph):** Relevance-filtered mini graph (FR-21) — 9-node display with force-directed layout, kind-colored nodes with icons, light dotted edges, position clamping, related concepts panel. 65 unit tests for scoring functions.
- **feat(concepts):** WorkKind backend (FR-22) — Document, Note, Person, Concept, Collection, Commentary. Wire ops for get/set kind. 41 seeded default concepts (hypertext/PKM/writing). Kind picker in document header and work list.

### Revision System (FR-23) — Phase A + C
- **feat(revisions):** 5 wire ops (work_revisions_list, work_text_at_revision, work_revision_describe, work_revision_mark_notable, work_revision_rollback). Auto-recording metadata in revise_work (timestamp, author, change summary, auto-notable detection). 19 backend tests.
- **feat(timeline):** Revision Timeline component in right panel History tab. View past revisions read-only, add descriptions, mark notable, non-destructive rollback.

### Connections + Links
- **feat(connections):** Connections tab with outbound links, backlinks, and transclusion spans. Link delete (× button). Web link URLs visible.
- **feat(linkcreator):** LinkCreator wizard integrated into workspace for typed link creation between works.

### Critical Bug Fixes
- **fix(codec):** Trail publish/unpublish/update/listPublished wire ops were missing from codec.rs — requests silently failed with "missing payload." Added handlers for all 5 ops. This was the root cause of trail publish not persisting.
- **fix(compound-builder):** Source loading uses textRange (ensure_can_read) instead of crdt_sync_open (ensure_logged_in). Anonymous users can now load compound sources.
- **fix(router):** App.tsx simplified — removed pushState/replaceState override that caused session churn (101 sessions/sec).

### Other
- **feat(trails):** Trail publish/unpublish from workspace badge with error handling. Trails tab shows all trails (not filtered by current work).
- **feat(anon-warning):** Amber banner when browsing anonymously — "Sign in to save links, edits, and revisions."
- **feat(work_set_text):** New wire op for batch text setting (bypasses grab requirement). Used for concept seeding.
- **docs:** 8 design documents (FR-18 through FR-23, versioning design, cross-server resolution).
- **test:** 2438 backend tests (+19 revision, +65 graph scoring), 360 frontend tests.

---

## [v0.8.1] — 2026-06-30

### Federation Activation (FR-3) — cluster goes live
- **feat(federation): FR-3 activation layer** — outbound dialer with exponential backoff reconnect, client-side mutual handshake (Ed25519/X25519 + ChaCha20-Poly1305 AEAD), `PeerPool` for broadcast, periodic sync/heartbeat loop (30s heartbeat, 60s content+membership+state+endorsement sync), donated-host join initiator (`MembershipJoinRequest` after initial sync), and PBFT `GovernancePrePrepare` broadcast via `governance_tx` channel.
  - New module: `src/server/transport/federation_active.rs` (~550 lines).
  - Shared `process_federation_frame` extracted from inbound handler (all 30+ frame types) for reuse by outbound connections.
  - `--trusted-peer-key <hex>` CLI flag (repeatable) — fixes the `is_peer_known` reject-all trap.
  - `membership_bootstrap_init()` called at startup when federation enabled.
  - Server verifying key logged at startup for operator cross-registration.
  - Standalone mode unaffected: all new paths gated behind `federation_is_enabled()`.
- **test(federation):** Two real two-server integration tests (`federation_activation_content_replication_end_to_end`, `federation_activation_membership_converges`) — exercise the actual dialer, handshake, sync, and convergence. Pass in <1s.
- **fix(persist):** `RemoteOriginRegistry` used `HashMap<[u8;32], _>` which serde_json cannot serialize as JSON object keys — replaced derived `Serialize`/`Deserialize` with manual impls that convert to/from `Vec` of pairs. Fixes manifest checkpoint failures (`"key must be a string"`) seen in Docker cluster.

### Docker federation test bed
- **build(docker):** Multi-stage Dockerfile (Vite frontend + Rust release binary + debian:trixie-slim runtime). `docker-compose.yml` runs 3 full-node peers on a bridge network (ports 8081/8082/8083) with cross-registered verifying keys. Working end-to-end: Dracula.txt uploaded on peer1 appears on peer2 via federation sync.

### Documentation
- **docs:** Expanded `federation-activation.html` (196→693 lines) with PBFT introduction + 3-phase consensus diagram, broadcast/sync mechanism diagram, chunk replication flow diagram, failure & recovery scenarios (partition, crash, Byzantine, split-brain, slow node), scaling guide with O(n²) mesh analysis and bandwidth estimates, and problem checklist organized by cluster size (2–50+ nodes).
- **docs:** `index.html` Federation card now links to `federation-activation.html`.

---

## [v0.8.0] — 2026-06-29

### UI Redesign
- **feat(ui): AppShell redesign** — identity panel (username, club ID, public verifying key with copy, clubs-you-can-access, capped roster), ⌘K search overlay with title matching, library slide-out with hover tooltips (last-edited + revision count), transclusion fully ported into the shell (hold selection → place at cursor → markers/links).
- **fix(ui):** Identity-modal clipping, dark-on-dark text, duplicate link key warnings, read-only cursor styling.

### Backend
- **feat(backend):** `WorkListEntry.updated_at` (last revision timestamp), `club_verifying_key_hex` accessor, capped `club_roster` wire request. `ClubRoster` in wire protocol.
- **feat(verification): Email verification backend (FR-2 slice 1)** — `Club.email`/`verified` fields with manifest snapshot round-trip, `verification/` module (token store + `DevProvider` + `EmailProvider` trait), `/signup`, `/verify`, `/resend-verification` endpoints.
- **revert:** Dropped the edit-protection signing-key gate in `ensure_can_edit` (commit 01901728 broke ~93 tests). Will be re-introduced gated on `verified` status in FR-2 slice 4.

### Documentation
- **docs:** FR-1 (signature verification tool), FR-2 (account verification & edit gate), FR-3 (federation activation) functional requirement specs.
- **docs:** "Xudanu at a Glance" clickable architecture hero diagram on `index.html`.

---

## [v0.7.9] — 2026-06-22

### Archive / Soft-Delete (#25)
- feat(work): `is_archived` + append-only `lifecycle_history` on `Work` (Archived/Unarchived events with actor + timestamp).
- feat(web): Archive/Unarchive in the More menu + Archived Works restore panel + confirmation toast.
- feat(archive): ghost rendering — references into archived works show dashed amber markers + "Archived work" tooltip.
- New ops: `WorkArchive` (0x031C), `WorkUnarchive` (0x031D), `WorkListArchived` (0x031E).
- Persisted via both manifest `WorkEntry` and snapshot `WorkStateSnapshot`.

### Comparison & Merge Tools (#21, #29)
- feat(web): visual diff UI — word-level LCS diff with green/red highlights.
- feat(web): fuzzy/exact paragraph matching toggle (Jaccard word similarity).
- feat(web): three-way merge tool — paragraph-level conflict detection with sentence-level auto-merge, per-segment resolution (Accept A/B/Base), bulk accept-all, and "Create Merged Document" with curator provenance.
- fix(web): split panes now use full height (was fixed 300px).
- style(web): softened diff highlight colors.

### Persistent WebSocket (major UX fix)
- fix(ws): single WebSocket connection persists across document switches — was tearing down + reconnecting on every click, causing the two-click bug and transclusion race conditions.
- CrdtSyncClient.switchWork(): closes old CRDT channel + opens new on the same connection.
- fix(compound): reset spansRef on work switch + sync from server — prevents compound edition corruption.

### Provenance & Attribution
- feat(attribution): transclusion placer provenance (`transcluded_by`), always-initialized attribution log, derivation-chain ancestry view.
- test(attribution): 3 regression tests (toggle+history, permission, persistence).

### Security
- fix(deps): bump undici 7.25.0 → 7.28.0 (6 dependabot vulns).
- fix(security): sanitize WS message logging in embedded fallback UI.
- fix(ci): pin third-party GitHub Actions to commit SHAs.
- fix(security,quality): clear CodeQL rust/unused-variable + JS findings.
- CodeQL report: 0 open alerts.

### Documentation
- docs: CHANGELOG.md (v0.1.1 → v0.7.7 history).
- docs: comparison-and-merge-guide.md (walkthrough of all comparison tools).
- docs: attribution-updates.md (provenance mechanism documentation).
- 19 GitHub releases populated with complete release notes.
- 26 Udanax-Gold feature-gap issues filed with effort estimates.

---

## [Unreleased] — 2026-06-17 →
- **feat(attribution):** transclusion placer provenance (`transcluded_by`), an always-initialized (in-memory, with on-disk fallback) attribution log, and a derivation-chain ancestry view (`provenance_ancestry` + `enrich_provenance_hops`).
- **fix(security):** sanitize WebSocket message logging in the embedded fallback UI (CodeQL log-injection).
- **fix(ci):** pin third-party GitHub Actions to commit SHAs (CodeQL unpinned-action).
- **fix(deps):** bump undici 7.25.0 → 7.28.0 (6 dependabot vulns).
- **fix(security,quality):** clear CodeQL `rust/unused-variable` + JS findings; add regression tests for the three provenance fixes.

## [v0.7.7] — 2026-06-17
- fix(ci): multiline matrix output for `GITHUB_OUTPUT`.

## [v0.7.6] — 2026-06-17
- feat: manifest migration framework + federation compatibility window.
- feat: 1-byte format tag on all chunks (breaking on-disk format change).
- feat: WAL version header for forward-only migration.
- fix(gc): abort on collection errors; protect backup-history chunks.
- fix: edition codec roundtrip + JSON pagination params.
- fix: update vite 8.0.8 → 8.0.16 (GHSA-fx2h-pf6j-xcff, GHSA-v6wh-96g9-6wx3).

## [v0.7.5] — 2026-06-16
- Maintenance release.

## [v0.7.4] — 2026-06-16
- fix: persist transclusion links across restarts.
- fix: WAL journaling for link creation.

## [v0.7.3] — 2026-06-15
- Maintenance/bugfix release.

## [v0.7.2] — 2026-06-14
- fix: editing UX, auth flow, Windows WAL, unused-code cleanup.

## [v0.7.1] — 2026-06-14
- feat: live transclusion rendering via the `CompoundEdition` layer.
- feat: recursive compound resolution with cycle detection.
- feat: delta-based span migration; pre-push validation script.
- fix: resolve TypeScript errors that had blocked the v0.7.0 release.

## [v0.7.0] — 2026-06-12
- feat: stars, trails, document map, content similarity, hardened persistence.
- feat: Phase A+C hardened checkpoint + dual-manifest persistence; Phase B Write-Ahead Log (WAL) for zero-loss persistence.
- feat: preflight check + schema-tolerant checksum validation.
- feat: CRDT duplication fix, author attribution, version timeline, document navigation.
- fix: graceful shutdown with checkpoint wait; star persistence/flicker fixes.

## [v0.6.4] — 2026-06-08
- fix: resolve all TypeScript errors for release builds.

## [v0.6.3] — 2026-06-08
- fix: upgrade oauth2 4 → 5 (rustls-webpki vulnerabilities).
- fix: extend a short test password to satisfy CodeQL.

## [v0.6.2] — 2026-06-08
- fix: CI test passwords and TypeScript errors for release builds.

## [v0.6.1] — 2026-06-08 (includes v0.6.0)
- feat: v0.6.0 — cookie auth, annotations, O-tree merge, private documents.
- fix: source-work switching, scroll speed, canvas click-through.

## [v0.5.0] — 2026-06-07
- feat: backlinks, endorsements with persistence, revision browser, find-similar.
- feat: undo/redo, text-based compare, attribution span splitting.
- feat: OAuth2 (GitHub/Google), compare view, provenance widgets, read-first server endpoints.
- feat: automatic source detection and attribution on paste.
- feat: source-work read-only viewer with full provenance persistence; author persistence.
- feat: RwLock migration (concurrent reads via `with_server_ref`).

## [v0.4.3] — 2026-06-01
- fix: raise excerpt-match limit (120 → 4096 bytes) for transclusion markers.

## [v0.4.2] — 2026-06-01
- feat: Tier A features — backlinks, annotations, link context, pagination, awareness identity.
- fix: adapt frontend to paginated `work_list` / `link_list_for_work` responses.

## [v0.4.1] — 2026-06-01
- feat: build the React frontend and include it in release artifacts.
- fix: persistence docs and WebSocket protocol for HTTPS.

## [v0.4.0] — 2026-05-31
- feat: Phase H — compound documents with live span resolution.
- feat: Phase G — hover tooltips, click-to-navigate markers, backlinks sidebar.
- feat: Phase F — provenance chain ("golden thread") for transclusion ancestry.
- feat: Phase E — version DAG wire protocol, transitive ancestors/descendants, trace position.
- feat: Phase C — server-side excerpt positions; Phase B — content-type endorsement stamps.
- feat: historical-author system, source-work import, author browser.
- feat: transclusion UI with bidirectional links and margin markers.
- feat: run-length carrier (Phases 1/2/4) with coalescing and batched delta application.
- feat: `.xchunk` extension, rsync backup, artifact attestations, startup verification + fsync durability.
- release 0.3.0: panic hardening, UTF-8 safety, feature-status document.

## [v0.3.5] — 2026-05-26
- feat: content-addressed ChunkStore (Phases 1–6) replacing `server.json`; Manifest; chunk serialization.
- feat: yrs CRDT collaboration layer with federation sync; `work_revise_delta` real-time editing.
- feat: cryptographic author attribution with transparency log; multi-user per-author signing.
- feat: club identity, credentials, CSRF, security logging (rate-limited login, Argon2id, ChaCha20-Poly1305 AEAD).
- feat: collaborative editing UI with awareness indicators; attribution panel.
- feat: content-watch with Jaccard similarity.
- feat: LLM integration (GitHub Models Phase 6; OpenRouter), writing feedback, document sharing, ARM64 release build.
- feat: multi-user collaborative editing with per-author attribution (Phases 4/5).
- feat: O-tree three-way merge engine with position mapping.
- fix: persistence hardening (atomic key history, orphaned-chunk GC, mutex-poisoning resilience).

## [v0.1.1] — 2026-05-11
- feat: federation foundation (Phases 14–18) — types/identity/wire ops, server-to-server transport, content replication (G-Set CRDT + BLAKE3), DagWood reconciliation, cross-server transclusion.
- feat: trust & membership (Phase 19a) — web-of-trust join protocol, membership CRDT; governance & BFT (Phase 19b) — PBFT consensus.
- feat: crash-safe persistence (Phase 21) — checkpoint, grab timeout, health endpoint, structured logging; keypair/blobs/federation state survive restart.
- feat: modern encryption (Phase 12); endorsement authority validation + wire ops (Phase 13).
- feat: recorder/fossil/agenda system with admin monitoring (Phase 11).
- feat: transclusion queries + bundle stepper (Phases 8–10); shared-content mapping (Phase 9).
- feat: label system and identity unification (Phase 7).
- feat: Phases 1–6 — path navigation, snapshots, endorsements, mapping algebra, FeText, FeWrapper, club hierarchy.
- feat: BackfollowEngine — unified transclusion index (Phase A); endorsement stamps, H-tree edges, trail-based backfollow (Phase B); element-level comparison (Phase C); reactive recorder (Phase D); ENT version DAG (Phase E).
- feat: Rule 8 publication model — read-club-as-publication, read-permission gates, wire codec.
- feat: split-pane compare view with colored shared regions; grab-request queuing, federation CLI.
- feat: versioned snapshot data format with migration support.
- TLS tests, Caddy auth proxy, browser fixes.
- fix: transclusion backfollow work-club preservation; `find_text_transcluders` substring correctness.

## [core-ent] — 2026-04-18
- Initial core/entity foundations. Earliest commit history begins 2026-04-21.

---

### Versioning notes
- Patch releases on the same day (e.g. v0.6.1–v0.6.4, v0.4.1–v0.4.3) were typically quick follow-up fixes to get a clean release build.
- The v0.1.1 release encompassed the bulk of the foundational subsystem build (Phases 1–22).

---

## [v0.9.8] — 2026-07-20

### EPUB Import
- **feat(epub):** EPUB file import via `cli-epub-to-text` + `epub` crates. Server-side extraction of text + metadata (title, author) from EPUB OPF. New `import_epub` and `extract_epub` wire ops. Follows existing `import_source_work` pipeline for source work creation with full attribution.

### Revision History Persistence Fix (critical)
- **fix(checkpoint):** Revision history was lost on server restart because `mark_dirty()` cleared `chunk_ref` without preserving old history. Added `prev_chunk_history` field to `WorkState` — old chunk references are preserved through `mark_dirty()` and merged during checkpoint via new `work_to_chunks_with_history()`. Old revisions now survive restarts.

### Attribution Panel
- **feat(attribution):** Full `AttributionPanel` in workspace Provenance tab — coverage bar, derivation chains, signature validity, per-span timeline, author badges (historical/LLM/signed/unsigned). Security-critical view for verifying provenance.
- **fix:** `refreshAttribution()` now called on every work load (was missing in workspace).

### Persistent ID Fix
- **fix:** Persistent IDs now use server's Ed25519 verifying key hash when no `--public-address` is configured. Globally unique (like Tor onion addresses) instead of `localhost`.

### Mentions & Tags
- **feat:** 👤 Mention and 💡 Tag buttons in selection popover. Lookup-or-create-and-link pattern for Person/Concept works. Toast notifications.

### Trail Codec Fix (critical)
- **fix(codec):** `TrailPublish`, `TrailUnpublish`, `TrailUpdate`, `TrailListPublished`, `TrailListCategories` were missing from codec.rs — trail publish silently failed. All 5 ops now have proper JSON codec handlers.

### Other
- **feat:** Library sort dropdown (recently updated, title A-Z, most revisions, work ID)
- **feat:** Connections tab with links, backlinks, transclusions + delete
- **feat:** LinkCreator wizard in workspace
- **feat:** Anonymous warning banner
- **feat:** Bold/Italic buttons restored in selection popover
- **feat:** `work_set_text` wire op for batch text setting
- **fix:** CompoundBuilder uses `textRange` instead of `crdt_sync_open` (anonymous users can load sources)
- **test:** 2440 backend tests (+22 revision/history), 360 frontend tests
