use std::sync::Arc;

use super::bundle::Bundle;
use super::orgl::Loaf;
use super::range_element::Carrier;
use super::xn_region::XnRegion;

pub struct BundleStepper {
    bundles: Vec<Bundle>,
    index: usize,
}

impl BundleStepper {
    pub fn empty() -> Self {
        BundleStepper {
            bundles: Vec::new(),
            index: 0,
        }
    }

    pub fn single(bundle: Bundle) -> Self {
        BundleStepper {
            bundles: vec![bundle],
            index: 0,
        }
    }

    pub fn from_entries(entries: Vec<(i64, Arc<Carrier>)>) -> Self {
        if entries.is_empty() {
            return BundleStepper::empty();
        }
        let mut bundles = Vec::new();
        let mut run_start = 0;
        for i in 1..=entries.len() {
            let end_of_run = i == entries.len() || *entries[i].1 != *entries[i - 1].1;
            if end_of_run {
                let run_end = i;
                let region = XnRegion::interval(entries[run_start].0, entries[run_end - 1].0 + 1);
                if run_end - run_start == 1 {
                    bundles.push(Bundle::Element {
                        region,
                        element: entries[run_start].1.element.clone(),
                    });
                } else {
                    let elements: Vec<_> = entries[run_start..run_end]
                        .iter()
                        .map(|(_, c)| c.element.clone())
                        .collect();
                    bundles.push(Bundle::Array { region, elements });
                }
                run_start = i;
            }
        }
        BundleStepper { bundles, index: 0 }
    }

    pub fn has_value(&self) -> bool {
        self.index < self.bundles.len()
    }

    pub fn fetch(&mut self) -> Option<&Bundle> {
        if self.index < self.bundles.len() {
            let bundle = &self.bundles[self.index];
            self.index += 1;
            Some(bundle)
        } else {
            None
        }
    }

    pub fn peek(&self) -> Option<&Bundle> {
        if self.index < self.bundles.len() {
            Some(&self.bundles[self.index])
        } else {
            None
        }
    }

    pub fn region(&self) -> Option<&XnRegion> {
        self.peek().map(|b| b.region())
    }

    pub fn collect_all(mut self) -> Vec<Bundle> {
        let mut result = Vec::new();
        while self.has_value() {
            if let Some(b) = self.fetch() {
                result.push(b.clone());
            }
        }
        result
    }

    fn peek_start(&self) -> Option<i64> {
        self.peek().and_then(|b| b.region().start())
    }
}

pub struct MergeBundleStepper {
    left: BundleStepper,
    right: BundleStepper,
}

impl MergeBundleStepper {
    pub fn new(left: BundleStepper, right: BundleStepper) -> Self {
        MergeBundleStepper { left, right }
    }

    pub fn has_value(&self) -> bool {
        self.left.has_value() || self.right.has_value()
    }

    pub fn fetch(&mut self) -> Option<Bundle> {
        match (self.left.peek_start(), self.right.peek_start()) {
            (Some(l), Some(r)) => {
                if l <= r {
                    self.left.fetch().cloned()
                } else {
                    self.right.fetch().cloned()
                }
            }
            (Some(_), None) => self.left.fetch().cloned(),
            (None, Some(_)) => self.right.fetch().cloned(),
            (None, None) => None,
        }
    }

    pub fn collect_all(mut self) -> Vec<Bundle> {
        let mut result = Vec::new();
        while self.has_value() {
            if let Some(b) = self.fetch() {
                result.push(b);
            }
        }
        result
    }
}

pub fn loaf_bundle_stepper(loaf: &Loaf, region: &XnRegion) -> BundleStepper {
    let entries = collect_entries_in_region(loaf, region);
    BundleStepper::from_entries(entries)
}

fn collect_entries_in_region(loaf: &Loaf, region: &XnRegion) -> Vec<(i64, Arc<Carrier>)> {
    match loaf {
        Loaf::Leaf {
            entries,
            region: leaf_region,
            ..
        } => {
            let intersection = leaf_region.intersect(region);
            if intersection.is_empty() {
                return Vec::new();
            }
            entries
                .iter()
                .filter(|(pos, _)| region.contains(*pos))
                .cloned()
                .collect()
        }
        Loaf::Split {
            split,
            in_child,
            out_child,
        } => {
            let in_region = region.intersect(split);
            let out_region = region.minus(split);
            let mut in_entries = collect_entries_in_region(in_child, &in_region);
            let out_entries = collect_entries_in_region(out_child, &out_region);
            in_entries.extend(out_entries);
            in_entries.sort_by_key(|(p, _)| *p);
            in_entries
        }
        Loaf::Dsp { offset, child } => {
            let child_region = shift_region_inverted(region, *offset);
            let entries = collect_entries_in_region(child, &child_region);
            entries.into_iter().map(|(p, c)| (p + offset, c)).collect()
        }
    }
}

