use std::collections::HashSet;
use std::time::Instant;

use crate::edition::BeId;

use super::keymaster::KeyMaster;

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

pub(crate) struct Session {
    id: SessionId,
    key_master: Option<KeyMaster>,
    connect_time: Instant,
    initial_login: Option<BeId>,
    active: bool,
}

impl Session {
    pub fn new(id: SessionId) -> Self {
        Session {
            id,
            key_master: None,
            connect_time: Instant::now(),
            initial_login: None,
            active: true,
        }
    }

    pub fn id(&self) -> SessionId {
        self.id
    }

    pub fn is_connected(&self) -> bool {
        self.active
    }

    pub fn end(&mut self) {
        self.active = false;
    }

    pub fn connect_time(&self) -> Instant {
        self.connect_time
    }

    pub fn initial_login(&self) -> Option<BeId> {
        self.initial_login
    }

    pub fn is_logged_in(&self) -> bool {
        self.key_master.is_some()
    }

    pub fn key_master(&self) -> Option<&KeyMaster> {
        self.key_master.as_ref()
    }

    pub fn key_master_mut(&mut self) -> Option<&mut KeyMaster> {
        self.key_master.as_mut()
    }

    pub fn set_key_master(&mut self, km: KeyMaster) {
        if self.key_master.is_none() {
            let authority = km.login_authority();
            self.initial_login = authority.iter().next().copied();
        }
        self.key_master = Some(km);
    }

    pub fn clear_key_master(&mut self) {
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
}

impl std::fmt::Debug for Session {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Session")
            .field("id", &self.id)
            .field("active", &self.active)
            .field("initial_login", &self.initial_login)
            .field("is_logged_in", &self.is_logged_in())
            .finish()
    }
}
