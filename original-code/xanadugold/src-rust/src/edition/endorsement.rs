use std::collections::BTreeSet;

use super::grandmap::Id;

#[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct Endorsement {
    club_id: u64,
    token_id: u64,
}

impl Endorsement {
    pub fn new(club_id: u64, token_id: u64) -> Self {
        Endorsement { club_id, token_id }
    }

    pub fn club_id(&self) -> u64 {
        self.club_id
    }

    pub fn token_id(&self) -> u64 {
        self.token_id
    }
}

impl std::fmt::Display for Endorsement {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "({},{})", self.club_id, self.token_id)
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct EndorsementSet {
    endorsements: BTreeSet<Endorsement>,
}

impl EndorsementSet {
    pub fn new() -> Self {
        EndorsementSet {
            endorsements: BTreeSet::new(),
        }
    }

    pub fn from_endorsements(endorsements: Vec<Endorsement>) -> Self {
        EndorsementSet {
            endorsements: endorsements.into_iter().collect(),
        }
    }

    pub fn single(club_id: u64, token_id: u64) -> Self {
        EndorsementSet {
            endorsements: BTreeSet::from([Endorsement::new(club_id, token_id)]),
        }
    }

    pub fn is_empty(&self) -> bool {
        self.endorsements.is_empty()
    }

    pub fn len(&self) -> usize {
        self.endorsements.len()
    }

    pub fn contains(&self, endorsement: &Endorsement) -> bool {
        self.endorsements.contains(endorsement)
    }

    pub fn contains_pair(&self, club_id: u64, token_id: u64) -> bool {
        self.endorsements.contains(&Endorsement::new(club_id, token_id))
    }

    pub fn iter(&self) -> impl Iterator<Item = &Endorsement> {
        self.endorsements.iter()
    }

    pub fn endorsements(&self) -> &BTreeSet<Endorsement> {
        &self.endorsements
    }

    pub fn to_vec(&self) -> Vec<Endorsement> {
        self.endorsements.iter().cloned().collect()
    }

    pub fn with(&self, endorsement: Endorsement) -> Self {
        let mut new_set = self.endorsements.clone();
        new_set.insert(endorsement);
        EndorsementSet {
            endorsements: new_set,
        }
    }

    pub fn with_all(&self, other: &EndorsementSet) -> Self {
        let mut new_set = self.endorsements.clone();
        for e in &other.endorsements {
            new_set.insert(e.clone());
        }
        EndorsementSet {
            endorsements: new_set,
        }
    }

    pub fn without(&self, endorsement: &Endorsement) -> Self {
        let mut new_set = self.endorsements.clone();
        new_set.remove(endorsement);
        EndorsementSet {
            endorsements: new_set,
        }
    }

    pub fn without_all(&self, other: &EndorsementSet) -> Self {
        let mut new_set = self.endorsements.clone();
        for e in &other.endorsements {
            new_set.remove(e);
        }
        EndorsementSet {
            endorsements: new_set,
        }
    }

    pub fn union(&self, other: &EndorsementSet) -> EndorsementSet {
        EndorsementSet {
            endorsements: self.endorsements.union(&other.endorsements).cloned().collect(),
        }
    }

    pub fn intersect(&self, other: &EndorsementSet) -> EndorsementSet {
        EndorsementSet {
            endorsements: self.endorsements.intersection(&other.endorsements).cloned().collect(),
        }
    }

    pub fn difference(&self, other: &EndorsementSet) -> EndorsementSet {
        EndorsementSet {
            endorsements: self.endorsements.difference(&other.endorsements).cloned().collect(),
        }
    }

    pub fn is_subset_of(&self, other: &EndorsementSet) -> bool {
        self.endorsements.is_subset(&other.endorsements)
    }

    pub fn matches_filter(&self, filter: &EndorsementFilter) -> bool {
        match filter {
            EndorsementFilter::Any => true,
            EndorsementFilter::None => false,
            EndorsementFilter::Exact(required) => required.iter().all(|e| self.contains(e)),
            EndorsementFilter::AnyOf(candidates) => candidates.iter().any(|e| self.contains(e)),
            EndorsementFilter::AllOf(required) => required.iter().all(|e| self.contains(e)),
            EndorsementFilter::ClubFilter(club_id) => {
                self.endorsements.iter().any(|e| e.club_id == *club_id)
            }
            EndorsementFilter::Not(negated) => !self.matches_filter(negated),
            EndorsementFilter::And(filters) => filters.iter().all(|f| self.matches_filter(f)),
            EndorsementFilter::Or(filters) => filters.iter().any(|f| self.matches_filter(f)),
        }
    }

