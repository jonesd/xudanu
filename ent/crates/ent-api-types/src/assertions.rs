use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize)]
#[serde(tag = "type")]
pub enum AssertionRequest {
    CreateNode {
        #[serde(rename = "nodeId")]
        node_id: u64,
        kind: String,
    },
    AttachChild {
        #[serde(rename = "parentId")]
        parent_id: u64,
        #[serde(rename = "childId")]
        child_id: u64,
        ordinal: u32,
    },
    DetachChild {
        #[serde(rename = "parentId")]
        parent_id: u64,
        #[serde(rename = "childId")]
        child_id: u64,
    },
    DeleteNode {
        #[serde(rename = "nodeId")]
        node_id: u64,
    },
    CreateSpan {
        #[serde(rename = "spanId")]
        span_id: u64,
    },
    SetSpanText {
        #[serde(rename = "spanId")]
        span_id: u64,
        text: String,
    },
    DeleteSpan {
        #[serde(rename = "spanId")]
        span_id: u64,
    },
    AttachSpanToNode {
        #[serde(rename = "nodeId")]
        node_id: u64,
        #[serde(rename = "spanId")]
        span_id: u64,
        ordinal: u32,
    },
    DetachSpanFromNode {
        #[serde(rename = "nodeId")]
        node_id: u64,
        #[serde(rename = "spanId")]
        span_id: u64,
    },
    CreateAnnotation {
        #[serde(rename = "annotationId")]
        annotation_id: u64,
        kind: String,
        payload: String,
    },
    AttachAnnotationToNode {
        #[serde(rename = "annotationId")]
        annotation_id: u64,
        #[serde(rename = "nodeId")]
        node_id: u64,
    },
    AttachAnnotationToSpan {
        #[serde(rename = "annotationId")]
        annotation_id: u64,
        #[serde(rename = "spanId")]
        span_id: u64,
    },
    DeleteAnnotation {
        #[serde(rename = "annotationId")]
        annotation_id: u64,
    },
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AssertionResponse {
    pub trace_id: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn deserialize_set_span_text() {
        let json = r#"{"type":"SetSpanText","spanId":3,"text":"hi"}"#;
        let req: AssertionRequest = serde_json::from_str(json).unwrap();
        match req {
            AssertionRequest::SetSpanText { span_id, text } => {
                assert_eq!(span_id, 3);
                assert_eq!(text, "hi");
            }
            other => panic!("expected SetSpanText, got {:?}", other),
        }
    }

    #[test]
    fn deserialize_create_node() {
        let json = r#"{"type":"CreateNode","nodeId":1,"kind":"paragraph"}"#;
        let req: AssertionRequest = serde_json::from_str(json).unwrap();
        match req {
            AssertionRequest::CreateNode { node_id, kind } => {
                assert_eq!(node_id, 1);
                assert_eq!(kind, "paragraph");
            }
            other => panic!("expected CreateNode, got {:?}", other),
        }
    }
}
