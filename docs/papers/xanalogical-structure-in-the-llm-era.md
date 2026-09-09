# Paper Skeleton — Xanalogical Structure in the LLM Era

Working draft plan. Target: arXiv (cs.HC / cs.DL) for priority, then
ACM Hypertext for the credential. Every section below names the repo
documentation that feeds it, so the draft assembles from material
that already exists. Measurements quoted are from the verification
ledger; re-verify before submission.

---

## Title (candidates)

1. **Xanalogical Structure in the LLM Era: A Working Implementation
   of Transclusion, Typed Links, and Per-Passage Provenance**
2. The Docuverse, Reimplemented: Enfilades, CRDTs, and Machine
   Assistance in a Modern Xanalogical System
3. From Udanax Gold to Convergent Editing: An Implementation Report

Candidate 1 recommended: states model, era-thesis, and evidence in
one line.

## Authorship + venue checklist (before writing)

- [ ] arXiv account + endorsement for cs.HC (request via arXiv's
      endorsement system; an existing cs.HY/cs.DL author vouches)
- [ ] Decide author name + affiliation (independent researcher is
      legitimate; ORCID recommended)
- [ ] Attribution sweep: roster-only framing in body text; any
      individual binding requires a primary-evidence footnote
      (source header / FEBE manual / release notes)
- [ ] ACM Hypertext 2027 CFP — note deadlines; format the LaTeX to
      ACM `sigconf` from the start, arXiv takes the same source
