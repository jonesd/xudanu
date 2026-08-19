//! Document structure invariants — the syntax gate.
//!
//! Every document arriving from an untrusted boundary (federation
//! peer, wire frame, restored chunk) passes through
//! [`validate_edition`] before its contents may touch server state.
//! The validator enforces well-formedness of entries, spans, and
//! provenance; it does NOT judge content truth — that is the
//! signature/trust layer's job (parse, don't validate: the guarantee
//! is carried by returning a typed report, not by hoping).
//!
//! Design rule: the validator is total — it returns a report for ANY
//! input, never panics, never allocates proportional to attacker
//! data beyond the caller's caps.

use crate::edition::range_element::{Carrier, RangeElement};
use crate::edition::Edition;

/// Hard caps a single edition may not exceed at the trust boundary.
/// Larger documents are structurally suspect (resource exhaustion)
/// regardless of content.
pub const MAX_ENTRIES: usize = 1_000_000;
pub const MAX_SPANS: usize = 100_000;
pub const MAX_TEXT_CHARS: usize = 50_000_000;
pub const MAX_TEXT_ENTRY_CHARS: usize = 1_000_000;
pub const MAX_TRANSCLUSION_DEPTH: usize = 32;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct InvariantViolation {
    pub code: ViolationCode,
    pub detail: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ViolationCode {
    /// Entry positions not strictly increasing (overlap/disorder).
    EntryPositionsUnordered,
    /// Duplicate entry position.
    DuplicatePosition,
    /// No entries at all in a non-empty edition context.
    EmptyEdition,
    /// Entry count exceeds MAX_ENTRIES.
    TooManyEntries,
    /// Text entry exceeds MAX_TEXT_ENTRY_CHARS.
    TextEntryTooLarge,
    /// Total text exceeds MAX_TEXT_CHARS.
    TotalTextTooLarge,
    /// Text entry contains forbidden control characters.
    ControlCharacters,
    /// Span list not sorted / overlapping.
    SpansUnorderedOrOverlapping,
    /// Span bounds outside the document's character range.
    SpanOutOfBounds,
    /// Zero-length span.
    EmptySpan,
    /// Span count exceeds MAX_SPANS.
    TooManySpans,
    /// Transclusion char range invalid (start >= end) or reversed.
    TransclusionRangeInvalid,
    /// Transclusion references its own work (self-cycle).
    TransclusionSelfCycle,
    /// Transclusion range exceeds plausible document bounds.
    TransclusionRangeTooLarge,
    /// Provenance public key is not a valid Ed25519 key shape.
    InvalidAuthorKey,
    /// Provenance timestamp is zero (unsigned authorship).
    ZeroTimestamp,
    /// Blob byte_size or mime_type implausible/absurd.
    ImplausibleBlob,
    /// Placeholder/label ids that are structurally meaningless.
    InvalidElementId,
}

impl std::fmt::Display for ViolationCode {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let name = match self {
            ViolationCode::EntryPositionsUnordered => "entry_positions_unordered",
            ViolationCode::DuplicatePosition => "duplicate_position",
            ViolationCode::EmptyEdition => "empty_edition",
            ViolationCode::TooManyEntries => "too_many_entries",
            ViolationCode::TextEntryTooLarge => "text_entry_too_large",
            ViolationCode::TotalTextTooLarge => "total_text_too_large",
            ViolationCode::ControlCharacters => "control_characters",
            ViolationCode::SpansUnorderedOrOverlapping => "spans_unordered_or_overlapping",
            ViolationCode::SpanOutOfBounds => "span_out_of_bounds",
            ViolationCode::EmptySpan => "empty_span",
            ViolationCode::TooManySpans => "too_many_spans",
            ViolationCode::TransclusionRangeInvalid => "transclusion_range_invalid",
            ViolationCode::TransclusionSelfCycle => "transclusion_self_cycle",
            ViolationCode::TransclusionRangeTooLarge => "transclusion_range_too_large",
            ViolationCode::InvalidAuthorKey => "invalid_author_key",
            ViolationCode::ZeroTimestamp => "zero_timestamp",
            ViolationCode::ImplausibleBlob => "implausible_blob",
            ViolationCode::InvalidElementId => "invalid_element_id",
        };
        f.write_str(name)
    }
}

