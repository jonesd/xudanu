use std::collections::{HashMap, HashSet};

use crate::ent::branch::BranchId;
use crate::ent::dagwood::TraceView;
use crate::ent::trace::TracePosition;

// === Entity IDs ===
// Opaque, stable across history.

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct DocumentId(pub u64);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct NodeId(pub u64);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct SpanId(pub u64);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct AnnotationId(pub u64);

impl DocumentId {
    pub fn new(id: u64) -> Self {
        DocumentId(id)
    }
    pub fn node_id(self) -> NodeId {
        NodeId(self.0)
    }
}

impl NodeId {
    pub fn new(id: u64) -> Self {
        NodeId(id)
    }
}

impl SpanId {
    pub fn new(id: u64) -> Self {
        SpanId(id)
    }
}

impl AnnotationId {
    pub fn new(id: u64) -> Self {
        AnnotationId(id)
    }
}

// === Assertion Payload ===

#[derive(Debug, Clone, PartialEq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub enum AssertionPayload {
    CreateNode {
        node_id: NodeId,
        kind: String,
    },
    AttachChild {
        parent_id: NodeId,
        child_id: NodeId,
        ordinal: u32,
    },
    DetachChild {
        parent_id: NodeId,
        child_id: NodeId,
    },
    DeleteNode {
        node_id: NodeId,
    },
    CreateSpan {
        span_id: SpanId,
    },
    SetSpanText {
        span_id: SpanId,
        text: String,
    },
    DeleteSpan {
        span_id: SpanId,
    },
    AttachSpanToNode {
        node_id: NodeId,
        span_id: SpanId,
        ordinal: u32,
    },
    DetachSpanFromNode {
        node_id: NodeId,
        span_id: SpanId,
    },
    CreateAnnotation {
        annotation_id: AnnotationId,
        kind: String,
        payload: String,
    },
    AttachAnnotationToNode {
        annotation_id: AnnotationId,
        node_id: NodeId,
    },
    AttachAnnotationToSpan {
        annotation_id: AnnotationId,
        span_id: SpanId,
    },
    DeleteAnnotation {
        annotation_id: AnnotationId,
    },
}

// === Assertion ===

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct AssertionId(pub u64);

#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct Assertion {
    pub id: AssertionId,
    pub position: TracePosition,
    pub payload: AssertionPayload,
}

// === AlternativeSet ===
// For single-valued properties where multiple branches disagree.
// DO NOT silently resolve — preserve all visible alternatives.

#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub enum AlternativeSet<T> {
    Single(T),
    Alternatives(Vec<T>),
}

impl<T: Clone + Eq + std::hash::Hash> AlternativeSet<T> {
    pub fn from_unique_values(mut values: Vec<T>) -> Self {
        let mut seen = HashSet::new();
        values.retain(|v| seen.insert(v.clone()));
        match values.len() {
            0 => AlternativeSet::Alternatives(Vec::new()),
            1 => AlternativeSet::Single(values.into_iter().next().unwrap()),
            _ => AlternativeSet::Alternatives(values),
        }
    }

    pub fn values(&self) -> &[T] {
        match self {
            AlternativeSet::Single(v) => std::slice::from_ref(v),
            AlternativeSet::Alternatives(v) => v,
        }
    }

    pub fn is_single(&self) -> bool {
        matches!(self, AlternativeSet::Single(_))
    }

    pub fn single_value(&self) -> Option<&T> {
        match self {
            AlternativeSet::Single(v) => Some(v),
            AlternativeSet::Alternatives(_) => None,
        }
    }
}

// === Materialized Types ===

#[derive(Debug, Clone, PartialEq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct MaterializedAnnotation {
    pub annotation_id: AnnotationId,
    pub kind: String,
    pub payload: String,
}

#[derive(Debug, Clone, PartialEq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct MaterializedSpan {
    pub span_id: SpanId,
    pub text: AlternativeSet<String>,
    pub annotations: Vec<MaterializedAnnotation>,
}

#[derive(Debug, Clone, PartialEq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct MaterializedNode {
    pub node_id: NodeId,
    pub kind: String,
    pub children: Vec<MaterializedNode>,
    pub spans: Vec<MaterializedSpan>,
    pub annotations: Vec<MaterializedAnnotation>,
}

#[derive(Debug, Clone, PartialEq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct MaterializedDocument {
    pub doc_id: DocumentId,
    pub root: Option<MaterializedNode>,
}

#[derive(Debug, Clone, PartialEq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub enum MaterializedEntity {
    Node(MaterializedNode),
    Span(MaterializedSpan),
    Annotation(MaterializedAnnotation),
    NotFound,
}

// === AssertionStore ===

pub struct AssertionStore {
    assertions: Vec<Assertion>,
    next_id: u64,
}

impl AssertionStore {
    pub fn new() -> Self {
        AssertionStore {
            assertions: Vec::new(),
            next_id: 1,
        }
    }

    pub fn add(&mut self, position: TracePosition, payload: AssertionPayload) -> AssertionId {
        let id = AssertionId(self.next_id);
        self.next_id += 1;
        self.assertions.push(Assertion {
            id,
            position,
            payload,
        });
        id
    }

    // visible_assertions(view) = all assertions where view.is_visible(assertion.position)
    // This is the SOLE filtering mechanism. No other rules apply.
    pub fn visible_assertions<'a>(&'a self, view: &TraceView) -> Vec<&'a Assertion> {
        self.assertions
            .iter()
            .filter(|a| view.is_visible(a.position))
            .collect()
    }

    pub fn all_assertions(&self) -> &[Assertion] {
        &self.assertions
    }
}

// === Materialization ===
// History determines visibility.
// Visibility determines meaning.
// Meaning must not silently discard visible assertions.

pub fn materialize_document(
    store: &AssertionStore,
    view: &TraceView,
    doc_id: DocumentId,
) -> MaterializedDocument {
    let visible = store.visible_assertions(view);
    let root = materialize_node_internal(&visible, doc_id.node_id());
    MaterializedDocument { doc_id, root }
}

pub fn materialize_node(
    store: &AssertionStore,
    view: &TraceView,
    node_id: NodeId,
) -> Option<MaterializedNode> {
    let visible = store.visible_assertions(view);
    materialize_node_internal(&visible, node_id)
}

pub fn materialize_span(
    store: &AssertionStore,
    view: &TraceView,
    span_id: SpanId,
) -> Option<MaterializedSpan> {
    let visible = store.visible_assertions(view);
    materialize_span_internal(&visible, span_id)
}

pub fn materialize_entity(
    store: &AssertionStore,
    view: &TraceView,
    entity: EntityId,
) -> MaterializedEntity {
    let visible = store.visible_assertions(view);
    match entity {
        EntityId::Node(id) => materialize_node_internal(&visible, id)
            .map(MaterializedEntity::Node)
            .unwrap_or(MaterializedEntity::NotFound),
        EntityId::Span(id) => materialize_span_internal(&visible, id)
            .map(MaterializedEntity::Span)
            .unwrap_or(MaterializedEntity::NotFound),
        EntityId::Annotation(id) => materialize_annotation_internal(&visible, id)
            .map(MaterializedEntity::Annotation)
            .unwrap_or(MaterializedEntity::NotFound),
    }
}

#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
#[derive(Debug, PartialEq)]
pub enum EntityId {
    Node(NodeId),
    Span(SpanId),
    Annotation(AnnotationId),
}

// --- Internal materialization helpers ---

fn entity_exists(
    visible: &[&Assertion],
    is_create: impl Fn(&AssertionPayload) -> bool,
    is_delete: impl Fn(&AssertionPayload) -> bool,
) -> bool {
    let created = visible.iter().any(|a| is_create(&a.payload));
    let deleted = visible.iter().any(|a| is_delete(&a.payload));
    created && !deleted
}

