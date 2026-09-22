//! FR-76 Phase 2: Transparent read path for evicted works.
//!
//! When a work's enfilade is frozen (evicted from RAM to chunks),
//! reads transparently fetch it back. The caller never knows the
//! work was evicted — the routing layer handles:
//!
//!   1. Active (RAM): the work's enfilade is in memory → direct read
//!   2. Cache (RAM): recently thawed works are cached → fast read
//!   3. Chunks (disk): thaw from the chunk store → cache → return
//!
//! Writes always promote the work back to active (mutable).

use crate::edition::epoch::{freeze_orgl, thaw_epoch_data, EpochId};
use crate::edition::orgl::OrglRoot;
use crate::persist::chunk_store::ChunkStore;
use std::collections::HashMap;
use std::time::Instant;

/// A work that has been evicted from the active set.
#[derive(Debug, Clone)]
pub struct EvictedWork {
    /// The chunk store hash for the orgl data.
    pub chunk_hash: [u8; 32],
    /// The epoch identity (root crum).
    pub epoch_id: EpochId,
    /// When this work was evicted.
    pub evicted_at: Instant,
    /// Entry count at eviction (for quick stats without thawing).
    pub entry_count: u64,
    /// Char length at eviction.
    pub char_length: u64,
}

/// A cached (thawed) work — brought back from chunks on demand.
#[derive(Debug)]
struct CachedWork {
    /// The thawed edition data.
    data: crate::edition::epoch::EpochData,
    /// When this was last accessed (for LRU eviction).
    last_access: Instant,
    /// Number of times this has been accessed (for stats).
    access_count: u64,
}

/// Statistics about the eviction/cache state.
#[derive(Debug, Default, Clone, serde::Serialize)]
pub struct EvictionStats {
    pub active_works: usize,
    pub evicted_works: usize,
    pub cached_works: usize,
    pub cache_hits: u64,
    pub cache_misses: u64,
    pub disk_reads: u64,
    pub evictions_performed: u64,
    pub cache_evictions: u64,
    pub total_entries_evicted: u64,
    pub total_chars_evicted: u64,
}

/// The transparent read path: routes reads to active/cache/chunks.
///
/// Sits alongside the server's works HashMap. When a work is evicted:
/// - Its enfilade is frozen to a chunk (via freeze_orgl)
/// - Its WorkState stays in the server (metadata is small)
/// - The EvictionManager records the chunk_hash for later thaw
///
/// On read:
/// - Active → direct (caller already has it)
/// - Cache → return from cache (RAM speed)
/// - Chunks → read chunk → deserialize → cache → return
///
/// On write:
/// - The work must be promoted back to active (thaw if needed)
/// - The caller writes normally after promotion
pub struct EvictionManager {
    /// Works evicted from the active set (work_id → chunk pointer).
    evicted: HashMap<u64, EvictedWork>,

    /// Recently thawed works (LRU cache).
    cache: HashMap<u64, CachedWork>,

    /// Cache budget: max works to keep in the cache.
    cache_budget: usize,

    /// Active set budget: max works to keep in RAM before eviction.
    /// 0 = no automatic eviction (manual only).
    active_budget: usize,

    /// Reference to the chunk store for freeze/thaw.
    chunk_store: std::sync::Arc<ChunkStore>,

    /// Statistics.
    stats: EvictionStats,
}

impl EvictionManager {
    pub fn new(chunk_store: std::sync::Arc<ChunkStore>) -> Self {
        Self {
            evicted: HashMap::new(),
            cache: HashMap::new(),
            cache_budget: 100, // cache up to 100 thawed works
            active_budget: 0,  // no auto-eviction by default
            chunk_store,
            stats: EvictionStats::default(),
        }
    }

    pub fn with_budgets(
        chunk_store: std::sync::Arc<ChunkStore>,
        active_budget: usize,
        cache_budget: usize,
    ) -> Self {
        Self {
            evicted: HashMap::new(),
            cache: HashMap::new(),
            cache_budget,
            active_budget,
            chunk_store,
            stats: EvictionStats::default(),
        }
    }

    // ── Eviction: RAM → disk ──────────────────────────────────────

    /// Evict a work: freeze its enfilade to a chunk and record the
    /// pointer. The caller removes the work from the active set after
    /// this succeeds.
    pub fn evict(
        &mut self,
        work_id: u64,
        orgl: &OrglRoot,
        parent_epoch: Option<EpochId>,
    ) -> Result<EvictedWork, String> {
        // Freeze the orgl to a chunk
        let result = freeze_orgl(orgl, parent_epoch, &self.chunk_store)?;

        let entry = EvictedWork {
            chunk_hash: result.chunk_hash,
            epoch_id: result.epoch.root_crum,
            evicted_at: Instant::now(),
            entry_count: result.epoch.entry_count,
            char_length: result.epoch.char_length,
        };

        // Remove from cache if present (it's now on disk)
        self.cache.remove(&work_id);

        // Record the eviction
        self.evicted.insert(work_id, entry.clone());
        self.stats.evictions_performed += 1;
        self.stats.total_entries_evicted += entry.entry_count;
        self.stats.total_chars_evicted += entry.char_length;

        Ok(entry)
    }