/// Result of validation: either the edition is well-formed, or a
/// list of every violation found (reported together — an adversary
/// should not learn which check failed first by probing).
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct ValidationReport {
    pub violations: Vec<InvariantViolation>,
}

impl ValidationReport {
    pub fn is_valid(&self) -> bool {
        self.violations.is_empty()
    }

    fn add(&mut self, code: ViolationCode, detail: impl Into<String>) {
        self.violations.push(InvariantViolation {
            code,
            detail: detail.into(),
        });
    }
}

/// Validate an edition's structure. Total: returns a report for any
/// input; callers enforce size caps BEFORE calling if the input came
/// from the network unbounded.
pub fn validate_edition(edition: &Edition, self_work_id: u64) -> ValidationReport {
    let mut report = ValidationReport::default();
    let entries = edition.all_entries();

    validate_entries(&entries, &mut report);
    validate_transclusions(&entries, self_work_id, &mut report);
    validate_spans(&entries, &edition.span_provenance, &mut report);
    validate_provenance(&entries, &mut report);

    report
}

fn validate_entries(entries: &[(i64, std::sync::Arc<Carrier>)], report: &mut ValidationReport) {
    if entries.is_empty() {
        report.add(ViolationCode::EmptyEdition, "edition has no entries");
        return;
    }
    if entries.len() > MAX_ENTRIES {
        report.add(
            ViolationCode::TooManyEntries,
            format!("{} entries (max {})", entries.len(), MAX_ENTRIES),
        );
    }

    let mut total_text: usize = 0;
    let mut prev_pos: Option<i64> = None;
    for (pos, carrier) in entries {
        if let Some(prev) = prev_pos {
            if *pos == prev {
                report.add(
                    ViolationCode::DuplicatePosition,
                    format!("duplicate position {pos}"),
                );
            } else if *pos < prev {
                report.add(
                    ViolationCode::EntryPositionsUnordered,
                    format!("position {pos} after {prev}"),
                );
            }
        }
        prev_pos = Some(*pos);

        if let RangeElement::Text { text } = &carrier.element {
            let char_len = text.chars().count();
            if char_len > MAX_TEXT_ENTRY_CHARS {
                report.add(
                    ViolationCode::TextEntryTooLarge,
                    format!(
                        "text entry at {pos} has {char_len} chars (max {MAX_TEXT_ENTRY_CHARS})"
                    ),
                );
            }
            total_text += char_len;
            if text
                .chars()
                .any(|c| (c.is_control() && c != '\n' && c != '\t' && c != '\r') || c == '\u{0}')
            {
                report.add(
                    ViolationCode::ControlCharacters,
                    format!("forbidden control characters in text entry at {pos}"),
                );
            }
        }
        if let RangeElement::Blob {
            byte_size,
            mime_type,
            ..
        } = &carrier.element
        {
            if (*byte_size as u64) == 0 || (*byte_size as u64) > 512 * 1024 * 1024 {
                report.add(
                    ViolationCode::ImplausibleBlob,
                    format!("blob at {pos}: byte_size={byte_size}"),
                );
            }
            let plausible = mime_type.starts_with("image/")
                || mime_type.starts_with("application/")
                || mime_type.starts_with("text/")
                || mime_type.starts_with("audio/")
                || mime_type.starts_with("video/");
            if !plausible {
                report.add(
                    ViolationCode::ImplausibleBlob,
                    format!("blob at {pos}: mime_type={mime_type:?}"),
                );
            }
        }
    }
    if total_text > MAX_TEXT_CHARS {
        report.add(
            ViolationCode::TotalTextTooLarge,
            format!("{total_text} total chars (max {MAX_TEXT_CHARS})"),
        );
    }
}

