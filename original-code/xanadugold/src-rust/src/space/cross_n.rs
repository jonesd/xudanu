use super::traits::*;
use std::cmp::Ordering;
use std::collections::HashMap;
use std::sync::Arc;

type DynRegion = Arc<dyn DynRegionTrait + Send + Sync>;
type DynDsp = Arc<dyn DynDspTrait + Send + Sync>;
type DynOrderSpec = Arc<dyn DynOrderSpecTrait + Send + Sync>;

trait DynPositionTrait: std::fmt::Debug + Send + Sync {
    fn as_any(&self) -> &dyn std::any::Any;
    fn dyn_eq(&self, other: &dyn DynPositionTrait) -> bool;
    fn dyn_hash(&self, hasher: &mut dyn std::hash::Hasher);
    fn dyn_clone(&self) -> DynPosition;
}

trait DynRegionTrait: std::fmt::Debug + Send + Sync {
    fn as_any(&self) -> &dyn std::any::Any;
    fn dyn_is_empty(&self) -> bool;
    fn dyn_is_full(&self) -> bool;
    fn dyn_intersect(&self, other: &dyn DynRegionTrait) -> DynRegion;
    fn dyn_union_with(&self, other: &dyn DynRegionTrait) -> DynRegion;
    fn dyn_complement(&self) -> DynRegion;
    fn dyn_minus(&self, other: &dyn DynRegionTrait) -> DynRegion;
    fn dyn_clone(&self) -> DynRegion;
}

trait DynDspTrait: std::fmt::Debug + Send + Sync {
    fn as_any(&self) -> &dyn std::any::Any;
    fn dyn_inverse(&self) -> DynDsp;
    fn dyn_clone(&self) -> DynDsp;
}

trait DynOrderSpecTrait: std::fmt::Debug + Send + Sync {
    fn dyn_compare(&self, a: &[DynPosition], b: &[DynPosition]) -> Option<Ordering>;
}

#[derive(Debug, Clone)]
pub struct DynPosition(DynPositionInner);

#[derive(Debug, Clone)]
enum DynPositionInner {
    Integer(super::integer::IntegerPos),
    Real(super::real::RealPos),
    Sequence(super::sequence::Sequence),
    Composite(Vec<DynPosition>),
}

impl PartialEq for DynPosition {
    fn eq(&self, other: &Self) -> bool {
        match (&self.0, &other.0) {
            (DynPositionInner::Integer(a), DynPositionInner::Integer(b)) => a == b,
            (DynPositionInner::Real(a), DynPositionInner::Real(b)) => a == b,
            (DynPositionInner::Sequence(a), DynPositionInner::Sequence(b)) => a == b,
            (DynPositionInner::Composite(a), DynPositionInner::Composite(b)) => a == b,
            _ => false,
        }
    }
}

impl Eq for DynPosition {}

impl std::hash::Hash for DynPosition {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        std::mem::discriminant(&self.0).hash(state);
        match &self.0 {
            DynPositionInner::Integer(p) => p.hash(state),
            DynPositionInner::Real(p) => {
                p.value().to_bits().hash(state);
            }
            DynPositionInner::Sequence(p) => p.hash(state),
            DynPositionInner::Composite(v) => v.hash(state),
        }
    }
}

impl DynPosition {
    pub fn integer(v: i64) -> Self {
        DynPosition(DynPositionInner::Integer(super::integer::IntegerPos(v)))
    }

    pub fn real(v: f64) -> Self {
        DynPosition(DynPositionInner::Real(super::real::RealPos(v)))
    }

    pub fn sequence(seq: super::sequence::Sequence) -> Self {
        DynPosition(DynPositionInner::Sequence(seq))
    }

    pub fn composite(parts: Vec<DynPosition>) -> Self {
        DynPosition(DynPositionInner::Composite(parts))
    }

    pub fn as_integer(&self) -> Option<i64> {
        match &self.0 {
            DynPositionInner::Integer(p) => Some(p.0),
            _ => None,
        }
    }

    pub fn as_real(&self) -> Option<f64> {
        match &self.0 {
            DynPositionInner::Real(p) => Some(p.value()),
            _ => None,
        }
    }

    pub fn as_composite(&self) -> Option<&[DynPosition]> {
        match &self.0 {
            DynPositionInner::Composite(v) => Some(v),
            _ => None,
        }
    }
}

