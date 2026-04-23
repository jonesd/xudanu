use crate::ent::branch::BranchId;

// [Adapted from Original] Replaces the abstract TracePosition + concrete
// BoundedTrace class hierarchy (tracepx.hxx lines 57-204). Only one concrete
// subclass existed in the original, so we use a single struct.
//
// [Original] "Each dagwood defines a partial ordering of TracePositions.
// Each TracePosition has a branch (a BranchDescription) and a position
// (a positive integer). The branch identifies which branch of the traceDag
// the position lies on, and the position identifies how far along the branch
// the position lies."
// Source: dagwoodx.hxx class comment
#[derive(Debug, Clone, Copy)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct TracePosition {
    branch: BranchId,
    position: u32,
}

impl TracePosition {
    pub fn new(branch: BranchId, position: u32) -> Self {
        TracePosition { branch, position }
    }

    pub fn branch(&self) -> BranchId {
        self.branch
    }

    pub fn position(&self) -> u32 {
        self.position
    }

    // [Adapted from Original] BoundedTrace::isEqual
    // Source: tracepx.cxx line 97-116
    // "Two positions are equal if they have the same branch and position."
    pub fn is_equal(&self, other: &TracePosition) -> bool {
        self.branch == other.branch && self.position == other.position
    }

    // [Adapted from Original] BoundedTrace::actualHashForEqual
    // Source: tracepx.cxx line 93
    // Formula: (branch_hash + position) * 10993 & 0x7FFFFFF
    // The original comment says "uses a couple of arbitrary primes".
    // 10993 and 0x7FFFFFF (2^27 - 1) are those primes.
    pub fn hash(&self) -> u32 {
        let branch_hash = self.branch_hash();
        branch_hash.wrapping_add(self.position).wrapping_mul(10993) & 0x7FFFFFF
    }

    // [New Migration Comment] The original used myBranch->hashForEqual()
    // which delegated to the BranchDescription's hash. Since we use BranchId
    // as the identity, we derive the hash from the BranchId value using the
    // same formula pattern.
    fn branch_hash(&self) -> u32 {
        // Mirror the id_hash function from branch.rs
        self.branch.raw_for_hash().wrapping_mul(10993) & 0x7FFFFFF
    }
}

impl PartialEq for TracePosition {
    fn eq(&self, other: &Self) -> bool {
        self.is_equal(other)
    }
}

impl Eq for TracePosition {}

impl std::hash::Hash for TracePosition {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        state.write_u32(self.hash());
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ent::branch::BranchStore;

    fn make_two_traces() -> (BranchStore, BranchId, BranchId) {
        let mut store = BranchStore::new();
        let (a, _) = store.create_root();
        let (b, _) = store.create_root();
        (store, a, b)
    }

    // T9: equality_same_branch_same_position
    #[test]
    fn equality_same_branch_same_position() {
        let mut store = BranchStore::new();
        let (root_id, _) = store.create_root();
        let a = TracePosition::new(root_id, 1);
        let b = TracePosition::new(root_id, 1);
        assert_eq!(a, b);
        assert!(a.is_equal(&b));
    }

    // T10: inequality_different_position
    #[test]
    fn inequality_different_position() {
        let mut store = BranchStore::new();
        let (root_id, _) = store.create_root();
        let a = TracePosition::new(root_id, 1);
        let b = TracePosition::new(root_id, 2);
        assert_ne!(a, b);
        assert!(!a.is_equal(&b));
    }

    // T11: inequality_different_branch
    #[test]
    fn inequality_different_branch() {
        let (_, a_id, b_id) = make_two_traces();
        let a = TracePosition::new(a_id, 1);
        let b = TracePosition::new(b_id, 1);
        assert_ne!(a, b);
        assert!(!a.is_equal(&b));
    }

    // T12: hash_deterministic
    #[test]
    fn hash_deterministic() {
        let mut store = BranchStore::new();
        let (root_id, _) = store.create_root();
        let t = TracePosition::new(root_id, 42);
        let h1 = t.hash();
        let h2 = t.hash();
        assert_eq!(h1, h2);
    }

    // T13: hash_formula
    #[test]
    fn hash_formula() {
        let mut store = BranchStore::new();
        let (root_id, _) = store.create_root();
        let pos: u32 = 5;
        let t = TracePosition::new(root_id, pos);
        let branch_hash = root_id.raw_for_hash().wrapping_mul(10993) & 0x7FFFFFF;
        let expected = branch_hash.wrapping_add(pos).wrapping_mul(10993) & 0x7FFFFFF;
        assert_eq!(t.hash(), expected);
    }
}
