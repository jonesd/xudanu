# Transclusion Attribution Suite — Feature Plan

## Effort Assessment

| Feature | Effort | Risk | Why |
|---|---|---|---|
| **Transclusion Ancestry** | Medium (3-4 days) | Low | Backend infrastructure exists (`ProvenanceHop` chain on `HyperRef`, `LinkListForWork`, `WorkBacklinks`). Mostly wiring new query endpoint + frontend panel. |
| **Attribution Diffs** | Small (1-2 days) | Low | The `AttributionPanel` already shows per-author colored spans with timeline. What's missing is "show me what changed between revision N and N+1" which is a compare-entries-by-timestamp on the existing data. |
| **Bidirectional Provenance** | Large (5-7 days) | Medium | Requires architectural change: when a derivative work edits transcluded content, the *source* work needs annotation. This involves new link types, reverse-propagation logic, and conflict resolution. |

## Related Features Worth Including

1. **Attribution Integrity Repair** — when attribution is wrong/missing, a way to re-run provenance propagation on a work
2. **Source Work Attribution in Attribution Panel** — currently `AttributionSpanPayload` has `historical_author_id` but no `source_work_id`. Adding the source work provenance chain to each span lets the panel show "this span came from Work X via Link Y"

---

## Phase 1: Attribution Panel Enhancement (1-2 days)

**Goal:** Make the existing panel show transclusion source information.

### Tasks

- [ ] **P1.1** Extend `ElementProvenance` with optional `source_work_id: Option<BeId>` field
  - File: `src/edition/provenance.rs`
  - Update serde `ElementProvenanceData` struct and Serialize/Deserialize impls
  - Existing fields that reference `ElementProvenance` should work since it's `Option`

- [ ] **P1.2** Extend `AttributionSpanPayload` with optional source work fields
  - File: `src/server/transport/protocol.rs`
  - Add `source_work_id: Option<BeId>`
  - Add `provenance_chain: Option<Vec<ProvenanceHopPayload>>`
  - Define `ProvenanceHopPayload { source_work_id: BeId, link_id: BeId }`

- [ ] **P1.3** Update `apply_transclusion_attribution` to store `source_work_id` in carrier provenance
  - File: `src/server/server.rs` (~line 4022)
  - When copying `source_prov` to matched range entries, set `source_prov.source_work_id = Some(origin_work_id)`

- [ ] **P1.4** Update `attribution_query` server method to populate new fields
  - When building `AttributionSpanPayload` from carrier provenance, include `source_work_id` and `provenance_chain` if present

- [ ] **P1.5** Update frontend `AttributionSpan` / `nionSpan` type
  - File: `web/app/src/api/crdt_sync.ts`
  - Add `source_work_id?: number`, `provenance_chain?: ProvenanceHop[]`

- [ ] **P1.6** Update `AttributionPanel` to show transclusion source
  - File: `web/app/src/components/AttributionPanel.tsx`
  - When a span has `historicalAuthorId` and `source_work_id`, show "via [source work]" label
  - Distinct gold color for historical authors (already exists)
  - Make source work clickable if possible

- [ ] **P1.7** Update existing tests
  - Verify `transclusion_attribution_propagates_historical_provenance` test checks `source_work_id` is set
  - Add assertion that `ElementProvenance.source_work_id == Some(origin_work_id)` after attribution

---

## Phase 2: Transclusion Ancestry View (3-4 days)

**Goal:** Show the chain of derivation from source to current document.

### Tasks

- [ ] **P2.1** New opcode `WorkTransclusionAncestry { work_id: BeId }`
  - File: `src/server/transport/protocol.rs`
  - Add `OperationCode::WorkTransclusionAncestry` (pick next available 0x03xx)
  - Add `WireRequest::WorkTransclusionAncestry { work_id: BeId }`
  - Add `WireResponse::TransclusionAncestryResult { ancestors: Vec<AncestorNode> }`
  - Define `AncestorNode { work_id: BeId, title: Option<String>, link_id: BeId, depth: u32, author_display_name: Option<String> }`

- [ ] **P2.2** Implement `work_transclusion_ancestry` on server
  - File: `src/server/server.rs`
  - Walk incoming links (where this work is destination) via link store
  - For each link, get origin work and provenance chain from `HyperRef`
  - Recursively walk to origin works, building ancestor tree with depth tracking
  - Deduplicate cycles (work appearing multiple times in chain)

