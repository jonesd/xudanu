use std::collections::BTreeMap;

use super::range_element::{Carrier, RangeElement};
use super::xn_region::XnRegion;

#[derive(Debug, Clone, PartialEq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct Edition {
    entries: BTreeMap<i64, Carrier>,
}

impl Edition {
    pub fn empty() -> Self {
        Edition {
            entries: BTreeMap::new(),
        }
    }

    pub fn from_one(position: i64, value: RangeElement) -> Self {
        let mut entries = BTreeMap::new();
        entries.insert(position, Carrier::new(value));
        Edition { entries }
    }

    pub fn from_all(region: &XnRegion, value: RangeElement) -> Self {
        let mut entries = BTreeMap::new();
        for (start, stop) in region.intervals() {
            for pos in start..stop {
                entries.insert(pos, Carrier::new(value.clone()));
            }
        }
        Edition { entries }
    }

    pub fn from_text(text: &str) -> Self {
        let mut entries = BTreeMap::new();
        for (i, ch) in text.chars().enumerate() {
            let mut buf = [0u8; 4];
            let s = ch.encode_utf8(&mut buf);
            entries.insert(i as i64, Carrier::new(RangeElement::text(s.to_string())));
        }
        Edition { entries }
    }

    pub fn from_text_elements(elements: &[RangeElement]) -> Self {
        let mut entries = BTreeMap::new();
        for (i, e) in elements.iter().enumerate() {
            entries.insert(i as i64, Carrier::new(e.clone()));
        }
        Edition { entries }
    }

