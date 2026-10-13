# Web Coverage Plan — 80% lines

**Status:** Phase 1 in progress (October 2026)
**Goal:** 80% line coverage on `web/app/src` — safely: behavior
assertions on real code, never coverage-chasing mocks.
**Measurement:** `npm test -- --coverage` (vitest, v8 provider).

## Baseline (2026-10-04, measured)

| Metric | Value |
|---|---|
| Lines | **20.7%** (2,700 / 13,019) |
| Branches | 17.5% |
| Functions | 16.5% |
| Files under 80% | 75 of 111 |

**Measurement bug, fixed:** v8 coverage counted only files *loaded*
by tests — 129 files / ~33.8k lines were invisible, flattering the
old number (42.7% over 52 loaded files). `vite.config.ts` now
includes all of `src/` (tests and boot excluded) and gates with
thresholds that ratchet per phase (currently floored at the
baseline: lines 20 / functions 16 / branches 17).

Reaching 80% = covering ~7,700 more lines.

## The gap, ranked by uncovered-line mass

| Uncovered | File | Risk if broken |
|---|---|---|
| 2,422 | components/workspace/WorkspaceShell.tsx | the whole app surface |
| 1,555 | components/CollaborativeEditor.tsx | editing, CRDT flush, markers |
| 833 | api/crdt_sync.ts | every server op the UI makes |
| 496 | components/VirtualizedEditor.tsx | large-doc rendering |
| 380 | hooks/useCrdtSync.ts | sync lifecycle |
| 275 | components/ComparePanel.tsx | revision integrity UI |
| 230 | components/CompoundBuilder.tsx | compound docs |
| 208 | components/AdminDashboard.tsx | admin ops |
| 205 | components/ProvenanceWidgets.tsx | provenance display |
| ~2,400 | 30+ more files at 0-60% | see coverage report |

## Phases

### Phase 1 — data layer & pure logic (target ≥35%)
`api/crdt_sync.ts` via the house pattern (override `sendRequest`,
assert op/payload/response-extraction per method — real bodies run),
then `offline-cache.ts`, `exhibition.ts`, `editor-dom-utils.ts`,
`work-store.ts`, `types/api.ts` helpers, remaining pure modules
(`text-diff`, `outline`, `overlay-canvas`, `prov-validator`,
`reuse-suggestions`, `split-authoring`, `argument-*`, `concepts-seed`).
**Why first:** every UI test after this reuses these fixtures/mocks;
pure logic has the highest assertion-value per line.

### Phase 2 — editor heart (target ≥50%)
`CollaborativeEditor` + `VirtualizedEditor` + `RemoteCursors` +
`EditableSpan` + `editor-dom-utils` remainder. Build one harness:
jsdom render with a mocked CRDT client + fixture document; cover
typing, marker rendering, permission states, CRDT flush, awareness.
`useCrdtSync` hook tests ride the same harness.

### Phase 3 — WorkspaceShell (target ≥64%)
Not one blob test: render the shell with the mocked client and drive
the real surfaces — link/type/endorser filters (FR-87), panels,
navigation, comment-on-link, open-link completion. Extract further
logic into hooks where a surface is untestable.

### Phase 4 — panels (target ≥80%)
Compare/Merge/ThreeWay (revision integrity first), CompoundBuilder,
MultiEndCompare, Trails, Import/Export, Admin, Provenance widgets,
Search surfaces, Identity/Origin/Directory remainder, the 0%
small components. Shared render-fixture harness from Phase 2.

## Safety rules

1. **Mock the transport, never the logic under test** — the
   `sendRequest`-override pattern runs real method bodies.
2. Assert *behavior* (payload shapes, unwrapping, fallbacks, error
   paths), not implementation details or snapshots.
3. Data-integrity surfaces (revision, merge, compare, transclusion)
   get negative tests: malformed responses, permission denials,
   empty payload fallbacks.
4. The ratchet only rises. A PR cannot lower the floor.
5. Coverage is the floor, not the goal — a test that asserts
   nothing but covers lines is deleted on review.

## Excluded from gates (defensible)

