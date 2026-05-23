use std::collections::HashMap;
use std::sync::Arc;

use super::edition::Edition;
use super::endorsement::{Endorsement, EndorsementSet};
use super::range_element::RangeElement;
use super::xn_region::XnRegion;

pub const WRAPPER_CLUB_ID: u64 = 1;

pub const TEXT_TOKEN: u64 = 1;
pub const SET_TOKEN: u64 = 2;
pub const PATH_TOKEN: u64 = 3;
pub const HYPERLINK_TOKEN: u64 = 4;
pub const HYPERREF_TOKEN: u64 = 5;

pub fn text_endorsement() -> Endorsement {
    Endorsement::new(WRAPPER_CLUB_ID, TEXT_TOKEN)
}

pub fn set_endorsement() -> Endorsement {
    Endorsement::new(WRAPPER_CLUB_ID, SET_TOKEN)
}

pub fn path_endorsement() -> Endorsement {
    Endorsement::new(WRAPPER_CLUB_ID, PATH_TOKEN)
}

pub fn hyperlink_endorsement() -> Endorsement {
    Endorsement::new(WRAPPER_CLUB_ID, HYPERLINK_TOKEN)
}

pub fn hyperref_endorsement() -> Endorsement {
    Endorsement::new(WRAPPER_CLUB_ID, HYPERREF_TOKEN)
}

#[derive(Debug, Clone)]
pub struct WrapperSpec {
    name: String,
    parent_name: Option<String>,
    token_id: u64,
    check_fn: fn(&Edition) -> bool,
}

impl WrapperSpec {
    pub fn new(
        name: &str,
        parent_name: Option<&str>,
        token_id: u64,
        check_fn: fn(&Edition) -> bool,
    ) -> Self {
        WrapperSpec {
            name: name.to_string(),
            parent_name: parent_name.map(|s| s.to_string()),
            token_id,
            check_fn,
        }
    }

    pub fn name(&self) -> &str {
        &self.name
    }

    pub fn token_id(&self) -> u64 {
        self.token_id
    }

    pub fn endorsement(&self) -> Endorsement {
        Endorsement::new(WRAPPER_CLUB_ID, self.token_id)
    }

    pub fn check(&self, edition: &Edition) -> bool {
        (self.check_fn)(edition)
    }

    pub fn certify(&self, endorsements: &mut EndorsementSet) -> bool {
        *endorsements = endorsements.with(self.endorsement());
        true
    }

    pub fn is_certified(&self, endorsements: &EndorsementSet) -> bool {
        endorsements.contains(&self.endorsement())
    }
}

#[derive(Debug, Clone, Default)]
pub struct WrapperRegistry {
    specs: HashMap<String, WrapperSpec>,
}

impl WrapperRegistry {
    pub fn new() -> Self {
        let mut registry = WrapperRegistry {
            specs: HashMap::new(),
        };
        registry.register(WrapperSpec::new("Text", None, TEXT_TOKEN, check_text));
        registry.register(WrapperSpec::new("Set", None, SET_TOKEN, check_set));
        registry.register(WrapperSpec::new("Path", None, PATH_TOKEN, check_path));
        registry.register(WrapperSpec::new(
            "HyperLink",
            None,
            HYPERLINK_TOKEN,
            check_hyperlink,
        ));
        registry.register(WrapperSpec::new(
            "HyperRef",
            None,
            HYPERREF_TOKEN,
            check_hyperref,
        ));
        registry
    }

    pub fn register(&mut self, spec: WrapperSpec) {
        self.specs.insert(spec.name.clone(), spec);
    }

    pub fn get(&self, name: &str) -> Option<&WrapperSpec> {
        self.specs.get(name)
    }

    pub fn spec_for_token(&self, token_id: u64) -> Option<&WrapperSpec> {
        self.specs.values().find(|s| s.token_id == token_id)
    }

