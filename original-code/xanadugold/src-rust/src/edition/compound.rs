use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CompoundSpan {
    source_work_id: u64,
    char_start: usize,
    char_end: usize,
}

impl CompoundSpan {
    pub fn new(source_work_id: u64, char_start: usize, char_end: usize) -> Self {
        let (start, end) = if char_start <= char_end {
            (char_start, char_end)
        } else {
            (char_end, char_start)
        };
        CompoundSpan {
            source_work_id,
            char_start: start,
            char_end: end,
        }
    }

    pub fn source_work_id(&self) -> u64 {
        self.source_work_id
    }

    pub fn char_start(&self) -> usize {
        self.char_start
    }

    pub fn char_end(&self) -> usize {
        self.char_end
    }

    pub fn char_len(&self) -> usize {
        self.char_end.saturating_sub(self.char_start)
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum CompoundElement {
    Text { content: String },
    Span { span: CompoundSpan },
}

impl CompoundElement {
    pub fn text(content: impl Into<String>) -> Self {
        CompoundElement::Text {
            content: content.into(),
        }
    }

    pub fn span(source_work_id: u64, char_start: usize, char_end: usize) -> Self {
        CompoundElement::Span {
            span: CompoundSpan::new(source_work_id, char_start, char_end),
        }
    }

    pub fn text_content(&self) -> Option<&str> {
        match self {
            CompoundElement::Text { content } => Some(content),
            CompoundElement::Span { .. } => None,
        }
    }

    pub fn span_content(&self) -> Option<&CompoundSpan> {
        match self {
            CompoundElement::Text { .. } => None,
            CompoundElement::Span { span } => Some(span),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CompoundEdition {
    elements: Vec<CompoundElement>,
}

impl CompoundEdition {
    pub fn new(elements: Vec<CompoundElement>) -> Self {
        CompoundEdition { elements }
    }

    pub fn empty() -> Self {
        CompoundEdition { elements: Vec::new() }
    }

    pub fn elements(&self) -> &[CompoundElement] {
        &self.elements
    }

    pub fn push(&mut self, element: CompoundElement) {
        self.elements.push(element);
    }

    pub fn is_empty(&self) -> bool {
        self.elements.is_empty()
    }

    pub fn len(&self) -> usize {
        self.elements.len()
    }

    pub fn referenced_works(&self) -> Vec<u64> {
        let mut works: Vec<u64> = self
            .elements
            .iter()
            .filter_map(|e| e.span_content().map(|s| s.source_work_id()))
            .collect();
        works.sort();
        works.dedup();
        works
    }

    pub fn span_count(&self) -> usize {
        self.elements
            .iter()
            .filter(|e| matches!(e, CompoundElement::Span { .. }))
            .count()
    }

    pub fn text_count(&self) -> usize {
        self.elements
            .iter()
            .filter(|e| matches!(e, CompoundElement::Text { .. }))
            .count()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn compound_span_new() {
        let span = CompoundSpan::new(1, 10, 20);
        assert_eq!(span.source_work_id(), 1);
        assert_eq!(span.char_start(), 10);
        assert_eq!(span.char_end(), 20);
        assert_eq!(span.char_len(), 10);
    }

    #[test]
    fn compound_span_zero_len() {
        let span = CompoundSpan::new(5, 10, 10);
        assert_eq!(span.char_len(), 0);
    }

    #[test]
    fn compound_element_text() {
        let elem = CompoundElement::text("hello");
        assert_eq!(elem.text_content(), Some("hello"));
        assert!(elem.span_content().is_none());
    }

    #[test]
    fn compound_element_span() {
        let elem = CompoundElement::span(42, 0, 100);
        assert!(elem.text_content().is_none());
        let span = elem.span_content().unwrap();
        assert_eq!(span.source_work_id(), 42);
    }

    #[test]
    fn compound_edition_empty() {
        let ed = CompoundEdition::empty();
        assert!(ed.is_empty());
        assert_eq!(ed.len(), 0);
    }

    #[test]
    fn compound_edition_mixed() {
        let ed = CompoundEdition::new(vec![
            CompoundElement::text("prefix "),
            CompoundElement::span(1, 0, 50),
            CompoundElement::text(" suffix"),
        ]);
        assert_eq!(ed.len(), 3);
        assert_eq!(ed.text_count(), 2);
        assert_eq!(ed.span_count(), 1);
    }

    #[test]
    fn compound_edition_referenced_works() {
        let ed = CompoundEdition::new(vec![
            CompoundElement::span(1, 0, 10),
            CompoundElement::text("middle"),
            CompoundElement::span(2, 0, 10),
            CompoundElement::span(1, 10, 20),
        ]);
        let works = ed.referenced_works();
        assert_eq!(works, vec![1, 2]);
    }

    #[test]
    fn compound_edition_push() {
        let mut ed = CompoundEdition::empty();
        ed.push(CompoundElement::text("a"));
        ed.push(CompoundElement::span(1, 0, 5));
        assert_eq!(ed.len(), 2);
    }

    #[test]
    fn compound_edition_serde_roundtrip() {
        let ed = CompoundEdition::new(vec![
            CompoundElement::text("hello "),
            CompoundElement::span(42, 10, 20),
            CompoundElement::text(" world"),
        ]);
        let json = serde_json::to_string(&ed).unwrap();
        let restored: CompoundEdition = serde_json::from_str(&json).unwrap();
        assert_eq!(ed, restored);
    }
}
