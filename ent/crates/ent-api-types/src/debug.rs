use serde::Serialize;

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DebugAssertion {
    pub id: u64,
    pub trace_id: String,
    pub branch_id: u64,
    pub position: u32,
    pub payload_type: String,
    pub payload_summary: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DebugBranch {
    pub branch_id: u64,
    pub last_position: u32,
    pub parent_traces: Option<Vec<String>>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DebugResponse {
    pub workspace_id: String,
    pub assertions: Vec<DebugAssertion>,
    pub branches: Vec<DebugBranch>,
}
