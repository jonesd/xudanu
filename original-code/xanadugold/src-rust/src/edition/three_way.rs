use std::sync::Arc;

use super::edition::Edition;
use super::mapping::Mapping;
use super::provenance::SpanProvenance;
use super::range_element::{Carrier, RangeElement};
use super::xn_region::XnRegion;

#[derive(Debug, Clone, PartialEq)]
pub struct AlignedRun {
    pub base_positions: Vec<i64>,
    pub a_positions: Vec<i64>,
    pub b_positions: Vec<i64>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct DiffRegion {
    pub base_start: i64,
    pub base_end: i64,
    pub edition_start: i64,
    pub edition_end: i64,
}

#[derive(Debug, Clone, PartialEq)]
pub struct ConflictRegion {
    pub base_start: i64,
    pub base_end: i64,
    pub a_start: i64,
    pub a_end: i64,
    pub b_start: i64,
    pub b_end: i64,
}

#[derive(Debug, Clone, PartialEq)]
pub struct ThreeWayDiff {
    pub unchanged: Vec<AlignedRun>,
    pub only_a: Vec<DiffRegion>,
    pub only_b: Vec<DiffRegion>,
    pub conflict: Vec<ConflictRegion>,
}

impl ThreeWayDiff {
    /// Returns the set of base positions that are unchanged in both A and B.
    /// Uses region algebra for clean set computation.
    pub fn unchanged_region(&self) -> XnRegion {
        let mut region = XnRegion::empty();
        for run in &self.unchanged {
            for &pos in &run.base_positions {
                region = region.with(pos);
            }
        }
        region
    }

    /// Returns the set of base positions that changed (delta of base vs union of A and B).
    /// This is: all_base_positions.minus(unchanged_region)
    /// Useful for comparison UIs to compute change density / heat maps.
    pub fn changed_region(&self, base_len: usize) -> XnRegion {
        let full = XnRegion::interval(0, base_len as i64);
        full.minus(&self.unchanged_region())
    }

    /// Returns the symmetric difference between A-only and B-only changes.
    /// High values indicate divergent edits; low values indicate complementary edits.
    pub fn conflict_density(&self) -> f64 {
        let total = self.only_a.len() + self.only_b.len() + self.conflict.len();
        if total == 0 {
            return 0.0;
        }
        self.conflict.len() as f64 / total as f64
    }

    /// Decompose unchanged regions into clean disjoint intervals.
    /// Uses simple_regions() for correct handling of gaps.
    pub fn unchanged_intervals(&self) -> Vec<(i64, i64)> {
        let region = self.unchanged_region();
        region.simple_regions()
    }

