# Xanalogical Structure in the LLM Era: A Working Implementation of Transclusion, Typed Links, and Per-Passage Provenance

## Abstract

The xanalogical model of literature — transclusion of content by
reference, unbreakable typed connections between specific passages,
and authorship traceable to the character — was designed in the
1960s and implemented in 1988–1992, but never reached users. We
argue the barrier was never the model's value but its cost of
manipulation: the mechanisms demanded expertise no reader could be
expected to have. We report on Xudanu, an open-source system that
implements the inherited model — enfilades with content-addressed
crums, tumbler-derived addressing, typed multi-ended links,
gathered end-sets — on modern infrastructure: a purpose-built
write-once CRDT for collaborative editing, per-passage Ed25519
attribution with an externally-anchored hash chain, and LLM-era
interaction in which the system itself detects re-typing of
existing content and offers it as a live transclusion. We measure
the editing engine against the system's earlier
operational-transform-style engine: under concurrent interleaving,
the write-once engine sustains ~80µs/op where the earlier engine
sustains 62–74ms/op (~900×), with convergence by construction.
Reuse detection fires within microseconds of six typed words. We
contribute an implementation report, honest claim-strength
boundaries for provenance systems, and a position: the xanalogical
barrier has moved from mechanism to interaction, and machine
assistance is what moves it.

---

## 1 Introduction

Ted Nelson conceived hypertext in the 1960s and spent the following
decades designing a literature that would not break: documents
connected by unbreakable links, content included by reference
rather than copy, every quotation traceable to its source [20, 21].
He named the deep version of reference *transclusion*, and the
project he built around it Project Xanadu. The implementation era
came late: from 1988, a small Autodesk-funded team built the
systems now known as Udanax Green (1988) and Udanax Gold (1992),
open-sourced in 1999. The deeper design was never completed, and
the web — arriving with simpler promises — took the world's
attention.

The xanalogical model faced two barriers. The first was
implementation complexity: enfilades (the dual-purpose trees at the
system's core) demanded theoretical machinery — convergence,
content addressing, structural transforms — that did not mature
until decades later. The second was manipulation cost: even if the
system worked, readers could not operate it. Creating a transclusion
required knowing what to reference, where it lived, and how to
address it. The model demanded expertise that no casual reader
would acquire.

Both barriers have moved. The first fell to modern infrastructure:
CRDT theory [24] provides convergence guarantees that Nelson's team
could only have dreamed of; content addressing (BLAKE3, IPFS,
Bitcoin) gives immutable identity to every unit; modern cryptography
(ECC signatures, timestamp anchoring) provides authorship
verification at the passage level. What changed is not whether a
lone builder could attempt the model — independent
single-implementer systems predate the LLM era [29] — but the depth
reachable per person-year: the substrate machinery the 1988–92 team
of seven built over years is now a one-person, months-scale project.
The second barrier is falling to
machine assistance: systems can now detect when a user is retyping
existing content and offer to complete it as a live reference, and
AI agents can operate the model as first-class editors with their
authorship tracked per-span.

The field has noticed. At ACM Hypertext 2026, multiple position
papers called for new foundations connecting hypertext to agentic
LLM systems [6, 10]. Adamski et al. reread Xanadu "not as a failed
project but as an uncompromising attempt to make high-dimensional
hypertextality an explicit design goal" [1]. Anderson traced how
contemporary tools-for-thought have "rediscovered, unknowingly,
ideas already known in the hypertext community" [2]. What the
community describes, no member has built: across 52 papers at
HT '26, zero implemented working transclusion engines; the terms
"enfilade" and "content-addressing" appear nowhere. Working systems
do exist outside the proceedings — Alph, a single-implementer project
under continuous development since 2016, implements transclusion,
visible links, and authorship queries as an overlay on the existing
Web [29] — but none implements the substrate beneath the Web:
content-addressed storage, convergent collaborative editing,
passage-level cryptographic provenance. This paper is an
implementation report from that substrate, and from the depth of
system a single implementer can now reach.

**Contributions.** (1) A full working implementation of the
inherited xanalogical model — enfilades, tumblers, typed
multi-ended links, gathered end-sets, per-work licensing — on
modern infrastructure. (2) A purpose-built write-once CRDT (the
"lattice") for collaborative editing, measured at ~900× the
throughput of the system's earlier OT-style engine under concurrent
interleaving, with convergence by construction. (3) Per-passage
cryptographic provenance with external timestamp anchoring
(OpenTimestamps / Bitcoin) and an explicit claim-strength analysis
separating what is cryptographically backed from what is
server-conditioned. (4) A reference-over-copy interaction loop
that detects re-typing of existing content and offers it as a live
transclusion, measured at microsecond latency. (5) An H(G)
hypertextuality profile of the resulting docuverse — the first
measured transclusion coordinate (θ > 0) — answering an open
question from the Hypertext 2026 proceedings.

---

## 2 The Inherited Model

We describe the model as inherited from the 1999 open-source
release and the design literature. Attribution of specific
structures to specific individuals follows the release's internal
documentation where available; where inferred, we name the team
collectively.

### 2.1 Transclusion

Nelson's coinage [20]: content included by reference, so a passage
exists once and its identity travels with it into every including
context. A quotation that is transcluded updates when its source
is edited; provenance is preserved by construction. The first use
of the term appears in a footnote in the 93.1 edition of *Literary
Machines*.

### 2.2 Enfilades

The core data structure: a balanced tree serving simultaneously as
a search index (by content fingerprint) and as a structural
container (applying displacements and transforms). Invented
circa 1980 by the implementation team working with Nelson.
Subtree hashes ("crums") provide O(1) equality checks and
O(changes) diff between editions.

### 2.3 Tumblers

Hierarchical universal addresses for content in a distributed
docuverse [19]. A tumbler like `1.5.3.2` narrows: server, work,
edition, span, character. Every passage in every document has a
location in one universal coordinate space, so a quotation on one
server can point precisely at its source on another.

### 2.4 Typed Multi-Ended Links

Connections between specific passages carrying semantic type
(Comment, Reference, Disagreement, Quotation, See Also). Links are
"sentences with blanks": the type is the verb, each end fills one
blank. A link may have any number of named ends. An end may itself
hold multiple passages (a *gathered end-set*), jointly filling one
blank.

### 2.5 The ent

A version-forking structure: a tree whose branches represent
alternative states and whose structure *is* reconciliation. The
lattice in Section 3 can be read as the ent's write-once principle
combined with CRDT convergence guarantees.

---

## 3 System Architecture

Xudanu separates the persistence substrate from the editing engine.
The enfilade remains the persistence layer for all content; the
editing engine is replaceable. Two engines exist:

**The O-tree** (operational): a purpose-built collaborative editor
using three-way merge. It carries the full content model and has
served all traffic to date. Under concurrent interleaving it
sustains 62–74ms/op (measured on the FR-50 verification ledger).

**The lattice** (write-once CRDT): units are immutable
span-records addressed by Sequences allocated in gaps between
neighbours (deepening allocation — the address *is* the order; no
anchors, no timestamps). Deletes are region tombstones carrying
the deleter's causal context (an OR-set rule generalized over the
Sequence region algebra). Merge is union of units and tombstones —
commutative, associative, idempotent by construction.