#[derive(Debug, Clone)]
pub struct CrossSpaceN {
    spaces: Vec<CrossSpaceNSlot>,
}

#[derive(Debug, Clone)]
pub enum CrossSpaceNSlot {
    Integer(super::integer::IntegerSpace),
    Real(super::real::RealSpace),
    Sequence(super::sequence::SequenceSpace),
    Cross(Box<CrossSpaceN>),
}

impl PartialEq for CrossSpaceN {
    fn eq(&self, other: &Self) -> bool {
        self.spaces.len() == other.spaces.len()
            && self
                .spaces
                .iter()
                .zip(other.spaces.iter())
                .all(|(a, b)| std::mem::discriminant(a) == std::mem::discriminant(b))
    }
}

impl Eq for CrossSpaceN {}

impl std::hash::Hash for CrossSpaceN {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.spaces.len().hash(state);
        for slot in &self.spaces {
            std::mem::discriminant(slot).hash(state);
        }
    }
}

impl CrossSpaceN {
    pub fn new(spaces: Vec<CrossSpaceNSlot>) -> Self {
        assert!(
            !spaces.is_empty(),
            "CrossSpaceN requires at least one dimension"
        );
        CrossSpaceN { spaces }
    }

    pub fn dimension(&self) -> usize {
        self.spaces.len()
    }

    pub fn position(&self, coords: Vec<DynPosition>) -> DynPosition {
        assert_eq!(coords.len(), self.spaces.len());
        DynPosition::composite(coords)
    }

    pub fn box_region(&self, regions: Vec<CrossRegionN>) -> CrossRegionN {
        assert_eq!(regions.len(), self.spaces.len());
        let mut axes = Vec::with_capacity(self.spaces.len());
        for (slot, region) in self.spaces.iter().zip(regions.iter()) {
            axes.push(extract_axis(slot, region));
        }
        CrossRegionN { boxes: vec![axes] }
    }

    pub fn full_region(&self) -> CrossRegionN {
        CrossRegionN::full(self.spaces.len())
    }

    pub fn empty_region(&self) -> CrossRegionN {
        CrossRegionN::empty(self.spaces.len())
    }

    pub fn identity_dsp(&self) -> CrossDspN {
        CrossDspN {
            per_axis: self.spaces.iter().map(|s| s.identity_dsp()).collect(),
        }
    }

    pub fn contains(&self, region: &CrossRegionN, pos: &[DynPosition]) -> bool {
        if pos.len() != self.spaces.len() {
            return false;
        }
        region.boxes.iter().any(|bx| {
            for (i, slot) in self.spaces.iter().enumerate() {
                if let Some(axis) = bx.get(i) {
                    if !axis_contains(slot, axis, &pos[i]) {
                        return false;
                    }
                }
            }
            true
        })
    }
}

impl CrossSpaceNSlot {
    pub fn integer() -> Self {
        CrossSpaceNSlot::Integer(super::integer::IntegerSpace)
    }

    pub fn real() -> Self {
        CrossSpaceNSlot::Real(super::real::RealSpace)
    }

    pub fn sequence() -> Self {
        CrossSpaceNSlot::Sequence(super::sequence::SequenceSpace)
    }

    pub fn cross(inner: CrossSpaceN) -> Self {
        CrossSpaceNSlot::Cross(Box::new(inner))
    }

    fn full_region(&self) -> CrossRegionN {
        match self {
            CrossSpaceNSlot::Integer(_)
            | CrossSpaceNSlot::Real(_)
            | CrossSpaceNSlot::Sequence(_) => CrossRegionN {
                boxes: vec![vec![CrossRegionAxis::Full]],
            },
            CrossSpaceNSlot::Cross(c) => c.full_region(),
        }
    }

    fn empty_region(&self) -> CrossRegionN {
        match self {
            CrossSpaceNSlot::Integer(_)
            | CrossSpaceNSlot::Real(_)
            | CrossSpaceNSlot::Sequence(_) => CrossRegionN {
                boxes: vec![vec![CrossRegionAxis::Empty]],
            },
            CrossSpaceNSlot::Cross(c) => c.empty_region(),
        }
    }

