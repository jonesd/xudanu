#[cfg(feature = "serde")]
use super::mapping::Mapping;
use super::xn_region::XnRegion;
use crate::space::mapping::{MappingDsp, MappingRegion, MappingSpace};
use crate::space::{Dsp, OrderSpec, Position, Region, Space};
#[cfg(feature = "serde")]
use std::cmp::Ordering;

// ── Position wrapper for i64 ──────────────────────────────────────────────

/// Thin wrapper around i64 that implements the Position trait.
/// Enables XnRegion to satisfy the Region trait.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct I64Pos(pub i64);

impl Position for I64Pos {
    type Region = XnRegion;
    fn as_region(&self) -> XnRegion {
        XnRegion::interval(self.0, self.0 + 1)
    }
}

// ── Dsp wrapper for i64 offset ─────────────────────────────────────────────

/// Constant displacement: shifts all positions by a fixed offset.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct I64Dsp(pub i64);

impl Dsp for I64Dsp {
    type Position = I64Pos;
    type Region = XnRegion;

    fn of(&self, pos: &Self::Position) -> Self::Position {
        I64Pos(pos.0 + self.0)
    }

    fn of_all(&self, region: &Self::Region) -> Self::Region {
        region.shift(self.0)
    }

    fn inverse(&self) -> Self {
        I64Dsp(-self.0)
    }

    fn compose(&self, other: &Self) -> Self {
        I64Dsp(self.0 + other.0)
    }
}

// ── Region trait impl for XnRegion ────────────────────────────────────────

impl Region for XnRegion {
    type Position = I64Pos;

    fn is_empty(&self) -> bool {
        XnRegion::is_empty(self)
    }

    fn is_full(&self) -> bool {
        XnRegion::is_full(self)
    }

    fn contains(&self, pos: &Self::Position) -> bool {
        XnRegion::contains(self, pos.0)
    }

    fn intersects(&self, other: &Self) -> bool {
        XnRegion::intersects(self, other)
    }

    fn intersect(&self, other: &Self) -> Self {
        XnRegion::intersect(self, other)
    }

    fn union_with(&self, other: &Self) -> Self {
        XnRegion::union(self, other)
    }

    fn complement(&self) -> Self {
        XnRegion::complement(self)
    }

    fn minus(&self, other: &Self) -> Self {
        XnRegion::minus(self, other)
    }

    fn is_simple(&self) -> bool {
        XnRegion::is_simple(self)
    }

    fn count(&self) -> Option<usize> {
        XnRegion::count(self).map(|c| c as usize)
    }

    // delta() uses default impl: (self - other) ∪ (other - self)
    // But we have the optimized XOR version, so override:
    fn delta(&self, other: &Self) -> Self {
        XnRegion::delta(self, other)
    }
}

// ── Space impl for integer space ───────────────────────────────────────────

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct IntegerSpace;

impl Space for IntegerSpace {
    type Position = I64Pos;
    type Region = XnRegion;
    type Dsp = I64Dsp;

    fn empty_region(&self) -> Self::Region {
        XnRegion::empty()
    }

    fn full_region(&self) -> Self::Region {
        XnRegion::full()
    }

    fn identity_dsp(&self) -> Self::Dsp {
        I64Dsp(0)
    }

    fn ascending(&self) -> Box<dyn OrderSpec<Position = Self::Position>> {
        Box::new(IntegerAscending)
    }

    fn descending(&self) -> Box<dyn OrderSpec<Position = Self::Position>> {
        Box::new(IntegerDescending)
    }
}

#[derive(Debug)]
struct IntegerAscending;

impl OrderSpec for IntegerAscending {
    type Position = I64Pos;
    fn follows(&self, a: &Self::Position, b: &Self::Position) -> bool {
        a.0 >= b.0
    }
}

#[derive(Debug)]
struct IntegerDescending;

impl OrderSpec for IntegerDescending {
    type Position = I64Pos;
    fn follows(&self, a: &Self::Position, b: &Self::Position) -> bool {
        a.0 <= b.0
    }
}

// ── MappingSpace impl for XnRegion ─────────────────────────────────────────

/// Marker type that makes XnRegion satisfy the MappingSpace trait hierarchy.
/// This connects the edition::Mapping to the space::SimpleMapping/CompositeMapping system.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct EditionMappingSpace;

