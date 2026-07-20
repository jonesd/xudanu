# Versioning and Revision Addressing — Design Document

> Foundational decision record: how Xudanu captures, stores, addresses,
> and exposes revisions of a work over time. Affects FR-18 (Timeline
> lens, version diffing, "cite this revision"), FR-14 (space algebra
> over revisions), and the persistence layer (FR-17).

## Decision Question

When a Xudanu work is edited over months and years, what does it mean
to "look at" or "link to" or "diff" a past state of that work — and
how is that past state addressed, stored, and discovered?

The answer shapes:
- Whether links to a work are durable across edits (Xanadu's #1 rule)
- Whether readers can see how ideas evolved
- Whether authors can cite a specific revision
- Whether the Timeline lens in FR-18 has anything to show
- How much disk we burn on history

## Background: What We Have Now

Xudanu today (v0.9.6) has:

- **Works** — content-addressed by `WorkId` (a tumbler). One work = one
  current state.
- **Edits** — CRDT operations (insert/delete) flow through the live
  O-tree. On checkpoint, the work's edition is serialized to a new set
  of chunks; the manifest's `WorkEntry` is updated to point at the new
  root chunk hash. Old chunks remain on disk (content-addressed) but
  aren't referenced by the manifest.
- **WAL** — short-lived write-ahead log, truncated on checkpoint. Not
  a history.
- **No revisions exposed** — there's no UI or API to view, list, or
  cite a past state. Each checkpoint silently orphans the previous one.
- **Per-span attribution** — authorship is tracked at the character
  level via `attribution_log`. This survives edits (span migration via
  `Mapping`) but doesn't constitute a revision history.
- **CRDT op stream** — `OtreeCrdtManager` receives ops in real time
  from collaborators but doesn't persist them beyond the WAL.

So today: editing works, but history is silently discarded.

## What We Need (Use Cases)

### Primary use cases (must support)

1. **Cite a specific revision.** Author A writes work W in 2024. Author
   B wants to cite "W as it was on 2024-03-15" so that the citation
   stays accurate even as W evolves. The citation must be a stable
   address.

2. **View revision history.** Reader opens work W and sees a timeline
   of notable revisions: when, by whom, what changed.

3. **Diff two revisions.** Reviewer wants to see exactly what changed
   between v22 and v23 of work W.

4. **Roll back.** Author wants to revert W to its state at revision R,
   creating a new revision that equals R's content.

### Secondary use cases (nice to support)

5. **Branch / fork.** Author wants to create work W' as a fork of W at
   revision R, then evolve W' independently.

6. **Trail through revisions.** Curator wants to build a Memex-style
   trail that visits revision R1 of W1, then R5 of W2, etc., telling a
   story about how ideas evolved.

7. **Audit / accountability.** "Who changed this paragraph, and when?"

8. **Transclusion across revisions.** Work A transcludes a span from
   work B. Should the transclusion follow B's latest revision, or pin
   to B's revision at transclusion time?

### Non-use cases (explicitly out of scope)

- **Real-time merge conflicts.** Xudanu uses a CRDT; concurrent edits
  converge without conflict. Branches don't need 3-way merge.
- **Cryptographic provenance of every keystroke.** The CRDT op stream
  could provide this, but it's not the revision model. (See
  Approach B for why we don't lean on it.)

## Approaches Considered

### Approach A: Status Quo (No Revisions)

Keep current behavior. Each checkpoint silently orphans the previous
state. Old chunks stay on disk but aren't addressable.

- **Pro:** Zero work. Editing performance unchanged.
- **Con:** Fails every primary use case.
- **Verdict:** Rejected. Doesn't meet requirements.

### Approach B: Internal CRDT Log

Persist every CRDT operation to disk as an append-only log per work.
To reconstruct the work at time T, replay ops from creation to T.

```
work.5.3/
  oplog/
    0000000001.postcard   # op: insert "Hello" at 0
    0000000002.postcard   # op: insert " world" at 5
    0000000003.postcard   # op: delete 0..1
    ...
  manifest.json
```

A revision is "the state derived from the first N ops".

- **Pro:** Captures every edit. Perfect audit trail. Reconstruct any
  past state, no matter how small the change.
- **Con:** Storage grows with edit count, not revision count. A
  10 KB doc with 10,000 keystrokes burns ~200 KB of op log even
  though it's "10 KB of content".
- **Con:** Reconstructing old states is O(N) in op count. Showing the
  Timeline lens requires materializing snapshots or accepting slow
  replay.
- **Con:** No stable addresses. You can compute "state at op 5,432"
  but there's no first-class tumbler for it. Linking to "this
  revision" requires inventing an addressing scheme on top.
- **Con:** Privacy. Every typo, deleted paragraph, and private draft
  is permanently recorded. Author can't "save revision" without also
  saving the embarrassing draft they were editing in between.
- **Con:** Doesn't match Xanadu's "everything is an addressable work"
  model. The log is an audit artifact, not a docuverse citizen.
- **Verdict:** Rejected as the primary model. Useful as an
  **implementation detail** for live session recovery (which we
  already have via WAL), not as the revision model.

### Approach C: Memex-Style First-Class Revisions

Every revision is a first-class addressable entity with its own
tumbler. Revisions are created explicitly (or on a cadence) and form
a linear chain (v1 → v2 → v3 → …). A revision is immutable once
minted.

```
Work W (mutable, current state)
  ├── revision R1  (tumbler: server.5.3.1)
  │     created: 2024-01-15
  │     by: ted
  │     parent: (none)
  │     content_hash: blake3:...
  │     manifest_hash: blake3:...
  ├── revision R2  (tumbler: server.5.3.2)
  │     created: 2024-03-15
  │     by: ted
  │     parent: R1
  │     description: "Added section on transclusion"
  │     content_hash: blake3:...
  └── revision R3  (tumbler: server.5.3.3)
        created: 2024-06-01
        by: andrew
        parent: R2
        description: "Fixed typos, expanded conclusion"
        content_hash: blake3:...

W.current → R3 (the "tip" of the chain)
```

A tumbler for a revision looks like `server.5.3.3` where:
- `5.3` is the work's tumbler path
- `.3` is the revision number within the work

Citing a specific revision: `xan://alice.example.com.5.3.2` always
resolves to R2's content, forever, even as W continues to evolve.

- **Pro:** Matches Xanadu's core philosophy — every meaningful state is
  an addressable, linkable work.
- **Pro:** Unbreakable links to past states. A citation made in 2024
  is still valid in 2030.
- **Pro:** Cheap to render history — just list the revisions.
- **Pro:** Cheap to diff — diff two manifest roots (we already have
  `work_diff_regions`).
- **Pro:** Cheap to store per FR-17 — snapshots are 10–20× smaller
  than enfilades for the current version. Revisions don't change that
  math until ~80–90 revisions per work, which is rare.
- **Pro:** Privacy-respecting — author chooses when to "save revision".
  Drafts in between are not preserved.
- **Pro:** Trail-friendly — a trail can cite `xan://alice.5.3.2` and
  `xan://bob.7.1.4` as stops, mixing works and revisions freely.
- **Con:** Requires explicit authorial action (or cadence). Not every
  edit becomes a revision.
- **Con:** Storage grows linearly with revision count. Manageable per
  FR-17, but not free.
- **Con:** Branching (use case 5) is awkward in a linear chain. Needs
  extension.
- **Verdict:** **Recommended.** See Recommendation below.

### Approach D: Gold/Udanax Deep Versioning (Enfilades)

Replace snapshot storage with enfilade-based deep versioning as used
in Udanax Gold. Each edit creates a new path through a structurally
shared tree; old versions stay alive by virtue of being reachable
from the canopy.

- **Pro:** All versions are inherently live — no explicit save needed.
- **Pro:** Structural sharing makes many revisions cheap to store.
- **Pro:** Matches the original Xanadu implementation.
- **Con:** Per FR-17, structural sharing only wins after ~80–90
  revisions for small docs, ~30–50 for large. Most works won't hit
  that.
- **Con:** Massive implementation effort. We'd be rebuilding the
  edition layer from scratch.
- **Con:** Each revision still needs metadata (date, author,
  description) — same as Approach C — so the versioning UI doesn't
  get simpler.
- **Verdict:** Rejected for now. Revisit if/when real users hit the
  crossover (FR-17 says wait). Approach C is forward-compatible: if
  we later add enfilades, revisions can be backed by them
  transparently.

### Approach E: Git-Style Branches

First-class branches with merges. Each work has a `main` branch and
any number of feature branches. Revisions are commits; branches can
merge.

- **Pro:** Powerful for parallel exploration. Supports use case 5
  (fork) cleanly.
- **Pro:** Familiar to developers.
- **Con:** Overkill for typical hypertext authoring. Most works don't
  need branches.
- **Con:** Merge conflicts are exactly what CRDTs are designed to
  eliminate. Adding git-style merges reintroduces them.
- **Con:** Complex UI — most authors would never touch a branch.
- **Verdict:** Rejected as the primary model. Fork (use case 5) is
  better served by "create new work from revision R" — a one-shot
  copy, not a live branch.

### Approach F: Hybrid — Memex Revisions + Live CRDT Window

Approach C for saved revisions, plus a short rolling window of CRDT
ops (last hour or last N edits) for "undo" semantics within the
current session.

- **Pro:** Authors get explicit revisions for citation/history.
- **Pro:** Authors also get fine-grained undo for "I deleted this
  paragraph 10 minutes ago, get it back".
- **Pro:** The two systems have different jobs and don't conflict.
- **Con:** Two storage systems, two mental models. Slightly more
  complexity.
- **Verdict:** **Recommended as future extension of C.** Ship C
  first; add the live CRDT window if undo requests come in.

## Comparison Matrix

| Approach | Stable addresses | Storage cost | Privacy | Branch | Implementation effort | Matches Xanadu |
|---|---|---|---|---|---|---|
| A. Status quo | ❌ | zero | n/a | ❌ | zero | partial |
| B. CRDT log | derived only | high (per op) | poor | ❌ | medium | ❌ |
| **C. Memex revisions** | **✅ first-class** | **low (per revision)** | **good** | **via fork** | **medium** | **✅** |
| D. Enfilades | ✅ | low (shared) | depends | ✅ | very high | ✅ |
| E. Git branches | ✅ | low | good | ✅ | high | ❌ |
| F. C + CRDT window | ✅ | low + small | good | via fork | medium-high | ✅ |

## Recommendation: Approach C, Followed by Approach F

Adopt Approach C as the primary model in v1. Revisions are first-class
addressable entities with stable tumblers. Revisions are minted
explicitly by authors (and optionally on a cadence as a convenience).

Once C is shipped and stable, layer Approach F on top: add a rolling
CRDT op window for fine-grained session undo. This is a **planned
two-phase rollout**, not "maybe someday":

- **Phase A (C):** First-class revisions with stable tumblers. This
  is what the FR-18 Timeline lens depends on. Ships first.
- **Phase B (F):** Live CRDT undo window — last hour or last N edits
  available for "undo this paragraph from 10 minutes ago" without
  minting a full revision. Ships after C is stable in production.

The two systems serve different jobs and don't conflict:

| Need | Served by |
|---|---|
| Cite a specific state forever | C (revision with stable tumbler) |
| See history of important changes | C (revision timeline) |
| Diff two saved states | C (revision diff) |
| "I deleted this 10 minutes ago, get it back" | F (CRDT op window) |
| "Show me every keystroke for audit" | F (extended CRDT log) |

### Why C over the alternatives

1. **Stable addresses are the Xanadu contract.** Ted Nelson's #1 rule
   is that links never break. If I cite your work today, that citation
   must still resolve in 20 years. Without first-class revision
   tumblers, citations to "the current state" break every time the
   author edits. Approach C is the only option (besides D) that
   delivers this.
2. **Privacy and editorial control.** Authors should decide which
   states of their work are "saved" vs "drafts in progress". Approach
   B preserves everything (privacy-hostile); Approach C preserves
   what the author marks (editorial control).
3. **Storage cost is acceptable.** FR-17 says snapshots are 10–20×
   cheaper than enfilades until ~80–90 revisions. Most works won't
   approach that. When they do, we can swap the storage backing
   without changing the revision model.
4. **Simpler than enfilades by an order of magnitude.** Approach D is
   a multi-month project that rewrites the edition layer. Approach C
   is a metadata index on top of storage we already have.
5. **Forward-compatible.** If we later adopt enfilades (D), the
   revision model from C survives unchanged. Revisions are an
   addressing scheme, not a storage scheme.
6. **Path to F is incremental.** Phase B (live CRDT window) builds on
   the same op stream we already persist for the WAL. Extending it to
   a longer retention window is a tunable, not a redesign.

## Data Model

### Revision entity

A new persisted entity alongside works. Stored in the manifest's
`RevisionsSection` (a new section parallel to `SocialSection`).

```rust
pub struct RevisionEntry {
    pub revision_id: u32,              // sequential within the work
    pub work_id: WorkId,               // the parent work
    pub parent_revision: Option<u32>,  // previous revision (linear chain)
    pub created_at: DateTime<Utc>,
    pub created_by: IdentityId,
    pub description: Option<String>,   // optional commit message
    pub manifest_hash: Hash,           // points at the edition's root chunk
    pub content_hash: Hash,            // BLAKE3 of canonical text (for dedup)
    pub is_notable: bool,              // for Timeline lens filtering
    pub tags: Vec<String>,             // e.g. ["published", "retracted"]
}

pub struct RevisionsSection {
    pub by_work: HashMap<WorkId, Vec<RevisionEntry>>,
}
```

### Addressing

A revision's tumbler extends the parent work's tumbler with a revision
component:

```
Work W:        alice.example.com.5.3
Revision R2:   alice.example.com.5.3.2
```

`XudanuTumbler` (already in the codebase) supports arbitrary numeric
path components, so no changes to the tumbler type are needed — just
a convention.

When the resolver sees a tumbler with N+1 path components where the
first N match a work and the (N+1)th is a valid revision id, it
returns the revision's content instead of the work's current state.

### Wire protocol additions

New WebSocket ops:

```
0x0901  WorkRevisionsList(work_id) -> Vec<RevisionSummary>
0x0902  WorkRevisionAt(work_id, revision_id) -> Edition payload
0x0903  WorkRevisionDiff(work_id, rev_a, rev_b) -> DiffPayload
0x0904  WorkRevisionCreate(work_id, description) -> RevisionId
0x0905  WorkRevisionRollback(work_id, target_revision_id) -> RevisionId
```

`RevisionSummary` includes `id, parent, created_at, created_by,
description, is_notable, content_hash`. The full edition payload is
fetched on demand via `WorkRevisionAt`.

### Storage cost

Each revision stores:
- One `RevisionEntry`: ~150 bytes (mostly hashes + timestamp)
- One edition snapshot (chunks): same as current snapshot cost
  (~10–20% overhead per FR-17 for distinct revisions)

For a typical work with 10 revisions of a 10 KB document:
- 10 × ~12 KB = ~120 KB (vs 10 KB for current-only)
- 12× overhead at 10 revisions; still well under the 80–90 crossover

This is the right tradeoff: we're paying for **addressability**, not
for **structural efficiency**.

### Snapshot reuse

Adjacent revisions often share most content. Two optimizations,
both optional:

1. **Chunk-level dedup is free** — BLAKE3 content addressing already
   gives us this. If revision R2 reuses 9 of R1's 10 chunks, only the
   changed chunk is stored.
2. **Delta storage** — store R2 as "R1 + delta" instead of full
   snapshot. Saves space but complicates random access. Defer until
   real users hit cost pressure (FR-17 decision: wait).

## When Are Revisions Minted?

Three modes, all configurable per work:

### Mode 1: Explicit (default)

Author clicks **Save Revision** in the UI, optionally with a
description. A new revision is minted.

- Best for: curated works, scholarly publishing
- Cost: lowest storage
- Risk: authors forget, lose intermediate states

### Mode 2: Cadence

Server mints a revision every N minutes while the work is being
actively edited, or every N edits. Like autosave, but a snapshot.

- Best for: collaborative works, draft-heavy writing
- Cost: moderate storage
- Risk: noisy history (many small revisions)

### Mode 3: Publish-gated

A revision is minted only when the author publishes. Between
publishes, edits accumulate in the live state but no revisions are
captured.

- Best for: works with clear publishing events (essays, articles)
- Cost: lowest storage
- Risk: catastrophic if author publishes rarely — long gaps with no
  history

### Recommendation

**Default: Mode 1 (explicit)** with **Mode 2 (cadence) opt-in**. Mode
3 is a special case of Mode 1 (publish action = explicit save).

The UI offers "Save Revision" prominently in Compose mode. Authors
who want cadence can enable it in work settings.

## "Notable" Revisions

The Timeline lens (FR-18 Phase 5) wants to show "important" revisions,
not every autosave. How does a revision become notable?

Three signals, in priority order:

1. **Manual mark** — author flags a revision as notable ("this is the
   v1.0 release"). Stored as `is_notable: true` in `RevisionEntry`.
2. **Publish event** — any revision created by a publish action is
   notable by default.
3. **Size threshold** — if a revision changes > X% of the content or
   > Y bytes, the server auto-marks it notable. Configurable; default
   X=20%, Y=500 bytes.

The Timeline lens shows notable revisions by default; a toggle reveals
all.

## Branching (Use Case 5)

Branches are not in v1. Instead, **fork** is:

> "Fork revision R of work W" creates a new work W' whose initial
> content equals W at R, and whose provenance records W.R as the
> source.

This gives us 90% of branching value at 10% of the complexity:

- The fork is a first-class work (its own tumbler, own history)
- The fork can be edited independently
- The fork's provenance chain includes W.R (so "Origins View" in
  FR-18 connects them)
- No merge conflicts (Xudanu is CRDT-based; forking doesn't create a
  branch relationship that needs merging)

If a user later wants to merge changes back, they can manually
transclude passages from W' into W. This is more in line with how
Xanadu thinks about reuse than git-style merging.

## Cross-Revision Transclusion (Use Case 8)

When work A transcludes a span from work B, which revision of B does
it see?

Two modes, configurable per transclusion:

- **Floating** (default): follows B's current state. If B is edited,
  the transclusion updates. Span migration (`Mapping`) keeps the
  transclusion alive across edits.
- **Pinned**: targets a specific revision of B (`xan://bob.7.1.4`).
  The transclusion shows the same content forever.

Pinned transclusions are made by citing a revision tumbler instead of
a work tumbler. The resolver handles the difference transparently.

UI: when creating a transclusion, a small dropdown offers "Latest" or
"Specific revision…". If specific, pick from B's revision list.

## Rollback (Use Case 4)

To roll back work W to revision R:

1. Author invokes "Roll back to R" action.
2. Server reads R's edition.
3. Server creates a new revision R' whose content equals R, with
   `description: "Rolled back to R"`, `parent: current_tip`.
4. Server updates `W.current` to point at R'.
5. R' is now the tip; history is preserved (R, R+1, R+2, …, R' all
   still exist).

