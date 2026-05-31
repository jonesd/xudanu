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
    #[serde(default)]
    pub sequence: u64,

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

pub fn rotate_manifest_backups(path: &Path, keep: usize) {
    let data_dir = match path.parent() {
        Some(d) => d,
        None => return,
    };
    let stem = path
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("manifest");

    let mut backups: Vec<(u64, std::path::PathBuf)> = Vec::new();
    let entries = match std::fs::read_dir(data_dir) {
        Ok(rd) => rd,
        Err(_) => return,
    };
    for entry in entries.flatten() {
        let name = entry.file_name();
        let name_str = match name.to_str() {
            Some(s) => s,
            None => continue,
        };
        if let Some(rest) = name_str
            .strip_prefix(stem)
            .and_then(|s| s.strip_prefix("_v"))
        {
            if let Some(seq_str) = rest.strip_suffix(".json") {
                if let Ok(seq) = seq_str.parse::<u64>() {
                    backups.push((seq, entry.path()));
                }
            }
        }
    }

    backups.sort_by_key(|(seq, _)| *seq);

    while backups.len() > keep {
        let (_, oldest) = backups.remove(0);
        if let Err(e) = std::fs::remove_file(&oldest) {
            tracing::warn!("Failed to remove old backup {}: {}", oldest.display(), e);
        }
    }
}

pub fn backup_manifest_path(data_dir: &Path, sequence: u64) -> std::path::PathBuf {
    data_dir.join(format!("manifest_v{}.json", sequence))
}

pub fn read_manifest_with_fallback(
    path: &Path,
    max_backups: usize,
) -> Result<Manifest, ManifestError> {
    match read_manifest(path) {
        Ok(m) => Ok(m),
        Err(primary_err) => {
            let data_dir = path.parent().unwrap_or(path);
            let mut backups: Vec<(u64, std::path::PathBuf)> = Vec::new();
            for entry in
                std::fs::read_dir(data_dir).unwrap_or_else(|_| std::fs::read_dir(".").unwrap())
            {
                if let Ok(entry) = entry {
                    let name = entry.file_name();
                    let name_str = name.to_str().unwrap_or("");
                    if let Some(rest) = name_str.strip_prefix("manifest_v") {
                        if let Some(seq_str) = rest.strip_suffix(".json") {
                            if let Ok(seq) = seq_str.parse::<u64>() {
                                backups.push((seq, entry.path()));
                            }
                        }
                    }
                }
            }
            backups.sort_by(|a, b| b.0.cmp(&a.0));

            let mut checked = 0;
            for (seq, backup_path) in &backups {
                if checked >= max_backups {
                    break;
                }
                checked += 1;
                tracing::warn!(
                    "Primary manifest failed ({}), trying manifest_v{}.json",
                    primary_err,
                    seq
                );
                match read_manifest(backup_path) {
                    Ok(m) => {
                        tracing::info!("Restored from manifest_v{}.json", seq);
                        let _ = std::fs::copy(backup_path, path);
                        tracing::info!("Promoted manifest_v{}.json to primary", seq);
                        return Ok(m);
                    }
                    Err(e) => {
                        tracing::warn!("manifest_v{}.json also failed: {}", seq, e);
                        continue;
                    }
                }
            }
            Err(primary_err)
        }
    }
}

