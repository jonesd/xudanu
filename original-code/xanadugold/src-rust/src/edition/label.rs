use std::collections::HashMap;
use std::sync::atomic::{AtomicU64, Ordering};

use super::range_element::{Carrier, RangeElement, RangeElementId};
use super::xn_region::XnRegion;
use super::edition::Edition;

static LABEL_COUNTER: AtomicU64 = AtomicU64::new(1);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct LabelId(pub u64);

impl LabelId {
    pub fn new() -> Self {
        LabelId(LABEL_COUNTER.fetch_add(1, Ordering::Relaxed))
    }

    pub fn from_raw(id: u64) -> Self {
        LabelId(id)
    }

    pub fn as_u64(&self) -> u64 {
        self.0
    }
}

impl Default for LabelId {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct Label {
    pub id: LabelId,
}

impl Label {
    pub fn new() -> Self {
        Label { id: LabelId::new() }
    }

    pub fn from_id(id: LabelId) -> Self {
        Label { id }
    }

    pub fn fake() -> Self {
        Label { id: LabelId::new() }
    }
}

impl Default for Label {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(Debug, Clone)]
pub struct LabelledCarrier {
    pub label: Option<LabelId>,
    pub carrier: Carrier,
}

impl LabelledCarrier {
    pub fn new(carrier: Carrier) -> Self {
        LabelledCarrier {
            label: None,
            carrier,
        }
    }

    pub fn labelled(label: LabelId, carrier: Carrier) -> Self {
        LabelledCarrier {
            label: Some(label),
            carrier,
        }
    }

    pub fn with_label(&self, label: LabelId) -> Self {
        LabelledCarrier {
            label: Some(label),
            carrier: self.carrier.clone(),
        }
    }

    pub fn without_label(&self) -> Self {
        LabelledCarrier {
            label: None,
            carrier: self.carrier.clone(),
        }
    }
}

#[derive(Debug, Clone)]
pub struct LabelledEdition {
    pub edition: Edition,
    pub label: Label,
}

impl LabelledEdition {
    pub fn new(edition: Edition) -> Self {
        LabelledEdition {
            edition,
            label: Label::new(),
        }
    }

    pub fn with_label(edition: Edition, label: Label) -> Self {
        LabelledEdition { edition, label }
    }

    pub fn relabelled(&self, new_label: Label) -> Self {
        LabelledEdition {
            edition: self.edition.clone(),
            label: new_label,
        }
    }

    pub fn combine(&self, other: &LabelledEdition) -> Result<LabelledEdition, super::edition::CombineConflict> {
        let combined = self.edition.combine(&other.edition)?;
        Ok(LabelledEdition {
            edition: combined,
            label: self.label.clone(),
        })
    }

    pub fn replace(&self, other: &LabelledEdition) -> LabelledEdition {
        LabelledEdition {
            edition: self.edition.replace(&other.edition),
            label: self.label.clone(),
        }
    }

    pub fn copy(&self, region: &XnRegion) -> LabelledEdition {
        LabelledEdition {
            edition: self.edition.copy(region),
            label: self.label.clone(),
        }
    }

    pub fn with(&self, position: i64, value: RangeElement, label: Option<LabelId>) -> LabelledEdition {
        let carrier = match label {
            Some(lid) => Carrier::labelled(RangeElementId::new(lid.as_u64()), value),
            None => Carrier::new(value),
        };
        LabelledEdition {
            edition: Edition::new_inner(self.edition.orgl.with(position, std::sync::Arc::new(carrier)), self.edition.endorsements.clone()),
            label: self.label.clone(),
        }
    }

    pub fn without(&self, position: i64) -> LabelledEdition {
        LabelledEdition {
            edition: self.edition.without(position),
            label: self.label.clone(),
        }
    }

    pub fn rebind(&self, position: i64, new_edition: &Edition) -> Result<LabelledEdition, RebindError> {
        let old = self.edition.fetch_owned(position).ok_or(RebindError::position_not_found(position))?;
        let old_label_id = old.label.clone();
        let new_carrier = match old_label_id {
            Some(lid) => {
                let elem = new_edition.get(position);
                Carrier::labelled(RangeElementId::new(lid.0), elem)
            }
            None => {
                let elem = new_edition.get(position);
                Carrier::new(elem)
            }
        };
        Ok(LabelledEdition {
            edition: Edition::new_inner(self.edition.orgl.with(position, std::sync::Arc::new(new_carrier)), self.edition.endorsements.clone()),
            label: self.label.clone(),
        })
    }

