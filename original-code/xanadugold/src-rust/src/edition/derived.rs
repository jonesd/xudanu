//! FR-37 Phase 4 (Path A — composition): derived-document specs.
//!
//! A derived document (trail, search view, backlink view — see the
//! FR-37 Phase 4 design note) is an Edition whose entries are Phase 3
//! `Virtual` elements. The spec is the SOURCE OF TRUTH for that
//! edition: same spec -> same edition, always, on every replica —
//! because every stop is a pinned VirtualSpec (Phase 3 determinism
//! rule) and the builder is a pure function of the spec.
//!
//! Gold lineage: Gold's virtual structures resolved through the
//! enfilade itself (OExpandingLoaf). Path A composes the same
//! property from proven parts — pinning, spec fingerprints, spaced
//! positions — without touching the Loaf type.

use serde::{Deserialize, Serialize};

use super::backend::BeId;
use super::edition::Edition;
use super::range_element::VirtualSpec;

/// What kind of derived document this spec describes. The kind does
/// not affect the built edition's structure (stops are stops); it
/// carries presentation/API intent so consumers can route and render.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum DerivedKind {
    /// A curated sequence of stops (FR-20/25).
    Trail,
    /// Matching spans from a search query (future: spec carries the
    /// query; stops are pre-resolved spans at build time).
    Search,
    /// Spans quoting/linked-to this work (future).
    Backlinks,
}

/// Serializable specification of a derived document: an ordered list
/// of pinned stops plus presentation metadata. Stored on the derived
/// work; rebuilding from the spec must reproduce the same edition.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DerivedSpec {
    pub kind: DerivedKind,
    /// Ordered stops. Each carries its own pinned source revision
    /// (Phase 3 rule: never "latest").
    pub stops: Vec<VirtualSpec>,
    /// Human title for the derived document (trail name, saved-search
    /// name). Not part of edition identity — presentation only.
    pub title: String,
    /// Optional per-stop notes (trail stop annotations). Same length
    /// as `stops` when present; presentation only.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub stop_notes: Option<Vec<String>>,
}

impl DerivedSpec {
    pub fn new(kind: DerivedKind, title: impl Into<String>) -> Self {
        DerivedSpec {
            kind,
            stops: Vec::new(),
            title: title.into(),
            stop_notes: None,
        }
    }

    /// Append a pinned stop. Ordering is insertion order; the builder
    /// places stops at monotonically spaced positions.
    pub fn add_stop(&mut self, stop: VirtualSpec) {
        self.stops.push(stop);
        // Notes stay aligned or absent — never half-present.
        if let Some(notes) = &mut self.stop_notes {
            notes.push(String::new());
        }
    }

    /// Deterministic spec fingerprint (BLAKE3 over the spec fields).
    /// This is the derived document's identity: two replicas holding
    /// equal specs hold equal fingerprints. Presentation metadata
    /// (title, notes) is EXCLUDED — a renamed trail is the same
    /// document (same stops, same crums); renaming must not renumber
    /// identity.
    pub fn fingerprint(&self) -> [u8; 32] {
        let mut hasher = blake3::Hasher::new();
        hasher.update(b"xudanu/derived-spec/v1");
        hasher.update(match self.kind {
            DerivedKind::Trail => b"trail",
            DerivedKind::Search => b"search",
            DerivedKind::Backlinks => b"backlinks",
        });
        hasher.update(&(self.stops.len() as u64).to_le_bytes());
        for stop in &self.stops {
            hasher.update(&stop.source_work_id.to_le_bytes());
            hasher.update(&stop.char_start.to_le_bytes());
            hasher.update(&stop.char_end.to_le_bytes());
            hasher.update(&stop.revision.to_le_bytes());
            // placed_at/placed_by are placement metadata, deliberately
            // excluded from identity (same rule as the wire payload:
            // two placements of the same quotation are the same stop).
        }
        *hasher.finalize().as_bytes()
    }

    /// Validate internal consistency before use.
    pub fn validate(&self) -> Result<(), String> {
        if let Some(notes) = &self.stop_notes {
            if notes.len() != self.stops.len() {
                return Err(format!(
                    "stop_notes len {} != stops len {}",
                    notes.len(),
                    self.stops.len()
                ));
            }
        }
        for stop in &self.stops {
            if stop.char_start > stop.char_end {
                return Err(format!(
                    "stop char_start {} > char_end {}",
                    stop.char_start, stop.char_end
                ));
            }
        }
        Ok(())
    }
}

