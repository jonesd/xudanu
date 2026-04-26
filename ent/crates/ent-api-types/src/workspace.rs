use serde::{Deserialize, Serialize};

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct WorkspaceListItem {
    pub workspace_id: String,
    pub name: String,
}

#[derive(Deserialize)]
pub struct CreateWorkspaceRequest {
    pub name: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CreateWorkspaceResponse {
    pub workspace_id: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct BranchItem {
    pub branch_id: String,
    pub name: String,
    pub head_trace_id: String,
}
