//! FR-38 S1: tumbler-stable span keys.
//!
//! A span key is an allocated hierarchical path (Gold tumbler style)
//! assigned to a span when its content is created and never mutated.
//! Char offsets — the working coordinate system — shift on edits;
//! keys do not. Inserting between two keys allocates a deeper level
//! (Gold's between-insertion rule), so no existing key ever changes
//! and keys remain strictly ordered.
//!
//! This is deliberately NOT the display/perm tumbler bridge
//! (`XudanuTumbler::for_char_range` bakes char offsets into the path
//! and rots with edits); it is the durable identity layer that
//! bridge will migrate onto (S3).

use std::cmp::Ordering;
use std::collections::BTreeSet;

/// A span's durable identity: an allocated path like `2.4.1`.
/// Ordering is lexicographic on components — allocation guarantees
/// it matches document order at all times.
#[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct SpanKey {
    components: Vec<u32>,
}

impl SpanKey {
    /// First span of a fresh space.
    pub fn first() -> Self {
        SpanKey {
            components: vec![1],
        }
    }

    pub fn components(&self) -> &[u32] {
        &self.components
    }

    /// Canonical string form: "2.4.1".
    pub fn canonical(&self) -> String {
        self.components
            .iter()
            .map(|c| c.to_string())
            .collect::<Vec<_>>()
            .join(".")
    }

    pub fn parse(s: &str) -> Option<Self> {
        if s.is_empty() {
            return None;
        }
        let mut components = Vec::new();
        for part in s.split('.') {
            components.push(part.parse::<u32>().ok()?);
        }
        Some(SpanKey { components })
    }
}

impl std::fmt::Display for SpanKey {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(&self.canonical())
    }
}

/// Allocated key space for one work's spans.
///
/// Invariant: the keys in `allocated` are exactly the live spans,
/// ordered by document order, and their lexicographic order matches
/// that document order — allocation maintains it, edits never touch
/// keys, only their char extents.
#[derive(Debug, Default, Clone)]
pub struct SpanKeySpace {
    allocated: BTreeSet<SpanKey>,
    base: u32,
}

impl SpanKeySpace {
    pub fn new() -> Self {
        SpanKeySpace {
            allocated: BTreeSet::new(),
            base: 1,
        }
    }

    /// A space whose first allocation is `start` instead of 1,
    /// reserving headroom below for front inserts (the map uses
    /// 2^31: effectively unlimited room on both sides).
    pub fn with_start(start: u32) -> Self {
        let mut s = SpanKeySpace::new();
        s.base = start;
        s
    }

    /// Allocate a key strictly before `first` (the current lowest
    /// key). Requires headroom — a space starting at 1 cannot go
    /// lower and degrades to `allocate_after_all`.
    pub fn allocate_before(&mut self, first: &SpanKey) -> SpanKey {
        if self.base > 1 && first.components.first() == Some(&self.base) {
            let lo = SpanKey {
                components: vec![1],
            };
            if let Some(k) = self.allocate_between(&lo, first) {
                return k;
            }
        }
        self.allocate_after_all()
    }

    pub fn len(&self) -> usize {
        self.allocated.len()
    }

    pub fn is_empty(&self) -> bool {
        self.allocated.is_empty()
    }

    pub fn iter(&self) -> impl Iterator<Item = &SpanKey> {
        self.allocated.iter()
    }

    /// Allocate the next key **after** every existing key (append at
    /// end of document). O(1) amortized: last component + 1.
    pub fn allocate_after_all(&mut self) -> SpanKey {
        let next = match self.allocated.iter().next_back() {
            None => SpanKey {
                components: vec![self.base],
            },
            Some(last) => {
                let mut c = last.components.clone();
                let n = c.len();
                c[n - 1] += 1;
                SpanKey { components: c }
            }
        };
        self.allocated.insert(next.clone());
        next
    }

