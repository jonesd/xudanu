# FR-155 — Cross-language transclusion: translation as a PROV edge

**Status:** Stage 1 complete and **verdict DECIDED 2026-10-30 —
Argos is the default engine; NLLB is the deliberate opt-in** (full
tally of record: `spike/xlate/bench/VERDICT.md` on the spike branch).
**Stage 2 tracer bullet BUILT 2026-10-30** (branch
`fr155/lang-read-path`): lazy `?lang=` read path on the public work
API, wire op 0x0f2d `translate_capabilities`, FR-156 registry row
live. DoD met against a live Argos sidecar: cold read 559ms for 3
spans (one batched provider call), warm read 3ms with zero provider
calls and byte-identical text, PROV edge per rendition
(`wasDerivedFrom` source hash, engine identity, machine-gisting
grade), kill rule p95 delta **1ms** against a +500ms budget.

**Heritage:** the Xanadu lineage made quoting-with-both-ends-visible
the core primitive. FR-155 completes it across languages: a reader
reads in their language while the original stays canonical,
addressed, and one hop away.

## The one-liner

A machine translation is a **derivation edge in the PROV graph** —
never a button that mutates text, never a bulk conversion, never a
substitute for the original.

```
span  <-used-  xudanu:Translation  -wasGeneratedBy->  rendition
  ╰———————— prov:wasDerivedFrom (THE EDGE) ————————╯
```

## The edge

The edge tuple is the cache key:

`(span content, source lang, target lang, provider, model version)`
→ content-addressed rendition

Invariants (spike-tested):

1. **Content addressing** — same tuple yields byte-identical bytes;
   a repeat resolve makes zero provider calls.
2. **Links resolve to originals** — the rendition `wasDerivedFrom`
   the span; a rendition is never a link target (see transclusion).
3. **No silent invalidation** — source edit → new checksum → new
   key; model upgrade → new key. Stale renditions are unreachable,
   never mutated under a stable address, and retained as history.
4. **Source language is pinned on the edge, never detected** at call
   time. Detection drift would silently change a stable key's output.
5. **Provider must name its model.** LibreTranslate's API cannot;
   model identity comes from deployment config (image digest), and
   the provider trait makes `model_version` first-class.
6. **Gisting-grade is labeled.** `qualityGrade: machine-gisting`
   ships on the entity; the chip labels rather than translates.

## The read path: `?lang=<target>` (lazy, per-reader)

Nothing happens at authoring time — ever. No language detection, no
eager translation, no N-language fan-out. Renditions exist only
because a reader asked:

1. Reader opens a document with `?lang=en`.
2. Each visible span is checked against its pinned source language:
   spans already in the target language render as-is; others resolve
   their edge key.
3. Cache hit → serve; miss → one provider call for that span → edge
   recorded → serve.
4. Next reader of the same pair gets the cache hit.

Design guards:

- `translate_provider_url` unset (the default) → **zero behavior
  change**; the read path behaves exactly as today.
- If the chosen engine's mislead rate exceeds the verdict threshold
  (≈⅓), renditions render **click-to-reveal only**, never
  auto-render.
- Kill rule for Stage 2: read-path p95 must not grow by more than
  ~500ms on a cache hit.
- Server has no `Accept-Language` handling anywhere (verified) —
  `?lang=` is explicit reader intent, not negotiation.

## Composition with transclusion (no special flow)

The cache key contains **no document** — spans, not works. Since
transclusion already moves content-addressed spans into reading
contexts, the two mechanisms compose without knowing about each
other:

- **Amortization** — two documents transcluding the same span share
  one rendition edge; widely-read spans converge to many languages
  organically, driven by real reader demand.
- **Mixed-language documents** — a German work transcluding a French
  span resolves `(span, fr, de)` per-span; the document's own
  language renders as-is.
- **Provenance chains lengthen correctly** — reader sees rendition →
  original span → transclusion link, answering "what exactly did I
  read" across both mechanisms.