A per-work switch governs which engine serves reads. The dual-write
shadow (FR-51 Phase 4) mirrors every edit to both engines; any
divergence is telemetry, not an assertion, until adjudicated. The
shadow caught two defects the primary engine had hidden — evidence
that the convergence guarantee is practical, not theoretical.

---

## 4 The Lattice in Measurement

Table 1 summarizes the engine comparison from the FR-50
verification ledger.

| Scenario | O-tree | Lattice | Ratio |
|---|---|---|---|
| Single-user edit | ~60µs/op | ~4µs/op | 15× |
| Two-session interleaved | 62–74ms/op | ~80µs/op | **~900×** |
| 16k-char doc, alternating | quadratic (fixed) | flat | — |

The lattice's cost is flat under interleaving because there is no
merge pass to pay. Memory is the honest cost: per-session views
are O(session × doc); tombstone accumulation is bounded by process
lifetime.

### 4.1 H(G): The Hypertextuality Profile

Adamski et al. [1] introduced H(G), a ten-coordinate profile of a
system's hypertextuality: relation density, reverse-traversability,
decentralisation, modularity, relation-type heterogeneity,
transclusion, structural entropy, path compactness, robustness, and
generative capacity. Their stress test corpus (Twitter/IRA data)
yielded θ (transclusion) = 0.119; the Web shows "limited
transclusion"; Xanadu's ideal of θ → 1 has never been measured —
no implementation existed.

Xudanu's combined corpus (97 works, 100 edges) yields:

| Coordinate | Value |
|---|---|
| ρrt (reverse-traversability) | **1.0** (by construction) |
| θ (transclusion) | **0.041** |
| η (type heterogeneity) | **0.603** |
| D (decentralisation) | 0.981 |
| Q (modularity) | 0.864 |

To our knowledge, this is the first measured nonzero θ on a
corpus with native transclusion. The profile occupies the corner
of H(G)-space — ρrt → 1, θ > 0, η high — that Adamski et al.
identify as Xanadu's explicit design goal.

---

## 5 Provenance, and How Strong the Claims Are

### 5.1 Per-span signatures

Every text element carries an Ed25519 signature over a
domain-separated BLAKE3 hash of its content fingerprint. Provenance
is stamped at element creation and is immutable (the lattice is
append-only). Verification recomputes the fingerprint from current
content and checks the signature against the author's public key.