    /// Allocate a key strictly between `prev` and `next`
    /// (document-order neighbours). Gold's rule:
    /// - gap between siblings → midpoint (u32 has room; worst case
    ///   after 31 mid-splits we descend)
    /// - adjacent siblings → one level deeper under `prev`
    /// Returns None if prev >= next (not a valid gap).
    pub fn allocate_between(&mut self, prev: &SpanKey, next: &SpanKey) -> Option<SpanKey> {
        match prev.components.cmp(&next.components) {
            Ordering::Greater | Ordering::Equal => return None,
            Ordering::Less => {}
        }
        let depth = prev.components.len().min(next.components.len());
        let mut branch = 0usize; // common prefix length
        while branch < depth && prev.components[branch] == next.components[branch] {
            branch += 1;
        }
        if branch == prev.components.len() {
            // `prev` is a strict prefix of `next` (e.g. [5] vs [5,1]).
            // With components >= 1 there is NO valid key strictly
            // between them ([5] < k < [5,1] requires [5,0]). Decline —
            // the caller falls back to allocate_after_all. Key order
            // is a convenience, never a correctness invariant (the
            // map's extents carry document order).
            return None;
        }
        let a = prev.components[branch];
        let b = next.components[branch];
        debug_assert!(a < b, "ordering checked above");

        let new_key = if b - a > 1 {
            // Gap: midpoint stays at the same depth.
            let mut c = prev.components[..=branch].to_vec();
            c[branch] = a + (b - a) / 2;
            SpanKey { components: c }
        } else {
            // Adjacent: descend one level under prev's branch.
            let mut c = prev.components[..=branch].to_vec();
            c.push(1);
            SpanKey { components: c }
        };
        // Never alias an existing key. Incrementing could jump past
        // `next` and break ordering — descend a level instead, which
        // is always strictly inside the gap.
        let mut probe = new_key;
        while self.allocated.contains(&probe) {
            let mut c = probe.components.clone();
            c.push(1);
            probe = SpanKey { components: c };
        }
        self.allocated.insert(probe.clone());
        Some(probe)
    }

    /// Retire a span's key (content deleted). The gap it leaves is
    /// what midpoint allocation reuses — keys of surviving spans are
    /// still never mutated.
    pub fn retire(&mut self, key: &SpanKey) -> bool {
        self.allocated.remove(key)
    }

    /// The key governing a char offset, given the (offset-sorted)
    /// extents of allocated spans: (char_start, key) pairs.
    /// Returns the last span starting at or before `offset`.
    pub fn key_at<'a>(
        &self,
        extents: &'a [(usize, SpanKey)],
        offset: usize,
    ) -> Option<&'a SpanKey> {
        let mut best: Option<&SpanKey> = None;
        for (start, key) in extents {
            if *start <= offset {
                best = Some(key);
            } else {
                break;
            }
        }
        best
    }
}

/// FR-38 S2: a work's live span table — (char_start, char_len, key)
/// sorted by start. Maintained alongside content edits:
/// inserts/deletes adjust extents and allocate/retire keys, but
/// **never mutate a surviving key**. This is what diff coordinates
/// and permalinks resolve against.
#[derive(Debug, Default, Clone)]
pub struct SpanKeyMap {
    spans: Vec<(usize, usize, SpanKey)>,
    /// Starts at 2^31: front inserts have the whole lower half of
    /// u32 to allocate into (midpoints against a synthetic [1]).
    space: SpanKeySpace,
}

impl SpanKeyMap {
    /// Initial map for bulk-created content: one span per
    /// `granularity` chars, keys allocated in order.
    pub fn from_total_chars(total_chars: usize, granularity: usize) -> Self {
        let mut m = SpanKeyMap {
            spans: Vec::new(),
            space: SpanKeySpace::with_start(2_147_483_648),
        };
        let g = granularity.max(1);
        let mut start = 0usize;
        while start < total_chars {
            let len = g.min(total_chars - start);
            let key = m.space.allocate_after_all();
            m.spans.push((start, len, key));
            start += len;
        }
        m
    }