    pub fn club_ids(&self) -> BTreeSet<u64> {
        self.endorsements.iter().map(|e| e.club_id).collect()
    }

    pub fn tokens_for_club(&self, club_id: u64) -> BTreeSet<u64> {
        self.endorsements
            .iter()
            .filter(|e| e.club_id == club_id)
            .map(|e| e.token_id)
            .collect()
    }
}

impl Default for EndorsementSet {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(Debug, Clone, PartialEq)]
pub enum EndorsementFilter {
    Any,
    None,
    Exact(EndorsementSet),
    AnyOf(EndorsementSet),
    AllOf(EndorsementSet),
    ClubFilter(u64),
    Not(Box<EndorsementFilter>),
    And(Vec<EndorsementFilter>),
    Or(Vec<EndorsementFilter>),
}

impl EndorsementFilter {
    pub fn any() -> Self {
        EndorsementFilter::Any
    }

    pub fn none() -> Self {
        EndorsementFilter::None
    }

    pub fn exact(set: EndorsementSet) -> Self {
        EndorsementFilter::Exact(set)
    }

    pub fn any_of(set: EndorsementSet) -> Self {
        EndorsementFilter::AnyOf(set)
    }

    pub fn all_of(set: EndorsementSet) -> Self {
        EndorsementFilter::AllOf(set)
    }

    pub fn club(club_id: u64) -> Self {
        EndorsementFilter::ClubFilter(club_id)
    }

    pub fn not(filter: EndorsementFilter) -> Self {
        EndorsementFilter::Not(Box::new(filter))
    }

    pub fn and(filters: Vec<EndorsementFilter>) -> Self {
        EndorsementFilter::And(filters)
    }

    pub fn or(filters: Vec<EndorsementFilter>) -> Self {
        EndorsementFilter::Or(filters)
    }

