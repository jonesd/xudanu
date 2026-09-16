# FR-69 — Connection resilience and recovery (release blocker)

Status: TOP PRIORITY. No release until every scenario below passes.

Written 2026-09-16 after a session in which the user hit "Connection
lost — reconnecting (attempt 105)" against servers that were, at
various points, healthy. The system cannot ship fragile.

## The honest failure taxonomy (observed 2026-09-16)

| # | Failure | Observed behavior | Root cause class |
|---|---|---|---|
| 1 | Backend restart (dev) | all WS drop; client shows Connection lost | expected — recovery is the question |
| 2 | Vite dev server dies | silent death, no crash log; tab retries into void | dev tooling |
| 3 | Vite ws-proxy after backend restart | proxy can strand; fresh page required | dev tooling |
| 4 | Client reconnect vs dead frontend | attempt counter climbs forever | no liveness distinction |
| 5 | Client reconnect vs backend restart alone | NEVER CLEANLY TESTED — masked by 2/3 every time | unknown — test first |
| 6 | Operator (AI) scripted restarts | bad paths, permission bits, timeouts killing servers | orchestration |

Server-side recovery is PROVEN: every kill/restart tonight restored
fully (WAL replay, checkpoints, 1292 session tickets, zero data
loss, 3507 tests green). The Rust server is not the weak link.

## Deployment fix (do first)

Single-process mode for all usage sessions: `xudanu-server run
<addr> <dir> --static-dir <built-dist>`. One process, no Vite, no
proxy — failure classes 2/3/6 collapse to class 1. Dev keeps Vite
for HMR only. scripts/restart.sh gains a `--single` mode.

## Stress harness — scripts/stress-connection.mjs

Failure injection + assertions, runnable against a scratch data dir
(NEVER the user's data). Every scenario has a hard acceptance
criterion; the harness exits nonzero on any failure.

| Scenario | Injection | Accept (all must hold) |
|---|---|---|
| S1 backend bounce | kill 10s, restart | client reconnects ≤ 30s of recovery, banner clears, no user action |
| S2 long outage | kill 120s, restart | same; offline mirror served during outage; edits made offline PUSH on reconnect, no loss |
| S3 rapid cycling | kill/restart x5 at 10s intervals | client converges within 30s of final recovery; server restore verifies clean each cycle |
| S4 many clients | 20 concurrent pages, kill/restart | all 20 heal; server RSS stable ±10% across 10 cycles |
| S5 mid-write kill | SIGKILL during rapid edit stream | WAL replays; every acknowledged edit survives; verify passes |
| S6 session ticket | restart, then identity still valid | no forced re-login; tickets restore (already observed: 1292 restored) |
| S7 CSRF rotation | restart issues new tokens | client refetches per attempt (code says yes — prove it) |
| S8 stale page | page open across S1-S3 | heals without reload — THE attempt-105 case |

## Client hardening (TypeScript — the actual weak link)

1. **Liveness-aware banner**: distinguish "backend down" from
   "frontend dead" (fetch /health alongside WS retry); never show
   "reconnecting" against a dead frontend — say reload needed.
2. **Reconnect audit**: guards (`connecting`, `disposed`,
   `generation`) — the code documents a historical stuck-guard bug;
   add a test that 100 sequential connect/fail cycles never wedge.
3. **Offline edit queue**: edits made during outage must flush on
   reconnect (reconnect-push logic exists — S2 proves or breaks it).
4. **Attempt cap UX**: after N failures, offer "Reload" prominently
   instead of counting forever.
5. **Heartbeat**: exists — verify stale-connection detection fires
   within its interval (timing).

## Memory, timing, concurrency

- Memory: server RSS logged per S4 cycle (trend must be flat);
  client heap via playwright metrics across a 30-min soak.
- Timing: reconnect backoff curve (200/500/1000…cap 30s) — assert
  the schedule; heartbeat interval vs detection time.
- Concurrency: S4/S5 cover multi-client editing under failure; add
  a lock-contention smoke (two editors, same span, kill/restart
  mid-merge; converge, no divergence).

## Rust vs TypeScript (the user's question, answered)

The server (Rust) proved the STRONGEST component tonight — perfect
restore through every abuse. The fragility lives in: dev
orchestration (fix: single-process mode), and the client's
recovery UX (fix: hardening list). TypeScript is not inherently
unreliable here; its reconnect logic is simply untested against
injected failure — which the harness fixes.

## Deliverables

1. scripts/stress-connection.mjs with S1-S8, exit codes, report
2. restart.sh --single (usage mode)
3. Client hardening items 1-4, each with a scenario proving it
4. A nightly-runnable report (pass/fail per scenario + RSS graph)
