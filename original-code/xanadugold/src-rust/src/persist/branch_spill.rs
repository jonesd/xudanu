// ChunkStoreSpill — lazily-durable, pack-batched fault-in backend for
// BranchStore over the content-addressed chunk store.
//
// [Durability contract — settled]
// spill() is ADMISSION, not commitment: the entry lands in an in-memory
// pending map and is NOT durable. flush_pending() (BranchStore::
// flush_spill) is the barrier: all pending entries are packed into ONE
// chunk — fsynced by ChunkStore::write_chunk — then every locator line is
// appended to the journal in ONE write + fsync. After the barrier returns,
// admitted spills survive a crash. Losing UN-flushed spills is acceptable
// by design, because the spill store is a cache over re-derivable state,
// never the system of record:
//   - every document edit is WAL-logged with a per-op fsync before the
//     server applies it (persist::wal::WalLog::append -> sync_all;
//     server.rs append_work_revise et al.), and restore rebuilds from
//     canonical chunks plus WAL replay;
//   - the ent layer this backend serves is itself derived — DagWood
//     metadata rebuilds from work (edition::backfollow) and BranchStore
//     restores from snapshots.
// A lost pending entry therefore surfaces as BranchError::SpillMiss on
// fault-in — an availability event (rebuild), never data loss. Per-spill
// fsync (the pre-pack behavior, ~4.2 ms/op = two fsyncs) bought durability
// this layer never needed.
//
// [Gold lineage] The original's FlockInfo was "the object that describes
// the state of this flock wrt disk" (shephx.hxx lines 312-317) and the
// packer journaled flock tables (shephx.cxx flockTable/dropFlock,
// fetchShepherd); persist::flock keeps that vocabulary (FlockState::Dirty
// is the typed form of Gold's "is the flock dirty?", shephx.cxx line 127).
// Stubbing itself was cheap and in-memory (becomeStub, shephx.cxx lines
// 121-131); flock bytes reached disk through the packer's batched writes.
// The pack is the chunk-level analogue of those batched regions.
//
// [Packs] One flush writes one PACK: many branches in a single chunk —
// magic XUSPILL1, an entry count, a key directory sorted by key (u64 key,
// u32 record offset each), then the records. One file + one journal fsync
// amortize across the batch; the sorted directory makes fetch O(log n) in
// pack size. fetch() serves pending first, then reads the pack (the
// chunk-store read cache holds it hot) and binary-searches. Subtree-
// locality packing (grouping evictions by enfilade subtree, the full
// flock model) stays an ent-layer policy choice — packs make it a
// grouping decision, not a format change.
//
// [Crash windows]
//   before flush       pending lost — SpillMiss, re-derive (see contract)
//   during pack write  torn/absent pack, no journal lines yet — no
//                      dangling locators; orphan chunk, harmless
//   during journal     multi-line append may tear; replay TOLERATES an
//   append             incomplete final line (truncates it) — a complete
//                      line that only lost its newline is accepted. An
//                      unparsable interior line remains fatal.
//   after journal      durable.
//   fsync
//
// [Caps & GC] The pending map is bounded (with_limits; defaults 65,536
// entries / 32 MiB): a spill that would cross a cap commits the pending
// batch first, so the W3 loss window is bounded by configuration at
// unchanged amortized cost — the flushing spill pays one barrier.
// open() runs gc(), deleting chunk files the journal no longer
// references (respills orphan their previous packs; journal compaction
// drops locators, not bytes) — the original's dismantle() role,
// shephx.cxx line 143 onward. Failure to GC is tidiness-loss, never
// availability-loss.
//
// [Legacy] Journals written by the per-spill adapter point at per-branch
// chunks. fetch() distinguishes by magic: a chunk without the pack magic
// IS the entry (solo form). Dev-era journals only; kept for graceful
// reopen.
//
// [Verification posture] Cold reads re-verify BLAKE3 (read_chunk); the
// 1024-entry read cache serves hot entries unverified, so on-disk
// tampering is caught on the cold/post-restart path. ent's fault_in adds
// the contents-hash check on top — two independent layers.
//
// The chunk store is a dedicated instance on its own directory: spill
// chunks never mix with work chunks, so manifest verification and
// rebuild-manifest never trip over them.
//
// Drop: best-effort flush_pending (errors ignored — there is no way to
// report them). Crash paths skip Drop, which is exactly the documented
// loss window. Tests that need crash semantics use std::mem::forget.

use std::collections::{HashMap, HashSet};
use std::fs::{File, OpenOptions};
use std::io::Write as _;
use std::path::{Path, PathBuf};

use crate::ent::branch::BranchSpill;
use crate::persist::chunk_store::{hash_to_hex, ChunkStore};

const JOURNAL_NAME: &str = "spill-journal.log";
const PACK_MAGIC: &[u8; 8] = b"XUSPILL1";
const DEFAULT_MAX_PENDING_ENTRIES: usize = 65_536;
const DEFAULT_MAX_PENDING_BYTES: usize = 32 * 1024 * 1024;

