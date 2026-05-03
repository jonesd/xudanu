use std::collections::HashMap;
use std::io::{Read, Write};
use std::path::{Path, PathBuf};

#[derive(Debug, Clone)]
pub struct BlobMeta {
    pub content_hash: [u8; 32],
    pub byte_size: u64,
    pub mime_type: String,
    pub preview_hash: Option<[u8; 32]>,
    pub metadata: HashMap<String, String>,
}

impl BlobMeta {
    pub fn new(content_hash: [u8; 32], byte_size: u64, mime_type: String) -> Self {
        BlobMeta {
            content_hash,
            byte_size,
            mime_type,
            preview_hash: None,
            metadata: HashMap::new(),
        }
    }

    pub fn with_preview(mut self, preview_hash: [u8; 32]) -> Self {
        self.preview_hash = Some(preview_hash);
        self
    }

    pub fn with_metadata(mut self, key: impl Into<String>, value: impl Into<String>) -> Self {
        self.metadata.insert(key.into(), value.into());
        self
    }

    pub fn hash_u64(&self) -> u64 {
        let mut bytes = [0u8; 8];
        bytes.copy_from_slice(&self.content_hash[..8]);
        u64::from_be_bytes(bytes)
    }

    pub fn is_image(&self) -> bool {
        self.mime_type.starts_with("image/")
    }
}

#[derive(Debug, Clone)]
pub enum BlobError {
    NotFound([u8; 32]),
    IoError(String),
    CorruptData { expected: [u8; 32], actual: [u8; 32] },
    BackendError(String),
}

impl std::fmt::Display for BlobError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            BlobError::NotFound(hash) => write!(f, "blob not found: {:016x}", u64_from_hash(hash)),
            BlobError::IoError(e) => write!(f, "io error: {}", e),
            BlobError::CorruptData { expected, actual } => {
                write!(f, "corrupt blob: expected {:016x}, got {:016x}", u64_from_hash(expected), u64_from_hash(actual))
            }
            BlobError::BackendError(e) => write!(f, "backend error: {}", e),
        }
    }
}

impl std::error::Error for BlobError {}

pub fn hash_content(data: &[u8]) -> [u8; 32] {
    blake3::hash(data).into()
}

pub fn u64_from_hash(hash: &[u8; 32]) -> u64 {
    let mut bytes = [0u8; 8];
    bytes.copy_from_slice(&hash[..8]);
    u64::from_be_bytes(bytes)
}

pub trait BlobBackend: Send + Sync + std::fmt::Debug + 'static {
    fn store(&self, hash: &[u8; 32], data: &[u8]) -> Result<(), BlobError>;
    fn retrieve(&self, hash: &[u8; 32]) -> Result<Vec<u8>, BlobError>;
    fn exists(&self, hash: &[u8; 32]) -> Result<bool, BlobError>;
    fn delete(&self, hash: &[u8; 32]) -> Result<(), BlobError>;
    fn retrieve_range(&self, hash: &[u8; 32], offset: u64, len: u64) -> Result<Vec<u8>, BlobError>;
    fn stats(&self) -> BlobBackendStats;
}

#[derive(Debug, Clone, Default)]
pub struct BlobBackendStats {
    pub total_blobs: u64,
    pub total_bytes: u64,
}

#[derive(Debug)]
pub struct MemoryBackend {
    blobs: std::sync::Mutex<HashMap<[u8; 32], Vec<u8>>>,
}

impl MemoryBackend {
    pub fn new() -> Self {
        MemoryBackend {
            blobs: std::sync::Mutex::new(HashMap::new()),
        }
    }
}

impl Default for MemoryBackend {
    fn default() -> Self {
        Self::new()
    }
}

impl BlobBackend for MemoryBackend {
    fn store(&self, hash: &[u8; 32], data: &[u8]) -> Result<(), BlobError> {
        let mut blobs = self.blobs.lock().unwrap();
        blobs.insert(*hash, data.to_vec());
        Ok(())
    }

