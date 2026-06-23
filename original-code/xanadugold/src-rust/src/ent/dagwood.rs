use std::collections::HashMap;

use crate::ent::branch::{BranchId, BranchKind, BranchStore};
use crate::ent::trace::TracePosition;

// [Original] "Each dagwood defines a partial ordering of TracePositions."
// Source: dagwoodx.hxx class comment (line 82-85)
//
// [Adapted from Original] Field mapping from DagWood (dagwoodx.hxx):
//   myRoot          → root (TracePosition)
//   myTrunk         → trunk (HashMap<TracePosition, BranchId>)
//   myCachedPosition → cached_position (Option<TracePosition>)
//   myNavCache       → nav_cache (HashMap<BranchId, u32>)
//
// [Phase 3] Navigation cache implements the ordering algorithm from
// tracepx.cxx/branchx.cxx. The cache maps BranchId → max reachable
// position from a fixed reference position, computed by upward traversal
// through branch parent links.
#[derive(Debug)]
pub struct DagWood {
    branches: BranchStore,
    root: TracePosition,
    trunk: HashMap<TracePosition, BranchId>,
    cached_position: Option<TracePosition>,
    nav_cache: HashMap<BranchId, u32>,
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
    pub fn new() -> Self {
        let mut branches = BranchStore::new();
        let trunk = HashMap::new();

        let (root_branch_id, root_pos) = branches.create_root();
        let root = root_pos;

        let mut dagwood = DagWood {
            branches,
            root,
            trunk,
            cached_position: None,
            nav_cache: HashMap::new(),
        };

        // [Original] "Ensure that no elements get allocated on the root branch."
        // Source: dagwoodx.cxx line 164-165
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

    // [Adapted from Original] BoundedTrace::newSuccessor
    // Source: tracepx.cxx lines 155-172
    //
    // "Return a new successor to the receiver. The first successor is on the
    // same branch with a higher position. Further successors are allocated
    // in a binary-tree fashion along a new branch."
    pub fn new_position_after(&mut self, after: TracePosition) -> TracePosition {
        self.create_after(after.branch(), after)
    }

    // [Adapted from Original] BoundedTrace::newSuccessorAfter
    // Source: tracepx.cxx lines 175-193
    //
    // "Return a new tracePosition that is after both the receiver and tracePos."
    // Creates a DagBranch (merge point) with two parents.
    pub fn new_successor_after(&mut self, a: TracePosition, b: TracePosition) -> TracePosition {
        let (dag_branch_id, _) = self.branches.create_dag(a, b);
        self.install_branch_after(dag_branch_id, a);
        self.install_branch_after(dag_branch_id, b);
        self.branches.next_position(dag_branch_id).unwrap()
    }

    // [Adapted from Original] BoundedTrace::isLE
    // Source: tracepx.cxx lines 119-128
    //
    // "Return true if the two positions are comparable and the receiver is
    // less than the argument."
    //
    // A.isLE(B): cache B's upward reachability, then check if A's branch
    // is reachable from B with A.position <= cached max.
    //
    // Delegates to BranchDescription::doesInclude via the navigation cache.
    // Source: branchx.cxx lines 90-104
    pub fn is_le(&mut self, a: TracePosition, b: TracePosition) -> bool {
        self.cache_trace_pos(b);
        match self.nav_cache.get(&a.branch()) {
            Some(&mark) => a.position() <= mark,
            None => false,
        }
    }

    // [Adapted from Original] DagWood::cacheTracePos
    // Source: dagwoodx.cxx lines 136-155
    //
    // "Install the supplied branch and position as the navCache and return it."
    //
    // Reuses cache if reference position unchanged; otherwise clears and
    // rebuilds. The original comment: "many comparisons IN THE SAME ORDER
    // will occur very fast."
    fn cache_trace_pos(&mut self, pos: TracePosition) {
        if self.cached_position == Some(pos) {
            return;
        }
        self.cached_position = Some(pos);
        self.nav_cache.clear();
        Self::cache_in_into(&self.branches, pos, &mut self.nav_cache);
    }

    // [Adapted from Original] BoundedTrace::cacheIn
    // Source: tracepx.cxx lines 139-151
    //
    // "Cache the nav-data for the receiver in navCache."
    //
    // For a position (branch, pos):
    // - If branch not yet visited (None in cache): store pos, recurse to parents
    // - If already visited: update to max(old, pos), no recursion
    //
    // The max-on-revisit is the "max of all paths" invariant for DAG convergence.
    //
    // Takes &BranchStore instead of &self so TraceView can build its own cache.
    fn cache_in_into(
        branches: &BranchStore,
        pos: TracePosition,
        cache: &mut HashMap<BranchId, u32>,
    ) {
        match cache.get(&pos.branch()).copied() {
            None => {
                cache.insert(pos.branch(), pos.position());
                Self::cache_recur_into(branches, pos.branch(), cache);
            }
            Some(old) => {
                let new_val = old.max(pos.position());
                cache.insert(pos.branch(), new_val);
            }
        }
    }

    // [Adapted from Original] RootBranch/TreeBranch/DagBranch::cacheRecur
    // Source: branchx.cxx
    //   RootBranch::cacheRecur  (lines 299-303): "The recursion ends here."
    //   TreeBranch::cacheRecur  (lines 326-328): parent->cacheIn(navCache)
    //   DagBranch::cacheRecur   (lines 262-265): parent1 + parent2
    //
    // "Recur toward the root filling in the cache."
    fn cache_recur_into(
        branches: &BranchStore,
        branch_id: BranchId,
        cache: &mut HashMap<BranchId, u32>,
    ) {
        let kind = branches.get(branch_id).unwrap().kind.clone();
        match kind {
            BranchKind::Root => {}
            BranchKind::Tree { parent } => {
                Self::cache_in_into(branches, parent, cache);
            }
            BranchKind::Dag { parent1, parent2 } => {
                Self::cache_in_into(branches, parent1, cache);
                Self::cache_in_into(branches, parent2, cache);
            }
        }
    }

    // [Adapted from Original] BranchDescription::createAfter()
    // Source: branchx.cxx lines 137-159
    fn create_after(&mut self, branch_id: BranchId, trace: TracePosition) -> TracePosition {
        let last_pos = self.branches.get(branch_id).unwrap().last_position;

        if last_pos == trace.position() {
            self.branches.next_position(branch_id).unwrap()
        } else {
            let (new_branch_id, _) = self.branches.create_tree(trace);
            self.install_branch_after(new_branch_id, trace);
            self.branches.next_position(new_branch_id).unwrap()
        }
    }

    // [Adapted from Original] DagWood::installBranchAfter()
    // Source: dagwoodx.cxx lines 107-123
    fn install_branch_after(&mut self, branch_id: BranchId, anchor: TracePosition) {
        if let Some(&existing_id) = self.trunk.get(&anchor) {
            self.branches
                .install_branch(existing_id, branch_id)
                .unwrap();
        } else {
            self.trunk.insert(anchor, branch_id);
        }
    }

    // [Adapted from Original] BoundedTrace::successors →
    // BranchDescription::successorsOf → DagWood::successorsOf +
    // BranchDescription::addSuccessorsTo
    // Source: branchx.cxx lines 109-133, dagwoodx.cxx lines 89-103
    //
    // Returns immediate successors of pos:
    //   - Next position on same branch (if not at last position)
    //   - Position 3 of every branch forked off from pos (via trunk map)
    pub fn successors(&self, pos: TracePosition) -> Vec<TracePosition> {
        let mut result = Vec::new();

        if let Ok(branch) = self.branches.get(pos.branch()) {
            if pos.position() != branch.last_position {
                result.push(TracePosition::new(pos.branch(), pos.position() + 1));
            }
        }

        if let Some(&trunk_branch_id) = self.trunk.get(&pos) {
            self.collect_branch_successors(trunk_branch_id, &mut result);
        }

        result
    }

    // [Adapted from Original] BranchDescription::addSuccessorsTo
    // Source: branchx.cxx lines 109-120
    //
    // Walk the binary tree of branches, collecting position 3 (the first
    // usable position) of each branch.
    fn collect_branch_successors(&self, branch_id: BranchId, result: &mut Vec<TracePosition>) {
        result.push(TracePosition::new(branch_id, 3));
        if let Ok(branch) = self.branches.get(branch_id) {
            if let Some(left) = branch.left {
                self.collect_branch_successors(left, result);
            }
            if let Some(right) = branch.right {
                self.collect_branch_successors(right, result);
            }
        }
    }

    // Build a TraceView — a snapshot of what's visible from a reference position.
    // The view owns its own navigation cache, independent of DagWood's internal cache.
    pub fn trace_view(&self, reference: TracePosition) -> TraceView {
        TraceView::new(&self.branches, reference)
    }

    #[cfg(test)]
    pub fn branches(&self) -> &BranchStore {
        &self.branches
    }

    #[cfg(test)]
    pub fn trunk(&self) -> &HashMap<TracePosition, BranchId> {
        &self.trunk
    }

    #[cfg(test)]
    pub fn cached_position(&self) -> Option<TracePosition> {
        self.cached_position
    }

    #[cfg(test)]
    pub fn nav_cache(&self) -> &HashMap<BranchId, u32> {
        &self.nav_cache
    }
}

// [Phase 4] A frozen snapshot of visibility from a single reference position.
// Owns its own navigation cache, independent of DagWood's mutable internal cache.
//
// Semantics: for each branch reachable from the reference via upward traversal
// through parent links, the cache stores the maximum position on that branch
// that is historically included in the reference. A position P is "visible"
// from the reference iff P's branch is in the cache AND P.position <= cache[P.branch].
//
// This is the read face of the Ent ordering — downstream content layers
// (H-tree, canopy, etc.) use this to decide what data to show.
pub struct TraceView {
    reference: TracePosition,
    nav_cache: HashMap<BranchId, u32>,
}

impl TraceView {
    pub fn new(branches: &BranchStore, reference: TracePosition) -> Self {
        let mut nav_cache = HashMap::new();
        DagWood::cache_in_into(branches, reference, &mut nav_cache);
        TraceView {
            reference,
            nav_cache,
        }
    }

