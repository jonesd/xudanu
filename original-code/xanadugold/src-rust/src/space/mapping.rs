use std::fmt::Debug;
use std::hash::Hash;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct SimpleMapping<S: MappingSpace> {
    domain: S::Region,
    dsp: S::Dsp,
}

impl<S: MappingSpace> SimpleMapping<S> {
    pub fn new(domain: S::Region, dsp: S::Dsp) -> Self {
        SimpleMapping { domain, dsp }
    }

    pub fn domain(&self) -> &S::Region {
        &self.domain
    }

    pub fn dsp(&self) -> &S::Dsp {
        &self.dsp
    }

    pub fn of(&self, pos: &S::Position) -> S::Position {
        self.dsp.of(pos)
    }

    pub fn of_all(&self, region: &S::Region) -> S::Region {
        self.dsp.of_all(&self.domain.intersect(region))
    }

    pub fn inverse(&self) -> SimpleMapping<S> {
        SimpleMapping {
            domain: self.dsp.of_all(&self.domain),
            dsp: self.dsp.inverse(),
        }
    }

    pub fn restrict(&self, region: &S::Region) -> Self {
        SimpleMapping {
            domain: self.domain.intersect(region),
            dsp: self.dsp.clone(),
        }
    }

    pub fn is_identity(&self) -> bool {
        self.dsp.is_identity_dsp()
    }
}

pub trait MappingSpace: Debug + Clone + PartialEq + Eq + Hash + Send + Sync + 'static {
    type Position;
    type Region: MappingRegion<Position = Self::Position>;
    type Dsp: MappingDsp<Position = Self::Position, Region = Self::Region>;

    fn empty_region() -> Self::Region;
    fn full_region() -> Self::Region;
    fn identity_dsp() -> Self::Dsp;
}

pub trait MappingRegion: Debug + Clone + PartialEq + Eq + Hash + Send + Sync + 'static {
    type Position;
    fn is_empty(&self) -> bool;
    fn is_full(&self) -> bool;
    fn intersect(&self, other: &Self) -> Self;
    fn union_with(&self, other: &Self) -> Self;
    fn complement(&self) -> Self;
    fn contains(&self, pos: &Self::Position) -> bool;
}

pub trait MappingDsp: Debug + Clone + PartialEq + Eq + Hash + Send + Sync + 'static {
    type Position;
    type Region: MappingRegion<Position = Self::Position>;
    fn of(&self, pos: &Self::Position) -> Self::Position;
    fn of_all(&self, region: &Self::Region) -> Self::Region;
    fn inverse(&self) -> Self;
    fn compose(&self, other: &Self) -> Self;
    fn is_identity_dsp(&self) -> bool;
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct CompositeMapping<S: MappingSpace> {
    mappings: Vec<SimpleMapping<S>>,
}

impl<S: MappingSpace> CompositeMapping<S> {
    pub fn new(mappings: Vec<SimpleMapping<S>>) -> Self {
        CompositeMapping { mappings }
    }

    pub fn empty() -> Self {
        CompositeMapping { mappings: Vec::new() }
    }

    pub fn from_single(mapping: SimpleMapping<S>) -> Self {
        CompositeMapping {
            mappings: vec![mapping],
        }
    }

    pub fn domain(&self) -> S::Region {
        self.mappings
            .iter()
            .fold(S::empty_region(), |acc, m| acc.union_with(m.domain()))
    }

    pub fn range(&self) -> S::Region {
        self.mappings
            .iter()
            .fold(S::empty_region(), |acc, m| acc.union_with(&m.dsp.of_all(&m.domain)))
    }

    pub fn of(&self, pos: &S::Position) -> Option<S::Position> {
        for mapping in &self.mappings {
            if mapping.domain.contains(pos) {
                return Some(mapping.dsp.of(pos));
            }
        }
        None
    }

    pub fn of_all(&self, region: &S::Region) -> S::Region {
        self.mappings
            .iter()
            .fold(S::empty_region(), |acc, m| {
                acc.union_with(&m.dsp.of_all(&m.domain.intersect(region)))
            })
    }

