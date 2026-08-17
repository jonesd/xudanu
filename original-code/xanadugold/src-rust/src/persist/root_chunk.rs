use crate::edition::backend::BeId;
use crate::edition::License;
use crate::edition::WorkKind;
use crate::persist::chunk_store::{ChunkError, ChunkStore, CHUNK_FORMAT_POSTCARD};
use crate::persist::edition_chunks::{EditionChunkRef, WorkChunkRef};
use crate::persist::manifest::RevisionMeta;

pub const ROOT_CHUNK_FORMAT_VERSION: u32 = 1;

pub const CHUNK_FORMAT_ROOT: u8 = 0x52;

fn serialize_to_bytes<T: serde::Serialize>(value: &T) -> Result<Vec<u8>, RootChunkError> {
    let postcard_data =
        postcard::to_allocvec(value).map_err(|e| RootChunkError::Serialization(e.to_string()))?;
    let mut result = Vec::with_capacity(1 + postcard_data.len());
    result.push(CHUNK_FORMAT_ROOT);
    result.extend_from_slice(&postcard_data);
    Ok(result)
}

pub fn deserialize_from_bytes<'a, T: serde::Deserialize<'a>>(
    bytes: &'a [u8],
) -> Result<T, RootChunkError> {
    if bytes.is_empty() {
        return Err(RootChunkError::CorruptData("empty root chunk".to_string()));
    }
    let format_tag = bytes[0];
    if format_tag != CHUNK_FORMAT_ROOT {
        return Err(RootChunkError::WrongFormat {
            expected: CHUNK_FORMAT_ROOT,
            actual: format_tag,
        });
    }
    postcard::from_bytes(&bytes[1..]).map_err(|e| RootChunkError::Serialization(e.to_string()))
}

#[derive(Debug)]
pub enum RootChunkError {
    Serialization(String),
    ChunkStore(ChunkError),
    CorruptData(String),
    WrongFormat { expected: u8, actual: u8 },
    MissingChunk([u8; 32]),
}

impl std::fmt::Display for RootChunkError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            RootChunkError::Serialization(e) => write!(f, "root chunk serialization error: {}", e),
            RootChunkError::ChunkStore(e) => write!(f, "root chunk store error: {}", e),
            RootChunkError::CorruptData(e) => write!(f, "corrupt root chunk: {}", e),
            RootChunkError::WrongFormat { expected, actual } => {
                write!(
                    f,
                    "root chunk format 0x{:02x}, expected 0x{:02x}",
                    actual, expected
                )
            }
            RootChunkError::MissingChunk(h) => {
                write!(
                    f,
                    "missing root chunk: 0x{:08x}",
                    u64::from_be_bytes(h[..8].try_into().unwrap_or([0; 8]))
                )
            }
        }
    }
}

impl std::error::Error for RootChunkError {}

impl From<ChunkError> for RootChunkError {
    fn from(e: ChunkError) -> Self {
        RootChunkError::ChunkStore(e)
    }
}

// ── WorkStateChunk ──────────────────────────────────────────────────────────

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct WorkStateChunk {
    #[serde(default)]
    pub format_version: u32,
    pub be_id: BeId,
    pub owner: Option<BeId>,
    pub read_club: Option<BeId>,
    pub edit_club: Option<BeId>,
    #[serde(default)]
    pub sponsors: Vec<BeId>,
    #[serde(default)]
    pub endorsements: Vec<(u64, u64)>,
    pub current_edition_hash: [u8; 32],
    pub revision_count: u64,
    #[serde(default)]
    pub history: Vec<(u64, [u8; 32])>,
    pub source_author_id: Option<BeId>,
    pub source_fingerprint: Option<Vec<u64>>,
    #[serde(default)]
    pub lifecycle_history: Vec<crate::edition::work::WorkLifecycleEvent>,
    pub history_club: Option<BeId>,
    #[serde(default)]
    pub kind: WorkKind,
    #[serde(default)]
    pub license: License,
    pub custom_title: Option<String>,
    #[serde(default)]
    pub is_source: bool,
    pub source_edition_info: Option<String>,
    pub content_start_line: Option<u64>,
    pub content_end_line: Option<u64>,
    #[serde(default)]
    pub is_archived: bool,
    #[serde(default)]
    pub revisions: Vec<RevisionMeta>,
}

// ── WorkIndexEntry ──────────────────────────────────────────────────────────

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct WorkIndexEntry {
    #[serde(default)]
    pub format_version: u32,
    pub be_id: BeId,
    pub work_state_hash: [u8; 32],
}

// ── WorksIndexChunk ────────────────────────────────────────────────────────

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct WorksIndexChunk {
    #[serde(default)]
    pub format_version: u32,
    pub entries: Vec<WorkIndexEntry>,
}

// ── ServerRootChunk ─────────────────────────────────────────────────────────

