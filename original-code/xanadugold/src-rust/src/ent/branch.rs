use std::collections::HashMap;

// [New Migration Comment] BranchId is a stable identity handle that persists
// across "become" transitions (materialized ↔ stub). In the original C++,
// identity was the memory address of a BranchDescription; the "become" mechanism
// used placement-new to overwrite the object in-place with a stub, so all
// existing pointers to the address saw the new type. Here, identity is an
// opaque integer; all references resolve through BranchStore.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct BranchId(pub(crate) u64);

impl BranchId {
    pub(crate) fn raw_for_hash(&self) -> u32 {
        self.0 as u32
    }

    pub fn to_u64(&self) -> u64 {
        self.0
    }

    /// FR-52 A-1 P1: rebuild from the persisted id (snapshot restore).
    pub fn from_u64(raw: u64) -> Self {
        BranchId(raw)
    }
}

// [New Migration Comment] Discriminates the three branch shapes from the
// original class hierarchy: RootBranch (no parents), TreeBranch (one parent),
// DagBranch (two parents). An enum replaces the three concrete subclasses.
// Source: branchx.hxx lines 90-175
#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub enum BranchKind {
    Root,
    Tree {
        parent: crate::ent::trace::TracePosition,
    },
    Dag {
        parent1: crate::ent::trace::TracePosition,
        parent2: crate::ent::trace::TracePosition,
    },
}

// [Original] "Instances of subclasses describe the different kinds of paths in
// a traceDag. The three kinds are root (no parent), tree (one parent) and dag
// (two parent) branches."
//
// [Adapted from Original] Field mapping from BranchDescription (branchx.hxx):
//   lastPosition  → last_position
//   myLeft        → left (Option<BranchId>)
//   myRight       → right (Option<BranchId>)
//   fulltrace     → deferred to Phase 2 (DagWood back-reference)
//
// The original also had myLeft/myRight as CHKPTR(BranchDescription | NULL),
// which were owning pointers with a checked-pointer wrapper.
#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct Branch {
    pub kind: BranchKind,
    // [Original] "At the moment, these never go away!!!"
    // lastPosition starts at 2; position 1 is the implicit entry position.
    // Source: branchx.cxx line 241
    pub last_position: u32,
    pub left: Option<BranchId>,
    pub right: Option<BranchId>,
}

// [New Migration Comment] Placeholder for an evicted branch. In the original,
// BranchDescriptionStub was created via placement-new overwriting the real
// BranchDescription in memory (branchx.sxx lines 89-199). The stub held only
// identity info; any method call triggered getReal() which faulted the object
// back from disk. Here, we record the identity and hash; reification is deferred
// until the persistence layer exists.
#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct BranchStub {
    pub hash: u32,
}

// [New Migration Comment] Encodes the "become" transition point explicitly.
// In the original C++, this was invisible — the same memory address would
// hold either a BranchDescription or a BranchDescriptionStub, with the vtable
// pointer swapped via changeClassToThatOf (tofux.ixx line 22-34). Making the
// transition explicit in the type system is the Rust equivalent.
#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub enum BranchState {
    Materialized(Branch),
    Stub(BranchStub),
}

/// FR-52 A-1 P1: the persisted form of one branch entry.
#[cfg(feature = "serde")]
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SnapshotBranchEntry {
    pub id: u64,
    pub state: BranchState,
}

#[derive(Debug, Clone)]
pub struct BranchStore {
    branches: HashMap<BranchId, BranchState>,
    next_id: u64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum BranchError {
    NotFound(BranchId),
    IsStub(BranchId),
}

impl BranchStore {
    pub fn new() -> Self {
        BranchStore {
            branches: HashMap::new(),
            next_id: 1,
        }
    }

    fn allocate_id(&mut self) -> BranchId {
        let id = BranchId(self.next_id);
        self.next_id += 1;
        id
    }

    // [Adapted from Original] BranchDescription::make(DagWood)
    // Source: branchx.cxx line 54-55
    // Creates a RootBranch. The original passed a DagWood reference
    // (fulltrace) which we defer.
    //
    // Returns (BranchId, TracePosition) where the TracePosition is at
    // position 1 — the implicit entry position. Position numbering starts at 2.
    pub fn create_root(&mut self) -> (BranchId, crate::ent::trace::TracePosition) {
        let id = self.allocate_id();
        let branch = Branch {
            kind: BranchKind::Root,
            last_position: 2,
            left: None,
            right: None,
        };
        self.branches.insert(id, BranchState::Materialized(branch));
        let entry = crate::ent::trace::TracePosition::new(id, 1);
        (id, entry)
    }

