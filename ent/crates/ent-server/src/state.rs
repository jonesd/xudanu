use std::collections::HashMap;
use std::sync::Arc;

use ent_core::ent::content::{
    AssertionPayload, AssertionStore, DocumentId, NodeId, SpanId,
};
use ent_core::ent::dagwood::DagWood;
use ent_core::ent::trace::TracePosition;
use tokio::sync::RwLock;

pub struct BranchInfo {
    pub name: String,
    pub head: TracePosition,
}

pub struct WorkspaceState {
    pub id: String,
    pub name: String,
    pub dagwood: DagWood,
    pub store: AssertionStore,
    pub branches: HashMap<String, BranchInfo>,
    pub doc_id: DocumentId,
    pub next_id: u64,
}

impl WorkspaceState {
    pub fn new(name: &str) -> Self {
        let id = name.to_lowercase().replace(' ', "-");
        let mut ws = WorkspaceState {
            id,
            name: name.to_string(),
            dagwood: DagWood::new(),
            store: AssertionStore::new(),
            branches: HashMap::new(),
            doc_id: DocumentId::new(1),
            next_id: 2,
        };

        let root = ws.dagwood.root();
        ws.branches.insert(
            "main".to_string(),
            BranchInfo {
                name: "main".to_string(),
                head: root,
            },
        );

        ws.seed_document();
        ws
    }

    fn seed_document(&mut self) {
        let pos = self.dagwood.root();
        let doc_node = self.doc_id.node_id();
        let para_node = NodeId::new(self.alloc_id());
        let span_id = SpanId::new(self.alloc_id());

        self.store.add(
            pos,
            AssertionPayload::CreateNode {
                node_id: doc_node,
                kind: "document".into(),
            },
        );
        self.store.add(
            pos,
            AssertionPayload::CreateNode {
                node_id: para_node,
                kind: "paragraph".into(),
            },
        );
        self.store.add(
            pos,
            AssertionPayload::AttachChild {
                parent_id: doc_node,
                child_id: para_node,
                ordinal: 1,
            },
        );
        self.store.add(pos, AssertionPayload::CreateSpan { span_id });
        self.store.add(
            pos,
            AssertionPayload::SetSpanText {
                span_id,
                text: "Hello world".into(),
            },
        );
        self.store.add(
            pos,
            AssertionPayload::AttachSpanToNode {
                node_id: para_node,
                span_id,
                ordinal: 1,
            },
        );
    }

    pub fn alloc_id(&mut self) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        id
    }
}

pub type SharedState = Arc<RwLock<HashMap<String, WorkspaceState>>>;
