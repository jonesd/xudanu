# Xudanu vs Xanadu (Gold/Smalltalk) — Architectural Comparison

> **Purpose:** Document where Xudanu and the original Xanadu
> implementation (Gold/Smalltalk, now being migrated by Roger Gregory
> to Rust via Pharo) diverge architecturally, and where they
> complement each other. This is not a competition — it's a mapping
> of strengths and gaps to guide collaboration.

---

## Core Data Model

| Concept | Xanadu (Gold) | Xudanu |
|---------|---------------|--------|
| **Position algebra** | Enfilades, I-streams, spanfilade | O-tree CRDT with space/region/displacement |
| **Content addressing** | Tumblers (hierarchical numeric) | Tumblers (domain-based + numeric), BLAKE3 hashes |
| **Document model** | Enfilade tree (zzstructure) | Flat text + inline RangeElements (transclusion, blob) |
| **Versioning** | Editions with full provenance walk | Editions with revision history + three-way merge |
| **Linking** | Bijective links (zzlinks) between spans | Typed links (6 types) with span migration |

### Where Xudanu differs:

**CRDT instead of enfilades.** This is the biggest divergence.
Gold uses enfilades — tree-structured data with I-streams for
positioning. Xudanu uses a custom O-tree CRDT with the space algebra
(region/displacement). The CRDT approach gives us:

- **Automatic convergence** — multiple editors can edit simultaneously
  without operational transform or locking. Any two servers that
  receive the same set of operations will converge to identical state.
- **Offline editing** — edits queue locally, merge on reconnect. No
  conflict resolution needed.
- **No central authority** — any server can accept edits. There's no
  "master" enfilade that must be kept consistent.

The CRDT approach might be difficult to reconcile with Gold's enfilade
model. Enfilades are deterministic and ordered; CRDTs are eventually
consistent. These are fundamentally different coordination strategies.

**Flat text + inline elements instead of enfilade tree.** Gold
represents documents as trees of enfilades. Xudanu represents
documents as flat text with inline RangeElements. A transclusion is
not a separate enfilade reference — it's an inline element in the
text stream. Same for images (`RangeElement::Blob`).

This means Xudanu doesn't have the deep tree structure that enables
Gold's spanfilade operations (sub-enfilade addressing, recursive
transclusion walks). But it makes the rendering layer much simpler —
a document is text with inline spans, which maps directly to a browser
contentEditable div.

---

## What Xudanu Has That Gold Likely Doesn't

### Browser-based real-time collaboration
- WebSocket transport with CRDT sync
- Live cursor positions, selections, typing indicators
- Multiple users editing the same document simultaneously
- Session tickets for persistent authentication across reconnects

### Cross-server protocol (XCP)
- HTTP-based content retrieval with BLAKE3 hash verification
- Domain-based tumblers (`"alice.example.com".5.3.10.7`)
- Server directory with trust management
- Automatic backlink notifications between servers
- Public content API (`/api/public/work/{id}`) with per-span provenance

### Modern web frontend
- contentEditable editor with inline transclusion rendering
- Compound builder (visual search + placement of transclusions)
- Typed links with visual markers (margin gutter, tooltips)
- Reading mode (seamless, no editing chrome)
- Provenance chain visualization
- Document map (force-directed graph of work connections)

### Cryptographic provenance
- Per-element Ed25519 signatures (every text element signed by author)
- BLAKE3 content hashing for tamper detection
- Federation provenance bundles (W3C PROV-JSON export)
- Cross-server signature verification

### Image handling
- Images as first-class CRDT elements (`RangeElement::Blob`)
- Content-addressed blob store
- Inline rendering at char positions (survives edits via span migration)
- Cross-server blob sharing (within cluster — HTTP endpoint TBD)

### License enforcement
- Per-work license metadata (ARR, Transcopyright, CC-BY, CC-BY-SA, PD)
- Transclusion compliance badges
- ARR warning on transclusion attempt
- License stamping in attribution log

---

## What Gold Has That Xudanu Doesn't

