//! FR-51 Phase 1: the lattice document store.
//!
//! Units are immutable span-records addressed by Sequences allocated
//! in gaps between neighbors (deepening allocation — the address IS
//! the order; no anchors, no timestamps). Deletes are region
//! tombstones carrying the deleter's causal context: a tombstone
//! kills a unit iff the unit's address falls in the region AND the
//! unit's dot is in the tombstone's context (the OR-set rule
//! generalized over the Sequence region algebra). Merge is union of
//! units and tombstones — commutative, associative, idempotent by
//! construction, so replicas converge regardless of delivery order.

use super::sequence::{Sequence, SequenceRegion};
use std::collections::{HashMap, HashSet};

/// Globally-unique unit identity: (server, counter). Two units with
/// the same dot are the same unit (idempotent merge).
pub type Dot = (u64, u64);

/// The live-set index: a weight-balanced BST keyed by unit address,
/// carrying subtree char totals — the enfilade core (order-statistics
/// over the live view). Gives O(log L): offset → unit (with prefix
/// sum), address neighbors, range collection, and in-order walk —
/// replacing the per-operation live-set sort that made keystrokes
/// linear (FR-51 Phase 2 gate).
mod index {
    use super::super::sequence::Sequence;
    use super::Dot;
    use std::cmp::Ordering;

    const BIAS: usize = 3;

    #[derive(Clone, Debug)]
    struct Node {
        addr: Sequence,
        dot: Dot,
        len: usize,
        l: Option<usize>,
        r: Option<usize>,
        w: usize,
        total: usize,
    }

    #[derive(Default, Clone, Debug)]
    pub(crate) struct LiveIndex {
        nodes: Vec<Node>,
        free: Vec<usize>,
        root: Option<usize>,
    }

    impl LiveIndex {
        pub fn new() -> Self {
            LiveIndex::default()
        }

        fn w(&self, n: Option<usize>) -> usize {
            n.map(|i| self.nodes[i].w).unwrap_or(0)
        }

        fn total(&self, n: Option<usize>) -> usize {
            n.map(|i| self.nodes[i].total).unwrap_or(0)
        }

        fn fix(&mut self, i: usize) {
            self.nodes[i].w = 1 + self.w(self.nodes[i].l) + self.w(self.nodes[i].r);
            self.nodes[i].total =
                self.nodes[i].len + self.total(self.nodes[i].l) + self.total(self.nodes[i].r);
        }

        fn rot_l(&mut self, x: usize) -> usize {
            let y = self.nodes[x].r.unwrap();
            self.nodes[x].r = self.nodes[y].l;
            self.nodes[y].l = Some(x);
            self.fix(x);
            self.fix(y);
            y
        }

        fn rot_r(&mut self, x: usize) -> usize {
            let y = self.nodes[x].l.unwrap();
            self.nodes[x].l = self.nodes[y].r;
            self.nodes[y].r = Some(x);
            self.fix(x);
            self.fix(y);
            y
        }

        fn balance(&mut self, i: usize) -> usize {
            let (lw, rw) = (self.w(self.nodes[i].l), self.w(self.nodes[i].r));
            if lw > BIAS * (rw + 1) {
                let l = self.nodes[i].l.unwrap();
                if self.w(self.nodes[l].r) > self.w(self.nodes[l].l) {
                    self.nodes[i].l = Some(self.rot_l(l));
                }
                return self.rot_r(i);
            }
            if rw > BIAS * (lw + 1) {
                let r = self.nodes[i].r.unwrap();
                if self.w(self.nodes[r].l) > self.w(self.nodes[r].r) {
                    self.nodes[i].r = Some(self.rot_r(r));
                }
                return self.rot_l(i);
            }
            i
        }

        fn alloc(&mut self, addr: Sequence, dot: Dot, len: usize) -> usize {
            let node = Node {
                addr,
                dot,
                len,
                l: None,
                r: None,
                w: 1,
                total: len,
            };
            if let Some(i) = self.free.pop() {
                self.nodes[i] = node;
                i
            } else {
                self.nodes.push(node);
                self.nodes.len() - 1
            }
        }

        fn insert_rec(&mut self, i: Option<usize>, addr: Sequence, dot: Dot, len: usize) -> usize {
            match i {
                None => self.alloc(addr, dot, len),
                Some(i) => {
                    match addr.compare_to(&self.nodes[i].addr) {
                        Ordering::Less => {
                            let c = self.insert_rec(self.nodes[i].l, addr, dot, len);
                            self.nodes[i].l = Some(c);
                        }
                        Ordering::Greater => {
                            let c = self.insert_rec(self.nodes[i].r, addr, dot, len);
                            self.nodes[i].r = Some(c);
                        }
                        Ordering::Equal => {
                            self.nodes[i].dot = dot;
                            self.nodes[i].len = len;
                            self.fix(i);
                            return i;
                        }
                    }
                    self.fix(i);
                    self.balance(i)
                }
            }
        }

        fn remove_min(&mut self, i: usize) -> (Option<usize>, Option<usize>) {
            // Returns (replacement_subtree_root, detached_min_node).
            match self.nodes[i].l {
                None => (self.nodes[i].r, Some(i)),
                Some(l) => {
                    let (new_l, m) = self.remove_min(l);
                    self.nodes[i].l = new_l;
                    self.fix(i);
                    (Some(self.balance(i)), m)
                }
            }
        }