    pub fn positions_labelled(&self, label_id: LabelId) -> XnRegion {
        let entries = self.edition.orgl.all_entries();
        let mut region = XnRegion::empty();
        for (pos, carrier) in &entries {
            match carrier.label.as_ref() {
                Some(l) if l.0 == label_id.as_u64() => {
                    region = region.with(*pos);
                }
                _ => {}
            }
            if let Some(inner_label) = carrier.element.label_id_value() {
                if inner_label == label_id.as_u64() {
                    region = region.with(*pos);
                }
            }
        }
        region
    }

    pub fn domain(&self) -> XnRegion {
        self.edition.domain()
    }

    pub fn count(&self) -> u64 {
        self.edition.count()
    }

    pub fn is_empty(&self) -> bool {
        self.edition.is_empty()
    }

    pub fn get(&self, position: i64) -> RangeElement {
        self.edition.get(position)
    }

    pub fn fetch(&self, position: i64) -> Option<RangeElement> {
        self.edition.fetch(position)
    }

    pub fn get_carrier(&self, position: i64) -> Option<std::sync::Arc<Carrier>> {
        self.edition.carrier_at(position)
    }

    pub fn all_labelled_entries(&self) -> Vec<(i64, LabelledCarrier)> {
        self.edition
            .orgl
            .all_entries()
            .into_iter()
            .map(|(pos, arc_carrier)| {
                let label_val = match arc_carrier.label.as_ref() {
                    Some(l) => Some(LabelId::from_raw(l.0)),
                    None => None,
                };
                let lc = LabelledCarrier {
                    label: label_val,
                    carrier: (*arc_carrier).clone(),
                };
                (pos, lc)
            })
            .collect()
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RebindError {
    pub message: String,
}

impl RebindError {
    pub fn position_not_found(pos: i64) -> Self {
        RebindError {
            message: format!("position {} not found in edition", pos),
        }
    }
}

impl std::fmt::Display for RebindError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "rebind error: {}", self.message)
    }
}

impl std::error::Error for RebindError {}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ElementIdentity(u64);

impl ElementIdentity {
    pub fn new(id: u64) -> Self {
        ElementIdentity(id)
    }

    pub fn as_u64(&self) -> u64 {
        self.0
    }
}

#[derive(Debug, Clone, PartialEq)]
pub enum CanMakeIdenticalResult {
    Yes,
    DifferentType,
    DifferentContent,
    NotOwned,
}

#[derive(Debug, Clone, PartialEq)]
pub struct MakeIdenticalError {
    pub reason: String,
}

impl std::fmt::Display for MakeIdenticalError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "makeIdentical failed: {}", self.reason)
    }
}

impl std::error::Error for MakeIdenticalError {}

