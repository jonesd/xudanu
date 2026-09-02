//! FR-40: the link canopy — enfiladic matching for link queries.
//!
//! Gold's link matching never scanned: links lived in the ent
//! tree and queries pruned whole subtrees via OR-ed crum flags
//! (the canopy — see canopy.rs for the Gold-faithful crum tree
//! used by backfollow, and gold-link-model.md §1 for the model).
//! Our links live in a server-side map, so this module builds the
//! same ALGORITHM over our store: a balanced tree over work-id
//! ranges whose internal nodes carry OR-ed link-type flags, and
//! whose leaves hold per-work attachment entries.
//!
//! A query descends from the root and prunes any subtree whose
//! work range does not intersect the queried works OR whose type
//! bits do not intersect the queried types — subtree pruning
//! instead of entry scanning is the essence of enfiladic matching.
//!
//! The index keys on (work, link, end) — NOT positions — so span
//! migration never touches it (an attachment's work does not move
//! under revise_work). It is DERIVED data: rebuilt at restore and
//! after WAL replay, never journaled (same contract as the FR-38
//! license overlay cache).
//!
//! Type ids are not uniformly small (custom types are FR-39
//! definition WORK ids, 1000+), so a dense slot registry maps
//! them to bit positions; beyond BITS_CAPACITY slots, entries
//! degrade to a scan-filter check the caller runs anyway (the
//! canopy may then over-return, never under-return — pruning is
//! conservative).

use std::collections::HashMap;

/// Flag bits per node: 128 (two u64 words) — enough for the five
/// built-ins plus a large custom registry; overflow degrades to
/// conservative over-return.
const WORDS: usize = 2;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct TypeBits([u64; WORDS]);

impl TypeBits {
    pub fn from_slot(slot: usize) -> Self {
        let mut b = TypeBits([0; WORDS]);
        b.set_slot(slot);
        b
    }

    pub fn set_slot(&mut self, slot: usize) {
        if slot < WORDS * 64 {
            self.0[slot / 64] |= 1u64 << (slot % 64);
        }
    }

    pub fn union(&mut self, other: &TypeBits) {
        for i in 0..WORDS {
            self.0[i] |= other.0[i];
        }
    }

    pub fn intersects(&self, other: &TypeBits) -> bool {
        (0..WORDS).any(|i| self.0[i] & other.0[i] != 0)
    }

    pub fn is_empty(&self) -> bool {
        self.0.iter().all(|w| *w == 0)
    }
}

/// Dense slot assignment for type ids (u64): built-ins 1..=7 keep
/// their id as slot; custom type ids (FR-39 definition work ids)
/// get 8.. on first sight, deterministically re-assigned at
/// restore by registration order.
#[derive(Debug, Clone, Default)]
pub struct TypeSlotRegistry {
    slots: HashMap<u64, usize>,
    next_custom: usize,
}

impl TypeSlotRegistry {
    pub fn new() -> Self {
        TypeSlotRegistry {
            slots: HashMap::new(),
            next_custom: 8,
        }
    }

    pub fn slot_for(&mut self, type_id: u64) -> usize {
        if (1..8).contains(&type_id) {
            return type_id as usize;
        }
        if let Some(s) = self.slots.get(&type_id) {
            return *s;
        }
        let s = self.next_custom;
        self.next_custom += 1;
        self.slots.insert(type_id, s);
        s
    }