        fn remove_rec(&mut self, i: Option<usize>, addr: &Sequence) -> (Option<usize>, bool) {
            let Some(i) = i else {
                return (None, false);
            };
            match addr.compare_to(&self.nodes[i].addr) {
                Ordering::Less => {
                    let (c, removed) = self.remove_rec(self.nodes[i].l, addr);
                    self.nodes[i].l = c;
                    if removed {
                        self.fix(i);
                        return (Some(self.balance(i)), true);
                    }
                    (Some(i), false)
                }
                Ordering::Greater => {
                    let (c, removed) = self.remove_rec(self.nodes[i].r, addr);
                    self.nodes[i].r = c;
                    if removed {
                        self.fix(i);
                        return (Some(self.balance(i)), true);
                    }
                    (Some(i), false)
                }
                Ordering::Equal => match (self.nodes[i].l, self.nodes[i].r) {
                    (None, r) => {
                        self.free.push(i);
                        (r, true)
                    }
                    (l, None) => {
                        self.free.push(i);
                        (l, true)
                    }
                    (Some(_), Some(_)) => {
                        let (new_r, m) = self.remove_min(self.nodes[i].r.unwrap());
                        let m = m.unwrap();
                        self.nodes[i].addr = self.nodes[m].addr.clone();
                        self.nodes[i].dot = self.nodes[m].dot;
                        self.nodes[i].len = self.nodes[m].len;
                        self.nodes[i].r = new_r;
                        self.free.push(m);
                        self.fix(i);
                        (Some(self.balance(i)), true)
                    }
                },
            }
        }

        pub fn upsert(&mut self, addr: &Sequence, dot: Dot, len: usize) {
            let root = self.insert_rec(self.root, addr.clone(), dot, len);
            self.root = Some(root);
        }

        pub fn remove_addr(&mut self, addr: &Sequence) -> bool {
            let (root, removed) = self.remove_rec(self.root, addr);
            self.root = root;
            removed
        }

        pub fn contains_addr(&self, addr: &Sequence) -> bool {
            self.dot_at(addr).is_some()
        }

        pub fn dot_at(&self, addr: &Sequence) -> Option<Dot> {
            let mut i = self.root;
            while let Some(n) = i {
                match addr.compare_to(&self.nodes[n].addr) {
                    Ordering::Less => i = self.nodes[n].l,
                    Ordering::Greater => i = self.nodes[n].r,
                    Ordering::Equal => return Some(self.nodes[n].dot),
                }
            }
            None
        }

        /// Offset → (address, dot, chars strictly before the unit,
        /// unit char length). O(log L).
        pub fn find_by_offset(&self, offset: usize) -> Option<(Sequence, Dot, usize, usize)> {
            let mut i = self.root?;
            let mut off = offset;
            let mut before = 0usize;
            loop {
                let lt = self.total(self.nodes[i].l);
                if off < lt {
                    i = self.nodes[i].l.unwrap();
                    continue;
                }
                let local = off - lt;
                if local < self.nodes[i].len {
                    let n = &self.nodes[i];
                    return Some((n.addr.clone(), n.dot, before + lt, n.len));
                }
                before += lt + self.nodes[i].len;
                off = local - self.nodes[i].len;
                i = self.nodes[i].r?;
            }
        }

        /// (predecessor, successor) addresses around `addr` (exclusive).
        pub fn neighbors(&self, addr: &Sequence) -> (Option<Sequence>, Option<Sequence>) {
            let mut pred = None;
            let mut succ = None;
            let mut i = self.root;
            while let Some(n) = i {
                match addr.compare_to(&self.nodes[n].addr) {
                    Ordering::Less => {
                        succ = Some(self.nodes[n].addr.clone());
                        i = self.nodes[n].l;
                    }
                    Ordering::Greater => {
                        pred = Some(self.nodes[n].addr.clone());
                        i = self.nodes[n].r;
                    }
                    Ordering::Equal => {
                        pred = self.nodes[n].l.map(|l| self.rightmost(l)).or(pred);
                        succ = self.nodes[n].r.map(|r| self.leftmost(r)).or(succ);
                        break;
                    }
                }
            }
            (pred, succ)
        }

        fn leftmost(&self, mut i: usize) -> Sequence {
            while let Some(l) = self.nodes[i].l {
                i = l;
            }
            self.nodes[i].addr.clone()
        }

        fn rightmost(&self, mut i: usize) -> Sequence {
            while let Some(r) = self.nodes[i].r {
                i = r;
            }
            self.nodes[i].addr.clone()
        }

        pub fn last(&self) -> Option<(Sequence, Dot)> {
            self.root.map(|r| {
                let a = self.rightmost(r);
                let d = self.dot_of_max(r);
                (a, d)
            })
        }

        fn dot_of_max(&self, mut i: usize) -> Dot {
            while let Some(r) = self.nodes[i].r {
                i = r;
            }
            self.nodes[i].dot
        }

        /// Live units with address in [lo, hi), in order.
        pub fn range_collect(&self, lo: &Sequence, hi: &Sequence) -> Vec<(Sequence, Dot)> {
            let mut out = Vec::new();
            self.range_walk(self.root, lo, hi, &mut out);
            out
        }

        fn range_walk(
            &self,
            i: Option<usize>,
            lo: &Sequence,
            hi: &Sequence,
            out: &mut Vec<(Sequence, Dot)>,
        ) {
            let Some(n) = i else { return };
            use std::cmp::Ordering::*;
            match self.nodes[n].addr.compare_to(lo) {
                Less => {
                    self.range_walk(self.nodes[n].r, lo, hi, out);
                }
                _ => {
                    self.range_walk(self.nodes[n].l, lo, hi, out);
                    if self.nodes[n].addr.compare_to(hi) == Less {
                        out.push((self.nodes[n].addr.clone(), self.nodes[n].dot));
                        self.range_walk(self.nodes[n].r, lo, hi, out);
                    }
                }
            }
        }

        /// Live units with address >= lo, in order.
        pub fn above_collect(&self, lo: &Sequence) -> Vec<(Sequence, Dot)> {
            let mut out = Vec::new();
            self.above_walk(self.root, lo, &mut out);
            out
        }

