use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicU64, Ordering as AtomicOrdering};
use std::sync::Mutex;

const CACHE_CAPACITY: usize = 1024;

#[derive(Debug)]
pub enum ChunkError {
    Io(String),
    HashMismatch { expected: String, actual: String },
    CorruptData(String),
}

impl std::fmt::Display for ChunkError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ChunkError::Io(e) => write!(f, "io error: {}", e),
            ChunkError::HashMismatch { expected, actual } => {
                write!(f, "hash mismatch: expected {}, got {}", expected, actual)
            }
            ChunkError::CorruptData(e) => write!(f, "corrupt chunk: {}", e),
        }
    }
}

impl std::error::Error for ChunkError {}

fn hash_to_hex(hash: &[u8; 32]) -> String {
    hash.iter().map(|b| format!("{:02x}", b)).collect()
}

fn hex_to_hash(hex: &str) -> Option<[u8; 32]> {
    if hex.len() != 64 {
        return None;
    }
    let mut result = [0u8; 32];
    for i in 0..32 {
        result[i] = u8::from_str_radix(&hex[i * 2..i * 2 + 2], 16).ok()?;
    }
    Some(result)
}

fn compute_hash(data: &[u8]) -> [u8; 32] {
    blake3::hash(data).into()
}

fn chunk_dir(base: &Path, hash: &[u8; 32]) -> PathBuf {
    let hex = hash_to_hex(hash);
    let prefix = &hex[..2];
    base.join("chunks").join(prefix)
}

fn chunk_path(base: &Path, hash: &[u8; 32]) -> PathBuf {
    chunk_dir(base, hash).join(hash_to_hex(hash))
}

struct Cache {
    entries: HashMap<[u8; 32], Vec<u8>>,
    order: Vec<[u8; 32]>,
    capacity: usize,
}

impl std::fmt::Debug for Cache {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Cache")
            .field("len", &self.entries.len())
            .field("capacity", &self.capacity)
            .finish()
    }
}

impl Cache {
    fn new(capacity: usize) -> Self {
        Cache {
            entries: HashMap::new(),
            order: Vec::new(),
            capacity,
        }
    }

    fn get(&mut self, hash: &[u8; 32]) -> Option<&Vec<u8>> {
        if self.entries.contains_key(hash) {
            if let Some(pos) = self.order.iter().position(|h| h == hash) {
                let entry = self.order.remove(pos);
                self.order.push(entry);
            }
        }
        self.entries.get(hash)
    }

    fn insert(&mut self, hash: [u8; 32], data: Vec<u8>) {
        if self.entries.contains_key(&hash) {
            return;
        }
        if self.order.len() >= self.capacity {
            if let Some(evict) = self.order.first().copied() {
                self.order.remove(0);
                self.entries.remove(&evict);
            }
        }
        self.order.push(hash);
        self.entries.insert(hash, data);
    }

    fn len(&self) -> usize {
        self.entries.len()
    }

    fn clear(&mut self) {
        self.entries.clear();
        self.order.clear();
    }
}

#[derive(Debug)]
pub struct ChunkStore {
    base_dir: PathBuf,
    cache: Mutex<Cache>,
    cache_hits: AtomicU64,
    cache_misses: AtomicU64,
}

impl ChunkStore {
    pub fn open(base_dir: &Path) -> Result<Self, ChunkError> {
        let chunks_dir = base_dir.join("chunks");
        std::fs::create_dir_all(&chunks_dir)
            .map_err(|e| ChunkError::Io(e.to_string()))?;
        Ok(ChunkStore {
            base_dir: base_dir.to_path_buf(),
            cache: Mutex::new(Cache::new(CACHE_CAPACITY)),
            cache_hits: AtomicU64::new(0),
            cache_misses: AtomicU64::new(0),
        })
    }