- **A rendition is never a transclusion source.** Want "the English
  version"? You transclude the original and get your own language's
  rendition — never a translation of a translation.

## Why mixed-language matters (the academic case)

- **Primary-source scholarship** — commentary in the scholar's
  language around canonical originals; the scholar never pastes a
  translation, they transclude the source and let readers choose.
- **Citations point at originals** — a machine rendition is a
  paraphrase aid, never quotable as the text; the original is one
  hop away by construction.
- **Citations don't rot** — checksum addressing means a cited
  rendition stays byte-identical; edited sources leave old renditions
  reachable as history, not mutated.
- **Human translation upgrades in place** — PROV natively
  distinguishes agents; a scholar's authoritative translation rides
  the same edge shape (`wasGeneratedBy` a person, not a provider),
  so the graph grades from machine-gisting to scholarly without a
  schema change. Future work; the shape allows it.
- **Pedagogy** — language learners read with on-demand renditions;
  click-to-reveal friction (the mislead rule) forces comparison with
  the original, which is the point in a classroom.

## Engine (DECIDED 2026-10-30: Argos default, NLLB opt-in)

| engine | role | p50 | p95 | worst | RSS | license |
|---|---|---|---|---|---|---|
| Argos | **default** | 430ms | 672ms | 1223ms | 987.5MiB | CC-BY (default-safe) |
| NLLB-600M int8 | deliberate opt-in | 1786ms | 2909ms | 5221ms | 1.031GiB | CC-BY-NC 4.0 (operator-fetched) |