Rollback is non-destructive. The revisions between R and the previous
tip remain in the timeline; they're just not the current state.

## Audit / Accountability (Use Case 7)

Per-span attribution (already in the codebase via `attribution_log`)
answers "who wrote this paragraph?". Revisions answer "when did this
paragraph appear, and in which revision?".

Combined: the Timeline lens can show, for any paragraph in the current
state, the revision in which it was introduced and the author who
introduced it. This is more precise than "who has edited this work"
and more useful for scholarly citation.

## Migration & Coexistence

### Existing works

Existing works have no revisions. The first time an author clicks
"Save Revision" on such a work, revision R1 is minted from the current
state. Future revisions build on R1.

If the author never saves a revision, the work continues to function
exactly as today. No data migration required.

### Backward compatibility

- Old clients (pre-revision) ignore the new `RevisionsSection` in the
  manifest. They see the work's current state.
- New clients can read works from old servers; they just see no
  revision history.
- The wire ops are additive (new opcodes 0x0901–0x0905); no existing
  ops change.

### Server-side implementation order

1. Add `RevisionsSection` to manifest (schema bump)
2. Add `WorkRevisionCreate` op
3. Add `WorkRevisionsList`, `WorkRevisionAt` ops
4. Add `WorkRevisionDiff`, `WorkRevisionRollback` ops
5. Expose in UI (FR-18 Phase 5: Timeline lens)

