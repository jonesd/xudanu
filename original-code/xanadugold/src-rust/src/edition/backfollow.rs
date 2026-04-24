use std::cell::RefCell;
use std::collections::HashSet;
use std::rc::Rc;

use super::canopy::{BertCanopy, CanopyCrumData, SensorCanopy, compute_join, propagate_flags};
use super::edition::Edition;
use super::grandmap::GrandMap;
use super::props::{BertProp, PropFinder};
use super::range_element::RangeElement;
use super::transclusion::{TrailBlazer, TransclusionIndex, TransclusionQuery, TransclusionResult, WorkQuery};
use super::work::Work;
use crate::ent::htree::HUpperCrumData;
use crate::ent::trace::TracePosition;

#[derive(Debug)]
pub struct EditionMeta {
    edition_id: u64,
    bert_crum: Rc<RefCell<CanopyCrumData>>,
    sensor_crum: Rc<RefCell<CanopyCrumData>>,
    h_crum: Option<Rc<RefCell<HUpperCrumData>>>,
    prop: BertProp,
    trace_position: Option<TracePosition>,
    works: Vec<u64>,
}

impl EditionMeta {
    pub fn new(
        edition_id: u64,
        bert_crum: Rc<RefCell<CanopyCrumData>>,
        sensor_crum: Rc<RefCell<CanopyCrumData>>,
        prop: BertProp,
    ) -> Self {
        EditionMeta {
            edition_id,
            bert_crum,
            sensor_crum,
            h_crum: None,
            prop,
            trace_position: None,
            works: Vec::new(),
        }
    }

    pub fn edition_id(&self) -> u64 {
        self.edition_id
    }

    pub fn bert_crum(&self) -> &Rc<RefCell<CanopyCrumData>> {
        &self.bert_crum
    }

    pub fn sensor_crum(&self) -> &Rc<RefCell<CanopyCrumData>> {
        &self.sensor_crum
    }

    pub fn h_crum(&self) -> Option<&Rc<RefCell<HUpperCrumData>>> {
        self.h_crum.as_ref()
    }

    pub fn prop(&self) -> &BertProp {
        &self.prop
    }

    pub fn set_h_crum(&mut self, h_crum: Rc<RefCell<HUpperCrumData>>) {
        self.h_crum = Some(h_crum);
    }

    pub fn set_trace_position(&mut self, pos: TracePosition) {
        self.trace_position = Some(pos);
    }

    pub fn trace_position(&self) -> Option<&TracePosition> {
        self.trace_position.as_ref()
    }

    pub fn update_prop(&mut self, new_prop: BertProp) {
        self.prop = new_prop;
        let flags = self.prop.flags();
        self.bert_crum.borrow_mut().set_own_flags(flags);
        propagate_flags(&self.bert_crum);
    }

    pub fn add_work(&mut self, work_id: u64) {
        if !self.works.contains(&work_id) {
            self.works.push(work_id);
        }
    }

    pub fn remove_work(&mut self, work_id: u64) {
        self.works.retain(|id| *id != work_id);
    }

    pub fn works(&self) -> &[u64] {
        &self.works
    }

    pub fn any_passes(&self, finder: &PropFinder) -> bool {
        let flags = self.bert_crum.borrow().flags();
        if !finder.does_pass(flags) {
            return false;
        }
        if let Some(ref hc) = self.h_crum {
            return hc.borrow().any_passes(finder);
        }
        true
    }
}

#[derive(Debug)]
pub struct BackfollowEngine {
    grand_map: GrandMap,
    transclusion_index: TransclusionIndex,
    bert_canopy: BertCanopy,
    sensor_canopy: SensorCanopy,
    edition_metas: std::collections::HashMap<u64, EditionMeta>,
    edition_storage: std::collections::HashMap<u64, Edition>,
    work_storage: std::collections::HashMap<u64, Work>,
    next_edition_id: u64,
    next_work_id: u64,
}

impl BackfollowEngine {
    pub fn new() -> Self {
        BackfollowEngine {
            grand_map: GrandMap::new(),
            transclusion_index: TransclusionIndex::new(),
            bert_canopy: BertCanopy::new(),
            sensor_canopy: SensorCanopy::new(),
            edition_metas: std::collections::HashMap::new(),
            edition_storage: std::collections::HashMap::new(),
            work_storage: std::collections::HashMap::new(),
            next_edition_id: 1,
            next_work_id: 1,
        }
    }