    pub fn place_holders(region: &XnRegion) -> Self {
        let mut entries = BTreeMap::new();
        let mut next_id = 0u64;
        for (start, stop) in region.intervals() {
            for pos in start..stop {
                entries.insert(
                    pos,
                    Carrier::new(RangeElement::placeholder(next_id)),
                );
                next_id += 1;
            }
        }
        Edition { entries }
    }

    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }

    pub fn count(&self) -> u64 {
        self.entries.len() as u64
    }

    pub fn domain(&self) -> XnRegion {
        if self.entries.is_empty() {
            return XnRegion::empty();
        }
        let mut region = XnRegion::empty();
        for &pos in self.entries.keys() {
            region = region.with(pos);
        }
        region
    }

    pub fn fetch(&self, position: i64) -> Option<&RangeElement> {
        self.entries.get(&position).map(|c| &c.element)
    }

    pub fn get(&self, position: i64) -> &RangeElement {
        self.entries
            .get(&position)
            .map(|c| &c.element)
            .expect("position not in edition")
    }

    pub fn has_position(&self, position: i64) -> bool {
        self.entries.contains_key(&position)
    }

    pub fn carrier_at(&self, position: i64) -> Option<&Carrier> {
        self.entries.get(&position)
    }

    pub fn with(&self, position: i64, value: RangeElement) -> Self {
        let mut new = self.clone();
        new.entries.insert(position, Carrier::new(value));
        new
    }

    pub fn with_all(&self, region: &XnRegion, value: RangeElement) -> Self {
        let mut new = self.clone();
        for (start, stop) in region.intervals() {
            for pos in start..stop {
                new.entries.insert(pos, Carrier::new(value.clone()));
            }
        }
        new
    }

    pub fn without(&self, position: i64) -> Self {
        let mut new = self.clone();
        new.entries.remove(&position);
        new
    }

    pub fn without_all(&self, region: &XnRegion) -> Self {
        let new_entries: BTreeMap<i64, Carrier> = self
            .entries
            .iter()
            .filter(|(&pos, _)| !region.contains(pos))
            .map(|(&pos, c)| (pos, c.clone()))
            .collect();
        Edition {
            entries: new_entries,
        }
    }

    pub fn combine(&self, other: &Edition) -> Result<Edition, CombineConflict> {
        let mut new = self.clone();
        for (&pos, carrier) in &other.entries {
            if let Some(existing) = new.entries.get(&pos) {
                if existing.element != carrier.element {
                    return Err(CombineConflict {
                        position: pos,
                        left: existing.element.clone(),
                        right: carrier.element.clone(),
                    });
                }
            } else {
                new.entries.insert(pos, carrier.clone());
            }
        }
        Ok(new)
    }

    pub fn replace(&self, other: &Edition) -> Edition {
        let mut new = self.clone();
        for (&pos, carrier) in &other.entries {
            new.entries.insert(pos, carrier.clone());
        }
        new
    }

    pub fn copy(&self, region: &XnRegion) -> Edition {
        let mut new_entries = BTreeMap::new();
        for (&pos, carrier) in &self.entries {
            if region.contains(pos) {
                new_entries.insert(pos, carrier.clone());
            }
        }
        Edition {
            entries: new_entries,
        }
    }

    pub fn transformed_by(&self, offset: i64) -> Edition {
        let mut new_entries = BTreeMap::new();
        for (&pos, carrier) in &self.entries {
            new_entries.insert(pos + offset, carrier.clone());
        }
        Edition {
            entries: new_entries,
        }
    }

    pub fn iter(&self) -> impl Iterator<Item = (&i64, &Carrier)> {
        self.entries.iter()
    }

    pub fn entries(&self) -> &BTreeMap<i64, Carrier> {
        &self.entries
    }

    pub fn to_text(&self) -> String {
        let mut result = String::new();
        for i in 0..self.count() as i64 {
            if let Some(elem) = self.fetch(i) {
                if let Some(s) = elem.as_text() {
                    result.push_str(s);
                }
            }
        }
        result
    }

    pub fn shared_region(&self, other: &Edition) -> XnRegion {
        let mut shared = XnRegion::empty();
        for (&pos, carrier) in &self.entries {
            if let Some(other_carrier) = other.entries.get(&pos) {
                if carrier.element == other_carrier.element {
                    shared = shared.with(pos);
                }
            }
        }
        shared
    }

    pub fn shared_with(&self, other: &Edition) -> Edition {
        let mut new_entries = BTreeMap::new();
        for (&pos, carrier) in &self.entries {
            if let Some(other_carrier) = other.entries.get(&pos) {
                if carrier.element == other_carrier.element {
                    new_entries.insert(pos, carrier.clone());
                }
            }
        }
        Edition {
            entries: new_entries,
        }
    }

    pub fn not_shared_with(&self, other: &Edition) -> Edition {
        let mut new_entries = BTreeMap::new();
        for (&pos, carrier) in &self.entries {
            match other.entries.get(&pos) {
                None => {
                    new_entries.insert(pos, carrier.clone());
                }
                Some(other_carrier) => {
                    if carrier.element != other_carrier.element {
                        new_entries.insert(pos, carrier.clone());
                    }
                }
            }
        }
        Edition {
            entries: new_entries,
        }
    }

    pub fn map_shared_to(&self, other: &Edition) -> BTreeMap<i64, i64> {
        let mut mapping = BTreeMap::new();
        for (&pos, carrier) in &self.entries {
            for (&other_pos, other_carrier) in &other.entries {
                if carrier.element == other_carrier.element {
                    mapping.insert(pos, other_pos);
                }
            }
        }
        mapping
    }

    pub fn positions_of(&self, value: &RangeElement) -> XnRegion {
        let mut region = XnRegion::empty();
        for (&pos, carrier) in &self.entries {
            if &carrier.element == value {
                region = region.with(pos);
            }
        }
        region
    }

    pub fn is_range_identical(&self, other: &Edition, region: Option<&XnRegion>) -> bool {
        let dom = match region {
            Some(r) => r.clone(),
            None => self.domain().union(&other.domain()),
        };
        for (start, stop) in dom.intervals() {
            for pos in start..stop {
                let a = self.fetch(pos);
                let b = other.fetch(pos);
                if a != b {
                    return false;
                }
            }
        }
        true
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

    #[test]
    fn empty_edition() {
        let e = Edition::empty();
        assert!(e.is_empty());
        assert_eq!(e.count(), 0);
        assert!(e.domain().is_empty());
        assert!(e.fetch(0).is_none());
    }

    #[test]
    fn from_one() {
        let e = Edition::from_one(5, RangeElement::text("x"));
        assert!(!e.is_empty());
        assert_eq!(e.count(), 1);
        assert!(e.has_position(5));
        assert!(!e.has_position(4));
        assert_eq!(e.fetch(5).unwrap().as_text(), Some("x"));
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
        assert_eq!(e.fetch(0).unwrap().as_text(), Some("a"));
        assert_eq!(e.fetch(1).unwrap().as_text(), Some("b"));
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
            assert_eq!(e.fetch(i).unwrap().as_text(), Some("x"));
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
        assert_eq!(c.fetch(0).unwrap().as_text(), Some("a"));
        assert_eq!(c.fetch(1).unwrap().as_text(), Some("b"));
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
        assert_eq!(shared.fetch(1).unwrap().as_text(), Some("b"));
        assert_eq!(shared.fetch(2).unwrap().as_text(), Some("c"));
    }

    #[test]
    fn not_shared_with_returns_differences() {
        let a = Edition::from_text("abc");
        let b = Edition::from_text("xbc");
        let diff = a.not_shared_with(&b);
        assert_eq!(diff.count(), 1);
        assert_eq!(diff.fetch(0).unwrap().as_text(), Some("a"));
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
        assert_eq!(e.fetch(0).unwrap().as_text(), Some("a"));
    }

    #[test]
    fn from_all_creates_uniform() {
        let region = XnRegion::interval(0, 4);
        let e = Edition::from_all(&region, RangeElement::text("z"));
        for i in 0..4 {
            assert_eq!(e.fetch(i).unwrap().as_text(), Some("z"));
        }
    }

    #[test]
    fn serde_round_trip() {
        #[cfg(feature = "serde")]
        {
            let e = Edition::from_text("hello");
            let json = serde_json::to_string(&e).unwrap();
            let e2: Edition = serde_json::from_str(&json).unwrap();
            assert_eq!(e, e2);
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
}
