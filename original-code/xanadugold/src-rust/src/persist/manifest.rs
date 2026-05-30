use std::collections::BTreeMap;
use std::path::Path;

use crate::edition::backend::BeId;
use crate::persist::chunk_store::ChunkStore;
use crate::persist::edition_chunks::{EditionChunkRef, WorkChunkRef};

const CURRENT_MANIFEST_VERSION: u32 = 3;

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ClubChunkRef {
    pub be_id: BeId,
    pub name: Option<String>,
    pub signature_club: Option<BeId>,
    pub work_root: WorkChunkRef,
    #[serde(default)]
    pub default_read_club: Option<BeId>,
    #[serde(default)]
    pub default_edit_club: Option<BeId>,
    #[serde(default)]
    pub is_personal: bool,
    #[serde(default)]
    pub display_name: Option<String>,
    #[serde(default)]
    pub credential: Option<crate::server::club::Credential>,
    #[serde(default)]
    pub encrypted_signing_key: Option<crate::crypto::club_keys::EncryptedSigningKey>,
    #[serde(default)]
    pub members: Vec<BeId>,
    #[serde(default)]
    pub sponsored_works: Vec<BeId>,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct StandaloneEditionChunkRef {
    pub be_id: BeId,
    pub edition_ref: EditionChunkRef,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct LinkEntry {
    pub link_id: BeId,
    pub origin: BeId,
    pub destination: BeId,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub origin_ref: Option<crate::server::transport::protocol::HyperRefPayload>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub destination_ref: Option<crate::server::transport::protocol::HyperRefPayload>,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct AdminEntry {
    pub accepting_connections: bool,
    pub shutdown_requested: bool,
    pub grants: Vec<(BeId, i64, i64)>,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct BlobMetaEntry {
    pub content_hash: Vec<u8>,
    pub hash_u64: u64,
    pub byte_size: u64,
    pub mime_type: String,
    pub preview_hash: Option<Vec<u8>>,
    pub metadata: std::collections::HashMap<String, String>,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct KeyHistoryEntry {
    pub server_id: String,
    pub entries: Vec<crate::crypto::keys::KeyHistoryEntryFile>,
    pub rotation_proofs: Vec<crate::crypto::keys::SignedKeyRotationFile>,
    pub current_key_id: crate::crypto::keys::KeyId,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct Manifest {
    pub format_version: u32,
    pub created_at: String,
    pub server_version: String,
    pub checksum: String,

    pub grand_map_id_counter: BeId,
    pub session_counter: u64,
    pub operation_counter: u64,
    pub system_clubs: crate::server::SystemClubs,

    pub works: Vec<(BeId, WorkChunkRef)>,
    pub clubs: Vec<ClubChunkRef>,
    pub standalone_editions: Vec<StandaloneEditionChunkRef>,
    pub links: Vec<LinkEntry>,
    pub link_counter: BeId,

    pub admin: AdminEntry,

    pub reconcile_store: crate::server::federation::ReconcileStore,
    pub reconcile_counter: u64,
    pub federation: Option<crate::server::federation::FederationSnapshot>,

    pub content_address: Option<crate::edition::ContentAddressIndex>,
    pub blob_metas: Vec<BlobMetaEntry>,
    pub key_history: Option<KeyHistoryEntry>,
}

#[derive(Debug)]
pub enum ManifestError {
    Io(std::io::Error),
    Json(serde_json::Error),
    ChecksumMismatch { expected: String, actual: String },
    InvalidVersion { found: u32, expected: u32 },
}

impl std::fmt::Display for ManifestError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ManifestError::Io(e) => write!(f, "io error: {}", e),
            ManifestError::Json(e) => write!(f, "json error: {}", e),
            ManifestError::ChecksumMismatch { expected, actual } => {
                write!(
                    f,
                    "checksum mismatch: expected {}, got {}",
                    expected, actual
                )
            }
            ManifestError::InvalidVersion { found, expected } => {
                write!(
                    f,
                    "unsupported manifest version {} (expected {})",
                    found, expected
                )
            }
        }
    }
}

impl std::error::Error for ManifestError {}

impl From<std::io::Error> for ManifestError {
    fn from(e: std::io::Error) -> Self {
        ManifestError::Io(e)
    }
}

impl From<serde_json::Error> for ManifestError {
    fn from(e: serde_json::Error) -> Self {
        ManifestError::Json(e)
    }
}

fn sort_json_value(value: &mut serde_json::Value) {
    match value {
        serde_json::Value::Object(map) => {
            let mut entries: Vec<_> = map.iter().map(|(k, v)| (k.clone(), v.clone())).collect();
            entries.sort_by(|a, b| a.0.cmp(&b.0));
            map.clear();
            for (k, mut v) in entries {
                sort_json_value(&mut v);
                map.insert(k, v);
            }
        }
        serde_json::Value::Array(arr) => {
            for v in arr.iter_mut() {
                sort_json_value(v);
            }
        }
        _ => {}
    }
}

fn compute_manifest_checksum(manifest: &Manifest) -> String {
    use sha2::{Digest, Sha256};
    let mut copy = manifest.clone();
    copy.checksum = String::new();
    copy.created_at = String::new();
    copy.server_version = String::new();
    let mut value = serde_json::to_value(&copy).unwrap_or_default();
    sort_json_value(&mut value);
    let json_str = serde_json::to_string(&value).unwrap_or_default();
    let mut hasher = Sha256::new();
    hasher.update(json_str.as_bytes());
    format!("{:x}", hasher.finalize())
}

fn iso_now() -> String {
    chrono::Utc::now().to_rfc3339()
}

fn server_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

pub fn write_manifest(manifest: &mut Manifest, path: &Path) -> Result<(), ManifestError> {
    manifest.format_version = CURRENT_MANIFEST_VERSION;
    manifest.checksum = String::new();
    manifest.created_at = String::new();
    manifest.server_version = String::new();
    manifest.checksum = compute_manifest_checksum(manifest);
    manifest.created_at = iso_now();
    manifest.server_version = server_version();

    let json = serde_json::to_string_pretty(manifest)?;
    let tmp_path = path.with_extension("tmp");
    std::fs::write(&tmp_path, json.as_bytes())?;
    std::fs::rename(&tmp_path, path)?;
    Ok(())
}

pub fn read_manifest(path: &Path) -> Result<Manifest, ManifestError> {
    let content = std::fs::read_to_string(path)?;
    let manifest: Manifest = serde_json::from_str(&content)?;

    if manifest.format_version != CURRENT_MANIFEST_VERSION {
        return Err(ManifestError::InvalidVersion {
            found: manifest.format_version,
            expected: CURRENT_MANIFEST_VERSION,
        });
    }

    let stored_checksum = manifest.checksum.clone();
    let computed = compute_manifest_checksum(&manifest);
    if stored_checksum != computed && !stored_checksum.is_empty() {
        return Err(ManifestError::ChecksumMismatch {
            expected: stored_checksum,
            actual: computed,
        });
    }

    Ok(manifest)
}

pub fn manifest_path(data_dir: &Path) -> std::path::PathBuf {
    data_dir.join("manifest.json")
}

pub fn create_empty_manifest(
    system_clubs: crate::server::SystemClubs,
    grand_map_id_counter: BeId,
) -> Manifest {
    Manifest {
        format_version: CURRENT_MANIFEST_VERSION,
        created_at: iso_now(),
        server_version: server_version(),
        checksum: String::new(),
        grand_map_id_counter,
        session_counter: 0,
        operation_counter: 0,
        system_clubs,
        works: Vec::new(),
        clubs: Vec::new(),
        standalone_editions: Vec::new(),
        links: Vec::new(),
        link_counter: 0,
        admin: AdminEntry {
            accepting_connections: true,
            shutdown_requested: false,
            grants: Vec::new(),
        },
        reconcile_store: crate::server::federation::ReconcileStore::new(),
        reconcile_counter: 0,
        federation: None,
        content_address: None,
        blob_metas: Vec::new(),
        key_history: None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn temp_dir() -> PathBuf {
        static COUNTER: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
        let id = COUNTER.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        std::env::temp_dir().join(format!(
            "xudanu_manifest_test_{}_{}",
            std::process::id(),
            id
        ))
    }

    use std::path::PathBuf;

    fn test_system_clubs() -> crate::server::SystemClubs {
        crate::server::SystemClubs {
            public_club: 1,
            admin_club: 2,
            access_club: 3,
            empty_club: 4,
        }
    }

    #[test]
    fn write_read_roundtrip() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let path = manifest_path(&dir);
        let mut manifest = create_empty_manifest(test_system_clubs(), 100);
        write_manifest(&mut manifest, &path).unwrap();

        assert!(path.exists());
        assert!(!path.with_extension("tmp").exists());

        let restored = read_manifest(&path).unwrap();
        assert_eq!(restored.format_version, CURRENT_MANIFEST_VERSION);
        assert_eq!(restored.grand_map_id_counter, 100);
        assert_eq!(restored.system_clubs.public_club, 1);
        assert!(restored.works.is_empty());
        assert!(restored.links.is_empty());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn checksum_detects_corruption() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let path = manifest_path(&dir);
        let mut manifest = create_empty_manifest(test_system_clubs(), 100);
        write_manifest(&mut manifest, &path).unwrap();

        let content = std::fs::read_to_string(&path).unwrap();
        let corrupted = content.replace(
            "\"grand_map_id_counter\": 100",
            "\"grand_map_id_counter\": 999",
        );
        std::fs::write(&path, corrupted).unwrap();

        let result = read_manifest(&path);
        assert!(result.is_err());
        match result.unwrap_err() {
            ManifestError::ChecksumMismatch { .. } => {}
            other => panic!("expected ChecksumMismatch, got: {}", other),
        }

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn invalid_version_rejected() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let path = manifest_path(&dir);

        let mut manifest = create_empty_manifest(test_system_clubs(), 0);
        manifest.format_version = 99;
        manifest.checksum = "abc".to_string();
        let json = serde_json::to_string_pretty(&manifest).unwrap();
        std::fs::write(&path, json).unwrap();

        let result = read_manifest(&path);
        assert!(result.is_err());
        match result.unwrap_err() {
            ManifestError::InvalidVersion {
                found: 99,
                expected: CURRENT_MANIFEST_VERSION,
            } => {}
            other => panic!("expected InvalidVersion, got: {}", other),
        }

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn manifest_with_works_and_links() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let store = ChunkStore::open(&dir).unwrap();

        let edition = crate::edition::edition::Edition::from_text("test document");
        let work = crate::edition::work::Work::new(10, edition);
        let work_ref = crate::persist::edition_chunks::work_to_chunks(&work, &store).unwrap();

        let mut manifest = create_empty_manifest(test_system_clubs(), 200);
        manifest.works.push((10, work_ref));
        manifest.links.push(LinkEntry {
            link_id: 50,
            origin: 10,
            destination: 11,
            origin_ref: None,
            destination_ref: None,
        });
        manifest.link_counter = 51;

        let path = manifest_path(&dir);
        write_manifest(&mut manifest, &path).unwrap();

        let restored = read_manifest(&path).unwrap();
        assert_eq!(restored.works.len(), 1);
        assert_eq!(restored.works[0].0, 10);
        assert_eq!(restored.links.len(), 1);
        assert_eq!(restored.links[0].origin, 10);
        assert_eq!(restored.link_counter, 51);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn manifest_path_is_data_dir_manifest_json() {
        let path = manifest_path(Path::new("/tmp/xudanu-data"));
        assert_eq!(
            path,
            std::path::PathBuf::from("/tmp/xudanu-data/manifest.json")
        );
    }

    #[test]
    fn empty_manifest_defaults() {
        let manifest = create_empty_manifest(test_system_clubs(), 1);
        assert_eq!(manifest.format_version, CURRENT_MANIFEST_VERSION);
        assert!(manifest.admin.accepting_connections);
        assert!(!manifest.admin.shutdown_requested);
        assert!(manifest.works.is_empty());
        assert!(manifest.clubs.is_empty());
        assert!(manifest.federation.is_none());
    }
}
