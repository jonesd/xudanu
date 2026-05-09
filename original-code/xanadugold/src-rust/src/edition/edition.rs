use std::collections::BTreeMap;
use std::sync::Arc;
use std::sync::OnceLock;

use super::bundle::{
    Bundle, CostMethod, RetrieveFlags, StorageCost,
    retrieve_bundles, compute_storage_cost, element_byte_size, fingerprint_u64,
};
use super::orgl::OrglRoot;
use super::range_element::{Carrier, RangeElement};
use super::shared_mapping::{SharedMapping, content_shared_region, content_map_shared_to, content_map_shared_onto};
use super::xn_region::XnRegion;
use super::endorsement::EndorsementSet;

#[derive(Debug, Clone)]
pub struct Edition {
    pub(crate) orgl: OrglRoot,
    pub(crate) endorsements: EndorsementSet,
    #[allow(dead_code)]
    pub(crate) entries_cache: Arc<OnceLock<Vec<(i64, Arc<Carrier>)>>>,
}

impl Edition {
    pub(crate) fn new_inner(orgl: OrglRoot, endorsements: EndorsementSet) -> Self {
        Edition { orgl, endorsements, entries_cache: Arc::new(OnceLock::new()) }
    }
}

impl PartialEq for Edition {
    fn eq(&self, other: &Self) -> bool {
        if self.orgl.count() != other.orgl.count() {
            return false;
        }
        let my_entries = self.orgl.all_entries();
        let other_entries = other.orgl.all_entries();
        if my_entries.len() != other_entries.len() {
            return false;
        }
        for (a, b) in my_entries.iter().zip(other_entries.iter()) {
            if a.0 != b.0 || *a.1 != *b.1 {
                return false;
            }
        }
        true
    }
}
impl Edition {

    pub fn cached_entries(&self) -> &Vec<(i64, Arc<Carrier>)> {
        self.entries_cache.get_or_init(|| self.orgl.all_entries())
    }

    pub fn empty() -> Self {
        Edition {
            orgl: OrglRoot::empty(),
            endorsements: EndorsementSet::new(),
            entries_cache: Arc::new(OnceLock::new()),
        }
    }

    pub fn from_one(position: i64, value: RangeElement) -> Self {
        let orgl = OrglRoot::empty().with(position, Arc::new(Carrier::new(value)));
        Edition { orgl, endorsements: EndorsementSet::new(), entries_cache: Arc::new(OnceLock::new()) }
    }

    pub fn from_all(region: &XnRegion, value: RangeElement) -> Self {
        if !region.is_finite() {
            let orgl = OrglRoot::with_default(region.clone(), Arc::new(Carrier::new(value)));
            return Edition { orgl, endorsements: EndorsementSet::new(), entries_cache: Arc::new(OnceLock::new()) };
        }
        let mut orgl = OrglRoot::empty();
        for (start, stop) in region.intervals() {
            for pos in start..stop {
                orgl = orgl.with(pos, Arc::new(Carrier::new(value.clone())));
            }
        }
        Edition { orgl, endorsements: EndorsementSet::new(), entries_cache: Arc::new(OnceLock::new()) }
    }

    pub fn from_text(text: &str) -> Self {
        let entries: Vec<(i64, Arc<Carrier>)> = text.chars().enumerate()
            .map(|(i, ch)| {
                let mut buf = [0u8; 4];
                let s = ch.encode_utf8(&mut buf);
                (i as i64, Arc::new(Carrier::new(RangeElement::text(s.to_string()))))
            })
            .collect();
        let n = entries.len();
        let region = if n > 0 { XnRegion::interval(0, n as i64) } else { XnRegion::empty() };
        Edition { orgl: OrglRoot::from_bulk_entries(entries, None, region), endorsements: EndorsementSet::new(), entries_cache: Arc::new(OnceLock::new()) }
    }

    pub fn from_text_elements(elements: &[RangeElement]) -> Self {
        let entries: Vec<(i64, Arc<Carrier>)> = elements.iter().enumerate()
            .map(|(i, e)| (i as i64, Arc::new(Carrier::new(e.clone()))))
            .collect();
        let n = entries.len();
        let region = if n > 0 { XnRegion::interval(0, n as i64) } else { XnRegion::empty() };
        Edition { orgl: OrglRoot::from_bulk_entries(entries, None, region), endorsements: EndorsementSet::new(), entries_cache: Arc::new(OnceLock::new()) }
    }

    pub fn place_holders(region: &XnRegion) -> Self {
        let mut next_id = 0u64;
        let mut entries = Vec::new();
        for (start, stop) in region.intervals() {
            for pos in start..stop {
                entries.push((pos, Arc::new(Carrier::new(RangeElement::placeholder(next_id)))));
                next_id += 1;
            }
        }
        Edition { orgl: OrglRoot::from_bulk_entries(entries, None, region.clone()), endorsements: EndorsementSet::new(), entries_cache: Arc::new(OnceLock::new()) }
    }

    pub fn with_default(region: XnRegion, value: RangeElement) -> Self {
        let orgl = OrglRoot::with_default(region, Arc::new(Carrier::new(value)));
        Edition { orgl, endorsements: EndorsementSet::new(), entries_cache: Arc::new(OnceLock::new()) }
    }

    pub fn is_empty(&self) -> bool {
        self.orgl.is_empty()
    }

    pub fn is_infinite(&self) -> bool {
        self.orgl.is_infinite()
    }

    pub fn default_value(&self) -> Option<RangeElement> {
        self.orgl.default_value()
    }

    pub fn count(&self) -> u64 {
        self.orgl.count()
    }

    pub fn is_finite(&self) -> bool {
        !self.orgl.is_infinite() && !self.orgl.is_empty()
    }

    pub fn domain(&self) -> XnRegion {
        self.orgl.domain()
    }

    pub fn fetch(&self, position: i64) -> Option<RangeElement> {
        self.orgl.fetch(position).map(|c| c.element.clone())
    }

