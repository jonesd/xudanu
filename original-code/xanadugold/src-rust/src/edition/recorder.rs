use std::collections::{HashMap, HashSet};
use std::sync::Arc;

use super::range_element::RangeElement;
use super::xn_region::XnRegion;

pub type RecorderId = u64;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum RecorderKind {
    Transcluders,
    Works,
}

#[derive(Debug, Clone)]
pub struct RecorderQuery {
    pub kind: RecorderKind,
    pub region: Option<XnRegion>,
    pub direct_only: bool,
    pub authority_clubs: Vec<u64>,
    pub endorsement_filter: Option<Vec<u64>>,
}

impl RecorderQuery {
    pub fn transcluders() -> Self {
        RecorderQuery {
            kind: RecorderKind::Transcluders,
            region: None,
            direct_only: false,
            authority_clubs: Vec::new(),
            endorsement_filter: None,
        }
    }

    pub fn works() -> Self {
        RecorderQuery {
            kind: RecorderKind::Works,
            region: None,
            direct_only: false,
            authority_clubs: Vec::new(),
            endorsement_filter: None,
        }
    }

    pub fn with_region(mut self, region: XnRegion) -> Self {
        self.region = Some(region);
        self
    }

    pub fn direct_only(mut self, direct_only: bool) -> Self {
        self.direct_only = direct_only;
        self
    }

    pub fn with_authority(mut self, clubs: Vec<u64>) -> Self {
        self.authority_clubs = clubs;
        self
    }

    pub fn with_endorsement_filter(mut self, endorsements: Vec<u64>) -> Self {
        self.endorsement_filter = Some(endorsements);
        self
    }
}

#[derive(Debug, Clone)]
pub struct RecordedResult {
    pub element: RangeElement,
    pub source_edition_id: Option<u64>,
    pub source_work_id: Option<u64>,
    pub is_direct: bool,
    pub timestamp: u64,
}

#[derive(Debug, Clone)]
pub struct Fossil {
    pub id: RecorderId,
    pub query: RecorderQuery,
    pub results: Vec<RecordedResult>,
    pub recorded_fingerprints: HashSet<Vec<u8>>,
    pub is_extinct: bool,
    pub reference_count: u64,
    pub created_at: u64,
}

impl Fossil {
    pub fn new(id: RecorderId, query: RecorderQuery) -> Self {
        Fossil {
            id,
            query,
            results: Vec::new(),
            recorded_fingerprints: HashSet::new(),
            is_extinct: false,
            reference_count: 1,
            created_at: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs(),
        }
    }

    pub fn record(&mut self, element: RangeElement, source_edition_id: Option<u64>, source_work_id: Option<u64>, is_direct: bool) -> bool {
        if self.is_extinct {
            return false;
        }
        let fp = element.content_fingerprint().to_vec();
        if self.recorded_fingerprints.contains(&fp) {
            return false;
        }
        self.recorded_fingerprints.insert(fp);
        self.results.push(RecordedResult {
            element,
            source_edition_id,
            source_work_id,
            is_direct,
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs(),
        });
        true
    }

    pub fn extinguish(&mut self) {
        self.is_extinct = true;
        self.reference_count = 0;
    }

    pub fn add_reference(&mut self) {
        if !self.is_extinct {
            self.reference_count += 1;
        }
    }

    pub fn remove_reference(&mut self) -> bool {
        if self.reference_count > 0 {
            self.reference_count -= 1;
        }
        self.reference_count == 0 && !self.is_extinct
    }

    pub fn is_purgeable(&self) -> bool {
        self.reference_count == 0 || self.is_extinct
    }

    pub fn result_count(&self) -> usize {
        self.results.len()
    }

    pub fn accepts(&self, element: &RangeElement) -> bool {
        match self.query.kind {
            RecorderKind::Transcluders => element.as_edition_id().is_some(),
            RecorderKind::Works => element.as_work_id().is_some(),
        }
    }