    pub fn certify_as(
        &self,
        edition: &Edition,
        endorsements: &mut EndorsementSet,
        type_name: &str,
    ) -> bool {
        if let Some(spec) = self.specs.get(type_name) {
            if spec.check(edition) {
                spec.certify(endorsements);
                return true;
            }
        }
        false
    }
    pub fn check_certifications(&self, endorsements: &EndorsementSet) -> Vec<String> {
        let mut result = Vec::new();
        for (name, spec) in &self.specs {
            if spec.is_certified(endorsements) {
                result.push(name.clone());
            }
        }
        result
    }

    pub fn all_specs(&self) -> impl Iterator<Item = &WrapperSpec> {
        self.specs.values()
    }
}

pub fn check_text(edition: &Edition) -> bool {
    if edition.is_empty() {
        return true;
    }
    let domain = edition.domain();
    if !domain.is_simple() {
        return false;
    }
    if let Some((start, _)) = domain.as_interval() {
        return start == 0;
    }
    false
}

pub fn check_set(edition: &Edition) -> bool {
    edition.is_finite()
}

pub fn check_path(edition: &Edition) -> bool {
    if edition.is_empty() {
        return true;
    }
    let domain = edition.domain();
    if !domain.is_simple() {
        return false;
    }
    if let Some((start, _)) = domain.as_interval() {
        if start != 0 {
            return false;
        }
    }
    for (_pos, carrier) in edition.all_entries() {
        match &carrier.element {
            RangeElement::Label { .. } => {}
            _ => return false,
        }
    }
    true
}

pub fn check_hyperlink(edition: &Edition) -> bool {
    !edition.is_empty()
}

pub fn check_hyperref(_edition: &Edition) -> bool {
    true
}

pub struct FeSet {
    edition: Edition,
}

impl FeSet {
    pub fn new(edition: Edition) -> Result<Self, FeSetError> {
        if !edition.is_finite() {
            return Err(FeSetError::NotFinite);
        }
        Ok(FeSet { edition })
    }

    pub fn empty() -> Self {
        FeSet {
            edition: Edition::empty(),
        }
    }

    pub fn from_elements(elements: &[RangeElement]) -> Self {
        let edition = Edition::from_text_elements(elements);
        FeSet { edition }
    }

    pub fn count(&self) -> u64 {
        self.edition.count()
    }

    pub fn is_empty(&self) -> bool {
        self.edition.is_empty()
    }

    pub fn edition(&self) -> &Edition {
        &self.edition
    }

    pub fn into_edition(self) -> Edition {
        self.edition
    }

    pub fn includes(&self, value: &RangeElement) -> bool {
        !self.edition.positions_of(value).is_empty()
    }

    pub fn intersect(&self, other: &FeSet) -> FeSet {
        let mut result_elements = Vec::new();
        for (_, carrier) in self.edition.all_entries() {
            if !other.edition.positions_of(&carrier.element).is_empty() {
                result_elements.push(carrier.element.clone());
            }
        }
        FeSet::from_elements(&result_elements)
    }

    pub fn minus(&self, other: &FeSet) -> FeSet {
        let mut result_elements = Vec::new();
        for (_, carrier) in self.edition.all_entries() {
            if other.edition.positions_of(&carrier.element).is_empty() {
                result_elements.push(carrier.element.clone());
            }
        }
        FeSet::from_elements(&result_elements)
    }

    pub fn union_with(&self, other: &FeSet) -> FeSet {
        let mut result_elements = Vec::new();
        for (_, carrier) in self.edition.all_entries() {
            result_elements.push(carrier.element.clone());
        }
        for (_, carrier) in other.edition.all_entries() {
            if self.edition.positions_of(&carrier.element).is_empty() {
                result_elements.push(carrier.element.clone());
            }
        }
        FeSet::from_elements(&result_elements)
    }

    pub fn with(&self, value: RangeElement) -> FeSet {
        if self.includes(&value) {
            return self.clone();
        }
        let pos = self.count() as i64;
        FeSet {
            edition: self.edition.with(pos, value),
        }
    }

