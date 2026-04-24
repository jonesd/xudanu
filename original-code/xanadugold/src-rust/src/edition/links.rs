use std::collections::HashMap;
use super::edition::Edition;
use super::range_element::RangeElement;

#[derive(Debug, Clone, PartialEq)]
pub struct Path {
    labels: Vec<RangeElement>,
}

impl Path {
    pub fn new(labels: Vec<RangeElement>) -> Self {
        Path { labels }
    }

    pub fn empty() -> Self {
        Path { labels: Vec::new() }
    }

    pub fn labels(&self) -> &[RangeElement] {
        &self.labels
    }

    pub fn is_empty(&self) -> bool {
        self.labels.is_empty()
    }

    pub fn len(&self) -> usize {
        self.labels.len()
    }

    pub fn with_label(&self, label: RangeElement) -> Self {
        let mut labels = self.labels.clone();
        labels.push(label);
        Path { labels }
    }

    pub fn follow(&self, _edition: &Edition) -> Option<RangeElement> {
        None
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct HyperRef {
    kind: HyperRefKind,
    work_context: Option<u64>,
    original_context: Option<u64>,
    path_context: Option<Path>,
}

#[derive(Debug, Clone, PartialEq)]
pub enum HyperRefKind {
    Single {
        excerpt: Option<Edition>,
    },
    Multi {
        refs: Vec<HyperRef>,
    },
}

impl HyperRef {
    pub fn single(
        material: Option<Edition>,
        work_context: Option<u64>,
        original_context: Option<u64>,
        path_context: Option<Path>,
    ) -> Self {
        HyperRef {
            kind: HyperRefKind::Single { excerpt: material },
            work_context,
            original_context,
            path_context,
        }
    }

    pub fn multi(
        refs: Vec<HyperRef>,
        work_context: Option<u64>,
        original_context: Option<u64>,
        path_context: Option<Path>,
    ) -> Self {
        HyperRef {
            kind: HyperRefKind::Multi { refs },
            work_context,
            original_context,
            path_context,
        }
    }

    pub fn kind(&self) -> &HyperRefKind {
        &self.kind
    }

    pub fn is_single(&self) -> bool {
        matches!(self.kind, HyperRefKind::Single { .. })
    }

    pub fn is_multi(&self) -> bool {
        matches!(self.kind, HyperRefKind::Multi { .. })
    }

    pub fn excerpt(&self) -> Option<&Edition> {
        match &self.kind {
            HyperRefKind::Single { excerpt } => excerpt.as_ref(),
            HyperRefKind::Multi { .. } => None,
        }
    }

    pub fn refs(&self) -> &[HyperRef] {
        match &self.kind {
            HyperRefKind::Single { .. } => &[],
            HyperRefKind::Multi { refs } => refs,
        }
    }

    pub fn work_context(&self) -> Option<u64> {
        self.work_context
    }

    pub fn original_context(&self) -> Option<u64> {
        self.original_context
    }

    pub fn path_context(&self) -> Option<&Path> {
        self.path_context.as_ref()
    }

    pub fn with_excerpt(&self, excerpt: Edition) -> Self {
        HyperRef {
            kind: HyperRefKind::Single { excerpt: Some(excerpt) },
            work_context: self.work_context,
            original_context: self.original_context,
            path_context: self.path_context.clone(),
        }
    }

    pub fn with_work_context(&self, work_id: Option<u64>) -> Self {
        HyperRef {
            kind: self.kind.clone(),
            work_context: work_id,
            original_context: self.original_context,
            path_context: self.path_context.clone(),
        }
    }

    pub fn with_original_context(&self, work_id: Option<u64>) -> Self {
        HyperRef {
            kind: self.kind.clone(),
            work_context: self.work_context,
            original_context: work_id,
            path_context: self.path_context.clone(),
        }
    }

    pub fn with_path_context(&self, path: Option<Path>) -> Self {
        HyperRef {
            kind: self.kind.clone(),
            work_context: self.work_context,
            original_context: self.original_context,
            path_context: path,
        }
    }

    pub fn with_ref(&self, new_ref: HyperRef) -> Self {
        match &self.kind {
            HyperRefKind::Multi { refs } => {
                let mut new_refs = refs.clone();
                let already = new_refs.iter().any(|r| r == &new_ref);
                if !already {
                    new_refs.push(new_ref);
                }
                HyperRef {
                    kind: HyperRefKind::Multi { refs: new_refs },
                    work_context: self.work_context,
                    original_context: self.original_context,
                    path_context: self.path_context.clone(),
                }
            }
            HyperRefKind::Single { .. } => self.clone(),
        }
    }

    pub fn without_ref(&self, remove_ref: &HyperRef) -> Self {
        match &self.kind {
            HyperRefKind::Multi { refs } => {
                let new_refs: Vec<HyperRef> =
                    refs.iter().filter(|r| *r != remove_ref).cloned().collect();
                HyperRef {
                    kind: HyperRefKind::Multi { refs: new_refs },
                    work_context: self.work_context,
                    original_context: self.original_context,
                    path_context: self.path_context.clone(),
                }
            }
            HyperRefKind::Single { .. } => self.clone(),
        }
    }

    pub fn union_with(&self, other: &HyperRef) -> Self {
        match (&self.kind, &other.kind) {
            (HyperRefKind::Multi { refs: a }, HyperRefKind::Multi { refs: b }) => {
                let mut merged = a.clone();
                for r in b {
                    if !merged.iter().any(|existing| existing == r) {
                        merged.push(r.clone());
                    }
                }
                HyperRef {
                    kind: HyperRefKind::Multi { refs: merged },
                    work_context: self.work_context,
                    original_context: self.original_context,
                    path_context: self.path_context.clone(),
                }
            }
            _ => self.clone(),
        }
    }

    pub fn intersect(&self, other: &HyperRef) -> Self {
        match (&self.kind, &other.kind) {
            (HyperRefKind::Multi { refs: a }, HyperRefKind::Multi { refs: b }) => {
                let kept: Vec<HyperRef> =
                    a.iter().filter(|r| b.iter().any(|o| o == *r)).cloned().collect();
                HyperRef {
                    kind: HyperRefKind::Multi { refs: kept },
                    work_context: self.work_context,
                    original_context: self.original_context,
                    path_context: self.path_context.clone(),
                }
            }
            _ => self.clone(),
        }
    }

    pub fn minus(&self, other: &HyperRef) -> Self {
        match (&self.kind, &other.kind) {
            (HyperRefKind::Multi { refs: a }, HyperRefKind::Multi { refs: b }) => {
                let kept: Vec<HyperRef> =
                    a.iter().filter(|r| !b.iter().any(|o| o == *r)).cloned().collect();
                HyperRef {
                    kind: HyperRefKind::Multi { refs: kept },
                    work_context: self.work_context,
                    original_context: self.original_context,
                    path_context: self.path_context.clone(),
                }
            }
            _ => self.clone(),
        }
    }

    pub fn referenced_content(&self) -> Vec<RangeElement> {
        let mut result = Vec::new();
        match &self.kind {
            HyperRefKind::Single { excerpt } => {
                if let Some(edition) = excerpt {
                    for (_, carrier) in edition.all_entries() {
                        result.push(carrier.element.clone());
                    }
                }
            }
            HyperRefKind::Multi { refs } => {
                for r in refs {
                    result.extend(r.referenced_content());
                }
            }
        }
        result
    }
}

const LINK_TYPES_KEY: &str = "LinkTypes";

#[derive(Debug, Clone, PartialEq)]
pub struct HyperLink {
    ends: HashMap<String, HyperRef>,
    link_types: Vec<u64>,
}

impl HyperLink {
    pub fn new() -> Self {
        HyperLink {
            ends: HashMap::new(),
            link_types: Vec::new(),
        }
    }

    pub fn make(
        types: Vec<u64>,
        left_end: HyperRef,
        right_end: HyperRef,
    ) -> Self {
        let mut ends = HashMap::new();
        ends.insert("LeftEnd".to_string(), left_end);
        ends.insert("RightEnd".to_string(), right_end);
        HyperLink {
            ends,
            link_types: types,
        }
    }

    pub fn make_with_ends(
        types: Vec<u64>,
        ends: HashMap<String, HyperRef>,
    ) -> Self {
        HyperLink {
            ends,
            link_types: types,
        }
    }

    pub fn end_at(&self, name: &str) -> Option<&HyperRef> {
        if name == LINK_TYPES_KEY {
            return None;
        }
        self.ends.get(name)
    }

    pub fn end_names(&self) -> Vec<&str> {
        self.ends.keys().map(|s| s.as_str()).collect()
    }

    pub fn link_types(&self) -> &[u64] {
        &self.link_types
    }

    pub fn with_end(&self, name: &str, link_end: HyperRef) -> Self {
        if name == LINK_TYPES_KEY {
            return self.clone();
        }
        let mut ends = self.ends.clone();
        ends.insert(name.to_string(), link_end);
        HyperLink {
            ends,
            link_types: self.link_types.clone(),
        }
    }

    pub fn without_end(&self, name: &str) -> Self {
        if name == LINK_TYPES_KEY {
            return self.clone();
        }
        let mut ends = self.ends.clone();
        ends.remove(name);
        HyperLink {
            ends,
            link_types: self.link_types.clone(),
        }
    }

    pub fn with_link_types(&self, types: Vec<u64>) -> Self {
        HyperLink {
            ends: self.ends.clone(),
            link_types: types,
        }
    }

    pub fn ends(&self) -> &HashMap<String, HyperRef> {
        &self.ends
    }

    pub fn end_count(&self) -> usize {
        self.ends.len()
    }

    pub fn has_end(&self, name: &str) -> bool {
        self.ends.contains_key(name)
    }

    pub fn all_referenced_content(&self) -> Vec<RangeElement> {
        let mut result = Vec::new();
        for end in self.ends.values() {
            result.extend(end.referenced_content());
        }
        result
    }

    pub fn is_two_ended(&self) -> bool {
        self.ends.len() == 2
    }

    pub fn left_end(&self) -> Option<&HyperRef> {
        self.ends.get("LeftEnd")
    }

    pub fn right_end(&self) -> Option<&HyperRef> {
        self.ends.get("RightEnd")
    }
}

impl Default for HyperLink {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn path_new() {
        let path = Path::new(vec![RangeElement::text("label1")]);
        assert_eq!(path.len(), 1);
        assert!(!path.is_empty());
    }

    #[test]
    fn path_empty() {
        let path = Path::empty();
        assert!(path.is_empty());
        assert_eq!(path.len(), 0);
    }

    #[test]
    fn path_with_label() {
        let path = Path::empty();
        let extended = path.with_label(RangeElement::text("a"));
        assert_eq!(extended.len(), 1);
        assert!(path.is_empty());
    }

    #[test]
    fn hyper_ref_single() {
        let edition = Edition::from_text("hello");
        let href = HyperRef::single(Some(edition), None, None, None);
        assert!(href.is_single());
        assert!(!href.is_multi());
        assert!(href.excerpt().is_some());
        assert!(href.refs().is_empty());
    }

    #[test]
    fn hyper_ref_multi() {
        let r1 = HyperRef::single(Some(Edition::from_text("a")), None, None, None);
        let r2 = HyperRef::single(Some(Edition::from_text("b")), None, None, None);
        let multi = HyperRef::multi(vec![r1, r2], None, None, None);
        assert!(multi.is_multi());
        assert!(multi.excerpt().is_none());
        assert_eq!(multi.refs().len(), 2);
    }

    #[test]
    fn hyper_ref_with_excerpt() {
        let href = HyperRef::single(None, None, None, None);
        assert!(href.excerpt().is_none());
        let updated = href.with_excerpt(Edition::from_text("new"));
        assert!(updated.excerpt().is_some());
    }

    #[test]
    fn hyper_ref_with_contexts() {
        let href = HyperRef::single(None, None, None, None);
        assert!(href.work_context().is_none());
        assert!(href.original_context().is_none());
        assert!(href.path_context().is_none());

        let with_work = href.with_work_context(Some(42));
        assert_eq!(with_work.work_context(), Some(42));

        let with_orig = with_work.with_original_context(Some(99));
        assert_eq!(with_orig.original_context(), Some(99));

        let with_path = with_orig.with_path_context(Some(Path::new(vec![RangeElement::text("x")])));
        assert!(with_path.path_context().is_some());
    }

    #[test]
    fn hyper_ref_with_ref() {
        let r1 = HyperRef::single(Some(Edition::from_text("a")), None, None, None);
        let multi = HyperRef::multi(vec![r1], None, None, None);
        assert_eq!(multi.refs().len(), 1);

        let r3 = HyperRef::single(Some(Edition::from_text("c")), None, None, None);
        let added = multi.with_ref(r3.clone());
        assert_eq!(added.refs().len(), 2);

        let duplicate = added.with_ref(r3);
        assert_eq!(duplicate.refs().len(), 2);
    }

    #[test]
    fn hyper_ref_without_ref() {
        let r1 = HyperRef::single(Some(Edition::from_text("a")), None, None, None);
        let r2 = HyperRef::single(Some(Edition::from_text("b")), None, None, None);
        let multi = HyperRef::multi(vec![r1.clone(), r2.clone()], None, None, None);
        assert_eq!(multi.refs().len(), 2);

        let removed = multi.without_ref(&r1);
        assert_eq!(removed.refs().len(), 1);
    }

    #[test]
    fn hyper_ref_union() {
        let r1 = HyperRef::single(Some(Edition::from_text("a")), None, None, None);
        let r2 = HyperRef::single(Some(Edition::from_text("b")), None, None, None);
        let r3 = HyperRef::single(Some(Edition::from_text("c")), None, None, None);
        let m1 = HyperRef::multi(vec![r1, r2.clone()], None, None, None);
        let m2 = HyperRef::multi(vec![r2, r3], None, None, None);
        let union = m1.union_with(&m2);
        assert_eq!(union.refs().len(), 3);
    }

    #[test]
    fn hyper_ref_intersect() {
        let r1 = HyperRef::single(Some(Edition::from_text("a")), None, None, None);
        let r2 = HyperRef::single(Some(Edition::from_text("b")), None, None, None);
        let r3 = HyperRef::single(Some(Edition::from_text("c")), None, None, None);
        let m1 = HyperRef::multi(vec![r1.clone(), r2.clone()], None, None, None);
        let m2 = HyperRef::multi(vec![r2, r3], None, None, None);
        let intersection = m1.intersect(&m2);
        assert_eq!(intersection.refs().len(), 1);
    }

    #[test]
    fn hyper_ref_minus() {
        let r1 = HyperRef::single(Some(Edition::from_text("a")), None, None, None);
        let r2 = HyperRef::single(Some(Edition::from_text("b")), None, None, None);
        let r3 = HyperRef::single(Some(Edition::from_text("c")), None, None, None);
        let m1 = HyperRef::multi(vec![r1, r2.clone()], None, None, None);
        let m2 = HyperRef::multi(vec![r2, r3], None, None, None);
        let diff = m1.minus(&m2);
        assert_eq!(diff.refs().len(), 1);
    }

    #[test]
    fn hyper_link_new() {
        let link = HyperLink::new();
        assert_eq!(link.end_count(), 0);
        assert!(link.end_names().is_empty());
    }

    #[test]
    fn hyper_link_make_two_ended() {
        let left = HyperRef::single(Some(Edition::from_text("source")), None, None, None);
        let right = HyperRef::single(Some(Edition::from_text("target")), None, None, None);
        let link = HyperLink::make(vec![], left, right);
        assert!(link.is_two_ended());
        assert!(link.has_end("LeftEnd"));
        assert!(link.has_end("RightEnd"));
        assert_eq!(link.end_count(), 2);
    }

    #[test]
    fn hyper_link_end_at() {
        let left = HyperRef::single(Some(Edition::from_text("source")), None, None, None);
        let right = HyperRef::single(Some(Edition::from_text("target")), None, None, None);
        let link = HyperLink::make(vec![], left, right);
        let left_ref = link.end_at("LeftEnd").unwrap();
        assert!(left_ref.is_single());
        assert!(link.end_at("NonExistent").is_none());
        assert!(link.end_at(LINK_TYPES_KEY).is_none());
    }

    #[test]
    fn hyper_link_with_end() {
        let left = HyperRef::single(Some(Edition::from_text("source")), None, None, None);
        let right = HyperRef::single(Some(Edition::from_text("target")), None, None, None);
        let link = HyperLink::make(vec![], left, right);

        let annotation = HyperRef::single(Some(Edition::from_text("note")), None, None, None);
        let extended = link.with_end("Annotation", annotation);
        assert_eq!(extended.end_count(), 3);
        assert!(extended.has_end("Annotation"));
        assert_eq!(link.end_count(), 2);
    }

    #[test]
    fn hyper_link_without_end() {
        let left = HyperRef::single(Some(Edition::from_text("source")), None, None, None);
        let right = HyperRef::single(Some(Edition::from_text("target")), None, None, None);
        let link = HyperLink::make(vec![], left, right);

        let reduced = link.without_end("RightEnd");
        assert_eq!(reduced.end_count(), 1);
        assert!(!reduced.has_end("RightEnd"));

        let unchanged = link.without_end(LINK_TYPES_KEY);
        assert_eq!(unchanged.end_count(), 2);
    }

    #[test]
    fn hyper_link_with_link_types() {
        let link = HyperLink::new();
        assert!(link.link_types().is_empty());
        let typed = link.with_link_types(vec![10, 20]);
        assert_eq!(typed.link_types(), &[10, 20]);
    }

    #[test]
    fn hyper_link_left_right_accessors() {
        let left = HyperRef::single(Some(Edition::from_text("source")), None, None, None);
        let right = HyperRef::single(Some(Edition::from_text("target")), None, None, None);
        let link = HyperLink::make(vec![], left.clone(), right.clone());
        assert_eq!(link.left_end().unwrap(), &left);
        assert_eq!(link.right_end().unwrap(), &right);
    }

    #[test]
    fn hyper_ref_referenced_content() {
        let edition = Edition::from_one(0, RangeElement::text("hello"));
        let href = HyperRef::single(Some(edition), None, None, None);
        let content = href.referenced_content();
        assert_eq!(content.len(), 1);
        assert_eq!(content[0], RangeElement::text("hello"));
    }

    #[test]
    fn hyper_link_all_referenced_content() {
        let left = HyperRef::single(Some(Edition::from_one(0, RangeElement::text("A"))), None, None, None);
        let right = HyperRef::single(Some(Edition::from_one(0, RangeElement::text("B"))), None, None, None);
        let link = HyperLink::make(vec![], left, right);
        let content = link.all_referenced_content();
        assert_eq!(content.len(), 2);
    }

    #[test]
    fn gold_hyper_link_make() {
        let left = HyperRef::single(Some(Edition::from_text("source")), Some(1), None, None);
        let right = HyperRef::single(Some(Edition::from_text("target")), Some(2), None, None);
        let link = HyperLink::make(vec![100], left, right);
        assert_eq!(link.link_types(), &[100]);
        assert!(link.left_end().unwrap().work_context() == Some(1));
        assert!(link.right_end().unwrap().work_context() == Some(2));
    }

    #[test]
    fn gold_hyper_link_add_remove_end() {
        let left = HyperRef::single(Some(Edition::from_text("L")), None, None, None);
        let right = HyperRef::single(Some(Edition::from_text("R")), None, None, None);
        let link = HyperLink::make(vec![], left, right);
        assert_eq!(link.end_count(), 2);

        let mid = HyperRef::single(Some(Edition::from_text("M")), None, None, None);
        let link3 = link.with_end("Middle", mid);
        assert_eq!(link3.end_count(), 3);

        let link2 = link3.without_end("Middle");
        assert_eq!(link2.end_count(), 2);
    }

    #[test]
    fn gold_multi_ref_set_operations() {
        let r1 = HyperRef::single(Some(Edition::from_text("a")), None, None, None);
        let r2 = HyperRef::single(Some(Edition::from_text("b")), None, None, None);
        let r3 = HyperRef::single(Some(Edition::from_text("c")), None, None, None);

        let m1 = HyperRef::multi(vec![r1.clone(), r2.clone()], None, None, None);
        let m2 = HyperRef::multi(vec![r2, r3], None, None, None);

        let union = m1.union_with(&m2);
        assert_eq!(union.refs().len(), 3);

        let intersection = m1.intersect(&m2);
        assert_eq!(intersection.refs().len(), 1);

        let diff = m1.minus(&m2);
        assert_eq!(diff.refs().len(), 1);
    }

    #[test]
    fn gold_single_ref_with_contexts() {
        let material = Edition::from_text("content");
        let href = HyperRef::single(
            Some(material),
            Some(10),
            Some(20),
            Some(Path::new(vec![RangeElement::text("inner")])),
        );
        assert_eq!(href.work_context(), Some(10));
        assert_eq!(href.original_context(), Some(20));
        assert_eq!(href.path_context().unwrap().len(), 1);

        let updated = href.with_work_context(Some(30));
        assert_eq!(updated.work_context(), Some(30));
        assert_eq!(updated.original_context(), Some(20));
    }

    #[test]
    fn hyper_link_make_with_custom_ends() {
        let mut ends = HashMap::new();
        ends.insert("Source".to_string(), HyperRef::single(Some(Edition::from_text("s")), None, None, None));
        ends.insert("Target".to_string(), HyperRef::single(Some(Edition::from_text("t")), None, None, None));
        ends.insert("Annotation".to_string(), HyperRef::single(Some(Edition::from_text("a")), None, None, None));
        let link = HyperLink::make_with_ends(vec![1, 2], ends);
        assert_eq!(link.end_count(), 3);
        assert!(!link.is_two_ended());
        assert_eq!(link.link_types().len(), 2);
    }
}