// Club state chunks
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ClubIndexChunk {
    #[serde(default)]
    pub format_version: u32,
    pub entries: Vec<ClubIndexEntry>,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ClubIndexEntry {
    #[serde(default)]
    pub format_version: u32,
    pub be_id: BeId,
    pub club_state_hash: [u8; 32],
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ClubStateChunk {
    #[serde(default)]
    pub format_version: u32,
    pub be_id: BeId,
    pub name: Option<String>,
    pub signature_club: Option<BeId>,
    pub work_root: WorkChunkRef,
    pub default_read_club: Option<BeId>,
    pub default_edit_club: Option<BeId>,
    pub is_personal: bool,
    pub display_name: Option<String>,
    pub credential: Option<crate::server::club::Credential>,
    pub encrypted_signing_key: Option<crate::crypto::club_keys::EncryptedSigningKey>,
    pub email: Option<String>,
    pub verified: bool,
    pub members: Vec<BeId>,
    pub sponsored_works: Vec<BeId>,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct StandaloneEditionsChunk {
    #[serde(default)]
    pub format_version: u32,
    pub entries: Vec<StandaloneEditionEntry>,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct StandaloneEditionEntry {
    #[serde(default)]
    pub format_version: u32,
    pub be_id: BeId,
    pub edition_ref_hash: [u8; 32],
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct AdminChunk {
    #[serde(default)]
    pub format_version: u32,
    pub admin: crate::persist::manifest::AdminEntry,
    pub accepting_connections: bool,
    pub shutdown_requested: bool,
    pub grants: Vec<(BeId, String)>,
    pub server_name: Option<String>,
    pub server_description: Option<String>,
    pub server_namespace_id: Option<u64>,
    pub public_address: Option<String>,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SystemClubsChunk {
    #[serde(default)]
    pub format_version: u32,
    pub system_clubs: crate::server::SystemClubs,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ServerRootChunk {
    pub format_version: u32,
    pub sequence: u64,
    pub checkpoint_at: String,

    pub grand_map_id_counter: BeId,
    pub session_counter: u64,
    pub operation_counter: u64,
    pub link_counter: BeId,

    #[serde(default)]
    pub works_index_hash: Option<[u8; 32]>,
    #[serde(default)]
    pub clubs_index_hash: Option<[u8; 32]>,
    #[serde(default)]
    pub standalone_editions_hash: Option<[u8; 32]>,
    #[serde(default)]
    pub links_hash: Option<[u8; 32]>,
    #[serde(default)]
    pub social_hash: Option<[u8; 32]>,
    #[serde(default)]
    pub federation_hash: Option<[u8; 32]>,
    #[serde(default)]
    pub annotations_hash: Option<[u8; 32]>,
    #[serde(default)]
    pub blob_metas_hash: Option<[u8; 32]>,
    #[serde(default)]
    pub content_address_hash: Option<[u8; 32]>,
    #[serde(default)]
    pub historical_authors_hash: Option<[u8; 32]>,
    #[serde(default)]
    pub fossil_snapshots_hash: Option<[u8; 32]>,
    #[serde(default)]
    pub admin_hash: Option<[u8; 32]>,
    #[serde(default)]
    pub key_history_hash: Option<[u8; 32]>,
    #[serde(default)]
    pub system_clubs_hash: Option<[u8; 32]>,
    #[serde(default)]
    pub reconcile_store_hash: Option<[u8; 32]>,
}

// ── RootManifest (tiny bootstrap file) ───────────────────────────────────────

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct RootManifest {
    pub current_root_hash: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub previous_root_hash: Option<String>,
    pub format_version: u32,
}

// ── Write / Read functions ──────────────────────────────────────────────────

pub fn write_root_chunk(
    chunk: &ServerRootChunk,
    store: &ChunkStore,
) -> Result<[u8; 32], RootChunkError> {
    let data = serialize_to_bytes(chunk)?;
    let hash = store.write_chunk(&data)?;
    Ok(hash)
}

pub fn read_root_chunk(
    hash: &[u8; 32],
    store: &ChunkStore,
) -> Result<ServerRootChunk, RootChunkError> {
    let data = store.read_chunk(hash)?;
    deserialize_from_bytes(&data)
}

pub fn write_works_index_chunk(
    chunk: &WorksIndexChunk,
    store: &ChunkStore,
) -> Result<[u8; 32], RootChunkError> {
    let data = serialize_to_bytes(chunk)?;
    let hash = store.write_chunk(&data)?;
    Ok(hash)
}

pub fn read_works_index_chunk(
    hash: &[u8; 32],
    store: &ChunkStore,
) -> Result<WorksIndexChunk, RootChunkError> {
    let data = store.read_chunk(hash)?;
    deserialize_from_bytes(&data)
}

pub fn write_work_state_chunk(
    chunk: &WorkStateChunk,
    store: &ChunkStore,
) -> Result<[u8; 32], RootChunkError> {
    let data = serialize_to_bytes(chunk)?;
    let hash = store.write_chunk(&data)?;
    Ok(hash)
}

pub fn read_work_state_chunk(
    hash: &[u8; 32],
    store: &ChunkStore,
) -> Result<WorkStateChunk, RootChunkError> {
    let data = store.read_chunk(hash)?;
    deserialize_from_bytes(&data)
}

pub fn write_root_manifest(manifest: &RootManifest, path: &std::path::Path) -> std::io::Result<()> {
    let json = serde_json::to_vec_pretty(manifest)
        .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
    let tmp_path = path.with_extension("tmp");
    std::fs::write(&tmp_path, &json)?;
    std::fs::rename(&tmp_path, path)?;
    Ok(())
}

pub fn read_root_manifest(path: &std::path::Path) -> std::io::Result<RootManifest> {
    let data = std::fs::read_to_string(path)?;
    serde_json::from_str(&data).map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))
}

/// Build and write a ServerRootChunk from data already computed during checkpoint.
///
/// This is called at the end of `checkpoint_persist()` after all edition chunks,
/// section chunks, and the manifest have been written. It creates:
/// - One WorkStateChunk per work (combining WorkEntry + WorkChunkRef data)
/// - One WorksIndexChunk pointing to all WorkStateChunks
/// - One ServerRootChunk pointing to the works index + all section hashes
/// - A tiny root_manifest.json bootstrap file
///
/// Returns the root chunk hash on success.
pub fn checkpoint_write_root(
    chunk_store: &ChunkStore,
    data_dir: &std::path::Path,
    manifest: &crate::persist::manifest::Manifest,
) -> std::io::Result<[u8; 32]> {
    let work_entries = &manifest.works;

    let mut work_index_entries = Vec::with_capacity(work_entries.len());
    for entry in work_entries {
        let ws = WorkStateChunk {
            format_version: ROOT_CHUNK_FORMAT_VERSION,
            be_id: entry.be_id,
            owner: entry.work_ref.owner,
            read_club: entry.work_ref.read_club,
            edit_club: entry.work_ref.edit_club,
            sponsors: entry.work_ref.sponsors.clone(),
            endorsements: entry.work_ref.endorsements.clone(),
            current_edition_hash: entry.work_ref.current_root.root_hash,
            revision_count: entry.work_ref.revision_count,
            history: entry
                .work_ref
                .history
                .iter()
                .map(|(rev_num, edition_ref)| (*rev_num, edition_ref.root_hash))
                .collect(),
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
            revisions: manifest
                .revisions
                .get(&entry.be_id)
                .cloned()
                .unwrap_or_default(),
        };
        let ws_hash = write_work_state_chunk(&ws, chunk_store)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e.to_string()))?;
        work_index_entries.push(WorkIndexEntry {
            format_version: ROOT_CHUNK_FORMAT_VERSION,
            be_id: entry.be_id,
            work_state_hash: ws_hash,
        });
    }

    let works_index_hash = if work_index_entries.is_empty() {
        None
    } else {
        Some(
            write_works_index_chunk(
                &WorksIndexChunk {
                    format_version: ROOT_CHUNK_FORMAT_VERSION,
                    entries: work_index_entries,
                },
                chunk_store,
            )
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e.to_string()))?,
        )
    };

    // ── Clubs: ClubStateChunks + ClubIndexChunk ─────────────────────────────────
    let mut club_index_entries = Vec::with_capacity(manifest.clubs.len());
    for club_ref in &manifest.clubs {
        let cs = ClubStateChunk {
            format_version: ROOT_CHUNK_FORMAT_VERSION,
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
        };
        let cs_hash = write_club_state_chunk(&cs, chunk_store)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e.to_string()))?;
        club_index_entries.push(ClubIndexEntry {
            format_version: ROOT_CHUNK_FORMAT_VERSION,
            be_id: club_ref.be_id,
            club_state_hash: cs_hash,
        });
    }

    let clubs_index_hash = if club_index_entries.is_empty() {
        None
    } else {
        Some(
            write_club_index_chunk(
                &ClubIndexChunk {
                    format_version: ROOT_CHUNK_FORMAT_VERSION,
                    entries: club_index_entries,
                },
                chunk_store,
            )
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e.to_string()))?,
        )
    };

    // ── Standalone Editions ─────────────────────────────────────────────────────
    let standalone_editions_hash = if manifest.standalone_editions.is_empty() {
        None
    } else {
        let entries: Vec<StandaloneEditionEntry> = manifest
            .standalone_editions
            .iter()
            .map(|se| StandaloneEditionEntry {
                format_version: ROOT_CHUNK_FORMAT_VERSION,
                be_id: se.be_id,
                edition_ref_hash: se.edition_ref.root_hash,
            })
            .collect();
        Some(
            write_standalone_editions_chunk(
                &StandaloneEditionsChunk {
                    format_version: ROOT_CHUNK_FORMAT_VERSION,
                    entries,
                },
                chunk_store,
            )
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e.to_string()))?,
        )
    };

    // ── Admin ───────────────────────────────────────────────────────────────────
    let admin_chunk = AdminChunk {
        format_version: ROOT_CHUNK_FORMAT_VERSION,
        admin: manifest.admin.clone(),
        accepting_connections: manifest.admin.accepting_connections,
        shutdown_requested: manifest.admin.shutdown_requested,
        grants: manifest
            .admin
            .grants
            .iter()
            .map(|(id, _, _)| (*id, String::new()))
            .collect(),
        server_name: None,
        server_description: None,
        server_namespace_id: None,
        public_address: None,
    };
    let admin_hash = Some(
        write_admin_chunk(&admin_chunk, chunk_store)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e.to_string()))?,
    );

    // ── System Clubs ────────────────────────────────────────────────────────────
    let sys_chunk = SystemClubsChunk {
        format_version: ROOT_CHUNK_FORMAT_VERSION,
        system_clubs: manifest.system_clubs,
    };
    let system_clubs_hash = Some(
        write_system_clubs_chunk(&sys_chunk, chunk_store)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e.to_string()))?,
    );

    // ── Reconcile Store (federation state, JSON section chunk) ──────────────────
    let reconcile_store_hash =
        crate::persist::manifest::write_section_chunk(chunk_store, &manifest.reconcile_store)
            .map_err(|e| e)?;

    let now = chrono::Utc::now().to_rfc3339();
    let root = ServerRootChunk {
        format_version: ROOT_CHUNK_FORMAT_VERSION,
        sequence: manifest.sequence,
        checkpoint_at: now,
        grand_map_id_counter: manifest.grand_map_id_counter,
        session_counter: manifest.session_counter,
        operation_counter: manifest.operation_counter,
        link_counter: manifest.link_counter,
        works_index_hash,
        clubs_index_hash,
        standalone_editions_hash,
        links_hash: manifest.links_hash.or(manifest.links_chunk_hash),
        social_hash: manifest.social_chunk_hash,
        federation_hash: manifest
            .federation_chunk_hash
            .or(manifest.federation.as_ref().and_then(|_| None)),
        annotations_hash: manifest.annotations_hash,
        blob_metas_hash: manifest.blob_metas_hash.or(manifest.blob_metas_chunk_hash),
        content_address_hash: manifest
            .content_address_hash
            .or(manifest.content_address_chunk_hash),
        historical_authors_hash: manifest
            .historical_authors_hash
            .or(manifest.historical_authors_chunk_hash),
        fossil_snapshots_hash: manifest.fossil_snapshots_hash,
        admin_hash,
        key_history_hash: None,
        system_clubs_hash,
        reconcile_store_hash,
    };

    let root_hash = write_root_chunk(&root, chunk_store)
        .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e.to_string()))?;

    let root_manifest_path = data_dir.join("root_manifest.json");
    let previous_root_hash = if root_manifest_path.exists() {
        match read_root_manifest(&root_manifest_path) {
            Ok(prev) => prev.current_root_hash,
            Err(_) => hash_to_hex(&root_hash),
        }
    } else {
        hash_to_hex(&root_hash)
    };

    let root_manifest = RootManifest {
        current_root_hash: hash_to_hex(&root_hash),
        previous_root_hash: Some(previous_root_hash),
        format_version: ROOT_CHUNK_FORMAT_VERSION,
    };

    write_root_manifest(&root_manifest, &root_manifest_path)?;

    Ok(root_hash)
}