    pub fn fetch_owned(&self, position: i64) -> Option<Arc<Carrier>> {
        self.orgl.fetch(position)
    }

    pub fn get(&self, position: i64) -> RangeElement {
        self.orgl.fetch(position).expect("position not in edition").element.clone()
    }

    pub fn get_owned(&self, position: i64) -> Arc<Carrier> {
        self.orgl.fetch(position).expect("position not in edition")
    }

    pub fn has_position(&self, position: i64) -> bool {
        self.orgl.has_position(position)
    }

    pub fn all_entries(&self) -> Vec<(i64, Arc<Carrier>)> {
        self.cached_entries().clone()
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

    pub fn with_endorsements(mut self, endorsements: EndorsementSet) -> Self {
        self.endorsements = endorsements;
        self
    }

    pub fn fetch_all(&self) -> Vec<(i64, Arc<Carrier>)> {
        self.orgl.all_entries()
    }

    pub fn fetch_range(&self, region: &XnRegion) -> Vec<(i64, Arc<Carrier>)> {
        self.orgl
            .all_entries()
            .into_iter()
            .filter(|(pos, _)| region.contains(*pos))
            .collect()
    }

    pub fn carrier_at(&self, position: i64) -> Option<Arc<Carrier>> {
        self.orgl.fetch(position)
    }

    pub fn with(&self, position: i64, value: RangeElement) -> Self {
        Edition {
            orgl: self.orgl.with(position, Arc::new(Carrier::new(value))),
            endorsements: self.endorsements.clone(),
            entries_cache: Arc::new(OnceLock::new()),
        }
    }

    pub fn with_all(&self, region: &XnRegion, value: RangeElement) -> Self {
        let mut orgl = self.orgl.clone();
        for (start, stop) in region.intervals() {
            for pos in start..stop {
                orgl = orgl.with(pos, Arc::new(Carrier::new(value.clone())));
            }
        }
        Edition { orgl, endorsements: EndorsementSet::new(), entries_cache: Arc::new(OnceLock::new()) }
    }

    pub fn without(&self, position: i64) -> Self {
        Edition {
            orgl: self.orgl.without(position),
            endorsements: self.endorsements.clone(),
            entries_cache: Arc::new(OnceLock::new()),
        }
    }

    pub fn without_all(&self, region: &XnRegion) -> Self {
        let keep_region = self.domain().minus(region);
        Edition {
            orgl: self.orgl.copy(&keep_region),
            endorsements: self.endorsements.clone(),
            entries_cache: Arc::new(OnceLock::new()),
        }
    }

    pub fn combine(&self, other: &Edition) -> Result<Edition, CombineConflict> {
        let my_entries = self.orgl.all_entries();
        let other_entries = other.orgl.all_entries();
        for (pos, carrier) in &my_entries {
            if let Some(idx) = other_entries.binary_search_by_key(pos, |(p, _)| *p).ok() {
                if *carrier != other_entries[idx].1 {
                    return Err(CombineConflict {
                        position: *pos,
                        left: carrier.element.clone(),
                        right: other_entries[idx].1.element.clone(),
                    });
                }
            }
        }
        match self.orgl.combine(&other.orgl) {
            Ok(combined) => Ok(Edition { orgl: combined, endorsements: EndorsementSet::new(), entries_cache: Arc::new(OnceLock::new()) }),
            Err(_) => {
                let mut orgl = self.orgl.clone();
                for (pos, carrier) in other_entries {
                    if !orgl.has_position(pos) {
                        orgl = orgl.with(pos, carrier);
                    }
                }
                Ok(Edition { orgl, endorsements: EndorsementSet::new(), entries_cache: Arc::new(OnceLock::new()) })
            }
        }
    }

    pub fn replace(&self, other: &Edition) -> Edition {
        Edition {
            orgl: self.orgl.replace(&other.orgl),
            endorsements: self.endorsements.clone(),
            entries_cache: Arc::new(OnceLock::new()),
        }
    }

    pub fn copy(&self, region: &XnRegion) -> Edition {
        Edition {
            orgl: self.orgl.copy(region),
            endorsements: self.endorsements.clone(),
            entries_cache: Arc::new(OnceLock::new()),
        }
    }

    pub fn transformed_by(&self, offset: i64) -> Edition {
        Edition {
            orgl: self.orgl.transformed_by(offset),
            endorsements: self.endorsements.clone(),
            entries_cache: Arc::new(OnceLock::new()),
        }
    }

    pub fn transformed_by_mapping(&self, mapping: &super::mapping::Mapping) -> Edition {
        if mapping.is_empty() {
            return Edition::empty();
        }
        if mapping.is_identity() {
            return self.clone();
        }
        let entries = self.orgl.all_entries();
        let mut new_entries: Vec<(i64, Arc<Carrier>)> = Vec::with_capacity(entries.len());
        for (pos, carrier) in &entries {
            if let Some(new_pos) = mapping.of(*pos) {
                new_entries.push((new_pos, carrier.clone()));
            }
        }
        new_entries.sort_by_key(|(p, _)| *p);
        let domain = self.domain();
        let new_domain = mapping.of_region(&domain);
        if new_entries.is_empty() {
            return Edition::empty();
        }
        Edition {
            orgl: OrglRoot::from_bulk_entries(new_entries, None, new_domain),
            endorsements: self.endorsements.clone(),
            entries_cache: Arc::new(OnceLock::new()),
        }
    }

    pub fn iter(&self) -> impl Iterator<Item = (i64, Arc<Carrier>)> {
        self.orgl.all_entries().into_iter()
    }

    pub fn entries_btreemap(&self) -> BTreeMap<i64, Carrier> {
        self.orgl
            .all_entries()
            .into_iter()
            .map(|(p, c)| (p, (*c).clone()))
            .collect()
    }

    pub fn to_text(&self) -> String {
        let mut result = String::new();
        for i in 0..self.count() as i64 {
            if let Some(carrier) = self.orgl.fetch(i) {
                if let Some(s) = carrier.element.as_text() {
                    result.push_str(s);
                }
            }
        }
        result
    }

    pub fn shared_region(&self, other: &Edition) -> XnRegion {
        self.orgl.shared_region(&other.orgl)
    }

    pub fn identity_shared_region<F>(&self, other: &Edition, id_eq: F) -> XnRegion
    where
        F: Fn(&Carrier, &Carrier) -> bool,
    {
        let my_entries = self.orgl.all_entries();
        let other_entries = other.orgl.all_entries();
        let mut region = XnRegion::empty();
        for (pos, carrier) in &my_entries {
            if let Some(idx) = other_entries.binary_search_by_key(pos, |(p, _)| *p).ok() {
                if id_eq(carrier, &other_entries[idx].1) {
                    region = region.with(*pos);
                }
            }
        }
        region
    }

    pub fn shared_with(&self, other: &Edition) -> Edition {
        let my_entries = self.orgl.all_entries();
        let other_entries = other.orgl.all_entries();
        let mut orgl = OrglRoot::empty();
        for (pos, carrier) in &my_entries {
            if let Some(idx) = other_entries.binary_search_by_key(pos, |(p, _)| *p).ok() {
                if *carrier == other_entries[idx].1 {
                    orgl = orgl.with(*pos, carrier.clone());
                }
            }
        }
        Edition { orgl, endorsements: EndorsementSet::new(), entries_cache: Arc::new(OnceLock::new()) }
    }

    pub fn not_shared_with(&self, other: &Edition) -> Edition {
        let my_entries = self.orgl.all_entries();
        let other_entries = other.orgl.all_entries();
        let mut orgl = OrglRoot::empty();
        for (pos, carrier) in &my_entries {
            let differs = match other_entries.binary_search_by_key(pos, |(p, _)| *p) {
                Ok(idx) => *carrier != other_entries[idx].1,
                Err(_) => true,
            };
            if differs {
                orgl = orgl.with(*pos, carrier.clone());
            }
        }
        Edition { orgl, endorsements: EndorsementSet::new(), entries_cache: Arc::new(OnceLock::new()) }
    }

    pub fn map_shared_to(&self, other: &Edition) -> BTreeMap<i64, i64> {
        let my_entries = self.orgl.all_entries();
        let other_entries = other.orgl.all_entries();
        let mut mapping = BTreeMap::new();
        for (pos, carrier) in &my_entries {
            for (other_pos, other_carrier) in &other_entries {
                if *carrier == *other_carrier {
                    mapping.insert(*pos, *other_pos);
                }
            }
        }
        mapping
    }

    pub fn content_shared_region(&self, other: &Edition) -> XnRegion {
        content_shared_region(&self.orgl.all_entries(), &other.orgl.all_entries())
    }

    pub fn content_map_shared_to(&self, other: &Edition) -> SharedMapping {
        content_map_shared_to(&self.orgl.all_entries(), &other.orgl.all_entries())
    }

    pub fn content_map_shared_onto(&self, other: &Edition) -> SharedMapping {
        content_map_shared_onto(&self.orgl.all_entries(), &other.orgl.all_entries())
    }

    pub fn positions_of(&self, value: &RangeElement) -> XnRegion {
        self.orgl.positions_of(&Carrier::new(value.clone()))
    }

    pub fn is_range_identical(&self, other: &Edition, region: Option<&XnRegion>) -> bool {
        let dom = match region {
            Some(r) => r.clone(),
            None => self.domain().union(&other.domain()),
        };
        for (start, stop) in dom.intervals() {
            for pos in start..stop {
                let a = self.orgl.fetch(pos);
                let b = other.orgl.fetch(pos);
                if a != b {
                    return false;
                }
            }
        }
        true
    }

    pub fn positions_labelled(&self, label_id: u64) -> XnRegion {
        let entries = self.orgl.all_entries();
        let mut region = XnRegion::empty();
        for (pos, carrier) in &entries {
            if carrier.element.label_id_value() == Some(label_id) {
                region = region.with(*pos);
            }
        }
        region
    }

    pub fn fetch_labelled(&self, label_id: u64) -> Option<(i64, RangeElement)> {
        let entries = self.orgl.all_entries();
        for (pos, carrier) in &entries {
            if carrier.element.label_id_value() == Some(label_id) {
                if let Some(inner) = carrier.element.as_label_inner() {
                    return Some((*pos, inner.clone()));
                }
                return Some((*pos, carrier.element.clone()));
            }
        }
        None
    }

    pub fn retrieve(&self, region: Option<&XnRegion>, flags: RetrieveFlags) -> Vec<Bundle> {
        let entries = self.orgl.all_entries();
        retrieve_bundles(&entries, region, flags)
    }

    pub fn cost(&self, method: CostMethod) -> StorageCost {
        let entries = self.orgl.all_entries();
        compute_storage_cost(&entries, &std::collections::HashMap::new(), method)
    }

    pub fn cost_with_shares(
        &self,
        content_share_counts: &std::collections::HashMap<u64, u64>,
        method: CostMethod,
    ) -> StorageCost {
        let entries = self.orgl.all_entries();
        compute_storage_cost(&entries, content_share_counts, method)
    }

    pub fn ordered_bundles(&self, region: Option<&XnRegion>) -> Vec<Bundle> {
        let search_region = region.cloned().unwrap_or_else(|| self.domain());
        super::bundle_stepper::loaf_bundle_stepper(self.orgl.loaf(), &search_region)
            .collect_all()
    }

    pub fn ordered_merge_bundles(&self, region: Option<&XnRegion>) -> Vec<Bundle> {
        let search_region = region.cloned().unwrap_or_else(|| self.domain());
        super::bundle_stepper::loaf_merge_stepper(self.orgl.loaf(), &search_region)
            .collect_all()
    }

    pub fn range_transcluders(
        &self,
        region: Option<&XnRegion>,
        direct_only: bool,
        index: &super::transclusion::TransclusionIndex,
    ) -> Vec<u64> {
        let query = super::range_transclusion::RangeTransclusionQuery::new()
            .direct_only(direct_only);
        let query = match region {
            Some(r) => query.with_region(r.clone()),
            None => query,
        };
        let tq = super::transclusion::TransclusionQuery::all();
        let result = super::range_transclusion::range_transcluders(self, &query, index, &tq);
        result.edition_ids
    }

    pub fn range_works(
        &self,
        region: Option<&XnRegion>,
        index: &super::transclusion::TransclusionIndex,
    ) -> Vec<u64> {
        let query = super::range_transclusion::RangeTransclusionQuery::new();
        let query = match region {
            Some(r) => query.with_region(r.clone()),
            None => query,
        };
        let wq = super::transclusion::WorkQuery::all();
        let result = super::range_transclusion::range_works(self, &query, index, &wq);
        result.work_ids
    }

    pub fn transclusion_depth(
        &self,
        position: i64,
        index: &super::transclusion::TransclusionIndex,
        max_depth: usize,
    ) -> usize {
        match self.fetch(position) {
            Some(element) => super::range_transclusion::count_transclusion_depth(
                &element, index, max_depth,
            ),
            None => 0,
        }
    }

    pub fn deeply_transcluded_elements(
        &self,
        region: &XnRegion,
        index: &super::transclusion::TransclusionIndex,
        min_depth: usize,
    ) -> Vec<(i64, RangeElement, usize)> {
        super::range_transclusion::find_deeply_transcluded(self, region, index, min_depth)
    }

    pub fn content_fingerprint_counts(&self) -> std::collections::HashMap<u64, u64> {
        let entries = self.orgl.all_entries();
        let mut counts = std::collections::HashMap::new();
        for (_, carrier) in &entries {
            let fp = fingerprint_u64(&carrier.element);
            *counts.entry(fp).or_insert(0) += 1;
        }
        counts
    }

    pub fn total_byte_size(&self) -> u64 {
        let entries = self.orgl.all_entries();
        entries.iter().map(|(_, c)| element_byte_size(&c.element)).sum()
    }

    pub fn find_content_shared_regions(&self, other: &Edition, min_run: usize) -> Vec<(i64, i64, i64, i64, String)> {
        let entries_a = self.cached_entries();
        let entries_b = other.cached_entries();
        if entries_a.is_empty() || entries_b.is_empty() || min_run == 0 {
            return Vec::new();
        }

        let fps_a: Vec<[u8; 32]> = entries_a.iter()
            .map(|(_, c)| c.element.content_fingerprint())
            .collect();
        let fps_b: Vec<[u8; 32]> = entries_b.iter()
            .map(|(_, c)| c.element.content_fingerprint())
            .collect();

        let mut fp_to_b: std::collections::HashMap<[u8; 32], Vec<usize>> =
            std::collections::HashMap::new();
        for (j, fp) in fps_b.iter().enumerate() {
            fp_to_b.entry(*fp).or_default().push(j);
        }

        let mut run_at_a: Vec<Option<(usize, usize)>> = vec![None; entries_a.len()];

        for i in 0..entries_a.len() {
            if run_at_a[i].is_some() {
                continue;
            }
            let b_cands = match fp_to_b.get(&fps_a[i]) {
                Some(v) => v,
                None => continue,
            };
            for &j in b_cands {
                let mut len = 1usize;
                while i + len < fps_a.len() && j + len < fps_b.len()
                    && fps_a[i + len] == fps_b[j + len]
                {
                    len += 1;
                }
                if len >= min_run {
                    run_at_a[i] = Some((j, len));
                    break;
                }
            }
        }

        let mut seeds: Vec<(usize, usize, usize)> = Vec::new();
        for i in 0..entries_a.len() {
            if let Some((j, len)) = run_at_a[i] {
                seeds.push((i, j, len));
            }
        }

        seeds.sort_by(|a, b| b.2.cmp(&a.2));

        let mut results = Vec::new();
        let mut claimed_a = vec![false; entries_a.len()];
        let mut claimed_b = vec![false; entries_b.len()];

        for (i, j, len) in &seeds {
            let mut conflict = false;
            for k in 0..*len {
                if claimed_a[i + k] || claimed_b[j + k] {
                    conflict = true;
                    break;
                }
            }
            if conflict {
                continue;
            }
            for k in 0..*len {
                claimed_a[i + k] = true;
                claimed_b[j + k] = true;
            }
            let pos_a_start = entries_a[*i].0;
            let pos_a_end = entries_a[*i + *len - 1].0 + 1;
            let pos_b_start = entries_b[*j].0;
            let pos_b_end = entries_b[*j + *len - 1].0 + 1;
            let text: String = entries_a[*i..*i + *len].iter()
                .filter_map(|(_, c)| c.element.as_text())
                .collect();
            results.push((pos_a_start, pos_a_end, pos_b_start, pos_b_end, text));
        }

        results
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct CombineConflict {
    pub position: i64,
    pub left: RangeElement,
    pub right: RangeElement,
}

impl std::fmt::Display for CombineConflict {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "combine conflict at position {}", self.position)
    }
}

impl std::error::Error for CombineConflict {}

#[cfg(test)]
mod tests {
    use super::*;

