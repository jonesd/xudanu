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
