use std::path::PathBuf;
use xudanu::persist::chunk_store::ChunkStore;
use xudanu::persist::manifest::{self, ClubChunkRef, Manifest};
use xudanu::persist::root_chunk::{
    self, AdminChunk, ClubIndexChunk, ClubIndexEntry, ClubStateChunk, RootManifest,
    ServerRootChunk, SystemClubsChunk, WorkIndexEntry, WorkStateChunk, WorksIndexChunk,
    ROOT_CHUNK_FORMAT_VERSION,
};

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: migrate_manifest <data_dir> [--dry-run]");
        eprintln!();
        eprintln!("Reads manifest.json from data_dir, writes all sections as chunks,");
        eprintln!("and creates root_manifest.json pointing to the new root chunk.");
        eprintln!();
        eprintln!("Options:");
        eprintln!("  --dry-run  Show what would be written without writing anything");
        std::process::exit(1);
    }

    let data_dir = PathBuf::from(&args[1]);
    let dry_run = args.get(2).map(|s| s.as_str()) == Some("--dry-run");

    if !data_dir.exists() {
        eprintln!("Error: data_dir '{}' does not exist", data_dir.display());
        std::process::exit(1);
    }

    let manifest_path = manifest::manifest_path(&data_dir);
    if !manifest_path.exists() {
        eprintln!("Error: manifest not found at '{}'", manifest_path.display());
        std::process::exit(1);
    }

    println!("=== Xudanu Manifest → Chunk Store Migration ===");
    println!("Data dir: {}", data_dir.display());
    println!("Manifest: {}", manifest_path.display());

    let m = match manifest::read_manifest_dual(&data_dir) {
        Ok(m) => m,
        Err(e) => {
            if e.to_string().contains("checksum mismatch") {
                eprintln!("Warning: manifest checksum mismatch (likely from manual edits)");
                eprintln!("         Attempting to re-read with checksum bypass...");
                let raw = match std::fs::read_to_string(&manifest_path) {
                    Ok(r) => r,
                    Err(io) => { eprintln!("Cannot read manifest file: {}", io); std::process::exit(1); }
                };
                let mut val: serde_json::Value = match serde_json::from_str(&raw) {
                    Ok(v) => v,
                    Err(j) => { eprintln!("Cannot parse manifest JSON: {}", j); std::process::exit(1); }
                };
                if let Some(obj) = val.as_object_mut() {
                    obj.insert("checksum".to_string(), serde_json::Value::String(String::new()));
                }
                let patched = match serde_json::to_string(&val) {
                    Ok(p) => p,
                    Err(j) => { eprintln!("Cannot re-serialize manifest: {}", j); std::process::exit(1); }
                };
                match manifest::read_manifest_from_str(&patched) {
                    Ok(m) => m,
                    Ok(e2) => { eprintln!("Checksum bypass also failed: {:?}", e2); std::process::exit(1); }
                    Err(e2) => { eprintln!("Checksum bypass also failed: {}", e2); std::process::exit(1); }
                }
            } else {
                eprintln!("Error reading manifest: {}", e);
                std::process::exit(1);
            }
        }
    };

    println!("Manifest: sequence={}, works={}, clubs={}, standalone_editions={}",
        m.sequence, m.works.len(), m.clubs.len(), m.standalone_editions.len());

    if dry_run {
        println!();
        println!("=== DRY RUN (nothing will be written) ===");
        println!("Would write sections:");
        println!("  works: {} entries → WorkStateChunks + WorksIndexChunk", m.works.len());
        println!("  clubs: {} entries → ClubStateChunks + ClubIndexChunk", m.clubs.len());
        println!("  standalone_editions: {} entries → StandaloneEditionsChunk", m.standalone_editions.len());
        println!("  admin: AdminChunk");
        println!("  system_clubs: SystemClubsChunk");
        println!("  links_hash: {:?}", m.links_chunk_hash);
        println!("  social_hash: {:?}", m.social_chunk_hash);
        println!("  blob_metas_hash: {:?}", m.blob_metas_chunk_hash);
        println!("  content_address_hash: {:?}", m.content_address_chunk_hash);
        println!("  historical_authors_hash: {:?}", m.historical_authors_chunk_hash);
        println!("  fossil_snapshots_hash: {:?}", m.fossil_snapshots_hash);
        println!("Then: ServerRootChunk → root_manifest.json");
        return;
    }

    let chunk_store = match ChunkStore::open(&data_dir) {
        Ok(cs) => cs,
        Err(e) => {
            eprintln!("Error opening chunk store at '{}': {:?}", data_dir.join("chunks").display(), e);
            std::process::exit(1);
        }
    };
    println!("Chunk store opened at {}", data_dir.join("chunks").display());

    let root_hash = migrate_manifest(&chunk_store, &data_dir, &m).unwrap_or_else(|e| {
        eprintln!("Migration failed: {}", e);
        std::process::exit(1);
    });

    println!();
    println!("=== Migration Complete ===");
    println!("Root chunk hash: {}", hex::encode(root_hash));
    println!("root_manifest.json written to {}", data_dir.display());
    println!();
    println!("To verify, start the server and check that it reads from the root chunk.");
}

