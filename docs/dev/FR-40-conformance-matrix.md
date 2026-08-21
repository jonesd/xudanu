# FR-40 Conformance Matrix — Xudanu vs the xanadu-spec link model

Status: living document · Date: 2026-08-21
FR: FR-40 (Green link constructs), with FR-39 (link types as
documents)
Reference: github.com/sisbell/xanadu-spec — formal specification of
the Xanadu hypertext system derived from Nelson's *Literary
Machines* and Gregory's udanax-green. Claim IDs below (L*, FL*,
S*, T*) cite that spec's ASN notes; ASN-0043 (Link Model) and
ASN-0121 (FINDLINKSFROMTOTHREE) are the primary notes.

Purpose: claim-by-claim account of where Xudanu satisfies, forks,
or gaps the spec's link-model semantics — in Xudanu's words, citing
their claim IDs. This is the artifact for (a) our own hardening
backlog, (b) the conversation with the spec's author (issue #1 on
sisbell/xanadu-spec), and (c) eventually, Roger Gregory.

Citation etiquette: the spec repo carries no license at time of
writing (all-rights-reserved by default). We cite claim IDs and
paraphrase semantics in our own words; no verbatim copying. Semantics
and ideas are not copyrightable, but prose is.

---

## How to read this matrix

- **Satisfies** — Xudanu's behavior meets the claim's requirement
  (possibly by different mechanism).
- **Fork (deliberate)** — we chose differently, with a reason; the
  divergence is a feature of Xudanu's design, recorded here so it is
  a decision and not an accident.
- **Fork (accidental?)** — a difference we did not consciously
  choose; candidates for alignment or explicit ratification.
- **Gap — adoptable** — spec capability we lack; tracked as backlog.
- **N/A** — the claim presumes machinery Xudanu does not have
  (permanent byte-address space); the user-level guarantee may still
  be met by other means, noted per row.

Legend for "where" column: `server.rs`, `links.rs` (edition),
`dispatch.rs`, `wal.rs` — implementation anchors in the Rust tree.

---

## 1. Identity and ownership

| Claim | Requirement (paraphrased) | Xudanu | Verdict | Where |
|---|---|---|---|---|
| — LinkStore DEF | links are first-class stored values | `links: HashMap<BeId, LinkState>` | Satisfies | server.rs |
| L11a LinkUniqueness | distinct creations → distinct ids, always fresh (no find-or-create) | `link_counter` monotonic; every create allocates a new id; no dedup anywhere | Satisfies | server.rs `create_link*` |
| L11b NonInjectivity | identical-content links coexist as separate objects | identity is the id, never the endsets; two identical A→B Comment links are two links | Satisfies | model-wide |
| L2 OwnershipEndsetIndependence | home determined without consulting endsets | `home_document: Option<BeId>` stored on LinkState; no end participates in its computation | Satisfies (structurally — even stronger: stored, not derived) | server.rs LinkState |
| L1a LinkScopedAllocation | every link is allocated under an existing document's prefix (mandatory home) | home is **optional**; default is server-global | Fork (deliberate): back-compat with ~900 commits of unhomed links; FR-40 Story 3 chose opt-in. Spec-pure would require home — see §6 backlog | server.rs |
| L12b HomeDocumentPersistence | homes of existing links remain allocated across transitions | we allow archiving a home (link hides, survives, restores) and never delete works outright | Satisfies (reversible-archive reading; we do not destroy homes) | server.rs `link_hidden_by_home_archive` |

## 2. Structure

