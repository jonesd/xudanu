# Transclusion Flow Catalogue

Complete reference for how transclusions flow through xudanu, from user gesture to persistent storage and back.

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│  Browser (React)                                        │
│                                                         │
│  Source Work Viewer ──selection──► holdSelection()      │
│  CollaborativeEditor ──selection──► holdSelection()     │
│                        ◄pending badge◄                  │
│  CollaborativeEditor ──click──► handlePlaceTransclusion │
│         │                        │                      │
│         │ setText()     linkCreate()  applyAttribution()│
│         ▼                        ▼           ▼          │
│     CRDT delta          WebSocket ops   WebSocket op    │
└─────────┬──────────────────────┬──────────────┬─────────┘
          │                      │              │
          ▼                      ▼              ▼
┌─────────────────────────────────────────────────────────┐
│  Rust Server                                            │
│                                                         │
│  dispatch.rs::LinkCreate ──► server.create_link()      │
│       │                            │                    │
│       │                    LinkState stored              │
│       │                    work_to_links indexed         │
│       │                    backfollow registered         │
│       │                    provenance chain computed     │
│       │                    auto_checkpoint()             │
│       │                                                │
│  dispatch.rs::ApplyAttribution ─► apply_transclusion_*  │
│       │                            │                    │
│       │                    excerpt found?               │
│       │                    ├── YES: stamp provenance    │
│       │                    │         revise work         │
│       │                    └── NO:  (PA already stored) │
│       │                                                │
│       │    PA ALWAYS stored (deduped by link_id)        │
│       │                                                │
│  try_materialize() ──► CRDT → Edition                  │
│       │                      │                          │
│       │         apply_pending_provenance_to_edition()   │
│       │         (stamps PA excerpts into edition        │
│       │          BEFORE revise_work — single commit)    │
│       │                      │                          │
│       │               revise_work (once)                │
│       │                                                │
│  attribution_query() ──► edition spans + PA overlay     │
│                                                         │
│  checkpoint_to_store() ──► links → chunk store          │
│  restore_from_data_dir() ◄── chunk store → links       │
│  rebuild_pending_attributions() ◄── links → PAs        │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Data Structures

### Rust Server

| Struct | Location | Purpose |
|--------|----------|---------|
| `PendingAttribution` | server.rs:127 | Deferred attribution waiting for excerpt to appear in destination text |
| `LinkState` | server.rs:144 | Runtime link with HyperLink + origin/dest BeIds |
| `ElementProvenance` | provenance.rs | Per-element authorship metadata (author_type, source_work_id, etc.) |
| `SpanProvenance` | provenance.rs | Cryptographic signature over a range of elements |
| `ProvenanceHop` | links.rs:277 | Single hop in a transclusion chain (source_work_id + link_id) |
| `HyperLink` | links.rs | Bidirectional link with LeftEnd/RightEnd HyperRefs |
| `HyperRef` | links.rs | Reference to a work with optional excerpt, path, provenance chain |

**Server fields holding transclusion state:**
| Field | Type | Location | Purpose |
|-------|------|----------|---------|
| `links` | `HashMap<BeId, LinkState>` | server.rs:95 | All links by link_id |
| `work_to_links` | `HashMap<BeId, Vec<BeId>>` | server.rs:96 | Work → link_ids index |
| `pending_attributions` | `Vec<PendingAttribution>` | server.rs:124 | Deferred attributions |
| `link_counter` | `BeId` | server.rs:97 | Auto-incrementing link ID |
| `backfollow` | `BackfollowEngine` | server.rs:98 | Content-based link matching |

### Frontend (TypeScript)

| Type | Location | Purpose |
|------|----------|---------|
| `PendingTransclusion` | useTransclusion.ts:12-18 | Held selection awaiting placement |
| `TransclusionMarker` | crdt_sync.ts:195-204 | Resolved visual marker in editor |
| `LinkEntry` | crdt_sync.ts:111-117 | Wire-format link from server |
| `HyperRefPayload` | crdt_sync.ts:177-183 | Wire-format hyperref |
| `ProvenanceHop` | crdt_sync.ts:119-122 | Wire-format chain hop |

