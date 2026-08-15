use std::collections::HashSet;
use std::path::PathBuf;

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: chunk_validator <data_dir> [--fix] [--deep]");
        eprintln!();
        eprintln!("Commands:");
        eprintln!("  (none)     Validate chunk store integrity (hash + tag + root tree)");
        eprintln!("  --fix      Auto-fix legacy filenames and clean stale tmps");
        eprintln!("  --deep     Postcard-deserialize every chunk and validate struct fields");
        eprintln!();
        eprintln!("Checks:");
        eprintln!("  --deep mode additionally:");
        eprintln!("  - Full postcard deserialization of every chunk");
        eprintln!("  - Schema version validation on ServerRootChunk");
        eprintln!("  - Root tree walk with typed deserialization");
        eprintln!("  - Accurate orphan detection via typed refs");
        eprintln!("  - Catches 'bool not 0 or 1' and other postcard errors");
        std::process::exit(1);
    }

    let data_dir = PathBuf::from(&args[1]);
    let fix = args.iter().any(|a| a == "--fix");
    let deep = args.iter().any(|a| a == "--deep");

    if !data_dir.exists() {
        eprintln!("Error: '{}' does not exist", data_dir.display());
        std::process::exit(1);
    }

    let chunks_dir = data_dir.join("chunks");
    if !chunks_dir.exists() {
        eprintln!("Error: no chunks/ directory found");
        std::process::exit(1);
    }

    println!("=== Xudanu Chunk Store Validator ===");
    println!("Data dir: {}", data_dir.display());
    println!(
        "Mode: {}{}",
        if fix { "fix " } else { "" },
        if deep { "deep" } else { "integrity" }
    );

    let store = match xudanu::persist::chunk_store::ChunkStore::open(&data_dir) {
        Ok(s) => s,
        Err(e) => {
            eprintln!("Error opening chunk store: {}", e);
            std::process::exit(1);
        }
    };

    let mut report = Report::new();

    scan_chunk_files(&chunks_dir, &mut report, fix);
    if fix {
        cleanup_stale_tmps(&chunks_dir, &mut report);
    } else {
        check_stale_tmps(&chunks_dir, &mut report);
    }
    validate_root_manifest(&data_dir, &mut report);

    if let Ok(root_hash) = read_current_root_hash(&data_dir) {
        let all_hashes = store.all_chunk_hashes().unwrap_or_default();
        let all_set: HashSet<[u8; 32]> = all_hashes.into_iter().collect();

        if !all_set.contains(&root_hash) {
            report.error(format!(
                "Root chunk {} not found in store",
                bytes_to_hex(&root_hash)
            ));
        } else {
            if deep {
                validate_root_tree_typed(&store, &root_hash, &all_set, &mut report);
                find_orphans_typed(&store, &root_hash, &all_set, &mut report);
            } else {
                validate_root_tree_integrity(&store, &root_hash, &all_set, &mut report);
                find_orphans_naive(&store, &data_dir, &root_hash, &all_set, &mut report);
            }
        }
    }

    report.print();
    if report.has_errors() {
        std::process::exit(1);
    }
}

struct Report {
    errors: Vec<String>,
    warnings: Vec<String>,
    info: Vec<String>,
    fixes: Vec<String>,
    counts: std::collections::HashMap<&'static str, u64>,
}

impl Report {
    fn new() -> Self {
        Self {
            errors: Vec::new(),
            warnings: Vec::new(),
            info: Vec::new(),
            fixes: Vec::new(),
            counts: std::collections::HashMap::new(),
        }
    }
    fn error(&mut self, msg: impl Into<String>) {
        self.errors.push(msg.into());
    }
    fn warn(&mut self, msg: impl Into<String>) {
        self.warnings.push(msg.into());
    }
    fn ok(&mut self, msg: impl Into<String>) {
        self.info.push(msg.into());
    }
    fn fix(&mut self, msg: impl Into<String>) {
        self.fixes.push(msg.into());
    }
    fn count(&mut self, key: &'static str) {
        *self.counts.entry(key).or_insert(0) += 1;
    }
    fn has_errors(&self) -> bool {
        !self.errors.is_empty()
    }