    pub fn alloc_edition_id(&mut self) -> u64 {
        let id = self.next_edition_id;
        self.next_edition_id += 1;
        id
    }

    pub fn alloc_work_id(&mut self) -> u64 {
        let id = self.next_work_id;
        self.next_work_id += 1;
        id
    }

    pub fn register_edition(
        &mut self,
        edition: Edition,
        edition_id: u64,
        prop: BertProp,
    ) {
        let flags = prop.flags();
        let bert_crum = self.bert_canopy.make_crum(flags);
        let sensor_crum = self.sensor_canopy.make_crum(0);
        let meta = EditionMeta::new(edition_id, bert_crum, sensor_crum, prop);
        let edition_elem = RangeElement::edition(edition_id);
        self.transclusion_index.register_edition(&edition, &edition_elem, None);
        self.edition_storage.insert(edition_id, edition);
        self.edition_metas.insert(edition_id, meta);
    }

    pub fn register_edition_with_parent(
        &mut self,
        edition: Edition,
        edition_id: u64,
        parent_id: u64,
        prop: BertProp,
    ) {
        let flags = prop.flags();
        let bert_crum = self.bert_canopy.make_crum(flags);
        let sensor_crum = self.sensor_canopy.make_crum(0);
        let meta = EditionMeta::new(edition_id, bert_crum, sensor_crum, prop);
        if let Some(parent_meta) = self.edition_metas.get(&parent_id) {
            if let Some(ref parent_hc) = parent_meta.h_crum {
                let parent_bert = parent_hc.borrow().bert_crum().clone();
                let _joined = compute_join(&meta.bert_crum, &parent_bert);
            }
        }
        let edition_elem = RangeElement::edition(edition_id);
        self.transclusion_index.register_edition(&edition, &edition_elem, None);
        self.edition_storage.insert(edition_id, edition);
        self.edition_metas.insert(edition_id, meta);
    }

    pub fn register_work(&mut self, work: Work, work_id: u64, edition_id: Option<u64>) {
        let edition = work.current_edition().clone();
        let work_elem = RangeElement::work(work_id);
        self.transclusion_index.register_work(&edition, &work_elem);
        if let Some(eid) = edition_id {
            if let Some(meta) = self.edition_metas.get_mut(&eid) {
                meta.add_work(work_id);
            }
        }
        self.work_storage.insert(work_id, work);
    }

    pub fn unregister_edition(&mut self, edition_id: u64) {
        if let Some(meta) = self.edition_metas.remove(&edition_id) {
            self.edition_storage.remove(&edition_id);
            let _ = meta;
        }
    }

    pub fn update_edition(&mut self, edition_id: u64, new_edition: Edition) {
        if self.edition_storage.contains_key(&edition_id) {
            self.edition_storage.insert(edition_id, new_edition);
            self.rebuild_index();
        }
    }

    fn rebuild_index(&mut self) {
        self.transclusion_index.clear();
        for (id, stored) in &self.edition_storage {
            let elem = RangeElement::edition(*id);
            self.transclusion_index.register_edition(stored, &elem, None);
        }
        for (wid, work) in &self.work_storage {
            let elem = RangeElement::work(*wid);
            self.transclusion_index.register_work(work.current_edition(), &elem);
        }
    }

    pub fn update_edition_prop(&mut self, edition_id: u64, new_prop: BertProp) {
        if let Some(meta) = self.edition_metas.get_mut(&edition_id) {
            meta.update_prop(new_prop);
        }
    }

    pub fn find_transcluders(
        &self,
        content: &RangeElement,
        query: &TransclusionQuery,
    ) -> Vec<TransclusionResult> {
        let index_results = self.transclusion_index.find_transcluders(content, query);
        if query.permissions_filter().is_full() && query.endorsements_filter().is_full() {
            return index_results;
        }
        let finder = query.to_prop_finder();
        let mut filtered = Vec::new();
        for result in index_results {
            if let Some(edition_id) = result.element.as_edition_id() {
                if let Some(meta) = self.edition_metas.get(&edition_id) {
                    if meta.any_passes(&finder) {
                        filtered.push(result);
                    }
                }
            } else {
                filtered.push(result);
            }
        }
        filtered
    }

