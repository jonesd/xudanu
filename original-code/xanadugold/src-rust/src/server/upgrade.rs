//! FR-82 — the shared upgrade pipeline.
//!
//! One implementation, two doors:
//!
//! - `xudanu-server upgrade <dir>` — the explicit, offline command
//!   (operators, scripts, CI).
//! - startup auto-migration — when `restore_from_data_dir` sees data
//!   older than the binary, it runs this same pipeline before
//!   booting (default; `--no-auto-migrate` / `XUDANU_NO_AUTO_MIGRATE=1`
//!   restores the refuse-and-instruct behavior).
//!
//! Pipeline: backup → migrate (the registered step chain, walked
//! revision by revision) → verify (full restore, counts, restore
//! errors) → stamp. Any failure rolls the data directory back from
//! the backup. Data NEWER than the binary is always refused —
//! auto-downgrade does not exist.

use std::path::{Path, PathBuf};

/// Report from a successful (or no-op) upgrade — the CLI prints it.
#[derive(Debug, Clone)]
pub struct UpgradeReport {
    /// "unknown" when the data pre-dates the VERSION sidecar.
    pub data_version: String,
    pub from_format: u32,
    pub binary_version: String,
    pub to_format: u32,
    pub backup_dir: Option<PathBuf>,
    pub steps_applied: usize,
    pub work_count: usize,
    pub link_count: usize,
    pub trail_count: usize,
    pub already_current: bool,
}

#[derive(Debug)]
pub enum UpgradeError {
    /// Not a xudanu data directory (typos, empty dirs init_tracing
    /// may have just materialized).
    NotADataDir(PathBuf),
    /// The data is from a NEWER binary — upgrade the binary instead.
    NewerThanBinary {
        data_format: u32,
        binary_format: u32,
    },
    /// Another migration holds the lock.
    LockHeld(PathBuf),
    /// Migration or verification failed; the data directory was
    /// restored from the backup (original data intact).
    RolledBack {
        reason: String,
        backup: PathBuf,
    },
    Io(std::io::Error),
}

impl std::fmt::Display for UpgradeError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            UpgradeError::NotADataDir(p) => write!(
                f,
                "{} does not exist or is not a xudanu data directory",
                p.display()
            ),
            UpgradeError::NewerThanBinary {
                data_format,
                binary_format,
            } => write!(
                f,
                "data is format v{} but this binary supports v{}. Upgrade xudanu-server first.",
                data_format, binary_format
            ),
            UpgradeError::LockHeld(p) => write!(
                f,
                "another migration is in progress (lock at {})",
                p.display()
            ),
            UpgradeError::RolledBack { reason, backup } => write!(
                f,
                "{}; rolled back from {}, original data intact",
                reason,
                backup.display()
            ),
            UpgradeError::Io(e) => write!(f, "io error: {}", e),
        }
    }
}

impl std::error::Error for UpgradeError {}

impl From<std::io::Error> for UpgradeError {
    fn from(e: std::io::Error) -> Self {
        UpgradeError::Io(e)
    }
}

impl From<crate::persist::migrations::MigrationError> for UpgradeError {
    fn from(e: crate::persist::migrations::MigrationError) -> Self {
        UpgradeError::Io(std::io::Error::other(e.to_string()))
    }
}

/// The first format that wrote the VERSION sidecar. Stampless data
/// with a manifest is from this era regardless of how far the
/// current format has advanced.
pub const STAMPLESS_FORMAT: u32 = 1;

/// --no-auto-migrate flag (CLI) and the env var both land here.
static NO_AUTO_MIGRATE: std::sync::atomic::AtomicBool = std::sync::atomic::AtomicBool::new(false);

pub fn set_no_auto_migrate(yes: bool) {
    NO_AUTO_MIGRATE.store(yes, std::sync::atomic::Ordering::Relaxed);
}

