use std::collections::HashMap;
use std::net::SocketAddr;
use std::sync::atomic::{AtomicU16, Ordering};

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

use crate::edition::BeId;
use super::audit::ThreatLevel;
use super::channel::{ChannelDetector, EventMessage};
use super::codec::{BinaryCodec, JsonCodec, WireCodec};
use super::dispatch;
use super::protocol::*;
use super::shared::SharedState;

static SUBSCRIPTION_COUNTER: AtomicU16 = AtomicU16::new(1);

#[derive(Debug, serde::Deserialize)]
pub struct WsQuery {
    pub format: Option<String>,
    pub version: Option<u8>,
}

pub fn build_router(state: SharedState) -> Router {
    Router::new()
        .route("/xudanu", get(ws_handler))
        .route("/xudanu/", get(ws_handler))
        .route("/blobs/{hash}", get(blob_get_handler))
        .route("/blobs/{hash}/preview", get(blob_preview_handler))
        .route("/", get(index_handler))
        .with_state(state)
}

async fn index_handler() -> impl IntoResponse {
    (
        [(axum::http::header::CONTENT_TYPE, "text/html; charset=utf-8")],
        include_str!("../../../static/index.html"),
    )
}

async fn ws_handler(
    ws: WebSocketUpgrade,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Query(query): Query<WsQuery>,
    State(state): State<SharedState>,
) -> impl IntoResponse {
    let format = query.format.as_deref().unwrap_or("binary").to_string();
    let client_version = query.version.unwrap_or(PROTOCOL_VERSION);
    ws.on_upgrade(move |socket| handle_socket(socket, state, format, Some(addr), client_version))
}

fn safe_content_type(mime: &str) -> axum::http::HeaderValue {
    mime.parse().unwrap_or_else(|_| "application/octet-stream".parse().unwrap())
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
        ).into_response(),
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
        ).into_response(),
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
        })).unwrap()
    } else {
        let mut buf = vec![PROTOCOL_VERSION, MessageType::Handshake.as_byte(), 0x00, 0x00];
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
        let accepting = state.server.with_server_ref(|srv| srv.admin_is_accepting_connections());
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

    let negotiated = perform_handshake(&codec, &mut ws_sender, &mut ws_receiver, client_version, is_text).await;
    if negotiated.is_none() {
        return;
    }

    let session_id = state.server.with_server(|srv| srv.connect());

    {
        let mut sec = state.security.lock().unwrap();
        sec.on_session_opened(session_id, remote_addr, format!("session opened from {}", remote_addr.map(|a| a.to_string()).unwrap_or_default()));
    }

    let (out_tx, mut out_rx) = mpsc::unbounded_channel::<Vec<u8>>();
    let (event_tx, mut event_rx) = mpsc::unbounded_channel::<EventMessage>();

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

    while let Some(Ok(msg)) = ws_receiver.next().await {
        {
            let shutting_down = state.server.with_server_ref(|srv| srv.is_shutdown_requested());
            if shutting_down {
                break;
            }
        }

        {
            let mut sec = state.security.lock().unwrap();
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
                    let mut sec = state.security.lock().unwrap();
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
                let result = dispatch::dispatch(&state.server, session_id, parsed.inner);

                if let Err(ref err) = result {
                    let mut sec = state.security.lock().unwrap();
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
                    let mut sec = state.security.lock().unwrap();
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
            IncomingMessage::Unsubscribe(parsed) => {
                let req_id = parsed.request_id;
                if let Ok(bytes) = codec.encode_response(req_id, &ResponseValue::Void) {
                    let _ = out_tx.send(bytes);
                }
            }
        }
    }

    writer_task.abort();
    state.server.with_server(|srv| {
        let _ = srv.disconnect(session_id);
    });
    {
        let mut sec = state.security.lock().unwrap();
        sec.on_session_closed(session_id, remote_addr, "connection closed".to_string());
    }
    drop(out_tx_clone);
}
