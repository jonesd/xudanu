use std::sync::Arc;

use super::range_element::{Carrier, RangeElement};
use super::xn_region::XnRegion;

const MAX_LEAF_SIZE: usize = 16384;

pub type Crum = [u8; 32];

pub fn compute_leaf_crum(
    entries: &[(i64, Arc<Carrier>)],
    region: &XnRegion,
    default: &Option<Arc<Carrier>>,
) -> Crum {
    let mut hasher = blake3::Hasher::new();
    hasher.update(b"leaf:");
    for (start, end) in region.intervals() {
        hasher.update(&start.to_le_bytes());
        hasher.update(&end.to_le_bytes());
    }
    for (pos, carrier) in entries {
        hasher.update(&pos.to_le_bytes());
        hasher.update(&carrier.element.content_fingerprint());
    }
    if let Some(d) = default {
        hasher.update(b"d:");
        hasher.update(&d.element.content_fingerprint());
    }
    *hasher.finalize().as_bytes()
}

fn compute_split_crum(split: &XnRegion, in_crum: &Crum, out_crum: &Crum) -> Crum {
    let mut hasher = blake3::Hasher::new();
    hasher.update(b"split:");
    for (start, end) in split.intervals() {
        hasher.update(&start.to_le_bytes());
        hasher.update(&end.to_le_bytes());
    }
    hasher.update(in_crum);
    hasher.update(out_crum);
    *hasher.finalize().as_bytes()
}

fn compute_dsp_crum(offset: i64, child_crum: &Crum) -> Crum {
    let mut hasher = blake3::Hasher::new();
    hasher.update(b"dsp:");
    hasher.update(&offset.to_le_bytes());
    hasher.update(child_crum);
    *hasher.finalize().as_bytes()
}

#[derive(Debug, Clone, PartialEq)]
pub(crate) enum Loaf {
    Leaf {
        region: XnRegion,
        entries: Vec<(i64, Arc<Carrier>)>,
        default: Option<Arc<Carrier>>,
    },
    Split {
        split: XnRegion,
        in_child: Box<Loaf>,
        out_child: Box<Loaf>,
    },
    Dsp {
        offset: i64,
        child: Box<Loaf>,
    },
}

#[allow(dead_code)]
impl Loaf {
    pub fn compute_crum(&self) -> Crum {
        match self {
            Loaf::Leaf {
                entries,
                region,
                default,
                ..
            } => compute_leaf_crum(entries, region, default),
            Loaf::Split {
                split,
                in_child,
                out_child,
                ..
            } => compute_split_crum(split, &in_child.compute_crum(), &out_child.compute_crum()),
            Loaf::Dsp { offset, child, .. } => compute_dsp_crum(*offset, &child.compute_crum()),
        }
    }

    fn new_leaf(region: XnRegion, entries: Vec<(i64, Arc<Carrier>)>) -> Self {
        Loaf::Leaf {
            region,
            entries,
            default: None,
        }
    }

    fn new_leaf_with_default(region: XnRegion, default: Arc<Carrier>) -> Self {
        Loaf::Leaf {
            region,
            entries: Vec::new(),
            default: Some(default),
        }
    }

    fn build_bulk(
        sorted_entries: Vec<(i64, Arc<Carrier>)>,
        default: Option<Arc<Carrier>>,
        region: XnRegion,
    ) -> Self {
        if sorted_entries.is_empty() && default.is_none() {
            return Loaf::empty_leaf();
        }
        if sorted_entries.is_empty() {
            return Loaf::Leaf {
                region,
                entries: sorted_entries,
                default,
            };
        }
        if sorted_entries.len() <= MAX_LEAF_SIZE {
            let first = sorted_entries.first().unwrap().0;
            let last = sorted_entries.last().unwrap().0;
            let entry_region = XnRegion::interval(first, last + 1);
            let leaf_region = if default.is_some() {
                region
            } else {
                entry_region
            };
            return Loaf::Leaf {
                region: leaf_region,
                entries: sorted_entries,
                default,
            };
        }
        let mid = sorted_entries.len() / 2;
        let split_pos = sorted_entries[mid].0;
        let in_entries = sorted_entries[..mid].to_vec();
        let out_entries = sorted_entries[mid..].to_vec();
        let split = XnRegion::below(split_pos);
        let in_region = region.intersect(&split);
        let out_region = region.intersect(&XnRegion::above(split_pos));
        let in_child = Box::new(Loaf::build_bulk(in_entries, default.clone(), in_region));
        let out_child = Box::new(Loaf::build_bulk(out_entries, default.clone(), out_region));
        Loaf::Split {
            split,
            in_child,
            out_child,
        }
    }

    fn empty_leaf() -> Self {
        Loaf::Leaf {
            region: XnRegion::empty(),
            entries: Vec::new(),
            default: None,
        }
    }

    fn domain(&self) -> XnRegion {
        match self {
            Loaf::Leaf { region, .. } => region.clone(),
            Loaf::Split {
                in_child,
                out_child,
                ..
            } => in_child.domain().union(&out_child.domain()),
            Loaf::Dsp { offset, child } => shift_region(&child.domain(), *offset),
        }
    }

    fn count(&self) -> u64 {
        match self {
            Loaf::Leaf {
                entries,
                region,
                default,
            } => {
                if default.is_some() {
                    return match region.count() {
                        Some(c) => c,
                        None => u64::MAX,
                    };
                }
                entries.len() as u64
            }
            Loaf::Split {
                in_child,
                out_child,
                ..
            } => {
                let c = in_child.count().saturating_add(out_child.count());
                if c == u64::MAX {
                    return u64::MAX;
                }
                c
            }
            Loaf::Dsp { child, .. } => child.count(),
        }
    }

    fn is_infinite(&self) -> bool {
        match self {
            Loaf::Leaf {
                default: Some(_),
                region,
                ..
            } => !region.is_finite(),
            Loaf::Leaf { default: None, .. } => false,
            Loaf::Split {
                in_child,
                out_child,
                ..
            } => in_child.is_infinite() || out_child.is_infinite(),
            Loaf::Dsp { child, .. } => child.is_infinite(),
        }
    }

    fn is_empty(&self) -> bool {
        match self {
            Loaf::Leaf {
                entries,
                region,
                default,
            } => default.is_none() && entries.is_empty() && region.is_empty(),
            Loaf::Split {
                in_child,
                out_child,
                ..
            } => in_child.is_empty() && out_child.is_empty(),
            Loaf::Dsp { child, .. } => child.is_empty(),
        }
    }

    fn default_value(&self) -> Option<RangeElement> {
        match self {
            Loaf::Leaf {
                default: Some(c), ..
            } => Some(c.element.clone()),
            Loaf::Leaf { default: None, .. } => None,
            Loaf::Split { in_child, .. } => in_child.default_value().or_else(|| None),
            Loaf::Dsp { child, .. } => child.default_value(),
        }
    }

    fn fetch(&self, position: i64) -> Option<Arc<Carrier>> {
        match self {
            Loaf::Leaf {
                entries,
                region,
                default,
            } => {
                if !region.contains(position) {
                    return None;
                }
                match entries.binary_search_by_key(&position, |(p, _)| *p) {
                    Ok(idx) => Some(entries[idx].1.clone()),
                    Err(_) => default.clone(),
                }
            }
            Loaf::Split {
                split,
                in_child,
                out_child,
            } => {
                if split.contains(position) {
                    in_child.fetch(position)
                } else {
                    out_child.fetch(position)
                }
            }
            Loaf::Dsp { offset, child } => {
                let child_pos = position - offset;
                child.fetch(child_pos)
            }
        }
    }

    fn has_position(&self, position: i64) -> bool {
        match self {
            Loaf::Leaf {
                entries,
                region,
                default,
            } => {
                if !region.contains(position) {
                    return false;
                }
                if default.is_some() {
                    return true;
                }
                entries.binary_search_by_key(&position, |(p, _)| *p).is_ok()
            }
            Loaf::Split {
                split,
                in_child,
                out_child,
            } => {
                if split.contains(position) {
                    in_child.has_position(position)
                } else {
                    out_child.has_position(position)
                }
            }
            Loaf::Dsp { offset, child } => child.has_position(position - offset),
        }
    }

