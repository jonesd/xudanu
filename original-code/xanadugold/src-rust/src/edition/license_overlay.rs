//! FR-38 Phase 2: license summary overlay.
//!
//! Gold lineage: CanopyCrum flag trees "widded by ORing up the
//! canopy" (`src/server/canopyx.hxx`) let permission queries prune
//! whole subtrees. Xudanu's overlay preserves that query shape —
//! O(log r + b) with b = ownership boundaries crossed — as a
//! run-length ownership index over the edition's char space.
//!
//! Two deliberate design rules:
//!
//! 1. **Ownership, not licenses, is indexed.** An owner's license can
//!    change without the content changing (the author re-licenses
//!    their work). Baking classes into the index would make it stale
//!    in a way content generations cannot detect. Classes resolve at
//!    query time through the caller's owner->license closure.
//!
//! 2. **Separation from content (FR-38 design rule).** Nothing here
//!    enters content crums. The overlay is derived data, rebuilt
//!    lazily; its absence or staleness never affects content
//!    correctness — queries fall back to the Phase 1 ground-truth
//!    scan (`Edition::span_license_classes`), which is also this
//!    module's regression oracle.

use std::sync::Arc;

use super::backend::BeId;
use super::edition::SpanLicenseSummary;
use super::range_element::Carrier;
use super::work::{License, LicenseClass};

/// One ownership run: a char range whose content is controlled by a
/// single provenance owner (`None` = no provenance; resolves to
/// UNKNOWN at query time — the safe default).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct OwnerRun {
    pub char_start: usize,
    pub char_end: usize,
    pub owner: Option<BeId>,
}

/// Run-length ownership index over an edition. Build O(n); query
/// O(log r + b). Server-layer caches one per work keyed by content
/// generation (see `Server::license_overlay_for`).
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct LicenseOverlay {
    runs: Vec<OwnerRun>,
}

impl LicenseOverlay {
    /// Build from an edition's flat view (sorted entries + cumulative
    /// char starts). Adjacent entries with the same provenance owner
    /// merge into one run; zero-char entries adopt the ongoing run
    /// (same semantics as the Phase 1 ground truth).
    pub fn build(entries: &[(i64, Arc<Carrier>)], char_starts: &[usize]) -> Self {
        let mut runs: Vec<OwnerRun> = Vec::new();
        for (idx, (_, carrier)) in entries.iter().enumerate() {
            let len = carrier.char_len();
            if len == 0 {
                continue;
            }
            let start = char_starts[idx];
            let end = start + len;
            let owner = carrier.provenance.as_ref().map(|p| p.author_club_id);
            match runs.last_mut() {
                Some(last) if last.owner == owner => last.char_end = end,
                _ => runs.push(OwnerRun {
                    char_start: start,
                    char_end: end,
                    owner,
                }),
            }
        }
        LicenseOverlay { runs }
    }

    pub fn runs(&self) -> &[OwnerRun] {
        &self.runs
    }

    pub fn is_empty(&self) -> bool {
        self.runs.is_empty()
    }

