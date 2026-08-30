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

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum DeltaOp {
    Retain(usize),
    Insert(usize),
    Delete(usize),
}

pub fn map_span_through_delta(
    span_start: usize,
    span_end: usize,
    ops: &[DeltaOp],
) -> (usize, usize) {
    // Algebraic implementation using Mapping
    let span = super::xn_region::XnRegion::interval(span_start as i64, span_end as i64);

    let mut pos: i64 = 0;
    let mut displacement: i64 = 0;
    let mut parts: Vec<(i64, i64, i64)> = Vec::new();

    for op in ops {
        match *op {
            DeltaOp::Retain(count) => {
                let end = pos + count as i64;
                parts.push((pos, end, displacement));
                pos = end;
            }
            DeltaOp::Insert(ins_len) => {
                displacement += ins_len as i64;
            }
            DeltaOp::Delete(count) => {
                pos += count as i64;
                displacement -= count as i64;
            }
        }
    }

    // The tail after the last op keeps the final displacement.
    // Without this part, insert-only deltas (no trailing retain —
    // the common client shape) collapsed to identity via the
    // all-zero-offset shortcut and never shifted following spans
    // (FR-50 finding 8, caught by the window-guard armor).
    parts.push((pos, i64::MAX, displacement));

    // If there are no retained regions, algebra can't build a displacement.
    // Fall back to imperative logic which handles replace semantics.
    if parts.len() <= 1 && parts[0].2 == 0 {
        return map_span_through_delta_imperative(span_start, span_end, ops);
    }

    let dsp = if parts.iter().all(|(_, _, off)| *off == 0) {
        super::mapping::Mapping::identity()
    } else {
        let mappings: Vec<super::mapping::Mapping> = parts
            .iter()
            .map(|(start, end, off)| {
                super::mapping::Mapping::restricted(
                    *off,
                    super::xn_region::XnRegion::interval(*start, *end),
                )
            })
            .collect();
        super::mapping::Mapping::from_parts(mappings)
    };

    let new_span = dsp.of_region(&span);

    if !new_span.is_empty() {
        // Algebraic result is valid
        if let Some((start, end)) = new_span.as_interval() {
            let s = start.max(0) as usize;
            let e = (end as usize).max(s);
            return (s, e);
        }
        let intervals = new_span.intervals();
        if !intervals.is_empty() {
            let s = intervals[0].0.max(0) as usize;
            let e = (intervals.last().unwrap().1 as usize).max(s);
            return (s, e);
        }
    }

    // Fall back to imperative logic for edge cases
    // (e.g., span entirely within a delete-then-insert replacement)
    map_span_through_delta_imperative(span_start, span_end, ops)
}

fn map_span_through_delta_imperative(
    span_start: usize,
    span_end: usize,
    ops: &[DeltaOp],
) -> (usize, usize) {
    let mut old_pos: usize = 0;
    let mut new_pos: usize = 0;
    let mut result_start = span_start;
    let mut result_end = span_end;
    let mut start_mapped = false;
    let mut end_mapped = false;

    for (i, op) in ops.iter().enumerate() {
        match *op {
            DeltaOp::Retain(count) => {
                if !start_mapped && span_start >= old_pos && span_start < old_pos + count {
                    result_start = new_pos + (span_start - old_pos);
                    start_mapped = true;
                }
                if !end_mapped && span_end >= old_pos && span_end < old_pos + count {
                    result_end = new_pos + (span_end - old_pos);
                    end_mapped = true;
                }
                old_pos += count;
                new_pos += count;
            }
            DeltaOp::Insert(ins_len) => {
                if !start_mapped && old_pos == span_start {
                    result_start = new_pos + ins_len;
                    start_mapped = true;
                }
                if !end_mapped && old_pos == span_end {
                    result_end = new_pos;
                    end_mapped = true;
                }
                new_pos += ins_len;
            }
            DeltaOp::Delete(count) => {
                let del_start = old_pos;
                let del_end = old_pos + count;

                if !start_mapped && span_start >= del_start && span_start < del_end {
                    result_start = new_pos;
                    start_mapped = true;
                }

                if !end_mapped && span_end > del_start && span_end <= del_end {
                    let mut extra = 0;
                    for j in (i + 1)..ops.len() {
                        match ops[j] {
                            DeltaOp::Insert(len) => extra += len,
                            _ => break,
                        }
                    }
                    result_end = new_pos + extra;
                    end_mapped = true;
                }

                old_pos += count;
            }
        }
    }

    if !start_mapped && span_start == old_pos {
        result_start = new_pos;
    }
    if !end_mapped && span_end == old_pos {
        result_end = new_pos;
    }

    if result_start > result_end {
        result_start = result_end;
    }

    (result_start, result_end)
}

