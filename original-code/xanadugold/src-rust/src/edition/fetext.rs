use super::edition::Edition;
use super::mapping::Mapping;
use super::range_element::RangeElement;
use super::xn_region::XnRegion;

#[derive(Debug, Clone, PartialEq)]
pub struct FeText {
    edition: Edition,
}

#[derive(Debug, Clone, PartialEq)]
pub enum FeTextError {
    NotContiguous,
    NotZeroBased,
}

impl std::fmt::Display for FeTextError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            FeTextError::NotContiguous => write!(f, "edition domain is not contiguous"),
            FeTextError::NotZeroBased => write!(f, "edition domain does not start at 0"),
        }
    }
}

impl std::error::Error for FeTextError {}

impl FeText {
    pub fn new(edition: Edition) -> Result<Self, FeTextError> {
        if edition.is_empty() {
            return Ok(FeText { edition });
        }
        let domain = edition.domain();
        if !domain.is_simple() {
            return Err(FeTextError::NotContiguous);
        }
        if let Some((start, _)) = domain.as_interval() {
            if start != 0 {
                return Err(FeTextError::NotZeroBased);
            }
        }
        Ok(FeText { edition })
    }

    pub fn from_text(text: &str) -> Self {
        FeText {
            edition: Edition::from_text(text),
        }
    }

    pub fn from_edition_unchecked(edition: Edition) -> Self {
        FeText { edition }
    }

    pub fn empty() -> Self {
        FeText {
            edition: Edition::empty(),
        }
    }

