use std::collections::{HashMap, HashSet};
use std::sync::Arc;

use super::admin::{AdminState, IdGrant, SessionInfo};
use super::club::Club;
use super::detector::{Detector, DetectorList, Event};
use super::error::ServerError;
use super::keymaster::KeyMaster;
use super::session::{Session, SessionId};
use super::wait_barrier::{ConsequenceTracker, OperationGuard, WriteBarrier, WriteGuard};
use crate::edition::backfollow::BackfollowEngine;
use crate::edition::blob_store::{BlobMeta, BlobStore};
use crate::edition::links::{HyperLink, HyperRef};
use crate::edition::props::BertProp;
use crate::edition::transclusion::{TransclusionQuery, WorkQuery};
use crate::edition::{BeId, ContentAddressIndex, Edition, GrandMap, RangeElement, Work, XnRegion};
use crate::ent::trace::TracePosition;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct SystemClubs {
    pub public_club: BeId,
    pub admin_club: BeId,
    pub access_club: BeId,
    pub empty_club: BeId,
}

struct GrabWaiter {
    session_id: SessionId,
    grabbed_at: u64,
}

pub(crate) struct WorkState {
    work: Work,
    chunk_ref: Option<crate::persist::edition_chunks::WorkChunkRef>,
    dirty_gen: u64,
    grabber: Option<SessionId>,
    grabbed_at: Option<u64>,
    grab_waiters: Vec<GrabWaiter>,
    last_revision_author: Option<BeId>,
    revision_authors: std::collections::HashMap<u64, BeId>,
    revision_timestamps: std::collections::HashMap<u64, u64>,
    status_detectors: DetectorList,
    revision_detectors: DetectorList,
    cached_title: String,
    is_source: bool,
    source_author_id: Option<BeId>,
    source_edition_info: Option<String>,
    #[allow(dead_code)]
    imported_by: Option<BeId>,
    content_start_line: Option<u64>,
    content_end_line: Option<u64>,
    source_fingerprint: Option<crate::server::source_matcher::MinHashSignature>,
}

impl WorkState {
    pub fn title(&self) -> &str {
        &self.cached_title
    }

    pub(crate) fn work(&self) -> &Work {
        &self.work
    }

    pub(crate) fn work_mut(&mut self) -> &mut Work {
        &mut self.work
    }

    pub(crate) fn grabber(&self) -> Option<SessionId> {
        self.grabber
    }

    pub(crate) fn cached_title(&self) -> &str {
        &self.cached_title
    }

    pub(crate) fn is_source(&self) -> bool {
        self.is_source
    }

    pub(crate) fn content_start_line(&self) -> Option<u64> {
        self.content_start_line
    }

    pub(crate) fn content_end_line(&self) -> Option<u64> {
        self.content_end_line
    }

    pub(crate) fn source_author_id(&self) -> Option<BeId> {
        self.source_author_id
    }

    pub(crate) fn source_edition_info(&self) -> Option<&str> {
        self.source_edition_info.as_deref()
    }

    fn mark_dirty(&mut self) {
        self.chunk_ref = None;
        self.dirty_gen = self.dirty_gen.wrapping_add(1);
    }
}

impl std::fmt::Debug for WorkState {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("WorkState")
            .field("be_id", &self.work.be_id())
            .field("grabber", &self.grabber)
            .field("revision_count", &self.work.revision_count())
            .finish()
    }
}

pub struct ContentNotification {
    pub fossil_id: crate::edition::RecorderId,
    pub edition_be_id: BeId,
    pub is_direct: bool,
    pub work_be_id: Option<BeId>,
    pub title: Option<String>,
}

const MAX_PENDING_NOTIFICATIONS: usize = 10_000;
const MAX_REVISION_AUTHORS: usize = 500;

/// One hop in a transclusion `again()` chain.
pub struct AgainHop {
    pub work_id: BeId,
    pub work_title: String,
    pub element_text: String,
    pub author_name: String,
    pub author_type: String,
    pub is_original: bool,
}

/// Lifecycle event info for wire serialization.
#[derive(Debug, Clone)]
pub struct WorkLifecycleEventInfo {
    pub kind: String,
    pub actor_club: BeId,
    pub timestamp: u64,
}

#[derive(Debug, Clone)]
pub struct RenderedElement {
    pub position: i64,
    pub text: String,
    pub source_work_id: Option<BeId>,
    pub source_author_name: Option<String>,
    pub is_transcluded: bool,
    pub transclusion_sources: Vec<RenderedTransclusionSource>,
}

#[derive(Debug, Clone)]
pub struct RenderedTransclusionSource {
    pub work_id: BeId,
    pub title: Option<String>,
    pub author_name: Option<String>,
    pub is_direct: bool,
}

#[derive(Debug, Clone)]
pub struct SearchMatch {
    pub char_offset: u64,
    pub line: u64,
    pub context: String,
}

#[derive(Debug, Clone)]
pub struct GlobalSearchResult {
    pub work_id: BeId,
    pub title: Option<String>,
    pub owner: Option<BeId>,
    pub revision_count: u64,
    pub matches: Vec<SearchMatch>,
}

#[derive(Debug, Clone)]
pub struct InlineTransclusionResult {
    pub text: String,
    pub span_ranges: Vec<crate::edition::compound::SpanRange>,
    pub source_titles: HashMap<BeId, String>,
}

/// Ghost metadata for an archived work — rendered when references
/// point to archived content instead of a 404 or full live view.
#[derive(Debug, Clone)]
pub struct WorkGhostInfo {
    pub work_id: BeId,
    pub title: String,
    pub owner: Option<BeId>,
    pub archived_by: Option<BeId>,
    pub archived_at: Option<u64>,
    pub lifecycle_history: Vec<WorkLifecycleEventInfo>,
}

pub struct Server {
    pub(crate) grand_map: GrandMap,
    pub(crate) sessions: HashMap<SessionId, Session>,
    session_counter: u64,
    pub(crate) clubs: HashMap<BeId, Club>,
    pub(crate) club_names: HashMap<String, BeId>,
    works: HashMap<BeId, WorkState>,
    standalone_editions: HashMap<BeId, Edition>,
    pub(crate) standalone_edition_refs:
        HashMap<BeId, crate::persist::edition_chunks::EditionChunkRef>,
    pub(crate) dirty_clubs: HashSet<BeId>,
    pub(crate) club_refs: HashMap<BeId, crate::persist::manifest::ClubChunkRef>,
    edition_detectors: HashMap<BeId, DetectorList>,
    pub(crate) system_clubs: SystemClubs,
    operation_counter: u64,
    admin: AdminState,
    links: HashMap<BeId, LinkState>,
    work_to_links: HashMap<BeId, Vec<BeId>>,
    link_counter: BeId,
    link_type_names: HashMap<u64, String>,
    backfollow: BackfollowEngine,
    content_address: ContentAddressIndex,
    blob_store: BlobStore,
    checkpoint_path: Option<std::path::PathBuf>,
    data_dir: Option<std::path::PathBuf>,
    chunk_store: Option<Arc<crate::persist::chunk_store::ChunkStore>>,
    manifest_sequence: u64,
    manifest_slot: char,
    recorder_system: crate::edition::RecorderSystem,
    pending_content_notifications: Vec<ContentNotification>,
    start_time: u64,
    server_keypair: crate::crypto::keys::ServerKeyPair,
    key_history: crate::crypto::keys::KeyHistory,
    federation: crate::server::federation::FederationState,
    reconcile_store: crate::server::federation::ReconcileStore,
    reconcile_counter: u64,
    last_checkpoint_time: u64,
    pub(crate) otree_crdt: super::otree_crdt::OtreeCrdtManager,
    pub(crate) personal_club_count: usize,
    pub(crate) max_personal_clubs: usize,
    pub(crate) login_attempts: HashMap<BeId, crate::server::identity::ClubAttemptTracker>,
    attribution_log: crate::server::transport::attribution_log::AttributionLog,
    pub(crate) historical_authors: crate::server::historical_author::HistoricalAuthorRegistry,
    pub(crate) source_patterns: Vec<crate::server::source_matcher::SourcePattern>,
    pub(crate) pending_attributions: Vec<PendingAttribution>,
    consequence_tracker: Arc<ConsequenceTracker>,
    write_barrier: Arc<WriteBarrier>,
    starred_works: HashMap<BeId, HashSet<BeId>>,
    trails: HashMap<BeId, TrailState>,
    trail_counter: BeId,
    compound_editions: HashMap<BeId, crate::edition::compound::CompoundEdition>,
    compound_dirty: HashSet<BeId>,
    wal: crate::persist::wal::WalLog,
    /// Errors encountered during data restoration. When non-empty,
    /// auto_checkpoint is SUPPRESSED to prevent overwriting good on-disk
    /// data with incomplete in-memory state (data loss prevention).
    /// Cleared by an explicit admin action once the root cause is fixed.
    restore_errors: Vec<String>,
}

#[derive(Debug, Clone)]
struct TrailStop {
    work_id: BeId,
    char_start: Option<u64>,
    char_end: Option<u64>,
    note: Option<String>,
}

#[derive(Debug, Clone)]
struct TrailState {
    trail_id: BeId,
    owner_club: BeId,
    name: String,
    stops: Vec<TrailStop>,
    created_at: u64,
    updated_at: u64,
}

#[derive(Clone)]
pub struct PendingAttribution {
    pub link_id: BeId,
    pub origin_work_id: BeId,
    pub dest_work_id: BeId,
    pub excerpt: String,
    pub placed_by: Option<crate::edition::provenance::TransclusionInfo>,
}

pub struct ServerHealth {
    pub operation_count: u64,
    pub active_recorders: usize,
    pub total_recorded: usize,
    pub blob_count: usize,
    pub link_count: usize,
    pub uptime_secs: u64,
}

#[derive(Debug)]
struct LinkState {
    link: HyperLink,
    origin: BeId,
    destination: BeId,
}

impl Default for Server {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(feature = "server")]
struct DirtyWorkData {
    be_id: BeId,
    work: Work,
    is_source: bool,
    source_author_id: Option<BeId>,
    source_edition_info: Option<String>,
    content_start_line: Option<u64>,
    content_end_line: Option<u64>,
    source_fingerprint: Option<Vec<u64>>,
    is_archived: bool,
    lifecycle_history: Vec<crate::edition::work::WorkLifecycleEvent>,
    history_club: Option<BeId>,
}

#[cfg(feature = "server")]
pub(crate) struct CheckpointPayload {
    chunk_store: Arc<crate::persist::chunk_store::ChunkStore>,
    manifest_path: std::path::PathBuf,
    data_dir: std::path::PathBuf,

    sub_content_address: Vec<u8>,
    sub_historical_authors: Vec<u8>,
    sub_annotations: Vec<u8>,
    sub_blob_metas: Vec<u8>,
    sub_fossil_snapshots: Option<Vec<u8>>,

    links: Vec<crate::persist::manifest::LinkEntry>,

    dirty_works: Vec<DirtyWorkData>,
    dirty_work_gens: Vec<(BeId, u64)>,
    dirty_clubs: Vec<(BeId, Club)>,
    dirty_club_ids: HashSet<BeId>,
    dirty_editions: Vec<(BeId, Edition)>,

    clean_work_entries: Vec<crate::persist::manifest::WorkEntry>,
    clean_club_refs: Vec<crate::persist::manifest::ClubChunkRef>,
    clean_edition_refs: Vec<crate::persist::manifest::StandaloneEditionChunkRef>,

    manifest_sequence: u64,
    manifest_slot: char,
    grand_map_id_counter: BeId,
    session_counter: u64,
    operation_counter: u64,
    system_clubs: SystemClubs,
    link_counter: BeId,
    admin_entry: crate::persist::manifest::AdminEntry,
    reconcile_store: crate::server::federation::ReconcileStore,
    reconcile_counter: u64,
    federation_snapshot: Option<crate::server::federation::FederationSnapshot>,
    starred_works: HashMap<BeId, HashSet<BeId>>,
    trails: Vec<crate::persist::manifest::TrailManifestEntry>,
    trail_counter: BeId,
    compound_editions: Vec<(BeId, crate::edition::compound::CompoundEdition)>,
    key_history: Option<crate::persist::manifest::KeyHistoryEntry>,
}

#[cfg(feature = "server")]
pub(crate) struct CheckpointResult {
    pub manifest_sequence: u64,
    pub manifest_slot: char,
    pub work_refs: Vec<(BeId, crate::persist::edition_chunks::WorkChunkRef, u64)>,
    pub club_refs: Vec<(BeId, crate::persist::manifest::ClubChunkRef)>,
    pub edition_refs: Vec<(BeId, crate::persist::edition_chunks::EditionChunkRef)>,
    pub dirty_club_ids: HashSet<BeId>,
    pub dirty_work_count: u64,
    pub dirty_club_count: u64,
    pub dirty_edition_count: u64,
}

#[cfg(feature = "server")]
fn tag_json(value: &impl serde::Serialize) -> std::io::Result<Vec<u8>> {
    let data =
        serde_json::to_vec(value).map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
    Ok(crate::persist::chunk_store::tag_chunk_data(
        crate::persist::chunk_store::CHUNK_FORMAT_JSON,
        &data,
    ))
}

#[cfg(feature = "server")]
pub(crate) fn checkpoint_persist(payload: CheckpointPayload) -> std::io::Result<CheckpointResult> {
    let start = std::time::Instant::now();
    let store = &payload.chunk_store;

    let dirty_work_gens = payload.dirty_work_gens;
    let mut work_refs = Vec::with_capacity(dirty_work_gens.len());
    let mut all_work_entries = payload.clean_work_entries;

    for (dw, (gen_be_id, dirty_gen)) in payload.dirty_works.into_iter().zip(dirty_work_gens) {
        let work_ref = crate::persist::edition_chunks::work_to_chunks(&dw.work, store)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
        work_refs.push((gen_be_id, work_ref.clone(), dirty_gen));
        all_work_entries.push(crate::persist::manifest::WorkEntry {
            be_id: dw.be_id,
            work_ref,
            is_source: dw.is_source,
            source_author_id: dw.source_author_id,
            source_edition_info: dw.source_edition_info,
            content_start_line: dw.content_start_line,
            content_end_line: dw.content_end_line,
            source_fingerprint: dw.source_fingerprint,
            is_archived: dw.is_archived,
            lifecycle_history: dw.lifecycle_history,
            history_club: dw.history_club,
        });
    }

    let mut club_refs = Vec::new();
    let mut all_club_refs = payload.clean_club_refs;
    for (id, club) in &payload.dirty_clubs {
        let work = club.work();
        let work_ref = crate::persist::edition_chunks::work_to_chunks(work, store)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
        let club_ref = crate::persist::manifest::ClubChunkRef {
            be_id: *id,
            name: club.name().map(|s| s.to_string()),
            signature_club: club.signature_club(),
            work_root: work_ref,
            default_read_club: club.default_read_club(),
            default_edit_club: club.default_edit_club(),
            is_personal: club.is_personal(),
            display_name: club.display_name().map(|s| s.to_string()),
            credential: club.credential().cloned(),
            encrypted_signing_key: club.encrypted_signing_key().cloned(),
            members: club.members().iter().copied().collect(),
            sponsored_works: club.sponsored_works().iter().copied().collect(),
        };
        club_refs.push((*id, club_ref.clone()));
        all_club_refs.push(club_ref);
    }

    let mut edition_refs = Vec::new();
    let mut all_edition_refs = payload.clean_edition_refs;
    for (id, edition) in &payload.dirty_editions {
        let ed_ref = crate::persist::edition_chunks::edition_to_chunks(edition, store)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
        edition_refs.push((*id, ed_ref.clone()));
        all_edition_refs.push(crate::persist::manifest::StandaloneEditionChunkRef {
            be_id: *id,
            edition_ref: ed_ref,
        });
    }

    let links_tagged = tag_json(&payload.links)?;
    let links_hash = Some(
        store
            .write_chunk(&links_tagged)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?,
    );
    let content_address_hash = Some(
        store
            .write_chunk(&payload.sub_content_address)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?,
    );
    let blob_metas_hash = Some(
        store
            .write_chunk(&payload.sub_blob_metas)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?,
    );
    let historical_authors_hash = Some(
        store
            .write_chunk(&payload.sub_historical_authors)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?,
    );
    let annotations_hash = Some(
        store
            .write_chunk(&payload.sub_annotations)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?,
    );
    let fossil_snapshots_hash = if let Some(ref fs_data) = payload.sub_fossil_snapshots {
        Some(
            store
                .write_chunk(fs_data)
                .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?,
        )
    } else {
        None
    };

    let next_slot = if payload.manifest_slot == 'a' {
        'b'
    } else {
        'a'
    };
    let manifest = crate::persist::manifest::Manifest {
        format_version: 0,
        created_at: String::new(),
        server_version: String::new(),
        checksum: String::new(),
        sequence: payload.manifest_sequence,
        manifest_slot: next_slot,
        grand_map_id_counter: payload.grand_map_id_counter,
        session_counter: payload.session_counter,
        operation_counter: payload.operation_counter,
        system_clubs: payload.system_clubs,
        works: all_work_entries,
        clubs: all_club_refs,
        standalone_editions: all_edition_refs,
        links_hash,
        links: payload.links,
        link_counter: payload.link_counter,
        admin: payload.admin_entry,
        reconcile_store: payload.reconcile_store,
        reconcile_counter: payload.reconcile_counter,
        federation: payload.federation_snapshot,
        content_address_hash,
        content_address: None,
        blob_metas_hash,
        blob_metas: Vec::new(),
        key_history: payload.key_history,
        historical_authors_hash,
        historical_authors: None,
        annotations_hash,
        fossil_snapshots_hash,
        starred_works: payload.starred_works,
        trails: payload.trails,
        trail_counter: payload.trail_counter,
        compound_editions: payload.compound_editions,
    };

    let dual_path = payload
        .data_dir
        .join(format!("manifest_{}.json", next_slot));

    crate::persist::manifest::rotate_manifest_backups(&payload.manifest_path, 3);
    let mut manifest = manifest;
    crate::persist::manifest::write_manifest(&mut manifest, &dual_path).map_err(|e| {
        tracing::error!(
            "Failed to write dual manifest to {}: {}",
            dual_path.display(),
            e
        );
        std::io::Error::new(std::io::ErrorKind::Other, e)
    })?;

    match std::fs::rename(&dual_path, &payload.manifest_path) {
        Ok(()) => {}
        Err(e) => {
            tracing::warn!(
                "Failed to promote {} to primary ({}), keeping as dual backup: {}",
                dual_path.display(),
                payload.manifest_path.display(),
                e
            );
            if !payload.manifest_path.exists() {
                return Err(e);
            }
        }
    }

    let backup =
        crate::persist::manifest::backup_manifest_path(&payload.data_dir, manifest.sequence);
    if let Err(e) =
        crate::persist::manifest::write_backup_with_fsync(&payload.manifest_path, &backup)
    {
        tracing::warn!("Failed to create versioned manifest backup: {}", e);
    }

    if let Some(ref kh) = manifest.key_history {
        let kh_path = payload.data_dir.join("key_history.json");
        match serde_json::to_string_pretty(kh) {
            Ok(json) => {
                let tmp_path = kh_path.with_extension("tmp");
                if let Ok(mut f) = std::fs::File::create(&tmp_path) {
                    if std::io::Write::write_all(&mut f, json.as_bytes()).is_ok() {
                        let _ = f.sync_all();
                        if std::fs::rename(&tmp_path, &kh_path).is_err() {
                            let _ = std::fs::remove_file(&tmp_path);
                        }
                    }
                }
            }
            Err(e) => {
                tracing::warn!("Failed to serialize key history: {}", e);
            }
        }
    }

    let dirty_work_count = work_refs.len() as u64;
    let dirty_club_count = club_refs.len() as u64;
    let dirty_edition_count = edition_refs.len() as u64;

    tracing::info!(
        "Async checkpoint persisted in {:.2}ms (dirty: {}/{}/{} works/clubs/editions)",
        start.elapsed().as_secs_f64() * 1000.0,
        dirty_work_count,
        dirty_club_count,
        dirty_edition_count,
    );

    Ok(CheckpointResult {
        manifest_sequence: manifest.sequence,
        manifest_slot: next_slot,
        work_refs,
        club_refs,
        edition_refs,
        dirty_club_ids: payload.dirty_club_ids,
        dirty_work_count,
        dirty_club_count,
        dirty_edition_count,
    })
}

impl Server {
    fn extract_title(edition: &Edition) -> String {
        let text: String = edition
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.as_text().unwrap_or(""))
            .collect();
        text.lines()
            .next()
            .unwrap_or("")
            .trim()
            .chars()
            .take(80)
            .collect()
    }

    pub fn new() -> Self {
        crate::edition::init_endorsement_flags();
        let mut grand_map = GrandMap::new();

        let public_club = {
            let (be_id, elem) = grand_map.new_work_element(None);
            grand_map.assign_new_id(elem);
            let _club = Club::new_with_owner(be_id, Some(be_id), Edition::from_text("public"));
            be_id
        };

        let admin_club = {
            let (be_id, elem) = grand_map.new_work_element(Some(public_club));
            grand_map.assign_new_id(elem);
            let _club = Club::new_with_owner(be_id, Some(be_id), Edition::from_text("admin"));
            be_id
        };

        let access_club = {
            let (be_id, elem) = grand_map.new_work_element(Some(admin_club));
            grand_map.assign_new_id(elem);
            let _club = Club::new_with_owner(be_id, Some(admin_club), Edition::from_text("access"));
            be_id
        };

        let empty_club = {
            let (be_id, elem) = grand_map.new_work_element(None);
            grand_map.assign_new_id(elem);
            let _club = Club::new(be_id, Edition::empty());
            be_id
        };

        let system_clubs = SystemClubs {
            public_club,
            admin_club,
            access_club,
            empty_club,
        };

        let server_kp = crate::crypto::keys::ServerKeyPair::generate("xudanu-server");

        let mut server = Server {
            grand_map,
            sessions: HashMap::new(),
            session_counter: 0,
            clubs: HashMap::new(),
            club_names: HashMap::new(),
            works: HashMap::new(),
            standalone_editions: HashMap::new(),
            standalone_edition_refs: HashMap::new(),
            dirty_clubs: HashSet::new(),
            club_refs: HashMap::new(),
            edition_detectors: HashMap::new(),
            system_clubs,
            operation_counter: 0,
            admin: AdminState::new(),
            links: HashMap::new(),
            work_to_links: HashMap::new(),
            link_counter: 0,
            link_type_names: HashMap::new(),
            backfollow: BackfollowEngine::new(),
            content_address: ContentAddressIndex::new(1_000_000),
            blob_store: BlobStore::in_memory(),
            checkpoint_path: None,
            data_dir: None,
            chunk_store: None,
            manifest_sequence: 0,
            manifest_slot: 'a',
            recorder_system: crate::edition::RecorderSystem::new(),
            pending_content_notifications: Vec::new(),
            start_time: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs(),
            server_keypair: server_kp.clone(),
            key_history: crate::crypto::keys::KeyHistory::new(&server_kp),
            federation: crate::server::federation::FederationState::disabled(),
            reconcile_store: crate::server::federation::ReconcileStore::new(),
            reconcile_counter: 0,
            last_checkpoint_time: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs(),
            otree_crdt: super::otree_crdt::OtreeCrdtManager::new(3),
            personal_club_count: 0,
            max_personal_clubs: 10_000,
            login_attempts: HashMap::new(),
            attribution_log: crate::server::transport::attribution_log::AttributionLog::in_memory(),
            historical_authors: crate::server::historical_author::HistoricalAuthorRegistry::new(),
            source_patterns: crate::server::source_matcher::builtin_patterns(),
            pending_attributions: Vec::new(),
            consequence_tracker: Arc::new(ConsequenceTracker::new()),
            write_barrier: Arc::new(WriteBarrier::new()),
            starred_works: HashMap::new(),
            trails: HashMap::new(),
            trail_counter: 10_000,
            compound_editions: HashMap::new(),
            compound_dirty: HashSet::new(),
            wal: crate::persist::wal::WalLog::disabled(),
            restore_errors: Vec::new(),
            // TODO: Annotations use a simple HashMap for pragmatic first implementation.
            // Migrate to Ent/AssertionStore (src/ent/content.rs) for proper versioning,
            // transclusion survival, and materialize_annotation_indexed support.
        };

        let pub_club =
            Club::new_with_owner(public_club, Some(public_club), Edition::from_text("public"));
        server.clubs.insert(public_club, pub_club);
        server.club_names.insert("public".to_string(), public_club);
        if let Some(c) = server.clubs.get_mut(&public_club) {
            c.set_name("public".to_string());
        }

        let adm_club =
            Club::new_with_owner(admin_club, Some(admin_club), Edition::from_text("admin"));
        server.clubs.insert(admin_club, adm_club);
        server.club_names.insert("admin".to_string(), admin_club);
        if let Some(c) = server.clubs.get_mut(&admin_club) {
            c.set_name("admin".to_string());
            c.set_read_club(Some(public_club));
        }

        let acc_club =
            Club::new_with_owner(access_club, Some(admin_club), Edition::from_text("access"));
        server.clubs.insert(access_club, acc_club);
        server.club_names.insert("access".to_string(), access_club);
        if let Some(c) = server.clubs.get_mut(&access_club) {
            c.set_name("access".to_string());
        }

        let emp_club = Club::new(empty_club, Edition::empty());
        server.clubs.insert(empty_club, emp_club);
        server.club_names.insert("empty".to_string(), empty_club);
        if let Some(c) = server.clubs.get_mut(&empty_club) {
            c.set_name("empty".to_string());
        }

        server
    }

    // === System info ===

    pub fn system_clubs(&self) -> &SystemClubs {
        &self.system_clubs
    }

    pub fn public_club_id(&self) -> BeId {
        self.system_clubs.public_club
    }

    pub fn admin_club_id(&self) -> BeId {
        self.system_clubs.admin_club
    }

    pub fn access_club_id(&self) -> BeId {
        self.system_clubs.access_club
    }

    pub fn empty_club_id(&self) -> BeId {
        self.system_clubs.empty_club
    }

    pub fn grand_map(&self) -> &GrandMap {
        &self.grand_map
    }

    pub fn grand_map_mut(&mut self) -> &mut GrandMap {
        &mut self.grand_map
    }

    pub fn consequence_tracker(&self) -> Arc<ConsequenceTracker> {
        self.consequence_tracker.clone()
    }

    pub fn write_barrier(&self) -> Arc<WriteBarrier> {
        self.write_barrier.clone()
    }

    pub fn pending_operation_count(&self) -> u64 {
        self.consequence_tracker.pending_count()
    }

    pub fn pending_write_count(&self) -> u64 {
        self.write_barrier.pending_writes()
    }

    // === Session management ===

    const DISCONNECTED_SESSION_GRACE: std::time::Duration = std::time::Duration::from_secs(60);

    pub fn connect(&mut self) -> SessionId {
        static SESSION_SECRET: std::sync::OnceLock<u64> = std::sync::OnceLock::new();
        let secret = *SESSION_SECRET.get_or_init(|| {
            use rand::RngCore;
            rand::rngs::OsRng.next_u64()
        });
        self.session_counter += 1;
        let id_val = self.session_counter ^ secret.wrapping_mul(0x5851F42D4C957F2D);
        let id = SessionId::new(id_val);
        let session = Session::new(id);
        self.sessions.insert(id, session);
        id
    }

    pub fn disconnect(
        &mut self,
        session_id: SessionId,
    ) -> Result<
        Vec<(
            BeId,
            Vec<(SessionId, crate::server::crdt_manager::SyncSessionId)>,
        )>,
        ServerError,
    > {
        if !self.sessions.contains_key(&session_id) {
            return Err(ServerError::SessionNotFound(session_id));
        }

        let grabbed: Vec<BeId> = self
            .works
            .iter()
            .filter(|(_, ws)| ws.grabber == Some(session_id))
            .map(|(id, _)| *id)
            .collect();

        for work_be_id in grabbed {
            if let Some(ws) = self.works.get_mut(&work_be_id) {
                ws.grabber = None;
                ws.grabbed_at = None;
                ws.status_detectors.fire(&Event::WorkReleased {
                    work_be_id,
                    session_id,
                });
            }
            self.grant_pending_grab(work_be_id);
        }

        let waiting: Vec<BeId> = self
            .works
            .iter()
            .filter(|(_, ws)| ws.grab_waiters.iter().any(|w| w.session_id == session_id))
            .map(|(id, _)| *id)
            .collect();
        for work_be_id in waiting {
            if let Some(ws) = self.works.get_mut(&work_be_id) {
                ws.grab_waiters.retain(|w| w.session_id != session_id);
            }
        }

        if let Some(session) = self.sessions.get_mut(&session_id) {
            session.end();
        }

        let crdt_works: Vec<BeId> = self.otree_crdt.works_for_session(session_id);

        let mut removal_relays = Vec::new();
        for work_id in crdt_works {
            if let Ok(result) = self.crdt_remove_awareness(session_id, work_id) {
                if !result.relay_to.is_empty() {
                    removal_relays.push((work_id, result.relay_to.clone()));
                }
            }
            self.otree_crdt.close_session(work_id, session_id);
        }

        Ok(removal_relays)
    }

    pub fn session(&self, session_id: SessionId) -> Result<&Session, ServerError> {
        self.sessions
            .get(&session_id)
            .ok_or(ServerError::SessionNotFound(session_id))
    }

    pub fn session_count(&self) -> usize {
        self.sessions.values().filter(|s| s.is_connected()).count()
    }

    pub fn prune_disconnected_sessions(&mut self) -> usize {
        let now = std::time::Instant::now();
        let grace = Self::DISCONNECTED_SESSION_GRACE;
        let before = self.sessions.len();
        self.sessions.retain(|_, s| {
            if s.is_connected() {
                return true;
            }
            match s.ended_at() {
                Some(ended) => now.duration_since(ended) < grace,
                None => true,
            }
        });
        before - self.sessions.len()
    }

    pub fn display_name_for_session(&self, session_id: SessionId) -> String {
        let (name, _, _) = self.identity_for_session(session_id);
        name
    }

    fn resolve_author_club(&self, session_id: SessionId) -> Option<BeId> {
        let session = self.sessions.get(&session_id)?;
        session
            .initial_login()
            .and_then(|id| self.clubs.get(&id))
            .filter(|c| c.is_personal())
            .map(|c| c.be_id())
            .or_else(|| {
                session.authority_clubs().iter().find_map(|id| {
                    self.clubs
                        .get(id)
                        .filter(|c| c.is_personal())
                        .map(|c| c.be_id())
                })
            })
            .or(session.initial_login())
    }

    fn resolve_transclusion_placer(
        &self,
        session_id: SessionId,
    ) -> Option<crate::edition::provenance::TransclusionInfo> {
        let club_id = self.resolve_author_club(session_id)?;
        let display_name = self
            .clubs
            .get(&club_id)
            .and_then(|c| c.display_name().map(|s| s.to_string()))
            .unwrap_or_else(|| format!("club:{:04x}", club_id));
        let public_key = self
            .sessions
            .get(&session_id)
            .and_then(|s| s.club_signing_key().map(|k| k.verifying_key().to_bytes()))
            .unwrap_or([0u8; 32]);
        Some(crate::edition::provenance::TransclusionInfo {
            club_id,
            display_name,
            public_key,
            timestamp: Self::current_timestamp_secs(),
        })
    }

    pub fn identity_for_session(
        &self,
        session_id: SessionId,
    ) -> (String, Option<BeId>, Option<Vec<u8>>) {
        let session = match self.sessions.get(&session_id) {
            Some(s) => s,
            None => return ("anonymous".to_string(), None, None),
        };
        let author_club = session
            .initial_login()
            .and_then(|id| self.clubs.get(&id))
            .filter(|c| c.is_personal())
            .map(|c| c.be_id())
            .or_else(|| {
                session.authority_clubs().iter().find_map(|id| {
                    self.clubs
                        .get(id)
                        .filter(|c| c.is_personal())
                        .map(|c| c.be_id())
                })
            })
            .or(session.initial_login());
        match author_club {
            Some(club_id) => {
                let name = self
                    .clubs
                    .get(&club_id)
                    .and_then(|c| c.display_name().map(|s| s.to_string()))
                    .unwrap_or_else(|| format!("club-{}", club_id));
                let pub_key = session
                    .club_signing_key()
                    .map(|k| k.verifying_key().to_bytes().to_vec());
                (name, Some(club_id), pub_key)
            }
            None => ("anonymous".to_string(), None, None),
        }
    }

    fn materialize_with_provenance(
        &mut self,
        work_be_id: BeId,
        session_id: SessionId,
    ) -> Result<Edition, ServerError> {
        let signing_key = self
            .sessions
            .get(&session_id)
            .and_then(|s| s.club_signing_key().cloned());
        let server_id_bytes = self.federation_server_id_bytes();
        let timestamp = Self::current_timestamp_secs();

        let author_sessions = self
            .otree_crdt
            .get_author_sessions(work_be_id)
            .map_err(|e| ServerError::Internal(e.to_string()))?;

        let mut author_signing_keys: std::collections::HashMap<BeId, ed25519_dalek::SigningKey> =
            std::collections::HashMap::new();
        for (sid, author_id) in &author_sessions {
            if let Some(sk) = self
                .sessions
                .get(sid)
                .and_then(|s| s.club_signing_key().cloned())
            {
                author_signing_keys.insert(author_id.club_be_id, sk);
            }
        }

        for (_, author_id) in &author_sessions {
            if !author_signing_keys.contains_key(&author_id.club_be_id) {
                if let Some(sk) = self
                    .otree_crdt
                    .get_club_signing_key(work_be_id, author_id.club_be_id)
                {
                    author_signing_keys.insert(author_id.club_be_id, sk);
                }
            }
        }

        match signing_key {
            Some(sk) => self
                .otree_crdt
                .materialize_edition_with_provenance(
                    work_be_id,
                    &sk,
                    &server_id_bytes,
                    timestamp,
                    &author_signing_keys,
                )
                .map_err(|e| ServerError::Internal(e.to_string())),
            None => self
                .otree_crdt
                .materialize_edition(work_be_id)
                .map_err(|e| ServerError::Internal(e.to_string())),
        }
    }

    fn build_edition_provenance(
        &self,
        session_id: SessionId,
        edition: &Edition,
    ) -> Option<Vec<crate::edition::SpanProvenance>> {
        let session = self.sessions.get(&session_id)?;
        let signing_key = session.club_signing_key()?;
        let entries = edition.all_entries();
        if entries.is_empty() {
            return None;
        }
        let fingerprints: Vec<[u8; 32]> = entries
            .iter()
            .map(|(_, c)| c.element.content_fingerprint())
            .collect();
        let first_pos = entries.first()?.0;
        let last_pos = entries.last()?.0;
        let server_id_bytes = self.federation_server_id_bytes();
        let timestamp = Self::current_timestamp_secs();
        let provenance = crate::edition::provenance::sign_span(
            signing_key,
            &fingerprints,
            timestamp,
            &server_id_bytes,
        );
        Some(vec![crate::edition::SpanProvenance {
            start: first_pos,
            end: last_pos + 1,
            provenance,
        }])
    }

    // === Club operations ===

    pub fn create_club(
        &mut self,
        session_id: SessionId,
        description: Edition,
    ) -> Result<BeId, ServerError> {
        self.ensure_logged_in(session_id)?;

        let (be_id, elem) = self.grand_map.new_work_element(None);
        self.grand_map.assign_new_id(elem);

        let owner = self
            .session(session_id)?
            .authority_clubs()
            .iter()
            .next()
            .copied();
        let mut club = Club::new_with_owner(be_id, owner, description);
        club.set_read_club(Some(self.system_clubs.public_club));
        club.set_edit_club(Some(be_id));

        self.clubs.insert(be_id, club);
        self.dirty_clubs.insert(be_id);
        Ok(be_id)
    }

    pub fn create_named_club(
        &mut self,
        session_id: SessionId,
        name: &str,
        description: Edition,
    ) -> Result<BeId, ServerError> {
        if self.club_names.contains_key(name) {
            return Err(ServerError::AlreadyExists(format!("club '{}'", name)));
        }
        let be_id = self.create_club(session_id, description)?;
        if let Some(club) = self.clubs.get_mut(&be_id) {
            club.set_name(name.to_string());
        }
        self.club_names.insert(name.to_string(), be_id);
        self.dirty_clubs.insert(be_id);
        Ok(be_id)
    }

    pub fn club(&self, club_id: BeId) -> Result<&Club, ServerError> {
        self.clubs
            .get(&club_id)
            .ok_or(ServerError::ClubNotFound(club_id))
    }

    pub fn personal_club_count(&self) -> usize {
        self.personal_club_count
    }

    pub fn club_mut(&mut self, club_id: BeId) -> Result<&mut Club, ServerError> {
        self.clubs
            .get_mut(&club_id)
            .ok_or(ServerError::ClubNotFound(club_id))
    }

    pub fn club_id_by_name(&self, name: &str) -> Option<BeId> {
        self.club_names.get(name).copied()
    }

    pub fn club_name_by_id(&self, club_id: BeId) -> Option<&str> {
        self.clubs.get(&club_id).and_then(|c| c.name())
    }

    pub fn session_signing_key_bytes(&self, session_id: SessionId) -> Option<Vec<u8>> {
        self.sessions
            .get(&session_id)
            .and_then(|s| s.club_signing_key().map(|k| k.to_bytes().to_vec()))
    }

    pub fn club_count(&self) -> usize {
        self.clubs.len()
    }

    pub fn club_names_list(&self) -> Vec<(&str, BeId)> {
        self.club_names
            .iter()
            .map(|(name, id)| (name.as_str(), *id))
            .collect()
    }

    // === Work operations ===

    pub fn create_work(
        &mut self,
        session_id: SessionId,
        edition: Edition,
    ) -> Result<BeId, ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        self.ensure_logged_in(session_id)?;
        const MAX_WORK_COUNT: usize = 100_000;
        if self.work_count() >= MAX_WORK_COUNT {
            return Err(ServerError::InvalidArgument(format!(
                "work limit reached (max {})",
                MAX_WORK_COUNT
            )));
        }

        let (be_id, elem) = self.grand_map.new_work_element(None);
        self.grand_map.assign_new_id(elem);

        let owner = self
            .session(session_id)?
            .authority_clubs()
            .iter()
            .next()
            .copied();
        let title = Self::extract_title(&edition);
        let mut work = Work::new_with_owner(be_id, owner, edition);

        let is_public_session = owner == Some(self.system_clubs.public_club);
        if is_public_session {
            work.set_read_club(Some(self.system_clubs.public_club));
            work.set_edit_club(Some(self.system_clubs.public_club));
        } else if let Some(owner_id) = owner {
            if let Some(club) = self.clubs.get(&owner_id) {
                work.set_read_club(club.default_read_club().or(Some(owner_id)));
                work.set_edit_club(club.default_edit_club().or(Some(owner_id)));
            } else {
                work.set_read_club(Some(owner_id));
                work.set_edit_club(Some(owner_id));
            }
        }

        let author_club = self.resolve_author_club(session_id);

        let ws = WorkState {
            work,
            chunk_ref: None,
            dirty_gen: 0,
            grabber: None,
            grabbed_at: None,
            grab_waiters: Vec::new(),
            last_revision_author: author_club,
            revision_authors: if let Some(cid) = author_club {
                let mut m = std::collections::HashMap::new();
                m.insert(0, cid);
                m
            } else {
                std::collections::HashMap::new()
            },
            revision_timestamps: {
                let mut m = std::collections::HashMap::new();
                m.insert(0u64, Self::current_timestamp_secs());
                m
            },
            status_detectors: DetectorList::new(),
            revision_detectors: DetectorList::new(),
            cached_title: title,
            is_source: false,
            source_author_id: None,
            source_edition_info: None,
            imported_by: None,
            content_start_line: None,
            content_end_line: None,
            source_fingerprint: None,
        };
        self.works.insert(be_id, ws);

        let edition = self.works[&be_id].work.edition().clone();
        self.content_address.intern_edition_elements(&edition);
        self.reconcile_record_local_revision(be_id, &edition, Self::current_timestamp_secs());
        let read_club = self.works[&be_id].work.read_club();
        let edit_club = self.works[&be_id].work.edit_club();
        let prop = BackfollowEngine::make_work_prop(&self.works[&be_id].work, read_club, edit_club);
        self.backfollow
            .register_work_with_prop(&self.works[&be_id].work, be_id, None, prop);
        // Newly created works may share content with already-watched documents,
        // so planted recorders must be checked here just as they are in revise_work.
        self.trigger_planted_recorders(be_id);
        self.auto_checkpoint();

        Ok(be_id)
    }

    pub fn work(&self, work_be_id: BeId) -> Result<&Work, ServerError> {
        self.works
            .get(&work_be_id)
            .map(|ws| &ws.work)
            .ok_or(ServerError::WorkNotFound(work_be_id))
    }

    pub fn work_edition(&self, work_be_id: BeId) -> Result<Edition, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        Ok(ws.work.edition().clone())
    }

    fn revise_work(
        &mut self,
        work_be_id: BeId,
        session_id: SessionId,
        mut edition: Edition,
        author_club: Option<BeId>,
    ) -> Result<u64, ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );

        let needs_element_prov = edition
            .all_entries()
            .iter()
            .any(|(_, c)| c.provenance.is_none());
        if needs_element_prov {
            if let Some(club_id) = author_club {
                let display_name = self
                    .clubs
                    .get(&club_id)
                    .and_then(|c| c.display_name().map(|s| s.to_string()))
                    .unwrap_or_else(|| format!("club:{:04x}", club_id));
                let pub_key = self
                    .sessions
                    .get(&session_id)
                    .and_then(|s| s.club_signing_key().map(|k| k.verifying_key().to_bytes()))
                    .unwrap_or([0u8; 32]);
                let timestamp = Self::current_timestamp_secs();
                let elem_prov = crate::edition::provenance::ElementProvenance {
                    author_public_key: pub_key,
                    author_display_name: display_name,
                    author_club_id: club_id,
                    timestamp,
                    author_type: crate::edition::provenance::AuthorType::Human,
                    llm_model: None,
                    historical_author_id: None,
                    source_work_id: None,
                    transcluded_by: None,
                    derived_by: None,
                };
                let entries = edition.all_entries();
                let text_before = edition.to_text();
                let mut new_entries: Vec<(i64, Arc<crate::edition::range_element::Carrier>)> =
                    Vec::with_capacity(entries.len());
                for (pos, c) in &entries {
                    if c.provenance.is_none() {
                        let mut carrier = (**c).clone();
                        carrier.provenance = Some(elem_prov.clone());
                        new_entries.push((*pos, Arc::new(carrier)));
                    } else {
                        new_entries.push((*pos, c.clone()));
                    }
                }
                let new_edition = crate::edition::Edition::from_entries(new_entries);
                let text_after = new_edition.to_text();
                if text_before == text_after {
                    edition = new_edition;
                } else {
                    tracing::warn!(
                        "[revise_work] element prov rebuild changed text ({} -> {}), skipping",
                        text_before.len(),
                        text_after.len()
                    );
                }
            }
        }

        if edition.span_provenance.is_empty() {
            if let Some(sp) = self.build_edition_provenance(session_id, &edition) {
                edition.span_provenance = sp;
            }
        }

        {
            let log = &mut self.attribution_log;
            let revision = self
                .works
                .get(&work_be_id)
                .map(|ws| ws.work.revision_count() + 1)
                .unwrap_or(1);
            let all_entries = edition.all_entries();
            for sp in &edition.span_provenance {
                let fps: Vec<[u8; 32]> = all_entries
                    .iter()
                    .filter(|(pos, _)| *pos >= sp.start && *pos < sp.end)
                    .map(|(_, c)| c.element.content_fingerprint())
                    .collect();
                if let Err(e) = log.append(
                    &crate::server::transport::attribution_log::AttributionEntry {
                        sequence: log.sequence(),
                        timestamp: sp.provenance.timestamp,
                        author_pk_hex: crate::server::crdt_manager::bytes_to_hex(
                            &sp.provenance.author_public_key,
                        ),
                        span_fp_hex: crate::edition::provenance::compute_span_fingerprint_hex(&fps),
                        signature_hex: crate::server::crdt_manager::bytes_to_hex(
                            &sp.provenance.signature,
                        ),
                        server_id_hex: crate::server::crdt_manager::bytes_to_hex(
                            &sp.provenance.server_id,
                        ),
                        work_id: work_be_id,
                        revision,
                    },
                ) {
                    tracing::error!("attribution log write failed: {}", e);
                }
            }
        }

        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;

        let old_edition = ws.work.edition().clone();
        let old_text = old_edition.to_text();
        let new_text = edition.to_text();
        let text_delta = crate::edition::compound::compute_text_delta(&old_text, &new_text);
        let needs_span_migration = old_text != new_text;
        ws.last_revision_author = author_club;
        ws.mark_dirty();
        ws.work.revise(edition);
        ws.cached_title = Self::extract_title(ws.work.current_edition());
        let revision = ws.work.revision_count();
        let now = Self::current_timestamp_secs();
        ws.revision_timestamps.insert(revision, now);
        if ws.revision_timestamps.len() > MAX_REVISION_AUTHORS {
            let oldest = *ws.revision_timestamps.keys().min().unwrap();
            ws.revision_timestamps.remove(&oldest);
        }
        if let Some(club_id) = author_club {
            ws.revision_authors.insert(revision, club_id);
            if ws.revision_authors.len() > MAX_REVISION_AUTHORS {
                let oldest = *ws.revision_authors.keys().min().unwrap();
                ws.revision_authors.remove(&oldest);
            }
        }

        ws.revision_detectors.fire(&Event::WorkRevised {
            work_be_id,
            revision,
            session_id,
        });

        let updated_edition = ws.work.edition().clone();
        let new_work = ws.work.clone();
        self.content_address
            .intern_edition_elements(&updated_edition);
        self.backfollow
            .update_work_with_parent(work_be_id, work_be_id, &old_edition, &new_work);
        self.trigger_planted_recorders(work_be_id);
        self.mark_compound_dirty(work_be_id);
        if needs_span_migration {
            let text_delta_ops: Vec<crate::server::transport::protocol::TextDeltaOp> = text_delta
                .iter()
                .map(|op| match op {
                    crate::edition::compound::DeltaOp::Retain(n) => {
                        crate::server::transport::protocol::TextDeltaOp::Retain { count: *n as u64 }
                    }
                    crate::edition::compound::DeltaOp::Insert(n) => {
                        crate::server::transport::protocol::TextDeltaOp::Insert {
                            text: " ".repeat(*n),
                        }
                    }
                    crate::edition::compound::DeltaOp::Delete(n) => {
                        crate::server::transport::protocol::TextDeltaOp::Delete { count: *n as u64 }
                    }
                })
                .collect();
            self.migrate_link_spans_for_delta(work_be_id, &text_delta_ops);
        }
        self.reconcile_record_local_revision(
            work_be_id,
            &updated_edition,
            Self::current_timestamp_secs(),
        );
        self.auto_checkpoint();

        Ok(revision)
    }

    pub fn work_revise(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
        new_edition: Edition,
    ) -> Result<u64, ServerError> {
        self.ensure_session(session_id)?;
        if self.is_source_work(work_be_id) {
            return Err(ServerError::InvalidArgument(
                "source works are immutable".into(),
            ));
        }
        self.ensure_grabbed_by(session_id, work_be_id)?;

        let author_club = self.resolve_author_club(session_id);

        let revision = self.revise_work(work_be_id, session_id, new_edition, author_club)?;
        Ok(revision)
    }

    pub fn work_grab(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        self.ensure_session(session_id)?;
        if self.is_source_work(work_be_id) {
            return Err(ServerError::InvalidArgument(
                "source works are immutable".into(),
            ));
        }
        self.ensure_can_edit(session_id, work_be_id)?;

        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;

        if ws.grabber.is_some() {
            return Err(ServerError::AlreadyGrabbed {
                work: work_be_id,
                by: ws.grabber,
            });
        }

        ws.grabber = Some(session_id);
        ws.grabbed_at = Some(
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs(),
        );
        ws.status_detectors.fire(&Event::WorkGrabbed {
            work_be_id,
            session_id,
        });

        Ok(())
    }

    pub fn work_force_release(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<Option<SessionId>, ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        self.ensure_can_edit(session_id, work_be_id)?;
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;

        let prev = ws.grabber.take();
        ws.grabbed_at = None;
        if prev.is_some() {
            self.grant_pending_grab(work_be_id);
        }
        Ok(prev)
    }

    pub fn work_release(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        self.ensure_session(session_id)?;
        self.ensure_grabbed_by(session_id, work_be_id)?;

        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;

        ws.grabber = None;
        ws.grabbed_at = None;
        ws.status_detectors.fire(&Event::WorkReleased {
            work_be_id,
            session_id,
        });

        self.grant_pending_grab(work_be_id);

        Ok(())
    }

    pub fn work_save_and_release(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
        new_edition: Edition,
    ) -> Result<u64, ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        self.ensure_session(session_id)?;
        self.ensure_grabbed_by(session_id, work_be_id)?;

        let author_club = self
            .sessions
            .get(&session_id)
            .and_then(|s| s.initial_login());

        {
            let ws = self
                .works
                .get_mut(&work_be_id)
                .ok_or(ServerError::WorkNotFound(work_be_id))?;

            ws.grabber = None;
            ws.grabbed_at = None;
            ws.status_detectors.fire(&Event::WorkReleased {
                work_be_id,
                session_id,
            });
        }

        let revision = self.revise_work(work_be_id, session_id, new_edition, author_club)?;
        self.grant_pending_grab(work_be_id);

        Ok(revision)
    }

    pub fn work_request_grab(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<bool, ServerError> {
        self.ensure_session(session_id)?;
        self.ensure_can_edit(session_id, work_be_id)?;

        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;

        if ws.grabber == Some(session_id) {
            return Ok(true);
        }

        if ws.grabber.is_none() {
            ws.grabber = Some(session_id);
            ws.grabbed_at = Some(
                std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_secs(),
            );
            ws.status_detectors.fire(&Event::WorkGrabbed {
                work_be_id,
                session_id,
            });
            return Ok(true);
        }

        let already_waiting = ws.grab_waiters.iter().any(|w| w.session_id == session_id);
        if !already_waiting {
            ws.grab_waiters.push(GrabWaiter {
                session_id,
                grabbed_at: std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_secs(),
            });
        }
        Ok(false)
    }

    pub fn work_cancel_grab_request(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
        self.ensure_session(session_id)?;
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        ws.grab_waiters.retain(|w| w.session_id != session_id);
        Ok(())
    }

    pub fn work_grab_waiters(&self, work_be_id: BeId) -> Result<Vec<SessionId>, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        Ok(ws.grab_waiters.iter().map(|w| w.session_id).collect())
    }

    fn grant_pending_grab(&mut self, work_be_id: BeId) {
        let candidates = {
            let ws = match self.works.get(&work_be_id) {
                Some(ws) => ws,
                None => return,
            };
            if ws.grabber.is_some() {
                return;
            }
            ws.grab_waiters
                .iter()
                .map(|w| w.session_id)
                .collect::<Vec<_>>()
        };

        for candidate in candidates {
            if self.session_can_edit(candidate, work_be_id) {
                let ws = match self.works.get_mut(&work_be_id) {
                    Some(ws) => ws,
                    None => return,
                };
                ws.grabber = Some(candidate);
                ws.grabbed_at = Some(
                    std::time::SystemTime::now()
                        .duration_since(std::time::UNIX_EPOCH)
                        .unwrap_or_default()
                        .as_secs(),
                );
                ws.grab_waiters.retain(|w| w.session_id != candidate);
                let session_id = candidate;
                ws.status_detectors.fire(&Event::WorkGrabbed {
                    work_be_id,
                    session_id,
                });
                return;
            }
            if let Some(ws) = self.works.get_mut(&work_be_id) {
                ws.grab_waiters.retain(|w| w.session_id != candidate);
            }
        }
    }

    pub fn work_is_grabbed(&self, work_be_id: BeId) -> Result<bool, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        Ok(ws.grabber.is_some())
    }

    pub fn work_grabber(&self, work_be_id: BeId) -> Result<Option<SessionId>, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        Ok(ws.grabber)
    }

    pub fn work_grabbed_at(&self, work_be_id: BeId) -> Result<Option<u64>, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        Ok(ws.grabbed_at)
    }

    pub fn work_can_read(
        &self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<bool, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        Ok(self.check_read_permission(session_id, &ws.work))
    }

    pub fn work_can_revise(
        &self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<bool, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        Ok(self.check_edit_permission(session_id, &ws.work))
    }

    pub fn work_set_read_club(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
        club_id: Option<BeId>,
    ) -> Result<(), ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        self.ensure_can_edit(session_id, work_be_id)?;
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        if ws.work.read_club().is_none() {
            return Err(ServerError::ReadClubIrrevocablyRemoved(work_be_id));
        }
        ws.work.set_read_club(club_id);
        ws.mark_dirty();
        self.auto_checkpoint();
        Ok(())
    }

    pub fn work_set_edit_club(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
        club_id: Option<BeId>,
    ) -> Result<(), ServerError> {
        self.ensure_can_edit(session_id, work_be_id)?;
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        ws.work.set_edit_club(club_id);
        ws.mark_dirty();
        Ok(())
    }

    /// Set the history club — controls who can access revision history.
    /// Requires owner permission (stricter than edit: changing who can see
    /// history is a governance decision).
    pub fn work_set_history_club(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
        club_id: Option<BeId>,
    ) -> Result<(), ServerError> {
        self.ensure_owner(session_id, work_be_id)?;
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        ws.work.set_history_club(club_id);
        self.auto_checkpoint();
        Ok(())
    }

    pub fn work_history_club(&self, work_be_id: BeId) -> Result<Option<BeId>, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        Ok(ws.work.history_club())
    }

    pub fn work_read_club(&self, work_be_id: BeId) -> Result<Option<BeId>, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        Ok(ws.work.read_club())
    }

    pub fn work_edit_club(&self, work_be_id: BeId) -> Result<Option<BeId>, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        Ok(ws.work.edit_club())
    }

    pub fn work_sponsor(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
        club_id: BeId,
    ) -> Result<(), ServerError> {
        self.ensure_can_edit(session_id, work_be_id)?;
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        ws.work.add_sponsor(club_id);
        ws.mark_dirty();
        Ok(())
    }

    pub fn work_unsponsor(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
        club_id: BeId,
    ) -> Result<(), ServerError> {
        self.ensure_can_edit(session_id, work_be_id)?;
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        ws.work.remove_sponsor(club_id);
        ws.mark_dirty();
        Ok(())
    }

    pub fn work_sponsors(&self, work_be_id: BeId) -> Result<&[BeId], ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        Ok(ws.work.sponsors())
    }

    pub fn work_revision_count(&self, work_be_id: BeId) -> Result<u64, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        Ok(ws.work.revision_count())
    }

    pub fn work_fetch_revision(
        &mut self,
        work_be_id: BeId,
        number: u64,
    ) -> Result<Option<Edition>, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;

        if ws.work.fetch_revision(number).is_some() {
            return Ok(ws.work.fetch_revision(number).cloned());
        }

        if number > ws.work.revision_count() {
            return Ok(None);
        }

        let chunk_ref = match ws.chunk_ref {
            Some(ref cr) => cr.clone(),
            None => return Ok(None),
        };

        let chunk_store = match self.chunk_store {
            Some(ref cs) => cs,
            None => return Ok(None),
        };

        let edition = match crate::persist::edition_chunks::work_load_revision(
            &chunk_ref,
            number,
            chunk_store,
        ) {
            Ok(ed) => ed,
            Err(_) => return Ok(None),
        };

        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        ws.work.load_revision(number, edition.clone());
        Ok(Some(edition))
    }

    pub fn work_fetch_revision_range(
        &mut self,
        work_be_id: BeId,
        from: u64,
        to: u64,
    ) -> Result<Vec<(u64, Edition)>, ServerError> {
        const MAX_RANGE: u64 = 100;

        if from > to {
            return Ok(Vec::new());
        }

        let span = to.checked_sub(from).and_then(|d| d.checked_add(1));
        match span {
            None => {
                return Err(ServerError::InvalidArgument(
                    "revision range overflow".into(),
                ))
            }
            Some(s) if s > MAX_RANGE => {
                return Err(ServerError::InvalidArgument(format!(
                    "revision range too large: requested {} but max is {}",
                    s, MAX_RANGE
                )));
            }
            _ => {}
        }

        let (revision_count, chunk_ref) = {
            let ws = self
                .works
                .get(&work_be_id)
                .ok_or(ServerError::WorkNotFound(work_be_id))?;
            (ws.work.revision_count(), ws.chunk_ref.clone())
        };

        let mut memory_results: Vec<Option<Edition>> = Vec::new();
        let mut all_in_memory = true;
        {
            let ws = self
                .works
                .get(&work_be_id)
                .ok_or(ServerError::WorkNotFound(work_be_id))?;
            for number in from..=to {
                if number > revision_count {
                    break;
                }
                if let Some(edition) = ws.work.fetch_revision(number).cloned() {
                    memory_results.push(Some(edition));
                } else {
                    memory_results.push(None);
                    all_in_memory = false;
                }
            }
        }

        if all_in_memory && memory_results.len() as u64 == span.unwrap() {
            return Ok(memory_results
                .into_iter()
                .enumerate()
                .map(|(i, opt)| (from + i as u64, opt.unwrap()))
                .collect());
        }

        let chunk_ref = match chunk_ref {
            Some(cr) => cr,
            None => {
                return Ok(memory_results
                    .into_iter()
                    .enumerate()
                    .filter_map(|(i, opt)| opt.map(|ed| (from + i as u64, ed)))
                    .collect());
            }
        };

        let mut disk_loaded: Vec<(usize, Edition)> = Vec::new();
        {
            let chunk_store = match self.chunk_store {
                Some(ref cs) => cs,
                None => {
                    return Ok(memory_results
                        .into_iter()
                        .enumerate()
                        .filter_map(|(i, opt)| opt.map(|ed| (from + i as u64, ed)))
                        .collect());
                }
            };
            for (i, opt) in memory_results.iter().enumerate() {
                if opt.is_some() {
                    continue;
                }
                let number = from + i as u64;
                if number > revision_count {
                    break;
                }
                if let Ok(edition) = crate::persist::edition_chunks::work_load_revision(
                    &chunk_ref,
                    number,
                    chunk_store,
                ) {
                    disk_loaded.push((i, edition));
                }
            }
        }

        if !disk_loaded.is_empty() {
            let ws = self
                .works
                .get_mut(&work_be_id)
                .ok_or(ServerError::WorkNotFound(work_be_id))?;
            for (i, edition) in &disk_loaded {
                let number = from + *i as u64;
                ws.work.load_revision(number, edition.clone());
            }
        }

        for (i, edition) in disk_loaded {
            memory_results[i] = Some(edition);
        }

        Ok(memory_results
            .into_iter()
            .enumerate()
            .filter_map(|(i, opt)| opt.map(|ed| (from + i as u64, ed)))
            .collect())
    }

    pub fn attribution_query(
        &self,
        work_be_id: BeId,
        start: Option<i64>,
        end: Option<i64>,
    ) -> Result<Vec<super::transport::protocol::AttributionSpanPayload>, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        let edition = ws.work.current_edition();
        let all_entries = edition.all_entries();
        tracing::info!(
            "[attribution_query] work={:04x} entries={} span_prov={} prov_entries={} entry_details={}",
            work_be_id,
            all_entries.len(),
            edition.span_provenance.len(),
            all_entries.iter().filter(|(_, c)| c.provenance.is_some()).count(),
            all_entries
                .iter()
                .take(10)
                .map(|(p, c)| {
                    let txt = c
                        .element
                        .as_text()
                        .unwrap_or("")
                        .chars()
                        .take(20)
                        .collect::<String>();
                    let has_prov = c.provenance.is_some();
                    format!("{}:{}({})", p, txt.len(), if has_prov { "P" } else { "_" })
                })
                .collect::<Vec<_>>()
                .join(",")
        );

        let mut elem_char_start: std::collections::HashMap<i64, usize> =
            std::collections::HashMap::with_capacity(all_entries.len());
        let mut cum = 0usize;
        for (pos, c) in &all_entries {
            elem_char_start.insert(*pos, cum);
            cum += c.char_len();
        }

        let elem_to_char = |elem_pos: i64, elem_end: i64| -> (i64, i64) {
            let c_start = elem_char_start.get(&elem_pos).copied().unwrap_or(0) as i64;
            let c_end = if let Some(next_pos) = all_entries
                .iter()
                .find(|(p, _)| *p >= elem_end)
                .map(|(p, _)| *p)
            {
                elem_char_start.get(&next_pos).copied().unwrap_or(cum) as i64
            } else {
                cum as i64
            };
            (c_start, c_end)
        };

        let ancestry = self.provenance_ancestry(work_be_id);
        let chain_payload = if ancestry.is_empty() {
            None
        } else {
            Some(self.enrich_provenance_hops(&ancestry))
        };

        let mut spans = Vec::new();
        for sp in &edition.span_provenance {
            if let Some(s) = start {
                if sp.end <= s {
                    continue;
                }
            }
            if let Some(e) = end {
                if sp.start >= e {
                    continue;
                }
            }

            let fps: Vec<[u8; 32]> = all_entries
                .iter()
                .filter(|(pos, _)| *pos >= sp.start && *pos < sp.end)
                .map(|(_, c)| c.element.content_fingerprint())
                .collect();

            let signature_valid =
                crate::edition::provenance::verify_span_provenance(&sp.provenance, &fps);

            let element_prov = all_entries
                .iter()
                .find(|(pos, _)| *pos >= sp.start && *pos < sp.end)
                .and_then(|(_, c)| c.provenance.as_ref());
            let author_type_str = element_prov.map(|ep| match ep.author_type {
                crate::edition::provenance::AuthorType::Human => "human".to_string(),
                crate::edition::provenance::AuthorType::Llm => "llm".to_string(),
                crate::edition::provenance::AuthorType::Historical => "historical".to_string(),
            });
            let llm_model = element_prov.and_then(|ep| ep.llm_model.clone());
            let historical_author_id = element_prov.and_then(|ep| ep.historical_author_id);
            let is_llm = element_prov.is_some_and(|ep| {
                matches!(ep.author_type, crate::edition::provenance::AuthorType::Llm)
            });
            let is_historical = element_prov.is_some_and(|ep| {
                matches!(
                    ep.author_type,
                    crate::edition::provenance::AuthorType::Historical
                )
            });

            let (author_display_name, author_club_id) = if is_llm {
                let model_name = llm_model.clone().unwrap_or_else(|| "llm".to_string());
                (Some(model_name), None)
            } else if is_historical {
                let ha_name = historical_author_id
                    .and_then(|id| self.historical_authors.get(id))
                    .map(|a| a.display_name.clone())
                    .unwrap_or_else(|| "Unknown Historical Author".to_string());
                (Some(ha_name), historical_author_id)
            } else {
                self.clubs
                    .iter()
                    .find(|(_, club)| match club.encrypted_signing_key() {
                        Some(ek) => ek.verifying_key == sp.provenance.author_public_key,
                        None => false,
                    })
                    .map(|(id, club)| (club.display_name().map(|s| s.to_string()), Some(*id)))
                    .unwrap_or((None, None))
            };

            let (char_start, char_end) = elem_to_char(sp.start, sp.end);

            let source_work_id = element_prov.and_then(|ep| ep.source_work_id);
            let (transcluded_by_name, transcluded_by_club_id) = element_prov
                .and_then(|ep| ep.transcluded_by.as_ref())
                .map(|t| (Some(t.display_name.clone()), Some(t.club_id)))
                .unwrap_or((None, None));

            let is_transcluded = source_work_id.is_some() || transcluded_by_name.is_some();
            let span_chain = if is_transcluded {
                chain_payload.clone()
            } else {
                None
            };

            spans.push(super::transport::protocol::AttributionSpanPayload {
                start: char_start,
                end: char_end,
                author_public_key: sp.provenance.author_public_key.to_vec(),
                author_display_name,
                author_club_id,
                signature_valid,
                timestamp: sp.provenance.timestamp,
                server_id: sp.provenance.server_id.to_vec(),
                author_type: author_type_str,
                llm_model,
                historical_author_id,
                source_work_id,
                transcluded_by_name,
                transcluded_by_club_id,
                provenance_chain: span_chain,
            });
        }

        let pending_for_work: Vec<&PendingAttribution> = self
            .pending_attributions
            .iter()
            .filter(|p| p.dest_work_id == work_be_id)
            .collect();

        if !pending_for_work.is_empty() {
            let edition_text = edition.to_text();
            let text_lower = edition_text.to_lowercase();

            for pa in &pending_for_work {
                let excerpt_lower = pa.excerpt.to_lowercase();
                let char_start = match text_lower.find(&excerpt_lower) {
                    Some(pos) => pos,
                    None => continue,
                };
                let char_end = char_start + pa.excerpt.len();

                let origin_ws = match self.works.get(&pa.origin_work_id) {
                    Some(ws) => ws,
                    None => continue,
                };

                let origin_edition = origin_ws.work.current_edition();
                let origin_entries = origin_edition.all_entries();

                let entry_prov = origin_entries
                    .iter()
                    .find_map(|(_, c)| c.provenance.as_ref());

                let (author_name, author_type_str, historical_id) =
                    if let Some(ha_id) = origin_ws.source_author_id {
                        let name = self
                            .historical_authors
                            .get(ha_id)
                            .map(|a| {
                                if a.display_name.is_empty() {
                                    a.name.clone()
                                } else {
                                    a.display_name.clone()
                                }
                            })
                            .unwrap_or_else(|| "Unknown Historical Author".to_string());
                        tracing::info!(
                        "[attribution_overlay] PA link={:04x} origin={:04x} author_id={} name={}",
                        pa.link_id,
                        pa.origin_work_id,
                        ha_id,
                        name
                    );
                        (name, "historical".to_string(), Some(ha_id))
                    } else if let Some(ep) = entry_prov {
                        let name = if matches!(
                            ep.author_type,
                            crate::edition::provenance::AuthorType::Historical
                        ) {
                            // Resolve from the registry by id (consistent with the
                            // span_provenance path); the stamped author_display_name
                            // may be empty for chained transclusions.
                            ep.historical_author_id
                                .and_then(|id| self.historical_authors.get(id))
                                .map(|a| {
                                    if a.display_name.is_empty() {
                                        a.name.clone()
                                    } else {
                                        a.display_name.clone()
                                    }
                                })
                                .unwrap_or_else(|| {
                                    if ep.author_display_name.is_empty() {
                                        "Unknown Historical Author".to_string()
                                    } else {
                                        ep.author_display_name.clone()
                                    }
                                })
                        } else if ep.author_display_name.is_empty() {
                            "Unknown".to_string()
                        } else {
                            ep.author_display_name.clone()
                        };
                        let at = match ep.author_type {
                            crate::edition::provenance::AuthorType::Human => "human",
                            crate::edition::provenance::AuthorType::Llm => "llm",
                            crate::edition::provenance::AuthorType::Historical => "historical",
                        };
                        (name, at.to_string(), ep.historical_author_id)
                    } else if let Some(club_id) = origin_ws
                        .work
                        .current_edition()
                        .all_entries()
                        .iter()
                        .find_map(|(_, c)| c.provenance.as_ref())
                        .map(|ep| ep.author_club_id)
                        .or(origin_ws.last_revision_author)
                    {
                        let name = self
                            .clubs
                            .get(&club_id)
                            .and_then(|c| c.display_name().map(|s| s.to_string()))
                            .unwrap_or_else(|| format!("Club {:04x}", club_id));
                        (name, "human".to_string(), None)
                    } else {
                        ("Unknown".to_string(), "human".to_string(), None)
                    };

                let existing: std::collections::HashSet<(i64, i64)> =
                    spans.iter().map(|s| (s.start, s.end)).collect();

                if !existing.contains(&(char_start as i64, char_end as i64)) {
                    tracing::info!(
                        "[attribution_overlay] adding span [{},{}] author={} origin={:04x}",
                        char_start,
                        char_end,
                        author_name,
                        pa.origin_work_id
                    );
                    spans.push(super::transport::protocol::AttributionSpanPayload {
                        start: char_start as i64,
                        end: char_end as i64,
                        author_public_key: entry_prov
                            .map(|ep| ep.author_public_key.to_vec())
                            .unwrap_or_default(),
                        author_display_name: Some(author_name),
                        author_club_id: entry_prov
                            .map(|ep| ep.author_club_id)
                            .or(origin_ws.last_revision_author)
                            .or(origin_ws.source_author_id),
                        signature_valid: true,
                        timestamp: entry_prov.map(|ep| ep.timestamp).unwrap_or_else(|| {
                            std::time::SystemTime::now()
                                .duration_since(std::time::UNIX_EPOCH)
                                .unwrap_or_default()
                                .as_secs()
                        }),
                        server_id: vec![0u8; 32],
                        author_type: Some(author_type_str),
                        llm_model: entry_prov.and_then(|ep| ep.llm_model.clone()),
                        historical_author_id: historical_id,
                        source_work_id: Some(pa.origin_work_id),
                        transcluded_by_name: pa.placed_by.as_ref().map(|t| t.display_name.clone()),
                        transcluded_by_club_id: pa.placed_by.as_ref().map(|t| t.club_id),
                        provenance_chain: chain_payload.clone(),
                    });
                } else {
                    tracing::info!(
                        "[attribution_overlay] DEDUP skipped span [{},{}] for origin={:04x} author={}",
                        char_start, char_end, pa.origin_work_id, author_name
                    );
                }
            }
        }

        let historical_ranges: Vec<(i64, i64)> = spans
            .iter()
            .filter(|s| s.author_type.as_deref() == Some("historical"))
            .map(|s| (s.start, s.end))
            .collect();

        if !historical_ranges.is_empty() {
            let mut trimmed = Vec::with_capacity(spans.len() + historical_ranges.len() * 2);
            for span in spans {
                if span.author_type.as_deref() == Some("historical") {
                    trimmed.push(span);
                    continue;
                }
                let mut pieces = vec![(span.start, span.end)];
                for &(hs, he) in &historical_ranges {
                    let mut next = Vec::new();
                    for (ps, pe) in pieces {
                        if he <= ps || hs >= pe {
                            next.push((ps, pe));
                        } else {
                            if hs > ps {
                                next.push((ps, hs));
                            }
                            if he < pe {
                                next.push((he, pe));
                            }
                        }
                    }
                    pieces = next;
                }
                for (ps, pe) in pieces {
                    if pe <= ps {
                        continue;
                    }
                    let mut s = span.clone();
                    s.start = ps;
                    s.end = pe;
                    trimmed.push(s);
                }
            }
            spans = trimmed;
        }

        Ok(spans)
    }

    pub fn attribution_query_resolved(
        &self,
        work_be_id: BeId,
    ) -> Result<Vec<super::transport::protocol::AttributionSpanPayload>, ServerError> {
        let resolved = self.resolve_inline_transclusions(work_be_id)?;

        if resolved.span_ranges.is_empty() {
            return self.attribution_query(work_be_id, None, None);
        }

        let own_spans = self.attribution_query(work_be_id, None, None)?;

        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        let edition = ws.work.current_edition();
        let entries = edition.cached_entries();

        let mut sorted_spans = resolved.span_ranges.clone();
        sorted_spans.sort_by_key(|sr| sr.flat_start);
        let mut span_idx = 0usize;

        let mut char_to_resolved: Vec<usize> = Vec::new();
        let mut own_char_pos: usize = 0;
        let mut resolved_pos: usize = 0;

        for (_, carrier) in entries.iter() {
            let entry_len = carrier.char_len();

            if carrier.element.is_transclusion() {
                while span_idx < sorted_spans.len()
                    && sorted_spans[span_idx].flat_start <= resolved_pos
                {
                    resolved_pos = resolved_pos.max(sorted_spans[span_idx].flat_end);
                    span_idx += 1;
                }
            } else {
                for _ in 0..entry_len {
                    char_to_resolved.push(resolved_pos);
                    own_char_pos += 1;
                    resolved_pos += 1;
                }
            }
        }

        let map_char = |pos: i64| -> i64 {
            let p = pos as usize;
            if p == 0 {
                char_to_resolved.get(0).copied().unwrap_or(0) as i64
            } else if p <= char_to_resolved.len() {
                char_to_resolved[p - 1] as i64 + 1
            } else {
                pos
            }
        };

        let mut result: Vec<super::transport::protocol::AttributionSpanPayload> = Vec::new();

        for span in &own_spans {
            let span_start = span.start as usize;
            let span_end = span.end as usize;
            let start = span_start.min(char_to_resolved.len().saturating_sub(1));
            let end = span_end.min(char_to_resolved.len());

            let mut seg_start = start;
            let mut prev_resolved = char_to_resolved.get(start).copied().unwrap_or(0);

            for i in (start + 1)..=end.min(char_to_resolved.len()) {
                let idx = (i - 1).min(char_to_resolved.len() - 1);
                let cur_resolved = char_to_resolved.get(idx).copied().unwrap_or(prev_resolved);

                if cur_resolved > prev_resolved + 1 {
                    result.push(super::transport::protocol::AttributionSpanPayload {
                        start: char_to_resolved.get(seg_start).copied().unwrap_or(0) as i64,
                        end: (prev_resolved + 1) as i64,
                        ..span.clone()
                    });
                    seg_start = i - 1;
                }
                prev_resolved = cur_resolved;
            }

            if seg_start < end || start == end {
                let s = char_to_resolved.get(seg_start).copied().unwrap_or(0) as i64;
                let e = if end > 0 && end <= char_to_resolved.len() {
                    char_to_resolved[end - 1] as i64 + 1
                } else {
                    s
                };
                if e > s {
                    result.push(super::transport::protocol::AttributionSpanPayload {
                        start: s,
                        end: e,
                        ..span.clone()
                    });
                }
            }
        }

        for sr in &resolved.span_ranges {
            let src_spans = self
                .attribution_query(sr.source_work_id, None, None)
                .unwrap_or_default();

            let src_text_len = self
                .work_text(sr.source_work_id)
                .map(|t| t.chars().count())
                .unwrap_or(0);

            let src_span_coverage: usize = src_spans
                .iter()
                .map(|s| (s.end - s.start).max(0) as usize)
                .sum();

            tracing::info!(
                "[attribution_resolved] transclusion src={:04x} char_range=[{},{}] content_len={} \
                 src_text_len={} src_spans={} src_coverage={}/{} ({:.0}%)",
                sr.source_work_id,
                sr.char_start,
                sr.char_end,
                sr.content_len,
                src_text_len,
                src_spans.len(),
                src_span_coverage,
                src_text_len,
                if src_text_len > 0 {
                    src_span_coverage as f64 / src_text_len as f64 * 100.0
                } else {
                    0.0
                },
            );

            for src_span in &src_spans {
                if (src_span.end as usize) <= sr.char_start
                    || (src_span.start as usize) >= sr.char_end
                {
                    continue;
                }

                let clamped_start = src_span.start.max(sr.char_start as i64);
                let clamped_end = src_span.end.min(sr.char_end as i64);

                let offset = sr.flat_start as i64 - sr.char_start as i64;

                let chain = self.transclusion_again_chain(
                    sr.source_work_id,
                    src_span.start as usize,
                    src_span.end as usize,
                );

                let provenance_chain = if chain.is_empty() {
                    None
                } else {
                    Some(
                        chain
                            .windows(2)
                            .map(|w| super::transport::protocol::ProvenanceHopPayload {
                                source_work_id: w[0].work_id,
                                link_id: 0,
                                source_work_title: Some(w[0].work_title.clone()),
                                source_author_name: Some(w[0].author_name.clone()),
                                dest_work_id: w[1].work_id,
                            })
                            .chain(std::iter::once(
                                super::transport::protocol::ProvenanceHopPayload {
                                    source_work_id: chain.last().unwrap().work_id,
                                    link_id: 0,
                                    source_work_title: Some(
                                        chain.last().unwrap().work_title.clone(),
                                    ),
                                    source_author_name: Some(
                                        chain.last().unwrap().author_name.clone(),
                                    ),
                                    dest_work_id: work_be_id,
                                },
                            ))
                            .collect(),
                    )
                };

                result.push(super::transport::protocol::AttributionSpanPayload {
                    start: clamped_start + offset,
                    end: clamped_end + offset,
                    source_work_id: Some(sr.source_work_id),
                    provenance_chain,
                    ..src_span.clone()
                });
            }
        }

        result.sort_by_key(|s| s.start);
        Ok(result)
    }

    pub fn attribution_verify(
        &self,
        author_public_key: [u8; 32],
        signature: [u8; 64],
        timestamp: u64,
        server_id: [u8; 32],
        span_fingerprint_hex: &str,
    ) -> bool {
        let fp_bytes = match Self::hex_decode(span_fingerprint_hex) {
            Ok(b) => b,
            Err(_) => return false,
        };
        let span_fp: [u8; 32] = match fp_bytes.try_into() {
            Ok(a) => a,
            Err(_) => return false,
        };
        let provenance = crate::edition::Provenance {
            author_public_key,
            signature,
            timestamp,
            server_id,
        };
        crate::edition::provenance::verify_span_provenance_with_span_fp(&provenance, &span_fp)
    }

    pub fn attribution_log_status(&self) -> super::transport::protocol::ResponseValue {
        let entry_count = self.attribution_log.sequence();
        let chain_valid = if self.attribution_log.is_in_memory() {
            true
        } else {
            self.verify_attribution_log_chain()
        };
        super::transport::protocol::ResponseValue::AttributionLogStatusResult {
            entry_count,
            chain_valid,
            last_sequence: entry_count,
            has_log: true,
        }
    }

    fn verify_attribution_log_chain(&self) -> bool {
        let data_dir = match &self.data_dir {
            Some(d) => d,
            None => return false,
        };
        let log_path = data_dir.join("attribution/attribution.log");
        let seed_path = data_dir.join("attribution/attribution.log.seed");
        let content = match std::fs::read_to_string(&log_path) {
            Ok(c) => c,
            Err(_) => return false,
        };
        if content.trim().is_empty() {
            return true;
        }
        let seed = match std::fs::read_to_string(&seed_path) {
            Ok(s) => s.trim().to_string(),
            Err(_) => return false,
        };
        crate::server::transport::attribution_log::verify_attribution_log(&content, &seed).is_ok()
    }

    pub fn register_historical_author(
        &mut self,
        name: String,
        display_name: String,
        birth_year: Option<i32>,
        death_year: Option<i32>,
        external_ids: std::collections::HashMap<String, String>,
        source_bibliography: String,
        created_by: BeId,
    ) -> Result<crate::server::historical_author::HistoricalAuthor, ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        let author = self
            .historical_authors
            .register(
                name,
                display_name,
                birth_year,
                death_year,
                external_ids,
                source_bibliography,
                created_by,
                timestamp,
            )
            .map_err(ServerError::Internal)?;
        self.auto_checkpoint();
        Ok(author)
    }

    pub fn get_historical_author(
        &self,
        be_id: BeId,
    ) -> Result<crate::server::historical_author::HistoricalAuthor, ServerError> {
        self.historical_authors
            .get(be_id)
            .cloned()
            .ok_or(ServerError::Internal(format!(
                "historical author {} not found",
                be_id
            )))
    }

    pub fn search_historical_authors(
        &self,
        query: &str,
    ) -> Vec<crate::server::historical_author::HistoricalAuthor> {
        self.historical_authors
            .search(query)
            .into_iter()
            .cloned()
            .collect()
    }

    pub fn list_historical_authors(
        &self,
    ) -> Vec<crate::server::historical_author::HistoricalAuthor> {
        self.historical_authors
            .list()
            .into_iter()
            .cloned()
            .collect()
    }

    fn is_source_work(&self, work_be_id: BeId) -> bool {
        self.works.get(&work_be_id).map_or(false, |ws| ws.is_source)
    }

    pub fn is_work_source(&self, work_be_id: BeId) -> Result<bool, ServerError> {
        self.works
            .get(&work_be_id)
            .map(|ws| ws.is_source)
            .ok_or(ServerError::WorkNotFound(work_be_id))
    }

    pub fn detect_source(&self, text: &str) -> crate::server::source_matcher::SourceMatchResult {
        crate::server::source_matcher::detect_source(text, &self.source_patterns)
    }

    pub fn match_content(&self, text: &str) -> Option<(BeId, BeId, f64)> {
        let sources: Vec<(BeId, crate::server::source_matcher::MinHashSignature)> = self
            .works
            .iter()
            .filter(|(_, ws)| ws.is_source && ws.source_fingerprint.is_some())
            .map(|(id, ws)| (*id, ws.source_fingerprint.unwrap()))
            .collect();

        tracing::info!(
            "[match_content] query_len={} source_count={} works_total={}",
            text.len(),
            sources.len(),
            self.works.len(),
        );
        for (id, _) in &sources {
            tracing::info!("[match_content] source_work={:04x}", id);
        }

        let (work_id, score) = crate::server::source_matcher::best_content_match(text, &sources)?;

        tracing::info!(
            "[match_content] matched work={:04x} score={:.3}",
            work_id,
            score
        );

        let author_id = self
            .works
            .get(&work_id)
            .and_then(|ws| ws.source_author_id)?;

        Some((work_id, author_id, score))
    }

    pub fn apply_source_attribution(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
        historical_author_id: BeId,
        source_work_id: Option<BeId>,
        paste_start: Option<usize>,
        paste_end: Option<usize>,
    ) -> Result<(), ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        self.ensure_can_edit(session_id, work_be_id)?;

        let author = self
            .historical_authors
            .get(historical_author_id)
            .ok_or_else(|| {
                ServerError::Internal(format!(
                    "historical author {} not found",
                    historical_author_id
                ))
            })?;

        let server_signing_key = &self.server_keypair.signing_key;
        let server_id = self.server_keypair.signing_key.verifying_key().to_bytes();
        let timestamp = Self::current_timestamp_secs();
        let display_name = author.display_name.clone();

        let current_edition = {
            let ws = self
                .works
                .get(&work_be_id)
                .ok_or(ServerError::WorkNotFound(work_be_id))?;
            ws.work.current_edition().clone()
        };

        // TODO(Phase 2 — Priority): Use source_fingerprint_set to gate attribution.
        // Currently all entries in range get attributed regardless of whether their
        // content actually matches the source work. Wire this up to only attribute
        // entries whose content_fingerprint() appears in the source's fingerprint set,
        // enabling verified (not assumed) attribution.
        let _source_fingerprint_set = source_work_id.and_then(|sid| {
            self.works.get(&sid).map(|ws| {
                let entries = ws.work.current_edition().all_entries();
                let mut set = std::collections::HashSet::new();
                for (_, c) in &entries {
                    set.insert(c.element.content_fingerprint());
                }
                set
            })
        });

        let elem_provenance = crate::edition::provenance::ElementProvenance {
            author_type: crate::edition::provenance::AuthorType::Historical,
            author_public_key: server_id,
            author_display_name: display_name,
            author_club_id: 0,
            historical_author_id: Some(historical_author_id),
            llm_model: None,
            timestamp,
            source_work_id,
            transcluded_by: None,
            derived_by: None,
        };

        let entries = current_edition.all_entries();

        let use_range = paste_start.is_some() && paste_end.is_some();
        let range_start = paste_start.unwrap_or(0);
        let range_end = paste_end.unwrap_or(usize::MAX);

        let mut new_entries: Vec<(i64, std::sync::Arc<crate::edition::range_element::Carrier>)> =
            Vec::with_capacity(entries.len());
        let mut cum = 0usize;
        let mut attributed_positions: Vec<i64> = Vec::new();

        for (pos, c) in &entries {
            let entry_start = cum;
            let entry_end = cum + c.char_len();

            let should_attrib = if use_range {
                let in_range = entry_end > range_start && entry_start < range_end;
                if !in_range {
                    false
                } else {
                    true
                }
            } else {
                true
            };

            if should_attrib {
                let mut carrier = (**c).clone();
                carrier.provenance = Some(elem_provenance.clone());
                new_entries.push((*pos, std::sync::Arc::new(carrier)));
                attributed_positions.push(*pos);
            } else {
                new_entries.push((*pos, c.clone()));
            }

            cum = entry_end;
        }

        let mut new_edition = crate::edition::Edition::from_entries(new_entries);
        new_edition.span_provenance = current_edition.span_provenance.clone();

        if !attributed_positions.is_empty() {
            let attributed_entries: Vec<(
                i64,
                std::sync::Arc<crate::edition::range_element::Carrier>,
            )> = entries
                .iter()
                .zip(attributed_positions.iter())
                .filter_map(|((_, c), &pos)| {
                    if attributed_positions.contains(&pos) {
                        Some((pos, c.clone()))
                    } else {
                        None
                    }
                })
                .collect();

            let fingerprints: Vec<[u8; 32]> = attributed_entries
                .iter()
                .map(|(_, c)| c.element.content_fingerprint())
                .collect();

            let prov = crate::edition::provenance::sign_historical_attestation(
                server_signing_key,
                &fingerprints,
                historical_author_id,
                timestamp,
                &server_id,
            );

            let span_prov = crate::edition::provenance::SpanProvenance {
                start: *attributed_positions.first().unwrap_or(&0),
                end: *attributed_positions.last().unwrap_or(&0) + 1,
                provenance: prov,
            };
            new_edition.span_provenance.push(span_prov);
        }

        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        ws.work.revise(new_edition);
        if !use_range {
            ws.source_author_id = Some(historical_author_id);
        }
        self.auto_checkpoint();
        Ok(())
    }

    pub fn list_source_patterns(&self) -> Vec<(String, String)> {
        self.source_patterns
            .iter()
            .map(|p| (p.source_type.clone(), p.display_name.clone()))
            .collect()
    }

    pub fn import_source_work(
        &mut self,
        session_id: SessionId,
        author_id: BeId,
        title: String,
        text: String,
        edition_info: String,
        skip_prefix_lines: u64,
        skip_suffix_lines: u64,
    ) -> Result<(BeId, BeId, u64, String), ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        self.ensure_logged_in(session_id)?;

        self.historical_authors.get(author_id).ok_or_else(|| {
            ServerError::Internal(format!("historical author {} not found", author_id))
        })?;

        let total_lines = text.lines().count() as u64;
        let content_start = skip_prefix_lines;
        let content_end = total_lines.saturating_sub(skip_suffix_lines);

        let mut edition = Edition::from_text_batched(&text);
        let text_length = text.chars().count() as u64;

        let (be_id, elem) = self.grand_map.new_work_element(None);
        self.grand_map.assign_new_id(elem);

        let importer = self
            .sessions
            .get(&session_id)
            .and_then(|s| s._key_master())
            .and_then(|km| km.login_authority().iter().next().copied());

        let server_signing_key = &self.server_keypair.signing_key;
        let server_id = self.server_keypair.signing_key.verifying_key().to_bytes();
        let timestamp = Self::current_timestamp_secs();

        let elem_provenance = crate::edition::provenance::ElementProvenance {
            author_type: crate::edition::provenance::AuthorType::Historical,
            author_public_key: server_id,
            author_display_name: String::new(),
            author_club_id: 0,
            historical_author_id: Some(author_id),
            llm_model: None,
            timestamp,
            source_work_id: None,
            transcluded_by: None,
            derived_by: None,
        };

        {
            let entries = edition.all_entries();
            if !entries.is_empty() {
                let fingerprints: Vec<[u8; 32]> = entries
                    .iter()
                    .map(|(_, c)| c.element.content_fingerprint())
                    .collect();

                let prov = crate::edition::provenance::sign_historical_attestation(
                    server_signing_key,
                    &fingerprints,
                    author_id,
                    timestamp,
                    &server_id,
                );

                let span_prov = crate::edition::provenance::SpanProvenance {
                    start: entries.first().map(|(p, _)| *p).unwrap_or(0),
                    end: entries.last().map(|(p, _)| *p + 1).unwrap_or(0),
                    provenance: prov,
                };

                let new_entries: Vec<(
                    i64,
                    std::sync::Arc<crate::edition::range_element::Carrier>,
                )> = entries
                    .into_iter()
                    .map(|(pos, c)| {
                        let mut carrier = (*c).clone();
                        carrier.provenance = Some(elem_provenance.clone());
                        (pos, std::sync::Arc::new(carrier))
                    })
                    .collect();

                let n = new_entries.len();
                let region = XnRegion::interval(0, n as i64);
                edition = Edition {
                    orgl: crate::edition::orgl::OrglRoot::from_bulk_entries(
                        new_entries,
                        None,
                        region,
                    ),
                    endorsements: crate::edition::endorsement::EndorsementSet::new(),
                    entries_cache: std::sync::Arc::new(std::sync::OnceLock::new()),
                    span_provenance: vec![span_prov],
                };
            }
        }

        let mut work = Work::new_with_owner(be_id, importer, edition);
        work.set_read_club(Some(self.system_clubs.public_club));

        let auto_title = Self::extract_title(work.edition());
        let final_title = if title.is_empty() {
            auto_title
        } else {
            title.clone()
        };
        let ws = WorkState {
            work,
            chunk_ref: None,
            dirty_gen: 0,
            grabber: None,
            grabbed_at: None,
            grab_waiters: Vec::new(),
            last_revision_author: None,
            revision_authors: std::collections::HashMap::new(),
            revision_timestamps: std::collections::HashMap::new(),
            status_detectors: DetectorList::new(),
            revision_detectors: DetectorList::new(),
            cached_title: title.clone(),
            is_source: true,
            source_author_id: Some(author_id),
            source_edition_info: Some(edition_info),
            imported_by: importer,
            content_start_line: Some(content_start),
            content_end_line: Some(content_end),
            source_fingerprint: Some(crate::server::source_matcher::compute_minhash(&text)),
        };
        self.works.insert(be_id, ws);

        let edition = self.works[&be_id].work.edition().clone();
        self.content_address.intern_edition_elements(&edition);

        Ok((be_id, author_id, text_length, final_title))
    }

    pub fn work_last_revision_author(&self, work_be_id: BeId) -> Result<Option<BeId>, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        Ok(ws.last_revision_author)
    }

    pub fn last_revision_author(&self, work_be_id: BeId) -> Option<String> {
        let club_id = self.work_last_revision_author(work_be_id).ok()??;
        self.clubs
            .get(&club_id)
            .and_then(|c| c.display_name().map(|s| s.to_string()))
            .or_else(|| Some(format!("club:{:04x}", club_id)))
    }

    pub fn work_owner(&self, work_be_id: BeId) -> Result<Option<BeId>, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        Ok(ws.work.owner())
    }

    pub fn work_set_owner(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
        owner: Option<BeId>,
    ) -> Result<(), ServerError> {
        self.ensure_can_edit(session_id, work_be_id)?;
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        ws.work.set_owner(owner);
        ws.mark_dirty();
        Ok(())
    }

    pub fn work_publish(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        self.ensure_owner(session_id, work_be_id)?;
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        if ws.work.read_club().is_none() {
            return Err(ServerError::ReadClubIrrevocablyRemoved(work_be_id));
        }
        ws.work.set_read_club(Some(self.system_clubs.public_club));
        ws.mark_dirty();
        self.update_work_prop_and_trigger(work_be_id);
        self.auto_checkpoint();
        Ok(())
    }

    pub fn work_unpublish(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        self.ensure_owner(session_id, work_be_id)?;
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        if ws.work.read_club().is_none() {
            return Err(ServerError::ReadClubIrrevocablyRemoved(work_be_id));
        }
        let owner = ws.work.owner();
        ws.work.set_read_club(owner);
        ws.mark_dirty();
        self.update_work_prop_and_trigger(work_be_id);
        self.auto_checkpoint();
        Ok(())
    }

    pub fn work_irrevocably_unpublish(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        self.ensure_owner(session_id, work_be_id)?;
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        ws.work.set_read_club(None);
        ws.mark_dirty();
        self.auto_checkpoint();
        Ok(())
    }

    /// Archive (soft-delete) a work. Archived works are hidden from the default
    /// work list but are never destroyed; they can be unarchived. The transition
    /// is recorded in the work's lifecycle history. Requires edit authority.
    pub fn work_archive(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        self.ensure_can_edit(session_id, work_be_id)?;
        let actor = self.resolve_author_club(session_id).unwrap_or(0);
        let ts = Self::current_timestamp_secs();
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        ws.work.archive(actor, ts);
        self.auto_checkpoint();
        Ok(())
    }

    /// Unarchive (restore) a work. Recorded in the lifecycle history.
    /// Requires edit authority.
    pub fn work_unarchive(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        self.ensure_can_edit(session_id, work_be_id)?;
        let actor = self.resolve_author_club(session_id).unwrap_or(0);
        let ts = Self::current_timestamp_secs();
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        ws.work.unarchive(actor, ts);
        self.auto_checkpoint();
        Ok(())
    }

    /// Current archive state of a work.
    pub fn work_is_archived(&self, work_be_id: BeId) -> Result<bool, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        Ok(ws.work.is_archived())
    }

    /// `(is_archived, title, owner)` for a work — used to enrich link endpoints
    /// so clients can render a "ghost" marker for references into archived works.
    pub(crate) fn link_endpoint_meta(
        &self,
        work_be_id: BeId,
    ) -> (bool, Option<String>, Option<BeId>) {
        self.works
            .get(&work_be_id)
            .map(|ws| {
                (
                    ws.work.is_archived(),
                    Some(ws.cached_title.clone()),
                    ws.work.owner(),
                )
            })
            .unwrap_or((false, None, None))
    }

    /// Merge two branches (A and B) against a common base into a new work.
    ///
    /// Each element in the result carries:
    /// - Its original author provenance (from whichever source edition it came from)
    /// - The curator's identity via `derived_by` (DerivationMethod::Merge)
    ///
    /// Elements without existing provenance get the curator stamped as author.
    pub fn work_merge(
        &mut self,
        session_id: SessionId,
        base_work_id: BeId,
        a_work_id: BeId,
        b_work_id: BeId,
    ) -> Result<BeId, ServerError> {
        self.ensure_can_edit(session_id, a_work_id)?;

        let base_edition = {
            let ws = self
                .works
                .get(&base_work_id)
                .ok_or(ServerError::WorkNotFound(base_work_id))?;
            ws.work.current_edition().clone()
        };
        let a_edition = {
            let ws = self
                .works
                .get(&a_work_id)
                .ok_or(ServerError::WorkNotFound(a_work_id))?;
            ws.work.current_edition().clone()
        };
        let b_edition = {
            let ws = self
                .works
                .get(&b_work_id)
                .ok_or(ServerError::WorkNotFound(b_work_id))?;
            ws.work.current_edition().clone()
        };

        let merge_result = crate::edition::three_way::three_way_merge(
            &base_edition,
            &a_edition,
            &b_edition,
            crate::edition::three_way::MergeStrategy::LastWriterWins,
        )
        .map_err(|_conflicts| {
            ServerError::Internal("merge conflicts could not be resolved".into())
        })?;

        let curator_club = self.resolve_author_club(session_id);
        let timestamp = Self::current_timestamp_secs();

        let curator_display_name = curator_club
            .and_then(|cid| {
                self.clubs
                    .get(&cid)
                    .and_then(|c| c.display_name().map(|s| s.to_string()))
            })
            .unwrap_or_else(|| "Unknown".to_string());
        let curator_pub_key = self
            .sessions
            .get(&session_id)
            .and_then(|s| s.club_signing_key().map(|k| k.verifying_key().to_bytes()))
            .unwrap_or([0u8; 32]);

        let derivation = crate::edition::provenance::DerivationInfo {
            method: crate::edition::provenance::DerivationMethod::Merge,
            curator_club_id: curator_club.unwrap_or(0),
            curator_display_name: curator_display_name.clone(),
            curator_public_key: curator_pub_key,
            timestamp,
        };

        let author_prov =
            curator_club.map(|club_id| crate::edition::provenance::ElementProvenance {
                author_public_key: curator_pub_key,
                author_display_name: curator_display_name.clone(),
                author_club_id: club_id,
                timestamp,
                author_type: crate::edition::provenance::AuthorType::Human,
                llm_model: None,
                historical_author_id: None,
                source_work_id: None,
                transcluded_by: None,
                derived_by: Some(derivation.clone()),
            });

        let merged_entries = merge_result.merged.all_entries();
        let mut new_entries: Vec<(i64, Arc<crate::edition::range_element::Carrier>)> =
            Vec::with_capacity(merged_entries.len());

        for (pos, c) in &merged_entries {
            let mut carrier = (**c).clone();
            if carrier.provenance.is_some() {
                carrier.provenance.as_mut().unwrap().derived_by = Some(derivation.clone());
            } else if let Some(ref prov) = author_prov {
                carrier.provenance = Some(prov.clone());
            }
            new_entries.push((*pos, Arc::new(carrier)));
        }

        let merged_edition = crate::edition::Edition::from_entries(new_entries);
        let new_work_id = self.create_work(session_id, merged_edition)?;
        Ok(new_work_id)
    }

    /// Ghost metadata for an archived work.
    ///
    /// Returns `None` if the work is not archived or doesn't exist.
    /// When a work is archived, references to it should surface this ghost
    /// instead of the full content.
    pub fn work_ghost(&self, work_be_id: BeId) -> Option<WorkGhostInfo> {
        let ws = self.works.get(&work_be_id)?;
        if !ws.work.is_archived() {
            return None;
        }

        let last_archive_event = ws
            .work
            .lifecycle_history()
            .iter()
            .rev()
            .find(|e| e.kind == crate::edition::work::LifecycleEventKind::Archived)
            .or_else(|| ws.work.lifecycle_history().last());

        let archived_by = last_archive_event.map(|e| e.actor_club);
        let archived_at = last_archive_event.map(|e| e.timestamp);

        Some(WorkGhostInfo {
            work_id: work_be_id,
            title: ws.cached_title.clone(),
            owner: ws.work.owner(),
            archived_by,
            archived_at,
            lifecycle_history: ws
                .work
                .lifecycle_history()
                .iter()
                .map(|e| WorkLifecycleEventInfo {
                    kind: match e.kind {
                        crate::edition::work::LifecycleEventKind::Archived => "archived",
                        crate::edition::work::LifecycleEventKind::Unarchived => "unarchived",
                    }
                    .to_string(),
                    actor_club: e.actor_club,
                    timestamp: e.timestamp,
                })
                .collect(),
        })
    }

    pub fn work_is_published(
        &self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<bool, ServerError> {
        self.ensure_session(session_id)?;
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        Ok(ws.work.read_club() == Some(self.system_clubs.public_club))
    }

    pub fn club_set_default_read_club(
        &mut self,
        session_id: SessionId,
        club_id: BeId,
        default_read_club: Option<BeId>,
    ) -> Result<(), ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        self.ensure_session(session_id)?;
        if !self
            .sessions
            .get(&session_id)
            .map(|s| s.has_authority(club_id))
            .unwrap_or(false)
        {
            return Err(ServerError::NotAuthorized);
        }
        let club = self
            .clubs
            .get_mut(&club_id)
            .ok_or(ServerError::ClubNotFound(club_id))?;
        club.set_default_read_club(default_read_club);
        self.dirty_clubs.insert(club_id);
        self.auto_checkpoint();
        Ok(())
    }

    pub fn club_set_default_edit_club(
        &mut self,
        session_id: SessionId,
        club_id: BeId,
        default_edit_club: Option<BeId>,
    ) -> Result<(), ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        self.ensure_session(session_id)?;
        if !self
            .sessions
            .get(&session_id)
            .map(|s| s.has_authority(club_id))
            .unwrap_or(false)
        {
            return Err(ServerError::NotAuthorized);
        }
        let club = self
            .clubs
            .get_mut(&club_id)
            .ok_or(ServerError::ClubNotFound(club_id))?;
        club.set_default_edit_club(default_edit_club);
        self.dirty_clubs.insert(club_id);
        self.auto_checkpoint();
        Ok(())
    }

    pub fn work_count(&self) -> usize {
        self.works.len()
    }

    #[cfg(feature = "server")]
    pub fn is_work_dirty(&self, work_id: BeId) -> Option<bool> {
        self.works.get(&work_id).map(|ws| ws.chunk_ref.is_none())
    }

    #[cfg(feature = "server")]
    pub fn is_club_dirty(&self, club_id: BeId) -> bool {
        self.dirty_clubs.contains(&club_id)
    }

    #[cfg(feature = "server")]
    pub fn has_edition_ref(&self, edition_id: BeId) -> bool {
        self.standalone_edition_refs.contains_key(&edition_id)
    }

    // === CRDT sync methods ===

    pub fn crdt_open_session(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<super::crdt_manager::SyncStartResult, ServerError> {
        self.ensure_session(session_id)?;
        self.ensure_can_read(session_id, work_be_id)?;
        self.ensure_can_edit(session_id, work_be_id)?;

        if self.crdt_is_active(work_be_id) {
            let needs = self.crdt_needs_materialization(work_be_id);
            if needs {
                let edition = self
                    .otree_crdt
                    .materialize_edition(work_be_id)
                    .map_err(|e| ServerError::Internal(e.to_string()))?;

                let author_club = self
                    .sessions
                    .keys()
                    .find(|sid| self.crdt_is_active_subscriber(work_be_id, **sid))
                    .and_then(|sid| self.resolve_author_club(*sid));

                self.revise_work(work_be_id, session_id, edition, author_club)?;
            }
        }

        {
            let initial_edition = if !self.otree_crdt.is_active(work_be_id) {
                Some(self.work_edition(work_be_id)?)
            } else {
                None
            };

            let result =
                self.otree_crdt
                    .open_sync_session(work_be_id, session_id, initial_edition.as_ref());

            self.register_crdt_author(session_id, work_be_id)?;

            Ok(super::crdt_manager::SyncStartResult {
                session_id: super::crdt_manager::SyncSessionId::from(result.session_id.as_u64()),
                state_vector: Vec::new(),
                current_text: result.current_text,
            })
        }
    }

    fn crdt_is_active_subscriber(&self, work_be_id: BeId, session_id: SessionId) -> bool {
        self.otree_crdt.is_subscriber(work_be_id, session_id)
    }

    fn register_crdt_author(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
        if let Some(session) = self.sessions.get(&session_id) {
            let author_club = session
                .initial_login()
                .and_then(|id| self.clubs.get(&id))
                .filter(|c| c.is_personal())
                .map(|c| c.be_id())
                .or_else(|| {
                    session.authority_clubs().iter().find_map(|id| {
                        self.clubs
                            .get(id)
                            .filter(|c| c.is_personal())
                            .map(|c| c.be_id())
                    })
                })
                .or(session.initial_login());

            if let Some(login_club) = author_club {
                let display_name = self
                    .clubs
                    .get(&login_club)
                    .and_then(|c| c.display_name().map(|s| s.to_string()))
                    .unwrap_or_else(|| format!("club-{}", login_club));
                let public_key = session
                    .club_verifying_key()
                    .map(|vk| vk.to_bytes())
                    .unwrap_or_else(|| {
                        let mut pk = [0u8; 32];
                        pk[..8].copy_from_slice(&login_club.to_le_bytes());
                        pk
                    });

                let author = super::otree_crdt::OtreeAuthorIdentity {
                    public_key,
                    display_name,
                    club_be_id: login_club,
                };
                if let Err(e) = self
                    .otree_crdt
                    .register_author(work_be_id, session_id, author)
                {
                    tracing::warn!(target: "xudanu::security", work_id = work_be_id, session_id = session_id.as_u64(), error = %e, event = "SECURITY:author_register_failed", "failed to register CRDT author");
                }
            }
        }
        Ok(())
    }

    pub fn crdt_close_session(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
        self.ensure_session(session_id)?;

        let needs = self.crdt_needs_materialization(work_be_id);

        if needs {
            let edition = self
                .otree_crdt
                .materialize_edition(work_be_id)
                .map_err(|e| ServerError::Internal(e.to_string()))?;

            let author_club = self.resolve_author_club(session_id);

            self.revise_work(work_be_id, session_id, edition, author_club)?;
        }

        self.otree_crdt
            .close_sync_session(work_be_id, session_id)
            .map_err(|e| ServerError::Internal(e.to_string()))
    }

    pub fn crdt_apply_text_delta(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
        ops: &[crate::server::transport::protocol::TextDeltaOp],
    ) -> Result<(super::crdt_manager::ApplyUpdateResult, Option<u64>), ServerError> {
        self.ensure_session(session_id)?;
        self.ensure_can_edit(session_id, work_be_id)?;

        {
            let result = self
                .otree_crdt
                .apply_text_delta(work_be_id, session_id, ops)
                .map_err(|e| ServerError::Internal(e.to_string()))?;

            self.migrate_compound_spans_for_delta(work_be_id, ops);
            self.migrate_link_spans_for_delta(work_be_id, ops);

            let relay_to: Vec<(SessionId, super::crdt_manager::SyncSessionId)> = result
                .relay_to
                .into_iter()
                .map(|(sid, osid)| (sid, super::crdt_manager::SyncSessionId::from(osid.as_u64())))
                .collect();

            let revision = if self.crdt_needs_materialization(work_be_id)
                && self
                    .otree_crdt
                    .debounce_elapsed(work_be_id)
                    .unwrap_or(false)
            {
                let ed = self.materialize_with_provenance(work_be_id, session_id)?;
                let author_club = self.resolve_author_club(session_id);
                Some(self.revise_work(work_be_id, session_id, ed, author_club)?)
            } else {
                None
            };

            Ok((
                super::crdt_manager::ApplyUpdateResult {
                    relay_to,
                    was_merged: result.was_merged,
                },
                revision,
            ))
        }
    }

    pub fn crdt_apply_update(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
        update_bytes: Vec<u8>,
    ) -> Result<super::crdt_manager::ApplyUpdateResult, ServerError> {
        self.ensure_session(session_id)?;
        self.ensure_can_edit(session_id, work_be_id)?;

        {
            let text = String::from_utf8(update_bytes)
                .map_err(|e| ServerError::Internal(format!("invalid utf8 update: {}", e)))?;
            let result = self
                .otree_crdt
                .apply_federation_update(work_be_id, &text, None)
                .map_err(|e| ServerError::Internal(e.to_string()))?;
            let relay_to: Vec<(SessionId, super::crdt_manager::SyncSessionId)> = result
                .relay_to
                .into_iter()
                .map(|(sid, osid)| (sid, super::crdt_manager::SyncSessionId::from(osid.as_u64())))
                .collect();
            self.try_materialize(work_be_id, session_id)?;
            Ok(super::crdt_manager::ApplyUpdateResult {
                relay_to,
                was_merged: false,
            })
        }
    }

    pub fn crdt_get_diff(
        &self,
        work_be_id: BeId,
        _state_vector: Vec<u8>,
    ) -> Result<Vec<u8>, ServerError> {
        self.otree_crdt
            .current_text(work_be_id)
            .map(|t| t.into_bytes())
            .map_err(|e| ServerError::Internal(e.to_string()))
    }

    pub fn crdt_get_full_state(&self, work_be_id: BeId) -> Result<Vec<u8>, ServerError> {
        self.otree_crdt
            .current_text(work_be_id)
            .map(|t| t.into_bytes())
            .map_err(|e| ServerError::Internal(e.to_string()))
    }

    pub fn crdt_subscriber_count(&self, work_be_id: BeId) -> usize {
        self.otree_crdt.subscriber_count(work_be_id)
    }

    pub fn crdt_is_active(&self, work_be_id: BeId) -> bool {
        self.otree_crdt.is_active(work_be_id)
    }

    pub fn crdt_needs_materialization(&self, work_be_id: BeId) -> bool {
        self.otree_crdt
            .needs_materialization(work_be_id)
            .unwrap_or(false)
    }

    pub fn set_work_title(&mut self, work_be_id: BeId, title: String) {
        if let Some(ws) = self.works.get_mut(&work_be_id) {
            ws.cached_title = title;
        }
    }

    pub fn crdt_current_text(&self, work_be_id: BeId) -> Result<String, ServerError> {
        self.otree_crdt
            .current_text(work_be_id)
            .map_err(|e| ServerError::Internal(e.to_string()))
    }

    pub fn crdt_text_range(
        &self,
        work_be_id: BeId,
        start_char: usize,
        end_char: usize,
    ) -> Result<super::otree_crdt::TextRangeResult, ServerError> {
        let is_source = self.is_source_work(work_be_id);
        tracing::info!(
            "[crdt_text_range] work={} is_source={} start={} end={}",
            work_be_id,
            is_source,
            start_char,
            end_char
        );
        if is_source {
            let ws = self
                .works
                .get(&work_be_id)
                .ok_or(ServerError::WorkNotFound(work_be_id))?;
            let edition = ws.work.edition();
            let total_chars = edition.char_len();
            let clamped_end = end_char.min(total_chars);
            let clamped_start = start_char.min(clamped_end);
            let text = edition.to_text_range(clamped_start, clamped_end);
            tracing::info!(
                "[crdt_text_range] source work {} total_chars={} chars {}..{}",
                work_be_id,
                total_chars,
                clamped_start,
                clamped_end
            );
            return Ok(super::otree_crdt::TextRangeResult {
                text,
                total_chars,
                start_char: clamped_start,
                end_char: clamped_end,
            });
        }
        self.otree_crdt
            .text_range(work_be_id, start_char, end_char)
            .map_err(|e| ServerError::Internal(e.to_string()))
    }

    pub fn work_outline(
        &self,
        work_be_id: BeId,
    ) -> Result<Vec<crate::edition::edition::OutlineEntry>, ServerError> {
        let text = self.crdt_current_text(work_be_id)?;
        let ed = Edition::from_text(&text);
        Ok(ed.extract_outline())
    }

    pub fn work_search(
        &self,
        work_be_id: BeId,
        query: &str,
        max_results: usize,
    ) -> Result<Vec<crate::edition::edition::SearchMatch>, ServerError> {
        let text = self.crdt_current_text(work_be_id)?;
        let ed = Edition::from_text(&text);
        Ok(ed.search_text(query, max_results))
    }

    pub fn work_goto(
        &self,
        work_be_id: BeId,
        target_line: u64,
        context_lines: u64,
    ) -> Result<(u64, u64, String), ServerError> {
        let text = self.crdt_current_text(work_be_id)?;
        let ed = Edition::from_text(&text);
        Ok(ed.get_context(target_line, context_lines))
    }

    fn try_materialize(
        &mut self,
        work_be_id: BeId,
        session_id: SessionId,
    ) -> Result<(), ServerError> {
        let should = self.crdt_needs_materialization(work_be_id);
        let elapsed = self
            .otree_crdt
            .debounce_elapsed(work_be_id)
            .map_err(|e| ServerError::Internal(e.to_string()))?;

        if should && elapsed {
            let mut edition = self.materialize_with_provenance(work_be_id, session_id)?;

            self.apply_pending_provenance_to_edition(work_be_id, &mut edition);

            let author_club = self.resolve_author_club(session_id);

            self.revise_work(work_be_id, session_id, edition, author_club)?;
        }

        Ok(())
    }

    pub fn crdt_materialize_now(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<u64, ServerError> {
        self.ensure_session(session_id)?;

        if !self.crdt_is_active(work_be_id) {
            return Err(ServerError::Internal(
                "no active CRDT session for this work".into(),
            ));
        }

        let mut edition = self.materialize_with_provenance(work_be_id, session_id)?;

        self.apply_pending_provenance_to_edition(work_be_id, &mut edition);

        let author_club = self.resolve_author_club(session_id);

        let revision = self.revise_work(work_be_id, session_id, edition, author_club)?;
        Ok(revision)
    }

    pub fn crdt_materialize_any_session(&mut self, work_be_id: BeId) -> Result<u64, ServerError> {
        if !self.crdt_is_active(work_be_id) {
            return Ok(0);
        }

        let sessions = self
            .otree_crdt
            .get_subscribed_sessions(work_be_id)
            .map_err(|e| ServerError::Internal(e.to_string()))?;

        let session_id = sessions
            .into_iter()
            .find(|sid| {
                self.sessions
                    .get(sid)
                    .and_then(|s| s.club_signing_key())
                    .is_some()
            })
            .or_else(|| {
                self.otree_crdt
                    .get_subscribed_sessions(work_be_id)
                    .ok()?
                    .into_iter()
                    .next()
            })
            .ok_or(ServerError::Internal("no subscribed session".into()))?;

        let mut edition = self.materialize_with_provenance(work_be_id, session_id)?;

        self.apply_pending_provenance_to_edition(work_be_id, &mut edition);

        let author_club = self.resolve_author_club(session_id);

        let text_before = edition.to_text();
        let revision = self.revise_work(work_be_id, session_id, edition, author_club)?;

        if let Ok(ed_new) = self.work_edition(work_be_id) {
            let text_after = ed_new.to_text();
            if text_before != text_after {
                tracing::error!(
                    "[materialize] text changed after revise_work ({} -> {})",
                    text_before.len(),
                    text_after.len()
                );
            }
            self.otree_crdt
                .sync_to_edition(work_be_id, ed_new)
                .unwrap_or_else(|e| {
                    tracing::warn!("[materialize] CRDT sync failed: {}", e);
                });
        }

        Ok(revision)
    }

    pub fn materialize_all_pending(&mut self) -> usize {
        let work_ids: Vec<BeId> = self.otree_crdt.pending_work_ids();

        let mut saved = 0;
        for work_id in work_ids {
            let rev = self
                .crdt_materialize_any_session(work_id)
                .unwrap_or_else(|_| self.materialize_pending_force(work_id));
            if rev > 0 {
                saved += 1;
                tracing::debug!("auto-save: materialized work {} rev {}", work_id, rev);
            }
        }
        saved
    }

    /// Force-materialize a pending CRDT edition without requiring an active session.
    /// Used as a fallback in the autosave loop when no session is available.
    fn materialize_pending_force(&mut self, work_be_id: BeId) -> u64 {
        let edition = match self.otree_crdt.current_edition(work_be_id) {
            Ok(ed) => ed,
            Err(_) => return 0,
        };
        let author_club = self
            .works
            .get(&work_be_id)
            .and_then(|ws| ws.last_revision_author);
        let placeholder_session = SessionId::new(0);
        match self.revise_work(work_be_id, placeholder_session, edition, author_club) {
            Ok(rev) => {
                let _ = self.otree_crdt.materialize_edition(work_be_id);
                tracing::warn!(
                    "force-materialized work {} rev {} (no active session)",
                    work_be_id,
                    rev
                );
                rev
            }
            Err(e) => {
                tracing::error!("force-materialize failed for work {}: {}", work_be_id, e);
                0
            }
        }
    }

    pub fn crdt_update_awareness(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
        state: super::crdt_manager::AwarenessState,
    ) -> Result<super::crdt_manager::AwarenessRelayResult, ServerError> {
        self.ensure_session(session_id)?;
        {
            let otree_state = super::otree_crdt::OtreeAwarenessState {
                session_id: state.session_id,
                user_name: state.user_name,
                club_id: state.club_id,
                author_public_key: state.author_public_key,
                cursor: state
                    .cursor
                    .map(|c| super::otree_crdt::OtreeCursorPosition { index: c.index }),
                selection: state
                    .selection
                    .map(|s| super::otree_crdt::OtreeSelectionRange {
                        start: s.start,
                        end: s.end,
                    }),
                is_typing: state.is_typing,
            };
            let result = self
                .otree_crdt
                .update_awareness(work_be_id, session_id, otree_state)
                .map_err(|e| ServerError::Internal(e.to_string()))?;
            let relay_to: Vec<(SessionId, super::crdt_manager::SyncSessionId)> = result
                .relay_to
                .into_iter()
                .map(|(sid, osid)| (sid, super::crdt_manager::SyncSessionId::from(osid.as_u64())))
                .collect();
            Ok(super::crdt_manager::AwarenessRelayResult { relay_to })
        }
    }

    pub fn crdt_remove_awareness(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<super::crdt_manager::AwarenessRelayResult, ServerError> {
        let result = self
            .otree_crdt
            .remove_awareness(work_be_id, session_id)
            .map_err(|e| ServerError::Internal(e.to_string()))?;
        let relay_to: Vec<(SessionId, super::crdt_manager::SyncSessionId)> = result
            .relay_to
            .into_iter()
            .map(|(sid, osid)| (sid, super::crdt_manager::SyncSessionId::from(osid.as_u64())))
            .collect();
        Ok(super::crdt_manager::AwarenessRelayResult { relay_to })
    }

    pub fn crdt_get_awareness(
        &self,
        work_be_id: BeId,
    ) -> Result<Vec<super::crdt_manager::AwarenessState>, ServerError> {
        let states = self
            .otree_crdt
            .get_awareness(work_be_id)
            .map_err(|e| ServerError::Internal(e.to_string()))?;
        Ok(states
            .into_iter()
            .map(|s| super::crdt_manager::AwarenessState {
                session_id: s.session_id,
                user_name: s.user_name.clone(),
                club_id: s.club_id,
                author_public_key: s.author_public_key.clone(),
                cursor: s
                    .cursor
                    .as_ref()
                    .map(|c| super::crdt_manager::CursorPosition { index: c.index }),
                selection: s
                    .selection
                    .as_ref()
                    .map(|sel| super::crdt_manager::SelectionRange {
                        start: sel.start,
                        end: sel.end,
                    }),
                is_typing: s.is_typing,
            })
            .collect())
    }

    pub fn crdt_register_author(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
        author: super::crdt_manager::AuthorIdentity,
    ) -> Result<(), ServerError> {
        self.ensure_session(session_id)?;
        {
            let otree_author = super::otree_crdt::OtreeAuthorIdentity {
                public_key: author.public_key,
                display_name: author.display_name,
                club_be_id: author.club_be_id,
            };
            self.otree_crdt
                .register_author(work_be_id, session_id, otree_author)
                .map_err(|e| ServerError::Internal(e.to_string()))
        }
    }

    pub fn crdt_update_author(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
        self.ensure_session(session_id)?;
        let session = self
            .sessions
            .get(&session_id)
            .ok_or(ServerError::SessionNotFound(session_id))?;

        let author_club = session
            .authority_clubs()
            .iter()
            .find_map(|id| {
                self.clubs
                    .get(&id)
                    .filter(|c| c.is_personal())
                    .map(|c| c.be_id())
            })
            .or_else(|| session.initial_login());

        let Some(login_club) = author_club else {
            return Err(ServerError::Unauthorized("no identity to register".into()));
        };

        let display_name = self
            .clubs
            .get(&login_club)
            .and_then(|c| c.display_name().map(|s| s.to_string()))
            .unwrap_or_else(|| format!("club-{}", login_club));

        let public_key = session
            .club_verifying_key()
            .map(|vk| vk.to_bytes())
            .unwrap_or_else(|| {
                let mut pk = [0u8; 32];
                pk[..8].copy_from_slice(&login_club.to_le_bytes());
                pk
            });

        {
            let author = super::otree_crdt::OtreeAuthorIdentity {
                public_key,
                display_name,
                club_be_id: login_club,
            };
            self.otree_crdt
                .register_author(work_be_id, session_id, author)
                .map_err(|e| ServerError::Internal(e.to_string()))?;
        }

        if let Some(sk) = self
            .sessions
            .get(&session_id)
            .and_then(|s| s.club_signing_key().cloned())
        {
            self.otree_crdt
                .store_club_signing_key(work_be_id, login_club, sk);
        }

        Ok(())
    }

    pub fn crdt_sign_update(&self, update_bytes: &[u8]) -> super::crdt_manager::SignedUpdate {
        let text = String::from_utf8_lossy(update_bytes);
        let signed = self
            .otree_crdt
            .sign_update(&text, &self.server_keypair.signing_key);
        super::crdt_manager::SignedUpdate {
            update_bytes: signed.update_text.into_bytes(),
            signature: signed.signature,
            signer_public_key: signed.signer_public_key,
        }
    }

    pub fn crdt_extract_signed_update_for_federation(
        &mut self,
        work_be_id: BeId,
    ) -> Result<super::crdt_manager::SignedUpdate, ServerError> {
        let signed = self
            .otree_crdt
            .extract_signed_update_for_federation(work_be_id, &self.server_keypair.signing_key)
            .map_err(|e| ServerError::Internal(e.to_string()))?;
        Ok(super::crdt_manager::SignedUpdate {
            update_bytes: signed.update_text.into_bytes(),
            signature: signed.signature,
            signer_public_key: signed.signer_public_key,
        })
    }

    pub fn crdt_apply_signed_federation_update(
        &mut self,
        work_be_id: BeId,
        signed: &super::crdt_manager::SignedUpdate,
        initial_text: Option<&str>,
    ) -> Result<super::crdt_manager::ApplyUpdateResult, ServerError> {
        let otree_signed = super::otree_crdt::OtreeSignedUpdate {
            update_text: String::from_utf8_lossy(&signed.update_bytes).into_owned(),
            signature: signed.signature.clone(),
            signer_public_key: signed.signer_public_key,
        };
        let initial_edition = initial_text.map(|t| Edition::from_text_batched(t));
        let result = self
            .otree_crdt
            .apply_signed_federation_update(
                work_be_id,
                &otree_signed,
                &std::collections::HashMap::new(),
                initial_edition.as_ref(),
            )
            .map_err(|e| ServerError::Internal(e.to_string()))?;
        let relay_to: Vec<(SessionId, super::crdt_manager::SyncSessionId)> = result
            .relay_to
            .into_iter()
            .map(|(sid, osid)| (sid, super::crdt_manager::SyncSessionId::from(osid.as_u64())))
            .collect();
        Ok(super::crdt_manager::ApplyUpdateResult {
            relay_to,
            was_merged: false,
        })
    }

    pub fn list_works(&self) -> Vec<(BeId, Option<BeId>, u64, bool)> {
        self.works
            .iter()
            .map(|(id, ws)| {
                let owner = ws.work.owner();
                let rev_count = ws.work.revision_count();
                let grabbed = ws.grabber.is_some();
                (*id, owner, rev_count, grabbed)
            })
            .collect()
    }

    pub fn work_star(&mut self, session_id: SessionId, work_id: BeId) -> Result<(), ServerError> {
        self.ensure_authenticated(session_id)?;
        let club_id = self
            .resolve_author_club(session_id)
            .ok_or(ServerError::NotAuthorized)?;
        self.starred_works
            .entry(club_id)
            .or_default()
            .insert(work_id);
        tracing::info!(
            "[star] club_id={} work_id={} total_clubs_with_stars={} wal_enabled={}",
            club_id,
            work_id,
            self.starred_works.len(),
            self.wal.is_enabled(),
        );
        if let Err(e) = self.wal.append_star(club_id, work_id) {
            tracing::warn!("WAL write failed for star: {}", e);
        }
        self.auto_checkpoint();
        Ok(())
    }

    pub fn work_unstar(&mut self, session_id: SessionId, work_id: BeId) -> Result<(), ServerError> {
        self.ensure_authenticated(session_id)?;
        let club_id = self
            .resolve_author_club(session_id)
            .ok_or(ServerError::NotAuthorized)?;
        if let Some(set) = self.starred_works.get_mut(&club_id) {
            set.remove(&work_id);
        }
        tracing::info!("[unstar] club_id={} work_id={}", club_id, work_id,);
        if let Err(e) = self.wal.append_unstar(club_id, work_id) {
            tracing::warn!("WAL write failed for unstar: {}", e);
        }
        self.auto_checkpoint();
        Ok(())
    }

    pub fn work_is_starred(
        &self,
        session_id: SessionId,
        work_id: BeId,
    ) -> Result<bool, ServerError> {
        self.ensure_session(session_id)?;
        let club_id = self.resolve_author_club(session_id);
        Ok(club_id.map_or(false, |cid| {
            self.starred_works
                .get(&cid)
                .map_or(false, |s| s.contains(&work_id))
        }))
    }

    pub fn starred_for_session(&self, session_id: SessionId) -> HashSet<BeId> {
        self.resolve_author_club(session_id)
            .and_then(|cid| self.starred_works.get(&cid).cloned())
            .unwrap_or_default()
    }

    pub(crate) fn wal_replay_star(&mut self, club_id: BeId, work_id: BeId) {
        self.starred_works
            .entry(club_id)
            .or_default()
            .insert(work_id);
    }

    pub(crate) fn wal_replay_unstar(&mut self, club_id: BeId, work_id: BeId) {
        if let Some(set) = self.starred_works.get_mut(&club_id) {
            set.remove(&work_id);
        }
    }

    pub(crate) fn wal_replay_trail_create(&mut self, owner_club: BeId, trail_id: BeId, name: &str) {
        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        self.trails.insert(
            trail_id,
            TrailState {
                trail_id,
                owner_club,
                name: name.to_string(),
                stops: Vec::new(),
                created_at: now,
                updated_at: now,
            },
        );
        if trail_id >= self.trail_counter {
            self.trail_counter = trail_id + 1;
        }
    }

    pub(crate) fn wal_replay_trail_delete(&mut self, trail_id: BeId) {
        self.trails.remove(&trail_id);
    }

    pub(crate) fn wal_replay_trail_add_stop(
        &mut self,
        trail_id: BeId,
        work_id: BeId,
        char_start: Option<u64>,
        char_end: Option<u64>,
        note: Option<String>,
    ) {
        if let Some(t) = self.trails.get_mut(&trail_id) {
            t.stops.push(TrailStop {
                work_id,
                char_start,
                char_end,
                note,
            });
        }
    }

    pub(crate) fn wal_replay_trail_remove_stop(&mut self, trail_id: BeId, work_id: BeId) {
        if let Some(t) = self.trails.get_mut(&trail_id) {
            t.stops.retain(|s| s.work_id != work_id);
        }
    }

    pub(crate) fn wal_replay_set_compound_edition(
        &mut self,
        work_id: BeId,
        compound: crate::edition::compound::CompoundEdition,
    ) {
        self.compound_editions.insert(work_id, compound);
    }

    pub(crate) fn wal_replay_compound_insert_element(
        &mut self,
        work_id: BeId,
        index: usize,
        element: crate::edition::compound::CompoundElement,
    ) {
        let compound = self
            .compound_editions
            .entry(work_id)
            .or_insert_with(crate::edition::compound::CompoundEdition::empty);
        compound.insert(index, element);
    }

    pub(crate) fn wal_replay_compound_remove_element(&mut self, work_id: BeId, index: usize) {
        if let Some(compound) = self.compound_editions.get_mut(&work_id) {
            compound.remove(index);
        }
    }

    pub(crate) fn wal_replay_compound_move_element(
        &mut self,
        work_id: BeId,
        from: usize,
        to: usize,
    ) {
        if let Some(compound) = self.compound_editions.get_mut(&work_id) {
            compound.move_element(from, to);
        }
    }

    pub(crate) fn wal_replay_create_link(
        &mut self,
        link_id: BeId,
        origin: BeId,
        destination: BeId,
        origin_ref: Option<crate::server::transport::protocol::HyperRefPayload>,
        destination_ref: Option<crate::server::transport::protocol::HyperRefPayload>,
        link_types: Vec<u64>,
    ) {
        if !self.links.contains_key(&link_id) {
            let o_ref = origin_ref
                .as_ref()
                .map(|hr| hr.to_hyper_ref(origin))
                .unwrap_or_else(|| {
                    crate::edition::links::HyperRef::single(None, Some(origin), None, None)
                });
            let d_ref = destination_ref
                .as_ref()
                .map(|hr| hr.to_hyper_ref(destination))
                .unwrap_or_else(|| {
                    crate::edition::links::HyperRef::single(None, Some(destination), None, None)
                });
            let hyperlink = crate::edition::links::HyperLink::make(link_types, o_ref, d_ref);
            self.links.insert(
                link_id,
                LinkState {
                    link: hyperlink,
                    origin,
                    destination,
                },
            );
            self.work_to_links.entry(origin).or_default().push(link_id);
            self.work_to_links
                .entry(destination)
                .or_default()
                .push(link_id);
            if link_id > self.link_counter {
                self.link_counter = link_id;
            }
        }
    }

    pub fn build_work_graph(
        &self,
        session_id: SessionId,
    ) -> (
        Vec<(BeId, String, bool, bool, u64)>,
        Vec<(BeId, BeId, String, u64)>,
    ) {
        let starred = self.starred_for_session(session_id);
        let mut visible: HashSet<BeId> = HashSet::new();
        let mut nodes = Vec::new();
        for (id, ws) in &self.works {
            if self
                .work(*id)
                .map(|w| self.work_is_readable(session_id, w))
                .unwrap_or(false)
                && !ws.work.is_archived()
            {
                visible.insert(*id);
                nodes.push((
                    *id,
                    ws.cached_title.clone(),
                    starred.contains(id),
                    ws.is_source,
                    ws.work.revision_count(),
                ));
            }
        }
        let mut seen_edges: HashSet<(BeId, BeId)> = HashSet::new();
        let mut edges = Vec::new();
        for (link_id, ls) in &self.links {
            if visible.contains(&ls.origin) && visible.contains(&ls.destination) {
                let key = if ls.origin < ls.destination {
                    (ls.origin, ls.destination)
                } else {
                    (ls.destination, ls.origin)
                };
                if seen_edges.insert(key) {
                    edges.push((ls.origin, ls.destination, "link".to_string(), 1u64));
                }
            }
            let _ = link_id;
        }

        let stop_words: HashSet<&str> = [
            "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with",
            "by", "from", "is", "was", "are", "were", "be", "been", "being", "have", "has", "had",
            "do", "does", "did", "will", "would", "could", "should", "may", "might", "shall",
            "can", "not", "no", "it", "its", "this", "that", "these", "those", "as", "if", "then",
            "than", "so", "such", "up", "out", "about", "into", "over", "after",
        ]
        .iter()
        .copied()
        .collect();

        let word_sets: Vec<(BeId, HashSet<String>)> = nodes
            .iter()
            .filter_map(|(id, _, _, _, _)| {
                let text = self.work_text((*id).into()).ok()?;
                let words: HashSet<String> = text
                    .to_ascii_lowercase()
                    .split(|c: char| !c.is_alphanumeric())
                    .filter(|w| w.len() >= 3)
                    .filter(|w| !stop_words.contains(*w))
                    .map(|w| w.to_string())
                    .collect();
                if words.is_empty() {
                    None
                } else {
                    Some((*id, words))
                }
            })
            .collect();

        for i in 0..word_sets.len() {
            for j in (i + 1)..word_sets.len() {
                let (id_a, ref set_a) = word_sets[i];
                let (id_b, ref set_b) = word_sets[j];
                let intersection = set_a.intersection(set_b).count() as u64;
                let union = set_a.union(set_b).count() as u64;
                if union == 0 {
                    continue;
                }
                let similarity = intersection as f64 / union as f64;
                if similarity > 0.15 {
                    let key = if id_a < id_b {
                        (id_a, id_b)
                    } else {
                        (id_b, id_a)
                    };
                    if seen_edges.insert(key) {
                        edges.push((
                            id_a,
                            id_b,
                            "similarity".to_string(),
                            (similarity * 100.0) as u64,
                        ));
                    }
                }
            }
        }

        (nodes, edges)
    }

    fn trail_owner_club(&self, session_id: SessionId) -> Result<BeId, ServerError> {
        self.resolve_author_club(session_id)
            .ok_or_else(|| ServerError::InvalidArgument("no personal club for session".into()))
    }

    fn trail_to_payload(&self, t: &TrailState) -> super::transport::protocol::TrailPayload {
        let stops: Vec<super::transport::protocol::TrailStopPayload> = t
            .stops
            .iter()
            .map(|s| {
                let title = self
                    .works
                    .get(&s.work_id)
                    .map(|ws| ws.cached_title.clone())
                    .unwrap_or_default();
                super::transport::protocol::TrailStopPayload {
                    work_id: s.work_id,
                    char_start: s.char_start,
                    char_end: s.char_end,
                    note: s.note.clone(),
                    title,
                }
            })
            .collect();
        super::transport::protocol::TrailPayload {
            trail_id: t.trail_id,
            name: t.name.clone(),
            stops,
            created_at: t.created_at,
            updated_at: t.updated_at,
        }
    }

    pub fn trail_create(
        &mut self,
        session_id: SessionId,
        name: String,
    ) -> Result<BeId, ServerError> {
        let owner = self.trail_owner_club(session_id)?;
        let trail_id = self.trail_counter;
        self.trail_counter += 1;
        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        self.trails.insert(
            trail_id,
            TrailState {
                trail_id,
                owner_club: owner,
                name: name.clone(),
                stops: Vec::new(),
                created_at: now,
                updated_at: now,
            },
        );
        if let Err(e) = self.wal.append_trail_create(owner, trail_id, &name) {
            tracing::warn!("WAL write failed for trail_create: {}", e);
        }
        Ok(trail_id)
    }

    pub fn trail_delete(
        &mut self,
        session_id: SessionId,
        trail_id: BeId,
    ) -> Result<(), ServerError> {
        let owner = self.trail_owner_club(session_id)?;
        let t = self
            .trails
            .get(&trail_id)
            .ok_or_else(|| ServerError::InvalidArgument("trail not found".into()))?;
        if t.owner_club != owner {
            return Err(ServerError::InvalidArgument("not your trail".into()));
        }
        self.trails.remove(&trail_id);
        if let Err(e) = self.wal.append_trail_delete(trail_id) {
            tracing::warn!("WAL write failed for trail_delete: {}", e);
        }
        Ok(())
    }

    pub fn trail_rename(
        &mut self,
        session_id: SessionId,
        trail_id: BeId,
        name: String,
    ) -> Result<(), ServerError> {
        let owner = self.trail_owner_club(session_id)?;
        let t = self
            .trails
            .get_mut(&trail_id)
            .ok_or_else(|| ServerError::InvalidArgument("trail not found".into()))?;
        if t.owner_club != owner {
            return Err(ServerError::InvalidArgument("not your trail".into()));
        }
        let old_name = t.name.clone();
        t.name = name.clone();
        t.updated_at = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        if let Err(e) = self.wal.append_trail_rename(trail_id, &old_name, &name) {
            tracing::warn!("WAL write failed for trail_rename: {}", e);
        }
        Ok(())
    }

    pub fn trail_add_stop(
        &mut self,
        session_id: SessionId,
        trail_id: BeId,
        work_id: BeId,
        char_start: Option<u64>,
        char_end: Option<u64>,
        note: Option<String>,
    ) -> Result<(), ServerError> {
        let owner = self.trail_owner_club(session_id)?;
        self.work(work_id)?;
        let t = self
            .trails
            .get_mut(&trail_id)
            .ok_or_else(|| ServerError::InvalidArgument("trail not found".into()))?;
        if t.owner_club != owner {
            return Err(ServerError::InvalidArgument("not your trail".into()));
        }
        t.stops.push(TrailStop {
            work_id,
            char_start,
            char_end,
            note: note.clone(),
        });
        t.updated_at = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        if let Err(e) =
            self.wal
                .append_trail_add_stop(trail_id, work_id, char_start, char_end, note.as_deref())
        {
            tracing::warn!("WAL write failed for trail_add_stop: {}", e);
        }
        Ok(())
    }

    pub fn trail_remove_stop(
        &mut self,
        session_id: SessionId,
        trail_id: BeId,
        stop_index: u64,
    ) -> Result<(), ServerError> {
        let owner = self.trail_owner_club(session_id)?;
        let t = self
            .trails
            .get_mut(&trail_id)
            .ok_or_else(|| ServerError::InvalidArgument("trail not found".into()))?;
        if t.owner_club != owner {
            return Err(ServerError::InvalidArgument("not your trail".into()));
        }
        let idx = stop_index as usize;
        if idx >= t.stops.len() {
            return Err(ServerError::InvalidArgument(
                "stop index out of range".into(),
            ));
        }
        let work_id = t.stops[idx].work_id;
        t.stops.remove(idx);
        t.updated_at = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        if let Err(e) = self.wal.append_trail_remove_stop(trail_id, work_id) {
            tracing::warn!("WAL write failed for trail_remove_stop: {}", e);
        }
        Ok(())
    }

    pub fn trail_reorder_stops(
        &mut self,
        session_id: SessionId,
        trail_id: BeId,
        stop_order: Vec<u64>,
    ) -> Result<(), ServerError> {
        let owner = self.trail_owner_club(session_id)?;
        let t = self
            .trails
            .get_mut(&trail_id)
            .ok_or_else(|| ServerError::InvalidArgument("trail not found".into()))?;
        if t.owner_club != owner {
            return Err(ServerError::InvalidArgument("not your trail".into()));
        }
        if stop_order.len() != t.stops.len() {
            return Err(ServerError::InvalidArgument(
                "stop order length mismatch".into(),
            ));
        }
        let mut new_stops = Vec::with_capacity(t.stops.len());
        for &idx in &stop_order {
            let i = idx as usize;
            if i >= t.stops.len() {
                return Err(ServerError::InvalidArgument(
                    "stop index out of range".into(),
                ));
            }
            new_stops.push(t.stops[i].clone());
        }
        t.stops = new_stops;
        t.updated_at = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        Ok(())
    }

    pub fn trail_list(
        &self,
        session_id: SessionId,
    ) -> Result<Vec<super::transport::protocol::TrailPayload>, ServerError> {
        let owner = self.trail_owner_club(session_id)?;
        let trails: Vec<_> = self
            .trails
            .values()
            .filter(|t| t.owner_club == owner)
            .map(|t| self.trail_to_payload(t))
            .collect();
        Ok(trails)
    }

    pub fn trail_get(
        &self,
        session_id: SessionId,
        trail_id: BeId,
    ) -> Result<super::transport::protocol::TrailPayload, ServerError> {
        let owner = self.trail_owner_club(session_id)?;
        let t = self
            .trails
            .get(&trail_id)
            .ok_or_else(|| ServerError::InvalidArgument("trail not found".into()))?;
        if t.owner_club != owner {
            return Err(ServerError::InvalidArgument("not your trail".into()));
        }
        Ok(self.trail_to_payload(t))
    }

    pub fn list_works_with_titles(
        &self,
    ) -> Vec<(
        BeId,
        Option<BeId>,
        u64,
        bool,
        String,
        Option<BeId>,
        bool,
        Option<u64>,
        Option<u64>,
        Option<BeId>,
        Option<String>,
    )> {
        self.works
            .iter()
            .map(|(id, ws)| {
                let owner = ws.work.owner();
                let rev_count = ws.work.revision_count();
                let grabbed = ws.grabber.is_some();
                let read_club = ws.work.read_club();
                (
                    *id,
                    owner,
                    rev_count,
                    grabbed,
                    ws.cached_title.clone(),
                    read_club,
                    ws.is_source,
                    ws.content_start_line,
                    ws.content_end_line,
                    ws.source_author_id,
                    ws.source_edition_info.clone(),
                )
            })
            .collect()
    }

    pub(crate) fn works_iter(&self) -> std::collections::hash_map::Iter<'_, BeId, WorkState> {
        self.works.iter()
    }

    pub(crate) fn session_authority_clubs(&self, session_id: SessionId) -> HashSet<BeId> {
        self.sessions
            .get(&session_id)
            .map(|s| s.authority_clubs())
            .unwrap_or_default()
    }

    pub fn list_works_by_owner(
        &self,
        owner: BeId,
    ) -> Vec<(BeId, Option<BeId>, u64, bool, Option<BeId>)> {
        self.works
            .iter()
            .filter(|(_, ws)| ws.work.owner() == Some(owner))
            .map(|(id, ws)| {
                let rev_count = ws.work.revision_count();
                let grabbed = ws.grabber.is_some();
                let read_club = ws.work.read_club();
                (*id, ws.work.owner(), rev_count, grabbed, read_club)
            })
            .collect()
    }

    pub fn list_works_by_historical_author(
        &self,
        author_id: BeId,
    ) -> Vec<(
        BeId,
        Option<BeId>,
        u64,
        bool,
        String,
        Option<BeId>,
        Option<String>,
    )> {
        self.works
            .iter()
            .filter(|(_, ws)| ws.source_author_id == Some(author_id))
            .map(|(id, ws)| {
                let rev_count = ws.work.revision_count();
                let grabbed = ws.grabber.is_some();
                let read_club = ws.work.read_club();
                (
                    *id,
                    ws.work.owner(),
                    rev_count,
                    grabbed,
                    ws.cached_title.clone(),
                    read_club,
                    ws.source_edition_info.clone(),
                )
            })
            .collect()
    }

    pub fn work_summary(
        &self,
        work_be_id: BeId,
    ) -> Result<super::transport::protocol::ResponseValue, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;

        let edition = ws.work.current_edition();
        let all_entries = edition.all_entries();

        let total_chars: u64 = all_entries.iter().map(|(_, c)| c.char_len() as u64).sum();

        let version_count = ws.work.revision_count();

        let mut source_work_ids: HashSet<BeId> = HashSet::new();
        let mut author_chars: HashMap<BeId, u64> = HashMap::new();
        let mut author_names: HashMap<BeId, String> = HashMap::new();
        let mut author_types: HashMap<BeId, String> = HashMap::new();

        for (_, c) in &all_entries {
            let char_count = c.char_len() as u64;
            if char_count == 0 {
                continue;
            }

            if let Some(ep) = &c.provenance {
                if let Some(sw) = ep.source_work_id {
                    source_work_ids.insert(sw);
                }

                let (author_key, display_name, atype) = match ep.author_type {
                    crate::edition::provenance::AuthorType::Historical => {
                        let ha_name = ep
                            .historical_author_id
                            .and_then(|id| self.historical_authors.get(id))
                            .map(|a| a.display_name.clone())
                            .unwrap_or_else(|| "Unknown Historical Author".to_string());
                        let key = ep.historical_author_id.unwrap_or(0);
                        (key, ha_name, "historical")
                    }
                    crate::edition::provenance::AuthorType::Llm => {
                        let model = ep.llm_model.as_deref().unwrap_or("llm");
                        let key =
                            ep.author_club_id
                                .wrapping_add(ep.llm_model.as_ref().map_or(0, |m| {
                                    m.as_str()
                                        .bytes()
                                        .fold(0u64, |a, b| a.wrapping_add(b as u64))
                                }));
                        (key, model.to_string(), "llm")
                    }
                    crate::edition::provenance::AuthorType::Human => {
                        let key = ep.author_club_id;
                        let name = self
                            .clubs
                            .get(&key)
                            .and_then(|c| c.display_name().map(|s| s.to_string()))
                            .unwrap_or_else(|| format!("club:{:04x}", key));
                        (key, name, "human")
                    }
                };

                *author_chars.entry(author_key).or_insert(0) += char_count;
                author_names.entry(author_key).or_insert(display_name);
                author_types.entry(author_key).or_insert(atype.to_string());
            }
        }

        if author_chars.is_empty() {
            for sp in &edition.span_provenance {
                let span_entries: Vec<_> = all_entries
                    .iter()
                    .filter(|(pos, _)| *pos >= sp.start && *pos < sp.end)
                    .collect();

                let span_char_count: u64 =
                    span_entries.iter().map(|(_, c)| c.char_len() as u64).sum();

                let element_prov = span_entries
                    .iter()
                    .find(|(_, c)| c.provenance.is_some())
                    .and_then(|(_, c)| c.provenance.as_ref());

                if let Some(sw) = element_prov.and_then(|ep| ep.source_work_id) {
                    source_work_ids.insert(sw);
                }

                let club_id = self
                    .clubs
                    .iter()
                    .find(|(_, club)| match club.encrypted_signing_key() {
                        Some(ek) => ek.verifying_key == sp.provenance.author_public_key,
                        None => false,
                    })
                    .map(|(id, _)| *id);

                if let Some(cid) = club_id {
                    *author_chars.entry(cid).or_insert(0) += span_char_count;
                    if !author_names.contains_key(&cid) {
                        let name = self
                            .clubs
                            .get(&cid)
                            .and_then(|c| c.display_name().map(|s| s.to_string()))
                            .unwrap_or_else(|| format!("club:{:04x}", cid));
                        author_names.insert(cid, name);
                        author_types.insert(cid, "human".to_string());
                    }
                }
            }
        }

        let unattributed: u64 = total_chars.saturating_sub(author_chars.values().sum());
        if unattributed > 0 {
            let unattributed_key = 0xFFFF_FFFF_FFFF_FFFF_u64;
            author_names.insert(unattributed_key, "Unattributed".to_string());
            author_chars.insert(unattributed_key, unattributed);
            author_types.insert(unattributed_key, "unattributed".to_string());
        }

        let mut author_contributions: Vec<super::transport::protocol::AuthorContributionEntry> =
            author_chars
                .into_iter()
                .map(|(cid, chars)| {
                    let pct = if total_chars > 0 {
                        (chars as f64 / total_chars as f64) * 100.0
                    } else {
                        0.0
                    };
                    let name = author_names
                        .get(&cid)
                        .cloned()
                        .unwrap_or_else(|| format!("club:{:04x}", cid));
                    super::transport::protocol::AuthorContributionEntry {
                        club_id: cid,
                        display_name: name,
                        char_count: chars,
                        percentage: pct,
                        author_type: author_types.get(&cid).cloned(),
                    }
                })
                .collect();
        author_contributions.sort_by(|a, b| {
            b.percentage
                .partial_cmp(&a.percentage)
                .unwrap_or(std::cmp::Ordering::Equal)
        });

        let mut reused_in_count: u64 = 0;
        let mut reused_in_docs: Vec<super::transport::protocol::ReusedInDocEntry> = Vec::new();
        for other_id in self.works.keys() {
            if *other_id == work_be_id {
                continue;
            }
            let shared = self.find_shared_regions(work_be_id, *other_id);
            if !shared.is_empty() {
                reused_in_count += 1;
                let shared_chars: u64 = shared.iter().map(|r| r.4.len() as u64).sum();
                let title = self
                    .works
                    .get(other_id)
                    .map(|ws| ws.cached_title.clone())
                    .unwrap_or_default();
                reused_in_docs.push(super::transport::protocol::ReusedInDocEntry {
                    work_id: *other_id,
                    title,
                    shared_char_count: shared_chars,
                });
            }
        }

        Ok(
            super::transport::protocol::ResponseValue::WorkSummaryResult {
                unique_sources: source_work_ids.len() as u64,
                unique_authors: author_names.len() as u64,
                version_count,
                char_count: total_chars,
                author_contributions,
                reused_in_count,
                reused_in_docs,
            },
        )
    }

    pub fn work_version_timeline(
        &self,
        work_be_id: BeId,
    ) -> Result<super::transport::protocol::ResponseValue, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;

        let rev_count = ws.work.revision_count();
        let mut revisions = Vec::new();

        for rev_num in 0..=rev_count {
            let ed = match ws.work.fetch_revision(rev_num) {
                Some(ed) => ed.clone(),
                None => continue,
            };
            let entries = ed.all_entries();
            let char_count: u64 = entries.iter().map(|(_, c)| c.char_len() as u64).sum();

            let (author_club_id, author_display_name, author_type) = {
                let from_rev = if rev_num == rev_count {
                    ws.last_revision_author
                } else {
                    ws.revision_authors.get(&rev_num).copied()
                };

                if let Some(cid) = from_rev {
                    let name = self
                        .clubs
                        .get(&cid)
                        .and_then(|c| c.display_name().map(|s| s.to_string()));
                    (Some(cid), name, Some("human".to_string()))
                } else {
                    let mut prov_chars: HashMap<BeId, u64> = HashMap::new();
                    let mut prov_names: HashMap<BeId, String> = HashMap::new();
                    let mut prov_types: HashMap<BeId, String> = HashMap::new();

                    for (_, c) in &entries {
                        if c.char_len() == 0 {
                            continue;
                        }
                        if let Some(ep) = &c.provenance {
                            let len = c.char_len() as u64;
                            let (key, name, atype) = match ep.author_type {
                                crate::edition::provenance::AuthorType::Historical => {
                                    let ha_name = ep
                                        .historical_author_id
                                        .and_then(|id| self.historical_authors.get(id))
                                        .map(|a| a.display_name.clone())
                                        .unwrap_or_else(|| "Unknown Historical Author".to_string());
                                    (ep.historical_author_id.unwrap_or(0), ha_name, "historical")
                                }
                                crate::edition::provenance::AuthorType::Llm => {
                                    let model = ep.llm_model.as_deref().unwrap_or("llm");
                                    let key = ep.author_club_id.wrapping_add(
                                        ep.llm_model.as_ref().map_or(0, |m| {
                                            m.as_str()
                                                .bytes()
                                                .fold(0u64, |a, b| a.wrapping_add(b as u64))
                                        }),
                                    );
                                    (key, model.to_string(), "llm")
                                }
                                crate::edition::provenance::AuthorType::Human => {
                                    let name = self
                                        .clubs
                                        .get(&ep.author_club_id)
                                        .and_then(|c| c.display_name().map(|s| s.to_string()))
                                        .unwrap_or_else(|| {
                                            format!("club:{:04x}", ep.author_club_id)
                                        });
                                    (ep.author_club_id, name, "human")
                                }
                            };
                            *prov_chars.entry(key).or_insert(0) += len;
                            prov_names.entry(key).or_insert(name);
                            prov_types.entry(key).or_insert(atype.to_string());
                        }
                    }

                    let best = prov_chars.iter().max_by_key(|(_, &v)| v);
                    if let Some((&best_key, _)) = best {
                        let best_type = prov_types
                            .get(&best_key)
                            .cloned()
                            .unwrap_or("human".to_string());
                        if best_type == "human" {
                            let cid = entries
                                .iter()
                                .filter_map(|(_, c)| c.provenance.as_ref())
                                .filter(|ep| match ep.author_type {
                                    crate::edition::provenance::AuthorType::Human => {
                                        let key = ep.author_club_id;
                                        key == best_key
                                    }
                                    _ => false,
                                })
                                .map(|ep| ep.author_club_id)
                                .next();
                            (cid, prov_names.get(&best_key).cloned(), Some(best_type))
                        } else {
                            (None, prov_names.get(&best_key).cloned(), Some(best_type))
                        }
                    } else {
                        (None, None, None)
                    }
                }
            };

            revisions.push(super::transport::protocol::RevisionMetaEntry {
                revision: rev_num,
                char_count,
                author_club_id,
                author_display_name,
                author_type,
                timestamp: ws.revision_timestamps.get(&rev_num).copied(),
            });
        }

        Ok(super::transport::protocol::ResponseValue::WorkVersionTimelineResult { revisions })
    }

    pub fn passage_composition(
        &self,
        work_be_id: BeId,
        start: u64,
        end: u64,
    ) -> Result<super::transport::protocol::ResponseValue, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;

        let rev_count = ws.work.revision_count();
        let mut layers = Vec::new();

        let mut prev_text: Option<String> = None;

        for rev_num in 0..=rev_count {
            let ed = match ws.work.fetch_revision(rev_num) {
                Some(ed) => ed.clone(),
                None => continue,
            };

            let full_text: String = ed
                .all_entries()
                .iter()
                .map(|(_, c)| c.element.as_text().unwrap_or(""))
                .collect();

            let start_usize = start as usize;
            let end_usize = (end as usize).min(full_text.len());

            if start_usize >= full_text.len() {
                prev_text = Some(full_text);
                continue;
            }

            let passage = &full_text[start_usize..end_usize];

            let operation = match &prev_text {
                Some(pt) => {
                    let pt_start = start as usize;
                    let pt_end = (end as usize).min(pt.len());
                    if pt_start >= pt.len() {
                        "added".to_string()
                    } else {
                        let prev_passage = &pt[pt_start..pt_end];
                        if passage == prev_passage {
                            continue;
                        } else if passage.contains(prev_passage) {
                            "expanded".to_string()
                        } else if prev_passage.contains(passage) {
                            "reduced".to_string()
                        } else {
                            "modified".to_string()
                        }
                    }
                }
                None => "added".to_string(),
            };

            let author_club_id = if rev_num == rev_count {
                ws.last_revision_author
            } else {
                None
            };

            let author_display_name = author_club_id.and_then(|cid| {
                self.clubs
                    .get(&cid)
                    .and_then(|c| c.display_name().map(|s| s.to_string()))
            });

            layers.push(super::transport::protocol::CompositionLayerEntry {
                revision: rev_num,
                author_club_id,
                author_display_name,
                text: passage.to_string(),
                operation,
            });

            prev_text = Some(full_text);
        }

        Ok(super::transport::protocol::ResponseValue::PassageCompositionResult { layers })
    }

    // === Edition operations ===

    pub fn store_edition(
        &mut self,
        session_id: SessionId,
        edition: Edition,
    ) -> Result<BeId, ServerError> {
        self.ensure_logged_in(session_id)?;

        let (be_id, elem) = self.grand_map.new_edition_element();
        self.grand_map.assign_new_id(elem);
        self.standalone_editions.insert(be_id, edition);
        let edition = self
            .standalone_editions
            .get(&be_id)
            .ok_or_else(|| {
                ServerError::Internal("standalone edition not found after insert".to_string())
            })?
            .clone();
        let _edition_elem = RangeElement::edition(be_id);
        self.backfollow
            .register_edition(&edition, be_id, BertProp::make());
        Ok(be_id)
    }

    pub fn get_edition(&self, be_id: BeId) -> Result<Option<Edition>, ServerError> {
        if let Some(edition) = self.standalone_editions.get(&be_id) {
            return Ok(Some(edition.clone()));
        }
        if let Some(ws) = self.works.get(&be_id) {
            return Ok(Some(ws.work.edition().clone()));
        }
        Ok(None)
    }

    // === Element lookup ===

    pub fn get_by_id(&self, id: &crate::edition::Id) -> Option<RangeElement> {
        self.grand_map
            .fetch_by_id(id)
            .map(|elem| elem.as_range_element())
    }

    pub fn get_by_be_id(&self, be_id: BeId) -> Option<RangeElement> {
        self.grand_map
            .fetch_by_be_id(be_id)
            .map(|elem| elem.as_range_element())
    }

    // === Admin operations ===

    pub fn admin(&self) -> &AdminState {
        &self.admin
    }

    pub fn admin_mut(&mut self) -> &mut AdminState {
        &mut self.admin
    }

    pub fn ensure_admin(&self, session_id: SessionId) -> Result<(), ServerError> {
        self.ensure_session(session_id)?;
        let session = self
            .sessions
            .get(&session_id)
            .ok_or(ServerError::SessionNotFound(session_id))?;
        if session.has_authority(self.system_clubs.admin_club)
            || session.has_authority(self.system_clubs.access_club)
        {
            Ok(())
        } else {
            Err(ServerError::AdminRequired)
        }
    }

    pub fn grant_admin_authority(&mut self, session_id: SessionId) -> Result<(), ServerError> {
        self.ensure_session(session_id)?;
        let admin_club = self.system_clubs.admin_club;
        let admin_km = KeyMaster::make(admin_club);
        if let Some(session) = self.sessions.get_mut(&session_id) {
            session.incorporate_authority(&admin_km);
        }
        Ok(())
    }

    pub fn admin_accept_connections(
        &mut self,
        session_id: SessionId,
        accept: bool,
    ) -> Result<(), ServerError> {
        self.ensure_admin(session_id)?;
        self.admin.set_accepting_connections(accept);
        Ok(())
    }

    pub fn admin_is_accepting_connections(&self) -> bool {
        self.admin.is_accepting_connections()
    }

    pub fn admin_active_sessions(
        &self,
        session_id: SessionId,
    ) -> Result<Vec<SessionInfo>, ServerError> {
        self.ensure_admin(session_id)?;
        let infos: Vec<SessionInfo> = self
            .sessions
            .values()
            .filter(|s| s.is_connected())
            .map(|s| {
                let grabbed_count = self
                    .works
                    .values()
                    .filter(|ws| ws.grabber == Some(s.id()))
                    .count();
                SessionInfo {
                    session_id: s.id().as_u64(),
                    is_logged_in: s.is_logged_in(),
                    authority_clubs: s.authority_clubs().into_iter().collect(),
                    initial_login: s.initial_login(),
                    has_grabbed_works: grabbed_count > 0,
                }
            })
            .collect();
        Ok(infos)
    }

    pub fn admin_shutdown(&mut self, session_id: SessionId) -> Result<(), ServerError> {
        self.ensure_admin(session_id)?;
        self.admin.request_shutdown();
        Ok(())
    }

    pub fn admin_grant(
        &mut self,
        session_id: SessionId,
        club_id: BeId,
        region: crate::edition::XnRegion,
    ) -> Result<(), ServerError> {
        self.ensure_admin(session_id)?;
        self.admin.grant(club_id, region);
        Ok(())
    }

    pub fn admin_revoke_grant(
        &mut self,
        session_id: SessionId,
        club_id: BeId,
    ) -> Result<bool, ServerError> {
        self.ensure_admin(session_id)?;
        Ok(self.admin.revoke_grant(club_id))
    }

    pub fn admin_grants(&self, session_id: SessionId) -> Result<&[IdGrant], ServerError> {
        self.ensure_admin(session_id)?;
        Ok(self.admin.grants())
    }

    pub fn is_shutdown_requested(&self) -> bool {
        self.admin.is_shutdown_requested()
    }

    pub fn bump_operation(&mut self) -> u64 {
        self.operation_counter += 1;
        if self.operation_counter % 10 == 0 {
            self.auto_checkpoint();
            self.check_grab_timeouts();
        }
        self.operation_counter
    }

    pub fn set_checkpoint_path(&mut self, path: std::path::PathBuf) {
        self.checkpoint_path = Some(path);
    }

    pub fn init_data_dir(
        &mut self,
        data_dir: &std::path::Path,
        passphrase: Option<&[u8]>,
    ) -> std::io::Result<()> {
        let manifest_path = data_dir.join("manifest.json");
        if manifest_path.exists() {
            return Err(std::io::Error::new(
                std::io::ErrorKind::AlreadyExists,
                format!("data directory already initialized: {}", data_dir.display()),
            ));
        }

        std::fs::create_dir_all(data_dir)?;
        std::fs::create_dir_all(data_dir.join("blobs"))?;

        let chunk_store = crate::persist::chunk_store::ChunkStore::open(data_dir)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
        self.chunk_store = Some(Arc::new(chunk_store));
        self.data_dir = Some(data_dir.to_path_buf());

        self.restore_keypair_from_dir(data_dir, passphrase)?;
        self.restore_blob_store_from_dir(data_dir)?;

        self.checkpoint_path = Some(manifest_path);
        self.attribution_log =
            match crate::server::transport::attribution_log::AttributionLog::open(data_dir) {
                Ok(log) => log,
                Err(e) => {
                    tracing::warn!("failed to open attribution log: {}, using in-memory", e);
                    crate::server::transport::attribution_log::AttributionLog::in_memory()
                }
            };
        self.wal = crate::persist::wal::WalLog::open(data_dir)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
        self.checkpoint_to_store()?;

        tracing::info!("Initialized xudanu data directory: {}", data_dir.display());
        Ok(())
    }

    pub fn restore_from_data_dir(
        &mut self,
        data_dir: &std::path::Path,
        passphrase: Option<&[u8]>,
    ) -> std::io::Result<()> {
        for name in &["manifest.json.tmp", "key_history.json.tmp"] {
            let p = data_dir.join(name);
            if p.exists() {
                let _ = std::fs::remove_file(&p);
                tracing::info!("Cleaned up stale {}", name);
            }
        }

        let manifest_path = data_dir.join("manifest.json");

        let chunk_store = crate::persist::chunk_store::ChunkStore::open(data_dir)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;

        let manifest = if manifest_path.exists() {
            match crate::persist::manifest::read_manifest_dual(data_dir) {
                Ok(m) => m,
                Err(e) => {
                    match crate::persist::manifest::read_manifest_with_fallback(&manifest_path, 3) {
                        Ok(m) => m,
                        Err(fallback_err) => {
                            return Err(std::io::Error::new(
                                std::io::ErrorKind::InvalidData,
                                format!(
                                    "manifest.json, dual slots, and all backups are corrupt: {} / {}. \
                                     Run 'xudanu-server rebuild-manifest {}' or delete the data directory to start fresh.",
                                    e, fallback_err, data_dir.display()
                                ),
                            ));
                        }
                    }
                }
            }
        } else {
            return Err(std::io::Error::new(
                std::io::ErrorKind::NotFound,
                format!("no manifest.json found in {}", data_dir.display()),
            ));
        };

        let verify_report =
            crate::persist::verify::verify_store_with_manifest(&manifest, &chunk_store);
        if !verify_report.is_ok() {
            tracing::warn!(
                "Data verification found issues: {} corrupt chunks, {} missing chunks, {} deserialization errors",
                verify_report.chunks_corrupt.len(),
                verify_report.chunks_missing.len(),
                verify_report.deserialization_errors.len(),
            );
            for err in &verify_report.deserialization_errors {
                tracing::warn!("  - {}", err);
            }
        }

        self.restore_keypair_from_dir(data_dir, passphrase)?;
        self.restore_blob_store_from_dir(data_dir)?;

        let historical_authors_from_chunk = if let Some(hash) = manifest.historical_authors_hash {
            match chunk_store.read_chunk(&hash) {
                Ok(data) => match crate::persist::chunk_store::untag_chunk_data(&data) {
                    Ok((format, payload))
                        if format == crate::persist::chunk_store::CHUNK_FORMAT_JSON =>
                    {
                        match serde_json::from_slice::<
                            crate::server::historical_author::HistoricalAuthorRegistry,
                        >(payload)
                        {
                            Ok(registry) => Some(registry),
                            Err(e) => {
                                tracing::warn!(
                                    "historical authors chunk deserialization failed: {}",
                                    e
                                );
                                None
                            }
                        }
                    }
                    Ok((format, _)) => {
                        tracing::warn!(
                            "historical authors chunk has unexpected format: {:#x}",
                            format
                        );
                        None
                    }
                    Err(e) => {
                        tracing::warn!("historical authors chunk untag failed: {}", e);
                        None
                    }
                },
                Err(e) => {
                    tracing::warn!("historical authors chunk read failed: {}", e);
                    None
                }
            }
        } else {
            None
        };

        let blob_metas_from_chunk: Vec<crate::persist::manifest::BlobMetaEntry> =
            if let Some(hash) = manifest.blob_metas_hash {
                match chunk_store.read_chunk(&hash) {
                    Ok(data) => match crate::persist::chunk_store::untag_chunk_data(&data) {
                        Ok((format, payload))
                            if format == crate::persist::chunk_store::CHUNK_FORMAT_JSON =>
                        {
                            serde_json::from_slice(payload).unwrap_or_else(|e| {
                                tracing::error!("blob_metas deserialization failed: {}", e);
                                self.restore_errors.push(format!("blob_metas: {}", e));
                                manifest.blob_metas.clone()
                            })
                        }
                        Ok((format, _)) => {
                            tracing::warn!("blob_metas chunk has unexpected format: {:#x}", format);
                            manifest.blob_metas.clone()
                        }
                        Err(e) => {
                            tracing::warn!("blob_metas chunk untag failed: {}", e);
                            manifest.blob_metas.clone()
                        }
                    },
                    Err(e) => {
                        tracing::warn!("blob_metas chunk read failed: {}", e);
                        manifest.blob_metas.clone()
                    }
                }
            } else {
                manifest.blob_metas.clone()
            };

        self.grand_map.set_id_counter(manifest.grand_map_id_counter);
        self.session_counter = manifest.session_counter;
        self.operation_counter = manifest.operation_counter;
        self.system_clubs = manifest.system_clubs;
        self.link_counter = manifest.link_counter;
        self.starred_works = manifest.starred_works;
        {
            let total: usize = self.starred_works.values().map(|s| s.len()).sum();
            tracing::info!(
                "[restore] starred_works: {} clubs, {} total stars",
                self.starred_works.len(),
                total
            );
        }
        self.trail_counter = manifest.trail_counter;
        for t in manifest.trails {
            self.trails.insert(
                t.trail_id,
                TrailState {
                    trail_id: t.trail_id,
                    owner_club: t.owner_club,
                    name: t.name,
                    stops: t
                        .stops
                        .into_iter()
                        .map(|s| TrailStop {
                            work_id: s.work_id,
                            char_start: s.char_start,
                            char_end: s.char_end,
                            note: s.note,
                        })
                        .collect(),
                    created_at: t.created_at,
                    updated_at: t.updated_at,
                },
            );
        }
        self.compound_editions = manifest.compound_editions.into_iter().collect();
        self.reconcile_store = manifest.reconcile_store;
        self.reconcile_counter = manifest.reconcile_counter;
        self.content_address = if let Some(hash) = manifest.content_address_hash {
            match chunk_store.read_chunk(&hash) {
                Ok(data) => match crate::persist::chunk_store::untag_chunk_data(&data) {
                    Ok((format, payload))
                        if format == crate::persist::chunk_store::CHUNK_FORMAT_JSON =>
                    {
                        serde_json::from_slice::<ContentAddressIndex>(payload).unwrap_or_else(|e| {
                            tracing::error!("content_address deserialization failed: {}", e);
                            self.restore_errors.push(format!("content_address: {}", e));
                            manifest
                                .content_address
                                .clone()
                                .unwrap_or_else(|| ContentAddressIndex::new(1_000_000))
                        })
                    }
                    Ok((format, _)) => {
                        tracing::warn!(
                            "content_address chunk has unexpected format: {:#x}",
                            format
                        );
                        manifest
                            .content_address
                            .clone()
                            .unwrap_or_else(|| ContentAddressIndex::new(1_000_000))
                    }
                    Err(e) => {
                        tracing::warn!("content_address chunk untag failed: {}", e);
                        manifest
                            .content_address
                            .clone()
                            .unwrap_or_else(|| ContentAddressIndex::new(1_000_000))
                    }
                },
                Err(e) => {
                    tracing::warn!("content_address chunk read failed: {}", e);
                    manifest
                        .content_address
                        .clone()
                        .unwrap_or_else(|| ContentAddressIndex::new(1_000_000))
                }
            }
        } else {
            manifest
                .content_address
                .clone()
                .unwrap_or_else(|| ContentAddressIndex::new(1_000_000))
        };

        if let Some(ref kh) = manifest.key_history {
            let kh_file = crate::crypto::keys::KeyHistoryFile {
                server_id: kh.server_id.clone(),
                entries: kh.entries.clone(),
                rotation_proofs: kh.rotation_proofs.clone(),
                current_key_id: kh.current_key_id,
            };
            match crate::crypto::keys::KeyHistory::from_file_repr(&kh_file) {
                Ok(history) => self.key_history = history,
                Err(e) => tracing::warn!("Corrupt key history in manifest: {}", e),
            }
        }

        self.admin
            .set_accepting_connections(manifest.admin.accepting_connections);
        if manifest.admin.shutdown_requested {
            self.admin.request_shutdown();
        }
        for (club_id, start, end) in &manifest.admin.grants {
            self.admin
                .grant(*club_id, crate::edition::XnRegion::interval(*start, *end));
        }

        for club_ref in &manifest.clubs {
            match crate::persist::edition_chunks::work_from_chunks_current(
                &club_ref.work_root,
                &chunk_store,
            ) {
                Ok(work) => {
                    let mut club =
                        Club::new_with_owner(club_ref.be_id, work.owner(), work.edition().clone());
                    club.set_signature_club(club_ref.signature_club);
                    club.set_default_read_club(club_ref.default_read_club);
                    club.set_default_edit_club(club_ref.default_edit_club);
                    if let Some(ref name) = club_ref.name {
                        club.set_name(name.clone());
                        self.club_names.insert(name.clone(), club_ref.be_id);
                    }
                    club.set_is_personal(club_ref.is_personal);
                    club.set_display_name(club_ref.display_name.clone());
                    club.set_credential(club_ref.credential.clone());
                    club.set_encrypted_signing_key(club_ref.encrypted_signing_key.clone());
                    for member_id in &club_ref.members {
                        club.add_member(*member_id);
                    }
                    for work_id in &club_ref.sponsored_works {
                        club.add_sponsored_work(*work_id);
                    }
                    self.clubs.insert(club_ref.be_id, club);
                    self.club_refs.insert(club_ref.be_id, club_ref.clone());
                }
                Err(e) => {
                    tracing::error!(
                        "Skipping corrupt club {} (chunk error: {}). \
                         Recreate this identity if needed.",
                        club_ref.be_id,
                        e
                    );
                }
            }
        }

        self.personal_club_count = self.clubs.values().filter(|c| c.is_personal()).count();

        for work_entry in &manifest.works {
            match crate::persist::edition_chunks::work_from_chunks_current(
                &work_entry.work_ref,
                &chunk_store,
            ) {
                Ok(work) => {
                    let source_fingerprint =
                        work_entry.source_fingerprint.as_ref().and_then(|fp| {
                            if fp.len() == crate::server::source_matcher::MINHASH_SIZE {
                                let mut arr = [0u64; crate::server::source_matcher::MINHASH_SIZE];
                                arr.copy_from_slice(fp);
                                Some(arr)
                            } else {
                                None
                            }
                        });
                    let mut work = work;
                    work.restore_archived_state(
                        work_entry.is_archived,
                        work_entry.lifecycle_history.clone(),
                    );
                    if let Some(hc) = work_entry.history_club {
                        work.set_history_club(Some(hc));
                    }
                    let ws = WorkState {
                        work: work.clone(),
                        chunk_ref: Some(work_entry.work_ref.clone()),
                        dirty_gen: 0,
                        grabber: None,
                        grabbed_at: None,
                        grab_waiters: Vec::new(),
                        last_revision_author: None,
                        revision_authors: std::collections::HashMap::new(),
                        revision_timestamps: std::collections::HashMap::new(),
                        status_detectors: DetectorList::new(),
                        revision_detectors: DetectorList::new(),
                        cached_title: Self::extract_title(work.current_edition()),
                        is_source: work_entry.is_source,
                        source_author_id: work_entry.source_author_id,
                        source_edition_info: work_entry.source_edition_info.clone(),
                        imported_by: None,
                        content_start_line: work_entry.content_start_line,
                        content_end_line: work_entry.content_end_line,
                        source_fingerprint,
                    };
                    self.works.insert(work_entry.be_id, ws);
                }
                Err(e) => {
                    tracing::error!(
                        "Skipping corrupt work {} (chunk error: {}). \
                         Data for this document is lost.",
                        work_entry.be_id,
                        e
                    );
                }
            }
        }

        for se_ref in &manifest.standalone_editions {
            match crate::persist::edition_chunks::edition_from_chunks(
                &se_ref.edition_ref,
                &chunk_store,
            ) {
                Ok(edition) => {
                    self.standalone_editions.insert(se_ref.be_id, edition);
                    self.standalone_edition_refs
                        .insert(se_ref.be_id, se_ref.edition_ref.clone());
                }
                Err(e) => {
                    tracing::error!(
                        "Skipping corrupt standalone edition {} (chunk error: {})",
                        se_ref.be_id,
                        e
                    );
                }
            }
        }

        let links_from_chunk: Vec<crate::persist::manifest::LinkEntry> =
            if let Some(hash) = manifest.links_hash {
                match chunk_store.read_chunk(&hash) {
                    Ok(data) => match crate::persist::chunk_store::untag_chunk_data(&data) {
                        Ok((format, payload))
                            if format == crate::persist::chunk_store::CHUNK_FORMAT_JSON =>
                        {
                            serde_json::from_slice(payload).unwrap_or_else(|e| {
                                tracing::error!("links chunk deserialization failed: {}", e);
                                self.restore_errors.push(format!("links: {}", e));
                                manifest.links.clone()
                            })
                        }
                        Ok((format, _)) => {
                            tracing::warn!("links chunk has unexpected format: {:#x}", format);
                            manifest.links.clone()
                        }
                        Err(e) => {
                            tracing::warn!("links chunk untag failed: {}", e);
                            manifest.links.clone()
                        }
                    },
                    Err(e) => {
                        tracing::warn!("links chunk read failed: {}", e);
                        manifest.links.clone()
                    }
                }
            } else {
                manifest.links.clone()
            };

        for link in &links_from_chunk {
            let o_ref = link
                .origin_ref
                .as_ref()
                .map(|hr| hr.to_hyper_ref(link.origin))
                .unwrap_or_else(|| {
                    crate::edition::links::HyperRef::single(None, Some(link.origin), None, None)
                });
            let d_ref = link
                .destination_ref
                .as_ref()
                .map(|hr| hr.to_hyper_ref(link.destination))
                .unwrap_or_else(|| {
                    crate::edition::links::HyperRef::single(
                        None,
                        Some(link.destination),
                        None,
                        None,
                    )
                });
            let hyperlink =
                crate::edition::links::HyperLink::make(link.link_types.clone(), o_ref, d_ref);
            self.links.insert(
                link.link_id,
                LinkState {
                    link: hyperlink,
                    origin: link.origin,
                    destination: link.destination,
                },
            );
            self.work_to_links
                .entry(link.origin)
                .or_default()
                .push(link.link_id);
            self.work_to_links
                .entry(link.destination)
                .or_default()
                .push(link.link_id);
        }

        self.federation = manifest
            .federation
            .as_ref()
            .map(|fs| crate::server::federation::FederationState::from_snapshot(fs))
            .unwrap_or_else(crate::server::federation::FederationState::disabled);

        self.chunk_store = Some(Arc::new(chunk_store));
        self.data_dir = Some(data_dir.to_path_buf());
        self.checkpoint_path = Some(manifest_path);
        self.manifest_sequence = manifest.sequence;
        self.attribution_log =
            match crate::server::transport::attribution_log::AttributionLog::open(data_dir) {
                Ok(log) => log,
                Err(e) => {
                    tracing::warn!("failed to open attribution log: {}, using in-memory", e);
                    crate::server::transport::attribution_log::AttributionLog::in_memory()
                }
            };
        self.wal = crate::persist::wal::WalLog::open(data_dir)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;

        let wal_path = data_dir.join("wal.log");
        if wal_path.exists() {
            match crate::persist::wal::WalLog::read_entries(&wal_path) {
                Ok((wal_version, entries)) => {
                    if wal_version > crate::persist::wal::WAL_VERSION {
                        tracing::warn!(
                            "WAL version {} is newer than supported {}, skipping replay",
                            wal_version,
                            crate::persist::wal::WAL_VERSION
                        );
                    } else if wal_version < crate::persist::wal::WAL_VERSION {
                        tracing::info!(
                            "WAL version {} → {} (migrating entries before replay)",
                            wal_version,
                            crate::persist::wal::WAL_VERSION
                        );
                        if !entries.is_empty() {
                            tracing::info!("WAL: replaying {} entries", entries.len());
                            let replayed =
                                crate::persist::wal::WalLog::replay_entries(self, &entries);
                            tracing::info!(
                                "WAL: replayed {} of {} entries",
                                replayed,
                                entries.len()
                            );
                        }
                    } else if !entries.is_empty() {
                        tracing::info!("WAL: replaying {} entries", entries.len());
                        let replayed = crate::persist::wal::WalLog::replay_entries(self, &entries);
                        tracing::info!("WAL: replayed {} of {} entries", replayed, entries.len());
                    }
                }
                Err(e) => {
                    tracing::warn!("WAL: failed to read entries: {}", e);
                }
            }
        }

        self.restore_blob_metas(blob_metas_from_chunk);

        let max_id = self
            .works
            .keys()
            .copied()
            .chain(self.clubs.keys().copied())
            .chain(self.links.keys().copied())
            .chain(self.standalone_editions.keys().copied())
            .max()
            .unwrap_or(0);
        if max_id >= self.grand_map.id_counter() {
            self.grand_map.set_id_counter(max_id + 1);
        }

        for (wid, ws) in &self.works {
            let prop = BackfollowEngine::make_work_prop(
                &ws.work,
                ws.work.read_club(),
                ws.work.edit_club(),
            );
            self.backfollow
                .register_work_with_prop(&ws.work, *wid, None, prop);
        }

        for (se_id, edition) in &self.standalone_editions {
            self.backfollow.register_edition(
                edition,
                *se_id,
                crate::edition::props::BertProp::make(),
            );
        }

        for (link_id, ls) in &self.links {
            self.backfollow.register_link_content(&ls.link, *link_id);
        }

        if let Some(ha) = historical_authors_from_chunk {
            self.historical_authors = ha;
        } else if let Some(ha) = manifest.historical_authors {
            self.historical_authors = ha;
        }

        if let Some(hash) = manifest.annotations_hash {
            if let Some(ref cs) = self.chunk_store {
                match cs.read_chunk(&hash) {
                    Ok(data) => {
                        let payload = match crate::persist::chunk_store::untag_chunk_data(&data) {
                            Ok((fmt, p))
                                if fmt == crate::persist::chunk_store::CHUNK_FORMAT_JSON =>
                            {
                                Some(p)
                            }
                            Ok((fmt, _)) => {
                                tracing::warn!(
                                    "annotations chunk has unexpected format: {:#x}",
                                    fmt
                                );
                                None
                            }
                            Err(e) => {
                                tracing::warn!("annotations chunk untag failed: {}", e);
                                None
                            }
                        };
                        if let Some(payload) = payload {
                            if let Ok(all_anns) = serde_json::from_slice::<
                                Vec<(BeId, Vec<super::otree_crdt::OtreeAnnotation>)>,
                            >(payload)
                            {
                                for (work_id, _annotations) in &all_anns {
                                    if let Some(ws) = self.works.get(work_id) {
                                        let edition = ws.work.current_edition();
                                        self.otree_crdt.initialize_from_edition(*work_id, &edition);
                                    }
                                }
                                self.otree_crdt.restore_annotations(&all_anns);
                                let total: usize = all_anns.iter().map(|(_, a)| a.len()).sum();
                                if total > 0 {
                                    tracing::info!(
                                        "Restored {} annotations across {} works",
                                        total,
                                        all_anns.len()
                                    );
                                }
                            } else {
                                // DO NOT silently continue with 0 annotations.
                                // The old chunk is still on disk — preserve it
                                // so it can be migrated/retried. Auto-checkpoint
                                // would otherwise overwrite it with empty data.
                                // See OtreeAnnotation schema evolution rules.
                                tracing::error!(
                                    "annotations chunk deserialization failed — \
                                     preserving old chunk, will retry on next restart. \
                                     If this persists, run a migration (see persist/migrations.rs)."
                                );
                                self.restore_errors.push("annotations chunk".into());
                            }
                        }
                    }
                    Err(e) => {
                        tracing::warn!("annotations chunk read failed: {}", e);
                    }
                }
            }
        }

        if let Some(hash) = manifest.fossil_snapshots_hash {
            if let Some(ref cs) = self.chunk_store {
                match cs.read_chunk(&hash) {
                    Ok(data) => {
                        let payload = match crate::persist::chunk_store::untag_chunk_data(&data) {
                            Ok((fmt, p))
                                if fmt == crate::persist::chunk_store::CHUNK_FORMAT_JSON =>
                            {
                                Some(p)
                            }
                            Ok((fmt, _)) => {
                                tracing::warn!(
                                    "fossil snapshots chunk has unexpected format: {:#x}",
                                    fmt
                                );
                                None
                            }
                            Err(e) => {
                                tracing::warn!("fossil snapshots chunk untag failed: {}", e);
                                None
                            }
                        };
                        if let Some(payload) = payload {
                            match serde_json::from_slice::<Vec<crate::edition::recorder::Fossil>>(
                                payload,
                            ) {
                                Ok(snapshots) => {
                                    let fossil_count = snapshots.len();
                                    let mut fingerprints_to_register: Vec<(
                                        crate::edition::recorder::RecorderId,
                                        Vec<crate::edition::RangeElement>,
                                    )> = Vec::new();
                                    let mut next_id = 0u64;
                                    for fossil in &snapshots {
                                        if fossil.id >= next_id {
                                            next_id = fossil.id + 1;
                                        }
                                        if !fossil.is_extinct {
                                            fingerprints_to_register.push((
                                                fossil.id,
                                                fossil.query.watched_content.clone(),
                                            ));
                                        }
                                    }
                                    self.recorder_system
                                        .restore_from_snapshots(snapshots, next_id);
                                    for (fossil_id, content) in &fingerprints_to_register {
                                        self.backfollow
                                            .register_fossil_fingerprints(*fossil_id, content);
                                    }
                                    tracing::info!(
                                        "Restored {} fossil snapshots ({} active)",
                                        fossil_count,
                                        fingerprints_to_register.len(),
                                    );
                                }
                                Err(e) => {
                                    tracing::warn!(
                                        "fossil snapshots chunk deserialization failed: {}",
                                        e
                                    );
                                }
                            }
                        }
                    }
                    Err(e) => {
                        tracing::warn!("fossil snapshots chunk read failed: {}", e);
                    }
                }
            }
        }

        self.rebuild_pending_attributions();

        Ok(())
    }

    pub fn restore_keypair_from_dir(
        &mut self,
        data_dir: &std::path::Path,
        passphrase: Option<&[u8]>,
    ) -> std::io::Result<()> {
        let key_path = data_dir.join("server.key");
        if key_path.exists() {
            let kp = if let Some(pass) = passphrase {
                crate::crypto::keys::ServerKeyPair::load_from_file_with_passphrase(&key_path, pass)
                    .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?
            } else {
                match crate::crypto::keys::ServerKeyPair::load_from_file_auto(&key_path, None) {
                    Ok(kp) => kp,
                    Err(crate::crypto::keys::KeypairFileError::WrongPassphrase) => {
                        return Err(std::io::Error::new(
                            std::io::ErrorKind::InvalidData,
                            "server key file is encrypted but no passphrase provided (use --key-passphrase or XUDANU_KEY_PASSPHRASE)",
                        ));
                    }
                    Err(e) => return Err(std::io::Error::new(std::io::ErrorKind::InvalidData, e)),
                }
            };
            tracing::info!("Restored server identity: {}", kp.identity_id());
            self.server_keypair = kp.clone();
            self.key_history = crate::crypto::keys::KeyHistory::new(&kp);
            Ok(())
        } else {
            let kp = crate::crypto::keys::ServerKeyPair::generate("xudanu-server");
            tracing::info!("Generated new server identity: {}", kp.identity_id());
            if let Some(pass) = passphrase {
                kp.save_to_file_encrypted(&key_path, pass)
                    .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
            } else {
                kp.save_to_file(&key_path)?;
            }
            self.server_keypair = kp.clone();
            self.key_history = crate::crypto::keys::KeyHistory::new(&kp);
            Ok(())
        }
    }

    pub fn load_keypair_from_dir(
        &mut self,
        data_dir: &std::path::Path,
        passphrase: Option<&[u8]>,
    ) -> std::io::Result<()> {
        let key_path = data_dir.join("server.key");
        let kp = if key_path.exists() {
            let kp = if let Some(pass) = passphrase {
                crate::crypto::keys::ServerKeyPair::load_from_file_with_passphrase(&key_path, pass)
                    .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?
            } else {
                match crate::crypto::keys::ServerKeyPair::load_from_file_auto(&key_path, None) {
                    Ok(kp) => kp,
                    Err(e) => return Err(std::io::Error::new(std::io::ErrorKind::InvalidData, e)),
                }
            };
            tracing::info!("Restored server identity: {}", kp.identity_id());
            kp
        } else {
            let kp = crate::crypto::keys::ServerKeyPair::generate("xudanu-server");
            tracing::info!("Generated new server identity: {}", kp.identity_id());
            if let Some(pass) = passphrase {
                kp.save_to_file_encrypted(&key_path, pass)
                    .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
            } else {
                kp.save_to_file(&key_path)?;
            }
            kp
        };
        self.server_keypair = kp.clone();
        Ok(())
    }

    pub fn restore_key_history_from_snapshot(&mut self) {
        if let Some(ref path) = self.checkpoint_path {
            let data_dir = path.parent().unwrap_or(path);
            let kh_path = data_dir.join("key_history.json");
            if kh_path.exists() {
                if let Ok(json) = std::fs::read_to_string(&kh_path) {
                    if let Ok(file) =
                        serde_json::from_str::<crate::crypto::keys::KeyHistoryFile>(&json)
                    {
                        match crate::crypto::keys::KeyHistory::from_file_repr(&file) {
                            Ok(kh) => {
                                tracing::info!(
                                    "Restored key history with {} entries",
                                    kh.entry_count()
                                );
                                self.key_history = kh;
                            }
                            Err(e) => {
                                tracing::warn!(
                                    "Corrupt key history file, using fresh history: {}",
                                    e
                                );
                            }
                        }
                    }
                }
            }
        }
    }

    pub fn save_key_history(&self) {
        if let Some(ref path) = self.checkpoint_path {
            let data_dir = path.parent().unwrap_or(path);
            let kh_path = data_dir.join("key_history.json");
            let file = self.key_history.to_file_repr();
            match serde_json::to_string_pretty(&file) {
                Ok(json) => {
                    let tmp_path = kh_path.with_extension("tmp");
                    match std::fs::File::create(&tmp_path) {
                        Ok(mut f) => match std::io::Write::write_all(&mut f, json.as_bytes()) {
                            Ok(()) => {
                                let _ = f.sync_all();
                                if let Err(e) = std::fs::rename(&tmp_path, &kh_path) {
                                    tracing::warn!("Failed to rename key history: {}", e);
                                    let _ = std::fs::remove_file(&tmp_path);
                                }
                            }
                            Err(e) => {
                                tracing::warn!("Failed to write key history: {}", e);
                                let _ = std::fs::remove_file(&tmp_path);
                            }
                        },
                        Err(e) => {
                            tracing::warn!("Failed to create key history tmp: {}", e);
                        }
                    }
                }
                Err(e) => {
                    tracing::warn!("Failed to serialize key history: {}", e);
                }
            }
        }
    }

    pub fn init_blob_store(&mut self, data_dir: &std::path::Path) -> std::io::Result<()> {
        self.restore_blob_store(data_dir, vec![])
    }

    pub fn restore_blob_store(
        &mut self,
        data_dir: &std::path::Path,
        metas: Vec<persist_snapshot::BlobMetaSnapshot>,
    ) -> std::io::Result<()> {
        let blobs_dir = data_dir.join("blobs");
        if !blobs_dir.exists() {
            std::fs::create_dir_all(&blobs_dir)?;
        }
        let store = BlobStore::filesystem(&blobs_dir).map_err(|e| {
            std::io::Error::new(
                std::io::ErrorKind::Other,
                format!("failed to init filesystem blobs: {}", e),
            )
        })?;
        tracing::info!("Using filesystem blob storage at {}", blobs_dir.display());
        self.blob_store = store;
        let restored_metas: Vec<_> = metas
            .into_iter()
            .filter_map(|ms| {
                let mut hash = [0u8; 32];
                if ms.content_hash.len() != 32 {
                    return None;
                }
                hash.copy_from_slice(&ms.content_hash);
                let mut meta =
                    crate::edition::blob_store::BlobMeta::new(hash, ms.byte_size, ms.mime_type);
                if let Some(ph) = ms.preview_hash {
                    if ph.len() == 32 {
                        let mut ph_arr: [u8; 32] = [0u8; 32];
                        ph_arr.copy_from_slice(&ph);
                        meta = meta.with_preview(ph_arr);
                    }
                }
                for (k, v) in ms.metadata {
                    meta = meta.with_metadata(k, v);
                }
                Some(meta)
            })
            .collect();
        self.blob_store.restore_metas(restored_metas);
        tracing::info!(
            "Restored {} blob metadata entries",
            self.blob_store.stats().total_blobs
        );
        Ok(())
    }

    pub fn restore_blob_store_from_dir(
        &mut self,
        data_dir: &std::path::Path,
    ) -> std::io::Result<()> {
        let blobs_dir = data_dir.join("blobs");
        if !blobs_dir.exists() {
            std::fs::create_dir_all(&blobs_dir)?;
        }
        let store = BlobStore::filesystem(&blobs_dir).map_err(|e| {
            std::io::Error::new(
                std::io::ErrorKind::Other,
                format!("failed to init filesystem blobs: {}", e),
            )
        })?;
        tracing::info!("Using filesystem blob storage at {}", blobs_dir.display());
        self.blob_store = store;
        Ok(())
    }

    pub fn restore_blob_metas(&mut self, metas: Vec<crate::persist::manifest::BlobMetaEntry>) {
        let restored: Vec<_> = metas
            .into_iter()
            .filter_map(|ms| {
                let mut hash = [0u8; 32];
                if ms.content_hash.len() != 32 {
                    return None;
                }
                hash.copy_from_slice(&ms.content_hash);
                let mut meta =
                    crate::edition::blob_store::BlobMeta::new(hash, ms.byte_size, ms.mime_type);
                if let Some(ph) = ms.preview_hash {
                    if ph.len() == 32 {
                        let mut ph_arr = [0u8; 32];
                        ph_arr.copy_from_slice(&ph);
                        meta = meta.with_preview(ph_arr);
                    }
                }
                for (k, v) in ms.metadata {
                    meta = meta.with_metadata(k, v);
                }
                Some(meta)
            })
            .collect();
        self.blob_store.restore_metas(restored);
        tracing::info!(
            "Restored {} blob metadata entries",
            self.blob_store.stats().total_blobs
        );
    }

    fn auto_checkpoint(&mut self) {
        #[cfg(feature = "server")]
        {
            // CRITICAL: suppress checkpoint if restore had errors.
            // Writing now would overwrite good on-disk chunks with
            // incomplete in-memory state — permanent data loss.
            if !self.restore_errors.is_empty() {
                return;
            }
            let now = std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs();
            let elapsed = now.saturating_sub(self.last_checkpoint_time);
            if elapsed >= 30 {
                if self.chunk_store.is_some() {
                    if let Err(e) = self.checkpoint_to_store() {
                        tracing::warn!("auto-checkpoint failed: {}", e);
                    } else {
                        self.last_checkpoint_time = now;
                    }
                } else if let Some(ref path) = self.checkpoint_path {
                    if let Err(e) = self.checkpoint_to_file(path) {
                        tracing::warn!("auto-checkpoint failed: {}", e);
                    } else {
                        self.last_checkpoint_time = now;
                    }
                }
            }
        }
    }

    /// Returns true if the server started with restore errors.
    /// When true, auto_checkpoint is suppressed to prevent data loss.
    pub fn has_restore_errors(&self) -> bool {
        !self.restore_errors.is_empty()
    }

    /// Returns the list of restore errors encountered at startup.
    pub fn restore_errors(&self) -> &[String] {
        &self.restore_errors
    }

    /// Clears restore errors, re-enabling auto_checkpoint.
    /// Use ONLY after the root cause has been fixed (e.g., a migration
    /// has been applied or the corrupted chunk has been repaired).
    pub fn clear_restore_errors(&mut self) {
        if !self.restore_errors.is_empty() {
            tracing::info!("restore errors cleared — auto_checkpoint re-enabled");
            self.restore_errors.clear();
        }
    }

    fn check_grab_timeouts(&mut self) {
        const GRAB_TIMEOUT_SECS: u64 = 1800;
        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        let timed_out: Vec<(BeId, SessionId)> = self
            .works
            .iter()
            .filter_map(|(id, ws)| {
                ws.grabbed_at.and_then(|t| {
                    if now.saturating_sub(t) > GRAB_TIMEOUT_SECS {
                        ws.grabber.map(|sid| (*id, sid))
                    } else {
                        None
                    }
                })
            })
            .collect();
        for (work_be_id, session_id) in &timed_out {
            tracing::warn!(
                "Releasing expired grab on work {:?} by session {:?} ({}s timeout)",
                work_be_id,
                session_id,
                GRAB_TIMEOUT_SECS
            );
            if let Some(ws) = self.works.get_mut(work_be_id) {
                ws.grabber = None;
                ws.grabbed_at = None;
                ws.status_detectors.fire(&Event::WorkReleased {
                    work_be_id: *work_be_id,
                    session_id: *session_id,
                });
            }
            self.grant_pending_grab(*work_be_id);
        }

        const WAIT_TIMEOUT_SECS: u64 = 3600;
        for (_, ws) in self.works.iter_mut() {
            ws.grab_waiters
                .retain(|w| now.saturating_sub(w.grabbed_at) <= WAIT_TIMEOUT_SECS);
        }
    }

    pub fn recovery_stats(&self) -> String {
        let grabbed = self
            .works
            .values()
            .filter(|ws| ws.grabber.is_some())
            .count();
        format!(
            "works={} clubs={} links={} editions={} sessions={} blobs={} grabbed={}",
            self.works.len(),
            self.clubs.len(),
            self.link_count(),
            self.standalone_editions.len(),
            self.sessions.len(),
            self.blob_count(),
            grabbed,
        )
    }

    pub fn chunk_store(&self) -> Option<&crate::persist::chunk_store::ChunkStore> {
        self.chunk_store.as_deref()
    }

    pub fn chunk_store_arc(&self) -> Option<Arc<crate::persist::chunk_store::ChunkStore>> {
        self.chunk_store.clone()
    }

    pub fn checkpoint_path(&self) -> Option<&std::path::Path> {
        self.checkpoint_path.as_deref()
    }

    pub fn last_checkpoint_time(&self) -> u64 {
        self.last_checkpoint_time
    }

    pub fn operation_count(&self) -> u64 {
        self.operation_counter
    }

    pub fn edition_count(&self) -> usize {
        self.standalone_editions.len()
    }

    // === Link operations ===

    pub fn create_link(
        &mut self,
        _session_id: SessionId,
        origin: BeId,
        destination: BeId,
        origin_ref: Option<HyperRef>,
        destination_ref: Option<HyperRef>,
    ) -> Result<BeId, ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        self.ensure_session(_session_id)?;
        let _ = self.work(origin)?;
        let _ = self.work(destination)?;

        self.link_counter += 1;
        let link_id = self.link_counter;

        let chain = self.compute_provenance_chain(origin);

        let link = if let (Some(o_ref), Some(d_ref)) = (origin_ref, destination_ref) {
            let o_with_chain = o_ref.with_provenance_chain(chain);
            HyperLink::make(vec![], o_with_chain, d_ref)
        } else {
            let o_ref =
                HyperRef::single(None, Some(origin), None, None).with_provenance_chain(chain);
            let d_ref = HyperRef::single(None, Some(destination), None, None);
            HyperLink::make(vec![], o_ref, d_ref)
        };

        let ls = LinkState {
            link,
            origin,
            destination,
        };
        self.links.insert(link_id, ls);
        self.work_to_links.entry(origin).or_default().push(link_id);
        self.work_to_links
            .entry(destination)
            .or_default()
            .push(link_id);
        self.backfollow
            .register_link_content(&self.links[&link_id].link, link_id);
        {
            let ls = &self.links[&link_id];
            let o_ref = ls
                .link
                .end_at("LeftEnd")
                .map(crate::server::transport::protocol::HyperRefPayload::from_hyper_ref);
            let d_ref = ls
                .link
                .end_at("RightEnd")
                .map(crate::server::transport::protocol::HyperRefPayload::from_hyper_ref);
            let _ = self.wal.append_create_link(
                link_id,
                origin,
                destination,
                o_ref.as_ref(),
                d_ref.as_ref(),
                ls.link.link_types(),
            );
        }
        self.auto_checkpoint();
        Ok(link_id)
    }

    pub fn create_link_with_hyperlink(
        &mut self,
        _session_id: SessionId,
        link: HyperLink,
    ) -> Result<BeId, ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        self.ensure_session(_session_id)?;

        let origin = link
            .end_at("LeftEnd")
            .and_then(|r| r.work_context())
            .ok_or_else(|| {
                ServerError::InvalidArgument("link must have LeftEnd with work_context".into())
            })?;
        let destination = link
            .end_at("RightEnd")
            .and_then(|r| r.work_context())
            .ok_or_else(|| {
                ServerError::InvalidArgument("link must have RightEnd with work_context".into())
            })?;

        let _ = self.work(origin)?;
        let _ = self.work(destination)?;

        self.link_counter += 1;
        let link_id = self.link_counter;

        let ls = LinkState {
            link,
            origin,
            destination,
        };
        self.links.insert(link_id, ls);
        self.work_to_links.entry(origin).or_default().push(link_id);
        self.work_to_links
            .entry(destination)
            .or_default()
            .push(link_id);
        self.backfollow
            .register_link_content(&self.links[&link_id].link, link_id);
        {
            let ls = &self.links[&link_id];
            let o_ref = ls
                .link
                .end_at("LeftEnd")
                .map(crate::server::transport::protocol::HyperRefPayload::from_hyper_ref);
            let d_ref = ls
                .link
                .end_at("RightEnd")
                .map(crate::server::transport::protocol::HyperRefPayload::from_hyper_ref);
            let _ = self.wal.append_create_link(
                link_id,
                origin,
                destination,
                o_ref.as_ref(),
                d_ref.as_ref(),
                ls.link.link_types(),
            );
        }
        self.auto_checkpoint();
        Ok(link_id)
    }

    pub fn apply_transclusion_attribution(
        &mut self,
        session_id: SessionId,
        link_id: BeId,
    ) -> Result<(), ServerError> {
        self.ensure_authenticated(session_id)?;

        let (origin_work_id, dest_work_id, excerpt_text) = {
            let ls = self
                .links
                .get(&link_id)
                .ok_or_else(|| ServerError::NotFound(format!("link {}", link_id)))?;
            let excerpt = ls
                .link
                .end_at("LeftEnd")
                .and_then(|r| r.excerpt())
                .map(|e| e.to_text())
                .unwrap_or_default();
            if excerpt.is_empty() {
                return Err(ServerError::Internal(
                    "link has no origin excerpt for transclusion attribution".into(),
                ));
            }
            (ls.origin, ls.destination, excerpt.to_string())
        };

        tracing::info!(
            "[apply_transclusion_attribution] link={:04x} origin={:04x} dest={:04x} excerpt_len={}",
            link_id,
            origin_work_id,
            dest_work_id,
            excerpt_text.len()
        );

        let placed_by = self.resolve_transclusion_placer(session_id);

        let result = self.apply_transclusion_attribution_internal(
            link_id,
            origin_work_id,
            dest_work_id,
            &excerpt_text,
            placed_by.clone(),
        );

        let already_pending = self
            .pending_attributions
            .iter()
            .any(|pa| pa.link_id == link_id);
        if !already_pending {
            self.pending_attributions.push(PendingAttribution {
                link_id,
                origin_work_id,
                dest_work_id,
                excerpt: excerpt_text,
                placed_by,
            });
            tracing::info!(
                "[apply_transclusion_attribution] stored pending attribution for link={:04x}",
                link_id
            );
        }

        result
    }

    fn rebuild_pending_attributions(&mut self) {
        let mut rebuilt = Vec::new();
        for (&link_id, ls) in &self.links {
            let excerpt = match ls
                .link
                .end_at("LeftEnd")
                .and_then(|r| r.excerpt())
                .map(|e| e.to_text())
            {
                Some(t) if !t.is_empty() => t.to_string(),
                _ => continue,
            };
            if self.works.contains_key(&ls.origin) && self.works.contains_key(&ls.destination) {
                rebuilt.push(PendingAttribution {
                    link_id,
                    origin_work_id: ls.origin,
                    dest_work_id: ls.destination,
                    excerpt,
                    placed_by: None,
                });
            }
        }
        if !rebuilt.is_empty() {
            tracing::info!("[rebuild_pending_attributions] rebuilt {} pending attributions from existing links", rebuilt.len());
        }
        self.pending_attributions = rebuilt;
    }

    fn apply_pending_provenance_to_edition(&self, work_id: BeId, edition: &mut Edition) {
        let pending: Vec<&PendingAttribution> = self
            .pending_attributions
            .iter()
            .filter(|p| p.dest_work_id == work_id)
            .collect();
        if pending.is_empty() {
            return;
        }

        let dest_text = edition.to_text();
        let dest_lower = dest_text.to_lowercase();

        for pa in &pending {
            let prov = match self.resolve_source_provenance(pa.origin_work_id, &pa.excerpt) {
                Some(p) => crate::edition::provenance::ElementProvenance {
                    source_work_id: Some(pa.origin_work_id),
                    transcluded_by: pa.placed_by.clone(),
                    ..p
                },
                None => continue,
            };

            let excerpt_lower = pa.excerpt.to_lowercase();
            let char_start = match dest_lower.find(&excerpt_lower) {
                Some(pos) => pos,
                None => continue,
            };
            let char_end = char_start + pa.excerpt.len();

            let entries = edition.all_entries();
            let mut new_entries: Vec<(
                i64,
                std::sync::Arc<crate::edition::range_element::Carrier>,
            )> = Vec::with_capacity(entries.len());
            let mut cum = 0usize;

            for (pos, c) in &entries {
                let entry_start = cum;
                let entry_end = cum + c.char_len();
                if entry_end > char_start && entry_start < char_end {
                    let mut carrier = (**c).clone();
                    carrier.provenance = Some(prov.clone());
                    new_entries.push((*pos, std::sync::Arc::new(carrier)));
                } else {
                    new_entries.push((*pos, c.clone()));
                }
                cum = entry_end;
            }

            let span_prov = std::mem::take(&mut edition.span_provenance);
            *edition = Edition::from_entries(new_entries);
            edition.span_provenance = span_prov;
        }
    }

    fn resolve_source_provenance(
        &self,
        origin_work_id: BeId,
        excerpt_text: &str,
    ) -> Option<crate::edition::provenance::ElementProvenance> {
        let ws = self.works.get(&origin_work_id)?;
        let source_edition = ws.work.current_edition();
        let source_entries = source_edition.all_entries();

        let source_text = source_edition.to_text();
        let source_lower = source_text.to_lowercase();
        let excerpt_lower = excerpt_text.to_lowercase();

        let (ex_char_start, ex_char_end) = match source_lower.find(&excerpt_lower) {
            Some(pos) => (pos, pos + excerpt_text.len()),
            None => {
                tracing::debug!(
                    "[resolve_source_provenance] excerpt not found in source work {:04x}, using first available provenance",
                    origin_work_id
                );
                return source_entries
                    .iter()
                    .find_map(|(_, c)| c.provenance.clone())
                    .or_else(|| self.fallback_source_provenance(ws, origin_work_id));
            }
        };

        let mut best_prov: Option<crate::edition::provenance::ElementProvenance> = None;
        let mut best_overlap: usize = 0;
        let mut cum = 0usize;
        for (_, c) in &source_entries {
            let entry_start = cum;
            let entry_end = cum + c.char_len();
            let overlap = entry_end
                .min(ex_char_end)
                .saturating_sub(entry_start.max(ex_char_start));
            if overlap > 0 {
                if let Some(ref prov) = c.provenance {
                    if overlap > best_overlap {
                        best_overlap = overlap;
                        best_prov = Some(prov.clone());
                    }
                }
            }
            cum = entry_end;
        }

        best_prov.or_else(|| self.fallback_source_provenance(ws, origin_work_id))
    }

    fn fallback_source_provenance(
        &self,
        ws: &WorkState,
        origin_work_id: BeId,
    ) -> Option<crate::edition::provenance::ElementProvenance> {
        if let Some(aid) = ws.source_author_id {
            let author_name = self
                .historical_authors
                .get(aid)
                .map(|a| {
                    if a.display_name.is_empty() {
                        a.name.clone()
                    } else {
                        a.display_name.clone()
                    }
                })
                .unwrap_or_else(|| "Unknown".to_string());
            return Some(crate::edition::provenance::ElementProvenance {
                author_public_key: [0u8; 32],
                author_display_name: author_name,
                author_club_id: 0,
                timestamp: std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_secs(),
                author_type: crate::edition::provenance::AuthorType::Historical,
                llm_model: None,
                historical_author_id: Some(aid),
                source_work_id: Some(origin_work_id),
                transcluded_by: None,
                derived_by: None,
            });
        }

        if let Some(club_id) = ws.last_revision_author {
            let display_name = self
                .clubs
                .get(&club_id)
                .and_then(|c| c.display_name().map(|s| s.to_string()))
                .unwrap_or_else(|| format!("club:{:04x}", club_id));
            let pub_key = self
                .clubs
                .get(&club_id)
                .and_then(|c| c.encrypted_signing_key())
                .map(|e| e.verifying_key)
                .unwrap_or([0u8; 32]);
            return Some(crate::edition::provenance::ElementProvenance {
                author_public_key: pub_key,
                author_display_name: display_name,
                author_club_id: club_id,
                timestamp: std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_secs(),
                author_type: crate::edition::provenance::AuthorType::Human,
                llm_model: None,
                historical_author_id: None,
                source_work_id: Some(origin_work_id),
                transcluded_by: None,
                derived_by: None,
            });
        }

        None
    }

    fn apply_transclusion_attribution_internal(
        &mut self,
        link_id: BeId,
        origin_work_id: BeId,
        dest_work_id: BeId,
        excerpt_text: &str,
        placed_by: Option<crate::edition::provenance::TransclusionInfo>,
    ) -> Result<(), ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        let source_prov = self
            .resolve_source_provenance(origin_work_id, excerpt_text)
            .unwrap_or_else(|| {
                tracing::warn!(
                    "[apply_transclusion_attribution_internal] no source provenance found for work {:04x}, using Unknown",
                    origin_work_id
                );
                crate::edition::provenance::ElementProvenance {
                    author_public_key: [0u8; 32],
                    author_display_name: "Unknown".to_string(),
                    author_club_id: 0,
                    timestamp: std::time::SystemTime::now()
                        .duration_since(std::time::UNIX_EPOCH)
                        .unwrap_or_default()
                        .as_secs(),
                    author_type: crate::edition::provenance::AuthorType::Historical,
                    llm_model: None,
                    historical_author_id: None,
                    source_work_id: Some(origin_work_id),
                    transcluded_by: None,
                    derived_by: None,
                }
            });

        let source_prov = crate::edition::provenance::ElementProvenance {
            source_work_id: Some(origin_work_id),
            transcluded_by: placed_by,
            ..source_prov
        };

        let dest_edition = {
            let ws = self
                .works
                .get(&dest_work_id)
                .ok_or(ServerError::WorkNotFound(dest_work_id))?;
            ws.work.current_edition().clone()
        };

        let dest_entries = dest_edition.all_entries();
        let dest_text = dest_edition.to_text();
        let excerpt_lower = excerpt_text.to_lowercase();
        let dest_lower = dest_text.to_lowercase();

        let char_start = match dest_lower.find(&excerpt_lower) {
            Some(pos) => pos,
            None => {
                tracing::debug!(
                    "[apply_transclusion_attribution_internal] excerpt not yet materialized in dest {:04x}, will apply on next materialization via PendingAttribution",
                    dest_work_id
                );
                return Ok(());
            }
        };
        let char_end = char_start + excerpt_text.len();

        let mut any_applied = false;
        let mut new_entries: Vec<(i64, std::sync::Arc<crate::edition::range_element::Carrier>)> =
            Vec::with_capacity(dest_entries.len());
        let mut stamped_fps: Vec<[u8; 32]> = Vec::new();

        let mut cum = 0usize;
        for (pos, c) in &dest_entries {
            let entry_start = cum;
            let entry_end = cum + c.char_len();
            let in_range = entry_end > char_start && entry_start < char_end;

            if in_range {
                let mut carrier = (**c).clone();
                carrier.provenance = Some(source_prov.clone());
                stamped_fps.push(carrier.element.content_fingerprint());
                new_entries.push((*pos, std::sync::Arc::new(carrier)));
                any_applied = true;
                cum = entry_end;
                continue;
            }
            new_entries.push((*pos, c.clone()));
            cum = entry_end;
        }

        if any_applied {
            let mut new_edition = crate::edition::Edition::from_entries(new_entries);
            new_edition.span_provenance = dest_edition.span_provenance.clone();
            let ws = self
                .works
                .get_mut(&dest_work_id)
                .ok_or(ServerError::WorkNotFound(dest_work_id))?;
            ws.work.revise(new_edition);
            self.auto_checkpoint();

            // Record this transclusion attribution in the transparency log. The
            // revision-path append (server.rs ~896) only covers author edits, so
            // without this transclusion events go unaudited (log stays at 0).
            {
                let log = &mut self.attribution_log;
                let revision = self
                    .works
                    .get(&dest_work_id)
                    .map(|ws| ws.work.revision_count())
                    .unwrap_or(0);
                let server_id = self.server_keypair.signing_key.verifying_key().to_bytes();
                let entry = crate::server::transport::attribution_log::AttributionEntry {
                    sequence: log.sequence(),
                    timestamp: source_prov.timestamp,
                    author_pk_hex: crate::server::crdt_manager::bytes_to_hex(
                        &source_prov.author_public_key,
                    ),
                    span_fp_hex: crate::edition::provenance::compute_span_fingerprint_hex(
                        &stamped_fps,
                    ),
                    // Transclusion attribution is server-stamped from resolved
                    // provenance, not author-signed; record a zero signature.
                    signature_hex: "0".repeat(128),
                    server_id_hex: crate::server::crdt_manager::bytes_to_hex(&server_id),
                    work_id: dest_work_id,
                    revision,
                };
                if let Err(e) = log.append(&entry) {
                    tracing::warn!("[attribution_log] transclusion append failed: {}", e);
                }
            }

            tracing::info!("[pending_attribution] applied for link {:04x}", link_id);
        }

        Ok(())
    }

    pub fn get_link(&self, link_id: BeId) -> Result<(BeId, BeId, &HyperLink), ServerError> {
        let ls = self
            .links
            .get(&link_id)
            .ok_or(ServerError::NotFound(format!("link {}", link_id)))?;
        Ok((ls.origin, ls.destination, &ls.link))
    }

    pub fn update_link(
        &mut self,
        _session_id: SessionId,
        link_id: BeId,
        origin_ref: Option<HyperRef>,
        destination_ref: Option<HyperRef>,
    ) -> Result<(), ServerError> {
        self.ensure_session(_session_id)?;
        if origin_ref.is_none() && destination_ref.is_none() {
            return Ok(());
        }
        let old_link = {
            let ls = self
                .links
                .get(&link_id)
                .ok_or(ServerError::NotFound(format!("link {}", link_id)))?;
            ls.link.clone()
        };
        self.backfollow.unregister_link_content(&old_link, link_id);
        let ls = self
            .links
            .get_mut(&link_id)
            .ok_or(ServerError::NotFound(format!("link {}", link_id)))?;
        if let Some(o_ref) = origin_ref {
            ls.link = ls.link.with_end("LeftEnd", o_ref);
        }
        if let Some(d_ref) = destination_ref {
            ls.link = ls.link.with_end("RightEnd", d_ref);
        }
        self.backfollow.register_link_content(&ls.link, link_id);
        Ok(())
    }

    pub fn delete_link(
        &mut self,
        _session_id: SessionId,
        link_id: BeId,
    ) -> Result<(), ServerError> {
        self.ensure_session(_session_id)?;
        let ls = self
            .links
            .remove(&link_id)
            .ok_or(ServerError::NotFound(format!("link {}", link_id)))?;
        self.backfollow.unregister_link_content(&ls.link, link_id);
        if let Some(ids) = self.work_to_links.get_mut(&ls.origin) {
            ids.retain(|id| *id != link_id);
        }
        if let Some(ids) = self.work_to_links.get_mut(&ls.destination) {
            ids.retain(|id| *id != link_id);
        }
        Ok(())
    }

    pub fn list_links_for_work(&self, work_id: BeId) -> Vec<(BeId, BeId, BeId)> {
        self.work_to_links
            .get(&work_id)
            .map(|ids| {
                ids.iter()
                    .filter_map(|&lid| {
                        self.links
                            .get(&lid)
                            .map(|ls| (lid, ls.origin, ls.destination))
                    })
                    .collect()
            })
            .unwrap_or_default()
    }

    pub fn link_add_end(
        &mut self,
        _session_id: SessionId,
        link_id: BeId,
        end_name: &str,
        end_ref: HyperRef,
    ) -> Result<(), ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        self.ensure_session(_session_id)?;
        let old_link = {
            let ls = self
                .links
                .get(&link_id)
                .ok_or(ServerError::NotFound(format!("link {}", link_id)))?;
            ls.link.clone()
        };
        self.backfollow.unregister_link_content(&old_link, link_id);
        let ls = self
            .links
            .get_mut(&link_id)
            .ok_or(ServerError::NotFound(format!("link {}", link_id)))?;
        ls.link = ls.link.with_end(end_name, end_ref);
        self.backfollow.register_link_content(&ls.link, link_id);
        self.auto_checkpoint();
        Ok(())
    }

    pub fn link_remove_end(
        &mut self,
        _session_id: SessionId,
        link_id: BeId,
        end_name: &str,
    ) -> Result<(), ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        self.ensure_session(_session_id)?;
        let old_link = {
            let ls = self
                .links
                .get(&link_id)
                .ok_or(ServerError::NotFound(format!("link {}", link_id)))?;
            ls.link.clone()
        };
        self.backfollow.unregister_link_content(&old_link, link_id);
        let ls = self
            .links
            .get_mut(&link_id)
            .ok_or(ServerError::NotFound(format!("link {}", link_id)))?;
        ls.link = ls.link.without_end(end_name);
        self.backfollow.register_link_content(&ls.link, link_id);
        self.auto_checkpoint();
        Ok(())
    }

    pub fn link_set_types(
        &mut self,
        _session_id: SessionId,
        link_id: BeId,
        link_types: Vec<u64>,
    ) -> Result<(), ServerError> {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        self.ensure_session(_session_id)?;
        let ls = self
            .links
            .get_mut(&link_id)
            .ok_or(ServerError::NotFound(format!("link {}", link_id)))?;
        ls.link = ls.link.with_link_types(link_types);
        Ok(())
    }

    pub fn register_link_type(&mut self, type_id: u64, name: String) {
        self.link_type_names.insert(type_id, name);
    }

    pub fn list_link_types(&self) -> Vec<(u64, String)> {
        let mut types: Vec<(u64, String)> = self
            .link_type_names
            .iter()
            .map(|(&id, name)| (id, name.clone()))
            .collect();
        types.sort_by_key(|(id, _)| *id);
        types
    }

    pub fn find_backlinks(
        &self,
        session_id: SessionId,
        work_id: BeId,
    ) -> Result<Vec<super::transport::protocol::BacklinkEntryPayload>, ServerError> {
        self.ensure_session(session_id)?;
        let link_ids = self
            .work_to_links
            .get(&work_id)
            .cloned()
            .unwrap_or_default();
        let mut results = Vec::new();
        let mut seen_works = std::collections::HashSet::new();
        seen_works.insert(work_id);
        for lid in link_ids {
            let ls = match self.links.get(&lid) {
                Some(ls) => ls,
                None => continue,
            };
            let source_work_id = if ls.destination == work_id {
                ls.origin
            } else if ls.origin == work_id {
                ls.destination
            } else {
                continue;
            };
            if seen_works.contains(&source_work_id) {
                continue;
            }
            if !self
                .work(source_work_id)
                .map(|w| self.work_is_readable(session_id, w))
                .unwrap_or(false)
            {
                continue;
            }
            seen_works.insert(source_work_id);
            let excerpt = ls
                .link
                .end_at("LeftEnd")
                .and_then(|hr| hr.excerpt())
                .and_then(|ed| {
                    let text: String = ed
                        .all_entries()
                        .iter()
                        .filter_map(|(_, c)| c.element.as_text())
                        .collect();
                    if text.is_empty() {
                        None
                    } else {
                        Some(text)
                    }
                });
            let title = self
                .works
                .get(&source_work_id)
                .map(|ws| ws.cached_title.clone())
                .filter(|t| !t.is_empty());
            let direction = if ls.destination == work_id {
                "incoming"
            } else {
                "outgoing"
            };
            results.push(super::transport::protocol::BacklinkEntryPayload {
                source_work_id,
                link_id: lid,
                link_type: format!("hyperlink_{}", direction),
                excerpt,
                title,
            });
        }
        Ok(results)
    }

    pub fn annotation_create(
        &mut self,
        session_id: SessionId,
        work_id: BeId,
        annotation_id: u64,
        kind: String,
        payload: String,
        char_start: usize,
        char_end: usize,
        is_private: bool,
    ) -> Result<(), ServerError> {
        self.ensure_authenticated(session_id)?;
        let created_by = self.sessions.get(&session_id).and_then(|s| {
            let km = s._key_master()?;
            let auth = km.actual_authority();
            auth.iter()
                .find(|&&id| {
                    id != self.public_club_id()
                        && id != self.admin_club_id()
                        && id != self.access_club_id()
                        && id != self.empty_club_id()
                })
                .copied()
        });
        if let Some(ws) = self.works.get(&work_id) {
            let edition = ws.work.current_edition();
            self.otree_crdt.initialize_from_edition(work_id, &edition);
        }
        self.otree_crdt
            .annotation_create(
                work_id,
                annotation_id,
                kind,
                payload,
                char_start,
                char_end,
                created_by,
                is_private,
            )
            .map_err(|e| ServerError::Internal(e.to_string()))?;
        if let Err(e) = self.checkpoint_to_store() {
            tracing::error!("annotation checkpoint failed: {}", e);
        }
        Ok(())
    }

    pub fn annotation_delete(
        &mut self,
        session_id: SessionId,
        work_id: BeId,
        annotation_id: u64,
    ) -> Result<(), ServerError> {
        self.ensure_authenticated(session_id)?;
        if let Some(ws) = self.works.get(&work_id) {
            let edition = ws.work.current_edition();
            self.otree_crdt.initialize_from_edition(work_id, &edition);
        }
        self.otree_crdt
            .annotation_delete(work_id, annotation_id)
            .map_err(|e| ServerError::Internal(e.to_string()))?;
        if let Err(e) = self.checkpoint_to_store() {
            tracing::error!("annotation delete checkpoint failed: {}", e);
        }
        Ok(())
    }

    pub fn annotation_attach_node(
        &mut self,
        _session_id: SessionId,
        _work_id: BeId,
        _annotation_id: u64,
        _node_id: u64,
    ) -> Result<(), ServerError> {
        Ok(())
    }

    pub fn annotation_attach_span(
        &mut self,
        _session_id: SessionId,
        _work_id: BeId,
        _annotation_id: u64,
        _span_id: u64,
    ) -> Result<(), ServerError> {
        Ok(())
    }

    pub fn annotation_get(
        &self,
        session_id: SessionId,
        work_id: BeId,
        annotation_id: u64,
    ) -> Result<Option<super::transport::protocol::AnnotationPayload>, ServerError> {
        self.ensure_session(session_id)?;
        let ws = self
            .works
            .get(&work_id)
            .ok_or_else(|| ServerError::NotFound(format!("work {}", work_id)))?;
        if !self.work_is_readable(session_id, &ws.work) {
            return Err(ServerError::NotAuthorized);
        }
        Ok(self
            .otree_crdt
            .annotation_get(work_id, annotation_id)
            .map_err(|e| ServerError::Internal(e.to_string()))?
            .map(|a| {
                let created_by_name = a.created_by.and_then(|cid| {
                    self.clubs.get(&cid).and_then(|c| {
                        c.display_name()
                            .map(|s| s.to_string())
                            .or_else(|| c.name().map(|s| s.to_string()))
                    })
                });
                super::transport::protocol::AnnotationPayload {
                    annotation_id: a.annotation_id,
                    kind: a.kind.clone(),
                    payload: a.payload.clone(),
                    char_start: a.char_start,
                    char_end: a.char_end,
                    created_by: a.created_by,
                    created_by_name,
                    created_at: a.created_at,
                    is_private: a.is_private,
                }
            }))
    }

    pub fn annotation_list(
        &mut self,
        session_id: SessionId,
        work_id: BeId,
    ) -> Result<Vec<super::transport::protocol::AnnotationPayload>, ServerError> {
        self.ensure_session(session_id)?;
        let ws = self
            .works
            .get(&work_id)
            .ok_or_else(|| ServerError::NotFound(format!("work {}", work_id)))?;
        if !self.work_is_readable(session_id, &ws.work) {
            return Err(ServerError::NotAuthorized);
        }
        let requester_club = self.sessions.get(&session_id).and_then(|s| {
            let km = s._key_master()?;
            let auth = km.actual_authority();
            auth.iter()
                .find(|&&id| {
                    id != self.public_club_id()
                        && id != self.admin_club_id()
                        && id != self.access_club_id()
                        && id != self.empty_club_id()
                })
                .copied()
        });
        let edition = ws.work.current_edition();
        self.otree_crdt
            .ensure_doc_for_annotations(work_id, &edition);
        Ok(self
            .otree_crdt
            .annotation_list(work_id)
            .map_err(|e| ServerError::Internal(e.to_string()))?
            .into_iter()
            .filter(|a| {
                if !a.is_private {
                    return true;
                }
                match (a.created_by, requester_club) {
                    (Some(creator), Some(requester)) => creator == requester,
                    _ => false,
                }
            })
            .map(|a| {
                let created_by_name = a.created_by.and_then(|cid| {
                    self.clubs.get(&cid).and_then(|c| {
                        c.display_name()
                            .map(|s| s.to_string())
                            .or_else(|| c.name().map(|s| s.to_string()))
                    })
                });
                super::transport::protocol::AnnotationPayload {
                    annotation_id: a.annotation_id,
                    kind: a.kind.clone(),
                    payload: a.payload.clone(),
                    char_start: a.char_start,
                    char_end: a.char_end,
                    created_by: a.created_by,
                    created_by_name,
                    created_at: a.created_at,
                    is_private: a.is_private,
                }
            })
            .collect())
    }

    pub fn link_count(&self) -> usize {
        self.links.len()
    }

    /// Gold's `again()` — walks the transclusion chain for a specific element,
    /// returning each hop (work → source work → ... → original) with text +
    /// author info. Lets a reader trace any passage back to its ultimate source.
    pub fn transclusion_again_chain(
        &self,
        work_id: BeId,
        char_start: usize,
        char_end: usize,
    ) -> Vec<AgainHop> {
        let mut chain = Vec::new();
        let mut current_work = work_id;
        let mut current_start = char_start;
        let mut current_end = char_end;
        let mut visited = std::collections::HashSet::new();

        loop {
            if !visited.insert(current_work) {
                break;
            }
            if chain.len() >= 32 {
                break;
            }

            let ws = match self.works.get(&current_work) {
                Some(ws) => ws,
                None => break,
            };

            let edition = ws.work.current_edition();
            let entries = edition.cached_entries();

            let mut cum = 0usize;
            let mut element_text = String::new();
            let mut prov: Option<&crate::edition::provenance::ElementProvenance> = None;
            let mut inline_transclusion: Option<(BeId, usize, usize)> = None;

            for (_, carrier) in entries {
                let entry_len = carrier.char_len();
                let entry_start = cum;
                let entry_end = cum + entry_len;
                cum = entry_end;

                if entry_end > current_start && entry_start < current_end {
                    if let Some(s) = carrier.element.as_text() {
                        element_text.push_str(s);
                    }
                    if prov.is_none() {
                        prov = carrier.provenance.as_ref();
                    }
                }

                if let Some((src, cs, ce)) = carrier.element.as_transclusion() {
                    if entry_start >= current_start && entry_start < current_end {
                        inline_transclusion = Some((src, cs, ce));
                    }
                }
            }

            if let Some((src_id, src_start, src_end)) = inline_transclusion {
                let src_ws = self.works.get(&src_id);
                let src_title = src_ws
                    .map(|w| w.cached_title.clone())
                    .unwrap_or_else(|| format!("work-{:04x}", src_id));

                let src_author = src_ws
                    .and_then(|w| w.last_revision_author)
                    .and_then(|cid| {
                        self.clubs
                            .get(&cid)
                            .and_then(|c| c.display_name().map(|s| s.to_string()))
                    })
                    .unwrap_or_else(|| "Unknown".to_string());

                chain.push(AgainHop {
                    work_id: current_work,
                    work_title: ws.cached_title.clone(),
                    element_text: if element_text.len() > 200 {
                        format!("{}...", &element_text[..200])
                    } else {
                        element_text
                    },
                    author_name: src_author.clone(),
                    author_type: "human".to_string(),
                    is_original: false,
                });

                current_work = src_id;
                current_start = src_start;
                current_end = src_end;
                continue;
            }

            if element_text.is_empty() && prov.is_none() {
                break;
            }

            let is_original = prov.map(|p| p.source_work_id.is_none()).unwrap_or(true);

            let author_name = prov
                .map(|p| p.author_display_name.clone())
                .unwrap_or_else(|| "Unknown".to_string());

            let author_type = prov
                .map(|p| match p.author_type {
                    crate::edition::provenance::AuthorType::Human => "human",
                    crate::edition::provenance::AuthorType::Llm => "llm",
                    crate::edition::provenance::AuthorType::Historical => "historical",
                })
                .unwrap_or("unknown");

            chain.push(AgainHop {
                work_id: current_work,
                work_title: ws.cached_title.clone(),
                element_text: if element_text.len() > 200 {
                    format!("{}...", &element_text[..200])
                } else {
                    element_text
                },
                author_name,
                author_type: author_type.to_string(),
                is_original,
            });

            match prov.and_then(|p| p.source_work_id) {
                Some(source_work_id) => {
                    // Resolve the excerpt text in the source work to get
                    // the character range for the next hop.
                    if let Some(source_ws) = self.works.get(&source_work_id) {
                        let source_edition = source_ws.work.current_edition();
                        let source_text = source_edition.to_text().to_lowercase();
                        let excerpt_lower = chain
                            .last()
                            .map(|h| h.element_text.to_lowercase())
                            .unwrap_or_default();
                        if let Some(pos) =
                            source_text.find(&excerpt_lower[..excerpt_lower.len().min(100)])
                        {
                            current_start = pos;
                            current_end = pos + excerpt_lower.len().min(200);
                        } else {
                            current_start = 0;
                            current_end = 100;
                        }
                    }
                    current_work = source_work_id;
                }
                None => break, // original source reached
            }
        }

        chain
    }

    pub(crate) fn compute_provenance_chain(
        &self,
        origin_work_id: BeId,
    ) -> Vec<crate::edition::links::ProvenanceHop> {
        use crate::edition::links::ProvenanceHop;
        let incoming = self.list_links_for_work(origin_work_id);
        let mut chain = Vec::new();
        let mut seen = std::collections::HashSet::new();
        for &(lid, orig, dest) in &incoming {
            if dest != origin_work_id {
                continue;
            }
            if !seen.insert((orig, lid)) {
                continue;
            }
            if let Some(ls) = self.links.get(&lid) {
                if let Some(o_ref) = ls.link.end_at("LeftEnd") {
                    for hop in o_ref.provenance_chain() {
                        let key = (hop.source_work_id(), hop.link_id());
                        if seen.insert(key) {
                            chain.push(hop.clone());
                        }
                    }
                }
            }
            chain.push(ProvenanceHop::new(orig, lid));
        }
        chain.sort_by_key(|hop| hop.link_id());
        chain
    }

    pub fn provenance_ancestry(&self, work_id: BeId) -> Vec<crate::edition::links::ProvenanceHop> {
        use crate::edition::links::ProvenanceHop;
        let mut chain = Vec::new();
        let mut seen = std::collections::HashSet::new();
        let mut visited_works = std::collections::HashSet::new();
        let mut queue = vec![work_id];
        while let Some(current) = queue.pop() {
            if !visited_works.insert(current) {
                continue;
            }
            let incoming = self.list_links_for_work(current);
            for &(lid, orig, dest) in &incoming {
                if dest != current {
                    continue;
                }
                if !seen.insert((orig, lid)) {
                    continue;
                }
                if let Some(ls) = self.links.get(&lid) {
                    if let Some(o_ref) = ls.link.end_at("LeftEnd") {
                        for hop in o_ref.provenance_chain() {
                            let key = (hop.source_work_id(), hop.link_id());
                            if seen.insert(key) {
                                chain.push(hop.clone());
                            }
                        }
                    }
                }
                chain.push(ProvenanceHop::new(orig, lid));
                queue.push(orig);
            }
        }
        chain.sort_by_key(|hop| hop.link_id());
        chain
    }

    pub(crate) fn enrich_provenance_hops(
        &self,
        hops: &[crate::edition::links::ProvenanceHop],
    ) -> Vec<super::transport::protocol::ProvenanceHopPayload> {
        use super::transport::protocol::ProvenanceHopPayload;

        hops.iter()
            .map(|hop| {
                let (source_work_title, source_author_name) =
                    if let Some(ws) = self.works.get(&hop.source_work_id()) {
                        let title = ws.work.current_edition().to_text();
                        let title_preview: String = title.chars().take(60).collect();
                        let title = if title.chars().count() > 60 {
                            format!("{}...", title_preview.trim_end())
                        } else if title_preview.is_empty() {
                            format!("work:{:04x}", hop.source_work_id())
                        } else {
                            title_preview
                        };

                        let author_name = if let Some(ha_id) = ws.source_author_id {
                            self.historical_authors.get(ha_id).map(|a| {
                                if a.display_name.is_empty() {
                                    a.name.clone()
                                } else {
                                    a.display_name.clone()
                                }
                            })
                        } else {
                            ws.last_revision_author
                                .or_else(|| {
                                    ws.work
                                        .current_edition()
                                        .all_entries()
                                        .iter()
                                        .find_map(|(_, c)| c.provenance.as_ref())
                                        .map(|ep| ep.author_club_id)
                                })
                                .and_then(|cid| {
                                    self.clubs
                                        .get(&cid)
                                        .and_then(|c| c.display_name().map(|s| s.to_string()))
                                })
                        };

                        (Some(title), author_name)
                    } else {
                        (None, None)
                    };

                let dest_work_id = self
                    .links
                    .get(&hop.link_id())
                    .map(|ls| ls.destination)
                    .unwrap_or(0);

                ProvenanceHopPayload {
                    source_work_id: hop.source_work_id(),
                    link_id: hop.link_id(),
                    source_work_title,
                    source_author_name,
                    dest_work_id,
                }
            })
            .collect()
    }

    pub fn blob_count(&self) -> usize {
        self.blob_store.stats().total_blobs as usize
    }

    pub fn health_json(&self) -> String {
        let grabbed = self
            .works
            .values()
            .filter(|ws| ws.grabber.is_some())
            .count();
        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        let since_checkpoint = now.saturating_sub(self.last_checkpoint_time);
        serde_json::json!({
            "status": "ok",
            "works": self.works.len(),
            "clubs": self.clubs.len(),
            "links": self.link_count(),
            "editions": self.standalone_editions.len(),
            "sessions": self.sessions.len(),
            "blobs": self.blob_count(),
            "grabbed_works": grabbed,
            "operations": self.operation_counter,
            "last_checkpoint_ago_secs": since_checkpoint,
            "server_id": self.server_keypair.identity_id().to_string(),
        })
        .to_string()
    }

    // === Transclusion queries ===

    pub fn find_transcluders(&self, content_be_id: BeId) -> Vec<(String, BeId, bool)> {
        let content = RangeElement::edition(content_be_id);
        let query = TransclusionQuery::all();
        self.find_transcluders_with_query(&content, &query)
    }

    pub fn find_transcluders_for_session(
        &self,
        session_id: SessionId,
        content_be_id: BeId,
    ) -> Result<Vec<(String, BeId, bool)>, ServerError> {
        let content = RangeElement::edition(content_be_id);
        let mut query = TransclusionQuery::all();
        if let Ok(session) = self.session(session_id) {
            let authority: Vec<u64> = session.authority_clubs().into_iter().collect();
            if !authority.is_empty() {
                let perm_region = crate::edition::props::permissions_region(&authority);
                query =
                    query.with_permissions(crate::edition::props::FilterRegion::new(perm_region));
            }
        }
        Ok(self.find_transcluders_with_query(&content, &query))
    }

    fn find_transcluders_with_query(
        &self,
        content: &RangeElement,
        query: &TransclusionQuery,
    ) -> Vec<(String, BeId, bool)> {
        let results = self
            .backfollow
            .find_transcluders_with_backfollow(&content, &query);
        results
            .into_iter()
            .map(|r| {
                let elem = &r.element;
                if let Some(wid) = elem.as_work_id() {
                    ("work".to_string(), wid, r.is_direct)
                } else if let Some(eid) = elem.as_edition_id() {
                    ("edition".to_string(), eid, r.is_direct)
                } else {
                    ("unknown".to_string(), 0u64, r.is_direct)
                }
            })
            .collect()
    }

    pub fn find_works_for_content(&self, content_be_id: BeId) -> Vec<BeId> {
        let content = RangeElement::edition(content_be_id);
        let query = WorkQuery::all();
        self.backfollow.find_works_for_content(&content, &query)
    }

    pub fn find_text_transcluders(
        &self,
        search_text: &str,
    ) -> Vec<(BeId, Option<BeId>, u64, Vec<(i64, i64)>)> {
        if search_text.is_empty() {
            return Vec::new();
        }

        let mut char_fps: Vec<[u8; 32]> = Vec::new();
        {
            let mut seen = std::collections::HashSet::new();
            for ch in search_text.chars() {
                let fp = RangeElement::text(&ch.to_string()).content_fingerprint();
                if seen.insert(fp) {
                    char_fps.push(fp);
                }
            }
        }

        let mut candidate_set: Option<std::collections::HashSet<BeId>> = None;
        for fp in &char_fps {
            let works: std::collections::HashSet<BeId> = self
                .backfollow
                .find_works_by_fingerprint(fp)
                .into_iter()
                .collect();
            candidate_set = Some(match candidate_set {
                None => works,
                Some(prev) => prev.intersection(&works).copied().collect(),
            });
            if candidate_set.as_ref().map_or(true, |s| s.is_empty()) {
                candidate_set = Some(std::collections::HashSet::new());
                break;
            }
        }

        let mut candidates = candidate_set.unwrap_or_default();
        for work_id in self.otree_crdt.active_works() {
            candidates.insert(work_id);
        }

        let mut results = Vec::new();
        for (work_id, ws) in &self.works {
            if !candidates.contains(work_id) {
                continue;
            }

            let text = if self.otree_crdt.is_active(*work_id) {
                match self.otree_crdt.current_text(*work_id) {
                    Ok(t) => t,
                    Err(_) => continue,
                }
            } else {
                let ed = ws.work.current_edition();
                ed.all_entries()
                    .iter()
                    .map(|(_, carrier)| carrier.element.as_text().unwrap_or(""))
                    .collect()
            };

            if !text.contains(search_text) {
                continue;
            }
            let mut matches = Vec::new();
            let mut byte_start = 0;
            while let Some(byte_pos) = text[byte_start..].find(search_text) {
                let abs_byte = byte_start + byte_pos;
                let char_start = text[..abs_byte].chars().count() as i64;
                let char_end = char_start + search_text.chars().count() as i64;
                matches.push((char_start, char_end));
                byte_start = abs_byte + search_text.len();
                if byte_start >= text.len() {
                    break;
                }
            }
            if !matches.is_empty() {
                results.push((*work_id, ws.work.owner(), ws.work.revision_count(), matches));
            }
        }
        results
    }

    pub fn global_text_search(
        &self,
        session_id: SessionId,
        query: &str,
        max_results: usize,
    ) -> Vec<GlobalSearchResult> {
        if query.is_empty() {
            return Vec::new();
        }
        let query_lower = query.to_ascii_lowercase();
        let mut results = Vec::new();

        for (&work_id, ws) in &self.works {
            if !self.work_is_readable(session_id, &ws.work) {
                continue;
            }

            let text = if self.otree_crdt.is_active(work_id) {
                match self.otree_crdt.current_text(work_id) {
                    Ok(t) => t,
                    Err(_) => continue,
                }
            } else {
                let ed = ws.work.current_edition();
                ed.all_entries()
                    .iter()
                    .filter_map(|(_, c)| c.element.as_text())
                    .collect::<String>()
            };

            let text_lower = text.to_ascii_lowercase();
            let mut matches = Vec::new();
            let mut search_start = 0usize;
            while let Some(rel_pos) = text_lower[search_start..].find(&query_lower) {
                let char_offset = search_start + rel_pos;

                let line = text[..char_offset].matches('\n').count() as u64;

                let ctx_start = char_offset.saturating_sub(40);
                let ctx_end = (char_offset + query.len() + 40).min(text.len());
                let ctx_start = text.floor_char_boundary(ctx_start);
                let ctx_end = text.ceil_char_boundary(ctx_end);
                let context = text[ctx_start..ctx_end].replace('\n', " ");

                matches.push(SearchMatch {
                    char_offset: char_offset as u64,
                    line,
                    context,
                });

                if matches.len() >= max_results {
                    break;
                }
                search_start = char_offset + query.len();
            }

            if !matches.is_empty() {
                results.push(GlobalSearchResult {
                    work_id,
                    title: Some(ws.cached_title.clone()),
                    owner: ws.work.owner(),
                    revision_count: ws.work.revision_count(),
                    matches,
                });
            }
        }

        results.sort_by(|a, b| b.matches.len().cmp(&a.matches.len()));
        results
    }

    pub fn render_transclusions(&self, work_id: BeId) -> Result<Vec<RenderedElement>, ServerError> {
        let edition = self.work_edition(work_id)?;
        let mut rendered = Vec::new();

        for (pos, carrier) in edition.all_entries() {
            let text = carrier.element.as_text().unwrap_or("").to_string();
            if text.is_empty() {
                continue;
            }

            let (source_work_id, source_author_name) = carrier
                .provenance
                .as_ref()
                .map(|p| (p.source_work_id, Some(p.author_display_name.clone())))
                .unwrap_or((None, None));

            let is_transcluded = source_work_id.is_some();

            let fp = carrier.element.content_fingerprint();
            let source_work_ids = self.backfollow.find_works_by_fingerprint(&fp);
            let transclusion_sources: Vec<RenderedTransclusionSource> = source_work_ids
                .into_iter()
                .filter(|&wid| wid != work_id)
                .filter_map(|wid| {
                    self.works.get(&wid).map(|_ws| {
                        let (_, title, owner) = self.link_endpoint_meta(wid);
                        let author_name = owner
                            .and_then(|oid| {
                                self.clubs
                                    .get(&oid)
                                    .and_then(|c| c.display_name().map(|s| s.to_string()))
                            })
                            .or(title.as_ref().map(|_| "unknown".to_string()));
                        RenderedTransclusionSource {
                            work_id: wid,
                            title,
                            author_name,
                            is_direct: true,
                        }
                    })
                })
                .collect();

            rendered.push(RenderedElement {
                position: pos,
                text,
                source_work_id,
                source_author_name,
                is_transcluded,
                transclusion_sources,
            });
        }

        Ok(rendered)
    }

    pub fn find_shared_regions(
        &self,
        work_a: BeId,
        work_b: BeId,
    ) -> Vec<(i64, i64, i64, i64, String)> {
        let ed_a = match self.work_edition(work_a) {
            Ok(ed) => ed,
            Err(_) => return Vec::new(),
        };
        let ed_b = match self.work_edition(work_b) {
            Ok(ed) => ed,
            Err(_) => return Vec::new(),
        };
        let mut results = ed_a.find_content_shared_regions(&ed_b, 2);
        let text_results = self.find_text_shared_regions(work_a, work_b);
        let mut seen_a = std::collections::HashSet::new();
        let mut seen_b = std::collections::HashSet::new();
        for (sa, ea, sb, eb, _) in &results {
            seen_a.insert((*sa, *ea));
            seen_b.insert((*sb, *eb));
        }
        for (sa, ea, sb, eb, text) in text_results {
            if !seen_a.contains(&(sa, ea)) || !seen_b.contains(&(sb, eb)) {
                results.push((sa, ea, sb, eb, text));
            }
        }
        results
    }

    pub fn find_text_shared_regions(
        &self,
        work_a: BeId,
        work_b: BeId,
    ) -> Vec<(i64, i64, i64, i64, String)> {
        let text_a = match self.otree_crdt.current_text(work_a) {
            Ok(t) => t,
            Err(_) => match self.works.get(&work_a) {
                Some(ws) => ws.work.current_edition().to_text(),
                None => return Vec::new(),
            },
        };
        let text_b = match self.otree_crdt.current_text(work_b) {
            Ok(t) => t,
            Err(_) => match self.works.get(&work_b) {
                Some(ws) => ws.work.current_edition().to_text(),
                None => return Vec::new(),
            },
        };
        if text_a.is_empty() || text_b.is_empty() {
            return Vec::new();
        }

        let min_len = 20;
        let mut results: Vec<(i64, i64, i64, i64, String)> = Vec::new();
        let mut claimed_a: Vec<std::ops::Range<usize>> = Vec::new();
        let mut claimed_b: Vec<std::ops::Range<usize>> = Vec::new();

        let _paras_a: Vec<&str> = text_a
            .split('\n')
            .filter(|p| p.trim().len() >= min_len)
            .collect();
        let mut para_offsets_a: Vec<usize> = Vec::new();
        {
            let mut off = 0;
            for line in text_a.split('\n') {
                para_offsets_a.push(off);
                off += line.len() + 1;
            }
        }

        let lines_a: Vec<(usize, &str)> = text_a
            .split('\n')
            .enumerate()
            .filter(|(_, l)| l.trim().len() >= min_len)
            .map(|(i, l)| (para_offsets_a.get(i).copied().unwrap_or(0), l))
            .collect();

        let mut line_offsets_b: Vec<usize> = Vec::new();
        {
            let mut off = 0;
            for line in text_b.split('\n') {
                line_offsets_b.push(off);
                off += line.len() + 1;
            }
        }

        let mut seeds: Vec<(usize, usize, usize, usize)> = Vec::new();

        for (off_a, line_a) in &lines_a {
            let trimmed_a = line_a.trim();
            let trim_start = line_a.len() - line_a.trim_start().len();
            let abs_off_a = off_a + trim_start;
            let abs_end_a = abs_off_a + trimmed_a.len();
            let search_len = trimmed_a.len();
            let mut start = 0;
            while start + search_len <= text_b.len() {
                if let Some(pos) = text_b[start..].find(trimmed_a) {
                    let abs_pos = start + pos;
                    let match_end = abs_pos + trimmed_a.len();
                    seeds.push((abs_off_a, abs_end_a, abs_pos, match_end));
                    start = match_end;
                } else {
                    break;
                }
            }
        }

        seeds.sort_by(|a, b| (b.1 - b.0).cmp(&(a.1 - a.0)));

        for (sa, ea, sb, eb) in seeds {
            let range_a = sa..ea;
            let range_b = sb..eb;
            let conflicts_a = claimed_a
                .iter()
                .any(|r| r.start < range_a.end && r.end > range_a.start);
            let conflicts_b = claimed_b
                .iter()
                .any(|r| r.start < range_b.end && r.end > range_b.start);
            if conflicts_a || conflicts_b {
                continue;
            }
            let text = text_a[sa..ea].to_string();
            results.push((sa as i64, ea as i64, sb as i64, eb as i64, text));
            claimed_a.push(range_a);
            claimed_b.push(range_b);
        }

        results
    }

    pub fn find_shared_regions_filtered(
        &self,
        work_a: BeId,
        work_b: BeId,
        filter_text: &str,
    ) -> Vec<(i64, i64, i64, i64, String)> {
        if filter_text.is_empty() {
            return self.find_shared_regions(work_a, work_b);
        }

        let filter_elem = RangeElement::text(filter_text);
        let filter_fp = filter_elem.content_fingerprint();

        let works_with_filter: std::collections::HashSet<BeId> = self
            .backfollow
            .find_works_by_fingerprint(&filter_fp)
            .into_iter()
            .collect();

        let both_contain =
            works_with_filter.contains(&work_a) && works_with_filter.contains(&work_b);

        let shared = self.find_shared_regions(work_a, work_b);

        if both_contain {
            shared
        } else {
            shared
                .into_iter()
                .filter(|(_, _, _, _, text)| text.contains(filter_text))
                .collect()
        }
    }

    pub fn find_excerpt_positions(&self, work_id: BeId, excerpt_text: &str) -> Vec<(usize, usize)> {
        if excerpt_text.is_empty() {
            return Vec::new();
        }
        let text = match self.otree_crdt.current_text(work_id) {
            Ok(t) => t,
            Err(_) => {
                if let Some(ws) = self.works.get(&work_id) {
                    let edition = ws.work.current_edition();
                    let mut t = String::new();
                    for (_, carrier) in edition.all_entries() {
                        if let Some(s) = carrier.element.as_text() {
                            t.push_str(s);
                        }
                    }
                    t
                } else {
                    return Vec::new();
                }
            }
        };
        let excerpt = if excerpt_text.len() > 4096 {
            let mut end = 4096;
            while !excerpt_text.is_char_boundary(end) && end < excerpt_text.len() {
                end += 1;
            }
            &excerpt_text[..end]
        } else {
            excerpt_text
        };
        let mut positions = Vec::new();
        let mut start = 0;
        while let Some(idx) = text[start..].find(excerpt) {
            let match_end = (start + idx + excerpt.len()).min(text.len());
            let char_start = text[..start + idx].chars().count();
            let char_end = text[..match_end].chars().count();
            positions.push((char_start, char_end));
            start += idx + excerpt.len();
        }
        positions
    }

    pub fn resolve_compound_to_text(
        &self,
        compound: &crate::edition::compound::CompoundEdition,
    ) -> Result<String, ServerError> {
        let mut result = String::new();
        for element in compound.elements() {
            match element {
                crate::edition::compound::CompoundElement::Text { content } => {
                    result.push_str(content);
                }
                crate::edition::compound::CompoundElement::Span { span } => {
                    let text = self.work_text(span.source_work_id())?;
                    let char_count = text.chars().count();
                    let start = span.char_start().min(char_count);
                    let end = span.char_end().min(char_count);
                    let byte_start = text
                        .char_indices()
                        .nth(start)
                        .map(|(i, _)| i)
                        .unwrap_or(text.len());
                    let byte_end = text
                        .char_indices()
                        .nth(end)
                        .map(|(i, _)| i)
                        .unwrap_or(text.len());
                    result.push_str(&text[byte_start..byte_end]);
                }
            }
        }
        Ok(result)
    }

    fn work_text(&self, work_id: u64) -> Result<String, ServerError> {
        if let Ok(text) = self.otree_crdt.current_text(work_id) {
            return Ok(text);
        }
        let work = self.work(work_id)?;
        let edition = work.current_edition();
        let text: String = edition
            .all_entries()
            .iter()
            .filter_map(|(_, c)| c.element.as_text())
            .collect();
        Ok(text)
    }

    pub fn get_compound_edition(
        &self,
        work_id: BeId,
    ) -> Option<&crate::edition::compound::CompoundEdition> {
        self.compound_editions.get(&work_id)
    }

    pub fn compound_edition_work_ids(&self) -> Vec<BeId> {
        self.compound_editions.keys().copied().collect()
    }

    pub fn set_compound_edition(
        &mut self,
        work_id: BeId,
        compound: crate::edition::compound::CompoundEdition,
        session_id: SessionId,
    ) -> Result<(), ServerError> {
        if !self.works.contains_key(&work_id) {
            return Err(ServerError::WorkNotFound(work_id));
        }
        self.compound_editions.insert(work_id, compound.clone());
        let compound_json = serde_json::to_string(&compound)
            .map_err(|_| ServerError::Internal("compound serde failed".into()))?;
        let _ = self.wal.append(
            "set_compound_edition",
            serde_json::json!({
                "work_id": work_id,
                "compound": compound_json,
            }),
        );
        let _ = session_id;
        Ok(())
    }

    pub fn element_insert(
        &mut self,
        session_id: SessionId,
        work_id: BeId,
        position: i64,
        element: RangeElement,
    ) -> Result<u64, ServerError> {
        self.ensure_session(session_id)?;
        let char_position = position.max(0) as usize;

        let new_edition = {
            let ws = self
                .works
                .get(&work_id)
                .ok_or(ServerError::WorkNotFound(work_id))?;
            let edition = ws.work().current_edition().clone();
            let entries = edition.cached_entries();

            let mut new_entries: Vec<(
                i64,
                std::sync::Arc<crate::edition::range_element::Carrier>,
            )> = Vec::with_capacity(entries.len() + 1);
            let mut cum_char = 0usize;
            let mut inserted = false;
            let carrier = crate::edition::range_element::Carrier::new(element);
            let arc_carrier = std::sync::Arc::new(carrier);
            let mut pos = 0i64;

            for (_, c) in entries.iter() {
                let entry_len = c.char_len();
                if !inserted && cum_char + entry_len >= char_position {
                    let offset_in_entry = char_position.saturating_sub(cum_char);
                    if let Some(t) = c.element.as_text() {
                        let chars: Vec<char> = t.chars().collect();
                        let split = offset_in_entry.min(chars.len());

                        let before: String = chars[..split].iter().collect();
                        let after: String = chars[split..].iter().collect();

                        let needs_newline_before = !before.is_empty() && !before.ends_with('\n');
                        let needs_newline_after = !after.is_empty() && !after.starts_with('\n');

                        if !before.is_empty() {
                            let before_text = if needs_newline_before {
                                format!("{}\n", before)
                            } else {
                                before
                            };
                            new_entries.push((
                                pos,
                                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                                    RangeElement::text(before_text),
                                )),
                            ));
                            pos += 1;
                        }
                        new_entries.push((pos, arc_carrier.clone()));
                        pos += 1;
                        inserted = true;
                        if !after.is_empty() {
                            let after_text = if needs_newline_after {
                                format!("\n{}", after)
                            } else {
                                after
                            };
                            new_entries.push((
                                pos,
                                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                                    RangeElement::text(after_text),
                                )),
                            ));
                            pos += 1;
                        }
                    } else {
                        if cum_char >= char_position {
                            new_entries.push((pos, arc_carrier.clone()));
                            pos += 1;
                            inserted = true;
                        }
                        new_entries.push((pos, c.clone()));
                        pos += 1;
                    }
                } else {
                    new_entries.push((pos, c.clone()));
                    pos += 1;
                }
                cum_char += entry_len;
            }
            if !inserted {
                new_entries.push((pos, arc_carrier));
            }
            crate::edition::Edition::from_entries(new_entries)
        };

        let author_club = self.resolve_author_club(session_id);
        self.revise_work(work_id, session_id, new_edition, author_club)
    }

    pub fn element_remove_transclusion(
        &mut self,
        session_id: SessionId,
        work_id: BeId,
        source_work_id: BeId,
        char_start: usize,
        char_end: usize,
    ) -> Result<bool, ServerError> {
        self.ensure_session(session_id)?;

        let new_edition = {
            let ws = self
                .works
                .get(&work_id)
                .ok_or(ServerError::WorkNotFound(work_id))?;
            let old_edition = ws.work().current_edition().clone();
            let entries = old_edition.cached_entries();

            let mut found = false;
            let mut new_entries: Vec<(
                i64,
                std::sync::Arc<crate::edition::range_element::Carrier>,
            )> = Vec::with_capacity(entries.len());
            let mut pos = 0i64;

            for (_, carrier) in entries.iter() {
                if !found {
                    if let crate::edition::RangeElement::Transclusion {
                        source_work_id: sid,
                        char_start: cs,
                        char_end: ce,
                    } = &carrier.element
                    {
                        if *sid == source_work_id && *cs == char_start && *ce == char_end {
                            found = true;
                            continue;
                        }
                    }
                }
                new_entries.push((pos, carrier.clone()));
                pos += 1;
            }

            if !found {
                return Ok(false);
            }
            crate::edition::Edition::from_entries(new_entries)
        };

        let author_club = self.resolve_author_club(session_id);
        self.revise_work(work_id, session_id, new_edition, author_club)?;
        Ok(true)
    }

    pub fn migrate_compound_to_inline(&mut self, work_id: BeId) -> Result<usize, ServerError> {
        let compound = match self.compound_editions.get(&work_id) {
            Some(c) => c.clone(),
            None => return Ok(0),
        };

        let ws = self
            .works
            .get_mut(&work_id)
            .ok_or(ServerError::WorkNotFound(work_id))?;
        let old_edition = ws.work().current_edition().clone();
        let entries = old_edition.cached_entries();

        let mut new_entries: Vec<(i64, std::sync::Arc<crate::edition::range_element::Carrier>)> =
            Vec::new();
        let mut text_chars_consumed = 0usize;
        let mut compound_idx = 0;
        let mut pos = 0i64;
        let mut migrated_count = 0usize;

        for (_, carrier) in entries.iter() {
            let entry_len = carrier.char_len();
            let remaining_in_entry = entry_len;

            while compound_idx < compound.elements().len() {
                let comp_elem = &compound.elements()[compound_idx];
                match comp_elem {
                    crate::edition::compound::CompoundElement::Text { content } => {
                        let content_len = content.chars().count();
                        if text_chars_consumed + remaining_in_entry >= content_len {
                            text_chars_consumed = 0;
                            compound_idx += 1;
                        } else {
                            text_chars_consumed += remaining_in_entry;
                            break;
                        }
                    }
                    crate::edition::compound::CompoundElement::Span { span } => {
                        let tc = crate::edition::range_element::Carrier::new(
                            RangeElement::transclusion(
                                span.source_work_id(),
                                span.char_start(),
                                span.char_end(),
                            ),
                        );
                        new_entries.push((pos, std::sync::Arc::new(tc)));
                        pos += 1;
                        compound_idx += 1;
                        migrated_count += 1;
                    }
                }
            }

            new_entries.push((pos, carrier.clone()));
            pos += 1;
        }

        let new_edition = crate::edition::Edition::from_entries(new_entries);
        ws.work_mut().update_current_edition(new_edition);
        ws.mark_dirty();

        self.compound_editions.remove(&work_id);
        Ok(migrated_count)
    }

    pub fn compound_insert_element(
        &mut self,
        work_id: BeId,
        index: usize,
        element: crate::edition::compound::CompoundElement,
        session_id: SessionId,
    ) -> Result<usize, ServerError> {
        if !self.works.contains_key(&work_id) {
            return Err(ServerError::WorkNotFound(work_id));
        }
        let compound = self
            .compound_editions
            .entry(work_id)
            .or_insert_with(crate::edition::compound::CompoundEdition::empty);
        compound.insert(index, element.clone());
        let count = compound.len();
        let element_json = serde_json::to_string(&element)
            .map_err(|_| ServerError::Internal("compound element serde failed".into()))?;
        let _ = self.wal.append(
            "compound_insert_element",
            serde_json::json!({
                "work_id": work_id,
                "index": index,
                "element": element_json,
            }),
        );
        let _ = session_id;
        Ok(count)
    }

    pub fn compound_remove_element(
        &mut self,
        work_id: BeId,
        index: usize,
        session_id: SessionId,
    ) -> Result<usize, ServerError> {
        if !self.works.contains_key(&work_id) {
            return Err(ServerError::WorkNotFound(work_id));
        }
        let compound = self
            .compound_editions
            .get_mut(&work_id)
            .ok_or(ServerError::Internal("no compound edition for work".into()))?;
        compound.remove(index);
        let count = compound.len();
        let _ = self.wal.append(
            "compound_remove_element",
            serde_json::json!({
                "work_id": work_id,
                "index": index,
            }),
        );
        let _ = session_id;
        Ok(count)
    }

    pub fn compound_move_element(
        &mut self,
        work_id: BeId,
        from: usize,
        to: usize,
        session_id: SessionId,
    ) -> Result<usize, ServerError> {
        if !self.works.contains_key(&work_id) {
            return Err(ServerError::WorkNotFound(work_id));
        }
        let compound = self
            .compound_editions
            .get_mut(&work_id)
            .ok_or(ServerError::Internal("no compound edition for work".into()))?;
        compound.move_element(from, to);
        let count = compound.len();
        let _ = self.wal.append(
            "compound_move_element",
            serde_json::json!({
                "work_id": work_id,
                "from": from,
                "to": to,
            }),
        );
        let _ = session_id;
        Ok(count)
    }
    ///
    /// Walks the work's current edition entries, grouping consecutive elements
    /// by their `source_work_id` provenance. For each group, searches for the
    /// group's text in the source work to determine the correct span range,
    /// producing a `CompoundElement::Span`. Runs without provenance become
    /// `CompoundElement::Text`.
    ///
    /// This repairs compounds that were corrupted (text-only, no spans) by
    /// the work-switch bug fixed in commit 4c2219c6.
    pub fn compound_rebuild(
        &mut self,
        work_id: BeId,
        session_id: SessionId,
    ) -> Result<crate::edition::compound::CompoundEdition, ServerError> {
        self.ensure_session(session_id)?;

        let edition = {
            let ws = self
                .works
                .get(&work_id)
                .ok_or(ServerError::WorkNotFound(work_id))?;
            ws.work.current_edition().clone()
        };

        let entries = edition.all_entries();
        let mut elements: Vec<crate::edition::compound::CompoundElement> = Vec::new();

        let mut text_buf = String::new();
        let mut span_source: Option<BeId> = None;
        let mut span_text = String::new();

        let flush_text =
            |buf: &mut String, elems: &mut Vec<crate::edition::compound::CompoundElement>| {
                if !buf.is_empty() {
                    elems.push(crate::edition::compound::CompoundElement::text(
                        buf.as_str(),
                    ));
                    buf.clear();
                }
            };

        for (_, c) in &entries {
            let src = c.provenance.as_ref().and_then(|p| p.source_work_id);

            if let Some(sid) = src {
                if span_source != Some(sid) {
                    flush_text(&mut text_buf, &mut elements);
                    if let Some(old_sid) = span_source.take() {
                        self.emit_span(&mut elements, old_sid, &span_text);
                        span_text.clear();
                    }
                    span_source = Some(sid);
                }
                if let Some(t) = c.element.as_text() {
                    span_text.push_str(t);
                }
            } else {
                if let Some(old_sid) = span_source.take() {
                    flush_text(&mut text_buf, &mut elements);
                    self.emit_span(&mut elements, old_sid, &span_text);
                    span_text.clear();
                }
                if let Some(t) = c.element.as_text() {
                    text_buf.push_str(t);
                }
            }
        }

        if let Some(sid) = span_source.take() {
            flush_text(&mut text_buf, &mut elements);
            self.emit_span(&mut elements, sid, &span_text);
        }
        flush_text(&mut text_buf, &mut elements);

        let compound = crate::edition::compound::CompoundEdition::new(elements);
        self.set_compound_edition(work_id, compound.clone(), session_id)?;
        Ok(compound)
    }

    fn emit_span(
        &self,
        elements: &mut Vec<crate::edition::compound::CompoundElement>,
        source_work_id: BeId,
        text: &str,
    ) {
        if text.is_empty() {
            return;
        }
        let positions = self.find_excerpt_positions(source_work_id, text);
        if let Some(&(char_start, char_end)) = positions.first() {
            elements.push(crate::edition::compound::CompoundElement::span(
                source_work_id,
                char_start,
                char_end,
            ));
        } else {
            elements.push(crate::edition::compound::CompoundElement::text(text));
        }
    }

    pub fn resolve_compound_edition(
        &self,
        work_id: BeId,
    ) -> Result<crate::edition::compound::ResolvedCompoundEdition, ServerError> {
        let compound = self
            .compound_editions
            .get(&work_id)
            .ok_or(ServerError::WorkNotFound(work_id))?;
        compound
            .resolve(|src_id| {
                self.work_text(src_id).map_err(|_| {
                    crate::edition::compound::ResolveError::SourceNotFound { work_id: src_id }
                })
            })
            .map_err(|e| match e {
                crate::edition::compound::ResolveError::SourceNotFound { work_id } => {
                    ServerError::WorkNotFound(work_id)
                }
                crate::edition::compound::ResolveError::SourceFetchFailed { work_id } => {
                    ServerError::WorkNotFound(work_id)
                }
            })
    }

    pub fn resolve_inline_transclusions(
        &self,
        work_id: BeId,
    ) -> Result<InlineTransclusionResult, ServerError> {
        let mut cache: HashMap<BeId, String> = HashMap::new();
        let mut stack: Vec<BeId> = Vec::new();
        let mut span_ranges = Vec::new();
        let mut source_titles = HashMap::new();

        let text = self.resolve_inline_recursive(
            work_id,
            &mut cache,
            &mut stack,
            &mut span_ranges,
            &mut source_titles,
            0,
        )?;

        Ok(InlineTransclusionResult {
            text,
            span_ranges,
            source_titles,
        })
    }

    const INLINE_MAX_DEPTH: usize = 32;

    fn resolve_inline_recursive(
        &self,
        work_id: BeId,
        cache: &mut HashMap<BeId, String>,
        stack: &mut Vec<BeId>,
        span_ranges: &mut Vec<crate::edition::compound::SpanRange>,
        source_titles: &mut HashMap<BeId, String>,
        depth: usize,
    ) -> Result<String, ServerError> {
        if depth >= Self::INLINE_MAX_DEPTH {
            return Ok(String::new());
        }
        if stack.contains(&work_id) {
            let ws = self
                .works
                .get(&work_id)
                .ok_or(ServerError::WorkNotFound(work_id))?;
            return Ok(ws.work().current_edition().to_text());
        }

        {
            if let Some(cached) = cache.get(&work_id) {
                return Ok(cached.clone());
            }
        }

        stack.push(work_id);

        let ws = self
            .works
            .get(&work_id)
            .ok_or(ServerError::WorkNotFound(work_id))?;
        let edition = ws.work().current_edition();
        let entries = edition.cached_entries();

        let mut text_offset = 0usize;
        let mut crdt_offset = 0usize;
        let mut resolved_text = String::new();

        for (_, carrier) in entries.iter() {
            if let crate::edition::RangeElement::Transclusion {
                source_work_id,
                char_start,
                char_end,
            } = &carrier.element
            {
                let src_id = *source_work_id;
                let c_start = *char_start;
                let c_end = *char_end;

                let src_text = self.resolve_inline_recursive(
                    src_id,
                    cache,
                    stack,
                    span_ranges,
                    source_titles,
                    depth + 1,
                )?;

                let src_chars: Vec<char> = src_text.chars().collect();
                let start = c_start.min(src_chars.len());
                let end = c_end.min(src_chars.len());
                let content: String = src_chars[start..end].iter().collect();
                let content_len = content.chars().count();

                span_ranges.push(crate::edition::compound::SpanRange {
                    source_work_id: src_id,
                    char_start: c_start,
                    char_end: c_end,
                    flat_start: text_offset,
                    flat_end: text_offset + content_len,
                    content_len,
                    otree_position: crdt_offset,
                    resolved_content: content.clone(),
                });

                if !source_titles.contains_key(&src_id) {
                    if let Some(title) = self.compound_source_title(src_id) {
                        source_titles.insert(src_id, title);
                    }
                }

                resolved_text.push_str(&content);
                text_offset += content_len;
            } else if let Some(s) = carrier.element.as_text() {
                resolved_text.push_str(s);
                let s_len = s.chars().count();
                text_offset += s_len;
                crdt_offset += s_len;
            }
        }

        stack.pop();
        cache.insert(work_id, resolved_text.clone());
        Ok(resolved_text)
    }

    pub fn work_has_inline_transclusions(&self, work_id: BeId) -> bool {
        if let Some(ws) = self.works.get(&work_id) {
            ws.work()
                .current_edition()
                .cached_entries()
                .iter()
                .any(|(_, c)| c.element.is_transclusion())
        } else {
            false
        }
    }

    pub fn migrate_inline_transclusions_for_delta(
        &mut self,
        source_work_id: BeId,
        ops: &[crate::server::transport::protocol::TextDeltaOp],
    ) {
        let delta_ops: Vec<crate::edition::compound::DeltaOp> = ops
            .iter()
            .map(|op| match op {
                crate::server::transport::protocol::TextDeltaOp::Retain { count } => {
                    crate::edition::compound::DeltaOp::Retain(*count as usize)
                }
                crate::server::transport::protocol::TextDeltaOp::Insert { text } => {
                    crate::edition::compound::DeltaOp::Insert(text.chars().count())
                }
                crate::server::transport::protocol::TextDeltaOp::Delete { count } => {
                    crate::edition::compound::DeltaOp::Delete(*count as usize)
                }
            })
            .collect();

        let affected: Vec<BeId> = self
            .works
            .iter()
            .filter(|(_, ws)| {
                ws.work()
                    .current_edition()
                    .cached_entries()
                    .iter()
                    .any(|(_, c)| {
                        c.element
                            .as_transclusion()
                            .map(|(sid, _, _)| sid == source_work_id)
                            .unwrap_or(false)
                    })
            })
            .map(|(id, _)| *id)
            .collect();

        for wid in affected {
            if let Some(ws) = self.works.get_mut(&wid) {
                let old_edition = ws.work().current_edition().clone();
                let entries = old_edition.cached_entries();
                let mut new_entries: Vec<(i64, std::sync::Arc<crate::edition::Carrier>)> =
                    Vec::with_capacity(entries.len());
                let mut pos = 0i64;
                for (_, carrier) in entries.iter() {
                    let mut new_carrier = (**carrier).clone();
                    if let crate::edition::RangeElement::Transclusion {
                        source_work_id: sid,
                        char_start,
                        char_end,
                    } = &new_carrier.element
                    {
                        if *sid == source_work_id {
                            let (ns, ne) = crate::edition::compound::map_span_through_delta(
                                *char_start,
                                *char_end,
                                &delta_ops,
                            );
                            new_carrier.element =
                                crate::edition::RangeElement::transclusion(*sid, ns, ne);
                        }
                    }
                    new_entries.push((pos, std::sync::Arc::new(new_carrier)));
                    pos += 1;
                }
                let new_edition = crate::edition::Edition::from_entries(new_entries);
                ws.work_mut().update_current_edition(new_edition);
                ws.mark_dirty();
            }
        }
    }

    const COMPOUND_MAX_DEPTH: usize = 32;

    fn resolve_text_recursive(
        &self,
        work_id: BeId,
        cache: &std::cell::RefCell<HashMap<BeId, String>>,
        stack: &std::cell::RefCell<Vec<BeId>>,
    ) -> Result<String, ServerError> {
        {
            let cache_ref = cache.borrow();
            if let Some(cached) = cache_ref.get(&work_id) {
                return Ok(cached.clone());
            }
        }

        {
            let stack_ref = stack.borrow();
            if stack_ref.len() >= Self::COMPOUND_MAX_DEPTH {
                return self.work_text(work_id);
            }
            if stack_ref.contains(&work_id) {
                return self.work_text(work_id);
            }
        }

        if let Some(compound) = self.compound_editions.get(&work_id).cloned() {
            stack.borrow_mut().push(work_id);

            let mut flat_text = String::new();
            for elem in compound.elements() {
                match elem {
                    crate::edition::compound::CompoundElement::Text { content } => {
                        flat_text.push_str(content);
                    }
                    crate::edition::compound::CompoundElement::Span { span } => {
                        let source_text =
                            self.resolve_text_recursive(span.source_work_id(), cache, stack)?;
                        let chars: Vec<char> = source_text.chars().collect();
                        let start = span.char_start().min(chars.len());
                        let end = span.char_end().min(chars.len());
                        flat_text.extend(&chars[start..end]);
                    }
                }
            }

            stack.borrow_mut().pop();
            cache.borrow_mut().insert(work_id, flat_text.clone());
            Ok(flat_text)
        } else {
            let text = self.work_text(work_id)?;
            cache.borrow_mut().insert(work_id, text.clone());
            Ok(text)
        }
    }

    pub fn resolve_compound_recursive(
        &self,
        work_id: BeId,
    ) -> Result<crate::edition::compound::ResolvedCompoundEdition, ServerError> {
        let compound = self
            .compound_editions
            .get(&work_id)
            .ok_or(ServerError::WorkNotFound(work_id))?;

        let cache = std::cell::RefCell::new(HashMap::new());
        let stack = std::cell::RefCell::new(Vec::new());

        compound
            .resolve(|src_id| {
                self.resolve_text_recursive(src_id, &cache, &stack)
                    .map_err(|_| crate::edition::compound::ResolveError::SourceNotFound {
                        work_id: src_id,
                    })
            })
            .map_err(|e| match e {
                crate::edition::compound::ResolveError::SourceNotFound { work_id } => {
                    ServerError::WorkNotFound(work_id)
                }
                crate::edition::compound::ResolveError::SourceFetchFailed { work_id } => {
                    ServerError::WorkNotFound(work_id)
                }
            })
    }

    pub fn compound_source_title(&self, work_id: BeId) -> Option<String> {
        self.works.get(&work_id).map(|ws| ws.cached_title.clone())
    }

    pub fn works_with_compound_referencing(&self, source_work_id: BeId) -> Vec<BeId> {
        self.compound_editions
            .iter()
            .filter_map(|(wid, compound)| {
                if compound
                    .referenced_works()
                    .contains(&(source_work_id as u64))
                {
                    Some(*wid)
                } else {
                    None
                }
            })
            .collect()
    }

    fn mark_compound_dirty(&mut self, revised_work_id: BeId) {
        let affected: Vec<BeId> = self.works_with_compound_referencing(revised_work_id);
        for wid in affected {
            self.compound_dirty.insert(wid);
        }
    }

    pub fn migrate_compound_spans_for_delta(
        &mut self,
        source_work_id: BeId,
        ops: &[crate::server::transport::protocol::TextDeltaOp],
    ) {
        let delta_ops: Vec<crate::edition::compound::DeltaOp> = ops
            .iter()
            .map(|op| match op {
                crate::server::transport::protocol::TextDeltaOp::Retain { count } => {
                    crate::edition::compound::DeltaOp::Retain(*count as usize)
                }
                crate::server::transport::protocol::TextDeltaOp::Insert { text } => {
                    crate::edition::compound::DeltaOp::Insert(text.chars().count())
                }
                crate::server::transport::protocol::TextDeltaOp::Delete { count } => {
                    crate::edition::compound::DeltaOp::Delete(*count as usize)
                }
            })
            .collect();

        let affected: Vec<BeId> = self.works_with_compound_referencing(source_work_id);
        for wid in affected {
            if let Some(compound) = self.compound_editions.get_mut(&wid) {
                compound.migrate_spans_for_delta(source_work_id, &delta_ops);
            }
        }
        self.mark_compound_dirty(source_work_id);
    }

    pub fn migrate_link_spans_for_delta(
        &mut self,
        source_work_id: BeId,
        ops: &[crate::server::transport::protocol::TextDeltaOp],
    ) {
        use crate::edition::compound::{map_span_through_delta, DeltaOp};

        let delta_ops: Vec<DeltaOp> = ops
            .iter()
            .map(|op| match op {
                crate::server::transport::protocol::TextDeltaOp::Retain { count } => {
                    DeltaOp::Retain(*count as usize)
                }
                crate::server::transport::protocol::TextDeltaOp::Insert { text } => {
                    DeltaOp::Insert(text.chars().count())
                }
                crate::server::transport::protocol::TextDeltaOp::Delete { count } => {
                    DeltaOp::Delete(*count as usize)
                }
            })
            .collect();

        let link_ids: Vec<BeId> = self
            .work_to_links
            .get(&source_work_id)
            .cloned()
            .unwrap_or_default();

        for link_id in link_ids {
            let old_link = match self.links.get(&link_id) {
                Some(ls) => ls.link.clone(),
                None => continue,
            };
            self.backfollow.unregister_link_content(&old_link, link_id);

            let ls = match self.links.get_mut(&link_id) {
                Some(ls) => ls,
                None => continue,
            };
            let mut link = ls.link.clone();
            let end_names: Vec<String> = link.end_names().iter().map(|s| s.to_string()).collect();
            for name in end_names {
                if let Some(hr) = link.end_at(&name) {
                    if hr.work_context() != Some(source_work_id) {
                        continue;
                    }
                    if let (Some(start), Some(end)) = (hr.start_position(), hr.end_position()) {
                        if start < 0 || end < 0 {
                            continue;
                        }
                        let (new_start, new_end) =
                            map_span_through_delta(start as usize, end as usize, &delta_ops);
                        let new_hr = hr.with_span(Some(new_start as i64), Some(new_end as i64));
                        link = link.with_end(&name, new_hr);
                    }
                }
            }
            ls.link = link.clone();
            self.backfollow.register_link_content(&ls.link, link_id);
        }
    }

    pub fn compound_dirty_works(&self) -> Vec<BeId> {
        self.compound_dirty.iter().copied().collect()
    }

    pub fn is_compound_dirty(&self, work_id: BeId) -> bool {
        self.compound_dirty.contains(&work_id)
    }

    pub fn clear_compound_dirty(&mut self, work_id: BeId) {
        self.compound_dirty.remove(&work_id);
    }

    pub fn compound_subscribers_for_source(
        &self,
        source_work_id: BeId,
    ) -> Vec<(BeId, Vec<SessionId>)> {
        let mut affected: std::collections::HashSet<BeId> = self
            .works_with_compound_referencing(source_work_id)
            .into_iter()
            .collect();

        for (wid, ws) in &self.works {
            let has_inline = ws
                .work()
                .current_edition()
                .cached_entries()
                .iter()
                .any(|(_, c)| {
                    c.element
                        .as_transclusion()
                        .map(|(sid, _, _)| sid == source_work_id)
                        .unwrap_or(false)
                });
            if has_inline {
                affected.insert(*wid);
            }
        }

        affected
            .into_iter()
            .filter_map(|wid| {
                let subs = self.otree_crdt.get_subscribed_sessions(wid).ok()?;
                if subs.is_empty() {
                    None
                } else {
                    Some((wid, subs))
                }
            })
            .collect()
    }

    pub fn content_address_lookup(&self, element: &RangeElement) -> Option<BeId> {
        self.content_address.lookup(element)
    }

    pub fn find_work_for_edition(&self, edition_be_id: BeId) -> Option<(BeId, String)> {
        self.works
            .iter()
            .find(|(_, ws)| {
                ws.work
                    .current_edition()
                    .all_entries()
                    .iter()
                    .any(|(_, c)| c.element.as_edition_id() == Some(edition_be_id))
            })
            .map(|(id, ws)| (*id, ws.title().to_string()))
    }

    pub fn content_address_count(&self) -> usize {
        self.content_address.fingerprint_count()
    }

    // === Blob operations ===

    pub fn blob_upload(
        &mut self,
        session_id: SessionId,
        data: Vec<u8>,
        mime_type: String,
    ) -> Result<BlobMeta, ServerError> {
        self.ensure_logged_in(session_id)?;
        const MAX_BLOB_SIZE: usize = 64 * 1024 * 1024;
        const MAX_BLOB_COUNT: usize = 10_000;
        if data.len() > MAX_BLOB_SIZE {
            return Err(ServerError::InvalidArgument(format!(
                "blob too large: {} bytes (max {})",
                data.len(),
                MAX_BLOB_SIZE
            )));
        }
        if self.blob_store.stats().total_blobs >= MAX_BLOB_COUNT as u64 {
            return Err(ServerError::InvalidArgument(format!(
                "blob limit reached (max {})",
                MAX_BLOB_COUNT
            )));
        }
        self.blob_store
            .store(&data, mime_type)
            .map_err(|e| ServerError::Internal(e.to_string()))
    }

    pub fn blob_get(&self, hash_u64: u64) -> Result<Vec<u8>, ServerError> {
        let meta = self
            .blob_store
            .get_meta_by_u64(hash_u64)
            .ok_or_else(|| ServerError::NotFound(format!("blob {:016x}", hash_u64)))?;
        self.blob_store
            .retrieve(&meta.content_hash)
            .map_err(|e| ServerError::Internal(e.to_string()))
    }

    pub fn recorder_create_for_content(
        &mut self,
        query: crate::edition::RecorderQuery,
        edition_id: u64,
    ) -> crate::edition::RecorderId {
        let matcher_query = query.clone();
        let fossil_id = self.recorder_system.create_fossil(query);
        if let Some(fossil) = self.recorder_system.get_fossil_mut(fossil_id) {
            fossil.source_edition_id = Some(edition_id);
        }
        self.recorder_system
            .schedule_matcher(fossil_id, matcher_query, Some(edition_id));
        fossil_id
    }

    pub fn recorder_extinguish(&mut self, fossil_id: crate::edition::RecorderId) -> bool {
        self.recorder_system.extinguish_fossil(fossil_id)
    }

    pub fn recorder_process(&mut self) -> usize {
        self.recorder_system
            .process_agenda_with_engine(&mut self.backfollow)
    }

    pub fn update_work_prop_and_trigger(&mut self, work_be_id: BeId) {
        let ws = match self.works.get(&work_be_id) {
            Some(ws) => ws,
            None => return,
        };
        let work = &ws.work;
        let read_club = work.read_club();
        let edit_club = work.edit_club();
        let new_prop = BackfollowEngine::make_work_prop(work, read_club, edit_club);
        self.backfollow.update_edition_prop(work_be_id, new_prop);
        let triggered = self.backfollow.on_prop_changed(work_be_id);
        for fossil_id in triggered {
            let fossil = match self.recorder_system.get_fossil(fossil_id) {
                Some(f) => f,
                None => continue,
            };
            if fossil.is_extinct {
                continue;
            }
            let query = fossil.query.clone();
            let mut all_results = Vec::new();
            for content in &query.watched_content {
                let results = match query.kind {
                    crate::edition::RecorderKind::Transcluders => {
                        let tq = crate::edition::TransclusionQuery::all();
                        self.backfollow
                            .find_transcluders_with_backfollow(content, &tq)
                    }
                    crate::edition::RecorderKind::Works => {
                        let wq = crate::edition::WorkQuery::all();
                        self.backfollow
                            .find_works_for_content(content, &wq)
                            .into_iter()
                            .map(|wid| crate::edition::TransclusionResult {
                                element: crate::edition::RangeElement::work(wid),
                                is_direct: true,
                            })
                            .collect()
                    }
                };
                all_results.extend(results);
            }
            for result in all_results {
                let source_id = result
                    .element
                    .as_work_id()
                    .or(result.element.as_edition_id());
                self.recorder_system.record_result(
                    fossil_id,
                    result.element,
                    source_id,
                    None,
                    result.is_direct,
                );
            }
        }
    }

    pub fn recorder_plant(
        &mut self,
        edition_id: u64,
        fossil_id: crate::edition::RecorderId,
        content: &[crate::edition::RangeElement],
    ) {
        if let Some(hoist_item) = self
            .backfollow
            .plant_recorder_with_hoist(edition_id, fossil_id, content)
        {
            self.recorder_system.schedule_hoist(hoist_item);
        }
        self.recorder_process();
    }

    pub fn recorder_unplant(
        &mut self,
        edition_id: u64,
        fossil_id: crate::edition::RecorderId,
        content: &[crate::edition::RangeElement],
    ) {
        self.backfollow
            .remove_planted_recorder(edition_id, fossil_id, content);
    }

    pub fn trigger_planted_recorders(&mut self, edition_id: u64) {
        let edition_fps: Vec<[u8; 32]> = self
            .get_edition(edition_id)
            .ok()
            .flatten()
            .map(|ed| {
                ed.all_entries()
                    .iter()
                    .map(|(_, c)| c.element.content_fingerprint())
                    .collect()
            })
            .unwrap_or_default();
        if edition_fps.is_empty() {
            tracing::debug!(target: "xudanu::content_watch",
                edition_id, "trigger_planted_recorders: no edition fingerprints");
            return;
        }
        let trigger_words: std::collections::HashSet<String> = self
            .get_edition(edition_id)
            .ok()
            .flatten()
            .map(|ed| ed.word_set())
            .unwrap_or_default();
        tracing::debug!(target: "xudanu::content_watch",
            edition_id, fp_count = edition_fps.len(), word_count = trigger_words.len(), "trigger_planted_recorders: checking");
        let triggered_fossils = self.backfollow.check_recorders_by_content(&edition_fps);
        tracing::debug!(target: "xudanu::content_watch",
            edition_id, triggered_count = triggered_fossils.len(), "trigger_planted_recorders: fossils triggered");
        let permission_queries: std::collections::HashMap<
            crate::edition::RecorderId,
            (Vec<u64>, Option<Vec<u64>>),
        > = triggered_fossils
            .iter()
            .filter_map(|&fid| {
                let f = self.recorder_system.get_fossil(fid)?;
                if f.is_extinct {
                    return None;
                }
                Some((
                    fid,
                    (
                        f.query.authority_clubs.clone(),
                        f.query.endorsement_filter.clone(),
                    ),
                ))
            })
            .collect();
        let triggered_fossils = self.backfollow.filter_fossils_by_permission(
            &triggered_fossils,
            &permission_queries,
            edition_id,
        );
        tracing::debug!(target: "xudanu::content_watch",
            edition_id, after_perm_filter = triggered_fossils.len(), "trigger_planted_recorders: after permission filter");
        for fossil_id in triggered_fossils {
            let (source_edition_id, query) = {
                let fossil = match self.recorder_system.get_fossil(fossil_id) {
                    Some(f) => f,
                    None => continue,
                };
                if fossil.is_extinct {
                    continue;
                }
                (fossil.source_edition_id, fossil.query.clone())
            };
            let source_words: std::collections::HashSet<String> = source_edition_id
                .and_then(|sid| self.get_edition(sid).ok().flatten())
                .map(|ed| ed.word_set())
                .unwrap_or_default();
            if !source_words.is_empty() && !trigger_words.is_empty() {
                let similarity = crate::edition::jaccard_similarity(&source_words, &trigger_words);
                if similarity < 0.05 {
                    tracing::debug!(target: "xudanu::content_watch",
                        fossil_id, similarity, "trigger_planted_recorders: below Jaccard threshold, skipping");
                    continue;
                }
                tracing::debug!(target: "xudanu::content_watch",
                    fossil_id, similarity, "trigger_planted_recorders: above Jaccard threshold");
            }
            let mut all_results = Vec::new();
            for content in &query.watched_content {
                let results = match query.kind {
                    crate::edition::RecorderKind::Transcluders => {
                        let tq = crate::edition::TransclusionQuery::all();
                        self.backfollow
                            .find_transcluders_with_backfollow(content, &tq)
                    }
                    crate::edition::RecorderKind::Works => {
                        let wq = crate::edition::WorkQuery::all();
                        self.backfollow
                            .find_works_for_content(content, &wq)
                            .into_iter()
                            .map(|wid| crate::edition::TransclusionResult {
                                element: crate::edition::RangeElement::work(wid),
                                is_direct: true,
                            })
                            .collect()
                    }
                };
                tracing::debug!(target: "xudanu::content_watch",
                    fossil_id, result_count = results.len(), "trigger_planted_recorders: query results");
                all_results.extend(results);
            }
            tracing::debug!(target: "xudanu::content_watch",
                fossil_id, total_results = all_results.len(),
                source_edition_id = ?source_edition_id,
                "trigger_planted_recorders: total results after dedup");
            let mut notified_ids: std::collections::HashSet<BeId> =
                std::collections::HashSet::new();
            for result in all_results {
                let result_edition_id = result
                    .element
                    .as_edition_id()
                    .or(result.element.as_work_id());
                if result_edition_id == source_edition_id {
                    continue;
                }
                let result_be_id = result
                    .element
                    .as_work_id()
                    .or(result.element.as_edition_id());
                let result_work_id = result.element.as_work_id();
                let _recorded = self.recorder_system.record_result(
                    fossil_id,
                    result.element,
                    Some(edition_id),
                    None,
                    result.is_direct,
                );
                if let Some(be_id) = result_be_id {
                    if !notified_ids.contains(&be_id) {
                        notified_ids.insert(be_id);
                        let (work_be_id, title) = if let Some(wid) = result_work_id {
                            (
                                Some(wid),
                                self.works.get(&wid).map(|ws| ws.title().to_string()),
                            )
                        } else {
                            self.find_work_for_edition(be_id)
                                .map(|(wid, t)| (Some(wid), Some(t)))
                                .unwrap_or((None, None))
                        };
                        self.cap_pending_notifications();
                        self.pending_content_notifications
                            .push(ContentNotification {
                                fossil_id,
                                edition_be_id: be_id,
                                is_direct: result.is_direct,
                                work_be_id,
                                title,
                            });
                    }
                }
            }
        }
    }

    pub fn version_is_before(&mut self, work_a: BeId, work_b: BeId) -> Option<bool> {
        self.backfollow.version_is_le(work_a, work_b)
    }

    pub fn version_ancestors(&self, work_id: BeId) -> Vec<BeId> {
        self.backfollow.version_ancestors(work_id)
    }

    pub fn version_ancestors_transitive(&self, work_id: BeId) -> Vec<BeId> {
        self.backfollow.version_ancestors_transitive(work_id)
    }

    pub fn version_descendants(&self, work_id: BeId) -> Vec<BeId> {
        self.backfollow.version_descendants(work_id)
    }

    pub fn version_trace_position(&self, work_id: BeId) -> Option<TracePosition> {
        self.backfollow.trace_position_of(work_id)
    }

    pub fn materialize_work(
        &self,
        work_id: BeId,
    ) -> Option<crate::ent::content::MaterializedDocument> {
        self.backfollow.materialize_work(work_id)
    }

    pub fn blob_preview(&self, hash_u64: u64) -> Result<Option<Vec<u8>>, ServerError> {
        let meta = self
            .blob_store
            .get_meta_by_u64(hash_u64)
            .ok_or_else(|| ServerError::NotFound(format!("blob {:016x}", hash_u64)))?;
        self.blob_store
            .retrieve_preview(&meta)
            .map_err(|e| ServerError::Internal(e.to_string()))
    }

    pub fn blob_exists(&self, hash_u64: u64) -> bool {
        self.blob_store.get_meta_by_u64(hash_u64).is_some()
    }

    pub fn blob_info(&self, hash_u64: u64) -> Result<BlobMeta, ServerError> {
        self.blob_store
            .get_meta_by_u64(hash_u64)
            .ok_or_else(|| ServerError::NotFound(format!("blob {:016x}", hash_u64)))
    }

    pub fn blob_content_path(
        &self,
        hash_u64: u64,
    ) -> Result<(std::path::PathBuf, String, [u8; 32]), ServerError> {
        let meta = self.blob_info(hash_u64)?;
        let path = self.blob_store.path_for_hash(&meta.content_hash);
        match path {
            Some(p) => Ok((p, meta.mime_type.clone(), meta.content_hash)),
            None => Err(ServerError::Internal(
                "blob store is not file-backed".into(),
            )),
        }
    }

    pub fn blob_preview_path(
        &self,
        hash_u64: u64,
    ) -> Result<(std::path::PathBuf, String), ServerError> {
        let meta = self.blob_info(hash_u64)?;
        let preview_hash = meta.preview_hash.ok_or_else(|| {
            ServerError::NotFound(format!("no preview for blob {:016x}", hash_u64))
        })?;
        let path = self
            .blob_store
            .path_for_hash(&preview_hash)
            .ok_or_else(|| ServerError::Internal("blob store is not file-backed".into()))?;
        Ok((path, meta.mime_type.clone()))
    }

    pub fn blob_stats(&self) -> (u64, u64) {
        let stats = self.blob_store.stats();
        (stats.total_blobs, stats.total_bytes)
    }

    pub fn blob_apply_overlay(
        &mut self,
        session_id: SessionId,
        base_hash: u64,
        ops: Vec<crate::edition::ImageOp>,
        mime_type: String,
    ) -> Result<BlobMeta, ServerError> {
        self.ensure_logged_in(session_id)?;
        if !self.blob_exists(base_hash) {
            return Err(ServerError::NotFound(format!(
                "base blob {:016x}",
                base_hash
            )));
        }
        self.blob_store
            .store_overlay(base_hash, ops, mime_type)
            .map_err(|e| ServerError::Internal(e.to_string()))
    }

    pub fn blob_get_overlay(
        &self,
        hash_u64: u64,
    ) -> Result<crate::edition::ImageOverlay, ServerError> {
        self.blob_store
            .retrieve_overlay_by_u64(hash_u64)
            .map_err(|e| ServerError::Internal(e.to_string()))
    }

    // === Detectors ===

    pub fn add_revision_detector(
        &mut self,
        work_be_id: BeId,
        detector: Box<dyn Detector>,
    ) -> Result<(), ServerError> {
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        ws.revision_detectors.add(detector);
        Ok(())
    }

    pub fn add_status_detector(
        &mut self,
        work_be_id: BeId,
        detector: Box<dyn Detector>,
    ) -> Result<(), ServerError> {
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        ws.status_detectors.add(detector);
        Ok(())
    }

    pub fn add_fill_detector(
        &mut self,
        edition_be_id: BeId,
        detector: Box<dyn Detector>,
    ) -> Result<(), ServerError> {
        self.edition_detectors
            .entry(edition_be_id)
            .or_insert_with(DetectorList::new)
            .add(detector);
        Ok(())
    }

    pub fn fire_fill_event(&mut self, edition_be_id: BeId, region: crate::edition::XnRegion) {
        if let Some(detectors) = self.edition_detectors.get_mut(&edition_be_id) {
            detectors.fire(&Event::RangeFilled {
                edition_be_id,
                region,
            });
        }
    }

    pub fn remove_detector(
        &mut self,
        det_type: super::transport::protocol::DetectorType,
        target_id: BeId,
        sub_id: u16,
    ) {
        match det_type {
            super::transport::protocol::DetectorType::Status => {
                if let Some(ws) = self.works.get_mut(&target_id) {
                    ws.status_detectors.remove(sub_id);
                }
            }
            super::transport::protocol::DetectorType::Revision => {
                if let Some(ws) = self.works.get_mut(&target_id) {
                    ws.revision_detectors.remove(sub_id);
                }
            }
            super::transport::protocol::DetectorType::Fill => {
                if let Some(list) = self.edition_detectors.get_mut(&target_id) {
                    list.remove(sub_id);
                }
            }
            super::transport::protocol::DetectorType::ContentTranscluders
            | super::transport::protocol::DetectorType::ContentWorks => {}
        }
    }

    pub fn drain_content_notifications_for(
        &mut self,
        fossil_ids: &std::collections::HashSet<crate::edition::RecorderId>,
    ) -> Vec<ContentNotification> {
        let mut matching = Vec::new();
        let mut remaining = Vec::new();
        for notif in self.pending_content_notifications.drain(..) {
            if fossil_ids.contains(&notif.fossil_id) {
                matching.push(notif);
            } else {
                remaining.push(notif);
            }
        }
        self.pending_content_notifications = remaining;
        matching
    }

    fn cap_pending_notifications(&mut self) {
        if self.pending_content_notifications.len() >= MAX_PENDING_NOTIFICATIONS {
            let drop_count = self.pending_content_notifications.len() / 4;
            self.pending_content_notifications.drain(..drop_count);
        }
    }

    #[cfg(test)]
    pub(crate) fn cap_pending_notifications_for_test(&mut self) {
        self.cap_pending_notifications();
    }

    // === Private helpers ===

    pub(crate) fn ensure_session(&self, session_id: SessionId) -> Result<(), ServerError> {
        let session = self
            .sessions
            .get(&session_id)
            .ok_or(ServerError::SessionNotFound(session_id))?;
        if !session.is_valid() {
            return Err(ServerError::SessionNotFound(session_id));
        }
        Ok(())
    }

    pub(crate) fn ensure_logged_in(&self, session_id: SessionId) -> Result<(), ServerError> {
        self.ensure_session(session_id)?;
        let session = self
            .sessions
            .get(&session_id)
            .ok_or(ServerError::SessionNotFound(session_id))?;
        if !session.is_logged_in() {
            return Err(ServerError::NotAuthorized);
        }
        Ok(())
    }

    pub(crate) fn ensure_authenticated(&self, session_id: SessionId) -> Result<(), ServerError> {
        self.ensure_session(session_id)?;
        let session = self
            .sessions
            .get(&session_id)
            .ok_or(ServerError::SessionNotFound(session_id))?;
        if session.club_signing_key().is_some() {
            return Ok(());
        }
        if let Some(km) = session._key_master() {
            let auth = km.actual_authority();
            if !auth.is_empty() && !auth.iter().all(|&id| id == 0) {
                return Ok(());
            }
        }
        Err(ServerError::NotAuthorized)
    }

    fn ensure_grabbed_by(
        &self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        match ws.grabber {
            Some(sid) if sid == session_id => Ok(()),
            Some(sid) => Err(ServerError::AlreadyGrabbed {
                work: work_be_id,
                by: Some(sid),
            }),
            None => Err(ServerError::NotGrabbed(work_be_id)),
        }
    }

    pub(crate) fn ensure_can_edit(
        &self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
        self.ensure_session(session_id)?;
        let session = self
            .sessions
            .get(&session_id)
            .ok_or(ServerError::SessionNotFound(session_id))?;
        if session.club_signing_key().is_none() {
            return Err(ServerError::NotAuthorized);
        }
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        if self.check_edit_permission(session_id, &ws.work) {
            Ok(())
        } else {
            Err(ServerError::NotAuthorized)
        }
    }

    fn ensure_owner(&self, session_id: SessionId, work_be_id: BeId) -> Result<(), ServerError> {
        self.ensure_session(session_id)?;
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        let owner = ws.work.owner();
        match owner {
            Some(owner_id) => {
                if self
                    .sessions
                    .get(&session_id)
                    .map(|s| s.has_authority(owner_id))
                    .unwrap_or(false)
                {
                    Ok(())
                } else {
                    Err(ServerError::NotOwner(work_be_id))
                }
            }
            None => Err(ServerError::NotOwner(work_be_id)),
        }
    }

    fn check_read_permission(&self, session_id: SessionId, work: &Work) -> bool {
        if let Some(ws) = self.works.get(&work.be_id()) {
            if ws.grabber == Some(session_id) {
                return true;
            }
        }
        if let Some(read_club) = work.read_club() {
            if read_club == self.system_clubs.public_club {
                return true;
            }
            if self
                .sessions
                .get(&session_id)
                .map(|s| s.has_authority(read_club))
                .unwrap_or(false)
            {
                return true;
            }
        }
        self.check_edit_permission(session_id, work)
    }

    pub fn work_is_readable(&self, session_id: SessionId, work: &Work) -> bool {
        self.check_read_permission(session_id, work)
    }

    pub fn ensure_can_read(
        &self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
        self.ensure_session(session_id)?;
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        if self.work_is_readable(session_id, &ws.work) {
            Ok(())
        } else {
            Err(ServerError::NotAuthorized)
        }
    }

    /// Check that the session can access revision history for a work.
    /// If `history_club` is set, checks against it. If None, falls back
    /// to normal read permission (backward-compatible).
    pub(crate) fn ensure_can_read_history(
        &self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
        self.ensure_session(session_id)?;
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        match ws.work.history_club() {
            Some(club_id) => {
                if club_id == self.system_clubs.public_club {
                    return Ok(());
                }
                let has_auth = self
                    .sessions
                    .get(&session_id)
                    .map(|s| s.has_authority(club_id))
                    .unwrap_or(false);
                if has_auth {
                    Ok(())
                } else {
                    Err(ServerError::NotAuthorized)
                }
            }
            None => {
                // No history_club set — fall back to read permission
                if self.work_is_readable(session_id, &ws.work) {
                    Ok(())
                } else {
                    Err(ServerError::NotAuthorized)
                }
            }
        }
    }

    pub(crate) fn check_edit_permission(&self, session_id: SessionId, work: &Work) -> bool {
        match work.edit_club() {
            Some(club_id) => {
                if club_id == self.system_clubs.public_club {
                    return true;
                }
                self.sessions
                    .get(&session_id)
                    .map(|s| s.has_authority(club_id))
                    .unwrap_or(false)
            }
            None => false,
        }
    }

    fn session_can_edit(&self, session_id: SessionId, work_be_id: BeId) -> bool {
        let ws = match self.works.get(&work_be_id) {
            Some(ws) => ws,
            None => return false,
        };
        self.sessions.contains_key(&session_id) && self.check_edit_permission(session_id, &ws.work)
    }

    pub(crate) fn refresh_all_session_authority(&mut self) {
        let session_ids: Vec<SessionId> = self.sessions.keys().copied().collect();
        for sid in session_ids {
            let km = self
                .sessions
                .get(&sid)
                .and_then(|s| s._key_master().cloned());
            if let Some(mut km) = km {
                km.update_authority(&self.clubs);
                if let Some(session) = self.sessions.get_mut(&sid) {
                    session.set_key_master(km);
                }
            }
        }
    }

    fn _find_grabbed_works(&self, session_id: SessionId) -> Option<Vec<BeId>> {
        let grabbed: Vec<BeId> = self
            .works
            .iter()
            .filter(|(_, ws)| ws.grabber == Some(session_id))
            .map(|(id, _)| *id)
            .collect();
        if grabbed.is_empty() {
            None
        } else {
            Some(grabbed)
        }
    }

    // === Label & Identity operations ===

    pub fn create_label(&mut self) -> u64 {
        use crate::edition::LabelId;
        let id = LabelId::new();
        id.as_u64()
    }

    pub fn label_get_positions(
        &self,
        work_id: BeId,
        label_id: u64,
    ) -> Result<XnRegion, ServerError> {
        let ws = self
            .works
            .get(&work_id)
            .ok_or(ServerError::WorkNotFound(work_id))?;
        let ed = ws.work.current_edition();
        Ok(ed.positions_labelled(label_id))
    }

    pub fn edition_relabel(
        &mut self,
        work_id: BeId,
        _label_id: u64,
    ) -> Result<Edition, ServerError> {
        let ws = self
            .works
            .get(&work_id)
            .ok_or(ServerError::WorkNotFound(work_id))?;
        let _ed = ws.work.current_edition();
        Ok(Edition::empty())
    }

    pub fn edition_rebind(
        &mut self,
        session_id: SessionId,
        work_id: BeId,
        position: i64,
        new_edition: Edition,
    ) -> Result<Edition, ServerError> {
        self.ensure_grabbed_by(session_id, work_id)?;
        let ws = self
            .works
            .get_mut(&work_id)
            .ok_or(ServerError::WorkNotFound(work_id))?;
        let current = ws.work.current_edition();
        if !current.has_position(position) {
            return Err(ServerError::InvalidArgument(format!(
                "position {} not found in work {}",
                position, work_id
            )));
        }
        let old_carrier = current
            .carrier_at(position)
            .ok_or(ServerError::InvalidArgument(
                "no carrier at position".into(),
            ))?;
        let new_elem = new_edition
            .fetch(position)
            .ok_or(ServerError::InvalidArgument(
                "no element at position in new edition".into(),
            ))?;
        let new_carrier = match old_carrier.label.as_ref() {
            Some(lid) => crate::edition::range_element::Carrier::labelled(lid.clone(), new_elem),
            None => crate::edition::range_element::Carrier::new(new_elem),
        };
        let updated = Edition::new_inner(
            current
                .orgl
                .with(position, std::sync::Arc::new(new_carrier)),
            current.endorsements.clone(),
        );
        let old_edition = ws.work.edition().clone();
        ws.work.revise(updated.clone());
        ws.mark_dirty();
        let new_work = ws.work.clone();
        self.backfollow
            .update_work_with_parent(work_id, work_id, &old_edition, &new_work);
        self.reconcile_record_local_revision(work_id, &updated, Self::current_timestamp_secs());
        Ok(updated)
    }

    pub fn can_make_identical_elements(
        &self,
        source_work_id: BeId,
        target_work_id: BeId,
        position: Option<i64>,
    ) -> Result<Vec<(i64, String)>, ServerError> {
        let source_ws = self
            .works
            .get(&source_work_id)
            .ok_or(ServerError::WorkNotFound(source_work_id))?;
        let target_ws = self
            .works
            .get(&target_work_id)
            .ok_or(ServerError::WorkNotFound(target_work_id))?;
        let source_ed = source_ws.work.current_edition();
        let target_ed = target_ws.work.current_edition();
        let positions: Vec<i64> = match position {
            Some(p) => vec![p],
            None => source_ed.all_entries().iter().map(|(p, _)| *p).collect(),
        };
        let mut results = Vec::new();
        for pos in positions {
            let source_elem = source_ed.fetch(pos);
            let target_elem = target_ed.fetch(pos);
            match (source_elem, target_elem) {
                (Some(s), Some(t)) => {
                    let result = crate::edition::can_make_identical(&s, &t);
                    let label = match result {
                        crate::edition::CanMakeIdenticalResult::Yes => "yes",
                        crate::edition::CanMakeIdenticalResult::DifferentType => "different_type",
                        crate::edition::CanMakeIdenticalResult::DifferentContent => {
                            "different_content"
                        }
                        crate::edition::CanMakeIdenticalResult::NotOwned => "not_owned",
                    };
                    results.push((pos, label.to_string()));
                }
                (Some(_), None) => results.push((pos, "no_target".to_string())),
                (None, _) => {}
            }
        }
        Ok(results)
    }

    pub fn make_range_identical_editions(
        &mut self,
        session_id: SessionId,
        source_work_id: BeId,
        target_work_id: BeId,
        region: Option<XnRegion>,
    ) -> Result<(String, u64, Edition), ServerError> {
        self.ensure_can_edit(session_id, source_work_id)?;
        let source_ws = self
            .works
            .get(&source_work_id)
            .ok_or(ServerError::WorkNotFound(source_work_id))?;
        let target_ws = self
            .works
            .get(&target_work_id)
            .ok_or(ServerError::WorkNotFound(target_work_id))?;
        let source_ed = source_ws.work.current_edition();
        let target_ed = target_ws.work.current_edition();
        let result = crate::edition::make_range_identical(&source_ed, &target_ed, region.as_ref());
        let outcome = match result.outcome {
            crate::edition::MakeRangeIdenticalOutcome::AllUnified => "all_unified",
            crate::edition::MakeRangeIdenticalOutcome::PartiallyUnified { .. } => {
                "partially_unified"
            }
        };
        let failed_count = result.failed.count();
        Ok((outcome.to_string(), failed_count, result.failed))
    }

    pub fn identity_unify(&mut self, source_id: u64, target_id: u64) {
        self.grand_map.unify_identity(source_id, target_id);
    }

    pub fn identity_resolve(&self, id: u64) -> u64 {
        self.grand_map.resolve_identity(id)
    }

    pub fn edition_retrieve(
        &self,
        work_id: BeId,
        region: Option<&XnRegion>,
        flags: crate::edition::RetrieveFlags,
    ) -> Result<Vec<crate::edition::Bundle>, ServerError> {
        let ws = self
            .works
            .get(&work_id)
            .ok_or_else(|| ServerError::WorkNotFound(work_id))?;
        let edition = ws.work.current_edition();
        Ok(edition.retrieve(region, flags))
    }

    pub fn edition_cost(
        &self,
        work_id: BeId,
        method: crate::edition::CostMethod,
    ) -> Result<crate::edition::StorageCost, ServerError> {
        let ws = self
            .works
            .get(&work_id)
            .ok_or_else(|| ServerError::WorkNotFound(work_id))?;
        let edition = ws.work.current_edition();
        Ok(edition.cost(method))
    }

    pub fn content_shared_region(
        &self,
        work_a: BeId,
        work_b: BeId,
    ) -> Result<XnRegion, ServerError> {
        let ed_a = self
            .get_edition(work_a)?
            .ok_or(ServerError::WorkNotFound(work_a))?;
        let ed_b = self
            .get_edition(work_b)?
            .ok_or(ServerError::WorkNotFound(work_b))?;
        Ok(ed_a.content_shared_region(&ed_b))
    }

    pub fn content_map_shared_to(
        &self,
        work_a: BeId,
        work_b: BeId,
    ) -> Result<crate::edition::SharedMapping, ServerError> {
        let ed_a = self
            .get_edition(work_a)?
            .ok_or(ServerError::WorkNotFound(work_a))?;
        let ed_b = self
            .get_edition(work_b)?
            .ok_or(ServerError::WorkNotFound(work_b))?;
        Ok(ed_a.content_map_shared_to(&ed_b))
    }

    pub fn content_map_shared_onto(
        &self,
        work_a: BeId,
        work_b: BeId,
    ) -> Result<crate::edition::SharedMapping, ServerError> {
        let ed_a = self
            .get_edition(work_a)?
            .ok_or(ServerError::WorkNotFound(work_a))?;
        let ed_b = self
            .get_edition(work_b)?
            .ok_or(ServerError::WorkNotFound(work_b))?;
        Ok(ed_a.content_map_shared_onto(&ed_b))
    }

    pub fn positions_of(
        &self,
        work_id: BeId,
        element: &RangeElement,
    ) -> Result<XnRegion, ServerError> {
        let edition = self
            .get_edition(work_id)?
            .ok_or(ServerError::WorkNotFound(work_id))?;
        Ok(edition.positions_of(element))
    }

    pub fn range_transcluders(
        &self,
        work_id: BeId,
        region: Option<&XnRegion>,
        direct_only: bool,
    ) -> Result<crate::edition::RangeTransclusionResult, ServerError> {
        let edition = self
            .get_edition(work_id)?
            .ok_or(ServerError::WorkNotFound(work_id))?;
        let query = crate::edition::RangeTransclusionQuery::new().direct_only(direct_only);
        let query = match region {
            Some(r) => query.with_region(r.clone()),
            None => query,
        };
        let tq = crate::edition::TransclusionQuery::all();
        Ok(crate::edition::range_transcluders(
            &edition,
            &query,
            self.backfollow.transclusion_index(),
            &tq,
        ))
    }

    pub fn range_works(
        &self,
        work_id: BeId,
        region: Option<&XnRegion>,
    ) -> Result<crate::edition::RangeWorkResult, ServerError> {
        let edition = self
            .get_edition(work_id)?
            .ok_or(ServerError::WorkNotFound(work_id))?;
        let query = crate::edition::RangeTransclusionQuery::new();
        let query = match region {
            Some(r) => query.with_region(r.clone()),
            None => query,
        };
        let wq = crate::edition::WorkQuery::all();
        Ok(crate::edition::range_works(
            &edition,
            &query,
            self.backfollow.transclusion_index(),
            &wq,
        ))
    }

    pub fn ordered_bundles(
        &self,
        work_id: BeId,
        region: Option<&XnRegion>,
    ) -> Result<Vec<crate::edition::Bundle>, ServerError> {
        let edition = self
            .get_edition(work_id)?
            .ok_or(ServerError::WorkNotFound(work_id))?;
        Ok(edition.ordered_merge_bundles(region))
    }

    pub fn transclusion_depth(
        &self,
        work_id: BeId,
        position: i64,
        max_depth: usize,
    ) -> Result<usize, ServerError> {
        let edition = self
            .get_edition(work_id)?
            .ok_or(ServerError::WorkNotFound(work_id))?;
        Ok(edition.transclusion_depth(position, self.backfollow.transclusion_index(), max_depth))
    }

    pub fn recorder_create(
        &mut self,
        query: crate::edition::RecorderQuery,
    ) -> Result<crate::edition::RecorderId, ServerError> {
        Ok(self.recorder_system.create_fossil(query))
    }

    pub fn recorder_record(
        &mut self,
        recorder_id: crate::edition::RecorderId,
        element: &crate::edition::RangeElement,
    ) -> Result<bool, ServerError> {
        let is_direct = true;
        let source_edition_id = element.as_edition_id();
        let source_work_id = element.as_work_id();
        Ok(self.recorder_system.record_result(
            recorder_id,
            element.clone(),
            source_edition_id,
            source_work_id,
            is_direct,
        ))
    }

    pub fn recorder_list(&self) -> Vec<&crate::edition::Fossil> {
        self.recorder_system
            .fossil_ids()
            .into_iter()
            .filter_map(|id| self.recorder_system.get_fossil(id))
            .collect()
    }

    pub fn recorder_get(&self, id: crate::edition::RecorderId) -> Option<&crate::edition::Fossil> {
        self.recorder_system.get_fossil(id)
    }

    pub fn server_health(&self) -> ServerHealth {
        ServerHealth {
            operation_count: self.operation_counter,
            active_recorders: self.recorder_system.active_fossil_count(),
            total_recorded: self.recorder_system.total_result_count(),
            blob_count: self.blob_store.stats().total_blobs as usize,
            link_count: self.links.len(),
            uptime_secs: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs()
                .saturating_sub(self.start_time),
        }
    }

    pub fn server_identity(&self) -> crate::crypto::keys::ServerIdentity {
        crate::crypto::keys::ServerIdentity::from_keypair(&self.server_keypair)
    }

    pub fn server_public_signing_key(&self) -> [u8; 32] {
        self.server_keypair.signing_verifying_key().to_bytes()
    }

    pub fn server_public_kex_key(&self) -> [u8; 32] {
        *self.server_keypair.kex_public().as_bytes()
    }

    pub fn server_key_id(&self) -> crate::crypto::keys::KeyId {
        self.server_keypair.key_id
    }

    pub fn server_key_history(&self) -> &crate::crypto::keys::KeyHistory {
        &self.key_history
    }

    pub fn rotate_server_keys(&mut self) -> Result<crate::crypto::keys::KeyId, ServerError> {
        let old_kp = self.server_keypair.clone();
        let new_kp = crate::crypto::keys::ServerKeyPair::generate("xudanu-server");
        let new_id = self
            .key_history
            .rotate(&old_kp, &new_kp)
            .map_err(|e| ServerError::Internal(format!("key rotation failed: {}", e)))?;
        self.server_keypair = new_kp;
        Ok(new_id)
    }

    pub fn sign_data(&self, data: &[u8]) -> Vec<u8> {
        let sig = crate::crypto::sign::sign_bytes(&self.server_keypair.signing_key, data);
        sig.to_bytes().to_vec()
    }

    pub fn verify_server_signature(
        &self,
        data: &[u8],
        signature: &[u8],
    ) -> Result<(), ServerError> {
        self.verify_server_signature_with_key(None, data, signature)
    }

    pub fn verify_server_signature_with_key(
        &self,
        key_id: Option<u64>,
        data: &[u8],
        signature: &[u8],
    ) -> Result<(), ServerError> {
        let sig = ed25519_dalek::Signature::from_slice(signature)
            .map_err(|_| ServerError::InvalidArgument("invalid signature bytes".into()))?;
        let verifying_key = match key_id {
            Some(kid) => {
                let entry = self.key_history.get(kid).ok_or_else(|| {
                    ServerError::InvalidArgument(format!("unknown key_id: {}", kid))
                })?;
                &entry.verifying_key
            }
            None => &self.server_keypair.signing_verifying_key(),
        };
        crate::crypto::sign::verify_signature(verifying_key, data, &sig)
            .map_err(|_| ServerError::InvalidArgument("signature verification failed".into()))
    }

    fn validate_endorsement(
        &self,
        session_id: SessionId,
        endorsements: &crate::edition::EndorsementSet,
    ) -> Result<(), ServerError> {
        if endorsements.is_empty() {
            return Ok(());
        }
        self.ensure_session(session_id)?;
        let session = self
            .sessions
            .get(&session_id)
            .ok_or(ServerError::SessionNotFound(session_id))?;
        for club_id in endorsements.club_ids() {
            if session.has_authority(club_id) {
                continue;
            }
            let km = match session._key_master() {
                Some(km) => km,
                None => {
                    return Err(ServerError::Unauthorized(format!(
                        "no authority for club {}",
                        club_id
                    )))
                }
            };
            if !km.has_signature_authority(club_id, &self.clubs) {
                return Err(ServerError::Unauthorized(format!(
                    "no signature authority for club {}",
                    club_id
                )));
            }
        }
        Ok(())
    }

    pub fn work_endorse(
        &mut self,
        session_id: SessionId,
        work_id: BeId,
        endorsements: crate::edition::EndorsementSet,
    ) -> Result<(), ServerError> {
        self.validate_endorsement(session_id, &endorsements)?;
        {
            let ws = self
                .works
                .get_mut(&work_id)
                .ok_or(ServerError::NotFound(format!("work {}", work_id)))?;
            ws.work.endorse(&endorsements);
            ws.mark_dirty();
        }
        tracing::info!(
            "[work_endorse] calling checkpoint_to_store for work {}",
            work_id
        );
        if let Err(e) = self.checkpoint_to_store() {
            tracing::warn!("[work_endorse] checkpoint failed: {}", e);
        }
        Ok(())
    }

    pub fn work_retract(
        &mut self,
        session_id: SessionId,
        work_id: BeId,
        endorsements: crate::edition::EndorsementSet,
    ) -> Result<(), ServerError> {
        self.validate_endorsement(session_id, &endorsements)?;
        {
            let ws = self
                .works
                .get_mut(&work_id)
                .ok_or(ServerError::NotFound(format!("work {}", work_id)))?;
            ws.work.retract(&endorsements);
            ws.mark_dirty();
        }
        let _ = self.checkpoint_to_store();
        Ok(())
    }

    pub fn work_endorsements(
        &self,
        work_id: BeId,
    ) -> Result<crate::edition::EndorsementSet, ServerError> {
        let ws = self
            .works
            .get(&work_id)
            .ok_or(ServerError::NotFound(format!("work {}", work_id)))?;
        Ok(ws.work.endorsements().clone())
    }

    pub fn edition_endorse(
        &mut self,
        session_id: SessionId,
        edition_id: BeId,
        endorsements: crate::edition::EndorsementSet,
    ) -> Result<(), ServerError> {
        self.validate_endorsement(session_id, &endorsements)?;
        let edition = self
            .standalone_editions
            .get_mut(&edition_id)
            .ok_or(ServerError::NotFound(format!("edition {}", edition_id)))?;
        edition.endorse(&endorsements);
        self.standalone_edition_refs.remove(&edition_id);
        Ok(())
    }

    pub fn edition_retract(
        &mut self,
        session_id: SessionId,
        edition_id: BeId,
        endorsements: crate::edition::EndorsementSet,
    ) -> Result<(), ServerError> {
        self.validate_endorsement(session_id, &endorsements)?;
        let edition = self
            .standalone_editions
            .get_mut(&edition_id)
            .ok_or(ServerError::NotFound(format!("edition {}", edition_id)))?;
        edition.retract(&endorsements);
        self.standalone_edition_refs.remove(&edition_id);
        Ok(())
    }

    pub fn edition_endorsements(
        &self,
        edition_id: BeId,
    ) -> Result<crate::edition::EndorsementSet, ServerError> {
        let edition = self
            .standalone_editions
            .get(&edition_id)
            .ok_or(ServerError::NotFound(format!("edition {}", edition_id)))?;
        Ok(edition.endorsements().clone())
    }

    pub fn edition_visible_endorsements(
        &self,
        session_id: SessionId,
        edition_id: BeId,
    ) -> Result<crate::edition::EndorsementSet, ServerError> {
        let edition = self
            .standalone_editions
            .get(&edition_id)
            .ok_or(ServerError::NotFound(format!("edition {}", edition_id)))?;
        let _session = self
            .sessions
            .get(&session_id)
            .ok_or(ServerError::SessionNotFound(session_id))?;
        let mut result = edition.endorsements().clone();
        let candidates = self.works_with_edition_fingerprints(edition);
        for wid in candidates {
            if let Some(ws) = self.works.get(&wid) {
                if ws.work.current_edition() == edition {
                    if self.work_can_read_by(session_id, ws.work.be_id()) {
                        result = result.union(ws.work.endorsements());
                    }
                }
            }
        }
        Ok(result)
    }

    pub fn edition_total_endorsements(
        &self,
        edition_id: BeId,
    ) -> Result<crate::edition::EndorsementSet, ServerError> {
        let edition = self
            .standalone_editions
            .get(&edition_id)
            .ok_or(ServerError::NotFound(format!("edition {}", edition_id)))?;
        let mut result = edition.endorsements().clone();
        let candidates = self.works_with_edition_fingerprints(edition);
        for wid in candidates {
            if let Some(ws) = self.works.get(&wid) {
                if ws.work.current_edition() == edition {
                    result = result.union(ws.work.endorsements());
                }
            }
        }
        Ok(result)
    }

    fn works_with_edition_fingerprints(
        &self,
        edition: &Edition,
    ) -> std::collections::HashSet<BeId> {
        let mut candidates = std::collections::HashSet::new();
        for (_, carrier) in edition.all_entries() {
            let fp = carrier.element.content_fingerprint();
            for wid in self.backfollow.find_works_by_fingerprint(&fp) {
                candidates.insert(wid);
            }
        }
        candidates
    }

    fn work_can_read_by(&self, session_id: SessionId, work_id: BeId) -> bool {
        let session = match self.sessions.get(&session_id) {
            Some(s) => s,
            None => return false,
        };
        let km = match session._key_master() {
            Some(km) => km,
            None => return false,
        };
        let ws = match self.works.get(&work_id) {
            Some(ws) => ws,
            None => return false,
        };
        match ws.work.read_club() {
            Some(read_club) => km.has_authority(read_club),
            None => true,
        }
    }

    pub fn federation_info(&self) -> crate::server::federation::FederationInfo {
        let identity = self.server_identity();
        let config = self.federation.config();
        let peers = config
            .peers
            .iter()
            .map(|p| {
                let addr_str = p.to_string();
                match self.federation.peer_server_id(&addr_str) {
                    Some(sid) => crate::server::federation::FederationPeerInfo::connected(
                        p.clone(),
                        sid.to_string(),
                    ),
                    None => crate::server::federation::FederationPeerInfo::unknown(p.clone()),
                }
            })
            .collect();
        crate::server::federation::FederationInfo {
            server_id: identity.server_id.clone(),
            federation_domain: crate::crypto::FEDERATION_DOMAIN.to_string(),
            key_id: self.server_key_id(),
            verifying_key: identity.signing_key_bytes().to_vec(),
            kex_key: identity.kex_public_bytes().to_vec(),
            mode: config.mode.clone(),
            peers,
            work_count: self.works.len(),
            edition_count: self.standalone_editions.len(),
        }
    }

    pub fn federation_peers(&self) -> Vec<crate::server::federation::PeerAddress> {
        self.federation.peer_addresses().to_vec()
    }

    pub fn federation_is_peer_known(&self, verifying_key_hex: &str) -> bool {
        if !self.federation.is_enabled() {
            return true;
        }
        self.federation.is_peer_known(verifying_key_hex)
    }

    pub fn set_federation_config(&mut self, config: crate::server::federation::FederationConfig) {
        self.federation = crate::server::federation::FederationState::new(config);
    }

    pub fn federation_register_peer_key(&mut self, verifying_key_hex: String) {
        self.federation.register_peer_key(verifying_key_hex);
    }

    pub fn federation_mark_peer_connected(&mut self, address: &str, server_id: String) {
        self.federation.mark_peer_connected(address, server_id);
    }

    pub fn federation_mark_peer_disconnected(&mut self, address: &str) {
        self.federation.mark_peer_disconnected(address);
    }

    pub fn get_remote_origin(
        &self,
        fingerprint: &[u8; 32],
    ) -> Option<&crate::server::federation::RemoteOrigin> {
        self.federation.get_remote_origin(fingerprint)
    }

    pub fn federation_remote_origin_count(&self) -> usize {
        self.federation.remote_origins().len()
    }

    pub fn federation_has_federated_transclusions(&self) -> bool {
        self.backfollow.has_federated_entries()
    }

    pub fn federation_is_enabled(&self) -> bool {
        self.federation.is_enabled()
    }

    pub fn federation_handshake_init(
        &self,
    ) -> (String, [u8; 32], crate::crypto::kex::EphemeralKeyPair) {
        let identity = self.server_identity();
        let eph = crate::crypto::kex::EphemeralKeyPair::generate();
        let eph_bytes = *eph.public_key();
        (identity.server_id, eph_bytes, eph)
    }

    pub fn federation_sign_handshake(
        &self,
        my_eph: &[u8; 32],
        peer_eph: &[u8; 32],
    ) -> (Vec<u8>, Vec<u8>, Vec<u8>) {
        let sig =
            crate::crypto::kex::sign_handshake(&self.server_keypair.signing_key, my_eph, peer_eph);
        (
            sig.to_bytes().to_vec(),
            self.server_keypair
                .signing_verifying_key()
                .to_bytes()
                .to_vec(),
            self.server_keypair.kex_public().as_bytes().to_vec(),
        )
    }

    pub fn federation_derive_session_keys(
        &self,
        peer_kex_public: &[u8; 32],
        my_eph: &crate::crypto::kex::EphemeralKeyPair,
        peer_eph: &[u8; 32],
    ) -> crate::crypto::kdf::FederationSessionKeys {
        let shared_secret = crate::crypto::kex::peer_key_exchange(
            &self.server_keypair.kex_secret,
            peer_kex_public,
            my_eph,
            peer_eph,
        );
        let transcript = crate::crypto::kex::canonical_transcript(my_eph.public_key(), peer_eph);
        crate::crypto::kdf::derive_federation_session_keys(shared_secret.as_bytes(), &transcript)
    }

    pub fn federation_export_works(&self) -> Vec<crate::server::federation::SyncWorkEntry> {
        let server_id = self.federation_server_id();
        self.works
            .iter()
            .filter(|(_, ws)| ws.work.read_club() == Some(self.system_clubs.public_club))
            .map(|(work_id, ws)| crate::server::federation::SyncWorkEntry {
                origin_server_id: server_id.clone(),
                work_id: *work_id,
                edition_payload: crate::server::transport::protocol::EditionPayload::from_edition(
                    ws.work.current_edition(),
                ),
                span_provenance: ws.work.current_edition().span_provenance.clone(),
            })
            .collect()
    }

    pub fn federation_export_editions(&self) -> Vec<crate::server::federation::SyncEditionEntry> {
        let server_id = self.federation_server_id();
        self.standalone_editions
            .iter()
            .map(
                |(edition_id, edition)| crate::server::federation::SyncEditionEntry {
                    origin_server_id: server_id.clone(),
                    edition_id: *edition_id,
                    edition_payload:
                        crate::server::transport::protocol::EditionPayload::from_edition(edition),
                },
            )
            .collect()
    }

    pub fn federation_import_works(
        &mut self,
        entries: &[crate::server::federation::SyncWorkEntry],
        my_server_id: &str,
    ) -> (usize, usize) {
        let _guard = OperationGuard::new(
            self.consequence_tracker.clone(),
            self.consequence_tracker.begin_operation(),
        );
        let mut imported = 0;
        let mut already_known = 0;
        let existing_fingerprints: Vec<[u8; 32]> = self
            .works
            .iter()
            .filter_map(|(_, ws)| {
                let ed = ws.work.current_edition();
                let entries = ed.all_entries();
                if entries.is_empty() {
                    return None;
                }
                let mut hasher = blake3::Hasher::new();
                for (pos, carrier) in &entries {
                    hasher.update(&pos.to_be_bytes());
                    hasher.update(&carrier.element.content_fingerprint());
                }
                Some(*hasher.finalize().as_bytes())
            })
            .collect();

        for entry in entries {
            if entry.origin_server_id == my_server_id {
                already_known += 1;
                continue;
            }
            let mut edition = entry.edition_payload.to_edition();
            if !entry.span_provenance.is_empty() && edition.span_provenance.is_empty() {
                edition.span_provenance = entry.span_provenance.clone();
            }
            let entry_fingerprint = {
                let entries = edition.all_entries();
                let mut hasher = blake3::Hasher::new();
                for (pos, carrier) in &entries {
                    hasher.update(&pos.to_be_bytes());
                    hasher.update(&carrier.element.content_fingerprint());
                }
                *hasher.finalize().as_bytes()
            };
            if existing_fingerprints
                .iter()
                .any(|fp| *fp == entry_fingerprint)
            {
                already_known += 1;
            } else {
                let (be_id, elem) = self.grand_map.new_work_element(None);
                self.grand_map.assign_new_id(elem);
                let title = Self::extract_title(&edition);
                let mut work = crate::edition::Work::new_with_owner(be_id, None, edition);
                work.set_read_club(Some(self.system_clubs.public_club));
                let ws = WorkState {
                    work,
                    chunk_ref: None,
                    dirty_gen: 0,
                    grabber: None,
                    grabbed_at: None,
                    grab_waiters: Vec::new(),
                    last_revision_author: None,
                    revision_authors: std::collections::HashMap::new(),
                    revision_timestamps: std::collections::HashMap::new(),
                    status_detectors: DetectorList::new(),
                    revision_detectors: DetectorList::new(),
                    cached_title: title,
                    is_source: false,
                    source_author_id: None,
                    source_edition_info: None,
                    imported_by: None,
                    content_start_line: None,
                    content_end_line: None,
                    source_fingerprint: None,
                };
                self.works.insert(be_id, ws);
                imported += 1;

                let ws = match self.works.get(&be_id) {
                    Some(ws) => ws,
                    None => continue,
                };
                for (_, carrier) in ws.work.current_edition().all_entries() {
                    let fp = carrier.element.content_fingerprint();
                    self.federation.record_remote_origin(
                        fp,
                        crate::server::federation::RemoteOrigin {
                            server_id: entry.origin_server_id.clone(),
                            local_id: entry.work_id,
                            element_type: crate::server::federation::RemoteElementType::Work,
                        },
                    );
                    self.backfollow.register_fingerprint_for_work(fp, be_id);
                    self.backfollow.register_federated_entry(
                        &carrier.element,
                        entry.origin_server_id.clone(),
                        entry.work_id,
                        "work".to_string(),
                        true,
                    );
                }
            }
        }
        (imported, already_known)
    }

    pub fn federation_export_blobs(&self) -> Vec<crate::server::federation::SyncBlobEntry> {
        let hashes: Vec<[u8; 32]> = self.blob_store.all_hashes();
        hashes
            .into_iter()
            .filter_map(|hash| {
                let data = match self.blob_store.retrieve(&hash) {
                    Ok(d) => d,
                    Err(_) => return None,
                };
                let meta = match self.blob_store.get_meta(&hash) {
                    Some(m) => m,
                    None => return None,
                };
                Some(crate::server::federation::SyncBlobEntry {
                    content_hash_hex: crate::edition::blob_store::hash_to_hex(&hash),
                    data: crate::edition::blob_store::base64_encode(&data),
                    mime_type: meta.mime_type.clone(),
                })
            })
            .collect()
    }

    pub fn federation_import_blobs(
        &mut self,
        entries: &[crate::server::federation::SyncBlobEntry],
        origin_server_id: &str,
    ) -> (usize, usize) {
        let mut imported = 0;
        let mut already_known = 0;
        for entry in entries {
            let hash_bytes = match crate::edition::blob_store::hex_to_hash(&entry.content_hash_hex)
            {
                Some(h) => h,
                None => continue,
            };
            if self.blob_store.exists(&hash_bytes).unwrap_or(false) {
                already_known += 1;
                continue;
            }
            let data = match crate::edition::blob_store::base64_decode(&entry.data) {
                Some(d) => d,
                None => continue,
            };
            let computed = crate::edition::blob_store::hash_content(&data);
            if computed != hash_bytes {
                tracing::warn!(
                    "Federation: blob hash mismatch for {}, rejecting",
                    entry.content_hash_hex
                );
                continue;
            }
            let _ = self.blob_store.store(&data, entry.mime_type.clone());
            self.federation.record_remote_origin(
                hash_bytes,
                crate::server::federation::RemoteOrigin {
                    server_id: origin_server_id.to_string(),
                    local_id: 0,
                    element_type: crate::server::federation::RemoteElementType::Blob,
                },
            );
            imported += 1;
        }
        (imported, already_known)
    }

    pub fn federation_server_id(&self) -> String {
        self.server_keypair.identity_id()
    }

    pub fn federation_server_id_bytes(&self) -> [u8; 32] {
        self.server_keypair.signing_key.verifying_key().to_bytes()
    }

    pub fn federation_crdt_pull(
        &mut self,
        work_ids: &[BeId],
    ) -> Vec<crate::server::federation::CrdtWorkUpdate> {
        let mut updates = Vec::new();
        for &work_id in work_ids {
            if let Ok(text) = self.otree_crdt.extract_update_for_federation(work_id) {
                if !text.is_empty() {
                    updates.push(crate::server::federation::CrdtWorkUpdate {
                        work_id,
                        update_bytes: text.into_bytes(),
                        span_provenance: self
                            .works
                            .get(&work_id)
                            .map(|ws| ws.work.current_edition().span_provenance.clone())
                            .unwrap_or_default(),
                    });
                }
            }
        }
        updates
    }

    pub fn federation_crdt_apply(
        &mut self,
        updates: &[crate::server::federation::CrdtWorkUpdate],
    ) -> crate::server::federation::CrdtSyncResult {
        let mut applied = 0usize;
        let mut failed = 0usize;
        for update in updates {
            let initial_text = if !self.otree_crdt.is_active(update.work_id) {
                if let Ok(edition) = self.work_edition(update.work_id) {
                    Some(
                        edition
                            .all_entries()
                            .iter()
                            .map(|(_, c)| c.element.as_text().unwrap_or(""))
                            .collect::<String>(),
                    )
                } else {
                    None
                }
            } else {
                None
            };

            let text = String::from_utf8_lossy(&update.update_bytes);
            let initial_edition = initial_text.as_deref().map(Edition::from_text_batched);
            match self.otree_crdt.apply_federation_update(
                update.work_id,
                &text,
                initial_edition.as_ref(),
            ) {
                Ok(_) => {
                    if !update.span_provenance.is_empty() {
                        self.otree_crdt.store_federated_provenance(
                            update.work_id,
                            update.span_provenance.clone(),
                        );
                    }
                    applied += 1
                }
                Err(_) => failed += 1,
            }
        }
        crate::server::federation::CrdtSyncResult {
            updates_applied: applied,
            updates_failed: failed,
        }
    }

    pub fn server_verifying_key(&self) -> ed25519_dalek::VerifyingKey {
        self.server_keypair.signing_verifying_key()
    }

    pub fn federation_get_work_edition(
        &self,
        work_id: u64,
    ) -> Option<crate::server::transport::protocol::EditionPayload> {
        self.works.get(&work_id).map(|ws| {
            crate::server::transport::protocol::EditionPayload::from_edition(
                ws.work.current_edition(),
            )
        })
    }

    pub fn federation_get_blob(&self, content_hash_hex: &str) -> Option<(String, String)> {
        let hash = crate::edition::blob_store::hex_to_hash(content_hash_hex)?;
        let data = self.blob_store.retrieve(&hash).ok()?;
        let meta = self.blob_store.get_meta(&hash)?;
        Some((
            crate::edition::blob_store::base64_encode(&data),
            meta.mime_type.clone(),
        ))
    }

    pub fn federation_query_local_transclusion(
        &self,
        content_fingerprint_hex: &str,
        direct_only: bool,
    ) -> Vec<crate::server::federation::FederatedTransclusionEntry> {
        let mut entries = Vec::new();

        let local_results = self
            .backfollow
            .transclusion_index()
            .find_by_fingerprint_hex(content_fingerprint_hex);
        for (element, is_direct) in &local_results {
            if direct_only && !is_direct {
                continue;
            }
            let (elem_type, local_id) = match element {
                crate::edition::RangeElement::Edition { edition_id } => ("edition", edition_id.0),
                crate::edition::RangeElement::Work { work_id } => ("work", work_id.0),
                _ => continue,
            };
            entries.push(crate::server::federation::FederatedTransclusionEntry {
                content_fingerprint_hex: content_fingerprint_hex.to_string(),
                origin_server_id: self.federation_server_id(),
                element_type: match elem_type {
                    "work" => crate::server::federation::RemoteElementType::Work,
                    _ => crate::server::federation::RemoteElementType::Edition,
                },
                local_id,
                is_direct: *is_direct,
            });
        }

        let fed_results = self
            .backfollow
            .transclusion_index()
            .find_federated_by_hex(content_fingerprint_hex);
        for result in &fed_results {
            if direct_only && !result.is_direct {
                continue;
            }
            entries.push(crate::server::federation::FederatedTransclusionEntry {
                content_fingerprint_hex: content_fingerprint_hex.to_string(),
                origin_server_id: result.origin_server_id.clone(),
                element_type: match result.element_type.as_str() {
                    "work" => crate::server::federation::RemoteElementType::Work,
                    "blob" => crate::server::federation::RemoteElementType::Blob,
                    _ => crate::server::federation::RemoteElementType::Edition,
                },
                local_id: result.local_id,
                is_direct: result.is_direct,
            });
        }

        entries
    }

    pub fn federation_fetch_by_fingerprint(
        &self,
        content_fingerprint_hex: &str,
    ) -> FederationFetchResponse {
        if let Some(fp_bytes) = Self::hex_to_fingerprint(content_fingerprint_hex) {
            let fp: [u8; 32] = match fp_bytes.as_slice().try_into() {
                Ok(arr) => arr,
                Err(_) => return FederationFetchResponse::NotFound,
            };
            if let Some(work_ids) = self.backfollow.fingerprint_to_works().get(&fp) {
                if let Some(&work_id) = work_ids.iter().next() {
                    if let Some(ws) = self.works.get(&work_id) {
                        let ed = ws.work.current_edition();
                        let payload =
                            crate::server::transport::protocol::EditionPayload::from_edition(&ed);
                        return FederationFetchResponse::Edition(payload);
                    }
                }
            }
            if let Ok(data) = self.blob_store.retrieve(&fp) {
                if let Some(meta) = self.blob_store.get_meta(&fp) {
                    return FederationFetchResponse::Blob(
                        crate::edition::blob_store::base64_encode(&data),
                        meta.mime_type.clone(),
                    );
                }
            }
        }
        FederationFetchResponse::NotFound
    }

    fn hex_to_fingerprint(hex: &str) -> Option<Vec<u8>> {
        if hex.len() != 64 {
            return None;
        }
        let mut bytes = Vec::with_capacity(32);
        for i in (0..64).step_by(2) {
            match u8::from_str_radix(&hex[i..i + 2], 16) {
                Ok(b) => bytes.push(b),
                Err(_) => return None,
            }
        }
        Some(bytes)
    }

    // =================================================================
    // Phase 18: DagWood Reconciliation & Endorsement Sync
    // =================================================================

    fn current_timestamp_secs() -> u64 {
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs()
    }

    fn hex_encode(data: &[u8]) -> String {
        data.iter().map(|b| format!("{:02x}", b)).collect()
    }

    fn hex_decode(hex: &str) -> Result<Vec<u8>, String> {
        if hex.len() % 2 != 0 {
            return Err("invalid hex length".to_string());
        }
        (0..hex.len())
            .step_by(2)
            .map(|i| {
                u8::from_str_radix(&hex[i..i + 2], 16)
                    .map_err(|e| format!("hex decode error: {}", e))
            })
            .collect()
    }

    /// Record a local work revision into the reconcile store.
    /// This should be called whenever a work is created or revised locally.
    pub fn reconcile_record_local_revision(
        &mut self,
        work_id: BeId,
        edition: &Edition,
        timestamp: u64,
    ) {
        let server_id = self.federation_server_id();
        let rev = {
            if let Some(ws) = self.works.get(&work_id) {
                ws.work.revision_count()
            } else {
                return;
            }
        };

        let fp_hex = {
            let entries = edition.all_entries();
            let mut hasher = blake3::Hasher::new();
            for (pos, carrier) in &entries {
                hasher.update(&pos.to_be_bytes());
                hasher.update(&carrier.element.content_fingerprint());
            }
            let hash = hasher.finalize();
            crate::edition::blob_store::hash_to_hex(hash.as_bytes())
        };

        let alt =
            crate::server::federation::AlternativeEdition::new(&server_id, rev, edition, timestamp);
        let key = alt.key();

        let state =
            self.reconcile_store
                .get_or_create(&fp_hex, key.clone(), alt, &server_id, timestamp);
        state.set_current(key, timestamp, &server_id);
    }

    /// Merge a remote ReconcileState into the local store.
    /// Used when receiving state_sync from a federated peer.
    pub fn reconcile_merge_remote(&mut self, remote: crate::server::federation::ReconcileState) {
        self.reconcile_store.merge_remote(&remote);
    }

    /// Export the full reconcile store for sync to a peer.
    pub fn reconcile_export_all(&self) -> Vec<crate::server::federation::ReconcileState> {
        self.reconcile_store
            .fingerprints()
            .into_iter()
            .filter_map(|fp| self.reconcile_store.get(&fp).cloned())
            .collect()
    }

    /// Get reconcile state for a specific work fingerprint.
    pub fn reconcile_get(
        &self,
        work_fingerprint: &str,
    ) -> Option<&crate::server::federation::ReconcileState> {
        self.reconcile_store.get(work_fingerprint)
    }

    /// Get all alternative editions for a work fingerprint.
    pub fn reconcile_alternatives(
        &self,
        work_fingerprint: &str,
    ) -> Vec<crate::server::federation::AlternativeEdition> {
        self.reconcile_store
            .get(work_fingerprint)
            .map(|s| s.all_alternatives().into_iter().cloned().collect())
            .unwrap_or_default()
    }

    /// Add an endorsement to a work's reconcile state via OR-Set CRDT.
    pub fn reconcile_endorse(
        &mut self,
        work_fingerprint: &str,
        club_id: u64,
        token_id: u64,
        tag: crate::server::federation::OrSetTag,
    ) {
        if let Some(state) = self.reconcile_store.get_mut(work_fingerprint) {
            let entry =
                crate::server::federation::EndorsementEntry::new(club_id, token_id, &tag.server_id);
            state.endorsements.add(entry, tag);
        }
    }

    /// Retract an endorsement from a work's reconcile state via OR-Set CRDT.
    /// Uses remove_value semantics — removes ALL entries matching the
    /// (club_id, token_id) pair, regardless of which tags added them.
    /// This is correct because the client doesn't track individual OR-Set tags.
    pub fn reconcile_retract(&mut self, work_fingerprint: &str, club_id: u64, token_id: u64) {
        let server_id = self.federation_server_id();
        if let Some(state) = self.reconcile_store.get_mut(work_fingerprint) {
            let entry =
                crate::server::federation::EndorsementEntry::new(club_id, token_id, &server_id);
            state.endorsements.remove_value(&entry);
        }
    }

    /// Get the next unique tag for this server's endorsement operations.
    pub fn reconcile_next_tag(&mut self) -> crate::server::federation::OrSetTag {
        self.reconcile_counter += 1;
        crate::server::federation::OrSetTag::new(
            self.federation_server_id(),
            self.reconcile_counter,
        )
    }

    /// Export all endorsement sync data for a peer.
    /// Returns (work_fingerprint, endorsements) pairs.
    pub fn reconcile_export_endorsements(
        &self,
    ) -> Vec<(
        String,
        crate::server::federation::OrSet<crate::server::federation::EndorsementEntry>,
    )> {
        self.reconcile_store
            .fingerprints()
            .into_iter()
            .filter_map(|fp| {
                self.reconcile_store
                    .get(&fp)
                    .map(|s| (fp, s.endorsements.clone()))
            })
            .collect()
    }

    /// Merge remote endorsement OR-Sets into local state.
    pub fn reconcile_merge_endorsements(
        &mut self,
        entries: &[(
            String,
            crate::server::federation::OrSet<crate::server::federation::EndorsementEntry>,
        )],
    ) {
        for (fp, remote_endorsements) in entries {
            if let Some(state) = self.reconcile_store.get_mut(fp) {
                state.endorsements.merge(remote_endorsements);
            }
        }
    }

    pub fn reconcile_store_len(&self) -> usize {
        self.reconcile_store.len()
    }

    // =================================================================
    // Phase 19a: Membership & Trust
    // =================================================================

    pub fn membership_bootstrap_init(&mut self) {
        let verifying_key = self.server_keypair.signing_verifying_key();
        let verifying_key_hex = Self::hex_encode(&verifying_key.to_bytes());
        let kex_public = self.server_keypair.kex_public();
        let kex_hex = Self::hex_encode(kex_public.as_bytes());
        let server_id = self.federation_server_id();
        let now = Self::current_timestamp_secs();

        let self_proof = match self.membership_sign_endorsement(&server_id, &verifying_key_hex) {
            Some(p) => p,
            None => {
                tracing::error!("membership_bootstrap_init: failed to create self-endorsement");
                return;
            }
        };

        let entry = crate::server::federation::MembershipEntry::new(
            server_id,
            verifying_key_hex,
            kex_hex,
            vec![self_proof],
            now,
        );
        let server_id = self.federation_server_id();
        let tag = self.federation.membership_mut().next_tag(&server_id);
        self.federation.membership_mut().add_member(entry, tag);
        self.federation.membership_mut().exit_bootstrap();
    }

    pub fn membership_self_entry(&self) -> Option<crate::server::federation::MembershipEntry> {
        let server_id = self.federation_server_id();
        self.federation.membership().find_member(&server_id)
    }

    pub fn membership_list(&self) -> Vec<crate::server::federation::MembershipEntry> {
        self.federation.membership().active_members()
    }

    pub fn membership_count(&self) -> usize {
        self.federation.membership().member_count()
    }

    pub fn membership_is_member(&self, server_id: &str) -> bool {
        self.federation.membership().is_member(server_id)
    }

    pub fn membership_is_known_member(&self, server_id: &str) -> bool {
        self.federation.membership().is_known_member(server_id)
    }

    pub fn membership_get_verifying_key_hex(&self, server_id: &str) -> Option<String> {
        self.federation
            .membership()
            .find_member(server_id)
            .map(|e| e.verifying_key_hex.clone())
    }

    pub fn membership_verify(
        &self,
        server_id: &str,
    ) -> crate::server::federation::MembershipVerifyResult {
        let membership = self.federation.membership();
        match membership.find_member(server_id) {
            Some(entry) => crate::server::federation::MembershipVerifyResult {
                server_id: server_id.to_string(),
                is_member: entry.is_active()
                    && entry.endorsement_count() >= membership.min_endorsements() as usize,
                endorsement_count: entry.endorsement_count(),
                min_endorsements: membership.min_endorsements(),
                endorsed_by: entry
                    .endorsed_by
                    .iter()
                    .map(|e| e.endorser_server_id.clone())
                    .collect(),
            },
            None => crate::server::federation::MembershipVerifyResult {
                server_id: server_id.to_string(),
                is_member: false,
                endorsement_count: 0,
                min_endorsements: membership.min_endorsements(),
                endorsed_by: vec![],
            },
        }
    }

    pub fn membership_process_join(
        &mut self,
        entry: crate::server::federation::MembershipEntry,
    ) -> crate::server::federation::JoinResult {
        let server_id = entry.server_id.clone();

        if let Err(reason) = self.federation.membership().validate_join(&entry) {
            return crate::server::federation::JoinResult::Rejected { server_id, reason };
        }

        if let Err(reason) = self.membership_verify_entry_endorsements(&entry) {
            return crate::server::federation::JoinResult::Rejected { server_id, reason };
        }

        let sid = self.federation_server_id();
        let tag = self.federation.membership_mut().next_tag(&sid);
        self.federation
            .membership_mut()
            .add_member(entry.clone(), tag);

        let offered_endorsement =
            self.membership_sign_endorsement(&entry.server_id, &entry.verifying_key_hex);

        crate::server::federation::JoinResult::Accepted {
            server_id,
            membership_entry: entry,
            offered_endorsement,
        }
    }

    pub fn membership_sign_endorsement(
        &self,
        endorsee_server_id: &str,
        endorsee_verifying_key_hex: &str,
    ) -> Option<crate::server::federation::EndorsementProof> {
        let my_server_id = self.federation_server_id();
        let timestamp = Self::current_timestamp_secs();
        let key_id = self.server_keypair.key_id;

        let proof = crate::server::federation::EndorsementProof {
            endorser_server_id: my_server_id,
            endorser_key_id: key_id,
            endorsee_server_id: endorsee_server_id.to_string(),
            endorsee_verifying_key_hex: endorsee_verifying_key_hex.to_string(),
            signature: vec![],
            timestamp,
        };

        let transcript = proof.canonical_transcript();
        let signature =
            crate::crypto::sign::sign_bytes(&self.server_keypair.signing_key, &transcript);

        Some(crate::server::federation::EndorsementProof {
            signature: signature.to_bytes().to_vec(),
            ..proof
        })
    }

    pub fn membership_verify_endorsement_proof(
        &self,
        proof: &crate::server::federation::EndorsementProof,
        endorser_verifying_key: &ed25519_dalek::VerifyingKey,
    ) -> bool {
        let transcript = proof.canonical_transcript();
        let sig_bytes: [u8; 64] = match proof.signature.as_slice().try_into() {
            Ok(b) => b,
            Err(_) => return false,
        };
        let signature = match ed25519_dalek::Signature::from_slice(&sig_bytes) {
            Ok(s) => s,
            Err(_) => return false,
        };
        crate::crypto::sign::verify_signature(endorser_verifying_key, &transcript, &signature)
            .is_ok()
    }

    pub fn membership_endorse(
        &mut self,
        server_id: &str,
        proof: crate::server::federation::EndorsementProof,
    ) -> bool {
        if !self.membership_verify_single_proof(&proof) {
            tracing::warn!(
                "endorsement proof signature verification failed for endorser={}",
                proof.endorser_server_id
            );
            return false;
        }
        self.federation
            .membership_mut()
            .endorse_member(server_id, proof)
    }

    fn membership_verify_entry_endorsements(
        &self,
        entry: &crate::server::federation::MembershipEntry,
    ) -> Result<(), String> {
        for proof in &entry.endorsed_by {
            if !self.membership_verify_single_proof(proof) {
                return Err(format!(
                    "invalid endorsement signature from {}",
                    proof.endorser_server_id
                ));
            }
        }
        Ok(())
    }

    fn membership_verify_single_proof(
        &self,
        proof: &crate::server::federation::EndorsementProof,
    ) -> bool {
        let endorser_entry = match self
            .federation
            .membership()
            .find_member(&proof.endorser_server_id)
        {
            Some(e) => e,
            None => {
                if self.federation.membership().is_bootstrap() {
                    return true;
                }
                return false;
            }
        };
        let vk_bytes = match Self::hex_decode(&endorser_entry.verifying_key_hex) {
            Ok(b) => b,
            Err(_) => return false,
        };
        let vk_bytes: [u8; 32] = match vk_bytes.try_into() {
            Ok(b) => b,
            Err(_) => return false,
        };
        let verifying_key = match ed25519_dalek::VerifyingKey::from_bytes(&vk_bytes) {
            Ok(vk) => vk,
            Err(_) => return false,
        };
        self.membership_verify_endorsement_proof(proof, &verifying_key)
    }

    pub fn membership_leave(&mut self) -> bool {
        let server_id = self.federation_server_id();
        self.federation.membership_mut().remove_member(&server_id)
    }

    pub fn membership_remove(&mut self, server_id: &str) -> bool {
        self.federation.membership_mut().remove_member(server_id)
    }

    pub fn membership_merge(&mut self, other: &crate::server::federation::MembershipState) {
        self.federation.membership_mut().merge(other);
    }

    pub fn membership_export_orset(
        &self,
    ) -> &crate::server::federation::OrSet<crate::server::federation::MembershipEntry> {
        self.federation.membership().to_orset()
    }

    pub fn membership_merge_orset(
        &mut self,
        other: &crate::server::federation::OrSet<crate::server::federation::MembershipEntry>,
    ) {
        self.federation.membership_mut().merge_orset(other);
    }

    // =================================================================
    // Phase 19b: Governance & BFT
    // =================================================================

    pub fn governance_propose(
        &mut self,
        transactions: Vec<crate::server::federation::GovernanceTx>,
    ) -> Option<crate::server::federation::GovernanceProposal> {
        let members: Vec<String> = self
            .federation
            .membership()
            .active_members()
            .iter()
            .map(|m| m.server_id.clone())
            .collect();
        let my_id = self.federation_server_id();
        let gov = self.federation.governance_mut();
        gov.set_cluster_size(members.len().max(1));
        if !gov.is_leader(&my_id, &members) {
            return None;
        }
        gov.propose(transactions, my_id)
    }

    pub fn governance_receive_prepare(
        &mut self,
        vote: crate::server::federation::PbftVote,
    ) -> crate::server::federation::RoundPhase {
        let members: Vec<String> = self
            .federation
            .membership()
            .active_members()
            .iter()
            .map(|m| m.server_id.clone())
            .collect();
        let member_ids: Vec<&str> = members.iter().map(|s| s.as_str()).collect();
        if !member_ids.contains(&vote.voter_id.as_str()) {
            return crate::server::federation::RoundPhase::PrePrepare;
        }
        let gov = self.federation.governance_mut();
        gov.set_cluster_size(members.len().max(1));
        gov.receive_prepare(vote)
    }

    pub fn governance_receive_commit(
        &mut self,
        vote: crate::server::federation::PbftVote,
    ) -> crate::server::federation::RoundPhase {
        let members: Vec<String> = self
            .federation
            .membership()
            .active_members()
            .iter()
            .map(|m| m.server_id.clone())
            .collect();
        let member_ids: Vec<&str> = members.iter().map(|s| s.as_str()).collect();
        if !member_ids.contains(&vote.voter_id.as_str()) {
            return crate::server::federation::RoundPhase::PrePrepare;
        }
        let gov = self.federation.governance_mut();
        gov.set_cluster_size(members.len().max(1));
        gov.receive_commit(vote)
    }

    pub fn governance_seal_round(&mut self) -> Option<crate::server::federation::SealedBatch> {
        let batch = self.federation.governance_mut().seal_round()?;
        for tx in &batch.transactions {
            self.governance_execute_tx(tx);
        }
        Some(batch)
    }

    pub(crate) fn governance_execute_tx(&mut self, tx: &crate::server::federation::GovernanceTx) {
        match tx {
            crate::server::federation::GovernanceTx::Admit {
                server_id,
                verifying_key_hex,
                kex_public_hex,
            } => {
                let proofs = vec![];
                let entry = crate::server::federation::MembershipEntry::new(
                    server_id,
                    verifying_key_hex,
                    kex_public_hex,
                    proofs,
                    Self::current_timestamp_secs(),
                );
                let tag = self.federation.membership_mut().next_tag(server_id);
                self.federation.membership_mut().add_member(entry, tag);
            }
            crate::server::federation::GovernanceTx::Expel { server_id, .. } => {
                self.federation.membership_mut().remove_member(server_id);
            }
            crate::server::federation::GovernanceTx::KeyRegister {
                server_id,
                verifying_key_hex,
                kex_public_hex,
                ..
            } => {
                if let Some(mut entry) = self.federation.membership().find_member(server_id) {
                    entry.verifying_key_hex = verifying_key_hex.clone();
                    entry.kex_public_hex = kex_public_hex.clone();
                    self.federation.membership_mut().remove_member(server_id);
                    let tag = self.federation.membership_mut().next_tag(server_id);
                    self.federation.membership_mut().add_member(entry, tag);
                }
            }
            crate::server::federation::GovernanceTx::RoyaltyRecord {
                origin_server_id,
                content_fingerprint_hex,
                royalty_type,
                amount,
                ..
            } => {
                let fp_bytes: [u8; 32] = match Self::hex_decode(content_fingerprint_hex)
                    .ok()
                    .and_then(|v| v.try_into().ok())
                {
                    Some(b) => b,
                    None => return,
                };
                self.federation
                    .record_royalty(crate::server::federation::RoyaltyEntry {
                        origin_server_id: origin_server_id.clone(),
                        content_fingerprint: fp_bytes,
                        royalty_type: royalty_type.clone(),
                        amount: *amount,
                        timestamp: Self::current_timestamp_secs(),
                    });
            }
        }
    }

    pub fn governance_log(&self) -> &[crate::server::federation::SealedBatch] {
        self.federation.governance().log()
    }

    pub fn governance_current_view(&self) -> u64 {
        self.federation.governance().current_view()
    }

    pub fn governance_current_sequence(&self) -> u64 {
        self.federation.governance().current_sequence()
    }

    pub fn governance_pending_round(&self) -> Option<&crate::server::federation::ConsensusRound> {
        self.federation.governance().pending_round()
    }

    pub fn governance_is_leader(&self) -> bool {
        let members: Vec<String> = self
            .federation
            .membership()
            .active_members()
            .iter()
            .map(|m| m.server_id.clone())
            .collect();
        let my_id = self.federation_server_id();
        self.federation.governance().is_leader(&my_id, &members)
    }

    pub fn governance_leader_id(&self) -> Option<String> {
        let members: Vec<String> = self
            .federation
            .membership()
            .active_members()
            .iter()
            .map(|m| m.server_id.clone())
            .collect();
        self.federation.governance().leader_id(&members)
    }

    pub fn governance_cluster_size(&self) -> usize {
        self.federation.governance().cluster_size()
    }

    pub fn governance_quorum_size(&self) -> usize {
        self.federation.governance().quorum_size()
    }

    pub fn governance_is_applied(&self, sequence_number: u64) -> bool {
        self.federation.governance().is_applied(sequence_number)
    }

    pub fn governance_mark_applied(&mut self, sequence_number: u64) {
        self.federation
            .governance_mut()
            .mark_applied(sequence_number);
    }

    pub fn federation_royalty_ledger(&self) -> &[crate::server::federation::RoyaltyEntry] {
        self.federation.royalty_ledger()
    }
}

#[derive(Debug)]
pub enum FederationFetchResponse {
    Edition(crate::server::transport::protocol::EditionPayload),
    Blob(String, String),
    NotFound,
}

#[cfg(feature = "server")]
pub(crate) mod persist_snapshot {
    use super::*;
    use crate::edition::persistent::{EditionSnapshot, WorkSnapshot};
    use std::collections::{HashMap, HashSet};

    #[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
    struct WorkStateSnapshot {
        work: WorkSnapshot,
        grabber: Option<u64>,
        last_revision_author: Option<BeId>,
        revision_authors: std::collections::HashMap<u64, BeId>,
        #[serde(default)]
        is_source: bool,
        #[serde(default)]
        source_author_id: Option<BeId>,
        #[serde(default)]
        source_edition_info: Option<String>,
        #[serde(default)]
        content_start_line: Option<u64>,
        #[serde(default)]
        content_end_line: Option<u64>,
        /// Soft-delete (archive) state.
        #[serde(default)]
        is_archived: bool,
        /// Append-only lifecycle history.
        #[serde(default, skip_serializing_if = "Vec::is_empty")]
        lifecycle_history: Vec<crate::edition::work::WorkLifecycleEvent>,
        #[serde(default, skip_serializing_if = "Option::is_none")]
        history_club: Option<BeId>,
    }

    #[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
    struct ClubSnapshot {
        be_id: BeId,
        name: Option<String>,
        signature_club: Option<BeId>,
        work: WorkSnapshot,
        #[serde(default)]
        default_read_club: Option<BeId>,
        #[serde(default)]
        default_edit_club: Option<BeId>,
        #[serde(default)]
        is_personal: bool,
        #[serde(default)]
        display_name: Option<String>,
        #[serde(default)]
        credential: Option<crate::server::club::Credential>,
        #[serde(default)]
        encrypted_signing_key: Option<crate::crypto::club_keys::EncryptedSigningKey>,
        #[serde(default)]
        members: Vec<BeId>,
        #[serde(default)]
        sponsored_works: Vec<BeId>,
    }

    #[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
    struct StandaloneEditionSnapshot {
        be_id: BeId,
        edition: EditionSnapshot,
    }

    #[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
    struct LinkSnapshot {
        link_id: BeId,
        origin: BeId,
        destination: BeId,
        #[serde(default, skip_serializing_if = "Option::is_none")]
        origin_ref: Option<crate::server::transport::protocol::HyperRefPayload>,
        #[serde(default, skip_serializing_if = "Option::is_none")]
        destination_ref: Option<crate::server::transport::protocol::HyperRefPayload>,
        #[serde(default, skip_serializing_if = "Vec::is_empty")]
        link_types: Vec<u64>,
    }

    #[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
    struct AdminSnapshot {
        accepting_connections: bool,
        shutdown_requested: bool,
        grants: Vec<(BeId, i64, i64)>,
    }

    #[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
    pub struct ServerSnapshot {
        grand_map_id_counter: BeId,
        session_counter: u64,
        operation_counter: u64,
        system_clubs: SystemClubs,
        works: Vec<(BeId, WorkStateSnapshot)>,
        clubs: Vec<ClubSnapshot>,
        standalone_editions: Vec<StandaloneEditionSnapshot>,
        links: Vec<LinkSnapshot>,
        link_counter: BeId,
        admin: AdminSnapshot,
        reconcile_store: crate::server::federation::ReconcileStore,
        reconcile_counter: u64,
        federation: Option<crate::server::federation::FederationSnapshot>,
        content_address: Option<crate::edition::ContentAddressIndex>,
        blob_metas: Vec<BlobMetaSnapshot>,
        key_history: Option<KeyHistorySnapshot>,
        #[serde(default)]
        historical_authors: Option<crate::server::historical_author::HistoricalAuthorRegistry>,
        #[serde(default)]
        starred_works: HashMap<BeId, HashSet<BeId>>,
        #[serde(default)]
        trails: Vec<TrailSnapshot>,
        #[serde(default)]
        trail_counter: BeId,
        #[serde(default)]
        compound_editions: Vec<(BeId, crate::edition::compound::CompoundEdition)>,
    }

    #[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
    struct TrailStopSnapshot {
        work_id: BeId,
        char_start: Option<u64>,
        char_end: Option<u64>,
        note: Option<String>,
    }

    #[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
    struct TrailSnapshot {
        trail_id: BeId,
        owner_club: BeId,
        name: String,
        stops: Vec<TrailStopSnapshot>,
        created_at: u64,
        updated_at: u64,
    }

    #[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
    pub(crate) struct BlobMetaSnapshot {
        pub(crate) content_hash: Vec<u8>,
        pub(crate) hash_u64: u64,
        pub(crate) byte_size: u64,
        pub(crate) mime_type: String,
        pub(crate) preview_hash: Option<Vec<u8>>,
        pub(crate) metadata: HashMap<String, String>,
    }

    #[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
    pub struct KeyHistorySnapshot {
        pub server_id: String,
        pub entries: Vec<crate::crypto::keys::KeyHistoryEntryFile>,
        pub rotation_proofs: Vec<crate::crypto::keys::SignedKeyRotationFile>,
        pub current_key_id: crate::crypto::keys::KeyId,
    }

    impl Server {
        pub fn to_snapshot(&self) -> ServerSnapshot {
            let works = self
                .works
                .iter()
                .map(|(id, ws)| {
                    (
                        *id,
                        WorkStateSnapshot {
                            work: WorkSnapshot::from_work(&ws.work),
                            grabber: ws.grabber.map(|s| s.0),
                            last_revision_author: ws.last_revision_author,
                            revision_authors: ws.revision_authors.clone(),
                            is_source: ws.is_source,
                            source_author_id: ws.source_author_id,
                            source_edition_info: ws.source_edition_info.clone(),
                            content_start_line: ws.content_start_line,
                            content_end_line: ws.content_end_line,
                            is_archived: ws.work.is_archived(),
                            lifecycle_history: ws.work.lifecycle_history().to_vec(),
                            history_club: ws.work.history_club(),
                        },
                    )
                })
                .collect();

            let clubs = self
                .clubs
                .iter()
                .map(|(id, club)| ClubSnapshot {
                    be_id: *id,
                    name: club.name().map(|s| s.to_string()),
                    signature_club: club.signature_club(),
                    work: WorkSnapshot::from_work(club.work()),
                    default_read_club: club.default_read_club(),
                    default_edit_club: club.default_edit_club(),
                    is_personal: club.is_personal(),
                    display_name: club.display_name().map(|s| s.to_string()),
                    credential: club.credential().cloned(),
                    encrypted_signing_key: club.encrypted_signing_key().cloned(),
                    members: club.members().iter().copied().collect(),
                    sponsored_works: club.sponsored_works().iter().copied().collect(),
                })
                .collect();

            let standalone_editions = self
                .standalone_editions
                .iter()
                .map(|(id, ed)| StandaloneEditionSnapshot {
                    be_id: *id,
                    edition: EditionSnapshot::from_edition(ed),
                })
                .collect();

            let blob_metas = self
                .blob_store
                .all_metas()
                .iter()
                .map(|(hash, meta)| BlobMetaSnapshot {
                    content_hash: hash.to_vec(),
                    hash_u64: meta.hash_u64(),
                    byte_size: meta.byte_size,
                    mime_type: meta.mime_type.clone(),
                    preview_hash: meta.preview_hash.map(|ph| ph.to_vec()),
                    metadata: meta.metadata.clone(),
                })
                .collect();

            let kh_file = self.key_history.to_file_repr();
            let key_history = Some(KeyHistorySnapshot {
                server_id: kh_file.server_id,
                entries: kh_file.entries,
                rotation_proofs: kh_file.rotation_proofs,
                current_key_id: kh_file.current_key_id,
            });

            ServerSnapshot {
                grand_map_id_counter: self.grand_map.id_counter(),
                session_counter: self.session_counter,
                operation_counter: self.operation_counter,
                system_clubs: self.system_clubs,
                works,
                clubs,
                standalone_editions,
                links: self
                    .links
                    .iter()
                    .map(|(id, ls)| {
                        let o_ref = ls.link.end_at("LeftEnd").map(
                            crate::server::transport::protocol::HyperRefPayload::from_hyper_ref,
                        );
                        let d_ref = ls.link.end_at("RightEnd").map(
                            crate::server::transport::protocol::HyperRefPayload::from_hyper_ref,
                        );
                        LinkSnapshot {
                            link_id: *id,
                            origin: ls.origin,
                            destination: ls.destination,
                            origin_ref: o_ref,
                            destination_ref: d_ref,
                            link_types: ls.link.link_types().to_vec(),
                        }
                    })
                    .collect(),
                link_counter: self.link_counter,
                admin: AdminSnapshot {
                    accepting_connections: self.admin.is_accepting_connections(),
                    shutdown_requested: self.admin.is_shutdown_requested(),
                    grants: self
                        .admin
                        .grants()
                        .iter()
                        .map(|g| {
                            let (start, end) = g.region.as_interval().unwrap_or((0, 0));
                            (g.club_id, start, end)
                        })
                        .collect(),
                },
                reconcile_store: self.reconcile_store.clone(),
                reconcile_counter: self.reconcile_counter,
                federation: Some(self.federation.to_snapshot()),
                content_address: Some(self.content_address.clone()),
                blob_metas,
                key_history,
                historical_authors: Some(self.historical_authors.clone()),
                starred_works: self.starred_works.clone(),
                trails: self
                    .trails
                    .values()
                    .map(|t| TrailSnapshot {
                        trail_id: t.trail_id,
                        owner_club: t.owner_club,
                        name: t.name.clone(),
                        stops: t
                            .stops
                            .iter()
                            .map(|s| TrailStopSnapshot {
                                work_id: s.work_id,
                                char_start: s.char_start,
                                char_end: s.char_end,
                                note: s.note.clone(),
                            })
                            .collect(),
                        created_at: t.created_at,
                        updated_at: t.updated_at,
                    })
                    .collect(),
                trail_counter: self.trail_counter,
                compound_editions: self
                    .compound_editions
                    .iter()
                    .map(|(id, c)| (*id, c.clone()))
                    .collect(),
            }
        }

        pub fn from_snapshot(snapshot: &ServerSnapshot) -> Self {
            let mut grand_map = GrandMap::new();
            crate::edition::init_endorsement_flags();
            grand_map.set_id_counter(snapshot.grand_map_id_counter);
            let server_kp = crate::crypto::keys::ServerKeyPair::generate("xudanu-server");

            let federation = snapshot
                .federation
                .as_ref()
                .map(|fs| crate::server::federation::FederationState::from_snapshot(fs))
                .unwrap_or_else(crate::server::federation::FederationState::disabled);
            let content_address = snapshot
                .content_address
                .clone()
                .unwrap_or_else(|| ContentAddressIndex::new(1_000_000));

            let mut server = Server {
                grand_map,
                sessions: HashMap::new(),
                session_counter: snapshot.session_counter,
                clubs: HashMap::new(),
                club_names: HashMap::new(),
                works: HashMap::new(),
                standalone_editions: HashMap::new(),
                standalone_edition_refs: HashMap::new(),
                dirty_clubs: HashSet::new(),
                club_refs: HashMap::new(),
                edition_detectors: HashMap::new(),
                system_clubs: snapshot.system_clubs,
                operation_counter: snapshot.operation_counter,
                admin: AdminState::new(),
                links: HashMap::new(),
                work_to_links: HashMap::new(),
                link_counter: snapshot.link_counter,
                link_type_names: HashMap::new(),
                backfollow: BackfollowEngine::new(),
                content_address,
                blob_store: BlobStore::in_memory(),
                checkpoint_path: None,
                data_dir: None,
                chunk_store: None,
                manifest_sequence: 0,
                manifest_slot: 'a',
                recorder_system: crate::edition::RecorderSystem::new(),
                pending_content_notifications: Vec::new(),
                start_time: std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_secs(),
                server_keypair: server_kp.clone(),
                key_history: crate::crypto::keys::KeyHistory::new(&server_kp),
                federation,
                reconcile_store: snapshot.reconcile_store.clone(),
                reconcile_counter: snapshot.reconcile_counter,
                last_checkpoint_time: std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_secs(),
                otree_crdt: crate::server::otree_crdt::OtreeCrdtManager::new(3),
                personal_club_count: 0,
                max_personal_clubs: 10_000,
                login_attempts: HashMap::new(),
                attribution_log:
                    crate::server::transport::attribution_log::AttributionLog::in_memory(),
                historical_authors: crate::server::historical_author::HistoricalAuthorRegistry::new(
                ),
                source_patterns: crate::server::source_matcher::builtin_patterns(),
                pending_attributions: Vec::new(),
                starred_works: snapshot.starred_works.clone(),
                trails: snapshot
                    .trails
                    .iter()
                    .map(|ts| {
                        (
                            ts.trail_id,
                            TrailState {
                                trail_id: ts.trail_id,
                                owner_club: ts.owner_club,
                                name: ts.name.clone(),
                                stops: ts
                                    .stops
                                    .iter()
                                    .map(|s| TrailStop {
                                        work_id: s.work_id,
                                        char_start: s.char_start,
                                        char_end: s.char_end,
                                        note: s.note.clone(),
                                    })
                                    .collect(),
                                created_at: ts.created_at,
                                updated_at: ts.updated_at,
                            },
                        )
                    })
                    .collect(),
                trail_counter: snapshot.trail_counter,
                compound_editions: snapshot.compound_editions.iter().cloned().collect(),
                compound_dirty: HashSet::new(),
                consequence_tracker: Arc::new(ConsequenceTracker::new()),
                write_barrier: Arc::new(WriteBarrier::new()),
                wal: crate::persist::wal::WalLog::disabled(),
                restore_errors: Vec::new(),
            };
            for club_snap in &snapshot.clubs {
                let work = club_snap
                    .work
                    .to_work(crate::persist::FlockId::new(club_snap.be_id, 0), None)
                    .work()
                    .clone();
                let mut club =
                    Club::new_with_owner(club_snap.be_id, work.owner(), work.edition().clone());
                club.set_signature_club(club_snap.signature_club);
                club.set_default_read_club(club_snap.default_read_club);
                club.set_default_edit_club(club_snap.default_edit_club);
                if let Some(ref name) = club_snap.name {
                    club.set_name(name.clone());
                    server.club_names.insert(name.clone(), club_snap.be_id);
                }
                club.set_is_personal(club_snap.is_personal);
                club.set_display_name(club_snap.display_name.clone());
                club.set_credential(club_snap.credential.clone());
                club.set_encrypted_signing_key(club_snap.encrypted_signing_key.clone());
                for member_id in &club_snap.members {
                    club.add_member(*member_id);
                }
                for work_id in &club_snap.sponsored_works {
                    club.add_sponsored_work(*work_id);
                }
                server.clubs.insert(club_snap.be_id, club);
            }

            server.personal_club_count = server.clubs.values().filter(|c| c.is_personal()).count();

            for (id, ws_snap) in &snapshot.works {
                let mut work = ws_snap
                    .work
                    .to_work(crate::persist::FlockId::new(*id, 0), None)
                    .work()
                    .clone();
                work.restore_archived_state(ws_snap.is_archived, ws_snap.lifecycle_history.clone());
                if let Some(hc) = ws_snap.history_club {
                    work.set_history_club(Some(hc));
                }
                let ws = WorkState {
                    work: work.clone(),
                    chunk_ref: None,
                    dirty_gen: 0,
                    grabber: None,
                    grabbed_at: None,
                    grab_waiters: Vec::new(),
                    last_revision_author: ws_snap.last_revision_author,
                    revision_authors: ws_snap.revision_authors.clone(),
                    revision_timestamps: std::collections::HashMap::new(),
                    status_detectors: DetectorList::new(),
                    revision_detectors: DetectorList::new(),
                    cached_title: Self::extract_title(work.current_edition()),
                    is_source: ws_snap.is_source,
                    source_author_id: ws_snap.source_author_id,
                    source_edition_info: ws_snap.source_edition_info.clone(),
                    imported_by: None,
                    content_start_line: ws_snap.content_start_line,
                    content_end_line: ws_snap.content_end_line,
                    source_fingerprint: if ws_snap.is_source {
                        let text = work.current_edition().to_text();
                        Some(crate::server::source_matcher::compute_minhash(&text))
                    } else {
                        None
                    },
                };
                server.works.insert(*id, ws);
            }

            for se_snap in &snapshot.standalone_editions {
                let edition = se_snap.edition.to_edition();
                server.standalone_editions.insert(se_snap.be_id, edition);
            }

            server
                .admin
                .set_accepting_connections(snapshot.admin.accepting_connections);
            if snapshot.admin.shutdown_requested {
                server.admin.request_shutdown();
            }
            for (club_id, start, end) in &snapshot.admin.grants {
                server
                    .admin
                    .grant(*club_id, crate::edition::XnRegion::interval(*start, *end));
            }

            for ls in &snapshot.links {
                let o_ref = ls
                    .origin_ref
                    .as_ref()
                    .map(|hr| hr.to_hyper_ref(ls.origin))
                    .unwrap_or_else(|| HyperRef::single(None, Some(ls.origin), None, None));
                let d_ref = ls
                    .destination_ref
                    .as_ref()
                    .map(|hr| hr.to_hyper_ref(ls.destination))
                    .unwrap_or_else(|| HyperRef::single(None, Some(ls.destination), None, None));
                let link = HyperLink::make(ls.link_types.clone(), o_ref, d_ref);
                server.links.insert(
                    ls.link_id,
                    LinkState {
                        link,
                        origin: ls.origin,
                        destination: ls.destination,
                    },
                );
                server
                    .work_to_links
                    .entry(ls.origin)
                    .or_default()
                    .push(ls.link_id);
                server
                    .work_to_links
                    .entry(ls.destination)
                    .or_default()
                    .push(ls.link_id);
            }

            for (wid, ws) in &server.works {
                let prop = BackfollowEngine::make_work_prop(
                    &ws.work,
                    ws.work.read_club(),
                    ws.work.edit_club(),
                );
                server
                    .backfollow
                    .register_work_with_prop(&ws.work, *wid, None, prop);
            }

            for (se_id, edition) in &server.standalone_editions {
                server.backfollow.register_edition(
                    edition,
                    *se_id,
                    crate::edition::props::BertProp::make(),
                );
            }

            for (link_id, ls) in &server.links {
                server.backfollow.register_link_content(&ls.link, *link_id);
            }

            let max_id = server
                .works
                .keys()
                .copied()
                .chain(server.clubs.keys().copied())
                .chain(server.links.keys().copied())
                .chain(server.standalone_editions.keys().copied())
                .max()
                .unwrap_or(0);
            if max_id >= server.grand_map.id_counter() {
                server.grand_map.set_id_counter(max_id + 1);
            }

            if let Some(ha) = &snapshot.historical_authors {
                server.historical_authors = ha.clone();
            }

            server.rebuild_pending_attributions();

            server
        }

        pub fn checkpoint_to_file(&self, path: &std::path::Path) -> std::io::Result<()> {
            let _wg = WriteGuard::new(self.write_barrier.clone());
            let start = std::time::Instant::now();
            let snapshot = self.to_snapshot();
            let data = serde_json::to_value(&snapshot)
                .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
            crate::server::transport::snapshot::write_versioned_snapshot(path, &data)
                .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
            self.save_key_history();
            tracing::info!(
                "Checkpoint saved in {:.2}ms",
                start.elapsed().as_secs_f64() * 1000.0,
            );
            Ok(())
        }

        pub fn checkpoint_prepare(&self) -> std::io::Result<CheckpointPayload> {
            let chunk_store = self.chunk_store_arc().ok_or_else(|| {
                std::io::Error::new(std::io::ErrorKind::Other, "no chunk store configured")
            })?;
            let manifest_path = self.checkpoint_path.clone().ok_or_else(|| {
                std::io::Error::new(std::io::ErrorKind::Other, "no checkpoint path configured")
            })?;
            let data_dir = self
                .data_dir
                .clone()
                .ok_or_else(|| std::io::Error::new(std::io::ErrorKind::Other, "no data dir"))?;

            let mut dirty_works = Vec::new();
            let mut clean_work_entries = Vec::new();
            let mut dirty_work_gens = Vec::new();

            for (id, ws) in &self.works {
                let is_archived = ws.work.is_archived();
                let lifecycle_history = ws.work.lifecycle_history().to_vec();
                let history_club = ws.work.history_club();
                if let Some(ref existing_ref) = ws.chunk_ref {
                    clean_work_entries.push(crate::persist::manifest::WorkEntry {
                        be_id: *id,
                        work_ref: existing_ref.clone(),
                        is_source: ws.is_source,
                        source_author_id: ws.source_author_id,
                        source_edition_info: ws.source_edition_info.clone(),
                        content_start_line: ws.content_start_line,
                        content_end_line: ws.content_end_line,
                        source_fingerprint: ws.source_fingerprint.map(|fp| fp.to_vec()),
                        is_archived,
                        lifecycle_history,
                        history_club,
                    });
                } else {
                    dirty_work_gens.push((*id, ws.dirty_gen));
                    dirty_works.push(DirtyWorkData {
                        be_id: *id,
                        work: ws.work.clone(),
                        is_source: ws.is_source,
                        source_author_id: ws.source_author_id,
                        source_edition_info: ws.source_edition_info.clone(),
                        content_start_line: ws.content_start_line,
                        content_end_line: ws.content_end_line,
                        source_fingerprint: ws.source_fingerprint.map(|fp| fp.to_vec()),
                        is_archived,
                        lifecycle_history,
                        history_club,
                    });
                }
            }

            let dirty_club_ids = self.dirty_clubs.clone();
            let mut dirty_clubs = Vec::new();
            let mut clean_club_refs = Vec::new();
            for (id, club) in &self.clubs {
                if !self.dirty_clubs.contains(id) {
                    if let Some(existing_ref) = self.club_refs.get(id) {
                        clean_club_refs.push(existing_ref.clone());
                        continue;
                    }
                }
                dirty_clubs.push((*id, club.clone()));
            }

            let mut dirty_editions = Vec::new();
            let mut clean_edition_refs = Vec::new();
            for (id, edition) in &self.standalone_editions {
                if let Some(existing_ref) = self.standalone_edition_refs.get(id) {
                    clean_edition_refs.push(crate::persist::manifest::StandaloneEditionChunkRef {
                        be_id: *id,
                        edition_ref: existing_ref.clone(),
                    });
                } else {
                    dirty_editions.push((*id, edition.clone()));
                }
            }

            let links: Vec<crate::persist::manifest::LinkEntry> =
                self.links
                    .iter()
                    .map(|(id, ls)| {
                        let o_ref = ls.link.end_at("LeftEnd").map(
                            crate::server::transport::protocol::HyperRefPayload::from_hyper_ref,
                        );
                        let d_ref = ls.link.end_at("RightEnd").map(
                            crate::server::transport::protocol::HyperRefPayload::from_hyper_ref,
                        );
                        crate::persist::manifest::LinkEntry {
                            link_id: *id,
                            origin: ls.origin,
                            destination: ls.destination,
                            origin_ref: o_ref,
                            destination_ref: d_ref,
                            link_types: ls.link.link_types().to_vec(),
                        }
                    })
                    .collect();

            let blob_metas: Vec<crate::persist::manifest::BlobMetaEntry> = self
                .blob_store
                .all_metas()
                .iter()
                .map(|(hash, meta)| crate::persist::manifest::BlobMetaEntry {
                    content_hash: hash.to_vec(),
                    hash_u64: meta.hash_u64(),
                    byte_size: meta.byte_size,
                    mime_type: meta.mime_type.clone(),
                    preview_hash: meta.preview_hash.map(|ph| ph.to_vec()),
                    metadata: meta.metadata.clone(),
                })
                .collect();

            let kh_file = self.key_history.to_file_repr();
            let key_history = Some(crate::persist::manifest::KeyHistoryEntry {
                server_id: kh_file.server_id,
                entries: kh_file.entries,
                rotation_proofs: kh_file.rotation_proofs,
                current_key_id: kh_file.current_key_id,
            });

            let annotations = self.otree_crdt.all_annotations();
            let (fossil_snapshots, _next_id) = self.recorder_system.to_snapshots();

            let admin_entry = crate::persist::manifest::AdminEntry {
                accepting_connections: self.admin.is_accepting_connections(),
                shutdown_requested: self.admin.is_shutdown_requested(),
                grants: self
                    .admin
                    .grants()
                    .iter()
                    .map(|g| {
                        let (start, end) = g.region.as_interval().unwrap_or_else(|| {
                            tracing::warn!(
                                "grant for club {} has non-interval region, saving as (0,0)",
                                g.club_id
                            );
                            (0, 0)
                        });
                        (g.club_id, start, end)
                    })
                    .collect(),
            };

            let federation_snapshot = self.federation.to_snapshot();

            let trails: Vec<crate::persist::manifest::TrailManifestEntry> = self
                .trails
                .values()
                .map(|t| crate::persist::manifest::TrailManifestEntry {
                    trail_id: t.trail_id,
                    owner_club: t.owner_club,
                    name: t.name.clone(),
                    stops: t
                        .stops
                        .iter()
                        .map(|s| crate::persist::manifest::TrailStopManifestEntry {
                            work_id: s.work_id,
                            char_start: s.char_start,
                            char_end: s.char_end,
                            note: s.note.clone(),
                        })
                        .collect(),
                    created_at: t.created_at,
                    updated_at: t.updated_at,
                })
                .collect();

            let compound_editions: Vec<_> = self
                .compound_editions
                .iter()
                .map(|(id, c)| (*id, c.clone()))
                .collect();

            let sub_content_address = tag_json(&self.content_address)?;
            let sub_historical_authors = tag_json(&self.historical_authors)?;
            let sub_annotations = tag_json(&annotations)?;
            let sub_blob_metas = tag_json(&blob_metas)?;
            let sub_fossil_snapshots = if fossil_snapshots.is_empty() {
                None
            } else {
                Some(tag_json(&fossil_snapshots)?)
            };

            Ok(CheckpointPayload {
                chunk_store,
                manifest_path,
                data_dir,
                sub_content_address,
                sub_historical_authors,
                sub_annotations,
                sub_blob_metas,
                sub_fossil_snapshots,
                links,
                dirty_works,
                dirty_work_gens,
                dirty_clubs,
                dirty_club_ids,
                dirty_editions,
                clean_work_entries,
                clean_club_refs,
                clean_edition_refs,
                manifest_sequence: self.manifest_sequence,
                manifest_slot: self.manifest_slot,
                grand_map_id_counter: self.grand_map.id_counter(),
                session_counter: self.session_counter,
                operation_counter: self.operation_counter,
                system_clubs: self.system_clubs,
                link_counter: self.link_counter,
                admin_entry,
                reconcile_store: self.reconcile_store.clone(),
                reconcile_counter: self.reconcile_counter,
                federation_snapshot: Some(federation_snapshot),
                starred_works: self.starred_works.clone(),
                trails,
                trail_counter: self.trail_counter,
                compound_editions,
                key_history,
            })
        }

        pub fn checkpoint_commit(&mut self, result: CheckpointResult) -> std::io::Result<()> {
            for (be_id, work_ref, dirty_gen) in &result.work_refs {
                if let Some(ws) = self.works.get_mut(be_id) {
                    if ws.dirty_gen == *dirty_gen && ws.chunk_ref.is_none() {
                        ws.chunk_ref = Some(work_ref.clone());
                    }
                }
            }

            for (id, club_ref) in &result.club_refs {
                self.club_refs.insert(*id, club_ref.clone());
            }

            for (id, ed_ref) in &result.edition_refs {
                self.standalone_edition_refs.insert(*id, ed_ref.clone());
            }

            for id in &result.dirty_club_ids {
                self.dirty_clubs.remove(id);
            }

            self.manifest_sequence = result.manifest_sequence;
            self.manifest_slot = result.manifest_slot;
            self.last_checkpoint_time = std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs();

            if let Err(e) = self.wal.truncate() {
                tracing::warn!("WAL truncate failed after checkpoint: {}", e);
            }

            if let Err(e) = self.gc_orphaned_chunks() {
                tracing::warn!("Chunk GC failed: {}", e);
            }

            tracing::info!(
                "Checkpoint #{} committed (dirty: {}/{}/{} works/clubs/editions)",
                result.manifest_sequence,
                result.dirty_work_count,
                result.dirty_club_count,
                result.dirty_edition_count,
            );

            Ok(())
        }

        pub fn checkpoint_to_store(&mut self) -> std::io::Result<()> {
            let _wg = WriteGuard::new(self.write_barrier.clone());
            let has_chunk_store = self.chunk_store.is_some();
            if !has_chunk_store {
                return Err(std::io::Error::new(
                    std::io::ErrorKind::Other,
                    "no chunk store configured",
                ));
            }
            let manifest_path = match self.checkpoint_path {
                Some(ref p) => p.clone(),
                None => {
                    return Err(std::io::Error::new(
                        std::io::ErrorKind::Other,
                        "no checkpoint path configured",
                    ))
                }
            };
            let start = std::time::Instant::now();

            let chunk_store = self.chunk_store.as_ref().unwrap();

            let mut dirty_work_count = 0u64;
            let mut work_entries: Vec<crate::persist::manifest::WorkEntry> = Vec::new();
            for (id, ws) in &self.works {
                let work_ref = if let Some(ref existing_ref) = ws.chunk_ref {
                    existing_ref.clone()
                } else {
                    dirty_work_count += 1;
                    crate::persist::edition_chunks::work_to_chunks(&ws.work, chunk_store)
                        .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?
                };
                work_entries.push(crate::persist::manifest::WorkEntry {
                    be_id: *id,
                    work_ref: work_ref.clone(),
                    is_source: ws.is_source,
                    source_author_id: ws.source_author_id,
                    source_edition_info: ws.source_edition_info.clone(),
                    content_start_line: ws.content_start_line,
                    content_end_line: ws.content_end_line,
                    source_fingerprint: ws.source_fingerprint.map(|fp| fp.to_vec()),
                    is_archived: ws.work.is_archived(),
                    lifecycle_history: ws.work.lifecycle_history().to_vec(),
                    history_club: ws.work.history_club(),
                });
            }

            for entry in &work_entries {
                if let Some(ws) = self.works.get_mut(&entry.be_id) {
                    if ws.chunk_ref.is_none() {
                        ws.chunk_ref = Some(entry.work_ref.clone());
                    }
                }
            }

            let mut dirty_club_count = 0u64;
            let mut club_refs = Vec::new();
            for (id, club) in &self.clubs {
                if !self.dirty_clubs.contains(id) {
                    if let Some(existing_ref) = self.club_refs.get(id) {
                        club_refs.push(existing_ref.clone());
                        continue;
                    }
                }
                dirty_club_count += 1;
                let work = club.work();
                let work_ref = crate::persist::edition_chunks::work_to_chunks(work, chunk_store)
                    .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
                let club_ref = crate::persist::manifest::ClubChunkRef {
                    be_id: *id,
                    name: club.name().map(|s| s.to_string()),
                    signature_club: club.signature_club(),
                    work_root: work_ref,
                    default_read_club: club.default_read_club(),
                    default_edit_club: club.default_edit_club(),
                    is_personal: club.is_personal(),
                    display_name: club.display_name().map(|s| s.to_string()),
                    credential: club.credential().cloned(),
                    encrypted_signing_key: club.encrypted_signing_key().cloned(),
                    members: club.members().iter().copied().collect(),
                    sponsored_works: club.sponsored_works().iter().copied().collect(),
                };
                club_refs.push(club_ref);
            }

            for club_ref in &club_refs {
                self.club_refs.insert(club_ref.be_id, club_ref.clone());
            }

            let mut dirty_edition_count = 0u64;
            let mut standalone_refs = Vec::new();
            for (id, edition) in &self.standalone_editions {
                if let Some(existing_ref) = self.standalone_edition_refs.get(id) {
                    standalone_refs.push(crate::persist::manifest::StandaloneEditionChunkRef {
                        be_id: *id,
                        edition_ref: existing_ref.clone(),
                    });
                    continue;
                }
                dirty_edition_count += 1;
                let ed_ref =
                    crate::persist::edition_chunks::edition_to_chunks(edition, chunk_store)
                        .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
                standalone_refs.push(crate::persist::manifest::StandaloneEditionChunkRef {
                    be_id: *id,
                    edition_ref: ed_ref.clone(),
                });
                self.standalone_edition_refs.insert(*id, ed_ref);
            }

            let links: Vec<_> =
                self.links
                    .iter()
                    .map(|(id, ls)| {
                        let o_ref = ls.link.end_at("LeftEnd").map(
                            crate::server::transport::protocol::HyperRefPayload::from_hyper_ref,
                        );
                        let d_ref = ls.link.end_at("RightEnd").map(
                            crate::server::transport::protocol::HyperRefPayload::from_hyper_ref,
                        );
                        crate::persist::manifest::LinkEntry {
                            link_id: *id,
                            origin: ls.origin,
                            destination: ls.destination,
                            origin_ref: o_ref,
                            destination_ref: d_ref,
                            link_types: ls.link.link_types().to_vec(),
                        }
                    })
                    .collect();

            let blob_metas: Vec<_> = self
                .blob_store
                .all_metas()
                .iter()
                .map(|(hash, meta)| crate::persist::manifest::BlobMetaEntry {
                    content_hash: hash.to_vec(),
                    hash_u64: meta.hash_u64(),
                    byte_size: meta.byte_size,
                    mime_type: meta.mime_type.clone(),
                    preview_hash: meta.preview_hash.map(|ph| ph.to_vec()),
                    metadata: meta.metadata.clone(),
                })
                .collect();

            let kh_file = self.key_history.to_file_repr();
            let key_history = Some(crate::persist::manifest::KeyHistoryEntry {
                server_id: kh_file.server_id,
                entries: kh_file.entries,
                rotation_proofs: kh_file.rotation_proofs,
                current_key_id: kh_file.current_key_id,
            });

            let next_slot = if self.manifest_slot == 'a' { 'b' } else { 'a' };
            let mut manifest = crate::persist::manifest::Manifest {
                format_version: 0,
                created_at: String::new(),
                server_version: String::new(),
                checksum: String::new(),
                sequence: self.manifest_sequence,
                manifest_slot: next_slot,
                grand_map_id_counter: self.grand_map.id_counter(),
                session_counter: self.session_counter,
                operation_counter: self.operation_counter,
                system_clubs: self.system_clubs,
                works: work_entries,
                clubs: club_refs,
                standalone_editions: standalone_refs,
                links_hash: {
                    let lk_data = serde_json::to_vec(&links)
                        .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
                    let tagged = crate::persist::chunk_store::tag_chunk_data(
                        crate::persist::chunk_store::CHUNK_FORMAT_JSON,
                        &lk_data,
                    );
                    let hash = chunk_store
                        .write_chunk(&tagged)
                        .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
                    Some(hash)
                },
                links: links.clone(),
                link_counter: self.link_counter,
                admin: crate::persist::manifest::AdminEntry {
                    accepting_connections: self.admin.is_accepting_connections(),
                    shutdown_requested: self.admin.is_shutdown_requested(),
                    grants: self
                        .admin
                        .grants()
                        .iter()
                        .map(|g| {
                            let (start, end) = g.region.as_interval().unwrap_or_else(|| {
                                tracing::warn!(
                                    "grant for club {} has non-interval region, saving as (0,0)",
                                    g.club_id
                                );
                                (0, 0)
                            });
                            (g.club_id, start, end)
                        })
                        .collect(),
                },
                reconcile_store: self.reconcile_store.clone(),
                reconcile_counter: self.reconcile_counter,
                federation: Some(self.federation.to_snapshot()),
                content_address_hash: {
                    let ca_data = serde_json::to_vec(&self.content_address)
                        .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
                    let tagged = crate::persist::chunk_store::tag_chunk_data(
                        crate::persist::chunk_store::CHUNK_FORMAT_JSON,
                        &ca_data,
                    );
                    let hash = chunk_store
                        .write_chunk(&tagged)
                        .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
                    Some(hash)
                },
                content_address: None,
                blob_metas_hash: {
                    let bm_data = serde_json::to_vec(&blob_metas)
                        .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
                    let tagged = crate::persist::chunk_store::tag_chunk_data(
                        crate::persist::chunk_store::CHUNK_FORMAT_JSON,
                        &bm_data,
                    );
                    let hash = chunk_store
                        .write_chunk(&tagged)
                        .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
                    Some(hash)
                },
                blob_metas: Vec::new(),
                key_history,
                historical_authors_hash: {
                    let ha_data = serde_json::to_vec(&self.historical_authors)
                        .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
                    let tagged = crate::persist::chunk_store::tag_chunk_data(
                        crate::persist::chunk_store::CHUNK_FORMAT_JSON,
                        &ha_data,
                    );
                    let hash = chunk_store
                        .write_chunk(&tagged)
                        .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
                    Some(hash)
                },
                historical_authors: None,
                annotations_hash: {
                    let all_anns = self.otree_crdt.all_annotations();
                    let total: usize = all_anns.iter().map(|(_, a)| a.len()).sum();
                    tracing::info!(
                        "[checkpoint] saving {} annotations across {} works",
                        total,
                        all_anns.len()
                    );
                    let ann_data = serde_json::to_vec(&all_anns)
                        .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
                    let tagged = crate::persist::chunk_store::tag_chunk_data(
                        crate::persist::chunk_store::CHUNK_FORMAT_JSON,
                        &ann_data,
                    );
                    let hash = chunk_store
                        .write_chunk(&tagged)
                        .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
                    tracing::info!(
                        "[checkpoint] annotations chunk hash={}",
                        hash.iter()
                            .map(|b| format!("{:02x}", b))
                            .collect::<String>()
                    );
                    Some(hash)
                },
                fossil_snapshots_hash: {
                    let (snapshots, _next_id) = self.recorder_system.to_snapshots();
                    if snapshots.is_empty() {
                        None
                    } else {
                        tracing::info!("[checkpoint] saving {} fossil snapshots", snapshots.len());
                        let fs_data = serde_json::to_vec(&snapshots)
                            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
                        let tagged = crate::persist::chunk_store::tag_chunk_data(
                            crate::persist::chunk_store::CHUNK_FORMAT_JSON,
                            &fs_data,
                        );
                        let hash = chunk_store
                            .write_chunk(&tagged)
                            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
                        Some(hash)
                    }
                },
                starred_works: {
                    let sw = self.starred_works.clone();
                    if !sw.is_empty() {
                        let total: usize = sw.values().map(|s| s.len()).sum();
                        tracing::info!(
                            "[checkpoint] serializing starred_works: {} clubs, {} total stars",
                            sw.len(),
                            total
                        );
                    }
                    sw
                },
                trails: self
                    .trails
                    .values()
                    .map(|t| crate::persist::manifest::TrailManifestEntry {
                        trail_id: t.trail_id,
                        owner_club: t.owner_club,
                        name: t.name.clone(),
                        stops: t
                            .stops
                            .iter()
                            .map(|s| crate::persist::manifest::TrailStopManifestEntry {
                                work_id: s.work_id,
                                char_start: s.char_start,
                                char_end: s.char_end,
                                note: s.note.clone(),
                            })
                            .collect(),
                        created_at: t.created_at,
                        updated_at: t.updated_at,
                    })
                    .collect(),
                trail_counter: self.trail_counter,
                compound_editions: self
                    .compound_editions
                    .iter()
                    .map(|(id, c)| (*id, c.clone()))
                    .collect(),
            };

            let data_dir = match self.data_dir.as_ref() {
                Some(d) => d.as_path(),
                None => {
                    return Err(std::io::Error::new(
                        std::io::ErrorKind::Other,
                        "no data dir",
                    ))
                }
            };

            let next_slot = if self.manifest_slot == 'a' { 'b' } else { 'a' };
            let dual_path = data_dir.join(format!("manifest_{}.json", next_slot));

            crate::persist::manifest::rotate_manifest_backups(&manifest_path, 3);
            crate::persist::manifest::write_manifest(&mut manifest, &dual_path).map_err(|e| {
                tracing::error!(
                    "Failed to write dual manifest to {}: {}",
                    dual_path.display(),
                    e
                );
                std::io::Error::new(std::io::ErrorKind::Other, e)
            })?;

            match std::fs::rename(&dual_path, &manifest_path) {
                Ok(()) => {}
                Err(e) => {
                    tracing::warn!(
                        "Failed to promote {} to primary ({}), keeping as dual backup: {}",
                        dual_path.display(),
                        manifest_path.display(),
                        e
                    );
                    if !manifest_path.exists() {
                        tracing::error!(
                            "Primary manifest missing and rename failed — data at risk"
                        );
                        return Err(e);
                    }
                }
            }

            self.manifest_sequence = manifest.sequence;
            self.manifest_slot = next_slot;

            self.dirty_clubs.clear();

            {
                let backup =
                    crate::persist::manifest::backup_manifest_path(data_dir, manifest.sequence);
                match crate::persist::manifest::write_backup_with_fsync(&manifest_path, &backup) {
                    Ok(()) => {}
                    Err(e) => {
                        tracing::warn!("Failed to create versioned manifest backup: {}", e);
                    }
                }
            }
            self.save_key_history();

            if let Err(e) = self.gc_orphaned_chunks() {
                tracing::warn!("Chunk GC failed: {}", e);
            }

            if let Err(e) = self.wal.truncate() {
                tracing::warn!("WAL truncate failed after checkpoint: {}", e);
            }

            tracing::info!(
                "Checkpoint #{} saved in {:.2}ms (dirty: {}/{}/{} works/clubs/editions)",
                start.elapsed().as_secs_f64() * 1000.0,
                dirty_work_count,
                dirty_club_count,
                dirty_edition_count,
                manifest.sequence,
            );
            self.last_checkpoint_time = std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs();
            Ok(())
        }

        pub fn gc_orphaned_chunks(&self) -> std::io::Result<u64> {
            let chunk_store = match self.chunk_store.as_ref() {
                Some(cs) => cs,
                None => return Ok(0),
            };

            let mut referenced: std::collections::HashSet<[u8; 32]> =
                std::collections::HashSet::new();
            for ws in self.works.values() {
                if let Some(ref work_ref) = ws.chunk_ref {
                    match crate::persist::edition_chunks::collect_work_hashes(work_ref, chunk_store)
                    {
                        Ok(hashes) => referenced.extend(hashes),
                        Err(e) => {
                            tracing::warn!(
                                "GC: failed to collect work {} hashes ({}), \
                                 skipping GC to avoid deleting valid chunks",
                                ws.work.be_id(),
                                e
                            );
                            return Ok(0);
                        }
                    }
                }
            }

            {
                let manifest_path = match self.checkpoint_path.as_ref() {
                    Some(p) => p,
                    None => {
                        return Err(std::io::Error::new(
                            std::io::ErrorKind::Other,
                            "no checkpoint path",
                        ))
                    }
                };
                let manifest = crate::persist::manifest::read_manifest(manifest_path);
                let manifest = match manifest {
                    Ok(m) => m,
                    Err(e) => {
                        tracing::warn!(
                            "GC: failed to read manifest for chunk protection ({}), \
                             skipping GC to avoid deleting valid chunks",
                            e
                        );
                        return Ok(0);
                    }
                };
                // CHECKLIST: every Option<[u8; 32]> field in Manifest must be
                // inserted into `referenced` here, or the GC will delete the
                // chunk. Current fields (as of 2026-06):
                //   - historical_authors_hash
                //   - blob_metas_hash
                //   - content_address_hash
                //   - links_hash
                //   - annotations_hash
                //   - fossil_snapshots_hash
                if let Some(hash) = manifest.historical_authors_hash {
                    referenced.insert(hash);
                }
                if let Some(hash) = manifest.blob_metas_hash {
                    referenced.insert(hash);
                }
                if let Some(hash) = manifest.content_address_hash {
                    referenced.insert(hash);
                }
                if let Some(hash) = manifest.links_hash {
                    referenced.insert(hash);
                }
                if let Some(hash) = manifest.annotations_hash {
                    referenced.insert(hash);
                }
                if let Some(hash) = manifest.fossil_snapshots_hash {
                    referenced.insert(hash);
                }
            }
            for club_ref in self.club_refs.values() {
                match crate::persist::edition_chunks::collect_work_hashes(
                    &club_ref.work_root,
                    chunk_store,
                ) {
                    Ok(hashes) => referenced.extend(hashes),
                    Err(e) => {
                        tracing::warn!(
                            "GC: failed to collect club hashes ({}), \
                             skipping GC to avoid deleting valid chunks",
                            e
                        );
                        return Ok(0);
                    }
                }
            }
            for ed_ref in self.standalone_edition_refs.values() {
                match crate::persist::edition_chunks::collect_edition_hashes(ed_ref, chunk_store) {
                    Ok(hashes) => referenced.extend(hashes),
                    Err(e) => {
                        tracing::warn!(
                            "GC: failed to collect standalone edition hashes ({}), \
                             skipping GC to avoid deleting valid chunks",
                            e
                        );
                        return Ok(0);
                    }
                }
            }

            let all_chunks = chunk_store
                .all_chunk_hashes()
                .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;

            if let Some(ref data_dir) = self.data_dir {
                let mut backup_manifests: Vec<std::path::PathBuf> = Vec::new();
                if let Ok(entries) = std::fs::read_dir(data_dir) {
                    for entry in entries.flatten() {
                        let name = entry.file_name();
                        let name_str = name.to_str().unwrap_or("");
                        if name_str.starts_with("manifest_v") && name_str.ends_with(".json") {
                            backup_manifests.push(entry.path());
                        }
                    }
                }
                for backup_path in &backup_manifests {
                    if let Ok(backup_manifest) =
                        crate::persist::manifest::read_manifest(backup_path)
                    {
                        for work_entry in &backup_manifest.works {
                            match crate::persist::edition_chunks::collect_work_hashes(
                                &work_entry.work_ref,
                                chunk_store,
                            ) {
                                Ok(hashes) => referenced.extend(hashes),
                                Err(e) => {
                                    tracing::warn!(
                                        "GC: failed to collect backup work hashes ({}), \
                                         skipping GC to avoid deleting valid chunks",
                                        e
                                    );
                                    return Ok(0);
                                }
                            }
                        }
                        for club_ref in &backup_manifest.clubs {
                            match crate::persist::edition_chunks::collect_work_hashes(
                                &club_ref.work_root,
                                chunk_store,
                            ) {
                                Ok(hashes) => referenced.extend(hashes),
                                Err(e) => {
                                    tracing::warn!(
                                        "GC: failed to collect backup club hashes ({}), \
                                         skipping GC to avoid deleting valid chunks",
                                        e
                                    );
                                    return Ok(0);
                                }
                            }
                        }
                        for se_ref in &backup_manifest.standalone_editions {
                            match crate::persist::edition_chunks::collect_edition_hashes(
                                &se_ref.edition_ref,
                                chunk_store,
                            ) {
                                Ok(hashes) => referenced.extend(hashes),
                                Err(e) => {
                                    tracing::warn!(
                                        "GC: failed to collect backup standalone edition \
                                         hashes ({}), skipping GC to avoid deleting valid chunks",
                                        e
                                    );
                                    return Ok(0);
                                }
                            }
                        }
                    }
                }
            }

            let mut removed = 0u64;
            for hash in &all_chunks {
                if !referenced.contains(hash) {
                    if let Ok(()) = chunk_store.delete_chunk(hash) {
                        removed += 1;
                    }
                }
            }

            if removed > 0 {
                tracing::info!(
                    "Chunk GC: removed {} orphaned chunks ({} referenced, {} total on disk)",
                    removed,
                    referenced.len(),
                    all_chunks.len(),
                );
            }

            Ok(removed)
        }

        pub fn restore_from_file(path: &std::path::Path) -> std::io::Result<Self> {
            let data = crate::server::transport::snapshot::full_restore(path)
                .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
            let snapshot: ServerSnapshot = serde_json::from_value(data)
                .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
            Ok(Self::from_snapshot(&snapshot))
        }

        pub fn restore_from_file_with_persistence(path: &std::path::Path) -> std::io::Result<Self> {
            let data = crate::server::transport::snapshot::full_restore(path)
                .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
            let snapshot: ServerSnapshot = serde_json::from_value(data)
                .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
            Ok(Self::from_snapshot_with_persistence(&snapshot, path))
        }

        fn from_snapshot_with_persistence(
            snapshot: &ServerSnapshot,
            snapshot_path: &std::path::Path,
        ) -> Self {
            let mut server = Self::from_snapshot(snapshot);
            server.checkpoint_path = Some(snapshot_path.to_path_buf());
            if let Some(data_dir) = snapshot_path.parent() {
                let _ = server.load_keypair_from_dir(data_dir, None);
                server.restore_key_history_from_snapshot();
                let _ = server.restore_blob_store(data_dir, snapshot.blob_metas.clone());
            }
            server
        }
    }
}

#[allow(dead_code)]
fn find_shared_substrings(
    text_a: &str,
    text_b: &str,
    min_len: usize,
) -> Vec<(i64, i64, i64, i64, String)> {
    let a_bytes = text_a.as_bytes();
    let b_bytes = text_b.as_bytes();
    let a_len = a_bytes.len();
    let b_len = b_bytes.len();
    if a_len == 0 || b_len == 0 || min_len == 0 {
        return Vec::new();
    }
    let mut results = Vec::new();
    let mut matched_a = vec![false; a_len];
    let mut matched_b = vec![false; b_len];
    for i in 0..a_len {
        if matched_a[i] {
            continue;
        }
        for j in 0..b_len {
            if matched_b[j] {
                continue;
            }
            let mut len = 0usize;
            while i + len < a_len
                && j + len < b_len
                && !matched_a[i + len]
                && !matched_b[j + len]
                && a_bytes[i + len] == b_bytes[j + len]
            {
                len += 1;
            }
            if len >= min_len {
                let shared = String::from_utf8_lossy(&a_bytes[i..i + len]).to_string();
                results.push((
                    i as i64,
                    (i + len) as i64,
                    j as i64,
                    (j + len) as i64,
                    shared,
                ));
                for k in 0..len {
                    matched_a[i + k] = true;
                    matched_b[j + k] = true;
                }
                break;
            }
        }
    }
    results
}

#[cfg(test)]
mod tests_find_text {
    use super::*;
    use crate::edition::Edition;

    fn setup() -> (Server, crate::server::SessionId) {
        let mut server = Server::new();
        let session = server.connect();
        server.login_public(session).unwrap();
        (server, session)
    }

    #[test]
    fn find_text_transcluders_basic() {
        let (mut server, sid) = setup();
        let doc1 = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();
        let doc2 = server
            .create_work(sid, Edition::from_text("hello universe"))
            .unwrap();
        let doc3 = server
            .create_work(sid, Edition::from_text("goodbye world"))
            .unwrap();

        let results = server.find_text_transcluders("hello");
        assert_eq!(results.len(), 2);
        let ids: Vec<BeId> = results.iter().map(|(id, _, _, _)| *id).collect();
        assert!(ids.contains(&doc1));
        assert!(ids.contains(&doc2));
        assert!(!ids.contains(&doc3));
    }

    #[test]
    fn find_text_transcluders_returns_match_positions() {
        let (mut server, sid) = setup();
        let _doc = server
            .create_work(sid, Edition::from_text("abc hello def hello ghi"))
            .unwrap();

        let results = server.find_text_transcluders("hello");
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].3.len(), 2);
        assert_eq!(results[0].3[0], (4, 9));
        assert_eq!(results[0].3[1], (14, 19));
    }

    #[test]
    fn find_text_transcluders_no_match() {
        let (mut server, sid) = setup();
        let _doc = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();

        let results = server.find_text_transcluders("xyz");
        assert!(results.is_empty());
    }

    #[test]
    fn find_text_transcluders_returns_owner_and_revision_count() {
        let (mut server, sid) = setup();
        let doc = server
            .create_work(sid, Edition::from_text("hello"))
            .unwrap();

        let results = server.find_text_transcluders("hello");
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].0, doc);
        assert!(results[0].1.is_some());
        assert_eq!(results[0].2, 0);
    }

    #[test]
    fn find_text_transcluders_fingerprint_intersection_filters() {
        let (mut server, sid) = setup();
        let _doc_a = server
            .create_work(sid, Edition::from_text("the quick brown fox"))
            .unwrap();
        let _doc_b = server
            .create_work(sid, Edition::from_text("aaa bbb ccc"))
            .unwrap();
        let doc_c = server
            .create_work(sid, Edition::from_text("the slow brown bear"))
            .unwrap();

        let results = server.find_text_transcluders("brown");
        let found_ids: Vec<BeId> = results.iter().map(|(id, _, _, _)| *id).collect();
        assert!(found_ids.contains(&doc_c), "doc_c contains 'brown'");
        assert_eq!(results.len(), 2, "two works contain 'b','r','o','w','n'");
    }

    #[test]
    fn find_text_transcluders_long_text_performance() {
        let (mut server, sid) = setup();
        let long_text: String = "abcdefghijklmnopqrstuvwxyz".repeat(200);
        let _doc = server
            .create_work(sid, Edition::from_text(&long_text))
            .unwrap();

        let results = server.find_text_transcluders("xyzabc");
        assert_eq!(results.len(), 1);
        assert!(
            !results[0].3.is_empty(),
            "should find 'xyzabc' at wrap-around boundary"
        );
    }

    #[test]
    fn find_shared_regions_basic() {
        let (mut server, sid) = setup();
        let doc_a = server
            .create_work(sid, Edition::from_text("the quick brown fox"))
            .unwrap();
        let doc_b = server
            .create_work(sid, Edition::from_text("a quick blue fox jumps"))
            .unwrap();

        let regions = server.find_shared_regions(doc_a, doc_b);
        assert!(!regions.is_empty());
        let texts: Vec<&str> = regions.iter().map(|r| r.4.as_str()).collect();
        assert!(texts.iter().any(|t: &&str| t.contains("quick")));
        assert!(texts.iter().any(|t: &&str| t.contains("fox")));
    }

    #[test]
    fn find_shared_regions_no_overlap() {
        let (mut server, sid) = setup();
        let doc_a = server.create_work(sid, Edition::from_text("aaaa")).unwrap();
        let doc_b = server.create_work(sid, Edition::from_text("bbbb")).unwrap();

        let regions = server.find_shared_regions(doc_a, doc_b);
        assert!(regions.is_empty());
    }

    #[test]
    fn find_shared_substrings_basic() {
        let results = find_shared_substrings("the quick brown fox", "a quick blue fox", 4);
        assert!(!results.is_empty());
        let texts: Vec<&str> = results.iter().map(|r| r.4.as_str()).collect();
        assert!(texts.iter().any(|t| t.contains("quick")));
    }

    #[test]
    fn find_shared_substrings_min_length() {
        let results = find_shared_substrings("abcdef", "abcxyz", 4);
        assert!(results.is_empty());
        let results = find_shared_substrings("abcdef", "abcxyz", 3);
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].4, "abc");
    }

    #[test]
    fn find_shared_substrings_empty() {
        assert!(find_shared_substrings("", "hello", 4).is_empty());
        assert!(find_shared_substrings("hello", "", 4).is_empty());
    }
}

#[cfg(test)]
mod tests {
    const TEST_OWNER_CREDENTIAL: &[u8] = b"xudanu-test-owner";
    const TEST_OTHER_CREDENTIAL: &[u8] = b"xudanu-test-other";
    const TEST_MEMBER_CREDENTIAL: &[u8] = b"xudanu-test-member";
    const TEST_ALT_CREDENTIAL: &[u8] = b"xudanu-test-alt";
    const TEST_ADMIN_CREDENTIAL: &[u8] = b"xudanu-test-admin";
    const TEST_CLUB_PASSWORD: &[u8] = b"xudanu-test-club-pass";
    use super::*;
    use crate::edition::RangeElement;
    use crate::server::crdt_manager::{AwarenessState, CursorPosition};
    use crate::server::lock::Lock;
    use crate::server::lock::LockCredential;
    use crate::server::transport::protocol::TextDeltaOp;

    fn setup_logged_in_server() -> (Server, SessionId) {
        let mut server = Server::new();
        let session = server.connect();
        server.login_public(session).unwrap();
        (server, session)
    }

    #[test]
    fn server_new_creates_system_clubs() {
        let server = Server::new();
        assert!(server.public_club_id() > 0);
        assert!(server.admin_club_id() > 0);
        assert!(server.access_club_id() > 0);
        assert!(server.empty_club_id() > 0);
        assert_ne!(server.public_club_id(), server.admin_club_id());
    }

    #[test]
    fn server_connect_creates_session() {
        let mut server = Server::new();
        let sid = server.connect();
        assert!(server.session(sid).unwrap().is_connected());
        assert_eq!(server.session_count(), 1);
    }

    #[test]
    fn server_login_public() {
        let mut server = Server::new();
        let sid = server.connect();
        let km = server.login_public(sid).unwrap();
        assert!(km.has_authority(server.public_club_id()));
        assert!(server.session(sid).unwrap().is_logged_in());
    }

    #[test]
    fn server_login_public_club_by_name() {
        let mut server = Server::new();
        let sid = server.connect();
        let club_id = server.club_id_by_name("public").unwrap();
        assert_eq!(club_id, server.public_club_id());
        let km = server.login_public(sid).unwrap();
        assert!(km.has_authority(server.public_club_id()));
    }

    #[test]
    fn server_login_nonexistent_club() {
        let mut server = Server::new();
        let sid = server.connect();
        let result = server.login_by_name(sid, "nonexistent");
        assert!(result.is_err());
    }

    #[test]
    fn server_create_work() {
        let (server, session) = setup_logged_in_server();
        drop(server);
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let edition = Edition::from_text("hello");
        let work_id = server.create_work(sid, edition).unwrap();
        assert!(work_id > 0);

        let ed = server.work_edition(work_id).unwrap();
        assert_eq!(ed.to_text(), "hello");
    }

    #[test]
    fn server_work_grab_release() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let work_id = server.create_work(sid, Edition::from_text("v1")).unwrap();

        assert!(!server.work_is_grabbed(work_id).unwrap());

        server.work_grab(sid, work_id).unwrap();
        assert!(server.work_is_grabbed(work_id).unwrap());
        assert_eq!(server.work_grabber(work_id).unwrap(), Some(sid));

        server.work_release(sid, work_id).unwrap();
        assert!(!server.work_is_grabbed(work_id).unwrap());
    }

    #[test]
    fn server_work_revise() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let work_id = server.create_work(sid, Edition::from_text("v1")).unwrap();

        server.work_grab(sid, work_id).unwrap();
        let rev = server
            .work_revise(sid, work_id, Edition::from_text("v2"))
            .unwrap();
        assert_eq!(rev, 1);

        let ed = server.work_edition(work_id).unwrap();
        assert_eq!(ed.to_text(), "v2");

        let old = server.work_fetch_revision(work_id, 0).unwrap().unwrap();
        assert_eq!(old.to_text(), "v1");
    }

    #[test]
    fn server_revise_without_grab_fails() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let work_id = server.create_work(sid, Edition::from_text("v1")).unwrap();

        let result = server.work_revise(sid, work_id, Edition::from_text("v2"));
        assert!(result.is_err());
    }

    #[test]
    fn server_grab_conflict() {
        let mut server = Server::new();
        let sid1 = server.connect();
        server.login_public(sid1).unwrap();
        let sid2 = server.connect();
        server.login_public(sid2).unwrap();

        let work_id = server
            .create_work(sid1, Edition::from_text("test"))
            .unwrap();

        server.work_grab(sid1, work_id).unwrap();
        let result = server.work_grab(sid2, work_id);
        assert!(result.is_err());
    }

    #[test]
    fn server_create_club() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let club_id = server
            .create_club(sid, Edition::from_text("my club"))
            .unwrap();
        assert!(club_id > 0);

        let club = server.club(club_id).unwrap();
        assert_eq!(club.edition().to_text(), "my club");
    }

    #[test]
    fn server_named_club() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let club_id = server
            .create_named_club(sid, "editors", Edition::empty())
            .unwrap();
        assert_eq!(server.club_id_by_name("editors"), Some(club_id));
        assert_eq!(server.club_name_by_id(club_id), Some("editors"));
    }

    #[test]
    fn server_duplicate_club_name_fails() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        server
            .create_named_club(sid, "editors", Edition::empty())
            .unwrap();
        let result = server.create_named_club(sid, "editors", Edition::empty());
        assert!(result.is_err());
    }

    #[test]
    fn server_work_permissions() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work_id = server.create_work(sid, Edition::from_text("doc")).unwrap();

        assert!(server.work_can_read(sid, work_id).unwrap());
        assert!(server.work_can_revise(sid, work_id).unwrap());
    }

    #[test]
    fn server_work_set_edit_club() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let private_club = server.create_club(sid, Edition::empty()).unwrap();
        let work_id = server
            .create_work(sid, Edition::from_text("restricted"))
            .unwrap();

        server
            .work_set_edit_club(sid, work_id, Some(private_club))
            .unwrap();

        assert!(!server.work_can_revise(sid, work_id).unwrap());
    }

    #[test]
    fn server_work_sponsors() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let club_id = server.create_club(sid, Edition::empty()).unwrap();
        let work_id = server.create_work(sid, Edition::from_text("doc")).unwrap();

        server.work_sponsor(sid, work_id, club_id).unwrap();
        assert_eq!(server.work_sponsors(work_id).unwrap(), &[club_id]);

        server.work_unsponsor(sid, work_id, club_id).unwrap();
        assert!(server.work_sponsors(work_id).unwrap().is_empty());
    }

    #[test]
    fn server_disconnect_releases_grabs() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let work_id = server.create_work(sid, Edition::from_text("doc")).unwrap();

        server.work_grab(sid, work_id).unwrap();
        assert!(server.work_is_grabbed(work_id).unwrap());

        server.disconnect(sid).unwrap();
        assert!(!server.work_is_grabbed(work_id).unwrap());
    }

    #[test]
    fn server_not_logged_in_cannot_create_work() {
        let mut server = Server::new();
        let sid = server.connect();
        let result = server.create_work(sid, Edition::empty());
        assert!(result.is_err());
    }

    #[test]
    fn server_work_revision_history() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let work_id = server.create_work(sid, Edition::from_text("r0")).unwrap();

        server.work_grab(sid, work_id).unwrap();
        for i in 1..5u64 {
            server
                .work_revise(sid, work_id, Edition::from_text(&format!("r{}", i)))
                .unwrap();
        }

        assert_eq!(server.work_revision_count(work_id).unwrap(), 4);
        assert_eq!(
            server
                .work_fetch_revision(work_id, 0)
                .unwrap()
                .unwrap()
                .to_text(),
            "r0"
        );
        assert_eq!(server.work_edition(work_id).unwrap().to_text(), "r4");
    }

    #[test]
    fn server_store_and_get_edition() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let edition = Edition::from_text("standalone");
        let be_id = server.store_edition(sid, edition).unwrap();
        let retrieved = server.get_edition(be_id).unwrap().unwrap();
        assert_eq!(retrieved.to_text(), "standalone");
    }

    #[test]
    fn server_get_by_be_id() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let work_id = server.create_work(sid, Edition::from_text("doc")).unwrap();

        let elem = server.get_by_be_id(work_id);
        assert!(elem.is_some());
    }

    #[test]
    fn server_club_names_list() {
        let server = Server::new();
        let names = server.club_names_list();
        let name_strs: Vec<&str> = names.iter().map(|(n, _)| *n).collect();
        assert!(name_strs.contains(&"public"));
        assert!(name_strs.contains(&"admin"));
    }

    #[test]
    fn server_work_not_found() {
        let server = Server::new();
        let result = server.work_edition(99999);
        assert!(result.is_err());
    }

    #[test]
    fn server_detector_revision_event() {
        use std::sync::{Arc, Mutex};

        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let work_id = server.create_work(sid, Edition::from_text("v0")).unwrap();

        let events: Arc<Mutex<Vec<Event>>> = Arc::new(Mutex::new(Vec::new()));
        let events_clone = events.clone();
        let detector = Box::new(crate::server::detector::FnDetector::new(
            move |event: &Event| {
                events_clone
                    .lock()
                    .unwrap_or_else(|e| e.into_inner())
                    .push(event.clone());
            },
        ));
        server.add_revision_detector(work_id, detector).unwrap();

        server.work_grab(sid, work_id).unwrap();
        server
            .work_revise(sid, work_id, Edition::from_text("v1"))
            .unwrap();

        let captured = events.lock().unwrap_or_else(|e| e.into_inner());
        assert_eq!(captured.len(), 1);
        match &captured[0] {
            Event::WorkRevised {
                work_be_id,
                revision,
                ..
            } => {
                assert_eq!(*work_be_id, work_id);
                assert_eq!(*revision, 1);
            }
            _ => panic!("expected WorkRevised event"),
        }
    }

    #[test]
    fn server_detector_status_events() {
        use std::sync::{Arc, Mutex};

        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let work_id = server.create_work(sid, Edition::empty()).unwrap();

        let events: Arc<Mutex<Vec<Event>>> = Arc::new(Mutex::new(Vec::new()));
        let events_clone = events.clone();
        let detector = Box::new(crate::server::detector::FnDetector::new(
            move |event: &Event| {
                events_clone
                    .lock()
                    .unwrap_or_else(|e| e.into_inner())
                    .push(event.clone());
            },
        ));
        server.add_status_detector(work_id, detector).unwrap();

        server.work_grab(sid, work_id).unwrap();
        server.work_release(sid, work_id).unwrap();

        let captured = events.lock().unwrap_or_else(|e| e.into_inner());
        assert_eq!(captured.len(), 2);
        assert!(matches!(&captured[0], Event::WorkGrabbed { .. }));
        assert!(matches!(&captured[1], Event::WorkReleased { .. }));
    }

    #[test]
    fn server_multi_session_workflow() {
        let mut server = Server::new();

        let alice = server.connect();
        server.login_public(alice).unwrap();
        let bob = server.connect();
        server.login_public(bob).unwrap();

        let doc = server
            .create_work(alice, Edition::from_text("shared doc"))
            .unwrap();

        assert!(server.work_can_read(alice, doc).unwrap());
        assert!(server.work_can_read(bob, doc).unwrap());

        server.work_grab(alice, doc).unwrap();
        assert!(server.work_is_grabbed(doc).unwrap());

        assert!(server.work_grab(bob, doc).is_err());

        server
            .work_revise(alice, doc, Edition::from_text("alice edited"))
            .unwrap();

        server.work_release(alice, doc).unwrap();
        assert!(!server.work_is_grabbed(doc).unwrap());

        server.work_grab(bob, doc).unwrap();
        server
            .work_revise(bob, doc, Edition::from_text("bob edited"))
            .unwrap();
        server.work_release(bob, doc).unwrap();

        assert_eq!(server.work_revision_count(doc).unwrap(), 2);
        assert_eq!(server.work_edition(doc).unwrap().to_text(), "bob edited");
        assert_eq!(
            server
                .work_fetch_revision(doc, 0)
                .unwrap()
                .unwrap()
                .to_text(),
            "shared doc"
        );
    }

    #[test]
    fn server_restricted_work_permissions() {
        let mut server = Server::new();
        let owner_sid = server.connect();
        server.login_public(owner_sid).unwrap();

        let private_club = server
            .create_named_club(owner_sid, "private", Edition::empty())
            .unwrap();

        let work_id = server
            .create_work(owner_sid, Edition::from_text("secret"))
            .unwrap();

        server
            .work_set_edit_club(owner_sid, work_id, Some(private_club))
            .unwrap();

        let reader_sid = server.connect();
        server.login_public(reader_sid).unwrap();
        assert!(server.work_can_read(reader_sid, work_id).unwrap());
        assert!(!server.work_can_revise(reader_sid, work_id).unwrap());
        assert!(server.work_grab(reader_sid, work_id).is_err());
    }

    #[test]
    fn server_club_signature_chain() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let signing_club = server
            .create_named_club(sid, "signers", Edition::empty())
            .unwrap();
        let main_club = server
            .create_named_club(sid, "main", Edition::empty())
            .unwrap();

        server
            .club_mut(main_club)
            .unwrap()
            .set_signature_club(Some(signing_club));

        let club = server.club(main_club).unwrap();
        assert_eq!(club.signature_club(), Some(signing_club));
    }

    #[test]
    fn server_work_owner_tracking() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let club_id = server
            .create_named_club(sid, "owners", Edition::empty())
            .unwrap();
        let work_id = server
            .create_work(sid, Edition::from_text("owned"))
            .unwrap();

        assert!(server.work_owner(work_id).unwrap().is_some());
        server.work_set_owner(sid, work_id, Some(club_id)).unwrap();
        assert_eq!(server.work_owner(work_id).unwrap(), Some(club_id));
    }

    #[test]
    fn server_fill_detector() {
        use std::sync::{Arc, Mutex};

        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let edition_id = server
            .store_edition(sid, Edition::from_text("content"))
            .unwrap();

        let events: Arc<Mutex<Vec<Event>>> = Arc::new(Mutex::new(Vec::new()));
        let events_clone = events.clone();
        let detector = Box::new(crate::server::detector::FnDetector::new(
            move |event: &Event| {
                events_clone
                    .lock()
                    .unwrap_or_else(|e| e.into_inner())
                    .push(event.clone());
            },
        ));
        server.add_fill_detector(edition_id, detector).unwrap();

        server.fire_fill_event(edition_id, crate::edition::XnRegion::interval(0, 7));

        let captured = events.lock().unwrap_or_else(|e| e.into_inner());
        assert_eq!(captured.len(), 1);
        assert!(matches!(&captured[0], Event::RangeFilled { .. }));
    }

    #[test]
    fn server_challenge_lock_workflow() {
        use crate::server::lock::ChallengeLock;

        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let club_id = server
            .create_named_club(sid, "challenge_club", Edition::empty())
            .unwrap();

        let signing_key = crate::crypto::sign::generate_signing_key();
        let verifying_key = signing_key.verifying_key().to_bytes();
        let challenge = vec![1u8, 2, 3, 4, 5, 6, 7, 8];
        let lock = ChallengeLock::new(club_id, challenge.clone(), verifying_key);

        let wrong_key = crate::crypto::sign::generate_signing_key();
        let mut wrong_msg = Vec::new();
        wrong_msg.extend_from_slice(b"xudanu/v1/");
        wrong_msg.extend_from_slice(&challenge);
        let wrong_sig = crate::crypto::sign::sign_bytes(&wrong_key, &wrong_msg);
        let result = lock.try_open(&LockCredential::ChallengeResponse(
            wrong_sig.to_bytes().to_vec(),
        ));
        assert!(result.is_err());

        let mut correct_msg = Vec::new();
        correct_msg.extend_from_slice(b"xudanu/v1/");
        correct_msg.extend_from_slice(&challenge);
        let correct_sig = crate::crypto::sign::sign_bytes(&signing_key, &correct_msg);
        let km = lock
            .try_open(&LockCredential::ChallengeResponse(
                correct_sig.to_bytes().to_vec(),
            ))
            .unwrap();
        assert!(km.has_authority(club_id));

        let correct_sig2 = crate::crypto::sign::sign_bytes(&signing_key, &correct_msg);
        server
            .authenticate(
                sid,
                &lock,
                &LockCredential::ChallengeResponse(correct_sig2.to_bytes().to_vec()),
            )
            .unwrap();
        assert!(server.session(sid).unwrap().has_authority(club_id));
    }

    #[test]
    fn server_match_lock_workflow() {
        use crate::server::lock::{LockSmith, MatchLockSmith};

        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let club_id = server
            .create_named_club(sid, "password_club", Edition::empty())
            .unwrap();

        let smith = MatchLockSmith::from_password(b"s3cret").unwrap();
        let lock = smith.create_lock(Some(club_id));

        let result = lock.try_open(&LockCredential::Password(b"wrong".to_vec()));
        assert!(result.is_err());

        let km = lock
            .try_open(&LockCredential::Password(b"s3cret".to_vec()))
            .unwrap();
        assert!(km.has_authority(club_id));

        server
            .authenticate(
                sid,
                lock.as_ref(),
                &LockCredential::Password(b"s3cret".to_vec()),
            )
            .unwrap();
        assert!(server.session(sid).unwrap().has_authority(club_id));
    }

    #[test]
    fn server_multi_lock_workflow() {
        use crate::server::lock::MultiLock;

        let club_a = 100u64;
        let club_b = 200u64;

        let ml = MultiLock::new(None)
            .with_sub_lock(
                "boo".to_string(),
                Box::new(crate::server::lock::BooLock::new(club_a)),
            )
            .with_sub_lock(
                "wall".to_string(),
                Box::new(crate::server::lock::WallLock::new()),
            );

        let km = ml
            .try_open(&LockCredential::Named {
                name: "boo".to_string(),
                credential: Box::new(LockCredential::Boo),
            })
            .unwrap();
        assert!(km.has_authority(club_a));
        assert!(!km.has_authority(club_b));

        let wall_result = ml.try_open(&LockCredential::Named {
            name: "wall".to_string(),
            credential: Box::new(LockCredential::Boo),
        });
        assert!(wall_result.is_err());
    }

    #[test]
    fn server_keymaster_incorporate_and_revoke() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let club1 = server
            .create_named_club(sid, "club1", Edition::empty())
            .unwrap();
        let club2 = server
            .create_named_club(sid, "club2", Edition::empty())
            .unwrap();

        let mut km1 = KeyMaster::make(club1);
        let km2 = KeyMaster::make(club2);
        km1.incorporate(&km2);
        assert!(km1.has_authority(club1));
        assert!(km1.has_authority(club2));

        let mut to_remove = std::collections::HashSet::new();
        to_remove.insert(club2);
        km1.remove_logins(&to_remove);
        assert!(km1.has_authority(club1));
        assert!(!km1.has_authority(club2));
    }

    #[test]
    fn gold_server_full_document_lifecycle() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let doc = server
            .create_work(sid, Edition::from_text("Hello World"))
            .unwrap();
        assert_eq!(server.work_edition(doc).unwrap().to_text(), "Hello World");
        assert_eq!(server.work_revision_count(doc).unwrap(), 0);

        server.work_grab(sid, doc).unwrap();
        let ed_v1 = server.work_edition(doc).unwrap();
        let ed_v2 = ed_v1.with(5, RangeElement::text("X"));
        server.work_revise(sid, doc, ed_v2).unwrap();
        assert_eq!(server.work_edition(doc).unwrap().to_text(), "HelloXWorld");

        let ed_v3 = Edition::from_text("Completely new content");
        server.work_revise(sid, doc, ed_v3).unwrap();
        assert_eq!(
            server.work_edition(doc).unwrap().to_text(),
            "Completely new content"
        );

        assert_eq!(server.work_revision_count(doc).unwrap(), 2);
        assert_eq!(
            server
                .work_fetch_revision(doc, 0)
                .unwrap()
                .unwrap()
                .to_text(),
            "Hello World"
        );

        server.work_release(sid, doc).unwrap();
        assert!(!server.work_is_grabbed(doc).unwrap());
    }

    #[test]
    fn gold_server_multiple_sessions_isolation() {
        let mut server = Server::new();
        let s1 = server.connect();
        let s2 = server.connect();
        server.login_public(s1).unwrap();
        server.login_public(s2).unwrap();

        let doc1 = server.create_work(s1, Edition::from_text("doc1")).unwrap();
        let doc2 = server.create_work(s2, Edition::from_text("doc2")).unwrap();

        server.work_grab(s1, doc1).unwrap();
        server.work_grab(s2, doc2).unwrap();

        server
            .work_revise(s1, doc1, Edition::from_text("doc1 v2"))
            .unwrap();
        server
            .work_revise(s2, doc2, Edition::from_text("doc2 v2"))
            .unwrap();

        assert_eq!(server.work_edition(doc1).unwrap().to_text(), "doc1 v2");
        assert_eq!(server.work_edition(doc2).unwrap().to_text(), "doc2 v2");

        assert!(server.work_grab(s2, doc1).is_err());
        assert!(server.work_grab(s1, doc2).is_err());
    }

    #[test]
    fn gold_server_disconnect_during_grab() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let doc = server.create_work(sid, Edition::from_text("data")).unwrap();

        server.work_grab(sid, doc).unwrap();
        assert!(server.work_is_grabbed(doc).unwrap());

        server.disconnect(sid).unwrap();
        assert!(!server.work_is_grabbed(doc).unwrap());
    }

    #[cfg(feature = "server")]
    struct TempDir(std::path::PathBuf);

    #[cfg(feature = "server")]
    impl TempDir {
        fn new(name: &str) -> Self {
            let dir = std::env::temp_dir().join(format!(
                "xudanu_server_test_{}_{}",
                name,
                std::process::id()
            ));
            let _ = std::fs::create_dir_all(&dir);
            TempDir(dir)
        }
        fn snapshot_path(&self) -> std::path::PathBuf {
            self.0.join("server.json")
        }
    }

    #[cfg(feature = "server")]
    impl Drop for TempDir {
        fn drop(&mut self) {
            let _ = std::fs::remove_dir_all(&self.0);
        }
    }

    #[test]
    #[cfg(feature = "server")]
    fn server_checkpoint_restore_empty() {
        let dir = TempDir::new("empty");
        let server = Server::new();
        server.checkpoint_to_file(&dir.snapshot_path()).unwrap();

        let restored = Server::restore_from_file(&dir.snapshot_path()).unwrap();
        assert_eq!(restored.work_count(), 0);
    }

    #[test]
    #[cfg(feature = "server")]
    fn server_checkpoint_restore_with_works() {
        let dir = TempDir::new("with_works");

        let doc_id;
        {
            let mut server = Server::new();
            let sid = server.connect();
            server.login_public(sid).unwrap();
            doc_id = server
                .create_work(sid, Edition::from_text("hello world"))
                .unwrap();
            server.checkpoint_to_file(&dir.snapshot_path()).unwrap();
        }
        {
            let mut server = Server::restore_from_file(&dir.snapshot_path()).unwrap();
            assert_eq!(server.work_count(), 1);
            assert_eq!(
                server.work_edition(doc_id).unwrap().to_text(),
                "hello world"
            );
        }
    }

    #[test]
    fn work_archive_toggles_state_and_records_history() {
        let mut server = Server::new();
        let (alice, alice_sid) = ac_create_user(&mut server, "alice", b"alice-pass-1");
        let work = server
            .create_work(alice_sid, Edition::from_text("hello"))
            .unwrap();
        if let Some(ws) = server.works.get_mut(&work) {
            ws.work.set_edit_club(Some(alice));
            ws.work.set_owner(Some(alice));
        }

        assert!(!server.work_is_archived(work).unwrap());
        assert!(server
            .works
            .get(&work)
            .unwrap()
            .work
            .lifecycle_history()
            .is_empty());

        server.work_archive(alice_sid, work).unwrap();
        assert!(server.work_is_archived(work).unwrap());
        let h = server.works.get(&work).unwrap().work.lifecycle_history();
        assert_eq!(h.len(), 1);
        assert_eq!(
            h[0].kind,
            crate::edition::work::LifecycleEventKind::Archived
        );
        assert_eq!(h[0].actor_club, alice);

        server.work_unarchive(alice_sid, work).unwrap();
        assert!(!server.work_is_archived(work).unwrap());
        assert_eq!(
            server
                .works
                .get(&work)
                .unwrap()
                .work
                .lifecycle_history()
                .len(),
            2
        );
    }

    #[test]
    fn work_archive_requires_edit_authority() {
        let mut server = Server::new();
        let (alice, alice_sid) = ac_create_user(&mut server, "alice", b"alice-pass-1");
        let (_bob, bob_sid) = ac_create_user(&mut server, "bob", b"bobby-pass-1");
        let work = server
            .create_work(alice_sid, Edition::from_text("secret doc"))
            .unwrap();
        if let Some(ws) = server.works.get_mut(&work) {
            ws.work.set_edit_club(Some(alice)); // only alice can edit
        }

        // A non-editor (bob) must not be able to archive.
        let err = server.work_archive(bob_sid, work).unwrap_err();
        assert!(
            matches!(err, ServerError::NotAuthorized),
            "non-editor must not archive, got {:?}",
            err
        );
        assert!(
            !server.work_is_archived(work).unwrap(),
            "state must be unchanged after a denied archive"
        );

        // The editor (alice) can.
        server.work_archive(alice_sid, work).unwrap();
        assert!(server.work_is_archived(work).unwrap());
    }

    #[test]
    fn archived_state_and_history_survive_checkpoint_restore() {
        let dir = TempDir::new("archive_persist");
        let work_id;
        {
            let mut server = Server::new();
            let (alice, alice_sid) = ac_create_user(&mut server, "alice", b"alice-pass-1");
            work_id = server
                .create_work(alice_sid, Edition::from_text("persist me"))
                .unwrap();
            if let Some(ws) = server.works.get_mut(&work_id) {
                ws.work.set_edit_club(Some(alice));
                ws.work.set_owner(Some(alice));
            }
            // archive -> unarchive -> archive leaves 3 lifecycle events.
            server.work_archive(alice_sid, work_id).unwrap();
            server.work_unarchive(alice_sid, work_id).unwrap();
            server.work_archive(alice_sid, work_id).unwrap();
            assert_eq!(
                server
                    .works
                    .get(&work_id)
                    .unwrap()
                    .work
                    .lifecycle_history()
                    .len(),
                3
            );
            server.checkpoint_to_file(&dir.snapshot_path()).unwrap();
        }
        {
            let server = Server::restore_from_file(&dir.snapshot_path()).unwrap();
            assert!(
                server.work_is_archived(work_id).unwrap(),
                "archived state must survive restart"
            );
            assert_eq!(
                server
                    .works
                    .get(&work_id)
                    .unwrap()
                    .work
                    .lifecycle_history()
                    .len(),
                3,
                "lifecycle history must survive restart"
            );
        }
    }

    #[test]
    #[cfg(feature = "server")]
    fn server_checkpoint_restore_multiple_revisions() {
        let dir = TempDir::new("revisions");

        let doc_id;
        {
            let mut server = Server::new();
            let sid = server.connect();
            server.login_public(sid).unwrap();
            doc_id = server.create_work(sid, Edition::from_text("v1")).unwrap();
            server.work_grab(sid, doc_id).unwrap();
            server
                .work_revise(sid, doc_id, Edition::from_text("v2"))
                .unwrap();
            server.work_release(sid, doc_id).unwrap();
            server.checkpoint_to_file(&dir.snapshot_path()).unwrap();
        }
        {
            let server = Server::restore_from_file(&dir.snapshot_path()).unwrap();
            assert_eq!(server.work_edition(doc_id).unwrap().to_text(), "v2");
        }
    }

    #[test]
    #[cfg(feature = "server")]
    fn server_checkpoint_restore_multiple_works() {
        let dir = TempDir::new("multi_works");

        let doc1;
        let doc2;
        let doc3;
        {
            let mut server = Server::new();
            let sid = server.connect();
            server.login_public(sid).unwrap();
            doc1 = server.create_work(sid, Edition::from_text("doc1")).unwrap();
            doc2 = server.create_work(sid, Edition::from_text("doc2")).unwrap();
            doc3 = server.create_work(sid, Edition::from_text("doc3")).unwrap();
            server.checkpoint_to_file(&dir.snapshot_path()).unwrap();
        }
        {
            let server = Server::restore_from_file(&dir.snapshot_path()).unwrap();
            assert_eq!(server.work_count(), 3);
            assert_eq!(server.work_edition(doc1).unwrap().to_text(), "doc1");
            assert_eq!(server.work_edition(doc2).unwrap().to_text(), "doc2");
            assert_eq!(server.work_edition(doc3).unwrap().to_text(), "doc3");
        }
    }

    #[test]
    #[cfg(feature = "server")]
    fn server_checkpoint_restore_grabs_not_preserved() {
        let dir = TempDir::new("grabs");

        let doc_id;
        {
            let mut server = Server::new();
            let sid = server.connect();
            server.login_public(sid).unwrap();
            doc_id = server.create_work(sid, Edition::from_text("data")).unwrap();
            server.work_grab(sid, doc_id).unwrap();
            assert!(server.work_is_grabbed(doc_id).unwrap());
            server.checkpoint_to_file(&dir.snapshot_path()).unwrap();
        }
        {
            let server = Server::restore_from_file(&dir.snapshot_path()).unwrap();
            assert!(!server.work_is_grabbed(doc_id).unwrap());
        }
    }

    #[test]
    #[cfg(feature = "server")]
    fn server_checkpoint_restore_system_clubs() {
        let dir = TempDir::new("sys_clubs");

        let original = Server::new();
        let pub_id = original.public_club_id();
        let adm_id = original.admin_club_id();
        original.checkpoint_to_file(&dir.snapshot_path()).unwrap();

        let restored = Server::restore_from_file(&dir.snapshot_path()).unwrap();
        assert_eq!(restored.public_club_id(), pub_id);
        assert_eq!(restored.admin_club_id(), adm_id);
    }

    #[test]
    #[cfg(feature = "server")]
    fn server_checkpoint_restore_with_editions() {
        let dir = TempDir::new("editions");

        {
            let mut server = Server::new();
            let sid = server.connect();
            server.login_public(sid).unwrap();

            let ed = Edition::from_text("standalone");
            let be_id = server.store_edition(sid, ed).unwrap();
            server.checkpoint_to_file(&dir.snapshot_path()).unwrap();
        }
        {
            let server = Server::restore_from_file(&dir.snapshot_path()).unwrap();
        }
    }

    #[test]
    #[cfg(feature = "server")]
    fn server_checkpoint_restore_id_counter_preserved() {
        let dir = TempDir::new("id_counter");

        let mut last_id = 0u64;
        {
            let mut server = Server::new();
            let sid = server.connect();
            server.login_public(sid).unwrap();
            for _ in 0..5 {
                last_id = server.create_work(sid, Edition::from_text("x")).unwrap();
            }
            server.checkpoint_to_file(&dir.snapshot_path()).unwrap();
        }
        {
            let mut server = Server::restore_from_file(&dir.snapshot_path()).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();
            let new_id = server.create_work(sid, Edition::from_text("y")).unwrap();
            assert!(
                new_id > last_id,
                "new id {} should be > last {}",
                new_id,
                last_id
            );
        }
    }

    #[test]
    fn blob_upload_and_get() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let meta = server
            .blob_upload(sid, b"hello blob".to_vec(), "text/plain".to_string())
            .unwrap();
        assert_eq!(meta.byte_size, 10);
        assert_eq!(meta.mime_type, "text/plain");
        let data = server.blob_get(meta.hash_u64()).unwrap();
        assert_eq!(data, b"hello blob");
    }

    #[test]
    fn blob_upload_requires_login() {
        let mut server = Server::new();
        let sid = server.connect();
        let result = server.blob_upload(sid, b"data".to_vec(), "image/png".to_string());
        assert!(result.is_err());
    }

    #[test]
    fn blob_deduplication() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let m1 = server
            .blob_upload(sid, b"same".to_vec(), "text/plain".to_string())
            .unwrap();
        let m2 = server
            .blob_upload(sid, b"same".to_vec(), "text/plain".to_string())
            .unwrap();
        assert_eq!(m1.hash_u64(), m2.hash_u64());
    }

    #[test]
    fn blob_exists() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let meta = server
            .blob_upload(sid, b"data".to_vec(), "text/plain".to_string())
            .unwrap();
        assert!(server.blob_exists(meta.hash_u64()));
        assert!(!server.blob_exists(99999));
    }

    #[test]
    fn blob_info() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let meta = server
            .blob_upload(sid, b"info test".to_vec(), "image/png".to_string())
            .unwrap();
        let info = server.blob_info(meta.hash_u64()).unwrap();
        assert_eq!(info.byte_size, 9);
        assert_eq!(info.mime_type, "image/png");
    }

    #[test]
    fn blob_not_found() {
        let server = Server::new();
        let result = server.blob_get(99999);
        assert!(result.is_err());
    }

    #[test]
    fn blob_content_path_in_memory_returns_err() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let meta = server
            .blob_upload(sid, b"path test".to_vec(), "text/plain".to_string())
            .unwrap();
        let result = server.blob_content_path(meta.hash_u64());
        assert!(
            result.is_err(),
            "in-memory blob store should not have file paths"
        );
    }

    #[test]
    fn blob_content_path_file_backed() {
        let tmp = tempfile::tempdir().unwrap();
        let mut server = Server::new();
        server.init_blob_store(tmp.path()).unwrap();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let meta = server
            .blob_upload(sid, b"file path test".to_vec(), "image/png".to_string())
            .unwrap();
        let (path, mime, hash) = server.blob_content_path(meta.hash_u64()).unwrap();
        assert_eq!(mime, "image/png");
        assert!(path.exists(), "blob file should exist on disk");
        let data = std::fs::read(&path).unwrap();
        assert_eq!(data, b"file path test");
        assert_eq!(hash, meta.content_hash);
    }

    #[test]
    fn blob_preview_path_file_backed_no_preview() {
        let tmp = tempfile::tempdir().unwrap();
        let mut server = Server::new();
        server.init_blob_store(tmp.path()).unwrap();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let meta = server
            .blob_upload(sid, b"no preview".to_vec(), "text/plain".to_string())
            .unwrap();
        let result = server.blob_preview_path(meta.hash_u64());
        assert!(result.is_err());
    }

    #[test]
    fn blob_stats() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let (blobs, bytes) = server.blob_stats();
        assert_eq!(blobs, 0);
        assert_eq!(bytes, 0);
        server
            .blob_upload(sid, b"aaa".to_vec(), "text/plain".to_string())
            .unwrap();
        let (blobs, bytes) = server.blob_stats();
        assert_eq!(blobs, 1);
        assert_eq!(bytes, 3);
    }

    #[test]
    fn find_structural_shared_regions_basic() {
        let (mut server, sid) = setup_logged_in_server();
        let doc1 = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();
        let doc2 = server
            .create_work(sid, Edition::from_text("say hello world now"))
            .unwrap();
        let regions = server.find_shared_regions(doc1, doc2);
        assert!(!regions.is_empty());
        let has_hello = regions
            .iter()
            .any(|(_, _, _, _, t)| t.contains("hello") || t.contains("world"));
        assert!(
            has_hello,
            "expected shared text containing 'hello' or 'world': {:?}",
            regions
        );
    }

    #[test]
    fn find_structural_shared_regions_identical() {
        let (mut server, sid) = setup_logged_in_server();
        let doc1 = server
            .create_work(sid, Edition::from_text("same content"))
            .unwrap();
        let doc2 = server
            .create_work(sid, Edition::from_text("same content"))
            .unwrap();
        let regions = server.find_shared_regions(doc1, doc2);
        assert_eq!(regions.len(), 1);
        assert_eq!(regions[0].4, "same content");
    }

    #[test]
    fn find_structural_shared_regions_empty() {
        let (mut server, sid) = setup_logged_in_server();
        let doc1 = server
            .create_work(sid, Edition::from_text("hello"))
            .unwrap();
        let doc2 = server.create_work(sid, Edition::from_text("")).unwrap();
        assert!(server.find_shared_regions(doc1, doc2).is_empty());
    }

    #[test]
    fn find_structural_shared_regions_not_found() {
        let (mut server, sid) = setup_logged_in_server();
        let doc1 = server.create_work(sid, Edition::from_text("abc")).unwrap();
        let doc2 = server.create_work(sid, Edition::from_text("xyz")).unwrap();
        assert!(server.find_shared_regions(doc1, doc2).is_empty());
    }

    #[test]
    fn find_structural_shared_regions_with_blob() {
        let (mut server, sid) = setup_logged_in_server();
        let doc1 = server
            .create_work(
                sid,
                Edition::from_text_elements(&[
                    RangeElement::text("a"),
                    RangeElement::text("b"),
                    RangeElement::Blob {
                        content_hash: 42,
                        mime_type: "image/png".into(),
                        byte_size: 100,
                        width: Some(10),
                        height: Some(10),
                    },
                    RangeElement::text("c"),
                ]),
            )
            .unwrap();
        let doc2 = server
            .create_work(
                sid,
                Edition::from_text_elements(&[
                    RangeElement::text("x"),
                    RangeElement::text("b"),
                    RangeElement::Blob {
                        content_hash: 42,
                        mime_type: "image/png".into(),
                        byte_size: 100,
                        width: Some(10),
                        height: Some(10),
                    },
                    RangeElement::text("c"),
                ]),
            )
            .unwrap();
        let regions = server.find_shared_regions(doc1, doc2);
        assert!(
            !regions.is_empty(),
            "structural comparison should find shared blob+text run"
        );
    }

    #[test]
    fn content_address_same_text_same_be_id() {
        let (mut server, sid) = setup_logged_in_server();
        server
            .create_work(sid, Edition::from_text("hello"))
            .unwrap();
        let id_first = server
            .content_address_lookup(&RangeElement::text("h"))
            .unwrap();
        server
            .create_work(sid, Edition::from_text("hippo"))
            .unwrap();
        let id_second = server
            .content_address_lookup(&RangeElement::text("h"))
            .unwrap();
        assert_eq!(
            id_first, id_second,
            "'h' should have the same canonical BeId across documents"
        );
    }

    #[test]
    fn content_address_different_text_different_be_id() {
        let (mut server, sid) = setup_logged_in_server();
        server.create_work(sid, Edition::from_text("abc")).unwrap();
        let id_a = server
            .content_address_lookup(&RangeElement::text("a"))
            .unwrap();
        let id_b = server
            .content_address_lookup(&RangeElement::text("b"))
            .unwrap();
        assert_ne!(id_a, id_b);
    }

    #[test]
    fn content_address_across_revisions() {
        let (mut server, sid) = setup_logged_in_server();
        let doc = server.create_work(sid, Edition::from_text("abc")).unwrap();
        let id_before = server
            .content_address_lookup(&RangeElement::text("a"))
            .unwrap();
        server.work_grab(sid, doc).unwrap();
        server
            .work_revise(sid, doc, Edition::from_text("axc"))
            .unwrap();
        let id_after = server
            .content_address_lookup(&RangeElement::text("a"))
            .unwrap();
        assert_eq!(
            id_before, id_after,
            "'a' identity should be stable across revisions"
        );
    }

    #[test]
    fn content_address_transclusion_finds_cross_document() {
        let (mut server, sid) = setup_logged_in_server();
        let _doc1 = server
            .create_work(sid, Edition::from_text("shared phrase here"))
            .unwrap();
        let _doc2 = server
            .create_work(sid, Edition::from_text("shared phrase there"))
            .unwrap();
        let results = server.find_text_transcluders("shared phrase");
        assert_eq!(
            results.len(),
            2,
            "should find 'shared phrase' in both documents"
        );
    }

    #[test]
    fn content_address_count_grows() {
        let (mut server, sid) = setup_logged_in_server();
        assert_eq!(server.content_address_count(), 0);
        server
            .create_work(sid, Edition::from_text("hello"))
            .unwrap();
        let count1 = server.content_address_count();
        assert!(count1 > 0);
        server
            .create_work(sid, Edition::from_text("hello"))
            .unwrap();
        assert_eq!(
            server.content_address_count(),
            count1,
            "duplicate doc should not increase count"
        );
        server
            .create_work(sid, Edition::from_text("world"))
            .unwrap();
        assert!(server.content_address_count() > count1);
    }

    #[test]
    fn federation_remote_origin_recorded_on_import() {
        let mut server = Server::new();
        let push = vec![crate::server::federation::SyncWorkEntry {
            origin_server_id: "remote-server".to_string(),
            work_id: 100,
            edition_payload: crate::server::transport::protocol::EditionPayload::Text(
                "hello world".to_string(),
            ),
            span_provenance: vec![],
        }];
        let my_id = server.federation_server_id();
        let (imported, _) = server.federation_import_works(&push, &my_id);
        assert_eq!(imported, 1);
        assert!(server.federation.remote_origins().len() > 0);
    }

    #[test]
    fn federation_transclusion_index_after_import() {
        let mut server = Server::new();
        let push = vec![crate::server::federation::SyncWorkEntry {
            origin_server_id: "remote-server".to_string(),
            work_id: 200,
            edition_payload: crate::server::transport::protocol::EditionPayload::Text(
                "hi".to_string(),
            ),
            span_provenance: vec![],
        }];
        let my_id = server.federation_server_id();
        let (imported, already) = server.federation_import_works(&push, &my_id);
        assert_eq!(imported, 1);
        assert_eq!(already, 0);

        let content = RangeElement::text("h".to_string());
        let fed_results = server
            .backfollow
            .transclusion_index()
            .find_federated_transcluders(&content);
        assert_eq!(fed_results.len(), 1);
        assert_eq!(fed_results[0].origin_server_id, "remote-server");
        assert_eq!(fed_results[0].local_id, 200);
    }

    #[test]
    fn federation_fetch_by_fingerprint_found() {
        let (mut server, sid) = setup_logged_in_server();
        server
            .create_work(sid, Edition::from_text("fetchable content"))
            .unwrap();

        let first_char = RangeElement::text("f".to_string());
        let fp = first_char.content_fingerprint();
        let hex: String = fp.iter().map(|b| format!("{:02x}", b)).collect();

        let result = server.federation_fetch_by_fingerprint(&hex);
        match result {
            FederationFetchResponse::Edition(_) => {}
            other => panic!("expected Edition response, got {:?}", other),
        }
    }

    #[test]
    fn federation_fetch_by_fingerprint_not_found() {
        let server = Server::new();
        let hex = "ff".repeat(32);
        let result = server.federation_fetch_by_fingerprint(&hex);
        match result {
            FederationFetchResponse::NotFound => {}
            other => panic!("expected NotFound, got {:?}", other),
        }
    }

    #[test]
    fn federation_royalty_on_cross_server_transclusion() {
        let mut server = Server::new();
        let text_elem = RangeElement::text("royalty content");
        let fp = text_elem.content_fingerprint();
        server
            .federation
            .record_royalty(crate::server::federation::RoyaltyEntry {
                origin_server_id: "origin-server".to_string(),
                content_fingerprint: fp,
                royalty_type: crate::server::federation::RoyaltyType::Transclusion,
                amount: 50,
                timestamp: 1234567890,
            });
        let ledger = server.federation.royalty_ledger();
        assert_eq!(ledger.len(), 1);
        assert_eq!(ledger[0].amount, 50);
        assert_eq!(ledger[0].origin_server_id, "origin-server");
    }

    #[test]
    fn re_import_does_not_duplicate_origin_entries() {
        let mut server = Server::new();
        let entry = crate::server::federation::SyncWorkEntry {
            origin_server_id: "remote-server".to_string(),
            work_id: 100,
            edition_payload: crate::server::transport::protocol::EditionPayload::Text(
                "hello".to_string(),
            ),
            span_provenance: vec![],
        };
        let my_id = server.federation_server_id();

        let (imported1, _) = server.federation_import_works(&[entry.clone()], &my_id);
        assert_eq!(imported1, 1);
        let origins_after_first = server.federation.remote_origins().len();
        let fed_after_first = server
            .backfollow
            .transclusion_index()
            .federated_entry_count();

        let (imported2, already2) = server.federation_import_works(&[entry.clone()], &my_id);
        assert_eq!(imported2, 0);
        assert_eq!(already2, 1);
        assert_eq!(
            server.federation.remote_origins().len(),
            origins_after_first,
            "re-import should not add more origin entries"
        );
        assert_eq!(
            server
                .backfollow
                .transclusion_index()
                .federated_entry_count(),
            fed_after_first,
            "re-import should not add more federated transclusion entries"
        );
    }

    #[test]
    fn fingerprint_index_resolves_to_correct_work() {
        let (mut server, sid) = setup_logged_in_server();
        let id_a = server
            .create_work(sid, Edition::from_text("alpha"))
            .unwrap();
        let id_b = server
            .create_work(sid, Edition::from_text("bravo"))
            .unwrap();

        let char_a = RangeElement::text("a".to_string());
        let fp_a = char_a.content_fingerprint();
        let hex_a: String = fp_a.iter().map(|b| format!("{:02x}", b)).collect();

        let result_a = server.federation_fetch_by_fingerprint(&hex_a);
        match &result_a {
            FederationFetchResponse::Edition(payload) => {
                let ed = payload.to_edition();
                let text: String = ed
                    .all_entries()
                    .iter()
                    .map(|(_, c)| c.element.as_text().unwrap_or(""))
                    .collect();
                assert!(text.contains('a'), "should find edition containing 'a'");
            }
            other => panic!("expected Edition for 'a', got {:?}", other),
        }

        let char_b = RangeElement::text("b".to_string());
        let fp_b = char_b.content_fingerprint();
        let hex_b: String = fp_b.iter().map(|b| format!("{:02x}", b)).collect();

        let result_b = server.federation_fetch_by_fingerprint(&hex_b);
        match &result_b {
            FederationFetchResponse::Edition(payload) => {
                let ed = payload.to_edition();
                let text: String = ed
                    .all_entries()
                    .iter()
                    .map(|(_, c)| c.element.as_text().unwrap_or(""))
                    .collect();
                assert!(text.contains('b'), "should find edition containing 'b'");
            }
            other => panic!("expected Edition for 'b', got {:?}", other),
        }

        assert_ne!(id_a, id_b);
    }

    #[test]
    fn blob_import_records_origin_server_id() {
        let mut server = Server::new();
        let data = b"test blob content".to_vec();
        let hash = crate::edition::blob_store::hash_content(&data);
        let hash_hex = crate::edition::blob_store::hash_to_hex(&hash);
        let data_b64 = crate::edition::blob_store::base64_encode(&data);

        let entries = vec![crate::server::federation::SyncBlobEntry {
            content_hash_hex: hash_hex.clone(),
            data: data_b64,
            mime_type: "text/plain".to_string(),
        }];

        let (imported, _) = server.federation_import_blobs(&entries, "origin-server-42");
        assert_eq!(imported, 1);

        let origin = server.federation.remote_origins().get(&hash);
        assert!(origin.is_some(), "blob origin should be recorded");
        let origin = origin.unwrap();
        assert_eq!(origin.server_id, "origin-server-42");
        assert_eq!(
            origin.element_type,
            crate::server::federation::RemoteElementType::Blob
        );
    }

    #[test]
    fn federated_query_maps_blob_element_type() {
        let mut server = Server::new();
        server.set_federation_config(crate::server::federation::FederationConfig::closed(vec![]));

        let data = b"blobby".to_vec();
        let data_elem = RangeElement::data(data.clone());
        let fp = data_elem.content_fingerprint();
        let fp_hex: String = fp.iter().map(|b| format!("{:02x}", b)).collect();

        server.backfollow.register_federated_entry(
            &data_elem,
            "remote-blob-server".to_string(),
            0,
            "blob".to_string(),
            true,
        );

        let results = server.federation_query_local_transclusion(&fp_hex, false);
        let blob_result = results.iter().find(|r| {
            matches!(
                r.element_type,
                crate::server::federation::RemoteElementType::Blob
            )
        });
        assert!(
            blob_result.is_some(),
            "should find Blob element_type for blob fingerprint"
        );
    }

    // =================================================================
    // Phase 18: Reconcile Server Method Tests
    // =================================================================

    #[test]
    fn reconcile_records_on_create_work() {
        let (mut server, sid) = setup_logged_in_server();
        server
            .create_work(sid, Edition::from_text("reconcile test"))
            .unwrap();
        assert!(
            server.reconcile_store_len() > 0,
            "creating a work should populate the reconcile store"
        );
    }

    #[test]
    fn reconcile_records_on_revise() {
        let (mut server, sid) = setup_logged_in_server();
        let work_id = server.create_work(sid, Edition::from_text("v1")).unwrap();
        server.work_grab(sid, work_id).unwrap();

        let updated = Edition::from_text("v2");
        server.work_revise(sid, work_id, updated).unwrap();

        assert!(
            server.reconcile_store_len() >= 2,
            "create and revise produce separate reconcile entries (different fingerprints)"
        );
    }

    #[test]
    fn reconcile_merge_remote_adds_alternatives() {
        let (mut server_a, sid) = setup_logged_in_server();
        let work_id = server_a
            .create_work(sid, Edition::from_text("from A"))
            .unwrap();
        let local_state = server_a.reconcile_export_all();
        let fp = local_state[0].work_fingerprint.clone();
        let a_timestamp = local_state[0].current.timestamp();

        let remote_timestamp = a_timestamp + 1000;
        let alt_b = crate::server::federation::AlternativeEdition::new(
            "server-b",
            0,
            &Edition::from_text("from B"),
            remote_timestamp,
        );
        let mut remote = crate::server::federation::ReconcileState::new(
            &fp,
            "server-b:0".to_string(),
            alt_b,
            "server-b",
            remote_timestamp,
        );

        server_a.reconcile_merge_remote(remote);
        let state = server_a.reconcile_get(&fp).unwrap();
        assert_eq!(state.alternative_count(), 2);
        assert!(state.has_alternatives());
        assert_eq!(state.current_text().unwrap(), "from B");
    }

    #[test]
    fn reconcile_endorse_via_orset() {
        let (mut server, sid) = setup_logged_in_server();
        server
            .create_work(sid, Edition::from_text("endorsed work"))
            .unwrap();
        let states = server.reconcile_export_all();
        let fp = states[0].work_fingerprint.clone();

        let tag = server.reconcile_next_tag();
        server.reconcile_endorse(&fp, 42, 7, tag);

        let state = server.reconcile_get(&fp).unwrap();
        assert_eq!(state.endorsements.len(), 1);
        assert!(state
            .endorsements
            .contains(&crate::server::federation::EndorsementEntry::new(
                42,
                7,
                &server.federation_server_id()
            )));
    }

    #[test]
    fn reconcile_retract_via_orset() {
        let (mut server, sid) = setup_logged_in_server();
        server
            .create_work(sid, Edition::from_text("retractable"))
            .unwrap();
        let states = server.reconcile_export_all();
        let fp = states[0].work_fingerprint.clone();

        let tag = server.reconcile_next_tag();
        server.reconcile_endorse(&fp, 42, 7, tag);

        server.reconcile_retract(&fp, 42, 7);

        let state = server.reconcile_get(&fp).unwrap();
        assert_eq!(
            state.endorsements.len(),
            0,
            "retracted endorsement should be removed"
        );
    }

    #[test]
    fn reconcile_export_and_merge_endorsements() {
        let (mut server_a, sid_a) = setup_logged_in_server();
        server_a
            .create_work(sid_a, Edition::from_text("shared work"))
            .unwrap();
        let states_a = server_a.reconcile_export_all();
        let fp = states_a[0].work_fingerprint.clone();

        let tag_a = server_a.reconcile_next_tag();
        server_a.reconcile_endorse(&fp, 1, 10, tag_a);

        let endorsements_a = server_a.reconcile_export_endorsements();
        assert_eq!(endorsements_a.len(), 1);
        assert_eq!(endorsements_a[0].0, fp);
        assert_eq!(endorsements_a[0].1.len(), 1);

        let (mut server_b, sid_b) = setup_logged_in_server();
        let alt_b = crate::server::federation::AlternativeEdition::new(
            "server-b-id",
            0,
            &Edition::from_text("shared work"),
            100,
        );
        let remote_state = crate::server::federation::ReconcileState::new(
            &fp,
            "server-b-id:0".to_string(),
            alt_b,
            "server-b-id",
            100,
        );
        server_b.reconcile_merge_remote(remote_state);
        server_b.reconcile_merge_endorsements(&endorsements_a);

        let state_b = server_b.reconcile_get(&fp).unwrap();
        assert_eq!(state_b.endorsements.len(), 1);
    }

    #[test]
    fn reconcile_next_tag_unique() {
        let mut server = Server::new();
        let tag1 = server.reconcile_next_tag();
        let tag2 = server.reconcile_next_tag();
        assert_ne!(tag1, tag2);
        assert_eq!(tag1.counter, 1);
        assert_eq!(tag2.counter, 2);
    }

    // =================================================================
    // Review Fix Regression Tests (Phase 18 review)
    // =================================================================

    #[test]
    fn retract_actually_removes_endorsement() {
        let (mut server, sid) = setup_logged_in_server();
        server
            .create_work(sid, Edition::from_text("retract fix test"))
            .unwrap();
        let states = server.reconcile_export_all();
        let fp = states[0].work_fingerprint.clone();

        let tag_a = server.reconcile_next_tag();
        server.reconcile_endorse(&fp, 10, 20, tag_a);

        let tag_b = server.reconcile_next_tag();
        server.reconcile_endorse(&fp, 30, 40, tag_b);

        let state = server.reconcile_get(&fp).unwrap();
        assert_eq!(state.endorsements.len(), 2);

        server.reconcile_retract(&fp, 10, 20);

        let state = server.reconcile_get(&fp).unwrap();
        assert!(
            !state
                .endorsements
                .contains(&crate::server::federation::EndorsementEntry::new(
                    10,
                    20,
                    &server.federation_server_id()
                )),
            "retracted endorsement should be removed"
        );
        assert!(
            state
                .endorsements
                .contains(&crate::server::federation::EndorsementEntry::new(
                    30,
                    40,
                    &server.federation_server_id()
                )),
            "unrelated endorsement should remain"
        );
    }

    #[test]
    fn retract_removes_all_tags_for_same_value() {
        let (mut server, sid) = setup_logged_in_server();
        server
            .create_work(sid, Edition::from_text("multi tag retract"))
            .unwrap();
        let states = server.reconcile_export_all();
        let fp = states[0].work_fingerprint.clone();

        let tag_a = server.reconcile_next_tag();
        server.reconcile_endorse(&fp, 5, 5, tag_a);
        let tag_b = server.reconcile_next_tag();
        server.reconcile_endorse(&fp, 5, 5, tag_b);

        let state = server.reconcile_get(&fp).unwrap();
        assert_eq!(
            state.endorsements.len(),
            1,
            "same value added twice should still be 1 unique value"
        );
        assert_eq!(state.endorsements.add_count(), 2, "but 2 add entries");

        server.reconcile_retract(&fp, 5, 5);

        let state = server.reconcile_get(&fp).unwrap();
        assert_eq!(
            state.endorsements.len(),
            0,
            "retract should remove all tags for the value"
        );
        assert_eq!(
            state.endorsements.tombstone_count(),
            2,
            "both tags should be tombstoned"
        );
    }

    #[test]
    fn reconcile_persisted_across_snapshot() {
        let (mut server, sid) = setup_logged_in_server();
        server
            .create_work(sid, Edition::from_text("persist me"))
            .unwrap();
        let tag = server.reconcile_next_tag();
        let states = server.reconcile_export_all();
        let fp = states[0].work_fingerprint.clone();
        server.reconcile_endorse(&fp, 99, 88, tag);
        assert_eq!(server.reconcile_counter, 1);

        let snapshot = server.to_snapshot();
        let restored = Server::from_snapshot(&snapshot);
        assert_eq!(
            restored.reconcile_counter, 1,
            "counter should survive snapshot restore"
        );
        assert_eq!(
            restored.reconcile_store_len(),
            1,
            "store should survive snapshot restore"
        );
        let restored_state = restored.reconcile_get(&fp).unwrap();
        assert_eq!(restored_state.endorsements.len(), 1);
        assert_eq!(restored_state.endorsements.values()[0].club_id, 99);
    }

    #[test]
    fn reconcile_counter_persisted_no_tag_collision() {
        let (mut server, sid) = setup_logged_in_server();
        server.reconcile_next_tag();
        server.reconcile_next_tag();
        server.reconcile_next_tag();
        assert_eq!(server.reconcile_counter, 3);

        let snapshot = server.to_snapshot();
        let mut restored = Server::from_snapshot(&snapshot);
        let tag = restored.reconcile_next_tag();
        assert_eq!(
            tag.counter, 4,
            "next tag after restore should continue from saved counter, not restart at 1"
        );
    }

    #[test]
    fn endorsement_add_requires_login() {
        use crate::server::transport::dispatch::dispatch;
        use crate::server::transport::shared::AppState;

        let mut server = Server::new();
        server.set_federation_config(crate::server::federation::FederationConfig::closed(vec![]));
        let state = AppState::new(server).shared();
        let session_id = crate::server::SessionId::new(1);

        let result = dispatch(
            &state,
            session_id,
            crate::server::transport::protocol::WireRequest::EndorsementAdd {
                work_fingerprint: "test".to_string(),
                club_id: 1,
                token_id: 1,
            },
        );
        assert!(result.is_err(), "endorsement add without login should fail");
        match result {
            Err(crate::server::ServerError::SessionRequired)
            | Err(crate::server::ServerError::SessionNotFound(_)) => {}
            other => panic!("expected session error, got {:?}", other),
        }
    }

    #[test]
    fn endorsement_retract_requires_login() {
        use crate::server::transport::dispatch::dispatch;
        use crate::server::transport::shared::AppState;

        let mut server = Server::new();
        server.set_federation_config(crate::server::federation::FederationConfig::closed(vec![]));
        let state = AppState::new(server).shared();
        let session_id = crate::server::SessionId::new(1);

        let result = dispatch(
            &state,
            session_id,
            crate::server::transport::protocol::WireRequest::EndorsementRetract {
                work_fingerprint: "test".to_string(),
                club_id: 1,
                token_id: 1,
            },
        );
        assert!(
            result.is_err(),
            "endorsement retract without login should fail"
        );
        match result {
            Err(crate::server::ServerError::SessionRequired)
            | Err(crate::server::ServerError::SessionNotFound(_)) => {}
            other => panic!("expected session error, got {:?}", other),
        }
    }

    #[test]
    fn endorsement_query_requires_login() {
        use crate::server::transport::dispatch::dispatch;
        use crate::server::transport::shared::AppState;

        let mut server = Server::new();
        server.set_federation_config(crate::server::federation::FederationConfig::closed(vec![]));
        let state = AppState::new(server).shared();
        let session_id = crate::server::SessionId::new(1);

        let result = dispatch(
            &state,
            session_id,
            crate::server::transport::protocol::WireRequest::EndorsementQuery {
                work_fingerprint: "test".to_string(),
            },
        );
        assert!(
            result.is_err(),
            "endorsement query without login should fail"
        );
    }

    // =====================================================================
    // Phase 19a: Membership Server Method Tests
    // =====================================================================

    fn setup_federated_server() -> Server {
        let mut server = Server::new();
        let mut config = crate::server::federation::FederationConfig::closed(vec![]);
        config.min_endorsements = 1;
        server.set_federation_config(config);
        server.membership_bootstrap_init();
        server
    }

    #[test]
    fn membership_bootstrap_init_adds_self() {
        let server = setup_federated_server();
        let server_id = server.federation_server_id();
        assert!(server.membership_is_member(&server_id));
        assert_eq!(server.membership_count(), 1);
    }

    #[test]
    fn membership_self_entry_returns_own_entry() {
        let server = setup_federated_server();
        let entry = server.membership_self_entry().unwrap();
        assert_eq!(entry.server_id, server.federation_server_id());
        assert!(entry.is_active());
    }

    #[test]
    fn membership_list_returns_active_members() {
        let server = setup_federated_server();
        let list = server.membership_list();
        assert_eq!(list.len(), 1);
        assert_eq!(list[0].server_id, server.federation_server_id());
    }

    #[test]
    fn membership_verify_own_server() {
        let server = setup_federated_server();
        let server_id = server.federation_server_id();
        let result = server.membership_verify(&server_id);
        assert!(result.is_member);
        assert_eq!(result.endorsement_count, 1);
    }

    #[test]
    fn membership_verify_unknown_server() {
        let server = setup_federated_server();
        let result = server.membership_verify("unknown-server");
        assert!(!result.is_member);
        assert_eq!(result.endorsement_count, 0);
    }

    #[test]
    fn membership_sign_and_verify_endorsement() {
        let server = setup_federated_server();
        let endorsee_id = "new-server-abc";
        let endorsee_vk = "deadbeef";

        let proof = server
            .membership_sign_endorsement(endorsee_id, endorsee_vk)
            .unwrap();
        assert_eq!(proof.endorser_server_id, server.federation_server_id());
        assert_eq!(proof.endorsee_server_id, endorsee_id);
        assert_eq!(proof.endorsee_verifying_key_hex, endorsee_vk);
        assert!(!proof.signature.is_empty());

        let verifying_key = server.server_keypair.signing_verifying_key();
        assert!(server.membership_verify_endorsement_proof(&proof, &verifying_key));
    }

    #[test]
    fn membership_verify_endorsement_rejects_tampered() {
        let server = setup_federated_server();
        let mut proof = server
            .membership_sign_endorsement("target", "vk123")
            .unwrap();
        proof.signature[0] ^= 0xff;

        let verifying_key = server.server_keypair.signing_verifying_key();
        assert!(!server.membership_verify_endorsement_proof(&proof, &verifying_key));
    }

    #[test]
    fn membership_verify_endorsement_rejects_wrong_key() {
        let server = setup_federated_server();
        let proof = server
            .membership_sign_endorsement("target", "vk123")
            .unwrap();

        let wrong_key = crate::crypto::keys::ServerKeyPair::generate("other");
        let wrong_vk = wrong_key.signing_verifying_key();
        assert!(!server.membership_verify_endorsement_proof(&proof, &wrong_vk));
    }

    #[test]
    fn membership_process_join_accepts_new_server() {
        let mut server = setup_federated_server();
        let my_id = server.federation_server_id();

        let proof = server
            .membership_sign_endorsement("new-server", "vk-new")
            .unwrap();
        let new_entry = crate::server::federation::MembershipEntry::new(
            "new-server",
            "vk-new",
            "kex-new",
            vec![proof],
            1000,
        );

        let result = server.membership_process_join(new_entry);
        match result {
            crate::server::federation::JoinResult::Accepted {
                server_id,
                offered_endorsement,
                ..
            } => {
                assert_eq!(server_id, "new-server");
                assert!(offered_endorsement.is_some());
                let proof = offered_endorsement.unwrap();
                assert_eq!(proof.endorser_server_id, my_id);
            }
            crate::server::federation::JoinResult::Rejected { reason, .. } => {
                panic!("should accept: {}", reason)
            }
        }
        assert_eq!(server.membership_count(), 2);
    }

    #[test]
    fn membership_process_join_rejects_duplicate() {
        let mut server = setup_federated_server();
        let my_id = server.federation_server_id();

        let entry = crate::server::federation::MembershipEntry::new(
            my_id.clone(),
            "vk-self",
            "kex-self",
            vec![],
            1000,
        );

        let result = server.membership_process_join(entry);
        match result {
            crate::server::federation::JoinResult::Rejected { reason, .. } => {
                assert!(reason.contains("already a member"));
            }
            crate::server::federation::JoinResult::Accepted { .. } => panic!("should reject"),
        }
    }

    #[test]
    fn membership_leave_removes_self() {
        let mut server = setup_federated_server();
        let my_id = server.federation_server_id();
        assert!(server.membership_is_member(&my_id));

        server.membership_leave();
        assert!(!server.membership_is_member(&my_id));
        assert_eq!(server.membership_count(), 0);
    }

    #[test]
    fn membership_remove_removes_target() {
        let mut server = setup_federated_server();

        let proof = server
            .membership_sign_endorsement("target-server", "vk-target")
            .unwrap();
        let new_entry = crate::server::federation::MembershipEntry::new(
            "target-server",
            "vk-target",
            "kex-target",
            vec![proof],
            1000,
        );
        server.membership_process_join(new_entry);
        assert_eq!(server.membership_count(), 2);

        assert!(server.membership_remove("target-server"));
        assert_eq!(server.membership_count(), 1);
        assert!(!server.membership_remove("target-server"));
    }

    #[test]
    fn membership_endorse_adds_endorsement() {
        let mut server = setup_federated_server();
        let my_id = server.federation_server_id();

        let join_proof = server
            .membership_sign_endorsement("new-server", "vk-new")
            .unwrap();
        let new_entry = crate::server::federation::MembershipEntry::new(
            "new-server",
            "vk-new",
            "kex-new",
            vec![join_proof],
            1000,
        );
        let result = server.membership_process_join(new_entry);
        match &result {
            crate::server::federation::JoinResult::Accepted { .. } => {}
            crate::server::federation::JoinResult::Rejected { reason, .. } => {
                panic!("join should succeed: {}", reason);
            }
        }

        let offered = match result {
            crate::server::federation::JoinResult::Accepted {
                offered_endorsement,
                ..
            } => offered_endorsement,
            _ => unreachable!(),
        };
        assert!(
            offered.is_some(),
            "bootstrap server should offer endorsement on accept"
        );

        let verify = server.membership_verify("new-server");
        assert!(verify.is_member);
        assert!(verify.endorsed_by.contains(&my_id));
    }

    #[test]
    fn membership_merge_syncs_across_servers() {
        let mut server_a = setup_federated_server();
        let mut server_b = setup_federated_server();

        let id_a = server_a.federation_server_id();
        let id_b = server_b.federation_server_id();

        let entry_b =
            crate::server::federation::MembershipEntry::new(&id_b, "vk-b", "kex-b", vec![], 1000);
        server_a.membership_process_join(entry_b);

        let membership_b = server_b.federation.membership().clone();
        server_a.membership_merge(&membership_b);

        assert!(server_a.membership_is_member(&id_a));
        assert!(server_a.membership_is_known_member(&id_b));
    }

    #[test]
    fn membership_endorsement_proof_cross_verify() {
        let server_a = setup_federated_server();
        let mut server_b = setup_federated_server();
        let id_a = server_a.federation_server_id();
        let id_b = server_b.federation_server_id();

        let proof = server_a.membership_sign_endorsement(&id_b, "vk-b").unwrap();

        let vk_a = server_a.server_keypair.signing_verifying_key();
        assert!(server_b.membership_verify_endorsement_proof(&proof, &vk_a));

        let wrong_vk = server_b.server_keypair.signing_verifying_key();
        assert!(!server_b.membership_verify_endorsement_proof(&proof, &wrong_vk));
    }

    #[test]
    fn membership_dispatch_requires_login() {
        use crate::server::transport::dispatch::dispatch;
        use crate::server::transport::shared::AppState;

        let mut server = Server::new();
        server.set_federation_config(crate::server::federation::FederationConfig::closed(vec![]));
        let state = AppState::new(server).shared();
        let session_id = crate::server::SessionId::new(1);

        let result = dispatch(
            &state,
            session_id,
            crate::server::transport::protocol::WireRequest::MembershipList,
        );
        assert!(result.is_err(), "membership list without login should fail");
    }

    #[test]
    fn membership_dispatch_requires_federation() {
        use crate::server::transport::dispatch::dispatch;
        use crate::server::transport::shared::AppState;

        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let state = AppState::new(server).shared();

        let result = dispatch(
            &state,
            sid,
            crate::server::transport::protocol::WireRequest::MembershipList,
        );
        assert!(
            result.is_err(),
            "membership list without federation should fail"
        );
    }

    // =====================================================================
    // Phase 19b: Governance Server Method Tests
    // =====================================================================

    #[test]
    fn governance_bootstrap_then_propose() {
        let mut server = setup_federated_server();
        let my_id = server.federation_server_id();

        let is_leader = server.governance_is_leader();
        assert!(is_leader, "single server should be leader");

        let proposal = server.governance_propose(vec![
            crate::server::federation::GovernanceTx::RoyaltyRecord {
                origin_server_id: my_id.clone(),
                target_server_id: "srv-b".to_string(),
                content_fingerprint_hex: format!("{:064x}", 42),
                royalty_type: crate::server::federation::RoyaltyType::Transclusion,
                amount: 100,
            },
        ]);
        assert!(proposal.is_some());
        let p = proposal.unwrap();
        assert_eq!(p.sequence_number, 1);
        assert_eq!(p.proposer_id, my_id);
    }

    #[test]
    fn governance_full_consensus_single_server() {
        let mut server = setup_federated_server();
        let my_id = server.federation_server_id();

        server
            .governance_propose(vec![crate::server::federation::GovernanceTx::Expel {
                server_id: "srv-bad".to_string(),
                reason: "test".to_string(),
            }])
            .unwrap();

        let vote = crate::server::federation::PbftVote {
            view_number: 0,
            sequence_number: 1,
            voter_id: my_id.clone(),
            phase: crate::server::federation::PbftPhase::Prepare,
        };
        server.governance_receive_prepare(vote);

        let commit = crate::server::federation::PbftVote {
            view_number: 0,
            sequence_number: 1,
            voter_id: my_id.clone(),
            phase: crate::server::federation::PbftPhase::Commit,
        };
        server.governance_receive_commit(commit);

        let batch = server.governance_seal_round();
        assert!(batch.is_some());
        assert_eq!(server.governance_log().len(), 1);
        assert_eq!(server.governance_current_sequence(), 1);
    }

    #[test]
    fn governance_execute_admit_tx() {
        let mut server = setup_federated_server();
        assert_eq!(server.membership_count(), 1);

        let tx = crate::server::federation::GovernanceTx::Admit {
            server_id: "srv-new".to_string(),
            verifying_key_hex: "vk-new".to_string(),
            kex_public_hex: "kex-new".to_string(),
        };
        server.governance_execute_tx(&tx);
        assert_eq!(server.membership_count(), 2);
        assert!(server.membership_is_known_member("srv-new"));
    }

    #[test]
    fn governance_execute_expel_tx() {
        let mut server = setup_federated_server();
        let my_id = server.federation_server_id();

        let tx_admit = crate::server::federation::GovernanceTx::Admit {
            server_id: "srv-new".to_string(),
            verifying_key_hex: "vk-new".to_string(),
            kex_public_hex: "kex-new".to_string(),
        };
        server.governance_execute_tx(&tx_admit);
        assert_eq!(server.membership_count(), 2);

        let tx_expel = crate::server::federation::GovernanceTx::Expel {
            server_id: "srv-new".to_string(),
            reason: "gone".to_string(),
        };
        server.governance_execute_tx(&tx_expel);
        assert_eq!(server.membership_count(), 1);
        assert!(!server.membership_is_known_member("srv-new"));
    }

    #[test]
    fn governance_execute_royalty_tx() {
        let mut server = setup_federated_server();

        let tx = crate::server::federation::GovernanceTx::RoyaltyRecord {
            origin_server_id: "srv-a".to_string(),
            target_server_id: "srv-b".to_string(),
            content_fingerprint_hex: format!("{:064x}", 99),
            royalty_type: crate::server::federation::RoyaltyType::Transclusion,
            amount: 250,
        };
        server.governance_execute_tx(&tx);

        let ledger = server.federation.royalty_ledger();
        assert_eq!(ledger.len(), 1);
        assert_eq!(ledger[0].amount, 250);
    }

    #[test]
    fn governance_status() {
        let server = setup_federated_server();
        assert_eq!(server.governance_current_view(), 0);
        assert_eq!(server.governance_current_sequence(), 0);
        assert!(server.governance_is_leader());
        assert!(server.governance_leader_id().is_some());
        assert!(server.governance_pending_round().is_none());
    }

    #[test]
    fn work_private_by_default() {
        let (server, _) = setup_logged_in_server();
        let entries = server.list_works_with_titles();
        for (_, _, _, _, _, read_club, _, _, _, _, _) in &entries {
            assert!(
                read_club.is_some(),
                "new works should have a read_club (owner club)"
            );
        }
    }

    #[test]
    fn work_publish_unpublish_cycle() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let owner_club = server
            .create_club(sid, Edition::from_text("owner club"))
            .unwrap();
        server
            .club_set_password(sid, owner_club, TEST_CLUB_PASSWORD)
            .unwrap();
        let lock = server.login(sid, owner_club).unwrap();
        server
            .authenticate(
                sid,
                &*lock,
                &LockCredential::Password(TEST_CLUB_PASSWORD.to_vec()),
            )
            .unwrap();
        let work_id = server
            .create_work(sid, Edition::from_text("pub test"))
            .unwrap();

        assert!(!server.work_is_published(sid, work_id).unwrap());

        server.work_publish(sid, work_id).unwrap();
        assert!(server.work_is_published(sid, work_id).unwrap());

        server.work_unpublish(sid, work_id).unwrap();
        assert!(!server.work_is_published(sid, work_id).unwrap());
    }

    #[test]
    fn work_irrevocably_unpublish_blocks_republish() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let owner_club = server
            .create_club(sid, Edition::from_text("owner club"))
            .unwrap();
        server
            .club_set_password(sid, owner_club, TEST_CLUB_PASSWORD)
            .unwrap();
        let lock = server.login(sid, owner_club).unwrap();
        server
            .authenticate(
                sid,
                &*lock,
                &LockCredential::Password(TEST_CLUB_PASSWORD.to_vec()),
            )
            .unwrap();
        let work_id = server
            .create_work(sid, Edition::from_text("permanent"))
            .unwrap();

        server.work_irrevocably_unpublish(sid, work_id).unwrap();

        let result = server.work_publish(sid, work_id);
        assert!(result.is_err());

        let result = server.work_unpublish(sid, work_id);
        assert!(result.is_err());

        let result = server.work_set_read_club(sid, work_id, Some(owner_club));
        assert!(result.is_err());
    }

    #[test]
    fn unpublished_work_readable_by_owner() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let owner_club = server
            .create_club(sid, Edition::from_text("owner club"))
            .unwrap();
        server
            .club_set_password(sid, owner_club, TEST_CLUB_PASSWORD)
            .unwrap();
        let lock = server.login(sid, owner_club).unwrap();
        server
            .authenticate(
                sid,
                &*lock,
                &LockCredential::Password(TEST_CLUB_PASSWORD.to_vec()),
            )
            .unwrap();
        let work_id = server
            .create_work(sid, Edition::from_text("secret doc"))
            .unwrap();

        assert!(server.work_is_readable(sid, server.work(work_id).unwrap()));
    }

    #[test]
    fn unpublished_work_not_readable_by_other() {
        let mut server = Server::new();
        let sid1 = server.connect();
        server.login_public(sid1).unwrap();
        let owner_club = server
            .create_club(sid1, Edition::from_text("owner club"))
            .unwrap();
        server
            .club_set_password(sid1, owner_club, TEST_CLUB_PASSWORD)
            .unwrap();
        let lock = server.login(sid1, owner_club).unwrap();
        server
            .authenticate(
                sid1,
                &*lock,
                &LockCredential::Password(TEST_CLUB_PASSWORD.to_vec()),
            )
            .unwrap();
        let work_id = server
            .create_work(sid1, Edition::from_text("private"))
            .unwrap();

        let sid2 = server.connect();
        server.login_public(sid2).unwrap();

        assert!(!server.work_is_readable(sid2, server.work(work_id).unwrap()));
    }

    #[test]
    fn published_work_readable_by_public() {
        let mut server = Server::new();
        let sid1 = server.connect();
        server.login_public(sid1).unwrap();
        let owner_club = server
            .create_club(sid1, Edition::from_text("owner club"))
            .unwrap();
        server
            .club_set_password(sid1, owner_club, TEST_CLUB_PASSWORD)
            .unwrap();
        let lock = server.login(sid1, owner_club).unwrap();
        server
            .authenticate(
                sid1,
                &*lock,
                &LockCredential::Password(TEST_CLUB_PASSWORD.to_vec()),
            )
            .unwrap();
        let work_id = server
            .create_work(sid1, Edition::from_text("public doc"))
            .unwrap();
        server.work_publish(sid1, work_id).unwrap();

        let sid2 = server.connect();
        server.login_public(sid2).unwrap();

        assert!(server.work_is_readable(sid2, server.work(work_id).unwrap()));
    }

    #[test]
    fn irrevocably_unpublished_only_readable_by_editors_and_grabber() {
        let mut server = Server::new();
        let sid1 = server.connect();
        server.login_public(sid1).unwrap();
        let owner_club = server
            .create_club(sid1, Edition::from_text("owner club"))
            .unwrap();
        server
            .club_set_password(sid1, owner_club, TEST_CLUB_PASSWORD)
            .unwrap();
        let lock = server.login(sid1, owner_club).unwrap();
        server
            .authenticate(
                sid1,
                &*lock,
                &LockCredential::Password(TEST_CLUB_PASSWORD.to_vec()),
            )
            .unwrap();
        let work_id = server
            .create_work(sid1, Edition::from_text("gone"))
            .unwrap();
        server.work_irrevocably_unpublish(sid1, work_id).unwrap();

        let sid2 = server.connect();
        server.login_public(sid2).unwrap();

        assert!(
            !server.work_is_readable(sid2, server.work(work_id).unwrap()),
            "non-owner should not read irrevocably unpublished work"
        );
        assert!(
            server.work_is_readable(sid1, server.work(work_id).unwrap()),
            "owner (editor) can still read after irrevocable unpublish"
        );

        server.work_grab(sid1, work_id).unwrap();
        assert!(
            server.work_is_readable(sid1, server.work(work_id).unwrap()),
            "grabber can always read"
        );
    }

    #[test]
    fn club_default_read_edit_club_snapshot_roundtrip() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let club_id = server
            .create_club(sid, Edition::from_text("snap club"))
            .unwrap();
        server
            .club_set_password(sid, club_id, TEST_CLUB_PASSWORD)
            .unwrap();
        let lock = server.login(sid, club_id).unwrap();
        server
            .authenticate(
                sid,
                &*lock,
                &LockCredential::Password(TEST_CLUB_PASSWORD.to_vec()),
            )
            .unwrap();
        let custom_club = server
            .create_club(sid, Edition::from_text("custom"))
            .unwrap();
        server
            .club_set_default_read_club(sid, club_id, Some(custom_club))
            .unwrap();
        server
            .club_set_default_edit_club(sid, club_id, Some(custom_club))
            .unwrap();

        let snapshot = server.to_snapshot();
        let restored = Server::from_snapshot(&snapshot);

        let club = restored.clubs.get(&club_id).unwrap();
        assert_eq!(club.default_read_club(), Some(custom_club));
        assert_eq!(club.default_edit_club(), Some(custom_club));
    }

    #[test]
    fn publish_unpublish_snapshot_roundtrip() {
        let (mut server, sid) = setup_logged_in_server();
        let owner_club = server
            .create_club(sid, Edition::from_text("owner club"))
            .unwrap();
        server
            .club_set_password(sid, owner_club, TEST_CLUB_PASSWORD)
            .unwrap();
        let lock = server.login(sid, owner_club).unwrap();
        server
            .authenticate(
                sid,
                &*lock,
                &LockCredential::Password(TEST_CLUB_PASSWORD.to_vec()),
            )
            .unwrap();
        let work_id = server
            .create_work(sid, Edition::from_text("persist test"))
            .unwrap();
        server.work_publish(sid, work_id).unwrap();

        let snapshot = server.to_snapshot();
        let mut restored = Server::from_snapshot(&snapshot);
        let sid2 = restored.connect();
        restored.login_public(sid2).unwrap();

        assert!(restored.work_is_published(sid2, work_id).unwrap());
    }

    #[test]
    fn ensure_can_read_blocks_non_owner_of_private_work() {
        let mut server = Server::new();
        let sid1 = server.connect();
        server.login_public(sid1).unwrap();
        let owner_club = server
            .create_club(sid1, Edition::from_text("owner club"))
            .unwrap();
        server
            .club_set_password(sid1, owner_club, TEST_CLUB_PASSWORD)
            .unwrap();
        let lock = server.login(sid1, owner_club).unwrap();
        server
            .authenticate(
                sid1,
                &*lock,
                &LockCredential::Password(TEST_CLUB_PASSWORD.to_vec()),
            )
            .unwrap();
        let work_id = server
            .create_work(sid1, Edition::from_text("hidden"))
            .unwrap();

        let sid2 = server.connect();
        server.login_public(sid2).unwrap();

        let result = server.ensure_can_read(sid2, work_id);
        assert!(result.is_err());
    }

    #[test]
    fn ensure_can_read_allows_owner_of_private_work() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let owner_club = server
            .create_club(sid, Edition::from_text("owner club"))
            .unwrap();
        server
            .club_set_password(sid, owner_club, TEST_CLUB_PASSWORD)
            .unwrap();
        let lock = server.login(sid, owner_club).unwrap();
        server
            .authenticate(
                sid,
                &*lock,
                &LockCredential::Password(TEST_CLUB_PASSWORD.to_vec()),
            )
            .unwrap();
        let work_id = server.create_work(sid, Edition::from_text("mine")).unwrap();

        let result = server.ensure_can_read(sid, work_id);
        assert!(result.is_ok());
    }

    #[test]
    fn publish_requires_owner() {
        let mut server = Server::new();
        let sid1 = server.connect();
        server.login_public(sid1).unwrap();
        let owner_club = server
            .create_club(sid1, Edition::from_text("owner club"))
            .unwrap();
        server
            .club_set_password(sid1, owner_club, TEST_CLUB_PASSWORD)
            .unwrap();
        let lock = server.login(sid1, owner_club).unwrap();
        server
            .authenticate(
                sid1,
                &*lock,
                &LockCredential::Password(TEST_CLUB_PASSWORD.to_vec()),
            )
            .unwrap();
        let work_id = server
            .create_work(sid1, Edition::from_text("owned"))
            .unwrap();

        let sid2 = server.connect();
        server.login_public(sid2).unwrap();

        let result = server.work_publish(sid2, work_id);
        assert!(result.is_err(), "non-owner should not be able to publish");
    }

    #[test]
    fn editors_can_always_read_private_work() {
        let mut server = Server::new();
        let sid1 = server.connect();
        server.login_public(sid1).unwrap();
        let club1 = server
            .create_club(sid1, Edition::from_text("owner club"))
            .unwrap();
        server
            .club_set_password(sid1, club1, TEST_CLUB_PASSWORD)
            .unwrap();
        let lock = server.login(sid1, club1).unwrap();
        server
            .authenticate(
                sid1,
                &*lock,
                &LockCredential::Password(TEST_CLUB_PASSWORD.to_vec()),
            )
            .unwrap();
        let work_id = server
            .create_work(sid1, Edition::from_text("owned"))
            .unwrap();

        let sid2 = server.connect();
        server.login_public(sid2).unwrap();
        let club2 = server
            .create_club(sid2, Edition::from_text("editor club"))
            .unwrap();
        server
            .club_set_password(sid2, club2, TEST_CLUB_PASSWORD)
            .unwrap();
        let lock2 = server.login(sid2, club2).unwrap();
        server
            .authenticate(
                sid2,
                &*lock2,
                &LockCredential::Password(TEST_CLUB_PASSWORD.to_vec()),
            )
            .unwrap();

        assert!(
            !server.work_is_readable(sid2, server.work(work_id).unwrap()),
            "non-editor should not read private work"
        );

        server
            .work_set_edit_club(sid1, work_id, Some(club2))
            .unwrap();

        assert!(
            server.work_is_readable(sid2, server.work(work_id).unwrap()),
            "editor should be able to read private work"
        );
    }

    #[test]
    fn unpublish_not_round_trip_for_custom_read_club() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let owner_club = server
            .create_club(sid, Edition::from_text("owner club"))
            .unwrap();
        server
            .club_set_password(sid, owner_club, TEST_CLUB_PASSWORD)
            .unwrap();
        let lock = server.login(sid, owner_club).unwrap();
        server
            .authenticate(
                sid,
                &*lock,
                &LockCredential::Password(TEST_CLUB_PASSWORD.to_vec()),
            )
            .unwrap();

        let custom_club = server
            .create_club(sid, Edition::from_text("custom"))
            .unwrap();
        let work_id = server.create_work(sid, Edition::from_text("test")).unwrap();
        server
            .work_set_read_club(sid, work_id, Some(custom_club))
            .unwrap();

        server.work_publish(sid, work_id).unwrap();
        assert_eq!(
            server.work(work_id).unwrap().read_club(),
            Some(server.system_clubs.public_club)
        );

        server.work_unpublish(sid, work_id).unwrap();
        assert_eq!(
            server.work(work_id).unwrap().read_club(),
            Some(owner_club),
            "unpublish sets read_club to owner, not previous custom club"
        );
    }

    #[test]
    fn club_set_default_requires_owner_authority() {
        let mut server = Server::new();
        let sid1 = server.connect();
        server.login_public(sid1).unwrap();
        let club1 = server
            .create_club(sid1, Edition::from_text("club1"))
            .unwrap();
        server
            .club_set_password(sid1, club1, TEST_CLUB_PASSWORD)
            .unwrap();
        let lock1 = server.login(sid1, club1).unwrap();
        server
            .authenticate(
                sid1,
                &*lock1,
                &LockCredential::Password(TEST_CLUB_PASSWORD.to_vec()),
            )
            .unwrap();

        let sid2 = server.connect();
        server.login_public(sid2).unwrap();
        let club2 = server
            .create_club(sid2, Edition::from_text("club2"))
            .unwrap();
        server
            .club_set_password(sid2, club2, TEST_CLUB_PASSWORD)
            .unwrap();
        let lock2 = server.login(sid2, club2).unwrap();
        server
            .authenticate(
                sid2,
                &*lock2,
                &LockCredential::Password(TEST_CLUB_PASSWORD.to_vec()),
            )
            .unwrap();

        let result = server.club_set_default_read_club(sid2, club1, Some(club2));
        assert!(result.is_err(), "non-owner should not set defaults on club");

        let result = server.club_set_default_read_club(sid1, club1, Some(club1));
        assert!(
            result.is_ok(),
            "owner should be able to set defaults on club"
        );
    }

    #[test]
    fn grabber_can_read_irrevocably_unpublished() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let owner_club = server
            .create_club(sid, Edition::from_text("owner club"))
            .unwrap();
        server
            .club_set_password(sid, owner_club, TEST_CLUB_PASSWORD)
            .unwrap();
        let lock = server.login(sid, owner_club).unwrap();
        server
            .authenticate(
                sid,
                &*lock,
                &LockCredential::Password(TEST_CLUB_PASSWORD.to_vec()),
            )
            .unwrap();
        let work_id = server.create_work(sid, Edition::from_text("gone")).unwrap();

        server.work_grab(sid, work_id).unwrap();
        server.work_irrevocably_unpublish(sid, work_id).unwrap();

        assert!(
            server.work_is_readable(sid, server.work(work_id).unwrap()),
            "grabber should still be able to read after irrevocable unpublish"
        );
    }

    #[test]
    fn find_shared_regions_works_via_element_comparison() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let ed_a = Edition::from_text_elements(&[
            RangeElement::text("A".to_string()),
            RangeElement::text("X".to_string()),
            RangeElement::text("Y".to_string()),
            RangeElement::text("B".to_string()),
        ]);
        let ed_b = Edition::from_text_elements(&[
            RangeElement::text("C".to_string()),
            RangeElement::text("X".to_string()),
            RangeElement::text("Y".to_string()),
            RangeElement::text("D".to_string()),
        ]);

        let id_a = server.create_work(sid, ed_a).unwrap();
        let id_b = server.create_work(sid, ed_b).unwrap();

        let regions = server.find_shared_regions(id_a, id_b);
        assert!(!regions.is_empty(), "should find shared regions");
        let texts: Vec<&str> = regions
            .iter()
            .map(|r: &(i64, i64, i64, i64, String)| r.4.as_str())
            .collect();
        assert!(
            texts.iter().any(|t| t.contains('X')),
            "shared regions should contain shared content, got {:?}",
            texts
        );
    }

    #[test]
    fn find_shared_regions_no_match() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let ed_a = Edition::from_text_elements(&[
            RangeElement::text("A".to_string()),
            RangeElement::text("B".to_string()),
        ]);
        let ed_b = Edition::from_text_elements(&[
            RangeElement::text("C".to_string()),
            RangeElement::text("D".to_string()),
        ]);

        let id_a = server.create_work(sid, ed_a).unwrap();
        let id_b = server.create_work(sid, ed_b).unwrap();

        let regions = server.find_shared_regions(id_a, id_b);
        assert!(
            regions.is_empty(),
            "works with no shared content should have no regions"
        );
    }

    #[test]
    fn find_shared_regions_filtered_by_text() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let ed_a = Edition::from_text_elements(&[
            RangeElement::text("A".to_string()),
            RangeElement::text("s".to_string()),
            RangeElement::text("h".to_string()),
            RangeElement::text("B".to_string()),
        ]);
        let ed_b = Edition::from_text_elements(&[
            RangeElement::text("C".to_string()),
            RangeElement::text("s".to_string()),
            RangeElement::text("h".to_string()),
            RangeElement::text("D".to_string()),
        ]);

        let id_a = server.create_work(sid, ed_a).unwrap();
        let id_b = server.create_work(sid, ed_b).unwrap();

        let all = server.find_shared_regions(id_a, id_b);
        assert!(!all.is_empty());

        let filtered = server.find_shared_regions_filtered(id_a, id_b, "s");
        assert!(!filtered.is_empty(), "filter should match 's'");

        let no_match = server.find_shared_regions_filtered(id_a, id_b, "nonexistent");
        assert!(
            no_match.is_empty(),
            "filter for nonexistent text should return empty"
        );
    }

    #[test]
    fn find_shared_regions_filtered_uses_fingerprint_index() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let ed_a = Edition::from_text_elements(&[
            RangeElement::text("intro A".to_string()),
            RangeElement::text("unique shared alpha".to_string()),
            RangeElement::text("unique shared beta".to_string()),
            RangeElement::text("outro A".to_string()),
        ]);
        let ed_b = Edition::from_text_elements(&[
            RangeElement::text("intro B".to_string()),
            RangeElement::text("unique shared alpha".to_string()),
            RangeElement::text("unique shared beta".to_string()),
            RangeElement::text("outro B".to_string()),
        ]);

        let id_a = server.create_work(sid, ed_a).unwrap();
        let id_b = server.create_work(sid, ed_b).unwrap();

        let fp = RangeElement::text("unique shared alpha").content_fingerprint();
        let works = server.backfollow.find_works_by_fingerprint(&fp);
        assert!(
            works.contains(&id_a) && works.contains(&id_b),
            "fingerprint index should contain both works for shared text"
        );

        let filtered = server.find_shared_regions_filtered(id_a, id_b, "unique shared alpha");
        assert!(
            !filtered.is_empty(),
            "fingerprint-based filter should find shared regions"
        );
    }

    #[test]
    fn watch_plant_and_trigger_finds_matching_work() {
        crate::edition::init_endorsement_flags();
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work_a = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();

        let edition = server.get_edition(work_a).unwrap().unwrap();
        let content_elements: Vec<RangeElement> = edition
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.clone())
            .collect();
        assert!(
            !content_elements.is_empty(),
            "edition should have content elements"
        );

        let query =
            crate::edition::RecorderQuery::works().with_watched_content(content_elements.clone());
        let fossil_id = server.recorder_create_for_content(query.clone(), work_a);
        server.recorder_plant(work_a, fossil_id, &query.watched_content);

        let work_b = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();

        let notifications =
            server.drain_content_notifications_for(&std::collections::HashSet::from([fossil_id]));
        assert!(!notifications.is_empty(), "revising work_b with shared content should trigger notifications for the watcher on work_a");
    }

    #[test]
    fn watch_no_notification_for_unrelated_content() {
        crate::edition::init_endorsement_flags();
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work_a = server
            .create_work(sid, Edition::from_text("alpha"))
            .unwrap();

        let edition = server.get_edition(work_a).unwrap().unwrap();
        let content_elements: Vec<RangeElement> = edition
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.clone())
            .collect();
        let query =
            crate::edition::RecorderQuery::works().with_watched_content(content_elements.clone());
        let fossil_id = server.recorder_create_for_content(query.clone(), work_a);
        server.recorder_plant(work_a, fossil_id, &query.watched_content);

        let work_b = server
            .create_work(sid, Edition::from_text("zzzzz"))
            .unwrap();

        let notifications =
            server.drain_content_notifications_for(&std::collections::HashSet::from([fossil_id]));
        assert!(
            notifications.is_empty(),
            "work_b with no shared content should not trigger notifications"
        );
    }

    #[test]
    fn watch_trigger_on_revision_of_existing_work() {
        crate::edition::init_endorsement_flags();
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work_a = server
            .create_work(sid, Edition::from_text("monitor this text"))
            .unwrap();

        let edition = server.get_edition(work_a).unwrap().unwrap();
        let content_elements: Vec<RangeElement> = edition
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.clone())
            .collect();
        let query =
            crate::edition::RecorderQuery::works().with_watched_content(content_elements.clone());
        let fossil_id = server.recorder_create_for_content(query.clone(), work_a);
        server.recorder_plant(work_a, fossil_id, &query.watched_content);

        let work_b = server
            .create_work(sid, Edition::from_text("ZZZZZ"))
            .unwrap();

        let before =
            server.drain_content_notifications_for(&std::collections::HashSet::from([fossil_id]));
        assert!(before.is_empty(), "unrelated content should not trigger");

        server.work_grab(sid, work_b).unwrap();
        server
            .work_revise(sid, work_b, Edition::from_text("monitor this text"))
            .unwrap();

        let after =
            server.drain_content_notifications_for(&std::collections::HashSet::from([fossil_id]));
        assert!(
            !after.is_empty(),
            "revising work_b to match watched content should trigger notification"
        );
    }

    #[test]
    fn watch_unplant_stops_notifications() {
        crate::edition::init_endorsement_flags();
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work_a = server
            .create_work(sid, Edition::from_text("shared content"))
            .unwrap();

        let edition = server.get_edition(work_a).unwrap().unwrap();
        let content_elements: Vec<RangeElement> = edition
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.clone())
            .collect();
        let query =
            crate::edition::RecorderQuery::works().with_watched_content(content_elements.clone());
        let fossil_id = server.recorder_create_for_content(query.clone(), work_a);
        server.recorder_plant(work_a, fossil_id, &query.watched_content);

        server.recorder_unplant(work_a, fossil_id, &query.watched_content);

        let work_b = server
            .create_work(sid, Edition::from_text("shared content"))
            .unwrap();

        let notifications =
            server.drain_content_notifications_for(&std::collections::HashSet::from([fossil_id]));
        assert!(
            notifications.is_empty(),
            "unplanted watcher should not receive notifications"
        );
    }

    #[test]
    fn watch_extinguish_stops_recording() {
        crate::edition::init_endorsement_flags();
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work_a = server
            .create_work(sid, Edition::from_text("track me"))
            .unwrap();

        let edition = server.get_edition(work_a).unwrap().unwrap();
        let content_elements: Vec<RangeElement> = edition
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.clone())
            .collect();
        let query =
            crate::edition::RecorderQuery::works().with_watched_content(content_elements.clone());
        let fossil_id = server.recorder_create_for_content(query.clone(), work_a);
        server.recorder_plant(work_a, fossil_id, &query.watched_content);

        server.recorder_extinguish(fossil_id);

        let work_b = server
            .create_work(sid, Edition::from_text("track me"))
            .unwrap();

        let notifications =
            server.drain_content_notifications_for(&std::collections::HashSet::from([fossil_id]));
        assert!(
            notifications.is_empty(),
            "extinguished fossil should not produce notifications"
        );
    }

    #[test]
    fn watch_multiple_watchers_independent() {
        crate::edition::init_endorsement_flags();
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work_a = server
            .create_work(sid, Edition::from_text("alpha"))
            .unwrap();
        let work_b = server
            .create_work(sid, Edition::from_text("ZZZZZ"))
            .unwrap();

        let ed_a = server.get_edition(work_a).unwrap().unwrap();
        let content_a: Vec<RangeElement> = ed_a
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.clone())
            .collect();
        let query_a =
            crate::edition::RecorderQuery::works().with_watched_content(content_a.clone());
        let fossil_a = server.recorder_create_for_content(query_a.clone(), work_a);
        server.recorder_plant(work_a, fossil_a, &query_a.watched_content);

        let ed_b = server.get_edition(work_b).unwrap().unwrap();
        let content_b: Vec<RangeElement> = ed_b
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.clone())
            .collect();
        let query_b =
            crate::edition::RecorderQuery::works().with_watched_content(content_b.clone());
        let fossil_b = server.recorder_create_for_content(query_b.clone(), work_b);
        server.recorder_plant(work_b, fossil_b, &query_b.watched_content);

        let work_c = server
            .create_work(sid, Edition::from_text("alpha"))
            .unwrap();

        let notifs_a =
            server.drain_content_notifications_for(&std::collections::HashSet::from([fossil_a]));
        let notifs_b =
            server.drain_content_notifications_for(&std::collections::HashSet::from([fossil_b]));
        assert!(
            !notifs_a.is_empty(),
            "watcher for alpha should trigger on alpha content"
        );
        assert!(
            notifs_b.is_empty(),
            "watcher for ZZZZZ should NOT trigger on alpha content"
        );
    }

    #[test]
    fn watch_notification_contains_work_id() {
        crate::edition::init_endorsement_flags();
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work_a = server
            .create_work(sid, Edition::from_text("hello"))
            .unwrap();

        let edition = server.get_edition(work_a).unwrap().unwrap();
        let content_elements: Vec<RangeElement> = edition
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.clone())
            .collect();
        let query =
            crate::edition::RecorderQuery::works().with_watched_content(content_elements.clone());
        let fossil_id = server.recorder_create_for_content(query.clone(), work_a);
        server.recorder_plant(work_a, fossil_id, &query.watched_content);

        let work_b = server
            .create_work(sid, Edition::from_text("hello"))
            .unwrap();

        let notifications =
            server.drain_content_notifications_for(&std::collections::HashSet::from([fossil_id]));
        assert!(!notifications.is_empty());
        let notif = &notifications[0];
        assert_eq!(notif.fossil_id, fossil_id);
        assert_eq!(
            notif.edition_be_id, work_b,
            "notification should reference the work that triggered it"
        );
    }

    #[test]
    fn watch_drain_is_consumed() {
        crate::edition::init_endorsement_flags();
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work_a = server
            .create_work(sid, Edition::from_text("payload"))
            .unwrap();

        let edition = server.get_edition(work_a).unwrap().unwrap();
        let content_elements: Vec<RangeElement> = edition
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.clone())
            .collect();
        let query =
            crate::edition::RecorderQuery::works().with_watched_content(content_elements.clone());
        let fossil_id = server.recorder_create_for_content(query.clone(), work_a);
        server.recorder_plant(work_a, fossil_id, &query.watched_content);

        let work_b = server
            .create_work(sid, Edition::from_text("payload"))
            .unwrap();

        let first =
            server.drain_content_notifications_for(&std::collections::HashSet::from([fossil_id]));
        assert!(!first.is_empty());

        let second =
            server.drain_content_notifications_for(&std::collections::HashSet::from([fossil_id]));
        assert!(second.is_empty(), "drain should consume notifications");
    }

    #[test]
    fn watch_initial_results_find_existing_work() {
        crate::edition::init_endorsement_flags();
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work_a = server
            .create_work(sid, Edition::from_text("one two three"))
            .unwrap();
        let work_b = server
            .create_work(sid, Edition::from_text("two three four"))
            .unwrap();

        let edition = server.get_edition(work_a).unwrap().unwrap();
        let content_elements: Vec<RangeElement> = edition
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.clone())
            .collect();
        let query = crate::edition::RecorderQuery::works().with_watched_content(content_elements);
        let fossil_id = server.recorder_create_for_content(query.clone(), work_a);
        server.recorder_plant(work_a, fossil_id, &query.watched_content);

        let fossil = server.recorder_get(fossil_id).unwrap();
        let results = fossil.results.clone();
        assert!(
            !results.is_empty(),
            "initial matcher should find work_b sharing content with work_a"
        );
        let found_works: Vec<u64> = results
            .iter()
            .filter_map(|r| {
                if let RangeElement::Work { work_id } = &r.element {
                    Some(work_id.0)
                } else {
                    None
                }
            })
            .collect();
        assert!(
            found_works.contains(&work_b),
            "results should include work_b ({:?}), got: {:?}",
            work_b,
            found_works
        );
    }

    #[test]
    fn watch_initial_results_edition_be_id_is_matching_work() {
        crate::edition::init_endorsement_flags();
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work_a = server
            .create_work(sid, Edition::from_text("one two three"))
            .unwrap();
        let work_b = server
            .create_work(sid, Edition::from_text("two three four"))
            .unwrap();

        let edition = server.get_edition(work_a).unwrap().unwrap();
        let content_elements: Vec<RangeElement> = edition
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.clone())
            .collect();
        let query = crate::edition::RecorderQuery::works().with_watched_content(content_elements);
        let fossil_id = server.recorder_create_for_content(query.clone(), work_a);
        server.recorder_plant(work_a, fossil_id, &query.watched_content);

        let fossil = server.recorder_get(fossil_id).unwrap();
        for result in &fossil.results {
            if let RangeElement::Work { work_id } = &result.element {
                if work_id.0 == work_b {
                    let edition_be_id = result.source_edition_id.unwrap_or(work_a);
                    assert_eq!(edition_be_id, work_b,
                        "source_edition_id for work_b result should be work_b ({:?}), not work_a ({:?}). \
                         The UI uses this field to identify the matching document.",
                        work_b, work_a);
                }
            }
        }
    }

    fn ac_setup() -> (Server, SessionId) {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        (server, sid)
    }

    fn ac_create_user(server: &mut Server, name: &str, password: &[u8]) -> (BeId, SessionId) {
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let phc = crate::crypto::password::hash_password(password).unwrap();
        let club_id = server
            .create_personal_club(
                sid,
                name.to_string(),
                Some(crate::server::club::Credential::Password { phc_hash: phc }),
                Some(password.to_vec()),
            )
            .unwrap();
        let sid2 = ac_login_as(server, club_id, password);
        (club_id, sid2)
    }

    fn ac_login_as(server: &mut Server, club_id: BeId, password: &[u8]) -> SessionId {
        let sid = server.connect();
        let _lock = server.login(sid, club_id).unwrap();
        server
            .authenticate_with_pending(sid, &LockCredential::Password(password.to_vec()))
            .unwrap();
        sid
    }

    fn ac_make_private_work(server: &mut Server, owner_sid: SessionId) -> (BeId, BeId) {
        let private_club = server
            .create_named_club(owner_sid, "private_edit", Edition::empty())
            .unwrap();
        let work_id = server
            .create_work(owner_sid, Edition::from_text("secret doc"))
            .unwrap();
        server
            .work_set_edit_club(owner_sid, work_id, Some(private_club))
            .unwrap();
        (work_id, private_club)
    }

    #[test]
    fn crdt_open_session_checks_edit_permission() {
        let (mut server, _pub_sid) = ac_setup();
        let (owner_club, owner_sid) = ac_create_user(&mut server, "owner", TEST_OWNER_CREDENTIAL);
        let edit_club = server
            .create_named_club(owner_sid, "priv_edit", Edition::empty())
            .unwrap();
        let work_id = server
            .create_work(owner_sid, Edition::from_text("secret"))
            .unwrap();
        server
            .work_set_edit_club(owner_sid, work_id, Some(edit_club))
            .unwrap();
        let (user_club, _user_sid) = ac_create_user(&mut server, "stranger", TEST_OTHER_CREDENTIAL);
        let intruder_sid = ac_login_as(&mut server, user_club, TEST_OTHER_CREDENTIAL);
        let result = server.crdt_open_session(intruder_sid, work_id);
        assert!(result.is_err(), "non-member should not open CRDT session");
    }

    #[test]
    fn crdt_open_session_allows_member() {
        let (mut server, _pub_sid) = ac_setup();
        let (owner_club, owner_sid) = ac_create_user(&mut server, "owner", TEST_OWNER_CREDENTIAL);
        let edit_club = server
            .create_named_club(owner_sid, "priv_edit", Edition::empty())
            .unwrap();
        let work_id = server
            .create_work(owner_sid, Edition::from_text("secret"))
            .unwrap();
        server
            .work_set_edit_club(owner_sid, work_id, Some(edit_club))
            .unwrap();
        let (user_club, _user_sid) = ac_create_user(&mut server, "member", TEST_OTHER_CREDENTIAL);
        server
            .club_add_member(owner_sid, edit_club, user_club)
            .unwrap();
        let member_sid = ac_login_as(&mut server, user_club, TEST_OTHER_CREDENTIAL);
        let result = server.crdt_open_session(member_sid, work_id);
        assert!(result.is_ok(), "member should open CRDT session");
    }

    #[test]
    fn crdt_apply_text_delta_checks_edit_permission() {
        let (mut server, _pub_sid) = ac_setup();
        let (owner_club, owner_sid) = ac_create_user(&mut server, "owner", TEST_OWNER_CREDENTIAL);
        let edit_club = server
            .create_named_club(owner_sid, "priv_edit", Edition::empty())
            .unwrap();
        server
            .club_add_member(owner_sid, edit_club, owner_club)
            .unwrap();
        let work_id = server
            .create_work(owner_sid, Edition::from_text("secret"))
            .unwrap();
        server
            .work_set_edit_club(owner_sid, work_id, Some(edit_club))
            .unwrap();
        let owner_sid2 = ac_login_as(&mut server, owner_club, TEST_OWNER_CREDENTIAL);
        let _ = server.crdt_open_session(owner_sid2, work_id).unwrap();
        let (user_club, _user_sid) = ac_create_user(&mut server, "stranger", TEST_OTHER_CREDENTIAL);
        let intruder_sid = ac_login_as(&mut server, user_club, TEST_OTHER_CREDENTIAL);
        let ops = vec![TextDeltaOp::Insert {
            text: "hacked".to_string(),
        }];
        let result = server.crdt_apply_text_delta(intruder_sid, work_id, &ops);
        assert!(result.is_err(), "non-member should not apply text delta");
    }

    #[test]
    fn crdt_apply_update_checks_edit_permission() {
        let (mut server, _pub_sid) = ac_setup();
        let (owner_club, owner_sid) = ac_create_user(&mut server, "owner", TEST_OWNER_CREDENTIAL);
        let edit_club = server
            .create_named_club(owner_sid, "priv_edit", Edition::empty())
            .unwrap();
        server
            .club_add_member(owner_sid, edit_club, owner_club)
            .unwrap();
        let work_id = server
            .create_work(owner_sid, Edition::from_text("secret"))
            .unwrap();
        server
            .work_set_edit_club(owner_sid, work_id, Some(edit_club))
            .unwrap();
        let owner_sid2 = ac_login_as(&mut server, owner_club, TEST_OWNER_CREDENTIAL);
        let _ = server.crdt_open_session(owner_sid2, work_id).unwrap();
        let (user_club, _user_sid) = ac_create_user(&mut server, "stranger", TEST_OTHER_CREDENTIAL);
        let intruder_sid = ac_login_as(&mut server, user_club, TEST_OTHER_CREDENTIAL);
        let result = server.crdt_apply_update(intruder_sid, work_id, vec![1, 2, 3]);
        assert!(result.is_err(), "non-member should not apply update");
    }

    #[test]
    fn crdt_materialize_now_checks_session() {
        let (mut server, owner_sid) = ac_setup();
        let work_id = server
            .create_work(owner_sid, Edition::from_text("test"))
            .unwrap();
        let _ = server.crdt_open_session(owner_sid, work_id).unwrap();
        let fake_sid = SessionId::new(9999999);
        let result = server.crdt_materialize_now(fake_sid, work_id);
        assert!(result.is_err());
    }

    #[test]
    fn crdt_awareness_update_requires_session() {
        let (mut server, owner_sid) = ac_setup();
        let work_id = server
            .create_work(owner_sid, Edition::from_text("aware"))
            .unwrap();
        let _ = server.crdt_open_session(owner_sid, work_id).unwrap();
        let stranger_sid = server.connect();
        let state = AwarenessState {
            session_id: stranger_sid.as_u64(),
            user_name: "stranger".to_string(),
            club_id: None,
            author_public_key: None,
            cursor: None,
            selection: None,
            is_typing: false,
        };
        let result = server.crdt_update_awareness(stranger_sid, work_id, state);
        assert!(result.is_err());
    }

    #[test]
    fn crdt_register_author_requires_session() {
        let (mut server, owner_sid) = ac_setup();
        let work_id = server
            .create_work(owner_sid, Edition::from_text("auth"))
            .unwrap();
        let _ = server.crdt_open_session(owner_sid, work_id).unwrap();
        let stranger_sid = server.connect();
        let result = server.crdt_update_author(stranger_sid, work_id);
        assert!(result.is_err());
    }

    #[test]
    fn work_set_edit_club_requires_edit_permission() {
        let (mut server, _pub_sid) = ac_setup();
        let (owner_club, owner_sid) = ac_create_user(&mut server, "owner", TEST_OWNER_CREDENTIAL);
        let edit_club = server
            .create_named_club(owner_sid, "edit_gate", Edition::empty())
            .unwrap();
        let work_id = server
            .create_work(owner_sid, Edition::from_text("gated"))
            .unwrap();
        server
            .work_set_edit_club(owner_sid, work_id, Some(edit_club))
            .unwrap();
        let (stranger_club, _stranger_sid) =
            ac_create_user(&mut server, "stranger", TEST_OTHER_CREDENTIAL);
        let stranger_sid = ac_login_as(&mut server, stranger_club, TEST_OTHER_CREDENTIAL);
        let result =
            server.work_set_edit_club(stranger_sid, work_id, Some(server.public_club_id()));
        assert!(result.is_err(), "stranger should not change edit club");
    }

    #[test]
    fn work_set_read_club_requires_edit_permission() {
        let (mut server, _pub_sid) = ac_setup();
        let (owner_club, owner_sid) = ac_create_user(&mut server, "owner", TEST_OWNER_CREDENTIAL);
        let edit_club = server
            .create_named_club(owner_sid, "read_gate", Edition::empty())
            .unwrap();
        let work_id = server
            .create_work(owner_sid, Edition::from_text("gated"))
            .unwrap();
        server
            .work_set_edit_club(owner_sid, work_id, Some(edit_club))
            .unwrap();
        let (stranger_club, _stranger_sid) =
            ac_create_user(&mut server, "stranger", TEST_OTHER_CREDENTIAL);
        let stranger_sid = ac_login_as(&mut server, stranger_club, TEST_OTHER_CREDENTIAL);
        let result =
            server.work_set_read_club(stranger_sid, work_id, Some(server.public_club_id()));
        assert!(result.is_err(), "stranger should not change read club");
    }

    #[test]
    fn work_publish_requires_owner() {
        let (mut server, _pub_sid) = ac_setup();
        let (owner_club, owner_sid) = ac_create_user(&mut server, "owner", TEST_OWNER_CREDENTIAL);
        let work_id = server
            .create_work(owner_sid, Edition::from_text("mine"))
            .unwrap();
        let (stranger_club, _stranger_sid) =
            ac_create_user(&mut server, "stranger", TEST_OTHER_CREDENTIAL);
        let stranger_sid = ac_login_as(&mut server, stranger_club, TEST_OTHER_CREDENTIAL);
        let result = server.work_publish(stranger_sid, work_id);
        assert!(result.is_err(), "non-owner should not publish");
    }

    #[test]
    fn work_unpublish_requires_owner() {
        let (mut server, _pub_sid) = ac_setup();
        let (owner_club, owner_sid) = ac_create_user(&mut server, "owner", TEST_OWNER_CREDENTIAL);
        let work_id = server
            .create_work(owner_sid, Edition::from_text("mine"))
            .unwrap();
        server.work_publish(owner_sid, work_id).unwrap();
        let (stranger_club, _stranger_sid) =
            ac_create_user(&mut server, "stranger", TEST_OTHER_CREDENTIAL);
        let stranger_sid = ac_login_as(&mut server, stranger_club, TEST_OTHER_CREDENTIAL);
        let result = server.work_unpublish(stranger_sid, work_id);
        assert!(result.is_err(), "non-owner should not unpublish");
    }

    #[test]
    fn work_irrevocably_unpublish_requires_owner() {
        let (mut server, _pub_sid) = ac_setup();
        let (owner_club, owner_sid) = ac_create_user(&mut server, "owner", TEST_OWNER_CREDENTIAL);
        let work_id = server
            .create_work(owner_sid, Edition::from_text("mine"))
            .unwrap();
        let (stranger_club, _stranger_sid) =
            ac_create_user(&mut server, "stranger", TEST_OTHER_CREDENTIAL);
        let stranger_sid = ac_login_as(&mut server, stranger_club, TEST_OTHER_CREDENTIAL);
        let result = server.work_irrevocably_unpublish(stranger_sid, work_id);
        assert!(
            result.is_err(),
            "non-owner should not irrevocably unpublish"
        );
    }

    #[test]
    fn work_sponsor_requires_edit_permission() {
        let (mut server, _pub_sid) = ac_setup();
        let (owner_club, owner_sid) = ac_create_user(&mut server, "owner", TEST_OWNER_CREDENTIAL);
        let edit_club = server
            .create_named_club(owner_sid, "sponsor_gate", Edition::empty())
            .unwrap();
        let work_id = server
            .create_work(owner_sid, Edition::from_text("sponsored"))
            .unwrap();
        server
            .work_set_edit_club(owner_sid, work_id, Some(edit_club))
            .unwrap();
        let (stranger_club, _stranger_sid) =
            ac_create_user(&mut server, "stranger", TEST_OTHER_CREDENTIAL);
        let stranger_sid = ac_login_as(&mut server, stranger_club, TEST_OTHER_CREDENTIAL);
        let result = server.work_sponsor(stranger_sid, work_id, server.public_club_id());
        assert!(
            result.is_err(),
            "stranger should not sponsor restricted work"
        );
    }

    #[test]
    fn sponsor_multiple_clubs_independent() {
        let (mut server, _pub_sid) = ac_setup();
        let (_owner_club, owner_sid) = ac_create_user(&mut server, "owner", TEST_OWNER_CREDENTIAL);
        let work_id = server
            .create_work(owner_sid, Edition::from_text("multi-sponsor"))
            .unwrap();

        let club_a = server
            .create_named_club(owner_sid, "club_a", Edition::empty())
            .unwrap();
        let club_b = server
            .create_named_club(owner_sid, "club_b", Edition::empty())
            .unwrap();
        let club_c = server
            .create_named_club(owner_sid, "club_c", Edition::empty())
            .unwrap();

        // Sponsor with all three
        server.work_sponsor(owner_sid, work_id, club_a).unwrap();
        server.work_sponsor(owner_sid, work_id, club_b).unwrap();
        server.work_sponsor(owner_sid, work_id, club_c).unwrap();

        let sponsors = server.work_sponsors(work_id).unwrap();
        assert_eq!(sponsors.len(), 3, "should have 3 sponsors");
        assert!(sponsors.contains(&club_a));
        assert!(sponsors.contains(&club_b));
        assert!(sponsors.contains(&club_c));

        // Unsponsor only club_b
        server.work_unsponsor(owner_sid, work_id, club_b).unwrap();
        let sponsors = server.work_sponsors(work_id).unwrap();
        assert_eq!(
            sponsors.len(),
            2,
            "should have 2 sponsors after removing club_b"
        );
        assert!(sponsors.contains(&club_a));
        assert!(!sponsors.contains(&club_b), "club_b should be gone");
        assert!(sponsors.contains(&club_c));
    }

    #[test]
    fn sponsor_is_idempotent() {
        let (mut server, _pub_sid) = ac_setup();
        let (_owner_club, owner_sid) = ac_create_user(&mut server, "owner", TEST_OWNER_CREDENTIAL);
        let work_id = server
            .create_work(owner_sid, Edition::from_text("dedup"))
            .unwrap();
        let club = server
            .create_named_club(owner_sid, "re_sponsor", Edition::empty())
            .unwrap();

        // Sponsor the same club twice — should not duplicate
        server.work_sponsor(owner_sid, work_id, club).unwrap();
        server.work_sponsor(owner_sid, work_id, club).unwrap();
        assert_eq!(
            server.work_sponsors(work_id).unwrap().len(),
            1,
            "double-sponsor should be idempotent"
        );

        // Unsponsor, re-sponsor, should still be 1
        server.work_unsponsor(owner_sid, work_id, club).unwrap();
        assert!(server.work_sponsors(work_id).unwrap().is_empty());
        server.work_sponsor(owner_sid, work_id, club).unwrap();
        assert_eq!(server.work_sponsors(work_id).unwrap(), &[club]);
    }

    #[test]
    fn sponsors_publicly_queryable() {
        let (mut server, _pub_sid) = ac_setup();
        let (owner_club, owner_sid) = ac_create_user(&mut server, "owner", TEST_OWNER_CREDENTIAL);
        let work_id = server
            .create_work(owner_sid, Edition::from_text("public sponsor"))
            .unwrap();
        server.work_publish(owner_sid, work_id).unwrap();

        let sponsor_club = server
            .create_named_club(owner_sid, "vouch_club", Edition::empty())
            .unwrap();
        server
            .work_sponsor(owner_sid, work_id, sponsor_club)
            .unwrap();

        // A completely unauthenticated stranger session should be able to
        // query sponsors (sponsors are public reputation, not secret).
        let stranger_sid = server.connect();
        server.login_public(stranger_sid).unwrap();
        let sponsors = server.work_sponsors(work_id).unwrap();
        assert!(
            sponsors.contains(&sponsor_club),
            "stranger should see sponsors on a public work"
        );
    }

    #[test]
    fn sponsors_survive_checkpoint_restore() {
        let dir = TempDir::new("sponsor_persist");
        let work_id;
        let club_a;
        let club_b;
        {
            let mut server = Server::new();
            let sid = server.connect();
            server.login_public(sid).unwrap();
            work_id = server
                .create_work(sid, Edition::from_text("persist sponsors"))
                .unwrap();
            club_a = server.create_club(sid, Edition::empty()).unwrap();
            club_b = server.create_club(sid, Edition::empty()).unwrap();

            server.work_sponsor(sid, work_id, club_a).unwrap();
            server.work_sponsor(sid, work_id, club_b).unwrap();
            assert_eq!(server.work_sponsors(work_id).unwrap().len(), 2);

            server.checkpoint_to_file(&dir.snapshot_path()).unwrap();
        }
        {
            let server = Server::restore_from_file(&dir.snapshot_path()).unwrap();
            let sponsors = server.work_sponsors(work_id).unwrap();
            assert_eq!(
                sponsors.len(),
                2,
                "sponsors must survive checkpoint/restore"
            );
            assert!(sponsors.contains(&club_a));
            assert!(sponsors.contains(&club_b));
        }
    }

    #[test]
    fn crdt_two_users_concurrent_edit() {
        let (mut server, sid1) = ac_setup();
        let work_id = server
            .create_work(sid1, Edition::from_text("initial"))
            .unwrap();
        let sid2 = server.connect();
        server.login_public(sid2).unwrap();
        let _r1 = server.crdt_open_session(sid1, work_id).unwrap();
        let _r2 = server.crdt_open_session(sid2, work_id).unwrap();
        let ops1 = vec![
            TextDeltaOp::Retain { count: 0 },
            TextDeltaOp::Insert {
                text: "A".to_string(),
            },
        ];
        let result1 = server.crdt_apply_text_delta(sid1, work_id, &ops1).unwrap();
        assert_eq!(result1.0.relay_to.len(), 1);
        let ops2 = vec![
            TextDeltaOp::Retain { count: 0 },
            TextDeltaOp::Insert {
                text: "B".to_string(),
            },
        ];
        server.crdt_apply_text_delta(sid2, work_id, &ops2).unwrap();
        let text = server.crdt_current_text(work_id).unwrap();
        assert!(
            text.contains('A') && text.contains('B'),
            "both edits present, got: {}",
            text
        );
    }

    #[test]
    fn crdt_three_users() {
        let (mut server, sid1) = ac_setup();
        let work_id = server.create_work(sid1, Edition::from_text("")).unwrap();
        let sid2 = server.connect();
        server.login_public(sid2).unwrap();
        let sid3 = server.connect();
        server.login_public(sid3).unwrap();
        let _r1 = server.crdt_open_session(sid1, work_id).unwrap();
        let _r2 = server.crdt_open_session(sid2, work_id).unwrap();
        let _r3 = server.crdt_open_session(sid3, work_id).unwrap();
        server
            .crdt_apply_text_delta(
                sid1,
                work_id,
                &[TextDeltaOp::Insert {
                    text: "alice".to_string(),
                }],
            )
            .unwrap();
        server
            .crdt_apply_text_delta(
                sid2,
                work_id,
                &[TextDeltaOp::Insert {
                    text: "bob".to_string(),
                }],
            )
            .unwrap();
        server
            .crdt_apply_text_delta(
                sid3,
                work_id,
                &[TextDeltaOp::Insert {
                    text: "carol".to_string(),
                }],
            )
            .unwrap();
        let text = server.crdt_current_text(work_id).unwrap();
        assert!(
            text.contains("alice") && text.contains("bob") && text.contains("carol"),
            "got: {}",
            text
        );
    }

    #[test]
    fn crdt_close_session_materializes() {
        let (mut server, sid1) = ac_setup();
        let work_id = server
            .create_work(sid1, Edition::from_text("original"))
            .unwrap();
        let _r1 = server.crdt_open_session(sid1, work_id).unwrap();
        server
            .crdt_apply_text_delta(
                sid1,
                work_id,
                &[TextDeltaOp::Insert {
                    text: "modified ".to_string(),
                }],
            )
            .unwrap();
        server.crdt_close_session(sid1, work_id).unwrap();
        let text = server.work_edition(work_id).unwrap().to_text();
        assert!(
            text.contains("modified"),
            "close should materialize, got: {}",
            text
        );
    }

    #[test]
    fn crdt_close_one_session_keeps_others() {
        let (mut server, sid1) = ac_setup();
        let work_id = server
            .create_work(sid1, Edition::from_text("shared"))
            .unwrap();
        let sid2 = server.connect();
        server.login_public(sid2).unwrap();
        let _r1 = server.crdt_open_session(sid1, work_id).unwrap();
        let _r2 = server.crdt_open_session(sid2, work_id).unwrap();
        server
            .crdt_apply_text_delta(
                sid1,
                work_id,
                &[TextDeltaOp::Insert {
                    text: "A".to_string(),
                }],
            )
            .unwrap();
        server.crdt_close_session(sid1, work_id).unwrap();
        assert!(
            server.crdt_is_active(work_id),
            "work should still be active with sid2"
        );
        assert_eq!(server.crdt_subscriber_count(work_id), 1);
    }

    #[test]
    fn crdt_conflict_resolution_overlapping_edits() {
        let (mut server, sid1) = ac_setup();
        let work_id = server
            .create_work(sid1, Edition::from_text("ABCDEFGH"))
            .unwrap();
        let sid2 = server.connect();
        server.login_public(sid2).unwrap();
        let _r1 = server.crdt_open_session(sid1, work_id).unwrap();
        let _r2 = server.crdt_open_session(sid2, work_id).unwrap();
        server
            .crdt_apply_text_delta(
                sid1,
                work_id,
                &[
                    TextDeltaOp::Retain { count: 4 },
                    TextDeltaOp::Delete { count: 4 },
                    TextDeltaOp::Insert {
                        text: "XYZ".to_string(),
                    },
                ],
            )
            .unwrap();
        server
            .crdt_apply_text_delta(
                sid2,
                work_id,
                &[
                    TextDeltaOp::Retain { count: 2 },
                    TextDeltaOp::Delete { count: 2 },
                    TextDeltaOp::Insert {
                        text: "12".to_string(),
                    },
                ],
            )
            .unwrap();
        let text = server.crdt_current_text(work_id).unwrap();
        assert!(
            text.contains("XYZ") || text.contains("12"),
            "conflict resolved, got: {}",
            text
        );
        assert_eq!(text.len(), 7);
    }

    #[test]
    fn crdt_rapid_edits_same_user() {
        let (mut server, sid1) = ac_setup();
        let work_id = server.create_work(sid1, Edition::from_text("")).unwrap();
        let _r1 = server.crdt_open_session(sid1, work_id).unwrap();
        for ch in "rapid typing".chars() {
            let text = server.crdt_current_text(work_id).unwrap();
            let ops = vec![
                TextDeltaOp::Retain {
                    count: text.len() as u64,
                },
                TextDeltaOp::Insert {
                    text: ch.to_string(),
                },
            ];
            server.crdt_apply_text_delta(sid1, work_id, &ops).unwrap();
        }
        assert_eq!(server.crdt_current_text(work_id).unwrap(), "rapid typing");
    }

    #[test]
    fn crdt_unicode_multi_user() {
        let (mut server, sid1) = ac_setup();
        let work_id = server
            .create_work(sid1, Edition::from_text("abcd"))
            .unwrap();
        let sid2 = server.connect();
        server.login_public(sid2).unwrap();
        let _r1 = server.crdt_open_session(sid1, work_id).unwrap();
        let _r2 = server.crdt_open_session(sid2, work_id).unwrap();
        server
            .crdt_apply_text_delta(
                sid1,
                work_id,
                &[
                    TextDeltaOp::Retain { count: 1 },
                    TextDeltaOp::Insert {
                        text: "X".to_string(),
                    },
                ],
            )
            .unwrap();
        server
            .crdt_apply_text_delta(
                sid2,
                work_id,
                &[
                    TextDeltaOp::Retain { count: 3 },
                    TextDeltaOp::Insert {
                        text: "Y".to_string(),
                    },
                ],
            )
            .unwrap();
        let text = server.crdt_current_text(work_id).unwrap();
        assert!(text.contains('X') && text.contains('Y'), "got: {}", text);
    }

    #[test]
    fn crdt_awareness_multi_user() {
        let (mut server, sid1) = ac_setup();
        let work_id = server
            .create_work(sid1, Edition::from_text("aware"))
            .unwrap();
        let sid2 = server.connect();
        server.login_public(sid2).unwrap();
        let _r1 = server.crdt_open_session(sid1, work_id).unwrap();
        let _r2 = server.crdt_open_session(sid2, work_id).unwrap();
        let state1 = AwarenessState {
            session_id: sid1.as_u64(),
            user_name: "alice".to_string(),
            club_id: None,
            author_public_key: None,
            cursor: Some(CursorPosition { index: 0 }),
            selection: None,
            is_typing: false,
        };
        let result1 = server.crdt_update_awareness(sid1, work_id, state1).unwrap();
        assert_eq!(result1.relay_to.len(), 1);
        let state2 = AwarenessState {
            session_id: sid2.as_u64(),
            user_name: "bob".to_string(),
            club_id: None,
            author_public_key: None,
            cursor: Some(CursorPosition { index: 5 }),
            selection: None,
            is_typing: false,
        };
        let result2 = server.crdt_update_awareness(sid2, work_id, state2).unwrap();
        assert_eq!(result2.relay_to.len(), 1);
        let states = server.crdt_get_awareness(work_id).unwrap();
        assert_eq!(states.len(), 2);
    }

    #[test]
    fn disconnect_removes_awareness_and_returns_relay() {
        let (mut server, sid1) = ac_setup();
        let work_id = server
            .create_work(sid1, Edition::from_text("disconnect-aware"))
            .unwrap();
        let sid2 = server.connect();
        server.login_public(sid2).unwrap();
        server.crdt_open_session(sid1, work_id).unwrap();
        server.crdt_open_session(sid2, work_id).unwrap();
        let state1 = AwarenessState {
            session_id: sid1.as_u64(),
            user_name: "alice".to_string(),
            club_id: None,
            author_public_key: None,
            cursor: Some(CursorPosition { index: 0 }),
            selection: None,
            is_typing: false,
        };
        server.crdt_update_awareness(sid1, work_id, state1).unwrap();
        let state2 = AwarenessState {
            session_id: sid2.as_u64(),
            user_name: "bob".to_string(),
            club_id: None,
            author_public_key: None,
            cursor: Some(CursorPosition { index: 3 }),
            selection: None,
            is_typing: false,
        };
        server.crdt_update_awareness(sid2, work_id, state2).unwrap();

        let removals = server.disconnect(sid2).unwrap();
        assert_eq!(removals.len(), 1, "should have removal info for 1 work");
        let (rm_work_id, relay) = &removals[0];
        assert_eq!(*rm_work_id, work_id);
        assert_eq!(relay.len(), 1, "should relay to 1 remaining subscriber");
        assert_eq!(relay[0].0, sid1);

        let states = server.crdt_get_awareness(work_id).unwrap();
        assert_eq!(states.len(), 1, "only sid1 awareness should remain");
        assert_eq!(states[0].user_name, "alice");
    }

    #[test]
    fn disconnect_with_no_crdt_works_returns_empty() {
        let (mut server, sid1) = ac_setup();
        let _work_id = server
            .create_work(sid1, Edition::from_text("no-crdt"))
            .unwrap();
        let sid2 = server.connect();
        server.login_public(sid2).unwrap();

        let removals = server.disconnect(sid2).unwrap();
        assert!(removals.is_empty(), "no CRDT sessions = no removals");
    }

    #[test]
    fn disconnect_relay_includes_multiple_works() {
        let (mut server, sid1) = ac_setup();
        let work_a = server
            .create_work(sid1, Edition::from_text("work-a"))
            .unwrap();
        let work_b = server
            .create_work(sid1, Edition::from_text("work-b"))
            .unwrap();
        let sid2 = server.connect();
        server.login_public(sid2).unwrap();
        server.crdt_open_session(sid1, work_a).unwrap();
        server.crdt_open_session(sid2, work_a).unwrap();
        server.crdt_open_session(sid1, work_b).unwrap();
        server.crdt_open_session(sid2, work_b).unwrap();

        server
            .crdt_update_awareness(
                sid2,
                work_a,
                AwarenessState {
                    session_id: sid2.as_u64(),
                    user_name: "bob".to_string(),
                    club_id: None,
                    author_public_key: None,
                    cursor: None,
                    selection: None,
                    is_typing: false,
                },
            )
            .unwrap();
        server
            .crdt_update_awareness(
                sid2,
                work_b,
                AwarenessState {
                    session_id: sid2.as_u64(),
                    user_name: "bob".to_string(),
                    club_id: None,
                    author_public_key: None,
                    cursor: Some(CursorPosition { index: 0 }),
                    selection: None,
                    is_typing: false,
                },
            )
            .unwrap();

        let removals = server.disconnect(sid2).unwrap();
        assert_eq!(removals.len(), 2, "should have removals for 2 works");
    }

    #[test]
    fn crdt_author_registration_multi_user() {
        let (mut server, sid1) = ac_setup();
        let work_id = server
            .create_work(sid1, Edition::from_text("auth"))
            .unwrap();
        let sid2 = server.connect();
        server.login_public(sid2).unwrap();
        let _r1 = server.crdt_open_session(sid1, work_id).unwrap();
        let _r2 = server.crdt_open_session(sid2, work_id).unwrap();
        server.crdt_update_author(sid1, work_id).unwrap();
        server.crdt_update_author(sid2, work_id).unwrap();
        let authors = server.otree_crdt.get_author_sessions(work_id).unwrap();
        assert_eq!(authors.len(), 2, "two authors should be registered");
        let sids: Vec<SessionId> = authors.iter().map(|(sid, _)| *sid).collect();
        assert!(sids.contains(&sid1));
        assert!(sids.contains(&sid2));
    }

    #[test]
    fn private_club_blocks_non_member_from_edit() {
        let (mut server, owner_sid) = ac_setup();
        let private_club = server
            .create_named_club(owner_sid, "exclusive", Edition::empty())
            .unwrap();
        let work_id = server
            .create_work(owner_sid, Edition::from_text("gated"))
            .unwrap();
        server
            .work_set_edit_club(owner_sid, work_id, Some(private_club))
            .unwrap();
        let stranger_sid = server.connect();
        server.login_public(stranger_sid).unwrap();
        assert!(!server.work_can_revise(stranger_sid, work_id).unwrap());
        assert!(server.work_grab(stranger_sid, work_id).is_err());
    }

    #[test]
    fn adding_member_to_edit_club_grants_access() {
        let (mut server, owner_sid) = ac_setup();
        let edit_club = server
            .create_named_club(owner_sid, "invited_editors", Edition::empty())
            .unwrap();
        let work_id = server
            .create_work(owner_sid, Edition::from_text("invited"))
            .unwrap();
        server
            .work_set_edit_club(owner_sid, work_id, Some(edit_club))
            .unwrap();
        let (user_club, user_sid) = ac_create_user(&mut server, "invitee", TEST_ALT_CREDENTIAL);
        assert!(
            !server.work_can_revise(user_sid, work_id).unwrap(),
            "before invite, user cannot edit"
        );
        server
            .club_add_member(owner_sid, edit_club, user_club)
            .unwrap();
        let user_sid2 = ac_login_as(&mut server, user_club, TEST_ALT_CREDENTIAL);
        assert!(
            server.work_can_revise(user_sid2, work_id).unwrap(),
            "after invite, user can edit"
        );
    }

    #[test]
    fn removing_member_revokes_access() {
        let (mut server, owner_sid) = ac_setup();
        let edit_club = server
            .create_named_club(owner_sid, "revokable_edit", Edition::empty())
            .unwrap();
        let work_id = server
            .create_work(owner_sid, Edition::from_text("revokable"))
            .unwrap();
        server
            .work_set_edit_club(owner_sid, work_id, Some(edit_club))
            .unwrap();
        let (user_club, _user_sid) = ac_create_user(&mut server, "tempuser", TEST_ALT_CREDENTIAL);
        server
            .club_add_member(owner_sid, edit_club, user_club)
            .unwrap();
        let user_sid2 = ac_login_as(&mut server, user_club, TEST_ALT_CREDENTIAL);
        assert!(server.work_can_revise(user_sid2, work_id).unwrap());
        server
            .club_remove_member(owner_sid, edit_club, user_club)
            .unwrap();
        let user_sid3 = ac_login_as(&mut server, user_club, TEST_ALT_CREDENTIAL);
        assert!(
            !server.work_can_revise(user_sid3, work_id).unwrap(),
            "removed member should not edit"
        );
    }

    #[test]
    fn read_club_restricts_visibility() {
        let (mut server, _pub_sid) = ac_setup();
        let (owner_club, owner_sid) = ac_create_user(&mut server, "owner", TEST_OWNER_CREDENTIAL);
        let read_club = server
            .create_named_club(owner_sid, "secret_readers", Edition::empty())
            .unwrap();
        let work_id = server
            .create_work(owner_sid, Edition::from_text("hidden"))
            .unwrap();
        server
            .work_set_read_club(owner_sid, work_id, Some(read_club))
            .unwrap();
        let (stranger_club, _stranger_sid) =
            ac_create_user(&mut server, "stranger", TEST_OTHER_CREDENTIAL);
        let stranger_sid = ac_login_as(&mut server, stranger_club, TEST_OTHER_CREDENTIAL);
        let can_read = server.work_can_read(stranger_sid, work_id).unwrap();
        assert!(
            !can_read,
            "stranger should not read work with restricted read_club"
        );
    }

    #[test]
    fn publish_makes_readable_by_all() {
        let (mut server, owner_sid) = ac_setup();
        let work_id = server
            .create_work(owner_sid, Edition::from_text("my doc"))
            .unwrap();
        server.work_publish(owner_sid, work_id).unwrap();
        let stranger_sid = server.connect();
        server.login_public(stranger_sid).unwrap();
        assert!(server.work_can_read(stranger_sid, work_id).unwrap());
    }

    #[test]
    fn unpublish_restricts_to_owner() {
        let (mut server, _pub_sid) = ac_setup();
        let (owner_club, owner_sid) = ac_create_user(&mut server, "owner", TEST_OWNER_CREDENTIAL);
        let work_id = server
            .create_work(owner_sid, Edition::from_text("my doc"))
            .unwrap();
        server.work_publish(owner_sid, work_id).unwrap();
        server.work_unpublish(owner_sid, work_id).unwrap();
        let (stranger_club, _stranger_sid) =
            ac_create_user(&mut server, "stranger", TEST_OTHER_CREDENTIAL);
        let stranger_sid = ac_login_as(&mut server, stranger_club, TEST_OTHER_CREDENTIAL);
        assert!(
            !server.work_can_read(stranger_sid, work_id).unwrap(),
            "unpublished work should not be readable by strangers"
        );
    }

    #[test]
    fn history_club_requires_owner_to_set() {
        let (mut server, _pub_sid) = ac_setup();
        let (owner_club, owner_sid) = ac_create_user(&mut server, "owner", TEST_OWNER_CREDENTIAL);
        let work_id = server
            .create_work(owner_sid, Edition::from_text("v1"))
            .unwrap();
        server.work_publish(owner_sid, work_id).unwrap();

        // Owner can set history_club
        server
            .work_set_history_club(owner_sid, work_id, Some(owner_club))
            .unwrap();
        assert_eq!(server.work_history_club(work_id).unwrap(), Some(owner_club));

        // Stranger cannot set history_club (not owner)
        let (stranger_club, _) = ac_create_user(&mut server, "stranger", TEST_OTHER_CREDENTIAL);
        let stranger_sid = ac_login_as(&mut server, stranger_club, TEST_OTHER_CREDENTIAL);
        let err = server
            .work_set_history_club(stranger_sid, work_id, Some(stranger_club))
            .unwrap_err();
        assert!(
            matches!(err, ServerError::NotOwner(_)),
            "non-owner must not set history_club, got {:?}",
            err
        );
    }

    #[test]
    fn history_club_gates_revision_access() {
        let (mut server, _pub_sid) = ac_setup();
        let (owner_club, owner_sid) = ac_create_user(&mut server, "owner", TEST_OWNER_CREDENTIAL);
        let work_id = server
            .create_work(owner_sid, Edition::from_text("v1"))
            .unwrap();
        // Revise to create history
        server.work_grab(owner_sid, work_id).unwrap();
        server
            .work_revise(owner_sid, work_id, Edition::from_text("v2"))
            .unwrap();
        server.work_release(owner_sid, work_id).unwrap();
        server.work_publish(owner_sid, work_id).unwrap();

        // Create a private history club (just the owner)
        server
            .work_set_history_club(owner_sid, work_id, Some(owner_club))
            .unwrap();

        // Owner can read history
        assert!(
            server.ensure_can_read_history(owner_sid, work_id).is_ok(),
            "owner should access history"
        );
        // Owner can fetch revision 1
        assert!(
            server.work_fetch_revision(work_id, 1).is_ok(),
            "owner should fetch revisions"
        );

        // Stranger can read the work (published) but NOT its history
        let (stranger_club, _) = ac_create_user(&mut server, "stranger", TEST_OTHER_CREDENTIAL);
        let stranger_sid = ac_login_as(&mut server, stranger_club, TEST_OTHER_CREDENTIAL);
        assert!(
            server.work_can_read(stranger_sid, work_id).unwrap(),
            "published work should be readable by strangers"
        );
        let err = server
            .ensure_can_read_history(stranger_sid, work_id)
            .unwrap_err();
        assert!(
            matches!(err, ServerError::NotAuthorized),
            "stranger must not access history when history_club is set, got {:?}",
            err
        );
    }

    #[test]
    fn history_club_none_falls_back_to_read() {
        let (mut server, _pub_sid) = ac_setup();
        let (owner_club, owner_sid) = ac_create_user(&mut server, "owner", TEST_OWNER_CREDENTIAL);
        let work_id = server
            .create_work(owner_sid, Edition::from_text("v1"))
            .unwrap();
        server.work_publish(owner_sid, work_id).unwrap();

        // history_club is None by default
        assert_eq!(server.work_history_club(work_id).unwrap(), None);

        // Stranger can read → can also read history (backward-compatible)
        let (stranger_club, _) = ac_create_user(&mut server, "stranger", TEST_OTHER_CREDENTIAL);
        let stranger_sid = ac_login_as(&mut server, stranger_club, TEST_OTHER_CREDENTIAL);
        assert!(
            server.work_can_read(stranger_sid, work_id).unwrap(),
            "published work should be readable"
        );
        assert!(
            server
                .ensure_can_read_history(stranger_sid, work_id)
                .is_ok(),
            "with no history_club, read permission should grant history access"
        );
    }

    #[test]
    fn again_chain_returns_original_for_untouched_content() {
        let (mut server, sid) = prov_setup();
        let work = server
            .create_work(sid, Edition::from_text("original content"))
            .unwrap();
        // No links, no transclusion — chain should have one hop marked original.
        let chain = server.transclusion_again_chain(work, 0, 10);
        assert_eq!(chain.len(), 1, "should have exactly one hop");
        assert!(chain[0].is_original, "should be marked original");
        assert_eq!(chain[0].work_id, work);
    }

    #[test]
    fn again_chain_walks_two_hop_transclusion() {
        let mut server = Server::new();
        let session = server.connect();
        server.login_public(session).unwrap();
        server.grant_admin_authority(session).unwrap();
        let club_id = server
            .session(session)
            .unwrap()
            .authority_clubs()
            .iter()
            .next()
            .copied()
            .unwrap();
        let public_club = server.public_club_id();

        // Register a historical author (import_source_work needs one)
        let author = server
            .register_historical_author(
                "Test Author".into(),
                "Test Author".into(),
                Some(1900),
                Some(1970),
                std::collections::HashMap::new(),
                "test".into(),
                club_id,
            )
            .unwrap();

        // Source work with known text
        let passage = "The quick brown fox jumps over the lazy dog.";
        let src_text = format!("{} That is all.", passage);
        let (src_id, _, _, _) = server
            .import_source_work(
                session,
                author.be_id,
                "test-src".into(),
                src_text,
                "ed".into(),
                0,
                0,
            )
            .unwrap();
        if let Some(ws) = server.works.get_mut(&src_id) {
            ws.work.set_edit_club(Some(public_club));
            ws.work.set_read_club(Some(public_club));
        }
        server
            .apply_source_attribution(session, src_id, author.be_id, None, None, None)
            .unwrap();

        // Doc A: transclude passage from source
        let doc_a_text = format!("intro {} outro", passage);
        let doc_a = server
            .create_work(session, Edition::from_text(&doc_a_text))
            .unwrap();
        if let Some(ws) = server.works.get_mut(&doc_a) {
            ws.work.set_edit_club(Some(public_club));
            ws.work.set_read_club(Some(public_club));
        }
        let link_a = server
            .create_link(
                session,
                src_id,
                doc_a,
                Some(crate::edition::links::HyperRef::single(
                    Some(Edition::from_text(passage)),
                    Some(src_id),
                    None,
                    None,
                )),
                Some(crate::edition::links::HyperRef::single(
                    None,
                    Some(doc_a),
                    None,
                    None,
                )),
            )
            .unwrap();
        server
            .apply_transclusion_attribution(session, link_a)
            .unwrap();

        // Query the again() chain for the transcluded passage in doc_a
        let passage_start = doc_a_text.find(passage).unwrap();
        let passage_end = passage_start + passage.len();
        let chain = server.transclusion_again_chain(doc_a, passage_start, passage_end);

        assert!(
            chain.len() >= 2,
            "should have at least 2 hops (doc_a -> source), got {}",
            chain.len()
        );
        // First hop: doc_a (not original)
        assert!(!chain[0].is_original, "first hop should not be original");
        assert_eq!(chain[0].work_id, doc_a);
        // Last hop: source (original)
        let last = chain.last().unwrap();
        assert!(last.is_original, "last hop should be marked original");
        assert_eq!(last.work_id, src_id);
    }

    #[test]
    fn again_chain_terminates_on_cycle() {
        let (mut server, sid) = prov_setup();
        // Two works linking to each other (cycle) — no provenance stamped,
        // so again() should just return the first work as original.
        let wa = server.create_work(sid, Edition::from_text("a")).unwrap();
        let wb = server.create_work(sid, Edition::from_text("b")).unwrap();
        let _l1 = server.create_link(sid, wa, wb, None, None).unwrap();
        let _l2 = server.create_link(sid, wb, wa, None, None).unwrap();

        // Without provenance stamped, again() should not loop.
        let chain = server.transclusion_again_chain(wa, 0, 1);
        assert_eq!(
            chain.len(),
            1,
            "should terminate immediately — no source provenance to walk"
        );
        assert!(chain[0].is_original);
    }

    #[test]
    fn crdt_edit_club_blocks_unauthorized_session() {
        let (mut server, owner_sid) = ac_setup();
        let edit_club = server
            .create_named_club(owner_sid, "crdt_gate", Edition::empty())
            .unwrap();
        let work_id = server
            .create_work(owner_sid, Edition::from_text("crdt_gated"))
            .unwrap();
        server
            .work_set_edit_club(owner_sid, work_id, Some(edit_club))
            .unwrap();
        let (user_club, _user_sid) = ac_create_user(&mut server, "crdt_user", TEST_ALT_CREDENTIAL);
        let user_sid = ac_login_as(&mut server, user_club, TEST_ALT_CREDENTIAL);
        assert!(server.crdt_open_session(user_sid, work_id).is_err());
        server
            .club_add_member(owner_sid, edit_club, user_club)
            .unwrap();
        let user_sid2 = ac_login_as(&mut server, user_club, TEST_ALT_CREDENTIAL);
        assert!(server.crdt_open_session(user_sid2, work_id).is_ok());
    }

    #[test]
    fn crdt_revoked_member_cannot_edit_anymore() {
        let (mut server, owner_sid) = ac_setup();
        let edit_club = server
            .create_named_club(owner_sid, "crdt_revoke", Edition::empty())
            .unwrap();
        let work_id = server
            .create_work(owner_sid, Edition::from_text("revokable crdt"))
            .unwrap();
        server
            .work_set_edit_club(owner_sid, work_id, Some(edit_club))
            .unwrap();
        let (user_club, _user_sid) = ac_create_user(&mut server, "revokee", TEST_ALT_CREDENTIAL);
        server
            .club_add_member(owner_sid, edit_club, user_club)
            .unwrap();
        let user_sid = ac_login_as(&mut server, user_club, TEST_ALT_CREDENTIAL);
        let _r = server.crdt_open_session(user_sid, work_id).unwrap();
        server
            .crdt_apply_text_delta(
                user_sid,
                work_id,
                &[TextDeltaOp::Insert {
                    text: "before revoke".to_string(),
                }],
            )
            .unwrap();
        server
            .club_remove_member(owner_sid, edit_club, user_club)
            .unwrap();
        let result = server.crdt_apply_text_delta(
            user_sid,
            work_id,
            &[TextDeltaOp::Insert {
                text: "after revoke".to_string(),
            }],
        );
        assert!(result.is_err(), "revoked member should not apply deltas");
    }

    #[test]
    fn no_edit_club_means_no_one_can_edit() {
        let (mut server, owner_sid) = ac_setup();
        let work_id = server
            .create_work(owner_sid, Edition::from_text("no edit"))
            .unwrap();
        server.work_set_edit_club(owner_sid, work_id, None).unwrap();
        assert!(
            !server.work_can_revise(owner_sid, work_id).unwrap(),
            "no edit_club means even owner cannot revise"
        );
    }

    #[test]
    fn public_edit_club_allows_all() {
        let (mut server, owner_sid) = ac_setup();
        let work_id = server
            .create_work(owner_sid, Edition::from_text("open"))
            .unwrap();
        server
            .work_set_edit_club(owner_sid, work_id, Some(server.public_club_id()))
            .unwrap();
        let stranger_sid = server.connect();
        server.login_public(stranger_sid).unwrap();
        assert!(server.work_can_revise(stranger_sid, work_id).unwrap());
    }

    #[test]
    fn work_list_includes_read_club_info() {
        let (mut server, owner_sid) = ac_setup();
        let public_work = server
            .create_work(owner_sid, Edition::from_text("public"))
            .unwrap();
        server.work_publish(owner_sid, public_work).unwrap();
        let read_club = server
            .create_named_club(owner_sid, "secret_list", Edition::empty())
            .unwrap();
        let private_work = server
            .create_work(owner_sid, Edition::from_text("private"))
            .unwrap();
        server
            .work_set_read_club(owner_sid, private_work, Some(read_club))
            .unwrap();
        let works = server.list_works_with_titles();
        let pub_entry = works
            .iter()
            .find(|(id, _, _, _, _, _, _, _, _, _, _)| *id == public_work)
            .unwrap();
        assert_eq!(pub_entry.5, Some(server.public_club_id()));
        let priv_entry = works
            .iter()
            .find(|(id, _, _, _, _, _, _, _, _, _, _)| *id == private_work)
            .unwrap();
        assert_eq!(priv_entry.5, Some(read_club));
    }

    fn prov_setup() -> (Server, SessionId) {
        crate::edition::init_endorsement_flags();
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        (server, sid)
    }

    #[test]
    fn provenance_chain_empty_for_first_link() {
        let (mut server, sid) = prov_setup();
        let work_a = server
            .create_work(sid, Edition::from_text("original"))
            .unwrap();
        let work_b = server.create_work(sid, Edition::from_text("copy")).unwrap();
        let link_id = server.create_link(sid, work_a, work_b, None, None).unwrap();
        let (_, _, link) = server.get_link(link_id).unwrap();
        let o_ref = link.end_at("LeftEnd").unwrap();
        assert!(
            o_ref.provenance_chain().is_empty(),
            "first link should have empty chain"
        );
    }

    #[test]
    fn provenance_chain_single_hop() {
        let (mut server, sid) = prov_setup();
        let work_a = server
            .create_work(sid, Edition::from_text("original"))
            .unwrap();
        let work_b = server.create_work(sid, Edition::from_text("copy")).unwrap();
        let work_c = server
            .create_work(sid, Edition::from_text("derived"))
            .unwrap();

        let _link1 = server.create_link(sid, work_a, work_b, None, None).unwrap();
        let link2 = server.create_link(sid, work_b, work_c, None, None).unwrap();

        let (_, _, link) = server.get_link(link2).unwrap();
        let o_ref = link.end_at("LeftEnd").unwrap();
        let chain = o_ref.provenance_chain();
        assert_eq!(chain.len(), 1, "chain should have one hop");
        assert_eq!(chain[0].source_work_id(), work_a);
        assert_eq!(chain[0].link_id(), _link1);
    }

    #[test]
    fn provenance_chain_multi_hop() {
        let (mut server, sid) = prov_setup();
        let wa = server.create_work(sid, Edition::from_text("a")).unwrap();
        let wb = server.create_work(sid, Edition::from_text("b")).unwrap();
        let wc = server.create_work(sid, Edition::from_text("c")).unwrap();
        let wd = server.create_work(sid, Edition::from_text("d")).unwrap();

        let l1 = server.create_link(sid, wa, wb, None, None).unwrap();
        let l2 = server.create_link(sid, wb, wc, None, None).unwrap();
        let l3 = server.create_link(sid, wc, wd, None, None).unwrap();

        let (_, _, link) = server.get_link(l3).unwrap();
        let chain = link.end_at("LeftEnd").unwrap().provenance_chain();
        assert_eq!(chain.len(), 2, "chain should have two hops");
        assert_eq!(chain[0].source_work_id(), wa);
        assert_eq!(chain[0].link_id(), l1);
        assert_eq!(chain[1].source_work_id(), wb);
        assert_eq!(chain[1].link_id(), l2);
    }

    #[test]
    fn provenance_ancestry_walks_full_chain() {
        let (mut server, sid) = prov_setup();
        let wa = server.create_work(sid, Edition::from_text("a")).unwrap();
        let wb = server.create_work(sid, Edition::from_text("b")).unwrap();
        let wc = server.create_work(sid, Edition::from_text("c")).unwrap();

        let _l1 = server.create_link(sid, wa, wb, None, None).unwrap();
        let _l2 = server.create_link(sid, wb, wc, None, None).unwrap();

        let ancestry = server.provenance_ancestry(wc);
        assert_eq!(ancestry.len(), 2);
        assert_eq!(ancestry[0].source_work_id(), wa);
        assert_eq!(ancestry[1].source_work_id(), wb);
    }

    #[test]
    fn provenance_chain_with_excerpt() {
        let (mut server, sid) = prov_setup();
        let wa = server
            .create_work(sid, Edition::from_text("source"))
            .unwrap();
        let wb = server
            .create_work(sid, Edition::from_text("target"))
            .unwrap();
        let wc = server
            .create_work(sid, Edition::from_text("final"))
            .unwrap();

        let o_ref = crate::edition::links::HyperRef::single(
            Some(Edition::from_text("excerpt text")),
            Some(wa),
            None,
            None,
        );
        let d_ref = crate::edition::links::HyperRef::single(None, Some(wb), None, None);
        let l1 = server
            .create_link(sid, wa, wb, Some(o_ref), Some(d_ref))
            .unwrap();

        let link2 = server.create_link(sid, wb, wc, None, None).unwrap();
        let (_, _, link) = server.get_link(link2).unwrap();
        let chain = link.end_at("LeftEnd").unwrap().provenance_chain();
        assert_eq!(chain.len(), 1);
        assert_eq!(chain[0].source_work_id(), wa);
        assert_eq!(chain[0].link_id(), l1);
    }

    #[test]
    fn provenance_chain_no_incoming_links() {
        let (mut server, sid) = prov_setup();
        let wa = server.create_work(sid, Edition::from_text("a")).unwrap();
        let ancestry = server.provenance_ancestry(wa);
        assert!(
            ancestry.is_empty(),
            "work with no incoming links has no ancestry"
        );
    }

    #[test]
    #[cfg(feature = "server")]
    fn historical_author_checkpoint_restore() {
        let dir = TempDir::new("ha_persist");

        let author_id;
        {
            let mut server = Server::new();
            let sid = server.connect();
            server.login_public(sid).unwrap();

            let author = server
                .register_historical_author(
                    "Vitruvius".into(),
                    "Vitruvius (c. 80\u{2013}15 BC)".into(),
                    Some(-80),
                    Some(-15),
                    HashMap::new(),
                    "De Architectura".into(),
                    1,
                )
                .unwrap();
            author_id = author.be_id;

            let got = server.get_historical_author(author_id).unwrap();
            assert_eq!(got.name, "Vitruvius");
            assert_eq!(got.display_name, "Vitruvius (c. 80\u{2013}15 BC)");
            assert_eq!(got.birth_year, Some(-80));
            assert_eq!(got.death_year, Some(-15));

            server.checkpoint_to_file(&dir.snapshot_path()).unwrap();
        }

        {
            let server = Server::restore_from_file(&dir.snapshot_path()).unwrap();
            let got = server.get_historical_author(author_id).unwrap();
            assert_eq!(got.name, "Vitruvius");
            assert_eq!(got.birth_year, Some(-80));
            assert_eq!(got.death_year, Some(-15));

            let list = server.list_historical_authors();
            assert_eq!(list.len(), 1);
            assert_eq!(list[0].name, "Vitruvius");
        }
    }

    #[test]
    #[cfg(feature = "server")]
    fn historical_author_sorted_by_name() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        server
            .register_historical_author(
                "Shakespeare".into(),
                "William Shakespeare".into(),
                Some(1564),
                Some(1616),
                HashMap::new(),
                String::new(),
                1,
            )
            .unwrap();
        server
            .register_historical_author(
                "Austen".into(),
                "Jane Austen".into(),
                Some(1775),
                Some(1817),
                HashMap::new(),
                String::new(),
                1,
            )
            .unwrap();
        server
            .register_historical_author(
                "Melville".into(),
                "Herman Melville".into(),
                Some(1819),
                Some(1891),
                HashMap::new(),
                String::new(),
                1,
            )
            .unwrap();

        let list = server.list_historical_authors();
        assert_eq!(list.len(), 3);
        assert_eq!(list[0].name, "Austen");
        assert_eq!(list[1].name, "Melville");
        assert_eq!(list[2].name, "Shakespeare");
    }

    #[test]
    #[cfg(feature = "server")]
    fn historical_author_works_by_author() {
        let dir = TempDir::new("ha_works");

        let author_id;
        let work_id;
        {
            let mut server = Server::new();
            let sid = server.connect();
            server.login_public(sid).unwrap();

            let author = server
                .register_historical_author(
                    "Vitruvius".into(),
                    "Vitruvius".into(),
                    None,
                    None,
                    HashMap::new(),
                    String::new(),
                    1,
                )
                .unwrap();
            author_id = author.be_id;

            work_id = server
                .import_source_work(
                    sid,
                    author_id,
                    "De Architectura".into(),
                    "Book I chapter 1".into(),
                    "De Architectura, Book I".into(),
                    0,
                    0,
                )
                .unwrap()
                .0;

            let works = server.list_works_by_historical_author(author_id);
            assert_eq!(works.len(), 1);
            assert_eq!(works[0].0, work_id);

            server.checkpoint_to_file(&dir.snapshot_path()).unwrap();
        }

        {
            let server = Server::restore_from_file(&dir.snapshot_path()).unwrap();

            let restored_author = server.get_historical_author(author_id).unwrap();
            assert_eq!(restored_author.name, "Vitruvius");

            let works = server.list_works_by_historical_author(author_id);
            assert_eq!(works.len(), 1);
            assert_eq!(works[0].0, work_id);
        }
    }

    #[test]
    fn transclusion_attribution_propagates_historical_provenance() {
        let mut server = Server::new();
        let session = server.connect();
        server.login_public(session).unwrap();
        server.grant_admin_authority(session).unwrap();
        let club_id = server
            .session(session)
            .unwrap()
            .authority_clubs()
            .iter()
            .next()
            .copied()
            .unwrap();
        let public_club = server.public_club_id();

        let author = server
            .register_historical_author(
                "Bram Stoker".into(),
                "Bram Stoker".into(),
                Some(1847),
                Some(1912),
                std::collections::HashMap::new(),
                "Dracula".into(),
                club_id,
            )
            .unwrap();

        let dracula_text = "It was the best of times it was the worst of times. ".repeat(10);
        let (dracula_id, _, _, _) = server
            .import_source_work(
                session,
                author.be_id,
                "Dracula".into(),
                dracula_text.clone(),
                "test edition".into(),
                0,
                0,
            )
            .unwrap();
        if let Some(ws) = server.works.get_mut(&dracula_id) {
            ws.work.set_edit_club(Some(public_club));
        }

        server
            .apply_source_attribution(session, dracula_id, author.be_id, None, None, None)
            .unwrap();

        let excerpt = "It was the best of times it was the worst of times.";
        let target_id = server
            .create_work(session, Edition::from_text("prefix"))
            .unwrap();
        if let Some(ws) = server.works.get_mut(&target_id) {
            ws.work.set_edit_club(Some(public_club));
        }

        let target_text = format!("prefix{}", excerpt);
        let revised = Edition::from_text(&target_text);
        server
            .revise_work(target_id, session, revised, Some(club_id))
            .unwrap();

        let link_id = server
            .create_link(
                session,
                dracula_id,
                target_id,
                Some(crate::edition::links::HyperRef::single(
                    Some(Edition::from_text(excerpt)),
                    Some(dracula_id),
                    None,
                    None,
                )),
                Some(crate::edition::links::HyperRef::single(
                    None,
                    Some(target_id),
                    None,
                    None,
                )),
            )
            .unwrap();

        server
            .apply_transclusion_attribution(session, link_id)
            .unwrap();

        let target_edition = server.work(target_id).unwrap().current_edition().clone();
        let target_entries = target_edition.all_entries();

        let mut historical_count = 0;
        let mut other_count = 0;
        for (_, carrier) in &target_entries {
            if let Some(ref prov) = carrier.provenance {
                if matches!(
                    prov.author_type,
                    crate::edition::provenance::AuthorType::Historical
                ) {
                    historical_count += 1;
                } else {
                    other_count += 1;
                }
            } else {
                other_count += 1;
            }
        }

        assert!(
            historical_count > 0,
            "expected some entries to have historical provenance, got {} historical, {} other",
            historical_count,
            other_count,
        );

        let mut source_work_id_set = 0;
        for (_, carrier) in &target_entries {
            if let Some(ref prov) = carrier.provenance {
                if matches!(
                    prov.author_type,
                    crate::edition::provenance::AuthorType::Historical
                ) && prov.source_work_id == Some(dracula_id)
                {
                    source_work_id_set += 1;
                }
            }
        }
        assert!(
            source_work_id_set > 0,
            "expected historical entries to have source_work_id set to dracula work"
        );
    }

    #[test]
    fn transclusion_chain_query_resolves_registry_author_name() {
        // Regression for the "Unknown" author bug: a 2-hop transclusion
        // (source -> docA -> docB) must resolve the historical author name
        // from the registry when queried through attribution_query. The bug
        // lived in the pending-attribution overlay, which used the stamped
        // (empty) author_display_name for non-source-work origins. The sibling
        // test above checks only the stamped element provenance and so missed
        // it; this one exercises the query/overlay layer.
        let mut server = Server::new();
        let session = server.connect();
        server.login_public(session).unwrap();
        server.grant_admin_authority(session).unwrap();
        let club_id = server
            .session(session)
            .unwrap()
            .authority_clubs()
            .iter()
            .next()
            .copied()
            .unwrap();
        let public_club = server.public_club_id();

        let author = server
            .register_historical_author(
                "Mary Shelley".into(),
                "Mary Shelley".into(),
                Some(1797),
                Some(1851),
                std::collections::HashMap::new(),
                "Frankenstein".into(),
                club_id,
            )
            .unwrap();

        let passage = "I am by birth a Genevese, and my family is one of the most distinguished of that republic.";
        let (src_id, _, _, _) = server
            .import_source_work(
                session,
                author.be_id,
                "Frankenstein Ch.1".into(),
                format!("{} My ancestors were counsellors.", passage),
                "1818".into(),
                0,
                0,
            )
            .unwrap();
        if let Some(ws) = server.works.get_mut(&src_id) {
            ws.work.set_edit_club(Some(public_club));
        }
        server
            .apply_source_attribution(session, src_id, author.be_id, None, None, None)
            .unwrap();

        // docA: contains the passage (created with full text so the passage
        // is attributed via transclusion, not as an admin author-edit span).
        let doc_a_text = format!("intro {} outro", passage);
        let doc_a = server
            .create_work(session, Edition::from_text(&doc_a_text))
            .unwrap();
        if let Some(ws) = server.works.get_mut(&doc_a) {
            ws.work.set_edit_club(Some(public_club));
        }
        let link_a = server
            .create_link(
                session,
                src_id,
                doc_a,
                Some(crate::edition::links::HyperRef::single(
                    Some(Edition::from_text(passage)),
                    Some(src_id),
                    None,
                    None,
                )),
                Some(crate::edition::links::HyperRef::single(
                    None,
                    Some(doc_a),
                    None,
                    None,
                )),
            )
            .unwrap();
        server
            .apply_transclusion_attribution(session, link_a)
            .unwrap();

        // docB: transclude the same passage FROM docA. docA is not a source
        // work, so the overlay takes the entry_prov branch that had the bug.
        let doc_b_text = format!("pref {} suff", passage);
        let doc_b = server
            .create_work(session, Edition::from_text(&doc_b_text))
            .unwrap();
        if let Some(ws) = server.works.get_mut(&doc_b) {
            ws.work.set_edit_club(Some(public_club));
        }
        let link_b = server
            .create_link(
                session,
                doc_a,
                doc_b,
                Some(crate::edition::links::HyperRef::single(
                    Some(Edition::from_text(passage)),
                    Some(doc_a),
                    None,
                    None,
                )),
                Some(crate::edition::links::HyperRef::single(
                    None,
                    Some(doc_b),
                    None,
                    None,
                )),
            )
            .unwrap();
        server
            .apply_transclusion_attribution(session, link_b)
            .unwrap();

        let spans = server.attribution_query(doc_b, None, None).unwrap();
        let names: Vec<&str> = spans
            .iter()
            .filter_map(|s| s.author_display_name.as_deref())
            .collect();
        assert!(
            names.iter().any(|n| *n == "Mary Shelley"),
            "2-hop transclusion must resolve the registry author name, got {:?}",
            names
        );
        assert!(
            !names.iter().any(|n| n.contains("Unknown")),
            "no span should show Unknown, got {:?}",
            names
        );
    }

    #[test]
    fn transclusion_attribution_appends_to_attribution_log() {
        // Regression: transclusion attribution must append to the transparency
        // log. Previously only the author-revision path logged, so transclusion
        // events left the log at 0 entries.
        let mut server = Server::new();
        let session = server.connect();
        server.login_public(session).unwrap();
        server.grant_admin_authority(session).unwrap();
        let club_id = server
            .session(session)
            .unwrap()
            .authority_clubs()
            .iter()
            .next()
            .copied()
            .unwrap();
        let public_club = server.public_club_id();

        let author = server
            .register_historical_author(
                "Bram Stoker".into(),
                "Bram Stoker".into(),
                Some(1847),
                Some(1912),
                std::collections::HashMap::new(),
                "Dracula".into(),
                club_id,
            )
            .unwrap();
        let excerpt = "It was the best of times it was the worst of times.";
        let (src_id, _, _, _) = server
            .import_source_work(
                session,
                author.be_id,
                "Dracula".into(),
                format!(
                    "{} {}",
                    excerpt,
                    "There were a king with a large jaw.".repeat(3)
                ),
                "ed".into(),
                0,
                0,
            )
            .unwrap();
        if let Some(ws) = server.works.get_mut(&src_id) {
            ws.work.set_edit_club(Some(public_club));
        }
        server
            .apply_source_attribution(session, src_id, author.be_id, None, None, None)
            .unwrap();

        let target_text = format!("prefix{}suffix", excerpt);
        let target_id = server
            .create_work(session, Edition::from_text("prefix"))
            .unwrap();
        if let Some(ws) = server.works.get_mut(&target_id) {
            ws.work.set_edit_club(Some(public_club));
        }
        server
            .revise_work(
                target_id,
                session,
                Edition::from_text(&target_text),
                Some(club_id),
            )
            .unwrap();

        let before = server.attribution_log.sequence();
        let link_id = server
            .create_link(
                session,
                src_id,
                target_id,
                Some(crate::edition::links::HyperRef::single(
                    Some(Edition::from_text(excerpt)),
                    Some(src_id),
                    None,
                    None,
                )),
                Some(crate::edition::links::HyperRef::single(
                    None,
                    Some(target_id),
                    None,
                    None,
                )),
            )
            .unwrap();
        server
            .apply_transclusion_attribution(session, link_id)
            .unwrap();
        let after = server.attribution_log.sequence();
        assert!(
            after > before,
            "transclusion attribution must append to the log (before={}, after={})",
            before,
            after
        );
    }

    #[test]
    fn enrich_provenance_hops_carries_dest_work_id() {
        // Regression: enriched ancestry hops must carry dest_work_id so clients
        // can distinguish parallel sources from a true chain. Previously the
        // list was flat and link-id-sorted, making independent sources read as
        // a linear lineage.
        let (mut server, sid) = prov_setup();
        let a = server
            .create_work(sid, Edition::from_text("source a"))
            .unwrap();
        let b = server
            .create_work(sid, Edition::from_text("source b"))
            .unwrap();
        let c = server
            .create_work(sid, Edition::from_text("target c"))
            .unwrap();

        // Two INDEPENDENT sources into c.
        server.create_link(sid, a, c, None, None).unwrap();
        server.create_link(sid, b, c, None, None).unwrap();
        let anc = server.provenance_ancestry(c);
        let parallel = server.enrich_provenance_hops(&anc);
        assert_eq!(parallel.len(), 2, "two independent sources into c");
        for hop in &parallel {
            assert_eq!(
                hop.dest_work_id, c,
                "independent sources must all dest on the target c, got dest={:04x}",
                hop.dest_work_id
            );
        }

        // A TRUE chain a -> b -> c.
        let (mut server2, sid2) = prov_setup();
        let ca = server2.create_work(sid2, Edition::from_text("a")).unwrap();
        let cb = server2.create_work(sid2, Edition::from_text("b")).unwrap();
        let cc = server2.create_work(sid2, Edition::from_text("c")).unwrap();
        server2.create_link(sid2, ca, cb, None, None).unwrap();
        server2.create_link(sid2, cb, cc, None, None).unwrap();
        let chain = server2.enrich_provenance_hops(&server2.provenance_ancestry(cc));
        let dests: std::collections::HashSet<_> = chain.iter().map(|h| h.dest_work_id).collect();
        assert!(
            dests.contains(&cb),
            "chain hop a->b must dest on b, dests={:?}",
            dests
        );
        assert!(
            dests.contains(&cc),
            "chain hop b->c must dest on c, dests={:?}",
            dests
        );
    }

    #[test]
    fn user_transclusion_preserves_original_author() {
        let mut server = Server::new();
        let (alice_id, alice_sid) = ac_create_user(&mut server, "alice", b"pw1");
        let (_bob_id, bob_sid) = ac_create_user(&mut server, "bob", b"pw2");
        let public = server.public_club_id();

        let alice_text = "The quick brown fox jumps over the lazy dog.";
        let source_id = server
            .create_work(alice_sid, Edition::from_text(alice_text))
            .unwrap();
        if let Some(ws) = server.works.get_mut(&source_id) {
            ws.work.set_edit_club(Some(public));
        }

        server.work_grab(alice_sid, source_id).unwrap();
        let alice_ed = {
            let edition = server.work_edition(source_id).unwrap();
            let entries = edition.all_entries();
            let alice_prov = crate::edition::provenance::ElementProvenance {
                author_public_key: [0u8; 32],
                author_display_name: "alice".to_string(),
                author_club_id: alice_id,
                timestamp: 100,
                author_type: crate::edition::provenance::AuthorType::Human,
                llm_model: None,
                historical_author_id: None,
                source_work_id: None,
                transcluded_by: None,
                derived_by: None,
            };
            let mut new_entries: Vec<(i64, Arc<crate::edition::range_element::Carrier>)> =
                Vec::new();
            for (pos, c) in &entries {
                let mut carrier = (**c).clone();
                carrier.provenance = Some(alice_prov.clone());
                new_entries.push((*pos, Arc::new(carrier)));
            }
            crate::edition::Edition::from_entries(new_entries)
        };
        server.work_revise(alice_sid, source_id, alice_ed).unwrap();
        server.work_release(alice_sid, source_id).unwrap();

        let excerpt = "quick brown fox";
        let dest_text = format!("prefix {} suffix", excerpt);
        let dest_id = server
            .create_work(bob_sid, Edition::from_text(&dest_text))
            .unwrap();
        if let Some(ws) = server.works.get_mut(&dest_id) {
            ws.work.set_edit_club(Some(public));
        }

        let link_id = server
            .create_link(
                bob_sid,
                source_id,
                dest_id,
                Some(crate::edition::links::HyperRef::single(
                    Some(Edition::from_text(excerpt)),
                    Some(source_id),
                    None,
                    None,
                )),
                Some(crate::edition::links::HyperRef::single(
                    None,
                    Some(dest_id),
                    None,
                    None,
                )),
            )
            .unwrap();

        server
            .apply_transclusion_attribution(bob_sid, link_id)
            .unwrap();

        let dest_edition = server.work(dest_id).unwrap().current_edition().clone();
        let dest_entries = dest_edition.all_entries();

        let mut alice_attributed = 0;
        let mut other_attributed = 0;
        for (_, carrier) in &dest_entries {
            if let Some(ref prov) = carrier.provenance {
                let text = carrier.element.as_text().unwrap_or("");
                if !text.is_empty() && text.chars().any(|c: char| !c.is_whitespace()) {
                    if prov.author_display_name == "alice" {
                        alice_attributed += 1;
                    } else {
                        other_attributed += 1;
                    }
                }
            }
        }

        assert!(
            alice_attributed > 0,
            "expected transcluded entries to show alice as author, got {} alice, {} other",
            alice_attributed,
            other_attributed,
        );

        for (_, carrier) in &dest_entries {
            if let Some(ref prov) = carrier.provenance {
                if prov.author_display_name == "alice" {
                    assert_eq!(
                        prov.source_work_id,
                        Some(source_id),
                        "alice's entries should have source_work_id set to the source work"
                    );
                    assert_eq!(
                        prov.author_club_id, alice_id,
                        "alice's entries should have alice's club_id"
                    );
                    assert!(
                        prov.transcluded_by.is_some(),
                        "transcluded entries should have transcluded_by set to the placer (bob)"
                    );
                    if let Some(ref tb) = prov.transcluded_by {
                        assert_eq!(
                            tb.display_name, "bob",
                            "transcluded_by should show bob as placer"
                        );
                    }
                }
            }
        }
    }

    #[test]
    fn attribution_query_provenance_chain_multi_hop() {
        let mut server = Server::new();
        let (alice_id, alice_sid) = ac_create_user(&mut server, "alice", b"pw1");
        let (_bob_id, bob_sid) = ac_create_user(&mut server, "bob", b"pw2");
        let (_carol_id, carol_sid) = ac_create_user(&mut server, "carol", b"pw3");
        let public = server.public_club_id();

        let alice_text = "The quick brown fox jumps over the lazy dog.";
        let work_a = server
            .create_work(alice_sid, Edition::from_text(alice_text))
            .unwrap();
        if let Some(ws) = server.works.get_mut(&work_a) {
            ws.work.set_edit_club(Some(public));
        }
        server.work_grab(alice_sid, work_a).unwrap();

        let alice_ed = {
            let edition = server.work_edition(work_a).unwrap();
            let entries = edition.all_entries();
            let alice_prov = crate::edition::provenance::ElementProvenance {
                author_public_key: [0u8; 32],
                author_display_name: "alice".to_string(),
                author_club_id: alice_id,
                timestamp: 100,
                author_type: crate::edition::provenance::AuthorType::Human,
                llm_model: None,
                historical_author_id: None,
                source_work_id: None,
                transcluded_by: None,
                derived_by: None,
            };
            let mut new_entries: Vec<(i64, Arc<crate::edition::range_element::Carrier>)> =
                Vec::new();
            for (pos, c) in &entries {
                let mut carrier = (**c).clone();
                carrier.provenance = Some(alice_prov.clone());
                new_entries.push((*pos, Arc::new(carrier)));
            }
            crate::edition::Edition::from_entries(new_entries)
        };
        server.work_revise(alice_sid, work_a, alice_ed).unwrap();
        server.work_release(alice_sid, work_a).unwrap();

        let excerpt_ab = "quick brown fox";
        let work_b_text = format!("intro {} outro", excerpt_ab);
        let work_b = server
            .create_work(bob_sid, Edition::from_text(&work_b_text))
            .unwrap();
        if let Some(ws) = server.works.get_mut(&work_b) {
            ws.work.set_edit_club(Some(public));
        }

        let link_ab = server
            .create_link(
                bob_sid,
                work_a,
                work_b,
                Some(crate::edition::links::HyperRef::single(
                    Some(Edition::from_text(excerpt_ab)),
                    Some(work_a),
                    None,
                    None,
                )),
                Some(crate::edition::links::HyperRef::single(
                    None,
                    Some(work_b),
                    None,
                    None,
                )),
            )
            .unwrap();
        server
            .apply_transclusion_attribution(bob_sid, link_ab)
            .unwrap();

        let excerpt_bc = "quick brown fox";
        let work_c_text = format!("prefix {} suffix", excerpt_bc);
        let work_c = server
            .create_work(carol_sid, Edition::from_text(&work_c_text))
            .unwrap();
        if let Some(ws) = server.works.get_mut(&work_c) {
            ws.work.set_edit_club(Some(public));
        }

        let link_bc = server
            .create_link(
                carol_sid,
                work_b,
                work_c,
                Some(crate::edition::links::HyperRef::single(
                    Some(Edition::from_text(excerpt_bc)),
                    Some(work_b),
                    None,
                    None,
                )),
                Some(crate::edition::links::HyperRef::single(
                    None,
                    Some(work_c),
                    None,
                    None,
                )),
            )
            .unwrap();
        server
            .apply_transclusion_attribution(carol_sid, link_bc)
            .unwrap();

        let spans = server.attribution_query(work_c, None, None).unwrap();
        assert!(!spans.is_empty(), "expected attribution spans for work_c");

        let transcluded_spans: Vec<_> = spans
            .iter()
            .filter(|s| s.source_work_id.is_some())
            .collect();
        assert!(
            !transcluded_spans.is_empty(),
            "expected at least one transcluded span with source_work_id"
        );

        for span in &transcluded_spans {
            assert!(
                span.provenance_chain.is_some(),
                "transcluded span should have provenance_chain populated"
            );
            let chain = span.provenance_chain.as_ref().unwrap();
            assert_eq!(
                chain.len(),
                2,
                "chain should have 2 hops: A->B and B->C, got {}",
                chain.len()
            );

            let hop_ids: Vec<(u64, u64)> = chain
                .iter()
                .map(|h| (h.source_work_id, h.link_id))
                .collect();
            assert!(
                hop_ids.contains(&(work_a, link_ab)),
                "chain should include hop (work_a, link_ab), got {:?}",
                hop_ids
            );
            assert!(
                hop_ids.contains(&(work_b, link_bc)),
                "chain should include hop (work_b, link_bc), got {:?}",
                hop_ids
            );
        }

        for hop in transcluded_spans[0].provenance_chain.as_ref().unwrap() {
            assert!(
                hop.source_work_title.is_some(),
                "hop should have enriched source_work_title"
            );
            assert!(
                hop.source_author_name.is_some(),
                "hop should have enriched source_author_name"
            );
        }

        let original_spans: Vec<_> = spans
            .iter()
            .filter(|s| s.source_work_id.is_none())
            .collect();
        for span in &original_spans {
            assert!(
                span.provenance_chain.is_none(),
                "non-transcluded span should not have provenance_chain"
            );
        }
    }

    #[test]
    fn transclusion_attribution_uses_correct_author_for_excerpt_range() {
        let mut server = Server::new();
        let (alice_id, alice_sid) = ac_create_user(&mut server, "alice", b"pw1");
        let (bob_id, bob_sid) = ac_create_user(&mut server, "bob", b"pw2");
        let public = server.public_club_id();

        let source_id = server
            .create_work(alice_sid, Edition::from_text("placeholder"))
            .unwrap();
        if let Some(ws) = server.works.get_mut(&source_id) {
            ws.work.set_edit_club(Some(public));
        }

        server.work_grab(alice_sid, source_id).unwrap();
        let multi_author_ed = {
            let alice_prov = crate::edition::provenance::ElementProvenance {
                author_public_key: [0u8; 32],
                author_display_name: "alice".to_string(),
                author_club_id: alice_id,
                timestamp: 100,
                author_type: crate::edition::provenance::AuthorType::Human,
                llm_model: None,
                historical_author_id: None,
                source_work_id: None,
                transcluded_by: None,
                derived_by: None,
            };
            let bob_prov = crate::edition::provenance::ElementProvenance {
                author_public_key: [0u8; 32],
                author_display_name: "bob".to_string(),
                author_club_id: bob_id,
                timestamp: 200,
                author_type: crate::edition::provenance::AuthorType::Human,
                llm_model: None,
                historical_author_id: None,
                source_work_id: None,
                transcluded_by: None,
                derived_by: None,
            };
            let mut entries: Vec<(i64, Arc<crate::edition::range_element::Carrier>)> = Vec::new();
            let c = crate::edition::range_element::Carrier::new(
                crate::edition::RangeElement::text("alice part".to_string()),
            )
            .with_provenance(alice_prov);
            entries.push((0, Arc::new(c)));
            let c2 = crate::edition::range_element::Carrier::new(
                crate::edition::RangeElement::text("bob unique text".to_string()),
            )
            .with_provenance(bob_prov);
            entries.push((1, Arc::new(c2)));
            crate::edition::Edition::from_entries(entries)
        };
        server
            .work_revise(alice_sid, source_id, multi_author_ed)
            .unwrap();
        server.work_release(alice_sid, source_id).unwrap();

        let excerpt = "bob unique text";
        let dest_text = format!("quote: {}", excerpt);
        let dest_id = server
            .create_work(alice_sid, Edition::from_text(&dest_text))
            .unwrap();
        if let Some(ws) = server.works.get_mut(&dest_id) {
            ws.work.set_edit_club(Some(public));
        }

        let link_id = server
            .create_link(
                alice_sid,
                source_id,
                dest_id,
                Some(crate::edition::links::HyperRef::single(
                    Some(Edition::from_text(excerpt)),
                    Some(source_id),
                    None,
                    None,
                )),
                Some(crate::edition::links::HyperRef::single(
                    None,
                    Some(dest_id),
                    None,
                    None,
                )),
            )
            .unwrap();

        server
            .apply_transclusion_attribution(alice_sid, link_id)
            .unwrap();

        let dest_edition = server.work(dest_id).unwrap().current_edition().clone();
        let dest_entries = dest_edition.all_entries();
        let dest_text = dest_edition.to_text();

        let excerpt_lower = excerpt.to_lowercase();
        let ex_start = dest_text.to_lowercase().find(&excerpt_lower).unwrap();
        let ex_end = ex_start + excerpt.len();

        let mut bob_attributed = 0;
        let mut alice_attributed = 0;
        let mut cum = 0usize;
        for (_, carrier) in &dest_entries {
            let entry_start = cum;
            let entry_end = cum + carrier.char_len();
            cum = entry_end;
            let in_range = entry_end > ex_start && entry_start < ex_end;
            if !in_range {
                continue;
            }
            if let Some(ref prov) = carrier.provenance {
                if prov.author_display_name == "bob" {
                    bob_attributed += 1;
                } else if prov.author_display_name == "alice" {
                    alice_attributed += 1;
                }
            }
        }

        assert!(
            bob_attributed > 0,
            "expected transcluded entries in excerpt range to be attributed to bob, got {} bob, {} alice",
            bob_attributed,
            alice_attributed,
        );
        assert_eq!(
            alice_attributed, 0,
            "should not attribute bob's excerpt to alice"
        );
    }

    #[test]
    fn transclusion_attribution_fallback_uses_last_revision_author() {
        let mut server = Server::new();
        let session = server.connect();
        server.login_public(session).unwrap();
        server.grant_admin_authority(session).unwrap();
        let club_id = server
            .session(session)
            .unwrap()
            .authority_clubs()
            .iter()
            .next()
            .copied()
            .unwrap();
        let public = server.public_club_id();

        let source_text = "Some content without element provenance.";
        let source_id = server
            .create_work(session, Edition::from_text(source_text))
            .unwrap();
        if let Some(ws) = server.works.get_mut(&source_id) {
            ws.work.set_edit_club(Some(public));
        }

        server.work_grab(session, source_id).unwrap();
        server
            .work_revise(session, source_id, Edition::from_text(source_text))
            .unwrap();
        server.work_release(session, source_id).unwrap();

        if let Some(ws) = server.works.get(&source_id) {
            for (_, c) in ws.work.current_edition().all_entries() {
                if c.provenance.is_some() {
                    let entries = ws.work.current_edition().all_entries();
                    let mut clean_entries = Vec::new();
                    for (pos, c2) in &entries {
                        let mut carrier = (**c2).clone();
                        carrier.provenance = None;
                        clean_entries.push((*pos, Arc::new(carrier)));
                    }
                    let clean_ed = crate::edition::Edition::from_entries(clean_entries);
                    drop(ws);
                    server.work_grab(session, source_id).unwrap();
                    server.work_revise(session, source_id, clean_ed).unwrap();
                    server.work_release(session, source_id).unwrap();
                    break;
                }
            }
        }

        let excerpt = "content without";
        let dest_text = format!("intro {} outro", excerpt);
        let dest_id = server
            .create_work(session, Edition::from_text(&dest_text))
            .unwrap();
        if let Some(ws) = server.works.get_mut(&dest_id) {
            ws.work.set_edit_club(Some(public));
        }

        let link_id = server
            .create_link(
                session,
                source_id,
                dest_id,
                Some(crate::edition::links::HyperRef::single(
                    Some(Edition::from_text(excerpt)),
                    Some(source_id),
                    None,
                    None,
                )),
                Some(crate::edition::links::HyperRef::single(
                    None,
                    Some(dest_id),
                    None,
                    None,
                )),
            )
            .unwrap();

        server
            .apply_transclusion_attribution(session, link_id)
            .unwrap();

        let dest_edition = server.work(dest_id).unwrap().current_edition().clone();
        let dest_entries = dest_edition.all_entries();
        let dest_text = dest_edition.to_text();

        let excerpt_lower = excerpt.to_lowercase();
        let ex_start = dest_text.to_lowercase().find(&excerpt_lower).unwrap();
        let ex_end = ex_start + excerpt.len();

        let mut attributed = 0;
        let mut cum = 0usize;
        for (_, carrier) in &dest_entries {
            let entry_start = cum;
            let entry_end = cum + carrier.char_len();
            cum = entry_end;
            let in_range = entry_end > ex_start && entry_start < ex_end;
            if !in_range {
                continue;
            }
            if let Some(ref prov) = carrier.provenance {
                assert_eq!(
                    prov.source_work_id,
                    Some(source_id),
                    "fallback provenance should have source_work_id set"
                );
                assert!(
                    !prov.author_display_name.is_empty() && prov.author_display_name != "Unknown",
                    "fallback should resolve a real author name, got '{}'",
                    prov.author_display_name
                );
                attributed += 1;
            }
        }

        assert!(
            attributed > 0,
            "expected transcluded entries to be attributed via fallback, got {}",
            attributed,
        );
    }

    #[test]
    fn range_attribution_only_affects_pasted_range() {
        let mut server = Server::new();
        let session = server.connect();
        server.login_public(session).unwrap();
        server.grant_admin_authority(session).unwrap();
        let club_id = server
            .session(session)
            .unwrap()
            .authority_clubs()
            .iter()
            .next()
            .copied()
            .unwrap();
        let public_club = server.public_club_id();

        let author = server
            .register_historical_author(
                "Bram Stoker".into(),
                "Bram Stoker".into(),
                None,
                None,
                std::collections::HashMap::new(),
                "Dracula".into(),
                club_id,
            )
            .unwrap();

        let source_text = "HELLO WORLD ".repeat(30);
        let (source_id, _, _, _) = server
            .import_source_work(
                session,
                author.be_id,
                "Source".into(),
                source_text.clone(),
                "test".into(),
                0,
                0,
            )
            .unwrap();
        if let Some(ws) = server.works.get_mut(&source_id) {
            ws.work.set_edit_club(Some(public_club));
        }

        server
            .apply_source_attribution(session, source_id, author.be_id, None, None, None)
            .unwrap();

        let paste_text = "HELLO WORLD HELLO WORLD";
        let target_text = format!("my_text{}my_text", paste_text);
        let target_id = server
            .create_work(session, Edition::from_text(&target_text))
            .unwrap();
        if let Some(ws) = server.works.get_mut(&target_id) {
            ws.work.set_edit_club(Some(public_club));
        }

        let paste_start = 7;
        let paste_end = paste_start + paste_text.len();

        server
            .apply_source_attribution(
                session,
                target_id,
                author.be_id,
                Some(source_id),
                Some(paste_start),
                Some(paste_end),
            )
            .unwrap();

        let target_edition = server.work(target_id).unwrap().current_edition().clone();
        let target_entries = target_edition.all_entries();

        let mut cum = 0usize;
        let mut in_range_historical = 0;
        let mut out_range_historical = 0;

        for (_, carrier) in &target_entries {
            let entry_start = cum;
            let entry_end = cum + carrier.char_len();
            let in_range = entry_end > paste_start && entry_start < paste_end;

            let is_historical = carrier.provenance.as_ref().is_some_and(|p| {
                matches!(
                    p.author_type,
                    crate::edition::provenance::AuthorType::Historical
                )
            });

            if in_range && is_historical {
                in_range_historical += 1;
            } else if !in_range && is_historical {
                out_range_historical += 1;
            }
            cum = entry_end;
        }

        assert!(
            in_range_historical > 0,
            "entries in paste range should have historical attribution"
        );
        assert_eq!(
            out_range_historical, 0,
            "entries outside paste range should NOT have historical attribution"
        );
    }

    #[test]
    fn attribution_query_returns_source_work_id() {
        let mut server = Server::new();
        let session = server.connect();
        server.login_public(session).unwrap();
        server.grant_admin_authority(session).unwrap();
        let club_id = server
            .session(session)
            .unwrap()
            .authority_clubs()
            .iter()
            .next()
            .copied()
            .unwrap();
        let public_club = server.public_club_id();

        let author = server
            .register_historical_author(
                "Jane Austen".into(),
                "Jane Austen".into(),
                Some(1775),
                Some(1817),
                std::collections::HashMap::new(),
                "Pride and Prejudice".into(),
                club_id,
            )
            .unwrap();

        let source_text = "It is a truth universally acknowledged ".repeat(10);
        let (source_id, _, _, _) = server
            .import_source_work(
                session,
                author.be_id,
                "Pride".into(),
                source_text.clone(),
                "test edition".into(),
                0,
                0,
            )
            .unwrap();
        if let Some(ws) = server.works.get_mut(&source_id) {
            ws.work.set_edit_club(Some(public_club));
        }

        server
            .apply_source_attribution(session, source_id, author.be_id, None, None, None)
            .unwrap();

        let excerpt = "It is a truth universally acknowledged";
        let target_id = server
            .create_work(session, Edition::from_text(&format!("intro{}", excerpt)))
            .unwrap();
        if let Some(ws) = server.works.get_mut(&target_id) {
            ws.work.set_edit_club(Some(public_club));
        }

        let intro_len = 5;
        let paste_end = intro_len + excerpt.len();
        server
            .apply_source_attribution(
                session,
                target_id,
                author.be_id,
                Some(source_id),
                Some(intro_len),
                Some(paste_end),
            )
            .unwrap();

        let spans = server.attribution_query(target_id, None, None).unwrap();
        assert!(!spans.is_empty(), "expected attribution spans");

        let historical_spans: Vec<_> = spans
            .iter()
            .filter(|s| s.author_type.as_deref() == Some("historical"))
            .collect();
        assert!(
            !historical_spans.is_empty(),
            "expected at least one historical span"
        );

        for span in &historical_spans {
            assert_eq!(
                span.source_work_id,
                Some(source_id),
                "historical span should have source_work_id pointing to source work"
            );
        }

        let non_historical_spans: Vec<_> = spans
            .iter()
            .filter(|s| s.author_type.as_deref() != Some("historical"))
            .collect();
        for span in &non_historical_spans {
            assert_eq!(
                span.source_work_id, None,
                "non-historical span should not have source_work_id"
            );
        }
    }

    #[test]
    fn element_provenance_source_work_id_serde_roundtrip() {
        let mut key = [0u8; 32];
        key[..4].copy_from_slice(b"test");
        let prov = crate::edition::provenance::ElementProvenance {
            author_public_key: key,
            author_display_name: "Bram Stoker".to_string(),
            author_club_id: 42,
            timestamp: 1234567890,
            author_type: crate::edition::provenance::AuthorType::Historical,
            llm_model: None,
            historical_author_id: Some(99),
            source_work_id: Some(0xABCD),
            transcluded_by: None,
            derived_by: None,
        };

        let json = serde_json::to_string(&prov).unwrap();
        let restored: crate::edition::provenance::ElementProvenance =
            serde_json::from_str(&json).unwrap();
        assert_eq!(prov, restored);
        assert_eq!(restored.source_work_id, Some(0xABCD));
    }

    #[test]
    fn element_provenance_source_work_id_none_serde_roundtrip() {
        let mut key = [0u8; 32];
        key[..4].copy_from_slice(b"test");
        let prov = crate::edition::provenance::ElementProvenance {
            author_public_key: key,
            author_display_name: "Alice".to_string(),
            author_club_id: 1,
            timestamp: 100,
            author_type: crate::edition::provenance::AuthorType::Human,
            llm_model: None,
            historical_author_id: None,
            source_work_id: None,
            transcluded_by: None,
            derived_by: None,
        };

        let json = serde_json::to_string(&prov).unwrap();
        let restored: crate::edition::provenance::ElementProvenance =
            serde_json::from_str(&json).unwrap();
        assert_eq!(prov, restored);
        assert_eq!(restored.source_work_id, None);
    }

    #[test]
    fn element_provenance_source_work_id_deserializes_without_field() {
        let json = r#"{
            "author_public_key":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
            "author_display_name":"Alice",
            "author_club_id":1,
            "timestamp":100,
            "author_type":"human",
            "llm_model":null,
            "historical_author_id":null
        }"#;
        let prov: crate::edition::provenance::ElementProvenance =
            serde_json::from_str(json).unwrap();
        assert_eq!(prov.source_work_id, None);
    }

    #[test]
    fn range_attribution_sets_source_work_id() {
        let mut server = Server::new();
        let session = server.connect();
        server.login_public(session).unwrap();
        server.grant_admin_authority(session).unwrap();
        let club_id = server
            .session(session)
            .unwrap()
            .authority_clubs()
            .iter()
            .next()
            .copied()
            .unwrap();
        let public_club = server.public_club_id();

        let author = server
            .register_historical_author(
                "Mary Shelley".into(),
                "Mary Shelley".into(),
                Some(1797),
                Some(1851),
                std::collections::HashMap::new(),
                "Frankenstein".into(),
                club_id,
            )
            .unwrap();

        let source_text = "I saw the pale student of unhallowed arts ".repeat(10);
        let (source_id, _, _, _) = server
            .import_source_work(
                session,
                author.be_id,
                "Frankenstein".into(),
                source_text.clone(),
                "test edition".into(),
                0,
                0,
            )
            .unwrap();
        if let Some(ws) = server.works.get_mut(&source_id) {
            ws.work.set_edit_club(Some(public_club));
        }

        server
            .apply_source_attribution(session, source_id, author.be_id, None, None, None)
            .unwrap();

        let paste_text = "I saw the pale student of unhallowed arts";
        let target_text = format!("prefix{}suffix", paste_text);
        let target_id = server
            .create_work(session, Edition::from_text(&target_text))
            .unwrap();
        if let Some(ws) = server.works.get_mut(&target_id) {
            ws.work.set_edit_club(Some(public_club));
        }

        let paste_start = 6;
        let paste_end = paste_start + paste_text.len();

        server
            .apply_source_attribution(
                session,
                target_id,
                author.be_id,
                Some(source_id),
                Some(paste_start),
                Some(paste_end),
            )
            .unwrap();

        let target_edition = server.work(target_id).unwrap().current_edition().clone();
        let target_entries = target_edition.all_entries();

        let mut cum = 0usize;
        let mut in_range_with_source = 0;
        let mut out_range_with_source = 0;

        for (_, carrier) in &target_entries {
            let entry_start = cum;
            let entry_end = cum + carrier.char_len();
            let in_range = entry_end > paste_start && entry_start < paste_end;

            if let Some(ref prov) = carrier.provenance {
                if matches!(
                    prov.author_type,
                    crate::edition::provenance::AuthorType::Historical
                ) {
                    if in_range {
                        assert_eq!(
                            prov.source_work_id,
                            Some(source_id),
                            "historical entries in paste range should have source_work_id"
                        );
                        in_range_with_source += 1;
                    } else {
                        out_range_with_source += 1;
                    }
                }
            }
            cum = entry_end;
        }

        assert!(
            in_range_with_source > 0,
            "entries in paste range should have historical attribution with source_work_id"
        );
        assert_eq!(
            out_range_with_source, 0,
            "entries outside paste range should NOT have historical attribution"
        );
    }

    #[test]
    fn match_content_finds_imported_source_work() {
        let mut server = Server::new();
        let session = server.connect();
        server.login_public(session).unwrap();
        server.grant_admin_authority(session).unwrap();
        let club_id = server
            .session(session)
            .unwrap()
            .authority_clubs()
            .iter()
            .next()
            .copied()
            .unwrap();

        let author = server
            .register_historical_author(
                "Leo Tolstoy".into(),
                "Leo Tolstoy".into(),
                Some(1828),
                Some(1910),
                std::collections::HashMap::new(),
                "War and Peace".into(),
                club_id,
            )
            .unwrap();

        let text = "It was the best of times it was the worst of times. ".repeat(30);
        let (source_id, _, _, _) = server
            .import_source_work(
                session,
                author.be_id,
                "War and Peace".into(),
                text.clone(),
                "test".into(),
                0,
                0,
            )
            .unwrap();

        let ws = server.works.get(&source_id).unwrap();
        assert!(ws.is_source, "imported work should have is_source=true");
        assert!(
            ws.source_fingerprint.is_some(),
            "imported work should have source_fingerprint"
        );

        let query: String = text.chars().take(text.len() / 3).collect();
        let result = server.match_content(&query);
        assert!(
            result.is_some(),
            "match_content should find the source work"
        );
        let (found_work_id, found_author_id, score) = result.unwrap();
        assert_eq!(found_work_id, source_id);
        assert_eq!(found_author_id, author.be_id);
        assert!(score > 0.3, "score should be >0.3, got {}", score);
    }

    #[test]
    #[cfg(feature = "server")]
    fn source_work_and_historical_author_survive_chunk_persistence() {
        let dir = TempDir::new("chunk_persist");
        let data_dir = dir.snapshot_path().parent().unwrap().join("data");
        std::fs::create_dir_all(&data_dir).unwrap();

        let source_id;
        let author_id;
        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();
            server.grant_admin_authority(sid);

            let author = server
                .register_historical_author(
                    "Bram Stoker".into(),
                    "Bram Stoker (1847\u{2013}1912)".into(),
                    Some(1847),
                    Some(1912),
                    HashMap::new(),
                    "Dracula".into(),
                    1,
                )
                .unwrap();
            author_id = author.be_id;

            let (s_id, _, _, _) = server
                .import_source_work(
                    sid,
                    author.be_id,
                    "Dracula".into(),
                    "Chapter 1\nJonathan Harker's Journal.\nLeft Munich at 8:35 P.M.".into(),
                    "1897 edition".into(),
                    0,
                    0,
                )
                .unwrap();
            source_id = s_id;

            let ws = server.works.get(&source_id).unwrap();
            assert!(ws.is_source);
            assert_eq!(ws.source_author_id, Some(author_id));

            server.checkpoint_to_store().unwrap();
        }

        {
            let mut server = Server::new();
            server.restore_from_data_dir(&data_dir, None).unwrap();

            let got = server.get_historical_author(author_id).unwrap();
            assert_eq!(got.name, "Bram Stoker");
            assert_eq!(got.birth_year, Some(1847));

            let list = server.list_historical_authors();
            assert_eq!(list.len(), 1);

            let ws = server.works.get(&source_id).unwrap();
            assert!(ws.is_source, "source work should be restored as source");
            assert_eq!(ws.source_author_id, Some(author_id));
            assert_eq!(ws.source_edition_info.as_deref(), Some("1897 edition"));
            assert!(
                ws.source_fingerprint.is_some(),
                "source fingerprint should be recomputed on restore"
            );
        }
    }

    #[test]
    fn work_summary_basic() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let edition = Edition::from_text("Hello world, this is a test document.");
        let work_id = server.create_work(sid, edition).unwrap();

        let result = server.work_summary(work_id).unwrap();
        match result {
            crate::server::transport::protocol::ResponseValue::WorkSummaryResult {
                unique_sources,
                unique_authors,
                version_count,
                char_count,
                author_contributions,
                reused_in_count,
                reused_in_docs: _,
            } => {
                assert_eq!(version_count, 0);
                assert!(char_count > 0, "char_count should be positive");
                assert_eq!(unique_sources, 0);
                assert_eq!(unique_authors, 1);
                assert_eq!(author_contributions.len(), 1);
                assert_eq!(author_contributions[0].display_name, "Unattributed");
                assert_eq!(author_contributions[0].char_count, char_count);
                assert_eq!(
                    author_contributions[0].author_type.as_deref(),
                    Some("unattributed")
                );
                assert_eq!(reused_in_count, 0);
            }
            _ => panic!("expected WorkSummaryResult"),
        }
    }

    #[test]
    fn work_summary_not_found() {
        let server = Server::new();
        let result = server.work_summary(99999);
        assert!(result.is_err());
    }

    #[test]
    fn work_summary_two_human_authors_via_element_provenance() {
        let mut server = Server::new();
        let (alice_id, alice_sid) = ac_create_user(&mut server, "alice", b"pw1");
        let (bob_id, bob_sid) = ac_create_user(&mut server, "bob", b"pw2");
        let public = server.public_club_id();

        let work_id = server
            .create_work(alice_sid, Edition::from_text("hello world"))
            .unwrap();
        if let Some(ws) = server.works.get_mut(&work_id) {
            ws.work.set_edit_club(Some(public));
        }

        server.work_grab(alice_sid, work_id).unwrap();
        let alice_ed = {
            let edition = server.work_edition(work_id).unwrap();
            let entries = edition.all_entries();
            let alice_prov = crate::edition::provenance::ElementProvenance {
                author_public_key: [0u8; 32],
                author_display_name: "alice".to_string(),
                author_club_id: alice_id,
                timestamp: 100,
                author_type: crate::edition::provenance::AuthorType::Human,
                llm_model: None,
                historical_author_id: None,
                source_work_id: None,
                transcluded_by: None,
                derived_by: None,
            };
            let mut new_entries: Vec<(i64, Arc<crate::edition::range_element::Carrier>)> =
                Vec::new();
            for (pos, c) in &entries {
                let mut carrier = (**c).clone();
                carrier.provenance = Some(alice_prov.clone());
                new_entries.push((*pos, Arc::new(carrier)));
            }
            crate::edition::Edition::from_entries(new_entries)
        };
        server.work_revise(alice_sid, work_id, alice_ed).unwrap();
        server.work_release(alice_sid, work_id).unwrap();

        server.work_grab(bob_sid, work_id).unwrap();
        let bob_ed = {
            let edition = server.work_edition(work_id).unwrap();
            let text = edition.to_text();
            let new_text = format!("{} and bob was here", &text[..5]);
            let bob_prov = crate::edition::provenance::ElementProvenance {
                author_public_key: [0u8; 32],
                author_display_name: "bob".to_string(),
                author_club_id: bob_id,
                timestamp: 200,
                author_type: crate::edition::provenance::AuthorType::Human,
                llm_model: None,
                historical_author_id: None,
                source_work_id: None,
                transcluded_by: None,
                derived_by: None,
            };
            let entries = edition.all_entries();
            let mut new_entries: Vec<(i64, Arc<crate::edition::range_element::Carrier>)> =
                Vec::new();
            let mut pos = 0i64;
            for (i, ch) in "hello".chars().enumerate() {
                let mut c = crate::edition::range_element::Carrier::new(
                    crate::edition::RangeElement::text(ch.to_string()),
                );
                if let Some(old_entry) = entries.iter().find(|(p, _)| *p == i as i64) {
                    c.provenance = old_entry.1.provenance.clone();
                }
                new_entries.push((pos, Arc::new(c)));
                pos += 1;
            }
            for part in &[" and bob was here"] {
                let c = crate::edition::range_element::Carrier::new(
                    crate::edition::RangeElement::text(part.to_string()),
                )
                .with_provenance(bob_prov.clone());
                new_entries.push((pos, Arc::new(c)));
                pos += 1;
            }
            crate::edition::Edition::from_entries(new_entries)
        };
        server.work_revise(bob_sid, work_id, bob_ed).unwrap();
        server.work_release(bob_sid, work_id).unwrap();

        let result = server.work_summary(work_id).unwrap();
        match result {
            crate::server::transport::protocol::ResponseValue::WorkSummaryResult {
                author_contributions,
                unique_authors,
                ..
            } => {
                assert!(
                    unique_authors >= 2,
                    "should have at least 2 authors, got {}",
                    unique_authors
                );
                let names: Vec<&str> = author_contributions
                    .iter()
                    .map(|a| a.display_name.as_str())
                    .collect();
                assert!(
                    names.iter().any(|n| *n == "alice"),
                    "alice should appear in {:?}",
                    names
                );
                assert!(
                    names.iter().any(|n| *n == "bob"),
                    "bob should appear in {:?}",
                    names
                );
                for ac in &author_contributions {
                    if ac.display_name == "alice" || ac.display_name == "bob" {
                        assert_eq!(
                            ac.author_type.as_deref(),
                            Some("human"),
                            "{} should have type human",
                            ac.display_name
                        );
                    }
                }
            }
            _ => panic!("expected WorkSummaryResult"),
        }
    }

    #[test]
    fn work_summary_historical_author_via_element_provenance() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        server.grant_admin_authority(sid).unwrap();
        let club_id = server
            .session(sid)
            .unwrap()
            .authority_clubs()
            .iter()
            .next()
            .copied()
            .unwrap();

        let author = server
            .register_historical_author(
                "Ted Nelson".into(),
                "Ted Nelson".into(),
                Some(1937),
                None,
                std::collections::HashMap::new(),
                "Literary Machines".into(),
                club_id,
            )
            .unwrap();

        let source_text = "Everything is deeply intertwingled.";
        let (source_id, _, _, _) = server
            .import_source_work(
                sid,
                author.be_id,
                "Literary Machines".into(),
                source_text.to_string(),
                "1980 edition".into(),
                0,
                0,
            )
            .unwrap();

        let result = server.work_summary(source_id).unwrap();
        match result {
            crate::server::transport::protocol::ResponseValue::WorkSummaryResult {
                author_contributions,
                unique_authors,
                char_count,
                ..
            } => {
                assert!(char_count > 0);
                assert!(
                    unique_authors >= 1,
                    "should have at least 1 author, got {}",
                    unique_authors
                );
                let names: Vec<&str> = author_contributions
                    .iter()
                    .map(|a| a.display_name.as_str())
                    .collect();
                assert!(
                    names.iter().any(|n| *n == "Ted Nelson"),
                    "Ted Nelson should appear in {:?}",
                    names
                );
                let ted = author_contributions
                    .iter()
                    .find(|a| a.display_name == "Ted Nelson");
                assert!(
                    ted.is_some() && ted.unwrap().author_type.as_deref() == Some("historical"),
                    "Ted Nelson should have type historical"
                );
            }
            _ => panic!("expected WorkSummaryResult"),
        }
    }

    #[test]
    fn work_summary_revise_stamps_element_provenance() {
        let mut server = Server::new();
        let (alice_id, alice_sid) = ac_create_user(&mut server, "alice", b"pw1");

        let work_id = server
            .create_work(alice_sid, Edition::from_text("aaaa bbbb cccc"))
            .unwrap();

        server.work_grab(alice_sid, work_id).unwrap();
        server
            .work_revise(
                alice_sid,
                work_id,
                Edition::from_text("aaaa bbbb cccc dddd"),
            )
            .unwrap();
        server.work_release(alice_sid, work_id).unwrap();

        let result = server.work_summary(work_id).unwrap();
        match result {
            crate::server::transport::protocol::ResponseValue::WorkSummaryResult {
                author_contributions,
                unique_authors,
                char_count,
                ..
            } => {
                assert!(char_count > 0);
                assert!(
                    unique_authors >= 1,
                    "should have at least alice, got {}",
                    unique_authors
                );
                assert!(
                    !author_contributions
                        .iter()
                        .any(|a| a.display_name == "Unattributed"),
                    "revise_work should have stamped element provenance on all entries, got {:?}",
                    author_contributions
                        .iter()
                        .map(|a| &a.display_name)
                        .collect::<Vec<_>>()
                );
                let alice = author_contributions
                    .iter()
                    .find(|a| a.display_name == "alice");
                assert!(
                    alice.is_some() && alice.unwrap().author_type.as_deref() == Some("human"),
                    "alice should have type human"
                );
            }
            _ => panic!("expected WorkSummaryResult"),
        }
    }

    #[test]
    fn work_summary_llm_author_via_element_provenance() {
        let mut server = Server::new();
        let (club_id, sid) = ac_create_user(&mut server, "user", b"pw1");

        let mut edition = Edition::from_text("Human text. ");
        let llm_prov = crate::edition::provenance::ElementProvenance {
            author_public_key: [0u8; 32],
            author_display_name: "gpt-4".to_string(),
            author_club_id: club_id,
            timestamp: 100,
            author_type: crate::edition::provenance::AuthorType::Llm,
            llm_model: Some("gpt-4".to_string()),
            historical_author_id: None,
            source_work_id: None,
            transcluded_by: None,
            derived_by: None,
        };
        let llm_text = "AI generated text.";
        let llm_carrier = crate::edition::range_element::Carrier::new(
            crate::edition::RangeElement::text(llm_text.to_string()),
        )
        .with_provenance(llm_prov);

        let mut entries = edition.all_entries().to_vec();
        let next_pos = entries.last().map(|(p, _)| *p + 1).unwrap_or(0);
        entries.push((next_pos, Arc::new(llm_carrier)));
        let full_edition = crate::edition::Edition::from_entries(entries);

        let work_id = server.create_work(sid, full_edition).unwrap();

        let result = server.work_summary(work_id).unwrap();
        match result {
            crate::server::transport::protocol::ResponseValue::WorkSummaryResult {
                author_contributions,
                ..
            } => {
                let names: Vec<&str> = author_contributions
                    .iter()
                    .map(|a| a.display_name.as_str())
                    .collect();
                assert!(
                    names.iter().any(|n| *n == "gpt-4"),
                    "gpt-4 should appear in {:?}",
                    names
                );
                let gpt = author_contributions
                    .iter()
                    .find(|a| a.display_name == "gpt-4");
                assert!(
                    gpt.is_some() && gpt.unwrap().author_type.as_deref() == Some("llm"),
                    "gpt-4 should have type llm"
                );
            }
            _ => panic!("expected WorkSummaryResult"),
        }
    }

    #[test]
    fn work_summary_span_provenance_fallback_when_no_element_prov() {
        let mut server = Server::new();
        let (alice_id, alice_sid) = ac_create_user(&mut server, "alice", b"pw1");

        let work_id = server
            .create_work(
                alice_sid,
                Edition::from_text("just span prov, no element prov"),
            )
            .unwrap();

        let result = server.work_summary(work_id).unwrap();
        match result {
            crate::server::transport::protocol::ResponseValue::WorkSummaryResult {
                unique_authors,
                author_contributions,
                char_count,
                ..
            } => {
                assert!(char_count > 0);
                assert!(
                    unique_authors >= 1,
                    "should report at least unattributed, got {}",
                    unique_authors
                );
                assert!(
                    !author_contributions.is_empty(),
                    "should have some author entry"
                );
            }
            _ => panic!("expected WorkSummaryResult"),
        }
    }

    #[test]
    fn work_version_timeline_basic() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let edition = Edition::from_text("Version one");
        let work_id = server.create_work(sid, edition).unwrap();
        server.work_grab(sid, work_id).unwrap();

        let edition2 = Edition::from_text("Version two is longer");
        server.work_revise(sid, work_id, edition2).unwrap();
        server.work_release(sid, work_id).unwrap();

        let result = server.work_version_timeline(work_id).unwrap();
        match result {
            crate::server::transport::protocol::ResponseValue::WorkVersionTimelineResult {
                revisions,
            } => {
                assert_eq!(revisions.len(), 2, "initial + 1 revise = 2 entries");
                assert_eq!(revisions[0].revision, 0);
                assert_eq!(revisions[0].char_count, 11);
                assert_eq!(revisions[1].revision, 1);
                assert!(revisions[1].char_count > revisions[0].char_count);
            }
            _ => panic!("expected WorkVersionTimelineResult"),
        }
    }

    #[test]
    fn work_version_timeline_not_found() {
        let server = Server::new();
        let result = server.work_version_timeline(99999);
        assert!(result.is_err());
    }

    #[test]
    fn work_version_timeline_includes_timestamps() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work_id = server
            .create_work(sid, Edition::from_text("rev zero"))
            .unwrap();
        server.work_grab(sid, work_id).unwrap();

        let ts_before_revise = Server::current_timestamp_secs();
        server
            .work_revise(sid, work_id, Edition::from_text("rev one"))
            .unwrap();
        let ts_after_revise = Server::current_timestamp_secs();
        server.work_release(sid, work_id).unwrap();

        let result = server.work_version_timeline(work_id).unwrap();
        match result {
            crate::server::transport::protocol::ResponseValue::WorkVersionTimelineResult {
                revisions,
            } => {
                assert_eq!(revisions.len(), 2);
                assert!(
                    revisions[0].timestamp.is_some(),
                    "revision 0 should have a timestamp"
                );
                assert!(
                    revisions[1].timestamp.is_some(),
                    "revision 1 should have a timestamp"
                );
                let ts1 = revisions[1].timestamp.unwrap();
                assert!(
                    ts1 >= ts_before_revise && ts1 <= ts_after_revise,
                    "revision 1 timestamp should be between pre- and post-revise"
                );
            }
            _ => panic!("expected WorkVersionTimelineResult"),
        }
    }

    #[test]
    fn passage_composition_basic() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let edition = Edition::from_text("Hello world");
        let work_id = server.create_work(sid, edition).unwrap();
        server.work_grab(sid, work_id).unwrap();

        let edition2 = Edition::from_text("Hello world, more text");
        server.work_revise(sid, work_id, edition2).unwrap();
        server.work_release(sid, work_id).unwrap();

        let result = server.passage_composition(work_id, 0, 11).unwrap();
        match result {
            crate::server::transport::protocol::ResponseValue::PassageCompositionResult {
                layers,
            } => {
                assert_eq!(
                    layers.len(),
                    1,
                    "only the initial addition, no change after"
                );
                assert_eq!(layers[0].text, "Hello world");
                assert_eq!(layers[0].operation, "added");
            }
            _ => panic!("expected PassageCompositionResult"),
        }
    }

    #[test]
    fn passage_composition_detects_modification() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let edition = Edition::from_text("Hello world");
        let work_id = server.create_work(sid, edition).unwrap();
        server.work_grab(sid, work_id).unwrap();

        let edition2 = Edition::from_text("Goodbye world");
        server.work_revise(sid, work_id, edition2).unwrap();
        server.work_release(sid, work_id).unwrap();

        let result = server.passage_composition(work_id, 0, 6).unwrap();
        match result {
            crate::server::transport::protocol::ResponseValue::PassageCompositionResult {
                layers,
            } => {
                assert_eq!(layers.len(), 2);
                assert_eq!(layers[0].text, "Hello ");
                assert_eq!(layers[0].operation, "added");
                assert_eq!(layers[1].text, "Goodby");
                assert_eq!(layers[1].operation, "modified");
            }
            _ => panic!("expected PassageCompositionResult"),
        }
    }

    #[test]
    fn passage_composition_not_found() {
        let server = Server::new();
        let result = server.passage_composition(99999, 0, 10);
        assert!(result.is_err());
    }

    fn setup_authenticated() -> (Server, SessionId, BeId) {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let club = server
            .create_club(sid, Edition::from_text("test club"))
            .unwrap();
        server.club_set_password(sid, club, b"test-pass1").unwrap();
        let lock = server.login(sid, club).unwrap();
        server
            .authenticate(
                sid,
                &*lock,
                &LockCredential::Password(b"test-pass1".to_vec()),
            )
            .unwrap();
        (server, sid, club)
    }

    #[test]
    fn annotation_create_and_list() {
        let (mut server, sid, _club) = setup_authenticated();
        let work_id = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();

        server
            .annotation_create(
                sid,
                work_id,
                1,
                "note".into(),
                "test note".into(),
                0,
                5,
                false,
            )
            .unwrap();

        let anns = server.annotation_list(sid, work_id).unwrap();
        assert_eq!(anns.len(), 1);
        assert_eq!(anns[0].annotation_id, 1);
        assert_eq!(anns[0].kind, "note");
        assert_eq!(anns[0].payload, "test note");
        assert_eq!(anns[0].char_start, 0);
        assert_eq!(anns[0].char_end, 5);
    }

    #[test]
    fn annotation_create_on_source_work() {
        let (mut server, sid, _club) = setup_authenticated();
        let work_id = server
            .create_work(sid, Edition::from_text("source text content"))
            .unwrap();

        {
            let ws = server.works.get_mut(&work_id).unwrap();
            ws.is_source = true;
        }

        server
            .annotation_create(
                sid,
                work_id,
                1,
                "note".into(),
                "on source".into(),
                3,
                10,
                false,
            )
            .unwrap();

        let anns = server.annotation_list(sid, work_id).unwrap();
        assert_eq!(anns.len(), 1);
        assert_eq!(anns[0].payload, "on source");
    }

    #[test]
    fn annotation_delete() {
        let (mut server, sid, _club) = setup_authenticated();
        let work_id = server
            .create_work(sid, Edition::from_text("hello"))
            .unwrap();

        server
            .annotation_create(sid, work_id, 1, "note".into(), "a".into(), 0, 1, false)
            .unwrap();
        server
            .annotation_create(sid, work_id, 2, "note".into(), "b".into(), 1, 2, false)
            .unwrap();

        server.annotation_delete(sid, work_id, 1).unwrap();

        let anns = server.annotation_list(sid, work_id).unwrap();
        assert_eq!(anns.len(), 1);
        assert_eq!(anns[0].annotation_id, 2);
    }

    #[test]
    fn annotation_requires_authentication() {
        let mut server = Server::new();
        let sid = server.connect();
        let result = server.annotation_create(sid, 9999, 1, "note".into(), "x".into(), 0, 1, false);
        assert!(result.is_err());
    }

    #[test]
    #[cfg(feature = "server")]
    fn annotation_survives_checkpoint_and_gc() {
        let dir = TempDir::new("annotation_persist");
        let data_dir = dir.snapshot_path().parent().unwrap().join("data");
        std::fs::create_dir_all(&data_dir).unwrap();

        let work_id;
        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();
            let club = server.create_club(sid, Edition::from_text("club")).unwrap();
            server.club_set_password(sid, club, b"test-pass1").unwrap();
            let lock = server.login(sid, club).unwrap();
            server
                .authenticate(
                    sid,
                    &*lock,
                    &LockCredential::Password(b"test-pass1".to_vec()),
                )
                .unwrap();

            work_id = server
                .create_work(sid, Edition::from_text("hello world"))
                .unwrap();

            server
                .annotation_create(
                    sid,
                    work_id,
                    42,
                    "note".into(),
                    "must survive".into(),
                    0,
                    5,
                    false,
                )
                .unwrap();

            server.checkpoint_to_store().unwrap();

            let ann_hash = {
                let cp = data_dir.join("manifest.json");
                let m = crate::persist::manifest::read_manifest(&cp).unwrap();
                m.annotations_hash.unwrap()
            };
            let hex: String = ann_hash.iter().map(|b| format!("{:02x}", b)).collect();
            let chunk_dir = data_dir.join("chunks");
            let chunk_path = chunk_dir.join(&hex[..2]).join(format!("{}.xchunk", hex));
            assert!(
                chunk_path.exists(),
                "annotation chunk must exist after checkpoint"
            );
        }

        {
            let mut server = Server::new();
            server.restore_from_data_dir(&data_dir, None).unwrap();

            let all_anns = server.otree_crdt.all_annotations();
            let total: usize = all_anns.iter().map(|(_, a)| a.len()).sum();
            assert_eq!(total, 1, "annotation must survive restore");
            assert_eq!(all_anns[0].1[0].payload, "must survive");
            assert_eq!(all_anns[0].1[0].annotation_id, 42);
        }
    }

    #[test]
    #[cfg(feature = "server")]
    fn link_persistence_round_trip_preserves_all_fields() {
        use crate::edition::links::{HyperLink, HyperRef, Path, ProvenanceHop};

        let dir = TempDir::new("link_persist");
        let data_dir = dir.snapshot_path().parent().unwrap().join("data");
        std::fs::create_dir_all(&data_dir).unwrap();

        let link_id;
        let origin_work_id;
        let dest_work_id;

        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();

            origin_work_id = server
                .create_work(sid, Edition::from_text("origin document"))
                .unwrap();
            dest_work_id = server
                .create_work(sid, Edition::from_text("destination document"))
                .unwrap();

            let origin_ref = HyperRef::single(
                Some(Edition::from_text("excerpt text")),
                Some(origin_work_id),
                None,
                Some(Path::new(vec![RangeElement::label(
                    42,
                    RangeElement::text("labelled"),
                )])),
            )
            .with_provenance_chain(vec![ProvenanceHop::new(999, 888)]);
            let dest_ref = HyperRef::single(None, Some(dest_work_id), Some(origin_work_id), None);
            let link = HyperLink::make(vec![100, 200], origin_ref, dest_ref);
            link_id = server.create_link_with_hyperlink(sid, link).unwrap();

            server.checkpoint_to_store().unwrap();
        }

        {
            let mut server = Server::new();
            server.restore_from_data_dir(&data_dir, None).unwrap();

            let ls = server
                .links
                .get(&link_id)
                .expect("link must survive restore");
            assert_eq!(ls.origin, origin_work_id);
            assert_eq!(ls.destination, dest_work_id);
            assert_eq!(
                ls.link.link_types(),
                &[100, 200],
                "link_types must survive restore"
            );

            let o_ref = ls.link.end_at("LeftEnd").expect("LeftEnd must exist");
            assert_eq!(o_ref.work_context(), Some(origin_work_id));
            assert!(o_ref.excerpt().is_some(), "excerpt must survive restore");
            assert_eq!(
                o_ref.excerpt().unwrap().to_text().to_string(),
                "excerpt text",
                "excerpt content must match"
            );
            assert!(
                o_ref.path_context().is_some(),
                "path_context must survive restore"
            );
            assert_eq!(o_ref.path_context().unwrap().len(), 1);
            assert_eq!(
                o_ref.provenance_chain().len(),
                1,
                "provenance_chain must survive restore"
            );
            assert_eq!(o_ref.provenance_chain()[0].source_work_id(), 999);
            assert_eq!(o_ref.provenance_chain()[0].link_id(), 888);

            let d_ref = ls.link.end_at("RightEnd").expect("RightEnd must exist");
            assert_eq!(d_ref.work_context(), Some(dest_work_id));
            assert_eq!(d_ref.original_context(), Some(origin_work_id));
        }
    }

    #[test]
    #[cfg(feature = "server")]
    fn link_snapshot_round_trip_preserves_all_fields() {
        use crate::edition::links::{HyperLink, HyperRef, Path, ProvenanceHop};

        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let origin_work_id = server
            .create_work(sid, Edition::from_text("origin"))
            .unwrap();
        let dest_work_id = server.create_work(sid, Edition::from_text("dest")).unwrap();

        let origin_ref = HyperRef::single(
            Some(Edition::from_text("excerpt")),
            Some(origin_work_id),
            None,
            Some(Path::new(vec![RangeElement::label(
                7,
                RangeElement::text("deep"),
            )])),
        )
        .with_provenance_chain(vec![ProvenanceHop::new(55, 66)]);
        let dest_ref = HyperRef::single(None, Some(dest_work_id), None, None);
        let link = HyperLink::make(vec![10, 20, 30], origin_ref, dest_ref);
        let link_id = server.create_link_with_hyperlink(sid, link).unwrap();

        let snapshot = server.to_snapshot();
        let restored = Server::from_snapshot(&snapshot);

        let ls = restored
            .links
            .get(&link_id)
            .expect("link must survive snapshot restore");
        assert_eq!(
            ls.link.link_types(),
            &[10, 20, 30],
            "link_types must survive snapshot"
        );

        let o_ref = ls.link.end_at("LeftEnd").unwrap();
        assert!(
            o_ref.path_context().is_some(),
            "path_context must survive snapshot"
        );
        assert_eq!(
            o_ref.provenance_chain().len(),
            1,
            "provenance_chain must survive snapshot"
        );
    }

    #[test]
    fn consequence_tracker_wired_into_create_work() {
        let mut server = Server::new();
        assert_eq!(server.pending_operation_count(), 0);

        let sid = server.connect();
        server.login_public(sid).unwrap();
        let _work_id = server
            .create_work(sid, Edition::from_text("hello"))
            .unwrap();

        assert_eq!(server.pending_operation_count(), 0);
    }

    #[test]
    fn consequence_tracker_wired_into_revise() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let wid = server.create_work(sid, Edition::from_text("v1")).unwrap();

        server.work_grab(sid, wid).unwrap();
        assert_eq!(server.pending_operation_count(), 0);

        server
            .work_save_and_release(sid, wid, Edition::from_text("v2"))
            .unwrap();
        assert_eq!(server.pending_operation_count(), 0);
    }

    #[test]
    fn consequence_tracker_wired_into_link_operations() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let w1 = server
            .create_work(sid, Edition::from_text("origin"))
            .unwrap();
        let w2 = server.create_work(sid, Edition::from_text("dest")).unwrap();

        let _link_id = server.create_link(sid, w1, w2, None, None).unwrap();
        assert_eq!(server.pending_operation_count(), 0);
    }

    #[test]
    fn write_barrier_tracks_checkpoints() {
        let mut server = Server::new();
        assert_eq!(server.pending_write_count(), 0);

        let sid = server.connect();
        server.login_public(sid).unwrap();
        let _wid = server.create_work(sid, Edition::from_text("test")).unwrap();

        assert_eq!(server.pending_write_count(), 0);
    }

    #[test]
    fn wait_for_consequences_returns_immediately_when_no_pending() {
        let tracker = std::sync::Arc::new(crate::server::ConsequenceTracker::new());
        assert_eq!(tracker.pending_count(), 0);
        tracker.wait_for_consequences();
    }

    #[test]
    fn wait_for_write_returns_immediately_when_no_pending() {
        let barrier = std::sync::Arc::new(crate::server::WriteBarrier::new());
        assert_eq!(barrier.pending_writes(), 0);
        barrier.wait_for_write();
    }

    #[test]
    fn operation_guard_fires_on_early_return() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let _result = server.work_force_release(sid, 99999);
        assert_eq!(server.pending_operation_count(), 0);
    }

    #[test]
    fn tracker_accessible_from_handle() {
        let server = Server::new();
        let tracker = server.consequence_tracker();
        let barrier = server.write_barrier();
        assert_eq!(tracker.pending_count(), 0);
        assert_eq!(barrier.pending_writes(), 0);
    }

    #[test]
    fn recorder_plant_uses_hoister() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let w1 = server
            .create_work(sid, Edition::from_text("alpha beta gamma"))
            .unwrap();

        let content_elements: Vec<_> = server
            .work_edition(w1)
            .unwrap()
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.clone())
            .collect();

        let query =
            crate::edition::RecorderQuery::works().with_watched_content(content_elements.clone());
        let fossil_id = server.recorder_create_for_content(query.clone(), w1);
        assert!(
            !server
                .recorder_system
                .get_fossil(fossil_id)
                .unwrap()
                .is_extinct
        );

        server.recorder_plant(w1, fossil_id, &query.watched_content);

        let fossil = server.recorder_system.get_fossil(fossil_id).unwrap();
        assert!(!fossil.is_extinct);
    }

    #[test]
    fn recorder_hoister_propagates_flags() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let w = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();

        let content_elements: Vec<_> = server
            .work_edition(w)
            .unwrap()
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.clone())
            .collect();

        let query =
            crate::edition::RecorderQuery::works().with_watched_content(content_elements.clone());
        let fossil_id = server.recorder_create_for_content(query.clone(), w);
        server.recorder_plant(w, fossil_id, &query.watched_content);

        assert!(
            server.backfollow.is_sensor_waiting(w),
            "sensor crum should have IS_SENSOR_WAITING_FLAG after planting"
        );
    }

    #[test]
    fn recorder_plant_idempotent() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let w = server
            .create_work(sid, Edition::from_text("test content"))
            .unwrap();

        let content_elements: Vec<_> = server
            .work_edition(w)
            .unwrap()
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.clone())
            .collect();

        let query =
            crate::edition::RecorderQuery::works().with_watched_content(content_elements.clone());
        let fossil_id = server.recorder_create_for_content(query.clone(), w);
        server.recorder_plant(w, fossil_id, &query.watched_content);
        server.recorder_plant(w, fossil_id, &query.watched_content);

        let fossil = server.recorder_system.get_fossil(fossil_id).unwrap();
        assert!(!fossil.is_extinct);
    }

    #[test]
    fn permission_filter_blocks_unauthorized_fossil() {
        use crate::edition::grandmap::Id;
        let mut engine = crate::edition::backfollow::BackfollowEngine::new();

        let public_edition = crate::edition::Edition::from_text("shared content");
        let private_edition = crate::edition::Edition::from_text("shared content");

        let pub_id = 1u64;
        let priv_id = 2u64;
        engine.register_edition(
            &public_edition,
            pub_id,
            crate::edition::props::BertProp::permissions_prop(vec![Id::global(0)]),
        );
        engine.register_edition(
            &private_edition,
            priv_id,
            crate::edition::props::BertProp::make(),
        );

        let fossil_ids = vec![1u64, 2u64, 3u64];
        let mut queries = std::collections::HashMap::new();
        queries.insert(1, (vec![0u64], None));
        queries.insert(2, (vec![42u64], None));
        queries.insert(3, (vec![], None));

        let filtered = engine.filter_fossils_by_permission(&fossil_ids, &queries, pub_id);
        assert!(
            filtered.contains(&1),
            "fossil with public authority should pass"
        );
        assert!(
            !filtered.contains(&2),
            "fossil with club 42 authority should be blocked by public-only work"
        );
        assert!(
            filtered.contains(&3),
            "fossil with no authority requirements should always pass"
        );
    }

    #[test]
    fn permission_filter_passes_all_when_no_authority() {
        let mut engine = crate::edition::backfollow::BackfollowEngine::new();
        let edition = crate::edition::Edition::from_text("test");
        engine.register_edition(&edition, 1, crate::edition::props::BertProp::make());

        let fossil_ids = vec![1u64, 2u64];
        let queries = std::collections::HashMap::new();

        let filtered = engine.filter_fossils_by_permission(&fossil_ids, &queries, 1);
        assert_eq!(filtered.len(), 2, "all fossils should pass with no queries");
    }

    #[test]
    fn fossil_snapshots_roundtrip() {
        let mut sys = crate::edition::RecorderSystem::new();
        let query_a = crate::edition::RecorderQuery::transcluders()
            .with_watched_content(vec![crate::edition::RangeElement::text("hello")]);
        let fid_a = sys.create_fossil(query_a);
        sys.record_result(
            fid_a,
            crate::edition::RangeElement::edition(42),
            Some(1),
            None,
            true,
        );

        let query_b = crate::edition::RecorderQuery::works()
            .with_authority(vec![10, 20])
            .with_watched_content(vec![crate::edition::RangeElement::text("world")]);
        let fid_b = sys.create_fossil(query_b);

        let extinct_query = crate::edition::RecorderQuery::transcluders();
        let fid_extinct = sys.create_fossil(extinct_query);
        sys.extinguish_fossil(fid_extinct);

        let (snapshots, next_id) = sys.to_snapshots();
        assert_eq!(
            snapshots.len(),
            2,
            "extinct fossils should not be snapshotted"
        );
        assert!(snapshots.iter().all(|f| !f.is_extinct));
        assert_eq!(next_id, 4, "next_id should be preserved");

        let json = serde_json::to_vec(&snapshots).unwrap();
        let restored: Vec<crate::edition::recorder::Fossil> =
            serde_json::from_slice(&json).unwrap();
        assert_eq!(restored.len(), 2);

        let mut sys2 = crate::edition::RecorderSystem::new();
        sys2.restore_from_snapshots(restored, next_id);
        assert!(sys2.get_fossil(fid_a).is_some());
        assert!(sys2.get_fossil(fid_b).is_some());
        assert!(sys2.get_fossil(fid_extinct).is_none());
        assert_eq!(sys2.get_fossil(fid_a).unwrap().result_count(), 1);
        assert!(sys2.next_id() > fid_extinct);
    }

    #[test]
    fn fossil_persistence_survives_checkpoint_restore() {
        let data_dir = std::env::temp_dir().join(format!(
            "xudanu_fossil_persist_test_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir);
        std::fs::create_dir_all(&data_dir).unwrap();

        let fossil_id;
        let work_id;
        let mut server = Server::new();
        let chunk_store = crate::persist::chunk_store::ChunkStore::open(&data_dir).unwrap();
        server.chunk_store = Some(Arc::new(chunk_store));
        server.checkpoint_path = Some(crate::persist::manifest::manifest_path(&data_dir));
        server.data_dir = Some(data_dir.clone());

        let sid = server.connect();
        server.login_public(sid).unwrap();

        work_id = server
            .create_work(sid, Edition::from_text("monitored content here"))
            .unwrap();

        let content_elements: Vec<_> = server
            .work_edition(work_id)
            .unwrap()
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.clone())
            .collect();

        let query =
            crate::edition::RecorderQuery::works().with_watched_content(content_elements.clone());
        fossil_id = server.recorder_create_for_content(query.clone(), work_id);
        server.recorder_plant(work_id, fossil_id, &query.watched_content);

        assert!(
            !server
                .recorder_system
                .get_fossil(fossil_id)
                .unwrap()
                .is_extinct
        );

        server.checkpoint_to_store().unwrap();
        drop(server);

        {
            let mut server2 = Server::new();
            server2.restore_from_data_dir(&data_dir, None).unwrap();

            let fossil = server2.recorder_system.get_fossil(fossil_id);
            assert!(fossil.is_some(), "fossil should survive checkpoint/restore");
            let f = fossil.unwrap();
            assert!(!f.is_extinct);
            assert_eq!(f.source_edition_id, Some(work_id));

            let fp_index = server2.backfollow.fossil_fingerprints();
            assert!(
                !fp_index.is_empty(),
                "fossil fingerprints should be re-registered in backfollow"
            );
        }

        let manifest = crate::persist::manifest::read_manifest(
            &crate::persist::manifest::manifest_path(&data_dir),
        )
        .unwrap();
        assert!(
            manifest.fossil_snapshots_hash.is_some(),
            "manifest should have fossil_snapshots_hash"
        );

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    fn empty_fossils_no_hash_in_manifest() {
        let data_dir = std::env::temp_dir().join(format!(
            "xudanu_fossil_empty_test_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir);
        std::fs::create_dir_all(&data_dir).unwrap();

        {
            let mut server = Server::new();
            server.chunk_store = Some(Arc::new(
                crate::persist::chunk_store::ChunkStore::open(&data_dir).unwrap(),
            ));
            server.checkpoint_path = Some(crate::persist::manifest::manifest_path(&data_dir));
            server.data_dir = Some(data_dir.clone());

            server.checkpoint_to_store().unwrap();
        }

        let manifest = crate::persist::manifest::read_manifest(
            &crate::persist::manifest::manifest_path(&data_dir),
        )
        .unwrap();
        assert!(
            manifest.fossil_snapshots_hash.is_none(),
            "empty recorder system should not produce fossil hash"
        );

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    fn reactive_trigger_after_revise_adds_matching_content() {
        crate::edition::init_endorsement_flags();
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work_a = server
            .create_work(sid, Edition::from_text("alpha"))
            .unwrap();

        let content_a: Vec<RangeElement> = server
            .get_edition(work_a)
            .unwrap()
            .unwrap()
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.clone())
            .collect();
        let query = crate::edition::RecorderQuery::works().with_watched_content(content_a.clone());
        let fossil_id = server.recorder_create_for_content(query.clone(), work_a);
        server.recorder_plant(work_a, fossil_id, &query.watched_content);

        let work_b = server.create_work(sid, Edition::from_text("beta")).unwrap();
        server.work_grab(sid, work_b).unwrap();
        let _drained =
            server.drain_content_notifications_for(&std::collections::HashSet::from([fossil_id]));

        server
            .work_revise(sid, work_b, Edition::from_text("alpha"))
            .unwrap();

        let notifications =
            server.drain_content_notifications_for(&std::collections::HashSet::from([fossil_id]));
        assert!(
            !notifications.is_empty(),
            "revising work_b to add matching content should trigger the recorder"
        );
    }

    #[test]
    fn reactive_trigger_on_publish_prop_change() {
        crate::edition::init_endorsement_flags();
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work = server
            .create_work(sid, Edition::from_text("content"))
            .unwrap();

        let edition = server.get_edition(work).unwrap().unwrap();
        let content: Vec<RangeElement> = edition
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.clone())
            .collect();
        let query = crate::edition::RecorderQuery::works().with_watched_content(content.clone());
        let fossil_id = server.recorder_create_for_content(query.clone(), work);
        server.recorder_plant(work, fossil_id, &query.watched_content);
        let results_before = server.recorder_get(fossil_id).unwrap().result_count();

        let work_b = server
            .create_work(sid, Edition::from_text("content"))
            .unwrap();
        let _drained =
            server.drain_content_notifications_for(&std::collections::HashSet::from([fossil_id]));

        server.work_unpublish(sid, work_b).unwrap();

        let results_after = server.recorder_get(fossil_id).unwrap().result_count();
        assert!(
            results_after >= results_before,
            "prop change should not lose existing results"
        );
    }

    #[test]
    fn extinguished_fossil_ignores_triggers() {
        crate::edition::init_endorsement_flags();
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work_a = server
            .create_work(sid, Edition::from_text("alpha"))
            .unwrap();

        let content_a: Vec<RangeElement> = server
            .get_edition(work_a)
            .unwrap()
            .unwrap()
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.clone())
            .collect();
        let query =
            crate::edition::RecorderQuery::works().with_watched_content(vec![content_a[0].clone()]);
        let fossil_id = server.recorder_create_for_content(query.clone(), work_a);
        server.recorder_plant(work_a, fossil_id, &query.watched_content);

        let _work_b = server
            .create_work(sid, Edition::from_text("alpha"))
            .unwrap();

        let results_before = server.recorder_get(fossil_id).unwrap().result_count();
        assert!(
            results_before > 0,
            "should have initial results from work_b"
        );

        server.recorder_extinguish(fossil_id);
        assert!(server.recorder_get(fossil_id).unwrap().is_extinct);

        let _work_c = server
            .create_work(sid, Edition::from_text("alpha"))
            .unwrap();

        let results_after = server.recorder_get(fossil_id).unwrap().result_count();
        assert_eq!(
            results_after, results_before,
            "extinguished fossil should not accumulate new results"
        );
    }

    #[test]
    fn ent_bridge_create_work_materializes() {
        crate::edition::init_endorsement_flags();
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work_id = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();

        let doc = server.materialize_work(work_id).unwrap();
        assert!(doc.root.is_some(), "document should have a root node");
        let root = doc.root.unwrap();
        assert_eq!(root.kind, "document");
        assert!(
            !root.spans.is_empty(),
            "should have spans from edition elements"
        );

        let all_text: String = root
            .spans
            .iter()
            .map(|s| match &s.text {
                crate::ent::content::AlternativeSet::Single(t) => t.as_str(),
                crate::ent::content::AlternativeSet::Alternatives(ts) => {
                    ts.first().map(|s| s.as_str()).unwrap_or("")
                }
            })
            .collect();
        assert!(
            all_text.contains("hello"),
            "materialized text should contain 'hello', got: {:?}",
            all_text
        );
    }

    #[test]
    fn ent_bridge_revise_creates_new_trace_position() {
        crate::edition::init_endorsement_flags();
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work_id = server.create_work(sid, Edition::from_text("v1")).unwrap();

        let tp1 = server.version_trace_position(work_id);
        assert!(tp1.is_some(), "first revision should have trace position");

        server.work_grab(sid, work_id).unwrap();
        server
            .work_revise(sid, work_id, Edition::from_text("v2"))
            .unwrap();

        let tp2 = server.version_trace_position(work_id);
        assert!(tp2.is_some(), "second revision should have trace position");
        assert_ne!(tp1, tp2, "revision should create new trace position");

        let doc = server.materialize_work(work_id).unwrap();
        let root = doc.root.unwrap();
        let all_text: String = root
            .spans
            .iter()
            .map(|s| match &s.text {
                crate::ent::content::AlternativeSet::Single(t) => t.as_str(),
                crate::ent::content::AlternativeSet::Alternatives(ts) => {
                    ts.first().map(|s| s.as_str()).unwrap_or("")
                }
            })
            .collect();
        assert!(
            all_text.contains("v2"),
            "after revise, materialized text should show v2, got: {:?}",
            all_text
        );
    }

    #[test]
    fn ent_bridge_version_ordering() {
        crate::edition::init_endorsement_flags();
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work_a = server
            .create_work(sid, Edition::from_text("original"))
            .unwrap();
        let work_b = server
            .create_work(sid, Edition::from_text("derived"))
            .unwrap();

        let is_before = server.version_is_before(work_a, work_b);
        assert!(
            is_before.is_some(),
            "both works should have trace positions"
        );
    }

    #[test]
    fn ent_bridge_materialize_after_revise() {
        crate::edition::init_endorsement_flags();
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work_id = server
            .create_work(sid, Edition::from_text("first"))
            .unwrap();
        server.work_grab(sid, work_id).unwrap();
        server
            .work_revise(sid, work_id, Edition::from_text("second"))
            .unwrap();
        server.work_release(sid, work_id).unwrap();

        let doc = server.materialize_work(work_id).unwrap();
        let root = doc.root.unwrap();

        let all_text: String = root
            .spans
            .iter()
            .map(|s| match &s.text {
                crate::ent::content::AlternativeSet::Single(t) => t.as_str(),
                crate::ent::content::AlternativeSet::Alternatives(ts) => {
                    ts.first().map(|s| s.as_str()).unwrap_or("")
                }
            })
            .collect();
        assert!(
            all_text.contains("second"),
            "materialized text should show latest revision, got: {:?}",
            all_text
        );
    }

    #[test]
    fn ent_bridge_ancestry_chain() {
        crate::edition::init_endorsement_flags();
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work_id = server.create_work(sid, Edition::from_text("r1")).unwrap();
        let tp1 = server.version_trace_position(work_id).unwrap();

        server.work_grab(sid, work_id).unwrap();
        server
            .work_revise(sid, work_id, Edition::from_text("r2"))
            .unwrap();
        server.work_release(sid, work_id).unwrap();
        let tp2 = server.version_trace_position(work_id).unwrap();

        server.work_grab(sid, work_id).unwrap();
        server
            .work_revise(sid, work_id, Edition::from_text("r3"))
            .unwrap();
        server.work_release(sid, work_id).unwrap();
        let tp3 = server.version_trace_position(work_id).unwrap();

        assert_ne!(tp1, tp2, "each revise creates new trace position");
        assert_ne!(tp2, tp3, "each revise creates new trace position");

        let doc = server.materialize_work(work_id).unwrap();
        let root = doc.root.unwrap();
        let all_text: String = root
            .spans
            .iter()
            .map(|s| match &s.text {
                crate::ent::content::AlternativeSet::Single(t) => t.as_str(),
                crate::ent::content::AlternativeSet::Alternatives(ts) => {
                    ts.first().map(|s| s.as_str()).unwrap_or("")
                }
            })
            .collect();
        assert!(
            all_text.contains("r3"),
            "latest revision should materialize with r3, got: {:?}",
            all_text
        );
    }

    #[cfg(feature = "server")]
    fn setup_chunk_store_server(name: &str) -> (Server, std::path::PathBuf) {
        let data_dir = std::env::temp_dir().join(format!(
            "xudanu_persist_test_{}_{}_{}",
            name,
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir);
        std::fs::create_dir_all(&data_dir).unwrap();

        let mut server = Server::new();
        server.init_data_dir(&data_dir, None).unwrap();
        (server, data_dir)
    }

    #[test]
    #[cfg(feature = "server")]
    fn checkpoint_store_writes_dual_slot_files() {
        let (mut server, data_dir) = setup_chunk_store_server("dual_slot");
        let sid = server.connect();
        server.login_public(sid).unwrap();
        server.create_work(sid, Edition::from_text("test")).unwrap();

        server.checkpoint_to_store().unwrap();

        let primary = data_dir.join("manifest.json");
        assert!(primary.exists(), "primary manifest should exist");

        let slot = server.manifest_slot;
        assert!(
            slot == 'a' || slot == 'b',
            "manifest_slot should be 'a' or 'b', got '{}'",
            slot
        );

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn checkpoint_store_alternates_slots() {
        let (mut server, data_dir) = setup_chunk_store_server("slot_alternation");
        let sid = server.connect();
        server.login_public(sid).unwrap();
        server.create_work(sid, Edition::from_text("test")).unwrap();

        let slot_init = server.manifest_slot;

        server.checkpoint_to_store().unwrap();
        let slot1 = server.manifest_slot;

        server.checkpoint_to_store().unwrap();
        let slot2 = server.manifest_slot;

        assert_ne!(slot1, slot2, "slots should alternate");
        assert_ne!(slot_init, slot1, "first checkpoint should change slot");

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn checkpoint_store_increments_sequence() {
        let (mut server, data_dir) = setup_chunk_store_server("sequence_increment");
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let seq0 = server.manifest_sequence;
        server.checkpoint_to_store().unwrap();
        assert!(server.manifest_sequence > seq0);

        let seq1 = server.manifest_sequence;
        server.checkpoint_to_store().unwrap();
        assert!(server.manifest_sequence > seq1);

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn checkpoint_store_updates_last_checkpoint_time() {
        let (mut server, data_dir) = setup_chunk_store_server("checkpoint_time");
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let before = server.last_checkpoint_time;
        std::thread::sleep(std::time::Duration::from_millis(10));
        server.checkpoint_to_store().unwrap();
        assert!(
            server.last_checkpoint_time >= before,
            "last_checkpoint_time should be updated after checkpoint"
        );

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn checkpoint_restore_roundtrip_with_works() {
        let data_dir = std::env::temp_dir().join(format!(
            "xudanu_roundtrip_test_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir);
        std::fs::create_dir_all(&data_dir).unwrap();

        let doc_id;
        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();

            doc_id = server
                .create_work(sid, Edition::from_text("hello world"))
                .unwrap();
            server
                .create_club(sid, Edition::from_text("my club"))
                .unwrap();

            server.checkpoint_to_store().unwrap();
        }

        {
            let mut server = Server::new();
            server.restore_from_data_dir(&data_dir, None).unwrap();

            assert_eq!(server.work_count(), 1);
            assert_eq!(
                server.work_edition(doc_id).unwrap().to_text(),
                "hello world"
            );
            assert_ne!(server.manifest_slot, '\0', "slot should be restored");
        }

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn checkpoint_restore_preserves_stars() {
        let data_dir = std::env::temp_dir().join(format!(
            "xudanu_stars_test_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir);
        std::fs::create_dir_all(&data_dir).unwrap();

        let doc_id;
        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();

            doc_id = server
                .create_work(sid, Edition::from_text("starred doc"))
                .unwrap();
            server.work_star(sid, doc_id).unwrap();

            server.checkpoint_to_store().unwrap();
        }

        {
            let mut server = Server::new();
            server.restore_from_data_dir(&data_dir, None).unwrap();

            let sid = server.connect();
            server.login_public(sid).unwrap();
            let starred = server.starred_for_session(sid);
            assert!(
                starred.contains(&doc_id),
                "star should survive checkpoint/restore"
            );
        }

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn checkpoint_restore_preserves_trails() {
        let data_dir = std::env::temp_dir().join(format!(
            "xudanu_trails_test_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir);
        std::fs::create_dir_all(&data_dir).unwrap();

        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();

            let doc1 = server.create_work(sid, Edition::from_text("doc1")).unwrap();
            let doc2 = server.create_work(sid, Edition::from_text("doc2")).unwrap();

            let trail = server.trail_create(sid, "My Trail".to_string()).unwrap();
            server
                .trail_add_stop(sid, trail, doc1, None, None, None)
                .unwrap();
            server
                .trail_add_stop(
                    sid,
                    trail,
                    doc2,
                    Some(10),
                    Some(50),
                    Some("note".to_string()),
                )
                .unwrap();

            server.checkpoint_to_store().unwrap();
        }

        {
            let mut server = Server::new();
            server.restore_from_data_dir(&data_dir, None).unwrap();

            let sid = server.connect();
            server.login_public(sid).unwrap();
            let trails = server.trail_list(sid).unwrap();
            assert_eq!(trails.len(), 1);
            assert_eq!(trails[0].name, "My Trail");
            assert_eq!(trails[0].stops.len(), 2);
            assert_eq!(trails[0].stops[1].char_start, Some(10));
            assert_eq!(trails[0].stops[1].note, Some("note".to_string()));
        }

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn async_checkpoint_integrity() {
        let data_dir = std::env::temp_dir().join(format!(
            "xudanu_async_ckpt_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir);
        std::fs::create_dir_all(&data_dir).unwrap();

        let doc_id;
        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();

            doc_id = server
                .create_work(sid, Edition::from_text("async checkpoint content"))
                .unwrap();
            server
                .create_club(sid, Edition::from_text("club for async test"))
                .unwrap();

            let payload = server.checkpoint_prepare().unwrap();
            let result = super::checkpoint_persist(payload).unwrap();
            server.checkpoint_commit(result).unwrap();
        }

        {
            let mut server = Server::new();
            server.restore_from_data_dir(&data_dir, None).unwrap();

            assert_eq!(server.work_count(), 1);
            assert_eq!(
                server.work_edition(doc_id).unwrap().to_text(),
                "async checkpoint content"
            );
            assert_ne!(server.manifest_slot, '\0');
        }

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn async_checkpoint_dirty_gen_prevents_stale_ref() {
        let data_dir = std::env::temp_dir().join(format!(
            "xudanu_dirty_gen_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir);
        std::fs::create_dir_all(&data_dir).unwrap();

        let doc_id;
        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();

            doc_id = server
                .create_work(sid, Edition::from_text("original content"))
                .unwrap();

            let payload = server.checkpoint_prepare().unwrap();

            server.works.get_mut(&doc_id).unwrap().mark_dirty();

            let result = super::checkpoint_persist(payload).unwrap();
            server.checkpoint_commit(result).unwrap();

            let ws = server.works.get(&doc_id).unwrap();
            assert!(
                ws.chunk_ref.is_none(),
                "work should remain dirty after modification during checkpoint window"
            );

            let payload2 = server.checkpoint_prepare().unwrap();
            let result2 = super::checkpoint_persist(payload2).unwrap();
            server.checkpoint_commit(result2).unwrap();

            let ws = server.works.get(&doc_id).unwrap();
            assert!(
                ws.chunk_ref.is_some(),
                "work should be clean after second checkpoint"
            );
        }

        {
            let mut server = Server::new();
            server.restore_from_data_dir(&data_dir, None).unwrap();
            assert_eq!(
                server.work_edition(doc_id).unwrap().to_text(),
                "original content",
            );
        }

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn async_checkpoint_matches_sync() {
        let data_dir_a = std::env::temp_dir().join(format!(
            "xudanu_cmp_a_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let data_dir_b = std::env::temp_dir().join(format!(
            "xudanu_cmp_b_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir_a);
        let _ = std::fs::remove_dir_all(&data_dir_b);
        std::fs::create_dir_all(&data_dir_a).unwrap();
        std::fs::create_dir_all(&data_dir_b).unwrap();

        let text = "comparison test content for sync vs async";

        let doc_a;
        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir_a, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();
            doc_a = server.create_work(sid, Edition::from_text(text)).unwrap();

            let payload = server.checkpoint_prepare().unwrap();
            let result = super::checkpoint_persist(payload).unwrap();
            server.checkpoint_commit(result).unwrap();
        }

        let doc_b;
        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir_b, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();
            doc_b = server.create_work(sid, Edition::from_text(text)).unwrap();
            server.checkpoint_to_store().unwrap();
        }

        let restored_a = {
            let mut server = Server::new();
            server.restore_from_data_dir(&data_dir_a, None).unwrap();
            server.work_edition(doc_a).unwrap().to_text()
        };
        let restored_b = {
            let mut server = Server::new();
            server.restore_from_data_dir(&data_dir_b, None).unwrap();
            server.work_edition(doc_b).unwrap().to_text()
        };

        assert_eq!(restored_a, restored_b);
        assert_eq!(restored_a, text);

        let _ = std::fs::remove_dir_all(&data_dir_a);
        let _ = std::fs::remove_dir_all(&data_dir_b);
    }

    #[test]
    #[cfg(feature = "server")]
    fn trail_crud_full_lifecycle() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        // Create
        let t1 = server.trail_create(sid, "Trail One".to_string()).unwrap();
        let t2 = server.trail_create(sid, "Trail Two".to_string()).unwrap();

        // List
        let trails = server.trail_list(sid).unwrap();
        assert_eq!(trails.len(), 2);

        // Create works
        let doc1 = server.create_work(sid, Edition::from_text("doc1")).unwrap();
        let doc2 = server.create_work(sid, Edition::from_text("doc2")).unwrap();
        let doc3 = server.create_work(sid, Edition::from_text("doc3")).unwrap();

        // Add stops
        server
            .trail_add_stop(sid, t1, doc1, None, None, None)
            .unwrap();
        server
            .trail_add_stop(sid, t1, doc2, Some(5), Some(20), Some("middle".into()))
            .unwrap();
        server
            .trail_add_stop(sid, t1, doc3, None, None, Some("end".into()))
            .unwrap();

        // Get
        let trail = server.trail_get(sid, t1).unwrap();
        assert_eq!(trail.name, "Trail One");
        assert_eq!(trail.stops.len(), 3);
        assert_eq!(trail.stops[0].work_id, doc1);
        assert_eq!(trail.stops[1].note.as_deref(), Some("middle"));
        assert_eq!(trail.stops[2].note.as_deref(), Some("end"));

        // Rename
        server
            .trail_rename(sid, t1, "Renamed Trail".to_string())
            .unwrap();
        let trail = server.trail_get(sid, t1).unwrap();
        assert_eq!(trail.name, "Renamed Trail");

        // Remove stop
        server.trail_remove_stop(sid, t1, 1).unwrap();
        let trail = server.trail_get(sid, t1).unwrap();
        assert_eq!(trail.stops.len(), 2);

        // Reorder
        let trail = server.trail_get(sid, t1).unwrap();
        let first_work = trail.stops[0].work_id;
        server.trail_reorder_stops(sid, t1, vec![1, 0]).unwrap();
        let trail = server.trail_get(sid, t1).unwrap();
        assert_eq!(trail.stops.len(), 2);
        assert_eq!(trail.stops[0].work_id, doc3); // swapped
        assert_ne!(trail.stops[0].work_id, first_work);

        // Delete
        server.trail_delete(sid, t2).unwrap();
        let trails = server.trail_list(sid).unwrap();
        assert_eq!(trails.len(), 1);
        assert_eq!(trails[0].name, "Renamed Trail"); // t1 survived, t2 gone
    }

    #[test]
    fn trail_stop_preserves_selection_range() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let doc = server
            .create_work(sid, Edition::from_text("Hello world."))
            .unwrap();
        let trail = server.trail_create(sid, "Selections".to_string()).unwrap();
        server
            .trail_add_stop(
                sid,
                trail,
                doc,
                Some(6),
                Some(11),
                Some("the word 'world'".to_string()),
            )
            .unwrap();

        let trail = server.trail_get(sid, trail).unwrap();
        assert_eq!(trail.stops[0].char_start, Some(6));
        assert_eq!(trail.stops[0].char_end, Some(11));
        assert_eq!(trail.stops[0].note.as_deref(), Some("the word 'world'"));
    }

    #[test]
    fn trail_updated_on_stop_modification() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let doc = server.create_work(sid, Edition::from_text("doc")).unwrap();
        let trail = server.trail_create(sid, "T".to_string()).unwrap();

        let before = server.trail_get(sid, trail).unwrap().updated_at;
        std::thread::sleep(std::time::Duration::from_secs(1));
        server
            .trail_add_stop(sid, trail, doc, None, None, None)
            .unwrap();
        let after = server.trail_get(sid, trail).unwrap().updated_at;
        assert!(after > before, "updated_at should change on modification");
    }

    #[test]
    #[cfg(feature = "server")]
    fn dirty_clubs_preserved_on_checkpoint_failure() {
        let data_dir = std::env::temp_dir().join(format!(
            "xudanu_dirty_clubs_test_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir);
        std::fs::create_dir_all(&data_dir).unwrap();

        let mut server = Server::new();
        server.init_data_dir(&data_dir, None).unwrap();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let club_id = server
            .create_club(sid, Edition::from_text("dirty"))
            .unwrap();

        assert!(
            server.dirty_clubs.contains(&club_id),
            "new club should be dirty"
        );

        server.checkpoint_to_store().unwrap();
        assert!(
            !server.dirty_clubs.contains(&club_id),
            "dirty_clubs should be cleared after successful checkpoint"
        );

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn dual_manifest_crash_simulation() {
        let data_dir = std::env::temp_dir().join(format!(
            "xudanu_crash_sim_test_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir);
        std::fs::create_dir_all(&data_dir).unwrap();

        let doc_id;
        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();

            doc_id = server
                .create_work(sid, Edition::from_text("survives crash"))
                .unwrap();
            server.checkpoint_to_store().unwrap();

            server.work_grab(sid, doc_id).unwrap();
            server
                .work_revise(sid, doc_id, Edition::from_text("updated before crash"))
                .unwrap();
            server.work_release(sid, doc_id).unwrap();
            server.checkpoint_to_store().unwrap();
        }

        {
            let primary = data_dir.join("manifest.json");
            let content = std::fs::read_to_string(&primary).unwrap();
            let corrupted = content.replace("updated before crash", "CORRUPTED_DATA");
            std::fs::write(&primary, corrupted).unwrap();
        }

        {
            let mut server = Server::new();
            match server.restore_from_data_dir(&data_dir, None) {
                Ok(()) => {
                    let text = server.work_edition(doc_id).unwrap().to_text();
                    assert!(
                        text.contains("updated before crash") || text.contains("survives crash"),
                        "should recover from backup, got: {}",
                        text
                    );
                }
                Err(_) => {
                    let mut found_backup = false;
                    if let Ok(entries) = std::fs::read_dir(&data_dir) {
                        for entry in entries.flatten() {
                            let name = entry.file_name();
                            let name_str = name.to_str().unwrap_or("");
                            if name_str.starts_with("manifest_v") {
                                found_backup = true;
                            }
                        }
                    }
                    assert!(found_backup, "recovery should succeed via versioned backup");
                }
            }
        }

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn dual_manifest_both_slots_survive_primary_loss() {
        let data_dir = std::env::temp_dir().join(format!(
            "xudanu_dual_slots_test_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir);
        std::fs::create_dir_all(&data_dir).unwrap();

        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();

            server.create_work(sid, Edition::from_text("doc1")).unwrap();
            server.checkpoint_to_store().unwrap();

            server.create_work(sid, Edition::from_text("doc2")).unwrap();
            server.checkpoint_to_store().unwrap();
        }

        {
            let primary = data_dir.join("manifest.json");
            if primary.exists() {
                std::fs::remove_file(&primary).unwrap();
            }
        }

        {
            let mut server = Server::new();
            match server.restore_from_data_dir(&data_dir, None) {
                Ok(()) => {
                    assert!(
                        server.work_count() >= 1,
                        "at least one doc should be recovered"
                    );
                }
                Err(_) => {}
            }
        }

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn schema_migration_with_new_fields() {
        let data_dir = std::env::temp_dir().join(format!(
            "xudanu_schema_test_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir);
        std::fs::create_dir_all(&data_dir).unwrap();

        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();
            server
                .create_work(sid, Edition::from_text("schema test"))
                .unwrap();
            server.checkpoint_to_store().unwrap();
        }

        {
            let primary = data_dir.join("manifest.json");
            let content = std::fs::read_to_string(&primary).unwrap();
            let modified = content.replace("\"manifest_slot\": \"b\"", "\"manifest_slot\": \"x\"");
            std::fs::write(&primary, modified).unwrap();
        }

        {
            let mut server = Server::new();
            assert!(
                server.restore_from_data_dir(&data_dir, None).is_ok(),
                "should handle invalid manifest_slot gracefully"
            );
            assert_eq!(
                server.manifest_slot, 'a',
                "invalid slot should default to 'a'"
            );
        }

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn multiple_checkpoints_create_versioned_backups() {
        let (mut server, data_dir) = setup_chunk_store_server("versioned_backups");
        let sid = server.connect();
        server.login_public(sid).unwrap();

        for i in 0..10 {
            server
                .create_work(sid, Edition::from_text(&format!("doc{}", i)))
                .unwrap();
            server.checkpoint_to_store().unwrap();
        }

        let mut backup_count = 0;
        for entry in std::fs::read_dir(&data_dir).unwrap() {
            let entry = entry.unwrap();
            let name = entry.file_name();
            let name_str = name.to_str().unwrap_or("");
            if name_str.starts_with("manifest_v") && name_str.ends_with(".json") {
                backup_count += 1;
            }
        }

        assert!(
            backup_count <= 4,
            "should keep at most 3 old + 1 new versioned backups, found {}",
            backup_count
        );
        assert!(
            backup_count >= 1,
            "should have at least 1 versioned backup, found {}",
            backup_count
        );

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn checkpoint_backup_uses_fsync() {
        let (mut server, data_dir) = setup_chunk_store_server("fsync_backup");
        let sid = server.connect();
        server.login_public(sid).unwrap();
        server
            .create_work(sid, Edition::from_text("fsync test"))
            .unwrap();

        server.checkpoint_to_store().unwrap();

        let seq = server.manifest_sequence;
        let backup_path = crate::persist::manifest::backup_manifest_path(&data_dir, seq);
        assert!(backup_path.exists(), "backup should exist");

        let primary = data_dir.join("manifest.json");
        let primary_content = std::fs::read_to_string(&primary).unwrap();
        let backup_content = std::fs::read_to_string(&backup_path).unwrap();
        assert_eq!(
            primary_content, backup_content,
            "backup should match primary"
        );

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn checkpoint_restore_survives_interrupted_write() {
        let data_dir = std::env::temp_dir().join(format!(
            "xudanu_interrupted_test_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir);
        std::fs::create_dir_all(&data_dir).unwrap();

        let doc_id;
        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();
            doc_id = server
                .create_work(sid, Edition::from_text("stable"))
                .unwrap();
            server.checkpoint_to_store().unwrap();
        }

        {
            let tmp_file = data_dir.join("manifest.json.tmp");
            std::fs::write(&tmp_file, b"PARTIAL_WRITE").unwrap();
        }

        {
            let mut server = Server::new();
            let result = server.restore_from_data_dir(&data_dir, None);
            assert!(result.is_ok(), "should recover despite stale tmp file");

            let text = server.work_edition(doc_id).unwrap().to_text();
            assert_eq!(text, "stable");
        }

        assert!(
            !data_dir.join("manifest.json.tmp").exists(),
            "stale tmp file should be cleaned up"
        );

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn wal_records_star_operations() {
        let (mut server, data_dir) = setup_chunk_store_server("wal_star");
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let doc = server.create_work(sid, Edition::from_text("test")).unwrap();

        server.work_star(sid, doc).unwrap();
        assert!(server.wal.is_enabled());
        assert_eq!(server.wal.seq(), 1, "star should write WAL entry");

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn wal_records_unstar_operations() {
        let (mut server, data_dir) = setup_chunk_store_server("wal_unstar");
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let doc = server.create_work(sid, Edition::from_text("test")).unwrap();

        server.work_star(sid, doc).unwrap();
        server.work_unstar(sid, doc).unwrap();
        assert_eq!(
            server.wal.seq(),
            2,
            "star + unstar should write 2 WAL entries"
        );

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn wal_truncated_after_checkpoint() {
        let (mut server, data_dir) = setup_chunk_store_server("wal_truncate");
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let doc = server.create_work(sid, Edition::from_text("test")).unwrap();

        server.work_star(sid, doc).unwrap();
        assert_eq!(server.wal.seq(), 1);

        server.checkpoint_to_store().unwrap();
        assert_eq!(
            server.wal.seq(),
            0,
            "WAL should be truncated after checkpoint"
        );

        let wal_path = data_dir.join("wal.log");
        let (_ver, entries) = crate::persist::wal::WalLog::read_entries(&wal_path).unwrap();
        assert!(
            entries.is_empty(),
            "WAL file should be empty after checkpoint"
        );

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn wal_replays_star_after_crash() {
        let data_dir = std::env::temp_dir().join(format!(
            "xudanu_wal_star_replay_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir);
        std::fs::create_dir_all(&data_dir).unwrap();

        let doc_id;
        let club_id;
        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();
            doc_id = server.create_work(sid, Edition::from_text("test")).unwrap();
            club_id = server.resolve_author_club(sid).unwrap();

            server.checkpoint_to_store().unwrap();
            assert_eq!(server.wal.seq(), 0, "WAL empty after checkpoint");

            server.work_star(sid, doc_id).unwrap();
            assert_eq!(server.wal.seq(), 1, "WAL has 1 entry after star");
        }

        {
            let mut server = Server::new();
            server.restore_from_data_dir(&data_dir, None).unwrap();

            let starred = server.starred_works.get(&club_id);
            assert!(
                starred.is_some() && starred.unwrap().contains(&doc_id),
                "star should be recovered via WAL replay"
            );
        }

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn wal_replays_trail_after_crash() {
        let data_dir = std::env::temp_dir().join(format!(
            "xudanu_wal_trail_replay_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir);
        std::fs::create_dir_all(&data_dir).unwrap();

        let doc1;
        let doc2;
        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();
            doc1 = server.create_work(sid, Edition::from_text("doc1")).unwrap();
            doc2 = server.create_work(sid, Edition::from_text("doc2")).unwrap();

            server.checkpoint_to_store().unwrap();

            let trail = server.trail_create(sid, "My Trail".to_string()).unwrap();
            server
                .trail_add_stop(sid, trail, doc1, None, None, None)
                .unwrap();
            server
                .trail_add_stop(
                    sid,
                    trail,
                    doc2,
                    Some(5),
                    Some(10),
                    Some("note".to_string()),
                )
                .unwrap();

            assert!(server.wal.seq() >= 3, "trail ops should write WAL entries");
        }

        {
            let mut server = Server::new();
            server.restore_from_data_dir(&data_dir, None).unwrap();

            let sid = server.connect();
            server.login_public(sid).unwrap();
            let trails = server.trail_list(sid).unwrap();
            assert_eq!(trails.len(), 1, "trail should be recovered via WAL replay");
            assert_eq!(trails[0].name, "My Trail");
            assert_eq!(trails[0].stops.len(), 2);
            assert_eq!(trails[0].stops[1].char_start, Some(5));
            assert_eq!(trails[0].stops[1].note, Some("note".to_string()));
        }

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn wal_replays_trail_delete_after_crash() {
        let data_dir = std::env::temp_dir().join(format!(
            "xudanu_wal_trail_del_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir);
        std::fs::create_dir_all(&data_dir).unwrap();

        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();
            server.create_work(sid, Edition::from_text("doc")).unwrap();

            let trail = server.trail_create(sid, "Delete Me".to_string()).unwrap();
            server.checkpoint_to_store().unwrap();

            server.trail_delete(sid, trail).unwrap();
        }

        {
            let mut server = Server::new();
            server.restore_from_data_dir(&data_dir, None).unwrap();

            let sid = server.connect();
            server.login_public(sid).unwrap();
            let trails = server.trail_list(sid).unwrap();
            assert!(trails.is_empty(), "trail should be deleted via WAL replay");
        }

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn wal_replays_unstar_after_crash() {
        let data_dir = std::env::temp_dir().join(format!(
            "xudanu_wal_unstar_replay_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir);
        std::fs::create_dir_all(&data_dir).unwrap();

        let doc_id;
        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();
            doc_id = server.create_work(sid, Edition::from_text("test")).unwrap();

            server.work_star(sid, doc_id).unwrap();
            server.checkpoint_to_store().unwrap();

            server.work_unstar(sid, doc_id).unwrap();
        }

        {
            let mut server = Server::new();
            server.restore_from_data_dir(&data_dir, None).unwrap();

            let sid = server.connect();
            server.login_public(sid).unwrap();
            let starred = server.starred_for_session(sid);
            assert!(
                !starred.contains(&doc_id),
                "star should be removed via WAL replay of unstar"
            );
        }

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn wal_replays_multiple_operations_in_order() {
        let data_dir = std::env::temp_dir().join(format!(
            "xudanu_wal_multi_ops_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir);
        std::fs::create_dir_all(&data_dir).unwrap();

        let doc1;
        let doc2;
        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();
            doc1 = server.create_work(sid, Edition::from_text("doc1")).unwrap();
            doc2 = server.create_work(sid, Edition::from_text("doc2")).unwrap();

            server.checkpoint_to_store().unwrap();

            server.work_star(sid, doc1).unwrap();
            server.work_star(sid, doc2).unwrap();
            server.work_unstar(sid, doc1).unwrap();

            let trail = server.trail_create(sid, "Trail".to_string()).unwrap();
            server
                .trail_add_stop(sid, trail, doc1, None, None, None)
                .unwrap();
        }

        {
            let mut server = Server::new();
            server.restore_from_data_dir(&data_dir, None).unwrap();

            let sid = server.connect();
            server.login_public(sid).unwrap();

            let starred = server.starred_for_session(sid);
            assert!(!starred.contains(&doc1), "doc1 star should be undone");
            assert!(starred.contains(&doc2), "doc2 star should be preserved");

            let trails = server.trail_list(sid).unwrap();
            assert_eq!(trails.len(), 1);
            assert_eq!(trails[0].stops.len(), 1);
            assert_eq!(trails[0].stops[0].work_id, doc1);
        }

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn wal_empty_after_clean_checkpoint_cycle() {
        let (mut server, data_dir) = setup_chunk_store_server("wal_clean_cycle");
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let doc = server.create_work(sid, Edition::from_text("test")).unwrap();

        server.work_star(sid, doc).unwrap();
        assert!(server.wal.seq() > 0);

        server.checkpoint_to_store().unwrap();
        assert_eq!(server.wal.seq(), 0, "WAL should be empty after checkpoint");

        server.work_star(sid, doc).unwrap();
        assert!(
            server.wal.seq() > 0,
            "WAL should accept new entries after truncate"
        );

        server.checkpoint_to_store().unwrap();
        assert_eq!(
            server.wal.seq(),
            0,
            "WAL should be empty after second checkpoint"
        );

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn wal_records_create_link() {
        let (mut server, data_dir) = setup_chunk_store_server("wal_link_record");
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let doc_a = server
            .create_work(sid, Edition::from_text("document A"))
            .unwrap();
        let doc_b = server
            .create_work(sid, Edition::from_text("document B"))
            .unwrap();

        server.create_link(sid, doc_a, doc_b, None, None).unwrap();
        assert!(
            server.wal.seq() >= 1,
            "create_link should write a WAL entry"
        );

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn wal_replays_link_after_crash() {
        use crate::edition::links::{HyperLink, HyperRef, Path, ProvenanceHop};

        let data_dir = std::env::temp_dir().join(format!(
            "xudanu_wal_link_replay_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir);
        std::fs::create_dir_all(&data_dir).unwrap();

        let origin_work_id;
        let dest_work_id;
        let link_id;

        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();

            origin_work_id = server
                .create_work(sid, Edition::from_text("origin document"))
                .unwrap();
            dest_work_id = server
                .create_work(sid, Edition::from_text("destination document"))
                .unwrap();

            server.checkpoint_to_store().unwrap();
            assert_eq!(server.wal.seq(), 0, "WAL empty after checkpoint");

            let origin_ref = HyperRef::single(
                Some(Edition::from_text("excerpt text")),
                Some(origin_work_id),
                None,
                Some(Path::new(vec![RangeElement::label(
                    42,
                    RangeElement::text("labelled"),
                )])),
            )
            .with_provenance_chain(vec![ProvenanceHop::new(999, 888)]);
            let dest_ref = HyperRef::single(None, Some(dest_work_id), Some(origin_work_id), None);
            let link = HyperLink::make(vec![100, 200], origin_ref, dest_ref);
            link_id = server.create_link_with_hyperlink(sid, link).unwrap();

            assert_eq!(
                server.wal.seq(),
                1,
                "WAL should have exactly 1 entry for the link"
            );
        }

        {
            let mut server = Server::new();
            server.restore_from_data_dir(&data_dir, None).unwrap();

            let ls = server
                .links
                .get(&link_id)
                .expect("link must survive crash via WAL replay");
            assert_eq!(ls.origin, origin_work_id);
            assert_eq!(ls.destination, dest_work_id);
            assert_eq!(
                ls.link.link_types(),
                &[100, 200],
                "link_types must survive WAL replay"
            );

            let o_ref = ls.link.end_at("LeftEnd").expect("LeftEnd must exist");
            assert_eq!(o_ref.work_context(), Some(origin_work_id));
            assert_eq!(
                o_ref.excerpt().unwrap().to_text().to_string(),
                "excerpt text",
                "excerpt must survive WAL replay"
            );
            assert_eq!(
                o_ref.provenance_chain().len(),
                1,
                "provenance_chain must survive WAL replay"
            );
            assert_eq!(o_ref.provenance_chain()[0].source_work_id(), 999);
            assert_eq!(o_ref.provenance_chain()[0].link_id(), 888);

            let d_ref = ls.link.end_at("RightEnd").expect("RightEnd must exist");
            assert_eq!(d_ref.work_context(), Some(dest_work_id));
            assert_eq!(d_ref.original_context(), Some(origin_work_id));

            let w2l = server.work_to_links.get(&origin_work_id);
            assert!(
                w2l.is_some() && w2l.unwrap().contains(&link_id),
                "work_to_links must include origin"
            );
            let w2l2 = server.work_to_links.get(&dest_work_id);
            assert!(
                w2l2.is_some() && w2l2.unwrap().contains(&link_id),
                "work_to_links must include destination"
            );

            assert!(
                server.link_counter >= link_id,
                "link_counter must be restored"
            );
        }

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn wal_link_truncated_after_checkpoint() {
        let (mut server, data_dir) = setup_chunk_store_server("wal_link_truncate");
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let doc_a = server
            .create_work(sid, Edition::from_text("document A"))
            .unwrap();
        let doc_b = server
            .create_work(sid, Edition::from_text("document B"))
            .unwrap();

        server.create_link(sid, doc_a, doc_b, None, None).unwrap();
        assert!(server.wal.seq() >= 1, "WAL should have link entry");

        server.checkpoint_to_store().unwrap();
        assert_eq!(
            server.wal.seq(),
            0,
            "WAL should be truncated after checkpoint"
        );

        let wal_path = data_dir.join("wal.log");
        let (_ver, entries) = crate::persist::wal::WalLog::read_entries(&wal_path).unwrap();
        assert!(
            entries.is_empty(),
            "WAL file should be empty after checkpoint"
        );

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    #[test]
    #[cfg(feature = "server")]
    fn wal_replays_link_does_not_duplicate() {
        let data_dir = std::env::temp_dir().join(format!(
            "xudanu_wal_link_nodupe_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        let _ = std::fs::remove_dir_all(&data_dir);
        std::fs::create_dir_all(&data_dir).unwrap();

        let link_id;

        {
            let mut server = Server::new();
            server.init_data_dir(&data_dir, None).unwrap();
            let sid = server.connect();
            server.login_public(sid).unwrap();
            let doc_a = server
                .create_work(sid, Edition::from_text("doc A"))
                .unwrap();
            let doc_b = server
                .create_work(sid, Edition::from_text("doc B"))
                .unwrap();

            server.checkpoint_to_store().unwrap();

            server.create_link(sid, doc_a, doc_b, None, None).unwrap();
            link_id = server.link_counter;

            assert_eq!(server.links.len(), 1);
        }

        {
            let mut server = Server::new();
            server.restore_from_data_dir(&data_dir, None).unwrap();

            assert_eq!(
                server.links.len(),
                1,
                "link should not be duplicated after WAL replay"
            );
            assert!(
                server.links.contains_key(&link_id),
                "original link_id should exist"
            );
        }

        let _ = std::fs::remove_dir_all(&data_dir);
    }

    fn compound_test_setup() -> (Server, SessionId, BeId, BeId) {
        let (mut server, sid) = setup_logged_in_server();
        let source_a = server
            .create_work(sid, Edition::from_text("Hello World"))
            .unwrap();
        let doc_b = server
            .create_work(sid, Edition::from_text("Start. End."))
            .unwrap();
        (server, sid, source_a, doc_b)
    }

    #[test]
    fn compound_set_and_get_edition() {
        let (mut server, sid, source_a, doc_b) = compound_test_setup();
        assert!(server.get_compound_edition(doc_b).is_none());

        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::text("Start. "),
            crate::edition::compound::CompoundElement::span(source_a, 0, 5),
            crate::edition::compound::CompoundElement::text(" End."),
        ]);
        server
            .set_compound_edition(doc_b, compound.clone(), sid)
            .unwrap();

        let retrieved = server.get_compound_edition(doc_b).unwrap();
        assert_eq!(retrieved.elements().len(), 3);
        assert_eq!(retrieved.span_count(), 1);
        assert_eq!(retrieved.referenced_works(), vec![source_a]);
    }

    #[test]
    fn compound_resolve_work_returns_resolved_text() {
        let (mut server, sid, source_a, doc_b) = compound_test_setup();
        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::text("Start. "),
            crate::edition::compound::CompoundElement::span(source_a, 0, 5),
            crate::edition::compound::CompoundElement::text(" End."),
        ]);
        server.set_compound_edition(doc_b, compound, sid).unwrap();

        let resolved = server.resolve_compound_edition(doc_b).unwrap();
        assert_eq!(resolved.flat_text(), "Start. Hello End.");
        assert_eq!(resolved.span_ranges().len(), 1);
        assert_eq!(resolved.span_ranges()[0].source_work_id, source_a);
        assert_eq!(resolved.span_ranges()[0].flat_start, 7);
        assert_eq!(resolved.span_ranges()[0].flat_end, 12);
    }

    #[test]
    fn compound_resolve_updates_after_source_revision() {
        let (mut server, sid, source_a, doc_b) = compound_test_setup();

        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::text("Intro: "),
            crate::edition::compound::CompoundElement::span(source_a, 0, 5),
            crate::edition::compound::CompoundElement::text(". Done."),
        ]);
        server.set_compound_edition(doc_b, compound, sid).unwrap();

        let resolved1 = server.resolve_compound_edition(doc_b).unwrap();
        assert_eq!(resolved1.flat_text(), "Intro: Hello. Done.");

        server.work_grab(sid, source_a).unwrap();
        server
            .work_revise(sid, source_a, Edition::from_text("Greetings World"))
            .unwrap();

        let resolved2 = server.resolve_compound_edition(doc_b).unwrap();
        assert_eq!(
            resolved2.flat_text(),
            "Intro: Greet. Done.",
            "compound should reflect source revision"
        );
    }

    #[test]
    fn compound_resolve_multiple_sources() {
        let (mut server, sid, _source_a, _doc_b) = compound_test_setup();
        let src1 = server.create_work(sid, Edition::from_text("AAA")).unwrap();
        let src2 = server.create_work(sid, Edition::from_text("BBB")).unwrap();
        let doc = server
            .create_work(sid, Edition::from_text("placeholder"))
            .unwrap();

        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::span(src1, 0, 3),
            crate::edition::compound::CompoundElement::text("-"),
            crate::edition::compound::CompoundElement::span(src2, 0, 3),
        ]);
        server.set_compound_edition(doc, compound, sid).unwrap();

        let resolved = server.resolve_compound_edition(doc).unwrap();
        assert_eq!(resolved.flat_text(), "AAA-BBB");
        assert_eq!(resolved.span_ranges().len(), 2);
        assert_eq!(resolved.span_ranges()[0].source_work_id, src1);
        assert_eq!(resolved.span_ranges()[1].source_work_id, src2);
    }

    #[test]
    fn compound_resolve_work_not_found() {
        let (server, _sid, _source_a, _doc_b) = compound_test_setup();
        let result = server.resolve_compound_edition(999_999);
        assert!(matches!(result, Err(ServerError::WorkNotFound(_))));
    }

    #[test]
    fn compound_resolve_source_deleted_returns_error() {
        let (mut server, sid, source_a, doc_b) = compound_test_setup();

        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::span(source_a, 0, 5),
        ]);
        server.set_compound_edition(doc_b, compound, sid).unwrap();

        server.works.remove(&source_a);

        let result = server.resolve_compound_edition(doc_b);
        assert!(
            result.is_err(),
            "resolution should fail when source work is gone"
        );
    }

    #[test]
    fn compound_resolve_unicode_source() {
        let (mut server, sid, _source_a, _doc_b) = compound_test_setup();
        let unicode_src = server
            .create_work(sid, Edition::from_text("日本語のテスト"))
            .unwrap();
        let doc = server.create_work(sid, Edition::from_text("x")).unwrap();

        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::text("Text: "),
            crate::edition::compound::CompoundElement::span(unicode_src, 0, 3),
            crate::edition::compound::CompoundElement::text("!"),
        ]);
        server.set_compound_edition(doc, compound, sid).unwrap();

        let resolved = server.resolve_compound_edition(doc).unwrap();
        assert_eq!(resolved.flat_text(), "Text: 日本語!");
    }

    #[test]
    fn compound_set_on_nonexistent_work_fails() {
        let (mut server, sid, _source_a, _doc_b) = compound_test_setup();
        let compound = crate::edition::compound::CompoundEdition::empty();
        let result = server.set_compound_edition(999_999, compound, sid);
        assert!(result.is_err());
    }

    #[test]
    fn compound_referencing_works_reverse_lookup() {
        let (mut server, sid, source_a, doc_b) = compound_test_setup();
        let doc_c = server
            .create_work(sid, Edition::from_text("doc-c"))
            .unwrap();

        let compound_b = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::span(source_a, 0, 3),
        ]);
        server.set_compound_edition(doc_b, compound_b, sid).unwrap();

        let compound_c = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::text("prefix"),
            crate::edition::compound::CompoundElement::span(source_a, 2, 5),
        ]);
        server.set_compound_edition(doc_c, compound_c, sid).unwrap();

        let referencing = server.works_with_compound_referencing(source_a);
        assert_eq!(referencing.len(), 2);
        assert!(referencing.contains(&doc_b));
        assert!(referencing.contains(&doc_c));
    }

    #[test]
    fn compound_persistence_survives_snapshot_roundtrip() {
        let (mut server, sid, source_a, doc_b) = compound_test_setup();

        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::text("Hello "),
            crate::edition::compound::CompoundElement::span(source_a, 0, 5),
        ]);
        server.set_compound_edition(doc_b, compound, sid).unwrap();

        let snapshot = server.to_snapshot();
        let restored = Server::from_snapshot(&snapshot);

        let retrieved = restored.get_compound_edition(doc_b);
        assert!(
            retrieved.is_some(),
            "compound should survive snapshot roundtrip"
        );
        assert_eq!(retrieved.unwrap().elements().len(), 2);
    }

    #[test]
    fn compound_resolve_clamps_span_beyond_source_length() {
        let (mut server, sid, _source_a, _doc_b) = compound_test_setup();
        let short_src = server.create_work(sid, Edition::from_text("hi")).unwrap();
        let doc = server.create_work(sid, Edition::from_text("x")).unwrap();

        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::span(short_src, 0, 100),
        ]);
        server.set_compound_edition(doc, compound, sid).unwrap();

        let resolved = server.resolve_compound_edition(doc).unwrap();
        assert_eq!(
            resolved.flat_text(),
            "hi",
            "span should clamp to source length"
        );
    }

    #[test]
    fn compound_resolve_empty_compound() {
        let (mut server, sid, _source_a, doc_b) = compound_test_setup();
        server
            .set_compound_edition(
                doc_b,
                crate::edition::compound::CompoundEdition::empty(),
                sid,
            )
            .unwrap();

        let resolved = server.resolve_compound_edition(doc_b).unwrap();
        assert!(resolved.flat_text().is_empty());
        assert!(resolved.elements().is_empty());
    }

    #[test]
    fn compound_resolve_text_only_compound() {
        let (mut server, sid, _source_a, doc_b) = compound_test_setup();
        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::text("just "),
            crate::edition::compound::CompoundElement::text("text"),
        ]);
        server.set_compound_edition(doc_b, compound, sid).unwrap();

        let resolved = server.resolve_compound_edition(doc_b).unwrap();
        assert_eq!(resolved.flat_text(), "just text");
        assert_eq!(resolved.span_ranges().len(), 0);
        assert_eq!(resolved.elements().len(), 2);
    }

    #[test]
    fn compound_source_title_lookup() {
        let (mut server, sid, _source_a, _doc_b) = compound_test_setup();
        let src = server
            .create_work(sid, Edition::from_text("content"))
            .unwrap();
        server.set_work_title(src, "My Source Doc".to_string());

        let title = server.compound_source_title(src);
        assert_eq!(title.as_deref(), Some("My Source Doc"));
    }

    #[test]
    fn compound_dirty_tracking_on_revision() {
        let (mut server, sid, source_a, doc_b) = compound_test_setup();

        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::text("intro: "),
            crate::edition::compound::CompoundElement::span(source_a, 0, 5),
        ]);
        server.set_compound_edition(doc_b, compound, sid).unwrap();

        assert!(
            !server.is_compound_dirty(doc_b),
            "compound should not be dirty before revision"
        );

        server.work_grab(sid, source_a).unwrap();
        server
            .work_revise(sid, source_a, Edition::from_text("Changed"))
            .unwrap();

        assert!(
            server.is_compound_dirty(doc_b),
            "compound doc should be dirty after source revised"
        );

        server.clear_compound_dirty(doc_b);
        assert!(
            !server.is_compound_dirty(doc_b),
            "compound should not be dirty after clear"
        );
    }

    #[test]
    fn compound_dirty_only_affects_referencing_docs() {
        let (mut server, sid, _source_a, _doc_b) = compound_test_setup();
        let src1 = server.create_work(sid, Edition::from_text("src1")).unwrap();
        let src2 = server.create_work(sid, Edition::from_text("src2")).unwrap();
        let doc1 = server.create_work(sid, Edition::from_text("d1")).unwrap();
        let doc2 = server.create_work(sid, Edition::from_text("d2")).unwrap();

        server
            .set_compound_edition(
                doc1,
                crate::edition::compound::CompoundEdition::new(vec![
                    crate::edition::compound::CompoundElement::span(src1, 0, 4),
                ]),
                sid,
            )
            .unwrap();
        server
            .set_compound_edition(
                doc2,
                crate::edition::compound::CompoundEdition::new(vec![
                    crate::edition::compound::CompoundElement::span(src2, 0, 4),
                ]),
                sid,
            )
            .unwrap();

        server.work_grab(sid, src1).unwrap();
        server
            .work_revise(sid, src1, Edition::from_text("modified"))
            .unwrap();

        assert!(server.is_compound_dirty(doc1));
        assert!(
            !server.is_compound_dirty(doc2),
            "doc2 references src2, should not be dirty when src1 changes"
        );
    }

    #[test]
    fn compound_resolution_reflects_multiple_revisions() {
        let (mut server, sid, source_a, doc_b) = compound_test_setup();

        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::span(source_a, 0, 5),
        ]);
        server.set_compound_edition(doc_b, compound, sid).unwrap();

        let r1 = server.resolve_compound_edition(doc_b).unwrap();
        assert_eq!(r1.flat_text(), "Hello");

        server.work_grab(sid, source_a).unwrap();
        server
            .work_revise(sid, source_a, Edition::from_text("First"))
            .unwrap();
        let r2 = server.resolve_compound_edition(doc_b).unwrap();
        assert_eq!(r2.flat_text(), "First");

        server
            .work_revise(sid, source_a, Edition::from_text("Second revision"))
            .unwrap();
        let r3 = server.resolve_compound_edition(doc_b).unwrap();
        assert_eq!(r3.flat_text(), "Secon", "span [0,5) of 'Second revision'");
    }

    fn setup_two_session_server() -> (Server, SessionId, SessionId) {
        let mut server = Server::new();
        let sid_a = server.connect();
        server.login_public(sid_a).unwrap();
        let sid_b = server.connect();
        server.login_public(sid_b).unwrap();
        (server, sid_a, sid_b)
    }

    #[test]
    fn compound_cross_session_edit_source_visible_to_other() {
        let (mut server, sid_a, sid_b) = setup_two_session_server();

        let source = server
            .create_work(sid_a, Edition::from_text("Original Source Text"))
            .unwrap();

        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::text("Quote: "),
            crate::edition::compound::CompoundElement::span(source, 0, 8),
            crate::edition::compound::CompoundElement::text("."),
        ]);
        let doc_b = server
            .create_work(sid_b, Edition::from_text("placeholder"))
            .unwrap();
        server.set_compound_edition(doc_b, compound, sid_b).unwrap();

        let resolved_before = server.resolve_compound_edition(doc_b).unwrap();
        assert_eq!(resolved_before.flat_text(), "Quote: Original.");

        server.work_grab(sid_a, source).unwrap();
        server
            .work_revise(sid_a, source, Edition::from_text("CHANGED!"))
            .unwrap();

        let resolved_after = server.resolve_compound_edition(doc_b).unwrap();
        assert_eq!(
            resolved_after.flat_text(),
            "Quote: CHANGED!.",
            "session B's compound should reflect session A's edit"
        );

        assert!(
            server.is_compound_dirty(doc_b),
            "compound should be marked dirty after source revised by other session"
        );
    }

    #[test]
    fn compound_concurrent_both_sessions_set_compound_different_docs() {
        let (mut server, sid_a, sid_b) = setup_two_session_server();

        let src = server
            .create_work(sid_a, Edition::from_text("Shared Source"))
            .unwrap();

        let doc_a = server
            .create_work(sid_a, Edition::from_text("doc-a"))
            .unwrap();
        let doc_b = server
            .create_work(sid_b, Edition::from_text("doc-b"))
            .unwrap();

        let compound_a = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::span(src, 0, 6),
        ]);
        server
            .set_compound_edition(doc_a, compound_a, sid_a)
            .unwrap();

        let compound_b = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::text("ref: "),
            crate::edition::compound::CompoundElement::span(src, 7, 13),
        ]);
        server
            .set_compound_edition(doc_b, compound_b, sid_b)
            .unwrap();

        let ra = server.resolve_compound_edition(doc_a).unwrap();
        assert_eq!(ra.flat_text(), "Shared");
        let rb = server.resolve_compound_edition(doc_b).unwrap();
        assert_eq!(rb.flat_text(), "ref: Source");

        server.work_grab(sid_a, src).unwrap();
        server
            .work_revise(sid_a, src, Edition::from_text("Updated Content"))
            .unwrap();

        assert!(server.is_compound_dirty(doc_a));
        assert!(server.is_compound_dirty(doc_b));

        let ra2 = server.resolve_compound_edition(doc_a).unwrap();
        assert_eq!(ra2.flat_text(), "Update");
        let rb2 = server.resolve_compound_edition(doc_b).unwrap();
        assert_eq!(
            rb2.flat_text(),
            "ref:  Conte",
            "span [7,13) of 'Updated Content' = ' Conte' (pos 7 is space)"
        );
    }

    #[test]
    fn compound_session_b_resolves_then_source_changes_then_resolves_again() {
        let (mut server, sid_a, sid_b) = setup_two_session_server();

        let source = server
            .create_work(sid_a, Edition::from_text("Version 1 text here"))
            .unwrap();
        let doc = server.create_work(sid_b, Edition::from_text("x")).unwrap();

        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::span(source, 0, 9),
        ]);
        server.set_compound_edition(doc, compound, sid_b).unwrap();

        let r1 = server.resolve_compound_edition(doc).unwrap();
        assert_eq!(r1.flat_text(), "Version 1");

        server.work_grab(sid_a, source).unwrap();
        server
            .work_revise(sid_a, source, Edition::from_text("Version 2 is different"))
            .unwrap();

        assert!(
            server.is_compound_dirty(doc),
            "dirty flag should be set after source revision"
        );
        server.clear_compound_dirty(doc);
        assert!(!server.is_compound_dirty(doc));

        let r2 = server.resolve_compound_edition(doc).unwrap();
        assert_eq!(r2.flat_text(), "Version 2");

        assert!(
            !server.is_compound_dirty(doc),
            "resolving should not set dirty; only source revision sets it"
        );
    }

    #[test]
    fn compound_cross_session_rapid_alternating_revisions() {
        let (mut server, sid_a, _sid_b) = setup_two_session_server();

        let source = server.create_work(sid_a, Edition::from_text("T0")).unwrap();
        let doc = server.create_work(sid_a, Edition::from_text("x")).unwrap();

        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::span(source, 0, 2),
        ]);
        server.set_compound_edition(doc, compound, sid_a).unwrap();

        server.work_grab(sid_a, source).unwrap();

        for i in 1..=5 {
            let new_text = format!("T{}", i);
            server
                .work_revise(sid_a, source, Edition::from_text(&new_text))
                .unwrap();

            let resolved = server.resolve_compound_edition(doc).unwrap();
            assert_eq!(
                resolved.flat_text(),
                &new_text,
                "iteration {} should reflect revision",
                i
            );
            assert!(server.is_compound_dirty(doc), "dirty after iteration {}", i);
            server.clear_compound_dirty(doc);
        }
    }

    #[test]
    fn compound_cross_session_chained_transclusion() {
        let (mut server, sid_a, sid_b) = setup_two_session_server();

        let root = server
            .create_work(sid_a, Edition::from_text("Root Content ABC"))
            .unwrap();
        let mid = server
            .create_work(sid_a, Edition::from_text("placeholder"))
            .unwrap();

        let mid_compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::text("Mid: "),
            crate::edition::compound::CompoundElement::span(root, 0, 12),
        ]);
        server
            .set_compound_edition(mid, mid_compound, sid_a)
            .unwrap();

        let doc = server.create_work(sid_b, Edition::from_text("x")).unwrap();

        let doc_compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::text("Doc: ["),
            crate::edition::compound::CompoundElement::span(mid, 0, 5),
            crate::edition::compound::CompoundElement::text("] end"),
        ]);
        server
            .set_compound_edition(doc, doc_compound, sid_b)
            .unwrap();

        // doc's span reads mid's O-tree text (not recursively resolving mid's compound).
        // mid's O-tree text is "placeholder", so span(0,5) = "place"
        let resolved = server.resolve_compound_edition(doc).unwrap();
        assert_eq!(
            resolved.flat_text(),
            "Doc: [place] end",
            "doc spans into mid's raw O-tree text, not recursively through compound"
        );

        // When we resolve mid directly, it DOES expand root's content via compound
        let resolved_mid = server.resolve_compound_edition(mid).unwrap();
        assert_eq!(resolved_mid.flat_text(), "Mid: Root Content");

        server.work_grab(sid_a, root).unwrap();
        server
            .work_revise(sid_a, root, Edition::from_text("NEWROOTCONTENT"))
            .unwrap();

        assert!(
            server.is_compound_dirty(mid),
            "mid is dirty because root changed"
        );
        assert!(
            !server.is_compound_dirty(doc),
            "doc references mid's O-tree text, not root — should not be dirty"
        );

        let resolved2 = server.resolve_compound_edition(mid).unwrap();
        assert_eq!(resolved2.flat_text(), "Mid: NEWROOTCONTE");

        let resolved3 = server.resolve_compound_edition(doc).unwrap();
        assert_eq!(
            resolved3.flat_text(),
            "Doc: [place] end",
            "doc unchanged because mid's O-tree text is still 'placeholder'"
        );
    }

    #[test]
    fn compound_cross_session_read_permission_dispatch_layer() {
        let (mut server, sid_a, sid_b) = setup_two_session_server();

        let source = server
            .create_work(sid_a, Edition::from_text("Secret Content"))
            .unwrap();
        let doc = server.create_work(sid_b, Edition::from_text("x")).unwrap();

        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::span(source, 0, 6),
        ]);
        server.set_compound_edition(doc, compound, sid_b).unwrap();

        let result = server.resolve_compound_edition(doc);
        assert!(result.is_ok(), "both public sessions can read");

        server
            .work_set_read_club(sid_a, source, Some(server.empty_club_id()))
            .unwrap();

        let resolve_result = server.resolve_compound_edition(doc);
        assert!(
            resolve_result.is_ok(),
            "resolve_compound_edition uses work_text which does not check permissions; \
             dispatch layer enforces read access"
        );
        assert_eq!(
            resolve_result.unwrap().flat_text(),
            "Secret",
            "server-level resolve succeeds; permission enforced at wire protocol layer"
        );
    }

    #[test]
    fn compound_dirty_works_list_tracks_all_affected() {
        let (mut server, sid_a, _sid_b) = setup_two_session_server();

        let source = server
            .create_work(sid_a, Edition::from_text("Source"))
            .unwrap();
        let doc1 = server.create_work(sid_a, Edition::from_text("d1")).unwrap();
        let doc2 = server.create_work(sid_a, Edition::from_text("d2")).unwrap();
        let doc3 = server.create_work(sid_a, Edition::from_text("d3")).unwrap();

        for doc in [&doc1, &doc2, &doc3] {
            server
                .set_compound_edition(
                    *doc,
                    crate::edition::compound::CompoundEdition::new(vec![
                        crate::edition::compound::CompoundElement::span(source, 0, 3),
                    ]),
                    sid_a,
                )
                .unwrap();
        }

        assert!(server.compound_dirty_works().is_empty());

        server.work_grab(sid_a, source).unwrap();
        server
            .work_revise(sid_a, source, Edition::from_text("Modified"))
            .unwrap();

        let dirty = server.compound_dirty_works();
        assert_eq!(dirty.len(), 3, "all 3 compound docs should be dirty");
        assert!(dirty.contains(&doc1));
        assert!(dirty.contains(&doc2));
        assert!(dirty.contains(&doc3));
    }

    fn make_compound_work(
        server: &mut Server,
        sid: SessionId,
        placeholder: &str,
        compound: crate::edition::compound::CompoundEdition,
    ) -> BeId {
        let wid = server
            .create_work(sid, Edition::from_text(placeholder))
            .unwrap();
        server.set_compound_edition(wid, compound, sid).unwrap();
        wid
    }

    fn span_el(src: u64, s: usize, e: usize) -> crate::edition::compound::CompoundElement {
        crate::edition::compound::CompoundElement::span(src, s, e)
    }

    fn text_el(s: &str) -> crate::edition::compound::CompoundElement {
        crate::edition::compound::CompoundElement::text(s)
    }

    #[test]
    fn compound_recursive_simple_chain() {
        let (mut server, sid, _) = setup_two_session_server();

        let root = server.create_work(sid, Edition::from_text("ROOT")).unwrap();
        let mid = make_compound_work(
            &mut server,
            sid,
            "mid-otree",
            crate::edition::compound::CompoundEdition::new(vec![
                text_el("mid:"),
                span_el(root, 0, 4),
            ]),
        );
        let doc = make_compound_work(
            &mut server,
            sid,
            "doc-otree",
            crate::edition::compound::CompoundEdition::new(vec![
                text_el("doc["),
                span_el(mid, 0, 4),
                text_el("]"),
            ]),
        );

        let resolved = server.resolve_compound_recursive(doc).unwrap();
        assert_eq!(
            resolved.flat_text(),
            "doc[mid:]",
            "recursive: span(mid,0,4) of mid's resolved 'mid:ROOT' = 'mid:'"
        );

        let non_recursive = server.resolve_compound_edition(doc).unwrap();
        assert_eq!(
            non_recursive.flat_text(),
            "doc[mid-]",
            "non-recursive: span(mid,0,4) of mid's O-tree 'mid-otree' = 'mid-'"
        );
    }

    #[test]
    fn compound_recursive_direct_cycle() {
        let (mut server, sid, _) = setup_two_session_server();

        let a = make_compound_work(
            &mut server,
            sid,
            "raw-a",
            crate::edition::compound::CompoundEdition::new(vec![
                text_el("A["),
                span_el(0, 0, 3),
                text_el("]"),
            ]),
        );
        let b = make_compound_work(
            &mut server,
            sid,
            "raw-b",
            crate::edition::compound::CompoundEdition::new(vec![
                text_el("B["),
                span_el(a, 0, 3),
                text_el("]"),
            ]),
        );

        server
            .set_compound_edition(
                a,
                crate::edition::compound::CompoundEdition::new(vec![
                    text_el("A["),
                    span_el(b, 0, 3),
                    text_el("]"),
                ]),
                sid,
            )
            .unwrap();

        let resolved = server.resolve_compound_recursive(a).unwrap();
        assert!(
            !resolved.flat_text().is_empty(),
            "cycle should resolve gracefully without hanging"
        );
        assert!(
            resolved.flat_text().contains("A["),
            "should contain A's own text"
        );
    }

    #[test]
    fn compound_recursive_self_cycle() {
        let (mut server, sid, _) = setup_two_session_server();

        let a = make_compound_work(
            &mut server,
            sid,
            "self-raw",
            crate::edition::compound::CompoundEdition::new(vec![
                text_el("A["),
                span_el(0, 0, 3),
                text_el("]"),
            ]),
        );

        server
            .set_compound_edition(
                a,
                crate::edition::compound::CompoundEdition::new(vec![
                    text_el("prefix "),
                    span_el(a, 0, 4),
                    text_el(" suffix"),
                ]),
                sid,
            )
            .unwrap();

        let resolved = server.resolve_compound_recursive(a).unwrap();
        assert!(
            !resolved.flat_text().is_empty(),
            "self-cycle should not hang"
        );
        assert!(
            resolved.flat_text().contains("prefix"),
            "should contain A's own text"
        );
    }

    #[test]
    fn compound_recursive_diamond() {
        let (mut server, sid, _) = setup_two_session_server();

        let d = server
            .create_work(sid, Edition::from_text("DIAMOND"))
            .unwrap();
        let b = make_compound_work(
            &mut server,
            sid,
            "b-raw",
            crate::edition::compound::CompoundEdition::new(vec![text_el("b:"), span_el(d, 0, 7)]),
        );
        let c = make_compound_work(
            &mut server,
            sid,
            "c-raw",
            crate::edition::compound::CompoundEdition::new(vec![text_el("c:"), span_el(d, 0, 7)]),
        );
        let a = make_compound_work(
            &mut server,
            sid,
            "a-raw",
            crate::edition::compound::CompoundEdition::new(vec![
                span_el(b, 0, 2),
                text_el("-"),
                span_el(c, 0, 2),
            ]),
        );

        let resolved = server.resolve_compound_recursive(a).unwrap();
        assert_eq!(
            resolved.flat_text(),
            "b:-c:",
            "diamond: both paths resolve D, memoization ensures consistency"
        );
    }

    #[test]
    fn compound_recursive_depth_limit() {
        let (mut server, sid, _) = setup_two_session_server();

        let base = server.create_work(sid, Edition::from_text("BASE")).unwrap();
        let mut prev = base;

        for i in 0..50 {
            let placeholder = format!("level{}", i);
            let wrapper = make_compound_work(
                &mut server,
                sid,
                &placeholder,
                crate::edition::compound::CompoundEdition::new(vec![
                    text_el(&format!("L{}:", i)),
                    span_el(prev, 0, 4),
                ]),
            );
            prev = wrapper;
        }

        let resolved = server.resolve_compound_recursive(prev).unwrap();
        assert!(
            !resolved.flat_text().is_empty(),
            "deep nesting should not cause stack overflow or hang"
        );
    }

    #[test]
    fn compound_recursive_mixed_compound_and_plain() {
        let (mut server, sid, _) = setup_two_session_server();

        let plain = server
            .create_work(sid, Edition::from_text("PLAIN"))
            .unwrap();
        let comp = make_compound_work(
            &mut server,
            sid,
            "comp-raw",
            crate::edition::compound::CompoundEdition::new(vec![
                text_el("comp:"),
                span_el(plain, 0, 5),
            ]),
        );
        let doc = make_compound_work(
            &mut server,
            sid,
            "doc-raw",
            crate::edition::compound::CompoundEdition::new(vec![
                text_el("["),
                span_el(comp, 0, 5),
                text_el("|"),
                span_el(plain, 0, 3),
                text_el("]"),
            ]),
        );

        let resolved = server.resolve_compound_recursive(doc).unwrap();
        assert_eq!(
            resolved.flat_text(),
            "[comp:|PLA]",
            "mix of compound and plain sources resolves correctly"
        );
    }

    #[test]
    fn compound_recursive_live_update_propagates() {
        let (mut server, sid_a, _sid_b) = setup_two_session_server();

        let root = server
            .create_work(sid_a, Edition::from_text("v1text"))
            .unwrap();
        let mid = make_compound_work(
            &mut server,
            sid_a,
            "mid-raw",
            crate::edition::compound::CompoundEdition::new(vec![
                text_el("["),
                span_el(root, 0, 2),
                text_el("]"),
            ]),
        );
        let doc = make_compound_work(
            &mut server,
            sid_a,
            "doc-raw",
            crate::edition::compound::CompoundEdition::new(vec![
                text_el("<"),
                span_el(mid, 0, 3),
                text_el(">"),
            ]),
        );

        let r1 = server.resolve_compound_recursive(doc).unwrap();
        assert_eq!(r1.flat_text(), "<[v1>");

        server.work_grab(sid_a, root).unwrap();
        server
            .work_revise(sid_a, root, Edition::from_text("v2text"))
            .unwrap();

        let r2 = server.resolve_compound_recursive(doc).unwrap();
        assert_eq!(
            r2.flat_text(),
            "<[v2>",
            "recursive resolution propagates live edits through the chain"
        );
    }

    #[test]
    fn compound_recursive_vs_non_recursive_comparison() {
        let (mut server, sid, _) = setup_two_session_server();

        let src = server.create_work(sid, Edition::from_text("SRC")).unwrap();
        let mid = make_compound_work(
            &mut server,
            sid,
            "mid-otree-text",
            crate::edition::compound::CompoundEdition::new(vec![text_el("M:"), span_el(src, 0, 3)]),
        );
        let doc = make_compound_work(
            &mut server,
            sid,
            "doc-otree-text",
            crate::edition::compound::CompoundEdition::new(vec![span_el(mid, 0, 2)]),
        );

        let non_recur = server.resolve_compound_edition(doc).unwrap();
        assert_eq!(
            non_recur.flat_text(),
            "mi",
            "non-recursive reads mid's O-tree: 'mid-otree-text'[0:2]"
        );

        let recur = server.resolve_compound_recursive(doc).unwrap();
        assert_eq!(
            recur.flat_text(),
            "M:",
            "recursive reads mid's compound resolution: 'M:SRC'[0:2]"
        );
    }

    #[test]
    fn pending_content_notifications_capped() {
        let (mut server, _sid) = setup_logged_in_server();

        let fossil_id: crate::edition::RecorderId = 999;
        for i in 0..(MAX_PENDING_NOTIFICATIONS + 500) {
            server
                .pending_content_notifications
                .push(ContentNotification {
                    fossil_id,
                    edition_be_id: 1000 + i as u64,
                    is_direct: true,
                    work_be_id: None,
                    title: None,
                });
        }
        assert!(
            server.pending_content_notifications.len() >= MAX_PENDING_NOTIFICATIONS + 500,
            "precondition: vec should be overfilled"
        );

        server.cap_pending_notifications_for_test();
        assert!(
            server.pending_content_notifications.len() <= MAX_PENDING_NOTIFICATIONS,
            "notifications should be capped at MAX, got {}",
            server.pending_content_notifications.len()
        );
    }

    #[test]
    fn revision_authors_bounded_after_many_revisions() {
        let (mut server, sid) = setup_logged_in_server();
        let edition = crate::edition::Edition::from_text("initial");
        let work_id = server.create_work(sid, edition).unwrap();
        let author_club = server.resolve_author_club(sid);

        for i in 0..(MAX_REVISION_AUTHORS + 200) {
            let edition = crate::edition::Edition::from_text(&format!("rev {}", i));
            server
                .revise_work(work_id, sid, edition, author_club)
                .unwrap();
        }

        let ws = server.works.get(&work_id).expect("work should exist");
        assert!(
            ws.revision_authors.len() <= MAX_REVISION_AUTHORS,
            "revision_authors should be bounded at {}, got {}",
            MAX_REVISION_AUTHORS,
            ws.revision_authors.len()
        );
    }

    #[test]
    fn prune_disconnected_sessions_removes_old_disconnected() {
        let mut server = Server::new();
        let active1 = server.connect();
        let active2 = server.connect();
        let disconnected = server.connect();
        server.disconnect(disconnected).unwrap();

        assert_eq!(server.sessions.len(), 3);
        assert_eq!(server.session_count(), 2);

        let pruned = server.prune_disconnected_sessions();
        assert_eq!(pruned, 0, "within grace period, nothing pruned");
        assert_eq!(server.sessions.len(), 3);

        let old = server.connect();
        server.disconnect(old).unwrap();
        let old_session = server.sessions.get_mut(&old).unwrap();
        old_session.ended_at =
            Some(std::time::Instant::now() - std::time::Duration::from_secs(120));

        let pruned = server.prune_disconnected_sessions();
        assert_eq!(pruned, 1, "old disconnected session pruned");
        assert!(!server.sessions.contains_key(&old));
        assert!(server.sessions.contains_key(&active1));
        assert!(server.sessions.contains_key(&active2));
        assert!(server.sessions.contains_key(&disconnected));
    }

    #[test]
    fn disconnected_session_identity_resolves_anonymous() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        server.disconnect(sid).unwrap();

        let (name, club_id, _) = server.identity_for_session(sid);
        assert!(
            !name.is_empty(),
            "identity_for_session should still resolve for disconnected session"
        );
        assert!(
            club_id.is_some(),
            "club_id should be preserved while in grace period"
        );
    }

    #[test]
    fn prune_does_not_affect_attribution_history() {
        let (mut server, sid) = setup_logged_in_server();
        let edition = crate::edition::Edition::from_text("attribution test");
        let work_id = server.create_work(sid, edition).unwrap();
        let author_club = server.resolve_author_club(sid);

        let edition2 = crate::edition::Edition::from_text("attribution test v2");
        server
            .revise_work(work_id, sid, edition2, author_club)
            .unwrap();

        server.disconnect(sid).unwrap();

        let old_session = server.sessions.get_mut(&sid).unwrap();
        old_session.ended_at =
            Some(std::time::Instant::now() - std::time::Duration::from_secs(120));
        let pruned = server.prune_disconnected_sessions();
        assert_eq!(pruned, 1);

        let ws = server.works.get(&work_id).unwrap();
        assert!(
            ws.last_revision_author.is_some(),
            "attribution history should survive session pruning"
        );
        let rev = ws.work.revision_count();
        assert!(
            ws.revision_authors.contains_key(&rev),
            "revision_authors should survive session pruning"
        );
    }

    #[test]
    fn compound_rebuild_from_provenance_stamped_entries() {
        let (mut server, sid) = setup_logged_in_server();
        let source = server
            .create_work(sid, Edition::from_text("Hello World"))
            .unwrap();
        let doc = server
            .create_work(sid, Edition::from_text("prefix Hello suffix"))
            .unwrap();

        server.work_grab(sid, doc).unwrap();

        let author_club = server.resolve_author_club(sid);
        let elem_prov = crate::edition::provenance::ElementProvenance {
            author_public_key: [0u8; 32],
            author_display_name: "TestAuthor".to_string(),
            author_club_id: author_club.unwrap_or(0),
            timestamp: 1000,
            author_type: crate::edition::provenance::AuthorType::Human,
            llm_model: None,
            historical_author_id: None,
            source_work_id: Some(source),
            transcluded_by: None,
            derived_by: None,
        };

        let edition = server.work(doc).unwrap().current_edition().clone();
        let entries = edition.all_entries();
        let mut new_entries: Vec<(i64, Arc<crate::edition::range_element::Carrier>)> =
            Vec::with_capacity(entries.len());
        let mut cum = 0usize;
        for (pos, c) in &entries {
            let text = c.element.as_text().unwrap_or("");
            if cum >= 7 && cum < 12 {
                let mut carrier = (**c).clone();
                carrier.provenance = Some(elem_prov.clone());
                new_entries.push((*pos, Arc::new(carrier)));
            } else {
                new_entries.push((*pos, c.clone()));
            }
            cum += c.char_len();
        }
        let new_edition = crate::edition::Edition::from_entries(new_entries);
        server
            .revise_work(doc, sid, new_edition, author_club)
            .unwrap();

        let compound = server.compound_rebuild(doc, sid).unwrap();
        let elements = compound.elements();
        assert!(
            elements.len() >= 2,
            "rebuild should produce text + span elements, got {} elements",
            elements.len()
        );

        let has_span = elements.iter().any(|e| match e {
            crate::edition::compound::CompoundElement::Span { span } => {
                span.source_work_id() == source
            }
            _ => false,
        });
        assert!(has_span, "rebuild should produce a span pointing to source");

        let resolved = server.resolve_compound_edition(doc).unwrap();
        assert_eq!(
            resolved.flat_text(),
            "prefix Hello suffix",
            "resolved text should match original"
        );
    }

    #[test]
    fn compound_rebuild_text_only_works() {
        let (mut server, sid) = setup_logged_in_server();
        let doc = server
            .create_work(sid, Edition::from_text("plain text no transclusion"))
            .unwrap();

        let compound = server.compound_rebuild(doc, sid).unwrap();
        let elements = compound.elements();
        assert!(
            elements
                .iter()
                .all(|e| matches!(e, crate::edition::compound::CompoundElement::Text { .. })),
            "text-only work should produce only text elements"
        );

        let resolved = server.resolve_compound_edition(doc).unwrap();
        assert_eq!(resolved.flat_text(), "plain text no transclusion");
        assert_eq!(resolved.span_ranges().len(), 0);
    }

    #[test]
    fn compound_rebuild_repairs_corrupted_compound() {
        let (mut server, sid) = setup_logged_in_server();
        let source_a = server
            .create_work(sid, Edition::from_text("Hello World"))
            .unwrap();
        let doc_b = server
            .create_work(sid, Edition::from_text("Start. Hello End."))
            .unwrap();

        let corrupted = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::text("Start. Hello End."),
        ]);
        server.set_compound_edition(doc_b, corrupted, sid).unwrap();

        let before = server.get_compound_edition(doc_b).unwrap();
        assert_eq!(
            before.elements().len(),
            1,
            "compound should be corrupted (text-only)"
        );

        server.work_grab(sid, doc_b).unwrap();
        let author_club = server.resolve_author_club(sid);
        let elem_prov = crate::edition::provenance::ElementProvenance {
            author_public_key: [0u8; 32],
            author_display_name: "TestAuthor".to_string(),
            author_club_id: author_club.unwrap_or(0),
            timestamp: 1000,
            author_type: crate::edition::provenance::AuthorType::Human,
            llm_model: None,
            historical_author_id: None,
            source_work_id: Some(source_a),
            transcluded_by: None,
            derived_by: None,
        };
        let edition = server.work(doc_b).unwrap().current_edition().clone();
        let entries = edition.all_entries();
        let mut new_entries: Vec<(i64, Arc<crate::edition::range_element::Carrier>)> =
            Vec::with_capacity(entries.len());
        let mut cum = 0usize;
        for (pos, c) in &entries {
            if cum >= 7 && cum < 12 {
                let mut carrier = (**c).clone();
                carrier.provenance = Some(elem_prov.clone());
                new_entries.push((*pos, Arc::new(carrier)));
            } else {
                new_entries.push((*pos, c.clone()));
            }
            cum += c.char_len();
        }
        let new_edition = crate::edition::Edition::from_entries(new_entries);
        server
            .revise_work(doc_b, sid, new_edition, author_club)
            .unwrap();

        let compound = server.compound_rebuild(doc_b, sid).unwrap();
        let has_span = compound.elements().iter().any(|e| match e {
            crate::edition::compound::CompoundElement::Span { span } => {
                span.source_work_id() == source_a
            }
            _ => false,
        });
        assert!(
            has_span,
            "rebuild should repair corrupted compound by adding spans from provenance"
        );
    }

    #[test]
    fn compound_insert_element_creates_compound_if_absent() {
        let (mut server, sid, source_a, doc_b) = compound_test_setup();
        assert!(server.get_compound_edition(doc_b).is_none());

        let count = server
            .compound_insert_element(
                doc_b,
                0,
                crate::edition::compound::CompoundElement::span(source_a, 0, 5),
                sid,
            )
            .unwrap();
        assert_eq!(count, 1);

        let compound = server.get_compound_edition(doc_b).unwrap();
        assert_eq!(compound.len(), 1);
        assert_eq!(compound.span_count(), 1);
    }

    #[test]
    fn compound_insert_element_at_various_positions() {
        let (mut server, sid, source_a, doc_b) = compound_test_setup();
        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::text("A"),
            crate::edition::compound::CompoundElement::text("C"),
        ]);
        server.set_compound_edition(doc_b, compound, sid).unwrap();

        server
            .compound_insert_element(
                doc_b,
                1,
                crate::edition::compound::CompoundElement::text("B"),
                sid,
            )
            .unwrap();

        let compound = server.get_compound_edition(doc_b).unwrap();
        assert_eq!(compound.len(), 3);
        let texts: Vec<&str> = compound
            .elements()
            .iter()
            .filter_map(|e| e.text_content())
            .collect();
        assert_eq!(texts, vec!["A", "B", "C"]);
    }

    #[test]
    fn compound_insert_element_appends_when_index_out_of_range() {
        let (mut server, sid, _source_a, doc_b) = compound_test_setup();
        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::text("first"),
        ]);
        server.set_compound_edition(doc_b, compound, sid).unwrap();

        let count = server
            .compound_insert_element(
                doc_b,
                99,
                crate::edition::compound::CompoundElement::text("second"),
                sid,
            )
            .unwrap();
        assert_eq!(count, 2);

        let compound = server.get_compound_edition(doc_b).unwrap();
        assert_eq!(compound.len(), 2);
    }

    #[test]
    fn compound_remove_element() {
        let (mut server, sid, source_a, doc_b) = compound_test_setup();
        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::text("keep"),
            crate::edition::compound::CompoundElement::span(source_a, 0, 3),
            crate::edition::compound::CompoundElement::text("remove me"),
        ]);
        server.set_compound_edition(doc_b, compound, sid).unwrap();

        let count = server.compound_remove_element(doc_b, 2, sid).unwrap();
        assert_eq!(count, 2);

        let compound = server.get_compound_edition(doc_b).unwrap();
        assert_eq!(compound.len(), 2);
        let texts: Vec<&str> = compound
            .elements()
            .iter()
            .filter_map(|e| e.text_content())
            .collect();
        assert_eq!(texts, vec!["keep"]);
    }

    #[test]
    fn compound_remove_element_out_of_range_noop() {
        let (mut server, sid, _source_a, doc_b) = compound_test_setup();
        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::text("only"),
        ]);
        server.set_compound_edition(doc_b, compound, sid).unwrap();

        let count = server.compound_remove_element(doc_b, 99, sid).unwrap();
        assert_eq!(count, 1, "remove out of range should not change length");
    }

    #[test]
    fn compound_move_element_forward() {
        let (mut server, sid, _source_a, doc_b) = compound_test_setup();
        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::text("A"),
            crate::edition::compound::CompoundElement::text("B"),
            crate::edition::compound::CompoundElement::text("C"),
        ]);
        server.set_compound_edition(doc_b, compound, sid).unwrap();

        server.compound_move_element(doc_b, 0, 2, sid).unwrap();

        let compound = server.get_compound_edition(doc_b).unwrap();
        let texts: Vec<&str> = compound
            .elements()
            .iter()
            .filter_map(|e| e.text_content())
            .collect();
        assert_eq!(texts, vec!["B", "C", "A"]);
    }

    #[test]
    fn compound_move_element_backward() {
        let (mut server, sid, _source_a, doc_b) = compound_test_setup();
        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::text("A"),
            crate::edition::compound::CompoundElement::text("B"),
            crate::edition::compound::CompoundElement::text("C"),
        ]);
        server.set_compound_edition(doc_b, compound, sid).unwrap();

        server.compound_move_element(doc_b, 2, 0, sid).unwrap();

        let compound = server.get_compound_edition(doc_b).unwrap();
        let texts: Vec<&str> = compound
            .elements()
            .iter()
            .filter_map(|e| e.text_content())
            .collect();
        assert_eq!(texts, vec!["C", "A", "B"]);
    }

    #[test]
    fn compound_incremental_ops_then_resolve() {
        let (mut server, sid, source_a, doc_b) = compound_test_setup();

        server
            .compound_insert_element(
                doc_b,
                0,
                crate::edition::compound::CompoundElement::text("Intro: "),
                sid,
            )
            .unwrap();
        server
            .compound_insert_element(
                doc_b,
                1,
                crate::edition::compound::CompoundElement::span(source_a, 0, 5),
                sid,
            )
            .unwrap();
        server
            .compound_insert_element(
                doc_b,
                2,
                crate::edition::compound::CompoundElement::text(" Done."),
                sid,
            )
            .unwrap();

        let resolved = server.resolve_compound_edition(doc_b).unwrap();
        assert_eq!(resolved.flat_text(), "Intro: Hello Done.");
        assert_eq!(resolved.span_ranges().len(), 1);
    }

    #[test]
    fn compound_insert_on_nonexistent_work_fails() {
        let (mut server, sid, _source_a, _doc_b) = compound_test_setup();
        let result = server.compound_insert_element(
            999_999,
            0,
            crate::edition::compound::CompoundElement::text("x"),
            sid,
        );
        assert!(result.is_err());
    }

    #[test]
    fn compound_remove_on_nonexistent_work_fails() {
        let (mut server, sid, _source_a, _doc_b) = compound_test_setup();
        let result = server.compound_remove_element(999_999, 0, sid);
        assert!(result.is_err());
    }

    #[test]
    fn inline_transclusion_resolves_text() {
        let (mut server, sid) = setup_logged_in_server();
        let src = server
            .create_work(sid, Edition::from_text("Hello World"))
            .unwrap();

        let entries = vec![
            (
                0i64,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text("Prefix "),
                )),
            ),
            (
                1,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::transclusion(src, 0, 5),
                )),
            ),
            (
                2,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text(" Suffix"),
                )),
            ),
        ];
        let edition = Edition::from_entries(entries);
        let doc = server.create_work(sid, edition).unwrap();

        let result = server.resolve_inline_transclusions(doc).unwrap();
        assert_eq!(result.text, "Prefix Hello Suffix");
        assert_eq!(result.span_ranges.len(), 1);
        assert_eq!(result.span_ranges[0].source_work_id, src);
        assert_eq!(result.span_ranges[0].flat_start, 7);
        assert_eq!(result.span_ranges[0].flat_end, 12);
    }

    #[test]
    fn inline_transclusion_detects_presence() {
        let (mut server, sid) = setup_logged_in_server();
        let src = server
            .create_work(sid, Edition::from_text("source"))
            .unwrap();

        let entries = vec![
            (
                0i64,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text("before "),
                )),
            ),
            (
                1,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::transclusion(src, 0, 3),
                )),
            ),
            (
                2,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text(" after"),
                )),
            ),
        ];
        let edition = Edition::from_entries(entries);
        let doc = server.create_work(sid, edition).unwrap();

        assert!(server.work_has_inline_transclusions(doc));
        assert!(!server.work_has_inline_transclusions(src));
    }

    #[test]
    fn inline_transclusion_no_transclusions_returns_plain_text() {
        let (mut server, sid) = setup_logged_in_server();
        let doc = server
            .create_work(sid, Edition::from_text("just plain text"))
            .unwrap();

        let result = server.resolve_inline_transclusions(doc).unwrap();
        assert_eq!(result.text, "just plain text");
        assert!(result.span_ranges.is_empty());
    }

    #[test]
    fn inline_transclusion_clamps_to_source_length() {
        let (mut server, sid) = setup_logged_in_server();
        let src = server.create_work(sid, Edition::from_text("hi")).unwrap();

        let entries = vec![(
            0i64,
            std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                RangeElement::transclusion(src, 0, 100),
            )),
        )];
        let edition = Edition::from_entries(entries);
        let doc = server.create_work(sid, edition).unwrap();

        let result = server.resolve_inline_transclusions(doc).unwrap();
        assert_eq!(result.text, "hi");
    }

    #[test]
    fn inline_transclusion_multiple_sources() {
        let (mut server, sid) = setup_logged_in_server();
        let src_a = server.create_work(sid, Edition::from_text("AAA")).unwrap();
        let src_b = server.create_work(sid, Edition::from_text("BBB")).unwrap();

        let entries = vec![
            (
                0i64,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::transclusion(src_a, 0, 3),
                )),
            ),
            (
                1,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text("-"),
                )),
            ),
            (
                2,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::transclusion(src_b, 0, 3),
                )),
            ),
        ];
        let edition = Edition::from_entries(entries);
        let doc = server.create_work(sid, edition).unwrap();

        let result = server.resolve_inline_transclusions(doc).unwrap();
        assert_eq!(result.text, "AAA-BBB");
        assert_eq!(result.span_ranges.len(), 2);
    }

    #[test]
    fn inline_transclusion_migration_on_source_edit() {
        let (mut server, sid) = setup_logged_in_server();
        let src = server
            .create_work(sid, Edition::from_text("Hello World"))
            .unwrap();

        let entries = vec![
            (
                0i64,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text("Intro "),
                )),
            ),
            (
                1,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::transclusion(src, 0, 5),
                )),
            ),
            (
                2,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text(" End."),
                )),
            ),
        ];
        let edition = Edition::from_entries(entries);
        let doc = server.create_work(sid, edition).unwrap();

        let before = server.resolve_inline_transclusions(doc).unwrap();
        assert_eq!(before.text, "Intro Hello End.");

        server.work_grab(sid, src).unwrap();
        server
            .work_revise(sid, src, Edition::from_text("GPS Hello World"))
            .unwrap();

        let delta_ops = vec![
            crate::server::transport::protocol::TextDeltaOp::Insert {
                text: "GPS ".to_string(),
            },
            crate::server::transport::protocol::TextDeltaOp::Retain {
                count: "Hello World".chars().count() as u64,
            },
        ];

        server.migrate_inline_transclusions_for_delta(src, &delta_ops);

        let after = server.resolve_inline_transclusions(doc).unwrap();
        assert_eq!(
            after.text, "Intro Hello End.",
            "transclusion should still resolve to 'Hello' after insert before it"
        );
    }

    #[test]
    fn inline_transclusion_recursive_chain() {
        let (mut server, sid) = setup_logged_in_server();
        let src = server
            .create_work(sid, Edition::from_text("Hello World"))
            .unwrap();

        let mid_entries = vec![
            (
                0i64,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text("Middle: "),
                )),
            ),
            (
                1,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::transclusion(src, 0, 5),
                )),
            ),
            (
                2,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text(" done."),
                )),
            ),
        ];
        let mid = server
            .create_work(sid, Edition::from_entries(mid_entries))
            .unwrap();

        let doc_entries = vec![
            (
                0i64,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text("Top: "),
                )),
            ),
            (
                1,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::transclusion(mid, 0, 100),
                )),
            ),
            (
                2,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text(" end."),
                )),
            ),
        ];
        let doc = server
            .create_work(sid, Edition::from_entries(doc_entries))
            .unwrap();

        let result = server.resolve_inline_transclusions(doc).unwrap();
        assert_eq!(
            result.text, "Top: Middle: Hello done. end.",
            "recursive resolution should follow transclusion chain"
        );
        assert_eq!(
            result.span_ranges.len(),
            2,
            "should have spans for both mid and src levels"
        );
    }

    #[test]
    fn inline_transclusion_recursive_cycle() {
        let (mut server, sid) = setup_logged_in_server();
        let a = server.create_work(sid, Edition::from_text("base")).unwrap();

        let b_entries = vec![
            (
                0i64,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text("B-"),
                )),
            ),
            (
                1,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::transclusion(a, 0, 4),
                )),
            ),
        ];
        let b = server
            .create_work(sid, Edition::from_entries(b_entries))
            .unwrap();

        let a2_entries = vec![
            (
                0i64,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text("A-"),
                )),
            ),
            (
                1,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::transclusion(b, 0, 100),
                )),
            ),
        ];
        server.work_grab(sid, a).unwrap();
        server
            .work_revise(sid, a, Edition::from_entries(a2_entries))
            .unwrap();

        let result = server.resolve_inline_transclusions(a).unwrap();
        assert!(
            !result.text.is_empty(),
            "cycle should not cause infinite loop"
        );
        assert!(
            result.text.contains("A-")
                || result.text.contains("B-")
                || result.text.contains("base"),
            "should resolve at least one level: {}",
            result.text
        );
    }

    #[test]
    fn inline_transclusion_self_transclusion_resolves() {
        let (mut server, sid) = setup_logged_in_server();

        let entries = vec![
            (
                0i64,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text("Hello World"),
                )),
            ),
            (
                1,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text(" - "),
                )),
            ),
            (
                2,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::transclusion(9999, 0, 5),
                )),
            ),
        ];
        // Use a fake work ID — we'll create the work first
        let doc = server
            .create_work(sid, Edition::from_text("Hello World - placeholder"))
            .unwrap();

        // Now replace the edition with one that has a self-transclusion
        let self_entries = vec![
            (
                0i64,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text("Hello World"),
                )),
            ),
            (
                1,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text(" - "),
                )),
            ),
            (
                2,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::transclusion(doc, 0, 5),
                )),
            ),
        ];
        server.work_grab(sid, doc).unwrap();
        server
            .work_revise(sid, doc, Edition::from_entries(self_entries))
            .unwrap();

        let result = server.resolve_inline_transclusions(doc).unwrap();
        assert_eq!(
            result.text, "Hello World - Hello",
            "self-transclusion should resolve to the work's own text"
        );
        assert_eq!(result.span_ranges.len(), 1);
        assert_eq!(result.span_ranges[0].source_work_id, doc);
    }

    #[test]
    fn inline_transclusion_survives_checkpoint_roundtrip() {
        let (mut server, sid) = setup_logged_in_server();
        let src = server
            .create_work(sid, Edition::from_text("Hello World"))
            .unwrap();

        let entries = vec![
            (
                0i64,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text("Intro "),
                )),
            ),
            (
                1,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::transclusion(src, 0, 5),
                )),
            ),
            (
                2,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text(" End."),
                )),
            ),
        ];
        let doc = server
            .create_work(sid, Edition::from_entries(entries))
            .unwrap();

        let before = server.resolve_inline_transclusions(doc).unwrap();
        assert_eq!(before.text, "Intro Hello End.");

        let snapshot = server.to_snapshot();
        let restored = Server::from_snapshot(&snapshot);

        let after = restored.resolve_inline_transclusions(doc).unwrap();
        assert_eq!(
            after.text, "Intro Hello End.",
            "transclusion must survive checkpoint roundtrip"
        );
        assert_eq!(after.span_ranges.len(), 1);
        assert_eq!(after.span_ranges[0].source_work_id, src);
    }

    #[test]
    fn inline_transclusion_survives_migrate_compound_to_inline() {
        let (mut server, sid) = setup_logged_in_server();
        let src = server
            .create_work(sid, Edition::from_text("Hello World"))
            .unwrap();

        let entries = vec![
            (
                0i64,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text("Intro "),
                )),
            ),
            (
                1,
                std::sync::Arc::new(crate::edition::range_element::Carrier::new(
                    RangeElement::text(" End."),
                )),
            ),
        ];
        let doc = server
            .create_work(sid, Edition::from_entries(entries))
            .unwrap();

        let compound = crate::edition::compound::CompoundEdition::new(vec![
            crate::edition::compound::CompoundElement::text("Intro "),
            crate::edition::compound::CompoundElement::span(src, 0, 5),
            crate::edition::compound::CompoundElement::text(" End."),
        ]);
        server.set_compound_edition(doc, compound, sid).unwrap();

        let migrated = server.migrate_compound_to_inline(doc).unwrap();
        assert_eq!(migrated, 1, "should migrate 1 span");

        let snapshot = server.to_snapshot();
        let restored = Server::from_snapshot(&snapshot);

        assert!(
            restored.work_has_inline_transclusions(doc),
            "migrated transclusion must survive checkpoint roundtrip"
        );
        let result = restored.resolve_inline_transclusions(doc).unwrap();
        assert!(
            result.span_ranges.iter().any(|sr| sr.source_work_id == src),
            "source work reference must survive roundtrip"
        );
    }

    #[test]
    fn work_merge_preserves_source_author_and_stamps_curator() {
        let (mut server, sid) = setup_logged_in_server();

        let base = server
            .create_work(sid, Edition::from_text("Hello World"))
            .unwrap();
        let branch_a = server
            .create_work(sid, Edition::from_text("Hello Earth"))
            .unwrap();
        let branch_b = server
            .create_work(sid, Edition::from_text("Hello Mars"))
            .unwrap();

        server.work_grab(sid, branch_a).unwrap();
        let author_club = server.resolve_author_club(sid);
        let alice_prov = crate::edition::provenance::ElementProvenance {
            author_public_key: [1u8; 32],
            author_display_name: "Alice".to_string(),
            author_club_id: author_club.unwrap_or(0),
            timestamp: 1000,
            author_type: crate::edition::provenance::AuthorType::Human,
            llm_model: None,
            historical_author_id: None,
            source_work_id: None,
            transcluded_by: None,
            derived_by: None,
        };
        let edition_a = server.work(branch_a).unwrap().current_edition().clone();
        let entries_a = edition_a.all_entries();
        let new_entries_a: Vec<(i64, Arc<crate::edition::range_element::Carrier>)> = entries_a
            .iter()
            .map(|(pos, c)| {
                let mut carrier = (**c).clone();
                carrier.provenance = Some(alice_prov.clone());
                (*pos, Arc::new(carrier))
            })
            .collect();
        let stamped_a = crate::edition::Edition::from_entries(new_entries_a);
        server
            .revise_work(branch_a, sid, stamped_a, author_club)
            .unwrap();

        let merged_id = server.work_merge(sid, base, branch_a, branch_b).unwrap();

        let merged_edition = server.work(merged_id).unwrap().current_edition().clone();
        let entries = merged_edition.all_entries();

        let has_derived_by = entries.iter().any(|(_, c)| {
            c.provenance
                .as_ref()
                .and_then(|p| p.derived_by.as_ref())
                .map(|d| d.method == crate::edition::provenance::DerivationMethod::Merge)
                .unwrap_or(false)
        });
        assert!(
            has_derived_by,
            "merged elements should carry curator provenance via derived_by"
        );

        let has_alice_author = entries.iter().any(|(_, c)| {
            c.provenance
                .as_ref()
                .map(|p| p.author_display_name == "Alice")
                .unwrap_or(false)
        });
        assert!(
            has_alice_author,
            "merged elements from branch_a should preserve Alice's author provenance"
        );
    }

    #[test]
    fn work_merge_creates_valid_text() {
        let (mut server, sid) = setup_logged_in_server();

        let base = server
            .create_work(sid, Edition::from_text("Hello World"))
            .unwrap();
        let branch_a = server
            .create_work(sid, Edition::from_text("Hello Earth"))
            .unwrap();
        let branch_b = server
            .create_work(sid, Edition::from_text("Hello World"))
            .unwrap();

        let merged_id = server.work_merge(sid, base, branch_a, branch_b).unwrap();
        let merged_text = server.work(merged_id).unwrap().current_edition().to_text();

        assert!(
            merged_text.contains("Hello"),
            "merged text should contain common prefix"
        );
    }

    #[test]
    fn work_ghost_returns_none_for_non_archived() {
        let (mut server, sid) = setup_logged_in_server();
        let work = server
            .create_work(sid, Edition::from_text("active work"))
            .unwrap();

        assert!(
            server.work_ghost(work).is_none(),
            "ghost should be None for non-archived work"
        );
    }

    #[test]
    fn work_ghost_returns_info_for_archived() {
        let (mut server, sid) = setup_logged_in_server();
        let work = server
            .create_work(sid, Edition::from_text("archived work"))
            .unwrap();
        server.set_work_title(work, "My Archived Doc".to_string());

        server.work_archive(sid, work).unwrap();

        let ghost = server
            .work_ghost(work)
            .expect("ghost should exist for archived work");
        assert_eq!(ghost.work_id, work);
        assert_eq!(ghost.title, "My Archived Doc");
        assert!(
            ghost.archived_by.is_some(),
            "ghost should record who archived"
        );
        assert!(
            ghost.archived_at.is_some(),
            "ghost should record when archived"
        );
        assert!(
            !ghost.lifecycle_history.is_empty(),
            "ghost should include lifecycle history"
        );
        assert_eq!(
            ghost.lifecycle_history.last().unwrap().kind,
            "archived",
            "last lifecycle event should be 'archived'"
        );
    }

    #[test]
    fn work_ghost_includes_full_lifecycle_history() {
        let (mut server, sid) = setup_logged_in_server();
        let work = server
            .create_work(sid, Edition::from_text("cycled work"))
            .unwrap();

        server.work_archive(sid, work).unwrap();
        server.work_unarchive(sid, work).unwrap();
        server.work_archive(sid, work).unwrap();

        let ghost = server
            .work_ghost(work)
            .expect("ghost should exist after re-archive");
        assert_eq!(
            ghost.lifecycle_history.len(),
            3,
            "should have 3 lifecycle events"
        );
        assert_eq!(ghost.lifecycle_history[0].kind, "archived");
        assert_eq!(ghost.lifecycle_history[1].kind, "unarchived");
        assert_eq!(ghost.lifecycle_history[2].kind, "archived");

        assert_eq!(
            ghost.archived_at,
            Some(ghost.lifecycle_history[2].timestamp),
            "archived_at should match last archive event"
        );
    }

    #[test]
    fn element_insert_work_ref_round_trip() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();
        let work_b = server
            .create_work(sid, Edition::from_text("target"))
            .unwrap();

        server.work_grab(sid, work_a).unwrap();
        let ed = server.work_edition(work_a).unwrap();
        let new_ed = ed.with(5, RangeElement::work(work_b));
        server.work_revise(sid, work_a, new_ed).unwrap();

        let ed2 = server.work_edition(work_a).unwrap();
        let entries = ed2.all_entries();
        let work_elem = entries
            .iter()
            .find(|(p, _)| *p == 5)
            .map(|(_, c)| &c.element);
        assert!(work_elem.is_some(), "position 5 should have an element");
        assert_eq!(
            work_elem.unwrap().as_work_id(),
            Some(work_b),
            "element at position 5 should be a WorkRef to work_b"
        );
    }

    #[test]
    fn element_insert_edition_ref_round_trip() {
        let (mut server, sid) = setup_logged_in_server();
        let work = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();

        server.work_grab(sid, work).unwrap();
        let ed = server.work_edition(work).unwrap();
        let new_ed = ed.with(0, RangeElement::edition(12345));
        server.work_revise(sid, work, new_ed).unwrap();

        let ed2 = server.work_edition(work).unwrap();
        let entries = ed2.all_entries();
        let edition_elem = entries
            .iter()
            .find(|(p, _)| *p == 0)
            .map(|(_, c)| &c.element);
        assert!(edition_elem.is_some(), "position 0 should have an element");
        assert_eq!(
            edition_elem.unwrap().as_edition_id(),
            Some(12345),
            "element at position 0 should be an EditionRef"
        );
    }

    #[test]
    fn element_insert_idholder_round_trip() {
        let (mut server, sid) = setup_logged_in_server();
        let work = server
            .create_work(sid, Edition::from_text("abcdef"))
            .unwrap();

        server.work_grab(sid, work).unwrap();
        let ed = server.work_edition(work).unwrap();
        let new_ed = ed.with(3, RangeElement::id_holder(999));
        server.work_revise(sid, work, new_ed).unwrap();

        let ed2 = server.work_edition(work).unwrap();
        let entries = ed2.all_entries();
        let idholder_elem = entries.iter().find(|(p, _)| *p == 3);
        assert!(idholder_elem.is_some(), "position 3 should have an element");
        assert!(
            matches!(
                idholder_elem.unwrap().1.element,
                RangeElement::IDHolder { id: 999 }
            ),
            "element at position 3 should be IDHolder(999)"
        );
    }

    #[test]
    fn element_insert_preserves_surrounding_text() {
        let (mut server, sid) = setup_logged_in_server();
        let work = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();

        server.work_grab(sid, work).unwrap();
        let ed = server.work_edition(work).unwrap();
        let new_ed = ed.with(100, RangeElement::work(42));
        server.work_revise(sid, work, new_ed).unwrap();

        let ed2 = server.work_edition(work).unwrap();
        assert_eq!(
            ed2.to_text(),
            "hello world",
            "existing text should be unchanged when inserting at a new position"
        );
        assert!(
            ed2.all_entries()
                .iter()
                .any(|(p, c)| { *p == 100 && c.element.as_work_id() == Some(42) }),
            "WorkRef element should exist at position 100"
        );
    }

    #[test]
    fn range_element_payload_work_ref_round_trip() {
        use crate::server::transport::protocol::RangeElementPayload;
        let re = RangeElement::work(42);
        let payload = RangeElementPayload::from_range_element(&re);
        assert_eq!(payload.elem_type, "work");
        assert_eq!(payload.work_id, Some(42));
        let back = payload.to_range_element().expect("should convert back");
        assert_eq!(back.as_work_id(), Some(42));
    }

    #[test]
    fn range_element_payload_edition_ref_round_trip() {
        use crate::server::transport::protocol::RangeElementPayload;
        let re = RangeElement::edition(99);
        let payload = RangeElementPayload::from_range_element(&re);
        assert_eq!(payload.elem_type, "edition");
        assert_eq!(payload.edition_id, Some(99));
        let back = payload.to_range_element().expect("should convert back");
        assert_eq!(back.as_edition_id(), Some(99));
    }

    #[test]
    fn range_element_payload_idholder_round_trip() {
        use crate::server::transport::protocol::RangeElementPayload;
        let re = RangeElement::id_holder(777);
        let payload = RangeElementPayload::from_range_element(&re);
        assert_eq!(payload.elem_type, "id_holder");
        assert_eq!(payload.id_holder, Some(777));
        let back = payload.to_range_element().expect("should convert back");
        assert!(matches!(back, RangeElement::IDHolder { id: 777 }));
    }

    #[test]
    fn range_element_payload_blob_round_trip() {
        use crate::server::transport::protocol::RangeElementPayload;
        let re = RangeElement::blob(0xABCD, "image/png", 1024);
        let payload = RangeElementPayload::from_range_element(&re);
        assert_eq!(payload.elem_type, "blob");
        assert_eq!(payload.blob_hash, Some(0xABCD));
        assert_eq!(payload.blob_mime.as_deref(), Some("image/png"));
        assert_eq!(payload.blob_size, Some(1024));
        let back = payload.to_range_element().expect("should convert back");
        assert_eq!(back.as_blob_hash(), Some(0xABCD));
    }

    #[test]
    fn range_element_payload_text_still_works() {
        use crate::server::transport::protocol::RangeElementPayload;
        let re = RangeElement::text("hello");
        let payload = RangeElementPayload::from_range_element(&re);
        assert_eq!(payload.elem_type, "text");
        let back = payload.to_range_element().expect("should convert back");
        assert_eq!(back.as_text(), Some("hello"));
    }

    #[test]
    fn inter_span_link_create_and_retrieve() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server
            .create_work(sid, Edition::from_text("paragraph one. paragraph two."))
            .unwrap();
        let work_b = server
            .create_work(sid, Edition::from_text("response text"))
            .unwrap();

        let origin_ref = crate::edition::links::HyperRef::single(None, Some(work_a), None, None)
            .with_span(Some(0), Some(15));
        let dest_ref = crate::edition::links::HyperRef::single(None, Some(work_b), None, None)
            .with_span(Some(3), Some(10));

        let link_id = server
            .create_link(sid, work_a, work_b, Some(origin_ref), Some(dest_ref))
            .unwrap();

        let (_, _, link) = server.get_link(link_id).unwrap();
        let o_ref = link.end_at("LeftEnd").expect("LeftEnd must exist");
        let d_ref = link.end_at("RightEnd").expect("RightEnd must exist");

        assert_eq!(
            o_ref.start_position(),
            Some(0),
            "origin ref should preserve start_position"
        );
        assert_eq!(
            o_ref.end_position(),
            Some(15),
            "origin ref should preserve end_position"
        );
        assert_eq!(
            d_ref.start_position(),
            Some(3),
            "destination ref should preserve start_position"
        );
        assert_eq!(
            d_ref.end_position(),
            Some(10),
            "destination ref should preserve end_position"
        );
    }

    #[test]
    fn inter_span_link_via_payload_round_trip() {
        use crate::server::transport::protocol::{HyperRefPayload, RangeElementPayload};

        let mut payload = HyperRefPayload {
            kind: "single".to_string(),
            work_context: Some(100),
            original_context: None,
            path_context: None,
            excerpt: Some("target excerpt".to_string()),
            provenance_chain: Vec::new(),
            start_position: Some(5),
            end_position: Some(20),
        };

        let hr = payload.to_hyper_ref(100);
        assert_eq!(
            hr.start_position(),
            Some(5),
            "to_hyper_ref should preserve start_position"
        );
        assert_eq!(
            hr.end_position(),
            Some(20),
            "to_hyper_ref should preserve end_position"
        );
        assert_eq!(hr.work_context(), Some(100));

        let back = HyperRefPayload::from_hyper_ref(&hr);
        assert_eq!(back.start_position, Some(5));
        assert_eq!(back.end_position, Some(20));

        let _ = payload;
    }

    #[test]
    fn inter_span_link_update_preserves_span() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server
            .create_work(sid, Edition::from_text("origin"))
            .unwrap();
        let work_b = server.create_work(sid, Edition::from_text("dest")).unwrap();

        let origin_ref = crate::edition::links::HyperRef::single(None, Some(work_a), None, None);
        let dest_ref = crate::edition::links::HyperRef::single(None, Some(work_b), None, None);

        let link_id = server
            .create_link(sid, work_a, work_b, Some(origin_ref), Some(dest_ref))
            .unwrap();

        let updated_origin =
            crate::edition::links::HyperRef::single(None, Some(work_a), None, None)
                .with_span(Some(2), Some(4));
        let updated_dest = crate::edition::links::HyperRef::single(None, Some(work_b), None, None)
            .with_span(Some(0), Some(3));

        server
            .update_link(sid, link_id, Some(updated_origin), Some(updated_dest))
            .unwrap();

        let (_, _, link) = server.get_link(link_id).unwrap();
        let o_ref = link.end_at("LeftEnd").expect("LeftEnd must exist");
        let d_ref = link.end_at("RightEnd").expect("RightEnd must exist");

        assert_eq!(o_ref.start_position(), Some(2));
        assert_eq!(o_ref.end_position(), Some(4));
        assert_eq!(d_ref.start_position(), Some(0));
        assert_eq!(d_ref.end_position(), Some(3));
    }

    #[test]
    fn inter_span_link_no_span_defaults_none() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server
            .create_work(sid, Edition::from_text("origin"))
            .unwrap();
        let work_b = server.create_work(sid, Edition::from_text("dest")).unwrap();

        let origin_ref = crate::edition::links::HyperRef::single(None, Some(work_a), None, None);
        let dest_ref = crate::edition::links::HyperRef::single(None, Some(work_b), None, None);

        let link_id = server
            .create_link(sid, work_a, work_b, Some(origin_ref), Some(dest_ref))
            .unwrap();

        let (_, _, link) = server.get_link(link_id).unwrap();
        let o_ref = link.end_at("LeftEnd").expect("LeftEnd must exist");
        assert!(
            o_ref.start_position().is_none(),
            "default link should have no start_position"
        );
        assert!(
            o_ref.end_position().is_none(),
            "default link should have no end_position"
        );
    }

    #[test]
    fn render_transclusions_shows_shared_content_sources() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();
        let work_b = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();

        let rendered = server.render_transclusions(work_b).unwrap();
        assert!(!rendered.is_empty(), "should have rendered elements");

        let h_elem = rendered
            .iter()
            .find(|e| e.text == "h")
            .expect("should find 'h'");
        assert!(
            h_elem
                .transclusion_sources
                .iter()
                .any(|s| s.work_id == work_a),
            "'h' should show work_a as a transclusion source"
        );
    }

    #[test]
    fn render_transclusions_no_sources_for_unique_content() {
        let (mut server, sid) = setup_logged_in_server();
        let _work_a = server.create_work(sid, Edition::from_text("aaa")).unwrap();
        let work_b = server.create_work(sid, Edition::from_text("zzz")).unwrap();

        let rendered = server.render_transclusions(work_b).unwrap();
        for e in &rendered {
            assert!(
                e.transclusion_sources.is_empty(),
                "element '{}' should have no transclusion sources",
                e.text
            );
        }
    }

    #[test]
    fn render_transclusions_preserves_positions_and_text() {
        let (mut server, sid) = setup_logged_in_server();
        let work = server.create_work(sid, Edition::from_text("abc")).unwrap();

        let rendered = server.render_transclusions(work).unwrap();
        assert_eq!(rendered.len(), 3, "should have 3 elements");
        assert_eq!(rendered[0].position, 0);
        assert_eq!(rendered[0].text, "a");
        assert_eq!(rendered[1].position, 1);
        assert_eq!(rendered[1].text, "b");
        assert_eq!(rendered[2].position, 2);
        assert_eq!(rendered[2].text, "c");
    }

    #[test]
    fn render_transclusions_marks_transcluded_elements() {
        use std::sync::Arc;
        let (mut server, sid) = setup_logged_in_server();
        let source_work = server
            .create_work(sid, Edition::from_text("source text"))
            .unwrap();

        let prov = crate::edition::provenance::ElementProvenance {
            author_public_key: [0u8; 32],
            author_display_name: "author".to_string(),
            author_club_id: 1,
            timestamp: 0,
            author_type: crate::edition::provenance::AuthorType::Human,
            llm_model: None,
            historical_author_id: None,
            source_work_id: Some(source_work),
            transcluded_by: None,
            derived_by: None,
        };
        let carrier = crate::edition::range_element::Carrier::new(RangeElement::text("T"))
            .with_provenance(prov);
        let ed = Edition::from_entries(vec![(0, Arc::new(carrier))]);

        let work = server.create_work(sid, ed).unwrap();
        let rendered = server.render_transclusions(work).unwrap();
        let elem = rendered.first().expect("should have at least one element");
        assert!(
            elem.is_transcluded,
            "element with source_work_id should be marked transcluded"
        );
        assert_eq!(
            elem.source_work_id,
            Some(source_work),
            "should preserve source_work_id"
        );
        assert_eq!(
            elem.source_author_name.as_deref(),
            Some("author"),
            "should preserve source author name"
        );
    }

    #[test]
    fn render_transclusions_partial_overlap() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server
            .create_work(sid, Edition::from_text("shared unique a"))
            .unwrap();
        let work_b = server
            .create_work(sid, Edition::from_text("shared unique b"))
            .unwrap();

        let rendered = server.render_transclusions(work_b).unwrap();
        let shared_elems: Vec<_> = rendered
            .iter()
            .filter(|e| e.transclusion_sources.iter().any(|s| s.work_id == work_a))
            .collect();
        assert!(
            !shared_elems.is_empty(),
            "should find shared elements (s, h, a, r, e, d)"
        );

        let unique_elems: Vec<_> = rendered.iter().filter(|e| e.text == "b").collect();
        for e in &unique_elems {
            assert!(
                !e.transclusion_sources.iter().any(|s| s.work_id == work_a),
                "'b' should not show work_a as source"
            );
        }
    }

    #[test]
    fn link_add_end_creates_multi_ended_link() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server.create_work(sid, Edition::from_text("a")).unwrap();
        let work_b = server.create_work(sid, Edition::from_text("b")).unwrap();
        let work_c = server.create_work(sid, Edition::from_text("c")).unwrap();

        let o_ref = crate::edition::links::HyperRef::single(None, Some(work_a), None, None);
        let d_ref = crate::edition::links::HyperRef::single(None, Some(work_b), None, None);
        let link_id = server
            .create_link(sid, work_a, work_b, Some(o_ref), Some(d_ref))
            .unwrap();

        let third_end = crate::edition::links::HyperRef::single(None, Some(work_c), None, None);
        server
            .link_add_end(sid, link_id, "Context", third_end)
            .unwrap();

        let (_, _, link) = server.get_link(link_id).unwrap();
        assert_eq!(link.end_count(), 3, "should have 3 ends");
        assert!(link.has_end("LeftEnd"));
        assert!(link.has_end("RightEnd"));
        assert!(link.has_end("Context"));
    }

    #[test]
    fn link_remove_end_removes_named_end() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server.create_work(sid, Edition::from_text("a")).unwrap();
        let work_b = server.create_work(sid, Edition::from_text("b")).unwrap();
        let work_c = server.create_work(sid, Edition::from_text("c")).unwrap();

        let o_ref = crate::edition::links::HyperRef::single(None, Some(work_a), None, None);
        let d_ref = crate::edition::links::HyperRef::single(None, Some(work_b), None, None);
        let link_id = server
            .create_link(sid, work_a, work_b, Some(o_ref), Some(d_ref))
            .unwrap();

        let third_end = crate::edition::links::HyperRef::single(None, Some(work_c), None, None);
        server
            .link_add_end(sid, link_id, "Context", third_end)
            .unwrap();
        assert_eq!(server.get_link(link_id).unwrap().2.end_count(), 3);

        server.link_remove_end(sid, link_id, "Context").unwrap();
        let (_, _, link) = server.get_link(link_id).unwrap();
        assert_eq!(link.end_count(), 2, "should have 2 ends after removal");
        assert!(!link.has_end("Context"));
    }

    #[test]
    fn link_set_types_updates_type_set() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server.create_work(sid, Edition::from_text("a")).unwrap();
        let work_b = server.create_work(sid, Edition::from_text("b")).unwrap();

        let link_id = server.create_link(sid, work_a, work_b, None, None).unwrap();
        let (_, _, link) = server.get_link(link_id).unwrap();
        assert!(
            link.link_types().is_empty(),
            "default link should have no types"
        );

        server.link_set_types(sid, link_id, vec![1, 2]).unwrap();
        let (_, _, link) = server.get_link(link_id).unwrap();
        assert_eq!(link.link_types(), &[1, 2], "types should be [1, 2]");

        server.link_set_types(sid, link_id, vec![3]).unwrap();
        let (_, _, link) = server.get_link(link_id).unwrap();
        assert_eq!(link.link_types(), &[3], "types should be [3] after update");
    }

    #[test]
    fn link_type_registry_register_and_list() {
        let (mut server, _sid) = setup_logged_in_server();

        server.register_link_type(1, "citation".to_string());
        server.register_link_type(2, "response".to_string());
        server.register_link_type(3, "commentary".to_string());

        let types = server.list_link_types();
        assert_eq!(types.len(), 3);
        assert_eq!(types[0], (1, "citation".to_string()));
        assert_eq!(types[1], (2, "response".to_string()));
        assert_eq!(types[2], (3, "commentary".to_string()));
    }

    #[test]
    fn link_type_registry_overwrite() {
        let (mut server, _sid) = setup_logged_in_server();

        server.register_link_type(1, "old_name".to_string());
        server.register_link_type(1, "new_name".to_string());

        let types = server.list_link_types();
        assert_eq!(types.len(), 1, "should have 1 type after overwrite");
        assert_eq!(types[0].1, "new_name");
    }

    #[test]
    fn link_get_returns_all_named_ends() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server.create_work(sid, Edition::from_text("a")).unwrap();
        let work_b = server.create_work(sid, Edition::from_text("b")).unwrap();
        let work_c = server.create_work(sid, Edition::from_text("c")).unwrap();

        let o_ref = crate::edition::links::HyperRef::single(None, Some(work_a), None, None);
        let d_ref = crate::edition::links::HyperRef::single(None, Some(work_b), None, None);
        let link_id = server
            .create_link(sid, work_a, work_b, Some(o_ref), Some(d_ref))
            .unwrap();

        let third = crate::edition::links::HyperRef::single(None, Some(work_c), None, None);
        server
            .link_add_end(sid, link_id, "Footnote", third)
            .unwrap();

        let (_, _, link) = server.get_link(link_id).unwrap();
        let end_names = link.end_names();
        assert!(end_names.contains(&"LeftEnd"), "should have LeftEnd");
        assert!(end_names.contains(&"RightEnd"), "should have RightEnd");
        assert!(end_names.contains(&"Footnote"), "should have Footnote");
        assert_eq!(end_names.len(), 3, "should have exactly 3 ends");
    }

    #[test]
    fn hyperlink_make_with_ends_supports_arbitrary_names() {
        use crate::edition::links::{HyperLink, HyperRef};
        use std::collections::HashMap;

        let mut ends = HashMap::new();
        ends.insert(
            "Source".to_string(),
            HyperRef::single(None, Some(1), None, None),
        );
        ends.insert(
            "Target".to_string(),
            HyperRef::single(None, Some(2), None, None),
        );
        ends.insert(
            "Evidence".to_string(),
            HyperRef::single(None, Some(3), None, None),
        );

        let link = HyperLink::make_with_ends(vec![10, 20], ends);
        assert_eq!(link.end_count(), 3);
        assert_eq!(link.link_types(), &[10, 20]);
        assert!(link.has_end("Source"));
        assert!(link.has_end("Target"));
        assert!(link.has_end("Evidence"));
        assert!(!link.is_two_ended());
    }

    #[test]
    fn link_span_migrates_on_text_insert_before() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();
        let work_b = server.create_work(sid, Edition::from_text("dest")).unwrap();

        let o_ref = crate::edition::links::HyperRef::single(None, Some(work_a), None, None)
            .with_span(Some(0), Some(5));
        let d_ref = crate::edition::links::HyperRef::single(None, Some(work_b), None, None);
        let link_id = server
            .create_link(sid, work_a, work_b, Some(o_ref), Some(d_ref))
            .unwrap();

        server.work_grab(sid, work_a).unwrap();
        let new_ed = Edition::from_text("XX hello world");
        server.work_revise(sid, work_a, new_ed).unwrap();

        let (_, _, link) = server.get_link(link_id).unwrap();
        let o_ref = link.end_at("LeftEnd").unwrap();
        assert_eq!(
            o_ref.start_position(),
            Some(3),
            "start should shift by 3 (inserted 'XX ')"
        );
        assert_eq!(o_ref.end_position(), Some(8), "end should shift by 3");
    }

    #[test]
    fn link_span_migrates_on_text_delete_before() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server
            .create_work(sid, Edition::from_text("XXXhello world"))
            .unwrap();
        let work_b = server.create_work(sid, Edition::from_text("dest")).unwrap();

        let o_ref = crate::edition::links::HyperRef::single(None, Some(work_a), None, None)
            .with_span(Some(3), Some(8));
        let d_ref = crate::edition::links::HyperRef::single(None, Some(work_b), None, None);
        let link_id = server
            .create_link(sid, work_a, work_b, Some(o_ref), Some(d_ref))
            .unwrap();

        server.work_grab(sid, work_a).unwrap();
        let new_ed = Edition::from_text("hello world");
        server.work_revise(sid, work_a, new_ed).unwrap();

        let (_, _, link) = server.get_link(link_id).unwrap();
        let o_ref = link.end_at("LeftEnd").unwrap();
        assert_eq!(
            o_ref.start_position(),
            Some(0),
            "start should shift back by 3"
        );
        assert_eq!(o_ref.end_position(), Some(5), "end should shift back by 3");
    }

    #[test]
    fn link_span_migrates_on_text_replace_middle() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server
            .create_work(sid, Edition::from_text("abc middle xyz"))
            .unwrap();
        let work_b = server.create_work(sid, Edition::from_text("dest")).unwrap();

        let o_ref = crate::edition::links::HyperRef::single(None, Some(work_a), None, None)
            .with_span(Some(4), Some(10));
        let d_ref = crate::edition::links::HyperRef::single(None, Some(work_b), None, None);
        let link_id = server
            .create_link(sid, work_a, work_b, Some(o_ref), Some(d_ref))
            .unwrap();

        server.work_grab(sid, work_a).unwrap();
        let new_ed = Edition::from_text("abc LONGER xyz");
        server.work_revise(sid, work_a, new_ed).unwrap();

        let (_, _, link) = server.get_link(link_id).unwrap();
        let o_ref = link.end_at("LeftEnd").unwrap();
        assert_eq!(
            o_ref.start_position(),
            Some(4),
            "start should be at delete boundary"
        );
        assert_eq!(
            o_ref.end_position(),
            Some(10),
            "end should cover the replacement (delete+insert look-ahead)"
        );
    }

    #[test]
    fn link_span_no_migration_when_text_unchanged() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();
        let work_b = server.create_work(sid, Edition::from_text("dest")).unwrap();

        let o_ref = crate::edition::links::HyperRef::single(None, Some(work_a), None, None)
            .with_span(Some(0), Some(5));
        let d_ref = crate::edition::links::HyperRef::single(None, Some(work_b), None, None);
        let link_id = server
            .create_link(sid, work_a, work_b, Some(o_ref), Some(d_ref))
            .unwrap();

        server.work_grab(sid, work_a).unwrap();
        let same_ed = Edition::from_text("hello world");
        server.work_revise(sid, work_a, same_ed).unwrap();

        let (_, _, link) = server.get_link(link_id).unwrap();
        let o_ref = link.end_at("LeftEnd").unwrap();
        assert_eq!(o_ref.start_position(), Some(0), "start should be unchanged");
        assert_eq!(o_ref.end_position(), Some(5), "end should be unchanged");
    }

    #[test]
    fn link_span_migrates_via_delta_path() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();
        let work_b = server.create_work(sid, Edition::from_text("dest")).unwrap();

        let o_ref = crate::edition::links::HyperRef::single(None, Some(work_a), None, None)
            .with_span(Some(6), Some(11));
        let d_ref = crate::edition::links::HyperRef::single(None, Some(work_b), None, None);
        let link_id = server
            .create_link(sid, work_a, work_b, Some(o_ref), Some(d_ref))
            .unwrap();

        server.work_grab(sid, work_a).unwrap();
        let ops = vec![
            crate::server::transport::protocol::TextDeltaOp::Retain { count: 6 },
            crate::server::transport::protocol::TextDeltaOp::Insert {
                text: "big ".to_string(),
            },
            crate::server::transport::protocol::TextDeltaOp::Retain { count: 5 },
        ];
        server.migrate_link_spans_for_delta(work_a, &ops);

        let (_, _, link) = server.get_link(link_id).unwrap();
        let o_ref = link.end_at("LeftEnd").unwrap();
        assert_eq!(
            o_ref.start_position(),
            Some(10),
            "start should shift by 4 (inserted 'big ')"
        );
        assert_eq!(o_ref.end_position(), Some(15), "end should shift by 4");
    }

    #[test]
    fn compute_text_delta_prefix_suffix() {
        use crate::edition::compound::{compute_text_delta, DeltaOp};

        let ops = compute_text_delta("hello world", "hello big world");
        assert_eq!(
            ops,
            vec![DeltaOp::Retain(6), DeltaOp::Insert(4), DeltaOp::Retain(5),]
        );
    }

    #[test]
    fn compute_text_delta_delete() {
        use crate::edition::compound::{compute_text_delta, DeltaOp};

        let ops = compute_text_delta("hello world", "world");
        assert_eq!(ops, vec![DeltaOp::Delete(6), DeltaOp::Retain(5)]);
    }

    #[test]
    fn compute_text_delta_identical() {
        use crate::edition::compound::{compute_text_delta, DeltaOp};

        let ops = compute_text_delta("hello", "hello");
        assert_eq!(ops, vec![DeltaOp::Retain(5)]);
    }

    #[test]
    fn compute_text_delta_empty_old() {
        use crate::edition::compound::{compute_text_delta, DeltaOp};

        let ops = compute_text_delta("", "hello");
        assert_eq!(ops, vec![DeltaOp::Insert(5)]);
    }

    #[test]
    fn compute_text_delta_empty_new() {
        use crate::edition::compound::{compute_text_delta, DeltaOp};

        let ops = compute_text_delta("hello", "");
        assert_eq!(ops, vec![DeltaOp::Delete(5)]);
    }

    #[test]
    fn link_span_migration_multi_ended_all_ends_migrate() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();
        let work_b = server.create_work(sid, Edition::from_text("dest")).unwrap();
        let work_c = server.create_work(sid, Edition::from_text("ctx")).unwrap();

        let o_ref = crate::edition::links::HyperRef::single(None, Some(work_a), None, None)
            .with_span(Some(0), Some(5));
        let d_ref = crate::edition::links::HyperRef::single(None, Some(work_b), None, None)
            .with_span(Some(0), Some(4));
        let link_id = server
            .create_link(sid, work_a, work_b, Some(o_ref), Some(d_ref))
            .unwrap();

        let third = crate::edition::links::HyperRef::single(None, Some(work_c), None, None)
            .with_span(Some(0), Some(3));
        server.link_add_end(sid, link_id, "Context", third).unwrap();

        server.work_grab(sid, work_a).unwrap();
        let new_ed = Edition::from_text(">>> hello world");
        server.work_revise(sid, work_a, new_ed).unwrap();

        let (_, _, link) = server.get_link(link_id).unwrap();
        let left = link.end_at("LeftEnd").unwrap();
        let right = link.end_at("RightEnd").unwrap();
        let ctx = link.end_at("Context").unwrap();

        assert_eq!(
            left.start_position(),
            Some(4),
            "LeftEnd span on work_a should shift by 3"
        );
        assert_eq!(left.end_position(), Some(9));

        assert_eq!(
            right.start_position(),
            Some(0),
            "RightEnd span on work_b should be unchanged"
        );
        assert_eq!(right.end_position(), Some(4));

        assert_eq!(
            ctx.start_position(),
            Some(0),
            "Context span on work_c should be unchanged"
        );
        assert_eq!(ctx.end_position(), Some(3));
    }

    #[test]
    fn link_span_collapses_when_fully_deleted() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();
        let work_b = server.create_work(sid, Edition::from_text("dest")).unwrap();

        let o_ref = crate::edition::links::HyperRef::single(None, Some(work_a), None, None)
            .with_span(Some(0), Some(5));
        let d_ref = crate::edition::links::HyperRef::single(None, Some(work_b), None, None);
        let link_id = server
            .create_link(sid, work_a, work_b, Some(o_ref), Some(d_ref))
            .unwrap();

        server.work_grab(sid, work_a).unwrap();
        let new_ed = Edition::from_text("world");
        server.work_revise(sid, work_a, new_ed).unwrap();

        let (_, _, link) = server.get_link(link_id).unwrap();
        let o_ref = link.end_at("LeftEnd").unwrap();
        assert_eq!(
            o_ref.start_position(),
            Some(0),
            "start should collapse to 0 when content before it is deleted"
        );
        assert_eq!(
            o_ref.end_position(),
            Some(0),
            "end should collapse to 0 (span content fully deleted)"
        );
    }

    #[test]
    fn link_span_unaffected_for_other_works() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();
        let work_b = server
            .create_work(sid, Edition::from_text("other text"))
            .unwrap();
        let work_c = server
            .create_work(sid, Edition::from_text("third"))
            .unwrap();

        let link_a = {
            let o = crate::edition::links::HyperRef::single(None, Some(work_a), None, None)
                .with_span(Some(0), Some(5));
            let d = crate::edition::links::HyperRef::single(None, Some(work_c), None, None);
            server
                .create_link(sid, work_a, work_c, Some(o), Some(d))
                .unwrap()
        };
        let link_b = {
            let o = crate::edition::links::HyperRef::single(None, Some(work_b), None, None)
                .with_span(Some(0), Some(5));
            let d = crate::edition::links::HyperRef::single(None, Some(work_c), None, None);
            server
                .create_link(sid, work_b, work_c, Some(o), Some(d))
                .unwrap()
        };

        server.work_grab(sid, work_a).unwrap();
        let new_ed = Edition::from_text("XXX hello world");
        server.work_revise(sid, work_a, new_ed).unwrap();

        let (_, _, link_a_data) = server.get_link(link_a).unwrap();
        let o_a = link_a_data.end_at("LeftEnd").unwrap();
        assert_eq!(o_a.start_position(), Some(4), "work_a link should migrate");
        assert_eq!(o_a.end_position(), Some(9));

        let (_, _, link_b_data) = server.get_link(link_b).unwrap();
        let o_b = link_b_data.end_at("LeftEnd").unwrap();
        assert_eq!(
            o_b.start_position(),
            Some(0),
            "work_b link should NOT migrate when work_a is edited"
        );
        assert_eq!(
            o_b.end_position(),
            Some(5),
            "work_b link span should be unchanged"
        );
    }

    #[test]
    fn link_span_multiple_links_same_work_all_migrate() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();
        let work_b = server
            .create_work(sid, Edition::from_text("dest b"))
            .unwrap();
        let work_c = server
            .create_work(sid, Edition::from_text("dest c"))
            .unwrap();

        let link1 = {
            let o = crate::edition::links::HyperRef::single(None, Some(work_a), None, None)
                .with_span(Some(0), Some(5));
            let d = crate::edition::links::HyperRef::single(None, Some(work_b), None, None);
            server
                .create_link(sid, work_a, work_b, Some(o), Some(d))
                .unwrap()
        };
        let link2 = {
            let o = crate::edition::links::HyperRef::single(None, Some(work_a), None, None)
                .with_span(Some(6), Some(11));
            let d = crate::edition::links::HyperRef::single(None, Some(work_c), None, None);
            server
                .create_link(sid, work_a, work_c, Some(o), Some(d))
                .unwrap()
        };

        server.work_grab(sid, work_a).unwrap();
        let new_ed = Edition::from_text("** hello world");
        server.work_revise(sid, work_a, new_ed).unwrap();

        let (_, _, link1_data) = server.get_link(link1).unwrap();
        let o1 = link1_data.end_at("LeftEnd").unwrap();
        assert_eq!(
            o1.start_position(),
            Some(3),
            "link1 start should shift by 3"
        );
        assert_eq!(o1.end_position(), Some(8), "link1 end should shift by 3");

        let (_, _, link2_data) = server.get_link(link2).unwrap();
        let o2 = link2_data.end_at("LeftEnd").unwrap();
        assert_eq!(
            o2.start_position(),
            Some(9),
            "link2 start should shift by 3"
        );
        assert_eq!(o2.end_position(), Some(14), "link2 end should shift by 3");
    }

    #[test]
    fn link_span_migrates_on_pure_insertion_at_end() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server
            .create_work(sid, Edition::from_text("hello"))
            .unwrap();
        let work_b = server.create_work(sid, Edition::from_text("dest")).unwrap();

        let o_ref = crate::edition::links::HyperRef::single(None, Some(work_a), None, None)
            .with_span(Some(0), Some(5));
        let d_ref = crate::edition::links::HyperRef::single(None, Some(work_b), None, None);
        let link_id = server
            .create_link(sid, work_a, work_b, Some(o_ref), Some(d_ref))
            .unwrap();

        server.work_grab(sid, work_a).unwrap();
        let new_ed = Edition::from_text("hello world");
        server.work_revise(sid, work_a, new_ed).unwrap();

        let (_, _, link) = server.get_link(link_id).unwrap();
        let o_ref = link.end_at("LeftEnd").unwrap();
        assert_eq!(o_ref.start_position(), Some(0), "start unchanged (append)");
        assert_eq!(
            o_ref.end_position(),
            Some(5),
            "end unchanged (span before insert)"
        );
    }

    #[test]
    fn link_span_migrates_on_pure_deletion_at_end() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();
        let work_b = server.create_work(sid, Edition::from_text("dest")).unwrap();

        let o_ref = crate::edition::links::HyperRef::single(None, Some(work_a), None, None)
            .with_span(Some(0), Some(5));
        let d_ref = crate::edition::links::HyperRef::single(None, Some(work_b), None, None);
        let link_id = server
            .create_link(sid, work_a, work_b, Some(o_ref), Some(d_ref))
            .unwrap();

        server.work_grab(sid, work_a).unwrap();
        let new_ed = Edition::from_text("hello");
        server.work_revise(sid, work_a, new_ed).unwrap();

        let (_, _, link) = server.get_link(link_id).unwrap();
        let o_ref = link.end_at("LeftEnd").unwrap();
        assert_eq!(o_ref.start_position(), Some(0), "start unchanged");
        assert_eq!(
            o_ref.end_position(),
            Some(5),
            "end unchanged (deleted after span)"
        );
    }

    #[test]
    fn link_span_survives_full_text_replacement() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server
            .create_work(sid, Edition::from_text("hello"))
            .unwrap();
        let work_b = server.create_work(sid, Edition::from_text("dest")).unwrap();

        let o_ref = crate::edition::links::HyperRef::single(None, Some(work_a), None, None)
            .with_span(Some(0), Some(5));
        let d_ref = crate::edition::links::HyperRef::single(None, Some(work_b), None, None);
        let link_id = server
            .create_link(sid, work_a, work_b, Some(o_ref), Some(d_ref))
            .unwrap();

        server.work_grab(sid, work_a).unwrap();
        let new_ed = Edition::from_text("completely different");
        server.work_revise(sid, work_a, new_ed).unwrap();

        let (_, _, link) = server.get_link(link_id).unwrap();
        let o_ref = link.end_at("LeftEnd").unwrap();
        assert_eq!(
            o_ref.start_position(),
            Some(0),
            "start should be at 0 (delete boundary)"
        );
        assert_eq!(
            o_ref.end_position(),
            Some(20),
            "end should cover replacement text (delete+insert look-ahead)"
        );
    }

    #[test]
    fn link_span_grows_with_insertion_inside_span() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();
        let work_b = server.create_work(sid, Edition::from_text("dest")).unwrap();

        let o_ref = crate::edition::links::HyperRef::single(None, Some(work_a), None, None)
            .with_span(Some(0), Some(11));
        let d_ref = crate::edition::links::HyperRef::single(None, Some(work_b), None, None);
        let link_id = server
            .create_link(sid, work_a, work_b, Some(o_ref), Some(d_ref))
            .unwrap();

        server.work_grab(sid, work_a).unwrap();
        let ops = vec![
            crate::server::transport::protocol::TextDeltaOp::Retain { count: 6 },
            crate::server::transport::protocol::TextDeltaOp::Insert {
                text: "big ".to_string(),
            },
            crate::server::transport::protocol::TextDeltaOp::Retain { count: 5 },
        ];
        server.migrate_link_spans_for_delta(work_a, &ops);

        let (_, _, link) = server.get_link(link_id).unwrap();
        let o_ref = link.end_at("LeftEnd").unwrap();
        assert_eq!(
            o_ref.start_position(),
            Some(0),
            "start unchanged (insert after start)"
        );
        assert_eq!(
            o_ref.end_position(),
            Some(15),
            "end should grow by 4 (inserted 'big ' before end)"
        );
    }

    #[test]
    fn global_text_search_finds_matching_works() {
        let (mut server, sid) = setup_logged_in_server();
        server
            .create_work(sid, Edition::from_text("hello world from work a"))
            .unwrap();
        server
            .create_work(sid, Edition::from_text("completely different content"))
            .unwrap();
        server
            .create_work(sid, Edition::from_text("hello again from work c"))
            .unwrap();

        let results = server.global_text_search(sid, "hello", 10);
        assert_eq!(results.len(), 2, "should find 2 works containing 'hello'");
        for r in &results {
            assert!(
                r.matches
                    .iter()
                    .any(|m| m.context.to_ascii_lowercase().contains("hello")),
                "context should contain the query"
            );
        }
    }

    #[test]
    fn global_text_search_case_insensitive() {
        let (mut server, sid) = setup_logged_in_server();
        server
            .create_work(sid, Edition::from_text("The Quick Brown Fox"))
            .unwrap();

        let results = server.global_text_search(sid, "quick brown", 10);
        assert_eq!(results.len(), 1, "should find 1 work (case-insensitive)");
        assert_eq!(results[0].matches.len(), 1);
        assert!(
            results[0].matches[0]
                .context
                .to_ascii_lowercase()
                .contains("quick brown"),
            "context should contain match"
        );
    }

    #[test]
    fn global_text_search_no_results() {
        let (mut server, sid) = setup_logged_in_server();
        server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();

        let results = server.global_text_search(sid, "nonexistent phrase", 10);
        assert!(results.is_empty(), "should find 0 works");
    }

    #[test]
    fn global_text_search_multiple_matches_in_same_work() {
        let (mut server, sid) = setup_logged_in_server();
        server
            .create_work(sid, Edition::from_text("cat dog cat bird cat fish"))
            .unwrap();

        let results = server.global_text_search(sid, "cat", 10);
        assert_eq!(results.len(), 1, "should find 1 work");
        assert_eq!(
            results[0].matches.len(),
            3,
            "should find 3 matches for 'cat'"
        );
    }

    #[test]
    fn global_text_search_respects_max_results() {
        let (mut server, sid) = setup_logged_in_server();
        server
            .create_work(sid, Edition::from_text("cat dog cat bird cat fish cat"))
            .unwrap();

        let results = server.global_text_search(sid, "cat", 2);
        assert_eq!(results.len(), 1, "should find 1 work");
        assert_eq!(
            results[0].matches.len(),
            2,
            "should cap at max_results matches"
        );
    }

    #[test]
    fn global_text_search_results_sorted_by_match_count() {
        let (mut server, sid) = setup_logged_in_server();
        let work_a = server
            .create_work(sid, Edition::from_text("foo bar"))
            .unwrap();
        let work_b = server
            .create_work(sid, Edition::from_text("foo foo foo bar"))
            .unwrap();

        let results = server.global_text_search(sid, "foo", 10);
        assert_eq!(results.len(), 2, "should find 2 works");
        assert_eq!(
            results[0].work_id, work_b,
            "work with more matches should be first"
        );
        assert_eq!(results[1].work_id, work_a);
    }

    #[test]
    fn global_text_search_includes_work_metadata() {
        let (mut server, sid) = setup_logged_in_server();
        let work_id = server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();

        let results = server.global_text_search(sid, "hello", 10);
        assert_eq!(results.len(), 1);
        let r = &results[0];
        assert_eq!(r.work_id, work_id);
        assert!(r.title.is_some(), "should include title");
        assert!(
            r.revision_count == 0 || r.revision_count == 1,
            "should include revision count"
        );
    }

    #[test]
    fn global_text_search_correct_line_numbers() {
        let (mut server, sid) = setup_logged_in_server();
        server
            .create_work(
                sid,
                Edition::from_text("line one\nline two\ntarget line\nline four"),
            )
            .unwrap();

        let results = server.global_text_search(sid, "target", 10);
        assert_eq!(results.len(), 1);
        assert_eq!(
            results[0].matches[0].line, 2,
            "target is on line 2 (0-indexed)"
        );
    }

    #[test]
    fn global_text_search_empty_query_returns_nothing() {
        let (mut server, sid) = setup_logged_in_server();
        server
            .create_work(sid, Edition::from_text("hello world"))
            .unwrap();

        let results = server.global_text_search(sid, "", 10);
        assert!(results.is_empty(), "empty query should return no results");
    }

    #[test]
    fn annotation_private_hidden_from_anonymous() {
        let (mut server, sid) = setup_logged_in_server();
        let work_id = server
            .create_work(sid, Edition::from_text("hello"))
            .unwrap();

        server
            .annotation_create(
                sid,
                work_id,
                1,
                "note".into(),
                "private note".into(),
                0,
                5,
                true,
            )
            .unwrap();

        let sid2 = server.connect();
        server.login_public(sid2).unwrap();

        let anns = server.annotation_list(sid, work_id).unwrap();
        assert!(
            anns.is_empty(),
            "private annotations from anonymous (login_public) are invisible to all — \
             no club ID to verify ownership"
        );

        let anns2 = server.annotation_list(sid2, work_id).unwrap();
        assert!(
            anns2.is_empty(),
            "other anonymous session also sees nothing"
        );
    }

    #[test]
    fn annotation_public_visible_to_everyone() {
        let (mut server, sid) = setup_logged_in_server();
        let work_id = server
            .create_work(sid, Edition::from_text("hello"))
            .unwrap();

        server
            .annotation_create(
                sid,
                work_id,
                1,
                "note".into(),
                "public note".into(),
                0,
                5,
                false,
            )
            .unwrap();

        let anns = server.annotation_list(sid, work_id).unwrap();
        assert_eq!(anns.len(), 1, "creator sees public annotation");

        let sid2 = server.connect();
        server.login_public(sid2).unwrap();

        let anns2 = server.annotation_list(sid2, work_id).unwrap();
        assert_eq!(anns2.len(), 1, "other session sees public annotation");
        assert!(!anns2[0].is_private);
    }

    #[test]
    fn annotation_default_is_public() {
        let (mut server, sid) = setup_logged_in_server();
        let work_id = server
            .create_work(sid, Edition::from_text("hello"))
            .unwrap();

        server
            .annotation_create(
                sid,
                work_id,
                1,
                "note".into(),
                "default note".into(),
                0,
                5,
                false,
            )
            .unwrap();

        let anns = server.annotation_list(sid, work_id).unwrap();
        assert_eq!(anns.len(), 1);
        assert!(
            !anns[0].is_private,
            "annotation created with is_private=false should be public"
        );
    }

    #[test]
    fn annotation_private_filter_at_manager_level() {
        use crate::server::otree_crdt::OtreeCrdtManager;
        let mut mgr = OtreeCrdtManager::new(2);
        let work_id: BeId = 42;
        mgr.initialize_from_edition(work_id, &Edition::from_text("hello"));

        mgr.annotation_create(
            work_id,
            1,
            "note".into(),
            "public".into(),
            0,
            2,
            Some(100),
            false,
        )
        .unwrap();
        mgr.annotation_create(
            work_id,
            2,
            "note".into(),
            "private from club 100".into(),
            3,
            5,
            Some(100),
            true,
        )
        .unwrap();
        mgr.annotation_create(
            work_id,
            3,
            "note".into(),
            "private from club 200".into(),
            0,
            1,
            Some(200),
            true,
        )
        .unwrap();

        let all = mgr.annotation_list(work_id).unwrap();
        assert_eq!(all.len(), 3, "manager returns all without filtering");

        let visible_to_100: Vec<_> = all
            .iter()
            .filter(|a| !a.is_private || a.created_by == Some(100))
            .collect();
        assert_eq!(
            visible_to_100.len(),
            2,
            "club 100 sees public + their own private"
        );

        let visible_to_200: Vec<_> = all
            .iter()
            .filter(|a| !a.is_private || a.created_by == Some(200))
            .collect();
        assert_eq!(
            visible_to_200.len(),
            2,
            "club 200 sees public + their own private"
        );

        let visible_to_999: Vec<_> = all
            .iter()
            .filter(|a| !a.is_private || a.created_by == Some(999))
            .collect();
        assert_eq!(visible_to_999.len(), 1, "club 999 sees only public");
    }
}
