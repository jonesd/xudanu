# FR-20: Trails — The Unified Span Grouping Primitive

> **Reframing:** What I originally sketched as a "SpanSet" entity is
> already implemented in Xudanu as **Trails**. This doc reframes
> the user's reviewer-focus use case as a Trail extension problem,
> identifies what's missing for full span-set semantics, and
> unifies several Xanadu concepts (trails, span clusters, focus
> blocks, citation groups) under one well-understood primitive.

## Decision Question

How does Xudanu represent a curated collection of spans — perhaps
all on one work (for review focus), perhaps across multiple works
(for a reading order), perhaps across servers (for a Xanadu-grade
network trail) — as a single addressable, shareable, citable
entity?

The answer shapes:
- Whether we invent a new primitive or extend what we have
- How FR-19 (Marginalia) defines focus blocks
- How reviewers, readers, and authors navigate grouped selections
- How citation clusters work in scholarly use

## Decision

**Use Trails as the single unified primitive.** Trails already
exist in Xudanu (`trail_list`, `trail_get`, `TrailPayload`,
`TrailsPanel` UI). They support:

- ✅ Multiple stops on the same work (the user's "review focus" case)
- ✅ Stops across multiple works (the traditional Xanadu trail case)
- ✅ Per-stop notes
- ✅ Ordering (stops array is ordered)
- ✅ Categorization (categories field)
- ✅ Publishing (published flag)
- ✅ Ownership (owner_club)
- ✅ Owner-curated discover feed (`trail_list_published`)

What's missing for full span-set semantics:
- ❌ Per-stop label (only has `note`)
- ❌ Per-stop priority / type
- ❌ Per-stop assignment (for review)
- ❌ Cross-server stops (no `cross_server_ref` field)
- ❌ Tight Marginalia integration (focus blocks should be trails)
- ❌ Workspace UI integration (currently opens as a modal panel)
- ❌ Span migration (stops don't currently migrate with edits)

**Recommendation: extend Trails, don't invent something new.** Add
the missing fields, wire up Marginalia, integrate into the
workspace, implement span migration. ~1–2 weeks of focused work.

## What We Already Have

### Data model

```typescript
// Already in api/crdt_sync.ts
interface TrailStop {
  work_id: number;
  char_start?: number;
  char_end?: number;
  note?: string;
  title: string;  // snapshot of the work title at time of stop
}

interface TrailPayload {
  trail_id: number;
  name: string;
  introduction?: string;
  categories?: string[];
  published?: boolean;
  owner_club: number;
  stops: TrailStop[];
  created_at: number;
  updated_at: number;
}
```

### Wire ops (existing)

- `trail_list` — list trails owned by current identity
- `trail_get` — fetch a specific trail by ID
- `trail_list_published` — browse published trails (with optional category filter)
- Plus unlisted ops for create/update/delete (need to grep)

### UI

- `TrailsPanel.tsx` — full management UI with two tabs (Mine / Discover)
- Modal-style panel; not yet integrated into the workspace shell

## What's Missing — and Why It Matters

### 1. Per-stop label and priority

Current `TrailStop` has only `note`. For review focus use cases, we want:

```typescript
interface TrailStop {
  // ...existing fields...
  label?: string;        // short title for the stop ("Spelling issue")
  priority?: number;     // 1=high, 2=med, 3=low
  type?: StopType;        // what kind of stop
}

type StopType =
  | "review"       // author wants reviewer to look here
  | "comment"      // a comment about this passage
  | "citation"     // citing this passage from elsewhere
  | "evidence"     // supporting evidence for a claim
  | "contrast"     // contrast with another passage
  | "default";     // generic
```

**Effort:** Half a day (additive fields; no migration).

### 2. Per-stop assignment (for review)

For multi-reviewer workflows, assign each stop to a specific reviewer:

```typescript
interface TrailStop {
  // ...existing fields...
  assigned_to?: number;  // IdentityId
  resolved?: boolean;    // for tracking review progress
  resolved_at?: number;
  resolved_by?: number;
}
```

**Effort:** Half a day.

### 3. Cross-server stops

The big one for the Xanadu purists. A stop should be able to point
at a passage on a different Xudanu server:

```typescript
interface TrailStop {
  // ...existing fields...
  cross_server_ref?: {
    server: string;        // domain
    content_hash: string;  // BLAKE3 of the work's content
    work_id: number;       // work ID on the remote server
  };
}
```

When resolving a cross-server stop, the server fetches the remote
work (if not already cached) and looks up the span by hash-verified
content.

**Effort:** 2–3 days (uses existing `CrossServerRef` infrastructure
from FR-6).

### 4. Span migration for stops

Today, when a work is edited, trail stops don't migrate — they
continue to point at the original character offsets, which may now
be wrong. We need stops to migrate via `Mapping` (FR-14):

```rust
// On edit, for each trail stop on this work:
let new_start = mapping.transformed_by(stop.char_start);
let new_end = mapping.transformed_by(stop.char_end);
if new_start != stop.char_start || new_end != stop.char_end {
    update_stop(stop.id, new_start, new_end);
}
```

This is the same mechanism used for transclusion and link spans.
The infrastructure exists; we just need to call it for trails.

**Effort:** 1 day.

### 5. Marginalia (FR-19) integration

FR-19 currently invents `FocusBlock` as a separate concept. It
should use Trails instead:

```typescript
// Instead of:
interface FocusBlock {
  start_char: u64;
  end_char: u64;
  label: Option<String>;
  assigned_reviewer: Option<IdentityId>;
}

// Use a Trail:
interface ReviewFocusSet {
  trail_id: TrailId;  // a Trail owned by the author, scoped to this work
}

// The Trail's stops are the focus blocks.
// Each stop has a label, note, priority, assigned_to.
```

Benefits:
- No new entity to maintain
- Focus sets are first-class works (citeable, shareable)
- Same UI patterns work for "review focus" and "reading trail"
- Reviewers can navigate stops via standard trail UI

**Effort:** 1 day to update FR-19; 2 days to wire up.

### 6. Workspace UI integration

Trails currently open as a modal panel. They should be:

- **Authorable from selection:** select text → "Add to trail" → pick which trail (or create new)
- **Navigable in the right panel:** a "Trails" tab showing all trails that touch the current work, with next/prev navigation
- **Visualized in the document:** stops on the current work shown as margin markers (similar to link markers)
- **Discoverable:** a "Trails" tab in the bottom lens row (when we re-add it) showing trails that include the current work as a stop

**Effort:** 3–4 days.

## Use Cases (Single Primitive, Many Uses)

Trails unify several Xanadu concepts under one entity:

| Use case | Trail variant |
|---|---|
| **Review focus set** | Single-work trail; per-stop notes for reviewer |
| **Citation cluster** | Single-work trail; stops are the cited passages; cite the trail as a whole |
| **Editorial marks** | Single-work trail; editor's marks for author to address |
| **Personal highlights** | Single-work trail; reader's own highlights/notes |
| **Reading order** | Multi-work trail; ordered stops through related works |
| **Syllabus / reading list** | Multi-work trail; published; categorized by topic |
| **Workshop critique** | Multi-work trail; one trail per workshop session |
| **Quote collection** | Multi-work trail; stops are quoted passages |
| **Trail of evidence** | Multi-work trail; legal/research use |
| **Bibliography with excerpts** | Multi-work trail; each stop includes the actual cited passage |
| **Cross-server citation** | Multi-server trail; stops reference remote works |
| **Curated tour** | Published trail; designed for readers to follow in order |

Twelve distinct use cases, one primitive. That's the leverage of
getting the abstraction right.

## Author UX

### Creating a trail from selection

1. Author selects text in a work
2. Selection popover offers "Add to trail…" (alongside existing Link/Transclude/Note)
3. Author picks an existing trail (or "New trail…")
4. Stop is appended with default metadata
5. Author can edit the stop's label/note/priority in the trail panel

### Trail management panel

In the workspace right panel, a new "Trails" tab lists all trails
that touch the current work. Each trail is expandable to show its
stops. Clicking a stop jumps to it.

For the author's own trails, full CRUD UI:
- Rename trail
- Edit introduction/description
- Add/remove/reorder stops
- Set per-stop label, note, priority, type
- Assign stops to reviewers (if integrated with Marginalia)
- Publish/unpublish

### Trail-following UI

For a reader or reviewer following a trail:

- Top of document shows trail context: "Trail: *Key passages on
  transclusion* · Stop 3 of 7"
- Previous / Next buttons jump between stops
- Each stop's note appears in the margin alongside the highlighted span
- Progress indicator (3/7 stops visited)

## Reviewer UX (via Marginalia)

When a reviewer opens a Marginalia link that includes a focus
trail:

1. Document loads with all trail stops highlighted
2. Right panel shows the trail's stops with the author's per-stop notes
3. Reviewer clicks a stop → jumps to it
4. Reviewer leaves typed feedback on the stop (creates a typed link)
5. Reviewer can resolve stops (marks progress)
6. Reviewer can navigate via next/prev

This is the user's original use case: "check ¶14, sentences 19–21,
spelling of word X" — each becomes a trail stop with its own note.

## Data Model (Unified)

```typescript
interface Trail {
  trail_id: number;
  name: string;
  description?: string;       // was: introduction
  categories?: string[];
  published?: boolean;
  owner_club: number;
  created_at: number;
  updated_at: number;
  stops: TrailStop[];
}

interface TrailStop {
  stop_id: number;            // NEW: stable ID for migration
  order: number;              // NEW: explicit ordering
  work_id: number;
  char_start?: number;
  char_end?: number;
  title: string;              // snapshot of work title
  note?: string;              // free-form note
  label?: string;             // NEW: short title
  priority?: number;          // NEW: 1=high, 2=med, 3=low
  type?: StopType;            // NEW: review/comment/citation/evidence/contrast
  assigned_to?: number;       // NEW: IdentityId
  resolved?: boolean;         // NEW: for review tracking
  cross_server_ref?: {        // NEW: for cross-server stops
    server: string;
    content_hash: string;
    work_id: number;
  };
}
```

## Wire Ops

Existing:
- `trail_list`
- `trail_get`
- `trail_list_published`
- (create/update/delete ops — confirm what's already there)

New / extended:
- `trail_stop_add(trail_id, work_id, char_start, char_end, label?, note?, type?, priority?)` → stop_id
- `trail_stop_update(stop_id, fields...)` → void
- `trail_stop_remove(stop_id)` → void
- `trail_stop_reorder(trail_id, stop_id_order[])` → void
- `trail_assign_stop(stop_id, identity_id)` → void
- `trail_resolve_stop(stop_id, resolved: bool)` → void
- `trail_get_for_work(work_id)` → Vec<Trail> (all trails touching this work)
- `trail_migrate_stops(work_id, mapping)` → void (called on edit; updates stop offsets)

## Implementation Phases

### Phase 1: Extend TrailStop schema (1–2 days)

- Add `label`, `priority`, `type`, `assigned_to`, `resolved` fields
- Add `stop_id` and explicit `order`
- Backend persistence; wire ops
- Backward compat: old fields stay; new fields optional

### Phase 2: Span migration for stops (1 day)

- On every edit, call `Mapping::transformed_by` for each affected stop
- Update offsets in storage
- Test: edit a work, verify trail stops follow their content

### Phase 3: Workspace UI integration (3–4 days)

- Right panel "Trails" tab
- "Add to trail" in selection popover
- Trail management panel (CRUD)
- Stop navigation (next/prev, jump to stop)

### Phase 4: Marginalia integration (1–2 days)

- Update FR-19 to use Trails for focus blocks
- Review link can include one or more trail IDs
- Reviewer UI loads the trail and shows stops as highlighted spans

### Phase 5: Cross-server stops (2–3 days)

- Add `cross_server_ref` field
- Resolution uses existing `CrossServerRef` infrastructure (FR-6)
- Cache remote works, verify via BLAKE3
- Test: trail with stops across two Xudanu servers

### Phase 6: Trail-following UI (1–2 days)

- Top-of-document trail context bar
- Previous/Next navigation
- Progress indicator
- Margin notes per stop

**Total: ~2 weeks for full feature.** Each phase is independently
shippable. Phases 1–3 give a usable single-work span set; Phase 4
unlocks the reviewer use case; Phase 5+6 add the Xanadu-grade
features.

## Alternatives Considered

### Alternative A: New SpanSet entity

Invent a separate `SpanSet` for the single-work case; keep Trails
for multi-work.

- **Pro:** Specialized semantics for each
- **Con:** Two entities doing similar things; users have to choose
  which to use; UI doubles in complexity
- **Verdict:** Rejected. **Trails ARE span sets** — they support
  single-work already. Don't fragment the concept.

### Alternative B: Use Compound Documents

A compound document embeds transclusions. Could we use compounds
as span clusters?

- **Pro:** Same underlying span-grouping idea
- **Con:** Compounds embed content inline; trails reference spans
  without embedding. Different semantics, different UIs.
- **Verdict:** Rejected. Compounds and trails are complementary;
  don't merge them.

### Alternative C: Use Annotations

Group annotations via a shared tag or cluster ID.

- **Pro:** No new entity
- **Con:** Annotations are span+note, not span collections. Don't
  support ordering, multi-work, cross-server, or per-stop metadata.
- **Verdict:** Rejected. Annotations are comments; trails are
  curated paths.

## Naming

**Trails** is the right term:

- Pays homage to Ted Nelson and the Xanadu tradition
- Evocative of a curated path through material (not just a set)
- Works for both single-work and multi-work cases
- Differentiates from "bookmark" (whole-doc) and "playlist" (media)
- Already in our codebase — no rename needed

Sub-concepts can use the trail metaphor:
- **Stop** — one span in a trail
- **Tour** — following a published trail as a reader
- **Trailhead** — the entry point (first stop + introduction)

## Implications for Other Features

### FR-19 (Marginalia)

Update FR-19's focus block design to use Trails:

```typescript
// Before (FR-19 draft):
interface FocusBlock {
  start_char: u64;
  end_char: u64;
  label: Option<String>;
  assigned_reviewer: Option<IdentityId>;
}

// After:
interface ReviewLink {
  // ...existing fields...
  focus_trail_id: Option<TrailId>;  // trail of stops to highlight for reviewer
}
```

Review link points at a trail. Reviewer sees all stops highlighted.
Per-stop notes from author become the focus guidance.

This is cleaner than FR-19's separate FocusBlock concept.

### Cross-server resolution

Trails with `cross_server_ref` stops use the existing
cross-server fetch infrastructure. Resolution order:

1. Local stop (work_id on this server) — direct lookup
2. Cached cross-server stop — use cache, verify hash
3. Fetch from origin server — fetch work, verify, cache, lookup span
4. Otherwise — broken citation (same as work-level cross-server)

### Versioning

Trails can reference specific revisions of works via revision
tumblers in `cross_server_ref`. A trail stop pinned to revision R
of a work points at immutable content — useful for scholarly
citation where the cited passage must never change.

## Trust and Privacy

### Trail visibility

- **Private trails:** visible only to owner (default for drafts)
- **Shared via link:** visible to anyone with the trail ID + token
- **Published:** visible to anyone on the server (in the Discover
  feed)
- **Cross-server:** published trails are listable from other
  servers via the public API

### Stop content

A trail stop references content by character span. If the
underlying work is private, can the trail stop be resolved by
someone who can't read the work?

- **Recommendation:** No. Trail stops inherit the visibility of
  the work they reference. A published trail with a stop on a
  private work shows the stop metadata (label, note) but not the
  passage content.

### Reviewer privacy

For Marginalia trails: the author sees who has been assigned to
each stop. The reviewer sees only their own assignments (unless
the author makes the trail public within the review context).

## Open Questions

1. **Trail of trails?** Can a trail contain another trail as a
   stop? Useful for "module 1 contains trails A, B, C."
   **Recommendation:** No for v1 — flat trails only. Nesting adds
   complexity; can be added later if needed.

2. **Trail versioning?** When a trail is edited (stop added /
   removed), should the old version be preserved? **Recommendation:**
   Yes — trails are works, they get the same revision treatment
   per the versioning design doc.

3. **Trail-level vs stop-level comments?** Can reviewers comment
   on the trail as a whole, or only on individual stops?
   **Recommendation:** Both. The trail is itself a work; comments
   on it are just typed links to the trail work.

4. **Trail discovery across servers?** Should there be a global
   "browse published trails" feature across servers?
   **Recommendation:** No for v1. Each server has its own Discover
   feed. Cross-server discovery is the same problem as cross-server
   content discovery (deferred per `cross-server-resolution.md`).

5. **Trail forks?** Can a reader fork a published trail to create
   their own variant? **Recommendation:** Yes, but treat as "create
   new trail from existing" — explicit copy, not git-style fork.

6. **Trail templates?** Pre-defined trail structures (e.g., "peer
   review template" with default stops for abstract, methodology,
   results, conclusion)? **Recommendation:** Yes, eventually. For
   v1, authors build trails from scratch.

## Success Criteria

- An author can create a trail by selecting passages and clicking
  "Add to trail" — total time under 10 seconds per stop.
- A reviewer opening a Marginalia link with a focus trail sees all
  stops highlighted and can navigate between them.
- Trail stops stay attached to their content across edits (no
  manual offset updating).
- A trail can be cited as a single addressable entity: `xan://server.trail_id`
- Trails work across multiple works on the same server.
- Trails work across multiple servers (with BLAKE3 verification).
- The same trail primitive serves review, citation, syllabus, and
  reading-list use cases without special-casing.

## Metrics

- Number of trails created per active user per month
- Average stops per trail (distribution)
- % of trails that are single-work vs multi-work
- % of trails published vs private
- Marginalia review links that include a focus trail (target: >50%)
- Trail-following completion rate (readers who visit all stops)

## Ties to Other Designs

| Feature | Relationship |
|---|---|
| **FR-19 Marginalia** | Focus blocks become trails; trails are the unit of review focus |
| **`versioning-design.md`** | Trails are works; they get revisions |
| **`cross-server-resolution.md`** | Cross-server stops use existing CrossServerRef |
| **FR-6 Linked servers** | Trails with cross-server stops depend on FR-6 |
| **FR-14 Space algebra** | Stop migration uses Mapping/transformed_by |
| **Compounds (existing)** | Complementary: compounds embed, trails reference |
| **Annotations (existing)** | Complementary: annotations are notes on spans; trails are paths through spans |

## References

- `web/app/src/components/TrailsPanel.tsx` — existing trail UI
- `web/app/src/api/crdt_sync.ts` — TrailPayload, TrailStop interfaces
- `src/server/transport/protocol.rs` — existing trail wire ops
- Ted Nelson, *Literary Machines* (1980) — original trail concept
- Vannevar Bush, *As We May Think* (1945) — Memex trails
- Maggie Appleton's pattern library — curated path / trail pattern