### Deep Xanalu data structures
- **Enfilades** — the canonical tree-structured content model
- **I-streams** — positioning system for within-enfilade addressing
- **Spanfilade** — sub-enfilade operations, recursive transclusion
- **Ent/Dagwood/HTree** — the full backend index machinery
- **Crum/BCrum** — the bottom-level data units

Roger's Pharo → C/Rust migration preserves these faithfully (byte-
identical to the Smalltalk oracle). Xudanu has simpler analogs (O-tree,
flat text, blob store) but not the full Gold machinery.

### Proven algorithmic correctness
Gold's algorithms have been validated against the original Smalltalk
implementation with byte-identical outputs. Xudanu's algorithms are
original and tested (2764+ tests) but not validated against a
reference implementation.

### Ted Nelson's design authority
Gold IS Xanadu — designed by Nelson and team over decades. Xudanu is
inspired by Xanadu but makes independent architectural choices.

---

## Where CRDT Might Create Tension

The CRDT model is fundamentally different from enfilades:

| Concern | Enfilades | CRDT |
|---------|-----------|------|
| **Consistency** | Deterministic, ordered | Eventually consistent |
| **Concurrency** | Requires coordination | Conflict-free by design |
| **Merging** | Explicit (three-way or operational transform) | Automatic (commutative operations) |
| **Positioning** | I-streams (absolute) | Space algebra (relative) |
| **History** | Full provenance walk (again()) | Revision history + element provenance |

**Potential friction:**
- A transclusion in Xudanu references content by BLAKE3 hash + tumbler.
  In Gold, it references an enfilade span. These are different
  addressing models.
- Span migration in Xudanu uses the CRDT's space algebra. In Gold, it
  uses the enfilade's mapping/displacement system. Both achieve "links
  survive edits" but via different math.
- Xudanu's `again()` provenance walk follows transclusion chains
  through flat text + element references. Gold's walk follows enfilade
  tree structure. The user-facing behavior is similar; the internals
  are completely different.

**Possible bridge:** The two systems could interoperate at the content
layer — both use content hashes and tumblers for cross-server
references. The CRDT vs enfilade difference is internal; the external
protocol (XCP) doesn't care how each server stores its content
internally.

---

## Potential Collaboration Models

### Model A: XCP interop
Gold and Xudanu servers both implement XCP. Content flows between
them via HTTP + BLAKE3 verification. Each server uses its own internal
model (enfilades vs CRDT). Users on either system can transclude from
the other.

**Advantage:** No need to reconcile data models. Each system keeps its
architecture.
**Barrier:** Gold would need an XCP adapter (HTTP endpoint serving
content + hashes).

### Model B: CRDT layer on Gold core
Use Gold's proven enfilade/spanfilade as the storage layer, with
Xudanu's CRDT sync as the collaboration layer. The CRDT manages
operational ordering; the enfilade manages content structure.

**Advantage:** Best of both worlds — proven core + modern collaboration.
**Barrier:** Significant integration work. CRDT operations would need
to map to enfilade mutations.

### Model C: Shared frontend
Use Xudanu's web frontend (editor, compound builder, provenance
visualization) with Gold as the backend. The frontend talks to the
backend via XCP/WebSocket.

**Advantage:** Roger gets a web UI without building one. Xudanu gets
proven core algorithms.
**Barrier:** API compatibility. The frontend would need to adapt to
Gold's operation model.

---

## Summary

| Dimension | Xudanu strength | Gold strength |
|-----------|----------------|---------------|
| **Core algorithms** | CRDT convergence, offline edit | Proven enfilade/spanfilade |
| **Collaboration** | Real-time, multi-user | Single-user (historically) |
| **Cross-server** | XCP protocol, working today | Tumblers (theoretical) |
| **Frontend** | Browser-based, polished | None (backend/library) |
| **Testing** | 2764+ tests, 77% coverage | Byte-identical to Smalltalk oracle |
| **Maturity of core** | New, original | Decades of design, proven correct |
| **Deployment** | Running on xudanu.com | Not deployed |

The honest assessment: Roger's Gold migration is the authoritative
implementation of the original Xanadu algorithms. Xudanu is a modern
reimagining that trades algorithmic purity for deployability and
collaboration. Both have value. The question is whether they can
meet in the middle.
