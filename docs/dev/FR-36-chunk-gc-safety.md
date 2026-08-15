# FR-36: Chunk GC Safety for Root Chunk Persistence

## Overview

Make chunk garbage collection (GC) safe — and correct — now that the
root chunk tree (FR: v1.5.0 chunk-rooted persistence) is the primary
persistence format. GC must never delete a chunk reachable from any
restorable checkpoint, and must resume reclaiming true orphans once
the root-chunk protection set is complete.

**Status**: Specification
**Severity**: Critical (data-loss class)
**Effort**: 1-2 days (walker + tests + legacy reconciliation)

## Background

### How GC worked before v1.5.0

`gc_orphaned_chunks` (server.rs) builds a **protection set** of hashes
before deleting anything:

1. In-memory work refs — `collect_work_hashes()` for every live work,
   club `work_root`, and standalone edition
2. `manifest.json` — all `Option<[u8; 32]>` section hashes inserted
   into the set
3. `manifest_v*.json` backups — works/clubs/standalone of every
   historical backup manifest, so prior checkpoints stay restorable

Anything on disk not in the set is deleted as an orphan. The design
rule (enforced by the existing CHECKLIST comment) is **skip GC rather
than risk deleting a valid chunk** — any collection error aborts the
entire pass.

### What v1.5.0 changed

Checkpoints no longer write `manifest.json`. They write an immutable
`ServerRootChunk` tree into the chunk store plus a 116-byte
`root_manifest.json` pointer (`current_root_hash`, `previous_root_hash`).

The GC still consults `manifest.json` and `manifest_v*.json`. Two
failure modes result:

| State | Behavior | Consequence |
|---|---|---|
| `manifest.json` **stale** (pre-migration file remains) | Protection set built from an old manifest | **Live root chunks not in the stale set are DELETED** |
| `manifest.json` **absent** (fresh install or post-cleanup) | `read_manifest` fails → GC aborts (skip path) | No GC at all; orphans accumulate forever |

The first mode is not hypothetical: during v1.5.0 testing, GC deleted
a freshly-migrated demo root tree mid-session ("Chunk GC: removed 5
orphaned chunks" — they were the new root chunks).

### Why the in-memory refs are not enough

The in-memory work refs cover *current* edition chunks, but the root
chunk tree references additional chunk classes GC never sees:

- `ServerRootChunk` itself (+ the previous checkpoint's root)
- Works/Clubs index chunks and WorkState/ClubState chunks
- Admin, SystemClubs, StandaloneEditions chunks
- `reconcile_store_hash` (federation state)
- All section chunks (links, social, blob_metas, content_address,
  historical_authors, annotations, fossil_snapshots, federation)

Any of these swept by GC breaks restore.

## Design

### 1. Root-tree hash walker (new, in `persist/root_chunk.rs`)

```rust
pub fn collect_root_tree_hashes(
    root_hash: &[u8; 32],
    store: &ChunkStore,
) -> Result<HashSet<[u8; 32]>, RootChunkError>
```

Walks one root tree, returning **every** chunk hash needed to restore
from it:

1. `root_hash` (the ServerRootChunk itself)
2. Every `Option<[u8; 32]>` field of `ServerRootChunk` — all 16,
   enumerated exhaustively so future fields fail a test, not a server
3. `works_index_hash` → WorksIndexChunk → each
   `work_state_hash` → WorkStateChunk → `current_edition_hash` +
   every `history` edition hash (each expanded via
   `collect_edition_hashes` — the EditionRootChunk/EntryChunk/
   ProvenanceChunk subtree)
4. `clubs_index_hash` → ClubIndexChunk → each `club_state_hash` →
   ClubStateChunk → `work_root` via `collect_work_hashes`
5. `standalone_editions_hash` → each `edition_ref_hash` expanded

Errors propagate — the caller decides to skip GC.

### 2. Root history protection (in `gc_orphaned_chunks`)

Read `root_manifest.json` from the data dir:

- Protect the full tree of `current_root_hash`
- Protect the full tree of `previous_root_hash` **if present** — the
  fallback root must survive (this is our crash-recovery layer; a
  two-deep chain is the current retention policy, see §Future)
- If `root_manifest.json` exists but any tree walk fails → **skip GC
  entirely** (log at warn), matching the existing safety rule

When `root_manifest.json` is absent (fresh pre-first-checkpoint dir),
the root-chunk stage contributes nothing and GC proceeds from the
other refs.

### 3. Legacy reconciliation

The existing manifest.json/manifest_v*.json protection blocks remain,
but:

- Missing files are normal now, not an error — drop the "skip GC"
  behavior tied to a missing primary manifest when a valid
  `root_manifest.json` tree was already protected (currently the
  missing-manifest path aborts the whole pass; that starves GC on
  every fresh-install dir)
- After a migration (`migrate_manifest`) or once the operator has
  verified several checkpoints, the legacy files can be deleted; GC
  then relies solely on the root-tree protection set

### 4. Checklist enforcement

The ServerRootChunk field checklist moves from comment-enforced to
**test-enforced** (see Test Plan). A new field added without walker
coverage fails CI.

## Test Plan

Unit tests (server.rs tests module):

1. **`gc_preserves_root_chunk_tree`** — checkpoint → record all
   root-tree hashes → run GC → assert every hash still
   `chunk_exists`
2. **`gc_preserves_previous_root_tree`** — checkpoint twice → GC →
   assert both root trees survive (current + previous)
3. **`gc_skips_on_corrupt_root_tree`** — checkpoint, corrupt a
   referenced sub-chunk file → GC returns 0 removed and deletes
   nothing
4. **`gc_still_removes_true_orphans`** — write an unreferenced chunk
   → checkpoint → GC → assert exactly that chunk was removed and the
   root tree survives
5. **`walker_covers_all_root_fields`** — construct a ServerRootChunk
   with every hash field set to a distinct dummy chunk; assert
   `collect_root_tree_hashes` returns every one (fails when a field
   is added to the struct without walker coverage)
6. **`gc_works_without_manifest_json`** — fresh dir, no
   manifest.json anywhere → checkpoint → GC runs (removed == 0) and
   root tree survives

Integration: existing `annotation_survives_checkpoint_and_gc` and
`root_chunk_immutability_simulation` continue to pass unchanged.

## Future (out of scope)

- **Retention policy** — previous-previous and older roots currently
  survive only if still referenced; a policy knob (keep N root
  generations) belongs in GC once safety is proven
- **unknown_tag chunks** — 1,000+ chunks in live data whose tag byte
  is neither 0x50/0x52/0x4A; identify their writer before GC treats
  them as reclaimable
- **WAL-aware GC** — chunks referenced only by un-truncated WAL
  entries; today's checkpoint-then-GC ordering already covers this

## Relationship to Other FRs

- Builds on v1.5.0 chunk-rooted persistence (root_manifest.json,
  ServerRootChunk tree)
- Pairs with CHUNK_FORMAT.md / chunk-schema.json — the walker's field
  enumeration is the normative "what the root tree references" list
- `reconcile_store_hash` (chunked federation state) must be in the
  protection set or federation restore breaks
