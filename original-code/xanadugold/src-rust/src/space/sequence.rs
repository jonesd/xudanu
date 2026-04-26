use super::traits::*;
use std::cmp::Ordering;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Sequence {
    shift: i64,
    numbers: Vec<i64>,
}

impl Sequence {
    pub fn zero() -> Self {
        Sequence {
            shift: 0,
            numbers: Vec::new(),
        }
    }

    pub fn one(a: i64) -> Self {
        if a == 0 {
            return Self::zero();
        }
        Sequence {
            shift: 0,
            numbers: vec![a],
        }
    }

    pub fn two(a: i64, b: i64) -> Self {
        Sequence::from_numbers_with_shift(vec![a, b], 0)
    }

    pub fn three(a: i64, b: i64, c: i64) -> Self {
        Sequence::from_numbers_with_shift(vec![a, b, c], 0)
    }

    pub fn from_numbers(mut numbers: Vec<i64>) -> Self {
        while numbers.last() == Some(&0) {
            numbers.pop();
        }
        while numbers.first() == Some(&0) {
            numbers.remove(0);
        }
        Sequence {
            shift: 0,
            numbers,
        }
    }

    fn from_numbers_with_shift(mut numbers: Vec<i64>, mut shift: i64) -> Self {
        while numbers.last() == Some(&0) {
            numbers.pop();
        }
        while numbers.first() == Some(&0) {
            numbers.remove(0);
            shift += 1;
        }
        Sequence { shift, numbers }
    }

    pub fn at(&self, index: i64) -> i64 {
        let adjusted = index - self.shift;
        if adjusted < 0 || adjusted >= self.numbers.len() as i64 {
            0
        } else {
            self.numbers[adjusted as usize]
        }
    }

    pub fn shift(&self) -> i64 {
        self.shift
    }

    pub fn numbers(&self) -> &[i64] {
        &self.numbers
    }

    pub fn is_zero(&self) -> bool {
        self.numbers.is_empty()
    }

    pub fn first_index(&self) -> Option<i64> {
        if self.numbers.is_empty() {
            None
        } else {
            Some(self.shift)
        }
    }

    pub fn last_index(&self) -> Option<i64> {
        if self.numbers.is_empty() {
            None
        } else {
            Some(self.shift + self.numbers.len() as i64 - 1)
        }
    }

    pub fn count(&self) -> usize {
        self.numbers.len()
    }

    pub fn shifted(&self, offset: i64) -> Self {
        Sequence {
            shift: self.shift + offset,
            numbers: self.numbers.clone(),
        }
    }

    pub fn plus(&self, other: &Sequence) -> Self {
        let start = self
            .first_index()
            .unwrap_or(0)
            .min(other.first_index().unwrap_or(0));
        let end = self
            .last_index()
            .unwrap_or(-1)
            .max(other.last_index().unwrap_or(-1));
        if start > end {
            return Self::zero();
        }
        let len = (end - start + 1) as usize;
        let mut result = vec![0i64; len];
        for i in 0..len {
            let idx = start + i as i64;
            result[i] = self.at(idx) + other.at(idx);
        }
        Sequence::from_numbers_with_shift(result, start)
    }

    pub fn minus(&self, other: &Sequence) -> Self {
        let start = self
            .first_index()
            .unwrap_or(0)
            .min(other.first_index().unwrap_or(0));
        let end = self
            .last_index()
            .unwrap_or(-1)
            .max(other.last_index().unwrap_or(-1));
        if start > end {
            return Self::zero();
        }
        let len = (end - start + 1) as usize;
        let mut result = vec![0i64; len];
        for i in 0..len {
            let idx = start + i as i64;
            result[i] = self.at(idx) - other.at(idx);
        }
        Sequence::from_numbers_with_shift(result, start)
    }

