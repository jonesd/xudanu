# Research catalogue

Papers, articles, and systems the project engages with, each with its
relevance to Xudanu. A living document — entries are added when we
actually engage with them, not speculatively. Cross-referenced with
the paper draft's numbered references where they appear there.

## Xanadu primary sources

- **Nelson, *Literary Machines* 93.1.** Mindful Press, 1993.
  The design document. Tumblers, transclusion, transcopyright,
  FEBE. (Paper ref [19].)
- **Nelson, "The Heart of Connection: Hypermedia Unified by
  Transclusion." CACM 38(8), 1995.** The compact statement of the
  unification claim. (Paper ref [20].)
- **Nelson, "Xanalogical Structure, Needed Now More Than Ever."
  ACM Computing Surveys 31(4es), 1999.** The late summary —
  parallel documents, deep links, deep versioning, deep re-use.
  (Paper ref [21].)
- **Udanax Gold/Green source release, 1999.** The artifact Xudanu
  re-implements the model from. Enfilades, tumblers, FEBE protocol.
  Local copy: `original-code/xanadugold/`.

## Precursors

- **Bush, "As We May Think." Atlantic Monthly, 1945.** The trail
  concept — curated paths through documents — that Xudanu's trails
  descend from.

## Distributed systems and CRDTs

- **Shapiro, Preguiça, Baquero, Zawirski, "A comprehensive study of
  convergent and commutative replicated data types." Inria TR,
  2011.** The convergence theory the O-tree CRDT rests on. (Paper
  ref [24].)
- **Litt, Lim, Kleppmann, van Hardenberg, "Peritext: A CRDT for
  Collaborative Rich Text Editing." PACM HCI 6(CSCW2), 2022.
  https://www.inkandswitch.com/peritext/**
  Anchored format spans (before/after gap anchors; growth rules per
  mark type) and the conflict-surfacing alternative to LWW. Relevant
  twice: link ends should adopt non-growing anchor semantics (issue
  #195), and anchored marks are the mechanism for links surviving
  branch-merge — if/when branch-merge deliberation is built.
- **Lamport, "Time, Clocks, and the Ordering of Events in a
  Distributed System." CACM 21(7), 1978.** Logical timestamps;
  ancestor of the actor+timestamp naming Zed also cites.

## Provenance and trust

- **Todd, OpenTimestamps. 2016. https://opentimestamps.org**
  Bitcoin-anchored existence proofs; the paper's per-span anchoring
  claim. (Paper ref [27].)
- **C2PA Specification. https://c2pa.org, 2023.** Content provenance
  metadata standard; contrasted in the paper. (Paper ref [28].)

## Modern convergence (the census, in depth)

- **Moore (LÆMEUR), The Alph Hypertext System Project.
  https://alph.io/, 2016–.** Web-overlay xanalogical work running
  since 2016; cited as prior art. (Paper ref [29].)
- **Sobo, "Xanadu Was Waiting for Agents." Zed Industries,
  September 2026. https://zed.dev/blog/agentic-xanadu**
  Industrial-scale convergence from the CRDT tradition: DeltaDB
  fragments, anchors, permanence, agents as the users the model
  waited for. (Paper ref [30].)
- **sisbell, skep. https://github.com/sisbell/skep** Rust
  content-addressed hypertext substrate with stigmergic agent
  coordination; also the udanu-test-harness (263 golden scenarios
  against the original code) and xanadu-spec.
- **Dubinko, "How Xanadu Works: technical overview." 2009.
  https://dubinko.info/blog/2009/11/how-xanadu-works/**
  The reference explainer of the 93.1 design, 17 years standing.
  The planned "How Xudanu Works" doc is its modern companion.

## Critiques (held deliberately)

- **Gwern, "Xanadu is a vaporware failure." https://gwern.net/xanadu**
  The strongest sustained counterargument (solved problems nobody
  had; unstable economic equilibrium). Engaged, not dismissed — the
  paper's positioning must survive reading it.
- **Wolf, "The Curse of Xanadu." Wired, June 1995.** The
  mismanagement narrative; context for why "unfinished" needs
  care in our writing.

## Collected

- **HT '26 census observation.** Fifty-plus papers on hypertext
  foundations at the conference; none presented a working
  transclusion engine. The theory/practice gap the project sits in.
