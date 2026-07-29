# Content Gateway Proposal: Xudanu ↔ Xanadu Interoperability

> **Author:** David Jones (Xudanu)
> **Date:** July 2026
> **Status:** Proposal for discussion

## Vision

A connected docuverse where documents on Xudanu servers, Gold servers,
and Green servers can reference each other's content via tumblers.
Users on any implementation can follow links, transclusions, and trails
that span multiple servers and implementations.

**We don't need to agree on internals. We need to agree on content
addresses and a read API.**

## What Each Side Brings

| Xudanu | Gold/Green |
|---|---|
| Browser-based UI | Spanfilade transclusion |
| Real-time CRDT collaboration | Granfilade, poomfilade |
| LLM integration (summary, feedback, tags) | 30 years of design refinement |
| Search + graph discovery | Cosmic tumblers |
| Cross-server federation (BLAKE3) | Ted Nelson's vision |
| Transcopyright licensing | Historical content |
| Deployable in minutes | Enfilade model |

## Phase 1: Content Gateway (Week 1-2)

### Goal
Any Xudanu user can view and reference content from a Gold server.
Any Gold user can view and reference content from a Xudanu server.

### Architecture

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│   Xudanu    │         │   Gateway     │         │   Gold      │
│   Server    │◄───────►│   Protocol    │◄───────►│   Server    │
│             │  HTTP   │              │  HTTP   │             │
│  /api/      │  JSON   │              │  JSON   │  /api/      │
│  public/    │         │              │         │  public/    │
└─────────────┘         └──────────────┘         └─────────────┘
      │                                                  │
      ▼                                                  ▼
┌─────────────┐                              ┌─────────────┐
│  Xudanu     │                              │  Gold       │
│  Web UI     │                              │  Desktop UI │
│  (browser)  │                              │             │
└─────────────┘                              └─────────────┘
```

### Standard Content API (both sides implement)

**`GET /api/public/work/{id}`**

Response:
```json
{
  "api_version": 1,
  "server_identity": {
    "server_id": "hex public key",
    "server_name": "Node Alpha",
    "public_address": "alice.example.com",
    "implementation": "xudanu" | "gold" | "green"
  },
  "work_id": "0x5",
  "title": "Pride and Prejudice",
  "text": "It is a truth universally acknowledged...",
  "char_count": 423001,
  "content_hash_blake3": "b4589ddac9...",
  "revision": 3,
  "author": "Jane Austen (historical)",
  "license": "public-domain",
  "span_provenance": [...],
  "links": [
    {
      "target_tumbler": "bob.example.com.0x10.1.0.0",
      "target_hash": "abc123...",
      "link_type": "reference",
      "excerpt": "related passage text"
    }
  ]
}
```

**`GET /.well-known/xanadu-server.json`**

```json
{
  "api_version": 1,
  "implementation": "xudanu",
  "server_id": "hex public key",
  "server_name": "Node Alpha",
  "public_address": "alice.example.com",
  "content_api": "/api/public/work/{id}",
  "supported_features": ["content", "links", "trails", "search"],
  "hash_algorithm": "blake3"
}
```

### Tumbler Format

**Unified tumbler:** `server_domain.work_id.revision.char_start-char_end`

Examples:
- `"alice.example.com".0x5.3.0-423001` — full work
- `"alice.example.com".0x5.3.100-200` — passage
- `"gold.xanadu.net".0x12.1.0-5000` — Gold work

This is compatible with:
- Xudanu's existing DNS-anchored tumblers (just add revision + range)
- Gold's cosmic tumblers (just add a server prefix for routing)

### Implementation on Xudanu Side

Already have:
- `/api/public/work/{id}` endpoint
- `/.well-known/xudanu-server.json`
- `CrossServerRef` with tumblers + BLAKE3
- `resolve_cross_server_ref()` fetches remote content

Need to add:
- Revision + char range in tumbler format
- Generic HTTP client for fetching from Gold servers
- Content hash verification for cached content
- Link resolution across implementations

### Implementation on Gold Side

Roger needs to add:
- A simple HTTP server (or adapter to existing server)
- `/api/public/work/{id}` returning the JSON above
- `/.well-known/xanadu-server.json`
- That's it — no protocol changes needed

## Phase 2: Link Exchange (Week 3-4)

### Goal
A user on Xudanu creates a link from their document to a passage
in a Gold document. The link uses a tumbler + content hash.

### Flow

1. Xudanu user selects text → clicks "Link" → chooses "Remote server"
2. Enters Gold server address + work ID
3. Xudanu fetches the Gold work via `/api/public/work/{id}`
4. User selects target passage
5. Link stored as `CrossServerRef` with:
   - `tumbler: "gold.xanadu.net".0x12.1.100-200`
   - `content_hash: "blake3:abc123..."`
   - `server_address: "gold.xanadu.net"`
6. When anyone clicks the link, Xudanu fetches the content from Gold
7. Content verified via BLAKE3 hash — tampering impossible

### Benefit
The docuverse becomes navigable. Links work across implementations
without either side changing their internal data model.

## Phase 3: Trail Sharing (Week 5-6)

### Goal
A trail on Xudanu includes stops on Gold (and vice versa).

### Flow

1. User creates a trail on Xudanu
2. Adds a remote stop: server="gold.xanadu.net", work=0x12, range=100-200
3. Trail stop stores `server_domain` field
4. When following the trail, each stop is fetched from its origin server
5. Content verified by hash

Already implemented in Xudanu (FR-25 Phase 2). Just needs Gold
to expose content via the gateway API.

## What This Does NOT Require

- No CRDT sync between implementations
- No FeBe protocol
- No enfilade/spanfilade translation
- No shared data structures
- No shared transaction model
- No shared UI

Each implementation keeps its internals. They communicate only through
the content gateway API.

## Success Criteria

- [ ] Xudanu user can reference a Gold work by tumbler
- [ ] Gold user can reference a Xudanu work by tumbler
- [ ] Content is verified by hash (tampering detected)
- [ ] Links work cross-implementation
- [ ] Trails span multiple implementations
- [ ] Server discovery via `/.well-known/xanadu-server.json`

## Open Questions

1. **Hash algorithm**: BLAKE3 (Xudanu) vs SHA-256 (common). Propose
   supporting both, with `hash_algorithm` field in server identity.

2. **Revision format**: Xudanu uses sequential revision numbers. Gold
   uses edition/version IDs. Propose using opaque revision IDs that
   are implementation-specific, with `latest` as a special value.

3. **Authentication**: Should cross-server content fetches require
   authentication? Propose: public works are freely accessible,
   private works require server-to-server auth tokens.

4. **Caching**: Should the gateway cache remote content? Propose:
   yes, with hash verification. Cache entries expire after 24 hours
   or when origin server reports a new revision.

## Next Steps

1. Xudanu: finalize the content API + tumbler format (this week)
2. Roger: add REST adapter to Gold (his timeline)
3. Both: test cross-references between implementations
4. Document the standard for other implementations to join

---

*This proposal is open for discussion. The goal is a standard that
any Xanadu-inspired implementation can adopt — not a proprietary
protocol. The more implementations that join, the richer the docuverse.*