pub fn compute_text_delta(old: &str, new: &str) -> Vec<DeltaOp> {
    let old_chars: Vec<char> = old.chars().collect();
    let new_chars: Vec<char> = new.chars().collect();
    let old_len = old_chars.len();
    let new_len = new_chars.len();

    let prefix = old_chars
        .iter()
        .zip(new_chars.iter())
        .take_while(|(a, b)| a == b)
        .count();
    let max_suffix = old_len
        .saturating_sub(prefix)
        .min(new_len.saturating_sub(prefix));
    let suffix = (0..max_suffix)
        .take_while(|&i| old_chars[old_len - 1 - i] == new_chars[new_len - 1 - i])
        .count();

    let mut ops = Vec::new();
    if prefix > 0 {
        ops.push(DeltaOp::Retain(prefix));
    }
    let delete_len = old_len - prefix - suffix;
    if delete_len > 0 {
        ops.push(DeltaOp::Delete(delete_len));
    }
    let insert_len = new_len - prefix - suffix;
    if insert_len > 0 {
        ops.push(DeltaOp::Insert(insert_len));
    }
    if suffix > 0 {
        ops.push(DeltaOp::Retain(suffix));
    }
    ops
}

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

    pub fn set_offsets(&mut self, start: usize, end: usize) {
        self.char_start = start;
        self.char_end = end;
    }

    pub fn migrate_for_delta(&mut self, ops: &[DeltaOp]) {
        let (new_start, new_end) = map_span_through_delta(self.char_start, self.char_end, ops);
        self.char_start = new_start;
        self.char_end = new_end;
    }

    /// Convert this span to a tumbler address using a document arrangement.
    /// Produces `"server".work_id.char_start.char_end`.
    pub fn to_tumbler(
        &self,
        arrangement: &super::tumbler::DocumentArrangement,
    ) -> super::tumbler::XudanuTumbler {
        arrangement.to_tumbler_range(self.char_start as i64, self.char_end as i64)
    }

    /// Construct a CompoundSpan from a tumbler address.
    /// The tumbler must have at least 3 path elements: [work_id, start, end].
    pub fn from_tumbler(tumbler: &super::tumbler::XudanuTumbler) -> Option<Self> {
        let path = tumbler.path();
        if path.len() < 3 {
            return None;
        }
        Some(CompoundSpan::new(
            path[0],
            path[1] as usize,
            path[2] as usize,
        ))
    }

    /// Check if this span references the same source as another.
    pub fn same_source(&self, other: &CompoundSpan) -> bool {
        self.source_work_id == other.source_work_id
    }

    /// Check if this span overlaps with another (same source, overlapping ranges).
    pub fn overlaps(&self, other: &CompoundSpan) -> bool {
        self.source_work_id == other.source_work_id
            && self.char_start < other.char_end
            && other.char_start < self.char_end
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "serde", serde(tag = "type", rename_all = "snake_case"))]
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

    pub fn span_content_mut(&mut self) -> Option<&mut CompoundSpan> {
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

    pub fn insert(&mut self, index: usize, element: CompoundElement) {
        if index >= self.elements.len() {
            self.elements.push(element);
        } else {
            self.elements.insert(index, element);
        }
    }

    pub fn remove(&mut self, index: usize) -> Option<CompoundElement> {
        if index < self.elements.len() {
            Some(self.elements.remove(index))
        } else {
            None
        }
    }

    pub fn move_element(&mut self, from: usize, to: usize) {
        if from >= self.elements.len() || to >= self.elements.len() {
            return;
        }
        let elem = self.elements.remove(from);
        self.elements.insert(to, elem);
    }

    pub fn clear(&mut self) {
        self.elements.clear();
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

    pub fn migrate_spans_for_delta(&mut self, source_work_id: u64, ops: &[DeltaOp]) {
        for element in &mut self.elements {
            if let Some(span) = element.span_content_mut() {
                if span.source_work_id() == source_work_id {
                    span.migrate_for_delta(ops);
                }
            }
        }
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
                        otree_position: 0,
                        resolved_content: content.clone(),
                        placed_at: 0,
                        placed_by: None,
                        source_changed: false,
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
    pub otree_position: usize,
    pub resolved_content: String,
    #[cfg_attr(feature = "serde", serde(default))]
    pub placed_at: u64,
    #[cfg_attr(feature = "serde", serde(default))]
    pub placed_by: Option<u64>,
    #[cfg_attr(feature = "serde", serde(default))]
    pub source_changed: bool,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[cfg_attr(feature = "serde", serde(tag = "type", rename_all = "snake_case"))]
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

    #[test]
    fn span_migrate_insert_before_span() {
        let mut span = CompoundSpan::new(1, 10, 19);
        span.migrate_for_delta(&[DeltaOp::Retain(5), DeltaOp::Insert(2), DeltaOp::Retain(35)]);
        assert_eq!(span.char_start(), 12);
        assert_eq!(span.char_end(), 21);
    }

    #[test]
    fn span_migrate_insert_at_start() {
        let mut span = CompoundSpan::new(1, 10, 19);
        span.migrate_for_delta(&[DeltaOp::Retain(10), DeltaOp::Insert(2), DeltaOp::Retain(30)]);
        assert_eq!(span.char_start(), 12);
        assert_eq!(span.char_end(), 21);
    }

    #[test]
    fn span_migrate_insert_at_end() {
        let mut span = CompoundSpan::new(1, 10, 19);
        span.migrate_for_delta(&[DeltaOp::Retain(19), DeltaOp::Insert(2), DeltaOp::Retain(21)]);
        assert_eq!(span.char_start(), 10);
        assert_eq!(span.char_end(), 19);
    }

    #[test]
    fn span_migrate_insert_inside_span() {
        let mut span = CompoundSpan::new(1, 10, 19);
        span.migrate_for_delta(&[DeltaOp::Retain(15), DeltaOp::Insert(3), DeltaOp::Retain(22)]);
        assert_eq!(span.char_start(), 10);
        assert_eq!(span.char_end(), 22);
    }

    #[test]
    fn span_migrate_delete_before_span() {
        let mut span = CompoundSpan::new(1, 10, 19);
        span.migrate_for_delta(&[DeltaOp::Retain(5), DeltaOp::Delete(3), DeltaOp::Retain(32)]);
        assert_eq!(span.char_start(), 7);
        assert_eq!(span.char_end(), 16);
    }

    #[test]
    fn span_migrate_delete_entire_span() {
        let mut span = CompoundSpan::new(1, 10, 19);
        span.migrate_for_delta(&[DeltaOp::Retain(10), DeltaOp::Delete(9), DeltaOp::Retain(25)]);
        assert_eq!(span.char_len(), 0);
        assert_eq!(span.char_start(), 10);
    }

    #[test]
    fn span_migrate_replace_span_content() {
        // Simulate: "brown fox" (9 chars at pos 10) replaced with "red fox" (7 chars)
        let mut span = CompoundSpan::new(1, 10, 19);
        span.migrate_for_delta(&[
            DeltaOp::Retain(10),
            DeltaOp::Delete(9),
            DeltaOp::Insert(7),
            DeltaOp::Retain(25),
        ]);
        assert_eq!(span.char_start(), 10);
        assert_eq!(span.char_end(), 17);
        assert_eq!(span.char_len(), 7);
    }

    #[test]
    fn span_migrate_no_op() {
        let mut span = CompoundSpan::new(1, 10, 19);
        span.migrate_for_delta(&[DeltaOp::Retain(44)]);
        assert_eq!(span.char_start(), 10);
        assert_eq!(span.char_end(), 19);
    }

    #[test]
    fn span_migrate_delete_partial_start() {
        // Delete overlaps span start: delete 5..12, span is 10..19
        let mut span = CompoundSpan::new(1, 10, 19);
        span.migrate_for_delta(&[DeltaOp::Retain(5), DeltaOp::Delete(7), DeltaOp::Retain(28)]);
        // Start clamps to 5 (deletion start in new text)
        assert_eq!(span.char_start(), 5);
        // End shifts left by 7: 19 - 7 = 12
        assert_eq!(span.char_end(), 12);
    }

    #[test]
    fn span_migrate_delete_partial_end() {
        // Delete overlaps span end: delete 15..20, span is 10..19
        let mut span = CompoundSpan::new(1, 10, 19);
        span.migrate_for_delta(&[DeltaOp::Retain(15), DeltaOp::Delete(5), DeltaOp::Retain(20)]);
        // Start unchanged
        assert_eq!(span.char_start(), 10);
        // End clamps to 15 (deletion start in new text)
        assert_eq!(span.char_end(), 15);
    }

    #[test]
    fn edition_migrate_spans_for_delta_matches_source() {
        let mut ed = CompoundEdition::new(vec![
            CompoundElement::text("prefix "),
            CompoundElement::span(1, 5, 10),
            CompoundElement::text(" middle "),
            CompoundElement::span(2, 0, 3),
            CompoundElement::text(" suffix"),
        ]);

        // Only migrate spans referencing work 1 — insert 3 chars before position 5
        ed.migrate_spans_for_delta(
            1,
            &[DeltaOp::Retain(3), DeltaOp::Insert(3), DeltaOp::Retain(50)],
        );

        let s1 = ed.elements()[1].span_content().unwrap();
        assert_eq!(s1.char_start(), 8);
        assert_eq!(s1.char_end(), 13);

        let s2 = ed.elements()[3].span_content().unwrap();
        assert_eq!(s2.char_start(), 0);
        assert_eq!(s2.char_end(), 3);
    }

    #[test]
    fn map_span_through_delta_replace_at_start() {
        // Full replace scenario: text ABCDE, span (0, 3) = "ABC"
        // Replace "ABC" with "XYZ"
        let (s, e) = map_span_through_delta(
            0,
            3,
            &[DeltaOp::Delete(3), DeltaOp::Insert(3), DeltaOp::Retain(2)],
        );
        assert_eq!(s, 0);
        assert_eq!(e, 3);
    }

    #[test]
    fn compound_span_to_tumbler() {
        let span = CompoundSpan::new(5, 10, 20);
        let arr = super::super::tumbler::DocumentArrangement::new("alice.com", 5);
        let t = span.to_tumbler(&arr);
        assert_eq!(t.server(), "alice.com");
        assert_eq!(t.path(), &[5, 10, 20]);
    }

    #[test]
    fn compound_span_from_tumbler() {
        let t = super::super::tumbler::XudanuTumbler::cross("alice.com", vec![5, 10, 20]);
        let span = CompoundSpan::from_tumbler(&t).unwrap();
        assert_eq!(span.source_work_id(), 5);
        assert_eq!(span.char_start(), 10);
        assert_eq!(span.char_end(), 20);
    }

    #[test]
    fn compound_span_from_tumbler_too_short() {
        let t = super::super::tumbler::XudanuTumbler::cross("alice.com", vec![5]);
        assert!(CompoundSpan::from_tumbler(&t).is_none());
    }

    #[test]
    fn compound_span_overlaps() {
        let a = CompoundSpan::new(5, 10, 20);
        let b = CompoundSpan::new(5, 15, 25);
        let c = CompoundSpan::new(5, 20, 30);
        let d = CompoundSpan::new(6, 10, 20);

        assert!(a.overlaps(&b), "overlapping ranges same source");
        assert!(!a.overlaps(&c), "adjacent ranges don't overlap");
        assert!(!a.overlaps(&d), "different source doesn't overlap");
    }

    #[test]
    fn compound_span_same_source() {
        let a = CompoundSpan::new(5, 0, 10);
        let b = CompoundSpan::new(5, 20, 30);
        let c = CompoundSpan::new(6, 0, 10);

        assert!(a.same_source(&b));
        assert!(!a.same_source(&c));
    }

    #[test]
    fn compound_span_tumbler_roundtrip() {
        let span = CompoundSpan::new(42, 100, 200);
        let arr = super::super::tumbler::DocumentArrangement::new("bob.com", 42);
        let tumbler = span.to_tumbler(&arr);
        let back = CompoundSpan::from_tumbler(&tumbler).unwrap();
        assert_eq!(back.source_work_id(), 42);
        assert_eq!(back.char_start(), 100);
        assert_eq!(back.char_end(), 200);
    }
}
