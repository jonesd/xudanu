use std::collections::{BTreeMap, BTreeSet};
use std::sync::Arc;

use super::range_element::Carrier;
use super::xn_region::XnRegion;

#[derive(Debug, Clone, PartialEq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct SharedMapping {
    pairs: Vec<(i64, i64)>,
}

impl SharedMapping {
    pub fn empty() -> Self {
        SharedMapping { pairs: Vec::new() }
    }

    pub fn from_pairs(pairs: Vec<(i64, i64)>) -> Self {
        let mut p = pairs;
        p.sort_by_key(|(k, _)| *k);
        SharedMapping { pairs: p }
    }

    pub fn domain(&self) -> XnRegion {
        let mut region = XnRegion::empty();
        for (pos, _) in &self.pairs {
            region = region.with(*pos);
        }
        region
    }

    pub fn range(&self) -> XnRegion {
        let mut region = XnRegion::empty();
        for (_, pos) in &self.pairs {
            region = region.with(*pos);
        }
        region
    }

    pub fn pairs(&self) -> &[(i64, i64)] {
        &self.pairs
    }

    pub fn of(&self, pos: i64) -> Option<i64> {
        let idx = self.pairs.binary_search_by_key(&pos, |(k, _)| *k).ok()?;
        Some(self.pairs[idx].1)
    }

    pub fn len(&self) -> usize {
        self.pairs.len()
    }

    pub fn is_empty(&self) -> bool {
        self.pairs.is_empty()
    }
}

pub fn content_shared_region(
    my_entries: &[(i64, Arc<Carrier>)],
    other_entries: &[(i64, Arc<Carrier>)],
) -> XnRegion {
    let other_fingerprints: BTreeSet<[u8; 8]> = other_entries
        .iter()
        .map(|(_, c)| {
            let bytes = c.element.content_fingerprint();
            let mut arr = [0u8; 8];
            arr.copy_from_slice(&bytes[..8]);
            arr
        })
        .collect();

    let mut region = XnRegion::empty();
    for (pos, carrier) in my_entries {
        let bytes = carrier.element.content_fingerprint();
        let mut arr = [0u8; 8];
        arr.copy_from_slice(&bytes[..8]);
        if other_fingerprints.contains(&arr) {
            region = region.with(*pos);
        }
    }
    region
}

pub fn content_map_shared_to(
    my_entries: &[(i64, Arc<Carrier>)],
    other_entries: &[(i64, Arc<Carrier>)],
) -> SharedMapping {
    let mut by_fingerprint: BTreeMap<[u8; 8], Vec<i64>> = BTreeMap::new();
    for (pos, carrier) in other_entries {
        let bytes = carrier.element.content_fingerprint();
        let mut arr = [0u8; 8];
        arr.copy_from_slice(&bytes[..8]);
        by_fingerprint.entry(arr).or_default().push(*pos);
    }

    let mut pairs = Vec::new();
    for (pos, carrier) in my_entries {
        let bytes = carrier.element.content_fingerprint();
        let mut arr = [0u8; 8];
        arr.copy_from_slice(&bytes[..8]);
        if let Some(other_positions) = by_fingerprint.get(&arr) {
            for &other_pos in other_positions {
                pairs.push((*pos, other_pos));
            }
        }
    }

    SharedMapping::from_pairs(pairs)
}

