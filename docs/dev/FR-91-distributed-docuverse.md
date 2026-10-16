# FR-91: Distributed Docuverse Architecture — Scaling, Distribution, and the Unused Gold Machinery

- **ID:** FR-91
- **Status:** Proposed (2026-10-15) — synthesis from the structural
  inventory and the Gold C++ comm-layer archaeology. Expansive by
  design: this is the umbrella FR that names the destination; the
  concrete sub-FRs live in §7.
- **Depends on:** FR-88 (engine extraction — the crate boundary
  matters for in-process distribution), FR-76 (epoch freeze — already
  shipped, the foundation of the scaling model)
- **Closes:** the "how does it span servers" question; the unused-
  Gold-machinery gap (cookbook, portal, promise, BeBe, bloom filters
  in the directory); the application-scenarios inventory

## 1. The three hard problems

1. **Responsiveness at scale** — queries and edits stay fast as the
   docuverse grows to millions of works with billions of spans
2. **Evolving complex data models** — new relationship types, new
   media, new organisational structures added without schema
   migration or system redesign
3. **Distribution across many servers** — content spans independent
   machines with independent administration, yet the docuverse feels
   like one system

Gold solved all three **in the data structure layer**, not in an
architecture layered on top. The substrate to run that design on
arrived between 1995 and 2020.

## 2. The six-layer scaling architecture

### Layer 1: The enfilade (SHIPPED)

The tree that is simultaneously index and container.

| Property | Mechanism | Consequence |
|---|---|---|
| Index + container | the enfilade IS the search structure | O(log N), no secondary indexes |
| Crums (subtree hashes) | BLAKE3 identity per subtree | 32-byte comparison = agreement |
| Splay optimization | hot data toward the root | self-tuning locality |
| Freeze protocol (FR-76) | entries → serialize → content-addressed chunk | identical entries = identical epoch IDs, independent of tree shape |
| Eviction (FR-76 Phase 2) | RAM → cache → disk, transparent | the caller never knows |

**The freeze protocol is the scaling secret**: tree shape is an
ephemeral optimization, not identity. Two servers can hold the
"same" enfilade with different splay histories and agree on identity.
Evicted works read transparently. The chunk store deduplicates
naturally.

### Layer 2: The promise/portal system (DESIGNED, NOT BUILT)

The C++ comm layer reveals the async architecture:

- **Portal** (portalx.hxx, DEFERRED class): a unified connection-point
  abstraction — local, same-machine (FeBe), or cross-machine (BeBe)
- **PromiseManager** (promanx.hxx): async deferred resolution — the
  front end issues a request, receives a promise, continues working;
  the promise resolves when the back end completes
- **ProtocolBroker** (negoti8x.hxx): version negotiation between
  parties before data exchange

This is 1960s-70s futures/promises — the same concept as async/await,
CompletableFuture, Rust Future. It was the mechanism for hiding
latency across process boundaries.

**Xudanu status**: the xcp wire protocol handles client-server
synchronously. The promise abstraction, BeBe (server-to-server),
and the unified portal model are not implemented.

### Layer 3: The cookbook/recipe system (DESIGNED, NOT BUILT)

The C++ comm layer contains:

- **Cookbook** (cookbkx.hxx): combines recipes
- **Recipe** (recipex.hxx): a declarative transformation specification

The Smalltalk census shows the concrete types:
- `ActualCookbook` — the composition container
- `ActualCopyRecipe` — "take this span from that document"
- `ActualProxyRecipe` — "take this content and present it as a
  different type"
- `ActualStubRecipe` — "a placeholder for content not yet available"

**What a recipe is**: a lazy, declarative specification of how to
derive content from other content. Production happens on demand,
at read time, on whichever server is closest.

**Xudanu equivalent**: `VirtualSpec` + `Virtual` element IS a recipe
(single-source). `Derived` documents (FR-37 Phase 4) for multi-source
compositions. Trails as ordered VirtualSpec sequences. What's
missing: the cookbook as a *named, shareable, versioned* composition
of recipes, and cross-server recipe resolution.