    pub fn find_transcluders_with_backfollow(
        &self,
        content: &RangeElement,
        query: &TransclusionQuery,
    ) -> Vec<TransclusionResult> {
        let index_results = self.transclusion_index.find_transcluders(content, query);
        let finder = query.to_prop_finder();
        let mut trail = TrailBlazer::new();
        let mut hcrum_cache = HashSet::new();
        for result in &index_results {
            if let Some(edition_id) = result.element.as_edition_id() {
                if let Some(meta) = self.edition_metas.get(&edition_id) {
                    if meta.any_passes(&finder) {
                        trail.record_element(&result.element);
                    }
                    if let Some(ref hc) = meta.h_crum() {
                        HUpperCrumData::delayed_store_backfollow(
                            hc,
                            &finder,
                            &mut hcrum_cache,
                            &mut |visited_hc| {
                                let visited_flags = visited_hc.borrow().bert_crum().borrow().flags();
                                if finder.does_pass(visited_flags) {
                                    for (eid, em) in &self.edition_metas {
                                        if let Some(ref em_hc) = em.h_crum() {
                                            if Rc::ptr_eq(em_hc, visited_hc) {
                                                let elem = RangeElement::edition(*eid);
                                                trail.record_element(&elem);
                                            }
                                        }
                                    }
                                }
                            },
                        );
                    }
                }
            } else {
                trail.record_element(&result.element);
            }
        }
        let mut final_results = Vec::new();
        for result in &index_results {
            final_results.push(TransclusionResult {
                element: result.element.clone(),
                is_direct: result.is_direct,
            });
        }
        final_results
    }

    pub fn find_works_for_content(
        &self,
        content: &RangeElement,
        query: &WorkQuery,
    ) -> Vec<u64> {
        let work_elements = self.transclusion_index.find_works(content, query);
        let mut work_ids = Vec::new();
        for elem in work_elements {
            if let Some(wid) = elem.as_work_id() {
                work_ids.push(wid);
            }
        }
        work_ids
    }

    pub fn get_edition(&self, id: u64) -> Option<&Edition> {
        self.edition_storage.get(&id)
    }

    pub fn get_edition_meta(&self, id: u64) -> Option<&EditionMeta> {
        self.edition_metas.get(&id)
    }

    pub fn get_work(&self, id: u64) -> Option<&Work> {
        self.work_storage.get(&id)
    }

    pub fn transclusion_index(&self) -> &TransclusionIndex {
        &self.transclusion_index
    }

    pub fn bert_canopy(&self) -> &BertCanopy {
        &self.bert_canopy
    }

    pub fn sensor_canopy(&self) -> &SensorCanopy {
        &self.sensor_canopy
    }

    pub fn edition_count(&self) -> usize {
        self.edition_storage.len()
    }

    pub fn work_count(&self) -> usize {
        self.work_storage.len()
    }

    pub fn delayed_store_backfollow_for_edition(
        &self,
        edition_id: u64,
        finder: &PropFinder,
        hcrum_cache: &mut HashSet<u32>,
        trail: &mut TrailBlazer,
    ) {
        if let Some(meta) = self.edition_metas.get(&edition_id) {
            if !meta.any_passes(finder) {
                return;
            }
            let edition_elem = RangeElement::edition(edition_id);
            trail.record_element(&edition_elem);
            if let Some(ref hc) = meta.h_crum() {
                HUpperCrumData::delayed_store_backfollow(
                    hc,
                    finder,
                    hcrum_cache,
                    &mut |visited_hc| {
                        let flags = visited_hc.borrow().bert_crum().borrow().flags();
                        if finder.does_pass(flags) {
                            for (eid, em) in &self.edition_metas {
                                if let Some(ref em_hc) = em.h_crum() {
                                    if Rc::ptr_eq(em_hc, visited_hc) {
                                        let e = RangeElement::edition(*eid);
                                        trail.record_element(&e);
                                    }
                                }
                            }
                        }
                    },
                );
            }
        }
    }

