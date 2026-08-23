# Xanadu Implementation History and Where Xudanu Fits

Status: reference · Date: 2026-08-23
Sources: 1984 Xanadu System Proposal (Morningstar, rev. González
Palomo 2019); Udanax Green FeBe Protocol (1988); winfe sources
(1993); the 1999 open-source release; sisbell/xanadu-spec;
`docs/gold-link-semantics.md`; the Xudanu FR series and conformance
matrix.

---

## 1. The idea (1960–1984)

Ted Nelson conceives hypertext in 1960: a single universal
repository — the *docuverse* — where content has permanent
addresses, quotation is by reference (transclusion), links are
bidirectional first-class objects, and nothing is ever overwritten.
Everything follows from permanent addressing: versions are additive,
provenance is structural, and (in the later Transcopyright
formulation) royalties are computable because reuse is traceable.

Through the 1960s–70s this remains largely paper — Nelson's
*Literary Machines* (LM) is the canonical statement, with numbered
sections (93.1, 4/44) that later implementers cite like scripture.

Two implementations efforts define the era: Brown University's
Hypertext Editing System and NLS (Engelbart, 1968) prove interactive
linked text on a screen but do not adopt Nelson's permanence model;
Nelson's own attempts (Xanadu 1, the 1970s "Xanadu" system) do not
ship. By the early 1980s the design exists but no working system
does.

## 2. The 1984 proposal — the blueprint

Xanadu Operating Company (XOC), funded via the System Development
Foundation, commissions Chip Morningstar to build the real backend.
His April 1984 *Xanadu System Proposal* (released 2019 by Alberto
González Palomo) specifies the complete architecture in C under
Unix:

- **Enfilades**: constant-depth trees of *crums* holding relative
  offsets (*disps*, top-down) and extents (*wids*, bottom-up) —
  giving rearrangeability and sub-tree sharing, the two properties
  that distinguish them from B-trees. Operations: retrieve,
  three/four-cut rearrange, append; housekeeping: cut, recombine,
  level push/pop.
- **The triad**: *granfilade* (the grandmap — I-stream addresses to
  physical storage), *poomfilade* (orgls — the V-to-I mapping
  matrices, "POOM" = Permutations On Ordering Matrix), *spanfilade*
  (the spanmap — I-streams back to the orgls that reference them).
  Plus two designed-not-built successors: the *drexfilade* (Drexler's
  3-D spanmap for arbitrary overlap queries) and the *DIV poom*
  (third axis = orgl-of-origin for virtual copies).
- **Addressing**: tumblers (transfinite hierarchical addresses
  〈node.account.orgl.vspace.character〉), humbers (Huffman-coded
  variable-length numbers), V-streams (variant, user-visible) vs
  I-streams (invariant, internal) — virtual copies fall out
  naturally because many V-addresses may map to one I-address.