Each step is independently shippable. Steps 1–4 are backend-only and
can ship before any UI consumes them.

### Phase B (F) implementation

After Phase A is stable, add the live CRDT undo window:

1. Extend WAL retention from "truncated on checkpoint" to "rolling
   window of last N ops or last M minutes" (configurable per work,
   default N=10,000 ops or M=60 minutes).
2. Add wire ops for op log queries:
   - `0x0910  WorkOpLogSlice(work_id, from_op_id, count)` — for
     paginated history browsing.
   - `0x0911  WorkReconstructAt(work_id, op_id)` — materialize the
     work's state at a given op, without minting a revision.
3. UI: an "Undo History" panel in Compose mode showing recent ops,
   grouped by time/author. Selecting an op previews the state at that
   op; "Restore this state" prompts to either roll back (no revision)
   or save as a new revision.
4. Op log is **session-scoped**, not revision-scoped. Rolling the log
   doesn't affect revisions. The two systems are independent.

Phase B is **opt-in per work**. Authors who don't want fine-grained
history keep the default (WAL truncated on checkpoint, no op log
retention).

### When to start Phase B

Trigger: after Phase A has been in production for at least one
release cycle, AND at least one of:
- Users request "I want to undo something from before my last saved
  revision"
- Collaborative editing sessions lose data due to revision boundaries
  being too coarse