    fn fetch_text(edition: &Edition, pos: i64) -> Option<String> {
        edition.fetch(pos).and_then(|e| e.as_text().map(|s| s.to_string()))
    }

    #[test]
    fn empty_edition() {
        let e = Edition::empty();
        assert!(e.is_empty());
        assert_eq!(e.count(), 0);
        assert!(e.domain().is_empty());
        assert!(e.fetch_owned(0).is_none());
    }

    #[test]
    fn from_one() {
        let e = Edition::from_one(5, RangeElement::text("x"));
        assert!(!e.is_empty());
        assert_eq!(e.count(), 1);
        assert!(e.has_position(5));
        assert!(!e.has_position(4));
        assert_eq!(fetch_text(&e, 5), Some("x".to_string()));
    }

    #[test]
    fn from_text() {
        let e = Edition::from_text("abc");
        assert_eq!(e.count(), 3);
        assert_eq!(e.to_text(), "abc");
    }

    #[test]
    fn from_text_elements() {
        let elems = vec![
            RangeElement::text("H"),
            RangeElement::text("i"),
            RangeElement::text("!"),
        ];
        let e = Edition::from_text_elements(&elems);
        assert_eq!(e.count(), 3);
        assert_eq!(e.to_text(), "Hi!");
    }

    #[test]
    fn with_adds_position() {
        let e = Edition::empty().with(0, RangeElement::text("a")).with(1, RangeElement::text("b"));
        assert_eq!(e.count(), 2);
        assert_eq!(fetch_text(&e, 0), Some("a".to_string()));
        assert_eq!(fetch_text(&e, 1), Some("b".to_string()));
    }

