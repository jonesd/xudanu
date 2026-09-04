//! FR-55 T3: the Arrangement — compound ⇄ cross-position mapping.
//!
//! Gold's mapping walk, made concrete: "compound char 540 = source
//! doc 0x23, chars 10–90". Built over the keyed segments (T2), it
//! answers both directions:
//!
//! - `at(local_char)` → which segment, which source work, which
//!   source range *at current offsets* (resolved through the
//!   source's live map — never stored, never stale)
//! - `place(source_work, source_char)` → local range in this
//!   compound (feeds beams columns and Origin-panel jumps)
//!
//! The existing `space::Arrangement<P>` is a sorted-position index;
//! this module is the document-level arrangement that USES segment
//! identity as its positions. Cross-space positions use Gold's
//! vocabulary: `(doc, char)` — the docverse coordinate.

use crate::edition::span_key::{SpanKey, SpanKeyMap};

pub type BeId = u64;

/// A cross-space position: (source work, char offset in that work).
/// Gold's `XuCrossSpace` coordinate — the docverse address.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct CrossPosition {
    pub work: BeId,
    pub char: usize,
}

/// One arrangement row: a segment's placement in the compound.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ArrangementEntry {
    /// Local char range in the compound [start, end).
    pub local_start: usize,
    pub local_end: usize,
    /// Segment source (subset needed for mapping).
    pub source: ArrangementSource,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ArrangementSource {
    Authored,
    Transcluded {
        source_work: BeId,
        source_key: SpanKey,
        placed_len: usize,
    },
}

/// The arrangement: ordered rows over a compound's segments.
/// Rebuilt on demand from segments + live resolution (offsets are
/// always current — the FR-55 no-stale-offsets rule).
#[derive(Debug, Clone, Default)]
pub struct CompoundArrangement {
    rows: Vec<ArrangementEntry>,
}

impl CompoundArrangement {
    /// Build from segment renders in order: each render's text
    /// length advances the local cursor.
    pub fn from_renders(
        segments: &[crate::edition::compound_segment::CompoundSegment],
        renders: &[crate::edition::compound_segment::SegmentRender],
    ) -> Self {
        let mut rows = Vec::with_capacity(segments.len());
        let mut cursor = 0usize;
        for (seg, render) in segments.iter().zip(renders.iter()) {
            let len = render.text().chars().count();
            let source = match &seg.source {
                crate::edition::compound_segment::SegmentSource::Authored { .. } => {
                    ArrangementSource::Authored
                }
                crate::edition::compound_segment::SegmentSource::Transcluded {
                    source_work,
                    source_key,
                    placed_len,
                    ..
                } => ArrangementSource::Transcluded {
                    source_work: *source_work,
                    source_key: source_key.clone(),
                    placed_len: *placed_len,
                },
            };
            rows.push(ArrangementEntry {
                local_start: cursor,
                local_end: cursor + len,
                source,
            });
            cursor += len;
        }
        CompoundArrangement { rows }
    }

    pub fn rows(&self) -> &[ArrangementEntry] {
        &self.rows
    }

    pub fn total_len(&self) -> usize {
        self.rows.last().map(|r| r.local_end).unwrap_or(0)
    }

    /// The row containing a local char offset (the mapping walk).
    pub fn row_at(&self, local_char: usize) -> Option<&ArrangementEntry> {
        self.rows
            .iter()
            .find(|r| local_char >= r.local_start && local_char < r.local_end)
            .or_else(|| self.rows.last().filter(|_| local_char >= self.total_len()))
    }

    /// Gold's follow-back: compound char → cross-position with the
    /// source range at CURRENT offsets (resolved live).
    pub fn at(
        &self,
        local_char: usize,
        source_maps: &std::collections::HashMap<BeId, SpanKeyMap>,
    ) -> Option<(CrossPosition, usize)> {
        let row = self.row_at(local_char)?;
        match &row.source {
            ArrangementSource::Authored => None,
            ArrangementSource::Transcluded {
                source_work,
                source_key,
                ..
            } => {
                let map = source_maps.get(source_work)?;
                let (src_start, _) = map.range_of(source_key)?;
                let into = local_char - row.local_start;
                let char = src_start + into.min(Self::row_extent(row));
                Some((
                    CrossPosition {
                        work: *source_work,
                        char,
                    },
                    Self::row_extent(row),
                ))
            }
        }
    }

    /// Inverse: where does a source char appear in this compound?
    /// (First matching row — multiple placements return the first.)
    pub fn place(
        &self,
        source_work: BeId,
        source_char: usize,
        source_maps: &std::collections::HashMap<BeId, SpanKeyMap>,
    ) -> Option<(usize, usize)> {
        let row = self.rows.iter().find(|r| match &r.source {
            ArrangementSource::Transcluded {
                source_work: sw,
                source_key,
                ..
            } => {
                *sw == source_work
                    && source_maps
                        .get(sw)
                        .and_then(|m| m.range_of(source_key))
                        .map(|(s, e)| source_char >= s && source_char < e)
                        .unwrap_or(false)
            }
            _ => false,
        })?;
        let (src_start, _) = match &row.source {
            ArrangementSource::Transcluded {
                source_key,
                source_work,
                ..
            } => source_maps.get(source_work)?.range_of(source_key)?,
            _ => return None,
        };
        let into = source_char
            .saturating_sub(src_start)
            .min(Self::row_extent(row));
        let start = row.local_start + into;
        Some((start, (start + 1).min(row.local_end)))
    }

