use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::Json;
use ent_api_types::assertions::{AssertionRequest, AssertionResponse};
use ent_api_types::errors::{ErrorBody, ErrorResponse};

use crate::state::SharedState;

pub async fn post_assertion(
    State(state): State<SharedState>,
    Path(workspace_id): Path<String>,
    Json(req): Json<AssertionRequest>,
) -> Result<(StatusCode, Json<AssertionResponse>), (StatusCode, Json<ErrorResponse>)> {
    let mut workspaces = state.write().await;
    let ws = workspaces.get_mut(&workspace_id).ok_or_else(|| {
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

    let branch_info = ws.branches.get("main").expect("main branch always exists");
    let branch_id = branch_info.head.branch();
    let new_pos = ws.dagwood.extend_branch(branch_id);
    let payload = crate::convert_assertion::convert_assertion(req);
    ws.store.add(new_pos, payload);

    let branch_name = "main".to_string();
    if let Some(branch) = ws.branches.get_mut(&branch_name) {
        branch.head = new_pos;
    }

    let trace_id = ent_core::ent::id_codec::encode_trace(new_pos);

    Ok((
        StatusCode::OK,
        Json(AssertionResponse { trace_id }),
    ))
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
        let resp = app
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
        let bytes = axum::body::to_bytes(resp.into_body(), usize::MAX)
            .await
            .unwrap();
        let json: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        json["workspaceId"].as_str().unwrap().to_string()
    }

    async fn get_main_trace_id(app: &mut axum::Router, ws_id: &str) -> String {
        let resp = app
            .oneshot(
                Request::builder()
                    .uri(format!("/api/workspaces/{ws_id}/branches"))
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        let bytes = axum::body::to_bytes(resp.into_body(), usize::MAX)
            .await
            .unwrap();
        let json: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        json.as_array()
            .unwrap()
            .iter()
            .find(|b| b["branchId"] == "main")
            .unwrap()["headTraceId"]
            .as_str()
            .unwrap()
            .to_string()
    }

    #[tokio::test]
    async fn set_span_text_updates_document() {
        let mut app = test_app();
        let ws_id = create_workspace(&mut app, "EditTest").await;
        let trace_before = get_main_trace_id(&mut app, &ws_id).await;

        let body = serde_json::json!({
            "type": "SetSpanText",
            "spanId": 3,
            "text": "Updated text"
        })
        .to_string();
        let resp = app
            .clone()
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri(format!("/api/workspaces/{ws_id}/assertions"))
                    .header("content-type", "application/json")
                    .body(Body::from(body))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(resp.status(), StatusCode::OK);
        let bytes = axum::body::to_bytes(resp.into_body(), usize::MAX)
            .await
            .unwrap();
        let json: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        let new_trace = json["traceId"].as_str().unwrap();
        assert_ne!(new_trace, trace_before);

        let trace_after = get_main_trace_id(&mut app, &ws_id).await;
        assert_eq!(trace_after, new_trace);

        let resp = app
            .oneshot(
                Request::builder()
                    .uri(format!(
                        "/api/workspaces/{ws_id}/document?traceId={trace_after}"
                    ))
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        let bytes = axum::body::to_bytes(resp.into_body(), usize::MAX)
            .await
            .unwrap();
        let doc: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        let span_text = doc["document"]["children"][0]["spans"][0]["text"].clone();
        assert_eq!(span_text["type"], "single");
        assert_eq!(span_text["value"], "Updated text");
    }

    #[tokio::test]
    async fn assertion_on_missing_workspace_returns_404() {
        let app = test_app();
        let body = serde_json::json!({
            "type": "SetSpanText",
            "spanId": 1,
            "text": "nope"
        })
        .to_string();
        let resp = app
            .oneshot(
                Request::builder()
                    .method("POST")
                    .uri("/api/workspaces/nonexistent/assertions")
                    .header("content-type", "application/json")
                    .body(Body::from(body))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(resp.status(), StatusCode::NOT_FOUND);
    }

    #[tokio::test]
    async fn same_branch_overwrite_keeps_single_value() {
        let mut app = test_app();
        let ws_id = create_workspace(&mut app, "Overwrite").await;

        let body1 = serde_json::json!({
            "type": "SetSpanText",
            "spanId": 3,
            "text": "first"
        })
        .to_string();
        {
            let app = app.clone();
            app.oneshot(
                Request::builder()
                    .method("POST")
                    .uri(format!("/api/workspaces/{ws_id}/assertions"))
                    .header("content-type", "application/json")
                    .body(Body::from(body1))
                    .unwrap(),
            )
            .await
            .unwrap();
        }

        let body2 = serde_json::json!({
            "type": "SetSpanText",
            "spanId": 3,
            "text": "second"
        })
        .to_string();
        {
            let app = app.clone();
            app.oneshot(
                Request::builder()
                    .method("POST")
                    .uri(format!("/api/workspaces/{ws_id}/assertions"))
                    .header("content-type", "application/json")
                    .body(Body::from(body2))
                    .unwrap(),
            )
            .await
            .unwrap();
        }

        let trace = get_main_trace_id(&mut app, &ws_id).await;
        let resp = app
            .oneshot(
                Request::builder()
                    .uri(format!(
                        "/api/workspaces/{ws_id}/document?traceId={trace}"
                    ))
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        let bytes = axum::body::to_bytes(resp.into_body(), usize::MAX)
            .await
            .unwrap();
        let doc: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
        let span_text = doc["document"]["children"][0]["spans"][0]["text"].clone();
        assert_eq!(span_text["type"], "single");
        assert_eq!(span_text["value"], "second");
    }
}