pub fn can_make_identical(source: &RangeElement, target: &RangeElement) -> CanMakeIdenticalResult {
    match (source, target) {
        (RangeElement::PlaceHolder { .. }, _) => CanMakeIdenticalResult::Yes,
        (_, RangeElement::PlaceHolder { .. }) => CanMakeIdenticalResult::Yes,
        (RangeElement::Text { text: a }, RangeElement::Text { text: b }) => {
            if a == b {
                CanMakeIdenticalResult::Yes
            } else {
                CanMakeIdenticalResult::DifferentContent
            }
        }
        (RangeElement::Data { bytes: a }, RangeElement::Data { bytes: b }) => {
            if a == b {
                CanMakeIdenticalResult::Yes
            } else {
                CanMakeIdenticalResult::DifferentContent
            }
        }
        (RangeElement::Edition { edition_id: a }, RangeElement::Edition { edition_id: b }) => {
            if a == b {
                CanMakeIdenticalResult::Yes
            } else {
                CanMakeIdenticalResult::DifferentContent
            }
        }
        (RangeElement::Work { work_id: a }, RangeElement::Work { work_id: b }) => {
            if a == b {
                CanMakeIdenticalResult::Yes
            } else {
                CanMakeIdenticalResult::DifferentContent
            }
        }
        (RangeElement::IDHolder { id: a }, RangeElement::IDHolder { id: b }) => {
            if a == b {
                CanMakeIdenticalResult::Yes
            } else {
                CanMakeIdenticalResult::DifferentContent
            }
        }
        (RangeElement::Label { label_id: la, inner: ia }, RangeElement::Label { label_id: lb, inner: ib }) => {
            let inner_result = can_make_identical(ia, ib);
            match inner_result {
                CanMakeIdenticalResult::Yes => {
                    if la == lb {
                        CanMakeIdenticalResult::Yes
                    } else {
                        CanMakeIdenticalResult::DifferentContent
                    }
                }
                other => other,
            }
        }
        (RangeElement::Blob { content_hash: a, .. }, RangeElement::Blob { content_hash: b, .. }) => {
            if a == b {
                CanMakeIdenticalResult::Yes
            } else {
                CanMakeIdenticalResult::DifferentContent
            }
        }
        _ => CanMakeIdenticalResult::DifferentType,
    }
}

#[derive(Debug, Clone, PartialEq)]
pub enum MakeRangeIdenticalOutcome {
    AllUnified,
    PartiallyUnified {
        failed_positions: Vec<(i64, MakeIdenticalError)>,
    },
}

#[derive(Debug, Clone)]
pub struct MakeRangeIdenticalResult {
    pub outcome: MakeRangeIdenticalOutcome,
    pub failed: Edition,
}

pub fn make_range_identical(
    source: &Edition,
    target: &Edition,
    region: Option<&XnRegion>,
) -> MakeRangeIdenticalResult {
    let source_entries = source.orgl.all_entries();
    let target_entries = target.orgl.all_entries();
    let target_map: HashMap<i64, std::sync::Arc<Carrier>> = target_entries
        .into_iter()
        .map(|(pos, c)| (pos, c))
        .collect();

    let mut failed_positions = Vec::new();
    let mut failed_entries: Vec<(i64, std::sync::Arc<Carrier>)> = Vec::new();

    for (pos, carrier) in &source_entries {
        if let Some(r) = region {
            if !r.contains(*pos) {
                continue;
            }
        }
        match target_map.get(pos) {
            None => {
                failed_positions.push((
                    *pos,
                    MakeIdenticalError {
                        reason: "no corresponding position in target".into(),
                    },
                ));
                failed_entries.push((*pos, carrier.clone()));
            }
            Some(target_carrier) => {
                let result = can_make_identical(&carrier.element, &target_carrier.element);
                match result {
                    CanMakeIdenticalResult::Yes => { /* unified — skip */ }
                    CanMakeIdenticalResult::DifferentContent => {
                        failed_positions.push((
                            *pos,
                            MakeIdenticalError {
                                reason: "different content".into(),
                            },
                        ));
                        failed_entries.push((*pos, carrier.clone()));
                    }
                    CanMakeIdenticalResult::DifferentType => {
                        failed_positions.push((
                            *pos,
                            MakeIdenticalError {
                                reason: "incompatible types".into(),
                            },
                        ));
                        failed_entries.push((*pos, carrier.clone()));
                    }
                    CanMakeIdenticalResult::NotOwned => {
                        failed_positions.push((
                            *pos,
                            MakeIdenticalError {
                                reason: "not owned".into(),
                            },
                        ));
                        failed_entries.push((*pos, carrier.clone()));
                    }
                }
            }
        }
    }

    let failed_edition = if failed_entries.is_empty() {
        Edition::empty()
    } else {
        let n = failed_entries.len();
        let min_pos = failed_entries.iter().map(|(p, _)| *p).min().unwrap_or(0);
        let max_pos = failed_entries.iter().map(|(p, _)| *p).max().unwrap_or(0);
        let region = if n > 0 {
            XnRegion::interval(min_pos, max_pos + 1)
        } else {
            XnRegion::empty()
        };
        Edition::new_inner(
            super::orgl::OrglRoot::from_bulk_entries(failed_entries, None, region),
            super::endorsement::EndorsementSet::new(),
        )
    };

    let outcome = if failed_positions.is_empty() {
        MakeRangeIdenticalOutcome::AllUnified
    } else {
        MakeRangeIdenticalOutcome::PartiallyUnified { failed_positions }
    };

    MakeRangeIdenticalResult {
        outcome,
        failed: failed_edition,
    }
}

