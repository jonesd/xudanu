use serde::Serialize;

#[derive(Serialize)]
#[serde(tag = "type")]
pub enum ApiText {
    #[serde(rename = "single")]
    Single { value: String },
    #[serde(rename = "alternatives")]
    Alternatives { values: Vec<String> },
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ApiAnnotation {
    pub annotation_id: String,
    pub kind: String,
    pub payload: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ApiSpan {
    pub span_id: String,
    pub text: ApiText,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub annotations: Vec<ApiAnnotation>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ApiNode {
    pub node_id: String,
    pub kind: String,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub children: Vec<ApiNode>,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub spans: Vec<ApiSpan>,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub annotations: Vec<ApiAnnotation>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DocumentResponse {
    pub workspace_id: String,
    pub trace_id: String,
    pub document: Option<ApiNode>,
}
