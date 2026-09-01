# FR-52 A-1: Ent/Fulltrace Activation — Design Note

> **Status:** Design (deliverable A-1.1)
> **Created:** 2026-08-31
> **Parent:** FR-52-gold-core-adoption.md, section A-1
> **Principle:** The fulltrace is a parallel index, not a replacement.
> BeId stays the primary key; lookup equivalence is provable by
> construction.

## 1. What Gold had

Gold's server-side object root was the **Ent** (`entx.hxx:86`) — a
Shepherd patriarch owning one `DagWood fulltrace`. Three things
mattered:

1. **`newTrace()`** — every orgl (document) created on the server
   got a `TracePosition` from the fulltrace: `(branch, position)`
   where branch identifies a path through the version DAG and
   position how far along it. Identity of a document was *a place
   in the server's version history*, not a counter.
2. **Design fluids** — `CurrentTrace` and `CurrentBertCrum`
   (`entx.hxx:78-79`) — dynamic context that crum computation
   read implicitly. This was Smalltalk idiom; in Rust we pass
   context explicitly.
3. **`tableSegmentMaxSize`** (`entx.ixx:40-46`) — orgl segmentation
   policy (16,384), already ported.

The surrounding Shepherd machinery (`newShepherd`, `remember`,
Abraham hierarchy, DiskCuisine GC) was Gold's persistence and
object-management substrate. We do not adopt it — chunk store +
WAL + snapshot + Rust ownership serve those roles. What we adopt
is the **fulltrace as the server's version-history namespace**.

## 2. What we have today

- `Server` (server.rs:631) holds ~12 flat `HashMap<BeId, _>` maps:
  `works`, `clubs`, `standalone_editions`, `edition_detectors`,
  `links`, `work_to_links`, `lattice_shadows`, `starred_works`,
  `trails`, `compound_editions`, `revisions`, and more. The
  `works` map alone has 94 get/insert call sites.
- `GrandMap` is **active** (server.rs:632) — BeIds come from
  `new_work_element`/`assign_new_id`. ID allocation is solved.
- Work revisions are a `HashMap<u64, ...>` keyed by a **linear
  counter** — history is a line, not a tree. There is no fork, no
  branch visibility, no "as of" view.
- `src/ent/` (4,422 lines, 479 tests) is complete but dormant
  except DagWood trace-position allocation inside backfollow.
  `Ent::new()` and `new_trace()` exist and pass tests.

The gap is not structural — it is wiring. Nothing on the server
calls `Ent::new_trace()` when a work is created.

## 3. Design

### 3.1 The core decision: parallel index, not replacement

Replacing `HashMap<BeId, WorkState>` with fulltrace-keyed lookup
would rewrite 94 call sites to chase an ordering we don't yet
consume — pure risk, zero gain. Instead:

```
Server gains:      fulltrace: Ent
WorkState gains:   trace: TracePosition
Invariant:         works.be_id <-> fulltrace position is a bijection
```

- `create_work` allocates `fulltrace.new_trace()` and stores the
  position in `WorkState`.
- All existing lookups are untouched — they key on BeId.
- New queries key on the fulltrace and resolve to BeIds.

**Armor (A-1.P1):** restore equivalence (checkpoint → restore →
same bijection), allocation uniqueness (N creates → N distinct
positions), and the flat-map/fulltrace agreement property
(every work has a position; every position maps back to one work).

### 3.2 Phase 2: club branches — the hierarchical namespace

Gold's fulltrace gave documents a *place*. Our equivalent grouping
is the club: every club-sponsored work should live on its club's
branch.

- Boot: each club gets a root branch (`create_root` per club at
  server init; the four system clubs at server.rs:1230-1252).
- `create_work(club)` uses `new_position_after` on the club's
  branch, not the anonymous trunk.
- `works_under_club(club)` becomes `trace_view(branch).is_visible`
  — subtree visibility instead of a linear filter over all works.

**Armor (A-1.P2):** `works_under_club` equivalence against the
existing linear filter (property test over randomized create
orders); orphan invariant (no work without a resolvable branch).

