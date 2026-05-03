use std::net::SocketAddr;

use axum::{
    extract::{
        ws::{Message, WebSocket, WebSocketUpgrade},
        ConnectInfo, State,
    },
    response::IntoResponse,
    routing::get,
    Router,
};
use futures_util::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};

use super::shared::SharedState;

const FEDERATION_PROTOCOL_VERSION: u8 = 1;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FederationHello {
    pub protocol_version: u8,
    pub ephemeral_public_key: Vec<u8>,
    pub server_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FederationSignature {
    pub signature: Vec<u8>,
    pub signing_key: Vec<u8>,
    pub kex_key: Vec<u8>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FederationReady {
    pub server_id: String,
    pub status: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum FederationFrame {
    Hello(FederationHello),
    Signature(FederationSignature),
    Ready(FederationReady),
    Heartbeat,
    Ack,
}

pub fn build_federation_router(state: SharedState) -> Router {
    Router::new()
        .route("/federation", get(federation_ws_handler))
        .route("/federation/", get(federation_ws_handler))
        .with_state(state)
}

pub fn merge_routers(client: Router, federation: Router) -> Router {
    client.merge(federation)
}

async fn federation_ws_handler(
    ws: WebSocketUpgrade,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    State(state): State<SharedState>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_federation_socket(socket, state, addr))
}

async fn handle_federation_socket(
    socket: WebSocket,
    state: SharedState,
    remote_addr: SocketAddr,
) {
    let (mut ws_sender, mut ws_receiver) = socket.split();

    let (my_server_id, my_eph_bytes, _my_eph) = state.server.with_server(|srv| {
        srv.federation_handshake_init()
    });

    let my_hello = FederationHello {
        protocol_version: FEDERATION_PROTOCOL_VERSION,
        ephemeral_public_key: my_eph_bytes.to_vec(),
        server_id: my_server_id.clone(),
    };

    let hello_json = match serde_json::to_string(&FederationFrame::Hello(my_hello)) {
        Ok(j) => j,
        Err(_) => return,
    };
    if ws_sender.send(Message::Text(hello_json.into())).await.is_err() {
        return;
    }

    let peer_hello = match wait_for_frame(&mut ws_receiver).await {
        Some(FederationFrame::Hello(hello)) => hello,
        Some(other) => {
            let _ = ws_sender.send(Message::Text(
                format!("{{\"type\":\"error\",\"message\":\"expected Hello, got {:?}\"}}", other).into()
            )).await;
            return;
        }
        None => return,
    };

    if peer_hello.protocol_version != FEDERATION_PROTOCOL_VERSION {
        let _ = ws_sender.send(Message::Text(
            format!("{{\"type\":\"error\",\"message\":\"unsupported version {}\"}}", peer_hello.protocol_version).into()
        )).await;
        return;
    }

    let peer_eph_bytes: [u8; 32] = match peer_hello.ephemeral_public_key.as_slice().try_into() {
        Ok(b) => b,
        Err(_) => return,
    };

    let (sig_bytes, signing_key_bytes, kex_key_bytes) = state.server.with_server(|srv| {
        srv.federation_sign_handshake(&my_eph_bytes, &peer_eph_bytes)
    });

    let my_sig = FederationSignature {
        signature: sig_bytes,
        signing_key: signing_key_bytes,
        kex_key: kex_key_bytes,
    };

    let sig_json = match serde_json::to_string(&FederationFrame::Signature(my_sig)) {
        Ok(j) => j,
        Err(_) => return,
    };
    if ws_sender.send(Message::Text(sig_json.into())).await.is_err() {
        return;
    }

    let peer_sig = match wait_for_frame(&mut ws_receiver).await {
        Some(FederationFrame::Signature(sig)) => sig,
        Some(other) => {
            let _ = ws_sender.send(Message::Text(
                format!("{{\"type\":\"error\",\"message\":\"expected Signature, got {:?}\"}}", other).into()
            )).await;
            return;
        }
        None => return,
    };

    let peer_signing_key_bytes: [u8; 32] = match peer_sig.signing_key.as_slice().try_into() {
        Ok(b) => b,
        Err(_) => return,
    };
    let peer_verifying_key = match ed25519_dalek::VerifyingKey::from_bytes(&peer_signing_key_bytes) {
        Ok(vk) => vk,
        Err(_) => {
            let _ = ws_sender.send(Message::Text(
                "{\"type\":\"error\",\"message\":\"invalid peer signing key\"}".into()
            )).await;
            return;
        }
    };

    let peer_sig_bytes: [u8; 64] = match peer_sig.signature.as_slice().try_into() {
        Ok(b) => b,
        Err(_) => return,
    };
    let peer_signature = match ed25519_dalek::Signature::from_slice(&peer_sig_bytes) {
        Ok(s) => s,
        Err(_) => return,
    };

    if let Err(e) = crate::crypto::kex::verify_handshake_signature(
        &peer_verifying_key,
        &peer_eph_bytes,
        &my_eph_bytes,
        &peer_signature,
    ) {
        let _ = ws_sender.send(Message::Text(
            format!("{{\"type\":\"error\",\"message\":\"handshake signature failed: {}\"}}", e).into()
        )).await;
        return;
    }

    let peer_kex_bytes: [u8; 32] = match peer_sig.kex_key.as_slice().try_into() {
        Ok(b) => b,
        Err(_) => return,
    };

    let _session_keys = state.server.with_server(|srv| {
        srv.federation_derive_session_keys(&peer_kex_bytes, &my_eph_bytes, &peer_eph_bytes)
    });

    let ready_json = match serde_json::to_string(&FederationFrame::Ready(FederationReady {
        server_id: my_server_id,
        status: "connected".to_string(),
    })) {
        Ok(j) => j,
        Err(_) => return,
    };
    if ws_sender.send(Message::Text(ready_json.into())).await.is_err() {
        return;
    }

    let peer_server_id = peer_hello.server_id.clone();

    tracing::info!(
        "Federation handshake completed with server {} from {}",
        peer_server_id, remote_addr
    );

    loop {
        tokio::select! {
            msg = ws_receiver.next() => {
                match msg {
                    Some(Ok(Message::Close(_))) | None => break,
                    Some(Ok(Message::Ping(_))) => continue,
                    Some(Ok(Message::Text(text))) => {
                        match serde_json::from_str::<FederationFrame>(&text) {
                            Ok(FederationFrame::Heartbeat) => {
                                let _ = ws_sender.send(Message::Text(
                                    serde_json::to_string(&FederationFrame::Ack).unwrap_or_default().into()
                                )).await;
                            }
                            Ok(FederationFrame::Ready(r)) => {
                                tracing::info!("Peer ready: {} status={}", r.server_id, r.status);
                            }
                            Ok(_) => {}
                            Err(_) => {}
                        }
                    }
                    Some(Ok(Message::Binary(_))) => {}
                    Some(Ok(Message::Pong(_))) => continue,
                    _ => continue,
                }
            }
        }
    }

    tracing::info!("Federation connection closed with server {}", peer_server_id);
}

async fn wait_for_frame(ws_receiver: &mut futures_util::stream::SplitStream<WebSocket>) -> Option<FederationFrame> {
    while let Some(Ok(msg)) = ws_receiver.next().await {
        match msg {
            Message::Text(text) => {
                match serde_json::from_str::<FederationFrame>(&text) {
                    Ok(frame) => return Some(frame),
                    Err(_) => return None,
                }
            }
            Message::Close(_) => return None,
            Message::Ping(_) => continue,
            Message::Pong(_) => continue,
            Message::Binary(_) => continue,
        }
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn federation_frame_hello_roundtrip() {
        let hello = FederationFrame::Hello(FederationHello {
            protocol_version: 1,
            ephemeral_public_key: vec![0u8; 32],
            server_id: "test".to_string(),
        });
        let json = serde_json::to_string(&hello).unwrap();
        assert!(json.contains("\"type\":\"Hello\""));
        let back: FederationFrame = serde_json::from_str(&json).unwrap();
        match back {
            FederationFrame::Hello(h) => {
                assert_eq!(h.protocol_version, 1);
                assert_eq!(h.server_id, "test");
            }
            _ => panic!("expected Hello"),
        }
    }

    #[test]
    fn federation_frame_signature_roundtrip() {
        let sig = FederationFrame::Signature(FederationSignature {
            signature: vec![1u8; 64],
            signing_key: vec![2u8; 32],
            kex_key: vec![3u8; 32],
        });
        let json = serde_json::to_string(&sig).unwrap();
        assert!(json.contains("\"type\":\"Signature\""));
        let back: FederationFrame = serde_json::from_str(&json).unwrap();
        match back {
            FederationFrame::Signature(s) => {
                assert_eq!(s.signature.len(), 64);
                assert_eq!(s.signing_key.len(), 32);
                assert_eq!(s.kex_key.len(), 32);
            }
            _ => panic!("expected Signature"),
        }
    }

    #[test]
    fn federation_frame_heartbeat_roundtrip() {
        let json = serde_json::to_string(&FederationFrame::Heartbeat).unwrap();
        assert!(json.contains("\"type\":\"Heartbeat\""));
        let back: FederationFrame = serde_json::from_str(&json).unwrap();
        assert!(matches!(back, FederationFrame::Heartbeat));
    }

    #[test]
    fn federation_frame_ready_roundtrip() {
        let ready = FederationFrame::Ready(FederationReady {
            server_id: "abc123".to_string(),
            status: "connected".to_string(),
        });
        let json = serde_json::to_string(&ready).unwrap();
        let back: FederationFrame = serde_json::from_str(&json).unwrap();
        match back {
            FederationFrame::Ready(r) => {
                assert_eq!(r.server_id, "abc123");
                assert_eq!(r.status, "connected");
            }
            _ => panic!("expected Ready"),
        }
    }
}