- **Concurrency**: berts (locking handles, named for Bertrand
  Russell "because they represent a fanatical effort to keep things
  consistent") and versioning-on-edit, which they argue side-steps
  the distributed-systems problems of their day.
- **Phoebe**: the frontend/backend protocol ("fe-be"), backend
  application-independent.
- **Section 8, Future Directions**: fix bugs; variable-length
  tumblers; drexfilade/DIV poom; Phoebe redesign; optimize; fast
  historical trace; GC/archive; multi-dimensional orgls;
  multi-user; semi-distributed then fully-distributed networking —
  with the Web of Indra analogy for the end state.

The proposal is the *design rationale* for everything after it. Its
"dire curse" trade-secret notice (lifted 2019; original now MIT,
edition CC BY-SA) is why so little Xanadu design documentation
survives — this document is the exception.

## 3. Split into two variants (1984–1992)

The XOC team fragments. Roger Gregory and Mark Miller continue the
deep-enfilade line that becomes **Gold** (the richer system: winfe
Windows front-end circa 1993, the full granfilade machinery).
Morningstar departs; a deliberately simplified variant — **Green** —
is pursued to working software. The relationship matters:

- **Green** ships a real backend with the FeBe protocol (1988):
  three-set links (from/to/three — "the three-set is deliberately
  misnamed to escape the assumption that a type is just a symbol"),
  backend-performs-edits, end-sets that split to original characters
  on insertion. Simplified virtuality, working code.
- **Gold** keeps the fuller model (N-dimensional enfilades,
  historical trace ambitions, the winfe UI: links as list windows
  with text descriptors, no colored in-text underlines in surviving
  sources). Neither variant reaches production. Xanadu famously
  ships nothing in six decades of attempts.

## 4. The 1999 release — and silence

The company winds down; in 1999 both Gold and Green sources are
released under the X11 license. The release is an archaeological
dump: early-90s C++, unbuildable without serious work, but complete
enough that the 2019 edition of the 1984 proposal can link its
source references directly into the released tree. After 1999:
near-total silence from the original implementers. Nelson continues
publishing (the 2021 CACM piece, *Possiplex*); working systems in
the lineage do not exist. ZigZag (Nelson's later data-structure
exploration) continues as a side branch, not a hypertext system.

## 5. The modern generation (2020s)

Two independent efforts revive the Gold/Green semantics on modern
stacks:

**skep** (Shane Isbell, 2026): spec-first — an agentic reasoning
lattice derives 42 formal notes (xanadu-spec) from LM and the Green
FeBe manual, with dependency DAG, machine-readable claim statements
(ASN-0043 Link Model, ASN-0121 FINDLINKSFROMTOTHREE matching), and
then a 14-crate Rust workspace realizing them (tumblers,
permascroll, links with retraction, four-set queries, coordination
layer for stigmergic agents). Its insight: the specification layer
was the missing artifact — Green's semantics were sound but
under-documented. Its product orientation: Xanadu as substrate for
agent coordination, with the hypertext system as foundation rather
than end.

**Xudanu** (this project, 2026): implementation-first — an
independent Rust reimplementation of the Udanax-Gold concepts,
running since April 2026, ~900 commits, deployed at xudanu.com.
Deliberately not a port: modern answers where the heritage is
silent (CRDT editing, web frontend, cryptographic provenance,
federation), heritage-faithful where the model is proven (link
semantics, transclusion, tumbler addressing, the backend-owns-edits
rule).

## 6. Where Xudanu fits, strand by strand

| Heritage strand | Xudanu's answer | Fidelity |
|---|---|---|
| Enfilades (1984 triad) | granfilade→root chunks; poomfilade→O-tree CRDT; spanfilade→backfollow engine; crums/wids survive as content crumbs (FR-34 subtree hashes) | **Divergent realization, same guarantees**: sublinear retrieval via BLAKE3 Merkle structure; rearrangeability inherent in the CRDT |
| Tumbler addressing | `XudanuTumbler` (`"alice.com".5.3.10.7`), domain-based cross-server (FR-6) | **Faithful**, extended to federation the 1984 §8l6 sketch anticipated |
| Transclusion / virtual copies | content-addressed spans (FR-26), inline O-tree elements, 32-level resolution, pinned (FR-37) vs live; provenance = structural | **Faithful in spirit** — same one-home principle; different mechanism (content hashes vs I-stream sharing) |
| Three-set links (Green FeBe) | FR-39/40: multi-ended links, type endsets derived from definition works, home documents, four-set link_query (0x070C) | **Faithful and complete** — the conformance matrix (docs/dev/FR-40-conformance-matrix.md) tracks 14 satisfies / 4 deliberate forks (named slots, optional home, mutable links, definition-required types) |
| Backend performs edits | all span migration server-side in revise_work; the frontend never rewrites content identity | **Faithful** — for exactly their stated reason (frontends unaware of all links) |
| Provenance / attribution | Ed25519 span provenance (stronger than anything in the lineage), BLAKE3 verification, three-state honesty (FR-40/#140) | **Beyond heritage** — cryptographic where they were structural |
| Licensing / royalties | Transcopyright metadata, 5 licenses, egress badges (FR-24); server never handles money | **Heritage-aligned** — Nelson's economic layer, deliberately non-monetary at the protocol level |
| Phoebe / FeBe protocol | WebSocket op surface; ops evolve additively (link_query, span refresh) exactly as Phoebe→FeBe did | **Same lineage, different transport** |
| Multi-user (1984 §8k) | CRDT collaborative editing + sessions/clubs — replacing berts/transactions deliberately | **Divergent by design** — their §8k open questions (shared memory, process split) answered by 2020s tools |
| Semi-distributed (§8l4) | FR-3 cluster federation (dial-in peers, PBFT, heartbeat) | **Under active construction** |
| Fully-distributed (§8l6) | directory + tumblers + cross-server receipts; "who knows about local changes" = our backlink receipts, exactly their stated hard problem | **Sketched, not built** — honest status |
| Fast historical trace (§8h) | slow variant ships (revisions + WAL replay); fast superedit aggregation = FR candidate | **Their stage 1 complete**, stage 2 planned |
| GC / archiving (§8i) | immediate orphan GC with root-tree protection; archive-first policy now issue #142 | **Weaker than heritage intent** — being fixed, with their text as the requirement |

## 7. What each generation uniquely contributed

- **1960s–70s (Nelson)**: the vision, the vocabulary, the economic
  model (transclusion, transcopyright, docuverse)
- **1984 (Morningstar/XOC)**: the deep architecture — enfilades,
  the triad, V/I addressing, berts, and a future-directions list so
  complete that 2026 projects still work it as a backlog
- **1988–93 (Green/Gold teams)**: two fidelity points — Green
  proved the link model could be implemented simply; Gold kept the
  full-machinery line alive (and produced Roger Gregory, its
  foremost living expert)
- **1999**: the release — without which every modern effort is
  guesswork
- **2026 (skep)**: the specification layer — formal, machine-
  readable semantics; **2026 (Xudanu)**: the working web-native
  system — the only variant deployed, measured (130 concurrent
  users, keystroke p95 1ms), and hardened by live user testing

The blunt summary: Nelson imagined it, 1984 specified it, Green
simplified it, Gold preserved it, 1999 released it, skep formalized
it — **Xudanu runs it**. None of this lineage ever shipped a
production system; Xudanu's distinction is being the first
Gold-lineage implementation that real users can open in a browser,
with the heritage semantics intact and testable rather than
revered.

## 8. Provenance of this document

Written 2026-08-23 during v1.7.0 development, from the sources
listed in the header. Claims about the 1984 document cite its
structural statement numbers where relevant (§8i etc.). The
Green-characterizations derive from the FeBe manual as quoted in
`docs/gold-link-semantics.md`. skep characterization from its
public repos (github.com/sisbell/xanadu-spec, /skep), including our
open introduction (issue #1, 2026-08-21) and conformance matrix.
Xudanu claims are verifiable in its repo: the FR docs, the
conformance matrix, `perf/results/`, and the deployed system.