Owner-ratified tally of record: **Argos 10g/2m/0f, NLLB 10g/1m/1f**
— mislead rates tie at 17%, under the ⅓ threshold, so **Argos
renditions may auto-render**. The honest headline: NLLB edges more
individual spans (technical register, *Anschauungen*, the numbers
span) and does not lose on rates — **Argos wins on failure
character**: both catastrophic failures in the set are NLLB's and
both are silent and fluent (Küssnacht → "Kiss Night"; the long
paragraph's final sentence dropped without error), while Argos's
failures are loud and self-flagging (*Stäbe* → "staffs"; garbled
numbers syntax). Visible failure warns the reader; invisible failure
deceives them. Owner preference, latency (430ms vs 1.8s p50), and
license (CC-BY vs CC-BY-NC) vote the same way. **NLLB, when opted
in, renders long spans click-to-reveal** — silent truncation is its
known failure class. Clean upgrades if coverage demands: MADLAD-400
(Apache-2.0), M2M-100 (MIT).

## Licensing & weights policy (decided)

- Weights are **never bundled or auto-downloaded** by the product.
- An operator wanting NLLB fetches the model themselves (becoming
  the direct licensee of the CC-BY-NC terms), sets config, and types
  an explicit acknowledgment.
- Engine identity rides every translation edge in PROV — per-instance
  compliance is auditable from the provenance graph itself.
- Translation appears in the FR-156 license-posture registry when
  this feature actually ships.

## Stage 2 — tracer bullet (BUILT 2026-10-30, branch fr155/lang-read-path)

Shipped surface:

- `GET /api/public/work/{id}?lang=<BCP-47>` — translated public
  read. Gather under short locks, provider call in `spawn_blocking`
  with no server lock held (FR-86 lesson), re-sign the translated
  body, original hash preserved, `x-xudanu-translation` header.
  Layout gaps (newlines between translation units) pass through
  verbatim. Provider failure degrades to the original text — a
  sidecar being down never breaks the public API.
- Translation units are coalesced **lines**, not O-tree
  per-character carriers (one carrier per char — translating letters
  is garbage; caught live in the first demo run).
- Wire op 0x0f2d `translate_capabilities` — provider, model,
  language coverage (`/languages`, 1h cache), cache depth;
  early-routed like the LLM ops so provider I/O never runs under
  the state lock.
- FR-156 registry: `translate` row live (RuntimeConfig source; state
  mirrors the env opt-in — still a mirror, not a switch).
- Config: `XUDANU_TRANSLATE_PROVIDER_URL` (unset = disabled, zero
  behavior change — regression-tested byte-for-byte), optional
  `XUDANU_TRANSLATE_PROVIDER` (default argos), `XUDANU_TRANSLATE_MODEL`
  (rides every PROV edge), `XUDANU_TRANSLATE_API_KEY`.

Measured (Argos sidecar, de↔en, 3-span document): cold 559ms /
warm 3ms / p95 delta vs plain 1ms. Kill rule (+500ms) not tripped.

Capacity probe (release build, Apple M4 10-core, Argos en↔fr in
Docker, `scripts/fr155-load.mjs`): warm translated reads serve
~2,800 req/s aggregate (p95 3–18ms at conc 4–32, zero engine
calls — same ballpark as untranslated reads); cold first-views run
~5.7 docs/s (~23 translation units/s, one batched engine call per
doc, p50 0.8s / p95 4.2s at conc 8). The public-read rate limiter
(120 GETs/min per client IP) is the per-reader design cap, not a
bottleneck: warm capacity is per-(content, language) once, so the
engine load tracks new content, not reader count.

Deliberately out (next stages): `work_get_edition` WS path,
transclusion resolution interplay, rendition-never-a-target
enforcement on the read side, federation travel, authoring-UI
language declaration, pre-warming (now unblocked by Stage 3).

## Stage 3 — rendition durability (BUILT 2026-10-31, branch fr155/rendition-durability)

Renditions now live on disk beside the chunks and blobs:
`<data>/renditions/<xx>/<key-hex>.json` — one JSON
`TranslationEntry` per file, named by the cache key (BLAKE3 of the
edge tuple), sharded like the blob store. Lookup order is memory →
disk → engine; a disk hit is promoted to memory, so a restart pays
one small file read per key, then memory speed.

Properties:

- **Self-healing, tamper-checked**: a file that fails to parse, or
  whose rendition text does not hash to its own `rendition_hash`,
  is treated as a miss (retranslate, overwrite) — corruption,
  tampering, and format evolution all degrade to recompute instead
  of being served. Writes are temp-file + rename (atomic
  visibility); a crashed `.tmp` is never read.
- **PROV survives**: the stored entry *is* the PROV record — after a
  restart, renditions report their original `created_at`, provider,
  and model. A changed model changes the key, so a new engine's
  output never mixes with the old engine's renditions.
- **Degradation contract**: no data directory → no store → exactly
  Stage 2's memory-only behavior (pinned over the wire:
  `translate_capabilities.cache_disk_entries` is null, not zero).
  A store that cannot open logs a warning and serves memory-only;
  startup never fails.
- `translate_capabilities` now also reports `cache_disk_entries` and
  `rendition_store_path`; the read block reports `disk_hits` and
  `renditions_durable`.

Measured — the strongest form of the proof: engine container
stopped, server `kill -9`ed, restarted on the same data dir. First
translated read after restart: **3.3ms, `disk_hits=3`,
`provider_calls=0`** — fully translated while the engine was
unreachable; second read 1.8ms from promoted memory. Kill rule
unaffected (p95 delta 0ms with the store attached). Files are plain
JSON, so any rendition's provenance is one `cat` away.

What this unlocks: pre-warming (per the provisioning decision) is
now worth building — warmed renditions survive restarts.

## Human renditions (DECIDED 2026-10-31)

`machine-gisting` is the bottom rung of a quality ladder, not a
final state. Humans may improve machine renditions; the design:

**Grade ladder** (all in PROV, where attribution already lives):

| Grade | How reached | Agent |
| --- | --- | --- |
| `machine-gisting` | engine produces it (today) | named engine + model |
| `human-draft` | a translator edits/submits, span-aligned | verified identity, license declared |
| `human-reviewed` | a second person endorses it | two-person rule |
| `canonical` | selected per (work, language) | owner/curator first, community endorsement later |