    fn retrieve(&self, hash: &[u8; 32]) -> Result<Vec<u8>, BlobError> {
        let blobs = self.blobs.lock().unwrap();
        blobs.get(hash).cloned().ok_or_else(|| BlobError::NotFound(*hash))
    }

    fn exists(&self, hash: &[u8; 32]) -> Result<bool, BlobError> {
        let blobs = self.blobs.lock().unwrap();
        Ok(blobs.contains_key(hash))
    }

    fn delete(&self, hash: &[u8; 32]) -> Result<(), BlobError> {
        let mut blobs = self.blobs.lock().unwrap();
        blobs.remove(hash);
        Ok(())
    }

    fn retrieve_range(&self, hash: &[u8; 32], offset: u64, len: u64) -> Result<Vec<u8>, BlobError> {
        let blobs = self.blobs.lock().unwrap();
        let data = blobs.get(hash).ok_or_else(|| BlobError::NotFound(*hash))?;
        let start = offset as usize;
        let end = (offset + len) as usize;
        if start > data.len() {
            return Ok(Vec::new());
        }
        Ok(data[start..end.min(data.len())].to_vec())
    }

    fn stats(&self) -> BlobBackendStats {
        let blobs = self.blobs.lock().unwrap();
        BlobBackendStats {
            total_blobs: blobs.len() as u64,
            total_bytes: blobs.values().map(|v| v.len() as u64).sum(),
        }
    }
}

#[derive(Debug)]
pub struct FilesystemBackend {
    base_dir: PathBuf,
}

impl FilesystemBackend {
    pub fn new(base_dir: impl AsRef<Path>) -> Result<Self, BlobError> {
        let base_dir = base_dir.as_ref().to_path_buf();
        std::fs::create_dir_all(&base_dir)
            .map_err(|e| BlobError::IoError(e.to_string()))?;
        Ok(FilesystemBackend { base_dir })
    }

    fn blob_path(&self, hash: &[u8; 32]) -> PathBuf {
        let hex = hex_encode(hash);
        let prefix = &hex[..2];
        self.base_dir.join(prefix).join(hex)
    }

    fn meta_path(&self, hash: &[u8; 32]) -> PathBuf {
        let hex = hex_encode(hash);
        let prefix = &hex[..2];
        self.base_dir.join(prefix).join(format!("{}.meta", hex))
    }

    fn ensure_dir(&self, hash: &[u8; 32]) -> Result<PathBuf, BlobError> {
        let hex = hex_encode(hash);
        let prefix = &hex[..2];
        let dir = self.base_dir.join(prefix);
        std::fs::create_dir_all(&dir)
            .map_err(|e| BlobError::IoError(e.to_string()))?;
        Ok(dir)
    }
}

impl BlobBackend for FilesystemBackend {
    fn store(&self, hash: &[u8; 32], data: &[u8]) -> Result<(), BlobError> {
        let path = self.blob_path(hash);
        if path.exists() {
            return Ok(());
        }
        self.ensure_dir(hash)?;
        let mut file = std::fs::File::create(&path)
            .map_err(|e| BlobError::IoError(e.to_string()))?;
        file.write_all(data)
            .map_err(|e| BlobError::IoError(e.to_string()))?;
        Ok(())
    }

    fn retrieve(&self, hash: &[u8; 32]) -> Result<Vec<u8>, BlobError> {
        let path = self.blob_path(hash);
        if !path.exists() {
            return Err(BlobError::NotFound(*hash));
        }
        std::fs::read(&path).map_err(|e| BlobError::IoError(e.to_string()))
    }

    fn exists(&self, hash: &[u8; 32]) -> Result<bool, BlobError> {
        Ok(self.blob_path(hash).exists())
    }

    fn delete(&self, hash: &[u8; 32]) -> Result<(), BlobError> {
        let path = self.blob_path(hash);
        if path.exists() {
            std::fs::remove_file(&path)
                .map_err(|e| BlobError::IoError(e.to_string()))?;
        }
        Ok(())
    }

