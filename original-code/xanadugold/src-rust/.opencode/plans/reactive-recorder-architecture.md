# Reactive Recorder System Architecture

## Overview

The reactive recorder system is Xanadu Gold's content-watch mechanism. It lets a client register a standing query ("notify me whenever a work containing text X is created or revised") and then automatically fires when matching content appears — without polling.

The system has **5 layers**, organized like a sensor network:

```
                    SensorCanopy (tree of canopy crums)
                    ┌─────────────────────┐
                    │  Root crum           │
                    │  recorders: [42]     │  ← IS_SENSOR_WAITING_FLAG
                    │  flags: 0x04000000   │
                    └──────┬──────┬────────┘
                    ┌──────┴──┐  ┌─┴────────┐
                    │ ab crum  │  │ cd crum    │
                    │ recs:[]  │  │ recs: []   │
                    └────┬─────┘  └───────────┘
                    ┌────┴──┐
                    │ a crum│  ← leaf: edition 1's sensor crum
                    │ [42]  │
                    └───────┘
```

## Layer 1: Fossil — a persisted query

**File:** `src/edition/recorder.rs`

A `Fossil` is a long-lived query monitor. Created by `recorder_create_for_content()`, it stores:

- `query: RecorderQuery` — what to watch for (transcluders of "X"? works containing "Y"?)
- `results: Vec<RecordedResult>` — accumulated matches found so far
- `recorded_fingerprints: HashSet<Vec<u8>>` — dedup set (blake3 hashes of matched elements)
- `is_extinct: bool` — dead fossils get purged
- `reference_count` — lifecycle tracking

A fossil also has filter methods:
- `accepts(&element)` — does this element match the query kind? (Transcluders → edition elements, Works → work elements)
- `matches_filters(&element, is_direct)` — does it pass the endorsement and direct-only filters?

## Layer 2: Planting — installing sensors in the canopy

**Files:** `src/server/server.rs:recorder_plant()`, `src/edition/backfollow.rs:plant_recorder_with_hoist()`, `src/edition/canopy.rs:recording_agent()`

When you call `recorder_plant(edition_id, fossil_id, content)`:

1. **Get the sensor crum**: Looks up the edition's `EditionMeta` and gets its `sensor_crum` (a leaf node in the SensorCanopy tree)
2. **Install recorder**: `recording_agent()` checks if the fossil ID is already on the crum. If not:
   - Calls `crum.install_recorders(&[fossil_id])` which adds the ID and sets `IS_SENSOR_WAITING_FLAG`
   - Returns a `RecorderHoister` agenda item
3. **Register fingerprints**: The fossil's watched content fingerprints are registered in `backfollow.fossil_by_fingerprint` — a `HashMap<[u8;32], HashSet<RecorderId>>` that maps content hashes to the fossils watching for them
4. **Schedule hoister**: The hoister is added to the agenda
5. **Process agenda**: `recorder_process()` runs the agenda to completion

## Layer 3: RecorderHoister — propagating flags up the tree

**File:** `src/edition/hoist.rs`

The `RecorderHoister` is a state machine that walks the SensorCanopy from leaf toward root. It has three phases:

### Phase: Hoisting

At each level, the hoister:
1. Gets the parent crum and its two children
2. Checks if the sibling crum also contains this recorder ID
3. **If both children have it**: Removes from both children, installs at parent (the recorder is "common" to both subtrees, so it belongs higher up). Continues hoisting.
4. **If only one child has it**: Keeps it in that child. Transitions to Propagating phase.
5. Calls `change_canopy()` to update aggregate flags at each level

### Phase: Propagating

Once the recorder cargo is placed correctly, the hoister keeps walking upward just to propagate `IS_SENSOR_WAITING_FLAG` via `change_canopy()` — ensuring all ancestors reflect the correct aggregate state.

### Result

Recorders end up at the **lowest common ancestor (LCA)** of all editions that planted them. This is the key canopy optimization: instead of checking every leaf, you walk from the new content's position upward and only check crums that have recorders.

Example: If editions at sensor leaves A, B, and C all plant fossil 42, after hoisting:
- Fossil 42 is at the LCA crum of {A, B, C}
- When new content appears at leaf D, the system walks from D upward
- It only checks crums that have recorders — skipping empty subtrees entirely

## Layer 4: Triggering — detecting new content matches

**File:** `src/server/server.rs:trigger_planted_recorders()`

Called after `create_work()` and `revise_work()`. The triggering pipeline:

### Step 1: Blake3 fingerprint lookup

Gets the new edition's content fingerprints and looks them up in `backfollow.fossil_by_fingerprint` — the O(1) hash map that finds which fossils care about this content. This replaces the O(n) scan of all fossils.

### Step 2: Permission filtering

