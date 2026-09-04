//! FR-55 H1 (tranche 1): keyed compound segments.
//!
//! A compound document is an ordered list of segments. Authored
//! segments carry their own text; transcluded segments reference a
//! source work by SPAN KEY (FR-38) — never char offset — plus the
//! content hash captured at assembly time. Resolution walks each
//! source's `SpanKeyMap`: offsets are looked up fresh on every
//! render, so source edits never rot a segment. A changed source
//! span is *marked* (drift), never silently wrong; a missing or
//! retired key renders a visible placeholder (Gold's async-fill
//! seam, issue #9).
//!
//! This tranche is pure edition-layer: types, resolution, legacy
//! migration, tests. Orgl assembly, persistence, and UI wiring are
//! tranches 2–4.

use std::collections::HashMap;

use crate::edition::span_key::{SpanKey, SpanKeyMap};

/// Content identity captured when a transclusion was placed.
/// BLAKE3 of the resolved span text at assembly time — a crum in
/// the FR-35 sense ([u8; 32] content identity).
pub type SegmentCrum = [u8; 32];

pub type BeId = u64;

/// What a segment IS.
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub enum SegmentSource {
    /// Native compound text, authored here.
    Authored { text: String },
    /// Transcluded from a source work, identified by span key.
    /// Survives every subsequent source edit; `placed_crum` enables
    /// drift detection (source content changed since placement).
    Transcluded {
        source_work: BeId,
        source_key: SpanKey,
        /// Extent in chars at placement time. The KEY anchors
        /// position (survives offset shifts); the length is
        /// placement metadata. Content change → crum mismatch →
        /// drift flag; never silently wrong either way.
        placed_len: usize,
        placed_crum: SegmentCrum,
    },
}

/// One segment of a compound document: identity + source.
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct CompoundSegment {
    /// Local identity within the compound (its own key space).
    pub local_key: SpanKey,
    pub source: SegmentSource,
}

impl CompoundSegment {
    pub fn authored(local_key: SpanKey, text: impl Into<String>) -> Self {
        CompoundSegment {
            local_key,
            source: SegmentSource::Authored { text: text.into() },
        }
    }

    pub fn transcluded(
        local_key: SpanKey,
        source_work: BeId,
        source_key: SpanKey,
        placed_len: usize,
        placed_crum: SegmentCrum,
    ) -> Self {
        CompoundSegment {
            local_key,
            source: SegmentSource::Transcluded {
                source_work,
                source_key,
                placed_len,
                placed_crum,
            },
        }
    }
}

/// Resolution result for one segment.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SegmentRender {
    /// Fully resolved text (authored, or transcluded and unchanged).
    Text(String),
    /// FR-55 T5: an embedded image — resolved by content hash from
    /// the blob store; renders caption + dimensions in text views.
    Image {
        content_hash: u64,
        mime_type: String,
        width: Option<u32>,
        height: Option<u32>,
        caption: Option<String>,
    },
    /// Transcluded and resolved, but the source span's content
    /// differs from placement time. Rendered WITH the flag —
    /// never silently wrong.
    Drifted {
        text: String,
        source_work: BeId,
        source_key: SpanKey,
    },
    /// The source key no longer resolves (span deleted, or the
    /// source work unknown to the resolver). Gold's placeholder
    /// seam: visible, addressable, fillable later (issue #9).
    Placeholder {
        source_work: BeId,
        source_key: SpanKey,
    },
}

impl SegmentRender {
    /// The text to render; placeholders render a visible marker.
    pub fn text(&self) -> String {
        match self {
            SegmentRender::Text(t) => t.clone(),
            SegmentRender::Image {
                caption,
                content_hash,
                width,
                height,
                ..
            } => {
                let marker = caption
                    .clone()
                    .unwrap_or_else(|| format!("[image {content_hash:016x}]"));
                match (width, height) {
                    (Some(w), Some(h)) => format!("{marker} ({w}×{h})"),
                    _ => marker,
                }
            }
            SegmentRender::Drifted { text, .. } => text.clone(),
            SegmentRender::Placeholder { .. } => "\u{2026}[awaiting source]\u{2026}".to_string(),
        }
    }

    pub fn is_drifted(&self) -> bool {
        matches!(self, SegmentRender::Drifted { .. })
    }

    pub fn is_placeholder(&self) -> bool {
        matches!(self, SegmentRender::Placeholder { .. })
    }
}

/// Read-side view of one source work: its live key map plus the
/// current text. Editions are immutable per revision, so a snapshot
/// pair is coherent for one resolution pass.
pub struct SourceView<'a> {
    pub keys: &'a SpanKeyMap,
    pub text: &'a str,
}