    fn retrieve_range(&self, hash: &[u8; 32], offset: u64, len: u64) -> Result<Vec<u8>, BlobError> {
        let path = self.blob_path(hash);
        if !path.exists() {
            return Err(BlobError::NotFound(*hash));
        }
        let mut file = std::fs::File::open(&path)
            .map_err(|e| BlobError::IoError(e.to_string()))?;
        use std::io::Seek;
        file.seek(std::io::SeekFrom::Start(offset))
            .map_err(|e| BlobError::IoError(e.to_string()))?;
        let read_len = (len as usize).min(64 * 1024 * 1024);
        let mut buf = vec![0u8; read_len];
        let n = file.read(&mut buf)
            .map_err(|e| BlobError::IoError(e.to_string()))?;
        buf.truncate(n);
        Ok(buf)
    }

    fn stats(&self) -> BlobBackendStats {
        let mut total_blobs = 0u64;
        let mut total_bytes = 0u64;
        if let Ok(entries) = std::fs::read_dir(&self.base_dir) {
            for entry in entries.flatten() {
                if entry.path().is_dir() {
                    if let Ok(sub) = std::fs::read_dir(entry.path()) {
                        for file in sub.flatten() {
                            let p = file.path();
                            if p.extension().map_or(false, |e| e == "meta") {
                                continue;
                            }
                            if let Ok(meta) = file.metadata() {
                                total_blobs += 1;
                                total_bytes += meta.len();
                            }
                        }
                    }
                }
            }
        }
        BlobBackendStats { total_blobs, total_bytes }
    }
}

fn hex_encode(hash: &[u8; 32]) -> String {
    hash.iter().map(|b| format!("{:02x}", b)).collect()
}

#[derive(Debug)]
pub struct BlobStore {
    backend: Box<dyn BlobBackend>,
    meta: std::sync::Mutex<HashMap<[u8; 32], BlobMeta>>,
    by_u64: std::sync::Mutex<HashMap<u64, [u8; 32]>>,
}

impl BlobStore {
    pub fn new(backend: Box<dyn BlobBackend>) -> Self {
        BlobStore {
            backend,
            meta: std::sync::Mutex::new(HashMap::new()),
            by_u64: std::sync::Mutex::new(HashMap::new()),
        }
    }

    pub fn in_memory() -> Self {
        BlobStore::new(Box::new(MemoryBackend::new()))
    }

    pub fn filesystem(base_dir: impl AsRef<Path>) -> Result<Self, BlobError> {
        Ok(BlobStore::new(Box::new(FilesystemBackend::new(base_dir)?)))
    }

    pub fn store(&self, data: &[u8], mime_type: String) -> Result<BlobMeta, BlobError> {
        let hash = hash_content(data);
        let byte_size = data.len() as u64;
        self.backend.store(&hash, data)?;
        if let Some(existing) = self.meta.lock().unwrap().get(&hash).cloned() {
            return Ok(existing);
        }
        let mut meta = BlobMeta::new(hash, byte_size, mime_type);
        if meta.is_image() {
            if let Some(preview_data) = generate_preview(data, &meta.mime_type) {
                let preview_hash = hash_content(&preview_data);
                let _ = self.backend.store(&preview_hash, &preview_data);
                meta = meta.with_preview(preview_hash);
            }
        }
        self.meta.lock().unwrap().insert(hash, meta.clone());
        self.by_u64.lock().unwrap().insert(meta.hash_u64(), hash);
        Ok(meta)
    }

    pub fn store_overlay(&self, base_hash: u64, ops: Vec<ImageOp>, mime_type: String) -> Result<BlobMeta, BlobError> {
        let overlay = ImageOverlay::new(base_hash, ops, mime_type);
        let json = serde_json::to_vec(&overlay)
            .map_err(|e| BlobError::IoError(e.to_string()))?;
        self.store(&json, "application/x-xudanu-overlay".to_string())
    }

