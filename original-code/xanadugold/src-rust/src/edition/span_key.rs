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
}

impl SpanKeySpace {
    pub fn new() -> Self {
        SpanKeySpace {
            allocated: BTreeSet::new(),
        }
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
            None => SpanKey::first(),
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

#[cfg(test)]
mod tests {
    use super::*;

    /// The live-span extent table: char start + key. Edits shift
    /// `start`s; keys are immutable.
    #[derive(Debug, Default, Clone)]
    struct Extents(Vec<(usize, SpanKey)>);

    #[test]
    fn keys_stable_under_prefix_insert() {
        let mut space = SpanKeySpace::new();
        let mut ext = Extents::default();
        // three spans: "AAAA" "BBBB" "CCCC"
        let k1 = space.allocate_after_all();
        let k2 = space.allocate_after_all();
        let k3 = space.allocate_after_all();
        ext.0 = vec![(0, k1.clone()), (4, k2.clone()), (8, k3.clone())];

        // Insert 3 chars BEFORE everything: offsets shift, keys don't.
        for (start, _) in ext.0.iter_mut() {
            *start += 3;
        }
        let before: Vec<String> = space.iter().map(|k| k.canonical()).collect();

        assert_eq!(before, vec!["1", "2", "3"]);
        assert_eq!(ext.0[0].0, 3);
        assert_eq!(space.key_at(&ext.0, 3).unwrap().canonical(), "1");
        assert_eq!(space.key_at(&ext.0, 7).unwrap().canonical(), "2");
    }

    #[test]
    fn between_allocation_orders_correctly() {
        let mut space = SpanKeySpace::new();
        let a = space.allocate_after_all(); // 1
        let b = space.allocate_after_all(); // 2
        let c = space.allocate_after_all(); // 3

        // Between 1 and 2 (adjacent) → deeper: 1.1
        let m1 = space.allocate_between(&a, &b).unwrap();
        assert_eq!(m1.canonical(), "1.1");
        // Order preserved: 1 < 1.1 < 2 < 3
        assert!(a < m1 && m1 < b && b < c);

        // Between 1.1 and 2 (adjacent at branch 0: 1 vs 2) → deeper under 1: 1.2
        let m2 = space.allocate_between(&m1, &b).unwrap();
        assert!(m1 < m2 && m2 < b);

        // Between 2 and 3 with room: midpoint impossible (2,3 adjacent) → 2.1
        let m3 = space.allocate_between(&b, &c).unwrap();
        assert_eq!(m3.canonical(), "2.1");

        // Wide gap from a deletion: 1,2,3 allocated; retire 2;
        // inserting between 1 and 3 reuses the freed midpoint.
        let mut wide = SpanKeySpace::new();
        let w1 = wide.allocate_after_all(); // 1
        let w2 = wide.allocate_after_all(); // 2
        let w3 = wide.allocate_after_all(); // 3
        assert!(wide.retire(&w2));
        let mid = wide.allocate_between(&w1, &w3).unwrap();
        assert_eq!(mid.canonical(), "2");
        assert!(w1 < mid && mid < w3);
        // Collision: allocate 2 again impossible (mid took it);
        // between 1 and 2(now mid) is adjacent → 1.1
        let inner = wide.allocate_between(&w1, &mid).unwrap();
        assert_eq!(inner.canonical(), "1.1");
        assert!(w1 < inner && inner < mid);
        let _ = (w1, w3);
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
        // The core Gold invariant: N inserts between the same pair
        // produce fresh, ordered keys; earlier keys byte-identical.
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
        // All distinct (BTreeSet size matches); origin key unchanged.
        assert_eq!(space.len(), 52);
        assert_eq!(snapshot_left.canonical(), "1");
        // Strictly increasing sequence of allocated gap keys.
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
}
