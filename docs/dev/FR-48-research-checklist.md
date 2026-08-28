# FR-48 Research Checklist — Tumbler Alignment

> Phase 0 research plan for FR-48 (tumbler mechanism update). Execute
> after BEBE implementation ships. Output feeds `FR-48-tumbler-alignment.md`.
> Budget: one session (~2.5h). A fresh session must be able to run this
> checklist cold — every source is named with a path.

## Why this research exists

The skep/sisbell exchange surfaced an architectural question. Xudanu's
tumblers (FR-34 Phase D-F) are a **derived view**: the O-tree CRDT owns
positions, `DocumentArrangement` bridges i64 positions to tumbler
addresses, and span migration keeps links alive across edits. Classic
Xanadu (and skep) invert this: tumblers ARE the storage addresses,
write-once, immutable by construction — links never need migration.

The research decides between (at least) two paths:

- **Hybrid**: keep CRDT + span migration; expose stable tumbler views
  for XCP cross-server refs. Weeks, low risk.
- **Tumbler-native**: I-space/V-space split, immutable versioned
  addresses, CRDT layered on top. Months, touches everything.

Strategic note: tumbler correctness is the most Roger-evaluable part of
the codebase. Original Udanax Gold source is in-tree (Section B).

## A. Xudanu Rust — current state (~45 min)

Read in this order:

1. `docs/dev/versioning-design.md` — **read first**. Foundational
   decision record on revision addressing; already frames "links durable
   across edits (Xanadu's #1 rule)". FR-48 must extend, not contradict it.
2. `docs/dev/FR-34-enfilade-native.md` — enfilade roadmap; Phase D-F
   tumbler status and open items.
3. `src-rust/src/edition/tumbler.rs` (793 lines) — `XudanuTumbler`,
   `DocumentArrangement`, `to_sequence()`/`from_sequence()` bridge.
   Tests at line ~627+.
4. `src-rust/src/space/sequence.rs` (1248 lines, mostly dormant) —
   the Sequence algebra. This is the Gold-lineage tumbler arithmetic.
5. `src-rust/src/space/` (rest) — region/displacement algebra (o-tree).
6. `src-rust/src/edition/links.rs` — `HyperRef`, `CrossServerRef`
   typed accessors (`work_id()`, `char_range()`, `parent_tumbler()`,
   `same_server_as()`), `HyperRef::tumbler_address()`,
   `for_tumbler_span()`.
7. `src-rust/src/edition/compound.rs` — `CompoundSpan::to_tumbler()` /
   `from_tumbler()` (transclusion coordinates).
8. `src-rust/src/server/otree_crdt.rs` — who owns positions today;
   how the O-tree does insertion/identity.
9. Span migration code (search `edition/` for delta migration) — how
   links survive edits today.

Extract for each:
- Is the tumbler stored or recomputed? When does it change?
- What Sequence-algebra operations exist, and which are actually called?
- Wire format of tumblers on XCP paths.
- Where span migration is triggered and what it costs.

## B. Original Udanax Gold — the canonical implementation (~60 min)

Root: `original-code/xanadugold/src/`. Read:

1. `src/server/z` — core kernel (single ASCII file; THE z code).
   Tumbler type, arithmetic, address stability model.
2. `src/server/zx`, `src/server/zstatic` — kernel extensions/statics.
3. `src/server/wrapperx.cxx` + `wrapperx.hxx` — wrapper layer, tumbler
   usage in the protocol.
4. `src/image/st.dir/*.st` — Smalltalk frontend algebra:
   `SequenceRegion.st`, `XuRealPos.st`, `XuRealRegion.st`,
   `XuSequenceRegion.st`, `RealRegion.st`, `BeforeReal.st`,
   `AfterReal.st`, `BeforeSequencePrefix.st`, `IEEE32Pos.st`,
   `IDUpOrder.st`. The Real/Sequence duality here IS the position/
   tumbler split as the original frontend saw it.
5. `src/Notes`, `src/disk/` (if present) — design notes, disk format
   for tumblers.
6. Workspace prior analysis: `docs/dev/xudanu-vs-xanadu.md`,
   `docs/dev/xanadu-17-rules.md` (workspace `docs/dev/`).

Extract:
- Gold's exact tumbler structure (digits, width limits, domain prefix?
  none?).
- I-space vs V-space: did Gold implement write-once immutable
  addresses? How are versions addressed?
- Tumbler arithmetic: comparison, widening, span intersection.
- How links/endorsements reference tumblers and stay stable.

## C. skep / xanadu-spec — the interop target (~30 min)

1. `/tmp/xcp-edit/` — XCP v1 `spec.md` + `spec-v1.1-bebe.md` (ours) +
   `conformance.py`. If gone, xcp repo: github.com/jonesd/xcp.
2. `/tmp/green-probe/` — sisbell/udanax-test-harness clone; check
   `docs/` for his tumbler model writeups. If gone, re-clone:
   `gh repo clone sisbell/udanax-test-harness /tmp/green-probe`.
3. Re-fetch the skep wire protocol doc (1,389 lines, was analyzed in
   the exchange; source: github.com/sisbell — repo or xanadu-spec
   issue #1 thread). Check whether his publishing crate shipped
   ("1-2 weeks" as of the exchange) — a live crate beats a doc.
4. sisbell/xanadu-spec — formal spec from Nelson's design + Gregory's
   green code; the tumbler sections.

Extract:
- skep's I-address write-once semantics: minting, immutability
  guarantee, versioning model.
- Dotted-decimal format and any widening/arithmetic rules.
- copy=transclusion mapping; what a CRDT peer must expose to be
  addressable by his model.

## D. Questions the research must answer

1. Are Xudanu tumblers stable across edits today, or recomputed? What
   breaks when a cross-server ref points at a span that migrated?
2. What does Gold's model actually guarantee, and did it hold in
   practice (check `src/Notes`, bugs)?
3. What does skep's write-once model require from a mutable CRDT peer?
4. What fraction of `space/sequence.rs` is needed for XCP v1.1/v2
   cross-server transclusion stability?
5. Does `versioning-design.md`'s decision record already answer part
   of this? (Its framing suggests yes — verify before re-deciding.)
6. Hybrid vs native: options, blast radius, migration path, cost.
7. What does BEBE (XCP v1.1) specifically need from tumblers that
   today's code doesn't give?

## Deliverables (end of session)

1. **Gap matrix**: rows = capabilities (stability, write-once,
   arithmetic, versioning, wire format, cross-server), columns =
   Xudanu / Gold / skep / XCP-required. Written into this file's
   successor or a `FR-48-research-notes.md` sibling.
2. **Open questions** with proposed resolution paths.
3. **Decision framing** for hybrid vs native (options, costs, risks,
   recommendation) — the input to `FR-48-tumbler-alignment.md`.

## Ground rules

- Research only: no code changes in Phase 0.
- Read Gold source before reading analysis of it; priors can bias.
- Cite file:line for every claim that lands in the FR doc.
- If the session runs long, B (Gold) is the part not to cut — it is
  the only non-derivative source.
