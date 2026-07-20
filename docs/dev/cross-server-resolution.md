# Cross-Server Content Resolution — Design Document

> Foundational decision record: how a Xudanu server resolves a
> `xan://` tumbler to actual content, what happens when the origin
> server is unreachable, and how paragraph-level addressing extends
> the model.

## Decision Question

When Alice cites `xan://bob.example.com.5.3` from her server, what
guarantees does she have that the citation will resolve — today, next
year, in 20 years? What if Bob's server is down? What if Bob's server
shuts down permanently? What if the citation points at a paragraph,
not a whole work?

The answer shapes:
- Whether Xudanu citations are durable (Xanadu rule #1: links never break)
- What infrastructure Xudanu needs beyond a single server
- How paragraph-level addressing fits into the existing tumbler scheme
- Trust model between servers

## Decision

**Rely on origin server + local cache. Do not build cluster federation
or DHT for now.** Paragraph-level addressing extends the same model.

Rationale:
- Origin server + BLAKE3-verified cache is already shipped (FR-6)
- Handles 95% of real cases: most citations resolve immediately from
  origin or from local cache after first access
- Cluster federation (FR-3) is implemented but optional; DHT is
  out-of-scope indefinitely
- Federation adds significant complexity (peer discovery, gossip
  protocols, sybil resistance) for a problem we don't yet have

Revisit when: real users start hitting the "origin gone, never cached"
case. Until then, the simpler model is correct.

## Background: What We Have Today

### Tumbler-based addressing

Every Xudanu work has a **tumbler** — a structured address of the form:

```
server_domain.work_id
```

For example: `alice.example.com.5.3` means "work 5.3 on
alice.example.com". The server domain is part of the address, so the
resolver knows where to fetch.

Implemented in `src/edition/tumbler.rs` as `XudanuTumbler`. The path
components after the server domain are numeric and arbitrary in
count — so the scheme already supports future extensions like
revisions (`5.3.2`) and paragraphs (`5.3.p17` or `5.3.17`).

### Cross-server content fetch (FR-6, shipped)

When a work transcludes or links to a remote work, the resolver:

1. Parses the tumbler to extract the server domain
2. Issues an HTTP GET to `https://<server>/api/public/work/<id>`
3. Receives the work's edition (postcard-serialized chunks)
4. **Verifies the response with BLAKE3** — content hash is part of
   the `CrossServerRef`, so a malicious server cannot substitute
   different content
5. Caches the content locally, keyed by hash

This is in `src/server/server.rs::http_get_json` and the
`CrossServerRef` infrastructure in `src/edition/links.rs`.

### Server discovery (FR-6, shipped)

- `/.well-known/xanadu-server.json` — server metadata endpoint
- Server directory tracks trusted servers (admin-curated)
- Each server publishes its public works list

### Cluster federation (FR-3, implemented but optional)

Behind the `--enable-cluster` flag:
- Outbound dialer to peer servers
- PeerPool with periodic sync/heartbeat
- PBFT broadcast for state replication

**This is cluster replication, not content discovery.** It replicates
state across a trusted set of servers running the same instance. It
does not help find content on a random third-party server.

## The Gap

### Scenario

Alice has a work `alice.example.com.5.3` — an essay on hypertext.
Bob, on `bob.example.net`, transcludes a paragraph from it into his
own work `bob.example.net.7.1`. Carol, on `carol.example.org`, later
reads Bob's work and follows the transclusion back to Alice's
paragraph.

What happens when Carol's server tries to resolve?

| Alice's server state | Carol's server state | Resolution |
|---|---|---|
| Online | Never seen `5.3` before | ✅ Fetches from Alice, verifies BLAKE3, caches |
| Online | Cached `5.3` from earlier | ✅ Uses cache (or re-fetches to refresh) |
| Offline | Cached `5.3` from earlier | ✅ Uses cache (BLAKE3-verified) |
| Offline | Never seen `5.3` | ❌ Cannot resolve |
| **Gone permanently** | Never seen `5.3` | ❌ **Citation broken** |
| **Gone permanently** | Cached earlier | ✅ Citation still works from cache |

The gap is the bottom rows: if Alice's server disappears AND Carol
never thought to pre-fetch, the citation is broken.

### How likely is the gap?

- **Single-server deploys (most common today):** No gap — everything
  is on one server.
- **Small trusted federation (2–5 servers):** Low gap. Server
  operators can manually mirror important content.
- **Open network (many independent servers):** Real gap. A citation
  to a work on a server that vanished years ago, that you never
  fetched, is broken.

For the foreseeable future, Xudanu deployments are likely to be in
the first two categories. The gap matters when Xudanu becomes a
widely-deployed public network, which is years away.

## Approaches Considered

### Approach A: Status quo (origin + cache)

Current behavior. No new infrastructure.

- **Pro:** Zero work. Already shipped. Well-understood.
- **Con:** Citations break if origin vanishes and you never cached.
- **Verdict:** **Adopted** as the primary model.

### Approach B: Federation gossip

Each server periodically broadcasts a Bloom filter (or sparse hash
index) of its cached content hashes to its peers. When a server
can't reach the origin, it asks its peers "do you have hash X?"

- **Pro:** Builds on existing PeerPool. No new protocol primitives.
- **Pro:** Works for small trusted federations (5–20 servers).
- **Con:** Only finds content within your peer set — if no peer has
  it, you're still stuck.
- **Con:** Bloom filters need periodic refresh; bandwidth cost grows
  with content count.
- **Con:** Trust model: you trust your peers not to serve modified
  content (BLAKE3 still catches modifications, but a malicious peer
  could DoS by serving junk).
- **Verdict:** **Deferred.** Build when real users hit the gap and
  have a trusted peer set they want to federate with.

### Approach C: DHT (distributed hash table)

Content hashes are keys in a Chord, Kademlia, or similar DHT. Any
server can find any content by hash in O(log N) network hops.

- **Pro:** Truly network-wide. Scales to internet size. Survives
  individual servers disappearing.
- **Pro:** Trust-free at the storage layer (BLAKE3 still verifies).
- **Con:** Significant complexity (routing tables, finger tables,
  network partitions, churn handling).
- **Con:** Sybil resistance is a hard problem — malicious actors can
  poison the DHT.
- **Con:** Operational burden on every server operator (maintaining
  a routing table, responding to queries).
- **Con:** Doesn't match how Xudanu is actually used today (mostly
  single-server or small federation).
