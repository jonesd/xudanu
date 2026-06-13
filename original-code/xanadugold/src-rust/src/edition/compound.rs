use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq)]
pub enum ResolveError {
    SourceNotFound { work_id: u64 },
    SourceFetchFailed { work_id: u64 },
}

impl std::fmt::Display for ResolveError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ResolveError::SourceNotFound { work_id } => {
                write!(f, "source work {} not found", work_id)
            }
            ResolveError::SourceFetchFailed { work_id } => {
                write!(f, "failed to fetch text from source work {}", work_id)
            }
        }
    }
}

impl std::error::Error for ResolveError {}

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
        CompoundEdition {
            elements: Vec::new(),
        }
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

    pub fn resolve<F>(&self, fetcher: F) -> Result<ResolvedCompoundEdition, ResolveError>
    where
        F: Fn(u64) -> Result<String, ResolveError>,
    {
        let mut resolved_elements = Vec::with_capacity(self.elements.len());
        let mut flat_text = String::new();
        let mut span_ranges = Vec::new();

        for elem in &self.elements {
            match elem {
                CompoundElement::Text { content } => {
                    let start = flat_text.chars().count();
                    flat_text.push_str(content);
                    let end = flat_text.chars().count();
                    resolved_elements.push(ResolvedElement::Text {
                        content: content.clone(),
                        flat_start: start,
                        flat_end: end,
                    });
                }
                CompoundElement::Span { span } => {
                    let source_text = fetcher(span.source_work_id())?;
                    let src_chars: Vec<char> = source_text.chars().collect();
                    let start = span.char_start().min(src_chars.len());
                    let end = span.char_end().min(src_chars.len());
                    let content: String = src_chars[start..end].iter().collect();

                    let flat_start = flat_text.chars().count();
                    flat_text.push_str(&content);
                    let flat_end = flat_text.chars().count();

                    span_ranges.push(SpanRange {
                        source_work_id: span.source_work_id(),
                        char_start: span.char_start(),
                        char_end: span.char_end(),
                        flat_start,
                        flat_end,
                        content_len: content.chars().count(),
                    });

                    resolved_elements.push(ResolvedElement::Span {
                        source_work_id: span.source_work_id(),
                        content,
                        flat_start,
                        flat_end,
                        original_char_start: span.char_start(),
                        original_char_end: span.char_end(),
                    });
                }
            }
        }

        Ok(ResolvedCompoundEdition {
            elements: resolved_elements,
            flat_text,
            span_ranges,
        })
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SpanRange {
    pub source_work_id: u64,
    pub char_start: usize,
    pub char_end: usize,
    pub flat_start: usize,
    pub flat_end: usize,
    pub content_len: usize,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ResolvedElement {
    Text {
        content: String,
        flat_start: usize,
        flat_end: usize,
    },
    Span {
        source_work_id: u64,
        content: String,
        flat_start: usize,
        flat_end: usize,
        original_char_start: usize,
        original_char_end: usize,
    },
}

impl ResolvedElement {
    pub fn flat_start(&self) -> usize {
        match self {
            ResolvedElement::Text { flat_start, .. } => *flat_start,
            ResolvedElement::Span { flat_start, .. } => *flat_start,
        }
    }

    pub fn flat_end(&self) -> usize {
        match self {
            ResolvedElement::Text { flat_end, .. } => *flat_end,
            ResolvedElement::Span { flat_end, .. } => *flat_end,
        }
    }

    pub fn is_span(&self) -> bool {
        matches!(self, ResolvedElement::Span { .. })
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ResolvedCompoundEdition {
    elements: Vec<ResolvedElement>,
    flat_text: String,
    span_ranges: Vec<SpanRange>,
}

impl ResolvedCompoundEdition {
    pub fn elements(&self) -> &[ResolvedElement] {
        &self.elements
    }

    pub fn flat_text(&self) -> &str {
        &self.flat_text
    }

    pub fn span_ranges(&self) -> &[SpanRange] {
        &self.span_ranges
    }

    pub fn is_empty(&self) -> bool {
        self.elements.is_empty()
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

    #[test]
    fn resolve_text_only() {
        let ed = CompoundEdition::new(vec![
            CompoundElement::text("hello "),
            CompoundElement::text("world"),
        ]);
        let resolved = ed
            .resolve(|_| Err(ResolveError::SourceNotFound { work_id: 0 }))
            .unwrap();
        assert_eq!(resolved.flat_text(), "hello world");
        assert!(resolved.span_ranges().is_empty());
        assert_eq!(resolved.elements().len(), 2);
    }

    #[test]
    fn resolve_mixed_content() {
        let ed = CompoundEdition::new(vec![
            CompoundElement::text("prefix "),
            CompoundElement::span(1, 0, 5),
            CompoundElement::text(" suffix"),
        ]);
        let resolved = ed
            .resolve(|wid| {
                assert_eq!(wid, 1);
                Ok("ABCDEFGHIJ".to_string())
            })
            .unwrap();
        assert_eq!(resolved.flat_text(), "prefix ABCDE suffix");
        assert_eq!(resolved.span_ranges().len(), 1);
        let sr = &resolved.span_ranges()[0];
        assert_eq!(sr.source_work_id, 1);
        assert_eq!(sr.flat_start, 7);
        assert_eq!(sr.flat_end, 12);
    }

    #[test]
    fn resolve_span_clamps_to_source_length() {
        let ed = CompoundEdition::new(vec![CompoundElement::span(1, 0, 100)]);
        let resolved = ed.resolve(|_| Ok("short".to_string())).unwrap();
        assert_eq!(resolved.flat_text(), "short");
        assert_eq!(resolved.span_ranges()[0].content_len, 5);
    }

    #[test]
    fn resolve_source_not_found() {
        let ed = CompoundEdition::new(vec![CompoundElement::span(99, 0, 5)]);
        let result = ed.resolve(|wid| {
            assert_eq!(wid, 99);
            Err(ResolveError::SourceNotFound { work_id: wid })
        });
        assert!(result.is_err());
    }

    #[test]
    fn resolve_unicode_content() {
        let ed = CompoundEdition::new(vec![
            CompoundElement::text("café "),
            CompoundElement::span(1, 0, 3),
        ]);
        let resolved = ed.resolve(|_| Ok("日本語テスト".to_string())).unwrap();
        assert_eq!(resolved.flat_text(), "café 日本語");
        assert_eq!(resolved.span_ranges()[0].flat_start, 5);
        assert_eq!(resolved.span_ranges()[0].flat_end, 8);
    }

    #[test]
    fn resolve_multiple_spans_same_source() {
        let ed = CompoundEdition::new(vec![
            CompoundElement::span(1, 0, 3),
            CompoundElement::text("-"),
            CompoundElement::span(1, 3, 6),
        ]);
        let resolved = ed.resolve(|_| Ok("ABCDEF".to_string())).unwrap();
        assert_eq!(resolved.flat_text(), "ABC-DEF");
        assert_eq!(resolved.span_ranges().len(), 2);
        assert_eq!(resolved.span_ranges()[0].flat_start, 0);
        assert_eq!(resolved.span_ranges()[1].flat_start, 4);
    }

    #[test]
    fn resolved_element_helpers() {
        let ed = CompoundEdition::new(vec![
            CompoundElement::text("ab"),
            CompoundElement::span(1, 0, 3),
        ]);
        let resolved = ed.resolve(|_| Ok("XYZ".to_string())).unwrap();
        assert!(!resolved.elements()[0].is_span());
        assert!(resolved.elements()[1].is_span());
        assert_eq!(resolved.elements()[0].flat_start(), 0);
        assert_eq!(resolved.elements()[0].flat_end(), 2);
        assert_eq!(resolved.elements()[1].flat_start(), 2);
        assert_eq!(resolved.elements()[1].flat_end(), 5);
    }

    #[test]
    fn resolved_compound_serde_roundtrip() {
        let ed = CompoundEdition::new(vec![
            CompoundElement::text("hello "),
            CompoundElement::span(42, 10, 20),
            CompoundElement::text(" world"),
        ]);
        let resolved = ed
            .resolve(|_| Ok("0123456789ABCDEFGHIJ".to_string()))
            .unwrap();
        let json = serde_json::to_string(&resolved).unwrap();
        let restored: ResolvedCompoundEdition = serde_json::from_str(&json).unwrap();
        assert_eq!(resolved, restored);
    }
}