    /// Check if the active set should evict (budget exceeded).
    pub fn should_evict(&self, active_count: usize) -> bool {
        self.active_budget > 0 && active_count > self.active_budget
    }

    // ── Read routing: active → cache → chunks ─────────────────────

    /// Check if a work is evicted (needs thawing).
    pub fn is_evicted(&self, work_id: u64) -> bool {
        self.evicted.contains_key(&work_id)
    }

    /// Read the text of an evicted work (transparent — the caller
    /// doesn't need to know the work is on disk).
    ///
    /// Check cache first (RAM), then chunks (disk). On cache miss,
    /// thaw from chunks and cache for future reads.
    pub fn read_work_text(&mut self, work_id: u64) -> Result<String, String> {
        // Check cache first
        if let Some(cached) = self.cache.get_mut(&work_id) {
            cached.last_access = Instant::now();
            cached.access_count += 1;
            self.stats.cache_hits += 1;

            // Clone the data to release the mutable borrow
            let data = cached.data.clone();
            return self.entries_to_text(&data);
        }

        self.stats.cache_misses += 1;

        // Not in cache — check if evicted
        let chunk_hash = self
            .evicted
            .get(&work_id)
            .map(|e| e.chunk_hash)
            .ok_or_else(|| format!("work {work_id} not evicted (should be in active set)"))?;

        // Thaw from chunks
        self.stats.disk_reads += 1;
        let data = thaw_epoch_data(&chunk_hash, &self.chunk_store)?;

        // Cache for future reads
        self.add_to_cache(work_id, data.clone());

        // Convert to text
        self.entries_to_text(&data)
    }

    /// Read the entries of an evicted work (for structural operations).
    pub fn read_work_entries(
        &mut self,
        work_id: u64,
    ) -> Result<crate::edition::epoch::EpochData, String> {
        // Check cache
        if let Some(cached) = self.cache.get_mut(&work_id) {
            cached.last_access = Instant::now();
            cached.access_count += 1;
            self.stats.cache_hits += 1;
            return Ok(cached.data.clone());
        }

        self.stats.cache_misses += 1;

        let chunk_hash = self
            .evicted
            .get(&work_id)
            .map(|e| e.chunk_hash)
            .ok_or_else(|| format!("work {work_id} not evicted"))?;

        self.stats.disk_reads += 1;
        let data = thaw_epoch_data(&chunk_hash, &self.chunk_store)?;
        self.add_to_cache(work_id, data.clone());
        Ok(data)
    }

    /// Promote an evicted work back to active (for writes).
    /// Returns the thawed entry data so the caller can rebuild the work.
    ///
    /// After promotion, the work is removed from the evicted set
    /// and the cache (it's now in the active/mutable set).
    pub fn promote_to_active(
        &mut self,
        work_id: u64,
    ) -> Result<crate::edition::epoch::EpochData, String> {
        // Check cache first (already thawed)
        if let Some(cached) = self.cache.remove(&work_id) {
            self.evicted.remove(&work_id);
            return Ok(cached.data);
        }

        // Thaw from chunks
        let chunk_hash = self
            .evicted
            .get(&work_id)
            .map(|e| e.chunk_hash)
            .ok_or_else(|| format!("work {work_id} not evicted"))?;

        self.stats.disk_reads += 1;
        let data = thaw_epoch_data(&chunk_hash, &self.chunk_store)?;

        // Remove from evicted (now active)
        self.evicted.remove(&work_id);

        Ok(data)
    }

    // ── Cache management ───────────────────────────────────────────

    fn add_to_cache(&mut self, work_id: u64, data: crate::edition::epoch::EpochData) {
        // Evict LRU entries if over budget
        while self.cache.len() >= self.cache_budget {
            self.evict_lru_from_cache();
        }

        self.cache.insert(
            work_id,
            CachedWork {
                data,
                last_access: Instant::now(),
                access_count: 1,
            },
        );
    }

    fn evict_lru_from_cache(&mut self) {
        if let Some((&oldest_id, _)) = self
            .cache
            .iter()
            .min_by_key(|(_, cached)| cached.last_access)
        {
            self.cache.remove(&oldest_id);
            self.stats.cache_evictions += 1;
        }
    }

    // ── Helpers ────────────────────────────────────────────────────