    fn identity_dsp(&self) -> CrossDspNSlot {
        match self {
            CrossSpaceNSlot::Integer(s) => CrossDspNSlot::Integer(s.identity_dsp()),
            CrossSpaceNSlot::Real(s) => CrossDspNSlot::Real(s.identity_dsp()),
            CrossSpaceNSlot::Sequence(s) => CrossDspNSlot::Sequence(s.identity_dsp()),
            CrossSpaceNSlot::Cross(c) => CrossDspNSlot::Cross(c.identity_dsp()),
        }
    }

    fn contains(&self, region: &CrossRegionN, pos: &DynPosition) -> bool {
        let check = |bx: &Vec<CrossRegionAxis>| match (self, &pos.0) {
            (CrossSpaceNSlot::Integer(_), DynPositionInner::Integer(p)) => {
                if let Some(CrossRegionAxis::Integer(r)) = bx.first() {
                    r.contains(p)
                } else {
                    false
                }
            }
            (CrossSpaceNSlot::Real(_), DynPositionInner::Real(p)) => {
                if let Some(CrossRegionAxis::Real(r)) = bx.first() {
                    r.contains(p)
                } else {
                    false
                }
            }
            (CrossSpaceNSlot::Sequence(_), DynPositionInner::Sequence(p)) => {
                if let Some(CrossRegionAxis::Sequence(r)) = bx.first() {
                    r.contains_sequence(p)
                } else {
                    false
                }
            }
            _ => false,
        };
        region.boxes.iter().any(check)
    }
}

fn extract_axis(slot: &CrossSpaceNSlot, region: &CrossRegionN) -> CrossRegionAxis {
    let first_box = match region.boxes.first() {
        Some(b) => b,
        None => return CrossRegionAxis::Empty,
    };
    match (slot, first_box.first()) {
        (CrossSpaceNSlot::Integer(_), Some(CrossRegionAxis::Integer(r))) => {
            CrossRegionAxis::Integer(r.clone())
        }
        (CrossSpaceNSlot::Real(_), Some(CrossRegionAxis::Real(r))) => {
            CrossRegionAxis::Real(r.clone())
        }
        (CrossSpaceNSlot::Sequence(_), Some(CrossRegionAxis::Sequence(r))) => {
            CrossRegionAxis::Sequence(r.clone())
        }
        _ => CrossRegionAxis::Full,
    }
}

fn axis_contains(slot: &CrossSpaceNSlot, axis: &CrossRegionAxis, pos: &DynPosition) -> bool {
    match (slot, axis, &pos.0) {
        (
            CrossSpaceNSlot::Integer(_),
            CrossRegionAxis::Integer(r),
            DynPositionInner::Integer(p),
        ) => r.contains(p),
        (CrossSpaceNSlot::Real(_), CrossRegionAxis::Real(r), DynPositionInner::Real(p)) => {
            r.contains(p)
        }
        (
            CrossSpaceNSlot::Sequence(_),
            CrossRegionAxis::Sequence(r),
            DynPositionInner::Sequence(p),
        ) => r.contains_sequence(p),
        (_, CrossRegionAxis::Full, _) => true,
        (_, CrossRegionAxis::Empty, _) => false,
        _ => false,
    }
}

#[derive(Debug, Clone)]
pub struct CrossRegionN {
    boxes: Vec<Vec<CrossRegionAxis>>,
}

#[derive(Debug, Clone)]
pub enum CrossRegionAxis {
    Empty,
    Full,
    Integer(super::integer::IntegerRegion),
    Real(super::real::RealRegion),
    Sequence(super::sequence::SequenceRegion),
}

impl PartialEq for CrossRegionAxis {
    fn eq(&self, other: &Self) -> bool {
        eq_axis(self, other)
    }
}

impl Eq for CrossRegionAxis {}

impl CrossRegionN {
    pub fn axis_integer(r: super::integer::IntegerRegion) -> Self {
        CrossRegionN {
            boxes: vec![vec![CrossRegionAxis::Integer(r)]],
        }
    }

    pub fn axis_real(r: super::real::RealRegion) -> Self {
        CrossRegionN {
            boxes: vec![vec![CrossRegionAxis::Real(r)]],
        }
    }

    pub fn axis_sequence(r: super::sequence::SequenceRegion) -> Self {
        CrossRegionN {
            boxes: vec![vec![CrossRegionAxis::Sequence(r)]],
        }
    }

    pub fn full(dims: usize) -> Self {
        CrossRegionN {
            boxes: vec![(0..dims).map(|_| CrossRegionAxis::Full).collect()],
        }
    }

