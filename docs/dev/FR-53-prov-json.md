# FR-53: PROV-JSON — Standard Conformance & Roadmap

- **ID:** FR-53
- **Status:** Phase 1 complete (conformance); Phase 2+ roadmap
- **Depends on:** FR-5 (attestation reports — the human artifact this is
  the machine-interchange twin of), per-span Ed25519 provenance
- **Audience:** backend; anyone selling to institutions that ingest
  provenance (archives, audit pipelines, research reproducibility)
- **Internal doc:** `src-rust/docs/PROV_JSON_INTEGRATION.md` (the
  original model-mapping analysis)

## 1. What PROV is, in one page

PROV is the W3C's 2013 vocabulary for provenance interchange —
*"information about entities, activities, and people involved in
producing a piece of data, used to form assessments about quality,
reliability, or trustworthiness."* It is **stable and final** — no
churn since 2013. The family:

| Document | What it is | We care because |
|---|---|---|
| [PROV-DM](https://www.w3.org/TR/prov-dm/) | The data model (entities, activities, agents; generation, usage, derivation, attribution) | Our export implements this model |
| [PROV-JSON](https://www.w3.org/Submission/2013/SUBM-prov-json-20130430/) | The JSON serialization — technically a **W3C Member Submission**, not a REC; the de-facto standard serialization | What we emit |
| [PROV-O](https://www.w3.org/TR/prov-o/) | OWL2/RDF ontology | Linked-data consumers; a future serialization for us |
| [PROV-CONSTRAINTS](https://www.w3.org/TR/prov-constraints/) | Defines *validity* (beyond syntax) — what validators check | Our conformance test mirrors the structural subset |
| [PROV-PRIMER](https://www.w3.org/TR/prov-primer/) | The gentle entry point | **Start here** when working on this FR |
| [PROV-DC](https://www.w3.org/TR/prov-dc/) | Dublin Core mapping | Archives/libraries speak DC natively — Phase 4 |
| [PROV-XML](https://www.w3.org/TR/prov-xml/) / [PROV-N](https://www.w3.org/TR/prov-n/) | Other serializations | Optional future output formats |

**Practical reading order:** Primer (1 hr) → PROV-JSON §2 examples
(the canonical JSON shapes, 30 min) → PROV-DM §5 (components) as
reference. The PROV-JSON spec's own §2 example documents are the
ground truth for serialization shape — our conformance test encodes
the same rules.

**Who uses it:** scientific workflows (Taverna/yesworkflow lineage,
NSF data-management plans), national archives & libraries (UK TNA,
LoC were working-group members), government open-data portals
(PROV-AQ access patterns), EBU broadcasting provenance, financial
& pharma audit adjacency (FSTC membership). Quiet institutional
infrastructure — never consumer-facing, frequently RFP-mandatory.

## 2. What xudanu has implemented

### Done (Phase 1 — this FR's completed work)

- **Full PROV-JSON document model** (provenance.rs): entities,
  activities, agents, `wasAttributedTo`, `wasDerivedFrom`
  (qualified form), `wasAssociatedWith`, `wasGeneratedBy`,
  `used`, `bundle` (federation witnessing), typed literals
  (`{"$": value, "type": "xsd:..."}` form), prefix bindings.
- **Export path**: `FederatedProvenance::to_prov_json_with_federation()`
  — base attribution + cross-server signature activities, usage
  records, federation consensus bundle.
- **Conformance fixes (hard-won, keep the tests)**:
  - QName legality: local names sanitized (`xudanu:span_42_0_10`,
    never `xudanu:span:42:0:10`) — central fix in `generate_prov_id`
  - No unbound prefixes (`attr:`, `cross_sig:`, `assoc:`,
    `consensus:` all eliminated)
  - `used` relation exists and is emitted (the core PROV-DM sentence)
  - Temporal slots carry `xsd:dateTime` (civil-from-days conversion);
    raw integers preserved in `xudanu:` attributes
  - QName-typed roles (`xudanu:verifier`, not bare `verifier`)
- **Structural conformance test** (`prov_json_export_conforms_to_spec`):
  validates the *serialized* JSON — allowed top-level keys, every ID
  prefix bound, local names legal, relation refs resolve, temporal
  slots dateTime-shaped, `prov:type` QName-typed. Caught a real bug
  (unbound `consensus:`) on its first run. **Extend, never bypass.**
- **Registered namespace**: `https://dgjones.info/ns/xudanu/`
  (replaces the `xudanu.example.org` placeholder; namespace document
  with RDFa served from the docs deployment at `docs/ns/xudanu/`).
- **Agent typing**: `AuthorType::to_prov_agent_type()` maps
  Human/LLM/Historical → `prov:Person` / `prov:SoftwareAgent` /
  derivation (the *function* is correct; the base exporter does not
  yet call it — see Phase 2).

### Known gaps (honest)

1. **Thinness**: the base export emits ONE synthetic span entity
   (`xudanu:span_0_0_1`, "generic entity ID since we don't have span
   info" — the code's own comment). The rich `ElementProvenance` /
   `SpanProvenance` data is not driven into the document yet. Valid
   PROV, vacuous content.
2. Author-type hardcoded to `prov:Person` in the base exporter.
3. No `prov:label` on entities (human readability in PROV tooling).
4. No edit-activity chains (used→generation for transclusion
   derivation is modeled but not emitted from real edit data).
5. Only PROV-JSON serialization; no PROV-O/RDF or PROV-N output.
6. Conformance test is *structural*; official PROV-CONSTRAINTS
   validity (e.g. no generation-before-usage time inversions) is
   not checked, and no external validator round-trip exists in CI.

## 3. Roadmap

### Phase 2 — Real content (the thinness fix) — ~2 days
- Drive per-span entities from `SpanProvenance`/`ElementProvenance`
  (one entity per signed span, real char ranges, per-span agents)
- Wire `AuthorType` mapping; `prov:label` = span excerpt (truncated)
- Emit derivation + usage chains for transclusions:
  `revision-activity used source-span → generated derived-span`
- Attestation report gains a `prov` companion export (same data,
  two artifacts)

### Phase 3 — Serializations — ~2-3 days
- PROV-O via JSON-LD (the `@context` is nearly free from our prefix
  map) for linked-data consumers
- PROV-N rendering for human-readable provenance in docs/demo
- Optional PROV-XML

### Phase 4 — Institutional interop — ~3-4 days
- PROV-DC mapping (archives/libraries; DC terms for title/creator/
  date alongside PROV structure)
- External validator round-trip in CI (provtoolbox or the online
  PROV validator; catches CONSTRAINTS-level invalidity our
  structural test cannot)
- PROV-CONSTRAINTS self-check on generation (time-ordering
  invariants)

### Phase 5 — Consumers (pairs with FR-5 trust ladder) — future
- C2PA manifest emission containing xudanu assertions (text
  provenance riding the Adobe/OpenAI infrastructure wave)
- W3C Verifiable Credentials wrapper of the attestation report
- SIEM/webhook ingestion of the chained security log

## 4. Product fit (recorded from strategy discussions)

- **Individuals** never see PROV — they get the attestation report
  (FR-5) and the verifier. PROV is plumbing beneath.
- **Small groups** need PROV only when a *third party* must verify
  without installing xudanu — the hand-off currency.
- **Organizations** ingest PROV into audit/SIEM/archival pipelines.
  PROV-JSON export is the interoperability tax that turns "no" into
  "yes" on institutional RFPs. Org-tier feature.

## 5. Test plan

- `prov_json_export_conforms_to_spec` — structural guard (exists;
  extend with each new relation type)
- Phase 2: golden-file test — a document with transclusion exports
  the full used→generation chain, span entities with real ranges
- Phase 4: external validator round-trip recorded in CI artifacts
- Property: any prefix used by any minted ID is bound (already
  asserted; keep generator changes central)

## 6. Relationships

- FR-5: attestation report = human/legal artifact; this FR = its
  machine-interchange twin. Same data, two audiences, never merged.
- FR-35/FR-37: federation witnessing bundles and crum identity give
  the PROV documents their strongest claims (Level 4 witnessing).
- FR-38: span keys and PROV entity IDs are the same idea in two
  vocabularies — stable identity for content positions; a future
  Phase 5 bridge could emit both in one manifest.
