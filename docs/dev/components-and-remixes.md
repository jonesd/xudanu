# Components & Remixes — what xudanu is made of, and where the parts fit elsewhere

> Written 2026-10-07, after the FR-142 durability arc. Premise: xudanu
> stays whole and open-source (Apache-2.0) as the reference system;
> individual components may be extracted to support other research
> and product work. Permissive licensing means proprietary builds on
> top are clean from day one — no fork required, no enterprise
> edition until a customer forces it.

## 1. The inventory

| # | Component | What it is | Why it's unusual | Extraction |
|---|---|---|---|---|
| C1 | **Provenance kernel** | Per-span authorship, Ed25519 span signing, `AuthorType::Llm` + model identity, W3C PROV-JSON export, character-level attribution queries | Machine-verifiable who-wrote-what — including human-vs-model — on text. Nobody ships this | Medium |
| C2 | **Chained security log** | Append-only, hash-chained audit trail; checkpoints; one-command full verification | Tamper evidence without blockchain theater | Low |
| C3 | **Chunk store (CAS)** | Content-addressed (BLAKE3) immutable storage; dedup; GC-with-archive; verification walks | Git's object model generalized beyond code, embeddable | Low |
| C4 | **Tumblers + space algebra** | Hierarchical addresses; positions are addresses, not offsets — references survive edits by construction | Link rot solved at the data-structure level | Medium |
| C5 | **Typed bidirectional links** | Connections as first-class records; visible from both ends; semantic types; multi-ended/gathered sets | The web's missing half; also a working traceability engine | Medium |
| C6 | **Detectors** | Standing watches with typed/directional filters; collect-don't-interrupt; ack-never-delete | Attention as durable server state | Low |
| C7 | **Transclusion engine** | Live windows onto source text by reference; span migration; hash-pinned quoting | Single-source quoting that actually follows its source | High |
| C8 | **Durability stack** | WAL (fsync-per-entry, rotation, torn-tail sanitization), writer fingerprints, merge sidecars; deterministic crash suites + model-checked chaos harness | The *methodology* (a failing durability test is a data-loss bug, by definition) is rarer than the code | Low–Medium |

## 2. The seams — what actually depends on what

The honest coupling map (read right as "depends on"):

```
C1 provenance ──────► span model (O-tree ranges), crypto (Ed25519)
C2 security log  ───► nothing xudanu-specific (self-contained)
C3 chunk store   ───► nothing (self-contained; blake3)
C4 tumblers      ───► space algebra (Sequence) — pure math, no server deps
C5 links         ───► works/spans for endpoints; NOT the editor
C6 detectors     ───► C5 (fires on link events), works (revisions)
C7 transclusion  ───► C4 + O-tree CRDT + C3  (deepest coupling)
C8 durability    ───► wraps whatever it stores; instruments are generic
```

Three clean seams stand out — components with **no xudanu-specific
dependencies** (C2, C3, C8-instruments), extractable nearly as-is.
Two more are clean *libraries* already (C4's algebra is pure code;
C1's signing/PROV logic needs only a span abstraction, not the
O-tree itself). The genuinely entangled one is C7 — transclusion
touches addressing, the CRDT, and storage simultaneously; do it
last or never.

The other important seam: **C5+C6 vs the editor.** Links and
detectors need works and spans to exist, but not collaborative
editing — a single-user document store with typed links and watches
is a coherent smaller system (that's close to what the public
sandbox runs).

## 3. Combinations — small systems from two or three parts

- **C1 + C2 — "the audit kernel."** Signed per-span authorship plus
  a tamper-evident log: the core of an AI-governance / compliance
  product ("prove what the model wrote and what it cited"). The
  strongest near-term pitch; every large organization is being
  handed this problem by regulation and policy right now.
- **C3 + C8 — "durable CAS."** The chunk store with the durability
  discipline and its test instruments: an embeddable foundation for
  any records/document store. Sell the chaos harness as the
  methodology that comes with it.
- **C4 + C3 — "permanent references."** Tumbler addressing over
  content-addressed storage: citations that cannot rot, for legal,
  regulatory, and standards documents. Small, very demoable.
- **C5 + C6 — "traceability engine."** Typed links + detectors
  without the CRDT editor: requirements traceability and impact
  alerting. The WidgetPerfect story is literally this pitch.
- **C1 + C5 — "contested claims."** Signed authorship on typed
  disagreement links: argument mapping where every objection is
  attributable and provable — policy deliberation, safety cases.
- **C2 + C6 — "watched compliance."** Tamper-evident log of what a
  watch collected and when it was acked: audit-grade monitoring.

## 4. Extraction playbook

1. Keep xudanu as the whole reference system — the credibility
   engine where everything works together (and where the chaos
   harness keeps all seams honest).
2. Extract at most two, at most three: **C1 first** (timeliness),
   **C3 second** (ubiquity), consider C2 riding along with either.
3. Each extraction becomes an independently-named crate with its
   own README and tests, xudanu consuming it upstream — the seam
   stays proven by xudanu itself building on the library.
4. Re-run the FR-142 instrument pattern for each extracted crate:
   a durability/property suite that defines "done" before the first
   external user exists.

## 5. Attribution (C1) — how it might actually fit

The concrete enterprise shape: documents arrive from humans *and*
model pipelines. The kernel maintains, per span: author identity
(signed), author type (human/LLM + model id), derivation (what was
transcluded or cited to produce it), and exports the whole story as
PROV-JSON for the compliance toolchain. The audit log guarantees
nobody edited the story afterwards. Xudanu demonstrates all of it
today; the extraction is mostly cutting the span-abstraction
umbilical to the O-tree.
