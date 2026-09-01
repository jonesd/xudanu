# FR-40: Green/Gold Link Constructs — multi-ended links, home documents, claim sets

Status: partially implemented (see Story status marks) · Drafted
2026-08-20 · Surveyed vs Gold source 2026-08-31
Builds on: FR-39 (link types as documents), FR-52 A-2 (Set/Path
SpanRef)
Heritage: Udanax Green FeBe manual, "Links and Link Types"; winfe
`links.cpp` (1993). Summary in `docs/gold-link-semantics.md`.

> **Green-compatibility note (2026-08-31):** observation of the
> running Green implementation (XCP-Green gateway work) shows heavy
> use of links with many ends. Two constructs from Green/Gold's
> ACTUAL end-set model are not yet expressed here and are added as
> Stories 6-7: an end-set may contain MULTIPLE spans (Gold
> `FeMultiRef`, nlinksx.hxx:295 vs `FeSingleRef` "a single
> attachment"), and an end-set may reference OTHER LINKS. Our
> Stories 1-5 model "any number of ends, each one span" — the
> shape matches, the per-end cardinality does not. The target is
> full Green link fidelity: 2-3 end-sets, each a set of
> attachments (spans, and links), so the gateway can translate
> Green links without loss.

## Why

Green's link model is more powerful than what Xudanu currently
exposes, in three specific ways. Our `HyperLink` core is already
shaped for it (`ends: HashMap<String, HyperRef>` — named, arbitrary
ends) but the wire protocol, the server ops, and the UI restrict
links to exactly two ends with a side-channel of type ids. This FR
removes those restrictions deliberately, story by story.

The heritage constructs and their payoff:

1. **Multi-ended links (end-sets).** Green links have any number of
   ends; a three-ended link IS a typed connection between three
   places (their original example: a quote link connecting the
   quotation, the source, AND the type-document). Today a Xudanu
   user expressing "A, B and C form a comparison" must make three
   two-ended links — losing the claim that they are ONE connection.

2. **The three-set / type end.** Green's third end-set is the type,
   deliberately an end of the link rather than a tag on it. With
   FR-39 (types as works), the natural completion: a link's type end
   points at its definition work, and a link can carry MULTIPLE type
   ends (a connection can be both Quotation and Comment).

3. **Home documents and home-sets.** A link lives in a document (its
   address there is its global id), independent of what it connects.
   Versioning/editing can place a link in multiple documents. Ours
   are server-global with no home; the home concept is what makes
   trails-as-documents and link portability clean (a link "belongs"
   to the essay that asserted it, travels with its versions).

## Current state (measured, not assumed; re-measured 2026-08-31)

- `HyperLink { ends: HashMap<String, HyperRef>, link_types: Vec<u64> }`
  — multi-ended shape EXISTS in the core model
- Wire ops: `link_create` (origin, destination, optional two refs);
  `link_add_end`/`link_remove_end` **implemented server-side with
  WAL replay (Story 1 backend DONE)**; LinkCreator has an
  "add another end" path
- Types: `link_types: Vec<u64>` already supports multiple types per
  link (`link_set_types` accepts a list) — underused
- **Story 3 DONE**: `home_document` in LinkState, accepted by
  link_create, home-filtered listing, ghost/archive respects homes
- **Story 4 DONE**: `link_query { from/to/type/home }` implemented
  with seeded-corpus test
- **Story 2 NOT DONE**: no derived type-end materialization found
- **Story 5 NOT DONE**: no comparison view for multi-ended links
- Each end is ONE `HyperRef` = one span — Green/Gold end-SETS
  (multi-span ends) not yet expressible (Story 6)
- Ends cannot reference links (Story 7)

## Stories

### Story 1 — Multi-ended links on the wire (server + frontend) — DONE (backend + LinkCreator path)
- `link_add_end`/`link_remove_end` brought into use: add a named end
  (existing HyperRef machinery) to any link you can edit
- `link_get`/list responses already serialize the ends map — verify
  and fix the payload shape if ends beyond Left/Right are dropped
- UI: Connections section renders multi-ended links as one item with
  N targets ("A ⇄ B ⇄ C — Comparison by you"), each target clickable
- LinkCreator gains a third step option: "add another end" (repeat
  target selection)
- Acceptance: create A–B link, add end C, all three works show the
  connection in Connections; deleting one end leaves a two-ended
  link, not a broken one

### Story 2 — Type ends unify with FR-39 definitions (server)
- When a link's types include a registered type with a definition
  work, the link GAINS a type end pointing at that work (derived,
  not stored twice — materialized on read like transclusion caches)
- Multiple types per link surfaced in the UI (the vector already
  supports it; LinkCreator currently forces one choice — allow
  toggling several; render stacked type chips)
- Acceptance: a link typed both Comment and Quotation renders both
  chips, filters under either, and its Connections entry links to
  both definition works

### Story 3 — Link home documents (server) — DONE
- `link_create` gains optional `home_document: Option<BeId>` —
  default remains server-global (back-compat), but a link MAY live
  in a work (the essay asserting it)
- Home-sets emerge via versioning for free: a trail materialization
  or derived work that includes the essay carries its links
- `work_ghost`/archive does NOT delete homed links (they belong to
  the document, not the library)
- Acceptance: a link created with home document H appears in H's
  Connections and disappears from the global list when H is archived
  (reversible); without home, behavior unchanged from today

### Story 4 — Link matching, the four-set query (server; from FR-39 S4, shared) — DONE
- `link_query { from_spec, to_spec, type_ids, home_spec }` over the
  ends map — Green's matching, our vocabulary. With multi-ended
  links the from/to distinction becomes "the end matching this spec"
  vs "another end matching that spec" (Green's own semantics)
- Acceptance: heritage queries ("everywhere A quotes B", "every
  Disagreement homed in H") correct on a seeded corpus

### Story 5 — Comparison view for multi-ended links (frontend) — NOT DONE
- Selecting a multi-ended link offers "Compare" — the three (N)
  ends side by side with shared/highlighted passages (the
  comparison machinery already exists for two works)
- The heritage payoff: Gold's transpointing windows, finally with a
  link construct that needs them
- Acceptance: a three-way comparison renders; shared content
  between any pair is highlighted

### Story 6 — Multi-span end-sets: an END is a SET of attachments

Gold's split: `FeSingleRef` ("a single attachment to some material",
nlinksx.hxx:414) vs `FeMultiRef` (nlinksx.hxx:295) — a link end
wrapping MULTIPLE attachments. Green's end-sets likewise contain a
set of v-spans, not one. Today every Xudanu end is one `HyperRef`
(one span in one work): "these three passages, taken together, are
one end of this disagreement" is not expressible — it degrades to
three links, losing the one-connection claim.

**Design:** the named end becomes a set of attachments —
`ends: HashMap<String, Vec<HyperRef>>`. `HyperRef` stays the
attachment unit (keeps cross-server refs, provenance chains, path
context — remote attachments keep working inside an end-set).
Existing single-span ends are singleton sets: migration is the
identity at rest, and `with_ends_mapped` generalizes to per-
attachment mapping so span migration covers EVERY attachment in
EVERY end. The wire gains `link_end_add_attachment`/
`link_end_remove_attachment` beside add/remove-end; `link_query`
specs match "any attachment of the end" (Green's own matching
semantics).

**Composition:** end-sets are the LINK-layer twin of FR-52 A-2's
`Set<SpanRef>` (content layer) — same construction, different
layer. A quotation end assembled from five pinned spans and a
Set element quoting five spans are deliberately the same shape.

**Risk:** medium — touches every ends consumer (backlinks, span
migration, markers, LinkState WAL). Armor: backlink equivalence
(any-attachment vs today's per-end), migration-moves-every-
attachment property tests, gateway round-trip: a Green link with
multi-span end-sets imports/exports without loss.

### Story 7 — Links-to-links: end-sets may reference LINKS

Green end-sets may contain link IDs as well as spans — commenting
on a CONNECTION itself is native practice. Ours cannot express it:
`HyperRef` targets content spans; links are not addressable as
endpoints. FR-39 made link TYPES works and Story 3 gave links
homes; this completes the pattern — a `HyperRef` variant
(targeting a link id, optionally its home document for context)
makes reentrant links expressible without making links works.

**Sequencing note:** after Story 6 (attachment sets) this is small
— one more attachment kind. Cycle discipline: a link may not
(transitively) end at itself; enforced at create/add time.

**Risk:** low-medium — additive attachment kind; consumers that
assume span-attachments (markers, comparison) degrade gracefully
to "link attachment shown as chip".

## Appendix A: application-use archaeology (2026-08-31)

Full treatment in `docs/gold-link-model.md` (source archaeology:
the model from nlinksx, the shipped UX from winfe, descriptors,
transpointing). Summary here for story context.

Read from the shipped Gold winfe sources (winfe/links.cpp,
xstuff.hxx, 1993) and the backend link implementation
(src/server/nlinksx.cxx) — how multi-ended links were ACTUALLY
used and intended, beyond the FeBe manual semantics.

### The Gold link data model, precise (nlinksx.cxx:102-245)

- A link is an EDITION whose domain holds a reserved
  `Link:LinkTypes` key (holding a FeSet — the type SET, endorsed
  by the author) plus ANY NUMBER of other named keys, each holding
  a FeHyperRef. Ends are named sub-editions; naming an end
  "Link:LinkTypes" raises MustUseDifferentLinkEndKey.
- The canonical constructor builds `Link:LinkTypes` +
  `Link:LeftEnd` + `Link:RightEnd` — our `HyperLink::make`
  mirrors this exactly (including our LINK_TYPES_KEY guard).
- `FeMultiRef::check` (nlinksx.cxx:464): a HyperRef carrying a
  `MultiRef:Refs` sub-edition in **IDSpace** — an identity-keyed,
  unordered SET — whose members must each be a FeHyperRef.
  Two consequences: (a) end-sets are true sets (order-free),
  matching our order-insensitive Set<SpanRef> fingerprint
  decision in FR-52 A-2 — convergent design, recorded; (b)
  members are refs, and FeMultiRef IS a FeHyperRef — **end-sets
  can nest** (a multi-ref of multi-refs).
- Links-to-links needs NO special mechanism in Gold: every link is
  a work (`XuWork::make(link->edition())` — winfe links.cpp:300),
  and a FeSingleRef's workContext can point at any work, including
  a LINK work. The uniform everything-is-a-work model gives
  reentrant links for free. **Design consequence for us:** Story
  7's special variant is the compensating mechanism because our
  links aren't works; the Gold-faithful alternative is links-as-
  works (which Story 3 homes + FR-39 types-as-works already
  approach). Decision stays with the variant (smaller blast
  radius), revisit if links ever become works.

### How the shipped application used the model (winfe links.cpp)

1. **The descriptor end** — `FE_MYLINKDESCKEY
   "FELink:Descriptor"` (links.cpp:26): every link carries an
   application-defined named END whose excerpt is the human-
   readable description ("< New Link >" default, then the first
   characters of the other end's text, then the descriptor if
   present). Multi-endedness was used for APPLICATION METADATA,
   not just content connections. This needs NO model change for
   us — `link_add_end` already carries it; it needs LinkCreator
   support (a "describe this link" field that creates the end).
2. **this/other presentation** — the link list showed every link
   two-ended-at-a-time, relative to the current work:
   `atRight(link, work)` → thisEnd/otherEnd
   (links.cpp:86-91). The n-ended model lived in the DATA layer;
   the UX simplified to two ends at a time. Lesson for our
   Connections panel: render any link as "this end ⇄ other ends
   (N)" from the viewing work's perspective — n-endedness without
   n-ended visual complexity.
3. **attachLink — commentary by fresh document** (links.cpp:305):
   one end = the target passage; other end = a BRAND-NEW document
   ("New Attachment", titled, public). The shipped annotation
   pattern: comment BY linking to a new doc, not by inline
   markup. This is the natural first application of links-to-
   links in Xudanu: "comment on this connection" creates a link
   whose end is the link (via Story 7) plus a fresh note work.
4. **Live link lists via transcluders** — the list window is
   `domain->rangeTranscluders(NULL, linkTypeFilter)` +
   FillRangeDetectors (links.cpp:151-155): links discovered by
   region query with type filter, updated reactively. Ours lists
   per-work; the region/filtered query is FR-39 S4's link_query.
5. **Creation UI never finished** — `endLink`'s TODO "this should
   pop up the link creation dialog" (links.cpp:299). Warning
   taken: link creation is where link UIs die; keep the
   two-ended fast path sacred and make every additional end a
   deliberate extra step (our LinkCreator wizard shape is right).

### Green-specific notes

Green's FeBe model (per the manual, documented in
docs/gold-link-semantics.md §1): from-set / to-set / three-set
(the type, "deliberately misnamed"), each end-SET containing
v-spans AND link ids; predefined types jump, quote, footnote,
marginal note. The running Green instance observed 2026-08
(heavy many-ended use) is consistent: Green's end-set matching
queries are n-ended by construction. **Open:** inspect the Green
instance's client scripts / scenario corpus for concrete
application patterns when the tree is located — recorded as a
follow-up, not blocking Stories 6-7 whose shapes match the
manual's model.

## Appendix B: UX review for Stories 6-7 (2026-08-31)

Principles drawn from the archaeology above, applied to our UI:

1. **Two-ended-at-a-time views over n-ended data** (the winfe
   lesson). Every link rendering is FROM a work: "this end ⇄
   others". Multi-span ends render as one CLUSTERED marker per
   end (link-markers.ts already clusters by lane/density) — a
   five-span end is five underlines sharing one badge/label, not
   five links. Hover on any member span highlights the whole end.
2. **Creation: gather, then commit.** The two-ended wizard stays
   the default. "Add another end" repeats target selection
   (exists). For multi-SPAN ends, a gather mode: select passage →
   "add to this end" → repeat → "complete end". The end-set
   materializes only on commit; cancel is free. Never require
   multi-span to make a simple link.
3. **Links-to-links: comment chips, not recursion.** A link with
   link-attachments renders a badge ("3 connections") on its
   marker and its Connections row; clicking opens the comparison
   or the attached link's own row. Visual depth capped at one
   level — no infinite nesting UI; the DATA allows nesting, the
   UI flattens (Gold's own UI did exactly this).
4. **The descriptor end ships with Story 6.** Once ends are
   sets, add "describe this link" in LinkCreator → named end
   holding a fresh note work (winfe's pattern, FR-37 derived
   works make the note portable). This gives every link a
   human-readable label cheaply — the winfe list window's core
   feature.
5. **Comparison (Story 5) is the payoff view** — transpointing
   windows for n ends. Sequence AFTER Story 6 lands: compare
   needs multi-span ends to have anything to show for gathered
   quotations.
6. **Destructive edges.** Removing an end from a 3-ended link
   leaves a 2-ended link (already Story 1 acceptance); removing
   a SPAN from a multi-span end with 1 span left removes the end
   (an end cannot be empty — Gold's check requires every
   non-type key to hold a ref; an empty end-set is not a link
   end). Deleting a link deletes its descriptor end's note work
   ONLY if the work is otherwise unreferenced (reachability,
   consistent with archive-first GC stance).

### Appendix B.1: rendering identity — what a colour means (2026-08-31)

Today's marker lanes are GEOMETRIC, not semantic:
`assignLinkLanes` (link-markers.ts) partitions by span collision —
a marker's lane exists so overlapping underlines stack legibly,
NOT because it carries meaning. Consequence: no user can learn
"what a colour means" because it is not stable across documents,
viewports, or even edits. Rendering identity for multi-span ends
separates the two jobs:

- **Lane = geometry** (unchanged): where underlines stack.
- **Colour = identity** (new rule): colour is assigned per LINK
  (or per end-set, if the two ends must be distinguishable in
  context), stable within a document view for the session.
  Members of one end share the colour PLUS a shared glyph/shape
  on their badges — redundant encoding, colourblind-safe.

Explaining the colour — three layers, because hover alone is not
discovery (nobody hovers everything):

1. **Hover tooltip** (the explanation): type icon + name, the
   link's descriptor (B.4 — this is what descriptors are FOR),
   "passage 1 of 3 in this end", author, jump controls. Hover on
   any member highlights all members of the end.
2. **Click = the live legend** (the discovery path): clicking any
   member span scrolls Connections to that link's row and
   highlights it. The panel is the legend — persistent, queryable,
   already-shipped UI — instead of a static key nobody reads.
3. **Density pill expansion**: where members cluster, the pill
   lists member passages with jump targets.

### Appendix B.2: members too far apart for one screen (2026-08-31)

The end is ONE object; the screen is not its boundary. Five
mechanisms, in increasing commitment — all driven from LINK DATA,
never from rendered marker DOM (the virtualized editor only
materializes visible ranges; DOM-driven gutters/minimaps would lie
about off-screen members):

1. **Jump cycling** — the marker badge click cycles members
   ("2 of 5"); ⌘→ next member within an end. The winfe answer:
   follow-navigation (`show`/`follow`), not same-screen display.
2. **Gutter badge per end** — the margin bar (lane offsets
   already exist) carries a persistent chip at every member
   location: "end · 1/5 here". Visible wherever ANY member is
   on screen.
3. **Minimap / DocumentMap dots** at member locations — the
   overview IS the answer for far-apart spans.
4. **Split view (Story 5 comparison)** — "show side by side"
   opens members in panes. This is transpointing's reason to
   exist: seeing far-apart connected content together.
5. **Bottom-bar strip** (RelatedFooter pattern): "This end:
   3 passages" with click-to-jump — works when nothing else is
   visible; the cheapest always-available surface.

## Non-goals

- Executable type-behaviors (Green's presentation programs) —
  FR-39's non-goal stands
- Restructuring the two-ended fast path — `link_create` stays
  ergonomic; multi-ended is additive
- Rewriting existing links — all shipped links remain valid
  two-ended links forever

## Heritage appendix

Green's operational rules we are adopting verbatim where possible:
- ends attach to CONTENTS (span-anchored) — already our behavior
- edits split end-sets to original characters — already our behavior
  (span splitting, verified against their text)
- the backend performs edits — already our architecture
- link matching never scans linearly in Green (enfiladic); ours
  scans until measured pain — recorded honestly
