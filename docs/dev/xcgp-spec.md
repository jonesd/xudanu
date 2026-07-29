# Xanadu Content Gateway Protocol (XCGP)

> **Version:** 1.0-draft
> **Status:** Open Standard for Discussion
> **License:** Apache 2.0 (this specification); implementations may use any license

## Purpose

An open standard enabling any hypertext implementation to share content
with any other implementation in the Xanadu docuverse. Implementations
communicate via standard HTTP/JSON — no shared protocol, data model,
or internal architecture required.

## Design Principles

1. **Implementation-agnostic** — does not mandate enfilades, CRDTs, or
   any specific data structure
2. **Read-only first** — content discovery and retrieval; no write
   propagation required
3. **Content-addressed** — all content verified by cryptographic hash
4. **Federated trust** — each server decides which servers to trust
5. **Minimal surface** — two endpoints, one identity file

## Conformance

An implementation **conforms to XCGP v1** if it provides:

- [ ] `GET /.well-known/xanadu-server.json` (Server Identity)
- [ ] `GET /api/public/work/{id}` (Content Retrieval)
- [ ] BLAKE3 content hashing (Hash Verification)
- [ ] Tumbler address format (Addressing)

Optional:
- [ ] `GET /api/public/work/{id}/range/{start}/{end}` (Passage Retrieval)
- [ ] `POST /api/backlink-notify` (Backlink Notification)
- [ ] `GET /api/search?q={query}` (Content Search)

---

## 1. Server Identity

### `GET /.well-known/xanadu-server.json`

Every XCGP server MUST publish a JSON document at this path.

**Response:**

```json
{
  "protocol": "xcgp",
  "protocol_version": 1,
  "implementation": "string",
  "implementation_version": "string",
  "server_name": "string",
  "server_description": "string",
  "public_address": "domain:port",
  "server_id": "hex-encoded-ed25519-public-key",
  "tumbler_prefix": "\"domain:port\"",
  "content_api": "/api/public/work/{id}",
  "hash_algorithm": "blake3",
  "supported_features": ["content", "range", "links", "trails", "search"],
  "public_content": true,
  "started_at": 1784505702
}
```

**Required fields:**

| Field | Description |
|---|---|
| `protocol` | MUST be `"xcgp"` |
| `protocol_version` | MUST be `1` |
| `implementation` | Name of the implementation (e.g., `"xudanu"`, `"gold"`, `"green"`) |
| `public_address` | Externally reachable address (`domain:port` or `domain`) |
| `server_id` | Ed25519 verifying key (hex) — used to verify server signatures |
| `tumbler_prefix` | Prefix for this server's tumblers (quoted domain: `"domain:port"`) |
| `content_api` | Path template for content retrieval |
| `hash_algorithm` | MUST be `"blake3"` for v1 |

**Optional fields:**

| Field | Description |
|---|---|
| `implementation_version` | Version string |
| `server_name` | Human-readable name |
| `server_description` | One-line description |
| `supported_features` | Array of capabilities |
| `public_content` | Whether public works are accessible without auth |
| `started_at` | Unix timestamp of server start |

---

## 2. Content Retrieval

### `GET /api/public/work/{id}`

Retrieves the full text and metadata of a published work.

**Path parameter:**

- `{id}` — work identifier in the implementation's native format.
  Hex-encoded is RECOMMENDED (e.g., `0x5`, `0049c`).

**Response (200 OK):**

```json
{
  "api_version": 1,
  "implementation": "xudanu",
  "work_id": "0x5",
  "title": "Pride and Prejudice",
  "revision": 3,
  "text": "It is a truth universally acknowledged...",
  "char_count": 423001,
  "content_hash_blake3": "b4589ddac9f0d326eebb88d7fc728fbad3098cb97eb5e97c5e98e861807f030b",
  "hash_algorithm": "blake3",
  "tumbler": "\"alice.example.com\".0x5.3",
  "license": "public-domain",
  "span_provenance": [...],
  "server_namespace_id": 12728757951001747821,
  "server_public_key": "16522a722cab6b18...",
  "server_signature": "d17534fc12780a9d..."
}
```

**Required fields:**