pub fn write_club_state_chunk(
    chunk: &ClubStateChunk,
    store: &ChunkStore,
) -> Result<[u8; 32], RootChunkError> {
    let data = serialize_to_bytes(chunk)?;
    let hash = store.write_chunk(&data)?;
    Ok(hash)
}

pub fn write_club_index_chunk(
    chunk: &ClubIndexChunk,
    store: &ChunkStore,
) -> Result<[u8; 32], RootChunkError> {
    let data = serialize_to_bytes(chunk)?;
    let hash = store.write_chunk(&data)?;
    Ok(hash)
}

pub fn write_standalone_editions_chunk(
    chunk: &StandaloneEditionsChunk,
    store: &ChunkStore,
) -> Result<[u8; 32], RootChunkError> {
    let data = serialize_to_bytes(chunk)?;
    let hash = store.write_chunk(&data)?;
    Ok(hash)
}

pub fn write_admin_chunk(
    chunk: &AdminChunk,
    store: &ChunkStore,
) -> Result<[u8; 32], RootChunkError> {
    let data = serialize_to_bytes(chunk)?;
    let hash = store.write_chunk(&data)?;
    Ok(hash)
}

pub fn write_system_clubs_chunk(
    chunk: &SystemClubsChunk,
    store: &ChunkStore,
) -> Result<[u8; 32], RootChunkError> {
    let data = serialize_to_bytes(chunk)?;
    let hash = store.write_chunk(&data)?;
    Ok(hash)
}

pub fn read_club_state_chunk(
    hash: &[u8; 32],
    store: &ChunkStore,
) -> Result<ClubStateChunk, RootChunkError> {
    let data = store.read_chunk(hash)?;
    deserialize_from_bytes(&data)
}

pub fn read_club_index_chunk(
    hash: &[u8; 32],
    store: &ChunkStore,
) -> Result<ClubIndexChunk, RootChunkError> {
    let data = store.read_chunk(hash)?;
    deserialize_from_bytes(&data)
}

pub fn read_standalone_editions_chunk(
    hash: &[u8; 32],
    store: &ChunkStore,
) -> Result<StandaloneEditionsChunk, RootChunkError> {
    let data = store.read_chunk(hash)?;
    deserialize_from_bytes(&data)
}

pub fn read_admin_chunk(hash: &[u8; 32], store: &ChunkStore) -> Result<AdminChunk, RootChunkError> {
    let data = store.read_chunk(hash)?;
    deserialize_from_bytes(&data)
}

pub fn read_system_clubs_chunk(
    hash: &[u8; 32],
    store: &ChunkStore,
) -> Result<SystemClubsChunk, RootChunkError> {
    let data = store.read_chunk(hash)?;
    deserialize_from_bytes(&data)
}

