#[derive(Debug, Clone, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct XnRegion {
    starts_inside: bool,
    transitions: Vec<i64>,
}

impl XnRegion {
    pub fn empty() -> Self {
        XnRegion {
            starts_inside: false,
            transitions: Vec::new(),
        }
    }

    pub fn full() -> Self {
        XnRegion {
            starts_inside: true,
            transitions: Vec::new(),
        }
    }

    pub fn singleton(v: i64) -> Self {
        XnRegion {
            starts_inside: false,
            transitions: vec![v, v + 1],
        }
    }

    pub fn interval(start: i64, stop: i64) -> Self {
        if start >= stop {
            return Self::empty();
        }
        XnRegion {
            starts_inside: false,
            transitions: vec![start, stop],
        }
    }

    pub fn above(start: i64) -> Self {
        XnRegion {
            starts_inside: false,
            transitions: vec![start],
        }
    }

    pub fn below(stop: i64) -> Self {
        XnRegion {
            starts_inside: true,
            transitions: vec![stop],
        }
    }

    pub fn is_empty(&self) -> bool {
        !self.starts_inside && self.transitions.is_empty()
    }

    pub fn is_full(&self) -> bool {
        self.starts_inside && self.transitions.is_empty()
    }

    pub fn is_finite(&self) -> bool {
        if self.transitions.is_empty() {
            return !self.starts_inside;
        }
        if self.starts_inside {
            return self.transitions.len() % 2 == 0;
        }
        self.transitions.len() % 2 == 0
    }

    pub fn is_bounded(&self) -> bool {
        if self.is_empty() {
            return true;
        }
        if self.starts_inside {
            if self.transitions.len() % 2 == 1 {
                return false;
            }
            return self.transitions.last().map(|&l| l != i64::MAX).unwrap_or(false);
        }
        if self.transitions.len() < 2 {
            return false;
        }
        self.transitions.len() % 2 == 0
            && self.transitions.first().map(|&f| f != i64::MIN).unwrap_or(true)
            && self.transitions.last().map(|&l| l != i64::MAX).unwrap_or(true)
    }

    pub fn contains(&self, v: i64) -> bool {
        let num_flips = match self.transitions.binary_search_by(|t| t.cmp(&v)) {
            Ok(idx) => idx + 1,
            Err(idx) => idx,
        };
        if num_flips % 2 == 0 {
            self.starts_inside
        } else {
            !self.starts_inside
        }
    }

    pub fn start(&self) -> Option<i64> {
        if self.is_empty() {
            return None;
        }
        if self.starts_inside {
            return Some(i64::MIN);
        }
        self.transitions.first().copied()
    }

    pub fn stop(&self) -> Option<i64> {
        if self.is_empty() {
            return None;
        }
        if self.starts_inside && self.transitions.len() % 2 == 1 {
            return None;
        }
        if !self.starts_inside && self.transitions.len() % 2 == 1 {
            return None;
        }
        self.transitions.last().copied()
    }

    pub fn count(&self) -> Option<u64> {
        if !self.is_finite() {
            return None;
        }
        if self.is_empty() {
            return Some(0);
        }
        let mut total: u64 = 0;
        let mut inside = self.starts_inside;
        let mut prev: i64 = if inside { i64::MIN } else { 0 };
        for &t in &self.transitions {
            if inside {
                total = total.saturating_add((t.wrapping_sub(prev)) as u64);
            }
            prev = t;
            inside = !inside;
        }
        Some(total)
    }

    pub fn intervals(&self) -> Vec<(i64, i64)> {
        let mut result = Vec::new();
        let mut inside = self.starts_inside;
        let mut seg_start: i64 = 0;
        for &t in &self.transitions {
            if inside {
                result.push((seg_start, t));
            } else {
                seg_start = t;
            }
            inside = !inside;
        }
        result
    }

    pub fn intersect(&self, other: &XnRegion) -> XnRegion {
        let (starts_inside, transitions) =
            merge_transitions(self, other, |a, b| a && b);
        XnRegion {
            starts_inside,
            transitions,
        }
    }

    pub fn union(&self, other: &XnRegion) -> XnRegion {
        let (starts_inside, transitions) =
            merge_transitions(self, other, |a, b| a || b);
        XnRegion {
            starts_inside,
            transitions,
        }
    }

