use std::collections::{BTreeMap, HashSet};

use crate::edition::backend::BeId;
use crate::edition::edition::Edition;
use crate::edition::persistent::{EditionSnapshot, WorkSnapshot};
use crate::edition::work::Work;
use crate::persist::chunk_store::ChunkStore;

const ENTRIES_PER_CHUNK: usize = 256;

#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct EditionChunkRef {
    pub root_hash: [u8; 32],
    pub entry_count: u32,
}

#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct WorkChunkRef {
    pub be_id: BeId,
    pub owner: Option<BeId>,
    pub revision_count: u64,
    pub current_root: EditionChunkRef,
    pub history: BTreeMap<u64, EditionChunkRef>,
    pub read_club: Option<BeId>,
    pub edit_club: Option<BeId>,
    pub sponsors: Vec<BeId>,
}

#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
struct EntryChunk {
    entries: Vec<(i64, crate::edition::range_element::RangeElement)>,
}

#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
struct EditionRootChunk {
    default: Option<crate::edition::range_element::RangeElement>,
    domain_start: Option<i64>,
    domain_infinite_above: bool,
    entry_count: u32,
    entry_chunk_hashes: Vec<[u8; 32]>,
}

#[derive(Debug)]
pub enum ChunkSerError {
    Serialization(String),
    ChunkStore(crate::persist::chunk_store::ChunkError),
    MissingChunk([u8; 32]),
    InvalidRevision { requested: u64, latest: u64 },
}

impl std::fmt::Display for ChunkSerError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ChunkSerError::Serialization(e) => write!(f, "serialization error: {}", e),
            ChunkSerError::ChunkStore(e) => write!(f, "chunk store error: {}", e),
            ChunkSerError::MissingChunk(h) => write!(f, "missing chunk: {:016x}", u64_from_hash(h)),
            ChunkSerError::InvalidRevision { requested, latest } => {
                write!(f, "invalid revision {} (latest: {})", requested, latest)
            }
        }
    }
}

impl std::error::Error for ChunkSerError {}

impl From<crate::persist::chunk_store::ChunkError> for ChunkSerError {
    fn from(e: crate::persist::chunk_store::ChunkError) -> Self {
        ChunkSerError::ChunkStore(e)
    }
}

fn u64_from_hash(hash: &[u8; 32]) -> u64 {
    let mut bytes = [0u8; 8];
    bytes.copy_from_slice(&hash[..8]);
    u64::from_be_bytes(bytes)
}

fn serialize_to_bytes<T: serde::Serialize>(value: &T) -> Result<Vec<u8>, ChunkSerError> {
    postcard::to_allocvec(value).map_err(|e| ChunkSerError::Serialization(e.to_string()))
}

fn deserialize_from_bytes<'a, T: serde::Deserialize<'a>>(bytes: &'a [u8]) -> Result<T, ChunkSerError> {
    postcard::from_bytes(bytes).map_err(|e| ChunkSerError::Serialization(e.to_string()))
}

pub fn edition_to_chunks(
    edition: &Edition,
    store: &ChunkStore,
) -> Result<EditionChunkRef, ChunkSerError> {
    let snapshot = EditionSnapshot::from_edition(edition);

    let mut entry_chunk_hashes = Vec::new();
    for chunk_entries in snapshot.entries.chunks(ENTRIES_PER_CHUNK) {
        let entry_chunk = EntryChunk {
            entries: chunk_entries.to_vec(),
        };
        let data = serialize_to_bytes(&entry_chunk)?;
        let hash = store.write_chunk(&data)?;
        entry_chunk_hashes.push(hash);
    }

    let root_chunk = EditionRootChunk {
        default: snapshot.default,
        domain_start: snapshot.domain_start,
        domain_infinite_above: snapshot.domain_infinite_above,
        entry_count: snapshot.entries.len() as u32,
        entry_chunk_hashes,
    };
    let root_data = serialize_to_bytes(&root_chunk)?;
    let root_hash = store.write_chunk(&root_data)?;

    Ok(EditionChunkRef {
        root_hash,
        entry_count: snapshot.entries.len() as u32,
    })
}

pub fn edition_from_chunks(
    chunk_ref: &EditionChunkRef,
    store: &ChunkStore,
) -> Result<Edition, ChunkSerError> {
    let root_data = store.read_chunk(&chunk_ref.root_hash)?;
    let root: EditionRootChunk = deserialize_from_bytes(&root_data)?;

    let mut all_entries = Vec::with_capacity(root.entry_count as usize);
    for hash in &root.entry_chunk_hashes {
        let chunk_data = store.read_chunk(hash)?;
        let entry_chunk: EntryChunk = deserialize_from_bytes(&chunk_data)?;
        all_entries.extend(entry_chunk.entries);
    }

    let snapshot = EditionSnapshot {
        entries: all_entries,
        default: root.default,
        domain_start: root.domain_start,
        domain_infinite_above: root.domain_infinite_above,
    };
    Ok(snapshot.to_edition())
}

