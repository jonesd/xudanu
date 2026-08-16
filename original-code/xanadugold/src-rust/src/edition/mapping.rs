use super::xn_region::XnRegion;

#[derive(Debug, Clone, PartialEq)]
pub enum Mapping {
    Empty,
    Simple { offset: i64, region: XnRegion },
    Composite(Vec<Mapping>),
}

impl Mapping {
    pub fn shift(offset: i64) -> Self {
        Mapping::Simple {
            offset,
            region: XnRegion::full(),
        }
    }

    pub fn identity() -> Self {
        Mapping::Simple {
            offset: 0,
            region: XnRegion::full(),
        }
    }

    pub fn empty() -> Self {
        Mapping::Empty
    }

    pub fn restricted(offset: i64, region: XnRegion) -> Self {
        if region.is_empty() {
            return Mapping::Empty;
        }
        Mapping::Simple { offset, region }
    }

    /// Build a canonical Mapping from parts in O(p log p): flatten all
    /// parts once, canonicalize once. Semantically identical to folding
    /// `combine` over the parts, but without the quadratic
    /// re-canonicalization per fold step (PERF-PLAN Stage 6).
    pub fn from_parts(parts: Vec<Mapping>) -> Mapping {
        let mut flat: Vec<(i64, XnRegion)> = Vec::with_capacity(parts.len());
        for p in &parts {
            flatten_into(p, &mut flat);
        }
        canonicalize(&mut flat)
    }

    pub fn of(&self, pos: i64) -> Option<i64> {
        match self {
            Mapping::Empty => None,
            Mapping::Simple { offset, region } => {
                if region.contains(pos) {
                    Some(pos + offset)
                } else {
                    None
                }
            }
            Mapping::Composite(mappings) => {
                for m in mappings {
                    if let Some(result) = m.of(pos) {
                        return Some(result);
                    }
                }
                None
            }
        }
    }

    /// Build a displacement Mapping from compound DeltaOps (usize-based).
    /// Parallel to from_delta_ops but for the edition::compound::DeltaOp type.
    pub fn from_compound_delta_ops(ops: &[crate::edition::compound::DeltaOp]) -> Mapping {
        let mut pos: i64 = 0;
        let mut displacement: i64 = 0;
        let mut parts: Vec<(i64, i64, i64)> = Vec::new();

        for op in ops {
            match op {
                crate::edition::compound::DeltaOp::Retain(count) => {
                    let end = pos + *count as i64;
                    if *count > 0 {
                        parts.push((pos, end, displacement));
                    }
                    pos = end;
                }
                crate::edition::compound::DeltaOp::Insert(len) => {
                    displacement += *len as i64;
                }
                crate::edition::compound::DeltaOp::Delete(count) => {
                    pos += *count as i64;
                    displacement -= *count as i64;
                }
            }
        }

        let mappings: Vec<Mapping> = parts
            .iter()
            .map(|(start, end, off)| Mapping::restricted(*off, XnRegion::interval(*start, *end)))
            .collect();

        if mappings.is_empty() {
            Mapping::identity()
        } else {
            Mapping::from_parts(mappings)
        }
    }

    pub fn of_region(&self, region: &XnRegion) -> XnRegion {
        match self {
            Mapping::Empty => XnRegion::empty(),
            Mapping::Simple {
                offset,
                region: domain,
            } => domain.intersect(region).shift(*offset),
            Mapping::Composite(mappings) => {
                let mut result = XnRegion::empty();
                for m in mappings {
                    result = result.union(&m.of_region(region));
                }
                result
            }
        }
    }

    pub fn inverse(&self) -> Mapping {
        match self {
            Mapping::Empty => Mapping::Empty,
            Mapping::Simple { offset, region } => Mapping::Simple {
                offset: -offset,
                region: region.shift(*offset),
            },
            Mapping::Composite(mappings) => {
                let inversed: Vec<Mapping> = mappings.iter().map(|m| m.inverse()).collect();
                Mapping::Composite(inversed)
            }
        }
    }