#[derive(Debug, Clone)]
pub struct IdentityMap {
    mappings: HashMap<u64, u64>,
}

impl IdentityMap {
    pub fn new() -> Self {
        IdentityMap {
            mappings: HashMap::new(),
        }
    }

    pub fn unify(&mut self, source_id: u64, target_id: u64) {
        self.mappings.insert(source_id, target_id);
    }

    pub fn resolve(&self, id: u64) -> u64 {
        let mut current = id;
        let mut seen = std::collections::HashSet::new();
        while let Some(&target) = self.mappings.get(&current) {
            if !seen.insert(current) {
                break;
            }
            current = target;
        }
        current
    }

    pub fn is_unified(&self, a: u64, b: u64) -> bool {
        self.resolve(a) == self.resolve(b)
    }

    pub fn mapping_count(&self) -> usize {
        self.mappings.len()
    }
}

impl Default for IdentityMap {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn label_id_unique() {
        let a = LabelId::new();
        let b = LabelId::new();
        assert_ne!(a, b);
    }

    #[test]
    fn label_new_unique() {
        let a = Label::new();
        let b = Label::new();
        assert_ne!(a.id, b.id);
    }

    #[test]
    fn labelled_carrier_with_label() {
        let lc = LabelledCarrier::labelled(LabelId::from_raw(42), Carrier::new(RangeElement::text("x")));
        assert_eq!(lc.label, Some(LabelId::from_raw(42)));
    }

    #[test]
    fn labelled_carrier_without_label() {
        let lc = LabelledCarrier::new(Carrier::new(RangeElement::text("x")));
        assert!(lc.label.is_none());
    }

    #[test]
    fn labelled_carrier_with_label_method() {
        let lc = LabelledCarrier::new(Carrier::new(RangeElement::text("x")));
        let relabelled = lc.with_label(LabelId::from_raw(7));
        assert_eq!(relabelled.label, Some(LabelId::from_raw(7)));
    }

    #[test]
    fn labelled_edition_new_gets_label() {
        let e = Edition::from_text("hello");
        let le = LabelledEdition::new(e);
        assert_ne!(le.label.id.as_u64(), 0);
    }

    #[test]
    fn labelled_edition_relabelled() {
        let e = Edition::from_text("hello");
        let le = LabelledEdition::new(e);
        let new_label = Label::from_id(LabelId::from_raw(999));
        let relabelled = le.relabelled(new_label.clone());
        assert_eq!(relabelled.label.id, LabelId::from_raw(999));
        assert_eq!(relabelled.edition.count(), 5);
    }

    #[test]
    fn labelled_edition_combine() {
        let a = LabelledEdition::new(Edition::from_one(0, RangeElement::text("a")));
        let b = LabelledEdition::new(Edition::from_one(1, RangeElement::text("b")));
        let c = a.combine(&b).unwrap();
        assert_eq!(c.edition.count(), 2);
        assert_eq!(c.label.id, a.label.id);
    }

    #[test]
    fn labelled_edition_replace() {
        let original = LabelledEdition::new(Edition::from_text("abc"));
        let replacement = LabelledEdition::new(Edition::from_one(1, RangeElement::text("X")));
        let result = original.replace(&replacement);
        assert_eq!(result.edition.to_text(), "aXc");
        assert_eq!(result.label.id, original.label.id);
    }

    #[test]
    fn labelled_edition_copy() {
        let le = LabelledEdition::new(Edition::from_text("abcde"));
        let sub = le.copy(&XnRegion::interval(1, 4));
        assert_eq!(sub.edition.count(), 3);
        assert_eq!(sub.label.id, le.label.id);
    }