fn validate_transclusions(
    entries: &[(i64, std::sync::Arc<Carrier>)],
    self_work_id: u64,
    report: &mut ValidationReport,
) {
    for (pos, carrier) in entries {
        if let RangeElement::Transclusion {
            source_work_id,
            char_start,
            char_end,
            ..
        } = &carrier.element
        {
            if char_start >= char_end {
                report.add(
                    ViolationCode::TransclusionRangeInvalid,
                    format!("at {pos}: char_start={char_start} >= char_end={char_end}"),
                );
            }
            if *source_work_id == self_work_id {
                report.add(
                    ViolationCode::TransclusionSelfCycle,
                    format!("at {pos}: transclusion references own work {self_work_id}"),
                );
            }
            if *char_end > MAX_TEXT_CHARS {
                report.add(
                    ViolationCode::TransclusionRangeTooLarge,
                    format!("at {pos}: char_end={char_end} exceeds document bounds"),
                );
            }
        }
    }
}

fn validate_spans(
    entries: &[(i64, std::sync::Arc<Carrier>)],
    spans: &[crate::edition::provenance::SpanProvenance],
    report: &mut ValidationReport,
) {
    if spans.is_empty() {
        return;
    }
    if spans.len() > MAX_SPANS {
        report.add(
            ViolationCode::TooManySpans,
            format!("{} spans (max {})", spans.len(), MAX_SPANS),
        );
    }

    // Character extent of the document (entries are position-ordered
    // elsewhere; here we compute the max covered char count so spans
    // can be bounds-checked regardless of ordering bugs upstream).
    let doc_len: i64 = entries.iter().map(|(_, c)| c.char_len() as i64).sum();

    let mut prev_end: Option<i64> = None;
    for span in spans {
        if span.end <= span.start {
            report.add(
                ViolationCode::EmptySpan,
                format!("span [{}, {}) is empty", span.start, span.end),
            );
            continue;
        }
        if span.start < 0 || span.end > doc_len {
            report.add(
                ViolationCode::SpanOutOfBounds,
                format!(
                    "span [{}, {}) outside document length {}",
                    span.start, span.end, doc_len
                ),
            );
        }
        if let Some(prev) = prev_end {
            if span.start < prev {
                report.add(
                    ViolationCode::SpansUnorderedOrOverlapping,
                    format!(
                        "span [{}, {}) starts before previous end {prev}",
                        span.start, span.end
                    ),
                );
            }
        }
        prev_end = Some(span.end);
    }
}