    /// Compute the "difference" between two mappings: result.apply(other.apply(x)) == self.apply(x).
    /// For constant shifts: self.offset - other.offset.
    /// Enables undoing a migration: original = migrated.minus(edit_dsp).
    pub fn minus(&self, other: &Mapping) -> Mapping {
        match (self, other) {
            (Mapping::Empty, _) | (_, Mapping::Empty) => Mapping::Empty,
            (
                Mapping::Simple {
                    offset: sa,
                    region: ra,
                },
                Mapping::Simple {
                    offset: sb,
                    region: rb,
                },
            ) if ra == rb => Mapping::Simple {
                offset: sa - sb,
                region: ra.clone(),
            },
            _ => {
                let other_inv = other.inverse();
                self.compose_with(&other_inv)
            }
        }
    }

    /// Compose two mappings: result.apply(x) == self.apply(other.apply(x)).
    pub fn compose_with(&self, other: &Mapping) -> Mapping {
        match (self, other) {
            (Mapping::Empty, _) | (_, Mapping::Empty) => Mapping::Empty,
            (Mapping::Simple { offset: 0, region }, _) if region.is_full() => other.clone(),
            (_, Mapping::Simple { offset: 0, region }) if region.is_full() => self.clone(),
            (
                Mapping::Simple {
                    offset: sa,
                    region: ra,
                },
                Mapping::Simple {
                    offset: sb,
                    region: rb,
                },
            ) => {
                // other maps rb → rb+sb, self maps ra → ra+sa
                // composed maps (rb ∩ ra-sb) → (rb ∩ ra-sb) + sa + sb
                let composed_region = rb.intersect(&ra.shift(-sb));
                if composed_region.is_empty() {
                    Mapping::Empty
                } else {
                    Mapping::Simple {
                        offset: sa + sb,
                        region: composed_region,
                    }
                }
            }
            (simple @ Mapping::Simple { .. }, Mapping::Composite(parts)) => {
                let composed: Vec<Mapping> = parts.iter().map(|p| simple.compose_with(p)).collect();
                let non_empty: Vec<Mapping> =
                    composed.into_iter().filter(|m| !m.is_empty()).collect();
                match non_empty.len() {
                    0 => Mapping::Empty,
                    1 => non_empty.into_iter().next().unwrap(),
                    _ => Mapping::Composite(non_empty),
                }
            }
            (Mapping::Composite(parts), _) => {
                let composed: Vec<Mapping> = parts.iter().map(|m| m.compose_with(other)).collect();
                let non_empty: Vec<Mapping> =
                    composed.into_iter().filter(|m| !m.is_empty()).collect();
                match non_empty.len() {
                    0 => Mapping::Empty,
                    1 => non_empty.into_iter().next().unwrap(),
                    _ => Mapping::Composite(non_empty),
                }
            }
        }
    }

    pub fn combine(&self, other: &Mapping) -> Mapping {
        if self.is_empty() {
            return other.clone();
        }
        if other.is_empty() {
            return self.clone();
        }
        // Flatten both into a list of simple parts
        let mut parts = Vec::new();
        flatten_into(self, &mut parts);
        flatten_into(other, &mut parts);
        canonicalize(&mut parts)
    }

    pub fn restrict(&self, region: &XnRegion) -> Mapping {
        match self {
            Mapping::Empty => Mapping::Empty,
            Mapping::Simple {
                offset,
                region: domain,
            } => {
                let restricted = domain.intersect(region);
                if restricted.is_empty() {
                    Mapping::Empty
                } else {
                    Mapping::Simple {
                        offset: *offset,
                        region: restricted,
                    }
                }
            }
            Mapping::Composite(mappings) => {
                let restricted: Vec<Mapping> = mappings
                    .iter()
                    .map(|m| m.restrict(region))
                    .filter(|m| !m.is_empty())
                    .collect();
                if restricted.is_empty() {
                    Mapping::Empty
                } else if restricted.len() == 1 {
                    restricted.into_iter().next().unwrap()
                } else {
                    Mapping::Composite(restricted)
                }
            }
        }
    }

    pub fn shift_range(&self, offset: i64) -> Mapping {
        match self {
            Mapping::Empty => Mapping::Empty,
            Mapping::Simple {
                offset: off,
                region,
            } => Mapping::Simple {
                offset: off + offset,
                region: region.clone(),
            },
            Mapping::Composite(mappings) => {
                Mapping::Composite(mappings.iter().map(|m| m.shift_range(offset)).collect())
            }
        }
    }

    pub fn domain(&self) -> XnRegion {
        match self {
            Mapping::Empty => XnRegion::empty(),
            Mapping::Simple { region, .. } => region.clone(),
            Mapping::Composite(mappings) => {
                let mut result = XnRegion::empty();
                for m in mappings {
                    result = result.union(&m.domain());
                }
                result
            }
        }
    }

