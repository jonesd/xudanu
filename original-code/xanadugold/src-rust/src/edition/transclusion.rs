use std::collections::HashSet;

use super::edition::Edition;
use super::grandmap::Id;
use super::range_element::RangeElement;
use super::xn_region::XnRegion;
use crate::edition::props::FilterRegion;

#[derive(Debug, Clone)]
pub struct TransclusionResult {
    pub element: RangeElement,
    pub is_direct: bool,
}

#[derive(Debug)]
pub struct TrailBlazer {
    trail: Edition,
    recorded: HashSet<u64>,
    next_id: u64,
}

impl TrailBlazer {
    pub fn new() -> Self {
        TrailBlazer {
            trail: Edition::empty(),
            recorded: HashSet::new(),
            next_id: 0,
        }
    }

    pub fn for_edition(trail_edition: Edition) -> Self {
        TrailBlazer {
            trail: trail_edition,
            recorded: HashSet::new(),
            next_id: 0,
        }
    }

    pub fn record(&mut self, answer: &RangeElement, id_hash: u64) -> bool {
        if self.recorded.contains(&id_hash) {
            return false;
        }
        self.recorded.insert(id_hash);
        let position = self.next_id as i64;
        self.next_id += 1;
        self.trail = self.trail.clone().with(position, answer.clone());
        true
    }

    pub fn record_element(&mut self, element: &RangeElement) -> bool {
        use std::hash::{Hash, Hasher};
        let mut hasher = std::collections::hash_map::DefaultHasher::new();
        element.hash(&mut hasher);
        let id_hash = hasher.finish();
        self.record(element, id_hash)
    }

    pub fn trail(&self) -> &Edition {
        &self.trail
    }

    pub fn into_trail(self) -> Edition {
        self.trail
    }

    pub fn result_count(&self) -> usize {
        self.recorded.len()
    }

    pub fn is_empty(&self) -> bool {
        self.recorded.is_empty()
    }
}

impl Default for TrailBlazer {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(Debug, Clone)]
pub struct TransclusionQuery {
    permissions_filter: FilterRegion,
    endorsements_filter: FilterRegion,
    direct_only: bool,
}

impl TransclusionQuery {
    pub fn new(
        permissions_filter: FilterRegion,
        endorsements_filter: FilterRegion,
        direct_only: bool,
    ) -> Self {
        TransclusionQuery {
            permissions_filter,
            endorsements_filter,
            direct_only,
        }
    }

    pub fn all() -> Self {
        TransclusionQuery {
            permissions_filter: FilterRegion::full(),
            endorsements_filter: FilterRegion::full(),
            direct_only: false,
        }
    }

    pub fn direct_only() -> Self {
        TransclusionQuery {
            permissions_filter: FilterRegion::full(),
            endorsements_filter: FilterRegion::full(),
            direct_only: true,
        }
    }

    pub fn with_permissions(mut self, filter: FilterRegion) -> Self {
        self.permissions_filter = filter;
        self
    }

    pub fn with_endorsements(mut self, filter: FilterRegion) -> Self {
        self.endorsements_filter = filter;
        self
    }

    pub fn permissions_filter(&self) -> &FilterRegion {
        &self.permissions_filter
    }

    pub fn endorsements_filter(&self) -> &FilterRegion {
        &self.endorsements_filter
    }

    pub fn is_direct_only(&self) -> bool {
        self.direct_only
    }

    pub fn matches_permissions(&self, permissions: &[Id]) -> bool {
        if self.permissions_filter.is_full() {
            return true;
        }
        if self.permissions_filter.is_empty() {
            return true;
        }
        let perm_region = ids_to_region(permissions);
        self.permissions_filter.match_region(&perm_region)
    }

    pub fn matches_endorsements(&self, endorsements: &[Id]) -> bool {
        if self.endorsements_filter.is_full() {
            return true;
        }
        if self.endorsements_filter.is_empty() {
            return true;
        }
        let endo_region = ids_to_region(endorsements);
        self.endorsements_filter.match_region(&endo_region)
    }
}

