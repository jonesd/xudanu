# Transclusion Implementation

This document describes the current state of transclusion in Xudanu and the
remaining work to reach full parity with the original Xanadu/Udanax-Gold
design.

---

## What Is Transclusion?

Transclusion is the inclusion of content from one document into another by
reference, not by copy. When content is transcluded, changes to the original
can propagate to every document that references it. The reader can always trace
any fragment back to its source — the "golden thread."

This is the core innovation of Ted Nelson's Xanadu system, distinguishing it
from hyperlinks (which navigate between documents) and copy-paste (which
breaks the connection).

---

## Current Implementation (Phase 1 — Complete)

### User Flow

1. **Select** text in a source document
2. Click the teal **Transclude** button in the header
3. A **TransclusionBadge** appears showing source info
4. **Navigate** to the target document via the sidebar
5. **Click** in the target editor to place the transclusion
6. Excerpt text is inserted at the click position
7. A bidirectional **link** is created (origin → destination)
8. A **margin bar marker** appears on the transcluded text

### Architecture

```
Frontend                          Server
────────                          ────
useTransclusion.ts                BackfollowEngine
  holdSelection()                   transclusion_index
  placeTransclusion()               fingerprint_to_works
  loadLinks()                       edition_metas
  deleteLink()                    LinkState (in Server)
                                    links, work_to_links
CollaborativeEditor.tsx
  drawOverlay() — margin bars
  handleEditorClick — placement

TransclusionBadge.tsx             Dispatch (protocol.rs)
  source info during placement     LinkCreate (0x0701)
                                   LinkGet (0x0702)
WorkspacePage.tsx                  LinkListForWork (0x0703)
  Transclude button                LinkDelete (0x0704)
  Links sidebar tab
```

### Data Model

- **`HyperLink`** — Multi-ended link with named ends ("LeftEnd", "RightEnd")
- **`HyperRef`** — Reference carrying excerpt (as `Edition`), work context,
  path context
- **`LinkEntry`** (persistence) — `link_id`, `origin`, `destination`,
  `origin_ref: Option<HyperRefPayload>`, `destination_ref: Option<HyperRefPayload>`
- **`HyperRefPayload`** (wire) — `kind`, `work_context`, `excerpt`, etc.

### Marker Rendering

- Client-side excerpt substring search (`findExcerptPositions()`)
- 3px colored margin bar per source work (hash-based color from `MARKER_COLORS`)
- No background tint (avoids conflict with attribution overlay)
- Colors: teal, indigo, deep-orange, cyan, purple, red, green, orange

### Persistence

- Excerpt text flows through `LinkCreate` → `HyperRef::single(Edition)` →
  stored in `BackfollowEngine`'s `LinkState.link`
- `LinkListForWork` extracts excerpts via `from_hyper_ref()`
- `LinkSnapshot` and `persist::LinkEntry` serialize `HyperRefPayload` with
  `#[serde(default)]` for backward compatibility

---

## Phase A: Unify Transclusion Storage (Complete)

### Problem

Server dual-wrote every Work/Edition/Link into both its own HashMaps and a
duplicate copy inside `BackfollowEngine`. On restart, `backfollow.work_storage`
was empty while `transclusion_index` was populated — inconsistent state.

### Changes

| Component | Before | After |
|-----------|--------|-------|
| `BackfollowEngine` fields | `work_storage`, `edition_storage`, `link_storage`, `_grand_map`, `next_*_id` | Removed. Only index structures remain. |
| `register_work()` | `fn register_work(work: Work, ...)` — owned | `fn register_work(work: &Work, ...)` — reference |
| `register_work_with_prop()` | Takes owned `Work` | Takes `&Work` |
| `update_work()` | Derives old edition from internal storage | Takes `&Edition` (old) + `&Work` (new) |
| `update_work_with_parent()` | Same | Same |
| `register_link()` | Stores `HyperLink` + indexes content | `register_link_content()` — indexes content only |
| Link query methods | `find_links_to_content()`, etc. | Removed — Server manages link queries |
| `unregister_edition()` | `(id)` | `(id, &Edition)` — caller provides edition |
| Server `create_work` | Clones Work into backfollow | Passes `&Work` reference |
| Server `revise_work` | Clones Work into backfollow | Extracts old edition, passes references |
| Server `restore` | Only populates transclusion_index | Calls `register_work_with_prop()` for canopy/crum |
| `from_snapshot` | Same dual-write as restore | Same fix |

