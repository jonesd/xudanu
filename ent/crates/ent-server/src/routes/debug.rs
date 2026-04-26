use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::Json;
use ent_api_types::debug::{DebugAssertion, DebugBranch, DebugResponse};
use ent_api_types::errors::{ErrorBody, ErrorResponse};

use crate::state::SharedState;

pub async fn get_debug(
    State(state): State<SharedState>,
    Path(workspace_id): Path<String>,
) -> Result<Json<DebugResponse>, (StatusCode, Json<ErrorResponse>)> {
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

    let assertions: Vec<DebugAssertion> = ws
        .store
        .all_assertions()
        .iter()
        .map(|a| DebugAssertion {
            id: a.id.as_u64(),
            trace_id: ent_core::ent::id_codec::encode_trace(a.position),
            branch_id: a.position.branch().as_u64(),
            position: a.position.position(),
            payload_type: a.payload.type_name().to_string(),
            payload_summary: a.payload.summary(),
        })
        .collect();

    let branches: Vec<DebugBranch> = ws
        .dagwood
        .debug_branches()
        .into_iter()
        .map(|b| DebugBranch {
            branch_id: b.branch_id,
            last_position: b.last_position,
            parent_traces: b.parents.map(|ps| {
                ps.iter().map(|p| ent_core::ent::id_codec::encode_trace(*p)).collect()
            }),
        })
        .collect();

    Ok(Json(DebugResponse {
        workspace_id: workspace_id.clone(),
        assertions,
        branches,
    }))
}