/// Reconstruct a Manifest from the root chunk tree.
///
/// This reads the ServerRootChunk → WorksIndexChunk → WorkStateChunks,
/// plus all section chunks, and produces a Manifest that the existing
/// restore code can consume without modification.
pub fn read_root_as_manifest(
    root_hash: &[u8; 32],
    store: &ChunkStore,
) -> Result<crate::persist::manifest::Manifest, RootChunkError> {
    let root = read_root_chunk(root_hash, store)?;

    // ── Works ───────────────────────────────────────────────────────────
    let mut all_work_entries = Vec::new();
    if let Some(idx_hash) = root.works_index_hash {
        let idx = read_works_index_chunk(&idx_hash, store)?;
        for entry in idx.entries {
            let ws = read_work_state_chunk(&entry.work_state_hash, store)?;
            let work_chunk_ref = crate::persist::edition_chunks::WorkChunkRef {
                be_id: ws.be_id,
                owner: ws.owner,
                revision_count: ws.revision_count,
                current_root: crate::persist::edition_chunks::EditionChunkRef {
                    root_hash: ws.current_edition_hash,
                    entry_count: 0,
                },
                history: ws
                    .history
                    .into_iter()
                    .map(|(rev, hash)| {
                        (
                            rev,
                            crate::persist::edition_chunks::EditionChunkRef {
                                root_hash: hash,
                                entry_count: 0,
                            },
                        )
                    })
                    .collect(),
                read_club: ws.read_club,
                edit_club: ws.edit_club,
                sponsors: ws.sponsors,
                endorsements: ws.endorsements,
            };
            let work_entry = crate::persist::manifest::WorkEntry {
                be_id: entry.be_id,
                work_ref: work_chunk_ref,
                is_source: ws.is_source,
                source_author_id: ws.source_author_id,
                source_edition_info: ws.source_edition_info,
                content_start_line: ws.content_start_line,
                content_end_line: ws.content_end_line,
                source_fingerprint: ws.source_fingerprint,
                is_archived: ws.is_archived,
                lifecycle_history: ws.lifecycle_history,
                history_club: ws.history_club,
                kind: ws.kind,
                license: ws.license,
                custom_title: ws.custom_title,
            };
            all_work_entries.push(work_entry);
        }
    }

    // ── Clubs ────────────────────────────────────────────────────────────────
    let mut all_club_refs = Vec::new();
    if let Some(idx_hash) = root.clubs_index_hash {
        let idx = read_club_index_chunk(&idx_hash, store)?;
        for entry in idx.entries {
            let cs = read_club_state_chunk(&entry.club_state_hash, store)?;
            let club_ref = crate::persist::manifest::ClubChunkRef {
                be_id: cs.be_id,
                name: cs.name,
                signature_club: cs.signature_club,
                work_root: cs.work_root,
                default_read_club: cs.default_read_club,
                default_edit_club: cs.default_edit_club,
                is_personal: cs.is_personal,
                display_name: cs.display_name,
                credential: cs.credential,
                encrypted_signing_key: cs.encrypted_signing_key,
                email: cs.email,
                verified: cs.verified,
                members: cs.members,
                sponsored_works: cs.sponsored_works,
            };
            all_club_refs.push(club_ref);
        }
    }

    // ── Standalone Editions ───────────────────────────────────────────────
    let mut all_standalone_refs = Vec::new();
    if let Some(se_hash) = root.standalone_editions_hash {
        let se = read_standalone_editions_chunk(&se_hash, store)?;
        for entry in se.entries {
            let ed_ref = crate::persist::edition_chunks::EditionChunkRef {
                root_hash: entry.edition_ref_hash,
                entry_count: 0,
            };
            all_standalone_refs.push(crate::persist::manifest::StandaloneEditionChunkRef {
                be_id: entry.be_id,
                edition_ref: ed_ref,
            });
        }
    }

    // ── Admin ──────────────────────────────────────────────────────────────────
    let (admin_entry, accepting, shutdown, grants, server_name, server_desc, ns_id, pub_addr) =
        if let Some(h) = root.admin_hash {
            match read_admin_chunk(&h, store) {
                Ok(ac) => (
                    ac.admin,
                    ac.accepting_connections,
                    ac.shutdown_requested,
                    ac.grants,
                    ac.server_name,
                    ac.server_description,
                    ac.server_namespace_id,
                    ac.public_address,
                ),
                Err(_) => (
                    crate::persist::manifest::AdminEntry {
                        accepting_connections: false,
                        shutdown_requested: false,
                        grants: vec![],
                    },
                    false,
                    false,
                    vec![],
                    None,
                    None,
                    None,
                    None,
                ),
            }
        } else {
            (
                crate::persist::manifest::AdminEntry {
                    accepting_connections: false,
                    shutdown_requested: false,
                    grants: vec![],
                },
                false,
                false,
                vec![],
                None,
                None,
                None,
                None,
            )
        };

    // ── System Clubs ──────────────────────────────────────────────────────
    let system_clubs = if let Some(h) = root.system_clubs_hash {
        read_system_clubs_chunk(&h, store)
            .ok()
            .map(|sc| sc.system_clubs)
    } else {
        None
    };

    let now = chrono::Utc::now().to_rfc3339();

    // ── Build Manifest ────────────────────────────────────────────────────────
    let manifest = crate::persist::manifest::Manifest {
        format_version: crate::persist::manifest::CURRENT_MANIFEST_VERSION,
        created_at: now.clone(),
        server_version: env!("CARGO_PKG_VERSION", "unknown").to_string(),
        checksum: String::new(),
        sequence: root.sequence,
        manifest_slot: 'a',
        grand_map_id_counter: root.grand_map_id_counter,
        session_counter: root.session_counter,
        operation_counter: root.operation_counter,
        system_clubs: system_clubs.unwrap_or_else(|| crate::server::SystemClubs {
            public_club: crate::edition::backend::BeId::default(),
            admin_club: crate::edition::backend::BeId::default(),
            access_club: crate::edition::backend::BeId::default(),
            empty_club: crate::edition::backend::BeId::default(),
        }),
        works: all_work_entries,
        clubs: all_club_refs,
        standalone_editions: all_standalone_refs,
        admin: admin_entry,
        key_history: None,
        // Section hashes come directly from the root chunk
        links_hash: root.links_hash,
        links: vec![],
        link_counter: root.link_counter,
        links_chunk_hash: root.links_hash,
        reconcile_store: root
            .reconcile_store_hash
            .and_then(|h| crate::persist::manifest::read_section_chunk(store, &h).ok())
            .unwrap_or_default(),
        reconcile_counter: 0,
        federation: None,
        federation_chunk_hash: root.federation_hash,
        content_address_hash: root.content_address_hash,
        content_address: None,
        content_address_chunk_hash: root.content_address_hash,
        blob_metas_hash: root.blob_metas_hash,
        blob_metas_chunk_hash: None,
        blob_metas: vec![],
        historical_authors_hash: root.historical_authors_hash,
        historical_authors_chunk_hash: None,
        historical_authors: None,
        annotations_hash: root.annotations_hash,
        fossil_snapshots_hash: root.fossil_snapshots_hash,
        starred_works: std::collections::HashMap::new(),
        trails: vec![],
        trail_counter: crate::edition::backend::BeId::default(),
        compound_editions: vec![],
        social_chunk_hash: root.social_hash,
        ticket_nonces: std::collections::HashMap::new(),
        revisions: std::collections::HashMap::new(),
    };

    Ok(manifest)
}

fn hash_to_hex(hash: &[u8; 32]) -> String {
    hash.iter().map(|b| format!("{:02x}", b)).collect()
}

// ── Root-tree hash collection (FR-36: GC safety) ────────────────────────────