    pub fn compare_to(&self, other: &Sequence) -> Ordering {
        let min_idx = self
            .first_index()
            .unwrap_or(0)
            .min(other.first_index().unwrap_or(0));
        let max_idx = self
            .last_index()
            .unwrap_or(-1)
            .max(other.last_index().unwrap_or(-1));
        for i in min_idx..=max_idx {
            let a = self.at(i);
            let b = other.at(i);
            if a < b {
                return Ordering::Less;
            }
            if a > b {
                return Ordering::Greater;
            }
        }
        Ordering::Equal
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, Default)]
pub struct SequenceSpace;

impl SequenceSpace {
    pub fn new() -> Self {
        SequenceSpace
    }

    pub fn position(&self, numbers: Vec<i64>) -> Sequence {
        Sequence::from_numbers(numbers)
    }

    pub fn interval(&self, start: &Sequence, stop: &Sequence) -> SequenceRegion {
        SequenceRegion::interval(start.clone(), stop.clone())
    }

    pub fn above(&self, start: &Sequence, inclusive: bool) -> SequenceRegion {
        SequenceRegion::above(start.clone(), inclusive)
    }

    pub fn below(&self, stop: &Sequence, inclusive: bool) -> SequenceRegion {
        SequenceRegion::below(stop.clone(), inclusive)
    }

    pub fn mapping(&self, shift: i64, translation: Sequence) -> SequenceDsp {
        SequenceDsp { shift, translation }
    }
}

impl Space for SequenceSpace {
    type Position = SequencePos;
    type Region = SequenceRegion;
    type Dsp = SequenceDsp;

    fn empty_region(&self) -> Self::Region {
        SequenceRegion::empty()
    }

    fn full_region(&self) -> Self::Region {
        SequenceRegion::full()
    }

    fn identity_dsp(&self) -> Self::Dsp {
        SequenceDsp {
            shift: 0,
            translation: Sequence::zero(),
        }
    }

    fn ascending(&self) -> Box<dyn OrderSpec<Position = Self::Position>> {
        Box::new(SequenceAscending)
    }