Three verification states exist: *verified* (signature checks
against current content — text is bit-identical to what was signed),
*author-maintained* (stored signature fails because the author's
own later edits regrouped the span, but re-signing with the same
key succeeds), and *unsigned*.

### 5.2 Chained attribution log

Every provenance event appends to a hash-chained log where each
entry's hash covers the previous entry's hash plus the current
entry's content. The chain head is anchored to Bitcoin via
OpenTimestamps [27], providing a trust-minimized existence floor:
the entire attribution history provably existed before a specific
block. Only a 32-byte hash leaves the server.

### 5.3 Claim-strength boundaries

We distinguish three claim tiers:

**Cryptographically backed:** "This exact text was signed by this
key at this time"; "This passage existed in this work at this
state"; "The attribution record is unaltered."

**Server-conditioned:** "Key K = Alice" (the server's club
registry binds identity to keys; the server is its own CA);
timestamps are server-signed with an external floor.

**Known gaps:** No external timestamp anchoring pre-confirmation;
key revocation beyond rotation proofs; cross-org trust discovery
is manual.

This honesty table is itself a contribution: most provenance
systems overclaim. Separating what is provable from what is
asserted allows systems to improve without misleading.

---

## 6 LLM-Era Manipulation

### 6.1 Reference-over-copy

The system detects when a user is retyping a passage that already
exists in a readable work and offers to complete it as a live
transclusion with attribution. This is a three-tier matcher: (1)
an n-gram inverted index over readable works (hash → occurrences),
probing at each typed prefix; (2) MinHash similarity for
near-duplicates; (3) optional LLM phrasing of the suggestion card
(never in the matching path).

Measured on a seeded corpus: 6-word window; fires at the first
completed window (trigger at ~10% of passage typed); top-rank
precision 100%; p99 latency ~130µs (against a 50ms budget). The
gate runs as living armor in CI.

### 6.2 Hypertextual friction

Millard [15] operationalises *hypertextual friction* as deliberate
points of interpretive effort where AI proposals demand human
curation before entering the knowledge network. His suggest-only
pattern ("AI proposes, human selects") preserves agency.

Reference-over-copy embodies this pattern at the content-model
level. The suggestion card demands a curatorial choice; accepting
creates a signed, attributed transclusion (provenance by
construction, not by tagging); the decision itself is recorded in
the anchored attribution log. The friction that Millard experiences
as workflow discipline, Xudanu provides as architecture.

### 6.3 Author-type classification

Every session carries an author type: human (default), LLM
(with optional model identifier), historical, machine. Agents tag
their sessions on connection; every subsequent revision stamps the
type in its per-span provenance. The system can therefore answer
Millard's design consideration — "encode provenance at finer
granularity than 'AI-generated' versus 'human-written'" [15 §7.3]
— automatically, without manual tagging.

### 6.4 H(G) per author

Edges are partitioned by the author type of the work that created
the link; H(G) coordinates are computed on each sub-graph. This
enables the comparison that Adamski et al. pose as open question
Q4: does H(G_AI) differ measurably from H(G_human)? On our corpus,
the human sub-profile shows η = 0.764 (higher type diversity)
while the unattributed mass (works without revisions) shows η =
0.648 — the method works; the measurement becomes meaningful as
mixed-authorship corpora accumulate.

---

## 7 Related Work

**CRDTs.** Shapiro et al. [24] established the theoretical
foundation. Our lattice is a purpose-built text CRDT on
Gold-derived addressing (Sequence positions), not a Yjs/Yrs-style
generic library. The convergence guarantee is the same; the data
model is domain-specific.

**Content provenance.** C2PA/Content Credentials [28] provide
asset-level provenance (whole images, videos). Xudanu operates at
sub-asset granularity (per-passage text) with provenance that
travels across documents via transclusion. The approaches are
complementary.

**Hypertext systems.** Beaumont and Anderson's Seed Hypermedia [3]
is the closest sibling: a decentralised P2P network of open
hypertext documents with signed versions and transclusion, rooted
in Nelson [21]. Seed federates documents; Xudanu implements the
engine underneath. Their evaluation is prospective; ours is
measured. Their deployment at HT '26 as the conference's
experimental medium demonstrates that the audience is primed.

Anderson [2] traces how contemporary tools-for-thought have
rediscovered hypertext concepts unknowingly. Our system is what
those tools would be if they had known about forty years of
hypertext research.

**Single-implementer systems.** Alph [29], built by one person
since 2016, is the closest working sibling outside academia:
transclusion via an HTML element, visible links, and authorship
queries — implemented as an overlay on the existing Web, using
URL-based selectors and JSON-LD link documents. The choice is
deliberate interoperability at the cost of web-conditional
addressing: when a page moves, its references break. Xudanu
differs in layer, not spirit: a content-addressed substrate whose
addresses are permanent by construction, with convergent editing
and cryptographic provenance beneath. That a web overlay and a
rebuilt substrate now coexist as independent single-implementer
projects — from different eras — is itself evidence that the
model's time has returned.

