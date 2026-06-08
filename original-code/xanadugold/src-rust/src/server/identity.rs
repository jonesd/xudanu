use std::time::Duration;

use super::club::{Club, Credential};
use super::error::ServerError;
use super::keymaster::KeyMaster;
use super::lock::{Lock, LockCredential, LockSmith};
use super::server::Server;
use super::session::SessionId;
use crate::crypto::club_keys::{decrypt_signing_key, encrypt_signing_key, generate_club_keypair};
use crate::edition::{BeId, Edition};

macro_rules! security_info {
    ($($arg:tt)*) => {
        tracing::info!(target: "xudanu::security", $($arg)*)
    };
}

macro_rules! security_warn {
    ($($arg:tt)*) => {
        tracing::warn!(target: "xudanu::security", $($arg)*)
    };
}

const MAX_PASSWORD_LEN: usize = 256;
const MIN_PASSWORD_LEN: usize = 10;
const MAX_CLUB_LOGIN_ATTEMPTS: u32 = 10;
const CLUB_LOGIN_ATTEMPT_WINDOW: Duration = Duration::from_secs(300);

#[derive(Debug, Clone)]
pub struct ClubAttemptTracker {
    pub count: u32,
    pub window_start: std::time::Instant,
}

impl Server {
    pub fn club_set_password(
        &mut self,
        session_id: SessionId,
        club_id: BeId,
        password: &[u8],
    ) -> Result<(), ServerError> {
        self.ensure_logged_in(session_id)?;
        if password.len() < MIN_PASSWORD_LEN {
            return Err(ServerError::InvalidArgument(format!(
                "password too short (min {} byte)",
                MIN_PASSWORD_LEN
            )));
        }
        if password.len() > MAX_PASSWORD_LEN {
            return Err(ServerError::InvalidArgument(format!(
                "password too long (max {} bytes)",
                MAX_PASSWORD_LEN
            )));
        }
        if !self.session(session_id)?.has_authority(club_id) {
            let session = self.session(session_id)?;
            let km = session._key_master().ok_or(ServerError::NotAuthorized)?;
            if !km.has_signature_authority(club_id, &self.clubs) {
                return Err(ServerError::NotAuthorized);
            }
        }
        let phc_hash = crate::crypto::password::hash_password(password)
            .map_err(|e| ServerError::Internal(format!("password hash failed: {}", e)))?;
        let is_personal = self
            .clubs
            .get(&club_id)
            .ok_or(ServerError::ClubNotFound(club_id))?
            .is_personal();

        let club = self
            .clubs
            .get_mut(&club_id)
            .ok_or(ServerError::ClubNotFound(club_id))?;
        club.set_credential(Some(Credential::Password { phc_hash }));
        self.dirty_clubs.insert(club_id);

        if is_personal {
            let existing_key = self
                .sessions
                .get(&session_id)
                .ok_or(ServerError::SessionNotFound(session_id))?
                .club_signing_key()
                .cloned();

            if let Some(sk) = existing_key {
                let encrypted = encrypt_signing_key(&sk, password).map_err(|e| {
                    ServerError::Internal(format!("club key re-encryption failed: {}", e))
                })?;
                club.set_encrypted_signing_key(Some(encrypted));
            } else if club.encrypted_signing_key().is_none() {
                let (encrypted, signing_key) = generate_club_keypair(password).map_err(|e| {
                    ServerError::Internal(format!("club key generation failed: {}", e))
                })?;
                club.set_encrypted_signing_key(Some(encrypted));
                let session = self
                    .sessions
                    .get_mut(&session_id)
                    .ok_or(ServerError::SessionNotFound(session_id))?;
                session.set_club_signing_key(Some(signing_key));
            }
        }

        Ok(())
    }

    pub fn club_clear_credential(
        &mut self,
        session_id: SessionId,
        club_id: BeId,
    ) -> Result<(), ServerError> {
        self.ensure_logged_in(session_id)?;
        if !self.session(session_id)?.has_authority(club_id) {
            let session = self.session(session_id)?;
            let km = session._key_master().ok_or(ServerError::NotAuthorized)?;
            if !km.has_signature_authority(club_id, &self.clubs) {
                return Err(ServerError::NotAuthorized);
            }
        }
        let verifying_key = self
            .clubs
            .get(&club_id)
            .ok_or(ServerError::ClubNotFound(club_id))?
            .encrypted_signing_key()
            .map(|e| e.verifying_key);
        let club = self
            .clubs
            .get_mut(&club_id)
            .ok_or(ServerError::ClubNotFound(club_id))?;
        club.set_credential(None);
        club.set_encrypted_signing_key(None);
        self.dirty_clubs.insert(club_id);
        security_info!(
            club_id = ?club_id,
            session_id = session_id.as_u64(),
            had_signing_key = verifying_key.is_some(),
            event = "SECURITY:credential_cleared",
            "credential cleared"
        );
        if let Some(vk_bytes) = verifying_key {
            for session in self.sessions.values_mut() {
                if session
                    .club_verifying_key()
                    .map(|vk| vk.to_bytes() == vk_bytes)
                    .unwrap_or(false)
                {
                    session.set_club_signing_key(None);
                }
            }
        }
        Ok(())
    }