### Layer 4: Detectors (PARTIALLY BUILT — pull-model, work-level)

FR-80's heritage line: *"Miller, 'The Open Society and Its Media'
(1994) — the fourth fundamental feature."*

**Current**: pull-model, work-level. Link detectors collect new
links landing on a work (filtered by type-set, direction, clubs);
revision detectors collect new revisions. Capped at 200 hits.

**Designed but not built**:
- Push-model (WebSocket notify — the transport already exists)
- Span-level pattern matching (the fossil engine's `RecorderQuery`:
  region + authority + endorsement filter)
- Cross-server detector networks (detector on A fires when content
  arrives on B)

**Why detectors are the scaling answer**: they invert the query
model. Instead of "search every time" (O(docuverse) per query),
you register "tell me when X" (O(1) registration, O(match) per
event). The Observer pattern at docuverse scale.

### Layer 5: Bloom filters (BUILT, NOT CONNECTED)

`ServerBloomFilter` exists in the server — probabilistic membership
testing (configurable false-positive rate, ~1 MB for millions of
items). **Not yet published in the server directory or used for
cross-server query routing.**

**The purpose**: before an expensive cross-server lookup, check the
bloom filter locally. If it says "no," skip the network round-trip.
Combined with tumblers (where to look) and backfollow (what
connects), bloom filters make distributed queries tractable without
a global index.

### Layer 6: The server directory (BUILT — the namespace authority)

`ServerDirectory` already tracks:
- Discovered servers with verifying keys, pinned keys, HTTPS support
- Trust (trusted/untrusted/quarantined)
- Reliability (successful resolutions, failure counts → quarantine)
- Provenance (who referred this server, when first seen)

**Missing**: bloom filter exchange (each entry carries the server's
filter), global content routing ("which servers might hold work X?").

## 3. The unified architecture

```
┌──────────────────────────────────────────────────────────────┐
│                 THE DOCUVERSE (distributed)                   │
├──────────────────────────────────────────────────────────────┤
│  Server A                Server B              Server C     │
│  ┌──────────────┐       ┌──────────────┐                    │
│  │ Enfilade     │       │ Enfilade     │                    │
│  │  active      │       │  active      │                    │
│  │  cached      │  BeBe │  cached      │                    │
│  │  frozen      │ ←───→ │  frozen      │                    │
│  │    ↓         │       │    ↓         │                    │
│  │ ChunkStore   │       │ ChunkStore   │                    │
│  └──────────────┘       └──────────────┘                    │
│       │ BloomFilter         │ BloomFilter                   │
│       └──────┬───────────────┘                               │
│              ▼                                               │
│     ┌────────────────┐                                      │
│     │ ServerDirectory│  ← namespace authority                │
│     │ + bloom filters│                                      │
│     │ + trust/health │                                      │
│     └────────────────┘                                      │
│                                                              │
│  DETECTORS: standing queries watching for change             │
│  PROMISES: async resolution across boundaries                │
│  RECIPES: declarative derivations computed on demand         │
│  CDN BRIDGE: immutable editions as hash-named assets         │
└──────────────────────────────────────────────────────────────┘
```

## 4. What XOC designed but couldn't ship, and why we can now

| Designed | Why they couldn't | Why we can |
|---|---|---|
| Promise layer | no async runtime in 1992 C++; blocking sockets | tokio, WebSocket, async/await |
| BeBe (server-to-server) | no internet-scale deployment to test against | federation verified; DNS-anchored tumblers |
| Cookbook/recipe system | no compute layer for on-demand resolution | VirtualSpec resolves deterministically; CDN bridge |
| Distributed detectors | no push notification infrastructure | WebSocket, webhooks, SSE — all standard |
| Bloom filter routing | not applied to distributed search until later | trivially available |
| Global namespace | the UAN authority needed coordination they couldn't achieve | DNS + server directory |

