use std::collections::BTreeMap;

use super::backend::BeId;
use super::edition::Edition;
use super::work::Work;

const FROZEN_SENTINEL: BeId = 0;

#[derive(Debug, Clone, PartialEq)]
pub struct Snapshot {
    source_work_id: BeId,
    frozen_at_revision: u64,
    edition: Edition,
}

impl Snapshot {
    pub fn new(source_work_id: BeId, revision: u64, edition: Edition) -> Self {
        Snapshot {
            source_work_id,
            frozen_at_revision: revision,
            edition,
        }
    }

    pub fn from_work(work: &Work) -> Self {
        Snapshot {
            source_work_id: work.be_id(),
            frozen_at_revision: work.revision_count(),
            edition: work.edition().clone(),
        }
    }

    pub fn source_work_id(&self) -> BeId {
        self.source_work_id
    }

    pub fn frozen_at_revision(&self) -> u64 {
        self.frozen_at_revision
    }

    pub fn edition(&self) -> &Edition {
        &self.edition
    }

    pub fn into_edition(self) -> Edition {
        self.edition
    }

    pub fn to_frozen_work(&self, new_be_id: BeId) -> Work {
        let mut work = Work::new(new_be_id, self.edition.clone());
        work.set_edit_club(Some(FROZEN_SENTINEL));
        work.set_revision_history(self.frozen_at_revision, BTreeMap::new());
        work
    }
}

pub fn is_frozen(work: &Work) -> bool {
    work.edit_club() == Some(FROZEN_SENTINEL)
}

pub fn freeze_work(work: &Work, snapshot_be_id: BeId) -> Work {
    let snapshot = Snapshot::from_work(work);
    snapshot.to_frozen_work(snapshot_be_id)
}

pub fn validate_frozen_for_context(work: &Work) -> Result<(), SnapshotError> {
    if !is_frozen(work) {
        return Err(SnapshotError::NotFrozen {
            work_id: work.be_id(),
        });
    }
    Ok(())
}

pub fn validate_not_frozen_for_edit(work: &Work) -> Result<(), SnapshotError> {
    if is_frozen(work) {
        return Err(SnapshotError::CannotEditFrozen {
            work_id: work.be_id(),
        });
    }
    Ok(())
}

#[derive(Debug, Clone, PartialEq)]
pub enum SnapshotError {
    NotFrozen { work_id: BeId },
    CannotEditFrozen { work_id: BeId },
}

impl std::fmt::Display for SnapshotError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            SnapshotError::NotFrozen { work_id } => {
                write!(f, "work {} is not frozen; original context must be frozen", work_id)
            }
            SnapshotError::CannotEditFrozen { work_id } => {
                write!(f, "cannot edit frozen work {}", work_id)
            }
        }
    }
}

impl std::error::Error for SnapshotError {}

#[derive(Debug, Clone)]
pub struct SnapshotStore {
    snapshots: BTreeMap<BeId, Snapshot>,
    next_id: BeId,
}

impl SnapshotStore {
    pub fn new() -> Self {
        SnapshotStore {
            snapshots: BTreeMap::new(),
            next_id: 1,
        }
    }

    pub fn with_start_id(mut self, start_id: BeId) -> Self {
        self.next_id = start_id;
        self
    }

    pub fn freeze(&mut self, work: &Work) -> BeId {
        let snapshot_id = self.next_id;
        self.next_id += 1;
        let snapshot = Snapshot::from_work(work);
        self.snapshots.insert(snapshot_id, snapshot);
        snapshot_id
    }

    pub fn freeze_at_revision(&mut self, work: &Work, revision: u64) -> Option<BeId> {
        let edition = work.fetch_revision(revision)?.clone();
        let snapshot_id = self.next_id;
        self.next_id += 1;
        let snapshot = Snapshot::new(work.be_id(), revision, edition);
        self.snapshots.insert(snapshot_id, snapshot);
        Some(snapshot_id)
    }

    pub fn get(&self, id: BeId) -> Option<&Snapshot> {
        self.snapshots.get(&id)
    }

