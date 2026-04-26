use super::traits::*;
use crate::edition::xn_region::XnRegion;

#[derive(Debug, Clone, PartialEq, Eq, Hash, Default)]
pub struct IntegerSpace;

impl IntegerSpace {
    pub fn new() -> Self {
        IntegerSpace
    }

    pub fn position(&self, value: i64) -> IntegerPos {
        IntegerPos(value)
    }

    pub fn interval(&self, start: i64, stop: i64) -> IntegerRegion {
        IntegerRegion::interval(start, stop)
    }

    pub fn above(&self, start: i64, inclusive: bool) -> IntegerRegion {
        IntegerRegion::above(if inclusive { start } else { start + 1 })
    }

    pub fn below(&self, stop: i64, inclusive: bool) -> IntegerRegion {
        IntegerRegion::below(if inclusive { stop + 1 } else { stop })
    }

    pub fn translation(&self, offset: i64) -> IntegerDsp {
        IntegerDsp(offset)
    }
}

impl Space for IntegerSpace {
    type Position = IntegerPos;
    type Region = IntegerRegion;
    type Dsp = IntegerDsp;

    fn empty_region(&self) -> Self::Region {
        IntegerRegion::empty()
    }

    fn full_region(&self) -> Self::Region {
        IntegerRegion::full()
    }

    fn identity_dsp(&self) -> Self::Dsp {
        IntegerDsp(0)
    }

    fn ascending(&self) -> Box<dyn OrderSpec<Position = Self::Position>> {
        Box::new(IntegerAscending)
    }

