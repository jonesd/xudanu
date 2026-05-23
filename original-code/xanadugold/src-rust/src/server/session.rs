use std::collections::HashSet;
use std::time::{Duration, Instant};

use ed25519_dalek::SigningKey;

use crate::edition::BeId;

use super::keymaster::KeyMaster;
use super::lock::Lock;

const DEFAULT_SESSION_TIMEOUT: Duration = Duration::from_secs(3600);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct SessionId(pub u64);

impl SessionId {
    pub fn new(id: u64) -> Self {
        SessionId(id)
    }

    pub fn as_u64(&self) -> u64 {
        self.0
    }
}

impl std::fmt::Display for SessionId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "session:{}", self.0)
    }
}

pub struct Session {
    id: SessionId,
    key_master: Option<KeyMaster>,
    _connect_time: Instant,
    initial_login: Option<BeId>,
    active: bool,
    pending_lock: Option<Box<dyn Lock>>,
    pending_lock_club: Option<BeId>,
    expires_at: Option<Instant>,
    club_signing_key: Option<SigningKey>,
}

impl Session {
    pub fn new(id: SessionId) -> Self {
        Session {
            id,
            key_master: None,
            _connect_time: Instant::now(),
            initial_login: None,
            active: true,
            pending_lock: None,
            pending_lock_club: None,
            expires_at: Some(Instant::now() + DEFAULT_SESSION_TIMEOUT),
            club_signing_key: None,
        }
    }

    pub fn new_with_timeout(id: SessionId, timeout: Duration) -> Self {
        Session {
            expires_at: Some(Instant::now() + timeout),
            ..Session::new(id)
        }
    }

    pub fn id(&self) -> SessionId {
        self.id
    }

    pub fn is_connected(&self) -> bool {
        self.active
    }

    pub fn is_expired(&self) -> bool {
        self.expires_at.map(|t| Instant::now() > t).unwrap_or(false)
    }

    pub fn is_valid(&self) -> bool {
        self.active && !self.is_expired()
    }

    pub fn end(&mut self) {
        self.active = false;
        self.club_signing_key = None;
    }

    pub fn _connect_time(&self) -> Instant {
        self._connect_time
    }

    pub fn initial_login(&self) -> Option<BeId> {
        self.initial_login
    }

    pub fn is_logged_in(&self) -> bool {
        self.key_master.is_some()
    }

    pub fn _key_master(&self) -> Option<&KeyMaster> {
        self.key_master.as_ref()
    }

    pub fn _key_master_mut(&mut self) -> Option<&mut KeyMaster> {
        self.key_master.as_mut()
    }

    pub fn set_key_master(&mut self, km: KeyMaster) {
        if self.key_master.is_none() {
            let authority = km.login_authority();
            self.initial_login = authority.iter().next().copied();
        }
        self.key_master = Some(km);
    }

    pub fn incorporate_authority(&mut self, other: &KeyMaster) {
        if let Some(ref mut km) = self.key_master {
            km.incorporate(other);
        }
    }

    pub fn _clear_key_master(&mut self) {
        self.key_master = None;
    }

    pub fn has_authority(&self, club_id: BeId) -> bool {
        self.key_master
            .as_ref()
            .map(|km| km.has_authority(club_id))
            .unwrap_or(false)
    }

    pub fn authority_clubs(&self) -> HashSet<BeId> {
        self.key_master
            .as_ref()
            .map(|km| km.actual_authority())
            .unwrap_or_default()
    }

    pub fn set_pending_lock(&mut self, lock: Box<dyn Lock>, club_id: BeId) {
        self.pending_lock = Some(lock);
        self.pending_lock_club = Some(club_id);
    }

    pub fn take_pending_lock(&mut self) -> Option<(Box<dyn Lock>, BeId)> {
        let club = self.pending_lock_club.take();
        self.pending_lock.take().zip(club)
    }

    pub fn pending_lock_club(&self) -> Option<BeId> {
        self.pending_lock_club
    }

    pub fn club_signing_key(&self) -> Option<&SigningKey> {
        self.club_signing_key.as_ref()
    }

    pub fn set_club_signing_key(&mut self, key: Option<SigningKey>) {
        self.club_signing_key = key;
    }

    pub fn club_verifying_key(&self) -> Option<ed25519_dalek::VerifyingKey> {
        self.club_signing_key.as_ref().map(|k| k.verifying_key())
    }
}

impl std::fmt::Debug for Session {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Session")
            .field("id", &self.id)
            .field("active", &self.active)
            .field("expired", &self.is_expired())
            .field("initial_login", &self.initial_login)
            .field("is_logged_in", &self.is_logged_in())
            .field("pending_lock_club", &self.pending_lock_club)
            .finish()
    }
}