    // === Personal clubs (user accounts) ===

    pub fn create_personal_club(
        &mut self,
        session_id: SessionId,
        display_name: String,
        credential: Option<Credential>,
        raw_password: Option<Vec<u8>>,
    ) -> Result<BeId, ServerError> {
        self.ensure_logged_in(session_id)?;

        if self.personal_club_count >= self.max_personal_clubs {
            return Err(ServerError::InvalidArgument(format!(
                "personal club limit reached (max {})",
                self.max_personal_clubs
            )));
        }

        if self.club_names.contains_key(&display_name) {
            return Err(ServerError::AlreadyExists(format!(
                "club name '{}' already taken",
                display_name
            )));
        }

        let session = self.session(session_id)?;
        let authority = session.authority_clubs();
        let already_has_personal = authority
            .iter()
            .any(|id| self.clubs.get(id).map(|c| c.is_personal()).unwrap_or(false));
        if already_has_personal {
            return Err(ServerError::AlreadyExists(
                "session already has a personal club".into(),
            ));
        }

        let (be_id, elem) = self.grand_map.new_work_element(None);
        self.grand_map.assign_new_id(elem);

        let owner = self.session(session_id)?.initial_login();
        let description = Edition::from_text(&format!("personal club: {}", display_name));
        let mut club = Club::new_personal(
            be_id,
            owner,
            description,
            Some(display_name.clone()),
            credential,
        );
        club.set_name(display_name.clone());
        club.set_read_club(Some(be_id));
        club.set_edit_club(Some(be_id));

        if let Some(ref password) = raw_password {
            let (encrypted, signing_key) = generate_club_keypair(password)
                .map_err(|e| ServerError::Internal(format!("club key generation failed: {}", e)))?;
            club.set_encrypted_signing_key(Some(encrypted));
            let session = self
                .sessions
                .get_mut(&session_id)
                .ok_or(ServerError::SessionNotFound(session_id))?;
            session.set_club_signing_key(Some(signing_key));
        }

        self.clubs.insert(be_id, club);
        self.dirty_clubs.insert(be_id);
        self.club_names.insert(display_name, be_id);
        self.personal_club_count += 1;

        let session = self
            .sessions
            .get_mut(&session_id)
            .ok_or(ServerError::SessionNotFound(session_id))?;
        let km = KeyMaster::make(be_id);
        session.incorporate_authority(&km);

        Ok(be_id)
    }

    pub fn create_personal_club_from_oauth(
        &mut self,
        session_id: SessionId,
        display_name: String,
    ) -> Result<BeId, ServerError> {
        self.ensure_logged_in(session_id)?;

        if self.personal_club_count >= self.max_personal_clubs {
            return Err(ServerError::InvalidArgument(format!(
                "personal club limit reached (max {})",
                self.max_personal_clubs
            )));
        }

        let mut name = display_name.clone();
        let mut suffix: u32 = 0;
        while self.club_names.contains_key(&name) {
            suffix += 1;
            name = format!("{}-{}", display_name, suffix);
        }

        let (be_id, elem) = self.grand_map.new_work_element(None);
        self.grand_map.assign_new_id(elem);

        let owner = self.session(session_id)?.initial_login();
        let description = Edition::from_text(&format!("personal club: {}", name));
        let mut club = Club::new_personal(be_id, owner, description, Some(name.clone()), None);
        club.set_name(name.clone());
        club.set_read_club(Some(be_id));
        club.set_edit_club(Some(be_id));

        self.clubs.insert(be_id, club);
        self.dirty_clubs.insert(be_id);
        self.club_names.insert(name, be_id);
        self.personal_club_count += 1;

        let session = self
            .sessions
            .get_mut(&session_id)
            .ok_or(ServerError::SessionNotFound(session_id))?;
        let km = KeyMaster::make(be_id);
        session.incorporate_authority(&km);

        Ok(be_id)
    }

