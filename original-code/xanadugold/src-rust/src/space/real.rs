use super::traits::*;
use std::cmp::Ordering;

#[derive(Debug, Clone, PartialEq, Eq, Hash, Default)]
pub struct RealSpace;

impl RealSpace {
    pub fn new() -> Self {
        RealSpace
    }

    pub fn position(&self, value: f64) -> RealPos {
        RealPos(value)
    }

    pub fn interval(&self, start: f64, stop: f64, start_incl: bool, stop_incl: bool) -> RealRegion {
        RealRegion::interval(start, stop, start_incl, stop_incl)
    }

    pub fn above(&self, start: f64, inclusive: bool) -> RealRegion {
        RealRegion::above(start, inclusive)
    }

    pub fn below(&self, stop: f64, inclusive: bool) -> RealRegion {
        RealRegion::below(stop, inclusive)
    }

    pub fn translation(&self, offset: f64) -> RealDsp {
        RealDsp(offset)
    }
}

impl Space for RealSpace {
    type Position = RealPos;
    type Region = RealRegion;
    type Dsp = RealDsp;

    fn empty_region(&self) -> Self::Region {
        RealRegion::empty()
    }

    fn full_region(&self) -> Self::Region {
        RealRegion::full()
    }

    fn identity_dsp(&self) -> Self::Dsp {
        RealDsp(0.0)
    }

    fn ascending(&self) -> Box<dyn OrderSpec<Position = Self::Position>> {
        Box::new(RealAscending)
    }

    fn descending(&self) -> Box<dyn OrderSpec<Position = Self::Position>> {
        Box::new(RealDescending)
    }
}

#[derive(Debug, Clone)]
pub struct RealPos(pub f64);

impl RealPos {
    pub fn value(&self) -> f64 {
        self.0
    }
}

impl PartialEq for RealPos {
    fn eq(&self, other: &Self) -> bool {
        self.0.to_bits() == other.0.to_bits()
    }
}

impl Eq for RealPos {}

impl std::hash::Hash for RealPos {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.0.to_bits().hash(state);
    }
}

impl Position for RealPos {
    type Region = RealRegion;

    fn as_region(&self) -> Self::Region {
        RealRegion::point(self.0)
    }
}

#[derive(Debug, Clone)]
pub struct RealRegion {
    starts_inside: bool,
    transitions: Vec<f64>,
}

impl PartialEq for RealRegion {
    fn eq(&self, other: &Self) -> bool {
        if self.starts_inside != other.starts_inside {
            return false;
        }
        if self.transitions.len() != other.transitions.len() {
            return false;
        }
        self.transitions
            .iter()
            .zip(other.transitions.iter())
            .all(|(a, b)| a.to_bits() == b.to_bits())
    }
}

impl Eq for RealRegion {}

impl std::hash::Hash for RealRegion {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.starts_inside.hash(state);
        for v in &self.transitions {
            v.to_bits().hash(state);
        }
    }
}

impl RealRegion {
    pub fn empty() -> Self {
        RealRegion {
            starts_inside: false,
            transitions: Vec::new(),
        }
    }

    pub fn full() -> Self {
        RealRegion {
            starts_inside: true,
            transitions: Vec::new(),
        }
    }

    pub fn point(v: f64) -> Self {
        RealRegion {
            starts_inside: false,
            transitions: vec![v, v.next_up()],
        }
    }

    pub fn interval(start: f64, stop: f64, start_incl: bool, stop_incl: bool) -> Self {
        let effective_start = if start_incl { start } else { start.next_up() };
        let effective_stop = if stop_incl { stop.next_up() } else { stop };
        if effective_start >= effective_stop {
            return Self::empty();
        }
        RealRegion {
            starts_inside: false,
            transitions: vec![effective_start, effective_stop],
        }
    }

    pub fn above(start: f64, inclusive: bool) -> Self {
        let effective = if inclusive { start } else { start.next_up() };
        RealRegion {
            starts_inside: false,
            transitions: vec![effective],
        }
    }