/// Resolve segments against the current state of their sources.
/// Every transclusion is looked up FRESH: source edits shift
/// offsets, keys hold, and the render is always exact-or-flagged.
pub fn resolve_segments(
    segments: &[CompoundSegment],
    sources: &HashMap<BeId, SourceView<'_>>,
) -> Vec<SegmentRender> {
    segments
        .iter()
        .map(|seg| match &seg.source {
            SegmentSource::Authored { text } => SegmentRender::Text(text.clone()),
            SegmentSource::Transcluded {
                source_work,
                source_key,
                placed_len,
                placed_crum,
            } => {
                let Some(view) = sources.get(source_work) else {
                    return SegmentRender::Placeholder {
                        source_work: *source_work,
                        source_key: source_key.clone(),
                    };
                };
                // The key ANCHORS the position (its range start —
                // stable across every offset shift); the placed
                // length carries the extent. If the source span
                // shrank away entirely, the key retires.
                let Some((start, _)) = view.keys.range_of(source_key) else {
                    return SegmentRender::Placeholder {
                        source_work: *source_work,
                        source_key: source_key.clone(),
                    };
                };
                let text: String = view.text.chars().skip(start).take(*placed_len).collect();
                let now_crum = content_crum(&text);
                if now_crum == *placed_crum {
                    SegmentRender::Text(text)
                } else {
                    SegmentRender::Drifted {
                        text,
                        source_work: *source_work,
                        source_key: source_key.clone(),
                    }
                }
            }
        })
        .collect()
}

/// Server-side resolution over owned (cloned-once) source state —
/// the mutex-held live maps can't back borrowed `SourceView`s, so
/// callers clone each referenced source's map once per resolve.
pub fn resolve_segments_owned(
    segments: &[CompoundSegment],
    sources: &HashMap<BeId, (SpanKeyMap, String)>,
) -> Vec<SegmentRender> {
    let views: HashMap<BeId, SourceView<'_>> = sources
        .iter()
        .map(|(id, (map, text))| (*id, SourceView { keys: map, text }))
        .collect();
    resolve_segments(segments, &views)
}

/// Content identity of a resolved span (BLAKE3, FR-35 sense).
pub fn content_crum(text: &str) -> SegmentCrum {
    blake3::hash(text.as_bytes()).into()
}

/// Migrate legacy offset-based compound elements (the manifest's
/// inline `CompoundEdition`) to keyed segments. Source keys are
/// derived from each span's CURRENT offsets via the source's map —
/// the one-time-derivation pattern from FR-38: imperfect once,
/// exact forever after. Text elements become authored segments.
/// Returns segments plus local keys allocated in order.
pub fn migrate_legacy<'a>(
    elements: &[crate::edition::compound::CompoundElement],
    sources: &HashMap<BeId, SourceView<'a>>,
) -> (Vec<CompoundSegment>, HashMap<BeId, SpanKeyMap>) {
    use crate::edition::compound::CompoundElement;

    let mut local_space = SpanKeyMap::default();
    // Updated source maps: placement keys are inserted into clones
    // of each source's map. The caller MUST adopt these (feed back
    // via the maintain path) so future resolutions see the keys.
    let mut updated_maps: HashMap<BeId, SpanKeyMap> = HashMap::new();
    let mut out = Vec::with_capacity(elements.len());
    for element in elements {
        match element {
            CompoundElement::Text { content } => {
                let key = local_space.insert_span(0, content.chars().count().max(1));
                // insert_span shifts later extents; for an append-only
                // build we want sequential keys — simpler: rebuild map
                // positions by tracking total length.
                let _ = key;
                let total: usize = out
                    .iter()
                    .map(|s: &CompoundSegment| match &s.source {
                        SegmentSource::Authored { text } => text.chars().count(),
                        SegmentSource::Transcluded { .. } => 0,
                    })
                    .sum();
                let local_key = local_space.insert_span(total, content.chars().count().max(1));
                out.push(CompoundSegment::authored(local_key, content.clone()));
            }
            CompoundElement::Image {
                content_hash,
                mime_type,
                byte_size: _,
                width,
                height,
                caption,
            } => {
                let label = caption
                    .clone()
                    .unwrap_or_else(|| format!("image {content_hash:016x}"));
                let total: usize = out
                    .iter()
                    .map(|s| match &s.source {
                        SegmentSource::Authored { text } => text.chars().count(),
                        SegmentSource::Transcluded { placed_len, .. } => *placed_len,
                    })
                    .sum();
                let local_key = local_space.insert_span(total, 1);
                out.push(CompoundSegment {
                    local_key,
                    source: SegmentSource::Authored { text: label },
                });
                // The blob reference itself rides in the render:
                // stash the full image data via extension — v1 keeps
                // segments text-typed; the builder resolves images
                // from the CompoundElement directly (hash is stable).
                let _ = (mime_type, width, height);
            }
            CompoundElement::Span { span } => {
                let sw = span.source_work_id();
                let cs = span.char_start();
                let ce = span.char_end();
                // Derive a key governing EXACTLY the legacy range —
                // one-time, aligned, exact forever after.
                let source_key = if let Some(v) = sources.get(&sw) {
                    let owned = updated_maps.entry(sw).or_insert_with(|| v.keys.clone());
                    owned.insert_span(cs, ce.saturating_sub(cs))
                } else {
                    SpanKey::first()
                };
                let text: String = sources
                    .get(&sw)
                    .map(|v| {
                        v.text
                            .chars()
                            .skip(cs)
                            .take(ce.saturating_sub(cs))
                            .collect()
                    })
                    .unwrap_or_default();
                let total: usize = out
                    .iter()
                    .map(|s: &CompoundSegment| match &s.source {
                        SegmentSource::Authored { text } => text.chars().count(),
                        SegmentSource::Transcluded { .. } => 0,
                    })
                    .sum();
                let local_key = local_space.insert_span(total, 1);
                out.push(CompoundSegment::transcluded(
                    local_key,
                    sw,
                    source_key,
                    ce.saturating_sub(cs),
                    content_crum(&text),
                ));
            }
        }
    }
    (out, updated_maps)
}