    pub fn matches_filters(&self, element: &RangeElement, is_direct: bool) -> bool {
        if self.query.direct_only && !is_direct {
            return false;
        }
        if let Some(ref filter) = self.query.endorsement_filter {
            if let Some(eid) = element.as_edition_id() {
                if !filter.contains(&eid) {
                    return false;
                }
            }
            if let Some(wid) = element.as_work_id() {
                if !filter.contains(&wid) {
                    return false;
                }
            }
        }
        true
    }
}

pub trait AgendaItem: std::fmt::Debug + Send + Sync {
    fn step(&mut self) -> bool;
    fn is_complete(&self) -> bool;
}

#[derive(Debug)]
pub struct Matcher {
    pub target_edition_id: Option<u64>,
    pub fossil_id: RecorderId,
    pub query: RecorderQuery,
    completed: bool,
}

impl Matcher {
    pub fn new(fossil_id: RecorderId, query: RecorderQuery, target_edition_id: Option<u64>) -> Self {
        Matcher {
            target_edition_id,
            fossil_id,
            query,
            completed: false,
        }
    }
}

impl AgendaItem for Matcher {
    fn step(&mut self) -> bool {
        self.completed = true;
        true
    }

    fn is_complete(&self) -> bool {
        self.completed
    }
}

#[derive(Debug)]
pub struct RecorderTrigger {
    pub fossil_id: RecorderId,
    pub element: RangeElement,
    pub source_edition_id: Option<u64>,
    pub source_work_id: Option<u64>,
    pub is_direct: bool,
    completed: bool,
}

impl RecorderTrigger {
    pub fn new(
        fossil_id: RecorderId,
        element: RangeElement,
        source_edition_id: Option<u64>,
        source_work_id: Option<u64>,
        is_direct: bool,
    ) -> Self {
        RecorderTrigger {
            fossil_id,
            element,
            source_edition_id,
            source_work_id,
            is_direct,
            completed: false,
        }
    }
}

impl AgendaItem for RecorderTrigger {
    fn step(&mut self) -> bool {
        self.completed = true;
        true
    }

    fn is_complete(&self) -> bool {
        self.completed
    }
}

#[derive(Debug)]
pub struct Agenda {
    items: Vec<Box<dyn AgendaItem>>,
}

impl Agenda {
    pub fn new() -> Self {
        Agenda { items: Vec::new() }
    }

    pub fn add(&mut self, item: Box<dyn AgendaItem>) {
        self.items.push(item);
    }

    pub fn step_all(&mut self) -> usize {
        let mut count = 0;
        for item in &mut self.items {
            if !item.is_complete() {
                item.step();
                count += 1;
            }
        }
        self.items.retain(|item| !item.is_complete());
        count
    }

    pub fn is_empty(&self) -> bool {
        self.items.is_empty()
    }

    pub fn len(&self) -> usize {
        self.items.len()
    }
}

impl Default for Agenda {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(Debug)]
pub struct RecorderSystem {
    fossils: HashMap<RecorderId, Fossil>,
    next_id: RecorderId,
    agenda: Agenda,
}

impl RecorderSystem {
    pub fn new() -> Self {
        RecorderSystem {
            fossils: HashMap::new(),
            next_id: 1,
            agenda: Agenda::new(),
        }
    }

    pub fn create_fossil(&mut self, query: RecorderQuery) -> RecorderId {
        let id = self.next_id;
        self.next_id += 1;
        self.fossils.insert(id, Fossil::new(id, query));
        id
    }

    pub fn get_fossil(&self, id: RecorderId) -> Option<&Fossil> {
        self.fossils.get(&id)
    }

    pub fn get_fossil_mut(&mut self, id: RecorderId) -> Option<&mut Fossil> {
        self.fossils.get_mut(&id)
    }

    pub fn extinguish_fossil(&mut self, id: RecorderId) -> bool {
        if let Some(fossil) = self.fossils.get_mut(&id) {
            fossil.extinguish();
            true
        } else {
            false
        }
    }

