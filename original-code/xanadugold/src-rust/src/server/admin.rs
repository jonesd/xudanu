use crate::edition::{BeId, XnRegion};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ServerState {
    Running,
    Accepting,
    Rejecting,
    ShuttingDown,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct IdGrant {
    pub club_id: BeId,
    pub region: XnRegion,
}

#[derive(Debug)]
pub struct AdminState {
    server_state: ServerState,
    accepting_connections: bool,
    id_grants: Vec<IdGrant>,
    shutdown_requested: bool,
}

impl Default for AdminState {
    fn default() -> Self {
        AdminState {
            server_state: ServerState::Running,
            accepting_connections: true,
            id_grants: Vec::new(),
            shutdown_requested: false,
        }
    }
}

impl AdminState {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn is_accepting_connections(&self) -> bool {
        self.accepting_connections && !self.shutdown_requested
    }

    pub fn set_accepting_connections(&mut self, accept: bool) {
        self.accepting_connections = accept;
        self.server_state = if accept {
            ServerState::Accepting
        } else {
            ServerState::Rejecting
        };
    }

    pub fn server_state(&self) -> ServerState {
        if self.shutdown_requested {
            ServerState::ShuttingDown
        } else {
            self.server_state
        }
    }

    pub fn request_shutdown(&mut self) {
        self.shutdown_requested = true;
        self.server_state = ServerState::ShuttingDown;
    }

    pub fn is_shutdown_requested(&self) -> bool {
        self.shutdown_requested
    }

    pub fn grant(&mut self, club_id: BeId, region: XnRegion) {
        self.id_grants.push(IdGrant { club_id, region });
    }

    pub fn revoke_grant(&mut self, club_id: BeId) -> bool {
        let len_before = self.id_grants.len();
        self.id_grants.retain(|g| g.club_id != club_id);
        self.id_grants.len() != len_before
    }

    pub fn has_grant_for_any(&self, clubs: &std::collections::HashSet<BeId>) -> bool {
        self.id_grants
            .iter()
            .any(|g| clubs.contains(&g.club_id) && g.region.is_full())
    }

    pub fn grants(&self) -> &[IdGrant] {
        &self.id_grants
    }

    pub fn grants_for_club(&self, club_id: BeId) -> Vec<&IdGrant> {
        self.id_grants
            .iter()
            .filter(|g| g.club_id == club_id)
            .collect()
    }

    pub fn has_grant_for(&self, club_id: BeId, id: i64) -> bool {
        self.id_grants
            .iter()
            .any(|g| g.club_id == club_id && g.region.contains(id))
    }
}

#[derive(Debug, Clone)]
pub struct SessionInfo {
    pub session_id: u64,
    pub is_logged_in: bool,
    pub authority_clubs: Vec<BeId>,
    pub initial_login: Option<BeId>,
    pub has_grabbed_works: bool,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn admin_default_accepts_connections() {
        let admin = AdminState::new();
        assert!(admin.is_accepting_connections());
        assert_eq!(admin.server_state(), ServerState::Running);
    }

    #[test]
    fn admin_stop_accepting() {
        let mut admin = AdminState::new();
        admin.set_accepting_connections(false);
        assert!(!admin.is_accepting_connections());
        assert_eq!(admin.server_state(), ServerState::Rejecting);
    }

    #[test]
    fn admin_resume_accepting() {
        let mut admin = AdminState::new();
        admin.set_accepting_connections(false);
        admin.set_accepting_connections(true);
        assert!(admin.is_accepting_connections());
    }

    #[test]
    fn admin_shutdown() {
        let mut admin = AdminState::new();
        admin.request_shutdown();
        assert!(admin.is_shutdown_requested());
        assert!(!admin.is_accepting_connections());
        assert_eq!(admin.server_state(), ServerState::ShuttingDown);
    }

    #[test]
    fn admin_grant_id_region() {
        let mut admin = AdminState::new();
        let region = XnRegion::interval(1000, 2000);
        admin.grant(42, region.clone());
        assert_eq!(admin.grants().len(), 1);
        assert_eq!(admin.grants()[0].club_id, 42);
        assert!(admin.has_grant_for(42, 1500));
        assert!(!admin.has_grant_for(42, 500));
        assert!(!admin.has_grant_for(99, 1500));
    }

    #[test]
    fn admin_grant_accumulates() {
        let mut admin = AdminState::new();
        admin.grant(42, XnRegion::interval(1000, 2000));
        admin.grant(42, XnRegion::interval(3000, 4000));
        assert_eq!(admin.grants().len(), 2);
        assert!(admin.has_grant_for(42, 1500));
        assert!(admin.has_grant_for(42, 3500));
    }

    #[test]
    fn admin_revoke_grant() {
        let mut admin = AdminState::new();
        admin.grant(42, XnRegion::interval(1000, 2000));
        assert!(admin.revoke_grant(42));
        assert!(admin.grants().is_empty());
        assert!(!admin.revoke_grant(42));
    }

    #[test]
    fn admin_grants_for_club() {
        let mut admin = AdminState::new();
        admin.grant(10, XnRegion::interval(100, 200));
        admin.grant(20, XnRegion::interval(300, 400));
        admin.grant(10, XnRegion::interval(500, 600));
        let c10 = admin.grants_for_club(10);
        assert_eq!(c10.len(), 2);
        let c20 = admin.grants_for_club(20);
        assert_eq!(c20.len(), 1);
    }

    #[test]
    fn admin_shutdown_overrides_accepting() {
        let mut admin = AdminState::new();
        admin.request_shutdown();
        admin.set_accepting_connections(true);
        assert!(!admin.is_accepting_connections());
    }
}
