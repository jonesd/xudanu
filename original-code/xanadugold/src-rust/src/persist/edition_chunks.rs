use std::collections::{BTreeMap, HashSet};

use crate::edition::backend::BeId;
use crate::edition::edition::Edition;
use crate::edition::persistent::EditionSnapshot;
use crate::edition::provenance::SpanProvenance;
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
    #[cfg_attr(feature = "serde", serde(default))]
    pub endorsements: Vec<(u64, u64)>,
}

const EDITION_CHUNK_FORMAT_VERSION: u32 = 1;

#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
struct EntryChunk {
    #[cfg_attr(feature = "serde", serde(default))]
    format_version: u32,
    entries: Vec<(i64, crate::edition::range_element::RangeElement)>,
    #[cfg_attr(feature = "serde", serde(default))]
    provenances: Vec<Option<crate::edition::provenance::ElementProvenance>>,
}

#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
struct ProvenanceChunk {
    #[cfg_attr(feature = "serde", serde(default))]
    format_version: u32,
    spans: Vec<SpanProvenance>,
}

#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
struct EditionRootChunk {
    #[cfg_attr(feature = "serde", serde(default))]
    format_version: u32,
    default: Option<crate::edition::range_element::RangeElement>,
    domain_start: Option<i64>,
    domain_infinite_above: bool,
    entry_count: u32,
    entry_chunk_hashes: Vec<[u8; 32]>,
    #[cfg_attr(feature = "serde", serde(default))]
    provenance_hash: Option<[u8; 32]>,
}

// Pre-versioning wire shapes (everything written before the format_version
// field existed). Postcard has no schema evolution, so adding the field was
// itself a format change: readers must fall back to these shapes when the
// versioned parse fails, or every pre-versioning data dir reads as corrupt.
#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
struct EntryChunkLegacy {
    entries: Vec<(i64, crate::edition::range_element::RangeElement)>,
    provenances: Vec<Option<crate::edition::provenance::ElementProvenance>>,
}

#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
struct ProvenanceChunkLegacy {
    spans: Vec<SpanProvenance>,
}

#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
struct EditionRootChunkLegacy {
    default: Option<crate::edition::range_element::RangeElement>,
    domain_start: Option<i64>,
    domain_infinite_above: bool,
    entry_count: u32,
    entry_chunk_hashes: Vec<[u8; 32]>,
    provenance_hash: Option<[u8; 32]>,
}

fn newer_format_error(chunk_kind: &str, found: u32) -> ChunkSerError {
    ChunkSerError::Serialization(format!(
        "{} chunk format_version {} is newer than supported {} — upgrade xudanu-server to open this data dir",
        chunk_kind, found, EDITION_CHUNK_FORMAT_VERSION
    ))
}

fn read_entry_chunk(bytes: &[u8]) -> Result<EntryChunk, ChunkSerError> {
    let versioned = deserialize_from_bytes::<EntryChunk>(bytes);
    if let Ok(chunk) = &versioned {
        if chunk.format_version == EDITION_CHUNK_FORMAT_VERSION {
            return Ok(chunk.clone());
        }
    }
    if let Ok(legacy) = deserialize_from_bytes::<EntryChunkLegacy>(bytes) {
        tracing::debug!("upgrading legacy entry chunk (pre format_version) in memory");
        return Ok(EntryChunk {
            format_version: EDITION_CHUNK_FORMAT_VERSION,
            entries: legacy.entries,
            provenances: legacy.provenances,
        });
    }
    match versioned {
        Ok(chunk) => Err(newer_format_error("entry", chunk.format_version)),
        Err(e) => Err(e),
    }
}

fn read_provenance_chunk(bytes: &[u8]) -> Result<ProvenanceChunk, ChunkSerError> {
    let versioned = deserialize_from_bytes::<ProvenanceChunk>(bytes);
    if let Ok(chunk) = &versioned {
        if chunk.format_version == EDITION_CHUNK_FORMAT_VERSION {
            return Ok(chunk.clone());
        }
    }
    if let Ok(legacy) = deserialize_from_bytes::<ProvenanceChunkLegacy>(bytes) {
        tracing::debug!("upgrading legacy provenance chunk (pre format_version) in memory");
        return Ok(ProvenanceChunk {
            format_version: EDITION_CHUNK_FORMAT_VERSION,
            spans: legacy.spans,
        });
    }
    match versioned {
        Ok(chunk) => Err(newer_format_error("provenance", chunk.format_version)),
        Err(e) => Err(e),
    }
}

