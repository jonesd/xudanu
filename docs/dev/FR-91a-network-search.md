# FR-91a: Network Search — Bloom-Routed Federated Query Fan-Out

- **ID:** FR-91a
- **Parent:** FR-91 (Distributed Docuverse) — sub-FR ranked first for
  cost/benefit
- **Status:** Proposed (2026-10-19). Grounded in machinery that now
  exists and is tested: server directory (FR-6), verified
  `.well-known` identity, signed cross-server exchanges (backlink
  notifications), the public content API, and the 4-node docker
  federation test bed.
- **Depends on:** nothing new — all substrate is shipped.

## 1. Problem

Search today is single-server ("ad-hoc"): `WorkSearch` (0x0d06)
queries one server's works. Cross-server discovery is manual — the
user must know which server holds a source, then hand-build a remote
link. The docuverse's addressing is already global (tumblers:
`"server-identity".work.span`); its search should be too.

**Non-goal:** a global index (crawler/central search). Non-goal:
searching private works — public-club works only, exactly like the
public content API. Non-goal: PBFT mesh membership — this rides the
content plane, membership-free.

## 2. Design: bloom-routed fan-out

### 2.1 Bloom filters per server (FR-91a core)

Each server maintains a bloom filter over the lowercased tokens of
its **public** works' titles and text:

- 4096-bit (512 bytes), k=4 hashes (blake3-derived), base64 in
  `.well-known` as `search_bloom`, alongside `bloom_updated_at`.
- Rebuilt lazily: on boot, and marked dirty on public-work mutation;
  rebuilt at most once per checkpoint cycle (never on the hot path).
- False positives are fine (they cost one wasted remote query);
  false negatives are not (a work must never be unfindable —
  insertion-only filter, rebuilt on delete-by-rebuild).

The bloom filter answers: "might this server hold the term?" — so a
querying server fans out only to plausible peers instead of everyone.
A directory of 50 peers typically prunes to a handful.

### 2.2 Remote query endpoint (each server)

`GET /api/public/search?q=<terms>&limit=<n>`

- Public-club works only (reuse the `public_work_list_search` gate,
  server.rs:8539 — private works are invisible, 404-shaped).
- Response: results (max 20/origin) each carrying
  `{tumbler, work_id, title, excerpt, updated_at}` + the server's
  own identity block. Every response is signed by the serving
  server's Ed25519 key (same scheme as backlink notifications:
  `X-Xudanu-Origin-Key` / `X-Xudanu-Signature` over the body) so
  results are attributable.
- Rate-limited per IP (`check_get`), body-capped, timeout-bounded.

### 2.3 Fan-out at the querying server (server-side, not client)

New WS op `NetworkSearch { query, include_local }` (or extend
`WorkSearch` with scope) → the local server:

1. Always searches itself (local results first, today's behavior).
2. For each **trusted directory entry** with a cached bloom that
   might contain the query: `GET /api/public/search` via the
   SSRF-guarded fetcher (`http_get_json` family), **2s per-peer
   timeout, 3s overall deadline** — the FR-40 lesson: a blackholed
   peer must never stall the querier; partial results always return.
3. Verifies each response signature against the origin's published
   `.well-known` key (cache shared with backlink verification).
4. Merges: local results + remote (tagged with origin server name
   from the directory), deduped by tumbler, capped at 50, ranked
   local-then-recency. Per-origin outcome reported
   (`{origin, status: ok|timeout|unreachable}`) — sender feedback,
   never silent.
5. Bloom cache refresh: directory sync pulls peer `.well-known`
   hourly; a missing/stale bloom downgrades that peer to
   "always queried" (correct, just unpruned).

### 2.4 Client (SearchOverlay)

New "network" scope toggle. Network results grouped by origin badge;
clicking a cross-server result fetches an excerpt preview via
`/api/public/work/{id}` (already access-gated) and offers the
existing actions: create remote link, transclude into current work.

## 3. Privacy & security notes (honest ledger)

- Queried servers see your queries (query leakage to your trusted
  directory — same trust boundary as cross-server linking; document
  it, don't hide it).
- No open relay: fan-out only to servers in the local directory.
- Results are public works only; excerpts capped (200 chars);
  content fetch re-gated at the origin.
- Attributable results (signed) — a lying middlebox can't forge
  result sets from a server it isn't.

## 4. Test plan

- Unit: bloom insert/maybe-contains correctness; merge/dedupe;
  public-only gating; signature over results.
- Integration (docker bed): cross-register node1↔node2 in each
  other's directory; create distinctive public work on node2;
  `NetworkSearch` from node1 finds it with origin badge; stop node2
  → search still returns local results + `unreachable` origin status
  within the 3s deadline.
- Regression: no result for private works cross-server.

## 5. Sizing

Small-to-medium: bloom (≈150 lines), endpoint (≈80), fan-out merge
(≈150), overlay changes (≈100). The pieces it leans on are all
built and battle-tested this week.
