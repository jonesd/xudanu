use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::Json;
use ent_api_types::errors::{ErrorBody, ErrorResponse};
use ent_api_types::workspace::{
    CreateWorkspaceRequest, CreateWorkspaceResponse, WorkspaceListItem,
};

use crate::state::SharedState;

pub async fn list(
    State(state): State<SharedState>,
) -> Json<Vec<WorkspaceListItem>> {
    let workspaces = state.read().await;
    let items: Vec<WorkspaceListItem> = workspaces
        .values()
        .map(|ws| WorkspaceListItem {
            workspace_id: ws.id.clone(),
            name: ws.name.clone(),
        })
        .collect();
    Json(items)
}

pub async fn create(
    State(state): State<SharedState>,
    Json(req): Json<CreateWorkspaceRequest>,
) -> Result<(StatusCode, Json<CreateWorkspaceResponse>), Json<ErrorResponse>> {
    let ws = crate::state::WorkspaceState::new(&req.name);
    let id = ws.id.clone();
    let resp = CreateWorkspaceResponse {
        workspace_id: id.clone(),
    };

    state.write().await.insert(id, ws);

    Ok((StatusCode::CREATED, Json(resp)))
}

pub async fn get_branches(
    State(state): State<SharedState>,
    Path(workspace_id): Path<String>,
) -> Result<Json<Vec<ent_api_types::workspace::BranchItem>>, (StatusCode, Json<ErrorResponse>)> {
    let workspaces = state.read().await;
    let ws = workspaces.get(&workspace_id).ok_or_else(|| {
        (
            StatusCode::NOT_FOUND,
            Json(ErrorResponse {
                error: ErrorBody {
                    code: "WORKSPACE_NOT_FOUND",
                    message: format!("workspace '{}' not found", workspace_id),
                },
            }),
        )
    })?;

    let branches: Vec<ent_api_types::workspace::BranchItem> = ws
        .branches
        .iter()
        .map(|(name, info)| ent_api_types::workspace::BranchItem {
            branch_id: name.clone(),
            name: info.name.clone(),
            head_trace_id: ent_core::ent::id_codec::encode_trace(info.head),
        })
        .collect();

    Ok(Json(branches))
}

#[cfg(test)]
mod tests {
    use axum::body::Body;
    use axum::http::{Request, StatusCode};
    use std::collections::HashMap;
    use std::sync::Arc;
    use tokio::sync::RwLock;
    use tower::ServiceExt;

    use crate::app::app as make_app;
    use crate::state::SharedState;

    fn test_app() -> axum::Router {
        let state: SharedState = Arc::new(RwLock::new(HashMap::new()));
        make_app(state)
    }

    async fn create_workspace(app: &mut axum::Router, name: &str) -> String {
        let body = serde_json::json!({ "name": name }).to_string();
        let response = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/api/workspaces")
                    .header("content-type", "application/json")
                    .body(Body::from(body))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(response.status(), StatusCode::CREATED);
        let bytes = axum::body::to_bytes(response.into_body(), usize::MAX)
            .await
            .unwrap();
        let json: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        json["workspaceId"].as_str().unwrap().to_string()
    }

    #[tokio::test]
    async fn list_workspaces_empty() {
        let app = test_app();
        let response = app
            .oneshot(
                Request::builder()
                    .uri("/api/workspaces")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(response.status(), StatusCode::OK);
        let bytes = axum::body::to_bytes(response.into_body(), usize::MAX)
            .await
            .unwrap();
        let json: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(json.as_array().unwrap().len(), 0);
    }

    #[tokio::test]
    async fn create_and_list_workspace() {
        let mut app = test_app();
        let id = create_workspace(&mut app, "Demo").await;

        let response = app
            .oneshot(
                Request::builder()
                    .uri("/api/workspaces")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        let bytes = axum::body::to_bytes(response.into_body(), usize::MAX)
            .await
            .unwrap();
        let json: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        let list = json.as_array().unwrap();
        assert_eq!(list.len(), 1);
        assert_eq!(list[0]["workspaceId"], id);
        assert_eq!(list[0]["name"], "Demo");
    }

    #[tokio::test]
    async fn get_branches_returns_main() {
        let mut app = test_app();
        let id = create_workspace(&mut app, "Test").await;

        let response = app
            .oneshot(
                Request::builder()
                    .uri(format!("/api/workspaces/{id}/branches"))
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(response.status(), StatusCode::OK);
        let bytes = axum::body::to_bytes(response.into_body(), usize::MAX)
            .await
            .unwrap();
        let json: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        let branches = json.as_array().unwrap();
        assert_eq!(branches.len(), 1);
        assert_eq!(branches[0]["branchId"], "main");
        assert_eq!(branches[0]["name"], "main");
        assert!(branches[0]["headTraceId"].as_str().unwrap().starts_with("t-"));
    }

    #[tokio::test]
    async fn get_branches_workspace_not_found() {
        let app = test_app();
        let response = app
            .oneshot(
                Request::builder()
                    .uri("/api/workspaces/nonexistent/branches")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(response.status(), StatusCode::NOT_FOUND);
    }
}