    fn descending(&self) -> Box<dyn OrderSpec<Position = Self::Position>> {
        Box::new(SequenceDescending)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct SequencePos(pub Sequence);

impl SequencePos {
    pub fn value(&self) -> &Sequence {
        &self.0
    }

    pub fn into_inner(self) -> Sequence {
        self.0
    }
}

impl Position for SequencePos {
    type Region = SequenceRegion;

    fn as_region(&self) -> Self::Region {
        SequenceRegion::singleton(self.0.clone())
    }
}

#[derive(Debug, Clone)]
pub struct SequenceEdge {
    pub sequence: Sequence,
    pub inclusive: bool,
}

impl PartialEq for SequenceEdge {
    fn eq(&self, other: &Self) -> bool {
        self.sequence == other.sequence && self.inclusive == other.inclusive
    }
}

impl Eq for SequenceEdge {}

impl std::hash::Hash for SequenceEdge {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.sequence.hash(state);
        self.inclusive.hash(state);
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct SequenceRegion {
    starts_inside: bool,
    transitions: Vec<SequenceEdge>,
}

impl SequenceRegion {
    pub fn empty() -> Self {
        SequenceRegion {
            starts_inside: false,
            transitions: Vec::new(),
        }
    }

    pub fn full() -> Self {
        SequenceRegion {
            starts_inside: true,
            transitions: Vec::new(),
        }
    }

    pub fn singleton(seq: Sequence) -> Self {
        SequenceRegion {
            starts_inside: false,
            transitions: vec![
                SequenceEdge {
                    sequence: seq.clone(),
                    inclusive: true,
                },
                SequenceEdge {
                    sequence: seq,
                    inclusive: false,
                },
            ],
        }
    }

    pub fn interval(start: Sequence, stop: Sequence) -> Self {
        if start.compare_to(&stop) != Ordering::Less {
            return Self::empty();
        }
        SequenceRegion {
            starts_inside: false,
            transitions: vec![
                SequenceEdge {
                    sequence: start,
                    inclusive: true,
                },
                SequenceEdge {
                    sequence: stop,
                    inclusive: false,
                },
            ],
        }
    }

    pub fn above(start: Sequence, inclusive: bool) -> Self {
        SequenceRegion {
            starts_inside: false,
            transitions: vec![SequenceEdge {
                sequence: start,
                inclusive,
            }],
        }
    }

    pub fn below(stop: Sequence, inclusive: bool) -> Self {
        SequenceRegion {
            starts_inside: true,
            transitions: vec![SequenceEdge {
                sequence: stop,
                inclusive,
            }],
        }
    }

    pub fn contains_sequence(&self, seq: &Sequence) -> bool {
        let idx = self
            .transitions
            .partition_point(|e| e.sequence.compare_to(seq) == Ordering::Less);
        if idx < self.transitions.len() && self.transitions[idx].sequence == *seq {
            return self.transitions[idx].inclusive;
        }
        if idx % 2 == 0 {
            self.starts_inside
        } else {
            !self.starts_inside
        }
    }
}

impl Default for SequenceRegion {
    fn default() -> Self {
        Self::empty()
    }
}

fn merge_sequence_regions(
    a: &SequenceRegion,
    b: &SequenceRegion,
    combine: impl Fn(bool, bool) -> bool,
) -> SequenceRegion {
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
        let n_seq = match (av, bv) {
            (Some(ae), Some(be)) => {
                if ae.sequence.compare_to(&be.sequence) != Ordering::Greater {
                    ae.sequence.clone()
                } else {
                    be.sequence.clone()
                }
            }
            (Some(ae), None) => ae.sequence.clone(),
            (None, Some(be)) => be.sequence.clone(),
            (None, None) => break,
        };

        let a_at = if av.map_or(false, |e| e.sequence == n_seq) {
            av.unwrap().inclusive
        } else {
            a_between
        };
        let b_at = if bv.map_or(false, |e| e.sequence == n_seq) {
            bv.unwrap().inclusive
        } else {
            b_between
        };

        if av.map_or(false, |e| e.sequence == n_seq) {
            a_between = !a_between;
            ai += 1;
        }
        if bv.map_or(false, |e| e.sequence == n_seq) {
            b_between = !b_between;
            bi += 1;
        }

        let new_at = combine(a_at, b_at);
        let new_between = combine(a_between, b_between);

        if new_at != new_between {
            if !new_at && new_between {
                result.push(SequenceEdge {
                    sequence: n_seq.clone(),
                    inclusive: false,
                });
                cur = true;
            } else {
                result.push(SequenceEdge {
                    sequence: n_seq.clone(),
                    inclusive: true,
                });
                result.push(SequenceEdge {
                    sequence: n_seq.clone(),
                    inclusive: false,
                });
                cur = false;
            }
        } else if new_at != cur {
            result.push(SequenceEdge {
                sequence: n_seq.clone(),
                inclusive: new_at,
            });
            cur = new_at;
        }
    }

    SequenceRegion {
        starts_inside: new_starts,
        transitions: result,
    }
}

impl Region for SequenceRegion {
    type Position = SequencePos;

    fn is_empty(&self) -> bool {
        !self.starts_inside && self.transitions.is_empty()
    }

    fn is_full(&self) -> bool {
        self.starts_inside && self.transitions.is_empty()
    }

    fn contains(&self, pos: &Self::Position) -> bool {
        self.contains_sequence(&pos.0)
    }

    fn intersects(&self, other: &Self) -> bool {
        !self.intersect(other).is_empty()
    }

    fn intersect(&self, other: &Self) -> Self {
        merge_sequence_regions(self, other, |a, b| a && b)
    }

    fn union_with(&self, other: &Self) -> Self {
        merge_sequence_regions(self, other, |a, b| a || b)
    }

    fn complement(&self) -> Self {
        SequenceRegion {
            starts_inside: !self.starts_inside,
            transitions: self
                .transitions
                .iter()
                .map(|e| SequenceEdge {
                    sequence: e.sequence.clone(),
                    inclusive: !e.inclusive,
                })
                .collect(),
        }
    }

    fn minus(&self, other: &Self) -> Self {
        merge_sequence_regions(self, other, |a, b| a && !b)
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

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct SequenceDsp {
    shift: i64,
    translation: Sequence,
}

impl SequenceDsp {
    pub fn new(shift: i64, translation: Sequence) -> Self {
        SequenceDsp { shift, translation }
    }

    pub fn shift(&self) -> i64 {
        self.shift
    }

    pub fn translation(&self) -> &Sequence {
        &self.translation
    }

    pub fn is_identity(&self) -> bool {
        self.shift == 0 && self.translation.is_zero()
    }

    fn transform(&self, seq: &Sequence) -> Sequence {
        seq.shifted(self.shift).plus(&self.translation)
    }

    fn _inverse_transform(&self, seq: &Sequence) -> Sequence {
        seq.minus(&self.translation).shifted(-self.shift)
    }
}

impl Dsp for SequenceDsp {
    type Position = SequencePos;
    type Region = SequenceRegion;

    fn of(&self, pos: &Self::Position) -> Self::Position {
        SequencePos(self.transform(&pos.0))
    }

    fn of_all(&self, region: &Self::Region) -> Self::Region {
        SequenceRegion {
            starts_inside: region.starts_inside,
            transitions: region
                .transitions
                .iter()
                .map(|e| SequenceEdge {
                    sequence: self.transform(&e.sequence),
                    inclusive: e.inclusive,
                })
                .collect(),
        }
    }

    fn inverse(&self) -> Self {
        let inv_translation = Sequence::zero().minus(&self.translation).shifted(-self.shift);
        SequenceDsp {
            shift: -self.shift,
            translation: inv_translation,
        }
    }

    fn compose(&self, other: &Self) -> Self {
        let new_shift = self.shift + other.shift;
        let new_translation = self
            .translation
            .plus(&other.translation.shifted(self.shift));
        SequenceDsp {
            shift: new_shift,
            translation: new_translation,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SequenceAscending;

impl OrderSpec for SequenceAscending {
    type Position = SequencePos;

    fn follows(&self, a: &Self::Position, b: &Self::Position) -> bool {
        a.0.compare_to(&b.0) != Ordering::Less
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SequenceDescending;

impl OrderSpec for SequenceDescending {
    type Position = SequencePos;

    fn follows(&self, a: &Self::Position, b: &Self::Position) -> bool {
        a.0.compare_to(&b.0) != Ordering::Greater
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sequence_zero() {
        let z = Sequence::zero();
        assert!(z.is_zero());
        assert_eq!(z.at(0), 0);
        assert_eq!(z.at(1), 0);
        assert_eq!(z.at(-1), 0);
    }

    #[test]
    fn sequence_one() {
        let s = Sequence::one(5);
        assert_eq!(s.at(0), 5);
        assert_eq!(s.at(1), 0);
        assert!(Sequence::one(0).is_zero());
    }

    #[test]
    fn sequence_two() {
        let s = Sequence::two(3, 7);
        assert_eq!(s.at(0), 3);
        assert_eq!(s.at(1), 7);
        assert_eq!(s.at(2), 0);
    }

    #[test]
    fn sequence_trims_zeros() {
        let s = Sequence::from_numbers(vec![0, 0, 3, 7, 0, 0]);
        assert_eq!(s.numbers(), &[3, 7]);
        assert_eq!(s.at(0), 3);
        assert_eq!(s.at(1), 7);
    }

    #[test]
    fn sequence_compare() {
        let a = Sequence::two(1, 2);
        let b = Sequence::two(1, 3);
        let c = Sequence::two(2, 0);
        assert_eq!(a.compare_to(&b), Ordering::Less);
        assert_eq!(b.compare_to(&a), Ordering::Greater);
        assert_eq!(a.compare_to(&a), Ordering::Equal);
        assert_eq!(c.compare_to(&a), Ordering::Greater);
    }

    #[test]
    fn sequence_plus_minus() {
        let a = Sequence::two(1, 2);
        let b = Sequence::two(3, 4);
        let sum = a.plus(&b);
        assert_eq!(sum.at(0), 4);
        assert_eq!(sum.at(1), 6);

        let diff = a.minus(&b);
        assert_eq!(diff.at(0), -2);
        assert_eq!(diff.at(1), -2);
    }

    #[test]
    fn sequence_shifted() {
        let s = Sequence::two(1, 2);
        let shifted = s.shifted(3);
        assert_eq!(shifted.at(3), 1);
        assert_eq!(shifted.at(4), 2);
        assert_eq!(shifted.at(0), 0);
    }

    #[test]
    fn region_empty() {
        let r = SequenceRegion::empty();
        assert!(r.is_empty());
        assert!(!r.contains_sequence(&Sequence::zero()));
    }

    #[test]
    fn region_full() {
        let r = SequenceRegion::full();
        assert!(r.is_full());
        assert!(r.contains_sequence(&Sequence::zero()));
        assert!(r.contains_sequence(&Sequence::two(1, 2)));
    }

    #[test]
    fn region_singleton() {
        let r = SequenceRegion::singleton(Sequence::two(1, 2));
        assert!(r.contains_sequence(&Sequence::two(1, 2)));
        assert!(!r.contains_sequence(&Sequence::two(1, 3)));
    }

    #[test]
    fn region_interval() {
        let lo = Sequence::one(1);
        let hi = Sequence::one(5);
        let r = SequenceRegion::interval(lo.clone(), hi.clone());
        assert!(r.contains_sequence(&Sequence::one(3)));
        assert!(r.contains_sequence(&Sequence::one(1)));
        assert!(!r.contains_sequence(&Sequence::one(5)));
        assert!(!r.contains_sequence(&Sequence::one(6)));
    }

    #[test]
    fn region_above() {
        let r = SequenceRegion::above(Sequence::one(3), true);
        assert!(r.contains_sequence(&Sequence::one(3)));
        assert!(r.contains_sequence(&Sequence::one(10)));
        assert!(!r.contains_sequence(&Sequence::one(2)));
    }

    #[test]
    fn region_below() {
        let r = SequenceRegion::below(Sequence::one(5), true);
        assert!(r.contains_sequence(&Sequence::one(5)));
        assert!(r.contains_sequence(&Sequence::one(0)));
        assert!(!r.contains_sequence(&Sequence::one(6)));
    }

    #[test]
    fn region_intersect() {
        let a = SequenceRegion::interval(Sequence::one(1), Sequence::one(10));
        let b = SequenceRegion::interval(Sequence::one(5), Sequence::one(15));
        let c = a.intersect(&b);
        assert!(c.contains_sequence(&Sequence::one(7)));
        assert!(!c.contains_sequence(&Sequence::one(3)));
        assert!(!c.contains_sequence(&Sequence::one(12)));
    }

    #[test]
    fn region_union() {
        let a = SequenceRegion::interval(Sequence::one(1), Sequence::one(5));
        let b = SequenceRegion::interval(Sequence::one(3), Sequence::one(8));
        let c = a.union_with(&b);
        assert!(c.contains_sequence(&Sequence::one(2)));
        assert!(c.contains_sequence(&Sequence::one(7)));
    }

    #[test]
    fn region_complement() {
        let r = SequenceRegion::interval(Sequence::one(3), Sequence::one(7));
        let c = r.complement();
        assert!(!c.contains_sequence(&Sequence::one(5)));
        assert!(c.contains_sequence(&Sequence::one(0)));
        assert!(c.contains_sequence(&Sequence::one(7)));
    }

    #[test]
    fn dsp_identity() {
        let d = SequenceDsp::new(0, Sequence::zero());
        assert!(d.is_identity());
        let seq = SequencePos(Sequence::two(3, 7));
        assert_eq!(d.of(&seq), seq);
    }

    #[test]
    fn dsp_shift_and_translate() {
        let d = SequenceDsp::new(2, Sequence::one(10));
        let pos = SequencePos(Sequence::one(5));
        let result = d.of(&pos);
        assert_eq!(result.0.at(0), 10);
        assert_eq!(result.0.at(2), 5);
        assert_eq!(result.0.at(3), 0);
    }

    #[test]
    fn dsp_inverse() {
        let d = SequenceDsp::new(2, Sequence::one(10));
        let inv = d.inverse();
        let pos = SequencePos(Sequence::one(5));
        let roundtrip = inv.of(&d.of(&pos));
        assert_eq!(roundtrip.0, pos.0);
    }

    #[test]
    fn ascending_order() {
        let asc = SequenceAscending;
        let a = SequencePos(Sequence::one(3));
        let b = SequencePos(Sequence::one(5));
        assert!(asc.follows(&b, &a));
        assert!(!asc.follows(&a, &b));
        assert!(asc.follows(&a, &a));
    }

    #[test]
    fn space_factory() {
        let s = SequenceSpace::new();
        let r = s.empty_region();
        assert!(r.is_empty());
        let d = s.identity_dsp();
        assert!(d.is_identity());
    }

    #[test]
    fn double_complement() {
        let r = SequenceRegion::interval(Sequence::one(1), Sequence::one(5));
        assert_eq!(r.complement().complement(), r);
    }

    #[test]
    fn intersect_shared_boundary() {
        let a = SequenceRegion::above(Sequence::one(3), false);
        let b = SequenceRegion::above(Sequence::one(3), true);
        let c = a.intersect(&b);
        assert!(!c.contains_sequence(&Sequence::one(3)));
        assert!(c.contains_sequence(&Sequence::one(4)));
        assert!(c.contains_sequence(&Sequence::one(100)));
    }

    #[test]
    fn union_shared_boundary() {
        let a = SequenceRegion::below(Sequence::one(5), true);
        let b = SequenceRegion::above(Sequence::one(5), true);
        let c = a.union_with(&b);
        assert!(c.contains_sequence(&Sequence::one(4)));
        assert!(c.contains_sequence(&Sequence::one(5)));
        assert!(c.contains_sequence(&Sequence::one(6)));
    }

    #[test]
    fn minus_shared_boundary() {
        let a = SequenceRegion::below(Sequence::one(5), true);
        let b = SequenceRegion::above(Sequence::one(3), true);
        let c = a.minus(&b);
        assert!(c.contains_sequence(&Sequence::one(2)));
        assert!(!c.contains_sequence(&Sequence::one(3)));
        assert!(!c.contains_sequence(&Sequence::one(4)));
    }

    #[test]
    fn intersect_above_above_same_boundary() {
        let a = SequenceRegion::above(Sequence::one(3), true);
        let b = SequenceRegion::above(Sequence::one(3), false);
        let c = a.intersect(&b);
        assert!(!c.contains_sequence(&Sequence::one(3)));
        assert!(c.contains_sequence(&Sequence::one(4)));
    }

    #[test]
    fn multi_element_sequences_in_region() {
        let lo = Sequence::two(1, 0);
        let hi = Sequence::two(1, 5);
        let r = SequenceRegion::interval(lo.clone(), hi.clone());
        assert!(r.contains_sequence(&Sequence::two(1, 3)));
        assert!(!r.contains_sequence(&Sequence::two(2, 0)));
    }
}