    pub fn range(&self) -> XnRegion {
        match self {
            Mapping::Empty => XnRegion::empty(),
            Mapping::Simple { offset, region } => region.shift(*offset),
            Mapping::Composite(mappings) => {
                let mut result = XnRegion::empty();
                for m in mappings {
                    result = result.union(&m.range());
                }
                result
            }
        }
    }

    pub fn is_empty(&self) -> bool {
        matches!(self, Mapping::Empty)
    }

    pub fn is_identity(&self) -> bool {
        match self {
            Mapping::Simple { offset, region } => *offset == 0 && region.is_full(),
            _ => false,
        }
    }

    /// Transform this mapping by pre-applying a displacement.
    /// Result.of(pos) == self.of(dsp.of(pos))
    ///
    /// For span migration: if `dsp` represents the displacement caused by
    /// a text edit, then `mapping.transformed_by(dsp)` gives the new
    /// positions of whatever the mapping pointed to.
    pub fn transformed_by(&self, dsp: &Mapping) -> Mapping {
        match (self, dsp) {
            (Mapping::Empty, _) => Mapping::Empty,
            (_, Mapping::Empty) => Mapping::Empty,
            (_, Mapping::Simple { offset: 0, region }) if region.is_full() => self.clone(),
            (
                Mapping::Simple {
                    offset: m,
                    region: r_m,
                },
                Mapping::Simple {
                    offset: d,
                    region: r_d,
                },
            ) => {
                let new_region = r_d.intersect(&r_m.shift(-d));
                if new_region.is_empty() {
                    Mapping::Empty
                } else {
                    Mapping::Simple {
                        offset: m + d,
                        region: new_region,
                    }
                }
            }
            (simple @ Mapping::Simple { .. }, Mapping::Composite(parts)) => {
                let transformed: Vec<Mapping> =
                    parts.iter().map(|p| simple.transformed_by(p)).collect();
                let non_empty: Vec<Mapping> =
                    transformed.into_iter().filter(|m| !m.is_empty()).collect();
                match non_empty.len() {
                    0 => Mapping::Empty,
                    1 => non_empty.into_iter().next().unwrap(),
                    _ => Mapping::Composite(non_empty),
                }
            }
            (Mapping::Composite(parts), _) => {
                let transformed: Vec<Mapping> =
                    parts.iter().map(|m| m.transformed_by(dsp)).collect();
                let non_empty: Vec<Mapping> =
                    transformed.into_iter().filter(|m| !m.is_empty()).collect();
                match non_empty.len() {
                    0 => Mapping::Empty,
                    1 => non_empty.into_iter().next().unwrap(),
                    _ => Mapping::Composite(non_empty),
                }
            }
        }
    }

    /// Build a displacement Mapping from a sequence of text delta operations.
    ///
    /// Each Retain advances position with zero displacement.
    /// Each Insert adds displacement equal to text length.
    /// Each Delete subtracts displacement equal to count.
    ///
    /// The result is a piecewise-constant Mapping that maps positions
    /// in the OLD text to corresponding positions in the NEW text.
    pub fn from_delta_ops(ops: &[crate::server::transport::protocol::TextDeltaOp]) -> Mapping {
        let mut pos: i64 = 0;
        let mut displacement: i64 = 0;
        let mut parts: Vec<(i64, i64, i64)> = Vec::new();

        for op in ops {
            match op {
                crate::server::transport::protocol::TextDeltaOp::Retain { count } => {
                    let end = pos + *count as i64;
                    if *count > 0 {
                        parts.push((pos, end, displacement));
                    }
                    pos = end;
                }
                crate::server::transport::protocol::TextDeltaOp::Insert { text } => {
                    let len = text.chars().count() as i64;
                    displacement += len;
                }
                crate::server::transport::protocol::TextDeltaOp::Delete { count } => {
                    let end = pos + *count as i64;
                    displacement -= *count as i64;
                    pos = end;
                }
            }
        }

        // Build mapping from the collected (start, end, offset) segments
        // Include zero-offset segments so the full domain is covered
        let mappings: Vec<Mapping> = parts
            .iter()
            .map(|(start, end, off)| Mapping::restricted(*off, XnRegion::interval(*start, *end)))
            .collect();

        if mappings.is_empty() {
            Mapping::identity()
        } else {
            Mapping::from_parts(mappings)
        }
    }
}