    pub fn retrieve_overlay(&self, hash: &[u8; 32]) -> Result<ImageOverlay, BlobError> {
        let data = self.backend.retrieve(hash)?;
        serde_json::from_slice(&data)
            .map_err(|e| BlobError::IoError(format!("invalid overlay: {}", e)))
    }

    pub fn retrieve_overlay_by_u64(&self, hash_u64: u64) -> Result<ImageOverlay, BlobError> {
        let full_hash = self.by_u64.lock().unwrap()
            .get(&hash_u64).copied()
            .ok_or(BlobError::NotFound([0u8; 32]))?;
        self.retrieve_overlay(&full_hash)
    }

    pub fn retrieve(&self, hash: &[u8; 32]) -> Result<Vec<u8>, BlobError> {
        self.backend.retrieve(hash)
    }

    pub fn retrieve_preview(&self, meta: &BlobMeta) -> Result<Option<Vec<u8>>, BlobError> {
        if let Some(preview_hash) = meta.preview_hash {
            Ok(Some(self.backend.retrieve(&preview_hash)?))
        } else {
            Ok(None)
        }
    }

    pub fn exists(&self, hash: &[u8; 32]) -> Result<bool, BlobError> {
        self.backend.exists(hash)
    }

    pub fn delete(&self, hash: &[u8; 32]) -> Result<(), BlobError> {
        self.backend.delete(hash)?;
        if let Some(meta) = self.meta.lock().unwrap().remove(hash) {
            self.by_u64.lock().unwrap().remove(&meta.hash_u64());
        }
        Ok(())
    }

    pub fn retrieve_range(&self, hash: &[u8; 32], offset: u64, len: u64) -> Result<Vec<u8>, BlobError> {
        self.backend.retrieve_range(hash, offset, len)
    }

    pub fn get_meta(&self, hash: &[u8; 32]) -> Option<BlobMeta> {
        self.meta.lock().unwrap().get(hash).cloned()
    }

    pub fn get_meta_by_u64(&self, hash_u64: u64) -> Option<BlobMeta> {
        let full_hash = self.by_u64.lock().unwrap().get(&hash_u64).copied()?;
        self.meta.lock().unwrap().get(&full_hash).cloned()
    }

    pub fn register_meta(&self, meta: BlobMeta) {
        let hash_u64 = meta.hash_u64();
        let full_hash = meta.content_hash;
        self.meta.lock().unwrap().insert(full_hash, meta);
        self.by_u64.lock().unwrap().insert(hash_u64, full_hash);
    }

    pub fn stats(&self) -> BlobBackendStats {
        self.backend.stats()
    }

    pub fn all_hashes(&self) -> Vec<[u8; 32]> {
        self.meta.lock().unwrap().keys().copied().collect()
    }
}

pub fn hash_to_hex(hash: &[u8; 32]) -> String {
    hash.iter().map(|b| format!("{:02x}", b)).collect()
}

pub fn hex_to_hash(hex: &str) -> Option<[u8; 32]> {
    if hex.len() != 64 {
        return None;
    }
    let mut result = [0u8; 32];
    for i in 0..32 {
        result[i] = u8::from_str_radix(&hex[i * 2..i * 2 + 2], 16).ok()?;
    }
    Some(result)
}