---

## 3. End-to-End Flows

### 3A. Source Work → Document (primary use case)

**Setup**: Source work has `is_source: true`, historical author, read-only `<div>` viewer.

```
User opens source work (e.g. Frankenstein, work 0x03ed)
  ├─ WorkspacePage detects is_source=true
  ├─ CRDT skipped (setSkipCrdt=true)
  ├─ Text loaded via client.textRange() into sourceText state
  └─ Rendered as plain <div> with userSelect:"text"

User selects text in source viewer
  ├─ selectionchange listener fires (WorkspacePage.tsx:295)
  ├─ Character offsets computed via Range technique
  └─ selectionRange state set → "Transclude" button appears

User clicks "Transclude"
  ├─ handleTranscludeSelection() (WorkspacePage.tsx:324)
  ├─ Extracts selectedText from displayText (sourceText for source works)
  ├─ transclusion.holdSelection(sourceWorkId, title, start, end, text)
  └─ PendingTransclusion stored, Transclude button hidden

User navigates to target document (e.g. composite work 0x03f0)
  ├─ selectWork(targetId) changes workBeId
  ├─ CRDT connects, editor renders
  └─ TransclusionBadge appears above editor

User clicks in editor
  ├─ handleEditorClick computes character position
  ├─ handlePlaceTransclusion(position) called
  │   ├─ setText(text.slice(0,pos) + excerpt + text.slice(pos))  ← CRDT insert
  │   ├─ transclusion.placeTransclusion(client, workBeId, pos)
  │   │   ├─ client.linkCreate(origin, dest, originRef, destRef) → linkId
  │   │   │   └─ Server: create_link() → auto_checkpoint()
  │   │   ├─ client.applyTransclusionAttribution(linkId)
  │   │   │   └─ Server: apply_transclusion_attribution()
  │   │   │       ├─ excerpt found in dest? → stamp ElementProvenance
  │   │   │       └─ excerpt NOT found? → create PendingAttribution
  │   │   └─ setPending(null)
  │   └─ await 500ms → loadLinks() → markers drawn
  └─ Editor returns to normal mode
```

**Critical timing**: Text is inserted via CRDT BEFORE linkCreate. The CRDT delta must reach the server and be materialized before applyTransclusionAttribution can find the excerpt. There is a race condition here — the attribution call may arrive before the CRDT materializes the text.

### 3B. Document → Document

Same flow as 3A except:
- Selection comes through editor's `onSelectionChange` callback (not `selectionchange` listener on div)
- Both works have active CRDT sessions
- Source work may have session-signed provenance instead of historical author provenance

### 3C. Chain Transclusion (A → B → C)

```
Work A (source) ──link 1──► Work B ──link 2──► Work C
```

When link 2 is created:
- `compute_provenance_chain(B)` finds link 1 as incoming
- Returns `[ProvenanceHop { source_work_id: A, link_id: 1 }]`
- Link 2's origin_ref carries this chain
- Visual: stacked colored bars in editor (3px base + 2px per chain hop)

### 3D. Attribution Query (reading back)

```
Client sends AttributionQuery { work_id, start, end }
  ├─ Server forces CRDT materialization if needed
  ├─ Phase 1: Build spans from edition's SpanProvenance
  │   ├─ Verify cryptographic signatures
  │   ├─ Resolve author names from clubs/historical authors
  │   └─ Build AttributionSpanPayload with source_work_id
  ├─ Phase 2: Pending attributions overlay
  │   ├─ For each PA matching this work
  │   ├─ Search for excerpt text in current edition
  │   ├─ Resolve source author from origin work
  │   ├─ Deduplicate against Phase 1 spans
  │   └─ Push synthetic AttributionSpanPayload
  └─ Return combined spans to client
```

