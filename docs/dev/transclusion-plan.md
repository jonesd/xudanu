# Endorsement-Based Transclusion Detection Plan

## Overview

Connect the existing (but disconnected) BackfollowEngine, canopy, recorder, and ENT
components into a working endorsement-based transclusion detection system with full
C++ parity including reactive queries.

**Current state:** All components are ported but disconnected. Server dual-writes to
both its own TransclusionIndex and BackfollowEngine's internal one. H-tree traversal
is dead code (h_crum never set). Endorsement filters are carried but never checked.
FindSharedRegions does naive paragraph matching. Recorder system is stubs.

**Target state:** Single consistent transclusion engine with canopy-filtered H-tree
queries, automatic endorsement stamps, reactive recorder system, and fingerprint-based
shared region detection.

---

## Phase A: Unify Transclusion Queries & Fix Consistency

**Goal:** Eliminate dual-write, make BackfollowEngine the single source of truth for
all transclusion queries, fix stale entry accumulation.

### A.1: Remove Server's separate `transclusion_index`

- Remove `transclusion_index: TransclusionIndex` from Server struct (server.rs:70)
- All transclusion queries route through `self.backfollow`
- Remove two-tier fallback logic in `find_transcluders()` (server.rs:1552-1579)
- Remove two-tier fallback in `find_works_for_content()` (server.rs:1581-1590)

### A.2: Change `element_fingerprint_to_work` to multi-valued

- Change type from `HashMap<[u8;32], BeId>` to `HashMap<[u8;32], HashSet<BeId>>`
- Move this field into BackfollowEngine (it belongs with the transclusion index)
- Update all write sites (create_work, work_revise, edition_rebind, federation_import)
- Update read site (federation_fetch_by_fingerprint)
- from_snapshot() rebuilds from all works

### A.3: Fix BackfollowEngine consistency

- **create_work**: Currently calls `backfollow.register_work()` which creates a NEW
  Work object (line 523-524 in server.rs). Fix: pass the same Work that was inserted
  into `self.works`, ensuring the BackfollowEngine's copy is identical.
- **work_revise**: Currently calls `backfollow.update_work()` which does O(n)
  `rebuild_index()`. Fix: implement incremental update — remove old edition's entries
  from the internal TransclusionIndex, then add new edition's entries. No full rebuild.
- **unregister_edition**: Currently removes from storage but NOT from the internal
  TransclusionIndex (backfollow.rs:211-216). Fix: clean up index entries.
- **Stale entries**: Server's old `transclusion_index` accumulated entries on revise
  without cleanup. Since we're removing it, this is solved. But BackfollowEngine's
  incremental update must handle it.

### A.4: Implement incremental `update_work()` in BackfollowEngine

Replace current `update_work()` (backfollow.rs:205-209):

```rust
fn update_work(&mut self, work_id: u64, old_edition: &Edition, new_work: Work) {
    // 1. Remove old edition's entries from transclusion_index
    let old_elem = RangeElement::work(work_id);
    self.transclusion_index.unregister_work(old_edition, &old_elem);
    
    // 2. Add new edition's entries
    let new_elem = RangeElement::work(work_id);
    self.transclusion_index.register_work(new_work.current_edition(), &new_elem);
    
    // 3. Update work storage
    self.work_storage.insert(work_id, new_work);
    
    // 4. Update fingerprint-to-works index
    // (remove old fingerprints, add new ones)
}
```

Add `unregister_edition()` / `unregister_work()` to TransclusionIndex that removes
entries for specific elements.

### A.5: Wire all Server operations through BackfollowEngine

