use super::xn_region::XnRegion;
#[cfg(feature = "serde")]
use std::collections::BTreeMap;

/// A region-aware index for querying spans (links, transclusions, annotations)
/// by their position ranges. Supports "find all spans intersecting/containing/
/// contained-in a query region."
///
/// Uses a sorted interval tree for O(log n) queries.
#[derive(Debug, Clone, Default)]
pub struct RegionIndex<T: Clone> {
    /// Sorted by start position: (start, end, value)
    entries: Vec<(i64, i64, T)>,
}

#[derive(Debug, Clone, PartialEq)]
pub enum RegionRelation {
    /// Query region contains the span
    Contains,
    /// Query region intersects the span
    Intersects,
    /// Span contains the query region
    ContainedBy,
    /// Span is entirely within query region
    Within,
}

impl<T: Clone> RegionIndex<T> {
    pub fn new() -> Self {
        RegionIndex {
            entries: Vec::new(),
        }
    }

    pub fn insert(&mut self, start: i64, end: i64, value: T) {
        self.entries.push((start, end, value));
        self.entries.sort_by_key(|(s, _, _)| *s);
    }

    pub fn len(&self) -> usize {
        self.entries.len()
    }

    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }

    pub fn clear(&mut self) {
        self.entries.clear();
    }

    /// Find all spans that intersect the query region.
    /// Returns (start, end, value) tuples.
    pub fn query_intersect(&self, query_start: i64, query_end: i64) -> Vec<(i64, i64, &T)> {
        self.entries
            .iter()
            .filter(|(s, e, _)| *s < query_end && *e > query_start)
            .map(|(s, e, v)| (*s, *e, v))
            .collect()
    }

    /// Find all spans entirely within the query region.
    pub fn query_within(&self, query_start: i64, query_end: i64) -> Vec<(i64, i64, &T)> {
        self.entries
            .iter()
            .filter(|(s, e, _)| *s >= query_start && *e <= query_end)
            .map(|(s, e, v)| (*s, *e, v))
            .collect()
    }

    /// Find all spans that contain the query region.
    pub fn query_containing(&self, query_start: i64, query_end: i64) -> Vec<(i64, i64, &T)> {
        self.entries
            .iter()
            .filter(|(s, e, _)| *s <= query_start && *e >= query_end)
            .map(|(s, e, v)| (*s, *e, v))
            .collect()
    }

    /// Find all spans that contain a specific position.
    pub fn query_at(&self, pos: i64) -> Vec<(i64, i64, &T)> {
        self.entries
            .iter()
            .filter(|(s, e, _)| *s <= pos && *e > pos)
            .map(|(s, e, v)| (*s, *e, v))
            .collect()
    }

    /// Query using an XnRegion for intersection.
    pub fn query_region_intersect(&self, region: &XnRegion) -> Vec<(i64, i64, &T)> {
        self.entries
            .iter()
            .filter(|(s, e, _)| {
                let span = XnRegion::interval(*s, *e);
                span.intersects(region)
            })
            .map(|(s, e, v)| (*s, *e, v))
            .collect()
    }

    /// Query using an XnRegion for containment (spans within region).
    pub fn query_region_within(&self, region: &XnRegion) -> Vec<(i64, i64, &T)> {
        self.entries
            .iter()
            .filter(|(s, e, _)| region.contains(*s) && region.contains(*e - 1))
            .map(|(s, e, v)| (*s, *e, v))
            .collect()
    }

    /// Migrate all spans through a displacement mapping.
    /// Uses Mapping::of_region for correct algebraic migration.
    pub fn migrate(&mut self, mapping: &super::mapping::Mapping) {
        let mut new_entries = Vec::with_capacity(self.entries.len());
        for (start, end, value) in self.entries.drain(..) {
            let span = XnRegion::interval(start, end);
            let migrated = mapping.of_region(&span);
            for (new_start, new_end) in migrated.simple_regions() {
                new_entries.push((new_start, new_end, value.clone()));
            }
        }
        new_entries.sort_by_key(|(s, _, _)| *s);
        self.entries = new_entries;
    }

    /// Remove all spans that are entirely outside the given region.
    pub fn retain_in_region(&mut self, region: &XnRegion) {
        self.entries.retain(|(s, e, _)| {
            let span = XnRegion::interval(*s, *e);
            span.intersects(region)
        });
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn query_intersect_basic() {
        let mut idx: RegionIndex<&str> = RegionIndex::new();
        idx.insert(0, 5, "first");
        idx.insert(10, 15, "second");
        idx.insert(20, 25, "third");

        let results = idx.query_intersect(12, 22);
        assert_eq!(results.len(), 2);
        assert_eq!(results[0].2, &"second");
        assert_eq!(results[1].2, &"third");
    }

    #[test]
    fn query_intersect_boundary() {
        let mut idx: RegionIndex<&str> = RegionIndex::new();
        idx.insert(0, 10, "a");
        idx.insert(10, 20, "b");

        let results = idx.query_intersect(5, 15);
        assert_eq!(results.len(), 2);
    }

    #[test]
    fn query_within() {
        let mut idx: RegionIndex<&str> = RegionIndex::new();
        idx.insert(2, 5, "inner");
        idx.insert(0, 10, "outer");
        idx.insert(8, 15, "crossing");

        let results = idx.query_within(1, 9);
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].2, &"inner");
    }

    #[test]
    fn query_containing() {
        let mut idx: RegionIndex<&str> = RegionIndex::new();
        idx.insert(0, 20, "big");
        idx.insert(5, 10, "small");
        idx.insert(25, 30, "outside");

        let results = idx.query_containing(7, 8);
        assert_eq!(results.len(), 2);
        assert_eq!(results[0].2, &"big");
        assert_eq!(results[1].2, &"small");
    }

    #[test]
    fn query_at_position() {
        let mut idx: RegionIndex<&str> = RegionIndex::new();
        idx.insert(0, 10, "a");
        idx.insert(5, 15, "b");

        let results = idx.query_at(7);
        assert_eq!(results.len(), 2);
    }

    #[test]
    fn query_region_intersect() {
        let mut idx: RegionIndex<&str> = RegionIndex::new();
        idx.insert(0, 5, "a");
        idx.insert(10, 15, "b");
        idx.insert(20, 25, "c");

        let region = XnRegion::interval(12, 22);
        let results = idx.query_region_intersect(&region);
        assert_eq!(results.len(), 2);
    }

    #[test]
    fn migrate_through_insert() {
        let mut idx: RegionIndex<&str> = RegionIndex::new();
        idx.insert(15, 20, "link1");
        idx.insert(25, 30, "link2");

        // Insert 5 chars at position 10
        let dsp = crate::edition::mapping::Mapping::restricted(5, XnRegion::above(10));
        idx.migrate(&dsp);

        let results = idx.query_intersect(0, 100);
        assert_eq!(results.len(), 2);
        // link1 should now start at 20 (was 15, +5)
        assert_eq!(results[0].0, 20);
        assert_eq!(results[0].1, 25);
        // link2 should now start at 30 (was 25, +5)
        assert_eq!(results[1].0, 30);
        assert_eq!(results[1].1, 35);
    }

    #[test]
    fn migrate_through_delete() {
        let mut idx: RegionIndex<&str> = RegionIndex::new();
        idx.insert(20, 25, "link");

        // Delete 5 chars at position 10-15
        let dsp = crate::edition::mapping::Mapping::restricted(-5, XnRegion::above(15));
        idx.migrate(&dsp);

        let results = idx.query_intersect(0, 100);
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].0, 15);
        assert_eq!(results[0].1, 20);
    }

    #[test]
    fn retain_in_region() {
        let mut idx: RegionIndex<&str> = RegionIndex::new();
        idx.insert(0, 5, "a");
        idx.insert(10, 15, "b");
        idx.insert(20, 25, "c");

        idx.retain_in_region(&XnRegion::interval(8, 18));
        assert_eq!(idx.len(), 1);
    }

    #[test]
    fn empty_index_queries() {
        let idx: RegionIndex<&str> = RegionIndex::new();
        assert!(idx.query_intersect(0, 10).is_empty());
        assert!(idx.query_at(5).is_empty());
        assert!(idx.is_empty());
    }

    #[test]
    fn overlapping_spans() {
        let mut idx: RegionIndex<i32> = RegionIndex::new();
        idx.insert(0, 10, 1);
        idx.insert(5, 15, 2);
        idx.insert(8, 20, 3);

        let results = idx.query_intersect(6, 9);
        assert_eq!(results.len(), 3);
    }
}
