use std::collections::HashMap;

use crate::ent::branch::{BranchId, BranchStore};
use crate::ent::trace::TracePosition;

// [Original] "Each dagwood defines a partial ordering of TracePositions."
// Source: dagwoodx.hxx class comment (line 82-85)
//
// [Adapted from Original] Field mapping from DagWood (dagwoodx.hxx):
//   myRoot          → root (TracePosition)
//   myTrunk         → trunk (HashMap<TracePosition, BranchId>)
//   myCachedPosition → deferred (navigation cache, Phase 3)
//   myNavCache       → deferred (navigation cache, Phase 3)
//
// The original also held a CHKPTR(MuTable) for myTrunk (a GrandHashTable),
// which we replace with a standard HashMap.
pub struct DagWood {
    branches: BranchStore,
    root: TracePosition,
    trunk: HashMap<TracePosition, BranchId>,
}

impl DagWood {
    // [Adapted from Original] DagWood::DagWood()
    // Source: dagwoodx.cxx lines 159-168
    //
    // Original constructor:
    //   myCachedPosition = NULL;
    //   myNavCache = PrimIndexTable::make(128);
    //   myTrunk = GrandHashTable::make(HeaperSpace::make());
    //   myRoot = TracePosition::make(BranchDescription::make(this), 1);
    //   myRoot->newSuccessor();  // "Ensure that no elements get allocated on the root branch."
    //   this->newShepherd();
    //   this->remember();
    //
    // [New Migration Comment] We omit myCachedPosition/myNavCache (Phase 3),
    // newShepherd/remember (persistence, Phase 6), and the fulltrace back-reference
    // on BranchDescription (DagWood mediates all operations instead).
    pub fn new() -> Self {
        let mut branches = BranchStore::new();
        let trunk = HashMap::new();

        let (root_branch_id, root_pos) = branches.create_root();
        let root = root_pos;

        let mut dagwood = DagWood {
            branches,
            root,
            trunk,
        };

        // [Original] "Ensure that no elements get allocated on the root branch."
        // Source: dagwoodx.cxx line 164-165
        //
        // This calls myRoot->newSuccessor() which triggers createAfter.
        // Since root_branch.last_position (2) != root.position (1), it forks:
        // creates a TreeBranch(parent=root), installs it in trunk, extends it once.
        // The returned position is discarded in the original.
        let _ = dagwood.create_after(root_branch_id, root);

        dagwood
    }

    // [Adapted from Original] DagWood::root()
    // Source: dagwoodx.cxx lines 76-78
    pub fn root(&self) -> TracePosition {
        self.root
    }

    // [Adapted from Original] DagWood::newPosition()
    // Source: dagwoodx.cxx lines 126-132
    // [Original] "This should really create a new root, but that's harder to draw!"
    pub fn new_position(&mut self) -> TracePosition {
        self.create_after(self.root.branch(), self.root)
    }

    // [Adapted from Original] BranchDescription::createAfter()
    // Source: branchx.cxx lines 137-159
    //
    // "Return a new successor to the receiver. The first successor is on the
    // same branch with a higher position. Further successors are allocated in
    // a binary-tree fashion along a new branch."
    //
    // [New Migration Comment] The original wrapped this in BEGIN_CONSISTENT(14)
    // (tracepx.cxx:167) — a retry loop for optimistic concurrency. We make the
    // operation deterministic by construction and omit the retry. The setbranch()
    // debug call at line 166 is also excluded (debug residue identified in Step 1).
    fn create_after(&mut self, branch_id: BranchId, trace: TracePosition) -> TracePosition {
        let last_pos = self.branches.get(branch_id).unwrap().last_position;

        if last_pos == trace.position() {
            // Extend same branch
            self.branches.next_position(branch_id).unwrap()
        } else {
            // Fork: create new TreeBranch anchored at trace
            let (new_branch_id, _) = self.branches.create_tree(trace);
            self.install_branch_after(new_branch_id, trace);
            self.branches.next_position(new_branch_id).unwrap()
        }
    }

