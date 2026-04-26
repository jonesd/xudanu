use ent_api_types::document::{
    ApiAnnotation, ApiNode, ApiSpan, ApiText, DocumentResponse,
};
use ent_core::ent::content::{
    AlternativeSet, MaterializedAnnotation, MaterializedDocument, MaterializedNode,
    MaterializedSpan,
};

use ent_core::ent::id_codec;

pub fn convert_document(
    workspace_id: &str,
    trace_id: &str,
    doc: &MaterializedDocument,
) -> DocumentResponse {
    DocumentResponse {
        workspace_id: workspace_id.to_string(),
        trace_id: trace_id.to_string(),
        document: doc.root.as_ref().map(convert_node),
    }
}

fn convert_node(node: &MaterializedNode) -> ApiNode {
    ApiNode {
        node_id: id_codec::encode_node(node.node_id),
        kind: node.kind.clone(),
        children: node.children.iter().map(convert_node).collect(),
        spans: node.spans.iter().map(convert_span).collect(),
        annotations: node.annotations.iter().map(convert_annotation).collect(),
    }
}

fn convert_span(span: &MaterializedSpan) -> ApiSpan {
    ApiSpan {
        span_id: id_codec::encode_span(span.span_id),
        text: convert_text(&span.text),
        annotations: span.annotations.iter().map(convert_annotation).collect(),
    }
}

fn convert_text(text: &AlternativeSet<String>) -> ApiText {
    match text {
        AlternativeSet::Single(v) => ApiText::Single { value: v.clone() },
        AlternativeSet::Alternatives(vals) => ApiText::Alternatives {
            values: vals.clone(),
        },
    }
}

fn convert_annotation(ann: &MaterializedAnnotation) -> ApiAnnotation {
    ApiAnnotation {
        annotation_id: id_codec::encode_annotation(ann.annotation_id),
        kind: ann.kind.clone(),
        payload: ann.payload.clone(),
    }
}