    fn row_extent(row: &ArrangementEntry) -> usize {
        row.local_end - row.local_start
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::compound_segment::{
        content_crum, resolve_segments_owned, CompoundSegment, SegmentRender,
    };
    use std::collections::HashMap;

    fn q1_off() -> usize {
        "INTRO THAT IS LONGER\n".chars().count()
    }
    fn q2_off() -> usize {
        "INTRO THAT IS LONGER\nthe first quoted passage\nGAP\n"
            .chars()
            .count()
    }

    fn build() -> (Vec<CompoundSegment>, HashMap<BeId, SpanKeyMap>, String) {
        // Source: two quoted passages; compound: header + quote1 +
        // middle + quote2 + footer.
        let src_id: BeId = 0x23;
        let src_text =
            "INTRO THAT IS LONGER\nthe first quoted passage\nGAP\nthe second quoted passage\nOUT";
        let mut src_map = SpanKeyMap::from_total_chars(src_text.chars().count(), 8);
        let q1_off = "INTRO THAT IS LONGER\n".chars().count();
        let q2_off = "INTRO THAT IS LONGER\nthe first quoted passage\nGAP\n"
            .chars()
            .count();
        let k1 = src_map.insert_span(q1_off, "the first quoted passage".chars().count());
        let k2 = src_map.insert_span(q2_off, "the second quoted passage".chars().count());

        let mut local = SpanKeyMap::default();
        let segs = vec![
            CompoundSegment::authored(local.insert_span(0, 7), "Header\n"),
            CompoundSegment::transcluded(
                local.insert_span(7, 26),
                src_id,
                k1,
                "the first quoted passage".chars().count(),
                content_crum("the first quoted passage"),
            ),
            CompoundSegment::authored(local.insert_span(33, 8), "\nMIDDLE\n"),
            CompoundSegment::transcluded(
                local.insert_span(41, 27),
                src_id,
                k2,
                "the second quoted passage".chars().count(),
                content_crum("the second quoted passage"),
            ),
            CompoundSegment::authored(local.insert_span(68, 7), "\nFooter"),
        ];
        let mut maps = HashMap::new();
        maps.insert(src_id, src_map);
        (segs, maps, src_text.to_string())
    }

    fn resolve(
        segs: &[CompoundSegment],
        maps: &HashMap<BeId, SpanKeyMap>,
        text: &str,
    ) -> Vec<SegmentRender> {
        let src_id: BeId = 0x23;
        let mut owned = HashMap::new();
        owned.insert(src_id, (maps[&src_id].clone(), text.to_string()));
        resolve_segments_owned(segs, &owned)
    }

    #[test]
    fn arrangement_walk_follow_back_exact() {
        let (segs, maps, text) = build();
        let renders = resolve(&segs, &maps, &text);
        let arr = CompoundArrangement::from_renders(&segs, &renders);

        // "Header\n" = 7 chars; quote1 starts at local 7; local 10
        // → into 3 → source q1_off + 3.
        let (pos, _) = arr.at(10, &maps).unwrap();
        assert_eq!(pos.work, 0x23);
        assert_eq!(pos.char, q1_off() + 3);

        // Authored region → None (no cross position).
        assert!(arr.at(2, &maps).is_none());

        // Quote2: renders give it local [39, 64); local 45 → into
        // 6 → q2_off + 6. Offsets COMPUTED, not magic.
        let q2_off = q2_off();
        let (pos2, _) = arr.at(45, &maps).unwrap();
        assert_eq!(pos2.char, q2_off + 6);
    }

    #[test]
    fn arrangement_walk_survives_source_edits() {
        // THE headline: prefix-edit the source; the SAME arrangement
        // (built after) resolves walks correctly — and an arrangement
        // built BEFORE still yields correct cross-chars because
        // offsets are resolved live, never stored.
        let (segs, mut maps, text) = build();
        let renders = resolve(&segs, &maps, &text);
        let arr = CompoundArrangement::from_renders(&segs, &renders);

        // Edit source: 100-char prefix insert; map maintained.
        let src_id: BeId = 0x23;
        let edited = format!("{}{}", "P".repeat(100), text);
        {
            let m = maps.get_mut(&src_id).unwrap();
            m.insert_span(0, 100);
        }
        // at(10) NOW points 100 further into the edited source.
        let (pos, _) = arr.at(10, &maps).unwrap();
        assert_eq!(pos.char, q1_off() + 3 + 100, "walk tracks live offsets");
    }

    #[test]
    fn arrangement_inverse_place() {
        let (segs, maps, text) = build();
        let renders = resolve(&segs, &maps, &text);
        let arr = CompoundArrangement::from_renders(&segs, &renders);
        let src_id: BeId = 0x23;

        // Source char inside quote1 (q1_off+5) appears at local
        // 7+5 (quote1 starts at local 7).
        let q1 = q1_off();
        let (start, _) = arr.place(src_id, q1 + 5, &maps).unwrap();
        assert_eq!(start, 7 + 5);

        // A source char not in any quote → None.
        assert!(arr.place(src_id, 3, &maps).is_none());
    }

    #[test]
    fn arrangement_rows_and_extent() {
        let (segs, maps, text) = build();
        let renders = resolve(&segs, &maps, &text);
        let arr = CompoundArrangement::from_renders(&segs, &renders);
        assert_eq!(arr.rows().len(), 5);
        assert_eq!(
            arr.total_len(),
            "Header\n".len()
                + "the first quoted passage".len()
                + "\nMIDDLE\n".len()
                + "the second quoted passage".len()
                + "\nFooter".len()
        );
        // row_at boundaries
        assert!(arr.row_at(0).unwrap().local_start == 0);
        assert!(arr.row_at(6).unwrap().local_end == 7);
        assert!(arr.row_at(7).unwrap().local_start == 7);
    }
}
