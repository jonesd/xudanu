use std::collections::HashMap;
use std::net::SocketAddr;
use std::sync::atomic::{AtomicU16, Ordering};

use crate::server::transport::shared::MAX_CSRF_TOKENS;

use axum::{
    extract::{
        ws::{Message, WebSocket, WebSocketUpgrade},
        ConnectInfo, Query, State,
    },
    response::IntoResponse,
    routing::get,
    Router,
};
use futures_util::{SinkExt, StreamExt};
use tokio::sync::mpsc;

use super::audit::ThreatLevel;
use super::channel::{ChannelDetector, EventMessage};
use super::codec::{BinaryCodec, JsonCodec, WireCodec};
use super::dispatch;
use super::protocol::*;
use super::shared::SharedState;
use crate::edition::BeId;

static SUBSCRIPTION_COUNTER: AtomicU16 = AtomicU16::new(1);

#[derive(Debug, serde::Deserialize)]
pub struct WsQuery {
    pub format: Option<String>,
    pub version: Option<u8>,
    pub csrf_token: Option<String>,
}

pub fn build_router(state: SharedState) -> Router {
    Router::new()
        .route("/xudanu", get(ws_handler))
        .route("/xudanu/", get(ws_handler))
        .route("/blobs/{hash}", get(blob_get_handler))
        .route("/blobs/{hash}/preview", get(blob_preview_handler))
        .route("/health", get(health_handler))
        .route("/csrf-token", get(csrf_token_handler))
        .route("/", get(index_handler))
        .fallback(get(static_fallback_handler))
        .with_state(state)
}

const EMBEDDED_INDEX_HTML: &str = include_str!("../../../static/index.html");

async fn index_handler(State(state): State<SharedState>) -> impl IntoResponse {
    let html = match &state.static_dir {
        Some(dir) => match tokio::fs::read_to_string(dir.join("index.html")).await {
            Ok(content) => {
                tracing::debug!("Serving index.html from {}", dir.display());
                content
            }
            Err(e) => {
                tracing::warn!(
                    "Failed to read {}/index.html: {}, using embedded",
                    dir.display(),
                    e
                );
                EMBEDDED_INDEX_HTML.to_owned()
            }
        },
        None => EMBEDDED_INDEX_HTML.to_owned(),
    };
    (
        [(axum::http::header::CONTENT_TYPE, "text/html; charset=utf-8")],
        html,
    )
}

async fn health_handler(State(state): State<SharedState>) -> impl IntoResponse {
    let json = state.server.with_server_ref(|server| server.health_json());
    (
        [(axum::http::header::CONTENT_TYPE, "application/json")],
        json,
    )
}

async fn csrf_token_handler(State(state): State<SharedState>) -> impl IntoResponse {
    if !state.csrf_enabled {
        return (
            axum::http::StatusCode::NOT_FOUND,
            "CSRF protection not enabled",
        )
            .into_response();
    }
    use rand::RngCore;
    let mut bytes = [0u8; 32];
    rand::rngs::OsRng.fill_bytes(&mut bytes);
    let token = hex_encode(&bytes);
    let mut tokens = state.csrf_tokens.lock().unwrap_or_else(|e| e.into_inner());
    tokens.push_back(token.clone());
    while tokens.len() > MAX_CSRF_TOKENS {
        tokens.pop_front();
    }
    drop(tokens);

    let body = serde_json::json!({"csrf_token": token});
    (
        [
            (axum::http::header::CONTENT_TYPE, "application/json"),
            (
                axum::http::header::SET_COOKIE,
                format!(
                    "xudanu_csrf={}; HttpOnly; SameSite=Strict; Path=/csrf-token",
                    token
                )
                .as_str(),
            ),
        ],
        serde_json::to_string(&body).unwrap_or_default(),
    )
        .into_response()
}

fn hex_encode(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{:02x}", b)).collect()
}

