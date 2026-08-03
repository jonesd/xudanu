use std::cmp::Ordering;
use std::fmt::Debug;
use std::hash::Hash;

pub trait Space: Debug + Clone + PartialEq + Eq + Hash + Send + Sync + 'static {
    type Position: Position<Region = Self::Region>;
    type Region: Region<Position = Self::Position>;
    type Dsp: Dsp<Position = Self::Position, Region = Self::Region>;

    fn empty_region(&self) -> Self::Region;
    fn full_region(&self) -> Self::Region;
    fn identity_dsp(&self) -> Self::Dsp;
    fn ascending(&self) -> Box<dyn OrderSpec<Position = Self::Position>>;
    fn descending(&self) -> Box<dyn OrderSpec<Position = Self::Position>>;
}

pub trait Position: Debug + Clone + PartialEq + Eq + Hash + Send + Sync + 'static {
    type Region: Region<Position = Self>;

    fn as_region(&self) -> Self::Region;
}

pub trait Region: Debug + Clone + PartialEq + Eq + Hash + Send + Sync + 'static {
    type Position: Position<Region = Self>;

    fn is_empty(&self) -> bool;
    fn is_full(&self) -> bool;
    fn contains(&self, pos: &Self::Position) -> bool;
    fn intersects(&self, other: &Self) -> bool;
    fn intersect(&self, other: &Self) -> Self;
    fn union_with(&self, other: &Self) -> Self;
    fn complement(&self) -> Self;
    fn minus(&self, other: &Self) -> Self;
    fn is_simple(&self) -> bool;
    fn count(&self) -> Option<usize>;

    /// Symmetric difference: (self - other) ∪ (other - self).
    /// Returns the region of positions that are in exactly one of the two regions.
    fn delta(&self, other: &Self) -> Self {
        let a_minus_b = self.minus(other);
        let b_minus_a = other.minus(self);
        a_minus_b.union_with(&b_minus_a)
    }
}

pub trait Dsp: Debug + Clone + PartialEq + Eq + Hash + Send + Sync + 'static {
    type Position: Position<Region = Self::Region>;
    type Region: Region<Position = Self::Position>;

    fn of(&self, pos: &Self::Position) -> Self::Position;
    fn of_all(&self, region: &Self::Region) -> Self::Region;
    fn inverse(&self) -> Self;
    fn compose(&self, other: &Self) -> Self;
}

pub trait OrderSpec: Debug + Send + Sync + 'static {
    type Position: Position;

    fn follows(&self, a: &Self::Position, b: &Self::Position) -> bool;

    fn compare(&self, a: &Self::Position, b: &Self::Position) -> Option<Ordering> {
        match (self.follows(a, b), self.follows(b, a)) {
            (true, true) => Some(Ordering::Equal),
            (true, false) => Some(Ordering::Greater),
            (false, true) => Some(Ordering::Less),
            (false, false) => None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::space::integer::{IntegerAscending, IntegerDescending, IntegerSpace};

    fn s() -> IntegerSpace {
        IntegerSpace::new()
    }

    mod delta_tests {
        use super::*;

        #[test]
        fn delta_disjoint_regions() {
            let a = s().interval(0, 5);
            let b = s().interval(10, 15);
            let d = a.delta(&b);
            assert_eq!(d.count(), Some(10));
        }

        #[test]
        fn delta_overlapping_regions() {
            let a = s().interval(0, 5);
            let b = s().interval(3, 8);
            let d = a.delta(&b);
            let expected = s().interval(0, 3).union_with(&s().interval(5, 8));
            assert_eq!(d, expected);
        }

        #[test]
        fn delta_identical_regions_is_empty() {
            let a = s().interval(0, 10);
            let b = s().interval(0, 10);
            let d = a.delta(&b);
            assert!(d.is_empty());
        }

        #[test]
        fn delta_subset() {
            let big = s().interval(0, 10);
            let small = s().interval(3, 7);
            let d = big.delta(&small);
            let expected = s().interval(0, 3).union_with(&s().interval(7, 10));
            assert_eq!(d, expected);
        }

        #[test]
        fn delta_with_empty() {
            let a = s().interval(0, 5);
            let e = s().empty_region();
            assert_eq!(a.delta(&e), a);
            assert_eq!(e.delta(&a), a);
        }

        #[test]
        fn delta_is_symmetric() {
            let a = s().interval(0, 5);
            let b = s().interval(3, 8);
            assert_eq!(a.delta(&b), b.delta(&a));
        }
    }

    mod compare_tests {
        use super::*;

        #[test]
        fn ascending_compare_equal() {
            let ord = s().ascending();
            let p = s().position(5);
            assert_eq!(ord.compare(&p, &p), Some(Ordering::Equal));
        }

        #[test]
        fn ascending_compare_less() {
            let ord = s().ascending();
            let a = s().position(3);
            let b = s().position(7);
            assert_eq!(ord.compare(&a, &b), Some(Ordering::Less));
        }

        #[test]
        fn ascending_compare_greater() {
            let ord = s().ascending();
            let a = s().position(9);
            let b = s().position(2);
            assert_eq!(ord.compare(&a, &b), Some(Ordering::Greater));
        }

        #[test]
        fn descending_compare_equal() {
            let ord = s().descending();
            let p = s().position(5);
            assert_eq!(ord.compare(&p, &p), Some(Ordering::Equal));
        }

        #[test]
        fn descending_compare_flipped() {
            let asc = s().ascending();
            let desc = s().descending();
            let a = s().position(3);
            let b = s().position(7);
            assert_eq!(asc.compare(&a, &b), Some(Ordering::Less));
            assert_eq!(desc.compare(&a, &b), Some(Ordering::Greater));
        }

        #[test]
        fn ascending_and_descending_are_inverse() {
            let asc = s().ascending();
            let desc = s().descending();
            let a = s().position(1);
            let b = s().position(10);
            let ab = asc.compare(&a, &b);
            let ba = desc.compare(&a, &b);
            assert_ne!(ab, ba);
        }
    }
}