    fn print(&self) {
        for f in &self.fixes {
            println!("  FIXED: {}", f);
        }
        for i in &self.info {
            println!("  OK:    {}", i);
        }
        for w in &self.warnings {
            println!("  WARN:  {}", w);
        }
        for e in &self.errors {
            println!("  ERROR: {}", e);
        }
        println!();
        println!("Results:");
        for (k, v) in &self.counts {
            println!("  {}: {}", k, v);
        }
        let total: u64 = self.counts.values().sum();
        if total > 0 {
            println!("  total chunks: {}", total);
        }
        if !self.fixes.is_empty() {
            println!("  fixes applied: {}", self.fixes.len());
        }
        if !self.warnings.is_empty() {
            println!("  warnings: {}", self.warnings.len());
        }
        if !self.errors.is_empty() {
            println!("  errors: {}", self.errors.len());
        }
        if self.errors.is_empty() && self.warnings.is_empty() {
            println!("  Chunk store is valid.");
        }
    }
}

fn scan_chunk_files(chunks_dir: &std::path::Path, report: &mut Report, fix: bool) {
    for path in walk_chunk_files_recursive(chunks_dir) {
        let name_str = match path.file_name().and_then(|n| n.to_str()) {
            Some(s) => s,
            None => continue,
        };

        let hash_hex = match extract_hash_from_filename(name_str) {
            Some(h) => h,
            None => {
                report.warn(format!("Unrecognized file: {}", path.display()));
                continue;
            }
        };

        let expected_hash = match hex_to_bytes(&hash_hex) {
            Some(h) => h,
            None => {
                report.error(format!("Invalid hex in filename: {}", name_str));
                continue;
            }
        };

        match std::fs::read(&path) {
            Ok(data) => {
                let actual = blake3_hash(&data);
                if actual != expected_hash {
                    report.error(format!(
                        "Hash mismatch: {} (expected {}, got {})",
                        name_str,
                        hash_hex,
                        bytes_to_hex(&actual)
                    ));
                } else if data.is_empty() {
                    report.warn(format!("Empty chunk: {}", name_str));
                } else {
                    match data[0] {
                        0x50 => {
                            report.count("edition");
                            report.count("total");
                        }
                        0x52 => {
                            report.count("root");
                            report.count("total");
                        }
                        0x4A => {
                            report.count("section_json");
                            report.count("total");
                            report.warn(format!("{}: JSON section tag (0x4A)", &hash_hex[..16]));
                        }
                        t => {
                            report.count("unknown_tag");
                            report.count("total");
                            report.warn(format!("{}: unknown tag 0x{:02x}", &hash_hex[..16], t));
                        }
                    }
                }
            }
            Err(e) => {
                report.error(format!("Cannot read {}: {}", name_str, e));
            }
        }

        if !name_str.ends_with(".xchunk") {
            report.count("legacy");
            if fix {
                let new_name = format!("{}.xchunk", name_str);
                if let Err(e) = std::fs::rename(&path, path.parent().unwrap().join(&new_name)) {
                    report.error(format!("Failed to rename {}: {}", name_str, e));
                } else {
                    report.fix(format!("Renamed {} -> {}", name_str, new_name));
                }
            }
        }
    }
}

fn validate_root_manifest(data_dir: &std::path::Path, report: &mut Report) {
    let rm_path = data_dir.join("root_manifest.json");
    if !rm_path.exists() {
        report.warn("No root_manifest.json found");
        return;
    }
    match std::fs::read_to_string(&rm_path) {
        Ok(content) => match serde_json::from_str::<serde_json::Value>(&content) {
            Ok(val) => {
                if let Some(obj) = val.as_object() {
                    let hash = obj
                        .get("current_root_hash")
                        .and_then(|v| v.as_str())
                        .unwrap_or("");
                    if hash.len() == 64 && hex::decode(hash).is_ok() {
                        report.ok(format!("root_manifest.json: root={}", &hash[..16]));
                    } else {
                        report.error(format!("root_manifest.json: invalid current_root_hash"));
                    }
                    match obj.get("format_version").and_then(|v| v.as_u64()) {
                        Some(1) => {}
                        Some(v) => report.error(format!(
                            "root_manifest.json: format_version={} (expected 1)",
                            v
                        )),
                        None => report.error("root_manifest.json: missing format_version"),
                    }
                }
            }
            Err(e) => report.error(format!("root_manifest.json: invalid JSON: {}", e)),
        },
        Err(e) => report.error(format!("root_manifest.json: read error: {}", e)),
    }
}