    /// Convert epoch entries back to text (position-ordered concatenation).
    fn entries_to_text(&self, data: &crate::edition::epoch::EpochData) -> Result<String, String> {
        let mut entries: Vec<&(i64, crate::edition::epoch::SerializableCarrier)> =
            data.entries.iter().collect();
        entries.sort_by_key(|(pos, _)| *pos);

        let mut text = String::new();
        for (_, carrier) in entries {
            match &carrier.element {
                crate::edition::range_element::RangeElement::Text { text: t } => {
                    text.push_str(t);
                }
                _ => {
                    return Err(
                        "non-text element in epoch data (transclusion/provenance entries not yet supported in text reconstruction)".to_string(),
                    )
                }
            }
        }
        Ok(text)
    }

    pub fn stats(&self) -> EvictionStats {
        let mut s = self.stats.clone();
        s.evicted_works = self.evicted.len();
        s.cached_works = self.cache.len();
        s
    }

    /// List all evicted work IDs.
    pub fn evicted_works(&self) -> Vec<u64> {
        self.evicted.keys().copied().collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── Eviction tests ─────────────────────────────────────────────

    #[test]
    fn evict_freezes_and_records() {
        let mut mgr = test_manager();
        let orgl = OrglRoot::empty().with(0, std::sync::Arc::new(test_carrier("evicted text")));

        let result = mgr.evict(1, &orgl, None);
        assert!(result.is_ok());
        let entry = result.unwrap();
        assert!(entry.entry_count > 0);
        assert!(entry.char_length > 0);
    }

    #[test]
    fn is_evicted_tracks_state() {
        let mut mgr = test_manager();
        assert!(!mgr.is_evicted(1));

        let orgl = OrglRoot::empty().with(0, std::sync::Arc::new(test_carrier("track me")));
        mgr.evict(1, &orgl, None).unwrap();
        assert!(mgr.is_evicted(1));
        assert!(!mgr.is_evicted(2));
    }

    #[test]
    fn evict_updates_stats() {
        let mut mgr = test_manager();
        let orgl = OrglRoot::empty().with(0, std::sync::Arc::new(test_carrier("stats test")));

        let before = mgr.stats().evictions_performed;
        mgr.evict(1, &orgl, None).unwrap();
        let after = mgr.stats().evictions_performed;
        assert_eq!(after, before + 1);
    }

    // ── Read path tests ────────────────────────────────────────────

    #[test]
    fn read_evicted_work_from_disk() {
        let mut mgr = test_manager();
        let orgl = OrglRoot::empty().with(0, std::sync::Arc::new(test_carrier("read from disk")));

        mgr.evict(1, &orgl, None).unwrap();

        // First read: cache miss, disk read
        let text = mgr.read_work_text(1).unwrap();
        assert_eq!(text, "read from disk");
        assert_eq!(mgr.stats().cache_misses, 1);
        assert_eq!(mgr.stats().disk_reads, 1);
    }

    #[test]
    fn second_read_hits_cache() {
        let mut mgr = test_manager();
        let orgl = OrglRoot::empty().with(0, std::sync::Arc::new(test_carrier("cache hit test")));

        mgr.evict(1, &orgl, None).unwrap();

        // First read: miss (disk)
        mgr.read_work_text(1).unwrap();
        assert_eq!(mgr.stats().cache_hits, 0);
        assert_eq!(mgr.stats().cache_misses, 1);

        // Second read: hit (cache)
        let text = mgr.read_work_text(1).unwrap();
        assert_eq!(text, "cache hit test");
        assert_eq!(mgr.stats().cache_hits, 1);
    }

    #[test]
    fn read_nonevicted_work_fails() {
        let mut mgr = test_manager();
        // Work 999 was never evicted
        assert!(mgr.read_work_text(999).is_err());
    }

    #[test]
    fn multi_entry_text_reconstruction() {
        let mut mgr = test_manager();
        let orgl = OrglRoot::empty()
            .with(0, std::sync::Arc::new(test_carrier("first")))
            .with(1, std::sync::Arc::new(test_carrier("second")))
            .with(2, std::sync::Arc::new(test_carrier("third")));

        mgr.evict(1, &orgl, None).unwrap();

        let text = mgr.read_work_text(1).unwrap();
        assert!(text.contains("first"));
        assert!(text.contains("second"));
        assert!(text.contains("third"));
    }

    // ── Promotion tests ────────────────────────────────────────────

    #[test]
    fn promote_returns_data_and_clears_eviction() {
        let mut mgr = test_manager();
        let orgl = OrglRoot::empty().with(0, std::sync::Arc::new(test_carrier("promote me")));

        mgr.evict(1, &orgl, None).unwrap();
        assert!(mgr.is_evicted(1));

        let data = mgr.promote_to_active(1).unwrap();
        assert!(!data.entries.is_empty());
        assert!(!mgr.is_evicted(1), "work should no longer be evicted");
    }

    #[test]
    fn promote_from_cache_is_fast() {
        let mut mgr = test_manager();
        let orgl = OrglRoot::empty().with(0, std::sync::Arc::new(test_carrier("cached promote")));

        mgr.evict(1, &orgl, None).unwrap();

        // Read first (populates cache)
        mgr.read_work_text(1).unwrap();
        let disk_reads_before = mgr.stats().disk_reads;

        // Promote (should use cache, no additional disk read)
        mgr.promote_to_active(1).unwrap();
        assert_eq!(
            mgr.stats().disk_reads,
            disk_reads_before,
            "promotion from cache should not hit disk"
        );
    }

    #[test]
    fn promote_nonevicted_fails() {
        let mut mgr = test_manager();
        assert!(mgr.promote_to_active(999).is_err());
    }

    // ── Cache management tests ─────────────────────────────────────

    #[test]
    fn cache_respects_budget() {
        let store = std::sync::Arc::new(test_store());
        let mut mgr = EvictionManager::with_budgets(store, 0, 3); // budget=3

        // Evict and read 5 works (cache budget is 3)
        for i in 1..=5 {
            let orgl = OrglRoot::empty().with(0, make_arc(&format!("work {}", i)));
            mgr.evict(i, &orgl, None).unwrap();
            mgr.read_work_text(i).unwrap();
        }

        // Cache should have evicted LRU entries
        let stats = mgr.stats();
        assert!(stats.cached_works <= 3, "cache should be within budget");
        assert!(stats.cache_evictions > 0, "should have evicted from cache");
    }

    #[test]
    fn lru_eviction_removes_oldest_first() {
        let store = std::sync::Arc::new(test_store());
        let mut mgr = EvictionManager::with_budgets(store, 0, 2);

        // Evict works 1, 2, 3 and read them in order
        for i in 1..=3 {
            let orgl = OrglRoot::empty().with(0, make_arc(&format!("lru {}", i)));
            mgr.evict(i, &orgl, None).unwrap();
            mgr.read_work_text(i).unwrap();
        }

        // With budget=2, reading work 3 should have evicted work 1 (LRU)
        // Reading work 1 again should be a disk read (was evicted from cache)
        let before = mgr.stats().disk_reads;
        mgr.read_work_text(1).unwrap();
        assert!(
            mgr.stats().disk_reads > before,
            "work 1 should have been evicted from cache (LRU)"
        );
    }

    // ── Statistics tests ───────────────────────────────────────────

    #[test]
    fn stats_track_all_operations() {
        let mut mgr = test_manager();

        // Evict two works
        for i in 1..=2 {
            let orgl = OrglRoot::empty().with(0, make_arc(&format!("stat {}", i)));
            mgr.evict(i, &orgl, None).unwrap();
        }

        // Read work 1 (miss → disk), then again (hit → cache)
        mgr.read_work_text(1).unwrap();
        mgr.read_work_text(1).unwrap();

        let stats = mgr.stats();
        assert_eq!(stats.evicted_works, 2);
        assert_eq!(stats.cache_hits, 1);
        assert_eq!(stats.cache_misses, 1);
        assert_eq!(stats.disk_reads, 1);
        assert_eq!(stats.evictions_performed, 2);
    }

    // ── Budget tests ───────────────────────────────────────────────

    #[test]
    fn should_evict_respects_budget() {
        let store = std::sync::Arc::new(test_store());
        let mut mgr = EvictionManager::with_budgets(store, 100, 10);

        assert!(!mgr.should_evict(99), "under budget: no eviction");
        assert!(!mgr.should_evict(100), "at budget: no eviction");
        assert!(mgr.should_evict(101), "over budget: should evict");
    }

    #[test]
    fn zero_budget_never_auto_evicts() {
        let store = std::sync::Arc::new(test_store());
        let mut mgr = EvictionManager::with_budgets(store, 0, 10);

        assert!(
            !mgr.should_evict(1_000_000),
            "zero budget = no auto-eviction"
        );
    }

    // ── Helpers ────────────────────────────────────────────────────

    fn test_carrier(text: &str) -> crate::edition::range_element::Carrier {
        crate::edition::range_element::Carrier::new(
            crate::edition::range_element::RangeElement::text(text.to_string()),
        )
    }

    fn make_arc(text: &str) -> std::sync::Arc<crate::edition::range_element::Carrier> {
        std::sync::Arc::new(test_carrier(text))
    }

    fn test_manager() -> EvictionManager {
        EvictionManager::new(std::sync::Arc::new(test_store()))
    }

    fn test_store() -> ChunkStore {
        let dir = std::env::temp_dir().join(format!(
            "xudanu-evict-{}-{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_nanos()
        ));
        std::fs::create_dir_all(&dir).unwrap();
        ChunkStore::open(&dir).unwrap()
    }
}
