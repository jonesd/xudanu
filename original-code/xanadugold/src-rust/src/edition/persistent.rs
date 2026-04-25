use std::any::Any;
use std::collections::BTreeMap;
use std::sync::Arc;

use crate::edition::backend::BeId;
use crate::edition::edition::Edition;
use crate::edition::orgl::OrglRoot;
use crate::edition::range_element::{Carrier, RangeElement};
use crate::edition::work::Work;
use crate::edition::xn_region::XnRegion;
use crate::persist::engine::StorageError;
use crate::persist::persistent::{FlockId, FlockInfo};
use crate::persist::traits::Persistent;

#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct EditionSnapshot {
    entries: Vec<(i64, RangeElement)>,
    default: Option<RangeElement>,
    domain_start: Option<i64>,
    domain_infinite_above: bool,
}

impl EditionSnapshot {
    pub fn from_edition(edition: &Edition) -> Self {
        let entries: Vec<(i64, RangeElement)> = edition
            .all_entries()
            .into_iter()
            .filter(|(pos, c)| {
                if let Some(default) = &edition.default_value() {
                    if c.element == *default {
                        return false;
                    }
                }
                true
            })
            .map(|(pos, c)| (pos, c.element.clone()))
            .collect();

        let default = edition.default_value();
        let domain = edition.domain();

        EditionSnapshot {
            entries,
            default,
            domain_start: None,
            domain_infinite_above: !domain.is_finite(),
        }
    }

    pub fn to_edition(&self) -> Edition {
        if let Some(ref default) = self.default {
            let region = if self.domain_infinite_above {
                XnRegion::above(self.domain_start.unwrap_or(0))
            } else {
                XnRegion::empty()
            };
            let carriers: Vec<(i64, Arc<Carrier>)> = self.entries.iter()
                .map(|(pos, elem)| (*pos, Arc::new(Carrier::new(elem.clone()))))
                .collect();
            Edition { orgl: OrglRoot::from_bulk_entries(carriers, Some(Arc::new(Carrier::new(default.clone()))), region) }
        } else {
            let carriers: Vec<(i64, Arc<Carrier>)> = self.entries.iter()
                .map(|(pos, elem)| (*pos, Arc::new(Carrier::new(elem.clone()))))
                .collect();
            let n = carriers.len();
            let region = if n > 0 {
                let first = carriers.first().unwrap().0;
                let last = carriers.last().unwrap().0;
                XnRegion::interval(first, last + 1)
            } else {
                XnRegion::empty()
            };
            Edition { orgl: OrglRoot::from_bulk_entries(carriers, None, region) }
        }
    }
}

#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct WorkSnapshot {
    be_id: BeId,
    owner: Option<BeId>,
    revision_count: u64,
    current: EditionSnapshot,
    history: BTreeMap<u64, EditionSnapshot>,
    read_club: Option<BeId>,
    edit_club: Option<BeId>,
    sponsors: Vec<BeId>,
}

impl WorkSnapshot {
    pub fn from_work(work: &Work) -> Self {
        WorkSnapshot {
            be_id: work.be_id(),
            owner: work.owner(),
            revision_count: work.revision_count(),
            current: EditionSnapshot::from_edition(work.edition()),
            history: work
                .revision_history()
                .iter()
                .map(|(k, v)| (*k, EditionSnapshot::from_edition(v)))
                .collect(),
            read_club: work.read_club(),
            edit_club: work.edit_club(),
            sponsors: work.sponsors().to_vec(),
        }
    }

    pub fn to_work(&self, flock_id: FlockId, info: Option<FlockInfo>) -> PersistentWork {
        let current = self.current.to_edition();
        let history: BTreeMap<u64, Edition> = self.history
            .iter()
            .map(|(k, v)| (*k, v.to_edition()))
            .collect();
        let mut work = Work::new(self.be_id, current);
        work.set_revision_history(self.revision_count, history);
        work.set_owner(self.owner);
        work.set_read_club(self.read_club);
        work.set_edit_club(self.edit_club);
        for s in &self.sponsors {
            work.add_sponsor(*s);
        }
        PersistentWork {
            flock_id,
            info,
            work,
        }
    }
}

#[derive(Debug)]
pub struct PersistentWork {
    flock_id: FlockId,
    info: Option<FlockInfo>,
    work: Work,
}

impl PersistentWork {
    pub fn new(be_id: BeId, edition: Edition) -> Self {
        let flock_id = FlockId::new(be_id, 0);
        PersistentWork {
            flock_id,
            info: None,
            work: Work::new(be_id, edition),
        }
    }

    pub fn with_flock_id(flock_id: FlockId, work: Work) -> Self {
        PersistentWork {
            flock_id,
            info: None,
            work,
        }
    }