    pub fn inverse(&self) -> Self {
        CompositeMapping {
            mappings: self.mappings.iter().map(|m| m.inverse()).collect(),
        }
    }

    pub fn mappings(&self) -> &[SimpleMapping<S>] {
        &self.mappings
    }

    pub fn is_empty_mapping(&self) -> bool {
        self.mappings.is_empty()
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct ConstantMapping<S: MappingSpace> {
    domain: S::Region,
    values: S::Region,
}

impl<S: MappingSpace> ConstantMapping<S> {
    pub fn new(domain: S::Region, values: S::Region) -> Self {
        ConstantMapping { domain, values }
    }

    pub fn domain(&self) -> &S::Region {
        &self.domain
    }

    pub fn values(&self) -> &S::Region {
        &self.values
    }

    pub fn of_all(&self, region: &S::Region) -> S::Region {
        if self.domain.intersect(region).is_empty() {
            S::empty_region()
        } else {
            self.values.clone()
        }
    }

    pub fn restrict(&self, region: &S::Region) -> Self {
        ConstantMapping {
            domain: self.domain.intersect(region),
            values: self.values.clone(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct EmptyMapping<S: MappingSpace> {
    _phantom: std::marker::PhantomData<S>,
}

impl<S: MappingSpace> EmptyMapping<S> {
    pub fn new() -> Self {
        EmptyMapping {
            _phantom: std::marker::PhantomData,
        }
    }

    pub fn domain(&self) -> S::Region {
        S::empty_region()
    }

    pub fn range(&self) -> S::Region {
        S::empty_region()
    }

    pub fn of_all(&self, _region: &S::Region) -> S::Region {
        S::empty_region()
    }
}

impl<S: MappingSpace> Default for EmptyMapping<S> {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::space::integer::*;
    use crate::space::traits::*;

    impl MappingSpace for IntegerSpace {
        type Position = IntegerPos;
        type Region = IntegerRegion;
        type Dsp = IntegerDsp;

        fn empty_region() -> Self::Region {
            IntegerRegion::empty()
        }

        fn full_region() -> Self::Region {
            IntegerRegion::full()
        }

        fn identity_dsp() -> Self::Dsp {
            IntegerDsp(0)
        }
    }

    impl MappingRegion for IntegerRegion {
        type Position = IntegerPos;

        fn is_empty(&self) -> bool {
            Region::is_empty(self)
        }

        fn is_full(&self) -> bool {
            Region::is_full(self)
        }

        fn intersect(&self, other: &Self) -> Self {
            Region::intersect(self, other)
        }

        fn union_with(&self, other: &Self) -> Self {
            Region::union_with(self, other)
        }

        fn complement(&self) -> Self {
            Region::complement(self)
        }

        fn contains(&self, pos: &Self::Position) -> bool {
            Region::contains(self, pos)
        }
    }

    impl MappingDsp for IntegerDsp {
        type Position = IntegerPos;
        type Region = IntegerRegion;

        fn of(&self, pos: &Self::Position) -> Self::Position {
            Dsp::of(self, pos)
        }

        fn of_all(&self, region: &Self::Region) -> Self::Region {
            Dsp::of_all(self, region)
        }

        fn inverse(&self) -> Self {
            Dsp::inverse(self)
        }

        fn compose(&self, other: &Self) -> Self {
            Dsp::compose(self, other)
        }

        fn is_identity_dsp(&self) -> bool {
            self.0 == 0
        }
    }

    #[test]
    fn simple_mapping_of() {
        let domain = IntegerRegion::interval(0, 10);
        let dsp = IntegerDsp(100);
        let m = SimpleMapping::<IntegerSpace>::new(domain, dsp);
        assert_eq!(m.of(&IntegerPos(5)), IntegerPos(105));
    }

    #[test]
    fn simple_mapping_of_all() {
        let domain = IntegerRegion::interval(0, 10);
        let dsp = IntegerDsp(100);
        let m = SimpleMapping::<IntegerSpace>::new(domain, dsp);
        let r = IntegerRegion::interval(3, 7);
        let result = m.of_all(&r);
        assert!(Region::contains(&result, &IntegerPos(103)));
        assert!(Region::contains(&result, &IntegerPos(106)));
        assert!(!Region::contains(&result, &IntegerPos(107)));
    }

    #[test]
    fn simple_mapping_inverse() {
        let domain = IntegerRegion::interval(0, 10);
        let dsp = IntegerDsp(100);
        let m = SimpleMapping::<IntegerSpace>::new(domain, dsp);
        let inv = m.inverse();
        assert_eq!(inv.of(&IntegerPos(105)), IntegerPos(5));
    }

    #[test]
    fn simple_mapping_restrict() {
        let domain = IntegerRegion::interval(0, 10);
        let dsp = IntegerDsp(100);
        let m = SimpleMapping::<IntegerSpace>::new(domain, dsp);
        let restricted = m.restrict(&IntegerRegion::interval(3, 7));
        assert!(Region::contains(restricted.domain(), &IntegerPos(5)));
        assert!(!Region::contains(restricted.domain(), &IntegerPos(8)));
    }

    #[test]
    fn composite_mapping() {
        let m1 = SimpleMapping::new(IntegerRegion::interval(0, 5), IntegerDsp(100));
        let m2 = SimpleMapping::new(IntegerRegion::interval(5, 10), IntegerDsp(200));
        let composite = CompositeMapping::<IntegerSpace>::new(vec![m1, m2]);
        assert_eq!(composite.of(&IntegerPos(3)), Some(IntegerPos(103)));
        assert_eq!(composite.of(&IntegerPos(7)), Some(IntegerPos(207)));
        assert_eq!(composite.of(&IntegerPos(15)), None);
    }

    #[test]
    fn composite_mapping_domain_range() {
        let m1 = SimpleMapping::new(IntegerRegion::interval(0, 5), IntegerDsp(100));
        let m2 = SimpleMapping::new(IntegerRegion::interval(5, 10), IntegerDsp(200));
        let composite = CompositeMapping::<IntegerSpace>::new(vec![m1, m2]);
        let domain = composite.domain();
        assert!(Region::contains(&domain, &IntegerPos(3)));
        assert!(Region::contains(&domain, &IntegerPos(7)));
        let range = composite.range();
        assert!(Region::contains(&range, &IntegerPos(103)));
        assert!(Region::contains(&range, &IntegerPos(205)));
    }

    #[test]
    fn composite_inverse() {
        let m1 = SimpleMapping::new(IntegerRegion::interval(0, 5), IntegerDsp(100));
        let composite = CompositeMapping::<IntegerSpace>::new(vec![m1]);
        let inv = composite.inverse();
        assert_eq!(inv.of(&IntegerPos(103)), Some(IntegerPos(3)));
    }

    #[test]
    fn constant_mapping() {
        let domain = IntegerRegion::interval(0, 10);
        let values = IntegerRegion::interval(100, 105);
        let m = ConstantMapping::<IntegerSpace>::new(domain, values);
        let r = IntegerRegion::interval(3, 7);
        let result = m.of_all(&r);
        assert_eq!(result, IntegerRegion::interval(100, 105));
    }

    #[test]
    fn constant_mapping_outside_domain() {
        let domain = IntegerRegion::interval(0, 10);
        let values = IntegerRegion::interval(100, 105);
        let m = ConstantMapping::<IntegerSpace>::new(domain, values);
        let outside = IntegerRegion::interval(20, 30);
        let result = m.of_all(&outside);
        assert!(Region::is_empty(&result));
    }

    #[test]
    fn empty_mapping() {
        let m = EmptyMapping::<IntegerSpace>::new();
        assert!(Region::is_empty(&m.domain()));
        assert!(Region::is_empty(&m.range()));
        let r = IntegerRegion::interval(0, 10);
        let result = m.of_all(&r);
        assert!(Region::is_empty(&result));
    }

    #[test]
    fn empty_composite() {
        let composite = CompositeMapping::<IntegerSpace>::empty();
        assert!(composite.is_empty_mapping());
        assert_eq!(composite.of(&IntegerPos(5)), None);
    }
}