/// Spacing between stop positions in the built edition. Wide gaps
/// leave room for per-stop edits (delta-path splits at midpoints)
/// before any re-spacing; same rationale as Stage 4's allocator.
pub const DERIVED_STOP_SPACING: i64 = 1 << 16;

/// Build the derived edition from a spec (pure function — 4b lands
/// the resolver; 4a ships the position plan so the determinism
/// property can pin it).
///
/// Each stop becomes one Virtual element at `i * DERIVED_STOP_SPACING`.
/// Unmaterialized (zero chars) — materialization happens through the
/// Phase 3 read path, exactly like placed virtual transclusions.
pub fn derived_stop_positions(stop_count: usize) -> Vec<i64> {
    (0..stop_count as i64)
        .map(|i| i * DERIVED_STOP_SPACING)
        .collect()
}

/// Build the derived edition from a spec (4b). PURE FUNCTION of the
/// spec: one unmaterialized Virtual element per stop, at the spaced
/// positions from derived_stop_positions. Zero-char until the Phase 3
/// read path materializes (Server::work_text_fresh /
/// materialize_virtual_elements) — exactly like placed virtual
/// transclusions. Determinism: same spec -> same entry sequence ->
/// same edition crums, on any replica, without touching the sources.
pub fn build_derived_edition(spec: &DerivedSpec) -> Result<Edition, String> {
    spec.validate()?;
    let positions = derived_stop_positions(spec.stops.len());
    let entries: Vec<(i64, std::sync::Arc<crate::edition::Carrier>)> = spec
        .stops
        .iter()
        .zip(positions)
        .map(|(stop, pos)| {
            (
                pos,
                std::sync::Arc::new(crate::edition::Carrier::new(
                    crate::edition::range_element::RangeElement::virtual_element(*stop),
                )),
            )
        })
        .collect();
    if entries.is_empty() {
        return Ok(Edition::empty());
    }
    Edition::from_entries_at_positions(entries)
}

/// The work id a derived document reports as its source-of-truth
/// owner in provenance (the club/identity that curates it). Reserved
/// for 4c server integration; defined here so the wire and spec
/// layers agree on the shape.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct DerivedWorkRef {
    pub derived_work_id: BeId,
    pub spec_fingerprint: [u8; 32],
}

#[cfg(test)]
mod tests {
    use super::*;
    use proptest::prelude::*;

    fn stop(source: u64, start: usize, end: usize, rev: u64) -> VirtualSpec {
        VirtualSpec {
            source_work_id: source,
            char_start: start,
            char_end: end,
            revision: rev,
            placed_at: 0,
            placed_by: None,
        }
    }

    #[test]
    fn fingerprint_deterministic_and_metadata_blind() {
        let mut a = DerivedSpec::new(DerivedKind::Trail, "My Trail");
        a.add_stop(stop(1, 0, 10, 3));
        a.add_stop(stop(2, 5, 15, 7));

        let mut b = DerivedSpec::new(DerivedKind::Trail, "Completely Different Name");
        b.add_stop(stop(1, 0, 10, 3));
        b.add_stop(stop(2, 5, 15, 7));

        // Same stops -> same fingerprint, regardless of title.
        assert_eq!(a.fingerprint(), b.fingerprint());

        // Different note structure (presentation) changes nothing.
        b.stop_notes = Some(vec!["note".to_string(), "note2".to_string()]);
        assert_eq!(a.fingerprint(), b.fingerprint());
    }

    #[test]
    fn fingerprint_sensitive_to_content_bearing_fields() {
        let base = || {
            let mut s = DerivedSpec::new(DerivedKind::Trail, "t");
            s.add_stop(stop(1, 0, 10, 3));
            s
        };

        let mut changed_span = base();
        changed_span.stops[0].char_end = 11;
        assert_ne!(base().fingerprint(), changed_span.fingerprint());

        let mut changed_rev = base();
        changed_rev.stops[0].revision = 4;
        assert_ne!(base().fingerprint(), changed_rev.fingerprint());

        let mut changed_src = base();
        changed_src.stops[0].source_work_id = 9;
        assert_ne!(base().fingerprint(), changed_src.fingerprint());

        let mut changed_kind = base();
        changed_kind.kind = DerivedKind::Search;
        assert_ne!(base().fingerprint(), changed_kind.fingerprint());

        // placed_at/by excluded (same rule as wire identity).
        let mut changed_meta = base();
        changed_meta.stops[0].placed_at = 999;
        changed_meta.stops[0].placed_by = Some(7);
        assert_eq!(base().fingerprint(), changed_meta.fingerprint());
    }

