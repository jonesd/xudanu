# FR-6: Linked Independent Servers via Tumbler Resolution

## Status: Proposed

## Relation to existing specs

- **Replaces FR-3** (federation activation) as the default multi-server model
- **FR-3** remains available for organizations that want full-data replication clusters
- **FR-4** (links/backlinks) works unchanged — links can reference cross-server tumblers
- **FR-5** (attestation/provenance) works unchanged — each server signs independently
- **FR-1/FR-2** (identity/verification) work per-server

## Motivation

The federation cluster model (FR-3) creates a shared-data plane where every peer
can read, write, and inject content on every other server. Our security audit
(found in `docs/federation-trust-analysis.html`) identified 14 authorization
gaps. The cluster model also requires 3+ servers minimum, consensus protocols
(PBFT), and significant operational overhead.

The original Xanadu concept was different: a **docuverse** of independent servers
connected by permanent references, not a shared database. Tumbler addresses
(`server.work.edition.position.element`) were designed exactly for this — a
global address space where each server owns its namespace.

FR-6 implements this original vision.

---

## 1. Overview

Each Xudanu server is **sovereign**. It owns its content, signs its own
provenance, and controls its own access policies. Servers reference each other's
content via tumbler addresses. The referencing server stores a cached snapshot;
the original server remains the authoritative source.

```
Server 1 (alice.example.com)          Server 2 (bob.example.com)
┌──────────────────────────┐          ┌──────────────────────────┐
│ Owns: works 1, 2, 3     │          │ Owns: works 5, 8, 9      │
│ Tumbler namespace: 1.*   │          │ Tumbler namespace: 2.*    │
│                          │  cache   │                           │
│ Alice transcludes from   │ <──────  │ Bob's "Moby Dick Analysis"│
│ Bob's work (tumbler 2.5) │  fetch   │ (tumbler 2.5.3.10+)      │
│                          │          │                           │
│ Stores: tumbler + hash   │          │ Signs content with its    │
│ + excerpt + provenance   │          │ own Ed25519 key           │
└──────────────────────────┘          └──────────────────────────┘
```

**No server-to-server replication. No consensus. No shared writes.**

---

## 2. Tumbler Addressing

### 2.1 Address structure

A tumbler is a hierarchical dotted address:

```
server . work . edition . position . element
  2    .   5  .    3    .    10    .    7
```

| Level | Meaning | Who assigns |
|-------|---------|-------------|
| 1 — server | Which server hosts the content | Server directory (Section 3) |
| 2 — work | Which work on that server | The host server |
| 3 — edition | Which revision of the work | The host server |
| 4 — position | Character position within the edition | The O-tree |
| 5 — element | Element within a multi-element position | The O-tree |

### 2.2 Zeros as separators

Tumblers use `0` as a level separator in their internal representation:

```
Dotted:    2.5.3.10.7
Internal:  [2, 0, 5, 0, 3, 0, 10, 0, 7]
```

This is already implemented in `space/sequence.rs`.

### 2.3 Resolution rule

A tumbler is resolved by:

1. Extract the server number (first component)
2. Look up the server in the directory (Section 3)
3. Fetch the work/edition/position from that server's public API
4. Verify the BLAKE3 hash matches what was recorded at reference-creation time

### 2.4 Prefix queries

Tumblers support hierarchical prefix matching:

- `2.*` — all content on server 2
- `2.5.*` — all editions of work 5 on server 2
- `2.5.3.*` — all positions in edition 3 of work 5

Prefix queries are used for:
- "Show me all references to this server"
- "Show me all references to this work"
- Server-level content inventories

Already implemented in `SequenceRegion::prefixed_by()`.

---

## 3. Server Directory

### 3.1 Well-known endpoint

Each server publishes its identity at a standard URL:

```
GET https://<server-address>/.well-known/xudanu-server.json
```

```json
{
  "protocol_version": 1,
  "server_id": 2,
  "address": "bob.example.com",
  "port": 8080,
  "verifying_key_ed25519": "9a8b7c6d5e4f3a2b...",
  "name": "Bob's Literature Server",
  "description": "Analysis and commentary on classic literature",
  "public_content": true,
  "started_at": "2026-07-05T12:00:00Z",
  "stats": {
    "work_count": 42,
    "revision_count": 318
  }
}
```

The `verifying_key_ed25519` is the server's long-term identity key. All content
served by this server is signed with the corresponding private key.

