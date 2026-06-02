use std::collections::{HashMap, HashSet};

use super::admin::{AdminState, IdGrant, SessionInfo};
use super::club::Club;
use super::crdt_manager::CrdtManager;
use super::detector::{Detector, DetectorList, Event};
use super::error::ServerError;
use super::keymaster::KeyMaster;
use super::lock::{BooLockSmith, Lock, LockCredential, LockSmith};
use super::session::{Session, SessionId};
use crate::edition::backfollow::BackfollowEngine;
use crate::edition::blob_store::{BlobMeta, BlobStore, MemoryBackend};
use crate::edition::links::{HyperLink, HyperRef};
use crate::edition::props::BertProp;
use crate::edition::transclusion::{TransclusionQuery, WorkQuery};
use crate::edition::{
    hash_content, u64_from_hash, BeId, BeRangeElement, BeStorage, ContentAddressIndex, Edition,
    GrandMap, InMemoryBeStorage, RangeElement, Work, XnRegion,
};
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

struct WorkState {
    work: Work,
    chunk_ref: Option<crate::persist::edition_chunks::WorkChunkRef>,
    grabber: Option<SessionId>,
    grabbed_at: Option<u64>,
    grab_waiters: Vec<GrabWaiter>,
    last_revision_author: Option<BeId>,
    status_detectors: DetectorList,
    revision_detectors: DetectorList,
    cached_title: String,
    is_source: bool,
    source_author_id: Option<BeId>,
    source_edition_info: Option<String>,
    imported_by: Option<BeId>,
    content_start_line: Option<u64>,
    content_end_line: Option<u64>,
}