    #[test]
    fn without_removes_position() {
        let e = Edition::from_text("abc");
        let e2 = e.without(1);
        assert_eq!(e2.count(), 2);
        assert!(e2.has_position(0));
        assert!(!e2.has_position(1));
        assert!(e2.has_position(2));
    }

    #[test]
    fn with_all_fills_region() {
        let region = XnRegion::interval(0, 5);
        let e = Edition::empty().with_all(&region, RangeElement::text("x"));
        assert_eq!(e.count(), 5);
        for i in 0..5 {
            assert_eq!(fetch_text(&e, i), Some("x".to_string()));
        }
    }

    #[test]
    fn without_all_clears_region() {
        let e = Edition::from_text("abcde");
        let region = XnRegion::interval(1, 4);
        let e2 = e.without_all(&region);
        assert_eq!(e2.count(), 2);
        assert!(e2.has_position(0));
        assert!(!e2.has_position(1));
        assert!(!e2.has_position(2));
        assert!(!e2.has_position(3));
        assert!(e2.has_position(4));
    }

    #[test]
    fn combine_disjoint() {
        let a = Edition::from_one(0, RangeElement::text("a"));
        let b = Edition::from_one(1, RangeElement::text("b"));
        let c = a.combine(&b).unwrap();
        assert_eq!(c.count(), 2);
        assert_eq!(fetch_text(&c, 0), Some("a".to_string()));
        assert_eq!(fetch_text(&c, 1), Some("b".to_string()));
    }