`backfollow.filter_fossils_by_permission()` checks each triggered fossil's `authority_clubs` against the triggering edition's canopy flags. Fossils that require clubs the new work doesn't share are filtered out.

### Step 3: Jaccard similarity check

Computes word-set overlap between the source edition (where the fossil was planted) and the triggering edition. If similarity < 0.05 (5%), the match is considered a false positive and skipped. This prevents spurious triggers from common words.

### Step 4: Query execution

For each surviving fossil, runs the actual transclusion query:
- `RecorderKind::Transcluders` → `backfollow.find_transcluders_with_backfollow()` — walks the H-tree for past matches
- `RecorderKind::Works` → `backfollow.find_works_for_content()` — looks up works by fingerprint

### Step 5: Record results

`recorder_system.record_result()` for each match:
- Checks `accepts()` (element type matches query kind?)
- Checks `matches_filters()` (endorsement filter, direct_only)
- Deduplicates via `recorded_fingerprints` (same content only recorded once)
- Stores the `RecordedResult` with timestamp, source edition, etc.

### Step 6: Push notifications

Creates `ContentNotification` entries in `pending_content_notifications` for delivery to connected clients.

## Layer 5: Wire Protocol

**File:** `src/server/transport/protocol.rs`, `src/server/transport/dispatch.rs`

The recorder lifecycle is exposed via the wire protocol:

| Operation | Code | Description |
|-----------|------|-------------|
| `AdminRecorderCreate` | 0x1101 | Create a new fossil with a query |
| `AdminRecorderList` | 0x1103 | List all active fossils and their results |
| `AdminRecorderRecord` | — | Manually record a result into a fossil |
| `ContentWatchStart` | — | Start watching content (creates fossil + plants) |
| `ContentWatchStop` | — | Stop watching (extinguishes fossil + unplants) |
| `ContentWatchResults` | — | Get accumulated results for a fossil |

## Persistence

**File:** `src/edition/recorder.rs:to_snapshots()/restore_from_snapshots()`, `src/server/server.rs:checkpoint/restore`

Fossils survive server restarts:
- **Checkpoint**: `to_snapshots()` serializes active (non-extinct) fossils to a chunk in the chunk store. The manifest stores `fossil_snapshots_hash`.
- **Restore**: The chunk is deserialized, fossils are restored, and `register_fossil_fingerprints()` re-populates the `fossil_by_fingerprint` blake3 index.
- **GC**: `fossil_snapshots_hash` is included in the orphan chunk GC referenced set (was a bug — fossil chunks were being deleted).

## Two-Canopy Design

The system uses two parallel canopy trees, following the C++ architecture:

### BertCanopy (northward / past)
- Indexed by **content properties** (permissions, endorsements)
- Used by `find_transcluders_with_backfollow()` to filter results while walking the H-tree upward
- Each `EditionMeta` has a `bert_crum` with flag bits

### SensorCanopy (southward / future)
- Indexed by **recorder IDs** (active queries)
- Used by `trigger_planted_recorders()` to find matching recorders when new content appears
- Each `EditionMeta` has a `sensor_crum` with recorder IDs and `IS_SENSOR_WAITING_FLAG`

The two canopies are **independent** — BertCanopy answers "what existing content matches?" while SensorCanopy answers "who is watching for future content?" This separation keeps query performance O(log n) in both directions.

## Data Flow Summary

```
Client: "Watch for works containing 'hello'"
    │
    ▼
Server.recorder_create_for_content(query)
    → Creates Fossil(id=42, query={kind: Works, content: ["hello"]})
    │
    ▼
Server.recorder_plant(edition_id=1, fossil_id=42, content=["hello"])
    → Install fossil 42 on edition 1's sensor crum
    → Register "hello".blake3() → {42} in fossil_by_fingerprint
    → RecorderHoister propagates IS_SENSOR_WAITING_FLAG up canopy
    │
    ▼
... time passes ...
    │
    ▼
Server.create_work(edition containing "hello")
    → BackfollowEngine registers new work, indexes fingerprints
    → Server.trigger_planted_recorders(edition_id=2)
        │
        ▼ Step 1: blake3 lookup
        "hello".blake3() → fossil_by_fingerprint → {42}
        │
        ▼ Step 2: permission filter
        Fossil 42 authority=[public], work 2 read_club=[public] → PASS
        │
        ▼ Step 3: Jaccard check
        source_words ∩ trigger_words similarity ≥ 0.05 → PASS
        │
        ▼ Step 4: execute query
        find_works_for_content("hello") → [work_1]
        │
        ▼ Step 5: record result
        Fossil 42.record(element=work_1, is_direct=true) → deduplicated
        │
        ▼ Step 6: notify client
        ContentNotification(fossil_id=42, work_be_id=1, ...)
```
