# FR-168: The Gold Property Registry — Specification by Verified Property

**Status:** proposal — consultation draft (input sought before implementation; see Open Questions)
**Created:** 2026-11-21
**Depends on:** none (extends the test registry, `docs/dev/test-registry.md`; shares discipline with the census, `docs/xanalogical-census.html`)
**Author:** David Jones

---

## The problem

The Gold lane of the xanalogical field has implementations and no
specification. None, of any kind:

- The 1999 Udanax Gold release freed the model but not the readability.
- The Green lane now has all three artifacts: a formal specification
  (`sisbell/xanadu-spec`, 42 notes derived from *Literary Machines* and
  `udanax-green`), a golden-test harness against the original backend
  (`sisbell/udanax-test-harness`), and a working Rust implementation
  differentially verified against those goldens (`sisbell/skep`).
- The Gold lane has byte-identical ports in progress (R. Gregory,
  unpublished pending release) and this project — a working, tested
  engine — but no statement of what a *conforming* Gold-lineage engine
  must do.

An implementer who wants to build a Gold-lineage system today has code
to read and nothing to build against. This FR proposes the missing
artifact: a property-level conformance specification for the Gold
document model, built bottom-up from a working engine's verified tests.

## The approach in one sentence

Every row of the registry states one normative property of the model in
implementation-neutral language, carries the reference test that
verifies it in a working engine, and is tagged with its provenance —
Gold-lineage, interpretation, or extension.

## The unit: property rows, three layers, provenance-marked

Each row:

1. **Normative statement** — one sentence, implementation-neutral,
   testable. *Example: "An address, once assigned, is never reused or
   renumbered; edits allocate new addresses."*
2. **Evidence** — the reference test(s) in a working engine, with
   status and evidence rung (below).
3. **Provenance tag:**
   - **[G] Gold-lineage** — from the translated model; Gold was explicit.
   - **[I] Interpretation** — Gold was silent or ambiguous; this
     implementation chose. The choice *and the considered alternative*
     are both stated in the row.
   - **[X] Extension** — beyond Gold (CRDT convergence, hash-verified
     crums, cross-server tumblers). Real and running, but outside the
     core being specified.

The **[I] rows are the registry's most valuable output.** They mark
exactly where implementations may legitimately diverge, and where the
original model has genuine seams. Top-down derivation from design
documents cannot produce them — ambiguity is invisible until an
implementation has to decide. A registry from a working engine knows
where every decision was made.

## The levels: a build order, not a taxonomy

Each level depends only on earlier levels. An implementer can read L0
alone and start building addresses today.

| Level | Name | Contents | Maps to (this engine) |
|---|---|---|---|
| L0 | Addressing | tumblers, never-renumber allocation, the between/sequence algebra | `space/sequence.rs` |
| L1 | Structure | enfilade equivalents, crums, the order axioms (already registered) | `ent/` (registry §DagWood) |
| L2 | Content | documents, arrangements, spans, content addressing | `edition/` core |
| L3 | Connection | two-ended links, endsets, span migration under edits, two-way visibility | `edition/links.rs` |
| L4 | Transclusion | live windows, resolution, cycles, depth guards | `edition/transclusion.rs` |
| L5 | History | versions, provenance, authorship spans | `edition/provenance.rs` |

Variants and neighboring lineages are **annexes, not core**: a Green
annex cross-references rows where Green differs; an extension annex
holds the [X] rows. The core never grows to fit a variant.

## The evidence ladder

Every row declares its rung:

1. **Example test** — one constructed case passes.
2. **Property test** — randomized, with seeds and operation counts
   stated (e.g. 5 seeds × 30 ops).
3. **Stress test** — scale bounds hold (e.g. 1,000-child traversal).

The registry already exhibits all three (D7–D25 examples, D26–D29
properties, P6 stress). Making the rung explicit tells a reader how
much weight each property bears.

## Machine-readability and conformance