    pub fn below(stop: f64, inclusive: bool) -> Self {
        let effective = if inclusive { stop.next_up() } else { stop };
        RealRegion {
            starts_inside: true,
            transitions: vec![effective],
        }
    }

    pub fn contains_value(&self, v: f64) -> bool {
        let mut inside = self.starts_inside;
        for t in &self.transitions {
            if *t > v {
                break;
            }
            inside = !inside;
        }
        inside
    }

    pub fn lower_bound(&self) -> Option<f64> {
        if self.is_empty() {
            return None;
        }
        if self.starts_inside {
            return Some(f64::NEG_INFINITY);
        }
        self.transitions.first().copied()
    }

    pub fn upper_bound(&self) -> Option<f64> {
        if self.is_empty() {
            return None;
        }
        let num = self.transitions.len();
        if self.starts_inside {
            if num % 2 == 1 {
                return Some(f64::INFINITY);
            }
        } else if num % 2 == 1 {
            return Some(f64::INFINITY);
        }
        self.transitions.last().copied()
    }
}

impl Default for RealRegion {
    fn default() -> Self {
        Self::empty()
    }
}

fn merge_real_regions(
    a: &RealRegion,
    b: &RealRegion,
    combine: impl Fn(bool, bool) -> bool,
) -> RealRegion {
    let new_starts = combine(a.starts_inside, b.starts_inside);
    let mut result = Vec::new();
    let mut ai = 0usize;
    let mut bi = 0usize;
    let mut a_between = a.starts_inside;
    let mut b_between = b.starts_inside;
    let mut cur = new_starts;

    loop {
        let av = a.transitions.get(ai);
        let bv = b.transitions.get(bi);
        let nv = match (av, bv) {
            (Some(&a_val), Some(&b_val)) => a_val.min(b_val),
            (Some(&a_val), None) => a_val,
            (None, Some(&b_val)) => b_val,
            (None, None) => break,
        };

        if av.map_or(false, |&v| v == nv) {
            a_between = !a_between;
            ai += 1;
        }
        if bv.map_or(false, |&v| v == nv) {
            b_between = !b_between;
            bi += 1;
        }

        let new_between = combine(a_between, b_between);
        if new_between != cur {
            result.push(nv);
            cur = new_between;
        }
    }

    RealRegion {
        starts_inside: new_starts,
        transitions: result,
    }
}

impl Region for RealRegion {
    type Position = RealPos;

    fn is_empty(&self) -> bool {
        !self.starts_inside && self.transitions.is_empty()
    }

    fn is_full(&self) -> bool {
        self.starts_inside && self.transitions.is_empty()
    }

    fn contains(&self, pos: &Self::Position) -> bool {
        self.contains_value(pos.0)
    }

    fn intersects(&self, other: &Self) -> bool {
        !self.intersect(other).is_empty()
    }

    fn intersect(&self, other: &Self) -> Self {
        merge_real_regions(self, other, |a, b| a && b)
    }

    fn union_with(&self, other: &Self) -> Self {
        merge_real_regions(self, other, |a, b| a || b)
    }

    fn complement(&self) -> Self {
        RealRegion {
            starts_inside: !self.starts_inside,
            transitions: self.transitions.clone(),
        }
    }

    fn minus(&self, other: &Self) -> Self {
        merge_real_regions(self, other, |a, b| a && !b)
    }

    fn is_simple(&self) -> bool {
        if self.is_empty() || self.is_full() {
            return true;
        }
        let num = self.transitions.len();
        if self.starts_inside {
            num <= 1
        } else {
            num <= 2
        }
    }

    fn count(&self) -> Option<usize> {
        None
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct RealDsp(pub f64);

impl RealDsp {
    pub fn offset(&self) -> f64 {
        self.0
    }

    pub fn is_identity(&self) -> bool {
        self.0 == 0.0
    }
}

impl Eq for RealDsp {}

impl std::hash::Hash for RealDsp {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.0.to_bits().hash(state);
    }
}

impl Dsp for RealDsp {
    type Position = RealPos;
    type Region = RealRegion;

    fn of(&self, pos: &Self::Position) -> Self::Position {
        RealPos(pos.0 + self.0)
    }