    pub fn without(&self, value: &RangeElement) -> FeSet {
        let positions = self.edition.positions_of(value);
        if positions.is_empty() {
            return self.clone();
        }
        let keep = self.edition.domain().minus(&positions);
        FeSet {
            edition: self.edition.copy(&keep),
        }
    }

    pub fn elements(&self) -> Vec<RangeElement> {
        self.edition
            .all_entries()
            .into_iter()
            .map(|(_, c)| c.element.clone())
            .collect()
    }
}

impl Clone for FeSet {
    fn clone(&self) -> Self {
        FeSet {
            edition: self.edition.clone(),
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub enum FeSetError {
    NotFinite,
}

impl std::fmt::Display for FeSetError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            FeSetError::NotFinite => write!(f, "set edition must be finite"),
        }
    }
}

impl std::error::Error for FeSetError {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn registry_has_builtin_types() {
        let registry = WrapperRegistry::new();
        assert!(registry.get("Text").is_some());
        assert!(registry.get("Set").is_some());
        assert!(registry.get("Path").is_some());
        assert!(registry.get("HyperLink").is_some());
        assert!(registry.get("HyperRef").is_some());
    }

    #[test]
    fn text_check_validates_contiguous_zero_based() {
        let edition = Edition::from_text("hello");
        assert!(check_text(&edition));

        let shifted = Edition::from_text("hello").transformed_by(5);
        assert!(!check_text(&shifted));

        assert!(check_text(&Edition::empty()));
    }

    #[test]
    fn set_check_requires_finite() {
        let edition = Edition::from_text("abc");
        assert!(check_set(&edition));

        let infinite = Edition::from_all(&XnRegion::above(0), RangeElement::text("x"));
        assert!(!check_set(&infinite));
    }

    #[test]
    fn path_check_validates_labels() {
        let edition = Edition::from_text_elements(&[
            RangeElement::label(1, RangeElement::text("a")),
            RangeElement::label(2, RangeElement::text("b")),
        ]);
        assert!(check_path(&edition));

        let text_edition = Edition::from_text("not labels");
        assert!(!check_path(&text_edition));
    }

    #[test]
    fn certify_stamps_endorsement() {
        let registry = WrapperRegistry::new();
        let edition = Edition::from_text("hello");
        let mut endorsements = EndorsementSet::new();
        assert!(registry.certify_as(&edition, &mut endorsements, "Text"));
        let spec = registry.get("Text").unwrap();
        assert!(spec.is_certified(&endorsements));
    }

    #[test]
    fn certify_rejects_invalid() {
        let registry = WrapperRegistry::new();
        let edition = Edition::from_text("hello").transformed_by(5);
        let mut endorsements = EndorsementSet::new();
        assert!(!registry.certify_as(&edition, &mut endorsements, "Text"));
    }

    #[test]
    fn check_certifications_lists_types() {
        let registry = WrapperRegistry::new();
        let mut endorsements = EndorsementSet::new();
        endorsements = endorsements.with(text_endorsement());
        endorsements = endorsements.with(set_endorsement());
        let certs = registry.check_certifications(&endorsements);
        assert!(certs.contains(&"Text".to_string()));
        assert!(certs.contains(&"Set".to_string()));
    }

    #[test]
    fn feset_empty() {
        let set = FeSet::empty();
        assert!(set.is_empty());
        assert_eq!(set.count(), 0);
    }

    #[test]
    fn feset_from_elements() {
        let set = FeSet::from_elements(&[
            RangeElement::text("a"),
            RangeElement::text("b"),
            RangeElement::text("c"),
        ]);
        assert_eq!(set.count(), 3);
        assert!(set.includes(&RangeElement::text("a")));
        assert!(!set.includes(&RangeElement::text("d")));
    }