### 3.2 Local server directory

Each server maintains a `server_directory.json` in its data directory:

```json
{
  "servers": {
    "1": {
      "address": "alice.example.com:8080",
      "verifying_key": "efdf23c44d7c29a3...",
      "name": "Alice's Server",
      "trusted": true,
      "discovered": "manual",
      "last_seen": "2026-07-05T14:30:00Z"
    },
    "2": {
      "address": "bob.example.com:8080",
      "verifying_key": "9a8b7c6d5e4f3a2b...",
      "name": "Bob's Literature Server",
      "trusted": true,
      "discovered": "referral",
      "referred_by": "1",
      "last_seen": "2026-07-05T14:25:00Z"
    },
    "3": {
      "address": "unknown.example.com:8080",
      "verifying_key": "unknown",
      "trusted": false,
      "discovered": "content-match",
      "last_seen": null
    }
  }
}
```

### 3.3 Discovery methods

| Method | How it works | Trust level |
|--------|-------------|-------------|
| **Manual** | Operator adds server to directory | Operator-chosen |
| **Referral** | Server A shares Server B's directory entry when resolving a reference chain | Inherits referrer's trust |
| **Content match** | BLAKE3 fingerprint matches content from an unknown server | Low — verify key independently |
| **Registry** | Opt-in public registry lists participating servers | Registry-curated |

### 3.4 Trust is independent per server

Each server decides independently which other servers to trust:

```
Server 1 trusts Server 2  →  verifies Server 2's Ed25519 signatures
Server 1 distrusts Server 3  →  shows content from Server 3 with "UNVERIFIED" warning
Server 1 trusts Server 4  →  verifies Server 4's signatures
```

There is no global trust state. No consensus. No voting.

---

## 4. Cross-Server Transclusion

### 4.1 Creating a cross-server reference

When Alice selects text from Bob's published work and transcludes it into her
document:

1. Alice's client fetches the content from Server 2 (if not already cached)
2. Client computes BLAKE3 fingerprints of each element
3. Client stores a **reference manifest** on Server 1:

```json
{
  "tumbler": "2.5.3.10.7",
  "blake3": "a3b1c2d4e5f6...",
  "span_fingerprint": "b2c3d4e5f6a7...",
  "excerpt": "The whale represents humanity's struggle...",
  "author": "Bob",
  "author_key": "9a8b7c6d...",
  "server_sig": "...",
  "fetched_at": 1783130786,
  "server_address": "bob.example.com:8080"
}
```

4. The reference manifest is stored as link metadata on Server 1
5. Server 1 signs the reference manifest with its own key (proving Alice created it)

### 4.2 Rendering a cross-server transclusion

When Alice's document is opened:

1. Client finds the reference manifest
2. **If content is cached locally** (blob store): render from cache, verify BLAKE3 matches
3. **If content is not cached**: fetch from Server 2, verify, cache, render
4. **If Server 2 is offline**: render the stored excerpt (Section 6)
5. Display provenance: "Transcluded from [Server 2 / Bob's Literature Server]"

### 4.3 Span migration

When Alice edits her document around a cross-server transclusion, the span
positions shift. The link span migration system (already implemented in
`migrate_link_spans_for_delta`) handles this — it tracks the link's position
and adjusts it when text is inserted/deleted before the transclusion point.

The tumbler address of the *source* content does not change — it always points
to the original on Server 2. Only the *position within Alice's document*
shifts.

---

## 5. Provenance

### 5.1 Per-server signing

Each server signs its own content independently:

- Server 2 signs Bob's work with Server 2's Ed25519 key
- Server 1 signs Alice's work with Server 1's Ed25519 key
- Alice's transclusion of Bob's content carries BOTH:
  - Bob's original provenance (signed by Server 2)
  - Alice's transclusion action (signed by Server 1)

### 5.2 Cross-server provenance chain

```
Alice's span [100, 150) on Server 1
  └── transcluded_by: Alice (Server 1 key)
      └── source: tumbler 2.5.3.10.7 (Server 2)
          └── author: Bob (Server 2 key)
              └── original_sig: Server 2's Ed25519 signature
```

The provenance chain is:
1. Server 2 signed the original content (Bob wrote it)
2. Server 1 signed the transclusion action (Alice quoted it)
3. The BLAKE3 hash links them (the excerpt matches the original)

### 5.3 Verification