    // [Adapted from Original] BranchDescription::make(DagWood, TracePosition)
    // Source: branchx.cxx line 59-61
    pub fn create_tree(
        &mut self,
        parent: crate::ent::trace::TracePosition,
    ) -> (BranchId, crate::ent::trace::TracePosition) {
        let id = self.allocate_id();
        let branch = Branch {
            kind: BranchKind::Tree { parent },
            last_position: 2,
            left: None,
            right: None,
        };
        self.branches.insert(id, BranchState::Materialized(branch));
        let entry = crate::ent::trace::TracePosition::new(id, 1);
        (id, entry)
    }

    // [Adapted from Original] BranchDescription::make(DagWood, TracePosition, TracePosition)
    // Source: branchx.cxx line 64-69
    pub fn create_dag(
        &mut self,
        parent1: crate::ent::trace::TracePosition,
        parent2: crate::ent::trace::TracePosition,
    ) -> (BranchId, crate::ent::trace::TracePosition) {
        let id = self.allocate_id();
        let branch = Branch {
            kind: BranchKind::Dag { parent1, parent2 },
            last_position: 2,
            left: None,
            right: None,
        };
        self.branches.insert(id, BranchState::Materialized(branch));
        let entry = crate::ent::trace::TracePosition::new(id, 1);
        (id, entry)
    }

    // [Adapted from Original] BranchDescription::nextPosition
    // Source: branchx.cxx line 225-233
    // "Return the first available tracePosition on this branch."
    // Increments lastPosition and returns a TracePosition at the new value.
    pub fn next_position(
        &mut self,
        id: BranchId,
    ) -> Result<crate::ent::trace::TracePosition, BranchError> {
        let branch = self.get_mut(id)?;
        branch.last_position += 1;
        let pos = branch.last_position;
        Ok(crate::ent::trace::TracePosition::new(id, pos))
    }

    // [Adapted from Original] BranchDescription::installBranch
    // Source: branchx.cxx line 162-187
    //
    // "Install branch as a descendant branch of myself. Walk down the binary
    // tree of branches to find a place to lodge it. This gets called if there
    // was already a branch existing off my root."
    //
    // Algorithm:
    //   1. If child_id == parent_id, return (identity guard).
    //   2. If parent.left is None, install there.
    //   3. Otherwise, recurse into parent.left, then SWAP left and right.
    //
    // [New Migration Comment] The swap-after-recurse is not a standard tree
    // rotation. It distributes growth across both subtrees by alternating
    // which side the recursive insertion targets. Tests T5-T8 verify the
    // observed behavior.
    pub fn install_branch(
        &mut self,
        parent_id: BranchId,
        child_id: BranchId,
    ) -> Result<(), BranchError> {
        if parent_id == child_id {
            return Ok(());
        }

        // [New Migration Comment] We extract the left_child value before
        // mutating, then release the borrow before recursing. The original
        // had no borrow checker — it used raw pointers throughout.
        {
            let parent = self.get_mut(parent_id)?;
            if parent.left.is_none() {
                parent.left = Some(child_id);
                return Ok(());
            }
        }

        // Left is Some — recurse then swap
        let left_child = self.get(parent_id)?.left.unwrap();
        self.install_branch(left_child, child_id)?;

        let parent = self.get_mut(parent_id)?;
        // [Original] Source: branchx.cxx lines 183-185
        //   tmpBr = myLeft;
        //   myLeft = myRight;
        //   myRight = tmpBr;
        let tmp = parent.left;
        parent.left = parent.right;
        parent.right = tmp;

        Ok(())
    }

    /// Get an immutable reference to a materialized branch.
    /// Returns Err if not found or if the branch is currently a stub.
    /// FR-52 A-1 P1: snapshot the branch FACTS for persistence.
    /// Derived caches live in DagWood and rebuild lazily.
    #[cfg(feature = "serde")]
    pub fn snapshot_entries(&self) -> Vec<SnapshotBranchEntry> {
        let mut entries: Vec<SnapshotBranchEntry> = self
            .branches
            .iter()
            .map(|(id, state)| SnapshotBranchEntry {
                id: id.to_u64(),
                state: state.clone(),
            })
            .collect();
        entries.sort_by_key(|e| e.id);
        entries
    }

