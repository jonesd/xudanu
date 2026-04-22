use std::collections::HashMap;

use xanadu_types::*;

use crate::sequence::Sequence;
use crate::state_vector::StateVector;

#[derive(Debug, Clone)]
pub struct Document {
    id: DocumentId,
    sequence: Sequence,
    site: SiteId,
    author: AuthorId,
    clock: u64,
    pending_ops: Vec<Op>,
    change_dag: HashMap<ChangeHash, Change>,
    heads: Vec<ChangeHash>,
    branches: HashMap<String, Document>,
    pending_changes: Vec<Change>,
}

impl Document {
    pub fn new(id: DocumentId, author: Author, site: SiteId) -> Self {
        Self {
            id,
            sequence: Sequence::new(site),
            site,
            author: *author.id(),
            clock: 0,
            pending_ops: Vec::new(),
            change_dag: HashMap::new(),
            heads: Vec::new(),
            branches: HashMap::new(),
            pending_changes: Vec::new(),
        }
    }

    pub fn id(&self) -> &DocumentId {
        &self.id
    }

    pub fn site(&self) -> &SiteId {
        &self.site
    }

    pub fn state_vector(&self) -> &StateVector {
        self.sequence.state_vector()
    }

    pub fn len(&self) -> usize {
        self.sequence.len()
    }

    pub fn is_empty(&self) -> bool {
        self.sequence.is_empty()
    }

    pub fn to_string(&self) -> String {
        self.sequence.to_string()
    }

    pub fn insert(&mut self, index: usize, text: impl Into<String>) {
        self.insert_styled(index, text, Vec::new());
    }

    pub fn insert_styled(&mut self, index: usize, text: impl Into<String>, marks: Vec<Mark>) {
        let content = ItemContent::styled(text, marks);
        let op = self.sequence.local_insert(index, content, self.site, self.author);
        self.clock += 1;
        self.pending_ops.push(op);
    }

    pub fn insert_block(&mut self, index: usize, block_type: BlockType) {
        let content = ItemContent::BlockStart(block_type);
        let op = self.sequence.local_insert(index, content, self.site, self.author);
        self.clock += 1;
        self.pending_ops.push(op);

        let content = ItemContent::BlockEnd;
        let op = self.sequence.local_insert(index + 1, content, self.site, self.author);
        self.clock += 1;
        self.pending_ops.push(op);
    }

    pub fn delete(&mut self, index: usize, len: usize) {
        let ops = self.sequence.local_delete(index, len, self.site, self.author);
        self.clock += ops.len() as u64;
        self.pending_ops.extend(ops);
    }

    pub fn commit_change(&mut self) -> Option<Change> {
        if self.pending_ops.is_empty() {
            return None;
        }

        let ops = std::mem::take(&mut self.pending_ops);
        let timestamp = HybridTimestamp::now(self.clock);
        let deps = self.heads.clone();

        let change = Change::unsigned(
            self.author,
            self.site,
            deps,
            ops,
            timestamp,
            self.clock,
        );

        let hash = change.id;
        self.change_dag.insert(hash, change.clone());
        self.heads = vec![hash];

        Some(change)
    }

    pub fn integrate_change(&mut self, change: &Change) {
        if self.change_dag.contains_key(&change.id) {
            return;
        }

        if !self.can_integrate(change) {
            self.pending_changes.push(change.clone());
            return;
        }

        self.do_integrate(change);
        self.try_flush_pending();
    }

    fn can_integrate(&self, change: &Change) -> bool {
        for op in &change.operations {
            match op {
                Op::Insert { left_id, right_id, .. } => {
                    if let Some(id) = left_id {
                        if !self.sequence.has_item(id) {
                            return false;
                        }
                    }
                    if let Some(id) = right_id {
                        if !self.sequence.has_item(id) {
                            return false;
                        }
                    }
                }
                Op::Delete { target_id, .. } => {
                    if !self.sequence.has_item(target_id) {
                        return false;
                    }
                }
                Op::Transclude { left_id, right_id, .. } => {
                    if let Some(id) = left_id {
                        if !self.sequence.has_item(id) {
                            return false;
                        }
                    }
                    if let Some(id) = right_id {
                        if !self.sequence.has_item(id) {
                            return false;
                        }
                    }
                }
            }
        }
        true
    }

    fn do_integrate(&mut self, change: &Change) {
        if self.change_dag.contains_key(&change.id) {
            return;
        }
        for op in &change.operations {
            self.sequence.integrate_op(op);
        }
        let hash = change.id;
        self.change_dag.insert(hash, change.clone());

        for dep in &change.deps {
            self.heads.retain(|h| h != dep);
        }
        self.heads.push(hash);
    }

    fn try_flush_pending(&mut self) {
        let mut progress = true;
        while progress {
            progress = false;
            let mut i = 0;
            while i < self.pending_changes.len() {
                if self.can_integrate(&self.pending_changes[i]) {
                    let change = self.pending_changes.remove(i);
                    self.do_integrate(&change);
                    progress = true;
                } else {
                    i += 1;
                }
            }
        }
    }

    pub fn integrate_ops(&mut self, ops: &[Op]) {
        for op in ops {
            self.sequence.integrate_op(op);
        }
    }

    pub fn pending_ops(&self) -> &[Op] {
        &self.pending_ops
    }

    pub fn create_branch(&mut self, name: String) -> &Document {
        let branch = self.clone();
        self.branches.insert(name.clone(), branch);
        self.branches.get(&name).unwrap()
    }

    pub fn get_branch(&self, name: &str) -> Option<&Document> {
        self.branches.get(name)
    }

    pub fn get_branch_mut(&mut self, name: &str) -> Option<&mut Document> {
        self.branches.get_mut(name)
    }

    pub fn list_branches(&self) -> Vec<&str> {
        self.branches.keys().map(|s| s.as_str()).collect()
    }

    pub fn iter_visible(&self) -> impl Iterator<Item = (&ItemId, &ItemContent, &AuthorId)> {
        self.sequence.iter_visible()
    }

    pub fn change_history(&self) -> Vec<&Change> {
        let mut changes: Vec<&Change> = self.change_dag.values().collect();
        changes.sort_by_key(|c| c.lamport);
        changes
    }
}