A verifier (human or `xudanu-cli verify-report`) can independently check:

1. Server 2's signature on the original content → verify against Server 2's published key
2. Server 1's signature on the transclusion → verify against Server 1's published key
3. BLAKE3 hash of the excerpt → matches the original content fingerprint
4. Attribution log chain on each server → tamper-evident audit trail

### 5.4 PROV-JSON export

The W3C PROV-JSON export (already implemented) represents cross-server
provenance using standard PROV relations:

```json
{
  "wasDerivedFrom": {
    "_:1": {
      "prov:generatedEntity": "xudanu:span:1.1:100:150",
      "prov:usedEntity": "xudanu:doc:2.5",
      "xudanu:tumbler": {"$": "2.5.3.10.7", "type": "xsd:string"},
      "xudanu:derivationType": {"$": "transclusion", "type": "xsd:string"}
    }
  }
}
```

---

## 6. Caching and Offline Behavior

### 6.1 Three-tier cache

| Tier | What's stored | Lifetime | Location |
|------|--------------|----------|----------|
| **Excerpt** (always) | The text excerpt + metadata at reference-creation time | Permanent | Server 1 link metadata |
| **Content cache** (on fetch) | Full fetched content keyed by BLAKE3 hash | Permanent (until GC) | Server 1 blob store |
| **Session cache** (in-memory) | Recently fetched content for fast rendering | Session | Client browser |

### 6.2 When Server 2 is online

```
Client requests transclusion
  → Check session cache → hit? render
  → Check content cache (blob store) → hit? verify hash, render
  → Fetch from Server 2 → verify hash → cache → render
```

### 6.3 When Server 2 is offline

```
Client requests transclusion
  → Check session cache → hit? render (stale indicator)
  → Check content cache → hit? render with "cached from Server 2 (offline)"
  → Check excerpt in link metadata → render with "cached excerpt (Server 2 offline)"
  → No cache available → show placeholder:
      "Content from Server 2 (bob.example.com) — temporarily unavailable"
      Title: "Moby Dick Analysis" by Bob
      Tumbler: 2.5.3.10.7
```

### 6.4 When Server 2 is permanently gone

Cached excerpts are **permanent proof** that the content existed:

- The excerpt text + BLAKE3 hash + Server 2's signature = cryptographic evidence
- Even if Server 2 is decommissioned, the provenance chain is verifiable
- The `xudanu-cli verify-report` command can verify the excerpt's signature
  offline using the stored verifying key

### 6.5 When Server 2 changes content

| Change | What happens |
|--------|-------------|
| Bob edits the work | New edition on Server 2. Alice's reference still points to the original (by hash). Client may show "newer edition available" |
| Bob deletes the work | Server 2 returns 404. Cached excerpt renders with "content deleted on origin server" |
| Bob reverts to original | Content matches hash again. Fresh fetch works normally |
| Bob serves tampered content | BLAKE3 hash mismatch. Client rejects fresh fetch, falls back to cache |

### 6.6 Garbage collection of cache

Cached cross-server content is subject to normal GC rules:

- Content referenced by an active link is never collected
- Content no longer referenced by any link can be collected after a grace period
- The excerpt in link metadata is NEVER collected (it's part of the link, not the cache)

---

## 7. Network Topology at Scale

### 7.1 Hundreds of servers

```
                    ┌─────────────────┐
                    │  Registry (opt) │
                    │  Lists servers  │
                    └────────┬────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
    ┌─────▼─────┐     ┌─────▼─────┐     ┌─────▼─────┐
    │ Server 1  │     │ Server 2  │     │ Server 3  │
    │ Alice     │────▶│ Bob       │◀────│ Carol     │
    │ Lit crit  │     │ Classics  │     │ Poetry    │
    └─────┬─────┘     └─────┬─────┘     └─────┬─────┘
          │                  │                  │
          │     ┌────────────┼────────────┐    │
          │     │            │            │    │
    ┌─────▼───┐ │    ┌──────▼───┐  ┌─────▼──┐ │
    │ Server 4│ │    │ Server 5 │  │Server 6│ │
    │ Dave    │ │    │ Eve      │  │Frank   │ │
    │ History │◀┘    │ Science  │  │Art     │◀┘
    └─────────┘      └──────────┘  └────────┘
```

Each server:
- Maintains its own server directory (who it knows about)
- Serves its own public content via HTTP/WS
- Caches referenced content from other servers
- Signs its own content with its own Ed25519 key

### 7.2 No central bottleneck

- **No central server** required (registry is optional)
- **No consensus rounds** that all servers must participate in
- **No global membership list** that must be synchronized
- **No all-to-all communication** — each server only contacts servers it references

A server with 10 cross-server references only needs to know about those 10
servers. It doesn't need to know about all 500 servers in the network.

### 7.3 Directory propagation

Server directories propagate through normal usage:

1. Alice references content from Bob (Server 2)
2. Server 1's directory now includes Server 2
3. Carol references Alice's document (Server 1)
4. Server 3's directory now includes Server 1
5. If Carol follows the transclusion chain, Server 3 discovers Server 2

This is organic growth — the network builds itself through references. Like the
web: you discover new sites by following links.

### 7.4 Cost model

| Server type | Hardware | Monthly cost | Users |
|-------------|----------|-------------|-------|
| Personal | $5 VPS (1 vCPU, 1 GB) | $5 | 1-5 |
| Small team | $10 VPS (2 vCPU, 4 GB) | $10 | 5-30 |
| Organization | $40 VPS (4 vCPU, 16 GB) | $40 | 30-200 |
| Large org | Dedicated server | $100+ | 200+ |

No minimum server count. A single $5 VPS is a fully functional Xudanu server
that can reference and be referenced by any other server in the network.

---

## 8. Hostile Machines

### 8.1 Threat model

Any server can join the network. Some may be hostile. The system must be secure
by default against:

| Attack | Defense |
|--------|---------|
| Serve fake content | BLAKE3 hash mismatch → client rejects |
| Forge another server's signatures | Ed25519 verification → fails |
| Serve modified versions | Original hash in reference → mismatch detected |
| Serve content with fake provenance | Signature verification against published key → fails |
| Harvest user data | No cross-server auth — only public content is served |
| Inject content onto other servers | No write access across servers — impossible by design |
| Sybil attack (many fake servers) | Each server curates its own directory — bad servers get delisted |
| Man-in-the-middle | TLS + Ed25519 content signatures + BLAKE3 hashes |
| Denial of service | Cached excerpts survive server downtime; no persistent connections needed |

### 8.2 Untrusted server display

When content is fetched from an untrusted server (one whose key is not in the
TrustedServerRegistry), the client displays a warning:

```
┌──────────────────────────────────────────────┐
│ ⚠ UNVERIFIED CONTENT                         │
│                                               │
│ This content was fetched from Server 99       │
│ (unknown.example.com), which is not in your   │
│ trusted server registry. The content cannot   │
│ be independently verified.                    │
│                                               │
│ [Trust this server]  [Show anyway]  [Hide]   │
└──────────────────────────────────────────────┘
```

### 8.3 Server reputation (community-managed, optional)

Servers can build reputation organically:

- **Referral chains**: if trusted Server 1 references Server 2, Server 2 gains
  credibility
- **Content quality**: servers with high-quality, well-attributed content get
  referenced more often
- **Uptime**: servers with consistent availability get cached less (reducing
  staleness)
- **Opt-in reputation services**: third parties can publish server reviews/ratings

No built-in reputation system — this is left to the community, like the web.

### 8.4 What a hostile server CANNOT do

| Action | Why it fails |
|--------|-------------|
| Read private content on other servers | No cross-server auth; only public content is served |
| Modify content on other servers | No write path exists between servers |
| Forge provenance on other servers' content | Each server signs independently |
| Take down the network | No central point of failure |
| Corrupt the tumbler namespace | Server IDs are self-assigned but content is verified by hash |
| Spam the network | Each server curates its own directory; no broadcast mechanism |

### 8.5 What a hostile server CAN do

| Action | Mitigation |
|--------|-----------|
| Serve low-quality content | Users don't reference it; it gets no inbound links |
| Go offline frequently | Cached excerpts on referencing servers remain available |
| Serve stale content | BLAKE3 verification shows it doesn't match the referenced hash |
| Claim to be another server | Key verification via well-known endpoint or referral chain |

---

## 9. Comparison with Cluster Model (FR-3)

| Aspect | FR-3 Cluster | FR-6 Linked |
|--------|-------------|-------------|
| Data sharing | Full replication of all content | Reference + cache specific content |
| Write access | Any peer can write to any server | Each server only accepts its own writes |
| Consensus | PBFT required | None |
| Min servers | 3-4 for Byzantine tolerance | 1 (standalone works) |
| Trust model | All trust all | Each trusts independently |
| Security surface | Large (14 gaps found) | Minimal (read-only public API) |
| Offline resilience | CRDT convergence on reconnect | Cached excerpts survive indefinitely |
| Joining | PBFT vote required | Start serving + publish well-known |
| Leaving | Membership removal protocol | Go offline — done |
| Cost | 3+ servers required | 1 server sufficient |
| Complexity | High (federation.rs: 4,419 LOC) | Low (~300 LOC new code) |
| Xanadu alignment | Low (shared database) | High (tumbler docuverse) |

### When to use which

| Use case | Recommended model |
|----------|------------------|
| Single user | FR-6 (single server) |
| Small team | FR-6 (single server) |
| Cross-org collaboration | FR-6 (linked servers) |
| Publishing to the docuverse | FR-6 (any server, referenced by others) |
| Large org needing redundancy | FR-3 (cluster with private data) |
| Government/legal requiring multi-witness | FR-3 (federation witnessing) |

FR-6 is the **default**. FR-3 is an **optional upgrade** for specific use cases.

---

## 10. Implementation Plan

### 10.1 What already exists

| Component | Location | Status |
|-----------|----------|--------|
| Tumbler addressing | `space/sequence.rs` | ✅ Complete |
| Tumbler prefix queries | `SequenceRegion::prefixed_by()` | ✅ Complete |
| BLAKE3 content fingerprinting | `edition/range_element.rs` | ✅ Complete |
| Ed25519 signing/verification | `edition/provenance.rs`, `crypto/sign.rs` | ✅ Complete |
| TrustedServerRegistry | `crypto/server_identity.rs` | ✅ Complete |
| Link creation with excerpts | `edition/links.rs` | ✅ Complete |
| Span migration | `server.rs: migrate_link_spans_for_delta` | ✅ Complete |
| Transclusion detection | `edition/transclusion.rs` | ✅ Complete |
| Attribution log | `transport/attribution_log.rs` | ✅ Complete |
| PROV-JSON export | `server.rs: federation_export_prov_json` | ✅ Complete |
| Public content read API | `/api/content`, `/health` routes | ✅ Partial |

### 10.2 What needs building

| Component | Effort | Description |
|-----------|--------|-------------|
| Well-known endpoint | ~30 LOC | `GET /.well-known/xudanu-server.json` |
| Server directory file | ~50 LOC | `server_directory.json` read/write |
| Cross-server content fetch | ~80 LOC | Client-side tumbler resolution + BLAKE3 verify |
| Reference manifest in links | ~40 LOC | Store tumbler + hash + excerpt in HyperRef |
| Cache management | ~50 LOC | Store/lookup fetched content by hash |
| Untrusted server warning UI | ~40 LOC | Frontend banner for unverified content |
| Server directory management UI | ~60 LOC | Add/remove/trust servers in settings |

**Total: ~350 lines of new code**, reusing all existing infrastructure.

### 10.3 Phased delivery

**Phase 1: Well-known endpoint + server directory (1 day)**
- Server publishes its identity
- Server can read/write a local directory of known servers
- Manual server discovery (add by URL)

**Phase 2: Cross-server reference creation (2 days)**
- When creating a transclusion from external content, store the full reference manifest
- Link metadata includes tumbler, hash, excerpt, author, signature
- Span migration handles cross-server references

**Phase 3: Cross-server rendering + caching (2 days)**
- Client resolves tumblers by fetching from origin server
- Content cached by BLAKE3 hash in blob store
- Offline rendering from excerpt
- Provenance chain display

**Phase 4: Trust management UI (1 day)**
- Settings panel for server directory
- Trust/distrust servers
- Untrusted content warnings
- Discovery via referral

### 10.4 What this replaces from FR-3

The following FR-3 components are NOT needed for FR-6:

- `federation.rs` (4,419 LOC) — CRDT sync, membership, governance
- `federation_handler.rs` (1,798 LOC) — inbound federation transport
- `federation_active.rs` (557 LOC) — outbound dialer + sync loop
- PBFT consensus engine
- Membership OR-set CRDT
- ReconcileState / LWW register
- Federation frame encryption

These remain in the codebase as an optional feature behind a feature flag, but
are not the default multi-server mechanism.

---

## 11. Sequence Diagrams

### 11.1 Creating a cross-server transclusion

```
Alice             Server 1           Server 2
  │                  │                   │
  │ Select text      │                   │
  │ from Bob's work  │                   │
  ├─────────────────────────────────────▶│
  │                  │   GET public      │
  │                  │   content         │
  │                  │◀──────────────────┤
  │                  │   content + sig   │
  │                  │                   │
  │                  │ Verify BLAKE3     │
  │                  │ Verify Ed25519    │
  │                  │ Cache in blob store│
  │                  │                   │
  │  "Transclude     │                   │
  │   from Bob?"     │                   │
  │◀─────────────────┤                   │
  │                  │                   │
  │ Confirm          │                   │
  ├─────────────────▶│                   │
  │                  │ Store reference:  │
  │                  │   tumbler 2.5.3   │
  │                  │   hash a3b1c2     │
  │                  │   excerpt "..."   │
  │                  │   provenance sig  │
  │                  │ Sign with S1 key  │
  │                  │                   │
  │  Done            │                   │
  │◀─────────────────┤                   │
```

### 11.2 Rendering when origin is offline

```
Alice             Server 1           Server 2
  │                  │                   │
  │ Open document    │                   │
  ├─────────────────▶│                   │
  │                  │                   │
  │                  │ Find reference    │
  │                  │ to tumbler 2.5.3  │
  │                  │                   │
  │                  │ Try fetch from S2 │
  │                  ├──────────────────▶│ × (timeout)
  │                  │                   │ (offline)
  │                  │                   │
  │                  │ Fall back to      │
  │                  │ cached excerpt    │
  │                  │                   │
  │  Document with   │                   │
  │  cached excerpt  │                   │
  │  "Server 2       │                   │
  │   offline"       │                   │
  │◀─────────────────┤                   │
```

### 11.3 Hundreds of servers

```
         ┌──────────────────────────────────────────────┐
         │              Tumbler Namespace               │
         │                                              │
         │  1.* ── Alice's Server (alice.example.com)  │
         │  2.* ── Bob's Server (bob.example.com)      │
         │  3.* ── Carol's Server (carol.example.com)  │
         │  ...                                        │
         │  500.* ── Zoe's Server (zoe.example.com)    │
         │                                              │
         │  Each server only knows about                │
         │  servers it has referenced or been           │
         │  referred by. No global view required.       │
         └──────────────────────────────────────────────┘

Server 42 knows about: { 1, 3, 17, 42 } (4 servers)
Server 1 knows about:  { 1, 2, 3, 5, 8, 42 } (6 servers)
Server 317 knows about: { 317, 42 } (2 servers)

Each server is independent. No coordination needed.
```

---

## 12. Open Questions

### 12.1 Server ID assignment

How does a new server get its server ID? Options:

- **Self-assigned**: operator picks a number. Collisions are harmless (content
  is verified by hash + key, not by server ID alone)
- **Content-hash derived**: server ID = first bytes of verifying key. No
  collisions, no registry needed
- **Registry-assigned**: optional registry assigns sequential IDs

**Recommendation**: self-assigned, with the verifying key as the canonical
identity. Server ID is for human convenience only.

### 12.2 Cross-server search

How do users find content across hundreds of servers?

- **Per-server search**: each server indexes its own content (already implemented)
- **Federated search**: client queries multiple known servers in parallel
- **Search index**: opt-in service that crawls public content (like a web search engine)

**Recommendation**: start with per-server search. Federated search as a Phase 2
enhancement.

### 12.3 Cross-server edit access

What if Alice wants Bob to co-edit her document?

- Alice hosts the document on Server 1
- Bob connects to Server 1 directly (as a regular user)
- No cross-server write protocol needed

If both need to host independently, they can:
- Create linked copies (each server has its own version)
- Cross-reference each other's changes via transclusion

**Not a priority** — true cross-server co-editing is an edge case.

---

## 13. References

- `docs/federation-trust-analysis.html` — security analysis of the cluster model
- `docs/dev/FR-3.md` — federation activation (cluster model)
- `docs/dev/FR-4.md` — typed bidirectional content links
- `docs/dev/FR-5.md` — attestation reports & provenance
- `docs/document-space.html` — tumbler addressing deep dive
- `docs/provenance-and-attribution.html` — per-server provenance
- `space/sequence.rs` — tumbler implementation
- `crypto/server_identity.rs` — TrustedServerRegistry