    /// Decompose changed regions into clean disjoint intervals.
    pub fn changed_intervals(&self, base_len: usize) -> Vec<(i64, i64)> {
        self.changed_region(base_len).simple_regions()
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MergeStrategy {
    LastWriterWins,
}

#[derive(Debug, Clone)]
pub struct MergeResult {
    pub merged: Edition,
    pub a_to_merged: Mapping,
    pub b_to_merged: Mapping,
}

#[derive(Debug, Clone, PartialEq)]
pub struct MergeConflict {
    pub region: ConflictRegion,
    pub a: Edition,
    pub b: Edition,
}

enum Segment {
    Unchanged {
        base_positions: Vec<i64>,
        a_positions: Vec<i64>,
        b_positions: Vec<i64>,
    },
    OnlyA {
        base_start: i64,
        base_end: i64,
        a_start: i64,
        a_end: i64,
    },
    OnlyB {
        base_start: i64,
        base_end: i64,
        b_start: i64,
        b_end: i64,
    },
    Conflict {
        base_start: i64,
        base_end: i64,
        a_start: i64,
        a_end: i64,
        b_start: i64,
        b_end: i64,
    },
    InsertA {
        after_base_pos: i64,
        a_start: i64,
        a_end: i64,
    },
    InsertB {
        after_base_pos: i64,
        b_start: i64,
        b_end: i64,
    },
}

fn fp(entry: &(i64, Arc<Carrier>)) -> [u8; 32] {
    entry.1.element.content_fingerprint()
}

struct PosEntry {
    pos: i64,
    idx: usize,
}

pub fn three_way_diff(base: &Edition, a: &Edition, b: &Edition) -> ThreeWayDiff {
    let base_crum = base.crum();
    let a_crum = a.crum();
    let b_crum = b.crum();

    if base_crum.is_some() && base_crum == a_crum && base_crum == b_crum {
        let base_positions: Vec<i64> = base.cached_entries().iter().map(|(p, _)| *p).collect();
        return ThreeWayDiff {
            unchanged: vec![AlignedRun {
                a_positions: base_positions.clone(),
                b_positions: base_positions.clone(),
                base_positions,
            }],
            only_a: Vec::new(),
            only_b: Vec::new(),
            conflict: Vec::new(),
        };
    }

    let base_e = base.cached_entries();
    let a_e = a.cached_entries();
    let b_e = b.cached_entries();

    if base_e.is_empty() && a_e.is_empty() && b_e.is_empty() {
        return ThreeWayDiff {
            unchanged: Vec::new(),
            only_a: Vec::new(),
            only_b: Vec::new(),
            conflict: Vec::new(),
        };
    }

    let base_to_a = if base_crum == a_crum && base_crum.is_some() {
        (0..base_e.len()).map(Some).collect::<Vec<_>>()
    } else {
        compute_alignment(&base_e, &a_e)
    };
    let base_to_b = if base_crum == b_crum && base_crum.is_some() {
        (0..base_e.len()).map(Some).collect::<Vec<_>>()
    } else {
        compute_alignment(&base_e, &b_e)
    };

    let segments = build_segments(&base_e, &a_e, &b_e, &base_to_a, &base_to_b);

    let mut unchanged = Vec::new();
    let mut only_a = Vec::new();
    let mut only_b = Vec::new();
    let mut conflict = Vec::new();

    for seg in segments {
        match seg {
            Segment::Unchanged {
                base_positions,
                a_positions,
                b_positions,
            } => unchanged.push(AlignedRun {
                base_positions,
                a_positions,
                b_positions,
            }),
            Segment::OnlyA {
                base_start,
                base_end,
                a_start,
                a_end,
            } => only_a.push(DiffRegion {
                base_start,
                base_end,
                edition_start: a_start,
                edition_end: a_end,
            }),
            Segment::OnlyB {
                base_start,
                base_end,
                b_start,
                b_end,
            } => only_b.push(DiffRegion {
                base_start,
                base_end,
                edition_start: b_start,
                edition_end: b_end,
            }),
            Segment::Conflict {
                base_start,
                base_end,
                a_start,
                a_end,
                b_start,
                b_end,
            } => conflict.push(ConflictRegion {
                base_start,
                base_end,
                a_start,
                a_end,
                b_start,
                b_end,
            }),
            Segment::InsertA {
                after_base_pos,
                a_start,
                a_end,
            } => only_a.push(DiffRegion {
                base_start: after_base_pos,
                base_end: after_base_pos,
                edition_start: a_start,
                edition_end: a_end,
            }),
            Segment::InsertB {
                after_base_pos,
                b_start,
                b_end,
            } => only_b.push(DiffRegion {
                base_start: after_base_pos,
                base_end: after_base_pos,
                edition_start: b_start,
                edition_end: b_end,
            }),
        }
    }

    ThreeWayDiff {
        unchanged,
        only_a,
        only_b,
        conflict,
    }
}

fn compute_chunk_matches(
    source: &[(i64, Arc<Carrier>)],
    target: &[(i64, Arc<Carrier>)],
    chunk_size: usize,
) -> Vec<bool> {
    if chunk_size == 0 || source.is_empty() {
        return Vec::new();
    }
    let n_chunks = (source.len() + chunk_size - 1) / chunk_size;
    let mut matches = Vec::with_capacity(n_chunks);
    for chunk_idx in 0..n_chunks {
        let start = chunk_idx * chunk_size;
        let end = (start + chunk_size).min(source.len());
        let src_chunk = &source[start..end];
        let tgt_chunk = &target[start..end.min(target.len())];
        let m = src_chunk.len() == tgt_chunk.len()
            && src_chunk
                .iter()
                .zip(tgt_chunk.iter())
                .all(|((sp, sc), (tp, tc))| {
                    sp == tp && sc.element.content_fingerprint() == tc.element.content_fingerprint()
                });
        matches.push(m);
    }
    matches
}

fn compute_alignment(
    source: &[(i64, Arc<Carrier>)],
    target: &[(i64, Arc<Carrier>)],
) -> Vec<Option<usize>> {
    if source.is_empty() {
        return Vec::new();
    }

    if source.len() == target.len() && source.len() > 128 {
        let chunk_size = 64usize;
        let matching = compute_chunk_matches(source, target, chunk_size);
        if matching.iter().all(|&m| m) {
            return (0..source.len()).map(Some).collect();
        }
    }

    // Patience-style alignment (PERF-PLAN S7), O(n):
    // 1. Anchor on entries whose fingerprint is unique in BOTH source
    //    and target (greedy-monotone). On typical prose this pins the
    //    long common runs exactly where the historical quadratic
    //    seed/extend search found them.
    // 2. Extend each anchor forward and backward over matching
    //    fingerprints (the run-growth the old seeds did n^2 work to
    //    rediscover).
    // 3. Cursor-fill remaining gaps greedily in list order (the S6
    //    rule), which handles duplicate-heavy spans the anchors skip.
    // Monotone by construction in phases 1-2; phase 3 is monotone per
    // gap. Replaces the O(n^2)-on-duplicates seed loop.
    let source_fps: Vec<[u8; 32]> = source.iter().map(|e| fp(e)).collect();
    let target_fps: Vec<[u8; 32]> = target.iter().map(|e| fp(e)).collect();

    let mut target_by_fp: std::collections::HashMap<[u8; 32], Vec<usize>> =
        std::collections::HashMap::new();
    for (j, f) in target_fps.iter().enumerate() {
        target_by_fp.entry(*f).or_default().push(j);
    }
    let mut source_fp_count: std::collections::HashMap<[u8; 32], usize> =
        std::collections::HashMap::new();
    for f in &source_fps {
        *source_fp_count.entry(*f).or_insert(0) += 1;
    }

    let mut alignment: Vec<Option<usize>> = vec![None; source.len()];
    let mut target_used = vec![false; target.len()];

    // Phase 1: unique anchors, kept monotone (greedy LIS).
    let mut anchors: Vec<(usize, usize)> = Vec::new();
    let mut last_t: i64 = -1;
    for (i, f) in source_fps.iter().enumerate() {
        if source_fp_count.get(f) == Some(&1) && target_by_fp.get(f).map(|v| v.len()) == Some(1) {
            let j = target_by_fp[f][0];
            if j as i64 > last_t {
                anchors.push((i, j));
                last_t = j as i64;
            }
        }
    }

    // Phase 2: extend runs around anchors (anchors ascending).
    for &(i0, j0) in &anchors {
        if alignment[i0].is_none() && !target_used[j0] {
            alignment[i0] = Some(j0);
            target_used[j0] = true;
        }
        let mut i = i0 + 1;
        let mut j = j0 + 1;
        while i < source.len()
            && j < target.len()
            && source_fps[i] == target_fps[j]
            && alignment[i].is_none()
            && !target_used[j]
        {
            alignment[i] = Some(j);
            target_used[j] = true;
            i += 1;
            j += 1;
        }
        let mut i = i0 as i64 - 1;
        let mut j = j0 as i64 - 1;
        while i >= 0
            && j >= 0
            && source_fps[i as usize] == target_fps[j as usize]
            && alignment[i as usize].is_none()
            && !target_used[j as usize]
        {
            alignment[i as usize] = Some(j as usize);
            target_used[j as usize] = true;
            i -= 1;
            j -= 1;
        }
    }

    // Phase 3: monotone cursor fill of the gaps.
    let mut cursors: std::collections::HashMap<[u8; 32], usize> = std::collections::HashMap::new();
    let mut last_j: i64 = -1;
    for (i, f) in source_fps.iter().enumerate() {
        if alignment[i].is_some() {
            last_j = alignment[i].unwrap() as i64;
            continue;
        }
        if let Some(positions) = target_by_fp.get(f) {
            let cur = cursors.entry(*f).or_insert(0);
            while *cur < positions.len()
                && ((positions[*cur] as i64) < last_j || target_used[positions[*cur]])
            {
                *cur += 1;
            }
            if *cur < positions.len() {
                let j = positions[*cur];
                *cur += 1;
                alignment[i] = Some(j);
                target_used[j] = true;
                last_j = j as i64;
            }
        }
    }

    alignment
}

#[allow(clippy::cognitive_complexity)]
fn mark_claimed_indices(
    segments: &[Segment],
    a_e: &[(i64, Arc<Carrier>)],
    b_e: &[(i64, Arc<Carrier>)],
    a_matched: &mut std::collections::HashSet<usize>,
    b_matched: &mut std::collections::HashSet<usize>,
) {
    fn mark_range(
        entries: &[(i64, Arc<Carrier>)],
        start: i64,
        end: i64,
        matched: &mut std::collections::HashSet<usize>,
    ) {
        // Bounded: entries are position-sorted.
        let from = entries.partition_point(|(p, _)| *p < start);
        let mut to = from;
        while to < entries.len() && entries[to].0 < end {
            to += 1;
        }
        for idx in from..to {
            matched.insert(idx);
        }
    }

    for seg in segments {
        match seg {
            Segment::Unchanged {
                a_positions,
                b_positions,
                ..
            } => {
                // Set membership: the run is O(n) long, so the
                // historical per-entry Vec::contains made this
                // O(n x run) — quadratic on large unchanged regions.
                let a_set: std::collections::HashSet<&i64> = a_positions.iter().collect();
                for (idx, (pos, _)) in a_e.iter().enumerate() {
                    if a_set.contains(pos) {
                        a_matched.insert(idx);
                    }
                }
                let b_set: std::collections::HashSet<&i64> = b_positions.iter().collect();
                for (idx, (pos, _)) in b_e.iter().enumerate() {
                    if b_set.contains(pos) {
                        b_matched.insert(idx);
                    }
                }
            }
            Segment::OnlyA { a_start, a_end, .. } => {
                mark_range(a_e, *a_start, *a_end, a_matched);
            }
            Segment::OnlyB { b_start, b_end, .. } => {
                mark_range(b_e, *b_start, *b_end, b_matched);
            }
            Segment::Conflict {
                a_start,
                a_end,
                b_start,
                b_end,
                ..
            } => {
                mark_range(a_e, *a_start, *a_end, a_matched);
                mark_range(b_e, *b_start, *b_end, b_matched);
            }
            Segment::InsertA { a_start, a_end, .. } => {
                mark_range(a_e, *a_start, *a_end, a_matched);
            }
            Segment::InsertB { b_start, b_end, .. } => {
                mark_range(b_e, *b_start, *b_end, b_matched);
            }
        }
    }
}

fn build_segments(
    base_e: &[(i64, Arc<Carrier>)],
    a_e: &[(i64, Arc<Carrier>)],
    b_e: &[(i64, Arc<Carrier>)],
    base_to_a: &[Option<usize>],
    base_to_b: &[Option<usize>],
) -> Vec<Segment> {
    let mut segments = Vec::new();
    let mut i = 0usize;
    let n = base_e.len();

    let mut a_matched: std::collections::HashSet<usize> =
        base_to_a.iter().filter_map(|&opt| opt).collect();
    let mut b_matched: std::collections::HashSet<usize> =
        base_to_b.iter().filter_map(|&opt| opt).collect();

    while i < n {
        let a_match = base_to_a.get(i).copied().flatten();
        let b_match = base_to_b.get(i).copied().flatten();

        if a_match.is_some() && b_match.is_some() {
            let mut base_positions = vec![base_e[i].0];
            let mut a_positions = vec![a_e[a_match.unwrap()].0];
            let mut b_positions = vec![b_e[b_match.unwrap()].0];
            let mut a_indices = vec![a_match.unwrap()];
            let mut b_indices = vec![b_match.unwrap()];
            let mut j = i + 1;
            while j < n {
                let aj = base_to_a.get(j).copied().flatten();
                let bj = base_to_b.get(j).copied().flatten();
                if aj.is_some() && bj.is_some() {
                    base_positions.push(base_e[j].0);
                    a_positions.push(a_e[aj.unwrap()].0);
                    b_positions.push(b_e[bj.unwrap()].0);
                    a_indices.push(aj.unwrap());
                    b_indices.push(bj.unwrap());
                    j += 1;
                } else {
                    break;
                }
            }

            // Gap detection by INDEX adjacency: a real insertion exists
            // iff consecutive aligned entries are not adjacent in the
            // edition's entry list. Value-based (+1) checks over-split
            // gap-allocated (sparse) layouts where consecutive positions
            // legitimately differ by more than 1 (PERF-PLAN S7).
            // saturating_sub: seed alignments are not guaranteed
            // monotone; a decrease means "no gap" (matches the
            // historical value-check behavior on negative deltas).
            let mut start = 0;
            for k in 1..base_positions.len() {
                let a_gap = a_indices[k].saturating_sub(a_indices[k - 1]) > 1;
                let b_gap = b_indices[k].saturating_sub(b_indices[k - 1]) > 1;
                if a_gap || b_gap {
                    segments.push(Segment::Unchanged {
                        base_positions: base_positions[start..k].to_vec(),
                        a_positions: a_positions[start..k].to_vec(),
                        b_positions: b_positions[start..k].to_vec(),
                    });
                    if a_gap {
                        let gap_start = a_positions[k - 1] + 1;
                        let gap_end = a_positions[k];
                        for idx in a_indices[k - 1] + 1..a_indices[k] {
                            a_matched.insert(idx);
                        }
                        segments.push(Segment::InsertA {
                            after_base_pos: base_positions[k - 1],
                            a_start: gap_start,
                            a_end: gap_end,
                        });
                    }
                    if b_gap {
                        let gap_start = b_positions[k - 1] + 1;
                        let gap_end = b_positions[k];
                        for idx in b_indices[k - 1] + 1..b_indices[k] {
                            b_matched.insert(idx);
                        }
                        segments.push(Segment::InsertB {
                            after_base_pos: base_positions[k - 1],
                            b_start: gap_start,
                            b_end: gap_end,
                        });
                    }
                    start = k;
                }
            }
            if start < base_positions.len() {
                segments.push(Segment::Unchanged {
                    base_positions: base_positions[start..].to_vec(),
                    a_positions: a_positions[start..].to_vec(),
                    b_positions: b_positions[start..].to_vec(),
                });
            }
            i = j;
        } else {
            let base_start = base_e[i].0;
            let mut base_end_idx = i + 1;
            let mut a_gap_start = a_match.map(|idx| a_e[idx].0);
            let mut a_gap_end: Option<i64> = None;
            let mut b_gap_start = b_match.map(|idx| b_e[idx].0);
            let mut b_gap_end: Option<i64> = None;

            if let Some(ai) = a_match {
                a_gap_end = Some(a_e[ai].0);
            }
            if let Some(bi) = b_match {
                b_gap_end = Some(b_e[bi].0);
            }

            while base_end_idx < n {
                let aj = base_to_a.get(base_end_idx).copied().flatten();
                let bj = base_to_b.get(base_end_idx).copied().flatten();
                if aj.is_some() && bj.is_some() {
                    break;
                }
                if let Some(ai) = aj {
                    if a_gap_start.is_none() {
                        a_gap_start = Some(a_e[ai].0);
                    }
                    a_gap_end = Some(a_e[ai].0 + 1);
                }
                if let Some(bi) = bj {
                    if b_gap_start.is_none() {
                        b_gap_start = Some(b_e[bi].0);
                    }
                    b_gap_end = Some(b_e[bi].0 + 1);
                }
                base_end_idx += 1;
            }

            let base_end_pos = if base_end_idx < n {
                base_e[base_end_idx].0
            } else {
                base_e[base_end_idx - 1].0 + 1
            };

            let a_changed = a_match.is_none();
            let b_changed = b_match.is_none();

            if a_changed && b_changed {
                let (a_s, a_e_pos) =
                    unmatched_range_near(&a_matched, a_e, base_to_a, i, base_end_idx);
                let (b_s, b_e_pos) =
                    unmatched_range_near(&b_matched, b_e, base_to_b, i, base_end_idx);

                segments.push(Segment::Conflict {
                    base_start,
                    base_end: base_end_pos,
                    a_start: a_s,
                    a_end: a_e_pos,
                    b_start: b_s,
                    b_end: b_e_pos,
                });
            } else if a_changed {
                let (a_s, a_e_pos) =
                    unmatched_range_near(&a_matched, a_e, base_to_a, i, base_end_idx);
                segments.push(Segment::OnlyA {
                    base_start,
                    base_end: base_end_pos,
                    a_start: a_s,
                    a_end: a_e_pos,
                });
            } else {
                let (b_s, b_e_pos) =
                    unmatched_range_near(&b_matched, b_e, base_to_b, i, base_end_idx);
                segments.push(Segment::OnlyB {
                    base_start,
                    base_end: base_end_pos,
                    b_start: b_s,
                    b_end: b_e_pos,
                });
            }

            i = base_end_idx;
        }
    }

    mark_claimed_indices(&segments, a_e, b_e, &mut a_matched, &mut b_matched);

    handle_trailing_a(&a_matched, a_e, base_e, &mut segments);
    handle_trailing_b(&b_matched, b_e, base_e, &mut segments);

    segments
}

fn unmatched_range_near(
    matched: &std::collections::HashSet<usize>,
    entries: &[(i64, Arc<Carrier>)],
    base_to_edition: &[Option<usize>],
    base_start_idx: usize,
    base_end_idx: usize,
) -> (i64, i64) {
    let a_before = if base_start_idx > 0 {
        (0..base_start_idx).rev().find_map(|k| {
            base_to_edition
                .get(k)
                .and_then(|opt| opt.map(|ai| entries[ai].0))
        })
    } else {
        None
    };
    let a_after = (base_end_idx..base_to_edition.len()).find_map(|k| {
        base_to_edition
            .get(k)
            .and_then(|opt| opt.map(|ai| entries[ai].0))
    });

    let lo = a_before.map_or(0i64, |p| p);
    let hi = a_after.map_or(i64::MAX, |p| p);

    let mut span_start = None;
    let mut span_end = None;
    for (idx, (pos, _)) in entries.iter().enumerate() {
        if matched.contains(&idx) {
            continue;
        }
        if *pos > lo && *pos < hi {
            if span_start.is_none() {
                span_start = Some(*pos);
            }
            span_end = Some(*pos + 1);
        }
    }

    match (span_start, span_end) {
        (Some(s), Some(e)) => (s, e),
        _ => {
            let default = a_before.map_or(0, |p| p + 1);
            (default, default)
        }
    }
}

fn handle_trailing_a(
    a_matched: &std::collections::HashSet<usize>,
    a_e: &[(i64, Arc<Carrier>)],
    _base_e: &[(i64, Arc<Carrier>)],
    segments: &mut Vec<Segment>,
) {
    let mut i = 0;
    while i < a_e.len() {
        if a_matched.contains(&i) {
            i += 1;
            continue;
        }
        let start = i;
        while i < a_e.len() && !a_matched.contains(&i) {
            i += 1;
        }
        let after_base = if start > 0 {
            // Anchor to the nearest preceding entry found in an
            // Unchanged run. The immediate predecessor may be missing
            // from Unchanged (matched in only one side); the historical
            // fallback of 0 misplaced such inserts (visible with
            // non-dense position layouts).
            let mut found = None;
            for k in (0..start).rev() {
                if let Some(pos) = find_base_pos_for_a(segments, a_e[k].0) {
                    found = Some(pos + 1);
                    break;
                }
            }
            found.unwrap_or(0)
        } else {
            -1
        };
        segments.push(Segment::InsertA {
            after_base_pos: after_base,
            a_start: a_e[start].0,
            a_end: a_e[i - 1].0 + 1,
        });
    }
}

fn handle_trailing_b(
    b_matched: &std::collections::HashSet<usize>,
    b_e: &[(i64, Arc<Carrier>)],
    _base_e: &[(i64, Arc<Carrier>)],
    segments: &mut Vec<Segment>,
) {
    let mut i = 0;
    while i < b_e.len() {
        if b_matched.contains(&i) {
            i += 1;
            continue;
        }
        let start = i;
        while i < b_e.len() && !b_matched.contains(&i) {
            i += 1;
        }
        let after_base = if start > 0 {
            let mut found = None;
            for k in (0..start).rev() {
                if let Some(pos) = find_base_pos_for_b(segments, b_e[k].0) {
                    found = Some(pos + 1);
                    break;
                }
            }
            found.unwrap_or(0)
        } else {
            -1
        };
        segments.push(Segment::InsertB {
            after_base_pos: after_base,
            b_start: b_e[start].0,
            b_end: b_e[i - 1].0 + 1,
        });
    }
}

fn find_base_pos_for_a(segments: &[Segment], a_pos: i64) -> Option<i64> {
    for seg in segments {
        if let Segment::Unchanged {
            a_positions,
            base_positions,
            ..
        } = seg
        {
            if let Some(idx) = a_positions.iter().position(|&p| p == a_pos) {
                return Some(base_positions[idx]);
            }
        }
    }
    None
}

fn find_base_pos_for_b(segments: &[Segment], b_pos: i64) -> Option<i64> {
    for seg in segments {
        if let Segment::Unchanged {
            b_positions,
            base_positions,
            ..
        } = seg
        {
            if let Some(idx) = b_positions.iter().position(|&p| p == b_pos) {
                return Some(base_positions[idx]);
            }
        }
    }
    None
}

pub fn three_way_merge(
    base: &Edition,
    a: &Edition,
    b: &Edition,
    strategy: MergeStrategy,
) -> Result<MergeResult, Vec<MergeConflict>> {
    let diff = three_way_diff(base, a, b);

    if diff.only_a.is_empty()
        && diff.only_b.is_empty()
        && diff.conflict.is_empty()
        && diff.unchanged.is_empty()
    {
        let n = base.count() as i64;
        let id_mapping = if n > 0 {
            Mapping::Simple {
                offset: 0,
                region: XnRegion::interval(0, n),
            }
        } else {
            Mapping::identity()
        };
        return Ok(MergeResult {
            merged: base.clone(),
            a_to_merged: id_mapping.clone(),
            b_to_merged: id_mapping,
        });
    }

    if diff.only_a.is_empty() && diff.conflict.is_empty() && !diff.only_b.is_empty() {
        let merged = b.clone();
        let b_to_merged = build_merge_mapping(b, &merged);
        let a_to_merged = build_merge_mapping(a, &merged);
        let migrated_sp = migrate_span_provenance(
            &a.span_provenance,
            &b.span_provenance,
            &a_to_merged,
            &b_to_merged,
        );
        let merged = merged.with_span_provenance(migrated_sp);
        return Ok(MergeResult {
            merged,
            a_to_merged,
            b_to_merged,
        });
    }

    if diff.only_b.is_empty() && diff.conflict.is_empty() && !diff.only_a.is_empty() {
        let merged = a.clone();
        let a_to_merged = build_merge_mapping(a, &merged);
        let b_to_merged = build_merge_mapping(b, &merged);
        let migrated_sp = migrate_span_provenance(
            &a.span_provenance,
            &b.span_provenance,
            &a_to_merged,
            &b_to_merged,
        );
        let merged = merged.with_span_provenance(migrated_sp);
        return Ok(MergeResult {
            merged,
            a_to_merged,
            b_to_merged,
        });
    }

    match strategy {
        MergeStrategy::LastWriterWins => {
            let (merged, a_map, b_map) = assemble_merge_lww(base, a, b, &diff);
            let migrated_sp =
                migrate_span_provenance(&a.span_provenance, &b.span_provenance, &a_map, &b_map);
            let merged = merged.with_span_provenance(migrated_sp);
            Ok(MergeResult {
                merged,
                a_to_merged: a_map,
                b_to_merged: b_map,
            })
        }
    }
}

fn assemble_merge_lww(
    base: &Edition,
    a: &Edition,
    b: &Edition,
    diff: &ThreeWayDiff,
) -> (Edition, Mapping, Mapping) {
    type PosPair = (i64, i64);

    enum AssemblyPiece {
        Unchanged {
            a_positions: Vec<i64>,
            b_positions: Vec<i64>,
            sort_key: i64,
        },
        OnlyA {
            sort_key: i64,
            a_span: (i64, i64),
        },
        OnlyB {
            sort_key: i64,
            b_span: (i64, i64),
        },
        Conflict {
            sort_key: i64,
            a_span: (i64, i64),
            b_span: (i64, i64),
        },
    }

    let mut pieces: Vec<AssemblyPiece> = Vec::new();

    for run in &diff.unchanged {
        pieces.push(AssemblyPiece::Unchanged {
            sort_key: run.base_positions.first().copied().unwrap_or(0),
            a_positions: run.a_positions.clone(),
            b_positions: run.b_positions.clone(),
        });
    }

    for reg in &diff.only_a {
        pieces.push(AssemblyPiece::OnlyA {
            sort_key: reg.base_start,
            a_span: (reg.edition_start, reg.edition_end),
        });
    }

    for reg in &diff.only_b {
        pieces.push(AssemblyPiece::OnlyB {
            sort_key: reg.base_start,
            b_span: (reg.edition_start, reg.edition_end),
        });
    }

    for cr in &diff.conflict {
        pieces.push(AssemblyPiece::Conflict {
            sort_key: cr.base_start,
            a_span: (cr.a_start, cr.a_end),
            b_span: (cr.b_start, cr.b_end),
        });
    }

    pieces.sort_by(|a, b| {
        let ka = match a {
            AssemblyPiece::Unchanged { sort_key, .. } => (*sort_key, 0),
            AssemblyPiece::OnlyA { sort_key, .. } => (*sort_key, 1),
            AssemblyPiece::OnlyB { sort_key, .. } => (*sort_key, 2),
            AssemblyPiece::Conflict { sort_key, .. } => (*sort_key, 3),
        };
        let kb = match b {
            AssemblyPiece::Unchanged { sort_key, .. } => (*sort_key, 0),
            AssemblyPiece::OnlyA { sort_key, .. } => (*sort_key, 1),
            AssemblyPiece::OnlyB { sort_key, .. } => (*sort_key, 2),
            AssemblyPiece::Conflict { sort_key, .. } => (*sort_key, 3),
        };
        ka.cmp(&kb)
    });

    let mut merged_entries: Vec<(i64, Arc<Carrier>)> = Vec::new();
    let mut next_pos: i64 = 0;
    let mut a_sub: Vec<Mapping> = Vec::new();
    let mut b_sub: Vec<Mapping> = Vec::new();

    for piece in &pieces {
        match piece {
            AssemblyPiece::Unchanged {
                a_positions,
                b_positions,
                ..
            } => {
                let a_entries = a.cached_entries();
                let b_entries = b.cached_entries();
                // Fast path: lockstep cursor walk when the run is
                // position-sorted (the overwhelmingly common case) —
                // O(run + skipped) instead of O(run log n).
                // Rotation-style seed alignments produce non-monotone
                // runs; those fall back to per-entry binary search,
                // which handles any order.
                let a_sorted = a_positions.windows(2).all(|w| w[0] < w[1]);
                let b_sorted = b_positions.windows(2).all(|w| w[0] < w[1]);
                let mut ai = if a_sorted {
                    a_entries.partition_point(|(p, _)| *p < a_positions[0])
                } else {
                    usize::MAX
                };
                let mut bi = if b_sorted {
                    b_entries.partition_point(|(p, _)| *p < b_positions[0])
                } else {
                    usize::MAX
                };
                for (a_pos, b_pos) in a_positions.iter().zip(b_positions.iter()) {
                    let a_carrier = if a_sorted {
                        while ai < a_entries.len() && a_entries[ai].0 < *a_pos {
                            ai += 1;
                        }
                        let c = a_entries
                            .get(ai)
                            .filter(|(p, _)| p == a_pos)
                            .map(|(_, c)| c.clone());
                        if a_entries.get(ai).map(|(p, _)| p) == Some(a_pos) {
                            ai += 1;
                        }
                        c
                    } else {
                        a_entries
                            .binary_search_by_key(a_pos, |(p, _)| *p)
                            .ok()
                            .map(|idx| a_entries[idx].1.clone())
                    };
                    let b_carrier = if b_sorted {
                        while bi < b_entries.len() && b_entries[bi].0 < *b_pos {
                            bi += 1;
                        }
                        let c = b_entries
                            .get(bi)
                            .filter(|(p, _)| p == b_pos)
                            .map(|(_, c)| c.clone());
                        if b_entries.get(bi).map(|(p, _)| p) == Some(b_pos) {
                            bi += 1;
                        }
                        c
                    } else {
                        b_entries
                            .binary_search_by_key(b_pos, |(p, _)| *p)
                            .ok()
                            .map(|idx| b_entries[idx].1.clone())
                    };
                    let carrier = match (a_carrier.as_ref(), b_carrier.as_ref()) {
                        // Prefer the carrier that has provenance — preserves correct attribution
                        (Some(a), Some(b)) => {
                            if b.provenance.is_some() && a.provenance.is_none() {
                                b.clone()
                            } else {
                                a.clone()
                            }
                        }
                        (Some(a), None) => a.clone(),
                        (None, Some(b)) => b.clone(),
                        (None, None) => {
                            let mut c = Carrier::new(RangeElement::text(""));
                            if let Some(prev) = merged_entries
                                .last()
                                .and_then(|(_, c)| c.provenance.clone())
                            {
                                c = c.with_provenance(prev);
                            }
                            Arc::new(c)
                        }
                    };
                    let m_pos = next_pos;
                    merged_entries.push((m_pos, carrier));
                    next_pos += 1;
                    a_sub.push(Mapping::restricted(
                        m_pos - a_pos,
                        XnRegion::singleton(*a_pos),
                    ));
                    b_sub.push(Mapping::restricted(
                        m_pos - b_pos,
                        XnRegion::singleton(*b_pos),
                    ));
                }
            }
            AssemblyPiece::OnlyA { a_span, .. } => {
                let source = collect_range(a.cached_entries(), a_span.0, a_span.1);
                for (src_pos, carrier) in &source {
                    let m_pos = next_pos;
                    merged_entries.push((m_pos, carrier.clone()));
                    next_pos += 1;
                    a_sub.push(Mapping::restricted(
                        m_pos - src_pos,
                        XnRegion::singleton(*src_pos),
                    ));
                }
            }
            AssemblyPiece::OnlyB { b_span, .. } => {
                let source = collect_range(b.cached_entries(), b_span.0, b_span.1);
                for (src_pos, carrier) in &source {
                    let m_pos = next_pos;
                    merged_entries.push((m_pos, carrier.clone()));
                    next_pos += 1;
                    b_sub.push(Mapping::restricted(
                        m_pos - src_pos,
                        XnRegion::singleton(*src_pos),
                    ));
                }
            }
            AssemblyPiece::Conflict { a_span, b_span, .. } => {
                let a_entries = collect_range(a.cached_entries(), a_span.0, a_span.1);
                let b_entries = collect_range(b.cached_entries(), b_span.0, b_span.1);
                // Both sides of a conflict survive: emit the side with
                // more provenance first (attribution preference), then
                // the other. Pick-one silently dropped concurrent edits
                // whenever alignment granularity improved (Stage 5 made
                // this visible: per-entry conflicts instead of the
                // degenerate whole-document OnlyA/OnlyB concatenation).
                let a_prov_count = a_entries
                    .iter()
                    .filter(|(_, c)| c.provenance.is_some())
                    .count();
                let b_prov_count = b_entries
                    .iter()
                    .filter(|(_, c)| c.provenance.is_some())
                    .count();
                let (first, second) = if a_prov_count >= b_prov_count {
                    (a_entries.clone(), b_entries.clone())
                } else {
                    (b_entries.clone(), a_entries.clone())
                };

                let identical = a_entries.len() == b_entries.len()
                    && a_entries.iter().zip(b_entries.iter()).all(|(x, y)| {
                        x.1.element.content_fingerprint() == y.1.element.content_fingerprint()
                    });

                if identical {
                    // Both sides made the same change: emit once, map
                    // both sides to the same merged positions.
                    let (first_from_a, ref_iter): (bool, _) = if a_prov_count >= b_prov_count {
                        (true, &a_entries)
                    } else {
                        (false, &b_entries)
                    };
                    let other = if first_from_a { &b_entries } else { &a_entries };
                    for ((src_pos, carrier), (other_pos, _)) in ref_iter.iter().zip(other.iter()) {
                        let m_pos = next_pos;
                        merged_entries.push((m_pos, carrier.clone()));
                        next_pos += 1;
                        if first_from_a {
                            a_sub.push(Mapping::restricted(
                                m_pos - src_pos,
                                XnRegion::singleton(*src_pos),
                            ));
                            b_sub.push(Mapping::restricted(
                                m_pos - other_pos,
                                XnRegion::singleton(*other_pos),
                            ));
                        } else {
                            b_sub.push(Mapping::restricted(
                                m_pos - src_pos,
                                XnRegion::singleton(*src_pos),
                            ));
                            a_sub.push(Mapping::restricted(
                                m_pos - other_pos,
                                XnRegion::singleton(*other_pos),
                            ));
                        }
                    }
                } else {
                    for (is_first_side, entries) in [(true, &first), (false, &second)] {
                        let from_a = if a_prov_count >= b_prov_count {
                            is_first_side
                        } else {
                            !is_first_side
                        };
                        for (src_pos, carrier) in entries {
                            let m_pos = next_pos;
                            merged_entries.push((m_pos, carrier.clone()));
                            next_pos += 1;
                            if from_a {
                                a_sub.push(Mapping::restricted(
                                    m_pos - src_pos,
                                    XnRegion::singleton(*src_pos),
                                ));
                            } else {
                                b_sub.push(Mapping::restricted(
                                    m_pos - src_pos,
                                    XnRegion::singleton(*src_pos),
                                ));
                            }
                        }
                    }
                }
            }
        }
    }

    let a_to_merged = Mapping::from_parts(a_sub);
    let b_to_merged = Mapping::from_parts(b_sub);

    if merged_entries.is_empty() {
        return (Edition::empty(), a_to_merged, b_to_merged);
    }

    let region = XnRegion::interval(0, next_pos);
    let merged = Edition {
        orgl: super::orgl::OrglRoot::from_bulk_entries(merged_entries, None, region),
        endorsements: base.endorsements().clone(),
        entries_cache: Arc::new(std::sync::OnceLock::new()),
        span_provenance: Vec::new(),
    };

    (merged, a_to_merged, b_to_merged)
}

fn collect_range(
    entries: &[(i64, Arc<Carrier>)],
    start: i64,
    end: i64,
) -> Vec<(i64, Arc<Carrier>)> {
    // Bounded slice: binary-search the start, take while inside the
    // span (entries are position-sorted).
    let from = entries.partition_point(|(p, _)| *p < start);
    let mut to = from;
    while to < entries.len() && entries[to].0 < end {
        to += 1;
    }
    entries[from..to].to_vec()
}

pub fn build_merge_mapping(source: &Edition, merged: &Edition) -> Mapping {
    let started = std::time::Instant::now();
    let source_entries = source.cached_entries();
    let merged_entries = merged.cached_entries();

    let mut source_by_fp: std::collections::HashMap<[u8; 8], Vec<i64>> =
        std::collections::HashMap::new();
    for (pos, carrier) in source_entries {
        let fp_val = carrier.element.content_fingerprint();
        let mut key = [0u8; 8];
        key.copy_from_slice(&fp_val[..8]);
        source_by_fp.entry(key).or_default().push(*pos);
    }

    // Positions are matched greedily in list order: the k-th merged entry
    // with a given fingerprint consumes the k-th source position with that
    // fingerprint. A per-key cursor reproduces the historical
    // first-unused-position scan without the O(n^2) rescan over duplicate
    // fingerprints (PERF-PLAN Stage 6).
    let mut sub_mappings = Vec::new();
    let mut cursors: std::collections::HashMap<[u8; 8], usize> = std::collections::HashMap::new();

    for (merged_pos, carrier) in merged_entries {
        let fp_val = carrier.element.content_fingerprint();
        let mut key = [0u8; 8];
        key.copy_from_slice(&fp_val[..8]);
        if let Some(source_positions) = source_by_fp.get(&key) {
            let cursor = cursors.entry(key).or_insert(0);
            if *cursor < source_positions.len() {
                let src_pos = source_positions[*cursor];
                *cursor += 1;
                sub_mappings.push(Mapping::restricted(
                    merged_pos - src_pos,
                    XnRegion::singleton(src_pos),
                ));
            }
        }
    }

    let mapping = Mapping::from_parts(sub_mappings);

    let elapsed = started.elapsed();
    if elapsed.as_millis() >= 1 {
        #[cfg(feature = "server")]
        {
            tracing::debug!(
                "[merge_mapping] {} source entries -> mapping in {:.2}ms",
                source_entries.len(),
                elapsed.as_secs_f64() * 1000.0,
            );
        }
    }

    mapping
}

fn group_consecutive(positions: &[i64]) -> Vec<(i64, i64)> {
    if positions.is_empty() {
        return Vec::new();
    }
    let mut groups = Vec::new();
    let mut start = positions[0];
    let mut end = positions[0] + 1;
    for &pos in &positions[1..] {
        if pos == end {
            end = pos + 1;
        } else {
            groups.push((start, end));
            start = pos;
            end = pos + 1;
        }
    }
    groups.push((start, end));
    groups
}

/// Split semantics: an edit inside a span divides the author's text
/// into surviving fragments. Each fragment keeps the author's
/// identity and original signature (which attests the pre-split
/// content recorded in the append-only attribution log); the fragment
/// covers ONLY its surviving characters — the editor's inserted text
/// is not attributed to the original author.
fn try_migrate_span_multi(span: &SpanProvenance, mapping: &Mapping) -> Vec<SpanProvenance> {
    let region = XnRegion::interval(span.start, span.end);
    let mapped = mapping.of_region(&region);
    let intervals = mapped.simple_regions();

    if intervals.len() == 1 {
        let (new_start, new_end) = intervals[0];
        vec![SpanProvenance {
            start: new_start,
            end: new_end,
            provenance: span.provenance.clone(),
        }]
    } else if intervals.len() > 1 {
        // Split: one fragment per mapped interval of the AUTHOR'S OWN
        // text. Gaps between intervals are the editor's insertions —
        // they get no fragment here.
        intervals
            .into_iter()
            .map(|(s, e)| SpanProvenance {
                start: s,
                end: e.max(s + 1),
                provenance: span.provenance.clone(),
            })
            .collect()
    } else {
        // The H1 incident shape: build_merge_mapping matches entries
        // by content fingerprint, so an edit INSIDE a span's entry
        // (prefixing "# " to a coalesced author region) leaves the
        // whole region unmapped. Entry-granular fallback: the span
        // keeps covering its surviving text via the neighbourhood
        // envelope (positions just before/after map reliably — their
        // entries were untouched).
        let lo_env = mapping.of_region(&XnRegion::interval(span.start - 1, span.start));
        let hi_env = mapping.of_region(&XnRegion::interval(span.end, span.end + 1));
        let lo = lo_env.simple_regions();
        let hi = hi_env.simple_regions();
        if let (Some((lo_s, _)), Some((_, hi_e))) = (lo.first(), hi.last()) {
            let new_start = *lo_s;
            let new_end = (*hi_e).max(new_start + 1);
            if new_end > new_start {
                return vec![SpanProvenance {
                    start: new_start,
                    end: new_end,
                    provenance: span.provenance.clone(),
                }];
            }
        }
        // Degenerate: span at the document edge with no mapped
        // neighbours — anchor to the closest mapped positions.
        let all = mapping
            .of_region(&XnRegion::interval(i64::MIN / 2, i64::MAX / 2))
            .simple_regions();
        if let (Some(first), Some(last)) = (all.first(), all.last()) {
            let new_start = if span.start == 0 { first.0 } else { last.0 };
            let new_end = last.1.max(new_start + 1);
            return vec![SpanProvenance {
                start: new_start,
                end: new_end,
                provenance: span.provenance.clone(),
            }];
        }
        Vec::new()
    }
}

pub fn migrate_span_provenance_single(
    spans: &[SpanProvenance],
    mapping: &Mapping,
) -> Vec<SpanProvenance> {
    spans
        .iter()
        .flat_map(|span| try_migrate_span_multi(span, mapping))
        .collect()
}

fn migrate_span_provenance(
    a_spans: &[SpanProvenance],
    b_spans: &[SpanProvenance],
    a_to_merged: &Mapping,
    b_to_merged: &Mapping,
) -> Vec<SpanProvenance> {
    let mut result = Vec::new();

    for span in a_spans {
        result.extend(try_migrate_span_multi(span, a_to_merged));
    }
    for span in b_spans {
        for migrated in try_migrate_span_multi(span, b_to_merged) {
            let is_dup = result.iter().any(|existing| {
                existing.start == migrated.start
                    && existing.end == migrated.end
                    && existing.provenance.author_public_key
                        == migrated.provenance.author_public_key
            });
            if !is_dup {
                result.push(migrated);
            }
        }
    }

    result
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::provenance::{AuthorType, ElementProvenance};
    use crate::edition::{Provenance, RangeElement};
    use proptest::prelude::*;

    fn text_edition(s: &str) -> Edition {
        Edition::from_text(s)
    }

    /// Regression: the H1 incident. A coalesced multi-author edition
    /// (one big entry per author region) whose span-containing entry
    /// is edited (prefix insert of "# ") must NOT lose that author's
    /// span. build_merge_mapping matches entries by fingerprint; the
    /// edited entry's fingerprint changes, the region maps to nothing,
    /// and try_migrate_span dropped the span wholesale.
    #[test]
    fn span_survives_edit_inside_author_region() {
        use ed25519_dalek::SigningKey;
        let author_a = SigningKey::generate(&mut rand::rngs::OsRng);
        let author_b = SigningKey::generate(&mut rand::rngs::OsRng);
        let text_a = "AAAA".repeat(30);
        let text_b = "BBBB".repeat(30);

        let mk_prov = |key: &SigningKey, name: &str| ElementProvenance {
            author_public_key: key.verifying_key().to_bytes(),
            author_display_name: name.to_string(),
            author_club_id: 1,
            timestamp: 1000,
            author_type: AuthorType::Human,
            llm_model: None,
            historical_author_id: None,
            source_work_id: None,
            transcluded_by: None,
            derived_by: None,
        };

        // Build the two-entry coalesced edition the seeder produces.
        let mut carrier_a =
            crate::edition::range_element::Carrier::new(RangeElement::text(text_a.clone()));
        carrier_a.provenance = Some(mk_prov(&author_a, "Author A"));
        let mut carrier_b =
            crate::edition::range_element::Carrier::new(RangeElement::text(text_b.clone()));
        carrier_b.provenance = Some(mk_prov(&author_b, "Author B"));
        let base = Edition::from_entries(vec![(0, Arc::new(carrier_a)), (1, Arc::new(carrier_b))]);

        // Span provenance over the two entries (positions 0..1, 1..2).
        let spans = vec![
            SpanProvenance {
                start: 0,
                end: 1,
                provenance: crate::edition::provenance::sign_span(
                    &author_a,
                    &[RangeElement::text(text_a.clone()).content_fingerprint()],
                    1000,
                    &[0u8; 32],
                ),
            },
            SpanProvenance {
                start: 1,
                end: 2,
                provenance: crate::edition::provenance::sign_span(
                    &author_b,
                    &[RangeElement::text(text_b.clone()).content_fingerprint()],
                    1000,
                    &[0u8; 32],
                ),
            },
        ];
        let base = base.with_span_provenance(spans);

        // Simulate the user edit: insert "# " at the start of Author
        // A's text. Rebuild the edition the way the edit path would
        // (Author A's entry changes, Author B's is untouched).
        let mut edited_a = crate::edition::range_element::Carrier::new(RangeElement::text(
            format!("# {}", text_a),
        ));
        edited_a.provenance = Some(mk_prov(&author_a, "Author A"));
        let edited = Edition::from_entries(vec![
            (0, Arc::new(edited_a)),
            (1, base.cached_entries()[1].1.clone()),
        ]);

        let mapping = build_merge_mapping(&base, &edited);
        let migrated = migrate_span_provenance_single(base.span_provenance(), &mapping);

        assert_eq!(
            migrated.len(),
            2,
            "both author spans must survive an edit inside one region — the H1 regression"
        );
    }

    #[test]
    fn three_way_diff_all_same() {
        let base = text_edition("hello world");
        let a = text_edition("hello world");
        let b = text_edition("hello world");

        let diff = three_way_diff(&base, &a, &b);

        assert!(diff.only_a.is_empty());
        assert!(diff.only_b.is_empty());
        assert!(diff.conflict.is_empty());
        assert_eq!(diff.unchanged.len(), 1);
    }

    #[test]
    fn three_way_diff_only_a_changes() {
        let base = text_edition("hello world");
        let a = text_edition("hello earth");
        let b = text_edition("hello world");

        let diff = three_way_diff(&base, &a, &b);

        assert!(
            diff.only_b.is_empty(),
            "only_b should be empty: {:?}",
            diff.only_b
        );
        assert!(
            diff.conflict.is_empty(),
            "no conflicts expected: {:?}",
            diff.conflict
        );
        assert!(!diff.unchanged.is_empty() || !diff.only_a.is_empty());
    }

    #[test]
    fn three_way_diff_only_b_changes() {
        let base = text_edition("hello world");
        let a = text_edition("hello world");
        let b = text_edition("hello earth");

        let diff = three_way_diff(&base, &a, &b);

        assert!(
            diff.only_a.is_empty(),
            "only_a should be empty: {:?}",
            diff.only_a
        );
        assert!(
            diff.conflict.is_empty(),
            "no conflicts expected: {:?}",
            diff.conflict
        );
        assert!(!diff.unchanged.is_empty() || !diff.only_b.is_empty());
    }

    #[test]
    fn three_way_diff_both_different_parts() {
        let base = text_edition("hello world");
        let a = text_edition("jello world");
        let b = text_edition("hello earth");

        let diff = three_way_diff(&base, &a, &b);

        assert!(
            diff.conflict.is_empty(),
            "non-overlapping changes should not conflict"
        );
        assert!(!diff.only_a.is_empty());
        assert!(!diff.only_b.is_empty());
    }

    #[test]
    fn three_way_merge_no_changes() {
        let base = text_edition("hello");
        let a = text_edition("hello");
        let b = text_edition("hello");

        let result = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins);
        let merged = result.expect("no conflicts expected");
        assert_eq!(merged.merged.to_text(), "hello");
    }

    #[test]
    fn three_way_merge_a_edits_start() {
        let base = text_edition("hello world");
        let a = text_edition("HELLO world");
        let b = text_edition("hello world");

        let result = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins);
        let mr = result.expect("no conflicts expected");
        let text = mr.merged.to_text();
        assert!(
            text.contains("world"),
            "world should survive: got {:?}",
            text
        );
    }