fn ids_to_region(ids: &[Id]) -> XnRegion {
    let mut region = XnRegion::empty();
    for id in ids {
        region = region.with(id.number);
    }
    region
}

#[derive(Debug, Clone)]
pub struct WorkQuery {
    permissions_filter: FilterRegion,
    endorsements_filter: FilterRegion,
}

impl WorkQuery {
    pub fn new(permissions_filter: FilterRegion, endorsements_filter: FilterRegion) -> Self {
        WorkQuery {
            permissions_filter,
            endorsements_filter,
        }
    }

    pub fn all() -> Self {
        WorkQuery {
            permissions_filter: FilterRegion::full(),
            endorsements_filter: FilterRegion::full(),
        }
    }

    pub fn matches_permissions(&self, permissions: &[Id]) -> bool {
        if self.permissions_filter.is_full() || self.permissions_filter.is_empty() {
            return true;
        }
        let perm_region = ids_to_region(permissions);
        self.permissions_filter.match_region(&perm_region)
    }

    pub fn matches_endorsements(&self, endorsements: &[Id]) -> bool {
        if self.endorsements_filter.is_full() || self.endorsements_filter.is_empty() {
            return true;
        }
        let endo_region = ids_to_region(endorsements);
        self.endorsements_filter.match_region(&endo_region)
    }
}

#[derive(Debug, Clone)]
pub struct FederatedTransclusionResult {
    pub origin_server_id: String,
    pub local_id: u64,
    pub element_type: String,
    pub is_direct: bool,
}

#[derive(Debug)]
pub struct TransclusionIndex {
    content_to_editions: std::collections::HashMap<String, Vec<(RangeElement, bool)>>,
    federated_entries: std::collections::HashMap<String, Vec<FederatedTransclusionResult>>,
}

impl TransclusionIndex {
    pub fn new() -> Self {
        TransclusionIndex {
            content_to_editions: std::collections::HashMap::new(),
            federated_entries: std::collections::HashMap::new(),
        }
    }

    /// Register a single element under its content key without
    /// building a one-element Edition (the link-content hot path —
    /// FR-50 finding 5: per-link per-keystroke registration used to
    /// allocate an orgl per element).
    pub fn register_element(&mut self, element: &RangeElement, owner: &RangeElement) {
        let key = element_key(element);
        self.content_to_editions
            .entry(key)
            .or_default()
            .push((owner.clone(), true));
    }

    /// Remove a link's label entries from a content key WITHOUT
    /// content equality: the label_id identifies the registrant.
    pub fn remove_link_entries(&mut self, key: &str, link_id: u64) {
        if let Some(vec) = self.content_to_editions.get_mut(key) {
            vec.retain(|(elem, _)| !is_link_label_of(elem, link_id));
            if vec.is_empty() {
                self.content_to_editions.remove(key);
            }
        }
    }

    pub fn register_edition(
        &mut self,
        edition: &Edition,
        edition_element: &RangeElement,
        region: Option<&XnRegion>,
    ) {
        let search_region = region.cloned().unwrap_or_else(|| XnRegion::full());
        let entries = edition.fetch_range(&search_region);
        for (_pos, carrier) in &entries {
            let key = element_key(&carrier.element);
            let is_direct = true;
            self.content_to_editions
                .entry(key)
                .or_default()
                .push((edition_element.clone(), is_direct));
        }
    }

    pub fn register_work(&mut self, edition: &Edition, work_element: &RangeElement) {
        let entries = edition.fetch_all();
        for (_pos, carrier) in &entries {
            let key = element_key(&carrier.element);
            self.content_to_editions
                .entry(key)
                .or_default()
                .push((work_element.clone(), true));
        }
    }

    pub fn find_transcluders(
        &self,
        content: &RangeElement,
        query: &TransclusionQuery,
    ) -> Vec<TransclusionResult> {
        let key = element_key(content);
        let mut results = Vec::new();
        if let Some(editions) = self.content_to_editions.get(&key) {
            for (element, is_direct) in editions {
                if *is_direct || !query.is_direct_only() {
                    results.push(TransclusionResult {
                        element: element.clone(),
                        is_direct: *is_direct,
                    });
                }
            }
        }
        results
    }

