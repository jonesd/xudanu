# FR-91 Phase 2: BeBe and the Promise Layer — Design Brief

- **ID:** FR-91-P2
- **Status:** Draft (2026-10-15) — the substantive design questions
  that must be answered before building the distributed docuverse.
  This document is the founding conversation, not the spec.
- **Depends on:** FR-88 S1 (back-edges severed — clean engine
  boundary), the modelling completeness audit (0h — confirms no
  missed Gold concepts), the Miller spelunking (erights.org, the
  thesis, the Agoric papers — the refined reasoning)
- **Produces:** two design documents — one for BeBe (the
  server-to-server protocol), one for the promise/portal layer
  (the async abstraction) — which together constrain FR-91e/f/g

## 1. The problem, stated in one paragraph

A docuverse that spans multiple servers must feel like one system
to every participant, regardless of which server they connect to.
Today, federation links across servers but doesn't share
enfilades, resolve recipes across boundaries, or hide cross-server
latency. The Gold team designed solutions to all three — BeBe
(server-to-server), the cookbook (cross-server recipes), and the
promise layer (async resolution) — but couldn't build them on 1992
infrastructure. We can. The question is: what did they actually
design, what has Miller refined it into, and what should xudanu's
version look like?

## 2. The founding questions

These are the questions that, once answered, determine everything
downstream. Each has a Gold heritage answer, a Miller-lineage
answer, and an xudanu-design answer that may differ from both.

### Q1: What crosses the server boundary?

**The question:** when server A and server B participate in the
same docuverse, what actually moves between them?

**Gold's answer (inferred from .enf files and BeBe):** whole
enfilades — the document-space as a portable unit. Server A holds
the enfilade; BeBe transfers it to server B (like loading a .enf
file over the network). The enfilade is the unit of sharing.

**Our current answer (federation):** individual spans — server A
resolves a cross-server transclusion by fetching the specific
passage from server B. The span is the unit of sharing.

**The design tension:**

| Model | Advantage | Disadvantage |
|---|---|---|
| Enfilade transfer (Gold) | simple unit, full context arrives, works offline after transfer | coarse — you get everything whether you need it or not; write-back requires re-transfer |
| Span resolution (ours) | fine-grained, cache-friendly, only what's needed | many round-trips for large reads; no offline capability; chatty |
| **Streaming sync (the CRDT path)** | real-time convergence; any server can write; no unit boundary needed | requires the lattice sync protocol to work cross-server (it works in-process today); bandwidth proportional to edit rate |

**The founding question:** is BeBe a *transfer* protocol (move
enfilades), a *resolution* protocol (fetch spans on demand), or a
*sync* protocol (replicate lattice deltas continuously)? Or a
layered combination — sync for servers in the same trust domain,
resolution for cross-domain reads, transfer for backup/migration?

**Miller's contribution:** E's vat model says the boundary is the
trust boundary, and communication across it is always async
(eventual sends / promises). This suggests: BeBe is async at its
core — you send a request and get a promise, never a synchronous
answer. The sync/transfer/resolution choice is above the async
substrate.

---

### Q2: Who owns writes?

**The question:** when a work is addressable on multiple servers,
which server accepts new revisions?