    pub fn record_result(
        &mut self,
        fossil_id: RecorderId,
        element: RangeElement,
        source_edition_id: Option<u64>,
        source_work_id: Option<u64>,
        is_direct: bool,
    ) -> bool {
        if let Some(fossil) = self.fossils.get_mut(&fossil_id) {
            if fossil.is_extinct {
                return false;
            }
            if !fossil.accepts(&element) {
                return false;
            }
            if !fossil.matches_filters(&element, is_direct) {
                return false;
            }
            fossil.record(element, source_edition_id, source_work_id, is_direct)
        } else {
            false
        }
    }

    pub fn schedule_trigger(
        &mut self,
        fossil_id: RecorderId,
        element: RangeElement,
        source_edition_id: Option<u64>,
        source_work_id: Option<u64>,
        is_direct: bool,
    ) {
        self.agenda.add(Box::new(RecorderTrigger::new(
            fossil_id,
            element,
            source_edition_id,
            source_work_id,
            is_direct,
        )));
    }

    pub fn process_agenda(&mut self) -> usize {
        let mut processed = 0;
        while !self.agenda.is_empty() {
            self.agenda.step_all();
            processed += 1;
        }
        processed
    }

    pub fn purge_extinct(&mut self) -> usize {
        let before = self.fossils.len();
        self.fossils.retain(|_, f| !f.is_purgeable());
        before - self.fossils.len()
    }

    pub fn active_fossil_count(&self) -> usize {
        self.fossils.values().filter(|f| !f.is_extinct).count()
    }

    pub fn total_result_count(&self) -> usize {
        self.fossils.values().map(|f| f.result_count()).sum()
    }

    pub fn fossil_ids(&self) -> Vec<RecorderId> {
        let mut ids: Vec<_> = self.fossils.keys().copied().collect();
        ids.sort();
        ids
    }
}

impl Default for RecorderSystem {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fossil_record_deduplicates() {
        let mut fossil = Fossil::new(1, RecorderQuery::transcluders());
        assert!(fossil.record(RangeElement::edition(42), None, None, true));
        assert!(!fossil.record(RangeElement::edition(42), None, None, true));
        assert_eq!(fossil.result_count(), 1);
    }

    #[test]
    fn fossil_extinguish() {
        let mut fossil = Fossil::new(1, RecorderQuery::works());
        assert!(!fossil.is_extinct);
        fossil.extinguish();
        assert!(fossil.is_extinct);
        assert!(!fossil.record(RangeElement::work(1), None, None, true));
    }

    #[test]
    fn fossil_reference_counting() {
        let mut fossil = Fossil::new(1, RecorderQuery::transcluders());
        assert_eq!(fossil.reference_count, 1);
        fossil.add_reference();
        fossil.add_reference();
        assert_eq!(fossil.reference_count, 3);
        assert!(!fossil.remove_reference());
        assert!(!fossil.remove_reference());
        assert!(fossil.remove_reference());
        assert!(fossil.is_purgeable());
    }

    #[test]
    fn fossil_accepts_transcluders() {
        let fossil = Fossil::new(1, RecorderQuery::transcluders());
        assert!(fossil.accepts(&RangeElement::edition(1)));
        assert!(!fossil.accepts(&RangeElement::work(1)));
    }

    #[test]
    fn fossil_accepts_works() {
        let fossil = Fossil::new(1, RecorderQuery::works());
        assert!(fossil.accepts(&RangeElement::work(1)));
        assert!(!fossil.accepts(&RangeElement::edition(1)));
    }

    #[test]
    fn fossil_direct_only_filter() {
        let query = RecorderQuery::transcluders().direct_only(true);
        let fossil = Fossil::new(1, query);
        assert!(fossil.matches_filters(&RangeElement::edition(1), true));
        assert!(!fossil.matches_filters(&RangeElement::edition(1), false));
    }

    #[test]
    fn fossil_endorsement_filter() {
        let query = RecorderQuery::transcluders().with_endorsement_filter(vec![10, 20]);
        let fossil = Fossil::new(1, query);
        assert!(fossil.matches_filters(&RangeElement::edition(10), true));
        assert!(!fossil.matches_filters(&RangeElement::edition(99), true));
    }

    #[test]
    fn recorder_system_create_and_get() {
        let mut sys = RecorderSystem::new();
        let id = sys.create_fossil(RecorderQuery::transcluders());
        assert_eq!(id, 1);
        let fossil = sys.get_fossil(id).unwrap();
        assert_eq!(fossil.id, id);
    }

