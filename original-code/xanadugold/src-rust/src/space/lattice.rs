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

#[derive(Debug, Clone, PartialEq)]
pub struct LatticeUnit {
    pub address: Sequence,
    pub content: String,
    pub author: u64,
    pub dot: Dot,
}

#[derive(Debug, Clone, PartialEq)]
pub struct RegionTombstone {
    pub region: SequenceRegion,
    /// Dots the deleter knew when deleting: a unit dies iff its dot
    /// is here AND its address is in the region. Units the deleter
    /// never saw survive.
    pub context: HashSet<Dot>,
}

#[derive(Debug, Clone)]
pub struct LatticeDoc {
    server: u64,
    counter: u64,
    units: HashMap<Dot, LatticeUnit>,
    tombstones: Vec<RegionTombstone>,
}

impl LatticeDoc {
    pub fn new(server: u64) -> Self {
        LatticeDoc {
            server,
            counter: 0,
            units: HashMap::new(),
            tombstones: Vec::new(),
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
    pub fn allocate_between(&self, prev: Option<&Sequence>, next: Option<&Sequence>) -> Sequence {
        let candidate = match prev {
            Some(p) => p.append_pair(self.server as i64, self.counter as i64 + 1),
            None => Sequence::from_numbers(vec![1, self.server as i64, self.counter as i64 + 1]),
        };
        if let Some(n) = next {
            if candidate.compare_to(n) != std::cmp::Ordering::Less {
                // Dense gap: anchor inside prev's last level instead —
                // [.., prev_last + 1, server, counter] under prev's
                // parent, which sorts between prev and any extension
                // of prev's next sibling only when prev_last + 1 stays
                // below next's divergence; the assert below is the
                // tripwire for shapes needing deeper handling.
                if let Some(p) = prev {
                    // Dense gap: prev ++ [0, server, counter] is
                    // strictly interior — allocations never emit
                    // zero-elements (server >= 1, counter >= 1), so
                    // the 0-level sits below every extension of prev
                    // and above prev itself. This is the widening
                    // invariant: deepen, never renumber.
                    let mut nums = p.numbers().to_vec();
                    nums.push(0);
                    nums.push(self.server as i64);
                    nums.push(self.counter as i64 + 1);
                    let deepened = Sequence::from_numbers(nums);
                    debug_assert!(
                        deepened.compare_to(n) == std::cmp::Ordering::Less,
                        "allocation invariant: interior address must sort below next"
                    );
                    return deepened;
                }
            }
        }
        candidate
    }

    /// Insert `content` between the units at the given live-set
    /// neighbor dots (None = before first / after last).
    pub fn insert_between(
        &mut self,
        prev: Option<&Sequence>,
        next: Option<&Sequence>,
        content: impl Into<String>,
        author: u64,
    ) -> Dot {
        let address = self.allocate_between(prev, next);
        let dot = self.next_dot();
        self.units.insert(
            dot,
            LatticeUnit {
                address,
                content: content.into(),
                author,
                dot,
            },
        );
        dot
    }

    /// The live units in address order.
    pub fn live(&self) -> Vec<&LatticeUnit> {
        let mut alive: Vec<&LatticeUnit> =
            self.units.values().filter(|u| !self.is_dead(u)).collect();
        alive.sort_by(|a, b| a.address.compare_to(&b.address));
        alive
    }

    fn is_dead(&self, unit: &LatticeUnit) -> bool {
        self.tombstones
            .iter()
            .any(|t| t.context.contains(&unit.dot) && t.region.contains_sequence(&unit.address))
    }

    /// Delete the units whose addresses fall in [start, stop)
    /// relative to the CURRENT live view — the tombstone carries this
    /// replica's knowledge (the dots of the live units in range), so
    /// concurrent unseen inserts survive.
    pub fn delete_range(&mut self, start: &Sequence, stop: &Sequence) {
        let region = SequenceRegion::interval(start.clone(), stop.clone());
        let context: HashSet<Dot> = self
            .live()
            .into_iter()
            .filter(|u| region.contains_sequence(&u.address))
            .map(|u| u.dot)
            .collect();
        if context.is_empty() {
            return;
        }
        self.tombstones.push(RegionTombstone { region, context });
    }

    /// Render the live view.
    pub fn render(&self) -> String {
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
        a.units.insert(
            (9, 1),
            LatticeUnit {
                address: base_addr.clone(),
                content: "M".into(),
                author: 9,
                dot: (9, 1),
            },
        );
        b.units.insert(
            (9, 1),
            LatticeUnit {
                address: base_addr.clone(),
                content: "M".into(),
                author: 9,
                dot: (9, 1),
            },
        );
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
        let unit = |addr: &Sequence, content: &str, dot: Dot| LatticeUnit {
            address: addr.clone(),
            content: content.to_string(),
            author: dot.0,
            dot,
        };
        a.units.insert((1, 1), unit(&x, "X", (1, 1)));
        b.units.insert((1, 1), unit(&x, "X", (1, 1)));
        b.units.insert((2, 1), unit(&y, "Y", (2, 1)));
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
        a.units.insert(
            (1, 1),
            LatticeUnit {
                address: l.clone(),
                content: "L".into(),
                author: 1,
                dot: (1, 1),
            },
        );
        b.units.insert(
            (2, 1),
            LatticeUnit {
                address: r.clone(),
                content: "R".into(),
                author: 2,
                dot: (2, 1),
            },
        );
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
