use std::collections::HashSet;
use std::path::Path;

use crate::persist::chunk_store::ChunkStore;
use crate::persist::edition_chunks::{self, EditionChunkRef, WorkChunkRef};
use crate::persist::manifest::{self, Manifest};

#[derive(Debug)]
pub struct VerifyReport {
    pub chunks_total: usize,
    pub chunks_verified: usize,
    pub chunks_corrupt: Vec<String>,
    pub chunks_orphaned: Vec<String>,
    pub chunks_missing: Vec<String>,
    pub deserialization_errors: Vec<String>,
    pub manifest_ok: bool,
    pub works_ok: usize,
    pub works_failed: usize,
    pub clubs_ok: usize,
    pub clubs_failed: usize,
    pub standalone_ok: usize,
    pub standalone_failed: usize,
}

impl VerifyReport {
    pub fn is_ok(&self) -> bool {
        self.chunks_corrupt.is_empty()
            && self.chunks_orphaned.is_empty()
            && self.chunks_missing.is_empty()
            && self.deserialization_errors.is_empty()
            && self.manifest_ok
            && self.works_failed == 0
            && self.clubs_failed == 0
            && self.standalone_failed == 0
    }
}

fn collect_referenced_hashes(manifest: &Manifest, store: &ChunkStore) -> HashSet<[u8; 32]> {
    let mut hashes = HashSet::new();

    for (_, work_ref) in &manifest.works {
        collect_work_ref_hashes(work_ref, store, &mut hashes);
    }
    for club_ref in &manifest.clubs {
        collect_work_ref_hashes(&club_ref.work_root, store, &mut hashes);
    }
    for se_ref in &manifest.standalone_editions {
        collect_edition_ref_hashes(&se_ref.edition_ref, store, &mut hashes);
    }

    hashes
}

fn collect_work_ref_hashes(work_ref: &WorkChunkRef, store: &ChunkStore, hashes: &mut HashSet<[u8; 32]>) {
    collect_edition_ref_hashes(&work_ref.current_root, store, hashes);
    for ed_ref in work_ref.history.values() {
        collect_edition_ref_hashes(ed_ref, store, hashes);
    }
}

fn collect_edition_ref_hashes(ed_ref: &EditionChunkRef, store: &ChunkStore, hashes: &mut HashSet<[u8; 32]>) {
    hashes.insert(ed_ref.root_hash);
    if let Ok(data) = store.read_chunk(&ed_ref.root_hash) {
        if let Ok(root) = postcard::from_bytes::<EditionRootChunkFull>(&data) {
            for h in &root.entry_chunk_hashes {
                hashes.insert(*h);
            }
        }
    }
}

#[derive(serde::Deserialize)]
struct EditionRootChunkFull {
    default: Option<crate::edition::range_element::RangeElement>,
    domain_start: Option<i64>,
    domain_infinite_above: bool,
    entry_count: u32,
    entry_chunk_hashes: Vec<[u8; 32]>,
}

