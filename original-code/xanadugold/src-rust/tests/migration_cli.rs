//! Integration tests for the migration & upgrade system (FR-82).
//!
//! Two layers:
//! - Library-driven tests for the startup version check in
//!   `restore_from_data_dir` (refuse older/newer, open matching and
//!   stampless data, self-stamp on checkpoint).
//! - CLI-driven tests for `xudanu-server upgrade` driving the real
//!   binary: happy path on stampless pre-migration data, idempotent
//!   re-run, refusal of newer data, rollback on migration failure,
//!   and error paths.
//!
//! See docs/dev/FR-82-data-migration.md for the contract under test.

#![cfg(feature = "server")]

use std::path::PathBuf;
use std::process::Command;

fn bin() -> Command {
    // CARGO_BIN_EXTR_* uses underscores: xudanu-server -> xudanu_server.
    let exe = std::env::var("CARGO_BIN_EXTR_xudanu-server")
        .or_else(|_| std::env::var("CARGO_BIN_EXTR_xudanu_server"))
        .unwrap_or_else(|_| {
            let p = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
                .join("../../../target/debug/xudanu-server");
            p.to_string_lossy().into_owned()
        });
    let mut c = Command::new(exe);
    c.stdin(std::process::Stdio::null());
    c
}

/// Fresh parent dir; tests put their data dir INSIDE it so upgrade
/// backups (siblings of the data dir) are contained and assertable.
fn temp_parent(tag: &str) -> PathBuf {
    let dir = std::env::temp_dir().join(format!(
        "xudanu_migration_{}_{}_{}",
        tag,
        std::process::id(),
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_millis()
    ));
    let _ = std::fs::remove_dir_all(&dir);
    std::fs::create_dir_all(&dir).unwrap();
    dir
}

/// Build a data dir through the library: N works + a checkpoint.
fn build_server_data(dir: &std::path::Path, work_count: usize) {
    use xudanu::edition::Edition;
    use xudanu::server::Server;

    let mut server = Server::new();
    server.init_data_dir(dir, None).unwrap();
    let sid = server.connect();
    server.login_public(sid).unwrap();
    for i in 0..work_count {
        server
            .create_work(sid, Edition::from_text(&format!("migration-test {}", i)))
            .unwrap();
    }
    server.checkpoint_to_store().unwrap();
}

/// Write a VERSION sidecar with an arbitrary format version,
/// simulating data written by a different-era binary.
fn write_stamp(dir: &std::path::Path, format_version: u32, server_version: &str) {
    let json = format!(
        "{{\"format_version\":{},\"server_version\":\"{}\",\"upgraded_at\":null}}",
        format_version, server_version
    );
    std::fs::write(dir.join("VERSION"), json).unwrap();
}

fn read_stamp(dir: &std::path::Path) -> Option<xudanu::persist::root_chunk::VersionStamp> {
    xudanu::persist::root_chunk::VersionStamp::read(dir)
}

/// Restore and count works — the "is the data intact" assertion.
fn restored_work_count(dir: &std::path::Path) -> usize {
    let mut server = xudanu::server::Server::new();
    server.restore_from_data_dir(dir, None).unwrap();
    server.work_count()
}

// ── Startup version check (library) ─────────────────────────────────

#[test]
fn startup_opens_data_with_matching_stamp() {
    let parent = temp_parent("open_match");
    let dir = parent.join("data");
    build_server_data(&dir, 2);
    write_stamp(&dir, 1, "1.14.4");

    let mut server = xudanu::server::Server::new();
    server
        .restore_from_data_dir(&dir, None)
        .expect("matching stamp must open");
    assert_eq!(server.work_count(), 2);

    let _ = std::fs::remove_dir_all(&parent);
}

#[test]
fn startup_opens_stampless_pre_migration_data() {
    // v1.14.4-era dirs have no VERSION sidecar: they must open
    // normally (the whole-dir gate arms itself on next checkpoint).
    let parent = temp_parent("open_stampless");
    let dir = parent.join("data");
    build_server_data(&dir, 2);
    std::fs::remove_file(dir.join("VERSION")).ok(); // belt and braces

    let mut server = xudanu::server::Server::new();
    server
        .restore_from_data_dir(&dir, None)
        .expect("stampless data must open");
    assert_eq!(server.work_count(), 2);

    let _ = std::fs::remove_dir_all(&parent);
}

