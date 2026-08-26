//! Transport-layer coverage sweep (FR-45 follow-up): line-coverage for
//! protocol.rs / codec.rs / dispatch.rs — the wire trio that carries
//! every client↔server interaction.
//!
//! Techniques:
//! - Op-code roundtrips cover both dense match tables (number→variant
//!   and variant→number) in one test each.
//! - JSON-name parsing covers the serde (snake_case) path used by the
//!   text protocol.
//! - An op-fire sweep sends EVERY op with `{}` payload through a live
//!   authenticated connection: no-arg ops dispatch; arg-taking ops
//!   fail inside their codec arm (missing field) — either way the arm
//!   executes instead of sitting dark.
//! - Minimal-payload fire for the high-value read ops drives their
//!   dispatch arms end-to-end.

#![cfg(feature = "server")]

use futures_util::{SinkExt, StreamExt};
use std::net::SocketAddr;
use tokio_tungstenite::tungstenite::Message;
use xudanu::server::transport::{build_router, AppState, OperationCode, PROTOCOL_VERSION};
use xudanu::server::transport::audit::{SecurityConfig, SecurityMonitor, TracingAuditLog};
use xudanu::server::Server;
use std::sync::Arc;

const ADMIN_PASSWORD: &[u8] = b"admin12345";

fn password_credential(pw: &[u8]) -> serde_json::Value {
    serde_json::json!({"password": pw.iter().map(|&b| serde_json::Value::from(b)).collect::<Vec<_>>()})
}

struct TestServer {
    addr: SocketAddr,
}

impl TestServer {
    async fn start() -> Self {
        let mut server = Server::new();
        let admin_club = server.admin_club_id();
        let setup_sid = server.connect();
        server.login_public(setup_sid).unwrap();
        server.grant_admin_authority(setup_sid).unwrap();
        server
            .club_set_password(setup_sid, admin_club, ADMIN_PASSWORD)
            .unwrap();
        server.disconnect(setup_sid).unwrap();
        // Sweep-friendly limits: the op sweep deliberately fires ~300
        // ops whose domain errors count as permission denials — the
        // production 30/min escalation would kill the socket mid-sweep.
        let cfg = SecurityConfig {
            max_permission_denials_per_minute: 100_000,
            max_auth_failures_per_minute: 100_000,
            max_protocol_violations_per_minute: 100_000,
            max_requests_per_second: 100_000,
            ..SecurityConfig::default()
        };
        let monitor = SecurityMonitor::new(Arc::new(TracingAuditLog)).with_config(cfg);
        let state = AppState::with_security(server, monitor).shared();
        let app = build_router(state).into_make_service_with_connect_info::<std::net::SocketAddr>();
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();
        tokio::spawn(async move {
            axum::serve(listener, app).await.unwrap();
        });
        TestServer { addr }
    }
}

type WsStream =
    tokio_tungstenite::WebSocketStream<tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>>;
type SplitSender = futures_util::stream::SplitSink<WsStream, Message>;
type SplitReceiver = futures_util::stream::SplitStream<WsStream>;