pub fn content_map_shared_onto(
    my_entries: &[(i64, Arc<Carrier>)],
    other_entries: &[(i64, Arc<Carrier>)],
) -> SharedMapping {
    let mut by_fingerprint: BTreeMap<[u8; 8], Vec<i64>> = BTreeMap::new();
    for (pos, carrier) in other_entries {
        let bytes = carrier.element.content_fingerprint();
        let mut arr = [0u8; 8];
        arr.copy_from_slice(&bytes[..8]);
        by_fingerprint.entry(arr).or_default().push(*pos);
    }

    let mut used_targets: BTreeSet<i64> = BTreeSet::new();
    let mut pairs = Vec::new();

    for (pos, carrier) in my_entries {
        let bytes = carrier.element.content_fingerprint();
        let mut arr = [0u8; 8];
        arr.copy_from_slice(&bytes[..8]);
        if let Some(other_positions) = by_fingerprint.get(&arr) {
            for &other_pos in other_positions {
                if used_targets.insert(other_pos) {
                    pairs.push((*pos, other_pos));
                    break;
                }
            }
        }
    }

    SharedMapping::from_pairs(pairs)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::RangeElement;

    fn make_entries(texts: &[&str]) -> Vec<(i64, Arc<Carrier>)> {
        texts
            .iter()
            .enumerate()
            .map(|(i, t)| {
                (
                    i as i64,
                    Arc::new(Carrier::new(RangeElement::text(t.to_string()))),
                )
            })
            .collect()
    }

    #[test]
    fn shared_mapping_empty() {
        let m = SharedMapping::empty();
        assert!(m.is_empty());
        assert_eq!(m.domain(), XnRegion::empty());
        assert_eq!(m.range(), XnRegion::empty());
    }

    #[test]
    fn shared_mapping_from_pairs() {
        let m = SharedMapping::from_pairs(vec![(5, 10), (3, 6)]);
        assert_eq!(m.of(3), Some(6));
        assert_eq!(m.of(5), Some(10));
        assert_eq!(m.of(4), None);
        assert_eq!(m.len(), 2);
    }

    #[test]
    fn content_shared_region_overlap() {
        let a = make_entries(&["x", "y", "z"]);
        let b = make_entries(&["a", "y", "b", "z"]);
        let region = content_shared_region(&a, &b);
        assert!(region.contains(1)); // y
        assert!(region.contains(2)); // z
        assert!(!region.contains(0)); // x not in b
    }

    #[test]
    fn content_shared_region_no_overlap() {
        let a = make_entries(&["x", "y"]);
        let b = make_entries(&["a", "b"]);
        let region = content_shared_region(&a, &b);
        assert!(region.is_empty());
    }

    #[test]
    fn content_map_shared_to_basic() {
        let a = make_entries(&["x", "y", "z"]);
        let b = make_entries(&["a", "y", "b", "z"]);
        let m = content_map_shared_to(&a, &b);
        assert!(m.len() >= 2);
        assert!(m.of(1).is_some()); // y -> 1
        assert!(m.of(2).is_some()); // z -> 3
    }

    #[test]
    fn content_map_shared_to_multiple_matches() {
        let a = make_entries(&["x"]);
        let b = make_entries(&["x", "x"]);
        let m = content_map_shared_to(&a, &b);
        assert_eq!(m.len(), 2); // position 0 in a maps to both 0 and 1 in b
    }

    #[test]
    fn content_map_shared_onto_is_injective() {
        let a = make_entries(&["x", "x", "y"]);
        let b = make_entries(&["x", "y"]);
        let m = content_map_shared_onto(&a, &b);
        let targets: BTreeSet<i64> = m.pairs().iter().map(|(_, t)| *t).collect();
        assert_eq!(
            targets.len(),
            m.len(),
            "each target should appear at most once"
        );
    }

    #[test]
    fn content_map_shared_onto_covers_all_targets() {
        let a = make_entries(&["x", "y"]);
        let b = make_entries(&["x", "y"]);
        let m = content_map_shared_onto(&a, &b);
        assert_eq!(m.len(), 2);
    }

    #[test]
    fn content_map_shared_onto_empty() {
        let a = make_entries(&["x"]);
        let b = make_entries(&["y"]);
        let m = content_map_shared_onto(&a, &b);
        assert!(m.is_empty());
    }

    #[test]
    fn shared_mapping_domain_range() {
        let m = SharedMapping::from_pairs(vec![(0, 10), (1, 20), (3, 30)]);
        let domain = m.domain();
        assert!(domain.contains(0));
        assert!(domain.contains(1));
        assert!(domain.contains(3));
        assert!(!domain.contains(2));

        let range = m.range();
        assert!(range.contains(10));
        assert!(range.contains(20));
        assert!(range.contains(30));
    }

    #[test]
    fn content_shared_region_with_placeholders() {
        let a = vec![
            (0, Arc::new(Carrier::new(RangeElement::placeholder(1)))),
            (1, Arc::new(Carrier::new(RangeElement::text("x")))),
        ];
        let b = vec![
            (0, Arc::new(Carrier::new(RangeElement::placeholder(1)))),
            (1, Arc::new(Carrier::new(RangeElement::text("y")))),
        ];
        let region = content_shared_region(&a, &b);
        assert!(region.contains(0)); // same placeholder ID
        assert!(!region.contains(1)); // x != y
    }

    #[test]
    fn content_map_shared_onto_more_sources_than_targets() {
        let a = make_entries(&["x", "x", "x"]);
        let b = make_entries(&["x"]);
        let m = content_map_shared_onto(&a, &b);
        assert_eq!(m.len(), 1); // only one can map onto the single target
    }
}