    // [Adapted from Original] DagWood::installBranchAfter()
    // Source: dagwoodx.cxx lines 107-123
    //
    // "Lookup the anchorTrace to find the branch hanging off it. If there isn't
    // one, then install branch as that branch. Otherwise walk a balanced walk
    // down the binary tree of branches to find a place to hang the new branch."
    fn install_branch_after(&mut self, branch_id: BranchId, anchor: TracePosition) {
        if let Some(&existing_id) = self.trunk.get(&anchor) {
            // Existing branch at this anchor — insert into its binary tree
            self.branches
                .install_branch(existing_id, branch_id)
                .unwrap();
        } else {
            // No branch yet — install directly in trunk
            self.trunk.insert(anchor, branch_id);
        }
    }

    // Expose internal state for testing only.
    #[cfg(test)]
    pub fn branches(&self) -> &BranchStore {
        &self.branches
    }

    #[cfg(test)]
    pub fn trunk(&self) -> &HashMap<TracePosition, BranchId> {
        &self.trunk
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ent::branch::BranchKind;

    // D1: constructor_root_is_position_1
    #[test]
    fn constructor_root_is_position_1() {
        let dw = DagWood::new();
        let root = dw.root();
        assert_eq!(root.position(), 1);

        let root_branch = dw.branches().get(root.branch()).unwrap();
        assert!(matches!(root_branch.kind, BranchKind::Root));
    }

    // D2: constructor_creates_one_trunk_entry
    #[test]
    fn constructor_creates_one_trunk_entry() {
        let dw = DagWood::new();
        let root = dw.root();

        assert_eq!(dw.trunk().len(), 1);
        let trunk_branch_id = dw.trunk().get(&root).unwrap();
        let trunk_branch = dw.branches().get(*trunk_branch_id).unwrap();

        match &trunk_branch.kind {
            BranchKind::Tree { parent } => {
                assert_eq!(*parent, root);
            }
            other => panic!("expected Tree branch, got {:?}", other),
        }
    }

    // D3: constructor_initial_branch_at_position_3
    #[test]
    fn constructor_initial_branch_at_position_3() {
        let dw = DagWood::new();
        let root = dw.root();
        let trunk_branch_id = dw.trunk().get(&root).unwrap();
        let trunk_branch = dw.branches().get(*trunk_branch_id).unwrap();
        // The constructor called create_after which forked and then called
        // next_position, incrementing last_position from 2 to 3.
        assert_eq!(trunk_branch.last_position, 3);
    }

    // D4: new_position_returns_position_3
    #[test]
    fn new_position_returns_position_3() {
        let mut dw = DagWood::new();
        let pos = dw.new_position();
        assert_eq!(pos.position(), 3);
    }

    // D5: new_position_creates_distinct_branches
    #[test]
    fn new_position_creates_distinct_branches() {
        let mut dw = DagWood::new();
        let p1 = dw.new_position();
        let p2 = dw.new_position();
        let p3 = dw.new_position();

        assert_eq!(p1.position(), 3);
        assert_eq!(p2.position(), 3);
        assert_eq!(p3.position(), 3);

        // Each call forks a new TreeBranch
        assert_ne!(p1.branch(), p2.branch());
        assert_ne!(p2.branch(), p3.branch());
        assert_ne!(p1.branch(), p3.branch());
    }

    // D6: new_position_populates_branch_tree
    #[test]
    fn new_position_populates_branch_tree() {
        let mut dw = DagWood::new();
        let root = dw.root();

        dw.new_position();
        dw.new_position();
        dw.new_position();

        // After 3 new_position calls beyond the constructor, the binary tree
        // rooted at the trunk entry should have grown.
        let trunk_branch_id = *dw.trunk().get(&root).unwrap();
        let trunk_branch = dw.branches().get(trunk_branch_id).unwrap();

        // The binary tree should have sub-branches (left or right populated)
        assert!(
            trunk_branch.left.is_some() || trunk_branch.right.is_some(),
            "expected binary tree to have grown after multiple new_position calls"
        );
    }
}