    pub fn reference(&self) -> TracePosition {
        self.reference
    }

    // A position is visible from the reference iff it falls within the
    // reference's historical cone: same semantics as DagWood::is_le.
    pub fn is_visible(&self, pos: TracePosition) -> bool {
        match self.nav_cache.get(&pos.branch()) {
            Some(&mark) => pos.position() <= mark,
            None => false,
        }
    }

    // The maximum position visible on a branch from the reference, or None
    // if the branch is not reachable.
    pub fn visible_max(&self, branch_id: BranchId) -> Option<u32> {
        self.nav_cache.get(&branch_id).copied()
    }

    // All branches reachable from the reference, with their max positions.
    pub fn visible_branches(&self) -> impl Iterator<Item = (BranchId, u32)> + '_ {
        self.nav_cache.iter().map(|(&b, &p)| (b, p))
    }

    pub fn branch_count(&self) -> usize {
        self.nav_cache.len()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

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

        let trunk_branch_id = *dw.trunk().get(&root).unwrap();
        let trunk_branch = dw.branches().get(trunk_branch_id).unwrap();

        assert!(
            trunk_branch.left.is_some() || trunk_branch.right.is_some(),
            "expected binary tree to have grown after multiple new_position calls"
        );
    }

    // D7: same_branch_monotonic_ordering
    #[test]
    fn same_branch_monotonic_ordering() {
        let mut dw = DagWood::new();
        let p1 = dw.new_position();
        let p2 = dw.new_position_after(p1);
        let p3 = dw.new_position_after(p2);

        assert!(dw.is_le(p1, p2));
        assert!(dw.is_le(p2, p3));
        assert!(dw.is_le(p1, p3));
        assert!(!dw.is_le(p2, p1));
        assert!(!dw.is_le(p3, p1));
        assert!(!dw.is_le(p3, p2));
    }

