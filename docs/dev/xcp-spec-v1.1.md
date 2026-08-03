# XCP — Cross-server Content Protocol

> **Version:** 1.1-draft
> **Status:** Open Standard for Discussion
> **License:** Apache 2.0 (this specification); implementations may use any license
> **Repository:** https://github.com/jonesd/xcp

## Purpose

An open standard for verifiable, cross-server content references. Any
implementation can publish content that any other implementation can
discover, retrieve, verify, and reference — with cryptographic proof
of authenticity and integrity.

XCP realizes the vision of a connected docuverse where content on any
server can reference content on any other, with attribution and
verification preserved end-to-end. The protocol draws on Ted Nelson's
Xanadu project (1960–present) and the open-sourced Udanax Gold
codebase, while remaining implementation-agnostic: any system that
serves text content can conform.

## Design Principles

1. **Implementation-agnostic** — no mandated data model, storage
   format, or internal architecture. Works with CRDTs, enfilades,
   relational databases, flat files, or anything else.
2. **Content-addressed** — all content verified by BLAKE3 hash.
   Tampered content is rejected. Version drift is detected.
3. **Read-only first** — content discovery and retrieval require no
   write access to the source server.
4. **Federated trust** — each server decides which servers to trust.
   No central registry, no certificate authority.
5. **Minimal surface** — two required endpoints, one identity file.
   Optional features layer on top.
6. **Backward compatible** — v1.1 adds features; v1.0 conformant
   servers remain conformant. Consumers MUST ignore unknown fields.

## Conformance

An implementation **conforms to XCP v1.1 Core** if it provides:

- [ ] `GET /.well-known/xcp-server.json` — Server Identity (§1)
- [ ] `GET /api/public/work/{id}` — Content Retrieval (§2)
- [ ] BLAKE3 content hashing (§3)
- [x] Tumbler address format (§4)

Optional features (v1.1 additions marked with **NEW**):

- [ ] `GET /api/public/work/{id}/range/{start}/{end}` — Passage Retrieval (§2.2)
- [ ] `POST /api/backlink-notify` — Backlink Notification (§5)
- [ ] `GET /api/search?q={query}` — Content Search (§6)
- [ ] `POST /api/webhook/subscribe` — **NEW** — Change Subscription (§7)
- [ ] `Accept` header content negotiation — **NEW** — Rich Content Types (§8)
- [ ] `Range` header pagination — **NEW** — Large Work Streaming (§9)
- [ ] `GET /.well-known/webfinger` — **NEW** — Discovery via WebFinger (§10)

---

## 1. Server Identity

### `GET /.well-known/xcp-server.json`

Every XCP server MUST publish a JSON document at this path.

**Response:**

```json
{
  "protocol": "xcp",
  "protocol_version": 1.1,
  "implementation": "string",
  "implementation_version": "string",
  "server_name": "string",
  "server_description": "string",
  "public_address": "domain:port",
  "server_id": "hex-encoded-ed25519-public-key",
  "tumbler_prefix": "\"domain:port\"",
  "content_api": "/api/public/work/{id}",
  "hash_algorithm": "blake3",
  "supported_features": ["content", "range", "links", "search", "webhooks"],
  "content_types": ["text/plain", "text/markdown"],
  "public_content": true,
  "started_at": 1784505702,
  "xcp_extensions": []
}
```

**Required fields:**

| Field | Description |
|---|---|
| `protocol` | MUST be `"xcp"` |
| `protocol_version` | MUST be `1` or `1.1` |
| `implementation` | Name of the implementation |
| `public_address` | Externally reachable address (`domain:port` or `domain`) |
| `server_id` | Ed25519 verifying key (hex) |
| `tumbler_prefix` | Prefix for this server's tumblers |
| `content_api` | Path template for content retrieval |
| `hash_algorithm` | MUST be `"blake3"` |

**Optional fields (v1.1):**

| Field | Description |
|---|---|
| `implementation_version` | Version string |
| `server_name` | Human-readable name |
| `server_description` | One-line description |
| `supported_features` | Array of capabilities (see below) |
| `content_types` | **NEW** — Content types this server can serve |
| `public_content` | Whether public works are accessible without auth |
| `started_at` | Unix timestamp |
| `xcp_extensions` | **NEW** — Extension URLs (see §11) |

**Feature values for `supported_features`:**

| Value | Endpoint | Description |
|---|---|---|
| `content` | `/api/public/work/{id}` | Full work retrieval (REQUIRED) |
| `range` | `/api/public/work/{id}/range/{start}/{end}` | Passage retrieval |
| `links` | response field | Link/backlink data in responses |
| `search` | `/api/search` | Content search |
| `webhooks` | `/api/webhook/subscribe` | **NEW** — Change notifications |
| `trails` | response field | Trail/curated path data |

