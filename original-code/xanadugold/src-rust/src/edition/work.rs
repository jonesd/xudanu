use std::collections::BTreeMap;

use super::backend::BeId;
use super::edition::Edition;
use super::endorsement::EndorsementSet;

/// The type of a work — used for graph icons, filtering, and
/// concept-as-work semantics. See docs/dev/FR-22-concepts-and-categorization.md.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
#[cfg_attr(feature = "serde", serde(rename_all = "lowercase"))]
pub enum WorkKind {
    Document,
    Note,
    Person,
    Concept,
    Collection,
    Commentary,
    Book,
}

impl Default for WorkKind {
    fn default() -> Self {
        WorkKind::Document
    }
}

impl WorkKind {
    pub fn as_str(&self) -> &'static str {
        match self {
            WorkKind::Document => "document",
            WorkKind::Note => "note",
            WorkKind::Person => "person",
            WorkKind::Concept => "concept",
            WorkKind::Collection => "collection",
            WorkKind::Commentary => "commentary",
            WorkKind::Book => "book",
        }
    }

    pub fn from_str_loose(s: &str) -> Self {
        match s.to_ascii_lowercase().as_str() {
            "note" => WorkKind::Note,
            "person" => WorkKind::Person,
            "concept" => WorkKind::Concept,
            "collection" => WorkKind::Collection,
            "commentary" => WorkKind::Commentary,
            "book" => WorkKind::Book,
            _ => WorkKind::Document,
        }
    }
}

/// The license under which a work is published. See FR-24.
/// Defaults to AllRightsReserved (Berne Convention automatic copyright).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub enum License {
    #[cfg_attr(feature = "serde", serde(rename = "all-rights-reserved"))]
    AllRightsReserved,
    #[cfg_attr(feature = "serde", serde(rename = "transcopyright"))]
    Transcopyright,
    #[cfg_attr(feature = "serde", serde(rename = "cc-by"))]
    CreativeCommonsBy,
    #[cfg_attr(feature = "serde", serde(rename = "cc-by-sa"))]
    CreativeCommonsBySa,
    #[cfg_attr(feature = "serde", serde(rename = "public-domain"))]
    PublicDomain,
}

impl Default for License {
    fn default() -> Self {
        License::AllRightsReserved
    }
}

impl License {
    pub fn as_str(&self) -> &'static str {
        match self {
            License::AllRightsReserved => "all-rights-reserved",
            License::Transcopyright => "transcopyright",
            License::CreativeCommonsBy => "cc-by",
            License::CreativeCommonsBySa => "cc-by-sa",
            License::PublicDomain => "public-domain",
        }
    }

    pub fn from_str_loose(s: &str) -> Self {
        match s.to_ascii_lowercase().as_str() {
            "transcopyright" | "tco" => License::Transcopyright,
            "cc-by" => License::CreativeCommonsBy,
            "cc-by-sa" => License::CreativeCommonsBySa,
            "public-domain" | "cc0" | "pd" => License::PublicDomain,
            _ => License::AllRightsReserved,
        }
    }

    /// License class bits for the FR-38 summary overlay. Derived, never
    /// independently stored — a pure function of License, so old data
    /// needs no migration. Classes are the common query granularity;
    /// per-owner questions go through span_owner_license (ground truth).
    pub fn license_class(&self) -> LicenseClass {
        match self {
            License::AllRightsReserved => LicenseClass::RESTRICTED,
            License::Transcopyright => LicenseClass::TRANSCLUSION_OK,
            License::CreativeCommonsBy => LicenseClass::ATTRIBUTION,
            License::CreativeCommonsBySa => LicenseClass::ATTRIBUTION,
            License::PublicDomain => LicenseClass::FREE,
        }
    }
}

/// OR-monoid license class bits (FR-38). One byte. Gold lineage:
/// CanopyCrum endorsement flags "widded by ORing up the canopy"
/// (canopyx.hxx) — a fixed summary that lets region queries prune
/// subtrees; criteria without a bit fall back to ground-truth search.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct LicenseClass(u8);

impl LicenseClass {
    pub const FREE: LicenseClass = LicenseClass(1 << 0);
    pub const ATTRIBUTION: LicenseClass = LicenseClass(1 << 1);
    pub const TRANSCLUSION_OK: LicenseClass = LicenseClass(1 << 2);
    pub const RESTRICTED: LicenseClass = LicenseClass(1 << 3);
    pub const UNKNOWN: LicenseClass = LicenseClass(1 << 4);

    /// Union (the widd operation). A span's class is the OR of the
    /// classes of everything it covers.
    pub fn combine(self, other: LicenseClass) -> LicenseClass {
        LicenseClass(self.0 | other.0)
    }

    pub fn contains(self, other: LicenseClass) -> bool {
        self.0 & other.0 == other.0
    }

    pub fn is_empty(self) -> bool {
        self.0 == 0
    }

    pub fn bits(self) -> u8 {
        self.0
    }
}

impl std::fmt::Display for LicenseClass {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        if self.0 == 0 {
            return write!(f, "empty");
        }
        let mut parts = Vec::new();
        if self.contains(LicenseClass::FREE) {
            parts.push("free");
        }
        if self.contains(LicenseClass::ATTRIBUTION) {
            parts.push("attribution");
        }
        if self.contains(LicenseClass::TRANSCLUSION_OK) {
            parts.push("transclusion-ok");
        }
        if self.contains(LicenseClass::RESTRICTED) {
            parts.push("restricted");
        }
        if self.contains(LicenseClass::UNKNOWN) {
            parts.push("unknown");
        }
        write!(f, "{}", parts.join("|"))
    }
}

