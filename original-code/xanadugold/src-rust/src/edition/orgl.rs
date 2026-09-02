use crate::edition::BeId;
use std::sync::Arc;

use super::range_element::{Carrier, RangeElement};
use super::xn_region::XnRegion;

/// Maximum entries per leaf. Kept small (Gold-style): leaf crum
/// recomputation is O(leaf size) per edit, so leaf granularity bounds
/// incremental-edit cost. 1024 entries ≈ 40KB hashed per leaf crum
/// rebuild — sub-millisecond even in debug builds (PERF-PLAN Stage 2).
const MAX_LEAF_SIZE: usize = 1024;

pub type Crum = [u8; 32];

pub fn compute_leaf_crum(
    entries: &[(i64, Arc<Carrier>)],
    region: &XnRegion,
    default: &Option<Arc<Carrier>>,
) -> Crum {
    let fingerprints: Vec<[u8; 32]> = entries
        .iter()
        .map(|(_, c)| c.element.content_fingerprint())
        .collect();
    compute_leaf_crum_parts(entries, region, default, &fingerprints)
}

/// Same hash order as `compute_leaf_crum`, but reusing cached per-entry
/// fingerprints. Results are byte-identical — incremental crum maintenance
/// must not change crum values (PERF-PLAN Stage 2).
fn compute_leaf_crum_parts(
    entries: &[(i64, Arc<Carrier>)],
    region: &XnRegion,
    default: &Option<Arc<Carrier>>,
    fingerprints: &[[u8; 32]],
) -> Crum {
    let mut hasher = blake3::Hasher::new();
    hasher.update(b"leaf:");
    for (start, end) in region.intervals() {
        hasher.update(&start.to_le_bytes());
        hasher.update(&end.to_le_bytes());
    }
    for ((pos, _), fp) in entries.iter().zip(fingerprints.iter()) {
        hasher.update(&pos.to_le_bytes());
        hasher.update(fp);
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

/// FR-52 A-3: the per-node OWNER crum — the canopy's stable
/// aggregation (owner CLUBS from entry provenance; licenses
/// resolve at query time, preserving FR-38's re-license-without-
/// rebuild). Sorted distinct set; union is a merge.
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub(crate) struct OwnerSet {
    owners: Vec<BeId>,
    /// Entries with no provenance exist in this subtree (owner
    /// None in the flat overlay — resolves to UNKNOWN class).
    has_unowned: bool,
}

impl OwnerSet {
    pub(crate) fn from_entries(entries: &[(i64, Arc<Carrier>)]) -> Self {
        let mut owners = Vec::new();
        let mut has_unowned = false;
        for (_, c) in entries {
            if c.char_len() == 0 {
                continue; // mirror the overlay: zero-len entries skip
            }
            match c.provenance.as_ref() {
                Some(p) => owners.push(p.author_club_id),
                None => has_unowned = true,
            }
        }
        owners.sort_unstable();
        owners.dedup();
        OwnerSet {
            owners,
            has_unowned,
        }
    }

    pub(crate) fn union(a: &OwnerSet, b: &OwnerSet) -> OwnerSet {
        let mut owners = Vec::with_capacity(a.owners.len() + b.owners.len());
        let (mut i, mut j) = (0, 0);
        while i < a.owners.len() && j < b.owners.len() {
            match a.owners[i].cmp(&b.owners[j]) {
                std::cmp::Ordering::Less => {
                    owners.push(a.owners[i]);
                    i += 1;
                }
                std::cmp::Ordering::Greater => {
                    owners.push(b.owners[j]);
                    j += 1;
                }
                std::cmp::Ordering::Equal => {
                    owners.push(a.owners[i]);
                    i += 1;
                    j += 1;
                }
            }
        }
        owners.extend_from_slice(&a.owners[i..]);
        owners.extend_from_slice(&b.owners[j..]);
        OwnerSet {
            owners,
            has_unowned: a.has_unowned || b.has_unowned,
        }
    }

    pub(crate) fn owners(&self) -> &[BeId] {
        &self.owners
    }

    pub(crate) fn has_unowned(&self) -> bool {
        self.has_unowned
    }

    pub fn is_empty(&self) -> bool {
        self.owners.is_empty() && !self.has_unowned
    }
}

/// Enfilade tree node with per-node crum and domain caches (Gold's OCs
/// on every node). Tree operations (`with`/`without`/`copy`) recompute
/// caches only along the changed path — O(log n) per op instead of a
/// full-tree rehash from the root (PERF-PLAN Stage 2).
#[derive(Debug, Clone, PartialEq)]
pub(crate) enum Loaf {
    Leaf {
        region: XnRegion,
        entries: Vec<(i64, Arc<Carrier>)>,
        /// Per-entry content fingerprints, parallel to `entries`. Avoids
        /// re-blake3 of entry text on every leaf crum recomputation.
        fingerprints: Vec<[u8; 32]>,
        default: Option<Arc<Carrier>>,
        crum: Crum,
        /// FR-52 A-3: stable owner canopy aggregation (see OwnerSet).
        owner_set: OwnerSet,
    },
    Split {
        split: XnRegion,
        in_child: Arc<Loaf>,
        out_child: Arc<Loaf>,
        domain: XnRegion,
        crum: Crum,
        owner_set: OwnerSet,
    },
    Dsp {
        offset: i64,
        child: Arc<Loaf>,
        domain: XnRegion,
        crum: Crum,
        owner_set: OwnerSet,
    },
}

#[allow(dead_code)]
impl Loaf {
    /// Cached crum — O(1). Every construction path maintains this.
    /// FR-52 A-3: cached owner canopy aggregation — O(1).
    pub(crate) fn owner_set(&self) -> &OwnerSet {
        match self {
            Loaf::Leaf { owner_set, .. } => owner_set,
            Loaf::Split { owner_set, .. } => owner_set,
            Loaf::Dsp { owner_set, .. } => owner_set,
        }
    }

    pub fn compute_crum(&self) -> Crum {
        match self {
            Loaf::Leaf { crum, .. } => *crum,
            Loaf::Split { crum, .. } => *crum,
            Loaf::Dsp { crum, .. } => *crum,
        }
    }

    /// Cached domain — O(1).
    pub(crate) fn cached_domain(&self) -> &XnRegion {
        match self {
            Loaf::Leaf { region, .. } => region,
            Loaf::Split { domain, .. } => domain,
            Loaf::Dsp { domain, .. } => domain,
        }
    }

    pub(crate) fn new_leaf(region: XnRegion, entries: Vec<(i64, Arc<Carrier>)>) -> Self {
        let fingerprints = entry_fingerprints(&entries);
        let crum = compute_leaf_crum_parts(&entries, &region, &None, &fingerprints);
        let owner_set = OwnerSet::from_entries(&entries);
        Loaf::Leaf {
            region,
            entries,
            fingerprints,
            default: None,
            crum,
            owner_set,
        }
    }

    fn new_leaf_with_default(region: XnRegion, default: Arc<Carrier>) -> Self {
        let entries = Vec::new();
        let fingerprints = Vec::new();
        let crum =
            compute_leaf_crum_parts(&entries, &region, &Some(default.clone()), &fingerprints);
        let owner_set = OwnerSet::from_entries(&entries);
        Loaf::Leaf {
            region,
            entries,
            fingerprints,
            default: Some(default),
            crum,
            owner_set,
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
            let fingerprints = Vec::new();
            let crum = compute_leaf_crum_parts(&sorted_entries, &region, &default, &fingerprints);
            let owner_set = OwnerSet::from_entries(&sorted_entries);
            return Loaf::Leaf {
                region,
                entries: sorted_entries,
                fingerprints,
                default,
                crum,
                owner_set,
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
            let fingerprints = entry_fingerprints(&sorted_entries);
            let crum =
                compute_leaf_crum_parts(&sorted_entries, &leaf_region, &default, &fingerprints);
            let owner_set = OwnerSet::from_entries(&sorted_entries);
            return Loaf::Leaf {
                region: leaf_region,
                entries: sorted_entries,
                fingerprints,
                default,
                crum,
                owner_set,
            };
        }
        let mid = sorted_entries.len() / 2;
        let split_pos = sorted_entries[mid].0;
        let in_entries = sorted_entries[..mid].to_vec();
        let out_entries = sorted_entries[mid..].to_vec();
        let split = XnRegion::below(split_pos);
        let in_region = region.intersect(&split);
        let out_region = region.intersect(&XnRegion::above(split_pos));
        let in_child = Arc::new(Loaf::build_bulk(in_entries, default.clone(), in_region));
        let out_child = Arc::new(Loaf::build_bulk(out_entries, default.clone(), out_region));
        Loaf::split_from(split, in_child, out_child)
    }

    fn empty_leaf() -> Self {
        let region = XnRegion::empty();
        let crum = compute_leaf_crum_parts(&[], &region, &None, &[]);
        Loaf::Leaf {
            region,
            entries: Vec::new(),
            fingerprints: Vec::new(),
            default: None,
            crum,
            owner_set: OwnerSet::from_entries(&[]),
        }
    }

    /// Build a Split maintaining crum/domain caches from the children's
    /// caches — O(intervals), no subtree walks (PERF-PLAN Stage 2).
    pub(crate) fn split_from(split: XnRegion, in_child: Arc<Loaf>, out_child: Arc<Loaf>) -> Self {
        let domain = in_child.cached_domain().union(out_child.cached_domain());
        let crum = compute_split_crum(&split, &in_child.compute_crum(), &out_child.compute_crum());
        let owner_set = OwnerSet::union(in_child.owner_set(), out_child.owner_set());
        Loaf::Split {
            split,
            in_child,
            out_child,
            domain,
            crum,
            owner_set,
        }
    }

    /// Build a Dsp maintaining crum/domain caches — O(intervals).
    pub(crate) fn dsp_from(offset: i64, child: Arc<Loaf>) -> Self {
        let domain = shift_region(child.cached_domain(), offset);
        let crum = compute_dsp_crum(offset, &child.compute_crum());
        let owner_set = child.owner_set().clone();
        Loaf::Dsp {
            offset,
            child,
            domain,
            crum,
            owner_set,
        }
    }

    fn domain(&self) -> XnRegion {
        self.cached_domain().clone()
    }

    fn count(&self) -> u64 {
        match self {
            Loaf::Leaf {
                entries,
                region,
                default,
                ..
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
                ..
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
                ..
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
                ..
            } => {
                if split.contains(position) {
                    in_child.fetch(position)
                } else {
                    out_child.fetch(position)
                }
            }
            Loaf::Dsp { offset, child, .. } => {
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
                ..
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
                ..
            } => {
                if split.contains(position) {
                    in_child.has_position(position)
                } else {
                    out_child.has_position(position)
                }
            }
            Loaf::Dsp { offset, child, .. } => child.has_position(position - offset),
        }
    }

    fn with(&self, position: i64, carrier: Arc<Carrier>) -> Loaf {
        match self {
            Loaf::Leaf {
                region,
                entries,
                fingerprints,
                default,
                ..
            } => {
                let mut new_region = region.clone();
                if !new_region.contains(position) {
                    new_region = new_region.with(position);
                }
                let mut new_entries = entries.clone();
                let mut new_fingerprints = fingerprints.clone();
                let fp = carrier.element.content_fingerprint();
                match new_entries.binary_search_by_key(&position, |(p, _)| *p) {
                    Ok(idx) => {
                        new_entries[idx].1 = carrier;
                        new_fingerprints[idx] = fp;
                    }
                    Err(idx) => {
                        new_entries.insert(idx, (position, carrier));
                        new_fingerprints.insert(idx, fp);
                    }
                }
                if new_entries.len() <= MAX_LEAF_SIZE {
                    let crum = compute_leaf_crum_parts(
                        &new_entries,
                        &new_region,
                        default,
                        &new_fingerprints,
                    );
                    Loaf::Leaf {
                        region: new_region,
                        entries: new_entries,
                        fingerprints: new_fingerprints,
                        default: default.clone(),
                        crum,
                        owner_set: OwnerSet::from_entries(&entries),
                    }
                } else {
                    let owner_set = OwnerSet::from_entries(&new_entries);
                    let loaf = Loaf::Leaf {
                        region: new_region,
                        entries: new_entries,
                        fingerprints: new_fingerprints,
                        default: default.clone(),
                        crum: [0u8; 32],
                        owner_set,
                    };
                    loaf.maybe_split()
                }
            }
            Loaf::Split {
                split,
                in_child,
                out_child,
                ..
            } => {
                if split.contains(position) {
                    let new_in = in_child.with(position, carrier);
                    Loaf::split_from(split.clone(), Arc::new(new_in), out_child.clone())
                } else {
                    let new_out = out_child.with(position, carrier);
                    Loaf::split_from(split.clone(), in_child.clone(), Arc::new(new_out))
                }
            }
            Loaf::Dsp { offset, child, .. } => {
                let child_pos = position - offset;
                let new_child = child.with(child_pos, carrier);
                Loaf::dsp_from(*offset, Arc::new(new_child))
            }
        }
    }

    fn without(&self, position: i64) -> Loaf {
        match self {
            Loaf::Leaf {
                region,
                entries,
                fingerprints,
                default,
                ..
            } => {
                let mut new_entries = entries.clone();
                let mut new_fingerprints = fingerprints.clone();
                if let Ok(idx) = new_entries.binary_search_by_key(&position, |(p, _)| *p) {
                    new_entries.remove(idx);
                    new_fingerprints.remove(idx);
                }
                let new_region = region.without(position);
                if default.is_some() && new_region.contains(position) {
                    let default_val = default.clone().unwrap();
                    let fp = default_val.element.content_fingerprint();
                    match new_entries.binary_search_by_key(&position, |(p, _)| *p) {
                        Ok(idx) => {
                            new_entries[idx].1 = default_val;
                            new_fingerprints[idx] = fp;
                        }
                        Err(idx) => {
                            new_entries.insert(idx, (position, default_val));
                            new_fingerprints.insert(idx, fp);
                        }
                    }
                }
                let crum =
                    compute_leaf_crum_parts(&new_entries, &new_region, default, &new_fingerprints);
                Loaf::Leaf {
                    region: new_region,
                    entries: new_entries,
                    fingerprints: new_fingerprints,
                    default: default.clone(),
                    crum,
                    owner_set: OwnerSet::from_entries(&entries),
                }
            }
            Loaf::Split {
                split,
                in_child,
                out_child,
                ..
            } => {
                if split.contains(position) {
                    let new_in = in_child.without(position);
                    Loaf::split_from(split.clone(), Arc::new(new_in), out_child.clone())
                } else {
                    let new_out = out_child.without(position);
                    Loaf::split_from(split.clone(), in_child.clone(), Arc::new(new_out))
                }
            }
            Loaf::Dsp { offset, child, .. } => {
                let child_pos = position - offset;
                let new_child = child.without(child_pos);
                Loaf::dsp_from(*offset, Arc::new(new_child))
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
                fingerprints,
                default,
                ..
            } => {
                let new_region = leaf_region.intersect(region);
                let mut new_entries = Vec::new();
                let mut new_fingerprints = Vec::new();
                for ((pos, carrier), fp) in entries.iter().zip(fingerprints.iter()) {
                    if region.contains(*pos) {
                        new_entries.push((*pos, carrier.clone()));
                        new_fingerprints.push(*fp);
                    }
                }
                let crum =
                    compute_leaf_crum_parts(&new_entries, &new_region, default, &new_fingerprints);
                Loaf::Leaf {
                    region: new_region,
                    entries: new_entries,
                    fingerprints: new_fingerprints,
                    default: default.clone(),
                    crum,
                    owner_set: OwnerSet::from_entries(&entries),
                }
            }
            Loaf::Split {
                split,
                in_child,
                out_child,
                ..
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
                    Loaf::split_from(split.clone(), Arc::new(new_in), Arc::new(new_out))
                }
            }
            Loaf::Dsp { offset, child, .. } => {
                let child_region = shift_region_inverted(region, *offset);
                let new_child = child.copy(&child_region);
                if new_child.is_empty() {
                    Loaf::empty_leaf()
                } else {
                    Loaf::dsp_from(*offset, Arc::new(new_child))
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
                fingerprints,
                default,
                ..
            } => {
                let in_region = leaf_region.intersect(region);
                let out_region = leaf_region.minus(region);
                if out_region.is_empty() {
                    return SplayResult::FullyContained;
                }
                if in_region.is_empty() {
                    return SplayResult::Outside;
                }
                let mut in_entries = Vec::new();
                let mut in_fingerprints = Vec::new();
                let mut out_entries = Vec::new();
                let mut out_fingerprints = Vec::new();
                for ((pos, carrier), fp) in entries.iter().zip(fingerprints.iter()) {
                    if region.contains(*pos) {
                        in_entries.push((*pos, carrier.clone()));
                        in_fingerprints.push(*fp);
                    } else {
                        out_entries.push((*pos, carrier.clone()));
                        out_fingerprints.push(*fp);
                    }
                }
                let default = default.clone();
                let in_crum =
                    compute_leaf_crum_parts(&in_entries, &in_region, &default, &in_fingerprints);
                let out_crum =
                    compute_leaf_crum_parts(&out_entries, &out_region, &default, &out_fingerprints);
                let in_loaf = Loaf::Leaf {
                    region: in_region.clone(),
                    entries: in_entries,
                    fingerprints: in_fingerprints,
                    default: default.clone(),
                    crum: in_crum,
                    owner_set: OwnerSet::from_entries(&entries),
                };
                let out_loaf = Loaf::Leaf {
                    region: out_region,
                    entries: out_entries,
                    fingerprints: out_fingerprints,
                    default,
                    crum: out_crum,
                    owner_set: OwnerSet::from_entries(&entries),
                };
                let split = region.intersect(leaf_region);
                *self = Loaf::split_from(split, Arc::new(in_loaf), Arc::new(out_loaf));
                SplayResult::Partial
            }
            Loaf::Split {
                split,
                in_child,
                out_child,
                crum: node_crum,
                domain: node_domain,
                owner_set: _,
            } => {
                // Children are Arc-shared across editions (structural
                // sharing). Take them out; unwrap_or_clone clones only
                // when another edition still references the subtree, so
                // in-place restructuring never mutates a shared node.
                let mut in_owned =
                    Arc::unwrap_or_clone(std::mem::replace(in_child, Arc::new(Loaf::empty_leaf())));
                let mut out_owned = Arc::unwrap_or_clone(std::mem::replace(
                    out_child,
                    Arc::new(Loaf::empty_leaf()),
                ));

                let mut in_res = in_owned.splay(region);
                let mut out_res = out_owned.splay(&region.minus(split));

                if out_res as u8 > in_res as u8 {
                    std::mem::swap(&mut in_res, &mut out_res);
                    std::mem::swap(&mut in_owned, &mut out_owned);
                    *split = split.complement();
                }

                let result = match (in_res, out_res) {
                    (SplayResult::FullyContained, SplayResult::Outside) => {
                        // Terminal results: no restructuring — restore the
                        // taken-out children (dropping them here loses
                        // content; bug found by the S3 probe, Aug 2026).
                        *in_child = Arc::new(in_owned);
                        *out_child = Arc::new(out_owned);
                        SplayResult::FullyContained
                    }
                    (SplayResult::Outside, SplayResult::Outside) => {
                        *in_child = Arc::new(in_owned);
                        *out_child = Arc::new(out_owned);
                        SplayResult::Outside
                    }
                    (SplayResult::FullyContained, SplayResult::FullyContained) => {
                        *in_child = Arc::new(in_owned);
                        *out_child = Arc::new(out_owned);
                        SplayResult::FullyContained
                    }
                    _ => {
                        match (in_res, out_res) {
                            (SplayResult::Partial, SplayResult::Outside) => {
                                let new_in = in_owned.extract_in_part();
                                let new_out_inner = in_owned.extract_out_part();
                                let new_out =
                                    Loaf::make_split(split.clone(), new_out_inner, out_owned);
                                *in_child = Arc::new(new_in);
                                *out_child = Arc::new(new_out);
                            }
                            (SplayResult::FullyContained, SplayResult::Partial) => {
                                let new_in_inner = Loaf::make_split(
                                    split.clone(),
                                    in_owned,
                                    out_owned.extract_in_part(),
                                );
                                let new_out = out_owned.extract_out_part();
                                *in_child = Arc::new(new_in_inner);
                                *out_child = Arc::new(new_out);
                            }
                            (SplayResult::Partial, SplayResult::Partial) => {
                                let in_in = in_owned.extract_in_part();
                                let in_out = in_owned.extract_out_part();
                                let out_in = out_owned.extract_in_part();
                                let out_out = out_owned.extract_out_part();
                                let new_in = Loaf::make_split(split.clone(), in_in, out_in);
                                let new_out = Loaf::make_split(split.clone(), in_out, out_out);
                                *in_child = Arc::new(new_in);
                                *out_child = Arc::new(new_out);
                            }
                            _ => {
                                *in_child = Arc::new(in_owned);
                                *out_child = Arc::new(out_owned);
                            }
                        }
                        let in_dom = in_child.domain();
                        let out_dom = out_child.domain();
                        let new_split = region.intersect(&in_dom.union(&out_dom));
                        *split = new_split;
                        SplayResult::Partial
                    }
                };

                // Node caches must reflect the (possibly swapped or
                // restructured) children — the swap path and the
                // restructure arms previously left the pre-splay crum
                // in place, so crum() lied after splay (self-review
                // HIGH-2, Aug 2026: consumers like source-change
                // detection would see spurious diffs). Recompute from
                // the children's caches — O(1) — on EVERY exit path;
                // for terminal restores this is a harmless identity.
                *node_crum =
                    compute_split_crum(split, &in_child.compute_crum(), &out_child.compute_crum());
                *node_domain = in_child.domain().union(&out_child.domain());
                result
            }
            Loaf::Dsp { offset, child, .. } => {
                let child_region = shift_region_inverted(region, *offset);
                let mut child_owned =
                    Arc::unwrap_or_clone(std::mem::replace(child, Arc::new(Loaf::empty_leaf())));
                let result = child_owned.splay(&child_region);
                if result == SplayResult::Partial {
                    let offset = *offset;
                    let materialized = Loaf::split_from(
                        shift_region(&child_owned.cached_domain(), offset),
                        Arc::new(child_owned.extract_in_part().transformed_by(offset)),
                        Arc::new(child_owned.extract_out_part().transformed_by(offset)),
                    );
                    *self = materialized;
                } else {
                    // Non-Partial children are content-unchanged, but
                    // refresh the crum anyway — symmetry with the Split
                    // arm and free (one hash of 32-byte inputs).
                    if let Loaf::Dsp {
                        offset,
                        child,
                        crum,
                        ..
                    } = self
                    {
                        *crum = compute_dsp_crum(*offset, &child.compute_crum());
                    }
                }
                result
            }
        }
    }

    fn extract_in_part(&mut self) -> Loaf {
        match self {
            Loaf::Leaf { .. } => self.clone(),
            Loaf::Split { in_child, .. } => {
                Arc::unwrap_or_clone(std::mem::replace(in_child, Arc::new(Loaf::empty_leaf())))
            }
            Loaf::Dsp { .. } => self.clone(),
        }
    }

    fn extract_out_part(&mut self) -> Loaf {
        match self {
            Loaf::Leaf { .. } => Loaf::empty_leaf(),
            Loaf::Split { out_child, .. } => {
                Arc::unwrap_or_clone(std::mem::replace(out_child, Arc::new(Loaf::empty_leaf())))
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
        Loaf::split_from(split, Arc::new(in_child), Arc::new(out_child))
    }

    fn maybe_split(self) -> Loaf {
        match &self {
            Loaf::Leaf {
                entries,
                region,
                fingerprints,
                default,
                ..
            } => {
                if entries.len() <= MAX_LEAF_SIZE {
                    return self;
                }
                let mid = entries.len() / 2;
                let split_pos = entries[mid].0;
                let mut in_entries = entries[..mid].to_vec();
                let mut in_fingerprints = fingerprints[..mid].to_vec();
                let out_entries = entries[mid..].to_vec();
                let out_fingerprints = fingerprints[mid..].to_vec();
                let in_region = region.intersect(&XnRegion::below(split_pos));
                let out_region = region.intersect(&XnRegion::above(split_pos));
                let default = default.clone();
                let in_crum =
                    compute_leaf_crum_parts(&in_entries, &in_region, &default, &in_fingerprints);
                let out_crum =
                    compute_leaf_crum_parts(&out_entries, &out_region, &default, &out_fingerprints);
                in_entries.shrink_to_fit();
                in_fingerprints.shrink_to_fit();
                Loaf::split_from(
                    XnRegion::below(split_pos),
                    Arc::new(Loaf::Leaf {
                        region: in_region,
                        entries: in_entries,
                        fingerprints: in_fingerprints,
                        default: default.clone(),
                        crum: in_crum,
                        owner_set: OwnerSet::from_entries(&entries),
                    }),
                    Arc::new(Loaf::Leaf {
                        region: out_region,
                        entries: out_entries,
                        fingerprints: out_fingerprints,
                        default,
                        crum: out_crum,
                        owner_set: OwnerSet::from_entries(&entries),
                    }),
                )
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
            Loaf::Dsp { offset, child, .. } => child
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
        Loaf::dsp_from(offset, Arc::new(self.clone()))
    }

    fn transform_materialized(&self, offset: i64) -> Loaf {
        match self {
            Loaf::Leaf {
                region,
                entries,
                fingerprints,
                default,
                ..
            } => {
                let new_region = shift_region(region, offset);
                let new_entries: Vec<(i64, Arc<Carrier>)> = entries
                    .iter()
                    .map(|(p, c)| (p + offset, c.clone()))
                    .collect();
                let new_fingerprints = fingerprints.clone();
                let crum =
                    compute_leaf_crum_parts(&new_entries, &new_region, default, &new_fingerprints);
                Loaf::Leaf {
                    region: new_region,
                    entries: new_entries,
                    fingerprints: new_fingerprints,
                    default: default.clone(),
                    crum,
                    owner_set: OwnerSet::from_entries(&entries),
                }
            }
            Loaf::Split {
                split,
                in_child,
                out_child,
                ..
            } => {
                let new_split = shift_region(split, offset);
                Loaf::split_from(
                    new_split,
                    Arc::new(in_child.transform_materialized(offset)),
                    Arc::new(out_child.transform_materialized(offset)),
                )
            }
            Loaf::Dsp {
                offset: existing,
                child,
                ..
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
        Loaf::split_from(split, Arc::new(self_copy), Arc::new(other_copy))
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

fn entry_fingerprints(entries: &[(i64, Arc<Carrier>)]) -> Vec<[u8; 32]> {
    entries
        .iter()
        .map(|(_, c)| c.element.content_fingerprint())
        .collect()
}

/// Eager full-tree crum recomputation — reference implementation used by
/// tests to verify incremental per-node cache maintenance (Stage 2b).
/// Must stay byte-identical to the cached values.
#[cfg(test)]
fn compute_crum_eager(loaf: &Loaf) -> Crum {
    match loaf {
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
        } => compute_split_crum(
            split,
            &compute_crum_eager(in_child),
            &compute_crum_eager(out_child),
        ),
        Loaf::Dsp { offset, child, .. } => compute_dsp_crum(*offset, &compute_crum_eager(child)),
    }
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
        // O(1): crum and domain are maintained per-node by every
        // construction path (PERF-PLAN Stage 2).
        let domain = loaf.domain();
        OrglRoot {
            inner: OrglInner::Actual {
                loaf,
                simple_domain: domain,
                cached_crum: None,
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
            let loaf = Loaf::split_from(
                split,
                Arc::new(in_root.loaf().clone()),
                Arc::new(out_root.loaf().clone()),
            );
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
                let loaf = Loaf::split_from(
                    split,
                    Arc::new(self.loaf().clone()),
                    Arc::new(other.loaf().clone()),
                );
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
                let loaf = Loaf::split_from(
                    kept.domain(),
                    Arc::new(kept.loaf().clone()),
                    Arc::new(other.loaf().clone()),
                );
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

    /// FR-34 recorders: visit carriers whose content differs between
    /// two editions — parallel subtree descent pruning equal crums,
    /// so identical bulk costs O(1). `visit(carrier, true)` = only
    /// in self (removed); `(carrier, false)` = only in other
    /// (added). Dsp offsets don't affect content identity.
    pub fn crum_diff_visit(
        &self,
        other: &OrglRoot,
        visit: &mut dyn FnMut(&super::range_element::Carrier, bool),
    ) {
        match (&self.inner, &other.inner) {
            (OrglInner::Empty, OrglInner::Empty) => {}
            (OrglInner::Empty, OrglInner::Actual { loaf, .. }) => {
                visit_loaf_all(loaf, visit, false);
            }
            (OrglInner::Actual { loaf, .. }, OrglInner::Empty) => {
                visit_loaf_all(loaf, visit, true);
            }
            (OrglInner::Actual { loaf: a, .. }, OrglInner::Actual { loaf: b, .. }) => {
                visit_loaf_pair(a, b, visit)
            }
        }
    }

    pub fn crum(&self) -> Option<Crum> {
        match &self.inner {
            OrglInner::Empty => None,
            OrglInner::Actual { loaf, .. } => Some(loaf.compute_crum()),
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
            } => {
                let result = loaf.splay(region);
                // Node-level caches are maintained by actual_splay; refresh
                // the root-level views from them (O(1)).
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
        Loaf::new_leaf(region, entries)
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

    /// Regression (Aug 2026): splaying a small region fully inside one
    /// child of a Split hit the terminal (FullyContained, Outside) arm,
    /// which dropped the taken-out children — total content loss.
    /// Found by the S3 probe (repeated edit+splay loop emptied the doc).
    #[test]
    fn loaf_splay_region_inside_one_child_preserves_content() {
        // Build a proper split: out child shifted to positions 3..6.
        let mut loaf = Loaf::split_from(
            XnRegion::below(3),
            Arc::new(make_text_loaf("ab")),
            Arc::new(Loaf::dsp_from(3, Arc::new(make_text_loaf("cde")))),
        );
        let before = loaf.all_entries();
        assert_eq!(before.len(), 5);
        // Region fully inside the OUT child.
        let r = loaf.splay(&XnRegion::interval(3, 4));
        let after = loaf.all_entries();
        assert_eq!(after.len(), 5, "content must survive splay");
        assert_eq!(before, after, "content must survive splay");

        // Region fully inside the IN child.
        let mut loaf2 = Loaf::split_from(
            XnRegion::below(3),
            Arc::new(make_text_loaf("ab")),
            Arc::new(Loaf::dsp_from(3, Arc::new(make_text_loaf("cde")))),
        );
        let before2 = loaf2.all_entries();
        let r2 = loaf2.splay(&XnRegion::interval(1, 2));
        assert_eq!(r2, SplayResult::Partial);
        assert_eq!(before2, loaf2.all_entries());
    }

    /// Repeated small-region splays at moving positions must never lose
    /// content (the failure mode the S3 probe exposed).
    #[test]
    fn loaf_splay_repeated_moving_regions_preserve_content() {
        let entries: Vec<(i64, Arc<Carrier>)> = (0..200)
            .map(|i| {
                (
                    i,
                    Arc::new(Carrier::new(RangeElement::text(format!("{:03}", i)))),
                )
            })
            .collect();
        let mut loaf = Loaf::new_leaf(XnRegion::interval(0, 200), entries);
        let expected: String = (0..200).map(|i| format!("{:03}", i)).collect();
        for start in [0i64, 1, 5, 50, 51, 100, 150, 198] {
            let _ = loaf.splay(&XnRegion::interval(start, start + 2));
            let text: String = loaf
                .all_entries()
                .iter()
                .map(|(_, c)| c.element.as_text().unwrap_or("").to_string())
                .collect();
            assert_eq!(text, expected, "content lost after splay at {}", start);
        }
    }

    /// Self-review HIGH-2 (Aug 2026): splaying a MULTI-LEVEL tree
    /// previously left pre-splay crums on restructured/swap-modified
    /// interior nodes, so crum() lied after splay. The existing
    /// splayed_crum tests use single-leaf documents (MAX_LEAF_SIZE
    /// 1024) and could not catch it. This tree forces splits.
    #[test]
    fn splay_multi_level_crum_stays_consistent() {
        let n = 5000i64;
        let entries: Vec<(i64, Arc<Carrier>)> = (0..n)
            .map(|i| {
                (
                    i,
                    Arc::new(Carrier::new(RangeElement::text(format!("e{}.", i)))),
                )
            })
            .collect();
        let region = XnRegion::interval(0, n);
        let mut loaf = Loaf::build_bulk(entries, None, region);
        assert!(
            matches!(loaf, Loaf::Split { .. }),
            "precondition: multi-level tree"
        );

        // Splay several regions across the tree.
        for start in [0i64, 100, 1500, 3000, 4998] {
            let r = loaf.splay(&XnRegion::interval(start, start + 2));
            assert_ne!(r, SplayResult::Outside);
            assert_eq!(
                loaf.compute_crum(),
                compute_crum_eager(&loaf),
                "cached crum must equal eager recomputation after splay at {}",
                start
            );
            let eager = eager_domain(&loaf);
            assert_eq!(loaf.cached_domain().clone(), eager, "domain at {}", start);
            // Content survives every step.
            assert_eq!(loaf.count(), n as u64);
        }
    }

    #[test]
    fn loaf_splay_split_rotates() {
        let mut loaf = Loaf::split_from(
            XnRegion::below(3),
            Arc::new(make_text_loaf("ab")),
            Arc::new(make_text_loaf("cde")),
        );
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
        let loaf = Loaf::new_leaf(region, entries.clone());
        let with_overflow = loaf.with(
            MAX_LEAF_SIZE as i64 + 10,
            Arc::new(Carrier::new(RangeElement::text("extra"))),
        );
        assert!(matches!(with_overflow, Loaf::Split { .. }));
    }

    #[test]
    fn orgl_positions_of() {
        let loaf = Loaf::new_leaf(
            XnRegion::interval(0, 3),
            vec![
                (0, Arc::new(Carrier::new(RangeElement::text("x")))),
                (1, Arc::new(Carrier::new(RangeElement::text("y")))),
                (2, Arc::new(Carrier::new(RangeElement::text("x")))),
            ],
        );
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
        let mut loaf = Loaf::new_leaf(region, entries);
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
        let dsp = Loaf::dsp_from(10, Arc::new(inner));
        assert_eq!(dsp.fetch(10).unwrap().element.as_text(), Some("a"));
        assert_eq!(dsp.fetch(12).unwrap().element.as_text(), Some("c"));
        assert!(dsp.fetch(0).is_none());
    }

    #[test]
    fn dsp_loaf_domain() {
        let inner = make_text_loaf("abc");
        let dsp = Loaf::dsp_from(5, Arc::new(inner));
        assert_eq!(dsp.domain(), XnRegion::interval(5, 8));
    }

    #[test]
    fn dsp_loaf_has_position() {
        let inner = make_text_loaf("abc");
        let dsp = Loaf::dsp_from(100, Arc::new(inner));
        assert!(dsp.has_position(100));
        assert!(dsp.has_position(102));
        assert!(!dsp.has_position(0));
        assert!(!dsp.has_position(103));
    }

    #[test]
    fn dsp_loaf_with() {
        let inner = make_text_loaf("abc");
        let dsp = Loaf::dsp_from(10, Arc::new(inner));
        let new_dsp = dsp.with(13, Arc::new(Carrier::new(RangeElement::text("X"))));
        assert_eq!(new_dsp.fetch(13).unwrap().element.as_text(), Some("X"));
        assert_eq!(new_dsp.fetch(10).unwrap().element.as_text(), Some("a"));
    }

    #[test]
    fn dsp_loaf_without() {
        let inner = make_text_loaf("abc");
        let dsp = Loaf::dsp_from(10, Arc::new(inner));
        let new_dsp = dsp.without(11);
        assert!(!new_dsp.has_position(11));
        assert!(new_dsp.has_position(10));
    }

    #[test]
    fn dsp_loaf_all_entries() {
        let inner = make_text_loaf("abc");
        let dsp = Loaf::dsp_from(5, Arc::new(inner));
        let entries = dsp.all_entries();
        assert_eq!(entries.len(), 3);
        assert_eq!(entries[0].0, 5);
        assert_eq!(entries[2].0, 7);
    }

    #[test]
    fn dsp_loaf_chained() {
        let inner = make_text_loaf("abc");
        let dsp1 = Loaf::dsp_from(10, Arc::new(inner));
        let dsp2 = Loaf::dsp_from(5, Arc::new(dsp1));
        assert_eq!(dsp2.domain(), XnRegion::interval(15, 18));
        assert_eq!(dsp2.fetch(15).unwrap().element.as_text(), Some("a"));
    }

    #[test]
    fn dsp_loaf_copy() {
        let inner = make_text_loaf("abcde");
        let dsp = Loaf::dsp_from(10, Arc::new(inner));
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
        let dsp = Loaf::dsp_from(100, Arc::new(inner));
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

    /// Eager from-scratch domain build — reference for cache verification.
    #[cfg(test)]
    fn eager_domain(loaf: &Loaf) -> XnRegion {
        match loaf {
            Loaf::Leaf { region, .. } => region.clone(),
            Loaf::Split {
                in_child,
                out_child,
                ..
            } => eager_domain(in_child).union(&eager_domain(out_child)),
            Loaf::Dsp { offset, child, .. } => shift_region(&eager_domain(child), *offset),
        }
    }

    proptest! {
        /// Stage 2b: per-node cache maintenance must produce byte-identical
        /// crums and domains to eager full-tree recomputation, for arbitrary
        /// op sequences (with/without/copy/transformed_by).
        #[test]
        fn prop_incremental_crum_matches_eager(
            initial in "[a-z]{0,60}",
            ops in proptest::collection::vec(
                (0u32..120, 0u32..4),
                0..40
            ),
        ) {
            let entries: Vec<(i64, Arc<Carrier>)> = initial.chars().enumerate()
                .map(|(i, c)| (i as i64, Arc::new(Carrier::new(RangeElement::text(c.to_string())))))
                .collect();
            let region = if entries.is_empty() {
                XnRegion::empty()
            } else {
                XnRegion::interval(0, entries.len() as i64)
            };
            let mut loaf = Loaf::new_leaf(region, entries);

            for (pos, op_kind) in ops {
                let pos = pos as i64;
                loaf = match op_kind {
                    0 => loaf.with(pos, Arc::new(Carrier::new(RangeElement::text("X")))),
                    1 => loaf.without(pos),
                    2 => loaf.copy(&XnRegion::interval(pos.saturating_mul(-1), pos + 3)),
                    _ => loaf.transformed_by(pos),
                };
                prop_assert_eq!(loaf.compute_crum(), compute_crum_eager(&loaf));
                prop_assert_eq!(loaf.cached_domain().clone(), eager_domain(&loaf));
            }
        }

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

fn visit_loaf_all(
    loaf: &Loaf,
    visit: &mut dyn FnMut(&super::range_element::Carrier, bool),
    removed: bool,
) {
    match loaf {
        Loaf::Leaf { entries, .. } => {
            for (_, c) in entries {
                visit(c, removed);
            }
        }
        Loaf::Split {
            in_child,
            out_child,
            ..
        } => {
            visit_loaf_all(in_child, visit, removed);
            visit_loaf_all(out_child, visit, removed);
        }
        Loaf::Dsp { child, .. } => visit_loaf_all(child, visit, removed),
    }
}

fn visit_loaf_pair(
    a: &Loaf,
    b: &Loaf,
    visit: &mut dyn FnMut(&super::range_element::Carrier, bool),
) {
    if a.compute_crum() == b.compute_crum() {
        return;
    }
    match (a, b) {
        (Loaf::Leaf { entries: ea, .. }, Loaf::Leaf { entries: eb, .. }) => {
            // Common prefix/suffix trim by content fingerprint: the
            // visitor feeds content-keyed indexes, so matched pairs
            // cancel exactly. Single-leaf editions (from_text) get
            // proportional visits without subtree structure.
            let fa = |i: usize| ea[i].1.element.content_fingerprint();
            let fb = |i: usize| eb[i].1.element.content_fingerprint();
            let mut pre = 0usize;
            while pre < ea.len() && pre < eb.len() && fa(pre) == fb(pre) {
                pre += 1;
            }
            let mut suf = 0usize;
            while suf < ea.len().saturating_sub(pre)
                && suf < eb.len().saturating_sub(pre)
                && fa(ea.len() - 1 - suf) == fb(eb.len() - 1 - suf)
            {
                suf += 1;
            }
            for (_, c) in &ea[pre..ea.len() - suf] {
                visit(c, true);
            }
            for (_, c) in &eb[pre..eb.len() - suf] {
                visit(c, false);
            }
        }
        (Loaf::Split { .. }, Loaf::Leaf { entries, .. }) => {
            visit_loaf_all(a, visit, true);
            for (_, c) in entries {
                visit(c, false);
            }
        }
        (Loaf::Leaf { entries, .. }, Loaf::Split { .. }) => {
            for (_, c) in entries {
                visit(c, true);
            }
            visit_loaf_all(b, visit, false);
        }
        (
            Loaf::Split {
                in_child: ai,
                out_child: ao,
                ..
            },
            Loaf::Split {
                in_child: bi,
                out_child: bo,
                ..
            },
        ) => {
            visit_loaf_pair(ai, bi, visit);
            visit_loaf_pair(ao, bo, visit);
        }
        (Loaf::Dsp { child, .. }, _) => visit_loaf_pair(child, b, visit),
        (_, Loaf::Dsp { child, .. }) => visit_loaf_pair(a, child, visit),
    }
}

#[cfg(test)]
mod a3_owner_canopy_tests {
    use super::*;
    use crate::edition::range_element::Carrier;

    fn owned(text: &str, club: u64) -> (i64, Arc<Carrier>) {
        let c = Carrier::new(crate::edition::RangeElement::text(text)).with_provenance(
            crate::edition::provenance::ElementProvenance {
                author_public_key: [0u8; 32],
                author_display_name: "t".into(),
                author_club_id: club,
                timestamp: 0,
                author_type: crate::edition::provenance::AuthorType::Human,
                llm_model: None,
                historical_author_id: None,
                source_work_id: None,
                transcluded_by: None,
                derived_by: None,
            },
        );
        (0, Arc::new(c))
    }

    fn plain(text: &str) -> (i64, Arc<Carrier>) {
        (
            0,
            Arc::new(Carrier::new(crate::edition::RangeElement::text(text))),
        )
    }

    #[test]
    fn a3_leaf_owner_set_from_provenance() {
        let leaf = Loaf::new_leaf(
            XnRegion::interval(0, 10),
            vec![owned("aaa", 7), owned("bbb", 7), owned("ccc", 9)],
        );
        assert_eq!(leaf.owner_set().owners(), &[7, 9]);
        assert!(!leaf.owner_set().has_unowned());
    }

    #[test]
    fn a3_unowned_entries_flagged() {
        let leaf = Loaf::new_leaf(
            XnRegion::interval(0, 10),
            vec![owned("aaa", 7), plain("bbb")],
        );
        assert_eq!(leaf.owner_set().owners(), &[7]);
        assert!(leaf.owner_set().has_unowned());
    }

    #[test]
    fn a3_build_bulk_aggregates_all_owners() {
        // Force deep structure: many entries split across leaves.
        let mut entries = Vec::new();
        for i in 0..5000i64 {
            entries.push((i, owned("x", (i % 7) as u64 + 1).1.clone()));
            entries.last_mut().unwrap().0 = i;
        }
        let loaf = Loaf::build_bulk(entries, None, XnRegion::above(0));
        assert_eq!(loaf.owner_set().owners(), &[1, 2, 3, 4, 5, 6, 7]);
    }

    #[test]
    fn a3_split_and_dsp_union_children() {
        let in_child = Arc::new(Loaf::new_leaf(
            XnRegion::interval(0, 5),
            vec![owned("aaa", 1)],
        ));
        let out_child = Arc::new(Loaf::new_leaf(
            XnRegion::interval(5, 10),
            vec![owned("bbb", 2), owned("ccc", 1)],
        ));
        let split = Loaf::split_from(XnRegion::below(5), in_child, out_child);
        assert_eq!(split.owner_set().owners(), &[1, 2]);

        let dsp = Loaf::dsp_from(100, Arc::new(split));
        assert_eq!(dsp.owner_set().owners(), &[1, 2]);
    }

    #[test]
    fn a3_with_without_preserve_owners() {
        let mut entries = Vec::new();
        for i in 0..200i64 {
            let mut e = owned("x", (i % 3) as u64 + 1);
            e.0 = i;
            entries.push(e);
        }
        let root = OrglRoot::from_loaf(Loaf::build_bulk(entries, None, XnRegion::above(0)));
        let loaf = match &root.inner {
            crate::edition::orgl::OrglInner::Actual { loaf, .. } => loaf,
            _ => panic!("expected actual loaf"),
        };
        assert_eq!(loaf.owner_set().owners(), &[1, 2, 3]);
    }
}
