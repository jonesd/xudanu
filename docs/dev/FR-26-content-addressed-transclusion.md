# FR-26: Content-Addressed Transclusion

> **Status:** Phases 1-3 complete, Phase 4 planned
> **Depends on:** FR-11 (Compound Documents), FR-17 (Storage Architecture)
> **Motivation:** Address Roger Gregory's concern that current range-based
> transclusion is "aggressively finite" — breaks when source is edited,
> can't reference deleted content, no version pinning.

## Problem

Current transclusion stores `(source_work_id, char_start, char_end)`.
This is fragile:

1. If source is edited, char positions shift → span migration needed
2. If source passage is deleted, transclusion breaks entirely
3. No way to reference a specific version of the source
4. No way to detect if the transcluded content has changed since creation

## Solution

Add content hash and source revision to transclusion references.

### Phase 1: Hash Verification — DONE

Store `content_hash: [u8; 32]` alongside the range in `RangeElement::Transclusion`.

When resolving:
1. Fetch current source text at `(start, end)`
2. Compute BLAKE3 of the fetched text
3. Compare with stored hash
4. If match → verified
5. If mismatch → source changed since transclusion (warning logged)

**Tests:** 4 (hash computation, mismatch detection, backward compat, checkpoint survival)

### Phase 2: Version Pinning — DONE

Store `source_revision: u64` at transclusion creation time.

When resolving:
1. Fetch current text → verify hash
2. If hash mismatch → retrieve original from revision history
3. If original matches stored hash → show pinned (original) version
4. If revision unavailable → show current with warning

**Tests:** 1 (version pinning retrieves original on source edit)

### Phase 3: Blob Snapshots — DONE

Store transclusion content as a BLAKE3-addressed blob at creation time.

When resolving:
1. If source work exists → resolve normally (live content)
2. If source work deleted → retrieve from immutable blob snapshot
3. If no blob and no source → transclusion fails gracefully

**Tests:** 1 (blob snapshot survives source deletion)

### What Phases 1-3 Provide

| Scenario | Behavior |
|---|---|
| Source unchanged | Hash matches, content shows normally |
| Source edited | Hash mismatch detected, original retrieved from revision history |
| Source heavily restructured | Same — hash verification catches any change |
| Source deleted | Content retrieved from immutable blob snapshot |
| Server restart | Hash + revision survive checkpoint/restore |

This covers **80% of the practical value** of spanfilade: transclusions
don't break when sources change or disappear.

### Phase 4: Spanfish (future, not started)

**What it would add on top of Phases 1-3:**

Phases 1-3 handle **resolution** (what to show when a transclusion is opened).
Spanfish adds **discovery** (finding all affected transclusion sites).

| Capability | Phases 1-3 | Spanfish adds |
|---|---|---|
| Source edited → detect mismatch | Yes | Also finds ALL 50 docs that transclude this passage |
| Source deleted → show blob | Yes | Same |
| "Who references this passage?" | Work-level only | Content-fingerprint-level (across versions) |
| "What breaks if I edit this?" | No way to know | Backfollow index shows all dependents |
| Push updates to affected docs | No | Notify all transclusion sites when source changes |

**How spanfish would work:**

1. New `RangeElement::SpanfishRef` variant storing content fingerprint
2. Backfollow index maps fingerprints → all transclusion sites
3. When content edited, backfollow finds all affected references
4. Uses existing `BackfollowEngine` (already in codebase)

**Effort:** ~4 weeks, ~2200 lines

**Recommendation:** Defer until:
- Roger Gregory confirms it's needed for Gold interop, OR
- Users report managing hundreds of cross-referencing documents

Phases 1-3 cover practical use cases. Spanfish is research-grade.

**Full implementation plan:** See `FR-26-phase4-spanfilade-plan.md`

### Phase 5: Full Enfilade (future, not started)

Reimplement Gold's I-stream/V-stream content model. Provides:

- Multiple versions visible simultaneously (no separate revision store)
- Efficient structural sharing between revisions (copy-on-write)
- Arbitrary restructuring survival (I-stream positions, not character offsets)

**Effort:** 3-6 months minimum
**Risk:** High — breaks CRDT compatibility
**Prerequisite:** Roger Gregory's collaboration on design

**Only worth pursuing if:**
1. Roger collaborates on the design (he built the original)
2. XCP adoption makes cross-implementation spanfilade interop necessary
3. Phases 1-3 prove insufficient for real-world use

---

## Acceptance Criteria

- [x] Transclusion stores BLAKE3 hash + source revision
- [x] Resolution verifies hash, shows verification status
- [x] If source changed, original version retrievable from revision history
- [x] Blob snapshot ensures transclusion survives source deletion
- [x] All changes survive checkpoint/restore
- [x] Tests: hash verification, source changed, source deleted (6 tests total)
