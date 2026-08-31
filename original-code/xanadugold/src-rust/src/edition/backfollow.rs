use std::collections::HashSet;
use std::sync::Arc;
use std::sync::Mutex;

use super::canopy::{compute_join, propagate_flags, BertCanopy, CanopyCrumData, SensorCanopy};
use super::edition::Edition;
use super::links::HyperLink;
use super::props::{BertProp, PropFinder};
use super::range_element::RangeElement;
use super::recorder::RecorderId;
use super::transclusion::{
    TrailBlazer, TransclusionIndex, TransclusionQuery, TransclusionResult, WorkQuery,
};
use super::work::Work;
use super::wrapper::{WrapperRegistry, WRAPPER_CLUB_ID};
use crate::ent::content::{
    AssertionPayload, AssertionStore, DocumentId, MaterializedDocument, SpanId,
};
use crate::ent::dagwood::{DagWood, TraceView};
use crate::ent::htree::{HPart, HUpperCrumData};
use crate::ent::trace::TracePosition;

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
        self.bert_crum
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .set_own_flags(flags);
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
        let flags = self
            .bert_crum
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .flags();
        if !finder.does_pass(flags) {
            return false;
        }
        if let Some(ref hc) = self.h_crum {
            return hc
                .lock()
                .unwrap_or_else(|e| e.into_inner())
                .any_passes(finder);
        }
        true
    }
}

impl HPart for EditionMeta {
    fn h_crum(&self) -> Option<Arc<Mutex<HUpperCrumData>>> {
        self.h_crum.clone()
    }
}

pub struct BackfollowEngine {
    transclusion_index: TransclusionIndex,
    bert_canopy: BertCanopy,
    sensor_canopy: SensorCanopy,
    edition_metas: std::collections::HashMap<u64, EditionMeta>,
    /// Content keys each link registered under — the bookkeeping that
    /// makes unregister O(keys) instead of re-deriving registrations
    /// by deep comparison over every excerpt element (FR-50 finding 5).
    link_registrations: std::collections::HashMap<u64, Vec<String>>,
    fingerprint_to_works: std::collections::HashMap<[u8; 32], std::collections::HashSet<u64>>,
    fossil_by_fingerprint:
        std::collections::HashMap<[u8; 32], std::collections::HashSet<RecorderId>>,
    dagwood: DagWood,
    parent_of: std::collections::HashMap<u64, Vec<u64>>,
    assertion_store: AssertionStore,
    next_span_id: u64,
    work_spans: std::collections::HashMap<u64, Vec<SpanId>>,
}

impl std::fmt::Debug for BackfollowEngine {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("BackfollowEngine")
            .field("edition_metas", &self.edition_metas)
            .field("parent_of", &self.parent_of)
            .finish()
    }
}

impl BackfollowEngine {
    pub fn new() -> Self {
        BackfollowEngine {
            transclusion_index: TransclusionIndex::new(),
            bert_canopy: BertCanopy::new(),
            sensor_canopy: SensorCanopy::new(),
            edition_metas: std::collections::HashMap::new(),
            link_registrations: std::collections::HashMap::new(),
            fingerprint_to_works: std::collections::HashMap::new(),
            fossil_by_fingerprint: std::collections::HashMap::new(),
            dagwood: DagWood::new(),
            parent_of: std::collections::HashMap::new(),
            assertion_store: AssertionStore::new(),
            next_span_id: 1,
            work_spans: std::collections::HashMap::new(),
        }
    }

    pub fn register_edition(&mut self, edition: &Edition, edition_id: u64, prop: BertProp) {
        let flags = prop.flags();
        let bert_crum = self.bert_canopy.make_crum(flags);
        let sensor_crum = self.sensor_canopy.make_crum(0);
        let meta = EditionMeta::new(edition_id, bert_crum, sensor_crum, prop);
        let edition_elem = RangeElement::edition(edition_id);
        self.transclusion_index
            .register_edition(edition, &edition_elem, None);
        self.edition_metas.insert(edition_id, meta);
    }

