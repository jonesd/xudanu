# HT-Driven Enhancements — what to build from the papers' usage patterns

Each item: the paper that showed the need, what's missing in Xudanu,
effort, and priority. Ordered by paper-alignment value.

---

## 1. Wire author_type through the content paths
**Source:** Millard §7.3 (finer-grained provenance); H(G) Q4
(H(G_AI) vs H(G_human)); Adamski §5.2 (phantom nodes)

**Gap:** AuthorType enum exists on ElementProvenance but is never set
by the creation/revision paths — all content defaults to the session
key type. No wire flag, no auto-detection from agent identity.

**Build:** Add `author_type` param to `work_create`, `work_revise`,
and `crdt_apply_text_delta` (optional, defaults to session key type).
An LLM agent connecting via WS passes `author_type: "llm"` on its
ops. The provenance stamp carries it. ~2 hours.

**Why it matters:** Unlocks the H(G_AI) vs H(G_human) measurement
(the paper figure nobody else can produce) and closes the gap
between our schema and our detection.

---

## 2. Narrative daily history (session-level changelog)
**Source:** Millard §4.3 (daily history entries — "narrative trace of
additions and connections that I review"); Seed §2.3 (conversation as
first-class units)

**Gap:** Our attribution log is cryptographically sound but
human-opaque (hex signatures, JSON entries). No readable narrative
of "what was added and connected today."

**Build:** On checkpoint, generate a per-day summary: new works,
new links (by type), transclusions created, revisions made. Store
as a work (type: "history") with links back to everything it
describes. Auto-created, human-readable, itself part of the
docuverse. ~4 hours.

**Why it matters:** Millard's history entries are "a hedge against
attribution drift" (the AI Memory Gap). Ours would be the same
hedge, but cryptographically anchored.

---

## 3. Maturity model on works (sapling/fern/tree)
**Source:** Millard §4.1 (maturity tracking via connectivity +
completeness); Anderson §3.6.1 (intentional vs collecting)

**Gap:** No work-level indicator of development stage. Works are
either "created" or "revised" — no gradient.

**Build:** Compute a connectivity score per work (in-degree +
out-degree + transclusion count), expose as work metadata. Three
tiers: sapling (< 3 connections), fern (3-7), tree (> 7). Display
in the library list + work summary panel. ~3 hours.

**Why it matters:** Makes the docuverse's growth visible. Gives
H(G)'s generative-capacity coordinate a human-facing proxy.

---

## 4. Typed-link export as RDF/PROV (bridge to Linked Data)
**Source:** Anderson §3.2.3 ("typed links offer an interesting
bridge to the Semantic Web and Linked Data"); Seed §2.4 (RDF/IPFS
as enabling substrate)

**Gap:** Our typed links are internal-only. No RDF/PROV export;
the PROV validator exists but there's no producer.

**Build:** An export subcommand (`xudanu-server export-prov <dir>`)
that walks works + links + provenance and emits PROV-JSON or
Turtle: works as prov:Entity, link types as prov:type, authors as
prov:Agent with AuthorType mapped to PROV agent classes. ~6 hours.

**Why it matters:** Anderson says current TfT are "blind" to Linked
Data; we'd be the system that ships the bridge. Also gives the
H(G) team a corpus in a format they can process.

---

## 5. Document forking (branch a work, provenance preserved)
**Source:** Seed §3 ("any document can be forked... preserving
attribution and provenance"); H(G) §5.3 (Xanadu's deep versioning)

**Gap:** We have club-level branches (FR-52 P2) but no user-facing
"fork this work" operation. Revising creates a new revision in the
same work; forking creates a new work with lineage.

**Build:** `work_fork(work_id, new_title)` — creates a new work
with a copy of the edition, sets `derived_from: original_id` in
metadata, creates a See Also link back. The fork is independent
but traceable. ~1 day.

**Why it matters:** Seed's core primitive; the ent's version-
forking realized. For debate corpora (like our policy debate),
forking lets positions branch without overwriting.

---

## 6. Multiple views: timeline view of a work
**Source:** Anderson §3.5.1 (Tinderbox's 10+ views of the same
notes); §3.5.3 (temporal axis); Engelbart's viewspecs

**Gap:** We have editor + reading + graph + compare, but no
temporal view. Revision timestamps exist; no visualization.

**Build:** A timeline panel for the History tab: each revision as
a point on a horizontal axis, colored by author, hoverable for
the revision's word count and delta. ~1 day.

**Why it matters:** Anderson says "the temporal aspect is addressed
only in task management; the temporal arc of the note's CONTENT is
ignored." Our revision compare has the data; a timeline view makes
it visible.

---

## 7. Conversation-anchored annotations (make them addressable)
**Source:** Seed §3 (Conversations and Discussions — "argumentative
discussions directly anchored to content... participants must
justify their arguments in relation to the referenced content")

**Gap:** Our annotations are private/public comments on char
ranges, but they're not ADDRESSABLE — you can't link TO an
annotation or transclude from one.

**Build:** Give annotations stable IDs; add a link type or wire op
that links to an annotation as a work-like target. ~1 day.

**Why it matters:** Seed treats conversations as "first-class units
of information, on par with document paragraphs." Our annotations
are one step away.

---

## PRIORITY ORDER (by paper-alignment × effort)

| # | Enhancement | Effort | Unblocks |
|---|---|---|---|
| 1 | author_type wiring | 2h | H(G) Q4 measurement; disclosure report |
| 2 | daily narrative history | 4h | Millard's attribution-drift hedge |
| 3 | maturity model | 3h | Visible docuverse growth; H(G) γ proxy |
| 4 | PROV/RDF export | 6h | Linked Data bridge; corpus for H(G) team |
| 5 | document forking | 1d | Seed alignment; debate corpus branching |
| 6 | timeline view | 1d | Anderson's temporal gap |
| 7 | addressable annotations | 1d | Seed's conversation-as-first-class |

Total: ~4 days for items 1-4 (the paper-alignment items);
items 5-7 are system-evolution items.