    pub fn find_works(&self, content: &RangeElement, _query: &WorkQuery) -> Vec<RangeElement> {
        let key = element_key(content);
        let mut results = Vec::new();
        if let Some(entries) = self.content_to_editions.get(&key) {
            for (element, _) in entries {
                results.push(element.clone());
            }
        }
        results
    }

    pub fn register_federated(
        &mut self,
        content: &RangeElement,
        origin_server_id: String,
        local_id: u64,
        element_type: String,
        is_direct: bool,
    ) {
        let key = element_key(content);
        self.federated_entries
            .entry(key)
            .or_default()
            .push(FederatedTransclusionResult {
                origin_server_id,
                local_id,
                element_type,
                is_direct,
            });
    }

    pub fn find_federated_transcluders(
        &self,
        content: &RangeElement,
    ) -> Vec<&FederatedTransclusionResult> {
        let key = element_key(content);
        self.federated_entries
            .get(&key)
            .map(|entries| entries.iter().collect())
            .unwrap_or_default()
    }

    pub fn find_by_fingerprint_hex(&self, fingerprint_hex: &str) -> Vec<(&RangeElement, bool)> {
        self.content_to_editions
            .get(fingerprint_hex)
            .map(|entries| entries.iter().map(|(e, d)| (e, *d)).collect())
            .unwrap_or_default()
    }

    pub fn find_federated_by_hex(
        &self,
        fingerprint_hex: &str,
    ) -> Vec<&FederatedTransclusionResult> {
        self.federated_entries
            .get(fingerprint_hex)
            .map(|entries| entries.iter().collect())
            .unwrap_or_default()
    }

    pub fn has_federated_entries(&self) -> bool {
        !self.federated_entries.is_empty()
    }

    pub fn federated_entry_count(&self) -> usize {
        self.federated_entries.values().map(|v| v.len()).sum()
    }

    pub fn unregister_edition(
        &mut self,
        edition: &Edition,
        edition_element: &RangeElement,
        region: Option<&XnRegion>,
    ) {
        let search_region = region.cloned().unwrap_or_else(|| XnRegion::full());
        let entries = edition.fetch_range(&search_region);
        for (_pos, carrier) in &entries {
            let key = element_key(&carrier.element);
            if let Some(vec) = self.content_to_editions.get_mut(&key) {
                vec.retain(|(elem, _)| elem != edition_element);
                if vec.is_empty() {
                    self.content_to_editions.remove(&key);
                }
            }
        }
    }

    pub fn unregister_work(&mut self, edition: &Edition, work_element: &RangeElement) {
        let entries = edition.fetch_all();
        for (_pos, carrier) in &entries {
            let key = element_key(&carrier.element);
            if let Some(vec) = self.content_to_editions.get_mut(&key) {
                vec.retain(|(elem, _)| elem != work_element);
                if vec.is_empty() {
                    self.content_to_editions.remove(&key);
                }
            }
        }
    }

    pub fn clear(&mut self) {
        self.content_to_editions.clear();
        self.federated_entries.clear();
    }
}

impl Default for TransclusionIndex {
    fn default() -> Self {
        Self::new()
    }
}

/// A link's registration token: label(link_id, text("link")). Only
/// link registration creates labels with link ids, so label_id alone
/// identifies the registrant — no content comparison needed.
fn is_link_label_of(elem: &RangeElement, link_id: u64) -> bool {
    matches!(
        elem,
        RangeElement::Label { label_id, .. } if label_id.0 == link_id
    )
}