| Claim | Requirement | Xudanu | Verdict | Where |
|---|---|---|---|---|
| L3 NEndsetStructure | arity ≥ 3; slot 3 (type) non-empty | arity ≥ 2; untyped links are the default; types live in `link_types: Vec<u64>` | Fork (deliberate): FR-40 non-goals keep the two-ended fast path ergonomic; multi-ended is additive. Our type channel is a vector, our ends a named map — see L5/L6 rows | links.rs HyperLink |
| L5 EndsetSetSemantics | an end is an unordered **set** of spans; no positional accessor inside an end | each named end holds **one** HyperRef (which may be Multi — a vec with set-like ops) | Partial fork: single-HyperRef ends approximate single-span ends; `HyperRefKind::Multi` restores set semantics within an end | links.rs |
| L6 SlotDistinction | slots are **positional** (e1=from, e2=to, e3=type…); link equality is tuple equality | ends are **named** (`HashMap<String, HyperRef>`: LeftEnd/RightEnd/custom); type is a separate vector | Fork (deliberate): names survive arity changes and read better on the wire; positional meaning is recovered by the Left/Right convention + link_query's distinct-pair semantics | links.rs, server.rs `link_query` |
| L4 EndsetGenerality | ends may span documents, subspaces, and non-content addresses | an end's HyperRef carries one `work_context`; cross-doc ends need multiple named ends or `HyperRef::Multi` | Partial: multi-work endsets possible via Multi refs (union/intersect exist) but not surfaced on the wire; cross-subspace (links-to-links) unexplored | links.rs |
| L14/L14a DualPrimitive / NonTranscludability | links and content occupy disjoint subspaces; arrangements never point at links | transclusions (spans) only reference works; links are not transcludable content in our model | Satisfies (by construction — different type universes) | model-wide |

## 3. Types (the three-set)

| Claim | Requirement | Xudanu | Verdict | Where |
|---|---|---|---|---|
| L8 TypeByAddress | type identity = address-set identity (coverage), not stored content | type identity = type **id** equality; ids reference registry entries | Satisfies-in-spirit: ids are our "pure addresses"; comparison is identity, content never consulted in matching | server.rs `link_query` |
| L9 TypeGhostPermission | types need no stored content (ghost types valid) | custom types **require** a definition work (registration hardening) | Fork (deliberate, FR-39): "the work IS the type" — we chose anti-squatting and human-legibility over ghost permission. Built-ins alias historical ids as the spec's own non-goal suggests for stability. Note: spec permits ghosts, does not require them — ours is a conforming restriction only if id-equality is read as the type identity | server.rs `register_link_type_checked` |
| L10 TypeHierarchyByContainment | prefix-containment subtyping; supertype query matches subtypes | exact-id matching | Gap — adoptable (FR-41 candidate). Our tumblers already do prefix queries (`XudanuTumbler`); type-id subtyping needs a convention for allocating subtype ids under supertype work-id prefixes | server.rs |
| LM 93.1 vocabulary breadth | Title/Author/Doc-Supercedes metalinks etc. | five built-ins + Web Link + Trail; custom types open | Partial: metalinks are FR-39 Story 6, still open | useTransclusion.ts, registry |

## 4. Queries (the four-set)

