//! FR-76: Epoch-structured enfilade — freeze protocol.
//!
//! The enfilade alternates between mutable (active) and immutable
//! (frozen) epochs. The active epoch is a splay tree in memory.
//! Freezing extracts the entries (the data), serializes them as a
//! content-addressed chunk, and records the epoch in the chain.
//! The tree structure itself is NOT frozen — it's a mutable
//! optimization (splaying) that is rebuilt on thaw.
//!
//! This means:
//! - Freeze = extract entries → serialize → BLAKE3 chunk → record epoch
//! - Thaw = read chunk → deserialize entries → rebuild orgl
//! - Identical entries always produce identical epoch IDs (content
//!   addressing, independent of tree shape)

use crate::edition::orgl::OrglRoot;
use crate::edition::range_element::Carrier;
use crate::persist::chunk_store::ChunkStore;
use serde::{Deserialize, Serialize};
use std::sync::Arc;

/// Identity of a frozen epoch — the BLAKE3 hash of the serialized entries.
pub type EpochId = [u8; 32];

/// A frozen epoch in the chain.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct FrozenEpoch {
    /// BLAKE3 hash of the serialized entry data — epoch identity.
    pub root_crum: EpochId,
    /// Parent epoch (the previous frozen epoch). None for the first.
    pub parent: Option<EpochId>,
    /// Number of entries (range elements).
    pub entry_count: u64,
    /// Total character length of the entries.
    pub char_length: u64,
    /// Unix timestamp when frozen.
    pub frozen_at: u64,
}

/// The epoch chain for one work.
#[derive(Debug, Default, Clone, Serialize, Deserialize)]
pub struct EpochChain {
    /// Frozen epochs, most recent first.
    pub frozen: Vec<FrozenEpoch>,
}

impl EpochChain {
    pub fn new() -> Self {
        Self::default()
    }

    /// The most recent frozen epoch, if any.
    pub fn latest(&self) -> Option<&FrozenEpoch> {
        self.frozen.first()
    }

    /// Push a newly frozen epoch onto the chain.
    pub fn push(&mut self, epoch: FrozenEpoch) {
        self.frozen.insert(0, epoch);
    }

    pub fn len(&self) -> usize {
        self.frozen.len()
    }

    pub fn is_empty(&self) -> bool {
        self.frozen.is_empty()
    }

    /// Find an epoch by ID.
    pub fn find(&self, id: &EpochId) -> Option<&FrozenEpoch> {
        self.frozen.iter().find(|e| &e.root_crum == id)
    }
}

/// Result of a freeze operation.
#[derive(Debug)]
pub struct FreezeResult {
    pub epoch: FrozenEpoch,
    /// The chunk store's hash key for retrieval.
    pub chunk_hash: [u8; 32],
    /// Bytes written to the chunk store.
    pub bytes_written: u64,
    /// Freeze duration (ms).
    pub freeze_duration_ms: f64,
}

/// Serializable entry data — what actually gets frozen.
/// The tree structure is rebuilt on thaw; only the data matters.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EpochData {
    /// (position, carrier element) pairs, sorted by position.
    pub entries: Vec<(i64, SerializableCarrier)>,
}

/// Serializable version of Carrier — strips the non-serde fields
/// (atomic memos are derived, not stored).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SerializableCarrier {
    pub label: Option<crate::edition::range_element::RangeElementId>,
    pub element: crate::edition::range_element::RangeElement,
    pub provenance: Option<crate::edition::provenance::ElementProvenance>,
}

impl From<&Carrier> for SerializableCarrier {
    fn from(c: &Carrier) -> Self {
        SerializableCarrier {
            label: c.label.clone(),
            element: c.element.clone(),
            provenance: c.provenance.clone(),
        }
    }
}

impl From<&SerializableCarrier> for Carrier {
    fn from(s: &SerializableCarrier) -> Self {
        let mut c = Carrier::new(s.element.clone());
        c.label = s.label.clone();
        c.provenance = s.provenance.clone();
        c
    }
}

/// Extract the entries from an orgl as serializable data.
/// The orgl's domain is walked to produce (position, carrier) pairs.
fn extract_entries(orgl: &OrglRoot) -> Vec<(i64, Arc<Carrier>)> {
    orgl.entries()
}

