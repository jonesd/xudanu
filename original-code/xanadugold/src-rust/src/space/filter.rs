use std::cmp::Ordering;
use std::fmt::Debug;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct FilterSpace {
    name: &'static str,
}

impl FilterSpace {
    pub fn new() -> Self {
        FilterSpace {
            name: "FilterSpace",
        }
    }
}

impl Default for FilterSpace {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct FilterPosition {
    region_tag: u64,
}

impl FilterPosition {
    pub fn new(tag: u64) -> Self {
        FilterPosition { region_tag: tag }
    }

    pub fn tag(&self) -> u64 {
        self.region_tag
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Filter {
    Full,
    Empty,
    NotSubset(u64),
    NotSuperset(u64),
    Subset(u64),
    Superset(u64),
    Intersection(u64),
    And(Vec<Filter>),
    Or(Vec<Filter>),
}

impl PartialOrd for Filter {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for Filter {
    fn cmp(&self, other: &Self) -> Ordering {
        fn kind(f: &Filter) -> u8 {
            match f {
                Filter::Empty => 0,
                Filter::NotSubset(_) => 1,
                Filter::NotSuperset(_) => 2,
                Filter::Subset(_) => 3,
                Filter::Intersection(_) => 4,
                Filter::Superset(_) => 5,
                Filter::And(_) => 6,
                Filter::Or(_) => 7,
                Filter::Full => 8,
            }
        }
        match kind(self).cmp(&kind(other)) {
            Ordering::Equal => match (self, other) {
                (Filter::Subset(a), Filter::Subset(b))
                | (Filter::Superset(a), Filter::Superset(b))
                | (Filter::Intersection(a), Filter::Intersection(b))
                | (Filter::NotSubset(a), Filter::NotSubset(b))
                | (Filter::NotSuperset(a), Filter::NotSuperset(b)) => a.cmp(b),
                (Filter::And(a), Filter::And(b)) | (Filter::Or(a), Filter::Or(b)) => a.cmp(b),
                _ => Ordering::Equal,
            },
            ord => ord,
        }
    }
}

impl Filter {
    pub fn open() -> Self {
        Filter::Full
    }

    pub fn closed() -> Self {
        Filter::Empty
    }

    pub fn subset(tag: u64) -> Self {
        Filter::Subset(tag)
    }

    pub fn superset(tag: u64) -> Self {
        Filter::Superset(tag)
    }

    pub fn intersection(tag: u64) -> Self {
        Filter::Intersection(tag)
    }

    pub fn not_subset(tag: u64) -> Self {
        Filter::NotSubset(tag)
    }

    pub fn not_superset(tag: u64) -> Self {
        Filter::NotSuperset(tag)
    }

    pub fn and(filters: Vec<Filter>) -> Self {
        let mut flat: Vec<Filter> = Vec::new();
        for f in &filters {
            match f {
                Filter::Empty => return Filter::Empty,
                Filter::Full => {}
                Filter::And(subs) => flat.extend(subs.clone()),
                other => flat.push(other.clone()),
            }
        }
        flat.sort_by(|a, b| a.cmp(b));
        flat.dedup();
        match flat.len() {
            0 => Filter::Full,
            1 => flat.pop().unwrap(),
            _ => Filter::And(flat),
        }
    }

    pub fn or(filters: Vec<Filter>) -> Self {
        let mut flat: Vec<Filter> = Vec::new();
        for f in &filters {
            match f {
                Filter::Full => return Filter::Full,
                Filter::Empty => {}
                Filter::Or(subs) => flat.extend(subs.clone()),
                other => flat.push(other.clone()),
            }
        }
        flat.sort_by(|a, b| a.cmp(b));
        flat.dedup();
        match flat.len() {
            0 => Filter::Empty,
            1 => flat.pop().unwrap(),
            _ => Filter::Or(flat),
        }
    }

    pub fn is_open(&self) -> bool {
        matches!(self, Filter::Full)
    }

    pub fn is_closed(&self) -> bool {
        matches!(self, Filter::Empty)
    }

    pub fn is_all_filter(&self) -> bool {
        matches!(self, Filter::Superset(_) | Filter::Full)
    }

    pub fn is_any_filter(&self) -> bool {
        matches!(
            self,
            Filter::Intersection(_) | Filter::Subset(_) | Filter::Full
        )
    }

    pub fn match_tag(&self, tag: u64, tags_set: &[u64]) -> bool {
        match self {
            Filter::Full => true,
            Filter::Empty => false,
            Filter::Subset(t) => tags_set.contains(t),
            Filter::Superset(t) => tags_set.contains(t),
            Filter::Intersection(t) => tags_set.contains(t),
            Filter::NotSubset(t) => !tags_set.contains(t),
            Filter::NotSuperset(t) => !tags_set.contains(t),
            Filter::And(subs) => subs.iter().all(|f| f.match_tag(tag, tags_set)),
            Filter::Or(subs) => subs.iter().any(|f| f.match_tag(tag, tags_set)),
        }
    }

    pub fn complement(&self) -> Self {
        match self {
            Filter::Full => Filter::Empty,
            Filter::Empty => Filter::Full,
            Filter::Subset(t) => Filter::NotSubset(*t),
            Filter::Superset(t) => Filter::NotSuperset(*t),
            Filter::Intersection(t) => Filter::NotSubset(*t),
            Filter::NotSubset(t) => Filter::Subset(*t),
            Filter::NotSuperset(t) => Filter::Superset(*t),
            Filter::And(subs) => {
                let comps: Vec<Filter> = subs.iter().map(|f| f.complement()).collect();
                Filter::or(comps)
            }
            Filter::Or(subs) => {
                let comps: Vec<Filter> = subs.iter().map(|f| f.complement()).collect();
                Filter::and(comps)
            }
        }
    }

    pub fn intersect_filter(&self, other: &Filter) -> Filter {
        Filter::and(vec![self.clone(), other.clone()])
    }

    pub fn union_filter(&self, other: &Filter) -> Filter {
        Filter::or(vec![self.clone(), other.clone()])
    }

    pub fn pass_joint(&self, joint: &Joint) -> Filter {
        match self {
            Filter::Full => Filter::Full,
            Filter::Empty => Filter::Empty,
            _ => {
                if joint.intersected_tags.is_empty() && joint.unioned_tags.is_empty() {
                    self.clone()
                } else {
                    self.clone()
                }
            }
        }
    }

    pub fn is_switched_by(&self, delta: &RegionDelta) -> bool {
        self.match_tag(0, &delta.before_tags) != self.match_tag(0, &delta.after_tags)
    }

    pub fn is_switched_on_by(&self, delta: &RegionDelta) -> bool {
        !self.match_tag(0, &delta.before_tags) && self.match_tag(0, &delta.after_tags)
    }

    pub fn is_switched_off_by(&self, delta: &RegionDelta) -> bool {
        self.match_tag(0, &delta.before_tags) && !self.match_tag(0, &delta.after_tags)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Joint {
    pub unioned_tags: Vec<u64>,
    pub intersected_tags: Vec<u64>,
}

impl Joint {
    pub fn empty() -> Self {
        Joint {
            unioned_tags: Vec::new(),
            intersected_tags: Vec::new(),
        }
    }

    pub fn single(tag: u64) -> Self {
        Joint {
            unioned_tags: vec![tag],
            intersected_tags: vec![tag],
        }
    }

    pub fn from_children(children: &[Joint]) -> Self {
        let mut unioned: Vec<u64> = Vec::new();
        let mut intersected: Vec<u64> = Vec::new();
        let mut first = true;
        for child in children {
            for &t in &child.unioned_tags {
                if !unioned.contains(&t) {
                    unioned.push(t);
                }
            }
            if first {
                intersected = child.intersected_tags.clone();
                first = false;
            } else {
                intersected.retain(|t| child.intersected_tags.contains(t));
            }
        }
        Joint {
            unioned_tags: unioned,
            intersected_tags: intersected,
        }
    }

    pub fn with_tag(&self, tag: u64) -> Self {
        let mut u = self.unioned_tags.clone();
        if !u.contains(&tag) {
            u.push(tag);
        }
        let mut i = self.intersected_tags.clone();
        if !i.contains(&tag) {
            i.push(tag);
        }
        Joint {
            unioned_tags: u,
            intersected_tags: i,
        }
    }

    pub fn join(&self, other: &Joint) -> Joint {
        Joint::from_children(&[self.clone(), other.clone()])
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct RegionDelta {
    pub before_tags: Vec<u64>,
    pub after_tags: Vec<u64>,
}

impl RegionDelta {
    pub fn new(before: Vec<u64>, after: Vec<u64>) -> Self {
        RegionDelta {
            before_tags: before,
            after_tags: after,
        }
    }

    pub fn is_same(&self) -> bool {
        self.before_tags == self.after_tags
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn filter_open_matches_everything() {
        let f = Filter::open();
        assert!(f.match_tag(0, &[1, 2, 3]));
        assert!(f.match_tag(0, &[]));
    }

    #[test]
    fn filter_closed_matches_nothing() {
        let f = Filter::closed();
        assert!(!f.match_tag(0, &[1, 2, 3]));
        assert!(!f.match_tag(0, &[]));
    }

    #[test]
    fn filter_subset_matches_when_tag_present() {
        let f = Filter::subset(42);
        assert!(f.match_tag(0, &[42]));
        assert!(f.match_tag(0, &[1, 42, 3]));
        assert!(!f.match_tag(0, &[1, 2, 3]));
    }

    #[test]
    fn filter_intersection_matches_when_tag_present() {
        let f = Filter::intersection(5);
        assert!(f.match_tag(0, &[5]));
        assert!(f.match_tag(0, &[1, 5]));
        assert!(!f.match_tag(0, &[1, 2]));
    }

    #[test]
    fn filter_and_all_must_match() {
        let f = Filter::and(vec![Filter::subset(1), Filter::subset(2)]);
        assert!(f.match_tag(0, &[1, 2, 3]));
        assert!(!f.match_tag(0, &[1, 3]));
        assert!(!f.match_tag(0, &[2, 3]));
    }

    #[test]
    fn filter_or_any_must_match() {
        let f = Filter::or(vec![Filter::subset(1), Filter::subset(2)]);
        assert!(f.match_tag(0, &[1]));
        assert!(f.match_tag(0, &[2]));
        assert!(!f.match_tag(0, &[3, 4]));
    }

    #[test]
    fn filter_complement() {
        let f = Filter::subset(1);
        let c = f.complement();
        assert!(c.match_tag(0, &[]));
        assert!(!c.match_tag(0, &[1]));
    }

    #[test]
    fn filter_and_simplifies() {
        let f = Filter::and(vec![Filter::Full, Filter::subset(1)]);
        assert_eq!(f, Filter::subset(1));
    }

    #[test]
    fn filter_or_simplifies() {
        let f = Filter::or(vec![Filter::Empty, Filter::subset(1)]);
        assert_eq!(f, Filter::subset(1));
    }

    #[test]
    fn filter_and_with_empty_is_empty() {
        let f = Filter::and(vec![Filter::subset(1), Filter::Empty]);
        assert_eq!(f, Filter::Empty);
    }

    #[test]
    fn filter_or_with_full_is_full() {
        let f = Filter::or(vec![Filter::subset(1), Filter::Full]);
        assert_eq!(f, Filter::Full);
    }

    #[test]
    fn joint_empty() {
        let j = Joint::empty();
        assert!(j.unioned_tags.is_empty());
        assert!(j.intersected_tags.is_empty());
    }

    #[test]
    fn joint_single() {
        let j = Joint::single(5);
        assert_eq!(j.unioned_tags, vec![5]);
        assert_eq!(j.intersected_tags, vec![5]);
    }

    #[test]
    fn joint_join() {
        let j1 = Joint::single(1);
        let j2 = Joint::single(2);
        let joined = j1.join(&j2);
        assert!(joined.unioned_tags.contains(&1));
        assert!(joined.unioned_tags.contains(&2));
        assert!(joined.intersected_tags.is_empty());
    }

    #[test]
    fn joint_join_same_tag() {
        let j1 = Joint::single(5);
        let j2 = Joint::single(5);
        let joined = j1.join(&j2);
        assert!(joined.intersected_tags.contains(&5));
    }

    #[test]
    fn region_delta_is_same() {
        let d = RegionDelta::new(vec![1, 2], vec![1, 2]);
        assert!(d.is_same());
        let d2 = RegionDelta::new(vec![1], vec![2]);
        assert!(!d2.is_same());
    }

    #[test]
    fn filter_intersect_filter() {
        let f1 = Filter::subset(1);
        let f2 = Filter::subset(2);
        let combined = f1.intersect_filter(&f2);
        assert!(combined.match_tag(0, &[1, 2]));
        assert!(!combined.match_tag(0, &[1]));
    }

    #[test]
    fn filter_union_filter() {
        let f1 = Filter::subset(1);
        let f2 = Filter::subset(2);
        let combined = f1.union_filter(&f2);
        assert!(combined.match_tag(0, &[1]));
        assert!(combined.match_tag(0, &[2]));
        assert!(!combined.match_tag(0, &[3]));
    }
}