impl WorkState {
    pub fn title(&self) -> &str {
        &self.cached_title
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
    backfollow: BackfollowEngine,
    content_address: ContentAddressIndex,
    blob_store: BlobStore,
    checkpoint_path: Option<std::path::PathBuf>,
    data_dir: Option<std::path::PathBuf>,
    chunk_store: Option<crate::persist::chunk_store::ChunkStore>,
    manifest_sequence: u64,
    recorder_system: crate::edition::RecorderSystem,
    pending_content_notifications: Vec<ContentNotification>,
    start_time: u64,
    server_keypair: crate::crypto::keys::ServerKeyPair,
    key_history: crate::crypto::keys::KeyHistory,
    federation: crate::server::federation::FederationState,
    reconcile_store: crate::server::federation::ReconcileStore,
    reconcile_counter: u64,
    last_checkpoint_time: u64,
    pub(crate) crdt_manager: CrdtManager,
    pub(crate) otree_crdt: super::otree_crdt::OtreeCrdtManager,
    pub use_otree_crdt: bool,
    pub(crate) personal_club_count: usize,
    pub(crate) max_personal_clubs: usize,
    pub(crate) login_attempts: HashMap<BeId, crate::server::identity::ClubAttemptTracker>,
    attribution_log: Option<crate::server::transport::attribution_log::AttributionLog>,
    pub(crate) historical_authors: crate::server::historical_author::HistoricalAuthorRegistry,
    pub(crate) source_patterns: Vec<crate::server::source_matcher::SourcePattern>,
    annotations: HashMap<BeId, HashMap<u64, AnnotationState>>,
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

#[derive(Debug, Clone)]
struct AnnotationState {
    kind: String,
    payload: String,
    attached_nodes: Vec<u64>,
    attached_spans: Vec<u64>,
    created_by: Option<BeId>,
}

impl Default for Server {
    fn default() -> Self {
        Self::new()
    }
}

impl Server {
    fn extract_title(edition: &Edition) -> String {
        let text: String = edition
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.as_text().unwrap_or(""))
            .collect();
        text.split_whitespace()
            .collect::<Vec<_>>()
            .join(" ")
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
            backfollow: BackfollowEngine::new(),
            content_address: ContentAddressIndex::new(1_000_000),
            blob_store: BlobStore::in_memory(),
            checkpoint_path: None,
            data_dir: None,
            chunk_store: None,
            manifest_sequence: 0,
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
            crdt_manager: CrdtManager::new(3),
            otree_crdt: super::otree_crdt::OtreeCrdtManager::new(3),
            use_otree_crdt: false,
            personal_club_count: 0,
            max_personal_clubs: 10_000,
            login_attempts: HashMap::new(),
            attribution_log: None,
            historical_authors: crate::server::historical_author::HistoricalAuthorRegistry::new(),
            source_patterns: crate::server::source_matcher::builtin_patterns(),

            // TODO: Annotations use a simple HashMap for pragmatic first implementation.
            // Migrate to Ent/AssertionStore (src/ent/content.rs) for proper versioning,
            // transclusion survival, and materialize_annotation_indexed support.
            annotations: HashMap::new(),
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

    // === Session management ===

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

    pub fn disconnect(&mut self, session_id: SessionId) -> Result<(), ServerError> {
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

        let crdt_works: Vec<BeId> = if self.use_otree_crdt {
            self.otree_crdt.works_for_session(session_id)
        } else {
            self.crdt_manager.works_for_session(session_id)
        };

        for work_id in crdt_works {
            let _ = self.crdt_remove_awareness(session_id, work_id);
            if self.use_otree_crdt {
                self.otree_crdt.close_session(work_id, session_id);
            } else {
                self.crdt_manager.close_session(work_id, session_id);
            }
        }

        Ok(())
    }

    pub fn session(&self, session_id: SessionId) -> Result<&Session, ServerError> {
        self.sessions
            .get(&session_id)
            .ok_or(ServerError::SessionNotFound(session_id))
    }

    pub fn session_count(&self) -> usize {
        self.sessions.values().filter(|s| s.is_connected()).count()
    }

    pub fn display_name_for_session(&self, session_id: SessionId) -> String {
        let (name, _, _) = self.identity_for_session(session_id);
        name
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

        if self.use_otree_crdt {
            let author_sessions = self
                .otree_crdt
                .get_author_sessions(work_be_id)
                .map_err(|e| ServerError::Internal(e.to_string()))?;

            let mut author_signing_keys: std::collections::HashMap<
                BeId,
                ed25519_dalek::SigningKey,
            > = std::collections::HashMap::new();
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
        } else {
            let author_sessions = self
                .crdt_manager
                .get_author_sessions(work_be_id)
                .map_err(|e| ServerError::Internal(e.to_string()))?;

            let mut author_signing_keys: std::collections::HashMap<
                BeId,
                ed25519_dalek::SigningKey,
            > = std::collections::HashMap::new();
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
                        .crdt_manager
                        .get_club_signing_key(work_be_id, author_id.club_be_id)
                    {
                        author_signing_keys.insert(author_id.club_be_id, sk);
                    }
                }
            }

            match signing_key {
                Some(sk) => self
                    .crdt_manager
                    .materialize_edition_with_provenance(
                        work_be_id,
                        &sk,
                        &server_id_bytes,
                        timestamp,
                        &author_signing_keys,
                    )
                    .map_err(|e| ServerError::Internal(e.to_string())),
                None => self
                    .crdt_manager
                    .materialize_edition(work_be_id)
                    .map_err(|e| ServerError::Internal(e.to_string())),
            }
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

        let ws = WorkState {
            work,
            chunk_ref: None,
            grabber: None,
            grabbed_at: None,
            grab_waiters: Vec::new(),
            last_revision_author: None,
            status_detectors: DetectorList::new(),
            revision_detectors: DetectorList::new(),
            cached_title: title,
            is_source: false,
            source_author_id: None,
            source_edition_info: None,
            imported_by: None,
            content_start_line: None,
            content_end_line: None,
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
        if edition.span_provenance.is_empty() {
            if let Some(sp) = self.build_edition_provenance(session_id, &edition) {
                edition.span_provenance = sp;
            }
        }

        if let Some(ref mut log) = self.attribution_log {
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
        ws.last_revision_author = author_club;
        ws.chunk_ref = None;
        ws.work.revise(edition);
        ws.cached_title = Self::extract_title(ws.work.current_edition());
        let revision = ws.work.revision_count();

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

        let author_club = self
            .sessions
            .get(&session_id)
            .and_then(|s| s.initial_login());

        let revision = self.revise_work(work_be_id, session_id, new_edition, author_club)?;
        Ok(revision)
    }

    pub fn work_grab(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
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
        self.ensure_can_edit(session_id, work_be_id)?;
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        if ws.work.read_club().is_none() {
            return Err(ServerError::ReadClubIrrevocablyRemoved(work_be_id));
        }
        ws.work.set_read_club(club_id);
        ws.chunk_ref = None;
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
        ws.chunk_ref = None;
        Ok(())
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
        ws.chunk_ref = None;
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
        ws.chunk_ref = None;
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
        tracing::debug!(
            "[attribution_query] work={:04x} entries={} span_prov={} entry_details={}",
            work_be_id,
            all_entries.len(),
            edition.span_provenance.len(),
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
            });
        }
        Ok(spans)
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
        match &self.attribution_log {
            Some(log) => {
                let entry_count = log.sequence();
                let chain_valid = self.verify_attribution_log_chain();
                super::transport::protocol::ResponseValue::AttributionLogStatusResult {
                    entry_count,
                    chain_valid,
                    last_sequence: entry_count,
                    has_log: true,
                }
            }
            None => super::transport::protocol::ResponseValue::AttributionLogStatusResult {
                entry_count: 0,
                chain_valid: false,
                last_sequence: 0,
                has_log: false,
            },
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
            grabber: None,
            grabbed_at: None,
            grab_waiters: Vec::new(),
            last_revision_author: None,
            status_detectors: DetectorList::new(),
            revision_detectors: DetectorList::new(),
            cached_title: final_title.clone(),
            is_source: true,
            source_author_id: Some(author_id),
            source_edition_info: Some(edition_info),
            imported_by: importer,
            content_start_line: Some(content_start),
            content_end_line: Some(content_end),
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
        ws.chunk_ref = None;
        Ok(())
    }

    pub fn work_publish(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
        self.ensure_owner(session_id, work_be_id)?;
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        if ws.work.read_club().is_none() {
            return Err(ServerError::ReadClubIrrevocablyRemoved(work_be_id));
        }
        ws.work.set_read_club(Some(self.system_clubs.public_club));
        ws.chunk_ref = None;
        self.auto_checkpoint();
        Ok(())
    }

    pub fn work_unpublish(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
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
        ws.chunk_ref = None;
        self.auto_checkpoint();
        Ok(())
    }

    pub fn work_irrevocably_unpublish(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
        self.ensure_owner(session_id, work_be_id)?;
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        ws.work.set_read_club(None);
        ws.chunk_ref = None;
        self.auto_checkpoint();
        Ok(())
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
        if self.is_source_work(work_be_id) {
            self.ensure_can_read(session_id, work_be_id)?;
        } else {
            self.ensure_can_edit(session_id, work_be_id)?;
        }

        if self.crdt_is_active(work_be_id) {
            let needs = self.crdt_needs_materialization(work_be_id);
            if needs {
                let edition = if self.use_otree_crdt {
                    self.otree_crdt
                        .materialize_edition(work_be_id)
                        .map_err(|e| ServerError::Internal(e.to_string()))?
                } else {
                    self.crdt_manager
                        .materialize_edition(work_be_id)
                        .map_err(|e| ServerError::Internal(e.to_string()))?
                };

                let author_club = self.sessions.iter().find_map(|(sid, _)| {
                    if self.crdt_is_active_subscriber(work_be_id, *sid) {
                        self.sessions.get(sid).and_then(|s| s.initial_login())
                    } else {
                        None
                    }
                });

                self.revise_work(work_be_id, session_id, edition, author_club)?;
            }
        }

        if self.use_otree_crdt {
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
        } else {
            let initial_text = if !self.crdt_manager.is_active(work_be_id) {
                let edition = self.work_edition(work_be_id)?;
                Some(
                    edition
                        .all_entries()
                        .iter()
                        .map(|(_, c)| c.element.as_text().unwrap_or(""))
                        .collect::<String>(),
                )
            } else {
                None
            };

            let result = self.crdt_manager.open_sync_session(
                work_be_id,
                session_id,
                initial_text.as_deref(),
            );

            self.register_crdt_author(session_id, work_be_id)?;

            Ok(result)
        }
    }

    fn crdt_is_active_subscriber(&self, work_be_id: BeId, session_id: SessionId) -> bool {
        if self.use_otree_crdt {
            self.otree_crdt.is_subscriber(work_be_id, session_id)
        } else {
            self.crdt_manager.is_subscriber(work_be_id, session_id)
        }
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

                if self.use_otree_crdt {
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
                } else {
                    let author = super::crdt_manager::AuthorIdentity {
                        public_key,
                        display_name,
                        club_be_id: login_club,
                    };
                    if let Err(e) = self
                        .crdt_manager
                        .register_author(work_be_id, session_id, author)
                    {
                        tracing::warn!(target: "xudanu::security", work_id = work_be_id, session_id = session_id.as_u64(), error = %e, event = "SECURITY:author_register_failed", "failed to register CRDT author");
                    }
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
            let edition = if self.use_otree_crdt {
                self.otree_crdt
                    .materialize_edition(work_be_id)
                    .map_err(|e| ServerError::Internal(e.to_string()))?
            } else {
                self.crdt_manager
                    .materialize_edition(work_be_id)
                    .map_err(|e| ServerError::Internal(e.to_string()))?
            };

            let author_club = self
                .sessions
                .get(&session_id)
                .and_then(|s| s.initial_login());

            self.revise_work(work_be_id, session_id, edition, author_club)?;
        }

        if self.use_otree_crdt {
            self.otree_crdt
                .close_sync_session(work_be_id, session_id)
                .map_err(|e| ServerError::Internal(e.to_string()))
        } else {
            self.crdt_manager
                .close_sync_session(work_be_id, session_id)
                .map_err(|e| ServerError::Internal(e.to_string()))
        }
    }

    pub fn crdt_apply_text_delta(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
        ops: &[crate::server::transport::protocol::TextDeltaOp],
    ) -> Result<(super::crdt_manager::ApplyUpdateResult, Option<u64>), ServerError> {
        self.ensure_session(session_id)?;
        self.ensure_can_edit(session_id, work_be_id)?;

        if self.use_otree_crdt {
            let result = self
                .otree_crdt
                .apply_text_delta(work_be_id, session_id, ops)
                .map_err(|e| ServerError::Internal(e.to_string()))?;

            let relay_to: Vec<(SessionId, super::crdt_manager::SyncSessionId)> = result
                .relay_to
                .into_iter()
                .map(|(sid, osid)| (sid, super::crdt_manager::SyncSessionId::from(osid.as_u64())))
                .collect();

            let revision = if self.crdt_needs_materialization(work_be_id) {
                let ed = self.materialize_with_provenance(work_be_id, session_id)?;
                let author_club = self
                    .sessions
                    .get(&session_id)
                    .and_then(|s| s.initial_login());
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
        } else {
            let result = self
                .crdt_manager
                .apply_text_delta(work_be_id, session_id, ops)
                .map_err(|e| ServerError::Internal(e.to_string()))?;

            let revision = if self.crdt_needs_materialization(work_be_id) {
                let ed = self.materialize_with_provenance(work_be_id, session_id)?;
                let author_club = self
                    .sessions
                    .get(&session_id)
                    .and_then(|s| s.initial_login());
                Some(self.revise_work(work_be_id, session_id, ed, author_club)?)
            } else {
                None
            };

            Ok((result, revision))
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

        if self.use_otree_crdt {
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
        } else {
            let result = self
                .crdt_manager
                .apply_update(work_be_id, session_id, &update_bytes)
                .map_err(|e| ServerError::Internal(e.to_string()))?;
            self.try_materialize(work_be_id, session_id)?;
            Ok(result)
        }
    }

    pub fn crdt_get_diff(
        &self,
        work_be_id: BeId,
        _state_vector: Vec<u8>,
    ) -> Result<Vec<u8>, ServerError> {
        if self.use_otree_crdt {
            self.otree_crdt
                .current_text(work_be_id)
                .map(|t| t.into_bytes())
                .map_err(|e| ServerError::Internal(e.to_string()))
        } else {
            self.crdt_manager
                .get_diff_since(work_be_id, &_state_vector)
                .map_err(|e| ServerError::Internal(e.to_string()))
        }
    }

    pub fn crdt_get_full_state(&self, work_be_id: BeId) -> Result<Vec<u8>, ServerError> {
        if self.use_otree_crdt {
            self.otree_crdt
                .current_text(work_be_id)
                .map(|t| t.into_bytes())
                .map_err(|e| ServerError::Internal(e.to_string()))
        } else {
            self.crdt_manager
                .get_full_state(work_be_id)
                .map_err(|e| ServerError::Internal(e.to_string()))
        }
    }

    pub fn crdt_subscriber_count(&self, work_be_id: BeId) -> usize {
        if self.use_otree_crdt {
            self.otree_crdt.subscriber_count(work_be_id)
        } else {
            self.crdt_manager.subscriber_count(work_be_id)
        }
    }

    pub fn crdt_is_active(&self, work_be_id: BeId) -> bool {
        if self.use_otree_crdt {
            self.otree_crdt.is_active(work_be_id)
        } else {
            self.crdt_manager.is_active(work_be_id)
        }
    }

    pub fn crdt_needs_materialization(&self, work_be_id: BeId) -> bool {
        if self.use_otree_crdt {
            self.otree_crdt
                .needs_materialization(work_be_id)
                .unwrap_or(false)
        } else {
            self.crdt_manager
                .needs_materialization(work_be_id)
                .unwrap_or(false)
        }
    }

    pub fn set_work_title(&mut self, work_be_id: BeId, title: String) {
        if let Some(ws) = self.works.get_mut(&work_be_id) {
            ws.cached_title = title;
        }
    }

    pub fn crdt_current_text(&self, work_be_id: BeId) -> Result<String, ServerError> {
        if self.use_otree_crdt {
            self.otree_crdt
                .current_text(work_be_id)
                .map_err(|e| ServerError::Internal(e.to_string()))
        } else {
            self.crdt_manager
                .current_text(work_be_id)
                .map_err(|e| ServerError::Internal(e.to_string()))
        }
    }

    pub fn crdt_text_range(
        &self,
        work_be_id: BeId,
        start_char: usize,
        end_char: usize,
    ) -> Result<super::otree_crdt::TextRangeResult, ServerError> {
        if self.use_otree_crdt {
            self.otree_crdt
                .text_range(work_be_id, start_char, end_char)
                .map_err(|e| ServerError::Internal(e.to_string()))
        } else {
            let text = self
                .crdt_manager
                .current_text(work_be_id)
                .map_err(|e| ServerError::Internal(e.to_string()))?;
            let total = text.chars().count();
            let start = start_char.min(total);
            let end = end_char.min(total);
            let range_text: String = text.chars().skip(start).take(end - start).collect();
            Ok(super::otree_crdt::TextRangeResult {
                text: range_text,
                total_chars: total,
                start_char: start,
                end_char: end,
            })
        }
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
        let elapsed = if self.use_otree_crdt {
            self.otree_crdt
                .debounce_elapsed(work_be_id)
                .map_err(|e| ServerError::Internal(e.to_string()))?
        } else {
            self.crdt_manager
                .debounce_elapsed(work_be_id)
                .map_err(|e| ServerError::Internal(e.to_string()))?
        };

        if should && elapsed {
            let edition = self.materialize_with_provenance(work_be_id, session_id)?;

            let author_club = self
                .sessions
                .get(&session_id)
                .and_then(|s| s.initial_login());

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

        let edition = self.materialize_with_provenance(work_be_id, session_id)?;

        let author_club = self
            .sessions
            .get(&session_id)
            .and_then(|s| s.initial_login());

        let revision = self.revise_work(work_be_id, session_id, edition, author_club)?;
        Ok(revision)
    }

    pub fn crdt_materialize_any_session(&mut self, work_be_id: BeId) -> Result<u64, ServerError> {
        if !self.crdt_is_active(work_be_id) {
            return Ok(0);
        }

        let sessions = if self.use_otree_crdt {
            self.otree_crdt
                .get_subscribed_sessions(work_be_id)
                .map_err(|e| ServerError::Internal(e.to_string()))?
        } else {
            self.crdt_manager
                .get_subscribed_sessions(work_be_id)
                .map_err(|e| ServerError::Internal(e.to_string()))?
        };

        let session_id = sessions
            .into_iter()
            .find(|sid| {
                self.sessions
                    .get(sid)
                    .and_then(|s| s.club_signing_key())
                    .is_some()
            })
            .or_else(|| {
                if self.use_otree_crdt {
                    self.otree_crdt
                        .get_subscribed_sessions(work_be_id)
                        .ok()?
                        .into_iter()
                        .next()
                } else {
                    self.crdt_manager
                        .get_subscribed_sessions(work_be_id)
                        .ok()?
                        .into_iter()
                        .next()
                }
            })
            .ok_or(ServerError::Internal("no subscribed session".into()))?;

        let edition = self.materialize_with_provenance(work_be_id, session_id)?;

        let author_club = self
            .sessions
            .get(&session_id)
            .and_then(|s| s.initial_login());

        let revision = self.revise_work(work_be_id, session_id, edition, author_club)?;
        Ok(revision)
    }

    pub fn materialize_all_pending(&mut self) -> usize {
        let work_ids: Vec<BeId> = if self.use_otree_crdt {
            self.otree_crdt.pending_work_ids()
        } else {
            self.crdt_manager.pending_work_ids()
        };

        let mut saved = 0;
        for work_id in work_ids {
            if let Ok(rev) = self.crdt_materialize_any_session(work_id) {
                if rev > 0 {
                    saved += 1;
                    tracing::debug!("auto-save: materialized work {} rev {}", work_id, rev);
                }
            }
        }
        saved
    }

    pub fn crdt_update_awareness(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
        state: super::crdt_manager::AwarenessState,
    ) -> Result<super::crdt_manager::AwarenessRelayResult, ServerError> {
        self.ensure_session(session_id)?;
        if self.use_otree_crdt {
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
        } else {
            self.crdt_manager
                .update_awareness(work_be_id, session_id, state)
                .map_err(|e| ServerError::Internal(e.to_string()))
        }
    }

    pub fn crdt_remove_awareness(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<super::crdt_manager::AwarenessRelayResult, ServerError> {
        if self.use_otree_crdt {
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
        } else {
            self.crdt_manager
                .remove_awareness(work_be_id, session_id)
                .map_err(|e| ServerError::Internal(e.to_string()))
        }
    }

    pub fn crdt_get_awareness(
        &self,
        work_be_id: BeId,
    ) -> Result<Vec<super::crdt_manager::AwarenessState>, ServerError> {
        if self.use_otree_crdt {
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
                    selection: s.selection.as_ref().map(|sel| {
                        super::crdt_manager::SelectionRange {
                            start: sel.start,
                            end: sel.end,
                        }
                    }),
                    is_typing: s.is_typing,
                })
                .collect())
        } else {
            let states = self
                .crdt_manager
                .get_awareness(work_be_id)
                .map_err(|e| ServerError::Internal(e.to_string()))?;
            Ok(states.into_iter().cloned().collect())
        }
    }

    pub fn crdt_register_author(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
        author: super::crdt_manager::AuthorIdentity,
    ) -> Result<(), ServerError> {
        self.ensure_session(session_id)?;
        if self.use_otree_crdt {
            let otree_author = super::otree_crdt::OtreeAuthorIdentity {
                public_key: author.public_key,
                display_name: author.display_name,
                club_be_id: author.club_be_id,
            };
            self.otree_crdt
                .register_author(work_be_id, session_id, otree_author)
                .map_err(|e| ServerError::Internal(e.to_string()))
        } else {
            self.crdt_manager
                .register_author(work_be_id, session_id, author)
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

        if self.use_otree_crdt {
            let author = super::otree_crdt::OtreeAuthorIdentity {
                public_key,
                display_name,
                club_be_id: login_club,
            };
            self.otree_crdt
                .register_author(work_be_id, session_id, author)
                .map_err(|e| ServerError::Internal(e.to_string()))?;
        } else {
            let author = super::crdt_manager::AuthorIdentity {
                public_key,
                display_name,
                club_be_id: login_club,
            };
            self.crdt_manager
                .register_author(work_be_id, session_id, author)
                .map_err(|e| ServerError::Internal(e.to_string()))?;
        }

        if let Some(sk) = self
            .sessions
            .get(&session_id)
            .and_then(|s| s.club_signing_key().cloned())
        {
            if self.use_otree_crdt {
                self.otree_crdt
                    .store_club_signing_key(work_be_id, login_club, sk);
            } else {
                self.crdt_manager
                    .store_club_signing_key(work_be_id, login_club, sk);
            }
        }

        Ok(())
    }

    pub fn crdt_sign_update(&self, update_bytes: &[u8]) -> super::crdt_manager::SignedUpdate {
        if self.use_otree_crdt {
            let text = String::from_utf8_lossy(update_bytes);
            let signed = self
                .otree_crdt
                .sign_update(&text, &self.server_keypair.signing_key);
            super::crdt_manager::SignedUpdate {
                update_bytes: signed.update_text.into_bytes(),
                signature: signed.signature,
                signer_public_key: signed.signer_public_key,
            }
        } else {
            self.crdt_manager
                .sign_update(update_bytes, &self.server_keypair.signing_key)
        }
    }

    pub fn crdt_extract_signed_update_for_federation(
        &mut self,
        work_be_id: BeId,
    ) -> Result<super::crdt_manager::SignedUpdate, ServerError> {
        if self.use_otree_crdt {
            let signed = self
                .otree_crdt
                .extract_signed_update_for_federation(work_be_id, &self.server_keypair.signing_key)
                .map_err(|e| ServerError::Internal(e.to_string()))?;
            Ok(super::crdt_manager::SignedUpdate {
                update_bytes: signed.update_text.into_bytes(),
                signature: signed.signature,
                signer_public_key: signed.signer_public_key,
            })
        } else {
            self.crdt_manager
                .extract_signed_update_for_federation(work_be_id, &self.server_keypair.signing_key)
                .map_err(|e| ServerError::Internal(e.to_string()))
        }
    }

    pub fn crdt_apply_signed_federation_update(
        &mut self,
        work_be_id: BeId,
        signed: &super::crdt_manager::SignedUpdate,
        initial_text: Option<&str>,
    ) -> Result<super::crdt_manager::ApplyUpdateResult, ServerError> {
        if self.use_otree_crdt {
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
        } else {
            let mut known_keys = std::collections::HashMap::new();
            let server_vk = self.server_keypair.signing_key.verifying_key();
            known_keys.insert(server_vk.to_bytes(), server_vk);

            self.crdt_manager
                .apply_signed_federation_update(work_be_id, signed, &known_keys, initial_text)
                .map_err(|e| ServerError::Internal(e.to_string()))
        }
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
        let edition_elem = RangeElement::edition(be_id);
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
        self.chunk_store = Some(chunk_store);
        self.data_dir = Some(data_dir.to_path_buf());

        self.restore_keypair_from_dir(data_dir, passphrase)?;
        self.restore_blob_store_from_dir(data_dir)?;

        self.checkpoint_path = Some(manifest_path);
        self.attribution_log =
            crate::server::transport::attribution_log::AttributionLog::open(data_dir).ok();
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
            match crate::persist::manifest::read_manifest_with_fallback(&manifest_path, 3) {
                Ok(m) => m,
                Err(e) => {
                    return Err(std::io::Error::new(
                        std::io::ErrorKind::InvalidData,
                        format!(
                            "manifest.json and all backups are corrupt: {}. \
                             Run 'xudanu-server rebuild-manifest {}' or delete the data directory to start fresh.",
                            e, data_dir.display()
                        ),
                    ));
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

        self.grand_map.set_id_counter(manifest.grand_map_id_counter);
        self.session_counter = manifest.session_counter;
        self.operation_counter = manifest.operation_counter;
        self.system_clubs = manifest.system_clubs;
        self.link_counter = manifest.link_counter;
        self.reconcile_store = manifest.reconcile_store;
        self.reconcile_counter = manifest.reconcile_counter;
        self.content_address = manifest
            .content_address
            .unwrap_or_else(|| ContentAddressIndex::new(1_000_000));

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

        for (id, work_ref) in &manifest.works {
            match crate::persist::edition_chunks::work_from_chunks_current(work_ref, &chunk_store) {
                Ok(work) => {
                    let ws = WorkState {
                        work: work.clone(),
                        chunk_ref: Some(work_ref.clone()),
                        grabber: None,
                        grabbed_at: None,
                        grab_waiters: Vec::new(),
                        last_revision_author: None,
                        status_detectors: DetectorList::new(),
                        revision_detectors: DetectorList::new(),
                        cached_title: Self::extract_title(work.current_edition()),
                        is_source: false,
                        source_author_id: None,
                        source_edition_info: None,
                        imported_by: None,
                        content_start_line: None,
                        content_end_line: None,
                    };
                    self.works.insert(*id, ws);
                }
                Err(e) => {
                    tracing::error!(
                        "Skipping corrupt work {} (chunk error: {}). \
                         Data for this document is lost.",
                        id,
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

        for link in &manifest.links {
            let o_ref = link
                .origin_ref
                .as_ref()
                .map(|hr| {
                    let excerpt = hr
                        .excerpt
                        .as_deref()
                        .map(crate::edition::Edition::from_text);
                    crate::edition::links::HyperRef::single(
                        excerpt,
                        hr.work_context,
                        hr.original_context,
                        None,
                    )
                })
                .unwrap_or_else(|| {
                    crate::edition::links::HyperRef::single(None, Some(link.origin), None, None)
                });
            let d_ref = link
                .destination_ref
                .as_ref()
                .map(|hr| {
                    let excerpt = hr
                        .excerpt
                        .as_deref()
                        .map(crate::edition::Edition::from_text);
                    crate::edition::links::HyperRef::single(
                        excerpt,
                        hr.work_context,
                        hr.original_context,
                        None,
                    )
                })
                .unwrap_or_else(|| {
                    crate::edition::links::HyperRef::single(
                        None,
                        Some(link.destination),
                        None,
                        None,
                    )
                });
            let hyperlink = crate::edition::links::HyperLink::make(vec![], o_ref, d_ref);
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

        self.chunk_store = Some(chunk_store);
        self.data_dir = Some(data_dir.to_path_buf());
        self.checkpoint_path = Some(manifest_path);
        self.manifest_sequence = manifest.sequence;
        self.attribution_log =
            crate::server::transport::attribution_log::AttributionLog::open(data_dir).ok();

        self.restore_blob_metas(manifest.blob_metas);

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
        self.chunk_store.as_ref()
    }

    pub fn checkpoint_path(&self) -> Option<&std::path::Path> {
        self.checkpoint_path.as_deref()
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
        Ok(link_id)
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

    pub fn find_backlinks(
        &self,
        session_id: SessionId,
        work_id: BeId,
    ) -> Result<Vec<super::transport::protocol::BacklinkEntryPayload>, ServerError> {
        self.ensure_session(session_id)?;
        let link_ids = self.work_to_links.get(&work_id).cloned().unwrap_or_default();
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
            let excerpt = ls.link.end_at("LeftEnd").and_then(|hr| hr.excerpt()).and_then(
                |ed| {
                    let text: String = ed
                        .all_entries()
                        .iter()
                        .filter_map(|(_, c)| c.element.as_text())
                        .collect();
                    if text.is_empty() { None } else { Some(text) }
                },
            );
            let title = self.works.get(&source_work_id).map(|ws| ws.cached_title.clone()).filter(|t| !t.is_empty());
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
    ) -> Result<(), ServerError> {
        self.ensure_authenticated(session_id)?;
        let ws = self.works.get(&work_id).ok_or_else(|| {
            ServerError::NotFound(format!("work {}", work_id))
        })?;
        if ws.grabber != Some(session_id) {
            return Err(ServerError::NotAuthorized);
        }
        let work_anns = self.annotations.entry(work_id).or_default();
        let session = self.sessions.get(&session_id);
        let created_by = session.and_then(|s| s.initial_login());
        work_anns.insert(
            annotation_id,
            AnnotationState {
                kind,
                payload,
                attached_nodes: Vec::new(),
                attached_spans: Vec::new(),
                created_by,
            },
        );
        Ok(())
    }

    pub fn annotation_delete(
        &mut self,
        session_id: SessionId,
        work_id: BeId,
        annotation_id: u64,
    ) -> Result<(), ServerError> {
        self.ensure_authenticated(session_id)?;
        let ws = self.works.get(&work_id).ok_or_else(|| {
            ServerError::NotFound(format!("work {}", work_id))
        })?;
        if ws.grabber != Some(session_id) {
            return Err(ServerError::NotAuthorized);
        }
        if let Some(work_anns) = self.annotations.get_mut(&work_id) {
            work_anns.remove(&annotation_id);
        }
        Ok(())
    }

    pub fn annotation_attach_node(
        &mut self,
        session_id: SessionId,
        work_id: BeId,
        annotation_id: u64,
        node_id: u64,
    ) -> Result<(), ServerError> {
        self.ensure_authenticated(session_id)?;
        let ws = self.works.get(&work_id).ok_or_else(|| {
            ServerError::NotFound(format!("work {}", work_id))
        })?;
        if ws.grabber != Some(session_id) {
            return Err(ServerError::NotAuthorized);
        }
        if let Some(work_anns) = self.annotations.get_mut(&work_id) {
            if let Some(ann) = work_anns.get_mut(&annotation_id) {
                if !ann.attached_nodes.contains(&node_id) {
                    ann.attached_nodes.push(node_id);
                }
            }
        }
        Ok(())
    }

    pub fn annotation_attach_span(
        &mut self,
        session_id: SessionId,
        work_id: BeId,
        annotation_id: u64,
        span_id: u64,
    ) -> Result<(), ServerError> {
        self.ensure_authenticated(session_id)?;
        let ws = self.works.get(&work_id).ok_or_else(|| {
            ServerError::NotFound(format!("work {}", work_id))
        })?;
        if ws.grabber != Some(session_id) {
            return Err(ServerError::NotAuthorized);
        }
        if let Some(work_anns) = self.annotations.get_mut(&work_id) {
            if let Some(ann) = work_anns.get_mut(&annotation_id) {
                if !ann.attached_spans.contains(&span_id) {
                    ann.attached_spans.push(span_id);
                }
            }
        }
        Ok(())
    }

    pub fn annotation_get(
        &self,
        session_id: SessionId,
        work_id: BeId,
        annotation_id: u64,
    ) -> Result<Option<super::transport::protocol::AnnotationPayload>, ServerError> {
        self.ensure_session(session_id)?;
        let ws = self.works.get(&work_id).ok_or_else(|| {
            ServerError::NotFound(format!("work {}", work_id))
        })?;
        if !self.work_is_readable(session_id, &ws.work) {
            return Err(ServerError::NotAuthorized);
        }
        Ok(self
            .annotations
            .get(&work_id)
            .and_then(|m| m.get(&annotation_id))
            .map(|a| super::transport::protocol::AnnotationPayload {
                annotation_id,
                kind: a.kind.clone(),
                payload: a.payload.clone(),
                attached_nodes: a.attached_nodes.clone(),
                attached_spans: a.attached_spans.clone(),
            }))
    }

    pub fn annotation_list(
        &self,
        session_id: SessionId,
        work_id: BeId,
    ) -> Result<Vec<super::transport::protocol::AnnotationPayload>, ServerError> {
        self.ensure_session(session_id)?;
        let ws = self.works.get(&work_id).ok_or_else(|| {
            ServerError::NotFound(format!("work {}", work_id))
        })?;
        if !self.work_is_readable(session_id, &ws.work) {
            return Err(ServerError::NotAuthorized);
        }
        Ok(self
            .annotations
            .get(&work_id)
            .map(|m| {
                m.iter()
                    .map(|(&id, a)| super::transport::protocol::AnnotationPayload {
                        annotation_id: id,
                        kind: a.kind.clone(),
                        payload: a.payload.clone(),
                        attached_nodes: a.attached_nodes.clone(),
                        attached_spans: a.attached_spans.clone(),
                    })
                    .collect()
            })
            .unwrap_or_default())
    }

    pub fn link_count(&self) -> usize {
        self.links.len()
    }

    fn compute_provenance_chain(
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
        for work_id in self.crdt_manager.active_works() {
            candidates.insert(work_id);
        }

        let mut results = Vec::new();
        for (work_id, ws) in &self.works {
            if !candidates.contains(work_id) {
                continue;
            }

            let text = if self.crdt_manager.is_active(*work_id) {
                match self.crdt_manager.current_text(*work_id) {
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
        ed_a.find_content_shared_regions(&ed_b, 2)
    }

    pub fn find_shared_regions_filtered(
        &self,
        work_a: BeId,
        work_b: BeId,
        filter_text: &str,
    ) -> Vec<(i64, i64, i64, i64, String)> {
        let ed_a = match self.work_edition(work_a) {
            Ok(ed) => ed,
            Err(_) => return Vec::new(),
        };
        let ed_b = match self.work_edition(work_b) {
            Ok(ed) => ed,
            Err(_) => return Vec::new(),
        };
        let shared = ed_a.find_content_shared_regions(&ed_b, 2);
        if filter_text.is_empty() {
            return shared;
        }
        shared
            .into_iter()
            .filter(|(_, _, _, _, text)| text.contains(filter_text))
            .collect()
    }

    pub fn find_excerpt_positions(&self, work_id: BeId, excerpt_text: &str) -> Vec<(usize, usize)> {
        if excerpt_text.is_empty() {
            return Vec::new();
        }
        let text = match self.crdt_manager.current_text(work_id) {
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

    pub fn resolve_compound_edition(
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
        if let Ok(text) = self.crdt_manager.current_text(work_id) {
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

    pub fn recorder_plant(
        &mut self,
        edition_id: u64,
        fossil_id: crate::edition::RecorderId,
        content: &[crate::edition::RangeElement],
    ) {
        self.backfollow
            .plant_recorder(edition_id, fossil_id, content);
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

    fn ensure_can_edit(&self, session_id: SessionId, work_be_id: BeId) -> Result<(), ServerError> {
        self.ensure_session(session_id)?;
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
        label_id: u64,
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
        ws.chunk_ref = None;
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
        let km = session._key_master().ok_or(ServerError::NotAuthorized)?;
        for club_id in endorsements.club_ids() {
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
        let ws = self
            .works
            .get_mut(&work_id)
            .ok_or(ServerError::NotFound(format!("work {}", work_id)))?;
        ws.work.endorse(&endorsements);
        ws.chunk_ref = None;
        Ok(())
    }

    pub fn work_retract(
        &mut self,
        session_id: SessionId,
        work_id: BeId,
        endorsements: crate::edition::EndorsementSet,
    ) -> Result<(), ServerError> {
        self.validate_endorsement(session_id, &endorsements)?;
        let ws = self
            .works
            .get_mut(&work_id)
            .ok_or(ServerError::NotFound(format!("work {}", work_id)))?;
        ws.work.retract(&endorsements);
        ws.chunk_ref = None;
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
                    grabber: None,
                    grabbed_at: None,
                    grab_waiters: Vec::new(),
                    last_revision_author: None,
                    status_detectors: DetectorList::new(),
                    revision_detectors: DetectorList::new(),
                    cached_title: title,
                    is_source: false,
                    source_author_id: None,
                    source_edition_info: None,
                    imported_by: None,
                    content_start_line: None,
                    content_end_line: None,
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
            if let Ok(bytes) = self.crdt_manager.extract_update_for_federation(work_id) {
                if bytes.len() > 2 {
                    updates.push(crate::server::federation::CrdtWorkUpdate {
                        work_id,
                        update_bytes: bytes,
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
            let initial_text = if !self.crdt_manager.is_active(update.work_id) {
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

            match self.crdt_manager.apply_federation_update(
                update.work_id,
                &update.update_bytes,
                initial_text.as_deref(),
            ) {
                Ok(_) => {
                    if !update.span_provenance.is_empty() {
                        self.crdt_manager.store_federated_provenance(
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
        let mut gov = self.federation.governance_mut();
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
        let mut gov = self.federation.governance_mut();
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
        let mut gov = self.federation.governance_mut();
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
                            is_source: ws.is_source,
                            source_author_id: ws.source_author_id,
                            source_edition_info: ws.source_edition_info.clone(),
                            content_start_line: ws.content_start_line,
                            content_end_line: ws.content_end_line,
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
                backfollow: BackfollowEngine::new(),
                content_address,
                blob_store: BlobStore::in_memory(),
                checkpoint_path: None,
                data_dir: None,
                chunk_store: None,
                manifest_sequence: 0,
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
                crdt_manager: CrdtManager::new(3),
                otree_crdt: crate::server::otree_crdt::OtreeCrdtManager::new(3),
                use_otree_crdt: false,
                personal_club_count: 0,
                max_personal_clubs: 10_000,
                login_attempts: HashMap::new(),
                attribution_log: None,
                historical_authors: crate::server::historical_author::HistoricalAuthorRegistry::new(
                ),
                source_patterns: crate::server::source_matcher::builtin_patterns(),
                annotations: HashMap::new(),
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
                let work = ws_snap
                    .work
                    .to_work(crate::persist::FlockId::new(*id, 0), None)
                    .work()
                    .clone();
                let ws = WorkState {
                    work: work.clone(),
                    chunk_ref: None,
                    grabber: None,
                    grabbed_at: None,
                    grab_waiters: Vec::new(),
                    last_revision_author: ws_snap.last_revision_author,
                    status_detectors: DetectorList::new(),
                    revision_detectors: DetectorList::new(),
                    cached_title: Self::extract_title(work.current_edition()),
                    is_source: ws_snap.is_source,
                    source_author_id: ws_snap.source_author_id,
                    source_edition_info: ws_snap.source_edition_info.clone(),
                    imported_by: None,
                    content_start_line: ws_snap.content_start_line,
                    content_end_line: ws_snap.content_end_line,
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
                    .map(|hr| {
                        let excerpt = hr
                            .excerpt
                            .as_deref()
                            .map(crate::edition::Edition::from_text);
                        HyperRef::single(excerpt, hr.work_context, hr.original_context, None)
                    })
                    .unwrap_or_else(|| HyperRef::single(None, Some(ls.origin), None, None));
                let d_ref = ls
                    .destination_ref
                    .as_ref()
                    .map(|hr| {
                        let excerpt = hr
                            .excerpt
                            .as_deref()
                            .map(crate::edition::Edition::from_text);
                        HyperRef::single(excerpt, hr.work_context, hr.original_context, None)
                    })
                    .unwrap_or_else(|| HyperRef::single(None, Some(ls.destination), None, None));
                let link = HyperLink::make(vec![], o_ref, d_ref);
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

            server
        }

        pub fn checkpoint_to_file(&self, path: &std::path::Path) -> std::io::Result<()> {
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

        pub fn checkpoint_to_store(&mut self) -> std::io::Result<()> {
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
            let mut work_refs: Vec<(BeId, crate::persist::edition_chunks::WorkChunkRef)> =
                Vec::new();
            for (id, ws) in &self.works {
                if let Some(ref existing_ref) = ws.chunk_ref {
                    work_refs.push((*id, existing_ref.clone()));
                } else {
                    dirty_work_count += 1;
                    let work_ref =
                        crate::persist::edition_chunks::work_to_chunks(&ws.work, chunk_store)
                            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
                    work_refs.push((*id, work_ref));
                }
            }

            for (id, work_ref) in &work_refs {
                if let Some(ws) = self.works.get_mut(id) {
                    if ws.chunk_ref.is_none() {
                        ws.chunk_ref = Some(work_ref.clone());
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
            self.dirty_clubs.clear();

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

            let mut manifest = crate::persist::manifest::Manifest {
                format_version: 0,
                created_at: String::new(),
                server_version: String::new(),
                checksum: String::new(),
                sequence: self.manifest_sequence,
                grand_map_id_counter: self.grand_map.id_counter(),
                session_counter: self.session_counter,
                operation_counter: self.operation_counter,
                system_clubs: self.system_clubs,
                works: work_refs,
                clubs: club_refs,
                standalone_editions: standalone_refs,
                links,
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
                content_address: Some(self.content_address.clone()),
                blob_metas,
                key_history,
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
            crate::persist::manifest::rotate_manifest_backups(&manifest_path, 3);
            crate::persist::manifest::write_manifest(&mut manifest, &manifest_path)
                .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
            self.manifest_sequence = manifest.sequence;
            {
                let backup =
                    crate::persist::manifest::backup_manifest_path(data_dir, manifest.sequence);
                if let Err(e) = std::fs::copy(&manifest_path, &backup) {
                    tracing::warn!("Failed to create versioned manifest backup: {}", e);
                }
            }
            self.save_key_history();

            if let Err(e) = self.gc_orphaned_chunks() {
                tracing::warn!("Chunk GC failed: {}", e);
            }

            tracing::info!(
                "Checkpoint #{} saved in {:.2}ms (dirty: {}/{}/{} works/clubs/editions)",
                start.elapsed().as_secs_f64() * 1000.0,
                dirty_work_count,
                dirty_club_count,
                dirty_edition_count,
                manifest.sequence,
            );
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
                    if let Ok(hashes) =
                        crate::persist::edition_chunks::collect_work_hashes(work_ref, chunk_store)
                    {
                        referenced.extend(hashes);
                    }
                }
            }
            for club_ref in self.club_refs.values() {
                if let Ok(hashes) = crate::persist::edition_chunks::collect_work_hashes(
                    &club_ref.work_root,
                    chunk_store,
                ) {
                    referenced.extend(hashes);
                }
            }
            for ed_ref in self.standalone_edition_refs.values() {
                if let Ok(hashes) =
                    crate::persist::edition_chunks::collect_edition_hashes(ed_ref, chunk_store)
                {
                    referenced.extend(hashes);
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
                        for (_, work_ref) in &backup_manifest.works {
                            if let Ok(hashes) =
                                crate::persist::edition_chunks::collect_edition_hashes(
                                    &work_ref.current_root,
                                    chunk_store,
                                )
                            {
                                referenced.extend(hashes);
                            }
                        }
                        for club_ref in &backup_manifest.clubs {
                            if let Ok(hashes) =
                                crate::persist::edition_chunks::collect_edition_hashes(
                                    &club_ref.work_root.current_root,
                                    chunk_store,
                                )
                            {
                                referenced.extend(hashes);
                            }
                        }
                        for se_ref in &backup_manifest.standalone_editions {
                            if let Ok(hashes) =
                                crate::persist::edition_chunks::collect_edition_hashes(
                                    &se_ref.edition_ref,
                                    chunk_store,
                                )
                            {
                                referenced.extend(hashes);
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
    fn server_disconnect_ends_session() {
        let mut server = Server::new();
        let sid = server.connect();
        server.disconnect(sid).unwrap();
        assert_eq!(server.session_count(), 0);
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

        let content = RangeElement::text("hi".to_string());
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
        let authors = server.crdt_manager.get_author_sessions(work_id).unwrap();
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
}
