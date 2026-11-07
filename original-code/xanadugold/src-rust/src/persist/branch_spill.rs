// ChunkStoreSpill — the BranchStore fault-in backend backed by the
// content-addressed chunk store.
//
// [Gold lineage] The original's FlockInfo was "the object that describes the
// state of this flock wrt disk" (shephx.hxx lines 312-317), and the packer
// journaled flock tables (shephx.cxx flockTable/dropFlock, fetchShepherd).
// This port keeps that vocabulary at the storage-engine layer
// (persist::flock: FlockId, FlockLocation, FlockState — FlockState::Dirty is
// the typed form of Gold's open question "Should this ensure that the flock
// is not dirty?", shephx.cxx line 127). ent::branch::BranchSpill is the
// Branch-level seam; this adapter is its store-backed implementation.
//
// Mapping: the stub locator (BranchId, contents hash) resolves to a BLAKE3
// chunk address through an append-only journal — the flock-table analogue.
// Chunks are write-once and BLAKE3-verified on every disk read
// (ChunkStore::read_chunk recomputes the hash; hot entries served from the
// store's 1024-entry read cache are not re-verified, so tampering is caught
// on the cold/post-restart path); the journal is fsynced per line, so a
// locator is never lost while its chunk exists.
//
// The chunk store used here is a dedicated instance on its own directory:
// spill chunks do not mix with work chunks, so manifest verification and
// rebuild-manifest never trip over them.

use std::collections::HashMap;
use std::fs::{File, OpenOptions};
use std::io::Write as _;
use std::path::{Path, PathBuf};

use crate::ent::branch::BranchSpill;
use crate::persist::chunk_store::{hash_to_hex, ChunkStore};

const JOURNAL_NAME: &str = "spill-journal.log";

pub struct ChunkStoreSpill {
    store: ChunkStore,
    dir: PathBuf,
    // spill key -> chunk hash; the live flock table
    index: HashMap<u64, [u8; 32]>,
    // append handle; one line per spill ("<key-hex16> <chunk-hex64>\n")
    journal: File,
}

impl std::fmt::Debug for ChunkStoreSpill {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("ChunkStoreSpill")
            .field("dir", &self.dir)
            .field("entries", &self.index.len())
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
        let mut index: HashMap<u64, [u8; 32]> = HashMap::new();
        let mut lines = 0usize;
        if let Ok(text) = std::fs::read_to_string(&journal_path) {
            for line in text.lines() {
                let mut parts = line.split_whitespace();
                let (Some(key_s), Some(hash_s), None) = (parts.next(), parts.next(), parts.next())
                else {
                    return Err(format!("corrupt spill journal line: {:?}", line));
                };
                let key = u64::from_str_radix(key_s, 16)
                    .map_err(|_| format!("corrupt spill journal key: {:?}", key_s))?;
                let hash_bytes = hex::decode(hash_s)
                    .map_err(|_| format!("corrupt spill journal hash: {:?}", hash_s))?;
                let hash: [u8; 32] = hash_bytes
                    .as_slice()
                    .try_into()
                    .map_err(|_| format!("wrong spill journal hash length: {:?}", hash_s))?;
                index.insert(key, hash);
                lines += 1;
            }
        }

        // Compact when superseded lines outnumber live ones: rewrite the
        // journal from the map, atomically (tmp + rename).
        let dead = lines - index.len();
        let journal = if dead > index.len() {
            let tmp = journal_path.with_extension("tmp");
            let mut text = String::new();
            for (key, hash) in &index {
                text.push_str(&format!("{:016x} {}\n", key, hash_to_hex(hash)));
            }
            std::fs::write(&tmp, text)
                .and_then(|_| std::fs::rename(&tmp, &journal_path))
                .map_err(|e| format!("spill journal compaction: {}", e))?;
            open_append(&journal_path)?
        } else {
            open_append(&journal_path)?
        };

        Ok(ChunkStoreSpill {
            store,
            dir: dir.to_path_buf(),
            index,
            journal,
        })
    }

    pub fn entry_count(&self) -> usize {
        self.index.len()
    }

    pub fn dir(&self) -> &Path {
        &self.dir
    }
}

fn open_append(path: &Path) -> Result<File, String> {
    OpenOptions::new()
        .create(true)
        .append(true)
        .open(path)
        .map_err(|e| format!("spill journal {}: {}", path.display(), e))
}

impl BranchSpill for ChunkStoreSpill {
    fn spill(&mut self, key: u64, bytes: &[u8]) -> Result<(), String> {
        let hash = self
            .store
            .write_chunk(bytes)
            .map_err(|e| format!("spill write {:016x}: {}", key, e))?;
        // Durability ordering: the chunk is fsynced by write_chunk, then the
        // locator line is appended and fsynced. A crash between the two
        // leaves an orphan chunk (harmless, GC-able); a crash after never
        // loses a locator whose chunk is missing.
        let line = format!("{:016x} {}\n", key, hash_to_hex(&hash));
        self.journal
            .write_all(line.as_bytes())
            .and_then(|_| self.journal.sync_all())
            .map_err(|e| format!("spill journal append {:016x}: {}", key, e))?;
        self.index.insert(key, hash);
        Ok(())
    }