- **Verdict:** **Rejected** for the foreseeable future. Revisit only
  if Xudanu becomes a widely-deployed public network.

### Approach D: Gateway / archive servers

A few well-known "library" servers (run by us, by universities, by
archives) mirror public Xudanu works. When origin is down, fall back
to querying known archives.

- **Pro:** Easiest to implement (just a fallback list of archive
  URLs).
- **Pro:** Aligns with how scholarly archives actually work (Portico,
  LOCKSS, Internet Archive).
- **Con:** Centralized. Against the Xanadu spirit of peer-to-peer.
- **Con:** Requires someone to pay for and maintain the archive
  servers.
- **Con:** Who decides what's worth archiving?
- **Verdict:** **Possible long-term,** but only after the ecosystem is
  mature enough to support dedicated archives. Not built by us; built
  by institutions that care about preservation.

### Approach E: Content-embedded citations

When Alice transcludes content from Bob, she stores enough of Bob's
content inline that the transclusion works even if Bob disappears.

- **Pro:** Self-contained citations. No network needed after first
  fetch.
- **Pro:** Already partially implemented — Xudanu's transclusions
  store the source span locally.
- **Con:** Storage grows. Every transclusion is a copy.
- **Con:** Doesn't help with links (which are references, not copies).
- **Verdict:** **Already partially adopted.** Xudanu already caches
  fetched content forever; this is essentially approach A with
  content-embedded fallback.

## Decision: Status Quo + Paragraph Tumblers

Adopt **Approach A** as the resolution model. Add **paragraph-level
tumblers** as a new addressable unit, using the same resolution
mechanism.

The full resolution order for any tumbler:

1. **Local:** Is this content on my server? (Local cache or local work)
2. **Origin:** Fetch from origin server (parsed from tumbler)
3. **Cache:** Already cached from a previous fetch? Use it.
4. **Failure:** Otherwise, citation is broken. Show the user a
   "content unreachable" state with the tumbler and origin for
   reference.

No federation, no DHT, no archive fallback. Just origin + cache.

## Paragraph-Level Addressing

### Motivation

Authors want to cite specific paragraphs, not whole works:
- "See ¶17 of Nelson's *Literary Machines*"
- "This transcludes ¶3–¶5 of Bush's *As We May Think*"

Today, paragraph-level citations are spans (character offsets). They
work, but the citation isn't human-readable and the offsets shift if
not migrated carefully. A stable paragraph ID gives us:

- Human-readable citations: `xan://alice.5.3.p17`
- Stable across edits (the ID doesn't change when paragraphs are
  added/removed/reordered)
- Natural unit for transclusion (transclude a whole paragraph)
- Natural unit for the Timeline lens (which paragraph changed in
  revision R?)