fn shift_region_inverted(region: &XnRegion, offset: i64) -> XnRegion {
    let intervals = region.intervals();
    let mut result = XnRegion::empty();
    for (start, stop) in intervals {
        let new_start = start.wrapping_sub(offset);
        let new_stop = stop.wrapping_sub(offset);
        if new_start < new_stop {
            result = result.union(&XnRegion::interval(new_start, new_stop));
        }
    }
    result
}

pub fn loaf_merge_stepper(loaf: &Loaf, region: &XnRegion) -> MergeBundleStepper {
    match loaf {
        Loaf::Leaf { .. } => {
            let stepper = loaf_bundle_stepper(loaf, region);
            MergeBundleStepper::new(stepper, BundleStepper::empty())
        }
        Loaf::Split {
            split,
            in_child,
            out_child,
        } => {
            let in_region = region.intersect(split);
            let out_region = region.minus(split);
            let in_ms = loaf_merge_stepper(in_child, &in_region);
            let out_ms = loaf_merge_stepper(out_child, &out_region);
            merge_two(in_ms, out_ms)
        }
        Loaf::Dsp { offset, child } => {
            let child_region = shift_region_inverted(region, *offset);
            let bundles: Vec<Bundle> = loaf_merge_stepper(child, &child_region)
                .collect_all()
                .into_iter()
                .map(|b| shift_bundle(b, *offset))
                .collect();
            let stepper = BundleStepper { bundles, index: 0 };
            MergeBundleStepper::new(stepper, BundleStepper::empty())
        }
    }
}

fn merge_two(a: MergeBundleStepper, b: MergeBundleStepper) -> MergeBundleStepper {
    let all_a = a.collect_all();
    let all_b = b.collect_all();
    let left = BundleStepper {
        bundles: all_a,
        index: 0,
    };
    let right = BundleStepper {
        bundles: all_b,
        index: 0,
    };
    MergeBundleStepper::new(left, right)
}

fn shift_bundle(bundle: Bundle, offset: i64) -> Bundle {
    let new_region = shift_bundle_region(bundle.region(), offset);
    match bundle {
        Bundle::Element { element, .. } => Bundle::Element {
            region: new_region,
            element,
        },
        Bundle::Array { elements, .. } => Bundle::Array {
            region: new_region,
            elements,
        },
        Bundle::PlaceHolder { .. } => Bundle::PlaceHolder { region: new_region },
    }
}