- Audit/compliance use cases emerge that need per-op provenance

If none of these triggers fire, Phase B can stay deferred
indefinitely — Phase A is sufficient for the primary use cases.

## Ties to Other Features

| Feature | Dependency on this design |
|---|---|
| **FR-18 Timeline lens** | Hard. The Timeline lens has nothing to show without revisions. |
| **FR-18 Diff lens** | Soft. Can diff current state against an arbitrary work today; revision diff is a special case. |
| **FR-18 Origins lens** | Soft. Uses provenance chain (already shipped); revisions make the chain richer. |
| **FR-14 Space algebra** | Soft. Revisions are natural inputs to `XnRegion::delta` and `Mapping::transformed_by`. Already supported. |
| **FR-17 Storage** | Soft. Revisions use existing chunk storage; no change to snapshot strategy. |
| **Cite a revision** (FR-18 Cite action) | Hard. Without revision tumblers, citations are to "current state" and break on edit. |
| **Persistent ID display** (FR-18 metadata strip) | Soft. Showing `xan://…` today; will show `xan://….3` for pinned revisions later. |

## Open Questions

1. **Revision numbering scheme.** Sequential integers (`1, 2, 3…`) or
   content-hash-based or timestamp-based? Sequential is most
   human-readable; hash-based enables dedup; timestamp-based enables
   natural ordering. **Recommend: sequential integers**, with
   timestamps and hashes as metadata.