## 5. Unused Gold machinery found in the tree

| Artifact | Location | What it is | Xudanu equivalent |
|---|---|---|---|
| Cookbook/Recipe hierarchy | cookbkx.hxx, recipex.hxx (C++); ActualCookbook etc. (Smalltalk) | declarative transformation system | VirtualSpec (single-source); missing: cookbook composition, recipe type registry |
| ProtocolBroker | negoti8x.hxx | version negotiation between parties | xcp has a version, no negotiation |
| Portal abstraction | portalx.hxx (DEFERRED class) | unified connection-point model (local/FeBe/BeBe) | WebSocket (remote) + direct (in-process); no unified abstraction |
| WormIssues concept | video title; WORM = Write Once Read Many **hardware storage devices** (1980s-90s optical media) | the physical immutability constraint the model was designed against — frozen editions, append-only chunks, content addressing are all software expressions of WORM hardware. The "WormIssues" videos discuss the engineering problems of targeting WORM drives: no rewrite, no delete, expensive per-byte (hence transclusion-as-dedup as economic necessity). WORM hardware died; the design constraints it forced turned out to be exactly right for content addressing (Git/BLAKE3), CRDTs, blockchain anchoring, and CDN caching | chunk store IS write-once (the software WORM); epoch freeze is the same constraint expressed as a protocol. The WormIssues videos are the primary record of their reasoning — priority transcription targets |
| Recorder/fossil engine | recorder.rs, RecorderQuery | span-level detector with structural pattern match (region + authority + endorsement) | work-level detectors only; the fossil engine is the design for span-level |

## 6. Application scenarios where the Gold model wins

### Engineering / CAD (Autodesk's original 1988 bet)
- Assemblies = CompoundEdition
- Part references = StructuralTransclusion (live windows, not copies)
- BOM = Set + HyperLink (unordered parts collection + typed connections)
- Where-used = backfollow
- Design review = ent DAG + Endorsement + Label
- Advantage over PLM/PDM: no schema to migrate; new relationship types are works

### Legal / regulatory
- Statutes = Works with deep versioning
- Stare decisis = StructuralTransclusion (live window onto prior decisions)
- Regulations referencing standards = HyperLink with type "implements"
- Provenance = per-span signatures + Bitcoin anchoring
- Multi-jurisdiction = federation

### Scientific data / reproducibility
- Methods = CompoundEdition + Virtual elements (reference exact data/code revisions)
- Data = Blobs (content-hashed, immutable)
- Analyses = Derived works (VirtualSpec pins the exact revision; deterministic replay)
- Peer review = Endorsement + typed links
- Multi-lab = federation with verified provenance

### Agent orchestration
- Shared knowledge = the docuverse (structural memory)
- Attribution = per-span author_type (human/LLM/historical)
- Agent scoping = clubs (least-privilege)
- Reasoning chains = Path (ordered steps, each a pinned span)
- Audit trail = provenance chain + anchoring

### Enterprise knowledge management
- Policies = Works + versioning + Endorsement
- Decision records = Path + Set + typed links
- Cross-department = federation with club-based access
- Compliance = per-span provenance

## 7. Concrete sub-FRs (ranked by cost/benefit)

| Sub-FR | What it unblocks | Size | Depends on |
|---|---|---|---|
| FR-91a: Bloom filters in the directory | cross-server search without global index | small — filter + directory exist, connect them | — |
| FR-91b: Push-model detectors (WebSocket notify) | responsive cross-server awareness | small — detector infra + WebSocket exist | — |
| FR-91c: Cookbook as a named, shared recipe | versioned derivations as works | small — VirtualSpec + Trail provide the machinery | FR-39 (types-as-documents) |
| FR-91d: Enfilade export/import (.enf equivalent) | portable docuverses (migration, backup, deployment) | medium — export format + address preservation | FR-88 S1 |
| FR-91e: BeBe (server-to-server protocol) | true distributed docuverse — sharing enfilades, not just linking | medium — trust layer exists (federation); protocol is new | FR-88, FR-91d |
| FR-91f: Cross-server recipe resolution | distributed query engine (recipe on A, sources on B and C) | larger — needs promise layer + cookbook + BeBe | FR-91c, FR-91e |
| FR-91g: Promise/portal abstraction | unified connection model (local/remote/cross-server) | medium — design work; tokio provides the substrate | FR-88 |