    pub fn empty(dims: usize) -> Self {
        CrossRegionN { boxes: Vec::new() }
    }

    pub fn is_empty(&self) -> bool {
        self.boxes.is_empty()
            || self.boxes.iter().all(|b| {
                b.iter().any(|a| match a {
                    CrossRegionAxis::Empty => true,
                    CrossRegionAxis::Integer(r) => r.is_empty(),
                    CrossRegionAxis::Real(r) => r.is_empty(),
                    CrossRegionAxis::Sequence(r) => r.is_empty(),
                    _ => false,
                })
            })
    }

    pub fn is_full(&self) -> bool {
        self.boxes.len() == 1
            && self.boxes[0].iter().all(|a| match a {
                CrossRegionAxis::Full => true,
                CrossRegionAxis::Integer(r) => r.is_full(),
                CrossRegionAxis::Real(r) => r.is_full(),
                CrossRegionAxis::Sequence(r) => r.is_full(),
                _ => false,
            })
    }

    pub fn intersect(&self, other: &Self) -> Self {
        let mut result = Vec::new();
        for ba in &self.boxes {
            for bb in &other.boxes {
                if ba.len() == bb.len() {
                    let axes: Vec<CrossRegionAxis> = ba
                        .iter()
                        .zip(bb.iter())
                        .map(|(a, b)| intersect_axis(a, b))
                        .collect();
                    let any_empty = axes.iter().any(|a| match a {
                        CrossRegionAxis::Empty => true,
                        CrossRegionAxis::Integer(r) => r.is_empty(),
                        CrossRegionAxis::Real(r) => r.is_empty(),
                        CrossRegionAxis::Sequence(r) => r.is_empty(),
                        _ => false,
                    });
                    if !any_empty {
                        result.push(axes);
                    }
                }
            }
        }
        CrossRegionN { boxes: result }
    }

    pub fn union_with(&self, other: &Self) -> Self {
        let mut boxes = self.boxes.clone();
        boxes.extend(other.boxes.clone());
        CrossRegionN { boxes }
    }

    pub fn complement(&self) -> Self {
        if self.boxes.is_empty() {
            return CrossRegionN::full(1);
        }
        let mut result: Option<CrossRegionN> = None;
        for bx in &self.boxes {
            let dims = bx.len();
            let full_axes: Vec<CrossRegionAxis> =
                (0..dims).map(|_| CrossRegionAxis::Full).collect();
            let mut comp_boxes = Vec::new();
            for (i, axis) in bx.iter().enumerate() {
                let c = complement_axis(axis);
                let c_empty = match &c {
                    CrossRegionAxis::Empty => true,
                    CrossRegionAxis::Integer(r) => r.is_empty(),
                    CrossRegionAxis::Real(r) => r.is_empty(),
                    CrossRegionAxis::Sequence(r) => r.is_empty(),
                    _ => false,
                };
                if !c_empty {
                    let mut strip = full_axes.clone();
                    strip[i] = c;
                    comp_boxes.push(strip);
                }
            }
            let box_complement = CrossRegionN { boxes: comp_boxes };
            result = Some(match result {
                None => box_complement,
                Some(prev) => prev.intersect(&box_complement),
            });
        }
        result.unwrap_or_else(|| CrossRegionN::full(1))
    }

    pub fn minus(&self, other: &Self) -> Self {
        self.intersect(&other.complement())
    }

    pub fn axis_count(&self) -> usize {
        self.boxes.first().map(|b| b.len()).unwrap_or(0)
    }

    pub fn axis(&self, index: usize) -> Option<&CrossRegionAxis> {
        self.boxes.first()?.get(index)
    }
}

impl PartialEq for CrossRegionN {
    fn eq(&self, other: &Self) -> bool {
        self.boxes == other.boxes
    }
}

impl Eq for CrossRegionN {}

impl std::hash::Hash for CrossRegionN {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.boxes.len().hash(state);
    }
}

fn intersect_axis(a: &CrossRegionAxis, b: &CrossRegionAxis) -> CrossRegionAxis {
    use CrossRegionAxis::*;
    match (a, b) {
        (Empty, _) | (_, Empty) => Empty,
        (Full, other) | (other, Full) => other.clone(),
        (Integer(a), Integer(b)) => Integer(a.intersect(b)),
        (Real(a), Real(b)) => Real(a.intersect(b)),
        (Sequence(a), Sequence(b)) => Sequence(a.intersect(b)),
        _ => Empty,
    }
}

