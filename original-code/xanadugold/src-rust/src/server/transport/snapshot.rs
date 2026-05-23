use std::path::Path;

const CURRENT_FORMAT_VERSION: u32 = 1;
const MIN_BACKUP_VERSIONS: usize = 2;

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct VersionedSnapshot {
    pub format_version: u32,
    pub created_at: String,
    pub server_version: String,
    pub checksum: String,
    pub data: serde_json::Value,
}

#[derive(Debug)]
pub struct ValidationReport {
    pub warnings: Vec<String>,
    pub errors: Vec<String>,
}

impl ValidationReport {
    pub fn is_valid(&self) -> bool {
        self.errors.is_empty()
    }

    pub fn has_warnings(&self) -> bool {
        !self.warnings.is_empty()
    }
}

#[derive(Debug)]
pub enum SnapshotError {
    Io(std::io::Error),
    Json(serde_json::Error),
    Migration {
        from_version: u32,
        to_version: u32,
        reason: String,
    },
    Validation(ValidationReport),
    InsufficientDiskSpace {
        required_bytes: u64,
        available_bytes: u64,
    },
    ChecksumMismatch {
        expected: String,
        actual: String,
    },
}

impl std::fmt::Display for SnapshotError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            SnapshotError::Io(e) => write!(f, "I/O error: {}", e),
            SnapshotError::Json(e) => write!(f, "JSON error: {}", e),
            SnapshotError::Migration {
                from_version,
                to_version,
                reason,
            } => {
                write!(
                    f,
                    "migration v{} → v{} failed: {}",
                    from_version, to_version, reason
                )
            }
            SnapshotError::Validation(report) => {
                write!(f, "validation failed: {} errors", report.errors.len())
            }
            SnapshotError::InsufficientDiskSpace {
                required_bytes,
                available_bytes,
            } => {
                write!(
                    f,
                    "insufficient disk space: need {} bytes, have {} bytes",
                    required_bytes, available_bytes
                )
            }
            SnapshotError::ChecksumMismatch { expected, actual } => {
                write!(
                    f,
                    "checksum mismatch: expected {}, got {}",
                    expected, actual
                )
            }
        }
    }
}

impl std::error::Error for SnapshotError {}

impl From<std::io::Error> for SnapshotError {
    fn from(e: std::io::Error) -> Self {
        SnapshotError::Io(e)
    }
}

impl From<serde_json::Error> for SnapshotError {
    fn from(e: serde_json::Error) -> Self {
        SnapshotError::Json(e)
    }
}

fn server_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

fn iso_now() -> String {
    chrono::Utc::now().to_rfc3339()
}

fn compute_checksum(data: &serde_json::Value) -> String {
    use sha2::{Digest, Sha256};
    let json_str = serde_json::to_string(data).unwrap_or_default();
    let mut hasher = Sha256::new();
    hasher.update(json_str.as_bytes());
    format!("{:x}", hasher.finalize())
}

fn available_disk_space(path: &Path) -> Result<u64, SnapshotError> {
    let parent = if path.is_dir() {
        path
    } else {
        path.parent().unwrap_or(path)
    };
    let output = std::process::Command::new("df")
        .arg("-k")
        .arg(parent)
        .output()
        .map_err(SnapshotError::Io)?;
    let stdout = String::from_utf8_lossy(&output.stdout);
    for line in stdout.lines().skip(1) {
        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() >= 4 {
            if let Ok(avail_kb) = parts[3].parse::<u64>() {
                return Ok(avail_kb * 1024);
            }
        }
    }
    Ok(u64::MAX)
}

fn file_size(path: &Path) -> Result<u64, SnapshotError> {
    Ok(std::fs::metadata(path).map(|m| m.len()).unwrap_or(0))
}

pub fn required_disk_space(current_size: u64) -> u64 {
    3 * current_size + 1024 * 1024
}

pub fn check_disk_space(snapshot_path: &Path) -> Result<u64, SnapshotError> {
    let current = file_size(snapshot_path)?;
    let required = required_disk_space(current);
    let available = available_disk_space(snapshot_path)?;
    if available < required {
        return Err(SnapshotError::InsufficientDiskSpace {
            required_bytes: required,
            available_bytes: available,
        });
    }
    Ok(available)
}

pub fn detect_version(raw: &serde_json::Value) -> u32 {
    if raw.is_object() {
        if let Some(version) = raw.get("format_version").and_then(|v| v.as_u64()) {
            return version as u32;
        }
    }
    0
}