async fn admin_ws(addr: &SocketAddr) -> (SplitSender, SplitReceiver) {
    let url = format!("ws://{}/xudanu?format=json&version={}", addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    let msg = r.next().await.unwrap().unwrap();
    assert!(matches!(&msg, Message::Text(t) if serde_json::from_str::<serde_json::Value>(t).unwrap()["type"] == "handshake"));

    let mut next_id = 1u16;
    macro_rules! req {
        ($op:expr, $payload:expr) => {{
            let id = next_id;
            next_id += 1;
            let mut frame = serde_json::json!({"v": PROTOCOL_VERSION, "type": "request", "id": id, "op": $op});
            if let Some(p) = $payload {
                frame["payload"] = p;
            }
            s.send(Message::Text(frame.to_string().into())).await.unwrap();
            let resp = tokio::time::timeout(std::time::Duration::from_secs(10), r.next()).await;
            match resp {
                Ok(Some(Ok(Message::Text(t)))) => {
                    let v: serde_json::Value = serde_json::from_str(&t).unwrap();
                    v
                }
                Ok(Some(Ok(Message::Binary(b)))) => serde_json::from_slice(&b).unwrap(),
                other => panic!("op {} got {:?} (want response or error frame)", $op, other.map(|o| o.map(|m| m.is_ok()))),
            }
        }};
    }

    // session_connect
    let v = req!("session_connect", None::<serde_json::Value>);
    assert_eq!(v["type"], "response", "connect: {:?}", v);
    let club = req!("club_id_by_name", Some(serde_json::json!({"name": "admin"})));
    let club_id = club["value"]["value"].as_u64().unwrap();
    let v = req!("session_login", Some(serde_json::json!({"club_id": club_id})));
    assert_eq!(v["type"], "response", "login: {:?}", v);
    let v = req!("session_authenticate", Some(serde_json::json!({"credential": password_credential(ADMIN_PASSWORD)})));
    assert_eq!(v["type"], "response", "auth: {:?}", v);
    (s, r)
}

// ─── Op-code roundtrips (protocol.rs match tables) ─────────────────

#[test]
fn op_code_u16_roundtrip_every_defined_code() {
    // number → variant covers from_u16's arms for every defined code.
    let mut parsed = 0;
    for code in 1u16..0x0FFF {
        if let Some(op) = OperationCode::from_u16(code) {
            // variant → number covers to_u16's arm for the same op.
            assert_eq!(op.to_u16(), code, "roundtrip failed for {:#06x}", code);
            parsed += 1;
        }
    }
    // Sanity: the table is substantial (the wire carries ~290 ops).
    assert!(parsed > 200, "expected >200 op codes, parsed {}", parsed);
    // Undefined hole must not parse.
    assert!(OperationCode::from_u16(0).is_none());
}

#[test]
fn op_code_serde_name_roundtrip() {
    // The JSON text protocol parses op names via serde snake_case.
    let names = [
        "session_connect",
        "work_create",
        "work_list",
        "work_admin_delete",
        "admin_clubs_list",
        "admin_audit_tail",
        "cross_server_resolve",
        "network_set_enabled",
        "external_links_set_enabled",
        "admin_edit_policy_set",
    ];
    for n in names {
        let v: OperationCode =
            serde_json::from_value(serde_json::Value::String(n.to_string())).unwrap();
        let back = serde_json::to_value(&v).unwrap();
        assert_eq!(back, serde_json::json!(n));
    }
    let bad: Result<OperationCode, _> =
        serde_json::from_value(serde_json::Value::String("no_such_op".into()));
    assert!(bad.is_err());
}

// ─── Codec + dispatch sweep: fire every op ──────────────────────────

/// Ops that must NOT be blind-fired (destructive or hang-prone:
/// disconnects the caller, shuts down the server, spawns waits, or
/// blocks on external network).
const SKIP: &[&str] = &[
    "session_disconnect",   // kills our own sweep connection
    "admin_shutdown",       // bricks the test server
    "work_grab_waiters",    // registered wait paths need live grabbers
    "session_login",        // re-login mid-sweep scrambles auth state
    "session_login_by_name",
    "session_authenticate",
    "session_login_public", // strips admin authority mid-sweep
    "membership_leave",     // mutates federation state mid-sweep
];

#[tokio::test]
async fn wire_sweep_every_op_executes() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = admin_ws(&srv.addr).await;

    // Fire every op with an empty-object payload. No-arg ops dispatch
    // (response or domain error); arg-taking ops fail inside their codec
    // arm — both execute code that would otherwise sit dark.
    let all = op_name_list();
    let mut dispatched = 0usize;
    let mut decode_rejected = 0usize;
    for op in &all {
        if SKIP.contains(&op.as_str()) {
            continue;
        }
        let frame = serde_json::json!({
            "v": PROTOCOL_VERSION,
            "type": "request",
            "id": 1,
            "op": op,
            "payload": {},
        });
        s.send(Message::Text(frame.to_string().into())).await.unwrap();
        tokio::time::sleep(std::time::Duration::from_millis(30)).await;
        let resp = tokio::time::timeout(std::time::Duration::from_secs(10), r.next()).await;
        match resp {
            Ok(Some(Ok(Message::Text(t)))) => {
                let v: serde_json::Value = serde_json::from_str(&t).unwrap();
                if v["type"] == "response" {
                    dispatched += 1;
                } else if v["type"] == "error" {
                    if v["code"] == "protocol_error" {
                        decode_rejected += 1;
                    } else {
                        // domain error — the dispatch arm ran.
                        dispatched += 1;
                    }
                } else {
                    panic!("op {} produced frame type {}", op, v["type"]);
                }
            }
            other => panic!("op {} timed out/errored: {:?}", op, other.is_ok()),
        }
    }
    eprintln!("sweep: {} dispatched, {} codec-rejected", dispatched, decode_rejected);
    assert!(dispatched > 25, "expected the no-payload ops to dispatch, got {}", dispatched);
}