    pub fn register_edition_with_parent(
        &mut self,
        edition: &Edition,
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
                let parent_bert = parent_hc
                    .lock()
                    .unwrap_or_else(|e| e.into_inner())
                    .bert_crum()
                    .clone();
                let _joined = compute_join(&meta.bert_crum, &parent_bert);
            }
        }
        let edition_elem = RangeElement::edition(edition_id);
        self.transclusion_index
            .register_edition(edition, &edition_elem, None);
        self.edition_metas.insert(edition_id, meta);
    }

    pub fn register_work(&mut self, work: &Work, work_id: u64, edition_id: Option<u64>) {
        let edition = work.current_edition();
        let work_elem = RangeElement::work(work_id);
        self.transclusion_index.register_work(edition, &work_elem);
        for (_, carrier) in edition.all_entries() {
            let fp = carrier.element.content_fingerprint();
            self.fingerprint_to_works
                .entry(fp)
                .or_default()
                .insert(work_id);
        }
        if let Some(eid) = edition_id {
            if let Some(meta) = self.edition_metas.get_mut(&eid) {
                meta.add_work(work_id);
            }
        }
    }

    pub fn register_work_with_prop(
        &mut self,
        work: &Work,
        work_id: u64,
        edition_id: Option<u64>,
        prop: BertProp,
    ) {
        let edition = work.current_edition();
        let work_elem = RangeElement::work(work_id);
        self.transclusion_index.register_work(edition, &work_elem);
        for (_, carrier) in edition.all_entries() {
            let fp = carrier.element.content_fingerprint();
            self.fingerprint_to_works
                .entry(fp)
                .or_default()
                .insert(work_id);
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
        self.bridge_edition_to_assertions(work_id, work.current_edition(), tp);
    }

    pub fn update_work_with_parent(
        &mut self,
        work_id: u64,
        parent_work_id: u64,
        old_edition: &Edition,
        new_work: &Work,
    ) {
        // FR-34 recorders: the index churn is crum-guided and
        // incremental (only differing subtrees); the metadata below
        // (crums, dagwood, assertions) is unchanged.
        self.update_work_incremental(work_id, old_edition, new_work);
        let new_edition = new_work.current_edition();

        let parent_tp = self
            .edition_metas
            .get(&parent_work_id)
            .and_then(|m| m.trace_position().copied());
        let tp = if let Some(parent_pos) = parent_tp {
            self.dagwood.new_position_after(parent_pos)
        } else {
            self.dagwood.new_position()
        };
        let old_prop = self
            .edition_metas
            .get(&work_id)
            .map(|m| m.prop().clone())
            .unwrap_or_else(BertProp::make);
        let new_endorsements = Self::compute_work_endorsements(new_work);
        let updated_prop = BertProp::new(
            old_prop.permissions().to_vec(),
            new_endorsements,
            false,
            false,
        );
        let flags = updated_prop.flags();
        let bert_crum = self.bert_canopy.make_crum(flags);
        let sensor_crum = self.sensor_canopy.make_crum(0);

        let parent_arc: Option<Arc<Mutex<EditionMeta>>> = self
            .edition_metas
            .get(&parent_work_id)
            .map(|m| Arc::new(Mutex::new(m.clone())));

        let h_crum = if let Some(parent_meta) = parent_arc {
            let h = HUpperCrumData::from_two(
                parent_meta.clone() as Arc<Mutex<dyn HPart>>,
                Arc::new(Mutex::new(EditionMeta::new(
                    work_id,
                    bert_crum.clone(),
                    sensor_crum.clone(),
                    updated_prop.clone(),
                ))) as Arc<Mutex<dyn HPart>>,
                tp,
                self.bert_canopy.clone(),
            );
            Arc::new(Mutex::new(h))
        } else {
            let h = HUpperCrumData::new(tp, bert_crum.clone(), self.bert_canopy.clone());
            Arc::new(Mutex::new(h))
        };

        let mut meta = EditionMeta::new(work_id, bert_crum, sensor_crum, updated_prop);
        meta.set_h_crum(h_crum);
        meta.set_trace_position(tp);
        self.parent_of.insert(work_id, vec![parent_work_id]);
        self.edition_metas.insert(work_id, meta);
        self.bridge_edition_to_assertions(work_id, new_work.current_edition(), tp);
    }

    pub fn update_work(&mut self, work_id: u64, old_edition: &Edition, new_work: &Work) {
        self.update_work_incremental(work_id, old_edition, new_work);
    }

    /// FR-34 recorders: crum-guided incremental update — parallel
    /// orgl descent prunes identical subtrees (equal crums), so a
    /// small edit churns only the differing entries' keys. Both
    /// indexes get count-based deltas; the full unregister/register
    /// walk (O(N) per edit, quadratic retains) only runs at restore.
    pub fn update_work_incremental(
        &mut self,
        work_id: u64,
        old_edition: &Edition,
        new_work: &Work,
    ) {
        use std::collections::HashMap;
        let new_edition = new_work.current_edition();

        // Count (element_key, fingerprint) occurrences per side over
        // ONLY the differing subtrees; equal crums cancel wholesale.
        let mut old_keys: HashMap<String, usize> = HashMap::new();
        let mut new_keys: HashMap<String, usize> = HashMap::new();
        let mut old_fps: HashMap<[u8; 32], usize> = HashMap::new();
        let mut new_fps: HashMap<[u8; 32], usize> = HashMap::new();
        old_edition
            .orgl
            .crum_diff_visit(&new_edition.orgl, &mut |carrier, removed| {
                let key = super::transclusion::element_key(&carrier.element);
                let fp = carrier.element.content_fingerprint();
                if removed {
                    *old_keys.entry(key).or_default() += 1;
                    *old_fps.entry(fp).or_default() += 1;
                } else {
                    *new_keys.entry(key).or_default() += 1;
                    *new_fps.entry(fp).or_default() += 1;
                }
            });

        let work_elem = RangeElement::work(work_id);
        let mut keys: Vec<&String> = old_keys.keys().chain(new_keys.keys()).collect();
        keys.sort();
        keys.dedup();
        for key in keys {
            let oc = old_keys.get(key).copied().unwrap_or(0);
            let nc = new_keys.get(key).copied().unwrap_or(0);
            if oc > nc {
                self.transclusion_index
                    .remove_counted(key, &work_elem, oc - nc);
            } else if nc > oc {
                self.transclusion_index
                    .add_counted(key, &work_elem, nc - oc);
            }
        }

        let mut fps: Vec<&[u8; 32]> = old_fps.keys().chain(new_fps.keys()).collect();
        fps.sort();
        fps.dedup();
        for fp in fps {
            let oc = old_fps.get(fp).copied().unwrap_or(0);
            let nc = new_fps.get(fp).copied().unwrap_or(0);
            if oc > 0 && nc == 0 {
                if let Some(set) = self.fingerprint_to_works.get_mut(fp) {
                    set.remove(&work_id);
                    if set.is_empty() {
                        self.fingerprint_to_works.remove(fp);
                    }
                }
            } else if oc == 0 && nc > 0 {
                self.fingerprint_to_works
                    .entry(*fp)
                    .or_default()
                    .insert(work_id);
            }
        }
    }

    pub fn update_work_full(&mut self, work_id: u64, old_edition: &Edition, new_work: &Work) {
        let old_elem = RangeElement::work(work_id);
        self.transclusion_index
            .unregister_work(old_edition, &old_elem);
        for (_, carrier) in old_edition.all_entries() {
            let fp = carrier.element.content_fingerprint();
            if let Some(set) = self.fingerprint_to_works.get_mut(&fp) {
                set.remove(&work_id);
                if set.is_empty() {
                    self.fingerprint_to_works.remove(&fp);
                }
            }
        }
        let new_edition = new_work.current_edition();
        let work_elem = RangeElement::work(work_id);
        self.transclusion_index
            .register_work(new_edition, &work_elem);
        for (_, carrier) in new_edition.all_entries() {
            let fp = carrier.element.content_fingerprint();
            self.fingerprint_to_works
                .entry(fp)
                .or_default()
                .insert(work_id);
        }
    }

    pub fn compute_work_endorsements(work: &Work) -> Vec<super::grandmap::Id> {
        use super::grandmap::Id;
        let registry = WrapperRegistry::new();
        let edition = work.current_edition();
        let mut endorsements = Vec::new();
        for spec in registry.all_specs() {
            if spec.check(edition) {
                endorsements.push(Id::in_space(
                    super::grandmap::IdSpaceId(WRAPPER_CLUB_ID),
                    spec.token_id() as i64,
                ));
            }
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

    pub fn unregister_edition(&mut self, edition_id: u64, edition: &Edition) {
        if self.edition_metas.remove(&edition_id).is_some() {
            let elem = RangeElement::edition(edition_id);
            self.transclusion_index
                .unregister_edition(edition, &elem, None);
        }
    }

    pub fn update_edition_prop(&mut self, edition_id: u64, new_prop: BertProp) {
        if let Some(meta) = self.edition_metas.get_mut(&edition_id) {
            meta.update_prop(new_prop);
        }
    }

    pub fn on_prop_changed(&self, edition_id: u64) -> Vec<RecorderId> {
        let meta = match self.edition_metas.get(&edition_id) {
            Some(m) => m,
            None => return Vec::new(),
        };
        let sensor_crum = meta.sensor_crum();
        let crum_guard = sensor_crum.lock().unwrap_or_else(|e| e.into_inner());
        let flags = crum_guard.flags();
        if flags & crate::edition::props::IS_SENSOR_WAITING_FLAG == 0 {
            return Vec::new();
        }
        crate::edition::hoist::check_recorders(sensor_crum, |_| true)
    }

    pub fn on_work_created(&mut self, work_id: u64, work: &Work) {
        let edition = work.current_edition();
        for (_, carrier) in edition.all_entries() {
            let fp = carrier.element.content_fingerprint();
            self.fingerprint_to_works
                .entry(fp)
                .or_default()
                .insert(work_id);
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
                                let visited_flags = visited_hc
                                    .lock()
                                    .unwrap_or_else(|e| e.into_inner())
                                    .bert_crum()
                                    .lock()
                                    .unwrap_or_else(|e| e.into_inner())
                                    .flags();
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

    pub fn find_works_for_content(&self, content: &RangeElement, query: &WorkQuery) -> Vec<u64> {
        let work_elements = self.transclusion_index.find_works(content, query);
        let mut work_ids = Vec::new();
        for elem in work_elements {
            if let Some(wid) = elem.as_work_id() {
                work_ids.push(wid);
            }
        }
        work_ids
    }

    pub fn get_edition_meta(&self, id: u64) -> Option<&EditionMeta> {
        self.edition_metas.get(&id)
    }

    pub fn version_is_le(&mut self, a: u64, b: u64) -> Option<bool> {
        let tp_a = self
            .edition_metas
            .get(&a)
            .and_then(|m| m.trace_position().copied());
        let tp_b = self
            .edition_metas
            .get(&b)
            .and_then(|m| m.trace_position().copied());
        match (tp_a, tp_b) {
            (Some(a_pos), Some(b_pos)) => Some(self.dagwood.is_le(a_pos, b_pos)),
            _ => None,
        }
    }

    pub fn version_ancestors(&self, work_id: u64) -> Vec<u64> {
        self.parent_of.get(&work_id).cloned().unwrap_or_default()
    }

    pub fn version_ancestors_transitive(&self, work_id: u64) -> Vec<u64> {
        let mut result = Vec::new();
        let mut stack = vec![work_id];
        let mut visited = HashSet::new();
        while let Some(id) = stack.pop() {
            if !visited.insert(id) {
                continue;
            }
            if let Some(parents) = self.parent_of.get(&id) {
                for &parent in parents {
                    if !visited.contains(&parent) {
                        result.push(parent);
                        stack.push(parent);
                    }
                }
            }
        }
        result
    }

    pub fn version_descendants(&self, work_id: u64) -> Vec<u64> {
        let mut result = Vec::new();
        let mut stack = vec![work_id];
        let mut visited = HashSet::new();
        while let Some(id) = stack.pop() {
            for (&child, parents) in &self.parent_of {
                if parents.contains(&id) && visited.insert(child) {
                    result.push(child);
                    stack.push(child);
                }
            }
        }
        result
    }

    pub fn trace_position_of(&self, work_id: u64) -> Option<TracePosition> {
        self.edition_metas
            .get(&work_id)
            .and_then(|m| m.trace_position().copied())
    }

    pub fn assertion_store(&self) -> &AssertionStore {
        &self.assertion_store
    }

    pub fn dagwood(&self) -> &DagWood {
        &self.dagwood
    }

    pub fn trace_view_for_work(&self, work_id: u64) -> Option<TraceView> {
        let meta = self.edition_metas.get(&work_id)?;
        let tp = meta.trace_position().copied()?;
        Some(self.dagwood.trace_view(tp))
    }

    pub fn materialize_work(&self, work_id: u64) -> Option<MaterializedDocument> {
        let meta = self.edition_metas.get(&work_id)?;
        let tp = meta.trace_position().copied()?;
        let view = self.dagwood.trace_view(tp);
        let doc_id = DocumentId::new(work_id);
        Some(crate::ent::content::materialize_document(
            &self.assertion_store,
            &view,
            doc_id,
        ))
    }

    fn bridge_edition_to_assertions(&mut self, work_id: u64, edition: &Edition, tp: TracePosition) {
        let doc_id = DocumentId::new(work_id);
        let node_id = doc_id.node_id();

        let first_time = !self.work_spans.contains_key(&work_id);

        if first_time {
            self.assertion_store.add(
                tp,
                AssertionPayload::CreateNode {
                    node_id,
                    kind: "document".into(),
                },
            );
        }

        let old_span_count = self.work_spans.get(&work_id).map(|s| s.len()).unwrap_or(0);
        let entries = edition.all_entries();
        let new_count = entries.len();

        let mut spans = self.work_spans.remove(&work_id).unwrap_or_default();

        for i in old_span_count..new_count {
            let span_id = SpanId::new(self.next_span_id);
            self.next_span_id += 1;
            spans.push(span_id);
            self.assertion_store
                .add(tp, AssertionPayload::CreateSpan { span_id });
            self.assertion_store.add(
                tp,
                AssertionPayload::AttachSpanToNode {
                    node_id,
                    span_id,
                    ordinal: i as u32,
                },
            );
        }

        for (i, (_, carrier)) in entries.iter().enumerate() {
            let span_id = spans[i];
            let text = carrier.element.as_text().unwrap_or("").to_string();
            self.assertion_store
                .add(tp, AssertionPayload::SetSpanText { span_id, text });
        }

        self.work_spans.insert(work_id, spans);
    }

    pub fn transclusion_index(&self) -> &TransclusionIndex {
        &self.transclusion_index
    }

    pub fn transclusion_index_mut(&mut self) -> &mut TransclusionIndex {
        &mut self.transclusion_index
    }

    pub fn fingerprint_to_works(
        &self,
    ) -> &std::collections::HashMap<[u8; 32], std::collections::HashSet<u64>> {
        &self.fingerprint_to_works
    }

    pub fn find_works_by_fingerprint(&self, fp: &[u8; 32]) -> Vec<u64> {
        self.fingerprint_to_works
            .get(fp)
            .map(|set| set.iter().copied().collect())
            .unwrap_or_default()
    }

    pub fn register_fingerprint_for_work(&mut self, fp: [u8; 32], work_id: u64) {
        self.fingerprint_to_works
            .entry(fp)
            .or_default()
            .insert(work_id);
    }

    pub fn register_federated_entry(
        &mut self,
        content: &RangeElement,
        origin_server_id: String,
        local_id: u64,
        element_type: String,
        is_direct: bool,
    ) {
        self.transclusion_index.register_federated(
            content,
            origin_server_id,
            local_id,
            element_type,
            is_direct,
        );
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

    pub fn plant_recorder(
        &mut self,
        edition_id: u64,
        fossil_id: RecorderId,
        content: &[RangeElement],
    ) {
        #[cfg(feature = "server")]
        {
            tracing::debug!(target: "xudanu::content_watch",
            edition_id, fossil_id, content_count = content.len(),
            "plant_recorder: installing fossil");
        }
        if let Some(meta) = self.edition_metas.get(&edition_id) {
            let scrum = meta.sensor_crum();
            scrum
                .lock()
                .unwrap_or_else(|e| e.into_inner())
                .install_recorders(&[fossil_id]);
            propagate_flags(scrum);
        } else {
            #[cfg(feature = "server")]
            {
                tracing::debug!(target: "xudanu::content_watch",
                edition_id, fossil_id,
                "plant_recorder: no edition_meta found for edition_id");
            }
        }
        for elem in content {
            let fp = elem.content_fingerprint();
            self.fossil_by_fingerprint
                .entry(fp)
                .or_default()
                .insert(fossil_id);
        }
        #[cfg(feature = "server")]
        {
            tracing::debug!(target: "xudanu::content_watch",
            fossil_id, total_fp_entries = self.fossil_by_fingerprint.len(),
            "plant_recorder: fossil_by_fingerprint updated");
        }
    }

    pub fn plant_recorder_with_hoist(
        &mut self,
        edition_id: u64,
        fossil_id: RecorderId,
        content: &[RangeElement],
    ) -> Option<Box<dyn super::recorder::AgendaItem>> {
        let hoist_item = if let Some(meta) = self.edition_metas.get(&edition_id) {
            let scrum = meta.sensor_crum().clone();
            self.sensor_canopy.recording_agent(&scrum, fossil_id)
        } else {
            None
        };
        for elem in content {
            let fp = elem.content_fingerprint();
            self.fossil_by_fingerprint
                .entry(fp)
                .or_default()
                .insert(fossil_id);
        }
        hoist_item
    }

    pub fn register_fossil_fingerprints(
        &mut self,
        fossil_id: RecorderId,
        content: &[RangeElement],
    ) {
        for elem in content {
            let fp = elem.content_fingerprint();
            self.fossil_by_fingerprint
                .entry(fp)
                .or_default()
                .insert(fossil_id);
        }
    }

    pub fn fossil_fingerprints(
        &self,
    ) -> &std::collections::HashMap<[u8; 32], std::collections::HashSet<RecorderId>> {
        &self.fossil_by_fingerprint
    }

    pub fn filter_fossils_by_permission(
        &self,
        fossil_ids: &[RecorderId],
        queries: &std::collections::HashMap<RecorderId, (Vec<u64>, Option<Vec<u64>>)>,
        edition_id: u64,
    ) -> Vec<RecorderId> {
        let meta = match self.edition_metas.get(&edition_id) {
            Some(m) => m,
            None => return fossil_ids.to_vec(),
        };
        let meta_flags = meta
            .bert_crum
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .flags();
        fossil_ids
            .iter()
            .copied()
            .filter(|fid| {
                if let Some((authority_clubs, _endo_filter)) = queries.get(fid) {
                    if authority_clubs.is_empty() {
                        return true;
                    }
                    let query_flags = crate::edition::props::permissions_flags(
                        &authority_clubs
                            .iter()
                            .map(|&c| super::grandmap::Id::global(c as i64))
                            .collect::<Vec<_>>(),
                    );
                    (query_flags & meta_flags) != 0
                } else {
                    true
                }
            })
            .collect()
    }

    pub fn is_sensor_waiting(&self, edition_id: u64) -> bool {
        self.edition_metas
            .get(&edition_id)
            .map(|m| {
                let flags = m
                    .sensor_crum
                    .lock()
                    .unwrap_or_else(|e| e.into_inner())
                    .flags();
                (flags & crate::edition::props::IS_SENSOR_WAITING_FLAG) != 0
            })
            .unwrap_or(false)
    }

    pub fn remove_planted_recorder(
        &mut self,
        edition_id: u64,
        fossil_id: RecorderId,
        content: &[RangeElement],
    ) {
        if let Some(meta) = self.edition_metas.get(&edition_id) {
            let scrum = meta.sensor_crum();
            scrum
                .lock()
                .unwrap_or_else(|e| e.into_inner())
                .remove_recorders(&[fossil_id]);
            propagate_flags(scrum);
        }
        for elem in content {
            let fp = elem.content_fingerprint();
            if let Some(set) = self.fossil_by_fingerprint.get_mut(&fp) {
                set.remove(&fossil_id);
            }
        }
        self.fossil_by_fingerprint.retain(|_, set| !set.is_empty());
    }

    pub fn recorders_on_edition(&self, edition_id: u64) -> Vec<RecorderId> {
        self.edition_metas
            .get(&edition_id)
            .map(|meta| {
                meta.sensor_crum()
                    .lock()
                    .unwrap_or_else(|e| e.into_inner())
                    .recorders()
                    .to_vec()
            })
            .unwrap_or_default()
    }

    pub fn check_recorders_for_change(&self, edition_id: u64) -> Vec<(RecorderId, u64)> {
        let mut results = Vec::new();
        let meta = match self.edition_metas.get(&edition_id) {
            Some(m) => m,
            None => return results,
        };
        let scrum = meta.sensor_crum();
        {
            let guard = scrum.lock().unwrap_or_else(|e| e.into_inner());
            for &fossil_id in guard.recorders() {
                results.push((fossil_id, edition_id));
            }
        }
        let mut current = scrum
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .parent()
            .cloned();
        while let Some(p) = current {
            let guard = p.lock().unwrap_or_else(|e| e.into_inner());
            for &fossil_id in guard.recorders() {
                results.push((fossil_id, edition_id));
            }
            current = guard.parent().cloned();
        }
        results
    }

    pub fn check_recorders_by_content(&self, fingerprints: &[[u8; 32]]) -> Vec<RecorderId> {
        let mut seen = std::collections::HashSet::new();
        let mut results = Vec::new();
        let mut matched_fps = 0usize;
        for fp in fingerprints {
            if let Some(fossil_ids) = self.fossil_by_fingerprint.get(fp) {
                matched_fps += 1;
                for &fossil_id in fossil_ids {
                    if seen.insert(fossil_id) {
                        results.push(fossil_id);
                    }
                }
            }
        }
        #[cfg(feature = "server")]
        {
            tracing::debug!(target: "xudanu::content_watch",
            input_fp_count = fingerprints.len(), matched_fps, triggered_fossils = results.len(),
            total_fp_entries = self.fossil_by_fingerprint.len(),
            "check_recorders_by_content: lookup results");
        }
        results
    }

    pub fn register_link_content(&mut self, link: &HyperLink, link_id: u64) {
        use super::wrapper::{HYPERLINK_TOKEN, HYPERREF_TOKEN};
        let content = link.all_referenced_content();
        let link_elem = RangeElement::label(link_id, RangeElement::text("link"));
        let mut keys = Vec::with_capacity(content.len());
        for element in &content {
            self.transclusion_index
                .register_element(element, &link_elem);
            keys.push(crate::edition::transclusion::element_key(element));
        }
        self.link_registrations.insert(link_id, keys);
        let mut endorsements = vec![super::grandmap::Id::in_space(
            super::grandmap::IdSpaceId(WRAPPER_CLUB_ID),
            HYPERLINK_TOKEN as i64,
        )];
        if !content.is_empty() {
            endorsements.push(super::grandmap::Id::in_space(
                super::grandmap::IdSpaceId(WRAPPER_CLUB_ID),
                HYPERREF_TOKEN as i64,
            ));
        }
        let prop = BertProp::new(Vec::new(), endorsements, false, false);
        let flags = prop.flags();
        let bert_crum = self.bert_canopy.make_crum(flags);
        let sensor_crum = self.sensor_canopy.make_crum(0);
        let mut meta = EditionMeta::new(link_id, bert_crum, sensor_crum, prop);
        let tp = self.dagwood.new_position();
        meta.set_trace_position(tp);
        self.edition_metas.insert(link_id, meta);
    }

    pub fn unregister_link_content(&mut self, _link: &HyperLink, link_id: u64) {
        // Registrations were recorded at register time; removal is by
        // bookkeeping and label identity — no content re-derivation,
        // no per-element Edition, no deep equality (FR-50 finding 5:
        // this was O(excerpt) eq-scans per link per keystroke).
        if let Some(keys) = self.link_registrations.remove(&link_id) {
            for key in keys {
                self.transclusion_index.remove_link_entries(&key, link_id);
            }
        }
        self.edition_metas.remove(&link_id);
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
                        let flags = visited_hc
                            .lock()
                            .unwrap_or_else(|e| e.into_inner())
                            .bert_crum()
                            .lock()
                            .unwrap_or_else(|e| e.into_inner())
                            .flags();
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

    pub fn delayed_find_matching(&self, edition_id: u64, finder: &PropFinder) -> Vec<u64> {
        let mut trail = TrailBlazer::new();
        let mut hcrum_cache = HashSet::new();
        self.delayed_store_backfollow_for_edition(edition_id, finder, &mut hcrum_cache, &mut trail);
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

    // Recorder perf guard: one small edit on a 15k-char per-char
    // edition must update the indexes cheaply (was O(N) walk with
    // quadratic retains). Release-gated, generous bound.
    #[test]
    fn recorder_update_cost_guard() {
        let base: String = "recorder guard text ".repeat(750);
        let mut work = Work::new(1, Edition::from_text(&base));
        let mut engine = BackfollowEngine::new();
        engine.register_work_with_prop(
            &work,
            1,
            None,
            BackfollowEngine::make_work_prop(&work, None, None),
        );
        let old = work.current_edition().clone();
        let mut chars: Vec<char> = base.chars().collect();
        let mid = chars.len() / 2;
        chars.splice(mid..mid + 1, "!".chars());
        let revised: String = chars.into_iter().collect();
        work.revise(Edition::from_text(&revised));
        let t = std::time::Instant::now();
        engine.update_work_incremental(1, &old, &work);
        let us = t.elapsed().as_micros();
        eprintln!(
            "recorder update: {}us for one edit on {} chars",
            us,
            base.chars().count()
        );
        #[cfg(not(debug_assertions))]
        assert!(
            us < 20_000,
            "recorder update regression: {}us (bound 20000us)",
            us
        );
    }

    // FR-34 recorder armor: the crum-guided incremental update must
    // leave the indexes EXACTLY as full unregister+register would —
    // across insert-only, delete-heavy, and repeated edits.
    #[test]
    fn incremental_update_matches_full_reregistration() {
        use crate::edition::Work;
        fn engine_after_edits(incremental: bool, edits: &[&str]) -> (BackfollowEngine, u64) {
            let mut engine = BackfollowEngine::new();
            let mut work = Work::new(1, Edition::from_text(edits[0]));
            engine.register_work_with_prop(
                &work,
                1,
                None,
                BackfollowEngine::make_work_prop(&work, None, None),
            );
            for text in &edits[1..] {
                let old = work.current_edition().clone();
                work.revise(Edition::from_text(text));
                if incremental {
                    engine.update_work_incremental(1, &old, &work);
                } else {
                    engine.update_work_full(1, &old, &work);
                }
            }
            (engine, 1)
        }
        for edits in [
            vec!["hello world", "hello worlds"],
            vec!["aaaa bbbb cccc", "aaaa cccc", "aaaa cccc dddd"],
            vec!["one", "two", "three", "thre"],
            vec!["x", "x"],
        ] {
            let (inc, w1) = engine_after_edits(true, &edits);
            let (full, w2) = engine_after_edits(false, &edits);
            let q = WorkQuery::all();
            for probe in [
                "a", "b", "c", "d", "e", "h", "l", "o", "n", "r", "t", "w", "x", "s",
            ] {
                let r1 = inc.find_works_for_content(&RangeElement::text(probe.to_string()), &q);
                let r2 = full.find_works_for_content(&RangeElement::text(probe.to_string()), &q);
                assert_eq!(r1, r2, "probe {:?} for edits {:?}", probe, edits);
            }
            for probe_fp in [
                RangeElement::text(String::from("a")).content_fingerprint(),
                RangeElement::text(String::from("o")).content_fingerprint(),
                RangeElement::text(String::from("q")).content_fingerprint(),
            ] {
                let r1 = inc.find_works_by_fingerprint(&probe_fp);
                let r2 = full.find_works_by_fingerprint(&probe_fp);
                assert_eq!(r1, r2, "fp probe for edits {:?}", edits);
            }
            assert_eq!(w1, w2);
        }
    }

    // The visitor must prune: a small edit on a fragmented doc
    // visits a small fraction of entries.
    #[test]
    fn crum_diff_visit_prunes_on_small_edit() {
        let base: String = "the quick brown fox ".repeat(200);
        let old = Edition::from_text(&base);
        let mut chars: Vec<char> = base.chars().collect();
        let mid = chars.len() / 2;
        chars.splice(mid..mid + 3, "XYZ".chars());
        let new_text: String = chars.into_iter().collect();
        let new = Edition::from_text(&new_text);
        let mut visited_removed = 0usize;
        let mut visited_added = 0usize;
        old.orgl.crum_diff_visit(&new.orgl, &mut |_c, removed| {
            if removed {
                visited_removed += 1;
            } else {
                visited_added += 1;
            }
        });
        let total = base.chars().count();
        assert!(visited_added > 0, "the edit must register");
        assert!(
            visited_removed + visited_added < total / 2,
            "visited {} of {} — identical bulk must be pruned",
            visited_removed + visited_added,
            total
        );
    }
    use crate::edition::grandmap::Id;
    use crate::edition::links::HyperRef;
    use crate::edition::props::PUBLIC_CLUB_FLAG;
    use crate::edition::wrapper::TEXT_TOKEN;

    #[test]
    fn backfollow_engine_new() {
        let _engine = BackfollowEngine::new();
    }

    #[test]
    fn backfollow_engine_register_edition() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_text("hello");
        let id = 1u64;
        engine.register_edition(&edition, id, BertProp::make());
        assert!(engine.get_edition_meta(id).is_some());
    }

    #[test]
    fn backfollow_engine_find_transcluders_simple() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("hello"));
        let id = 1u64;
        engine.register_edition(&edition, id, BertProp::make());

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
        let id = 1u64;
        engine.register_edition(&edition, id, BertProp::make());

        let query = TransclusionQuery::all();
        let results = engine.find_transcluders(&RangeElement::text("goodbye"), &query);
        assert!(results.is_empty());
    }

    #[test]
    fn backfollow_engine_multiple_editions() {
        let mut engine = BackfollowEngine::new();
        let e1 = Edition::from_one(0, RangeElement::text("shared"));
        let e2 = Edition::from_one(0, RangeElement::text("shared"));
        let id1 = 1u64;
        let id2 = 2u64;
        engine.register_edition(&e1, id1, BertProp::make());
        engine.register_edition(&e2, id2, BertProp::make());

        let query = TransclusionQuery::all();
        let results = engine.find_transcluders(&RangeElement::text("shared"), &query);
        assert_eq!(results.len(), 2);
    }

    #[test]
    fn backfollow_engine_find_works() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("hello"));
        let eid = 1u64;
        engine.register_edition(&edition, eid, BertProp::make());

        let wid = 2u64;
        let work = Work::new_with_owner(wid, Some(1), edition);
        engine.register_work(&work, wid, Some(eid));

        let query = WorkQuery::all();
        let works = engine.find_works_for_content(&RangeElement::text("hello"), &query);
        assert_eq!(works.len(), 1);
        assert_eq!(works[0], wid);
    }

    #[test]
    fn backfollow_engine_unregister_edition() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("hello"));
        let id = 1u64;
        engine.register_edition(&edition, id, BertProp::make());
        assert!(engine.get_edition_meta(id).is_some());

        engine.unregister_edition(id, &edition);
        assert!(engine.get_edition_meta(id).is_none());
    }

    #[test]
    fn backfollow_engine_update_edition_prop() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("secret"));
        let id = 1u64;
        engine.register_edition(&edition, id, BertProp::make());

        let meta = engine.get_edition_meta(id).unwrap();
        assert_eq!(
            meta.bert_crum()
                .lock()
                .unwrap_or_else(|e| e.into_inner())
                .flags(),
            0
        );

        let new_prop = BertProp::permissions_prop(vec![Id::global(0)]);
        engine.update_edition_prop(id, new_prop);

        let meta = engine.get_edition_meta(id).unwrap();
        assert_eq!(
            meta.bert_crum()
                .lock()
                .unwrap_or_else(|e| e.into_inner())
                .own_flags(),
            PUBLIC_CLUB_FLAG
        );
    }

    #[test]
    fn backfollow_engine_edition_meta_any_passes() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("x"));
        let id = 1u64;
        engine.register_edition(&edition, id, BertProp::make());

        let open = PropFinder::open();
        let meta = engine.get_edition_meta(id).unwrap();
        assert!(meta.any_passes(&open));

        let prop = BertProp::permissions_prop(vec![Id::global(0)]);
        engine.update_edition_prop(id, prop);
        let meta = engine.get_edition_meta(id).unwrap();
        assert!(meta.any_passes(&open));
    }

    #[test]
    fn edition_meta_update_prop_propagates() {
        let canopy = BertCanopy::new();
        let sensor = SensorCanopy::new();
        let bert = canopy.make_crum(0);
        let sensor_crum = sensor.make_crum(0);
        let mut meta = EditionMeta::new(1, bert.clone(), sensor_crum, BertProp::make());

        assert_eq!(bert.lock().unwrap_or_else(|e| e.into_inner()).flags(), 0);
        meta.update_prop(BertProp::permissions_prop(vec![Id::global(0)]));
        assert_eq!(
            bert.lock().unwrap_or_else(|e| e.into_inner()).own_flags(),
            PUBLIC_CLUB_FLAG
        );
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
        let id = 1u64;
        engine.register_edition(&edition, id, BertProp::make());

        let query = TransclusionQuery::all();
        let results =
            engine.find_transcluders_with_backfollow(&RangeElement::text("hello"), &query);
        assert_eq!(results.len(), 1);
    }

    #[test]
    fn backfollow_engine_delayed_find_matching() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("data"));
        let id = 1u64;
        engine.register_edition(&edition, id, BertProp::make());

        let finder = PropFinder::open();
        let found = engine.delayed_find_matching(id, &finder);
        assert_eq!(found.len(), 1);
        assert_eq!(found[0], id);
    }

    #[test]
    fn backfollow_engine_delayed_find_matching_no_hcrum() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("data"));
        let id = 1u64;
        engine.register_edition(&edition, id, BertProp::make());

        let closed = PropFinder::closed();
        let found = engine.delayed_find_matching(id, &closed);
        assert!(found.is_empty());
    }

    #[test]
    fn backfollow_engine_register_edition_with_parent() {
        let mut engine = BackfollowEngine::new();
        let parent_edition = Edition::from_text("parent content");
        let parent_id = 1u64;
        engine.register_edition(&parent_edition, parent_id, BertProp::make());

        let child_edition = Edition::from_one(0, RangeElement::text("child"));
        let child_id = 2u64;
        engine.register_edition_with_parent(&child_edition, child_id, parent_id, BertProp::make());

        assert!(engine.get_edition_meta(child_id).is_some());
        assert!(engine.get_edition_meta(parent_id).is_some());
    }

    #[test]
    fn gold_backfollow_two_editions_shared_content() {
        let mut engine = BackfollowEngine::new();
        let e1 = Edition::from_text("abc");
        let e2 = Edition::from_one(0, RangeElement::text("a"));
        let id1 = 1u64;
        let id2 = 2u64;
        engine.register_edition(&e1, id1, BertProp::make());
        engine.register_edition(&e2, id2, BertProp::make());

        let query = TransclusionQuery::all();
        let results = engine.find_transcluders(&RangeElement::text("a"), &query);
        assert!(results.len() >= 2);

        let found_ids: Vec<u64> = results
            .iter()
            .filter_map(|r| r.element.as_edition_id())
            .collect();
        assert!(found_ids.contains(&id1));
        assert!(found_ids.contains(&id2));
    }

    #[test]
    fn gold_backfollow_work_on_edition() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("document"));
        let eid = 1u64;
        engine.register_edition(&edition, eid, BertProp::make());

        let wid = 2u64;
        let work = Work::new_with_owner(wid, Some(42), edition);
        engine.register_work(&work, wid, Some(eid));

        let query = WorkQuery::all();
        let works = engine.find_works_for_content(&RangeElement::text("document"), &query);
        assert_eq!(works.len(), 1);
        assert_eq!(works[0], wid);
    }

    #[test]
    fn gold_backfollow_unregister_removes_from_index() {
        let mut engine = BackfollowEngine::new();
        let edition = Edition::from_one(0, RangeElement::text("temp"));
        let id = 1u64;
        engine.register_edition(&edition, id, BertProp::make());

        let query = TransclusionQuery::all();
        assert_eq!(
            engine
                .find_transcluders(&RangeElement::text("temp"), &query)
                .len(),
            1
        );

        engine.unregister_edition(id, &edition);
        assert!(
            engine
                .find_transcluders(&RangeElement::text("temp"), &query)
                .is_empty(),
            "unregistered edition should be removed from index"
        );
    }

    #[test]
    fn gold_backfollow_prop_filtering() {
        let mut engine = BackfollowEngine::new();
        let e1 = Edition::from_one(0, RangeElement::text("public"));
        let e2 = Edition::from_one(0, RangeElement::text("public"));
        let id1 = 1u64;
        let id2 = 2u64;
        engine.register_edition(&e1, id1, BertProp::permissions_prop(vec![Id::global(0)]));
        engine.register_edition(&e2, id2, BertProp::make());

        let query = TransclusionQuery::all();
        let results = engine.find_transcluders(&RangeElement::text("public"), &query);
        assert_eq!(results.len(), 2);
    }

    #[test]
    fn stress_backfollow_many_editions() {
        let mut engine = BackfollowEngine::new();
        let num_editions = 500u64;
        for id in 1..=num_editions {
            let edition = Edition::from_one(0, RangeElement::text("common"));
            engine.register_edition(&edition, id, BertProp::make());
        }

        let query = TransclusionQuery::all();
        let results = engine.find_transcluders(&RangeElement::text("common"), &query);
        assert_eq!(results.len(), num_editions as usize);
    }

    #[test]
    fn backfollow_engine_register_link_content() {
        let mut engine = BackfollowEngine::new();
        let left = HyperRef::single(
            Some(Edition::from_one(0, RangeElement::text("source"))),
            None,
            None,
            None,
        );
        let right = HyperRef::single(
            Some(Edition::from_one(0, RangeElement::text("target"))),
            None,
            None,
            None,
        );
        let link = HyperLink::make(vec![], left, right);
        let lid = 1u64;
        engine.register_link_content(&link, lid);

        let query = TransclusionQuery::all();
        let results = engine.find_transcluders(&RangeElement::text("source"), &query);
        assert!(!results.is_empty(), "link content should be indexed");
    }

    #[test]
    fn gold_link_transclusion_integration() {
        let mut engine = BackfollowEngine::new();
        let e1 = 1u64;
        let e2 = 2u64;
        let ed_a = Edition::from_one(0, RangeElement::text("docA"));
        let ed_b = Edition::from_one(0, RangeElement::text("docB"));
        engine.register_edition(&ed_a, e1, BertProp::make());
        engine.register_edition(&ed_b, e2, BertProp::make());

        let left = HyperRef::single(
            Some(Edition::from_one(0, RangeElement::text("docA"))),
            None,
            None,
            None,
        );
        let right = HyperRef::single(
            Some(Edition::from_one(0, RangeElement::text("docB"))),
            None,
            None,
            None,
        );
        let link = HyperLink::make(vec![], left, right);
        let lid = 3u64;
        engine.register_link_content(&link, lid);

        let transcluders =
            engine.find_transcluders(&RangeElement::text("docA"), &TransclusionQuery::all());
        assert!(transcluders.len() >= 1);
    }

    #[test]
    fn incremental_update_removes_old_adds_new() {
        let mut engine = BackfollowEngine::new();
        let old_edition = Edition::from_one(0, RangeElement::text("hello"));
        let work = Work::new(1, old_edition.clone());
        engine.register_work(&work, 1, None);

        let q = TransclusionQuery::all();
        let results = engine.find_transcluders(&RangeElement::text("hello"), &q);
        assert!(!results.is_empty());

        let new_edition = Edition::from_one(0, RangeElement::text("goodbye"));
        let updated_work = Work::new(1, new_edition);
        engine.update_work(1, &old_edition, &updated_work);

        let old_results = engine.find_transcluders(&RangeElement::text("hello"), &q);
        assert!(
            old_results.is_empty(),
            "old content should be removed from index"
        );

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
        engine.register_work(&work_a, 10, None);
        engine.register_work(&work_b, 20, None);

        let fp = shared_text.content_fingerprint();
        let works = engine.find_works_by_fingerprint(&fp);
        assert_eq!(
            works.len(),
            2,
            "both works should be found for shared content"
        );
        assert!(works.contains(&10));
        assert!(works.contains(&20));
    }

    #[test]
    fn incremental_update_cleans_fingerprint_index() {
        let mut engine = BackfollowEngine::new();
        let elem = RangeElement::text("unique text");
        let edition = Edition::from_one(0, elem.clone());
        let work = Work::new(1, edition.clone());
        engine.register_work(&work, 1, None);

        let fp = elem.content_fingerprint();
        assert_eq!(engine.find_works_by_fingerprint(&fp).len(), 1);

        let new_elem = RangeElement::text("different text");
        let new_edition = Edition::from_one(0, new_elem);
        let updated_work = Work::new(1, new_edition);
        engine.update_work(1, &edition, &updated_work);

        assert!(
            engine.find_works_by_fingerprint(&fp).is_empty(),
            "old fingerprint should be removed"
        );
    }

    #[test]
    fn unregister_edition_cleans_index() {
        let mut engine = BackfollowEngine::new();
        let elem = RangeElement::text("test content");
        let edition = Edition::from_one(0, elem.clone());
        let prop = BertProp::new(vec![], vec![], false, false);
        engine.register_edition(&edition, 1, prop);

        let q = TransclusionQuery::all();
        assert!(!engine.find_transcluders(&elem, &q).is_empty());

        engine.unregister_edition(1, &edition);
        assert!(
            engine.find_transcluders(&elem, &q).is_empty(),
            "unregistered edition should be removed from index"
        );
    }

    #[test]
    fn register_work_with_prop_sets_h_crum() {
        crate::edition::init_endorsement_flags();
        let mut engine = BackfollowEngine::new();
        let work = Work::new(1, Edition::from_text("hello"));
        let prop = BertProp::make();
        engine.register_work_with_prop(&work, 1, None, prop);

        let meta = engine.get_edition_meta(1).unwrap();
        assert!(
            meta.h_crum().is_some(),
            "register_work_with_prop should set h_crum"
        );
        assert!(
            meta.trace_position().is_some(),
            "register_work_with_prop should set trace_position"
        );
    }

    #[test]
    fn compute_work_endorsements_detects_text() {
        let work = Work::new(1, Edition::from_text("hello"));
        let endorsements = BackfollowEngine::compute_work_endorsements(&work);
        assert!(
            !endorsements.is_empty(),
            "text work should have endorsements"
        );
        assert!(
            endorsements.iter().any(|id| id.number == TEXT_TOKEN as i64),
            "text work should have TEXT_TOKEN endorsement"
        );
    }

    #[test]
    fn compute_work_endorsements_empty_work() {
        let work = Work::new(1, Edition::empty());
        let endorsements = BackfollowEngine::compute_work_endorsements(&work);
        assert!(
            !endorsements.is_empty(),
            "empty work should still have content-type endorsements"
        );
        assert!(
            endorsements.iter().any(|id| id.number == TEXT_TOKEN as i64),
            "empty work should have TEXT_TOKEN (empty text is valid text)"
        );
    }

    #[test]
    fn make_work_prop_includes_permissions_and_endorsements() {
        let work = Work::new(1, Edition::from_text("hello"));
        let prop = BackfollowEngine::make_work_prop(&work, Some(42), Some(43));
        assert!(
            !prop.permissions().is_empty(),
            "prop should have permissions"
        );
        assert!(
            !prop.endorsements().is_empty(),
            "prop should have endorsements"
        );
        let flags = prop.flags();
        assert_ne!(flags, 0, "prop should have non-zero flags");
    }

    #[test]
    fn update_work_with_parent_creates_h_tree_edge() {
        crate::edition::init_endorsement_flags();
        let mut engine = BackfollowEngine::new();
        let ed1 = Edition::from_one(0, RangeElement::text("v1"));
        let work = Work::new(1, ed1.clone());
        let prop = BackfollowEngine::make_work_prop(&work, None, None);
        engine.register_work_with_prop(&work, 1, None, prop);

        let v2 = Work::new(1, Edition::from_one(0, RangeElement::text("v2")));
        engine.update_work_with_parent(1, 1, &ed1, &v2);

        let meta = engine.get_edition_meta(1).unwrap();
        assert!(meta.h_crum().is_some(), "updated work should have h_crum");
        let hc = meta
            .h_crum()
            .unwrap()
            .lock()
            .unwrap_or_else(|e| e.into_inner());
        assert!(
            !hc.o_parents().is_empty(),
            "updated work should have o_parents linking to previous version"
        );
    }

    #[test]
    fn find_transcluders_with_backfollow_returns_trail() {
        crate::edition::init_endorsement_flags();
        let mut engine = BackfollowEngine::new();
        let shared = RangeElement::text("X");
        let work_a = Work::new(1, Edition::from_one(0, shared.clone()));
        let prop_a = BackfollowEngine::make_work_prop(&work_a, None, None);
        engine.register_work_with_prop(&work_a, 1, None, prop_a);

        let work_b = Work::new(2, Edition::from_one(0, shared.clone()));
        let prop_b = BackfollowEngine::make_work_prop(&work_b, None, None);
        engine.register_work_with_prop(&work_b, 2, None, prop_b);

        let q = TransclusionQuery::all();
        let results = engine.find_transcluders_with_backfollow(&shared, &q);
        assert!(
            !results.is_empty(),
            "should find transcluders via backfollow"
        );
    }

    #[test]
    fn dagwood_trace_positions_are_ordered() {
        crate::edition::init_endorsement_flags();
        let mut engine = BackfollowEngine::new();
        let ed1 = Edition::from_one(0, RangeElement::text("v1"));
        let work = Work::new(1, ed1.clone());
        let prop = BackfollowEngine::make_work_prop(&work, None, None);
        engine.register_work_with_prop(&work, 1, None, prop);

        let tp1 = engine.trace_position_of(1).unwrap();

        let v2 = Work::new(1, Edition::from_one(0, RangeElement::text("v2")));
        engine.update_work_with_parent(1, 1, &ed1, &v2);
        let tp2 = engine.trace_position_of(1).unwrap();

        assert_eq!(
            engine.version_is_le(1, 1),
            Some(true),
            "a version should be <= itself"
        );
        assert_ne!(
            tp1, tp2,
            "different versions should have different trace positions"
        );
    }

    #[test]
    fn version_ancestors_across_different_works() {
        crate::edition::init_endorsement_flags();
        let mut engine = BackfollowEngine::new();
        let work_a = Work::new(1, Edition::from_one(0, RangeElement::text("A")));
        let prop_a = BackfollowEngine::make_work_prop(&work_a, None, None);
        engine.register_work_with_prop(&work_a, 1, None, prop_a);

        let ancestors_a = engine.version_ancestors(1);
        assert!(
            ancestors_a.is_empty(),
            "work with no parent has no ancestors"
        );

        let work_b = Work::new(2, Edition::from_one(0, RangeElement::text("B")));
        let prop_b = BackfollowEngine::make_work_prop(&work_b, None, None);
        engine.register_work_with_prop(&work_b, 2, None, prop_b);

        let ancestors_b = engine.version_ancestors(2);
        assert!(
            ancestors_b.is_empty(),
            "work with no parent has no ancestors"
        );

        assert_eq!(
            engine.version_is_le(1, 2),
            Some(false),
            "unrelated works should not be ordered"
        );
        assert_eq!(
            engine.version_is_le(2, 1),
            Some(false),
            "unrelated works should not be ordered"
        );
    }

    #[test]
    fn stress_many_revisions_with_backfollow() {
        crate::edition::init_endorsement_flags();
        let mut engine = BackfollowEngine::new();
        let ed0 = Edition::from_one(0, RangeElement::text("v0"));
        let work = Work::new(1, ed0.clone());
        let prop = BackfollowEngine::make_work_prop(&work, None, None);
        engine.register_work_with_prop(&work, 1, None, prop);

        let mut old_edition = ed0;
        for i in 1..=200 {
            let text = format!("v{}", i);
            let new_work = Work::new(1, Edition::from_one(0, RangeElement::text(&text)));
            let new_edition = new_work.current_edition().clone();
            engine.update_work_with_parent(1, 1, &old_edition, &new_work);
            old_edition = new_edition;

            let content = RangeElement::text(&text);
            let query = TransclusionQuery::all();
            let _results = engine.find_transcluders_with_backfollow(&content, &query);
        }
    }

    #[test]
    fn edition_to_assertions_maps_text() {
        use crate::ent::content::AssertionPayload;
        let edition = Edition::from_text("hello");
        let mut dagwood = DagWood::new();
        let tp = dagwood.new_position();
        let assertions = edition_to_assertions(1, &edition, tp);
        assert!(!assertions.is_empty());
        let has_create_node = assertions
            .iter()
            .any(|a| matches!(a.payload, AssertionPayload::CreateNode { .. }));
        assert!(has_create_node, "should have CreateNode assertion");
        let has_set_span = assertions
            .iter()
            .any(|a| matches!(a.payload, AssertionPayload::SetSpanText { .. }));
        assert!(has_set_span, "should have SetSpanText assertion");
    }

    #[test]
    fn register_link_content_creates_hyperlink_endorsement() {
        crate::edition::init_endorsement_flags();
        let mut engine = BackfollowEngine::new();
        let o_ref = HyperRef::single(Some(Edition::from_text("excerpt")), None, None, None);
        let d_ref = HyperRef::single(None, None, None, None);
        let link = HyperLink::make(vec![], o_ref, d_ref);
        engine.register_link_content(&link, 100);
        let meta = engine.get_edition_meta(100);
        assert!(meta.is_some(), "link should get an EditionMeta");
        let prop = meta.unwrap().prop();
        assert!(
            !prop.endorsements().is_empty(),
            "link should have HYPERLINK endorsement"
        );
    }

    /// FR-50 finding 5 armor: removal is by bookkeeping + label
    /// identity, not content equality. Links sharing content keys
    /// must not disturb each other's registrations.
    #[test]
    fn unregister_link_preserves_other_links_sharing_content() {
        crate::edition::init_endorsement_flags();
        use crate::edition::transclusion::TransclusionQuery;
        let mut engine = BackfollowEngine::new();
        let excerpt = Some(Edition::from_text("shared excerpt body"));
        let o1 = HyperRef::single(excerpt.clone(), None, None, None);
        let o2 = HyperRef::single(excerpt, None, None, None);
        let d = HyperRef::single(None, None, None, None);
        let link1 = HyperLink::make(vec![], o1, d.clone());
        let link2 = HyperLink::make(vec![], o2, d);
        engine.register_link_content(&link1, 101);
        engine.register_link_content(&link2, 102);

        // from_text segments one entry per character; probe a single char
        // that appears in the excerpt — its content key holds one
        // entry per registrant.
        let probe = RangeElement::text("s");
        let query = TransclusionQuery::all();
        let label_count = |engine: &BackfollowEngine, id: u64| {
            engine
                .transclusion_index()
                .find_transcluders(&probe, &query)
                .iter()
                .filter(|r| matches!(&r.element, RangeElement::Label { label_id, .. } if label_id.0 == id))
                .count()
        };
        assert_eq!(label_count(&engine, 101), 1, "link 101 registered");
        assert_eq!(label_count(&engine, 102), 1, "link 102 registered");

        engine.unregister_link_content(&link1, 101);
        assert_eq!(label_count(&engine, 101), 0, "link 101 entries removed");
        assert_eq!(
            label_count(&engine, 102),
            1,
            "link 102 must survive link 101's removal — shared keys, distinct labels"
        );
        assert!(engine.get_edition_meta(102).is_some());
    }

    #[test]
    fn unregister_link_content_removes_meta() {
        crate::edition::init_endorsement_flags();
        let mut engine = BackfollowEngine::new();
        let o_ref = HyperRef::single(Some(Edition::from_text("excerpt")), None, None, None);
        let d_ref = HyperRef::single(None, None, None, None);
        let link = HyperLink::make(vec![], o_ref, d_ref);
        engine.register_link_content(&link, 100);
        assert!(engine.get_edition_meta(100).is_some());
        engine.unregister_link_content(&link, 100);
        assert!(
            engine.get_edition_meta(100).is_none(),
            "unregister should remove link EditionMeta"
        );
    }

    #[test]
    fn update_work_with_parent_recomputes_endorsements() {
        crate::edition::init_endorsement_flags();
        let mut engine = BackfollowEngine::new();
        let ed1 = Edition::from_one(0, RangeElement::text("v1"));
        let work = Work::new(1, ed1.clone());
        let prop = BackfollowEngine::make_work_prop(&work, None, None);
        engine.register_work_with_prop(&work, 1, None, prop);

        let v2 = Work::new(1, Edition::from_one(0, RangeElement::text("v2")));
        engine.update_work_with_parent(1, 1, &ed1, &v2);

        let meta = engine.get_edition_meta(1).unwrap();
        let endorsements = meta.prop().endorsements();
        assert!(
            !endorsements.is_empty(),
            "updated work should have recomputed endorsements"
        );
        assert!(
            endorsements.iter().any(|id| id.number == TEXT_TOKEN as i64),
            "updated work should have TEXT_TOKEN"
        );
    }

    #[test]
    fn find_transcluders_with_permission_filter() {
        crate::edition::init_endorsement_flags();
        let mut engine = BackfollowEngine::new();
        let shared = RangeElement::text("shared");

        let club_a: u64 = 100;
        let work_a = Work::new(1, Edition::from_one(0, shared.clone()));
        let prop_a = BackfollowEngine::make_work_prop(&work_a, Some(club_a), Some(club_a));
        engine.register_work_with_prop(&work_a, 1, None, prop_a);

        let club_b: u64 = 200;
        let work_b = Work::new(2, Edition::from_one(0, shared.clone()));
        let prop_b = BackfollowEngine::make_work_prop(&work_b, Some(club_b), Some(club_b));
        engine.register_work_with_prop(&work_b, 2, None, prop_b);

        let q_all = TransclusionQuery::all();
        let all_results = engine.find_transcluders(&shared, &q_all);
        assert!(all_results.len() >= 2, "unfiltered should find both works");

        let perm_region = crate::edition::props::permissions_region(&[club_a]);
        let q_filtered = TransclusionQuery::all()
            .with_permissions(crate::edition::props::FilterRegion::new(perm_region));
        let filtered_results = engine.find_transcluders(&shared, &q_filtered);
        assert!(
            !filtered_results.is_empty(),
            "filtered should find at least one result"
        );
    }
}
