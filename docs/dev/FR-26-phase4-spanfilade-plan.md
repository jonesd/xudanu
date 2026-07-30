# FR-26 Phase 4: Spanfilade Implementation Plan

> **Status:** Planning (not started)
> **Estimated effort:** 3-6 months (full), 4-6 weeks (spanfish subset)
> **Risk:** High — breaks CRDT compatibility, requires enfilade data structure
> **Prerequisite:** XCP adoption for cross-server interop

## What Spanfilade Is

Gold's spanfilade is an **enfilade variant** that stores content at the
I-stream (insertion stream) level — a layer below character offsets.

### How it differs from our current model

| Aspect | Xudanu (range-based) | Gold (spanfilade) |
|---|---|---|
| Content reference | Character positions (start, end) | I-stream position (insertion order) |
| Survives restructuring | No — positions shift, span migration needed | Yes — positions are structural |
| Version history | Separate revision store | All versions coexist in enfilade |
| Transclusion of deleted content | Only via blob snapshot (Phase 3) | Native — enfilade preserves everything |
| Copy-on-write | No (full snapshot per revision) | Yes (structural sharing between versions) |

### What FR-26 Phases 1-3 already provide

Phases 1-3 give **80% of the practical value**:
- Hash verification (Phase 1) — detects if source changed
- Version pinning (Phase 2) — retrieves original from revision history
- Blob snapshots (Phase 3) — survives source deletion

### What only spanfilade provides

- Transclusions that survive **arbitrary restructuring** (not just inserts/deletes)
- **Multiple versions visible simultaneously** (no separate revision store)
- **Efficient cross-version queries** via canopy flag pruning
- **Structural sharing** between revisions (no full snapshots)

---

## Implementation Approaches

### Option A: Full Enfilade (3-6 months)

Reimplement Gold's enfilade data structure as the content model.

**What exists:**
- `ent/` module with crum/HTree machinery (htree.rs)
- Canopy flag pruning (canopy.rs)
- Space algebra (xn_region.rs, mapping.rs)
- Version DAG (dagwood.rs)
- Trace positions (trace.rs)

**What needs building:**

1. **I-stream content layer** (~8 weeks)
   - New data structure below character offsets
   - Content addressed by insertion order, not position
   - Insert/delete at I-stream level
   - Translate between I-stream positions and character positions
   - Estimated: 2000-3000 lines Rust

2. **Spanfilade enfilade** (~6 weeks)
   - Loaf-based tree with structural sharing
   - Splits/displacements for content insertion
   - Backfollow queries for finding all transclusion sites
   - Estimated: 1500-2000 lines Rust

3. **Transclusion migration** (~4 weeks)
   - Replace `RangeElement::Transclusion` with I-stream reference
   - Update all resolution code
   - Update wire protocol
   - Update checkpoint/restore
   - Estimated: 500-1000 lines Rust

4. **CRDT compatibility layer** (~4 weeks)
   - The CRDT produces complete editions, not deltas through a version tree
   - Need to extract deltas from editions and apply them to the enfilade
   - Or: run CRDT and enfilade side-by-side, reconcile on materialization
   - Estimated: 1000-1500 lines Rust

5. **Testing** (~4 weeks)
   - Property tests for I-stream positioning
   - Round-trip tests for transclusion creation/resolution/deletion
   - Concurrent edit tests
   - Cross-version query tests
   - Estimated: 2000+ lines of tests

**Total: ~26 weeks (~6 months)**

**Risks:**
- **CRDT incompatibility** — the O-tree CRDT assumes range-based positions. Spanfilade's I-stream positions would require a fundamentally different merge strategy.
- **Performance regression** — enfilade queries are O(log N) but with higher constant factors than range-based lookup.
- **Memory overhead** — structural sharing saves disk but increases in-memory complexity.
- **Maintenance burden** — two parallel content models (O-tree for CRDT, enfilade for spanfilade) is hard to maintain.

### Option B: Spanfish Subset (4-6 weeks)

Implement a **lightweight span reference** that gives some spanfilade properties without the full enfilade.