async fn static_fallback_handler(
    axum::extract::OriginalUri(uri): axum::extract::OriginalUri,
    State(state): State<SharedState>,
) -> impl IntoResponse {
    let dir = match &state.static_dir {
        Some(d) => d,
        None => return axum::http::StatusCode::NOT_FOUND.into_response(),
    };
    let path = uri.path().trim_start_matches('/');
    if path.is_empty() {
        return axum::http::StatusCode::NOT_FOUND.into_response();
    }
    let file_path = dir.join(path);
    if !file_path.starts_with(dir) {
        return axum::http::StatusCode::FORBIDDEN.into_response();
    }
    match tokio::fs::read(&file_path).await {
        Ok(bytes) => {
            let mime = mime_guess::from_path(&file_path).first_or_octet_stream();
            (
                [(axum::http::header::CONTENT_TYPE, mime.to_string())],
                bytes,
            )
                .into_response()
        }
        Err(_) => axum::http::StatusCode::NOT_FOUND.into_response(),
    }
}

async fn ws_handler(
    ws: WebSocketUpgrade,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Query(query): Query<WsQuery>,
    State(state): State<SharedState>,
    headers: axum::http::HeaderMap,
) -> impl IntoResponse {
    if let Some(ref allowed) = state.allowed_origins {
        let origin = headers
            .get("origin")
            .and_then(|v| v.to_str().ok())
            .unwrap_or("");
        if !allowed.contains(origin) {
            tracing::warn!(
                target: "xudanu::security",
                origin = origin,
                remote_addr = %addr,
                event = "SECURITY:ws_origin_rejected",
                "WebSocket origin rejected"
            );
            return (axum::http::StatusCode::FORBIDDEN, "Origin not allowed").into_response();
        }
    }

    if state.csrf_enabled {
        if let Some(ref token) = query.csrf_token {
            let valid = {
                let mut tokens = state.csrf_tokens.lock().unwrap_or_else(|e| e.into_inner());
                if let Some(pos) = tokens.iter().position(|t| t == token) {
                    tokens.remove(pos);
                    true
                } else {
                    false
                }
            };
            if !valid {
                tracing::warn!(
                    target: "xudanu::security",
                    remote_addr = %addr,
                    event = "SECURITY:ws_csrf_invalid",
                    "WebSocket CSRF token invalid"
                );
                return (axum::http::StatusCode::FORBIDDEN, "Invalid CSRF token").into_response();
            }
        } else {
            return (axum::http::StatusCode::FORBIDDEN, "CSRF token required").into_response();
        }
    }

    let format = query.format.as_deref().unwrap_or("binary").to_string();
    let client_version = query.version.unwrap_or(PROTOCOL_VERSION);
    ws.max_frame_size(16 * 1024 * 1024)
        .max_message_size(64 * 1024 * 1024)
        .on_upgrade(move |socket| handle_socket(socket, state, format, Some(addr), client_version))
        .into_response()
}

fn safe_content_type(mime: &str) -> axum::http::HeaderValue {
    mime.parse()
        .unwrap_or_else(|_| "application/octet-stream".parse().unwrap())
}

async fn blob_get_handler(
    axum::extract::Path(hash_hex): axum::extract::Path<String>,
    State(state): State<SharedState>,
) -> axum::response::Response {
    let hash_u64 = match u64::from_str_radix(&hash_hex, 16) {
        Ok(h) => h,
        Err(_) => return axum::http::StatusCode::BAD_REQUEST.into_response(),
    };
    let result: Option<(Vec<u8>, String)> = state.server.with_server(|srv| {
        let meta = srv.blob_info(hash_u64).ok()?;
        let data = srv.blob_get(hash_u64).ok()?;
        Some((data, meta.mime_type.clone()))
    });
    match result {
        Some((bytes, mime)) => (
            [(axum::http::header::CONTENT_TYPE, safe_content_type(&mime))],
            bytes,
        )
            .into_response(),
        None => axum::http::StatusCode::NOT_FOUND.into_response(),
    }
}