---

## 2. Content Retrieval

### 2.1 Full Work

### `GET /api/public/work/{id}`

Retrieves the full text and metadata of a published work.

**Path parameter:**
- `{id}` — work identifier in the implementation's native format.
  Hex-encoded is RECOMMENDED (e.g., `0x5`, `0049c`).

**Content Negotiation (NEW in v1.1):**

Clients MAY send an `Accept` header to request a specific format:

| Accept value | Response `Content-Type` | Description |
|---|---|---|
| `text/plain` (default) | `text/plain` | Plain text, no formatting |
| `text/markdown` | `text/markdown` | Markdown with structure |
| `text/html` | `text/html` | HTML with formatting |
| `application/json` | `application/json` | Full metadata + content (default) |

Servers declare supported types in `content_types` field of their
identity document. If the requested type is not supported, the server
MUST respond with `406 Not Acceptable` or fall back to `text/plain`.

**Response (200 OK) — JSON (default):**

```json
{
  "api_version": 1.1,
  "implementation": "xudanu",
  "work_id": "0x5",
  "title": "Pride and Prejudice",
  "revision": 3,
  "text": "It is a truth universally acknowledged...",
  "char_count": 423001,
  "content_hash_blake3": "b4589ddac9f0d326...",
  "hash_algorithm": "blake3",
  "tumbler": "\"alice.example.com\".0x5.3",
  "license": "public-domain",
  "span_provenance": [...],
  "links": [...],
  "content_type": "text/plain",
  "language": "en",
  "author": "Jane Austen",
  "created_at": 1784505702,
  "updated_at": 1784505800,
  "server_namespace_id": 12728757951001747821,
  "server_public_key": "16522a722cab6b18...",
  "server_signature": "d17534fc12780a9d..."
}
```

**Required fields:**

| Field | Description |
|---|---|
| `api_version` | MUST be `1` or `1.1` |
| `implementation` | Name of the serving implementation |
| `work_id` | The work's identifier |
| `title` | Work title (may be auto-extracted) |
| `revision` | Revision number (opaque to consumer) |
| `text` | Full plain text of the work |
| `char_count` | Character count of text |
| `content_hash_blake3` | BLAKE3 hash of the UTF-8 encoded `text` field |
| `hash_algorithm` | MUST be `"blake3"` |
| `tumbler` | Full tumbler address (see §4) |
| `license` | License identifier (see §4.2) |

**Optional fields (v1.1 additions):**

| Field | Description |
|---|---|
| `content_type` | **NEW** — The MIME type of the `text` field |
| `language` | **NEW** — ISO 639-1 language code |
| `author` | **NEW** — Author name or identifier |
| `created_at` | **NEW** — Unix timestamp of creation |
| `updated_at` | **NEW** — Unix timestamp of last revision |
| `links` | Outbound links from this work |
| `span_provenance` | Attribution data for transcluded passages |

**Response (404):** Work not found, or work is not public.
**Response (406):** Requested content type not supported.
**Response (429):** Rate limit exceeded.

### 2.2 Passage Retrieval (optional)

### `GET /api/public/work/{id}/range/{start}/{end}`

Retrieves a character range from a work. Same response format as
full retrieval, but `text` contains only the requested range and
`content_hash_blake3` is the hash of the range text only.

---

## 3. Hash Verification

Consumers MUST verify that `BLAKE3(text.encode('utf-8'))` matches
`content_hash_blake3`. If the hash does not match, the content has
been modified in transit and MUST be rejected.

### Server Signature Verification (optional)

The `server_signature` is an Ed25519 signature over the string:
```
content_hash_blake3|server_namespace_id|revision
```

Consumers MAY verify this signature against `server_public_key` to
confirm the content was served by the claimed server.

---

## 4. Addressing (Tumblers)

### 4.1 Tumbler Format

```
"server_address".work_id.revision.char_start-char_end
```

**Examples:**

| Tumbler | Meaning |
|---|---|
| `"alice.example.com".0x5.3` | Full work, revision 3 |
| `"alice.example.com".0x5.3.100-200` | Characters 100-200 |
| `"gold.xanadu.net".0x12.1` | Work on Gold server |
| `12728757951001747821.0x5.3` | Numeric server ID |

### 4.2 License Values

| Value | Description |
|---|---|
| `all-rights-reserved` | Default copyright (Berne Convention) |
| `transcopyright` | Ted Nelson's Transcopyright License |
| `cc-by` | Creative Commons Attribution |
| `cc-by-sa` | Creative Commons Attribution-ShareAlike |
| `cc-by-nc` | Creative Commons Attribution-NonCommercial |
| `public-domain` | No copyright restrictions |
| `unknown` | License not specified |

### 4.3 Resolution

To resolve a tumbler:

