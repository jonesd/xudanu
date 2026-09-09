# HT '26 Learnings — Applicability to Xudanu

Synthesis of the four clipped HT '26 papers (Anderson, Beaumont &
Anderson, Millard, Adamski et al.) filtered for what changes,
extends, or validates our direction. Each item: the learning, its
source, and the concrete action (if any).

---

## 1. THE FIELD IS PRIMED FOR WHAT WE SHIPPED

**Learning:** Three separate position papers argue hypertext needs
a "new foundation" for the LLM era; the community feels its
substrate shifting and is theorizing rapidly while building almost
nothing. 52 papers; zero working transclusion engines; "enfilade"
and "content-addressing" appear nowhere.

**Sources:** All four papers; the full proceedings TOC.

**Action:** Our implementation report fills the exact gap. No
change needed — just submit. The paper's positioning writes itself:
"the community describes the destination; we report from it."

---

## 2. PROVENANCE AT FINER GRANULARITY IS AN OPEN NEED

**Learning:** Millard's §7.3 design consideration — "Systems for
scholarary knowledge work should encode provenance at finer
granularity than 'AI-generated' versus 'human-written'." His
#human tag is a manual, paragraph-level, trust-based workaround.

**Source:** Millard (friction paper), §7.3.

**Action:** ALREADY SHIPPED. AuthorType per span (human / llm /
machine / historical), Ed25519-signed, is exactly what he asks
for. The paper should quote this and note the delta: his is
workflow discipline; ours is architecture (provenance is native
and automatic, not tagged). No build needed — but the AI-disclosure
report (FR-61 S3) turns this into a visible artifact.

---

## 3. HYPERTEXTUAL FRICTION IS A DESIGN STANCE, NOT A BUG

**Learning:** Friction (the curatorial pause where AI proposals
demand human evaluation) is experienced as intrinsically rewarding,
not cognitive cost. The suggest-only pattern (AI proposes, human
selects) preserves agency. BUT: Millard notes the friction requires
active participation — "beneficial friction is not automatic."

**Source:** Millard §6.3, §7.1; also Anderson's TfT (typed links
add friction vs wiki-links).

**Action:** FR-58's suggestion card IS hypertextual friction at the
content-model level — accept creates a signed transclusion (the
choice leaves a cryptographic record). Currently off by default.
Consider: the disclosure report (FR-61 S3) surfaces the friction/
provenance trade-off for admin review, making the system's values
visible.

---

## 4. THE SEED HYPERMEDIA MODEL IS OUR SIBLING, NOT COMPETITOR

**Learning:** Seed = decentralised P2P network of open hypertext
documents. Same Nelson '99 roots. Their key sentence: "hypermedia
servers are not centres of control, but points of authority for
provenance" — that's the Xudanu hub model, published by someone
else. Their evaluation is prospective (experiment not yet run).

**Source:** Beaumont & Anderson (Seed paper).

**Action:** Complementary, not competing. Cite as siblings. Quote
the "points of authority" sentence when positioning the hub. Their
HT '24 paper + the HT '26 deployment validate the audience. Long-
term: Xudanu-class engines could serve as Seed's provenance layer.

---

## 5. THE H(G) FRAMEWORK INVITES VALIDATION WE ALONE CAN PROVIDE

**Learning:** Ten-dimensional hypertextuality profile. Their θ
(transclusion) coordinate has never been measured on a system that
realises it — every corpus they tested has θ near zero. Their open
Q4: "does H(G_AI) differ measurably from H(G_human)?" needs
authorship-labeled data that doesn't exist.

**Source:** Adamski et al. (H(G) paper), §5.4, open Q4.

**Action:** BUILT (hg-profile subcommand). First measurement:
ρrt=1.0, η=0.603, θ=0.041 on the combined corpus. Representative
corpora generator built for four-genre comparison. NEXT: fix the
custom label mapping (68 edges show as "custom" — they're seeded
demo links using non-standard type ids). Then compute H(G) per
corpus for the comparative table.

---

## 6. THE XANADU REREAD IS NOW ACADEMICALLY ESTABLISHED