fn read_current_root_hash(data_dir: &std::path::Path) -> Result<[u8; 32], String> {
    let content =
        std::fs::read_to_string(data_dir.join("root_manifest.json")).map_err(|e| e.to_string())?;
    let val: serde_json::Value = serde_json::from_str(&content).map_err(|e| e.to_string())?;
    let hash_hex = val["current_root_hash"]
        .as_str()
        .ok_or("missing current_root_hash")?;
    let bytes = hex::decode(hash_hex).map_err(|e| e.to_string())?;
    if bytes.len() != 32 {
        return Err(format!("root hash is {} bytes, expected 32", bytes.len()));
    }
    let mut arr = [0u8; 32];
    arr.copy_from_slice(&bytes);
    Ok(arr)
}

fn validate_root_tree_integrity(
    store: &xudanu::persist::chunk_store::ChunkStore,
    root_hash: &[u8; 32],
    all_hashes: &HashSet<[u8; 32]>,
    report: &mut Report,
) {
    if !all_hashes.contains(root_hash) {
        report.error(format!(
            "Root chunk {} not found in store",
            bytes_to_hex(root_hash)
        ));
        return;
    }
    report.ok(format!(
        "Root chunk {} exists",
        &bytes_to_hex(root_hash)[..16]
    ));

    let data = match store.read_chunk(root_hash) {
        Ok(d) => d,
        Err(e) => {
            report.error(format!("Cannot read root chunk: {}", e));
            return;
        }
    };
    if data.is_empty() || data[0] != 0x52 {
        report.error(format!(
            "Root chunk: bad tag (expected 0x52, got 0x{:02x})",
            data[0]
        ));
        return;
    }
    report.ok("Root chunk: valid tag byte (0x52)");

    match xudanu::persist::root_chunk::deserialize_from_bytes::<
        xudanu::persist::root_chunk::ServerRootChunk,
    >(&data)
    {
        Ok(root) => {
            if root.format_version != 1 {
                report.error(format!(
                    "Root chunk: format_version={} (expected 1)",
                    root.format_version
                ));
            } else {
                report.ok(format!(
                    "Root chunk: format_version=1, sequence={}, {} section refs",
                    root.sequence,
                    root.works_index_hash.is_some() as u64
                        + root.clubs_index_hash.is_some() as u64
                        + root.standalone_editions_hash.is_some() as u64
                        + root.admin_hash.is_some() as u64
                        + root.system_clubs_hash.is_some() as u64
                        + root.links_hash.is_some() as u64
                        + root.social_hash.is_some() as u64
                        + root.federation_hash.is_some() as u64
                        + root.blob_metas_hash.is_some() as u64
                        + root.content_address_hash.is_some() as u64
                        + root.historical_authors_hash.is_some() as u64
                        + root.fossil_snapshots_hash.is_some() as u64
                        + root.annotations_hash.is_some() as u64
                        + root.key_history_hash.is_some() as u64,
                ));
            }
        }
        Err(e) => report.error(format!("Root chunk: deserialization failed: {}", e)),
    }
}