    pub fn count(&self) -> i64 {
        self.edition.count() as i64
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

    pub fn to_text(&self) -> String {
        self.edition.to_text()
    }

    pub fn domain(&self) -> XnRegion {
        self.edition.domain()
    }

    pub fn fetch(&self, pos: i64) -> Option<RangeElement> {
        self.edition.fetch(pos)
    }

    pub fn insert(&self, position: i64, text: &FeText) -> FeText {
        assert!(
            position >= 0 && position <= self.count(),
            "insert position out of range"
        );

        if text.is_empty() {
            return self.clone();
        }
        if self.is_empty() {
            return FeText {
                edition: text.edition.clone(),
            };
        }

        let inserted = text
            .edition
            .transformed_by_mapping(&Mapping::restricted(position, XnRegion::above(0)));

        let before_mapping = Mapping::restricted(0, XnRegion::below(position));
        let after_mapping = Mapping::restricted(text.count(), XnRegion::above(position));
        let original_mapping = before_mapping.combine(&after_mapping);
        let shifted_original = self.edition.transformed_by_mapping(&original_mapping);

        FeText {
            edition: inserted.combine(&shifted_original).unwrap(),
        }
    }

    pub fn extract(&self, region: &XnRegion) -> FeText {
        let actual = region.intersect(&self.edition.domain());
        if actual.is_empty() {
            return FeText::empty();
        }
        let mapping = actual.compactor();
        FeText {
            edition: self.edition.transformed_by_mapping(&mapping),
        }
    }

    pub fn delete(&self, region: &XnRegion) -> FeText {
        let keep = self.edition.domain().minus(region);
        self.extract(&keep)
    }

    pub fn move_range(&self, pos: i64, region: &XnRegion) -> FeText {
        assert!(
            pos >= 0 && pos <= self.count(),
            "move position out of range"
        );

        let moved = self.edition.domain().intersect(region);
        if moved.is_empty() {
            return self.clone();
        }
        let moved_text = self.extract(region);
        let remaining = self.delete(region);
        remaining.insert(pos, &moved_text)
    }

    pub fn replace(&self, dest: &XnRegion, other: &FeText) -> FeText {
        let to = if XnRegion::below(0).intersects(dest) {
            0
        } else if dest.intersects(&self.edition.domain()) {
            dest.intersect(&self.edition.domain()).start().unwrap_or(0)
        } else if XnRegion::above(self.count()).intersects(dest) {
            self.count()
        } else {
            0
        };
        self.extract(&dest.complement()).insert(to, other)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_fetext() {
        let ft = FeText::empty();
        assert!(ft.is_empty());
        assert_eq!(ft.count(), 0);
        assert_eq!(ft.to_text(), "");
    }

    #[test]
    fn from_text_basic() {
        let ft = FeText::from_text("hello");
        assert_eq!(ft.count(), 5);
        assert_eq!(ft.to_text(), "hello");
    }

    #[test]
    fn new_validates_contiguous_zero_based() {
        let edition = Edition::from_text("abc");
        assert!(FeText::new(edition).is_ok());

        let shifted = Edition::from_text("abc").transformed_by(5);
        assert!(matches!(
            FeText::new(shifted),
            Err(FeTextError::NotZeroBased)
        ));
    }

    #[test]
    fn insert_at_beginning() {
        let ft = FeText::from_text("world");
        let ins = FeText::from_text("hello ");
        let result = ft.insert(0, &ins);
        assert_eq!(result.to_text(), "hello world");
    }

    #[test]
    fn insert_at_end() {
        let ft = FeText::from_text("hello");
        let ins = FeText::from_text(" world");
        let result = ft.insert(5, &ins);
        assert_eq!(result.to_text(), "hello world");
    }

    #[test]
    fn insert_in_middle() {
        let ft = FeText::from_text("helo");
        let ins = FeText::from_text("l");
        let result = ft.insert(2, &ins);
        assert_eq!(result.to_text(), "hello");
    }

    #[test]
    fn insert_empty_is_noop() {
        let ft = FeText::from_text("abc");
        let result = ft.insert(1, &FeText::empty());
        assert_eq!(result.to_text(), "abc");
    }

    #[test]
    fn insert_into_empty() {
        let ft = FeText::empty();
        let ins = FeText::from_text("hello");
        let result = ft.insert(0, &ins);
        assert_eq!(result.to_text(), "hello");
    }

    #[test]
    fn extract_simple_range() {
        let ft = FeText::from_text("hello world");
        let region = XnRegion::interval(0, 5);
        let result = ft.extract(&region);
        assert_eq!(result.to_text(), "hello");
    }

    #[test]
    fn extract_middle() {
        let ft = FeText::from_text("hello world");
        let region = XnRegion::interval(6, 11);
        let result = ft.extract(&region);
        assert_eq!(result.to_text(), "world");
    }

    #[test]
    fn extract_disjoint_compacts() {
        let ft = FeText::from_text("ABCDEFGHIJ");
        let region = XnRegion::interval(0, 3).union(&XnRegion::interval(7, 10));
        let result = ft.extract(&region);
        assert_eq!(result.to_text(), "ABCHIJ");
        assert_eq!(result.count(), 6);
    }

    #[test]
    fn extract_empty_region() {
        let ft = FeText::from_text("hello");
        let result = ft.extract(&XnRegion::empty());
        assert!(result.is_empty());
    }

    #[test]
    fn delete_range() {
        let ft = FeText::from_text("hello world");
        let region = XnRegion::interval(5, 11);
        let result = ft.delete(&region);
        assert_eq!(result.to_text(), "hello");
    }

    #[test]
    fn delete_middle() {
        let ft = FeText::from_text("hello world");
        let region = XnRegion::interval(5, 6);
        let result = ft.delete(&region);
        assert_eq!(result.to_text(), "helloworld");
    }

    #[test]
    fn move_range_basic() {
        let ft = FeText::from_text("ABCDEFGHIJ");
        let region = XnRegion::interval(3, 6);
        let result = ft.move_range(2, &region);
        assert_eq!(result.to_text(), "ABDEFCGHIJ");
    }

    #[test]
    fn move_range_to_end() {
        let ft = FeText::from_text("ABCDEFGHIJ");
        let region = XnRegion::interval(0, 3);
        let result = ft.move_range(7, &region);
        assert_eq!(result.to_text(), "DEFGHIJABC");
    }

    #[test]
    fn move_range_to_beginning() {
        let ft = FeText::from_text("ABCDEFGHIJ");
        let region = XnRegion::interval(7, 10);
        let result = ft.move_range(0, &region);
        assert_eq!(result.to_text(), "HIJABCDEFG");
    }

    #[test]
    fn move_empty_region_is_noop() {
        let ft = FeText::from_text("hello");
        let result = ft.move_range(2, &XnRegion::empty());
        assert_eq!(result.to_text(), "hello");
    }

    #[test]
    fn replace_region() {
        let ft = FeText::from_text("hello world");
        let dest = XnRegion::interval(6, 11);
        let replacement = FeText::from_text("there");
        let result = ft.replace(&dest, &replacement);
        assert_eq!(result.to_text(), "hello there");
    }

    #[test]
    fn replace_with_shorter() {
        let ft = FeText::from_text("hello world");
        let dest = XnRegion::interval(5, 11);
        let replacement = FeText::from_text("!");
        let result = ft.replace(&dest, &replacement);
        assert_eq!(result.to_text(), "hello!");
    }

    #[test]
    fn replace_with_longer() {
        let ft = FeText::from_text("hi");
        let dest = XnRegion::interval(1, 2);
        let replacement = FeText::from_text("ello");
        let result = ft.replace(&dest, &replacement);
        assert_eq!(result.to_text(), "hello");
    }

    #[test]
    fn insert_chain() {
        let ft = FeText::from_text("world");
        let result = ft
            .insert(0, &FeText::from_text("hello "))
            .insert(11, &FeText::from_text("!"));
        assert_eq!(result.to_text(), "hello world!");
    }

    #[test]
    fn delete_then_insert_is_replace() {
        let ft = FeText::from_text("hello world");
        let dest = XnRegion::interval(5, 6);
        let deleted = ft.delete(&dest);
        let result = deleted.insert(5, &FeText::from_text("-"));
        assert_eq!(result.to_text(), "hello-world");
    }

    #[test]
    fn extract_preserves_elements() {
        let ft = FeText::from_text("ABC");
        let _elem0 = ft.fetch(0).unwrap();
        let extracted = ft.extract(&XnRegion::interval(1, 3));
        let elem0_new = extracted.fetch(0).unwrap();
        assert_eq!(elem0_new.as_text(), Some("B"));
    }

    #[test]
    fn compactor_contiguous_is_shift() {
        let region = XnRegion::interval(5, 10);
        let mapping = region.compactor();
        assert_eq!(mapping.of(5), Some(0));
        assert_eq!(mapping.of(9), Some(4));
        assert_eq!(mapping.of(10), None);
    }

    #[test]
    fn compactor_disjoint_renumbers() {
        let region = XnRegion::interval(3, 6).union(&XnRegion::interval(10, 13));
        let mapping = region.compactor();
        assert_eq!(mapping.of(3), Some(0));
        assert_eq!(mapping.of(5), Some(2));
        assert_eq!(mapping.of(10), Some(3));
        assert_eq!(mapping.of(12), Some(5));
        assert_eq!(mapping.of(6), None);
    }

    #[test]
    fn multiple_operations_sequence() {
        let ft = FeText::from_text("The quick brown fox");
        let ft2 = ft.delete(&XnRegion::interval(4, 10));
        assert_eq!(ft2.to_text(), "The brown fox");
        let ft3 = ft2.insert(4, &FeText::from_text("lazy "));
        assert_eq!(ft3.to_text(), "The lazy brown fox");
    }

    #[test]
    fn move_preserves_all_content() {
        let ft = FeText::from_text("ABCDEFGHIJ");
        let moved = ft.move_range(0, &XnRegion::interval(5, 10));
        assert_eq!(moved.count(), 10);
        let text = moved.to_text();
        let original_chars: Vec<char> = "ABCDEFGHIJ".chars().collect();
        let moved_chars: Vec<char> = text.chars().collect();
        let mut sorted_orig: Vec<char> = original_chars.clone();
        let mut sorted_moved: Vec<char> = moved_chars.clone();
        sorted_orig.sort();
        sorted_moved.sort();
        assert_eq!(sorted_orig, sorted_moved);
    }
}