    pub fn write_chunk(&self, data: &[u8]) -> Result<[u8; 32], ChunkError> {
        let hash = compute_hash(data);
        let path = chunk_path(&self.base_dir, &hash);
        {
            let mut cache = self.cache.lock().unwrap_or_else(|e| e.into_inner());
            if cache.get(&hash).is_some() || path.exists() {
                return Ok(hash);
            }
            let dir = chunk_dir(&self.base_dir, &hash);
            std::fs::create_dir_all(&dir)
                .map_err(|e| ChunkError::Io(e.to_string()))?;
            let tmp_path = path.with_extension("tmp");
            std::fs::write(&tmp_path, data)
                .map_err(|e| ChunkError::Io(e.to_string()))?;
            std::fs::rename(&tmp_path, &path)
                .map_err(|e| ChunkError::Io(e.to_string()))?;
            cache.insert(hash, data.to_vec());
        }
        Ok(hash)
    }

    pub fn read_chunk(&self, hash: &[u8; 32]) -> Result<Vec<u8>, ChunkError> {
        {
            let mut cache = self.cache.lock().unwrap_or_else(|e| e.into_inner());
            if let Some(data) = cache.get(hash).cloned() {
                self.cache_hits.fetch_add(1, AtomicOrdering::Relaxed);
                return Ok(data);
            }
        }
        self.cache_misses.fetch_add(1, AtomicOrdering::Relaxed);
        let path = chunk_path(&self.base_dir, hash);
        if !path.exists() {
            return Err(ChunkError::CorruptData(format!(
                "chunk not found: {}", hash_to_hex(hash)
            )));
        }
        let data = std::fs::read(&path)
            .map_err(|e| ChunkError::Io(e.to_string()))?;
        let actual = compute_hash(&data);
        if &actual != hash {
            return Err(ChunkError::HashMismatch {
                expected: hash_to_hex(hash),
                actual: hash_to_hex(&actual),
            });
        }
        self.cache.lock().unwrap_or_else(|e| e.into_inner()).insert(*hash, data.clone());
        Ok(data)
    }

    pub fn chunk_exists(&self, hash: &[u8; 32]) -> bool {
        chunk_path(&self.base_dir, hash).exists()
    }

    pub fn delete_chunk(&self, hash: &[u8; 32]) -> Result<(), ChunkError> {
        let path = chunk_path(&self.base_dir, hash);
        if path.exists() {
            std::fs::remove_file(&path)
                .map_err(|e| ChunkError::Io(e.to_string()))?;
        }
        {
            let mut cache = self.cache.lock().unwrap_or_else(|e| e.into_inner());
            cache.entries.remove(hash);
            cache.order.retain(|h| h != hash);
        }
        Ok(())
    }

    pub fn verify_chunk(&self, hash: &[u8; 32]) -> Result<(), ChunkError> {
        let data = std::fs::read(chunk_path(&self.base_dir, hash))
            .map_err(|e| ChunkError::Io(e.to_string()))?;
        let actual = compute_hash(&data);
        if &actual != hash {
            return Err(ChunkError::HashMismatch {
                expected: hash_to_hex(hash),
                actual: hash_to_hex(&actual),
            });
        }
        Ok(())
    }

    pub fn all_chunk_hashes(&self) -> Result<Vec<[u8; 32]>, ChunkError> {
        let chunks_dir = self.base_dir.join("chunks");
        if !chunks_dir.exists() {
            return Ok(Vec::new());
        }
        let mut hashes = Vec::new();
        for entry in std::fs::read_dir(&chunks_dir)
            .map_err(|e| ChunkError::Io(e.to_string()))?
        {
            let entry = entry.map_err(|e| ChunkError::Io(e.to_string()))?;
            if !entry.path().is_dir() {
                continue;
            }
            for file_entry in std::fs::read_dir(entry.path())
                .map_err(|e| ChunkError::Io(e.to_string()))?
            {
                let file_entry = file_entry.map_err(|e| ChunkError::Io(e.to_string()))?;
                let name = file_entry.file_name();
                let name_str = name.to_string_lossy();
                if name_str.ends_with(".tmp") {
                    continue;
                }
                if let Some(hash) = hex_to_hash(&name_str) {
                    hashes.push(hash);
                }
            }
        }
        Ok(hashes)
    }