#[cfg(test)]
mod tests {
    use super::*;

    /// FR-55 test 1: the rot fix, pinned. Source edits shift every
    /// offset; keyed segments render the right content regardless.
    #[test]
    fn compound_survives_source_edits() {
        let src_text = "PRELUDE TEXT HERE\nthe quoted passage verbatim\nTAIL";
        let mut live_map = SpanKeyMap::from_total_chars(src_text.chars().count(), 8);
        let src_id: BeId = 0x20;

        // PLACEMENT allocates a dedicated key governing exactly the
        // placed range (tranche-2 server placement calls the same
        // insert_span). Never borrow a granularity-span's key.
        let target_offset = "PRELUDE TEXT HERE\n".chars().count();
        let passage_len = "the quoted passage verbatim".chars().count();
        let source_key = live_map.insert_span(target_offset, passage_len);
        let span_text: String = src_text
            .chars()
            .skip(target_offset)
            .take("the quoted passage verbatim".chars().count())
            .collect();
        let segs = vec![CompoundSegment::transcluded(
            SpanKey::first(),
            src_id,
            source_key,
            "the quoted passage verbatim".chars().count(),
            content_crum(&span_text),
        )];

        // Render before edits — exact.
        let mut sources: HashMap<BeId, SourceView<'_>> = HashMap::new();
        sources.insert(
            src_id,
            SourceView {
                keys: &live_map,
                text: src_text,
            },
        );
        let r = resolve_segments(&segs, &sources);
        assert_eq!(r[0].text(), "the quoted passage verbatim");
        assert!(!r[0].is_drifted());

        // SOURCE EDIT: 250 chars inserted at the front (every stored
        // offset would now be wrong — the legacy rot). The live path
        // maintains the source map through the same op.
        live_map.insert_span(0, 250);
        let edited_text = format!("{}{}", "X".repeat(250), src_text);
        let mut sources2: HashMap<BeId, SourceView<'_>> = HashMap::new();
        sources2.insert(
            src_id,
            SourceView {
                keys: &live_map,
                text: &edited_text,
            },
        );
        let r2 = resolve_segments(&segs, &sources2);
        assert_eq!(
            r2[0].text(),
            "the quoted passage verbatim",
            "keyed segment survives source prefix-insert"
        );
        assert!(!r2[0].is_drifted());
    }

    /// FR-55 test 2: source content changed under the key —
    /// rendered WITH a drift flag, never silently wrong.
    #[test]
    fn drift_marked_not_silent() {
        let mut smap = SpanKeyMap::from_total_chars(
            "stable lead\nMUTABLE PASSAGE\nstable tail".chars().count(),
            6,
        );
        let src_id: BeId = 0x21;
        let offset = "stable lead\n".chars().count();
        let original = "MUTABLE PASSAGE";
        let key = smap.insert_span(offset, original.chars().count());
        let segs = vec![CompoundSegment::transcluded(
            SpanKey::first(),
            src_id,
            key,
            original.chars().count(),
            content_crum(original),
        )];

        // Same key, DIFFERENT text underneath (in-place edit).
        let changed = "stable lead\nREWRITTEN NOW!\nstable tail";
        let mut sources: HashMap<BeId, SourceView<'_>> = HashMap::new();
        sources.insert(
            src_id,
            SourceView {
                keys: &smap,
                text: changed,
            },
        );
        let r = resolve_segments(&segs, &sources);
        assert!(r[0].is_drifted(), "drift must be flagged");
        // The placed extent (16 chars) over the shorter replacement
        // includes the trailing newline — honest drift rendering.
        assert_eq!(r[0].text(), "REWRITTEN NOW!\n");
    }