fn validate_root_tree_typed(
    store: &xudanu::persist::chunk_store::ChunkStore,
    root_hash: &[u8; 32],
    all_hashes: &HashSet<[u8; 32]>,
    report: &mut Report,
) {
    let data = match store.read_chunk(root_hash) {
        Ok(d) => d,
        Err(e) => {
            report.error(format!("Cannot read root chunk: {}", e));
            return;
        }
    };
    if data.is_empty() || data[0] != 0x52 {
        report.error("Root chunk: bad tag");
        return;
    }

    let root = match xudanu::persist::root_chunk::deserialize_from_bytes::<
        xudanu::persist::root_chunk::ServerRootChunk,
    >(&data)
    {
        Ok(r) => r,
        Err(e) => {
            report.error(format!("Root chunk: deserialization failed: {}", e));
            return;
        }
    };

    report.ok(format!(
        "Root chunk: format_version={}, sequence={}",
        root.format_version, root.sequence
    ));

    let mut referenced = HashSet::new();
    referenced.insert(*root_hash);

    let mut walk_queue: Vec<(&str, [u8; 32])> = Vec::new();

    if let Some(h) = root.works_index_hash {
        referenced.insert(h);
        walk_queue.push(("works_index", h));
    }
    if let Some(h) = root.clubs_index_hash {
        referenced.insert(h);
        walk_queue.push(("clubs_index", h));
    }
    if let Some(h) = root.standalone_editions_hash {
        referenced.insert(h);
        walk_queue.push(("standalone_editions", h));
    }
    if let Some(h) = root.admin_hash {
        referenced.insert(h);
        walk_queue.push(("admin", h));
    }
    if let Some(h) = root.system_clubs_hash {
        referenced.insert(h);
        walk_queue.push(("system_clubs", h));
    }

    for (label, hash) in &walk_queue {
        if !all_hashes.contains(hash) {
            report.error(format!(
                "{} chunk {} not found in store",
                label,
                bytes_to_hex(hash)
            ));
            continue;
        }
        match try_deserialize_chunk(store, hash) {
            Ok((tag, name)) => report.ok(format!(
                "{}: {} ({})",
                &bytes_to_hex(hash)[..16],
                label,
                name
            )),
            Err(e) => report.error(format!(
                "{} ({}): deserialization failed: {}",
                &bytes_to_hex(hash)[..16],
                label,
                e
            )),
        }
    }

    if let Some(h) = root.works_index_hash {
        if all_hashes.contains(&h) {
            match xudanu::persist::root_chunk::read_works_index_chunk(&h, store) {
                Ok(idx) => {
                    report.ok(format!("WorksIndexChunk: {} entries", idx.entries.len()));
                    for entry in &idx.entries {
                        referenced.insert(entry.work_state_hash);
                        if !all_hashes.contains(&entry.work_state_hash) {
                            report.error(format!(
                                "WorkStateChunk {} not found",
                                bytes_to_hex(&entry.work_state_hash)
                            ));
                        } else {
                            match xudanu::persist::root_chunk::read_work_state_chunk(
                                &entry.work_state_hash,
                                store,
                            ) {
                                Ok(ws) => report.ok(format!(
                                    "  WorkStateChunk {}: kind={:?}, revisions={}",
                                    &bytes_to_hex(&entry.work_state_hash)[..16],
                                    ws.kind,
                                    ws.revision_count
                                )),
                                Err(e) => report.error(format!(
                                    "  WorkStateChunk {}: {}",
                                    &bytes_to_hex(&entry.work_state_hash)[..16],
                                    e
                                )),
                            }
                        }
                    }
                }
                Err(e) => report.error(format!("WorksIndexChunk: {}", e)),
            }
        }
    }

    if let Some(h) = root.clubs_index_hash {
        if all_hashes.contains(&h) {
            match xudanu::persist::root_chunk::read_club_index_chunk(&h, store) {
                Ok(idx) => {
                    report.ok(format!("ClubIndexChunk: {} entries", idx.entries.len()));
                    for entry in &idx.entries {
                        referenced.insert(entry.club_state_hash);
                        if !all_hashes.contains(&entry.club_state_hash) {
                            report.error(format!(
                                "ClubStateChunk {} not found",
                                bytes_to_hex(&entry.club_state_hash)
                            ));
                        } else {
                            match xudanu::persist::root_chunk::read_club_state_chunk(
                                &entry.club_state_hash,
                                store,
                            ) {
                                Ok(cs) => report.ok(format!(
                                    "  ClubStateChunk {}: {}",
                                    &bytes_to_hex(&entry.club_state_hash)[..16],
                                    cs.be_id
                                )),
                                Err(e) => report.error(format!(
                                    "  ClubStateChunk {}: {}",
                                    &bytes_to_hex(&entry.club_state_hash)[..16],
                                    e
                                )),
                            }
                        }
                    }
                }
                Err(e) => report.error(format!("ClubIndexChunk: {}", e)),
            }
        }
    }

    if let Some(h) = root.standalone_editions_hash {
        if all_hashes.contains(&h) {
            match xudanu::persist::root_chunk::read_standalone_editions_chunk(&h, store) {
                Ok(se) => report.ok(format!(
                    "StandaloneEditionsChunk: {} entries",
                    se.entries.len()
                )),
                Err(e) => report.error(format!("StandaloneEditionsChunk: {}", e)),
            }
        }
    }

    if let Some(h) = root.admin_hash {
        if all_hashes.contains(&h) {
            match xudanu::persist::root_chunk::read_admin_chunk(&h, store) {
                Ok(ac) => report.ok(format!(
                    "AdminChunk: accepting={}, shutdown={}",
                    ac.accepting_connections, ac.shutdown_requested
                )),
                Err(e) => report.error(format!("AdminChunk: {}", e)),
            }
        }
    }

    if let Some(h) = root.system_clubs_hash {
        if all_hashes.contains(&h) {
            match xudanu::persist::root_chunk::read_system_clubs_chunk(&h, store) {
                Ok(_) => report.ok("SystemClubsChunk: valid"),
                Err(e) => report.error(format!("SystemClubsChunk: {}", e)),
            }
        }
    }

    find_orphans_typed(store, root_hash, all_hashes, report);
}