### Result

- BackfollowEngine holds **only index structures**: `transclusion_index`,
  `fingerprint_to_works`, `edition_metas`, canopies, DagWood
- No duplicate Work/Edition/Link storage
- Consistent state after restart (all structures rebuilt from Server's data)
- 1776 lib tests pass, 0 fail

---

## Phase B: H-Tree Connection + Endorsement Stamps (Complete)

### Goal

Connect the H-tree for versioned ancestry queries with content-type endorsement stamps.

### Changes

| Component | Before | After |
|-----------|--------|-------|
| `compute_work_endorsements()` | Manual check for `TEXT_TOKEN` only | Uses `WrapperRegistry` to detect all content types (Text, Set, Path, HyperLink, HyperRef) |
| `update_work_with_parent()` | Preserves old `BertProp` on revise | Re-computes endorsements from new work content, preserves permissions |
| `register_link_content()` | Indexes content only | Creates `EditionMeta` with HYPERLINK_TOKEN + HYPERREF_TOKEN endorsements |
| `unregister_link_content()` | Removes transclusion index entries | Also removes link's `EditionMeta` |
| `find_transcluders()` | No endorsement-aware filtering of links | Links have `EditionMeta` and participate in canopy filtering |
| `find_transcluders_with_backfollow()` | Already working with H-tree traversal | Now benefits from correct endorsement flags on all entities |

### Endorsement Types (from `WrapperRegistry`)

| Token | Constant | Check | When auto-stamped |
|-------|----------|-------|-------------------|
| 1 | `TEXT_TOKEN` | Contiguous zero-based edition | Works with text content, empty editions |
| 2 | `SET_TOKEN` | Finite edition | Any finite edition |
| 3 | `PATH_TOKEN` | Zero-based with only labels | Label-only editions |
| 4 | `HYPERLINK_TOKEN` | Non-empty edition | All links on registration |
| 5 | `HYPERREF_TOKEN` | Always true | Links with non-empty content |

### Result

- All entities (works, editions, links) carry endorsement stamps reflecting their content types
- Endorsement flags flow into BertCanopy and H-tree, enabling filtered transclusion queries
- Revising a work re-computes endorsement stamps from the new content
- 1779 lib tests pass, 0 fail

---

## Phase C: Server-Side Excerpt Position Lookup + Restore Fix (Complete)

### Goal

Replace client-side substring search with server-side position lookup, and fix restore-path gaps for standalone editions and links.

### Changes

| Component | Before | After |
|-----------|--------|-------|
| `find_excerpt_positions()` | N/A | New server method. Searches CRDT text or persisted edition, returns character offsets |
| `FindExcerptPositions` wire op | N/A | `0x0706` opcode, returns `ExcerptPositionPayload[]` |
| `useTransclusion.loadLinks()` | Client-side `findExcerptPositions()` substring search | Server API call via `client.findExcerptPositions()` |
| `loadLinks` signature | `(client, workId, works, currentText)` | `(client, workId, works)` — no longer needs client-side text |
| Manifest restore (`restore_from_store`) | Only works re-indexed in backfollow | Standalone editions and links also registered |
| Snapshot restore (`from_snapshot`) | Same gap | Same fix |

### Result

- Marker positions computed by server using authoritative CRDT/persisted text
- Server handles both CRDT-active and persisted-only works transparently
- Restore paths fully re-index all entities (works, standalone editions, links)
- 1779 lib tests pass, frontend builds clean

---

## Phase D: Reactive Recorder System (Already Complete)

### Status

Phase D was fully implemented in prior work. The entire reactive recorder pipeline exists and passes all tests.

### What Exists

| Component | Status | Details |
|-----------|--------|---------|
| `RecorderSystem`, `Fossil`, `RecorderQuery` | Complete | Full lifecycle: create, accumulate, extinguish, dedup, ref counting |
| `Matcher` / `RecorderTrigger` / `Agenda` | Complete | Deferred query execution with `process_agenda_with_engine` |
| SensorCanopy integration | Complete | `plant_recorder` / `remove_planted_recorder` on sensor_crum with flag propagation |
| Reactive trigger pipeline | Complete | `trigger_planted_recorders` called on every `create_work` / `revise_work` with Jaccard filtering |
| Fossil-by-fingerprint index | Complete | `fossil_by_fingerprint` reverse index for O(1) content-to-fossil lookup |
| Wire protocol | Complete | 4 admin opcodes (0x1101-0x1104) + Subscribe/Unsubscribe + ContentMatch event |
| WebSocket real-time push | Complete | Subscribe/plant/drain/unsubscribe lifecycle, 200ms polling, cleanup on disconnect |
| Test coverage | Complete | 20 recorder unit tests + 10 watch integration tests |

### Known Gaps (low priority)

- No fossil persistence across server restart (in-memory only)
- `RecorderQuery.region` filtering not wired into `Fossil.matches_filters`
- No federated recorder triggers (only local create/revise)

---

## Phase E: ENT Version DAG Integration (Complete)

### Goal

Version-aware transclusion queries via DagWood partial ordering, with wire protocol exposure.

### What Already Existed

| Component | Status | Details |
|-----------|--------|---------|
| DagWood (version DAG) | Complete | Fork, extend, merge, `is_le()`, successors, TraceView |
| TracePosition | Complete | Lightweight `(BranchId, u32)` identity |
| HUpperCrumData (H-tree) | Complete | Parent links, canopy join, backfollow traversal |
| Assertion system | Complete | 13 payload types, store, visibility, materialization |
| `edition_to_assertions` bridge | Complete | Converts Edition to ENT assertions |
| `version_is_le` / `version_ancestors` | Partial | Existed in backfollow but not exposed via wire protocol |
| Work revision history | Complete | BTreeMap with count, fetch, range, persistence |

### New Changes

| Component | Details |
|-----------|---------|
| `version_ancestors_transitive()` | BFS walk through `parent_of` to find all ancestors, not just direct parents |
| `version_descendants()` | Reverse lookup of children from `parent_of` |
| Wire protocol opcodes | `0x1001` VersionIsBefore, `0x1002` VersionAncestors, `0x1003` VersionDescendants, `0x1004` VersionTracePosition |
| Dispatch handlers | All 4 ops with read permission checks |
| Frontend API methods | `versionIsBefore`, `versionAncestors`, `versionDescendants`, `versionTracePosition` |
| `BranchId::to_u64()` | Public accessor for trace position wire serialization |

### Result

- Full version DAG ancestry and descendant queries exposed via wire protocol
- Transitive ancestor traversal (not just flat parent list)
- 1779 lib tests pass, frontend builds clean

---

## Phase F: Provenance Chain (Golden Thread) (Complete)

### Goal

Full origin chain through transclusion hops — the "golden thread" that lets any content be traced back to its original source.

### Changes

| Component | Details |
|-----------|---------|
| `ProvenanceHop` | New struct: `{ source_work_id: u64, link_id: u64 }` |
| `HyperRef.provenance_chain` | `Vec<ProvenanceHop>` — ordered oldest-to-newest, propagated through all `with_*` methods |
| `create_link()` | Computes chain from incoming links to origin work |
| `compute_provenance_chain()` | Server method: finds incoming links, merges their chains, adds new hop |
| `provenance_ancestry()` | BFS walk of full ancestry for a work, with `visited_works` dedup |
| `ProvenanceHopPayload` | Wire type with `source_work_id`, `link_id` |
| `HyperRefPayload.provenance_chain` | `Vec<ProvenanceHopPayload>` — serde default, backward compatible |
| `ProvenanceAncestry` wire op | `0x0805` — returns full ancestry chain for a work |
| Stacked margin bars | Amber (historical) bars stacked beside primary marker, one per chain hop |
| Links sidebar | Shows hop count badge with tooltip |
| `provenanceAncestry()` | Frontend API client method |

### Chain Propagation

When creating a link from work B to work C:
1. Find incoming links to B (links where B is the destination)
2. For each incoming link IL (A→B), collect IL's chain + `ProvenanceHop(A, IL.id)`
3. Set the merged chain on the new link's origin_ref

Example: A→B→C→D
- L1 (A→B): chain = []
- L2 (B→C): chain = [Hop(A, L1)]
- L3 (C→D): chain = [Hop(A, L1), Hop(B, L2)]

### Result

- 1790 lib tests pass (5 unit + 6 integration new)
- Frontend builds clean
- Stacked amber bars show provenance depth in margin
- Links sidebar shows hop count with tooltip

---

## Phase G: UI Features (Complete)

### Goal

User-facing transclusion interaction features on the unified infrastructure.

### Changes

| Feature | Details |
|---------|---------|
| Hover tooltips | `MarkerHitZone` tracking during `drawOverlay`, mousemove hit-testing on canvas. Tooltip shows work title (colored), direction, provenance hop count |
| Click-to-navigate | Canvas click handler checks hit zones, calls `onNavigateToWork` → `selectWork` |
| Backlinks separation | Links sidebar split into "Transcluded to" (outgoing) and "Transcluded from" (incoming) sections with counts |
| CSS | `.marker-tooltip`, `.marker-tooltip-title`, `.marker-tooltip-direction`, `.marker-tooltip-chain`, `.link-section-label` |

### Deferred

- Three-way visual comparison
- Live transclusion rendering
- Transclusion browser (graph visualization)
- Inter-span links (range-level)

---

## Remaining Phases

### Phase H: Compound Documents

**Goal:** Documents assembled from live references to other documents' content.

- `CompoundEdition` with `Vec<CompoundSpan>`
- Live vs snapshot resolution
- Composition UI

**Dependencies:** All previous phases

---

## Dependency Graph

```
Phase A (Unify Storage) ✅
    ├── Phase C (Server Excerpt Lookup) ✅
    │                                     Phase F (Golden Thread) ✅
    └── Phase B (H-Tree + Endorsements) ✅    │
          │                                    Phase G (UI) ✅
          └── Phase D (Reactive Recorders) ✅       │
               │                                   Phase H (Compound Docs)
               └── Phase E (Version DAG) ✅
```

---

## Nelson's 17 Rules — Transclusion Coverage

| Rule | Status | Phase |
|------|--------|-------|
| 6. Links + transclusions | **Phase 1 done** | — |
| 7. Visible bidirectional links | **Phase 1 done** | G: backlinks panel |
| 9. Royalty at any granularity | Not started | Post-H |
| 11. Secure access controls | Partial | B: permission filtering |
| 16. Secure auditable transactions | **Phase F done** | F: provenance chain |

---

## File Map

| File | Role |
|------|------|
| `src/edition/backfollow.rs` | BackfollowEngine — transclusion index, canopy, DagWood |
| `src/edition/transclusion.rs` | TransclusionIndex, TrailBlazer, queries |
| `src/edition/links.rs` | HyperLink, HyperRef, Path |
| `src/edition/content_address.rs` | ContentAddressIndex (BLAKE3 fingerprints) |
| `src/edition/canopy.rs` | BertCanopy, SensorCanopy |
| `src/edition/recorder.rs` | RecorderFossil, Matcher, Trigger |
| `src/edition/shared_mapping.rs` | Content-based shared detection |
| `src/edition/range_element.rs` | RangeElement, content_fingerprint() |
| `src/edition/provenance.rs` | Cryptographic provenance/signing |
| `src/server/server.rs` | Server — link CRUD, transclusion queries |
| `src/server/transport/dispatch.rs` | Wire protocol handlers |
| `src/server/transport/protocol.rs` | Operation codes, payload types |
| `web/app/src/hooks/useTransclusion.ts` | Frontend transclusion state |
| `web/app/src/components/TransclusionBadge.tsx` | Placement banner |
| `web/app/src/components/CollaborativeEditor.tsx` | Margin bar rendering |
| `web/app/src/components/VirtualizedEditor.tsx` | Viewport-aware markers |
| `web/app/src/components/WorkspacePage.tsx` | Transclude button, Links tab |