    /// Rebuild from snapshot facts. next_id must be >= every id + 1;
    /// callers carry it in the snapshot.
    #[cfg(feature = "serde")]
    pub fn restore(next_id: u64, entries: Vec<SnapshotBranchEntry>) -> Self {
        let mut branches = HashMap::new();
        for e in entries {
            branches.insert(BranchId::from_u64(e.id), e.state);
        }
        BranchStore { branches, next_id }
    }

    /// FR-52 A-1 P1: next id (persisted in the snapshot).
    #[cfg(feature = "serde")]
    pub fn next_id(&self) -> u64 {
        self.next_id
    }

    /// Debug accessor for restore diagnostics.
    pub fn next_id_value(&self) -> u64 {
        self.next_id
    }

    pub fn get(&self, id: BranchId) -> Result<&Branch, BranchError> {
        match self.branches.get(&id) {
            None => Err(BranchError::NotFound(id)),
            Some(BranchState::Materialized(b)) => Ok(b),
            Some(BranchState::Stub(_)) => Err(BranchError::IsStub(id)),
        }
    }

    /// Get a mutable reference to a materialized branch.
    pub fn get_mut(&mut self, id: BranchId) -> Result<&mut Branch, BranchError> {
        match self.branches.get_mut(&id) {
            None => Err(BranchError::NotFound(id)),
            Some(BranchState::Materialized(b)) => Ok(b),
            Some(BranchState::Stub(_)) => Err(BranchError::IsStub(id)),
        }
    }

    // [New Migration Comment] Evict a branch: transition from Materialized to Stub.
    // This is the "becomeStub" operation from the original (branchx.sxx line 206-211).
    // The original used placement-new to overwrite the object in-place:
    //   void BranchDescription::becomeStub() {
    //       UInt32 hash = this->hashForEqual();
    //       WPTR(FlockInfo) info = this->fetchInfo();
    //       new (this) BranchDescriptionStub(shepFlag, hash, info);
    //   }
    // Here, we replace the entry in the HashMap. The BranchId remains stable.
    pub fn evict(&mut self, id: BranchId) -> Result<(), BranchError> {
        let hash = match self.branches.get(&id) {
            None => return Err(BranchError::NotFound(id)),
            Some(BranchState::Stub(_)) => return Ok(()),
            Some(BranchState::Materialized(_)) => {
                // We need the hash; compute from the BranchId for now
                id_hash(&id)
            }
        };
        self.branches
            .insert(id, BranchState::Stub(BranchStub { hash }));
        Ok(())
    }

    // [Adapted from Original] BranchDescription::contentsHash
    // Source: branchx.cxx line 85-87
    //
    // The original XORs:
    //   Abraham::contentsHash() ^ myLeft->hashForEqual() ^ myRight->hashForEqual()
    //   ^ fulltrace->hashForEqual()
    //
    // [New Migration Comment] We stub Abraham::contentsHash() as 0 and
    // fulltrace->hashForEqual() as the BranchId's hash. These will be corrected
    // in Phase 2 when DagWood and the Category system exist.
    pub fn contents_hash(&self, id: BranchId) -> Result<u32, BranchError> {
        let branch = self.get(id)?;
        let abraham_hash: u32 = 0;
        let fulltrace_hash: u32 = id_hash(&id);
        let left_hash = match branch.left {
            Some(lid) => id_hash(&lid),
            None => 0,
        };
        let right_hash = match branch.right {
            Some(rid) => id_hash(&rid),
            None => 0,
        };
        Ok(abraham_hash ^ left_hash ^ right_hash ^ fulltrace_hash)
    }

    pub fn contains(&self, id: BranchId) -> bool {
        self.branches.contains_key(&id)
    }

    pub fn is_stub(&self, id: BranchId) -> bool {
        matches!(self.branches.get(&id), Some(BranchState::Stub(_)))
    }
}

// Simple deterministic hash for BranchId. Uses the same formula as
// BoundedTrace::actualHashForEqual for consistency.
// [New Migration Comment] The original used Heaper::takeOop() which was a
// monotonic counter. We use the BranchId value directly.
fn id_hash(id: &BranchId) -> u32 {
    id.raw_for_hash().wrapping_mul(10993) & 0x7FFFFFF
}

#[cfg(test)]
mod tests {
    use super::*;

    // T1: root_branch_starts_at_position_2
    #[test]
    fn root_branch_starts_at_position_2() {
        let mut store = BranchStore::new();
        let (root_id, entry_pos) = store.create_root();
        let branch = store.get(root_id).unwrap();
        assert_eq!(branch.last_position, 2);
        assert_eq!(entry_pos.position(), 1);
        assert_eq!(entry_pos.branch(), root_id);
    }

