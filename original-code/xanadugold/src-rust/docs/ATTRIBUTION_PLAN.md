# Transclusion Attribution Suite — Implementation Record

## Overview

Five-phase overhaul to ensure transcluded content always shows the **original author**, not the person who placed the transclusion. Each phase built on the previous one, moving from reliability fixes to rich multi-hop provenance display.

---

## Phase 1: Attribution Reliability (Completed)

**Goal:** Fix wrong-author attribution when a source work has multiple contributors.

**Problem:** `apply_transclusion_attribution` picked the first entry's provenance in the source work as the author for transcluded content. If the source had mixed authors (e.g., historical author + user edits), the wrong author could be attributed.

**Changes:**
- New `resolve_source_provenance()` — finds the excerpt text in the source work, walks all entries overlapping that range, picks the author with the most character overlap
- New `fallback_source_provenance()` — fallback chain: `source_author_id` -> `last_revision_author` (club lookup with verifying key) -> None
- Both `apply_transclusion_attribution_internal` and `apply_pending_provenance_to_edition` use these helpers
- Debug log instead of silent skip when excerpt not yet materialized

**Tests:**
- `user_transclusion_preserves_original_author` — alice writes, bob transcludes, attribution shows alice
- `transclusion_attribution_uses_correct_author_for_excerpt_range` — multi-author source, correct author selected
- `transclusion_attribution_fallback_uses_last_revision_author` — missing element provenance, fallback works

---

## Phase 2: Always-Initialize AttributionLog (Completed)

**Goal:** Eliminate the "No Log" state where attribution logging silently stopped.

**Problem:** `AttributionLog` was `Option<AttributionLog>`. If file initialization failed (e.g., new server, permissions), the field was `None` and all attribution logging was silently skipped. The panel showed "No Log" and revision history was lost.

**Changes:**
- `AttributionLog` refactored to enum: `File(FileAttributionLog)` | `InMemory(InMemoryAttributionLog)`
- Server field changed from `Option<AttributionLog>` to `AttributionLog` — always present
- `Server::new()` and `from_snapshot()` use `AttributionLog::in_memory()`
- `init_data_dir`/`restore_from_data_dir` use explicit error handling instead of `.ok()` swallowing
- `attribution_log_status()` always returns `has_log: true`
- `revise_work` always appends to attribution log (no `if let Some` guard)

**Tests:**
- `in_memory_log_works` — new server has working in-memory log

---

## Phase 3: transcluded_by Field (Completed)

**Goal:** Track who placed a transclusion, separate from who originally wrote the content.

**Problem:** Transcluded spans showed only the original author. There was no record of who actually performed the transclusion (the placer). This loses important provenance information — knowing who introduced content into a document is distinct from knowing who wrote it.

**Changes:**
- New `TransclusionInfo` struct in `provenance.rs`: `{ club_id, display_name, public_key, timestamp }`
- `ElementProvenance` gains `transcluded_by: Option<TransclusionInfo>` field with `#[serde(default)]` for backward compat
- `PendingAttribution` gains `placed_by: Option<TransclusionInfo>` — resolved once via `resolve_transclusion_placer()` at placement time
- `apply_transclusion_attribution_internal` accepts `placed_by` param, sets it on source provenance
- `apply_pending_provenance_to_edition` reads `placed_by` from `PendingAttribution`
- `AttributionSpanPayload` gains `transcluded_by_name` and `transcluded_by_club_id` fields
- Frontend `AttributionPanel.tsx` shows "transcluded by [name]"

**Tests:**
- Extended `user_transclusion_preserves_original_author` to verify `transcluded_by.display_name == "bob"`

---

## Phase 4: Multi-Hop Provenance Chain (Completed)

**Goal:** Surface the full derivation ancestry in the attribution panel.

**Problem:** `provenance_chain: None` was hardcoded in `attribution_query`. The chain data existed on links (computed by `compute_provenance_chain` / `provenance_ancestry`) but was never sent to the frontend. Users couldn't trace content through multiple levels of transclusion.

**Changes:**
- New `enrich_provenance_hops()` helper — looks up work title (first 60 chars) + author name for each hop
- `ProvenanceHopPayload` gains optional `source_work_title` and `source_author_name` (`#[serde(default)]` for backward compat)
- `attribution_query` computes `provenance_ancestry(work)` once, attaches to transcluded spans only
- `dispatch.rs` provenance_ancestry endpoint also enriched
- Frontend `AttributionPanel.tsx` shows "Derivation Chain" section: `[work title] (author) via link:[id] -> ... -> This document`

**Tests:**
- `attribution_query_provenance_chain_multi_hop` — Alice -> Bob -> Carol chain, verifies 2-hop enriched chain

---

## Phase 5: Cleanup (Completed)

**Goal:** Documentation update and warning fixes.

---

## Architecture Summary

### Data Flow

```
User places transclusion
  -> create_link() computes provenance_chain for origin ref
  -> apply_transclusion_attribution()
       -> resolve_transclusion_placer() -> TransclusionInfo
       -> resolve_source_provenance() -> correct original author
       -> fallback_source_provenance() -> if no element provenance
       -> sets ElementProvenance { author, source_work_id, transcluded_by }
       -> stores PendingAttribution { placed_by, ... }
  -> setText fires (may run before attribution)
  -> apply_pending_provenance_to_edition() -> safety net on materialization

attribution_query(work)
  -> provenance_ancestry(work) -> full derivation chain
  -> enrich_provenance_hops() -> add titles + author names
  -> transcluded spans get chain, original spans get None
  -> frontend renders Derivation Chain + Author list + Timeline
```

### Key Types

| Type | File | Purpose |
|---|---|---|
| `ElementProvenance` | `provenance.rs` | Per-entry authorship + `source_work_id` + `transcluded_by` |
| `TransclusionInfo` | `provenance.rs` | Identity of who placed a transclusion |
| `PendingAttribution` | `server.rs` | Deferred attribution for race-condition safety |
| `AttributionLog` | `attribution_log.rs` | Append-only revision chain (File or InMemory) |
| `ProvenanceHop` | `links.rs` | Single hop in derivation chain |
| `ProvenanceHopPayload` | `protocol.rs` | Wire format with enriched title/author |
| `AttributionSpanPayload` | `protocol.rs` | Per-span attribution data sent to frontend |

### Key Methods

| Method | File | Purpose |
|---|---|---|
| `resolve_source_provenance()` | `server.rs` | Excerpt-range-aware original author lookup |
| `fallback_source_provenance()` | `server.rs` | Fallback chain for missing element provenance |
| `resolve_transclusion_placer()` | `server.rs` | Session -> TransclusionInfo |
| `compute_provenance_chain()` | `server.rs` | Link-level chain (propagated on link creation) |
| `provenance_ancestry()` | `server.rs` | Work-level recursive ancestry walk |
| `enrich_provenance_hops()` | `server.rs` | Add work titles + author names to hops |
| `apply_transclusion_attribution_internal()` | `server.rs` | Core attribution propagation |
| `apply_pending_provenance_to_edition()` | `server.rs` | Safety-net re-application on materialization |

---

## Future Enhancements (Not Yet Implemented)

### Attribution Diffs
Show what changed between revisions, per author. The `AttributionPanel` already shows per-author colored spans with timeline. Missing piece: "show me what changed between revision N and N+1".

### Bidirectional Provenance
When a derivative work edits transcluded content, annotate the source work. Requires new link types, reverse-propagation logic, and conflict resolution. Large effort (5-7 days).

### Attribution Integrity Repair
Admin operation to re-run provenance propagation on a work. Iterate all incoming links, re-run `apply_transclusion_attribution` for each.