`src/__tests__/**`, `setupTests.ts`, `main.tsx` (boot), `globals.d.ts`.
E2E (Playwright) remains the check for cross-layer flows and does
not count toward these numbers.

## Progress log

- 2026-10-04: baseline measured, honest includes + ratchet in
  `vite.config.ts`; Phase 1 started (`crdt-sync-client.test.ts`).
- 2026-10-04 (2): Phase 1 modules landed — `exhibition.ts` 17→96%,
  `offline-cache.ts` 20→92% (fake-indexeddb; eviction/LRU/over-budget
  covered), `store/work-store.ts` 0→95%, `editor-dom-utils.test.ts`
  added, `crdt_sync.ts` 25→46% (45 tests; found + fixed a null-crash
  in `workTextAtRevision`). Total 20.1→23.8% lines; ratchet floor
  raised to 23/21/19. Type-only `src/types/**` excluded from the
  denominator. Next: remaining pure modules
  (`text-diff`, `outline`, `overlay-canvas`, `prov-validator`,
  `reuse-suggestions`, `split-authoring`, `argument-*`,
  `concepts-seed`, `llm-proposals`), then the WS/reconnect machinery
  in Phase 2.
- 2026-10-04 (3): Phase 2 opened with the sync layer —
  `hooks/useCrdtSync.ts` 0→86% (37 tests). Covered: the 3s
  disconnect grace window (no flicker on blips), reconnect attempt
  surfacing/reset, the 2s poll, work switching + late-auth retry for
  denied private works, per-work state resets, denial precision,
  deferred identity/stats/permissions, logout authority teardown,
  annotation optimistic-update + revert, login/ticket caching,
  share/unshare club flow, LLM wrapper error shapes, and the
  attribution resolved→plain fallback (the silent-empty bug class).
  Total 23.8→26.3% lines; ratchet floor 26/23/21.
- 2026-10-04 (4): CollaborativeEditor harness shipped (10 tests):
  canvas/ResizeObserver/IntersectionObserver/rAF stubs; render modes
  (read-only denial, contenteditable activation on pointerdown,
  remote-update rebuild), typing→onTextChange round-trip (echo-guard,
  leading-newline strip, lone-newline=empty), and the debounced
  undo/redo stack. CollaborativeEditor 3.2→23.8% (mount surface);
  total 26.3→28.8%; ratchet 28/25/22. FINDING (documented in test):
  the undo debounce collapses a fast burst to the LAST pre-keystroke
  state — the pre-burst text is unreachable via ctrl+z; burst-start
  collapse was likely the intent. Next: VirtualizedEditor windowing,
  then marker overlay interactions.
- 2026-10-04 (5): VirtualizedEditor windowing pinned (9 tests):
  scroll-math windows + spacer sizing, end-clamping, the STITCHING
  GUARD (edits in initial and scrolled windows land at exactly the
  right line; everything else byte-identical), echo-guard, windowed
  undo, read-only, #L deep-links. VirtualizedEditor 0→43%; total
  28.8→30.2%; ratchet 30/25/23. FINDING (flagged in test): handleInput
  stitches `prefix + visible + suffix` with NO guard that the
  visible slice keeps its trailing newline — real typing preserves
  it, but a DOM state that loses it silently CONCATENATES the
  window's last line with the first off-screen line in the saved
  document. Suggested hardening: assert the boundary newline before
  stitching.
- 2026-10-04 (6): marker-overlay interactions (7 tests) via
  deterministic geometry stubs (Range.getClientRects = 10px/char,
  all elements at origin). Covered: gutter-zone click navigation
  (outgoing left / incoming right — the zones are margin bars, not
  text), jump-target preference (work+span travel together),
  double-click → backlinks (e.detail contract), text clicks do NOT
  navigate, hover→tooltip (300ms) + leave-hide (2000ms), pin on
  click + Escape unpin, annotation zones override markers, density
  pills (≥5 overlapping) collapse→expand→individual. NOTE for
  future tests: fireEvent.click defaults detail:0 — the component
  branches on detail 1/2. CollaborativeEditor 23.8→43.8%; total
  30.2→32.6%; ratchet 32/26/25.