    // D8: reflexivity
    #[test]
    fn reflexivity() {
        let mut dw = DagWood::new();
        let p = dw.new_position();
        assert!(dw.is_le(p, p));

        let root = dw.root();
        assert!(dw.is_le(root, root));
    }

    // D9: antisymmetry
    #[test]
    fn antisymmetry() {
        let mut dw = DagWood::new();
        let p1 = dw.new_position();
        let p2 = dw.new_position_after(p1);

        assert!(dw.is_le(p1, p2));
        assert!(!dw.is_le(p2, p1));
        assert_ne!(p1, p2);
    }

    // D10: simple fork ancestry
    #[test]
    fn simple_fork_ancestry() {
        let mut dw = DagWood::new();
        let root = dw.root();
        let a = dw.new_position();
        let b = dw.new_position();

        assert!(dw.is_le(root, a));
        assert!(dw.is_le(root, b));
        assert!(!dw.is_le(a, b));
        assert!(!dw.is_le(b, a));
        assert!(!dw.is_le(a, root));
        assert!(!dw.is_le(b, root));
    }

    // D11: deeper ancestry
    #[test]
    fn deeper_ancestry() {
        let mut dw = DagWood::new();
        let a = dw.new_position();
        let b = dw.new_position_after(a);
        let _ext = dw.new_position_after(b);
        let c = dw.new_position_after(b);

        assert!(dw.is_le(a, c));
        assert!(dw.is_le(b, c));
        assert!(!dw.is_le(c, a));
        assert!(!dw.is_le(c, b));
    }

    // D12: simple merge ancestry
    #[test]
    fn simple_merge_ancestry() {
        let mut dw = DagWood::new();
        let root = dw.root();
        let a = dw.new_position();
        let b = dw.new_position();
        let merged = dw.new_successor_after(a, b);

        assert!(dw.is_le(a, merged));
        assert!(dw.is_le(b, merged));
        assert!(dw.is_le(root, merged));
        assert!(!dw.is_le(merged, a));
        assert!(!dw.is_le(merged, b));
    }

    // D13: max_over_paths — critical DAG convergence test
    #[test]
    fn max_over_paths() {
        let mut dw = DagWood::new();

        let x3 = dw.new_position();
        let x4 = dw.new_position_after(x3);
        let y3 = dw.new_position_after(x3);
        let _x5 = dw.new_position_after(x4);
        let z3 = dw.new_position_after(x4);
        let w3 = dw.new_successor_after(y3, z3);

        let trunk = x3.branch();
        let tp3 = TracePosition::new(trunk, 3);
        let tp4 = TracePosition::new(trunk, 4);
        let tp5 = TracePosition::new(trunk, 5);

        assert!(dw.is_le(tp3, w3));
        assert!(dw.is_le(tp4, w3));
        assert!(!dw.is_le(tp5, w3));
    }

    // D14: merge preserves parent incomparability
    #[test]
    fn merge_preserves_parent_incomparability() {
        let mut dw = DagWood::new();
        let a = dw.new_position();
        let b = dw.new_position();
        let _merged = dw.new_successor_after(a, b);

        assert!(!dw.is_le(a, b));
        assert!(!dw.is_le(b, a));
    }

    // D15: diverged descendants incomparable
    #[test]
    fn diverged_descendants_incomparable() {
        let mut dw = DagWood::new();
        let a = dw.new_position();
        let _a2 = dw.new_position_after(a);
        let b = dw.new_position_after(a);
        let c = dw.new_position_after(a);

        assert!(dw.is_le(a, b));
        assert!(dw.is_le(a, c));
        assert!(!dw.is_le(b, c));
        assert!(!dw.is_le(c, b));
    }

    // D16: cache reuse
    #[test]
    fn cache_reuse_same_reference() {
        let mut dw = DagWood::new();
        let a = dw.new_position();
        let b = dw.new_position();
        let c = dw.new_position();

        assert!(!dw.is_le(c, b));
        assert_eq!(dw.cached_position(), Some(b));

        assert!(!dw.is_le(a, b));
        assert_eq!(dw.cached_position(), Some(b));
    }

    // D17: cache invalidation
    #[test]
    fn cache_invalidation_new_reference() {
        let mut dw = DagWood::new();
        let a = dw.new_position();
        let b = dw.new_position();
        let c = dw.new_position();

        assert!(!dw.is_le(a, b));
        assert_eq!(dw.cached_position(), Some(b));
        let cache_for_b = dw.nav_cache().clone();

        assert!(!dw.is_le(a, c));
        assert_eq!(dw.cached_position(), Some(c));
        assert_ne!(dw.nav_cache(), &cache_for_b);
    }

    // D18: root ancestor of all
    #[test]
    fn root_ancestor_of_all() {
        let mut dw = DagWood::new();
        let root = dw.root();
        let a = dw.new_position();
        let b = dw.new_position();
        let c = dw.new_position_after(a);
        let d = dw.new_successor_after(a, b);

        assert!(dw.is_le(root, a));
        assert!(dw.is_le(root, b));
        assert!(dw.is_le(root, c));
        assert!(dw.is_le(root, d));
    }

    // D19: no phantom ordering
    #[test]
    fn no_phantom_ordering() {
        let mut dw = DagWood::new();
        let a = dw.new_position();
        let b = dw.new_position();
        let c = dw.new_position();

        assert!(!dw.is_le(a, b));
        assert!(!dw.is_le(b, a));
        assert!(!dw.is_le(a, c));
        assert!(!dw.is_le(c, a));
        assert!(!dw.is_le(b, c));
        assert!(!dw.is_le(c, b));

        assert!(dw.is_le(a, a));
        assert!(dw.is_le(b, b));
        assert!(dw.is_le(c, c));
    }