    #[test]
    fn combine_conflict() {
        let a = Edition::from_one(0, RangeElement::text("a"));
        let b = Edition::from_one(0, RangeElement::text("b"));
        let err = a.combine(&b).unwrap_err();
        assert_eq!(err.position, 0);
    }

    #[test]
    fn combine_same_value_succeeds() {
        let a = Edition::from_one(0, RangeElement::text("x"));
        let b = Edition::from_one(0, RangeElement::text("x"));
        let c = a.combine(&b).unwrap();
        assert_eq!(c.count(), 1);
    }

    #[test]
    fn replace_overwrites() {
        let a = Edition::from_text("abc");
        let b = Edition::from_one(1, RangeElement::text("X"));
        let c = a.replace(&b);
        assert_eq!(c.to_text(), "aXc");
    }

    #[test]
    fn copy_subset() {
        let e = Edition::from_text("abcde");
        let region = XnRegion::interval(1, 4);
        let sub = e.copy(&region);
        assert_eq!(sub.count(), 3);
        assert!(!sub.has_position(0));
        assert!(sub.has_position(1));
        assert!(sub.has_position(2));
        assert!(sub.has_position(3));
        assert!(!sub.has_position(4));
    }

    #[test]
    fn transformed_by_shifts() {
        let e = Edition::from_text("abc");
        let e2 = e.transformed_by(10);
        assert_eq!(e2.count(), 3);
        assert!(!e2.has_position(0));
        assert!(e2.has_position(10));
        assert!(e2.has_position(11));
        assert!(e2.has_position(12));
    }

    #[test]
    fn shared_region_finds_common() {
        let a = Edition::from_text("abc");
        let b = Edition::from_text("xbc");
        let shared = a.shared_region(&b);
        assert!(shared.contains(1));
        assert!(shared.contains(2));
        assert!(!shared.contains(0));
    }

    #[test]
    fn shared_with_returns_common_entries() {
        let a = Edition::from_text("abc");
        let b = Edition::from_text("xbc");
        let shared = a.shared_with(&b);
        assert_eq!(shared.count(), 2);
        assert_eq!(fetch_text(&shared, 1), Some("b".to_string()));
        assert_eq!(fetch_text(&shared, 2), Some("c".to_string()));
    }

    #[test]
    fn not_shared_with_returns_differences() {
        let a = Edition::from_text("abc");
        let b = Edition::from_text("xbc");
        let diff = a.not_shared_with(&b);
        assert_eq!(diff.count(), 1);
        assert_eq!(fetch_text(&diff, 0), Some("a".to_string()));
    }

    #[test]
    fn map_shared_to() {
        let a = Edition::from_text("abc");
        let b = a.transformed_by(5);
        let mapping = a.map_shared_to(&b);
        assert_eq!(mapping.get(&0), Some(&5));
        assert_eq!(mapping.get(&1), Some(&6));
        assert_eq!(mapping.get(&2), Some(&7));
    }

    #[test]
    fn positions_of() {
        let e = Edition::empty()
            .with(0, RangeElement::text("x"))
            .with(1, RangeElement::text("y"))
            .with(2, RangeElement::text("x"));
        let pos = e.positions_of(&RangeElement::text("x"));
        assert!(pos.contains(0));
        assert!(!pos.contains(1));
        assert!(pos.contains(2));
    }

    #[test]
    fn is_range_identical() {
        let a = Edition::from_text("abc");
        let b = Edition::from_text("abc");
        assert!(a.is_range_identical(&b, None));

        let c = Edition::from_text("axc");
        assert!(!a.is_range_identical(&c, None));

        let region = XnRegion::interval(0, 1);
        assert!(a.is_range_identical(&c, Some(&region)));
    }