/// Collect every chunk hash needed to restore from one root tree.
///
/// GC uses this to build its protection set. Errors propagate to the
/// caller, which must skip GC rather than risk deleting valid chunks.
///
/// FIELD CHECKLIST: every `Option<[u8; 32]>` on ServerRootChunk must be
/// inserted below — enforced by `walker_covers_all_root_fields` test.
pub fn collect_root_tree_hashes(
    root_hash: &[u8; 32],
    store: &ChunkStore,
) -> Result<std::collections::HashSet<[u8; 32]>, RootChunkError> {
    use std::collections::HashSet;

    let mut refs: HashSet<[u8; 32]> = HashSet::new();
    let root = read_root_chunk(root_hash, store)?;
    refs.insert(*root_hash);

    // Section-hash fields (all 16, exhaustive).
    for h in [
        root.works_index_hash,
        root.clubs_index_hash,
        root.standalone_editions_hash,
        root.links_hash,
        root.social_hash,
        root.federation_hash,
        root.annotations_hash,
        root.blob_metas_hash,
        root.content_address_hash,
        root.historical_authors_hash,
        root.fossil_snapshots_hash,
        root.admin_hash,
        root.key_history_hash,
        root.system_clubs_hash,
        root.reconcile_store_hash,
    ]
    .into_iter()
    .flatten()
    {
        refs.insert(h);
    }

    // Works: index → work-state chunks → edition subtrees.
    if let Some(idx_hash) = root.works_index_hash {
        let idx = read_works_index_chunk(&idx_hash, store)?;
        refs.insert(idx_hash);
        for entry in &idx.entries {
            refs.insert(entry.work_state_hash);
            let ws = read_work_state_chunk(&entry.work_state_hash, store)?;
            let mut expand = |hash: &[u8; 32], refs: &mut HashSet<[u8; 32]>| {
                let ed_ref = crate::persist::edition_chunks::EditionChunkRef {
                    root_hash: *hash,
                    entry_count: 0,
                };
                match crate::persist::edition_chunks::collect_edition_hashes(&ed_ref, store) {
                    Ok(hashes) => refs.extend(hashes),
                    Err(e) => {
                        tracing::warn!(
                            "root-tree walk: edition chunk collection failed for {}: {}",
                            hash_to_hex(hash),
                            e
                        );
                    }
                }
            };
            expand(&ws.current_edition_hash, &mut refs);
            for (_, h) in &ws.history {
                expand(h, &mut refs);
            }
        }
    }

    // Clubs: index → club-state chunks → work subtrees.
    if let Some(idx_hash) = root.clubs_index_hash {
        let idx = read_club_index_chunk(&idx_hash, store)?;
        refs.insert(idx_hash);
        for entry in &idx.entries {
            refs.insert(entry.club_state_hash);
            let cs = read_club_state_chunk(&entry.club_state_hash, store)?;
            match crate::persist::edition_chunks::collect_work_hashes(&cs.work_root, store) {
                Ok(hashes) => refs.extend(hashes),
                Err(e) => {
                    tracing::warn!(
                        "root-tree walk: club work hash collection failed for club {}: {}",
                        cs.be_id,
                        e
                    );
                }
            }
        }
    }

    // Standalone editions: entry hashes → edition subtrees.
    if let Some(se_hash) = root.standalone_editions_hash {
        let se = read_standalone_editions_chunk(&se_hash, store)?;
        refs.insert(se_hash);
        for entry in &se.entries {
            refs.insert(entry.edition_ref_hash);
            let ed_ref = crate::persist::edition_chunks::EditionChunkRef {
                root_hash: entry.edition_ref_hash,
                entry_count: 0,
            };
            match crate::persist::edition_chunks::collect_edition_hashes(&ed_ref, store) {
                Ok(hashes) => refs.extend(hashes),
                Err(e) => {
                    tracing::warn!(
                        "root-tree walk: standalone edition hash collection failed for {}: {}",
                        cs_id_display(entry.be_id),
                        e
                    );
                }
            }
        }
    }

    Ok(refs)
}

fn cs_id_display(be_id: BeId) -> String {
    be_id.to_string()
}

/// Protect the current and previous root trees named by `root_manifest.json`.
///
/// Returns the union of both trees' hashes. If the root manifest exists but
/// any tree walk fails, returns Err — callers must skip GC entirely.
/// If `root_manifest.json` does not exist, returns an empty set (Ok).
pub fn collect_root_manifest_tree_hashes(
    data_dir: &std::path::Path,
    store: &ChunkStore,
) -> Result<std::collections::HashSet<[u8; 32]>, RootChunkError> {
    use std::collections::HashSet;

    let rm_path = data_dir.join("root_manifest.json");
    if !rm_path.exists() {
        return Ok(HashSet::new());
    }
    let rm = read_root_manifest(&rm_path)
        .map_err(|e| RootChunkError::CorruptData(format!("root_manifest.json: {}", e)))?;

    let mut refs = HashSet::new();
    let current = hex_to_hash(&rm.current_root_hash)?;
    refs.extend(collect_root_tree_hashes(&current, store)?);

    if let Some(prev_hex) = rm.previous_root_hash {
        if let Ok(prev) = hex_to_hash(&prev_hex) {
            if prev != current && store.chunk_exists(&prev) {
                refs.extend(collect_root_tree_hashes(&prev, store)?);
            }
        }
    }
    Ok(refs)
}

fn hex_to_hash(hex: &str) -> Result<[u8; 32], RootChunkError> {
    let bytes = ::hex::decode(hex)
        .map_err(|e| RootChunkError::CorruptData(format!("invalid hex hash: {}", e)))?;
    if bytes.len() != 32 {
        return Err(RootChunkError::CorruptData(format!(
            "hash must be 32 bytes, got {}",
            bytes.len()
        )));
    }
    let mut arr = [0u8; 32];
    arr.copy_from_slice(&bytes);
    Ok(arr)
}

