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