    pub fn authenticate_session_from_oauth(
        &mut self,
        session_id: SessionId,
        club_id: BeId,
        signing_key_bytes: Option<Vec<u8>>,
    ) -> Result<(), ServerError> {
        let session = self
            .sessions
            .get_mut(&session_id)
            .ok_or(ServerError::SessionNotFound(session_id))?;
        let km = KeyMaster::make(club_id);
        session.set_key_master(km);
        if let Some(bytes) = signing_key_bytes {
            if bytes.len() == 32 {
                let arr: [u8; 32] = bytes.try_into().unwrap();
                let signing_key = ed25519_dalek::SigningKey::from_bytes(&arr);
                session.set_club_signing_key(Some(signing_key));
            }
        }
        Ok(())
    }

    pub fn who_am_i(&self, session_id: SessionId) -> Result<Vec<(BeId, String)>, ServerError> {
        self.ensure_logged_in(session_id)?;
        let session = self.session(session_id)?;
        let mut result = Vec::new();
        let authority = session.authority_clubs();
        for club_id in &authority {
            if let Some(club) = self.clubs.get(club_id) {
                if club.is_personal() {
                    let name = club
                        .display_name()
                        .or(club.name())
                        .unwrap_or("")
                        .to_string();
                    result.push((*club_id, name));
                }
            }
        }
        Ok(result)
    }

    // === Club membership ===

    pub fn club_add_member(
        &mut self,
        session_id: SessionId,
        club_id: BeId,
        member_id: BeId,
    ) -> Result<(), ServerError> {
        self.ensure_logged_in(session_id)?;
        let has_auth = {
            let session = self.session(session_id)?;
            let km = session._key_master().ok_or(ServerError::NotAuthorized)?;
            km.has_signature_authority(club_id, &self.clubs) || km.has_authority(club_id)
        };
        if !has_auth {
            return Err(ServerError::NotAuthorized);
        }
        if !self.clubs.contains_key(&member_id) {
            return Err(ServerError::ClubNotFound(member_id));
        }
        let club = self
            .clubs
            .get_mut(&club_id)
            .ok_or(ServerError::ClubNotFound(club_id))?;
        club.add_member(member_id);
        self.dirty_clubs.insert(club_id);
        self.refresh_all_session_authority();
        Ok(())
    }

    pub fn club_remove_member(
        &mut self,
        session_id: SessionId,
        club_id: BeId,
        member_id: BeId,
    ) -> Result<(), ServerError> {
        self.ensure_logged_in(session_id)?;
        let has_auth = {
            let session = self.session(session_id)?;
            let km = session._key_master().ok_or(ServerError::NotAuthorized)?;
            km.has_signature_authority(club_id, &self.clubs) || km.has_authority(club_id)
        };
        if !has_auth {
            return Err(ServerError::NotAuthorized);
        }
        let club = self
            .clubs
            .get_mut(&club_id)
            .ok_or(ServerError::ClubNotFound(club_id))?;
        club.remove_member(member_id);
        self.dirty_clubs.insert(club_id);
        self.refresh_all_session_authority();
        Ok(())
    }