    pub fn get_edition(&self, id: BeId) -> Option<&Edition> {
        self.snapshots.get(&id).map(|s| s.edition())
    }

    pub fn get_frozen_work(&self, id: BeId) -> Option<Work> {
        self.snapshots.get(&id).map(|s| s.to_frozen_work(id))
    }

    pub fn remove(&mut self, id: BeId) -> Option<Snapshot> {
        self.snapshots.remove(&id)
    }

    pub fn contains(&self, id: BeId) -> bool {
        self.snapshots.contains_key(&id)
    }

    pub fn len(&self) -> usize {
        self.snapshots.len()
    }

    pub fn is_empty(&self) -> bool {
        self.snapshots.is_empty()
    }

    pub fn snapshots_for_work(&self, work_id: BeId) -> Vec<(BeId, &Snapshot)> {
        self.snapshots
            .iter()
            .filter(|(_, s)| s.source_work_id == work_id)
            .map(|(id, s)| (*id, s))
            .collect()
    }
}

impl Default for SnapshotStore {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn snapshot_from_work() {
        let work = Work::new(1, Edition::from_text("hello"));
        let snapshot = Snapshot::from_work(&work);
        assert_eq!(snapshot.source_work_id(), 1);
        assert_eq!(snapshot.frozen_at_revision(), 0);
        assert_eq!(snapshot.edition().to_text(), "hello");
    }

    #[test]
    fn snapshot_from_work_with_revisions() {
        let mut work = Work::new(1, Edition::from_text("v0"));
        work.revise(Edition::from_text("v1"));
        work.revise(Edition::from_text("v2"));
        let snapshot = Snapshot::from_work(&work);
        assert_eq!(snapshot.frozen_at_revision(), 2);
        assert_eq!(snapshot.edition().to_text(), "v2");
    }

    #[test]
    fn snapshot_to_frozen_work() {
        let work = Work::new(1, Edition::from_text("content"));
        let snapshot = Snapshot::from_work(&work);
        let frozen = snapshot.to_frozen_work(99);
        assert!(is_frozen(&frozen));
        assert_eq!(frozen.be_id(), 99);
        assert_eq!(frozen.edition().to_text(), "content");
    }

    #[test]
    fn frozen_work_cannot_be_edited() {
        let work = Work::new(1, Edition::from_text("content"));
        let snapshot = Snapshot::from_work(&work);
        let frozen = snapshot.to_frozen_work(99);
        assert!(validate_not_frozen_for_edit(&frozen).is_err());
    }

    #[test]
    fn normal_work_can_be_edited() {
        let work = Work::new(1, Edition::from_text("content"));
        assert!(validate_not_frozen_for_edit(&work).is_ok());
    }

    #[test]
    fn validate_frozen_context() {
        let work = Work::new(1, Edition::from_text("content"));
        let snapshot = Snapshot::from_work(&work);
        let frozen = snapshot.to_frozen_work(99);
        assert!(validate_frozen_for_context(&frozen).is_ok());
        assert!(validate_frozen_for_context(&work).is_err());
    }

    #[test]
    fn snapshot_independence() {
        let mut work = Work::new(1, Edition::from_text("original"));
        let snapshot = Snapshot::from_work(&work);
        work.revise(Edition::from_text("modified"));
        assert_eq!(snapshot.edition().to_text(), "original");
        assert_eq!(work.edition().to_text(), "modified");
    }

    #[test]
    fn snapshot_store_freeze() {
        let mut store = SnapshotStore::new();
        let work = Work::new(1, Edition::from_text("hello"));
        let id = store.freeze(&work);
        assert_eq!(id, 1);
        let snapshot = store.get(id).unwrap();
        assert_eq!(snapshot.edition().to_text(), "hello");
    }

