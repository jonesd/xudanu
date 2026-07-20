# FR-23: Revisions — Detailed Implementation Spec

> Builds on `docs/dev/versioning-design.md` (Approach C decision).
> This doc is the concrete implementation plan: wire ops, data
> structures, backend methods, frontend components, migration, and
> test plan. A developer should be able to implement directly from
> this document.

## Scope

**In scope:**
- Revision metadata (description, notable flag, author, timestamp)
- Wire ops for listing, loading, and describing revisions
- Workspace Timeline lens (FR-18 Phase 5)
- Revision diff UI (reusing ComparePanel)
- Non-destructive rollback
- Revision tumblers (`xan://server.work.r2`)
- Span migration for links/annotations across revisions

**Out of scope (deferred):**
- CRDT undo window (Approach F — Phase B of versioning design)
- Branching / forking (use "create new work from revision" instead)
- Cross-server revision resolution (depends on federation, deferred per cross-server-resolution.md)

## What Already Exists (Don't Rebuild)

| Component | Location | Status |
|---|---|---|
| Revision storage in chunk store | `persist/edition_chunks.rs::WorkChunkRef.history` | ✅ Ships |
| Load revision by number | `persist/edition_chunks.rs::work_load_revision()` | ✅ Ships |
| Diff two editions | `server.rs::find_shared_regions()`, `work_diff_regions` op | ✅ Ships |
| `revision_count` on works | `edition/work.rs` | ✅ Ships |
| `revision_history: BTreeMap<u64, Edition>` in-memory | `edition/work.rs` | ✅ Ships |
| Manifest persistence of revision refs | `WorkChunkRef.history` serialized to manifest | ✅ Ships |

## What's Missing (Build This)

### 1. Revision metadata struct

Currently a revision is just an `Edition` stored in the chunk store.
We need metadata alongside it: description, notable flag, author,
timestamp, content hash.

```rust
// New file: src/persist/revision_meta.rs

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct RevisionMeta {
    /// Sequential revision number (0-based, matches edition_history key)
    pub revision_id: u64,

    /// Parent revision (None for the first revision)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub parent: Option<u64>,

    /// Unix timestamp (seconds) when this revision was created
    pub created_at: u64,

    /// Identity (club ID) that created this revision
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub created_by: Option<BeId>,

    /// Author-supplied description ("Refined wording, added section on...")
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,

    /// Author-marked as notable (publishing event, major revision)
    #[serde(default)]
    pub is_notable: bool,

    /// BLAKE3 hash of the edition's canonical text (for dedup + verification)
    #[serde(default, skip_serializing_if = "String::is_empty")]
    pub content_hash: String,

    /// Character count of the edition (quick stat without loading full edition)
    #[serde(default)]
    pub char_count: u64,

    /// Auto-detected change summary vs. parent ("+123 chars, -45 chars")
    #[serde(default, skip_serializing_if = "String::is_empty")]
    pub change_summary: String,
}
```

### 2. Storage: revisions section in manifest

Add a new section to the manifest alongside existing sections:

```rust
// In persist/manifest.rs

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, Default)]
pub struct RevisionsSection {
    /// Map: work_id → list of revision metadata (indexed by revision_id)
    #[serde(default, skip_serializing_if = "std::collections::HashMap::is_empty")]
    pub by_work: HashMap<BeId, Vec<RevisionMeta>>,
}
```

Added to `ManifestData`:
```rust
pub struct ManifestData {
    // ...existing fields...
    #[serde(default)]
    pub revisions: RevisionsSection,
}
```

Backward compatible: old manifests deserialize with empty `revisions`.

### 3. Wire ops

Six new ops, all JSON-only (binary protocol returns MissingPayload):

| Opcode | Op name | Request | Response |
|---|---|---|---|
| `0x0C01` | `work_revisions_list` | `{work_id: N}` | `Vec<RevisionSummary>` |
| `0x0C02` | `work_text_at_revision` | `{work_id: N, revision_id: N}` | `{text: "..."}` |
| `0x0C03` | `work_revision_describe` | `{work_id: N, revision_id: N, description: "..."}` | void |
| `0x0C04` | `work_revision_mark_notable` | `{work_id: N, revision_id: N, notable: bool}` | void |
| `0x0C05` | `work_revision_rollback` | `{work_id: N, target_revision_id: N}` | new revision_id |
| `0x0C06` | `work_revision_diff` | `{work_id: N, rev_a: N, rev_b: N}` | `DiffPayload` (same as work_diff_regions) |

