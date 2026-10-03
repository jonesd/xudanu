# FR-141: Docuverse MCP Server — Agents as First-Class Readers and Authors

Status: Shipped — all four phases, plus live-server transport.
Phase 1 (read-only tools, stdio JSON-RPC, xudanu://work URIs).
Phase 2 (create_work / transclude / create_link / revise /
compare_versions behind --enable-agent-writes, AuthorType::Llm stamped
with --llm-model). Phase 3 (watch_work / detector_events /
detector_ack / unwatch_work — FR-80 loop live). Phase 4 (verify_work
tool + xudanu-verify binary: chunk store, chained logs, key rotation,
per-work provenance + transclusion drift, root-chunk and legacy
formats).
Transport: data-dir mode (in-process restore, exit checkpoint flush)
and --server ws://host:port live mode (mcp_ws.rs — v2 JSON WebSocket
with CSRF + origin handling, event-skipping response correlation;
verified against a production-configured running server). tests/mcp_ws.rs
boots a real Axum server and round-trips read AND write tool sets
including detector firing.

Bugs found while shipping (fixed):
- FR-80 link detectors never fired on link creation (only on
  set_types) — the HyperLink::make creation path bypassed the hook;
  both create paths now fire.
- FR-80 fire_link used HashMap iteration order for `acting_work`,
  making the self-watch suppression nondeterministic; now
  deterministically the LeftEnd origin.
- WAL work_create entries carried text only — crash-before-checkpoint
  permanently lost span provenance (and element structure); entries
  now carry the full EditionSnapshot, replay prefers it, legacy
  text-only entries still replay.
- xudanu-mcp flushes a checkpoint on stdin EOF in data-dir mode —
  throttled auto_checkpoint could otherwise leave agent writes WAL-only.
- Drift verification uses the pinned-revision original text for
  relocation-heal checks, not the current-range excerpt.

Tests: 32 unit (server::mcp) + 2 live-server integration (tests/mcp_ws.rs).
Dependencies: none new (builds on existing transport dispatch, clubs/sessions, provenance, transclusion, detectors)
Sibling arcs: FR-80 (detectors), FR-76 (eviction), FR-34 (recorder/backfollow), FR-24 (licensing)

## Why

Xudanu's hardest sell is "change how you write." Agents do not have that
inertia. Every Claude / opencode / Cursor session currently works over
context windows full of pasted, provenance-free text. An MCP (Model
Context Protocol) server exposing the docuverse turns the running system
into an agent's tool source: agents read works, quote via transclusion,
attach commentary via extrinsic links, follow backlinks, and watch
detectors — with every action flowing through the same clubs,
signatures, and provenance chain as human users.

This is also the distribution wedge that needs no full stack: the agent
host IS the frontend.

Primary story (read-only first): an agent answers "what criticizes this
passage?" with real backlinks instead of guessing, and every verbatim
quotation it emits is a transclusion whose source is verifiable by
construction. Pitch phrase for external use: **verified quotation
provenance** (do not promise "cannot hallucinate" — this guarantees
fabricated sources are impossible when quoting via transclusion; it does
not police paraphrase or argument).

Nelson alignment: Rule 7 (links visible from all endpoints — for agents
too), Rule 3 (every user uniquely identified — agents are club members
with keys), the Miller "Open Society" accountability model applied to AI
actors: no official truths, only who said what — including software
agents.

## Scope guardrails

- No new core semantics. MCP is an adapter layer over existing wire
  operations and server methods.
- Agents authenticate through the existing club/session model. An agent
  session is a session; permissions are enforced exactly as for humans.
- Read-only tools ship first. Mutation tools (Phase 2) are opt-in per
  server, per-club.
- The MCP surface must not bypass `ensure_*` permission checks or the
  wire-op validation path.

## Architecture

One new binary `xudanu-mcp` (stdio transport, standard MCP JSON-RPC)
plus a small `src/server/mcp/` module in the library. stdio keeps
deployment trivial: the agent host spawns the process; no HTTP surface
to harden. A `--http` mode for remote/shared docuverse instances is
deferred to Phase 3.

```
agent host (opencode/Claude/Cursor)
    |  MCP JSON-RPC over stdio
xudanu-mcp binary
    |  internal calls into library (same Server methods the wire
    |  dispatch uses — not raw struct access)
Server (clubs, sessions, provenance, transclusion, detectors)
```

Key decision: the MCP layer calls the SAME server methods that
`transport/dispatch.rs` calls for the WebSocket/HTTP path, so
permissions, validation, provenance stamping, and span migration behave
identically for agents and humans. Where dispatch logic is nontrivial
it should be lifted into shared server methods rather than duplicated.

## Phase 1 — Read-only tools (the demo milestone)

| Tool | Backing (existing) | Notes |
|---|---|---|
| `search_works` | search/dispatch text search | paginated; returns ids + titles + snippets |
| `read_work` | work read + resolve_inline_transclusions | resolved text, span ranges, provenance summary |
| `read_span` | raw range read with nesting | exact slice + source provenance |
| `find_backlinks` | list_links_for_work + link query | bidirectional visibility |
| `who_transcluded` | find_transcluders_for_session | content reuse graph; answer to "what reuses this?" |
| `get_prov` | provenance export | PROV-JSON for a work/span incl. signatures |
| `get_version_info` | revision history summary | count, times, revisers |