    fn fetch(&mut self, key: u64) -> Result<Option<Vec<u8>>, String> {
        let Some(hash) = self.index.get(&key).copied() else {
            return Ok(None);
        };
        // read_chunk verifies the BLAKE3 hash on disk reads; ent's fault_in
        // adds the contents-hash check on top. Two independent layers.
        self.store
            .read_chunk(&hash)
            .map(Some)
            .map_err(|e| format!("spill read {:016x}: {}", key, e))
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

    // T: chunkstore_spill_roundtrip
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

    // T: reopen_finds_spilled_entries — the journal and chunks survive
    // process death; a fresh adapter locates them again.
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

    // T: respill_supersedes_and_compacts — a respill under the same key
    // overwrites the entry; a reopen compacts once superseded lines
    // outnumber live ones.
    #[test]
    fn respill_supersedes_and_compacts() {
        let dir = temp_dir("respill");
        let key_a: u64 = 0x0000_0001_0000_0002;
        let key_b: u64 = 0x0000_0003_0000_0004;
        {
            let mut spill = ChunkStoreSpill::open(&dir).unwrap();
            spill.spill(key_a, b"v1").unwrap();
            spill.spill(key_a, b"v2").unwrap();
            spill.spill(key_a, b"v3").unwrap();
            spill.spill(key_a, b"v4").unwrap();
            spill.spill(key_b, b"b1").unwrap();
            assert_eq!(spill.fetch(key_a).unwrap().unwrap(), b"v4");
        }
        // key_a has 4 lines (3 dead), key_b has 1: dead(3) > live(2), so the
        // reopen compacts the journal to exactly the live entries.
        let reopened = ChunkStoreSpill::open(&dir).unwrap();
        assert_eq!(reopened.entry_count(), 2);
        let text = std::fs::read_to_string(dir.join(JOURNAL_NAME)).unwrap();
        assert_eq!(text.lines().count(), 2);

        std::fs::remove_dir_all(&dir).ok();
    }

    // T: tampered_chunk_fails_fetch — BLAKE3 verification in read_chunk
    // turns on-disk corruption into a typed error, not wrong data.
    // Caveat exercised deliberately: the chunk store's 1024-entry read
    // cache serves HOT entries without re-verification, so tampering is
    // discovered on the cold path — modelled here by reopening (fresh
    // cache, journal replayed) before corrupting the chunk file.
    #[test]
    fn tampered_chunk_fails_fetch() {
        let dir = temp_dir("tamper");
        let key = 0x0000_0001_0000_0002;
        {
            let mut spill = ChunkStoreSpill::open(&dir).unwrap();
            spill.spill(key, b"original bytes").unwrap();
        }
        // Reopen: the journal restores the locator; the cache starts cold.
        // (No fetch before tampering — a fetch would warm the cache.)
        let mut spill = ChunkStoreSpill::open(&dir).unwrap();

        // Exactly one chunk exists; find its file by walking the layout.
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
        match spill.fetch(key) {
            Err(msg) => assert!(msg.contains("spill read"), "{}", msg),
            Ok(v) => panic!("expected error, got {:?}", v),
        }

        std::fs::remove_dir_all(&dir).ok();
    }

    // T: lost_backend_after_evict_is_spill_miss — stub markers can outlive
    // the backend (snapshot restored elsewhere, spill dir lost). A fresh
    // backend on the same dir has an empty index: typed miss, and the ent
    // layer's SpillMiss surfaces.
    #[test]
    fn lost_backend_after_evict_is_spill_miss() {
        let dir = temp_dir("lost-backend");
        let spill = ChunkStoreSpill::open(&dir).unwrap();
        let mut store = BranchStore::new().with_spill(Box::new(spill));
        let (root_id, _) = store.create_root();
        store.evict(root_id).unwrap();

        // Wipe the spill dir and re-attach a fresh backend: the stub says
        // the branch is spillable, the backend knows nothing.
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
    // three backends. InMemorySpill is the machinery-only floor (encode,
    // hash, map ops); FileSpill is raw fs; ChunkStoreSpill is the durable
    // production path (chunk fsync + journal fsync per spill). The chunk
    // store's read cache holds 1024 entries, so with N=5000 most fault-ins
    // are true disk reads.
    #[test]
    #[ignore]
    fn p7_spill_fault_roundtrip_cost() {
        use crate::ent::branch::InMemorySpill;
        use std::time::Instant;

        let n: usize = 5_000;

        let report = |label: &str, phase: &str, t: std::time::Duration, count: usize| {
            eprintln!(
                "  P7 {:>12} {:>6}: {:>8.3}s  {:>8.2} µs/op  {:>9.0} ops/s",
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

        // ChunkStore — durable production path
        {
            let dir = temp_dir("p7-chunkstore");
            let spill = ChunkStoreSpill::open(&dir).unwrap();
            let mut store = BranchStore::new().with_spill(Box::new(spill));
            let ids: Vec<BranchId> = (0..n).map(|_| store.create_root().0).collect();
            let t = Instant::now();
            for &id in &ids {
                store.evict(id).unwrap();
            }
            report("ChunkStore", "evict", t.elapsed(), n);
            let t = Instant::now();
            for &id in &ids {
                assert_eq!(store.materialize(id).unwrap().last_position, 2);
            }
            report("ChunkStore", "fault", t.elapsed(), n);
            std::fs::remove_dir_all(&dir).ok();
        }
    }
}
