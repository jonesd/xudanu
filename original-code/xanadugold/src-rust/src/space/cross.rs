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
    boxes: Vec<(R1, R2)>,
}

impl<R1: Region, R2: Region> CrossRegion2<R1, R2> {
    pub fn box_of(r1: R1, r2: R2) -> Self {
        if r1.is_empty() || r2.is_empty() {
            return CrossRegion2 { boxes: Vec::new() };
        }
        CrossRegion2 { boxes: vec![(r1, r2)] }
    }

    pub fn projection_a(&self) -> R1
    where
        R1: Clone,
    {
        let first = self.boxes.first();
        if first.is_none() {
            unreachable!("projection_a called on empty CrossRegion2");
        }
        let mut result = self.boxes[0].0.clone();
        for (r, _) in &self.boxes[1..] {
            result = result.union_with(r);
        }
        result
    }

    pub fn projection_b(&self) -> R2
    where
        R2: Clone,
    {
        let first = self.boxes.first();
        if first.is_none() {
            unreachable!("projection_b called on empty CrossRegion2");
        }
        let mut result = self.boxes[0].1.clone();
        for (_, r) in &self.boxes[1..] {
            result = result.union_with(r);
        }
        result
    }

    pub fn into_projections(self) -> (R1, R2) {
        if self.boxes.is_empty() {
            panic!("into_projections called on empty CrossRegion2");
        }
        let mut r1 = self.boxes[0].0.clone();
        let mut r2 = self.boxes[0].1.clone();
        for (a, b) in &self.boxes[1..] {
            r1 = r1.union_with(a);
            r2 = r2.union_with(b);
        }
        (r1, r2)
    }
}

impl<R1: Region, R2: Region> Region for CrossRegion2<R1, R2> {
    type Position = Tuple2<R1::Position, R2::Position>;

    fn is_empty(&self) -> bool {
        self.boxes.is_empty()
    }

    fn is_full(&self) -> bool {
        self.boxes.len() == 1 && self.boxes[0].0.is_full() && self.boxes[0].1.is_full()
    }

    fn contains(&self, pos: &Self::Position) -> bool {
        self.boxes.iter().any(|(r1, r2)| r1.contains(&pos.0) && r2.contains(&pos.1))
    }

    fn intersects(&self, other: &Self) -> bool {
        for (r1, r2) in &self.boxes {
            for (o1, o2) in &other.boxes {
                if r1.intersects(o1) && r2.intersects(o2) {
                    return true;
                }
            }
        }
        false
    }

    fn intersect(&self, other: &Self) -> Self {
        let mut result = Vec::new();
        for (r1, r2) in &self.boxes {
            for (o1, o2) in &other.boxes {
                let i1 = r1.intersect(o1);
                let i2 = r2.intersect(o2);
                if !i1.is_empty() && !i2.is_empty() {
                    result.push((i1, i2));
                }
            }
        }
        CrossRegion2 { boxes: result }
    }

    fn union_with(&self, other: &Self) -> Self {
        let mut boxes = self.boxes.clone();
        boxes.extend(other.boxes.clone());
        CrossRegion2 { boxes }
    }

    fn complement(&self) -> Self {
        if self.boxes.is_empty() {
            return self.clone();
        }
        let full_r1 = self.boxes[0].0.complement().union_with(&self.boxes[0].0);
        let full_r2 = self.boxes[0].1.complement().union_with(&self.boxes[0].1);
        let mut result: Option<CrossRegion2<R1, R2>> = None;
        for (r1, r2) in &self.boxes {
            let r1c = r1.complement();
            let r2c = r2.complement();
            let mut comp_boxes = Vec::new();
            if !r1c.is_empty() {
                comp_boxes.push((r1c, full_r2.clone()));
            }
            if !r2c.is_empty() {
                comp_boxes.push((full_r1.clone(), r2c));
            }
            let box_comp = CrossRegion2 { boxes: comp_boxes };
            result = Some(match result {
                None => box_comp,
                Some(prev) => prev.intersect(&box_comp),
            });
        }
        result.unwrap_or_else(|| CrossRegion2 { boxes: Vec::new() })
    }

    fn minus(&self, other: &Self) -> Self {
        self.intersect(&other.complement())
    }

    fn is_simple(&self) -> bool {
        self.boxes.len() <= 1 && self.boxes.iter().all(|(r1, r2)| r1.is_simple() && r2.is_simple())
    }

    fn count(&self) -> Option<usize> {
        self.boxes.iter().try_fold(0usize, |acc, (r1, r2)| {
            match (r1.count(), r2.count()) {
                (Some(a), Some(b)) => Some(acc + a * b),
                _ => None,
            }
        })
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
        let boxes: Vec<_> = region
            .boxes
            .iter()
            .map(|(r1, r2)| (self.0.of_all(r1), self.1.of_all(r2)))
            .collect();
        CrossRegion2 { boxes }
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
        let r1 = s.box_region(
            IntegerRegion::interval(0, 10),
            IntegerRegion::interval(0, 10),
        );
        let r2 = s.box_region(
            IntegerRegion::interval(5, 15),
            IntegerRegion::interval(3, 7),
        );
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
    fn cross_complement_is_union_of_strips() {
        let s = space();
        let ra = IntegerRegion::interval(2, 5);
        let rb = IntegerRegion::interval(10, 20);
        let r = s.box_region(ra, rb);
        let c = r.complement();
        assert!(!c.contains(&Tuple2(IntegerPos(3), IntegerPos(15))));
        assert!(c.contains(&Tuple2(IntegerPos(0), IntegerPos(15))));
        assert!(c.contains(&Tuple2(IntegerPos(3), IntegerPos(25))));
        assert!(c.contains(&Tuple2(IntegerPos(10), IntegerPos(0))));
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