- `create_work()` -> `backfollow.register_work()` (already called, fix the duplicate Work creation)
- `work_revise()` -> `backfollow.update_work()` (replace rebuild with incremental)
- `store_edition()` -> `backfollow.register_edition()` (currently only writes to Server's own index)
- `create_link()` -> `backfollow.register_link()` (currently only writes to Server's own index)
- `federation_import_works()` -> `backfollow.register_work()`
- Snapshot restore -> rebuild BackfollowEngine from all works/editions

### A.6: Update snapshot/persistence

- `from_snapshot()` must rebuild BackfollowEngine's storage + indexes from WorkSnapshot data
- `to_snapshot()` already captures all works, so restore just needs to re-register them
- Rebuild link index as part of restore

### A.7: Tests

- Unit: BackfollowEngine incremental update preserves correct index state
- Unit: TransclusionIndex unregister removes only the specified entries
- Unit: Multi-work fingerprint index returns ALL works containing content
- Integration: create two works with shared text, verify find_transcluders finds both
- Integration: revise a work, verify stale entries are removed, new entries are correct
- Regression: all existing tests pass with unified query path

### Files modified
- `src/server/server.rs` — remove transclusion_index field, remove element_fingerprint_to_work, update all registration/query methods
- `src/edition/backfollow.rs` — add incremental update_work, move fingerprint_to_works here
- `src/edition/transclusion.rs` — add unregister_edition/unregister_work methods
- `src/edition/persistent.rs` — update from_snapshot/to_snapshot

---

## Phase B: H-Tree Connection + Endorsement Stamps

**Goal:** Connect the H-tree for versioned ancestry queries. Define well-known
endorsement types and auto-stamp content. Wire endorsement filtering into queries.

### B.1: Define well-known endorsement types

Following C++ granmapx.cxx lines 203-237, define system endorsement tokens:

```rust
pub const ENDORSE_TEXT: i64 = 0;
pub const ENDORSE_HYPERLINK: i64 = 1;
pub const ENDORSE_HYPERREF: i64 = 2;
pub const ENDORSE_SINGLE_REF: i64 = 3;
pub const ENDORSE_MULTI_REF: i64 = 4;
```

At Server init, call `use_endorsement_flag()` for each to allocate flag bits.
This mirrors C++ `CanopyCrum::useEndorsementFlags()` (granmapx.cxx line 238).

### B.2: Auto-endorse content on create/revise

When Server creates a work or revises it, scan the edition's elements and add
endorsement stamps matching the element types (Text -> ENDORSE_TEXT, HyperLink ->
ENDORSE_HYPERLINK, etc.). This mirrors C++ `BeWork::endorse()` (brange2x.cxx lines
432-445).

### B.3: Set h_crum during edition registration

When BackfollowEngine registers an edition with a parent, create an H-tree node
linking the child to the parent. Currently `compute_join()` is called but the result
is discarded (backfollow.rs:184). Fix: actually use the joined crum to form the
parent-child H-tree edge.

This requires BackfollowEngine to own a DagWood (for allocating TracePositions).
Add a DagWood field to BackfollowEngine.

Implementation:
1. Allocate a TracePosition from DagWood for the new edition
2. Create HUpperCrumData with the new trace position
3. Add the parent's HUpperCrumData as an o_parent
4. Store the HUpperCrumData in EditionMeta.h_crum

### B.4: Wire version history in Server

On `work_revise()`:
- Old edition becomes parent in H-tree
- New edition is registered as child with `register_edition_with_parent()`
- This creates the version ancestry chain

On `create_work()`:
- First edition registered without parent (root of its H-tree)

### B.5: Wire endorsement filtering into queries

Fix `BackfollowEngine::find_transcluders()` to actually apply endorsement filtering
via the PropFinder + canopy flag bits. Currently the TransclusionQuery's
endorsements_filter is carried but never checked in the index lookup.

### B.6: Fix find_transcluders_with_backfollow trail results

Currently the trail is built but discarded (backfollow.rs:308-315). The method
reconstructs final_results from index_results, ignoring the H-tree traversal in
the trail. Fix: return results from the trail, which includes transitive matches
found via H-tree walking.

### B.7: Add read permission filtering

Following C++ `BeWork::canBeReadBy()` (brange2x.cxx lines 121-136) and
`visibleEndorsements()` (brange3x.cxx lines 487-500):

Add `can_be_read_by()` check in transclusion query results. The query's
`permissions_filter` should encode the querying user's club memberships.
Results are filtered to only include works the user can read.

Update Server's `find_transcluders()` and `find_works_for_content()` to accept
a session_id and construct queries with the session's authority.

### B.8: Tests

- Unit: Well-known endorsement flag bits are allocated correctly
- Unit: Auto-endorsement stamps Text elements with ENDORSE_TEXT flag
- Unit: H-tree parent-child link formed on revise
- Unit: find_transcluders_with_backfollow returns H-tree traversal results
- Unit: Endorsement filter correctly prunes non-matching results
- Unit: Read permission filter excludes works the user can't read
- Integration: Create work A with text, create work B with same text, verify
  A can find B as transcluder (and vice versa)
- Integration: Create private work, verify it doesn't appear in another user's
  transclusion results
- Integration: Revise work, verify H-tree ancestry chain is correct

### Files modified
- `src/edition/backfollow.rs` — add DagWood field, fix register_edition_with_parent,
  fix find_transcluders_with_backfollow trail usage, wire endorsement filtering
- `src/edition/endorsement.rs` — add well-known endorsement type constants, from_token()
- `src/server/server.rs` — auto_endorse_work(), pass session authority to queries,
  set up endorsement flags at init, wire version history on revise
- `src/ent/htree.rs` — may need updates for HPart implementation on EditionMeta

---

## Phase C: Fingerprint-Based Shared Regions

**Goal:** Replace naive paragraph text matching in FindSharedRegions with
element-fingerprint comparison using the unified transclusion index.

### C.1: Replace FindSharedRegions dispatch handler

Current (dispatch.rs:477-575): Splits text into paragraphs, does exact string comparison.

The existing `Edition::find_content_shared_regions()` (edition.rs:540-582) already
does element-level comparison with run detection and returns contiguous matching runs.
The Server already has `find_shared_regions()` (server.rs:1625-1639) which delegates
to this method.

**Simplest fix**: change the dispatch handler to call `srv.find_shared_regions(work_a, work_b)`
instead of reimplementing text matching inline.

### C.2: Add filter_text support via transclusion index

When `filter_text` is provided:
1. Create a Text RangeElement from the filter text
2. Compute its blake3 fingerprint
3. Look up in the BackfollowEngine's transclusion index
4. Find which works/editions contain that exact text element
5. For positional matching, find the element's position within each work's edition

This replaces the current `String::find()` approach with content-addressable lookup.

### C.3: Update web UI if needed

The web UI's Compare view may need updates to handle element-level positions instead
of character positions. Evaluate after C.1 and C.2.

### C.4: Tests

- Unit: find_content_shared_regions detects shared elements correctly
- Integration: Compare two works with shared text, verify shared regions found
- Integration: Compare two works with no shared text, verify empty results
- Integration: filter_text lookup via transclusion index finds correct works
- Regression: existing compare view still works

### Files modified
- `src/server/transport/dispatch.rs` — replace FindSharedRegions handler
- `src/server/server.rs` — may add fingerprint-based shared region methods
- `static/index.html` — may need position format updates

---

## Phase D: Reactive Recorder System

**Goal:** Implement the C++ reactive transclusion query system where RecorderFossils
monitor for future matching content via the SensorCanopy.

This is the most architecturally complex phase. The C++ uses a two-canopy design:

1. **BertCanopy** (northward/past): Indexes existing content by properties.
   When a transclusion query is initiated, the system walks northward through
   the H-tree, filtering by BertCanopy flag bits.

2. **SensorCanopy** (southward/future): Records active queries. When content
   properties change (new endorsements, new works, permission changes), the
   system walks southward through the SensorCanopy to find matching recorders.

The C++ query flow:
1. Create a RecorderFossil with the query's filters and authority
2. Plant recording agents in the SensorCanopy (for future matches)
3. Walk the H-tree northward filtered by BertCanopy (for past matches)
4. TrailBlazer deduplicates overlapping results

### D.1: Implement `Matcher::step()`

Current stub (recorder.rs:202-205): Immediately marks complete.

Real implementation walks the H-tree from the starting edition's h_crum, using
delayed_store_backfollow to find matching editions. For each match, creates a
RecorderTrigger that records the result into the fossil.

Matcher needs a reference to BackfollowEngine. Use `Rc<RefCell<BackfollowEngine>>`
or pass engine reference at schedule time.

### D.2: Implement `RecorderTrigger::step()`

Current stub (recorder.rs:242-244): Immediately marks complete.

Real implementation checks if the element matches the fossil's filters (accepts()
and matches_filters()), then records the result into the fossil if it passes.

### D.3: Wire SensorCanopy for reactive notifications

When content properties change (work created, revised, endorsed, permission changed):

1. Compute the property delta (old BertProp vs new BertProp)
2. Walk southward through the SensorCanopy
3. At each SensorCrum, check for stored RecorderFossils
4. For matching recorders, schedule a RecorderTrigger

This mirrors C++ `BeEdition::propChanged()` (brange3x.cxx lines 530-616) and
`SouthRecorderChecker` (tcludex.cxx lines 1141-1160).

### D.4: Implement RecorderFossil lifecycle

C++ pattern (tcludex.cxx lines 350-473):
- Fossil is created with query parameters and authority
- Fossil can be "reanimated" to reconstruct a ResultRecorder with captured permissions
- Fossil tracks reference count and agenda count
- When both reach zero, fossil becomes "extinct" and is cleaned up

Wire into Server:
- `recorder_create(query)` -> creates fossil in RecorderSystem
- `recorder_results(fossil_id)` -> returns accumulated results
- `recorder_extinguish(fossil_id)` -> marks fossil extinct, stops monitoring
- Add wire protocol operations for recorder lifecycle

### D.5: Wire property change propagation

Add a method to BackfollowEngine called when a work/edition's properties change:

```rust
fn on_prop_changed(&mut self, edition_id: u64, old_prop: &BertProp, new_prop: &BertProp) {
    // 1. Update EditionMeta's prop
    // 2. Walk SensorCanopy to find matching recorders
    // 3. Schedule RecorderTriggers for matching recorders
}
```

Call this from Server when:
- Work is created (new prop)
- Work is revised (prop may change)
- Work is endorsed/retracted
- Work's read_club/edit_club changes (publish/unpublish)

### D.6: Add wire protocol operations

Add to protocol.rs:
- `RecorderCreate { query: RecorderQueryPayload }` -> returns fossil_id
- `RecorderResults { fossil_id: u64 }` -> returns Vec<RecordedResult>
- `RecorderExtinguish { fossil_id: u64 }` -> extinguishes fossil
- `RecorderList` -> lists active fossils

Add corresponding codec.rs and dispatch.rs handlers.

### D.7: Tests

- Unit: Matcher::step() triggers H-tree walk and records results
- Unit: RecorderTrigger::step() records matching element into fossil
- Unit: SensorCanopy propagation fires recorders on property change
- Unit: RecorderFossil lifecycle (create, accumulate, extinguish, cleanup)
- Unit: Fossil deduplication (same result recorded once)
- Unit: Fossil endorsement filtering (only matching endorsements trigger)
- Integration: Create recorder for "Text" endorsement, create matching work,
  verify recorder fires with result
- Integration: Create recorder, then revise a work to add matching content,
  verify reactive notification
- Integration: Extinguish recorder, verify no further notifications

### Files modified
- `src/edition/recorder.rs` — implement Matcher::step(), RecorderTrigger::step(),
  wire into RecorderSystem
- `src/edition/backfollow.rs` — add on_prop_changed(), wire SensorCanopy
- `src/server/server.rs` — call on_prop_changed() from all mutation methods,
  expose recorder lifecycle operations
- `src/server/transport/protocol.rs` — add recorder operation types
- `src/server/transport/codec.rs` — add recorder encoding
- `src/server/transport/dispatch.rs` — add recorder handlers

---

## Phase E: ENT Version DAG Integration

**Goal:** Connect the ENT version DAG to enable version-aware transclusion queries
and full partial ordering semantics.

### E.1: Set trace_position on EditionMeta

When an edition is registered in BackfollowEngine:
- Allocate a TracePosition from the DagWood
- Store it in EditionMeta.trace_position
- Use it for version ordering comparisons

### E.2: Bridge Edition/Work to ENT's content layer

Map Edition operations to ENT assertions:
- Each element in an edition becomes a `SetSpanText` assertion at the edition's
  TracePosition
- Revising a work creates new assertions at a new TracePosition
- The DagWood's partial ordering determines which assertions are visible

This enables:
- `is_le(edition_a, edition_b)` — is A historically before B?
- `TraceView` — what content is visible at a given point in version history?
- Conflict detection — when two branches set different text for the same span

### E.3: Version-aware transclusion queries

Use ENT's `is_le` to determine:
- Whether a transcluding content is derived from (descended from) the original
- Whether two works share a common ancestor
- Whether content has been modified since it was transcluded

### E.4: Tests

- Unit: trace_position allocated correctly on edition registration
- Unit: is_le() correctly orders editions by creation time
- Unit: TraceView shows correct visible content for a given reference point
- Integration: Create work, revise it, verify version ancestry
- Integration: Fork and merge works, verify DagWood merge semantics

### Files modified
- `src/edition/backfollow.rs` — allocate TracePosition on registration
- `src/ent/dagwood.rs` — may need updates for edition-awareness
- `src/ent/content.rs` — map Edition operations to assertions
- `src/server/server.rs` — wire ENT into create/revise flows

---

## Execution Order & Dependencies

```
Phase A (Unify Storage)
    |
    +---> Phase C (Fingerprint Shared Regions) [can parallel with B]
    |
    v
Phase B (H-Tree + Endorsements)
    |
    v
Phase D (Reactive Recorders) [requires B]
    |
    v
Phase E (ENT Integration) [requires B + D]
```

Phase C depends only on Phase A (unified index). It can be done in parallel with B.

---

## Risk Assessment

| Risk | Mitigation |
|------|-----------|
| `Rc<RefCell<>>` cycles in reactive system | Use weak references for back-pointers |
| Performance regression from canopy walks | Canopy flag-based pruning is O(log n); benchmark with 10k works |
| Incremental update bugs (stale entries) | Property-based testing: register, update, verify index state |
| H-tree traversal visiting same crum multiple times | Hash cache (already implemented in htree.rs) |
| DagWood not thread-safe | Current server is single-threaded; address when adding async |
| RecorderFossil memory leaks | Reference counting + purge_extinct() already implemented |

---

## Success Criteria

After all phases:
- [ ] find_transcluders() uses canopy-filtered H-tree traversal (not flat index scan)
- [ ] Endorsement stamps auto-assigned on content creation
- [ ] Read permission filtering applied to all transclusion results
- [ ] FindSharedRegions uses element fingerprints (not text matching)
- [ ] RecorderFossils detect future matching content reactively
- [ ] H-tree version ancestry tracks work revisions
- [ ] ENT DagWood enables version-aware queries
- [ ] No dual-write — BackfollowEngine is single source of truth
- [ ] All existing tests pass (994 lib, 192 integration)
- [ ] New test coverage for each phase (unit + integration)