fn read_edition_root_chunk(bytes: &[u8]) -> Result<EditionRootChunk, ChunkSerError> {
    let versioned = deserialize_from_bytes::<EditionRootChunk>(bytes);
    if let Ok(chunk) = &versioned {
        if chunk.format_version == EDITION_CHUNK_FORMAT_VERSION {
            return Ok(chunk.clone());
        }
    }
    if let Ok(legacy) = deserialize_from_bytes::<EditionRootChunkLegacy>(bytes) {
        tracing::debug!("upgrading legacy edition root chunk (pre format_version) in memory");
        return Ok(EditionRootChunk {
            format_version: EDITION_CHUNK_FORMAT_VERSION,
            default: legacy.default,
            domain_start: legacy.domain_start,
            domain_infinite_above: legacy.domain_infinite_above,
            entry_count: legacy.entry_count,
            entry_chunk_hashes: legacy.entry_chunk_hashes,
            provenance_hash: legacy.provenance_hash,
        });
    }
    match versioned {
        Ok(chunk) => Err(newer_format_error("edition root", chunk.format_version)),
        Err(e) => Err(e),
    }
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
    let postcard_data =
        postcard::to_allocvec(value).map_err(|e| ChunkSerError::Serialization(e.to_string()))?;
    Ok(crate::persist::chunk_store::tag_chunk_data(
        crate::persist::chunk_store::CHUNK_FORMAT_POSTCARD,
        &postcard_data,
    ))
}

fn deserialize_from_bytes<'a, T: serde::Deserialize<'a>>(
    bytes: &'a [u8],
) -> Result<T, ChunkSerError> {
    let (_, payload) = crate::persist::chunk_store::untag_chunk_data(bytes)
        .map_err(|e| ChunkSerError::ChunkStore(e))?;
    postcard::from_bytes(payload).map_err(|e| ChunkSerError::Serialization(e.to_string()))
}

pub fn edition_to_chunks(
    edition: &Edition,
    store: &ChunkStore,
) -> Result<EditionChunkRef, ChunkSerError> {
    edition_to_chunks_durable(edition, store, true)
}

