use crate::edition::{BeId, Edition, Work};

#[derive(Debug, Clone)]
pub struct Club {
    be_id: BeId,
    work: Work,
    signature_club: Option<BeId>,
    name: Option<String>,
}

impl Club {
    pub fn new(be_id: BeId, description: Edition) -> Self {
        let work = Work::new(be_id, description);
        Club {
            be_id,
            work,
            signature_club: None,
            name: None,
        }
    }

    pub fn new_with_owner(be_id: BeId, owner: Option<BeId>, description: Edition) -> Self {
        let work = Work::new_with_owner(be_id, owner, description);
        Club {
            be_id,
            work,
            signature_club: None,
            name: None,
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
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::RangeElement;

    #[test]
    fn club_new() {
        let desc = Edition::from_text("public club");
        let club = Club::new(1, desc);
        assert_eq!(club.be_id(), 1);
        assert!(club.owner().is_none());
        assert!(club.signature_club().is_none());
        assert!(club.name().is_none());
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
}