fn migrate_v0_to_v1(mut raw: serde_json::Value) -> Result<serde_json::Value, SnapshotError> {
    if !raw.is_object() {
        return Err(SnapshotError::Migration {
            from_version: 0,
            to_version: 1,
            reason: "expected JSON object".to_string(),
        });
    }
    let checksum = compute_checksum(&raw);
    let wrapped = serde_json::json!({
        "format_version": 1,
        "created_at": iso_now(),
        "server_version": server_version(),
        "checksum": checksum,
        "data": raw,
    });
    Ok(wrapped)
}

pub fn migrate_to_latest(
    raw: serde_json::Value,
    from_version: u32,
) -> Result<serde_json::Value, SnapshotError> {
    let mut current = raw;
    let mut version = from_version;
    while version < CURRENT_FORMAT_VERSION {
        let next = version + 1;
        current = match (version, next) {
            (0, 1) => migrate_v0_to_v1(current)?,
            _ => {
                return Err(SnapshotError::Migration {
                    from_version: version,
                    to_version: next,
                    reason: format!("no migration path from v{}", version),
                })
            }
        };
        version = next;
    }
    Ok(current)
}

pub fn validate_snapshot(data: &serde_json::Value) -> ValidationReport {
    let mut warnings = Vec::new();
    let mut errors = Vec::new();

    if !data.is_object() {
        errors.push("snapshot root is not an object".to_string());
        return ValidationReport { warnings, errors };
    }

    let obj = data.as_object().unwrap();

    if !obj.contains_key("grand_map_id_counter") {
        errors.push("missing grand_map_id_counter".to_string());
    }
    if !obj.contains_key("works") {
        errors.push("missing works array".to_string());
    }
    if let Some(works) = obj.get("works").and_then(|w| w.as_array()) {
        for (i, work_entry) in works.iter().enumerate() {
            let work = if work_entry.is_array() && work_entry.as_array().unwrap().len() >= 2 {
                &work_entry.as_array().unwrap()[1]
            } else {
                work_entry
            };
            if !work.is_object() {
                warnings.push(format!("works[{}] entry is not an object", i));
                continue;
            }
            let wo = work.as_object().unwrap();
            let rev_count = wo
                .get("revision_count")
                .and_then(|v| v.as_u64())
                .unwrap_or(0);
            let history_len = wo
                .get("history")
                .and_then(|v| v.as_object())
                .map(|h| h.len() as u64)
                .unwrap_or(0);
            if rev_count > 0 && history_len == 0 {
                warnings.push(format!(
                    "works[{}] has revision_count={} but empty history",
                    i, rev_count
                ));
            }
        }
    }
    if let Some(links) = obj.get("links").and_then(|l| l.as_array()) {
        for (i, link) in links.iter().enumerate() {
            if !link.is_object() {
                errors.push(format!("links[{}] is not an object", i));
            }
        }
    }
    if let Some(clubs) = obj.get("clubs").and_then(|c| c.as_array()) {
        if clubs.len() < 3 {
            warnings.push(format!(
                "only {} clubs (expected at least 3 system clubs)",
                clubs.len()
            ));
        }
    }

    ValidationReport { warnings, errors }
}

pub fn create_backup(snapshot_path: &Path) -> Result<(), SnapshotError> {
    let version_suffix = detect_file_version(snapshot_path)?;
    let file_name = snapshot_path
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("server.json");
    let backup_name = format!("{}.v{}.bak", file_name, version_suffix);
    let backup_path = snapshot_path.with_file_name(backup_name);
    if snapshot_path.exists() {
        std::fs::copy(snapshot_path, &backup_path)?;
        tracing::info!("Created backup: {}", backup_path.display());
        cleanup_old_backups(snapshot_path)?;
    }
    Ok(())
}

fn detect_file_version(path: &Path) -> Result<u32, SnapshotError> {
    if !path.exists() {
        return Ok(0);
    }
    let content = std::fs::read_to_string(path)?;
    let raw: serde_json::Value = serde_json::from_str(&content)?;
    Ok(detect_version(&raw))
}

fn cleanup_old_backups(snapshot_path: &Path) -> Result<(), SnapshotError> {
    let parent = snapshot_path.parent().unwrap_or(snapshot_path);
    let stem = snapshot_path
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("server");
    let mut backups: Vec<(u32, std::path::PathBuf)> = Vec::new();
    for entry in std::fs::read_dir(parent)? {
        let entry = entry?;
        let name = entry.file_name();
        let name_str = name.to_string_lossy();
        if name_str.starts_with(stem) && name_str.contains(".v") && name_str.ends_with(".bak") {
            if let Some(version) = extract_backup_version(&name_str) {
                backups.push((version, entry.path()));
            }
        }
    }
    backups.sort_by(|a, b| b.0.cmp(&a.0));
    for (_, path) in backups.into_iter().skip(MIN_BACKUP_VERSIONS) {
        let _ = std::fs::remove_file(&path);
    }
    Ok(())
}

