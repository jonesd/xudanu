//! FR-76 companion: Content Match Index.
//!
//! Pre-builds a BLAKE3 fingerprint index across all works so content
//! matching is O(k) (k = fingerprint hits) instead of O(N×M) pairwise
//! comparison. This is the fix for the C1/C2 scaling cliff identified
//! by the XPS benchmark: content match was the only operation scaling
//! linearly with corpus size.

use crate::edition::edition::Edition;
use std::collections::HashMap;
use std::sync::Arc;

/// BLAKE3 content fingerprint for one entry (range element).
pub type Fingerprint = u64;

/// Where a fingerprint appears (work + position).
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct FingerprintLocation {
    pub work_id: u64,
    pub position: i64,
}

/// A shared passage between two works.
#[derive(Debug, Clone)]
pub struct SharedPassage {
    pub work_a: u64,
    pub work_b: u64,
    pub start_a: i64,
    pub end_a: i64,
    pub start_b: i64,
    pub end_b: i64,
    /// Number of consecutive fingerprint matches in this run.
    pub match_count: usize,
}

/// Pre-built content-match index across a corpus.
///
/// Build: O(total_entries) — one pass over all works.
/// Query (C1 pairwise): O(hits) — fingerprint lookups + run detection.
/// Query (C2 corpus-wide): O(hits) — same index, broader lookup.
pub struct ContentMatchIndex {
    /// fingerprint → list of locations.
    index: HashMap<Fingerprint, Vec<FingerprintLocation>>,
    /// Per-work sorted entries: (position, fingerprint) pairs.
    work_entries: HashMap<u64, Vec<(i64, Fingerprint)>>,
    /// Total entries indexed.
    total_entries: usize,
    /// Number of distinct fingerprints (vocabulary size).
    distinct_fingerprints: usize,
    /// Works indexed (work_id → entry count).
    work_counts: HashMap<u64, usize>,
}

impl ContentMatchIndex {
    /// Build the index from a set of works.
    ///
    /// Each work's entries are hashed (content fingerprint) and
    /// the (work_id, position) pair is recorded in the index.
    pub fn build(works: &[(u64, &Edition)]) -> Self {
        let mut index: HashMap<Fingerprint, Vec<FingerprintLocation>> = HashMap::new();
        let mut work_entries: HashMap<u64, Vec<(i64, Fingerprint)>> = HashMap::new();
        let mut total_entries = 0;
        let mut work_counts = HashMap::new();

        for (work_id, edition) in works {
            let entries = edition.cached_entries();
            work_counts.insert(*work_id, entries.len());
            let mut sorted_entries = Vec::with_capacity(entries.len());
            for (pos, carrier) in entries {
                let fp = fingerprint_of(carrier);
                index.entry(fp).or_default().push(FingerprintLocation {
                    work_id: *work_id,
                    position: *pos,
                });
                sorted_entries.push((*pos, fp));
                total_entries += 1;
            }
            sorted_entries.sort_by_key(|(pos, _)| *pos);
            work_entries.insert(*work_id, sorted_entries);
        }

        let distinct_fingerprints = index.len();
        Self {
            index,
            work_entries,
            total_entries,
            distinct_fingerprints,
            work_counts,
        }
    }

    /// C1: Find shared passages between two specific works.
    ///
    /// O(k) where k = number of fingerprint hits between the two works.
    /// Returns passages with ≥ min_run consecutive matches.
    pub fn shared_passages(&self, work_a: u64, work_b: u64, min_run: usize) -> Vec<SharedPassage> {
        let entries_a = self.work_entries_sorted(work_a);
        let entries_b = self.work_entries_sorted(work_b);

        if entries_a.is_empty() || entries_b.is_empty() {
            return Vec::new();
        }

        // Build a lookup for work_b's positions by fingerprint
        let mut b_by_fp: HashMap<Fingerprint, Vec<i64>> = HashMap::new();
        for (pos, fp) in &entries_b {
            b_by_fp.entry(*fp).or_default().push(*pos);
        }

        // Scan work_a's entries, looking up each in work_b
        // Collect matches as (pos_a, pos_b) pairs
        let mut matches: Vec<(i64, i64)> = Vec::new();
        for (pos_a, fp) in &entries_a {
            if let Some(b_positions) = b_by_fp.get(fp) {
                for &pos_b in b_positions {
                    matches.push((*pos_a, pos_b));
                }
            }
        }

        // Sort by pos_a and detect consecutive runs
        matches.sort_by_key(|(a, _)| *a);
        detect_shared_runs(&matches, work_a, work_b, min_run)
    }