#### Wire request structs

```rust
// In protocol.rs

WorkRevisionsList {
    work_id: BeId,
},
WorkTextAtRevision {
    work_id: BeId,
    revision_id: u64,
},
WorkRevisionDescribe {
    work_id: BeId,
    revision_id: u64,
    description: String,
},
WorkRevisionMarkNotable {
    work_id: BeId,
    revision_id: u64,
    notable: bool,
},
WorkRevisionRollback {
    work_id: BeId,
    target_revision_id: u64,
},
WorkRevisionDiff {
    work_id: BeId,
    rev_a: u64,
    rev_b: u64,
},
```

#### Response types

```rust
// Reuses existing ResponseValue variants where possible

// For work_revisions_list:
ResponseValue::RevisionListResult(Vec<RevisionMeta>)

// For work_text_at_revision:
ResponseValue::TextResult(String)

// For work_revision_describe / mark_notable:
ResponseValue::Void

// For work_revision_rollback:
ResponseValue::Id(new_revision_id)

// For work_revision_diff:
ResponseValue::WorkDiffRegionsResult(existing_payload)
```

### 4. Backend server methods

```rust
// In server.rs

/// List all revisions for a work with metadata.
/// Loads from in-memory revision_history + manifest revision metadata.
/// Back-fills metadata for revisions that don't have it yet (lazy migration).
pub fn work_revisions_list(
    &self,
    session_id: SessionId,
    work_id: BeId,
) -> Result<Vec<RevisionMeta>, ServerError>;

/// Get the text content of a specific revision.
/// Loads the edition from chunk store via work_load_revision().
pub fn work_text_at_revision(
    &self,
    session_id: SessionId,
    work_id: BeId,
    revision_id: u64,
) -> Result<String, ServerError>;

/// Set or update the description on a revision.
pub fn work_revision_describe(
    &mut self,
    session_id: SessionId,
    work_id: BeId,
    revision_id: u64,
    description: String,
) -> Result<(), ServerError>;

/// Mark a revision as notable (or unmark).
pub fn work_revision_mark_notable(
    &mut self,
    session_id: SessionId,
    work_id: BeId,
    revision_id: u64,
    notable: bool,
) -> Result<(), ServerError>;

/// Non-destructive rollback: creates a new revision equal to target.
/// The target revision's edition is loaded and becomes the new current.
pub fn work_revision_rollback(
    &mut self,
    session_id: SessionId,
    work_id: BeId,
    target_revision_id: u64,
) -> Result<u64, ServerError>;

/// Diff two revisions. Loads both editions, calls existing find_shared_regions.
pub fn work_revision_diff(
    &self,
    session_id: SessionId,
    work_id: BeId,
    rev_a: u64,
    rev_b: u64,
) -> Result<WorkDiffResult, ServerError>;
```

#### Key implementation details

**`work_revisions_list`:**
```rust
fn work_revisions_list(&self, session_id, work_id) -> Result<Vec<RevisionMeta>> {
    self.ensure_can_read(session_id, work_id)?;
    let ws = self.works.get(&work_id).ok_or(...)?;
    let count = ws.work.revision_count();
    let mut result = Vec::with_capacity(count as usize + 1);

    // For each revision 0..count (inclusive of current):
    for rev_id in 0..=count {
        // Check if we have metadata in the manifest
        let meta = self.revision_meta(work_id, rev_id);
        result.push(meta);
    }
    Ok(result)
}
```

**`work_text_at_revision`:**
```rust
fn work_text_at_revision(&self, session_id, work_id, revision_id) -> Result<String> {
    self.ensure_can_read(session_id, work_id)?;
    let ws = self.works.get(&work_id).ok_or(...)?;

    if revision_id == ws.work.revision_count() {
        // Current edition — return directly
        return Ok(ws.work.edition().to_text());
    }

    // Load from chunk store
    let chunk_ref = &ws.chunk_ref.as_ref().ok_or(...)?;
    let edition = work_load_revision(chunk_ref, revision_id, &self.chunk_store)?;
    Ok(edition.to_text())
}
```

