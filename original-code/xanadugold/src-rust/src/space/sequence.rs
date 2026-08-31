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
        Sequence { shift: 0, numbers }
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

    /// Extend with two path elements — the lattice's collision-free
    /// concurrent allocation shape (FR-51 Phase 1).
    pub fn append_pair(&self, a: i64, b: i64) -> Self {
        let mut nums = self.numbers.to_vec();
        nums.push(a);
        nums.push(b);
        Sequence::from_numbers(nums)
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

    pub fn first(&self) -> Sequence {
        for (i, &v) in self.numbers.iter().enumerate() {
            if v == 0 {
                return Sequence::from_numbers_with_shift(self.numbers[..i].to_vec(), self.shift);
            }
        }
        self.clone()
    }

    pub fn rest(&self) -> Sequence {
        for (i, &v) in self.numbers.iter().enumerate() {
            if v == 0 {
                let rest = &self.numbers[i + 1..];
                return Sequence::from_numbers_with_shift(rest.to_vec(), self.shift + i as i64 + 1);
            }
        }
        Sequence::zero()
    }

    pub fn with_rest(&self, other: &Sequence) -> Sequence {
        let mut nums = self.numbers.clone();
        nums.push(0);
        nums.extend_from_slice(&other.numbers);
        Sequence {
            shift: self.shift,
            numbers: nums,
        }
    }

    pub fn with_last(&self, n: i64) -> Sequence {
        if n == 0 {
            return self.clone();
        }
        let mut nums = self.numbers.clone();
        nums.push(n);
        Sequence {
            shift: self.shift,
            numbers: nums,
        }
    }

    pub fn with_first(&self, n: i64) -> Sequence {
        if n == 0 {
            return self.clone();
        }
        if self.numbers.is_empty() {
            return Sequence::one(n);
        }
        let mut nums = vec![n];
        nums.extend_from_slice(&self.numbers);
        Sequence {
            shift: self.shift,
            numbers: nums,
        }
    }

    pub fn compare_prefix(&self, other: &Sequence, limit: i64) -> Ordering {
        let self_has = self.last_index().map_or(false, |l| l >= limit);
        let other_has = other.last_index().map_or(false, |l| l >= limit);
        if !self_has && !other_has {
            return Ordering::Equal;
        }
        if !self_has {
            return match other.first_non_zero_up_to(limit) {
                Some(v) if v > 0 => Ordering::Less,
                Some(v) if v < 0 => Ordering::Greater,
                _ => Ordering::Equal,
            };
        }
        if !other_has {
            return match self.first_non_zero_up_to(limit) {
                Some(v) if v > 0 => Ordering::Greater,
                Some(v) if v < 0 => Ordering::Less,
                _ => Ordering::Equal,
            };
        }
        let min_idx = self
            .first_index()
            .unwrap_or(0)
            .min(other.first_index().unwrap_or(0));
        for i in min_idx..=limit {
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

    fn first_non_zero_up_to(&self, limit: i64) -> Option<i64> {
        let start = self.first_index().unwrap_or(0);
        for i in start..=limit {
            let v = self.at(i);
            if v != 0 {
                return Some(v);
            }
        }
        None
    }

    pub fn from_dotted(s: &str) -> Self {
        let parts: Vec<i64> = s.split('.').filter_map(|p| p.parse().ok()).collect();
        if parts.is_empty() {
            return Sequence::zero();
        }
        let mut nums = Vec::new();
        for (i, v) in parts.iter().enumerate() {
            if i > 0 {
                nums.push(0);
            }
            nums.push(*v);
        }
        Sequence::from_numbers(nums)
    }
}

impl std::fmt::Display for Sequence {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        if self.numbers.is_empty() {
            return write!(f, "0");
        }
        let mut first = true;
        let mut i = 0i64;
        while i < self.shift {
            if !first {
                write!(f, ".")?;
            }
            write!(f, "0")?;
            first = false;
            i += 1;
        }
        for &v in &self.numbers {
            if !first {
                write!(f, ".")?;
            }
            write!(f, "{}", v)?;
            first = false;
        }
        Ok(())
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

    pub fn prefixed_by(&self, sequence: &Sequence, limit: i64) -> SequenceRegion {
        SequenceRegion::prefixed_by(sequence, limit)
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
    prefix_filter: Option<PrefixFilter>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
struct PrefixFilter {
    sequence: Sequence,
    limit: i64,
}

impl SequenceRegion {
    pub fn empty() -> Self {
        SequenceRegion {
            starts_inside: false,
            transitions: Vec::new(),
            prefix_filter: None,
        }
    }

    pub fn full() -> Self {
        SequenceRegion {
            starts_inside: true,
            transitions: Vec::new(),
            prefix_filter: None,
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
            prefix_filter: None,
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
            prefix_filter: None,
        }
    }

    pub fn above(start: Sequence, inclusive: bool) -> Self {
        SequenceRegion {
            starts_inside: false,
            transitions: vec![SequenceEdge {
                sequence: start,
                inclusive,
            }],
            prefix_filter: None,
        }
    }

    pub fn below(stop: Sequence, inclusive: bool) -> Self {
        SequenceRegion {
            starts_inside: true,
            transitions: vec![SequenceEdge {
                sequence: stop,
                inclusive,
            }],
            prefix_filter: None,
        }
    }

    pub fn prefixed_by(sequence: &Sequence, limit: i64) -> Self {
        SequenceRegion {
            starts_inside: true,
            transitions: Vec::new(),
            prefix_filter: Some(PrefixFilter {
                sequence: sequence.clone(),
                limit,
            }),
        }
    }

    /// Read-only transition edges (wire serialization of regions —
    /// lattice tombstone regions are interval/above/singleton
    /// shapes, round-tripped via those constructors).
    pub fn edge_descriptors(&self) -> (bool, Vec<(Vec<i64>, bool)>) {
        (
            self.starts_inside,
            self.transitions
                .iter()
                .map(|e| (e.sequence.numbers().to_vec(), e.inclusive))
                .collect(),
        )
    }

    /// Reconstruct from edge descriptors (the shapes our tombstones
    /// use: interval [a,b) — two edges inclusive/exclusive; above a —
    /// one inclusive edge; empty — none).
    pub fn from_edge_descriptors(
        starts_inside: bool,
        edges: &[(Vec<i64>, bool)],
    ) -> Option<SequenceRegion> {
        if starts_inside {
            return None;
        }
        match edges {
            [] => Some(SequenceRegion::empty()),
            [(a, true)] => Some(SequenceRegion::above(
                Sequence::from_numbers(a.clone()),
                true,
            )),
            [(a, true), (b, false)] => Some(SequenceRegion::interval(
                Sequence::from_numbers(a.clone()),
                Sequence::from_numbers(b.clone()),
            )),
            _ => None,
        }
    }

    pub fn contains_sequence(&self, seq: &Sequence) -> bool {
        if let Some(pf) = &self.prefix_filter {
            let matches = seq.compare_prefix(&pf.sequence, pf.limit) == Ordering::Equal;
            if !matches {
                return false;
            }
            if self.transitions.is_empty() {
                return true;
            }
        }
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
    let new_prefix = match (&a.prefix_filter, &b.prefix_filter) {
        (Some(p), None) => Some(p.clone()),
        (None, Some(p)) => Some(p.clone()),
        (Some(p1), Some(p2)) if p1 == p2 => Some(p1.clone()),
        _ => None,
    };
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
        prefix_filter: new_prefix,
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
            prefix_filter: self.prefix_filter.clone(),
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
            prefix_filter: region.prefix_filter.as_ref().map(|pf| PrefixFilter {
                sequence: self.transform(&pf.sequence),
                limit: pf.limit,
            }),
        }
    }

    fn inverse(&self) -> Self {
        let inv_translation = Sequence::zero()
            .minus(&self.translation)
            .shifted(-self.shift);
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

    #[test]
    fn first_returns_prefix_before_zero() {
        let s = Sequence::from_numbers(vec![1, 0, 3, 5]);
        let f = s.first();
        assert_eq!(f, Sequence::one(1));
    }

    #[test]
    fn rest_returns_suffix_after_zero() {
        let s = Sequence::from_numbers(vec![1, 0, 3, 5]);
        let r = s.rest();
        assert_eq!(r.at(2), 3);
        assert_eq!(r.at(3), 5);
        assert_eq!(r.shift(), 2);
    }

    #[test]
    fn first_no_zero_returns_self() {
        let s = Sequence::two(3, 5);
        assert_eq!(s.first(), s);
    }

    #[test]
    fn rest_no_zero_returns_zero() {
        let s = Sequence::two(3, 5);
        assert!(s.rest().is_zero());
    }

    #[test]
    fn first_empty_returns_zero() {
        assert!(Sequence::zero().first().is_zero());
    }

    #[test]
    fn rest_empty_returns_zero() {
        assert!(Sequence::zero().rest().is_zero());
    }

    #[test]
    fn first_with_multiple_zeros() {
        let s = Sequence::from_numbers(vec![1, 0, 3, 0, 5]);
        assert_eq!(s.first(), Sequence::one(1));
    }

    #[test]
    fn with_rest_concatenates_with_zero_separator() {
        let a = Sequence::one(1);
        let b = Sequence::two(3, 5);
        let result = a.with_rest(&b);
        assert_eq!(result.at(0), 1);
        assert_eq!(result.at(1), 0);
        assert_eq!(result.at(2), 3);
        assert_eq!(result.at(3), 5);
    }

    #[test]
    fn with_rest_roundtrip() {
        let original = Sequence::from_numbers(vec![1, 0, 3, 5]);
        assert_eq!(original.first().with_rest(&original.rest()), original);
    }

    #[test]
    fn with_rest_with_zero_other() {
        let a = Sequence::one(1);
        let result = a.with_rest(&Sequence::zero());
        assert_eq!(result.at(0), 1);
        assert_eq!(result.at(1), 0);
        assert!(result.at(2) == 0);
    }

    #[test]
    fn with_last_appends() {
        let s = Sequence::two(1, 2).with_last(3);
        assert_eq!(s.at(0), 1);
        assert_eq!(s.at(1), 2);
        assert_eq!(s.at(2), 3);
    }

    #[test]
    fn with_first_prepends() {
        let s = Sequence::two(2, 3).with_first(1);
        assert_eq!(s.at(0), 1);
        assert_eq!(s.at(1), 2);
        assert_eq!(s.at(2), 3);
    }

    #[test]
    fn compare_prefix_equal_up_to_limit() {
        let a = Sequence::from_numbers(vec![1, 3, 5]);
        let b = Sequence::from_numbers(vec![1, 3, 7]);
        assert_eq!(a.compare_prefix(&b, 1), Ordering::Equal);
    }

    #[test]
    fn compare_prefix_differs_within_range() {
        let a = Sequence::from_numbers(vec![1, 3, 5]);
        let b = Sequence::from_numbers(vec![1, 4, 5]);
        assert_eq!(a.compare_prefix(&b, 1), Ordering::Less);
    }

    #[test]
    fn compare_prefix_beyond_array() {
        let a = Sequence::from_numbers(vec![1, 3]);
        let b = Sequence::from_numbers(vec![1, 3, 5]);
        assert_eq!(a.compare_prefix(&b, 1), Ordering::Equal);
    }

    #[test]
    fn from_dotted_and_display_roundtrip() {
        let s = Sequence::from_dotted("3.7.5");
        assert_eq!(s.at(0), 3);
        assert_eq!(s.at(1), 0);
        assert_eq!(s.at(2), 7);
        assert_eq!(s.at(3), 0);
        assert_eq!(s.at(4), 5);
    }

    #[test]
    fn display_shows_dotted() {
        let s = Sequence::from_numbers(vec![1, 0, 3, 0, 5]);
        let displayed = format!("{}", s);
        assert!(displayed.contains("1"));
        assert!(displayed.contains("3"));
        assert!(displayed.contains("5"));
    }

    #[test]
    fn prefixed_by_matches_prefix() {
        let prefix = Sequence::from_numbers(vec![1, 3]);
        let region = SequenceRegion::prefixed_by(&prefix, 1);
        assert!(
            region.contains_sequence(&Sequence::from_numbers(vec![1, 3, 5])),
            "prefix [1,3] should contain [1,3,5]"
        );
        assert!(
            region.contains_sequence(&Sequence::from_numbers(vec![1, 3, 7])),
            "prefix [1,3] should contain [1,3,7]"
        );
        assert!(
            !region.contains_sequence(&Sequence::from_numbers(vec![1, 4, 5])),
            "prefix [1,3] should not contain [1,4,5]"
        );
    }

    #[test]
    fn prefixed_by_single_element() {
        let prefix = Sequence::one(1);
        let region = SequenceRegion::prefixed_by(&prefix, 0);
        assert!(region.contains_sequence(&Sequence::from_numbers(vec![1, 0, 5])));
        assert!(!region.contains_sequence(&Sequence::from_numbers(vec![2, 0, 5])));
    }

    #[test]
    fn prefixed_by_intersect_with_interval() {
        let prefix = Sequence::one(1);
        let region = SequenceRegion::prefixed_by(&prefix, 0);
        let interval = SequenceRegion::interval(
            Sequence::from_numbers(vec![1, 0, 0]),
            Sequence::from_numbers(vec![1, 0, 10]),
        );
        let intersection = region.intersect(&interval);
        assert!(intersection.contains_sequence(&Sequence::from_numbers(vec![1, 0, 5])));
    }

    #[test]
    fn space_prefixed_by() {
        let space = SequenceSpace::new();
        let prefix = Sequence::two(1, 3);
        let region = space.prefixed_by(&prefix, 1);
        assert!(region.contains_sequence(&Sequence::from_numbers(vec![1, 3, 5])));
    }

    #[test]
    fn tumbler_decomposition_hierarchy() {
        let addr = Sequence::from_numbers(vec![1, 0, 3, 0, 5]);
        let server = addr.first();
        assert_eq!(server, Sequence::one(1));
        let rest1 = addr.rest();
        assert_eq!(rest1.at(2), 3);
        assert_eq!(rest1.at(4), 5);
        let work = rest1.first();
        assert_eq!(work.at(2), 3);
        let rest2 = rest1.rest();
        let position = rest2.first();
        assert_eq!(position.at(4), 5);
    }

    #[test]
    fn tumbler_recompose_hierarchy() {
        let server = Sequence::one(1);
        let work = Sequence::one(3);
        let position = Sequence::one(5);
        let addr = server.with_rest(&work).with_rest(&position);
        assert_eq!(addr, Sequence::from_numbers(vec![1, 0, 3, 0, 5]));
    }
}