    #[test]
    fn labelled_edition_with_labelled_position() {
        let le = LabelledEdition::new(Edition::empty());
        let label = LabelId::from_raw(42);
        let with_pos = le.with(0, RangeElement::text("x"), Some(label));
        let carrier = with_pos.get_carrier(0).unwrap();
        assert_eq!(carrier.label, Some(RangeElementId::new(42)));
    }

    #[test]
    fn labelled_edition_with_unlabelled_position() {
        let le = LabelledEdition::new(Edition::empty());
        let with_pos = le.with(0, RangeElement::text("x"), None);
        let carrier = with_pos.get_carrier(0).unwrap();
        assert!(carrier.label.is_none());
    }

    #[test]
    fn labelled_edition_without() {
        let le = LabelledEdition::new(Edition::from_text("abc"));
        let without = le.without(1);
        assert_eq!(without.edition.count(), 2);
        assert_eq!(without.label.id, le.label.id);
    }

    #[test]
    fn labelled_edition_rebind() {
        let le = LabelledEdition::new(Edition::from_text("abc"));
        let new_edition = Edition::from_text("XYZ");
        let rebound = le.rebind(1, &new_edition).unwrap();
        assert_eq!(rebound.edition.get(1).as_text(), Some("Y"));
    }

    #[test]
    fn labelled_edition_rebind_preserves_label() {
        let le = LabelledEdition::new(Edition::empty())
            .with(0, RangeElement::text("old"), Some(LabelId::from_raw(10)));
        let new_edition = Edition::from_text("new");
        let rebound = le.rebind(0, &new_edition).unwrap();
        let carrier = rebound.get_carrier(0).unwrap();
        assert_eq!(carrier.label, Some(RangeElementId::new(10)));
    }

    #[test]
    fn labelled_edition_rebind_missing_position() {
        let le = LabelledEdition::new(Edition::from_text("abc"));
        let new_edition = Edition::from_text("XYZ");
        let result = le.rebind(99, &new_edition);
        assert!(result.is_err());
    }

    #[test]
    fn labelled_edition_positions_labelled() {
        let le = LabelledEdition::new(Edition::empty())
            .with(0, RangeElement::text("a"), Some(LabelId::from_raw(1)))
            .with(1, RangeElement::text("b"), None)
            .with(2, RangeElement::text("c"), Some(LabelId::from_raw(1)));
        let region = le.positions_labelled(LabelId::from_raw(1));
        assert!(region.contains(0));
        assert!(!region.contains(1));
        assert!(region.contains(2));
    }

    #[test]
    fn labelled_edition_all_labelled_entries() {
        let le = LabelledEdition::new(Edition::empty())
            .with(0, RangeElement::text("a"), Some(LabelId::from_raw(5)))
            .with(1, RangeElement::text("b"), None);
        let entries = le.all_labelled_entries();
        assert_eq!(entries.len(), 2);
        assert_eq!(entries[0].1.label, Some(LabelId::from_raw(5)));
        assert!(entries[1].1.label.is_none());
    }

    #[test]
    fn can_make_identical_placeholder_to_anything() {
        let ph = RangeElement::placeholder(1);
        let text = RangeElement::text("hello");
        assert_eq!(can_make_identical(&ph, &text), CanMakeIdenticalResult::Yes);
        assert_eq!(can_make_identical(&text, &ph), CanMakeIdenticalResult::Yes);
    }

    #[test]
    fn can_make_identical_same_text() {
        let a = RangeElement::text("hello");
        let b = RangeElement::text("hello");
        assert_eq!(can_make_identical(&a, &b), CanMakeIdenticalResult::Yes);
    }

    #[test]
    fn can_make_identical_different_text() {
        let a = RangeElement::text("hello");
        let b = RangeElement::text("world");
        assert_eq!(can_make_identical(&a, &b), CanMakeIdenticalResult::DifferentContent);
    }

    #[test]
    fn can_make_identical_same_data() {
        let a = RangeElement::data(vec![1, 2, 3]);
        let b = RangeElement::data(vec![1, 2, 3]);
        assert_eq!(can_make_identical(&a, &b), CanMakeIdenticalResult::Yes);
    }

    #[test]
    fn can_make_identical_different_data() {
        let a = RangeElement::data(vec![1, 2, 3]);
        let b = RangeElement::data(vec![4, 5, 6]);
        assert_eq!(can_make_identical(&a, &b), CanMakeIdenticalResult::DifferentContent);
    }