pub struct ChunkStoreSpill {
    store: ChunkStore,
    dir: PathBuf,
    // durable: spill key -> pack chunk hash; the live flock table
    index: HashMap<u64, [u8; 32]>,
    // admitted, not yet durable; respills coalesce (last wins)
    pending: HashMap<u64, Vec<u8>>,
    // running sum of pending value lengths, for the byte cap
    pending_bytes: usize,
    max_pending_entries: usize,
    max_pending_bytes: usize,
    journal: File,
}

impl std::fmt::Debug for ChunkStoreSpill {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("ChunkStoreSpill")
            .field("dir", &self.dir)
            .field("durable", &self.index.len())
            .field("pending", &self.pending.len())
            .finish()
    }
}

impl ChunkStoreSpill {
    pub fn open(dir: &Path) -> Result<Self, String> {
        std::fs::create_dir_all(dir).map_err(|e| format!("spill dir {}: {}", dir.display(), e))?;
        let store = ChunkStore::open(dir).map_err(|e| e.to_string())?;
        let journal_path = dir.join(JOURNAL_NAME);

        // Replay the journal; later lines supersede earlier ones, so a
        // respill under the same key simply overwrites the map entry.
        // A missing trailing newline means the last line tore in a crash
        // mid-append: if it does not parse it is dropped and the file is
        // truncated back to the last complete line; if it does parse the
        // content is complete and it is accepted. Unparsable interior
        // lines are real corruption and fatal.
        let mut index: HashMap<u64, [u8; 32]> = HashMap::new();
        let mut lines = 0usize;
        let mut truncate_at: Option<u64> = None;
        let journal_text = match std::fs::read_to_string(&journal_path) {
            Ok(t) => Some(t),
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => None,
            Err(e) => {
                return Err(format!("spill journal {}: {}", journal_path.display(), e));
            }
        };
        if let Some(text) = journal_text {
            let segments: Vec<&str> = text.split('\n').collect();
            let mut end = segments.len();
            if segments.last() == Some(&"") {
                end -= 1;
            } else if let Some(last) = segments.last() {
                if parse_line(last).is_none() {
                    truncate_at = Some((text.len() - last.len()) as u64);
                    end -= 1;
                }
            }
            for (i, seg) in segments.iter().take(end).enumerate() {
                let (key, hash) = parse_line(seg)
                    .ok_or_else(|| format!("corrupt spill journal line {}: {:?}", i + 1, seg))?;
                index.insert(key, hash);
                lines += 1;
            }
        }

        // Compact when superseded lines outnumber live ones: rewrite the
        // journal from the map, atomically (tmp + rename). Compaction
        // subsumes torn-tail truncation; otherwise truncate explicitly so
        // the next append does not merge with torn bytes.
        let dead = lines - index.len();
        if dead > index.len() {
            let tmp = journal_path.with_extension("tmp");
            let mut text = String::new();
            for (key, hash) in &index {
                text.push_str(&format!("{:016x} {}\n", key, hash_to_hex(hash)));
            }
            std::fs::write(&tmp, text)
                .and_then(|_| std::fs::rename(&tmp, &journal_path))
                .map_err(|e| format!("spill journal compaction: {}", e))?;
        } else if let Some(offset) = truncate_at {
            let f = OpenOptions::new()
                .write(true)
                .open(&journal_path)
                .map_err(|e| format!("spill journal {}: {}", journal_path.display(), e))?;
            f.set_len(offset)
                .and_then(|_| f.sync_all())
                .map_err(|e| format!("spill journal truncate: {}", e))?;
        }

        let mut spill = ChunkStoreSpill {
            store,
            dir: dir.to_path_buf(),
            index,
            pending: HashMap::new(),
            pending_bytes: 0,
            max_pending_entries: DEFAULT_MAX_PENDING_ENTRIES,
            max_pending_bytes: DEFAULT_MAX_PENDING_BYTES,
            journal: open_append(&journal_path)?,
        };
        // Startup is the natural GC cadence: respills orphan their previous
        // packs, and compaction drops locators, not bytes. Failure is
        // tidiness-loss, not availability-loss.
        if let Err(e) = spill.gc() {
            tracing::warn!("spill gc on open: {}", e);
        }
        Ok(spill)
    }

    pub fn entry_count(&self) -> usize {
        self.index.len()
    }

    pub fn pending_count(&self) -> usize {
        self.pending.len()
    }

    pub fn dir(&self) -> &Path {
        &self.dir
    }

    // Bound the crash loss window (W3). A spill that would cross a cap
    // commits the pending batch first, so at most max_entries entries /
    // max_bytes bytes of admitted-not-durable state can exist. Amortized
    // cost is unchanged; the flushing spill pays one barrier. An entry
    // larger than max_bytes still admits alone (the next spill commits
    // it), so the window is bounded by count and typical bytes.
    pub fn with_limits(mut self, max_entries: usize, max_bytes: usize) -> Self {
        self.max_pending_entries = max_entries;
        self.max_pending_bytes = max_bytes;
        self
    }