- 2026-10-05: Phase 3 opened — WorkspaceShell boots end-to-end
  through the wire-client seam (module mock + fallback Proxy for
  methods the fixture doesn't define; note: the LIVE shell is
  components/workspace/WorkspaceShell.tsx — App.tsx renders it; the
  old components/shell/ generation is dead except SearchOverlay,
  which the new shell reuses). First surface: FR-87 end-to-end —
  the endorser filter over real panel rows (any-vouch, specific
  club, reset), the Links tab gating, and the reader vouch toggle
  (link_endorse with the right id + panel reload). The shell mount
  alone lights up the whole tree: total 32.6→38.5% lines;
  WorkspaceShell 0→25%; ratchet 38/31/31.
- 2026-10-05 (2): shell data operations (5 more flows): comment-on-
  link asserts the full FR-40 S7 sequence (work_create → linkCreate →
  link_set_types [Comment] → Connection end attachment to the
  commented link; composer closes on success — note it renders in
  the DOCUMENT column, not the panel); open-link completion (FR-71)
  issues link_add_end RightEnd with the new work; Reference chip
  filters/toggles; delete asks confirm then link_deletes; retype
  issues link_set_types. WorkspaceShell 25→29%; total 38.5→39.2%;
  ratchet 39/31/31. Remaining shell surfaces: provenance panel,
  trails, import/export, admin.
- 2026-10-05 (3): the WebSocket engine (crdt_sync.ts 543-945 block)
  — 12 tests over a FakeWebSocket + controllable csrf fetch:
  anonymous handshake sequence (session_connect → who_am_i →
  login_public → crdt_sync_open → awareness_get), csrf-tokened URL,
  id-correlation with per-frame error rejects, closed-socket
  immediate rejects, connection-drop fails all pending, the
  reconnect table (consecutive failures escalate [200,500,1000] then
  exponential 4000±25%; SUCCESSFUL open resets the table — the test
  initially conflated the two), disconnect-never-resurrects, the
  generation guard against the stranded-connect bug (disconnect
  during csrf fetch abandons the open AND unlocks connect()),
  20s heartbeat, crdt_text_update event application with the echo
  window, and the delta/save-state machine (retain/insert ops,
  saving→saved→idle, failed ordinary delta ROLLS BACK, saveState
  error). crdt_sync.ts 47→57%; total 39.2→40.2%; ratchet 40/32/33.
  The lost-edits surface (sync layer + wire engine + editors) is now
  fully covered. Next round candidates: ComparePanel+ThreeWay+
  MergePanel (revision integrity UI), then the 0% panels batch.
- 2026-10-05 (stability): intermittent single-test failures under
  `--coverage` (≈1 run in 3) diagnosed: always "Test timed out in
  5000ms" on the heaviest full-shell boots — real-time budget
  exhaustion under instrumentation load (2-3× slowdown), not a logic
  race. Fix: per-file `vi.setConfig({ testTimeout: 20000 })` for
  workspace-shell-links (the WS backoff tests already had 20s
  per-test). Lesson for future integration tests: fake timers
  advance instantly, but every act() chunk costs real CPU — size
  per-test REAL budgets for instrumented runs, not dev runs.
  Verified: 4/4 consecutive clean coverage runs, 1,167/1,167.
- 2026-10-05 (4): revision-integrity surfaces (11 tests): pure
  highlightRegions/wordSimilarity; useCompare document path (server
  regions + edition load, findSharedRegions fallback, self-compare
  no-op, mode-switch clears), revision path (fuzzy catches
  paraphrase: "new"/"old second paragraph" scores 0.5 ≥ 0.35 — both
  paragraphs match); MergePanel 90% — clean divergence classified
  (A-only/B-only/0 conflicts), conflict defaults to A with B
  rewrites the MERGED PREVIEW (panes keep both sides), workMerge
  called with (base,A,B) → onMerged, refused merge surfaces the
  server error. HARNESS LESSONS (in-test): the WorkPicker closes on
  a 150ms BLUR timeout (fireEvent.focus never blurs siblings in
  jsdom — blur explicitly + settle); a single-entry dropdown's
  LIST div textContent equals its row (match no-nested-div, exact).
  ComparePanel 17→48%, ThreeWayDiffPanel 0→28%, MergePanel 0→90%.
  Total 40.2→42.2%; ratchet 42/34/34; 1,178 tests.
