# Embedder introduction — draft + source map (2026-10-12)

Companion to FR-88 S4 ("build your own client" docs page). Part A
is the draft introductory document for developers/projects that
might build on Xudanu. Part B maps every section to existing
material. Part C lists what must exist before publishing.

---

# Part A — the draft

# Xudanu for Developers

*The engine, the protocol, and your own clients.*

## 1. What Xudanu is (30 seconds)

Xudanu is an open-source document engine where **connections are
first-class**: every link is typed, multi-ended, and visible from
both ends; quoted content is included by reference (transclusion),
not copied; every version stays addressable; and every passage
carries cryptographic attribution. Multiple people can edit live,
and documents can link across independent servers.

## 2. Where it comes from

The model is Ted Nelson's Xanadu design — specifically the Udanax
Gold system (Xanadu 92.1), built 1992–96 by the Xanadu team and
open-sourced in 1999. The release shipped the back end twice —
732 Smalltalk classes and a consistent C++ translation of the
model — but the team had dispersed and the productization was
unfinished. Orphaned, not broken: the code sat comprehensible-to-
almost-no-one for 27 years.

Xudanu is an independent re-implementation of that model in Rust,
with the additions the original never had: realtime CRDT
collaboration, per-passage Ed25519 provenance anchored to Bitcoin,
content-addressed storage, and machine-assisted authoring. It is
not affiliated with Project Xanadu; it implements the model.

## 3. What the engine does

- **Typed, multi-ended links** — Comment, Reference, Disagreement,
  Quotation, See Also, Web; one connection can have many ends,
  compared side by side; gathered end-sets fill one blank jointly
- **Real transclusion** — content from one document appears live
  in another and updates with its source; provenance travels with
  the passage
- **Deep versioning** — partial-order branches; every revision
  addressable and comparable; links survive edits because
  addresses are positions-in-structure, not byte offsets
- **Per-passage provenance** — who wrote what, at span level,
  Ed25519-signed; tamper-evident chained log; optional Bitcoin
  anchoring for a trust-minimized existence floor
- **Realtime collaboration** — a write-once CRDT engine; no locks;
  measured ~900× faster than the earlier OT-style engine under
  interleaving
- **Federation** — documents link across independent servers with
  content verification
- **Content addressing** — BLAKE3-verified tumblers; reference
  over copy: re-typing existing content is detected and offered
  as a live transclusion

## 4. What you could build with it

The engine is a library-shaped asset: any application whose
documents argue with, quote, or annotate other documents.

- **Note-taking and PKM tools** — bidirectional links that are
  structural, not bolted on; notes that quote sources by
  reference; disagreement as a first-class gesture
- **Editors and writing tools** — drafts that share passages
  without copying; comparison of versions through their
  connections
- **Wikis and knowledge bases** — fine-grained transclusion with
  attribution, the thing wiki embeds approximate
- **Annotation and citation layers** — commentary that lives
  attached to exact passages, visible from both sides
- **Research notebooks and literature review** — claims, evidence,
  and rebuttals as connected structure; provenance from source to
  synthesis
- **LLM-driven agents and tools** — the MCP server exposes the
  engine to model clients; per-span authorship typing (human /
  LLM / historical) makes machine contribution disclosable and
  auditable
- **Archives and digital libraries** — immutable versions,
  character-level citation, cross-collection linking

## 5. See it running

- Hosted instance (read-only): **xudanu.com** — includes the
  interactive Links Course
- Public sandbox (write): **demo.transclusion.org**
- Locally in 90 seconds: `docker compose -f docker-compose.demo.yml up`
  (QUICKSTART.md), or a static release binary — one command, no
  build
- The **Gallery of Unusual Connections** — seeded exhibits of
  every link structure, one command on your own server

## 6. Build on it — three ladders

1. **Any language, over the wire.** The server exposes a
   documented, versioned WebSocket protocol (140+ operations:
   xcp-spec). Point a client at it and drive the whole model.
   The reference client is `xudanu-cli` — a terminal program that
   creates works, makes typed links, browses connections, and
   runs an interactive REPL. Read its source as a worked example.
2. **Model context (MCP).** `xudanu-mcp` exposes the engine to
   LLM clients — reading, linking, and transcluding as tool
   calls.
3. **In-process, in Rust.** The engine is being extracted into a
   standalone crate with no network dependencies (FR-88): your
   application links it directly. A demo binary shows the full
   loop — create, type, link, transclude, provenance dump — with
   no server running.

*(3 ships with FR-88; 1 and 2 work today.)*

## 7. The web UI is a client, not a layer

The bundled web interface is a TypeScript application that talks
the same wire protocol as any other client — nothing in the
engine renders, serves, or knows about it. Run it as-is, fork it,
or ignore it and ship your own UI on any stack. Your interface,
our engine.

---

# Part B — source map

| Section | Reused from | New writing |
|---|---|---|
| 1 What it is | README "What Xudanu does differently" | condensation only |
| 2 Where it comes from | udanax-to-xudanu.html; gold-heritage.html; green-gold-matrix (census numbers); xanadu-contact-history phrasing rule ("orphaned, not broken") | 3 paragraphs, from logged material |
| 3 Capabilities | README; transclusion-engine/architecture deep-dives; provenance-flow-and-claims; FR-51 measurements (900×); FR-58 (reference-over-copy) | condensation |
| 4 Use cases | — (weak spot: no existing use-case doc) | **all new — the section that earns the page** |
| 5 Demos | README Try-in-90-seconds; QUICKSTART.md; gallery docs; sandbox URLs | assembly |
| 6 Three ladders | wire-protocol.html; xcp-spec-v1.1.md; xudanu-cli source; MCP docs; FR-88 | ladder framing new |
| 7 UI is a client | FR-88 §1; web/ architecture | short, new |

# Part C — publish blockers / gaps

1. FR-88 S4 demo binary (ladder 3's example) — page can ship
   before it with the parenthetical, as drafted
2. A `xudanu-cli` walkthrough transcript (paste a real session)
3. Use-case section (Part A §4) should get one screenshot or
   terminal capture per bullet eventually — not a blocker
4. Live link check: confirm xcp-spec filename/link text once the
   protocol page URL is final on the docs site
