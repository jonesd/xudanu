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

    pub fn combine(&self, other: &Mapping) -> Mapping {
        if self.is_empty() {
            return other.clone();
        }
        if other.is_empty() {
            return self.clone();
        }
        match (self, other) {
            (
                Mapping::Simple {
                    offset: a_off,
                    region: a_reg,
                },
                Mapping::Simple {
                    offset: b_off,
                    region: b_reg,
                },
            ) if a_off == b_off && a_reg.intersects(b_reg) => {
                let merged = a_reg.union(b_reg);
                Mapping::Simple {
                    offset: *a_off,
                    region: merged,
                }
            }
            (
                Mapping::Simple {
                    offset: a_off,
                    region: a_reg,
                },
                Mapping::Simple {
                    offset: b_off,
                    region: b_reg,
                },
            ) if a_off == b_off && !a_reg.intersects(b_reg) => {
                Mapping::Composite(vec![self.clone(), other.clone()])
            }
            _ => Mapping::Composite(vec![self.clone(), other.clone()]),
        }
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
}

#[cfg(test)]
mod tests {
    use super::*;

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
}
