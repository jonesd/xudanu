use std::collections::HashSet;

use crate::edition::BeId;

#[derive(Debug, Clone)]
pub struct KeyMaster {
    login_authority: HashSet<BeId>,
    actual_authority: HashSet<BeId>,
}

impl KeyMaster {
    pub fn make(club_id: BeId) -> Self {
        let mut login = HashSet::new();
        login.insert(club_id);
        let actual = login.clone();
        KeyMaster {
            login_authority: login,
            actual_authority: actual,
        }
    }

    pub fn make_all(club_ids: HashSet<BeId>) -> Self {
        let actual = club_ids.clone();
        KeyMaster {
            login_authority: club_ids,
            actual_authority: actual,
        }
    }

    pub fn make_public() -> Self {
        let login: HashSet<BeId> = [0].into_iter().collect();
        KeyMaster {
            actual_authority: login.clone(),
            login_authority: login,
        }
    }

    pub fn login_authority(&self) -> &HashSet<BeId> {
        &self.login_authority
    }

    pub fn actual_authority(&self) -> HashSet<BeId> {
        self.actual_authority.clone()
    }

    pub fn has_authority(&self, club_id: BeId) -> bool {
        self.actual_authority.contains(&club_id)
    }

    pub fn incorporate(&mut self, other: &KeyMaster) {
        for club_id in &other.login_authority {
            self.login_authority.insert(*club_id);
        }
        for club_id in &other.actual_authority {
            self.actual_authority.insert(*club_id);
        }
    }

    pub fn remove_logins(&mut self, old_logins: &HashSet<BeId>) {
        for club_id in old_logins {
            self.login_authority.remove(club_id);
        }
        self.actual_authority = self.login_authority.clone();
    }

    pub fn has_signature_authority(&self, club_id: BeId) -> bool {
        self.actual_authority.contains(&club_id)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn make_single_club() {
        let km = KeyMaster::make(42);
        assert!(km.has_authority(42));
        assert!(!km.has_authority(99));
        assert_eq!(km.login_authority().len(), 1);
    }

    #[test]
    fn make_multiple_clubs() {
        let mut clubs = HashSet::new();
        clubs.insert(1);
        clubs.insert(2);
        clubs.insert(3);
        let km = KeyMaster::make_all(clubs);
        assert!(km.has_authority(1));
        assert!(km.has_authority(2));
        assert!(km.has_authority(3));
        assert!(!km.has_authority(4));
    }

    #[test]
    fn incorporate_merges() {
        let mut km1 = KeyMaster::make(1);
        let km2 = KeyMaster::make(2);
        km1.incorporate(&km2);
        assert!(km1.has_authority(1));
        assert!(km1.has_authority(2));
        assert_eq!(km1.login_authority().len(), 2);
    }

    #[test]
    fn remove_logins_revokes() {
        let mut km = KeyMaster::make(1);
        km.incorporate(&KeyMaster::make(2));
        let mut to_remove = HashSet::new();
        to_remove.insert(2);
        km.remove_logins(&to_remove);
        assert!(km.has_authority(1));
        assert!(!km.has_authority(2));
    }

    #[test]
    fn make_public() {
        let km = KeyMaster::make_public();
        assert!(km.has_authority(0));
    }
}