- Every property has a stable ID (`G-L3-014`).
- A generated manifest maps IDs → reference test names → current status.
- A conforming implementation publishes a **conformance report**: the
  set of core levels for which it passes every row ("passes Gold-core
  L0–L4"), plus its own [I] divergences declared row by row.

The frozen wire protocol already specifies the *surface*. This
specifies the *semantics beneath it*. Together they are a complete
interoperability story without appealing to any authority.

## The convergence hook

Byte-identical ports of the original backend, when released, become a
golden oracle for the [I] rows. The registry pre-registers every
interpretive choice now; the ports adjudicate later. An [I] row that
survives contact is re-tagged [G] with a dated note; one that does not
is corrected, dated and attributed, in public. The release does not
obsolete this work — it completes it.

## Deliverables

1. Registry format specification (the row schema, provenance rules,
   evidence ladder) — this document, refined.
2. **PoC: the L3 Connection section** — approximately 30 rows lifted
   from existing passing tests. L3 is chosen first because it is the
   xanalogical heart (span migration, two-way visibility), because it
   has zero coverage in the current test registry, and because it
   proves the format can specify the class, not just the substrate.
3. The L0 section (addressing) — largely mechanical from existing
   `space/` tests.
4. Manifest + conformance report format, with a generator wired into
   the test run.
5. Annex stubs (Green differences; extensions).

No new tests are required to begin. This is curation of evidence that
already passes.

## Scope and anti-goals

- The registry states *"what a working Gold-lineage engine has
  verified"* — never *"what Gold is."* That sentence stands at the top
  of the document.
- No completeness claim. The registry is the curated property core
  (~100 rows), not a transcription of 3,883 tests.
- No top-down formalization. Properties with executable evidence, not
  proofs. (The Green lane owns the formal approach; this is the other
  lane, done the way its evidence permits.)
- Not a rival to any lineage: Green is complete in its own terms; this
  opens the Gold lane to the same courtesy.
- Independent of Project Xanadu, as everywhere in this project. The
  model is translated and extended under Apache-2.0; nothing here
  claims the vision, only tests it.

## Open questions — input sought

This section is the reason for the consultation status. Each question
is live; answers will change the design.

1. **Legitimacy of bottom-up.** Is property extraction from one working
   interpretation a specification, or must specification derive from
   design intent? (The Green lane demonstrates the top-down path; this
   proposes the bottom-up path is the honest one for Gold, whose design
   documents are scattered where they exist at all.)
2. **Custody.** Where should such a registry live so that no
   implementation owns it? This repo (which holds the reference
   evidence)? A separate repo? Somewhere community-held?
3. **Shared core.** Where Green and Gold agree (they share permanent
   addressing and bidirectional links at minimum), should rows be
   shared with lineage annotations, or duplicated per-lane in annexes?
4. **Conformance scope.** Should a conformance report require the wire
   protocol as well as the property core, or remain semantics-only?
5. **Adjudication before the oracle.** Until byte-identical ports are
   public, what settles a disputed [I] row — the reference engine's
   behavior, documented precedent (Literary Machines, the release
   notes), or community review?
6. **Level granularity.** Are six levels the right cut? Alternatives:
   merge L1 into L0; split L3 by link model vs. migration behavior.
7. **Corrections discipline.** Adopt the dated-claims model throughout
   (every correction attributed and dated, never silently folded)?
   This project's census already works this way.

Corrections and opinions on any of the above are welcome and will be
attributed: https://github.com/jonesd/xudanu/issues

## Relationship to existing artifacts

- **Test registry** (`docs/dev/test-registry.md`) — the property
  registry is its continuation upward through the model; the ent layer
  (§Branch–§WASM) becomes L1 with rows re-tagged.
- **Census** (`docs/xanalogical-census.html`) — the same discipline
  (rows, dated, verified, how-verified) applied to properties instead
  of systems.
- **Field door** (`docs/xanalogical-systems.html`) — the general layer
  in prose; this gives the field its first testable definition of the
  Gold side.
- **Wire protocol docs** — the surface this registry sits beneath.