    // D20: transitivity
    #[test]
    fn transitivity() {
        let mut dw = DagWood::new();
        let a = dw.new_position();
        let b = dw.new_position_after(a);
        let c = dw.new_position_after(b);

        assert!(dw.is_le(a, b));
        assert!(dw.is_le(b, c));
        assert!(dw.is_le(a, c));
    }

    // D21: cross_branch transitivity
    #[test]
    fn cross_branch_transitivity() {
        let mut dw = DagWood::new();
        let root = dw.root();
        let a = dw.new_position();
        let b = dw.new_position_after(a);
        let _ext = dw.new_position_after(b);
        let c = dw.new_position_after(b);

        assert!(dw.is_le(root, a));
        assert!(dw.is_le(a, b));
        assert!(dw.is_le(root, c));
        assert!(dw.is_le(b, c));
        assert!(dw.is_le(a, c));
    }

    // === Gap-closure tests (D22–D25) ===
    //
    // These address three subtle areas often missed at this stage:
    //   Gap 1: max-over-paths must be verified at the cache level, not
    //          just at the ordering-result level.
    //   Gap 2: cached is_le must equal a from-scratch recomputation for
    //          every pair in a complex graph.
    //   Gap 3: ancestry must propagate correctly through multiple layers
    //          of DAG merge.

    // -- Reference (no-cache) implementation for gap 2 --

    fn compute_reachable(
        store: &BranchStore,
        pos: TracePosition,
        visited: &mut std::collections::HashMap<BranchId, u32>,
    ) {
        match visited.get(&pos.branch()).copied() {
            None => {
                visited.insert(pos.branch(), pos.position());
                let kind = store.get(pos.branch()).unwrap().kind.clone();
                match kind {
                    BranchKind::Root => {}
                    BranchKind::Tree { parent } => {
                        compute_reachable(store, parent, visited);
                    }
                    BranchKind::Dag { parent1, parent2 } => {
                        compute_reachable(store, parent1, visited);
                        compute_reachable(store, parent2, visited);
                    }
                }
            }
            Some(old) => {
                let new_val = old.max(pos.position());
                visited.insert(pos.branch(), new_val);
            }
        }
    }

    fn is_le_no_cache(dw: &DagWood, a: TracePosition, b: TracePosition) -> bool {
        let mut visited = std::collections::HashMap::new();
        compute_reachable(dw.branches(), b, &mut visited);
        match visited.get(&a.branch()) {
            Some(&mark) => a.position() <= mark,
            None => false,
        }
    }

    // D22: dag_convergence_cache_value — directly inspect cache after
    // DAG convergence to verify max-over-paths at the cache level.
    //
    // Structure:
    //   trunk: root → pos3 → pos4 → pos5
    //   fork from pos3 → Y
    //   fork from pos4 → Z
    //   merge Y, Z → W
    //
    // Path Y→trunk enters at position 3; path Z→trunk enters at position 4.
    // Cache[trunk] must be max(3,4) == 4.
    #[test]
    fn dag_convergence_cache_value() {
        let mut dw = DagWood::new();

        let x3 = dw.new_position();
        let x4 = dw.new_position_after(x3);
        let y3 = dw.new_position_after(x3);
        let _x5 = dw.new_position_after(x4);
        let z3 = dw.new_position_after(x4);
        let w3 = dw.new_successor_after(y3, z3);

        let _ = dw.is_le(TracePosition::new(x3.branch(), 1), w3);

        let cache = dw.nav_cache();
        let trunk = x3.branch();
        assert_eq!(
            cache.get(&trunk),
            Some(&4),
            "cache[trunk] must be max(3,4)=4"
        );
        assert_eq!(cache.get(&y3.branch()), Some(&3));
        assert_eq!(cache.get(&z3.branch()), Some(&3));
        assert!(cache.get(&w3.branch()).is_some());

        let tp4 = TracePosition::new(trunk, 4);
        let tp5 = TracePosition::new(trunk, 5);
        assert!(
            dw.is_le(tp4, w3),
            "position 4 must be included (4 <= cache=4)"
        );
        assert!(
            !dw.is_le(tp5, w3),
            "position 5 must NOT be included (5 > cache=4)"
        );
    }

    // D23: deep_dag_multi_merge — ancestry through multiple merge layers.
    //
    // Structure:
    //        root
    //         |
    //         A
    //        / \
    //       B   C
    //        \ /
    //         D  (merge 1)
    //         |
    //         E
    //        / \
    //       F   G
    //        \ /
    //         H  (merge 2)
    #[test]
    fn deep_dag_multi_merge() {
        let mut dw = DagWood::new();
        let root = dw.root();

        let a = dw.new_position();
        let _ext_a = dw.new_position_after(a);
        let b = dw.new_position_after(a);
        let c = dw.new_position_after(a);
        let d = dw.new_successor_after(b, c);
        let e = dw.new_position_after(d);
        let _ext_e = dw.new_position_after(e);
        let f = dw.new_position_after(e);
        let g = dw.new_position_after(e);
        let h = dw.new_successor_after(f, g);

        assert!(dw.is_le(root, h));
        assert!(dw.is_le(a, h));
        assert!(dw.is_le(b, h));
        assert!(dw.is_le(c, h));
        assert!(dw.is_le(d, h));
        assert!(dw.is_le(e, h));
        assert!(dw.is_le(f, h));
        assert!(dw.is_le(g, h));

        assert!(!dw.is_le(h, root));
        assert!(!dw.is_le(h, a));
        assert!(!dw.is_le(h, d));
        assert!(!dw.is_le(h, e));

        assert!(!dw.is_le(b, c));
        assert!(!dw.is_le(c, b));
        assert!(!dw.is_le(f, g));
        assert!(!dw.is_le(g, f));

        assert!(dw.is_le(h, h));
    }