    #[test]
    fn find_content_shared_regions_basic() {
        let a = Edition::from_text("hello world");
        let b = Edition::from_text("say hello world now");
        let regions = a.find_content_shared_regions(&b, 2);
        assert!(!regions.is_empty());
        let (sa, ea, _sb, _eb, text) = &regions[0];
        assert_eq!(text, "hello world");
        assert_eq!(*sa, 0);
        assert_eq!(*ea, 11);
    }

    #[test]
    fn find_content_shared_regions_partial() {
        let a = Edition::from_text("the quick brown fox");
        let b = Edition::from_text("a quick blue fox");
        let regions = a.find_content_shared_regions(&b, 4);
        assert!(regions.len() >= 1);
        let texts: Vec<&str> = regions.iter().map(|r| r.4.as_str()).collect();
        assert!(texts.iter().any(|t| t.contains("quick") || t.contains("fox")),
            "expected 'quick' or 'fox' in {:?}, find_content_shared_regions_partial):", texts);
    }

    #[test]
    fn find_content_shared_regions_min_run() {
        let a = Edition::from_text("abcdef");
        let b = Edition::from_text("abcxyz");
        let regions3 = a.find_content_shared_regions(&b, 4);
        assert!(regions3.is_empty(), "3-char match should not meet min_run=4");
        let regions2 = a.find_content_shared_regions(&b, 2);
        assert!(!regions2.is_empty());
        assert!(regions2[0].4.contains("abc"));
    }

    #[test]
    fn find_content_shared_regions_empty() {
        let a = Edition::from_text("");
        let b = Edition::from_text("hello");
        assert!(a.find_content_shared_regions(&b, 4).is_empty());
        assert!(b.find_content_shared_regions(&a, 4).is_empty());
    }

    #[test]
    fn find_content_shared_regions_identical() {
        let a = Edition::from_text("same text");
        let b = Edition::from_text("same text");
        let regions = a.find_content_shared_regions(&b, 2);
        assert_eq!(regions.len(), 1);
        assert_eq!(regions[0].4, "same text");
        assert_eq!(regions[0].0, 0);
        assert_eq!(regions[0].1, 9);
        assert_eq!(regions[0].2, 0);
        assert_eq!(regions[0].3, 9);
    }

    #[test]
    fn find_content_shared_regions_shifted() {
        let a = Edition::from_text("hello");
        let b = Edition::from_text("xxhello");
        let regions = a.find_content_shared_regions(&b, 2);
        assert_eq!(regions.len(), 1);
        assert_eq!(regions[0].4, "hello");
        assert_eq!(regions[0].0, 0);
        assert_eq!(regions[0].1, 5);
        assert_eq!(regions[0].2, 2);
        assert_eq!(regions[0].3, 7);
    }

    #[test]
    fn find_content_shared_regions_multiple_runs() {
        let a = Edition::from_text("cat dog bird cat dog");
        let b = Edition::from_text("cat dog fish cat dog");
        let regions = a.find_content_shared_regions(&b, 3);
        assert!(regions.len() >= 2, "expected at least 2 shared runs, got {}: {:?}", regions.len(), regions);
    }

    #[test]
    fn find_content_shared_regions_with_blob() {
        let a = Edition::from_text_elements(&[
            RangeElement::text("a"),
            RangeElement::text("b"),
            RangeElement::Blob { content_hash: 42, mime_type: "image/png".into(), byte_size: 100, width: Some(10), height: Some(10) },
            RangeElement::text("c"),
        ]);
        let b = Edition::from_text_elements(&[
            RangeElement::text("x"),
            RangeElement::text("b"),
            RangeElement::Blob { content_hash: 42, mime_type: "image/png".into(), byte_size: 100, width: Some(10), height: Some(10) },
            RangeElement::text("c"),
        ]);
        let regions = a.find_content_shared_regions(&b, 2);
        assert!(!regions.is_empty(), "should find shared blob+text run");
    }

    #[test]
    fn place_holders_creates_identity() {
        let region = XnRegion::interval(0, 3);
        let e = Edition::place_holders(&region);
        assert_eq!(e.count(), 3);
        for i in 0..3 {
            let elem = e.fetch(i).unwrap();
            assert!(matches!(elem, RangeElement::PlaceHolder { .. }));
        }
    }

    #[test]
    fn domain_returns_all_keys() {
        let e = Edition::empty()
            .with(3, RangeElement::text("a"))
            .with(7, RangeElement::text("b"))
            .with(10, RangeElement::text("c"));
        let dom = e.domain();
        assert!(dom.contains(3));
        assert!(dom.contains(7));
        assert!(dom.contains(10));
        assert!(!dom.contains(0));
        assert_eq!(dom.count(), Some(3));
    }

    #[test]
    fn immutability_original_unchanged() {
        let e = Edition::from_text("abc");
        let _e2 = e.with(0, RangeElement::text("X"));
        assert_eq!(fetch_text(&e, 0), Some("a".to_string()));
    }

    #[test]
    fn from_all_creates_uniform() {
        let region = XnRegion::interval(0, 4);
        let e = Edition::from_all(&region, RangeElement::text("z"));
        for i in 0..4 {
            assert_eq!(fetch_text(&e, i), Some("z".to_string()));
        }
    }

    #[test]
    fn gold_placeholders_over_empty_region() {
        let e = Edition::place_holders(&XnRegion::empty());
        assert!(e.is_empty());
    }

    #[test]
    fn gold_from_one_with_data() {
        let e = Edition::from_one(2, RangeElement::data(vec![3]));
        assert_eq!(e.count(), 1);
        assert!(e.has_position(2));
    }

    #[test]
    fn gold_from_all_over_empty() {
        let e = Edition::from_all(&XnRegion::empty(), RangeElement::placeholder(0));
        assert!(e.is_empty());
    }

    #[test]
    fn gold_from_text_empty_string() {
        let e = Edition::from_text("");
        assert!(e.is_empty());
        assert_eq!(e.count(), 0);
    }

