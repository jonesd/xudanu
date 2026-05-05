# Nelson's 17 Rules for Xanadu Systems — xudanu Compliance

Source: [Project Xanadu - Wikipedia](https://en.wikipedia.org/wiki/Project_Xanadu#Original_17_rules)

## Status Summary

- **6 Fully Implemented:** Rules 1, 4, 6, 7, 10, 12, 17
- **6 Partially Implemented:** Rules 2, 3, 5, 8, 11, 16
- **4 Not Yet Implemented:** Rules 9, 13, 14, 15

## Rule-by-Rule Assessment

### Rule 1: Every Xanadu server is uniquely and securely identified

**Status: Yes**

Each server generates an Ed25519 keypair stored in `data/server.key`. The public key provides a unique identity via `federation_server_id()`. The identity persists across restarts and is used for federation authentication.

### Rule 2: Every Xanadu server can be operated independently or in a network

**Status: Partial**

Standalone operation works fully. Federation transport (encrypted peer channels, wire protocol) exists and has integration tests, but the federation system is not yet production-ready — peer discovery, automatic reconnection, and data synchronization are incomplete.

### Rule 3: Every user is uniquely and securely identified

**Status: Partial**

Users receive numeric session IDs via `session_login_public`, but there is no cryptographic user identity. Any connection can claim any ID. Planned: optional display names and per-user signing keys.

### Rule 4: Every user can search, retrieve, create, and store documents

**Status: Yes**

Full document lifecycle: `work_create`, `work_grab`, `work_revise`, `work_release`, `work_fetch_edition`, `work_list`. Blob storage for binary data. Search via `find_text_transcluders` and `find_shared_regions`.

### Rule 5: Every document can consist of any number of parts each of which may be of any data type

**Status: Partial**

Documents support text content and embedded blobs (images). The O-tree/edition model supports spans and ranges, but arbitrary data types (video, structured data, etc.) are not yet supported as first-class document parts.

### Rule 6: Every document can contain links of any type including virtual copies (transclusions) to any other document

**Status: Yes**

Bidirectional links tracked in both directions. Transclusion tracking via `TransclusionIndex` and `ContentAddressIndex`. Shared region finding across documents. Content fingerprinting (BLAKE3) enables automatic transclusion detection.

### Rule 7: Links are visible and can be followed from all endpoints

**Status: Yes**

Link visualization in the web UI with navigation chips. Transclusion split view with canvas bridge lines connecting shared regions. Links are bidirectional — `link_list_for_work` returns both outgoing and incoming links.

### Rule 8: Permission to link to a document is explicitly granted by the act of publication

**Status: Partial**

Documents are published by default when created. There is no explicit "publish" action that grants link permission separately from creation. Club-based access controls exist but are not wired through the UI.

### Rule 9: Every document can contain a royalty mechanism at any desired degree of granularity

**Status: No**

No royalty or micropayment system exists. The `cost-utility-meter` and `cost-model` modules define the data structures for usage tracking and billing, but the actual payment flow is not implemented.

### Rule 10: Every document is uniquely and securely identified

**Status: Yes**

Documents are content-addressed via BeIds in the GrandMap. Work IDs provide stable references. Editions use structural sharing so content identity is preserved across revisions.

### Rule 11: Every document can have secure access controls

**Status: Partial**

The club system supports `read_club` and `edit_club` fields on documents, with membership lists and owner tracking. However, these are not enforced in the dispatch layer and are not exposed in the UI.

### Rule 12: Every document can be rapidly searched, stored and retrieved without user knowledge of where it is physically stored

**Status: Yes**

The server abstracts all storage. Content-addressed blob storage with BLAKE3 fingerprints. Snapshots serialized to `server.json`. Clients interact via work IDs without knowing physical location.

### Rule 13: Every document is automatically moved to physical storage appropriate to its frequency of access from any given location

**Status: No**

No adaptive storage tiering. All data lives in the local filesystem under the data directory. No hot/cold storage migration.

### Rule 14: Every document is automatically stored redundantly to maintain availability even in case of a disaster

**Status: Partial**

Crash-safe persistence with time-based auto-checkpoint and graceful shutdown checkpoint. Key history survives rotation. No geographic replication or automatic backup.

### Rule 15: Every Xanadu service provider can charge their users at any rate they choose

**Status: No**

No billing system. The cost model structures exist (`StorageCost`, `CostMethod`) but are not connected to any payment infrastructure.

### Rule 16: Every transaction is secure and auditable only by the parties to that transaction

**Status: Partial**

Federation channels use X25519 key exchange and ChaCha20-Poly1305 encryption. Server identity uses Ed25519 signing. However, there is no per-transaction audit trail or end-to-end encryption between users.

### Rule 17: The Xanadu client-server communication protocol is an openly published standard

**Status: Yes**

WebSocket JSON protocol documented in `docs/custom-frontend.md` and `docs/protocol-and-audit.md`. Wire operations are enumerated in `src/server/transport/protocol.rs`. WASM bindings enable third-party clients. The server can serve custom frontends via `--static-dir`.
