use super::traits::*;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct CrossSpace2<A: Space, B: Space> {
    pub a: A,
    pub b: B,
}

impl<A: Space, B: Space> CrossSpace2<A, B> {
    pub fn new(a: A, b: B) -> Self {
        CrossSpace2 { a, b }
    }

    pub fn position(&self, pa: A::Position, pb: B::Position) -> Tuple2<A::Position, B::Position> {
        Tuple2(pa, pb)
    }

    pub fn box_region(&self, ra: A::Region, rb: B::Region) -> CrossRegion2<A::Region, B::Region> {
        CrossRegion2::box_of(ra, rb)
    }
}

impl<A: Space + Default, B: Space + Default> Default for CrossSpace2<A, B> {
    fn default() -> Self {
        CrossSpace2 {
            a: A::default(),
            b: B::default(),
        }
    }
}

impl<A: Space, B: Space> Space for CrossSpace2<A, B> {
    type Position = Tuple2<A::Position, B::Position>;
    type Region = CrossRegion2<A::Region, B::Region>;
    type Dsp = CrossDsp2<A::Dsp, B::Dsp>;

    fn empty_region(&self) -> Self::Region {
        CrossRegion2::box_of(self.a.empty_region(), self.b.full_region())
    }

    fn full_region(&self) -> Self::Region {
        CrossRegion2::box_of(self.a.full_region(), self.b.full_region())
    }

    fn identity_dsp(&self) -> Self::Dsp {
        CrossDsp2(self.a.identity_dsp(), self.b.identity_dsp())
    }

    fn ascending(&self) -> Box<dyn OrderSpec<Position = Self::Position>> {
        Box::new(CrossOrder2 {
            a_order: self.a.ascending(),
            b_order: self.b.ascending(),
        })
    }

