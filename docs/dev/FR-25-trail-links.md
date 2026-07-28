# FR-25: Trail Link Type & Cross-Server Trails

> **Status:** Phase 1 (local trail links) — in development
> **Depends on:** FR-4 (Typed Links), FR-6 (Cross-Server), FR-20 (Trails)

## Motivation

Trails are curated journeys through the docuverse. Currently, trails exist as
metadata (a sequence of work stops) with no way to link to them from document
text. A reader encountering an interesting passage should be able to discover
"this passage is part of the 'Hypertext History' trail" and follow that trail
through other documents.

This implements Ted Nelson's original Xanadu concept of **trails** — paths
through the docuverse that guide readers across documents and servers.

## Design

### Phase 1: Trail Link Type (Local)

Add type 7 ("Trail") to the existing 6 link types:

| Type ID | Name | Color | Use Case |
|---|---|---|---|
| 1 | Comment | Blue | Annotative remark |
| 2 | Reference | Green | Citation/source |
| 3 | Disagreement | Red | Counter-argument |
| 4 | Quotation | Purple | Direct quote |
| 5 | See Also | Amber | Related work |
| 6 | Web Link | Teal | External URL |
| **7** | **Trail** | **Orange (#f97316)** | **Part of a curated trail** |

**Creating a Trail link:**
1. User selects text in a document
2. Opens Link Creator → selects "Trail" type
3. Chooses from existing trails (dropdown of trail names)
4. Link is created between the document passage and the trail

**Clicking a Trail link:**
1. Opens the Trails panel with the linked trail selected
2. Shows the trail's stops with navigation (next/previous)
3. Highlights the current document's position in the trail

**Storage:** Trail links use the existing link infrastructure (HyperLink with
type 7). The trail_id is stored in the link's metadata/payload.

### Phase 2: Trail Stops with Server Addresses

Extend trail stops from `{work_id, start, end}` to include server origin:

```json
{
  "work_id": "0x49c",
  "start": 100,
  "end": 200,
  "server_domain": "alice.example.com",
  "content_hash": "b4589ddac9...",
  "note": "Key passage about transclusion"
}
```

- `server_domain` defaults to the local server for existing trails
- `content_hash` (BLAKE3) is captured at creation time for verification
- Enables cross-server trail following (Phase 3)

### Phase 3: Cross-Server Trail Following

A trail on Server A references stops on Servers B, C, D:

```
Reader on Server A follows trail:
  Stop 1 → Server A, work 0x49c  (local, instant)
  Stop 2 → Server B, work 0x103  (fetch via /api/public/work/103)
  Stop 3 → Server C, work 0x1a2  (fetch via /api/public/work/1a2)
```

**Content fetching:**
- Each remote stop is fetched via the existing FR-6 public content API
- Content is verified against the stored BLAKE3 hash
- If hash mismatches → content was modified, reader is warned
- If server is unreachable → fall back to cached snapshot (Phase 4)

**Permissions:**
- Trail stops can only reference **public** works on remote servers
- Private works require the reader to authenticate on the remote server
- Future: federation tokens for cross-server private access

### Phase 4: Content Snapshots

When a trail creator adds a remote stop, Server A caches the content:

```json
{
  "work_id": "0x103",
  "server_domain": "bob.example.com",
  "start": 50,
  "end": 150,
  "text": "The cached passage text...",
  "content_hash": "b4589ddac9...",
  "captured_at": 1784505702,
  "verified": true
}
```

Benefits:
- Trail works even if the remote server goes offline
- Reader doesn't need to wait for cross-server fetch on each stop
- Hash verification ensures authenticity
- Similar to transclusion caching (FR-6 backfollow index)

**Staleness:** The cached content may differ from the current version if the
remote document was edited. The trail shows "captured on {date}" with a link
to fetch the live version.

### Phase 5: Trail Publishing & Discovery

- Trails can be **published** (visible to all users) or **private** (owner only)
- Published trails appear in the trail directory
- Trails can be **tagged** with concepts (FR-22 auto-tag)
- Trails can be **endorsed** by other users (FR-3 federation)
- Cross-server trail discovery via server directory (FR-6)

### Phase 6: Trail Branching (Future)

Trails can branch at decision points:
- Stop 5 has two continuations: "Technical path" and "Historical path"
- Reader chooses which branch to follow
- Creates a tree/graph structure, not just a linear sequence
- Aligns with Xanadu's "zig-zag" linking concept

## Wire Protocol Changes

### Phase 1

| Op | Code | Description |
|---|---|---|
| `LinkTypeRegister` (existing) | — | Register type 7 "Trail" |
| `TrailLinkCreate` | 0x0351 | Create link between passage and trail |
| `TrailLinkGet` | 0x0352 | Get trail associated with a link |

### Phase 2+

| Op | Code | Description |
|---|---|---|
| `TrailStopAddRemote` | 0x0353 | Add a stop referencing a remote server |
| `TrailContentFetch` | 0x0354 | Fetch content for a remote trail stop |
| `TrailPublish` | 0x0355 | Publish a trail for discovery |
| `TrailSearch` | 0x0356 | Search published trails across servers |

## Persistence

| Data | Location | Format |
|---|---|---|
| Trail links | Existing link store | HyperLink with type 7 |
| Trail stop server refs | TrailManifestEntry (FR-20) | Extended with server_domain |
| Content snapshots | Chunk store | BLAKE3-addressed, like blobs |
| Published trails | SocialSection | TrailMetadata with visibility |

## Security Considerations

1. **Content verification**: Every remote stop is verified via BLAKE3 hash.
   Modified content is detected and the reader is warned.

2. **Trail integrity**: Trail links are signed by the creator (existing link
   provenance). Modifying a trail's stops requires edit access.

3. **No content copying**: Trail stops reference content by address, not by
   copy. The original content stays on the origin server (transclusion model).

4. **DDoS protection**: Cross-server content fetches are rate-limited via the
   existing FR-6 rate limiting (`backlink_rate_ip`, `backlink_rate_server`).

5. **Snapshot staleness**: Cached content is marked with capture date. Readers
   are informed when viewing potentially stale content.

## Alignment with Xanadu Principles

| Principle | How trails comply |
|---|---|
| Invariant addresses | Trail stops use tumblers (server.work_id.start.end) |
| Content reuse, not copying | Stops reference content by address |
| Provenance | Every stop links to its source with hash verification |
| Two-way links | Trail links are bidirectional (document ↔ trail) |
| Transcopyright | Content stays on origin server; trail is metadata |

## Acceptance Criteria

### Phase 1 (Local)
- [ ] Type 7 "Trail" appears in link type picker
- [ ] User can create a Trail link from a document passage to an existing trail
- [ ] Clicking a Trail link opens the Trails panel with the trail selected
- [ ] Trail links survive span migration (text edits don't break them)
- [ ] Trail links show in RelatedFooter and Connections panel

### Phase 2 (Server Addresses)
- [ ] Trail stops include server_domain field
- [ ] Local stops have server_domain = current server
- [ ] Trail stop schema is backward-compatible (missing server_domain → local)

### Phase 3 (Cross-Server)
- [ ] Remote stop content fetched via /api/public/work/{id}
- [ ] Content verified against stored BLAKE3 hash
- [ ] Hash mismatch shows warning to reader
- [ ] Server unreachable shows fallback message

### Phase 4 (Snapshots)
- [ ] Remote stop content cached at creation time
- [ ] Cache survives server restart (persisted to chunk store)
- [ ] Stale content shows capture date with "fetch live version" option
- [ ] Offline remote server falls back to cached content