**Implementation reports.** The genre is underrepresented at
Hypertext. Bernstein's Tinderbox papers [4, 5] are the model: a
system described honestly, with what works and what does not. We
follow that tradition.

---

## 8 Discussion: What Remains Hard

**Transclusion placement UX.** The hardest open problem. Where a
transcluded passage appears in the including document — and how
the user specifies that — has no satisfying solution. We have
iteratively improved inline placement, but the general case
(arbitrary position, overlapping inclusions, padding) remains
active work.

**Federation of provenance.** Cross-server transclusion carries
provenance; verifying it across trust domains does not yet work
end-to-end. The tumbler addressing model supports it; the trust
discovery does not.

**Server as CA.** The key-to-identity binding is server-vouched.
Key receipts (users exporting their public keys) mitigate; a
web-of-trust model is the long-term answer.

**Tombstone growth.** The lattice's append-only model means
tombstones accumulate. GC is decidable (the server knows all
views' counters) but not yet implemented [FR-57].

**Permanence is untested at its own timescale.** The oldest
functioning web links date to 1991–93 and survive by continuous
institutional service — W3C, archives, stubborn administrators —
not by architecture. The oldest functioning xanalogical links are
golden-scenario fixtures from the 1990–92 Green test suite, alive
today because a modern harness replays them. The creation dates
are contemporaneous; the difference is thirty-five years of
continuous service against none. Tumbler addressing promises what
URLs failed to deliver, but architectural permanence is a design
property until proven by decades of operation. Closing that gap
is the timescale this system must now survive.

---

## 9 Conclusion

The xanalogical model was never wrong about literature. The
machinery was too heavy for readers, and the tools did not exist.
The machinery is now cheap: convergence theory, content addressing,
and modern cryptography make the substrate practical. The tools now
assist: the system detects intent, offers references, and tracks
authorship to the character.

We have reported from the destination that Hypertext 2026's
position papers describe. The model deserves its second
implementation, and machine assistance is what finally makes it
reachable.

---

## Acknowledgments

The 1988–1992 Autodesk-era implementation team, working with Ted
Nelson, designed the model this system inherits. The 1999
open-source release made study possible. The modern Green test
harness and formal specification work in the lineage community
proved the old code still runs.

Xudanu is an independent, open-source project (Apache 2.0). It is
not affiliated with, endorsed by, or sponsored by Ted Nelson,
Project Xanadu, the Xanadu Operating Company, Autodesk Inc., or
the Udanax development team. All trademarks belong to their
respective owners.

---

## References

[1] Adamski, Błocki, Pisarski, Szewczyk. "Hypertext as the Native
    Architecture of Reality." HT '26, 36–41.

[2] Anderson. "The Future Is Not What It Used to Be: Hypertext,
    Note-Taking, And Tools for Thought." HT '26, 19–31.

[3] Beaumont, Anderson. "The Emergence of Shared Meaning in
    Hypermedia Networks with No Central Gravity." HT '26, 262–269.

[4] Bernstein. "Patterns of Hypertext." HT '98, 21–29.

[5] Bernstein. "Structural Patterns and Hypertext Rhetoric."
    Computing Surveys 31(4es), 1999.

[6] Brooker. "Computer, Enhance! Augmentation, Ideation, Hypertext."
    HT '24, 193–196.

[10] Lupi et al. "From Gardens to Landscapes: a new Foundation for
     Hypertext in the Age of Agentic LLMs." HT '26.

[15] Millard. "Permanently Under Construction: Hypertextual
     Friction in an AI-Augmented Zettelkasten." HT '26, 383–393.

[19] Nelson. *Literary Machines* 93.1. Mindful Press, 1993.

[20] Nelson. "The Heart of Connection: Hypermedia Unified by
     Transclusion." Communications of the ACM 38(8), 1995, 31–33.

[21] Nelson. "Xanalogical Structure, Needed Now More Than Ever:
     Parallel Documents, Deep Links to Content, Deep Versioning,
     and Deep Re-use." ACM Computing Surveys 31(4es), 1999.

[24] Shapiro, Preguiça, Baquero, Zawirski. "A comprehensive study
     of convergent and commutative replicated data types." Inria
     Technical Report, 2011.

[27] Todd. "OpenTimestamps." https://opentimestamps.org, 2016.

[28] C2PA Specification. https://c2pa.org, 2023.

[29] Moore, A. (LÆMEUR). "The Alph Hypertext System Project."
     https://alph.io/, 2016–2025. Accessed September 2026.