pub fn element_key(element: &RangeElement) -> String {
    let fp = element.content_fingerprint();
    fp.iter().map(|b| format!("{:02x}", b)).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn trail_blazer_empty() {
        let tb = TrailBlazer::new();
        assert!(tb.is_empty());
        assert_eq!(tb.result_count(), 0);
    }

    #[test]
    fn trail_blazer_record() {
        let mut tb = TrailBlazer::new();
        let e = RangeElement::text("hello");
        assert!(tb.record_element(&e));
        assert_eq!(tb.result_count(), 1);
        assert!(!tb.is_empty());
    }

    #[test]
    fn trail_blazer_deduplicates() {
        let mut tb = TrailBlazer::new();
        let e = RangeElement::text("hello");
        assert!(tb.record_element(&e));
        assert!(!tb.record_element(&e));
        assert_eq!(tb.result_count(), 1);
    }

    #[test]
    fn trail_blazer_trail_edition() {
        let mut tb = TrailBlazer::new();
        let e = RangeElement::text("hello");
        tb.record_element(&e);
        let trail = tb.into_trail();
        assert!(!trail.is_empty());
    }

    #[test]
    fn trail_blazer_records_different_elements() {
        let mut tb = TrailBlazer::new();
        let e1 = RangeElement::text("hello");
        let e2 = RangeElement::text("world");
        assert!(tb.record_element(&e1));
        assert!(tb.record_element(&e2));
        assert_eq!(tb.result_count(), 2);
    }

    #[test]
    fn transclusion_query_all() {
        let q = TransclusionQuery::all();
        assert!(!q.is_direct_only());
        assert!(q.matches_permissions(&[]));
        assert!(q.matches_endorsements(&[]));
    }

    #[test]
    fn transclusion_query_direct_only() {
        let q = TransclusionQuery::direct_only();
        assert!(q.is_direct_only());
    }

    #[test]
    fn transclusion_query_with_permissions_filter() {
        let q = TransclusionQuery::all()
            .with_permissions(FilterRegion::new(XnRegion::interval(0, 100)));
        assert!(q.matches_permissions(&[Id::global(50)]));
        assert!(!q.matches_permissions(&[Id::global(200)]));
    }

    #[test]
    fn transclusion_index_empty() {
        let idx = TransclusionIndex::new();
        let q = TransclusionQuery::all();
        let results = idx.find_transcluders(&RangeElement::text("hello"), &q);
        assert!(results.is_empty());
    }

    #[test]
    fn transclusion_index_register_and_find() {
        let mut idx = TransclusionIndex::new();
        let edition = Edition::from_one(0, RangeElement::text("hello"));
        let edition_elem = RangeElement::edition(42);
        idx.register_edition(&edition, &edition_elem, None);

        let q = TransclusionQuery::all();
        let results = idx.find_transcluders(&RangeElement::text("hello"), &q);
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].element, edition_elem);
        assert!(results[0].is_direct);
    }

    #[test]
    fn transclusion_index_direct_only_filter() {
        let mut idx = TransclusionIndex::new();
        let edition = Edition::from_one(0, RangeElement::text("hello"));
        let edition_elem = RangeElement::edition(42);
        idx.register_edition(&edition, &edition_elem, None);

        let q = TransclusionQuery::direct_only();
        let results = idx.find_transcluders(&RangeElement::text("hello"), &q);
        assert_eq!(results.len(), 1);
    }

    #[test]
    fn transclusion_index_no_match() {
        let mut idx = TransclusionIndex::new();
        let edition = Edition::from_one(0, RangeElement::text("hello"));
        let edition_elem = RangeElement::edition(42);
        idx.register_edition(&edition, &edition_elem, None);

        let q = TransclusionQuery::all();
        let results = idx.find_transcluders(&RangeElement::text("goodbye"), &q);
        assert!(results.is_empty());
    }

    #[test]
    fn transclusion_index_multiple_editions() {
        let mut idx = TransclusionIndex::new();
        let edition1 = Edition::from_one(0, RangeElement::text("hello"));
        let edition2 = Edition::from_one(0, RangeElement::text("hello"));
        idx.register_edition(&edition1, &RangeElement::edition(1), None);
        idx.register_edition(&edition2, &RangeElement::edition(2), None);

        let q = TransclusionQuery::all();
        let results = idx.find_transcluders(&RangeElement::text("hello"), &q);
        assert_eq!(results.len(), 2);
    }

    #[test]
    fn transclusion_index_register_work() {
        let mut idx = TransclusionIndex::new();
        let edition = Edition::from_one(0, RangeElement::text("hello"));
        let work_elem = RangeElement::work(99);
        idx.register_work(&edition, &work_elem);

        let q = WorkQuery::all();
        let results = idx.find_works(&RangeElement::text("hello"), &q);
        assert_eq!(results.len(), 1);
        assert_eq!(results[0], work_elem);
    }

    #[test]
    fn transclusion_index_clear() {
        let mut idx = TransclusionIndex::new();
        let edition = Edition::from_text("hello");
        idx.register_edition(&edition, &RangeElement::edition(1), None);
        idx.clear();
        let q = TransclusionQuery::all();
        let results = idx.find_transcluders(&RangeElement::text("hello"), &q);
        assert!(results.is_empty());
    }

    #[test]
    fn transclusion_index_register_with_region() {
        let mut idx = TransclusionIndex::new();
        let mut edition = Edition::empty();
        edition = edition.with(0, RangeElement::text("a"));
        edition = edition.with(1, RangeElement::text("b"));
        edition = edition.with(2, RangeElement::text("c"));

        let edition_elem = RangeElement::edition(1);
        idx.register_edition(&edition, &edition_elem, Some(&XnRegion::interval(0, 2)));

        let q = TransclusionQuery::all();
        let results_a = idx.find_transcluders(&RangeElement::text("a"), &q);
        assert_eq!(results_a.len(), 1);
        let results_c = idx.find_transcluders(&RangeElement::text("c"), &q);
        assert!(results_c.is_empty());
    }

    #[test]
    fn element_key_deterministic() {
        let e = RangeElement::text("hello");
        let k1 = element_key(&e);
        let k2 = element_key(&e);
        assert_eq!(k1, k2);
    }

    #[test]
    fn element_key_different_for_different_content() {
        let e1 = RangeElement::text("hello");
        let e2 = RangeElement::text("world");
        assert_ne!(element_key(&e1), element_key(&e2));
    }

    #[test]
    fn federated_register_and_find() {
        let mut idx = TransclusionIndex::new();
        let content = RangeElement::text("shared content");
        idx.register_federated(
            &content,
            "server-a".to_string(),
            42,
            "work".to_string(),
            true,
        );
        assert!(idx.has_federated_entries());
        assert_eq!(idx.federated_entry_count(), 1);

        let results = idx.find_federated_transcluders(&content);
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].origin_server_id, "server-a");
        assert_eq!(results[0].local_id, 42);
        assert!(results[0].is_direct);
    }

    #[test]
    fn federated_find_no_match() {
        let mut idx = TransclusionIndex::new();
        idx.register_federated(
            &RangeElement::text("hello"),
            "server-a".to_string(),
            1,
            "work".to_string(),
            true,
        );
        let results = idx.find_federated_transcluders(&RangeElement::text("goodbye"));
        assert!(results.is_empty());
    }

    #[test]
    fn federated_multiple_entries_for_same_content() {
        let mut idx = TransclusionIndex::new();
        let content = RangeElement::text("shared");
        idx.register_federated(
            &content,
            "server-a".to_string(),
            1,
            "work".to_string(),
            true,
        );
        idx.register_federated(
            &content,
            "server-b".to_string(),
            2,
            "edition".to_string(),
            true,
        );
        idx.register_federated(
            &content,
            "server-c".to_string(),
            3,
            "work".to_string(),
            false,
        );

        let results = idx.find_federated_transcluders(&content);
        assert_eq!(results.len(), 3);
        assert_eq!(idx.federated_entry_count(), 3);
    }

    #[test]
    fn federated_clear_clears_both_indexes() {
        let mut idx = TransclusionIndex::new();
        let edition = Edition::from_one(0, RangeElement::text("hello"));
        idx.register_edition(&edition, &RangeElement::edition(1), None);
        idx.register_federated(
            &RangeElement::text("hello"),
            "remote".to_string(),
            10,
            "work".to_string(),
            true,
        );

        let q = TransclusionQuery::all();
        assert_eq!(
            idx.find_transcluders(&RangeElement::text("hello"), &q)
                .len(),
            1
        );
        assert_eq!(
            idx.find_federated_transcluders(&RangeElement::text("hello"))
                .len(),
            1
        );

        idx.clear();
        assert!(idx
            .find_transcluders(&RangeElement::text("hello"), &q)
            .is_empty());
        assert!(idx
            .find_federated_transcluders(&RangeElement::text("hello"))
            .is_empty());
        assert!(!idx.has_federated_entries());
    }

    #[test]
    fn federated_same_fingerprint_as_local() {
        let mut idx = TransclusionIndex::new();
        let content = RangeElement::text("hello");
        let edition = Edition::from_one(0, content.clone());
        idx.register_edition(&edition, &RangeElement::edition(1), None);
        idx.register_federated(
            &content,
            "remote".to_string(),
            99,
            "edition".to_string(),
            true,
        );

        let q = TransclusionQuery::all();
        let local = idx.find_transcluders(&content, &q);
        let fed = idx.find_federated_transcluders(&content);
        assert_eq!(local.len(), 1);
        assert_eq!(fed.len(), 1);
    }

    #[test]
    fn unregister_edition_removes_entries() {
        let mut idx = TransclusionIndex::new();
        let edition = Edition::from_one(0, RangeElement::text("hello"));
        let elem = RangeElement::edition(1);
        idx.register_edition(&edition, &elem, None);

        let q = TransclusionQuery::all();
        assert_eq!(
            idx.find_transcluders(&RangeElement::text("hello"), &q)
                .len(),
            1
        );

        idx.unregister_edition(&edition, &elem, None);
        assert!(idx
            .find_transcluders(&RangeElement::text("hello"), &q)
            .is_empty());
    }

    #[test]
    fn unregister_edition_preserves_other_editions() {
        let mut idx = TransclusionIndex::new();
        let edition_a = Edition::from_one(0, RangeElement::text("hello"));
        let edition_b = Edition::from_one(0, RangeElement::text("hello"));
        let elem_a = RangeElement::edition(1);
        let elem_b = RangeElement::edition(2);
        idx.register_edition(&edition_a, &elem_a, None);
        idx.register_edition(&edition_b, &elem_b, None);

        let q = TransclusionQuery::all();
        assert_eq!(
            idx.find_transcluders(&RangeElement::text("hello"), &q)
                .len(),
            2
        );

        idx.unregister_edition(&edition_a, &elem_a, None);
        let results = idx.find_transcluders(&RangeElement::text("hello"), &q);
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].element, elem_b);
    }

    #[test]
    fn unregister_work_removes_entries() {
        let mut idx = TransclusionIndex::new();
        let edition = Edition::from_one(0, RangeElement::text("hello"));
        let elem = RangeElement::work(42);
        idx.register_work(&edition, &elem);

        let q = WorkQuery::all();
        assert_eq!(idx.find_works(&RangeElement::text("hello"), &q).len(), 1);

        idx.unregister_work(&edition, &elem);
        assert!(idx.find_works(&RangeElement::text("hello"), &q).is_empty());
    }

    #[test]
    fn unregister_work_preserves_other_works() {
        let mut idx = TransclusionIndex::new();
        let edition = Edition::from_one(0, RangeElement::text("hello"));
        let elem_a = RangeElement::work(10);
        let elem_b = RangeElement::work(20);
        idx.register_work(&edition, &elem_a);
        idx.register_work(&edition, &elem_b);

        let q = WorkQuery::all();
        assert_eq!(idx.find_works(&RangeElement::text("hello"), &q).len(), 2);

        idx.unregister_work(&edition, &elem_a);
        let results = idx.find_works(&RangeElement::text("hello"), &q);
        assert_eq!(results.len(), 1);
        assert_eq!(results[0], elem_b);
    }
}