/// Auto-migration is on by default; the flag or env var opts out.
pub fn auto_migrate_enabled() -> bool {
    if NO_AUTO_MIGRATE.load(std::sync::atomic::Ordering::Relaxed) {
        return false;
    }
    std::env::var("XUDANU_NO_AUTO_MIGRATE").as_deref() != Ok("1")
}

// Re-entrancy guard: the pipeline's own verification restore must
// not re-trigger startup auto-migration on the still-old stamp.
thread_local! {
    static IN_UPGRADE: std::cell::Cell<bool> = const { std::cell::Cell::new(false) };
}

fn in_upgrade() -> bool {
    IN_UPGRADE.with(|c| c.get())
}

/// Test/embedder hook: run the pipeline against an arbitrary step
/// chain instead of the production registry. Not for production use.
#[doc(hidden)]
pub fn set_step_override(steps: Option<Vec<crate::persist::migrations::MigrationStep>>) {
    let mut guard = STEP_OVERRIDE.lock().unwrap();
    *guard = steps;
}

static STEP_OVERRIDE: std::sync::Mutex<Option<Vec<crate::persist::migrations::MigrationStep>>> =
    std::sync::Mutex::new(None);

fn effective_steps() -> Vec<crate::persist::migrations::MigrationStep> {
    STEP_OVERRIDE
        .lock()
        .unwrap()
        .clone()
        .unwrap_or_else(|| crate::persist::migrations::MIGRATION_STEPS.to_vec())
}

pub fn looks_like_data_dir(dir: &Path) -> bool {
    [
        "root_manifest.json",
        "manifest.json",
        "VERSION",
        "server.json",
    ]
    .iter()
    .any(|f| dir.join(f).exists())
        || dir.join("chunks").is_dir()
}

/// The inferred format of a data dir: the sidecar's value, or the
/// stampless era for manifest-bearing dirs. None = no xudanu data.
pub fn data_format_of(
    dir: &Path,
) -> Option<(u32, Option<crate::persist::root_chunk::VersionStamp>)> {
    let stamp = crate::persist::root_chunk::VersionStamp::read(dir);
    if let Some(s) = stamp {
        return Some((s.format_version, Some(s)));
    }
    if looks_like_data_dir(dir) {
        return Some((STAMPLESS_FORMAT, None));
    }
    None
}

/// Run the pipeline with the production (or overridden) step chain.
pub fn run_upgrade(data_dir: &Path) -> Result<UpgradeReport, UpgradeError> {
    run_upgrade_with(data_dir, effective_steps())
}