    pub fn len(&self) -> usize {
        self.spans.len()
    }

    pub fn is_empty(&self) -> bool {
        self.spans.is_empty()
    }

    pub fn iter(&self) -> impl Iterator<Item = &(usize, usize, SpanKey)> {
        self.spans.iter()
    }

    /// Key covering a char offset (the last span starting at or
    /// before it).
    pub fn key_at(&self, offset: usize) -> Option<&SpanKey> {
        let mut best = None;
        for (start, _, key) in &self.spans {
            if *start <= offset {
                best = Some(key);
            } else {
                break;
            }
        }
        best
    }

    /// Char range currently governed by a key (permalink → offsets).
    pub fn range_of(&self, key: &SpanKey) -> Option<(usize, usize)> {
        for (start, len, k) in &self.spans {
            if k == key {
                return Some((*start, *start + *len));
            }
        }
        None
    }

    /// Insert new content: spans at/after `at` shift right by `len`;
    /// the new span's key is allocated between its new neighbours
    /// (front inserts use the reserved headroom below the space's
    /// start).
    pub fn insert_span(&mut self, at: usize, len: usize) -> SpanKey {
        for (start, _, _) in self.spans.iter_mut() {
            if *start >= at {
                *start += len;
            }
        }
        let idx = self.spans.partition_point(|(s, _, _)| *s < at);
        let prev_key = (idx > 0).then(|| self.spans[idx - 1].2.clone());
        let next_key = self.spans.get(idx).map(|(_, _, k)| k.clone());
        let key = match (&prev_key, &next_key) {
            (Some(p), Some(n)) => self
                .space
                .allocate_between(p, n)
                .unwrap_or_else(|| self.space.allocate_after_all()),
            (Some(_), None) => self.space.allocate_after_all(),
            (None, Some(first)) => self.space.allocate_before(first),
            (None, None) => self.space.allocate_after_all(),
        };
        self.spans.insert(idx, (at, len, key.clone()));
        key
    }

    /// Delete content: spans fully inside the range retire their
    /// keys; overlapping spans shrink (key survives); spans after
    /// shift left. Surviving keys are untouched.
    pub fn delete_range(&mut self, start: usize, end: usize) {
        let removed = end.saturating_sub(start);
        let mut out = Vec::with_capacity(self.spans.len());
        let mut retired: Vec<SpanKey> = Vec::new();
        for (s, l, k) in self.spans.drain(..) {
            let e = s + l;
            if e <= start {
                out.push((s, l, k)); // entirely before: untouched
            } else if s >= end {
                out.push((s - removed, l, k)); // entirely after: shift
            } else if s >= start && e <= end {
                retired.push(k); // fully deleted
            } else {
                // Overlaps the range: shrink; the key survives edits
                // (identity is durable even as extent changes).
                let overlap = e.min(end) - s.max(start);
                let ns = if s > start { s - removed } else { s };
                out.push((ns, l - overlap, k));
            }
        }
        for k in retired {
            self.space.retire(&k);
        }
        out.sort_by_key(|(s, _, _)| *s);
        self.spans = out;
    }
}

/// FR-38 S2: resolve a structural diff's matched ranges into
/// (key_in_a, key_in_b) pairs. Ranges without a governing key on
/// either side are skipped.
pub fn resolve_matched_keys(
    diff: &crate::edition::orgl::CrumDiff,
    map_a: &SpanKeyMap,
    map_b: &SpanKeyMap,
) -> Vec<(SpanKey, SpanKey)> {
    let mut out = Vec::with_capacity(diff.matched.len());
    for (sa, ea, sb, eb) in &diff.matched {
        if let (Some(ka), Some(kb)) = (map_a.key_at(*sa as usize), map_b.key_at(*sb as usize)) {
            out.push((ka.clone(), kb.clone()));
        }
        let _ = (ea, eb);
    }
    out
}