    fn with(&self, position: i64, carrier: Arc<Carrier>) -> Loaf {
        match self {
            Loaf::Leaf {
                region,
                entries,
                default,
            } => {
                let mut new_region = region.clone();
                if !new_region.contains(position) {
                    new_region = new_region.with(position);
                }
                let mut new_entries = entries.clone();
                match new_entries.binary_search_by_key(&position, |(p, _)| *p) {
                    Ok(idx) => new_entries[idx].1 = carrier,
                    Err(idx) => new_entries.insert(idx, (position, carrier)),
                }
                if new_entries.len() <= MAX_LEAF_SIZE {
                    Loaf::Leaf {
                        region: new_region,
                        entries: new_entries,
                        default: default.clone(),
                    }
                } else {
                    let loaf = Loaf::Leaf {
                        region: new_region,
                        entries: new_entries,
                        default: default.clone(),
                    };
                    loaf.maybe_split()
                }
            }
            Loaf::Split {
                split,
                in_child,
                out_child,
            } => {
                if split.contains(position) {
                    let new_in = in_child.with(position, carrier);
                    Loaf::Split {
                        split: split.clone(),
                        in_child: Box::new(new_in),
                        out_child: out_child.clone(),
                    }
                } else {
                    let new_out = out_child.with(position, carrier);
                    Loaf::Split {
                        split: split.clone(),
                        in_child: in_child.clone(),
                        out_child: Box::new(new_out),
                    }
                }
            }
            Loaf::Dsp { offset, child } => {
                let child_pos = position - offset;
                let new_child = child.with(child_pos, carrier);
                Loaf::Dsp {
                    offset: *offset,
                    child: Box::new(new_child),
                }
            }
        }
    }

    fn without(&self, position: i64) -> Loaf {
        match self {
            Loaf::Leaf {
                region,
                entries,
                default,
            } => {
                let mut new_entries = entries.clone();
                if let Ok(idx) = new_entries.binary_search_by_key(&position, |(p, _)| *p) {
                    new_entries.remove(idx);
                }
                let new_region = region.without(position);
                if default.is_some() && new_region.contains(position) {
                    let default_val = default.clone().unwrap();
                    new_entries.push((position, default_val.clone()));
                    new_entries.sort_by_key(|(p, _)| *p);
                }
                Loaf::Leaf {
                    region: new_region,
                    entries: new_entries,
                    default: default.clone(),
                }
            }
            Loaf::Split {
                split,
                in_child,
                out_child,
            } => {
                if split.contains(position) {
                    let new_in = in_child.without(position);
                    Loaf::Split {
                        split: split.clone(),
                        in_child: Box::new(new_in),
                        out_child: out_child.clone(),
                    }
                } else {
                    let new_out = out_child.without(position);
                    Loaf::Split {
                        split: split.clone(),
                        in_child: in_child.clone(),
                        out_child: Box::new(new_out),
                    }
                }
            }
            Loaf::Dsp { offset, child } => {
                let child_pos = position - offset;
                let new_child = child.without(child_pos);
                Loaf::Dsp {
                    offset: *offset,
                    child: Box::new(new_child),
                }
            }
        }
    }

    fn copy(&self, region: &XnRegion) -> Loaf {
        if region.is_empty() || self.is_empty() {
            return Loaf::empty_leaf();
        }
        let dom = self.domain();
        let intersection = dom.intersect(region);
        if intersection.is_empty() {
            return Loaf::empty_leaf();
        }
        if dom.is_subset_of(region) {
            return self.clone();
        }
        match self {
            Loaf::Leaf {
                region: leaf_region,
                entries,
                default,
            } => {
                let new_region = leaf_region.intersect(region);
                let new_entries: Vec<(i64, Arc<Carrier>)> = entries
                    .iter()
                    .filter(|(p, _)| region.contains(*p))
                    .cloned()
                    .collect();
                Loaf::Leaf {
                    region: new_region,
                    entries: new_entries,
                    default: default.clone(),
                }
            }
            Loaf::Split {
                split,
                in_child,
                out_child,
            } => {
                let in_region = region.intersect(split);
                let out_region = region.minus(split);
                let new_in = if in_region.is_empty() {
                    Loaf::empty_leaf()
                } else {
                    in_child.copy(&in_region)
                };
                let new_out = if out_region.is_empty() {
                    Loaf::empty_leaf()
                } else {
                    out_child.copy(&out_region)
                };
                if new_in.is_empty() && new_out.is_empty() {
                    Loaf::empty_leaf()
                } else if new_in.is_empty() {
                    new_out
                } else if new_out.is_empty() {
                    new_in
                } else {
                    Loaf::Split {
                        split: split.clone(),
                        in_child: Box::new(new_in),
                        out_child: Box::new(new_out),
                    }
                }
            }
            Loaf::Dsp { offset, child } => {
                let child_region = shift_region_inverted(region, *offset);
                let new_child = child.copy(&child_region);
                if new_child.is_empty() {
                    Loaf::empty_leaf()
                } else {
                    Loaf::Dsp {
                        offset: *offset,
                        child: Box::new(new_child),
                    }
                }
            }
        }
    }

    fn splay(&mut self, region: &XnRegion) -> SplayResult {
        if self.is_empty() {
            return SplayResult::Outside;
        }
        let dom = self.domain();
        if dom.is_subset_of(region) {
            return SplayResult::FullyContained;
        }
        if !dom.intersects(region) {
            return SplayResult::Outside;
        }
        self.actual_splay(region)
    }

    fn actual_splay(&mut self, region: &XnRegion) -> SplayResult {
        match self {
            Loaf::Leaf {
                region: leaf_region,
                entries,
                default,
            } => {
                let in_region = leaf_region.intersect(region);
                let out_region = leaf_region.minus(region);
                if out_region.is_empty() {
                    return SplayResult::FullyContained;
                }
                if in_region.is_empty() {
                    return SplayResult::Outside;
                }
                let in_entries: Vec<(i64, Arc<Carrier>)> = entries
                    .iter()
                    .filter(|(p, _)| region.contains(*p))
                    .cloned()
                    .collect();
                let out_entries: Vec<(i64, Arc<Carrier>)> = entries
                    .iter()
                    .filter(|(p, _)| !region.contains(*p))
                    .cloned()
                    .collect();
                let in_loaf = Loaf::Leaf {
                    region: in_region,
                    entries: in_entries,
                    default: default.clone(),
                };
                let out_loaf = Loaf::Leaf {
                    region: out_region,
                    entries: out_entries,
                    default: default.clone(),
                };
                *self = Loaf::Split {
                    split: region.intersect(leaf_region),
                    in_child: Box::new(in_loaf),
                    out_child: Box::new(out_loaf),
                };
                SplayResult::Partial
            }
            Loaf::Split {
                split,
                in_child,
                out_child,
            } => {
                let mut in_res = in_child.splay(region);
                let mut out_res = out_child.splay(&region.minus(split));

                if out_res as u8 > in_res as u8 {
                    std::mem::swap(&mut in_res, &mut out_res);
                    std::mem::swap(in_child, out_child);
                    *split = split.complement();
                }

                match (in_res, out_res) {
                    (SplayResult::FullyContained, SplayResult::Outside) => {
                        SplayResult::FullyContained
                    }
                    (SplayResult::Outside, SplayResult::Outside) => SplayResult::Outside,
                    (SplayResult::FullyContained, SplayResult::FullyContained) => {
                        SplayResult::FullyContained
                    }
                    _ => {
                        match (in_res, out_res) {
                            (SplayResult::Partial, SplayResult::Outside) => {
                                let new_in = in_child.extract_in_part();
                                let new_out_inner = in_child.extract_out_part();
                                let old_out =
                                    std::mem::replace(out_child, Box::new(Loaf::empty_leaf()));
                                *in_child = Box::new(new_in);
                                *out_child = Box::new(Loaf::make_split(
                                    split.clone(),
                                    new_out_inner,
                                    *old_out,
                                ));
                            }
                            (SplayResult::FullyContained, SplayResult::Partial) => {
                                let old_in =
                                    std::mem::replace(in_child, Box::new(Loaf::empty_leaf()));
                                let new_in_inner = Loaf::make_split(
                                    split.clone(),
                                    *old_in,
                                    out_child.extract_in_part(),
                                );
                                let new_out = out_child.extract_out_part();
                                *in_child = Box::new(new_in_inner);
                                *out_child = Box::new(new_out);
                            }
                            (SplayResult::Partial, SplayResult::Partial) => {
                                let in_in = in_child.extract_in_part();
                                let in_out = in_child.extract_out_part();
                                let out_in = out_child.extract_in_part();
                                let out_out = out_child.extract_out_part();
                                let new_in = Loaf::make_split(split.clone(), in_in, out_in);
                                let new_out = Loaf::make_split(split.clone(), in_out, out_out);
                                *in_child = Box::new(new_in);
                                *out_child = Box::new(new_out);
                            }
                            _ => {}
                        }
                        let in_dom = in_child.domain();
                        let out_dom = out_child.domain();
                        let new_split = region.intersect(&in_dom.union(&out_dom));
                        *split = new_split;
                        SplayResult::Partial
                    }
                }
            }
            Loaf::Dsp { offset, child } => {
                let child_region = shift_region_inverted(region, *offset);
                let result = child.splay(&child_region);
                if result == SplayResult::Partial {
                    let materialized = Loaf::Split {
                        split: shift_region(&child.domain(), *offset),
                        in_child: Box::new(child.extract_in_part().transformed_by(*offset)),
                        out_child: Box::new(child.extract_out_part().transformed_by(*offset)),
                    };
                    *self = materialized;
                }
                result
            }
        }
    }