Serve order on `?lang=`: canonical → human-reviewed → human-draft →
machine. Every response stamps its honest grade; a reader always
knows which rung they are on. Human renditions record
`wasRevisionOf` the machine draft (or `wasDerivedFrom` the source)
with the translator as PROV agent — attribution stays derived from
who did the work, never annotated.

**Validation anchors to the source, never to the machine draft.**
A similarity-to-MT gate would enforce MT-shaped prose and punish
exactly the nuance a human is paid for. Mechanical checks are:
same source hash, every source span covered (no omissions), valid
BCP-47 target, verified identity, license declared. Edit distance
to the machine draft is *recorded as metadata* (it grades engines
by how much correction they need) and never gates.

**Two hard rules:** human renditions are still not content — not
transcludable, not link targets, parallel readings keyed to source
spans (the xanalogical parallel-document model). And a human
translation is copyrightable creative work: the translator declares
a license (FR-24 options) and grants serving rights on submission.

**Staged path:** submit/review ops → serve order by grade →
community endorsements (one per verified identity, retractable) →
cross-server canonical selection via PBFT when federation travel
arrives. Builds on machinery that already exists: `LinkEndorse`
(0x0710, WAL-durable) proves per-identity endorsement over the
wire; `edition/endorsement.rs` provides the set algebra; a
*reputation* model (accumulated standing) is future work and
deliberately not required for the first stages.

**Udanax Gold lineage** (checked against `src/promise.rog/client.prc`):
this design re-inhabits Gold's trust model rather than inventing
one. Gold's `Edition` and `Work` both carried
`endorse(CrossRegion)` / `endorsements()` / `retract(CrossRegion)`
— trust assertions anchored to *regions of content*, including
`CrossRegion[IDSpace,IDSpace]` (a region in one space vouching
for a region in another — exactly the shape of a translation
endorsement: source spans ↔ rendition spans). `Work.sponsor(
IDRegion clubs)` was the public-reputation layer (the Rust port
keeps `add_sponsor`, persisted and queryable; "sponsors are public
reputation, not secret"). `visibleEndorsements()` separated what
endorsements exist from what a reader may see. The port kept the
set algebra, `CrossRegionN` in the space module, sponsorship, and
WAL-durable link endorsement; what was dormant — humans endorsing
regions — is precisely what this stage restores, pointed at
renditions first.

Sequencing note: reordered 2026-10-31 — this lands *before* pre-warming
and the offer-list, because the trust-lab experiment (FR-157) needs the
ladder as its substrate.

## Stage A — submit, endorse, serve by grade (BUILT 2026-10-31, branch fr155/human-renditions)

The ladder's first three rungs are real: `machine-gisting` (engine,
Stage 2), `human-draft` (submit), `human-reviewed` (endorse). The
`canonical` rung stays future (owner/curator selection, later PBFT).

**Data model** (`server/translate.rs`): a `HumanSubmission` is a
whole-document translation into one language — `work_id` (hex),
`target_lang`, `submitter_club`, optional `derived_from_model`
(`wasRevisionOf` PROV material), FR-24 `license`, `created_at`, and
span-aligned `HumanSpanRendition`s (`char_start`, `char_end`,
`source_hash`, `rendition`). The submission's **id is its content**
(blake3 over everything except endorsements): endorsements mutate the
record, never the identity, so a grade can rise and fall without
orphaning references. `grade()` is derived, not stored: no
endorsements → `human-draft`, any → `human-reviewed`.

**Durable layout** (rides the Stage 3 store, `<data>/renditions/`):
`human/<xx>/<hash>.json` per submission, written atomically
(tmp+rename); `human-index/<work>-<lang>.json` lists ids per
(work, language). Tamper semantics inherit Stage 3's: a corrupt or
unparseable file is a miss, never a crash.

