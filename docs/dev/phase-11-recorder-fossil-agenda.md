# Phase 11: Recorder / Fossil / Agenda + Admin Monitoring

## Overview

Phase 11 adds the Recorder system — a mechanism for registering persistent queries that accumulate results over time as content flows through the server. This is the Rust equivalent of the C++ `ResultRecorder` / `RecorderFossil` / `AgendaItem` subsystem from `tcludex.hxx`, plus an admin health monitoring endpoint.

## What Was Built

### 1. Recorder System (`src/edition/recorder.rs`)

**RecorderKind** — The type of content a recorder watches for:

```rust
pub enum RecorderKind {
    Transcluders,  // watches for Edition elements
    Works,         // watches for Work elements
}
```

**RecorderQuery** — A builder-pattern query describing what a recorder is interested in:

```rust
let query = RecorderQuery::transcluders()
    .with_region(XnRegion::interval(0, 10))
    .direct_only(true)
    .with_authority(vec![1, 2])
    .with_endorsement_filter(vec![10, 20]);
```

Fields: `kind`, `region` (optional scope), `direct_only` (skip indirect transclusions), `authority_clubs`, `endorsement_filter` (whitelist of element IDs).

**Fossil** — A long-lived accumulator for recorded results. Each fossil wraps a query and collects matching elements with content-fingerprint deduplication:

- `record()` — Adds a result if not already seen (by fingerprint). Returns `true` if new, `false` if duplicate or extinct.
- `extinguish()` — Marks the fossil as dead; no further recording.
- `add_reference()` / `remove_reference()` — Reference counting for lifecycle management.
- `accepts()` — Checks if element kind matches the query (Transcluders → Edition, Works → Work).
- `matches_filters()` — Checks `direct_only` and `endorsement_filter` constraints.

**RecordedResult** — A single recorded observation with `element`, `source_edition_id`, `source_work_id`, `is_direct`, and `timestamp`.

**RecorderSystem** — The top-level manager holding all fossils keyed by `RecorderId` (u64):

- `create_fossil(query)` — Creates and returns a new recorder ID.
- `record_result(fossil_id, element, ...)` — Records an element into the matching fossil (checks kind, filters, dedup).
- `extinguish_fossil(id)` / `purge_extinct()` — Lifecycle management.
- `schedule_trigger()` — Queues a `RecorderTrigger` on the agenda.
- `process_agenda()` — Drains all pending agenda items.
- `active_fossil_count()` / `total_result_count()` / `fossil_ids()` — Stats.

### 2. Agenda System

**AgendaItem trait** — A trait for deferred processing items with `step()` and `is_complete()`.

**Matcher** — An agenda item that matches a target edition against a fossil's query. Completes in one step (foundation for future multi-step matching).

**RecorderTrigger** — An agenda item representing a pending record operation for a fossil.

**Agenda** — Holds `Vec<Box<dyn AgendaItem>>` with `step_all()` to process all items in one pass and remove completed ones.

### 3. Server Integration

**ServerHealth** — Admin monitoring struct:

```rust
pub struct ServerHealth {
    pub operation_count: u64,
    pub active_recorders: usize,
    pub total_recorded: usize,
    pub blob_count: usize,
    pub link_count: usize,
    pub uptime_secs: u64,
}
```

Five new operations added to the wire protocol (opcodes 0x1101–0x1105):

| Operation | Opcode | Request | Response |
|-----------|--------|---------|----------|
| `admin_recorder_create` | 0x1101 | kind, direct_only?, region? | recorder_id |
| `admin_recorder_record` | 0x1102 | recorder_id, element | recorded (bool) |
| `admin_recorder_list` | 0x1103 | *(none)* | recorders[] |
| `admin_recorder_get` | 0x1104 | recorder_id | recorder or null |
| `admin_server_health` | 0x1105 | *(none)* | health stats |

All admin operations require admin session (via `ensure_admin()`). The server stores a `recorder_system: RecorderSystem` and `start_time: u64` (epoch-relative) for uptime calculation.

Full integration path: protocol.rs → codec.rs → dispatch.rs → server.rs.

## C++ Equivalence

| C++ Class/Method | Rust Equivalent |
|------------------|-----------------|
| `RecorderFossil` | `Fossil` |
| `ResultRecorder` / `EditionRecorder` / `WorkRecorder` | `RecorderSystem` with `RecorderKind` |
| `RecorderQuery` (kind + region + direct) | `RecorderQuery` builder |
| `AgendaItem` | `AgendaItem` trait |
| `Matcher` | `Matcher` struct |
| `RecorderTrigger` | `RecorderTrigger` struct |
| `Agenda::stepAll()` | `Agenda::step_all()` |
| `FeAdminer` health queries | `ServerHealth` + `admin_server_health` op |

## Design Decisions

1. **Unified Fossil type**: The C++ has separate `EditionRecorder` and `WorkRecorder` subclasses. The Rust uses a single `Fossil` struct with `RecorderKind` enum, dispatching on kind via `accepts()`.

2. **Content-fingerprint dedup**: Uses `RangeElement::content_fingerprint()` (BLAKE3) for deduplication, stored as `HashSet<Vec<u8>>`. This is simpler than the C++ `HashSetCache<T>` template.

3. **Reference counting for lifecycle**: Fossils track `reference_count` to support future use cases where multiple clients share a recorder. `purge_extinct()` removes dead fossils.

4. **Single-step agenda items**: `Matcher` and `RecorderTrigger` complete in one `step()` call. The agenda infrastructure is in place for future multi-step items (e.g., recursive transclusion walkers).

5. **Admin-only operations**: All recorder and health endpoints require admin session via `ensure_admin()`, matching the C++ `FeAdminer` pattern.

## Tests

- **17 unit tests**: Fossil recording/dedup, extinction, reference counting, kind filtering, direct_only/endorsement filters, RecorderSystem CRUD, agenda processing, stats, timestamps.
- **5 integration tests**: `admin_recorder_create_and_list`, `admin_recorder_record_and_get`, `admin_recorder_record_wrong_kind`, `admin_recorder_not_found`, `admin_server_health`.
- **Total: 1250 tests passing** (1140 unit + 110 integration)