**`work_revision_rollback`:**
```rust
fn work_revision_rollback(&mut self, session_id, work_id, target_revision_id) -> Result<u64> {
    self.ensure_can_edit(session_id, work_id)?;

    // Load the target edition
    let target_text = self.work_text_at_revision(session_id, work_id, target_revision_id)?;

    // Create a new edition with the target text
    let new_edition = Edition::from_text_batched(&target_text);

    // Revise (bypasses grab — same as work_set_text)
    let author_club = self.resolve_author_club(session_id);
    let new_rev = self.revise_work(work_id, session_id, new_edition, author_club)?;

    // Set metadata: description + notable
    let meta = RevisionMeta {
        revision_id: new_rev,
        parent: Some(ws.work.revision_count() - 1),
        created_at: now,
        created_by: author_club,
        description: Some(format!("Rolled back to revision {}", target_revision_id)),
        is_notable: true,
        content_hash: blake3(&target_text),
        char_count: target_text.len() as u64,
        change_summary: format!("Rollback to r{}", target_revision_id),
    };
    self.insert_revision_meta(work_id, meta);

    Ok(new_rev)
}
```

### 5. Auto-recording revision metadata on revise

The most important change: **every call to `revise_work` should
auto-record revision metadata.** This is the lazy migration path —
revisions created after this change have full metadata; older ones
get back-filled on demand.

```rust
// In revise_work(), after the existing logic:

let meta = RevisionMeta {
    revision_id: old_number, // the revision that was just pushed to history
    parent: if old_number > 0 { Some(old_number - 1) } else { None },
    created_at: Self::current_timestamp_secs(),
    created_by: author_club,
    description: None, // set by user later
    is_notable: false, // auto-detected later
    content_hash: blake3(&old_edition.to_text()),
    char_count: old_edition.to_text().len() as u64,
    change_summary: String::new(), // computed on demand
};
self.insert_revision_meta(work_be_id, meta);
```

### 6. Auto-detecting "notable" revisions

After each revise, compute a change summary and auto-mark as notable
if the change is large enough:

```rust
fn compute_change_summary(
    old_text: &str,
    new_text: &str,
) -> (String, bool) {
    let old_len = old_text.len();
    let new_len = new_text.len();
    let delta = new_len as i64 - old_len as i64;

    // Use the existing find_shared_regions to compute actual overlap
    let shared = /* call find_content_shared_regions */;
    let shared_chars: usize = shared.iter().map(|r| r.1 - r.0).sum();

    let changed_pct = if old_len > 0 {
        (1.0 - shared_chars as f64 / old_len as f64) * 100.0
    } else {
        100.0
    };

    let summary = if delta >= 0 {
        format!("+{} chars, {}% changed", delta, changed_pct as u32)
    } else {
        format!("{} chars, {}% changed", delta, changed_pct as u32)
    };

    // Auto-notable: > 20% changed or > 500 chars changed
    let is_notable = changed_pct > 20.0 || delta.abs() > 500;

    (summary, is_notable)
}
```

### 7. Frontend: Client API