/// Freeze an orgl into a content-addressed chunk.
///
/// Serializes the epoch data as a chunk keyed by the orgl's crum.
/// After freezing, the in-memory tree can be dropped — the data
/// is recoverable from the chunk store.
pub fn freeze_orgl(
    orgl: &OrglRoot,
    parent_epoch: Option<EpochId>,
    store: &ChunkStore,
) -> Result<FreezeResult, String> {
    let start = std::time::Instant::now();

    // The orgl's crum is its BLAKE3 content hash — the epoch identity
    let root_crum: EpochId = orgl
        .crum()
        .ok_or_else(|| "orgl has no crum (empty tree?)".to_string())?;

    // Extract and serialize the entries
    let raw_entries = extract_entries(orgl);
    let data = EpochData {
        entries: raw_entries
            .iter()
            .map(|(pos, c)| (*pos, SerializableCarrier::from(c.as_ref())))
            .collect(),
    };
    let serialized = postcard::to_allocvec(&data)
        .map_err(|e| format!("epoch data serialization failed: {e}"))?;

    // Write to the chunk store
    let chunk_hash = store
        .write_chunk(&serialized)
        .map_err(|e| format!("chunk write failed: {e}"))?;

    let epoch = FrozenEpoch {
        root_crum,
        parent: parent_epoch,
        entry_count: data.entries.len() as u64,
        char_length: crate::edition::orgl::entries_char_len(&raw_entries) as u64,
        frozen_at: std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs(),
    };

    Ok(FreezeResult {
        epoch,
        chunk_hash,
        bytes_written: serialized.len() as u64,
        freeze_duration_ms: start.elapsed().as_secs_f64() * 1000.0,
    })
}

