use std::collections::HashMap;
use std::net::SocketAddr;

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
use super::audit::{AuditEventKind, ThreatLevel};
use super::channel::{ChannelDetector, EventMessage};
use super::codec::{BinaryCodec, JsonCodec, WireCodec};
use super::dispatch;
use super::protocol::*;
use super::shared::SharedState;

#[derive(Debug, serde::Deserialize)]
pub struct WsQuery {
    pub format: Option<String>,
}

pub fn build_router(state: SharedState) -> Router {
    Router::new()
        .route("/xudanu", get(ws_handler))
        .route("/xudanu/", get(ws_handler))
        .route("/", get(ws_handler))
        .with_state(state)
}

async fn ws_handler(
    ws: WebSocketUpgrade,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Query(query): Query<WsQuery>,
    State(state): State<SharedState>,
) -> impl IntoResponse {
    let format = query.format.as_deref().unwrap_or("binary").to_string();
    ws.on_upgrade(move |socket| handle_socket(socket, state, format, Some(addr)))
}

async fn handle_socket(
    socket: WebSocket,
    state: SharedState,
    format: String,
    remote_addr: Option<SocketAddr>,
) {
    let is_text = format == "json";
    let codec: Box<dyn WireCodec> = if is_text {
        Box::new(JsonCodec)
    } else {
        Box::new(BinaryCodec)
    };

    let session_id = state.server.with_server(|srv| srv.connect());

    {
        let mut sec = state.security.lock().unwrap();
        sec.on_session_opened(session_id, remote_addr, format!("session opened from {}", remote_addr.map(|a| a.to_string()).unwrap_or_default()));
    }

    let (mut ws_sender, mut ws_receiver) = socket.split();

    let (out_tx, mut out_rx) = mpsc::unbounded_channel::<Vec<u8>>();
    let (event_tx, mut event_rx) = mpsc::unbounded_channel::<EventMessage>();

    let writer_task = tokio::spawn(async move {
        loop {
            tokio::select! {
                Some(bytes) = out_rx.recv() => {
                    let msg = if is_text {
                        Message::Text(String::from_utf8_lossy(&bytes).into_owned().into())
                    } else {
                        Message::Binary(bytes.into())
                    };
                    if ws_sender.send(msg).await.is_err() {
                        break;
                    }
                }
                Some(ev) = event_rx.recv() => {
                    let event_codec: Box<dyn WireCodec> = if is_text {
                        Box::new(JsonCodec)
                    } else {
                        Box::new(BinaryCodec)
                    };
                    let wire_event = WireEvent {
                        subscription_id: 0,
                        event: ev.event,
                    };
                    match event_codec.encode_event(&wire_event) {
                        Ok(bytes) => {
                            let msg = if is_text {
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

    let _subscriptions: HashMap<u16, (DetectorType, BeId)> = HashMap::new();

    while let Some(Ok(msg)) = ws_receiver.next().await {
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
                let is_permission_op = matches!(
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

                let detector: Box<dyn crate::server::Detector> = Box::new(
                    ChannelDetector::new(session_id, event_tx.clone()),
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
                        codec.encode_response(req_id, &ResponseValue::Humber(req_id as u64))
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
                if let Ok(b) = codec.encode_response(parsed.request_id, &ResponseValue::Void) {
                    let _ = out_tx.send(b);
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
}