    #[test]
    fn snapshot_store_multiple_freezes() {
        let mut store = SnapshotStore::new();
        let work1 = Work::new(1, Edition::from_text("a"));
        let work2 = Work::new(2, Edition::from_text("b"));
        let id1 = store.freeze(&work1);
        let id2 = store.freeze(&work2);
        assert_ne!(id1, id2);
        assert_eq!(store.get_edition(id1).unwrap().to_text(), "a");
        assert_eq!(store.get_edition(id2).unwrap().to_text(), "b");
    }

    #[test]
    fn snapshot_store_freeze_at_revision() {
        let mut store = SnapshotStore::new();
        let mut work = Work::new(1, Edition::from_text("v0"));
        work.revise(Edition::from_text("v1"));
        work.revise(Edition::from_text("v2"));
        let id = store.freeze_at_revision(&work, 1).unwrap();
        let snapshot = store.get(id).unwrap();
        assert_eq!(snapshot.frozen_at_revision(), 1);
        assert_eq!(snapshot.edition().to_text(), "v1");
    }

    #[test]
    fn snapshot_store_freeze_at_revision_not_found() {
        let store = SnapshotStore::new();
        let work = Work::new(1, Edition::from_text("v0"));
        let result = std::panic::catch_unwind(|| {
            let mut store = store;
            store.freeze_at_revision(&work, 99)
        });
        assert!(result.is_ok());
        assert!(result.unwrap().is_none());
    }

    #[test]
    fn snapshot_store_get_frozen_work() {
        let mut store = SnapshotStore::new();
        let work = Work::new(1, Edition::from_text("hello"));
        let id = store.freeze(&work);
        let frozen = store.get_frozen_work(id).unwrap();
        assert!(is_frozen(&frozen));
        assert_eq!(frozen.edition().to_text(), "hello");
    }

    #[test]
    fn snapshot_store_remove() {
        let mut store = SnapshotStore::new();
        let work = Work::new(1, Edition::from_text("hello"));
        let id = store.freeze(&work);
        assert!(store.contains(id));
        let removed = store.remove(id).unwrap();
        assert_eq!(removed.edition().to_text(), "hello");
        assert!(!store.contains(id));
    }

    #[test]
    fn snapshot_store_snapshots_for_work() {
        let mut store = SnapshotStore::new();
        let mut work = Work::new(1, Edition::from_text("v0"));
        let id1 = store.freeze(&work);
        work.revise(Edition::from_text("v1"));
        let id2 = store.freeze(&work);
        let _id3 = store.freeze(&Work::new(2, Edition::from_text("other")));
        let for_work1 = store.snapshots_for_work(1);
        assert_eq!(for_work1.len(), 2);
        assert_eq!(for_work1[0].0, id1);
        assert_eq!(for_work1[1].0, id2);
    }

    #[test]
    fn snapshot_error_display() {
        let err = SnapshotError::NotFrozen { work_id: 42 };
        assert!(err.to_string().contains("42"));
        assert!(err.to_string().contains("not frozen"));

        let err = SnapshotError::CannotEditFrozen { work_id: 99 };
        assert!(err.to_string().contains("99"));
        assert!(err.to_string().contains("cannot edit"));
    }

    #[test]
    fn freeze_work_function() {
        let work = Work::new(1, Edition::from_text("content"));
        let frozen = freeze_work(&work, 50);
        assert!(is_frozen(&frozen));
        assert_eq!(frozen.be_id(), 50);
        assert_eq!(frozen.edition().to_text(), "content");
    }

    #[test]
    fn snapshot_store_default() {
        let store = SnapshotStore::default();
        assert!(store.is_empty());
    }

    #[test]
    fn snapshot_store_with_start_id() {
        let store = SnapshotStore::new().with_start_id(1000);
        let work = Work::new(1, Edition::from_text("hello"));
        let mut store = store;
        let id = store.freeze(&work);
        assert_eq!(id, 1000);
    }

    #[test]
    fn snapshot_preserves_revision_count() {
        let mut work = Work::new(1, Edition::from_text("v0"));
        work.revise(Edition::from_text("v1"));
        work.revise(Edition::from_text("v2"));
        let frozen = freeze_work(&work, 99);
        assert_eq!(frozen.revision_count(), 2);
    }
}
