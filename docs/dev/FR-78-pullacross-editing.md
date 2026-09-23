# FR-78: Pullacross Editing — Rewriting With Origin Beams

**Status:** planned (phased)
**Created:** 2026-09-22
**Tradition:** Nelson, "Xanalogical Structure, Needed Now More than Ever"
(1999), Figs. 6 & 20 — pullacross editing; transclusion beams between
versions. PYXI's Declaration-of-Independence drafts (Fig. 5) is the
reference demonstration.

## The idea

Cut-and-paste makes a copy with amnesia. Pullacross makes **rewriting a
transclusive act**: passages pulled from an old revision into the new
draft keep their identity — the same content, knowably, in both places —
with **origin beams** showing where each passage came from, and the old
draft remaining a browsable pool of **what hasn't been used yet**.

For the single author this is the real prize (not multi-contributor
merge): seeing your own rewriting — what moved, what was dropped, which
arrangement was abandoned. And because our model records identity
(content addresses, span keys), the "diff" between versions is **read
from the ledger, not reconstructed by string comparison** — git guesses
history; we have it.

## What already exists (the surprise: most of it)

| Piece | Status |
|---|---|
| Revision history (`work_revisions_list`, `work_text_at_revision`) | shipped |
| Compare view, side-by-side with shared-passage highlights | shipped (MultiEndCompare) |
| Pinned-to-revision transclusions ("virtual" elements, `virtual_revision`) | shipped (FR-37 P3) — unpinned forbidden for determinism |
| Span keys stable across edits | shipped (FR-38) |
| Content-match index: BLAKE3 fingerprints, O(k) identical-span lookup | shipped — works across revisions, not just works |
| Attribution spans (who wrote what, per character) | shipped (CRDT layer) |

## Phases, prioritized by value-to-us per unit of risk

### Phase 1 — "The Two Drafts" gallery exhibit (no new machinery) 🥇

Seed one document with a visibly rearranged earlier revision; the
exhibit opens Compare on the two revisions with shared passages
highlighted. This is PYXI's Declaration demo with our engine, inside
the Gallery, next to the spectrum sentence.

- New room in the gallery seeder ("Wing II · Room 10: The Two Drafts")
- Text: an essay + a deliberately earlier draft (reorder paragraphs,
  cut a passage, add a new one)
- The room text explains beams = same content, not similarity
- **Value**: the tradition made visible in 30 seconds; HN/demo ready.
- **Risk**: ~zero. Seed script + an open-in-compare affordance.

### Phase 2 — Identity-based revision beams (read-side) 🥈

Teach Compare to render **transclusion beams between revisions of the
same work**: use the content-match index to find identical spans
between revision N−1 and N; draw beams; color them differently from
link-ribbons (braided vs dotted, the 1965 law). Add a "history" entry
point: from any work, open it against its previous revision in one
click.

- Server: `content_match` already crosses works; verify revision-pairs
  path; possibly a `revision_shared_spans` convenience op.
- Client: revision-pair mode in compare; beams join shared passages.
- **Value**: "showing the history of a document" becomes exact and
  beautiful — the ledger read aloud. Benefits single authors directly.
- **Risk**: low-medium. Reuses shipped indexes and view.

### Phase 3 — The pull gesture (write-side pullacross) 🥉

Split view: current draft beside revision N−1. Select a passage in the
old pane → **Pull** (button or drag) → inserts into the draft as a
**pinned virtual element** (`virtual_revision` = N−1, source span) —
never a copy. Origin beams render from the pulled span to its source
for as long as the author wants them visible.

- Server: element machinery already accepts pinned virtuals; may need
  an op variant that accepts revision + span and returns the placed
  element (small).
- Client: the gesture, the split view, beam rendering (overlay canvas
  already draws connector elbows — beams are a new shape, not a new
  system).
- Semantics: pulled content is LIVE-transcluded-but-pinned: the new
  draft shows the old text; "resolve to current" is an explicit later
  action if the author wants to keep editing it in place.
- **Value**: the full Nelson gesture; the writing workflow differentiator.
- **Risk**: medium. Editing-mode UX care (FR-74 model-truth rules apply).

### Phase 4 — The unused pool (coverage)

In the old pane: shade passages that have NOT been pulled, dim ones
that have — "what's left to use". Computed by interval subtraction of
pulled-source spans over the old revision's ranges. Purely read-side;
falls out of Phase 3's bookkeeping.

- **Value**: the poetic completion — nothing is ever lost, and you can
  see what you haven't used.
- **Risk**: low once Phase 3 records sources.

## Explicitly deferred

- Cross-work pullacross (pulling from OTHER works, not revisions) —
  compounds/FR-55 territory; revisit after Phase 3.
- Micropayment/transcopyright hooks (transpublishing) — business layer,
  not now.
- Fuzzy diff fallback when identity is absent (heavily rewritten text)
  — text-diff exists (`revision_compare`); keep it as the fallback
  view, never the primary story.

## Exit criteria

- P1: gallery visitor opens Two Drafts, sees beams between rearranged
  revisions, reads the label, gets it.
- P2: any work → one click → its previous revision side-by-side with
  identical passages beamed; beams are identity-colored, not diff-colored.
- P3: author pulls a passage from an old revision; it lands as pinned
  transclusion; beam visible on demand; unpulled material visibly
  distinct (P4).