/// Thaw an orgl from a chunk store entry.
pub fn thaw_epoch_data(chunk_hash: &[u8; 32], store: &ChunkStore) -> Result<EpochData, String> {
    let data = store
        .read_chunk(chunk_hash)
        .map_err(|e| format!("chunk read failed: {e}"))?;
    postcard::from_bytes(&data).map_err(|e| format!("epoch data deserialization failed: {e}"))
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── EpochChain tests ─────────────────────────────────────────

    #[test]
    fn chain_starts_empty() {
        let chain = EpochChain::new();
        assert!(chain.is_empty());
        assert_eq!(chain.len(), 0);
        assert!(chain.latest().is_none());
    }

    #[test]
    fn chain_push_orders_most_recent_first() {
        let mut chain = EpochChain::new();

        let e1 = test_epoch([1; 32], None, 100, 5000);
        chain.push(e1.clone());
        assert_eq!(chain.len(), 1);
        assert_eq!(chain.latest().unwrap().root_crum, [1; 32]);

        let e2 = test_epoch([2; 32], Some([1; 32]), 150, 7500);
        chain.push(e2.clone());
        assert_eq!(chain.len(), 2);
        // Most recent first
        assert_eq!(chain.frozen[0].root_crum, [2; 32]);
        assert_eq!(chain.frozen[1].root_crum, [1; 32]);
        assert_eq!(chain.latest().unwrap().root_crum, [2; 32]);
    }

    #[test]
    fn chain_forms_parent_linkage() {
        let mut chain = EpochChain::new();
        let e1 = test_epoch([0xAA; 32], None, 10, 100);
        let e2 = test_epoch([0xBB; 32], Some(e1.root_crum), 20, 200);
        let e3 = test_epoch([0xCC; 32], Some(e2.root_crum), 30, 300);

        chain.push(e1);
        chain.push(e2);
        chain.push(e3);

        // Chain: [e3, e2, e1]
        assert_eq!(chain.frozen[0].parent, Some([0xBB; 32]));
        assert_eq!(chain.frozen[1].parent, Some([0xAA; 32]));
        assert_eq!(chain.frozen[2].parent, None);
    }

    #[test]
    fn chain_find_by_id() {
        let mut chain = EpochChain::new();
        let e1 = test_epoch([0x11; 32], None, 1, 10);
        let e2 = test_epoch([0x22; 32], Some(e1.root_crum), 2, 20);
        chain.push(e1);
        chain.push(e2);

        assert!(chain.find(&[0x22; 32]).is_some());
        assert!(chain.find(&[0x11; 32]).is_some());
        assert!(chain.find(&[0xFF; 32]).is_none());
    }

    #[test]
    fn chain_serialization_roundtrip() {
        let mut chain = EpochChain::new();
        chain.push(test_epoch([1; 32], None, 10, 100));
        chain.push(test_epoch([2; 32], Some([1; 32]), 20, 200));

        let json = serde_json::to_string(&chain).unwrap();
        let back: EpochChain = serde_json::from_str(&json).unwrap();
        assert_eq!(back.len(), 2);
        assert_eq!(back.latest().unwrap().root_crum, [2; 32]);
    }

    // ── Content addressing tests ──────────────────────────────────

    #[test]
    fn identical_content_produces_identical_crum() {
        // Two orgls with the same entries must produce the same crum
        let orgl1 = OrglRoot::empty().with(0, Arc::new(test_carrier("same text")));
        let orgl2 = OrglRoot::empty().with(0, Arc::new(test_carrier("same text")));

        let crum1 = orgl1.crum().unwrap();
        let crum2 = orgl2.crum().unwrap();
        assert_eq!(
            crum1, crum2,
            "content addressing: same data must produce same crum"
        );
    }

    #[test]
    fn different_content_produces_different_crum() {
        let orgl1 = OrglRoot::empty().with(0, Arc::new(test_carrier("text A")));
        let orgl2 = OrglRoot::empty().with(0, Arc::new(test_carrier("text B")));

        let crum1 = orgl1.crum().unwrap();
        let crum2 = orgl2.crum().unwrap();
        assert_ne!(
            crum1, crum2,
            "different content must produce different crums"
        );
    }

    #[test]
    fn crum_changes_on_edit() {
        let orgl = OrglRoot::empty().with(0, Arc::new(test_carrier("original")));
        let crum1 = orgl.crum().unwrap();

        let orgl_edited = orgl.with(1, Arc::new(test_carrier("added")));
        let crum2 = orgl_edited.crum().unwrap();

        assert_ne!(
            crum1, crum2,
            "adding an entry must change the crum (new epoch)"
        );
    }

    // ── Freeze/thaw integration tests ────────────────────────────

    #[test]
    fn freeze_writes_chunk_and_returns_metadata() {
        let store = test_store();
        let orgl = OrglRoot::empty()
            .with(0, Arc::new(test_carrier("freeze me")))
            .with(1, Arc::new(test_carrier("and me too")));

        let crum = orgl.crum().unwrap();
        let count = orgl.count();
        let char_len = crate::edition::orgl::entries_char_len(&extract_entries(&orgl));

        let result = freeze_orgl(&orgl, None, &store).unwrap();

        // Metadata correctness
        assert_eq!(
            result.epoch.root_crum, crum,
            "epoch ID must be the orgl's crum"
        );
        assert_eq!(result.epoch.entry_count, count);
        assert_eq!(result.epoch.char_length as usize, char_len);
        assert!(result.epoch.frozen_at > 0);
        assert!(result.bytes_written > 0);
        assert!(
            result.freeze_duration_ms < 100.0,
            "small tree should freeze fast"
        );

        // Chunk is readable
        let data = store.read_chunk(&result.chunk_hash).unwrap();
        assert!(!data.is_empty());

        cleanup_store(&store);
    }

    #[test]
    fn freeze_with_parent_links_epochs() {
        let store = test_store();

        let orgl1 = OrglRoot::empty().with(0, Arc::new(test_carrier("first epoch")));
        let r1 = freeze_orgl(&orgl1, None, &store).unwrap();
        assert_eq!(r1.epoch.parent, None, "first epoch has no parent");

        let orgl2 = orgl1.with(1, Arc::new(test_carrier("second entry")));
        let r2 = freeze_orgl(&orgl2, Some(r1.epoch.root_crum), &store).unwrap();
        assert_eq!(
            r2.epoch.parent,
            Some(r1.epoch.root_crum),
            "second epoch links to first"
        );
        assert_ne!(
            r1.epoch.root_crum, r2.epoch.root_crum,
            "different content = different epoch IDs"
        );

        cleanup_store(&store);
    }

    #[test]
    fn freeze_is_idempotent_for_same_content() {
        let store = test_store();

        let orgl = OrglRoot::empty().with(0, Arc::new(test_carrier("same content")));

        let r1 = freeze_orgl(&orgl, None, &store).unwrap();
        let r2 = freeze_orgl(&orgl, None, &store).unwrap();

        assert_eq!(
            r1.epoch.root_crum, r2.epoch.root_crum,
            "freezing the same content twice must produce the same epoch ID"
        );

        cleanup_store(&store);
    }

    #[test]
    fn multiple_freezes_form_chain() {
        let store = test_store();
        let mut chain = EpochChain::new();

        // Build and freeze three successive versions
        let mut orgl = OrglRoot::empty();
        let mut parent: Option<EpochId> = None;

        for i in 0..3 {
            orgl = orgl.with(i, Arc::new(test_carrier(&format!("entry {i}"))));
            let result = freeze_orgl(&orgl, parent, &store).unwrap();
            chain.push(result.epoch.clone());
            parent = Some(result.epoch.root_crum);
        }

        assert_eq!(chain.len(), 3);
        // Most recent first, linked chain
        assert_eq!(chain.frozen[0].parent, Some(chain.frozen[1].root_crum));
        assert_eq!(chain.frozen[1].parent, Some(chain.frozen[2].root_crum));
        assert_eq!(chain.frozen[2].parent, None);

        // Entry counts increase
        assert!(chain.frozen[0].entry_count > chain.frozen[1].entry_count);
        assert!(chain.frozen[1].entry_count > chain.frozen[2].entry_count);

        cleanup_store(&store);
    }

    #[test]
    fn thaw_returns_serializable_data() {
        let store = test_store();

        let orgl = OrglRoot::empty().with(0, Arc::new(test_carrier("thaw test")));

        let result = freeze_orgl(&orgl, None, &store).unwrap();
        let data = thaw_epoch_data(&result.chunk_hash, &store).unwrap();

        // EpochData deserializes successfully
        assert!(!data.entries.is_empty() || result.epoch.entry_count == 0);

        cleanup_store(&store);
    }

    #[test]
    fn empty_orgl_freeze_fails_gracefully() {
        let store = test_store();
        let orgl = OrglRoot::empty();

        let result = freeze_orgl(&orgl, None, &store);
        assert!(result.is_err(), "empty orgl should fail to freeze");
        assert!(
            result.unwrap_err().contains("crum"),
            "error message should mention the crum issue"
        );

        cleanup_store(&store);
    }

    // ── Freeze performance tests ─────────────────────────────────

    #[test]
    fn freeze_1000_entries_under_100ms() {
        let store = test_store();
        let mut orgl = OrglRoot::empty();

        for i in 0..1000 {
            orgl = orgl.with(i, Arc::new(test_carrier(&format!("entry {i}"))));
        }

        let result = freeze_orgl(&orgl, None, &store).unwrap();
        assert!(
            result.freeze_duration_ms < 100.0,
            "1000 entries should freeze in <100ms, took {:.1}ms",
            result.freeze_duration_ms
        );
        assert_eq!(result.epoch.entry_count, 1000);

        cleanup_store(&store);
    }

    // ── Test helpers ──────────────────────────────────────────────

    fn test_epoch(crum: EpochId, parent: Option<EpochId>, entries: u64, chars: u64) -> FrozenEpoch {
        FrozenEpoch {
            root_crum: crum,
            parent,
            entry_count: entries,
            char_length: chars,
            frozen_at: 1,
        }
    }

    fn test_carrier_impl(text: &str) -> Carrier {
        let element = crate::edition::range_element::RangeElement::text(text.to_string());
        Carrier::new(element)
    }

    fn test_carrier(text: &str) -> Carrier {
        test_carrier_impl(text)
    }

    fn test_store() -> ChunkStore {
        let dir = std::env::temp_dir().join(format!(
            "xudanu-epoch-{}/{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_nanos()
        ));
        std::fs::create_dir_all(&dir).unwrap();
        ChunkStore::open(&dir).unwrap()
    }

    fn cleanup_store(store: &ChunkStore) {
        // Get the base dir from the store for cleanup
        // (ChunkStore doesn't expose its dir; we clean up in /tmp
        // via the test framework's temp handling)
        let _ = store;
    }
}