    // D24: cache_equals_recomputed_simple — property test on a simple graph.
    // For every pair of positions, cached is_le must equal no-cache is_le.
    #[test]
    fn cache_equals_recomputed_simple() {
        let mut dw = DagWood::new();
        let root = dw.root();
        let a = dw.new_position();
        let b = dw.new_position();
        let merged = dw.new_successor_after(a, b);

        let positions = vec![root, a, b, merged];
        for x in &positions {
            for y in &positions {
                let cached = dw.is_le(*x, *y);
                let uncached = is_le_no_cache(&dw, *x, *y);
                assert_eq!(cached, uncached, "cache mismatch: is_le({:?}, {:?})", x, y);
            }
        }
    }

    // D25: cache_equals_recomputed_deep — property test on the deep
    // multi-merge graph from D23. Every pair checked.
    #[test]
    fn cache_equals_recomputed_deep() {
        let mut dw = DagWood::new();
        let root = dw.root();

        let a = dw.new_position();
        let _ext_a = dw.new_position_after(a);
        let b = dw.new_position_after(a);
        let c = dw.new_position_after(a);
        let d = dw.new_successor_after(b, c);
        let e = dw.new_position_after(d);
        let _ext_e = dw.new_position_after(e);
        let f = dw.new_position_after(e);
        let g = dw.new_position_after(e);
        let h = dw.new_successor_after(f, g);

        let positions = vec![root, a, b, c, d, e, f, g, h];
        for x in &positions {
            for y in &positions {
                let cached = dw.is_le(*x, *y);
                let uncached = is_le_no_cache(&dw, *x, *y);
                assert_eq!(cached, uncached, "cache mismatch: is_le({:?}, {:?})", x, y);
            }
        }
    }

    // =====================================================================
    // Phase 3.5 — Property-based testing and stress tests (D26–D33)
    // =====================================================================

    // -- Deterministic PRNG (xorshift64) for reproducible DAG generation --

    struct Prng {
        state: u64,
    }

    impl Prng {
        fn new(seed: u64) -> Self {
            Prng {
                state: if seed == 0 { 1 } else { seed },
            }
        }

        fn next_u64(&mut self) -> u64 {
            self.state ^= self.state << 13;
            self.state ^= self.state >> 7;
            self.state ^= self.state << 17;
            self.state
        }

        fn next_usize(&mut self, n: usize) -> usize {
            (self.next_u64() as usize) % n.max(1)
        }
    }

    struct GeneratedDag {
        dw: DagWood,
        positions: Vec<TracePosition>,
    }

    // Build a random DAG with `ops` operations from a seeded PRNG.
    // Operations: 40% fork/extend, 30% root fork, 30% merge.
    // positions[0] is always the root.
    fn generate_dag(seed: u64, ops: usize) -> GeneratedDag {
        let mut rng = Prng::new(seed);
        let mut dw = DagWood::new();
        let mut positions = vec![dw.root()];

        for _ in 0..ops {
            let op = rng.next_usize(10);
            if op < 4 {
                let idx = rng.next_usize(positions.len());
                let pos = dw.new_position_after(positions[idx]);
                positions.push(pos);
            } else if op < 7 {
                positions.push(dw.new_position());
            } else if positions.len() >= 2 {
                let i = rng.next_usize(positions.len());
                let j = rng.next_usize(positions.len());
                if i != j {
                    let pos = dw.new_successor_after(positions[i], positions[j]);
                    positions.push(pos);
                }
            }
        }

        GeneratedDag { dw, positions }
    }

    // D26: property_reflexivity — A <= A for every position in random DAGs.
    #[test]
    fn property_reflexivity() {
        for seed in [42u64, 137, 999, 2024, 31415] {
            let mut dag = generate_dag(seed, 30);
            for &p in &dag.positions {
                assert!(dag.dw.is_le(p, p), "reflexivity failed (seed={})", seed);
            }
        }
    }

    // D27: property_antisymmetry — A<=B and B<=A implies A==B.
    #[test]
    fn property_antisymmetry() {
        for seed in [42u64, 137, 999, 2024, 31415] {
            let mut dag = generate_dag(seed, 25);
            let n = dag.positions.len();
            for i in 0..n {
                for j in 0..n {
                    let a = dag.positions[i];
                    let b = dag.positions[j];
                    if dag.dw.is_le(a, b) && dag.dw.is_le(b, a) {
                        assert_eq!(a, b, "antisymmetry failed (seed={}): [{},{}]", seed, i, j);
                    }
                }
            }
        }
    }

    // D28: property_transitivity — A<=B and B<=C implies A<=C.
    #[test]
    fn property_transitivity() {
        for seed in [42u64, 137, 999, 2024, 31415] {
            let mut dag = generate_dag(seed, 20);
            let n = dag.positions.len();
            for i in 0..n {
                for j in 0..n {
                    for k in 0..n {
                        let a = dag.positions[i];
                        let b = dag.positions[j];
                        let c = dag.positions[k];
                        if dag.dw.is_le(a, b) && dag.dw.is_le(b, c) {
                            assert!(
                                dag.dw.is_le(a, c),
                                "transitivity failed (seed={}): [{},{},{}]",
                                seed,
                                i,
                                j,
                                k
                            );
                        }
                    }
                }
            }
        }
    }

    // D29: property_cache_equivalence — cached is_le matches from-scratch
    // recomputation for every pair in multiple random DAGs.
    #[test]
    fn property_cache_equivalence() {
        for seed in [42u64, 137, 999, 2024, 31415] {
            let mut dag = generate_dag(seed, 25);
            let n = dag.positions.len();
            for i in 0..n {
                for j in 0..n {
                    let a = dag.positions[i];
                    let b = dag.positions[j];
                    let cached = dag.dw.is_le(a, b);
                    let uncached = is_le_no_cache(&dag.dw, a, b);
                    assert_eq!(
                        cached, uncached,
                        "cache mismatch (seed={}): [{},{}]",
                        seed, i, j
                    );
                }
            }
        }
    }