fn materialize_node_internal(
    visible: &[&Assertion],
    node_id: NodeId,
) -> Option<MaterializedNode> {
    let exists = entity_exists(
        visible,
        |p| matches!(p, AssertionPayload::CreateNode { node_id: id, .. } if *id == node_id),
        |p| matches!(p, AssertionPayload::DeleteNode { node_id: id } if *id == node_id),
    );
    if !exists {
        return None;
    }

    let kind = visible
        .iter()
        .find_map(|a| match &a.payload {
            AssertionPayload::CreateNode {
                node_id: id,
                kind,
            } if *id == node_id => Some(kind.clone()),
            _ => None,
        })
        .unwrap_or_default();

    let children = collect_children(visible, node_id);
    let spans = collect_spans(visible, node_id);
    let annotations = collect_annotations_for_node(visible, node_id);

    Some(MaterializedNode {
        node_id,
        kind,
        children,
        spans,
        annotations,
    })
}

fn collect_children(visible: &[&Assertion], node_id: NodeId) -> Vec<MaterializedNode> {
    let attached: HashSet<NodeId> = visible
        .iter()
        .filter_map(|a| match &a.payload {
            AssertionPayload::AttachChild {
                parent_id,
                child_id,
                ..
            } if *parent_id == node_id => Some(*child_id),
            _ => None,
        })
        .collect();

    let detached: HashSet<NodeId> = visible
        .iter()
        .filter_map(|a| match &a.payload {
            AssertionPayload::DetachChild {
                parent_id,
                child_id,
            } if *parent_id == node_id => Some(*child_id),
            _ => None,
        })
        .collect();

    attached
        .difference(&detached)
        .filter_map(|&id| materialize_node_internal(visible, id))
        .collect()
}

fn collect_spans(visible: &[&Assertion], node_id: NodeId) -> Vec<MaterializedSpan> {
    let attached: HashSet<SpanId> = visible
        .iter()
        .filter_map(|a| match &a.payload {
            AssertionPayload::AttachSpanToNode {
                node_id: nid,
                span_id,
                ..
            } if *nid == node_id => Some(*span_id),
            _ => None,
        })
        .collect();

    let detached: HashSet<SpanId> = visible
        .iter()
        .filter_map(|a| match &a.payload {
            AssertionPayload::DetachSpanFromNode {
                node_id: nid,
                span_id,
            } if *nid == node_id => Some(*span_id),
            _ => None,
        })
        .collect();

    attached
        .difference(&detached)
        .filter_map(|&id| materialize_span_internal(visible, id))
        .collect()
}

fn materialize_span_internal(
    visible: &[&Assertion],
    span_id: SpanId,
) -> Option<MaterializedSpan> {
    let exists = entity_exists(
        visible,
        |p| matches!(p, AssertionPayload::CreateSpan { span_id: id } if *id == span_id),
        |p| matches!(p, AssertionPayload::DeleteSpan { span_id: id } if *id == span_id),
    );
    if !exists {
        return None;
    }

    let text = collect_span_text(visible, span_id);
    let annotations = collect_annotations_for_span(visible, span_id);

    Some(MaterializedSpan {
        span_id,
        text,
        annotations,
    })
}

// Same-branch: latest position wins (overwrite).
// Cross-branch: each branch contributes its latest; if branches disagree → alternatives.
fn collect_span_text(visible: &[&Assertion], span_id: SpanId) -> AlternativeSet<String> {
    let mut per_branch: HashMap<BranchId, (u32, String)> = HashMap::new();

    for a in visible {
        if let AssertionPayload::SetSpanText {
            span_id: sid,
            text,
        } = &a.payload
        {
            if *sid == span_id {
                let branch = a.position.branch();
                let pos = a.position.position();
                match per_branch.get(&branch) {
                    None => {
                        per_branch.insert(branch, (pos, text.clone()));
                    }
                    Some((existing_pos, _)) if pos > *existing_pos => {
                        per_branch.insert(branch, (pos, text.clone()));
                    }
                    _ => {}
                }
            }
        }
    }

    let values: Vec<String> = per_branch.into_values().map(|(_, v)| v).collect();
    if values.is_empty() {
        AlternativeSet::Single(String::new())
    } else {
        AlternativeSet::from_unique_values(values)
    }
}

fn materialize_annotation_internal(
    visible: &[&Assertion],
    annotation_id: AnnotationId,
) -> Option<MaterializedAnnotation> {
    let exists = entity_exists(
        visible,
        |p| {
            matches!(
                p,
                AssertionPayload::CreateAnnotation { annotation_id: id, .. }
                if *id == annotation_id
            )
        },
        |p| {
            matches!(
                p,
                AssertionPayload::DeleteAnnotation { annotation_id: id }
                if *id == annotation_id
            )
        },
    );
    if !exists {
        return None;
    }

    visible
        .iter()
        .find_map(|a| match &a.payload {
            AssertionPayload::CreateAnnotation {
                annotation_id: id,
                kind,
                payload,
            } if *id == annotation_id => Some(MaterializedAnnotation {
                annotation_id,
                kind: kind.clone(),
                payload: payload.clone(),
            }),
            _ => None,
        })
}

fn collect_annotations_for_node(
    visible: &[&Assertion],
    node_id: NodeId,
) -> Vec<MaterializedAnnotation> {
    let attached: HashSet<AnnotationId> = visible
        .iter()
        .filter_map(|a| match &a.payload {
            AssertionPayload::AttachAnnotationToNode {
                annotation_id,
                node_id: nid,
            } if *nid == node_id => Some(*annotation_id),
            _ => None,
        })
        .collect();

    attached
        .into_iter()
        .filter_map(|id| materialize_annotation_internal(visible, id))
        .collect()
}

