use std::sync::Arc;

use super::edition::Edition;
use super::mapping::Mapping;
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

    let base_to_a = compute_alignment(&base_e, &a_e);
    let base_to_b = compute_alignment(&base_e, &b_e);

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

fn compute_alignment(
    source: &[(i64, Arc<Carrier>)],
    target: &[(i64, Arc<Carrier>)],
) -> Vec<Option<usize>> {
    if source.is_empty() {
        return Vec::new();
    }

    let source_fps: Vec<[u8; 32]> = source.iter().map(|e| fp(e)).collect();
    let target_fps: Vec<[u8; 32]> = target.iter().map(|e| fp(e)).collect();

    let mut target_by_fp: std::collections::HashMap<[u8; 32], Vec<usize>> =
        std::collections::HashMap::new();
    for (j, fp_val) in target_fps.iter().enumerate() {
        target_by_fp.entry(*fp_val).or_default().push(j);
    }

    let mut seeds: Vec<(usize, usize, usize)> = Vec::new();
    for i in 0..source_fps.len() {
        if let Some(targets) = target_by_fp.get(&source_fps[i]) {
            for &j in targets {
                let mut len = 1usize;
                while i + len < source_fps.len()
                    && j + len < target_fps.len()
                    && source_fps[i + len] == target_fps[j + len]
                {
                    len += 1;
                }
                seeds.push((i, j, len));
            }
        }
    }

    seeds.sort_by(|a, b| b.2.cmp(&a.2).then_with(|| a.0.cmp(&b.0)));

    let mut source_matched = vec![false; source.len()];
    let mut target_matched = vec![false; target.len()];
    let mut alignment: Vec<Option<usize>> = vec![None; source.len()];

    for (si, ti, len) in &seeds {
        let mut ok = true;
        for k in 0..*len {
            if source_matched[si + k] || target_matched[ti + k] {
                ok = false;
                break;
            }
        }
        if !ok {
            continue;
        }
        for k in 0..*len {
            source_matched[si + k] = true;
            target_matched[ti + k] = true;
            alignment[si + k] = Some(ti + k);
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
        for (idx, (pos, _)) in entries.iter().enumerate() {
            if *pos >= start && *pos < end {
                matched.insert(idx);
            }
        }
    }

    for seg in segments {
        match seg {
            Segment::Unchanged {
                a_positions,
                b_positions,
                ..
            } => {
                for (idx, (pos, _)) in a_e.iter().enumerate() {
                    if a_positions.contains(pos) {
                        a_matched.insert(idx);
                    }
                }
                for (idx, (pos, _)) in b_e.iter().enumerate() {
                    if b_positions.contains(pos) {
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
            let mut j = i + 1;
            while j < n {
                let aj = base_to_a.get(j).copied().flatten();
                let bj = base_to_b.get(j).copied().flatten();
                if aj.is_some() && bj.is_some() {
                    base_positions.push(base_e[j].0);
                    a_positions.push(a_e[aj.unwrap()].0);
                    b_positions.push(b_e[bj.unwrap()].0);
                    j += 1;
                } else {
                    break;
                }
            }

            let mut start = 0;
            for k in 1..base_positions.len() {
                let a_gap = a_positions[k] - a_positions[k - 1] > 1;
                let b_gap = b_positions[k] - b_positions[k - 1] > 1;
                if a_gap || b_gap {
                    segments.push(Segment::Unchanged {
                        base_positions: base_positions[start..k].to_vec(),
                        a_positions: a_positions[start..k].to_vec(),
                        b_positions: b_positions[start..k].to_vec(),
                    });
                    if a_gap {
                        let gap_start = a_positions[k - 1] + 1;
                        let gap_end = a_positions[k];
                        for (idx, (pos, _)) in a_e.iter().enumerate() {
                            if *pos >= gap_start && *pos < gap_end {
                                a_matched.insert(idx);
                            }
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
                        for (idx, (pos, _)) in b_e.iter().enumerate() {
                            if *pos >= gap_start && *pos < gap_end {
                                b_matched.insert(idx);
                            }
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
            if let Some(pos) = find_base_pos_for_a(segments, a_e[start - 1].0) {
                pos + 1
            } else {
                0
            }
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
            if let Some(pos) = find_base_pos_for_b(segments, b_e[start - 1].0) {
                pos + 1
            } else {
                0
            }
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

    match strategy {
        MergeStrategy::LastWriterWins => {
            let (merged, a_map, b_map) = assemble_merge_lww(base, a, b, &diff);
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
                for (a_pos, b_pos) in a_positions.iter().zip(b_positions.iter()) {
                    let a_carrier = a_entries
                        .binary_search_by_key(a_pos, |(p, _)| *p)
                        .ok()
                        .map(|idx| a_entries[idx].1.clone());
                    let b_carrier = b_entries
                        .binary_search_by_key(b_pos, |(p, _)| *p)
                        .ok()
                        .map(|idx| b_entries[idx].1.clone());
                    let carrier = a_carrier.or(b_carrier).unwrap_or_else(|| {
                        let mut c = Carrier::new(RangeElement::text(""));
                        if let Some(prev) = merged_entries
                            .last()
                            .and_then(|(_, c)| c.provenance.clone())
                        {
                            c = c.with_provenance(prev);
                        }
                        Arc::new(c)
                    });
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
                let (source, from_a) = if a_entries.len() >= b_entries.len() {
                    (a_entries, true)
                } else {
                    (b_entries, false)
                };
                let merged_start = next_pos;
                for (src_pos, carrier) in &source {
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
                let other = if from_a {
                    collect_range(b.cached_entries(), b_span.0, b_span.1)
                } else {
                    collect_range(a.cached_entries(), a_span.0, a_span.1)
                };
                let mut m_pos = merged_start;
                for (src_pos, _) in &other {
                    if from_a {
                        b_sub.push(Mapping::restricted(
                            m_pos - src_pos,
                            XnRegion::singleton(*src_pos),
                        ));
                    } else {
                        a_sub.push(Mapping::restricted(
                            m_pos - src_pos,
                            XnRegion::singleton(*src_pos),
                        ));
                    }
                    m_pos += 1;
                }
            }
        }
    }

    let a_to_merged = a_sub
        .into_iter()
        .fold(Mapping::empty(), |acc, m| acc.combine(&m));
    let b_to_merged = b_sub
        .into_iter()
        .fold(Mapping::empty(), |acc, m| acc.combine(&m));

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
    entries
        .iter()
        .filter(|(pos, _)| *pos >= start && *pos < end)
        .cloned()
        .collect()
}

pub fn build_merge_mapping(source: &Edition, merged: &Edition) -> Mapping {
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

    let mut sub_mappings = Vec::new();
    let mut used_sources: std::collections::HashSet<i64> = std::collections::HashSet::new();

    for (merged_pos, carrier) in merged_entries {
        let fp_val = carrier.element.content_fingerprint();
        let mut key = [0u8; 8];
        key.copy_from_slice(&fp_val[..8]);
        if let Some(source_positions) = source_by_fp.get(&key) {
            for &src_pos in source_positions {
                if used_sources.insert(src_pos) {
                    sub_mappings.push(Mapping::restricted(
                        merged_pos - src_pos,
                        XnRegion::singleton(src_pos),
                    ));
                    break;
                }
            }
        }
    }

    sub_mappings
        .into_iter()
        .fold(Mapping::empty(), |acc, m| acc.combine(&m))
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::RangeElement;

    fn text_edition(s: &str) -> Edition {
        Edition::from_text(s)
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
}