    #[test]
    fn gold_from_text_hello_world() {
        let e = Edition::from_text("hello world");
        assert_eq!(e.count(), 11);
        assert_eq!(e.to_text(), "hello world");
    }

    #[test]
    fn gold_from_text_shifted_domain() {
        let shifted = Edition::from_text("hello world!").transformed_by(10);
        assert_eq!(shifted.count(), 12);
        assert!(shifted.has_position(10));
        assert!(!shifted.has_position(0));
    }

    #[test]
    fn gold_with_all_then_without() {
        let e = Edition::empty()
            .with_all(&XnRegion::interval(0, 10), RangeElement::placeholder(0))
            .without(3);
        assert_eq!(e.count(), 9);
        assert!(!e.has_position(3));
        assert!(e.has_position(2));
        assert!(e.has_position(4));
    }

    #[test]
    fn gold_without_all_removes_above() {
        let e = Edition::empty()
            .with_all(&XnRegion::interval(0, 10), RangeElement::placeholder(0))
            .without_all(&XnRegion::above(2));
        assert_eq!(e.count(), 2);
        assert!(e.has_position(0));
        assert!(e.has_position(1));
        assert!(!e.has_position(2));
    }

    #[test]
    fn gold_combine_then_replace() {
        let edition = Edition::empty()
            .with(0, RangeElement::placeholder(0))
            .with(1, RangeElement::data(vec![65]));
        let other = Edition::from_one(5, RangeElement::placeholder(1));
        let combined = edition.combine(&other).unwrap();
        assert_eq!(combined.count(), 3);
        assert!(combined.has_position(0));
        assert!(combined.has_position(1));
        assert!(combined.has_position(5));

        let replacement = Edition::from_one(1, RangeElement::placeholder(1));
        let replaced = edition.replace(&replacement);
        assert_eq!(replaced.count(), 2);
    }

    #[test]
    fn gold_shared_region_with_subset_copy() {
        let a = Edition::from_text("abcdefghijklmnopqrstuvwxyz");
        let b = a.clone();
        let b_sub = b.copy(&XnRegion::interval(0, 5));
        assert_eq!(a.shared_region(&b_sub), XnRegion::interval(0, 5));
    }

    #[test]
    fn gold_shared_region_is_symmetric() {
        let a = Edition::from_text("hello");
        let b = Edition::from_text("hxllo");
        assert_eq!(a.shared_region(&b), b.shared_region(&a));
        assert_eq!(a.shared_with(&b), b.shared_with(&a));
    }

    #[test]
    fn gold_map_shared_to_shifted_edition() {
        let a = Edition::from_text("abc");
        let b = a.transformed_by(10);
        let mapping = a.map_shared_to(&b);
        assert_eq!(mapping.get(&0), Some(&10));
        assert_eq!(mapping.get(&1), Some(&11));
        assert_eq!(mapping.get(&2), Some(&12));
    }

    #[test]
    fn stress_large_edition_otree() {
        let mut e = Edition::empty();
        for i in 0..50_000 {
            e = e.with(i, RangeElement::text(format!("{i}")));
        }
        assert_eq!(e.count(), 50_000);
        assert!(e.has_position(25_000));
        assert_eq!(fetch_text(&e, 25_000), Some("25000".to_string()));
    }

    #[test]
    fn stress_splay_on_large_edition() {
        let mut e = Edition::empty();
        for i in 0..10_000 {
            e = e.with(i, RangeElement::text(format!("{i}")));
        }
        use crate::edition::orgl::SplayResult;
        let mut orgl = e.orgl.clone();
        let result = orgl.splay(&XnRegion::interval(1000, 2000));
        assert_eq!(result, SplayResult::Partial);
    }

    // === Infinite domain tests ===

    #[test]
    fn infinite_edition_from_all() {
        let e = Edition::from_all(&XnRegion::above(0), RangeElement::text("."));
        assert!(e.is_infinite());
        assert!(!e.is_finite());
        assert!(e.has_position(0));
        assert!(e.has_position(1000000));
        assert_eq!(fetch_text(&e, 42), Some(".".to_string()));
    }

    #[test]
    fn infinite_edition_override() {
        let e = Edition::from_all(&XnRegion::above(0), RangeElement::text("."))
            .with(5, RangeElement::text("X"));
        assert_eq!(fetch_text(&e, 5), Some("X".to_string()));
        assert_eq!(fetch_text(&e, 6), Some(".".to_string()));
    }

    #[test]
    fn infinite_edition_without() {
        let e = Edition::from_all(&XnRegion::above(0), RangeElement::text("."))
            .without(5);
        assert!(!e.has_position(5));
        assert!(e.has_position(4));
        assert!(e.has_position(6));
    }

    #[test]
    fn infinite_edition_with_default() {
        let e = Edition::with_default(XnRegion::interval(0, 100), RangeElement::text("?"));
        assert!(!e.is_infinite());
        assert!(e.has_position(50));
        assert_eq!(fetch_text(&e, 50), Some("?".to_string()));
    }

    #[test]
    fn infinite_edition_transformed() {
        let e = Edition::from_all(&XnRegion::above(0), RangeElement::text("."))
            .transformed_by(100);
        assert!(e.has_position(100));
        assert!(!e.has_position(0));
        assert_eq!(fetch_text(&e, 150), Some(".".to_string()));
    }

    #[test]
    fn infinite_edition_copy() {
        let e = Edition::from_all(&XnRegion::above(0), RangeElement::text("."));
        let sub = e.copy(&XnRegion::interval(0, 10));
        assert!(sub.has_position(5));
        assert!(!sub.has_position(10));
    }

    // === DspLoaf through Edition ===

    #[test]
    fn transformed_by_is_lazy_dsp() {
        let e = Edition::from_text("abc");
        let shifted = e.transformed_by(10);
        assert_eq!(shifted.count(), 3);
        assert!(shifted.has_position(10));
        assert_eq!(fetch_text(&shifted, 10), Some("a".to_string()));
    }