- 2026-10-05 (5): every right-panel TAB through the shell harness
  (7 tests, one boot + one fixture set): Attribution (authorship
  summary, span/author counts, log chain), Map (graph nodes with
  endorsement state — the map surface already speaks FR-87), Trails
  (mine + published, stop notes, per-work stop counts), History
  (RevisionTimeline: notable marks, rollback, FR-59 compare),
  Servers (directory: peer address + trust controls), Compare
  (empty-state contract), More (detectors — Miller's fourth
  fundamental). Total 42.2→43.4%; WorkspaceShell 29→30%;
  RevisionTimeline 0→45%, ServerDirectoryPanel →61%; ratchet
  43/35/37; 1,185 tests.
- 2026-10-05 (6): dead-code deletion + outline surfaces. FINDING:
  DocumentMapPanel.tsx (165 lines, 0 mounts) was the PRE-ARGUMENT-MAP
  graph view — NOT the outline feature — deleted after verifying zero
  references. The outline feature lives separately (outline.ts 100%,
  left-rail DocumentOutlinePanel, editors' OutlinePanel). New tests:
  TrailsPanel full overlay via Manage (names render, closes);
  left-rail Outline renders markdown headings from live text;
  editor outline sidebar toggle→entries→close. TrailsPanel 0→31%,
  DocumentOutline 0→63%, OutlinePanel 0→30%. Total 43.4→44.7%
  (denominator shrank by the deletion); ratchet 44/38/36; 1,188
  tests.
- 2026-10-05 (7): deep surfaces — ImportWizard (welcome-page event
  opens the paste step; .wizard-close closes) and AdminDashboard
  (31→40%: admin-gated mount, health metrics render, Audit tab's
  on-demand tail via Load / refresh shows the tamper-evident lines).
  HARNESS NOTES: AdminDashboard ALWAYS mounts (display:none wrapper)
  and its overview polls /health — a stub missing `operations`
  crashed the whole render tree at boot; getIsAdmin() on the fake
  gates the admin button. OPEN MYSTERY (documented, deferred): the
  doc-column tail (Where-is-this-used? / Provenance-chain Trace
  sections, WorkspaceShell ~6505-6602) does NOT render in the
  harness despite canEdit=true (the + Add Link canEdit-gate renders)
  —   its enclosing JSX nesting resists mapping; needs a focused
  archaeology pass or a component extraction. Total 44.7→45.2%;
  ratchet 45/38/37; 1,190 tests.
- 2026-10-05 (8) PROVENANCE AUDIT — two shipping bugs found and
  fixed, one self-inflicted incident:
  (1) THE PROVENANCE UI WAS INVISIBLE: the annotation modal's
  conditional was missing its closing `</div>)}` — "Where is this
  used?" AND the Provenance-chain Trace section were swallowed
  into the modal's gate, rendering only while composing an
  annotation. Fixed surgically (close after the modal; remove the
  duplicate close). REGRESSION TEST added.
  (2) WHOLE-DOC TRACE ALWAYS EMPTY: the Trace button called
  workTransclusionChain(work, 0, 0) — the server's span test
  (entry_start < end && entry_end > start) matches NOTHING at
  (0,0), so Trace always reported "original content" even for
  transcluded works. Fixed to (0, text.length); wire payload
  asserted in the test.
  (3) INCIDENT (self-inflicted, disclosed): a `git checkout --`
  during marker cleanup reverted UNCOMMITTED session work — the
  FR-87 endorser UI (select, vouch toggle, backlink badges) was
  wiped from WorkspaceShell. Fully restored from session history;
  all 1,193 tests green. LESSON: never `git checkout --` on files
  carrying uncommitted session work; commit feature work before
  debugging in the same file.
  Audit leftovers for next round: prov-validator.ts (154 lines, 0%)
  — the FORENSIC VERIFICATION CORE untested; ProvenanceWidgets
  (alive via ReadingView, 0%); docMode has no setter (dead "layout"
  branch). Total 45.3%; ratchet 45/38/37; 1,193 tests.