## 8. Sequencing

This FR is the post-launch **second arc** (the engine extraction is
the first). The sub-FRs sequence naturally:

1. FR-91a + FR-91b (small, immediate value for existing federation)
2. FR-91c (the cookbook — opens the recipe ecosystem)
3. FR-91d (portability — the enfilade-as-file)
4. FR-91e (BeBe — the real distributed protocol)
5. FR-91f + FR-91g (the full distributed query engine)

Each stage is independently valuable and demonstrable. The build-in-
public arc: "we're connecting bloom filters to the directory" →
"we're adding push notifications to detectors" → "the cookbook is a
work" → "enfilades are portable files" → "servers share enfilades"
→ "any server can resolve any recipe."

## 9. The structural inventory (reference)

The complete list of structural primitives from the edition module,
for use in the modelling completeness matrix (FR-91's sibling):

### Container primitives (RangeElement variants)
Text, Data, Blob, Edition, Work, Label{inner}, PlaceHolder, IDHolder,
Overlay, Transclusion, StructuralTransclusion, Virtual{spec}, Set{spans},
Path{spans}

### Connection primitives
HyperLink{types, ends}, HyperRef (single), HyperRefKind::Multi (gathered),
HyperRefKind::LinkAttachment (link-about-link), Path (label-path context),
CrossServerRef (federation)

### Organisational primitives
Exhibition (gathers), Trail, Endorsement, Label, Bundle/CompoundEdition,
Derived

### Address/algebra primitives
Tumbler, IntegerSpace, RealSpace, SequenceSpace, CrossSpace, CrossNSpace,
Filter, Enfilade/Canopy, Lattice

### Composition recipes (how they combine)
1. Nesting without schema: Label + Edition
2. Gathered evidence: Set + HyperLink + Endorsement
3. Derived views: Virtual + Trail + Set (zero storage, deterministic)
4. Compound documents: CompoundEdition + StructuralTransclusion + Image
5. Argument maps: Path + Label + HyperLink (reasoning chains)
6. Version-annotated models: ent DAG + Label + Endorsement
7. Spatial models: CrossSpace + Blob + Label

Each recipe costs approximately zero storage because content is
always held by reference, pinned by crum, resolved on demand.

## 10. The Miller lineage — post-Xanadu continuation

Mark Miller continued the Gold-era thinking immediately after the
August 1992 divestment. His subsequent work is the most direct
intellectual descendant of the promise system, the portal
abstraction, the club-based access model, and the agoric economic
layer. These are the sources that contain the reasoning the
WormIssues videos might not have captured.

### The trajectory

| Project | Carries forward from Gold | Key insight for xudanu |
|---|---|---|
| **E language** (mid-90s onward) | promise system → distributed promises; portal → vat-to-vat communication; clubs → capability-based access control | E's `eventual send` (`<-`) is a promise across a vat boundary — exactly what Portal + PromiseManager designed. Decades of refinement. |
| **EROS / Coyotos** (capability OS) | immutable data + capability security | the hardware-level expression of "you can't rewrite, only create" |
| **Agoric computing** (with Drexler) | transcopyright and micropayments as computational market mechanisms | the economic layer — resource pricing for a docuverse |
| **"Robust Composition" PhD thesis** (2006) | the unified treatment of access control + concurrency in distributed systems | literally the PhD-level version of FR-91's problem space; capability-based composition with promises |
| **"The Open Society and Its Media"** (1994) | the detector concept (already FR-80's heritage) + the broader media model | the bridge document — written two years post-Xanadu |
| **Agoric (the company)** | capability-based smart contracts | the agoric computing vision, operational |
| **ECMAScript TC39** | Miller's role in the Promise, async/await, and security specifications | **JavaScript's Promise IS Gold's promise system, standardised** |

### The capability model (the deep connection)

Miller's capability model is the mature version of Xanadu's club-
based access control, with one crucial insight:

> **If you can't name it, you can't access it.**

Capabilities are unforgeable references — not permission lists
attached to identities, but the references themselves ARE the
permissions. Possession of the capability is the authority. This
maps to xudanu's design:

| Xudanu concept | Capability-model reading |
|---|---|
| Tumbler addresses | unforgeable references to content |
| Clubs | capability scopes — you can only access works your club holds |
| Ed25519 signatures | proof of capability possession |
| Federation keys | cross-server capability delegation |
| The MCP agent-club recipe (MCP guide §"Scoping") | least-privilege by capability, not by ACL |

The deeper alignment: **tumblers as unforgeable addresses ARE
capabilities**. If you don't know the tumbler, you can't reference
the content. If you do know it, the content-hash verification proves
you're looking at the right thing. This is capability-security
through content addressing.

### Sources to spelunk (added to the queue)

| Source | What it holds | Where |
|---|---|---|
| **erights.org** | E language docs, papers, "waldo" and other distributed-systems essays | Miller's personal site |
| **"Robust Composition" thesis** (2006) | unified access+concurrency theory; ~300 pages | freely available |
| **Agoric papers** (with Drexler) | computational markets, resource pricing, agent economies | various archives |
| **"The Open Society and Its Media"** (1994) | detector concept + broader media model | already partially known (FR-80) |
| **TC39 Promise specification** | the Gold promise system, standardised | ECMA archives |

### The quiet stunner

JavaScript's `Promise` and `async/await` — used by every web
developer on Earth — are the standardised descendants of the
promise layer Mark Miller designed for Xanadu's front-end/back-end
protocol. He didn't just continue the ideas in academia; he got
them into the world's most widely deployed programming language.

The same arc holds for capabilities: what started as Xanadu's club
model became E's capability system, which influenced JavaScript's
module system, and is now the basis of Agoric's smart-contract
platform. The Gold model's access-control thinking has been
shipping in production for decades — just under different names.


The complete list of structural primitives from the edition module,
for use in the modelling completeness matrix (FR-91's sibling):

### Container primitives (RangeElement variants)
Text, Data, Blob, Edition, Work, Label{inner}, PlaceHolder, IDHolder,
Overlay, Transclusion, StructuralTransclusion, Virtual{spec}, Set{spans},
Path{spans}

### Connection primitives
HyperLink{types, ends}, HyperRef (single), HyperRefKind::Multi (gathered),
HyperRefKind::LinkAttachment (link-about-link), Path (label-path context),
CrossServerRef (federation)

### Organisational primitives
Exhibition (gathers), Trail, Endorsement, Label, Bundle/CompoundEdition,
Derived

### Address/algebra primitives
Tumbler, IntegerSpace, RealSpace, SequenceSpace, CrossSpace, CrossNSpace,
Filter, Enfilade/Canopy, Lattice

### Composition recipes (how they combine)
1. Nesting without schema: Label + Edition
2. Gathered evidence: Set + HyperLink + Endorsement
3. Derived views: Virtual + Trail + Set (zero storage, deterministic)
4. Compound documents: CompoundEdition + StructuralTransclusion + Image
5. Argument maps: Path + Label + HyperLink (reasoning chains)
6. Version-annotated models: ent DAG + Label + Endorsement
7. Spatial models: CrossSpace + Blob + Label

Each recipe costs approximately zero storage because content is
always held by reference, pinned by crum, resolved on demand.