    pub fn minus(&self, other: &XnRegion) -> XnRegion {
        let (starts_inside, transitions) =
            merge_transitions(self, other, |a, b| a && !b);
        XnRegion {
            starts_inside,
            transitions,
        }
    }

    pub fn complement(&self) -> XnRegion {
        XnRegion {
            starts_inside: !self.starts_inside,
            transitions: self.transitions.clone(),
        }
    }

    pub fn with(&self, v: i64) -> XnRegion {
        if self.contains(v) {
            return self.clone();
        }
        self.union(&XnRegion::singleton(v))
    }

    pub fn without(&self, v: i64) -> XnRegion {
        if !self.contains(v) {
            return self.clone();
        }
        self.minus(&XnRegion::singleton(v))
    }

    pub fn is_subset_of(&self, other: &XnRegion) -> bool {
        self.minus(other).is_empty()
    }

    pub fn intersects(&self, other: &XnRegion) -> bool {
        !self.intersect(other).is_empty()
    }

    pub fn is_simple(&self) -> bool {
        if self.is_empty() {
            return true;
        }
        let ivs = self.intervals();
        ivs.len() <= 1
    }
}

impl Default for XnRegion {
    fn default() -> Self {
        Self::empty()
    }
}

fn merge_transitions(
    a: &XnRegion,
    b: &XnRegion,
    combine: impl Fn(bool, bool) -> bool,
) -> (bool, Vec<i64>) {
    let new_starts_inside = combine(a.starts_inside, b.starts_inside);
    let mut result = Vec::new();
    let mut ai = 0usize;
    let mut bi = 0usize;
    let mut a_inside = a.starts_inside;
    let mut b_inside = b.starts_inside;
    let mut cur = new_starts_inside;

    loop {
        let a_val = if ai < a.transitions.len() {
            Some(a.transitions[ai])
        } else {
            None
        };
        let b_val = if bi < b.transitions.len() {
            Some(b.transitions[bi])
        } else {
            None
        };

        let next_val = match (a_val, b_val) {
            (Some(av), Some(bv)) => Some(av.min(bv)),
            (Some(av), None) => Some(av),
            (None, Some(bv)) => Some(bv),
            (None, None) => None,
        };

        match next_val {
            None => break,
            Some(nv) => {
                if a_val == Some(nv) {
                    a_inside = !a_inside;
                    ai += 1;
                }
                if b_val == Some(nv) {
                    b_inside = !b_inside;
                    bi += 1;
                }
                let new_val = combine(a_inside, b_inside);
                if new_val != cur {
                    result.push(nv);
                    cur = new_val;
                }
            }
        }
    }

    (new_starts_inside, result)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_region_is_empty() {
        let r = XnRegion::empty();
        assert!(r.is_empty());
        assert!(!r.is_full());
        assert!(r.is_finite());
        assert_eq!(r.count(), Some(0));
        assert!(r.intervals().is_empty());
        assert!(!r.contains(0));
        assert!(!r.contains(-100));
        assert!(!r.contains(100));
    }

    #[test]
    fn full_region_is_full() {
        let r = XnRegion::full();
        assert!(r.is_full());
        assert!(!r.is_empty());
        assert!(r.contains(0));
        assert!(r.contains(i64::MAX));
        assert!(r.contains(i64::MIN));
    }

    #[test]
    fn singleton_contains_only_that_value() {
        let r = XnRegion::singleton(42);
        assert!(r.contains(42));
        assert!(!r.contains(41));
        assert!(!r.contains(43));
        assert!(r.is_finite());
        assert_eq!(r.count(), Some(1));
        assert_eq!(r.intervals(), vec![(42, 43)]);
    }

    #[test]
    fn interval_basic() {
        let r = XnRegion::interval(3, 7);
        assert!(r.contains(3));
        assert!(r.contains(6));
        assert!(!r.contains(7));
        assert!(!r.contains(2));
        assert!(r.is_finite());
        assert_eq!(r.count(), Some(4));
        assert_eq!(r.intervals(), vec![(3, 7)]);
    }

    #[test]
    fn interval_empty_when_start_ge_stop() {
        assert!(XnRegion::interval(5, 5).is_empty());
        assert!(XnRegion::interval(7, 3).is_empty());
    }

    #[test]
    fn above_contains_start_and_beyond() {
        let r = XnRegion::above(10);
        assert!(r.contains(10));
        assert!(r.contains(100));
        assert!(!r.contains(9));
    }

    #[test]
    fn below_contains_up_to_stop() {
        let r = XnRegion::below(10);
        assert!(r.contains(9));
        assert!(r.contains(0));
        assert!(!r.contains(10));
    }

    #[test]
    fn intersect_two_intervals() {
        let a = XnRegion::interval(3, 10);
        let b = XnRegion::interval(7, 15);
        let c = a.intersect(&b);
        assert_eq!(c.intervals(), vec![(7, 10)]);
        assert_eq!(c.count(), Some(3));
    }

    #[test]
    fn intersect_disjoint_is_empty() {
        let a = XnRegion::interval(0, 5);
        let b = XnRegion::interval(10, 15);
        assert!(a.intersect(&b).is_empty());
    }

    #[test]
    fn union_two_intervals() {
        let a = XnRegion::interval(3, 7);
        let b = XnRegion::interval(10, 15);
        let c = a.union(&b);
        assert_eq!(c.intervals(), vec![(3, 7), (10, 15)]);
        assert_eq!(c.count(), Some(9));
    }

    #[test]
    fn union_overlapping_merges() {
        let a = XnRegion::interval(3, 8);
        let b = XnRegion::interval(6, 12);
        let c = a.union(&b);
        assert_eq!(c.intervals(), vec![(3, 12)]);
    }

    #[test]
    fn minus_subtracts() {
        let a = XnRegion::interval(0, 20);
        let b = XnRegion::interval(5, 10);
        let c = a.minus(&b);
        assert_eq!(c.intervals(), vec![(0, 5), (10, 20)]);
    }

    #[test]
    fn complement_flips() {
        let r = XnRegion::interval(3, 7);
        let c = r.complement();
        assert!(!c.contains(4));
        assert!(c.contains(0));
        assert!(c.contains(7));
    }

    #[test]
    fn with_adds_value() {
        let r = XnRegion::interval(3, 7);
        let r2 = r.with(10);
        assert!(r2.contains(10));
        assert!(r2.contains(4));
    }

    #[test]
    fn without_removes_value() {
        let r = XnRegion::interval(3, 7);
        let r2 = r.without(5);
        assert!(!r2.contains(5));
        assert!(r2.contains(4));
        assert!(r2.contains(6));
    }

    #[test]
    fn is_subset_of() {
        let a = XnRegion::interval(3, 7);
        let b = XnRegion::interval(0, 10);
        assert!(a.is_subset_of(&b));
        assert!(!b.is_subset_of(&a));
    }

    #[test]
    fn is_simple() {
        assert!(XnRegion::empty().is_simple());
        assert!(XnRegion::interval(3, 7).is_simple());
        let multi = XnRegion::interval(3, 7).union(&XnRegion::interval(10, 15));
        assert!(!multi.is_simple());
    }

    #[test]
    fn intersects() {
        let a = XnRegion::interval(3, 7);
        let b = XnRegion::interval(6, 10);
        let c = XnRegion::interval(10, 15);
        assert!(a.intersects(&b));
        assert!(!a.intersects(&c));
    }

    #[test]
    fn start_stop() {
        let r = XnRegion::interval(3, 7);
        assert_eq!(r.start(), Some(3));
        assert_eq!(r.stop(), Some(7));
        assert!(XnRegion::empty().start().is_none());
    }

    #[test]
    fn triple_union_collapses_adjacent() {
        let a = XnRegion::interval(3, 7);
        let b = XnRegion::interval(7, 10);
        let c = XnRegion::interval(10, 15);
        let merged = a.union(&b).union(&c);
        assert_eq!(merged.intervals(), vec![(3, 15)]);
    }

    #[test]
    fn complement_intersect_roundtrip() {
        let a = XnRegion::interval(3, 7);
        let b = XnRegion::interval(5, 10);
        let diff = a.minus(&b);
        assert_eq!(diff.intervals(), vec![(3, 5)]);
    }

    #[test]
    fn double_complement_is_identity() {
        let r = XnRegion::interval(3, 7).union(&XnRegion::interval(10, 15));
        let rc = r.complement().complement();
        assert_eq!(r, rc);
    }

    #[test]
    fn de_morgan_intersect() {
        let a = XnRegion::interval(3, 7);
        let b = XnRegion::interval(5, 10);
        let lhs = a.intersect(&b);
        let rhs = a.complement().union(&b.complement()).complement();
        assert_eq!(lhs, rhs);
    }

    #[test]
    fn above_minus_interval() {
        let a = XnRegion::above(0);
        let b = XnRegion::interval(5, 10);
        let c = a.minus(&b);
        assert!(c.contains(0));
        assert!(c.contains(4));
        assert!(!c.contains(7));
        assert!(c.contains(10));
    }

    #[test]
    fn full_minus_interval() {
        let full = XnRegion::full();
        let iv = XnRegion::interval(3, 7);
        let c = full.minus(&iv);
        assert!(!c.contains(4));
        assert!(c.contains(0));
        assert!(c.contains(7));
    }

    #[test]
    fn union_with_complement_is_full() {
        let r = XnRegion::interval(3, 7);
        let u = r.union(&r.complement());
        assert!(u.is_full());
    }

    #[test]
    fn empty_operations_identity() {
        let e = XnRegion::empty();
        let r = XnRegion::interval(3, 7);
        assert_eq!(r.intersect(&e), e);
        assert_eq!(r.union(&e), r);
        assert_eq!(r.minus(&e), r);
        assert_eq!(e.minus(&r), e);
    }

    #[test]
    fn serde_round_trip() {
        #[cfg(feature = "serde")]
        {
            let r = XnRegion::interval(3, 7).union(&XnRegion::interval(10, 15));
            let json = serde_json::to_string(&r).unwrap();
            let r2: XnRegion = serde_json::from_str(&json).unwrap();
            assert_eq!(r, r2);
        }
    }

    fn example_regions() -> Vec<(&'static str, XnRegion)> {
        vec![
            ("empty", XnRegion::empty()),
            ("full", XnRegion::full()),
            ("interval(3,7)", XnRegion::interval(3, 7)),
            ("complement_of_interval(3,7)", XnRegion::interval(3, 7).complement()),
            ("above(5)", XnRegion::above(5)),
            ("below(5)", XnRegion::below(5)),
        ]
    }

    #[test]
    fn gold_unary_checks_all_example_regions() {
        for (name, a) in example_regions() {
            assert_eq!(a, a, "identity failed for {name}");
            assert_eq!(a.intersects(&a), !a.is_empty(), "self-intersects for {name}");
            assert!(a.minus(&a).is_empty(), "self-minus for {name}");
            assert!(a.is_subset_of(&a), "self-subset for {name}");
            assert_eq!(a.intersect(&a), a, "self-intersect identity for {name}");
            assert_eq!(a.is_full(), a.complement().is_empty(), "full/complement for {name}");
            assert!(a.intersect(&a.complement()).is_empty(), "intersect complement for {name}");
            assert_eq!(a.minus(&a.complement()), a, "minus complement for {name}");
            assert_eq!(a.complement().complement(), a, "double complement for {name}");
            assert!(a.union(&a.complement()).is_full(), "union complement for {name}");
        }
    }

    #[test]
    fn gold_binary_checks_all_example_region_pairs() {
        let examples = example_regions();
        for (i, (name_a, a)) in examples.iter().enumerate() {
            for (name_b, b) in examples.iter().skip(i) {
                assert_eq!(a.intersect(b), b.intersect(a), "intersect commutativity {name_a} vs {name_b}");
                assert!(a.intersect(b).is_subset_of(a), "intersect subset a {name_a} vs {name_b}");
                assert!(a.intersect(b).is_subset_of(b), "intersect subset b {name_a} vs {name_b}");
                assert_eq!(a.intersects(b), !a.intersect(b).is_empty(), "intersects consistency {name_a} vs {name_b}");
                assert!(!a.minus(b).intersects(b), "minus disjoint {name_a} vs {name_b}");
                assert!(a.minus(b).is_subset_of(a), "minus subset {name_a} vs {name_b}");
                assert_eq!(a.union(b), b.union(a), "union commutativity {name_a} vs {name_b}");
                assert!(a.is_subset_of(&a.union(b)), "union superset a {name_a} vs {name_b}");
                assert!(b.is_subset_of(&a.union(b)), "union superset b {name_a} vs {name_b}");
                assert_eq!(a.is_subset_of(b) && b.is_subset_of(a), *a == *b, "subset=equality {name_a} vs {name_b}");
            }
        }
    }
}