**Learning:** "Xanadu is reread not as a failed project but as an
uncompromising attempt to make high-dimensional hypertextality an
explicit design goal." Multiple papers at HT '26 invoke Nelson
positively. Anderson's TfT paper shows current Tools-for-Thought
"rediscovered, unknowingly, ideas already known in the hypertext
community."

**Sources:** Adamski §5.3; Anderson §6.1; Bernstein throughout.

**Action:** The paper's introduction can cite these rather than
arguing the point ourselves. The renaissance framing is no longer
ours alone — it's the community's own conclusion. Quote Adamski
directly.

---

## 7. CONFERENCE PROCEEDINGS AS LIVING HYPERTEXT (SEED'S EXPERIMENT)

**Learning:** Seed was deployed AT HT '26 as the conference's
experimental medium — papers published from author nodes, the
conference site as aggregator, discussions anchored to fragments.
Three-phase experiment (before/during/after).

**Source:** Beaumont & Anderson §4.

**Action:** For HT '27: offer Xudanu as a complementary system —
Seed federates documents, Xudanu provides the engine + provenance.
A joint deployment (Seed's network + Xudanu's anchoring) would be
a landmark demo. Also: their honest limitation ("attendees
prioritise interpersonal exchange over proceedings engagement")
is our demo-design data — the practice-lead demo must not assume
engagement; it must earn it in minutes.

---

## 8. MILLENNIAL TFT BLINDNESS IS THE MARKET GAP

**Learning:** Current TfT apps (Obsidian, Roam, Logseq) show "no
evidence of knowledge of the rich past work in this area." The
un-inquisitiveness of tool makers about prior art is a documented,
systematic pattern. Rheingold: "a lot of this knowledge... has
really been mostly hidden from people who develop software."

**Source:** Anderson §6.0.3-6.0.4, §6.1.

**Action:** This is the user-facing story: Xudanu is what TfT tools
would be if they had known about 40 years of hypertext research.
The README/docs already imply this; make it explicit in the paper
and in the demo narrative. NOT a product claim — a lineage claim.

---

## 9. THE SOCIAL-MEDIA PROFILE IS THE INVERSE OF OURS

**Learning:** "H(social media) shows low reverse-traversability,
high centralisation, and low relation-type heterogeneity." The
pathologies (filter bubbles, disinformation) correlate
structurally with these parameters.

**Source:** Adamski §5.5.

**Action:** The contrast table for the paper — H(social media) vs
H(Xudanu) vs H(Xanadu-ideal) — is ready to write. Our profile
(ρrt=1.0, high η, high D) is the structural inverse of the
pathology profile. Frame: "the architecture that prevents filter
bubbles is the architecture Xanadu proposed."

---

## 10. NON-WESTERN TRADITIONS AS DESIGN SOURCES

**Learning:** Anderson's §5: Chinese biji (fragmentation-
comfortable), Japanese zuihitsu (meandering associative), Islamic
hashiya (marginal commentary) and isnad (chains of transmission)
— none used as design sources. "A field already blind to forty
years of hypertext research is doubly blind to traditions further
from home."

**Source:** Anderson §5, §8.

**Action:** Isnad (chains of transmission) maps directly to our
provenance chains — an historical validation. Biji maps to the
lattice's append-only structure (fragments without forced
synthesis). Not build items, but the paper's §8 (Discussion)
should acknowledge these traditions and note where the model
accidentally supports them. This is also the diversity point that
reviewers increasingly expect.

---

## PRIORITY ACTIONS (from all ten learnings)

| # | Action | Effort | Status |
|---|---|---|---|
| 1 | Fix custom label mapping in hg-profile (68 "custom" edges) | ~1h | TODO |
| 2 | Per-corpus H(G) profiles (four-genre table) | ~2h | Generator built; profiles pending fix |
| 3 | AI-disclosure report (FR-61 S3) — turns learning #2 into a visible artifact | ~1d | Spec'd in FR-61 |
| 4 | Quote-the-community passages for paper §1 (learnings #6, #8) | hours | In paper skeleton |
| 5 | H(G_AI) vs H(G_human) on AuthorType-labeled corpus (learning #5, Q4) | ~1d | AuthorType data exists |