**Tumbler correspondence:** the branch hierarchy IS the server
namespace — `XudanuTumbler` addresses (`"alice.com".5.3.10.7`)
map to (server, club-branch, work, position). DocumentArrangement
(FR-34 Phase D) currently derives document positions from BeId;
after P2 it derives them from the fulltrace position, making
tumblers stable across re-import (BeId changes, trace position
doesn't have to). This is a later, optional consumer — noted, not
scheduled.

### 3.3 Phase 3: branching revision histories

The deep change. Today `revisions: HashMap<BeId, Vec<RevisionMeta>>`
is a linear counter keyed list. With the fulltrace live, a work's
revision history becomes positions on the work's own branch
sub-DagWood:

- `new_revision` = `new_position_after(last)` — same as today.
- **`fork_revision`** = `new_successor_after(a, b)` — creates a
  real branch point. Two successors of the same revision are
  siblings; `is_le` gives the partial order; `trace_view(ref)`
  gives "the history visible from reference R" — the Gold
  version-visibility semantics, exactly.

This is the only phase that changes user-visible behavior (fork
becomes expressible). It must not land until a frontend consumer
exists (the editor's history view). Design constraint: `RevisionMeta`
gains an optional `trace: TracePosition`; absent = linear legacy.
Old manifests restore with `None` and the counter path continues
to work — migration-free both directions.

**Armor (A-1.P3):** for linear histories, branch-order ≡ counter
order (equivalence property); fork visibility matches Gold's
trace_view semantics (port the DagWood visibility tests at the
revision level); CRDT merge stays revision-tree-agnostic (the
O-tree doesn't know about traces — that boundary is load-bearing
and must survive).

### 3.4 Phase 4: content tree (IS-A hierarchy) — deferred

`src/ent/content.rs` (typed content hierarchy: text/set/path/
hyperlink wrappers, IS-A relationships) stays dormant until a
consumer exists. A-2 (Set/Path RangeElements) is the first
consumer of the *types*; the *tree* (inheritance between them) has
no consumer in our model — our types are closed enums, and Rust
gives us nothing from a runtime IS-A DAG. **Rejected-for-now with
rationale**: adopt types (A-2), reject the hierarchy unless
user-defined content types ever exist.

### 3.5 What we deliberately do not adopt

| Gold mechanism | Why not | Our equivalent |
|---|---|---|
| Shepherd/Abraham hierarchy | GC'd object substrate | Rust ownership + Arc |
| `newShepherd`/`remember` | Object persistence protocol | chunk store + manifest |
| DiskCuisine | Disk GC | snapshot + packer |
| Design fluids | Implicit global context | Explicit parameters |
| `CurrentBertCrum` fluid | Crum context for A-3 | Pass BertCrum explicitly (A-3's problem) |
| Ent as `contentsHash` root | Server-wide content root | `server_root_crum` (FR-34) already does this |

## 4. Persistence

- Manifest: `WorkEntry` gains `trace_branch: u64, trace_position:
  u32` (plain fields, backward compatible — absent = trunk/0 for
  legacy entries; restore synthesizes trunk positions).
- The DagWood itself (branches, trunk map, nav cache) persists as
  a new manifest section `fulltrace`, written at checkpoint when
  dirty. Restore rebuilds `Ent` from it; empty section = fresh
  Ent with synthesized positions (first-boot-after-upgrade path).
- WAL: work-create entries gain the trace fields; journal replay
  maintains the bijection invariant.

## 5. Sequencing and risk

| Phase | Deliverable | Risk | Armor |
|---|---|---|---|
| P1 | Ent on Server; trace in WorkState; bijection | Low — additive | restore/alloc/bijection props |
| P2 | Club branches; visibility queries | Low-Med | works_under_club equivalence |
| P3 | Branching revisions + fork | Med — user-visible | order equivalence, visibility port |
| P4 | Content tree | Rejected-for-now | — |

P1 is small (a field, an allocation call, a manifest section, a
property suite). P2 is small. P3 waits for a frontend consumer.
The 94 existing call sites change by **zero lines** — that is the
measure of this design's safety.

## 6. Relationship to FR-51 (lattice)

The fulltrace and the lattice are orthogonal and complementary:
the lattice is the *content* store (positions inside a document);
the fulltrace is the *namespace* store (positions of documents in
the server's history). FR-51 cutover does not block A-1, and A-1
P2's tumbler correspondence becomes more valuable after cutover
(tumbler-native content + tumbler-native namespace = the complete
Gold addressing story). No ordering constraint either way beyond
taste; recommend A-1 P1/P2 first because they are smaller than
any remaining FR-51 phase.