#[test]
fn startup_refuses_data_from_newer_format() {
    let parent = temp_parent("refuse_newer");
    let dir = parent.join("data");
    build_server_data(&dir, 2);
    write_stamp(&dir, 99, "9.0.0-from-the-future");

    let mut server = xudanu::server::Server::new();
    let err = server
        .restore_from_data_dir(&dir, None)
        .expect_err("newer-format data must be refused");
    let msg = err.to_string();
    assert!(msg.contains("DATA FORMAT MISMATCH"), "got: {msg}");
    assert!(msg.contains("format v99"), "got: {msg}");
    assert!(msg.contains("Upgrade xudanu-server"), "got: {msg}");

    let _ = std::fs::remove_dir_all(&parent);
}

#[test]
fn startup_refuses_data_from_older_format() {
    // With auto-migrate the DEFAULT, the plain refusal only appears
    // for opted-out operators — pin the flag so this is deterministic
    // regardless of the global step override other tests inject.
    let _guard = AUTO_MIGRATE_TEST_MUTEX
        .lock()
        .unwrap_or_else(|p| p.into_inner());
    xudanu::server::upgrade::set_no_auto_migrate(true);

    let parent = temp_parent("refuse_older");
    let dir = parent.join("data");
    build_server_data(&dir, 2);
    write_stamp(&dir, 0, "0.0.1-ancient");

    let mut server = xudanu::server::Server::new();
    let err = server
        .restore_from_data_dir(&dir, None)
        .expect_err("older-format data must be refused when opted out");
    let msg = err.to_string();
    assert!(msg.contains("DATA FORMAT UPGRADE NEEDED"), "got: {msg}");
    assert!(msg.contains("xudanu-server upgrade"), "got: {msg}");

    xudanu::server::upgrade::set_no_auto_migrate(false);
    let _ = std::fs::remove_dir_all(&parent);
}

#[test]
fn corrupt_stamp_degrades_to_stampless_and_self_stamps() {
    // A torn VERSION write must not wedge the server: treat as
    // stampless, open, and re-stamp on the next checkpoint.
    let parent = temp_parent("corrupt_stamp");
    let dir = parent.join("data");
    build_server_data(&dir, 1);
    std::fs::write(dir.join("VERSION"), "{torn write").unwrap();

    let mut server = xudanu::server::Server::new();
    server
        .restore_from_data_dir(&dir, None)
        .expect("corrupt stamp must degrade to stampless");
    server.checkpoint_to_store().unwrap();

    let stamp = read_stamp(&dir).expect("checkpoint re-stamps");
    assert_eq!(stamp.format_version, 1);
    assert!(!stamp.server_version.is_empty());

    let _ = std::fs::remove_dir_all(&parent);
}

#[test]
fn checkpoint_restamps_stampless_data() {
    let parent = temp_parent("restamp");
    let dir = parent.join("data");
    build_server_data(&dir, 1);
    std::fs::remove_file(dir.join("VERSION")).unwrap();

    let mut server = xudanu::server::Server::new();
    server.restore_from_data_dir(&dir, None).unwrap();
    assert!(read_stamp(&dir).is_none(), "restore alone must not stamp");
    server.checkpoint_to_store().unwrap();

    let stamp = read_stamp(&dir).expect("sync checkpoint writes VERSION");
    assert_eq!(stamp.format_version, 1);

    let _ = std::fs::remove_dir_all(&parent);
}

// ── Upgrade command (CLI) ───────────────────────────────────────────

#[test]
fn upgrade_stampless_pre_migration_dir_stamps_baseline() {
    // THE v1.14.4 upgrade path: no sidecar, real data. Upgrade must
    // recognize it as baseline format v1 (matching the current
    // binary → idempotent path) and stamp it — not fail with a
    // rollback (the NoStep(0) bug this test guards). The backup →
    // migrate → verify path becomes reachable when format v2 lands.
    let parent = temp_parent("cli_stampless");
    let dir = parent.join("data");
    build_server_data(&dir, 3);
    std::fs::remove_file(dir.join("VERSION")).unwrap();

    let out = bin().arg("upgrade").arg(&dir).output().unwrap();
    let stdout = String::from_utf8_lossy(&out.stdout);
    let stderr = String::from_utf8_lossy(&out.stderr);
    assert!(out.status.success(), "stdout: {stdout}\nstderr: {stderr}");
    assert!(
        stdout.contains("Already at format"),
        "stampless v1-era data is baseline: {stdout}"
    );

    let stamp = read_stamp(&dir).expect("stamped after upgrade");
    assert_eq!(stamp.format_version, 1);
    assert!(stamp.upgraded_at.is_some(), "upgrade sets upgraded_at");
    // And the now-stamped data opens normally.
    assert_eq!(restored_work_count(&dir), 3, "data intact after upgrade");

    let _ = std::fs::remove_dir_all(&parent);
}