    #[test]
    fn recorder_system_record_result() {
        let mut sys = RecorderSystem::new();
        let id = sys.create_fossil(RecorderQuery::transcluders());
        assert!(sys.record_result(id, RangeElement::edition(42), Some(1), Some(10), true));
        let fossil = sys.get_fossil(id).unwrap();
        assert_eq!(fossil.result_count(), 1);
        assert_eq!(fossil.results[0].source_edition_id, Some(1));
        assert!(fossil.results[0].is_direct);
    }

    #[test]
    fn recorder_system_rejects_wrong_kind() {
        let mut sys = RecorderSystem::new();
        let id = sys.create_fossil(RecorderQuery::works());
        assert!(!sys.record_result(id, RangeElement::edition(42), None, None, true));
    }

    #[test]
    fn recorder_system_schedule_and_process() {
        let mut sys = RecorderSystem::new();
        let id = sys.create_fossil(RecorderQuery::transcluders());
        sys.schedule_trigger(id, RangeElement::edition(1), Some(10), Some(5), true);
        sys.schedule_trigger(id, RangeElement::edition(2), Some(11), Some(6), false);
        assert!(!sys.agenda.is_empty());
        sys.record_result(id, RangeElement::edition(1), Some(10), Some(5), true);
        sys.record_result(id, RangeElement::edition(2), Some(11), Some(6), false);
        let count = sys.process_agenda();
        assert!(count >= 1);
        assert!(sys.agenda.is_empty());
        let fossil = sys.get_fossil(id).unwrap();
        assert_eq!(fossil.result_count(), 2);
    }

    #[test]
    fn recorder_system_purge_extinct() {
        let mut sys = RecorderSystem::new();
        let id1 = sys.create_fossil(RecorderQuery::transcluders());
        let _id2 = sys.create_fossil(RecorderQuery::works());
        sys.extinguish_fossil(id1);
        let purged = sys.purge_extinct();
        assert_eq!(purged, 1);
        assert_eq!(sys.active_fossil_count(), 1);
    }

    #[test]
    fn recorder_system_stats() {
        let mut sys = RecorderSystem::new();
        let id1 = sys.create_fossil(RecorderQuery::transcluders());
        let _id2 = sys.create_fossil(RecorderQuery::works());
        sys.record_result(id1, RangeElement::edition(1), None, None, true);
        sys.record_result(id1, RangeElement::edition(2), None, None, true);
        assert_eq!(sys.active_fossil_count(), 2);
        assert_eq!(sys.total_result_count(), 2);
        assert_eq!(sys.fossil_ids(), vec![1, 2]);
    }

    #[test]
    fn recorder_query_builders() {
        let q = RecorderQuery::transcluders()
            .with_region(XnRegion::interval(0, 10))
            .direct_only(true)
            .with_authority(vec![1, 2])
            .with_endorsement_filter(vec![10]);
        assert_eq!(q.kind, RecorderKind::Transcluders);
        assert!(q.region.is_some());
        assert!(q.direct_only);
        assert_eq!(q.authority_clubs, vec![1, 2]);
        assert_eq!(q.endorsement_filter, Some(vec![10]));
    }

    #[test]
    fn agenda_step_completes_items() {
        let mut agenda = Agenda::new();
        agenda.add(Box::new(Matcher::new(1, RecorderQuery::transcluders(), None)));
        assert_eq!(agenda.len(), 1);
        let count = agenda.step_all();
        assert_eq!(count, 1);
        assert!(agenda.is_empty());
    }

    #[test]
    fn fossil_created_timestamp() {
        let fossil = Fossil::new(1, RecorderQuery::transcluders());
        assert!(fossil.created_at > 0);
    }

    #[test]
    fn recorded_result_timestamp() {
        let mut fossil = Fossil::new(1, RecorderQuery::transcluders());
        fossil.record(RangeElement::edition(1), None, None, true);
        assert!(fossil.results[0].timestamp > 0);
    }
}