    #[test]
    fn three_way_merge_b_edits_end() {
        let base = text_edition("hello world");
        let a = text_edition("hello world");
        let b = text_edition("hello WORLD");

        let result = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins);
        let mr = result.expect("no conflicts expected");
        let text = mr.merged.to_text();
        assert!(
            text.contains("hello"),
            "hello should survive: got {:?}",
            text
        );
    }

    #[test]
    fn three_way_merge_concurrent_non_overlapping() {
        let base = text_edition("abcdef");
        let a = text_edition("ABcdef");
        let b = text_edition("abCDEF");

        let result = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins);
        let mr = result.expect("no conflicts expected");
        let text = mr.merged.to_text();
        assert!(
            text.contains("AB")
                || text.contains("cd")
                || text.contains("CD")
                || text.contains("EF"),
            "should have elements from both branches: got {:?}",
            text
        );
    }

    #[test]
    fn three_way_merge_empty_base() {
        let base = Edition::empty();
        let a = text_edition("hello");
        let b = Edition::empty();

        let result = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins);
        let mr = result.expect("no conflicts expected");
        assert_eq!(mr.merged.to_text(), "hello");
    }

    #[test]
    fn three_way_merge_both_empty() {
        let base = text_edition("hello");
        let a = Edition::empty();
        let b = Edition::empty();

        let result = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins);
        let mr = result.expect("no conflicts expected");
        assert_eq!(mr.merged.to_text(), "");
    }

    #[test]
    fn three_way_merge_preserves_non_text() {
        let mut base = Edition::from_text("ab");
        base = base.with(2, RangeElement::data(vec![1, 2, 3]));
        base = base.with(3, RangeElement::text("cd"));

        let mut a = base.clone();
        a = a.with(0, RangeElement::text("X"));

        let b = base.clone();

        let result = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins);
        let mr = result.expect("no conflicts expected");

        let has_data = mr
            .merged
            .all_entries()
            .iter()
            .any(|(_, c)| matches!(c.element, RangeElement::Data { .. }));
        assert!(has_data, "data element should survive merge");
    }

    #[test]
    fn three_way_merge_preserves_edition_ref() {
        let mut base = Edition::from_text("ab");
        base = base.with(2, RangeElement::edition(999));

        let mut a = base.clone();
        a = a.with(0, RangeElement::text("X"));

        let b = base.clone();

        let result = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins);
        let mr = result.expect("no conflicts expected");

        let has_edition_ref = mr
            .merged
            .all_entries()
            .iter()
            .any(|(_, c)| matches!(c.element, RangeElement::Edition { .. }));
        assert!(has_edition_ref, "edition reference should survive merge");
    }

    #[test]
    fn three_way_merge_insertion_by_a() {
        let base = text_edition("ac");
        let a = text_edition("abc");
        let b = text_edition("ac");

        let result = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins);
        let mr = result.expect("no conflicts expected");
        let text = mr.merged.to_text();
        assert!(
            text.contains("b"),
            "insertion from a should appear: got {:?}",
            text
        );
    }

    #[test]
    fn three_way_merge_deletion_by_a() {
        let base = text_edition("abc");
        let a = text_edition("ac");
        let b = text_edition("abc");

        let result = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins);
        let mr = result.expect("no conflicts expected");
        let text = mr.merged.to_text();
        assert!(
            !text.contains("b") || text == "ac" || text == "abc",
            "deletion from a should be reflected or overwritten by b: got {:?}",
            text
        );
    }

    #[test]
    fn group_consecutive_empty() {
        let groups = group_consecutive(&[]);
        assert!(groups.is_empty());
    }

    #[test]
    fn group_consecutive_single() {
        let groups = group_consecutive(&[5]);
        assert_eq!(groups, vec![(5, 6)]);
    }

    #[test]
    fn group_consecutive_run() {
        let groups = group_consecutive(&[1, 2, 3]);
        assert_eq!(groups, vec![(1, 4)]);
    }

    #[test]
    fn group_consecutive_gap() {
        let groups = group_consecutive(&[1, 2, 5, 6]);
        assert_eq!(groups, vec![(1, 3), (5, 7)]);
    }

    /// Stage 6: cursor-based matching must reproduce the historical
    /// first-unused-position scan exactly, including duplicate-heavy text.
    #[test]
    fn build_merge_mapping_cursor_equivalence() {
        // Reference: the original O(n^2) rescan implementation.
        fn reference(source: &Edition, merged: &Edition) -> Vec<(i64, i64)> {
            let source_entries = source.cached_entries();
            let mut source_by_fp: std::collections::HashMap<[u8; 8], Vec<i64>> =
                std::collections::HashMap::new();
            for (pos, carrier) in source_entries {
                let fp_val = carrier.element.content_fingerprint();
                let mut key = [0u8; 8];
                key.copy_from_slice(&fp_val[..8]);
                source_by_fp.entry(key).or_default().push(*pos);
            }
            let mut used = std::collections::HashSet::new();
            let mut pairs = Vec::new();
            for (merged_pos, carrier) in merged.cached_entries() {
                let fp_val = carrier.element.content_fingerprint();
                let mut key = [0u8; 8];
                key.copy_from_slice(&fp_val[..8]);
                if let Some(positions) = source_by_fp.get(&key) {
                    for &src_pos in positions {
                        if used.insert(src_pos) {
                            pairs.push((*merged_pos, src_pos));
                            break;
                        }
                    }
                }
            }
            pairs
        }

        fn actual_pairs(source: &Edition, merged: &Edition) -> Vec<(i64, i64)> {
            let mapping = build_merge_mapping(source, merged);
            let mut pairs = Vec::new();
            for (pos, _) in source.cached_entries() {
                if let Some(new_pos) = mapping.of(*pos) {
                    pairs.push((new_pos, *pos));
                }
            }
            pairs.sort();
            pairs
        }

        let cases = [
            ("aaaa", "aa"),
            ("ab", "ba"),
            ("aabbcc", "abcabc"),
            ("hello world", "hello brave world"),
            ("xyz", ""),
            ("", "xyz"),
            ("mississippi", "mississippi"),
        ];
        for (src, mrg) in cases {
            let source = text_edition(src);
            let merged = text_edition(mrg);
            let mut expected = reference(&source, &merged);
            expected.sort();
            assert_eq!(
                actual_pairs(&source, &merged),
                expected,
                "cursor matching diverged for {:?} -> {:?}",
                src,
                mrg
            );
        }
    }

    #[test]
    fn build_merge_mapping_basic() {
        let source = text_edition("abc");
        let merged = text_edition("abc");

        let mapping = build_merge_mapping(&source, &merged);
        assert!(!mapping.is_empty());
        assert_eq!(mapping.of(0), Some(0));
        assert_eq!(mapping.of(1), Some(1));
        assert_eq!(mapping.of(2), Some(2));
    }

    #[test]
    fn three_way_diff_empty_everything() {
        let base = Edition::empty();
        let a = Edition::empty();
        let b = Edition::empty();

        let diff = three_way_diff(&base, &a, &b);
        assert!(diff.unchanged.is_empty());
        assert!(diff.only_a.is_empty());
        assert!(diff.only_b.is_empty());
        assert!(diff.conflict.is_empty());
    }

    #[test]
    fn merge_result_mappings_no_changes() {
        let base = text_edition("abc");
        let a = text_edition("abc");
        let b = text_edition("abc");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        assert_eq!(mr.a_to_merged.of(0), Some(0));
        assert_eq!(mr.a_to_merged.of(1), Some(1));
        assert_eq!(mr.a_to_merged.of(2), Some(2));
        assert_eq!(mr.b_to_merged.of(0), Some(0));
        assert_eq!(mr.b_to_merged.of(2), Some(2));
    }

    #[test]
    fn merge_result_mappings_a_inserts() {
        let base = text_edition("ac");
        let a = text_edition("abc");
        let b = text_edition("ac");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        assert_eq!(mr.merged.to_text(), "abc");
        assert_eq!(mr.a_to_merged.of(0), Some(0));
        assert_eq!(mr.a_to_merged.of(1), Some(1));
        assert_eq!(mr.a_to_merged.of(2), Some(2));
        assert_eq!(mr.b_to_merged.of(0), Some(0));
        assert_eq!(mr.b_to_merged.of(1), Some(2));
    }

    #[test]
    fn merge_result_mappings_a_deletes() {
        let base = text_edition("abc");
        let a = text_edition("ac");
        let b = text_edition("abc");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        assert_eq!(mr.merged.to_text(), "ac");
        assert_eq!(mr.a_to_merged.of(0), Some(0));
        assert_eq!(mr.a_to_merged.of(1), Some(1));
    }

    #[test]
    fn merge_result_mappings_both_edit_different_parts() {
        let base = text_edition("abcd");
        let a = text_edition("Abcd");
        let b = text_edition("abCD");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        assert!(!mr.a_to_merged.is_empty());
        assert!(!mr.b_to_merged.is_empty());
        let a_mapped = mr.a_to_merged.of(2);
        let b_mapped = mr.b_to_merged.of(2);
        assert!(a_mapped.is_some() || b_mapped.is_some());
    }

    #[test]
    fn merge_result_inverse_roundtrip_a() {
        let base = text_edition("abcde");
        let a = text_edition("aXcde");
        let b = text_edition("abcYe");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        let a_inv = mr.a_to_merged.inverse();
        for (src_pos, _) in a.cached_entries() {
            if let Some(merged_pos) = mr.a_to_merged.of(*src_pos) {
                assert_eq!(a_inv.of(merged_pos), Some(*src_pos));
            }
        }
    }

    #[test]
    fn merge_result_inverse_roundtrip_b() {
        let base = text_edition("abcde");
        let a = text_edition("aXcde");
        let b = text_edition("abcYe");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        let b_inv = mr.b_to_merged.inverse();
        for (src_pos, _) in b.cached_entries() {
            if let Some(merged_pos) = mr.b_to_merged.of(*src_pos) {
                assert_eq!(b_inv.of(merged_pos), Some(*src_pos));
            }
        }
    }

    #[test]
    fn merge_result_concurrent_inserts_both_sides() {
        let base = text_edition("ac");
        let a = text_edition("aXc");
        let b = text_edition("aYc");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        let text = mr.merged.to_text();
        assert!(text.contains('X'), "merged should contain X from A");
        assert!(text.contains('Y'), "merged should contain Y from B");
        assert!(text.starts_with('a'), "merged should start with 'a'");
        assert!(text.ends_with('c'), "merged should end with 'c'");

        assert!(mr.a_to_merged.of(0).is_some(), "a's 'a' should map");
        assert!(mr.a_to_merged.of(2).is_some(), "a's 'c' should map");
        assert_eq!(
            mr.a_to_merged
                .of(1)
                .map(|p| mr.merged.to_text().chars().nth(p as usize)),
            Some(Some('X'))
        );

        assert!(mr.b_to_merged.of(0).is_some(), "b's 'a' should map");
        assert!(mr.b_to_merged.of(2).is_some(), "b's 'c' should map");
    }

    #[test]
    fn merge_result_insert_at_start() {
        let base = text_edition("bc");
        let a = text_edition("abc");
        let b = text_edition("bc");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        assert_eq!(mr.merged.to_text(), "abc");
        assert_eq!(mr.a_to_merged.of(0), Some(0));
        assert_eq!(mr.a_to_merged.of(1), Some(1));
        assert_eq!(mr.a_to_merged.of(2), Some(2));
        assert_eq!(mr.b_to_merged.of(0), Some(1));
        assert_eq!(mr.b_to_merged.of(1), Some(2));
    }

    #[test]
    fn merge_result_insert_at_end() {
        let base = text_edition("ab");
        let a = text_edition("abc");
        let b = text_edition("ab");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        assert_eq!(mr.merged.to_text(), "abc");
        assert_eq!(mr.a_to_merged.of(0), Some(0));
        assert_eq!(mr.a_to_merged.of(1), Some(1));
        assert_eq!(mr.a_to_merged.of(2), Some(2));
        assert_eq!(mr.b_to_merged.of(0), Some(0));
        assert_eq!(mr.b_to_merged.of(1), Some(1));
    }

    #[test]
    fn merge_result_both_insert_at_end() {
        let base = text_edition("ab");
        let a = text_edition("abX");
        let b = text_edition("abY");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        let text = mr.merged.to_text();
        assert!(text.starts_with("ab"));
        assert!(text.contains('X'));
        assert!(text.contains('Y'));

        assert_eq!(mr.a_to_merged.of(0), Some(0));
        assert_eq!(mr.a_to_merged.of(1), Some(1));
        assert!(mr.a_to_merged.of(2).is_some());

        assert_eq!(mr.b_to_merged.of(0), Some(0));
        assert_eq!(mr.b_to_merged.of(1), Some(1));
        assert!(mr.b_to_merged.of(2).is_some());
    }

    #[test]
    fn merge_result_both_delete_different_parts() {
        let base = text_edition("abcde");
        let a = text_edition("acde");
        let b = text_edition("abce");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        let text = mr.merged.to_text();
        assert!(text.contains('a'), "should contain 'a'");
        assert!(text.contains('e'), "should contain 'e'");
        assert!(!text.contains('b'), "A deleted 'b'");
        assert!(!text.contains('d'), "B deleted 'd'");

        assert_eq!(mr.a_to_merged.of(0), Some(0), "a's 'a' at 0");
        assert_eq!(mr.b_to_merged.of(0), Some(0), "b's 'a' at 0");
    }

    #[test]
    fn merge_result_delete_middle_a() {
        let base = text_edition("abcde");
        let a = text_edition("abde");
        let b = text_edition("abcde");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        assert_eq!(mr.merged.to_text(), "abde");

        assert_eq!(mr.a_to_merged.of(0), Some(0));
        assert_eq!(mr.a_to_merged.of(1), Some(1));
        assert_eq!(mr.a_to_merged.of(2), Some(2));
        assert_eq!(mr.a_to_merged.of(3), Some(3));
        assert_eq!(mr.a_to_merged.of(4), None, "a has no pos 4");

        assert_eq!(mr.b_to_merged.of(0), Some(0));
        assert_eq!(mr.b_to_merged.of(1), Some(1));
        assert!(mr.b_to_merged.of(2).is_none(), "b's 'c' was deleted by A");
        assert_eq!(mr.b_to_merged.of(3), Some(2));
        assert_eq!(mr.b_to_merged.of(4), Some(3));
    }

    #[test]
    fn merge_result_delete_middle_b() {
        let base = text_edition("abcde");
        let a = text_edition("abcde");
        let b = text_edition("abde");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        assert_eq!(mr.merged.to_text(), "abde");

        assert_eq!(mr.a_to_merged.of(0), Some(0));
        assert_eq!(mr.a_to_merged.of(1), Some(1));
        assert!(mr.a_to_merged.of(2).is_none(), "a's 'c' deleted by B");
        assert_eq!(mr.a_to_merged.of(3), Some(2));
        assert_eq!(mr.a_to_merged.of(4), Some(3));

        assert_eq!(mr.b_to_merged.of(0), Some(0));
        assert_eq!(mr.b_to_merged.of(1), Some(1));
        assert_eq!(mr.b_to_merged.of(2), Some(2));
        assert_eq!(mr.b_to_merged.of(3), Some(3));
    }

    #[test]
    fn merge_result_identical_changes() {
        let base = text_edition("abc");
        let a = text_edition("aXc");
        let b = text_edition("aXc");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        assert_eq!(mr.merged.to_text(), "aXc");

        assert_eq!(mr.a_to_merged.of(0), Some(0));
        assert_eq!(mr.a_to_merged.of(1), Some(1));
        assert_eq!(mr.a_to_merged.of(2), Some(2));

        assert_eq!(mr.b_to_merged.of(0), Some(0));
        assert_eq!(mr.b_to_merged.of(1), Some(1));
        assert_eq!(mr.b_to_merged.of(2), Some(2));
    }

    #[test]
    fn merge_result_empty_base_both_insert() {
        let base = text_edition("");
        let a = text_edition("ab");
        let b = text_edition("cd");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        let text = mr.merged.to_text();
        assert!(!text.is_empty(), "merged should not be empty");
        assert!(text.contains('a') || text.contains('c'));

        assert!(mr.a_to_merged.of(0).is_some(), "a's first char should map");
        assert!(mr.b_to_merged.of(0).is_some(), "b's first char should map");
    }

    #[test]
    fn merge_result_a_deletes_b_inserts_same_region() {
        let base = text_edition("abc");
        let a = text_edition("ac");
        let b = text_edition("aXc");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        let text = mr.merged.to_text();
        assert!(text.starts_with('a'));
        assert!(text.ends_with('c'));
    }

    #[test]
    fn merge_result_b_deletes_a_inserts_same_region() {
        let base = text_edition("abc");
        let a = text_edition("aXc");
        let b = text_edition("ac");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        let text = mr.merged.to_text();
        assert!(text.starts_with('a'));
        assert!(text.ends_with('c'));
    }

    #[test]
    fn merge_result_multi_insert_a() {
        let base = text_edition("ace");
        let a = text_edition("abcde");
        let b = text_edition("ace");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        assert_eq!(mr.merged.to_text(), "abcde");

        assert_eq!(mr.a_to_merged.of(0), Some(0));
        assert_eq!(mr.a_to_merged.of(1), Some(1));
        assert_eq!(mr.a_to_merged.of(2), Some(2));
        assert_eq!(mr.a_to_merged.of(3), Some(3));
        assert_eq!(mr.a_to_merged.of(4), Some(4));

        assert_eq!(mr.b_to_merged.of(0), Some(0));
        assert_eq!(mr.b_to_merged.of(1), Some(2));
        assert_eq!(mr.b_to_merged.of(2), Some(4));
    }

    #[test]
    fn merge_result_multi_region_concurrent() {
        let base = text_edition("abcdef");
        let a = text_edition("XbcdYf");
        let b = text_edition("aZcdef");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        let text = mr.merged.to_text();

        assert!(
            text.contains('X') || text.contains('Z'),
            "should have some edit"
        );

        let a_inv = mr.a_to_merged.inverse();
        for (src_pos, _) in a.cached_entries() {
            if let Some(merged_pos) = mr.a_to_merged.of(*src_pos) {
                assert_eq!(
                    a_inv.of(merged_pos),
                    Some(*src_pos),
                    "A inverse roundtrip failed for pos {}",
                    src_pos
                );
            }
        }

        let b_inv = mr.b_to_merged.inverse();
        for (src_pos, _) in b.cached_entries() {
            if let Some(merged_pos) = mr.b_to_merged.of(*src_pos) {
                assert_eq!(
                    b_inv.of(merged_pos),
                    Some(*src_pos),
                    "B inverse roundtrip failed for pos {}",
                    src_pos
                );
            }
        }
    }

    #[test]
    fn merge_result_mapping_composition_roundtrip() {
        let base = text_edition("abcde");
        let a = text_edition("aXcYe");

        let mr = three_way_merge(&base, &a, &a, MergeStrategy::LastWriterWins).unwrap();
        assert_eq!(mr.merged.to_text(), "aXcYe");

        let a_inv = mr.a_to_merged.inverse();
        let a_roundtrip = mr.a_to_merged.combine(&a_inv);
        for (src_pos, _) in a.cached_entries() {
            if mr.a_to_merged.of(*src_pos).is_some() {
                assert_eq!(
                    a_roundtrip.of(*src_pos),
                    Some(*src_pos),
                    "compose(inv) should be identity at pos {}",
                    src_pos
                );
            }
        }
    }

    #[test]
    fn merge_result_all_positions_mapped_consistently() {
        let base = text_edition("abcdefgh");
        let a = text_edition("aXXdefYY");
        let b = text_edition("abYYefgh");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();

        let mut a_mapped_positions: Vec<i64> = Vec::new();
        for (pos, _) in a.cached_entries() {
            if let Some(mp) = mr.a_to_merged.of(*pos) {
                a_mapped_positions.push(mp);
            }
        }

        for i in 0..a_mapped_positions.len() {
            for j in (i + 1)..a_mapped_positions.len() {
                assert!(
                    a_mapped_positions[i] < a_mapped_positions[j],
                    "A mapping should preserve order: {} !< {} (src {} vs {})",
                    a_mapped_positions[i],
                    a_mapped_positions[j],
                    i,
                    j
                );
            }
        }

        let mut b_mapped_positions: Vec<i64> = Vec::new();
        for (pos, _) in b.cached_entries() {
            if let Some(mp) = mr.b_to_merged.of(*pos) {
                b_mapped_positions.push(mp);
            }
        }

        for i in 0..b_mapped_positions.len() {
            for j in (i + 1)..b_mapped_positions.len() {
                assert!(
                    b_mapped_positions[i] < b_mapped_positions[j],
                    "B mapping should preserve order: {} !< {} (src {} vs {})",
                    b_mapped_positions[i],
                    b_mapped_positions[j],
                    i,
                    j
                );
            }
        }
    }

    #[test]
    fn merge_result_no_duplicate_merged_positions() {
        let base = text_edition("abcdef");
        let a = text_edition("aXcYef");
        let b = text_edition("abZdeF");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();

        let mut all_mapped: Vec<i64> = Vec::new();
        for (pos, _) in a.cached_entries() {
            if let Some(mp) = mr.a_to_merged.of(*pos) {
                all_mapped.push(mp);
            }
        }
        for (pos, _) in b.cached_entries() {
            if let Some(mp) = mr.b_to_merged.of(*pos) {
                all_mapped.push(mp);
            }
        }

        all_mapped.sort();
        all_mapped.dedup();
        let merged_len = mr.merged.cached_entries().len() as i64;
        assert!(
            all_mapped.len() as i64 <= merged_len,
            "mapped positions should not exceed merged edition length"
        );
    }

    #[test]
    fn merge_result_both_sides_delete_all() {
        let base = text_edition("abc");
        let a = text_edition("");
        let b = text_edition("");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        assert_eq!(mr.merged.to_text(), "");
    }

    #[test]
    fn merge_result_a_deletes_all_b_unchanged() {
        let base = text_edition("abc");
        let a = text_edition("");
        let b = text_edition("abc");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        assert_eq!(mr.merged.to_text(), "");
    }

    #[test]
    fn merge_result_large_concurrent_edits() {
        let base = text_edition("abcdefghijklmnopqrstuvwxyz");
        let a = text_edition("aBcDefgHIJklmnopQrStuVwxyz");
        let b = text_edition("ab1cde2fgh3ijk4lmn5opq6rst7uvw8xyz");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();

        let a_inv = mr.a_to_merged.inverse();
        for (src_pos, _) in a.cached_entries() {
            if let Some(merged_pos) = mr.a_to_merged.of(*src_pos) {
                assert_eq!(
                    a_inv.of(merged_pos),
                    Some(*src_pos),
                    "A inverse failed at pos {}",
                    src_pos
                );
            }
        }

        let b_inv = mr.b_to_merged.inverse();
        for (src_pos, _) in b.cached_entries() {
            if let Some(merged_pos) = mr.b_to_merged.of(*src_pos) {
                assert_eq!(
                    b_inv.of(merged_pos),
                    Some(*src_pos),
                    "B inverse failed at pos {}",
                    src_pos
                );
            }
        }
    }

    #[test]
    fn batched_three_way_merge_no_changes() {
        let base = Edition::from_text_batched("hello\nworld\n");
        let a = Edition::from_text_batched("hello\nworld\n");
        let b = Edition::from_text_batched("hello\nworld\n");
        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        assert_eq!(mr.merged.to_text(), "hello\nworld\n");
    }

    #[test]
    fn batched_three_way_merge_a_edits_one_line() {
        let base = Edition::from_text_batched("line1\nline2\nline3\n");
        let mut a_entries: Vec<(i64, Arc<Carrier>)> = base.all_entries();
        a_entries[0] = (
            0,
            Arc::new(Carrier::new(RangeElement::text("LINE1\n".to_string()))),
        );
        let a = Edition::from_entries(a_entries);
        let b = Edition::from_text_batched("line1\nline2\nline3\n");
        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        let text = mr.merged.to_text();
        assert!(text.contains("LINE1"), "should contain A's edit");
        assert!(text.contains("line2"), "should retain unchanged lines");
        assert!(text.contains("line3"), "should retain unchanged lines");
    }

    #[test]
    fn batched_three_way_merge_both_edit_different_lines() {
        let base = Edition::from_text_batched("aaa\nbbb\nccc\n");
        let mut a_entries: Vec<(i64, Arc<Carrier>)> = base.all_entries();
        a_entries[0] = (
            0,
            Arc::new(Carrier::new(RangeElement::text("AAA\n".to_string()))),
        );
        let a = Edition::from_entries(a_entries);
        let mut b_entries: Vec<(i64, Arc<Carrier>)> = base.all_entries();
        b_entries[2] = (
            2,
            Arc::new(Carrier::new(RangeElement::text("CCC\n".to_string()))),
        );
        let b = Edition::from_entries(b_entries);
        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        let text = mr.merged.to_text();
        assert!(text.contains("AAA"), "should contain A's edit to line 1");
        assert!(text.contains("bbb"), "should retain unchanged line 2");
        assert!(text.contains("CCC"), "should contain B's edit to line 3");
    }

    #[test]
    fn batched_three_way_merge_delete_line() {
        let base = Edition::from_text_batched("keep\ndelete\nkeep2\n");
        let a_entries: Vec<(i64, Arc<Carrier>)> = vec![
            (
                0,
                Arc::new(Carrier::new(RangeElement::text("keep\n".to_string()))),
            ),
            (
                1,
                Arc::new(Carrier::new(RangeElement::text("keep2\n".to_string()))),
            ),
        ];
        let a = Edition::from_entries(a_entries);
        let b = Edition::from_text_batched("keep\ndelete\nkeep2\n");
        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        let text = mr.merged.to_text();
        assert!(!text.contains("delete"), "A deleted 'delete' line");
        assert!(text.contains("keep"), "should retain other lines");
    }

    #[test]
    fn batched_three_way_diff_identical_batched() {
        let base = Edition::from_text_batched("hello\nworld\n");
        let diff = three_way_diff(&base, &base, &base);
        assert!(diff.only_a.is_empty());
        assert!(diff.only_b.is_empty());
        assert!(diff.conflict.is_empty());
    }

    #[test]
    fn batched_build_merge_mapping() {
        let source = Edition::from_text_batched("aaa\nbbb\nccc\n");
        let merged = Edition::from_text_batched("aaa\nbbb\nccc\n");
        let mapping = build_merge_mapping(&source, &merged);
        assert!(!mapping.is_empty());
        assert_eq!(mapping.of(0), Some(0));
        assert_eq!(mapping.of(1), Some(1));
        assert_eq!(mapping.of(2), Some(2));
    }

    #[test]
    fn batched_merge_preserves_provenance() {
        use crate::edition::provenance::{AuthorType, ElementProvenance};
        let prov = ElementProvenance {
            author_public_key: [1u8; 32],
            author_display_name: "alice".to_string(),
            author_club_id: 0,
            timestamp: 100,
            author_type: AuthorType::Human,
            llm_model: None,
            historical_author_id: None,
            source_work_id: None,
            transcluded_by: None,
            derived_by: None,
        };
        let base = Edition::from_text_batched("hello\nworld\n");
        let mut a_entries: Vec<(i64, Arc<Carrier>)> = base.all_entries();
        a_entries[0] = (
            0,
            Arc::new(
                Carrier::new(RangeElement::text("HELLO\n".to_string()))
                    .with_provenance(prov.clone()),
            ),
        );
        let a = Edition::from_entries(a_entries);
        let b = Edition::from_text_batched("hello\nworld\n");
        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        let has_prov = mr
            .merged
            .all_entries()
            .iter()
            .any(|(_, c)| c.provenance.is_some());
        assert!(has_prov, "merged edition should carry A's provenance");
    }

    #[test]
    fn unchanged_region_all_same() {
        let base = text_edition("hello world");
        let a = text_edition("hello world");
        let b = text_edition("hello world");
        let diff = three_way_diff(&base, &a, &b);
        let region = diff.unchanged_region();
        assert!(region.contains(0));
        assert!(region.contains(10));
    }

    #[test]
    fn unchanged_region_with_changes() {
        let base = text_edition("hello world");
        let a = text_edition("HELLO world");
        let b = text_edition("hello world");
        let diff = three_way_diff(&base, &a, &b);
        let region = diff.unchanged_region();
        assert!(!region.contains(0));
        assert!(region.contains(7));
    }

    #[test]
    fn changed_region_complement_of_unchanged() {
        let base = text_edition("hello world");
        let a = text_edition("HELLO world");
        let b = text_edition("hello WORLD");
        let diff = three_way_diff(&base, &a, &b);
        let changed = diff.changed_region(11);
        let unchanged = diff.unchanged_region();
        assert!(!changed.intersects(&unchanged));
        assert!(changed.contains(0));
        assert!(changed.contains(6));
    }

    #[test]
    fn conflict_density_zero_when_complementary() {
        let base = text_edition("hello world");
        let a = text_edition("HELLO world");
        let b = text_edition("hello WORLD");
        let diff = three_way_diff(&base, &a, &b);
        assert_eq!(diff.conflict_density(), 0.0);
    }

    #[test]
    fn conflict_density_nonzero_when_overlapping() {
        let base = text_edition("hello");
        let a = text_edition("HELLO");
        let b = text_edition("Hello");
        let diff = three_way_diff(&base, &a, &b);
        assert!(diff.conflict_density() > 0.0);
    }

    #[test]
    fn unchanged_intervals_clean_decomposition() {
        let base = text_edition("aaa bbb ccc");
        let a = text_edition("aaa XXX ccc");
        let b = text_edition("aaa bbb ccc");
        let diff = three_way_diff(&base, &a, &b);
        let intervals = diff.unchanged_intervals();
        assert!(intervals.len() >= 1);
        for (start, end) in &intervals {
            assert!(*start < *end, "intervals must be non-empty");
        }
    }

    #[test]
    fn changed_intervals_for_heatmap() {
        let base = text_edition("abcdefghij");
        let a = text_edition("abcXefghij");
        let b = text_edition("abcdefghij");
        let diff = three_way_diff(&base, &a, &b);
        let intervals = diff.changed_intervals(10);
        assert!(
            !intervals.is_empty(),
            "should have at least one changed interval"
        );
    }

    fn dummy_provenance(author: u8) -> Provenance {
        Provenance {
            author_public_key: [author; 32],
            signature: [0u8; 64],
            timestamp: 1000,
            server_id: [0u8; 32],
        }
    }

    #[test]
    fn merge_conflict_preserves_non_text_from_losing_side() {
        let base = text_edition("X");

        let a = text_edition("A");

        let mut b = text_edition("B");
        b = b.with(1, RangeElement::data(vec![9]));

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();

        let has_data = mr
            .merged
            .all_entries()
            .iter()
            .any(|(_, c)| matches!(c.element, RangeElement::Data { .. }));
        assert!(
            has_data,
            "non-text element from losing side should survive conflict"
        );
    }

    #[test]
    fn merge_conflict_preserves_transclusion_from_losing_side() {
        let base = text_edition("X");

        let a = text_edition("A");

        let mut b = text_edition("B");
        b = b.with(1, RangeElement::edition(42));

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();

        let has_edition = mr
            .merged
            .all_entries()
            .iter()
            .any(|(_, c)| matches!(c.element, RangeElement::Edition { .. }));
        assert!(
            has_edition,
            "edition-ref (transclusion) from losing side should survive conflict"
        );
    }

    #[test]
    fn merge_span_provenance_preserved_no_changes() {
        let base = text_edition("ab");
        let a = text_edition("ab");
        let b = text_edition("ab");

        let a_sp = a.with_span_provenance(vec![SpanProvenance {
            start: 0,
            end: 2,
            provenance: dummy_provenance(1),
        }]);

        let mr = three_way_merge(&base, &a_sp, &b, MergeStrategy::LastWriterWins).unwrap();

        assert_eq!(mr.merged.span_provenance().len(), 1);
        assert_eq!(mr.merged.span_provenance()[0].start, 0);
        assert_eq!(mr.merged.span_provenance()[0].end, 2);
    }

    #[test]
    fn merge_span_provenance_shifted_by_other_insertion() {
        let base = text_edition("cd");
        let a = text_edition("cd");
        let b = text_edition("abcd");

        let a_sp = a.with_span_provenance(vec![SpanProvenance {
            start: 0,
            end: 2,
            provenance: dummy_provenance(1),
        }]);

        let mr = three_way_merge(&base, &a_sp, &b, MergeStrategy::LastWriterWins).unwrap();

        assert_eq!(mr.merged.to_text(), "abcd");
        let sp = mr.merged.span_provenance();
        assert_eq!(sp.len(), 1, "span provenance should survive");
        assert_eq!(sp[0].start, 2, "start should shift by B's insertion length");
        assert_eq!(sp[0].end, 4, "end should shift by B's insertion length");
    }

    #[test]
    fn merge_span_provenance_dropped_on_non_contiguous() {
        let base = text_edition("ac");
        let a = text_edition("abc");
        let b = text_edition("aXYZWc");

        let a_sp = a.with_span_provenance(vec![SpanProvenance {
            start: 0,
            end: 3,
            provenance: dummy_provenance(1),
        }]);

        let mr = three_way_merge(&base, &a_sp, &b, MergeStrategy::LastWriterWins).unwrap();

        assert_eq!(mr.merged.to_text(), "abXYZWc");
        let sp = mr.merged.span_provenance();
        // Split contract: the author's text survives as fragments
        // around the other editor's XYZW insert; the inserted chars
        // are not theirs. Never dropped.
        assert!(
            !sp.is_empty(),
            "author attribution must survive a non-contiguous merge"
        );
        assert!(
            sp.iter()
                .all(|s| s.end <= 2 || s.start >= 6 || (s.end - s.start) <= 3),
            "fragments cover only the author's characters, got {:?}",
            sp.iter().map(|s| (s.start, s.end)).collect::<Vec<_>>()
        );
    }

    #[test]
    fn merge_span_provenance_dedup_identical() {
        let base = text_edition("ab");
        let a = text_edition("ab");
        let b = text_edition("ab");

        let prov = dummy_provenance(1);
        let a_sp = a.with_span_provenance(vec![SpanProvenance {
            start: 0,
            end: 2,
            provenance: prov.clone(),
        }]);
        let b_sp = b.with_span_provenance(vec![SpanProvenance {
            start: 0,
            end: 2,
            provenance: prov,
        }]);

        let mr = three_way_merge(&base, &a_sp, &b_sp, MergeStrategy::LastWriterWins).unwrap();

        assert_eq!(
            mr.merged.span_provenance().len(),
            1,
            "identical span provenance from both sides should dedup"
        );
    }

    #[test]
    fn merge_span_provenance_both_sides_distinct() {
        let base = text_edition("abcd");
        let a = text_edition("abcd");
        let b = text_edition("abcd");

        let a_sp = a.with_span_provenance(vec![SpanProvenance {
            start: 0,
            end: 2,
            provenance: dummy_provenance(1),
        }]);
        let b_sp = b.with_span_provenance(vec![SpanProvenance {
            start: 2,
            end: 4,
            provenance: dummy_provenance(2),
        }]);

        let mr = three_way_merge(&base, &a_sp, &b_sp, MergeStrategy::LastWriterWins).unwrap();

        assert_eq!(
            mr.merged.span_provenance().len(),
            2,
            "distinct span provenance from both sides should both survive"
        );
    }

    #[test]
    fn delta_span_provenance_survives_append() {
        let original = text_edition("ab");
        let modified = text_edition("abc");

        let mapping = build_merge_mapping(&original, &modified);

        let span = SpanProvenance {
            start: 0,
            end: 2,
            provenance: dummy_provenance(1),
        };

        let migrated = migrate_span_provenance_single(&[span], &mapping);
        assert_eq!(migrated.len(), 1);
        assert_eq!(migrated[0].start, 0);
        assert_eq!(migrated[0].end, 2);
    }

    #[test]
    fn delta_span_provenance_shifts_on_prepend() {
        let original = text_edition("ab");
        let modified = text_edition("Xab");

        let mapping = build_merge_mapping(&original, &modified);

        let span = SpanProvenance {
            start: 0,
            end: 2,
            provenance: dummy_provenance(1),
        };

        let migrated = migrate_span_provenance_single(&[span], &mapping);
        assert_eq!(migrated.len(), 1);
        assert_eq!(migrated[0].start, 1);
        assert_eq!(migrated[0].end, 3);
    }

    #[test]
    fn delta_span_provenance_dropped_on_mid_insert() {
        let original = text_edition("abc");
        let modified = text_edition("aXbc");

        let mapping = build_merge_mapping(&original, &modified);

        let span = SpanProvenance {
            start: 0,
            end: 3,
            provenance: dummy_provenance(1),
        };

        let migrated = migrate_span_provenance_single(&[span], &mapping);
        // Split contract: the author keeps fragments covering exactly
        // their surviving text; the editor's inserted 'X' is NOT
        // attributed to them. 'a' -> [0,1), 'bc' -> [2,4).
        assert!(
            migrated.len() >= 1,
            "mid-span insertion must never erase the author's attribution"
        );
        let covered: Vec<(i64, i64)> = migrated.iter().map(|s| (s.start, s.end)).collect();
        assert!(
            covered.contains(&(0, 1)) && covered.contains(&(2, 4)),
            "expected fragments [0,1) and [2,4) around the inserted 'X', got {:?}",
            covered
        );
        for f in &migrated {
            assert!(
                !(f.start <= 1 && f.end > 1),
                "no fragment may cover the editor's inserted character at 1, got {:?}",
                covered
            );
        }
    }

    #[test]
    fn delta_span_provenance_partial_survives_deletion() {
        let original = text_edition("abcd");
        let modified = text_edition("ad");

        let mapping = build_merge_mapping(&original, &modified);

        let span = SpanProvenance {
            start: 0,
            end: 4,
            provenance: dummy_provenance(1),
        };

        let migrated = migrate_span_provenance_single(&[span], &mapping);
        assert_eq!(migrated.len(), 1, "partially deleted span should survive");
        assert_eq!(migrated[0].start, 0);
        assert_eq!(migrated[0].end, 2);
    }

    #[test]
    fn provenance_survives_merge_prefers_carrier_with_provenance() {
        let base = text_edition("abc");
        let a = text_edition("abc");
        let b = text_edition("abc");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();

        let text = mr.merged.to_text();
        assert_eq!(text, "abc");
    }

    #[test]
    fn entry_identities_match_after_coalesce() {
        let edition = Edition::from_text("abc");
        let coalesced = edition.coalesce();

        let orig_ids = edition.entry_identities();
        let coal_ids = coalesced.entry_identities();

        assert_eq!(orig_ids.len(), 3, "from_text creates per-char entries");
        assert!(
            coal_ids.len() <= orig_ids.len(),
            "coalesce should not increase entry count"
        );
    }

    #[test]
    fn merge_preserves_element_provenance_from_winning_side() {
        let base = text_edition("X");

        let mut a_entries: Vec<(i64, Arc<Carrier>)> = Vec::new();
        let mut c = Carrier::new(RangeElement::text("A".to_string()));
        c = c.with_provenance(crate::edition::provenance::ElementProvenance {
            author_public_key: [1; 32],
            author_display_name: "Alice".to_string(),
            author_club_id: 0,
            timestamp: 1000,
            author_type: crate::edition::provenance::AuthorType::Human,
            llm_model: None,
            historical_author_id: None,
            source_work_id: None,
            transcluded_by: None,
            derived_by: None,
        });
        a_entries.push((0, Arc::new(c)));
        let a = Edition::from_entries(a_entries);

        let b = text_edition("B");

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();

        let a_carrier = mr
            .merged
            .all_entries()
            .into_iter()
            .find(|(_, c)| c.provenance.is_some());

        assert!(
            a_carrier.is_some(),
            "provenance from winning side (A has provenance, B doesn't) should survive"
        );
        if let Some((_, c)) = a_carrier {
            assert_eq!(c.provenance.as_ref().unwrap().author_display_name, "Alice");
        }
    }

    proptest! {
        #[test]
        fn prop_merge_idempotent(text in "[a-z]{0,50}") {
            let base = text_edition(&text);
            let a = base.clone();
            let b = base.clone();

            let mr = three_way_merge(
                &base, &a, &b, MergeStrategy::LastWriterWins,
            ).unwrap();

            prop_assert_eq!(mr.merged.to_text(), text);
        }

        #[test]
        fn prop_merge_all_content_survives(
            base_text in "[a-z]{1,30}",
            a_text in "[a-z]{1,30}",
            b_text in "[a-z]{1,30}"
        ) {
            let base = text_edition(&base_text);
            let a = text_edition(&a_text);
            let b = text_edition(&b_text);

            let mr = three_way_merge(
                &base, &a, &b, MergeStrategy::LastWriterWins,
            ).unwrap();

            let merged_text = mr.merged.to_text();
            let merged_len = merged_text.len();
            let sum = a_text.len() + b_text.len();

            prop_assert!(
                merged_len <= sum * 3,
                "merged should not be absurdly large: merged={}, a+b={}",
                merged_len, sum
            );
        }

        #[test]
        fn prop_merge_preserves_data_elements(
            base_text in "[a-z]{1,20}",
            a_text in "[a-z]{1,20}",
        ) {
            let mut base = text_edition(&base_text);
            let data_pos = base_text.len() as i64;
            base = base.with(data_pos, RangeElement::data(vec![1, 2, 3]));

            let mut a = base.clone();
            a = a.with(0, RangeElement::text("X"));

            let b = base.clone();

            let mr = three_way_merge(
                &base, &a, &b, MergeStrategy::LastWriterWins,
            ).unwrap();

            let has_data = mr.merged.all_entries().iter()
                .any(|(_, c)| matches!(c.element, RangeElement::Data { .. }));
            prop_assert!(has_data, "data element should survive merge");
        }

        #[test]
        fn prop_span_provenance_positions_valid(
            base_text in "[a-z]{2,20}",
            a_text in "[a-z]{2,20}",
            b_text in "[a-z]{2,20}"
        ) {
            let base = text_edition(&base_text);
            let a = text_edition(&a_text);
            let b = text_edition(&b_text);

            let a_sp = a.with_span_provenance(vec![SpanProvenance {
                start: 0,
                end: a_text.len() as i64,
                provenance: dummy_provenance(1),
            }]);

            let mr = three_way_merge(
                &base, &a_sp, &b, MergeStrategy::LastWriterWins,
            ).unwrap();

            let merged_count = mr.merged.count() as i64;
            for span in mr.merged.span_provenance() {
                prop_assert!(span.start >= 0, "span start must be non-negative");
                prop_assert!(
                    span.end <= merged_count,
                    "span end must be within merged bounds"
                );
                prop_assert!(span.start < span.end, "span must be non-empty");
            }
        }

        #[test]
        fn prop_merge_does_not_duplicate(
            base_text in "[a-z]{1,30}",
            delta_text in "[a-z]{0,20}",
        ) {
            let base = text_edition(&base_text);
            let a = text_edition(&(delta_text.clone() + &base_text));
            let b = base.clone();

            let mr = three_way_merge(
                &base, &a, &b, MergeStrategy::LastWriterWins,
            ).unwrap();

            let merged = mr.merged.to_text();
            let expected_len = delta_text.len() + base_text.len();
            let actual_len = merged.len();
            prop_assert!(
                actual_len <= expected_len * 2,
                "merge should not wildly duplicate: expected ~{}, got {}",
                expected_len, actual_len
            );
        }

        #[test]
        fn prop_entry_identities_consistent(
            text in "[a-z]{1,50}",
        ) {
            let edition = text_edition(&text);
            let ids = edition.entry_identities();

            prop_assert_eq!(ids.len(), text.len());
            for (i, id) in ids.iter().enumerate() {
                prop_assert_eq!(id.position, i as i64);
                prop_assert!(id.is_text);
            }
        }

        #[test]
        fn prop_crum_skip_one_side_unchanged(
            base_text in "[a-z]{5,30}",
            b_text in "[a-z]{5,30}",
        ) {
            prop_assume!(base_text != b_text);
            let base = text_edition(&base_text);
            let a = base.clone();
            let b = text_edition(&b_text);

            let diff = three_way_diff(&base, &a, &b);
            let has_changes = !diff.only_b.is_empty() || !diff.conflict.is_empty();
            prop_assert!(
                has_changes,
                "B differs from base, so diff should have changes"
            );
        }

        #[test]
        fn prop_crum_skip_both_sides_identical(
            base_text in "[a-z]{5,30}",
            edit_text in "[a-z]{5,30}",
        ) {
            prop_assume!(base_text != edit_text);
            let base = text_edition(&base_text);
            let a = text_edition(&edit_text);
            let b = text_edition(&edit_text);

            let mr = three_way_merge(
                &base, &a, &b, MergeStrategy::LastWriterWins,
            ).unwrap();

            let merged = mr.merged.to_text();
            prop_assert!(
                merged.contains(&edit_text[..1]),
                "merged should contain content from both sides (which agree): got {:?}",
                merged
            );
        }
    }

    fn alice_prov() -> ElementProvenance {
        ElementProvenance {
            author_public_key: [1; 32],
            author_display_name: "Alice".to_string(),
            author_club_id: 0,
            timestamp: 1000,
            author_type: AuthorType::Human,
            llm_model: None,
            historical_author_id: None,
            source_work_id: None,
            transcluded_by: None,
            derived_by: None,
        }
    }

    fn bob_prov() -> ElementProvenance {
        ElementProvenance {
            author_public_key: [2; 32],
            author_display_name: "Bob".to_string(),
            author_club_id: 0,
            timestamp: 2000,
            author_type: AuthorType::Human,
            llm_model: None,
            historical_author_id: None,
            source_work_id: None,
            transcluded_by: None,
            derived_by: None,
        }
    }

    fn edition_chars_prov(text: &str, prov: &ElementProvenance) -> Edition {
        let entries: Vec<(i64, Arc<Carrier>)> = text
            .chars()
            .enumerate()
            .map(|(i, ch)| {
                let carrier = Carrier::new(RangeElement::text(ch.to_string()))
                    .with_provenance((*prov).clone());
                (i as i64, Arc::new(carrier))
            })
            .collect();
        Edition::from_entries(entries)
    }

    fn edition_mixed_prov(parts: &[(&str, &ElementProvenance)]) -> Edition {
        let mut entries = Vec::new();
        let mut pos = 0i64;
        for (text, prov) in parts {
            for ch in text.chars() {
                let carrier = Carrier::new(RangeElement::text(ch.to_string()))
                    .with_provenance((**prov).clone());
                entries.push((pos, Arc::new(carrier)));
                pos += 1;
            }
        }
        Edition::from_entries(entries)
    }

    #[test]
    fn lifecycle_multi_author_concurrent_edit() {
        let alice = alice_prov();
        let bob = bob_prov();

        let base = edition_chars_prov("hello world", &alice);
        let a = edition_chars_prov("hello world!", &alice);
        let b = edition_mixed_prov(&[("HELLO", &bob), (" world", &alice)]);

        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();

        let merged_text = mr.merged.to_text();
        assert!(merged_text.contains("HELLO"), "Bob's edit should survive");
        assert!(
            merged_text.contains(" world"),
            "unchanged content should survive"
        );
        assert!(merged_text.contains('!'), "Alice's edit should survive");

        let entries = mr.merged.all_entries();
        let has_alice = entries.iter().any(|(_, c)| {
            c.provenance
                .as_ref()
                .map_or(false, |p| p.author_display_name == "Alice")
        });
        let has_bob = entries.iter().any(|(_, c)| {
            c.provenance
                .as_ref()
                .map_or(false, |p| p.author_display_name == "Bob")
        });
        assert!(has_alice, "Alice should be attributable in merged result");
        assert!(has_bob, "Bob should be attributable in merged result");
    }

    #[test]
    fn lifecycle_split_preserves_original_author() {
        let alice = alice_prov();

        let entries: Vec<(i64, Arc<Carrier>)> = vec![
            (
                0,
                Arc::new(
                    Carrier::new(RangeElement::text("hello".to_string()))
                        .with_provenance(alice.clone()),
                ),
            ),
            (
                1,
                Arc::new(
                    Carrier::new(RangeElement::text("world".to_string()))
                        .with_provenance(alice.clone()),
                ),
            ),
        ];
        let edition = Edition::from_entries(entries);

        use crate::server::otree_crdt::apply_text_delta_to_edition;
        use crate::server::transport::protocol::TextDeltaOp;

        let result = apply_text_delta_to_edition(
            &edition,
            &[
                TextDeltaOp::Retain { count: 3 },
                TextDeltaOp::Delete { count: 2 },
                TextDeltaOp::Retain { count: 5 },
            ],
            None,
        );

        assert_eq!(result.to_text(), "helworld");
        let all_have_alice = result
            .all_entries()
            .iter()
            .filter(|(_, c)| c.element.as_text().is_some())
            .all(|(_, c)| {
                c.provenance
                    .as_ref()
                    .map_or(false, |p| p.author_display_name == "Alice")
            });
        assert!(
            all_have_alice,
            "all text entries should retain Alice's provenance after split"
        );
    }

    #[test]
    fn lifecycle_span_provenance_create_edit_merge() {
        let alice = alice_prov();
        let base = edition_chars_prov("abcdef", &alice);
        let a = edition_chars_prov("abcdef", &alice);
        let a_sp = a.with_span_provenance(vec![SpanProvenance {
            start: 0,
            end: 3,
            provenance: dummy_provenance(1),
        }]);
        let b = edition_chars_prov("Xabcdef", &alice);

        let mr = three_way_merge(&base, &a_sp, &b, MergeStrategy::LastWriterWins).unwrap();

        assert_eq!(mr.merged.to_text(), "Xabcdef");
        let sp = mr.merged.span_provenance();
        assert_eq!(sp.len(), 1, "span should shift after B's prepend");
        assert_eq!(sp[0].start, 1);
        assert_eq!(sp[0].end, 4);
    }

    #[test]
    fn lifecycle_non_text_survives_two_merges() {
        let base = {
            let mut e = text_edition("ab");
            e = e.with(2, RangeElement::edition(100));
            e = e.with(3, RangeElement::text("cd"));
            e
        };
        let a = {
            let mut e = text_edition("AXb");
            e = e.with(3, RangeElement::edition(100));
            e = e.with(4, RangeElement::text("cd"));
            e
        };
        let b = {
            let mut e = text_edition("ab");
            e = e.with(2, RangeElement::edition(200));
            e = e.with(3, RangeElement::text("cd"));
            e
        };

        let mr1 = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        let has_t1 = mr1
            .merged
            .all_entries()
            .iter()
            .any(|(_, c)| matches!(c.element, RangeElement::Edition { .. }));
        assert!(has_t1, "transclusion should survive first merge");

        let c = text_edition("different");
        let mr2 = three_way_merge(&base, &mr1.merged, &c, MergeStrategy::LastWriterWins).unwrap();
        let has_t2 = mr2
            .merged
            .all_entries()
            .iter()
            .any(|(_, c)| matches!(c.element, RangeElement::Edition { .. }));
        assert!(has_t2, "transclusion should survive second merge");
    }

    #[test]
    fn lifecycle_provenance_chain_two_merge_rounds() {
        let alice = alice_prov();
        let bob = bob_prov();

        let base = edition_chars_prov("hello", &alice);
        let round1 = edition_mixed_prov(&[("HELLO", &bob), (" world", &alice)]);
        let mr1 = three_way_merge(&base, &round1, &base, MergeStrategy::LastWriterWins).unwrap();
        let has_bob_1 = mr1.merged.all_entries().iter().any(|(_, c)| {
            c.provenance
                .as_ref()
                .map_or(false, |p| p.author_display_name == "Bob")
        });
        assert!(has_bob_1, "Bob should be present after round 1");

        let round2 = edition_mixed_prov(&[("HELLO", &bob), (" world", &alice), ("!", &alice)]);
        let mr2 =
            three_way_merge(&base, &mr1.merged, &round2, MergeStrategy::LastWriterWins).unwrap();

        let final_text = mr2.merged.to_text();
        assert!(
            final_text.contains("HELLO"),
            "Bob's edit should survive two rounds"
        );
        assert!(
            final_text.contains('!'),
            "Alice's addition should survive two rounds"
        );

        let has_alice = mr2.merged.all_entries().iter().any(|(_, c)| {
            c.provenance
                .as_ref()
                .map_or(false, |p| p.author_display_name == "Alice")
        });
        let has_bob = mr2.merged.all_entries().iter().any(|(_, c)| {
            c.provenance
                .as_ref()
                .map_or(false, |p| p.author_display_name == "Bob")
        });
        assert!(has_alice, "Alice attributable after 2 merge rounds");
        assert!(has_bob, "Bob attributable after 2 merge rounds");
    }

    /// Benchmark: build_merge_mapping at increasing scale. Documents the
    /// O(n) fingerprint-map build run on every edit (twice in the no-merge
    /// path) — the target of incremental merge mapping (PERF-PLAN Stage 6).
    ///
    /// NOTE: sizes are capped small because Mapping::combine canonicalizes
    /// the full parts list on every fold step, making the total fold
    /// quadratic — this is itself a measured cost of the current design.
    #[test]
    fn benchmark_build_merge_mapping_scale() {
        for size in [1_000usize, 3_000, 9_000] {
            let text: String = "ab".repeat(size / 2);
            let base = text_edition(&text);
            let mid = size / 2;
            let edited = text_edition(&format!("{}X{}", &text[..mid], &text[mid..]));

            let start = std::time::Instant::now();
            let mapping = build_merge_mapping(&base, &edited);
            let elapsed = start.elapsed();

            let mapped = mapping
                .of_region(&crate::edition::XnRegion::interval(0, 1))
                .intervals()
                .len();
            assert_eq!(mapped, 1);
            println!("build_merge_mapping ({} entries): {:?}", size, elapsed);
        }
    }

    /// S7: merge scaling at 10k/100k — both-sides-changed with a small
    /// localized edit each (the common collaborative case after
    /// Stage 5: edits arrive as sparse-layout editions).
    #[test]
    fn benchmark_merge_both_sides_scale() {
        for size in [10_000usize, 100_000] {
            let text: String = "ab".repeat(size / 2);
            let mid = size / 2;
            let base = text_edition(&text);
            let a = text_edition(&format!("{}X{}", &text[..mid], &text[mid..]));
            let b = text_edition(&format!("{}{}Y", &text[..mid + 10], &text[mid + 10..]));

            let start = std::time::Instant::now();
            let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
            let elapsed = start.elapsed();

            let t = mr.merged.to_text();
            assert!(t.contains('X') && t.contains('Y'));
            println!(
                "merge_both_sides localized ({} entries): {:?}",
                size, elapsed
            );
        }
    }

    #[test]
    fn benchmark_merge_no_concurrent_edits() {
        let text: String = (0..1000)
            .map(|i| char::from_u32(97 + i % 26).unwrap())
            .collect();
        let base = text_edition(&text);
        let a = base.clone();
        let b = base.clone();

        let start = std::time::Instant::now();
        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        let elapsed = start.elapsed();

        assert_eq!(mr.merged.to_text(), text);
        println!("merge_no_concurrent (1000 entries): {:?}", elapsed);
    }

    #[test]
    fn benchmark_merge_single_sided() {
        let text: String = (0..1000)
            .map(|i| char::from_u32(97 + i % 26).unwrap())
            .collect();
        let base = text_edition(&text);
        let a = text_edition(&format!("{}!", &text));

        let start = std::time::Instant::now();
        let mr = three_way_merge(&base, &a, &base, MergeStrategy::LastWriterWins).unwrap();
        let elapsed = start.elapsed();

        assert!(mr.merged.to_text().contains('!'));
        println!("merge_single_sided (1000 entries): {:?}", elapsed);
    }

    #[test]
    fn benchmark_merge_both_sides_changed() {
        let text: String = (0..1000)
            .map(|i| char::from_u32(97 + i % 26).unwrap())
            .collect();
        let base = text_edition(&text);
        let a = text_edition(&format!("X{}", &text[..999]));
        let b = text_edition(&format!("{}{}", &text[..999], "Y"));

        let start = std::time::Instant::now();
        let mr = three_way_merge(&base, &a, &b, MergeStrategy::LastWriterWins).unwrap();
        let elapsed = start.elapsed();

        println!("merge_both_changed (1000 entries): {:?}", elapsed);
    }

    #[test]
    fn benchmark_crum_comparison() {
        let text: String = (0..1000)
            .map(|i| char::from_u32(97 + i % 26).unwrap())
            .collect();
        let e1 = text_edition(&text);
        let e2 = text_edition(&text);
        let e3 = text_edition(&format!("{}!", &text));

        let start = std::time::Instant::now();
        let c1 = e1.crum();
        let c2 = e2.crum();
        let c3 = e3.crum();
        let elapsed = start.elapsed();

        assert_eq!(c1, c2);
        assert_ne!(c1, c3);
        println!("crum_comparison (1000 entries): {:?}", elapsed);
    }
}
