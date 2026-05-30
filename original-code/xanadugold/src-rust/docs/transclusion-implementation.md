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

## Remaining Phases

### Phase B: H-Tree Connection + Endorsement Stamps

**Goal:** Connect the H-tree for versioned ancestry queries.

- Define well-known endorsement types (TEXT, HYPERLINK, etc.)
- Auto-endorse content on create/revise
- Set `h_crum` during edition registration (parent-child edges)
- Wire endorsement filtering into `find_transcluders()`
- Fix `find_transcluders_with_backfollow` to use trail results
- Add read permission filtering

**Dependencies:** Phase A (done)

### Phase C: Fingerprint-Based Shared Regions

**Goal:** Replace client-side substring search with BLAKE3 fingerprint matching.

- Replace `FindSharedRegions` handler with element-level comparison
- Replace client-side `findExcerptPositions()` with server fingerprint lookup
- Marker rendering uses element positions instead of char-offset search
- Federation support (cross-server shared regions)

**Dependencies:** Phase A (done). Can run in parallel with B.

### Phase D: Reactive Recorder System

**Goal:** RecorderFossils that monitor for future matching content.

- Implement `Matcher::step()` (H-tree northward walk)
- Implement `RecorderTrigger::step()` (element matching)
- Wire SensorCanopy for reactive notifications
- RecorderFossil lifecycle (create, accumulate, extinguish)
- Wire `on_prop_changed()` from all Server mutations
- Add wire protocol operations for recorder lifecycle
- Real-time push via WebSocket

**Dependencies:** Phase B

### Phase E: ENT Version DAG Integration

**Goal:** Version-aware transclusion queries via DagWood partial ordering.

- Set `trace_position` on EditionMeta during registration
- Bridge Edition/Work to ENT content layer
- `is_le(a, b)` for derivation ancestry
- Version history UI

**Dependencies:** Phases B + D

### Phase F: Provenance Chain (Golden Thread)

**Goal:** Full origin chain through transclusion hops.

- Store `Vec<ProvenanceHop>` in `HyperRef`
- Stacked margin bars with chain tooltips
- Links sidebar shows full ancestry
- Attribution propagation through chain

**Dependencies:** Phase C

### Phase G: UI Features

**Goal:** User-facing features on unified infrastructure.

- Hover tooltips on margin markers
- Click marker to navigate to linked position
- Backlinks panel ("Who transcludes this?")
- Three-way visual comparison
- Live transclusion rendering
- Transclusion browser (graph visualization)
- Inter-span links (range-level, not just work-level)

**Dependencies:** Phases A, C, F

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
    ├── Phase C (Fingerprint Matching)
    │                                     Phase F (Golden Thread)
    └── Phase B (H-Tree + Endorsements)       │
         │                                    │
         └── Phase D (Reactive Recorders)     │
              │                               │
              └── Phase E (Version DAG)       │
                                                  │
                              Phase G (UI) ←──────┘
                                   │
                              Phase H (Compound Docs)
```

---

## Nelson's 17 Rules — Transclusion Coverage

| Rule | Status | Phase |
|------|--------|-------|
| 6. Links + transclusions | **Phase 1 done** | — |
| 7. Visible bidirectional links | **Phase 1 done** | G: backlinks panel |
| 9. Royalty at any granularity | Not started | Post-H |
| 11. Secure access controls | Partial | B: permission filtering |
| 16. Secure auditable transactions | Partial | F: provenance chain |

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