/// Minimal-payload drive for high-value read ops whose dispatch arms
/// need real arguments (the {} sweep only reaches their codec error).
#[tokio::test]
async fn wire_sweep_read_ops_with_minimal_payloads() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = admin_ws(&srv.addr).await;

    // Seed a work so id-bearing queries have a target.
    let frame = serde_json::json!({
        "v": PROTOCOL_VERSION, "type": "request", "id": 1, "op": "work_create",
        "payload": {"edition": {"text": "sweep target doc"}},
    });
    s.send(Message::Text(frame.to_string().into())).await.unwrap();
    let resp = tokio::time::timeout(std::time::Duration::from_secs(10), r.next()).await.unwrap().unwrap().unwrap();
    let v: serde_json::Value = match &resp {
        Message::Text(t) => serde_json::from_str(t).unwrap(),
        Message::Binary(b) => serde_json::from_slice(b).unwrap(),
        _ => panic!("bad frame"),
    };
    let work_id = v["value"]["value"].as_u64().expect("work created");

    // (op, payload) pairs — every one dispatches a real arm.
    let cases: Vec<(&str, serde_json::Value)> = vec![
        ("work_get_edition", serde_json::json!({"work_id": work_id})),
        ("work_is_grabbed", serde_json::json!({"work_id": work_id})),
        ("work_grabber", serde_json::json!({"work_id": work_id})),
        ("work_can_read", serde_json::json!({"work_id": work_id})),
        ("work_can_revise", serde_json::json!({"work_id": work_id})),
        ("work_revisions_list", serde_json::json!({"work_id": work_id})),
        ("work_text_at_revision", serde_json::json!({"work_id": work_id, "revision": 0})),
        ("work_blob_list", serde_json::json!({"work_id": work_id})),
        ("work_get_read_club", serde_json::json!({"work_id": work_id})),
        ("work_get_edit_club", serde_json::json!({"work_id": work_id})),
        ("work_is_source", serde_json::json!({"work_id": work_id})),
        ("work_kind_get", serde_json::json!({"work_id": work_id})),
        ("work_license_get", serde_json::json!({"work_id": work_id})),
        ("work_version_timeline", serde_json::json!({"work_id": work_id})),
        ("link_list_for_work", serde_json::json!({"work_id": work_id})),
        ("work_backlinks", serde_json::json!({"work_id": work_id})),
        ("annotation_list", serde_json::json!({"work_id": work_id})),
        ("work_outline", serde_json::json!({"work_id": work_id})),
        ("work_list", serde_json::json!({})),
        ("work_list_by_kind", serde_json::json!({"kind": "document"})),
        ("work_list_archived", serde_json::json!({})),
        ("club_names", serde_json::json!({})),
        ("club_who_am_i", serde_json::json!({})),
        ("trail_list", serde_json::json!({})),
        ("trail_list_categories", serde_json::json!({})),
        ("label_get_positions", serde_json::json!({})),
        ("source_pattern_list", serde_json::json!({})),
        ("historical_author_list", serde_json::json!({})),
        ("server_stats", serde_json::json!({})),
        ("blob_stats", serde_json::json!({})),
        ("federation_info", serde_json::json!({})),
        ("federation_peers", serde_json::json!({})),
        ("governance_status", serde_json::json!({})),
        ("governance_log", serde_json::json!({})),
        ("membership_list", serde_json::json!({})),
        ("admin_active_sessions", serde_json::json!({})),
        ("admin_grants", serde_json::json!({})),
        ("admin_is_accepting_connections", serde_json::json!({})),
        ("admin_server_health", serde_json::json!({})),
        ("admin_recorder_list", serde_json::json!({})),
        ("admin_clubs_list", serde_json::json!({})),
        ("admin_audit_tail", serde_json::json!({})),
        ("server_directory_list", serde_json::json!({})),
        ("attribution_log_status", serde_json::json!({})),
        ("connection_pins_get", serde_json::json!({})),
        ("crypto_get_public_key", serde_json::json!({})),
        ("crypto_key_history", serde_json::json!({})),
        ("work_graph", serde_json::json!({})),
        ("work_search", serde_json::json!({"query": "sweep"})),
        ("global_text_search", serde_json::json!({"query": "sweep"})),
    ];

    let mut id = 10u16;
    let mut ok_or_domain_err = 0usize;
    for (op, payload) in &cases {
        id += 1;
        let frame = serde_json::json!({
            "v": PROTOCOL_VERSION, "type": "request", "id": id, "op": op, "payload": payload,
        });
        s.send(Message::Text(frame.to_string().into())).await.unwrap();
        tokio::time::sleep(std::time::Duration::from_millis(30)).await;
        let resp = tokio::time::timeout(std::time::Duration::from_secs(10), r.next())
            .await
            .unwrap_or_else(|_| panic!("op {} timed out", op))
            .unwrap()
            .unwrap();
        let v: serde_json::Value = match &resp {
            Message::Text(t) => serde_json::from_str(t).unwrap(),
            Message::Binary(b) => serde_json::from_slice(b).unwrap(),
            _ => panic!("bad frame for {}", op),
        };
        assert!(
            v["type"] == "response" || v["type"] == "error",
            "op {} -> {:?}",
            op,
            v
        );
        if v["type"] != "error" || v["code"] != "protocol_error" {
            ok_or_domain_err += 1;
        } else {
            eprintln!("NOT-DISPATCHED {}: {}", op, v["message"].as_str().unwrap_or("?"));
        }
    }
    assert!(
        ok_or_domain_err > cases.len() - 8,
        "most cases must reach dispatch ({} of {})",
        ok_or_domain_err,
        cases.len()
    );
}