/// The pipeline proper. `steps` is the chain to walk; everything
/// else (backup, verify, stamp, rollback) is identical for the CLI
/// and startup doors.
pub fn run_upgrade_with(
    data_dir: &Path,
    steps: Vec<crate::persist::migrations::MigrationStep>,
) -> Result<UpgradeReport, UpgradeError> {
    let binary_format = crate::persist::root_chunk::ROOT_CHUNK_FORMAT_VERSION;
    let binary_version = env!("CARGO_PKG_VERSION").to_string();

    let (from_format, stamp) = match data_format_of(data_dir) {
        Some(v) => v,
        None => return Err(UpgradeError::NotADataDir(data_dir.to_path_buf())),
    };
    let data_version = stamp
        .as_ref()
        .map(|s| s.server_version.clone())
        .unwrap_or_else(|| "unknown".to_string());

    if from_format > binary_format {
        return Err(UpgradeError::NewerThanBinary {
            data_format: from_format,
            binary_format,
        });
    }

    if from_format == binary_format {
        // Idempotent: refresh the stamp so it names this binary.
        let fresh = crate::persist::root_chunk::VersionStamp {
            format_version: binary_format,
            server_version: binary_version.clone(),
            upgraded_at: Some(chrono::Utc::now().to_rfc3339()),
        };
        fresh.write(data_dir)?;
        return Ok(UpgradeReport {
            data_version,
            from_format,
            binary_version,
            to_format: binary_format,
            backup_dir: None,
            steps_applied: 0,
            work_count: 0,
            link_count: 0,
            trail_count: 0,
            already_current: true,
        });
    }

    // Exclusive lock: a concurrent server on the same data dir must
    // never observe (or race) a half-migrated directory.
    let _lock = MigrationLock::acquire(data_dir)?;

    // Backup — always, before any step touches the data.
    let backup_dir = data_dir
        .parent()
        .unwrap_or_else(|| Path::new("."))
        .join(format!(
            "backup-{}",
            chrono::Utc::now().format("%Y%m%d-%H%M%S")
        ));
    crate::persist::migrations::copy_dir(data_dir, &backup_dir)?;

    let rollback = |reason: String| -> UpgradeError {
        // Rollback failures must be LOUD, never silent (bug-pattern
        // catalog: silent I/O failure). The data has no other copy
        // than the backup at this moment.
        if let Err(e) = std::fs::remove_dir_all(data_dir) {
            tracing::error!("[migrate] rollback: removing migrated dir failed: {e}");
        }
        match std::fs::rename(&backup_dir, data_dir) {
            Ok(()) => UpgradeError::RolledBack {
                reason,
                backup: backup_dir.clone(),
            },
            Err(e) => {
                tracing::error!(
                    "[migrate] CRITICAL: rollback rename failed: {e} — original data \
                     preserved at {}",
                    backup_dir.display()
                );
                UpgradeError::Io(std::io::Error::other(format!(
                    "rollback failed: {e}; original data preserved at {}",
                    backup_dir.display()
                )))
            }
        }
    };

    // Migration failure → rollback.
    let steps_applied = match crate::persist::migrations::apply_steps_with(
        data_dir,
        from_format,
        binary_format,
        &steps,
    ) {
        Ok(n) => n,
        Err(e) => return Err(rollback(format!("migration failed: {}", e))),
    };

    // Verification: full restore on a fresh server. The in_upgrade
    // guard keeps this restore from re-triggering auto-migration.
    IN_UPGRADE.with(|c| c.set(true));
    let verify = (|| -> Result<(usize, usize, usize), String> {
        let mut server = crate::server::Server::new();
        server
            .restore_from_data_dir(data_dir, None)
            .map_err(|e| format!("verification failed: could not restore: {}", e))?;
        if server.has_restore_errors() {
            let errs = server.restore_errors().join("; ");
            return Err(format!("verification found restore errors: {}", errs));
        }
        // FR-82/83 interplay: verification is DELIBERATE full
        // hydration — under lazy restore the restore alone verifies
        // only metadata; thawing every work reads and rebuilds every
        // edition from chunks, which is the verification's point.
        // A thaw failure (corrupt/mangled chunk) fails the upgrade
        // into rollback, exactly like an eager-restore failure.
        let ids: Vec<_> = server.works.keys().copied().collect();
        let mut thaw_failures = Vec::new();
        for id in ids {
            if let Err(e) = server.ensure_materialized(id) {
                thaw_failures.push(format!("work {:x}: {}", id, e));
            }
        }
        if !thaw_failures.is_empty() {
            return Err(format!(
                "verification found unthawable works: {}",
                thaw_failures.join("; ")
            ));
        }
        Ok((
            server.work_count(),
            server.link_count(),
            server.trail_count(),
        ))
    })();
    IN_UPGRADE.with(|c| c.set(false));

    let (work_count, link_count, trail_count) = match verify {
        Ok(v) => v,
        Err(reason) => return Err(rollback(reason)),
    };

    // Stamp the new version — only after verification passed.
    let fresh = crate::persist::root_chunk::VersionStamp {
        format_version: binary_format,
        server_version: binary_version.clone(),
        upgraded_at: Some(chrono::Utc::now().to_rfc3339()),
    };
    fresh.write(data_dir)?;

    Ok(UpgradeReport {
        data_version,
        from_format,
        binary_version,
        to_format: binary_format,
        backup_dir: Some(backup_dir),
        steps_applied,
        work_count,
        link_count,
        trail_count,
        already_current: false,
    })
}