---

## 4. Persistence Paths

### 4A. Links

```
CREATE:
  create_link() → self.links HashMap updated → auto_checkpoint()
                                        ↓ (every 30s or on shutdown)
                              checkpoint_to_store()
                                        ↓
                              links serialized via postcard
                              chunk_store.write_chunk() → .xchunk file
                              manifest.links_hash = chunk hash

RESTORE:
  restore_from_data_dir()
    ├─ manifest.json → read links_hash
    ├─ chunk_store.read_chunk(links_hash) → deserialize LinkEntry vec
    ├─ Reconstruct HyperLink/HyperRef from LinkEntry
    ├─ Populate self.links, self.work_to_links
    └─ Re-register backfollow index
```

### 4B. Pending Attributions

```
NOT persisted to disk. Two sources:

1. rebuild_pending_attributions() — iterates self.links on startup
   - Called from from_snapshot() (checkpoint_to_file path)
   - Called from restore_from_data_dir() (chunk store path)  ← FIXED

2. Runtime creation — apply_transclusion_attribution() now always
   stores a PendingAttribution (deduped by link_id) regardless
   of whether the excerpt was found.  ← FIXED
```

### 4C. Entry-Level Provenance

```
Stamped into ElementProvenance.carrier.provenance by:
  apply_transclusion_attribution_internal() (immediate, if excerpt found)
  apply_pending_provenance_to_edition() (on every materialization, before commit)

Survives: YES — because apply_pending_provenance_to_edition runs BEFORE
  revise_work, provenance is baked into the edition before it's committed.
  No post-hoc re-stamping needed.

Not lost on materialization: The materialization flow is:
  materialize_with_provenance → apply_pending_provenance_to_edition → revise_work
  Provenance is stamped into the fresh edition before the single commit.
```

---

## 5. Architecture: Provenance Preservation

All former bugs are now fixed. The system uses a single-commit provenance preservation pattern:

### How it works

1. **`apply_transclusion_attribution()`** always stores a `PendingAttribution` (deduped by link_id).
   If the excerpt is already in the destination, it also stamps entry-level provenance immediately.

2. **Every materialization path** (`try_materialize`, `crdt_materialize_now`, `crdt_materialize_any_session`)
   calls `apply_pending_provenance_to_edition(work_id, &mut edition)` BEFORE `revise_work()`.
   This stamps PA excerpts into the new edition's entries in a single pass — no post-hoc re-stamping.

3. **`attribution_query()`** has an overlay that also searches PAs at query time as a safety net.

4. **`rebuild_pending_attributions()`** runs on startup (both `restore_from_data_dir` and `from_snapshot`),
   reconstructing PAs from persisted links.

### Why there's no loop

Previous approach: materialize → revise (loses provenance) → re-stamp → revise again (loop).
New approach: materialize → stamp provenance into edition → revise once. Provenance is baked in before commit.

---

## 6. Wire Protocol

| Op Code | Request | Response | Direction |
|---------|---------|----------|-----------|
| `0x0701` | `LinkCreate { origin, destination, origin_ref, destination_ref }` | `Id(link_id)` | Client → Server |
| `0x0D12` | `WorkApplyTransclusionAttribution { link_id }` | `Void` | Client → Server |
| `0x0D01` | `AttributionQuery { work_id, start, end }` | `AttributionQueryResult { spans }` | Client → Server |
| `0x0703` | `LinkListForWork { work_id }` | `LinkList { links }` | Client → Server |
| `0x0704` | `LinkDelete { link_id }` | `Void` | Client → Server |
| `0x0D04` | `FindExcerptPositions { work_id, excerpt }` | `Positions { positions }` | Client → Server |

---

## 7. File Reference Index

### Rust Server