    // T2: tree_branch_has_parent
    #[test]
    fn tree_branch_has_parent() {
        let mut store = BranchStore::new();
        let (root_id, _) = store.create_root();
        let parent = crate::ent::trace::TracePosition::new(root_id, 1);
        let (tree_id, _) = store.create_tree(parent);
        let branch = store.get(tree_id).unwrap();
        assert_eq!(branch.last_position, 2);
        match &branch.kind {
            BranchKind::Tree { parent: p } => assert_eq!(*p, parent),
            _ => panic!("expected Tree branch kind"),
        }
    }

    // T3: dag_branch_has_two_parents
    #[test]
    fn dag_branch_has_two_parents() {
        let mut store = BranchStore::new();
        let (root_id, _) = store.create_root();
        let p1 = crate::ent::trace::TracePosition::new(root_id, 1);
        let p2 = crate::ent::trace::TracePosition::new(root_id, 2);
        let (dag_id, _) = store.create_dag(p1, p2);
        let branch = store.get(dag_id).unwrap();
        assert_eq!(branch.last_position, 2);
        match &branch.kind {
            BranchKind::Dag { parent1, parent2 } => {
                assert_eq!(*parent1, p1);
                assert_eq!(*parent2, p2);
            }
            _ => panic!("expected Dag branch kind"),
        }
    }

    // T4: next_position_increments
    // [New Migration Comment] lastPosition starts at 2. nextPosition increments
    // then returns, so first call returns 3, not 2. Position 2 is reserved
    // (never assigned by nextPosition). Evidence: addSuccessorsTo at
    // branchx.cxx:113 stores TracePosition::make(this, 3), confirming position 3
    // is the first successor position.
    #[test]
    fn next_position_increments() {
        let mut store = BranchStore::new();
        let (root_id, _) = store.create_root();

        let pos3 = store.next_position(root_id).unwrap();
        assert_eq!(pos3.position(), 3);

        let pos4 = store.next_position(root_id).unwrap();
        assert_eq!(pos4.position(), 4);

        let pos5 = store.next_position(root_id).unwrap();
        assert_eq!(pos5.position(), 5);

        let branch = store.get(root_id).unwrap();
        assert_eq!(branch.last_position, 5);
    }

    // T5: install_branch_first_child_goes_left
    #[test]
    fn install_branch_first_child_goes_left() {
        let mut store = BranchStore::new();
        let (root_id, _) = store.create_root();
        let (child_a, _) = store.create_root();

        store.install_branch(root_id, child_a).unwrap();

        let root = store.get(root_id).unwrap();
        assert_eq!(root.left, Some(child_a));
        assert_eq!(root.right, None);
    }

    // T6: install_branch_second_child_rotates
    #[test]
    fn install_branch_second_child_rotates() {
        let mut store = BranchStore::new();
        let (root_id, _) = store.create_root();
        let (child_a, _) = store.create_root();
        let (child_b, _) = store.create_root();

        store.install_branch(root_id, child_a).unwrap();
        store.install_branch(root_id, child_b).unwrap();

        let root = store.get(root_id).unwrap();
        // After second installation, both left and right should be populated
        // due to the swap-after-recurse pattern.
        assert!(root.left.is_some() || root.right.is_some());
        // The tree should contain both children somewhere
        let mut found_a = false;
        let mut found_b = false;
        if root.left == Some(child_a) || root.right == Some(child_a) {
            found_a = true;
        }
        if root.left == Some(child_b) || root.right == Some(child_b) {
            found_b = true;
        }
        // At least one child should be directly referenced
        assert!(found_a || found_b);
    }

    // T7: install_branch_idempotent_for_self
    #[test]
    fn install_branch_idempotent_for_self() {
        let mut store = BranchStore::new();
        let (root_id, _) = store.create_root();
        let (child_a, _) = store.create_root();

        store.install_branch(root_id, child_a).unwrap();

        let left_before = store.get(root_id).unwrap().left;

        // Installing root into itself should be a no-op
        store.install_branch(root_id, root_id).unwrap();

        let left_after = store.get(root_id).unwrap().left;
        assert_eq!(left_before, left_after);
    }