1. Parse the server address (quoted domain or numeric ID)
2. Fetch `/.well-known/xcp-server.json` from that server
3. Fetch `/api/public/work/{work_id}` from that server
4. Verify content hash matches
5. If range specified, extract `text[start:end]`

---

## 5. Backlink Notification (optional)

### `POST /api/backlink-notify`

Notifies a server that another server has linked to its content.

**Request:**

```json
{
  "origin_server": "bob.example.com",
  "origin_work_id": "0x10",
  "origin_work_title": "My Analysis",
  "target_work_id": "0x5",
  "target_tumbler": "\"alice.example.com\".0x5.3.100-200",
  "target_hash": "b4589ddac9f0d326...",
  "link_type": "reference",
  "excerpt": "The passage I'm referencing..."
}
```

The receiving server MAY record this as a backlink for display.

---

## 6. Content Search (optional, NEW in v1.1)

### `GET /api/search?q={query}&limit={n}&offset={n}`

Searches public content on this server.

**Parameters:**

| Parameter | Required | Description |
|---|---|---|
| `q` | Yes | Search query (full-text) |
| `limit` | No | Max results (default: 20, max: 100) |
| `offset` | No | Pagination offset (default: 0) |
| `license` | No | Filter by license (e.g., `public-domain`) |
| `content_type` | No | **NEW** — Filter by content type |

**Response (200 OK):**

```json
{
  "query": "hypertext",
  "total": 42,
  "limit": 20,
  "offset": 0,
  "results": [
    {
      "work_id": "0x5",
      "title": "Literary Machines",
      "tumbler": "\"alice.example.com\".0x5.3",
      "excerpt": "...the concept of <em>hypertext</em> was first...",
      "content_hash_blake3": "b4589d...",
      "license": "cc-by",
      "relevance": 0.95
    }
  ]
}
```

**Use cases:**
- Cross-server discovery ("find passages about X across trusted servers")
- Citation finding ("does anyone reference this passage?")
- Content aggregation ("build a reading list on topic Y")

---

## 7. Change Subscription / Webhooks (NEW in v1.1)

### `POST /api/webhook/subscribe`

Subscribe to notifications when a work is revised.

**Request:**

```json
{
  "callback_url": "https://bob.example.com/xcp-webhook",
  "work_id": "0x5",
  "events": ["revised", "deleted"],
  "secret": "shared-secret-for-hmac"
}
```

**Response (201 Created):**

```json
{
  "subscription_id": "sub_abc123",
  "work_id": "0x5",
  "events": ["revised", "deleted"],
  "expires_at": 1785105702
}
```

### Webhook Delivery

When a subscribed event occurs, the server POSTs to `callback_url`:

**Request:**

```json
{
  "event": "revised",
  "work_id": "0x5",
  "old_revision": 3,
  "new_revision": 4,
  "new_content_hash_blake3": "c5690eebd...",
  "tumbler": "\"alice.example.com\".0x5.4",
  "timestamp": 1784600000
}
```

The request includes an `X-XCP-Signature` header:
```
X-XCP-Signature: hmac-sha256=<hex>
```
Computed as `HMAC-SHA256(secret, request_body)`.

### `DELETE /api/webhook/subscribe/{subscription_id}`

Unsubscribe from notifications.

**Use cases:**
- Live transclusion updates — when a source is revised, all servers
  with transclusions from it get notified
- Citation monitoring — "was my content updated?"
- Mirror/sync — keep a local cache in sync with the source

---

## 8. Content Negotiation (NEW in v1.1)

Servers MAY support multiple content representations. Clients request
a specific format via the `Accept` header.

**Example:**

```http
GET /api/public/work/0x5 HTTP/1.1
Host: alice.example.com
Accept: text/markdown
```

**Response:**

```http
HTTP/1.1 200 OK
Content-Type: text/markdown
X-XCP-Hash: b4589ddac9f0d326...

# Pride and Prejudice

It is a truth universally acknowledged...
```

The `X-XCP-Hash` header contains the BLAKE3 hash of the response
body, allowing verification regardless of content type.

**Supported types** (server declares in identity document):

| Content-Type | Use case |
|---|---|
| `text/plain` | Default, universal |
| `text/markdown` | Structured documents with formatting |
| `text/html` | Rich text with embedded styling |
| `application/json` | Full metadata + structured content |

---

## 9. Large Work Streaming (NEW in v1.1)

For works exceeding 1MB, servers SHOULD support range-based
retrieval via the HTTP `Range` header.

**Request:**

```http
GET /api/public/work/0x99 HTTP/1.1
Range: bytes=0-65535
```

**Response (206 Partial Content):**

```http
HTTP/1.1 206 Partial Content
Content-Range: bytes 0-65535/4230001
Content-Length: 65536
X-XCP-Hash: b4589d...
X-XCP-Range-Hash: e1234f...
```