pub fn work_to_chunks(
    work: &Work,
    store: &ChunkStore,
) -> Result<WorkChunkRef, ChunkSerError> {
    let current_root = edition_to_chunks(work.edition(), store)?;

    let mut history = BTreeMap::new();
    for (rev_num, edition) in work.revision_history() {
        let chunk_ref = edition_to_chunks(edition, store)?;
        history.insert(*rev_num, chunk_ref);
    }

    Ok(WorkChunkRef {
        be_id: work.be_id(),
        owner: work.owner(),
        revision_count: work.revision_count(),
        current_root,
        history,
        read_club: work.read_club(),
        edit_club: work.edit_club(),
        sponsors: work.sponsors().to_vec(),
    })
}

pub fn work_from_chunks_current(
    chunk_ref: &WorkChunkRef,
    store: &ChunkStore,
) -> Result<Work, ChunkSerError> {
    let current = edition_from_chunks(&chunk_ref.current_root, store)?;
    let mut work = Work::new(chunk_ref.be_id, current);
    work.set_owner(chunk_ref.owner);
    work.set_read_club(chunk_ref.read_club);
    work.set_edit_club(chunk_ref.edit_club);
    for s in &chunk_ref.sponsors {
        work.add_sponsor(*s);
    }
    work.set_revision_count(chunk_ref.revision_count);
    Ok(work)
}