#[test]
fn upgrade_current_data_is_idempotent() {
    let parent = temp_parent("cli_idempotent");
    let dir = parent.join("data");
    build_server_data(&dir, 2);

    let first = bin().arg("upgrade").arg(&dir).output().unwrap();
    assert!(
        first.status.success(),
        "first upgrade: {}",
        String::from_utf8_lossy(&first.stderr)
    );

    let second = bin().arg("upgrade").arg(&dir).output().unwrap();
    let stdout = String::from_utf8_lossy(&second.stdout);
    assert!(
        second.status.success(),
        "second upgrade must succeed: {stdout}"
    );
    assert!(
        stdout.contains("Already at format"),
        "second run reports no-op: {stdout}"
    );
    // Idempotent run must NOT leave a backup behind.
    let backups: Vec<_> = std::fs::read_dir(&parent)
        .unwrap()
        .filter_map(|e| e.ok())
        .filter(|e| e.file_name().to_string_lossy().starts_with("backup-"))
        .collect();
    assert!(
        backups.is_empty(),
        "idempotent upgrade must not create backups"
    );
    assert_eq!(restored_work_count(&dir), 2);

    let _ = std::fs::remove_dir_all(&parent);
}

#[test]
fn upgrade_refuses_data_newer_than_binary() {
    let parent = temp_parent("cli_newer");
    let dir = parent.join("data");
    build_server_data(&dir, 2);
    write_stamp(&dir, 42, "9.9.9");

    let out = bin().arg("upgrade").arg(&dir).output().unwrap();
    let stderr = String::from_utf8_lossy(&out.stderr);
    assert!(!out.status.success(), "must exit non-zero");
    assert!(
        stderr.contains("Upgrade xudanu-server first"),
        "stderr: {stderr}"
    );
    // No backup, no touch: the stamp is unchanged, and dropping the
    // (bogus) stamp reveals the underlying data is intact.
    let stamp = read_stamp(&dir).unwrap();
    assert_eq!(stamp.format_version, 42, "stamp untouched");
    std::fs::remove_file(dir.join("VERSION")).unwrap();
    assert_eq!(restored_work_count(&dir), 2);

    let _ = std::fs::remove_dir_all(&parent);
}

#[test]
fn upgrade_rolls_back_on_migration_failure() {
    // An explicit format-0 stamp takes the migration path; no step
    // is registered from 0, so the step fails and the upgrade must
    // roll back from the backup leaving the original data intact.
    let parent = temp_parent("cli_rollback");
    let dir = parent.join("data");
    build_server_data(&dir, 2);
    write_stamp(&dir, 0, "0.0.1-ancient");

    let out = bin().arg("upgrade").arg(&dir).output().unwrap();
    let stderr = String::from_utf8_lossy(&out.stderr);
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert!(!out.status.success(), "must exit non-zero");
    assert!(stderr.contains("Rollback complete"), "stderr: {stderr}");
    assert!(
        stderr.contains("no migration step") || stdout.contains("no migration step"),
        "stderr: {stderr}\nstdout: {stdout}"
    );

    // Original data intact and the backup consumed by the rollback.
    let stamp = read_stamp(&dir).unwrap();
    assert_eq!(stamp.format_version, 0, "stamp not advanced");
    std::fs::remove_file(dir.join("VERSION")).unwrap();
    assert_eq!(restored_work_count(&dir), 2, "rolled-back data intact");
    let backups: Vec<_> = std::fs::read_dir(&parent)
        .unwrap()
        .filter_map(|e| e.ok())
        .filter(|e| e.file_name().to_string_lossy().starts_with("backup-"))
        .collect();
    assert!(
        backups.is_empty(),
        "rollback consumes the backup (renamed back)"
    );

    let _ = std::fs::remove_dir_all(&parent);
}

