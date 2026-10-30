# FR-155 — Cross-language transclusion: translation as a PROV edge

**Status:** Stage 1 complete and **verdict DECIDED 2026-10-30 —
Argos is the default engine; NLLB is the deliberate opt-in** (full
tally of record: `spike/xlate/bench/VERDICT.md` on the spike branch).
Stage 2 tracer bullet scoped, not started. The design below is fixed
by the spike (`spike/cross-language-transclusion`).

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

## Stage 2 — tracer bullet (scoped)

- `?lang=` read path on one span kind, flag-gated, local server only.
- `translate_provider_url` config; unset = zero behavior change.
- DoD: reader sees the rendition + its PROV record; reload hits the
  cache (zero provider calls).
- Kill rule: read-path p95 +>500ms on hit → stop, reshape.

## Language declaration: an annotation on runs (direction chosen)

Author attribution is **intrinsic** — derived from edit provenance by
the attribution system, never annotated (an annotation would compete
with the store's own truth). Language is **declared**, not intrinsic
— detection is banned by the spike rule (a stable translation key
must not drift), so the author or curator declares it:

- Rides the existing open-typed annotation system (`kind:
  "language"`, payload a language tag), document-default declared at
  creation, run-level override explicit.
- Declarations are claims with provenance (who, when); corrections
  are themselves recorded edits — never silent mutation.
- The translation edge pins source language at creation and must
  agree with the declared annotation — one source of truth.

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
