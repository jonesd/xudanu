use std::sync::Arc;
use std::collections::HashSet;

use super::edition::Edition;
use super::range_element::{Carrier, RangeElement};
use super::xn_region::XnRegion;

#[derive(Debug, Clone)]
pub struct RangeTransclusionQuery {
    region: Option<XnRegion>,
    direct_only: bool,
    local_present_only: bool,
}

impl RangeTransclusionQuery {
    pub fn new() -> Self {
        RangeTransclusionQuery {
            region: None,
            direct_only: false,
            local_present_only: true,
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

    pub fn local_present_only(mut self, local_present_only: bool) -> Self {
        self.local_present_only = local_present_only;
        self
    }

    pub fn region(&self) -> Option<&XnRegion> {
        self.region.as_ref()
    }

    pub fn is_direct_only(&self) -> bool {
        self.direct_only
    }

    pub fn is_local_present_only(&self) -> bool {
        self.local_present_only
    }
}

impl Default for RangeTransclusionQuery {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(Debug, Clone)]
pub struct RangeTransclusionResult {
    pub edition_ids: Vec<u64>,
    pub work_ids: Vec<u64>,
    pub region: XnRegion,
}

#[derive(Debug, Clone)]
pub struct RangeWorkResult {
    pub work_ids: Vec<u64>,
    pub region: XnRegion,
}

pub fn range_transcluders(
    edition: &Edition,
    query: &RangeTransclusionQuery,
    index: &super::transclusion::TransclusionIndex,
    transclusion_query: &super::transclusion::TransclusionQuery,
) -> RangeTransclusionResult {
    let search_region = query.region().cloned().unwrap_or_else(|| edition.domain());
    let search_edition = if query.region().is_some() {
        edition.copy(&search_region)
    } else {
        edition.clone()
    };
    let entries = search_edition.fetch_range(&search_region);
    let mut seen = HashSet::new();
    let mut edition_ids = Vec::new();
    let mut work_ids = Vec::new();
    for (_pos, carrier) in &entries {
        let results = index.find_transcluders(&carrier.element, transclusion_query);
        for result in results {
            if query.is_direct_only() && !result.is_direct {
                continue;
            }
            if let Some(eid) = result.element.as_edition_id() {
                if seen.insert(format!("e:{}", eid)) {
                    edition_ids.push(eid);
                }
            } else if let Some(wid) = result.element.as_work_id() {
                if seen.insert(format!("w:{}", wid)) {
                    work_ids.push(wid);
                }
            }
        }
    }
    RangeTransclusionResult {
        edition_ids,
        work_ids,
        region: search_region,
    }
}

pub fn range_works(
    edition: &Edition,
    query: &RangeTransclusionQuery,
    index: &super::transclusion::TransclusionIndex,
    work_query: &super::transclusion::WorkQuery,
) -> RangeWorkResult {
    let search_region = query.region().cloned().unwrap_or_else(|| edition.domain());
    let search_edition = if query.region().is_some() {
        edition.copy(&search_region)
    } else {
        edition.clone()
    };
    let entries = search_edition.fetch_range(&search_region);
    let mut seen_works = HashSet::new();
    let mut work_ids = Vec::new();
    for (_pos, carrier) in &entries {
        let results = index.find_works(&carrier.element, work_query);
        for elem in results {
            if let Some(wid) = elem.as_work_id() {
                if seen_works.insert(wid) {
                    work_ids.push(wid);
                }
            }
        }
    }
    RangeWorkResult {
        work_ids,
        region: search_region,
    }
}

pub fn walk_otree_shared(
    loaf_entries: &[(i64, Arc<Carrier>)],
    other_entries: &[(i64, Arc<Carrier>)],
    region: &XnRegion,
) -> Vec<(i64, RangeElement)> {
    let mut shared = Vec::new();
    let mut other_idx = 0usize;
    for (pos, carrier) in loaf_entries {
        if !region.contains(*pos) {
            continue;
        }
        while other_idx < other_entries.len() && other_entries[other_idx].0 < *pos {
            other_idx += 1;
        }
        if other_idx < other_entries.len() && other_entries[other_idx].0 == *pos {
            if *carrier == other_entries[other_idx].1 {
                shared.push((*pos, carrier.element.clone()));
            }
            other_idx += 1;
        }
    }
    shared
}

pub fn collect_unique_elements(
    edition: &Edition,
    region: &XnRegion,
) -> Vec<RangeElement> {
    let entries = edition.fetch_range(region);
    let mut seen = HashSet::new();
    let mut unique = Vec::new();
    for (_, carrier) in &entries {
        let fp = carrier.element.content_fingerprint();
        let key: Vec<u8> = fp.to_vec();
        if seen.insert(key) {
            unique.push(carrier.element.clone());
        }
    }
    unique
}

pub fn count_transclusion_depth(
    element: &RangeElement,
    index: &super::transclusion::TransclusionIndex,
    max_depth: usize,
) -> usize {
    if max_depth == 0 {
        return 0;
    }
    let query = super::transclusion::TransclusionQuery::all();
    let results = index.find_transcluders(element, &query);
    if results.is_empty() {
        return 0;
    }
    let mut max_child_depth = 0;
    for result in &results {
        let child_depth = count_transclusion_depth(&result.element, index, max_depth - 1);
        if child_depth + 1 > max_child_depth {
            max_child_depth = child_depth + 1;
        }
        if max_child_depth >= max_depth {
            break;
        }
    }
    max_child_depth
}

pub fn find_deeply_transcluded(
    edition: &Edition,
    region: &XnRegion,
    index: &super::transclusion::TransclusionIndex,
    min_depth: usize,
) -> Vec<(i64, RangeElement, usize)> {
    let unique = collect_unique_elements(edition, region);
    let mut result = Vec::new();
    for element in &unique {
        let depth = count_transclusion_depth(element, index, min_depth + 1);
        if depth >= min_depth {
            let positions = edition.positions_of(element);
            for (start, stop) in positions.intersect(region).intervals() {
                for pos in start..stop {
                    result.push((pos, element.clone(), depth));
                }
            }
        }
    }
    result.sort_by_key(|(p, _, _)| *p);
    result
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::transclusion::TransclusionIndex;

    #[test]
    fn range_transclusion_query_default() {
        let q = RangeTransclusionQuery::new();
        assert!(q.region().is_none());
        assert!(!q.is_direct_only());
        assert!(q.is_local_present_only());
    }

    #[test]
    fn range_transclusion_query_with_region() {
        let q = RangeTransclusionQuery::new()
            .with_region(XnRegion::interval(0, 10));
        assert!(q.region().is_some());
        assert_eq!(q.region().unwrap().start(), Some(0));
    }

    #[test]
    fn range_transclusion_query_builders() {
        let q = RangeTransclusionQuery::new()
            .direct_only(true)
            .local_present_only(false);
        assert!(q.is_direct_only());
        assert!(!q.is_local_present_only());
    }

    #[test]
    fn range_transcluders_finds_editions() {
        let mut idx = TransclusionIndex::new();
        let edition = Edition::from_text("hello world");
        idx.register_edition(&edition, &RangeElement::edition(1), None);
        idx.register_edition(&edition, &RangeElement::edition(2), None);

        let query = RangeTransclusionQuery::new();
        let tq = crate::edition::transclusion::TransclusionQuery::all();
        let result = range_transcluders(&edition, &query, &idx, &tq);
        assert!(result.edition_ids.contains(&1));
        assert!(result.edition_ids.contains(&2));
    }

    #[test]
    fn range_transcluders_with_region() {
        let mut idx = TransclusionIndex::new();
        let mut edition = Edition::empty();
        edition = edition.with(0, RangeElement::text("a"));
        edition = edition.with(1, RangeElement::text("b"));
        edition = edition.with(2, RangeElement::text("c"));
        idx.register_edition(&edition, &RangeElement::edition(10), None);

        let query = RangeTransclusionQuery::new().with_region(XnRegion::interval(0, 2));
        let tq = crate::edition::transclusion::TransclusionQuery::all();
        let result = range_transcluders(&edition, &query, &idx, &tq);
        assert!(result.edition_ids.contains(&10));
    }

    #[test]
    fn range_transcluders_empty_edition() {
        let idx = TransclusionIndex::new();
        let edition = Edition::empty();
        let query = RangeTransclusionQuery::new();
        let tq = crate::edition::transclusion::TransclusionQuery::all();
        let result = range_transcluders(&edition, &query, &idx, &tq);
        assert!(result.edition_ids.is_empty());
    }

    #[test]
    fn range_works_finds_works() {
        let mut idx = TransclusionIndex::new();
        let edition = Edition::from_text("document");
        idx.register_work(&edition, &RangeElement::work(42));

        let query = RangeTransclusionQuery::new();
        let wq = crate::edition::transclusion::WorkQuery::all();
        let result = range_works(&edition, &query, &idx, &wq);
        assert!(result.work_ids.contains(&42));
    }

    #[test]
    fn range_works_deduplicates() {
        let mut idx = TransclusionIndex::new();
        let mut edition = Edition::empty();
        edition = edition.with(0, RangeElement::text("x"));
        edition = edition.with(1, RangeElement::text("x"));
        idx.register_work(&edition, &RangeElement::work(1));
        idx.register_work(&edition, &RangeElement::work(1));

        let query = RangeTransclusionQuery::new();
        let wq = crate::edition::transclusion::WorkQuery::all();
        let result = range_works(&edition, &query, &idx, &wq);
        assert_eq!(result.work_ids.len(), 1);
    }

    #[test]
    fn walk_otree_shared_finds_common() {
        let a: Vec<(i64, Arc<Carrier>)> = vec![
            (0, Arc::new(Carrier::new(RangeElement::text("a")))),
            (1, Arc::new(Carrier::new(RangeElement::text("b")))),
            (2, Arc::new(Carrier::new(RangeElement::text("c")))),
        ];
        let b: Vec<(i64, Arc<Carrier>)> = vec![
            (0, Arc::new(Carrier::new(RangeElement::text("a")))),
            (1, Arc::new(Carrier::new(RangeElement::text("X")))),
            (2, Arc::new(Carrier::new(RangeElement::text("c")))),
        ];
        let region = XnRegion::interval(0, 3);
        let shared = walk_otree_shared(&a, &b, &region);
        assert_eq!(shared.len(), 2);
        assert_eq!(shared[0].0, 0);
        assert_eq!(shared[1].0, 2);
    }

    #[test]
    fn walk_otree_shared_empty() {
        let a: Vec<(i64, Arc<Carrier>)> = vec![];
        let b: Vec<(i64, Arc<Carrier>)> = vec![];
        let region = XnRegion::interval(0, 3);
        let shared = walk_otree_shared(&a, &b, &region);
        assert!(shared.is_empty());
    }

    #[test]
    fn collect_unique_elements_deduplicates() {
        let edition = Edition::from_text("aabbc");
        let region = XnRegion::interval(0, 5);
        let unique = collect_unique_elements(&edition, &region);
        assert_eq!(unique.len(), 3);
    }

    #[test]
    fn collect_unique_elements_with_region() {
        let edition = Edition::from_text("aabbc");
        let region = XnRegion::interval(0, 2);
        let unique = collect_unique_elements(&edition, &region);
        assert_eq!(unique.len(), 1);
    }

    #[test]
    fn count_transclusion_depth_no_transcluders() {
        let idx = TransclusionIndex::new();
        let depth = count_transclusion_depth(&RangeElement::text("x"), &idx, 3);
        assert_eq!(depth, 0);
    }

    #[test]
    fn count_transclusion_depth_direct() {
        let mut idx = TransclusionIndex::new();
        let edition = Edition::from_one(0, RangeElement::text("x"));
        idx.register_edition(&edition, &RangeElement::edition(1), None);
        let depth = count_transclusion_depth(&RangeElement::text("x"), &idx, 3);
        assert!(depth >= 1);
    }

    #[test]
    fn find_deeply_transcluded_basic() {
        let mut idx = TransclusionIndex::new();
        let edition = Edition::from_text("abc");
        idx.register_edition(&edition, &RangeElement::edition(1), None);
        idx.register_edition(&edition, &RangeElement::edition(2), None);

        let region = XnRegion::interval(0, 3);
        let result = find_deeply_transcluded(&edition, &region, &idx, 1);
        assert!(!result.is_empty());
    }

    #[test]
    fn find_deeply_transcluded_none() {
        let idx = TransclusionIndex::new();
        let edition = Edition::from_text("xyz");
        let region = XnRegion::interval(0, 3);
        let result = find_deeply_transcluded(&edition, &region, &idx, 1);
        assert!(result.is_empty());
    }

    #[test]
    fn range_transcluders_no_match() {
        let idx = TransclusionIndex::new();
        let edition = Edition::from_text("unique content");
        let query = RangeTransclusionQuery::new();
        let tq = crate::edition::transclusion::TransclusionQuery::all();
        let result = range_transcluders(&edition, &query, &idx, &tq);
        assert!(result.edition_ids.is_empty());
    }
}