#[test]
fn upgrade_non_data_dir_fails_closed() {
    // A directory with no xudanu artifacts (which init_tracing may
    // have just materialized for a typo'd path) must be rejected
    // with a clear message, never migrated (FR-82 guarantee 5).
    let parent = temp_parent("cli_unknown");
    let dir = parent.join("data");
    std::fs::create_dir_all(&dir).unwrap();
    std::fs::write(dir.join("stray.txt"), "not a xudanu data dir").unwrap();

    let out = bin().arg("upgrade").arg(&dir).output().unwrap();
    let stderr = String::from_utf8_lossy(&out.stderr);
    assert!(!out.status.success(), "must exit non-zero");
    assert!(
        stderr.contains("not a xudanu data directory"),
        "stderr: {stderr}"
    );
    // No backup was created for a rejected dir.
    let backups: Vec<_> = std::fs::read_dir(&parent)
        .unwrap()
        .filter_map(|e| e.ok())
        .filter(|e| e.file_name().to_string_lossy().starts_with("backup-"))
        .collect();
    assert!(backups.is_empty());

    let _ = std::fs::remove_dir_all(&parent);
}

#[test]
fn upgrade_nonexistent_dir_errors() {
    let parent = temp_parent("cli_missing");
    let dir = parent.join("never-existed");

    let out = bin().arg("upgrade").arg(&dir).output().unwrap();
    let stderr = String::from_utf8_lossy(&out.stderr);
    assert!(!out.status.success(), "must exit non-zero");
    assert!(
        stderr.contains("not a xudanu data directory"),
        "stderr: {stderr}"
    );

    let _ = std::fs::remove_dir_all(&parent);
}

#[test]
fn upgrade_output_shows_versions_and_baseline() {
    let parent = temp_parent("cli_output");
    let dir = parent.join("data");
    build_server_data(&dir, 4);

    let out = bin().arg("upgrade").arg(&dir).output().unwrap();
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert!(out.status.success(), "stdout: {stdout}");
    assert!(stdout.contains("Data version:"), "stdout: {stdout}");
    assert!(stdout.contains("binary:"), "stdout: {stdout}");
    // Current data (stamped v1 by the build's checkpoint) takes the
    // idempotent path; the migrate/verify output appears at v2.
    assert!(stdout.contains("Already at format"), "stdout: {stdout}");

    let _ = std::fs::remove_dir_all(&parent);
}

// ── Multi-revision chains (the away-for-6-months path) ──────────────
//
// A user returning after several format bumps must migrate through
// every intermediate revision in order. The production registry has
// no steps yet (v1 is baseline), so these tests drive custom chains
// through the same walker the upgrade command uses
// (apply_steps_with), over REAL server data dirs, and prove the
// version-gate interplay afterward.

use xudanu::persist::migrations::{apply_steps_with, MigrationStep};

fn marker_step(from: u32, to: u32, marker: &'static str) -> MigrationStep {
    // fn pointers can't capture; one arm per marker used below.
    fn append(
        dir: &std::path::Path,
        line: &str,
    ) -> Result<(), xudanu::persist::migrations::MigrationError> {
        use std::io::Write;
        use xudanu::persist::migrations::MigrationError;
        let mut f = std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(dir.join("migration-log"))
            .map_err(MigrationError::Io)?;
        writeln!(f, "{}", line).map_err(MigrationError::Io)?;
        Ok(())
    }
    let transform: fn(&std::path::Path) -> Result<(), xudanu::persist::migrations::MigrationError> =
        match marker {
            "v0-to-v1" => |dir| append(dir, "v0-to-v1"),
            "v1-to-v2" => |dir| append(dir, "v1-to-v2"),
            "v2-to-v3" => |dir| append(dir, "v2-to-v3"),
            "v3-to-v4" => |dir| append(dir, "v3-to-v4"),
            _ => unreachable!("unknown marker"),
        };
    MigrationStep {
        from_format: from,
        to_format: to,
        description: marker,
        transform,
    }
}

#[test]
fn multi_revision_chain_migrates_real_data_in_order() {
    let parent = temp_parent("chain_real");
    let dir = parent.join("data");
    build_server_data(&dir, 3);

    // Data at v1; a binary three formats ahead needs all three steps.
    let steps = vec![
        marker_step(1, 2, "v1-to-v2"),
        marker_step(2, 3, "v2-to-v3"),
        marker_step(3, 4, "v3-to-v4"),
    ];
    let applied = apply_steps_with(&dir, 1, 4, &steps).unwrap();
    assert_eq!(applied, 3);
    assert_eq!(
        std::fs::read_to_string(dir.join("migration-log")).unwrap(),
        "v1-to-v2\nv2-to-v3\nv3-to-v4\n",
        "every intermediate revision runs, in order"
    );

    // The migrated data dir is still fully restorable.
    assert_eq!(restored_work_count(&dir), 3, "real data survives the chain");

    let _ = std::fs::remove_dir_all(&parent);
}