    pub fn cache_len(&self) -> usize {
        self.cache.lock().unwrap_or_else(|e| e.into_inner()).len()
    }

    pub fn clear_cache(&self) {
        self.cache.lock().unwrap_or_else(|e| e.into_inner()).clear();
    }

    pub fn base_dir(&self) -> &Path {
        &self.base_dir
    }

    pub fn cache_stats(&self) -> (u64, u64, f64, usize) {
        let hits = self.cache_hits.load(AtomicOrdering::Relaxed);
        let misses = self.cache_misses.load(AtomicOrdering::Relaxed);
        let total = hits + misses;
        let rate = if total > 0 { hits as f64 / total as f64 } else { 0.0 };
        let len = self.cache_len();
        (hits, misses, rate, len)
    }

    pub fn reset_stats(&self) {
        self.cache_hits.store(0, AtomicOrdering::Relaxed);
        self.cache_misses.store(0, AtomicOrdering::Relaxed);
    }

    pub fn cache_capacity(&self) -> usize {
        CACHE_CAPACITY
    }

    pub fn total_chunks_on_disk(&self) -> Result<usize, ChunkError> {
        Ok(self.all_chunk_hashes()?.len())
    }

    pub fn disk_bytes(&self) -> Result<u64, ChunkError> {
        let chunks_dir = self.base_dir.join("chunks");
        if !chunks_dir.exists() {
            return Ok(0);
        }
        let mut total: u64 = 0;
        for entry in std::fs::read_dir(&chunks_dir)
            .map_err(|e| ChunkError::Io(e.to_string()))?
        {
            let entry = entry.map_err(|e| ChunkError::Io(e.to_string()))?;
            if !entry.path().is_dir() {
                continue;
            }
            for file_entry in std::fs::read_dir(entry.path())
                .map_err(|e| ChunkError::Io(e.to_string()))?
            {
                let file_entry = file_entry.map_err(|e| ChunkError::Io(e.to_string()))?;
                let name = file_entry.file_name();
                let name_str = name.to_string_lossy();
                if name_str.ends_with(".tmp") {
                    continue;
                }
                if hex_to_hash(&name_str).is_none() {
                    continue;
                }
                if let Ok(meta) = file_entry.metadata() {
                    total += meta.len();
                }
            }
        }
        Ok(total)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn temp_dir() -> PathBuf {
        static COUNTER: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
        let id = COUNTER.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        std::env::temp_dir().join(format!(
            "xudanu_chunk_test_{}_{}",
            std::process::id(),
            id
        ))
    }

    #[test]
    fn write_and_read_roundtrip() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let data = b"hello world";
        let hash = store.write_chunk(data).unwrap();

        let read = store.read_chunk(&hash).unwrap();
        assert_eq!(read, data);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn same_data_produces_same_hash() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let h1 = store.write_chunk(b"same content").unwrap();
        let h2 = store.write_chunk(b"same content").unwrap();
        assert_eq!(h1, h2);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn different_data_produces_different_hash() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let h1 = store.write_chunk(b"aaa").unwrap();
        let h2 = store.write_chunk(b"bbb").unwrap();
        assert_ne!(h1, h2);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn write_is_idempotent() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let hash = store.write_chunk(b"test").unwrap();
        store.write_chunk(b"test").unwrap();

        let data = store.read_chunk(&hash).unwrap();
        assert_eq!(data, b"test");

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn chunk_exists() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let hash = store.write_chunk(b"exists?").unwrap();
        assert!(store.chunk_exists(&hash));

        let missing = compute_hash(b"nope");
        assert!(!store.chunk_exists(&missing));

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn verify_good_chunk() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let hash = store.write_chunk(b"good data").unwrap();
        assert!(store.verify_chunk(&hash).is_ok());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn verify_corrupt_chunk() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let hash = store.write_chunk(b"original").unwrap();

        let path = chunk_path(&dir, &hash);
        std::fs::write(&path, b"corrupted!").unwrap();

        let result = store.verify_chunk(&hash);
        assert!(result.is_err());
        match result.unwrap_err() {
            ChunkError::HashMismatch { .. } => {}
            other => panic!("expected HashMismatch, got: {}", other),
        }

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn read_missing_chunk() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let missing = compute_hash(b"ghost");
        let result = store.read_chunk(&missing);
        assert!(result.is_err());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn cache_populated_on_write() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        assert_eq!(store.cache_len(), 0);
        store.write_chunk(b"cached").unwrap();
        assert_eq!(store.cache_len(), 1);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn cache_hit_avoids_disk_read() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let hash = store.write_chunk(b"from cache").unwrap();

        let path = chunk_path(&dir, &hash);
        std::fs::remove_file(&path).unwrap();

        let data = store.read_chunk(&hash).unwrap();
        assert_eq!(data, b"from cache");

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn cache_eviction() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        for i in 0..1100u32 {
            let data = format!("chunk-{}", i);
            store.write_chunk(data.as_bytes()).unwrap();
        }

        assert!(store.cache_len() <= CACHE_CAPACITY);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn clear_cache() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        store.write_chunk(b"a").unwrap();
        store.write_chunk(b"b").unwrap();
        assert_eq!(store.cache_len(), 2);

        store.clear_cache();
        assert_eq!(store.cache_len(), 0);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn all_chunk_hashes() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let h1 = store.write_chunk(b"one").unwrap();
        let h2 = store.write_chunk(b"two").unwrap();
        let h3 = store.write_chunk(b"three").unwrap();

        let mut hashes = store.all_chunk_hashes().unwrap();
        hashes.sort();
        let mut expected = vec![h1, h2, h3];
        expected.sort();
        assert_eq!(hashes, expected);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn all_chunk_hashes_empty() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let hashes = store.all_chunk_hashes().unwrap();
        assert!(hashes.is_empty());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn multiple_chunks_independent() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let h1 = store.write_chunk(b"alpha").unwrap();
        let h2 = store.write_chunk(b"beta").unwrap();
        let h3 = store.write_chunk(b"gamma").unwrap();

        assert_eq!(store.read_chunk(&h1).unwrap(), b"alpha");
        assert_eq!(store.read_chunk(&h2).unwrap(), b"beta");
        assert_eq!(store.read_chunk(&h3).unwrap(), b"gamma");

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn large_chunk() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let data: Vec<u8> = (0..100_000).map(|i| (i % 256) as u8).collect();
        let hash = store.write_chunk(&data).unwrap();
        let read = store.read_chunk(&hash).unwrap();
        assert_eq!(read, data);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn creates_chunks_directory_on_open() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);