    pub fn bits_for(&mut self, type_ids: &[u64]) -> TypeBits {
        let mut b = TypeBits::default();
        for t in type_ids {
            b.set_slot(self.slot_for(*t));
        }
        b
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AttachmentEntry {
    pub link_id: u64,
    pub end_name: String,
}

#[derive(Debug, Clone, Default)]
struct Leaf {
    entries: Vec<AttachmentEntry>,
    bits: TypeBits,
}

#[derive(Debug, Clone)]
struct Node {
    /// Inclusive work-id range this subtree covers.
    lo: u64,
    hi: u64,
    bits: TypeBits,
    /// None = internal with children; Some(()) marks leaf band.
    leaf: Option<()>,
    left: Option<usize>,
    right: Option<usize>,
    /// Leaf storage: work -> entries. Present only at leaves.
    leaf_map: HashMap<u64, Leaf>,
}

///
/// The link canopy. Arena-backed binary tree over the u64 work-id
/// space; splits lazily as works are inserted (depth stays O(log)
/// under realistic id spreads; adversarial worst cases degrade to
/// linear descent but never incorrectness).
///
/// Query contract: `query` returns (work, link, end) entries that
/// MAY match — every returned candidate still needs the exact
/// per-link checks (to-spec pairing, home, author) the caller
/// already runs. The canopy may over-return (conservative
/// pruning); it never under-returns.
#[derive(Debug)]
pub struct LinkCanopy {
    nodes: Vec<Node>,
    /// Visited counters for pruning stats (test/demo) — Cell so
    /// queries borrow &self (no per-query clone at the call site).
    pub visited_subtrees: std::sync::atomic::AtomicUsize,
    pub visited_entries: std::sync::atomic::AtomicUsize,
}

impl Clone for LinkCanopy {
    fn clone(&self) -> Self {
        LinkCanopy {
            nodes: self.nodes.clone(),
            visited_subtrees: std::sync::atomic::AtomicUsize::new(0),
            visited_entries: std::sync::atomic::AtomicUsize::new(0),
        }
    }
}

impl Default for LinkCanopy {
    fn default() -> Self {
        Self::new()
    }
}

impl LinkCanopy {
    pub fn new() -> Self {
        let mut c = LinkCanopy {
            nodes: Vec::new(),
            visited_subtrees: std::sync::atomic::AtomicUsize::new(0),
            visited_entries: std::sync::atomic::AtomicUsize::new(0),
        };
        c.nodes.push(Node {
            lo: 0,
            hi: u64::MAX,
            bits: TypeBits::default(),
            leaf: Some(()),
            left: None,
            right: None,
            leaf_map: HashMap::new(),
        });
        c
    }

    fn root(&self) -> usize {
        0
    }

    /// Insert an attachment entry under a work, OR-ing its type
    /// bits up the path.
    pub fn insert(&mut self, work: u64, entry: AttachmentEntry, bits: &TypeBits) {
        self.insert_at(self.root(), work, entry, bits);
    }

    fn insert_at(&mut self, idx: usize, work: u64, entry: AttachmentEntry, bits: &TypeBits) {
        // Lazy split BEFORE landing: a crowded leaf band partitions
        // so deep spreads stay logarithmic.
        if self.nodes[idx].leaf.is_some() {
            self.ensure_split(idx);
        }
        self.nodes[idx].bits.union(bits);
        if self.nodes[idx].leaf.is_some() {
            let node = &mut self.nodes[idx];
            let leaf = node.leaf_map.entry(work).or_default();
            if !leaf.entries.contains(&entry) {
                leaf.entries.push(entry);
            }
            leaf.bits.union(bits);
            return;
        }
        let (l, r) = (
            self.nodes[idx].left.unwrap(),
            self.nodes[idx].right.unwrap(),
        );
        let mid = mid_of(self.nodes[idx].lo, self.nodes[idx].hi);
        if work <= mid {
            self.insert_at(l, work, entry, bits);
        } else {
            self.insert_at(r, work, entry, bits);
        }
    }

    /// Remove an entry; recomputes OR bits up the path (removal is
    /// rarer than insert; recompute-from-children keeps it simple
    /// and correct).
    pub fn remove(&mut self, work: u64, entry: &AttachmentEntry) {
        self.remove_at(self.root(), work, entry);
    }

    fn remove_at(&mut self, idx: usize, work: u64, entry: &AttachmentEntry) {
        let node = &mut self.nodes[idx];
        if node.leaf.is_some() {
            if let Some(leaf) = node.leaf_map.get_mut(&work) {
                leaf.entries.retain(|e| e != entry);
                // bits recompute deferred to the upward pass below
            }
            return;
        }
        let (l, r) = (node.left.unwrap(), node.right.unwrap());
        let mid = mid_of(node.lo, node.hi);
        if work <= mid {
            self.remove_at(l, work, entry);
        } else {
            self.remove_at(r, work, entry);
        }
        // Recompute this node's bits from children + any leaf data.
        let mut bits = TypeBits::default();
        for c in [l, r] {
            bits.union(&self.nodes[c].bits);
        }
        self.nodes[idx].bits = bits;
    }

    /// Leaf bit recompute is not derivable from children (leaves
    /// hold the truth), so removal must fix leaf bits from its
    /// remaining entries — which requires the registry to map
    /// back. Instead of coupling, removal takes the leaf's new
    /// bits explicitly: callers compute them from the link's
    /// remaining types (they know the link).
    pub fn remove_with_bits(
        &mut self,
        work: u64,
        entry: &AttachmentEntry,
        new_leaf_bits: &TypeBits,
    ) {
        self.remove_entry_and_set_bits(self.root(), work, entry, new_leaf_bits);
    }

    fn remove_entry_and_set_bits(
        &mut self,
        idx: usize,
        work: u64,
        entry: &AttachmentEntry,
        new_leaf_bits: &TypeBits,
    ) {
        let node = &mut self.nodes[idx];
        if node.leaf.is_some() {
            if let Some(leaf) = node.leaf_map.get_mut(&work) {
                leaf.entries.retain(|e| e != entry);
                leaf.bits = *new_leaf_bits;
            }
            return;
        }
        let (l, r) = (node.left.unwrap(), node.right.unwrap());
        let mid = mid_of(node.lo, node.hi);
        if work <= mid {
            self.remove_entry_and_set_bits(l, work, entry, new_leaf_bits);
        } else {
            self.remove_entry_and_set_bits(r, work, entry, new_leaf_bits);
        }
        let mut bits = TypeBits::default();
        for c in [l, r] {
            bits.union(&self.nodes[c].bits);
        }
        self.nodes[idx].bits = bits;
    }

    /// Split leaves lazily: called before insert descent so deep
    /// work spreads partition. A leaf holding ≥ SPLIT distinct
    /// works whose band is wider than 1 splits at its midpoint.
    fn ensure_split(&mut self, idx: usize) {
        const SPLIT_AT: usize = 8;
        let (lo, hi, distinct) = {
            let n = &self.nodes[idx];
            (n.lo, n.hi, n.leaf_map.len())
        };
        if distinct < SPLIT_AT || hi - lo < 2 {
            return;
        }
        let mid = mid_of(lo, hi);
        let node = self.nodes[idx].leaf_map.drain().collect::<Vec<_>>();
        let mut left_map = HashMap::new();
        let mut right_map = HashMap::new();
        for (w, leaf) in node {
            if w <= mid {
                left_map.insert(w, leaf);
            } else {
                right_map.insert(w, leaf);
            }
        }
        let l = self.nodes.len();
        self.nodes.push(Node {
            lo,
            hi: mid,
            bits: TypeBits::default(),
            leaf: Some(()),
            left: None,
            right: None,
            leaf_map: left_map,
        });
        let r = self.nodes.len();
        self.nodes.push(Node {
            lo: mid + 1,
            hi,
            bits: TypeBits::default(),
            leaf: Some(()),
            left: None,
            right: None,
            leaf_map: right_map,
        });
        // Children carry their own OR bits (born from their leaf
        // maps) — the parent recomputes from them.
        let l_bits = self.nodes[l].recompute_leaf_bits();
        let r_bits = self.nodes[r].recompute_leaf_bits();
        self.nodes[l].bits = l_bits;
        self.nodes[r].bits = r_bits;
        let mut bits = TypeBits::default();
        bits.union(&l_bits);
        bits.union(&r_bits);
        let n = &mut self.nodes[idx];
        n.leaf = None;
        n.left = Some(l);
        n.right = Some(r);
        n.bits = bits;
    }

    /// Enfiladic query: works-filter (None = all works) and
    /// type-filter (empty bits = all types). Returns candidate
    /// (work, entry) pairs — conservative superset of true
    /// matches. Records pruning stats in visited_*.
    pub fn query(
        &self,
        works: Option<&[u64]>,
        type_bits: &TypeBits,
    ) -> Vec<(u64, AttachmentEntry)> {
        self.visited_subtrees
            .store(0, std::sync::atomic::Ordering::Relaxed);
        self.visited_entries
            .store(0, std::sync::atomic::Ordering::Relaxed);
        let mut out = Vec::new();
        let bits = *type_bits;
        self.query_at(self.root(), works, &bits, &mut out);
        out
    }

    fn query_at(
        &self,
        idx: usize,
        works: Option<&[u64]>,
        bits: &TypeBits,
        out: &mut Vec<(u64, AttachmentEntry)>,
    ) {
        let node = &self.nodes[idx];
        // Prune 1: subtree's work range vs queried works.
        if let Some(ws) = works {
            if !ws.iter().any(|w| *w >= node.lo && *w <= node.hi) {
                return;
            }
        }
        // Prune 2: subtree's OR-ed type bits vs queried types.
        if !bits.is_empty() && !node.bits.intersects(bits) {
            return;
        }
        self.visited_subtrees
            .fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        if node.leaf.is_some() {
            for (w, leaf) in &node.leaf_map {
                if let Some(ws) = works {
                    if !ws.contains(w) {
                        continue;
                    }
                }
                if !bits.is_empty() && !leaf.bits.intersects(bits) {
                    continue;
                }
                self.visited_entries
                    .fetch_add(leaf.entries.len(), std::sync::atomic::Ordering::Relaxed);
                for e in &leaf.entries {
                    out.push((*w, e.clone()));
                }
            }
            return;
        }
        let (l, r) = (node.left.unwrap(), node.right.unwrap());
        self.query_at(l, works, bits, out);
        self.query_at(r, works, bits, out);
    }

    pub fn total_entries(&self) -> usize {
        self.nodes
            .iter()
            .filter(|n| n.leaf.is_some())
            .map(|n| n.leaf_map.values().map(|l| l.entries.len()).sum::<usize>())
            .sum()
    }
}

impl Node {
    fn recompute_leaf_bits(&self) -> TypeBits {
        let mut b = TypeBits::default();
        for leaf in self.leaf_map.values() {
            b.union(&leaf.bits);
        }
        b
    }
}

fn mid_of(lo: u64, hi: u64) -> u64 {
    lo + (hi - lo) / 2
}

#[cfg(test)]
mod tests {
    use super::*;

    fn entry(link: u64, end: &str) -> AttachmentEntry {
        AttachmentEntry {
            link_id: link,
            end_name: end.to_string(),
        }
    }

    #[test]
    fn type_bits_basics() {
        let mut b = TypeBits::default();
        assert!(b.is_empty());
        b.set_slot(5);
        b.set_slot(130); // beyond 128 — ignored (degrades, never wrong)
        assert!(b.intersects(&TypeBits::from_slot(5)));
        assert!(!b.intersects(&TypeBits::from_slot(6)));
        let mut c = TypeBits::from_slot(6);
        c.union(&b);
        assert!(c.intersects(&TypeBits::from_slot(5)));
        assert!(c.intersects(&TypeBits::from_slot(6)));
    }

    #[test]
    fn slot_registry_builtins_and_customs() {
        let mut r = TypeSlotRegistry::new();
        assert_eq!(r.slot_for(3), 3);
        assert_eq!(r.slot_for(1004), 8);
        assert_eq!(r.slot_for(1004), 8);
        assert_eq!(r.slot_for(1005), 9);
        let bits = r.bits_for(&[1, 1004]);
        assert!(bits.intersects(&TypeBits::from_slot(1)));
        assert!(bits.intersects(&TypeBits::from_slot(8)));
        assert!(!bits.intersects(&TypeBits::from_slot(2)));
    }

    #[test]
    fn insert_query_roundtrip_and_work_filter() {
        let mut c = LinkCanopy::new();
        c.insert(10, entry(1, "LeftEnd"), &TypeBits::from_slot(4));
        c.insert(20, entry(1, "RightEnd"), &TypeBits::from_slot(4));
        c.insert(20, entry(2, "LeftEnd"), &TypeBits::from_slot(3));

        let all = c.query(None, &TypeBits::default());
        assert_eq!(all.len(), 3);

        let from10 = c.query(Some(&[10]), &TypeBits::default());
        assert_eq!(from10.len(), 1);
        assert_eq!(from10[0].1.link_id, 1);

        let both20 = c.query(Some(&[20]), &TypeBits::default());
        assert_eq!(both20.len(), 2);
    }

    #[test]
    fn type_pruning_skips_subtrees() {
        let mut c = LinkCanopy::new();
        // Work 10 region: only Quotation(4). Work 20 region: only
        // Disagreement(3).
        c.insert(10, entry(1, "LeftEnd"), &TypeBits::from_slot(4));
        c.insert(20, entry(2, "LeftEnd"), &TypeBits::from_slot(3));

        let q4 = c.query(None, &TypeBits::from_slot(4));
        assert_eq!(q4.len(), 1);
        assert_eq!(q4[0].1.link_id, 1);

        let q3 = c.query(None, &TypeBits::from_slot(3));
        assert_eq!(q3.len(), 1);
        assert_eq!(q3[0].1.link_id, 2);
    }

    #[test]
    fn removal_recomputes_bits() {
        let mut c = LinkCanopy::new();
        let bits43 = {
            let mut b = TypeBits::from_slot(4);
            b.union(&TypeBits::from_slot(3));
            b
        };
        c.insert(10, entry(1, "LeftEnd"), &bits43);
        c.insert(10, entry(2, "LeftEnd"), &TypeBits::from_slot(3));
        // Remove entry 1 (which carried the only type-4 bit at
        // work 10): leaf's remaining bits are type-3 only.
        let mut r = TypeSlotRegistry::new();
        let remaining = r.bits_for(&[3]);
        c.remove_with_bits(10, &entry(1, "LeftEnd"), &remaining);
        assert_eq!(c.query(None, &TypeBits::from_slot(4)).len(), 0);
        assert_eq!(c.query(None, &TypeBits::from_slot(3)).len(), 1);
    }

    #[test]
    fn lazy_splitting_keeps_queries_correct() {
        let mut c = LinkCanopy::new();
        let mut r = TypeSlotRegistry::new();
        for w in 0..40u64 {
            let bits = r.bits_for(&[(w % 5) + 1]);
            c.insert(1000 + w * 7, entry(w, "LeftEnd"), &bits);
        }
        assert!(c.nodes.len() > 1, "splitting must have happened");
        let all = c.query(None, &TypeBits::default());
        assert_eq!(all.len(), 40);
        // Each type query returns exactly its eighth.
        for t in 1..=5u64 {
            let q = c.query(None, &r.bits_for(&[t]));
            assert_eq!(q.len(), 8, "type {}", t);
        }
    }

    #[test]
    fn pruning_stats_show_skipping() {
        let mut c = LinkCanopy::new();
        let mut r = TypeSlotRegistry::new();
        for w in 0..200u64 {
            c.insert(w, entry(w, "L"), &r.bits_for(&[(w % 50) + 8]));
        }
        // A rare-type query must visit far fewer entries than the
        // total (200). With lazy splits the halves partition.
        let q = c.query(None, &r.bits_for(&[8]));
        let visited = c.visited_entries.load(std::sync::atomic::Ordering::Relaxed);
        assert_eq!(q.len(), 4); // works 0, 50, 100, 150
        assert!(
            visited < 200,
            "pruning must skip entries: visited {} of 200",
            visited
        );
    }

    #[test]
    fn conservative_over_return_is_allowed_never_under() {
        // Slot overflow (>128 custom types) degrades: the canopy
        // may return entries whose bits were not representable.
        let mut r = TypeSlotRegistry::new();
        let mut c = LinkCanopy::new();
        for i in 0..200u64 {
            let bits = r.bits_for(&[2000 + i]);
            c.insert(i, entry(i, "L"), &bits);
        }
        // All 200 custom types; slots 8..208 — most beyond 128.
        // Querying one specific type may over-return others, but
        // MUST include the true match (work 57 <-> type 2057).
        let q = c.query(None, &r.bits_for(&[2057]));
        assert!(
            q.iter().any(|(w, e)| *w == 57 && e.link_id == 57),
            "the true match must always be returned"
        );
    }
}