#[test]
fn multi_revision_chain_from_middle_skips_done_steps() {
    // Returning user at v2 (migrated once, gone away again): only
    // the steps ahead of v2 may run — re-running old steps could
    // corrupt data that v2→v3 expects to transform.
    let parent = temp_parent("chain_middle");
    let dir = parent.join("data");
    build_server_data(&dir, 2);

    let steps = vec![
        marker_step(1, 2, "v1-to-v2"),
        marker_step(2, 3, "v2-to-v3"),
        marker_step(3, 4, "v3-to-v4"),
    ];
    let applied = apply_steps_with(&dir, 2, 4, &steps).unwrap();
    assert_eq!(applied, 2);
    assert_eq!(
        std::fs::read_to_string(dir.join("migration-log")).unwrap(),
        "v2-to-v3\nv3-to-v4\n",
        "already-applied revisions never re-run"
    );
    assert_eq!(restored_work_count(&dir), 2);

    let _ = std::fs::remove_dir_all(&parent);
}

#[test]
fn multi_revision_gap_fails_closed_on_real_data() {
    // A registry with a missing intermediate step must refuse —
    // guessing would corrupt. The upgrade command rolls back from
    // its backup in this case.
    let parent = temp_parent("chain_gap");
    let dir = parent.join("data");
    build_server_data(&dir, 2);

    let steps = vec![marker_step(1, 2, "v1-to-v2"), marker_step(3, 4, "v3-to-v4")];
    let err = apply_steps_with(&dir, 1, 4, &steps).unwrap_err();
    assert!(
        err.to_string().contains("no migration step from version 2"),
        "got: {err}"
    );
    // The step before the gap ran; the one after it did not.
    assert_eq!(
        std::fs::read_to_string(dir.join("migration-log")).unwrap(),
        "v1-to-v2\n"
    );
    // Data untouched by the never-run step.
    assert_eq!(restored_work_count(&dir), 2);

    let _ = std::fs::remove_dir_all(&parent);
}

#[test]
fn multi_revision_stamp_after_chain_gates_startup() {
    // The full interplay: migrate a real dir through a custom chain,
    // stamp the result at the chain's target, and confirm the
    // version gate treats it exactly like native future data (an
    // older binary refuses; matching opens).
    let parent = temp_parent("chain_gate");
    let dir = parent.join("data");
    build_server_data(&dir, 2);

    let steps = vec![marker_step(1, 2, "v1-to-v2"), marker_step(2, 3, "v2-to-v3")];
    apply_steps_with(&dir, 1, 3, &steps).unwrap();

    // Stamp at the migrated target (what upgrade does post-verify).
    write_stamp(&dir, 3, "2.0.0");
    let mut older = xudanu::server::Server::new(); // this binary: format v1
    let err = older
        .restore_from_data_dir(&dir, None)
        .expect_err("older binary must refuse format v3 data");
    assert!(
        err.to_string().contains("DATA FORMAT MISMATCH"),
        "got: {err}"
    );

    let _ = std::fs::remove_dir_all(&parent);
}

// ── Startup auto-migration (FR-82 default) ──────────────────────────
//
// The startup gate runs the same pipeline as `xudanu-server
// upgrade` when data is OLDER than the binary; NEWER data always
// refuses; --no-auto-migrate / XUDANU_NO_AUTO_MIGRATE restores the
// refuse-and-instruct behavior. Tests inject a step chain via the
// override hook (the production registry has no steps while v1 is
// baseline), serialized by a mutex because the override is global.

static AUTO_MIGRATE_TEST_MUTEX: std::sync::Mutex<()> = std::sync::Mutex::new(());

#[test]
fn startup_auto_migrates_older_data_through_the_chain() {
    let _guard = AUTO_MIGRATE_TEST_MUTEX.lock().unwrap();
    xudanu::server::upgrade::set_step_override(Some(vec![marker_step(0, 1, "v0-to-v1")]));

    let parent = temp_parent("auto_migrate");
    let dir = parent.join("data");
    build_server_data(&dir, 3);
    write_stamp(&dir, 0, "0.0.1-ancient"); // older than binary format v1

    // Starting against older data migrates it, then boots.
    let mut server = xudanu::server::Server::new();
    server
        .restore_from_data_dir(&dir, None)
        .expect("auto-migration must let the server boot");
    assert_eq!(server.work_count(), 3, "works survive auto-migration");

    // The chain ran (marker file) and the stamp advanced.
    assert_eq!(
        std::fs::read_to_string(dir.join("migration-log")).unwrap(),
        "v0-to-v1\n"
    );
    let stamp = read_stamp(&dir).expect("stamped after auto-migration");
    assert_eq!(stamp.format_version, 1);
    // The migration lock was released.
    assert!(!dir.join("MIGRATION.lock").exists(), "lock released");

    xudanu::server::upgrade::set_step_override(None);
    let _ = std::fs::remove_dir_all(&parent);
}

