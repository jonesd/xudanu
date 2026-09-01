# Gold & Green Link Semantics — Heritage Notes and Xudanu Alignment

Status: reference · Date: 2026-08-20
Deeper source treatment of the model, the shipped UX, descriptors,
and transpointing: see `docs/gold-link-model.md` (2026-08-31,
source archaeology from nlinksx + winfe).

Sources studied:
- Udanax Green FeBe manual, "Links and Link Types" chapter (via the
  open-sourced 1999 materials)
- John Dougan, *LinkTypes*, 20 Jan 2007, from the
  [dotmpe/udanax-mpe](https://github.com/dotmpe/udanax-mpe) fork
  lineage of the Udanax code and archaeology pages
  (`var/htdocs/Xanadu-archaeology/articles/text/LinkTypes`) —
  credited wherever its proposals are referenced
- winfe (Gold Windows front-end) `links.cpp`, April 1993 — local tree
  at `original-code/xanadugold/winfe/links.cpp.gz`

---

## 1. What Green specified (and how we compare)

### Three end-sets per link

Green links carry from-set, to-set, and **three-set** — the third
being the type, "deliberately misnamed to escape the assumption that
a type is just a symbol." Types were planned to become *documents*
holding conventions, or even presentation programs.

**Xudanu:** five hardcoded types + Web Link; `register_link_type`
exists as a bare name map. The document-typed future is FR-39.

### Links attach to contents, not positions

"Links stay attached to the same contents, independent of their
location... The end-set of the link effectively splits to only
include the original characters" when text is inserted inside a
linked span.

**Xudanu:** implemented independently and identically in spirit —
span migration on `revise_work`; the H1-incident fix (span splitting:
fragments keep the original characters, inserted text gets the
editor's attribution) reproduces Green's specified split semantics.

### The backend performs the edits

"Consistent interaction between links and editing operations requires
that the backend perform the editing operations. Frontends might be
unaware of all links attached to a particular span."

**Xudanu:** span migration and provenance handling live server-side
in `revise_work`, exactly for this reason.

### Home documents and home-sets

A link lives in a home document (its address there is its global
id); versioning can cause it to exist in multiple documents (the
home-set). The home is independent of the end-sets — a link in one
document can connect two other documents' contents.

**Xudanu:** links are server-global with origin/destination work refs;
the home-set concept anticipates our derived-works/trails
materialization problem (links appearing in trail snapshots).

### Link matching — the four-set query

One operation takes from/to/three/home spec-sets and returns matching
links, executed on the enfilade structures ("does NOT search through
all the links"). The canonical example: everywhere author A quotes
anyone; restrict the to-set and it's everywhere A quotes B.

**Xudanu:** we have `work_backlinks`, `find_transcluders`,
`content_match` — but no unified query op, and ours are linear scans.

---

## 2. Type vocabulary across the lineage

| Source | Types |
|---|---|
| **Green predefined** (tumbler ids) | jump, quote, footnote, marginal note |
| **LM 93.1** pp. 4/52–4/55 | Title, Author, Doc-Supercedes, Correction, Comment, Counterpart, Translation, Heading, Paragraph, Quote-Link, Footnote, Layout, Vanilla Jump, Modal Jump, Expansion, Citation, Alt-Version, Comment-Doc, Certification, Mail |
| **Dougan 2007** (proposed, credit dotmpe/udanax-mpe) | + the LM set, and a wiki-level formatting set: Italics, Boldface, Underline, Text-Size, Paragraph, Heading |
| **Xudanu shipped** | Comment, Reference, Disagreement, Quotation, See Also, Web Link |

Notes:
- **Disagreement** does not appear in the historical lists we have.
  It is consistent with Nelson's two-way-critical-connection
  principle, but we document it as a Xudanu addition, not inherited
  vocabulary.
- Green used links for *all formatting* (no inline markup). Xudanu
  uses annotation kinds (bold/heading/…) — same idea, different
  mechanism; recorded as a deliberate fork, per Dougan's own note
  that formatting-link assignment "was never formally done except in
  the most superficial way."
- Dougan's "Certification" anticipates our Ed25519 provenance
  verification; his "Doc-Supercedes / Alt-Version" anticipates our
  versioning — both cases where Xudanu has already shipped the
  capability by other means.

---

## 3. Metalinks: bibliographic claims as links

LM 93.1's Title and Author are *metalinks* — metadata expressed as
typed links rather than record fields. This is more Xanadu-pure than
our owner/title fields, and it buys something fields cannot:

- **Contested claims**: competing titles or disputed authorship
  become multiple signed claims (who asserted, when), not a silent
  overwrite
- **Cross-server claims**: Doc-Supercedes between documents on
  different servers is inherently a link
- **Live queries**: "every work anyone attributes to author X" is a
  link-matching query; author pages become live bibliographies

**Xudanu position:** span-level Ed25519 provenance already covers
attribution-of-text more strongly than an Author metalink. Metalinks
are the complementary *bibliographic claim* layer: fields remain as
materialized cache of the preferred claim; links carry the claims.
Not all metadata wants this (mime types, timestamps gain nothing).

→ Folded into FR-39 as Story 6.

---

## 4. FR candidates arising

1. **FR-39 Link Types as Documents** (drafted,
   `FR-39-link-types-as-documents.md`): definitions as works, UI
   conventions from definitions, per-type styling as validated data,
   Green's four-set matching query, federation of definitions — and
   Story 6: **metalinks for bibliographic claims** (register Title /
   Author / Doc-Supercedes types; metalinks augment fields; render
   multiplicity where it exists; fields become cached preferences).
2. **Link matching query** (FR-39 Story 4): unified four-set search
   over `work_to_links`; enfiladic indexing deferred until measured.

---

## 5. Front-end archaeology note

Gold's winfe `links.cpp` (1993) shows the shipped UI: links rendered
as a **list window with text descriptors** — "< New Link >" replaced
by the first characters of the far end's text, plus an optional
description end (`FE_MYLINKDESCKEY`). No colored in-text underlines
survive in the sources we have. Xudanu's in-text typed underlines
are an original rendering in the spirit of the type system, not a
reproduction.

---

## 6. Primary-source lineage (added 2026-08-23)

The complete documented chain for Xudanu's link model, root to
present:

1. **1984 — Xanadu System Proposal** (Chip Morningstar, Xanadu
   Operating Company; 2019 edition revised by Alberto González
   Palomo, CC BY-SA 4.0):
   sentido-labs.com/en/library/201904240732/Xanadu%20Hypertext%20Documents.html
   The design of the original C backend under Unix: enfilade theory
   (crums, wids, disps; retrieve/rearrange/append; cut and
   three/four-cut algorithms), the granfilade/poomfilade/spanfilade
   triad, tumblers and humbers, orgls/berts/virtual copies,
   historical trace, and the "Future Directions" (§8) that became
   the roadmap everything after it executed. Phoebe — "fe-be",
   frontend-backend — is named here (§8f). This is the design
   rationale for the code in `original-code/xanadugold/` and the
   common ancestor of both the Green and Gold variants.

2. **1988 — Udanax Green FeBe Protocol**: udanax.xanadu.com/green/febe/
   The realization of §8f: the wire protocol for the simplified
   Green variant — three-set links ("deliberately misnamed"),
   backend-performs-edits, end-sets splitting to original
   characters. The manual cited throughout §1 of this document.

3. **1999 — open-source release** (X11 license): both variants,
   including the Gold winfe (1993) examined in §5 above.

4. **2026 — Xudanu**: FR-39/FR-40 implement the Green link model
   (multi-ended links, type endsets, home documents, four-set
   matching); `FR-40-conformance-matrix.md` tracks the claim-by-
   claim alignment; the proposal's §8i (GC archive-first) and §8h
   (superedit historical trace) are adopted as issues #142 and
   candidates respectively.

Heritage items from the 1984 proposal now tracked in Xudanu:

- **§8i GC** → issue #142 (archive-first, full-reachability audit)
- **§8h historical trace** — slow variant ships (revision history +
  WAL replay); fast variant (superedit aggregation, "an enfilade
  constructed from enfilades") is an FR-34 candidate
- **§8l3b1 time as a retrieval dimension** — FR candidate
- **§8l4/8l6 semi- vs fully-distributed** — FR-3 cluster is
  squarely "semi-distributed"; the fully-distributed analysis
  (locate non-local data, track who knows about local changes)
  describes our cross-server receipts and tumblers problem exactly;
  the Web of Indra analogy is the one-line description of the
  federated docuverse
- **Phoebe → FeBe → our WS ops**: the protocol-naming lineage;
  FR-40's new ops continue the same evolution

Quotation note: the 2019 edition is CC BY-SA 4.0 — quoting with
attribution is clean; the original 1984 text is MIT per the
editor's lifting of the "dire curse."