fn migrate_manifest(
    chunk_store: &ChunkStore,
    data_dir: &std::path::Path,
    m: &Manifest,
) -> Result<[u8; 32], Box<dyn std::error::Error>> {
    let mut written_chunks = 0u64;

    // --- Works: WorkStateChunks + WorksIndexChunk ---
    let mut work_index_entries = Vec::with_capacity(m.works.len());
    for entry in &m.works {
        let ws = build_work_state_chunk(entry);
        let ws_hash = root_chunk::write_work_state_chunk(&ws, chunk_store)?;
        written_chunks += 1;
        work_index_entries.push(WorkIndexEntry {
            format_version: 0,
            be_id: entry.be_id,
            work_state_hash: ws_hash,
        });
    }

    let works_index_hash = if work_index_entries.is_empty() {
        None
    } else {
        let h = root_chunk::write_works_index_chunk(
            &WorksIndexChunk { format_version: 0, entries: work_index_entries },
            chunk_store,
        )?;
        written_chunks += 1;
        Some(h)
    };
    println!("  works: {} WorkStateChunks + WorksIndexChunk",
        m.works.len());

    // --- Clubs: ClubStateChunks + ClubIndexChunk ---
    let mut club_index_entries = Vec::with_capacity(m.clubs.len());
    for club_ref in &m.clubs {
        let cs = build_club_state_chunk(club_ref);
        let cs_hash = root_chunk::write_club_state_chunk(&cs, chunk_store)?;
        written_chunks += 1;
        club_index_entries.push(ClubIndexEntry {
            format_version: 0,
            be_id: club_ref.be_id,
            club_state_hash: cs_hash,
        });
    }

    let clubs_index_hash = if club_index_entries.is_empty() {
        None
    } else {
        let h = root_chunk::write_club_index_chunk(
            &ClubIndexChunk { format_version: 0, entries: club_index_entries },
            chunk_store,
        )?;
        written_chunks += 1;
        Some(h)
    };
    println!("  clubs: {} ClubStateChunks + ClubIndexChunk",
        m.clubs.len());

    // --- Standalone Editions ---
    let standalone_editions_hash = if m.standalone_editions.is_empty() {
        None
    } else {
        let entries: Vec<root_chunk::StandaloneEditionEntry> = m.standalone_editions
            .iter()
            .map(|se| root_chunk::StandaloneEditionEntry {
                format_version: 0,
                be_id: se.be_id,
                edition_ref_hash: se.edition_ref.root_hash,
            })
            .collect();
        let chunk = root_chunk::StandaloneEditionsChunk { format_version: 0, entries };
        let hash = root_chunk::write_standalone_editions_chunk(&chunk, chunk_store)?;
        written_chunks += 1;
        Some(hash)
    };
    println!("  standalone_editions: chunk written");

    // --- Admin ---
    let admin_chunk = AdminChunk {
        format_version: 0,
        admin: m.admin.clone(),
        accepting_connections: true,
        shutdown_requested: false,
        grants: vec![],
        server_name: None,
        server_description: None,
        server_namespace_id: None,
        public_address: None,
    };
    let admin_hash = Some(root_chunk::write_admin_chunk(&admin_chunk, chunk_store)?);
    written_chunks += 1;
    println!("  admin: AdminChunk written");

    // --- System Clubs ---
    let sys_chunk = SystemClubsChunk {
        format_version: 0,
        system_clubs: m.system_clubs.clone(),
    };
    let system_clubs_hash = Some(root_chunk::write_system_clubs_chunk(&sys_chunk, chunk_store)?);
    written_chunks += 1;
    println!("  system_clubs: SystemClubsChunk written");

    // --- Reconcile Store ---
    let reconcile_store_hash = manifest::write_section_chunk(chunk_store, &m.reconcile_store)?;
    if reconcile_store_hash.is_some() {
        written_chunks += 1;
        println!("  reconcile_store: section chunk written");
    }

    // --- Build ServerRootChunk ---
    let now = chrono::Utc::now().to_rfc3339();
    let root = ServerRootChunk {
        format_version: ROOT_CHUNK_FORMAT_VERSION,
        sequence: m.sequence,
        checkpoint_at: now,
        grand_map_id_counter: m.grand_map_id_counter,
        session_counter: m.session_counter,
        operation_counter: m.operation_counter,
        link_counter: m.link_counter,
        works_index_hash,
        clubs_index_hash,
        standalone_editions_hash,
        links_hash: m.links_chunk_hash,
        social_hash: m.social_chunk_hash,
        federation_hash: m.federation_chunk_hash,
        annotations_hash: m.fossil_snapshots_hash,
        blob_metas_hash: m.blob_metas_chunk_hash,
        content_address_hash: m.content_address_chunk_hash,
        historical_authors_hash: m.historical_authors_chunk_hash,
        fossil_snapshots_hash: m.fossil_snapshots_hash,
        admin_hash,
        key_history_hash: None,
        system_clubs_hash,
        reconcile_store_hash,
    };

    let root_hash = root_chunk::write_root_chunk(&root, chunk_store)?;
    written_chunks += 1;
    println!("  root: ServerRootChunk written");

    // --- Write root_manifest.json ---
    let root_manifest = RootManifest {
        current_root_hash: hex::encode(root_hash),
        previous_root_hash: None,
        format_version: ROOT_CHUNK_FORMAT_VERSION,
    };
    root_chunk::write_root_manifest(&root_manifest, &data_dir.join("root_manifest.json"))?;
    println!("  root_manifest.json written");

    println!();
    println!("  Total chunks written: {}", written_chunks);

    Ok(root_hash)
}

