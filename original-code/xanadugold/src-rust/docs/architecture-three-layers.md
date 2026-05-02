# Xudanu Architecture: Three-Layer Model

## Overview

Xudanu is built as a layered system, separating the core hypertext engine from the applications that use it. This document describes the three layers and how different clients can be built on top of the server.

## Layer 1: Core Engine (Library)

The `xudanu` Rust crate — a faithful migration of the Udanax Gold C++ hypertext document engine.

**Modules:**

| Module | Purpose |
|--------|---------|
| `edition` | Editions, OrglRoot (O-tree), RangeElement, Carrier |
| `edition/range_element` | RangeElement enum (Text, Data, Blob, Overlay, Edition, Label, PlaceHolder) |
| `edition/orgl` | OrglRoot — BTree-based storage, the core data structure |
| `edition/xn_region` | XnRegion — interval-based region algebra |
| `edition/mapping` | Mapping — affine transformations (shift, compose, invert) |
| `edition/shared_mapping` | SharedMapping — arbitrary position-to-position content mappings |
| `edition/label` | Label system, LabelledCarrier, IdentityMap |
| `edition/bundle` | Bundle types (Element, Array, PlaceHolder), retrieve(), storage cost |
| `edition/blob_store` | Content-addressable blob storage with preview generation |
| `edition/content_address` | ContentAddressIndex — fingerprint-based element lookup |
| `edition/backend` | BeStorage, InMemoryBeStorage — persistent storage trait |
| `edition/canopy` | Canopy — merged view of Edition hierarchies |
| `edition/links` | HyperLink, HyperRef — bidirectional link system |
| `edition/transclusion` | TransclusionIndex — finds transcluders and works |
| `edition/backfollow` | BackfollowEngine — reverse navigation |
| `edition/persistent` | Snapshot/restore for Edition and Work state |

**Key design decisions:**
- No standard library dependency possible (`no_std` compatible for WASM)
- All server dependencies behind feature flags
- Serde serialization behind `serde` feature
- BLAKE3 for content fingerprinting

## Layer 2: Server + Protocol

The `xudanu-server` binary — a WebSocket server exposing the engine over a wire protocol.

**Protocol:**
- Transport: WebSocket (JSON or binary codec)
- Endpoint: `ws://host:8080/xudanu?format=json&version=2`
- Handshake → Connect → Login → Operations
- Operations are typed with numeric op codes (0x0001–0x0e04 currently)

**Current operation groups:**

| Range | Group |
|-------|-------|
| 0x01xx | Session management (connect, login) |
| 0x02xx | Work operations (create, revise, list, delete) |
| 0x03xx | Club and endorsement operations |
| 0x04xx | FeSet and FeWrapper operations |
| 0x05xx | Mapping and copy/combine operations |
| 0x06xx | Snapshot operations |
| 0x07xx | Link operations |
| 0x08xx | Blob operations |
| 0x09xx | Overlay operations |
| 0x0axx | Transclusion queries |
| 0x0bxx | Label and identity operations |
| 0x0cxx | Bundle retrieval and storage cost |
| 0x0exx | Shared content mapping |

**Server features:**
- In-memory or persistent (directory-based) storage
- Checkpoint/restart for persistent mode
- Content-addressable blob storage with server-side preview generation
- Multi-user sessions with public and authenticated login

**The protocol IS the platform.** Any client that speaks this protocol has full access to the hypertext engine. The protocol is the stable contract between Layer 1 and Layer 3.

## Layer 3: Clients and Applications

Multiple clients can be built on top of the Xudanu server. The only requirement is speaking the WebSocket protocol.

### Current Client: Built-in Web UI

A single-file Preact application (`static/index.html`) served directly by the server. Provides:
- Work creation and text editing
- Revision history browsing
- Transclusion queries
- Blob upload and preview
- Link creation and navigation

This is a reference client — demonstrating the protocol, not defining the user experience.

### Potential Clients

**Document Editor**
- Rich text editing with transclusion support
- Side-by-side source/transcluded view
- Real-time collaboration via WebSocket
- Micropayment integration for pay-per-read content
- Could be a standalone web app (React/Vue/Svelte) or a desktop app (Tauri/Electron)

**Research Tool**
- Academic paper composition with automatic citation via transclusion
- Cross-document search and shared content visualization
- Version tracking and provenance chains
- Export to PDF/LaTeX with transclusion resolution

**Content Marketplace**
- Publisher dashboard with storage cost tracking
- Reader paywall with Lightning Network micropayments
- Royalty distribution reports per transclusion event
- Content analytics (who transcluded what, where, how much earned)

**API Client / SDK**
- Rust crate wrapping the WebSocket protocol for programmatic access
- Could be used to build bots, importers, exporters, batch processors
- The `xudanu` library itself could be embedded directly (no server needed) for single-user tools

**Mobile Client**
- Native iOS/Android reading/browsing app
- Lightning wallet integration for micropayments
- Offline reading with sync on reconnect

### Client Integration Points

```
                    ┌─────────────────────┐
                    │   xudanu-server     │
                    │   (WebSocket API)   │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
        ┌─────▼─────┐   ┌─────▼─────┐   ┌──────▼──────┐
        │  Web UI   │   │ Desktop   │   │   Mobile    │
        │  (Preact) │   │  (Tauri)  │   │  (native)   │
        └───────────┘   └───────────┘   └─────────────┘
              │                │                │
              └────────────────┼────────────────┘
                               │
                        ┌──────▼──────┐
                        │  Protocol   │
                        │  (the API)  │
                        └─────────────┘
```

### Proposed Server Configuration

```bash
# Headless — no UI, just the protocol
xudanu-server run --headless

# Built-in reference UI (current default)
xudanu-server run --ui embedded

# Custom UI from a directory
xudanu-server run --ui ./my-custom-ui

# With persistence
xudanu-server run --data-dir ./data --ui embedded

# With payment gateway (future)
xudanu-server run --features lightning --ui ./marketplace-ui
```

## Post-Migration Priorities

Once the C++ → Rust migration is complete (Phases 1–12), the next steps would be:

1. **Stabilize the protocol** — document all ops formally, version the protocol
2. **Refactor server for pluggable UI** — make the web UI optional and configurable
3. **Build the Rust SDK client** — a crate that wraps the protocol for programmatic use
4. **Choose a "flagship" client** — pick one application to build well (document editor is the natural choice)
5. **Payment integration** — Lightning Network via LDK behind a feature flag
6. **Multi-node federation** — Xanadu's original vision was a network of interoperable servers

The key principle: **Layer 1 and Layer 2 are the platform. Layer 3 is where innovation happens.** We build the engine once, and many applications can flourish on top of it.
