# FR-160: MCP Read-Surface Batch — Four Tools, Both Paths

- **ID:** FR-160
- **Status:** Shipped (2026-11-07)
- **Parent:** FR-141 (Docuverse MCP server), FR-159 (agent skills)

## Problem

The MCP server exposed 19 read tools but none of them reached four pieces
of machinery that already existed as public server functions: per-work
licensing (FR-24), published trails (FR-37), the server directory (FR-6),
and federated search (FR-41 S1). An agent asked "what can I quote from
this work?" or "is this passage anywhere else on the network?" had no tool
to reach for.

## What shipped

Four read tools, each implemented on **both** docuverse paths so local
(data-dir) and remote (live WebSocket) MCP clients see identical shapes:

| Tool | Reads | Permission route |
|---|---|---|
| `get_license` | `work_license_get` — license id plus reuse guidance | `ensure_can_read` on the work |
| `read_trails` | `trail_list_published` — published trails only, optional category filter | published-by-construction (owner-private trails never appear) |
| `list_servers` | `server_directory().list()` — peers with trust/quarantine state | anonymous surface: directory metadata only, no content |
| `search_federated` | `federated_search` — local corpus + bloom-routed peer fan-out, signed responses | public works only; wire op rate-limits 10/min per session |

The remote arms translate to existing wire ops
(`work_license_get`, `trail_list_published`, `server_directory_list`,
`federated_search`) — no protocol changes, no new opcodes.

## Security notes

- Work-scoped tools enforce the same `ensure_can_read` gate as every other
  read; club-private works never leak to agents.
- `read_trails` returns published trails only — the anonymous-session
  surface, mirroring the wire op's design.
- `list_servers` exposes trust/quarantine metadata, which is public by
  design (the trust graph is how cross-server content gets vetted).
- `search_federated` inherits the wire op's per-session rate limit
(10/min) — fan-outs cost peers real work; the tool description states
the limit so agents don't hammer it.

## Verification

- 40 MCP lib tests green (4 new: license default + permission denial,
  trails/servers empty-server, federated local-merge).
- Live probe against `wss://xudanu.com` (2026-11-07): `read_trails`
  returned 2 published trails (The Curator's Tour, 10 stops; The Links
  Course, 6 stops); `list_servers` returned 0 (no `--peer` configured,
  correct); `search_federated "garden"` returned 1 local match carrying
  origin `server_id`/`server_name`.

## Follow-ups (next batches)

- **FR-161 (sketch): `find_transclusions`** — corpus-wide transclusion
  query over the backfollow index (by source work, by span, direct vs
  nested, paginated). Removes the per-work
  `search_works → who_transcluded` chain for reuse-graph questions.
- **FR-162 (sketch): read-delegation tokens** — mint/verify/revoke,
  delegated login op, structurally-empty authority set. Agents read as
  the user (club-private works included), writes stay anonymous-surface.
  Defense by construction: the token grants no mutation power at all.
