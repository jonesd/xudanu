# Gold Mechanism Integration Plan

> Incorporating the remaining Udanax Gold recorder/canopy/agenda mechanisms
> into Xudanu, combining Gold's architectural patterns with our modern blake3
> content-addressing, chunk store, and React frontend.

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Efficiency Comparison: Gold vs Xudanu](#efficiency-comparison)
3. [Phase 1: Complete Island Code Wiring](#phase-1)
4. [Phase 2: Hybrid Canopy + Persistent Fossils](#phase-2)
5. [Phase 3: Tumbler/CrossSpace Wiring](#phase-3)
6. [Phase 4: AssertionStore Annotation Migration](#phase-4)
7. [Phase 5: Position-Level Recorder Planting](#phase-5)
8. [Phase 6: Persistent Agenda with Crash Recovery](#phase-6)
9. [Phase 7: Full Canopy Walk Triggering](#phase-7)
10. [Phase 8: Frontend Updates](#phase-8)
11. [Implementation Priority and Dependencies](#dependencies)
12. [Pros, Cons, and Tradeoffs](#pros-cons)
13. [Risk Assessment](#risks)
14. [Appendix: Gold Architecture Reference](#appendix)

---

<a id="executive-summary"></a>
## 1. Executive Summary

This document describes how to incorporate the remaining Udanax Gold mechanisms
into the Xudanu Rust server. The Gold system used two parallel canopy trees
(Bert for permissions, Sensor for recorders) with a persistent agenda system
to provide incremental, crash-resilient content watching and transclusion
finding. Our implementation already has the data structures (canopy, hoister,
recorder system) but they are "island code" -- compiled, tested, but not wired
into the server's runtime paths.

The plan proceeds in 8 phases, from immediate wiring work through architectural
enhancements, ending with frontend updates. Each phase is incremental -- it
builds on prior phases and does not require re-architecting what came before.

### Key Design Decision

We use a **hybrid approach**: our blake3 O(1) HashMap for content-to-recorder
lookup (which Gold never had) combined with Gold's canopy tree for
permission-aware filtering (which our HashMap alone cannot provide). This gives
us the best of both systems.

---

<a id="efficiency-comparison"></a>
## 2. Efficiency Comparison: Gold vs Xudanu

### Current State

| Operation | Gold | Xudanu (now) | Winner |
|---|---|---|---|
| Content to recorder lookup | O(D·B) canopy walk | O(1) blake3 HashMap | **Xudanu** |
| Transclusion finding | O(V) H-tree walk | O(1) TransclusionIndex | **Xudanu** |
| Content storage | No dedup | blake3 content-addressed chunks | **Xudanu** |
| Edit triggers recorders | O(log N) canopy walk + pruning | O(K) scan all edition fossils | **Gold** |
| Permission filtering | O(1) subtree pruning | O(K) post-filter | **Gold** |
| Triggering granularity | Position-level (per Loaf) | Edition-level (whole doc) | **Gold** |
| Fossil memory | On-demand reanimation from disk | All in memory | **Gold** |
| Crash recovery | Persistent agenda, resume | All in-flight work lost | **Gold** |
| Annotation edit survival | Structural span attachment | Byte offsets (broken on edit) | **Gold** |

### After All Phases Complete

| Operation | Gold | Xudanu (completed) | Winner |
|---|---|---|---|
| Content to recorder lookup | O(D·B) canopy walk | O(1) blake3 + O(D) canopy check | **Xudanu** |
| Transclusion finding | O(V) H-tree walk | O(1) TransclusionIndex | **Xudanu** |
| Content storage | No dedup | blake3 content-addressed chunks | **Xudanu** |
| Edit triggers recorders | O(log N) canopy walk | O(log N) canopy walk from position | **Tie** |
| Permission filtering | O(1) subtree pruning | O(1) subtree pruning | **Tie** |
| Triggering granularity | Position-level | Position-level (per chunk) | **Tie** |
| Fossil memory | On-demand reanimation | Persisted in checkpoint | **Slight Gold** |
| Crash recovery | Persistent agenda | Persistent agenda | **Tie** |
| Annotation edit survival | Structural spans | Structural spans (AssertionStore) | **Tie** |

### Estimated Overall Performance

After all phases, Xudanu should achieve **110-130% of Gold's overall
performance** in typical workloads, with advantages concentrated in the most
common operations:

- **Content-based operations** (transclusion finding, shared content detection,
  content matching): Xudanu is **significantly faster** due to blake3 O(1)
  lookups replacing Gold's O(N) tree walks.

- **Recorder operations** (triggering, filtering, hoisting): **Roughly
  equivalent** to Gold. The canopy walk is the same algorithm, but Xudanu has
  an additional blake3 shortcut to find the starting position faster.

- **Storage**: Xudanu is **clearly superior** -- content-addressed dedup,
  incremental chunk writes, blake3 integrity verification. Gold stored
  duplicate content and had no content hashing.

- **Scalability**: Gold has a slight edge at extreme scale (millions of
  fossils) due to on-demand reanimation. Xudanu loads all fossils on restore.
  This could be addressed later with lazy loading from the chunk store.

---

<a id="phase-1"></a>
## 3. Phase 1: Complete Island Code Wiring

### Status: IN PROGRESS

Wire the existing "island code" (Features 1-5 from the original migration) into
the server's runtime paths.

### 3A. F5: ConsequenceTracker / WriteBarrier (DONE)

**What was done:**
- Added `Arc<ConsequenceTracker>` and `Arc<WriteBarrier>` fields to `Server`
- Added `OperationGuard` (RAII) to all mutating Server methods (19 methods)
- Added `WriteGuard` to `checkpoint_to_store()` and `checkpoint_to_file()`
- Added `wait_for_consequences()` and `wait_for_write()` to `ServerHandle`
- 8 integration tests, 1914 total tests passing

**Efficiency impact:** None directly. This is a correctness mechanism that
prevents reads during writes and provides client-side notification of
completion.

### 3B. F4: RecorderHoister Wiring (IN PROGRESS)

**What's done:**
- `RecorderSystem::schedule_hoist()` added to `recorder.rs`
- `process_agenda_with_engine` now steps `RecorderHoister` items

**What remains:**
- Wire `recording_agent()` into `recorder_plant()`:
  ```
  recorder_plant(edition_id, fossil_id, content)
    |-- backfollow.plant_recorder(...)          (existing)
    |-- canopy.recording_agent(crum, fossil_id) (NEW)
    |-- recorder_system.schedule_hoist(item)    (NEW)
    +-- recorder_process()                      (existing)
  ```
- Wire `recording_agent()` into `recorder_create_for_content()`
- Tests: verify hoister steps during plant, flags propagate correctly

**Efficiency impact:** Minor. The hoister propagates `IS_SENSOR_WAITING_FLAG`
correctly through the canopy. Currently `propagate_flags` does this in one
shot; the hoister does it incrementally (multi-step state machine). The
hoister is more correct (it handles the case where flags change during
propagation) but not faster.

**New code locations:**
- `src/server/server.rs` -- modify `recorder_plant()` and
  `recorder_create_for_content()`
- `src/edition/recorder.rs` -- `schedule_hoist()` already added
- `src/edition/canopy.rs` -- `recording_agent()` already exists

### 3C. F1: Link Types in Protocol

**What to do:**
- Add `link_types: Vec<u64>` field to `LinkCreate` request in `protocol.rs`
- Wire through dispatch to `create_link()` so clients can set link types
- The storage path already preserves `link_types` (done in F1 migration)

**Efficiency impact:** None. This is a completeness feature.

**Files:**
- `src/server/transport/protocol.rs` -- add `link_types` to `LinkCreateRequest`
- `src/server/transport/dispatch.rs` -- wire through to `create_link()`
- `src/server/server.rs` -- modify `create_link()` signature

---

<a id="phase-2"></a>
## 4. Phase 2: Hybrid Canopy + Persistent Fossils

### 2A. Permission-Filtered Recorder Triggering

**The Problem:** Currently `trigger_planted_recorders` finds fossils via
blake3 HashMap lookup, then does a Jaccard similarity check. It does NOT
check whether the fossil's query permission requirements match the
triggering work's permissions. A fossil watching for "public-only content"
could be triggered by a private work that happens to share content.

**The Solution:** Add a canopy-based permission check after the blake3 lookup:

```
trigger_planted_recorders(work_be_id)
  |-- blake3 lookup: fossil_by_fingerprint[fp] -> fossil_ids    (O(1), our strength)
  |-- canopy filter: BertProp check on each fossil             (O(K) where K = matched fossils)
  |     +-- Skip fossils whose query.authority_clubs don't pass the work's BertProp
  |-- Jaccard similarity check (existing, threshold 0.05)
  +-- Record results + push notifications
```

**Implementation:**
- New method: `BackfollowEngine::filter_fossils_by_permission(fossil_ids, work_prop) -> Vec<RecorderId>`
- Uses the existing `BertCanopy::walk_northward()` with a `PropFinder` built from the work's properties
- Each fossil's `query.authority_clubs` are checked against the canopy flags

**Efficiency:** O(K) where K is the number of matched fossils. Gold achieves
O(1) subtree pruning (it never even enters subtrees that don't match). Our
approach is a post-filter, so we do K comparisons. For typical workloads
(K < 100), this is negligible. For pathological cases (K = 10,000+), Gold's
approach would be faster. Phase 7 addresses this.

**New code locations:**
- `src/edition/backfollow.rs` -- `filter_fossils_by_permission()`
- `src/server/server.rs` -- modify `trigger_planted_recorders()`

### 2B. RecorderHoister in recorder_plant

**The Problem:** Currently `backfollow.plant_recorder()` calls `propagate_flags()`
directly, which does a one-shot walk up the canopy. The RecorderHoister does
the same thing but incrementally (multi-step) and also handles the case where
recorders should be hoisted to ancestor crums when both children contain them.

**The Solution:** Replace direct `propagate_flags` with `recording_agent()`
+ `schedule_hoist()`:

```
recorder_plant(edition_id, fossil_id, content)
  |-- backfollow.plant_recorder(...)        (installs in sensor_crum + fingerprint index)
  |-- for each edition's sensor_crum:
  |     canopy.recording_agent(crum, fossil_id)  (returns Option<AgendaItem>)
  |     if Some(item): recorder_system.schedule_hoist(item)
  +-- recorder_process()                    (drains agenda, runs hoisters + matchers)
```

**Efficiency:** Equivalent. The hoister does the same flag propagation, but
incrementally. It also performs recorder hoisting (moving recorders up to
ancestor crums when both siblings contain them), which saves memory at scale.

**New code locations:**
- `src/server/server.rs` -- modify `recorder_plant()`

### 2C. Persistent Fossils in Checkpoint

**The Problem:** Fossils (active recorder queries) are lost on server restart.
Clients that had active content-watch subscriptions lose them and must
re-subscribe.

**The Solution:** Serialize fossil state into the manifest:

```rust
struct FossilSnapshot {
    id: u64,
    query: RecorderQuery,
    results: Vec<RecordedResult>,
    recorded_fingerprints: HashSet<Vec<u8>>,
    is_extinct: bool,
    reference_count: u64,
    created_at: u64,
    source_edition_id: Option<u64>,
}
```

Add to manifest:
```rust
struct Manifest {
    // ... existing fields ...
    fossil_snapshots: Vec<FossilSnapshot>,
    fossil_next_id: u64,
}
```

On restore, recreate `RecorderSystem` from snapshots and re-register
`fossil_by_fingerprint` entries in the BackfollowEngine.

**Efficiency:** One-time cost on restart to rebuild the fingerprint index.
For N fossils watching M fingerprints each, this is O(N*M). Typical: N < 1000,
M < 100, so O(100K) hash insertions. Negligible.

**Comparison to Gold:** Gold had on-demand reanimation -- fossils were loaded
from disk only when touched. Our approach loads all fossils on restart. At
scale (100K+ fossils), Gold's approach would use less memory. We could add
lazy loading later if needed.

**New code locations:**
- `src/persist/manifest.rs` -- add `FossilSnapshot`, `fossil_snapshots` field
- `src/server/server.rs` -- serialize in `checkpoint_to_store()`, deserialize
  in `from_snapshot()`
- `src/edition/recorder.rs` -- add `to_snapshot()` / `from_snapshot()` methods

---

<a id="phase-3"></a>
## 5. Phase 3: Tumbler/CrossSpace Wiring (F2 + F3)

### 3A. Tumbler Decomposition (F2)

**What to do:** Use the `Sequence` operations we already built (first, rest,
from_dotted, PrefixFilter) in actual server operations:

- **Edition navigation:** Decompose a work ID into hierarchical components
  (server.work.edition.position) for tumbler-style addressing
- **Prefix queries:** Use `SequenceRegion::prefixed_by()` for finding all
  editions/works under a given hierarchical prefix
- **Dotted notation:** Accept `from_dotted()` in the wire protocol for
  position addressing

**Efficiency:** Sequence operations are O(1) per component. The PrefixFilter
is O(log N) per query. This is equivalent to Gold's tumbler performance.

**New code locations:**
- `src/server/transport/protocol.rs` -- add tumbler address fields
- `src/server/transport/dispatch.rs` -- wire tumbler decomposition
- `src/server/server.rs` -- add tumbler-based edition/work lookup methods

### 3B. CrossSpace for Endorsements (F3)

**What to do:** Wire `CrossSpaceN` and `CrossRegionN` into the endorsement
system:

- Replace flat `BTreeSet<Endorsement>` with `CrossRegionN` over
  `IDSpace x EndorsementSpace`
- Support per-region endorsements within an edition (Gold had this)
- Enable `projection()` operations for cross-dimensional queries

**Efficiency:** CrossRegion operations are O(N) per axis where N is the number
of intervals. This is equivalent to Gold's CrossRegion performance. The
benefit is structural: multi-dimensional endorsement sets enable richer
queries (e.g., "endorsed by club X in region Y").

**New code locations:**
- `src/edition/endorsement.rs` -- integrate CrossRegionN
- `src/server/server.rs` -- modify endorsement methods
- `src/edition/backfollow.rs` -- use CrossRegion for endorsement filtering

---

<a id="phase-4"></a>
## 6. Phase 4: AssertionStore Annotation Migration (F6)

### The Problem

The current `OtreeAnnotation` in `otree_crdt.rs` uses `char_start`/`char_end`
byte offsets. When text is edited, these offsets become stale -- annotations
point to the wrong text or go out of bounds. This is the same problem Gold
solved by attaching annotations to structural spans (which have identity
independent of position).

### The Solution

Replace `Vec<OtreeAnnotation>` with `AssertionStore` from `src/ent/content.rs`.

The `AssertionStore` already exists with:
- `AssertionPayload::CreateAnnotation`, `AttachAnnotationToNode`,
  `AttachAnnotationToSpan`, `DeleteAnnotation`
- `MaterializedDocument`, `MaterializedNode`, `MaterializedSpan`,
  `MaterializedAnnotation` for reconstruction
- `TraceView::visible_assertions()` for version-aware filtering

### Migration Path

1. **Add `AssertionStore` as a Server field** (alongside existing `OtreeCrdtManager`)
2. **New annotation API** that creates structural spans:
   ```
   annotation_create(work_id, kind, payload, span_start, span_end)
     |-- Create Span: store.add(position, CreateSpan { span_id })
     |-- Create Annotation: store.add(position, CreateAnnotation { annotation_id, kind, payload })
     |-- Attach to Span: store.add(position, AttachAnnotationToSpan { annotation_id, span_id })
     +-- Materialize via TraceView when reading
   ```
3. **Keep `OtreeAnnotation` for backward compat** during migration
4. **Migrate existing annotations**: convert `OtreeAnnotation.char_start/char_end`
   to `SpanId`s in the assertion store
5. **Eventually deprecate `OtreeAnnotation`**

### Transclusion Survival

Because annotations attach to `SpanId`s (structural identity) not byte offsets:
- When text is edited, the span's text changes but the span ID persists
- Annotations automatically follow the content they're attached to
- `MaterializedDocument` reconstructs the full annotation tree on read
- The `TraceView` filters visible assertions by DagWood branch, giving proper
  versioning

### Efficiency

- **Create annotation:** O(1) -- append to assertion vector
- **Read annotations:** O(A) where A = number of visible assertions
- **Materialize document:** O(N + A) where N = nodes, A = assertions
- **Edit survival:** O(0) -- annotations survive automatically, no work needed

Gold's approach was equivalent (structural span attachment). We match it.

### New Code Locations

- `src/server/server.rs` -- add `AssertionStore` field, new annotation methods
- `src/server/otree_crdt.rs` -- keep for backward compat, add migration path
- `src/ent/content.rs` -- already has all needed types
- `src/server/transport/protocol.rs` -- update annotation wire format
- `src/server/transport/dispatch.rs` -- wire new annotation operations

---

<a id="phase-5"></a>
## 7. Phase 5: Position-Level Recorder Planting

### The Problem

Currently recorders are planted at the **edition level** -- one `SensorCrum`
per edition. When one word changes in a 100K-character document, we check ALL
fossils watching that edition, even if they only care about a different part.

Gold planted recorders at the **Loaf level** -- individual positions within
the O-tree. A recorder watching position 500-600 would not be triggered by
a change at position 10000.

### The Solution

Create `SensorCrum` nodes at the chunk level (256 entries each, matching our
chunk store granularity):

```
Edition (one BertCrum)
  +-- Chunk 0: entries 0-255     (SensorCrum)
  +-- Chunk 1: entries 256-511   (SensorCrum)
  +-- Chunk 2: entries 512-767   (SensorCrum)
  +-- ...
```

When a recorder is planted with `watched_content` covering positions 500-600:
1. Determine which chunks overlap (chunk 1 and chunk 2)
2. Install the fossil ID in those chunks' SensorCrums
3. Hoist upward through the canopy tree

When content changes at position 10000 (chunk 39):
1. Walk the Sensor canopy from chunk 39's crum upward
2. Only fossils installed in chunk 39 (or ancestors) are triggered
3. Skip all fossils in chunks 0-38 and 40+

### Efficiency Impact

| Scenario | Edition-Level (now) | Position-Level (after) |
|---|---|---|
| Small edit (1 chunk) | Check all fossils for edition | Check fossils in 1 chunk |
| Large edit (all chunks) | Check all fossils | Check all fossils (same) |
| Permission change | Check all fossils | Check all fossils (same) |

For the common case (small edit touching 1-2 chunks in a 400-chunk
document), this is a **~200x reduction** in recorder checking.

### Implementation

- New: `BackfollowEngine::plant_recorder_at_positions(edition_id, fossil_id, positions)`
- New: Per-chunk SensorCrum tree nested under the edition's BertCrum
- Modify: `trigger_planted_recorders` to walk from changed chunks, not whole edition
- Modify: `recorder_plant` to accept position ranges

### New Code Locations

- `src/edition/backfollow.rs` -- per-chunk sensor crums, position-level planting
- `src/server/server.rs` -- modify trigger/plant methods
- `src/edition/canopy.rs` -- nested canopy tree (chunk crums under edition crum)

---

<a id="phase-6"></a>
## 8. Phase 6: Persistent Agenda with Crash Recovery

### The Problem

Our agenda is drained synchronously in `recorder_process()`. If the server
crashes mid-match, all in-flight work is lost. Gold's agenda was a persistent
task queue that survived crashes -- `AgendaItem::step()` was called repeatedly
until completion, and items were stored on disk between steps.

### The Solution

Serialize agenda state into the manifest:

```rust
enum AgendaItemSnapshot {
    Matcher { fossil_id: u64, query: RecorderQuery, target_edition_id: Option<u64> },
    RecorderTrigger { fossil_id: u64, element_json: String, source_edition_id: Option<u64>, is_direct: bool },
    Hoister { phase: HoisterPhaseSnapshot },
}

struct AgendaSnapshot {
    items: Vec<AgendaItemSnapshot>,
}
```

On restore:
1. Deserialize `AgendaSnapshot` from manifest
2. Reconstruct `AgendaItem` objects from snapshots
3. Resume stepping until agenda is empty

### Sequencer Ordering

Gold used `Sequencer` to guarantee "plant recorders before matching." We need
equivalent ordering:

```
recorder_plant_and_match(edition_id, fossil_id, content)
  |-- Phase 1: plant_recorder (install in canopy + fingerprint index)
  |-- Phase 2: schedule_matcher (find existing matches)
  +-- Order: Phase 1 MUST complete before Phase 2 starts
```

Add a `Sequencer` struct to `recorder.rs`:
```rust
struct Sequencer {
    first: Option<Box<dyn AgendaItem>>,
    rest: Option<Box<dyn AgendaItem>>,
}
```

### Comparison to Gold

| Aspect | Gold | Xudanu (after) |
|---|---|---|
| Agenda persistence | Via SnarfPacker (object-level) | Via manifest (JSON serialization) |
| Crash recovery | Automatic (re-read Turtle, step agenda) | Rebuild agenda from manifest on restart |
| Sequencer ordering | Persistent, survives crash | In-memory, rebuilt from snapshot |
| Step granularity | One item per step | One item per step (same) |

Gold's approach was more granular (every consistent block triggered agenda
drain), but our approach is simpler and achieves the same crash-recovery
guarantee at the checkpoint boundary.

### New Code Locations

- `src/edition/recorder.rs` -- `Sequencer`, agenda serialization
- `src/persist/manifest.rs` -- `AgendaSnapshot` in manifest
- `src/server/server.rs` -- serialize/deserialize agenda on checkpoint/restore

---

<a id="phase-7"></a>
## 9. Phase 7: Full Canopy Walk Triggering

### The Problem

Phases 2A and 5 add canopy-based filtering, but the primary lookup is still
the blake3 HashMap. The canopy is only used as a post-filter. Gold's approach
was to use the canopy as the **primary** lookup mechanism -- walk the tree,
pruning subtrees whose flags don't match, and only check fossils in surviving
subtrees.

### The Solution

Replace the triggering path:

```
BEFORE (Phase 2):
  blake3 lookup -> O(K) permission post-filter -> O(K) Jaccard check

AFTER (Phase 7):
  canopy walk from changed position -> prune subtrees -> only check surviving crums
  (blake3 HashMap remains as a fast path for content-based queries)
```

The triggering algorithm:
1. Get the changed position's SensorCrum (from Phase 5)
2. Walk the canopy tree upward, collecting recorders at each level
3. At each level, check the BertProp against the fossil's authority requirements
4. Only return fossils that pass both canopy filtering and content matching

### When Each Lookup Wins

| Scenario | blake3 HashMap | Canopy Walk | Winner |
|---|---|---|---|
| Content change, few recorders | O(1) lookup, O(K) filter | O(D*B) walk | **HashMap** for small K |
| Content change, many recorders | O(1) lookup, O(K) filter | O(D*B) walk | **Canopy** for large K |
| Permission change, no content change | O(1) lookup returns nothing | O(D*B) walk finds affected recorders | **Canopy** (only option) |
| New edition created | O(1) lookup | O(D*B) walk | **HashMap** (content-based) |

**Hybrid approach:** Use blake3 HashMap for content changes, canopy walk for
permission changes. This covers both cases optimally.

### New Code Locations

- `src/server/server.rs` -- add canopy-walk triggering path alongside HashMap
- `src/edition/canopy.rs` -- `walk_for_recorders(crum, finder)` method

---

<a id="phase-8"></a>
## 10. Phase 8: Frontend Updates

### 8A. Expose New Features to React Frontend

| Feature | Wire Operation | UI Change |
|---|---|---|
| WaitForConsequences | New WebSocket op | "Wait for results" button on recorder panel |
| WaitForWrite | New WebSocket op | "Saved" indicator in toolbar |
| Link types | Modify `LinkCreate` | Type selector in link creation dialog |
| Persistent subscriptions | Automatic (server-side) | No change (subscriptions survive refresh) |
| Structural annotations | New annotation API | Annotations survive edits automatically |

### 8B. Gold-Inspired UI Additions

| Feature | Description | Priority |
|---|---|---|
| PlaceHolder fill detection | Async result slots that fill in live | Medium |
| Inter-span links | Position-level link targeting | Medium |
| Version genealogy | Tree graph visualization | Low |
| Recorder status panel | Active fossils, pending results, trigger count | Medium |
| Canopy inspector | Developer tool showing canopy tree + flags | Low |

---

<a id="dependencies"></a>
## 11. Implementation Priority and Dependencies

```
Phase 1 (wiring) --------------------------------------------------+
  1A. F5 ConsequenceTracker    [DONE]                               |
  1B. F4 RecorderHoister       [IN PROGRESS]                        |
  1C. F1 Link types            [pending]                            |
                                                                     |
Phase 2 (architectural) <- depends on Phase 1 ---------------------+
  2A. Canopy post-filter                                            |
  2B. Hoister in recorder_plant                                     |
  2C. Persistent fossils                                            |
                                                                     |
Phase 3 (Gold fidelity) <- independent -----------------------------+
  3A. Tumbler decomposition                                         |
  3B. CrossSpace endorsements                                       |
                                                                     |
Phase 4 (annotations) <- independent ------------------------------+
  4A. AssertionStore migration                                      |
                                                                     |
Phase 5 (position-level) <- depends on Phase 2 -------------------+
  5A. Per-chunk SensorCrums                                         |
                                                                     |
Phase 6 (crash recovery) <- depends on Phase 2C ------------------+
  6A. Persistent agenda                                             |
  6B. Sequencer ordering                                            |
                                                                     |
Phase 7 (canopy triggering) <- depends on Phase 5 -----------------+
  7A. Full canopy walk                                              |
  7B. Hybrid HashMap + canopy triggering                            |
                                                                     |
Phase 8 (frontend) <- depends on Phases 1-4 ----------------------+
  8A. New wire operations                                           |
  8B. Gold-inspired UI                                              |
```

### Estimated Task Counts

| Phase | Tasks | New Tests | Risk | Duration |
|---|---|---|---|---|
| 1B | 3-4 | 4-6 | Low | 1 session |
| 1C | 2-3 | 2-3 | Low | 0.5 session |
| 2A | 2-3 | 5-8 | Medium | 1 session |
| 2B | 2-3 | 3-4 | Medium | 0.5 session |
| 2C | 4-5 | 4-6 | Medium | 1 session |
| 3A | 3-4 | 3-5 | Low | 1 session |
| 3B | 3-4 | 4-6 | Medium | 1 session |
| 4 | 8-10 | 10-15 | High | 2-3 sessions |
| 5 | 5-7 | 6-10 | High | 2 sessions |
| 6 | 4-6 | 5-8 | Medium | 1-2 sessions |
| 7 | 3-5 | 4-6 | Medium | 1 session |
| 8 | 5-8 | N/A | Low | 1-2 sessions |

---

<a id="pros-cons"></a>
## 12. Pros, Cons, and Tradeoffs

### blake3 Content Addressing

| Pros | Cons |
|---|---|
| O(1) content lookup (vs Gold's O(N) tree walk) | 32-byte keys are larger than Gold's pointer references |
| Automatic deduplication across all editions | Requires recomputing hash on every element access |
| Integrity verification on read | No built-in ordering (must use separate index) |
| Cross-server content identity (same hash = same content) | Hash collisions theoretically possible (2^256 space makes this negligible) |

### Hybrid HashMap + Canopy Approach

| Pros | Cons |
|---|---|
| Best of both: O(1) for content, O(D*B) for permissions | Two systems to maintain and keep in sync |
| Content-based triggering is instant | Permission-only changes still need canopy walk |
| Graceful degradation: HashMap works without canopy | Complexity: two code paths for triggering |

### Persistent Agenda (vs Gold's SnarfPacker)

| Pros | Cons |
|---|---|
| Much simpler implementation (JSON manifest vs binary disk format) | Coarser granularity (crash recovery at checkpoint boundary, not per-operation) |
| Human-readable, debuggable | No object-level persistence |
| Works with our existing chunk store | Larger manifests at scale |
| blake3 integrity verification built in | |

### AssertionStore Annotations

| Pros | Cons |
|---|---|
| Annotations survive edits automatically | More complex than byte offsets |
| Versioned (branch-aware via TraceView) | Requires migration of existing annotations |
| Structural: attach to spans, not positions | Materialization cost on read |
| Matches Gold's design | API change for frontend |

### Position-Level Recorder Planting

| Pros | Cons |
|---|---|
| ~200x reduction in recorder checks for small edits | More SensorCrum nodes to manage |
| Matches Gold's granularity | Complexity: nested canopy tree |
| Enables precise "watch this paragraph" queries | Memory overhead for per-chunk crums |

---

<a id="risks"></a>
## 13. Risk Assessment

### High Risk

| Risk | Phase | Mitigation |
|---|---|---|
| AssertionStore migration breaks existing annotations | 4 | Keep OtreeAnnotation path, dual-write during migration |
| Per-chunk canopy tree increases memory significantly | 5 | Benchmark first; start with 1024-entry chunks if needed |
| Persistent agenda serialization format evolves badly | 6 | Version the snapshot format, add migration path |

### Medium Risk

| Risk | Phase | Mitigation |
|---|---|---|
| Canopy post-filter performance at scale | 2A | Benchmark with 10K+ fossils before committing |
| Hoister state machine edge cases | 2B | Comprehensive tests for each phase transition |
| CrossRegion endorsement queries are slow | 3B | Benchmark against flat BTreeSet baseline |

### Low Risk

| Risk | Phase | Mitigation |
|---|---|---|
| Link types protocol change breaks clients | 1C | Default to empty vec, backward compatible |
| Tumbler addressing misunderstood | 3A | Start with wire protocol, add UI later |
| Frontend updates reveal missing server features | 8 | Phase 8 after all server phases complete |

---

<a id="appendix"></a>
## 14. Appendix: Gold Architecture Reference

### Gold's Two-Canopy System

```
Bert Canopy (permissions/endorsements)
  +-> Each edition gets a BertCrum
  +-> Flags: publicClub, otherClubs, otherEndorsements, isNotPartializable
  +-> Used for: northward (past) walks in backfollow
  +-> PropFinder checks flags at each node, prunes subtrees

Sensor Canopy (recorders/watchers)
  +-> Each edition gets a SensorCrum
  +-> Stores: Vec<RecorderFossil> in myBackfollowRecorders
  +-> Flags: IS_SENSOR_WAITING (has any recorder)
  +-> Used for: southward (present/future) walks
  +-> RecorderHoister propagates recorders upward
```

### Gold's Agenda Sequencing

```
scheduleDelayedBackfollow(fossil, region):
  1. rAgents = Agenda::make()
  2. oroot->storeRecordingAgents(fossil, rAgents)  // walk O-tree, plant recorders
  3. matcher = Matcher::make(oroot, finder, fossil)
  4. Sequencer::make(rAgents, matcher)->schedule()
     // FIRST: propagate recorder flags through canopy
     // THEN:  find existing matches via H-tree walk

propChanged(edition):
  1. changer = PropChanger::make(bertCrum)          // propagate permission changes
  2. checker = SouthRecorderChecker::make(...)       // walk southward for recorders
  3. Sequencer::make(changer, checker)->schedule()
     // FIRST: update Bert canopy
     // THEN:  check recorders with new permissions
```

### Gold's Step Granularity

| AgendaItem | Steps | Behavior |
|---|---|---|
| Matcher | 1 (one-shot) | Walks entire HTree path, schedules RecorderTriggers |
| RecorderTrigger | 1 (one-shot) | Records one matching element into fossil's trail |
| SouthRecorderChecker | 1 (one-shot) | Walks O-tree southward, triggers matching recorders |
| RecorderHoister | Multi-step | Hoists recorders one canopy level per step |
| PropChanger | Multi-step | Propagates flags one canopy level per step |
| Sequencer | Multi-step | Steps first until done, then steps rest |

### Gold's Persistence Model

- **SnarfPacker**: Object-level persistence with copy-on-write disk blocks
- **Consistent blocks**: `BEGIN_CONSISTENT(N)` / `END_CONSISTENT` = nested transactions
- **Agenda stepping**: Runs at end of every consistent block (transaction-driven)
- **Turtle**: Root persistent object holding the root Agenda
- **Reanimation**: Fossils loaded from disk on demand via `becomeStub()` / `secretRecorder()`
- **Crash recovery**: Read Turtle, step agenda items until empty

### File References (Gold C++ Source)

| Component | File | Lines |
|---|---|---|
| CanopyCrum | `src/server/canopyx.hxx` | 113-138 |
| SensorCrum recordingAgent | `src/server/canopyx.cxx` | 1103-1130 |
| RecorderHoister | `src/server/tcludex.hxx` | 436-473 |
| RecorderHoister step | `src/server/tcludex.cxx` | 648-719 |
| Matcher | `src/server/tcludex.hxx` | 190-228 |
| SouthRecorderChecker | `src/server/tcludex.hxx` | 756-823 |
| scheduleDelayedBackfollow | `src/server/brange3x.cxx` | 1208-1256 |
| propChanged (Sequencer) | `src/server/brange3x.cxx` | 544-616 |
| SnarfPacker consistent | `src/disk/packerx.cxx` | 692-798 |
| AgendaItem | `src/disk/turtlex.hxx` | 67-145 |
| Sequencer | `src/disk/turtlex.hxx` | 231-277 |
| Turtle (root) | `src/disk/turtlex.hxx` | 281-353 |
| waitForConsequences | `src/server/nkernelx.cxx` | 3782-3810 |
| waitForWrite | `src/server/nkernelx.cxx` | 3813-3835 |

### File References (Xudanu Rust Source)

| Component | File |
|---|---|
| RecorderSystem, Fossil, Agenda | `src/edition/recorder.rs` |
| BackfollowEngine | `src/edition/backfollow.rs` |
| Canopy (Bert + Sensor) | `src/edition/canopy.rs` |
| RecorderHoister | `src/edition/hoist.rs` |
| ContentAddressIndex | `src/edition/content_address.rs` |
| ChunkStore | `src/persist/chunk_store.rs` |
| Edition chunks | `src/persist/edition_chunks.rs` |
| AssertionStore | `src/ent/content.rs` |
| WaitDetector, ConsequenceTracker | `src/server/wait_barrier.rs` |
| Server (recorder methods) | `src/server/server.rs` lines 5561-5724 |
| Wire protocol | `src/server/transport/protocol.rs` |
| Dispatch layer | `src/server/transport/dispatch.rs` |
| React frontend | `web/app/src/` |
