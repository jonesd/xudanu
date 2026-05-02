use std::collections::BTreeMap;

use super::backend::BeId;
use super::edition::Edition;
use super::endorsement::EndorsementSet;

#[derive(Debug, Clone)]
pub struct Work {
    be_id: BeId,
    owner: Option<BeId>,
    current_edition: Edition,
    revision_count: u64,
    revision_history: BTreeMap<u64, Edition>,
    read_club: Option<BeId>,
    edit_club: Option<BeId>,
    sponsors: Vec<BeId>,
    endorsements: EndorsementSet,
}

impl Work {
    pub fn new(be_id: BeId, edition: Edition) -> Self {
        Work {
            be_id,
            owner: None,
            current_edition: edition,
            revision_count: 0,
            revision_history: BTreeMap::new(),
            read_club: None,
            edit_club: None,
            sponsors: Vec::new(),
            endorsements: EndorsementSet::new(),
        }
    }

    pub fn new_with_owner(be_id: BeId, owner: Option<BeId>, edition: Edition) -> Self {
        Work {
            be_id,
            owner,
            current_edition: edition,
            revision_count: 0,
            revision_history: BTreeMap::new(),
            read_club: None,
            edit_club: None,
            sponsors: Vec::new(),
            endorsements: EndorsementSet::new(),
        }
    }

    pub fn be_id(&self) -> BeId {
        self.be_id
    }

    pub fn owner(&self) -> Option<BeId> {
        self.owner
    }

    pub fn set_owner(&mut self, owner: Option<BeId>) {
        self.owner = owner;
    }

    pub fn edition(&self) -> &Edition {
        &self.current_edition
    }

    pub fn current_edition(&self) -> &Edition {
        &self.current_edition
    }

    pub fn current_edition_id(&self) -> Option<u64> {
        None
    }

    pub fn revision_count(&self) -> u64 {
        self.revision_count
    }

    pub fn revision_history(&self) -> &BTreeMap<u64, Edition> {
        &self.revision_history
    }

    pub fn revise(&mut self, new_edition: Edition) {
        let old_number = self.revision_count;
        self.revision_history
            .insert(old_number, self.current_edition.clone());
        self.revision_count += 1;
        self.current_edition = new_edition;
    }

    pub fn try_revise(&mut self, new_edition: Edition) -> Result<(), super::snapshot::SnapshotError> {
        if self.edit_club == Some(0) {
            return Err(super::snapshot::SnapshotError::CannotEditFrozen {
                work_id: self.be_id,
            });
        }
        self.revise(new_edition);
        Ok(())
    }

    pub fn fetch_revision(&self, number: u64) -> Option<&Edition> {
        if number == self.revision_count {
            return Some(&self.current_edition);
        }
        self.revision_history.get(&number)
    }

    pub fn read_club(&self) -> Option<BeId> {
        self.read_club
    }

    pub fn set_read_club(&mut self, club: Option<BeId>) {
        self.read_club = club;
    }

    pub fn edit_club(&self) -> Option<BeId> {
        self.edit_club
    }

    pub fn set_edit_club(&mut self, club: Option<BeId>) {
        self.edit_club = club;
    }

    pub fn sponsors(&self) -> &[BeId] {
        &self.sponsors
    }

    pub fn add_sponsor(&mut self, club: BeId) {
        if !self.sponsors.contains(&club) {
            self.sponsors.push(club);
        }
    }

    pub fn remove_sponsor(&mut self, club: BeId) {
        self.sponsors.retain(|s| *s != club);
    }

    pub fn set_revision_history(&mut self, count: u64, history: BTreeMap<u64, Edition>) {
        self.revision_count = count;
        self.revision_history = history;
    }

    pub fn endorsements(&self) -> &EndorsementSet {
        &self.endorsements
    }

    pub fn endorse(&mut self, additional: &EndorsementSet) {
        self.endorsements = self.endorsements.union(additional);
    }

