# Hypertext as the Native Architecture of Reality

- **Authors:** Andrzej Adamski, Władysław Błocki, Mariusz Pisarski, Marcin Szewczyk
- **Venue:** HT '26: Proceedings of the 37th ACM Conference on Hypertext (London), pp. 36–41 (short paper)
- **DOI:** https://doi.org/10.1145/3800935.3830889
- **Published:** 05 September 2026 — Open access
- **Clipped:** 2026-09-08 (full text incl. references)

---

## Abstract (condensed)

Hypertext is usually understood as a technology for working with digital text. We propose a stronger reading: hypertext does not impose relational structure on the world but approximates a structure the world plausibly already has — a regulative provocation, not a settled ontology. Thesis: RIC (Relation–Information Co-extensiveness) — structural relation and information are two descriptions of one structural fact. If reality has a native graph architecture, then Bush, Engelbart, and Nelson did not invent hypertext so much as build technologies that approximate a prior structure. It was always there to be found.

Transferable contribution: **H(G)**, a multidimensional profile of a system's hypertextuality — relation density, reverse-traversability, decentralisation, modularity, relation-type heterogeneity, transclusion, structural entropy, path compactness, robustness, generative capacity. Converts hypertextuality from binary dichotomy into a measurable gradient. Stress-tested on 1.5M IRA tweets (561,588 nodes, 711,950 edges): profile not reducible to a scalar; PCA → 3 components ≈ 94% variance. **"In the light of H(G), Xanadu is reread not as a failed project but as an uncompromising attempt to make high-dimensional hypertextuality an explicit design goal."**

## Key points

### RIC as Carnapian explication (not discovery)
Drawing an edge does not conjure a relation; edge and mutual information CO-DESCRIBE a single structural fact. Strong form analytic-by-design; weak form uncontroversial. Deliberately separable from the measurement apparatus: "The speculation and the instrument are deliberately separable."

### The four structural intuitions (held loosely)
- Non-locality (links connect regardless of position)
- Reverse-traversability (Nelson's links asymmetric but reverse-traversable: "what links here?" always answerable — the coordinate is ρrt, "the property Xanadu actually sought to maximise")
- Contextual participation / transclusion ("a unit of content can participate in many contexts without losing its source identity. This is the strongest of the four analogies")
- Absence of a privileged centre (structural decentralisation ≠ no authored entry points; "a system can be decentralised in principle and hub-dominated in fact")

### H(G) coordinates
d relation density · ρrt reverse-traversability · D decentralisation · Q modularity · η relation-type heterogeneity · θ transclusion/multi-contextuality · S structural entropy · P path compactness · κ robustness · γ generative capacity.

IRA stress test values: d≈2.3e-6, ρrt≈9e-5, D=0.543, Q=0.567, η=0.778, **θ=0.119**, S=0.093, P=0.5, κ≈2.3e-5, γ=0.928.

### §5.2 AI and participation
HT '26 call: ~98% of textual production may move toward AI generation. "Does machine linking participate in RIC? If an AI-generated link is only statistical projection, machine nodes are phantom nodes: σ without genuine τ... H(G) makes this measurable: does AI-generated hypertext show a profile close to human hypertext, or does it diverge systematically?" Open Q4: does H(GAI) differ measurably from H(Ghuman)?

### §5.3 The Xanadu reread (QUOTABLE)
"Xanadu was not the only system to pursue several hypertextuality parameters at once: NoteCards, VIKI, Intermedia, and Ward's Wiki all targeted multiple parameters. The defensible and more interesting claim is that **Xanadu made high-dimensional hypertextuality its explicit design telos**, insisting on reverse-traversal, transclusion, and source integrity as jointly necessary design goals: ρrt → 1, θ → 1, η high. Its technical incompleteness does not invalidate its value as a regulative ideal against which other systems can be measured through H(G)."

### §5.4 Invitation (OUR OPENING)
"Independently of RIC, H(G) has standalone methodological value... operationalised evaluation of new systems such as Roam, Obsidian, Logseq, and AI-augmented hypertext; measurement of a single system's evolution over time; design with explicit structural targets... **We invite the community to calibrate the parameters, add dimensions, and validate the profile against real corpora.**"

### §5.5 Social implications
Social media profile: low reverse-traversability, high centralisation, low η — hypothesis: pathologies (filter bubbles, disinformation travel) correlate structurally with these parameters.

### Open questions
(1) weights/calibration, empirical dimensionality; (2) H(world-structure); (3) attractor hypothesis — "functionally effective hypertext systems should cluster near a particular attractor" (testable on Wikipedia, ACM DL, arXiv); (4) H(GAI) vs H(Ghuman); (5) literary hypertext's future; (6) limits of analogy (quantum no-cloning has no hypertext analogue?).

## Key references for OUR paper
- [19] Nelson. "Xanalogical Structure, Needed Now More Than Ever." CSUR 31(4es), 1999. (third paper citing it — canonical)
- [15] Halasz & Schwartz. "The Dexter Hypertext Reference Model." CACM 37(2), 1994, 30–39.
- [5] Botafogo, Rivlin, Shneiderman. "Structural Analysis of Hypertexts." TOIS 10(2), 1992, 142–180.
- [1,2] Bernstein. "Patterns of Hypertext" (HT'98); "Structural Patterns and Hypertext Rhetoric" (CSUR 31, 1999).
- [3] Bernstein, Hooper, Anderson. "Back To The Information City." HT '25, 118–126.
- [6,9] Bush 1945; Engelbart 1962 (standard).