    // D30: stress_deep_linear_chain — 200 positions on one branch.
    #[test]
    fn stress_deep_linear_chain() {
        let mut dw = DagWood::new();
        let mut positions = vec![dw.new_position()];
        for _ in 1..200 {
            let last = *positions.last().unwrap();
            positions.push(dw.new_position_after(last));
        }

        assert!(dw.is_le(positions[0], positions[199]));
        assert!(!dw.is_le(positions[199], positions[0]));
        assert!(dw.is_le(positions[0], positions[1]));

        let indices: Vec<usize> = (0..200).step_by(10).collect();
        for &i in &indices {
            for &j in &indices {
                let cached = dw.is_le(positions[i], positions[j]);
                let uncached = is_le_no_cache(&dw, positions[i], positions[j]);
                assert_eq!(cached, uncached, "chain [{}, {}]", i, j);
            }
        }
    }

    // D31: stress_wide_fork_tree — 100 root forks, pairwise incomparable.
    #[test]
    fn stress_wide_fork_tree() {
        let mut dw = DagWood::new();
        let mut children = Vec::new();
        for _ in 0..100 {
            children.push(dw.new_position());
        }

        let root = dw.root();
        for &child in &children {
            assert!(dw.is_le(root, child));
            assert!(!dw.is_le(child, root));
        }

        for i in 0..20 {
            for j in (i + 1)..20 {
                assert!(!dw.is_le(children[i], children[j]));
                assert!(!dw.is_le(children[j], children[i]));
            }
        }
    }

    // D32: stress_repeated_merges — chain of 50 merge-extend cycles.
    #[test]
    fn stress_repeated_merges() {
        let mut dw = DagWood::new();
        let root = dw.root();
        let mut positions = vec![dw.new_position(), dw.new_position()];

        for _ in 0..50 {
            let a = positions[positions.len() - 2];
            let b = positions[positions.len() - 1];
            let merged = dw.new_successor_after(a, b);
            let extended = dw.new_position_after(merged);
            positions.push(extended);
        }

        for &p in &positions {
            assert!(dw.is_le(root, p));
        }

        let n = positions.len();
        for i in (0..n).step_by(5) {
            for j in (0..n).step_by(5) {
                let cached = dw.is_le(positions[i], positions[j]);
                let uncached = is_le_no_cache(&dw, positions[i], positions[j]);
                assert_eq!(cached, uncached, "merge stress [{}, {}]", i, j);
            }
        }
    }

    // D33: stress_heavy_cache_reuse — 1000 comparisons against same reference.
    #[test]
    fn stress_heavy_cache_reuse() {
        let mut dw = DagWood::new();
        let mut positions = vec![dw.root()];
        for _ in 0..50 {
            positions.push(dw.new_position());
        }

        let reference = positions[25];
        let expected: Vec<bool> = positions
            .iter()
            .map(|&p| is_le_no_cache(&dw, p, reference))
            .collect();

        for _ in 0..20 {
            for (i, &p) in positions.iter().enumerate() {
                assert_eq!(
                    dw.is_le(p, reference),
                    expected[i],
                    "cache reuse corrupted at {}",
                    i
                );
            }
        }

        assert_eq!(dw.cached_position(), Some(reference));
    }

    // =====================================================================
    // Phase 4 — Successor traversal and TraceView tests (S1–S7, V1–V6)
    // =====================================================================

    // S1: same_branch_successor — next position on same branch.
    #[test]
    fn same_branch_successor() {
        let mut dw = DagWood::new();
        let p1 = dw.new_position();
        let _p2 = dw.new_position_after(p1);
        let succs = dw.successors(p1);
        assert_eq!(succs, vec![TracePosition::new(p1.branch(), 4)]);
    }

    // S2: no_same_branch_successor_at_tip.
    #[test]
    fn no_same_branch_successor_at_tip() {
        let mut dw = DagWood::new();
        let p1 = dw.new_position();
        let succs = dw.successors(p1);
        assert!(!succs.iter().any(|s| s.branch() == p1.branch()));
    }

    // S3: cross_branch_successors from trunk map.
    #[test]
    fn cross_branch_successors() {
        let mut dw = DagWood::new();
        let root = dw.root();
        let _a = dw.new_position();
        let _b = dw.new_position();
        let succs = dw.successors(root);
        let cross_branch: Vec<_> = succs
            .iter()
            .filter(|s| s.branch() != root.branch())
            .collect();
        assert!(
            cross_branch.len() >= 2,
            "root should have cross-branch successors"
        );
        for s in &cross_branch {
            assert_eq!(s.position(), 3);
        }
    }

    // S4: no_cross_branch_successors when nothing forked from position.
    #[test]
    fn no_cross_branch_successors_for_leaf() {
        let mut dw = DagWood::new();
        let p = dw.new_position();
        let succs = dw.successors(p);
        assert!(succs.is_empty());
    }

    // S5: successors_after_fork — same-branch + cross-branch combined.
    #[test]
    fn successors_after_fork() {
        let mut dw = DagWood::new();
        let p1 = dw.new_position();
        let _p2 = dw.new_position_after(p1);
        let p3 = dw.new_position_after(p1);
        let succs = dw.successors(p1);
        assert!(succs.contains(&TracePosition::new(p1.branch(), 4)));
        assert!(succs.contains(&TracePosition::new(p3.branch(), 3)));
    }

    // S6: successors_at_branch_end_with_forks.
    #[test]
    fn successors_at_branch_end_with_forks() {
        let mut dw = DagWood::new();
        let p1 = dw.new_position();
        let _ext = dw.new_position_after(p1);
        let child = dw.new_position_after(p1);
        let succs = dw.successors(p1);
        assert!(succs.contains(&TracePosition::new(child.branch(), 3)));
    }

    // S7: successors_property — every successor S of P satisfies S >= P
    // (i.e., P <= S in the partial order). This is the fundamental
    // consistency check between forward and backward navigation.
    #[test]
    fn successors_are_forward() {
        let mut dw = DagWood::new();
        let mut positions = vec![dw.root(), dw.new_position(), dw.new_position()];
        for _ in 0..10 {
            let idx = positions.len() % positions.len();
            positions.push(dw.new_position_after(positions[idx]));
        }
        let merged = dw.new_successor_after(positions[1], positions[2]);
        positions.push(merged);

        for &p in &positions {
            let succs = dw.successors(p);
            for &s in &succs {
                assert!(dw.is_le(p, s), "{:?} should be <= successor {:?}", p, s);
            }
        }
    }