    /// C2: Find all works that share content with the given work.
    ///
    /// O(hits × avg_locations_per_fingerprint).
    pub fn works_sharing_content(&self, work_id: u64, min_run: usize) -> Vec<(u64, usize)> {
        let mut sharing_works: HashMap<u64, usize> = HashMap::new();

        // For each fingerprint in this work, find other works that have it
        for (fp, locations) in &self.index {
            let has_work = locations.iter().any(|l| l.work_id == work_id);
            if !has_work {
                continue;
            }
            for loc in locations {
                if loc.work_id != work_id {
                    *sharing_works.entry(loc.work_id).or_insert(0) += 1;
                }
            }
        }

        // Filter by minimum match count (approximate: fingerprint hits,
        // not consecutive runs — full run detection would need positions)
        sharing_works
            .into_iter()
            .filter(|(_, count)| *count >= min_run)
            .collect()
    }

    /// Check if a specific fingerprint exists anywhere in the corpus.
    pub fn contains(&self, fp: &Fingerprint) -> bool {
        self.index.contains_key(fp)
    }

    /// All locations for a fingerprint.
    pub fn locations(&self, fp: &Fingerprint) -> &[FingerprintLocation] {
        self.index.get(fp).map(|v| v.as_slice()).unwrap_or(&[])
    }

    /// Index statistics.
    pub fn stats(&self) -> IndexStats {
        IndexStats {
            total_entries: self.total_entries,
            distinct_fingerprints: self.distinct_fingerprints,
            works: self.work_counts.len(),
            avg_locations_per_fingerprint: if self.distinct_fingerprints > 0 {
                self.total_entries as f64 / self.distinct_fingerprints as f64
            } else {
                0.0
            },
        }
    }

    /// Get sorted (position, fingerprint) pairs for a work.
    fn work_entries_sorted(&self, work_id: u64) -> Vec<(i64, Fingerprint)> {
        self.work_entries.get(&work_id).cloned().unwrap_or_default()
    }
}

/// Statistics about the index.
#[derive(Debug, Clone, serde::Serialize)]
pub struct IndexStats {
    pub total_entries: usize,
    pub distinct_fingerprints: usize,
    pub works: usize,
    pub avg_locations_per_fingerprint: f64,
}

/// Extract the content fingerprint from a carrier.
fn fingerprint_of(carrier: &Arc<crate::edition::range_element::Carrier>) -> Fingerprint {
    // Use the first 8 bytes of the BLAKE3 hash as a u64
    let fp = carrier.element.content_fingerprint();
    u64::from_be_bytes([fp[0], fp[1], fp[2], fp[3], fp[4], fp[5], fp[6], fp[7]])
}

