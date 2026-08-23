# FR-39: Link Types as Documents — completing the Green/Gold link model

Status: draft · Date: 2026-08-20
Heritage: Udanax Green FeBe manual ("the three-set is deliberately
misnamed to escape the assumption that a type is just a symbol");
Dougan 2007 LinkTypes proposal ("types should be documents that store
the conventions for the given type"). We implement their stated plan.

## Why

Today's five types (Comment, Reference, Disagreement, Quotation, See
Also) + Web Link are hardcoded vocabulary: ids 1-6 with fixed colors
and dash styles in the frontend. `register_link_type` exists but is a
bare id→name map any authenticated user can overwrite, nothing is
persisted/verified, and no community can grow its own vocabulary —
Translation, Citation, Certification, Alt-Version all exist in the
heritage literature and none can be expressed.

Green's answer (and Dougan's): a link type is not a symbol. It is a
**document** — carrying a human definition, presentation
conventions, and eventually behavioral hints. Type ids become stable
references to definition works, and the system gets an extensible,
interoperable vocabulary for free.

## Stories

### Story 1 — Typed-link definitions become works (server)
- `register_link_type` gains a `definition_work: Option<BeId>` and
  stores (type_id, name, definition_work) in a dedicated map
  replacing the name-only map; persisted via manifest + WAL
- Creating a type registers the definition work's id as the type id
  (the work IS the type — Green's "type as document" literally)
- The five built-ins get seeded definition works on first boot of a
  fresh data dir (Comment, Reference, Disagreement, Quotation, See
  Also — each a short frozen work defining the convention, with
  heritage notes: Green's quote/footnote/jump tumblers, LM 93.1
  names, Dougan's list)
- `link_type_list` returns definition work ids; old callers ignore them
- Acceptance: restart persists custom types; `link_type_list` shows
  definitions; built-in rendering unchanged (backward compat)

### Story 2 — Type-convention content renders in the UI (frontend)
- LinkCreator's type picker shows the definition work's title + first
  line of its body as the type's description (fetch via definition id)
- Tooltip/help text for each type in the picker comes from the
  definition work instead of hardcoded strings
- Filter chips and legend labels in Connections use the registered
  names throughout (already partially true)
- Acceptance: registering a new type with a definition work makes it
  usable end-to-end: create, list, filter, tooltip

### Story 3 — Per-type styling as data (frontend + definition schema)
- Definition works may carry a `link-style` annotation (JSON: color,
  dash pattern, underline offset) on their body
- The editor's `LINK_TYPE_STYLES` falls back to the annotation when
  present, so a community's new types render distinctly without code
- Constraint: styles are validated (hex color, dash array) — a
  definition work cannot inject arbitrary values
- Acceptance: a "Certification" type registered with a gold solid
  style renders gold solid everywhere after reload

### Story 4 — Link matching query (server; Green's four-set search)
- New op `link_query { from_spec, to_spec, type_ids, home_spec }`
  where specs are (work_ids | author_club | any), following Green's
  from/to/three/home matching with our vocabulary
- Answers heritage questions directly: "every Quotation from A's
  documents to anywhere", "every Disagreement between X and Y"
- Implementation is a filtered scan over `work_to_links` initially
  (honest: not enfiladic); index optimization deferred until measured
- Acceptance: the two heritage queries return correct results on a
  seeded corpus; exposed in Connections as an advanced filter

### Story 5 — Federation of type definitions (network)
- Type ids being work ids means definitions replicate like any work:
  cross-server links carry the type's tumbler, resolving to the
  definition work on the origin server
- A receiving server that lacks the definition fetches + sanitizes it
  via the existing web-fetch path and registers a local alias
- Interop note recorded in the definition work's provenance
- Acceptance: a Disagreement link from another server renders with
  its type name and style intact

### Story 6 — Metalinks: bibliographic claims as links

Heritage: LM 93.1's Title and Author are *metalinks* — metadata as
typed links. More Xanadu-pure than record fields, and they buy what
fields cannot: contested claims stay visible instead of silently
overwritten, claims work across servers, and authorship becomes a
live query rather than a lookup. (Full rationale:
`docs/gold-link-semantics.md` §3.)

- Register three built-in metalink types alongside the five content
  types (definition works, per Stories 1-2):
  - **Title** — a claim about what this work should be called
  - **Author** — a claim of authorship, destination a Person work
    or an identity; the claim's provenance is the claimant's
    signature, NOT proof of the attribution itself
  - **Doc-Supercedes** — version lineage: this work replaces that
    one (cross-server by construction)
- Positioning is complementary, not a migration: span-level Ed25519
  provenance remains the attribution-of-record for *text*; metalinks
  are the *bibliographic claim* layer (cataloguing, disputes,
  cross-server credit)
- Fields remain as cache: `work.title`/`work.owner` become the
  materialized view of the preferred (owner's own, else most recent
  trusted) Title/Author claim — no query explosion in work lists
- Multiplicity renders where it exists: a work with two Author
  metalinks shows both in its header (hover: who claimed, when),
  with the cached field marked "contested"
- Link matching (Story 4) makes author pages live: "every work with
  an Author metalink to X" is one query; Doc-Supercedes chains give
  version lineages for free
- Acceptance:
  - a work with two Author metalinks renders both + contested field
  - the owner's Title metalink updates the cached title on next
    checkpoint (no list regression)
  - "all works attributed to X" query returns correct results on a
    seeded corpus
  - a Doc-Supercedes pair orders correctly in the version timeline

## Non-goals

- Executable/rendering programs in definitions (Green's "equation as
  graph" future) — conventions text and static style JSON only
- Formatting-as-links (Green's radical model) — our annotation kinds
  remain the formatting mechanism; documented as a deliberate fork
- Migrating the five built-in ids (1-5) — stability first; their
  definition works alias the historical ids

## Heritage appendix

| Source | Types |
|---|---|
| Green predefined | jump, quote, footnote, marginal note |
| LM 93.1 (pp. 4/52–4/55) | Title, Author, Doc-Supercedes, Correction, Comment, Counterpart, Translation, Heading, Paragraph, Quote-Link, Footnote, Layout, Vanilla/Modal Jump, Expansion, Citation, Alt-Version, Comment-Doc, Certification, Mail |
| Dougan 2007 | + Italics, Boldface, Underline, Text-Size (formatting set) |
| Xudanu shipped | Comment, Reference, Disagreement, Quotation, See Also, Web Link |

Disagreement: not found in the historical lists — document it as a
Xudanu addition consistent with Nelson's two-way-criticism principle.