    fn descending(&self) -> Box<dyn OrderSpec<Position = Self::Position>> {
        Box::new(IntegerDescending)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct IntegerPos(pub i64);

impl IntegerPos {
    pub fn value(&self) -> i64 {
        self.0
    }
}

impl Position for IntegerPos {
    type Region = IntegerRegion;

    fn as_region(&self) -> Self::Region {
        IntegerRegion::singleton(self.0)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct IntegerRegion {
    inner: XnRegion,
}

impl IntegerRegion {
    pub fn empty() -> Self {
        IntegerRegion {
            inner: XnRegion::empty(),
        }
    }

    pub fn full() -> Self {
        IntegerRegion {
            inner: XnRegion::full(),
        }
    }

    pub fn singleton(v: i64) -> Self {
        IntegerRegion {
            inner: XnRegion::singleton(v),
        }
    }

    pub fn interval(start: i64, stop: i64) -> Self {
        IntegerRegion {
            inner: XnRegion::interval(start, stop),
        }
    }

    pub fn above(start: i64) -> Self {
        IntegerRegion {
            inner: XnRegion::above(start),
        }
    }

    pub fn below(stop: i64) -> Self {
        IntegerRegion {
            inner: XnRegion::below(stop),
        }
    }

    pub fn start(&self) -> Option<i64> {
        self.inner.start()
    }

    pub fn stop(&self) -> Option<i64> {
        self.inner.stop()
    }

    pub fn intervals(&self) -> Vec<(i64, i64)> {
        self.inner.intervals()
    }

    pub fn contains_value(&self, v: i64) -> bool {
        self.inner.contains(v)
    }
}

impl Default for IntegerRegion {
    fn default() -> Self {
        Self::empty()
    }
}

impl Region for IntegerRegion {
    type Position = IntegerPos;

    fn is_empty(&self) -> bool {
        self.inner.is_empty()
    }

    fn is_full(&self) -> bool {
        self.inner.is_full()
    }

    fn contains(&self, pos: &Self::Position) -> bool {
        self.inner.contains(pos.0)
    }

    fn intersects(&self, other: &Self) -> bool {
        self.inner.intersects(&other.inner)
    }

    fn intersect(&self, other: &Self) -> Self {
        IntegerRegion {
            inner: self.inner.intersect(&other.inner),
        }
    }

    fn union_with(&self, other: &Self) -> Self {
        IntegerRegion {
            inner: self.inner.union(&other.inner),
        }
    }

    fn complement(&self) -> Self {
        IntegerRegion {
            inner: self.inner.complement(),
        }
    }

    fn minus(&self, other: &Self) -> Self {
        IntegerRegion {
            inner: self.inner.minus(&other.inner),
        }
    }

    fn is_simple(&self) -> bool {
        self.inner.is_simple()
    }

    fn count(&self) -> Option<usize> {
        self.inner.count().map(|c| c as usize)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct IntegerDsp(pub i64);

impl IntegerDsp {
    pub fn offset(&self) -> i64 {
        self.0
    }

    pub fn is_identity(&self) -> bool {
        self.0 == 0
    }
}

impl Dsp for IntegerDsp {
    type Position = IntegerPos;
    type Region = IntegerRegion;

    fn of(&self, pos: &Self::Position) -> Self::Position {
        IntegerPos(pos.0.wrapping_add(self.0))
    }

    fn of_all(&self, region: &Self::Region) -> Self::Region {
        IntegerRegion {
            inner: region.inner.shift(self.0),
        }
    }

    fn inverse(&self) -> Self {
        IntegerDsp(self.0.wrapping_neg())
    }

    fn compose(&self, other: &Self) -> Self {
        IntegerDsp(self.0.wrapping_add(other.0))
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IntegerAscending;

impl OrderSpec for IntegerAscending {
    type Position = IntegerPos;

    fn follows(&self, a: &Self::Position, b: &Self::Position) -> bool {
        a.0 >= b.0
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IntegerDescending;

impl OrderSpec for IntegerDescending {
    type Position = IntegerPos;

    fn follows(&self, a: &Self::Position, b: &Self::Position) -> bool {
        a.0 <= b.0
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn space() -> IntegerSpace {
        IntegerSpace::new()
    }

    #[test]
    fn space_factory_empty() {
        let s = space();
        let r = s.empty_region();
        assert!(r.is_empty());
        assert!(!r.is_full());
        assert_eq!(r.count(), Some(0));
    }

    #[test]
    fn space_factory_full() {
        let s = space();
        let r = s.full_region();
        assert!(r.is_full());
        assert!(!r.is_empty());
    }

    #[test]
    fn space_factory_identity_dsp() {
        let s = space();
        let d = s.identity_dsp();
        assert!(d.is_identity());
        let p = s.position(42);
        assert_eq!(d.of(&p), p);
    }

    #[test]
    fn space_factory_interval() {
        let s = space();
        let r = s.interval(3, 7);
        assert!(r.contains(&IntegerPos(3)));
        assert!(r.contains(&IntegerPos(6)));
        assert!(!r.contains(&IntegerPos(7)));
        assert!(!r.contains(&IntegerPos(2)));
        assert_eq!(r.count(), Some(4));
    }

    #[test]
    fn space_factory_above_below() {
        let s = space();
        let above_inc = s.above(10, true);
        assert!(above_inc.contains(&IntegerPos(10)));
        assert!(!above_inc.contains(&IntegerPos(9)));

        let above_exc = s.above(10, false);
        assert!(!above_exc.contains(&IntegerPos(10)));
        assert!(above_exc.contains(&IntegerPos(11)));

        let below_inc = s.below(10, true);
        assert!(below_inc.contains(&IntegerPos(10)));
        assert!(!below_inc.contains(&IntegerPos(11)));

        let below_exc = s.below(10, false);
        assert!(!below_exc.contains(&IntegerPos(10)));
        assert!(below_exc.contains(&IntegerPos(9)));
    }

    #[test]
    fn pos_value_and_as_region() {
        let p = IntegerPos(42);
        assert_eq!(p.value(), 42);
        let r = p.as_region();
        assert!(r.contains(&p));
        assert!(!r.contains(&IntegerPos(41)));
        assert!(!r.contains(&IntegerPos(43)));
        assert_eq!(r.count(), Some(1));
    }

    #[test]
    fn region_empty() {
        let r = IntegerRegion::empty();
        assert!(r.is_empty());
        assert!(!r.is_full());
        assert!(r.is_simple());
        assert_eq!(r.count(), Some(0));
        assert!(!r.contains(&IntegerPos(0)));
        assert_eq!(r.intervals(), vec![]);
    }

    #[test]
    fn region_full() {
        let r = IntegerRegion::full();
        assert!(r.is_full());
        assert!(!r.is_empty());
        assert!(r.contains(&IntegerPos(0)));
        assert!(r.contains(&IntegerPos(i64::MIN)));
        assert!(r.contains(&IntegerPos(i64::MAX)));
    }

    #[test]
    fn region_singleton() {
        let r = IntegerRegion::singleton(42);
        assert!(r.contains(&IntegerPos(42)));
        assert!(!r.contains(&IntegerPos(41)));
        assert!(!r.contains(&IntegerPos(43)));
        assert!(r.is_simple());
        assert_eq!(r.count(), Some(1));
        assert_eq!(r.intervals(), vec![(42, 43)]);
    }

    #[test]
    fn region_interval() {
        let r = IntegerRegion::interval(3, 7);
        assert!(r.contains(&IntegerPos(3)));
        assert!(r.contains(&IntegerPos(6)));
        assert!(!r.contains(&IntegerPos(7)));
        assert!(!r.contains(&IntegerPos(2)));
        assert!(r.is_simple());
        assert_eq!(r.count(), Some(4));
        assert_eq!(r.start(), Some(3));
        assert_eq!(r.stop(), Some(7));
    }

    #[test]
    fn region_interval_empty_when_inverted() {
        assert!(IntegerRegion::interval(5, 5).is_empty());
        assert!(IntegerRegion::interval(7, 3).is_empty());
    }

    #[test]
    fn region_above() {
        let r = IntegerRegion::above(10);
        assert!(r.contains(&IntegerPos(10)));
        assert!(r.contains(&IntegerPos(100)));
        assert!(!r.contains(&IntegerPos(9)));
        assert!(r.is_simple());
    }

    #[test]
    fn region_below() {
        let r = IntegerRegion::below(10);
        assert!(r.contains(&IntegerPos(9)));
        assert!(r.contains(&IntegerPos(0)));
        assert!(!r.contains(&IntegerPos(10)));
        assert!(r.is_simple());
    }

    #[test]
    fn region_intersect() {
        let a = IntegerRegion::interval(3, 10);
        let b = IntegerRegion::interval(7, 15);
        let c = a.intersect(&b);
        assert_eq!(c.intervals(), vec![(7, 10)]);
        assert_eq!(c.count(), Some(3));
    }

    #[test]
    fn region_intersect_disjoint_is_empty() {
        let a = IntegerRegion::interval(0, 5);
        let b = IntegerRegion::interval(10, 15);
        assert!(a.intersect(&b).is_empty());
    }

    #[test]
    fn region_union() {
        let a = IntegerRegion::interval(3, 7);
        let b = IntegerRegion::interval(10, 15);
        let c = a.union_with(&b);
        assert_eq!(c.intervals(), vec![(3, 7), (10, 15)]);
        assert_eq!(c.count(), Some(9));
    }

    #[test]
    fn region_union_overlapping_merges() {
        let a = IntegerRegion::interval(3, 8);
        let b = IntegerRegion::interval(6, 12);
        let c = a.union_with(&b);
        assert_eq!(c.intervals(), vec![(3, 12)]);
    }

    #[test]
    fn region_union_adjacent_collapses() {
        let a = IntegerRegion::interval(3, 7);
        let b = IntegerRegion::interval(7, 10);
        let c = a.union_with(&b);
        assert_eq!(c.intervals(), vec![(3, 10)]);
    }

    #[test]
    fn region_minus() {
        let a = IntegerRegion::interval(0, 20);
        let b = IntegerRegion::interval(5, 10);
        let c = a.minus(&b);
        assert_eq!(c.intervals(), vec![(0, 5), (10, 20)]);
    }

    #[test]
    fn region_complement() {
        let r = IntegerRegion::interval(3, 7);
        let c = r.complement();
        assert!(!c.contains(&IntegerPos(4)));
        assert!(c.contains(&IntegerPos(0)));
        assert!(c.contains(&IntegerPos(7)));
    }

    #[test]
    fn region_intersects() {
        let a = IntegerRegion::interval(3, 7);
        let b = IntegerRegion::interval(6, 10);
        let c = IntegerRegion::interval(10, 15);
        assert!(a.intersects(&b));
        assert!(!a.intersects(&c));
    }

    #[test]
    fn region_is_simple() {
        assert!(IntegerRegion::empty().is_simple());
        assert!(IntegerRegion::interval(3, 7).is_simple());
        assert!(IntegerRegion::above(5).is_simple());
        assert!(IntegerRegion::below(5).is_simple());
        let multi = IntegerRegion::interval(3, 7).union_with(&IntegerRegion::interval(10, 15));
        assert!(!multi.is_simple());
    }

    #[test]
    fn region_count_infinite_is_none() {
        assert_eq!(IntegerRegion::full().count(), None);
        assert_eq!(IntegerRegion::above(0).count(), None);
        assert_eq!(IntegerRegion::below(0).count(), None);
    }

    #[test]
    fn dsp_identity() {
        let d = IntegerDsp(0);
        assert!(d.is_identity());
        assert_eq!(d.offset(), 0);
    }

    #[test]
    fn dsp_of_translates_position() {
        let d = IntegerDsp(7);
        assert_eq!(d.of(&IntegerPos(4)), IntegerPos(11));
        assert_eq!(d.of(&IntegerPos(0)), IntegerPos(7));

        let neg = IntegerDsp(-3);
        assert_eq!(neg.of(&IntegerPos(10)), IntegerPos(7));
    }

    #[test]
    fn dsp_of_all_translates_region() {
        let r = IntegerRegion::interval(3, 7);
        let d = IntegerDsp(10);
        let shifted = d.of_all(&r);
        assert!(shifted.contains(&IntegerPos(13)));
        assert!(shifted.contains(&IntegerPos(16)));
        assert!(!shifted.contains(&IntegerPos(17)));
        assert!(!shifted.contains(&IntegerPos(12)));
        assert_eq!(shifted.intervals(), vec![(13, 17)]);
    }

    #[test]
    fn dsp_of_all_preserves_gaps() {
        let r = IntegerRegion::interval(0, 5).union_with(&IntegerRegion::interval(10, 15));
        let d = IntegerDsp(100);
        let shifted = d.of_all(&r);
        assert_eq!(
            shifted.intervals(),
            vec![(100, 105), (110, 115)]
        );
    }

    #[test]
    fn dsp_inverse() {
        let d = IntegerDsp(7);
        let inv = d.inverse();
        assert_eq!(inv.offset(), -7);
        assert_eq!(d.of(&inv.of(&IntegerPos(42))), IntegerPos(42));
    }

    #[test]
    fn dsp_compose() {
        let a = IntegerDsp(3);
        let b = IntegerDsp(7);
        let c = a.compose(&b);
        assert_eq!(c.offset(), 10);
        assert_eq!(c.of(&IntegerPos(0)), IntegerPos(10));
    }

    #[test]
    fn dsp_compose_with_inverse_is_identity() {
        let d = IntegerDsp(42);
        let inv = d.inverse();
        let identity = d.compose(&inv);
        assert!(identity.is_identity());
        assert_eq!(identity.of(&IntegerPos(100)), IntegerPos(100));
    }

    #[test]
    fn ascending_follows() {
        let asc = IntegerAscending;
        assert!(asc.follows(&IntegerPos(5), &IntegerPos(3)));
        assert!(asc.follows(&IntegerPos(3), &IntegerPos(3)));
        assert!(!asc.follows(&IntegerPos(3), &IntegerPos(5)));
    }

    #[test]
    fn ascending_compare() {
        let asc = IntegerAscending;
        assert_eq!(asc.compare(&IntegerPos(5), &IntegerPos(3)), Some(std::cmp::Ordering::Greater));
        assert_eq!(asc.compare(&IntegerPos(3), &IntegerPos(5)), Some(std::cmp::Ordering::Less));
        assert_eq!(asc.compare(&IntegerPos(3), &IntegerPos(3)), Some(std::cmp::Ordering::Equal));
    }

    #[test]
    fn descending_follows() {
        let desc = IntegerDescending;
        assert!(desc.follows(&IntegerPos(3), &IntegerPos(5)));
        assert!(desc.follows(&IntegerPos(5), &IntegerPos(5)));
        assert!(!desc.follows(&IntegerPos(5), &IntegerPos(3)));
    }

    #[test]
    fn double_complement_is_identity() {
        let r = IntegerRegion::interval(3, 7).union_with(&IntegerRegion::interval(10, 15));
        assert_eq!(r.complement().complement(), r);
    }

    #[test]
    fn de_morgan_intersect() {
        let a = IntegerRegion::interval(3, 7);
        let b = IntegerRegion::interval(5, 10);
        let lhs = a.intersect(&b);
        let rhs = a.complement().union_with(&b.complement()).complement();
        assert_eq!(lhs, rhs);
    }

    #[test]
    fn de_morgan_union() {
        let a = IntegerRegion::interval(3, 7);
        let b = IntegerRegion::interval(5, 10);
        let lhs = a.union_with(&b);
        let rhs = a.complement().intersect(&b.complement()).complement();
        assert_eq!(lhs, rhs);
    }

    #[test]
    fn union_with_complement_is_full() {
        let r = IntegerRegion::interval(3, 7);
        let u = r.union_with(&r.complement());
        assert!(u.is_full());
    }

    #[test]
    fn empty_operations_identity() {
        let e = IntegerRegion::empty();
        let r = IntegerRegion::interval(3, 7);
        assert_eq!(r.intersect(&e), e);
        assert_eq!(r.union_with(&e), r);
        assert_eq!(r.minus(&e), r);
        assert_eq!(e.minus(&r), e);
    }

    fn example_regions() -> Vec<(&'static str, IntegerRegion)> {
        vec![
            ("empty", IntegerRegion::empty()),
            ("full", IntegerRegion::full()),
            ("interval(3,7)", IntegerRegion::interval(3, 7)),
            (
                "complement_of_interval(3,7)",
                IntegerRegion::interval(3, 7).complement(),
            ),
            ("above(5)", IntegerRegion::above(5)),
            ("below(5)", IntegerRegion::below(5)),
        ]
    }

    #[test]
    fn unary_checks_all_example_regions() {
        for (name, a) in example_regions() {
            assert_eq!(a, a, "identity failed for {name}");
            assert_eq!(
                a.intersects(&a),
                !a.is_empty(),
                "self-intersects for {name}"
            );
            assert!(a.minus(&a).is_empty(), "self-minus for {name}");
            assert!(a.intersect(&a) == a, "self-intersect identity for {name}");
            assert_eq!(
                a.is_full(),
                a.complement().is_empty(),
                "full/complement for {name}"
            );
            assert!(
                a.intersect(&a.complement()).is_empty(),
                "intersect complement for {name}"
            );
            assert_eq!(
                a.minus(&a.complement()),
                a,
                "minus complement for {name}"
            );
            assert_eq!(
                a.complement().complement(),
                a,
                "double complement for {name}"
            );
            assert!(
                a.union_with(&a.complement()).is_full(),
                "union complement for {name}"
            );
        }
    }

    #[test]
    fn binary_checks_all_example_region_pairs() {
        let examples = example_regions();
        for (i, (name_a, a)) in examples.iter().enumerate() {
            for (name_b, b) in examples.iter().skip(i) {
                assert_eq!(
                    a.intersect(b),
                    b.intersect(a),
                    "intersect commutativity {name_a} vs {name_b}"
                );
                assert!(
                    a.intersect(b).is_subset_of_region(a),
                    "intersect subset a {name_a} vs {name_b}"
                );
                assert!(
                    a.intersect(b).is_subset_of_region(b),
                    "intersect subset b {name_a} vs {name_b}"
                );
                assert_eq!(
                    a.intersects(b),
                    !a.intersect(b).is_empty(),
                    "intersects consistency {name_a} vs {name_b}"
                );
                assert!(
                    !a.minus(b).intersects(b),
                    "minus disjoint {name_a} vs {name_b}"
                );
                assert_eq!(
                    a.union_with(b),
                    b.union_with(a),
                    "union commutativity {name_a} vs {name_b}"
                );
            }
        }
    }

    trait RegionExt: Region {
        fn is_subset_of_region(&self, other: &Self) -> bool {
            self.minus(other).is_empty()
        }
    }

    impl<R: Region> RegionExt for R {}

    #[test]
    fn space_trait_bounds_work() {
        let s = IntegerSpace::new();
        let r = s.interval(0, 10);
        let d = s.translation(5);
        let shifted = d.of_all(&r);
        assert_eq!(shifted.intervals(), vec![(5, 15)]);

        let asc = s.ascending();
        assert!(asc.follows(&s.position(5), &s.position(3)));

        let desc = s.descending();
        assert!(desc.follows(&s.position(3), &s.position(5)));
    }
}