`X-XCP-Range-Hash` is the BLAKE3 hash of just this chunk.
`X-XCP-Hash` is the hash of the full work (for verification after
all chunks are assembled).

---

## 10. Discovery via WebFinger (NEW in v1.1)

### `GET /.well-known/webfinger?resource={domain}`

Allows XCP discovery from a standard WebFinger query.

**Response:**

```json
{
  "subject": "alice.example.com",
  "links": [
    {
      "rel": "https://jonesd.info/xcp/identity",
      "href": "https://alice.example.com/.well-known/xcp-server.json"
    }
  ]
}
```

**Use case:** A service can check "does this domain speak XCP?"
without knowing the `.well-known` path. Standard WebFinger clients
discover XCP capability alongside ActivityPub, WebMention, etc.

---

## 11. Extensions (NEW in v1.1)

Servers MAY advertise protocol extensions in their identity document:

```json
{
  "xcp_extensions": [
    {
      "name": "xudanu-trails",
      "url": "https://github.com/jonesd/xudanu/blob/main/docs/xcp-extensions/trails.md"
    }
  ]
}
```

Extensions are implementation-specific capabilities not covered by
this spec. Consumers MAY implement extensions but MUST function
correctly without them.

---

## 12. Server Discovery

Each server maintains its own list of trusted servers. There is no
central registry. Servers discover each other through:

1. Manual configuration (admin adds trusted server)
2. Tumbler references (server A sees a link to server B)
3. **NEW** — WebFinger query (§10)
4. **NEW** — Search results (§6 — discover servers with relevant content)
5. Word of mouth (community shares server addresses)

### Trust Model

- **Untrusted servers**: content can be fetched but is marked as
  unverified (hash check still required, server identity not trusted)
- **Trusted servers**: content verified, server identity trusted for
  backlinks and attribution
- Each server admin decides trust independently

---

## Positioning Statement

XCP is an open, implementation-agnostic protocol for verifiable
cross-server content references. It draws inspiration from Ted
Nelson's Xanadu project — the original vision of a connected
docuverse where content on any system can reference content on any
other, with attribution preserved and links that never break.

The protocol is designed to be useful independent of any specific
implementation or organization. Any service that serves text content
can conform: a blog, a wiki, a legal database, an academic
preprint server, or a full hypertext system.

The Xanadu heritage is in the design philosophy (unbreakable links,
content addressing, provenance), the tumbler address format, and
the transcopyright license option. These are optional layers, not
requirements for basic participation.

---

## Implementation Notes

### For Xudanu
- All core endpoints implemented since v0.9
- BLAKE3 hashing in use since v0.9
- Tumbler format matches (DNS-anchored)
- Ed25519 server signatures implemented
- Cross-server resolution with SSRF protection
- **v1.1 features to implement**: search, webhooks, content negotiation

### For Gold/Green
- Needs HTTP server adapter (thin wrapper over existing API)
- Tumbler format needs server prefix mapping
- Content hashing: compute BLAKE3 over work text
- Server identity: generate Ed25519 keypair

### For New Implementations
- Any language, any data model
- Serve the two required endpoints
- Compute BLAKE3 hashes
- Generate Ed25519 keypair for signatures
- That's it — you're part of the network

### For Non-Hypertext Services (NEW)
- A blog platform: map posts to work IDs, serve post text
- A legal database: map opinions/statutes to work IDs
- A documentation site: map pages to work IDs
- An academic server: map papers to work IDs
- Content negotiation lets you serve markdown or HTML, not just plain text

---

## Versioning

| Version | Status | Changes |
|---|---|---|
| 1.0-draft | Under discussion | Initial specification (formerly "XCGP") |
| 1.1-draft | Under discussion | Renamed to XCP. Added: content negotiation, search, webhooks, large work streaming, WebFinger discovery, extensions, license filtering. |

Future versions will be backward compatible. New fields may be added
to responses; consumers MUST ignore unknown fields.

## License

This specification is licensed under Apache 2.0. Implementations may
use any license. The specification itself is open and free to
implement by anyone, for any purpose.

## Acknowledgments

This protocol builds on concepts from:

- **Project Xanadu** (Ted Nelson, 1960–present) — the vision of a
  connected docuverse with unbreakable links, transclusion, and
  transcopyright
- **Udanax Gold** (Autodesk, released 1999) — the open-sourced
  reference implementation that proved these concepts could work
- **Roger Gregory, Andrew Pam** and the Xanadu development community
- **W3C WebMention** — the backlink notification pattern
- **IPFS** — content-addressed storage concepts
- **ActivityPub** — federated server trust model

The goal is to realize Ted Nelson's vision of a connected docuverse
where content on any implementation can reference content on any
other — with cryptographic verification, permanent addresses, and
attribution that flows through every link.
