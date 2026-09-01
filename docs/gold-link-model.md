# The Gold Link Model — Source Archaeology and Application Design

Status: reference · Date: 2026-08-31
Companion to: `docs/gold-link-semantics.md` (spec-level heritage and
Xudanu alignment), `docs/dev/FR-40-green-link-constructs.md`
(implementation stories). This document is the deeper treatment:
the data model read from the Gold sources themselves, the shipped
application UX (winfe, 1993), descriptors, and the
transpointing/comparison story.

Sources examined:
- `src/server/nlinksx.hxx` / `nlinksx.cxx` — FeHyperLink,
  FeHyperRef, FeSingleRef, FeMultiRef, FePath (the complete link
  wrapper system)
- `winfe/links.cpp` (April 1993) — the shipped Windows frontend's
  link manager: list window, creation flows, descriptor ends
- `winfe/xstuff.hxx` — FEStuff helpers (linkKey, atRight, endAt)
- Udanax Green FeBe manual, "Links and Link Types" (via
  `gold-link-semantics.md` §1)
- Literary Machines 93.1 pp. 4/52–4/55 (type vocabulary)

---

## 1. The data model (nlinksx.cxx, precise)

### A link is an edition

`FeHyperLink::check` (nlinksx.cxx:102) defines the shape:

```
link-edition = {
    "Link:LinkTypes" : FeSet          // REQUIRED, the type set
    <any other name>  : FeHyperRef    // the ends — any number
    ...
}
```

- The type set is endorsed by the creating author at construction
  (`FeServer::endorsementRegion(CurrentAuthor...)`, nlinksx.cxx:145)
  — types are CLAIMS with authors, not tags.
- Naming an end `Link:LinkTypes` raises `MustUseDifferentLinkEndKey`
  (nlinksx.cxx:213) — the type slot is reserved.
- The canonical constructor (nlinksx.cxx:193) builds exactly
  `Link:LinkTypes` + `Link:LeftEnd` + `Link:RightEnd`. Xudanu's
  `HyperLink::make(types, left, right)` mirrors this, including the
  reserved-key guard (`LINK_TYPES_KEY`).

Because a link is an edition, it is also a WORK — winfe wraps it
so (`XuWork::make(makeLink(...)->edition())`, links.cpp:300) and
sets its read club public. Everything-is-a-work is load-bearing:

- **Links-to-links needs no special mechanism.** A `FeSingleRef`'s
  `workContext` may point at any work — including a link work.
- Links have homes (the link work itself), versions, and clubs.

### The reference hierarchy (nlinksx.hxx)

`FeHyperRef` — the base — carries three contexts:

| Field | Gold's contract (source comments) | Xudanu mirror |
|---|---|---|
| `workContext` | "The Work whose state this is attached to" | `work_context: Option<u64>` |
| `originalContext` | "A Work **frozen** on the contents of the Work at the time the [ref was made]" — must be a frozen Work | revision pinning (VirtualSpec), CrossServerRef frozen source |
| `pathContext` | "The path of labels down from the top-level Edition" — FePath, "a sequence of Labels, used for context information in a LinkEnd" | `path_context: Option<Path>` |

`FeSingleRef` — "Represents a single attachment to some material
in the context of a Work, and maybe a Path beneath it"
(nlinksx.hxx:414). `make(material OR NULL, workContext,
originalContext, pathContext)` — at least one non-NULL.

`FeMultiRef` — a HyperRef carrying a `MultiRef:Refs` sub-edition
whose coordinate space is **IDSpace** (`check` requires
`isKindOf(cat_IDSpace)`, nlinksx.cxx:479). Two consequences:

1. **An end-set is a true set** — identity-keyed, unordered.
   (Xudanu's FR-52 A-2 Set fingerprint is order-insensitive for
   the same reason; convergent design, recorded.)
2. **Members must be FeHyperRefs — and FeMultiRef IS one**, so
   end-sets can NEST: a multi-ref of multi-refs. Multi-endedness
   recurses.

### What Green specified vs what Gold shipped