2. **Who can mint a revision?** Anyone with edit access? Only the
   owner? Anyone, but owner-curated? **Recommend: anyone with edit
   access**, with the owner's revisions auto-marked as notable.

3. **Pruning.** Should old revisions ever be deleted? If so, by whom,
   and what happens to links pointing at them? **Recommend: revisions
   are immutable once minted; never auto-deleted.** Manual deletion by
   owner is allowed but warns about breaking citations.

4. **Cross-server revisions.** If `xan://alice.5.3.2` is cited from
   Bob's server, does Bob cache the revision? For how long? **Recommend:
   yes, indefinitely, with content-hash verification** (same as
   cross-server work caching).

5. **Revision discovery.** How does a client list revisions of a work
   on another server? New well-known endpoint? Part of
   `/api/public/work/{id}`? **Recommend: extend the public work API
   to include a revisions array.**

6. **Diff algorithm.** Already have `work_diff_regions` and
   `find_content_shared_regions`. Are these sufficient for revision
   diff, or do we need a dedicated revision-diff that knows about
   paragraph-level structure? **Recommend: start with existing; revisit
   if users want paragraph-aware diffs.**

7. **Multi-work revision groups.** Should "publish" ever mint
   revisions across multiple works atomically (e.g., publishing a
   collection and all its entries)? **Recommend: no in v1.** Each work
   has its own revision timeline.