async fn blob_preview_handler(
    axum::extract::Path(hash_hex): axum::extract::Path<String>,
    State(state): State<SharedState>,
) -> axum::response::Response {
    let hash_u64 = match u64::from_str_radix(&hash_hex, 16) {
        Ok(h) => h,
        Err(_) => return axum::http::StatusCode::BAD_REQUEST.into_response(),
    };
    let result: Option<(Vec<u8>, String)> = state.server.with_server(|srv| {
        let meta = srv.blob_info(hash_u64).ok()?;
        let preview = srv.blob_preview(hash_u64).ok()??;
        Some((preview, meta.mime_type.clone()))
    });
    match result {
        Some((bytes, mime)) => (
            [(axum::http::header::CONTENT_TYPE, safe_content_type(&mime))],
            bytes,
        )
            .into_response(),
        None => axum::http::StatusCode::NOT_FOUND.into_response(),
    }
}

async fn perform_handshake(
    _codec: &Box<dyn WireCodec>,
    ws_sender: &mut futures_util::stream::SplitSink<WebSocket, Message>,
    _ws_receiver: &mut futures_util::stream::SplitStream<WebSocket>,
    client_version: u8,
    is_text: bool,
) -> Option<u8> {
    let hs_resp = HandshakeResponse::accepted(client_version);
    if client_version < MIN_SUPPORTED_VERSION || client_version > PROTOCOL_VERSION {
        let msg = if is_text {
            Message::Text(
                serde_json::to_string(&serde_json::json!({
                    "type": "error",
                    "code": "unsupported_version",
                    "message": format!("client version {} not in [{}, {}]", client_version, MIN_SUPPORTED_VERSION, PROTOCOL_VERSION)
                })).unwrap().into()
            )
        } else {
            Message::Binary(axum::body::Bytes::new())
        };
        let _ = ws_sender.send(msg).await;
        return None;
    }

    let negotiated = hs_resp.negotiated_version;
    let resp_bytes = if is_text {
        serde_json::to_vec(&serde_json::json!({
            "type": "handshake",
            "v": negotiated,
            "payload": {
                "server_version": hs_resp.server_version,
                "negotiated_version": hs_resp.negotiated_version,
                "server_id": hs_resp.server_id,
                "server_capabilities": hs_resp.server_capabilities,
            }
        }))
        .unwrap()
    } else {
        let mut buf = vec![
            PROTOCOL_VERSION,
            MessageType::Handshake.as_byte(),
            0x00,
            0x00,
        ];
        let payload = serde_json::to_vec(&hs_resp).unwrap();
        super::varint::encode_varint(payload.len() as u64, &mut buf);
        buf.extend_from_slice(&payload);
        buf
    };

    let msg = if is_text {
        Message::Text(String::from_utf8_lossy(&resp_bytes).into_owned().into())
    } else {
        Message::Binary(resp_bytes.into())
    };
    if ws_sender.send(msg).await.is_err() {
        return None;
    }

    Some(negotiated)
}