    #[test]
    fn stop_order_matters() {
        let mut a = DerivedSpec::new(DerivedKind::Trail, "t");
        a.add_stop(stop(1, 0, 10, 3));
        a.add_stop(stop(2, 0, 10, 3));
        let mut b = DerivedSpec::new(DerivedKind::Trail, "t");
        b.add_stop(stop(2, 0, 10, 3));
        b.add_stop(stop(1, 0, 10, 3));
        assert_ne!(a.fingerprint(), b.fingerprint());
    }

    #[test]
    fn add_stop_keeps_notes_aligned() {
        let mut s = DerivedSpec::new(DerivedKind::Trail, "t");
        s.stop_notes = Some(vec![]);
        s.add_stop(stop(1, 0, 5, 1));
        s.add_stop(stop(1, 5, 9, 1));
        assert_eq!(s.stop_notes.as_ref().unwrap().len(), 2);
        assert!(s.validate().is_ok());
    }

    #[test]
    fn validate_rejects_misalignment_and_bad_ranges() {
        let mut s = DerivedSpec::new(DerivedKind::Trail, "t");
        s.add_stop(stop(1, 0, 5, 1));
        s.stop_notes = Some(vec![]); // misaligned
        assert!(s.validate().is_err());

        let mut bad_range = DerivedSpec::new(DerivedKind::Trail, "t");
        bad_range.add_stop(stop(1, 9, 5, 1));
        assert!(bad_range.validate().is_err());
    }

    #[test]
    fn positions_spaced_and_increasing() {
        let ps = derived_stop_positions(4);
        assert_eq!(
            ps,
            vec![
                0,
                DERIVED_STOP_SPACING,
                2 * DERIVED_STOP_SPACING,
                3 * DERIVED_STOP_SPACING
            ]
        );
        assert!(ps.windows(2).all(|w| w[0] < w[1]));
        assert!(derived_stop_positions(0).is_empty());
    }

    /// 4b: builder determinism — same spec builds byte-identical
    /// editions (same positions, same entries, same crums).
    #[test]
    fn build_deterministic_editions() {
        let mut spec = DerivedSpec::new(DerivedKind::Trail, "t");
        spec.add_stop(stop(1, 0, 5, 1));
        spec.add_stop(stop(2, 10, 20, 4));

        let a = build_derived_edition(&spec).unwrap();
        let b = build_derived_edition(&spec).unwrap();
        assert_eq!(a.positions(), b.positions());
        assert_eq!(a.crum(), b.crum());
        assert_eq!(a.count(), 2);
        // Unmaterialized: zero chars until the read path resolves.
        assert_eq!(a.char_len(), 0);
    }

    /// 4b: the builder is a pure function — building the SAME spec
    /// after an edition built from it was edited produces the same
    /// fresh edition (no hidden state).
    #[test]
    fn build_is_pure_across_calls() {
        let mut spec = DerivedSpec::new(DerivedKind::Trail, "t");
        spec.add_stop(stop(7, 3, 9, 2));
        let a = build_derived_edition(&spec).unwrap();
        let fingerprint = spec.fingerprint();
        // Simulate independent rebuild on "another replica".
        let spec2: DerivedSpec =
            serde_json::from_str(&serde_json::to_string(&spec).unwrap()).unwrap();
        let b = build_derived_edition(&spec2).unwrap();
        assert_eq!(a.crum(), b.crum());
        assert_eq!(fingerprint, spec2.fingerprint());
    }

    /// 4b: empty spec -> empty edition; validation errors propagate.
    #[test]
    fn build_edge_cases() {
        let empty = DerivedSpec::new(DerivedKind::Trail, "empty");
        assert!(build_derived_edition(&empty).unwrap().is_empty());

        let mut bad = DerivedSpec::new(DerivedKind::Trail, "bad");
        bad.add_stop(stop(1, 9, 5, 1));
        assert!(build_derived_edition(&bad).is_err());
    }

