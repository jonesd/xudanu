use std::collections::HashMap;
use std::convert::TryFrom;

use xudanu_types::*;
use yrs::updates::decoder::Decode;
use yrs::{GetString, ReadTxn, Text, Transact};

use crate::state_vector::StateVector;

fn site_to_client_id(site: &SiteId) -> u64 {
    use sha2::{Digest, Sha256};
    let mut hasher = Sha256::new();
    hasher.update(site.as_bytes());
    let hash = hasher.finalize();
    let mut arr = [0u8; 8];
    arr.copy_from_slice(&hash[..8]);
    u64::from_be_bytes(arr)
}

#[derive(Debug, Clone)]
pub struct Document {
    doc: yrs::Doc,
    text: yrs::TextRef,
    site: SiteId,
    author: AuthorId,
    client_id: u64,
    clock: u64,
    last_committed_sv: yrs::StateVector,
    sv: StateVector,
    change_dag: HashMap<ChangeHash, Change>,
    heads: Vec<ChangeHash>,
    branches: HashMap<String, Document>,
    pending_changes: Vec<Change>,
    visible_items: Vec<(ItemId, ItemContent, AuthorId)>,
    client_author_map: HashMap<u64, AuthorId>,
}

impl Document {
    pub fn new(_id: DocumentId, author: Author, site: SiteId) -> Self {
        let doc = yrs::Doc::new();
        let client_id = doc.client_id();
        let text = doc.get_or_insert_text("main");

        let author_id = *author.id();
        let mut client_author_map: HashMap<u64, AuthorId> = HashMap::new();
        client_author_map.insert(client_id, author_id);

        let last_committed_sv = {
            let txn = doc.transact();
            txn.state_vector()
        };

        let mut s = Self {
            doc,
            text,
            site,
            author: author_id,
            client_id,
            clock: 0,
            last_committed_sv,
            sv: StateVector::new(),
            change_dag: HashMap::new(),
            heads: Vec::new(),
            branches: HashMap::new(),
            pending_changes: Vec::new(),
            visible_items: Vec::new(),
            client_author_map,
        };
        s.rebuild_visible_cache();
        s
    }

    pub fn id(&self) -> &DocumentId {
        static DUMMY: DocumentId = [0u8; 32];
        &DUMMY
    }

    pub fn site(&self) -> &SiteId {
        &self.site
    }

    pub fn state_vector(&self) -> &StateVector {
        &self.sv
    }