    // Remove chunk files the journal no longer references. Respills
    // orphan their previous packs; journal compaction drops locators, not
    // bytes — this is the bytes half. Safe because the store is a
    // dedicated instance: every hex-named file under chunks/ is a spill
    // pack (or a legacy solo chunk) whose only liveness is the journal.
    // Gold lineage: the original's dismantle() played this role
    // (shephx.cxx line 143 onward). Flushes pending first so a
    // just-superseded pack is not still the durable locator for its keys.
    // Tidiness-loss only under the eviction invariant (FR-166): every
    // spilled branch must remain re-derivable from the record.
    pub fn gc(&mut self) -> Result<usize, String> {
        if !self.pending.is_empty() {
            self.flush_pending()?;
        }
        let live: HashSet<[u8; 32]> = self.index.values().copied().collect();
        let chunks_dir = self.dir.join("chunks");
        let entries = match std::fs::read_dir(&chunks_dir) {
            Ok(e) => e,
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => return Ok(0),
            Err(e) => return Err(format!("spill gc {}: {}", chunks_dir.display(), e)),
        };
        let mut removed = 0usize;
        for entry in entries {
            let path = entry.map_err(|e| format!("spill gc: {}", e))?.path();
            let candidates: Vec<PathBuf> = if path.is_dir() {
                std::fs::read_dir(&path)
                    .map_err(|e| format!("spill gc {}: {}", path.display(), e))?
                    .map(|f| f.map_err(|e| format!("spill gc: {}", e)).map(|f| f.path()))
                    .collect::<Result<Vec<_>, _>>()?
            } else {
                vec![path]
            };
            for cand in candidates {
                // Real chunks are <64-hex>.xchunk (legacy extensionless
                // chunks are migrated to that shape at store open);
                // anything else under chunks/ (e.g. the store's README)
                // is not ours to judge.
                let Some(name) = cand.file_name().and_then(|n| n.to_str()) else {
                    continue;
                };
                let Some(stem) = name.strip_suffix(".xchunk") else {
                    continue;
                };
                let Ok(raw) = hex::decode(stem) else {
                    continue;
                };
                let Ok(hash) = <[u8; 32]>::try_from(raw.as_slice()) else {
                    continue;
                };
                if live.contains(&hash) {
                    continue;
                }
                std::fs::remove_file(&cand)
                    .map_err(|e| format!("spill gc remove {}: {}", cand.display(), e))?;
                removed += 1;
            }
        }
        Ok(removed)
    }

    // The durability barrier. Returns the number of entries committed.
    // On error the pending map is left untouched, so a failed flush can
    // simply be retried.
    pub fn flush_pending(&mut self) -> Result<usize, String> {
        if self.pending.is_empty() {
            return Ok(0);
        }
        let pack = build_pack(&self.pending);
        let hash = self
            .store
            .write_chunk(&pack)
            .map_err(|e| format!("spill pack write: {}", e))?;
        let mut lines = String::new();
        for key in self.pending.keys() {
            lines.push_str(&format!("{:016x} {}\n", key, hash_to_hex(&hash)));
        }
        self.journal
            .write_all(lines.as_bytes())
            .and_then(|_| self.journal.sync_all())
            .map_err(|e| format!("spill journal append: {}", e))?;
        let count = self.pending.len();
        for key in self.pending.keys() {
            self.index.insert(*key, hash);
        }
        self.pending.clear();
        self.pending_bytes = 0;
        Ok(count)
    }
}

impl Drop for ChunkStoreSpill {
    fn drop(&mut self) {
        self.flush_pending().ok();
    }
}

fn open_append(path: &Path) -> Result<File, String> {
    OpenOptions::new()
        .create(true)
        .append(true)
        .open(path)
        .map_err(|e| format!("spill journal {}: {}", path.display(), e))
}

fn parse_line(line: &str) -> Option<(u64, [u8; 32])> {
    let mut parts = line.split_whitespace();
    let key = u64::from_str_radix(parts.next()?, 16).ok()?;
    let hash_bytes = hex::decode(parts.next()?).ok()?;
    if parts.next().is_some() {
        return None;
    }
    let hash: [u8; 32] = hash_bytes.as_slice().try_into().ok()?;
    Some((key, hash))
}

// Pack layout: magic, u32 LE entry count, a key directory of count ×
// (u64 LE key, u32 LE record offset) sorted by key, then the records as
// (u32 LE length, bytes). Offsets are absolute from the pack start and
// point at the record's length field. The sorted directory lets fetch
// binary-search instead of scanning.
fn build_pack(entries: &HashMap<u64, Vec<u8>>) -> Vec<u8> {
    let mut sorted: Vec<(&u64, &Vec<u8>)> = entries.iter().collect();
    sorted.sort_by_key(|(k, _)| **k);
    let dir_start = PACK_MAGIC.len() + 4;
    let records_start = dir_start + sorted.len() * 12;
    let records_len: usize = sorted.iter().map(|(_, b)| b.len() + 4).sum();
    let mut out = Vec::with_capacity(records_start + records_len);
    out.extend_from_slice(PACK_MAGIC);
    out.extend_from_slice(&(sorted.len() as u32).to_le_bytes());
    let mut off = records_start;
    for (key, bytes) in &sorted {
        out.extend_from_slice(&key.to_le_bytes());
        out.extend_from_slice(&(off as u32).to_le_bytes());
        off += 4 + bytes.len();
    }
    for (_, bytes) in &sorted {
        out.extend_from_slice(&(bytes.len() as u32).to_le_bytes());
        out.extend_from_slice(bytes);
    }
    out
}

