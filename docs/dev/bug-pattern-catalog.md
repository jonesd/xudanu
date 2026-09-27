# Bug Pattern Catalog & Testing Strategy

**Date:** September 2026
**Trigger:** persistence audit found 4 CRITICAL + 9 HIGH bugs despite 3,655 passing tests
**Root cause:** tests verified the happy path, not the failure modes

---

## The Five Bug Patterns

Every data-loss bug we found fits one of five patterns. Each has a
specific test type that catches it.

### Pattern 1: Silent read failure → empty default → cemented loss

**What happens:** a chunk/file read fails (corruption, missing file,
wrong format). The code logs a warning and falls back to an empty
default. The system continues running. The next checkpoint persists
the empty state, permanently destroying the data.

**Sites found (all now fixed with `restore_errors` gating):**
- Social chunk (stars/pins/trails/compound) — H4
- Links chunk — H5
- Historical authors chunk
- Blob metadata chunk
- Federation snapshot chunk
- Content address chunk
- Annotations chunk
- Fossil snapshots chunk
- Trails sidecar
- Detectors sidecar

**Test that catches it:**
```
1. Create data (trails, stars, etc.)
2. Kill server (SIGKILL)
3. Corrupt the specific chunk/sidecar file
4. Restart server
5. ASSERT: restore_errors is non-empty
6. ASSERT: auto_checkpoint returns false (data-loss prevention)
```

### Pattern 2: Flag set but never consumed

**What happens:** a function sets a flag (like `checkpoint_in_flight`)
and returns a value indicating action is needed. But the callers
discard the return value and nothing acts on the flag. The system
enters a permanently wedged state.

**Sites found:**
- `auto_checkpoint()` → `checkpoint_in_flight` (C2) — 52 call sites
  discarded the return; the flag permanently disabled checkpoints

**Test that catches it:**
```
1. Trigger the mutation that sets the flag
2. Wait the relevant timeout
3. ASSERT: the expected side effect actually occurred
   (not just that the flag was set)
```

### Pattern 3: Written but never read back

**What happens:** data is serialized to disk (chunk, manifest field,
sidecar), but the restore path never reads that field back. The data
exists on disk but is invisible to the running system.

**Sites found:**
- `link_type_registry` — written to root chunk, never restored (H1)
- `compound_segments` — written to social chunk, never read (H2)
- FR-23 `revisions` — written to WorkStateChunks, never mapped back (H3)
- Link `cross_server_notify` — accepted as lossy (L7)

**Test that catches it:**
```
ROUND-TRIP TEST:
1. Create data in memory
2. Trigger checkpoint (full, not partial)
3. Create a fresh server instance
4. Restore from the same data dir
5. ASSERT: the restored value matches the in-memory value
```

### Pattern 4: Async path skips data that sync path includes

**What happens:** two code paths write to disk — a sync path
(shutdown/init) and an async path (periodic autosave). The async path
silently skips some data sections. In production, the async path is
the one that runs, so the skipped data has no durability.

**Sites found:**
- Async checkpoint drops: social chunk (stars/pins/trails/compound),
  revisions, link_type_registry, federation snapshot, ticket nonces (C1)
- Sync path skips per-chunk fsync for work chunks (M7)

**Test that catches it:**
```
DIFF TEST:
1. Create data via the API
2. Wait for async checkpoint (NOT shutdown)
3. Read the on-disk state directly
4. ASSERT: the data is present on disk
```

### Pattern 5: Non-idempotent WAL replay

**What happens:** the WAL records a mutation. A checkpoint persists
the state INCLUDING that mutation. But the WAL is not truncated after
the async checkpoint. On the next crash+restore, the checkpoint
provides the state AND the WAL replays the same entry, causing a
duplicate.

**Sites found:**
- `wal_replay_link_end_add_attachment` blind-pushed (C4)

**Test that catches it:**
```
CRASH-REPLAY TEST:
1. Create data (link with attachment)
2. Wait for async checkpoint (state on disk)
3. Kill server (SIGKILL — WAL NOT truncated)
4. Restart server (checkpoint restores + WAL replays)
5. ASSERT: no duplicates
```

---

## Common Sources of Bugs (Ranked by what we actually found)

| Source | Bugs found | Why it's common |
|---|---|---|
| **Async/sync path divergence** | C1, M7 | Two code paths are hard to keep in sync |
| **Silent error swallowing** | H4, H5, H6, H7, M5 | `let _ = ...` and `warn!` + default are easy to write |
| **Serialization round-trip gaps** | H1, H2, H3, L7 | Writing a field is easy; remembering to read it back is not |
| **Flag lifecycle errors** | C2 | Setting a flag is easy; ensuring someone consumes it is not |
| **WAL lifecycle (append/replay/clear)** | C4, H8, H7 | Three phases must be consistent; each is maintained separately |
| **Checkpoint timing windows** | C2, H9 | 15-second throttle + background execution = wide gap |

