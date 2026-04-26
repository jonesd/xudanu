use axum::routing::{get, post};
use axum::Router;

use crate::routes;
use crate::state::SharedState;

pub fn app(state: SharedState) -> Router {
    Router::new()
        .route("/health", get(routes::health::health))
        .route("/api/workspaces", get(routes::workspaces::list))
        .route("/api/workspaces", post(routes::workspaces::create))
        .route(
            "/api/workspaces/{workspace_id}/branches",
            get(routes::workspaces::get_branches),
        )
        .route(
            "/api/workspaces/{workspace_id}/document",
            get(routes::documents::get_document),
        )
        .route(
            "/api/workspaces/{workspace_id}/assertions",
            post(routes::assertions::post_assertion),
        )
        .route(
            "/api/workspaces/{workspace_id}/debug",
            get(routes::debug::get_debug),
        )
        .with_state(state)
}