    // -- TraceView tests --

    // V1: trace_view_matches_is_le.
    #[test]
    fn trace_view_matches_is_le() {
        let mut dw = DagWood::new();
        let root = dw.root();
        let a = dw.new_position();
        let b = dw.new_position();
        let merged = dw.new_successor_after(a, b);

        let view = dw.trace_view(merged);

        assert!(view.is_visible(a));
        assert!(view.is_visible(b));
        assert!(view.is_visible(merged));
        assert!(view.is_visible(root));
        assert!(!dw.trace_view(a).is_visible(b));
        assert!(!dw.trace_view(b).is_visible(a));
    }

    // V2: trace_view_independent_of_internal_cache.
    #[test]
    fn trace_view_independent_of_internal_cache() {
        let mut dw = DagWood::new();
        let a = dw.new_position();
        let b = dw.new_position();

        let _ = dw.is_le(a, b);
        assert_eq!(dw.cached_position(), Some(b));

        let view = dw.trace_view(a);
        assert!(view.is_visible(a));
        assert!(!view.is_visible(b));
    }

    // V3: visible_branches_and_max.
    #[test]
    fn visible_branches_and_max() {
        let mut dw = DagWood::new();
        let root = dw.root();
        let a = dw.new_position();
        let b = dw.new_position();
        let merged = dw.new_successor_after(a, b);

        let view = dw.trace_view(merged);

        assert_eq!(view.visible_max(root.branch()), Some(1));
        assert_eq!(view.visible_max(a.branch()), Some(3));
        assert_eq!(view.visible_max(b.branch()), Some(3));
        assert_eq!(view.visible_max(merged.branch()), Some(3));
        assert_eq!(view.branch_count(), 4);
    }

    // V4: visible_max_returns_none_for_unreachable.
    #[test]
    fn visible_max_none_for_unreachable() {
        let mut dw = DagWood::new();
        let a = dw.new_position();
        let b = dw.new_position();
        let c = dw.new_position_after(a);

        let view = dw.trace_view(c);
        assert_eq!(view.visible_max(b.branch()), None);
    }

    // V5: trace_view_on_deep_dag.
    #[test]
    fn trace_view_on_deep_dag() {
        let mut dw = DagWood::new();
        let root = dw.root();
        let a = dw.new_position();
        let _ext_a = dw.new_position_after(a);
        let b = dw.new_position_after(a);
        let c = dw.new_position_after(a);
        let d = dw.new_successor_after(b, c);
        let e = dw.new_position_after(d);
        let _ext_e = dw.new_position_after(e);
        let f = dw.new_position_after(e);
        let g = dw.new_position_after(e);
        let h = dw.new_successor_after(f, g);

        let view = dw.trace_view(h);

        assert!(view.is_visible(root));
        assert!(view.is_visible(a));
        assert!(view.is_visible(b));
        assert!(view.is_visible(c));
        assert!(view.is_visible(d));
        assert!(view.is_visible(e));
        assert!(view.is_visible(f));
        assert!(view.is_visible(g));
        assert!(view.is_visible(h));
        assert!(!view.is_visible(TracePosition::new(a.branch(), 100)));
    }

    // V6: trace_view_matches_is_le_on_random_dags — property test.
    #[test]
    fn trace_view_matches_is_le_on_random_dags() {
        for seed in [42u64, 137, 999, 2024, 31415] {
            let mut dag = generate_dag(seed, 25);
            let n = dag.positions.len();
            for j in 0..n {
                let reference = dag.positions[j];
                let view = dag.dw.trace_view(reference);
                for i in 0..n {
                    let pos = dag.positions[i];
                    let from_is_le = dag.dw.is_le(pos, reference);
                    let from_view = view.is_visible(pos);
                    assert_eq!(
                        from_is_le, from_view,
                        "TraceView mismatch (seed={}): is_le({:?},{:?})={} but view.is_visible={}",
                        seed, dag.positions[i], reference, from_is_le, from_view
                    );
                }
            }
        }
    }

    // =====================================================================
    // Stress tests (P1, P2, P7, P8, P10)
    // Run with: cargo test --features "serde,serde_json" -- --ignored
    // =====================================================================

    use std::time::Instant;

    fn elapsed(t: Instant) -> String {
        format!("{:.3}s", t.elapsed().as_secs_f64())
    }

    // P1: stress_deep_linear_100k — 100,000 position linear chain.
    // Exercises O(B) cache_in traversal through 100K+ branches.
    // Verifies is_le against brute-force computation for sampled pairs.
    #[test]
    #[ignore]
    fn stress_deep_linear_100k() {
        let t = Instant::now();
        let mut dw = DagWood::new();
        let mut positions = vec![dw.root()];
        let mut tip = dw.new_position();
        positions.push(tip);
        for _ in 1..100_000 {
            tip = dw.new_position_after(tip);
            positions.push(tip);
        }
        eprintln!("  P1 build 100K chain: {}", elapsed(t));

        let first = positions[0];
        let last = *positions.last().unwrap();

        let t2 = Instant::now();
        assert!(dw.is_le(first, last));
        eprintln!("  P1 is_le(first, last): {}", elapsed(t2));

        let t3 = Instant::now();
        assert!(!dw.is_le(last, first));
        eprintln!("  P1 is_le(last, first): {}", elapsed(t3));

        let t4 = Instant::now();
        let sample_indices: Vec<usize> = (0..100).map(|i| i * 1000).collect();
        for &i in &sample_indices {
            for &j in &sample_indices {
                let expected = i <= j;
                let actual = dw.is_le(positions[i], positions[j]);
                assert_eq!(actual, expected, "is_le({}, {}) mismatch", i, j);
            }
        }
        eprintln!("  P1 10K sampled comparisons: {}", elapsed(t4));
        eprintln!("  P1 total: {}", elapsed(t));
    }