    #[test]
    fn can_make_identical_text_vs_data() {
        let a = RangeElement::text("hello");
        let b = RangeElement::data(b"hello".to_vec());
        assert_eq!(can_make_identical(&a, &b), CanMakeIdenticalResult::DifferentType);
    }

    #[test]
    fn can_make_identical_same_edition() {
        let a = RangeElement::edition(42);
        let b = RangeElement::edition(42);
        assert_eq!(can_make_identical(&a, &b), CanMakeIdenticalResult::Yes);
    }

    #[test]
    fn can_make_identical_different_edition() {
        let a = RangeElement::edition(42);
        let b = RangeElement::edition(99);
        assert_eq!(can_make_identical(&a, &b), CanMakeIdenticalResult::DifferentContent);
    }

    #[test]
    fn can_make_identical_same_work() {
        let a = RangeElement::work(10);
        let b = RangeElement::work(10);
        assert_eq!(can_make_identical(&a, &b), CanMakeIdenticalResult::Yes);
    }

    #[test]
    fn can_make_identical_same_blob() {
        let a = RangeElement::blob(0xabcd, "image/png", 100);
        let b = RangeElement::blob(0xabcd, "image/jpeg", 200);
        assert_eq!(can_make_identical(&a, &b), CanMakeIdenticalResult::Yes);
    }

    #[test]
    fn can_make_identical_different_blob() {
        let a = RangeElement::blob(0xabcd, "image/png", 100);
        let b = RangeElement::blob(0x1234, "image/png", 100);
        assert_eq!(can_make_identical(&a, &b), CanMakeIdenticalResult::DifferentContent);
    }

    #[test]
    fn can_make_identical_same_id_holder() {
        let a = RangeElement::id_holder(42);
        let b = RangeElement::id_holder(42);
        assert_eq!(can_make_identical(&a, &b), CanMakeIdenticalResult::Yes);
    }

    #[test]
    fn can_make_identical_different_types() {
        let a = RangeElement::text("hello");
        let b = RangeElement::edition(1);
        assert_eq!(can_make_identical(&a, &b), CanMakeIdenticalResult::DifferentType);
    }

    #[test]
    fn make_range_identical_all_match() {
        let source = Edition::from_text("abc");
        let target = Edition::from_text("abc");
        let result = make_range_identical(&source, &target, None);
        assert_eq!(result.outcome, MakeRangeIdenticalOutcome::AllUnified);
        assert!(result.failed.is_empty());
    }

    #[test]
    fn make_range_identical_partial_mismatch() {
        let source = Edition::from_text("abc");
        let target = Edition::empty()
            .with(0, RangeElement::text("a"))
            .with(1, RangeElement::text("X"))
            .with(2, RangeElement::text("c"));
        let result = make_range_identical(&source, &target, None);
        match result.outcome {
            MakeRangeIdenticalOutcome::PartiallyUnified { failed_positions } => {
                assert_eq!(failed_positions.len(), 1);
                assert_eq!(failed_positions[0].0, 1);
            }
            _ => panic!("expected partial unification"),
        }
        assert_eq!(result.failed.count(), 1);
    }

    #[test]
    fn make_range_identical_with_region() {
        let source = Edition::from_text("abc");
        let target = Edition::from_text("aXc");
        let region = XnRegion::interval(0, 1);
        let result = make_range_identical(&source, &target, Some(&region));
        assert_eq!(result.outcome, MakeRangeIdenticalOutcome::AllUnified);
    }

    #[test]
    fn make_range_identical_missing_positions() {
        let source = Edition::from_text("abc");
        let target = Edition::from_text("ab");
        let result = make_range_identical(&source, &target, None);
        match result.outcome {
            MakeRangeIdenticalOutcome::PartiallyUnified { failed_positions } => {
                assert!(failed_positions.iter().any(|(p, _)| *p == 2));
            }
            _ => panic!("expected partial unification"),
        }
    }