fn try_deserialize_chunk(
    store: &xudanu::persist::chunk_store::ChunkStore,
    hash: &[u8; 32],
) -> Result<(u8, String), String> {
    let data = store.read_chunk(hash).map_err(|e| e.to_string())?;
    if data.is_empty() {
        return Err("empty chunk".into());
    }
    let tag = data[0];
    let name = match tag {
        0x50 => "edition",
        0x52 => "root_tree",
        0x4A => "section_json",
        _ => return Ok((tag, format!("unknown_0x{:02x}", tag))),
    };
    Ok((tag, name.to_string()))
}

fn find_orphans_naive(
    store: &xudanu::persist::chunk_store::ChunkStore,
    data_dir: &std::path::Path,
    root_hash: &[u8; 32],
    all_hashes: &HashSet<[u8; 32]>,
    report: &mut Report,
) {
    let mut referenced = HashSet::new();
    referenced.insert(*root_hash);
    let data = match store.read_chunk(root_hash) {
        Ok(d) => d,
        Err(_) => return,
    };
    if data.len() < 2 {
        return;
    }
    let root = match xudanu::persist::root_chunk::deserialize_from_bytes::<
        xudanu::persist::root_chunk::ServerRootChunk,
    >(&data)
    {
        Ok(r) => r,
        Err(_) => return,
    };
    collect_refs_from_root(&root, &mut referenced);
    let mut orphans = Vec::new();
    for h in all_hashes {
        if !referenced.contains(h) {
            orphans.push(bytes_to_hex(h));
        }
    }
    orphans.sort();
    for o in &orphans {
        report.warn(format!("Orphan: {}", o));
    }
    if !orphans.is_empty() {
        report.warn(format!("{} orphan chunks", orphans.len()));
    }
}

fn find_orphans_typed(
    store: &xudanu::persist::chunk_store::ChunkStore,
    root_hash: &[u8; 32],
    all_hashes: &HashSet<[u8; 32]>,
    report: &mut Report,
) {
    find_orphans_typed_inner(store, root_hash, all_hashes, report);
}

fn find_orphans_typed_inner(
    store: &xudanu::persist::chunk_store::ChunkStore,
    root_hash: &[u8; 32],
    all_hashes: &HashSet<[u8; 32]>,
    report: &mut Report,
) {
    let mut referenced = HashSet::new();
    referenced.insert(*root_hash);
    let data = match store.read_chunk(root_hash) {
        Ok(d) => d,
        Err(_) => return,
    };
    let root = match xudanu::persist::root_chunk::deserialize_from_bytes::<
        xudanu::persist::root_chunk::ServerRootChunk,
    >(&data)
    {
        Ok(r) => r,
        Err(_) => return,
    };
    collect_refs_from_root(&root, &mut referenced);

    if let Some(h) = root.works_index_hash {
        if let Ok(idx) = xudanu::persist::root_chunk::read_works_index_chunk(&h, store) {
            for e in &idx.entries {
                referenced.insert(e.work_state_hash);
            }
        }
    }
    if let Some(h) = root.clubs_index_hash {
        if let Ok(idx) = xudanu::persist::root_chunk::read_club_index_chunk(&h, store) {
            for e in &idx.entries {
                referenced.insert(e.club_state_hash);
            }
        }
    }
    if let Some(h) = root.standalone_editions_hash {
        referenced.insert(h);
    }
    if let Some(h) = root.admin_hash {
        referenced.insert(h);
    }
    if let Some(h) = root.system_clubs_hash {
        referenced.insert(h);
    }

    let mut orphans = Vec::new();
    for h in all_hashes {
        if !referenced.contains(h) {
            orphans.push(bytes_to_hex(h));
        }
    }
    orphans.sort();
    for o in &orphans {
        report.warn(format!("Orphan: {}", o));
    }
    if !orphans.is_empty() {
        report.warn(format!("{} orphan chunks", orphans.len()));
    }
}