Tool results include a `xudanu://work/<id>#span=<s>,<e>` reference in
tool-result metadata so downstream tool calls (and humans reading the
transcript) can address exactly what the agent saw.

Phase 1 acceptance: an agent, given only these tools against a seeded
docuverse, answers "what is the best argument against passage X" by
following real backlinks and returns quotations as span references —
zero free-text quotation of docuverse content that is not backed by a
`read_span` result.

## Phase 2 — Quotation by transclusion + commentary by link

| Tool | Backing | Notes |
|---|---|---|
| `create_work` | create_work | agent-authored documents |
| `transclude` | element_insert / transclusion placement | the core primitive: quote = live window onto source, hash-pinned, drift-detected |
| `create_link` | create_link | extrinsic commentary: link end-sets, typed (Comment/Reference/Disagreement) |
| `revise` | work_revise via element list | edits carry provenance; LLM author type |
| `compare_versions` | shared_region / content diff | differential reading support |

Agent authorship identity: the agent's club carries the signing key; the
provenance `AuthorType::Llm` already exists and must be stamped with the
model/host identity (see `hg_profile` LLM fields) so spans are
attributable to a specific agent, not "an AI".

Acceptance: a brief/memo drafted by an agent where every quotation is a
transclusion; clicking any quote in the UI shows source, span, author
signature, and drift status if the source was later edited. The
"demonstrable motion brief" demo for the legal/traceability pitch.

## Phase 3 — Detectors and the WidgetPerfect loop

| Tool | Backing | Notes |
|---|---|---|
| `watch_work` | FR-80 detector plant | link + revision detectors |
| `detector_events` | detector poll/read | agent-side notification loop |

This makes Ruth/John from the WidgetPerfect saga agents: "watch this
spec; when a requirement link lands on my section, update the affected
plans and tell me what changed" — differential reading via
`compare_versions`.

Async shape: MCP tools are request/response; long-lived notification is
the agent host's job. `detector_events` is a poll; the demo loop polls
on a timer. (A push variant can ride stdio notifications later; do not
block Phase 3 on it.)

## Phase 4 — Verification kit (separate but coupled)

Standalone verifier (CLI + static web page) for: provenance signatures,
transclusion content hashes, PROV-JSON export validity, and the
anchored chain. This is the artifact that makes "anyone can check" true
without running a server, and it is the leave-behind for every demo.

## Security and abuse notes

- stdio binary connects to a data dir like any client; for shared
  instances Phase 3+ needs the HTTP transport with existing session
  auth (CSRF/OAuth paths already exist for HTTP).
- Rate/size limits: reuse existing paginated list ops; cap tool result
  payloads; never dump whole docuverse in one tool result.
- Untrusted agent content is untrusted user content: licensing badges
  (FR-24) and edit-policy apply to agent revisions identically.
- Log agent sessions distinctly (`transport: mcp`) in the security log
  for auditability of AI actions.

## Implementation order and rough sizes

1. `src/server/mcp/mod.rs` + `xudanu-mcp` stdio skeleton, MCP handshake
   (initialize/tools/list/tools/call) — small
2. Phase 1 read tools wired to existing methods — small/medium (mostly
   mapping + payload shaping + pagination)
3. Agent club bootstrap: `--agent-name` flag creating/logging into a
   dedicated club — small
4. Phase 2 mutation tools behind `--enable-agent-writes` — medium
   (provenance stamping path + tests)
5. Phase 3 detector tools — small (FR-80 already provides the engine)
6. Verifier kit — medium, independent track
7. Demo corpus + scripted demo (seeded works, planted criticism links,
   agent transcript) — small; this is the pitch artifact

Dependencies to add: an MCP Rust SDK crate (evaluate `rmcp` vs
hand-rolled JSON-RPC; hand-rolled stdio JSON-RPC is acceptable if SDK
churn is a concern — MCP over stdio is a small protocol).

## Test plan

- Unit: tool schemas, payload shaping, pagination caps
- Integration: agent session over stdio executes each tool against a
  seeded server; permission failures (agent club without read on a work)
  surface as MCP tool errors, not raw panics
- Property: every `read_span` result's content matches a fresh
  `resolve` of the same span (guards against stale caching in the
  adapter)
- Provenance: agent revisions carry AuthorType::Llm with model identity;
  signature chain verifies via the Phase 4 verifier
- Abuse: oversized results rejected; agent write attempts fail closed
  when `--enable-agent-writes` is off

## Non-goals (for this FR)

- Agent-side planning/prompting — that is the host's business
- Push notifications over MCP (later)
- Multi-agent orchestration features (agents coordinate via the
  docuverse itself — links and detectors — which is the point)
- Any relaxation of permission checks "for convenience"

## Positioning notes (external messaging)

- "The docuverse as an MCP tool source: agents quote by transclusion,
  comment by link, and every AI action is signed and auditable."
- Legal/traceability wedge: verified quotation provenance for AI-drafted
  briefs and living traceability matrices.
- Survives Roger Gregory's release by construction: the original will
  never speak MCP. This is the layer where Xudanu is the only entrant.