**Validation anchors to the source** (`validate_human_submission`):
every translatable span (declared source language ≠ target) must be
covered exactly once, each candidate's range must equal a span's, and
each `source_hash` must match the span's *current* text — a mismatch
means the source changed and the submission is rejected
("retranslate"). Extra ranges, duplicates, empty renditions, and
malformed BCP-47 targets are rejected. Submit-side checks run in the
dispatch layer (0x0f30) against `edition_text_spans` +
`public_language_annotations`, and the work must pass
`public_work_edition` — renditions serve the public read path, so a
non-public work has nothing to attach to. License must be one of the
FR-24 serde tags.

**Serving** (`assemble_translated_read`, new last param `human`):
the strongest submission for (work, lang) is fetched
(`best_human`: reviewed beats draft, more endorsements beat fewer,
then newest) and consulted **span by span before cache, disk, and
engine**. A human span applies only while the live text still hashes
to what the translator anchored to — an edited source silently
invalidates that span back to the machine path, never serving a
stale human rendition. Full human coverage makes no provider call.
PROV per human span: `wasGeneratedBy: xudanu:HumanSubmission`,
quality_grade at the submission's grade, `wasRevisionOf` the engine
model when the translator started from a draft, submitter recorded.
The response block carries a `human` section (submission id, grade,
submitter, license, endorsers, spans offered/used). The top-level
grade goes human only when human spans covered *every* translated
span — partial coverage keeps `machine-gisting` at the top while the
per-span entries carry the mixed truth. Human renditions remain not
content: never addressable, never transcludable.

**Endorsement rules** (in the store, enforced server-side):
two-person rule (the submitter's club cannot endorse its own
submission), one endorsement per identity, retraction via
`translation_unendorse`. Endorsements are `(club_id, timestamp)`
— unweighted by design; weighting is the n>100 problem (FR-157).

**Wire ops** (protocol + codec + dispatch; tripwire now 0x0f34):

| Op | Code | Gate |
| --- | --- | --- |
| `translation_submit` | 0x0f30 | logged-in identity; source-anchored validation |
| `translation_endorse` | 0x0f31 | logged-in identity; two-person + one-per-identity |
| `translation_unendorse` | 0x0f32 | logged-in identity |
| `translation_list` | 0x0f33 | any connected session; strongest first |

All four are museum-mode mutations (except list) and route early in
dispatch with the FR-86 lock discipline: gather session/spans under a
short lock, do file I/O outside it. Requires the data-dir rendition
store (clear Internal error when absent).

**Tests**: 7 new unit tests (preference over machine with zero
provider calls, partial coverage fallback, stale-hash fallback, id
stability under endorsement, validation accept/reject matrix, store
roundtrip + endorse rules) and a full wire test
(`translation_human_renditions_over_wire`) driving two
password-authenticated personal identities through
publish → annotate → submit → self-endorse rejection → endorse →
duplicate rejection → list → retract → cross-endorse ordering.

**Known limitation (deliberate)**: the `?lang=` read path remains
provider-gated as a whole — without `XUDANU_TRANSLATE_PROVIDER_URL`,
human renditions are durable and listable but not *served*, keeping
the zero-behavior-change guarantee byte-simple. Human-only serving
without an engine is a small future change (the gate, not the
assembly — assembly already needs no provider call for covered
spans) and is recorded here so it is a decision, not an accident.