- [ ] Trademark disclaimer in acknowledgments (same wording as the
      repo's) — required: the paper cites Project Xanadu heavily

## Abstract (draft — ~200 words)

The xanalogical model of literature — transclusion of content by
reference, unbreakable typed connections between specific passages,
and authorship traceable to the character — was designed in the
1960s and implemented in 1988–1992, but never reached users. We
argue the barrier was never the model's value but its cost of
manipulation: the mechanisms demanded expertise no reader could be
expected to have. We report on Xudanu, an open-source system that
implements the inherited model (enfilades with content-addressed
crums, tumbler-derived addressing, typed multi-ended links,
gathered end-sets) on modern infrastructure: a purpose-built
write-once CRDT for collaborative editing, per-passage Ed25519
attribution with an externally-anchored hash chain, and LLM-era
interaction in which the system itself detects re-typing of
existing content and offers it as a live transclusion. We measure
the editing engine against the system's earlier operational-
transform-style engine: under concurrent interleaving, the
write-once engine sustains ~80µs/op where the earlier engine
sustains 62–74ms/op (~900×), with convergence by construction.
Reuse detection fires within microseconds of six typed words. We
contribute an implementation report, honest claim-strength
boundaries for provenance systems, and a position: the xanalogical
barrier has moved from mechanism to interaction, and machine
assistance is what moves it.

## 1. Introduction

- The xanalogical thesis in one paragraph (Nelson's coinage,
  "quoted material knows its history" — cite Literary Machines,
  the 1999 "Xanalogical structure" essay)
- The two barriers: (a) implementation complexity (enfilades,
  divergence before CRDT theory existed), (b) user manipulation
  cost (readers could not operate the machinery)
- Claim: both barriers have moved. (a) → CRDT theory + content
  addressing + modern crypto; (b) → systems can now detect intent
  (reference-over-copy) and machine agents can operate the model
  as first-class editors

### Quotable passages from HT '26 (cite directly in §1, §7)

**On the renaissance (Adamski et al., §5.3):**
"Xanadu is reread not as a failed project but as an uncompromising
attempt to make high-dimensional hypertextality an explicit design
goal." — cite for the premise that the model was right.

**On the field's blindness to prior art (Anderson, §6.1):**
"Current TfT have rediscovered, unknowingly, ideas already known
in the hypertext community, while remaining blind both to that
prior art and to these alternative traditions." — cite for the gap
we fill.

**On the substrate being ready (Beaumont & Anderson, §2.4):**
"Recent advances in distributed systems, cryptographic identity,
version control algorithms, and peer-to-peer networking make it
possible to revisit long-standing hypertext and decentralisation
ambitions with new practical realism." — cite for the timing.

**On hypertext vs AI (Millard, §7.4):**
"Hypertext's foundational role — scaffolding structured thinking,
making connections visible, producing persistent artefacts — is
not diminished but amplified by generative AI." — cite for the
thesis alignment.

**On the engine/server positioning (Beaumont & Anderson, §2.5):**
"Hypermedia servers are not centres of control, but points of
authority for provenance, where authorship and licensing are
persistently maintained." — cite when positioning the hub.

- Contribution list: (1) full working implementation of the
  inherited model; (2) write-once lattice engine with measured
  900× under interleaving; (3) per-passage provenance with external
  anchoring and an explicit claim-strength analysis; (4) the
  reference-over-copy interaction loop with measured matching
  quality; (5) an implementation report genre for lineage systems

**Feeds:** docs/dev/provenance-flow-and-claims.md §1,
lattice-explainer (deployed), this repo's AGENTS.md lineage notes.

## 2. The inherited model (Xanadu, 1960–1999)

- Transclusion: inclusion by reference; the passage's identity
  travels with it
- Typed, multi-ended links as "sentences with blanks"; gathered
  end-sets filling one blank jointly
- Enfilades: dual-purpose trees (index + container); crums as
  subtree identities
- Tumblers: hierarchical universal addresses
- The ent: version-forking as structure (Drexler)
- Honest archaeology: what the 1999 release contains, what the
  literature says

**Attribution policy (decided 2026-09-08):** name the TEAM,
collectively — the 1988–92 Autodesk-era implementers (Gregory,
Miller, Greene, Drexler, Tribble, Pandya, King, Hill, working with
Nelson), cited to the release and the primary literature. Do NOT
bind specific structures to specific individuals unless verified
against primary evidence (source-file headers, the FEBE manual,
release notes — all present in this repo's inherited tree under
`original-code/xanadugold/src/` and `docs/`). Unverified bindings
from secondary summaries stay out of the paper; the verified tier
gets a footnote naming its evidence. Rationale: individual
attributions in our archaeology notes are inferred, and a printed
misattribution is both a scholarly error and a diplomatic one.

**Feeds:** docs/gold-link-model.md, gold-xudanu-complexity.html,
udanax-to-xudanu.html (the lineage-attribution tables there are
INFERRED — re-verify against the source tree before any binding
survives into the paper), the inherited source tree for primary
verification.

## 3. System architecture

- One substrate, two engines: the enfilade as persistence layer;
  the editing engine replaceable (the cutover method)
- The O-tree engine (operational, three-way merge) — the baseline
- The lattice engine: Sequence-keyed write-once units, region
  tombstones with causal context (OR-set rule over the region
  algebra), merge as union — commutative, associative, idempotent
- Dual-write shadow as migration and correctness oracle (it caught
  merge-garbling defects the primary engine hid — F6, F10)

**Feeds:** FR-51-enfilade-native-crdt.md (design + phase logs),
architecture.html, lattice-explainer.html.

## 4. The lattice in measurement

Table 1 (from the verification ledger):

| scenario | O-tree | lattice | ratio |
|---|---|---|---|
| single-user edit | ~60µs/op | ~4µs/op | 15× |
| two-session interleaved | 62–74 ms/op | ~80µs/op | **~900×** |
| 16k-char doc, alternating | quadratic (F10, fixed to 634µs after fix) | flat | — |

- Flat under interleaving: no merge pass exists to pay
- Memory: per-session views; the honest cost side
  (O(sessions × doc size)); tombstone accumulation bounded by
  process lifetime, GC design specified (FR-57)

**Feeds:** FR-50-performance-verification.md (ledger, scenarios
dual-engine-interleaved), FR-51 measurements.

## 5. Provenance, and how strong the claims are

- Per-span Ed25519 signatures over domain-separated content
  fingerprint folds; three verification states (verified /
  author-maintained / unsigned)
- Hash-chained attribution log; OpenTimestamps anchoring of chain
  heads to Bitcoin — trust-minimized existence floor; the
  walkthrough composition (one 32-byte anchor covers unbounded
  history)
- Range notarization: prove a quote existed without the document
- **Claim-strength table as a contribution**: what is
  cryptographically backed vs server-conditioned vs gap — the
  honesty analysis as a reusable pattern
- Landscape: C2PA is asset-granularity; PROV is a model without
  crypto; per-passage signatures over mutable collaborative text
  with cross-document travel is the gap this fills

**Feeds:** provenance-flow-and-claims.md (whole doc),
FR-60-ots-anchoring.md.

## 6. LLM-era manipulation

- The reference-over-copy loop: type a passage that exists →
  n-gram probe → suggestion card → accept inserts a live
  transclusion with attribution
- Measured matching: 6-word window; fires at first completed
  window; top-rank precision 100% on the corpus; p99 ~130µs
  (E-0 matrix); the honest noise analysis
- Authorship typing: human / machine / transcluded as
  first-class provenance classes (the disclosure-report substrate)
- The interaction grammar: hover = peek, click = travel to the
  passage's document, gather = passages jointly filling a blank;
  LLM assistance as authoring layer, never as content provenance
  (phrasing only — machine text never enters documents through
  the suggestion path)

**Feeds:** FR-58 spec + E-0 matrix in reuse_match.rs, the
navigation-demo corpus design, demo-script.md.

## 7. Related work

- CRDTs: Shapiro et al. (composable CRDTs), Kleppmann (CRDT apps),
  Attiya et al. (bounds); the lattice as a purpose-built text CRDT
  on Gold-derived addressing
- Operational transformation (Ellis/Revot); why the seam cost
  recurs
- Content provenance: C2PA/CAI (asset-level), W3C PROV (model)
- Hypertext history: Engelbart, Nelson, the 1999 Udanax release,
  modern Green/Gold restorations and formal-spec work in the
  lineage community (credit per repo conventions)
- Collaborative editors: Wiki lineage (weak links, copies);
  block-reference tools (Roam/Obsidian embeds — vault-local
  references, not content identity)

## 8. Discussion: what remains hard

- Transclusion placement UX (the open interaction problem)
- Federation of provenance across trust domains (TSA beside
  Bitcoin; cross-org key discovery)
- The server-as-CA boundary; key receipts as mitigation
- Honest limits: tombstone growth, view memory, single-server
  scale ceilings

## 9. Conclusion

The model was never wrong about literature; the machinery was too
heavy for readers. The machinery is now cheap, and the reader has
an assistant. Reproduction: everything cited is open source.

## HT '26 intelligence (London, proceedings live — mined 2026-09-08)

52 papers, 4 demos, 5 workshops. The community is actively in our
thesis-space but is position/theory-heavy — NO paper implements
transclusion or provenance as a working system; "enfilade" and
"content-addressing" appear nowhere. Our implementation report fills
the exact gap. Key citations and neighbors:

- **Beaumont & Anderson, "The Emergence of Shared Meaning in
  Hypermedia Networks with No Central Gravity"** — transclusion,
  provenance, versioning, decentralised authorship. CLOSEST
  neighbor; must cite and differentiate (they theorize; we ship).
- **Adamski, Błocki, Pisarski & Szewczyk, "Hypertext as the Native
  Architecture of Reality"** — H(G) hypertextuality profile with
  transclusion as a measured dimension; rereads Xanadu as "not a
  failed project." Direct support for the renaissance framing.
- **Lupi et al., "From Gardens to Landscapes"** — hypertext
  foundation for the agentic-LLM era. The era-claim, theorized.
- **Rahdari, Raj & Brusilovsky, "Hyperlayered Hypertext"** —
  agents + documents without dissolving reader inspection.
  (Adjacent to sisbell's direction — no Isbell in the list.)
- **Sharma et al., "Edit-Distance Links"** — CRDTs and version
  control diffs as link semantics.
- **Millard, "Permanently Under Construction"** — friction in
  AI-augmented Zettelkasten.
- **Revere & Blustein, "Transhierarchy redux" (demo)** —
  transclusion in outline processors.
- **Bernstein** ("A Reader's Workbench"; "The Link and the
  Journey" civic scale) — the community's voice; cite for genre
  calibration.

Track fit: "Systems, Protocols & Data Architectures" session is
our home. HT '27 is the target; watch for the CFP (~spring 2027).

## Seed Hypermedia — closest neighbor, differentiation notes (2026-09-08)

Full text clipped: docs/papers/ht26/pdfs/beaumont-anderson-2026-seed-hypermedia.md

The overlap is real and the separation is clean. Seed: decentralised
P2P network of open hypertext documents, block-level addressing,
embeds-as-transclusion, capability permissions, CC BY default — a
NETWORK-layer xanalogical system (Web-native, no Gold lineage).
Xudanu: single-server hub implementing the FULL Gold-lineage model —
enfilades, tumblers, CHARACTER-granularity, typed MULTI-ended links,
gathered end-sets, per-work licensing — with a measured CRDT engine
and Bitcoin-anchored per-span provenance. Cite as siblings answering
the same call (both root in Nelson '99 "Xanalogical Structure,
Needed Now More Than Ever"): Seed federates the documents; Xudanu
implements the engine. Their evaluation is prospective; ours is
measured. Their footnote 2 (Anderson/Carr/Millard HT'17 Wikipedia
transclusion study) is another citation for us.

Strategic note: Seed was DEPLOYED AT HT '26 as the conference's
experimental medium — the community literally ran a federated-
transclusion experiment on itself. An HT '27 implementation report
speaks directly into a primed room.

BONUS: their §2.5 sentence — "hypermedia servers are not centres of
control, but points of authority for provenance" — is the exact
Xudanu server model, published. Quote it when positioning the hub.

## Millard digest — friction as architecture vs friction as workflow (2026-09-08)

Full text: docs/papers/ht26/pdfs/millard-2026-hypertextual-friction.md

Autoethnography of an Obsidian Zettelkasten co-constructed with
Claude Code over 6 months (steering chair's own practice!). Key
findings: hypertextual friction (AI proposes, human curates) is
intrinsically rewarding, not cost; builder's advantage = hypertext's
existentialist demand; persistent hypertext beats ephemeral chat.

THREE DIRECT HOOKS FOR US:

1. His §7.3 design consideration — "Systems for scholarly knowledge
   work should encode provenance at finer granularity than
   'AI-generated' versus 'human-written'" — Xudanu HAS this:
   AuthorType (human/llm/historical/machine) per span, signed.
   Cite as the community asking for what we shipped.
2. The #human tag — manual, paragraph-level, trust-based provenance
   marking. Our per-span signatures + disclosure reports make the
   tag unnecessary: provenance is native, automatic, cryptographic.
   His is workflow discipline; ours is architecture.
3. The AI Memory Gap [Zindulka et al.] — attribution drift over
   time; his history entries as hedge. Our attribution log + Bitcoin
   anchoring is that hedge, permanent. "The persistent artefact
   remembers what the human mind does not" — our chained log IS
   that artefact.

FR-58 POSITIONING UPGRADE: reference-over-copy is hypertextual
friction at the CONTENT-MODEL level. Millard's friction lives in
workflow checkpoints (suggest-only); ours is structural — the
suggestion card demands a curatorial choice, and accepting creates
a signed, attributed transclusion (provenance by construction, not
by tagging). The decision itself lands in the anchored attribution
log. Friction that leaves a cryptographic record.

His suggest-only workflow = our suggestion card accept/decline.
Same principle, deeper substrate.

## H(G) digest — the invitation we were built to answer (2026-09-08)

Full text: docs/papers/ht26/pdfs/adamski-2026-hg-native-architecture.md

Ten-dimensional hypertextuality profile; Xanadu reread as "explicit
design telos: ρrt → 1, θ → 1, η high"; stress-tested on IRA tweets
(θ=0.119 — near-zero transclusion, like every corpus they could
test). §5.4 explicitly INVITES: "validate the profile against real
corpora."

THE OPPORTUNITY, precisely: their θ (transclusion) and ρrt
(reverse-traversability) coordinates have never been measured on a
system that actually realises them — Xanadu remains a "regulative
ideal... never measured because no implementation existed."
Xudanu IS the implementation: bidirectional typed links by
construction (ρrt = 1 exactly), real inline transclusions (θ
measurable and nonzero for the first time), η across 5+ link types,
AuthorType enabling their open Q4 (H(GAI) vs H(Ghuman)) on real
data. H(Xudanu docuverse) is a figure nobody else can produce, it
validates their framework exactly where they asked, and it turns
our §4 from "our engine is fast" into "our docuverse occupies the
corner of H(G)-space the field has only theorised." Plan: compute
the ten coordinates over the seeded docuverse + navigation-tour
corpus; one figure + one table in §4 or §6.

Also quotable for §1: the Xanadu-reread sentence, and their framing
of the AI question ("phantom nodes: σ without genuine τ") connects
to our provenance typing (machine-authored spans are marked, signed
— never phantom).

## Citation list to assemble (verify each before submission)

VERIFIED (from Seed's reference list):
- Nelson, T.H. "The Heart of Connection: Hypermedia Unified by
  Transclusion." CACM 38(8), 1995, 31–33.
- Nelson, T.H. "Xanalogical Structure, Needed Now More Than Ever:
  Parallel Documents, Deep Links to Content, Deep Versioning, and
  Deep Re-use." ACM Computing Surveys 31(4es), 1999, Article 33.
- Shapiro, Preguiça, Baquero, Zawirski. "A comprehensive study of
  convergent and commutative replicated data types." Inria TR, 2011.
- Anderson, Carr, Millard. "There and Here: Patterns of Content
  Transclusion in Wikipedia." HT '17, 115–124.
- Beaumont et al. "Seed Hypermedia." HT '24, 351–356.
- Beaumont & Anderson. "The Emergence of Shared Meaning in
  Hypermedia Networks with No Central Gravity." HT '26, 262–269.

- Nelson, Literary Machines (editions) — transclusion, xanalogical
- Nelson, "Xanalogical structure: Needed now more than ever" (1997)
- Udanax Gold/Green source release (1999) + release notes
- Gregory/Miller/Greene lineage (enfilade origin — locate primary
  documentation or cite via Nelson/historians)
- Shapiro, Preguiça, Baquero, Zawirski, "Conflict-free replicated
  data types" (2011) + "Composition" (SQPZ 11)
- Kleppmann et al., "Moving fast with software correctness" /
  CRDT text editors work; Attiya et al. lower bounds (2016)
- C2PA specification; W3C PROV-DM; OpenTimestamps (Todd, 2016)
- ACM Hypertext precedent papers for genre calibration

## Mechanics

- LaTeX, ACM sigconf template, same source to arXiv
- Figures: architecture diagram (from docs/architecture.html),
  lattice comparison chart (rebuild from Table 1 numbers),
  suggestion-card flow, claim-strength table
- Length target: 10–12 pages HT format
- Anonymization: NOT needed for arXiv; check HT 2027 policy for
  the submission track (likely not anonymized for the
  implementation track — verify)