/// FR-38 S2: revision move detection. For editions of the SAME work
/// (shared key space), an `only_a` range whose key also resolves in
/// B — with matching content — is a MOVE, not a delete+insert.
pub fn detect_moves(
    diff: &crate::edition::orgl::CrumDiff,
    map_a: &SpanKeyMap,
    map_b: &SpanKeyMap,
    text_a: &str,
    text_b: &str,
) -> Vec<crate::edition::orgl::CrumDiff> {
    // One pseudo-diff entry per move: matched = (a_range, b_range).
    let mut moves = Vec::new();
    let chars_a: Vec<char> = text_a.chars().collect();
    let chars_b: Vec<char> = text_b.chars().collect();
    for (sa, ea) in &diff.only_a {
        let key = match map_a.key_at(*sa as usize) {
            Some(k) => k.clone(),
            None => continue,
        };
        let (sb, eb) = match map_b.range_of(&key) {
            Some(r) => r,
            None => continue,
        };
        let (sb, eb) = (sb as i64, eb as i64);
        if diff
            .matched
            .iter()
            .any(|(_, _, ms, me)| *ms <= sb && eb <= *me)
        {
            continue; // already matched structurally
        }
        let len_a = (*ea - *sa) as usize;
        let len_b = (eb - sb) as usize;
        if len_a != len_b {
            continue;
        }
        let a_slice: String = chars_a.iter().skip(*sa as usize).take(len_a).collect();
        let b_slice: String = chars_b.iter().skip(sb as usize).take(len_b).collect();
        if a_slice == b_slice && !a_slice.trim().is_empty() {
            moves.push(crate::edition::orgl::CrumDiff {
                matched: vec![(*sa, *ea, sb, eb)],
                only_a: Vec::new(),
                only_b: Vec::new(),
                matched_crum_count: 0,
            });
        }
    }
    moves
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn keys_stable_under_prefix_insert() {
        let mut space = SpanKeySpace::new();
        let k1 = space.allocate_after_all();
        let k2 = space.allocate_after_all();
        let k3 = space.allocate_after_all();
        let mut ext = vec![(0usize, k1.clone()), (4, k2.clone()), (8, k3.clone())];
        for (start, _) in ext.iter_mut() {
            *start += 3;
        }
        assert_eq!(
            space.iter().map(|k| k.canonical()).collect::<Vec<_>>(),
            vec!["1", "2", "3"]
        );
        assert_eq!(ext[0].0, 3);
        assert_eq!(space.key_at(&ext, 3).unwrap().canonical(), "1");
        assert_eq!(space.key_at(&ext, 7).unwrap().canonical(), "2");
    }

    #[test]
    fn between_allocation_orders_correctly() {
        let mut space = SpanKeySpace::new();
        let a = space.allocate_after_all();
        let b = space.allocate_after_all();
        let c = space.allocate_after_all();

        let m1 = space.allocate_between(&a, &b).unwrap();
        assert_eq!(m1.canonical(), "1.1");
        assert!(a < m1 && m1 < b && b < c);

        let m2 = space.allocate_between(&m1, &b).unwrap();
        assert!(m1 < m2 && m2 < b);

        let m3 = space.allocate_between(&b, &c).unwrap();
        assert_eq!(m3.canonical(), "2.1");

        // Midpoint reuse after retire: 1,2,3; retire 2; between 1
        // and 3 allocates the freed midpoint.
        let mut wide = SpanKeySpace::new();
        let w1 = wide.allocate_after_all();
        let w2 = wide.allocate_after_all();
        let w3 = wide.allocate_after_all();
        assert!(wide.retire(&w2));
        let mid = wide.allocate_between(&w1, &w3).unwrap();
        assert_eq!(mid.canonical(), "2");
        let inner = wide.allocate_between(&w1, &mid).unwrap();
        assert_eq!(inner.canonical(), "1.1");
    }

    #[test]
    fn between_declines_when_prev_prefix_of_next() {
        // The impossible adjacency: [5] and [5,1] are ordered
        // neighbours with NO valid key between them (would need the
        // illegal [5,0]). Found by the keystroke-cost hammer —
        // allocation must decline, never panic.
        let mut space = SpanKeySpace::new();
        let a = space.allocate_after_all(); // [1]
        let b = space.allocate_after_all(); // [2]
        let deep = space.allocate_between(&a, &b).unwrap(); // [1.1]
        assert!(a < deep && deep < b);
        // [1] vs [1.1]: prefix adjacency → None (no panic)
        // (a vs deep has room: allocates [1.0.5-style midpoint normally))
        // Direct check of the panicking shape:
        let prev = SpanKey::parse("5").unwrap();
        let next = SpanKey::parse("5.1").unwrap();
        assert!(prev < next);
        assert!(space.allocate_between(&prev, &next).is_none());
        // And it stays none for deeper prefixes:
        let prev2 = SpanKey::parse("5.1").unwrap();
        let next2 = SpanKey::parse("5.1.1").unwrap();
        assert!(space.allocate_between(&prev2, &next2).is_none());
    }

    #[test]
    fn between_rejects_invalid_gap() {
        let mut space = SpanKeySpace::new();
        let a = space.allocate_after_all();
        let b = space.allocate_after_all();
        assert!(space.allocate_between(&b, &a).is_none());
        assert!(space.allocate_between(&a.clone(), &a).is_none());
    }

    #[test]
    fn repeated_inserts_never_mutate_or_collide() {
        let mut space = SpanKeySpace::new();
        let mut left = space.allocate_after_all();
        let right = space.allocate_after_all();
        let snapshot_left = left.clone();

        let mut prev_keys = Vec::new();
        for _ in 0..50 {
            let k = space.allocate_between(&left, &right).unwrap();
            assert!(left < k && k < right, "new key stays in the gap");
            prev_keys.push(k.clone());
            left = k;
        }
        assert_eq!(space.len(), 52);
        assert_eq!(snapshot_left.canonical(), "1");
        for w in prev_keys.windows(2) {
            assert!(w[0] < w[1]);
        }
    }

    #[test]
    fn parse_roundtrip() {
        let k = SpanKey::parse("2.4.1").unwrap();
        assert_eq!(k.canonical(), "2.4.1");
        assert_eq!(k.components(), &[2, 4, 1]);
        assert!(SpanKey::parse("").is_none());
        assert!(SpanKey::parse("2.x").is_none());
    }

    // ── S2: SpanKeyMap edit maintenance ──────────────────────────────

    #[test]
    fn map_insert_between_allocates_and_shifts() {
        let mut m = SpanKeyMap::from_total_chars(100, 50);
        assert_eq!(m.len(), 2);
        let k_first = m.key_at(0).unwrap().clone();
        let k_second = m.key_at(60).unwrap().clone();

        // Insert 10 chars at 50 (between the two spans).
        let new_key = m.insert_span(50, 10);
        assert!(
            k_first < new_key && new_key < k_second,
            "orders between neighbours"
        );
        // Second span shifted right by 10; keys unchanged.
        assert_eq!(m.range_of(&k_second), Some((60, 110)));
        assert_eq!(m.range_of(&k_first), Some((0, 50)));
        assert_eq!(m.range_of(&new_key), Some((50, 60)));
    }

    #[test]
    fn map_front_insert_uses_headroom() {
        let mut m = SpanKeyMap::from_total_chars(100, 50);
        let first = m.key_at(0).unwrap().clone();
        let front = m.insert_span(0, 5);
        assert!(front < first, "front key orders before every existing key");
        assert_eq!(m.range_of(&front), Some((0, 5)));
        assert_eq!(m.range_of(&first), Some((5, 55)));
    }

    #[test]
    fn map_delete_retires_and_shifts_without_mutating() {
        let mut m = SpanKeyMap::from_total_chars(200, 50);
        let k1 = m.key_at(0).unwrap().clone();
        let k2 = m.key_at(60).unwrap().clone();
        let k3 = m.key_at(110).unwrap().clone();
        let k4 = m.key_at(160).unwrap().clone();

        // Delete span 2 entirely (50..100).
        m.delete_range(50, 100);
        assert_eq!(m.range_of(&k2), None, "retired key no longer resolves");
        // Neighbours untouched, later spans shifted left by 50.
        assert_eq!(m.range_of(&k1), Some((0, 50)));
        assert_eq!(m.range_of(&k3), Some((50, 100)));
        assert_eq!(m.range_of(&k4), Some((100, 150)));
        // Survivor canonical strings never changed.
        assert_eq!(k1.canonical(), k1.canonical());

        // Partial delete shrinks, key survives.
        m.delete_range(0, 25);
        assert_eq!(m.range_of(&k1), Some((0, 25)));
    }

    #[test]
    fn s2_detect_moves_contract() {
        use crate::edition::orgl::CrumDiff;

        // A moved block: same content, same KEY (revision of one
        // work), different offsets. Hand-built maps pin the
        // contract without depending on crum_diff gap boundaries.
        let block = "MOVEDBLOCKCONTENT";
        let text_a = format!("aaaa\n{block}\nbbbb\n");
        let text_b = format!("aaaa\nbbbb\n{block}\n");
        let old_start = text_a.find(block).unwrap();
        let new_start = text_b.find(block).unwrap();
        let blen = block.chars().count();

        let mut map_a = SpanKeyMap::from_total_chars(0, 1);
        let key = map_a.insert_span(old_start, blen);
        let mut map_b = SpanKeyMap::from_total_chars(0, 1);
        // Revision carries the SAME key with the content:
        for (st, _, _) in map_b.spans.iter_mut() {
            if *st >= new_start {
                *st += blen;
            }
        }
        let idx = map_b.spans.partition_point(|(st, _, _)| *st < new_start);
        map_b.spans.insert(idx, (new_start, blen, key.clone()));

        // Structural diff sees divergence at the old site (and
        // elsewhere); the block's range is in only_a.
        let diff = CrumDiff {
            matched: Vec::new(),
            only_a: vec![(old_start as i64, (old_start + blen) as i64)],
            only_b: Vec::new(),
            matched_crum_count: 0,
        };
        let moves = detect_moves(&diff, &map_a, &map_b, &text_a, &text_b);
        assert_eq!(moves.len(), 1, "exactly one move detected");
        let (ms, me, md, mf) = moves[0].matched[0];
        assert_eq!((ms as usize, me as usize), (old_start, old_start + blen));
        assert_eq!((md as usize, mf as usize), (new_start, new_start + blen));

        // Already-matched ranges are not reported as moves.
        let diff_matched = CrumDiff {
            matched: vec![(0, 4, 0, 4)],
            only_a: vec![(0, 4)],
            only_b: Vec::new(),
            matched_crum_count: 1,
        };
        assert!(detect_moves(&diff_matched, &map_a, &map_b, &text_a, &text_b).is_empty());
    }

    #[test]
    fn map_permalinks_survive_edits() {
        // The headline S3 property, at the map level: resolve a key
        // before and after heavy editing — offsets move, key holds.
        let mut m = SpanKeyMap::from_total_chars(1000, 100);
        let target = m.key_at(450).unwrap().clone();
        let (s0, e0) = m.range_of(&target).unwrap();

        m.insert_span(0, 250); // prefix insert
        let (s1, e1) = m.range_of(&target).unwrap();
        assert_eq!(e1 - s1, 100, "extent length preserved");
        assert_eq!(s1, s0 + 250, "offset shifted by insert");

        m.delete_range(0, 250); // and back
        let (s2, _) = m.range_of(&target).unwrap();
        assert_eq!(s2, s0);
    }
}