    fn extract_in_part(&mut self) -> Loaf {
        match self {
            Loaf::Leaf { .. } => self.clone(),
            Loaf::Split { in_child, .. } => std::mem::replace(&mut **in_child, Loaf::empty_leaf()),
            Loaf::Dsp { .. } => self.clone(),
        }
    }

    fn extract_out_part(&mut self) -> Loaf {
        match self {
            Loaf::Leaf { .. } => Loaf::empty_leaf(),
            Loaf::Split { out_child, .. } => {
                std::mem::replace(&mut **out_child, Loaf::empty_leaf())
            }
            Loaf::Dsp { .. } => Loaf::empty_leaf(),
        }
    }

    fn make_split(split: XnRegion, in_child: Loaf, out_child: Loaf) -> Loaf {
        if in_child.is_empty() && out_child.is_empty() {
            return Loaf::empty_leaf();
        }
        if in_child.is_empty() {
            return out_child;
        }
        if out_child.is_empty() {
            return in_child;
        }
        Loaf::Split {
            split,
            in_child: Box::new(in_child),
            out_child: Box::new(out_child),
        }
    }

    fn maybe_split(self) -> Loaf {
        match &self {
            Loaf::Leaf {
                entries,
                region,
                default,
            } => {
                if entries.len() <= MAX_LEAF_SIZE {
                    return self;
                }
                let mid = entries.len() / 2;
                let split_pos = entries[mid].0;
                let in_entries = entries[..mid].to_vec();
                let out_entries = entries[mid..].to_vec();
                let in_region = region.intersect(&XnRegion::below(split_pos));
                let out_region = region.intersect(&XnRegion::above(split_pos));
                Loaf::Split {
                    split: XnRegion::below(split_pos),
                    in_child: Box::new(Loaf::Leaf {
                        region: in_region,
                        entries: in_entries,
                        default: default.clone(),
                    }),
                    out_child: Box::new(Loaf::Leaf {
                        region: out_region,
                        entries: out_entries,
                        default: default.clone(),
                    }),
                }
            }
            Loaf::Split { .. } | Loaf::Dsp { .. } => self,
        }
    }

    fn all_entries(&self) -> Vec<(i64, Arc<Carrier>)> {
        match self {
            Loaf::Leaf { entries, .. } => entries.clone(),
            Loaf::Split {
                in_child,
                out_child,
                ..
            } => {
                let mut result = in_child.all_entries();
                result.extend(out_child.all_entries());
                result.sort_by_key(|(p, _)| *p);
                result
            }
            Loaf::Dsp { offset, child } => child
                .all_entries()
                .into_iter()
                .map(|(p, c)| (p + offset, c))
                .collect(),
        }
    }

    fn shared_region(&self, other: &Loaf) -> XnRegion {
        let my_entries = self.all_entries();
        let other_entries = other.all_entries();
        let mut shared = XnRegion::empty();
        for (pos, carrier) in &my_entries {
            if let Some(idx) = other_entries.binary_search_by_key(pos, |(p, _)| *p).ok() {
                if *carrier == other_entries[idx].1 {
                    shared = shared.with(*pos);
                }
            }
        }
        shared
    }

    fn positions_of(&self, value: &Carrier) -> XnRegion {
        let entries = self.all_entries();
        let mut region = XnRegion::empty();
        for (pos, carrier) in &entries {
            if **carrier == *value {
                region = region.with(*pos);
            }
        }
        region
    }

    fn transformed_by(&self, offset: i64) -> Loaf {
        if offset == 0 {
            return self.clone();
        }
        Loaf::Dsp {
            offset,
            child: Box::new(self.clone()),
        }
    }

    fn transform_materialized(&self, offset: i64) -> Loaf {
        match self {
            Loaf::Leaf {
                region,
                entries,
                default,
            } => {
                let new_region = shift_region(region, offset);
                let new_entries: Vec<(i64, Arc<Carrier>)> = entries
                    .iter()
                    .map(|(p, c)| (p + offset, c.clone()))
                    .collect();
                Loaf::Leaf {
                    region: new_region,
                    entries: new_entries,
                    default: default.clone(),
                }
            }
            Loaf::Split {
                split,
                in_child,
                out_child,
            } => {
                let new_split = shift_region(split, offset);
                Loaf::Split {
                    split: new_split,
                    in_child: Box::new(in_child.transform_materialized(offset)),
                    out_child: Box::new(out_child.transform_materialized(offset)),
                }
            }
            Loaf::Dsp {
                offset: existing,
                child,
            } => child.transform_materialized(*existing + offset),
        }
    }

    fn combine(&self, other: &Loaf, limit: &XnRegion) -> Result<Loaf, String> {
        if self.is_empty() {
            return Ok(other.clone());
        }
        if other.is_empty() {
            return Ok(self.clone());
        }
        let my_dom = self.domain().intersect(limit);
        let other_dom = other.domain().intersect(limit);
        if my_dom.intersect(&other_dom).is_empty() {
            return Ok(self.merge_disjoint(other, limit));
        }
        Err("combine: overlapping domains not yet supported".into())
    }

    fn merge_disjoint(&self, other: &Loaf, limit: &XnRegion) -> Loaf {
        let self_copy = self.copy(limit);
        let other_copy = other.copy(limit);
        if self_copy.is_empty() {
            return other_copy;
        }
        if other_copy.is_empty() {
            return self_copy;
        }
        let split = self_copy.domain();
        Loaf::Split {
            split,
            in_child: Box::new(self_copy),
            out_child: Box::new(other_copy),
        }
    }
}

fn shift_region(region: &XnRegion, offset: i64) -> XnRegion {
    let intervals = region.intervals();
    let mut result = XnRegion::empty();
    for (start, stop) in intervals {
        let new_start = start.wrapping_add(offset);
        let new_stop = stop.wrapping_add(offset);
        if new_start < new_stop {
            result = result.union(&XnRegion::interval(new_start, new_stop));
        }
    }
    result
}