// ── Tests ───────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {

    use super::*;
    use std::path::PathBuf;

    fn temp_dir() -> PathBuf {
        static COUNTER: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
        let id = COUNTER.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        std::env::temp_dir().join(format!(
            "xudanu_root_chunk_test_{}_{}",
            std::process::id(),
            id
        ))
    }

    fn make_test_hash(seed: u8) -> [u8; 32] {
        let mut h = [0u8; 32];
        h[0] = seed;
        h
    }

    // ── WorkStateChunk roundtrip ────────────────────────────────────────

    #[test]
    fn work_state_chunk_roundtrip() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let chunk = WorkStateChunk {
            format_version: 0,
            be_id: 42,
            owner: Some(99),
            read_club: Some(10),
            edit_club: Some(20),
            sponsors: vec![30, 31],
            endorsements: vec![(5, 6)],
            current_edition_hash: make_test_hash(1),
            revision_count: 3,
            history: vec![
                (0, make_test_hash(2)),
                (1, make_test_hash(3)),
                (2, make_test_hash(4)),
            ],
            source_author_id: Some(100),
            source_fingerprint: Some(vec![1, 2, 3]),
            lifecycle_history: vec![crate::edition::work::WorkLifecycleEvent {
                kind: crate::edition::work::LifecycleEventKind::Archived,
                actor_club: 10,
                timestamp: 9999,
            }],
            history_club: Some(50),
            kind: WorkKind::Document,
            license: License::AllRightsReserved,
            custom_title: Some("My Doc".to_string()),
            is_source: true,
            source_edition_info: None,
            content_start_line: Some(1),
            content_end_line: Some(100),
            is_archived: false,
            revisions: vec![],
        };

        let hash = write_work_state_chunk(&chunk, &store).unwrap();
        let restored = read_work_state_chunk(&hash, &store).unwrap();

        assert_eq!(restored.be_id, 42);
        assert_eq!(restored.owner, Some(99));
        assert_eq!(restored.read_club, Some(10));
        assert_eq!(restored.edit_club, Some(20));
        assert_eq!(restored.sponsors, vec![30, 31]);
        assert_eq!(restored.endorsements, vec![(5, 6)]);
        assert_eq!(restored.current_edition_hash, make_test_hash(1));
        assert_eq!(restored.revision_count, 3);
        assert_eq!(restored.history.len(), 3);
        assert_eq!(restored.is_source, true);
        assert_eq!(restored.custom_title, Some("My Doc".to_string()));
        assert_eq!(restored.is_archived, false);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn work_state_chunk_minimal_fields() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let chunk = WorkStateChunk {
            format_version: 0,
            be_id: 1,
            current_edition_hash: make_test_hash(0),
            revision_count: 0,
            history: vec![],
            kind: WorkKind::Document,
            license: License::AllRightsReserved,
            is_source: false,
            is_archived: false,
            endorsements: vec![],
            sponsors: vec![],
            lifecycle_history: vec![],
            revisions: vec![],
            owner: None,
            read_club: None,
            edit_club: None,
            history_club: None,
            source_author_id: None,
            source_fingerprint: None,
            source_edition_info: None,
            content_start_line: None,
            content_end_line: None,
            custom_title: None,
        };

        let hash = write_work_state_chunk(&chunk, &store).unwrap();
        let restored = read_work_state_chunk(&hash, &store).unwrap();

        assert_eq!(restored.be_id, 1);
        assert_eq!(restored.revision_count, 0);
        assert!(restored.history.is_empty());
        assert_eq!(restored.kind, WorkKind::Document);
        assert_eq!(restored.license, License::AllRightsReserved);

        let _ = std::fs::remove_dir_all(&dir);
    }

    // ── WorksIndexChunk roundtrip ──────────────────────────────────────

    #[test]
    fn works_index_chunk_roundtrip() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let chunk = WorksIndexChunk {
            format_version: 1,
            entries: vec![
                WorkIndexEntry {
                    format_version: 0,
                    be_id: 1,
                    work_state_hash: make_test_hash(10),
                },
                WorkIndexEntry {
                    format_version: 0,
                    be_id: 2,
                    work_state_hash: make_test_hash(20),
                },
                WorkIndexEntry {
                    format_version: 0,
                    be_id: 3,
                    work_state_hash: make_test_hash(30),
                },
            ],
        };

        let hash = write_works_index_chunk(&chunk, &store).unwrap();
        let restored = read_works_index_chunk(&hash, &store).unwrap();

        assert_eq!(restored.entries.len(), 3);
        assert_eq!(restored.entries[0].be_id, 1);
        assert_eq!(restored.entries[2].work_state_hash, make_test_hash(30));

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn works_index_chunk_empty() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let chunk = WorksIndexChunk {
            format_version: 0,
            entries: vec![],
        };
        let hash = write_works_index_chunk(&chunk, &store).unwrap();
        let restored = read_works_index_chunk(&hash, &store).unwrap();
        assert!(restored.entries.is_empty());

        let _ = std::fs::remove_dir_all(&dir);
    }

    // ── ServerRootChunk roundtrip ──────────────────────────────────────

    #[test]
    fn server_root_chunk_roundtrip() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let chunk = ServerRootChunk {
            format_version: ROOT_CHUNK_FORMAT_VERSION,
            sequence: 42,
            checkpoint_at: "2026-08-14T12:00:00Z".to_string(),
            grand_map_id_counter: 1000,
            session_counter: 500,
            operation_counter: 10000,
            link_counter: 200,
            works_index_hash: Some(make_test_hash(1)),
            clubs_index_hash: Some(make_test_hash(2)),
            standalone_editions_hash: None,
            links_hash: Some(make_test_hash(3)),
            social_hash: Some(make_test_hash(4)),
            federation_hash: None,
            annotations_hash: None,
            blob_metas_hash: Some(make_test_hash(5)),
            content_address_hash: Some(make_test_hash(6)),
            historical_authors_hash: None,
            fossil_snapshots_hash: None,
            admin_hash: Some(make_test_hash(7)),
            key_history_hash: None,
            system_clubs_hash: Some(make_test_hash(8)),
            reconcile_store_hash: Some(make_test_hash(9)),
        };

        let hash = write_root_chunk(&chunk, &store).unwrap();
        let restored = read_root_chunk(&hash, &store).unwrap();

        assert_eq!(restored.format_version, ROOT_CHUNK_FORMAT_VERSION);
        assert_eq!(restored.sequence, 42);
        assert_eq!(restored.checkpoint_at, "2026-08-14T12:00:00Z");
        assert_eq!(restored.grand_map_id_counter, 1000);
        assert_eq!(restored.works_index_hash, Some(make_test_hash(1)));
        assert_eq!(restored.federation_hash, None);
        assert_eq!(restored.blob_metas_hash, Some(make_test_hash(5)));

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn server_root_chunk_empty_refs() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let chunk = ServerRootChunk {
            format_version: ROOT_CHUNK_FORMAT_VERSION,
            sequence: 0,
            checkpoint_at: String::new(),
            grand_map_id_counter: 0,
            session_counter: 0,
            operation_counter: 0,
            link_counter: 0,
            works_index_hash: None,
            clubs_index_hash: None,
            standalone_editions_hash: None,
            links_hash: None,
            social_hash: None,
            federation_hash: None,
            annotations_hash: None,
            blob_metas_hash: None,
            content_address_hash: None,
            historical_authors_hash: None,
            fossil_snapshots_hash: None,
            admin_hash: None,
            key_history_hash: None,
            system_clubs_hash: None,
            reconcile_store_hash: None,
        };

        let hash = write_root_chunk(&chunk, &store).unwrap();
        let restored = read_root_chunk(&hash, &store).unwrap();

        assert_eq!(restored.format_version, 1);
        assert_eq!(restored.sequence, 0);
        assert!(restored.works_index_hash.is_none());

        let _ = std::fs::remove_dir_all(&dir);
    }

    // ── Format tag verification ────────────────────────────────────────

    #[test]
    fn root_chunk_has_correct_format_tag() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let chunk = ServerRootChunk {
            format_version: ROOT_CHUNK_FORMAT_VERSION,
            sequence: 1,
            checkpoint_at: "test".to_string(),
            grand_map_id_counter: 0,
            session_counter: 0,
            operation_counter: 0,
            link_counter: 0,
            works_index_hash: None,
            clubs_index_hash: None,
            standalone_editions_hash: None,
            links_hash: None,
            social_hash: None,
            federation_hash: None,
            annotations_hash: None,
            blob_metas_hash: None,
            content_address_hash: None,
            historical_authors_hash: None,
            fossil_snapshots_hash: None,
            admin_hash: None,
            key_history_hash: None,
            system_clubs_hash: None,
            reconcile_store_hash: None,
        };

        let hash = write_root_chunk(&chunk, &store).unwrap();
        let data = store.read_chunk(&hash).unwrap();

        assert_eq!(
            data[0], CHUNK_FORMAT_ROOT,
            "first byte should be 0x52 (ROOT format tag)"
        );
        assert_eq!(data.len(), 1 + postcard::to_allocvec(&chunk).unwrap().len());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn wrong_format_tag_rejected() {
        let bad_data = vec![
            CHUNK_FORMAT_POSTCARD, // 0x50, not 0x52
            0x01,
            0x00,
            0x00,
            0x00, // format_version = 1
        ];

        let result = deserialize_from_bytes::<ServerRootChunk>(&bad_data);
        assert!(result.is_err());
        match result.unwrap_err() {
            RootChunkError::WrongFormat {
                expected: 0x52,
                actual: 0x50,
            } => {}
            other => panic!("expected WrongFormat, got: {}", other),
        }
    }

    // ── Content-addressed deduplication ────────────────────────────────

    #[test]
    fn identical_root_chunks_produce_same_hash() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let make_root = || ServerRootChunk {
            format_version: ROOT_CHUNK_FORMAT_VERSION,
            sequence: 99,
            checkpoint_at: "same".to_string(),
            grand_map_id_counter: 0,
            session_counter: 0,
            operation_counter: 0,
            link_counter: 0,
            works_index_hash: None,
            clubs_index_hash: None,
            standalone_editions_hash: None,
            links_hash: None,
            social_hash: None,
            federation_hash: None,
            annotations_hash: None,
            blob_metas_hash: None,
            content_address_hash: None,
            historical_authors_hash: None,
            fossil_snapshots_hash: None,
            admin_hash: None,
            key_history_hash: None,
            system_clubs_hash: None,
            reconcile_store_hash: None,
        };

        let h1 = write_root_chunk(&make_root(), &store).unwrap();
        let h2 = write_root_chunk(&make_root(), &store).unwrap();
        assert_eq!(
            h1, h2,
            "identical root chunks must produce identical hashes"
        );

        let _ = std::fs::remove_dir_all(&dir);
    }

    // ── RootManifest roundtrip ─────────────────────────────────────────

    #[test]
    fn root_manifest_roundtrip() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let manifest = RootManifest {
            current_root_hash: "ab".repeat(32),
            previous_root_hash: Some("cd".repeat(32)),
            format_version: ROOT_CHUNK_FORMAT_VERSION,
        };

        let path = dir.join("root_manifest.json");
        write_root_manifest(&manifest, &path).unwrap();
        let restored = read_root_manifest(&path).unwrap();

        assert_eq!(restored.current_root_hash, "ab".repeat(32));
        assert_eq!(restored.previous_root_hash, Some("cd".repeat(32)));
        assert_eq!(restored.format_version, ROOT_CHUNK_FORMAT_VERSION);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn root_manifest_no_previous() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let manifest = RootManifest {
            current_root_hash: "ef".repeat(32),
            previous_root_hash: None,
            format_version: ROOT_CHUNK_FORMAT_VERSION,
        };

        let path = dir.join("root_manifest.json");
        write_root_manifest(&manifest, &path).unwrap();
        let restored = read_root_manifest(&path).unwrap();

        assert_eq!(restored.current_root_hash, "ef".repeat(32));
        assert!(restored.previous_root_hash.is_none());

        let _ = std::fs::remove_dir_all(&dir);
    }

    // ── Corruption detection ──────────────────────────────────────────

    #[test]
    fn corrupt_root_chunk_detected_on_read() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let chunk = ServerRootChunk {
            format_version: ROOT_CHUNK_FORMAT_VERSION,
            sequence: 1,
            checkpoint_at: "test".to_string(),
            grand_map_id_counter: 0,
            session_counter: 0,
            operation_counter: 0,
            link_counter: 0,
            works_index_hash: None,
            clubs_index_hash: None,
            standalone_editions_hash: None,
            links_hash: None,
            social_hash: None,
            federation_hash: None,
            annotations_hash: None,
            blob_metas_hash: None,
            content_address_hash: None,
            historical_authors_hash: None,
            fossil_snapshots_hash: None,
            admin_hash: None,
            key_history_hash: None,
            system_clubs_hash: None,
            reconcile_store_hash: None,
        };

        let hash = write_root_chunk(&chunk, &store).unwrap();

        let hex = hash
            .iter()
            .map(|b| format!("{:02x}", b))
            .collect::<String>();
        let prefix = &hex[..2];
        let chunk_dir = dir.join("chunks").join(prefix);
        let chunk_file = chunk_dir.join(format!("{}.xchunk", hex));
        std::fs::write(
            &chunk_file,
            b"corrupted data that is not a valid root chunk",
        )
        .unwrap();
        store.clear_cache();

        let result = read_root_chunk(&hash, &store);
        assert!(result.is_err(), "corrupted root chunk should fail to read");
        match result.unwrap_err() {
            RootChunkError::ChunkStore(ChunkError::HashMismatch { .. }) => {}
            other => panic!("expected HashMismatch, got: {}", other),
        }

        let _ = std::fs::remove_dir_all(&dir);
    }

    // ── Previous root fallback ───────────────────────────────────────

    #[test]
    fn previous_root_serves_as_fallback() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let prev_root = ServerRootChunk {
            format_version: ROOT_CHUNK_FORMAT_VERSION,
            sequence: 10,
            checkpoint_at: "prev".to_string(),
            grand_map_id_counter: 0,
            session_counter: 0,
            operation_counter: 0,
            link_counter: 0,
            works_index_hash: None,
            clubs_index_hash: None,
            standalone_editions_hash: None,
            links_hash: None,
            social_hash: None,
            federation_hash: None,
            annotations_hash: None,
            blob_metas_hash: None,
            content_address_hash: None,
            historical_authors_hash: None,
            fossil_snapshots_hash: None,
            admin_hash: None,
            key_history_hash: None,
            system_clubs_hash: None,
            reconcile_store_hash: None,
        };

        let prev_hash = write_root_chunk(&prev_root, &store).unwrap();
        let prev_hash_hex = hash_to_hex(&prev_hash);
        let prev_hash_hex_clone = prev_hash_hex.clone();

        let root_manifest = RootManifest {
            current_root_hash: "ff".repeat(32),
            previous_root_hash: Some(prev_hash_hex),
            format_version: ROOT_CHUNK_FORMAT_VERSION,
        };

        let manifest_path = dir.join("root_manifest.json");
        write_root_manifest(&root_manifest, &manifest_path).unwrap();

        let loaded = read_root_manifest(&manifest_path).unwrap();
        assert_eq!(loaded.current_root_hash, "ff".repeat(32));
        assert_eq!(loaded.previous_root_hash, Some(prev_hash_hex_clone));

        let prev_hash_bytes: [u8; 32] = hex_to_hash(&loaded.previous_root_hash.unwrap()).unwrap();
        let restored = read_root_chunk(&prev_hash_bytes, &store).unwrap();
        assert_eq!(restored.sequence, 10);
        assert_eq!(restored.checkpoint_at, "prev");

        let _ = std::fs::remove_dir_all(&dir);
    }

    // ── Multi-work index + individual work states ────────────────────

    #[test]
    fn full_tree_roundtrip() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let work1 = WorkStateChunk {
            format_version: 0,
            be_id: 1,
            current_edition_hash: make_test_hash(100),
            revision_count: 2,
            history: vec![(0, make_test_hash(101)), (1, make_test_hash(102))],
            kind: WorkKind::Document,
            license: License::CreativeCommonsBy,
            custom_title: Some("Doc One".to_string()),
            is_source: false,
            is_archived: false,
            endorsements: vec![],
            sponsors: vec![],
            lifecycle_history: vec![],
            revisions: vec![],
            owner: None,
            read_club: None,
            edit_club: None,
            history_club: None,
            source_author_id: None,
            source_fingerprint: None,
            source_edition_info: None,
            content_start_line: None,
            content_end_line: None,
        };

        let work2 = WorkStateChunk {
            format_version: 0,
            be_id: 2,
            current_edition_hash: make_test_hash(200),
            revision_count: 0,
            history: vec![],
            kind: WorkKind::Concept,
            license: License::PublicDomain,
            is_source: true,
            is_archived: false,
            endorsements: vec![],
            sponsors: vec![],
            lifecycle_history: vec![],
            revisions: vec![],
            owner: None,
            read_club: None,
            edit_club: None,
            history_club: None,
            source_author_id: None,
            source_fingerprint: None,
            source_edition_info: None,
            content_start_line: None,
            content_end_line: None,
            custom_title: None,
        };

        let work3 = WorkStateChunk {
            format_version: 0,
            be_id: 3,
            current_edition_hash: make_test_hash(44),
            revision_count: 5,
            kind: WorkKind::Note,
            license: License::AllRightsReserved,
            is_archived: true,
            is_source: false,
            history: vec![],
            endorsements: vec![],
            sponsors: vec![],
            lifecycle_history: vec![],
            revisions: vec![],
            owner: None,
            read_club: None,
            edit_club: None,
            history_club: None,
            source_author_id: None,
            source_fingerprint: None,
            source_edition_info: None,
            content_start_line: None,
            content_end_line: None,
            custom_title: None,
        };

        let h1 = write_work_state_chunk(&work1, &store).unwrap();
        let h2 = write_work_state_chunk(&work2, &store).unwrap();
        let h3 = write_work_state_chunk(&work3, &store).unwrap();

        let index = WorksIndexChunk {
            format_version: 0,
            entries: vec![
                WorkIndexEntry {
                    format_version: 0,
                    be_id: 1,
                    work_state_hash: h1,
                },
                WorkIndexEntry {
                    format_version: 0,
                    be_id: 2,
                    work_state_hash: h2,
                },
                WorkIndexEntry {
                    format_version: 0,
                    be_id: 3,
                    work_state_hash: h3,
                },
            ],
        };
        let index_hash = write_works_index_chunk(&index, &store).unwrap();

        let root = ServerRootChunk {
            format_version: ROOT_CHUNK_FORMAT_VERSION,
            sequence: 1,
            checkpoint_at: "2026-08-14T12:00:00Z".to_string(),
            grand_map_id_counter: 1000,
            session_counter: 500,
            operation_counter: 10000,
            link_counter: 200,
            works_index_hash: Some(index_hash),
            links_hash: Some(make_test_hash(50)),
            social_hash: Some(make_test_hash(51)),
            standalone_editions_hash: None,
            clubs_index_hash: None,
            federation_hash: None,
            annotations_hash: None,
            blob_metas_hash: None,
            content_address_hash: None,
            historical_authors_hash: None,
            fossil_snapshots_hash: None,
            admin_hash: None,
            key_history_hash: None,
            system_clubs_hash: None,
            reconcile_store_hash: None,
        };
        let root_hash = write_root_chunk(&root, &store).unwrap();

        let restored_root = read_root_chunk(&root_hash, &store).unwrap();
        assert_eq!(restored_root.sequence, 1);
        assert_eq!(restored_root.works_index_hash, Some(index_hash));

        let restored_index =
            read_works_index_chunk(&restored_root.works_index_hash.unwrap(), &store).unwrap();
        assert_eq!(restored_index.entries.len(), 3);

        let restored_w1 =
            read_work_state_chunk(&restored_index.entries[0].work_state_hash, &store).unwrap();
        assert_eq!(restored_w1.be_id, 1);
        assert_eq!(restored_w1.kind, WorkKind::Document);
        assert_eq!(restored_w1.license, License::CreativeCommonsBy);
        assert_eq!(restored_w1.revision_count, 2);
        assert_eq!(restored_w1.custom_title, Some("Doc One".to_string()));

        let restored_w2 =
            read_work_state_chunk(&restored_index.entries[1].work_state_hash, &store).unwrap();
        assert_eq!(restored_w2.be_id, 2);
        assert_eq!(restored_w2.kind, WorkKind::Concept);
        assert!(restored_w2.is_source);

        let restored_w3 =
            read_work_state_chunk(&restored_index.entries[2].work_state_hash, &store).unwrap();
        assert_eq!(restored_w3.be_id, 3);
        assert!(restored_w3.is_archived);

        let _ = std::fs::remove_dir_all(&dir);
    }

    // ── Helpers ───────────────────────────────────────────────────────

    fn hex_to_hash(hex: &str) -> Option<[u8; 32]> {
        if hex.len() != 64 {
            return None;
        }
        let mut result = [0u8; 32];
        for i in 0..32 {
            result[i] = u8::from_str_radix(&hex[i * 2..i * 2 + 2], 16).ok()?;
        }
        Some(result)
    }

    // ── FR-36: GC safety ───────────────────────────────────────────────

    #[test]
    fn walker_covers_all_root_fields() {
        // FIELD CHECKLIST enforcement: every Option<[u8; 32]> on
        // ServerRootChunk must appear in collect_root_tree_hashes output.
        // Sections that the walker reads (indexes) use real empty chunks;
        // unread section hashes use distinct dummy values.
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        // Readable empty index chunks for the three walked sections.
        let works_idx_hash = write_works_index_chunk(
            &WorksIndexChunk {
                format_version: ROOT_CHUNK_FORMAT_VERSION,
                entries: vec![],
            },
            &store,
        )
        .unwrap();
        let clubs_idx_hash = write_club_index_chunk(
            &ClubIndexChunk {
                format_version: ROOT_CHUNK_FORMAT_VERSION,
                entries: vec![],
            },
            &store,
        )
        .unwrap();
        let standalone_hash = write_standalone_editions_chunk(
            &StandaloneEditionsChunk {
                format_version: ROOT_CHUNK_FORMAT_VERSION,
                entries: vec![],
            },
            &store,
        )
        .unwrap();

        // Distinct dummy hashes for unread sections (seed 1..=12).
        let dummy = |n: u8| {
            let mut h = [0u8; 32];
            h[0] = n;
            h
        };

        let root = ServerRootChunk {
            format_version: ROOT_CHUNK_FORMAT_VERSION,
            sequence: 1,
            checkpoint_at: "2026-08-15T00:00:00Z".into(),
            grand_map_id_counter: 1,
            session_counter: 1,
            operation_counter: 1,
            link_counter: 1,
            works_index_hash: Some(works_idx_hash),
            clubs_index_hash: Some(clubs_idx_hash),
            standalone_editions_hash: Some(standalone_hash),
            links_hash: Some(dummy(1)),
            social_hash: Some(dummy(2)),
            federation_hash: Some(dummy(3)),
            annotations_hash: Some(dummy(4)),
            blob_metas_hash: Some(dummy(5)),
            content_address_hash: Some(dummy(6)),
            historical_authors_hash: Some(dummy(7)),
            fossil_snapshots_hash: Some(dummy(8)),
            admin_hash: Some(dummy(9)),
            key_history_hash: Some(dummy(10)),
            system_clubs_hash: Some(dummy(11)),
            reconcile_store_hash: Some(dummy(12)),
        };
        let root_hash = write_root_chunk(&root, &store).unwrap();

        let refs = collect_root_tree_hashes(&root_hash, &store).unwrap();

        for n in 1u8..=12 {
            assert!(
                refs.contains(&dummy(n)),
                "walker must cover section hash seed {}",
                n
            );
        }
        assert!(refs.contains(&works_idx_hash));
        assert!(refs.contains(&clubs_idx_hash));
        assert!(refs.contains(&standalone_hash));
        assert!(refs.contains(&root_hash));

        let _ = std::fs::remove_dir_all(&dir);
    }
}
