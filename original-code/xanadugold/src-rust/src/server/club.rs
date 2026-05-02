use std::collections::{HashMap, HashSet};

use crate::edition::{BeId, Edition, EndorsementSet, Endorsement, Work};
use crate::edition::RangeElement;

#[derive(Debug, Clone)]
pub struct Club {
    be_id: BeId,
    work: Work,
    signature_club: Option<BeId>,
    name: Option<String>,
    members: HashSet<BeId>,
    sponsored_works: HashSet<BeId>,
}

impl Club {
    pub fn new(be_id: BeId, description: Edition) -> Self {
        Club {
            be_id,
            work: Work::new(be_id, description),
            signature_club: None,
            name: None,
            members: HashSet::new(),
            sponsored_works: HashSet::new(),
        }
    }

    pub fn new_with_owner(be_id: BeId, owner: Option<BeId>, description: Edition) -> Self {
        Club {
            be_id,
            work: Work::new_with_owner(be_id, owner, description),
            signature_club: owner,
            name: None,
            members: HashSet::new(),
            sponsored_works: HashSet::new(),
        }
    }

    pub fn be_id(&self) -> BeId {
        self.be_id
    }

    pub fn work(&self) -> &Work {
        &self.work
    }

    pub fn work_mut(&mut self) -> &mut Work {
        &mut self.work
    }

    pub fn edition(&self) -> &Edition {
        self.work.edition()
    }

    pub fn signature_club(&self) -> Option<BeId> {
        self.signature_club
    }

    pub fn set_signature_club(&mut self, club: Option<BeId>) {
        self.signature_club = club;
    }

    pub fn remove_signature_club(&mut self) {
        self.signature_club = None;
    }

    pub fn name(&self) -> Option<&str> {
        self.name.as_deref()
    }

    pub fn set_name(&mut self, name: String) {
        self.name = Some(name);
    }

    pub fn owner(&self) -> Option<BeId> {
        self.work.owner()
    }

    pub fn set_owner(&mut self, owner: Option<BeId>) {
        self.work.set_owner(owner);
    }

    pub fn read_club(&self) -> Option<BeId> {
        self.work.read_club()
    }

    pub fn edit_club(&self) -> Option<BeId> {
        self.work.edit_club()
    }

    pub fn set_read_club(&mut self, club: Option<BeId>) {
        self.work.set_read_club(club);
    }

    pub fn set_edit_club(&mut self, club: Option<BeId>) {
        self.work.set_edit_club(club);
    }

    pub fn members(&self) -> &HashSet<BeId> {
        &self.members
    }

    pub fn add_member(&mut self, member_id: BeId) {
        self.members.insert(member_id);
    }

    pub fn remove_member(&mut self, member_id: BeId) {
        self.members.remove(&member_id);
    }

    pub fn is_member(&self, member_id: BeId) -> bool {
        self.members.contains(&member_id)
    }

    pub fn sponsored_works(&self) -> &HashSet<BeId> {
        &self.sponsored_works
    }

    pub fn add_sponsored_work(&mut self, work_id: BeId) {
        self.sponsored_works.insert(work_id);
    }

    pub fn remove_sponsored_work(&mut self, work_id: BeId) {
        self.sponsored_works.remove(&work_id);
    }

    pub fn endorsements(&self) -> &EndorsementSet {
        self.work.endorsements()
    }

    pub fn endorse(&mut self, additional: &EndorsementSet) {
        self.work.endorse(additional);
    }

    pub fn retract(&mut self, removed: &EndorsementSet) {
        self.work.retract(removed);
    }

    pub fn transitive_super_club_ids(
        &self,
        all_clubs: &HashMap<BeId, Club>,
    ) -> HashSet<BeId> {
        let mut result = HashSet::new();
        result.insert(self.be_id);
        let mut queue = vec![self.be_id];
        while let Some(current_id) = queue.pop() {
            for (&club_id, club) in all_clubs {
                if club.members.contains(&current_id) && result.insert(club_id) {
                    queue.push(club_id);
                }
            }
        }
        result
    }