fn union_axis(a: &CrossRegionAxis, b: &CrossRegionAxis) -> CrossRegionAxis {
    use CrossRegionAxis::*;
    match (a, b) {
        (Empty, other) | (other, Empty) => other.clone(),
        (Full, _) | (_, Full) => Full,
        (Integer(a), Integer(b)) => Integer(a.union_with(b)),
        (Real(a), Real(b)) => Real(a.union_with(b)),
        (Sequence(a), Sequence(b)) => Sequence(a.union_with(b)),
        _ => Empty,
    }
}

fn complement_axis(a: &CrossRegionAxis) -> CrossRegionAxis {
    use CrossRegionAxis::*;
    match a {
        Empty => Full,
        Full => Empty,
        Integer(r) => Integer(r.complement()),
        Real(r) => Real(r.complement()),
        Sequence(r) => Sequence(r.complement()),
    }
}

fn minus_axis(a: &CrossRegionAxis, b: &CrossRegionAxis) -> CrossRegionAxis {
    use CrossRegionAxis::*;
    match (a, b) {
        (_, Full) => Empty,
        (Empty, _) => Empty,
        (Integer(a), Integer(b)) => Integer(a.minus(b)),
        (Real(a), Real(b)) => Real(a.minus(b)),
        (Sequence(a), Sequence(b)) => Sequence(a.minus(b)),
        _ => a.clone(),
    }
}

fn eq_axis(a: &CrossRegionAxis, b: &CrossRegionAxis) -> bool {
    use CrossRegionAxis::*;
    match (a, b) {
        (Empty, Empty) | (Full, Full) => true,
        (Integer(a), Integer(b)) => a == b,
        (Real(a), Real(b)) => a == b,
        (Sequence(a), Sequence(b)) => a == b,
        _ => false,
    }
}

#[derive(Debug, Clone)]
pub struct CrossDspN {
    per_axis: Vec<CrossDspNSlot>,
}

#[derive(Debug, Clone)]
pub enum CrossDspNSlot {
    Integer(super::integer::IntegerDsp),
    Real(super::real::RealDsp),
    Sequence(super::sequence::SequenceDsp),
    Cross(CrossDspN),
}

impl CrossDspN {
    pub fn inverse(&self) -> Self {
        CrossDspN {
            per_axis: self.per_axis.iter().map(|s| s.inverse()).collect(),
        }
    }

    pub fn axis_count(&self) -> usize {
        self.per_axis.len()
    }
}

impl CrossDspNSlot {
    fn inverse(&self) -> Self {
        match self {
            CrossDspNSlot::Integer(d) => CrossDspNSlot::Integer(d.inverse()),
            CrossDspNSlot::Real(d) => CrossDspNSlot::Real(d.inverse()),
            CrossDspNSlot::Sequence(d) => CrossDspNSlot::Sequence(d.inverse()),
            CrossDspNSlot::Cross(c) => CrossDspNSlot::Cross(c.inverse()),
        }
    }
}

#[derive(Debug, Clone)]
pub struct CrossOrderN {
    ascending: bool,
    dims: usize,
}

impl CrossOrderN {
    pub fn ascending(dims: usize) -> Self {
        CrossOrderN {
            ascending: true,
            dims,
        }
    }

    pub fn descending(dims: usize) -> Self {
        CrossOrderN {
            ascending: false,
            dims,
        }
    }

    pub fn compare(&self, a: &[DynPosition], b: &[DynPosition]) -> Option<Ordering> {
        if a.len() != b.len() || a.len() != self.dims {
            return None;
        }
        for i in 0..a.len() {
            let cmp = compare_dyn_positions(&a[i], &b[i]);
            if cmp != Ordering::Equal {
                return if self.ascending {
                    Some(cmp)
                } else {
                    Some(cmp.reverse())
                };
            }
        }
        Some(Ordering::Equal)
    }
}