Green (FeBe manual): from-set / to-set / **three-set** — the
third is the type, "deliberately misnamed to escape the assumption
that a type is just a symbol"; types were planned to become
documents holding conventions, or presentation programs. End-sets
contain v-spans (versioned spans) AND link ids.

Gold (the code above): the generalized form — any number of named
ends, each optionally a whole SET of references, plus a type SET
endorsed by the author. Green's three-set link is the Gold model
with three named ends. Xudanu's FR-40 implements the Gold shape
and can express the Green three-set as a special case — which is
exactly what the XCP-Green gateway needs for loss-free
translation.

---

## 2. The range of links (type vocabulary)

| Source | Types |
|---|---|
| **Green predefined** (tumbler ids) | jump, quote, footnote, marginal note |
| **LM 93.1** pp. 4/52–4/55 | Title, Author, Doc-Supercedes, Correction, Comment, Counterpart, Translation, Heading, Paragraph, Quote-Link, Footnote, Layout, Vanilla Jump, Modal Jump, Expansion, Citation, Alt-Version, Comment-Doc, Certification, Mail |
| **Dougan 2007** (proposed) | + the LM set and a formatting set: Italics, Boldface, Underline, Text-Size |
| **Gold winfe shipped** | one relationship type at creation (`relationshipLinkTypeID()`, links.cpp:302) |
| **Xudanu shipped** | Comment, Reference, Disagreement, Quotation, See Also, Web Link + FR-39 registered types as works |

Reading of the range, by ROLE rather than name:

1. **Jumping** — Vanilla/Modal Jump, Citation, See Also: the
   reader-action pair. Green's `jump` was the primitive.
2. **Quoting** — Quote-Link, Footnote, Quotation, Transclusion:
   content carried alongside its source.
3. **Contesting** — Correction, Counterpart, Doc-Supercedes,
   Disagreement (Xudanu's addition, consistent with Nelson's
   two-way-critical-connection principle but ours to own).
4. **Structuring** — Heading, Paragraph, Layout, the formatting
   set: Green used links for ALL formatting (no inline markup).
   Xudanu deliberately forks here (annotation kinds); Dougan
   himself notes formatting-link assignment "was never formally
   done except in the most superficial way."
5. **Claiming (metalinks)** — Title, Author, Certification,
   Comment-Doc: metadata AS links — contested claims, cross-server
   by nature, live bibliographies (folded into FR-39 Story 6).
6. **Corresponding** — Translation, Alt-Version: equivalence
   claims between documents.

The winfe shipped UI used ONE type (relationship) — the model's
range was always far ahead of the shipped UX. The lesson is not
"Gold users had 20 types"; it is "the model carries the range,
the application surfaces what it needs."

---

## 3. The shipped UX (winfe links.cpp, 1993)

### The link list window

Links rendered as a **list window with text descriptors**
(links.cpp:1, "The manager for a list of links and its trail"):

- Default descriptor: `"< New Link >"`.
- Fallback: the first few characters at the link's OTHER end —
  fetched live (`getText` over the other end's edition,
  links.cpp:73).
- Override: the **descriptor end** (below).
- Double-click behavior split: `show()` selects THIS end in
  context; `follow()` jumps to the OTHER end (`FESheet::showRef`,
  links.cpp:186). Two-ended-at-a-time.

No colored in-text underlines survive in the Gold-era sources —
Xudanu's typed underlines are an original rendering in the spirit
of the type system.

### Descriptors: the application's own ends

`FE_MYLINKDESCKEY = "FELink:Descriptor"` (links.cpp:26): the
frontend stores each link's human-readable description as a NAMED
END of the link itself — an edition whose excerpt reads as text
(links.cpp:77). Resolution order: descriptor end if present, else
other-end excerpt, else the default.

This is multi-endedness used for APPLICATION METADATA, and it
needs no model extension in Xudanu — `link_add_end` already
carries a named end; the missing piece is LinkCreator's
"describe this link" field plus list rendering. FR-40 Appendix B
ships it with Story 6.

### attachLink: commentary by fresh document