pub fn base64_encode(data: &[u8]) -> String {
    const TABLE: &[u8; 64] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    let mut out = String::with_capacity((data.len() + 2) / 3 * 4);
    let mut i = 0;
    while i + 2 < data.len() {
        let n = ((data[i] as u32) << 16) | ((data[i + 1] as u32) << 8) | (data[i + 2] as u32);
        out.push(TABLE[((n >> 18) & 0x3F) as usize] as char);
        out.push(TABLE[((n >> 12) & 0x3F) as usize] as char);
        out.push(TABLE[((n >> 6) & 0x3F) as usize] as char);
        out.push(TABLE[(n & 0x3F) as usize] as char);
        i += 3;
    }
    let remaining = data.len() - i;
    if remaining == 1 {
        let n = (data[i] as u32) << 16;
        out.push(TABLE[((n >> 18) & 0x3F) as usize] as char);
        out.push(TABLE[((n >> 12) & 0x3F) as usize] as char);
        out.push('=');
        out.push('=');
    } else if remaining == 2 {
        let n = ((data[i] as u32) << 16) | ((data[i + 1] as u32) << 8);
        out.push(TABLE[((n >> 18) & 0x3F) as usize] as char);
        out.push(TABLE[((n >> 12) & 0x3F) as usize] as char);
        out.push(TABLE[((n >> 6) & 0x3F) as usize] as char);
        out.push('=');
    }
    out
}

pub fn base64_decode(input: &str) -> Option<Vec<u8>> {
    fn val(c: u8) -> Option<u8> {
        match c {
            b'A'..=b'Z' => Some(c - b'A'),
            b'a'..=b'z' => Some(c - b'a' + 26),
            b'0'..=b'9' => Some(c - b'0' + 52),
            b'+' => Some(62),
            b'/' => Some(63),
            _ => None,
        }
    }
    let input = input.trim_end_matches('=').as_bytes();
    let mut out = Vec::with_capacity(input.len() * 3 / 4);
    let mut i = 0;
    while i + 3 < input.len() {
        let a = val(input[i])? as u32;
        let b = val(input[i + 1])? as u32;
        let c = val(input[i + 2])? as u32;
        let d = val(input[i + 3])? as u32;
        let n = (a << 18) | (b << 12) | (c << 6) | d;
        out.push(((n >> 16) & 0xFF) as u8);
        out.push(((n >> 8) & 0xFF) as u8);
        out.push((n & 0xFF) as u8);
        i += 4;
    }
    let remaining = input.len() - i;
    if remaining >= 2 {
        let a = val(input[i])? as u32;
        let b = val(input[i + 1])? as u32;
        out.push((((a << 18) | (b << 12)) >> 16) as u8);
        if remaining >= 3 {
            let c = val(input[i + 2])? as u32;
            out.push((((a << 18) | (b << 12) | (c << 6)) >> 8) as u8);
        }
    }
    Some(out)
}

fn generate_preview(data: &[u8], mime_type: &str) -> Option<Vec<u8>> {
    match mime_type {
        "image/png" | "image/jpeg" | "image/gif" | "image/webp" => {
            generate_image_preview(data)
        }
        _ => None,
    }
}