fn extract_backup_version(filename: &str) -> Option<u32> {
    let start = filename.find(".v")?;
    let rest = &filename[start + 2..];
    let end = rest.find(".bak")?;
    rest[..end].parse().ok()
}

pub fn write_versioned_snapshot(
    snapshot_path: &Path,
    data: &serde_json::Value,
) -> Result<(), SnapshotError> {
    let checksum = compute_checksum(data);
    let versioned = VersionedSnapshot {
        format_version: CURRENT_FORMAT_VERSION,
        created_at: iso_now(),
        server_version: server_version(),
        checksum,
        data: data.clone(),
    };
    let json = serde_json::to_string_pretty(&versioned).map_err(SnapshotError::Json)?;
    let tmp_path = snapshot_path.with_extension("tmp");
    std::fs::write(&tmp_path, json.as_bytes())?;
    std::fs::rename(&tmp_path, snapshot_path)?;
    Ok(())
}

pub fn read_and_migrate(
    snapshot_path: &Path,
) -> Result<(serde_json::Value, u32, bool), SnapshotError> {
    let content = std::fs::read_to_string(snapshot_path)?;
    let raw: serde_json::Value = serde_json::from_str(&content)?;

    let detected_version = detect_version(&raw);
    let needs_migration = detected_version < CURRENT_FORMAT_VERSION;

    let (data, final_version) = if detected_version == CURRENT_FORMAT_VERSION {
        let versioned: VersionedSnapshot =
            serde_json::from_value(raw).map_err(SnapshotError::Json)?;
        let computed = compute_checksum(&versioned.data);
        if computed != versioned.checksum {
            return Err(SnapshotError::ChecksumMismatch {
                expected: versioned.checksum,
                actual: computed,
            });
        }
        (versioned.data, versioned.format_version)
    } else {
        let migrated = migrate_to_latest(raw, detected_version)?;
        let versioned: VersionedSnapshot =
            serde_json::from_value(migrated).map_err(SnapshotError::Json)?;
        (versioned.data, versioned.format_version)
    };

    Ok((data, final_version, needs_migration))
}