**Next**: trust-lab v0 (FR-157's synthetic-population harness) on
this substrate.

## Provisioning languages (DECIDED 2026-10-30)

The system has exactly three units, and "installing a language"
means different things at each layer:

| Layer | Unit | Notes |
| --- | --- | --- |
| Engine capability | directional pair (en→fr) | one model; measured 80–156 MB per direction, 60–272 MB across the catalog |
| Reader intent | single target tag (`?lang=fr`) | one language per read, always |
| Deployment | a set of pairs | the engine's `--load-only` list |

**Pairs are the atom.** Directionality halves resource cost where a
community only reads across one direction, and it keeps PROV exact:
every rendition names the model that produced it.

**Packages are selection UX, never server concepts.** A named
language pack would (1) create a canon problem — whoever defines
"the European pack" owns a contested, stale-prone taxonomy; (2)
couple the wire protocol to engine deployment details that
`translate_capabilities` already reports truthfully; (3) tempt
mixed-engine packs (Latin and Ancient Greek exist only on NLLB),
forcing multi-engine routing before it is designed. The offer-list
panel (follow-on) gets multi-select plus a paste-able
`en,fr,de` line instead — sharing selections without taxonomy.

**Model installation stays an operator act.** Weights are never
bundled or auto-downloaded; the operator fetches, becomes the
direct licensee, and the deployment is deliberate and inspectable.
The engine has no runtime model-loading API regardless — changing
pairs means recreating the container.

**Batch shows up as pre-warming, later.** An admin action to
translate one work into all offered languages ahead of readers is
cheap at measured rates (~5.7 docs/s cold → a 10-language pre-warm
≈ 2s of engine time) and smooths the first-view stampede tail
(p95 4.2s). It belongs beside rendition durability, so warmed
renditions survive restarts.

### Operator runbook: adding a language pair

1. Recreate the engine with the pair loaded, e.g.
   `docker run -d --name xlate -p 5050:5000 libretranslate/libretranslate --load-only en,fr,de --disable-web-ui`
   (~60–160 MB downloads per direction; en↔de measured 313 MB, en↔fr 158 MB).
2. Nothing to restart on the xudanu server: it discovers coverage
   from the engine's `/languages` on the next capabilities call
   (cached 1h).
3. Pairs without a direct model pivot through English
   automatically, at some quality cost.
4. For languages Argos does not serve (e.g. `la`, `grc`): deploy the
   NLLB sidecar instead — the deliberate opt-in per the engine
   verdict (operator-fetched weights, CC-BY-NC).
5. The server's renditions cache is content-addressed; a changed
   model identity changes PROV and cache keys, so readers see the
   new engine on fresh content without staleness.

## Language declaration: an annotation on runs (direction chosen)

Author attribution is **intrinsic** — derived from edit provenance by
the attribution system, never annotated (an annotation would compete
with the store's own truth). Language is **declared**, not intrinsic
— detection is banned by the spike rule (a stable translation key
must not drift), so the author or curator declares it:

- Rides the existing open-typed annotation system (`kind:
  "language"`, payload a language tag), document-default declared at
  creation, run-level override explicit.
- **Transcluded runs inherit** — the declaration lives on the
  original text in the source work; a document quoting Latin from a
  Latin work never re-declares it (language resolves through the
  link; one source of truth).
- **Detection may suggest, never declare** — an authoring UI may
  offer "this looks like Latin — mark it?", but nothing is recorded
  until a human confirms. Detector output is version-dependent and
  must never touch a stable key.
- Tag vocabulary is BCP-47 (`en`, `fr`, `la`, `grc` vs `el`) — no
  invented taxonomy.
- Declarations are claims with provenance (who, when); corrections
  are themselves recorded edits — never silent mutation.
- The translation edge pins source language at creation and must
  agree with the declared annotation — one source of truth.
- Failure modes, honestly: a missing override falls to the document
  default → the run renders as-is, no rendition offered (benign
  absence, visible); a wrong declaration keys a wrong rendition
  (malign) — which is why language is fail-critical and the
  declaration UX is guarded.

Governance as run annotations multiply: every new kind answers *who
declares it, what consumes it, what breaks if it lies*. Language is
fail-critical (a lie keys wrong renditions); formatting marks are
cosmetic. Severity sets how guarded the declaration UX must be.

## Deliberately unanswered

Federation travel of renditions (whose cache serves a cross-server
read; does the edge travel with the span?), cluster/quorum
endorsement of renditions, write-side anything, language detection
at authoring time (banned for keys; the authoring-UI shape for
declaring language is Stage 2 work).