impl MappingSpace for EditionMappingSpace {
    type Position = I64Pos;
    type Region = XnRegionBridge;
    type Dsp = I64DspBridge;

    fn empty_region() -> Self::Region {
        XnRegionBridge(XnRegion::empty())
    }
    fn full_region() -> Self::Region {
        XnRegionBridge(XnRegion::full())
    }
    fn identity_dsp() -> Self::Dsp {
        I64DspBridge(0)
    }
}

/// Wrapper to impl MappingRegion on XnRegion (avoids orphan rules).
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct XnRegionBridge(pub XnRegion);

impl MappingRegion for XnRegionBridge {
    type Position = I64Pos;

    fn is_empty(&self) -> bool {
        self.0.is_empty()
    }
    fn is_full(&self) -> bool {
        self.0.is_full()
    }
    fn intersect(&self, other: &Self) -> Self {
        XnRegionBridge(self.0.intersect(&other.0))
    }
    fn union_with(&self, other: &Self) -> Self {
        XnRegionBridge(self.0.union(&other.0))
    }
    fn complement(&self) -> Self {
        XnRegionBridge(self.0.complement())
    }
    fn contains(&self, pos: &Self::Position) -> bool {
        self.0.contains(pos.0)
    }
}

/// Wrapper to impl MappingDsp on i64 offsets.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct I64DspBridge(pub i64);

impl MappingDsp for I64DspBridge {
    type Position = I64Pos;
    type Region = XnRegionBridge;

    fn of(&self, pos: &Self::Position) -> Self::Position {
        I64Pos(pos.0 + self.0)
    }
    fn of_all(&self, region: &Self::Region) -> Self::Region {
        XnRegionBridge(region.0.shift(self.0))
    }
    fn inverse(&self) -> Self {
        I64DspBridge(-self.0)
    }
    fn compose(&self, other: &Self) -> Self {
        I64DspBridge(self.0 + other.0)
    }
    fn is_identity_dsp(&self) -> bool {
        self.0 == 0
    }
}