pub fn edition_to_chunks_durable(
    edition: &Edition,
    store: &ChunkStore,
    durable: bool,
) -> Result<EditionChunkRef, ChunkSerError> {
    let snapshot = EditionSnapshot::from_edition(edition);

    let mut entry_chunk_hashes = Vec::new();
    for chunk_range in (0..snapshot.entries.len())
        .step_by(ENTRIES_PER_CHUNK)
        .map(|start| {
            let end = (start + ENTRIES_PER_CHUNK).min(snapshot.entries.len());
            start..end
        })
    {
        let entries = snapshot.entries[chunk_range.clone()].to_vec();
        let provenances = if snapshot.provenances.len() >= chunk_range.end {
            snapshot.provenances[chunk_range.clone()].to_vec()
        } else {
            vec![None; chunk_range.len()]
        };
        let entry_chunk = EntryChunk {
            format_version: EDITION_CHUNK_FORMAT_VERSION,
            entries,
            provenances,
        };
        let data = serialize_to_bytes(&entry_chunk)?;
        let hash = store.write_chunk_durable(&data, durable)?;
        entry_chunk_hashes.push(hash);
    }

    let provenance_hash = if snapshot.span_provenance.is_empty() {
        None
    } else {
        let prov_chunk = ProvenanceChunk {
            format_version: EDITION_CHUNK_FORMAT_VERSION,
            spans: snapshot.span_provenance,
        };
        let prov_data = serialize_to_bytes(&prov_chunk)?;
        Some(store.write_chunk_durable(&prov_data, durable)?)
    };

    let root_chunk = EditionRootChunk {
        format_version: EDITION_CHUNK_FORMAT_VERSION,
        default: snapshot.default,
        domain_start: snapshot.domain_start,
        domain_infinite_above: snapshot.domain_infinite_above,
        entry_count: snapshot.entries.len() as u32,
        entry_chunk_hashes,
        provenance_hash,
    };
    let root_data = serialize_to_bytes(&root_chunk)?;
    let root_hash = store.write_chunk_durable(&root_data, durable)?;

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
    let root = read_edition_root_chunk(&root_data)?;

    let mut all_entries = Vec::with_capacity(root.entry_count as usize);
    let mut all_provenances = Vec::with_capacity(root.entry_count as usize);
    for hash in &root.entry_chunk_hashes {
        let chunk_data = store.read_chunk(hash)?;
        let entry_chunk = read_entry_chunk(&chunk_data)?;
        all_entries.extend(entry_chunk.entries);
        all_provenances.extend(entry_chunk.provenances);
    }
    if all_entries.len() != root.entry_count as usize {
        return Err(ChunkSerError::Serialization(format!(
            "entry count mismatch: root claims {} entries, chunks hold {}",
            root.entry_count,
            all_entries.len()
        )));
    }

    let span_provenance = match root.provenance_hash {
        Some(hash) => match store.read_chunk(&hash) {
            Ok(data) => {
                let prov_chunk = read_provenance_chunk(&data);
                match prov_chunk {
                    Ok(c) => c.spans,
                    Err(e) => {
                        tracing::warn!("provenance chunk deserialization failed: {}", e);
                        Vec::new()
                    }
                }
            }
            Err(e) => {
                tracing::warn!("provenance chunk read failed: {}", e);
                Vec::new()
            }
        },
        None => Vec::new(),
    };

    let snapshot = EditionSnapshot {
        entries: all_entries,
        provenances: all_provenances,
        default: root.default,
        domain_start: root.domain_start,
        domain_infinite_above: root.domain_infinite_above,
        span_provenance,
    };
    Ok(snapshot.to_edition())
}

pub fn work_to_chunks(work: &Work, store: &ChunkStore) -> Result<WorkChunkRef, ChunkSerError> {
    work_to_chunks_durable(work, store, true)
}

pub fn work_to_chunks_durable(
    work: &Work,
    store: &ChunkStore,
    durable: bool,
) -> Result<WorkChunkRef, ChunkSerError> {
    work_to_chunks_with_history(work, store, durable, None)
}