        assert!(!dir.join("chunks").exists());
        let _store = ChunkStore::open(&dir).unwrap();
        assert!(dir.join("chunks").exists());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn hash_to_hex_roundtrip() {
        let hash = compute_hash(b"test");
        let hex = hash_to_hex(&hash);
        let restored = hex_to_hash(&hex).unwrap();
        assert_eq!(hash, restored);
    }

    #[test]
    fn hex_to_hash_invalid() {
        assert!(hex_to_hash("abc").is_none());
        assert!(hex_to_hash("").is_none());
        assert!(hex_to_hash(&"g".repeat(64)).is_none());
    }

    #[test]
    fn empty_data_roundtrip() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let hash = store.write_chunk(b"").unwrap();
        let data = store.read_chunk(&hash).unwrap();
        assert!(data.is_empty());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn binary_data_roundtrip() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let data: Vec<u8> = (0..=255).collect();
        let hash = store.write_chunk(&data).unwrap();
        let read = store.read_chunk(&hash).unwrap();
        assert_eq!(read, data);

        let with_nulls = b"\x00\x00\x00\x00".as_slice();
        let hash2 = store.write_chunk(with_nulls).unwrap();
        let read2 = store.read_chunk(&hash2).unwrap();
        assert_eq!(read2, with_nulls);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn tmp_file_cleaned_up_after_write() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        store.write_chunk(b"clean tmp").unwrap();

