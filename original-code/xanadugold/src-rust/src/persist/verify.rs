use std::collections::HashSet;
use std::path::Path;

use crate::persist::chunk_store::ChunkStore;
use crate::persist::edition_chunks::{self, EditionChunkRef, WorkChunkRef};
use crate::persist::manifest::{self, Manifest};

fn make_work_entry(
    be_id: crate::edition::backend::BeId,
    work_ref: WorkChunkRef,
) -> manifest::WorkEntry {
    manifest::WorkEntry {
        be_id,
        work_ref,
        is_source: false,
        source_author_id: None,
        source_edition_info: None,
        content_start_line: None,
        content_end_line: None,
        source_fingerprint: None,
        is_archived: false,
        lifecycle_history: Vec::new(),
        history_club: None,
    }
}

#[derive(Debug, Default)]
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

    for entry in &manifest.works {
        collect_work_ref_hashes(&entry.work_ref, store, &mut hashes);
    }
    for club_ref in &manifest.clubs {
        collect_work_ref_hashes(&club_ref.work_root, store, &mut hashes);
    }
    for se_ref in &manifest.standalone_editions {
        collect_edition_ref_hashes(&se_ref.edition_ref, store, &mut hashes);
    }

    hashes
}

fn collect_work_ref_hashes(
    work_ref: &WorkChunkRef,
    store: &ChunkStore,
    hashes: &mut HashSet<[u8; 32]>,
) {
    collect_edition_ref_hashes(&work_ref.current_root, store, hashes);
    for ed_ref in work_ref.history.values() {
        collect_edition_ref_hashes(ed_ref, store, hashes);
    }
}