| Claim | Requirement | Xudanu | Verdict | Where |
|---|---|---|---|---|
| FL-DEF satisfaction rule | AND across slots; within a slot, single-address overlap suffices ("AND of ORs") | AND across the four sets; within a set we require the end's **work** to be listed in `work_ids` or owned by `author` | Partial: our spec granularity is work-ids/authors, not address spans — at our granularity the within-slot rule degenerates to membership (equivalent). True span-level OR awaits span-spec queries | server.rs `link_query` |
| FL-RES ResidenceEndpointIndependence | home criterion independent of endpoint criteria | home_spec tested against `LinkState.home_document`; from/to against ends — disjoint fields | Satisfies | server.rs |
| FL-DIR PositionalDirectionality | from/to matched by position, never pooled | distinct-pair semantics: the to-end must be a *different* end than the from-end (integration-tested) | Satisfies | server.rs, tests |
| FL-WILD WildcardSemantics | unspecified slot = no constraint (unit) | empty spec = Any (unit) | Satisfies | LinkEndpointSpecPayload |
| FL-EMP EmptyConstraintZero | empty-coverage constrained slot yields ∅ (zero ≠ unit) | no zero case: work_ids:[] + author:None collapses to Any | **Gap — accidental.** `work_ids:[]` and "no constraint" are indistinguishable on the wire. Fix: an explicit `constrained: bool` per spec or an `empty` sentinel meaning "match nothing" | LinkEndpointSpecPayload |
| FL-JUNK NonImpedance | non-matching links never affect results | linear scan filters per link; junk cannot affect matches | Satisfies (trivially at our scale; spec's point is asymptotic — our honesty note stands: linear until measured pain) | server.rs |
| FL-MON MonotoneAccumulation | matches persist as store grows (absent retraction) | matches are computed fresh per query; nothing removes links except delete | Satisfies | server.rs |
| FL-STB StabilityUnderEditing | edits never change the link set returned | span migration updates end positions, never link identity/membership | Satisfies (heritage-verified behavior; spec's L12+append-only is a stronger mechanism for the same guarantee) | revise_work span migration |

## 5. Lifecycle

| Claim | Requirement | Xudanu | Verdict | Where |
|---|---|---|---|---|
| L12 LinkImmutability | links never change after creation; no update op exists | `link_set_types`, `link_update`, `link_add_end`/`remove_end`, `delete_link` all mutate | Fork (deliberate, unratified?): interactive editing UX won over spec purity; end-editing was FR-40 Story 1's explicit requirement ("degrades to a valid N−1-ended link"). Flag for future: an append-only link-event log could restore immutability semantics underneath the mutating API | server.rs |
| Retraction (ASN-0086) | withdrawal = separate retraction links; store monotone; addressability filter | destructive `delete_link` | Fork (deliberate): matches our archive-not-delete philosophy elsewhere (works) but not for links. **FR-41 candidate: link retraction** — tombstone + addressable filter; cheap because `link_query` already has the filter shape | server.rs |
| L12a StoreMonotonicity | dom(Σ.L) only grows | delete shrinks it | Same fork as above (retraction restores conformity) | server.rs |

## 6. Summary and backlog

**Satisfies (or satisfies-in-spirit): 14 claims** — the identity,
ownership-independence, query-separation, directionality, wildcard,
and stability rows.

**Deliberate forks (4):** named-vs-positional slots (L6/L5),
optional home (L1a), mutable links (L12), definition-required types
(L9). Each is a real design decision with a reason; none is an
accident.

**Gaps — adoptable, prioritized:**
1. **FL-EMP zero-case** — explicit "match nothing" vs "any"
   distinction in `LinkEndpointSpecPayload`. Small, wire-compat
   additive field. *First fix.*
2. **L10 prefix type-hierarchy** — subtype matching by tumbler
   prefix on type ids. Medium; needs an id-allocation convention.
3. **Retraction (ASN-0086)** — non-destructive withdrawal +
   addressability. Medium-large; aligns with our archive
   philosophy; unlocks spec-conformant L12a.
4. **AND-of-ORs at span granularity** — span-level specs in
   link_query (from_spec/to_spec as span sets, not work lists).
   Large; deferred until a real query needs it.
5. **L1a mandatory home** — considered and rejected for back-compat;
   revisit only if home-sets (versioning) become load-bearing.

**Property-test conversions (next):** L11b (no dedup), L2 (home
invariant under end edits), FL-JUNK (junk addition invariance),
FL-DIR (reversed query distinctness), L12b (home archive/restore
never loses links). These map mechanically onto proptest from the
statements files.

---

## Provenance

- Spec reviewed 2026-08-20/21 from
  github.com/sisbell/xanadu-spec (commit history through
  2026-06-17; statements files through 2026-05-31/06-11 extracts).
- Outreach: github.com/sisbell/xanadu-spec issue #1 (2026-08-21),
  incl. the offer to run udanax-test-harness goldens as a
  differential suite (pending reply; Docker suite prerequisite).
- Xudanu implementation state: commit 88c9e1e ("feat(links): FR-40
  Green link constructs + FR-39 registration hardening", v1.7.0
  branch state).