| File | Key Lines | Component |
|------|-----------|-----------|
| `server/server.rs` | 124-133 | `PendingAttribution` struct |
| `server/server.rs` | 144-149 | `LinkState` struct |
| `server/server.rs` | 4465-4507 | `create_link()` |
| `server/server.rs` | 4509-4538 | `apply_transclusion_attribution()` |
| `server/server.rs` | 4662-4759 | `apply_transclusion_attribution_internal()` |
| `server/server.rs` | 4540-4560 | `rebuild_pending_attributions()` |
| `server/server.rs` | 4562-4577 | `process_pending_attributions()` |
| `server/server.rs` | 5054-5083 | `compute_provenance_chain()` |
| `server/server.rs` | 5303-5343 | `find_excerpt_positions()` |
| `server/server.rs` | 1439-1676 | `attribution_query()` |
| `server/server.rs` | 2765-2807 | `try_materialize()` |
| `server/server.rs` | 471-578 | `materialize_with_provenance()` |
| `server/server.rs` | 785-867 | `revise_work()` |
| `server/server.rs` | 8352-8413 | checkpoint links to chunk store |
| `server/server.rs` | 3983-4058 | restore links from chunk store |
| `server/transport/dispatch.rs` | 784-836 | `LinkCreate` dispatch |
| `server/transport/dispatch.rs` | 2456-2459 | `WorkApplyTransclusionAttribution` dispatch |
| `server/transport/dispatch.rs` | 2082-2096 | `AttributionQuery` dispatch |
| `server/transport/protocol.rs` | 2010-2026 | `AttributionSpanPayload` |
| `server/transport/protocol.rs` | 2151-2162 | `HyperRefPayload` |
| `server/transport/protocol.rs` | 2120-2127 | `LinkPayload` |
| `edition/links.rs` | 277-297 | `ProvenanceHop` |
| `edition/provenance.rs` | — | `ElementProvenance`, `SpanProvenance` |

### Frontend

| File | Key Lines | Component |
|------|-----------|-----------|
| `components/WorkspacePage.tsx` | 279-293 | `handlePlaceTransclusion` |
| `components/WorkspacePage.tsx` | 295-322 | source work `selectionchange` listener |
| `components/WorkspacePage.tsx` | 324-329 | `handleTranscludeSelection` |
| `components/WorkspacePage.tsx` | 540-549 | Transclude button in header |
| `components/WorkspacePage.tsx` | 793-798 | TransclusionBadge placement |
| `components/WorkspacePage.tsx` | 803-820 | source work viewer (plain div) |
| `hooks/useTransclusion.ts` | 41-46 | `holdSelection()` |
| `hooks/useTransclusion.ts` | 52-75 | `placeTransclusion()` |
| `hooks/useTransclusion.ts` | 77-123 | `loadLinks()` / marker building |
| `components/CollaborativeEditor.tsx` | 66-205 | `drawOverlay()` with markers |
| `components/CollaborativeEditor.tsx` | 475-489 | `handleEditorClick` (placement) |
| `components/CollaborativeEditor.tsx` | 558-581 | marker tooltip |
| `components/VirtualizedEditor.tsx` | 379-406 | marker rendering |
| `components/VirtualizedEditor.tsx` | 537-556 | `handleEditorClick` (placement) |
| `components/TransclusionBadge.tsx` | 1-34 | badge UI |
| `components/AttributionPanel.tsx` | 1-179 | attribution sidebar panel |
| `components/ProvenanceWidgets.tsx` | 1-767 | provenance visualizations |
| `components/reading/ReadingView.tsx` | 72-131 | reading view provenance levels |
| `api/crdt_sync.ts` | 560-564 | `applyTransclusionAttribution` |
| `api/crdt_sync.ts` | 580-607 | `linkCreate` |
| `api/crdt_sync.ts` | 614-620 | `linkListForWork` |
| `api/crdt_sync.ts` | 656-661 | `findExcerptPositions` |