    /// 4b acceptance gate (equivalence): a derived edition built from
    /// a trail-like spec, materialized through the Phase 3 read path,
    /// yields EXACTLY the concatenation of each stop's pinned source
    /// span. Legacy trails never rendered text server-side (payloads
    /// are metadata; resolution was client-side), so the gate pins the
    /// NEW pinned-span semantics against direct span extraction —
    /// the invariant 4c's server integration and any client renderer
    /// can rely on.
    #[test]
    fn derived_trail_materializes_to_pinned_spans() {
        use crate::edition::range_element::RangeElement;
        use std::sync::Arc;

        // Two source works with distinct texts and multiple revisions.
        let src1_text = "first source document";
        let src2_text = "second source, different shape";

        let mut spec = DerivedSpec::new(DerivedKind::Trail, "my trail");
        // Stop 1: chars 6..12 of source 1 ("source").
        spec.add_stop(VirtualSpec {
            source_work_id: 1,
            char_start: 6,
            char_end: 12,
            revision: 1,
            placed_at: 0,
            placed_by: None,
        });
        // Stop 2: chars 0..6 of source 2 ("second").
        spec.add_stop(VirtualSpec {
            source_work_id: 2,
            char_start: 0,
            char_end: 6,
            revision: 3,
            placed_at: 0,
            placed_by: None,
        });

        let derived = build_derived_edition(&spec).unwrap();
        assert_eq!(derived.char_len(), 0, "unmaterialized");

        // Materialize exactly as Server::materialize_virtual_elements
        // does: resolve each spec against its pinned revision.
        let resolve = |text: &str, s: usize, e: usize| -> String {
            let chars: Vec<char> = text.chars().collect();
            chars[s.min(chars.len())..e.min(chars.len())]
                .iter()
                .collect()
        };
        let mut entries = derived.cached_entries().clone();
        for (_, carrier) in entries.iter_mut() {
            if let Some(vs) = carrier.element.virtual_spec() {
                let text = match vs.source_work_id {
                    1 => src1_text,
                    _ => src2_text,
                };
                let mut elem = carrier.element.clone();
                elem.set_virtual_content(resolve(text, vs.char_start, vs.char_end));
                *carrier = std::sync::Arc::new(crate::edition::Carrier::new(elem));
            }
        }
        let materialized = Edition::from_entries_at_positions(entries).unwrap();

        // THE GATE: derived text == concatenation of pinned spans.
        assert_eq!(
            materialized.to_text(),
            format!("{}{}", resolve(src1_text, 6, 12), resolve(src2_text, 0, 6)),
            "materialized trail text must equal pinned-span concatenation"
        );
        assert_eq!(materialized.to_text(), "sourcesecond");
        // One entry per stop, spec identity intact through the round trip.
        assert_eq!(materialized.count(), 2);
        assert!(materialized
            .cached_entries()
            .iter()
            .all(|(_, c)| c.element.virtual_spec().is_some()));
    }

    /// 4a acceptance gate: same spec -> same fingerprint, ALWAYS, for
    /// arbitrary specs — the derived document's identity contract
    /// that 4b's builder and 4c's server integration rely on.
    proptest! {
        #[test]
        fn prop_spec_identity_deterministic(
            kind_seed in 0u8..3,
            title_a in "[a-z ]{0,20}",
            title_b in "[a-z ]{0,20}",
            stops in proptest::collection::vec((1u64..100, 0usize..200, 0usize..200, 1u64..50), 0..8),
        ) {
            let kind = match kind_seed { 0 => DerivedKind::Trail, 1 => DerivedKind::Search, _ => DerivedKind::Backlinks };
            let mut a = DerivedSpec::new(kind, title_a.clone());
            let mut b = DerivedSpec::new(kind, title_b);
            for (src, s, e, rev) in &stops {
                let (s, e) = (*s, *e.max(s)); // valid ranges
                a.add_stop(stop(*src, s, e, *rev));
                b.add_stop(stop(*src, s, e, *rev));
            }
            prop_assert_eq!(a.fingerprint(), b.fingerprint());
            prop_assert!(a.validate().is_ok());
            // Rebuilding from serialization preserves identity too.
            let json = serde_json::to_string(&a).unwrap();
            let back: DerivedSpec = serde_json::from_str(&json).unwrap();
            prop_assert_eq!(a.fingerprint(), back.fingerprint());
        }
    }

    #[test]
    fn serde_round_trip_preserves_identity() {
        let mut s = DerivedSpec::new(DerivedKind::Trail, "trail name");
        s.add_stop(stop(1, 0, 10, 3));
        s.add_stop(stop(2, 5, 15, 7));
        let json = serde_json::to_string(&s).unwrap();
        let back: DerivedSpec = serde_json::from_str(&json).unwrap();
        assert_eq!(s, back);
        assert_eq!(s.fingerprint(), back.fingerprint());
    }
}