/// The op-name list, kept in the test so the sweep is self-contained.
/// Generated from the OperationCode enum (snake_case).
fn op_name_list() -> Vec<String> {
    // The authoritative wire-name list, verbatim from serde's
    // unknown-variant enumeration (kept in sync by regenerating from any
    // "unknown variant" error when ops are added).
    [
        "session_connect",
        "session_disconnect",
        "session_login",
        "session_login_by_name",
        "session_authenticate",
        "session_login_public",
        "session_ticket_issue",
        "session_ticket_redeem",
        "server_get_by_id",
        "server_get_by_be_id",
        "club_create",
        "club_create_named",
        "club_get",
        "club_by_name",
        "club_id_by_name",
        "club_name_by_id",
        "club_names",
        "work_create",
        "work_get_edition",
        "work_revise",
        "work_grab",
        "work_release",
        "work_save_and_release",
        "work_force_release",
        "work_is_grabbed",
        "work_grabber",
        "work_request_grab",
        "work_cancel_grab_request",
        "work_grab_waiters",
        "work_can_read",
        "work_can_revise",
        "work_set_read_club",
        "work_set_edit_club",
        "work_set_history_club",
        "work_read_club",
        "work_edit_club",
        "work_history_club",
        "work_transclusion_chain",
        "work_revision_count",
        "work_fetch_revision",
        "work_sponsor",
        "work_unsponsor",
        "work_sponsors",
        "work_star",
        "work_set_source",
        "web_fetch_sanitize",
        "work_unstar",
        "work_is_starred",
        "connection_pin_set",
        "connection_pin_unset",
        "connection_pins_get",
        "cross_server_backlinks_get",
        "work_graph",
        "work_kind_get",
        "work_kind_set",
        "work_license_get",
        "work_license_set",
        "work_list_by_kind",
        "work_set_text",
        "work_revisions_list",
        "work_blob_list",
        "work_text_at_revision",
        "work_revision_describe",
        "work_revision_mark_notable",
        "work_revision_rollback",
        "trail_create",
        "trail_delete",
        "trail_rename",
        "trail_add_stop",
        "trail_remove_stop",
        "trail_reorder_stops",
        "trail_list",
        "trail_get",
        "work_owner",
        "work_publish",
        "work_unpublish",
        "work_irrevocably_unpublish",
        "work_archive",
        "work_unarchive",
        "work_list_archived",
        "work_is_published",
        "work_merge",
        "work_ghost",
        "work_fetch_revision_range",
        "club_set_default_read_club",
        "club_set_default_edit_club",
        "club_set_password",
        "club_clear_credential",
        "club_create_personal",
        "club_who_am_i",
        "club_add_member",
        "club_remove_member",
        "club_members",
        "club_roster",
        "edition_store",
        "edition_get",
        "admin_accept_connections",
        "admin_is_accepting_connections",
        "admin_active_sessions",
        "admin_shutdown",
        "admin_grant",
        "admin_revoke_grant",
        "admin_grants",
        "admin_server_info",
        "work_list",
        "work_list_by_owner",
        "work_revise_delta",
        "work_diff_narration",
        "work_writing_feedback",
        "work_suggest_title",
        "work_set_title",
        "work_auto_tag",
        "work_backlinks",
        "link_create",
        "link_get",
        "link_update",
        "link_delete",
        "link_list_for_work",
        "link_add_end",
        "link_remove_end",
        "link_set_types",
        "link_type_register",
        "link_type_list",
        "link_query",
        "find_excerpt_positions",
        "find_transcluders",
        "find_works_for_content",
        "find_text_transcluders",
        "find_shared_regions",
        "work_diff_regions",
        "server_stats",
        "metrics_snapshot",
        "blob_upload",
        "blob_get",
        "blob_get_preview",
        "blob_exists",
        "blob_info",
        "blob_stats",
        "overlay_apply",
        "overlay_get",
        "label_create",
        "label_get_positions",
        "edition_relabel",
        "edition_rebind",
        "can_make_identical",
        "make_range_identical",
        "identity_unify",
        "identity_resolve",
        "edition_retrieve",
        "edition_cost",
        "element_insert",
        "transclusion_place_cross_server",
        "cross_server_span_refresh",
        "element_update",
        "render_transclusions",
        "annotation_create",
        "annotation_delete",
        "annotation_attach_node",
        "annotation_attach_span",
        "annotation_get",
        "annotation_list",
        "content_shared_region",
        "content_map_shared_to",
        "content_map_shared_onto",
        "positions_of",
        "range_transcluders",
        "range_works",
        "ordered_bundles",
        "transclusion_depth",
        "version_is_before",
        "version_ancestors",
        "version_descendants",
        "version_trace_position",
        "provenance_ancestry",
        "admin_recorder_create",
        "admin_recorder_record",
        "admin_recorder_list",
        "admin_recorder_get",
        "admin_server_health",
        "resolve_inline_transclusions",
        "migrate_compound_to_inline",
        "element_remove_transclusion",
        "attribution_query_resolved",
        "crypto_get_public_key",
        "crypto_sign_data",
        "crypto_verify_signature",
        "crypto_key_rotation",
        "crypto_key_history",
        "work_endorse",
        "work_retract",
        "work_endorsements",
        "edition_endorse",
        "edition_retract",
        "edition_endorsements",
        "edition_visible_endorsements",
        "edition_total_endorsements",
        "federation_info",
        "federation_peers",
        "federated_transclusion_query",
        "federated_content_fetch",
        "endorsement_sync",
        "endorsement_add",
        "endorsement_retract",
        "endorsement_query",
        "state_sync",
        "state_alternatives",
        "membership_join_request",
        "membership_join_response",
        "membership_endorse_offer",
        "membership_endorse_accept",
        "membership_sync",
        "membership_sync_result",
        "membership_leave",
        "membership_list",
        "membership_verify",
        "governance_propose",
        "governance_prepare",
        "governance_commit",
        "governance_seal",
        "governance_log",
        "governance_status",
        "crdt_sync_open",
        "crdt_sync_close",
        "crdt_sync_update",
        "crdt_sync_diff",
        "crdt_sync_full_state",
        "crdt_sync_materialize",
        "crdt_sync_subscriber_count",
        "crdt_sync_text",
        "crdt_awareness_update",
        "crdt_awareness_get",
        "crdt_register_author",
        "attribution_query",
        "attribution_verify",
        "attribution_log_status",
        "attestation_report",
        "work_text_range",
        "work_outline",
        "work_search",
        "work_goto",
        "prov_json_export",
        "server_directory_list",
        "server_directory_add",
        "server_directory_remove",
        "server_directory_set_trust",
        "network_set_enabled",
        "external_links_set_enabled",
        "work_admin_delete",
        "admin_edit_policy_set",
        "admin_session_kick",
        "admin_audit_tail",
        "admin_clubs_list",
        "admin_grant_admin",
        "admin_revoke_admin",
        "cross_server_resolve",
        "cross_server_fetch_work",
        "cross_server_list_works",
        "federated_search",
        "fetch_introductions",
        "add_discovered_server",
        "cross_server_link_create",
        "cross_server_link_list",
        "fetch_remote_identity",
        "tumbler_resolve",
        "bloom_filter_get",
        "bloom_filter_check",
        "federation_attestation_create",
        "federation_attestation_verify",
        "federation_bundle_export",
        "cluster_verification_create",
        "cross_server_signature_verify",
        "historical_author_register",
        "historical_author_get",
        "historical_author_search",
        "historical_author_list",
        "import_source_work",
        "import_epub",
        "source_detect",
        "source_pattern_list",
        "work_list_by_author",
        "content_match",
        "work_apply_source_attribution",
        "work_apply_transclusion_attribution",
        "work_summary",
        "work_version_timeline",
        "passage_composition",
        "global_text_search",
        "seed_demo_attribution",
        "trail_update",
        "trail_publish",
        "trail_unpublish",
        "trail_list_published",
        "trail_list_categories",
        "trail_derived_work",
    ]
    .iter()
    .map(|s| s.to_string())
    .collect()
}