    pub fn retract(&mut self, removed: &EndorsementSet) {
        self.endorsements = self.endorsements.difference(removed);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::RangeElement;

    #[test]
    fn work_new() {
        let edition = Edition::from_text("hello");
        let work = Work::new(1, edition);
        assert_eq!(work.be_id(), 1);
        assert!(work.owner().is_none());
        assert_eq!(work.revision_count(), 0);
        assert!(work.revision_history().is_empty());
    }

    #[test]
    fn work_edition_access() {
        let edition = Edition::from_text("hello");
        let work = Work::new(1, edition);
        assert_eq!(work.edition().to_text(), "hello");
    }

    #[test]
    fn work_revise_pushes_history() {
        let edition_v1 = Edition::from_text("v1");
        let edition_v2 = Edition::from_text("v2");
        let edition_v3 = Edition::from_text("v3");
        let mut work = Work::new(1, edition_v1);
        assert_eq!(work.revision_count(), 0);

        work.revise(edition_v2);
        assert_eq!(work.revision_count(), 1);
        assert_eq!(work.edition().to_text(), "v2");
        assert_eq!(
            work.fetch_revision(0).unwrap().to_text(),
            "v1"
        );

        work.revise(edition_v3);
        assert_eq!(work.revision_count(), 2);
        assert_eq!(work.edition().to_text(), "v3");
        assert_eq!(
            work.fetch_revision(1).unwrap().to_text(),
            "v2"
        );
    }

    #[test]
    fn work_revision_history_map() {
        let v1 = Edition::from_text("a");
        let v2 = Edition::from_text("b");
        let v3 = Edition::from_text("c");
        let mut work = Work::new(1, v1);
        work.revise(v2);
        work.revise(v3);
        let history = work.revision_history();
        assert_eq!(history.len(), 2);
        assert_eq!(history[&0].to_text(), "a");
        assert_eq!(history[&1].to_text(), "b");
    }

    #[test]
    fn work_owner() {
        let mut work = Work::new_with_owner(1, Some(42), Edition::empty());
        assert_eq!(work.owner(), Some(42));
        work.set_owner(Some(99));
        assert_eq!(work.owner(), Some(99));
        work.set_owner(None);
        assert!(work.owner().is_none());
    }

    #[test]
    fn work_clubs() {
        let mut work = Work::new(1, Edition::empty());
        assert!(work.read_club().is_none());
        assert!(work.edit_club().is_none());
        work.set_read_club(Some(10));
        work.set_edit_club(Some(20));
        assert_eq!(work.read_club(), Some(10));
        assert_eq!(work.edit_club(), Some(20));
    }

    #[test]
    fn work_sponsors() {
        let mut work = Work::new(1, Edition::empty());
        assert!(work.sponsors().is_empty());
        work.add_sponsor(10);
        work.add_sponsor(20);
        work.add_sponsor(10);
        assert_eq!(work.sponsors(), &[10, 20]);
        work.remove_sponsor(10);
        assert_eq!(work.sponsors(), &[20]);
    }

    #[test]
    fn work_fetch_revision_current() {
        let edition = Edition::from_text("current");
        let work = Work::new(1, edition.clone());
        let current = work.fetch_revision(0).unwrap();
        assert_eq!(current.to_text(), "current");
    }

    #[test]
    fn work_fetch_revision_nonexistent() {
        let work = Work::new(1, Edition::empty());
        assert!(work.fetch_revision(99).is_none());
    }

    #[test]
    fn work_many_revisions() {
        let mut work = Work::new(1, Edition::from_text("v0"));
        for i in 1..100u64 {
            work.revise(Edition::from_one(i as i64, RangeElement::text(format!("v{}", i))));
        }
        assert_eq!(work.revision_count(), 99);
        assert_eq!(work.revision_history().len(), 99);
        assert_eq!(
            work.fetch_revision(0).unwrap().to_text(),
            "v0"
        );
        assert_eq!(
            work.fetch_revision(50).unwrap().fetch(50).unwrap().as_text().unwrap(),
            "v50"
        );
    }

    #[test]
    fn work_try_revise_normal() {
        let mut work = Work::new(1, Edition::from_text("v0"));
        work.try_revise(Edition::from_text("v1")).unwrap();
        assert_eq!(work.edition().to_text(), "v1");
    }

    #[test]
    fn work_try_revise_frozen_rejected() {
        let mut work = Work::new(1, Edition::from_text("v0"));
        work.set_edit_club(Some(0));
        let result = work.try_revise(Edition::from_text("v1"));
        assert!(result.is_err());
        assert_eq!(work.edition().to_text(), "v0");
    }
}