// ── Tests ─────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn trait_region_matches_concrete() {
        let a = XnRegion::interval(0, 10);
        let b = XnRegion::interval(5, 15);

        // Trait operations match concrete operations
        assert_eq!(Region::intersect(&a, &b), XnRegion::intersect(&a, &b));
        assert_eq!(Region::union_with(&a, &b), XnRegion::union(&a, &b));
        assert_eq!(Region::minus(&a, &b), XnRegion::minus(&a, &b));
        assert_eq!(Region::delta(&a, &b), XnRegion::delta(&a, &b));
        assert_eq!(Region::complement(&a), XnRegion::complement(&a));
    }

    #[test]
    fn trait_contains() {
        let r = XnRegion::interval(0, 10);
        assert!(Region::contains(&r, &I64Pos(0)));
        assert!(Region::contains(&r, &I64Pos(9)));
        assert!(!Region::contains(&r, &I64Pos(10)));
    }

    #[test]
    fn trait_dsp_of() {
        let dsp = I64Dsp(5);
        assert_eq!(Dsp::of(&dsp, &I64Pos(10)), I64Pos(15));
        assert_eq!(Dsp::of(&dsp, &I64Pos(0)), I64Pos(5));
    }

    #[test]
    fn trait_dsp_of_all() {
        let dsp = I64Dsp(3);
        let r = XnRegion::interval(0, 10);
        let shifted = Dsp::of_all(&dsp, &r);
        assert!(shifted.contains(3));
        assert!(shifted.contains(12));
        assert!(!shifted.contains(2));
    }

    #[test]
    fn trait_dsp_compose() {
        let a = I64Dsp(3);
        let b = I64Dsp(5);
        let composed = Dsp::compose(&a, &b);
        assert_eq!(Dsp::of(&composed, &I64Pos(0)), I64Pos(8));
    }

    #[test]
    fn trait_dsp_inverse() {
        let d = I64Dsp(7);
        let inv = Dsp::inverse(&d);
        assert_eq!(Dsp::of(&inv, &I64Pos(10)), I64Pos(3));
    }

    #[test]
    fn space_integer() {
        let space = IntegerSpace;
        assert!(space.empty_region().is_empty());
        assert!(space.full_region().is_full());
        let id = space.identity_dsp();
        assert_eq!(Dsp::of(&id, &I64Pos(42)), I64Pos(42));
    }

    #[test]
    fn space_ascending() {
        let space = IntegerSpace;
        let order = space.ascending();
        assert!(order.follows(&I64Pos(5), &I64Pos(3)));
        assert!(!order.follows(&I64Pos(3), &I64Pos(5)));
        assert!(order.follows(&I64Pos(5), &I64Pos(5)));
    }

    #[test]
    fn trait_delta_laws() {
        let a = XnRegion::interval(0, 10);
        let b = XnRegion::interval(5, 15);

        // delta is symmetric
        assert_eq!(Region::delta(&a, &b), Region::delta(&b, &a));
        // delta self is empty
        assert!(Region::delta(&a, &a).is_empty());
        // delta is subset of union
        let u = Region::union_with(&a, &b);
        assert!(Region::minus(&Region::delta(&a, &b), &u).is_empty());
    }

    #[test]
    fn position_as_region() {
        let p = I64Pos(5);
        let r = p.as_region();
        assert!(r.contains(5));
        assert!(!r.contains(4));
        assert!(!r.contains(6));
    }

    #[test]
    fn mapping_space_bridge() {
        use crate::space::mapping::SimpleMapping;
        let domain = XnRegionBridge(XnRegion::interval(0, 10));
        let dsp = I64DspBridge(5);
        let m = SimpleMapping::<EditionMappingSpace>::new(domain, dsp);
        assert_eq!(m.of(&I64Pos(3)), I64Pos(8));
        assert_eq!(m.of(&I64Pos(9)), I64Pos(14));
    }

    #[test]
    fn mapping_space_inverse() {
        use crate::space::mapping::SimpleMapping;
        let domain = XnRegionBridge(XnRegion::interval(0, 10));
        let dsp = I64DspBridge(5);
        let m = SimpleMapping::<EditionMappingSpace>::new(domain, dsp);
        let inv = m.inverse();
        assert_eq!(inv.of(&I64Pos(8)), I64Pos(3));
    }

    #[test]
    fn mapping_space_composite() {
        use crate::space::mapping::{CompositeMapping, SimpleMapping};
        let m1 = SimpleMapping::<EditionMappingSpace>::new(
            XnRegionBridge(XnRegion::interval(0, 5)),
            I64DspBridge(10),
        );
        let m2 = SimpleMapping::<EditionMappingSpace>::new(
            XnRegionBridge(XnRegion::interval(5, 10)),
            I64DspBridge(20),
        );
        let composite = CompositeMapping::new(vec![m1, m2]);
        assert_eq!(composite.of(&I64Pos(3)), Some(I64Pos(13)));
        assert_eq!(composite.of(&I64Pos(7)), Some(I64Pos(27)));
        assert_eq!(composite.of(&I64Pos(10)), None);
    }

    #[test]
    fn mapping_space_of_all() {
        use crate::space::mapping::SimpleMapping;
        let m = SimpleMapping::<EditionMappingSpace>::new(
            XnRegionBridge(XnRegion::interval(0, 10)),
            I64DspBridge(5),
        );
        let query = XnRegionBridge(XnRegion::interval(3, 8));
        let result = m.of_all(&query);
        assert!(result.0.contains(8));
        assert!(result.0.contains(12));
        assert!(!result.0.contains(7));
    }

    #[test]
    fn cross_compatible_with_space_integer() {
        // IntegerRegion wraps XnRegion internally. Verify both systems
        // produce identical results for the same algebraic operations.
        let a = XnRegion::interval(0, 10);
        let b = XnRegion::interval(5, 15);

        // Test via trait interface on XnRegion
        let trait_intersect = <XnRegion as Region>::intersect(&a, &b);
        let trait_union = <XnRegion as Region>::union_with(&a, &b);
        let trait_minus = <XnRegion as Region>::minus(&a, &b);
        let trait_delta = <XnRegion as Region>::delta(&a, &b);

        // Test via inherent methods
        let inh_intersect = a.intersect(&b);
        let inh_union = a.union(&b);
        let inh_minus = a.minus(&b);
        let inh_delta = a.delta(&b);

        // They must be identical
        assert_eq!(trait_intersect, inh_intersect);
        assert_eq!(trait_union, inh_union);
        assert_eq!(trait_minus, inh_minus);
        assert_eq!(trait_delta, inh_delta);
    }
}