    pub fn delayed_find_matching(
        &self,
        edition_id: u64,
        finder: &PropFinder,
    ) -> Vec<u64> {
        let mut trail = TrailBlazer::new();
        let mut hcrum_cache = HashSet::new();
        self.delayed_store_backfollow_for_edition(
            edition_id,
            finder,
            &mut hcrum_cache,
            &mut trail,
        );
        let trail_edition = trail.into_trail();
        let mut result = Vec::new();
        for (_pos, carrier) in trail_edition.all_entries() {
            if let Some(eid) = carrier.element.as_edition_id() {
                result.push(eid);
            }
        }
        result
    }
}

impl Default for BackfollowEngine {
    fn default() -> Self {
        Self::new()
    }
}

impl TransclusionQuery {
    pub fn to_prop_finder(&self) -> PropFinder {
        if self.permissions_filter().is_full() && self.endorsements_filter().is_full() {
            return PropFinder::open();
        }
        if self.permissions_filter().is_empty() && self.endorsements_filter().is_empty() {
            return PropFinder::closed();
        }
        let perm_region = self.permissions_filter().region().clone();
        let endo_region = self.endorsements_filter().region().clone();
        PropFinder::backfollow_full(perm_region, endo_region)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::grandmap::Id;
    use crate::edition::props::PUBLIC_CLUB_FLAG;

    #[test]
    fn backfollow_engine_new() {
        let engine = BackfollowEngine::new();
        assert_eq!(engine.edition_count(), 0);
        assert_eq!(engine.work_count(), 0);
    }

    #[test]
    fn backfollow_engine_register_edition() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_text("hello");
        let id = engine.alloc_edition_id();
        engine.register_edition(edition.clone(), id, BertProp::make());
        assert_eq!(engine.edition_count(), 1);
        assert!(engine.get_edition(id).is_some());
        assert!(engine.get_edition_meta(id).is_some());
    }