/// Detect consecutive runs in fingerprint matches.
fn detect_shared_runs(
    matches: &[(i64, i64)],
    work_a: u64,
    work_b: u64,
    min_run: usize,
) -> Vec<SharedPassage> {
    let mut passages = Vec::new();
    if matches.is_empty() {
        return passages;
    }

    let mut run_start = 0;
    for i in 1..=matches.len() {
        let is_consecutive = i < matches.len()
            && matches[i].0 == matches[i - 1].0 + 1
            && matches[i].1 == matches[i - 1].1 + 1;

        if !is_consecutive {
            let run_len = i - run_start;
            if run_len >= min_run {
                passages.push(SharedPassage {
                    work_a,
                    work_b,
                    start_a: matches[run_start].0,
                    end_a: matches[i - 1].0 + 1,
                    start_b: matches[run_start].1,
                    end_b: matches[i - 1].1 + 1,
                    match_count: run_len,
                });
            }
            run_start = i;
        }
    }

    passages
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::edition::Edition;
    use std::sync::Arc;

    // ── Index construction tests ─────────────────────────────────

    #[test]
    fn build_empty_corpus() {
        let idx = ContentMatchIndex::build(&[]);
        let stats = idx.stats();
        assert_eq!(stats.total_entries, 0);
        assert_eq!(stats.distinct_fingerprints, 0);
        assert_eq!(stats.works, 0);
    }

    #[test]
    fn build_single_work() {
        let ed = Edition::from_text("hello world");
        let idx = ContentMatchIndex::build(&[(1, &ed)]);
        assert_eq!(idx.stats().total_entries, ed.cached_entries().len());
        assert_eq!(idx.stats().works, 1);
        assert!(idx.stats().distinct_fingerprints > 0);
    }

    #[test]
    fn build_two_works() {
        let ed1 = Edition::from_text("hello world");
        let ed2 = Edition::from_text("hello there");
        let idx = ContentMatchIndex::build(&[(1, &ed1), (2, &ed2)]);
        assert_eq!(idx.stats().works, 2);
        assert!(idx.stats().total_entries > 0);
    }

    #[test]
    fn duplicate_fingerprints_tracked() {
        let ed1 = Edition::from_text("the same text appears");
        let ed2 = Edition::from_text("the same text appears");
        let idx = ContentMatchIndex::build(&[(1, &ed1), (2, &ed2)]);
        // With identical text, many fingerprints should have 2+ locations
        let stats = idx.stats();
        assert!(
            stats.avg_locations_per_fingerprint > 1.0,
            "duplicate content should have multiple locations per fingerprint"
        );
    }

    // ── Lookup tests ──────────────────────────────────────────────

    #[test]
    fn contains_returns_false_for_missing() {
        let ed = Edition::from_text("unique content");
        let idx = ContentMatchIndex::build(&[(1, &ed)]);
        let fake_fp: Fingerprint = 0xDEADBEEF;
        assert!(!idx.contains(&fake_fp));
    }

    #[test]
    fn locations_returns_empty_for_missing() {
        let ed = Edition::from_text("some content");
        let idx = ContentMatchIndex::build(&[(1, &ed)]);
        assert!(idx.locations(&0xDEADBEEF).is_empty());
    }

    // ── Corpus-wide query (C2) tests ─────────────────────────────

    #[test]
    fn works_sharing_content_finds_duplicates() {
        let ed1 = Edition::from_text("shared passage between documents");
        let ed2 = Edition::from_text("shared passage between documents");
        let ed3 = Edition::from_text("zyzqx jwvbn klrop vfyts zyxwv 98765");

        let idx = ContentMatchIndex::build(&[(1, &ed1), (2, &ed2), (3, &ed3)]);
        let sharing = idx.works_sharing_content(1, 1);

        assert!(
            sharing.iter().any(|(w, _)| *w == 2),
            "work 2 shares content with work 1"
        );
        let w2_hits = sharing
            .iter()
            .find(|(w, _)| *w == 2)
            .map(|(_, c)| *c)
            .unwrap_or(0);
        let w3_hits = sharing
            .iter()
            .find(|(w, _)| *w == 3)
            .map(|(_, c)| *c)
            .unwrap_or(0);
        assert!(
            w2_hits > w3_hits,
            "work 2 should share more content than work 3 (w2={w2_hits}, w3={w3_hits})"
        );
    }

    #[test]
    fn works_sharing_content_returns_self_excluded() {
        let ed = Edition::from_text("some text");
        let idx = ContentMatchIndex::build(&[(1, &ed)]);
        let sharing = idx.works_sharing_content(1, 0);
        assert!(
            !sharing.iter().any(|(w, _)| *w == 1),
            "a work should not share with itself"
        );
    }

    #[test]
    fn works_sharing_content_respects_min_run() {
        let ed1 = Edition::from_text("one shared word");
        let ed2 = Edition::from_text("only one shared word here");
        let idx = ContentMatchIndex::build(&[(1, &ed1), (2, &ed2)]);

        // With high min_run, fewer matches qualify
        let strict = idx.works_sharing_content(1, 100);
        assert!(
            strict.is_empty() || strict.iter().all(|(_, c)| *c >= 100),
            "strict filter should only return works with ≥100 fingerprint hits"
        );
    }

    // ── Run detection tests ───────────────────────────────────────

    #[test]
    fn detect_runs_finds_consecutive_matches() {
        let matches = vec![(0, 10), (1, 11), (2, 12), (5, 20), (6, 21)];
        let runs = detect_shared_runs(&matches, 1, 2, 3);
        assert_eq!(runs.len(), 1, "one run of 3, one run of 2 (below min)");
        assert_eq!(runs[0].start_a, 0);
        assert_eq!(runs[0].end_a, 3);
        assert_eq!(runs[0].start_b, 10);
        assert_eq!(runs[0].end_b, 13);
        assert_eq!(runs[0].match_count, 3);
    }

    #[test]
    fn detect_runs_empty_matches() {
        let runs = detect_shared_runs(&[], 1, 2, 1);
        assert!(runs.is_empty());
    }

    #[test]
    fn detect_runs_single_match() {
        let matches = vec![(0, 5)];
        let runs = detect_shared_runs(&matches, 1, 2, 1);
        assert_eq!(runs.len(), 1);
        assert_eq!(runs[0].match_count, 1);
    }

    #[test]
    fn detect_runs_filters_below_min() {
        let matches = vec![(0, 0), (1, 1)]; // run of 2
        let runs = detect_shared_runs(&matches, 1, 2, 3); // min_run=3
        assert!(runs.is_empty(), "run of 2 should not match min_run=3");
    }

    // ── Statistics tests ──────────────────────────────────────────

    #[test]
    fn stats_track_work_count() {
        let eds: Vec<Edition> = (0..5)
            .map(|i| Edition::from_text(&format!("document {i}")))
            .collect();
        let refs: Vec<(u64, &Edition)> = eds
            .iter()
            .enumerate()
            .map(|(i, e)| (i as u64 + 1, e))
            .collect();
        let idx = ContentMatchIndex::build(&refs);
        assert_eq!(idx.stats().works, 5);
    }

    // ── Performance tests ─────────────────────────────────────────

    #[test]
    fn build_100_works_under_1s() {
        let start = std::time::Instant::now();
        let eds: Vec<Edition> = (0..100)
            .map(|i| {
                Edition::from_text(&format!(
                    "document {i} with some content that is unique per document {i}"
                ))
            })
            .collect();
        let refs: Vec<(u64, &Edition)> = eds
            .iter()
            .enumerate()
            .map(|(i, e)| (i as u64 + 1, e))
            .collect();
        let _idx = ContentMatchIndex::build(&refs);
        let elapsed = start.elapsed();
        assert!(
            elapsed.as_secs_f64() < 1.0,
            "100 small works should index in <1s, took {:.1}ms",
            elapsed.as_secs_f64() * 1000.0
        );
    }

    #[test]
    fn build_1000_works_under_5s() {
        let start = std::time::Instant::now();
        let eds: Vec<Edition> = (0..1000)
            .map(|i| {
                Edition::from_text(&format!(
                    "document {i} with unique content for scale testing {i}"
                ))
            })
            .collect();
        let refs: Vec<(u64, &Edition)> = eds
            .iter()
            .enumerate()
            .map(|(i, e)| (i as u64 + 1, e))
            .collect();
        let _idx = ContentMatchIndex::build(&refs);
        let elapsed = start.elapsed();
        assert!(
            elapsed.as_secs_f64() < 5.0,
            "1000 small works should index in <5s, took {:.1}ms",
            elapsed.as_secs_f64() * 1000.0
        );
    }
}