- [ ] **P2.3** Wire codec and dispatch
  - File: `src/server/transport/codec.rs` — parse new request
  - File: `src/server/transport/dispatch.rs` — dispatch to server method

- [ ] **P2.4** Frontend API client method
  - File: `web/app/src/api/crdt_sync.ts`
  - Add `getTransclusionAncestry(workId: number): Promise<AncestorNode[]>`

- [ ] **P2.5** Frontend Ancestry panel component
  - New component or section within `AttributionPanel`
  - Collapsible tree showing work title, link type, author, depth
  - Click to navigate to ancestor work
  - Show "No transclusion ancestry" for original works

---

## Phase 3: Attribution Diffs (1-2 days)

**Goal:** Show what changed between revisions, per author.

### Tasks

- [ ] **P3.1** Extend `AttributionQuery` response with revision boundaries
  - File: `src/server/transport/protocol.rs`
  - Add `revision_boundaries: Vec<RevisionBoundary>` to `AttributionQueryResult`
  - Define `RevisionBoundary { timestamp: u64, author_public_key: Vec<u8>, span_count: u64, char_count: u64 }`

- [ ] **P3.2** Compute revision boundaries server-side
  - Group spans by timestamp (or timestamp windows), compute per-group stats

- [ ] **P3.3** Frontend revision slider/dropdown
  - File: `web/app/src/components/AttributionPanel.tsx`
  - Dropdown to select revision range
  - Filter displayed spans to selected range
  - Summary: "Author X added N chars in this revision"

---

## Phase 4: Bidirectional Provenance (5-7 days)

**Goal:** When derivative work edits transcluded content, annotate the source work.

### Tasks

- [ ] **P4.1** New derivative link type / flag
  - File: `src/edition/links.rs`
  - Add `DerivativeEdit` variant or flag on existing link types
  - Payload: `{ original_range, derivative_work_id, derivative_range }`

- [ ] **P4.2** Detect derivative edits on `WorkRevise`
  - File: `src/server/server.rs`
  - On revision, compare old and new editions
  - If modified content overlaps with transcluded regions (entries that have `source_work_id` set), create derivative link

- [ ] **P4.3** Store and query derivative links
  - Register in backfollow engine
  - Return via `WorkBacklinks` for source work

- [ ] **P4.4** Frontend: show derived edits in source work
  - Badge on spans that have derivative modifications
  - "Edited in N derivative works" indicator

---

## Phase 5: Attribution Integrity Repair (1-2 days)

**Goal:** Admin operation to re-run attribution propagation.

### Tasks

- [ ] **P5.1** New opcode `WorkRepairAttribution { work_id: BeId }`
- [ ] **P5.2** Server method: iterate all incoming links, re-run `apply_transclusion_attribution` for each
- [ ] **P5.3** Frontend: admin-only "Repair Attribution" button in panel

---

## Dependency Graph

```
Phase 1 (Panel Enhancement)
    ├── Phase 2 (Ancestry View) ← depends on Phase 1 data
    ├── Phase 3 (Attribution Diffs) ← independent of Phase 2
    └── Phase 4 (Bidirectional Provenance) ← depends on Phase 1 data model
        └── Phase 5 (Repair) ← depends on Phase 4
```

## Recommended Order

**Phase 1 → 2 → 3 → 4 → 5**

Phases 1-3 are additive, low-risk, and immediately useful. Phase 4 is the big one and should be designed carefully before implementation. Phase 5 is a safety net for Phase 4.

## Total Estimate

- **Phases 1-3 (high-value, low-risk):** 5-8 days
- **All phases:** 11-17 days

## Key Files

- `src/edition/provenance.rs` — `ElementProvenance`, `Provenance`, signing/verification
- `src/edition/links.rs` — `ProvenanceHop`, `HyperRef`, provenance chain
- `src/edition/backfollow.rs` — `BackfollowEngine`, `find_transcluders`, `find_transcluders_with_backfollow`
- `src/server/server.rs` — `apply_transclusion_attribution` (~4022), `apply_source_attribution` (~1737)
- `src/server/transport/protocol.rs` — `WireRequest`, `AttributionSpanPayload`, opcodes
- `src/server/transport/codec.rs` — request parsing
- `src/server/transport/dispatch.rs` — request dispatch
- `web/app/src/components/AttributionPanel.tsx` — attribution UI
- `web/app/src/api/crdt_sync.ts` — frontend API client
- `web/app/src/hooks/useTransclusion.ts` — transclusion hook