    #[test]
    fn transformed_chain_is_efficient() {
        let e = Edition::from_text("hello");
        let result = e.transformed_by(10).transformed_by(10).transformed_by(10);
        assert_eq!(fetch_text(&result, 30), Some("h".to_string()));
        assert_eq!(fetch_text(&result, 34), Some("o".to_string()));
    }

    #[test]
    fn identity_shared_region_by_be_id() {
        let e1 = Edition::from_one(0, RangeElement::edition(1))
            .with(1, RangeElement::edition(2))
            .with(2, RangeElement::edition(3));
        let e2 = Edition::from_one(0, RangeElement::edition(1))
            .with(1, RangeElement::edition(99))
            .with(2, RangeElement::edition(3));
        let id_eq = |a: &Carrier, b: &Carrier| match (&a.element, &b.element) {
            (
                RangeElement::Edition { edition_id: id_a },
                RangeElement::Edition { edition_id: id_b },
            ) => id_a == id_b,
            _ => false,
        };
        let region = e1.identity_shared_region(&e2, id_eq);
        assert!(region.contains(0));
        assert!(!region.contains(1));
        assert!(region.contains(2));
    }

    #[test]
    fn identity_shared_region_empty_on_no_match() {
        let e1 = Edition::from_one(0, RangeElement::edition(1));
        let e2 = Edition::from_one(0, RangeElement::edition(2));
        let id_eq = |a: &Carrier, b: &Carrier| match (&a.element, &b.element) {
            (
                RangeElement::Edition { edition_id: id_a },
                RangeElement::Edition { edition_id: id_b },
            ) => id_a == id_b,
            _ => false,
        };
        let region = e1.identity_shared_region(&e2, id_eq);
        assert!(region.is_empty());
    }

    #[test]
    fn positions_labelled_finds_single_label() {
        let e = Edition::from_text_elements(&[
            RangeElement::text("before"),
            RangeElement::label(1, RangeElement::text("target")),
            RangeElement::text("after"),
        ]);
        let region = e.positions_labelled(1);
        assert!(region.contains(1));
        assert!(!region.contains(0));
        assert!(!region.contains(2));
    }

    #[test]
    fn positions_labelled_multiple_labels() {
        let e = Edition::from_text_elements(&[
            RangeElement::label(1, RangeElement::text("a")),
            RangeElement::label(2, RangeElement::text("b")),
            RangeElement::label(1, RangeElement::text("c")),
        ]);
        let region = e.positions_labelled(1);
        assert!(region.contains(0));
        assert!(!region.contains(1));
        assert!(region.contains(2));
    }

    #[test]
    fn positions_labelled_no_match() {
        let e = Edition::from_text("hello");
        let region = e.positions_labelled(99);
        assert!(region.is_empty());
    }

    #[test]
    fn fetch_labelled_returns_position_and_inner() {
        let e = Edition::from_text_elements(&[
            RangeElement::text("before"),
            RangeElement::label(42, RangeElement::text("found")),
            RangeElement::text("after"),
        ]);
        let (pos, elem) = e.fetch_labelled(42).unwrap();
        assert_eq!(pos, 1);
        assert_eq!(elem.as_text(), Some("found"));
    }

    #[test]
    fn fetch_labelled_no_match() {
        let e = Edition::from_text("hello");
        assert!(e.fetch_labelled(99).is_none());
    }

    #[test]
    #[ignore]
    fn bench_old_vs_bulk_construction() {
        use std::time::Instant;
        use std::sync::Arc;
        use crate::edition::orgl::OrglRoot;
        use crate::edition::range_element::Carrier;

        let sizes = [1_000, 10_000, 50_000, 100_000];

        println!("\n{:>10} | {:>12} | {:>12} | {:>8} | {}",
            "Size", "Old (ms)", "Bulk (ms)", "Speedup", "Count OK");
        println!("{:-<10}-+-{:-<12}-+-{:-<12}-+-{:-<8}-+-{:-<10}",
            "", "", "", "", "");

        for &n in &sizes {
            let entries: Vec<(i64, RangeElement)> = (0..n)
                .map(|i| (i as i64, RangeElement::text(format!("v{}", i))))
                .collect();

            let carriers: Vec<(i64, Arc<Carrier>)> = entries.iter()
                .map(|(pos, elem)| (*pos, Arc::new(Carrier::new(elem.clone()))))
                .collect();

            let start = Instant::now();
            let mut old_edition = Edition::empty();
            for (pos, elem) in &entries {
                old_edition = old_edition.with(*pos, elem.clone());
            }
            let old_dur = start.elapsed();
            let old_count = old_edition.count();

            let start = Instant::now();
            let region = XnRegion::interval(0, n as i64);
            let orgl = OrglRoot::from_bulk_entries(carriers.clone(), None, region);
            let bulk_edition = Edition { orgl, endorsements: EndorsementSet::new(), entries_cache: Arc::new(OnceLock::new()) };
            let bulk_dur = start.elapsed();
            let bulk_count = bulk_edition.count();

            let old_ms = old_dur.as_secs_f64() * 1000.0;
            let bulk_ms = bulk_dur.as_secs_f64() * 1000.0;
            let speedup = old_ms / bulk_ms.max(0.001);

            assert_eq!(old_count, bulk_count);
            assert_eq!(old_count, n as u64);

            println!("{:>10} | {:>12.2} | {:>12.2} | {:>7.1}x | old={} bulk={}",
                n, old_ms, bulk_ms, speedup, old_count, bulk_count);

            for i in (0..n).step_by(n / 10.max(1)) {
                let old_val = old_edition.fetch(i as i64);
                let bulk_val = bulk_edition.fetch(i as i64);
                assert!(old_val.is_some(), "old missing at {}", i);
                assert!(bulk_val.is_some(), "bulk missing at {}", i);
                assert_eq!(old_val, bulk_val, "mismatch at position {}", i);
            }
        }
    }
}