    fn of_all(&self, region: &Self::Region) -> Self::Region {
        RealRegion {
            starts_inside: region.starts_inside,
            transitions: region.transitions.iter().map(|v| v + self.0).collect(),
        }
    }

    fn inverse(&self) -> Self {
        RealDsp(-self.0)
    }

    fn compose(&self, other: &Self) -> Self {
        RealDsp(self.0 + other.0)
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RealAscending;

impl OrderSpec for RealAscending {
    type Position = RealPos;

    fn follows(&self, a: &Self::Position, b: &Self::Position) -> bool {
        a.0 >= b.0
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RealDescending;

impl OrderSpec for RealDescending {
    type Position = RealPos;

    fn follows(&self, a: &Self::Position, b: &Self::Position) -> bool {
        a.0 <= b.0
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn space() -> RealSpace {
        RealSpace::new()
    }

    #[test]
    fn empty_region() {
        let r = RealRegion::empty();
        assert!(r.is_empty());
        assert!(!r.is_full());
        assert!(r.is_simple());
        assert!(!r.contains_value(0.0));
        assert!(!r.contains_value(100.0));
    }

    #[test]
    fn full_region() {
        let r = RealRegion::full();
        assert!(r.is_full());
        assert!(!r.is_empty());
        assert!(r.contains_value(0.0));
        assert!(r.contains_value(-1e300));
        assert!(r.contains_value(1e300));
    }

    #[test]
    fn point_region() {
        let r = RealRegion::point(3.5);
        assert!(r.contains_value(3.5));
        assert!(!r.contains_value(3.4));
        assert!(!r.contains_value(3.6));
    }

    #[test]
    fn closed_interval() {
        let r = RealRegion::interval(1.0, 5.0, true, true);
        assert!(r.contains_value(1.0));
        assert!(r.contains_value(5.0));
        assert!(r.contains_value(3.0));
        assert!(!r.contains_value(0.9));
        assert!(!r.contains_value(5.1));
    }

    #[test]
    fn open_interval() {
        let r = RealRegion::interval(1.0, 5.0, false, false);
        assert!(!r.contains_value(1.0));
        assert!(!r.contains_value(5.0));
        assert!(r.contains_value(3.0));
        assert!(r.contains_value(1.1));
        assert!(r.contains_value(4.9));
    }

    #[test]
    fn half_open_interval() {
        let r = RealRegion::interval(1.0, 5.0, true, false);
        assert!(r.contains_value(1.0));
        assert!(!r.contains_value(5.0));
        assert!(r.contains_value(3.0));
    }

    #[test]
    fn interval_same_point_inclusive() {
        let r = RealRegion::interval(3.0, 3.0, true, true);
        assert!(r.contains_value(3.0));
    }

    #[test]
    fn interval_same_point_exclusive_is_empty() {
        let r = RealRegion::interval(3.0, 3.0, false, false);
        assert!(r.is_empty());
    }

    #[test]
    fn above_inclusive() {
        let r = RealRegion::above(10.0, true);
        assert!(r.contains_value(10.0));
        assert!(r.contains_value(100.0));
        assert!(!r.contains_value(9.9));
    }

    #[test]
    fn above_exclusive() {
        let r = RealRegion::above(10.0, false);
        assert!(!r.contains_value(10.0));
        assert!(r.contains_value(10.1));
        assert!(!r.contains_value(9.9));
    }

    #[test]
    fn below_inclusive() {
        let r = RealRegion::below(10.0, true);
        assert!(r.contains_value(10.0));
        assert!(r.contains_value(0.0));
        assert!(!r.contains_value(10.1));
    }

    #[test]
    fn below_exclusive() {
        let r = RealRegion::below(10.0, false);
        assert!(!r.contains_value(10.0));
        assert!(r.contains_value(9.9));
        assert!(!r.contains_value(10.1));
    }

    #[test]
    fn intersect_intervals() {
        let a = RealRegion::interval(1.0, 5.0, true, false);
        let b = RealRegion::interval(3.0, 7.0, false, true);
        let c = a.intersect(&b);
        assert!(!c.contains_value(3.0));
        assert!(c.contains_value(4.0));
        assert!(!c.contains_value(5.0));
    }

    #[test]
    fn intersect_disjoint() {
        let a = RealRegion::interval(0.0, 3.0, true, true);
        let b = RealRegion::interval(5.0, 8.0, true, true);
        assert!(a.intersect(&b).is_empty());
    }

    #[test]
    fn union_intervals() {
        let a = RealRegion::interval(1.0, 3.0, true, true);
        let b = RealRegion::interval(5.0, 7.0, true, true);
        let c = a.union_with(&b);
        assert!(c.contains_value(2.0));
        assert!(c.contains_value(6.0));
        assert!(!c.contains_value(4.0));
    }

    #[test]
    fn union_overlapping() {
        let a = RealRegion::interval(1.0, 5.0, true, true);
        let b = RealRegion::interval(3.0, 7.0, true, true);
        let c = a.union_with(&b);
        assert!(c.contains_value(2.0));
        assert!(c.contains_value(6.0));
        assert!(c.contains_value(4.0));
    }

    #[test]
    fn complement() {
        let r = RealRegion::interval(1.0, 5.0, true, false);
        let c = r.complement();
        assert!(!c.contains_value(3.0));
        assert!(c.contains_value(0.0));
        assert!(c.contains_value(5.0));
        assert!(!c.contains_value(1.0));
    }

    #[test]
    fn minus() {
        let a = RealRegion::interval(0.0, 10.0, true, true);
        let b = RealRegion::interval(3.0, 7.0, true, true);
        let c = a.minus(&b);
        assert!(c.contains_value(2.0));
        assert!(!c.contains_value(5.0));
        assert!(c.contains_value(8.0));
    }

    #[test]
    fn double_complement() {
        let r = RealRegion::interval(1.0, 5.0, true, false);
        assert_eq!(r.complement().complement(), r);
    }

    #[test]
    fn dsp_translation() {
        let d = RealDsp(10.0);
        assert_eq!(d.of(&RealPos(3.0)), RealPos(13.0));
        assert_eq!(d.inverse(), RealDsp(-10.0));
    }

    #[test]
    fn dsp_of_all_shifts_region() {
        let r = RealRegion::interval(1.0, 5.0, true, false);
        let d = RealDsp(10.0);
        let shifted = d.of_all(&r);
        assert!(shifted.contains_value(11.0));
        assert!(!shifted.contains_value(15.0));
        assert!(shifted.contains_value(14.9));
    }

    #[test]
    fn dsp_compose_inverse_identity() {
        let d = RealDsp(42.5);
        let id = d.compose(&d.inverse());
        assert!(id.is_identity());
    }

    #[test]
    fn ascending_order() {
        let asc = RealAscending;
        assert!(asc.follows(&RealPos(5.0), &RealPos(3.0)));
        assert!(asc.follows(&RealPos(3.0), &RealPos(3.0)));
        assert!(!asc.follows(&RealPos(3.0), &RealPos(5.0)));
        assert_eq!(
            asc.compare(&RealPos(3.0), &RealPos(3.0)),
            Some(Ordering::Equal)
        );
    }

    #[test]
    fn space_factory() {
        let s = space();
        let r = s.interval(1.0, 5.0, true, false);
        assert!(r.contains(&RealPos(3.0)));
        let d = s.identity_dsp();
        assert!(d.is_identity());
    }

    #[test]
    fn real_count_is_none() {
        assert_eq!(RealRegion::point(1.0).count(), None);
        assert_eq!(RealRegion::interval(0.0, 1.0, true, true).count(), None);
    }

    #[test]
    fn de_morgan_intersect() {
        let a = RealRegion::interval(1.0, 5.0, true, false);
        let b = RealRegion::interval(3.0, 7.0, false, true);
        let lhs = a.intersect(&b);
        let rhs = a.complement().union_with(&b.complement()).complement();
        assert_eq!(lhs, rhs);
    }

    #[test]
    fn union_with_complement_is_full() {
        let r = RealRegion::interval(1.0, 5.0, true, false);
        assert!(r.union_with(&r.complement()).is_full());
    }
}