    pub fn work(&self) -> &Work {
        &self.work
    }

    pub fn work_mut(&mut self) -> &mut Work {
        &mut self.work
    }
}

impl Persistent for PersistentWork {
    fn flock_id(&self) -> FlockId { self.flock_id }
    fn set_flock_id(&mut self, id: FlockId) { self.flock_id = id; }
    fn flock_info(&self) -> Option<&FlockInfo> { self.info.as_ref() }
    fn set_flock_info(&mut self, info: Option<FlockInfo>) { self.info = info; }
    fn flock_info_mut(&mut self) -> Option<&mut FlockInfo> { self.info.as_mut() }
    fn as_any(&self) -> &dyn Any { self }
    fn as_any_mut(&mut self) -> &mut dyn Any { self }
    fn clone_boxed(&self) -> Box<dyn Persistent> {
        Box::new(PersistentWork {
            flock_id: self.flock_id,
            info: self.info.clone(),
            work: self.work.clone(),
        })
    }
    fn type_tag(&self) -> &'static str { "Work" }
    fn to_bytes(&self) -> Result<Vec<u8>, StorageError> {
        let snapshot = WorkSnapshot::from_work(&self.work);
        serde_json::to_vec(&snapshot).map_err(|e| StorageError::Io(e.to_string()))
    }
}

pub fn deserialize_work(data: &[u8], flock_id: FlockId) -> Result<Box<dyn Persistent>, StorageError> {
    let snapshot: WorkSnapshot = serde_json::from_slice(data)
        .map_err(|e| StorageError::CorruptData(e.to_string()))?;
    Ok(Box::new(snapshot.to_work(flock_id, None)))
}

#[derive(Debug)]
pub struct PersistentEdition {
    flock_id: FlockId,
    info: Option<FlockInfo>,
    edition: Edition,
}

impl PersistentEdition {
    pub fn new(flock_id: FlockId, edition: Edition) -> Self {
        PersistentEdition {
            flock_id,
            info: None,
            edition,
        }
    }

    pub fn edition(&self) -> &Edition {
        &self.edition
    }

    pub fn edition_mut(&mut self) -> &mut Edition {
        &mut self.edition
    }
}

impl Persistent for PersistentEdition {
    fn flock_id(&self) -> FlockId { self.flock_id }
    fn set_flock_id(&mut self, id: FlockId) { self.flock_id = id; }
    fn flock_info(&self) -> Option<&FlockInfo> { self.info.as_ref() }
    fn set_flock_info(&mut self, info: Option<FlockInfo>) { self.info = info; }
    fn flock_info_mut(&mut self) -> Option<&mut FlockInfo> { self.info.as_mut() }
    fn as_any(&self) -> &dyn Any { self }
    fn as_any_mut(&mut self) -> &mut dyn Any { self }
    fn clone_boxed(&self) -> Box<dyn Persistent> {
        Box::new(PersistentEdition {
            flock_id: self.flock_id,
            info: self.info.clone(),
            edition: self.edition.clone(),
        })
    }
    fn type_tag(&self) -> &'static str { "Edition" }
    fn to_bytes(&self) -> Result<Vec<u8>, StorageError> {
        let snapshot = EditionSnapshot::from_edition(&self.edition);
        serde_json::to_vec(&snapshot).map_err(|e| StorageError::Io(e.to_string()))
    }
}