**Gold's answer:** the home server. The tumbler address includes
the server identity; writes route to the authority. The home
server is the "point of authority for provenance" (Beaumont &
Anderson's phrasing).

**Our current answer:** single-server only. Each work lives on
one server; there is no multi-server write path.

**The design tension:**

| Model | Advantage | Disadvantage |
|---|---|---|
| Home-server authority (Gold) | simple; provenance is clean; matches DNS anchoring | single point of failure; no partition tolerance |
| Multi-master CRDT (the lattice path) | any server accepts writes; the lattice merges deterministically; partition-safe | provenance is harder (who "really" wrote first?); needs vector clocks or equivalent; cross-server span addressing gets complex |
| **Hybrid: home + read replicas** | home server owns writes; replicas serve reads and cache content; replicas can promote if the home fails | promotion protocol needed; a replica is stale until the home pushes or the replica pulls |

**The founding question:** is the docuverse's consistency model
"one authority per work" (Gold) or "eventual consistency for all
works everywhere" (CRDT)? The answer determines whether BeBe is
a request-response protocol (authority model) or a gossip/sync
protocol (CRDT model).

**Miller's contribution:** E's capability model says authority
should be object-scoped, not server-scoped. Each *work* carries
its own authority set (which clubs can write), and any server
holding the capability can exercise it. This is neither pure
home-server nor pure multi-master — it's capability-routed writes.

---

### Q3: What is the trust model?

**The question:** how do servers establish and maintain trust?

**What we have:** the server directory tracks verifying keys,
trust/untrusted/quarantined status, referral chains, and health
monitoring. Ed25519 signatures verify content. BLAKE3 hashes
verify content identity. This is a good foundation.

**What's missing for BeBe:**

1. **Key rotation** — if server A's signing key is compromised,
   how does B learn the new key? (The directory has `pinned_key`
   as a field — is this the mechanism?)

2. **Capability delegation** — server A grants server B
   read-access to work X (but not write-access, and not
   read-access to work Y). This is Miller's territory: the
   capability is unforgeable, delegable, and revocable.

3. **Quarantined-server recovery** — the directory already
   tracks quarantine. What happens to works that were partially
   resolved from a quarantined server? Is there a "clean-up"
   protocol?

4. **Cross-server provenance chains** — if work W on server A
   transcludes from work V on server B, and B's provenance chain
   is anchored to Bitcoin, can A verify B's chain without
   contacting B? (The anchoring should make this possible: A
   checks the Bitcoin anchor, which is public.)

**The founding question:** is trust between servers binary
(trusted/untrusted) or fine-grained (per-work, per-operation,
time-limited)? Gold's club model suggests fine-grained; Miller's
capability model confirms it.

---

### Q4: How do recipes resolve across servers?

**The question:** a derived document (a trail, a search view, a
compound) on server A references sources on servers B and C.
How does A produce the result?

**Three models:**

| Model | How it works | Latency | Server load |
|---|---|---|---|
| **Fetch-and-resolve** | A fetches the source spans from B and C, resolves locally | high on first resolution; low on cache hits | B and C serve reads; A does compute |
| **Distributed resolution** | A sends the recipe to B; B resolves its part; sends the partial result back | lower (compute moves to data) | B does compute; A does assembly |
| **Client-side resolution** | the client resolves all sources directly | highest (client does everything) | A serves the recipe only; B and C serve reads |

**Gold's cookbook design (inferred):** recipes are declarative
and deterministic (VirtualSpec pins the revision). Any party
with access to the sources can resolve. The question is
*efficiency*, not correctness — every model produces the same
answer.

**The founding question:** should BeBe support distributed
recipe resolution (compute moves to data), or is fetch-and-
resolve sufficient? The CDN bridge might make this moot — if
immutable editions are hash-named static assets served by any
CDN, "fetching" is cheap everywhere.

---

### Q5: What is the promise abstraction?

**The question:** how do long-running cross-server operations
hide latency from the caller?

**Gold's design:** Portal (unified connection abstraction) +
PromiseManager (async deferred resolution) + ProtocolBroker
(version negotiation). A request across any boundary returns a
promise; the promise resolves when the result arrives.

**Our current design:** xcp ops are synchronous request-response
over WebSocket. There is no async op surface.

**The design tension:**

| Approach | How it works | Fits xudanu where |
|---|---|---|
| **Wire-level promises** | xcp gains a `promise` op type: submit a long-running query, get a promise ID, poll or subscribe for the result | the WebSocket transport; MCP clients; the web UI |
| **In-process promises** | Rust `Future` behind the engine boundary (FR-88); async internally, synchronous externally | the engine crate; in-process embedders |
| **Both** | the engine is async (Rust futures); the wire protocol exposes promises for remote operations; the two compose | everywhere |

**The founding question:** is the promise layer a wire protocol
evolution (xcp v2 gains async ops), or an internal engine
abstraction (the crate is async, the protocol stays sync), or
both? Gold's design suggests both — the promise is the
concept; the wire and the engine are two expressions of it.

**Miller's contribution:** E's eventual sends are *exactly* this
pattern, refined over decades. The key insight: **promises
compose** — you can chain them, combine them, race them. A
cross-server recipe resolution is a promise that depends on
other promises (the source fetches), and the dependency graph
is the promise chain. This is FR-91f's architecture, already
designed by Miller.

---

### Q6: How do detectors work across servers?

**The question:** a detector on server A watches for new links
to work W, but W is also linked from server B. How does A's
detector fire?

**Three models:**

1. **Polling federation**: A periodically queries B for new links
   to W. Simple, but adds latency and load.

2. **Detector registration**: A registers its detector with B;
   B notifies A when the detector fires. This is push-model
   detectors extended cross-server — and it's a *promise*
   ("notify me when X happens").

3. **Detector network**: detectors are themselves works, and the
   detector-registry is the same federated infrastructure as any
   other work. Any server can subscribe to any other's
   detectors.

**The founding question:** are cross-server detectors a
federation feature (the servers cooperate to route detector
events) or a docuverse feature (detectors are works, and the
subscription is a link)? The second is more xanalogical — the
detector system built from the model's own primitives.

---

## 3. The design constraints (what any solution must satisfy)

These are the invariants — properties the distributed docuverse
must have regardless of which design answers we choose:

1. **Immutability at every layer** — frozen editions, write-once
   chunks, content-addressed identity. No design may introduce
   mutable shared state.

2. **Content verification** — BLAKE3 hashes prove content
   identity across servers. No design may rely on trust where
   verification is possible.

3. **Convergence** — the lattice CRDT merges deterministically.
   No design may require a consensus protocol (no Paxos, no
   Raft) for content state.

4. **Provenance preservation** — per-span attribution chains
   must survive cross-server transit. The chain must be
   verifiable independently of any single server.

5. **Address stability** — tumblers are permanent. No design
   may break an existing address. Migration preserves addresses
   (DNS re-pointing).

6. **The everything-is-a-work uniformity** — protocols,
   detectors, recipes, access policies are all works. No design
   may introduce a second kind of persistent object.

7. **Schema freedom** — new relationship types, new media, new
   organisational structures added without schema migration.
   No design may freeze the vocabulary.

8. **Offline capability** — a server that loses connectivity
   must still be able to serve reads from its cached replicas
   and queue writes for later synchronisation.

## 4. The design concerns (what could go wrong)

### The failure modes

| Concern | Scenario | Mitigation direction |
|---|---|---|
| **Split-brain provenance** | two servers accept conflicting revisions of the same work; both have valid provenance chains | the ent DAG *preserves* the conflict as a branch (by design); the question is presentation, not storage |
| **Byzantine content** | a malicious server serves content that doesn't match the BLAKE3 hash it claims | hash verification at every read; the server directory quarantines on mismatch |
| **Cascading staleness** | server A's cached replica of work W is stale because server B (the authority) is down | TTL-based staleness marking; readers see "this content is N revisions behind" rather than silently serving stale data |
| **Detector storms** | a popular work gets linked from many servers; each server's detector fires, creating a notification cascade | detector aggregation at the federation boundary; rate limiting in the server directory |
| **Recipe resolution cost** | a complex recipe references hundreds of sources across many servers | recipe batching; the CDN bridge (immutable sources served from edge caches); lazy resolution (only produce the spans being read) |
| **Trust-graph collapse** | a trusted server is compromised; works it vouched for are now suspect | key rotation in the directory; Bitcoin-anchored provenance (the anchor is independent of any server's trustworthiness) |

### The engineering concerns

| Concern | Why it matters |
|---|---|
| **Bandwidth proportional to edit rate, not corpus size** | sync protocols that send the whole corpus are non-starters; only deltas are viable |
| **Server discovery at scale** | the directory works for dozens of servers; what about thousands? (DNS hierarchy + bloom filters) |
| **The MCP layer across servers** | agents need to be aware of federation boundaries (or shielded from them); the capability model should handle this |
| **Backward compatibility** | the current xcp protocol and federation must keep working; BeBe is additive |
| **Testing distributed properties** | convergence tests need multi-server simulation; the existing CRDT test infrastructure is in-process only |

## 5. The Miller reading list (what to study before designing)

These are the specific papers and sources that contain the
reasoning we need. Priority order:

| # | Source | What it contains | Priority |
|---|---|---|---|
| 1 | **"Robust Composition" thesis** (Miller, 2006) | the unified access-control + concurrency theory; capability composition; the formal treatment of promises in distributed systems | highest — this is the PhD-level version of our problem |
| 2 | **erights.org — the E papers** | distributed promises in practice; eventual sends; the vat model; decades of refinement of the ideas Gold's promise layer started | high |
| 3 | **"The Open Society and Its Media"** (Miller, 1994) | already cited in FR-80; but read fully for the detector + media + trust model, not just the detector concept | high |
| 4 | **Agoric papers** (Miller + Drexler) | computational markets; the economic layer that transcopyright needs; resource pricing for a docuverse | medium — relevant for the micropayments layer we're deliberately deferring |
| 5 | **TC39 Promise spec** (Miller was a co-author) | the standardised promise semantics; edge cases; cancellation semantics | medium — useful for the wire-protocol design |
| 6 | **The WormIssues videos** (from the archive) | the WORM-hardware reasoning; why immutability was chosen; the engineering constraints | high — whisper transcription needed |

## 6. The output: what Phase 2 produces

Two documents:

1. **The BeBe Protocol Design** — the server-to-server
   specification: what crosses the boundary, how trust works,
   how writes route, how detectors federate, how recipes resolve.
   Should be normative (implementable without ambiguity).

2. **The Promise Layer Design** — the async abstraction: how it
   appears in the engine (Rust), in the wire protocol (xcp), and
   in the MCP surface. Should compose with BeBe (cross-server
   operations return promises).

Both documents should reference this brief's founding questions
and demonstrate that each has been answered.

## 7. The preconditions (what must be true before Phase 2 starts)

- [ ] FR-88 S1 complete (back-edges severed; clean engine boundary)
- [ ] Modelling completeness audit (0h) complete — confirms no
      missed Gold concepts that would change the design
- [ ] WormIssues videos transcribed (whisper run) — the WORM
      reasoning
- [ ] Miller reading list §5 items 1-3 read and digested
- [ ] FR-91a and FR-91b shipped (bloom filters in directory,
      push-model detectors) — the practical groundwork
- [ ] FR-90 (NFC) shipped — the content-identity prerequisite
      for cross-server hash agreement

---

*This document is a design brief, not a spec. Its job is to name
the right questions and the constraints on the answers. The spec
comes after the questions are answered.*