fn shift_region_inverted(region: &XnRegion, offset: i64) -> XnRegion {
    shift_region(region, -offset)
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SplayResult {
    Outside = 0,
    Partial = 1,
    FullyContained = 2,
}

#[derive(Debug, Clone, PartialEq)]
pub struct OrglRoot {
    inner: OrglInner,
}

#[derive(Debug, Clone, PartialEq)]
enum OrglInner {
    Empty,
    Actual {
        loaf: Loaf,
        simple_domain: XnRegion,
        cached_crum: Option<Crum>,
    },
}

impl OrglRoot {
    pub fn empty() -> Self {
        OrglRoot {
            inner: OrglInner::Empty,
        }
    }

    pub(crate) fn from_loaf(loaf: Loaf) -> Self {
        let domain = loaf.domain();
        let crum = loaf.compute_crum();
        OrglRoot {
            inner: OrglInner::Actual {
                loaf,
                simple_domain: domain,
                cached_crum: Some(crum),
            },
        }
    }

    pub fn from_bulk_entries(
        entries: Vec<(i64, Arc<Carrier>)>,
        default: Option<Arc<Carrier>>,
        region: XnRegion,
    ) -> Self {
        if entries.is_empty() && default.is_none() {
            return OrglRoot::empty();
        }
        OrglRoot::from_loaf(Loaf::build_bulk(entries, default, region))
    }

    pub fn with_default(region: XnRegion, default: Arc<Carrier>) -> Self {
        let loaf = Loaf::new_leaf_with_default(region, default);
        OrglRoot::from_loaf(loaf)
    }

    pub fn domain(&self) -> XnRegion {
        match &self.inner {
            OrglInner::Empty => XnRegion::empty(),
            OrglInner::Actual { loaf, .. } => loaf.domain(),
        }
    }

    pub fn simple_domain(&self) -> &XnRegion {
        match &self.inner {
            OrglInner::Empty => {
                static EMPTY: std::sync::OnceLock<XnRegion> = std::sync::OnceLock::new();
                EMPTY.get_or_init(XnRegion::empty)
            }
            OrglInner::Actual { simple_domain, .. } => simple_domain,
        }
    }

    pub fn count(&self) -> u64 {
        match &self.inner {
            OrglInner::Empty => 0,
            OrglInner::Actual { loaf, .. } => loaf.count(),
        }
    }

    pub fn is_empty(&self) -> bool {
        match &self.inner {
            OrglInner::Empty => true,
            OrglInner::Actual { loaf, .. } => loaf.is_empty(),
        }
    }

    pub fn is_infinite(&self) -> bool {
        match &self.inner {
            OrglInner::Empty => false,
            OrglInner::Actual { loaf, .. } => loaf.is_infinite(),
        }
    }

    pub fn default_value(&self) -> Option<RangeElement> {
        match &self.inner {
            OrglInner::Empty => None,
            OrglInner::Actual { loaf, .. } => loaf.default_value(),
        }
    }

    pub fn fetch(&self, position: i64) -> Option<Arc<Carrier>> {
        match &self.inner {
            OrglInner::Empty => None,
            OrglInner::Actual { loaf, .. } => loaf.fetch(position),
        }
    }

    pub fn has_position(&self, position: i64) -> bool {
        match &self.inner {
            OrglInner::Empty => false,
            OrglInner::Actual { loaf, .. } => loaf.has_position(position),
        }
    }

    pub fn with(&self, position: i64, carrier: Arc<Carrier>) -> OrglRoot {
        match &self.inner {
            OrglInner::Empty => {
                let region = XnRegion::singleton(position);
                let loaf = Loaf::new_leaf(region, vec![(position, carrier)]);
                OrglRoot::from_loaf(loaf)
            }
            OrglInner::Actual { loaf, .. } => OrglRoot::from_loaf(loaf.with(position, carrier)),
        }
    }

    pub fn without(&self, position: i64) -> OrglRoot {
        match &self.inner {
            OrglInner::Empty => OrglRoot::empty(),
            OrglInner::Actual { loaf, .. } => {
                let new_loaf = loaf.without(position);
                if new_loaf.is_empty() {
                    OrglRoot::empty()
                } else {
                    OrglRoot::from_loaf(new_loaf)
                }
            }
        }
    }

    pub fn copy(&self, region: &XnRegion) -> OrglRoot {
        match &self.inner {
            OrglInner::Empty => OrglRoot::empty(),
            OrglInner::Actual { loaf, .. } => {
                let new_loaf = loaf.copy(region);
                if new_loaf.is_empty() {
                    OrglRoot::empty()
                } else {
                    OrglRoot::from_loaf(new_loaf)
                }
            }
        }
    }

    pub fn combine(&self, other: &OrglRoot) -> Result<OrglRoot, String> {
        if self.is_empty() {
            return Ok(other.clone());
        }
        if other.is_empty() {
            return Ok(self.clone());
        }
        let my_dom = self.domain();
        let other_dom = other.domain();
        if my_dom.intersect(&other_dom).is_empty() {
            let (in_root, out_root) = if self.domain().start() <= other.domain().start() {
                (self, other)
            } else {
                (other, self)
            };
            let split = in_root.domain();
            let loaf = Loaf::Split {
                split,
                in_child: Box::new(in_root.loaf().clone()),
                out_child: Box::new(out_root.loaf().clone()),
            };
            return Ok(OrglRoot::from_loaf(loaf));
        }
        Err("combine: overlapping domains not yet supported".into())
    }

    /// Combine two OrglRoots, resolving overlapping positions with LWW
    /// (other wins at overlapping positions). Unlike `combine`, this
    /// method never fails — it handles both disjoint and overlapping domains.
    pub fn combine_overlapping(&self, other: &OrglRoot) -> OrglRoot {
        if self.is_empty() {
            return other.clone();
        }
        if other.is_empty() {
            return self.clone();
        }
        let overlap = self.domain().intersect(&other.domain());
        if overlap.is_empty() {
            return self.combine(other).unwrap_or_else(|_| {
                let split = self.domain();
                let loaf = Loaf::Split {
                    split,
                    in_child: Box::new(self.loaf().clone()),
                    out_child: Box::new(other.loaf().clone()),
                };
                OrglRoot::from_loaf(loaf)
            });
        }
        self.replace(other)
    }

    pub fn replace(&self, other: &OrglRoot) -> OrglRoot {
        if other.is_empty() {
            return self.clone();
        }
        let keep_region = self.domain().minus(&other.domain());
        let kept = self.copy(&keep_region);
        if kept.is_empty() {
            return other.clone();
        }
        if other.domain().intersect(&kept.domain()).is_empty() {
            kept.combine(other).unwrap_or_else(|_| {
                let loaf = Loaf::Split {
                    split: kept.domain(),
                    in_child: Box::new(kept.loaf().clone()),
                    out_child: Box::new(other.loaf().clone()),
                };
                OrglRoot::from_loaf(loaf)
            })
        } else {
            let my_entries = kept.loaf().all_entries();
            let other_entries = other.loaf().all_entries();
            let mut all: Vec<(i64, Arc<Carrier>)> = my_entries;
            for (pos, carrier) in other_entries {
                if let Ok(idx) = all.binary_search_by_key(&pos, |(p, _)| *p) {
                    all[idx].1 = carrier;
                } else {
                    all.push((pos, carrier));
                }
            }
            all.sort_by_key(|(p, _)| *p);
            let region = all.iter().fold(XnRegion::empty(), |r, (p, _)| r.with(*p));
            let loaf = Loaf::new_leaf(region, all);
            OrglRoot::from_loaf(loaf)
        }
    }

    pub fn shared_region(&self, other: &OrglRoot) -> XnRegion {
        match (&self.inner, &other.inner) {
            (OrglInner::Empty, _) | (_, OrglInner::Empty) => XnRegion::empty(),
            (OrglInner::Actual { loaf: a, .. }, OrglInner::Actual { loaf: b, .. }) => {
                a.shared_region(b)
            }
        }
    }

    pub fn positions_of(&self, value: &Carrier) -> XnRegion {
        match &self.inner {
            OrglInner::Empty => XnRegion::empty(),
            OrglInner::Actual { loaf, .. } => loaf.positions_of(value),
        }
    }

    pub fn all_entries(&self) -> Vec<(i64, Arc<Carrier>)> {
        match &self.inner {
            OrglInner::Empty => Vec::new(),
            OrglInner::Actual { loaf, .. } => loaf.all_entries(),
        }
    }

    pub fn crum(&self) -> Option<Crum> {
        match &self.inner {
            OrglInner::Empty => None,
            OrglInner::Actual {
                cached_crum: Some(c),
                ..
            } => Some(*c),
            OrglInner::Actual {
                loaf,
                cached_crum: None,
                ..
            } => {
                let c = loaf.compute_crum();
                Some(c)
            }
        }
    }

    pub fn transformed_by(&self, offset: i64) -> OrglRoot {
        match &self.inner {
            OrglInner::Empty => OrglRoot::empty(),
            OrglInner::Actual { loaf, .. } => {
                let new_loaf = loaf.transformed_by(offset);
                OrglRoot::from_loaf(new_loaf)
            }
        }
    }

    pub(crate) fn splay(&mut self, region: &XnRegion) -> SplayResult {
        match &mut self.inner {
            OrglInner::Empty => SplayResult::Outside,
            OrglInner::Actual {
                loaf,
                cached_crum,
                simple_domain,
                ..
            } => {
                let result = loaf.splay(region);
                // Splay restructured the loaf: cached crum and domain are stale.
                *cached_crum = None;
                *simple_domain = loaf.domain();
                result
            }
        }
    }

    pub(crate) fn loaf(&self) -> &Loaf {
        match &self.inner {
            OrglInner::Empty => {
                static EMPTY: std::sync::OnceLock<Loaf> = std::sync::OnceLock::new();
                EMPTY.get_or_init(Loaf::empty_leaf)
            }
            OrglInner::Actual { loaf, .. } => loaf,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::range_element::RangeElement;
    use crate::edition::Edition;
    use proptest::prelude::*;

    fn make_text_loaf(text: &str) -> Loaf {
        let entries: Vec<(i64, Arc<Carrier>)> = text
            .chars()
            .enumerate()
            .map(|(i, ch)| {
                (
                    i as i64,
                    Arc::new(Carrier::new(RangeElement::text(ch.to_string()))),
                )
            })
            .collect();
        let region = if entries.is_empty() {
            XnRegion::empty()
        } else {
            XnRegion::interval(0, entries.len() as i64)
        };
        Loaf::Leaf {
            region,
            entries,
            default: None,
        }
    }

    #[test]
    fn loaf_leaf_fetch() {
        let loaf = make_text_loaf("abc");
        assert_eq!(loaf.fetch(0).unwrap().element.as_text(), Some("a"));
        assert_eq!(loaf.fetch(1).unwrap().element.as_text(), Some("b"));
        assert!(loaf.fetch(3).is_none());
    }

    #[test]
    fn loaf_leaf_domain() {
        let loaf = make_text_loaf("abc");
        assert_eq!(loaf.domain(), XnRegion::interval(0, 3));
    }

    #[test]
    fn loaf_leaf_count() {
        let loaf = make_text_loaf("abc");
        assert_eq!(loaf.count(), 3);
    }

    #[test]
    fn loaf_leaf_with_adds() {
        let loaf = make_text_loaf("abc");
        let new_loaf = loaf.with(5, Arc::new(Carrier::new(RangeElement::text("x"))));
        assert!(new_loaf.has_position(5));
        assert!(new_loaf.has_position(0));
    }

    #[test]
    fn loaf_leaf_without_removes() {
        let loaf = make_text_loaf("abc");
        let new_loaf = loaf.without(1);
        assert!(!new_loaf.has_position(1));
        assert!(new_loaf.has_position(0));
        assert!(new_loaf.has_position(2));
    }

    #[test]
    fn loaf_leaf_copy_subset() {
        let loaf = make_text_loaf("abcde");
        let copied = loaf.copy(&XnRegion::interval(1, 4));
        assert_eq!(copied.count(), 3);
        assert!(!copied.has_position(0));
        assert!(copied.has_position(1));
        assert!(copied.has_position(3));
        assert!(!copied.has_position(4));
    }

    #[test]
    fn loaf_splay_leaf_splits() {
        let mut loaf = make_text_loaf("abcde");
        let result = loaf.splay(&XnRegion::interval(0, 3));
        assert_eq!(result, SplayResult::Partial);
        assert!(matches!(loaf, Loaf::Split { .. }));
    }

    #[test]
    fn loaf_splay_leaf_fully_contained() {
        let mut loaf = make_text_loaf("abc");
        let result = loaf.splay(&XnRegion::interval(0, 10));
        assert_eq!(result, SplayResult::FullyContained);
    }

    #[test]
    fn loaf_splay_leaf_outside() {
        let mut loaf = make_text_loaf("abc");
        let result = loaf.splay(&XnRegion::interval(10, 20));
        assert_eq!(result, SplayResult::Outside);
    }

    #[test]
    fn loaf_splay_split_rotates() {
        let mut loaf = Loaf::Split {
            split: XnRegion::below(3),
            in_child: Box::new(make_text_loaf("ab")),
            out_child: Box::new(make_text_loaf("cde")),
        };
        let result = loaf.splay(&XnRegion::interval(1, 4));
        assert_eq!(result, SplayResult::Partial);
    }

    #[test]
    fn orgl_empty() {
        let orgl = OrglRoot::empty();
        assert!(orgl.is_empty());
        assert_eq!(orgl.count(), 0);
        assert!(orgl.domain().is_empty());
        assert!(orgl.fetch(0).is_none());
    }

    #[test]
    fn orgl_from_loaf() {
        let loaf = make_text_loaf("hello");
        let orgl = OrglRoot::from_loaf(loaf);
        assert_eq!(orgl.count(), 5);
        assert_eq!(orgl.domain(), XnRegion::interval(0, 5));
        assert_eq!(orgl.fetch(0).unwrap().element.as_text(), Some("h"));
    }

    #[test]
    fn orgl_with_adds() {
        let orgl = OrglRoot::empty();
        let orgl = orgl.with(0, Arc::new(Carrier::new(RangeElement::text("a"))));
        assert_eq!(orgl.count(), 1);
        assert!(orgl.has_position(0));
    }

    #[test]
    fn orgl_without_removes() {
        let loaf = make_text_loaf("abc");
        let orgl = OrglRoot::from_loaf(loaf);
        let orgl = orgl.without(1);
        assert_eq!(orgl.count(), 2);
        assert!(!orgl.has_position(1));
    }

    #[test]
    fn orgl_copy_subset() {
        let loaf = make_text_loaf("abcde");
        let orgl = OrglRoot::from_loaf(loaf);
        let copied = orgl.copy(&XnRegion::interval(1, 4));
        assert_eq!(copied.count(), 3);
    }

    #[test]
    fn orgl_combine_disjoint() {
        let loaf_a = make_text_loaf("ab");
        let loaf_b = make_text_loaf("cd");
        let orgl_b = OrglRoot::from_loaf(loaf_b).transformed_by(2);
        let orgl_a = OrglRoot::from_loaf(loaf_a);
        let combined = orgl_a.combine(&orgl_b).unwrap();
        assert_eq!(combined.count(), 4);
        assert!(combined.has_position(0));
        assert!(combined.has_position(2));
    }

    #[test]
    fn orgl_replace() {
        let loaf = make_text_loaf("abc");
        let orgl = OrglRoot::from_loaf(loaf);
        let replacement = OrglRoot::from_loaf(Loaf::new_leaf(
            XnRegion::singleton(1),
            vec![(1, Arc::new(Carrier::new(RangeElement::text("X"))))],
        ));
        let replaced = orgl.replace(&replacement);
        assert_eq!(replaced.fetch(1).unwrap().element.as_text(), Some("X"));
        assert_eq!(replaced.fetch(0).unwrap().element.as_text(), Some("a"));
    }

    #[test]
    fn orgl_shared_region() {
        let loaf_a = make_text_loaf("abc");
        let loaf_b = make_text_loaf("xbc");
        let orgl_a = OrglRoot::from_loaf(loaf_a);
        let orgl_b = OrglRoot::from_loaf(loaf_b);
        let shared = orgl_a.shared_region(&orgl_b);
        assert!(shared.contains(1));
        assert!(shared.contains(2));
        assert!(!shared.contains(0));
    }

    #[test]
    fn orgl_transformed_by() {
        let loaf = make_text_loaf("abc");
        let orgl = OrglRoot::from_loaf(loaf);
        let shifted = orgl.transformed_by(10);
        assert_eq!(shifted.count(), 3);
        assert!(shifted.has_position(10));
        assert!(!shifted.has_position(0));
    }

    #[test]
    fn loaf_split_on_overflow() {
        let entries: Vec<(i64, Arc<Carrier>)> = (0..MAX_LEAF_SIZE + 1)
            .map(|i| {
                (
                    i as i64,
                    Arc::new(Carrier::new(RangeElement::text(format!("{i}")))),
                )
            })
            .collect();
        let region = XnRegion::interval(0, (MAX_LEAF_SIZE + 1) as i64);
        let loaf = Loaf::Leaf {
            region,
            entries: entries.clone(),
            default: None,
        };
        let with_overflow = loaf.with(
            MAX_LEAF_SIZE as i64 + 10,
            Arc::new(Carrier::new(RangeElement::text("extra"))),
        );
        assert!(matches!(with_overflow, Loaf::Split { .. }));
    }

    #[test]
    fn orgl_positions_of() {
        let loaf = Loaf::Leaf {
            region: XnRegion::interval(0, 3),
            entries: vec![
                (0, Arc::new(Carrier::new(RangeElement::text("x")))),
                (1, Arc::new(Carrier::new(RangeElement::text("y")))),
                (2, Arc::new(Carrier::new(RangeElement::text("x")))),
            ],
            default: None,
        };
        let orgl = OrglRoot::from_loaf(loaf);
        let pos = orgl.positions_of(&Carrier::new(RangeElement::text("x")));
        assert!(pos.contains(0));
        assert!(!pos.contains(1));
        assert!(pos.contains(2));
    }

    #[test]
    fn loaf_large_tree() {
        let n = 5000;
        let entries: Vec<(i64, Arc<Carrier>)> = (0..n)
            .map(|i| {
                (
                    i as i64,
                    Arc::new(Carrier::new(RangeElement::text(format!("{i}")))),
                )
            })
            .collect();
        let region = XnRegion::interval(0, n as i64);
        let mut loaf = Loaf::Leaf {
            region,
            entries,
            default: None,
        };
        assert_eq!(loaf.count(), n as u64);
        assert_eq!(loaf.fetch(2500).unwrap().element.as_text(), Some("2500"));
        let result = loaf.splay(&XnRegion::interval(1000, 2000));
        assert_eq!(result, SplayResult::Partial);
        assert_eq!(loaf.count(), n as u64);
    }

    // === DspLoaf tests ===

    #[test]
    fn dsp_loaf_fetch() {
        let inner = make_text_loaf("abc");
        let dsp = Loaf::Dsp {
            offset: 10,
            child: Box::new(inner),
        };
        assert_eq!(dsp.fetch(10).unwrap().element.as_text(), Some("a"));
        assert_eq!(dsp.fetch(12).unwrap().element.as_text(), Some("c"));
        assert!(dsp.fetch(0).is_none());
    }

    #[test]
    fn dsp_loaf_domain() {
        let inner = make_text_loaf("abc");
        let dsp = Loaf::Dsp {
            offset: 5,
            child: Box::new(inner),
        };
        assert_eq!(dsp.domain(), XnRegion::interval(5, 8));
    }

    #[test]
    fn dsp_loaf_has_position() {
        let inner = make_text_loaf("abc");
        let dsp = Loaf::Dsp {
            offset: 100,
            child: Box::new(inner),
        };
        assert!(dsp.has_position(100));
        assert!(dsp.has_position(102));
        assert!(!dsp.has_position(0));
        assert!(!dsp.has_position(103));
    }

    #[test]
    fn dsp_loaf_with() {
        let inner = make_text_loaf("abc");
        let dsp = Loaf::Dsp {
            offset: 10,
            child: Box::new(inner),
        };
        let new_dsp = dsp.with(13, Arc::new(Carrier::new(RangeElement::text("X"))));
        assert_eq!(new_dsp.fetch(13).unwrap().element.as_text(), Some("X"));
        assert_eq!(new_dsp.fetch(10).unwrap().element.as_text(), Some("a"));
    }

    #[test]
    fn dsp_loaf_without() {
        let inner = make_text_loaf("abc");
        let dsp = Loaf::Dsp {
            offset: 10,
            child: Box::new(inner),
        };
        let new_dsp = dsp.without(11);
        assert!(!new_dsp.has_position(11));
        assert!(new_dsp.has_position(10));
    }

    #[test]
    fn dsp_loaf_all_entries() {
        let inner = make_text_loaf("abc");
        let dsp = Loaf::Dsp {
            offset: 5,
            child: Box::new(inner),
        };
        let entries = dsp.all_entries();
        assert_eq!(entries.len(), 3);
        assert_eq!(entries[0].0, 5);
        assert_eq!(entries[2].0, 7);
    }

    #[test]
    fn dsp_loaf_chained() {
        let inner = make_text_loaf("abc");
        let dsp1 = Loaf::Dsp {
            offset: 10,
            child: Box::new(inner),
        };
        let dsp2 = Loaf::Dsp {
            offset: 5,
            child: Box::new(dsp1),
        };
        assert_eq!(dsp2.domain(), XnRegion::interval(15, 18));
        assert_eq!(dsp2.fetch(15).unwrap().element.as_text(), Some("a"));
    }

    #[test]
    fn dsp_loaf_copy() {
        let inner = make_text_loaf("abcde");
        let dsp = Loaf::Dsp {
            offset: 10,
            child: Box::new(inner),
        };
        let copied = dsp.copy(&XnRegion::interval(11, 14));
        assert!(copied.has_position(11));
        assert!(copied.has_position(13));
        assert!(!copied.has_position(10));
    }

    #[test]
    fn transformed_by_returns_dsp() {
        let loaf = make_text_loaf("abc");
        let result = loaf.transformed_by(10);
        assert!(matches!(result, Loaf::Dsp { offset: 10, .. }));
    }

    #[test]
    fn transformed_by_zero_is_identity() {
        let loaf = make_text_loaf("abc");
        let result = loaf.transformed_by(0);
        assert!(matches!(result, Loaf::Leaf { .. }));
    }

    #[test]
    fn transform_materialized_rebuilds() {
        let loaf = make_text_loaf("abc");
        let materialized = loaf.transform_materialized(10);
        assert!(matches!(materialized, Loaf::Leaf { .. }));
        assert_eq!(materialized.fetch(10).unwrap().element.as_text(), Some("a"));
    }

    // === Infinite domain tests ===

    #[test]
    fn infinite_leaf_default_value() {
        let loaf = Loaf::new_leaf_with_default(
            XnRegion::above(0),
            Arc::new(Carrier::new(RangeElement::text("?"))),
        );
        assert!(loaf.is_infinite());
        assert_eq!(loaf.fetch(0).unwrap().element.as_text(), Some("?"));
        assert_eq!(loaf.fetch(100).unwrap().element.as_text(), Some("?"));
        assert_eq!(loaf.fetch(-1), None);
    }

    #[test]
    fn infinite_leaf_override_default() {
        let loaf = Loaf::new_leaf_with_default(
            XnRegion::above(0),
            Arc::new(Carrier::new(RangeElement::text("?"))),
        );
        let with_override = loaf.with(5, Arc::new(Carrier::new(RangeElement::text("X"))));
        assert_eq!(with_override.fetch(5).unwrap().element.as_text(), Some("X"));
        assert_eq!(
            with_override.fetch(100).unwrap().element.as_text(),
            Some("?")
        );
    }

    #[test]
    fn infinite_leaf_has_position() {
        let loaf = Loaf::new_leaf_with_default(
            XnRegion::interval(0, 100),
            Arc::new(Carrier::new(RangeElement::placeholder(0))),
        );
        assert!(loaf.has_position(0));
        assert!(loaf.has_position(50));
        assert!(loaf.has_position(99));
        assert!(!loaf.has_position(100));
    }

    #[test]
    fn infinite_orgl() {
        let orgl = OrglRoot::with_default(
            XnRegion::above(0),
            Arc::new(Carrier::new(RangeElement::text("."))),
        );
        assert!(orgl.is_infinite());
        assert!(orgl.has_position(0));
        assert!(orgl.has_position(1000000));
        assert_eq!(orgl.fetch(42).unwrap().element.as_text(), Some("."));
    }

    #[test]
    fn infinite_orgl_with_override() {
        let orgl = OrglRoot::with_default(
            XnRegion::above(0),
            Arc::new(Carrier::new(RangeElement::text("."))),
        );
        let orgl = orgl.with(3, Arc::new(Carrier::new(RangeElement::text("X"))));
        assert_eq!(orgl.fetch(3).unwrap().element.as_text(), Some("X"));
        assert_eq!(orgl.fetch(4).unwrap().element.as_text(), Some("."));
    }

    #[test]
    fn infinite_leaf_without_adds_tombstone() {
        let loaf = Loaf::new_leaf_with_default(
            XnRegion::above(0),
            Arc::new(Carrier::new(RangeElement::text("."))),
        );
        let without = loaf.without(5);
        assert!(!without.has_position(5));
        assert!(without.has_position(4));
        assert!(without.has_position(6));
    }

    #[test]
    fn infinite_leaf_splay() {
        let mut loaf = Loaf::new_leaf_with_default(
            XnRegion::above(0),
            Arc::new(Carrier::new(RangeElement::text("."))),
        );
        loaf = loaf.with(5, Arc::new(Carrier::new(RangeElement::text("X"))));
        let result = loaf.splay(&XnRegion::interval(0, 10));
        assert_eq!(result, SplayResult::Partial);
    }

    #[test]
    fn dsp_infinite_domain() {
        let inner = Loaf::new_leaf_with_default(
            XnRegion::above(0),
            Arc::new(Carrier::new(RangeElement::text("."))),
        );
        let dsp = Loaf::Dsp {
            offset: 100,
            child: Box::new(inner),
        };
        assert!(dsp.is_infinite());
        assert_eq!(dsp.fetch(150).unwrap().element.as_text(), Some("."));
    }

    #[test]
    fn finite_leaf_not_infinite() {
        let loaf = make_text_loaf("abc");
        assert!(!loaf.is_infinite());
    }

    #[test]
    fn crum_identical_editions_match() {
        let e1 = Edition::from_text("hello world");
        let e2 = Edition::from_text("hello world");
        assert_eq!(
            e1.crum(),
            e2.crum(),
            "identical content must have matching crums"
        );
    }

    #[test]
    fn crum_different_content_differs() {
        let e1 = Edition::from_text("hello world");
        let e2 = Edition::from_text("hello earth");
        assert_ne!(
            e1.crum(),
            e2.crum(),
            "different content must have different crums"
        );
    }

    #[test]
    fn crum_position_sensitive() {
        let mut e1 = Edition::from_text("ab");
        e1 = e1.with(2, RangeElement::text("c".to_string()));
        let mut e2 = Edition::from_text("ac");
        e2 = e2.with(2, RangeElement::text("b".to_string()));
        assert_ne!(
            e1.crum(),
            e2.crum(),
            "same characters at different positions must differ"
        );
    }

    #[test]
    fn crum_empty_edition_is_none() {
        let e = Edition::empty();
        assert!(e.crum().is_none(), "empty edition should have no crum");
    }

    #[test]
    fn crum_nonempty_edition_is_some() {
        let e = Edition::from_text("x");
        assert!(e.crum().is_some(), "non-empty edition should have a crum");
    }

    #[test]
    fn crum_bulk_vs_with_same_content() {
        let bulk = Edition::from_text("abc");
        let with = Edition::empty()
            .with(0, RangeElement::text("a".to_string()))
            .with(1, RangeElement::text("b".to_string()))
            .with(2, RangeElement::text("c".to_string()));
        assert_eq!(
            bulk.crum(),
            with.crum(),
            "same entries (same content at same positions) must have matching crums regardless of tree structure"
        );
    }

    #[test]
    fn crum_dsp_different_offset_differs() {
        let e1 = Edition::from_text("abc");
        let e2 = e1.transformed_by(5);
        assert_ne!(
            e1.orgl.crum(),
            e2.orgl.crum(),
            "Dsp with different offset must have different crum"
        );
    }

    #[test]
    fn crum_dsp_zero_offset_matches() {
        let e1 = Edition::from_text("abc");
        let e2 = e1.transformed_by(0);
        assert_eq!(
            e1.orgl.crum(),
            e2.orgl.crum(),
            "Dsp with zero offset should be identity (same crum)"
        );
    }

    #[test]
    fn crum_with_changes_crum() {
        let e1 = Edition::from_text("hello");
        let e2 = e1.with(0, RangeElement::text("X".to_string()));
        assert_ne!(e1.crum(), e2.crum(), "mutation must change crum");
    }

    #[test]
    fn crum_without_changes_crum() {
        let e1 = Edition::from_text("abc");
        let e2 = e1.without(1);
        assert_ne!(e1.crum(), e2.crum(), "deletion must change crum");
    }

    #[test]
    fn crum_large_edition_consistent() {
        let text: String = (0..500)
            .map(|i| char::from_u32(97 + i % 26).unwrap())
            .collect();
        let e1 = Edition::from_text(&text);
        let e2 = Edition::from_text(&text);
        assert_eq!(
            e1.crum(),
            e2.crum(),
            "large identical editions must have matching crums"
        );
    }

    #[test]
    fn crum_data_element_differs_from_text() {
        let e1 = Edition::from_one(0, RangeElement::text("hello".to_string()));
        let e2 = Edition::from_one(0, RangeElement::data(vec![1, 2, 3]));
        assert_ne!(
            e1.crum(),
            e2.crum(),
            "different element types must have different crums"
        );
    }

    #[test]
    fn crum_coalesced_differs_from_uncoalesced() {
        let per_char = Edition::from_text("abc");
        let coalesced = per_char.coalesce();
        assert_ne!(
            per_char.crum(),
            coalesced.crum(),
            "coalesce changes entry structure (3 entries -> 1), so crum should differ"
        );
    }

    #[test]
    fn crum_copy_preserves_subtree() {
        let e = Edition::from_text("abcdef");
        let region = XnRegion::interval(1, 4);
        let copied = e.copy(&region);
        let copied_crum = copied.crum();
        assert!(copied_crum.is_some(), "non-empty copy should have a crum");
        let entries = copied.all_entries();
        assert_eq!(entries.len(), 3, "copy should contain 3 entries");
    }

    #[test]
    fn crum_copy_empty_is_none() {
        let e = Edition::from_text("abc");
        let region = XnRegion::interval(10, 20);
        let copied = e.copy(&region);
        assert!(
            copied.crum().is_none(),
            "copy of non-overlapping region should be empty (no crum)"
        );
    }

    #[test]
    fn crum_identical_batched_match() {
        let e1 = Edition::from_text_batched("hello\nworld\nfoo");
        let e2 = Edition::from_text_batched("hello\nworld\nfoo");
        assert_eq!(
            e1.crum(),
            e2.crum(),
            "identical batched editions must have matching crums"
        );
    }

    #[test]
    fn crum_provenance_does_not_change_crum() {
        use crate::edition::provenance::{AuthorType, ElementProvenance};
        let plain = Edition::from_text("hello");
        let prov = ElementProvenance {
            author_public_key: [1; 32],
            author_display_name: "Alice".to_string(),
            author_club_id: 0,
            timestamp: 1000,
            author_type: AuthorType::Human,
            llm_model: None,
            historical_author_id: None,
            source_work_id: None,
            transcluded_by: None,
            derived_by: None,
        };
        let entries: Vec<(i64, Arc<Carrier>)> = plain
            .all_entries()
            .into_iter()
            .map(|(pos, carrier)| {
                let c = (*carrier).clone().with_provenance(prov.clone());
                (pos, Arc::new(c))
            })
            .collect();
        let with_prov = Edition::from_entries(entries);
        assert_eq!(
            plain.crum(),
            with_prov.crum(),
            "crum represents content identity; provenance is metadata and should not affect crum"
        );
    }

    #[test]
    fn crum_merge_preserves_unchanged() {
        use crate::edition::three_way::{three_way_merge, MergeStrategy};
        let base = Edition::from_text("hello world");
        let a = Edition::from_text("hello world");
        let b = Edition::from_text("hello world");
        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        assert_eq!(
            base.crum(),
            mr.merged.crum(),
            "merge of identical editions should preserve crum"
        );
    }

    #[test]
    fn crum_merge_different_from_base() {
        use crate::edition::three_way::{three_way_merge, MergeStrategy};
        let base = Edition::from_text("hello world");
        let a = Edition::from_text("hello earth");
        let b = Edition::from_text("hello world");
        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        assert_ne!(
            base.crum(),
            mr.merged.crum(),
            "merge with changes should produce different crum from base"
        );
    }

    #[test]
    fn crum_deterministic_across_construction_methods() {
        let from_bulk = Edition::from_text("xyz");
        let from_with = Edition::empty()
            .with(0, RangeElement::text("x".to_string()))
            .with(1, RangeElement::text("y".to_string()))
            .with(2, RangeElement::text("z".to_string()));
        assert_eq!(
            from_bulk.crum(),
            from_with.crum(),
            "same content at same positions must produce same crum regardless of construction method"
        );
    }

    #[test]
    fn crum_transclusion_differs_from_text() {
        let e1 = Edition::from_one(0, RangeElement::text("a".to_string()));
        let e2 = Edition::from_one(0, RangeElement::edition(42));
        assert_ne!(
            e1.crum(),
            e2.crum(),
            "text vs edition-ref at same position must have different crums"
        );
    }

    #[test]
    fn crum_different_edition_refs_differ() {
        let e1 = Edition::from_one(0, RangeElement::edition(42));
        let e2 = Edition::from_one(0, RangeElement::edition(99));
        assert_ne!(
            e1.crum(),
            e2.crum(),
            "different edition IDs must produce different crums"
        );
    }

    proptest! {
        #[test]
        fn prop_crum_deterministic(text in "[a-z]{0,100}") {
            let e1 = Edition::from_text(&text);
            let e2 = Edition::from_text(&text);
            prop_assert_eq!(e1.crum(), e2.crum(), "identical text must always produce identical crum");
        }

        #[test]
        fn prop_crum_different_text_differs(
            a in "[a-z]{1,50}",
            b in "[a-z]{1,50}",
        ) {
            prop_assume!(a != b);
            let e1 = Edition::from_text(&a);
            let e2 = Edition::from_text(&b);
            prop_assert_ne!(e1.crum(), e2.crum(), "different text must produce different crums");
        }

        #[test]
        fn prop_crum_with_then_without_identity(
            text in "[a-z]{1,50}",
            pos in 0usize..50,
        ) {
            prop_assume!(pos < text.len());
            let original = Edition::from_text(&text);
            let ch = text.chars().nth(pos).unwrap();
            let modified = original.without(pos as i64);
            let restored = modified.with(pos as i64, RangeElement::text(ch.to_string()));
            prop_assert_ne!(
                original.crum(),
                modified.crum(),
                "deletion must change crum"
            );
            prop_assert_eq!(
                original.crum(),
                restored.crum(),
                "delete + re-add same content should restore crum"
            );
        }

        #[test]
        fn prop_crum_batched_vs_perchar(
            text in "[a-z]{1,80}",
        ) {
            let per_char = Edition::from_text(&text);
            let coalesced = per_char.coalesce();
            let batched = Edition::from_text_batched(&text);
            prop_assert_eq!(
                batched.crum(),
                coalesced.crum(),
                "batched single-line edition should have same crum as coalesced per-char edition"
            );
        }
    }

    #[test]
    fn combine_overlapping_disjoint() {
        let a = OrglRoot::from_bulk_entries(
            vec![(
                0,
                Arc::new(Carrier::new(RangeElement::text("a".to_string()))),
            )],
            None,
            XnRegion::interval(0, 1),
        );
        let b = OrglRoot::from_bulk_entries(
            vec![(
                1,
                Arc::new(Carrier::new(RangeElement::text("b".to_string()))),
            )],
            None,
            XnRegion::interval(1, 2),
        );
        let combined = a.combine_overlapping(&b);
        assert_eq!(combined.count(), 2);
        assert_eq!(combined.fetch(0).unwrap().element.as_text(), Some("a"));
        assert_eq!(combined.fetch(1).unwrap().element.as_text(), Some("b"));
    }

    #[test]
    fn combine_overlapping_lww() {
        let a = OrglRoot::from_bulk_entries(
            vec![
                (
                    0,
                    Arc::new(Carrier::new(RangeElement::text("a".to_string()))),
                ),
                (
                    1,
                    Arc::new(Carrier::new(RangeElement::text("b".to_string()))),
                ),
            ],
            None,
            XnRegion::interval(0, 2),
        );
        let b = OrglRoot::from_bulk_entries(
            vec![
                (
                    1,
                    Arc::new(Carrier::new(RangeElement::text("X".to_string()))),
                ),
                (
                    2,
                    Arc::new(Carrier::new(RangeElement::text("c".to_string()))),
                ),
            ],
            None,
            XnRegion::interval(1, 3),
        );
        let combined = a.combine_overlapping(&b);
        assert_eq!(combined.fetch(0).unwrap().element.as_text(), Some("a"));
        assert_eq!(combined.fetch(1).unwrap().element.as_text(), Some("X"));
        assert_eq!(combined.fetch(2).unwrap().element.as_text(), Some("c"));
    }

    #[test]
    fn combine_overlapping_empty() {
        let a = OrglRoot::from_bulk_entries(
            vec![(
                0,
                Arc::new(Carrier::new(RangeElement::text("a".to_string()))),
            )],
            None,
            XnRegion::interval(0, 1),
        );
        let empty = OrglRoot::empty();
        assert_eq!(a.combine_overlapping(&empty).count(), 1);
        assert_eq!(empty.combine_overlapping(&a).count(), 1);
    }

    proptest! {
        #[test]
        fn prop_combine_overlapping_preserves_content(
            a_text in "[a-z]{1,20}",
            b_text in "[a-z]{1,20}",
        ) {
            let a_entries: Vec<(i64, Arc<Carrier>)> = a_text.chars().enumerate()
                .map(|(i, c)| (i as i64, Arc::new(Carrier::new(RangeElement::text(c.to_string())))))
                .collect();
            let b_entries: Vec<(i64, Arc<Carrier>)> = b_text.chars().enumerate()
                .map(|(i, c)| (i as i64, Arc::new(Carrier::new(RangeElement::text(c.to_string())))))
                .collect();
            let a = OrglRoot::from_bulk_entries(a_entries, None,
                XnRegion::interval(0, a_text.len() as i64));
            let b = OrglRoot::from_bulk_entries(b_entries, None,
                XnRegion::interval(0, b_text.len() as i64));

            let combined = a.combine_overlapping(&b);
            let n = a_text.len().max(b_text.len());
            for i in 0..n {
                let fetched = combined.fetch(i as i64);
                if i < b_text.len() {
                    let expected: String = b_text.chars().nth(i).unwrap().into();
                    let actual: String = fetched.unwrap().element.as_text().unwrap_or("").to_string();
                    prop_assert_eq!(actual, expected, "position {} should have b's value (LWW)", i);
                } else if i < a_text.len() {
                    let expected: String = a_text.chars().nth(i).unwrap().into();
                    let actual: String = fetched.unwrap().element.as_text().unwrap_or("").to_string();
                    prop_assert_eq!(actual, expected, "position {} should have a's value (only in a)", i);
                }
            }
        }

        #[test]
        fn prop_splayed_preserves_all_entries(
            text in "[a-z\n]{1,50}",
            s in 0usize..50,
            e in 0usize..50,
        ) {
            let ed = Edition::from_text_batched(&text);
            let (start, end) = if s <= e { (s, e) } else { (e, s) };
            let region = XnRegion::interval(start as i64, end as i64);
            let (splayed, _) = ed.splayed(&region);
            let orig = ed.all_entries();
            let spl = splayed.all_entries();
            prop_assert_eq!(orig.len(), spl.len(), "entry count must match");
            for (a, b) in orig.iter().zip(spl.iter()) {
                prop_assert_eq!(a.0, b.0, "position must match");
                prop_assert_eq!(a.1.element.as_text(), b.1.element.as_text(), "content must match");
            }
        }

        #[test]
        fn prop_chunk_crums_deterministic(
            text in "[a-z]{10,50}",
            chunk_size in 2usize..10,
        ) {
            let e1 = Edition::from_text(&text);
            let e2 = Edition::from_text(&text);
            let c1 = e1.chunk_crums(chunk_size);
            let c2 = e2.chunk_crums(chunk_size);
            prop_assert_eq!(c1.len(), c2.len());
            for (a, b) in c1.iter().zip(c2.iter()) {
                prop_assert_eq!(a.2, b.2, "crums must be deterministic");
            }
        }

        #[test]
        fn prop_chunk_diff_identical_all_match(
            text in "[a-z]{10,50}",
        ) {
            let e1 = Edition::from_text(&text);
            let e2 = Edition::from_text(&text);
            let (matching, differing) = e1.chunk_diff(&e2, 3);
            prop_assert!(differing.is_empty(), "identical editions have no differing blocks");
            prop_assert!(!matching.is_empty());
        }

        #[test]
        fn prop_document_arrangement_roundtrip(
            work_id in 1u64..1000,
            position in 0i64..1000,
        ) {
            let arr = crate::edition::tumbler::DocumentArrangement::new("server.com", work_id);
            let tumbler = arr.to_tumbler(position);
            let back = arr.from_tumbler(&tumbler);
            prop_assert_eq!(back, Some(position), "roundtrip must recover position");
            prop_assert!(arr.owns_tumbler(&tumbler), "arrangement must own the tumbler");
        }
    }
}
