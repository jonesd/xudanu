# FR-58: Reference-over-Copy — Live Reuse Suggestions While Typing

- **ID:** FR-58
- **Status:** Proposed — gated on experiment E-0 (below). No
  implementation until E-0 numbers clear the thresholds.
- **Depends on:** FR-34 (recorders/backfollow index), FR-24 (license
  metadata), FR-51 (dots, stable addresses), FR-52 A-3 (OwnerSet
  canopy — license/visibility queries)
- **Optional tier:** `server/ollama.rs` (phrasing only, never matching)

## 1. Why this FR exists

The xanalogical principle is *no duplication*: a passage exists once
and is included by reference. Every mechanism we built enforces this
structurally (transclusions, backfollow, content addressing) — but
only *after* the user already knows the content exists elsewhere.
The missing piece is the moment of decision: **while a user is
typing a passage that already exists in the docuverse, the system
should offer to complete it as a live transclusion** — with
attribution, license-aware, before the duplicate is committed.

This is the one feature that is uniquely impossible without both
transclusion and a fast content-addressed substrate. A plain
collaborative editor can autocomplete from a model; only a
xanalogical system can autocomplete *from the docuverse, by
reference*. It turns Nelson's principle from an architectural rule
into a keystroke-level affordance.

Antecedents in this codebase (all become components):
- `source_matcher.rs` — MinHash near-duplicate detection (built for
  import attribution; here it becomes the fuzzy tier)
- `backfollow.rs` + recorders — the content-reuse index (here it
  becomes the candidate store)
- `ollama.rs` — optional LLM tier (phrasing of the suggestion card;
  never in the matching path)

## 2. The matching tiers

Typing is incremental, so exact paragraph crums alone fire too late
(a prefix is not the paragraph). Three tiers, cheapest first:

| Tier | Mechanism | Fires when | Cost |
|---|---|---|---|
| T1 exact | n-gram/sentence hash inverted index: `hash(n-gram) → [(work, dot-range)]` | after the first completed n-gram of a known passage | µs (hash probe) |
| T2 near | MinHash signature per paragraph (existing `compute_minhash`), candidate works ranked by `minhash_similarity` | paragraph ~60% typed | µs–ms |
| T3 phrase | Ollama wording of the suggestion card ("this passage appears in…") | on display | optional, off critical path |

T1 is the workhorse: it triggers *mid-passage*, which is the UX
requirement. The n-gram size `n` is the tuning knob — small n fires
early but noisier; large n fires late but precise. E-0 exists to
measure exactly this tradeoff on real corpus data.

Suggestions are anchored to **dot ranges / Sequence addresses**, not
char offsets — immune to the drift that plagues offset-based
anchors (the C-3 migration guarantee). A suggestion that fires at
time T remains valid while the source work is edited, because the
address space is append-only.

## 3. The loop

1. **Trigger:** debounced (300–500ms idle or every N chars), the
   client sends the changed region's last completed n-grams.
2. **Query (server):** T1 probe → candidate (work, dot-range) list →
   rank (longest overlap, same-work down-ranked, link-graph
   proximity up-ranked) → **license gate**: A-3 OwnerSet canopy query
   drops anything the user cannot read; ARR sources surface with the
   FR-24 warning badge instead of silently vanishing.
3. **Present:** ghost-text completion card — source work, author
   provenance (dots carry it), license badge, match tier.
4. **Accept:** insert an inline `RangeElement::Transclusion` (C-2
   overlay) pointing at the source dot-range. Attribution is
   automatic and exact — no LLM-generated text enters the document.
5. **Decline:** suggestion expires; the typed text stands. (A
   declined-then-completed duplicate is a *future* backfollow
   detection, not a nag.)

## 4. Experiment E-0 — the cheap gate

**Question:** on real corpus text, do the tiers fire early enough,
precisely enough, and fast enough to be worth building?

**Method (offline replay, no UI, no new server surface):**
1. Instantiate a test server with the seeded demo corpus
   (`--seed-links-demo`): the Links Course contains quotation links,
   three-ended links, gathered end-sets — all *by construction*
   duplicated passages with known ground truth (the link records
   themselves say which span came from which work).
2. For every known duplication (link/transclusion record), replay
   the destination passage as typing: prefixes at 10/25/50/75/100%.
3. At each prefix, run T1 (sweep n ∈ {4, 6, 8, 10} words) and T2;
   record the earliest trigger, correctness, and query latency.
4. Report the matrix: coverage (share of known duplications
   detected), precision, mean trigger point (% typed), p50/p99
   latency — as a function of n.

**Proceed to implementation iff:** coverage ≥ 80%, precision ≥ 90%,
mean trigger ≤ 60% of passage typed, p99 query ≤ 50ms. If T1 alone
clears the bar, T2 is demoted to fallback; if nothing clears it,
the FR dies cheap (a day of harness code, zero product code).

## 5. Stories

| # | Story | Notes |
|---|---|---|
| E-0 | Replay harness + matrix report | gating; pure test code |
| S1 | N-gram index service (server-side, maintained by recorders on materialization) | write path, incremental |
| S2 | Query op + wire (`SuggestionQuery` 0x0358, response carries ranked cards) | admin-off by default, per-user enable |
| S3 | Frontend ghost-text card (CollaborativeEditor overlay) | accept/decline/dismiss |
| S4 | Accept → inline Transclusion with provenance | reuses C-2 overlay verbatim |
| S5 | Telemetry (fire/accept/decline rates, trigger point) + n tuning | feeds back into E-0 matrix live |

## 6. Acceptance criteria

- E-0 thresholds met on the seeded corpus (above).
- An accepted suggestion produces a real transclusion whose
  provenance, license badge, and live-update behavior are identical
  to a manually created one (no special case in the read path).
- No suggestion ever surfaces content the querying user cannot read
  (server-enforced via A-3; tested with a private-work fixture).
- Suggestion queries add ≤ 1ms p50 to editor dispatch when enabled.
- The feature is off by default and per-user reversible.

## 7. Non-goals

- No LLM-generated text entering documents (T3 phrases the card,
  not the content).
- No proactive "you duplicated this" enforcement after the fact —
  backfollow already reports reuse; this FR only acts at typing time.
- No cross-server suggestions in v1 (federation candidate later; the
  index is local works only).

## 8. Relationship to other FRs

| FR | Relationship |
|---|---|
| FR-34 | Recorders maintain the T1/T2 indexes on materialization |
| FR-24 | License badges + ARR warning on the card; server never brokers rights |
| FR-51 | Dots/Sequence anchors keep suggestions stable under concurrent edits |
| FR-52 A-3 | OwnerSet canopy = the visibility gate |
| FR-40 | "Why similar" context: existing links between the works decorate the card |
| FR-57 | Not a dependency — suggestions are read-path, unaffected by tombstone GC |