    pub fn transitive_member_ids(
        &self,
        all_clubs: &HashMap<BeId, Club>,
    ) -> HashSet<BeId> {
        let mut result = HashSet::new();
        result.insert(self.be_id);
        let mut queue: Vec<BeId> = self.members.iter().copied().collect();
        while let Some(member_id) = queue.pop() {
            if result.insert(member_id) {
                if let Some(member_club) = all_clubs.get(&member_id) {
                    for &sub_member in &member_club.members {
                        if !result.contains(&sub_member) {
                            queue.push(sub_member);
                        }
                    }
                }
            }
        }
        result
    }

    pub fn can_be_read_by(
        &self,
        keymaster: &KeyMaster,
    ) -> bool {
        if let Some(read_club) = self.read_club() {
            if keymaster.has_authority(read_club) {
                return true;
            }
        }
        self.can_be_edited_by(keymaster)
    }

    pub fn can_be_edited_by(
        &self,
        keymaster: &KeyMaster,
    ) -> bool {
        if let Some(edit_club) = self.edit_club() {
            if keymaster.has_authority(edit_club) {
                return true;
            }
        }
        false
    }
}

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

    fn make_club_hierarchy() -> HashMap<BeId, Club> {
        let mut clubs = HashMap::new();
        let mut root = Club::new_with_owner(1, Some(1), Edition::from_text("root"));
        root.set_name("root".to_string());
        let mut admin = Club::new_with_owner(2, Some(1), Edition::from_text("admin"));
        admin.set_name("admin".to_string());
        let mut user = Club::new_with_owner(3, Some(2), Edition::from_text("user"));
        user.set_name("user".to_string());
        let guest = Club::new_with_owner(4, Some(3), Edition::from_text("guest"));

        root.add_member(2);
        root.add_member(3);
        admin.add_member(4);

        clubs.insert(1, root);
        clubs.insert(2, admin);
        clubs.insert(3, user);
        clubs.insert(4, guest);
        clubs
    }

    #[test]
    fn club_new() {
        let desc = Edition::from_text("public club");
        let club = Club::new(1, desc);
        assert_eq!(club.be_id(), 1);
        assert!(club.owner().is_none());
        assert!(club.signature_club().is_none());
        assert!(club.name().is_none());
        assert!(club.members().is_empty());
    }

    #[test]
    fn club_with_name() {
        let mut club = Club::new(1, Edition::empty());
        club.set_name("admins".to_string());
        assert_eq!(club.name(), Some("admins"));
    }

    #[test]
    fn club_signature() {
        let mut club = Club::new(1, Edition::empty());
        assert!(club.signature_club().is_none());
        club.set_signature_club(Some(42));
        assert_eq!(club.signature_club(), Some(42));
        club.remove_signature_club();
        assert!(club.signature_club().is_none());
    }

    #[test]
    fn club_edition_access() {
        let desc = Edition::from_one(0, RangeElement::text("member"));
        let club = Club::new(1, desc);
        assert_eq!(club.edition().count(), 1);
    }

    #[test]
    fn club_club_settings() {
        let mut club = Club::new(1, Edition::empty());
        club.set_read_club(Some(10));
        club.set_edit_club(Some(20));
        assert_eq!(club.read_club(), Some(10));
        assert_eq!(club.edit_club(), Some(20));
    }

    #[test]
    fn club_members() {
        let mut club = Club::new(1, Edition::empty());
        club.add_member(10);
        club.add_member(20);
        club.add_member(10);
        assert!(club.is_member(10));
        assert!(club.is_member(20));
        assert!(!club.is_member(30));
        assert_eq!(club.members().len(), 2);
        club.remove_member(10);
        assert!(!club.is_member(10));
    }

    #[test]
    fn club_sponsored_works() {
        let mut club = Club::new(1, Edition::empty());
        club.add_sponsored_work(100);
        club.add_sponsored_work(200);
        assert!(club.sponsored_works().contains(&100));
        assert!(club.sponsored_works().contains(&200));
        club.remove_sponsored_work(100);
        assert!(!club.sponsored_works().contains(&100));
    }

    #[test]
    fn club_endorsements() {
        let mut club = Club::new(1, Edition::empty());
        assert!(club.endorsements().is_empty());
        let endorsement = Endorsement::new(1, 10);
        let set = EndorsementSet::new().with(endorsement.clone());
        club.endorse(&set);
        assert!(club.endorsements().contains(&endorsement));
        club.retract(&set);
        assert!(!club.endorsements().contains(&endorsement));
    }

    #[test]
    fn transitive_super_club_ids() {
        let clubs = make_club_hierarchy();
        let guest = clubs.get(&4).unwrap();
        let supers = guest.transitive_super_club_ids(&clubs);
        assert!(supers.contains(&4));
        assert!(supers.contains(&2));
        assert!(supers.contains(&1));
        assert!(!supers.contains(&3));
    }

    #[test]
    fn transitive_super_club_ids_root() {
        let clubs = make_club_hierarchy();
        let root = clubs.get(&1).unwrap();
        let supers = root.transitive_super_club_ids(&clubs);
        assert!(supers.contains(&1));
        assert_eq!(supers.len(), 1);
    }

    #[test]
    fn transitive_member_ids() {
        let clubs = make_club_hierarchy();
        let root = clubs.get(&1).unwrap();
        let members = root.transitive_member_ids(&clubs);
        assert!(members.contains(&1));
        assert!(members.contains(&2));
        assert!(members.contains(&3));
        assert!(members.contains(&4));
    }

    #[test]
    fn keymaster_authority_with_hierarchy() {
        let clubs = make_club_hierarchy();
        let mut km = KeyMaster::make(4);
        km.update_authority(&clubs);
        assert!(km.has_authority(4));
        assert!(km.has_authority(2));
        assert!(km.has_authority(1));
        assert!(!km.has_authority(3));
    }

    #[test]
    fn keymaster_signature_authority() {
        let clubs = make_club_hierarchy();
        let km = KeyMaster::make(1);
        assert!(km.has_signature_authority(2, &clubs));
        assert!(!km.has_signature_authority(4, &clubs));
    }

    #[test]
    fn keymaster_can_read_via_edit() {
        let clubs = make_club_hierarchy();
        let mut club = Club::new(10, Edition::empty());
        club.set_edit_club(Some(1));
        let km = KeyMaster::make(1);
        assert!(club.can_be_read_by(&km));
    }

    #[test]
    fn keymaster_cannot_read_without_permission() {
        let mut club = Club::new(10, Edition::empty());
        club.set_read_club(Some(99));
        club.set_edit_club(Some(99));
        let km = KeyMaster::make(1);
        assert!(!club.can_be_read_by(&km));
    }

    #[test]
    fn keymaster_can_edit_with_permission() {
        let mut club = Club::new(10, Edition::empty());
        club.set_edit_club(Some(1));
        let km = KeyMaster::make(1);
        assert!(club.can_be_edited_by(&km));
    }

    #[test]
    fn keymaster_cannot_edit_without_permission() {
        let mut club = Club::new(10, Edition::empty());
        club.set_edit_club(Some(99));
        let km = KeyMaster::make(1);
        assert!(!club.can_be_edited_by(&km));
    }

    #[test]
    fn keymaster_update_authority_propagates() {
        let clubs = make_club_hierarchy();
        let mut km = KeyMaster::make(3);
        km.update_authority(&clubs);
        assert!(km.has_authority(3));
        assert!(km.has_authority(1));
    }

    #[test]
    fn keymaster_incorporate_merges() {
        let mut km1 = KeyMaster::make(1);
        let km2 = KeyMaster::make(2);
        km1.incorporate(&km2);
        assert!(km1.has_authority(1));
        assert!(km1.has_authority(2));
        assert_eq!(km1.login_authority().len(), 2);
    }

    #[test]
    fn keymaster_remove_logins_revokes() {
        let mut km = KeyMaster::make(1);
        km.incorporate(&KeyMaster::make(2));
        let mut to_remove = HashSet::new();
        to_remove.insert(2);
        km.remove_logins(&to_remove);
        assert!(km.has_authority(1));
        assert!(!km.has_authority(2));
    }

    #[test]
    fn keymaster_make_public() {
        let km = KeyMaster::make_public();
        assert!(km.has_authority(0));
    }
}