```typescript
// In crdt_sync.ts

interface RevisionMeta {
    revision_id: number;
    parent?: number;
    created_at: number;
    created_by?: number;
    description?: string;
    is_notable: boolean;
    content_hash?: string;
    char_count: number;
    change_summary?: string;
}

async workRevisionsList(workId: number): Promise<RevisionMeta[]> {
    const resp = await this.sendRequest("work_revisions_list", { work_id: workId });
    return extractValue(resp) as RevisionMeta[];
}

async workTextAtRevision(workId: number, revisionId: number): Promise<string> {
    const resp = await this.sendRequest("work_text_at_revision", {
        work_id: workId,
        revision_id: revisionId,
    });
    const val = extractValue(resp);
    return (val as { text?: string }).text || "";
}

async workRevisionDescribe(
    workId: number, revisionId: number, description: string
): Promise<void> {
    await this.sendRequest("work_revision_describe", {
        work_id: workId, revision_id: revisionId, description,
    });
}

async workRevisionMarkNotable(
    workId: number, revisionId: number, notable: boolean
): Promise<void> {
    await this.sendRequest("work_revision_mark_notable", {
        work_id: workId, revision_id: revisionId, notable,
    });
}

async workRevisionRollback(
    workId: number, targetRevisionId: number
): Promise<number> {
    const resp = await this.sendRequest("work_revision_rollback", {
        work_id: workId, target_revision_id: targetRevisionId,
    });
    return extractValue(resp) as number;
}

async workRevisionDiff(
    workId: number, revA: number, revB: number
): Promise<WorkDiffResult> {
    const resp = await this.sendRequest("work_revision_diff", {
        work_id: workId, rev_a: revA, rev_b: revB,
    });
    return extractValue(resp) as WorkDiffResult;
}
```

### 8. Frontend: Timeline lens component

New component: `web/app/src/components/RevisionTimeline.tsx`

```
┌──────────────────────────────────────────────────┐
│ TIMELINE                          [Compare ▾]    │
│ ──────────────────────────────────────────────── │
│                                                  │
│  ★ v23  2023-11-02  ted                         │
│     Refined wording and added provenance         │
│     +123 chars, 15% changed                      │
│     [View] [Diff vs v22] [Roll back]             │
│                                                  │
│    v22  2023-08-15  ted                          │
│     Added section on two-way links               │
│     +450 chars, 8% changed                       │
│     [View] [Diff] [Notable]                      │
│                                                  │
│  ★ v17  2019-06-18  ted                          │
│     (no description)                             │
│     +1.2K chars, 35% changed                     │
│     [View] [Diff]                                │
│                                                  │
│    v1   1965-07-01  ted                          │
│     Original publication                         │
│     +4.5K chars                                  │
│     [View] [Diff]                                │
│                                                  │
│ ──────────────────────────────────────────────── │
│ [Save current as revision...]                    │
└──────────────────────────────────────────────────┘
```

**Component props:**
```typescript
interface RevisionTimelineProps {
    workId: number;
    currentRevisionId: number;
    onRevisionsChange: () => void; // refresh after describe/rollback
    client: CrdtSyncClient | null;
}
```

**Features:**
- Vertical list of revisions, newest first
- Notable revisions (★) highlighted with amber background
- Each revision shows: version, date, author, description, change summary
- Actions: View (loads text at revision), Diff (compare two), Roll back
- "Save current as revision" button at bottom — triggers explicit revision save with description prompt
- "Mark as notable" toggle per revision
- Compare mode: select two revisions → shows diff using existing ComparePanel

### 9. Frontend: Revision diff integration

The Timeline lens has a "Compare" button that switches to diff mode:
- User picks two revisions from the timeline
- Frontend calls `workRevisionDiff(workId, revA, revB)`
- Response uses the same `WorkDiffResult` shape as existing `work_diff_regions`
- Rendered by the existing `ComparePanel` component (no changes needed)

### 10. Frontend: "Save revision" action

Added to the workspace document action bar:

```tsx
<button
    className="ws-action-btn"
    onClick={handleSaveRevision}
    title="Save current state as a named revision"
>
    Save revision
</button>
```

```typescript
const handleSaveRevision = useCallback(async () => {
    const description = prompt("Revision description (optional):", "");
    if (description === null) return; // cancelled
    // The revise has already happened via CRDT; this just adds metadata
    // to the latest revision.
    if (workBeId !== null && clientRef.current) {
        const revisions = await clientRef.current.workRevisionsList(workBeId);
        const latest = revisions[revisions.length - 1];
        if (description) {
            await clientRef.current.workRevisionDescribe(
                workBeId, latest.revision_id, description
            );
        }
        await clientRef.current.workRevisionMarkNotable(
            workBeId, latest.revision_id, true
        );
    }
}, [workBeId, clientRef]);
```

### 11. Revision tumblers

Tumbler format: `xan://server.work_id.r{revision_id}`