/// A lifecycle transition recorded on a Work (append-only history).
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub enum LifecycleEventKind {
    Archived,
    Unarchived,
    /// FR-45: admin hard-delete. The work is removed from the works map;
    /// this event lives on in the (already-checkpointed) lifecycle
    /// history of prior manifest generations — an audit trail of the
    /// deletion itself.
    AdminDeleted,
}

#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct WorkLifecycleEvent {
    pub kind: LifecycleEventKind,
    pub actor_club: BeId,
    pub timestamp: u64,
}

#[derive(Debug, Clone)]
pub struct Work {
    be_id: BeId,
    owner: Option<BeId>,
    current_edition: Edition,
    revision_count: u64,
    revision_history: BTreeMap<u64, Edition>,
    read_club: Option<BeId>,
    edit_club: Option<BeId>,
    history_club: Option<BeId>,
    sponsors: Vec<BeId>,
    endorsements: EndorsementSet,
    is_archived: bool,
    lifecycle_history: Vec<WorkLifecycleEvent>,
    kind: WorkKind,
    license: License,
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
            history_club: None,
            sponsors: Vec::new(),
            endorsements: EndorsementSet::new(),
            is_archived: false,
            lifecycle_history: Vec::new(),
            kind: WorkKind::Document,
            license: License::AllRightsReserved,
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
            history_club: None,
            sponsors: Vec::new(),
            endorsements: EndorsementSet::new(),
            is_archived: false,
            lifecycle_history: Vec::new(),
            kind: WorkKind::Document,
            license: License::AllRightsReserved,
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

    /// The work's kind (Document / Fragment / Person / Concept / Collection /
    /// Commentary). See FR-22.
    pub fn kind(&self) -> WorkKind {
        self.kind
    }

    pub fn set_kind(&mut self, kind: WorkKind) {
        self.kind = kind;
    }

    pub fn license(&self) -> License {
        self.license
    }

    pub fn set_license(&mut self, license: License) {
        self.license = license;
    }

    /// Current archive (soft-delete) state. Archived works are hidden from the
    /// default work list but never destroyed — they can be unarchived.
    pub fn is_archived(&self) -> bool {
        self.is_archived
    }

    /// Append-only lifecycle history (archive/unarchive transitions). Replaying
    /// it answers "was this work archived at time T?".
    pub fn lifecycle_history(&self) -> &[WorkLifecycleEvent] {
        &self.lifecycle_history
    }

    /// Archive (soft-delete) the work, recording who/when.
    pub fn archive(&mut self, actor_club: BeId, timestamp: u64) {
        self.is_archived = true;
        self.lifecycle_history.push(WorkLifecycleEvent {
            kind: LifecycleEventKind::Archived,
            actor_club,
            timestamp,
        });
    }

    /// Unarchive (restore) the work, recording who/when.
    pub fn unarchive(&mut self, actor_club: BeId, timestamp: u64) {
        self.is_archived = false;
        self.lifecycle_history.push(WorkLifecycleEvent {
            kind: LifecycleEventKind::Unarchived,
            actor_club,
            timestamp,
        });
    }

    /// FR-45: mark for admin hard-delete (records the event; the works
    /// map removal happens server-side, chunks go to GC grace).
    pub fn admin_delete(&mut self, actor_club: BeId, timestamp: u64) {
        self.is_archived = true;
        self.lifecycle_history.push(WorkLifecycleEvent {
            kind: LifecycleEventKind::AdminDeleted,
            actor_club,
            timestamp,
        });
    }

    /// Restore the archived state + lifecycle history from a persisted snapshot
    /// (manifest). Does not push a new event.
    pub(crate) fn restore_archived_state(
        &mut self,
        is_archived: bool,
        history: Vec<WorkLifecycleEvent>,
    ) {
        self.is_archived = is_archived;
        self.lifecycle_history = history;
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

    pub fn try_revise(
        &mut self,
        new_edition: Edition,
    ) -> Result<(), super::snapshot::SnapshotError> {
        if self.edit_club == Some(0) {
            return Err(super::snapshot::SnapshotError::CannotEditFrozen {
                work_id: self.be_id,
            });
        }
        self.revise(new_edition);
        Ok(())
    }

    pub fn update_current_edition(&mut self, edition: Edition) {
        self.current_edition = edition;
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

    /// Club that controls access to revision history. If None, falls back to
    /// read_club (backward-compatible: anyone who can read can see history).
    pub fn history_club(&self) -> Option<BeId> {
        self.history_club
    }

    pub fn set_history_club(&mut self, club: Option<BeId>) {
        self.history_club = club;
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

    /// Clear in-memory revision history while preserving revision_count.
    /// Simulates what happens on server restart (history is on disk only).
    #[cfg(test)]
    pub fn clear_revision_history(&mut self) {
        self.revision_history.clear();
    }

    pub fn load_revision(&mut self, number: u64, edition: Edition) {
        if number != self.revision_count {
            self.revision_history.insert(number, edition);
        }
    }

    pub fn set_revision_count(&mut self, count: u64) {
        self.revision_count = count;
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
        assert_eq!(work.fetch_revision(0).unwrap().to_text(), "v1");

        work.revise(edition_v3);
        assert_eq!(work.revision_count(), 2);
        assert_eq!(work.edition().to_text(), "v3");
        assert_eq!(work.fetch_revision(1).unwrap().to_text(), "v2");
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
            work.revise(Edition::from_one(
                i as i64,
                RangeElement::text(format!("v{}", i)),
            ));
        }
        assert_eq!(work.revision_count(), 99);
        assert_eq!(work.revision_history().len(), 99);
        assert_eq!(work.fetch_revision(0).unwrap().to_text(), "v0");
        assert_eq!(
            work.fetch_revision(50)
                .unwrap()
                .fetch(50)
                .unwrap()
                .as_text()
                .unwrap(),
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