fn collect_annotations_for_span(
    visible: &[&Assertion],
    span_id: SpanId,
) -> Vec<MaterializedAnnotation> {
    let attached: HashSet<AnnotationId> = visible
        .iter()
        .filter_map(|a| match &a.payload {
            AssertionPayload::AttachAnnotationToSpan {
                annotation_id,
                span_id: sid,
            } if *sid == span_id => Some(*annotation_id),
            _ => None,
        })
        .collect();

    attached
        .into_iter()
        .filter_map(|id| materialize_annotation_internal(visible, id))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ent::dagwood::DagWood;

    // Helper: build a simple linear history and return (dw, positions)
    fn linear_history(n: usize) -> (DagWood, Vec<TracePosition>) {
        let mut dw = DagWood::new();
        let mut positions = vec![dw.root()];
        let mut tip = dw.new_position();
        positions.push(tip);
        for _ in 1..n {
            tip = dw.new_position_after(tip);
            positions.push(tip);
        }
        (dw, positions)
    }

    // C1: basic creation — node + span + text materialize correctly
    #[test]
    fn basic_creation() {
        let (dw, positions) = linear_history(3);
        let doc_id = DocumentId::new(1);
        let span_id = SpanId::new(10);

        let mut store = AssertionStore::new();
        store.add(
            positions[1],
            AssertionPayload::CreateNode {
                node_id: doc_id.node_id(),
                kind: "document".into(),
            },
        );
        store.add(positions[2], AssertionPayload::CreateSpan { span_id });
        store.add(
            positions[2],
            AssertionPayload::SetSpanText {
                span_id,
                text: "Hello".into(),
            },
        );
        store.add(
            positions[2],
            AssertionPayload::AttachSpanToNode {
                node_id: doc_id.node_id(),
                span_id,
                ordinal: 1,
            },
        );

        let view = dw.trace_view(positions[2]);
        let doc = materialize_document(&store, &view, doc_id);

        let root = doc.root.unwrap();
        assert_eq!(root.node_id, doc_id.node_id());
        assert_eq!(root.kind, "document");
        assert_eq!(root.spans.len(), 1);
        assert_eq!(root.spans[0].span_id, span_id);
        assert_eq!(
            root.spans[0].text.single_value(),
            Some(&"Hello".to_string())
        );
    }

    // C2: visibility filtering — only visible assertions included
    #[test]
    fn visibility_filtering() {
        let (dw, positions) = linear_history(4);

        let span_a = SpanId::new(1);
        let span_b = SpanId::new(2);

        let mut store = AssertionStore::new();
        store.add(positions[1], AssertionPayload::CreateSpan { span_id: span_a });
        store.add(
            positions[1],
            AssertionPayload::SetSpanText {
                span_id: span_a,
                text: "visible".into(),
            },
        );
        store.add(positions[3], AssertionPayload::CreateSpan { span_id: span_b });
        store.add(
            positions[3],
            AssertionPayload::SetSpanText {
                span_id: span_b,
                text: "hidden".into(),
            },
        );

        let view = dw.trace_view(positions[2]);
        let visible = store.visible_assertions(&view);

        assert!(visible.iter().any(|a| matches!(
            &a.payload,
            AssertionPayload::CreateSpan { span_id } if *span_id == span_a
        )));
        assert!(!visible.iter().any(|a| matches!(
            &a.payload,
            AssertionPayload::CreateSpan { span_id } if *span_id == span_b
        )));

        let mat = materialize_span(&store, &view, span_a);
        assert!(mat.is_some());

        let mat = materialize_span(&store, &view, span_b);
        assert!(mat.is_none());
    }

    // C3: same-branch overwrite — latest value on same branch wins
    #[test]
    fn same_branch_overwrite() {
        let (dw, positions) = linear_history(4);
        let span_id = SpanId::new(1);

        let mut store = AssertionStore::new();
        store.add(positions[1], AssertionPayload::CreateSpan { span_id });
        store.add(
            positions[2],
            AssertionPayload::SetSpanText {
                span_id,
                text: "first".into(),
            },
        );
        store.add(
            positions[3],
            AssertionPayload::SetSpanText {
                span_id,
                text: "second".into(),
            },
        );

        let view = dw.trace_view(positions[3]);
        let span = materialize_span(&store, &view, span_id).unwrap();
        assert_eq!(
            span.text,
            AlternativeSet::Single("second".to_string()),
            "same-branch: latest value wins"
        );
    }

    // C4: cross-branch merge — divergent values produce alternatives
    #[test]
    fn cross_branch_merge_alternatives() {
        let mut dw = DagWood::new();
        let root = dw.root();
        let branch_a = dw.new_position();
        let branch_b = dw.new_position();
        let merged = dw.new_successor_after(branch_a, branch_b);

        let span_id = SpanId::new(1);

        let mut store = AssertionStore::new();
        store.add(root, AssertionPayload::CreateSpan { span_id });
        store.add(
            branch_a,
            AssertionPayload::SetSpanText {
                span_id,
                text: "Hello!".into(),
            },
        );
        store.add(
            branch_b,
            AssertionPayload::SetSpanText {
                span_id,
                text: "Hello world".into(),
            },
        );

        let view = dw.trace_view(merged);
        let span = materialize_span(&store, &view, span_id).unwrap();

        match &span.text {
            AlternativeSet::Alternatives(texts) => {
                assert!(texts.contains(&"Hello!".to_string()));
                assert!(texts.contains(&"Hello world".to_string()));
            }
            other => panic!("expected alternatives, got {:?}", other),
        }
    }

    // C5: delete suppression — create + delete → no visible entity
    #[test]
    fn delete_suppression() {
        let (dw, positions) = linear_history(3);
        let span_id = SpanId::new(1);

        let mut store = AssertionStore::new();
        store.add(positions[1], AssertionPayload::CreateSpan { span_id });
        store.add(
            positions[1],
            AssertionPayload::SetSpanText {
                span_id,
                text: "gone".into(),
            },
        );
        store.add(positions[2], AssertionPayload::DeleteSpan { span_id });

        let view = dw.trace_view(positions[2]);
        let span = materialize_span(&store, &view, span_id);
        assert!(span.is_none(), "deleted span should not materialize");
    }

    // C6: structural attachment — spans attached to nodes appear in tree
    #[test]
    fn structural_attachment() {
        let (dw, positions) = linear_history(3);
        let doc_id = DocumentId::new(1);
        let child_id = NodeId::new(2);
        let span_id = SpanId::new(10);

        let mut store = AssertionStore::new();
        store.add(
            positions[1],
            AssertionPayload::CreateNode {
                node_id: doc_id.node_id(),
                kind: "document".into(),
            },
        );
        store.add(
            positions[1],
            AssertionPayload::CreateNode {
                node_id: child_id,
                kind: "paragraph".into(),
            },
        );
        store.add(
            positions[1],
            AssertionPayload::AttachChild {
                parent_id: doc_id.node_id(),
                child_id,
                ordinal: 1,
            },
        );
        store.add(positions[2], AssertionPayload::CreateSpan { span_id });
        store.add(
            positions[2],
            AssertionPayload::SetSpanText {
                span_id,
                text: "text".into(),
            },
        );
        store.add(
            positions[2],
            AssertionPayload::AttachSpanToNode {
                node_id: child_id,
                span_id,
                ordinal: 1,
            },
        );

        let view = dw.trace_view(positions[2]);
        let doc = materialize_document(&store, &view, doc_id);

        let root = doc.root.unwrap();
        assert_eq!(root.children.len(), 1);
        assert_eq!(root.children[0].node_id, child_id);
        assert_eq!(root.children[0].kind, "paragraph");
        assert_eq!(root.children[0].spans.len(), 1);
        assert_eq!(
            root.children[0].spans[0].text.single_value(),
            Some(&"text".to_string())
        );
    }

    // C7: detach child — attached then detached → not in tree
    #[test]
    fn detach_suppression() {
        let (dw, positions) = linear_history(4);
        let parent_id = NodeId::new(1);
        let child_id = NodeId::new(2);

        let mut store = AssertionStore::new();
        store.add(
            positions[1],
            AssertionPayload::CreateNode {
                node_id: parent_id,
                kind: "doc".into(),
            },
        );
        store.add(
            positions[1],
            AssertionPayload::CreateNode {
                node_id: child_id,
                kind: "para".into(),
            },
        );
        store.add(
            positions[1],
            AssertionPayload::AttachChild {
                parent_id,
                child_id,
                ordinal: 1,
            },
        );
        store.add(
            positions[2],
            AssertionPayload::DetachChild {
                parent_id,
                child_id,
            },
        );

        let view = dw.trace_view(positions[3]);
        let node = materialize_node(&store, &view, parent_id).unwrap();
        assert!(node.children.is_empty(), "detached child should not appear");
    }

    // C8: annotation on node
    #[test]
    fn annotation_on_node() {
        let (dw, positions) = linear_history(3);
        let node_id = NodeId::new(1);
        let ann_id = AnnotationId::new(100);

        let mut store = AssertionStore::new();
        store.add(
            positions[1],
            AssertionPayload::CreateNode {
                node_id,
                kind: "doc".into(),
            },
        );
        store.add(
            positions[1],
            AssertionPayload::CreateAnnotation {
                annotation_id: ann_id,
                kind: "bold".into(),
                payload: "true".into(),
            },
        );
        store.add(
            positions[1],
            AssertionPayload::AttachAnnotationToNode {
                annotation_id: ann_id,
                node_id,
            },
        );

        let view = dw.trace_view(positions[2]);
        let node = materialize_node(&store, &view, node_id).unwrap();
        assert_eq!(node.annotations.len(), 1);
        assert_eq!(node.annotations[0].kind, "bold");
    }

    // C9: annotation on span
    #[test]
    fn annotation_on_span() {
        let (dw, positions) = linear_history(3);
        let span_id = SpanId::new(1);
        let ann_id = AnnotationId::new(100);

        let mut store = AssertionStore::new();
        store.add(positions[1], AssertionPayload::CreateSpan { span_id });
        store.add(
            positions[1],
            AssertionPayload::CreateAnnotation {
                annotation_id: ann_id,
                kind: "italic".into(),
                payload: "true".into(),
            },
        );
        store.add(
            positions[1],
            AssertionPayload::AttachAnnotationToSpan {
                annotation_id: ann_id,
                span_id,
            },
        );

        let view = dw.trace_view(positions[2]);
        let span = materialize_span(&store, &view, span_id).unwrap();
        assert_eq!(span.annotations.len(), 1);
        assert_eq!(span.annotations[0].annotation_id, ann_id);
    }

    // C10: delete annotation
    #[test]
    fn delete_annotation() {
        let (dw, positions) = linear_history(3);
        let span_id = SpanId::new(1);
        let ann_id = AnnotationId::new(100);

        let mut store = AssertionStore::new();
        store.add(positions[1], AssertionPayload::CreateSpan { span_id });
        store.add(
            positions[1],
            AssertionPayload::CreateAnnotation {
                annotation_id: ann_id,
                kind: "italic".into(),
                payload: "true".into(),
            },
        );
        store.add(
            positions[1],
            AssertionPayload::AttachAnnotationToSpan {
                annotation_id: ann_id,
                span_id,
            },
        );
        store.add(
            positions[2],
            AssertionPayload::DeleteAnnotation {
                annotation_id: ann_id,
            },
        );

        let view = dw.trace_view(positions[2]);
        let span = materialize_span(&store, &view, span_id).unwrap();
        assert!(span.annotations.is_empty());
    }

    // C11: delete node suppresses children but not annotations on the node itself
    #[test]
    fn delete_node_suppresses() {
        let (dw, positions) = linear_history(3);
        let node_id = NodeId::new(1);

        let mut store = AssertionStore::new();
        store.add(
            positions[1],
            AssertionPayload::CreateNode {
                node_id,
                kind: "doc".into(),
            },
        );
        store.add(positions[2], AssertionPayload::DeleteNode { node_id });

        let view = dw.trace_view(positions[2]);
        let result = materialize_node(&store, &view, node_id);
        assert!(result.is_none());
    }

    // C12: merge with same text on both branches → single value (no alternatives)
    #[test]
    fn merge_agreement_no_alternatives() {
        let mut dw = DagWood::new();
        let root = dw.root();
        let branch_a = dw.new_position();
        let branch_b = dw.new_position();
        let merged = dw.new_successor_after(branch_a, branch_b);

        let span_id = SpanId::new(1);

        let mut store = AssertionStore::new();
        store.add(root, AssertionPayload::CreateSpan { span_id });
        store.add(
            branch_a,
            AssertionPayload::SetSpanText {
                span_id,
                text: "same".into(),
            },
        );
        store.add(
            branch_b,
            AssertionPayload::SetSpanText {
                span_id,
                text: "same".into(),
            },
        );

        let view = dw.trace_view(merged);
        let span = materialize_span(&store, &view, span_id).unwrap();
        assert_eq!(
            span.text,
            AlternativeSet::Single("same".to_string()),
            "branches agree: single value"
        );
    }

    // C13: view before creation → entity not visible
    #[test]
    fn view_before_creation() {
        let (dw, positions) = linear_history(4);
        let span_id = SpanId::new(1);

        let mut store = AssertionStore::new();
        store.add(positions[3], AssertionPayload::CreateSpan { span_id });
        store.add(
            positions[3],
            AssertionPayload::SetSpanText {
                span_id,
                text: "future".into(),
            },
        );

        let view = dw.trace_view(positions[2]);
        let span = materialize_span(&store, &view, span_id);
        assert!(span.is_none(), "span created after view should not be visible");
    }

    // C14: multi-merge chain — alternatives propagate through stacked merges
    #[test]
    fn multi_merge_chain() {
        let mut dw = DagWood::new();
        let root = dw.root();
        let a = dw.new_position();
        let b = dw.new_position();
        let merge1 = dw.new_successor_after(a, b);
        let c = dw.new_position();
        let merge2 = dw.new_successor_after(merge1, c);

        let span_id = SpanId::new(1);

        let mut store = AssertionStore::new();
        store.add(root, AssertionPayload::CreateSpan { span_id });
        store.add(
            a,
            AssertionPayload::SetSpanText {
                span_id,
                text: "alpha".into(),
            },
        );
        store.add(
            b,
            AssertionPayload::SetSpanText {
                span_id,
                text: "beta".into(),
            },
        );
        store.add(
            c,
            AssertionPayload::SetSpanText {
                span_id,
                text: "gamma".into(),
            },
        );

        let view = dw.trace_view(merge2);
        let span = materialize_span(&store, &view, span_id).unwrap();

        match &span.text {
            AlternativeSet::Alternatives(texts) => {
                assert_eq!(texts.len(), 3);
                assert!(texts.contains(&"alpha".to_string()));
                assert!(texts.contains(&"beta".to_string()));
                assert!(texts.contains(&"gamma".to_string()));
            }
            other => panic!("expected 3 alternatives, got {:?}", other),
        }
    }

    // === Merge semantics tests (M1–M5) ===
    // Align with Merge Semantics Design Note v1.

    // M1: compatible merge — different property types coexist.
    // Branch A sets text; branch B adds annotation. Both visible.
    #[test]
    fn merge_compatible_different_properties() {
        let mut dw = DagWood::new();
        let root = dw.root();
        let branch_a = dw.new_position();
        let branch_b = dw.new_position();
        let merged = dw.new_successor_after(branch_a, branch_b);

        let span_id = SpanId::new(1);
        let ann_id = AnnotationId::new(100);

        let mut store = AssertionStore::new();
        store.add(root, AssertionPayload::CreateSpan { span_id });
        store.add(
            branch_a,
            AssertionPayload::SetSpanText {
                span_id,
                text: "Hello".into(),
            },
        );
        store.add(
            branch_b,
            AssertionPayload::CreateAnnotation {
                annotation_id: ann_id,
                kind: "comment".into(),
                payload: "needs review".into(),
            },
        );
        store.add(
            branch_b,
            AssertionPayload::AttachAnnotationToSpan {
                annotation_id: ann_id,
                span_id,
            },
        );

        let view = dw.trace_view(merged);
        let span = materialize_span(&store, &view, span_id).unwrap();

        assert_eq!(span.text, AlternativeSet::Single("Hello".to_string()));
        assert_eq!(span.annotations.len(), 1);
        assert_eq!(span.annotations[0].kind, "comment");
        assert_eq!(span.annotations[0].payload, "needs review");
    }

    // M4: delete vs modify in merge context.
    // Branch A sets text; branch B deletes span. Delete wins.
    #[test]
    fn merge_delete_vs_modify() {
        let mut dw = DagWood::new();
        let root = dw.root();
        let branch_a = dw.new_position();
        let branch_b = dw.new_position();
        let merged = dw.new_successor_after(branch_a, branch_b);

        let span_id = SpanId::new(1);

        let mut store = AssertionStore::new();
        store.add(root, AssertionPayload::CreateSpan { span_id });
        store.add(
            branch_a,
            AssertionPayload::SetSpanText {
                span_id,
                text: "Hello!".into(),
            },
        );
        store.add(branch_b, AssertionPayload::DeleteSpan { span_id });

        let view = dw.trace_view(merged);
        let span = materialize_span(&store, &view, span_id);
        assert!(
            span.is_none(),
            "delete wins over modify in merge: span should not exist"
        );
    }

    // M2: text conflict → alternatives.
    // Two branches diverge on span text. Each branch alone shows a single
    // resolved value; the merge view shows both as alternatives.
    // This proves that merge does NOT auto-resolve text conflicts.
    #[test]
    fn merge_text_conflict_produces_alternatives() {
        let mut dw = DagWood::new();
        let root = dw.root();
        let branch_a = dw.new_position();
        let branch_b = dw.new_position();
        let merged = dw.new_successor_after(branch_a, branch_b);

        let span_id = SpanId::new(1);

        let mut store = AssertionStore::new();
        store.add(root, AssertionPayload::CreateSpan { span_id });
        store.add(
            branch_a,
            AssertionPayload::SetSpanText {
                span_id,
                text: "Hello!".into(),
            },
        );
        store.add(
            branch_b,
            AssertionPayload::SetSpanText {
                span_id,
                text: "Hello world".into(),
            },
        );

        let view_a = dw.trace_view(branch_a);
        let span_a = materialize_span(&store, &view_a, span_id).unwrap();
        assert_eq!(
            span_a.text,
            AlternativeSet::Single("Hello!".to_string()),
            "branch A alone: single resolved value"
        );

        let view_b = dw.trace_view(branch_b);
        let span_b = materialize_span(&store, &view_b, span_id).unwrap();
        assert_eq!(
            span_b.text,
            AlternativeSet::Single("Hello world".to_string()),
            "branch B alone: single resolved value"
        );

        let view_merged = dw.trace_view(merged);
        let span_merged = materialize_span(&store, &view_merged, span_id).unwrap();
        match &span_merged.text {
            AlternativeSet::Alternatives(texts) => {
                assert_eq!(texts.len(), 2, "merge of text conflict: exactly 2 alternatives");
                assert!(texts.contains(&"Hello!".to_string()));
                assert!(texts.contains(&"Hello world".to_string()));
            }
            other => panic!("expected Alternatives for text conflict, got {:?}", other),
        }
    }

    // M3: agreement collapse.
    // Two branches set the same text value on a span. The merge collapses
    // to AlternativeSet::Single — branches that agree deduplicate.
    #[test]
    fn merge_agreement_collapses() {
        let mut dw = DagWood::new();
        let root = dw.root();
        let branch_a = dw.new_position();
        let branch_b = dw.new_position();
        let merged = dw.new_successor_after(branch_a, branch_b);

        let span_id = SpanId::new(1);

        let mut store = AssertionStore::new();
        store.add(root, AssertionPayload::CreateSpan { span_id });
        store.add(
            branch_a,
            AssertionPayload::SetSpanText {
                span_id,
                text: "agreed".into(),
            },
        );
        store.add(
            branch_b,
            AssertionPayload::SetSpanText {
                span_id,
                text: "agreed".into(),
            },
        );

        let view = dw.trace_view(merged);
        let span = materialize_span(&store, &view, span_id).unwrap();
        assert_eq!(
            span.text,
            AlternativeSet::Single("agreed".to_string()),
            "branches agree: collapses to single value, not Alternatives(vec![one])"
        );
    }

    // M5: multi-merge alternatives preserved (diamond-of-diamonds).
    // Four branches, two sub-merges, then a final merge of both sub-merges.
    // Alternatives from both sub-merges survive in the final merge.
    //
    //        root
    //      / / \ \
    //     A  B  C  D
    //      \/    \/
    //     AB     CD
    //        \  /
    //        ABCD
    #[test]
    fn merge_multi_merge_preserves_alternatives() {
        let mut dw = DagWood::new();
        let root = dw.root();
        let a = dw.new_position();
        let b = dw.new_position();
        let c = dw.new_position();
        let d = dw.new_position();
        let merge_ab = dw.new_successor_after(a, b);
        let merge_cd = dw.new_successor_after(c, d);
        let merge_all = dw.new_successor_after(merge_ab, merge_cd);

        let span_id = SpanId::new(1);

        let mut store = AssertionStore::new();
        store.add(root, AssertionPayload::CreateSpan { span_id });
        store.add(
            a,
            AssertionPayload::SetSpanText {
                span_id,
                text: "alpha".into(),
            },
        );
        store.add(
            b,
            AssertionPayload::SetSpanText {
                span_id,
                text: "beta".into(),
            },
        );
        store.add(
            c,
            AssertionPayload::SetSpanText {
                span_id,
                text: "gamma".into(),
            },
        );
        store.add(
            d,
            AssertionPayload::SetSpanText {
                span_id,
                text: "delta".into(),
            },
        );

        let view_ab = dw.trace_view(merge_ab);
        let span_ab = materialize_span(&store, &view_ab, span_id).unwrap();
        match &span_ab.text {
            AlternativeSet::Alternatives(texts) => {
                assert_eq!(texts.len(), 2, "sub-merge AB: 2 alternatives");
                assert!(texts.contains(&"alpha".to_string()));
                assert!(texts.contains(&"beta".to_string()));
            }
            other => panic!("expected 2 alternatives in sub-merge AB, got {:?}", other),
        }

        let view_cd = dw.trace_view(merge_cd);
        let span_cd = materialize_span(&store, &view_cd, span_id).unwrap();
        match &span_cd.text {
            AlternativeSet::Alternatives(texts) => {
                assert_eq!(texts.len(), 2, "sub-merge CD: 2 alternatives");
                assert!(texts.contains(&"gamma".to_string()));
                assert!(texts.contains(&"delta".to_string()));
            }
            other => panic!("expected 2 alternatives in sub-merge CD, got {:?}", other),
        }

        let view_all = dw.trace_view(merge_all);
        let span_all = materialize_span(&store, &view_all, span_id).unwrap();
        match &span_all.text {
            AlternativeSet::Alternatives(texts) => {
                assert_eq!(texts.len(), 4, "final merge: all 4 alternatives preserved");
                assert!(texts.contains(&"alpha".to_string()));
                assert!(texts.contains(&"beta".to_string()));
                assert!(texts.contains(&"gamma".to_string()));
                assert!(texts.contains(&"delta".to_string()));
            }
            other => panic!(
                "expected 4 alternatives in final merge, got {:?}",
                other
            ),
        }
    }

    // === Serde round-trip tests (S1–S18) ===

    #[cfg(feature = "serde_json")]
    fn serde_round_trip<T: serde::Serialize + serde::de::DeserializeOwned + PartialEq + std::fmt::Debug>(
        value: &T,
    ) {
        let json = serde_json::to_string(value).unwrap();
        let back: T = serde_json::from_str(&json).unwrap();
        assert_eq!(*value, back, "round-trip failed for: {}", json);
    }

    #[cfg(feature = "serde_json")]
    #[test]
    fn serde_id_types_round_trip() {
        assert_eq!(serde_json::to_string(&DocumentId::new(42)).unwrap(), "42");
        serde_round_trip(&DocumentId::new(0));
        serde_round_trip(&DocumentId::new(1));
        serde_round_trip(&DocumentId::new(999));
        serde_round_trip(&NodeId::new(100));
        serde_round_trip(&SpanId::new(200));
        serde_round_trip(&AnnotationId::new(300));
        serde_round_trip(&AssertionId(400));
    }

    #[cfg(feature = "serde_json")]
    #[test]
    fn serde_id_values_are_json_numbers() {
        assert_eq!(serde_json::to_string(&DocumentId::new(7)).unwrap(), "7");
        assert_eq!(serde_json::to_string(&NodeId::new(8)).unwrap(), "8");
        assert_eq!(serde_json::to_string(&SpanId::new(9)).unwrap(), "9");
        assert_eq!(serde_json::to_string(&AnnotationId::new(10)).unwrap(), "10");
    }

    #[cfg(feature = "serde_json")]
    #[test]
    fn serde_payload_all_variants_round_trip() {
        let payloads = vec![
            AssertionPayload::CreateNode { node_id: NodeId::new(1), kind: "doc".into() },
            AssertionPayload::AttachChild { parent_id: NodeId::new(1), child_id: NodeId::new(2), ordinal: 0 },
            AssertionPayload::DetachChild { parent_id: NodeId::new(1), child_id: NodeId::new(2) },
            AssertionPayload::DeleteNode { node_id: NodeId::new(1) },
            AssertionPayload::CreateSpan { span_id: SpanId::new(10) },
            AssertionPayload::SetSpanText { span_id: SpanId::new(10), text: "hello".into() },
            AssertionPayload::DeleteSpan { span_id: SpanId::new(10) },
            AssertionPayload::AttachSpanToNode { node_id: NodeId::new(1), span_id: SpanId::new(10), ordinal: 1 },
            AssertionPayload::DetachSpanFromNode { node_id: NodeId::new(1), span_id: SpanId::new(10) },
            AssertionPayload::CreateAnnotation { annotation_id: AnnotationId::new(100), kind: "bold".into(), payload: "true".into() },
            AssertionPayload::AttachAnnotationToNode { annotation_id: AnnotationId::new(100), node_id: NodeId::new(1) },
            AssertionPayload::AttachAnnotationToSpan { annotation_id: AnnotationId::new(100), span_id: SpanId::new(10) },
            AssertionPayload::DeleteAnnotation { annotation_id: AnnotationId::new(100) },
        ];
        for payload in &payloads {
            serde_round_trip(payload);
        }
    }

    #[cfg(feature = "serde_json")]
    #[test]
    fn serde_alternative_set_round_trip() {
        serde_round_trip(&AlternativeSet::Single("hello".to_string()));
        serde_round_trip(&AlternativeSet::<String>::Alternatives(vec!["alpha".into(), "beta".into()]));
        serde_round_trip(&AlternativeSet::<String>::Alternatives(vec![]));
    }

    #[cfg(feature = "serde_json")]
    #[test]
    fn serde_alternative_set_json_structure() {
        let single = serde_json::to_string(&AlternativeSet::Single("hello".to_string())).unwrap();
        assert!(single.contains("\"Single\""), "Single variant: {}", single);
        let alt = serde_json::to_string(
            &AlternativeSet::<String>::Alternatives(vec!["a".into(), "b".into()])
        ).unwrap();
        assert!(alt.contains("\"Alternatives\""), "Alternatives variant: {}", alt);
    }

    #[cfg(feature = "serde_json")]
    #[test]
    fn serde_full_document_round_trip() {
        let (dw, positions) = linear_history(3);
        let doc_id = DocumentId::new(1);
        let span_id = SpanId::new(10);
        let ann_id = AnnotationId::new(100);
        let mut store = AssertionStore::new();
        store.add(positions[1], AssertionPayload::CreateNode { node_id: doc_id.node_id(), kind: "document".into() });
        store.add(positions[2], AssertionPayload::CreateSpan { span_id });
        store.add(positions[2], AssertionPayload::SetSpanText { span_id, text: "Hello".into() });
        store.add(positions[2], AssertionPayload::AttachSpanToNode { node_id: doc_id.node_id(), span_id, ordinal: 1 });
        store.add(positions[2], AssertionPayload::CreateAnnotation { annotation_id: ann_id, kind: "bold".into(), payload: "true".into() });
        store.add(positions[2], AssertionPayload::AttachAnnotationToSpan { annotation_id: ann_id, span_id });
        let view = dw.trace_view(positions[2]);
        let doc = materialize_document(&store, &view, doc_id);
        let json = serde_json::to_string(&doc).unwrap();
        let parsed: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert_eq!(parsed["doc_id"], 1);
        assert_eq!(parsed["root"]["node_id"], 1);
        assert_eq!(parsed["root"]["kind"], "document");
        assert_eq!(parsed["root"]["spans"][0]["span_id"], 10);
        assert_eq!(parsed["root"]["spans"][0]["text"]["Single"], "Hello");
        assert_eq!(parsed["root"]["spans"][0]["annotations"][0]["kind"], "bold");
        let back: MaterializedDocument = serde_json::from_str(&json).unwrap();
        assert_eq!(doc, back);
    }

    #[cfg(feature = "serde_json")]
    #[test]
    fn serde_cross_branch_alternatives() {
        let mut dw = DagWood::new();
        let root = dw.root();
        let a = dw.new_position();
        let b = dw.new_position();
        let merged = dw.new_successor_after(a, b);
        let span_id = SpanId::new(1);
        let mut store = AssertionStore::new();
        store.add(root, AssertionPayload::CreateSpan { span_id });
        store.add(a, AssertionPayload::SetSpanText { span_id, text: "Hello!".into() });
        store.add(b, AssertionPayload::SetSpanText { span_id, text: "Hello world".into() });
        let view = dw.trace_view(merged);
        let span = materialize_span(&store, &view, span_id).unwrap();
        let json = serde_json::to_string(&span).unwrap();
        let parsed: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert!(parsed["text"]["Alternatives"].is_array());
        let alts = parsed["text"]["Alternatives"].as_array().unwrap();
        assert_eq!(alts.len(), 2);
        assert!(alts.iter().any(|v| v.as_str() == Some("Hello!")));
        assert!(alts.iter().any(|v| v.as_str() == Some("Hello world")));
        let back: MaterializedSpan = serde_json::from_str(&json).unwrap();
        assert_eq!(span, back);
    }

    #[cfg(feature = "serde_json")]
    #[test]
    fn serde_nested_children_round_trip() {
        let (dw, positions) = linear_history(4);
        let parent_id = NodeId::new(1);
        let child_id = NodeId::new(2);
        let grandchild_id = NodeId::new(3);
        let mut store = AssertionStore::new();
        store.add(positions[1], AssertionPayload::CreateNode { node_id: parent_id, kind: "doc".into() });
        store.add(positions[1], AssertionPayload::CreateNode { node_id: child_id, kind: "para".into() });
        store.add(positions[1], AssertionPayload::CreateNode { node_id: grandchild_id, kind: "span_node".into() });
        store.add(positions[1], AssertionPayload::AttachChild { parent_id, child_id, ordinal: 1 });
        store.add(positions[1], AssertionPayload::AttachChild { parent_id: child_id, child_id: grandchild_id, ordinal: 1 });
        let view = dw.trace_view(positions[3]);
        let node = materialize_node(&store, &view, parent_id).unwrap();
        let json = serde_json::to_string(&node).unwrap();
        let parsed: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert_eq!(parsed["children"][0]["node_id"], 2);
        assert_eq!(parsed["children"][0]["children"][0]["node_id"], 3);
        let back: MaterializedNode = serde_json::from_str(&json).unwrap();
        assert_eq!(node, back);
    }

    #[cfg(feature = "serde_json")]
    #[test]
    fn serde_missing_document_null_root() {
        let (dw, positions) = linear_history(3);
        let store = AssertionStore::new();
        let view = dw.trace_view(positions[2]);
        let doc = materialize_document(&store, &view, DocumentId::new(999));
        let json = serde_json::to_string(&doc).unwrap();
        let parsed: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert_eq!(parsed["doc_id"], 999);
        assert!(parsed["root"].is_null());
    }

    #[cfg(feature = "serde_json")]
    #[test]
    fn serde_empty_string_preserved() {
        let (dw, positions) = linear_history(3);
        let span_id = SpanId::new(1);
        let mut store = AssertionStore::new();
        store.add(positions[1], AssertionPayload::CreateSpan { span_id });
        store.add(positions[1], AssertionPayload::SetSpanText { span_id, text: String::new() });
        let view = dw.trace_view(positions[2]);
        let span = materialize_span(&store, &view, span_id).unwrap();
        let json = serde_json::to_string(&span).unwrap();
        let parsed: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert_eq!(parsed["text"]["Single"].as_str(), Some(""));
    }

    #[cfg(feature = "serde_json")]
    #[test]
    fn serde_deleted_entity_is_null() {
        let (dw, positions) = linear_history(3);
        let span_id = SpanId::new(1);
        let mut store = AssertionStore::new();
        store.add(positions[1], AssertionPayload::CreateSpan { span_id });
        store.add(positions[2], AssertionPayload::DeleteSpan { span_id });
        let view = dw.trace_view(positions[2]);
        assert!(materialize_span(&store, &view, span_id).is_none());
        assert_eq!(serde_json::to_string(&materialize_span(&store, &view, span_id)).unwrap(), "null");
    }

    #[cfg(feature = "serde_json")]
    #[test]
    fn serde_unicode_text_round_trip() {
        let (dw, positions) = linear_history(3);
        let span_id = SpanId::new(1);
        let text = "你好世界 🌍 こんにちは";
        let mut store = AssertionStore::new();
        store.add(positions[1], AssertionPayload::CreateSpan { span_id });
        store.add(positions[1], AssertionPayload::SetSpanText { span_id, text: text.into() });
        let view = dw.trace_view(positions[2]);
        let span = materialize_span(&store, &view, span_id).unwrap();
        let json = serde_json::to_string(&span).unwrap();
        let back: MaterializedSpan = serde_json::from_str(&json).unwrap();
        assert_eq!(back.text, AlternativeSet::Single(text.to_string()));
    }

    #[cfg(feature = "serde_json")]
    #[test]
    fn serde_payload_from_js_format() {
        let cases: Vec<(&str, AssertionPayload)> = vec![
            (r#"{"CreateNode":{"node_id":1,"kind":"document"}}"#,
             AssertionPayload::CreateNode { node_id: NodeId::new(1), kind: "document".into() }),
            (r#"{"SetSpanText":{"span_id":10,"text":"Hello"}}"#,
             AssertionPayload::SetSpanText { span_id: SpanId::new(10), text: "Hello".into() }),
            (r#"{"DeleteNode":{"node_id":5}}"#,
             AssertionPayload::DeleteNode { node_id: NodeId::new(5) }),
            (r#"{"AttachChild":{"parent_id":1,"child_id":2,"ordinal":0}}"#,
             AssertionPayload::AttachChild { parent_id: NodeId::new(1), child_id: NodeId::new(2), ordinal: 0 }),
            (r#"{"CreateAnnotation":{"annotation_id":100,"kind":"bold","payload":"true"}}"#,
             AssertionPayload::CreateAnnotation { annotation_id: AnnotationId::new(100), kind: "bold".into(), payload: "true".into() }),
        ];
        for (json, expected) in cases {
            assert_eq!(serde_json::from_str::<AssertionPayload>(json).unwrap(), expected, "failed: {}", json);
        }
    }

    #[cfg(feature = "serde_json")]
    #[test]
    fn serde_payload_rejects_invalid() {
        assert!(serde_json::from_str::<AssertionPayload>(r#"{"not_a_variant":true}"#).is_err());
    }

    #[cfg(feature = "serde_json")]
    #[test]
    fn serde_annotation_round_trip() {
        serde_round_trip(&MaterializedAnnotation {
            annotation_id: AnnotationId::new(42),
            kind: "comment".into(),
            payload: "needs review".into(),
        });
    }

    #[cfg(feature = "serde_json")]
    #[test]
    fn serde_entity_id_round_trip() {
        serde_round_trip(&EntityId::Node(NodeId::new(1)));
        serde_round_trip(&EntityId::Span(SpanId::new(2)));
        serde_round_trip(&EntityId::Annotation(AnnotationId::new(3)));
    }

    // =====================================================================
    // Stress tests (P3, P4, P5)
    // Run with: cargo test --features "serde,serde_json" -- --ignored
    // =====================================================================

    // P3: stress_materialize_100k_assertions — 100,000 visible assertions.
    // 1000 child nodes x 10 spans each x 10 assertions per span.
    // Materializes the full document. Exercises O(V*N) linear scan.
    #[test]
    #[ignore]
    fn stress_materialize_100k_assertions() {
        use std::time::Instant;
        let t = Instant::now();
        let (dw, positions) = linear_history(3);
        let pos = positions[1];

        let mut store = AssertionStore::new();
        let doc_id = DocumentId::new(1);
        store.add(pos, AssertionPayload::CreateNode { node_id: doc_id.node_id(), kind: "document".into() });

        let n_children = 1000usize;
        let n_spans = 10usize;

        let mut child_ids = Vec::new();
        for i in 0..n_children {
            let nid = NodeId::new(100 + i as u64);
            child_ids.push(nid);
            store.add(pos, AssertionPayload::CreateNode { node_id: nid, kind: "paragraph".into() });
            store.add(pos, AssertionPayload::AttachChild { parent_id: doc_id.node_id(), child_id: nid, ordinal: i as u32 });
        }
        eprintln!("  P3 create {} nodes: {:.3}s", n_children, t.elapsed().as_secs_f64());

        for (i, &nid) in child_ids.iter().enumerate() {
            for j in 0..n_spans {
                let sid = SpanId::new(10_000 + (i as u64) * 10 + j as u64);
                store.add(pos, AssertionPayload::CreateSpan { span_id: sid });
                store.add(pos, AssertionPayload::SetSpanText { span_id: sid, text: format!("text-{}-{}", i, j) });
                store.add(pos, AssertionPayload::AttachSpanToNode { node_id: nid, span_id: sid, ordinal: j as u32 });
            }
        }
        eprintln!("  P3 {} total assertions added: {:.3}s", store.all_assertions().len(), t.elapsed().as_secs_f64());

        let t2 = Instant::now();
        let view = dw.trace_view(positions[2]);
        eprintln!("  P3 TraceView: {:.3}s", t2.elapsed().as_secs_f64());

        let t3 = Instant::now();
        let doc = materialize_document(&store, &view, doc_id);
        eprintln!("  P3 materialize: {:.3}s", t3.elapsed().as_secs_f64());

        let root = doc.root.expect("document should have a root");
        assert_eq!(root.kind, "document");
        assert_eq!(root.children.len(), n_children);
        for child in &root.children {
            assert_eq!(child.spans.len(), n_spans);
        }
        eprintln!("  P3 total: {:.3}s", t.elapsed().as_secs_f64());
    }

    // P4: stress_deep_nesting — deeply nested node levels.
    // Exercises recursive materialize_node_internal stack depth and
    // the O(V*D) cost of repeated linear scans. Depth limited to 500
    // due to default test stack size (2MB); run with RUST_MIN_STACK=64MB
    // to push higher.
    #[test]
    #[ignore]
    fn stress_deep_nesting() {
        use std::time::Instant;
        let t = Instant::now();
        let (dw, positions) = linear_history(3);
        let pos = positions[1];

        let depth = 500;
        let mut store = AssertionStore::new();
        let mut parent_id = NodeId::new(1);
        store.add(pos, AssertionPayload::CreateNode { node_id: parent_id, kind: "level_0".into() });

        for d in 1..depth {
            let child_id = NodeId::new(1 + d as u64);
            store.add(pos, AssertionPayload::CreateNode { node_id: child_id, kind: format!("level_{}", d) });
            store.add(pos, AssertionPayload::AttachChild { parent_id, child_id, ordinal: 1 });
            parent_id = child_id;
        }
        eprintln!("  P4 build {} levels ({} assertions): {:.3}s", depth, store.all_assertions().len(), t.elapsed().as_secs_f64());

        let t2 = Instant::now();
        let view = dw.trace_view(positions[2]);
        let doc = materialize_document(&store, &view, DocumentId::new(1));
        eprintln!("  P4 materialize {} levels: {:.3}s", depth, t2.elapsed().as_secs_f64());

        let root = doc.root.expect("should have root");
        let mut node = &root;
        for d in 0..depth {
            assert_eq!(node.kind, format!("level_{}", d), "wrong kind at depth {}", d);
            if d < depth - 1 {
                assert_eq!(node.children.len(), 1);
                node = &node.children[0];
            } else {
                assert!(node.children.is_empty());
            }
        }
        eprintln!("  P4 total: {:.3}s", t.elapsed().as_secs_f64());
        eprintln!("  NOTE: To test deeper nesting (1K+), run with: RUST_MIN_STACK=67108864 cargo test ... --ignored");
    }

    // P5: stress_10k_branch_alternatives — 10,000 conflicting branches on one span.
    // Each branch sets different text. All merged via binary tree of merges.
    // Materialized span should contain all 10K alternatives.
    #[test]
    #[ignore]
    fn stress_10k_branch_alternatives() {
        use std::time::Instant;
        let t = Instant::now();
        let mut dw = DagWood::new();
        let root = dw.root();

        let span_id = SpanId::new(1);
        let mut store = AssertionStore::new();
        store.add(root, AssertionPayload::CreateSpan { span_id });

        let n_branches = 10_000usize;
        let mut branches: Vec<TracePosition> = Vec::new();
        for i in 0..n_branches {
            let branch = dw.new_position();
            store.add(branch, AssertionPayload::SetSpanText {
                span_id,
                text: format!("version_{}", i),
            });
            branches.push(branch);
        }
        eprintln!("  P5 create {} branches: {:.3}s", n_branches, t.elapsed().as_secs_f64());

        let t2 = Instant::now();
        while branches.len() > 1 {
            let mut merged = Vec::new();
            let mut i = 0;
            while i + 1 < branches.len() {
                let m = dw.new_successor_after(branches[i], branches[i + 1]);
                merged.push(m);
                i += 2;
            }
            if branches.len() % 2 == 1 {
                merged.push(branches[branches.len() - 1]);
            }
            branches = merged;
        }
        eprintln!("  P5 merge tree: {:.3}s", t2.elapsed().as_secs_f64());

        let t3 = Instant::now();
        let view = dw.trace_view(branches[0]);
        eprintln!("  P5 TraceView: {:.3}s", t3.elapsed().as_secs_f64());

        let t4 = Instant::now();
        let span = materialize_span(&store, &view, span_id).expect("span should exist");
        eprintln!("  P5 materialize span: {:.3}s", t4.elapsed().as_secs_f64());

        match &span.text {
            AlternativeSet::Alternatives(texts) => {
                assert!(texts.len() >= 9000, "expected ~10K alternatives, got {}", texts.len());
                for i in 0..n_branches {
                    let expected = format!("version_{}", i);
                    assert!(texts.contains(&expected), "missing alternative: {}", expected);
                }
            }
            other => panic!("expected Alternatives, got {:?}", other),
        }
        eprintln!("  P5 total: {:.3}s", t.elapsed().as_secs_f64());
    }

    // =====================================================================
    // Missing coverage tests
    // =====================================================================

    #[test]
    fn materialize_entity_node() {
        let (dw, positions) = linear_history(3);
        let mut store = AssertionStore::new();
        let nid = NodeId::new(1);
        store.add(positions[1], AssertionPayload::CreateNode { node_id: nid, kind: "doc".into() });
        let view = dw.trace_view(positions[2]);
        let entity = materialize_entity(&store, &view, EntityId::Node(nid));
        match entity {
            MaterializedEntity::Node(n) => assert_eq!(n.node_id, nid),
            other => panic!("expected Node, got {:?}", other),
        }
    }

    #[test]
    fn materialize_entity_span() {
        let (dw, positions) = linear_history(3);
        let mut store = AssertionStore::new();
        let sid = SpanId::new(1);
        store.add(positions[1], AssertionPayload::CreateSpan { span_id: sid });
        store.add(positions[1], AssertionPayload::SetSpanText { span_id: sid, text: "hi".into() });
        let view = dw.trace_view(positions[2]);
        let entity = materialize_entity(&store, &view, EntityId::Span(sid));
        match entity {
            MaterializedEntity::Span(s) => assert_eq!(s.span_id, sid),
            other => panic!("expected Span, got {:?}", other),
        }
    }

    #[test]
    fn materialize_entity_annotation() {
        let (dw, positions) = linear_history(3);
        let mut store = AssertionStore::new();
        let aid = AnnotationId::new(1);
        store.add(positions[1], AssertionPayload::CreateAnnotation {
            annotation_id: aid, kind: "note".into(), payload: "x".into(),
        });
        let view = dw.trace_view(positions[2]);
        let entity = materialize_entity(&store, &view, EntityId::Annotation(aid));
        match entity {
            MaterializedEntity::Annotation(a) => assert_eq!(a.annotation_id, aid),
            other => panic!("expected Annotation, got {:?}", other),
        }
    }

    #[test]
    fn materialize_entity_not_found() {
        let (dw, positions) = linear_history(3);
        let store = AssertionStore::new();
        let view = dw.trace_view(positions[2]);
        let entity = materialize_entity(&store, &view, EntityId::Node(NodeId::new(999)));
        assert_eq!(entity, MaterializedEntity::NotFound);
    }

    #[test]
    fn alternative_set_values() {
        let single = AlternativeSet::Single("a".to_string());
        assert_eq!(single.values(), &["a"]);
        let multi = AlternativeSet::<String>::Alternatives(vec!["x".into(), "y".into()]);
        assert_eq!(multi.values(), &["x", "y"]);
    }

    #[test]
    fn alternative_set_is_single() {
        assert!(AlternativeSet::Single("a".to_string()).is_single());
        assert!(!AlternativeSet::<String>::Alternatives(vec!["a".into()]).is_single());
    }

    #[test]
    fn alternative_set_single_value() {
        assert_eq!(AlternativeSet::Single("a".to_string()).single_value(), Some(&"a".to_string()));
        assert_eq!(AlternativeSet::<String>::Alternatives(vec!["a".into()]).single_value(), None);
    }

    #[test]
    fn alternative_set_empty_alternatives() {
        let empty = AlternativeSet::<String>::Alternatives(vec![]);
        assert_eq!(empty.values().len(), 0);
        assert!(!empty.is_single());
    }

    #[test]
    fn all_assertions_accessor() {
        let mut store = AssertionStore::new();
        assert_eq!(store.all_assertions().len(), 0);
        let (dw, positions) = linear_history(2);
        store.add(positions[1], AssertionPayload::CreateNode { node_id: NodeId::new(1), kind: "doc".into() });
        assert_eq!(store.all_assertions().len(), 1);
    }
}