    pub fn club_members(
        &self,
        session_id: SessionId,
        club_id: BeId,
    ) -> Result<Vec<BeId>, ServerError> {
        self.ensure_logged_in(session_id)?;
        let session = self.session(session_id)?;
        let club = self.club(club_id)?;
        let authorized = session.has_authority(club_id)
            || club
                .read_club()
                .map_or(false, |rc| session.has_authority(rc))
            || club
                .edit_club()
                .map_or(false, |ec| session.has_authority(ec))
            || club
                .default_read_club()
                .map_or(false, |rc| session.has_authority(rc))
            || club
                .default_edit_club()
                .map_or(false, |ec| session.has_authority(ec));
        if !authorized {
            return Err(ServerError::NotAuthorized);
        }
        drop(session);
        drop(club);
        let club = self.club(club_id)?;
        Ok(club.members().iter().copied().collect())
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

        let lock: Box<dyn Lock> = match club.credential() {
            Some(Credential::Password { phc_hash }) => {
                let smith = super::lock::MatchLockSmith::from_phc_hash(phc_hash.clone());
                smith.create_lock(Some(club_id))
            }
            Some(Credential::PublicKey { verifying_key }) => {
                let smith = super::lock::ChallengeLockSmith::new(*verifying_key);
                smith.create_lock(Some(club_id))
            }
            None => super::lock::WallLock::new().clone_boxed(),
        };

        let session = self
            .sessions
            .get_mut(&session_id)
            .ok_or(ServerError::SessionNotFound(session_id))?;
        session.set_pending_lock(lock.clone_boxed(), club_id);

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
        let mut km = lock.try_open(credential)?;
        km.update_authority(&self.clubs);
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

    pub fn authenticate_with_pending(
        &mut self,
        session_id: SessionId,
        credential: &LockCredential,
    ) -> Result<KeyMaster, ServerError> {
        self.ensure_session(session_id)?;
        let (lock, club_id) = {
            let session = self
                .sessions
                .get_mut(&session_id)
                .ok_or(ServerError::SessionNotFound(session_id))?;
            if let Some(club_id) = session.pending_lock_club() {
                let now = std::time::Instant::now();
                if let Some(tracker) = self.login_attempts.get_mut(&club_id) {
                    if now.duration_since(tracker.window_start) > CLUB_LOGIN_ATTEMPT_WINDOW {
                        tracker.count = 0;
                        tracker.window_start = now;
                    }
                    if tracker.count >= MAX_CLUB_LOGIN_ATTEMPTS {
                        security_warn!(
                            club_id = ?club_id,
                            session_id = session_id.as_u64(),
                            attempts = tracker.count,
                            event = "SECURITY:login_rate_limited",
                            "login rate limited"
                        );
                        return Err(ServerError::Unauthorized(
                            "too many login attempts for this account, try again later".into(),
                        ));
                    }
                }
            }
            session
                .take_pending_lock()
                .ok_or(ServerError::InvalidArgument(
                    "no pending login; call login() first".into(),
                ))?
        };
        match self.authenticate(session_id, lock.as_ref(), credential) {
            Ok(km) => {
                self.login_attempts.remove(&club_id);
                security_info!(
                    club_id = ?club_id,
                    session_id = session_id.as_u64(),
                    event = "SECURITY:login_succeeded",
                    "login succeeded"
                );
                if let LockCredential::Password(ref password_bytes) = credential {
                    if let Some(club) = self.clubs.get(&club_id) {
                        if let Some(encrypted_key) = club.encrypted_signing_key() {
                            match decrypt_signing_key(encrypted_key, password_bytes) {
                                Ok(signing_key) => {
                                    if let Some(session) = self.sessions.get_mut(&session_id) {
                                        session.set_club_signing_key(Some(signing_key));
                                    }
                                }
                                Err(e) => {
                                    security_warn!(
                                        club_id = ?club_id,
                                        error = %e,
                                        event = "SECURITY:signing_key_decrypt_failed",
                                        "failed to decrypt club signing key"
                                    );
                                }
                            }
                        }
                    }
                }
                Ok(km)
            }
            Err(e) => {
                let now = std::time::Instant::now();
                let tracker = self
                    .login_attempts
                    .entry(club_id)
                    .or_insert(ClubAttemptTracker {
                        count: 0,
                        window_start: now,
                    });
                if now.duration_since(tracker.window_start) > CLUB_LOGIN_ATTEMPT_WINDOW {
                    tracker.count = 0;
                    tracker.window_start = now;
                }
                tracker.count += 1;
                security_warn!(
                    club_id = ?club_id,
                    session_id = session_id.as_u64(),
                    attempt = tracker.count,
                    error = %e,
                    event = "SECURITY:login_failed",
                    "login failed"
                );
                Err(e)
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::Edition;
    use crate::server::lock::LockCredential;

    fn setup_logged_in() -> (Server, SessionId) {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        (server, sid)
    }

    #[test]
    fn password_protected_club_login_succeeds_with_correct_password() {
        let (mut server, sid) = setup_logged_in();
        let club_id = server
            .create_personal_club(sid, "alice".to_string(), None, None)
            .unwrap();
        server
            .club_set_password(sid, club_id, b"secret1234")
            .unwrap();

        let sid2 = server.connect();
        let _lock = server.login(sid2, club_id).unwrap();
        let km = server
            .authenticate_with_pending(sid2, &LockCredential::Password(b"secret1234".to_vec()))
            .unwrap();
        assert!(km.has_authority(club_id));
    }

    #[test]
    fn password_protected_club_login_fails_with_wrong_password() {
        let (mut server, sid) = setup_logged_in();
        let club_id = server
            .create_personal_club(sid, "alice".to_string(), None, None)
            .unwrap();
        server
            .club_set_password(sid, club_id, b"secret1234")
            .unwrap();

        let sid2 = server.connect();
        let _lock = server.login(sid2, club_id).unwrap();
        let result =
            server.authenticate_with_pending(sid2, &LockCredential::Password(b"wrong".to_vec()));
        assert!(result.is_err());
    }

    #[test]
    fn authenticate_without_login_fails() {
        let mut server = Server::new();
        let sid = server.connect();
        let result = server.authenticate_with_pending(sid, &LockCredential::Boo);
        assert!(result.is_err());
    }

    #[test]
    fn public_club_login_still_works() {
        let mut server = Server::new();
        let sid = server.connect();
        let km = server.login_public(sid).unwrap();
        assert!(km.has_authority(server.public_club_id()));
    }

    #[test]
    fn create_personal_club_with_password() {
        let (mut server, sid) = setup_logged_in();
        let phc_hash = crate::crypto::password::hash_password(b"mypassword").unwrap();
        let club_id = server
            .create_personal_club(
                sid,
                "bob".to_string(),
                Some(Credential::Password { phc_hash }),
                Some(b"secret1234".to_vec()),
            )
            .unwrap();

        let club = server.club(club_id).unwrap();
        assert!(club.is_personal());
        assert_eq!(club.display_name(), Some("bob"));

        let sid2 = server.connect();
        let _lock = server.login(sid2, club_id).unwrap();
        let km = server
            .authenticate_with_pending(sid2, &LockCredential::Password(b"mypassword".to_vec()))
            .unwrap();
        assert!(km.has_authority(club_id));
    }

    #[test]
    fn who_ami_returns_personal_clubs() {
        let (mut server, sid) = setup_logged_in();
        let club_id = server
            .create_personal_club(sid, "alice".to_string(), None, None)
            .unwrap();

        let result = server.who_am_i(sid).unwrap();
        assert!(result
            .iter()
            .any(|(id, name)| *id == club_id && name == "alice"));
    }

    #[test]
    fn club_clear_credential_removes_password() {
        let (mut server, sid) = setup_logged_in();
        let club_id = server
            .create_personal_club(sid, "charlie".to_string(), None, None)
            .unwrap();
        server
            .club_set_password(sid, club_id, b"password1")
            .unwrap();
        assert!(server.club(club_id).unwrap().credential().is_some());

        server.club_clear_credential(sid, club_id).unwrap();
        assert!(server.club(club_id).unwrap().credential().is_none());
    }

    #[test]
    fn set_password_requires_authority() {
        let (mut server, sid) = setup_logged_in();
        let alice_id = server
            .create_personal_club(sid, "alice".to_string(), None, None)
            .unwrap();
        server
            .club_set_password(sid, alice_id, b"alicepass1")
            .unwrap();

        let sid_alice = server.connect();
        let _lock = server.login(sid_alice, alice_id).unwrap();
        server
            .authenticate_with_pending(sid_alice, &LockCredential::Password(b"alicepass1".to_vec()))
            .unwrap();
        let club_id = server
            .create_club(sid_alice, Edition::from_text("target"))
            .unwrap();

        let sid2 = server.connect();
        server.login_public(sid2).unwrap();
        let result = server.club_set_password(sid2, club_id, b"hacked1234");
        assert!(result.is_err());
    }

    #[test]
    fn login_stores_pending_lock_on_session() {
        let mut server = Server::new();
        let sid = server.connect();
        let _lock = server.login(sid, server.public_club_id()).unwrap();

        let session = server.session(sid).unwrap();
        assert_eq!(session.pending_lock_club(), Some(server.public_club_id()));
    }

    #[test]
    fn crdt_author_auto_assigned_from_session() {
        let (mut server, sid) = setup_logged_in();
        let club_id = server
            .create_personal_club(sid, "alice".to_string(), None, None)
            .unwrap();

        let work_id = server
            .create_work(sid, crate::edition::Edition::from_text("hello"))
            .unwrap();
        let _result = server.crdt_open_session(sid, work_id).unwrap();

        let author = server.otree_crdt.get_author(work_id, sid).unwrap().unwrap();
        let mut expected_key = [0u8; 32];
        expected_key[..8].copy_from_slice(&club_id.to_le_bytes());
        assert_eq!(author.public_key, expected_key);
        assert_eq!(author.display_name, "alice");
    }

    #[test]
    fn crdt_author_assigned_for_public_login() {
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();

        let work_id = server
            .create_work(sid, crate::edition::Edition::from_text("hello"))
            .unwrap();
        let _result = server.crdt_open_session(sid, work_id).unwrap();

        let author = server.otree_crdt.get_author(work_id, sid).unwrap().unwrap();
        let public_id = server.public_club_id();
        let mut expected_key = [0u8; 32];
        expected_key[..8].copy_from_slice(&public_id.to_le_bytes());
        assert_eq!(author.public_key, expected_key);
    }

    #[test]
    fn club_add_and_remove_member() {
        let (mut server, sid) = setup_logged_in();
        let group_id = server
            .create_named_club(sid, "team", Edition::from_text("team"))
            .unwrap();
        let alice_id = server
            .create_personal_club(sid, "alice".to_string(), None, None)
            .unwrap();

        server.club_add_member(sid, group_id, alice_id).unwrap();
        assert!(server.club(group_id).unwrap().is_member(alice_id));

        let members = server.club_members(sid, group_id).unwrap();
        assert!(members.contains(&alice_id));

        server.club_remove_member(sid, group_id, alice_id).unwrap();
        assert!(!server.club(group_id).unwrap().is_member(alice_id));
    }

    #[test]
    fn club_add_member_requires_authority() {
        let (mut server, sid) = setup_logged_in();
        let group_id = server
            .create_named_club(sid, "team", Edition::from_text("team"))
            .unwrap();

        let sid2 = server.connect();
        server.login_public(sid2).unwrap();
        let result = server.club_add_member(sid2, group_id, 999);
        assert!(result.is_err());
    }

    #[test]
    fn club_membership_grants_transitive_authority() {
        let (mut server, sid) = setup_logged_in();
        let group_id = server
            .create_named_club(sid, "team", Edition::from_text("team"))
            .unwrap();
        server
            .club_add_member(sid, group_id, server.public_club_id())
            .unwrap();

        let members = server.club(group_id).unwrap().members();
        assert!(members.contains(&server.public_club_id()));
    }

    #[test]
    fn create_second_personal_club_fails() {
        let (mut server, sid) = setup_logged_in();
        server
            .create_personal_club(sid, "alice".to_string(), None, None)
            .unwrap();
        let result = server.create_personal_club(sid, "alice2".to_string(), None, None);
        assert!(result.is_err());
    }

    #[test]
    fn create_personal_club_with_existing_name_fails() {
        let (mut server, sid) = setup_logged_in();
        server
            .create_personal_club(sid, "alice".to_string(), None, None)
            .unwrap();

        let sid2 = server.connect();
        server.login_public(sid2).unwrap();
        let result = server.create_personal_club(sid2, "alice".to_string(), None, None);
        assert!(result.is_err());
    }

    #[test]
    fn login_rate_limited_after_max_attempts() {
        let (mut server, sid) = setup_logged_in();
        let club_id = server
            .create_personal_club(sid, "alice".to_string(), None, None)
            .unwrap();
        server
            .club_set_password(sid, club_id, b"secret12345")
            .unwrap();

        let sid2 = server.connect();
        for _ in 0..10 {
            let _lock = server.login(sid2, club_id).unwrap();
            let _ = server
                .authenticate_with_pending(sid2, &LockCredential::Password(b"wrongxxx".to_vec()));
        }

        let _lock = server.login(sid2, club_id).unwrap();
        let result = server
            .authenticate_with_pending(sid2, &LockCredential::Password(b"secret12345".to_vec()));
        assert!(result.is_err(), "11th attempt should be rate limited");
    }

    #[test]
    fn login_rate_limit_persists_across_sessions() {
        let (mut server, sid) = setup_logged_in();
        let club_id = server
            .create_personal_club(sid, "alice".to_string(), None, None)
            .unwrap();
        server
            .club_set_password(sid, club_id, b"secret12345")
            .unwrap();

        for i in 0..10 {
            let fresh_sid = server.connect();
            let _lock = server.login(fresh_sid, club_id).unwrap();
            let _ = server.authenticate_with_pending(
                fresh_sid,
                &LockCredential::Password(b"wrongxxx".to_vec()),
            );
            if i < 9 {
                assert!(server.login_attempts.get(&club_id).unwrap().count == (i + 1) as u32);
            }
        }

        let fresh_sid = server.connect();
        let _lock = server.login(fresh_sid, club_id).unwrap();
        let result = server.authenticate_with_pending(
            fresh_sid,
            &LockCredential::Password(b"secret12345".to_vec()),
        );
        assert!(
            result.is_err(),
            "rate limit should persist across new sessions"
        );
    }

    #[test]
    fn login_rate_limit_resets_on_success() {
        let (mut server, sid) = setup_logged_in();
        let club_id = server
            .create_personal_club(sid, "alice".to_string(), None, None)
            .unwrap();
        server
            .club_set_password(sid, club_id, b"secret12345")
            .unwrap();

        let sid2 = server.connect();
        for _ in 0..9 {
            let _lock = server.login(sid2, club_id).unwrap();
            let _ = server
                .authenticate_with_pending(sid2, &LockCredential::Password(b"wrongxxx".to_vec()));
        }

        let _lock = server.login(sid2, club_id).unwrap();
        let result = server
            .authenticate_with_pending(sid2, &LockCredential::Password(b"secret12345".to_vec()));
        assert!(
            result.is_ok(),
            "10th attempt with correct password should succeed and reset"
        );
        assert!(
            server.login_attempts.get(&club_id).is_none(),
            "success clears tracker"
        );
    }

    #[test]
    fn session_ids_are_not_sequential() {
        let mut server = Server::new();
        let id1 = server.connect().as_u64();
        let id2 = server.connect().as_u64();
        let id3 = server.connect().as_u64();
        assert_ne!(id1, id2);
        assert_ne!(id2, id3);
        assert_ne!(id1, id3);
        assert!(!((id1 as i64) - (id2 as i64)).abs() < 10);
    }

    #[test]
    fn personal_club_with_password_gets_signing_key() {
        let (mut server, sid) = setup_logged_in();
        let phc_hash = crate::crypto::password::hash_password(b"testpass").unwrap();
        let club_id = server
            .create_personal_club(
                sid,
                "keyowner".to_string(),
                Some(Credential::Password { phc_hash }),
                Some(b"testpass".to_vec()),
            )
            .unwrap();

        let club = server.club(club_id).unwrap();
        assert!(
            club.encrypted_signing_key().is_some(),
            "personal club with password should have encrypted signing key"
        );

        let session = server.sessions.get(&sid).unwrap();
        assert!(
            session.club_signing_key().is_some(),
            "session should have decrypted signing key after creation"
        );

        let verifying_key = session.club_verifying_key().unwrap();
        let encrypted = club.encrypted_signing_key().unwrap();
        assert_eq!(
            verifying_key.to_bytes(),
            encrypted.verifying_key,
            "session key should match stored verifying key"
        );
    }

    #[test]
    fn login_decrypts_signing_key() {
        let (mut server, sid) = setup_logged_in();
        let phc_hash = crate::crypto::password::hash_password(b"mypass").unwrap();
        let club_id = server
            .create_personal_club(
                sid,
                "decryptor".to_string(),
                Some(Credential::Password { phc_hash }),
                Some(b"mypass".to_vec()),
            )
            .unwrap();

        let sid2 = server.connect();
        server.login_public(sid2).unwrap();
        let _lock = server.login(sid2, club_id).unwrap();
        let _km = server
            .authenticate_with_pending(sid2, &LockCredential::Password(b"mypass".to_vec()))
            .unwrap();

        let session = server.sessions.get(&sid2).unwrap();
        assert!(
            session.club_signing_key().is_some(),
            "login should decrypt and store signing key on session"
        );
    }

    #[test]
    fn set_password_on_personal_club_generates_key() {
        let (mut server, sid) = setup_logged_in();
        let club_id = server
            .create_personal_club(sid, "latekey".to_string(), None, None)
            .unwrap();

        let club = server.club(club_id).unwrap();
        assert!(
            club.encrypted_signing_key().is_none(),
            "no key before password"
        );

        server
            .club_set_password(sid, club_id, b"newpass1234")
            .unwrap();

        let club = server.club(club_id).unwrap();
        assert!(
            club.encrypted_signing_key().is_some(),
            "key generated after setting password"
        );
    }

    #[test]
    fn set_password_rejects_short_password() {
        let (mut server, sid) = setup_logged_in();
        let club_id = server
            .create_personal_club(sid, "short-pw-test".to_string(), None, None)
            .unwrap();
        let result = server.club_set_password(sid, club_id, b"short");
        assert!(result.is_err(), "password under 8 bytes should be rejected");
    }

    #[test]
    fn set_password_accepts_min_length_password() {
        let (mut server, sid) = setup_logged_in();
        let club_id = server
            .create_personal_club(sid, "tiny-pw-test".to_string(), None, None)
            .unwrap();
        server
            .club_set_password(sid, club_id, b"1234567890")
            .unwrap();

        let sid2 = server.connect();
        let _lock = server.login(sid2, club_id).unwrap();
        let result = server
            .authenticate_with_pending(sid2, &LockCredential::Password(b"1234567890".to_vec()));
        assert!(result.is_ok(), "10-byte password should authenticate");
    }

    #[test]
    fn set_password_rejects_7_byte_password() {
        let (mut server, sid) = setup_logged_in();
        let club_id = server
            .create_personal_club(sid, "seven-pw-test".to_string(), None, None)
            .unwrap();
        let result = server.club_set_password(sid, club_id, b"1234567");
        assert!(result.is_err(), "7-byte password should be rejected");
    }

    #[test]
    fn set_password_rejects_oversized_password() {
        let (mut server, sid) = setup_logged_in();
        let club_id = server
            .create_personal_club(sid, "big-pw-test".to_string(), None, None)
            .unwrap();
        let long_pw = vec![b'a'; 257];
        let result = server.club_set_password(sid, club_id, &long_pw);
        assert!(result.is_err());
    }

    #[test]
    fn set_password_accepts_max_length_password() {
        let (mut server, sid) = setup_logged_in();
        let club_id = server
            .create_personal_club(sid, "maxlen-pw-test".to_string(), None, None)
            .unwrap();
        let max_pw = vec![b'a'; 256];
        server.club_set_password(sid, club_id, &max_pw).unwrap();

        let sid2 = server.connect();
        let _lock = server.login(sid2, club_id).unwrap();
        let result = server.authenticate_with_pending(sid2, &LockCredential::Password(max_pw));
        assert!(result.is_ok(), "256-byte password should authenticate");
    }

    #[test]
    fn password_change_invalidates_old_password() {
        let (mut server, sid) = setup_logged_in();
        let club_id = server
            .create_personal_club(sid, "pw-change-invalid".to_string(), None, None)
            .unwrap();
        server
            .club_set_password(sid, club_id, b"oldpass1234")
            .unwrap();

        server
            .club_set_password(sid, club_id, b"newpass1234")
            .unwrap();

        let sid2 = server.connect();
        let _lock = server.login(sid2, club_id).unwrap();
        let old_result = server
            .authenticate_with_pending(sid2, &LockCredential::Password(b"oldpass1234".to_vec()));
        assert!(
            old_result.is_err(),
            "old password should not work after change"
        );
    }

    #[test]
    fn password_change_allows_new_password() {
        let (mut server, sid) = setup_logged_in();
        let club_id = server
            .create_personal_club(sid, "pw-change-valid".to_string(), None, None)
            .unwrap();
        server
            .club_set_password(sid, club_id, b"oldpass1234")
            .unwrap();

        server
            .club_set_password(sid, club_id, b"newpass1234")
            .unwrap();

        let sid2 = server.connect();
        let _lock = server.login(sid2, club_id).unwrap();
        let new_result = server
            .authenticate_with_pending(sid2, &LockCredential::Password(b"newpass1234".to_vec()));
        assert!(new_result.is_ok(), "new password should work after change");
    }

    #[test]
    fn password_with_special_chars_roundtrip() {
        let (mut server, sid) = setup_logged_in();
        let club_id = server
            .create_personal_club(sid, "special-pw".to_string(), None, None)
            .unwrap();
        let pw = b"p@$$w0rd!\xc3\xa9";
        server.club_set_password(sid, club_id, pw).unwrap();

        let sid2 = server.connect();
        let _lock = server.login(sid2, club_id).unwrap();
        let result = server.authenticate_with_pending(sid2, &LockCredential::Password(pw.to_vec()));
        assert!(result.is_ok());
        let wrong = server
            .authenticate_with_pending(sid2, &LockCredential::Password(b"p@$$w0rd!".to_vec()));
        assert!(wrong.is_err());
    }

    #[test]
    fn login_by_name_with_password() {
        let (mut server, sid) = setup_logged_in();
        let phc_hash = crate::crypto::password::hash_password(b"testpass").unwrap();
        let _club_id = server
            .create_personal_club(
                sid,
                "loginby-name".to_string(),
                Some(Credential::Password { phc_hash }),
                Some(b"testpass".to_vec()),
            )
            .unwrap();

        let sid2 = server.connect();
        server.login_public(sid2).unwrap();
        let _lock = server.login_by_name(sid2, "loginby-name").unwrap();
        let _km = server
            .authenticate_with_pending(sid2, &LockCredential::Password(b"testpass".to_vec()))
            .unwrap();

        let who = server.who_am_i(sid2).unwrap();
        assert!(
            who.iter().any(|(_, name)| name == "loginby-name"),
            "who_am_i should include loginby-name club"
        );
    }

    #[test]
    fn login_by_name_wrong_password_fails() {
        let (mut server, sid) = setup_logged_in();
        let phc_hash = crate::crypto::password::hash_password(b"rightpass").unwrap();
        let _club_id = server
            .create_personal_club(
                sid,
                "wrongpw-name".to_string(),
                Some(Credential::Password { phc_hash }),
                Some(b"rightpass".to_vec()),
            )
            .unwrap();

        let sid2 = server.connect();
        server.login_public(sid2).unwrap();
        let _lock = server.login_by_name(sid2, "wrongpw-name").unwrap();
        let result = server
            .authenticate_with_pending(sid2, &LockCredential::Password(b"wrongpass".to_vec()));
        assert!(result.is_err());
    }
}