/// Same as work_to_chunks_durable, but merges in preserved history from
/// before a server restart. The prev_history map contains chunk references
/// for revisions that existed before the current process started — these
/// aren't in work.revision_history() (which is empty after restart) but
/// their chunk data is still on disk.
pub fn work_to_chunks_with_history(
    work: &Work,
    store: &ChunkStore,
    durable: bool,
    prev_history: Option<&BTreeMap<u64, EditionChunkRef>>,
) -> Result<WorkChunkRef, ChunkSerError> {
    let current_root = edition_to_chunks_durable(work.edition(), store, durable)?;

    // Start with preserved history from before restart (if any)
    let mut history: BTreeMap<u64, EditionChunkRef> = match prev_history {
        Some(prev) => prev.clone(),
        None => BTreeMap::new(),
    };

    // Merge in new revisions from in-memory history (post-restart)
    for (rev_num, edition) in work.revision_history() {
        let chunk_ref = edition_to_chunks_durable(edition, store, durable)?;
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
        endorsements: work
            .endorsements()
            .iter()
            .map(|e| (e.club_id(), e.token_id()))
            .collect(),
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
    if !chunk_ref.endorsements.is_empty() {
        let es = crate::edition::endorsement::EndorsementSet::from_endorsements(
            chunk_ref
                .endorsements
                .iter()
                .map(|&(c, t)| crate::edition::endorsement::Endorsement::new(c, t))
                .collect(),
        );
        tracing::info!(
            "[restore] restoring {} endorsements for work {}",
            es.len(),
            chunk_ref.be_id
        );
        work.endorse(&es);
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
    let chunk_ref =
        work_chunk_ref
            .history
            .get(&revision)
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
        assert!(
            entry_chunks >= 2,
            "expected at least 2 entry chunks, got {}",
            entry_chunks
        );

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

    fn write_legacy_edition(edition: &Edition, store: &ChunkStore) -> EditionChunkRef {
        let snapshot = EditionSnapshot::from_edition(edition);

        let mut entry_chunk_hashes = Vec::new();
        for chunk_range in (0..snapshot.entries.len())
            .step_by(ENTRIES_PER_CHUNK)
            .map(|start| {
                let end = (start + ENTRIES_PER_CHUNK).min(snapshot.entries.len());
                start..end
            })
        {
            let entry_chunk = EntryChunkLegacy {
                entries: snapshot.entries[chunk_range.clone()].to_vec(),
                provenances: if snapshot.provenances.len() >= chunk_range.end {
                    snapshot.provenances[chunk_range.clone()].to_vec()
                } else {
                    vec![None; chunk_range.len()]
                },
            };
            let data = serialize_to_bytes(&entry_chunk).unwrap();
            entry_chunk_hashes.push(store.write_chunk(&data).unwrap());
        }

        let root_chunk = EditionRootChunkLegacy {
            default: snapshot.default,
            domain_start: snapshot.domain_start,
            domain_infinite_above: snapshot.domain_infinite_above,
            entry_count: snapshot.entries.len() as u32,
            entry_chunk_hashes,
            provenance_hash: None,
        };
        let root_data = serialize_to_bytes(&root_chunk).unwrap();
        let root_hash = store.write_chunk(&root_data).unwrap();

        EditionChunkRef {
            root_hash,
            entry_count: snapshot.entries.len() as u32,
        }
    }

    #[test]
    fn legacy_chunks_still_load() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let edition = Edition::from_text("written before format_version existed");
        let chunk_ref = write_legacy_edition(&edition, &store);

        let restored = edition_from_chunks(&chunk_ref, &store).unwrap();
        assert_eq!(restored.to_text(), "written before format_version existed");

        let hashes = collect_edition_hashes(&chunk_ref, &store).unwrap();
        assert!(hashes.contains(&chunk_ref.root_hash));

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn legacy_and_versioned_chunks_coexist() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let legacy_ref = write_legacy_edition(&Edition::from_text("old format"), &store);
        let new_ref = edition_to_chunks(&Edition::from_text("new format"), &store).unwrap();

        assert_eq!(
            edition_from_chunks(&legacy_ref, &store).unwrap().to_text(),
            "old format"
        );
        assert_eq!(
            edition_from_chunks(&new_ref, &store).unwrap().to_text(),
            "new format"
        );

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn future_version_chunk_rejected() {
        let bytes = serialize_to_bytes(&EntryChunk {
            format_version: EDITION_CHUNK_FORMAT_VERSION + 1,
            entries: Vec::new(),
            provenances: Vec::new(),
        })
        .unwrap();

        let err = read_entry_chunk(&bytes).unwrap_err().to_string();
        assert!(err.contains("newer than supported"), "got: {}", err);
    }

    #[test]
    fn entry_count_mismatch_rejected() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let entry_chunk = EntryChunk {
            format_version: EDITION_CHUNK_FORMAT_VERSION,
            entries: vec![(0, RangeElement::text("a"))],
            provenances: vec![None],
        };
        let data = serialize_to_bytes(&entry_chunk).unwrap();
        let entry_hash = store.write_chunk(&data).unwrap();

        let root_chunk = EditionRootChunk {
            format_version: EDITION_CHUNK_FORMAT_VERSION,
            default: None,
            domain_start: None,
            domain_infinite_above: true,
            entry_count: 5,
            entry_chunk_hashes: vec![entry_hash],
            provenance_hash: None,
        };
        let root_data = serialize_to_bytes(&root_chunk).unwrap();
        let root_hash = store.write_chunk(&root_data).unwrap();

        let chunk_ref = EditionChunkRef {
            root_hash,
            entry_count: 5,
        };
        let err = edition_from_chunks(&chunk_ref, &store)
            .unwrap_err()
            .to_string();
        assert!(err.contains("entry count mismatch"), "got: {}", err);

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
    let root = read_edition_root_chunk(&root_data)?;
    for h in &root.entry_chunk_hashes {
        hashes.insert(*h);
    }
    if let Some(ph) = &root.provenance_hash {
        hashes.insert(*ph);
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