## Success Criteria

- An author can save a revision of their work with a description, and
  that revision is addressable forever via a stable tumbler.
- A reader can view the timeline of revisions for any work, with
  notable revisions highlighted.
- A reader can diff any two revisions of a work and see character-level
  changes.
- A citation to `xan://alice.5.3.2` resolves to the same content in
  2024 and 2034, regardless of how work 5.3 evolves.
- An author can roll back to a previous revision without losing
  history.
- A reader can pin a transclusion to a specific revision, and that
  transclusion never changes.

## References

- `docs/dev/FR-17.md` — Storage architecture (snapshot vs enfilade
  trade-off; crossover at ~80–90 revisions)
- `docs/dev/FR-18.md` — Workspace design (Timeline lens depends on
  this doc)
- `docs/dev/FR-14.md` — Space algebra (provides the diff/region
  primitives revisions build on)
- `src/edition/tumbler.rs` — `XudanuTumbler` type (already supports
  the path components needed for revision addressing)
- `src/edition/three_way.rs` — `ThreeWayDiff` (used for revision diff)
- Vannevar Bush, *"As We May Think"* (1945) — Memex concept of trails
  through documents
- Ted Nelson, *Literary Machines* (1980) — original Xanadu versioning
  model
- Udanax Gold source — enfilade/canopy implementation reference
