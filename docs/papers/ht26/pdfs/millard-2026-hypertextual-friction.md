# Permanently Under Construction: Hypertextual Friction in an AI-Augmented Zettelkasten

- **Author:** David E. Millard
- **Venue:** HT '26: Proceedings of the 37th ACM Conference on Hypertext (London), pp. 383–393
- **DOI:** https://doi.org/10.1145/3800935.3830837
- **Published:** 05 September 2026 — Open access
- **Clipped:** 2026-09-08 (full text incl. references)

---

## Abstract

Contemporary AI tools for knowledge work encourage users to query and consume rather than construct and connect, risking a loss of the human agency that makes such work intellectually valuable. This paper presents an autoethnographic case study of an AI-augmented Zettelkasten, co-constructed within Obsidian using Claude Code. Through daily use over six months, the system and the researcher's practices co-evolved via a bootstrapping process in which the system's own conceptual resources were used to theorise its design, derive explicit values, and audit its own workflows. The resulting system operationalises hypertextual friction: deliberate points of interpretive effort where AI-generated proposals demand human curation before entering the knowledge network. The paper argues that these curatorial decisions are not obstacles to thinking but the site where thinking occurs, and that they are experienced as intrinsically rewarding rather than as cognitive cost. While the system works best for the person who built it (a builder's advantage), this reflects an existentialist commitment that hypertext has always required of its users. These findings suggest that hypertext's role in scaffolding structured thinking is amplified rather than diminished by generative AI, provided the system demands co-construction rather than consumption.

## 1 Introduction

Personal note-taking and scholarly writing are cognitively demanding practices in which composing text is inseparable from thinking, yet LLMs increasingly invite us to delegate this labour. When AI writes summaries or builds arguments on our behalf, it accelerates cognitive offloading and the deskilling of precisely those capacities that writing is supposed to exercise [13], acting as 'The Thief of Reason' [20]. If AI systems handle both writing and structure, our role in sense-making becomes dangerously thin [27].

Dominant AI interfaces — linear chats — create a trust paradox: accept unverifiable text at face value or re-do the work to check it. Hypertext offers the alternative: augmentation rather than automation [4,7,6,12] — systems that make their organisational logic visible rather than hiding synthesis behind seamless outputs [19].

The system: an AI-augmented Zettelkasten built in Obsidian, co-constructed with Claude Code, deliberately embedding hypertextual friction [16]. AI services propose summaries, links, and structural moves that ALWAYS require user evaluation. The hypertext becomes a 'Tool for Thought' [3], turning opaque model behaviour into a navigable landscape the user actively curates.

Three contributions: (1) operationalises hypertextual friction as a design strategy; (2) autoethnographic account of an evolving AI-augmented Zettelkasten via Engelbart's bootstrapping [12]; (3) experiential findings — friction as intrinsic reward; value inseparable from existentialist commitment; persistent navigable hypertext as the differentiator from chat.

## 2 Background

### 2.1 Hypertext, augmentation, and friction
Augmentation tradition (Bush [8], Engelbart [12]): tools work best when they make structure visible and keep humans engaged. Chalmers & Galani's seamful design [10]; productive friction [11]; Wu et al. [28]: nonlinear LLM interface improved creativity/synthesis but rated LOWER usability — friction experienced as cost in the lab.

Liu & Almeda [16] introduced hypertextual friction (vs algorithmic systems foregrounding 'outputs driven by computational models or agents') — design stance centring friction, traceability, structure. This paper embeds it in hypertext co-construction: jointly building a persistent hypertext with an AI, link by link.

### 2.2 Zettelkasten
Luhmann's slip-box [17]: atomic notes + explicit links; interlocutor; structure arises from use. Digital: Obsidian etc. Chosen precisely because its granular externalisation of associative structure is where agentic AI can thrive — co-construction generating friction rather than seamless automation.

### 2.3 LLMs in writing
Cognitive offloading mediates AI use → reduced critical thinking [13]; sycophancy [18]; authorship drift frameworks [23,15] remain prose-focused. This paper shifts the site of collaboration from TEXT GENERATION to STRUCTURE: building persistent hypertext, keeping the human as author of the knowledge network rather than editor of machine output.

### 2.4 Existing AI note tools
Category 1 (AI as interface to corpus): NotebookLM, Copilot Notebooks — linear chat, ephemeral, no constructive human role. Category 2 (human-built structure + AI initiative): Roam, Tinderbox, Logseq, Obsidian+AI — bidirectional links persist; AI suggests within human-made structure. Atzenbeck et al. [5]: spatial hypertext interrupts passive consumption — structure delivered vs structure made.

## 3 Methodology: analytic autoethnography [2]
Single researcher, 25 years in hypertext; dual role constitutive not confounding. Senior-led partnership: human retains direction/final authority; AI contributes summarisation, concept extraction, link proposal, narrative generation — "a principal investigator working with a research fellow."

Nov 2025–Apr 2026. Data: vault daily history entries (AI-generated narrative nodes) + rationale file (contemporaneous design decisions). No formal coding; significant episodes: design pivots, values conflicts, structural change. Negative cases were HUMAN breakdowns (not reading history, accepting without engagement) — friction places requirements on motivation, not only design.

## 4 System overview
Obsidian + three layers: conceptual structure (atomic notes 200–400 words → hubs → Maps of Content as narrative trails, drawing on Bush's associative trail), tools/integrations, command vocabulary.

Components via MCP: Obsidian (markdown + wiki-links + Dataview; maturity model sapling/fern/tree), Claude Code (terminal, CLAUDE.md conventions, persistent memory), Smart Connections (local vector embeddings), Gemini CLI (headless large-doc summarisation — 80–90% token savings; "Gemini for extraction, Claude for reasoning"), Zotero (reference queries).

Commands: Knowledge Capture (ingest-resource, create-literature-note), Academic Grounding (find-papers, evaluate-papers), Textual Production (expand-moc). Note creation is INTERACTIVE: Claude proposes, identifies overlaps; human accepts/selects/redirects. Daily history entry per session.

## 5 System evolution
Bootstrapping (Engelbart): the vault was built WITH the AI; tool and practice co-evolution part of the phenomenon.

**Suggest-only workflow** (foundational): AI proposes candidate notes and waits for explicit approval. Motivations: recursive explosion risk without human filter; human as filter AND exit point. "The AI suggests, the human selects" — human as curator rather than consumer.

**The #human tag inversion**: in a mostly-AI-generated vault, the exception needing protection is HUMAN text. Tagged paragraphs protected from AI modification. "The inversion is telling: the exception that needs protection is not the machine's contribution but the human's."

Monolithic instruction problem → progressive disclosure skills. Sub-agents → shared skills ("knowledge gains value through connection rather than isolation"). Voice: epistemological pluralism — tentative phrasing vs RLHF-driven confident orthodoxy; attribution preserving source-to-claim chains.

**Values document** (bootstrapped from the vault's own concepts, via an essay assembled from atomic notes through a MOC): ten values — Human Agency as Non-Negotiable; Transparency Over Opacity; Beneficial Friction (eliminate tedious friction, preserve cognitive friction); Augmentation Over Automation; Spatial & Associative Thinking; Reciprocal Challenge (resist sycophancy); Cognitive Preservation; **Provenance & Attribution** ("maintain clear chains from source material through interpretation to synthesis; distinguish evidential weight"); Emergent Structure; Humanism as Foundation.

**Self-audit**: AI audited every workflow against the values; found Reciprocal Challenge systematically underserved (helpful, obedient, never pushing back) → pre-creation awareness checks, structural previews, challenge-directing reading strategies, reflection prompts.

## 6 Hypertextual friction in practice
Vault at 6 months: 600+ files — 450 atomic, 72 literature, 33 resources, 20 drafts, 17 hubs, 10 MOCs, 64 history entries.

Example workflow (Liu & Almeda ingestion): one command → Zotero metadata → Gemini summary → literature note → semantic search → engagement guide (directing attention toward CHALLENGING material) → candidate atomic notes (3 proposed, weakest flagged) → human accepts 2, redirects 1 into existing note. ~15 new bidirectional links; half a dozen curatorial decisions.

**Selection and negotiation** — the primary locus of friction: acceptance, acceptance-with-reframing, merging, rejection-as-redundant, spotting what the AI missed. ~half of all proposals rejected or reshaped. Requires holding proposed note against existing network — tacit topology knowledge the AI does not share. "I am the exit condition" (against recursive growth).

**MOCs as narrative trails** (top-down friction): human does architectural thinking (which notes, order, argument); AI generates prose (/expand-moc). 40-note MOC assembled manually, then expanded.

**Preserving human voice**: #human tag anchors authentic voice; forces AI to integrate rather than overwrite. Tentative voice = textual friction (provisional phrasing resists treating as settled). History entries = review friction in thematic context.

## 7 Discussion
**Friction as enjoyment, not endurance**: curatorial decisions "are not obstacles to the real work; they are the real work." Creative-practice engagement, not speed-bump discomfort. Vs Wu et al.'s lab finding — difference may be OWNERSHIP (built over months vs handed a tool for a session). AI Memory Gap [29]: attribution of contributions degrades; history entries as hedge — "The persistent artefact remembers what the human mind does not."

**Builder's advantage**: system works best for its builder — not a failed generalisation but hypertext's existentialist demand (Anderson & Millard's "requirement for non-regularity" [3]); existence precedes essence; meaning constructed through choice. Design implication: systems must create genuine space for users to shape them.

**Design considerations**: (1) "Systems for scholarly knowledge work should encode provenance at finer granularity than 'AI-generated' versus 'human-written'." (2) vault better as thinking space than production pipeline. (3) friction requires active participation — beneficial friction is not automatic.

**Hypertext as persistent artefact**: chat = ephemeral synthesis; vault persists; direct navigation outnumbers conversational queries; compounding value; externalised associative memory; "Bush's associative trail made concrete and collaborative."

## 8 Limitations
Single case; builder's-advantage circularity; domain self-reference (building the tool IS doing the research). Motivates multi-builder studies and unrelated-domain observations.

## 9 Conclusion
Three findings: friction as intrinsic reward; builder's advantage as existentialist commitment; persistent navigable hypertext as the differentiator. "Hypertext has always asked its users to construct meaning rather than find it. In the age of AI, that demand is more urgent, not less."

## Acknowledgments
"#human This paper was co-constructed with the AI Zettelkasten tool described in this paper... every section of the paper was touched by both AI and author, and yet — because of the intermediate hypertext structure — the ideas, arguments, insights, and experiences, remain the author's own."

## Key references for OUR paper
- [16] Liu & Almeda. "Agency Among Agents: Designing with Hypertextual Friction in the Algorithmic Web." HT '25 Adjunct, 30–34. (origin of hypertextual friction)
- [3] Anderson & Millard. "Seven Hypertexts." HT '23, 1–15. (hypertext ideology; existentialist reading)
- [20] Millard. "The Shadow of the Machine: Hypertext in the Age of AI." NHT '25 Workshop.
- [29] Zindulka et al. "The AI Memory Gap: Users Misremember What They Created With AI or Without." arXiv:2509.11851. (provenance as memory hedge — OUR argument!)
- [13] Gerlich. "AI Tools in Society: Impacts on Cognitive Offloading." Societies 15(1), 2025.
- [5] Atzenbeck, Herder, Roßner. "Breaking the routine: spatial hypertext..." NRHMM 29(1), 2023.
