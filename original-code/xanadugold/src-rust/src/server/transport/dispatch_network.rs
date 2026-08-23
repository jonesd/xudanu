//! FR-41/#141: async dispatch paths for operations that perform
//! outbound network IO. The sync `dispatch` runs inside the server
//! write lock; these ops previously held that lock across HTTP
//! fetches to peers — a reachable-but-unresponsive peer froze the
//! whole server (observed live, twice).
//!
//! Pattern per op: SNAPSHOT (under the lock, cheap) → FETCH
//! (spawn_blocking, no lock) → APPLY (re-acquire the lock, apply the
//! fetched state). Re-validates state at apply time; a racing edit
//! between snapshot and apply surfaces as a normal conflict error,
//! not corruption.

use super::protocol::*;
use super::shared::SharedState;
use crate::server::ServerError;

/// Ops routed here. Everything else uses the sync path unchanged.
pub fn is_network_op(req: &WireRequest) -> bool {
    matches!(
        req,
        WireRequest::FederatedSearch { .. }
            | WireRequest::TransclusionPlaceCrossServer { .. }
            | WireRequest::CrossServerSpanRefresh { .. }
    )
    // Cross-server backlink notify in LinkCreate is handled inline
    // below via the same snapshot/fetch/apply split.
}

pub async fn dispatch_network(
    state: &SharedState,
    session_id: crate::server::SessionId,
    request: WireRequest,
) -> Result<ResponseValue, ServerError> {
    match request {
        WireRequest::FederatedSearch { query } => {
            // SNAPSHOT: rate-limit check + trusted peer list.
            let gate_ok = state
                .rate_limiter
                .check_federated_search(session_id.as_u64());
            if !gate_ok {
                tracing::warn!(
                    target: "xudanu::security",
                    session = session_id.as_u64(),
                    event = "SECURITY:federated_search_rate_limited",
                    "federated search rate limit exceeded"
                );
                return Err(ServerError::Unauthorized(
                    "too many federated searches, wait a moment".into(),
                ));
            }
            let peers: Vec<(u64, String, Option<u16>, String)> = state
                .server
                .with_server_ref(|srv| srv.snapshot_trusted_peers_for_search());
            // FETCH: no lock held.
            let query_for_task = query.clone();
            let fetched = tokio::task::spawn_blocking(move || {
                crate::server::server::federated_fetch_peers(peers, &query_for_task)
            })
            .await
            .map_err(|e| ServerError::Internal(format!("fan-out task failed: {}", e)))?;
            // APPLY: merge local + fetched under the lock.
            let results = state
                .server
                .with_server(|srv| srv.federated_search_merge(&query, fetched));
            Ok(ResponseValue::FederatedSearchResult { results })
        }

        WireRequest::TransclusionPlaceCrossServer {
            dest_work,
            cursor,
            tumbler,
            span_start,
            span_end,
            title_hint,
        } => {
            // SNAPSHOT: auth, dest exists, origin directory entry.
            let plan = state.server.with_server(|srv| {
                srv.snapshot_cross_server_span_fetch(
                    session_id, dest_work, &tumbler, span_start, span_end,
                )
            })?;
            // FETCH: span from origin (hash-verified in fetch).
            let fetched = tokio::task::spawn_blocking(move || {
                crate::server::server::cross_server_fetch_span(plan)
            })
            .await
            .map_err(|e| ServerError::Internal(format!("span fetch task failed: {}", e)))??;
            // APPLY: freeze source + place virtual under the lock.
            let payload = state.server.with_server(|srv| {
                srv.apply_cross_server_span_fetch(
                    session_id, dest_work, cursor, fetched, title_hint,
                )
            })?;
            Ok(ResponseValue::CrossServerTransclusion(payload))
        }

        WireRequest::CrossServerSpanRefresh {
            source_work,
            update,
        } => {
            // SNAPSHOT: read the provenance bond + origin entry.
            let plan = state
                .server
                .with_server(|srv| srv.snapshot_span_refresh(source_work))?;
            // FETCH: current span from origin (hash-verified inside).
            let fetched = tokio::task::spawn_blocking(move || {
                crate::server::server::cross_server_fetch_span(plan)
            })
            .await
            .map_err(|e| ServerError::Internal(format!("refresh fetch task failed: {}", e)))??;
            // APPLY: compare + optional update under the lock.
            let payload = state.server.with_server(|srv| {
                srv.apply_span_refresh(session_id, source_work, fetched, update)
            })?;
            Ok(ResponseValue::CrossServerSpanRefresh(payload))
        }

        other => {
            // Not a network op after all — fall back to sync dispatch.
            super::dispatch::dispatch(state, session_id, other)
        }
    }
}