fn compare_dyn_positions(a: &DynPosition, b: &DynPosition) -> Ordering {
    match (&a.0, &b.0) {
        (DynPositionInner::Integer(a), DynPositionInner::Integer(b)) => a.0.cmp(&b.0),
        (DynPositionInner::Real(a), DynPositionInner::Real(b)) => {
            a.value().partial_cmp(&b.value()).unwrap_or(Ordering::Equal)
        }
        (DynPositionInner::Sequence(a), DynPositionInner::Sequence(b)) => a.compare_to(b),
        (DynPositionInner::Composite(a), DynPositionInner::Composite(b)) => {
            for (ap, bp) in a.iter().zip(b.iter()) {
                let cmp = compare_dyn_positions(ap, bp);
                if cmp != Ordering::Equal {
                    return cmp;
                }
            }
            Ordering::Equal
        }
        _ => Ordering::Equal,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn cross_space_n_2d_integer() {
        let space = CrossSpaceN::new(vec![CrossSpaceNSlot::integer(), CrossSpaceNSlot::integer()]);
        assert_eq!(space.dimension(), 2);

        let pos = space.position(vec![DynPosition::integer(3), DynPosition::integer(7)]);
        let coords = pos.as_composite().unwrap();
        assert_eq!(coords[0].as_integer().unwrap(), 3);
        assert_eq!(coords[1].as_integer().unwrap(), 7);
    }

    #[test]
    fn cross_space_n_3d_mixed() {
        let space = CrossSpaceN::new(vec![
            CrossSpaceNSlot::integer(),
            CrossSpaceNSlot::real(),
            CrossSpaceNSlot::sequence(),
        ]);
        assert_eq!(space.dimension(), 3);

        let full = space.full_region();
        assert!(full.is_full());

        let empty = space.empty_region();
        assert!(empty.is_empty());
    }

    #[test]
    fn cross_region_intersect() {
        let space = CrossSpaceN::new(vec![CrossSpaceNSlot::integer(), CrossSpaceNSlot::integer()]);
        let a = space.box_region(vec![
            CrossRegionN::axis_integer(super::super::integer::IntegerRegion::interval(0, 10)),
            CrossRegionN::axis_integer(super::super::integer::IntegerRegion::interval(0, 10)),
        ]);
        let b = space.box_region(vec![
            CrossRegionN::axis_integer(super::super::integer::IntegerRegion::interval(5, 15)),
            CrossRegionN::axis_integer(super::super::integer::IntegerRegion::interval(3, 7)),
        ]);
        let c = a.intersect(&b);
        assert!(c.axis_count() == 2, "intersect should have 2 axes");
        assert!(
            space.contains(&c, &[DynPosition::integer(7), DynPosition::integer(5)]),
            "intersect should contain (7, 5)"
        );
        assert!(
            space.contains(&c, &[DynPosition::integer(9), DynPosition::integer(6)]),
            "intersect should contain (9, 6)"
        );
        assert!(!space.contains(&c, &[DynPosition::integer(2), DynPosition::integer(5)],));
        assert!(!space.contains(&c, &[DynPosition::integer(7), DynPosition::integer(8)],));
    }

    #[test]
    fn cross_region_complement() {
        let space = CrossSpaceN::new(vec![CrossSpaceNSlot::integer(), CrossSpaceNSlot::integer()]);
        let r = space.box_region(vec![
            CrossRegionN::axis_integer(super::super::integer::IntegerRegion::interval(0, 10)),
            CrossRegionN::axis_integer(super::super::integer::IntegerRegion::interval(0, 10)),
        ]);
        let c = r.complement();
        assert!(!space.contains(&c, &[DynPosition::integer(5), DynPosition::integer(5)],));
    }

    #[test]
    fn cross_order_ascending() {
        let order = CrossOrderN::ascending(2);
        let a = vec![DynPosition::integer(1), DynPosition::integer(2)];
        let b = vec![DynPosition::integer(1), DynPosition::integer(3)];
        assert_eq!(order.compare(&a, &b), Some(Ordering::Less));
    }

    #[test]
    fn cross_dsp_inverse() {
        let space = CrossSpaceN::new(vec![CrossSpaceNSlot::integer(), CrossSpaceNSlot::integer()]);
        let dsp = space.identity_dsp();
        let inv = dsp.inverse();
        assert_eq!(dsp.axis_count(), 2);
        assert_eq!(inv.axis_count(), 2);
    }

    #[test]
    fn dyn_position_equality() {
        let a = DynPosition::integer(42);
        let b = DynPosition::integer(42);
        let c = DynPosition::integer(43);
        assert_eq!(a, b);
        assert_ne!(a, c);
    }
}