    /// License classes covering [char_start, char_end): binary search
    /// the first overlapping run, walk while inside, resolve each
    /// run's owner through `owner_license` at query time. The closure
    /// receives `Option<BeId>` (None = provenance-less run) so callers
    /// can apply work-level fallbacks for ownerless content. Result
    /// shape matches the Phase 1 ground truth (`span_license_classes`)
    /// — `boundaries` lists clipped ownership runs with resolved
    /// classes.
    pub fn query<F>(
        &self,
        char_start: usize,
        char_end: usize,
        owner_license: F,
    ) -> SpanLicenseSummary
    where
        F: Fn(Option<BeId>) -> Option<License>,
    {
        let mut summary = SpanLicenseSummary::default();
        if char_start >= char_end || self.runs.is_empty() {
            return summary;
        }
        let mut idx = self.runs.partition_point(|r| r.char_end <= char_start);
        while idx < self.runs.len() {
            let run = &self.runs[idx];
            if run.char_start >= char_end {
                break;
            }
            let clip_start = run.char_start.max(char_start);
            let clip_end = run.char_end.min(char_end);
            let class = match owner_license(run.owner) {
                Some(l) => l.license_class(),
                None => LicenseClass::UNKNOWN,
            };
            summary.total_class = summary.total_class.combine(class);
            summary.pending_class = class;
            if class.contains(LicenseClass::UNKNOWN) {
                summary.unresolved_entries += 1;
            }
            summary
                .boundaries
                .push((clip_start, clip_end, run.owner, class));
            summary.distinct_owners += 1;
            idx += 1;
        }
        summary
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::edition::Edition;
    use crate::edition::provenance::{AuthorType, ElementProvenance};
    use crate::edition::range_element::RangeElement;
    use crate::edition::work::License;
    use proptest::prelude::*;

    fn prov(owner: BeId) -> ElementProvenance {
        ElementProvenance {
            author_public_key: [owner as u8; 32],
            author_display_name: format!("owner-{}", owner),
            author_club_id: owner,
            timestamp: 1,
            author_type: AuthorType::Human,
            llm_model: None,
            historical_author_id: None,
            source_work_id: None,
            transcluded_by: None,
            derived_by: None,
        }
    }

    fn chunk(text: &str, owner: Option<BeId>) -> (i64, Arc<Carrier>) {
        let c = match owner {
            Some(o) => Carrier::new(RangeElement::text(text.to_string())).with_provenance(prov(o)),
            None => Carrier::new(RangeElement::text(text.to_string())),
        };
        (0, Arc::new(c))
    }

    fn licenses(owner: Option<BeId>) -> Option<License> {
        match owner {
            Some(1) => Some(License::Transcopyright),
            Some(2) => Some(License::AllRightsReserved),
            Some(3) => Some(License::PublicDomain),
            // Ownerless content: no license determinable -> UNKNOWN
            // (server callers layer a work-level fallback on top).
            _ => None,
        }
    }

    #[test]
    fn build_merges_adjacent_same_owner() {
        let entries = vec![
            chunk("aa", Some(1)),
            chunk("bb", Some(1)),
            chunk("cc", Some(2)),
        ];
        let ed = Edition::from_entries(entries);
        let ov = ed.license_overlay();
        let runs = ov.runs();
        assert_eq!(runs.len(), 2, "aa+bb merge under owner 1");
        assert_eq!(runs[0].char_start, 0);
        assert_eq!(runs[0].char_end, 4);
        assert_eq!(runs[0].owner, Some(1));
        assert_eq!(runs[1].char_start, 4);
        assert_eq!(runs[1].char_end, 6);
    }

    #[test]
    fn query_single_run_one_lookup() {
        let entries = vec![chunk("hello ", Some(1)), chunk("world", Some(1))];
        let ov = Edition::from_entries(entries).license_overlay();
        let s = ov.query(0, 11, licenses);
        assert_eq!(s.distinct_owners, 1);
        assert!(s.total_class.contains(LicenseClass::TRANSCLUSION_OK));
        assert!(!s.total_class.contains(LicenseClass::RESTRICTED));
    }

    #[test]
    fn query_clips_and_reports_boundaries() {
        let entries = vec![chunk("aaaa", Some(1)), chunk("bbbb", Some(2))];
        let ov = Edition::from_entries(entries).license_overlay();
        // Span crossing the boundary at char 4.
        let s = ov.query(2, 6, licenses);
        assert_eq!(s.distinct_owners, 2);
        assert_eq!(
            s.boundaries[0],
            (2, 4, Some(1), LicenseClass::TRANSCLUSION_OK)
        );
        assert_eq!(s.boundaries[1], (4, 6, Some(2), LicenseClass::RESTRICTED));
        assert!(s.total_class.contains(LicenseClass::TRANSCLUSION_OK));
        assert!(s.total_class.contains(LicenseClass::RESTRICTED));
    }

    #[test]
    fn query_empty_and_out_of_range() {
        let entries = vec![chunk("abc", Some(1))];
        let ov = Edition::from_entries(entries).license_overlay();
        assert!(ov.query(1, 1, licenses).total_class.is_empty());
        assert!(ov.query(5, 9, licenses).total_class.is_empty());
    }

    #[test]
    fn unowned_runs_resolve_unknown() {
        let entries = vec![chunk("abc", None)];
        let ov = Edition::from_entries(entries).license_overlay();
        let s = ov.query(0, 3, licenses);
        assert!(s.total_class.contains(LicenseClass::UNKNOWN));
        assert_eq!(s.boundaries[0].2, None);
    }

    /// Classes resolve at QUERY time: the same overlay yields
    /// different classes under different owner->license mappings —
    /// re-licensing never requires rebuilding the index.
    #[test]
    fn licenses_resolve_at_query_time() {
        let entries = vec![chunk("abc", Some(1))];
        let ov = Edition::from_entries(entries).license_overlay();

        let as_tco = ov.query(0, 3, |o| (o == Some(1)).then_some(License::Transcopyright));
        assert!(as_tco.total_class.contains(LicenseClass::TRANSCLUSION_OK));

        let as_arr = ov.query(0, 3, |o| {
            (o == Some(1)).then_some(License::AllRightsReserved)
        });
        assert!(as_arr.total_class.contains(LicenseClass::RESTRICTED));
        assert!(!as_arr.total_class.contains(LicenseClass::TRANSCLUSION_OK));
    }

    /// FR-38 Phase 2 acceptance: the overlay must equal the Phase 1
    /// ground-truth scan for arbitrary provenance layouts and query
    /// ranges (total class, boundaries, distinct owners).
    proptest! {
        #[test]
        fn prop_overlay_equals_ground_truth(
            chunks in proptest::collection::vec(("[a-z]{1,8}", 0u8..5), 1..12),
            range_seed in proptest::collection::vec((0u16..200, 0u16..200), 0..6),
        ) {
            let entries: Vec<(i64, Arc<Carrier>)> = chunks
                .iter()
                .map(|(t, o)| chunk(t, match o { 0 => None, n => Some(*n as BeId) }))
                .collect();
            let ed = Edition::from_entries(entries);
            let ov = ed.license_overlay();
            let total = ed.char_len();

            for (s, e) in range_seed {
                let s = (s as usize) % (total + 1);
                let e = (e as usize) % (total + 1);
                let (s, e) = if s <= e { (s, e) } else { (e, s) };

                // Ground truth resolves owners internally (BeId ->
                // license); the overlay hands runs' Option owners to
                // the caller. Same mapping, two shapes.
                let gt_licenses = |owner: BeId| -> Option<License> {
                    licenses(Some(owner))
                };
                let via_overlay = ov.query(s, e, licenses);
                let ground_truth = ed.span_license_classes(s, e, gt_licenses);

                prop_assert_eq!(via_overlay.total_class, ground_truth.total_class, "range [{},{})", s, e);
                prop_assert_eq!(via_overlay.boundaries, ground_truth.boundaries, "range [{},{})", s, e);
                prop_assert_eq!(via_overlay.distinct_owners, ground_truth.distinct_owners, "range [{},{})", s, e);
            }
        }
    }
}
