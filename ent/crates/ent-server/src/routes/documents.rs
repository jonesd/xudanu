use axum::extract::{Path, Query, State};
use axum::http::StatusCode;
use axum::Json;
use ent_api_types::document::DocumentResponse;
use ent_api_types::errors::{ErrorBody, ErrorResponse};
use serde::Deserialize;

use crate::state::SharedState;

#[derive(Deserialize)]
#[allow(non_snake_case)]
pub struct DocumentQuery {
    pub traceId: String,
}

pub async fn get_document(
    State(state): State<SharedState>,
    Path(workspace_id): Path<String>,
    Query(query): Query<DocumentQuery>,
) -> Result<Json<DocumentResponse>, (StatusCode, Json<ErrorResponse>)> {
    let trace_pos = ent_core::ent::id_codec::decode_trace(&query.traceId).ok_or_else(|| {
        (
            StatusCode::BAD_REQUEST,
            Json(ErrorResponse {
                error: ErrorBody {
                    code: "INVALID_TRACE_ID",
                    message: format!("cannot decode trace id: '{}'", query.traceId),
                },
            }),
        )
    })?;

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

    let view = ws.dagwood.trace_view(trace_pos);
    let doc =
        ent_core::ent::content::materialize_document(&ws.store, &view, ws.doc_id);
    let response =
        crate::convert::convert_document(&workspace_id, &query.traceId, &doc);

    Ok(Json(response))
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
        let bytes = axum::body::to_bytes(response.into_body(), usize::MAX)
            .await
            .unwrap();
        let json: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        json["workspaceId"].as_str().unwrap().to_string()
    }

    async fn get_branch_trace_id(
        app: &mut axum::Router,
        ws_id: &str,
        branch: &str,
    ) -> String {
        let response = app
            .oneshot(
                Request::builder()
                    .uri(format!("/api/workspaces/{ws_id}/branches"))
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        let bytes = axum::body::to_bytes(response.into_body(), usize::MAX)
            .await
            .unwrap();
        let json: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        json.as_array()
            .unwrap()
            .iter()
            .find(|b| b["branchId"] == branch)
            .unwrap()["headTraceId"]
            .as_str()
            .unwrap()
            .to_string()
    }

    #[tokio::test]
    async fn get_document_returns_seeded_content() {
        let mut app = test_app();
        let ws_id = create_workspace(&mut app, "DocTest").await;
        let trace_id = get_branch_trace_id(&mut app, &ws_id, "main").await;

        let response = app
            .oneshot(
                Request::builder()
                    .uri(format!(
                        "/api/workspaces/{ws_id}/document?traceId={trace_id}"
                    ))
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

        assert_eq!(json["workspaceId"], ws_id);
        assert_eq!(json["traceId"], trace_id);
        let doc = &json["document"];
        assert_eq!(doc["kind"], "document");
        assert_eq!(doc["children"].as_array().unwrap().len(), 1);

        let para = &doc["children"][0];
        assert_eq!(para["kind"], "paragraph");
        assert_eq!(para["spans"].as_array().unwrap().len(), 1);

        let span = &para["spans"][0];
        assert_eq!(span["text"]["type"], "single");
        assert_eq!(span["text"]["value"], "Hello world");
    }

    #[tokio::test]
    async fn get_document_workspace_not_found() {
        let app = test_app();
        let response = app
            .oneshot(
                Request::builder()
                    .uri("/api/workspaces/nope/document?traceId=t-1-1")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(response.status(), StatusCode::NOT_FOUND);
    }

    #[tokio::test]
    async fn get_document_invalid_traceId() {
        let mut app = test_app();
        let ws_id = create_workspace(&mut app, "BadTrace").await;

        let response = app
            .oneshot(
                Request::builder()
                    .uri(format!(
                        "/api/workspaces/{ws_id}/document?traceId=garbage"
                    ))
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(response.status(), StatusCode::BAD_REQUEST);
    }

    #[tokio::test]
    async fn get_document_root_node_has_correct_ids() {
        let mut app = test_app();
        let ws_id = create_workspace(&mut app, "Ids").await;
        let trace_id = get_branch_trace_id(&mut app, &ws_id, "main").await;

        let response = app
            .oneshot(
                Request::builder()
                    .uri(format!(
                        "/api/workspaces/{ws_id}/document?traceId={trace_id}"
                    ))
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

        let doc = &json["document"];
        assert!(doc["nodeId"].as_str().unwrap().starts_with("node-"));
        assert!(doc["children"][0]["spans"][0]["spanId"]
            .as_str()
            .unwrap()
            .starts_with("span-"));
    }
}