/// Exclusive migration lock: `data/MIGRATION.lock` holding the PID.
/// A live foreign process holding the lock blocks; a stale lock
/// (dead PID, crashed mid-migration) is stolen.
struct MigrationLock {
    path: PathBuf,
    released: bool,
}

impl MigrationLock {
    fn acquire(data_dir: &Path) -> Result<Self, UpgradeError> {
        let path = data_dir.join("MIGRATION.lock");
        match std::fs::File::options()
            .write(true)
            .create_new(true)
            .open(&path)
        {
            Ok(mut f) => {
                use std::io::Write;
                if let Err(e) = writeln!(f, "{}", std::process::id()) {
                    // Degrades safely: an unreadable lock reads as
                    // stale and is stealable. But never silently.
                    tracing::warn!("[migrate] could not write PID to lock: {e}");
                }
                Ok(MigrationLock {
                    path,
                    released: false,
                })
            }
            Err(e) if e.kind() == std::io::ErrorKind::AlreadyExists => {
                if Self::holder_is_dead(&path) {
                    // Stale lock from a crashed migration: steal it.
                    if let Err(steal_err) = std::fs::remove_file(&path) {
                        tracing::warn!("[migrate] removing stale lock failed: {steal_err}");
                    }
                    return Self::acquire(data_dir);
                }
                Err(UpgradeError::LockHeld(path))
            }
            Err(e) => Err(UpgradeError::Io(e)),
        }
    }

    fn holder_is_dead(path: &Path) -> bool {
        let text = std::fs::read_to_string(path).unwrap_or_default();
        let pid: i32 = text.trim().parse().unwrap_or(0);
        if pid <= 0 {
            return true; // unreadable lock = stale
        }
        #[cfg(unix)]
        {
            // Signal 0: liveness probe, no actual signal delivered.
            std::process::Command::new("kill")
                .args(["-0", &pid.to_string()])
                .stdin(std::process::Stdio::null())
                .stdout(std::process::Stdio::null())
                .stderr(std::process::Stdio::null())
                .status()
                .map(|s| !s.success())
                .unwrap_or(false)
        }
        #[cfg(not(unix))]
        {
            false // cannot probe: assume alive (fail closed)
        }
    }
}

impl Drop for MigrationLock {
    fn drop(&mut self) {
        if !self.released {
            if let Err(e) = std::fs::remove_file(&self.path) {
                tracing::warn!(
                    "[migrate] lock release failed: {e} — a stale lock will be \
                     stolen by the next migration"
                );
            }
        }
    }
}

/// Whether startup auto-migration should run for this restore —
/// used by `restore_from_data_dir`'s version gate.
pub fn startup_should_auto_migrate() -> bool {
    auto_migrate_enabled() && !in_upgrade()
}

/// The gate decision for a restore facing older-format data.
/// `Proceed` covers the pipeline's own verification restore (the
/// stamp is written only after verification passes).
pub enum StartupGate {
    Proceed,
    AutoMigrate,
    Refuse,
}

pub fn startup_gate_decision() -> StartupGate {
    if in_upgrade() {
        StartupGate::Proceed
    } else if auto_migrate_enabled() {
        StartupGate::AutoMigrate
    } else {
        StartupGate::Refuse
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn auto_migrate_default_on_flag_off() {
        assert!(auto_migrate_enabled());
        set_no_auto_migrate(true);
        assert!(!auto_migrate_enabled());
        set_no_auto_migrate(false);
        assert!(auto_migrate_enabled());
    }

    #[test]
    fn not_a_data_dir_rejected() {
        let dir = std::env::temp_dir().join(format!(
            "xudanu_upgrade_nodata_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        std::fs::create_dir_all(&dir).unwrap();
        assert!(matches!(
            run_upgrade(&dir),
            Err(UpgradeError::NotADataDir(_))
        ));
        drop(std::fs::remove_dir_all(&dir));
    }
}