        let chunks_dir = dir.join("chunks");
        for entry in std::fs::read_dir(&chunks_dir).unwrap() {
            let entry = entry.unwrap();
            if entry.path().is_dir() {
                for file_entry in std::fs::read_dir(entry.path()).unwrap() {
                    let file_entry = file_entry.unwrap();
                    let name = file_entry.file_name().to_string_lossy().to_string();
                    assert!(!name.ends_with(".tmp"), "leftover .tmp file: {}", name);
                }
            }
        }

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn rewrite_after_disk_delete() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let data = b"phoenix";
        let hash = store.write_chunk(data).unwrap();

        let path = chunk_path(&dir, &hash);
        std::fs::remove_file(&path).unwrap();

        store.clear_cache();

        let hash2 = store.write_chunk(data).unwrap();
        assert_eq!(hash, hash2);

        let read = store.read_chunk(&hash2).unwrap();
        assert_eq!(read, data);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn cache_eviction_all_readable_from_disk() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let n = CACHE_CAPACITY + 200;
        let mut hashes = Vec::with_capacity(n);
        for i in 0..n {
            let data = format!("evict-test-{}", i);
            hashes.push(store.write_chunk(data.as_bytes()).unwrap());
        }

        store.clear_cache();

        for (i, hash) in hashes.iter().enumerate() {
            let data = store.read_chunk(hash).unwrap();
            assert_eq!(data, format!("evict-test-{}", i).as_bytes());
        }

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn open_nonexistent_nested_directory() {
        let dir = std::env::temp_dir().join(format!(
            "xudanu_chunk_nested_test_{}_{}", std::process::id(), 9999
        ));
        let nested = dir.join("a").join("b").join("c");
        let _ = std::fs::remove_dir_all(&dir);

        let store = ChunkStore::open(&nested).unwrap();
        let hash = store.write_chunk(b"nested").unwrap();
        let data = store.read_chunk(&hash).unwrap();
        assert_eq!(data, b"nested");

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn reopen_reads_existing_chunks() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);

        let hash;
        {
            let store = ChunkStore::open(&dir).unwrap();
            hash = store.write_chunk(b"persistent").unwrap();
        }

        {
            let store = ChunkStore::open(&dir).unwrap();
            let data = store.read_chunk(&hash).unwrap();
            assert_eq!(data, b"persistent");
        }

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn leftover_tmp_file_ignored() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        store.write_chunk(b"real").unwrap();

        let hash = compute_hash(b"ghost");
        let hex = hash_to_hex(&hash);
        let prefix = &hex[..2];
        let ghost_dir = dir.join("chunks").join(prefix);
        std::fs::create_dir_all(&ghost_dir).unwrap();
        std::fs::write(ghost_dir.join(format!("{}.tmp", hex)), b"ghost data").unwrap();

