use std::sync::Arc;

use super::range_element::{Carrier, RangeElement};
use super::xn_region::XnRegion;

#[derive(Debug, Clone, PartialEq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
#[cfg_attr(feature = "serde", serde(tag = "type", rename_all = "snake_case"))]
pub enum Bundle {
    Element {
        region: XnRegion,
        element: RangeElement,
    },
    Array {
        region: XnRegion,
        elements: Vec<RangeElement>,
    },
    PlaceHolder {
        region: XnRegion,
    },
}

impl Bundle {
    pub fn region(&self) -> &XnRegion {
        match self {
            Bundle::Element { region, .. } => region,
            Bundle::Array { region, .. } => region,
            Bundle::PlaceHolder { region } => region,
        }
    }

    pub fn is_empty(&self) -> bool {
        self.region().is_empty()
    }

    pub fn count(&self) -> u64 {
        self.region().count().unwrap_or(0)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
#[cfg_attr(feature = "serde", serde(rename_all = "snake_case"))]
pub enum CostMethod {
    OmitShared,
    ProrateShared,
    TotalShared,
}

impl Default for CostMethod {
    fn default() -> Self {
        CostMethod::TotalShared
    }
}

#[derive(Debug, Clone, PartialEq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct StorageCost {
    pub total_bytes: u64,
    pub unique_bytes: u64,
    pub shared_bytes: u64,
    pub share_count: u64,
    pub method: CostMethod,
}

impl StorageCost {
    pub fn zero(method: CostMethod) -> Self {
        StorageCost {
            total_bytes: 0,
            unique_bytes: 0,
            shared_bytes: 0,
            share_count: 0,
            method,
        }
    }

