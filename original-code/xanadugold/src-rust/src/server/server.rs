use std::collections::HashMap;

use crate::edition::{
    BeId, BeRangeElement, BeStorage, Edition, GrandMap, InMemoryBeStorage,
    Work, XnRegion, ContentAddressIndex,
    RangeElement, hash_content, u64_from_hash,
};
use crate::edition::backfollow::BackfollowEngine;
use crate::edition::blob_store::{BlobMeta, BlobStore, MemoryBackend};
use crate::edition::links::{HyperLink, HyperRef};
use crate::edition::transclusion::{TransclusionIndex, TransclusionQuery, WorkQuery};
use super::admin::{AdminState, IdGrant, SessionInfo};
use super::club::Club;
use super::detector::{Detector, DetectorList, Event};
use super::error::ServerError;
use super::keymaster::KeyMaster;
use super::lock::{Lock, LockCredential, BooLockSmith, LockSmith};
use super::session::{Session, SessionId};


#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct SystemClubs {
    pub public_club: BeId,
    pub admin_club: BeId,
    pub access_club: BeId,
    pub empty_club: BeId,
}

struct WorkState {
    work: Work,
    grabber: Option<SessionId>,
    last_revision_author: Option<BeId>,
    status_detectors: DetectorList,
    revision_detectors: DetectorList,
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

pub struct Server {
    grand_map: GrandMap,
    sessions: HashMap<SessionId, Session>,
    session_counter: u64,
    clubs: HashMap<BeId, Club>,
    club_names: HashMap<String, BeId>,
    works: HashMap<BeId, WorkState>,
    standalone_editions: HashMap<BeId, Edition>,
    edition_detectors: HashMap<BeId, DetectorList>,
    system_clubs: SystemClubs,
    operation_counter: u64,
    admin: AdminState,
    links: HashMap<BeId, LinkState>,
    link_counter: BeId,
    backfollow: BackfollowEngine,
    transclusion_index: TransclusionIndex,
    content_address: ContentAddressIndex,
    blob_store: BlobStore,
    checkpoint_path: Option<std::path::PathBuf>,
    recorder_system: crate::edition::RecorderSystem,
    start_time: u64,
    server_keypair: crate::crypto::keys::ServerKeyPair,
    key_history: crate::crypto::keys::KeyHistory,
    federation: crate::server::federation::FederationState,
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

impl Server {
    pub fn new() -> Self {
        let mut grand_map = GrandMap::new();

        let public_club = {
            let (be_id, elem) = grand_map.new_work_element(None);
            grand_map.assign_new_id(elem);
            let _club = Club::new_with_owner(
                be_id,
                Some(be_id),
                Edition::from_text("public"),
            );
            be_id
        };

        let admin_club = {
            let (be_id, elem) = grand_map.new_work_element(Some(public_club));
            grand_map.assign_new_id(elem);
            let _club = Club::new_with_owner(
                be_id,
                Some(be_id),
                Edition::from_text("admin"),
            );
            be_id
        };

        let access_club = {
            let (be_id, elem) = grand_map.new_work_element(Some(admin_club));
            grand_map.assign_new_id(elem);
            let _club = Club::new_with_owner(
                be_id,
                Some(admin_club),
                Edition::from_text("access"),
            );
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
            edition_detectors: HashMap::new(),
            system_clubs,
            operation_counter: 0,
            admin: AdminState::new(),
            links: HashMap::new(),
            link_counter: 0,
            transclusion_index: TransclusionIndex::new(),
            content_address: ContentAddressIndex::new(1_000_000),
            backfollow: BackfollowEngine::new(),
            blob_store: BlobStore::in_memory(),
            checkpoint_path: None,
            recorder_system: crate::edition::RecorderSystem::new(),
            start_time: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs(),
            server_keypair: server_kp.clone(),
            key_history: crate::crypto::keys::KeyHistory::new(&server_kp),
            federation: crate::server::federation::FederationState::disabled(),
        };

        let pub_club = Club::new_with_owner(
            public_club,
            Some(public_club),
            Edition::from_text("public"),
        );
        server.clubs.insert(public_club, pub_club);
        server.club_names.insert("public".to_string(), public_club);

        let adm_club = Club::new_with_owner(
            admin_club,
            Some(admin_club),
            Edition::from_text("admin"),
        );
        server.clubs.insert(admin_club, adm_club);
        server.club_names.insert("admin".to_string(), admin_club);
        if let Some(c) = server.clubs.get_mut(&admin_club) {
            c.set_read_club(Some(public_club));
        }

        let acc_club = Club::new_with_owner(
            access_club,
            Some(admin_club),
            Edition::from_text("access"),
        );
        server.clubs.insert(access_club, acc_club);
        server.club_names.insert("access".to_string(), access_club);

        let emp_club = Club::new(empty_club, Edition::empty());
        server.clubs.insert(empty_club, emp_club);
        server.club_names.insert("empty".to_string(), empty_club);

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
        self.session_counter += 1;
        let id = SessionId::new(self.session_counter);
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
                ws.status_detectors.fire(&Event::WorkReleased {
                    work_be_id,
                    session_id,
                });
            }
        }

