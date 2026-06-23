# Performance, Stability & Security Backlog

Scope: make the `xudanu` backend (Rust) and web frontend (Vite/React) suitable for
long uptimes with many concurrent users, and harden the frontend.

Status legend: `[ ]` todo · `[~]` in progress · `[x]` done

Risk: LOW / MED / HIGH (blast radius if it regresses the CRDT editing path)
Size: S / M / L
Deps: story should land after the listed stories.

---

## Test strategy (applies to every story)

Every fix ships with an automated test. No story is "done" until its test is green.

**Backend** (run from `original-code/xanadugold/src-rust/`):
```sh
cargo test --features server              # all tests
cargo test --features server <name>       # one test/test-module
cargo clippy --features server --all-targets
```
- Integration / WS behaviour: `tests/integration.rs`, `tests/ws_stress.rs` (real
  server + WS clients — the established model).
- Unit tests: inline `#[cfg(test)] mod tests` in the touched module.
- Restore integrity (checkpoint/manifest): extend `tests/integration.rs` +
  exercise `verify_store` after restart.
- LLM tests need a mock (the server hits Ollama/`src/server/ollama.rs`); gate
  real calls behind a configurable base URL and point tests at a stub, or assert
  the no-LLM-configured path.

**Frontend** (run from `web/app/`):
```sh
npm test          # vitest run
npm run build     # tsc -b + vite build (typecheck gate)
npm run lint
```
- Specs live in `web/app/src/__tests__/` (vitest + jsdom).
- Render-count assertions via `vi.fn()` spies on memoized children or
  `useReducer`/`useRef` counters to prove re-renders stopped.

---

## Performance measurement strategy (applies to every perf story)

**Principle:** no perf story lands blind. Record a **baseline** before, an
**after** measurement, and keep the benchmark in-tree so it regresses loudly.

**Backend (Rust) — criterion benchmarks**
- New `benches/` directory, criterion as a `server`-gated dev-dependency:
  `criterion = { version = "0.5", features = ["async_tokio", "html_reports"] }`.
- Run: `cargo bench --features server` (criterion writes HTML to
  `target/criterion/`). Compare runs: `cargo bench --features server -- --save-baseline <name>`
  then `--baseline <name>`.
- Shared harness: a bench helper that boots a `Server` in-memory, seeds known
  works/sessions, and exposes synchronous + async (`tokio`) entry points. Reuse
  the same WS-client machinery as `tests/ws_stress.rs`.
- Memory/leak stories (B1, B4): a long-running soak test that asserts collection
  sizes stay bounded (test, not bench).

**Frontend — render-count + timing**
- Vitest render-count spies (as above) for "did we stop re-rendering".
- A tiny `bench()` helper (`performance.now()` loop) in `src/__tests__/` for
  pure micro-benchmarks (e.g. TextBuffer edit throughput).
- Optional: React Profiler `onRender` capture in a test to assert commit times.

**Per-story evidence:** each perf story below lists a **Metric** and a target.
The story isn't done until: (a) tests green, (b) the metric improves vs the
recorded baseline by at least the stated factor, (c) the bench committed.

**Where results live:** paste baseline/after numbers into the PR description and
keep a running `docs/dev/perf-results.md` (created with the first perf story).

---

## B0 — Backend benchmark harness  `[ ]` · LOW · S · deps: none

**Goal:** provide the measurement infra all backend perf stories depend on.

**Scope:** add `criterion` dev-dep (server-gated); create `benches/` with a
shared `BenchState` (boot server, seed works/sessions) and seed benchmarks:
concurrent read-only ops, blob fetch, work_list vs work count, request latency
during checkpoint. Wire into `Cargo.toml` `[[bench]]` targets with
`required-features = ["server"]`, `harness = false`.

**Tests/accept:** `cargo bench --features server` runs and produces a baseline;
no behaviour change. Create `docs/dev/perf-results.md` with recorded baselines.

## F0 — Frontend benchmark helpers  `[ ]` · LOW · S · deps: none

**Goal:** provide FE measurement helpers.

**Scope:** add a `src/__tests__/bench.ts` with `time(fn, iters)` and a
`renderCount()` hook/spy util; add one example render-count test.

**Tests/accept:** helpers exist; example test green; used by F4/F5.

---

## Completed (record only — already built + tested green)

These transport fixes are done (release binary rebuilt; `cargo test --features server` passes):

- `[x]` **Duplicate op codes** — `WorkDiffNarration/WorkWritingFeedback/WorkBacklinks`
  reassigned to `0x0341/0x0342/0x0343` (`protocol.rs:403-405,682-684`). Fixes
  binary-client/federation round-trips; JSON (web) unaffected.
- `[x]` **`unreachable!` landmines** → `ServerError::Internal`
  (`dispatch.rs:2514-2523`).
