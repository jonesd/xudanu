//! Chaos harness for durability: seeded, model-checked random
//! sequences of mutations interrupted by random failures.
//!
//! The invariant is the persistence contract: every operation that
//! returned Ok before an interruption must be visible after
//! recovery. Interruptions include hard crashes (drop, no
//! checkpoint), checkpoints, torn final WAL entries, and a
//! corrupted byte in the final WAL entry. Only the FINAL entry may
//! be damaged — earlier entries were fsync'd before their acks, so
//! a real crash cannot affect them.
//!
//! Reproduce a failure with the printed seed:
//!   XUDANU_CHAOS_SEED=12345 cargo test --features server \
//!     --test durability_chaos -- --ignored --nocapture

#![cfg(feature = "server")]

use xudanu::edition::Edition;
use xudanu::edition::License;
use xudanu::server::server::Server;
use xudanu::server::session::SessionId;

struct Rng(u64);

impl Rng {
    fn next(&mut self) -> u64 {
        let mut x = self.0;
        x ^= x >> 12;
        x ^= x << 25;
        x ^= x >> 27;
        self.0 = x;
        x.wrapping_mul(0x2545F4914F6CDD1D)
    }
    fn below(&mut self, n: u64) -> u64 {
        self.next() % n
    }
}

#[derive(Clone, Debug, PartialEq)]
enum Fact {
    WorkExists(u64),
    WorkPublished(u64),
    WorkLicensed(u64, License),
    WorkStarred(u64),
    TrailExists(u64, String),
    TrailPublished(String),
    TrailStops(u64, usize),
    WorkKindIs(u64, xudanu::edition::WorkKind),
    WorkTitle(u64, String),
    WorkArchived(u64),
    WorkNotArchived(u64),
    Annotation(u64, u64),
    LinkGone(u64),
}

