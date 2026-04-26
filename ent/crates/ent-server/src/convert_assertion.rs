use ent_api_types::assertions::AssertionRequest;
use ent_core::ent::content::{
    AnnotationId, AssertionPayload, NodeId, SpanId,
};

pub fn convert_assertion(req: AssertionRequest) -> AssertionPayload {
    match req {
        AssertionRequest::CreateNode { node_id, kind } => AssertionPayload::CreateNode {
            node_id: NodeId::new(node_id),
            kind,
        },
        AssertionRequest::AttachChild {
            parent_id,
            child_id,
            ordinal,
        } => AssertionPayload::AttachChild {
            parent_id: NodeId::new(parent_id),
            child_id: NodeId::new(child_id),
            ordinal,
        },
        AssertionRequest::DetachChild {
            parent_id,
            child_id,
        } => AssertionPayload::DetachChild {
            parent_id: NodeId::new(parent_id),
            child_id: NodeId::new(child_id),
        },
        AssertionRequest::DeleteNode { node_id } => AssertionPayload::DeleteNode {
            node_id: NodeId::new(node_id),
        },
        AssertionRequest::CreateSpan { span_id } => AssertionPayload::CreateSpan {
            span_id: SpanId::new(span_id),
        },
        AssertionRequest::SetSpanText { span_id, text } => AssertionPayload::SetSpanText {
            span_id: SpanId::new(span_id),
            text,
        },
        AssertionRequest::DeleteSpan { span_id } => AssertionPayload::DeleteSpan {
            span_id: SpanId::new(span_id),
        },
        AssertionRequest::AttachSpanToNode {
            node_id,
            span_id,
            ordinal,
        } => AssertionPayload::AttachSpanToNode {
            node_id: NodeId::new(node_id),
            span_id: SpanId::new(span_id),
            ordinal,
        },
        AssertionRequest::DetachSpanFromNode { node_id, span_id } => {
            AssertionPayload::DetachSpanFromNode {
                node_id: NodeId::new(node_id),
                span_id: SpanId::new(span_id),
            }
        }
        AssertionRequest::CreateAnnotation {
            annotation_id,
            kind,
            payload,
        } => AssertionPayload::CreateAnnotation {
            annotation_id: AnnotationId::new(annotation_id),
            kind,
            payload,
        },
        AssertionRequest::AttachAnnotationToNode {
            annotation_id,
            node_id,
        } => AssertionPayload::AttachAnnotationToNode {
            annotation_id: AnnotationId::new(annotation_id),
            node_id: NodeId::new(node_id),
        },
        AssertionRequest::AttachAnnotationToSpan {
            annotation_id,
            span_id,
        } => AssertionPayload::AttachAnnotationToSpan {
            annotation_id: AnnotationId::new(annotation_id),
            span_id: SpanId::new(span_id),
        },
        AssertionRequest::DeleteAnnotation { annotation_id } => {
            AssertionPayload::DeleteAnnotation {
                annotation_id: AnnotationId::new(annotation_id),
            }
        }
    }
}