**What it would provide:**
- Content-addressed span references (not just ranges)
- Backfollow queries (find all transclusions referencing content X)
- Cross-version content matching via fingerprint

**What it would NOT provide:**
- Multiple versions visible simultaneously
- Efficient structural sharing
- Arbitrary restructuring survival

**How:**
1. Add a new `RangeElement::SpanfishRef` variant that stores:
   - Content fingerprint (BLAKE3 of content, not just position)
   - Source work + revision
   - Backfollow index entry

2. Build a backfollow index that maps content fingerprints to all
   spanfish references that point at them — using the existing
   `BackfollowEngine` (already in the codebase at `backfollow.rs`)

3. When content is edited, the backfollow index finds all affected
   spanfish references and updates them — similar to span migration
   but based on content matching, not position deltas.

**Effort breakdown:**

| Piece | Time | Lines |
|---|---|---|
| SpanfishRef variant + wire protocol | 3 days | 200 |
| Backfollow index integration | 1 week | 500 |
| Content-fingerprint matching | 3 days | 300 |
| Resolution path (content-addressed) | 1 week | 400 |
| Checkpoint/restore | 2 days | 100 |
| Tests | 1 week | 500 |
| Documentation | 2 days | 200 |
| **Total** | **~4 weeks** | **~2200** |

**Risks:**
- Content-fingerprint matching may have false positives (same text in different contexts)
- Still doesn't give the "all versions simultaneously" property
- May not be worth the complexity over Phases 1-3

### Option C: Wait and Collaborate (0 weeks)

**Recommendation:** Defer until Roger Gregory's input.

Roger knows the enfilade better than anyone. If Gold and Xudanu are
going to interoperate via XCP, the spanfilade implementation should
be informed by what Gold actually needs from us.

Phases 1-3 give us:
- Hash verification (tamper detection)
- Version pinning (original content retrieval)
- Blob snapshots (source deletion survival)

These cover the practical use cases. The remaining spanfilade properties
(multi-version coexistence, structural sharing) are primarily relevant
for deep hypertext research, not user-facing features.

---

## Recommendation

**Option C (Wait) for now.** Here's why:

1. **Phases 1-3 cover practical needs** — transclusions don't break
2. **CRDT incompatibility** is a serious risk that needs design work
3. **Roger's input** could save months of work (he built the original)
4. **XCP adoption** determines whether spanfilade even matters for interop
5. **Other features have higher ROI** — editor fixes, search, mobile

If spanfilade becomes necessary later:
1. Start with Option B (spanfish, 4 weeks)
2. Evaluate whether it provides enough value
3. Only commit to Option A (full enfilade, 6 months) if Roger
   collaborates on the design

---

## Cost-Benefit Summary

| Approach | Time | Risk | Value | ROI |
|---|---|---|---|---|
| Phase 1-3 (done) | 2 days | Low | 80% of practical value | Excellent |
| Spanfish (Phase 4a) | 4 weeks | Medium | 90% of practical value | Good |
| Full enfilade (Phase 4b) | 6 months | High | 100% | Only if collaborating |

---

## Appendix: Existing Infrastructure

### Already built (usable for spanfilade)

| Module | What it provides | Lines |
|---|---|---|
| `ent/htree.rs` | Crum/HTree nodes, backfollow walking | 470 |
| `edition/canopy.rs` | Bert canopy, flag pruning, crum data | 400 |
| `ent/dagwood.rs` | Version DAG, trace views | 350 |
| `ent/trace.rs` | Trace positions (version addresses) | 200 |
| `edition/mapping.rs` | Space algebra (region/displacement) | 600 |
| `backfollow.rs` | Backfollow engine (content reuse index) | 300 |

### Would need building

| Piece | Priority | Difficulty |
|---|---|---|
| I-stream content model | P1 (full) | Very hard |
| Spanfilade enfilade | P1 (full) | Hard |
| Spanfish reference type | P1 (subset) | Medium |
| Backfollow → transclusion bridge | P2 | Medium |
| CRDT ↔ enfilade reconciliation | P1 (full) | Very hard |
| Cross-version queries | P2 | Hard |
| Structural sharing | P2 | Hard |
