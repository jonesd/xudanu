use std::collections::HashMap;
use std::path::{Path, PathBuf};
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
}

impl ChunkStore {
    pub fn open(base_dir: &Path) -> Result<Self, ChunkError> {
        let chunks_dir = base_dir.join("chunks");
        std::fs::create_dir_all(&chunks_dir)
            .map_err(|e| ChunkError::Io(e.to_string()))?;
        Ok(ChunkStore {
            base_dir: base_dir.to_path_buf(),
            cache: Mutex::new(Cache::new(CACHE_CAPACITY)),
        })
    }

    pub fn write_chunk(&self, data: &[u8]) -> Result<[u8; 32], ChunkError> {
        let hash = compute_hash(data);
        let path = chunk_path(&self.base_dir, &hash);
        if path.exists() {
            self.cache.lock().unwrap().insert(hash, data.to_vec());
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
        self.cache.lock().unwrap().insert(hash, data.to_vec());
        Ok(hash)
    }

    pub fn read_chunk(&self, hash: &[u8; 32]) -> Result<Vec<u8>, ChunkError> {
        {
            let mut cache = self.cache.lock().unwrap();
            if let Some(data) = cache.get(hash).cloned() {
                return Ok(data);
            }
        }
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
        self.cache.lock().unwrap().insert(*hash, data.clone());
        Ok(data)
    }

    pub fn chunk_exists(&self, hash: &[u8; 32]) -> bool {
        chunk_path(&self.base_dir, hash).exists()
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
        self.cache.lock().unwrap().len()
    }

    pub fn clear_cache(&self) {
        self.cache.lock().unwrap().clear();
    }

    pub fn base_dir(&self) -> &Path {
        &self.base_dir
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
}