- `[x]` **CSRF hardening** — `VecDeque`→`HashSet` (O(1)), cookie `Path=/`, added
  double-submit validation (`shared.rs:24,48`; `handler.rs:107-112,121,286-321`).
- `[x]` **WS idle timeout (90s)** — dead/half-open connections now close
  (`handler.rs:654-655,663,945-953`).

> Activation note: fixes take effect after the running server is restarted with
> the new binary. Op-code change is wire-incompatible for binary clients only
> (redeploy federation peers together).

---

## Backend stories

### B1 — Bound & prune unbounded in-memory maps  `[ ]` · LOW · S · deps: none

**Goal:** stop slow memory leaks over long uptimes.

**Scope:**
- `pending_content_notifications`: cap on push + drop notifications for fossils
  with no active subscriber (`server.rs:7692,7862`).
- `WorkState.revision_authors`: keep most-recent N per work (`server.rs:961`).
- `login_attempts`: prune entries whose window elapsed (`identity.rs:544`).

**Tests (automated):**
- Unit: push `>MAX` notifications for an unsubscribed fossil → collection size ≤ cap.
- Unit: perform many `revise_work` calls → `revision_authors.len()` ≤ N.
- Unit: advance time past the window with repeated failures → stale `login_attempts` removed.

**Accept:** no collection grows unbounded in a 1h soak; existing tests green.

---

### B2 — Gate LLM auto-title to WorkCreate only  `[ ]` · LOW · S · deps: none

**Goal:** stop `spawn_auto_title` firing on ClubCreate / EditionStore / etc.

**Scope:** trigger only on actual `WorkCreate` (check the op, not `ResponseValue::Id`)
(`dispatch.rs:48,2822-2857`).

**Tests:**
- Integration: create a club / store an edition with LLM configured (stubbed) →
  assert the auto-title task is **not** spawned (spy/counter).
- Integration: create a work → auto-title runs exactly once.

**Accept:** auto-title only on work creation; all other ops unchanged.

---

### B3 — Bound LLM op cost (timeout + concurrency)  `[ ]` · MED · S · deps: none

**Goal:** a few slow LLM calls can't starve tokio workers.

**Scope:** wrap the LLM HTTP call in `tokio::time::timeout`; gate global
concurrency with a `Semaphore` (e.g. 4) so excess calls queue
(`dispatch.rs:110-113,193-197`).

**Tests:**
- Integration (stubbed LLM that sleeps): narration returns within the timeout
  with a timeout error, not indefinitely.
- Concurrency: issue `>semaphore` concurrent narration requests against a
  counting stub → assert at most `semaphore` run at once.

**Accept:** LLM calls time out cleanly; worker pool not exhausted under burst.

---

### B4 — Prune disconnected sessions  `[ ]` · MED · M · deps: none

**Goal:** fix the `sessions` HashMap leak + keep `session_count()` O(1)-ish.

**Pre-check (blocker):** confirm attribution **snapshots** author data at write
time and does not resolve `session_id` lazily after disconnect. If it does,
keep a minimal tombstone instead of full removal.

**Scope:** `disconnect()` removes (or evicts expired-inactive) sessions
(`server.rs:399-461`). Add periodic eviction of `!connected && expired`.

**Tests:**
- `tests/ws_stress.rs`: connect N clients, disconnect all →
  `admin_active_sessions` reflects ~0; map stays bounded under churn.
- Integration: author a revision, disconnect, then query attribution → author
  display name/key still present (proves no attribution regression).

**Accept:** bounded sessions after churn; attribution history intact.

---

### B5 — Blocking blob/chunk I/O off the async runtime  `[ ]` · MED · M · deps: none

**Goal:** file I/O stops blocking the reactor and other clients.

**Scope:**
- `blob_get_handler`: read only the hash/path under the server lock; read file
  bytes via `tokio::fs`/`spawn_blocking` (`handler.rs:337-349`).
- Audit `chunk_store.rs:282-347` and `blob_store.rs:200-278` read paths; move
  blocking `std::fs` reads to `spawn_blocking`. Never hold the server lock
  across I/O.

**Tests:**
- Integration: store a large blob; while fetching it concurrently, fire rapid
  WS ops from another client → op latency stays under threshold (no stall).
- Integration: blob fetch returns correct bytes (hash-verified).

**Metric:** p99 latency of a concurrent WS op during a 10 MB blob fetch vs
no-fetch baseline. **Target:** ≤ 1.5× baseline (currently stalls ~serially).
**Accept:** large blob fetch doesn't stall other clients; correctness preserved.

---

### B6 — Non-blocking checkpoint  `[ ]` · MED-HIGH · L · deps: B5

