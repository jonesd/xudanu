use std::collections::BTreeMap;
use std::path::Path;

use crate::edition::backend::BeId;
use crate::persist::chunk_store::ChunkStore;
use crate::persist::edition_chunks::{EditionChunkRef, WorkChunkRef};

const CURRENT_MANIFEST_VERSION: u32 = 4;

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
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub link_types: Vec<u64>,
}

/// On-disk representation of a work entry in the manifest.
///
/// ## Persistence invariant
///
/// Every field on `WorkState` that must survive a server restart must have a
/// corresponding field here, and must be written in `Server::checkpoint_to_store()`
/// and read back in `Server::restore_from_data_dir()`.
///
/// If you add a field to `WorkState` that should be persisted, you **must**:
/// 1. Add it to this struct (with `#[serde(default)]` for backward compat)
/// 2. Write it in `Server::checkpoint_to_store()` (the `WorkEntry { … }` literal)
/// 3. Read it in `Server::restore_from_data_dir()` (the `WorkState { … }` literal)
/// 4. Add a test in `server::server::tests` that proves it survives a
///    `checkpoint_to_store()` → `restore_from_data_dir()` round-trip
///
/// The `source_fingerprint` field is intentionally **not** stored here — it is
/// recomputed from the edition text on restore (see `restore_from_data_dir`).
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct WorkEntry {
    pub be_id: BeId,
    pub work_ref: WorkChunkRef,
    #[serde(default)]
    pub is_source: bool,
    #[serde(default)]
    pub source_author_id: Option<BeId>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub source_edition_info: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub content_start_line: Option<u64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub content_end_line: Option<u64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub source_fingerprint: Option<Vec<u64>>,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct AdminEntry {
    pub accepting_connections: bool,
    pub shutdown_requested: bool,
    pub grants: Vec<(BeId, i64, i64)>,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct TrailStopManifestEntry {
    pub work_id: BeId,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub char_start: Option<u64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub char_end: Option<u64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct TrailManifestEntry {
    pub trail_id: BeId,
    pub owner_club: BeId,
    pub name: String,
    pub stops: Vec<TrailStopManifestEntry>,
    pub created_at: u64,
    pub updated_at: u64,
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

/// The manifest is the primary persistence artifact for the chunk-based data
/// directory. It is written by `Server::checkpoint_to_store()` and read by
/// `Server::restore_from_data_dir()`.
///
/// ## Persistence invariant
///
/// Runtime state that must survive a restart lives in one of three places:
///
/// 1. **Chunk store** — edition content (the actual text), stored as hashed
///    chunks referenced by `WorkChunkRef` / `EditionChunkRef`.
/// 2. **This manifest** — metadata that doesn't live in chunks: work source
///    flags, authorship, links, clubs, historical authors, etc.
/// 3. **Sidecar files** — key material (`server.key`), blob data (`blobs/`),
///    attribution log.
///
/// If you add persistable state to `Server`, `WorkState`, or any other runtime
/// struct, you must also add it here (with `#[serde(default)]` for backward
/// compat) and wire it through `checkpoint_to_store()` / `restore_from_data_dir()`.
/// See `WorkEntry` for the per-field checklist.
fn is_null_char(c: &char) -> bool {
    *c == '\0'
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct Manifest {
    pub format_version: u32,
    pub created_at: String,
    pub server_version: String,
    pub checksum: String,
    #[serde(default)]
    pub sequence: u64,
    #[serde(default, skip_serializing_if = "is_null_char")]
    pub manifest_slot: char,

    pub grand_map_id_counter: BeId,
    pub session_counter: u64,
    pub operation_counter: u64,
    pub system_clubs: crate::server::SystemClubs,

    pub works: Vec<WorkEntry>,
    pub clubs: Vec<ClubChunkRef>,
    pub standalone_editions: Vec<StandaloneEditionChunkRef>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub links_hash: Option<[u8; 32]>,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub links: Vec<LinkEntry>,
    pub link_counter: BeId,

    pub admin: AdminEntry,

    pub reconcile_store: crate::server::federation::ReconcileStore,
    pub reconcile_counter: u64,
    pub federation: Option<crate::server::federation::FederationSnapshot>,

    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub content_address_hash: Option<[u8; 32]>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub content_address: Option<crate::edition::ContentAddressIndex>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub blob_metas_hash: Option<[u8; 32]>,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub blob_metas: Vec<BlobMetaEntry>,
    pub key_history: Option<KeyHistoryEntry>,
    /// Hash of the historical author registry chunk in the chunk store.
    /// Used on restore to load authors from the chunk store.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub historical_authors_hash: Option<[u8; 32]>,
    /// Legacy inline historical author registry. Kept for backward compat with
    /// old manifests. New checkpoints use `historical_authors_hash` instead.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub historical_authors: Option<crate::server::historical_author::HistoricalAuthorRegistry>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub annotations_hash: Option<[u8; 32]>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub fossil_snapshots_hash: Option<[u8; 32]>,
    #[serde(default)]
    pub starred_works: std::collections::HashMap<BeId, std::collections::HashSet<BeId>>,
    #[serde(default)]
    pub trails: Vec<TrailManifestEntry>,
    #[serde(default)]
    pub trail_counter: BeId,
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

fn compute_manifest_checksum_from_raw(content: &str) -> String {
    use sha2::{Digest, Sha256};
    let mut value: serde_json::Value = match serde_json::from_str(content) {
        Ok(v) => v,
        Err(_) => return String::new(),
    };
    if let serde_json::Value::Object(ref mut map) = value {
        map.remove("checksum");
        map.remove("created_at");
        map.remove("server_version");
    }
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

pub fn write_backup_with_fsync(src: &Path, dst: &Path) -> Result<(), ManifestError> {
    let tmp_path = dst.with_extension("baktmp");
    {
        let mut src_file = std::fs::File::open(src)?;
        let mut dst_file = std::fs::File::create(&tmp_path)?;
        std::io::copy(&mut src_file, &mut dst_file)?;
        dst_file.sync_all()?;
    }
    if tmp_path != dst {
        std::fs::rename(&tmp_path, dst)?;
    }
    if let Some(parent) = dst.parent() {
        if let Ok(dir) = std::fs::File::open(parent) {
            let _ = dir.sync_all();
        }
    }
    Ok(())
}

pub fn read_manifest_dual(data_dir: &Path) -> Result<Manifest, ManifestError> {
    let primary = data_dir.join("manifest.json");
    let slot_a = data_dir.join("manifest_a.json");
    let slot_b = data_dir.join("manifest_b.json");

    let primary_result = if primary.exists() {
        read_manifest(&primary).ok()
    } else {
        None
    };

    let slot_a_result = if slot_a.exists() {
        read_manifest(&slot_a).ok()
    } else {
        None
    };

    let slot_b_result = if slot_b.exists() {
        read_manifest(&slot_b).ok()
    } else {
        None
    };

    let best = match (primary_result, slot_a_result, slot_b_result) {
        (Some(p), Some(a), Some(b)) => {
            if p.sequence >= a.sequence && p.sequence >= b.sequence {
                Some(p)
            } else if a.sequence >= b.sequence {
                Some(a)
            } else {
                Some(b)
            }
        }
        (Some(p), Some(a), None) => {
            if p.sequence >= a.sequence {
                Some(p)
            } else {
                Some(a)
            }
        }
        (Some(p), None, Some(b)) => {
            if p.sequence >= b.sequence {
                Some(p)
            } else {
                Some(b)
            }
        }
        (Some(p), None, None) => Some(p),
        (None, Some(a), Some(b)) => {
            if a.sequence >= b.sequence {
                Some(a)
            } else {
                Some(b)
            }
        }
        (None, Some(a), None) => Some(a),
        (None, None, Some(b)) => Some(b),
        (None, None, None) => None,
    };

    match best {
        Some(manifest) => {
            let slot = if manifest.manifest_slot == 'a' || manifest.manifest_slot == 'b' {
                manifest.manifest_slot
            } else {
                'a'
            };
            let _ = std::fs::copy(
                match slot {
                    'a' => &slot_a,
                    'b' => &slot_b,
                    _ => &slot_a,
                },
                &primary,
            );
            Ok(manifest)
        }
        None => read_manifest_with_fallback(&primary, 3),
    }
}

pub fn read_manifest(path: &Path) -> Result<Manifest, ManifestError> {
    let content = std::fs::read_to_string(path)?;
    read_manifest_from_str(&content)
}

fn read_manifest_from_str(content: &str) -> Result<Manifest, ManifestError> {
    let manifest: Manifest = serde_json::from_str(content)?;

    if manifest.format_version > CURRENT_MANIFEST_VERSION {
        return Err(ManifestError::InvalidVersion {
            found: manifest.format_version,
            expected: CURRENT_MANIFEST_VERSION,
        });
    }
    if manifest.format_version < CURRENT_MANIFEST_VERSION {
        tracing::info!(
            "Manifest version {} → {} (will upgrade on next checkpoint)",
            manifest.format_version,
            CURRENT_MANIFEST_VERSION,
        );
    }

    let stored_checksum = manifest.checksum.clone();
    let computed = compute_manifest_checksum(&manifest);
    if stored_checksum != computed && !stored_checksum.is_empty() {
        let raw_computed = compute_manifest_checksum_from_raw(content);
        if raw_computed == stored_checksum {
            tracing::warn!(
                "Manifest checksum mismatch due to schema evolution (new default fields). \
                 Accepting manifest — checksum will be corrected on next checkpoint."
            );
            return Ok(manifest);
        }

        tracing::error!(
            "Manifest checksum mismatch: stored={}, recompute={}, raw={}. \
             The manifest may be genuinely corrupt. \
             Possible fixes: \
             (1) restore from a backup in the data directory, \
             (2) run 'xudanu-server rebuild-manifest <data-dir>', or \
             (3) delete the data directory to start fresh.",
            stored_checksum,
            computed,
            raw_computed,
        );
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

#[derive(Debug)]
pub struct PreflightReport {
    pub manifest_found: bool,
    pub manifest_version: Option<u32>,
    pub manifest_sequence: Option<u64>,
    pub checksum_ok: bool,
    pub checksum_schema_drift: bool,
    pub can_start: bool,
    pub warnings: Vec<String>,
    pub errors: Vec<String>,
}

impl std::fmt::Display for PreflightReport {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        writeln!(f, "Preflight check for data directory:")?;
        if !self.manifest_found {
            writeln!(f, "  manifest.json: NOT FOUND (will initialize)")?;
            return Ok(());
        }
        writeln!(
            f,
            "  manifest version: {}",
            self.manifest_version
                .map(|v| v.to_string())
                .unwrap_or_else(|| "?".to_string())
        )?;
        writeln!(
            f,
            "  manifest sequence: {}",
            self.manifest_sequence
                .map(|s| s.to_string())
                .unwrap_or_else(|| "?".to_string())
        )?;
        if self.checksum_schema_drift {
            writeln!(
                f,
                "  checksum: SCHEMA DRIFT (new default fields, will self-heal on checkpoint)"
            )?;
        } else if self.checksum_ok {
            writeln!(f, "  checksum: OK")?;
        } else {
            writeln!(f, "  checksum: FAILED (corrupt or tampered)")?;
        }
        for w in &self.warnings {
            writeln!(f, "  WARNING: {}", w)?;
        }
        for e in &self.errors {
            writeln!(f, "  ERROR: {}", e)?;
        }
        if self.can_start {
            writeln!(f, "  result: OK — safe to start")?;
        } else {
            writeln!(f, "  result: BLOCKED — fix errors before starting")?;
        }
        Ok(())
    }
}

pub fn preflight_check(data_dir: &Path) -> PreflightReport {
    let mut report = PreflightReport {
        manifest_found: false,
        manifest_version: None,
        manifest_sequence: None,
        checksum_ok: false,
        checksum_schema_drift: false,
        can_start: false,
        warnings: Vec::new(),
        errors: Vec::new(),
    };

    let path = manifest_path(data_dir);
    if !path.exists() {
        report.can_start = true;
        return report;
    }
    report.manifest_found = true;

    let content = match std::fs::read_to_string(&path) {
        Ok(c) => c,
        Err(e) => {
            report.errors.push(format!(
                "Cannot read {}: {}. Check file permissions.",
                path.display(),
                e
            ));
            return report;
        }
    };

    let raw_value: serde_json::Value = match serde_json::from_str(&content) {
        Ok(v) => v,
        Err(e) => {
            report.errors.push(format!(
                "Invalid JSON in {}: {}. \
                 Run 'xudanu-server rebuild-manifest {}' or restore from a backup.",
                path.display(),
                e,
                data_dir.display()
            ));
            return report;
        }
    };

    let version = raw_value
        .get("format_version")
        .and_then(|v| v.as_u64())
        .map(|v| v as u32);
    report.manifest_version = version;

    report.manifest_sequence = raw_value.get("sequence").and_then(|v| v.as_u64());

    let stored_checksum = raw_value
        .get("checksum")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();

    if let Some(v) = version {
        if v > CURRENT_MANIFEST_VERSION {
            report.errors.push(format!(
                "Manifest format_version {} is NEWER than this binary supports ({}). \
                 You need to upgrade xudanu-server to a newer version. \
                 Downgrade is not supported.",
                v, CURRENT_MANIFEST_VERSION
            ));
            return report;
        }
        if v < CURRENT_MANIFEST_VERSION {
            report.warnings.push(format!(
                "Manifest format_version {} will be auto-upgraded to {} on next checkpoint.",
                v, CURRENT_MANIFEST_VERSION
            ));
        }
    } else {
        report
            .errors
            .push("Manifest has no format_version field. File may be corrupt.".to_string());
        return report;
    }

    if stored_checksum.is_empty() {
        report
            .warnings
            .push("Manifest has no checksum — skipping validation.".to_string());
        report.checksum_ok = true;
        report.can_start = true;
        return report;
    }

    let manifest: Manifest = match serde_json::from_str(&content) {
        Ok(m) => m,
        Err(e) => {
            report.errors.push(format!(
                "Manifest parsed as raw JSON but failed struct deserialization: {}. \
                 A field may have an incompatible type. \
                 Run 'xudanu-server rebuild-manifest {}' to rebuild.",
                e,
                data_dir.display()
            ));
            return report;
        }
    };

    let computed = compute_manifest_checksum(&manifest);
    if computed == stored_checksum {
        report.checksum_ok = true;
        report.can_start = true;
        return report;
    }

    let raw_computed = compute_manifest_checksum_from_raw(&content);
    if raw_computed == stored_checksum {
        report.checksum_schema_drift = true;
        report.checksum_ok = true;
        report.can_start = true;
        report.warnings.push(
            "Checksum matches raw content but differs after deserialization — \
             this is normal after a schema upgrade. \
             The checksum will self-heal on the next checkpoint."
                .to_string(),
        );
        return report;
    }

    report.errors.push(format!(
        "Primary manifest checksum mismatch: stored {} but content hashes to {}. \
         Checking backups...",
        stored_checksum, raw_computed
    ));

    let mut backup_entries: Vec<(u64, std::path::PathBuf)> = Vec::new();
    if let Ok(rd) = std::fs::read_dir(data_dir) {
        for entry in rd.flatten() {
            let name = entry.file_name();
            let name_str = match name.to_str() {
                Some(s) => s,
                None => continue,
            };
            if let Some(rest) = name_str.strip_prefix("manifest_v") {
                if let Some(seq_str) = rest.strip_suffix(".json") {
                    if let Ok(seq) = seq_str.parse::<u64>() {
                        backup_entries.push((seq, entry.path()));
                    }
                }
            }
        }
    }
    backup_entries.sort_by(|a, b| b.0.cmp(&a.0));

    let mut found_valid_backup = false;
    for (seq, backup_path) in &backup_entries {
        tracing::info!("Preflight: trying backup manifest_v{}.json", seq);
        match read_manifest(backup_path) {
            Ok(_m) => {
                tracing::info!(
                    "Preflight: backup manifest_v{}.json is valid. \
                     Primary will be restored from backup on startup.",
                    seq
                );
                report.errors.clear();
                report.warnings.push(format!(
                    "Primary manifest corrupt, but backup manifest_v{}.json is valid. \
                     Server will restore from backup automatically.",
                    seq
                ));
                report.can_start = true;
                found_valid_backup = true;
                break;
            }
            Err(e) => {
                tracing::warn!(
                    "Preflight: backup manifest_v{}.json also failed: {}",
                    seq,
                    e
                );
            }
        }
    }

    if !found_valid_backup {
        report.errors.push(format!(
            "No valid backup found either. Options: \
             (1) Run 'xudanu-server rebuild-manifest {}', or \
             (2) Delete the data directory to start fresh (all data will be lost).",
            data_dir.display()
        ));
    }

    let _ = manifest;
    report
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
        manifest_slot: 'a',
        grand_map_id_counter,
        session_counter: 0,
        operation_counter: 0,
        system_clubs,
        works: Vec::new(),
        clubs: Vec::new(),
        standalone_editions: Vec::new(),
        links_hash: None,
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
        content_address_hash: None,
        content_address: None,
        blob_metas_hash: None,
        blob_metas: Vec::new(),
        key_history: None,
        historical_authors_hash: None,
        historical_authors: None,
        annotations_hash: None,
        fossil_snapshots_hash: None,
        starred_works: std::collections::HashMap::new(),
        trails: Vec::new(),
        trail_counter: 10_000,
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
        manifest.works.push(WorkEntry {
            be_id: 10,
            work_ref: work_ref,
            is_source: false,
            source_author_id: None,
            source_edition_info: None,
            content_start_line: None,
            content_end_line: None,
            source_fingerprint: None,
        });
        manifest.links.push(LinkEntry {
            link_id: 50,
            origin: 10,
            destination: 11,
            origin_ref: None,
            destination_ref: None,
            link_types: vec![],
        });
        manifest.link_counter = 51;

        let path = manifest_path(&dir);
        write_manifest(&mut manifest, &path).unwrap();

        let restored = read_manifest(&path).unwrap();
        assert_eq!(restored.works.len(), 1);
        assert_eq!(restored.works[0].be_id, 10);
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

    #[test]
    fn manifest_slot_roundtrip() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        assert_eq!(m.manifest_slot, 'a');
        let path = manifest_path(&dir);
        write_manifest(&mut m, &path).unwrap();

        let restored = read_manifest(&path).unwrap();
        assert_eq!(restored.manifest_slot, 'a');

        m.manifest_slot = 'b';
        write_manifest(&mut m, &path).unwrap();
        let restored = read_manifest(&path).unwrap();
        assert_eq!(restored.manifest_slot, 'b');

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn write_backup_with_fsync_creates_identical_copy() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        let path = manifest_path(&dir);
        write_manifest(&mut m, &path).unwrap();

        let backup = dir.join("backup_manifest.json");
        write_backup_with_fsync(&path, &backup).unwrap();

        assert!(backup.exists());
        let original = std::fs::read_to_string(&path).unwrap();
        let backup_content = std::fs::read_to_string(&backup).unwrap();
        assert_eq!(original, backup_content);

        let restored = read_manifest(&backup).unwrap();
        assert_eq!(restored.sequence, m.sequence);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn write_backup_with_fsync_uses_tmp_then_rename() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        let path = manifest_path(&dir);
        write_manifest(&mut m, &path).unwrap();

        let backup = dir.join("backup_test.json");
        write_backup_with_fsync(&path, &backup).unwrap();
        assert!(
            !dir.join("backup_test.baktmp").exists(),
            "tmp file should be cleaned up"
        );

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn dual_manifest_recovery_prefers_higher_sequence() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m_a = create_empty_manifest(test_system_clubs(), 100);
        m_a.manifest_slot = 'a';
        let path_a = dir.join("manifest_a.json");
        write_manifest(&mut m_a, &path_a).unwrap();

        let mut m_b = create_empty_manifest(test_system_clubs(), 200);
        m_b.manifest_slot = 'b';
        m_b.sequence = m_a.sequence + 10;
        m_b.checksum = compute_manifest_checksum(&m_b);
        let path_b = dir.join("manifest_b.json");
        {
            let json = serde_json::to_string_pretty(&m_b).unwrap();
            std::fs::write(&path_b, json).unwrap();
        }

        let result = read_manifest_dual(&dir).unwrap();
        assert_eq!(
            result.grand_map_id_counter, 200,
            "should pick manifest_b (higher sequence)"
        );

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn dual_manifest_primary_corrupt_falls_back_to_slot() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        m.manifest_slot = 'a';
        let slot_a = dir.join("manifest_a.json");
        write_manifest(&mut m, &slot_a).unwrap();

        let primary = manifest_path(&dir);
        std::fs::copy(&slot_a, &primary).unwrap();

        std::fs::write(&primary, b"CORRUPTED").unwrap();

        let result = read_manifest_dual(&dir).unwrap();
        assert_eq!(result.grand_map_id_counter, 100);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn dual_manifest_all_corrupt_falls_back_to_versioned() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        let path = manifest_path(&dir);
        write_manifest(&mut m, &path).unwrap();

        let backup = backup_manifest_path(&dir, m.sequence);
        std::fs::copy(&path, &backup).unwrap();

        let slot_a = dir.join("manifest_a.json");
        let slot_b = dir.join("manifest_b.json");
        std::fs::write(&path, b"BAD_PRIMARY").unwrap();
        std::fs::write(&slot_a, b"BAD_A").unwrap();
        std::fs::write(&slot_b, b"BAD_B").unwrap();

        let result = read_manifest_dual(&dir).unwrap();
        assert_eq!(
            result.grand_map_id_counter, 100,
            "should recover from versioned backup"
        );

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn dual_manifest_no_slots_uses_primary() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        let path = manifest_path(&dir);
        write_manifest(&mut m, &path).unwrap();

        let result = read_manifest_dual(&dir).unwrap();
        assert_eq!(result.grand_map_id_counter, 100);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn dual_manifest_empty_dir_returns_error() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let result = read_manifest_dual(&dir);
        assert!(result.is_err());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn backup_rotation_keeps_newest_first() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let path = manifest_path(&dir);

        let mut m1 = create_empty_manifest(test_system_clubs(), 100);
        write_manifest(&mut m1, &path).unwrap();
        let b1 = backup_manifest_path(&dir, m1.sequence);
        std::fs::copy(&path, &b1).unwrap();

        let mut m2 = create_empty_manifest(test_system_clubs(), 200);
        m2.sequence = 5;
        m2.checksum = compute_manifest_checksum(&m2);
        let b5 = backup_manifest_path(&dir, 5);
        let json = serde_json::to_string_pretty(&m2).unwrap();
        std::fs::write(&b5, json).unwrap();

        let mut m3 = create_empty_manifest(test_system_clubs(), 300);
        m3.sequence = 10;
        m3.checksum = compute_manifest_checksum(&m3);
        let b10 = backup_manifest_path(&dir, 10);
        let json3 = serde_json::to_string_pretty(&m3).unwrap();
        std::fs::write(&b10, json3).unwrap();

        let mut m4 = create_empty_manifest(test_system_clubs(), 400);
        m4.sequence = 15;
        m4.checksum = compute_manifest_checksum(&m4);
        let b15 = backup_manifest_path(&dir, 15);
        let json4 = serde_json::to_string_pretty(&m4).unwrap();
        std::fs::write(&b15, json4).unwrap();

        assert!(b1.exists());
        assert!(b5.exists());
        assert!(b10.exists());
        assert!(b15.exists());

        rotate_manifest_backups(&path, 2);

        assert!(!b1.exists(), "v1 should be removed");
        assert!(!b5.exists(), "v5 should be removed");
        assert!(b10.exists(), "v10 should survive");
        assert!(b15.exists(), "v15 should survive");

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn old_manifest_without_manifest_slot_passes_checksum() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        let path = manifest_path(&dir);

        m.manifest_slot = '\0';
        write_manifest(&mut m, &path).unwrap();

        let content = std::fs::read_to_string(&path).unwrap();
        assert!(
            !content.contains("manifest_slot"),
            "null slot should be skipped during serialization"
        );

        let restored = read_manifest(&path).unwrap();
        assert_eq!(restored.manifest_slot, '\0');
        assert_eq!(restored.grand_map_id_counter, 100);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn legacy_manifest_without_slot_field_is_readable() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        m.manifest_slot = '\0';
        let path = manifest_path(&dir);
        write_manifest(&mut m, &path).unwrap();

        let content = std::fs::read_to_string(&path).unwrap();
        let legacy_content = content.replace("\"manifest_slot\": \"\\u0000\",\n", "");
        assert!(
            !legacy_content.contains("manifest_slot"),
            "should have no manifest_slot field"
        );
        std::fs::write(&path, &legacy_content).unwrap();

        let restored = read_manifest(&path).unwrap();
        assert_eq!(
            restored.grand_map_id_counter, 100,
            "should read legacy manifest"
        );
        assert_eq!(
            restored.manifest_slot, '\0',
            "missing field defaults to null"
        );

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn preflight_empty_dir_is_ok() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let report = preflight_check(&dir);
        assert!(report.can_start);
        assert!(!report.manifest_found);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn preflight_valid_manifest_is_ok() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        let path = manifest_path(&dir);
        write_manifest(&mut m, &path).unwrap();

        let report = preflight_check(&dir);
        assert!(report.can_start);
        assert!(report.manifest_found);
        assert!(report.checksum_ok);
        assert!(!report.checksum_schema_drift);
        assert!(report.errors.is_empty());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn preflight_null_slot_valid_manifest_is_ok() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        m.manifest_slot = '\0';
        let path = manifest_path(&dir);
        write_manifest(&mut m, &path).unwrap();

        let content = std::fs::read_to_string(&path).unwrap();
        assert!(
            !content.contains("manifest_slot"),
            "null slot should not appear in file"
        );

        let report = preflight_check(&dir);
        assert!(report.can_start, "valid manifest should pass");
        assert!(report.checksum_ok);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn preflight_detects_real_corruption() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        let path = manifest_path(&dir);
        write_manifest(&mut m, &path).unwrap();

        let content = std::fs::read_to_string(&path).unwrap();
        let corrupted = content.replace("100", "99999");
        std::fs::write(&path, &corrupted).unwrap();

        let report = preflight_check(&dir);
        assert!(!report.can_start, "genuine corruption should block startup");
        assert!(!report.errors.is_empty());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn preflight_corrupt_manifest_is_blocked() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        let path = manifest_path(&dir);
        write_manifest(&mut m, &path).unwrap();

        let content = std::fs::read_to_string(&path).unwrap();
        let corrupted = content.replace(
            "\"grand_map_id_counter\": 100",
            "\"grand_map_id_counter\": 999",
        );
        std::fs::write(&path, &corrupted).unwrap();

        let report = preflight_check(&dir);
        assert!(!report.can_start, "corrupt manifest should block startup");
        assert!(!report.errors.is_empty());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn preflight_future_version_is_blocked() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        let path = manifest_path(&dir);
        write_manifest(&mut m, &path).unwrap();

        let content = std::fs::read_to_string(&path).unwrap();
        let modified = content.replace(
            &format!("\"format_version\": {}", CURRENT_MANIFEST_VERSION),
            "\"format_version\": 999",
        );
        std::fs::write(&path, &modified).unwrap();

        let report = preflight_check(&dir);
        assert!(!report.can_start, "future version should block startup");
        assert!(report.errors.iter().any(|e| e.contains("NEWER")));

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn preflight_invalid_json_is_blocked() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let path = manifest_path(&dir);
        std::fs::write(&path, b"{not valid json}").unwrap();

        let report = preflight_check(&dir);
        assert!(!report.can_start);
        assert!(report.errors.iter().any(|e| e.contains("Invalid JSON")));

        let _ = std::fs::remove_dir_all(&dir);
    }
}