        if let Some(session) = self.sessions.get_mut(&session_id) {
            session.end();
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

    // === Authentication ===

    pub fn login(
        &mut self,
        session_id: SessionId,
        club_id: BeId,
    ) -> Result<Box<dyn Lock>, ServerError> {
        self.ensure_session(session_id)?;

        let club = self
            .clubs
            .get(&club_id)
            .ok_or(ServerError::ClubNotFound(club_id))?;

        if club.read_club() == Some(self.system_clubs.public_club) {
            let lock = BooLockSmith::new().create_lock(Some(club_id));
            return Ok(lock);
        }

        let lock: Box<dyn Lock> = if club_id == self.system_clubs.public_club {
            Box::new(super::lock::BooLock::new(club_id))
        } else {
            Box::new(super::lock::WallLock::new())
        };

        Ok(lock)
    }

    pub fn login_by_name(
        &mut self,
        session_id: SessionId,
        club_name: &str,
    ) -> Result<Box<dyn Lock>, ServerError> {
        let club_id = self
            .club_names
            .get(club_name)
            .copied()
            .ok_or_else(|| ServerError::NotFound(format!("club '{}'", club_name)))?;
        self.login(session_id, club_id)
    }

    pub fn authenticate(
        &mut self,
        session_id: SessionId,
        lock: &dyn Lock,
        credential: &LockCredential,
    ) -> Result<KeyMaster, ServerError> {
        let km = lock.try_open(credential)?;
        let session = self
            .sessions
            .get_mut(&session_id)
            .ok_or(ServerError::SessionNotFound(session_id))?;
        session.set_key_master(km.clone());
        Ok(km)
    }

    pub fn login_public(&mut self, session_id: SessionId) -> Result<KeyMaster, ServerError> {
        let lock = super::lock::BooLock::new(self.system_clubs.public_club);
        self.authenticate(session_id, &lock, &LockCredential::Boo)
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

        let owner = self.session(session_id)?.authority_clubs().iter().next().copied();
        let mut club = Club::new_with_owner(be_id, owner, description);
        club.set_read_club(Some(self.system_clubs.public_club));
        club.set_edit_club(Some(be_id));

        self.clubs.insert(be_id, club);
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
        Ok(be_id)
    }

    pub fn club(&self, club_id: BeId) -> Result<&Club, ServerError> {
        self.clubs
            .get(&club_id)
            .ok_or(ServerError::ClubNotFound(club_id))
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
        self.clubs
            .get(&club_id)
            .and_then(|c| c.name())
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

        let (be_id, elem) = self.grand_map.new_work_element(None);
        self.grand_map.assign_new_id(elem);

        let owner = self.session(session_id)?.authority_clubs().iter().next().copied();
        let mut work = Work::new_with_owner(be_id, owner, edition);
        work.set_read_club(Some(self.system_clubs.public_club));
        work.set_edit_club(Some(self.system_clubs.public_club));

        let ws = WorkState {
            work,
            grabber: None,
            last_revision_author: None,
            status_detectors: DetectorList::new(),
            revision_detectors: DetectorList::new(),
        };
        self.works.insert(be_id, ws);

        let edition = self.works[&be_id].work.edition().clone();
        self.content_address.intern_edition_elements(&edition);
        let work_elem = RangeElement::work(be_id);
        self.transclusion_index.register_work(&edition, &work_elem);
        let work = Work::new_with_owner(be_id, owner, edition);
        self.backfollow.register_work(work, be_id, None);
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

    pub fn work_revise(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
        new_edition: Edition,
    ) -> Result<u64, ServerError> {
        self.ensure_session(session_id)?;
        self.ensure_grabbed_by(session_id, work_be_id)?;

        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;

        let author_club = self
            .sessions
            .get(&session_id)
            .and_then(|s| s.initial_login());

        ws.last_revision_author = author_club;
        ws.work.revise(new_edition);
        let revision = ws.work.revision_count();

        ws.revision_detectors.fire(&Event::WorkRevised {
            work_be_id,
            revision,
            session_id,
        });

        let updated_edition = ws.work.edition().clone();
        self.content_address.intern_edition_elements(&updated_edition);
        let work_elem = RangeElement::work(work_be_id);
        self.transclusion_index.register_work(&updated_edition, &work_elem);
        let updated_work = Work::new_with_owner(work_be_id, ws.work.owner(), updated_edition);
        self.backfollow.update_work(work_be_id, updated_work);
        self.auto_checkpoint();

        Ok(revision)
    }

    pub fn work_grab(
        &mut self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
        self.ensure_session(session_id)?;
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
        ws.status_detectors.fire(&Event::WorkGrabbed {
            work_be_id,
            session_id,
        });

        Ok(())
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
        ws.status_detectors.fire(&Event::WorkReleased {
            work_be_id,
            session_id,
        });

        Ok(())
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
        ws.work.set_read_club(club_id);
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
        work_be_id: BeId,
        club_id: BeId,
    ) -> Result<(), ServerError> {
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        ws.work.add_sponsor(club_id);
        Ok(())
    }

    pub fn work_unsponsor(
        &mut self,
        work_be_id: BeId,
        club_id: BeId,
    ) -> Result<(), ServerError> {
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        ws.work.remove_sponsor(club_id);
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
        &self,
        work_be_id: BeId,
        number: u64,
    ) -> Result<Option<Edition>, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        Ok(ws.work.fetch_revision(number).cloned())
    }

    pub fn work_last_revision_author(
        &self,
        work_be_id: BeId,
    ) -> Result<Option<BeId>, ServerError> {
        let ws = self
            .works
            .get(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        Ok(ws.last_revision_author)
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
        _session_id: SessionId,
        work_be_id: BeId,
        owner: Option<BeId>,
    ) -> Result<(), ServerError> {
        let ws = self
            .works
            .get_mut(&work_be_id)
            .ok_or(ServerError::WorkNotFound(work_be_id))?;
        ws.work.set_owner(owner);
        Ok(())
    }

    pub fn work_count(&self) -> usize {
        self.works.len()
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

    pub fn list_works_with_titles(&self) -> Vec<(BeId, Option<BeId>, u64, bool, String)> {
        self.works
            .iter()
            .map(|(id, ws)| {
                let owner = ws.work.owner();
                let rev_count = ws.work.revision_count();
                let grabbed = ws.grabber.is_some();
                let text = ws.work.current_edition()
                    .all_entries()
                    .iter()
                    .map(|(_, c)| c.element.as_text().unwrap_or(""))
                    .collect::<String>();
                let title = text.lines().next().unwrap_or("").chars().take(60).collect();
                (*id, owner, rev_count, grabbed, title)
            })
            .collect()
    }

    pub fn list_works_by_owner(&self, owner: BeId) -> Vec<(BeId, Option<BeId>, u64, bool)> {
        self.works
            .iter()
            .filter(|(_, ws)| ws.work.owner() == Some(owner))
            .map(|(id, ws)| {
                let rev_count = ws.work.revision_count();
                let grabbed = ws.grabber.is_some();
                (*id, ws.work.owner(), rev_count, grabbed)
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
        let edition = self.standalone_editions.get(&be_id).unwrap().clone();
        let edition_elem = RangeElement::edition(be_id);
        self.transclusion_index.register_edition(&edition, &edition_elem, None);
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
        let session = self.sessions.get(&session_id).unwrap();
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

    pub fn admin_active_sessions(&self, session_id: SessionId) -> Result<Vec<SessionInfo>, ServerError> {
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
        }
        self.operation_counter
    }

    pub fn set_checkpoint_path(&mut self, path: std::path::PathBuf) {
        self.checkpoint_path = Some(path);
    }

    fn auto_checkpoint(&mut self) {
        #[cfg(feature = "server")]
        if let Some(ref path) = self.checkpoint_path {
            if let Err(e) = self.checkpoint_to_file(path) {
                tracing::warn!("auto-checkpoint failed: {}", e);
            }
        }
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

        let link = if let (Some(o_ref), Some(d_ref)) = (origin_ref, destination_ref) {
            HyperLink::make(vec![], o_ref, d_ref)
        } else {
            let o_ref = HyperRef::single(None, Some(origin), None, None);
            let d_ref = HyperRef::single(None, Some(destination), None, None);
            HyperLink::make(vec![], o_ref, d_ref)
        };

        let ls = LinkState { link, origin, destination };
        self.links.insert(link_id, ls);
        let link_elem = RangeElement::work(link_id);
        let origin_elem = RangeElement::work(origin);
        let dest_elem = RangeElement::work(destination);
        self.transclusion_index.register_work(
            &crate::edition::Edition::from_one(0, origin_elem.clone()),
            &link_elem,
        );
        self.transclusion_index.register_work(
            &crate::edition::Edition::from_one(0, dest_elem.clone()),
            &link_elem,
        );
        Ok(link_id)
    }

    pub fn get_link(&self, link_id: BeId) -> Result<(BeId, BeId, &HyperLink), ServerError> {
        let ls = self.links.get(&link_id)
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
        let ls = self.links.get_mut(&link_id)
            .ok_or(ServerError::NotFound(format!("link {}", link_id)))?;
        if let Some(o_ref) = origin_ref {
            ls.link = ls.link.with_end("LeftEnd", o_ref);
        }
        if let Some(d_ref) = destination_ref {
            ls.link = ls.link.with_end("RightEnd", d_ref);
        }
        Ok(())
    }

    pub fn delete_link(&mut self, _session_id: SessionId, link_id: BeId) -> Result<(), ServerError> {
        self.ensure_session(_session_id)?;
        if self.links.remove(&link_id).is_none() {
            return Err(ServerError::NotFound(format!("link {}", link_id)));
        }
        Ok(())
    }

    pub fn list_links_for_work(&self, work_id: BeId) -> Vec<(BeId, BeId, BeId)> {
        self.links
            .iter()
            .filter(|(_, ls)| ls.origin == work_id || ls.destination == work_id)
            .map(|(id, ls)| (*id, ls.origin, ls.destination))
            .collect()
    }

    pub fn link_count(&self) -> usize {
        self.links.len()
    }

    // === Transclusion queries ===

    pub fn find_transcluders(&self, content_be_id: BeId) -> Vec<(String, BeId, bool)> {
        let content = RangeElement::edition(content_be_id);
        let query = TransclusionQuery::all();
        let results = self.backfollow.find_transcluders(&content, &query);
        if !results.is_empty() {
            return results.into_iter().map(|r| {
                let elem = &r.element;
                if let Some(wid) = elem.as_work_id() {
                    ("work".to_string(), wid, r.is_direct)
                } else if let Some(eid) = elem.as_edition_id() {
                    ("edition".to_string(), eid, r.is_direct)
                } else {
                    ("unknown".to_string(), 0, r.is_direct)
                }
            }).collect();
        }
        let results = self.transclusion_index.find_transcluders(&content, &query);
        results.into_iter().map(|r| {
            let elem = &r.element;
            if let Some(wid) = elem.as_work_id() {
                ("work".to_string(), wid, r.is_direct)
            } else if let Some(eid) = elem.as_edition_id() {
                ("edition".to_string(), eid, r.is_direct)
            } else {
                ("unknown".to_string(), 0, r.is_direct)
            }
        }).collect()
    }

    pub fn find_works_for_content(&self, content_be_id: BeId) -> Vec<BeId> {
        let content = RangeElement::edition(content_be_id);
        let query = WorkQuery::all();
        let elems = self.backfollow.find_works_for_content(&content, &query);
        if !elems.is_empty() {
            return elems;
        }
        let elems = self.transclusion_index.find_works(&content, &query);
        elems.into_iter().filter_map(|e| e.as_work_id()).collect()
    }

    pub fn find_text_transcluders(
        &self,
        search_text: &str,
    ) -> Vec<(BeId, Option<BeId>, u64, Vec<(i64, i64)>)> {
        let mut results = Vec::new();
        for (work_id, ws) in &self.works {
            let ed = ws.work.current_edition();
            let text = ed
                .all_entries()
                .iter()
                .map(|(_, carrier)| carrier.element.as_text().unwrap_or(""))
                .collect::<String>();
            let mut matches = Vec::new();
            let mut start = 0;
            while let Some(pos) = text[start..].find(search_text) {
                let abs_start = (start + pos) as i64;
                let abs_end = abs_start + search_text.len() as i64;
                matches.push((abs_start, abs_end));
                start += pos + 1;
                if start >= text.len() { break; }
            }
            if !matches.is_empty() {
                results.push((
                    *work_id,
                    ws.work.owner(),
                    ws.work.revision_count(),
                    matches,
                ));
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

    pub fn content_address_lookup(&self, element: &RangeElement) -> Option<BeId> {
        self.content_address.lookup(element)
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
        if data.len() > MAX_BLOB_SIZE {
            return Err(ServerError::InvalidArgument(
                format!("blob too large: {} bytes (max {})", data.len(), MAX_BLOB_SIZE)
            ));
        }
        self.blob_store.store(&data, mime_type)
            .map_err(|e| ServerError::Internal(e.to_string()))
    }

    pub fn blob_get(&self, hash_u64: u64) -> Result<Vec<u8>, ServerError> {
        let meta = self.blob_store.get_meta_by_u64(hash_u64)
            .ok_or_else(|| ServerError::NotFound(format!("blob {:016x}", hash_u64)))?;
        self.blob_store.retrieve(&meta.content_hash)
            .map_err(|e| ServerError::Internal(e.to_string()))
    }

    pub fn blob_preview(&self, hash_u64: u64) -> Result<Option<Vec<u8>>, ServerError> {
        let meta = self.blob_store.get_meta_by_u64(hash_u64)
            .ok_or_else(|| ServerError::NotFound(format!("blob {:016x}", hash_u64)))?;
        self.blob_store.retrieve_preview(&meta)
            .map_err(|e| ServerError::Internal(e.to_string()))
    }

    pub fn blob_exists(&self, hash_u64: u64) -> bool {
        self.blob_store.get_meta_by_u64(hash_u64).is_some()
    }

    pub fn blob_info(&self, hash_u64: u64) -> Result<BlobMeta, ServerError> {
        self.blob_store.get_meta_by_u64(hash_u64)
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
            return Err(ServerError::NotFound(format!("base blob {:016x}", base_hash)));
        }
        self.blob_store.store_overlay(base_hash, ops, mime_type)
            .map_err(|e| ServerError::Internal(e.to_string()))
    }

    pub fn blob_get_overlay(&self, hash_u64: u64) -> Result<crate::edition::ImageOverlay, ServerError> {
        self.blob_store.retrieve_overlay_by_u64(hash_u64)
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

    pub fn fire_fill_event(
        &mut self,
        edition_be_id: BeId,
        region: crate::edition::XnRegion,
    ) {
        if let Some(detectors) = self.edition_detectors.get_mut(&edition_be_id) {
            detectors.fire(&Event::RangeFilled {
                edition_be_id,
                region,
            });
        }
    }

    // === Private helpers ===

    fn ensure_session(&self, session_id: SessionId) -> Result<(), ServerError> {
        let session = self
            .sessions
            .get(&session_id)
            .ok_or(ServerError::SessionNotFound(session_id))?;
        if !session.is_connected() {
            return Err(ServerError::SessionNotFound(session_id));
        }
        Ok(())
    }

    fn ensure_logged_in(&self, session_id: SessionId) -> Result<(), ServerError> {
        self.ensure_session(session_id)?;
        let session = self.sessions.get(&session_id).unwrap();
        if !session.is_logged_in() {
            return Err(ServerError::NotAuthorized);
        }
        Ok(())
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

    fn ensure_can_edit(
        &self,
        session_id: SessionId,
        work_be_id: BeId,
    ) -> Result<(), ServerError> {
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

    fn check_read_permission(&self, session_id: SessionId, work: &Work) -> bool {
        match work.read_club() {
            Some(club_id) => {
                if club_id == self.system_clubs.public_club || club_id == self.system_clubs.empty_club {
                    return true;
                }
                self.sessions
                    .get(&session_id)
                    .map(|s| s.has_authority(club_id))
                    .unwrap_or(false)
            }
            None => true,
        }
    }

    fn check_edit_permission(&self, session_id: SessionId, work: &Work) -> bool {
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
            None => true,
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

    pub fn label_get_positions(&self, work_id: BeId, label_id: u64) -> Result<XnRegion, ServerError> {
        let ws = self.works.get(&work_id).ok_or(ServerError::WorkNotFound(work_id))?;
        let ed = ws.work.current_edition();
        Ok(ed.positions_labelled(label_id))
    }

    pub fn edition_relabel(&mut self, work_id: BeId, label_id: u64) -> Result<Edition, ServerError> {
        let ws = self.works.get(&work_id).ok_or(ServerError::WorkNotFound(work_id))?;
        let _ed = ws.work.current_edition();
        Ok(Edition::empty())
    }

    pub fn edition_rebind(&mut self, session_id: SessionId, work_id: BeId, position: i64, new_edition: Edition) -> Result<Edition, ServerError> {
        self.ensure_grabbed_by(session_id, work_id)?;
        let ws = self.works.get_mut(&work_id).ok_or(ServerError::WorkNotFound(work_id))?;
        let current = ws.work.current_edition();
        if !current.has_position(position) {
            return Err(ServerError::InvalidArgument(format!("position {} not found in work {}", position, work_id)));
        }
        let old_carrier = current.carrier_at(position)
            .ok_or(ServerError::InvalidArgument("no carrier at position".into()))?;
        let new_elem = new_edition.fetch(position)
            .ok_or(ServerError::InvalidArgument("no element at position in new edition".into()))?;
        let new_carrier = match old_carrier.label.as_ref() {
            Some(lid) => crate::edition::range_element::Carrier::labelled(lid.clone(), new_elem),
            None => crate::edition::range_element::Carrier::new(new_elem),
        };
        let updated = Edition {
            orgl: current.orgl.with(position, std::sync::Arc::new(new_carrier)),
            endorsements: current.endorsements.clone(),
        };
        ws.work.revise(updated.clone());
        Ok(updated)
    }

    pub fn can_make_identical_elements(
        &self,
        source_work_id: BeId,
        target_work_id: BeId,
        position: Option<i64>,
    ) -> Result<Vec<(i64, String)>, ServerError> {
        let source_ws = self.works.get(&source_work_id).ok_or(ServerError::WorkNotFound(source_work_id))?;
        let target_ws = self.works.get(&target_work_id).ok_or(ServerError::WorkNotFound(target_work_id))?;
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
                        crate::edition::CanMakeIdenticalResult::DifferentContent => "different_content",
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
        let source_ws = self.works.get(&source_work_id).ok_or(ServerError::WorkNotFound(source_work_id))?;
        let target_ws = self.works.get(&target_work_id).ok_or(ServerError::WorkNotFound(target_work_id))?;
        let source_ed = source_ws.work.current_edition();
        let target_ed = target_ws.work.current_edition();
        let result = crate::edition::make_range_identical(&source_ed, &target_ed, region.as_ref());
        let outcome = match result.outcome {
            crate::edition::MakeRangeIdenticalOutcome::AllUnified => "all_unified",
            crate::edition::MakeRangeIdenticalOutcome::PartiallyUnified { .. } => "partially_unified",
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
        let ws = self.works.get(&work_id)
            .ok_or_else(|| ServerError::WorkNotFound(work_id))?;
        let edition = ws.work.current_edition();
        Ok(edition.retrieve(region, flags))
    }

    pub fn edition_cost(
        &self,
        work_id: BeId,
        method: crate::edition::CostMethod,
    ) -> Result<crate::edition::StorageCost, ServerError> {
        let ws = self.works.get(&work_id)
            .ok_or_else(|| ServerError::WorkNotFound(work_id))?;
        let edition = ws.work.current_edition();
        Ok(edition.cost(method))
    }

    pub fn content_shared_region(&self, work_a: BeId, work_b: BeId) -> Result<XnRegion, ServerError> {
        let ed_a = self.get_edition(work_a)?.ok_or(ServerError::WorkNotFound(work_a))?;
        let ed_b = self.get_edition(work_b)?.ok_or(ServerError::WorkNotFound(work_b))?;
        Ok(ed_a.content_shared_region(&ed_b))
    }

    pub fn content_map_shared_to(&self, work_a: BeId, work_b: BeId) -> Result<crate::edition::SharedMapping, ServerError> {
        let ed_a = self.get_edition(work_a)?.ok_or(ServerError::WorkNotFound(work_a))?;
        let ed_b = self.get_edition(work_b)?.ok_or(ServerError::WorkNotFound(work_b))?;
        Ok(ed_a.content_map_shared_to(&ed_b))
    }

    pub fn content_map_shared_onto(&self, work_a: BeId, work_b: BeId) -> Result<crate::edition::SharedMapping, ServerError> {
        let ed_a = self.get_edition(work_a)?.ok_or(ServerError::WorkNotFound(work_a))?;
        let ed_b = self.get_edition(work_b)?.ok_or(ServerError::WorkNotFound(work_b))?;
        Ok(ed_a.content_map_shared_onto(&ed_b))
    }

    pub fn positions_of(&self, work_id: BeId, element: &RangeElement) -> Result<XnRegion, ServerError> {
        let edition = self.get_edition(work_id)?.ok_or(ServerError::WorkNotFound(work_id))?;
        Ok(edition.positions_of(element))
    }

    pub fn range_transcluders(&self, work_id: BeId, region: Option<&XnRegion>, direct_only: bool) -> Result<crate::edition::RangeTransclusionResult, ServerError> {
        let edition = self.get_edition(work_id)?.ok_or(ServerError::WorkNotFound(work_id))?;
        let query = crate::edition::RangeTransclusionQuery::new()
            .direct_only(direct_only);
        let query = match region {
            Some(r) => query.with_region(r.clone()),
            None => query,
        };
        let tq = crate::edition::TransclusionQuery::all();
        Ok(crate::edition::range_transcluders(&edition, &query, &self.transclusion_index, &tq))
    }

    pub fn range_works(&self, work_id: BeId, region: Option<&XnRegion>) -> Result<crate::edition::RangeWorkResult, ServerError> {
        let edition = self.get_edition(work_id)?.ok_or(ServerError::WorkNotFound(work_id))?;
        let query = crate::edition::RangeTransclusionQuery::new();
        let query = match region {
            Some(r) => query.with_region(r.clone()),
            None => query,
        };
        let wq = crate::edition::WorkQuery::all();
        Ok(crate::edition::range_works(&edition, &query, &self.transclusion_index, &wq))
    }

    pub fn ordered_bundles(&self, work_id: BeId, region: Option<&XnRegion>) -> Result<Vec<crate::edition::Bundle>, ServerError> {
        let edition = self.get_edition(work_id)?.ok_or(ServerError::WorkNotFound(work_id))?;
        Ok(edition.ordered_merge_bundles(region))
    }

    pub fn transclusion_depth(&self, work_id: BeId, position: i64, max_depth: usize) -> Result<usize, ServerError> {
        let edition = self.get_edition(work_id)?.ok_or(ServerError::WorkNotFound(work_id))?;
        Ok(edition.transclusion_depth(position, &self.transclusion_index, max_depth))
    }

    pub fn recorder_create(&mut self, query: crate::edition::RecorderQuery) -> Result<crate::edition::RecorderId, ServerError> {
        Ok(self.recorder_system.create_fossil(query))
    }

    pub fn recorder_record(&mut self, recorder_id: crate::edition::RecorderId, element: &crate::edition::RangeElement) -> Result<bool, ServerError> {
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
        self.recorder_system.fossil_ids()
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
        let new_id = self.key_history.rotate(&old_kp, &new_kp)
            .map_err(|e| ServerError::Internal(format!("key rotation failed: {}", e)))?;
        self.server_keypair = new_kp;
        Ok(new_id)
    }

    pub fn sign_data(&self, data: &[u8]) -> Vec<u8> {
        let sig = crate::crypto::sign::sign_bytes(&self.server_keypair.signing_key, data);
        sig.to_bytes().to_vec()
    }

    pub fn verify_server_signature(&self, data: &[u8], signature: &[u8]) -> Result<(), ServerError> {
        self.verify_server_signature_with_key(None, data, signature)
    }

    pub fn verify_server_signature_with_key(&self, key_id: Option<u64>, data: &[u8], signature: &[u8]) -> Result<(), ServerError> {
        let sig = ed25519_dalek::Signature::from_slice(signature)
            .map_err(|_| ServerError::InvalidArgument("invalid signature bytes".into()))?;
        let verifying_key = match key_id {
            Some(kid) => {
                let entry = self.key_history.get(kid)
                    .ok_or_else(|| ServerError::InvalidArgument(format!("unknown key_id: {}", kid)))?;
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
        let session = self.sessions.get(&session_id).unwrap();
        let km = session._key_master()
            .ok_or(ServerError::NotAuthorized)?;
        for club_id in endorsements.club_ids() {
            if !km.has_signature_authority(club_id, &self.clubs) {
                return Err(ServerError::Unauthorized(
                    format!("no signature authority for club {}", club_id)
                ));
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
        let ws = self.works.get_mut(&work_id)
            .ok_or(ServerError::NotFound(format!("work {}", work_id)))?;
        ws.work.endorse(&endorsements);
        Ok(())
    }

    pub fn work_retract(
        &mut self,
        session_id: SessionId,
        work_id: BeId,
        endorsements: crate::edition::EndorsementSet,
    ) -> Result<(), ServerError> {
        self.validate_endorsement(session_id, &endorsements)?;
        let ws = self.works.get_mut(&work_id)
            .ok_or(ServerError::NotFound(format!("work {}", work_id)))?;
        ws.work.retract(&endorsements);
        Ok(())
    }

    pub fn work_endorsements(&self, work_id: BeId) -> Result<crate::edition::EndorsementSet, ServerError> {
        let ws = self.works.get(&work_id)
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
        let edition = self.standalone_editions.get_mut(&edition_id)
            .ok_or(ServerError::NotFound(format!("edition {}", edition_id)))?;
        edition.endorse(&endorsements);
        Ok(())
    }

    pub fn edition_retract(
        &mut self,
        session_id: SessionId,
        edition_id: BeId,
        endorsements: crate::edition::EndorsementSet,
    ) -> Result<(), ServerError> {
        self.validate_endorsement(session_id, &endorsements)?;
        let edition = self.standalone_editions.get_mut(&edition_id)
            .ok_or(ServerError::NotFound(format!("edition {}", edition_id)))?;
        edition.retract(&endorsements);
        Ok(())
    }

    pub fn edition_endorsements(&self, edition_id: BeId) -> Result<crate::edition::EndorsementSet, ServerError> {
        let edition = self.standalone_editions.get(&edition_id)
            .ok_or(ServerError::NotFound(format!("edition {}", edition_id)))?;
        Ok(edition.endorsements().clone())
    }

    pub fn edition_visible_endorsements(
        &self,
        session_id: SessionId,
        edition_id: BeId,
    ) -> Result<crate::edition::EndorsementSet, ServerError> {
        let edition = self.standalone_editions.get(&edition_id)
            .ok_or(ServerError::NotFound(format!("edition {}", edition_id)))?;
        let _session = self.sessions.get(&session_id)
            .ok_or(ServerError::SessionNotFound(session_id))?;
        let mut result = edition.endorsements().clone();
        for (_, ws) in &self.works {
            let current_ed = ws.work.current_edition();
            if current_ed == edition {
                if self.work_can_read_by(session_id, ws.work.be_id()) {
                    result = result.union(ws.work.endorsements());
                }
            }
        }
        Ok(result)
    }

    pub fn edition_total_endorsements(
        &self,
        edition_id: BeId,
    ) -> Result<crate::edition::EndorsementSet, ServerError> {
        let edition = self.standalone_editions.get(&edition_id)
            .ok_or(ServerError::NotFound(format!("edition {}", edition_id)))?;
        let mut result = edition.endorsements().clone();
        for (_, ws) in &self.works {
            let current_ed = ws.work.current_edition();
            if current_ed == edition {
                result = result.union(ws.work.endorsements());
            }
        }
        Ok(result)
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
        let peers = config.peers.iter().map(|p| {
            crate::server::federation::FederationPeerInfo {
                server_id: String::new(),
                address: p.clone(),
                connected: false,
            }
        }).collect();
        crate::server::federation::FederationInfo {
            server_id: identity.server_id.clone(),
            federation_domain: crate::crypto::FEDERATION_DOMAIN.to_string(),
            key_id: self.server_key_id(),
            signing_key: identity.signing_key_bytes().to_vec(),
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

    pub fn set_federation_config(&mut self, config: crate::server::federation::FederationConfig) {
        self.federation = crate::server::federation::FederationState::new(config);
    }

    pub fn federation_is_enabled(&self) -> bool {
        self.federation.is_enabled()
    }
}

#[cfg(feature = "server")]
mod persist_snapshot {
    use super::*;
    use crate::edition::persistent::{EditionSnapshot, WorkSnapshot};

    #[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
    struct WorkStateSnapshot {
        work: WorkSnapshot,
        grabber: Option<u64>,
        last_revision_author: Option<BeId>,
    }

    #[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
    struct ClubSnapshot {
        be_id: BeId,
        name: Option<String>,
        signature_club: Option<BeId>,
        work: WorkSnapshot,
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
    }

    impl Server {
        pub fn to_snapshot(&self) -> ServerSnapshot {
            let works = self.works.iter().map(|(id, ws)| {
                (*id, WorkStateSnapshot {
                    work: WorkSnapshot::from_work(&ws.work),
                    grabber: ws.grabber.map(|s| s.0),
                    last_revision_author: ws.last_revision_author,
                })
            }).collect();

            let clubs = self.clubs.iter().map(|(id, club)| {
                ClubSnapshot {
                    be_id: *id,
                    name: club.name().map(|s| s.to_string()),
                    signature_club: club.signature_club(),
                    work: WorkSnapshot::from_work(club.work()),
                }
            }).collect();

            let standalone_editions = self.standalone_editions.iter().map(|(id, ed)| {
                StandaloneEditionSnapshot {
                    be_id: *id,
                    edition: EditionSnapshot::from_edition(ed),
                }
            }).collect();

            ServerSnapshot {
                grand_map_id_counter: self.grand_map.id_counter(),
                session_counter: self.session_counter,
                operation_counter: self.operation_counter,
                system_clubs: self.system_clubs,
                works,
                clubs,
                standalone_editions,
                links: self.links.iter().map(|(id, ls)| LinkSnapshot {
                    link_id: *id,
                    origin: ls.origin,
                    destination: ls.destination,
                }).collect(),
                link_counter: self.link_counter,
                admin: AdminSnapshot {
                    accepting_connections: self.admin.is_accepting_connections(),
                    shutdown_requested: self.admin.is_shutdown_requested(),
                    grants: self.admin.grants().iter().map(|g| {
                        let (start, end) = g.region.as_interval().unwrap_or((0, 0));
                        (g.club_id, start, end)
                    }).collect(),
                },
            }
        }

        pub fn from_snapshot(snapshot: &ServerSnapshot) -> Self {
            let mut grand_map = GrandMap::new();
            grand_map.set_id_counter(snapshot.grand_map_id_counter);
            let server_kp = crate::crypto::keys::ServerKeyPair::generate("xudanu-server");

            let mut server = Server {
                grand_map,
                sessions: HashMap::new(),
                session_counter: snapshot.session_counter,
                clubs: HashMap::new(),
                club_names: HashMap::new(),
                works: HashMap::new(),
                standalone_editions: HashMap::new(),
                edition_detectors: HashMap::new(),
                system_clubs: snapshot.system_clubs,
                operation_counter: snapshot.operation_counter,
                admin: AdminState::new(),
                links: HashMap::new(),
                link_counter: snapshot.link_counter,
                transclusion_index: TransclusionIndex::new(),
                content_address: ContentAddressIndex::new(1_000_000),
                backfollow: BackfollowEngine::new(),
                blob_store: BlobStore::in_memory(),
                checkpoint_path: None,
                recorder_system: crate::edition::RecorderSystem::new(),
                start_time: std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_secs(),
                server_keypair: server_kp.clone(),
                key_history: crate::crypto::keys::KeyHistory::new(&server_kp),
                federation: crate::server::federation::FederationState::disabled(),
            };

            for club_snap in &snapshot.clubs {
                let work = club_snap.work.to_work(
                    crate::persist::FlockId::new(club_snap.be_id, 0),
                    None,
                ).work().clone();
                let mut club = Club::new_with_owner(
                    club_snap.be_id,
                    work.owner(),
                    work.edition().clone(),
                );
                club.set_signature_club(club_snap.signature_club);
                if let Some(ref name) = club_snap.name {
                    club.set_name(name.clone());
                    server.club_names.insert(name.clone(), club_snap.be_id);
                }
                server.clubs.insert(club_snap.be_id, club);
            }

            for (id, ws_snap) in &snapshot.works {
                let work = ws_snap.work.to_work(
                    crate::persist::FlockId::new(*id, 0),
                    None,
                ).work().clone();
                let ws = WorkState {
                    work,
                    grabber: None,
                    last_revision_author: ws_snap.last_revision_author,
                    status_detectors: DetectorList::new(),
                    revision_detectors: DetectorList::new(),
                };
                server.works.insert(*id, ws);
            }

            for se_snap in &snapshot.standalone_editions {
                let edition = se_snap.edition.to_edition();
                server.standalone_editions.insert(se_snap.be_id, edition);
            }

            server.admin.set_accepting_connections(snapshot.admin.accepting_connections);
            if snapshot.admin.shutdown_requested {
                server.admin.request_shutdown();
            }
            for (club_id, start, end) in &snapshot.admin.grants {
                server.admin.grant(*club_id, crate::edition::XnRegion::interval(*start, *end));
            }

            for ls in &snapshot.links {
                let o_ref = HyperRef::single(None, Some(ls.origin), None, None);
                let d_ref = HyperRef::single(None, Some(ls.destination), None, None);
                let link = HyperLink::make(vec![], o_ref, d_ref);
                server.links.insert(ls.link_id, LinkState {
                    link,
                    origin: ls.origin,
                    destination: ls.destination,
                });
            }

            for (wid, ws) in &server.works {
                let edition = ws.work.edition().clone();
                let elem = RangeElement::work(*wid);
                server.transclusion_index.register_work(&edition, &elem);
            }

            let max_id = server.works.keys().copied()
                .chain(server.clubs.keys().copied())
                .chain(server.links.keys().copied())
                .chain(server.standalone_editions.keys().copied())
                .max()
                .unwrap_or(0);
            if max_id >= server.grand_map.id_counter() {
                server.grand_map.set_id_counter(max_id + 1);
            }

            server
        }

        pub fn checkpoint_to_file(&self, path: &std::path::Path) -> std::io::Result<()> {
            let snapshot = self.to_snapshot();
            let json = serde_json::to_string_pretty(&snapshot)
                .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
            let tmp_path = path.with_extension("tmp");
            std::fs::write(&tmp_path, json.as_bytes())?;
            std::fs::rename(&tmp_path, path)
        }

        pub fn restore_from_file(path: &std::path::Path) -> std::io::Result<Self> {
            let json = std::fs::read_to_string(path)?;
            let snapshot: ServerSnapshot = serde_json::from_str(&json)
                .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
            Ok(Self::from_snapshot(&snapshot))
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
            while i + len < a_len && j + len < b_len
                && !matched_a[i + len] && !matched_b[j + len]
                && a_bytes[i + len] == b_bytes[j + len]
            {
                len += 1;
            }
            if len >= min_len {
                let shared = String::from_utf8_lossy(&a_bytes[i..i + len]).to_string();
                results.push((i as i64, (i + len) as i64, j as i64, (j + len) as i64, shared));
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
        let doc1 = server.create_work(sid, Edition::from_text("hello world")).unwrap();
        let doc2 = server.create_work(sid, Edition::from_text("hello universe")).unwrap();
        let doc3 = server.create_work(sid, Edition::from_text("goodbye world")).unwrap();

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
        let _doc = server.create_work(sid, Edition::from_text("abc hello def hello ghi")).unwrap();

        let results = server.find_text_transcluders("hello");
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].3.len(), 2);
        assert_eq!(results[0].3[0], (4, 9));
        assert_eq!(results[0].3[1], (14, 19));
    }

    #[test]
    fn find_text_transcluders_no_match() {
        let (mut server, sid) = setup();
        let _doc = server.create_work(sid, Edition::from_text("hello world")).unwrap();

        let results = server.find_text_transcluders("xyz");
        assert!(results.is_empty());
    }

    #[test]
    fn find_text_transcluders_returns_owner_and_revision_count() {
        let (mut server, sid) = setup();
        let doc = server.create_work(sid, Edition::from_text("hello")).unwrap();

        let results = server.find_text_transcluders("hello");
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].0, doc);
        assert!(results[0].1.is_some());
        assert_eq!(results[0].2, 0);
    }

    #[test]
    fn find_shared_regions_basic() {
        let (mut server, sid) = setup();
        let doc_a = server.create_work(sid, Edition::from_text("the quick brown fox")).unwrap();
        let doc_b = server.create_work(sid, Edition::from_text("a quick blue fox jumps")).unwrap();

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
    use super::*;
    use crate::edition::RangeElement;

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
        let lock = server.login_by_name(sid, "public").unwrap();
        let km = server.authenticate(sid, lock.as_ref(), &LockCredential::Boo).unwrap();
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

        let work_id = server.create_work(sid1, Edition::from_text("test")).unwrap();

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
        let work_id = server.create_work(sid, Edition::from_text("restricted")).unwrap();

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

        server.work_sponsor(work_id, club_id).unwrap();
        assert_eq!(server.work_sponsors(work_id).unwrap(), &[club_id]);

        server.work_unsponsor(work_id, club_id).unwrap();
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
                .work_revise(
                    sid,
                    work_id,
                    Edition::from_text(&format!("r{}", i)),
                )
                .unwrap();
        }

        assert_eq!(server.work_revision_count(work_id).unwrap(), 4);
        assert_eq!(
            server.work_fetch_revision(work_id, 0).unwrap().unwrap().to_text(),
            "r0"
        );
        assert_eq!(
            server.work_edition(work_id).unwrap().to_text(),
            "r4"
        );
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
                events_clone.lock().unwrap().push(event.clone());
            },
        ));
        server.add_revision_detector(work_id, detector).unwrap();

        server.work_grab(sid, work_id).unwrap();
        server
            .work_revise(sid, work_id, Edition::from_text("v1"))
            .unwrap();

        let captured = events.lock().unwrap();
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
                events_clone.lock().unwrap().push(event.clone());
            },
        ));
        server.add_status_detector(work_id, detector).unwrap();

        server.work_grab(sid, work_id).unwrap();
        server.work_release(sid, work_id).unwrap();

        let captured = events.lock().unwrap();
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

        let doc = server.create_work(alice, Edition::from_text("shared doc")).unwrap();

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
            server.work_fetch_revision(doc, 0).unwrap().unwrap().to_text(),
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
        let work_id = server.create_work(sid, Edition::from_text("owned")).unwrap();

        assert!(server.work_owner(work_id).unwrap().is_some());
        server
            .work_set_owner(sid, work_id, Some(club_id))
            .unwrap();
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
                events_clone.lock().unwrap().push(event.clone());
            },
        ));
        server.add_fill_detector(edition_id, detector).unwrap();

        server.fire_fill_event(edition_id, crate::edition::XnRegion::interval(0, 7));

        let captured = events.lock().unwrap();
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

        let lock = ChallengeLock::new(club_id, b"challenge_data".to_vec(), b"expected_response".to_vec());

        let result = lock.try_open(&LockCredential::ChallengeResponse(b"wrong".to_vec()));
        assert!(result.is_err());

        let km = lock
            .try_open(&LockCredential::ChallengeResponse(b"expected_response".to_vec()))
            .unwrap();
        assert!(km.has_authority(club_id));

        server.authenticate(sid, &lock, &LockCredential::ChallengeResponse(b"expected_response".to_vec())).unwrap();
        assert!(server.session(sid).unwrap().has_authority(club_id));
    }

    #[test]
    fn server_match_lock_workflow() {
        use crate::server::lock::{MatchLockSmith, LockSmith};

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

        server.authenticate(sid, lock.as_ref(), &LockCredential::Password(b"s3cret".to_vec())).unwrap();
        assert!(server.session(sid).unwrap().has_authority(club_id));
    }

    #[test]
    fn server_multi_lock_workflow() {
        use crate::server::lock::MultiLock;

        let club_a = 100u64;
        let club_b = 200u64;

        let ml = MultiLock::new(None)
            .with_sub_lock("boo".to_string(), Box::new(crate::server::lock::BooLock::new(club_a)))
            .with_sub_lock("wall".to_string(), Box::new(crate::server::lock::WallLock::new()));

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

        let doc = server.create_work(sid, Edition::from_text("Hello World")).unwrap();
        assert_eq!(server.work_edition(doc).unwrap().to_text(), "Hello World");
        assert_eq!(server.work_revision_count(doc).unwrap(), 0);

        server.work_grab(sid, doc).unwrap();
        let ed_v1 = server.work_edition(doc).unwrap();
        let ed_v2 = ed_v1.with(5, RangeElement::text("X"));
        server.work_revise(sid, doc, ed_v2).unwrap();
        assert_eq!(server.work_edition(doc).unwrap().to_text(), "HelloXWorld");

        let ed_v3 = Edition::from_text("Completely new content");
        server.work_revise(sid, doc, ed_v3).unwrap();
        assert_eq!(server.work_edition(doc).unwrap().to_text(), "Completely new content");

        assert_eq!(server.work_revision_count(doc).unwrap(), 2);
        assert_eq!(
            server.work_fetch_revision(doc, 0).unwrap().unwrap().to_text(),
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

        server.work_revise(s1, doc1, Edition::from_text("doc1 v2")).unwrap();
        server.work_revise(s2, doc2, Edition::from_text("doc2 v2")).unwrap();

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
                "xudanu_server_test_{}_{}", name, std::process::id()
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
            doc_id = server.create_work(sid, Edition::from_text("hello world")).unwrap();
            server.checkpoint_to_file(&dir.snapshot_path()).unwrap();
        }
        {
            let mut server = Server::restore_from_file(&dir.snapshot_path()).unwrap();
            assert_eq!(server.work_count(), 1);
            assert_eq!(server.work_edition(doc_id).unwrap().to_text(), "hello world");
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
            server.work_revise(sid, doc_id, Edition::from_text("v2")).unwrap();
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
            assert!(new_id > last_id, "new id {} should be > last {}", new_id, last_id);
        }
    }

    #[test]
    fn blob_upload_and_get() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let meta = server.blob_upload(sid, b"hello blob".to_vec(), "text/plain".to_string()).unwrap();
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
        let m1 = server.blob_upload(sid, b"same".to_vec(), "text/plain".to_string()).unwrap();
        let m2 = server.blob_upload(sid, b"same".to_vec(), "text/plain".to_string()).unwrap();
        assert_eq!(m1.hash_u64(), m2.hash_u64());
    }

    #[test]
    fn blob_exists() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let meta = server.blob_upload(sid, b"data".to_vec(), "text/plain".to_string()).unwrap();
        assert!(server.blob_exists(meta.hash_u64()));
        assert!(!server.blob_exists(99999));
    }

    #[test]
    fn blob_info() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let meta = server.blob_upload(sid, b"info test".to_vec(), "image/png".to_string()).unwrap();
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
        server.blob_upload(sid, b"aaa".to_vec(), "text/plain".to_string()).unwrap();
        let (blobs, bytes) = server.blob_stats();
        assert_eq!(blobs, 1);
        assert_eq!(bytes, 3);
    }

    #[test]
    fn find_structural_shared_regions_basic() {
        let (mut server, sid) = setup_logged_in_server();
        let doc1 = server.create_work(sid, Edition::from_text("hello world")).unwrap();
        let doc2 = server.create_work(sid, Edition::from_text("say hello world now")).unwrap();
        let regions = server.find_shared_regions(doc1, doc2);
        assert!(!regions.is_empty());
        let has_hello = regions.iter().any(|(_, _, _, _, t)| t.contains("hello") || t.contains("world"));
        assert!(has_hello, "expected shared text containing 'hello' or 'world': {:?}", regions);
    }

    #[test]
    fn find_structural_shared_regions_identical() {
        let (mut server, sid) = setup_logged_in_server();
        let doc1 = server.create_work(sid, Edition::from_text("same content")).unwrap();
        let doc2 = server.create_work(sid, Edition::from_text("same content")).unwrap();
        let regions = server.find_shared_regions(doc1, doc2);
        assert_eq!(regions.len(), 1);
        assert_eq!(regions[0].4, "same content");
    }

    #[test]
    fn find_structural_shared_regions_empty() {
        let (mut server, sid) = setup_logged_in_server();
        let doc1 = server.create_work(sid, Edition::from_text("hello")).unwrap();
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
        let doc1 = server.create_work(sid, Edition::from_text_elements(&[
            RangeElement::text("a"),
            RangeElement::text("b"),
            RangeElement::Blob { content_hash: 42, mime_type: "image/png".into(), byte_size: 100, width: Some(10), height: Some(10) },
            RangeElement::text("c"),
        ])).unwrap();
        let doc2 = server.create_work(sid, Edition::from_text_elements(&[
            RangeElement::text("x"),
            RangeElement::text("b"),
            RangeElement::Blob { content_hash: 42, mime_type: "image/png".into(), byte_size: 100, width: Some(10), height: Some(10) },
            RangeElement::text("c"),
        ])).unwrap();
        let regions = server.find_shared_regions(doc1, doc2);
        assert!(!regions.is_empty(), "structural comparison should find shared blob+text run");
    }

    #[test]
    fn content_address_same_text_same_be_id() {
        let (mut server, sid) = setup_logged_in_server();
        server.create_work(sid, Edition::from_text("hello")).unwrap();
        let id_first = server.content_address_lookup(&RangeElement::text("h")).unwrap();
        server.create_work(sid, Edition::from_text("hippo")).unwrap();
        let id_second = server.content_address_lookup(&RangeElement::text("h")).unwrap();
        assert_eq!(id_first, id_second, "'h' should have the same canonical BeId across documents");
    }

    #[test]
    fn content_address_different_text_different_be_id() {
        let (mut server, sid) = setup_logged_in_server();
        server.create_work(sid, Edition::from_text("abc")).unwrap();
        let id_a = server.content_address_lookup(&RangeElement::text("a")).unwrap();
        let id_b = server.content_address_lookup(&RangeElement::text("b")).unwrap();
        assert_ne!(id_a, id_b);
    }

    #[test]
    fn content_address_across_revisions() {
        let (mut server, sid) = setup_logged_in_server();
        let doc = server.create_work(sid, Edition::from_text("abc")).unwrap();
        let id_before = server.content_address_lookup(&RangeElement::text("a")).unwrap();
        server.work_grab(sid, doc).unwrap();
        server.work_revise(sid, doc, Edition::from_text("axc")).unwrap();
        let id_after = server.content_address_lookup(&RangeElement::text("a")).unwrap();
        assert_eq!(id_before, id_after, "'a' identity should be stable across revisions");
    }

    #[test]
    fn content_address_transclusion_finds_cross_document() {
        let (mut server, sid) = setup_logged_in_server();
        let _doc1 = server.create_work(sid, Edition::from_text("shared phrase here")).unwrap();
        let _doc2 = server.create_work(sid, Edition::from_text("shared phrase there")).unwrap();
        let results = server.find_text_transcluders("shared phrase");
        assert_eq!(results.len(), 2, "should find 'shared phrase' in both documents");
    }

    #[test]
    fn content_address_count_grows() {
        let (mut server, sid) = setup_logged_in_server();
        assert_eq!(server.content_address_count(), 0);
        server.create_work(sid, Edition::from_text("hello")).unwrap();
        let count1 = server.content_address_count();
        assert!(count1 > 0);
        server.create_work(sid, Edition::from_text("hello")).unwrap();
        assert_eq!(server.content_address_count(), count1, "duplicate doc should not increase count");
        server.create_work(sid, Edition::from_text("world")).unwrap();
        assert!(server.content_address_count() > count1);
    }
}