pub fn full_restore(snapshot_path: &Path) -> Result<serde_json::Value, SnapshotError> {
    check_disk_space(snapshot_path)?;

    let (data, version, needs_migration) = read_and_migrate(snapshot_path)?;

    let report = validate_snapshot(&data);
    if !report.is_valid() {
        return Err(SnapshotError::Validation(report));
    }
    for warning in &report.warnings {
        tracing::warn!("Snapshot validation warning: {}", warning);
    }

    if needs_migration {
        tracing::info!("Migrating snapshot to v{}", version);
        create_backup(snapshot_path)?;
        write_versioned_snapshot(snapshot_path, &data)?;
        tracing::info!("Migration to v{} complete", version);
    }

    Ok(data)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;

    fn v0_snapshot_json() -> &'static str {
        r#"{"grand_map_id_counter":100,"session_counter":0,"operation_counter":0,"system_clubs":{"public_club":1,"admin_club":2,"server_club":3},"works":[],"clubs":[{"be_id":1,"name":"public","signature_club":null,"work":{"be_id":1,"owner":null,"revision_count":0,"current":{"entries":[],"default":null,"domain_start":null,"domain_infinite_above":false},"history":{},"read_club":null,"edit_club":null,"sponsors":[]},"default_read_club":null,"default_edit_club":null}],"standalone_editions":[],"links":[],"link_counter":0,"admin":{"accepting_connections":true,"shutdown_requested":false,"grants":[]},"reconcile_store":[],"reconcile_counter":0,"federation":null,"content_address":null,"blob_metas":[],"key_history":null}"#
    }

    #[test]
    fn detect_v0_format() {
        let raw: serde_json::Value = serde_json::from_str(v0_snapshot_json()).unwrap();
        assert_eq!(detect_version(&raw), 0);
    }

    #[test]
    fn detect_v1_format() {
        let wrapped = serde_json::json!({
            "format_version": 1,
            "created_at": "2026-01-01T00:00:00Z",
            "server_version": "0.1.1",
            "checksum": "abc123",
            "data": {"grand_map_id_counter": 100}
        });
        assert_eq!(detect_version(&wrapped), 1);
    }

    #[test]
    fn migrate_v0_to_v1_wraps_data() {
        let raw: serde_json::Value = serde_json::from_str(v0_snapshot_json()).unwrap();
        let result = migrate_v0_to_v1(raw).unwrap();
        assert_eq!(result["format_version"], 1);
        assert!(result["created_at"].is_string());
        assert_eq!(result["server_version"], server_version());
        assert!(result["checksum"].is_string());
        assert!(result["data"]["grand_map_id_counter"].is_number());
    }

    #[test]
    fn migrate_v0_to_v1_preserves_data() {
        let raw: serde_json::Value = serde_json::from_str(v0_snapshot_json()).unwrap();
        let original = raw.clone();
        let result = migrate_v0_to_v1(raw).unwrap();
        assert_eq!(
            result["data"]["grand_map_id_counter"],
            original["grand_map_id_counter"]
        );
        assert_eq!(result["data"]["works"], original["works"]);
    }

    #[test]
    fn checksum_detects_corruption() {
        let raw: serde_json::Value = serde_json::from_str(v0_snapshot_json()).unwrap();
        let migrated = migrate_v0_to_v1(raw).unwrap();
        let checksum = migrated["checksum"].as_str().unwrap().to_string();

        let mut corrupted = migrated.clone();
        corrupted["data"]["grand_map_id_counter"] = serde_json::json!(999);
        let bad_checksum = compute_checksum(&corrupted["data"]);
        assert_ne!(checksum, bad_checksum);
    }

    #[test]
    fn validate_good_snapshot() {
        let raw: serde_json::Value = serde_json::from_str(v0_snapshot_json()).unwrap();
        let report = validate_snapshot(&raw);
        assert!(report.is_valid());
    }

    #[test]
    fn validate_missing_fields() {
        let raw = serde_json::json!({"works": []});
        let report = validate_snapshot(&raw);
        assert!(!report.is_valid());
    }

    #[test]
    fn validate_not_object() {
        let raw = serde_json::json!(42);
        let report = validate_snapshot(&raw);
        assert!(!report.is_valid());
        assert!(report.errors[0].contains("not an object"));
    }

    #[test]
    fn required_disk_space_is_triple_plus_margin() {
        assert!(required_disk_space(1000) > 3000);
    }

    #[test]
    fn extract_backup_version_works() {
        assert_eq!(extract_backup_version("server.json.v0.bak"), Some(0));
        assert_eq!(extract_backup_version("server.json.v1.bak"), Some(1));
        assert_eq!(extract_backup_version("server.json.v12.bak"), Some(12));
        assert_eq!(extract_backup_version("server.tmp"), None);
    }

    #[test]
    fn migrate_to_latest_from_v0() {
        let raw: serde_json::Value = serde_json::from_str(v0_snapshot_json()).unwrap();
        let result = migrate_to_latest(raw, 0).unwrap();
        assert_eq!(result["format_version"], 1);
    }

    #[test]
    fn migrate_to_latest_already_current() {
        let raw: serde_json::Value = serde_json::from_str(v0_snapshot_json()).unwrap();
        let v1 = migrate_v0_to_v1(raw).unwrap();
        let result = migrate_to_latest(v1.clone(), 1).unwrap();
        assert_eq!(result, v1);
    }

    #[test]
    fn full_write_read_roundtrip() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("server.json");
        let data: serde_json::Value = serde_json::from_str(v0_snapshot_json()).unwrap();

        write_versioned_snapshot(&path, &data).unwrap();

        let content = std::fs::read_to_string(&path).unwrap();
        let raw: serde_json::Value = serde_json::from_str(&content).unwrap();
        assert_eq!(detect_version(&raw), 1);

        let (read_data, version, _) = read_and_migrate(&path).unwrap();
        assert_eq!(version, 1);
        assert_eq!(read_data["grand_map_id_counter"], 100);
    }

    #[test]
    fn migration_creates_backup() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("server.json");

        std::fs::write(&path, v0_snapshot_json().as_bytes()).unwrap();

        let data = match crate::server::transport::snapshot::full_restore(&path) {
            Ok(d) => d,
            Err(e) => {
                panic!("full_restore failed: {}", e);
            }
        };

        assert!(
            dir.path().join("server.json.v0.bak").exists(),
            "backup should exist at server.json.v0.bak"
        );

        let content = std::fs::read_to_string(&path).unwrap();
        let raw: serde_json::Value = serde_json::from_str(&content).unwrap();
        assert_eq!(detect_version(&raw), 1, "file should now be v1");
    }
}