fn fresh_dir(seed: u64) -> std::path::PathBuf {
    let dir = std::env::temp_dir().join(format!(
        "xudanu_chaos_{}_{}_{}",
        seed,
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

fn restore(dir: &std::path::Path) -> (Server, SessionId) {
    let mut s = Server::new();
    s.restore_from_data_dir(dir, None).unwrap();
    let sid = s.connect();
    s.login_public(sid).unwrap();
    (s, sid)
}

fn verify(s: &mut Server, sid: SessionId, facts: &[Fact]) -> Result<(), String> {
    for f in facts {
        match f {
            Fact::WorkExists(w) => {
                if s.work_revision_count(*w).is_err() {
                    return Err(format!("work {} missing", w));
                }
            }
            Fact::WorkPublished(w) => {
                if !s.work_is_published(sid, *w).unwrap_or(false) {
                    return Err(format!("work {} lost published state", w));
                }
            }
            Fact::WorkLicensed(w, l) => {
                if s.work_license_get(*w).unwrap_or(License::Transcopyright) != *l {
                    return Err(format!("work {} lost license {:?}", w, l));
                }
            }
            Fact::WorkStarred(w) => {
                if !s.work_is_starred(sid, *w).unwrap_or(false) {
                    return Err(format!("work {} lost star", w));
                }
            }
            Fact::TrailExists(t, name) => {
                let ok = s
                    .trail_list(sid)
                    .map(|ts| ts.iter().any(|x| x.trail_id == *t && x.name == *name))
                    .unwrap_or(false);
                if !ok {
                    return Err(format!("trail {} ({}) missing", t, name));
                }
            }
            Fact::TrailPublished(name) => {
                let ok = s
                    .trail_list_published(sid, None)
                    .map(|ts| ts.iter().any(|x| x.name == *name))
                    .unwrap_or(false);
                if !ok {
                    return Err(format!("trail {} lost published state", name));
                }
            }
            Fact::TrailStops(t, n) => {
                let got = s
                    .trail_list(sid)
                    .ok()
                    .and_then(|ts| ts.iter().find(|x| x.trail_id == *t).map(|x| x.stops.len()))
                    .unwrap_or(usize::MAX);
                if got != *n {
                    return Err(format!("trail {} stops {} != {}", t, got, n));
                }
            }
            Fact::WorkKindIs(w, k) => {
                let got = s
                    .work_kind_get(*w)
                    .map(|g| g.as_str().to_string())
                    .unwrap_or_default();
                if got != k.as_str() {
                    return Err(format!("work {} kind {} != {}", w, got, k.as_str()));
                }
            }
            Fact::WorkTitle(w, title) => {
                let got = s
                    .list_works_with_titles()
                    .into_iter()
                    .find(|(id, ..)| *id == *w)
                    .map(|x| x.4)
                    .unwrap_or_default();
                if got != *title {
                    return Err(format!("work {} title {:?} != {:?}", w, got, title));
                }
            }
            Fact::WorkArchived(w) => {
                if !s.work_is_archived(*w).unwrap_or(false) {
                    return Err(format!("work {} lost archived state", w));
                }
            }
            Fact::WorkNotArchived(w) => {
                if s.work_is_archived(*w).unwrap_or(false) {
                    return Err(format!("work {} spuriously archived", w));
                }
            }
            Fact::Annotation(w, a) => {
                let got = s
                    .annotation_list(sid, *w)
                    .map(|l| l.iter().any(|p| p.annotation_id == *a))
                    .unwrap_or(false);
                if !got {
                    return Err(format!("annotation {} on work {} missing", a, w));
                }
            }
            Fact::LinkGone(l) => {
                if s.link_endorsements(*l).is_ok() {
                    return Err(format!("link {} resurrected", l));
                }
            }
        }
    }
    Ok(())
}

fn works_in(model: &[Fact]) -> Vec<u64> {
    model
        .iter()
        .filter_map(|f| match f {
            Fact::WorkExists(w) => Some(*w),
            _ => None,
        })
        .collect()
}

fn trails_in(model: &[Fact]) -> Vec<u64> {
    model
        .iter()
        .filter_map(|f| match f {
            Fact::TrailExists(t, _) => Some(*t),
            _ => None,
        })
        .collect()
}

fn random_op(s: &mut Server, sid: SessionId, rng: &mut Rng, model: &mut Vec<Fact>, n: u64) {
    let works = works_in(model);
    let trails = trails_in(model);
    let choice = rng.below(14);
    match choice {
        0 => {
            if let Ok(w) = s.create_work(sid, Edition::from_text(&format!("chaos {}", n))) {
                model.push(Fact::WorkExists(w));
            }
        }
        1 => {
            if let Some(w) = works.first().copied() {
                if s.work_publish(sid, w).is_ok() {
                    model.retain(|f| !matches!(f, Fact::WorkPublished(x) if *x == w));
                    model.push(Fact::WorkPublished(w));
                }
            }
        }
        2 => {
            if let Some(w) = works.first().copied() {
                let l = if rng.below(2) == 0 {
                    License::AllRightsReserved
                } else {
                    License::CreativeCommonsBy
                };
                if s.work_license_set(w, l).is_ok() {
                    model.retain(|f| !matches!(f, Fact::WorkLicensed(x, _) if *x == w));
                    model.push(Fact::WorkLicensed(w, l));
                }
            }
        }
        3 => {
            if let Some(w) = works.first().copied() {
                if s.work_star(sid, w).is_ok() {
                    model.push(Fact::WorkStarred(w));
                }
            }
        }
        4 => {
            let name = format!("chaos-trail-{}", n);
            if let Ok(t) = s.trail_create(sid, name.clone(), None, vec![]) {
                model.push(Fact::TrailExists(t, name));
            }
        }
        5 => {
            if let Some(t) = trails.first().copied() {
                let name = model
                    .iter()
                    .find_map(|f| match f {
                        Fact::TrailExists(tt, nm) if *tt == t => Some(nm.clone()),
                        _ => None,
                    })
                    .unwrap_or_default();
                if !name.is_empty() && s.trail_publish(sid, t).is_ok() {
                    model.push(Fact::TrailPublished(name));
                }
            }
        }
        _ => {
            if let (Some(w), Some(t)) = (works.first().copied(), trails.first().copied()) {
                let _ = s.trail_add_stop(sid, t, w, None, None, None, None);
            }
        }
    }
}

/// Byte offset where the final WAL entry starts (0 = single entry).
fn last_entry_start(data: &[u8]) -> usize {
    let text = String::from_utf8_lossy(data);
    match text[..text.len().saturating_sub(1)].rfind('\n') {
        Some(i) => i + 1,
        None => 0,
    }
}

#[test]
#[ignore = "chaos harness: run explicitly with a seed"]
fn chaos_durability() {
    let seed: u64 = std::env::var("XUDANU_CHAOS_SEED")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(0x5eed);
    let iters: u64 = std::env::var("XUDANU_CHAOS_ITERS")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(200);

    let mut rng = Rng(seed | 1);
    let dir = fresh_dir(seed);
    let mut server = Server::new();
    server.init_data_dir(&dir, None).unwrap();
    let mut sid = server.connect();
    server.login_public(sid).unwrap();
    let mut model: Vec<Fact> = Vec::new();

    for i in 0..iters {
        random_op(&mut server, sid, &mut rng, &mut model, i);

        // Facts that predate the final op survive any legal failure;
        // the final entry's fact may legitimately be lost.
        let stable: Vec<Fact> = {
            let mut m = model.clone();
            m.pop();
            m
        };

        let event = rng.below(20);
        match event {
            0..=11 => {}
            12..=14 => {
                drop(server);
                let (mut s2, sid2) = restore(&dir);
                if let Err(e) = verify(&mut s2, sid2, &model) {
                    panic!("CHAOS FAILURE seed={} iter={} crash: {}", seed, i, e);
                }
                server = s2;
                sid = sid2;
            }
            15..=16 => {
                server.checkpoint_to_store().unwrap();
            }
            17 => {
                server.checkpoint_to_store().unwrap();
                drop(server);
                let (mut s, s3) = restore(&dir);
                server = s;
                if let Err(e) = verify(&mut server, s3, &model) {
                    panic!("CHAOS FAILURE seed={} iter={} ckpt+crash: {}", seed, i, e);
                }
                sid = s3;
            }
            18 => {
                drop(server);
                let wal = dir.join("wal.log");
                if let Ok(data) = std::fs::read(&wal) {
                    let start = last_entry_start(&data);
                    if data.len() > start + 1 {
                        let cut = start + (rng.below((data.len() - start) as u64) as usize);
                        let mut f = std::fs::File::create(&wal).unwrap();
                        std::io::Write::write_all(&mut f, &data[..cut]).unwrap();
                    }
                }
                let (mut s, s4) = restore(&dir);
                server = s;
                if let Err(e) = verify(&mut server, s4, &stable) {
                    panic!("CHAOS FAILURE seed={} iter={} torn-wal: {}", seed, i, e);
                }
                sid = s4;
                // The torn final entry's fact is legitimately gone;
                // prune it from the model so later checks align.
                model = stable;
            }
            _ => {
                drop(server);
                let wal = dir.join("wal.log");
                if let Ok(data) = std::fs::read(&wal) {
                    let start = last_entry_start(&data);
                    if data.len() > start + 1 {
                        let at = start + (rng.below((data.len() - start - 1) as u64) as usize);
                        let mut data = data;
                        data[at] = data[at].wrapping_add(1);
                        std::fs::write(&wal, data).unwrap();
                    }
                }
                let (mut s, s5) = restore(&dir);
                server = s;
                sid = s5;
                if let Err(e) = verify(&mut server, s5, &stable) {
                    panic!("CHAOS FAILURE seed={} iter={} wal-corrupt: {}", seed, i, e);
                }
                // Corrupted final entry: its fact is legitimately
                // suspect; prune it from the model.
                model = stable;
            }
        }
    }

    drop(server);
    let (mut s, sidf) = restore(&dir);
    if let Err(e) = verify(&mut s, sidf, &model) {
        panic!("CHAOS FAILURE seed={} final: {}", seed, e);
    }
    let _ = std::fs::remove_dir_all(&dir);
}