    #[test]
    fn feset_with_adds_element() {
        let set = FeSet::from_elements(&[RangeElement::text("a")]);
        let set2 = set.with(RangeElement::text("b"));
        assert_eq!(set2.count(), 2);
        assert!(set2.includes(&RangeElement::text("b")));
    }

    #[test]
    fn feset_with_duplicate_is_noop() {
        let set = FeSet::from_elements(&[RangeElement::text("a")]);
        let set2 = set.with(RangeElement::text("a"));
        assert_eq!(set2.count(), 1);
    }

    #[test]
    fn feset_without_removes_element() {
        let set = FeSet::from_elements(&[
            RangeElement::text("a"),
            RangeElement::text("b"),
            RangeElement::text("c"),
        ]);
        let set2 = set.without(&RangeElement::text("b"));
        assert_eq!(set2.count(), 2);
        assert!(set2.includes(&RangeElement::text("a")));
        assert!(!set2.includes(&RangeElement::text("b")));
    }

    #[test]
    fn feset_intersect() {
        let a = FeSet::from_elements(&[
            RangeElement::text("a"),
            RangeElement::text("b"),
            RangeElement::text("c"),
        ]);
        let b = FeSet::from_elements(&[
            RangeElement::text("b"),
            RangeElement::text("c"),
            RangeElement::text("d"),
        ]);
        let result = a.intersect(&b);
        assert_eq!(result.count(), 2);
        assert!(result.includes(&RangeElement::text("b")));
        assert!(result.includes(&RangeElement::text("c")));
    }

    #[test]
    fn feset_minus() {
        let a = FeSet::from_elements(&[
            RangeElement::text("a"),
            RangeElement::text("b"),
            RangeElement::text("c"),
        ]);
        let b = FeSet::from_elements(&[RangeElement::text("b")]);
        let result = a.minus(&b);
        assert_eq!(result.count(), 2);
        assert!(result.includes(&RangeElement::text("a")));
        assert!(!result.includes(&RangeElement::text("b")));
    }

    #[test]
    fn feset_union() {
        let a = FeSet::from_elements(&[RangeElement::text("a"), RangeElement::text("b")]);
        let b = FeSet::from_elements(&[RangeElement::text("b"), RangeElement::text("c")]);
        let result = a.union_with(&b);
        assert_eq!(result.count(), 3);
        assert!(result.includes(&RangeElement::text("a")));
        assert!(result.includes(&RangeElement::text("b")));
        assert!(result.includes(&RangeElement::text("c")));
    }

    #[test]
    fn feset_elements() {
        let set = FeSet::from_elements(&[RangeElement::text("x"), RangeElement::text("y")]);
        let elems = set.elements();
        assert_eq!(elems.len(), 2);
    }

    #[test]
    fn wrapper_spec_endorsement_roundtrip() {
        let spec = WrapperSpec::new("Text", None, TEXT_TOKEN, check_text);
        let endorsement = spec.endorsement();
        assert_eq!(endorsement.club_id(), WRAPPER_CLUB_ID);
        assert_eq!(endorsement.token_id(), TEXT_TOKEN);

        let set = EndorsementSet::new().with(endorsement);
        assert!(spec.is_certified(&set));
    }

    #[test]
    fn path_check_empty() {
        assert!(check_path(&Edition::empty()));
    }

    #[test]
    fn path_check_shifted_fails() {
        let edition =
            Edition::from_text_elements(&[RangeElement::label(1, RangeElement::text("a"))])
                .transformed_by(5);
        assert!(!check_path(&edition));
    }

    #[test]
    fn hyperlink_and_hyperref_checks() {
        let edition = Edition::from_text("something");
        assert!(check_hyperlink(&edition));
        assert!(check_hyperref(&edition));
        assert!(!check_hyperlink(&Edition::empty()));
    }

    #[test]
    fn registry_spec_for_token() {
        let registry = WrapperRegistry::new();
        let spec = registry.spec_for_token(TEXT_TOKEN).unwrap();
        assert_eq!(spec.name(), "Text");
    }
}
