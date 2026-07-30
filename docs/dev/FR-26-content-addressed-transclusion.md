# FR-26: Content-Addressed Transclusion

> **Status:** In development
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

### Phase 1: Hash Verification

Store `content_hash: [u8; 32]` alongside the range in `RangeElement::Transclusion`.

When resolving:
1. Fetch current source text at `(start, end)`
2. Compute BLAKE3 of the fetched text
3. Compare with stored hash
4. If match → show "✓ verified"
5. If mismatch → show "⚠ source changed since transclusion" (still show current text)

### Phase 2: Version Pinning

Store `source_revision: u64` at transclusion creation time.

When resolving:
1. Fetch current text → verify hash
2. If hash mismatch → offer "view original" from revision history
3. Revision history already exists (FR-23)

### Phase 3: Blob Snapshots

Store transclusion content as a BLAKE3-addressed blob at creation time.

Benefits:
- Transclusion survives source deletion (blob persists)
- Exact-match retrieval without revision lookup
- Content-addressed, not position-addressed

### Phase 4: Spanfish (future)

Lightweight span-level reference that Gold/Green can interoperate with.
Depends on XCP adoption.

## Acceptance Criteria

- [ ] Transclusion stores BLAKE3 hash + source revision
- [ ] Resolution verifies hash, shows verification status
- [ ] If source changed, user can view original from revision history
- [ ] Blob snapshot ensures transclusion survives source deletion
- [ ] All changes survive checkpoint/restore
- [ ] Tests: hash verification, source changed, source deleted