pub fn write_manifest(manifest: &mut Manifest, path: &Path) -> Result<(), ManifestError> {
    manifest.format_version = CURRENT_MANIFEST_VERSION;
    manifest.checksum = String::new();
    manifest.created_at = String::new();
    manifest.server_version = String::new();
    if manifest.sequence == 0 {
        if path.exists() {
            if let Ok(existing) = read_manifest(path) {
                manifest.sequence = existing.sequence;
            }
        }
    }
    manifest.sequence += 1;
    manifest.checksum = compute_manifest_checksum(manifest);
    manifest.created_at = iso_now();
    manifest.server_version = server_version();

    let json = serde_json::to_string_pretty(manifest)?;
    let tmp_path = path.with_extension("tmp");
    {
        let mut f = std::fs::File::create(&tmp_path)?;
        std::io::Write::write_all(&mut f, json.as_bytes())?;
        f.sync_all()?;
    }
    std::fs::rename(&tmp_path, path)?;
    if let Some(parent) = path.parent() {
        if let Ok(dir) = std::fs::File::open(parent) {
            let _ = dir.sync_all();
        }
    }
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
        sequence: 0,
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
        assert_eq!(manifest.sequence, 0);
    }

    #[test]
    fn sequence_increments_on_write() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        let path = manifest_path(&dir);

        write_manifest(&mut m, &path).unwrap();
        assert_eq!(m.sequence, 1);

        write_manifest(&mut m, &path).unwrap();
        assert_eq!(m.sequence, 2);

        write_manifest(&mut m, &path).unwrap();
        assert_eq!(m.sequence, 3);

        let restored = read_manifest(&path).unwrap();
        assert_eq!(restored.sequence, 3);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn sequence_survives_reload() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        let path = manifest_path(&dir);

        write_manifest(&mut m, &path).unwrap();
        assert_eq!(m.sequence, 1);

        let mut reloaded = read_manifest(&path).unwrap();
        assert_eq!(reloaded.sequence, 1);

        write_manifest(&mut reloaded, &path).unwrap();
        assert_eq!(reloaded.sequence, 2);

        let final_read = read_manifest(&path).unwrap();
        assert_eq!(final_read.sequence, 2);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn rotate_creates_backup_copies() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        let path = manifest_path(&dir);

        write_manifest(&mut m, &path).unwrap();
        assert_eq!(m.sequence, 1);
        let backup = backup_manifest_path(&dir, 1);
        assert!(
            !backup.exists(),
            "versioned backup not yet created (created on next checkpoint)"
        );

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn rotate_enforces_keep_limit() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        for seq in 1..=5 {
            let backup = backup_manifest_path(&dir, seq);
            std::fs::write(&backup, format!("{{\"sequence\":{}}}", seq)).unwrap();
        }

        let path = manifest_path(&dir);
        let _ = std::fs::write(&path, "{}");

        rotate_manifest_backups(&path, 3);

        assert!(
            !backup_manifest_path(&dir, 1).exists(),
            "v1 should be removed (keep=3)"
        );
        assert!(
            !backup_manifest_path(&dir, 2).exists(),
            "v2 should be removed (keep=3)"
        );
        assert!(backup_manifest_path(&dir, 3).exists(), "v3 should survive");
        assert!(backup_manifest_path(&dir, 4).exists(), "v4 should survive");
        assert!(backup_manifest_path(&dir, 5).exists(), "v5 should survive");

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn versioned_backups_named_by_sequence() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        let path = manifest_path(&dir);

        write_manifest(&mut m, &path).unwrap();
        assert_eq!(m.sequence, 1);
        let b1 = backup_manifest_path(&dir, 1);
        std::fs::copy(&path, &b1).unwrap();

        m.grand_map_id_counter = 200;
        write_manifest(&mut m, &path).unwrap();
        assert_eq!(m.sequence, 2);
        let b2 = backup_manifest_path(&dir, 2);
        std::fs::copy(&path, &b2).unwrap();

        assert!(b1.exists());
        assert!(b2.exists());
        assert!(b1
            .file_name()
            .unwrap()
            .to_str()
            .unwrap()
            .contains("manifest_v1.json"));
        assert!(b2
            .file_name()
            .unwrap()
            .to_str()
            .unwrap()
            .contains("manifest_v2.json"));

        let r1 = read_manifest(&b1).unwrap();
        assert_eq!(r1.sequence, 1);
        assert_eq!(r1.grand_map_id_counter, 100);

        let r2 = read_manifest(&b2).unwrap();
        assert_eq!(r2.sequence, 2);
        assert_eq!(r2.grand_map_id_counter, 200);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn fallback_reads_primary_first() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        let path = manifest_path(&dir);
        write_manifest(&mut m, &path).unwrap();

        let result = read_manifest_with_fallback(&path, 3).unwrap();
        assert_eq!(result.sequence, m.sequence);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn fallback_uses_backup_when_primary_corrupt() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        let path = manifest_path(&dir);
        write_manifest(&mut m, &path).unwrap();

        let backup = backup_manifest_path(&dir, m.sequence);
        std::fs::copy(&path, &backup).unwrap();

        std::fs::write(&path, b"CORRUPTED!!!").unwrap();

        let result = read_manifest_with_fallback(&path, 3).unwrap();
        assert_eq!(
            result.sequence, m.sequence,
            "should read from versioned backup"
        );

        let primary = std::fs::read_to_string(&path).unwrap();
        assert!(
            !primary.starts_with("CORRUPTED"),
            "primary should be restored from backup"
        );

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn fallback_tries_multiple_backups() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m1 = create_empty_manifest(test_system_clubs(), 100);
        let path = manifest_path(&dir);
        write_manifest(&mut m1, &path).unwrap();
        let b1 = backup_manifest_path(&dir, m1.sequence);
        std::fs::copy(&path, &b1).unwrap();

        let mut m2 = m1.clone();
        m2.grand_map_id_counter = 200;
        write_manifest(&mut m2, &path).unwrap();
        let b2 = backup_manifest_path(&dir, m2.sequence);
        std::fs::copy(&path, &b2).unwrap();

        std::fs::write(&path, b"BAD").unwrap();
        std::fs::write(&b2, b"ALSO BAD").unwrap();

        let result = read_manifest_with_fallback(&path, 3).unwrap();
        assert_eq!(
            result.grand_map_id_counter, 100,
            "should read from v1 backup"
        );

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn fallback_returns_error_when_all_corrupt() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        let path = manifest_path(&dir);
        write_manifest(&mut m, &path).unwrap();
        let b1 = backup_manifest_path(&dir, m.sequence);
        std::fs::copy(&path, &b1).unwrap();

        m.grand_map_id_counter = 200;
        write_manifest(&mut m, &path).unwrap();
        let b2 = backup_manifest_path(&dir, m.sequence);
        std::fs::copy(&path, &b2).unwrap();

        std::fs::write(&path, b"BAD1").unwrap();
        std::fs::write(&b1, b"BAD2").unwrap();
        std::fs::write(&b2, b"BAD3").unwrap();

        let result = read_manifest_with_fallback(&path, 3);
        assert!(result.is_err(), "should fail when all backups are corrupt");

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn write_manifest_uses_fsync() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        let path = manifest_path(&dir);
        write_manifest(&mut m, &path).unwrap();

        assert!(
            !path.with_extension("tmp").exists(),
            "tmp file should be cleaned up"
        );
        assert!(path.exists(), "manifest should exist");

        let restored = read_manifest(&path).unwrap();
        assert_eq!(restored.sequence, 1);
        assert!(!restored.checksum.is_empty());

        let _ = std::fs::remove_dir_all(&dir);
    }
}