async fn handle_socket(
    socket: WebSocket,
    state: SharedState,
    format: String,
    remote_addr: Option<SocketAddr>,
    client_version: u8,
) {
    let is_text = format == "json";
    let codec: Box<dyn WireCodec> = if is_text {
        Box::new(JsonCodec)
    } else {
        Box::new(BinaryCodec)
    };

    {
        let accepting = state
            .server
            .with_server_ref(|srv| srv.admin_is_accepting_connections());
        if !accepting {
            let (mut sender, _) = socket.split();
            let msg = if is_text {
                Message::Text(r#"{"type":"error","code":"not_accepting_connections"}"#.into())
            } else {
                Message::Binary(axum::body::Bytes::new())
            };
            let _ = sender.send(msg).await;
            return;
        }
    }

    let (mut ws_sender, mut ws_receiver) = socket.split();

    let negotiated = perform_handshake(
        &codec,
        &mut ws_sender,
        &mut ws_receiver,
        client_version,
        is_text,
    )
    .await;
    if negotiated.is_none() {
        return;
    }

    let too_many = {
        let sec = state.security.lock().unwrap_or_else(|e| e.into_inner());
        sec.active_sessions_for_ip(remote_addr) >= 50
    };
    if too_many {
        tracing::warn!(
            "Rejecting connection from {}: too many sessions",
            remote_addr.map(|a| a.to_string()).unwrap_or_default()
        );
        let _ = ws_sender.send(Message::Close(None)).await;
        return;
    }

    let session_id = state.server.with_server(|srv| srv.connect());

    {
        let mut sec = state.security.lock().unwrap_or_else(|e| e.into_inner());
        sec.on_session_opened(
            session_id,
            remote_addr,
            format!(
                "session opened from {}",
                remote_addr.map(|a| a.to_string()).unwrap_or_default()
            ),
        );
    }

    let (out_tx, mut out_rx) = mpsc::unbounded_channel::<Vec<u8>>();
    let (event_tx, mut event_rx) = mpsc::unbounded_channel::<EventMessage>();

    state.register_session_sender(session_id, event_tx.clone());
    let state_cleanup = state.clone();
    let session_id_cleanup = session_id;

    let out_tx_clone = out_tx.clone();
    let is_text_writer = is_text;
    let writer_task = tokio::spawn(async move {
        loop {
            tokio::select! {
                biased;

                Some(bytes) = out_rx.recv() => {
                    let msg = if is_text_writer {
                        Message::Text(String::from_utf8_lossy(&bytes).into_owned().into())
                    } else {
                        Message::Binary(bytes.into())
                    };
                    if ws_sender.send(msg).await.is_err() {
                        break;
                    }
                }
                Some(ev) = event_rx.recv() => {
                    let event_codec: Box<dyn WireCodec> = if is_text_writer {
                        Box::new(JsonCodec)
                    } else {
                        Box::new(BinaryCodec)
                    };
                    let wire_event = WireEvent {
                        subscription_id: ev.subscription_id,
                        event: ev.event,
                    };
                    match event_codec.encode_event(&wire_event) {
                        Ok(bytes) => {
                            let msg = if is_text_writer {
                                Message::Text(String::from_utf8_lossy(&bytes).into_owned().into())
                            } else {
                                Message::Binary(bytes.into())
                            };
                            if ws_sender.send(msg).await.is_err() {
                                break;
                            }
                        }
                        Err(_) => break,
                    }
                }
                else => break,
            }
        }
    });

    let mut subscriptions: HashMap<u16, (DetectorType, BeId)> = HashMap::new();
    let mut content_subscriptions: HashMap<
        u16,
        (
            crate::edition::RecorderId,
            BeId,
            Vec<crate::edition::RangeElement>,
        ),
    > = HashMap::new();
    let mut fossil_to_sub: HashMap<crate::edition::RecorderId, u16> = HashMap::new();

    let drain_fn = |fossil_to_sub: &HashMap<crate::edition::RecorderId, u16>,
                    out_tx: &mpsc::UnboundedSender<Vec<u8>>,
                    is_text_writer: bool| {
        if fossil_to_sub.is_empty() {
            return;
        }
        let my_fossils: std::collections::HashSet<_> = fossil_to_sub.keys().copied().collect();
        let notifications = state
            .server
            .with_server(|srv| srv.drain_content_notifications_for(&my_fossils));
        if notifications.is_empty() {
            return;
        }
        let event_codec: Box<dyn WireCodec> = if is_text_writer {
            Box::new(JsonCodec)
        } else {
            Box::new(BinaryCodec)
        };
        for notif in notifications {
            if let Some(&sub_id) = fossil_to_sub.get(&notif.fossil_id) {
                let wire_event = WireEvent {
                    subscription_id: sub_id,
                    event: EventPayload::ContentMatch {
                        fossil_id: notif.fossil_id,
                        edition_be_id: notif.edition_be_id,
                        is_direct: notif.is_direct,
                        work_be_id: notif.work_be_id,
                        title: notif.title.clone(),
                    },
                };
                if let Ok(ev_bytes) = event_codec.encode_event(&wire_event) {
                    let _ = out_tx.send(ev_bytes);
                }
            }
        }
    };

    let mut drain_interval = tokio::time::interval(std::time::Duration::from_millis(200));
    drain_interval.tick().await;

    loop {
        tokio::select! {
            msg_result = ws_receiver.next() => {
                let msg = match msg_result {
                    Some(Ok(m)) => m,
                    _ => break,
                };

                {
                    let shutting_down = state.server.with_server_ref(|srv| srv.is_shutdown_requested());
                    if shutting_down {
                        break;
                    }
                }

                {
                    let session_valid = state.server.with_server_ref(|srv| {
                        srv.session(session_id).map(|s| s.is_valid()).unwrap_or(false)
                    });
                    if !session_valid {
                        break;
                    }
                }

                {
                    let mut sec = state.security.lock().unwrap_or_else(|e| e.into_inner());
                    let threat = sec.on_request(session_id, remote_addr);
                    if threat == ThreatLevel::Critical {
                        let _ = out_tx.send(vec![]);
                        break;
                    }
                }

                let data = match msg {
                    Message::Binary(data) => data.to_vec(),
                    Message::Text(text) => text.as_bytes().to_vec(),
                    Message::Close(_) => break,
                    Message::Ping(_) => continue,
                    Message::Pong(_) => continue,
                };

                let incoming = match codec.decode_request(&data) {
                    Ok(msg) => msg,
                    Err(e) => {
                        {
                            let mut sec = state.security.lock().unwrap_or_else(|e| e.into_inner());
                            sec.on_protocol_violation(session_id, remote_addr, e.to_string());
                            if sec.should_disconnect(session_id, remote_addr) {
                                break;
                            }
                        }
                        if let Ok(bytes) = codec.encode_error(0, ErrorCode::ProtocolError, &e.to_string()) {
                            let _ = out_tx.send(bytes);
                        }
                        continue;
                    }
                };

                match incoming {
                    IncomingMessage::Heartbeat => {
                        if let Ok(bytes) = codec.encode_heartbeat() {
                            let _ = out_tx.send(bytes);
                        }
                    }
                    IncomingMessage::Request(parsed) => {
                        let req_id = parsed.request_id;
                        let is_auth_op = matches!(
                            &parsed.inner,
                            WireRequest::SessionLoginPublic
                                | WireRequest::SessionLogin { .. }
                                | WireRequest::SessionLoginByName { .. }
                                | WireRequest::SessionAuthenticate { .. }
                        );
                        let _is_permission_op = matches!(
                            &parsed.inner,
                            WireRequest::WorkGrab { .. }
                                | WireRequest::WorkRevise { .. }
                                | WireRequest::WorkSetReadClub { .. }
                                | WireRequest::WorkSetEditClub { .. }
                                | WireRequest::WorkRelease { .. }
                        );
                        let result = dispatch::dispatch(&state, session_id, parsed.inner);

                        if let Err(ref err) = result {
                            let mut sec = state.security.lock().unwrap_or_else(|e| e.into_inner());
                            let code = ErrorCode::from_server_error(err);
                            match code {
                                ErrorCode::NotAuthorized => {
                                    if is_auth_op {
                                        sec.on_auth_failure(session_id, remote_addr, err.to_string());
                                    } else {
                                        sec.on_permission_denied(session_id, remote_addr, err.to_string());
                                    }
                                }
                                ErrorCode::NotGrabbed | ErrorCode::AlreadyGrabbed => {
                                    sec.on_grab_conflict(session_id, remote_addr, err.to_string());
                                }
                                _ => {}
                            }
                            if sec.should_disconnect(session_id, remote_addr) {
                                let bytes = codec
                                    .encode_error(req_id, code, &err.to_string())
                                    .unwrap_or_default();
                                let _ = out_tx.send(bytes);
                                break;
                            }
                        } else if is_auth_op {
                            let mut sec = state.security.lock().unwrap_or_else(|e| e.into_inner());
                            sec.on_auth_success(session_id, remote_addr, "login".to_string());
                        }

                        let bytes = match result {
                            Ok(value) => codec.encode_response(req_id, &value),
                            Err(err) => {
                                let code = ErrorCode::from_server_error(&err);
                                codec.encode_error(req_id, code, &err.to_string())
                            }
                        };
                        if let Ok(b) = bytes {
                            let _ = out_tx.send(b);
                        }
                    }
                    IncomingMessage::Subscribe(parsed) => {
                        let req_id = parsed.request_id;
                        let target_id = parsed.subscribe.target_id;
                        let det_type = parsed.subscribe.detector_type;
                        let sub_id = SUBSCRIPTION_COUNTER.fetch_add(1, Ordering::Relaxed);

                        match det_type {
                            DetectorType::Status | DetectorType::Revision | DetectorType::Fill => {
                                let detector: Box<dyn crate::server::Detector> = Box::new(
                                    ChannelDetector::new_with_sub(session_id, sub_id, event_tx.clone()),
                                );
                                let result = match det_type {
                                    DetectorType::Status => {
                                        state.server.with_server(|srv| srv.add_status_detector(target_id, detector))
                                    }
                                    DetectorType::Revision => {
                                        state.server.with_server(|srv| srv.add_revision_detector(target_id, detector))
                                    }
                                    DetectorType::Fill => {
                                        state.server.with_server(|srv| srv.add_fill_detector(target_id, detector))
                                    }
                                    _ => unreachable!(),
                                };
                                let resp = match result {
                                    Ok(()) => {
                                        subscriptions.insert(sub_id, (det_type, target_id));
                                        codec.encode_response(req_id, &ResponseValue::Humber(sub_id as u64))
                                    }
                                    Err(err) => {
                                        let code = ErrorCode::from_server_error(&err);
                                        codec.encode_error(req_id, code, &err.to_string())
                                    }
                                };
                                if let Ok(b) = resp {
                                    let _ = out_tx.send(b);
                                }
                            }
                            DetectorType::ContentTranscluders | DetectorType::ContentWorks => {
                                let kind = match det_type {
                                    DetectorType::ContentTranscluders => crate::edition::RecorderKind::Transcluders,
                                    DetectorType::ContentWorks => crate::edition::RecorderKind::Works,
                                    _ => unreachable!(),
                                };
                                tracing::debug!(target: "xudanu::content_watch",
                                    target_id, ?det_type, "Subscribe content watch");
                                let (fossil_id, initial_results, content_elements, watched_words) = state.server.with_server(|srv| {
                                    let content_elements: Vec<crate::edition::RangeElement> = srv
                                        .get_edition(target_id)
                                        .ok()
                                        .flatten()
                                        .map(|ed| {
                                            ed.all_entries().iter().map(|(_, c)| c.element.clone()).collect()
                                        })
                                        .unwrap_or_default();
                                    let watched_words: std::collections::HashSet<String> = srv
                                        .get_edition(target_id)
                                        .ok()
                                        .flatten()
                                        .map(|ed| ed.word_set())
                                        .unwrap_or_default();
                                    tracing::debug!(target: "xudanu::content_watch",
                                        count = content_elements.len(), word_count = watched_words.len(), "Content elements extracted");
                                    let query = crate::edition::RecorderQuery {
                                        kind,
                                        region: None,
                                        direct_only: false,
                                        authority_clubs: Vec::new(),
                                        endorsement_filter: None,
                                        watched_content: content_elements.clone(),
                                    };
                                    let fossil_id = srv.recorder_create_for_content(query.clone(), target_id);
                                    srv.recorder_plant(target_id, fossil_id, &query.watched_content);
                                    let fossil = srv.recorder_get(fossil_id).unwrap();
                                    let results = fossil.results.clone();
                                    tracing::debug!(target: "xudanu::content_watch",
                                        fossil_id, result_count = results.len(), "Initial results");
                                    (fossil_id, results, content_elements, watched_words)
                                });
                                content_subscriptions.insert(sub_id, (fossil_id, target_id, content_elements));
                                fossil_to_sub.insert(fossil_id, sub_id);
                                let resp = codec.encode_response(req_id, &ResponseValue::Humber(sub_id as u64));
                                if let Ok(b) = resp {
                                    let _ = out_tx.send(b);
                                }
                                let event_codec: Box<dyn WireCodec> = if is_text_writer {
                                    Box::new(JsonCodec)
                                } else {
                                    Box::new(BinaryCodec)
                                };
                                for result in initial_results {
                                    let edition_be_id = result.source_edition_id.unwrap_or(target_id);
                                    if edition_be_id == target_id {
                                        tracing::debug!(target: "xudanu::content_watch",
                                            edition_be_id, "Skipping self-match in initial results");
                                        continue;
                                    }
                                    if !watched_words.is_empty() {
                                        let match_words: std::collections::HashSet<String> = state.server.with_server(|srv| {
                                            srv.get_edition(edition_be_id)
                                                .ok()
                                                .flatten()
                                                .map(|ed| ed.word_set())
                                                .unwrap_or_default()
                                        });
                                        if !match_words.is_empty() {
                                            let sim = crate::edition::jaccard_similarity(&watched_words, &match_words);
                                            if sim < 0.05 {
                                                tracing::debug!(target: "xudanu::content_watch",
                                                    edition_be_id, sim, "Skipping initial match below Jaccard threshold");
                                                continue;
                                            }
                                        }
                                    }
                                    tracing::debug!(target: "xudanu::content_watch",
                                        edition_be_id, "Sending initial content match");
                    let (work_be_id, title) = state.server.with_server(|srv| {
                        srv.find_work_for_edition(edition_be_id)
                            .map(|(wid, t)| (Some(wid), Some(t)))
                            .unwrap_or((None, None))
                    });
                                    let wire_event = WireEvent {
                                        subscription_id: sub_id,
                                        event: EventPayload::ContentMatch {
                                            fossil_id,
                                            edition_be_id,
                                            is_direct: result.is_direct,
                                            work_be_id,
                                            title,
                                        },
                                    };
                                    if let Ok(bytes) = event_codec.encode_event(&wire_event) {
                                        let _ = out_tx.send(bytes);
                                    }
                                }
                            }
                        }
                    }
                    IncomingMessage::Unsubscribe(parsed) => {
                        let req_id = parsed.request_id;
                        let sub_id = req_id;
                        if let Some((det_type, target_id)) = subscriptions.remove(&sub_id) {
                            state.server.with_server(|srv| {
                                srv.remove_detector(det_type, target_id, sub_id);
                            });
                        }
                        if let Some((fossil_id, edition_id, content)) = content_subscriptions.remove(&sub_id) {
                            fossil_to_sub.remove(&fossil_id);
                            state.server.with_server(|srv| {
                                srv.recorder_unplant(edition_id, fossil_id, &content);
                                srv.recorder_extinguish(fossil_id);
                            });
                        }
                        if let Ok(bytes) = codec.encode_response(req_id, &ResponseValue::Void) {
                            let _ = out_tx.send(bytes);
                        }
                    }
                }

                drain_fn(&fossil_to_sub, &out_tx, is_text_writer);
            }
            _ = drain_interval.tick() => {
                drain_fn(&fossil_to_sub, &out_tx, is_text_writer);
            }
        }
    }

    writer_task.abort();
    for (sub_id, (det_type, target_id)) in subscriptions.drain() {
        state.server.with_server(|srv| {
            srv.remove_detector(det_type, target_id, sub_id);
        });
    }
    for (_sub_id, (fossil_id, edition_id, content)) in content_subscriptions.drain() {
        fossil_to_sub.remove(&fossil_id);
        state.server.with_server(|srv| {
            srv.recorder_unplant(edition_id, fossil_id, &content);
            srv.recorder_extinguish(fossil_id);
        });
    }
    if !fossil_to_sub.is_empty() {
        let remaining_fossils: std::collections::HashSet<_> =
            fossil_to_sub.keys().copied().collect();
        state.server.with_server(|srv| {
            srv.drain_content_notifications_for(&remaining_fossils);
        });
    }
    state.server.with_server(|srv| {
        let _ = srv.disconnect(session_id);
    });
    {
        let mut sec = state.security.lock().unwrap_or_else(|e| e.into_inner());
        sec.on_session_closed(session_id, remote_addr, "connection closed".to_string());
    }
    drop(out_tx_clone);
    state_cleanup.unregister_session_sender(&session_id_cleanup);
}
