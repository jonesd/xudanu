//! Deterministic data-loss checks.
//!
//! The contract under test: **acked ⇒ present after recovery** — for
//! every state-changing operation class, in the three ways state can
//! be lost:
//!
//! (a) crash before any checkpoint — WAL replay is the only recovery
//! (b) checkpoint, then restart — manifest is the only recovery
//! (c) checkpoint, then MORE mutations, then crash — manifest plus
//!     post-checkpoint WAL replay
//!
//! A failure here is a data-loss bug by definition: the server
//! acknowledged an operation that did not survive.

#![cfg(feature = "server")]

use xudanu::edition::Edition;
use xudanu::edition::License;
use xudanu::server::server::Server;

use xudanu::server::session::SessionId;

fn fresh_dir(name: &str) -> std::path::PathBuf {
    let dir = std::env::temp_dir().join(format!(
        "xudanu_durability_{}_{}_{}",
        name,
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

fn start(name: &str) -> (Server, std::path::PathBuf, SessionId) {
    let dir = fresh_dir(name);
    let mut server = Server::new();
    server.init_data_dir(&dir, None).unwrap();
    let sid = server.connect();
    server.login_public(sid).unwrap();
    (server, dir, sid)
}

/// Simulated crash: drop the server with NO shutdown checkpoint.
/// Recovery must come from WAL (+ last checkpoint if any).
fn crash_restore(dir: &std::path::Path) -> (Server, SessionId) {
    let mut server = Server::new();
    server.restore_from_data_dir(dir, None).unwrap();
    let sid = server.connect();
    server.login_public(sid).unwrap();
    (server, sid)
}

fn make_work(server: &mut Server, sid: SessionId, text: &str) -> u64 {
    server.create_work(sid, Edition::from_text(text)).unwrap()
}

// ── (a) crash before checkpoint ───────────────────────────────────

#[test]
fn work_create_survives_crash_before_checkpoint() {
    let (mut server, dir, sid) = start("work_create_crash");
    let w = make_work(&mut server, sid, "durable?");
    drop(server);
    let (mut s2, sid2) = crash_restore(&dir);
    assert!(
        s2.work_revision_count(w).is_ok(),
        "created work missing after crash (WAL replay)"
    );
    assert!(
        s2.work_is_published(sid2, w).is_ok(),
        "created work not readable after crash"
    );
    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn work_publish_survives_crash_before_checkpoint() {
    let (mut server, dir, sid) = start("publish_crash");
    let w = make_work(&mut server, sid, "publish me");
    server.work_publish(sid, w).unwrap();
    drop(server);
    let (mut s2, sid2) = crash_restore(&dir);
    assert!(
        s2.work_is_published(sid2, w).unwrap(),
        "publish lost on crash"
    );
    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn work_star_survives_crash_before_checkpoint() {
    let (mut server, dir, sid) = start("star_crash");
    let w = make_work(&mut server, sid, "star me");
    server.work_star(sid, w).unwrap();
    drop(server);
    let (mut s2, sid2) = crash_restore(&dir);
    assert!(s2.work_is_starred(sid2, w).unwrap(), "star lost on crash");
    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn work_license_survives_crash_before_checkpoint() {
    let (mut server, dir, _sid) = start("license_crash");
    let w = make_work(&mut server, _sid, "license me");
    server
        .work_license_set(w, License::AllRightsReserved)
        .unwrap();
    drop(server);
    let (mut s2, _sid2) = crash_restore(&dir);
    assert_eq!(s2.work_license_get(w).unwrap(), License::AllRightsReserved);
    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn trail_create_and_stop_survive_crash_before_checkpoint() {
    let (mut server, dir, sid) = start("trail_crash");
    let w = make_work(&mut server, sid, "a stop target");
    let t = server
        .trail_create(sid, "Durable Trail".into(), Some("intro".into()), vec![])
        .unwrap();
    server
        .trail_add_stop(sid, t, w, Some(0), Some(2), Some("note".into()), None)
        .unwrap();
    drop(server);
    let (mut s2, sid2) = crash_restore(&dir);
    let trails = s2.trail_list(sid2).unwrap();
    assert!(
        trails.iter().any(|t| t.name == "Durable Trail"),
        "trail lost on crash: {:?}",
        trails
    );
    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn trail_publish_survives_crash_before_checkpoint() {
    let (mut server, dir, sid) = start("trail_publish_crash");
    let t = server
        .trail_create(sid, "Publish Me".into(), None, vec![])
        .unwrap();
    server.trail_publish(sid, t).unwrap();
    drop(server);
    let (mut s2, _sid2) = crash_restore(&dir);
    let published = s2.trail_list_published(_sid2, None).unwrap();
    assert!(
        published.iter().any(|p| p.name == "Publish Me"),
        "trail publish lost on crash — WAL does not cover trail_publish"
    );
    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn trail_delete_survives_crash_before_checkpoint() {
    let (mut server, dir, sid) = start("trail_delete_crash");
    let t = server
        .trail_create(sid, "Doomed".into(), None, vec![])
        .unwrap();
    server.trail_delete(sid, t).unwrap();
    drop(server);
    let (mut s2, sid2) = crash_restore(&dir);
    let trails = s2.trail_list(sid2).unwrap();
    assert!(
        !trails.iter().any(|x| x.name == "Doomed"),
        "deleted trail resurrected on crash"
    );
    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn link_and_endorsement_survive_crash_before_checkpoint() {
    let (mut server, dir, sid) = start("link_crash");
    let a = make_work(&mut server, sid, "origin doc");
    let b = make_work(&mut server, sid, "destination doc");
    let link = server.create_link(sid, a, b, None, None).unwrap();
    server.link_endorse(sid, link).unwrap();
    drop(server);
    let (mut s2, sid2) = crash_restore(&dir);
    let endorsements = s2.link_endorsements(link).unwrap();
    assert!(!endorsements.is_empty(), "link endorsement lost on crash");
    let _ = std::fs::remove_dir_all(&dir);
}

// ── (b) checkpoint, then restart ──────────────────────────────────

#[test]
fn trails_survive_checkpoint_and_restart() {
    let (mut server, dir, sid) = start("trail_ckpt");
    let w = make_work(&mut server, sid, "stop target");
    let t = server
        .trail_create(sid, "Checkpointed".into(), None, vec![])
        .unwrap();
    server
        .trail_add_stop(sid, t, w, None, None, Some("stop".into()), None)
        .unwrap();
    server.trail_publish(sid, t).unwrap();
    server.checkpoint_to_store().unwrap();
    drop(server);
    let (mut s2, _sid2) = crash_restore(&dir);
    let published = s2.trail_list_published(_sid2, None).unwrap();
    assert!(
        published.iter().any(|p| p.name == "Checkpointed"),
        "trail lost across checkpoint+restart"
    );
    let _ = std::fs::remove_dir_all(&dir);
}

// ── (c) checkpoint, then more mutations, then crash ───────────────

#[test]
fn post_checkpoint_trail_mutations_survive_crash() {
    let (mut server, dir, sid) = start("trail_post_ckpt");
    let w1 = make_work(&mut server, sid, "first");
    let t = server
        .trail_create(sid, "Growing".into(), None, vec![])
        .unwrap();
    server
        .trail_add_stop(sid, t, w1, None, None, None, None)
        .unwrap();
    server.checkpoint_to_store().unwrap();

    // Post-checkpoint mutations: only the WAL can save these.
    let w2 = make_work(&mut server, sid, "second");
    server
        .trail_add_stop(sid, t, w2, None, None, Some("added later".into()), None)
        .unwrap();
    server.trail_publish(sid, t).unwrap();
    drop(server);

    let (mut s2, sid2) = crash_restore(&dir);
    let trails = s2.trail_list(sid2).unwrap();
    let found = trails.iter().find(|x| x.name == "Growing");
    assert!(found.is_some(), "trail lost after post-checkpoint crash");
    let stops = found.map(|x| x.stops.clone()).unwrap_or_default();
    assert_eq!(stops.len(), 2, "post-checkpoint stop lost: {:?}", stops);
    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn repro_star_across_checkpoint_crash() {
    let (mut server, dir, sid) = start("repro_star");
    let w = make_work(&mut server, sid, "target");
    server.work_star(sid, w).unwrap();
    server.checkpoint_to_store().unwrap();
    let _w2 = make_work(&mut server, sid, "after ckpt");
    drop(server);
    let (mut s2, sid2) = crash_restore(&dir);
    let starred = s2.work_is_starred(sid2, w).unwrap_or(false);
    println!("starred after ckpt+crash: {}", starred);
    assert!(starred, "STAR LOST across checkpoint+crash");
    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn repro_trail_across_checkpoint_crash() {
    let (mut server, dir, sid) = start("repro_trail");
    let _w = make_work(&mut server, sid, "t");
    let t = server
        .trail_create(sid, "Repro Trail".into(), None, vec![])
        .unwrap();
    server.checkpoint_to_store().unwrap();
    let _w2 = make_work(&mut server, sid, "after ckpt");
    drop(server);
    let (mut s2, sid2) = crash_restore(&dir);
    let trails = s2.trail_list(sid2).unwrap();
    println!(
        "trails after ckpt+crash: {:?}",
        trails.iter().map(|x| x.name.clone()).collect::<Vec<_>>()
    );
    assert!(
        trails.iter().any(|x| x.trail_id == t),
        "TRAIL LOST across checkpoint+crash"
    );
    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn writer_gate_refuses_foreign_and_passes_legacy() {
    use xudanu::persist::manifest::Manifest;
    let mut m = Manifest::empty_for_tests();
    m.writer_tag = Some("deadbeef-release".to_string());
    std::env::remove_var("XUDANU_ALLOW_FOREIGN_WRITER");
    assert!(
        m.check_writer_gate(env!("XUDANU_WRITER_TAG")).is_err(),
        "foreign writer must be refused"
    );
    std::env::set_var("XUDANU_ALLOW_FOREIGN_WRITER", "1");
    assert!(
        m.check_writer_gate(env!("XUDANU_WRITER_TAG")).is_ok(),
        "foreign writer with override must pass"
    );
    std::env::remove_var("XUDANU_ALLOW_FOREIGN_WRITER");
    m.writer_tag = Some(env!("XUDANU_WRITER_TAG").to_string());
    assert!(
        m.check_writer_gate(env!("XUDANU_WRITER_TAG")).is_ok(),
        "same writer must pass"
    );
    m.writer_tag = None;
    assert!(
        m.check_writer_gate(env!("XUDANU_WRITER_TAG")).is_ok(),
        "legacy manifest must pass with warning"
    );
}

#[test]
fn work_kind_survives_crash_before_checkpoint() {
    let (mut server, dir, _sid) = start("kind_crash");
    let w = make_work(&mut server, _sid, "kind target");
    use xudanu::edition::WorkKind;
    server.work_kind_set(w, WorkKind::Note).unwrap();
    drop(server);
    let (mut s2, _s) = crash_restore(&dir);
    assert_eq!(s2.work_kind_get(w).unwrap(), WorkKind::Note);
    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn work_title_survives_crash_before_checkpoint() {
    let (mut server, dir, _sid) = start("title_crash");
    let w = make_work(&mut server, _sid, "titled");
    server.set_work_title(w, "An Explicit Title".into());
    drop(server);
    let (mut s2, _s) = crash_restore(&dir);
    let title = s2
        .list_works_with_titles()
        .into_iter()
        .find(|(id, ..)| *id == w)
        .map(|x| x.4)
        .unwrap_or_default();
    assert_eq!(title, "An Explicit Title");
    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn work_archive_survives_crash_before_checkpoint() {
    let (mut server, dir, sid) = start("archive_crash");
    let w = make_work(&mut server, sid, "to archive");
    server.work_archive(sid, w).unwrap();
    drop(server);
    let (mut s2, _s) = crash_restore(&dir);
    assert!(s2.work_is_archived(w).unwrap(), "archive lost on crash");
    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn annotation_survives_crash_before_checkpoint() {
    let (mut server, dir, sid) = start("annot_crash");
    let w = make_work(&mut server, sid, "annotated");
    server
        .annotation_create(sid, w, 7, "note".into(), "a note".into(), 0, 1, false)
        .unwrap();
    drop(server);
    let (mut s2, sid2) = crash_restore(&dir);
    let list = s2.annotation_list(sid2, w).unwrap();
    assert!(
        list.iter().any(|a| a.annotation_id == 7),
        "annotation lost on crash"
    );
    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn trail_rename_survives_crash_before_checkpoint() {
    let (mut server, dir, sid) = start("rename_crash");
    let t = server
        .trail_create(sid, "Before".into(), None, vec![])
        .unwrap();
    server.trail_rename(sid, t, "After".into()).unwrap();
    drop(server);
    let (mut s2, sid2) = crash_restore(&dir);
    let trails = s2.trail_list(sid2).unwrap();
    assert!(
        trails.iter().any(|x| x.trail_id == t && x.name == "After"),
        "trail rename lost on crash"
    );
    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn sidecar_resurrects_trail_lost_from_wal_and_manifest() {
    let (mut server, dir, sid) = start("sidecar_rescue");
    let w = make_work(&mut server, sid, "stop");
    let t = server
        .trail_create(sid, "Sidecar Rescue".into(), None, vec![])
        .unwrap();
    server
        .trail_add_stop(sid, t, w, None, None, Some("s".into()), None)
        .unwrap();
    drop(server);
    let _ = std::fs::remove_file(dir.join("wal.log"));
    let (mut s2, sid2) = crash_restore(&dir);
    let trails = s2.trail_list(sid2).unwrap();
    assert!(
        trails
            .iter()
            .any(|x| x.trail_id == t && x.name == "Sidecar Rescue"),
        "sidecar failed to resurrect trail lost from WAL+manifest"
    );
    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn sidecar_merge_never_drops_manifest_trails() {
    let (mut server, dir, sid) = start("sidecar_merge");
    let t_manifest_only = server
        .trail_create(sid, "Manifest Only".into(), None, vec![])
        .unwrap();
    drop(server);
    let sidecar = serde_json::json!({
        "trail_counter": 1,
        "trails": []
    });
    std::fs::write(dir.join("trails.json"), sidecar.to_string()).unwrap();
    let (mut s2, sid2) = crash_restore(&dir);
    let trails = s2.trail_list(sid2).unwrap();
    assert!(
        trails.iter().any(|x| x.trail_id == t_manifest_only),
        "sidecar merge dropped a manifest-restored trail"
    );
    let _ = std::fs::remove_dir_all(&dir);
}