**Backend resolver changes:**
- Parse the `.rN` suffix from tumblers
- If present, load that revision instead of current
- Add `/api/public/work/{id}/revision/{rev}` HTTP endpoint

**Frontend Cite action:**
- When citing, offer "current" or "specific revision" via dropdown
- If revision selected, cite includes `.r{N}` suffix

**Pinned transclusions:**
- When creating a transclusion, offer "latest" or "pinned to revision"
- Pinned transclusions store the revision in the CrossServerRef
- Resolution loads the specific revision (immutable)

### 12. Migration strategy

**No data migration required.** Existing revisions work as-is.

**Lazy metadata back-fill:**
- `work_revisions_list` checks if metadata exists for each revision
- If not, creates a minimal `RevisionMeta` with:
  - `revision_id`: known
  - `created_at`: 0 (unknown — can't reconstruct)
  - `description`: None
  - `is_notable`: false
  - `content_hash`: computed on-the-fly from the edition text
  - `char_count`: computed from the edition text
- The back-filled metadata is persisted to the manifest on next checkpoint

**New revisions (created after this feature ships):**
- `revise_work` auto-records full metadata
- Timestamp and author are accurate

### 13. Test plan

#### Backend unit tests

```rust
#[test]
fn test_revisions_list_empty_work() {
    // New work has 1 revision (the initial empty edition)
    // work_revisions_list returns 1 entry
}

#[test]
fn test_revisions_list_after_edit() {
    // Create work, edit 3 times
    // work_revisions_list returns 4 entries (0, 1, 2, 3)
    // Each has correct revision_id, timestamp, char_count
}

#[test]
fn test_text_at_revision() {
    // Create work with text "hello"
    // Edit to "hello world"
    // work_text_at_revision(work, 0) == "hello"
    // work_text_at_revision(work, 1) == "hello world"
}

#[test]
fn test_revision_describe() {
    // Create work, revise
    // work_revision_describe(work, 0, "initial draft")
    // work_revisions_list[0].description == "initial draft"
}

#[test]
fn test_revision_mark_notable() {
    // Create work, revise
    // work_revision_mark_notable(work, 0, true)
    // work_revisions_list[0].is_notable == true
}

#[test]
fn test_revision_rollback() {
    // Create work with text A, revise to B, rollback to A
    // Current text should be A again
    // revision_count should be 3 (A, B, A-copy)
    // work_revisions_list should have 3 entries
}

#[test]
fn test_revision_diff() {
    // Create work with "hello world"
    // Revise to "hello universe"
    // work_revision_diff(work, 0, 1) shows changed region
}

#[test]
fn test_revision_auto_notable() {
    // Create work with 1000 chars
    // Revise with 500 new chars (> 20% change)
    // Auto-detected as notable
}

#[test]
fn test_back_fill_metadata() {
    // Load server with pre-FR-23 manifest (revisions without metadata)
    // work_revisions_list back-fills metadata
    // Checkpoint persists the back-filled data
}
```

#### Frontend tests

```typescript
describe("RevisionTimeline", () => {
    it("renders revisions newest first");
    it("highlights notable revisions");
    it("shows change summary per revision");
    it("View button loads text at revision");
    it("Diff button opens compare panel");
    it("Rollback creates new revision");
    it("Save revision prompts for description");
    it("Mark notable toggles the flag");
});
```

#### Integration tests

```
1. Create work → edit 5 times → verify 6 revisions in list
2. Describe revision 3 → verify description persists across checkpoint
3. Rollback to revision 2 → verify text matches revision 2
4. Diff revision 1 vs 4 → verify changed regions
5. Cite revision 3 → verify tumbler includes .r3
6. Open cited tumbler → verify loads revision 3 text
```

## Implementation Phases

### Phase A: Backend wire ops + metadata (3–4 days)

**Deliverables:**
- [ ] `RevisionMeta` struct + `RevisionsSection` in manifest
- [ ] 6 wire ops registered (opcodes, codec, dispatch)
- [ ] 6 server methods implemented
- [ ] Auto-recording metadata in `revise_work`
- [ ] Auto-detecting notable revisions
- [ ] Back-fill logic in `work_revisions_list`
- [ ] Backend unit tests (9 tests above)
- [ ] Backend integration test: create → edit → list → load → diff → rollback
- [ ] Verify backward compat: old manifest loads, back-fills lazily

### Phase B: Frontend client API (half day)

**Deliverables:**
- [ ] `RevisionMeta` TypeScript interface
- [ ] 6 client methods in `crdt_sync.ts`
- [ ] Client unit tests for each method

### Phase C: Timeline lens UI (2–3 days)

**Deliverables:**
- [ ] `RevisionTimeline.tsx` component
- [ ] Wire into workspace bottom area as a lens
- [ ] Vertical revision list with metadata display
- [ ] Notable revision highlighting
- [ ] "View" action — loads text at revision in read-only mode
- [ ] "Save revision" action in workspace header
- [ ] "Mark notable" toggle
- [ ] "Add description" inline editing

### Phase D: Diff UI integration (1–2 days)

**Deliverables:**
- [ ] Compare mode in Timeline lens
- [ ] Revision picker (select two)
- [ ] Calls `workRevisionDiff` → reuses `ComparePanel`
- [ ] Side-by-side rendering with shared region highlights

### Phase E: Rollback UI (half day)

**Deliverables:**
- [ ] "Roll back to this revision" action in Timeline
- [ ] Confirmation dialog
- [ ] Success feedback (new revision created)

### Phase F: Revision tumblers (3–4 days)

**Deliverables:**
- [ ] Tumbler parser handles `.rN` suffix
- [ ] `work_resolve_tumbler` loads specific revision
- [ ] HTTP endpoint `/api/public/work/{id}/revision/{rev}`
- [ ] Frontend Cite action offers "specific revision" option
- [ ] Pinned transclusions (store revision in CrossServerRef)
- [ ] Tests: cite revision, open citation, verify immutability

**Total: ~10–14 days for all phases.**
Phase A–C gives a usable revision history (the main deliverable).
Phase D–E adds diff + rollback.
Phase F adds cross-revision addressing.

## Dependencies

| Component | Depends on |
|---|---|
| Phase A (backend) | Nothing new — uses existing chunk store + edition infrastructure |
| Phase B (client API) | Phase A |
| Phase C (Timeline lens) | Phase B |
| Phase D (diff UI) | Phase C + existing ComparePanel |
| Phase E (rollback) | Phase C |
| Phase F (tumblers) | Phase A + `cross-server-resolution.md` Phase 4 |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Back-fill is slow for works with many revisions | Low | Medium | Compute lazily; cache in memory; only compute content_hash on first access |
| Revision metadata grows manifest size | Low | Low | Each RevisionMeta is ~150 bytes; 1000 revisions = 150KB — negligible |
| `work_text_at_revision` is slow (chunk store load) | Medium | Medium | Cache last-accessed revision in memory; eviction on memory pressure |
| Auto-notable detection is noisy | Medium | Low | User can un-mark; threshold is configurable; default is conservative |
| Rollback creates unexpected transclusion breakage | Low | High | Test with transclusions that span the rolled-back revision; verify span migration |

## Success Criteria

- Opening a work shows a timeline of revisions with dates, descriptions, and change summaries.
- User can view any past revision read-only.
- User can diff any two revisions side-by-side.
- User can roll back to a previous revision non-destructively.
- User can save the current state as a named, notable revision.
- Notable revisions are auto-detected (> 20% change) and manually adjustable.
- Revision metadata survives server restart (persisted in manifest).
- Old manifests (pre-FR-23) load and back-fill metadata lazily.
- Citing `xan://server.work.r2` resolves to the same content forever.

## References

- `docs/dev/versioning-design.md` — Decision record (Approach C → F)
- `docs/dev/cross-server-resolution.md` — Revision tumblers
- `docs/dev/FR-18.md` — Workspace Timeline lens (Phase 5)
- `src/edition/work.rs::revise()` — Existing revision mechanism
- `src/persist/edition_chunks.rs::work_load_revision()` — Existing chunk store loader
- `src/server/server.rs::find_shared_regions()` — Existing diff primitive
- `web/app/src/components/ComparePanel.tsx` — Existing diff UI
- `TODO.md` — Revision phases summary