fn shift_bundle_region(region: &XnRegion, offset: i64) -> XnRegion {
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::range_element::RangeElement;

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
    fn bundle_stepper_empty() {
        let stepper = BundleStepper::from_entries(vec![]);
        assert!(!stepper.has_value());
    }

    #[test]
    fn bundle_stepper_single_element() {
        let entries = vec![(0i64, Arc::new(Carrier::new(RangeElement::text("a"))))];
        let mut stepper = BundleStepper::from_entries(entries);
        assert!(stepper.has_value());
        let b = stepper.fetch().unwrap();
        assert!(matches!(b, Bundle::Element { .. }));
        assert_eq!(b.region().start(), Some(0));
        assert!(!stepper.has_value());
    }

    #[test]
    fn bundle_stepper_groups_same_elements() {
        let entries = vec![
            (0i64, Arc::new(Carrier::new(RangeElement::text("x")))),
            (1i64, Arc::new(Carrier::new(RangeElement::text("x")))),
            (2i64, Arc::new(Carrier::new(RangeElement::text("y")))),
        ];
        let mut stepper = BundleStepper::from_entries(entries);
        assert!(stepper.has_value());
        let first = stepper.fetch().unwrap();
        assert!(matches!(first, Bundle::Array { .. }));
        assert_eq!(first.region().start(), Some(0));
        let second = stepper.fetch().unwrap();
        assert!(matches!(second, Bundle::Element { .. }));
        assert_eq!(second.region().start(), Some(2));
        assert!(!stepper.has_value());
    }

    #[test]
    fn bundle_stepper_from_loaf_leaf() {
        let loaf = make_text_loaf("abc");
        let region = XnRegion::interval(0, 3);
        let stepper = loaf_bundle_stepper(&loaf, &region);
        let bundles = stepper.collect_all();
        assert!(!bundles.is_empty());
    }

    #[test]
    fn bundle_stepper_from_loaf_partial_region() {
        let loaf = make_text_loaf("abcde");
        let region = XnRegion::interval(1, 4);
        let stepper = loaf_bundle_stepper(&loaf, &region);
        let bundles = stepper.collect_all();
        assert!(!bundles.is_empty());
        for b in &bundles {
            assert!(b.region().intersects(&region));
        }
    }

    #[test]
    fn bundle_stepper_from_loaf_split() {
        let loaf = Loaf::Split {
            split: XnRegion::below(2),
            in_child: Box::new(make_text_loaf("ab")),
            out_child: Box::new(make_text_loaf("cde")),
        };
        let region = XnRegion::interval(0, 4);
        let stepper = loaf_bundle_stepper(&loaf, &region);
        let bundles = stepper.collect_all();
        assert!(!bundles.is_empty());
    }

    #[test]
    fn bundle_stepper_from_loaf_dsp() {
        let loaf = Loaf::Dsp {
            offset: 10,
            child: Box::new(make_text_loaf("ab")),
        };
        let region = XnRegion::interval(10, 12);
        let stepper = loaf_bundle_stepper(&loaf, &region);
        let bundles = stepper.collect_all();
        assert!(!bundles.is_empty());
        assert_eq!(bundles[0].region().start(), Some(10));
    }

    #[test]
    fn merge_bundle_stepper_orders_correctly() {
        let e1 = vec![(0i64, Arc::new(Carrier::new(RangeElement::text("a"))))];
        let e2 = vec![(1i64, Arc::new(Carrier::new(RangeElement::text("b"))))];
        let left = BundleStepper::from_entries(e1);
        let right = BundleStepper::from_entries(e2);
        let mut merged = MergeBundleStepper::new(left, right);
        let first = merged.fetch().unwrap();
        assert_eq!(first.region().start(), Some(0));
        let second = merged.fetch().unwrap();
        assert_eq!(second.region().start(), Some(1));
        assert!(!merged.has_value());
    }

    #[test]
    fn merge_bundle_stepper_reverse_order() {
        let e1 = vec![(5i64, Arc::new(Carrier::new(RangeElement::text("a"))))];
        let e2 = vec![(2i64, Arc::new(Carrier::new(RangeElement::text("b"))))];
        let left = BundleStepper::from_entries(e1);
        let right = BundleStepper::from_entries(e2);
        let mut merged = MergeBundleStepper::new(left, right);
        let first = merged.fetch().unwrap();
        assert_eq!(first.region().start(), Some(2));
        let second = merged.fetch().unwrap();
        assert_eq!(second.region().start(), Some(5));
    }

    #[test]
    fn merge_bundle_stepper_empty() {
        let left = BundleStepper::empty();
        let right = BundleStepper::empty();
        let merged = MergeBundleStepper::new(left, right);
        assert!(!merged.has_value());
    }

    #[test]
    fn merge_bundle_stepper_one_empty() {
        let e = vec![(0i64, Arc::new(Carrier::new(RangeElement::text("x"))))];
        let left = BundleStepper::from_entries(e);
        let right = BundleStepper::empty();
        let mut merged = MergeBundleStepper::new(left, right);
        assert!(merged.has_value());
        let b = merged.fetch().unwrap();
        assert_eq!(b.region().start(), Some(0));
        assert!(!merged.has_value());
    }

    #[test]
    fn loaf_merge_stepper_leaf() {
        let loaf = make_text_loaf("abc");
        let region = XnRegion::interval(0, 3);
        let ms = loaf_merge_stepper(&loaf, &region);
        let bundles = ms.collect_all();
        assert!(!bundles.is_empty());
    }

    #[test]
    fn loaf_merge_stepper_split_preserves_order() {
        let loaf = Loaf::Split {
            split: XnRegion::below(2),
            in_child: Box::new(make_text_loaf("ab")),
            out_child: Box::new(make_text_loaf("cde")),
        };
        let region = XnRegion::interval(0, 5);
        let ms = loaf_merge_stepper(&loaf, &region);
        let bundles = ms.collect_all();
        let mut last_start = i64::MIN;
        for b in &bundles {
            let start = b.region().start().unwrap_or(i64::MAX);
            assert!(
                start >= last_start,
                "bundles not ordered: {} >= {}",
                start,
                last_start
            );
            last_start = start;
        }
    }

    #[test]
    fn loaf_merge_stepper_dsp_shifts() {
        let loaf = Loaf::Dsp {
            offset: 100,
            child: Box::new(make_text_loaf("xy")),
        };
        let region = XnRegion::interval(100, 102);
        let ms = loaf_merge_stepper(&loaf, &region);
        let bundles = ms.collect_all();
        assert!(!bundles.is_empty());
        assert_eq!(bundles[0].region().start(), Some(100));
    }

    #[test]
    fn bundle_stepper_peek_does_not_advance() {
        let entries = vec![
            (0i64, Arc::new(Carrier::new(RangeElement::text("a")))),
            (1i64, Arc::new(Carrier::new(RangeElement::text("b")))),
        ];
        let mut stepper = BundleStepper::from_entries(entries);
        let r1 = stepper.region().cloned();
        let r2 = stepper.region().cloned();
        assert_eq!(r1, r2);
        stepper.fetch();
        let r3 = stepper.region().cloned();
        assert_ne!(r1, r3);
    }

    #[test]
    fn bundle_stepper_collect_all_exhausts() {
        let entries: Vec<(i64, Arc<Carrier>)> = (0..10)
            .map(|i| {
                (
                    i,
                    Arc::new(Carrier::new(RangeElement::text(format!("{i}")))),
                )
            })
            .collect();
        let stepper = BundleStepper::from_entries(entries);
        let bundles = stepper.collect_all();
        assert_eq!(bundles.len(), 10);
    }
}