    #[test]
    fn backfollow_engine_find_transcluders_simple() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("hello"));
        let id = engine.alloc_edition_id();
        engine.register_edition(edition, id, BertProp::make());

        let query = TransclusionQuery::all();
        let results = engine.find_transcluders(&RangeElement::text("hello"), &query);
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].element, RangeElement::edition(id));
        assert!(results[0].is_direct);
    }

    #[test]
    fn backfollow_engine_find_transcluders_no_match() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("hello"));
        let id = engine.alloc_edition_id();
        engine.register_edition(edition, id, BertProp::make());

        let query = TransclusionQuery::all();
        let results = engine.find_transcluders(&RangeElement::text("goodbye"), &query);
        assert!(results.is_empty());
    }

    #[test]
    fn backfollow_engine_multiple_editions() {
        let mut engine = BackfollowEngine::new();
        let e1 = Edition::from_one(0, RangeElement::text("shared"));
        let e2 = Edition::from_one(0, RangeElement::text("shared"));
        let id1 = engine.alloc_edition_id();
        let id2 = engine.alloc_edition_id();
        engine.register_edition(e1, id1, BertProp::make());
        engine.register_edition(e2, id2, BertProp::make());

        let query = TransclusionQuery::all();
        let results = engine.find_transcluders(&RangeElement::text("shared"), &query);
        assert_eq!(results.len(), 2);
    }

    #[test]
    fn backfollow_engine_find_works() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("hello"));
        let eid = engine.alloc_edition_id();
        engine.register_edition(edition.clone(), eid, BertProp::make());

        let wid = engine.alloc_work_id();
        let work = Work::new_with_owner(wid, Some(1), edition);
        engine.register_work(work, wid, Some(eid));

        let query = WorkQuery::all();
        let works = engine.find_works_for_content(&RangeElement::text("hello"), &query);
        assert_eq!(works.len(), 1);
        assert_eq!(works[0], wid);
    }

    #[test]
    fn backfollow_engine_unregister_edition() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("hello"));
        let id = engine.alloc_edition_id();
        engine.register_edition(edition, id, BertProp::make());
        assert_eq!(engine.edition_count(), 1);

        engine.unregister_edition(id);
        assert_eq!(engine.edition_count(), 0);
    }

    #[test]
    fn backfollow_engine_update_edition() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("hello"));
        let id = engine.alloc_edition_id();
        engine.register_edition(edition, id, BertProp::make());

        let query = TransclusionQuery::all();
        let before = engine.find_transcluders(&RangeElement::text("hello"), &query);
        assert_eq!(before.len(), 1);

        let updated = Edition::from_one(0, RangeElement::text("world"));
        engine.update_edition(id, updated);

        let old_results = engine.find_transcluders(&RangeElement::text("hello"), &query);
        assert!(old_results.is_empty());

        let new_results = engine.find_transcluders(&RangeElement::text("world"), &query);
        assert_eq!(new_results.len(), 1);
    }

    #[test]
    fn backfollow_engine_update_edition_prop() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("secret"));
        let id = engine.alloc_edition_id();
        engine.register_edition(edition, id, BertProp::make());

        let meta = engine.get_edition_meta(id).unwrap();
        assert_eq!(meta.bert_crum().borrow().flags(), 0);

        let new_prop = BertProp::permissions_prop(vec![Id::global(0)]);
        engine.update_edition_prop(id, new_prop);

        let meta = engine.get_edition_meta(id).unwrap();
        assert_eq!(meta.bert_crum().borrow().own_flags(), PUBLIC_CLUB_FLAG);
    }

    #[test]
    fn backfollow_engine_edition_meta_any_passes() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("x"));
        let id = engine.alloc_edition_id();
        engine.register_edition(edition, id, BertProp::make());

        let open = PropFinder::open();
        let meta = engine.get_edition_meta(id).unwrap();
        assert!(meta.any_passes(&open));

        let prop = BertProp::permissions_prop(vec![Id::global(0)]);
        engine.update_edition_prop(id, prop);
        let meta = engine.get_edition_meta(id).unwrap();
        assert!(meta.any_passes(&open));
    }

    #[test]
    fn backfollow_engine_alloc_ids() {
        let mut engine = BackfollowEngine::new();
        let e1 = engine.alloc_edition_id();
        let e2 = engine.alloc_edition_id();
        assert!(e2 > e1);

        let w1 = engine.alloc_work_id();
        let w2 = engine.alloc_work_id();
        assert!(w2 > w1);
    }

    #[test]
    fn edition_meta_update_prop_propagates() {
        let canopy = BertCanopy::new();
        let sensor = SensorCanopy::new();
        let bert = canopy.make_crum(0);
        let sensor_crum = sensor.make_crum(0);
        let mut meta = EditionMeta::new(1, bert.clone(), sensor_crum, BertProp::make());

        assert_eq!(bert.borrow().flags(), 0);
        meta.update_prop(BertProp::permissions_prop(vec![Id::global(0)]));
        assert_eq!(bert.borrow().own_flags(), PUBLIC_CLUB_FLAG);
    }

    #[test]
    fn edition_meta_works() {
        let canopy = BertCanopy::new();
        let sensor = SensorCanopy::new();
        let bert = canopy.make_crum(0);
        let sensor_crum = sensor.make_crum(0);
        let mut meta = EditionMeta::new(1, bert, sensor_crum, BertProp::make());

        assert!(meta.works().is_empty());
        meta.add_work(10);
        meta.add_work(20);
        meta.add_work(10);
        assert_eq!(meta.works().len(), 2);
        meta.remove_work(10);
        assert_eq!(meta.works().len(), 1);
        assert_eq!(meta.works()[0], 20);
    }

    #[test]
    fn transclusion_query_to_prop_finder() {
        let q = TransclusionQuery::all();
        let finder = q.to_prop_finder();
        assert!(finder.is_full());

        let q2 = TransclusionQuery::direct_only();
        let finder2 = q2.to_prop_finder();
        assert!(finder2.is_full());
    }

    #[test]
    fn backfollow_engine_find_transcluders_with_backfollow() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("hello"));
        let id = engine.alloc_edition_id();
        engine.register_edition(edition, id, BertProp::make());

        let query = TransclusionQuery::all();
        let results = engine.find_transcluders_with_backfollow(
            &RangeElement::text("hello"),
            &query,
        );
        assert_eq!(results.len(), 1);
    }

    #[test]
    fn backfollow_engine_delayed_find_matching() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("data"));
        let id = engine.alloc_edition_id();
        engine.register_edition(edition, id, BertProp::make());

        let finder = PropFinder::open();
        let found = engine.delayed_find_matching(id, &finder);
        assert_eq!(found.len(), 1);
        assert_eq!(found[0], id);
    }

    #[test]
    fn backfollow_engine_delayed_find_matching_no_hcrum() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("data"));
        let id = engine.alloc_edition_id();
        engine.register_edition(edition, id, BertProp::make());

        let closed = PropFinder::closed();
        let found = engine.delayed_find_matching(id, &closed);
        assert!(found.is_empty());
    }

    #[test]
    fn backfollow_engine_register_edition_with_parent() {
        let mut engine = BackfollowEngine::new();
        let parent_edition = Edition::from_text("parent content");
        let parent_id = engine.alloc_edition_id();
        engine.register_edition(parent_edition, parent_id, BertProp::make());

        let child_edition = Edition::from_one(0, RangeElement::text("child"));
        let child_id = engine.alloc_edition_id();
        engine.register_edition_with_parent(child_edition, child_id, parent_id, BertProp::make());

        assert_eq!(engine.edition_count(), 2);
        assert!(engine.get_edition(child_id).is_some());
    }

    #[test]
    fn gold_backfollow_two_editions_shared_content() {
        let mut engine = BackfollowEngine::new();
        let e1 = Edition::from_text("abc");
        let e2 = Edition::from_one(0, RangeElement::text("a"));
        let id1 = engine.alloc_edition_id();
        let id2 = engine.alloc_edition_id();
        engine.register_edition(e1, id1, BertProp::make());
        engine.register_edition(e2, id2, BertProp::make());

        let query = TransclusionQuery::all();
        let results = engine.find_transcluders(&RangeElement::text("a"), &query);
        assert!(results.len() >= 2);

        let found_ids: Vec<u64> = results.iter()
            .filter_map(|r| r.element.as_edition_id())
            .collect();
        assert!(found_ids.contains(&id1));
        assert!(found_ids.contains(&id2));
    }

    #[test]
    fn gold_backfollow_work_on_edition() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("document"));
        let eid = engine.alloc_edition_id();
        engine.register_edition(edition.clone(), eid, BertProp::make());

        let wid = engine.alloc_work_id();
        let work = Work::new_with_owner(wid, Some(42), edition);
        engine.register_work(work, wid, Some(eid));

        let query = WorkQuery::all();
        let works = engine.find_works_for_content(
            &RangeElement::text("document"),
            &query,
        );
        assert_eq!(works.len(), 1);
        assert_eq!(works[0], wid);

        let stored_work = engine.get_work(wid).unwrap();
        assert_eq!(stored_work.be_id(), wid);
    }

    #[test]
    fn gold_backfollow_unregister_removes_from_index() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("temp"));
        let id = engine.alloc_edition_id();
        engine.register_edition(edition, id, BertProp::make());

        let query = TransclusionQuery::all();
        assert_eq!(engine.find_transcluders(&RangeElement::text("temp"), &query).len(), 1);

        engine.unregister_edition(id);
        assert_eq!(engine.edition_count(), 0);
    }

    #[test]
    fn gold_backfollow_prop_filtering() {
        let mut engine = BackfollowEngine::new();
        let e1 = Edition::from_one(0, RangeElement::text("public"));
        let e2 = Edition::from_one(0, RangeElement::text("public"));
        let id1 = engine.alloc_edition_id();
        let id2 = engine.alloc_edition_id();
        engine.register_edition(e1, id1, BertProp::permissions_prop(vec![Id::global(0)]));
        engine.register_edition(e2, id2, BertProp::make());

        let query = TransclusionQuery::all();
        let results = engine.find_transcluders(&RangeElement::text("public"), &query);
        assert_eq!(results.len(), 2);
    }

    #[test]
    fn stress_backfollow_many_editions() {
        let mut engine = BackfollowEngine::new();
        let num_editions = 500;
        let mut ids = Vec::new();
        for _i in 0..num_editions {
            let edition = Edition::from_one(0, RangeElement::text("common"));
            let id = engine.alloc_edition_id();
            engine.register_edition(edition, id, BertProp::make());
            ids.push(id);
        }

        let query = TransclusionQuery::all();
        let results = engine.find_transcluders(&RangeElement::text("common"), &query);
        assert_eq!(results.len(), num_editions as usize);
    }
}