    // P2: stress_exponential_merge_dag — binary tree of merges.
    // 14 levels: 16384 leaf branches, ~16K merge branches = ~32K total.
    // Tests that the HashMap visited-set prevents exponential blowup.
    #[test]
    #[ignore]
    fn stress_exponential_merge_dag() {
        let t = Instant::now();
        let mut dw = DagWood::new();

        let mut leaves: Vec<TracePosition> = (0..16384).map(|_| dw.new_position()).collect();
        eprintln!("  P2 create 16384 leaves: {}", elapsed(t));

        let t2 = Instant::now();
        for _level in 0..14 {
            let mut merged = Vec::new();
            let mut i = 0;
            while i + 1 < leaves.len() {
                let m = dw.new_successor_after(leaves[i], leaves[i + 1]);
                merged.push(m);
                i += 2;
            }
            if !leaves.is_empty() && leaves.len() % 2 == 1 {
                merged.push(leaves[leaves.len() - 1]);
            }
            leaves = merged;
        }
        eprintln!("  P2 merge tree (14 levels): {}", elapsed(t2));

        assert_eq!(leaves.len(), 1);
        let root_merge = leaves[0];

        let t3 = Instant::now();
        let view = dw.trace_view(root_merge);
        assert!(
            view.branch_count() > 30000,
            "should see ~32K branches, got {}",
            view.branch_count()
        );
        eprintln!(
            "  P2 TraceView ({} branches): {}",
            view.branch_count(),
            elapsed(t3)
        );

        let t4 = Instant::now();
        for _ in 0..1000 {
            let _ = dw.is_le(dw.root(), root_merge);
        }
        eprintln!("  P2 1K is_le calls: {}", elapsed(t4));
        eprintln!("  P2 total: {}", elapsed(t));
    }

    // P7: stress_cache_thrashing — 100K alternating-reference is_le calls.
    // Each reference change clears and rebuilds the entire nav_cache.
    #[test]
    #[ignore]
    fn stress_cache_thrashing() {
        let t = Instant::now();
        let mut dag = generate_dag(42, 2000);
        let n = dag.positions.len();
        eprintln!(
            "  P7 generate 2000-op DAG ({} positions): {}",
            n,
            elapsed(t)
        );

        let ref_indices: Vec<usize> = (0..20).map(|i| (i * n / 20).min(n - 1)).collect();

        let t2 = Instant::now();
        for round in 0..1000 {
            for &ref_idx in &ref_indices {
                let reference = dag.positions[ref_idx];
                let query_idx = (round * ref_idx) % n;
                let query = dag.positions[query_idx];

                let cached = dag.dw.is_le(query, reference);
                let brute = is_le_no_cache(&dag.dw, query, reference);
                assert_eq!(
                    cached, brute,
                    "cache mismatch at round {} ref={} query={}",
                    round, ref_idx, query_idx
                );
            }
        }
        eprintln!("  P7 20K is_le+brute pairs: {}", elapsed(t2));
        eprintln!("  P7 total: {}", elapsed(t));
    }

    // P8: stress_trace_view_5k_branches — TraceView on 5,000+ branch DAG.
    // Verifies is_visible for all positions from multiple reference points.
    #[test]
    #[ignore]
    fn stress_trace_view_5k_branches() {
        let t = Instant::now();
        let mut dag = generate_dag(31415, 5000);
        let n = dag.positions.len();
        eprintln!("  P8 generate 5K-op DAG ({} positions): {}", n, elapsed(t));

        let ref_points = [0, n / 8, n / 4, n / 2, 3 * n / 4, n - 1];
        for &seed_ref in &ref_points {
            let reference = dag.positions[seed_ref];
            let t2 = Instant::now();
            let view = dag.dw.trace_view(reference);
            eprintln!("  P8 TraceView(ref[{}]) created: {}", seed_ref, elapsed(t2));

            for (i, &pos) in dag.positions.iter().enumerate() {
                let from_view = view.is_visible(pos);
                let from_is_le = dag.dw.is_le(pos, reference);
                assert_eq!(
                    from_view, from_is_le,
                    "mismatch at pos[{}] ref[{}]",
                    i, seed_ref
                );
            }
        }
        eprintln!("  P8 total: {}", elapsed(t));
    }

    // P10: stress_marathon_properties — extended property testing.
    // Runs reflexivity, antisymmetry, transitivity on 50 random DAGs
    // with 500 ops each. ~20K positions per DAG, all-pairs/all-triples checks.
    #[test]
    #[ignore]
    fn stress_marathon_properties() {
        let seeds: Vec<u64> = (0..50).map(|i| i * 7919 + 42).collect();
        for (_si, &seed) in seeds.iter().enumerate() {
            let t = Instant::now();
            let mut dag = generate_dag(seed, 500);
            let n = dag.positions.len();
            eprint!("  P10 seed={} ({} positions) ", seed, n);

            for i in 0..n {
                assert!(
                    dag.dw.is_le(dag.positions[i], dag.positions[i]),
                    "reflexivity failed seed={} i={}",
                    seed,
                    i
                );
            }

            for i in 0..n {
                for j in 0..n {
                    let a = dag.positions[i];
                    let b = dag.positions[j];
                    if dag.dw.is_le(a, b) && dag.dw.is_le(b, a) {
                        assert_eq!(a, b, "antisymmetry failed seed={}", seed);
                    }
                }
            }

            for i in (0..n).step_by(5) {
                for j in (0..n).step_by(5) {
                    for k in (0..n).step_by(5) {
                        let a = dag.positions[i];
                        let b = dag.positions[j];
                        let c = dag.positions[k];
                        if dag.dw.is_le(a, b) && dag.dw.is_le(b, c) {
                            assert!(dag.dw.is_le(a, c), "transitivity failed seed={}", seed);
                        }
                    }
                }
            }
            eprintln!("{}", elapsed(t));
        }
    }
}