        fn above_walk(&self, i: Option<usize>, lo: &Sequence, out: &mut Vec<(Sequence, Dot)>) {
            let Some(n) = i else { return };
            use std::cmp::Ordering::*;
            match self.nodes[n].addr.compare_to(lo) {
                Less => self.above_walk(self.nodes[n].r, lo, out),
                _ => {
                    self.above_walk(self.nodes[n].l, lo, out);
                    out.push((self.nodes[n].addr.clone(), self.nodes[n].dot));
                    self.above_walk(self.nodes[n].r, lo, out);
                }
            }
        }

        pub fn in_order(&self) -> Vec<(Sequence, Dot)> {
            let mut out = Vec::new();
            self.walk(self.root, &mut out);
            out
        }

        fn walk(&self, i: Option<usize>, out: &mut Vec<(Sequence, Dot)>) {
            let Some(n) = i else { return };
            self.walk(self.nodes[n].l, out);
            out.push((self.nodes[n].addr.clone(), self.nodes[n].dot));
            self.walk(self.nodes[n].r, out);
        }

        pub fn clear(&mut self) {
            self.nodes.clear();
            self.free.clear();
            self.root = None;
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct LatticeUnit {
    pub address: Sequence,
    pub content: String,
    pub author: u64,
    pub dot: Dot,
    /// Split provenance: (parent dot, start, end) — char range within
    /// the parent unit. Parts derived from the same parent+range get
    /// the SAME deterministic dot, so concurrent identical splits
    /// coalesce in merge (P1-1). ROOT-ANCHORED: the dot is the
    /// original root unit's dot (never a derived one) and the range
    /// is char offsets in the root's content — two replicas that
    /// split the same root at different points still produce parts
    /// whose ranges are comparable, so culls trim them and identical
    /// sub-ranges coalesce.
    pub lineage: Option<(Dot, usize, usize)>,
    /// For fresh (non-part) inserts: the root unit and root offset of
    /// the split boundary the insert landed on. The address is
    /// root-relative ([.., offset, server, counter]) so it is a
    /// deterministic function of POSITION — independent of which
    /// replica merges first.
    pub anchor: Option<(Dot, usize)>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct RegionTombstone {
    pub region: SequenceRegion,
    /// Dots the deleter knew when deleting: a unit dies iff its dot
    /// is here AND its address is in the region. Units the deleter
    /// never saw survive.
    pub context: HashSet<Dot>,
    /// Parent-range culls: each killed unit contributes (its lineage
    /// parent or own dot, its char range). Concurrently-derived parts
    /// of the same parent are trimmed/contained by these — the
    /// P1-1 convergence rule.
    pub culls: Vec<(Dot, usize, usize)>,
}

fn content_len_of(u: &LatticeUnit) -> usize {
    u.content.chars().count()
}

use index::LiveIndex;

#[derive(Debug, Clone, Default)]
pub struct LatticeDoc {
    server: u64,
    counter: u64,
    units: HashMap<Dot, LatticeUnit>,
    tombstones: Vec<RegionTombstone>,
    index: LiveIndex,
}

impl LatticeDoc {
    pub fn new(server: u64) -> Self {
        LatticeDoc {
            server,
            counter: 0,
            units: HashMap::new(),
            tombstones: Vec::new(),
            index: LiveIndex::new(),
        }
    }

    fn next_dot(&mut self) -> Dot {
        self.counter += 1;
        (self.server, self.counter)
    }

    /// Allocate an address strictly between `prev` and `next`
    /// (exclusive bounds; None = unbounded on that side). The rule:
    /// extend prev with [server, counter] — server-scoped so
    /// concurrent replicas minting in the same gap never collide,
    /// and prefix-extension keeps the new address > prev. When that
    /// would not land below `next` (a dense gap), deepen one more
    /// level anchored on the common prefix instead.
    #[allow(clippy::same_item_push)]
    pub fn allocate_between(&self, prev: Option<&Sequence>, next: Option<&Sequence>) -> Sequence {
        let less = |a: &Sequence, b: &Sequence| a.compare_to(b) == std::cmp::Ordering::Less;
        let candidate = match prev {
            Some(p) => p.append_pair(self.server as i64, self.counter as i64 + 1),
            None => Sequence::from_numbers(vec![1, self.server as i64, self.counter as i64 + 1]),
        };
        if let Some(n) = next {
            if !less(&candidate, n) {
                // Dense gap — the widening invariant: deepen below the
                // anchor with zero-prefixes until strictly below next.
                // Zeros are never minted by allocation, so a 0-chain
                // sorts below next's first nonzero element at that
                // depth — the general interior rule; never renumber.
                let anchor: Vec<i64> = match prev {
                    Some(p) => p.numbers().to_vec(),
                    None => vec![*n.numbers().first().unwrap_or(&1)],
                };
                let mut zeros = 0usize;
                loop {
                    let mut nums = anchor.clone();
                    for _ in 0..zeros {
                        nums.push(0);
                    }
                    nums.push(self.server as i64);
                    nums.push(self.counter as i64 + 1);
                    let interior = Sequence::from_numbers(nums);
                    if less(&interior, n) && prev.map(|p| less(p, &interior)).unwrap_or(true) {
                        debug_assert!(zeros <= n.numbers().len() + 2, "interior depth runaway");
                        return interior;
                    }
                    zeros += 1;
                }
            }
        }
        candidate
    }

    /// Insert `content` between the units at the given live-set
    /// neighbor dots (None = before first / after last). Classic
    /// gap allocation — the doc-local, pre-merge path.
    pub fn insert_between(
        &mut self,
        prev: Option<&Sequence>,
        next: Option<&Sequence>,
        content: impl Into<String>,
        author: u64,
    ) -> Dot {
        self.insert_at(prev, next, content, author, None)
    }

    /// Insert with a root-relative anchor (P1-2): the split boundary
    /// identified the root unit and the offset within it, so the
    /// address is [root.., offset, server, counter] — a deterministic
    /// function of position, not of merge order. Concurrent inserts
    /// at the same offset order by (server, counter).
    pub fn insert_at(
        &mut self,
        prev: Option<&Sequence>,
        next: Option<&Sequence>,
        content: impl Into<String>,
        author: u64,
        anchor: Option<(Dot, usize)>,
    ) -> Dot {
        let dot = self.next_dot();
        self.insert_at_with_dot(prev, next, content, author, anchor, dot)
    }

    /// Insert with an explicit dot — the multi-writer path (Phase 3):
    /// the session's author id and its own counter mint the identity.
    /// The address suffix IS the dot, so concurrent inserts at one
    /// anchor order deterministically by (author, counter) regardless
    /// of which replica applies them first.
    pub fn insert_at_with_dot(
        &mut self,
        prev: Option<&Sequence>,
        next: Option<&Sequence>,
        content: impl Into<String>,
        author: u64,
        anchor: Option<(Dot, usize)>,
        dot: Dot,
    ) -> Dot {
        if dot.0 == self.server {
            self.counter = self.counter.max(dot.1);
        }
        let address = match anchor.and_then(|(rd, o)| self.units.get(&rd).map(|ru| (ru, o))) {
            Some((ru, offset)) => {
                let mut nums = ru.address.numbers().to_vec();
                // The doubled offset keys inserts strictly between
                // parts ending at `offset` ([root.., s, offset]) and
                // parts starting at it ([root.., offset, e]) — an
                // author id never collides with a range end.
                nums.push(offset as i64);
                nums.push(offset as i64);
                nums.push(dot.0 as i64);
                nums.push(dot.1 as i64);
                Sequence::from_numbers(nums)
            }
            None => self.allocate_between(prev, next),
        };
        self.units.insert(
            dot,
            LatticeUnit {
                address: address.clone(),
                content: content.into(),
                author,
                dot,
                lineage: None,
                anchor,
            },
        );
        self.index
            .upsert(&address, dot, content_len_of(&self.units[&dot]));
        dot
    }

    /// The live units in address order (index walk).
    pub fn live(&self) -> Vec<&LatticeUnit> {
        self.index
            .in_order()
            .into_iter()
            .filter_map(|(_, dot)| self.units.get(&dot))
            .collect()
    }

    fn is_dead(&self, unit: &LatticeUnit) -> bool {
        !self.index.contains_addr(&unit.address)
    }

    /// Death by tombstone scan (used to rebuild the index after a
    /// merge unions in units and tombstones that may cross-kill).
    fn dead_by_scan(&self, unit: &LatticeUnit) -> bool {
        self.tombstones
            .iter()
            .any(|t| t.context.contains(&unit.dot) && t.region.contains_sequence(&unit.address))
    }

    fn rebuild_index(&mut self) {
        self.index.clear();
        let entries: Vec<(Sequence, Dot, usize)> = self
            .units
            .values()
            .filter(|u| !self.dead_by_scan(u))
            .map(|u| (u.address.clone(), u.dot, u.content.chars().count()))
            .collect();
        for (addr, dot, len) in entries {
            self.index.upsert(&addr, dot, len);
        }
    }

    /// Delete the units whose addresses fall in [start, stop)
    /// relative to the CURRENT live view — the tombstone carries this
    /// replica's knowledge (the dots of the live units in range), so
    /// concurrent unseen inserts survive.
    pub fn delete_range(&mut self, start: &Sequence, stop: &Sequence) {
        let region = SequenceRegion::interval(start.clone(), stop.clone());
        let hits = self.index.range_collect(start, stop);
        if hits.is_empty() {
            return;
        }
        let mut context = HashSet::new();
        let mut culls = Vec::new();
        let mut addrs = Vec::new();
        for (addr, dot) in &hits {
            let Some(u) = self.units.get(dot) else {
                continue;
            };
            context.insert(*dot);
            let (parent, s, e) = u.lineage.unwrap_or((u.dot, 0, u.content.chars().count()));
            culls.push((parent, s, e));
            addrs.push(addr.clone());
        }
        self.tombstones.push(RegionTombstone {
            region,
            context,
            culls,
        });
        for addr in addrs {
            self.index.remove_addr(&addr);
        }
    }

    /// Render the live view (normalizes first — cull trimming is
    /// part of the view, deterministic from state).
    /// Debug view: (address numbers, content, dot, lineage, anchor,
    /// dead) per unit, in address order.
    #[allow(clippy::type_complexity)]
    pub fn debug_units(
        &self,
    ) -> Vec<(
        Vec<i64>,
        String,
        Dot,
        Option<(Dot, usize, usize)>,
        Option<(Dot, usize)>,
        bool,
    )> {
        let mut units: Vec<_> = self
            .units
            .values()
            .map(|u| {
                (
                    u.address.numbers().to_vec(),
                    u.content.clone(),
                    u.dot,
                    u.lineage,
                    u.anchor,
                    self.is_dead(u),
                )
            })
            .collect();
        units.sort_by(|a, b| {
            self.units
                .get(&a.2)
                .unwrap()
                .address
                .compare_to(&self.units.get(&b.2).unwrap().address)
        });
        units
    }

    pub fn render(&mut self) -> String {
        self.normalize();
        let mut out = String::new();
        for u in self.live() {
            out.push_str(&u.content);
        }
        out
    }

    /// The lattice join: union of units (same dot = same unit,
    /// idempotent) and union of tombstones. Order-independent by
    /// construction.
    pub fn merge(&mut self, other: &LatticeDoc) {
        for (dot, unit) in &other.units {
            self.units.entry(*dot).or_insert_with(|| unit.clone());
        }
        self.tombstones.extend(other.tombstones.iter().cloned());
        self.counter = self.counter.max(other.counter_of(self.server));
        self.rebuild_index();
    }

    /// Tombstone one unit by dot (the split operation's primitive).
    /// Context-only: a split replaces the unit with parts, it deletes
    /// no content — recording a cull here would kill the parts (their
    /// lineage points at this unit). Culls belong to deletes only.
    pub fn tombstone_dot(&mut self, dot: Dot) {
        let Some(unit) = self.units.get(&dot) else {
            return;
        };
        let mut context = HashSet::new();
        context.insert(dot);
        self.tombstones.push(RegionTombstone {
            region: SequenceRegion::singleton(unit.address.clone()),
            context,
            culls: vec![],
        });
        self.index.remove_addr(&unit.address);
    }

    /// Public range delete (the simulator adapter's boundary form).
    pub fn delete_range_public(&mut self, start: &Sequence, stop: &Sequence) {
        self.delete_range(start, stop);
    }

    /// Multi-writer delete (Phase 3): the session's view contained
    /// exactly `seen` live units (dot + root range) between the
    /// boundary addresses. The tombstone kills those dots (OR-set
    /// rule: concurrent unseen content in the region survives) and
    /// the culls trim concurrently-derived parts of the same roots at
    /// normalize. Correct even when the shared doc split those units
    /// differently — culls carry the intent, dots the context.
    pub fn delete_seen_range(
        &mut self,
        start: &Sequence,
        end: &Sequence,
        seen: &[(Dot, (Dot, usize, usize))],
    ) {
        if seen.is_empty() {
            return;
        }
        let region = SequenceRegion::interval(start.clone(), end.clone());
        let context: HashSet<Dot> = seen.iter().map(|(d, _)| *d).collect();
        let culls: Vec<(Dot, usize, usize)> = seen.iter().map(|(_, r)| *r).collect();
        self.tombstones.push(RegionTombstone {
            region,
            context,
            culls,
        });
        let addrs: Vec<Sequence> = seen
            .iter()
            .filter_map(|(d, _)| self.units.get(d).map(|u| u.address.clone()))
            .collect();
        for addr in addrs {
            self.index.remove_addr(&addr);
        }
    }

    /// Live units with address in [lo, hi), as (dot, root-range) —
    /// the session's seen-set for a multi-writer delete.
    pub fn live_dots_between(
        &self,
        lo: &Sequence,
        hi: &Sequence,
    ) -> Vec<(Dot, (Dot, usize, usize))> {
        self.index
            .range_collect(lo, hi)
            .into_iter()
            .filter_map(|(_, dot)| {
                let u = self.units.get(&dot)?;
                let range = u.lineage.unwrap_or((dot, 0, u.content.chars().count()));
                Some((dot, range))
            })
            .collect()
    }

    /// Live units with address >= lo, as (dot, root-range).
    pub fn live_dots_above(&self, lo: &Sequence) -> Vec<(Dot, (Dot, usize, usize))> {
        self.index
            .above_collect(lo)
            .into_iter()
            .filter_map(|(_, dot)| {
                let u = self.units.get(&dot)?;
                let range = u.lineage.unwrap_or((dot, 0, u.content.chars().count()));
                Some((dot, range))
            })
            .collect()
    }

    /// Multi-writer delete of everything from `start` to the end, as
    /// seen by the session (`seen` = its live units there).
    pub fn delete_seen_above(&mut self, start: &Sequence, seen: &[(Dot, (Dot, usize, usize))]) {
        if seen.is_empty() {
            return;
        }
        let region = SequenceRegion::above(start.clone(), true);
        let context: HashSet<Dot> = seen.iter().map(|(d, _)| *d).collect();
        let culls: Vec<(Dot, usize, usize)> = seen.iter().map(|(_, r)| *r).collect();
        self.tombstones.push(RegionTombstone {
            region,
            context,
            culls,
        });
        let addrs: Vec<Sequence> = seen
            .iter()
            .filter_map(|(d, _)| self.units.get(d).map(|u| u.address.clone()))
            .collect();
        for addr in addrs {
            self.index.remove_addr(&addr);
        }
    }

    /// Ensure no LIVE part of root `root` straddles char offset `o`:
    /// split the covering part so an insert anchored at (root, o)
    /// orders correctly between its neighbors. The straddler is
    /// found by address probe ([root.., o] sorts after any part
    /// starting before o), so this is O(log L) per level.
    pub fn ensure_root_boundary(&mut self, root: Dot, o: usize) {
        let Some(ru) = self.units.get(&root) else {
            return;
        };
        let mut probe = ru.address.numbers().to_vec();
        probe.push(o as i64);
        let probe = Sequence::from_numbers(probe);
        let Some(pred_addr) = self.index.neighbors(&probe).0 else {
            return;
        };
        let Some(dot) = self.index.dot_at(&pred_addr) else {
            return;
        };
        let Some(u) = self.units.get(&dot) else {
            return;
        };
        let (rd, rs, re) = u.lineage.unwrap_or((dot, 0, u.content.chars().count()));
        if rd == root && rs <= o && o < re && rs < re {
            self.split_unit(dot, o - rs);
        }
    }

    /// Memory telemetry: (units, tombstones, total content bytes,
    /// live content bytes).
    pub fn memory_estimate(&self) -> (usize, usize, usize, usize) {
        let mut total = 0usize;
        let mut live = 0usize;
        for u in self.units.values() {
            let b = u.content.len();
            total += b;
            if self.index.contains_addr(&u.address) {
                live += b;
            }
        }
        (self.units.len(), self.tombstones.len(), total, live)
    }

    /// Is the unit with this dot currently live?
    pub fn is_live(&self, dot: Dot) -> bool {
        self.units
            .get(&dot)
            .map(|u| self.index.contains_addr(&u.address))
            .unwrap_or(false)
    }

    /// Delete from `start` to the end of the document.
    pub fn delete_to_end(&mut self, start: &Sequence) {
        let region = SequenceRegion::above(start.clone(), true);
        let hit = self.index.above_collect(start);
        if hit.is_empty() {
            return;
        }
        let mut context = std::collections::HashSet::new();
        let mut culls: Vec<(Dot, usize, usize)> = Vec::new();
        let mut addrs = Vec::new();
        for (addr, dot) in &hit {
            let Some(u) = self.units.get(dot) else {
                continue;
            };
            context.insert(*dot);
            let (parent, s, e) = u.lineage.unwrap_or((u.dot, 0, u.content.chars().count()));
            culls.push((parent, s, e));
            addrs.push(addr.clone());
        }
        for addr in addrs {
            self.index.remove_addr(&addr);
        }
        self.tombstones.push(RegionTombstone {
            region,
            context,
            culls,
        });
    }

    /// Nudge the counter (test scaffolding for deterministic dots
    /// after cloning a shared base).
    pub fn set_counter_hint(&mut self, minimum: u64) {
        self.counter = self.counter.max(minimum);
    }

    /// Seed a pre-shared unit (bootstrap base for split-brain
    /// replicas: same dot on both sides, merge is a no-op).
    pub fn seed_shared_unit(
        &mut self,
        address: Sequence,
        content: impl Into<String>,
        author: u64,
        dot: Dot,
    ) {
        self.counter = self.counter.max(dot.1);
        self.units.insert(
            dot,
            LatticeUnit {
                address: address.clone(),
                content: content.into(),
                author,
                dot,
                lineage: None,
                anchor: None,
            },
        );
        self.index
            .upsert(&address, dot, content_len_of(&self.units[&dot]));
    }

    /// Deterministic split-part dot: derived from (parent, range) so
    /// concurrent identical splits mint the SAME dot and coalesce in
    /// merge. The high bit marks derivation; real counters stay small.
    pub fn derived_dot(parent: Dot, start: usize, end: usize) -> Dot {
        let mut x = parent.1.wrapping_mul(0x9E3779B97F4A7C15) ^ ((start as u64) << 32) ^ end as u64;
        x ^= x >> 30;
        x = x.wrapping_mul(0xBF58476D1CE4E5B9);
        x ^= x >> 27;
        x = x.wrapping_mul(0x94D049BB133111EB);
        x ^= x >> 31;
        (parent.0, x | (1u64 << 63))
    }

    /// Insert a split part with deterministic lineage identity
    /// (P1-1). `root`/`range` are ROOT-ANCHORED: the original unit's
    /// dot and the part's char range within the root's content. The
    /// address is the root's address extended with [start, end] — a
    /// deterministic function of the part's position, so parts
    /// coalesce bitwise across merge orders (no local allocation).
    pub fn insert_part(
        &mut self,
        content: impl Into<String>,
        root: Dot,
        range: (usize, usize),
    ) -> Dot {
        let address = match self.units.get(&root) {
            Some(ru) => {
                let mut nums = ru.address.numbers().to_vec();
                nums.push(range.0 as i64);
                nums.push(range.1 as i64);
                Sequence::from_numbers(nums)
            }
            None => Sequence::from_numbers(vec![1, root.0 as i64, root.1 as i64]),
        };
        let dot = Self::derived_dot(root, range.0, range.1);
        self.units.insert(
            dot,
            LatticeUnit {
                address: address.clone(),
                content: content.into(),
                author: root.0,
                dot,
                lineage: Some((root, range.0, range.1)),
                anchor: None,
            },
        );
        self.index
            .upsert(&address, dot, content_len_of(&self.units[&dot]));
        dot
    }

    /// Split the unit `dot` at char offset `at`, tombstoning it and
    /// re-inserting the parts. Part lineage is root-anchored and part
    /// addresses are root-relative, so independent split histories
    /// produce comparable, coalescable parts. Returns the addresses
    /// bounding the new boundary (unit before, unit after) plus the
    /// boundary's root anchor (root dot, root offset) for fresh
    /// inserts landing on it.
    pub fn split_unit(
        &mut self,
        dot: Dot,
        at: usize,
    ) -> (Option<Sequence>, Option<Sequence>, Option<(Dot, usize)>) {
        let Some(unit) = self.units.get(&dot) else {
            return (None, None, None);
        };
        let chars: Vec<char> = unit.content.chars().collect();
        let len = chars.len();
        let root = unit.lineage.unwrap_or((dot, 0, len));
        let at = at.min(len);
        let (prev_addr, next_addr) = self.index.neighbors(&unit.address);
        // Edge splits are no-ops: the surviving part would be the
        // unit itself (same root range = same derived dot and
        // address), and tombstoning it would self-kill the re-insert.
        if at == 0 {
            return (
                prev_addr,
                Some(unit.address.clone()),
                Some((root.0, root.1)),
            );
        }
        if at == len {
            return (
                Some(unit.address.clone()),
                next_addr,
                Some((root.0, root.2)),
            );
        }
        self.tombstone_dot(dot);
        let mut before = prev_addr.clone();
        let mut after = next_addr.clone();
        if at > 0 {
            let left: String = chars[..at].iter().collect();
            let d = self.insert_part(left, root.0, (root.1, root.1 + at));
            before = self.address_of(d).cloned();
        }
        if at < len {
            let right: String = chars[at..].iter().collect();
            let d = self.insert_part(right, root.0, (root.1 + at, root.2));
            after = self.address_of(d).cloned();
        }
        (before, after, Some((root.0, root.1 + at)))
    }

    /// P1-1/P1-2 convergence passes, run to fixpoint inside render.
    /// Deterministic from merged state, so both replicas normalize
    /// identically:
    ///
    /// 1. Cull trim: a live part fully inside a deleter's cull dies;
    ///    a partially-overlapping part is killed and re-inserted as
    ///    the surviving sub-parts (derived dots coalesce identical
    ///    ranges across split histories).
    /// 2. Refinement: two live parts of the same root with
    ///    overlapping ranges (concurrent splits at different offsets,
    ///    no delete involved) would duplicate content. Kill both and
    ///    re-insert the common refinement — the union of cut points.
    ///    Identical sub-ranges mint identical dots and coalesce.
    #[allow(clippy::type_complexity)]
    pub fn normalize(&mut self) {
        loop {
            match self.find_cull_work() {
                Some((dot, None)) => {
                    // Fully culled: kill, re-insert nothing.
                    self.tombstone_dot(dot);
                }
                Some((dot, Some((parent, s, e, ovs, ove)))) => {
                    let unit = self.units.get(&dot).unwrap().clone();
                    let chars: Vec<char> = unit.content.chars().collect();
                    let left = (s, ovs);
                    let right = (ove, e);
                    self.tombstone_dot(dot);
                    if left.0 < left.1 {
                        let lc: String = chars[left.0 - s..left.1 - s].iter().collect();
                        self.insert_part(lc, parent, left);
                    }
                    if right.0 < right.1 {
                        let rc: String = chars[right.0 - s..right.1 - s].iter().collect();
                        self.insert_part(rc, parent, right);
                    }
                }
                None => {
                    if !self.refine_one_overlap() {
                        return;
                    }
                }
            }
        }
    }

    /// Find the first cull-affected live part: `Some((dot, None))` =
    /// fully culled (kill only); `Some((dot, Some(trim)))` = partially
    /// culled (kill and re-insert the surviving sub-parts).
    #[allow(clippy::type_complexity)]
    fn find_cull_work(&self) -> Option<(Dot, Option<(Dot, usize, usize, usize, usize)>)> {
        for u in self.live() {
            let Some((parent, s, e)) = u.lineage else {
                continue;
            };
            for t in &self.tombstones {
                for &(cp, cs, ce) in &t.culls {
                    if cp != parent || cs >= e || ce <= s {
                        continue;
                    }
                    if cs <= s && ce >= e {
                        return Some((u.dot, None));
                    }
                    let work = (parent, s, e, cs.max(s), ce.min(e));
                    return Some((u.dot, Some(work)));
                }
            }
        }
        None
    }

    fn refine_one_overlap(&mut self) -> bool {
        let live: Vec<LatticeUnit> = self.live().into_iter().cloned().collect();
        for i in 0..live.len() {
            let Some((ra, sa, ea)) = live[i].lineage else {
                continue;
            };
            for j in (i + 1)..live.len() {
                let Some((rb, sb, eb)) = live[j].lineage else {
                    continue;
                };
                if ra != rb || sa >= eb || sb >= ea {
                    continue;
                }
                let (ua, ub) = (live[i].clone(), live[j].clone());
                let mut cuts = [sa, ea, sb, eb];
                cuts.sort_unstable();
                // Kill only parts that are actually refined (the
                // other's boundary falls strictly inside). A part
                // whose whole range survives as a piece must NOT be
                // tombstoned — the re-inserted identical part would
                // self-kill (same dot, same address).
                let interior = |x: usize, s: usize, e: usize| x > s && x < e;
                let kill_a = interior(sb, sa, ea) || interior(eb, sa, ea);
                let kill_b = interior(sa, sb, eb) || interior(ea, sb, eb);
                let a_chars: Vec<char> = ua.content.chars().collect();
                let b_chars: Vec<char> = ub.content.chars().collect();
                if kill_a {
                    self.tombstone_dot(ua.dot);
                }
                if kill_b {
                    self.tombstone_dot(ub.dot);
                }
                for w in cuts.windows(2) {
                    let (x, y) = (w[0], w[1]);
                    if x == y {
                        continue;
                    }
                    let piece: String = if x >= sa && y <= ea {
                        a_chars[x - sa..y - sa].iter().collect()
                    } else {
                        b_chars[x - sb..y - sb].iter().collect()
                    };
                    self.insert_part(piece, ra, (x, y));
                }
                return true;
            }
        }
        false
    }

    /// The address of a unit by dot (the adapter needs the REAL
    /// addresses of freshly split parts, never stale bounds).
    pub fn address_of(&self, dot: Dot) -> Option<&Sequence> {
        self.units.get(&dot).map(|u| &u.address)
    }

    /// Offset → the live unit containing it: (address, dot, chars
    /// strictly before, unit length). O(log L) — the keystroke fast
    /// path (FR-51 Phase 2).
    pub fn find_boundary(&self, offset: usize) -> Option<(Sequence, Dot, usize, usize)> {
        self.index.find_by_offset(offset)
    }

    /// The last live unit (address, dot).
    /// Debug: in-order (address numbers, dot, len) as the index
    /// sees the live set.
    pub fn debug_index(&self) -> Vec<(Vec<i64>, Dot, usize)> {
        self.index
            .in_order()
            .into_iter()
            .map(|(a, d)| {
                (
                    a.numbers().to_vec(),
                    d,
                    self.units
                        .get(&d)
                        .map(|u| u.content.chars().count())
                        .unwrap_or(0),
                )
            })
            .collect()
    }

    pub fn live_last(&self) -> Option<(Sequence, Dot)> {
        self.index.last()
    }

    /// The live successor's address, if any.
    pub fn live_succ(&self, addr: &Sequence) -> Option<Sequence> {
        self.index.neighbors(addr).1
    }

    /// Root anchor of the boundary immediately AFTER the unit: for a
    /// part, the end of its root range; for a fresh insert, its own
    /// anchor point; for a root unit, its full extent. Fresh inserts
    /// at this boundary address themselves root-relative.
    pub fn boundary_anchor_after(&self, dot: Dot) -> Option<(Dot, usize)> {
        let unit = self.units.get(&dot)?;
        if let Some((rd, _, e)) = unit.lineage {
            Some((rd, e))
        } else if let Some((rd, o)) = unit.anchor {
            Some((rd, o))
        } else {
            Some((dot, unit.content.chars().count()))
        }
    }

    fn counter_of(&self, server: u64) -> u64 {
        if server == self.server {
            self.counter
        } else {
            0
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn doc(server: u64) -> LatticeDoc {
        LatticeDoc::new(server)
    }

    #[test]
    fn single_writer_build_and_render() {
        let mut d = doc(1);
        d.insert_between(None, None, "hello ", 1);
        let all = d.live();
        let first_addr = all[0].address.clone();
        d.insert_between(Some(&first_addr), None, "world", 1);
        assert_eq!(d.render(), "hello world");
    }

    #[test]
    fn addresses_strictly_between_neighbors() {
        let mut d = doc(1);
        let a = d.insert_between(None, None, "A", 1);
        let a_addr = d.units[&a].address.clone();
        let b = d.insert_between(Some(&a_addr), None, "B", 1);
        let b_addr = d.units[&b].address.clone();
        let c = d.insert_between(Some(&a_addr), Some(&b_addr), "C", 1);
        let c_addr = d.units[&c].address.clone();
        assert!(a_addr.compare_to(&c_addr) == std::cmp::Ordering::Less);
        assert!(c_addr.compare_to(&b_addr) == std::cmp::Ordering::Less);
        assert_eq!(d.render(), "ACB");
    }

    #[test]
    fn merge_is_commutative_and_idempotent() {
        let mut a = doc(1);
        let mut b = doc(2);
        a.insert_between(None, None, "left-", 1);
        b.insert_between(None, None, "right", 2);

        let mut ab = a.clone();
        ab.merge(&b);
        let mut ba = b.clone();
        ba.merge(&a);
        assert_eq!(ab.render(), ba.render(), "merge order must not matter");

        let text = ab.render();
        ab.merge(&b);
        assert_eq!(ab.render(), text, "duplicate merge must be idempotent");
        assert!(text.contains("left-") && text.contains("right"));
    }

    #[test]
    fn concurrent_inserts_same_gap_deterministic_order() {
        let mut a = doc(1);
        let mut b = doc(2);
        // Both replicas start from the same unit.
        let base_addr = Sequence::from_numbers(vec![1, 9, 1]);
        a.seed_shared_unit(base_addr.clone(), "M", 9, (9, 1));
        b.seed_shared_unit(base_addr.clone(), "M", 9, (9, 1));
        // Each inserts after base concurrently.
        a.insert_between(Some(&base_addr), None, "A", 1);
        b.insert_between(Some(&base_addr), None, "B", 2);

        let mut ab = a.clone();
        ab.merge(&b);
        let mut ba = b.clone();
        ba.merge(&a);
        assert_eq!(ab.render(), ba.render(), "same gap, both orders agree");
        let r = ab.render();
        assert!(r.starts_with('M'), "base first: {}", r);
    }

    #[test]
    fn delete_of_unseen_insert_survives() {
        let mut a = doc(1);
        let mut b = doc(2);
        let x = Sequence::from_numbers(vec![1, 5, 1]);
        let y = Sequence::from_numbers(vec![1, 5, 2]);
        a.seed_shared_unit(x.clone(), "X", 1, (1, 1));
        b.seed_shared_unit(x.clone(), "X", 1, (1, 1));
        b.seed_shared_unit(y.clone(), "Y", 2, (2, 1));
        // A (knowing only X) deletes the whole range covering X and Y.
        let lo = Sequence::from_numbers(vec![1, 5]);
        let hi = Sequence::from_numbers(vec![1, 6]);
        a.delete_range(&lo, &hi);
        // B (knowing X and Y) has no tombstones.
        let mut m = a.clone();
        m.merge(&b);
        let text = m.render();
        assert_eq!(
            text, "Y",
            "X dies (in context), Y survives (unseen by deleter): got {:?}",
            text
        );
    }

    #[test]
    fn disjoint_concurrent_ops_both_apply() {
        let mut a = doc(1);
        let mut b = doc(2);
        let l = Sequence::from_numbers(vec![1, 1, 1]);
        let r = Sequence::from_numbers(vec![9, 9, 9]);
        a.seed_shared_unit(l.clone(), "L", 1, (1, 1));
        b.seed_shared_unit(r.clone(), "R", 2, (2, 1));
        // A deletes around L only; B inserts R — both apply.
        a.delete_range(
            &Sequence::from_numbers(vec![1, 1]),
            &Sequence::from_numbers(vec![2]),
        );
        let mut m = a.clone();
        m.merge(&b);
        assert_eq!(m.render(), "R", "L deleted, R lives");
    }

    #[test]
    fn delete_then_reinsert_same_range() {
        let mut d = doc(1);
        d.insert_between(None, None, "gone", 1);
        let lo = Sequence::from_numbers(vec![0]);
        let hi = Sequence::from_numbers(vec![100]);
        d.delete_range(&lo, &hi);
        assert_eq!(d.render(), "", "all dead");
        // New insert gets a fresh dot — not covered by the old context.
        d.insert_between(None, None, "fresh", 1);
        assert_eq!(d.render(), "fresh", "new units are not retro-tombstoned");
    }
}