    #[test]
    fn make_range_identical_placeholder_to_text() {
        let source = Edition::from_one(0, RangeElement::placeholder(1));
        let target = Edition::from_one(0, RangeElement::text("hello"));
        let result = make_range_identical(&source, &target, None);
        assert_eq!(result.outcome, MakeRangeIdenticalOutcome::AllUnified);
    }

    #[test]
    fn make_range_identical_different_types() {
        let source = Edition::from_one(0, RangeElement::text("hello"));
        let target = Edition::from_one(0, RangeElement::edition(1));
        let result = make_range_identical(&source, &target, None);
        match result.outcome {
            MakeRangeIdenticalOutcome::PartiallyUnified { failed_positions } => {
                assert_eq!(failed_positions.len(), 1);
                assert_eq!(failed_positions[0].0, 0);
            }
            _ => panic!("expected partial unification"),
        }
    }

    #[test]
    fn identity_map_basic() {
        let mut map = IdentityMap::new();
        map.unify(1, 2);
        assert!(map.is_unified(1, 2));
        assert!(!map.is_unified(1, 3));
    }

    #[test]
    fn identity_map_transitive() {
        let mut map = IdentityMap::new();
        map.unify(1, 2);
        map.unify(2, 3);
        assert!(map.is_unified(1, 3));
    }

    #[test]
    fn identity_map_resolve() {
        let mut map = IdentityMap::new();
        map.unify(10, 20);
        assert_eq!(map.resolve(10), 20);
        assert_eq!(map.resolve(20), 20);
    }

    #[test]
    fn identity_map_resolve_transitive() {
        let mut map = IdentityMap::new();
        map.unify(1, 2);
        map.unify(2, 3);
        map.unify(3, 4);
        assert_eq!(map.resolve(1), 4);
        assert_eq!(map.resolve(2), 4);
    }

    #[test]
    fn identity_map_no_mapping() {
        let map = IdentityMap::new();
        assert_eq!(map.resolve(42), 42);
    }

    #[test]
    fn identity_map_mapping_count() {
        let mut map = IdentityMap::new();
        assert_eq!(map.mapping_count(), 0);
        map.unify(1, 2);
        assert_eq!(map.mapping_count(), 1);
        map.unify(3, 4);
        assert_eq!(map.mapping_count(), 2);
    }

    #[test]
    fn identity_map_overwrite() {
        let mut map = IdentityMap::new();
        map.unify(1, 2);
        map.unify(1, 3);
        assert_eq!(map.resolve(1), 3);
    }

    #[test]
    fn make_range_identical_empty_editions() {
        let source = Edition::empty();
        let target = Edition::empty();
        let result = make_range_identical(&source, &target, None);
        assert_eq!(result.outcome, MakeRangeIdenticalOutcome::AllUnified);
    }

    #[test]
    fn labelled_edition_domain_and_count() {
        let le = LabelledEdition::new(Edition::from_text("hello"));
        assert_eq!(le.count(), 5);
        assert!(!le.domain().is_empty());
        assert!(!le.is_empty());
    }

    #[test]
    fn labelled_edition_get_and_fetch() {
        let le = LabelledEdition::new(Edition::from_text("abc"));
        assert_eq!(le.get(1).as_text(), Some("b"));
        assert_eq!(le.fetch(1).unwrap().as_text(), Some("b"));
        assert!(le.fetch(99).is_none());
    }

    #[test]
    fn can_make_identical_label_same_inner_same_label() {
        let a = RangeElement::label(1, RangeElement::text("x"));
        let b = RangeElement::label(1, RangeElement::text("x"));
        assert_eq!(can_make_identical(&a, &b), CanMakeIdenticalResult::Yes);
    }

    #[test]
    fn can_make_identical_label_different_label() {
        let a = RangeElement::label(1, RangeElement::text("x"));
        let b = RangeElement::label(2, RangeElement::text("x"));
        assert_eq!(can_make_identical(&a, &b), CanMakeIdenticalResult::DifferentContent);
    }

    #[test]
    fn can_make_identical_label_different_inner() {
        let a = RangeElement::label(1, RangeElement::text("x"));
        let b = RangeElement::label(1, RangeElement::text("y"));
        assert_eq!(can_make_identical(&a, &b), CanMakeIdenticalResult::DifferentContent);
    }
}