pub fn work_load_revision(
    work_chunk_ref: &WorkChunkRef,
    revision: u64,
    store: &ChunkStore,
) -> Result<Edition, ChunkSerError> {
    if revision == work_chunk_ref.revision_count {
        return edition_from_chunks(&work_chunk_ref.current_root, store);
    }
    let chunk_ref = work_chunk_ref.history.get(&revision)
        .ok_or_else(|| ChunkSerError::InvalidRevision {
            requested: revision,
            latest: work_chunk_ref.revision_count,
        })?;
    edition_from_chunks(chunk_ref, store)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::RangeElement;

    fn temp_dir() -> PathBuf {
        static COUNTER: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
        let id = COUNTER.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        std::env::temp_dir().join(format!(
            "xudanu_edition_chunk_test_{}_{}",
            std::process::id(),
            id
        ))
    }

    use std::path::PathBuf;

    #[test]
    fn simple_edition_roundtrip() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let edition = Edition::from_text("hello world");
        let chunk_ref = edition_to_chunks(&edition, &store).unwrap();

        let restored = edition_from_chunks(&chunk_ref, &store).unwrap();
        assert_eq!(restored.to_text(), "hello world");

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn empty_edition_roundtrip() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let edition = Edition::empty();
        let chunk_ref = edition_to_chunks(&edition, &store).unwrap();
        assert_eq!(chunk_ref.entry_count, 0);

        let restored = edition_from_chunks(&chunk_ref, &store).unwrap();
        assert_eq!(restored.count(), 0);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn sparse_edition_roundtrip() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let edition = Edition::from_one(0, RangeElement::data(vec![1]))
            .with(100, RangeElement::data(vec![2]))
            .with(999, RangeElement::data(vec![3]));

        let chunk_ref = edition_to_chunks(&edition, &store).unwrap();
        let restored = edition_from_chunks(&chunk_ref, &store).unwrap();

        assert_eq!(restored.count(), 3);
        assert!(restored.has_position(0));
        assert!(restored.has_position(100));
        assert!(restored.has_position(999));

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn shared_chunks_deduplicate() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let edition_a = Edition::from_text("the quick brown fox");
        let edition_b = Edition::from_text("the quick brown fox");

        let ref_a = edition_to_chunks(&edition_a, &store).unwrap();
        let ref_b = edition_to_chunks(&edition_b, &store).unwrap();

        assert_eq!(ref_a.root_hash, ref_b.root_hash);

        let hashes = store.all_chunk_hashes().unwrap();
        let count_before = hashes.len();

        let _ref_b2 = edition_to_chunks(&edition_b, &store).unwrap();
        let hashes_after = store.all_chunk_hashes().unwrap();
        assert_eq!(hashes_after.len(), count_before);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn large_edition_creates_multiple_chunks() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let mut edition = Edition::empty();
        for i in 0..300i64 {
            edition = edition.with(i, RangeElement::data(format!("entry-{}", i).into_bytes()));
        }

        let chunk_ref = edition_to_chunks(&edition, &store).unwrap();
        assert_eq!(chunk_ref.entry_count, 300);

        let hashes = store.all_chunk_hashes().unwrap();
        let entry_chunks = hashes.len() - 1; // -1 for root chunk
        assert!(entry_chunks >= 2, "expected at least 2 entry chunks, got {}", entry_chunks);

        let restored = edition_from_chunks(&chunk_ref, &store).unwrap();
        assert_eq!(restored.count(), 300);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn work_roundtrip_current_only() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let edition = Edition::from_text("my document");
        let work = Work::new(42, edition);

        let chunk_ref = work_to_chunks(&work, &store).unwrap();
        assert_eq!(chunk_ref.be_id, 42);
        assert_eq!(chunk_ref.revision_count, 0);
        assert!(chunk_ref.history.is_empty());

        let restored = work_from_chunks_current(&chunk_ref, &store).unwrap();
        assert_eq!(restored.be_id(), 42);
        assert_eq!(restored.edition().to_text(), "my document");

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn work_roundtrip_with_history() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let v1 = Edition::from_text("version one");
        let v2 = Edition::from_text("version two");
        let v3 = Edition::from_text("version three");
        let mut work = Work::new(1, v1);
        work.revise(v2);
        work.revise(v3);

        let chunk_ref = work_to_chunks(&work, &store).unwrap();
        assert_eq!(chunk_ref.revision_count, 2);
        assert_eq!(chunk_ref.history.len(), 2);

        let restored = work_from_chunks_current(&chunk_ref, &store).unwrap();
        assert_eq!(restored.edition().to_text(), "version three");
        assert_eq!(restored.revision_count(), 2);

        let rev0 = work_load_revision(&chunk_ref, 0, &store).unwrap();
        assert_eq!(rev0.to_text(), "version one");

        let rev1 = work_load_revision(&chunk_ref, 1, &store).unwrap();
        assert_eq!(rev1.to_text(), "version two");

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn work_preserves_metadata() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let mut work = Work::new(1, Edition::from_text("content"));
        work.set_owner(Some(99));
        work.set_read_club(Some(10));
        work.set_edit_club(Some(20));
        work.add_sponsor(30);

        let chunk_ref = work_to_chunks(&work, &store).unwrap();
        assert_eq!(chunk_ref.owner, Some(99));
        assert_eq!(chunk_ref.read_club, Some(10));
        assert_eq!(chunk_ref.edit_club, Some(20));
        assert_eq!(chunk_ref.sponsors, vec![30]);

        let restored = work_from_chunks_current(&chunk_ref, &store).unwrap();
        assert_eq!(restored.owner(), Some(99));
        assert_eq!(restored.read_club(), Some(10));
        assert_eq!(restored.edit_club(), Some(20));
        assert_eq!(restored.sponsors(), &[30]);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn load_revision_current_equals_edition() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let edition = Edition::from_text("current");
        let mut work = Work::new(1, edition);
        work.revise(Edition::from_text("new current"));

        let chunk_ref = work_to_chunks(&work, &store).unwrap();

        let via_revision = work_load_revision(&chunk_ref, 1, &store).unwrap();
        let via_current = edition_from_chunks(&chunk_ref.current_root, &store).unwrap();

        assert_eq!(via_revision.to_text(), via_current.to_text());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn entry_count_matches_edition() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let mut edition = Edition::empty();
        for i in 0..50i64 {
            edition = edition.with(i, RangeElement::text(format!("e{}", i)));
        }

        let chunk_ref = edition_to_chunks(&edition, &store).unwrap();
        assert_eq!(chunk_ref.entry_count, 50);

        let _ = std::fs::remove_dir_all(&dir);
    }
}

pub fn collect_edition_hashes(
    chunk_ref: &EditionChunkRef,
    store: &ChunkStore,
) -> Result<HashSet<[u8; 32]>, ChunkSerError> {
    let mut hashes = HashSet::new();
    hashes.insert(chunk_ref.root_hash);
    let root_data = store.read_chunk(&chunk_ref.root_hash)?;
    let root: EditionRootChunk = deserialize_from_bytes(&root_data)?;
    for h in &root.entry_chunk_hashes {
        hashes.insert(*h);
    }
    Ok(hashes)
}

pub fn collect_work_hashes(
    work_ref: &WorkChunkRef,
    store: &ChunkStore,
) -> Result<HashSet<[u8; 32]>, ChunkSerError> {
    let mut hashes = collect_edition_hashes(&work_ref.current_root, store)?;
    for edition_ref in work_ref.history.values() {
        let edition_hashes = collect_edition_hashes(edition_ref, store)?;
        hashes.extend(edition_hashes);
    }
    Ok(hashes)
}