### Tumbler scheme

Three options for the path component:

| Format | Example | Tradeoff |
|---|---|---|
| `.p17` (letter prefix) | `alice.5.3.p17` | Unambiguous; doesn't conflict with revision `.17` |
| `.17` (bare number) | `alice.5.3.17` | Ambiguous with revisions; resolver needs context |
| `.r2.p17` (scoped) | `alice.5.3.r2.p17` | Most precise; revision + paragraph |

**Recommendation: `.p17` for paragraphs, `.r2` for revisions.** Letter
prefixes disambiguate, parsers stay simple, both can coexist:
`xan://alice.5.3.r2.p17` = paragraph 17 of revision 2 of work 5.3.

### Paragraph ID assignment

When a new paragraph is created (via insertion of a block break), the
server assigns the next sequential paragraph ID from a per-work
counter. The ID is stored in the O-tree element alongside the
content.

Paragraph IDs are **never reused**. If you delete a paragraph, its
ID is retired. If you delete ¶17 and add a new paragraph later, the
new one gets the next available ID (not 17).

### Display vs. citation

Two views of paragraph IDs:

- **Display (UI):** Show stable IDs in the margin. If paragraphs are
  reordered, the IDs are out of sequence (e.g., ¶17 followed by ¶5
  followed by ¶42). This is honest — it shows the actual identity.
- **Positional (optional secondary view):** Show current position
  numbers (¶1, ¶2, ¶3...). Resets on reorder. Useful for "see the
  3rd paragraph" but not for citation.

The **Cite** action always uses stable IDs.

### Data model

```rust
pub struct ParagraphId(u64);

pub struct ParagraphMarker {
    pub id: ParagraphId,
    pub work_id: WorkId,
    pub created_at: DateTime<Utc>,
    pub created_by: IdentityId,
    pub deleted: bool,  // soft-delete; ID never reused
}

// On the Work's edition:
pub struct Edition {
    // ...existing fields...
    pub paragraph_markers: Vec<ParagraphMarker>,  // indexed by char offset
    pub next_paragraph_id: u64,
}
```

The `paragraph_markers` array maps character offsets to paragraph
IDs. When span migration transforms character offsets, it also
transforms the marker offsets. When a new paragraph break is
inserted, a new marker is created with the next ID.

### Resolution

`xan://alice.5.3.p17` resolves as:

1. Parse tumbler: server=alice, work=5.3, paragraph=17
2. Resolve work 5.3 (origin + cache, as today)
3. Look up paragraph 17 in the work's `paragraph_markers`
4. Return the span (start_char, end_char) for that paragraph
5. If paragraph 17 was deleted, return "paragraph deleted" with the
   tombstone metadata (when, by whom)

### Cross-server behavior

Same as works today:
- Origin server resolves paragraph tumblers via
  `/api/public/work/5.3/paragraph/17` (new endpoint)
- Response includes the paragraph text + BLAKE3 hash of the
  containing work (for verification)
- Caching server stores the paragraph reference alongside its cached
  copy of the work

No new infrastructure. Paragraphs piggyback on the existing
cross-server work resolution.

## Implementation Phases

### Phase 1: Paragraph IDs (backend)

- Add `ParagraphMarker` to the edition
- Assign IDs on paragraph insertion
- Migrate markers via Mapping on edits
- Wire op: `paragraph_lookup(work_id, paragraph_id) → Span`

### Phase 2: Paragraph endpoints (backend)

- `/api/public/work/{id}/paragraph/{pid}` HTTP endpoint
- WebSocket op `paragraph_resolve` for interactive use
- Tombstone response for deleted paragraphs

### Phase 3: Workspace UI (frontend)

- Show stable paragraph IDs in margin (WorkspaceShell)
- Cite action generates `xan://…p17` instead of work-only ref
- Click paragraph number to copy permalink

### Phase 4: Cross-server paragraph fetch

- Resolver handles paragraph tumblers by fetching parent work then
  looking up paragraph
- Cache paragraph resolution alongside work cache
- Verify via parent work's hash

Each phase is independently shippable. Phases 1 and 2 are
backend-only and can ship before any UI consumes them.

## Migration & Coexistence

### Existing works

Works created before this feature have no paragraph markers. On
first open with the new code, the server back-fills markers by
splitting on `\n\n` boundaries and assigning sequential IDs. This
happens lazily (only when the work is loaded) and is persisted on
next checkpoint.

### Backward compatibility

- Old clients ignore the `paragraph_markers` field. They continue
  to see the work as a flat text.
