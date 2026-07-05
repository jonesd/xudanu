use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;

use futures_util::{SinkExt, StreamExt};
use tokio::sync::{mpsc, RwLock};
use tokio_tungstenite::{
    connect_async, tungstenite::Message as WsMessage, MaybeTlsStream, WebSocketStream,
};

use super::federation_handler::decrypt_frame;
use super::federation_handler::encrypt_frame;
use super::federation_handler::process_federation_frame;
use super::federation_handler::FederationFrame;
use super::federation_handler::FederationHello;
use super::federation_handler::FederationSignature;
use super::federation_handler::FEDERATION_MIN_COMPAT_VERSION;
use super::federation_handler::FEDERATION_PROTOCOL_VERSION;
use super::shared::SharedState;
use crate::crypto::keys::hex_encode;

type PeerStream = WebSocketStream<MaybeTlsStream<tokio::net::TcpStream>>;

struct PeerChannel {
    frame_tx: mpsc::UnboundedSender<FederationFrame>,
    peer_server_id: String,
}

#[derive(Clone)]
pub struct PeerPool {
    peers: Arc<RwLock<HashMap<String, PeerChannel>>>,
}

impl PeerPool {
    pub fn new() -> Self {
        PeerPool {
            peers: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    async fn insert(
        &self,
        addr: String,
        server_id: String,
        tx: mpsc::UnboundedSender<FederationFrame>,
    ) {
        self.peers.write().await.insert(
            addr,
            PeerChannel {
                frame_tx: tx,
                peer_server_id: server_id,
            },
        );
    }

    async fn remove(&self, addr: &str) {
        self.peers.write().await.remove(addr);
    }

    pub async fn broadcast(&self, frame: &FederationFrame) {
        let peers = self.peers.read().await;
        for ch in peers.values() {
            let _ = ch.frame_tx.send(frame.clone());
        }
    }

    pub async fn send(&self, addr: &str, frame: &FederationFrame) {
        let peers = self.peers.read().await;
        if let Some(ch) = peers.get(addr) {
            let _ = ch.frame_tx.send(frame.clone());
        }
    }

    pub async fn connected_peers(&self) -> Vec<String> {
        self.peers
            .read()
            .await
            .values()
            .map(|ch| ch.peer_server_id.clone())
            .collect()
    }

    pub async fn len(&self) -> usize {
        self.peers.read().await.len()
    }
}

pub async fn dial_and_maintain(peer_addr: String, state: SharedState, pool: PeerPool) {
    let mut backoff_secs = 1u64;
    const MAX_BACKOFF_SECS: u64 = 30;

    loop {
        match dial_peer(&peer_addr, &state).await {
            Ok((ws, peer_server_id, encrypt_cipher, decrypt_cipher)) => {
                tracing::info!(
                    "Federation: outbound connection established to {} ({})",
                    peer_server_id,
                    peer_addr
                );
                backoff_secs = 1;

                run_outbound_connection(
                    ws,
                    state.clone(),
                    pool.clone(),
                    peer_addr.clone(),
                    peer_server_id,
                    encrypt_cipher,
                    decrypt_cipher,
                )
                .await;

                tracing::info!(
                    "Federation: outbound connection to {} lost, will reconnect",
                    peer_addr
                );
            }
            Err(e) => {
                tracing::warn!(
                    "Federation: failed to connect to {}: {}, retry in {}s",
                    peer_addr,
                    e,
                    backoff_secs
                );
            }
        }

        tokio::time::sleep(Duration::from_secs(backoff_secs)).await;
        backoff_secs = (backoff_secs * 2).min(MAX_BACKOFF_SECS);
    }
}

async fn dial_peer(
    peer_addr: &str,
    state: &SharedState,
) -> Result<
    (
        PeerStream,
        String,
        crate::crypto::aead::SessionCipher,
        crate::crypto::aead::SessionCipher,
    ),
    String,
> {
    let url = format!("ws://{}/federation", peer_addr);

    let (mut ws, _) = connect_async(&url)
        .await
        .map_err(|e| format!("connect failed: {}", e))?;

    let server_hello_json = recv_text_frame(&mut ws).await?;
    let server_hello_frame: FederationFrame = serde_json::from_str(&server_hello_json)
        .map_err(|e| format!("invalid server Hello JSON: {}", e))?;
    let server_hello = match server_hello_frame {
        FederationFrame::Hello(h) => h,
        _ => return Err("expected Hello from server".to_string()),
    };

    if server_hello.protocol_version < FEDERATION_MIN_COMPAT_VERSION
        || FEDERATION_PROTOCOL_VERSION < server_hello.min_compat_version
    {
        return Err(format!(
            "incompatible versions: peer v{} (min {}), us v{} (min {})",
            server_hello.protocol_version,
            server_hello.min_compat_version,
            FEDERATION_PROTOCOL_VERSION,
            FEDERATION_MIN_COMPAT_VERSION
        ));
    }

    let peer_eph_bytes: [u8; 32] = server_hello
        .ephemeral_public_key
        .as_slice()
        .try_into()
        .map_err(|_| "invalid server ephemeral key length".to_string())?;

    let (my_server_id, my_eph_bytes, my_eph) = state
        .server
        .with_server(|srv| srv.federation_handshake_init());

    let my_hello = FederationFrame::Hello(FederationHello {
        protocol_version: FEDERATION_PROTOCOL_VERSION,
        min_compat_version: FEDERATION_MIN_COMPAT_VERSION,
        ephemeral_public_key: my_eph_bytes.to_vec(),
        server_id: my_server_id.clone(),
    });
    ws.send(WsMessage::Text(
        serde_json::to_string(&my_hello)
            .map_err(|e| format!("serialize Hello: {}", e))?
            .into(),
    ))
    .await
    .map_err(|e| format!("send Hello: {}", e))?;

    let server_sig_json = recv_text_frame(&mut ws).await?;
    let server_sig_frame: FederationFrame = serde_json::from_str(&server_sig_json)
        .map_err(|e| format!("invalid server Signature JSON: {}", e))?;
    let server_sig = match server_sig_frame {
        FederationFrame::Signature(s) => s,
        _ => return Err("expected Signature from server".to_string()),
    };

    let peer_vk_bytes: [u8; 32] = server_sig
        .verifying_key
        .as_slice()
        .try_into()
        .map_err(|_| "invalid server verifying key length".to_string())?;
    let peer_verifying_key = ed25519_dalek::VerifyingKey::from_bytes(&peer_vk_bytes)
        .map_err(|_| "invalid server verifying key".to_string())?;

    let peer_sig_bytes: [u8; 64] = server_sig
        .signature
        .as_slice()
        .try_into()
        .map_err(|_| "invalid server signature length".to_string())?;
    let peer_signature = ed25519_dalek::Signature::from_slice(&peer_sig_bytes)
        .map_err(|_| "invalid server signature".to_string())?;

    crate::crypto::kex::verify_handshake_signature(
        &peer_verifying_key,
        &peer_eph_bytes,
        &my_eph_bytes,
        &peer_signature,
    )
    .map_err(|e| format!("server handshake signature failed: {}", e))?;

    let peer_verifying_key_hex = hex_encode(&peer_vk_bytes);

    let peer_known = state
        .server
        .with_server_ref(|srv| srv.federation_is_peer_known(&peer_verifying_key_hex));
    if !peer_known {
        return Err(format!(
            "server {} not in trusted peers list (key={}…)",
            server_hello.server_id,
            &peer_verifying_key_hex[..16]
        ));
    }

    let peer_kex_bytes: [u8; 32] = server_sig
        .kex_key
        .as_slice()
        .try_into()
        .map_err(|_| "invalid server kex key length".to_string())?;

    let session_keys = state.server.with_server(|srv| {
        srv.federation_derive_session_keys(&peer_kex_bytes, &my_eph, &peer_eph_bytes)
    });

    let encrypt_cipher = crate::crypto::aead::SessionCipher::new(
        session_keys.inbound,
        0,
        crate::crypto::kdf::DomainLabel::FEDERATION_SERVER_FROM_SERVER,
    );
    let decrypt_cipher = crate::crypto::aead::SessionCipher::new(
        session_keys.outbound,
        0,
        crate::crypto::kdf::DomainLabel::FEDERATION_SERVER_TO_SERVER,
    );

    let (sig_bytes, signing_key_bytes, kex_key_bytes) = state
        .server
        .with_server(|srv| srv.federation_sign_handshake(&my_eph_bytes, &peer_eph_bytes));

    let my_sig = FederationFrame::Signature(FederationSignature {
        signature: sig_bytes,
        verifying_key: signing_key_bytes,
        kex_key: kex_key_bytes,
    });
    ws.send(WsMessage::Text(
        serde_json::to_string(&my_sig)
            .map_err(|e| format!("serialize Signature: {}", e))?
            .into(),
    ))
    .await
    .map_err(|e| format!("send Signature: {}", e))?;

    let ready_data = recv_binary_frame(&mut ws).await?;
    let mut dec_cipher = decrypt_cipher;
    let plaintext =
        decrypt_frame(&ready_data, &mut dec_cipher).map_err(|e| format!("decrypt Ready: {}", e))?;
    let ready_text = String::from_utf8(plaintext)
        .map_err(|_| "decrypted Ready is not valid UTF-8".to_string())?;
    let ready_frame: FederationFrame =
        serde_json::from_str(&ready_text).map_err(|e| format!("parse Ready: {}", e))?;
    match ready_frame {
        FederationFrame::Ready(r) => {
            tracing::info!(
                "Federation: server {} ready, status={}",
                r.server_id,
                r.status
            );
        }
        _ => return Err("expected Ready from server".to_string()),
    }

    state.server.with_server(|srv| {
        srv.federation_mark_peer_connected(peer_addr, server_hello.server_id.clone());
    });

    tracing::info!(
        "Federation: encrypted handshake completed with server {} (key={}…) at {}",
        server_hello.server_id,
        &peer_verifying_key_hex[..16],
        peer_addr
    );

    Ok((ws, server_hello.server_id, encrypt_cipher, dec_cipher))
}

async fn run_outbound_connection(
    ws: PeerStream,
    state: SharedState,
    pool: PeerPool,
    peer_addr: String,
    peer_server_id: String,
    mut encrypt_cipher: crate::crypto::aead::SessionCipher,
    mut decrypt_cipher: crate::crypto::aead::SessionCipher,
) {
    let (mut ws_sender, mut ws_receiver) = ws.split();

    let (frame_tx, mut frame_rx) = mpsc::unbounded_channel::<FederationFrame>();
    pool.insert(peer_addr.clone(), peer_server_id.clone(), frame_tx)
        .await;

    let mut gov_rx = state.governance_tx.subscribe();

    let mut heartbeat_interval = tokio::time::interval(Duration::from_secs(30));
    heartbeat_interval.tick().await;

    let mut sync_interval = tokio::time::interval(Duration::from_secs(60));
    sync_interval.tick().await;

    {
        let sync_frames = build_sync_frames(&state).await;
        for f in sync_frames {
            send_encrypted(&mut ws_sender, &f, &mut encrypt_cipher).await;
        }
    }

    {
        let join_frame = state.server.with_server(|srv| {
            srv.membership_self_entry()
                .map(|entry| FederationFrame::MembershipJoinRequest { entry })
        });
        if let Some(frame) = join_frame {
            tracing::info!(
                "Federation: sending membership join request to {}",
                peer_server_id
            );
            send_encrypted(&mut ws_sender, &frame, &mut encrypt_cipher).await;
        }
    }

    loop {
        tokio::select! {
            msg = ws_receiver.next() => {
                match msg {
                    Some(Ok(WsMessage::Binary(data))) => {
                        if data.len() > 64 * 1024 * 1024 {
                            tracing::warn!(
                                "Federation: oversized frame from {} ({} bytes), dropping",
                                peer_server_id,
                                data.len()
                            );
                            continue;
                        }
                        let plaintext = match decrypt_frame(&data, &mut decrypt_cipher) {
                            Ok(p) => p,
                            Err(e) => {
                                tracing::warn!(
                                    "Federation: failed to decrypt frame from {}: {}",
                                    peer_server_id,
                                    e
                                );
                                continue;
                            }
                        };
                        let text = match String::from_utf8(plaintext) {
                            Ok(t) => t,
                            Err(_) => {
                                tracing::warn!(
                                    "Federation: decrypted frame is not valid UTF-8 from {}",
                                    peer_server_id
                                );
                                continue;
                            }
                        };
                        let frame = match serde_json::from_str::<FederationFrame>(&text) {
                            Ok(f) => f,
                            Err(e) => {
                                tracing::warn!(
                                    "Federation: failed to parse frame from {}: {}",
                                    peer_server_id,
                                    e
                                );
                                continue;
                            }
                        };

                        let replies = process_federation_frame(
                            frame,
                            &state,
                            &peer_server_id,
                        ).await;

                        for reply in replies {
                            send_encrypted(&mut ws_sender, &reply, &mut encrypt_cipher).await;
                        }
                    }
                    Some(Ok(WsMessage::Text(_))) => {
                        tracing::warn!(
                            "Federation: received unencrypted text frame after handshake from {}, ignoring",
                            peer_server_id
                        );
                    }
                    Some(Ok(WsMessage::Close(_))) | None => break,
                    Some(Ok(WsMessage::Pong(_))) | Some(Ok(WsMessage::Ping(_))) => {
                        continue;
                    }
                    Some(Ok(_)) => continue,
                    Some(Err(e)) => {
                        tracing::warn!(
                            "Federation: WebSocket error from {}: {}",
                            peer_server_id,
                            e
                        );
                        break;
                    }
                }
            }

            frame = frame_rx.recv() => {
                match frame {
                    Some(f) => {
                        send_encrypted(&mut ws_sender, &f, &mut encrypt_cipher).await;
                    }
                    None => break,
                }
            }

            gov_result = gov_rx.recv() => {
                if let Ok(f) = gov_result {
                    send_encrypted(&mut ws_sender, &f, &mut encrypt_cipher).await;
                }
            }

            _ = heartbeat_interval.tick() => {
                send_encrypted(&mut ws_sender, &FederationFrame::Heartbeat, &mut encrypt_cipher).await;
            }

            _ = sync_interval.tick() => {
                let sync_frames = build_sync_frames(&state).await;
                for f in sync_frames {
                    send_encrypted(&mut ws_sender, &f, &mut encrypt_cipher).await;
                }
            }
        }
    }

    pool.remove(&peer_addr).await;
    state
        .server
        .with_server(|srv| srv.federation_mark_peer_disconnected(&peer_addr));
    tracing::info!(
        "Federation: outbound connection closed with server {}",
        peer_server_id
    );
}

async fn build_sync_frames(state: &SharedState) -> Vec<FederationFrame> {
    let (server_id, sync_pull, members, states, endorsements) = state.server.with_server(|srv| {
        (
            srv.federation_server_id(),
            crate::server::federation::SyncPull {
                server_id: srv.federation_server_id(),
                known_fingerprints: vec![],
                max_entries: crate::server::federation::MAX_SYNC_ENTRIES,
            },
            srv.membership_export_orset().clone(),
            srv.reconcile_export_all(),
            srv.reconcile_export_endorsements(),
        )
    });

    vec![
        FederationFrame::SyncPull(sync_pull),
        FederationFrame::MembershipSyncPush { members },
        FederationFrame::StateSyncPush { states },
        FederationFrame::EndorsementSyncPush { endorsements },
        FederationFrame::CrdtSyncPull {
            server_id,
            work_ids: vec![],
        },
    ]
}

async fn send_encrypted(
    ws_sender: &mut futures_util::stream::SplitSink<PeerStream, WsMessage>,
    frame: &FederationFrame,
    cipher: &mut crate::crypto::aead::SessionCipher,
) {
    let json = match serde_json::to_string(frame) {
        Ok(j) => j,
        Err(e) => {
            tracing::error!("Failed to serialize federation frame: {}", e);
            return;
        }
    };
    let encrypted = encrypt_frame(json.as_bytes(), cipher);
    if encrypted.is_empty() {
        return;
    }
    let _ = ws_sender.send(WsMessage::Binary(encrypted.into())).await;
}

async fn recv_text_frame(ws: &mut PeerStream) -> Result<String, String> {
    while let Some(msg_result) = ws.next().await {
        match msg_result {
            Ok(WsMessage::Text(t)) => return Ok(t.to_string()),
            Ok(WsMessage::Close(_)) => return Err("connection closed during handshake".to_string()),
            Ok(_) => continue,
            Err(e) => return Err(format!("WebSocket error during handshake: {}", e)),
        }
    }
    Err("connection closed during handshake".to_string())
}

async fn recv_binary_frame(ws: &mut PeerStream) -> Result<Vec<u8>, String> {
    while let Some(msg_result) = ws.next().await {
        match msg_result {
            Ok(WsMessage::Binary(b)) => return Ok(b.to_vec()),
            Ok(WsMessage::Close(_)) => return Err("connection closed during handshake".to_string()),
            Ok(_) => continue,
            Err(e) => return Err(format!("WebSocket error: {}", e)),
        }
    }
    Err("connection closed during handshake".to_string())
}

pub async fn spawn_federation_tasks(state: SharedState, pool: PeerPool) {
    let peer_addrs: Vec<String> = state.server.with_server_ref(|srv| {
        srv.federation_peers()
            .iter()
            .map(|p| format!("{}:{}", p.host, p.port))
            .collect()
    });

    for addr in peer_addrs {
        tracing::info!("Federation: spawning dialer for {}", addr);
        let s = state.clone();
        let p = pool.clone();
        tokio::spawn(async move {
            dial_and_maintain(addr, s, p).await;
        });
    }
}