/// Flatten a Mapping into a list of (offset, region) pairs.
fn flatten_into(m: &Mapping, out: &mut Vec<(i64, XnRegion)>) {
    match m {
        Mapping::Empty => {}
        Mapping::Simple { offset, region } => {
            if !region.is_empty() {
                out.push((*offset, region.clone()));
            }
        }
        Mapping::Composite(parts) => {
            for p in parts {
                flatten_into(p, out);
            }
        }
    }
}

/// Canonicalize a list of (offset, region) pairs into a minimal Mapping.
/// Merges same-offset overlapping/adjacent regions, removes empty parts,
/// collapses identities, and flattens nested composites.
fn canonicalize(parts: &mut Vec<(i64, XnRegion)>) -> Mapping {
    // Remove empty regions
    parts.retain(|(_, r)| !r.is_empty());
    if parts.is_empty() {
        return Mapping::Empty;
    }

    // Sort by offset, then by region start
    parts.sort_by(|a, b| {
        a.0.cmp(&b.0).then_with(|| {
            let a_start = a.1.start().unwrap_or(i64::MIN);
            let b_start = b.1.start().unwrap_or(i64::MIN);
            a_start.cmp(&b_start)
        })
    });

    // Merge same-offset parts: union overlapping or adjacent regions
    let mut merged: Vec<(i64, XnRegion)> = Vec::new();
    for (offset, region) in parts.drain(..) {
        if let Some(last) = merged.last_mut() {
            if last.0 == offset
                && (last.1.intersects(&region)
                    || last.1.intersects(&region.shift(1))
                    || region.intersects(&last.1.shift(1)))
            {
                last.1 = last.1.union(&region);
                continue;
            }
        }
        merged.push((offset, region));
    }

    // Check for identity collapse: offset=0 and region covers everything
    if merged.len() == 1 && merged[0].0 == 0 {
        let r = &merged[0].1;
        // [0,∞) from above(0) union interval(0,n) = above(0)
        if r == &XnRegion::above(0) || r.is_full() {
            return Mapping::identity();
        }
    }

    match merged.len() {
        0 => Mapping::Empty,
        1 => {
            let (offset, region) = merged.pop().unwrap();
            Mapping::Simple { offset, region }
        }
        _ => Mapping::Composite(
            merged
                .into_iter()
                .map(|(offset, region)| Mapping::Simple { offset, region })
                .collect(),
        ),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Stage 6: from_parts must equal the historical fold-combine for
    /// arbitrary singleton lists — it replaces the quadratic path.
    #[test]
    fn from_parts_equals_fold_combine() {
        let cases: Vec<Vec<(i64, i64, i64)>> = vec![
            vec![],
            vec![(0, 1, 0)],
            vec![(0, 1, 5), (2, 3, -1)],
            vec![(0, 5, 1), (3, 8, 2), (10, 12, 0)],
            vec![(0, 3, 1), (3, 6, 1), (6, 9, -2)],
            vec![(5, 6, 0), (0, 2, 3), (7, 9, -7)],
        ];
        for parts in cases {
            let mappings: Vec<Mapping> = parts
                .iter()
                .map(|(s, e, o)| Mapping::restricted(*o, XnRegion::interval(*s, *e)))
                .collect();
            let folded = mappings
                .clone()
                .into_iter()
                .fold(Mapping::empty(), |acc, m| acc.combine(&m));
            let built = Mapping::from_parts(mappings);
            assert_eq!(folded, built, "from_parts must equal fold for {:?}", parts);
        }
    }

    /// Stage 6 benchmark: 9k singleton parts must canonicalize in
    /// milliseconds, not the ~6.4s the quadratic fold took.
    #[test]
    fn from_parts_scale() {
        let parts: Vec<Mapping> = (0..9_000i64)
            .map(|i| Mapping::restricted(i % 7, XnRegion::interval(i * 2, i * 2 + 1)))
            .collect();
        let start = std::time::Instant::now();
        let m = Mapping::from_parts(parts);
        let elapsed = start.elapsed();
        assert_eq!(m.of(0), Some(0));
        assert_eq!(m.of(4), Some(6), "position 4 -> i=2, offset 2");
        println!("from_parts (9000 parts): {:?}", elapsed);
        assert!(
            elapsed < std::time::Duration::from_secs(2),
            "from_parts should be near-linear, took {:?}",
            elapsed
        );
    }

    #[test]
    fn empty_mapping_maps_nothing() {
        let m = Mapping::empty();
        assert!(m.is_empty());
        assert_eq!(m.of(0), None);
        assert_eq!(m.of(42), None);
        assert!(m.domain().is_empty());
        assert!(m.range().is_empty());
    }

    #[test]
    fn identity_mapping_preserves_positions() {
        let m = Mapping::identity();
        assert!(m.is_identity());
        assert_eq!(m.of(0), Some(0));
        assert_eq!(m.of(42), Some(42));
        assert_eq!(m.of(-5), Some(-5));
    }

    #[test]
    fn shift_mapping_adds_offset() {
        let m = Mapping::shift(10);
        assert_eq!(m.of(0), Some(10));
        assert_eq!(m.of(5), Some(15));
        assert_eq!(m.of(-3), Some(7));
    }

    #[test]
    fn restricted_mapping_only_maps_in_region() {
        let m = Mapping::restricted(5, XnRegion::interval(0, 10));
        assert_eq!(m.of(0), Some(5));
        assert_eq!(m.of(9), Some(14));
        assert_eq!(m.of(10), None);
        assert_eq!(m.of(-1), None);
    }

    #[test]
    fn restricted_empty_region_is_empty() {
        let m = Mapping::restricted(5, XnRegion::empty());
        assert!(m.is_empty());
    }

    #[test]
    fn inverse_shift_negates_offset() {
        let m = Mapping::shift(10);
        let inv = m.inverse();
        assert_eq!(inv.of(10), Some(0));
        assert_eq!(inv.of(15), Some(5));
    }

    #[test]
    fn inverse_restricted_swaps_domain_range() {
        let m = Mapping::restricted(5, XnRegion::interval(0, 3));
        let inv = m.inverse();
        assert_eq!(inv.of(5), Some(0));
        assert_eq!(inv.of(7), Some(2));
        assert_eq!(inv.of(8), None);
        assert_eq!(inv.domain(), XnRegion::interval(5, 8));
    }

    #[test]
    fn inverse_composite() {
        let m = Mapping::Composite(vec![
            Mapping::restricted(10, XnRegion::interval(0, 5)),
            Mapping::restricted(-3, XnRegion::interval(10, 15)),
        ]);
        let inv = m.inverse();
        assert_eq!(inv.of(10), Some(0));
        assert_eq!(inv.of(7), Some(10));
    }

    #[test]
    fn combine_two_shifts_same_offset_adjacent() {
        let a = Mapping::restricted(5, XnRegion::interval(0, 3));
        let b = Mapping::restricted(5, XnRegion::interval(3, 6));
        let combined = a.combine(&b);
        assert_eq!(combined.of(0), Some(5));
        assert_eq!(combined.of(5), Some(10));
        assert_eq!(combined.domain(), XnRegion::interval(0, 6));
    }

    #[test]
    fn combine_different_offsets_creates_composite() {
        let a = Mapping::restricted(0, XnRegion::below(5));
        let b = Mapping::restricted(10, XnRegion::above(5));
        let combined = a.combine(&b);
        assert_eq!(combined.of(0), Some(0));
        assert_eq!(combined.of(4), Some(4));
        assert_eq!(combined.of(5), Some(15));
        assert_eq!(combined.of(20), Some(30));
    }

    #[test]
    fn combine_with_empty_is_identity() {
        let m = Mapping::shift(5);
        let combined = m.combine(&Mapping::empty());
        assert_eq!(combined.of(0), Some(5));

        let combined2 = Mapping::empty().combine(&m);
        assert_eq!(combined2.of(0), Some(5));
    }

    #[test]
    fn restrict_limits_domain() {
        let m = Mapping::shift(10);
        let restricted = m.restrict(&XnRegion::interval(0, 5));
        assert_eq!(restricted.of(0), Some(10));
        assert_eq!(restricted.of(4), Some(14));
        assert_eq!(restricted.of(5), None);
    }

    #[test]
    fn restrict_composite() {
        let m = Mapping::Composite(vec![
            Mapping::restricted(0, XnRegion::interval(0, 5)),
            Mapping::restricted(10, XnRegion::interval(10, 15)),
        ]);
        let restricted = m.restrict(&XnRegion::interval(0, 12));
        assert_eq!(restricted.of(0), Some(0));
        assert_eq!(restricted.of(4), Some(4));
        assert_eq!(restricted.of(10), Some(20));
        assert_eq!(restricted.of(11), Some(21));
        assert_eq!(restricted.of(12), None);
    }

    #[test]
    fn shift_range_adds_to_offset() {
        let m = Mapping::restricted(5, XnRegion::interval(0, 10));
        let shifted = m.shift_range(20);
        assert_eq!(shifted.of(0), Some(25));
        assert_eq!(shifted.of(5), Some(30));
    }

    #[test]
    fn domain_and_range() {
        let m = Mapping::restricted(10, XnRegion::interval(5, 10));
        assert_eq!(m.domain(), XnRegion::interval(5, 10));
        assert_eq!(m.range(), XnRegion::interval(15, 20));
    }

    #[test]
    fn composite_domain_and_range() {
        let m = Mapping::Composite(vec![
            Mapping::restricted(10, XnRegion::interval(0, 5)),
            Mapping::restricted(20, XnRegion::interval(10, 15)),
        ]);
        assert_eq!(
            m.domain(),
            XnRegion::interval(0, 5).union(&XnRegion::interval(10, 15))
        );
        assert_eq!(
            m.range(),
            XnRegion::interval(10, 15).union(&XnRegion::interval(30, 35))
        );
    }

    #[test]
    fn of_region_maps_correctly() {
        let m = Mapping::restricted(10, XnRegion::interval(0, 5));
        let input = XnRegion::interval(2, 4);
        let output = m.of_region(&input);
        assert_eq!(output, XnRegion::interval(12, 14));
    }

    #[test]
    fn of_region_composite() {
        let m = Mapping::Composite(vec![
            Mapping::restricted(0, XnRegion::below(5)),
            Mapping::restricted(10, XnRegion::above(5)),
        ]);
        let input = XnRegion::interval(0, 10);
        let output = m.of_region(&input);
        assert_eq!(
            output,
            XnRegion::interval(0, 5).union(&XnRegion::interval(15, 20))
        );
    }

    #[test]
    fn double_inverse_is_identity() {
        let m = Mapping::restricted(10, XnRegion::interval(0, 5));
        let double_inv = m.inverse().inverse();
        assert_eq!(double_inv.of(0), Some(10));
        assert_eq!(double_inv.of(4), Some(14));
        assert_eq!(double_inv.of(5), None);
    }

    #[test]
    fn transformed_by_simple_shift() {
        let m = Mapping::restricted(10, XnRegion::interval(5, 15));
        let dsp = Mapping::shift(3);
        let m2 = m.transformed_by(&dsp);
        assert_eq!(m2.of(2), Some(15));
        assert_eq!(m2.of(7), Some(20));
        assert_eq!(m2.of(12), None);
    }

    #[test]
    fn transformed_by_identity_is_self() {
        let m = Mapping::restricted(10, XnRegion::interval(0, 10));
        let identity = Mapping::identity();
        assert_eq!(m.transformed_by(&identity), m);
    }

    #[test]
    fn transformed_by_empty_is_empty() {
        let m = Mapping::restricted(10, XnRegion::interval(0, 10));
        assert!(m.transformed_by(&Mapping::empty()).is_empty());
        assert!(Mapping::empty().transformed_by(&m).is_empty());
    }

    #[test]
    fn transformed_by_composite_insert() {
        let m = Mapping::restricted(0, XnRegion::interval(0, 20));
        let dsp = Mapping::Composite(vec![
            Mapping::restricted(0, XnRegion::below(10)),
            Mapping::restricted(5, XnRegion::above(10)),
        ]);
        let m2 = m.transformed_by(&dsp);
        assert_eq!(m2.of(0), Some(0));
        assert_eq!(m2.of(9), Some(9));
        assert_eq!(m2.of(10), Some(15));
        assert_eq!(m2.of(14), Some(19));
        assert_eq!(m2.of(15), None);
    }

    #[test]
    fn transformed_by_preserves_of_semantics() {
        let m = Mapping::restricted(7, XnRegion::interval(3, 12));
        let dsp = Mapping::shift(-2);
        let m2 = m.transformed_by(&dsp);
        for pos in 0..20 {
            let expected = m.of(dsp.of(pos).unwrap_or(pos));
            let actual = m2.of(pos);
            assert_eq!(expected, actual, "mismatch at pos={pos}");
        }
    }

    #[test]
    fn transformed_by_composite_delete() {
        let m = Mapping::restricted(0, XnRegion::interval(0, 20));
        let dsp = Mapping::Composite(vec![
            Mapping::restricted(0, XnRegion::below(5)),
            Mapping::restricted(-3, XnRegion::above(8)),
        ]);
        let m2 = m.transformed_by(&dsp);
        assert_eq!(m2.of(0), Some(0));
        assert_eq!(m2.of(4), Some(4));
        assert_eq!(m2.of(8), Some(5));
        assert_eq!(m2.of(15), Some(12));
    }

    #[test]
    fn from_delta_ops_insert() {
        use crate::server::transport::protocol::TextDeltaOp;
        let ops = vec![
            TextDeltaOp::Retain { count: 5 },
            TextDeltaOp::Insert {
                text: "XXX".to_string(),
            },
            TextDeltaOp::Retain { count: 10 },
        ];
        let dsp = Mapping::from_delta_ops(&ops);
        assert_eq!(dsp.of(0), Some(0));
        assert_eq!(dsp.of(4), Some(4));
        assert_eq!(dsp.of(5), Some(8));
        assert_eq!(dsp.of(14), Some(17));
    }

    #[test]
    fn from_delta_ops_delete() {
        use crate::server::transport::protocol::TextDeltaOp;
        let ops = vec![
            TextDeltaOp::Retain { count: 5 },
            TextDeltaOp::Delete { count: 3 },
            TextDeltaOp::Retain { count: 10 },
        ];
        let dsp = Mapping::from_delta_ops(&ops);
        assert_eq!(dsp.of(0), Some(0));
        assert_eq!(dsp.of(4), Some(4));
        assert_eq!(dsp.of(8), Some(5));
        assert_eq!(dsp.of(17), Some(14));
    }

    #[test]
    fn from_delta_ops_no_change() {
        use crate::server::transport::protocol::TextDeltaOp;
        let ops = vec![TextDeltaOp::Retain { count: 20 }];
        let dsp = Mapping::from_delta_ops(&ops);
        assert_eq!(dsp.of(0), Some(0));
        assert_eq!(dsp.of(19), Some(19));
    }

    #[test]
    fn from_delta_ops_insert_at_end() {
        use crate::server::transport::protocol::TextDeltaOp;
        let ops = vec![
            TextDeltaOp::Retain { count: 10 },
            TextDeltaOp::Insert {
                text: " appended".to_string(),
            },
        ];
        let dsp = Mapping::from_delta_ops(&ops);
        assert_eq!(dsp.of(0), Some(0));
        assert_eq!(dsp.of(9), Some(9));
    }

    #[test]
    fn span_migration_via_algebra() {
        use crate::server::transport::protocol::TextDeltaOp;
        let ops = vec![
            TextDeltaOp::Retain { count: 10 },
            TextDeltaOp::Insert {
                text: "INSERTED ".to_string(),
            },
            TextDeltaOp::Retain { count: 20 },
        ];
        let dsp = Mapping::from_delta_ops(&ops);
        let old_span = XnRegion::interval(15, 25);
        let new_span = dsp.of_region(&old_span);
        assert!(new_span.contains(24));
        assert!(new_span.contains(33));
        assert!(!new_span.contains(23));
        assert!(!new_span.contains(34));
    }

    #[test]
    fn minus_constant_shift() {
        let a = Mapping::shift(10);
        let b = Mapping::shift(3);
        let diff = a.minus(&b);
        assert_eq!(diff.of(0), Some(7));
    }

    #[test]
    fn minus_same_region() {
        // a = shift by 10, b = shift by 3, both over [0,20)
        // a.minus(b): compose a with b.inverse()
        // b.inverse() = { offset: -3, region: [3,23) } (shifted by +3)
        // a.compose_with(b_inv): region = [3,23) ∩ [0,20).shift(3) = [3,23) ∩ [3,23) = [3,23)
        // offset = 10 + (-3) = 7
        let a = Mapping::restricted(10, XnRegion::interval(0, 20));
        let b = Mapping::restricted(3, XnRegion::interval(0, 20));
        let diff = a.minus(&b);
        let result = diff.of(5);
        // 5 is in [3,23) so result = 5 + 7 = 12
        assert_eq!(result, Some(12));
    }

    #[test]
    fn compose_with_identity() {
        let m = Mapping::restricted(5, XnRegion::interval(0, 10));
        assert_eq!(m.compose_with(&Mapping::identity()), m);
        assert_eq!(Mapping::identity().compose_with(&m), m);
    }

    #[test]
    fn compose_two_shifts() {
        let a = Mapping::shift(3);
        let b = Mapping::shift(5);
        let composed = a.compose_with(&b);
        assert_eq!(composed.of(0), Some(8));
    }

    #[test]
    fn minus_undoes_migration() {
        let edit_dsp = Mapping::shift(10);
        let migrated = Mapping::shift(20);
        let original = migrated.minus(&edit_dsp);
        assert_eq!(original.of(0), Some(10));
    }

    #[test]
    fn compose_with_composite() {
        let simple = Mapping::restricted(0, XnRegion::interval(0, 30));
        let composite = Mapping::Composite(vec![
            Mapping::restricted(0, XnRegion::below(10)),
            Mapping::restricted(5, XnRegion::above(10)),
        ]);
        let result = simple.compose_with(&composite);
        assert_eq!(result.of(0), Some(0));
        assert_eq!(result.of(9), Some(9));
        assert_eq!(result.of(15), Some(20));
    }

    #[test]
    fn combine_merges_same_offset_overlapping() {
        let a = Mapping::restricted(5, XnRegion::interval(0, 10));
        let b = Mapping::restricted(5, XnRegion::interval(5, 15));
        let combined = a.combine(&b);
        match combined {
            Mapping::Simple { offset, region } => {
                assert_eq!(offset, 5);
                assert!(region.contains(0));
                assert!(region.contains(14));
            }
            _ => panic!("expected Simple, got {:?}", combined),
        }
    }

    #[test]
    fn combine_merges_same_offset_adjacent() {
        let a = Mapping::restricted(3, XnRegion::interval(0, 5));
        let b = Mapping::restricted(3, XnRegion::interval(5, 10));
        let combined = a.combine(&b);
        match combined {
            Mapping::Simple { offset, region } => {
                assert_eq!(offset, 3);
                assert!(region.contains(0));
                assert!(region.contains(9));
            }
            _ => panic!("expected Simple for adjacent, got {:?}", combined),
        }
    }

    #[test]
    fn combine_keeps_different_offsets() {
        let a = Mapping::restricted(5, XnRegion::interval(0, 10));
        let b = Mapping::restricted(10, XnRegion::interval(0, 10));
        let combined = a.combine(&b);
        assert!(matches!(combined, Mapping::Composite(_)));
    }

    #[test]
    fn combine_collapses_identity() {
        // interval(0,10) union above(10) = [0,10) ∪ [10,∞) = [0,∞) = full
        let a = Mapping::restricted(0, XnRegion::interval(0, 10));
        let b = Mapping::restricted(0, XnRegion::above(10));
        let combined = a.combine(&b);
        // Should merge into offset=0, region=full → identity
        assert!(
            combined.is_identity(),
            "expected identity, got {:?}",
            combined
        );
    }

    #[test]
    fn combine_flattens_nested() {
        let inner = Mapping::Composite(vec![Mapping::restricted(3, XnRegion::interval(0, 5))]);
        let outer = Mapping::restricted(3, XnRegion::interval(5, 10));
        let combined = inner.combine(&outer);
        match combined {
            Mapping::Simple { offset, region } => {
                assert_eq!(offset, 3);
                assert!(region.contains(0));
                assert!(region.contains(9));
            }
            _ => panic!("expected flattened Simple, got {:?}", combined),
        }
    }

    #[test]
    fn combine_repeated_builds_canonical() {
        let mut m = Mapping::empty();
        for i in 0..5 {
            m = m.combine(&Mapping::restricted(
                5,
                XnRegion::interval(i * 3, i * 3 + 3),
            ));
        }
        // All parts have offset 5, should merge into one Simple
        match m {
            Mapping::Simple { offset, region } => {
                assert_eq!(offset, 5);
                assert!(region.contains(0));
                assert!(region.contains(14));
            }
            _ => panic!("expected canonical Simple, got {:?}", m),
        }
    }

    #[test]
    fn combine_empty_parts_removed() {
        let a = Mapping::restricted(5, XnRegion::interval(0, 10));
        let b = Mapping::restricted(5, XnRegion::empty());
        let combined = a.combine(&b);
        assert_eq!(combined, a);
    }
}