fn le_u32(data: &[u8], off: &mut usize) -> Option<u32> {
    let b: [u8; 4] = data.get(*off..*off + 4)?.try_into().ok()?;
    *off += 4;
    Some(u32::from_le_bytes(b))
}

fn scan_pack(data: &[u8], key: u64) -> Option<Vec<u8>> {
    if !data.starts_with(PACK_MAGIC) {
        // Legacy per-branch chunk: the whole chunk is the entry.
        return Some(data.to_vec());
    }
    let count = le_u32(data, &mut (PACK_MAGIC.len()))? as usize;
    let dir_start = PACK_MAGIC.len() + 4;
    let dir_len = count.checked_mul(12)?;
    let dir = data.get(dir_start..dir_start + dir_len)?;
    let read_dir = |i: usize| -> Option<(u64, usize)> {
        let base = i * 12;
        let k = u64::from_le_bytes(dir[base..base + 8].try_into().ok()?);
        let off = u32::from_le_bytes(dir[base + 8..base + 12].try_into().ok()?);
        Some((k, off as usize))
    };
    let mut lo = 0usize;
    let mut hi = count;
    while lo < hi {
        let mid = (lo + hi) / 2;
        match read_dir(mid)? {
            (k, _) if k < key => lo = mid + 1,
            _ => hi = mid,
        }
    }
    let (k, mut off) = read_dir(lo)?;
    if k != key {
        return None;
    }
    let len = le_u32(data, &mut off)? as usize;
    data.get(off..off + len).map(|b| b.to_vec())
}

impl BranchSpill for ChunkStoreSpill {
    fn spill(&mut self, key: u64, bytes: &[u8]) -> Result<(), String> {
        let next_entries = self.pending.len() + 1;
        let next_bytes = self.pending_bytes + bytes.len();
        if next_entries > self.max_pending_entries || next_bytes > self.max_pending_bytes {
            self.flush_pending()?;
        }
        if let Some(old) = self.pending.get(&key) {
            self.pending_bytes -= old.len();
        }
        self.pending.insert(key, bytes.to_vec());
        self.pending_bytes += bytes.len();
        Ok(())
    }

    fn fetch(&mut self, key: u64) -> Result<Option<Vec<u8>>, String> {
        if let Some(bytes) = self.pending.get(&key) {
            return Ok(Some(bytes.clone()));
        }
        let Some(hash) = self.index.get(&key).copied() else {
            return Ok(None);
        };
        let data = self
            .store
            .read_chunk(&hash)
            .map_err(|e| format!("spill read {:016x}: {}", key, e))?;
        Ok(scan_pack(&data, key))
    }