| Field | Description |
|---|---|
| `api_version` | MUST be `1` |
| `implementation` | Name of the serving implementation |
| `work_id` | The work's identifier |
| `title` | Work title (may be auto-extracted) |
| `revision` | Revision number (opaque to consumer) |
| `text` | Full plain text of the work |
| `char_count` | Character count of text |
| `content_hash_blake3` | BLAKE3 hash of the UTF-8 encoded `text` field |
| `hash_algorithm` | MUST be `"blake3"` |
| `tumbler` | Full tumbler address: `prefix.work_id.revision` |
| `license` | License identifier (see License Values below) |

**Response (404):** Work not found, or work is not public.

**Response (429):** Rate limit exceeded.

### Content Hash Verification

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

## 3. Passage Retrieval (optional)

### `GET /api/public/work/{id}/range/{start}/{end}`

Retrieves a character range from a work. Same response format as
Content Retrieval, but `text` contains only the requested range.

---

## 4. Addressing (Tumblers)

### Tumbler Format

```
"server_address".work_id.revision.char_start-char_end
```

**Examples:**

| Tumbler | Meaning |
|---|---|
| `"alice.example.com".0x5.3` | Full work, latest revision |
| `"alice.example.com".0x5.3.100-200` | Characters 100-200 |
| `"gold.xanadu.net".0x12.1` | Work on Gold server |
| `12728757951001747821.0x5.3` | Numeric server ID (for trusted directory) |

### Parsing Rules

1. If the tumbler starts with `"`, the quoted string is the server address
2. After the server prefix, the next component is the work ID
3. The second component is the revision (opaque to consumer)
4. An optional `start-end` range may follow

### Resolution

To resolve a tumbler:

1. Parse the server address (quoted domain or numeric ID)
2. Fetch `/.well-known/xanadu-server.json` from that server
3. Fetch `/api/public/work/{work_id}` from that server
4. Verify content hash matches
5. If range specified, extract `text[start:end]`

---

## 5. License Values

| Value | Description |
|---|---|
| `all-rights-reserved` | Default copyright (Berne Convention) |
| `transcopyright` | Ted Nelson's Transcopyright License |
| `cc-by` | Creative Commons Attribution |
| `cc-by-sa` | Creative Commons Attribution-ShareAlike |
| `public-domain` | No copyright restrictions |
| `unknown` | License not specified |

---

## 6. Backlink Notification (optional)

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

The receiving server MAY record this as a backlink for display to
its users.

---

## 7. Server Discovery

### Trusted Server Directory

Each server maintains its own list of trusted servers. There is no
central registry. Servers discover each other through:

1. Manual configuration (admin adds trusted server)
2. Tumbler references (server A sees a link to server B, fetches its
   identity, admin approves trust)
3. Word of mouth (community shares server addresses)

### Trust Model

- **Untrusted servers**: content can be fetched but is marked as
  unverified (hash check still required, but server identity is not
  trusted)
- **Trusted servers**: content is verified and server identity is
  trusted for backlinks and attribution
- Each server admin decides trust independently

---

## Implementation Notes

### For Xudanu
- All endpoints already implemented
- BLAKE3 hashing in use since v0.9
- Tumbler format matches (DNS-anchored)
- Cross-server resolution with SSRF protection

### For Gold/Green
- Needs HTTP server adapter (can be a thin wrapper)
- Tumbler format needs server prefix mapping
- Content hashing: compute BLAKE3 over work text
- Server identity: generate Ed25519 keypair, publish identity file

### For New Implementations
- Any language, any data model
- Serve the two required endpoints
- Compute BLAKE3 hashes
- Generate Ed25519 keypair for signatures
- That's it — you're part of the docuverse

---

## Versioning

| Version | Status | Changes |
|---|---|---|
| 1.0-draft | Under discussion | Initial specification |

Future versions will be backward compatible. New fields may be added
to responses; consumers MUST ignore unknown fields.

## License

This specification is licensed under Apache 2.0. Implementations may
use any license. The specification itself is open and free to
implement by anyone, for any purpose.

## Acknowledgments

This protocol builds on concepts from:
- Project Xanadu (Ted Nelson, 1960-present)
- Udanax Gold (Autodesk, released 1999)
- The Xanadu community (Roger Gregory, Andrew Pam, and others)

The goal is to realize Ted Nelson's vision of a connected docuverse
where content on any implementation can reference content on any other.