        let hashes = store.all_chunk_hashes().unwrap();
        assert_eq!(hashes.len(), 1);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn concurrent_reads() {
        use std::sync::Arc;
        use std::thread;

        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = Arc::new(ChunkStore::open(&dir).unwrap());

        let mut hashes = Vec::new();
        for i in 0..100u32 {
            let data = format!("concurrent-{}", i);
            hashes.push(store.write_chunk(data.as_bytes()).unwrap());
        }

        let mut handles = Vec::new();
        for t in 0..4 {
            let store = Arc::clone(&store);
            let hashes = hashes.clone();
            handles.push(thread::spawn(move || {
                let mut ok = 0u64;
                for i in 0..500 {
                    let idx = ((t * 500 + i) as usize) % hashes.len();
                    let data = store.read_chunk(&hashes[idx]).unwrap();
                    assert_eq!(data, format!("concurrent-{}", idx).as_bytes());
                    ok += 1;
                }
                ok
            }));
        }

        let total: u64 = handles.into_iter().map(|h| h.join().unwrap()).sum();
        assert_eq!(total, 2000);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn concurrent_writes_same_content() {
        use std::sync::Arc;
        use std::thread;

        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = Arc::new(ChunkStore::open(&dir).unwrap());

        let data = b"shared content for concurrent write";
        let mut handles = Vec::new();
        for _ in 0..4 {
            let store = Arc::clone(&store);
            let data = data.to_vec();
            handles.push(thread::spawn(move || {
                store.write_chunk(&data)
            }));
        }

        let results: Vec<_> = handles.into_iter().map(|h| h.join().unwrap()).collect();
        let expected_hash = compute_hash(data);
        for result in &results {
            let hash = result.as_ref().expect("concurrent write should not fail");
            assert_eq!(*hash, expected_hash);
        }

        let read = store.read_chunk(&expected_hash).unwrap();
        assert_eq!(read, data);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn concurrent_mixed_read_write() {
        use std::sync::Arc;
        use std::thread;

        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = Arc::new(ChunkStore::open(&dir).unwrap());

        let mut seed_hashes = Vec::new();
        for i in 0..50u32 {
            seed_hashes.push(store.write_chunk(format!("seed-{}", i).as_bytes()).unwrap());
        }

        let mut handles = Vec::new();
        for t in 0..4 {
            let store = Arc::clone(&store);
            let seed_hashes = seed_hashes.clone();
            handles.push(thread::spawn(move || {
                let mut writes = 0u64;
                let mut reads = 0u64;
                for i in 0..200 {
                    if i % 3 == 0 {
                        let data = format!("mixed-t{}-{}", t, i);
                        store.write_chunk(data.as_bytes()).unwrap();
                        writes += 1;
                    } else {
                        let idx = (i as usize) % seed_hashes.len();
                        let data = store.read_chunk(&seed_hashes[idx]).unwrap();
                        assert_eq!(data, format!("seed-{}", idx).as_bytes());
                        reads += 1;
                    }
                }
                (writes, reads)
            }));
        }

        let (total_writes, total_reads): (u64, u64) =
            handles.into_iter().map(|h| h.join().unwrap()).fold((0, 0), |(w, r), (dw, dr)| (w + dw, r + dr));
        assert!(total_writes > 0);
        assert!(total_reads > 0);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn cache_get_updates_lru_order() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let h_a = store.write_chunk(b"aaa").unwrap();
        let h_b = store.write_chunk(b"bbb").unwrap();

        let _ = store.read_chunk(&h_a);
        store.reset_stats();

        for i in 0..(CACHE_CAPACITY - 1) {
            store.write_chunk(format!("filler-{}", i).as_bytes()).unwrap();
        }

        let read_a = store.read_chunk(&h_a);
        let (hits_after_a, _, _, _) = store.cache_stats();
        assert!(read_a.is_ok());
        assert!(hits_after_a >= 1, "a should be a cache hit (recently accessed)");

        store.reset_stats();
        let read_b = store.read_chunk(&h_b);
        let (hits_after_b, misses_after_b, _, _) = store.cache_stats();
        assert!(read_b.is_ok());
        assert!(misses_after_b >= 1, "b should be a cache miss (evicted, served from disk)");

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn garbage_files_in_chunks_dir_ignored() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        store.write_chunk(b"legit").unwrap();

        let chunks_dir = dir.join("chunks");
        let sub_dir = chunks_dir.join("zz");
        std::fs::create_dir_all(&sub_dir).unwrap();
        std::fs::write(sub_dir.join("not_a_hash.txt"), b"garbage").unwrap();
        std::fs::write(sub_dir.join("also_not"), b"more garbage").unwrap();

        let hashes = store.all_chunk_hashes().unwrap();
        assert_eq!(hashes.len(), 1);

        let bytes = store.disk_bytes().unwrap();
        assert!(bytes > 0);

        let _ = std::fs::remove_dir_all(&dir);
    }
}