fn collect_edition_ref_hashes(
    ed_ref: &EditionChunkRef,
    store: &ChunkStore,
    hashes: &mut HashSet<[u8; 32]>,
) {
    hashes.insert(ed_ref.root_hash);
    if let Ok(data) = store.read_chunk(&ed_ref.root_hash) {
        if let Ok((_, payload)) = crate::persist::chunk_store::untag_chunk_data(&data) {
            if let Ok(root) = postcard::from_bytes::<EditionRootChunkFull>(payload) {
                for h in &root.entry_chunk_hashes {
                    hashes.insert(*h);
                }
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
    let manifest =
        manifest::read_manifest(&manifest_path).map_err(|e| format!("manifest error: {}", e))?;

    let chunk_store =
        ChunkStore::open(data_dir).map_err(|e| format!("chunk store error: {}", e))?;

    verify_store_with_manifest_data(&manifest, &chunk_store)
}

pub fn verify_store_with_manifest(manifest: &Manifest, chunk_store: &ChunkStore) -> VerifyReport {
    verify_store_with_manifest_data(manifest, chunk_store).unwrap_or_else(|e| {
        let mut report = VerifyReport::default();
        report.manifest_ok = false;
        report
            .deserialization_errors
            .push(format!("internal verify error: {}", e));
        report
    })
}

fn verify_store_with_manifest_data(
    manifest: &Manifest,
    chunk_store: &ChunkStore,
) -> Result<VerifyReport, String> {
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

    let all_hashes = chunk_store
        .all_chunk_hashes()
        .map_err(|e| format!("failed to list chunks: {}", e))?;
    report.chunks_total = all_hashes.len();

    for hash in &all_hashes {
        if let Err(e) = chunk_store.verify_chunk(hash) {
            report
                .chunks_corrupt
                .push(format!("{}: {}", format_hash(hash), e));
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

    for entry in &manifest.works {
        match edition_chunks::work_from_chunks_current(&entry.work_ref, &chunk_store) {
            Ok(_) => report.works_ok += 1,
            Err(e) => {
                report.works_failed += 1;
                report
                    .deserialization_errors
                    .push(format!("work {}: {}", entry.be_id, e));
            }
        }
    }

    for club_ref in &manifest.clubs {
        match edition_chunks::work_from_chunks_current(&club_ref.work_root, &chunk_store) {
            Ok(_) => report.clubs_ok += 1,
            Err(e) => {
                report.clubs_failed += 1;
                report
                    .deserialization_errors
                    .push(format!("club {}: {}", club_ref.be_id, e));
            }
        }
    }

    for se_ref in &manifest.standalone_editions {
        match edition_chunks::edition_from_chunks(&se_ref.edition_ref, &chunk_store) {
            Ok(_) => report.standalone_ok += 1,
            Err(e) => {
                report.standalone_failed += 1;
                report
                    .deserialization_errors
                    .push(format!("edition {}: {}", se_ref.be_id, e));
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

    let chunk_store =
        ChunkStore::open(data_dir).map_err(|e| format!("chunk store error: {}", e))?;

    let total_chunks = chunk_store
        .all_chunk_hashes()
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
        std::env::temp_dir().join(format!("xudanu_verify_test_{}_{}", std::process::id(), id))
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
        m.works.push(make_work_entry(10, work_ref));
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
        m.works.push(make_work_entry(10, work_ref));

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
        store
            .write_chunk(b"orphaned data that nobody references")
            .unwrap();

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
        m.works.push(make_work_entry(1, work_ref));
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
        m.works.push(make_work_entry(10, work_ref));
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

    #[test]
    fn verify_store_with_manifest_detects_missing_chunks() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let store = ChunkStore::open(&dir).unwrap();
        let work = Work::new(42, Edition::from_text("verify with manifest test"));
        let work_ref = crate::persist::edition_chunks::work_to_chunks(&work, &store).unwrap();
        drop(store);

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        m.works.push(make_work_entry(42, work_ref));

        let report = verify_store_with_manifest(&m, &ChunkStore::open(&dir).unwrap());
        assert!(report.is_ok());

        let chunks_dir = dir.join("chunks");
        if chunks_dir.exists() {
            std::fs::remove_dir_all(&chunks_dir).unwrap();
        }
        std::fs::create_dir_all(&chunks_dir).unwrap();

        let store2 = ChunkStore::open(&dir).unwrap();
        let report2 = verify_store_with_manifest(&m, &store2);
        assert!(!report2.is_ok());
        assert!(!report2.chunks_missing.is_empty());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn verify_store_with_manifest_ok_on_healthy_data() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let store = ChunkStore::open(&dir).unwrap();
        let work = Work::new(1, Edition::from_text("healthy data"));
        let work_ref = crate::persist::edition_chunks::work_to_chunks(&work, &store).unwrap();
        drop(store);

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        m.works.push(make_work_entry(1, work_ref));

        let store2 = ChunkStore::open(&dir).unwrap();
        let report = verify_store_with_manifest(&m, &store2);
        assert!(report.is_ok());
        assert_eq!(report.works_ok, 1);
        assert_eq!(report.works_failed, 0);
        assert!(report.manifest_ok);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn chunk_store_fsync_leaves_no_tmp() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let store = ChunkStore::open(&dir).unwrap();
        let hash = store.write_chunk(b"fsync test data").unwrap();
        assert!(store.chunk_exists(&hash));

        let path = chunk_path_from_hash(&dir, &hash);
        assert!(path.exists(), "chunk file should exist");
        assert!(
            !path.with_extension("tmp").exists(),
            "tmp file should be cleaned up after rename"
        );

        let data = store.read_chunk(&hash).unwrap();
        assert_eq!(data, b"fsync test data");

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn chunk_store_cleanup_stale_tmp_on_open() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let chunks_dir = dir.join("chunks");
        std::fs::create_dir_all(chunks_dir.join("ab")).unwrap();
        std::fs::write(
            chunks_dir.join("ab").join("abcdef123456.tmp"),
            b"stale data",
        )
        .unwrap();
        std::fs::write(chunks_dir.join("ab").join("other.tmp"), b"another stale").unwrap();

        let store = ChunkStore::open(&dir).unwrap();

        assert!(
            !chunks_dir.join("ab").join("abcdef123456.tmp").exists(),
            "stale tmp should be cleaned up on open"
        );
        assert!(
            !chunks_dir.join("ab").join("other.tmp").exists(),
            "stale tmp should be cleaned up on open"
        );

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn manifest_rotation_preserves_all_data() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let store = ChunkStore::open(&dir).unwrap();
        let w1 = Work::new(1, Edition::from_text("doc one"));
        let wr1 = crate::persist::edition_chunks::work_to_chunks(&w1, &store).unwrap();
        drop(store);

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        m.works.push(crate::persist::manifest::WorkEntry {
            be_id: 1,
            work_ref: wr1.clone(),
            is_source: false,
            source_author_id: None,
            source_edition_info: None,
            content_start_line: None,
            content_end_line: None,
            source_fingerprint: None,
            is_archived: false,
            lifecycle_history: Vec::new(),
            history_club: None,
        });
        let path = manifest::manifest_path(&dir);

        manifest::write_manifest(&mut m, &path).unwrap();
        let b1 = manifest::backup_manifest_path(&dir, m.sequence);
        std::fs::copy(&path, &b1).unwrap();
        assert_eq!(m.sequence, 1);

        let store2 = ChunkStore::open(&dir).unwrap();
        let w2 = Work::new(2, Edition::from_text("doc two"));
        let wr2 = crate::persist::edition_chunks::work_to_chunks(&w2, &store2).unwrap();
        drop(store2);

        m.works.push(crate::persist::manifest::WorkEntry {
            be_id: 2,
            work_ref: wr2,
            is_source: false,
            source_author_id: None,
            source_edition_info: None,
            content_start_line: None,
            content_end_line: None,
            source_fingerprint: None,
            is_archived: false,
            lifecycle_history: Vec::new(),
            history_club: None,
        });
        manifest::write_manifest(&mut m, &path).unwrap();
        let b2 = manifest::backup_manifest_path(&dir, m.sequence);
        std::fs::copy(&path, &b2).unwrap();
        assert_eq!(m.sequence, 2);

        assert!(b1.exists());
        assert!(b2.exists());

        let r1 = manifest::read_manifest(&b1).unwrap();
        assert_eq!(r1.works.len(), 1, "backup v1 should have 1 work");
        assert_eq!(r1.sequence, 1);

        let r2 = manifest::read_manifest(&b2).unwrap();
        assert_eq!(r2.works.len(), 2, "backup v2 should have 2 works");
        assert_eq!(r2.sequence, 2);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn recovery_from_corrupt_primary_with_backup() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let store = ChunkStore::open(&dir).unwrap();
        let work = Work::new(5, Edition::from_text("recoverable data"));
        let work_ref = crate::persist::edition_chunks::work_to_chunks(&work, &store).unwrap();
        drop(store);

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        m.works.push(crate::persist::manifest::WorkEntry {
            be_id: 5,
            work_ref: work_ref,
            is_source: false,
            source_author_id: None,
            source_edition_info: None,
            content_start_line: None,
            content_end_line: None,
            source_fingerprint: None,
            is_archived: false,
            lifecycle_history: Vec::new(),
            history_club: None,
        });
        let path = manifest::manifest_path(&dir);
        manifest::write_manifest(&mut m, &path).unwrap();

        let backup = manifest::backup_manifest_path(&dir, m.sequence);
        std::fs::copy(&path, &backup).unwrap();

        let original_content = std::fs::read_to_string(&path).unwrap();

        std::fs::write(&path, b"{{{{CORRUPTED JSON{{{{").unwrap();

        let recovered = manifest::read_manifest_with_fallback(&path, 3).unwrap();
        assert_eq!(recovered.works.len(), 1);
        assert_eq!(recovered.works[0].be_id, 5);

        let restored_primary = std::fs::read_to_string(&path).unwrap();
        assert_eq!(
            restored_primary, original_content,
            "primary should be restored from backup"
        );

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn gc_preserves_chunks_referenced_by_backups() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let store = ChunkStore::open(&dir).unwrap();
        let w1 = Work::new(1, Edition::from_text("old document"));
        let wr1 = crate::persist::edition_chunks::work_to_chunks(&w1, &store).unwrap();

        let w2 = Work::new(2, Edition::from_text("new document"));
        let wr2 = crate::persist::edition_chunks::work_to_chunks(&w2, &store).unwrap();
        drop(store);

        let mut m = create_empty_manifest(test_system_clubs(), 100);
        m.works.push(make_work_entry(1, wr1));
        let path = manifest::manifest_path(&dir);
        manifest::write_manifest(&mut m, &path).unwrap();

        let b1 = manifest::backup_manifest_path(&dir, m.sequence);
        std::fs::copy(&path, &b1).unwrap();

        m.works.retain(|e| e.be_id != 1);
        m.works.push(make_work_entry(2, wr2.clone()));
        manifest::write_manifest(&mut m, &path).unwrap();

        let store2 = ChunkStore::open(&dir).unwrap();
        let mut referenced = std::collections::HashSet::new();
        if let Ok(hashes) =
            crate::persist::edition_chunks::collect_edition_hashes(&wr2.current_root, &store2)
        {
            referenced.extend(hashes);
        }

        if let Ok(bm) = manifest::read_manifest(&b1) {
            for entry in &bm.works {
                if let Ok(hashes) =
                    crate::persist::edition_chunks::collect_work_hashes(&entry.work_ref, &store2)
                {
                    referenced.extend(hashes);
                }
            }
        }

        let all = store2.all_chunk_hashes().unwrap();
        for hash in &all {
            if !referenced.contains(hash) {
                panic!(
                    "GC would delete chunk {} that exists on disk but is only in backup - \
                     backup-aware GC should protect it",
                    format_hash(hash)
                );
            }
        }

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn gc_preserves_backup_history_chunks() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        // Create a work with revision history
        let store = ChunkStore::open(&dir).unwrap();
        let mut w1 = Work::new(10, Edition::from_text("revision zero"));
        w1.revise(Edition::from_text("revision one"));
        w1.revise(Edition::from_text("revision two"));
        let wr1 = crate::persist::edition_chunks::work_to_chunks(&w1, &store).unwrap();
        assert!(!wr1.history.is_empty(), "work should have history entries");

        // Collect all chunks for this work (current + history)
        let all_work1_hashes =
            crate::persist::edition_chunks::collect_work_hashes(&wr1, &store).unwrap();
        let current_only_hashes =
            crate::persist::edition_chunks::collect_edition_hashes(&wr1.current_root, &store)
                .unwrap();

        // History-only chunks are those NOT in current_only
        let history_only: HashSet<[u8; 32]> = all_work1_hashes
            .difference(&current_only_hashes)
            .copied()
            .collect();
        assert!(
            !history_only.is_empty(),
            "there must be history-only chunks to test the fix"
        );

        drop(store);

        // Write manifest with the work, then create a backup
        let mut m = create_empty_manifest(test_system_clubs(), 100);
        m.works.push(make_work_entry(10, wr1));
        let path = manifest::manifest_path(&dir);
        manifest::write_manifest(&mut m, &path).unwrap();

        let backup = manifest::backup_manifest_path(&dir, m.sequence);
        std::fs::copy(&path, &backup).unwrap();

        // Remove the work from the current manifest (simulate deletion)
        m.works.clear();
        manifest::write_manifest(&mut m, &path).unwrap();

        // Simulate GC mark phase: scan backup manifest
        let store2 = ChunkStore::open(&dir).unwrap();
        let mut referenced: HashSet<[u8; 32]> = HashSet::new();

        let bm = manifest::read_manifest(&backup).unwrap();
        for entry in &bm.works {
            match crate::persist::edition_chunks::collect_work_hashes(&entry.work_ref, &store2) {
                Ok(hashes) => referenced.extend(hashes),
                Err(_) => {
                    panic!(
                        "collect_work_hashes on backup entry failed — \
                         GC would abort, but should succeed"
                    );
                }
            }
        }

        // Every history-only chunk must be in referenced (protected by backup)
        for hash in &history_only {
            assert!(
                referenced.contains(hash),
                "history chunk {} is NOT in referenced set — \
                 if GC used collect_edition_hashes instead of collect_work_hashes, \
                 this chunk would be deleted",
                format_hash(hash)
            );
        }

        let _ = std::fs::remove_dir_all(&dir);
    }
}

fn chunk_path_from_hash(base: &std::path::Path, hash: &[u8; 32]) -> std::path::PathBuf {
    let hex: String = hash.iter().map(|b| format!("{:02x}", b)).collect();
    let prefix = &hex[..2];
    base.join("chunks")
        .join(prefix)
        .join(format!("{}.xchunk", hex))
}
