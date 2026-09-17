# Design principles — the durable conclusions

Written 2026-09-12 after the first-user walkthrough session. These
principles were *re-derived* that night, half of them already latent
in earlier work (the compare view realized juxtaposition a month
before it was articulated). They are the tests new UI proposals must
pass.

## 1. The document is the stage

Users spend their time in text. Every panel, rail, badge, or marker
that makes the connective model visible competes with the document
for attention. Test for any new UI element: *does the document get
calmer or noisier?*

## 2. Juxtapose, don't navigate

Nelson's transpointing answer: connections are shown as geometry
between documents, not chrome around them. Clicking a link should
not abandon your place — the far passage opens *beside*, highlighted
with the connection line joining the two. (Compare view has the
machinery; making "open beside" the default gesture of following a
link is the completion.)

## 3. Panels are for maps, not meaning

The Connections panel, docuverse graph, trails — they're overviews,
surveys, administration. The *experience* of a connection belongs in
the document(s) themselves (markers, hover, juxtaposition).

## 4. Help lives in the doing context

Course teaches in course context; help must appear at the moment of
confusion — wizard coaching, empty-state pointers, contextual docs
links. Never require the user to leave their task to learn their
task.

## 5. Intent-first, machinery-second

Users arrive wanting to *do* something (react, cite, compare), not
to configure machinery (type + ends + gathering). Ask the intent,
pre-configure the structure. (FR-66's core.)

## 6. Complexity is unlocked by doing, not by reading

Progressive disclosure gated on demonstrated use: multi-ended and
gathered ends appear after simpler links succeed. The competence
ladder (FR-66) applies to every advanced feature, not just links.

## 7. One layout, converged

Two full layouts (classic/studio) are two unreconciled answers to
principle 1. Converge on one document-centered layout; panels on
demand. The reader/author calm toggle is the one axis worth keeping
because it is the user's own moment-to-moment choice.

## 8. Ambiguity in the UI is a bug even when the system is correct

Silent no-ops, layout changes without explanation, two CTAs
competing for one job — the system behaving correctly while the user
cannot tell why something happened is a defect (tonight: New
Document no-op, layout FAB, dual demo buttons).

## 9. The same content at every step

Walking a chain — inline quote, hover, origin panel, provenance
hops — every surface must show the same passage. Consistency across
steps is how the system earns trust; a surface that denies what
another just showed (a bare "span could not be located" after the
reader SAW the quote) breaks the reader's faith in all of them.
When drift makes exact display impossible, show what was quoted as
it stood, marked as such — never a bare not-found. (Found in the
wild 2026-09-16: stale workshop transclusion, OriginPanel.)

---

History note: principles 2-3 trace to the compare/beams work
(transpointing windows); 1 and 4-8 crystallized in the 2026-09-12
walkthrough; 9 in the 2026-09-16 rendering session. See FR-65,
FR-66 for the onboarding applications.