pub fn verify_store(data_dir: &Path) -> Result<VerifyReport, String> {
    let manifest_path = manifest::manifest_path(data_dir);
    let manifest = manifest::read_manifest(&manifest_path)
        .map_err(|e| format!("manifest error: {}", e))?;

    let chunk_store = ChunkStore::open(data_dir)
        .map_err(|e| format!("chunk store error: {}", e))?;

    let mut report = VerifyReport {
        chunks_total: 0,
        chunks_verified: 0,
        chunks_corrupt: Vec::new(),
        chunks_orphaned: Vec::new(),
        chunks_missing: Vec::new(),
        deserialization_errors: Vec::new(),
        manifest_ok: true,
        works_ok: 0,
        works_failed: 0,
        clubs_ok: 0,
        clubs_failed: 0,
        standalone_ok: 0,
        standalone_failed: 0,
    };

    let referenced = collect_referenced_hashes(&manifest, &chunk_store);

    for hash in &referenced {
        if !chunk_store.chunk_exists(hash) {
            report.chunks_missing.push(format_hash(hash));
        }
    }

    let all_hashes = chunk_store.all_chunk_hashes()
        .map_err(|e| format!("failed to list chunks: {}", e))?;
    report.chunks_total = all_hashes.len();

    for hash in &all_hashes {
        if let Err(e) = chunk_store.verify_chunk(hash) {
            report.chunks_corrupt.push(format!("{}: {}", format_hash(hash), e));
            continue;
        }
        report.chunks_verified += 1;
    }

    let referenced_set: HashSet<_> = referenced.into_iter().collect();
    for hash in &all_hashes {
        if !referenced_set.contains(hash) {
            report.chunks_orphaned.push(format_hash(hash));
        }
    }

    for (id, work_ref) in &manifest.works {
        match edition_chunks::work_from_chunks_current(work_ref, &chunk_store) {
            Ok(_) => report.works_ok += 1,
            Err(e) => {
                report.works_failed += 1;
                report.deserialization_errors.push(format!("work {}: {}", id, e));
            }
        }
    }

    for club_ref in &manifest.clubs {
        match edition_chunks::work_from_chunks_current(&club_ref.work_root, &chunk_store) {
            Ok(_) => report.clubs_ok += 1,
            Err(e) => {
                report.clubs_failed += 1;
                report.deserialization_errors.push(format!("club {}: {}", club_ref.be_id, e));
            }
        }
    }

    for se_ref in &manifest.standalone_editions {
        match edition_chunks::edition_from_chunks(&se_ref.edition_ref, &chunk_store) {
            Ok(_) => report.standalone_ok += 1,
            Err(e) => {
                report.standalone_failed += 1;
                report.deserialization_errors.push(format!("edition {}: {}", se_ref.be_id, e));
            }
        }
    }

    Ok(report)
}

pub fn rebuild_manifest(data_dir: &Path) -> Result<VerifyReport, String> {
    let manifest_path = manifest::manifest_path(data_dir);
    let backup_path = manifest_path.with_extension("json.bak");

    if manifest_path.exists() {
        std::fs::copy(&manifest_path, &backup_path)
            .map_err(|e| format!("failed to backup manifest: {}", e))?;
    }

    let mut report = verify_store(data_dir)?;

    if !report.chunks_corrupt.is_empty() || !report.chunks_missing.is_empty() {
        return Ok(report);
    }

    let mut manifest = if backup_path.exists() {
        manifest::read_manifest(&backup_path)
            .map_err(|e| format!("cannot read backup manifest: {}", e))?
    } else {
        return Err("no manifest to rebuild from".to_string());
    };

    let chunk_store = ChunkStore::open(data_dir)
        .map_err(|e| format!("chunk store error: {}", e))?;

    let total_chunks = chunk_store.all_chunk_hashes()
        .map_err(|e| format!("failed to list chunks: {}", e))?
        .len();

    manifest::write_manifest(&mut manifest, &manifest_path)
        .map_err(|e| format!("failed to write manifest: {}", e))?;

    tracing::info!(
        "Rebuilt manifest: {} chunks, {} works, {} clubs verified",
        total_chunks,
        manifest.works.len(),
        manifest.clubs.len(),
    );

    report.chunks_total = total_chunks;
    Ok(report)
}