fn generate_image_preview(data: &[u8]) -> Option<Vec<u8>> {
    let _ = data;
    None
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub enum ImageOp {
    Brightness(i32),
    Contrast(i32),
    Crop { x: u32, y: u32, width: u32, height: u32 },
    Rotate(u16),
    FlipHorizontal,
    FlipVertical,
    Grayscale,
    Opacity(u16),
    Resize { width: u32, height: u32 },
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ImageOverlay {
    pub base_hash: u64,
    pub operations: Vec<ImageOp>,
    pub mime_type: String,
}

impl ImageOverlay {
    pub fn new(base_hash: u64, operations: Vec<ImageOp>, mime_type: String) -> Self {
        ImageOverlay { base_hash, operations, mime_type }
    }

    pub fn single(base_hash: u64, op: ImageOp, mime_type: String) -> Self {
        ImageOverlay { base_hash, operations: vec![op], mime_type }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::hash_map::DefaultHasher;
    use std::hash::{Hash, Hasher};

    #[test]
    fn hash_content_deterministic() {
        let data = b"hello world";
        let h1 = hash_content(data);
        let h2 = hash_content(data);
        assert_eq!(h1, h2);
    }

    #[test]
    fn hash_content_different_for_different_data() {
        let h1 = hash_content(b"hello");
        let h2 = hash_content(b"world");
        assert_ne!(h1, h2);
    }

    #[test]
    fn memory_backend_store_retrieve() {
        let backend = MemoryBackend::new();
        let hash = hash_content(b"test data");
        backend.store(&hash, b"test data").unwrap();
        let data = backend.retrieve(&hash).unwrap();
        assert_eq!(data, b"test data");
    }

    #[test]
    fn memory_backend_exists() {
        let backend = MemoryBackend::new();
        let hash = hash_content(b"test");
        assert!(!backend.exists(&hash).unwrap());
        backend.store(&hash, b"test").unwrap();
        assert!(backend.exists(&hash).unwrap());
    }

    #[test]
    fn memory_backend_not_found() {
        let backend = MemoryBackend::new();
        let hash = hash_content(b"missing");
        match backend.retrieve(&hash) {
            Err(BlobError::NotFound(_)) => {}
            other => panic!("expected NotFound, got {:?}", other),
        }
    }

    #[test]
    fn memory_backend_delete() {
        let backend = MemoryBackend::new();
        let hash = hash_content(b"test");
        backend.store(&hash, b"test").unwrap();
        assert!(backend.exists(&hash).unwrap());
        backend.delete(&hash).unwrap();
        assert!(!backend.exists(&hash).unwrap());
    }

    #[test]
    fn memory_backend_store_idempotent() {
        let backend = MemoryBackend::new();
        let hash = hash_content(b"test");
        backend.store(&hash, b"test").unwrap();
        backend.store(&hash, b"test").unwrap();
        assert!(backend.exists(&hash).unwrap());
    }

    #[test]
    fn memory_backend_retrieve_range() {
        let backend = MemoryBackend::new();
        let hash = hash_content(b"hello world");
        backend.store(&hash, b"hello world").unwrap();
        let range = backend.retrieve_range(&hash, 6, 5).unwrap();
        assert_eq!(range, b"world");
    }

    #[test]
    fn memory_backend_retrieve_range_past_end() {
        let backend = MemoryBackend::new();
        let hash = hash_content(b"hello");
        backend.store(&hash, b"hello").unwrap();
        let range = backend.retrieve_range(&hash, 3, 100).unwrap();
        assert_eq!(range, b"lo");
    }

    #[test]
    fn memory_backend_stats() {
        let backend = MemoryBackend::new();
        let h1 = hash_content(b"aaa");
        let h2 = hash_content(b"bbbb");
        backend.store(&h1, b"aaa").unwrap();
        backend.store(&h2, b"bbbb").unwrap();
        let stats = backend.stats();
        assert_eq!(stats.total_blobs, 2);
        assert_eq!(stats.total_bytes, 7);
    }

    #[test]
    fn blob_meta_hash_u64() {
        let hash = hash_content(b"test");
        let meta = BlobMeta::new(hash, 4, "text/plain".to_string());
        let h = meta.hash_u64();
        assert_ne!(h, 0);
    }

    #[test]
    fn blob_meta_is_image() {
        let hash = hash_content(b"test");
        let img = BlobMeta::new(hash, 100, "image/png".to_string());
        let txt = BlobMeta::new(hash, 100, "text/plain".to_string());
        assert!(img.is_image());
        assert!(!txt.is_image());
    }

    #[test]
    fn blob_meta_with_preview() {
        let hash = hash_content(b"test");
        let preview_hash = hash_content(b"preview");
        let meta = BlobMeta::new(hash, 100, "image/png".to_string()).with_preview(preview_hash);
        assert_eq!(meta.preview_hash, Some(preview_hash));
    }

    #[test]
    fn blob_meta_with_metadata() {
        let hash = hash_content(b"test");
        let meta = BlobMeta::new(hash, 100, "image/png".to_string())
            .with_metadata("width", "800")
            .with_metadata("height", "600");
        assert_eq!(meta.metadata.get("width"), Some(&"800".to_string()));
        assert_eq!(meta.metadata.get("height"), Some(&"600".to_string()));
    }

    #[test]
    fn blob_store_in_memory_store_and_retrieve() {
        let store = BlobStore::in_memory();
        let meta = store.store(b"image data", "image/png".to_string()).unwrap();
        assert_eq!(meta.byte_size, 10);
        assert_eq!(meta.mime_type, "image/png");
        let data = store.retrieve(&meta.content_hash).unwrap();
        assert_eq!(data, b"image data");
    }

    #[test]
    fn blob_store_deduplication() {
        let store = BlobStore::in_memory();
        let m1 = store.store(b"same data", "image/png".to_string()).unwrap();
        let m2 = store.store(b"same data", "image/png".to_string()).unwrap();
        assert_eq!(m1.content_hash, m2.content_hash);
    }

    #[test]
    fn blob_store_get_meta() {
        let store = BlobStore::in_memory();
        let meta = store.store(b"data", "text/plain".to_string()).unwrap();
        let retrieved = store.get_meta(&meta.content_hash).unwrap();
        assert_eq!(retrieved.content_hash, meta.content_hash);
    }

    #[test]
    fn blob_store_stats() {
        let store = BlobStore::in_memory();
        store.store(b"aaa", "text/plain".to_string()).unwrap();
        store.store(b"bbbb", "text/plain".to_string()).unwrap();
        let stats = store.stats();
        assert_eq!(stats.total_blobs, 2);
    }

    #[test]
    fn image_op_equality() {
        let op1 = ImageOp::Brightness(20);
        let op2 = ImageOp::Brightness(20);
        let op3 = ImageOp::Brightness(30);
        assert_eq!(op1, op2);
        assert_ne!(op1, op3);
    }

    #[test]
    fn image_op_hash_deterministic() {
        let op = ImageOp::Crop { x: 10, y: 20, width: 100, height: 200 };
        let mut h1 = DefaultHasher::new();
        let mut h2 = DefaultHasher::new();
        op.hash(&mut h1);
        op.hash(&mut h2);
        assert_eq!(h1.finish(), h2.finish());
    }

    #[test]
    fn image_overlay_new() {
        let overlay = ImageOverlay::new(
            12345,
            vec![ImageOp::Brightness(20), ImageOp::Grayscale],
            "image/png".to_string(),
        );
        assert_eq!(overlay.base_hash, 12345);
        assert_eq!(overlay.operations.len(), 2);
    }

    #[test]
    fn image_overlay_equality() {
        let o1 = ImageOverlay::single(100, ImageOp::Grayscale, "image/png".to_string());
        let o2 = ImageOverlay::single(100, ImageOp::Grayscale, "image/png".to_string());
        assert_eq!(o1, o2);
    }

    #[test]
    #[cfg(feature = "serde")]
    fn image_op_serde_roundtrip() {
        let op = ImageOp::Crop { x: 10, y: 20, width: 100, height: 200 };
        let json = serde_json::to_string(&op).unwrap();
        let op2: ImageOp = serde_json::from_str(&json).unwrap();
        assert_eq!(op, op2);
    }

    #[test]
    #[cfg(feature = "serde")]
    fn image_overlay_serde_roundtrip() {
        let overlay = ImageOverlay::new(42, vec![ImageOp::Rotate(90)], "image/jpeg".to_string());
        let json = serde_json::to_string(&overlay).unwrap();
        let o2: ImageOverlay = serde_json::from_str(&json).unwrap();
        assert_eq!(overlay, o2);
    }

    #[test]
    fn filesystem_backend_store_retrieve() {
        let dir = tempfile();
        let backend = FilesystemBackend::new(&dir).unwrap();
        let hash = hash_content(b"file test");
        backend.store(&hash, b"file test").unwrap();
        let data = backend.retrieve(&hash).unwrap();
        assert_eq!(data, b"file test");
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn filesystem_backend_exists() {
        let dir = tempfile();
        let backend = FilesystemBackend::new(&dir).unwrap();
        let hash = hash_content(b"test");
        assert!(!backend.exists(&hash).unwrap());
        backend.store(&hash, b"test").unwrap();
        assert!(backend.exists(&hash).unwrap());
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn filesystem_backend_store_idempotent() {
        let dir = tempfile();
        let backend = FilesystemBackend::new(&dir).unwrap();
        let hash = hash_content(b"test");
        backend.store(&hash, b"test").unwrap();
        backend.store(&hash, b"test").unwrap();
        let data = backend.retrieve(&hash).unwrap();
        assert_eq!(data, b"test");
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn filesystem_backend_delete() {
        let dir = tempfile();
        let backend = FilesystemBackend::new(&dir).unwrap();
        let hash = hash_content(b"delete me");
        backend.store(&hash, b"delete me").unwrap();
        assert!(backend.exists(&hash).unwrap());
        backend.delete(&hash).unwrap();
        assert!(!backend.exists(&hash).unwrap());
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn filesystem_backend_retrieve_range() {
        let dir = tempfile();
        let backend = FilesystemBackend::new(&dir).unwrap();
        let hash = hash_content(b"hello world range test");
        backend.store(&hash, b"hello world range test").unwrap();
        let range = backend.retrieve_range(&hash, 6, 5).unwrap();
        assert_eq!(range, b"world");
        let _ = std::fs::remove_dir_all(&dir);
    }

    fn tempfile() -> PathBuf {
        std::env::temp_dir().join(format!(
            "xudanu_test_{}_{:?}",
            std::process::id(),
            std::thread::current().id()
        ))
    }

    #[test]
    fn store_overlay_creates_blob() {
        let store = BlobStore::in_memory();
        let base = store.store(b"fake image data", "image/png".to_string()).unwrap();
        let base_hash = base.hash_u64();
        let ops = vec![ImageOp::Brightness(800), ImageOp::Grayscale];
        let meta = store.store_overlay(base_hash, ops.clone(), "image/png".to_string()).unwrap();
        assert_eq!(meta.mime_type, "application/x-xudanu-overlay");
        assert!(meta.byte_size > 0);
    }

    #[test]
    fn retrieve_overlay_roundtrip() {
        let store = BlobStore::in_memory();
        let base = store.store(b"base data", "image/jpeg".to_string()).unwrap();
        let base_hash = base.hash_u64();
        let ops = vec![ImageOp::Contrast(1200), ImageOp::Rotate(90), ImageOp::FlipHorizontal];
        let meta = store.store_overlay(base_hash, ops.clone(), "image/jpeg".to_string()).unwrap();
        let overlay = store.retrieve_overlay_by_u64(meta.hash_u64()).unwrap();
        assert_eq!(overlay.base_hash, base_hash);
        assert_eq!(overlay.operations, ops);
        assert_eq!(overlay.mime_type, "image/jpeg");
    }

    #[test]
    fn overlay_deduplication() {
        let store = BlobStore::in_memory();
        let base = store.store(b"base", "image/png".to_string()).unwrap();
        let base_hash = base.hash_u64();
        let ops = vec![ImageOp::Grayscale];
        let m1 = store.store_overlay(base_hash, ops.clone(), "image/png".to_string()).unwrap();
        let m2 = store.store_overlay(base_hash, ops.clone(), "image/png".to_string()).unwrap();
        assert_eq!(m1.hash_u64(), m2.hash_u64());
    }

    #[test]
    fn overlay_different_ops_different_hash() {
        let store = BlobStore::in_memory();
        let base = store.store(b"base", "image/png".to_string()).unwrap();
        let base_hash = base.hash_u64();
        let m1 = store.store_overlay(base_hash, vec![ImageOp::Grayscale], "image/png".to_string()).unwrap();
        let m2 = store.store_overlay(base_hash, vec![ImageOp::FlipVertical], "image/png".to_string()).unwrap();
        assert_ne!(m1.hash_u64(), m2.hash_u64());
    }
}