    fn flush(&mut self) -> Result<(), String> {
        self.flush_pending().map(|_| ())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ent::branch::{BranchId, BranchKind, BranchStore};

    fn temp_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!(
            "xudanu-chunkstore-spill-{}-{}",
            name,
            std::process::id()
        ));
        std::fs::remove_dir_all(&dir).ok();
        dir
    }

    fn journal_line_count(dir: &Path) -> usize {
        std::fs::read_to_string(dir.join(JOURNAL_NAME))
            .map(|t| t.lines().count())
            .unwrap_or(0)
    }

    fn chunk_file_count(dir: &Path) -> usize {
        let mut n = 0;
        if let Ok(entries) = std::fs::read_dir(dir.join("chunks")) {
            for e in entries.flatten() {
                let p = e.path();
                if p.is_dir() {
                    n += std::fs::read_dir(&p)
                        .map(|it| {
                            it.flatten()
                                .filter(|f| f.file_name().to_string_lossy().ends_with(".xchunk"))
                                .count()
                        })
                        .unwrap_or(0);
                } else if p
                    .file_name()
                    .and_then(|n| n.to_str())
                    .is_some_and(|n| n.ends_with(".xchunk"))
                {
                    n += 1;
                }
            }
        }
        n
    }

    // T: chunkstore_spill_roundtrip — evict through BranchStore, fault
    // back in (from pending), fields intact.
    #[test]
    fn chunkstore_spill_roundtrip() {
        let dir = temp_dir("roundtrip");
        let spill = ChunkStoreSpill::open(&dir).unwrap();
        let mut store = BranchStore::new().with_spill(Box::new(spill));

        let (root_id, _) = store.create_root();
        let parent = crate::ent::trace::TracePosition::new(root_id, 3);
        let (tree_id, _) = store.create_tree(parent);
        let (child, _) = store.create_root();
        store.install_branch(root_id, child).unwrap();

        store.evict(root_id).unwrap();
        store.evict(tree_id).unwrap();
        assert!(store.is_stub(root_id) && store.is_stub(tree_id));

        match &store.get_mut(tree_id).unwrap().kind {
            BranchKind::Tree { parent: p } => assert_eq!(*p, parent),
            other => panic!("expected Tree kind, got {:?}", other),
        }
        assert_eq!(store.get_mut(root_id).unwrap().left, Some(child));

        std::fs::remove_dir_all(&dir).ok();
    }

    // T: reopen_finds_spilled_entries — Drop's best-effort flush makes the
    // entries durable; a fresh adapter locates them again via pack scan.
    #[test]
    fn reopen_finds_spilled_entries() {
        let dir = temp_dir("reopen");
        {
            let mut spill = ChunkStoreSpill::open(&dir).unwrap();
            spill.spill(0x0000_0001_0000_0002, b"branch-one").unwrap();
            spill.spill(0x0000_0003_0000_0004, b"branch-two").unwrap();
        }
        let mut reopened = ChunkStoreSpill::open(&dir).unwrap();
        assert_eq!(reopened.entry_count(), 2);
        assert_eq!(
            reopened.fetch(0x0000_0001_0000_0002).unwrap().unwrap(),
            b"branch-one"
        );
        assert_eq!(
            reopened.fetch(0x0000_0003_0000_0004).unwrap().unwrap(),
            b"branch-two"
        );
        assert!(reopened.fetch(0xdead_beef_0000_0000).unwrap().is_none());

        std::fs::remove_dir_all(&dir).ok();
    }

    // T: flush_pending_is_the_durability_barrier — before the barrier the
    // entries are pending only; after it they are durable across reopen,
    // and one pack chunk carries them all.
    #[test]
    fn flush_pending_is_the_durability_barrier() {
        let dir = temp_dir("barrier");
        {
            let mut spill = ChunkStoreSpill::open(&dir).unwrap();
            spill.spill(1, b"one").unwrap();
            spill.spill(2, b"two").unwrap();
            spill.spill(3, b"three").unwrap();
            assert_eq!(spill.pending_count(), 3);
            assert_eq!(spill.entry_count(), 0);
            assert_eq!(spill.flush_pending().unwrap(), 3);
            assert_eq!(spill.pending_count(), 0);
            assert_eq!(spill.entry_count(), 3);
        }
        let mut reopened = ChunkStoreSpill::open(&dir).unwrap();
        assert_eq!(reopened.entry_count(), 3);
        assert_eq!(reopened.fetch(2).unwrap().unwrap(), b"two");
        assert_eq!(journal_line_count(&dir), 3);
        std::fs::remove_dir_all(&dir).ok();
    }

    // T: crash_before_flush_loses_pending — mem::forget skips Drop, which
    // is exactly what a crash does. The pending entries are gone; this is
    // the documented loss window (SpillMiss upstream, re-derive), never
    // wrong data.
    #[test]
    fn crash_before_flush_loses_pending() {
        let dir = temp_dir("crash-loss");
        {
            let mut spill = ChunkStoreSpill::open(&dir).unwrap();
            spill.spill(1, b"lost-in-crash").unwrap();
            std::mem::forget(spill);
        }
        let mut reopened = ChunkStoreSpill::open(&dir).unwrap();
        assert_eq!(reopened.entry_count(), 0);
        assert!(reopened.fetch(1).unwrap().is_none());
        std::fs::remove_dir_all(&dir).ok();
    }

    // T: pending_coalesces_last_wins — a respill under the same key
    // before the barrier overwrites in place: one journal line, one pack
    // entry, latest bytes win.
    #[test]
    fn pending_coalesces_last_wins() {
        let dir = temp_dir("coalesce");
        {
            let mut spill = ChunkStoreSpill::open(&dir).unwrap();
            spill.spill(7, b"v1").unwrap();
            spill.spill(7, b"v2").unwrap();
            spill.spill(8, b"b1").unwrap();
            assert_eq!(spill.flush_pending().unwrap(), 2);
        }
        let mut reopened = ChunkStoreSpill::open(&dir).unwrap();
        assert_eq!(reopened.entry_count(), 2);
        assert_eq!(reopened.fetch(7).unwrap().unwrap(), b"v2");
        assert_eq!(reopened.fetch(8).unwrap().unwrap(), b"b1");
        assert_eq!(journal_line_count(&dir), 2);
        std::fs::remove_dir_all(&dir).ok();
    }

    // T: fetch_serves_pending_before_flush — a fault-in right after evict
    // hits the pending map; no disk traffic, no journal content yet.
    #[test]
    fn fetch_serves_pending_before_flush() {
        let dir = temp_dir("pending-fetch");
        let mut spill = ChunkStoreSpill::open(&dir).unwrap();
        spill.spill(9, b"still-pending").unwrap();
        assert_eq!(spill.fetch(9).unwrap().unwrap(), b"still-pending");
        assert_eq!(journal_line_count(&dir), 0);
        std::fs::remove_dir_all(&dir).ok();
    }

    // T: torn_journal_tail_tolerated — a crash mid-append leaves a partial
    // final line; open() succeeds, drops the fragment, truncates the file
    // so the next append cannot merge with torn bytes, and keeps the
    // complete entries.
    #[test]
    fn torn_journal_tail_tolerated() {
        let dir = temp_dir("torn-tail");
        let good = format!("{:016x} {}\n", 1u64, "ab".repeat(32));
        let torn = format!("{:016x} f", 2u64);
        {
            std::fs::create_dir_all(&dir).unwrap();
            let mut j = OpenOptions::new()
                .create(true)
                .append(true)
                .open(dir.join(JOURNAL_NAME))
                .unwrap();
            j.write_all(good.as_bytes()).unwrap();
            j.write_all(torn.as_bytes()).unwrap();
        }
        let mut spill = ChunkStoreSpill::open(&dir).unwrap();
        assert_eq!(spill.entry_count(), 1);
        let text = std::fs::read_to_string(dir.join(JOURNAL_NAME)).unwrap();
        assert_eq!(text, good);
        // Appends after recovery land on clean boundaries.
        spill.spill(3, b"post-recovery").unwrap();
        spill.flush_pending().unwrap();
        let text = std::fs::read_to_string(dir.join(JOURNAL_NAME)).unwrap();
        assert!(text.starts_with(&good));
        assert!(text.ends_with('\n'));
        std::fs::remove_dir_all(&dir).ok();
    }

    // T: legacy_solo_chunk_fetchable — journals written by the per-spill
    // adapter point at per-branch chunks; fetch() recognises them by the
    // missing pack magic and returns the whole chunk.
    #[test]
    fn legacy_solo_chunk_fetchable() {
        let dir = temp_dir("legacy");
        {
            let store = ChunkStore::open(&dir).unwrap();
            let hash = store.write_chunk(b"legacy branch bytes").unwrap();
            let line = format!("{:016x} {}\n", 5u64, hash_to_hex(&hash));
            let mut j = OpenOptions::new()
                .create(true)
                .append(true)
                .open(dir.join(JOURNAL_NAME))
                .unwrap();
            j.write_all(line.as_bytes()).unwrap();
        }
        let mut spill = ChunkStoreSpill::open(&dir).unwrap();
        assert_eq!(spill.entry_count(), 1);
        assert_eq!(spill.fetch(5).unwrap().unwrap(), b"legacy branch bytes");
        std::fs::remove_dir_all(&dir).ok();
    }

    // T: tampered_pack_fails_cold_fetch — BLAKE3 verification in
    // read_chunk turns on-disk pack corruption into a typed error, not
    // wrong data, on the cold (post-restart) path. The 1024-entry read
    // cache serves hot entries unverified — hence the reopen.
    #[test]
    fn tampered_pack_fails_cold_fetch() {
        let dir = temp_dir("tamper");
        {
            let mut spill = ChunkStoreSpill::open(&dir).unwrap();
            spill.spill(11, b"original bytes").unwrap();
            spill.flush_pending().unwrap();
        }
        let mut spill = ChunkStoreSpill::open(&dir).unwrap();
        let chunk_path = {
            let mut found = None;
            for entry in std::fs::read_dir(dir.join("chunks")).unwrap() {
                let sub = entry.unwrap().path();
                if !sub.is_dir() {
                    continue;
                }
                for f in std::fs::read_dir(&sub).unwrap() {
                    found = Some(f.unwrap().path());
                }
            }
            found.expect("spill chunk file")
        };
        std::fs::write(&chunk_path, b"tampered bytes").unwrap();
        match spill.fetch(11) {
            Err(msg) => assert!(msg.contains("spill read"), "{}", msg),
            Ok(v) => panic!("expected error, got {:?}", v),
        }
        std::fs::remove_dir_all(&dir).ok();
    }

    // T: respill_across_flushes_compacts — respills after earlier flushes
    // create dead journal lines; once dead outnumbers live, reopen
    // compacts to exactly the live entries.
    #[test]
    fn respill_across_flushes_compacts() {
        let dir = temp_dir("respill");
        let key_a: u64 = 0x0000_0001_0000_0002;
        let key_b: u64 = 0x0000_0003_0000_0004;
        {
            let mut spill = ChunkStoreSpill::open(&dir).unwrap();
            spill.spill(key_a, b"a1").unwrap();
            spill.spill(key_b, b"b1").unwrap();
            spill.flush_pending().unwrap();
            spill.spill(key_a, b"a2").unwrap();
            spill.flush_pending().unwrap();
            spill.spill(key_a, b"a3").unwrap();
            spill.flush_pending().unwrap();
            // 4 lines, 2 live, 2 dead — not yet (dead must EXCEED live).
            spill.spill(key_b, b"b2").unwrap();
            spill.flush_pending().unwrap();
            // 5 lines, 2 live, 3 dead — compaction triggers on reopen.
        }
        let reopened = ChunkStoreSpill::open(&dir).unwrap();
        assert_eq!(reopened.entry_count(), 2);
        assert_eq!(journal_line_count(&dir), 2);
        std::fs::remove_dir_all(&dir).ok();
    }

    // T: large_pack_binary_search — a full pack's sorted directory serves
    // every key after reopen (journal replay at scale + binary-search
    // correctness at both ends and the middle of the key space).
    #[test]
    fn large_pack_binary_search() {
        let dir = temp_dir("large-pack");
        {
            let mut spill = ChunkStoreSpill::open(&dir).unwrap();
            for i in 0..1000u64 {
                spill
                    .spill(i * 0x100, format!("branch-{}", i).as_bytes())
                    .unwrap();
            }
            assert_eq!(spill.flush_pending().unwrap(), 1000);
        }
        let mut reopened = ChunkStoreSpill::open(&dir).unwrap();
        assert_eq!(reopened.entry_count(), 1000);
        for i in [0u64, 1, 137, 500, 768, 999] {
            assert_eq!(
                reopened.fetch(i * 0x100).unwrap().unwrap(),
                format!("branch-{}", i).as_bytes(),
                "key {:x}",
                i * 0x100
            );
        }
        assert!(reopened.fetch(0xdead_beef_0000_0000).unwrap().is_none());
        std::fs::remove_dir_all(&dir).ok();
    }

    // T: gc_removes_orphaned_packs — a respill across flushes orphans the
    // previous pack; gc deletes exactly the unreferenced chunks and every
    // live key still fetches.
    #[test]
    fn gc_removes_orphaned_packs() {
        let dir = temp_dir("gc-direct");
        let mut spill = ChunkStoreSpill::open(&dir).unwrap();
        spill.spill(1, b"one-v1").unwrap();
        spill.spill(2, b"two-v1").unwrap();
        spill.flush_pending().unwrap();
        spill.spill(1, b"one-v2").unwrap();
        spill.spill(2, b"two-v2").unwrap();
        spill.flush_pending().unwrap();
        assert_eq!(chunk_file_count(&dir), 2);
        assert_eq!(spill.gc().unwrap(), 1);
        assert_eq!(chunk_file_count(&dir), 1);
        assert_eq!(spill.fetch(1).unwrap().unwrap(), b"one-v2");
        assert_eq!(spill.fetch(2).unwrap().unwrap(), b"two-v2");
        std::fs::remove_dir_all(&dir).ok();
    }

    // T: gc_runs_on_reopen — open() is the GC cadence, so a dir handed
    // across restarts stays bounded without operator action.
    #[test]
    fn gc_runs_on_reopen() {
        let dir = temp_dir("gc-reopen");
        {
            let mut spill = ChunkStoreSpill::open(&dir).unwrap();
            spill.spill(1, b"one-v1").unwrap();
            spill.flush_pending().unwrap();
            spill.spill(1, b"one-v2").unwrap();
            spill.flush_pending().unwrap();
            assert_eq!(chunk_file_count(&dir), 2);
        }
        let mut reopened = ChunkStoreSpill::open(&dir).unwrap();
        assert_eq!(chunk_file_count(&dir), 1);
        assert_eq!(reopened.entry_count(), 1);
        assert_eq!(reopened.fetch(1).unwrap().unwrap(), b"one-v2");
        std::fs::remove_dir_all(&dir).ok();
    }

    // T: pending_entry_cap_auto_flushes — crossing the entry cap commits
    // the pending batch first; the loss window never exceeds the cap.
    #[test]
    fn pending_entry_cap_auto_flushes() {
        let dir = temp_dir("cap-entries");
        let mut spill = ChunkStoreSpill::open(&dir)
            .unwrap()
            .with_limits(2, usize::MAX);
        spill.spill(1, b"one").unwrap();
        spill.spill(2, b"two").unwrap();
        assert_eq!(spill.pending_count(), 2);
        spill.spill(3, b"three").unwrap();
        assert_eq!(spill.entry_count(), 2);
        assert_eq!(spill.pending_count(), 1);
        assert_eq!(journal_line_count(&dir), 2);
        assert_eq!(spill.fetch(1).unwrap().unwrap(), b"one");
        assert_eq!(spill.fetch(3).unwrap().unwrap(), b"three");
        std::fs::remove_dir_all(&dir).ok();
    }

    // T: pending_byte_cap_auto_flushes — same contract in bytes: the
    // third 10-byte spill crosses a 24-byte cap and commits the first two.
    #[test]
    fn pending_byte_cap_auto_flushes() {
        let dir = temp_dir("cap-bytes");
        let mut spill = ChunkStoreSpill::open(&dir)
            .unwrap()
            .with_limits(usize::MAX, 24);
        spill.spill(1, b"0123456789").unwrap();
        spill.spill(2, b"0123456789").unwrap();
        assert_eq!(spill.pending_count(), 2);
        spill.spill(3, b"0123456789").unwrap();
        assert_eq!(spill.entry_count(), 2);
        assert_eq!(spill.pending_count(), 1);
        assert_eq!(spill.fetch(2).unwrap().unwrap(), b"0123456789");
        assert_eq!(spill.fetch(3).unwrap().unwrap(), b"0123456789");
        std::fs::remove_dir_all(&dir).ok();
    }

    // T: lost_backend_after_evict_is_spill_miss — stub markers can outlive
    // the backend (spill dir wiped, fresh backend attached). A fault-in is
    // a typed miss, never wrong data.
    #[test]
    fn lost_backend_after_evict_is_spill_miss() {
        let dir = temp_dir("lost-backend");
        let spill = ChunkStoreSpill::open(&dir).unwrap();
        let mut store = BranchStore::new().with_spill(Box::new(spill));
        let (root_id, _) = store.create_root();
        store.evict(root_id).unwrap();

        std::fs::remove_dir_all(&dir).unwrap();
        let fresh = ChunkStoreSpill::open(&dir).unwrap();
        store.set_spill(Box::new(fresh));
        match store.get_mut(root_id) {
            Err(crate::ent::branch::BranchError::SpillMiss(_)) => {}
            other => panic!("expected SpillMiss, got {:?}", other),
        }

        std::fs::remove_dir_all(&dir).ok();
    }

    // P7: spill_fault_roundtrip_cost — evict-all / fault-all across the
    // backends, now including the two durability modes of the chunk-store
    // path. InMemorySpill is the machinery-only floor; FileSpill is raw
    // fs; ChunkStore lazy is admission + one flush barrier (the production
    // shape: evicts are map inserts, durability amortizes across the
    // batch); ChunkStore flush-per-spill is the eager knob for callers
    // that want evict-durable-per-op (~two fsyncs each).
    #[test]
    #[ignore]
    fn p7_spill_fault_roundtrip_cost() {
        use crate::ent::branch::InMemorySpill;
        use std::time::Instant;

        let n: usize = 5_000;

        let report = |label: &str, phase: &str, t: std::time::Duration, count: usize| {
            eprintln!(
                "  P7 {:>22} {:>6}: {:>8.3}s  {:>8.2} µs/op  {:>9.0} ops/s",
                label,
                phase,
                t.as_secs_f64(),
                t.as_secs_f64() * 1e6 / count as f64,
                count as f64 / t.as_secs_f64()
            );
        };

        // InMemory — machinery floor
        {
            let mut store = BranchStore::new().with_spill(Box::new(InMemorySpill::new()));
            let ids: Vec<BranchId> = (0..n).map(|_| store.create_root().0).collect();
            let t = Instant::now();
            for &id in &ids {
                store.evict(id).unwrap();
            }
            report("InMemory", "evict", t.elapsed(), n);
            let t = Instant::now();
            for &id in &ids {
                assert_eq!(store.materialize(id).unwrap().last_position, 2);
            }
            report("InMemory", "fault", t.elapsed(), n);
        }

        // File — raw fs
        {
            let dir = temp_dir("p7-file");
            let spill = crate::ent::branch::FileSpill::new(&dir).unwrap();
            let mut store = BranchStore::new().with_spill(Box::new(spill));
            let ids: Vec<BranchId> = (0..n).map(|_| store.create_root().0).collect();
            let t = Instant::now();
            for &id in &ids {
                store.evict(id).unwrap();
            }
            report("File", "evict", t.elapsed(), n);
            let t = Instant::now();
            for &id in &ids {
                assert_eq!(store.materialize(id).unwrap().last_position, 2);
            }
            report("File", "fault", t.elapsed(), n);
            std::fs::remove_dir_all(&dir).ok();
        }

        // ChunkStore — lazy admission, one flush barrier at the end
        {
            let dir = temp_dir("p7-chunkstore-lazy");
            let spill = ChunkStoreSpill::open(&dir).unwrap();
            let mut store = BranchStore::new().with_spill(Box::new(spill));
            let ids: Vec<BranchId> = (0..n).map(|_| store.create_root().0).collect();
            let t = Instant::now();
            for &id in &ids {
                store.evict(id).unwrap();
            }
            report("ChunkStore-lazy", "evict", t.elapsed(), n);
            let t = Instant::now();
            store.flush_spill().unwrap();
            report("ChunkStore-lazy", "flush", t.elapsed(), n);
            let t = Instant::now();
            for &id in &ids {
                assert_eq!(store.materialize(id).unwrap().last_position, 2);
            }
            report("ChunkStore-lazy", "fault", t.elapsed(), n);
            std::fs::remove_dir_all(&dir).ok();
        }

        // ChunkStore — flush after every spill (eager durability knob)
        {
            let dir = temp_dir("p7-chunkstore-eager");
            let spill = ChunkStoreSpill::open(&dir).unwrap();
            let mut store = BranchStore::new().with_spill(Box::new(spill));
            let ids: Vec<BranchId> = (0..n).map(|_| store.create_root().0).collect();
            let t = Instant::now();
            for &id in &ids {
                store.evict(id).unwrap();
                store.flush_spill().unwrap();
            }
            report("ChunkStore-eager", "evict", t.elapsed(), n);
            let t = Instant::now();
            for &id in &ids {
                assert_eq!(store.materialize(id).unwrap().last_position, 2);
            }
            report("ChunkStore-eager", "fault", t.elapsed(), n);
            std::fs::remove_dir_all(&dir).ok();
        }
    }
}