**Goal:** the 5s autosave stops blocking all request dispatch.

**Scope:** collect the dirty chunk set under a brief write lock; release; then
serialize + `write_chunk_durable`/`sync_all` on `spawn_blocking`
(`xudanu-server.rs:707`; `server.rs:10502+`; `chunk_store.rs:296-310`).

**Tests:**
- Integration: drive heavy concurrent traffic; trigger checkpoint; assert
  per-request latency stays under threshold during the checkpoint.
- Integrity: checkpoint → kill → restart → `verify_store` OK and state identical
  to pre-checkpoint (extend the restore round-trip test).

**Metric:** median request latency during a checkpoint vs idle. **Target:** ≤ 1.5×
idle (currently dispatch is fully blocked for the checkpoint duration).
**Accept:** checkpoint no longer serializes all clients; manifest verifies clean.

---

### B7 — Read/write lock split in dispatch  `[ ]` · HIGH · L · deps: B6

**Goal:** read-only requests run concurrently (highest-leverage change).

**Scope:** route read-only dispatch arms through `with_server_ref` (read lock);
keep `with_server` (write lock) only for arms that mutate. The compiler enforces
this — any arm needing `&mut Server` fails to compile under a read lock
(`shared.rs:122-136`; `dispatch.rs:25-31`). Also restructure the 200ms
notification drain so it doesn't take the write lock per client (`handler.rs:634`).

**Tests:**
- `tests/ws_stress.rs`: add a deadlock-guard — many concurrent read-only ops
  (`work_list`, `work_get_edition`, `crdt_sync_full_state`) interleaved with a
  writer, wrapped in a hard timeout (must complete, not hang).
- Throughput: concurrent read-only ops finish materially faster than serial
  baseline (assertion on wall-clock for a fixed batch).
- Full suite + all 12 existing stress tests green.

**Metric:** throughput of 8 concurrent read-only ops (`work_list` /
`work_get_edition`). **Target:** ≥ 3× single-op throughput (currently ~1× — all
serialized by the write lock).
**Accept:** reads concurrent; no deadlocks; no correctness regressions.

---

### B8 — WorkList scaling (visibility index + pagination)  `[ ]` · MED · M · deps: B7

**Goal:** `work_list` stays fast as the work count grows.

**Scope:** maintain a per-authority visible-works index (or paginate before the
permission filter) instead of scanning all works + 3 lookups each
(`dispatch.rs:891-943`; `server.rs:3913-3950`).

**Tests:**
- Integration: seed 10k works across owners/permissions; assert `work_list`
  latency under threshold and results identical to the current implementation
  (golden-output comparison).
- Pagination: page through full set; union of pages == unpaginated result.

**Metric:** `work_list` latency at 1k vs 10k vs 50k works. **Target:** 10k/1k and
50k/1k ratios both ≤ 2 (currently ~linear, 10× from 1k→10k).
**Accept:** flat latency with work count; identical results.

---

## Frontend stories

### F1 — Resilient WS reconnect (backoff + jitter)  `[ ]` · LOW · S · deps: none

**Goal:** avoid thundering-herd reconnect on a backend outage.

**Scope:** exponential backoff (e.g. 1s→2s→4s…→cap 30s) + jitter, reset to base
on successful connect (`crdt_sync.ts:1365-1371`).

**Careful:** preserve all other reconnect semantics — CRDT sync must still
re-establish (`crdt_sync_open`/`full_state`) and `session_connect` must re-run.

**Tests (vitest, fake timers):**
- Simulate `onclose`; assert nth reconnect delay is within the backoff+jitter
  envelope for n=0..5.
- Assert a successful connect resets the delay to base.
- Assert an eventually-returning server is re-synced (CRDT `full_state` requested).

**Accept:** reconnect still works; backoff observable; sync resumption unchanged.

---

### F2 — WS-only authentication  `[ ]` · MED · S · deps: confirm intent

**Goal:** remove the redundant cleartext password POST; rely on WSS (TLS) for the
WS auth path.

**Scope:** drop the `/auth/login` POST; keep `session_login_by_name` over WS
(`useCrdtSync.ts:229-242`; `crdt_sync.ts:1001,1019`).

**Pre-check (blocker):** confirm the HTTP `xudanu_session` cookie isn't required
for OAuth auto-auth on the WS upgrade (`handler.rs:308-316`). If OAuth needs the
cookie, keep the HTTP path for OAuth **only** and remove it for password login.

**Tests:**
- Vitest: password login → assert WS `session_login_by_name` sent and **no**
  `/auth/login` POST made.
- OAuth: GitHub/Google flow still establishes the session cookie and auto-auths
  the WS (separate test).

**Accept:** single password auth path; login + OAuth both work.

---

