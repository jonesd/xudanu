use std::sync::Mutex;
use std::collections::HashSet;
use std::sync::Arc;

use super::canopy::{BertCanopy, CanopyCrumData, SensorCanopy, compute_join, propagate_flags};
use super::edition::Edition;
use super::grandmap::GrandMap;
use super::links::{HyperLink, HyperRef};
use super::props::{BertProp, PropFinder};
use super::range_element::RangeElement;
use super::transclusion::{TrailBlazer, TransclusionIndex, TransclusionQuery, TransclusionResult, WorkQuery};
use super::work::Work;
use super::wrapper::{WRAPPER_CLUB_ID, TEXT_TOKEN};
use crate::ent::htree::{HUpperCrumData, HPart};
use crate::ent::trace::TracePosition;
use crate::ent::dagwood::DagWood;

#[derive(Debug, Clone)]
pub struct EditionMeta {
    edition_id: u64,
    bert_crum: Arc<Mutex<CanopyCrumData>>,
    sensor_crum: Arc<Mutex<CanopyCrumData>>,
    h_crum: Option<Arc<Mutex<HUpperCrumData>>>,
    prop: BertProp,
    trace_position: Option<TracePosition>,
    works: Vec<u64>,
}

impl EditionMeta {
    pub fn new(
        edition_id: u64,
        bert_crum: Arc<Mutex<CanopyCrumData>>,
        sensor_crum: Arc<Mutex<CanopyCrumData>>,
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

    pub fn bert_crum(&self) -> &Arc<Mutex<CanopyCrumData>> {
        &self.bert_crum
    }

    pub fn sensor_crum(&self) -> &Arc<Mutex<CanopyCrumData>> {
        &self.sensor_crum
    }

    pub fn h_crum(&self) -> Option<&Arc<Mutex<HUpperCrumData>>> {
        self.h_crum.as_ref()
    }

    pub fn prop(&self) -> &BertProp {
        &self.prop
    }

    pub fn set_h_crum(&mut self, h_crum: Arc<Mutex<HUpperCrumData>>) {
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
        self.bert_crum.lock().unwrap().set_own_flags(flags);
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
        let flags = self.bert_crum.lock().unwrap().flags();
        if !finder.does_pass(flags) {
            return false;
        }
        if let Some(ref hc) = self.h_crum {
            return hc.lock().unwrap().any_passes(finder);
        }
        true
    }
}

impl HPart for EditionMeta {
    fn h_crum(&self) -> Option<Arc<Mutex<HUpperCrumData>>> {
        self.h_crum.clone()
    }
}

#[derive(Debug)]
pub struct BackfollowEngine {
    _grand_map: GrandMap,
    transclusion_index: TransclusionIndex,
    bert_canopy: BertCanopy,
    sensor_canopy: SensorCanopy,
    edition_metas: std::collections::HashMap<u64, EditionMeta>,
    edition_storage: std::collections::HashMap<u64, Edition>,
    work_storage: std::collections::HashMap<u64, Work>,
    link_storage: std::collections::HashMap<u64, HyperLink>,
    fingerprint_to_works: std::collections::HashMap<[u8; 32], std::collections::HashSet<u64>>,
    dagwood: DagWood,
    parent_of: std::collections::HashMap<u64, Vec<u64>>,
    next_edition_id: u64,
    next_work_id: u64,
    next_link_id: u64,
}

impl BackfollowEngine {
    pub fn new() -> Self {
        BackfollowEngine {
            _grand_map: GrandMap::new(),
            transclusion_index: TransclusionIndex::new(),
            bert_canopy: BertCanopy::new(),
            sensor_canopy: SensorCanopy::new(),
            edition_metas: std::collections::HashMap::new(),
            edition_storage: std::collections::HashMap::new(),
            work_storage: std::collections::HashMap::new(),
            link_storage: std::collections::HashMap::new(),
            fingerprint_to_works: std::collections::HashMap::new(),
            dagwood: DagWood::new(),
            parent_of: std::collections::HashMap::new(),
            next_edition_id: 1,
            next_work_id: 1,
            next_link_id: 1,
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
                let parent_bert = parent_hc.lock().unwrap().bert_crum().clone();
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
        for (_, carrier) in edition.all_entries() {
            let fp = carrier.element.content_fingerprint();
            self.fingerprint_to_works.entry(fp).or_default().insert(work_id);
        }
        if let Some(eid) = edition_id {
            if let Some(meta) = self.edition_metas.get_mut(&eid) {
                meta.add_work(work_id);
            }
        }
        self.work_storage.insert(work_id, work);
    }

    pub fn register_work_with_prop(&mut self, work: Work, work_id: u64, edition_id: Option<u64>, prop: BertProp) {
        let edition = work.current_edition().clone();
        let work_elem = RangeElement::work(work_id);
        self.transclusion_index.register_work(&edition, &work_elem);
        for (_, carrier) in edition.all_entries() {
            let fp = carrier.element.content_fingerprint();
            self.fingerprint_to_works.entry(fp).or_default().insert(work_id);
        }
        if let Some(eid) = edition_id {
            if let Some(meta) = self.edition_metas.get_mut(&eid) {
                meta.add_work(work_id);
            }
        }
        let tp = self.dagwood.new_position();
        let flags = prop.flags();
        let bert_crum = self.bert_canopy.make_crum(flags);
        let sensor_crum = self.sensor_canopy.make_crum(0);
        let h_crum = HUpperCrumData::new(tp, bert_crum.clone(), self.bert_canopy.clone());
        let mut meta = EditionMeta::new(work_id, bert_crum, sensor_crum, prop);
        meta.set_h_crum(Arc::new(Mutex::new(h_crum)));
        meta.set_trace_position(tp);
        self.parent_of.insert(work_id, Vec::new());
        self.edition_metas.insert(work_id, meta);
        self.work_storage.insert(work_id, work);
    }

    pub fn update_work_with_parent(&mut self, work_id: u64, parent_work_id: u64, new_work: Work) {
        let old_edition = self.work_storage.get(&work_id)
            .map(|w| w.current_edition().clone());
        if let Some(old_ed) = old_edition {
            let old_elem = RangeElement::work(work_id);
            self.transclusion_index.unregister_work(&old_ed, &old_elem);
            for (_, carrier) in old_ed.all_entries() {
                let fp = carrier.element.content_fingerprint();
                if let Some(set) = self.fingerprint_to_works.get_mut(&fp) {
                    set.remove(&work_id);
                    if set.is_empty() {
                        self.fingerprint_to_works.remove(&fp);
                    }
                }
            }
        }
        let new_edition = new_work.current_edition().clone();
        let work_elem = RangeElement::work(work_id);
        self.transclusion_index.register_work(&new_edition, &work_elem);
        for (_, carrier) in new_edition.all_entries() {
            let fp = carrier.element.content_fingerprint();
            self.fingerprint_to_works.entry(fp).or_default().insert(work_id);
        }

        let parent_tp = self.edition_metas.get(&parent_work_id)
            .and_then(|m| m.trace_position().copied());
        let tp = if let Some(parent_pos) = parent_tp {
            self.dagwood.new_position_after(parent_pos)
        } else {
            self.dagwood.new_position()
        };
        let old_prop = self.edition_metas.get(&work_id)
            .map(|m| m.prop().clone())
            .unwrap_or_else(BertProp::make);
        let flags = old_prop.flags();
        let bert_crum = self.bert_canopy.make_crum(flags);
        let sensor_crum = self.sensor_canopy.make_crum(0);

        let parent_arc: Option<Arc<Mutex<EditionMeta>>> = self.edition_metas.get(&parent_work_id)
            .map(|m| Arc::new(Mutex::new(m.clone())));

        let h_crum = if let Some(parent_meta) = parent_arc {
            let h = HUpperCrumData::from_two(
                parent_meta.clone() as Arc<Mutex<dyn HPart>>,
                Arc::new(Mutex::new(EditionMeta::new(work_id, bert_crum.clone(), sensor_crum.clone(), old_prop.clone()))) as Arc<Mutex<dyn HPart>>,
                tp,
                self.bert_canopy.clone(),
            );
            Arc::new(Mutex::new(h))
        } else {
            let h = HUpperCrumData::new(tp, bert_crum.clone(), self.bert_canopy.clone());
            Arc::new(Mutex::new(h))
        };

        let mut meta = EditionMeta::new(work_id, bert_crum, sensor_crum, old_prop);
        meta.set_h_crum(h_crum);
        meta.set_trace_position(tp);
        self.parent_of.insert(work_id, vec![parent_work_id]);
        self.edition_metas.insert(work_id, meta);
        self.work_storage.insert(work_id, new_work);
    }

    pub fn update_work(&mut self, work_id: u64, new_work: Work) {
        let old_edition = self.work_storage.get(&work_id)
            .map(|w| w.current_edition().clone());
        if let Some(old_ed) = old_edition {
            let old_elem = RangeElement::work(work_id);
            self.transclusion_index.unregister_work(&old_ed, &old_elem);
            for (_, carrier) in old_ed.all_entries() {
                let fp = carrier.element.content_fingerprint();
                if let Some(set) = self.fingerprint_to_works.get_mut(&fp) {
                    set.remove(&work_id);
                    if set.is_empty() {
                        self.fingerprint_to_works.remove(&fp);
                    }
                }
            }
        }
        let new_edition = new_work.current_edition().clone();
        let work_elem = RangeElement::work(work_id);
        self.transclusion_index.register_work(&new_edition, &work_elem);
        for (_, carrier) in new_edition.all_entries() {
            let fp = carrier.element.content_fingerprint();
            self.fingerprint_to_works.entry(fp).or_default().insert(work_id);
        }
        self.work_storage.insert(work_id, new_work);
    }

    pub fn compute_work_endorsements(work: &Work) -> Vec<super::grandmap::Id> {
        use super::grandmap::Id;
        let mut has_text = false;
        for (_, carrier) in work.current_edition().all_entries() {
            match &carrier.element {
                RangeElement::Text { .. } | RangeElement::Data { .. } => has_text = true,
                _ => {}
            }
        }
        let mut endorsements = Vec::new();
        if has_text {
            endorsements.push(Id::in_space(super::grandmap::IdSpaceId(WRAPPER_CLUB_ID), TEXT_TOKEN as i64));
        }
        endorsements
    }

    pub fn make_work_prop(work: &Work, read_club: Option<u64>, edit_club: Option<u64>) -> BertProp {
        let mut permissions = Vec::new();
        if let Some(rc) = read_club {
            permissions.push(super::grandmap::Id::global(rc as i64));
        }
        if let Some(ec) = edit_club {
            permissions.push(super::grandmap::Id::global(ec as i64));
        }
        let endorsements = Self::compute_work_endorsements(work);
        BertProp::new(permissions, endorsements, false, false)
    }

    pub fn unregister_edition(&mut self, edition_id: u64) {
        if let Some(meta) = self.edition_metas.remove(&edition_id) {
            if let Some(edition) = self.edition_storage.remove(&edition_id) {
                let elem = RangeElement::edition(edition_id);
                self.transclusion_index.unregister_edition(&edition, &elem, None);
            }
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
        self.fingerprint_to_works.clear();
        for (id, stored) in &self.edition_storage {
            let elem = RangeElement::edition(*id);
            self.transclusion_index.register_edition(stored, &elem, None);
        }
        for (wid, work) in &self.work_storage {
            let elem = RangeElement::work(*wid);
            self.transclusion_index.register_work(work.current_edition(), &elem);
            for (_, carrier) in work.current_edition().all_entries() {
                let fp = carrier.element.content_fingerprint();
                self.fingerprint_to_works.entry(fp).or_default().insert(*wid);
            }
        }
    }

    pub fn update_edition_prop(&mut self, edition_id: u64, new_prop: BertProp) {
        if let Some(meta) = self.edition_metas.get_mut(&edition_id) {
            meta.update_prop(new_prop);
        }
    }

    pub fn on_work_created(&mut self, work_id: u64, work: &Work) {
        let edition = work.current_edition().clone();
        for (_, carrier) in edition.all_entries() {
            let fp = carrier.element.content_fingerprint();
            self.fingerprint_to_works.entry(fp).or_default().insert(work_id);
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
                                let visited_flags = visited_hc.lock().unwrap().bert_crum().lock().unwrap().flags();
                                if finder.does_pass(visited_flags) {
                                    for (eid, em) in &self.edition_metas {
                                        if let Some(ref em_hc) = em.h_crum() {
                                            if Arc::ptr_eq(em_hc, visited_hc) {
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
        let trail_edition = trail.into_trail();
        let mut final_results = Vec::new();
        for (_, carrier) in trail_edition.all_entries() {
            let is_direct = index_results.iter().any(|r| r.element == carrier.element);
            final_results.push(TransclusionResult {
                element: carrier.element.clone(),
                is_direct,
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

    pub fn version_is_le(&mut self, a: u64, b: u64) -> Option<bool> {
        let tp_a = self.edition_metas.get(&a).and_then(|m| m.trace_position().copied());
        let tp_b = self.edition_metas.get(&b).and_then(|m| m.trace_position().copied());
        match (tp_a, tp_b) {
            (Some(a_pos), Some(b_pos)) => Some(self.dagwood.is_le(a_pos, b_pos)),
            _ => None,
        }
    }

    pub fn version_ancestors(&self, work_id: u64) -> Vec<u64> {
        self.parent_of.get(&work_id).cloned().unwrap_or_default()
    }

    pub fn trace_position_of(&self, work_id: u64) -> Option<TracePosition> {
        self.edition_metas.get(&work_id).and_then(|m| m.trace_position().copied())
    }

    pub fn get_work(&self, id: u64) -> Option<&Work> {
        self.work_storage.get(&id)
    }

    pub fn transclusion_index(&self) -> &TransclusionIndex {
        &self.transclusion_index
    }

    pub fn transclusion_index_mut(&mut self) -> &mut TransclusionIndex {
        &mut self.transclusion_index
    }

    pub fn fingerprint_to_works(&self) -> &std::collections::HashMap<[u8; 32], std::collections::HashSet<u64>> {
        &self.fingerprint_to_works
    }

    pub fn find_works_by_fingerprint(&self, fp: &[u8; 32]) -> Vec<u64> {
        self.fingerprint_to_works.get(fp)
            .map(|set| set.iter().copied().collect())
            .unwrap_or_default()
    }

    pub fn register_fingerprint_for_work(&mut self, fp: [u8; 32], work_id: u64) {
        self.fingerprint_to_works.entry(fp).or_default().insert(work_id);
    }

    pub fn register_federated_entry(
        &mut self,
        content: &RangeElement,
        origin_server_id: String,
        local_id: u64,
        element_type: String,
        is_direct: bool,
    ) {
        self.transclusion_index.register_federated(content, origin_server_id, local_id, element_type, is_direct);
    }

    pub fn has_federated_entries(&self) -> bool {
        self.transclusion_index.has_federated_entries()
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

    pub fn alloc_link_id(&mut self) -> u64 {
        let id = self.next_link_id;
        self.next_link_id += 1;
        id
    }

    pub fn register_link(&mut self, link: HyperLink, link_id: u64) {
        let content = link.all_referenced_content();
        for element in content {
            let link_elem = RangeElement::label(link_id, RangeElement::text("link"));
            self.transclusion_index.register_edition(
                &Edition::from_one(0, element.clone()),
                &link_elem,
                None,
            );
        }
        self.link_storage.insert(link_id, link);
    }

    pub fn unregister_link(&mut self, link_id: u64) {
        self.link_storage.remove(&link_id);
    }

    pub fn get_link(&self, link_id: u64) -> Option<&HyperLink> {
        self.link_storage.get(&link_id)
    }

    pub fn update_link(&mut self, link_id: u64, new_link: HyperLink) {
        if self.link_storage.contains_key(&link_id) {
            self.link_storage.insert(link_id, new_link);
        }
    }

    pub fn rebuild_link_index(&mut self) {
        for (link_id, link) in &self.link_storage {
            let content = link.all_referenced_content();
            for element in content {
                let link_elem = RangeElement::label(*link_id, RangeElement::text("link"));
                self.transclusion_index.register_edition(
                    &Edition::from_one(0, element.clone()),
                    &link_elem,
                    None,
                );
            }
        }
    }

    pub fn link_count(&self) -> usize {
        self.link_storage.len()
    }

    pub fn find_links_to_content(&self, content: &RangeElement) -> Vec<u64> {
        let mut result = Vec::new();
        for (link_id, link) in &self.link_storage {
            let referenced = link.all_referenced_content();
            if referenced.iter().any(|e| e == content) {
                result.push(*link_id);
            }
        }
        result
    }

    pub fn find_links_referencing_edition(&self, edition_id: u64) -> Vec<u64> {
        let mut result = Vec::new();
        for (link_id, link) in &self.link_storage {
            for end in link.ends().values() {
                if let Some(excerpt) = end.excerpt() {
                    for (_, carrier) in excerpt.all_entries() {
                        if let Some(eid) = carrier.element.as_edition_id() {
                            if eid == edition_id {
                                if !result.contains(link_id) {
                                    result.push(*link_id);
                                }
                            }
                        }
                    }
                }
            }
        }
        result
    }

    pub fn find_links_from_work(&self, work_id: u64) -> Vec<u64> {
        let mut result = Vec::new();
        for (link_id, link) in &self.link_storage {
            for end in link.ends().values() {
                if end.work_context() == Some(work_id) {
                    if !result.contains(link_id) {
                        result.push(*link_id);
                    }
                }
            }
        }
        result
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
                        let flags = visited_hc.lock().unwrap().bert_crum().lock().unwrap().flags();
                        if finder.does_pass(flags) {
                            for (eid, em) in &self.edition_metas {
                                if let Some(ref em_hc) = em.h_crum() {
                                    if Arc::ptr_eq(em_hc, visited_hc) {
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

pub fn edition_to_assertions(
    edition_id: u64,
    edition: &Edition,
    tp: TracePosition,
) -> Vec<crate::ent::content::Assertion> {
    use crate::ent::content::{Assertion, AssertionId, AssertionPayload, NodeId, SpanId};
    let mut assertions = Vec::new();
    let mut next_id = 1u64;
    let doc_node = NodeId::new(edition_id);
    assertions.push(Assertion {
        id: AssertionId(next_id),
        position: tp,
        payload: AssertionPayload::CreateNode {
            node_id: doc_node,
            kind: "Edition".to_string(),
        },
    });
    next_id += 1;
    for (pos, carrier) in edition.all_entries() {
        let span_id = SpanId::new({
            use std::hash::{Hash, Hasher};
            let mut h = std::collections::hash_map::DefaultHasher::new();
            edition_id.hash(&mut h);
            pos.hash(&mut h);
            h.finish()
        });
        let ordinal = (pos.max(0) as u64).min(u32::MAX as u64) as u32;
        if let Some(text) = carrier.element.as_text() {
            assertions.push(Assertion {
                id: AssertionId(next_id),
                position: tp,
                payload: AssertionPayload::CreateSpan { span_id },
            });
            next_id += 1;
            assertions.push(Assertion {
                id: AssertionId(next_id),
                position: tp,
                payload: AssertionPayload::SetSpanText {
                    span_id,
                    text: text.to_string(),
                },
            });
            next_id += 1;
            assertions.push(Assertion {
                id: AssertionId(next_id),
                position: tp,
                payload: AssertionPayload::AttachSpanToNode {
                    node_id: doc_node,
                    span_id,
                    ordinal,
                },
            });
            next_id += 1;
        }
    }
    assertions
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
        assert_eq!(meta.bert_crum().lock().unwrap().flags(), 0);

        let new_prop = BertProp::permissions_prop(vec![Id::global(0)]);
        engine.update_edition_prop(id, new_prop);

        let meta = engine.get_edition_meta(id).unwrap();
        assert_eq!(meta.bert_crum().lock().unwrap().own_flags(), PUBLIC_CLUB_FLAG);
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

        assert_eq!(bert.lock().unwrap().flags(), 0);
        meta.update_prop(BertProp::permissions_prop(vec![Id::global(0)]));
        assert_eq!(bert.lock().unwrap().own_flags(), PUBLIC_CLUB_FLAG);
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

    #[test]
    fn backfollow_engine_register_link() {
        let mut engine = BackfollowEngine::new();
        let left = HyperRef::single(Some(Edition::from_one(0, RangeElement::text("source"))), None, None, None);
        let right = HyperRef::single(Some(Edition::from_one(0, RangeElement::text("target"))), None, None, None);
        let link = HyperLink::make(vec![], left, right);
        let lid = engine.alloc_link_id();
        engine.register_link(link, lid);
        assert_eq!(engine.link_count(), 1);
    }

    #[test]
    fn backfollow_engine_find_links_to_content() {
        let mut engine = BackfollowEngine::new();
        let left = HyperRef::single(Some(Edition::from_one(0, RangeElement::text("source"))), None, None, None);
        let right = HyperRef::single(Some(Edition::from_one(0, RangeElement::text("target"))), None, None, None);
        let link = HyperLink::make(vec![], left, right);
        let lid = engine.alloc_link_id();
        engine.register_link(link, lid);

        let found = engine.find_links_to_content(&RangeElement::text("source"));
        assert_eq!(found.len(), 1);
        assert_eq!(found[0], lid);

        let not_found = engine.find_links_to_content(&RangeElement::text("absent"));
        assert!(not_found.is_empty());
    }

    #[test]
    fn backfollow_engine_find_links_referencing_edition() {
        let mut engine = BackfollowEngine::new();
        let eid = engine.alloc_edition_id();
        let edition = Edition::from_one(0, RangeElement::edition(eid));
        engine.register_edition(Edition::from_one(0, RangeElement::text("data")), eid, BertProp::make());

        let left = HyperRef::single(Some(edition), None, None, None);
        let right = HyperRef::single(Some(Edition::from_text("target")), None, None, None);
        let link = HyperLink::make(vec![], left, right);
        let lid = engine.alloc_link_id();
        engine.register_link(link, lid);

        let found = engine.find_links_referencing_edition(eid);
        assert_eq!(found.len(), 1);
        assert_eq!(found[0], lid);
    }

    #[test]
    fn backfollow_engine_find_links_from_work() {
        let mut engine = BackfollowEngine::new();
        let left = HyperRef::single(Some(Edition::from_text("source")), Some(42), None, None);
        let right = HyperRef::single(Some(Edition::from_text("target")), None, None, None);
        let link = HyperLink::make(vec![], left, right);
        let lid = engine.alloc_link_id();
        engine.register_link(link, lid);

        let found = engine.find_links_from_work(42);
        assert_eq!(found.len(), 1);

        let not_found = engine.find_links_from_work(99);
        assert!(not_found.is_empty());
    }

    #[test]
    fn backfollow_engine_unregister_link() {
        let mut engine = BackfollowEngine::new();
        let left = HyperRef::single(Some(Edition::from_text("source")), None, None, None);
        let right = HyperRef::single(Some(Edition::from_text("target")), None, None, None);
        let link = HyperLink::make(vec![], left, right);
        let lid = engine.alloc_link_id();
        engine.register_link(link, lid);
        assert_eq!(engine.link_count(), 1);

        engine.unregister_link(lid);
        assert_eq!(engine.link_count(), 0);
    }

    #[test]
    fn backfollow_engine_update_link() {
        let mut engine = BackfollowEngine::new();
        let left = HyperRef::single(Some(Edition::from_one(0, RangeElement::text("source"))), None, None, None);
        let right = HyperRef::single(Some(Edition::from_one(0, RangeElement::text("target"))), None, None, None);
        let link = HyperLink::make(vec![], left, right);
        let lid = engine.alloc_link_id();
        engine.register_link(link, lid);

        let updated_left = HyperRef::single(Some(Edition::from_one(0, RangeElement::text("new_source"))), None, None, None);
        let new_link = engine.get_link(lid).unwrap().with_end("LeftEnd", updated_left);
        engine.update_link(lid, new_link);

        let found = engine.find_links_to_content(&RangeElement::text("new_source"));
        assert_eq!(found.len(), 1);
    }

    #[test]
    fn gold_link_transclusion_integration() {
        let mut engine = BackfollowEngine::new();
        let e1 = engine.alloc_edition_id();
        let e2 = engine.alloc_edition_id();
        engine.register_edition(Edition::from_one(0, RangeElement::text("docA")), e1, BertProp::make());
        engine.register_edition(Edition::from_one(0, RangeElement::text("docB")), e2, BertProp::make());

        let left = HyperRef::single(Some(Edition::from_one(0, RangeElement::text("docA"))), None, None, None);
        let right = HyperRef::single(Some(Edition::from_one(0, RangeElement::text("docB"))), None, None, None);
        let link = HyperLink::make(vec![], left, right);
        let lid = engine.alloc_link_id();
        engine.register_link(link, lid);

        let links_to_a = engine.find_links_to_content(&RangeElement::text("docA"));
        let links_to_b = engine.find_links_to_content(&RangeElement::text("docB"));
        assert_eq!(links_to_a.len(), 1);
        assert_eq!(links_to_b.len(), 1);

        let transcluders = engine.find_transcluders(&RangeElement::text("docA"), &TransclusionQuery::all());
        assert!(transcluders.len() >= 1);
    }

    #[test]
    fn gold_multi_ended_link_find() {
        let mut engine = BackfollowEngine::new();
        let left = HyperRef::single(Some(Edition::from_one(0, RangeElement::text("A"))), None, None, None);
        let right = HyperRef::single(Some(Edition::from_one(0, RangeElement::text("B"))), None, None, None);
        let note = HyperRef::single(Some(Edition::from_one(0, RangeElement::text("C"))), None, None, None);
        let link = HyperLink::make(vec![], left, right).with_end("Note", note);
        let lid = engine.alloc_link_id();
        engine.register_link(link, lid);

        assert_eq!(engine.find_links_to_content(&RangeElement::text("A")).len(), 1);
        assert_eq!(engine.find_links_to_content(&RangeElement::text("B")).len(), 1);
        assert_eq!(engine.find_links_to_content(&RangeElement::text("C")).len(), 1);
    }

    #[test]
    fn incremental_update_removes_old_adds_new() {
        let mut engine = BackfollowEngine::new();
        let old_edition = Edition::from_one(0, RangeElement::text("hello"));
        let work = Work::new(1, old_edition);
        engine.register_work(work, 1, None);

        let q = TransclusionQuery::all();
        let results = engine.find_transcluders(&RangeElement::text("hello"), &q);
        assert!(!results.is_empty());

        let new_edition = Edition::from_one(0, RangeElement::text("goodbye"));
        let updated_work = Work::new(1, new_edition);
        engine.update_work(1, updated_work);

        let old_results = engine.find_transcluders(&RangeElement::text("hello"), &q);
        assert!(old_results.is_empty(), "old content should be removed from index");

        let new_results = engine.find_transcluders(&RangeElement::text("goodbye"), &q);
        assert!(!new_results.is_empty(), "new content should be in index");
    }

    #[test]
    fn fingerprint_to_works_multi_valued() {
        let mut engine = BackfollowEngine::new();
        let shared_text = RangeElement::text("common content");
        let edition_a = Edition::from_one(0, shared_text.clone());
        let edition_b = Edition::from_one(0, shared_text.clone());
        let work_a = Work::new(10, edition_a);
        let work_b = Work::new(20, edition_b);
        engine.register_work(work_a, 10, None);
        engine.register_work(work_b, 20, None);

        let fp = shared_text.content_fingerprint();
        let works = engine.find_works_by_fingerprint(&fp);
        assert_eq!(works.len(), 2, "both works should be found for shared content");
        assert!(works.contains(&10));
        assert!(works.contains(&20));
    }

    #[test]
    fn incremental_update_cleans_fingerprint_index() {
        let mut engine = BackfollowEngine::new();
        let elem = RangeElement::text("unique text");
        let edition = Edition::from_one(0, elem.clone());
        let work = Work::new(1, edition);
        engine.register_work(work, 1, None);

        let fp = elem.content_fingerprint();
        assert_eq!(engine.find_works_by_fingerprint(&fp).len(), 1);

        let new_elem = RangeElement::text("different text");
        let new_edition = Edition::from_one(0, new_elem);
        let updated_work = Work::new(1, new_edition);
        engine.update_work(1, updated_work);

        assert!(engine.find_works_by_fingerprint(&fp).is_empty(),
            "old fingerprint should be removed");
    }

    #[test]
    fn unregister_edition_cleans_index() {
        let mut engine = BackfollowEngine::new();
        let elem = RangeElement::text("test content");
        let edition = Edition::from_one(0, elem.clone());
        let prop = BertProp::new(vec![], vec![], false, false);
        engine.register_edition(edition, 1, prop);

        let q = TransclusionQuery::all();
        assert!(!engine.find_transcluders(&elem, &q).is_empty());

        engine.unregister_edition(1);
        assert!(engine.find_transcluders(&elem, &q).is_empty(),
            "unregistered edition should be removed from index");
    }

    #[test]
    fn register_work_with_prop_sets_h_crum() {
        crate::edition::init_endorsement_flags();
        let mut engine = BackfollowEngine::new();
        let work = Work::new(1, Edition::from_text("hello"));
        let prop = BertProp::make();
        engine.register_work_with_prop(work, 1, None, prop);

        let meta = engine.get_edition_meta(1).unwrap();
        assert!(meta.h_crum().is_some(), "register_work_with_prop should set h_crum");
        assert!(meta.trace_position().is_some(), "register_work_with_prop should set trace_position");
    }

    #[test]
    fn compute_work_endorsements_detects_text() {
        let work = Work::new(1, Edition::from_text("hello"));
        let endorsements = BackfollowEngine::compute_work_endorsements(&work);
        assert!(!endorsements.is_empty(), "text work should have endorsements");
        assert!(endorsements.iter().any(|id| id.number == TEXT_TOKEN as i64),
            "text work should have TEXT_TOKEN endorsement");
    }

    #[test]
    fn compute_work_endorsements_empty_work() {
        let work = Work::new(1, Edition::empty());
        let endorsements = BackfollowEngine::compute_work_endorsements(&work);
        assert!(endorsements.is_empty(), "empty work should have no endorsements");
    }

    #[test]
    fn make_work_prop_includes_permissions_and_endorsements() {
        let work = Work::new(1, Edition::from_text("hello"));
        let prop = BackfollowEngine::make_work_prop(&work, Some(42), Some(43));
        assert!(!prop.permissions().is_empty(), "prop should have permissions");
        assert!(!prop.endorsements().is_empty(), "prop should have endorsements");
        let flags = prop.flags();
        assert_ne!(flags, 0, "prop should have non-zero flags");
    }

    #[test]
    fn update_work_with_parent_creates_h_tree_edge() {
        crate::edition::init_endorsement_flags();
        let mut engine = BackfollowEngine::new();
        let work = Work::new(1, Edition::from_one(0, RangeElement::text("v1")));
        let prop = BackfollowEngine::make_work_prop(&work, None, None);
        engine.register_work_with_prop(work, 1, None, prop);

        let v2 = Work::new(1, Edition::from_one(0, RangeElement::text("v2")));
        engine.update_work_with_parent(1, 1, v2);

        let meta = engine.get_edition_meta(1).unwrap();
        assert!(meta.h_crum().is_some(), "updated work should have h_crum");
        let hc = meta.h_crum().unwrap().lock().unwrap();
        assert!(!hc.o_parents().is_empty(), "updated work should have o_parents linking to previous version");
    }

    #[test]
    fn find_transcluders_with_backfollow_returns_trail() {
        crate::edition::init_endorsement_flags();
        let mut engine = BackfollowEngine::new();
        let shared = RangeElement::text("X");
        let work_a = Work::new(1, Edition::from_one(0, shared.clone()));
        let prop_a = BackfollowEngine::make_work_prop(&work_a, None, None);
        engine.register_work_with_prop(work_a, 1, None, prop_a);

        let work_b = Work::new(2, Edition::from_one(0, shared.clone()));
        let prop_b = BackfollowEngine::make_work_prop(&work_b, None, None);
        engine.register_work_with_prop(work_b, 2, None, prop_b);

        let q = TransclusionQuery::all();
        let results = engine.find_transcluders_with_backfollow(&shared, &q);
        assert!(!results.is_empty(), "should find transcluders via backfollow");
    }

    #[test]
    fn dagwood_trace_positions_are_ordered() {
        crate::edition::init_endorsement_flags();
        let mut engine = BackfollowEngine::new();
        let work = Work::new(1, Edition::from_one(0, RangeElement::text("v1")));
        let prop = BackfollowEngine::make_work_prop(&work, None, None);
        engine.register_work_with_prop(work, 1, None, prop);

        let tp1 = engine.trace_position_of(1).unwrap();

        let v2 = Work::new(1, Edition::from_one(0, RangeElement::text("v2")));
        engine.update_work_with_parent(1, 1, v2);
        let tp2 = engine.trace_position_of(1).unwrap();

        assert_eq!(engine.version_is_le(1, 1), Some(true), "a version should be <= itself");
        assert_ne!(tp1, tp2, "different versions should have different trace positions");
    }

    #[test]
    fn version_ancestors_across_different_works() {
        crate::edition::init_endorsement_flags();
        let mut engine = BackfollowEngine::new();
        let work_a = Work::new(1, Edition::from_one(0, RangeElement::text("A")));
        let prop_a = BackfollowEngine::make_work_prop(&work_a, None, None);
        engine.register_work_with_prop(work_a, 1, None, prop_a);

        let ancestors_a = engine.version_ancestors(1);
        assert!(ancestors_a.is_empty(), "work with no parent has no ancestors");

        let work_b = Work::new(2, Edition::from_one(0, RangeElement::text("B")));
        let prop_b = BackfollowEngine::make_work_prop(&work_b, None, None);
        engine.register_work_with_prop(work_b, 2, None, prop_b);

        let ancestors_b = engine.version_ancestors(2);
        assert!(ancestors_b.is_empty(), "work with no parent has no ancestors");

        assert_eq!(engine.version_is_le(1, 2), Some(false), "unrelated works should not be ordered");
        assert_eq!(engine.version_is_le(2, 1), Some(false), "unrelated works should not be ordered");
    }

    #[test]
    fn edition_to_assertions_maps_text() {
        use crate::ent::content::AssertionPayload;
        let edition = Edition::from_text("hello");
        let mut dagwood = DagWood::new();
        let tp = dagwood.new_position();
        let assertions = edition_to_assertions(1, &edition, tp);
        assert!(!assertions.is_empty());
        let has_create_node = assertions.iter().any(|a| matches!(a.payload, AssertionPayload::CreateNode { .. }));
        assert!(has_create_node, "should have CreateNode assertion");
        let has_set_span = assertions.iter().any(|a| matches!(a.payload, AssertionPayload::SetSpanText { .. }));
        assert!(has_set_span, "should have SetSpanText assertion");
    }
}