#[test]
fn startup_auto_migrate_failure_rolls_back_and_refuses_to_boot() {
    let _guard = AUTO_MIGRATE_TEST_MUTEX.lock().unwrap();
    // A chain with a gap from v0: migration must fail, roll back,
    // and the boot must refuse with a clear error.
    xudanu::server::upgrade::set_step_override(Some(vec![marker_step(1, 2, "v1-to-v2")]));

    let parent = temp_parent("auto_fail");
    let dir = parent.join("data");
    build_server_data(&dir, 2);
    write_stamp(&dir, 0, "0.0.1-ancient");

    let mut server = xudanu::server::Server::new();
    let err = server
        .restore_from_data_dir(&dir, None)
        .expect_err("failed migration must refuse to boot");
    let msg = err.to_string();
    assert!(msg.contains("AUTO-MIGRATION FAILED"), "got: {msg}");
    assert!(msg.contains("no migration step"), "got: {msg}");

    // Rolled back: stamp still v0, data intact, backup consumed.
    assert_eq!(read_stamp(&dir).unwrap().format_version, 0);
    std::fs::remove_file(dir.join("VERSION")).unwrap();
    assert_eq!(restored_work_count(&dir), 2);
    let backups: Vec<_> = std::fs::read_dir(&parent)
        .unwrap()
        .filter_map(|e| e.ok())
        .filter(|e| e.file_name().to_string_lossy().starts_with("backup-"))
        .collect();
    assert!(backups.is_empty(), "rollback consumed the backup");

    xudanu::server::upgrade::set_step_override(None);
    let _ = std::fs::remove_dir_all(&parent);
}

#[test]
fn startup_no_auto_migrate_flag_refuses_with_instructions() {
    let _guard = AUTO_MIGRATE_TEST_MUTEX.lock().unwrap();
    xudanu::server::upgrade::set_step_override(Some(vec![marker_step(0, 1, "v0-to-v1")]));
    xudanu::server::upgrade::set_no_auto_migrate(true);

    let parent = temp_parent("no_auto");
    let dir = parent.join("data");
    build_server_data(&dir, 2);
    write_stamp(&dir, 0, "0.0.1-ancient");

    let mut server = xudanu::server::Server::new();
    let err = server
        .restore_from_data_dir(&dir, None)
        .expect_err("opted-out startup must refuse older data");
    let msg = err.to_string();
    assert!(msg.contains("DATA FORMAT UPGRADE NEEDED"), "got: {msg}");
    assert!(msg.contains("xudanu-server upgrade"), "got: {msg}");
    // Nothing ran: no migration log, stamp untouched.
    assert!(!dir.join("migration-log").exists());
    assert_eq!(read_stamp(&dir).unwrap().format_version, 0);

    xudanu::server::upgrade::set_no_auto_migrate(false);
    xudanu::server::upgrade::set_step_override(None);
    let _ = std::fs::remove_dir_all(&parent);
}

#[test]
fn startup_auto_migrate_respects_concurrent_lock() {
    let _guard = AUTO_MIGRATE_TEST_MUTEX.lock().unwrap();
    xudanu::server::upgrade::set_step_override(Some(vec![marker_step(0, 1, "v0-to-v1")]));

    let parent = temp_parent("auto_lock");
    let dir = parent.join("data");
    build_server_data(&dir, 2);
    write_stamp(&dir, 0, "0.0.1-ancient");
    // Simulate a live concurrent migration: our own PID holds the
    // lock (a dead PID would be stolen).
    std::fs::write(dir.join("MIGRATION.lock"), std::process::id().to_string()).unwrap();

    let mut server = xudanu::server::Server::new();
    let err = server
        .restore_from_data_dir(&dir, None)
        .expect_err("live lock must block auto-migration");
    assert!(
        err.to_string().contains("AUTO-MIGRATION FAILED"),
        "got: {err}"
    );

    xudanu::server::upgrade::set_step_override(None);
    let _ = std::fs::remove_dir_all(&parent);
}