    pub fn matches(&self, set: &EndorsementSet) -> bool {
        set.matches_filter(self)
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct Endorseable {
    endorsements: EndorsementSet,
}

impl Endorseable {
    pub fn new() -> Self {
        Endorseable {
            endorsements: EndorsementSet::new(),
        }
    }

    pub fn with_endorsements(endorsements: EndorsementSet) -> Self {
        Endorseable { endorsements }
    }

    pub fn endorsements(&self) -> &EndorsementSet {
        &self.endorsements
    }

    pub fn endorse(&mut self, additional: &EndorsementSet) {
        self.endorsements = self.endorsements.with_all(additional);
    }

    pub fn endorse_one(&mut self, club_id: u64, token_id: u64) {
        self.endorsements = self
            .endorsements
            .with(Endorsement::new(club_id, token_id));
    }

    pub fn retract(&mut self, to_remove: &EndorsementSet) {
        self.endorsements = self.endorsements.without_all(to_remove);
    }

    pub fn retract_one(&mut self, club_id: u64, token_id: u64) {
        self.endorsements = self
            .endorsements
            .without(&Endorsement::new(club_id, token_id));
    }

    pub fn is_endorsed_by(&self, club_id: u64, token_id: u64) -> bool {
        self.endorsements.contains_pair(club_id, token_id)
    }

    pub fn has_club_endorsement(&self, club_id: u64) -> bool {
        self.endorsements
            .iter()
            .any(|e| e.club_id == club_id)
    }

    pub fn matches_filter(&self, filter: &EndorsementFilter) -> bool {
        self.endorsements.matches_filter(filter)
    }
}

impl Default for Endorseable {
    fn default() -> Self {
        Self::new()
    }
}

pub fn endorsements_from_ids(pairs: &[(u64, u64)]) -> EndorsementSet {
    EndorsementSet::from_endorsements(
        pairs
            .iter()
            .map(|&(c, t)| Endorsement::new(c, t))
            .collect(),
    )
}

pub fn endorsement_ids_to_grandmap(endorsements: &EndorsementSet) -> Vec<Id> {
    endorsements
        .iter()
        .map(|e| Id::in_space(super::grandmap::IdSpaceId::new(e.club_id), e.token_id as i64))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn endorsement_new() {
        let e = Endorsement::new(1, 2);
        assert_eq!(e.club_id(), 1);
        assert_eq!(e.token_id(), 2);
    }

    #[test]
    fn endorsement_display() {
        let e = Endorsement::new(42, 99);
        assert_eq!(format!("{}", e), "(42,99)");
    }

    #[test]
    fn endorsement_equality() {
        let a = Endorsement::new(1, 2);
        let b = Endorsement::new(1, 2);
        let c = Endorsement::new(1, 3);
        assert_eq!(a, b);
        assert_ne!(a, c);
    }

    #[test]
    fn endorsement_ordering() {
        let a = Endorsement::new(1, 2);
        let b = Endorsement::new(1, 3);
        let c = Endorsement::new(2, 1);
        assert!(a < b);
        assert!(b < c);
    }

    #[test]
    fn endorsement_set_new() {
        let set = EndorsementSet::new();
        assert!(set.is_empty());
        assert_eq!(set.len(), 0);
    }

    #[test]
    fn endorsement_set_single() {
        let set = EndorsementSet::single(1, 2);
        assert!(!set.is_empty());
        assert_eq!(set.len(), 1);
        assert!(set.contains_pair(1, 2));
        assert!(!set.contains_pair(1, 3));
    }

    #[test]
    fn endorsement_set_from_vec() {
        let set = EndorsementSet::from_endorsements(vec![
            Endorsement::new(1, 10),
            Endorsement::new(2, 20),
            Endorsement::new(1, 10),
        ]);
        assert_eq!(set.len(), 2);
    }

    #[test]
    fn endorsement_set_with_adds() {
        let set = EndorsementSet::new()
            .with(Endorsement::new(1, 10))
            .with(Endorsement::new(2, 20));
        assert_eq!(set.len(), 2);
        assert!(set.contains_pair(1, 10));
        assert!(set.contains_pair(2, 20));
    }

    #[test]
    fn endorsement_set_with_deduplicates() {
        let set = EndorsementSet::single(1, 10)
            .with(Endorsement::new(1, 10));
        assert_eq!(set.len(), 1);
    }

    #[test]
    fn endorsement_set_without_removes() {
        let set = EndorsementSet::from_endorsements(vec![
            Endorsement::new(1, 10),
            Endorsement::new(2, 20),
        ]);
        let reduced = set.without(&Endorsement::new(1, 10));
        assert_eq!(reduced.len(), 1);
        assert!(!reduced.contains_pair(1, 10));
        assert!(reduced.contains_pair(2, 20));
    }

    #[test]
    fn endorsement_set_union() {
        let a = EndorsementSet::from_endorsements(vec![
            Endorsement::new(1, 10),
            Endorsement::new(2, 20),
        ]);
        let b = EndorsementSet::from_endorsements(vec![
            Endorsement::new(2, 20),
            Endorsement::new(3, 30),
        ]);
        let union = a.union(&b);
        assert_eq!(union.len(), 3);
    }

    #[test]
    fn endorsement_set_intersect() {
        let a = EndorsementSet::from_endorsements(vec![
            Endorsement::new(1, 10),
            Endorsement::new(2, 20),
        ]);
        let b = EndorsementSet::from_endorsements(vec![
            Endorsement::new(2, 20),
            Endorsement::new(3, 30),
        ]);
        let intersection = a.intersect(&b);
        assert_eq!(intersection.len(), 1);
        assert!(intersection.contains_pair(2, 20));
    }

    #[test]
    fn endorsement_set_difference() {
        let a = EndorsementSet::from_endorsements(vec![
            Endorsement::new(1, 10),
            Endorsement::new(2, 20),
        ]);
        let b = EndorsementSet::from_endorsements(vec![
            Endorsement::new(2, 20),
            Endorsement::new(3, 30),
        ]);
        let diff = a.difference(&b);
        assert_eq!(diff.len(), 1);
        assert!(diff.contains_pair(1, 10));
    }

    #[test]
    fn endorsement_set_is_subset() {
        let a = EndorsementSet::single(1, 10);
        let b = EndorsementSet::from_endorsements(vec![
            Endorsement::new(1, 10),
            Endorsement::new(2, 20),
        ]);
        assert!(a.is_subset_of(&b));
        assert!(!b.is_subset_of(&a));
    }

    #[test]
    fn endorsement_set_club_ids() {
        let set = EndorsementSet::from_endorsements(vec![
            Endorsement::new(1, 10),
            Endorsement::new(1, 20),
            Endorsement::new(2, 30),
        ]);
        let clubs = set.club_ids();
        assert_eq!(clubs.len(), 2);
        assert!(clubs.contains(&1));
        assert!(clubs.contains(&2));
    }

    #[test]
    fn endorsement_set_tokens_for_club() {
        let set = EndorsementSet::from_endorsements(vec![
            Endorsement::new(1, 10),
            Endorsement::new(1, 20),
            Endorsement::new(2, 30),
        ]);
        let tokens = set.tokens_for_club(1);
        assert_eq!(tokens.len(), 2);
        assert!(tokens.contains(&10));
        assert!(tokens.contains(&20));
    }

    #[test]
    fn endorsement_set_with_all() {
        let a = EndorsementSet::single(1, 10);
        let b = EndorsementSet::single(2, 20);
        let merged = a.with_all(&b);
        assert_eq!(merged.len(), 2);
    }

    #[test]
    fn endorsement_set_without_all() {
        let a = EndorsementSet::from_endorsements(vec![
            Endorsement::new(1, 10),
            Endorsement::new(2, 20),
            Endorsement::new(3, 30),
        ]);
        let b = EndorsementSet::from_endorsements(vec![
            Endorsement::new(1, 10),
            Endorsement::new(3, 30),
        ]);
        let result = a.without_all(&b);
        assert_eq!(result.len(), 1);
        assert!(result.contains_pair(2, 20));
    }

    #[test]
    fn filter_any() {
        let set = EndorsementSet::new();
        assert!(set.matches_filter(&EndorsementFilter::any()));
    }

    #[test]
    fn filter_none() {
        let set = EndorsementSet::single(1, 10);
        assert!(!set.matches_filter(&EndorsementFilter::none()));
    }

    #[test]
    fn filter_all_of_pass() {
        let set = EndorsementSet::from_endorsements(vec![
            Endorsement::new(1, 10),
            Endorsement::new(2, 20),
        ]);
        let required = EndorsementSet::single(1, 10);
        assert!(set.matches_filter(&EndorsementFilter::all_of(required)));
    }

    #[test]
    fn filter_all_of_fail() {
        let set = EndorsementSet::single(1, 10);
        let required = EndorsementSet::from_endorsements(vec![
            Endorsement::new(1, 10),
            Endorsement::new(2, 20),
        ]);
        assert!(!set.matches_filter(&EndorsementFilter::all_of(required)));
    }

    #[test]
    fn filter_any_of() {
        let set = EndorsementSet::single(1, 10);
        let candidates = EndorsementSet::from_endorsements(vec![
            Endorsement::new(1, 10),
            Endorsement::new(3, 30),
        ]);
        assert!(set.matches_filter(&EndorsementFilter::any_of(candidates)));
    }

    #[test]
    fn filter_any_of_fail() {
        let set = EndorsementSet::single(1, 10);
        let candidates = EndorsementSet::from_endorsements(vec![
            Endorsement::new(2, 20),
            Endorsement::new(3, 30),
        ]);
        assert!(!set.matches_filter(&EndorsementFilter::any_of(candidates)));
    }

    #[test]
    fn filter_club() {
        let set = EndorsementSet::from_endorsements(vec![
            Endorsement::new(1, 10),
            Endorsement::new(2, 20),
        ]);
        assert!(set.matches_filter(&EndorsementFilter::club(1)));
        assert!(set.matches_filter(&EndorsementFilter::club(2)));
        assert!(!set.matches_filter(&EndorsementFilter::club(3)));
    }

    #[test]
    fn filter_not() {
        let set = EndorsementSet::single(1, 10);
        assert!(set.matches_filter(&EndorsementFilter::not(EndorsementFilter::none())));
        assert!(!set.matches_filter(&EndorsementFilter::not(EndorsementFilter::any())));
    }

    #[test]
    fn filter_and() {
        let set = EndorsementSet::from_endorsements(vec![
            Endorsement::new(1, 10),
            Endorsement::new(2, 20),
        ]);
        let filter = EndorsementFilter::and(vec![
            EndorsementFilter::club(1),
            EndorsementFilter::club(2),
        ]);
        assert!(set.matches_filter(&filter));
    }

    #[test]
    fn filter_and_fail() {
        let set = EndorsementSet::single(1, 10);
        let filter = EndorsementFilter::and(vec![
            EndorsementFilter::club(1),
            EndorsementFilter::club(2),
        ]);
        assert!(!set.matches_filter(&filter));
    }

    #[test]
    fn filter_or() {
        let set = EndorsementSet::single(1, 10);
        let filter = EndorsementFilter::or(vec![
            EndorsementFilter::club(1),
            EndorsementFilter::club(2),
        ]);
        assert!(set.matches_filter(&filter));
    }

    #[test]
    fn filter_or_fail() {
        let set = EndorsementSet::single(3, 10);
        let filter = EndorsementFilter::or(vec![
            EndorsementFilter::club(1),
            EndorsementFilter::club(2),
        ]);
        assert!(!set.matches_filter(&filter));
    }

    #[test]
    fn endorseable_new() {
        let e = Endorseable::new();
        assert!(e.endorsements().is_empty());
    }

    #[test]
    fn endorseable_endorse() {
        let mut e = Endorseable::new();
        e.endorse_one(1, 10);
        assert!(e.is_endorsed_by(1, 10));
        assert!(!e.is_endorsed_by(1, 20));
    }

    #[test]
    fn endorseable_endorse_set() {
        let mut e = Endorseable::new();
        let set = EndorsementSet::from_endorsements(vec![
            Endorsement::new(1, 10),
            Endorsement::new(2, 20),
        ]);
        e.endorse(&set);
        assert!(e.is_endorsed_by(1, 10));
        assert!(e.is_endorsed_by(2, 20));
    }

    #[test]
    fn endorseable_retract() {
        let mut e = Endorseable::with_endorsements(
            EndorsementSet::from_endorsements(vec![
                Endorsement::new(1, 10),
                Endorsement::new(2, 20),
            ]),
        );
        e.retract_one(1, 10);
        assert!(!e.is_endorsed_by(1, 10));
        assert!(e.is_endorsed_by(2, 20));
    }

    #[test]
    fn endorseable_retract_set() {
        let mut e = Endorseable::with_endorsements(
            EndorsementSet::from_endorsements(vec![
                Endorsement::new(1, 10),
                Endorsement::new(2, 20),
                Endorsement::new(3, 30),
            ]),
        );
        let to_remove = EndorsementSet::from_endorsements(vec![
            Endorsement::new(1, 10),
            Endorsement::new(3, 30),
        ]);
        e.retract(&to_remove);
        assert_eq!(e.endorsements().len(), 1);
        assert!(e.is_endorsed_by(2, 20));
    }

    #[test]
    fn endorseable_has_club() {
        let mut e = Endorseable::new();
        e.endorse_one(1, 10);
        e.endorse_one(1, 20);
        assert!(e.has_club_endorsement(1));
        assert!(!e.has_club_endorsement(2));
    }

    #[test]
    fn endorseable_matches_filter() {
        let mut e = Endorseable::new();
        e.endorse_one(1, 10);
        e.endorse_one(2, 20);
        assert!(e.matches_filter(&EndorsementFilter::club(1)));
        assert!(!e.matches_filter(&EndorsementFilter::club(3)));
    }

    #[test]
    fn endorseable_idempotent_endorse() {
        let mut e = Endorseable::new();
        e.endorse_one(1, 10);
        e.endorse_one(1, 10);
        assert_eq!(e.endorsements().len(), 1);
    }

    #[test]
    fn endorseable_retract_nonexistent_is_noop() {
        let mut e = Endorseable::new();
        e.endorse_one(1, 10);
        e.retract_one(99, 99);
        assert_eq!(e.endorsements().len(), 1);
    }

    #[test]
    fn test_endorsements_from_ids() {
        let set = endorsements_from_ids(&[(1, 10), (2, 20)]);
        assert_eq!(set.len(), 2);
        assert!(set.contains_pair(1, 10));
    }

    #[test]
    fn endorsement_set_to_vec_preserves_order() {
        let set = EndorsementSet::from_endorsements(vec![
            Endorsement::new(3, 30),
            Endorsement::new(1, 10),
            Endorsement::new(2, 20),
        ]);
        let vec = set.to_vec();
        assert_eq!(vec[0], Endorsement::new(1, 10));
        assert_eq!(vec[1], Endorsement::new(2, 20));
        assert_eq!(vec[2], Endorsement::new(3, 30));
    }

    #[test]
    fn endorsement_set_default() {
        let set = EndorsementSet::default();
        assert!(set.is_empty());
    }

    #[test]
    fn endorseable_default() {
        let e = Endorseable::default();
        assert!(e.endorsements().is_empty());
    }

    #[test]
    fn complex_filter_combo() {
        let mut e = Endorseable::new();
        e.endorse_one(1, 10);
        e.endorse_one(2, 20);
        e.endorse_one(3, 30);

        let filter = EndorsementFilter::and(vec![
            EndorsementFilter::not(EndorsementFilter::club(4)),
            EndorsementFilter::or(vec![
                EndorsementFilter::club(1),
                EndorsementFilter::club(4),
            ]),
        ]);
        assert!(e.matches_filter(&filter));
    }

    #[test]
    fn endorsement_set_iter() {
        let set = EndorsementSet::from_endorsements(vec![
            Endorsement::new(1, 10),
            Endorsement::new(2, 20),
        ]);
        let items: Vec<_> = set.iter().collect();
        assert_eq!(items.len(), 2);
    }
}