---

## Testing Strategy

### Layer 1: Unit tests (existing 3,655 — keep and maintain)

The happy path tests. They catch regressions in individual functions.
**Keep them.** But they cannot catch system-level persistence bugs.

### Layer 2: Round-trip serialization tests (NEW — most impactful)

For every data type that is serialized to disk, verify that the
restore produces the same in-memory state:

```rust
#[test]
fn <datatype>_roundtrip() {
    let dir = tempdir();
    let mut server = create_server_with_data();
    server.checkpoint_to_store().unwrap();
    let mut server2 = Server::restore_from_data_dir(&dir);
    assert_eq!(server2.get_<datatype>(), server.get_<datatype>());
}
```

**Data types that need round-trip tests:**
- [x] trails (via sidecar)
- [x] detectors (via sidecar)
- [x] link_type_registry
- [ ] stars (via social chunk — async path untested)
- [ ] user_pins (via social chunk — async path untested)
- [ ] compound_editions
- [ ] compound_segments
- [ ] annotations
- [ ] historical_authors
- [ ] blob_metas
- [ ] content_address
- [ ] fossil_snapshots
- [ ] link endorsements (per-link)
- [ ] FR-23 revisions
- [ ] federation state
- [ ] edit_policy
- [ ] server_directory entries

### Layer 3: Crash-recovery tests (persist-stress.mjs — expand)

The stress test tool already runs crash + chaos modes. Needs:
- [ ] CI integration (run on every PR)
- [ ] More data types (compound, annotations, directory)
- [ ] Timing variations (kill at 0ms, 100ms, 1s, 5s, 15s, 30s)
- [ ] Concurrent mutation + kill (multiple writers racing)
- [ ] Kill DURING checkpoint (not just between checkpoints)

### Layer 4: Invariant tests (NEW)

After every checkpoint, verify that on-disk state matches in-memory
state. Any divergence is a bug:

```rust
#[test]
fn checkpoint_perserves_all_state() {
    let server = create_server_with_all_data_types();
    let manifest_before = server.prepare_manifest();
    server.checkpoint_to_store().unwrap();
    let server2 = restore_from_same_dir();
    let manifest_after = server2.prepare_manifest();
    // Compare field by field
    assert_eq!(manifest_before.field_count, manifest_after.field_count);
}
```

### Layer 5: Fault injection (NEW — for the brave)

Systematically fail each I/O operation and verify the system either:
- Recovers gracefully
- Fails loudly (no silent data loss)

```rust
#[test]
fn wal_write_failure_is_visible() {
    let server = create_server();
    // Inject: make WAL writes fail
    server.set_wal_failure_rate(1.0);
    server.star_work(sid, work_id);
    // ASSERT: a warning or error was logged
    // ASSERT: the star still works in memory (best-effort WAL)
    assert!(server.is_work_starred(work_id));
}
```

---

## Coverage Assessment

### Current state
- 3,655 unit tests: catch individual function regressions
- 39 ignored tests: likely performance/integration
- **0 round-trip serialization tests** for most data types
- **0 crash-recovery tests** in CI (persist-stress runs locally only)
- **0 fault-injection tests**
- **Coverage measurement: NOT ENABLED**

### Recommendation

1. **Enable coverage measurement** (`cargo-tarpaulin` or `cargo-llvm-cov`)
2. **Set a floor, not a ceiling:** 80% line coverage minimum for
   `src/persist/` (the persistence layer — where all the bugs were)
3. **Track per-module coverage:** the persistence modules should be
   higher than the average
4. **Add "round-trip coverage"** — a custom metric: for each field
   that's serialized, is there a test that verifies it round-trips?

### Why test count alone is misleading

| Metric | Value | What it tells you |
|---|---|---|
| Total tests | 3,655 | Individual functions work correctly |
| Persistence bugs found | 13 | System-level interactions are broken |
| Ratio | 281:1 | Tests are deep but narrow — they test functions, not flows |

**The fix isn't more tests of the same type — it's different types of tests.**

---

## CI Integration Plan

### Immediate (this week)
```yaml
# .github/workflows/ci.yml — add these jobs

persistence-stress:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Build server
      run: cargo build --features server --bin xudanu-server
    - name: Run persistence stress test
      run: |
        node scripts/persist-stress.mjs --mode=crash --iterations=2
        node scripts/persist-stress.mjs --mode=chaos --iterations=2

roundtrip-tests:
  runs-on: ubuntu-latest
  steps:
    - name: Run round-trip serialization tests
      run: cargo test --features server --lib roundtrip
```

### Short-term (next release)
```yaml
coverage:
  runs-on: ubuntu-latest
  steps:
    - name: Generate coverage report
      run: cargo llvm-cov --features server --lib
    - name: Check persistence coverage ≥ 80%
      run: cargo llvm-cov --features server --lib --summary-only | grep "persist" | awk -F: '{if ($3 < 80) exit 1}'
```