    /// FR-55 test 4: retired/unknown key → visible placeholder
    /// (the async-fill seam, issue #9).
    #[test]
    fn placeholder_for_missing_source() {
        let src_text = "short";
        let smap = SpanKeyMap::from_total_chars(src_text.chars().count(), 2);
        let src_id: BeId = 0x22;
        let key = smap.key_at(0).unwrap().clone();

        // Unknown work:
        let segs = vec![CompoundSegment::transcluded(
            SpanKey::first(),
            0xDEAD,
            key.clone(),
            1,
            content_crum("x"),
        )];
        let mut sources: HashMap<BeId, SourceView<'_>> = HashMap::new();
        sources.insert(
            src_id,
            SourceView {
                keys: &smap,
                text: src_text,
            },
        );
        assert!(resolve_segments(&segs, &sources)[0].is_placeholder());

        // Known work, retired key (span deleted from the map):
        let empty_map = SpanKeyMap::from_total_chars(0, 1);
        let segs = vec![CompoundSegment::transcluded(
            SpanKey::first(),
            src_id,
            key,
            1,
            content_crum("x"),
        )];
        let mut sources2: HashMap<BeId, SourceView<'_>> = HashMap::new();
        sources2.insert(
            src_id,
            SourceView {
                keys: &empty_map,
                text: src_text,
            },
        );
        let r = resolve_segments(&segs, &sources2);
        assert!(r[0].is_placeholder());
        assert!(r[0].text().contains("awaiting source"));
    }

    /// FR-55 test 6: legacy offset-based compound migrates to keyed
    /// segments; assembled output identical to the legacy render —
    /// and identical AGAIN after a source prefix edit.
    #[test]
    fn migration_renders_identical() {
        use crate::edition::compound::{CompoundElement, CompoundSpan};
        let src_id: BeId = 0x23;
        let src_text = "alpha quote here\nomega";
        let mut smap = SpanKeyMap::from_total_chars(src_text.chars().count(), 4);
        let legacy = vec![
            CompoundElement::Text {
                content: "Header\n".to_string(),
            },
            CompoundElement::Span {
                span: CompoundSpan::new(src_id, 0, 16),
            },
            CompoundElement::Text {
                content: "\nFooter".to_string(),
            },
        ];
        // Migrate ONCE against the original state — segments (and
        // their source keys) are derived a single time.
        let mut sources: HashMap<BeId, SourceView<'_>> = HashMap::new();
        sources.insert(
            src_id,
            SourceView {
                keys: &smap,
                text: src_text,
            },
        );
        let (segs, updated) = migrate_legacy(&legacy, &sources);
        // Adopt the placement-keyed map (the server's maintain path
        // does this in tranche 2).
        let owned_map = updated.get(&src_id).cloned().unwrap();
        let render = |segs: &[CompoundSegment], maps: &HashMap<BeId, SourceView<'_>>| -> String {
            resolve_segments(segs, maps)
                .iter()
                .map(|r| r.text())
                .collect::<Vec<_>>()
                .join("")
        };
        let mut migrated_sources: HashMap<BeId, SourceView<'_>> = HashMap::new();
        migrated_sources.insert(
            src_id,
            SourceView {
                keys: &owned_map,
                text: src_text,
            },
        );
        assert_eq!(
            render(&segs, &migrated_sources),
            "Header\nalpha quote here\nFooter"
        );

        // Source prefix-edit AFTER migration: re-RESOLVE the SAME
        // segments — output identical (the whole point of keys).
        // The edit maintains the source map (live-path op) and the
        // placed key — being a dedicated span — shifts with content.
        let mut live_map = owned_map.clone();
        live_map.insert_span(0, 100);
        let edited_text = format!("{}{}", "Z".repeat(100), src_text);
        let mut sources2: HashMap<BeId, SourceView<'_>> = HashMap::new();
        sources2.insert(
            src_id,
            SourceView {
                keys: &live_map,
                text: &edited_text,
            },
        );
        assert_eq!(render(&segs, &sources2), "Header\nalpha quote here\nFooter");
    }
}