### F3 — Stabilize editor callbacks (useCallback + listener)  `[ ]` · LOW · S · deps: none

**Goal:** restore `React.memo` effectiveness on the editors.

**Scope:** wrap `onSelectionChange` (and similar) in `useCallback`
(`WorkspacePage.tsx:1300-1304,1326-1330`); attach `selectionchange` once (ref or
stable handler) (`CollaborativeEditor.tsx:750-755`).

**Tests:**
- Vitest: render `VirtualizedEditor`/`CollaborativeEditor`; force a parent
  re-render with unchanged props → assert the memoized child render count does
  not increase.
- Vitest: type a character → assert the `document` `selectionchange` listener is
  not removed/re-added (count add/remove calls).

**Accept:** editors stop re-rendering on unrelated parent renders.

---

### F4 — Decouple sidebar from keystrokes (isolate text state)  `[ ]` · HIGH · M · deps: F3

**Goal:** typing doesn't re-run the sidebar's work/link/backlink filtering.

**Scope:** move editor text into its own context/provider (or a child
component) so `text` updates don't re-render `WorkspacePage`
(`useCrdtSync.ts:49,80`; `WorkspacePage.tsx:109,990-1238`).

**Careful (CRDT):** verify nothing in the sidebar/header legitimately depends on
live `text`; CRDT op generation (`crdt_sync`) must be untouched.

**Tests:**
- Vitest: type in the editor → assert the sidebar subtree render count does not
  increase (spy), while the editor still updates.
- Vitest: assert CRDT delta op generation is byte-identical before/after the
  refactor (feed the same keystroke sequence, compare emitted ops).

**Metric:** sidebar React commits per keystroke (Profiler `onRender` count).
**Target:** 0 (currently ≥ 1 per keystroke).
**Accept:** typing doesn't re-render the sidebar; CRDT behaviour unchanged.

---

### F5 — Incremental TextBuffer line-offset updates  `[ ]` · HIGH · M · deps: none

**Goal:** stop rebuilding the whole line-offset table per keystroke.

**Scope:** apply edits incrementally to the offset table instead of full rescan
(`text_buffer.ts:16-24`; `CollaborativeEditor.tsx:381`; `VirtualizedEditor.tsx:172`).

**Careful (CRDT):** this is **rendering-only**. CRDT delta generation
(`crdt_sync.ts`) must not change — it computes deltas independently of
`TextBuffer`. Keep the public `TextBuffer` API identical.

**Tests:**
- Vitest property test: random edit sequences → incremental line-offsets ==
  full-rebuild reference (equivalence).
- Vitest: large doc (~100k chars), type at end → assert no full O(n) rescan
  (e.g. spy on the scan, or assert sub-linear time).
- Vitest: CRDT ops emitted for a given edit are identical before/after.

**Metric:** per-edit cost on a 100k-char doc (insert at end). **Target:** O(edit
size), ≥ 20× faster than full rebuild (currently O(doc) per keystroke).
**Accept:** large-doc typing stays cheap; CRDT deltas unchanged; offsets correct.

---

### F6 — Tame background polling  `[ ]` · LOW-MED · M · deps: none

**Goal:** background work stops re-rendering mid-typing.

**Scope:**
- Pause `loadWorks` 5s polling while typing / window blurred; resume on idle
  (`WorkspacePage.tsx:296-300`).
- Batch endorsements (single request) or derive from `work_list`; stop the N+1
  waterfall re-running each poll (`WorkspacePage.tsx:193-216`).
- Drop `awareness.length` from the awareness-refresh effect deps to break the
  self-perpetuating loop (`WorkspacePage.tsx:426-431`).

**Tests:**
- Vitest: while typing, assert `loadWorks` fetch is not fired; on idle it resumes.
- Vitest: list of N works → exactly one (batched) endorsements request, not N.
- Vitest: awareness effect schedules exactly one refresh per mount, not a loop
  (assert timer count with fake timers).

**Accept:** no mid-typing re-renders from background work; data still refreshes.

---

## Recommended execution order

0. **Measurement harness first:** B0, F0 (so every later perf story records a
   baseline before changing code)
1. **Safe quick wins:** B1, B2, B3, F3, F1, F6
2. **Careful backend mem/IO:** B4, B5
3. **Backend concurrency core:** B6 → B7 → B8 (re-measure each vs baseline)
4. **CRDT-careful frontend:** F4, F5 (extra test focus; do after F3)
5. **Confirm & do:** F2 (after the OAuth cookie pre-check)

Run `cargo test --features server` after every backend story and
`npm test` + `npm run build` after every frontend story. For perf stories also
run `cargo bench --features server` (or the FE bench) before **and** after, and
paste baseline/after into `docs/dev/perf-results.md`. Commit one story per
PR-sized change.