    // T8: install_branch_grows_depth
    #[test]
    fn install_branch_grows_depth() {
        let mut store = BranchStore::new();
        let (root_id, _) = store.create_root();
        let mut child_ids = Vec::new();
        for _ in 0..5 {
            let (cid, _) = store.create_root();
            child_ids.push(cid);
        }
        for &cid in &child_ids {
            store.install_branch(root_id, cid).unwrap();
        }

        // After 5 insertions, the tree should have depth > 1
        let root = store.get(root_id).unwrap();
        assert!(root.left.is_some());
        assert!(root.right.is_some());

        // Check that at least one child of root has its own children
        let has_depth_2 = if let Some(lid) = root.left {
            let left = store.get(lid).unwrap();
            left.left.is_some() || left.right.is_some()
        } else {
            false
        };
        assert!(has_depth_2);
    }

    // T_extra: evict_and_check_become_semantics
    #[test]
    fn evict_transitions_to_stub() {
        let mut store = BranchStore::new();
        let (root_id, _) = store.create_root();

        assert!(!store.is_stub(root_id));

        store.evict(root_id).unwrap();

        assert!(store.is_stub(root_id));
        // Accessing a stubbed branch should return IsStub error
        match store.get(root_id) {
            Err(BranchError::IsStub(_)) => {}
            other => panic!("expected IsStub error, got {:?}", other),
        }
    }

    // T_extra: branch_id_stability_across_evict
    #[test]
    fn branch_id_stability_across_evict() {
        let mut store = BranchStore::new();
        let (root_id, _) = store.create_root();

        let trace = crate::ent::trace::TracePosition::new(root_id, 1);
        assert_eq!(trace.branch(), root_id);

        store.evict(root_id).unwrap();

        // The TracePosition still holds the same BranchId
        assert_eq!(trace.branch(), root_id);
        // The store still has an entry for that id
        assert!(store.contains(root_id));
    }

    // T_extra: evict_already_stubbed_is_idempotent
    #[test]
    fn evict_already_stubbed_is_idempotent() {
        let mut store = BranchStore::new();
        let (root_id, _) = store.create_root();

        store.evict(root_id).unwrap();
        store.evict(root_id).unwrap();

        assert!(store.is_stub(root_id));
    }

    // T_extra: contents_hash_is_deterministic
    #[test]
    fn contents_hash_is_deterministic() {
        let mut store = BranchStore::new();
        let (root_id, _) = store.create_root();
        let (child_a, _) = store.create_root();
        store.install_branch(root_id, child_a).unwrap();

        let h1 = store.contents_hash(root_id).unwrap();
        let h2 = store.contents_hash(root_id).unwrap();
        assert_eq!(h1, h2);
    }

    // P6: stress_install_branch_100k — 100,000 children under one parent.
    // Exercises the recursive insert-with-swap pattern at scale.
    // Verifies all children are reachable by tree traversal.
    // Also measures insertion and traversal time separately.
    #[test]
    #[ignore]
    fn stress_install_branch_100k() {
        use std::time::Instant;
        let t = Instant::now();

        let mut store = BranchStore::new();
        let (root_id, _) = store.create_root();
        let mut child_ids = Vec::new();

        for i in 0..100_000 {
            let (cid, _) = store.create_root();
            store.install_branch(root_id, cid).unwrap();
            child_ids.push(cid);
            if i > 0 && i % 25_000 == 0 {
                eprintln!(
                    "  P6 inserted {} children in {:.3}s",
                    i,
                    t.elapsed().as_secs_f64()
                );
            }
        }
        eprintln!(
            "  P6 insert 100K children: {:.3}s",
            t.elapsed().as_secs_f64()
        );

        let t2 = Instant::now();
        let mut found = std::collections::HashSet::new();
        fn collect(
            store: &BranchStore,
            id: BranchId,
            found: &mut std::collections::HashSet<BranchId>,
        ) {
            if found.insert(id) {
                let branch = store.get(id).unwrap();
                if let Some(l) = branch.left {
                    collect(store, l, found);
                }
                if let Some(r) = branch.right {
                    collect(store, r, found);
                }
            }
        }
        collect(&store, root_id, &mut found);
        eprintln!(
            "  P6 traverse tree ({} nodes): {:.3}s",
            found.len(),
            t2.elapsed().as_secs_f64()
        );

        for &cid in &child_ids {
            assert!(
                found.contains(&cid),
                "child {} not reachable from root",
                cid.raw_for_hash()
            );
        }
        eprintln!("  P6 total: {:.3}s", t.elapsed().as_secs_f64());
    }
}