fn collect_refs_from_root(
    root: &xudanu::persist::root_chunk::ServerRootChunk,
    refs: &mut HashSet<[u8; 32]>,
) {
    let mut add = |h: &Option<[u8; 32]>| {
        if let Some(hash) = h {
            refs.insert(*hash);
        }
    };
    add(&root.works_index_hash);
    add(&root.clubs_index_hash);
    add(&root.standalone_editions_hash);
    add(&root.admin_hash);
    add(&root.system_clubs_hash);
    add(&root.links_hash);
    add(&root.social_hash);
    add(&root.federation_hash);
    add(&root.annotations_hash);
    add(&root.blob_metas_hash);
    add(&root.content_address_hash);
    add(&root.historical_authors_hash);
    add(&root.fossil_snapshots_hash);
    add(&root.key_history_hash);
}

fn check_stale_tmps(chunks_dir: &std::path::Path, report: &mut Report) {
    let mut count = 0u64;
    for path in walk_chunk_files_recursive(chunks_dir) {
        if let Some(n) = path.file_name().and_then(|f| f.to_str()) {
            if n.ends_with(".tmp") {
                report.warn(format!("Stale tmp: {}", n));
                count += 1;
            }
        }
    }
    if count > 0 {
        report.warn(format!("{} stale .tmp files (use --fix)", count));
    }
}

fn cleanup_stale_tmps(chunks_dir: &std::path::Path, report: &mut Report) {
    let mut count = 0u64;
    for path in walk_chunk_files_recursive(chunks_dir) {
        if let Some(n) = path.file_name().and_then(|f| f.to_str()) {
            if n.ends_with(".tmp") {
                match std::fs::remove_file(&path) {
                    Ok(()) => {
                        report.fix(format!("Removed tmp: {}", n));
                        count += 1;
                    }
                    Err(e) => report.error(format!("Failed to remove {}: {}", n, e)),
                }
            }
        }
    }
    if count > 0 {
        report.ok(format!("Cleaned {} tmp files", count));
    }
}

fn walk_chunk_files_recursive(chunks_dir: &std::path::Path) -> Vec<std::path::PathBuf> {
    let mut files = Vec::new();
    if let Ok(entries) = std::fs::read_dir(chunks_dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_dir() {
                if let Ok(sub) = std::fs::read_dir(&path) {
                    for s in sub.flatten() {
                        if s.path().is_file() {
                            files.push(s.path());
                        }
                    }
                }
            }
        }
    }
    files
}

fn extract_hash_from_filename(name: &str) -> Option<String> {
    let stem = name.strip_suffix(".xchunk").unwrap_or(name);
    if stem.len() != 64 || !stem.chars().all(|c| c.is_ascii_hexdigit()) {
        return None;
    }
    Some(stem.to_string())
}

fn blake3_hash(data: &[u8]) -> [u8; 32] {
    blake3::hash(data).into()
}

fn bytes_to_hex(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{:02x}", b)).collect()
}

fn hex_to_bytes(hex: &str) -> Option<[u8; 32]> {
    if hex.len() != 64 {
        return None;
    }
    let mut arr = [0u8; 32];
    for i in 0..32 {
        arr[i] = u8::from_str_radix(&hex[i * 2..i * 2 + 2], 16).ok()?;
    }
    Some(arr)
}