    fn descending(&self) -> Box<dyn OrderSpec<Position = Self::Position>> {
        Box::new(CrossOrder2 {
            a_order: self.a.descending(),
            b_order: self.b.descending(),
        })
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Tuple2<A, B>(pub A, pub B);

impl<A: Position, B: Position> Position for Tuple2<A, B> {
    type Region = CrossRegion2<A::Region, B::Region>;

    fn as_region(&self) -> Self::Region {
        CrossRegion2::box_of(self.0.as_region(), self.1.as_region())
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct CrossRegion2<R1, R2> {
    r1: R1,
    r2: R2,
}

impl<R1: Region, R2: Region> CrossRegion2<R1, R2> {
    pub fn box_of(r1: R1, r2: R2) -> Self {
        CrossRegion2 { r1, r2 }
    }

    pub fn projection_a(&self) -> &R1 {
        &self.r1
    }

    pub fn projection_b(&self) -> &R2 {
        &self.r2
    }

    pub fn into_projections(self) -> (R1, R2) {
        (self.r1, self.r2)
    }
}

impl<R1: Region, R2: Region> Region for CrossRegion2<R1, R2> {
    type Position = Tuple2<R1::Position, R2::Position>;

    fn is_empty(&self) -> bool {
        self.r1.is_empty() || self.r2.is_empty()
    }

    fn is_full(&self) -> bool {
        self.r1.is_full() && self.r2.is_full()
    }

    fn contains(&self, pos: &Self::Position) -> bool {
        self.r1.contains(&pos.0) && self.r2.contains(&pos.1)
    }

    fn intersects(&self, other: &Self) -> bool {
        self.r1.intersects(&other.r1) && self.r2.intersects(&other.r2)
    }

    fn intersect(&self, other: &Self) -> Self {
        CrossRegion2::box_of(self.r1.intersect(&other.r1), self.r2.intersect(&other.r2))
    }

    fn union_with(&self, other: &Self) -> Self {
        CrossRegion2::box_of(self.r1.union_with(&other.r1), self.r2.union_with(&other.r2))
    }

    fn complement(&self) -> Self {
        let r1c = self.r1.complement();
        let r2c = self.r2.complement();
        let left = CrossRegion2::box_of(r1c, self.r2.clone());
        let right = CrossRegion2::box_of(self.r1.clone(), r2c);
        left.union_with(&right)
    }

    fn minus(&self, other: &Self) -> Self {
        self.intersect(&other.complement())
    }

    fn is_simple(&self) -> bool {
        self.r1.is_simple() && self.r2.is_simple()
    }

    fn count(&self) -> Option<usize> {
        match (self.r1.count(), self.r2.count()) {
            (Some(a), Some(b)) => Some(a * b),
            _ => None,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct CrossDsp2<D1, D2>(pub D1, pub D2);

impl<D1: Dsp, D2: Dsp> Dsp for CrossDsp2<D1, D2> {
    type Position = Tuple2<D1::Position, D2::Position>;
    type Region = CrossRegion2<D1::Region, D2::Region>;

    fn of(&self, pos: &Self::Position) -> Self::Position {
        Tuple2(self.0.of(&pos.0), self.1.of(&pos.1))
    }

    fn of_all(&self, region: &Self::Region) -> Self::Region {
        let (r1, r2) = region.clone().into_projections();
        CrossRegion2::box_of(self.0.of_all(&r1), self.1.of_all(&r2))
    }

    fn inverse(&self) -> Self {
        CrossDsp2(self.0.inverse(), self.1.inverse())
    }

    fn compose(&self, other: &Self) -> Self {
        CrossDsp2(self.0.compose(&other.0), self.1.compose(&other.1))
    }
}

pub struct CrossOrder2<P1: Position, P2: Position> {
    a_order: Box<dyn OrderSpec<Position = P1>>,
    b_order: Box<dyn OrderSpec<Position = P2>>,
}

impl<P1: Position, P2: Position> std::fmt::Debug for CrossOrder2<P1, P2> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("CrossOrder2").finish()
    }
}

impl<P1: Position, P2: Position> OrderSpec for CrossOrder2<P1, P2> {
    type Position = Tuple2<P1, P2>;

    fn follows(&self, a: &Self::Position, b: &Self::Position) -> bool {
        let a_cmp_b = self.a_order.compare(&a.0, &b.0);
        match a_cmp_b {
            Some(std::cmp::Ordering::Greater) | Some(std::cmp::Ordering::Equal) => true,
            Some(std::cmp::Ordering::Less) => false,
            None => self.b_order.follows(&a.1, &b.1),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::space::integer::*;

    type IntIntSpace = CrossSpace2<IntegerSpace, IntegerSpace>;

    fn space() -> IntIntSpace {
        CrossSpace2::new(IntegerSpace::new(), IntegerSpace::new())
    }

    #[test]
    fn cross_empty() {
        let s = space();
        let r = s.empty_region();
        assert!(r.is_empty());
    }

    #[test]
    fn cross_full() {
        let s = space();
        let r = s.full_region();
        assert!(r.is_full());
    }

    #[test]
    fn cross_box_contains() {
        let s = space();
        let ra = IntegerRegion::interval(1, 5);
        let rb = IntegerRegion::interval(10, 20);
        let r = s.box_region(ra, rb);
        assert!(r.contains(&Tuple2(IntegerPos(3), IntegerPos(15))));
        assert!(!r.contains(&Tuple2(IntegerPos(0), IntegerPos(15))));
        assert!(!r.contains(&Tuple2(IntegerPos(3), IntegerPos(25))));
    }

    #[test]
    fn cross_intersect() {
        let s = space();
        let r1 = s.box_region(IntegerRegion::interval(0, 10), IntegerRegion::interval(0, 10));
        let r2 = s.box_region(IntegerRegion::interval(5, 15), IntegerRegion::interval(3, 7));
        let ri = r1.intersect(&r2);
        assert!(ri.contains(&Tuple2(IntegerPos(7), IntegerPos(5))));
        assert!(!ri.contains(&Tuple2(IntegerPos(3), IntegerPos(5))));
        assert!(!ri.contains(&Tuple2(IntegerPos(7), IntegerPos(8))));
    }

    #[test]
    fn cross_union() {
        let s = space();
        let r1 = s.box_region(IntegerRegion::interval(0, 5), IntegerRegion::interval(0, 5));
        let r2 = s.box_region(IntegerRegion::interval(3, 8), IntegerRegion::interval(3, 8));
        let ru = r1.union_with(&r2);
        assert!(ru.contains(&Tuple2(IntegerPos(2), IntegerPos(2))));
        assert!(ru.contains(&Tuple2(IntegerPos(7), IntegerPos(7))));
    }

    #[test]
    fn cross_complement_produces_box() {
        let s = space();
        let ra = IntegerRegion::interval(2, 5);
        let rb = IntegerRegion::interval(10, 20);
        let r = s.box_region(ra, rb);
        let c = r.complement();
        assert!(c.is_full());
    }

    #[test]
    fn cross_count() {
        let s = space();
        let r = s.box_region(IntegerRegion::interval(0, 3), IntegerRegion::interval(0, 4));
        assert_eq!(r.count(), Some(12));
    }

    #[test]
    fn cross_dsp() {
        let s = space();
        let d = s.identity_dsp();
        let p = Tuple2(IntegerPos(3), IntegerPos(7));
        assert_eq!(d.of(&p), p);
    }

    #[test]
    fn cross_dsp_compose() {
        let d1 = CrossDsp2(IntegerDsp(5), IntegerDsp(10));
        let d2 = CrossDsp2(IntegerDsp(3), IntegerDsp(-2));
        let d3 = d1.compose(&d2);
        let p = Tuple2(IntegerPos(0), IntegerPos(0));
        let result = d3.of(&p);
        assert_eq!(result.0, IntegerPos(8));
        assert_eq!(result.1, IntegerPos(8));
    }

    #[test]
    fn cross_dsp_inverse() {
        let d = CrossDsp2(IntegerDsp(5), IntegerDsp(10));
        let inv = d.inverse();
        let roundtrip = d.compose(&inv);
        let p = Tuple2(IntegerPos(42), IntegerPos(100));
        assert_eq!(roundtrip.of(&p), p);
    }

    #[test]
    fn tuple_as_region() {
        let t = Tuple2(IntegerPos(3), IntegerPos(7));
        let r = t.as_region();
        assert!(r.contains(&Tuple2(IntegerPos(3), IntegerPos(7))));
        assert!(!r.contains(&Tuple2(IntegerPos(4), IntegerPos(7))));
        assert!(!r.contains(&Tuple2(IntegerPos(3), IntegerPos(8))));
    }

    #[test]
    fn cross_ascending_order() {
        let s = space();
        let asc = s.ascending();
        let a = Tuple2(IntegerPos(1), IntegerPos(0));
        let b = Tuple2(IntegerPos(2), IntegerPos(0));
        let c = Tuple2(IntegerPos(1), IntegerPos(5));
        assert!(asc.follows(&b, &a));
        assert!(asc.follows(&c, &a));
    }
}