fn validate_provenance(entries: &[(i64, std::sync::Arc<Carrier>)], report: &mut ValidationReport) {
    for (pos, carrier) in entries {
        let Some(prov) = &carrier.provenance else {
            continue;
        };
        if prov.author_public_key.len() != 32 || prov.author_public_key.iter().all(|&b| b == 0) {
            report.add(
                ViolationCode::InvalidAuthorKey,
                format!("entry at {pos}: malformed author key"),
            );
        }
        if prov.timestamp == 0 {
            report.add(
                ViolationCode::ZeroTimestamp,
                format!("entry at {pos}: zero provenance timestamp"),
            );
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::provenance::{AuthorType, ElementProvenance};
    use crate::edition::range_element::Carrier;
    use proptest::prelude::*;
    use std::sync::Arc;

    #[test]
    fn valid_edition_passes() {
        let ed = Edition::from_text("hello world");
        let report = validate_edition(&ed, 42);
        assert!(report.is_valid(), "violations: {:?}", report.violations);
    }

    #[test]
    fn control_characters_rejected() {
        let ed = Edition::from_text("bad\u{0}text");
        let report = validate_edition(&ed, 42);
        assert!(report
            .violations
            .iter()
            .any(|v| v.code == ViolationCode::ControlCharacters));
    }

    #[test]
    fn empty_edition_flagged() {
        let ed = Edition::empty();
        let report = validate_edition(&ed, 42);
        assert!(report
            .violations
            .iter()
            .any(|v| v.code == ViolationCode::EmptyEdition));
    }

    // ── Property: valid documents always pass ─────────────────────

    fn text_carrier(s: &str) -> Arc<Carrier> {
        Arc::new(Carrier::new(RangeElement::text(s.to_string())))
    }

    fn transclusion_carrier(src: u64, start: usize, end: usize) -> Arc<Carrier> {
        Arc::new(Carrier::new(RangeElement::transclusion(src, start, end)))
    }

    prop_compose! {
        fn valid_document()(sections in prop::collection::vec(
            "[a-z ]{1,40}",
            1..8
        )) -> Edition {
            let entries: Vec<(i64, Arc<Carrier>)> = sections
                .iter()
                .map(|s| (0i64, text_carrier(s)))
                .collect();
            Edition::from_entries(entries).coalesce()
        }
    }

    proptest! {
        #[test]
        fn prop_valid_document_passes(ed in valid_document()) {
            let report = validate_edition(&ed, 42);
            prop_assert!(
                report.is_valid(),
                "false positive: {:?}",
                report.violations
            );
        }

        #[test]
        fn prop_valid_with_spans_passes(
            sections in prop::collection::vec("[a-z ]{1,40}", 1..6)
        ) {
            // Build a document and a contiguous span tiling of it.
            let text = sections.join("");
            let ed = Edition::from_text(&text);
            let n = text.chars().count() as i64;
            // one span covering a prefix, plus one covering the rest
            let cut = n / 2;
            if cut == 0 { return Ok(()); }
            let spans = vec![
                crate::edition::provenance::SpanProvenance {
                    start: 0,
                    end: cut,
                    provenance: dummy_prov(),
                },
                crate::edition::provenance::SpanProvenance {
                    start: cut,
                    end: n,
                    provenance: dummy_prov(),
                },
            ];
            let ed = ed.with_span_provenance(spans);
            let report = validate_edition(&ed, 42);
            prop_assert!(report.is_valid(), "false positive: {:?}", report.violations);
        }
    }

    fn dummy_prov() -> crate::edition::provenance::Provenance {
        crate::edition::provenance::Provenance {
            author_public_key: [7u8; 32],
            signature: [5u8; 64],
            timestamp: 1_700_000_000,
            server_id: [1u8; 32],
        }
    }

    // ── Adversary: every corruption class is caught ────────────────

    #[test]
    fn mutation_span_out_of_bounds() {
        let text = "hello world, this is a document";
        let ed = Edition::from_text(text).with_span_provenance(vec![
            crate::edition::provenance::SpanProvenance {
                start: 0,
                end: text.chars().count() as i64 + 5, // stretched past end
                provenance: dummy_prov(),
            },
        ]);
        let report = validate_edition(&ed, 42);
        assert!(report
            .violations
            .iter()
            .any(|v| v.code == ViolationCode::SpanOutOfBounds));
    }

    #[test]
    fn mutation_empty_span() {
        let ed = Edition::from_text("hello").with_span_provenance(vec![
            crate::edition::provenance::SpanProvenance {
                start: 2,
                end: 2,
                provenance: dummy_prov(),
            },
        ]);
        let report = validate_edition(&ed, 42);
        assert!(report
            .violations
            .iter()
            .any(|v| v.code == ViolationCode::EmptySpan));
    }

    #[test]
    fn mutation_overlapping_spans() {
        let ed = Edition::from_text("hello world").with_span_provenance(vec![
            crate::edition::provenance::SpanProvenance {
                start: 0,
                end: 5,
                provenance: dummy_prov(),
            },
            crate::edition::provenance::SpanProvenance {
                start: 3, // overlaps [0,5)
                end: 8,
                provenance: dummy_prov(),
            },
        ]);
        let report = validate_edition(&ed, 42);
        assert!(report
            .violations
            .iter()
            .any(|v| v.code == ViolationCode::SpansUnorderedOrOverlapping));
    }

    #[test]
    fn mutation_transclusion_self_cycle() {
        let entries = vec![
            (0i64, text_carrier("before ")),
            (1i64, transclusion_carrier(42, 0, 10)), // src == self_work_id
            (2i64, text_carrier(" after")),
        ];
        let ed = Edition::from_entries(entries);
        let report = validate_edition(&ed, 42);
        assert!(report
            .violations
            .iter()
            .any(|v| v.code == ViolationCode::TransclusionSelfCycle));
    }

    #[test]
    fn mutation_transclusion_reversed_range() {
        // The constructor normalizes reversed ranges, but deserialization
        // bypasses constructors: the validator must catch the raw form.
        let raw = RangeElement::Transclusion {
            source_work_id: 99,
            char_start: 20,
            char_end: 5,
            placed_at: 0,
            placed_by: None,
            content_hash: None,
            source_revision: None,
        };
        let entries = vec![(0i64, Arc::new(Carrier::new(raw)))];
        let ed = Edition::from_entries(entries);
        let report = validate_edition(&ed, 42);
        assert!(report
            .violations
            .iter()
            .any(|v| v.code == ViolationCode::TransclusionRangeInvalid));
    }

    #[test]
    fn mutation_transclusion_absurd_range() {
        let entries = vec![(0i64, transclusion_carrier(99, 0, 4_000_000_000))];
        let ed = Edition::from_entries(entries);
        let report = validate_edition(&ed, 42);
        assert!(report
            .violations
            .iter()
            .any(|v| v.code == ViolationCode::TransclusionRangeTooLarge));
    }

    #[test]
    fn mutation_implausible_blob() {
        let entries = vec![(
            0i64,
            Arc::new(Carrier::new(RangeElement::blob(
                1234,
                "definitely/not-a-mime",
                0, // zero size
            ))),
        )];
        let ed = Edition::from_entries(entries);
        let report = validate_edition(&ed, 42);
        assert!(report
            .violations
            .iter()
            .any(|v| v.code == ViolationCode::ImplausibleBlob));
    }

    #[test]
    fn mutation_invalid_provenance_key() {
        let mut c = Carrier::new(RangeElement::text("hi".to_string()));
        c.provenance = Some(ElementProvenance {
            author_public_key: [0u8; 32], // all-zero: never a real key
            author_display_name: "attacker".into(),
            author_club_id: 1,
            timestamp: 1_700_000_000,
            author_type: AuthorType::Human,
            llm_model: None,
            historical_author_id: None,
            source_work_id: None,
            transcluded_by: None,
            derived_by: None,
        });
        let ed = Edition::from_entries(vec![(0i64, Arc::new(c))]);
        let report = validate_edition(&ed, 42);
        assert!(report
            .violations
            .iter()
            .any(|v| v.code == ViolationCode::InvalidAuthorKey));
    }

    #[test]
    fn mutation_zero_timestamp() {
        let mut c = Carrier::new(RangeElement::text("hi".to_string()));
        c.provenance = Some(ElementProvenance {
            author_public_key: [7u8; 32],
            author_display_name: "no time".into(),
            author_club_id: 1,
            timestamp: 0,
            author_type: AuthorType::Human,
            llm_model: None,
            historical_author_id: None,
            source_work_id: None,
            transcluded_by: None,
            derived_by: None,
        });
        let ed = Edition::from_entries(vec![(0i64, Arc::new(c))]);
        let report = validate_edition(&ed, 42);
        assert!(report
            .violations
            .iter()
            .any(|v| v.code == ViolationCode::ZeroTimestamp));
    }
}