    pub fn billed_bytes(&self) -> u64 {
        match self.method {
            CostMethod::OmitShared => self.unique_bytes,
            CostMethod::ProrateShared => {
                if self.share_count == 0 {
                    self.unique_bytes
                } else {
                    self.unique_bytes + self.shared_bytes / self.share_count
                }
            }
            CostMethod::TotalShared => self.total_bytes,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct RetrieveFlags {
    pub ignore_total_ordering: bool,
    pub ignore_array_ordering: bool,
    pub separate_owners: bool,
}

impl Default for RetrieveFlags {
    fn default() -> Self {
        RetrieveFlags {
            ignore_total_ordering: false,
            ignore_array_ordering: false,
            separate_owners: false,
        }
    }
}

impl RetrieveFlags {
    pub fn empty() -> Self {
        RetrieveFlags::default()
    }
}

fn positions_to_region(positions: &[i64]) -> XnRegion {
    let mut region = XnRegion::empty();
    for &p in positions {
        region = region.with(p);
    }
    region
}

pub fn retrieve_bundles(
    entries: &[(i64, Arc<Carrier>)],
    region: Option<&XnRegion>,
    _flags: RetrieveFlags,
) -> Vec<Bundle> {
    let filtered: Vec<(i64, Arc<Carrier>)> = match region {
        Some(r) => entries
            .iter()
            .filter(|(p, _)| r.contains(*p))
            .cloned()
            .collect(),
        None => entries.to_vec(),
    };

    if filtered.is_empty() {
        return Vec::new();
    }

    let mut bundles: Vec<Bundle> = Vec::new();
    let mut run_start = 0;

    while run_start < filtered.len() {
        let start_element = filtered[run_start].1.element.clone();
        let is_placeholder = matches!(start_element, RangeElement::PlaceHolder { .. });

        if is_placeholder {
            let mut run_end = run_start + 1;
            while run_end < filtered.len() {
                if !matches!(
                    filtered[run_end].1.element,
                    RangeElement::PlaceHolder { .. }
                ) {
                    break;
                }
                run_end += 1;
            }
            let positions: Vec<i64> = filtered[run_start..run_end]
                .iter()
                .map(|(p, _)| *p)
                .collect();
            let region = positions_to_region(&positions);
            bundles.push(Bundle::PlaceHolder { region });
            run_start = run_end;
        } else {
            let mut same_element = true;
            let mut run_end = run_start + 1;

            while run_end < filtered.len() {
                let elem = &filtered[run_end].1.element;
                if matches!(elem, RangeElement::PlaceHolder { .. }) {
                    break;
                }
                if *elem != start_element {
                    same_element = false;
                }
                if !same_element {
                    break;
                }
                run_end += 1;
            }

            if same_element && run_end > run_start {
                let positions: Vec<i64> = filtered[run_start..run_end]
                    .iter()
                    .map(|(p, _)| *p)
                    .collect();
                let region = positions_to_region(&positions);
                bundles.push(Bundle::Element {
                    region,
                    element: start_element,
                });
                run_start = run_end;
            } else {
                let mut array_end = run_start + 1;
                while array_end < filtered.len() {
                    if matches!(
                        filtered[array_end].1.element,
                        RangeElement::PlaceHolder { .. }
                    ) {
                        break;
                    }
                    if array_end - run_start >= 1024 {
                        break;
                    }
                    array_end += 1;
                }
                let positions: Vec<i64> = filtered[run_start..array_end]
                    .iter()
                    .map(|(p, _)| *p)
                    .collect();
                let elements: Vec<RangeElement> = filtered[run_start..array_end]
                    .iter()
                    .map(|(_, c)| c.element.clone())
                    .collect();

                let can_merge = elements.windows(2).all(|w| w[0] == w[1]);
                let region = positions_to_region(&positions);

                if can_merge {
                    bundles.push(Bundle::Element {
                        region,
                        element: elements[0].clone(),
                    });
                } else {
                    bundles.push(Bundle::Array { region, elements });
                }
                run_start = array_end;
            }
        }
    }

    bundles
}

pub fn compute_storage_cost(
    entries: &[(i64, Arc<Carrier>)],
    content_share_counts: &std::collections::HashMap<u64, u64>,
    method: CostMethod,
) -> StorageCost {
    let mut total_bytes: u64 = 0;
    let mut unique_bytes: u64 = 0;
    let mut shared_bytes: u64 = 0;
    let mut share_count: u64 = 0;

    for (_, carrier) in entries {
        let elem_size = element_byte_size(&carrier.element);
        total_bytes += elem_size;

        let fingerprint = fingerprint_u64(&carrier.element);
        if let Some(&count) = content_share_counts.get(&fingerprint) {
            if count > 1 {
                shared_bytes += elem_size;
                share_count = share_count.max(count);
            } else {
                unique_bytes += elem_size;
            }
        } else {
            unique_bytes += elem_size;
        }
    }

    StorageCost {
        total_bytes,
        unique_bytes,
        shared_bytes,
        share_count,
        method,
    }
}

pub fn element_byte_size(element: &RangeElement) -> u64 {
    match element {
        RangeElement::Text { text } => {
            let base = std::mem::size_of::<RangeElement>() as u64;
            base + text.len() as u64
        }
        RangeElement::Data { bytes } => {
            let base = std::mem::size_of::<RangeElement>() as u64;
            base + bytes.len() as u64
        }
        RangeElement::Blob { byte_size, .. } => {
            let base = std::mem::size_of::<RangeElement>() as u64;
            base + byte_size
        }
        RangeElement::Overlay { overlay } => {
            let base = std::mem::size_of::<RangeElement>() as u64;
            base + overlay.operations.len() as u64 * 64
        }
        RangeElement::Edition { .. } => std::mem::size_of::<RangeElement>() as u64 + 16,
        RangeElement::Label { inner, .. } => {
            std::mem::size_of::<RangeElement>() as u64 + element_byte_size(inner)
        }
        _ => std::mem::size_of::<RangeElement>() as u64,
    }
}

pub fn fingerprint_u64(element: &RangeElement) -> u64 {
    let bytes = element.content_fingerprint();
    let mut arr = [0u8; 8];
    arr.copy_from_slice(&bytes[..8]);
    u64::from_le_bytes(arr)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn element_bundle_single_type() {
        let entries = vec![
            (0, Arc::new(Carrier::new(RangeElement::text("a")))),
            (1, Arc::new(Carrier::new(RangeElement::text("a")))),
            (2, Arc::new(Carrier::new(RangeElement::text("a")))),
        ];
        let bundles = retrieve_bundles(&entries, None, RetrieveFlags::empty());
        assert_eq!(bundles.len(), 1);
        match &bundles[0] {
            Bundle::Element { region, element } => {
                assert_eq!(region.count(), Some(3));
                assert_eq!(*element, RangeElement::text("a"));
            }
            _ => panic!("expected ElementBundle"),
        }
    }

    #[test]
    fn array_bundle_mixed() {
        let entries = vec![
            (0, Arc::new(Carrier::new(RangeElement::text("a")))),
            (1, Arc::new(Carrier::new(RangeElement::text("b")))),
            (2, Arc::new(Carrier::new(RangeElement::text("c")))),
        ];
        let bundles = retrieve_bundles(&entries, None, RetrieveFlags::empty());
        assert_eq!(bundles.len(), 1);
        match &bundles[0] {
            Bundle::Array { region, elements } => {
                assert_eq!(region.count(), Some(3));
                assert_eq!(elements.len(), 3);
                assert_eq!(elements[0], RangeElement::text("a"));
                assert_eq!(elements[1], RangeElement::text("b"));
                assert_eq!(elements[2], RangeElement::text("c"));
            }
            _ => panic!("expected ArrayBundle"),
        }
    }

    #[test]
    fn placeholder_bundle() {
        let entries = vec![
            (0, Arc::new(Carrier::new(RangeElement::placeholder(1)))),
            (1, Arc::new(Carrier::new(RangeElement::placeholder(2)))),
        ];
        let bundles = retrieve_bundles(&entries, None, RetrieveFlags::empty());
        assert_eq!(bundles.len(), 1);
        match &bundles[0] {
            Bundle::PlaceHolder { region } => {
                assert_eq!(region.count(), Some(2));
            }
            _ => panic!("expected PlaceHolderBundle"),
        }
    }

    #[test]
    fn mixed_bundles() {
        let entries = vec![
            (0, Arc::new(Carrier::new(RangeElement::text("a")))),
            (1, Arc::new(Carrier::new(RangeElement::text("a")))),
            (2, Arc::new(Carrier::new(RangeElement::placeholder(1)))),
            (3, Arc::new(Carrier::new(RangeElement::text("b")))),
        ];
        let bundles = retrieve_bundles(&entries, None, RetrieveFlags::empty());
        assert!(bundles.len() >= 2);
        let types: Vec<&str> = bundles
            .iter()
            .map(|b| match b {
                Bundle::Element { .. } => "element",
                Bundle::Array { .. } => "array",
                Bundle::PlaceHolder { .. } => "placeholder",
            })
            .collect();
        assert!(types.contains(&"element") || types.contains(&"array"));
        assert!(types.contains(&"placeholder"));
    }

    #[test]
    fn retrieve_with_region_filter() {
        let entries = vec![
            (0, Arc::new(Carrier::new(RangeElement::text("a")))),
            (1, Arc::new(Carrier::new(RangeElement::text("b")))),
            (2, Arc::new(Carrier::new(RangeElement::text("c")))),
        ];
        let region = XnRegion::interval(1, 3);
        let bundles = retrieve_bundles(&entries, Some(&region), RetrieveFlags::empty());
        assert_eq!(bundles.len(), 1);
        match &bundles[0] {
            Bundle::Array { elements, region } => {
                assert_eq!(elements.len(), 2);
                assert_eq!(elements[0], RangeElement::text("b"));
                assert_eq!(elements[1], RangeElement::text("c"));
                assert_eq!(region.count(), Some(2));
            }
            _ => panic!("expected ArrayBundle"),
        }
    }

    #[test]
    fn retrieve_empty() {
        let entries: Vec<(i64, Arc<Carrier>)> = vec![];
        let bundles = retrieve_bundles(&entries, None, RetrieveFlags::empty());
        assert!(bundles.is_empty());
    }

    #[test]
    fn storage_cost_text() {
        let entries = vec![(0, Arc::new(Carrier::new(RangeElement::text("hello"))))];
        let cost = compute_storage_cost(
            &entries,
            &std::collections::HashMap::new(),
            CostMethod::TotalShared,
        );
        assert!(cost.total_bytes > 0);
        assert_eq!(cost.total_bytes, cost.billed_bytes());
    }

    #[test]
    fn storage_cost_omit_shared() {
        let mut share_counts = std::collections::HashMap::new();
        let fp = fingerprint_u64(&RangeElement::text("shared"));
        share_counts.insert(fp, 3);

        let entries = vec![
            (0, Arc::new(Carrier::new(RangeElement::text("shared")))),
            (1, Arc::new(Carrier::new(RangeElement::text("unique")))),
        ];
        let cost = compute_storage_cost(&entries, &share_counts, CostMethod::OmitShared);
        assert!(cost.unique_bytes > 0);
        assert!(cost.shared_bytes > 0);
        assert_eq!(cost.billed_bytes(), cost.unique_bytes);
    }

    #[test]
    fn storage_cost_prorate_shared() {
        let mut share_counts = std::collections::HashMap::new();
        let fp = fingerprint_u64(&RangeElement::text("shared"));
        share_counts.insert(fp, 4);

        let entries = vec![(0, Arc::new(Carrier::new(RangeElement::text("shared"))))];
        let cost = compute_storage_cost(&entries, &share_counts, CostMethod::ProrateShared);
        assert!(cost.shared_bytes > 0);
        assert!(cost.billed_bytes() < cost.total_bytes);
    }

    #[test]
    fn bundle_region_accessor() {
        let region = XnRegion::interval(5, 10);
        let bundle = Bundle::Element {
            region: region.clone(),
            element: RangeElement::text("x"),
        };
        assert_eq!(bundle.region(), &region);
        assert_eq!(bundle.count(), 5);
    }

    #[test]
    fn cost_method_default() {
        assert_eq!(CostMethod::default(), CostMethod::TotalShared);
    }

    #[test]
    fn element_byte_sizes() {
        let text_size = element_byte_size(&RangeElement::text("hello"));
        assert!(text_size > 5);

        let data_size = element_byte_size(&RangeElement::data(vec![1, 2, 3]));
        assert!(data_size > 3);

        let ph_size = element_byte_size(&RangeElement::placeholder(1));
        assert!(ph_size > 0);

        let edition_size = element_byte_size(&RangeElement::edition(42));
        assert!(edition_size > 0);

        let blob_size = element_byte_size(&RangeElement::blob(123, "image/png", 1000));
        assert!(blob_size > 1000);
    }

    #[test]
    fn retrieve_with_empty_region() {
        let entries = vec![(0, Arc::new(Carrier::new(RangeElement::text("a"))))];
        let region = XnRegion::empty();
        let bundles = retrieve_bundles(&entries, Some(&region), RetrieveFlags::empty());
        assert!(bundles.is_empty());
    }

    #[test]
    fn retrieve_preserves_position_ordering() {
        let entries = vec![
            (5, Arc::new(Carrier::new(RangeElement::text("x")))),
            (10, Arc::new(Carrier::new(RangeElement::text("y")))),
            (15, Arc::new(Carrier::new(RangeElement::text("z")))),
        ];
        let bundles = retrieve_bundles(&entries, None, RetrieveFlags::empty());
        assert_eq!(bundles.len(), 1);
        match &bundles[0] {
            Bundle::Array { elements, region } => {
                assert_eq!(elements[0], RangeElement::text("x"));
                assert_eq!(elements[1], RangeElement::text("y"));
                assert_eq!(elements[2], RangeElement::text("z"));
                assert!(region.contains(5));
                assert!(region.contains(10));
                assert!(region.contains(15));
                assert!(!region.contains(0));
            }
            _ => panic!("expected ArrayBundle"),
        }
    }

    #[test]
    fn storage_cost_zero() {
        let cost = StorageCost::zero(CostMethod::OmitShared);
        assert_eq!(cost.total_bytes, 0);
        assert_eq!(cost.unique_bytes, 0);
        assert_eq!(cost.shared_bytes, 0);
        assert_eq!(cost.billed_bytes(), 0);
    }

    #[test]
    fn retrieve_labelled_elements() {
        let entries = vec![
            (
                0,
                Arc::new(Carrier::labelled(
                    super::super::range_element::RangeElementId::new(1),
                    RangeElement::text("a"),
                )),
            ),
            (
                1,
                Arc::new(Carrier::labelled(
                    super::super::range_element::RangeElementId::new(1),
                    RangeElement::text("a"),
                )),
            ),
        ];
        let bundles = retrieve_bundles(&entries, None, RetrieveFlags::empty());
        assert!(bundles.len() >= 1);
    }
}