    pub fn len(&self) -> usize {
        let txn = self.doc.transact();
        let s = self.text.get_string(&txn);
        s.chars().count()
    }

    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }

    pub fn to_string(&self) -> String {
        let txn = self.doc.transact();
        self.text.get_string(&txn)
    }

    pub fn insert(&mut self, index: usize, text: impl Into<String>) {
        self.insert_styled(index, text, Vec::new());
    }

    pub fn insert_styled(&mut self, index: usize, text: impl Into<String>, _marks: Vec<Mark>) {
        let text = text.into();
        if text.is_empty() {
            return;
        }
        let byte_offset = self.char_to_byte_offset(index);
        {
            let mut txn = self.doc.transact_mut();
            let attrs = yrs::types::Attrs::from([(
                std::sync::Arc::from("__author"),
                yrs::Any::String(std::sync::Arc::from(hex::encode(self.author))),
            )]);
            self.text
                .insert_with_attributes(&mut txn, byte_offset, &text, attrs);
        }
        self.clock += 1;
        self.update_sv_from_yrs();
        self.rebuild_visible_cache();
    }

    pub fn insert_block(&mut self, _index: usize, _block_type: BlockType) {}

    pub fn delete(&mut self, index: usize, char_len: usize) {
        if char_len == 0 {
            return;
        }
        let byte_start = self.char_to_byte_offset(index);
        let byte_end = self.char_to_byte_offset(index + char_len);
        let byte_len = byte_end - byte_start;
        if byte_len > 0 {
            let mut txn = self.doc.transact_mut();
            self.text.remove_range(&mut txn, byte_start, byte_len);
        }
        self.clock += 1;
        self.update_sv_from_yrs();
        self.rebuild_visible_cache();
    }

    pub fn commit_change(&mut self) -> Option<Change> {
        let current_sv = {
            let txn = self.doc.transact();
            txn.state_vector()
        };

        let update_bytes = {
            let txn = self.doc.transact();
            txn.encode_diff_v1(&self.last_committed_sv)
        };

        if update_bytes.len() <= 2 {
            return None;
        }

        let local_clock = current_sv.get(&self.client_id) as u64;

        let timestamp = HybridTimestamp::now(self.clock);
        let deps = self.heads.clone();

        let mut change = Change::from_update(
            self.author,
            self.site,
            deps,
            update_bytes,
            timestamp,
            local_clock,
        );
        change.sender_client_id = self.client_id;

        let hash = change.id;
        self.change_dag.insert(hash, change.clone());
        self.heads = vec![hash];

        self.sv.set(self.site, local_clock);
        self.last_committed_sv = current_sv;

        Some(change)
    }

    fn update_sv_from_yrs(&mut self) {
        let txn = self.doc.transact();
        let yrs_sv = txn.state_vector();
        let local_clock = yrs_sv.get(&self.client_id);
        if local_clock > 0 {
            self.sv.set(self.site, local_clock as u64);
        }
    }

    pub fn integrate_change(&mut self, change: &Change) {
        if self.change_dag.contains_key(&change.id) {
            return;
        }

        self.client_author_map
            .insert(site_to_client_id(&change.site), change.actor);
        if change.sender_client_id != 0 {
            self.client_author_map
                .insert(change.sender_client_id, change.actor);
        }

        if !change.update_bytes.is_empty() {
            match yrs::Update::decode_v1(&change.update_bytes) {
                Ok(update) => {
                    let mut txn = self.doc.transact_mut();
                    let _ = txn.apply_update(update);
                }
                Err(_) => {
                    self.pending_changes.push(change.clone());
                    return;
                }
            }
        }

        self.change_dag.insert(change.id, change.clone());

        for dep in &change.deps {
            self.heads.retain(|h| h != dep);
        }
        self.heads.push(change.id);

        if change.lamport > 0 {
            self.sv.set(change.site, change.lamport);
        }

        // Register any new client_ids from the update with this change's author
        {
            let txn = self.doc.transact();
            let yrs_sv = txn.state_vector();
            for (&cid, &clock) in yrs_sv.iter() {
                if clock > 0 && !self.client_author_map.contains_key(&cid) {
                    self.client_author_map.insert(cid, change.actor);
                }
            }
        }

        self.last_committed_sv = {
            let txn = self.doc.transact();
            txn.state_vector()
        };

        self.try_flush_pending();
        self.rebuild_visible_cache();
    }

    pub fn integrate_ops(&mut self, _ops: &[Op]) {}

    pub fn pending_ops(&self) -> &[Op] {
        &[]
    }

    pub fn create_branch(&mut self, name: String) -> &Document {
        let full_state = {
            let txn = self.doc.transact();
            txn.encode_state_as_update_v1(&yrs::StateVector::default())
        };

        let new_doc = yrs::Doc::new();
        let branch_client_id = new_doc.client_id();
        {
            let mut txn = new_doc.transact_mut();
            if let Ok(update) = yrs::Update::decode_v1(&full_state) {
                let _ = txn.apply_update(update);
            }
        }
        let text = new_doc.get_or_insert_text("main");
        let branch_sv = {
            let txn = new_doc.transact();
            txn.state_vector()
        };

        let branch = Document {
            doc: new_doc,
            text,
            site: self.site,
            author: self.author,
            client_id: branch_client_id,
            clock: self.clock,
            last_committed_sv: branch_sv,
            sv: self.sv.clone(),
            change_dag: self.change_dag.clone(),
            heads: self.heads.clone(),
            branches: HashMap::new(),
            pending_changes: Vec::new(),
            visible_items: Vec::new(),
            client_author_map: self.client_author_map.clone(),
        };
        self.branches.insert(name.clone(), branch);
        let branch = self.branches.get_mut(&name).unwrap();
        branch.rebuild_visible_cache();
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
        self.visible_items.iter().map(|t| (&t.0, &t.1, &t.2))
    }

    pub fn change_history(&self) -> Vec<&Change> {
        let mut changes: Vec<&Change> = self.change_dag.values().collect();
        changes.sort_by_key(|c| c.lamport);
        changes
    }

    fn char_to_byte_offset(&self, char_index: usize) -> u32 {
        let txn = self.doc.transact();
        let s = self.text.get_string(&txn);
        let byte_offset = s
            .char_indices()
            .nth(char_index)
            .map(|(i, _)| i)
            .unwrap_or(s.len());
        byte_offset as u32
    }

    fn rebuild_visible_cache(&mut self) {
        self.visible_items.clear();
        let txn = self.doc.transact();
        let chunks = self.text.diff(&txn, yrs::types::text::YChange::identity);

        let mut char_pos = 0u64;

        for chunk in &chunks {
            let inserted_str = match String::try_from(chunk.insert.clone()) {
                Ok(s) => s,
                Err(_) => continue,
            };

            if inserted_str.is_empty() {
                continue;
            }

            let author = chunk
                .attributes
                .as_ref()
                .and_then(|attrs| attrs.get("__author"))
                .and_then(|v| {
                    if let yrs::Any::String(s) = v {
                        hex::decode(s.as_ref()).ok().and_then(|bytes| {
                            if bytes.len() == 32 {
                                let mut arr = [0u8; 32];
                                arr.copy_from_slice(&bytes);
                                Some(arr)
                            } else {
                                None
                            }
                        })
                    } else {
                        None
                    }
                })
                .or_else(|| {
                    chunk
                        .ychange
                        .as_ref()
                        .and_then(|yc| self.client_author_map.get(&yc.id.client).copied())
                })
                .unwrap_or(self.author);

            self.visible_items.push((
                ItemId::new(self.site, char_pos),
                ItemContent::plain(&inserted_str),
                author,
            ));
            char_pos += inserted_str.chars().count() as u64;
        }

        if self.visible_items.is_empty() {
            let s = self.text.get_string(&txn);
            if !s.is_empty() {
                self.visible_items.push((
                    ItemId::new(self.site, 0),
                    ItemContent::plain(&s),
                    self.author,
                ));
            }
        }
    }

    fn try_flush_pending(&mut self) {
        let mut progress = true;
        while progress {
            progress = false;
            let mut i = 0;
            while i < self.pending_changes.len() {
                let change = &self.pending_changes[i];
                if !change.update_bytes.is_empty() {
                    if let Ok(update) = yrs::Update::decode_v1(&change.update_bytes) {
                        let change = self.pending_changes.remove(i);

                        self.client_author_map
                            .insert(site_to_client_id(&change.site), change.actor);

                        let mut txn = self.doc.transact_mut();
                        let _ = txn.apply_update(update);

                        self.change_dag.insert(change.id, change.clone());
                        for dep in &change.deps {
                            self.heads.retain(|h| h != dep);
                        }
                        self.heads.push(change.id);
                        if change.lamport > 0 {
                            self.sv.set(change.site, change.lamport);
                        }

                        progress = true;
                        continue;
                    }
                }
                i += 1;
            }
        }
    }
}