fn build_work_state_chunk(entry: &manifest::WorkEntry) -> WorkStateChunk {
    let history: Vec<(u64, [u8; 32])> = entry
        .work_ref
        .history
        .iter()
        .map(|(rev, eref)| (*rev, eref.root_hash))
        .collect();

    WorkStateChunk {
        format_version: 0,
        be_id: entry.be_id,
        owner: entry.work_ref.owner,
        read_club: entry.work_ref.read_club,
        edit_club: entry.work_ref.edit_club,
        sponsors: entry.work_ref.sponsors.clone(),
        endorsements: entry.work_ref.endorsements.clone(),
        current_edition_hash: entry.work_ref.current_root.root_hash,
        revision_count: entry.work_ref.history.len() as u64,
        history,
        source_author_id: entry.source_author_id,
        source_fingerprint: entry.source_fingerprint.clone(),
        lifecycle_history: entry.lifecycle_history.clone(),
        history_club: entry.history_club,
        kind: entry.kind,
        license: entry.license,
        custom_title: entry.custom_title.clone(),
        is_source: entry.is_source,
        source_edition_info: entry.source_edition_info.clone(),
        content_start_line: entry.content_start_line,
        content_end_line: entry.content_end_line,
        is_archived: entry.is_archived,
        revisions: vec![],
    }
}

fn build_club_state_chunk(club_ref: &ClubChunkRef) -> ClubStateChunk {
    ClubStateChunk {
        format_version: 0,
        be_id: club_ref.be_id,
        name: club_ref.name.clone(),
        signature_club: club_ref.signature_club,
        work_root: club_ref.work_root.clone(),
        default_read_club: club_ref.default_read_club,
        default_edit_club: club_ref.default_edit_club,
        is_personal: club_ref.is_personal,
        display_name: club_ref.display_name.clone(),
        credential: club_ref.credential.clone(),
        encrypted_signing_key: club_ref.encrypted_signing_key.clone(),
        email: club_ref.email.clone(),
        verified: club_ref.verified,
        members: club_ref.members.clone(),
        sponsored_works: club_ref.sponsored_works.clone(),
    }
}