The second creation flow (links.cpp:305) does not link two
existing passages. It creates a link whose other end is a
BRAND-NEW work — "This is a new attachment.", titled "New
Attachment", public — made on the spot. The shipped annotation
pattern: comment BY linking to a fresh document, not by inline
markup. This is the natural first application of links-to-links
in Xudanu: "comment on this connection" = a link ending at the
link, plus a fresh note work.

### Live lists: links as region queries

The list window is not a stored collection — it is
`domain->rangeTranscluders(NULL, linkTypeFilter)` +
`FillRangeDetector`s (links.cpp:151-155): the links CONNECTED TO
THIS REGION, discovered enfiladically, updated reactively as
content changes. Ours lists per-work (work_to_links); FR-39 S4's
`link_query` is the same concept; enfiladic indexing deferred
until measured pain (recorded honestly).

### The warning: creation UI is where link UIs die

`endLink`'s TODO: "this should pop up the link creation dialog"
(links.cpp:299) — Gold's creation dialog never shipped. Xudanu's
rule (FR-40 Appendix B): the two-ended fast path stays sacred;
every additional end or span is a deliberate extra step.

---

## 4. Transpointing and comparison

**Transpointing windows** are Nelson's concept (Literary
Machines): side-by-side windows showing connected passages with
their shared content visibly aligned — seeing the SAME text in
multiple contexts at once, the visual form of "no duplication."
Honest archaeology: **no transpointing UI survives in the Gold
sources** — winfe's shipped surface is the list window plus
follow-jumps, strictly two-ended-at-a-time. The concept predates
and outlives the implementation.

Gold's model, however, is built FOR it:

- end-sets make "the same passage in N contexts" one queryable
  object (the comparison has a subject);
- `originalContext` freezing gives stable text to align against;
- the multi-ref's IDSpace set means alignment is by identity, not
  position.

FR-40 Story 5 is Xudanu's transpointing: an N-ended comparison
view with shared passages highlighted pairwise, using the
comparison machinery that already exists for two works. Its
sequence is deliberate — AFTER Story 6 (multi-span ends), because
gathered end-sets are what give comparison something to show:
five quotations assembled as one end, compared against the source
passages, shared content highlighted. The deep version (live
scroll-aligned windows with synchronized highlights) remains
Nelson's open invitation; the comparison view is the honest first
step.

---

## 5. Xudanu alignment summary

| Gold model element | Xudanu state | Where |
|---|---|---|
| Link = edition + type set + named ends | `HyperLink { ends, link_types }` — shape matches | links.rs |
| Canonical LeftEnd/RightEnd constructor | `HyperLink::make` | links.rs |
| Reserved type key | `LINK_TYPES_KEY` guard | links.rs |
| N named ends on the wire | DONE (link_add_end/remove_end + WAL) | FR-40 S1 |
| Type set endorsed by author | types as works (stronger: signed definitions) | FR-39 |
| End as SET of refs (FeMultiRef) | NOT YET — Story 6 (`Vec<HyperRef>` ends) | FR-40 S6 |
| Nesting end-sets | folds out of Story 6's Vec (design allows) | FR-40 S6 |
| Links-to-links (ref → link work) | NOT YET — Story 7 variant | FR-40 S7 |
| originalContext frozen work | revision pinning + CrossServerRef | range_element.rs, links.rs |
| pathContext (label path) | `path_context: Option<Path>` | links.rs |
| Home documents | DONE | FR-40 S3 |
| Four-set matching query | DONE (linear; enfiladic deferred) | FR-40 S4 |
| Descriptor end | NOT YET — LinkCreator field | FR-40 App. B |
| attachLink commentary pattern | NOT YET — needs S7 | FR-40 App. B |
| Transpointing/comparison | NOT YET — Story 5, after S6 | FR-40 S5 |
| Region-discovered link lists | partial (per-work lists; link_query exists) | FR-39 S4 |

The model is one story away at each layer: the wire (S6), the
reentrancy (S7), the view (S5), the label (descriptor). The Gold
sources agree with the FR-40 sequencing — and add one warning it
already heeds: keep simple links simple.