fn format_hash(hash: &[u8; 32]) -> String {
    hash.iter().map(|b| format!("{:02x}", b)).collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::{Edition, Work};
    use crate::persist::chunk_store::ChunkStore;
    use crate::persist::manifest::{self, create_empty_manifest};

    fn temp_dir() -> std::path::PathBuf {
        static COUNTER: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
        let id = COUNTER.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        std::env::temp_dir().join(format!(
            "xudanu_verify_test_{}_{}",
            std::process::id(),
            id
        ))
    }

    fn test_system_clubs() -> crate::server::SystemClubs {
        crate::server::SystemClubs {
            public_club: 1,
            admin_club: 2,
            access_club: 3,
            empty_club: 4,
        }
    }

    #[test]
    fn verify_empty_store() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let store = ChunkStore::open(&dir).unwrap();
        let mut m = create_empty_manifest(test_system_clubs(), 0);
        let path = manifest::manifest_path(&dir);
        manifest::write_manifest(&mut m, &path).unwrap();
        drop(store);

        let report = verify_store(&dir).unwrap();
        assert!(report.is_ok());
        assert_eq!(report.chunks_total, 0);
        assert_eq!(report.works_ok, 0);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn verify_with_works() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let store = ChunkStore::open(&dir).unwrap();
        let work = Work::new(10, Edition::from_text("test doc"));
        let work_ref = crate::persist::edition_chunks::work_to_chunks(&work, &store).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        m.works.push((10, work_ref));
        drop(store);

        let path = manifest::manifest_path(&dir);
        manifest::write_manifest(&mut m, &path).unwrap();

        let report = verify_store(&dir).unwrap();
        assert!(report.is_ok());
        assert_eq!(report.works_ok, 1);
        assert!(report.chunks_corrupt.is_empty());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn verify_detects_missing_chunks() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let store = ChunkStore::open(&dir).unwrap();
        let work = Work::new(10, Edition::from_text("test"));
        let work_ref = crate::persist::edition_chunks::work_to_chunks(&work, &store).unwrap();
        drop(store);

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        m.works.push((10, work_ref));

        let path = manifest::manifest_path(&dir);
        manifest::write_manifest(&mut m, &path).unwrap();

        let chunks_dir = dir.join("chunks");
        if chunks_dir.exists() {
            std::fs::remove_dir_all(&chunks_dir).unwrap();
        }
        std::fs::create_dir_all(&chunks_dir).unwrap();

        let report = verify_store(&dir).unwrap();
        assert!(!report.is_ok());
        assert!(!report.chunks_missing.is_empty());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn verify_detects_corrupt_manifest() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let path = manifest::manifest_path(&dir);
        std::fs::write(&path, b"not valid json!!!").unwrap();

        let result = verify_store(&dir);
        assert!(result.is_err());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn verify_orphaned_chunks() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let store = ChunkStore::open(&dir).unwrap();
        store.write_chunk(b"orphaned data that nobody references").unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 0);
        let path = manifest::manifest_path(&dir);
        manifest::write_manifest(&mut m, &path).unwrap();
        drop(store);

        let report = verify_store(&dir).unwrap();
        assert!(!report.chunks_orphaned.is_empty());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn verify_with_history() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let store = ChunkStore::open(&dir).unwrap();
        let v1 = Edition::from_text("version one");
        let v2 = Edition::from_text("version two");
        let mut work = Work::new(1, v1);
        work.revise(v2);
        let work_ref = crate::persist::edition_chunks::work_to_chunks(&work, &store).unwrap();

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        m.works.push((1, work_ref));
        drop(store);

        let path = manifest::manifest_path(&dir);
        manifest::write_manifest(&mut m, &path).unwrap();

        let report = verify_store(&dir).unwrap();
        assert!(report.is_ok());
        assert_eq!(report.works_ok, 1);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn rebuild_manifest_roundtrip() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let store = ChunkStore::open(&dir).unwrap();
        let work = Work::new(10, Edition::from_text("rebuild test"));
        let work_ref = crate::persist::edition_chunks::work_to_chunks(&work, &store).unwrap();
        drop(store);

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        m.works.push((10, work_ref));
        let path = manifest::manifest_path(&dir);
        manifest::write_manifest(&mut m, &path).unwrap();

        let original = std::fs::read_to_string(&path).unwrap();

        let report = rebuild_manifest(&dir).unwrap();
        assert!(report.is_ok());

        let rebuilt = std::fs::read_to_string(&path).unwrap();
        assert_ne!(original, rebuilt, "manifest should have updated timestamp");

        assert!(path.with_extension("json.bak").exists());

        let verify_after = verify_store(&dir).unwrap();
        assert!(verify_after.is_ok());

        let _ = std::fs::remove_dir_all(&dir);
    }
}
