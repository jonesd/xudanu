use std::collections::HashSet;

use crate::edition::BeId;
use super::club::Club;
use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct KeyMaster {
    login_authority: HashSet<BeId>,
    actual_authority: HashSet<BeId>,
}

impl KeyMaster {
    pub fn make(club_id: BeId) -> Self {
        let login: HashSet<BeId> = [club_id].into_iter().collect();
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

    pub fn has_signature_authority(
        &self,
        club_id: BeId,
        all_clubs: &HashMap<BeId, Club>,
    ) -> bool {
        if let Some(club) = all_clubs.get(&club_id) {
            if let Some(sig_club) = club.signature_club() {
                return self.has_authority(sig_club);
            }
        }
        false
    }

    pub fn update_authority(
        &mut self,
        all_clubs: &HashMap<BeId, Club>,
    ) {
        self.actual_authority = HashSet::new();
        for login_id in &self.login_authority {
            if let Some(club) = all_clubs.get(login_id) {
                let supers = club.transitive_super_club_ids(all_clubs);
                self.actual_authority.extend(supers);
            } else {
                self.actual_authority.insert(*login_id);
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::Edition;
    use crate::server::club::Club;
    use std::collections::HashMap;

    fn make_club_hierarchy() -> HashMap<BeId, Club> {
        let mut clubs = HashMap::new();
        let mut root = Club::new_with_owner(1, Some(1), Edition::from_text("root"));
        let mut admin = Club::new_with_owner(2, Some(1), Edition::from_text("admin"));
        let user = Club::new_with_owner(3, Some(2), Edition::from_text("user"));

        root.add_member(2);
        root.add_member(3);
        admin.add_member(4u64);

        clubs.insert(1, root);
        clubs.insert(2, admin);
        clubs.insert(3, user);
        let guest = Club::new_with_owner(4, Some(3), Edition::from_text("guest"));
        clubs.insert(4, guest);
        clubs
    }

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

    #[test]
    fn update_authority_with_hierarchy() {
        let clubs = make_club_hierarchy();
        let mut km = KeyMaster::make(4);
        km.update_authority(&clubs);
        assert!(km.has_authority(4));
        assert!(km.has_authority(2));
        assert!(km.has_authority(1));
    }

    #[test]
    fn signature_authority_check() {
        let clubs = make_club_hierarchy();
        let km = KeyMaster::make(1);
        assert!(km.has_signature_authority(2, &clubs));
        assert!(!km.has_signature_authority(4, &clubs));
    }
}