pub fn deserialize_edition(data: &[u8], flock_id: FlockId) -> Result<Box<dyn Persistent>, StorageError> {
    let snapshot: EditionSnapshot = serde_json::from_slice(data)
        .map_err(|e| StorageError::CorruptData(e.to_string()))?;
    Ok(Box::new(PersistentEdition {
        flock_id,
        info: None,
        edition: snapshot.to_edition(),
    }))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn edition_snapshot_roundtrip_simple() {
        let edition = Edition::from_text("hello");
        let snapshot = EditionSnapshot::from_edition(&edition);
        let restored = snapshot.to_edition();
        assert_eq!(restored.to_text(), "hello");
    }

    #[test]
    fn edition_snapshot_roundtrip_sparse() {
        let edition = Edition::from_one(0, RangeElement::data(vec![1]))
            .with(100, RangeElement::data(vec![2]))
            .with(999, RangeElement::data(vec![3]));
        let snapshot = EditionSnapshot::from_edition(&edition);
        let restored = snapshot.to_edition();
        assert_eq!(restored.count(), 3);
        assert!(restored.has_position(0));
        assert!(restored.has_position(100));
        assert!(restored.has_position(999));
    }

    #[test]
    fn edition_snapshot_roundtrip_infinite() {
        let region = XnRegion::above(10);
        let edition = Edition::with_default(region, RangeElement::data(vec![42]))
            .with(5, RangeElement::data(vec![99]));
        let snapshot = EditionSnapshot::from_edition(&edition);
        let restored = snapshot.to_edition();
        assert!(restored.is_infinite());
        assert_eq!(restored.fetch(5).unwrap().as_bytes().unwrap(), &[99]);
        assert_eq!(restored.fetch(100).unwrap().as_bytes().unwrap(), &[42]);
    }

    #[test]
    fn persistent_work_roundtrip() {
        let edition = Edition::from_text("v1");
        let work = Work::new(1, edition);
        let pw = PersistentWork::new(1, work.edition().clone());
        let data = pw.to_bytes().unwrap();
        let restored = deserialize_work(&data, pw.flock_id()).unwrap();
        let pw2 = restored.as_any().downcast_ref::<PersistentWork>().unwrap();
        assert_eq!(pw2.work().edition().to_text(), "v1");
        assert_eq!(pw2.work().be_id(), 1);
    }

    #[test]
    fn persistent_work_with_history() {
        let v1 = Edition::from_text("v1");
        let v2 = Edition::from_text("v2");
        let mut work = Work::new(1, v1);
        work.revise(v2);
        let pw = PersistentWork::with_flock_id(FlockId::new(1, 0), work);
        let data = pw.to_bytes().unwrap();
        let restored = deserialize_work(&data, pw.flock_id()).unwrap();
        let pw2 = restored.as_any().downcast_ref::<PersistentWork>().unwrap();
        assert_eq!(pw2.work().edition().to_text(), "v2");
        assert_eq!(pw2.work().revision_count(), 1);
        assert_eq!(pw2.work().fetch_revision(0).unwrap().to_text(), "v1");
    }

    #[test]
    fn persistent_edition_roundtrip() {
        let edition = Edition::from_text("test data");
        let pe = PersistentEdition::new(FlockId::new(42, 7), edition);
        let data = pe.to_bytes().unwrap();
        let restored = deserialize_edition(&data, pe.flock_id()).unwrap();
        let pe2 = restored.as_any().downcast_ref::<PersistentEdition>().unwrap();
        assert_eq!(pe2.edition().to_text(), "test data");
        assert_eq!(pe2.flock_id(), FlockId::new(42, 7));
    }

    #[test]
    fn persistent_work_preserves_clubs_and_sponsors() {
        let mut work = Work::new(1, Edition::from_text("content"));
        work.set_read_club(Some(10));
        work.set_edit_club(Some(20));
        work.add_sponsor(30);
        work.add_sponsor(40);
        let pw = PersistentWork::with_flock_id(FlockId::new(1, 0), work);
        let data = pw.to_bytes().unwrap();
        let restored = deserialize_work(&data, pw.flock_id()).unwrap();
        let pw2 = restored.as_any().downcast_ref::<PersistentWork>().unwrap();
        assert_eq!(pw2.work().read_club(), Some(10));
        assert_eq!(pw2.work().edit_club(), Some(20));
        assert_eq!(pw2.work().sponsors(), &[30, 40]);
    }

    #[test]
    #[ignore]
    fn stress_persistent_work_large_edition() {
        let mut edition = Edition::empty();
        for i in 0..10_000i64 {
            edition = edition.with(i, RangeElement::data(format!("entry-{}", i).into_bytes()));
        }
        let work = Work::new(1, edition);
        let pw = PersistentWork::with_flock_id(FlockId::new(1, 0), work);
        let data = pw.to_bytes().unwrap();
        assert!(data.len() > 0);

        let restored = deserialize_work(&data, pw.flock_id()).unwrap();
        let pw2 = restored.as_any().downcast_ref::<PersistentWork>().unwrap();
        assert_eq!(pw2.work().edition().count(), 10_000);
        assert_eq!(
            pw2.work().edition().fetch(9999).unwrap().as_bytes().unwrap(),
            b"entry-9999"
        );
    }

    #[test]
    #[ignore]
    fn stress_persistent_100_works() {
        let mut works_data = Vec::new();
        for w in 0..100u64 {
            let text = format!("work-{} content here", w);
            let edition = Edition::from_text(&text);
            let work = Work::new(w, edition);
            let pw = PersistentWork::with_flock_id(FlockId::new(w, 0), work);
            let data = pw.to_bytes().unwrap();
            works_data.push((pw.flock_id(), data));
        }

        for (w, (flock_id, data)) in works_data.into_iter().enumerate() {
            let restored = deserialize_work(&data, flock_id).unwrap();
            let pw = restored.as_any().downcast_ref::<PersistentWork>().unwrap();
            assert_eq!(
                pw.work().edition().to_text(),
                format!("work-{} content here", w as u64)
            );
            assert_eq!(pw.work().be_id(), w as u64);
        }
    }
}