- New clients can read works from old servers; they just don't see
  paragraph IDs.
- The wire ops are additive; no existing ops change.

### Tumbler compatibility

The `XudanuTumbler` type already supports arbitrary numeric path
components with arbitrary letter prefixes. Adding `.p17` is purely a
parsing convention; the type itself doesn't change.

## Trust Model

### Origin authority

The origin server is the authoritative source for:
- What content the work has
- Which paragraph IDs exist
- The current state of each paragraph

A caching server stores content **with its BLAKE3 hash**. If the
origin server later tries to serve different content for the same
tumbler, the cache detects the mismatch and refuses.

### What about revisions?

Revisions (per `versioning-design.md`) are immutable once minted. So
`xan://alice.5.3.r2.p17` always resolves to the same content — even
if Alice later creates r3, r4, r5, the r2 content is frozen.

Combined with paragraph IDs, this gives us:
- `xan://alice.5.3` — the current state of work 5.3 (mutable)
- `xan://alice.5.3.p17` — paragraph 17 of the current state (migrates
  if the paragraph is edited)
- `xan://alice.5.3.r2` — revision 2 of work 5.3 (immutable)
- `xan://alice.5.3.r2.p17` — paragraph 17 of revision 2 (immutable)

The last form is the most durable citation possible: a specific
paragraph of a specific revision of a specific work, on a specific
server. Resolves forever as long as any copy exists.

## Failure Modes

### Origin unreachable, never cached

Citation is broken. UI shows:
- The tumbler (`xan://alice.5.3.p17`)
- The origin server (alice.example.com)
- A note: "Origin server unreachable and no cached copy available."
- A button: "Retry" (in case the server comes back)

### Origin returns different content (hash mismatch)

Cache detects the mismatch. UI shows:
- "Content has changed on origin server in an unexpected way."
- The original hash vs. new hash
- A choice: keep the cached version (preserve citation) or update
  (and accept that the citation may now mean something different)

This is rare but important — it catches both malicious substitution
and genuine server corruption.

### Paragraph deleted

Origin server returns a tombstone. UI shows:
- "Paragraph 17 was deleted on <date> by <identity>."
- The original content (from cache) as a struck-through block
- The user can still read the deleted content (it's in the cache)

This preserves the historical record without pretending the
paragraph still exists.

## When to Revisit Federation

Build Approach B (federation gossip) when **all** of these are true:

1. Multiple Xudanu servers are deployed independently (not just dev
   instances)
2. Users regularly cite works across servers
3. Users report broken citations due to unreachable origin servers
4. A natural trusted peer set exists (e.g., a Xudanu operator
   community where peers opt in to mutual backup)

Build Approach C (DHT) when:

1. Federation gossip exists and is insufficient
2. Xudanu has dozens+ of independent servers
3. There's a real ecosystem reason for internet-scale resolution
   (not just theoretical)

Until then, both are over-engineering.

## Ties to Other Designs

| Feature | Dependency |
|---|---|
| **FR-6 Linked independent servers** | This doc explains FR-6's resolution model in detail |
| **FR-3 Cluster federation** | Out of scope per this decision; FR-3 is cluster replication, not discovery |
| **`versioning-design.md`** | Revisions + paragraph IDs combine for durable citations |
| **FR-18 Workspace** | Paragraph margin numbers depend on this design |
| **O-tree CRDT** | Already supports stable element IDs — paragraph IDs piggyback on this |

## Success Criteria

- A citation to `xan://alice.5.3.p17` resolves correctly when Alice's
  server is online.
- The same citation resolves from local cache when Alice's server is
  offline (assuming prior access).
- A citation to `xan://alice.5.3.r2.p17` resolves to the same content
  forever (revision is immutable).
- Deleted paragraphs return a tombstone, not a 404.
- The resolver never accepts content that doesn't match the BLAKE3
  hash in the citation.
- Paragraph IDs are stable across edits (¶17 stays ¶17 even after
  surrounding paragraphs are added/removed/reordered).

## References

- `src/edition/tumbler.rs` — `XudanuTumbler` type
- `src/edition/links.rs` — `CrossServerRef`, cross-server link storage
- `src/server/server.rs::http_get_json` — cross-server fetch
- `src/server/server_directory.rs` — server directory
- `docs/dev/FR-6.md` — Linked independent servers design
- `docs/dev/FR-3.md` — Cluster federation (related but distinct)
- `docs/dev/versioning-design.md` — Revision addressing
- Ted Nelson, *The Future of Information* (1997) — original tumbler
  design
- Udanax Gold source — enfilade/canopy implementation reference
