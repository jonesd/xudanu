use std::net::SocketAddr;
use std::time::Duration;

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
use crate::crypto::keys::hex_encode;

pub(crate) const FEDERATION_PROTOCOL_VERSION: u8 = 1;
pub(crate) const FEDERATION_MIN_COMPAT_VERSION: u8 = 1;
const HANDSHAKE_TIMEOUT_SECS: u64 = 30;

fn default_min_compat() -> u8 {
    1
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FederationHello {
    pub protocol_version: u8,
    #[cfg_attr(feature = "serde", serde(default = "default_min_compat"))]
    pub min_compat_version: u8,
    pub ephemeral_public_key: Vec<u8>,
    pub server_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FederationSignature {
    pub signature: Vec<u8>,
    pub verifying_key: Vec<u8>,
    pub kex_key: Vec<u8>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FederationReady {
    pub server_id: String,
    pub status: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "serde", serde(tag = "type"))]
pub enum FederationFrame {
    Hello(FederationHello),
    Signature(FederationSignature),
    Ready(FederationReady),
    Heartbeat,
    Ack,
    SyncPush(crate::server::federation::SyncPush),
    SyncPull(crate::server::federation::SyncPull),
    SyncResult(crate::server::federation::ContentSyncResult),
    ContentGet {
        work_id: u64,
    },
    ContentResponse {
        found: bool,
        edition_payload: Option<crate::server::transport::protocol::EditionPayload>,
    },
    BlobGet {
        content_hash_hex: String,
    },
    BlobResponse {
        found: bool,
        data: Option<String>,
        mime_type: Option<String>,
    },
    TranscludeQuery {
        content_fingerprint_hex: String,
        direct_only: bool,
    },
    TranscludeResponse {
        results: Vec<crate::server::federation::FederatedTransclusionEntry>,
    },
    ContentFetch {
        content_fingerprint_hex: String,
    },
    ContentFetchResponse {
        found: bool,
        edition_payload: Option<crate::server::transport::protocol::EditionPayload>,
        blob_data: Option<String>,
        blob_mime_type: Option<String>,
    },

    EndorsementSyncPush {
        endorsements: Vec<(
            String,
            crate::server::federation::OrSet<crate::server::federation::EndorsementEntry>,
        )>,
    },
    EndorsementSyncResult {
        endorsements: Vec<(
            String,
            crate::server::federation::OrSet<crate::server::federation::EndorsementEntry>,
        )>,
    },
    StateSyncPush {
        states: Vec<crate::server::federation::ReconcileState>,
    },
    StateSyncResult {
        states: Vec<crate::server::federation::ReconcileState>,
    },

    MembershipJoinRequest {
        entry: crate::server::federation::MembershipEntry,
    },
    MembershipJoinResult {
        result: crate::server::federation::JoinResult,
    },
    MembershipEndorseOffer {
        server_id: String,
        proof: crate::server::federation::EndorsementProof,
    },
    MembershipEndorseResult {
        accepted: bool,
    },
    MembershipSyncPush {
        members: crate::server::federation::OrSet<crate::server::federation::MembershipEntry>,
    },
    MembershipSyncResult {
        members: crate::server::federation::OrSet<crate::server::federation::MembershipEntry>,
    },
    MembershipLeave {
        server_id: String,
    },

    GovernancePrePrepare {
        proposal: crate::server::federation::GovernanceProposal,
    },
    GovernancePrepareVote {
        vote: crate::server::federation::PbftVote,
    },
    GovernanceCommitVote {
        vote: crate::server::federation::PbftVote,
    },
    GovernanceSealed {
        batch: crate::server::federation::SealedBatch,
    },
    GovernanceViewChange {
        message: crate::server::federation::ViewChangeMessage,
    },
    GovernanceNewView {
        new_view: crate::server::federation::NewViewMessage,
    },
    /// FR-75 follow-up (state transfer): a lagging replica requests
    /// the sealed-batch tail from a peer.
    GovernanceLogRequest {
        from_seq: u64,
    },
    GovernanceLogResult {
        /// Sealed batches with sequence ≥ from_seq (bounded to what
        /// the peer still retains — pruned_below cuts the rest).
        batches: Vec<crate::server::federation::SealedBatch>,
        /// The peer's watermark: sequences below this are gone; a
        /// requester still behind it cannot fully catch up.
        pruned_below: u64,
    },

    CrdtSyncPush {
        server_id: String,
        updates: Vec<crate::server::federation::CrdtWorkUpdate>,
    },
    CrdtSyncPull {
        server_id: String,
        work_ids: Vec<crate::edition::BeId>,
    },
    CrdtSyncResult {
        updates: Vec<crate::server::federation::CrdtWorkUpdate>,
    },

    // Phase 3: Federation-PROV Integration frames
    ProvJsonExport {
        work_id: Option<u64>,
        include_federation: bool,
    },
    ProvJsonExportResult {
        prov_json: String,
    },
    FederationProvBundle {
        bundle: crate::edition::provenance::FederationProvenanceBundle,
    },
    FederationAttestationRequest {
        attestation_type: String,
        subject_server_id: String,
    },
    FederationAttestationResponse {
        attestation: Option<crate::edition::provenance::FederationAttestation>,
        accepted: bool,
    },
    ClusterVerificationProv {
        timestamp: u64,
        consensus_type: String,
    },
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

async fn handle_federation_socket(socket: WebSocket, state: SharedState, remote_addr: SocketAddr) {
    // Transport DOS cap (FR follow-up): a single IP flooding
    // federation sockets must not exhaust server resources. The slot
    // is held for the socket's lifetime and released on exit.
    {
        let allowed = state
            .security
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .federation_conn_try_acquire(Some(remote_addr));
        if !allowed {
            tracing::warn!(
                remote = %remote_addr,
                event = "SECURITY:federation_conn_capped",
                "Federation connection refused: per-IP connection cap exceeded"
            );
            return; // drop the socket without a handshake
        }
    }
    let result = handle_federation_socket_inner(socket, state.clone(), remote_addr).await;
    state
        .security
        .lock()
        .unwrap_or_else(|e| e.into_inner())
        .federation_conn_release(Some(remote_addr));
    result
}

async fn handle_federation_socket_inner(
    socket: WebSocket,
    state: SharedState,
    remote_addr: SocketAddr,
) {
    let (mut ws_sender, mut ws_receiver) = socket.split();

    let (my_server_id, my_eph_bytes, my_eph) = state
        .server
        .with_server(|srv| srv.federation_handshake_init());

    let my_hello = FederationHello {
        protocol_version: FEDERATION_PROTOCOL_VERSION,
        min_compat_version: FEDERATION_MIN_COMPAT_VERSION,
        ephemeral_public_key: my_eph_bytes.to_vec(),
        server_id: my_server_id.clone(),
    };

    let hello_json = match serde_json::to_string(&FederationFrame::Hello(my_hello)) {
        Ok(j) => j,
        Err(e) => {
            tracing::error!("Failed to serialize federation Hello: {}", e);
            return;
        }
    };
    if ws_sender
        .send(Message::Text(hello_json.into()))
        .await
        .is_err()
    {
        return;
    }

    let peer_hello = match wait_for_frame_timeout(&mut ws_receiver, HANDSHAKE_TIMEOUT_SECS).await {
        Some(Ok(FederationFrame::Hello(hello))) => hello,
        Some(Ok(other)) => {
            let _ = ws_sender
                .send(Message::Text(
                    format!(
                        "{{\"type\":\"error\",\"message\":\"expected Hello, got {:?}\"}}",
                        other
                    )
                    .into(),
                ))
                .await;
            return;
        }
        Some(Err(e)) => {
            tracing::warn!(
                "Federation handshake timeout or error waiting for Hello from {}: {}",
                remote_addr,
                e
            );
            return;
        }
        None => return,
    };

    let peer_version = peer_hello.protocol_version;
    let peer_min = peer_hello.min_compat_version;
    let my_version = FEDERATION_PROTOCOL_VERSION;
    let my_min = FEDERATION_MIN_COMPAT_VERSION;

    if peer_version < my_min || my_version < peer_min {
        let _ = ws_sender
            .send(Message::Text(
                format!(
                    "{{\"type\":\"error\",\"message\":\"incompatible versions: \
                     peer v{} (min {}), server v{} (min {})\"}}",
                    peer_version, peer_min, my_version, my_min
                )
                .into(),
            ))
            .await;
        return;
    }

    let peer_eph_bytes: [u8; 32] = match peer_hello.ephemeral_public_key.as_slice().try_into() {
        Ok(b) => b,
        Err(_) => return,
    };

    let (sig_bytes, signing_key_bytes, kex_key_bytes) = state
        .server
        .with_server(|srv| srv.federation_sign_handshake(&my_eph_bytes, &peer_eph_bytes));

    let my_sig = FederationSignature {
        signature: sig_bytes,
        verifying_key: signing_key_bytes,
        kex_key: kex_key_bytes,
    };

    let sig_json = match serde_json::to_string(&FederationFrame::Signature(my_sig)) {
        Ok(j) => j,
        Err(e) => {
            tracing::error!("Failed to serialize federation Signature: {}", e);
            return;
        }
    };
    if ws_sender
        .send(Message::Text(sig_json.into()))
        .await
        .is_err()
    {
        return;
    }

    let peer_sig = match wait_for_frame_timeout(&mut ws_receiver, HANDSHAKE_TIMEOUT_SECS).await {
        Some(Ok(FederationFrame::Signature(sig))) => sig,
        Some(Ok(other)) => {
            let _ = ws_sender
                .send(Message::Text(
                    format!(
                        "{{\"type\":\"error\",\"message\":\"expected Signature, got {:?}\"}}",
                        other
                    )
                    .into(),
                ))
                .await;
            return;
        }
        Some(Err(e)) => {
            tracing::warn!(
                "Federation handshake timeout waiting for Signature from {}: {}",
                remote_addr,
                e
            );
            return;
        }
        None => return,
    };

    let peer_verifying_key_bytes: [u8; 32] = match peer_sig.verifying_key.as_slice().try_into() {
        Ok(b) => b,
        Err(_) => return,
    };
    let peer_verifying_key =
        match ed25519_dalek::VerifyingKey::from_bytes(&peer_verifying_key_bytes) {
            Ok(vk) => vk,
            Err(_) => {
                let _ = ws_sender
                    .send(Message::Text(
                        "{\"type\":\"error\",\"message\":\"invalid peer verifying key\"}".into(),
                    ))
                    .await;
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
        let _ = ws_sender
            .send(Message::Text(
                format!(
                    "{{\"type\":\"error\",\"message\":\"handshake signature failed: {}\"}}",
                    e
                )
                .into(),
            ))
            .await;
        return;
    }

    let peer_verifying_key_hex = hex_encode(&peer_verifying_key_bytes);
    let peer_known = state
        .server
        .with_server_ref(|srv| srv.federation_is_peer_known(&peer_verifying_key_hex));

    if !peer_known {
        tracing::warn!(
            "Federation connection rejected from unknown peer {} (key={}) at {}",
            peer_hello.server_id,
            &peer_verifying_key_hex[..16],
            remote_addr
        );
        let _ = ws_sender
            .send(Message::Text(
                format!("{{\"type\":\"error\",\"message\":\"peer not in trusted peers list\"}}")
                    .into(),
            ))
            .await;
        return;
    }

    let peer_server_id = peer_hello.server_id.clone();
    let registry_check = state.server.with_server_ref(|srv| {
        srv.trusted_server_registry().map(|reg| {
            (reg.server_count() > 0).then(|| {
                crate::crypto::server_identity::verify_server_identity(
                    &peer_server_id,
                    &peer_verifying_key_bytes,
                    reg,
                )
            })
        })
    });

    match registry_check {
        Some(Some(Err(e))) => {
            tracing::warn!(
                peer = %peer_server_id,
                key = &peer_verifying_key_hex[..16],
                error = %e,
                event = "SECURITY:federation_identity_mismatch",
                "Federation connection rejected: server_id does not match registry"
            );
            let _ = ws_sender
                .send(Message::Text(
                    format!("{{\"type\":\"error\",\"message\":\"server identity verification failed\"}}")
                        .into(),
                ))
                .await;
            return;
        }
        None => {
            tracing::warn!(
                "Federation: no TrustedServerRegistry configured — server_id binding not enforced"
            );
        }
        Some(Some(Ok(()))) => {
            tracing::info!(
                peer = %peer_server_id,
                "Federation: server identity verified against registry"
            );
        }
        Some(None) => {}
    }

    let peer_kex_bytes: [u8; 32] = match peer_sig.kex_key.as_slice().try_into() {
        Ok(b) => b,
        Err(_) => return,
    };

    let session_keys = state.server.with_server(|srv| {
        srv.federation_derive_session_keys(&peer_kex_bytes, &my_eph, &peer_eph_bytes)
    });

    let mut outbound_cipher = crate::crypto::aead::SessionCipher::new(
        session_keys.outbound,
        0,
        crate::crypto::kdf::DomainLabel::FEDERATION_SERVER_TO_SERVER,
    );
    let mut inbound_cipher = crate::crypto::aead::SessionCipher::new(
        session_keys.inbound,
        0,
        crate::crypto::kdf::DomainLabel::FEDERATION_SERVER_FROM_SERVER,
    );

    let my_server_id_for_sync = state
        .server
        .with_server_ref(|srv| srv.federation_server_id());

    let ready_json = match serde_json::to_string(&FederationFrame::Ready(FederationReady {
        server_id: my_server_id_for_sync.clone(),
        status: "connected".to_string(),
    })) {
        Ok(j) => j,
        Err(e) => {
            tracing::error!("Failed to serialize federation Ready: {}", e);
            return;
        }
    };
    let ready_frame = encrypt_frame(ready_json.as_bytes(), &mut outbound_cipher);
    if ws_sender
        .send(Message::Binary(ready_frame.into()))
        .await
        .is_err()
    {
        return;
    }

    let remote_addr_str = remote_addr.to_string();

    state.server.with_server(|srv| {
        srv.federation_mark_peer_connected(&remote_addr_str, peer_server_id.clone());
    });

    tracing::info!(
        "Federation encrypted handshake completed with server {} (key={}…) from {}",
        peer_server_id,
        &peer_verifying_key_hex[..16],
        remote_addr
    );

    loop {
        tokio::select! {
            msg = ws_receiver.next() => {
                match msg {
                    Some(Ok(Message::Close(_))) | None => break,
                    Some(Ok(Message::Ping(data))) => {
                        let _ = ws_sender.send(Message::Pong(data)).await;
                        continue;
                    }
                    Some(Ok(Message::Binary(data))) => {
                        if data.len() > 64 * 1024 * 1024 {
                            tracing::warn!("Federation: oversized frame from {} ({} bytes), dropping", peer_server_id, data.len());
                            continue;
                        }
                        let plaintext = match decrypt_frame(&data, &mut inbound_cipher) {
                            Ok(p) => p,
                            Err(e) => {
                                tracing::warn!("Federation: failed to decrypt frame from {}: {}", peer_server_id, e);
                                continue;
                            }
                        };
                        let text = match String::from_utf8(plaintext) {
                            Ok(t) => t,
                            Err(_) => {
                                tracing::warn!("Federation: decrypted frame is not valid UTF-8 from {}", peer_server_id);
                                continue;
                            }
                        };
                        match serde_json::from_str::<FederationFrame>(&text) {
                            Ok(FederationFrame::Heartbeat) => {
                                match serde_json::to_string(&FederationFrame::Ack) {
                                    Ok(ack_json) => {
                                        let ack_frame = encrypt_frame(ack_json.as_bytes(), &mut outbound_cipher);
                                        let _ = ws_sender.send(Message::Binary(ack_frame.into())).await;
                                    }
                                    Err(e) => {
                                        tracing::error!("Failed to serialize Ack: {}", e);
                                    }
                                }
                            }
                            Ok(FederationFrame::Ready(r)) => {
                                tracing::info!("Peer ready: {} status={}", r.server_id, r.status);
                            }
                            Ok(FederationFrame::SyncPull(pull)) => {
                                let max = pull.max_entries.min(crate::server::federation::MAX_SYNC_ENTRIES);
                                let push = state.server.with_server(|srv| {
                                    let mut works = srv.federation_export_works();
                                    let mut editions = srv.federation_export_editions();
                                    let mut blobs = srv.federation_export_blobs();
                                    works.truncate(max);
                                    editions.truncate(max.saturating_sub(works.len()));
                                    blobs.truncate(max.saturating_sub(works.len()).saturating_sub(editions.len()));
                                    crate::server::federation::SyncPush {
                                        server_id: srv.federation_server_id(),
                                        works,
                                        editions,
                                        blobs,
                                    }
                                });
                                send_encrypted_frame(&mut ws_sender, &FederationFrame::SyncPush(push), &mut outbound_cipher).await;
                            }
                            Ok(FederationFrame::SyncPush(push)) => {
                                let result = state.server.with_server(|srv| {
                                    let my_id = srv.federation_server_id();
                                    let (works_imported, works_known) = srv.federation_import_works(&push.works, &my_id);
                                    let (blobs_imported, blobs_known) = srv.federation_import_blobs(&push.blobs, &push.server_id);
                                    crate::server::federation::ContentSyncResult {
                                        works_received: works_imported,
                                        editions_received: 0,
                                        blobs_received: blobs_imported,
                                        works_already_known: works_known,
                                        editions_already_known: 0,
                                        blobs_already_known: blobs_known,
                                    }
                                });
                                send_encrypted_frame(&mut ws_sender, &FederationFrame::SyncResult(result), &mut outbound_cipher).await;
                            }
                            Ok(FederationFrame::ContentGet { work_id }) => {
                                let response = state.server.with_server_ref(|srv| {
                                    match srv.federation_get_work_edition(work_id) {
                                        Some(edition_payload) => FederationFrame::ContentResponse {
                                            found: true,
                                            edition_payload: Some(edition_payload),
                                        },
                                        None => FederationFrame::ContentResponse { found: false, edition_payload: None },
                                    }
                                });
                                send_encrypted_frame(&mut ws_sender, &response, &mut outbound_cipher).await;
                            }
                            Ok(FederationFrame::BlobGet { content_hash_hex }) => {
                                let response = state.server.with_server_ref(|srv| {
                                    match srv.federation_get_blob(&content_hash_hex) {
                                        Some((data_b64, mime_type)) => FederationFrame::BlobResponse {
                                            found: true,
                                            data: Some(data_b64),
                                            mime_type: Some(mime_type),
                                        },
                                        None => FederationFrame::BlobResponse { found: false, data: None, mime_type: None },
                                    }
                                });
                                send_encrypted_frame(&mut ws_sender, &response, &mut outbound_cipher).await;
                            }
                            Ok(FederationFrame::TranscludeQuery { content_fingerprint_hex, direct_only }) => {
                                let results = state.server.with_server(|srv| {
                                    srv.federation_query_local_transclusion(&content_fingerprint_hex, direct_only)
                                });
                                send_encrypted_frame(&mut ws_sender, &FederationFrame::TranscludeResponse { results }, &mut outbound_cipher).await;
                            }
                            Ok(FederationFrame::ContentFetch { content_fingerprint_hex }) => {
                                let response = state.server.with_server(|srv| {
                                    match srv.federation_fetch_by_fingerprint(&content_fingerprint_hex) {
                                        super::super::server::FederationFetchResponse::Edition(payload) => {
                                            FederationFrame::ContentFetchResponse {
                                                found: true,
                                                edition_payload: Some(payload),
                                                blob_data: None,
                                                blob_mime_type: None,
                                            }
                                        }
                                        super::super::server::FederationFetchResponse::Blob(data, mime) => {
                                            FederationFrame::ContentFetchResponse {
                                                found: true,
                                                edition_payload: None,
                                                blob_data: Some(data),
                                                blob_mime_type: Some(mime),
                                            }
                                        }
                                        super::super::server::FederationFetchResponse::NotFound => {
                                            FederationFrame::ContentFetchResponse {
                                                found: false,
                                                edition_payload: None,
                                                blob_data: None,
                                                blob_mime_type: None,
                                            }
                                        }
                                    }
                                });
                                send_encrypted_frame(&mut ws_sender, &response, &mut outbound_cipher).await;
                            }
                            Ok(FederationFrame::EndorsementSyncPush { endorsements }) => {
                                state.server.with_server(|srv| {
                                    srv.reconcile_merge_endorsements(&endorsements);
                                });
                                let reply_endorsements = state.server.with_server(|srv| {
                                    srv.reconcile_export_endorsements()
                                });
                                send_encrypted_frame(
                                    &mut ws_sender,
                                    &FederationFrame::EndorsementSyncResult {
                                        endorsements: reply_endorsements,
                                    },
                                    &mut outbound_cipher,
                                ).await;
                            }
                            Ok(FederationFrame::EndorsementSyncResult { endorsements }) => {
                                state.server.with_server(|srv| {
                                    srv.reconcile_merge_endorsements(&endorsements);
                                });
                            }
                            Ok(FederationFrame::StateSyncPush { states }) => {
                                state.server.with_server(|srv| {
                                    for remote_state in &states {
                                        srv.reconcile_merge_remote(remote_state.clone());
                                    }
                                });
                                let reply_states = state.server.with_server(|srv| {
                                    srv.reconcile_export_all()
                                });
                                send_encrypted_frame(
                                    &mut ws_sender,
                                    &FederationFrame::StateSyncResult {
                                        states: reply_states,
                                    },
                                    &mut outbound_cipher,
                                ).await;
                            }
                            Ok(FederationFrame::StateSyncResult { states }) => {
                                state.server.with_server(|srv| {
                                    for remote_state in &states {
                                        srv.reconcile_merge_remote(remote_state.clone());
                                    }
                                });
                            }
                            Ok(FederationFrame::MembershipJoinRequest { entry }) => {
                                let result = state.server.with_server(|srv| {
                                    srv.membership_process_join(entry)
                                });
                                send_encrypted_frame(
                                    &mut ws_sender,
                                    &FederationFrame::MembershipJoinResult { result },
                                    &mut outbound_cipher,
                                ).await;
                            }
                            Ok(FederationFrame::MembershipJoinResult { result }) => {
                                match &result {
                                    crate::server::federation::JoinResult::Accepted { server_id, membership_entry, offered_endorsement } => {
                                        tracing::info!(
                                            "Membership join accepted for server {}",
                                            server_id
                                        );
                                        if let Some(proof) = offered_endorsement {
                                            let endorsee_id = membership_entry.server_id.clone();
                                            let proof_clone = proof.clone();
                                            state.server.with_server(|srv| {
                                                srv.membership_endorse(&endorsee_id, proof_clone);
                                            });
                                        }
                                    }
                                    crate::server::federation::JoinResult::Rejected { server_id, reason } => {
                                        tracing::warn!(
                                            "Membership join rejected for server {}: {}",
                                            server_id, reason
                                        );
                                    }
                                }
                            }
                            Ok(FederationFrame::MembershipEndorseOffer { server_id, proof }) => {
                                let accepted = state.server.with_server(|srv| {
                                    srv.membership_endorse(&server_id, proof)
                                });
                                send_encrypted_frame(
                                    &mut ws_sender,
                                    &FederationFrame::MembershipEndorseResult { accepted },
                                    &mut outbound_cipher,
                                ).await;
                            }
                            Ok(FederationFrame::MembershipEndorseResult { accepted }) => {
                                tracing::info!("Membership endorse result: accepted={}", accepted);
                            }
                            Ok(FederationFrame::MembershipSyncPush { members }) => {
                                state.server.with_server(|srv| {
                                    srv.membership_merge_orset(&members);
                                });
                                let reply_members = state.server.with_server(|srv| {
                                    srv.membership_export_orset().clone()
                                });
                                send_encrypted_frame(
                                    &mut ws_sender,
                                    &FederationFrame::MembershipSyncResult { members: reply_members },
                                    &mut outbound_cipher,
                                ).await;
                            }
                            Ok(FederationFrame::MembershipSyncResult { members }) => {
                                state.server.with_server(|srv| {
                                    srv.membership_merge_orset(&members);
                                });
                            }
                            Ok(FederationFrame::MembershipLeave { server_id }) => {
                                if server_id != peer_server_id {
                                    tracing::warn!(
                                        "MembershipLeave: rejected — claimed {} but authenticated as {}",
                                        server_id, peer_server_id
                                    );
                                } else {
                                    state.server.with_server(|srv| {
                                        srv.membership_remove(&server_id);
                                    });
                                    tracing::info!("Peer {} left federation membership", server_id);
                                }
                            }
                            Ok(frame) if matches!(
                                frame,
                                FederationFrame::GovernancePrePrepare { .. }
                                    | FederationFrame::GovernancePrepareVote { .. }
                                    | FederationFrame::GovernanceCommitVote { .. }
                                    | FederationFrame::GovernanceSealed { .. }
                                    | FederationFrame::GovernanceViewChange { .. }
                                    | FederationFrame::GovernanceNewView { .. }
                                    | FederationFrame::GovernanceLogRequest { .. }
                                    | FederationFrame::GovernanceLogResult { .. }
                            ) => {
                                // Single orchestration point (also used by
                                // the sync path and the test mesh): returns
                                // the frames to broadcast to ALL peers.
                                for out in handle_governance_frame(&frame, &state, &peer_server_id) {
                                    let _ = state.governance_tx.send(out);
                                }
                            }
                            Ok(FederationFrame::CrdtSyncPull { server_id, work_ids }) => {
                                if server_id != peer_server_id {
                                    tracing::warn!(
                                        "CrdtSyncPull: rejected — claimed {} but authenticated as {}",
                                        server_id, peer_server_id
                                    );
                                } else {
                                    let updates = state.server.with_server(|srv| {
                                        srv.federation_crdt_pull(&work_ids)
                                    });
                                    send_encrypted_frame(
                                        &mut ws_sender,
                                        &FederationFrame::CrdtSyncResult { updates },
                                        &mut outbound_cipher,
                                    ).await;
                                }
                            }
                            Ok(FederationFrame::CrdtSyncPush { server_id, updates }) => {
                                if server_id != peer_server_id {
                                    tracing::warn!(
                                        "CrdtSyncPush: rejected — claimed {} but authenticated as {}",
                                        server_id, peer_server_id
                                    );
                                } else {
                                    let result = state.server.with_server(|srv| {
                                        srv.federation_crdt_apply(&updates)
                                    });
                                    tracing::info!(
                                        "CRDT federation: applied {} updates, {} failed from {}",
                                        result.updates_applied, result.updates_failed, peer_server_id
                                    );
                                }
                            }
                            Ok(FederationFrame::CrdtSyncResult { updates }) => {
                                let result = state.server.with_server(|srv| {
                                    srv.federation_crdt_apply(&updates)
                                });
                                tracing::info!(
                                    "CRDT federation sync result: applied {}, failed {}",
                                    result.updates_applied, result.updates_failed
                                );
                            }
                            Ok(FederationFrame::ProvJsonExport { work_id, include_federation }) => {
                                #[cfg(feature = "serde")]
                                {
                                    let result = state.server.with_server(|srv| {
                                        srv.federation_export_prov_json(work_id, include_federation)
                                    });
                                    match result {
                                        Ok(prov_json) => {
                                            send_encrypted_frame(
                                                &mut ws_sender,
                                                &FederationFrame::ProvJsonExportResult { prov_json },
                                                &mut outbound_cipher,
                                            ).await;
                                        }
                                        Err(e) => {
                                            tracing::warn!("Failed to export PROV-JSON: {}", e);
                                            let error_response = FederationFrame::ProvJsonExportResult {
                                                prov_json: format!(r#"{{"error": "{}"}}"#, e),
                                            };
                                            send_encrypted_frame(
                                                &mut ws_sender,
                                                &error_response,
                                                &mut outbound_cipher,
                                            ).await;
                                        }
                                    }
                                }
                                #[cfg(not(feature = "serde"))]
                                {
                                    tracing::warn!("ProvJsonExport requested but serde feature is disabled");
                                    send_encrypted_frame(
                                        &mut ws_sender,
                                        &FederationFrame::ProvJsonExportResult {
                                            prov_json: r#"{"error": "PROV-JSON export requires serde feature"}"#.to_string(),
                                        },
                                        &mut outbound_cipher,
                                    ).await;
                                }
                            }
                            Ok(FederationFrame::FederationProvBundle { bundle }) => {
                                #[cfg(feature = "serde")]
                                {
                                    tracing::info!(
                                        "Received FederationProvBundle from {} with {} server agents, {} verification activities, {} attestations",
                                        peer_server_id,
                                        bundle.server_agents.len(),
                                        bundle.verification_activities.len(),
                                        bundle.attestations.len()
                                    );
                                    let result = state.server.with_server(|srv| {
                                        srv.federation_receive_prov_bundle(bundle)
                                    });
                                    if let Err(e) = result {
                                        tracing::warn!("Failed to process federation PROV bundle: {}", e);
                                    }
                                }
                                #[cfg(not(feature = "serde"))]
                                {
                                    tracing::warn!("FederationProvBundle received but serde feature is disabled");
                                }
                            }
                            Ok(FederationFrame::FederationAttestationRequest { attestation_type, subject_server_id }) => {
                                #[cfg(feature = "serde")]
                                {
                                    tracing::info!(
                                        "Received FederationAttestationRequest from {} for type '{}' on server '{}'",
                                        peer_server_id,
                                        attestation_type,
                                        subject_server_id
                                    );
                                    let result = state.server.with_server(|srv| {
                                        srv.federation_create_attestation_response(attestation_type, subject_server_id, peer_server_id.clone())
                                    });
                                    match result {
                                        Ok(attestation) => {
                                            send_encrypted_frame(
                                                &mut ws_sender,
                                                &FederationFrame::FederationAttestationResponse {
                                                    attestation: Some(attestation),
                                                    accepted: true,
                                                },
                                                &mut outbound_cipher,
                                            ).await;
                                        }
                                        Err(e) => {
                                            tracing::warn!("Failed to create attestation: {}", e);
                                            send_encrypted_frame(
                                                &mut ws_sender,
                                                &FederationFrame::FederationAttestationResponse {
                                                    attestation: None,
                                                    accepted: false,
                                                },
                                                &mut outbound_cipher,
                                            ).await;
                                        }
                                    }
                                }
                                #[cfg(not(feature = "serde"))]
                                {
                                    tracing::warn!("FederationAttestationRequest received but serde feature is disabled");
                                    send_encrypted_frame(
                                        &mut ws_sender,
                                        &FederationFrame::FederationAttestationResponse {
                                            attestation: None,
                                            accepted: false,
                                        },
                                        &mut outbound_cipher,
                                    ).await;
                                }
                            }
                            Ok(FederationFrame::FederationAttestationResponse { attestation, accepted }) => {
                                #[cfg(feature = "serde")]
                                {
                                    if accepted {
                                        if let Some(attestation_data) = attestation {
                                            tracing::info!(
                                                "Received FederationAttestationResponse from {} for attestation type '{}'",
                                                peer_server_id,
                                                attestation_data.attestation_type
                                            );
                                            let result = state.server.with_server(|srv| {
                                                srv.federation_verify_attestation(&attestation_data)
                                            });
                                            if let Err(e) = result {
                                                tracing::warn!("Failed to verify attestation: {}", e);
                                            }
                                        } else {
                                            tracing::info!(
                                                "FederationAttestationRequest rejected by {}",
                                                peer_server_id
                                            );
                                        }
                                    }
                                }
                                #[cfg(not(feature = "serde"))]
                                {
                                    tracing::warn!("FederationAttestationResponse received but serde feature is disabled");
                                }
                            }
                            Ok(FederationFrame::ClusterVerificationProv { timestamp, consensus_type }) => {
                                #[cfg(feature = "serde")]
                                {
                                    tracing::info!(
                                        "Received ClusterVerificationProv from {} timestamp={} consensus_type={}",
                                        peer_server_id,
                                        timestamp,
                                        consensus_type
                                    );
                                    let result = state.server.with_server(|srv| {
                                        srv.federation_record_cluster_verification(timestamp, consensus_type, peer_server_id.clone())
                                    });
                                    if let Err(e) = result {
                                        tracing::warn!("Failed to record cluster verification: {}", e);
                                    }
                                }
                                #[cfg(not(feature = "serde"))]
                                {
                                    tracing::warn!("ClusterVerificationProv received but serde feature is disabled");
                                }
                            }
                            Ok(frame) => {
                                tracing::warn!("Federation: unexpected frame type from {}: {:?}", peer_server_id, frame);
                            }
                            Err(e) => {
                                tracing::warn!("Federation: failed to parse frame from {}: {}", peer_server_id, e);
                            }
                        }
                    }
                    Some(Ok(Message::Text(text))) => {
                        tracing::warn!("Federation: received unencrypted text frame after handshake from {}, ignoring", peer_server_id);
                        let _ = text;
                    }
                    Some(Ok(Message::Pong(_))) => continue,
                    _ => continue,
                }
            }
        }
    }

    state.server.with_server(|srv| {
        srv.federation_mark_peer_disconnected(&remote_addr_str);
    });
    tracing::info!(
        "Federation connection closed with server {}",
        peer_server_id
    );
}

pub(crate) fn encrypt_frame(
    plaintext: &[u8],
    cipher: &mut crate::crypto::aead::SessionCipher,
) -> Vec<u8> {
    match cipher.seal(plaintext, b"xudanu-federation") {
        Ok(envelope) => envelope.encode(),
        Err(e) => {
            tracing::error!("Federation encryption failed: {}", e);
            Vec::new()
        }
    }
}

pub(crate) fn decrypt_frame(
    data: &[u8],
    cipher: &mut crate::crypto::aead::SessionCipher,
) -> Result<Vec<u8>, String> {
    let envelope = crate::crypto::aead::SealedEnvelope::decode(data)
        .map_err(|e| format!("invalid envelope: {}", e))?;
    cipher
        .open(&envelope, b"xudanu-federation")
        .map_err(|e| format!("decryption failed: {}", e))
}

async fn send_encrypted_frame(
    ws_sender: &mut futures_util::stream::SplitSink<WebSocket, Message>,
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
    let _ = ws_sender.send(Message::Binary(encrypted.into())).await;
}

async fn wait_for_frame_timeout(
    ws_receiver: &mut futures_util::stream::SplitStream<WebSocket>,
    timeout_secs: u64,
) -> Option<Result<FederationFrame, String>> {
    match tokio::time::timeout(
        Duration::from_secs(timeout_secs),
        wait_for_frame_inner(ws_receiver),
    )
    .await
    {
        Ok(result) => result,
        Err(_) => Some(Err(format!("handshake timed out after {}s", timeout_secs))),
    }
}

async fn wait_for_frame_inner(
    ws_receiver: &mut futures_util::stream::SplitStream<WebSocket>,
) -> Option<Result<FederationFrame, String>> {
    while let Some(Ok(msg)) = ws_receiver.next().await {
        match msg {
            Message::Text(text) => match serde_json::from_str::<FederationFrame>(&text) {
                Ok(frame) => return Some(Ok(frame)),
                Err(e) => return Some(Err(format!("invalid JSON: {}", e))),
            },
            Message::Close(_) => return None,
            Message::Ping(_) => continue,
            Message::Pong(_) => continue,
            Message::Binary(_) => continue,
        }
    }
    None
}

async fn wait_for_frame(
    ws_receiver: &mut futures_util::stream::SplitStream<WebSocket>,
) -> Option<FederationFrame> {
    wait_for_frame_inner(ws_receiver).await.and_then(|r| r.ok())
}

/// Process one governance frame and return the frames this node must
/// BROADCAST to all peers (votes, sealed batches, NewView). This is
/// the single orchestration point used by the live ws path, the sync
/// path, AND the test mesh — the protocol cascade (pre-prepare →
/// prepare votes → commit votes → sealed) is defined exactly once.
#[allow(clippy::too_many_lines)]
pub(crate) fn handle_governance_frame(
    frame: &FederationFrame,
    state: &SharedState,
    peer_server_id: &str,
) -> Vec<FederationFrame> {
    use crate::server::federation::{PbftPhase, RoundPhase};
    match frame {
        FederationFrame::GovernancePrePrepare { proposal } => {
            tracing::info!(
                "Governance: received pre-prepare from {} view={} seq={}",
                proposal.proposer_id, proposal.view_number, proposal.sequence_number
            );
            // Replica path (L1 fix): validate + create the local round,
            // cast OUR signed prepare vote, broadcast it ALL-TO-ALL.
            match state
                .server
                .with_server(|srv| srv.governance_receive_pre_prepare(proposal))
            {
                Ok(vote) => {
                    let mut out = vec![FederationFrame::GovernancePrepareVote { vote }];
                    // Tiny-quorum clusters can reach Commit from the
                    // own vote alone.
                    if state.server.with_server_ref(|srv| srv.governance_pending_round_phase())
                        == Some(RoundPhase::Commit)
                    {
                        let commit = state.server.with_server(|srv| {
                            let v = srv.governance_make_signed_vote(PbftPhase::Commit, proposal);
                            // Self-count before broadcasting.
                            let _ = srv.governance_receive_commit(v.clone());
                            v
                        });
                        out.push(FederationFrame::GovernanceCommitVote { vote: commit });
                    }
                    out
                }
                Err(reason) => {
                    tracing::warn!(%reason, "Governance: rejected pre-prepare");
                    vec![]
                }
            }
        }
        FederationFrame::GovernancePrepareVote { vote } => {
            if vote.voter_id != peer_server_id {
                tracing::warn!(
                    "Governance: rejected prepare vote from {} claiming to be {}",
                    peer_server_id, vote.voter_id
                );
                return vec![];
            }
            let phase = state
                .server
                .with_server(|srv| srv.governance_receive_prepare(vote.clone()));
            tracing::debug!("Governance: prepare vote processed, phase={:?}", phase);
            // Commit-phase broadcast: whoever crosses prepare-quorum
            // casts its commit vote to all peers (L1 fix).
            if phase == RoundPhase::Commit {
                if let Some(proposal) =
                    state.server.with_server_ref(|srv| srv.governance_pending_round_proposal())
                {
                    let commit = state.server.with_server(|srv| {
                        let v = srv.governance_make_signed_vote(PbftPhase::Commit, &proposal);
                        // Self-count before broadcasting: the emitter's
                        // own round must count its own commit vote (the
                        // mesh caught commits landing everywhere EXCEPT
                        // on their origin node).
                        let _ = srv.governance_receive_commit(v.clone());
                        v
                    });
                    return vec![FederationFrame::GovernanceCommitVote { vote: commit }];
                }
            }
            vec![]
        }
        FederationFrame::GovernanceCommitVote { vote } => {
            if vote.voter_id != peer_server_id {
                tracing::warn!(
                    "Governance: rejected commit vote from {} claiming to be {}",
                    peer_server_id, vote.voter_id
                );
                return vec![];
            }
            let phase = state
                .server
                .with_server(|srv| srv.governance_receive_commit(vote.clone()));
            if phase == RoundPhase::Sealed {
                // Sealed locally with full certificates: execute and
                // broadcast (L2 fix).
                if let Some(batch) = state.server.with_server(|srv| srv.governance_seal_round()) {
                    tracing::info!(
                        "Governance: sealed batch seq={} with {} txs — broadcasting",
                        batch.sequence_number,
                        batch.transactions.len()
                    );
                    return vec![FederationFrame::GovernanceSealed { batch }];
                }
            }
            vec![]
        }
        FederationFrame::GovernanceSealed { batch } => {
            tracing::info!(
                "Governance: received sealed batch seq={} from {}",
                batch.sequence_number, batch.proposer_id
            );
            // Verify certificates, then execute + ingest (S1 fix).
            state
                .server
                .with_server(|srv| srv.governance_ingest_sealed_batch(batch.clone()));
            vec![]
        }
        FederationFrame::GovernanceViewChange { message } => {
            if message.server_id != peer_server_id {
                tracing::warn!(
                    "Governance: view-change from {} claiming to be {}",
                    peer_server_id, message.server_id
                );
                return vec![];
            }
            match state
                .server
                .with_server(|srv| srv.governance_receive_view_change(message))
            {
                Some(new_view) => {
                    tracing::info!(
                        view = new_view.view_number,
                        "Governance: view-change quorum — broadcasting NewView"
                    );
                    vec![FederationFrame::GovernanceNewView { new_view }]
                }
                None => vec![],
            }
        }
        FederationFrame::GovernanceNewView { new_view } => {
            state
                .server
                .with_server(|srv| srv.governance_apply_new_view(new_view));
            vec![]
        }
        FederationFrame::GovernanceLogRequest { from_seq } => {
            // State transfer (replica catch-up): hand over the sealed
            // tail the peer is missing, plus the retention watermark.
            let (batches, pruned_below) = state.server.with_server_ref(|srv| {
                let log = srv.governance_log();
                (
                    log.iter()
                        .filter(|b| b.sequence_number >= *from_seq)
                        .cloned()
                        .collect::<Vec<_>>(),
                    srv.governance_pruned_below(),
                )
            });
            vec![FederationFrame::GovernanceLogResult {
                batches,
                pruned_below,
            }]
        }
        FederationFrame::GovernanceLogResult {
            batches,
            pruned_below,
        } => {
            state.server.with_server(|srv| {
                srv.governance_ingest_log_tail(batches.clone(), *pruned_below);
            });
            vec![]
        }
        _ => vec![],
    }
}

pub(crate) async fn process_federation_frame(
    frame: FederationFrame,
    state: &SharedState,
    peer_server_id: &str,
) -> Vec<FederationFrame> {
    match frame {
        FederationFrame::Hello(_) | FederationFrame::Signature(_) => {
            tracing::warn!("Federation: unexpected handshake frame after completion, ignoring");
            vec![]
        }
        FederationFrame::Heartbeat => vec![FederationFrame::Ack],
        FederationFrame::Ack => vec![],
        FederationFrame::Ready(r) => {
            tracing::info!("Peer ready: {} status={}", r.server_id, r.status);
            vec![]
        }
        FederationFrame::SyncPull(pull) => {
            let max = pull
                .max_entries
                .min(crate::server::federation::MAX_SYNC_ENTRIES);
            let push = state.server.with_server(|srv| {
                let mut works = srv.federation_export_works();
                let mut editions = srv.federation_export_editions();
                let mut blobs = srv.federation_export_blobs();
                works.truncate(max);
                editions.truncate(max.saturating_sub(works.len()));
                blobs.truncate(
                    max.saturating_sub(works.len())
                        .saturating_sub(editions.len()),
                );
                crate::server::federation::SyncPush {
                    server_id: srv.federation_server_id(),
                    works,
                    editions,
                    blobs,
                }
            });
            vec![FederationFrame::SyncPush(push)]
        }
        FederationFrame::SyncPush(push) => {
            let result = state.server.with_server(|srv| {
                let my_id = srv.federation_server_id();
                let (works_imported, works_known) =
                    srv.federation_import_works(&push.works, &my_id);
                let (blobs_imported, blobs_known) =
                    srv.federation_import_blobs(&push.blobs, &push.server_id);
                crate::server::federation::ContentSyncResult {
                    works_received: works_imported,
                    editions_received: 0,
                    blobs_received: blobs_imported,
                    works_already_known: works_known,
                    editions_already_known: 0,
                    blobs_already_known: blobs_known,
                }
            });
            vec![FederationFrame::SyncResult(result)]
        }
        FederationFrame::SyncResult(_result) => vec![],
        FederationFrame::ContentGet { work_id } => {
            let response = state.server.with_server_ref(|srv| {
                match srv.federation_get_work_edition(work_id) {
                    Some(edition_payload) => FederationFrame::ContentResponse {
                        found: true,
                        edition_payload: Some(edition_payload),
                    },
                    None => FederationFrame::ContentResponse {
                        found: false,
                        edition_payload: None,
                    },
                }
            });
            vec![response]
        }
        FederationFrame::ContentResponse { .. } => vec![],
        FederationFrame::BlobGet { content_hash_hex } => {
            let response = state.server.with_server_ref(|srv| {
                match srv.federation_get_blob(&content_hash_hex) {
                    Some((data_b64, mime_type)) => FederationFrame::BlobResponse {
                        found: true,
                        data: Some(data_b64),
                        mime_type: Some(mime_type),
                    },
                    None => FederationFrame::BlobResponse {
                        found: false,
                        data: None,
                        mime_type: None,
                    },
                }
            });
            vec![response]
        }
        FederationFrame::BlobResponse { .. } => vec![],
        FederationFrame::TranscludeQuery {
            content_fingerprint_hex,
            direct_only,
        } => {
            let results = state.server.with_server(|srv| {
                srv.federation_query_local_transclusion(&content_fingerprint_hex, direct_only)
            });
            vec![FederationFrame::TranscludeResponse { results }]
        }
        FederationFrame::TranscludeResponse { .. } => vec![],
        FederationFrame::ContentFetch {
            content_fingerprint_hex,
        } => {
            let response = state.server.with_server(|srv| {
                match srv.federation_fetch_by_fingerprint(&content_fingerprint_hex) {
                    super::super::server::FederationFetchResponse::Edition(payload) => {
                        FederationFrame::ContentFetchResponse {
                            found: true,
                            edition_payload: Some(payload),
                            blob_data: None,
                            blob_mime_type: None,
                        }
                    }
                    super::super::server::FederationFetchResponse::Blob(data, mime) => {
                        FederationFrame::ContentFetchResponse {
                            found: true,
                            edition_payload: None,
                            blob_data: Some(data),
                            blob_mime_type: Some(mime),
                        }
                    }
                    super::super::server::FederationFetchResponse::NotFound => {
                        FederationFrame::ContentFetchResponse {
                            found: false,
                            edition_payload: None,
                            blob_data: None,
                            blob_mime_type: None,
                        }
                    }
                }
            });
            vec![response]
        }
        FederationFrame::ContentFetchResponse { .. } => vec![],
        FederationFrame::EndorsementSyncPush { endorsements } => {
            state.server.with_server(|srv| {
                srv.reconcile_merge_endorsements(&endorsements);
            });
            let reply_endorsements = state
                .server
                .with_server(|srv| srv.reconcile_export_endorsements());
            vec![FederationFrame::EndorsementSyncResult {
                endorsements: reply_endorsements,
            }]
        }
        FederationFrame::EndorsementSyncResult { endorsements } => {
            state.server.with_server(|srv| {
                srv.reconcile_merge_endorsements(&endorsements);
            });
            vec![]
        }
        FederationFrame::StateSyncPush { states } => {
            state.server.with_server(|srv| {
                for remote_state in &states {
                    srv.reconcile_merge_remote(remote_state.clone());
                }
            });
            let reply_states = state.server.with_server(|srv| srv.reconcile_export_all());
            vec![FederationFrame::StateSyncResult {
                states: reply_states,
            }]
        }
        FederationFrame::StateSyncResult { states } => {
            state.server.with_server(|srv| {
                for remote_state in &states {
                    srv.reconcile_merge_remote(remote_state.clone());
                }
            });
            vec![]
        }
        FederationFrame::MembershipJoinRequest { entry } => {
            let result = state
                .server
                .with_server(|srv| srv.membership_process_join(entry));
            vec![FederationFrame::MembershipJoinResult { result }]
        }
        FederationFrame::MembershipJoinResult { result } => {
            match &result {
                crate::server::federation::JoinResult::Accepted {
                    server_id,
                    membership_entry,
                    offered_endorsement,
                } => {
                    tracing::info!("Membership join accepted for server {}", server_id);
                    if let Some(proof) = offered_endorsement {
                        let endorsee_id = membership_entry.server_id.clone();
                        let proof_clone = proof.clone();
                        state
                            .server
                            .with_server(|srv| srv.membership_endorse(&endorsee_id, proof_clone));
                    }
                }
                crate::server::federation::JoinResult::Rejected { server_id, reason } => {
                    tracing::warn!(
                        "Membership join rejected for server {}: {}",
                        server_id,
                        reason
                    );
                }
            }
            vec![]
        }
        FederationFrame::MembershipEndorseOffer { server_id, proof } => {
            let accepted = state
                .server
                .with_server(|srv| srv.membership_endorse(&server_id, proof));
            vec![FederationFrame::MembershipEndorseResult { accepted }]
        }
        FederationFrame::MembershipEndorseResult { accepted } => {
            tracing::info!("Membership endorse result: accepted={}", accepted);
            vec![]
        }
        FederationFrame::MembershipSyncPush { members } => {
            state.server.with_server(|srv| {
                srv.membership_merge_orset(&members);
            });
            let reply_members = state
                .server
                .with_server(|srv| srv.membership_export_orset().clone());
            vec![FederationFrame::MembershipSyncResult {
                members: reply_members,
            }]
        }
        FederationFrame::MembershipSyncResult { members } => {
            state.server.with_server(|srv| {
                srv.membership_merge_orset(&members);
            });
            vec![]
        }
        FederationFrame::MembershipLeave { server_id } => {
            if server_id != peer_server_id {
                tracing::warn!(
                    "MembershipLeave: rejected — claimed {} but authenticated as {}",
                    server_id,
                    peer_server_id
                );
            } else {
                state
                    .server
                    .with_server(|srv| srv.membership_remove(&server_id));
                tracing::info!("Peer {} left federation membership", server_id);
            }
            vec![]
        }
        FederationFrame::GovernancePrePrepare { .. }
        | FederationFrame::GovernancePrepareVote { .. }
        | FederationFrame::GovernanceCommitVote { .. }
        | FederationFrame::GovernanceSealed { .. }
        | FederationFrame::GovernanceViewChange { .. }
        | FederationFrame::GovernanceNewView { .. }
        | FederationFrame::GovernanceLogRequest { .. }
        | FederationFrame::GovernanceLogResult { .. } => {
            // Delegated to the single governance orchestration point
            // (shared with the ws path and the test mesh).
            handle_governance_frame(&frame, state, peer_server_id)
        }
        FederationFrame::CrdtSyncPull {
            server_id,
            work_ids,
        } => {
            if server_id != peer_server_id {
                tracing::warn!(
                    "CrdtSyncPull: rejected — claimed {} but authenticated as {}",
                    server_id,
                    peer_server_id
                );
                vec![]
            } else {
                let updates = state
                    .server
                    .with_server(|srv| srv.federation_crdt_pull(&work_ids));
                vec![FederationFrame::CrdtSyncResult { updates }]
            }
        }
        FederationFrame::CrdtSyncPush { server_id, updates } => {
            if server_id != peer_server_id {
                tracing::warn!(
                    "CrdtSyncPush: rejected — claimed {} but authenticated as {}",
                    server_id,
                    peer_server_id
                );
            } else {
                let result = state
                    .server
                    .with_server(|srv| srv.federation_crdt_apply(&updates));
                tracing::info!(
                    "CRDT federation: applied {} updates, {} failed from {}",
                    result.updates_applied,
                    result.updates_failed,
                    peer_server_id
                );
            }
            vec![]
        }
        FederationFrame::CrdtSyncResult { updates } => {
            let result = state
                .server
                .with_server(|srv| srv.federation_crdt_apply(&updates));
            tracing::info!(
                "CRDT federation sync result: applied {}, failed {}",
                result.updates_applied,
                result.updates_failed
            );
            vec![]
        }

        // Phase 3: Federation-PROV Integration frame handling
        FederationFrame::ProvJsonExport {
            work_id,
            include_federation,
        } => {
            let response = state.server.with_server_ref(|srv| {
                match srv.federation_export_prov_json(work_id, include_federation) {
                    Ok(prov_json) => FederationFrame::ProvJsonExportResult { prov_json },
                    Err(e) => FederationFrame::ProvJsonExportResult {
                        prov_json: format!("Error: {}", e),
                    },
                }
            });
            vec![response]
        }
        FederationFrame::ProvJsonExportResult { .. } => vec![],
        FederationFrame::FederationProvBundle { bundle } => {
            state.server.with_server(|srv| {
                // Handle incoming federation provenance bundle
                tracing::info!(
                    "Received federation provenance bundle: {}",
                    bundle.bundle_id
                );
            });
            vec![]
        }
        FederationFrame::FederationAttestationRequest {
            attestation_type,
            subject_server_id,
        } => {
            let response = state.server.with_server_ref(|srv| {
                match srv.federation_create_attestation_response(
                    attestation_type.clone(),
                    subject_server_id.clone(),
                    peer_server_id.to_string(),
                ) {
                    Ok(attestation) => FederationFrame::FederationAttestationResponse {
                        attestation: Some(attestation),
                        accepted: true,
                    },
                    Err(_) => FederationFrame::FederationAttestationResponse {
                        attestation: None,
                        accepted: false,
                    },
                }
            });
            vec![response]
        }
        FederationFrame::FederationAttestationResponse {
            attestation,
            accepted,
        } => {
            if let Some(attestation) = attestation {
                let verified = state
                    .server
                    .with_server_ref(|srv| srv.federation_verify_attestation(&attestation));
                tracing::info!("Attestation verification result: {:?}", verified);
            }
            vec![]
        }
        FederationFrame::ClusterVerificationProv {
            timestamp,
            consensus_type,
        } => {
            let response = state.server.with_server(|srv| {
                match srv.federation_record_cluster_verification(
                    timestamp,
                    consensus_type.clone(),
                    peer_server_id.to_string(),
                ) {
                    Ok(_) => FederationFrame::ClusterVerificationProv {
                        timestamp,
                        consensus_type: consensus_type.clone(),
                    },
                    Err(e) => FederationFrame::ClusterVerificationProv {
                        timestamp,
                        consensus_type: format!("Error: {}", consensus_type),
                    },
                }
            });
            vec![response]
        }
    }
}
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn federation_frame_hello_roundtrip() {
        let hello = FederationFrame::Hello(FederationHello {
            protocol_version: 1,
            min_compat_version: 1,
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
            verifying_key: vec![2u8; 32],
            kex_key: vec![3u8; 32],
        });
        let json = serde_json::to_string(&sig).unwrap();
        assert!(json.contains("\"type\":\"Signature\""));
        let back: FederationFrame = serde_json::from_str(&json).unwrap();
        match back {
            FederationFrame::Signature(s) => {
                assert_eq!(s.signature.len(), 64);
                assert_eq!(s.verifying_key.len(), 32);
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

    #[test]
    fn encrypt_decrypt_roundtrip() {
        let key = [42u8; 32];
        let mut enc = crate::crypto::aead::SessionCipher::new(
            key,
            0,
            crate::crypto::kdf::DomainLabel::FEDERATION_SERVER_TO_SERVER,
        );
        let mut dec = crate::crypto::aead::SessionCipher::new(
            key,
            0,
            crate::crypto::kdf::DomainLabel::FEDERATION_SERVER_TO_SERVER,
        );

        let plaintext = b"{\"type\":\"Heartbeat\"}";
        let encrypted = encrypt_frame(plaintext, &mut enc);
        assert!(!encrypted.is_empty());
        let decrypted = decrypt_frame(&encrypted, &mut dec).unwrap();
        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn decrypt_rejects_garbage() {
        let key = [42u8; 32];
        let mut dec = crate::crypto::aead::SessionCipher::new(
            key,
            0,
            crate::crypto::kdf::DomainLabel::FEDERATION_SERVER_TO_SERVER,
        );
        assert!(decrypt_frame(&[0u8; 20], &mut dec).is_err());
    }

    #[test]
    fn decrypt_rejects_wrong_key() {
        let key_a = [42u8; 32];
        let key_b = [99u8; 32];
        let mut enc = crate::crypto::aead::SessionCipher::new(
            key_a,
            0,
            crate::crypto::kdf::DomainLabel::FEDERATION_SERVER_TO_SERVER,
        );
        let mut dec = crate::crypto::aead::SessionCipher::new(
            key_b,
            0,
            crate::crypto::kdf::DomainLabel::FEDERATION_SERVER_TO_SERVER,
        );

        let encrypted = encrypt_frame(b"secret", &mut enc);
        assert!(decrypt_frame(&encrypted, &mut dec).is_err());
    }

    #[test]
    fn federation_frame_transclude_query_roundtrip() {
        let frame = FederationFrame::TranscludeQuery {
            content_fingerprint_hex: "ab".repeat(32),
            direct_only: true,
        };
        let json = serde_json::to_string(&frame).unwrap();
        assert!(json.contains("\"type\":\"TranscludeQuery\""));
        let back: FederationFrame = serde_json::from_str(&json).unwrap();
        match back {
            FederationFrame::TranscludeQuery {
                content_fingerprint_hex,
                direct_only,
            } => {
                assert_eq!(content_fingerprint_hex.len(), 64);
                assert!(direct_only);
            }
            _ => panic!("expected TranscludeQuery"),
        }
    }

    #[test]
    fn federation_frame_transclude_response_roundtrip() {
        let frame = FederationFrame::TranscludeResponse {
            results: vec![crate::server::federation::FederatedTransclusionEntry {
                content_fingerprint_hex: "cd".repeat(32),
                origin_server_id: "srv-a".to_string(),
                element_type: crate::server::federation::RemoteElementType::Work,
                local_id: 42,
                is_direct: true,
            }],
        };
        let json = serde_json::to_string(&frame).unwrap();
        assert!(json.contains("\"type\":\"TranscludeResponse\""));
        let back: FederationFrame = serde_json::from_str(&json).unwrap();
        match back {
            FederationFrame::TranscludeResponse { results } => {
                assert_eq!(results.len(), 1);
                assert_eq!(results[0].origin_server_id, "srv-a");
            }
            _ => panic!("expected TranscludeResponse"),
        }
    }

    #[test]
    fn federation_frame_content_fetch_roundtrip() {
        let frame = FederationFrame::ContentFetch {
            content_fingerprint_hex: "ff".repeat(32),
        };
        let json = serde_json::to_string(&frame).unwrap();
        assert!(json.contains("\"type\":\"ContentFetch\""));
        let back: FederationFrame = serde_json::from_str(&json).unwrap();
        match back {
            FederationFrame::ContentFetch {
                content_fingerprint_hex,
            } => {
                assert_eq!(content_fingerprint_hex, "ff".repeat(32));
            }
            _ => panic!("expected ContentFetch"),
        }
    }

    #[test]
    fn federation_frame_content_fetch_response_roundtrip() {
        let frame = FederationFrame::ContentFetchResponse {
            found: false,
            edition_payload: None,
            blob_data: None,
            blob_mime_type: None,
        };
        let json = serde_json::to_string(&frame).unwrap();
        assert!(json.contains("\"type\":\"ContentFetchResponse\""));
        let back: FederationFrame = serde_json::from_str(&json).unwrap();
        match back {
            FederationFrame::ContentFetchResponse { found, .. } => {
                assert!(!found);
            }
            _ => panic!("expected ContentFetchResponse"),
        }
    }

    fn roundtrip(frame: &FederationFrame) -> FederationFrame {
        let json = serde_json::to_string(frame).expect("serialize");
        serde_json::from_str(&json).expect("deserialize")
    }

    fn assert_has_tag(frame: &FederationFrame, tag: &str) {
        let json = serde_json::to_string(frame).expect("serialize");
        assert!(
            json.contains(&format!("\"type\":\"{}\"", tag)),
            "expected tag {}, json was: {}",
            tag,
            json
        );
    }

    #[test]
    fn default_min_compat_is_one() {
        assert_eq!(default_min_compat(), 1);
    }

    #[test]
    fn federation_hello_uses_default_min_compat_when_missing() {
        let json = r#"{"protocol_version":2,"ephemeral_public_key":[1,2,3],"server_id":"x"}"#;
        let hello: FederationHello = serde_json::from_str(json).expect("deserialize");
        assert_eq!(hello.min_compat_version, 1);
        assert_eq!(hello.protocol_version, 2);
        assert_eq!(hello.server_id, "x");
    }

    #[test]
    fn federation_protocol_version_constants() {
        assert_eq!(FEDERATION_PROTOCOL_VERSION, 1);
        assert_eq!(FEDERATION_MIN_COMPAT_VERSION, 1);
        assert!(FEDERATION_MIN_COMPAT_VERSION <= FEDERATION_PROTOCOL_VERSION);
    }

    #[test]
    fn federation_frame_ack_roundtrip() {
        let frame = FederationFrame::Ack;
        assert_has_tag(&frame, "Ack");
        let back = roundtrip(&frame);
        assert!(matches!(back, FederationFrame::Ack));
    }

    #[test]
    fn federation_frame_content_get_roundtrip() {
        let frame = FederationFrame::ContentGet { work_id: 4242 };
        assert_has_tag(&frame, "ContentGet");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::ContentGet { work_id } => assert_eq!(work_id, 4242),
            _ => panic!("expected ContentGet"),
        }
    }

    #[test]
    fn federation_frame_content_response_found_roundtrip() {
        let frame = FederationFrame::ContentResponse {
            found: true,
            edition_payload: Some(crate::server::transport::protocol::EditionPayload::Text(
                "hello".to_string(),
            )),
        };
        assert_has_tag(&frame, "ContentResponse");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::ContentResponse {
                found,
                edition_payload,
            } => {
                assert!(found);
                assert!(matches!(
                    edition_payload,
                    Some(crate::server::transport::protocol::EditionPayload::Text(_))
                ));
            }
            _ => panic!("expected ContentResponse"),
        }
    }

    #[test]
    fn federation_frame_content_response_not_found_roundtrip() {
        let frame = FederationFrame::ContentResponse {
            found: false,
            edition_payload: None,
        };
        let back = roundtrip(&frame);
        match back {
            FederationFrame::ContentResponse { found, .. } => assert!(!found),
            _ => panic!("expected ContentResponse"),
        }
    }

    #[test]
    fn federation_frame_blob_get_roundtrip() {
        let frame = FederationFrame::BlobGet {
            content_hash_hex: "ab".repeat(32),
        };
        assert_has_tag(&frame, "BlobGet");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::BlobGet { content_hash_hex } => {
                assert_eq!(content_hash_hex, "ab".repeat(32))
            }
            _ => panic!("expected BlobGet"),
        }
    }

    #[test]
    fn federation_frame_blob_response_roundtrip() {
        let frame = FederationFrame::BlobResponse {
            found: true,
            data: Some("ZGF0YQ==".to_string()),
            mime_type: Some("text/plain".to_string()),
        };
        assert_has_tag(&frame, "BlobResponse");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::BlobResponse {
                found,
                data,
                mime_type,
            } => {
                assert!(found);
                assert_eq!(data.as_deref(), Some("ZGF0YQ=="));
                assert_eq!(mime_type.as_deref(), Some("text/plain"));
            }
            _ => panic!("expected BlobResponse"),
        }
    }

    #[test]
    fn federation_frame_blob_response_not_found_roundtrip() {
        let frame = FederationFrame::BlobResponse {
            found: false,
            data: None,
            mime_type: None,
        };
        let back = roundtrip(&frame);
        match back {
            FederationFrame::BlobResponse { found, .. } => assert!(!found),
            _ => panic!("expected BlobResponse"),
        }
    }

    #[test]
    fn federation_frame_sync_pull_roundtrip() {
        let frame = FederationFrame::SyncPull(crate::server::federation::SyncPull {
            server_id: "s1".to_string(),
            known_fingerprints: vec!["aa".to_string(), "bb".to_string()],
            max_entries: 500,
        });
        assert_has_tag(&frame, "SyncPull");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::SyncPull(p) => {
                assert_eq!(p.server_id, "s1");
                assert_eq!(p.known_fingerprints.len(), 2);
                assert_eq!(p.max_entries, 500);
            }
            _ => panic!("expected SyncPull"),
        }
    }

    #[test]
    fn federation_frame_sync_push_roundtrip() {
        let frame = FederationFrame::SyncPush(crate::server::federation::SyncPush {
            server_id: "s1".to_string(),
            works: vec![],
            editions: vec![],
            blobs: vec![],
        });
        assert_has_tag(&frame, "SyncPush");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::SyncPush(p) => {
                assert_eq!(p.server_id, "s1");
                assert!(p.works.is_empty());
            }
            _ => panic!("expected SyncPush"),
        }
    }

    #[test]
    fn federation_frame_sync_result_roundtrip() {
        let frame = FederationFrame::SyncResult(crate::server::federation::ContentSyncResult {
            works_received: 1,
            editions_received: 2,
            blobs_received: 3,
            works_already_known: 4,
            editions_already_known: 5,
            blobs_already_known: 6,
        });
        assert_has_tag(&frame, "SyncResult");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::SyncResult(r) => {
                assert_eq!(r.works_received, 1);
                assert_eq!(r.blobs_already_known, 6);
            }
            _ => panic!("expected SyncResult"),
        }
    }

    #[test]
    fn federation_frame_crdt_sync_pull_roundtrip() {
        let frame = FederationFrame::CrdtSyncPull {
            server_id: "s1".to_string(),
            work_ids: vec![1, 2, 3],
        };
        assert_has_tag(&frame, "CrdtSyncPull");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::CrdtSyncPull {
                server_id,
                work_ids,
            } => {
                assert_eq!(server_id, "s1");
                assert_eq!(work_ids, vec![1, 2, 3]);
            }
            _ => panic!("expected CrdtSyncPull"),
        }
    }

    #[test]
    fn federation_frame_crdt_sync_push_roundtrip() {
        let frame = FederationFrame::CrdtSyncPush {
            server_id: "s1".to_string(),
            updates: vec![],
        };
        assert_has_tag(&frame, "CrdtSyncPush");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::CrdtSyncPush { server_id, updates } => {
                assert_eq!(server_id, "s1");
                assert!(updates.is_empty());
            }
            _ => panic!("expected CrdtSyncPush"),
        }
    }

    #[test]
    fn federation_frame_crdt_sync_result_roundtrip() {
        let frame = FederationFrame::CrdtSyncResult { updates: vec![] };
        assert_has_tag(&frame, "CrdtSyncResult");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::CrdtSyncResult { updates } => assert!(updates.is_empty()),
            _ => panic!("expected CrdtSyncResult"),
        }
    }

    #[test]
    fn federation_frame_membership_leave_roundtrip() {
        let frame = FederationFrame::MembershipLeave {
            server_id: "srv-leaving".to_string(),
        };
        assert_has_tag(&frame, "MembershipLeave");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::MembershipLeave { server_id } => {
                assert_eq!(server_id, "srv-leaving")
            }
            _ => panic!("expected MembershipLeave"),
        }
    }

    #[test]
    fn federation_frame_membership_endorse_result_roundtrip() {
        let frame = FederationFrame::MembershipEndorseResult { accepted: true };
        assert_has_tag(&frame, "MembershipEndorseResult");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::MembershipEndorseResult { accepted } => assert!(accepted),
            _ => panic!("expected MembershipEndorseResult"),
        }
    }

    fn sample_endorsement_proof() -> crate::server::federation::EndorsementProof {
        crate::server::federation::EndorsementProof {
            endorser_server_id: "endorser".to_string(),
            endorser_key_id: 7,
            endorsee_server_id: "endorsee".to_string(),
            endorsee_verifying_key_hex: "ff".repeat(32),
            signature: vec![0u8; 64],
            timestamp: 99,
        }
    }

    #[test]
    fn federation_frame_membership_endorse_offer_roundtrip() {
        let frame = FederationFrame::MembershipEndorseOffer {
            server_id: "endorsee".to_string(),
            proof: sample_endorsement_proof(),
        };
        assert_has_tag(&frame, "MembershipEndorseOffer");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::MembershipEndorseOffer { server_id, proof } => {
                assert_eq!(server_id, "endorsee");
                assert_eq!(proof.endorser_server_id, "endorser");
                assert_eq!(proof.endorser_key_id, 7);
            }
            _ => panic!("expected MembershipEndorseOffer"),
        }
    }

    fn sample_membership_entry() -> crate::server::federation::MembershipEntry {
        crate::server::federation::MembershipEntry::new(
            "srv-x",
            "aa".repeat(32),
            "bb".repeat(32),
            vec![sample_endorsement_proof()],
            1234,
        )
    }

    #[test]
    fn federation_frame_membership_join_request_roundtrip() {
        let frame = FederationFrame::MembershipJoinRequest {
            entry: sample_membership_entry(),
        };
        assert_has_tag(&frame, "MembershipJoinRequest");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::MembershipJoinRequest { entry } => {
                assert_eq!(entry.server_id, "srv-x");
                assert_eq!(entry.endorsement_count(), 1);
            }
            _ => panic!("expected MembershipJoinRequest"),
        }
    }

    #[test]
    fn federation_frame_membership_join_result_rejected_roundtrip() {
        let frame = FederationFrame::MembershipJoinResult {
            result: crate::server::federation::JoinResult::Rejected {
                server_id: "srv-y".to_string(),
                reason: "not enough endorsements".to_string(),
            },
        };
        assert_has_tag(&frame, "MembershipJoinResult");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::MembershipJoinResult {
                result: crate::server::federation::JoinResult::Rejected { server_id, reason },
            } => {
                assert_eq!(server_id, "srv-y");
                assert_eq!(reason, "not enough endorsements");
            }
            _ => panic!("expected MembershipJoinResult::Rejected"),
        }
    }

    #[test]
    fn federation_frame_membership_sync_push_roundtrip() {
        let frame = FederationFrame::MembershipSyncPush {
            members: crate::server::federation::OrSet::new(),
        };
        assert_has_tag(&frame, "MembershipSyncPush");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::MembershipSyncPush { .. } => {}
            _ => panic!("expected MembershipSyncPush"),
        }
    }

    #[test]
    fn federation_frame_membership_sync_result_roundtrip() {
        let frame = FederationFrame::MembershipSyncResult {
            members: crate::server::federation::OrSet::new(),
        };
        assert_has_tag(&frame, "MembershipSyncResult");
        let back = roundtrip(&frame);
        assert!(matches!(back, FederationFrame::MembershipSyncResult { .. }));
    }

    #[test]
    fn federation_frame_state_sync_push_roundtrip() {
        let frame = FederationFrame::StateSyncPush { states: vec![] };
        assert_has_tag(&frame, "StateSyncPush");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::StateSyncPush { states } => assert!(states.is_empty()),
            _ => panic!("expected StateSyncPush"),
        }
    }

    #[test]
    fn federation_frame_state_sync_result_roundtrip() {
        let frame = FederationFrame::StateSyncResult { states: vec![] };
        assert_has_tag(&frame, "StateSyncResult");
        let back = roundtrip(&frame);
        assert!(matches!(back, FederationFrame::StateSyncResult { .. }));
    }

    #[test]
    fn federation_frame_endorsement_sync_push_roundtrip() {
        let frame = FederationFrame::EndorsementSyncPush {
            endorsements: vec![],
        };
        assert_has_tag(&frame, "EndorsementSyncPush");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::EndorsementSyncPush { endorsements } => {
                assert!(endorsements.is_empty())
            }
            _ => panic!("expected EndorsementSyncPush"),
        }
    }

    #[test]
    fn federation_frame_endorsement_sync_result_roundtrip() {
        let frame = FederationFrame::EndorsementSyncResult {
            endorsements: vec![],
        };
        assert_has_tag(&frame, "EndorsementSyncResult");
        let back = roundtrip(&frame);
        assert!(matches!(
            back,
            FederationFrame::EndorsementSyncResult { .. }
        ));
    }

    fn sample_proposal() -> crate::server::federation::GovernanceProposal {
        crate::server::federation::GovernanceProposal {
            view_number: 1,
            sequence_number: 2,
            transactions: vec![],
            proposer_id: "proposer-1".to_string(),
            timestamp: 55,
        }
    }

    #[test]
    fn federation_frame_governance_preprepare_roundtrip() {
        let frame = FederationFrame::GovernancePrePrepare {
            proposal: sample_proposal(),
        };
        assert_has_tag(&frame, "GovernancePrePrepare");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::GovernancePrePrepare { proposal } => {
                assert_eq!(proposal.view_number, 1);
                assert_eq!(proposal.sequence_number, 2);
                assert_eq!(proposal.proposer_id, "proposer-1");
            }
            _ => panic!("expected GovernancePrePrepare"),
        }
    }

    fn sample_vote(
        phase: crate::server::federation::PbftPhase,
    ) -> crate::server::federation::PbftVote {
        crate::server::federation::PbftVote {
            view_number: 1,
            sequence_number: 2,
            voter_id: "voter-1".to_string(),
            phase,
            digest: "ab".repeat(32),
            signature: "cd".repeat(64),
        }
    }

    #[test]
    fn federation_frame_governance_prepare_vote_roundtrip() {
        let frame = FederationFrame::GovernancePrepareVote {
            vote: sample_vote(crate::server::federation::PbftPhase::Prepare),
        };
        assert_has_tag(&frame, "GovernancePrepareVote");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::GovernancePrepareVote { vote } => {
                assert_eq!(vote.voter_id, "voter-1");
                assert_eq!(vote.phase, crate::server::federation::PbftPhase::Prepare);
            }
            _ => panic!("expected GovernancePrepareVote"),
        }
    }

    #[test]
    fn federation_frame_governance_commit_vote_roundtrip() {
        let frame = FederationFrame::GovernanceCommitVote {
            vote: sample_vote(crate::server::federation::PbftPhase::Commit),
        };
        assert_has_tag(&frame, "GovernanceCommitVote");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::GovernanceCommitVote { vote } => {
                assert_eq!(vote.phase, crate::server::federation::PbftPhase::Commit)
            }
            _ => panic!("expected GovernanceCommitVote"),
        }
    }

    #[test]
    fn federation_frame_governance_sealed_roundtrip() {
        let frame = FederationFrame::GovernanceSealed {
            batch: crate::server::federation::SealedBatch {
                view_number: 1,
                sequence_number: 2,
                transactions: vec![],
                proposer_id: "proposer-1".to_string(),
                timestamp: 55,
                digest: "ab".repeat(32),
                prepare_votes: vec![sample_vote(crate::server::federation::PbftPhase::Prepare)],
                commit_votes: vec![
                    sample_vote(crate::server::federation::PbftPhase::Commit),
                    sample_vote(crate::server::federation::PbftPhase::Commit),
                ],
            },
        };
        assert_has_tag(&frame, "GovernanceSealed");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::GovernanceSealed { batch } => {
                assert_eq!(batch.sequence_number, 2);
                assert_eq!(batch.commit_votes.len(), 2);
            }
            _ => panic!("expected GovernanceSealed"),
        }
    }

    #[test]
    fn federation_frame_prov_json_export_roundtrip() {
        let frame = FederationFrame::ProvJsonExport {
            work_id: Some(42),
            include_federation: true,
        };
        assert_has_tag(&frame, "ProvJsonExport");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::ProvJsonExport {
                work_id,
                include_federation,
            } => {
                assert_eq!(work_id, Some(42));
                assert!(include_federation);
            }
            _ => panic!("expected ProvJsonExport"),
        }
    }

    #[test]
    fn federation_frame_prov_json_export_result_roundtrip() {
        let frame = FederationFrame::ProvJsonExportResult {
            prov_json: r#"{"bundle":"x"}"#.to_string(),
        };
        assert_has_tag(&frame, "ProvJsonExportResult");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::ProvJsonExportResult { prov_json } => {
                assert_eq!(prov_json, r#"{"bundle":"x"}"#)
            }
            _ => panic!("expected ProvJsonExportResult"),
        }
    }

    #[test]
    fn federation_frame_cluster_verification_prov_roundtrip() {
        let frame = FederationFrame::ClusterVerificationProv {
            timestamp: 1700000000,
            consensus_type: "pbft".to_string(),
        };
        assert_has_tag(&frame, "ClusterVerificationProv");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::ClusterVerificationProv {
                timestamp,
                consensus_type,
            } => {
                assert_eq!(timestamp, 1700000000);
                assert_eq!(consensus_type, "pbft");
            }
            _ => panic!("expected ClusterVerificationProv"),
        }
    }

    #[test]
    fn federation_frame_federation_attestation_request_roundtrip() {
        let frame = FederationFrame::FederationAttestationRequest {
            attestation_type: "membership".to_string(),
            subject_server_id: "srv-subject".to_string(),
        };
        assert_has_tag(&frame, "FederationAttestationRequest");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::FederationAttestationRequest {
                attestation_type,
                subject_server_id,
            } => {
                assert_eq!(attestation_type, "membership");
                assert_eq!(subject_server_id, "srv-subject");
            }
            _ => panic!("expected FederationAttestationRequest"),
        }
    }

    #[test]
    fn federation_frame_federation_attestation_response_roundtrip() {
        let frame = FederationFrame::FederationAttestationResponse {
            attestation: None,
            accepted: false,
        };
        assert_has_tag(&frame, "FederationAttestationResponse");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::FederationAttestationResponse { accepted, .. } => {
                assert!(!accepted)
            }
            _ => panic!("expected FederationAttestationResponse"),
        }
    }

    #[test]
    fn federation_frame_federation_prov_bundle_roundtrip() {
        use crate::edition::provenance::{FederationMetadata, FederationProvenanceBundle};
        let frame = FederationFrame::FederationProvBundle {
            bundle: FederationProvenanceBundle {
                bundle_id: "bundle-1".to_string(),
                timestamp: 7,
                federation_metadata: FederationMetadata::new(
                    "srv-1".to_string(),
                    "example.com".to_string(),
                    3,
                    "closed".to_string(),
                    2,
                    "active".to_string(),
                ),
                server_agents: vec![],
                verification_activities: vec![],
                attestations: vec![],
                cross_server_signatures: vec![],
            },
        };
        assert_has_tag(&frame, "FederationProvBundle");
        let back = roundtrip(&frame);
        match back {
            FederationFrame::FederationProvBundle { bundle } => {
                assert_eq!(bundle.bundle_id, "bundle-1");
                assert_eq!(bundle.federation_metadata.server_id, "srv-1");
            }
            _ => panic!("expected FederationProvBundle"),
        }
    }

    #[test]
    fn federation_frame_rejects_unknown_type_tag() {
        let json = r#"{"type":"DefinitelyNotARealFrame"}"#;
        assert!(serde_json::from_str::<FederationFrame>(json).is_err());
    }

    fn fresh_state() -> super::super::shared::SharedState {
        use crate::server::transport::shared::AppState;
        use crate::server::Server;
        AppState::new(Server::new()).shared()
    }

    // ── Governance mesh harness ─────────────────────────────────────
    //
    // An in-process N-node "network" driving the REAL protocol code:
    // every hop goes through handle_governance_frame — the same
    // orchestration the live ws loop uses. Partitions, crashes, and
    // view-change ticks are mesh controls; time is forced via
    // governance_force_stall_for_tests so stalls are deterministic.

    mod governance_mesh {
        use super::super::super::federation_handler::FederationFrame;
        use super::super::handle_governance_frame;
        use crate::server::transport::shared::AppState;
        use crate::server::Server;
        use crate::server::transport::shared::SharedState;

        const TIMEOUT: u64 = 600;

        struct Node {
            id: String,
            state: SharedState,
        }

        struct Mesh {
            nodes: Vec<Node>,
            /// FR-75 §4: per-member offline recovery keys, registered at
            /// Admit.
            recovery_keys: std::collections::HashMap<String, ed25519_dalek::SigningKey>,
            /// Directed delivery blocks (a, a): a's frames never reach b.
            blocked: std::collections::HashSet<(usize, usize)>,
            /// Dead nodes neither send nor receive.
            dead: std::collections::HashSet<usize>,
            /// Fuzz mode: seeded delivery-order shuffling (every message
            /// still arrives — reordering, not loss — exercising the
            /// buffering paths exactly where the mesh found real bugs).
            shuffle_seed: Option<u64>,
        }

        impl Mesh {
            fn new(n: usize) -> Mesh {
                let mut states: Vec<SharedState> = (0..n)
                    .map(|_| {
                        let mut srv = Server::new();
                        let config = crate::server::federation::FederationConfig::closed(vec![]);
                        srv.set_federation_config(config);
                        srv.membership_bootstrap_init();
                        AppState::new(srv).shared()
                    })
                    .collect();
                // Collect self entries first (id + verifying key).
                let entries: Vec<(String, String)> = states
                    .iter()
                    .map(|st| {
                        let e = st
                            .server
                            .with_server_ref(|srv| srv.membership_self_entry().unwrap());
                        (e.server_id, e.verifying_key_hex)
                    })
                    .collect();
                // FR-75 §4: offline recovery keys per member.
                let recovery_keys: std::collections::HashMap<String, ed25519_dalek::SigningKey> =
                    entries
                        .iter()
                        .enumerate()
                        .map(|(i, (id, _))| {
                            let mut seed = [0u8; 32];
                            seed[0] = 0xA0 + i as u8;
                            (id.clone(), ed25519_dalek::SigningKey::from_bytes(&seed))
                        })
                        .collect();
                // Cross-register membership: every node admits every
                // other (with their recovery keys).
                for state in &states {
                    for (id, vk) in &entries {
                        let rk = recovery_keys[id]
                            .verifying_key()
                            .to_bytes()
                            .iter()
                            .map(|b| format!("{b:02x}"))
                            .collect::<String>();
                        state.server.with_server(|srv| {
                            srv.governance_execute_tx(
                                &crate::server::federation::GovernanceTx::Admit {
                                    server_id: id.clone(),
                                    verifying_key_hex: vk.clone(),
                                    kex_public_hex: "00".to_string(),
                                    recovery_key_hex: rk,
                                },
                            );
                        });
                    }
                }
                let nodes = states
                    .into_iter()
                    .zip(&entries)
                    .map(|(state, (id, _))| Node { id: id.clone(), state })
                    .collect();
                Mesh {
                    nodes,
                    recovery_keys,
                    blocked: std::collections::HashSet::new(),
                    dead: std::collections::HashSet::new(),
                    shuffle_seed: None,
                }
            }

            /// Enable seeded delivery-order fuzzing.
            fn with_shuffle_seed(mut self, seed: u64) -> Self {
                self.shuffle_seed = Some(seed);
                self
            }

            /// Build a valid FR-75 §4 Path-A authorization for rotating
            /// `server_id` to `new_vk` (current key + recovery key).
            fn operator_authorization(
                &self,
                server_id: &str,
                new_vk: &str,
            ) -> crate::server::federation::KeyRegisterAuthorization {
                use ed25519_dalek::Signer;
                let payload = crate::server::federation::KeyRegisterAuthorization::payload_for(
                    server_id, new_vk,
                );
                let node = self.nodes.iter().find(|n| n.id == server_id).unwrap();
                let current_sig = node
                    .state
                    .server
                    .with_server_ref(|srv| srv.server_signing_key_test())
                    .sign(payload.as_bytes())
                    .to_bytes()
                    .iter()
                    .map(|b| format!("{b:02x}"))
                    .collect::<String>();
                let recovery_sig = self.recovery_keys[server_id]
                    .sign(payload.as_bytes())
                    .to_bytes()
                    .iter()
                    .map(|b| format!("{b:02x}"))
                    .collect::<String>();
                crate::server::federation::KeyRegisterAuthorization::Operator {
                    current_signature: current_sig,
                    recovery_signature: recovery_sig,
                }
            }

            /// Index of the leader for the given view — computed over
            /// the LIVE (epoch-valid) voting pool at the next sequence,
            /// sorted by server_id. Matches governance_propose exactly.
            fn leader_for_view(&self, view: u64) -> usize {
                let pool: Vec<String> = self.nodes[0]
                    .state
                    .server
                    .with_server_ref(|srv| {
                        let seq = srv.governance_current_sequence() + 1;
                        srv.governance_validator_members_at(seq)
                            .into_iter()
                            .map(|m| m.server_id)
                            .collect()
                    });
                let mut ids = pool;
                ids.sort();
                let leader_id = ids[(view as usize) % ids.len()].clone();
                self.nodes.iter().position(|n| n.id == leader_id).unwrap()
            }

            fn log_len(&self, i: usize) -> usize {
                self.nodes[i]
                    .state
                    .server
                    .with_server_ref(|srv| srv.governance_log().len())
            }

            fn current_view(&self, i: usize) -> u64 {
                self.nodes[i]
                    .state
                    .server
                    .with_server_ref(|srv| srv.governance_current_view())
            }

            fn seal_digests(&self, i: usize) -> Vec<String> {
                self.nodes[i]
                    .state
                    .server
                    .with_server_ref(|srv| {
                        srv.governance_log().iter().map(|b| b.digest.clone()).collect()
                    })
            }

            fn deliver_from(&mut self, from: usize, frame: &FederationFrame, depth: usize) {
                assert!(depth < 24, "protocol cascade exceeded depth cap");
                let mut targets: Vec<usize> = (0..self.nodes.len()).collect();
                if let Some(seed) = self.shuffle_seed {
                    // Deterministic per-(seed, depth, from) shuffle:
                    // every recipient still gets the frame, in a
                    // randomized order.
                    use rand::seq::SliceRandom;
                    use rand::SeedableRng;
                    let mut rng = rand::rngs::StdRng::seed_from_u64(
                        seed ^ ((depth as u64) << 32) ^ (from as u64),
                    );
                    targets.shuffle(&mut rng);
                }
                for to in targets {
                    if to == from
                        || self.dead.contains(&from)
                        || self.dead.contains(&to)
                        || self.blocked.contains(&(from, to))
                        || self.blocked.contains(&(to, from))
                    {
                        continue;
                    }
                    let peer_id = self.nodes[from].id.clone();
                    let outs =
                        handle_governance_frame(frame, &self.nodes[to].state, &peer_id);
                    for out in outs {
                        self.deliver_from(to, &out, depth + 1);
                    }
                }
            }

            /// The leader proposes and the pre-prepare fans out (with
            /// `reach` limiting delivery — a crashing leader that only
            /// reached some replicas).
            fn propose_from(&mut self, leader: usize, reach: Option<Vec<usize>>) {
                let txs = vec![crate::server::federation::GovernanceTx::RoyaltyRecord {
                    origin_server_id: self.nodes[leader].id.clone(),
                    target_server_id: self.nodes[leader].id.clone(),
                    content_fingerprint_hex: "ab".repeat(32),
                    royalty_type: crate::server::federation::RoyaltyType::Transclusion,
                    amount: 1,
                }];
                let frame = self.nodes[leader]
                    .state
                    .server
                    .with_server(|srv| srv.governance_propose(txs))
                    .map(|proposal| FederationFrame::GovernancePrePrepare { proposal })
                    .expect("leader proposes");
                match reach {
                    Some(targets) => {
                        for to in targets {
                            let peer_id = self.nodes[leader].id.clone();
                            let outs = handle_governance_frame(
                                &frame,
                                &self.nodes[to].state,
                                &peer_id,
                            );
                            for out in outs {
                                self.deliver_from(to, &out, 1);
                            }
                        }
                    }
                    None => self.deliver_from(leader, &frame, 0),
                }
            }

            /// One view-change poll for every alive node — mirrors
            /// federation_active exactly: make the signed message,
            /// count it LOCALLY, deliver to peers, and broadcast any
            /// assembled NewView.
            fn tick_stalls(&mut self) {
                for i in 0..self.nodes.len() {
                    if self.dead.contains(&i) {
                        continue;
                    }
                    let outcome = self.nodes[i].state.server.with_server(|srv| {
                        srv.governance_force_stall_for_tests();
                        if srv.governance_view_change_due(TIMEOUT) {
                            let msg = srv.governance_make_view_change(TIMEOUT);
                            let new_view = srv.governance_receive_view_change(&msg);
                            Some((msg, new_view))
                        } else {
                            None
                        }
                    });
                    if let Some((msg, new_view)) = outcome {
                        self.deliver_from(
                            i,
                            &FederationFrame::GovernanceViewChange { message: msg },
                            0,
                        );
                        if let Some(nv) = new_view {
                            self.deliver_from(
                                i,
                                &FederationFrame::GovernanceNewView { new_view: nv },
                                0,
                            );
                        }
                    }
                }
            }
        }

        fn assert_all_agree(mesh: &Mesh, expected_len: usize) {
            let mut digests: Option<Vec<String>> = None;
            for i in 0..mesh.nodes.len() {
                assert_eq!(mesh.log_len(i), expected_len, "node {i} log length");
                let d = mesh.seal_digests(i);
                if let Some(prev) = &digests {
                    assert_eq!(&d, prev, "node {i} sealed different digests — FORK");
                } else {
                    digests = Some(d);
                }
            }
        }

        #[test]
        fn mesh_four_node_happy_path_cascades_to_seal() {
            let mut mesh = Mesh::new(4);
            let leader = mesh.leader_for_view(0);
            eprintln!("DBG leader={leader} ids={:?}",
                mesh.nodes.iter().map(|n| n.id.clone()).collect::<Vec<_>>());
            mesh.propose_from(leader, None);
            for i in 0..4 {
                let (phase, prep, comm, cluster) = mesh.nodes[i].state.server.with_server_ref(|srv| {
                    let r = srv.governance_pending_round();
                    (format!("{:?}", r.map(|x| x.phase)),
                     r.map(|x| x.prepare_votes.len()).unwrap_or(0),
                     r.map(|x| x.commit_votes.len()).unwrap_or(0),
                     srv.governance_cluster_size())
                });
                eprintln!("DBG node {i}: phase={phase} prepares={prep} commits={comm} cluster={cluster} log={}", mesh.log_len(i));
            }
            assert_all_agree(&mesh, 1);
            for i in 0..4 {
                assert_eq!(mesh.current_view(i), 0);
            }
        }

        #[test]
        fn mesh_leader_crash_mid_round_recovers_via_view_change() {
            let mut mesh = Mesh::new(4);
            let leader = mesh.leader_for_view(0);
            // The leader reaches only ONE replica (2 of quorum 3),
            // then crashes — the round stalls without quorum.
            let others: Vec<usize> = (0..4).filter(|i| *i != leader).collect();
            mesh.propose_from(leader, Some(vec![others[0]]));
            mesh.dead.insert(leader);

            // Both reached replicas now hold stalled rounds (no quorum).
            // Ticking drives: view-change(v1) → quorum → NewView → all
            // enter view 1. The round never reached prepare-quorum, so
            // it is correctly DISCARDED (unprepared requests are lost —
            // the client retries with the new leader, as in PBFT).
            for _ in 0..6 {
                mesh.tick_stalls();
            }
            // Every ALIVE node advanced to view 1 (the dead leader
            // obviously cannot).
            for i in 0..4 {
                if mesh.dead.contains(&i) {
                    continue;
                }
                assert_eq!(
                    mesh.current_view(i),
                    1,
                    "alive node {i} must have advanced to view 1"
                );
            }

            // Client retry with the SAME value (a view change
            // re-proposes prepared values; a different value at a
            // prepared sequence is refused). The digest covers only
            // (seq, transactions), so this re-proposal carries the
            // original digest.
            let new_leader = mesh.leader_for_view(1);
            assert!(!mesh.dead.contains(&new_leader), "view-1 leader must be alive");
            let original_txs = vec![crate::server::federation::GovernanceTx::RoyaltyRecord {
                origin_server_id: mesh.nodes[mesh
                    .dead
                    .iter()
                    .copied()
                    .next()
                    .unwrap()]
                    .id
                    .clone(),
                target_server_id: mesh.nodes[mesh
                    .dead
                    .iter()
                    .copied()
                    .next()
                    .unwrap()]
                    .id
                    .clone(),
                content_fingerprint_hex: "ab".repeat(32),
                royalty_type: crate::server::federation::RoyaltyType::Transclusion,
                amount: 1,
            }];
            let frame = mesh.nodes[new_leader]
                .state
                .server
                .with_server(|srv| srv.governance_propose(original_txs))
                .map(|proposal| FederationFrame::GovernancePrePrepare { proposal })
                .expect("retry re-proposes the prepared value");
            mesh.deliver_from(new_leader, &frame, 0);
            for i in 0..4 {
                if mesh.dead.contains(&i) {
                    continue;
                }
                assert_eq!(mesh.log_len(i), 1, "alive node {i} sealed the retry");
                assert_eq!(mesh.current_view(i), 1);
            }
            let digests: Vec<Vec<String>> = (0..4)
                .filter(|i| !mesh.dead.contains(i))
                .map(|i| mesh.seal_digests(i))
                .collect();
            assert!(
                digests.windows(2).all(|w| w[0] == w[1]),
                "alive nodes sealed identical digests — no fork"
            );
        }

        #[test]
        fn mesh_byzantine_leader_forged_seal_rejected_everywhere() {
            let mut mesh = Mesh::new(4);
            let leader = mesh.leader_for_view(0);
            mesh.propose_from(leader, None);
            assert_all_agree(&mesh, 1);

            // The (now byzantine) leader replays the seal with
            // hijacked transactions and the SAME certificates.
            let real = mesh.nodes[leader]
                .state
                .server
                .with_server_ref(|srv| srv.governance_log()[0].clone());
            let mut forged = real.clone();
            forged.transactions = vec![crate::server::federation::GovernanceTx::Expel {
                server_id: "hijacked".to_string(),
                reason: "forged".to_string(),
            }];
            mesh.deliver_from(leader, &FederationFrame::GovernanceSealed { batch: forged }, 0);
            assert_all_agree(&mesh, 1);
        }

        #[test]
        fn mesh_conflicting_reproposal_at_sealed_seq_rejected() {
            let mut mesh = Mesh::new(4);
            let leader = mesh.leader_for_view(0);
            mesh.propose_from(leader, None);
            assert_all_agree(&mesh, 1);

            // A conflicting proposal at the SEALED sequence: the next
            // expected seq is 2, so a forged pre-prepare at seq 1 with
            // different content must be refused by every replica.
            let mut conflicting = crate::server::federation::GovernanceProposal {
                view_number: 0,
                sequence_number: 1,
                transactions: vec![crate::server::federation::GovernanceTx::Expel {
                    server_id: "conflicting".to_string(),
                    reason: "fork attempt".to_string(),
                }],
                proposer_id: mesh.nodes[leader].id.clone(),
                timestamp: 42,
            };
            mesh.deliver_from(
                leader,
                &FederationFrame::GovernancePrePrepare { proposal: conflicting },
                0,
            );
            assert_all_agree(&mesh, 1);
        }

        #[test]
        fn newview_forgery_variants_rejected() {
            let mut mesh = Mesh::new(4);
            let leader = mesh.leader_for_view(0);
            mesh.propose_from(leader, Some(vec![])); // leader's own round only
            mesh.dead.insert(leader);

            // Collect three REAL signed view-changes from the followers.
            let others: Vec<usize> = (0..4).filter(|i| *i != leader).collect();
            let vcs: Vec<_> = others
                .iter()
                .map(|i| {
                    mesh.nodes[*i].state.server.with_server(|srv| {
                        srv.governance_force_stall_for_tests();
                        srv.governance_make_view_change(TIMEOUT)
                    })
                })
                .collect();
            let target = mesh.nodes[others[0]]
                .state
                .server
                .with_server_ref(|srv| srv.governance_current_view())
                + 1;
            let new_leader = mesh.leader_for_view(target);

            // The real NewView: assembled by the correct leader, signed.
            let real_nv = mesh.nodes[new_leader].state.server.with_server(|srv| {
                let mut assembled = None;
                for vc in &vcs {
                    if let Some(nv) = srv.governance_receive_view_change(vc) {
                        assembled = Some(nv);
                    }
                }
                assembled.expect("quorum assembles")
            });
            // The new leader (already at view 1 via self-apply)
            // re-applies the pristine NewView idempotently.
            mesh.nodes[new_leader]
                .state
                .server
                .with_server(|srv| srv.governance_apply_new_view(&real_nv));
            assert_eq!(mesh.current_view(new_leader), target, "pristine NewView applies");

            // One clean victim suffices — rejections never advance the
            // view, so it serves all three variants.
            let victim = others
                .iter()
                .copied()
                .find(|i| *i != new_leader && mesh.current_view(*i) == 0)
                .expect("at least one node remains at view 0");

            // Variant A: wrong assembler (a non-leader member id).
            let mut a = real_nv.clone();
            a.assembler_id = mesh.nodes[victim].id.clone();
            a.signature = String::new();
            mesh.nodes[victim]
                .state
                .server
                .with_server(|srv| srv.governance_apply_new_view(&a));
            assert_eq!(mesh.current_view(victim), 0, "wrong assembler rejected");

            // Variant B: cross-view certificates (certs say v+2 inside a
            // v+1 announcement).
            let mut b = real_nv.clone();
            for vc in b.view_changes.iter_mut() {
                vc.new_view = target + 1;
                vc.signature = String::new(); // sigs now invalid too
            }
            mesh.nodes[victim]
                .state
                .server
                .with_server(|srv| srv.governance_apply_new_view(&b));
            assert_eq!(mesh.current_view(victim), 0, "cross-view certs rejected");

            // Variant C: insufficient certificates (only 1 of 3).
            let mut c = real_nv.clone();
            c.view_changes.truncate(1);
            mesh.nodes[victim]
                .state
                .server
                .with_server(|srv| srv.governance_apply_new_view(&c));
            assert_eq!(mesh.current_view(victim), 0, "insufficient certs rejected");
        }

        /// FR-75 §3 (test matrix #4): membership sync cannot smuggle
        /// validator keys. A sync frame carrying a new member or a key
        /// change is sanitized; governance Admit remains the only door.
        #[test]
        fn mesh_membership_sync_cannot_smuggle_validator_keys() {
            let mut mesh = Mesh::new(4);
            let leader = mesh.leader_for_view(0);
            mesh.propose_from(leader, None);
            // 4 validators — the round sealed.
            for i in 0..4 {
                assert_eq!(
                    mesh.nodes[i]
                        .state
                        .server
                        .with_server_ref(|srv| srv.governance_validator_members().len()),
                    4
                );
            }

            // A hostile MembershipSync arrives at node 0: a new member
            // plus a hijacked key for node 1.
            let hostile_entry_new = {
                let mut e = mesh.nodes[1]
                    .state
                    .server
                    .with_server_ref(|srv| srv.membership_self_entry().unwrap());
                e.server_id = format!("{}-evil", e.server_id);
                e.verifying_key_hex = "ff".repeat(32);
                e.admitted_by_governance = true; // the smuggled flag!
                e
            };
            let hostile_key_change = {
                let mut e = mesh.nodes[1]
                    .state
                    .server
                    .with_server_ref(|srv| srv.membership_self_entry().unwrap());
                e.verifying_key_hex = "ee".repeat(32);
                e
            };
            let mut hostile = crate::server::federation::OrSet::new();
            hostile.add(
                hostile_entry_new,
                crate::server::federation::OrSetTag::new("evil-node", 1),
            );
            hostile.add(
                hostile_key_change,
                crate::server::federation::OrSetTag::new("evil-node", 2),
            );
            mesh.nodes[0].state.server.with_server(|srv| {
                srv.membership_merge_orset(&hostile);
            });

            // Validator set unchanged; keys unchanged; no fifth validator.
            let node1_id = mesh.nodes[1].id.clone();
            let node1_real_vk = mesh.nodes[1]
                .state
                .server
                .with_server_ref(|srv| srv.membership_self_entry().unwrap())
                .verifying_key_hex;
            let (validators, stored_vk, has_evil) =
                mesh.nodes[0].state.server.with_server_ref(|srv| {
                    (
                        srv.governance_validator_members().len(),
                        srv.find_member_public(&node1_id)
                            .map(|m| m.verifying_key_hex)
                            .unwrap_or_default(),
                        srv.membership_list()
                            .iter()
                            .any(|m| m.server_id.ends_with("-evil")),
                    )
                });
            assert_eq!(validators, 4, "no smuggled validator");
            assert!(!has_evil, "evil member entry dropped from sync");
            assert_eq!(
                stored_vk, node1_real_vk,
                "hijacked key sanitized back to the governed key"
            );
        }

        /// FR-75 test 1: a member whose key epoch ended before the
        /// round's sequence cannot vote; the round completes with the
        /// remaining pool (quorum still 3 — expired members count
        /// toward f like crashed members).
        #[test]
        fn mesh_expired_member_cannot_vote_round_completes() {
            let mut mesh = Mesh::new(4);
            // Expire a member FIRST — the sorted voting pool (and thus
            // the leader) is a function of the epoch state.
            let old_leader = mesh.leader_for_view(0);
            let victim = (0..4).find(|i| *i != old_leader).unwrap();

            // The victim's key expired before sequence 1 — set on
            // EVERY node's membership (in production, epochs change
            // via sealed KeyRegister batches executed everywhere).
            let expired = crate::server::federation::KeyEpoch {
                valid_from_seq: 1,
                valid_until_seq: 1, // covers nothing at seq 1
            };
            let victim_id = mesh.nodes[victim].id.clone();
            for node in &mesh.nodes {
                node.state
                    .server
                    .with_server(|srv| srv.membership_set_epoch_for_tests(&victim_id, expired.clone()));
            }
            // Recompute the leader over the LIVE voting pool.
            let leader = mesh.leader_for_view(0);

            mesh.propose_from(leader, None);
            // Everyone converges — the expired member never seals
            // locally but INGESTS the consensus decision (it follows
            // governance; it just cannot vote).
            for i in 0..4 {
                assert_eq!(mesh.log_len(i), 1, "node {i} applied the sealed batch");
            }
            let digests: Vec<Vec<String>> = (0..4).map(|i| mesh.seal_digests(i)).collect();
            assert!(
                digests.windows(2).all(|w| w[0] == w[1]),
                "no fork — expired member agrees with the validators"
            );
            // The honest invariant: the victim's vote appears in NO
            // certificate of the sealed batch.
            let victim_id = mesh.nodes[victim].id.clone();
            let voted = mesh.nodes[leader].state.server.with_server_ref(|srv| {
                let batch = &srv.governance_log()[0];
                batch.prepare_votes.iter().chain(batch.commit_votes.iter())
                    .any(|v| v.voter_id == victim_id)
            });
            assert!(!voted, "expired member's vote appears in no certificate");
        }

        /// FR-75 test 7: with the expired member still admitted, quorum
        /// stays 3 and the pool of 3 must be unanimous; with TWO
        /// expiries the pool (2) drops below quorum (3) and governance
        /// halts safely — no round opens, no fork.
        #[test]
        fn mesh_double_expiry_halts_safely() {
            let mut mesh = Mesh::new(4);
            let leader = mesh.leader_for_view(0);
            let others: Vec<usize> = (0..4).filter(|i| *i != leader).collect();

            // Expire two members — on every node's membership.
            let expired = crate::server::federation::KeyEpoch {
                valid_from_seq: 1,
                valid_until_seq: 1,
            };
            for v in &others[..2] {
                let id = mesh.nodes[*v].id.clone();
                for node in &mesh.nodes {
                    node.state.server.with_server(|srv| {
                        srv.membership_set_epoch_for_tests(&id, expired.clone())
                    });
                }
            }

            // The leader's own propose is refused: pool 2 < quorum 3.
            let result = mesh.nodes[leader].state.server.with_server(|srv| {
                srv.governance_propose(vec![crate::server::federation::GovernanceTx::RoyaltyRecord {
                    origin_server_id: String::new(),
                    target_server_id: String::new(),
                    content_fingerprint_hex: "ab".repeat(32),
                    royalty_type: crate::server::federation::RoyaltyType::Transclusion,
                    amount: 1,
                }])
            });
            assert!(result.is_none(), "governance halted: no round may open");
            for i in 0..4 {
                assert_eq!(mesh.log_len(i), 0, "nothing sealed — halted, not forked");
            }
        }

        /// FR-75 test 2: after a KeyRegister rotation seals, the old key
        /// can never vote again (prepare/commit refused everywhere);
        /// membership carries the new key from the next round.
        #[test]
        fn mesh_rotation_kills_old_key_for_votes() {
            let mut mesh = Mesh::new(4);
            let leader = mesh.leader_for_view(0);
            mesh.propose_from(leader, None);

            // Rotate a non-leader member's key on every node (in
            // production: a sealed KeyRegister batch, executed
            // everywhere).
            let victim = (0..4).find(|i| *i != leader).unwrap();
            let victim_id = mesh.nodes[victim].id.clone();
            let new_key = {
                let mut seed = [0u8; 32];
                seed[0] = 0x5a;
                ed25519_dalek::SigningKey::from_bytes(&seed)
            };
            let new_vk: String = new_key
                .verifying_key()
                .to_bytes()
                .iter()
                .map(|b| format!("{b:02x}"))
                .collect();
            let authorization = mesh.operator_authorization(&victim_id, &new_vk);
            for node in &mesh.nodes {
                node.state.server.with_server(|srv| {
                    srv.governance_execute_tx_at(
                        &crate::server::federation::GovernanceTx::KeyRegister {
                            server_id: victim_id.clone(),
                            key_id: 0,
                            verifying_key_hex: new_vk.clone(),
                            kex_public_hex: "00".to_string(),
                authorization: authorization.clone(),
                        },
                        1,
                    );
                });
            }

            // Membership carries the NEW key for rounds after seq 1.
            let keys = mesh.nodes[leader]
                .state
                .server
                .with_server_ref(|srv| srv.governance_member_keys_at(2));
            assert_eq!(
                keys.get(&victim_id).map(|s| s.as_str()),
                Some(new_vk.as_str()),
                "membership carries the rotated key"
            );

            // A vote signed by the victim's (unchanged, now-retired)
            // SERVER key is refused at the leader.
            let old_key = mesh.nodes[victim]
                .state
                .server
                .with_server_ref(|srv| srv.server_signing_key_test());
            let mut old_vote = crate::server::federation::PbftVote {
                view_number: 0,
                sequence_number: 2,
                voter_id: victim_id.clone(),
                phase: crate::server::federation::PbftPhase::Prepare,
                digest: "ab".repeat(32),
                signature: String::new(),
            };
            crate::server::federation::sign_vote(&mut old_vote, &old_key);
            let old_vote_sent = old_vote.clone();
            let phase = mesh.nodes[leader]
                .state
                .server
                .with_server(move |srv| srv.governance_receive_prepare(old_vote_sent));
            assert_eq!(
                format!("{phase:?}"),
                "PrePrepare",
                "retired key's prepare vote refused"
            );

            // The NEW key's vote verifies against membership.
            let mut new_vote = old_vote;
            new_vote.signature = String::new();
            crate::server::federation::sign_vote(&mut new_vote, &new_key);
            assert!(
                crate::server::federation::verify_vote_signature(&new_vote, &new_vk),
                "rotated key's vote verifies"
            );
        }

        /// FR-75 test 3: a view-change signed under the OLD key
        /// verifies within the grace window and fails beyond it.
        #[test]
        fn view_change_grace_window_for_retired_keys() {
            let mut mesh = Mesh::new(4);
            let leader = mesh.leader_for_view(0);
            mesh.propose_from(leader, None);

            let victim = (0..4).find(|i| *i != leader).unwrap();
            let victim_id = mesh.nodes[victim].id.clone();
            let new_vk = "cd".repeat(32);
            let authorization = mesh.operator_authorization(&victim_id, &new_vk);
            for node in &mesh.nodes {
                node.state.server.with_server(|srv| {
                    srv.governance_execute_tx_at(
                        &crate::server::federation::GovernanceTx::KeyRegister {
                            server_id: victim_id.clone(),
                            key_id: 0,
                            verifying_key_hex: new_vk.to_string(),
                            kex_public_hex: "00".to_string(),
                authorization: authorization.clone(),
                        },
                        1,
                    );
                });
            }

            // Within grace (current seq 1, retired at 1): the victim's
            // OLD key authenticates a view-change at any OTHER node.
            // The vc is signed with the SERVER key (the old key — the
            // server keypair never changed) and claims the victim id.
            let vc = mesh.nodes[victim]
                .state
                .server
                .with_server(|srv| srv.governance_make_view_change(600));
            let accepted = mesh.nodes[leader].state.server.with_server_ref(|srv| {
                let seq = srv.governance_current_sequence();
                match srv.retired_key_lookup_for_test(&vc.server_id, seq) {
                    Some(key) => {
                        crate::server::federation::verify_hex_sig(&key, &vc.payload(), &vc.signature)
                    }
                    None => false,
                }
            });
            assert!(accepted, "old key authenticates within grace");

            // Beyond grace: retired_at 1, current_sequence 200 →
            // 200 - 1 > 100 → refused.
            mesh.nodes[leader]
                .state
                .server
                .with_server(|srv| srv.governance_set_current_sequence_for_tests(200));
            let refused = mesh.nodes[leader].state.server.with_server_ref(|srv| {
                let seq = srv.governance_current_sequence();
                srv.retired_key_lookup_for_test(&vc.server_id, seq).is_none()
            });
            assert!(refused, "old key refused beyond grace");
        }

        /// FR-75 test 5: rotation authority — the current key alone
        /// never suffices. Unproven rotation refused in multi-server
        /// mode; operator (current+recovery) accepted; social
        /// recovery (quorum of others) accepted; recovery key WITHOUT
        /// the current key refused.
        #[test]
        fn rotation_authority_matrix() {
            let mut mesh = Mesh::new(4);
            let leader = mesh.leader_for_view(0);
            mesh.propose_from(leader, None);
            let victim = (0..4).find(|i| *i != leader).unwrap();
            let victim_id = mesh.nodes[victim].id.clone();
            let new_vk = "ab".repeat(32);

            let rotate = |mesh: &Mesh, auth: crate::server::federation::KeyRegisterAuthorization, vk: &str| {
                let mut any_changed = false;
                for node in &mesh.nodes {
                    let changed = node.state.server.with_server(|srv| {
                        let before = srv.find_member_public(&victim_id)
                            .map(|m| m.verifying_key_hex).unwrap_or_default();
                        srv.governance_execute_tx_at(
                            &crate::server::federation::GovernanceTx::KeyRegister {
                                server_id: victim_id.clone(),
                                key_id: 0,
                                verifying_key_hex: vk.to_string(),
                                kex_public_hex: "00".to_string(),
                                authorization: auth.clone(),
                            },
                            1,
                        );
                        let after = srv.find_member_public(&victim_id)
                            .map(|m| m.verifying_key_hex).unwrap_or_default();
                        after != before
                    });
                    any_changed = any_changed || changed;
                }
                any_changed
            };

            // 1. Unproven rotation refused (multi-server).
            assert!(
                !rotate(&mesh, crate::server::federation::KeyRegisterAuthorization::None, &new_vk),
                "no authorization — refused"
            );

            // 2. Recovery key alone (attacker holds the offline key but
            // not the current key): current_signature invalid.
            use ed25519_dalek::Signer;
            let payload = crate::server::federation::KeyRegisterAuthorization::payload_for(
                &victim_id, &new_vk,
            );
            let forged = {
                let wrong_current = {
                    let mut seed = [0u8; 32];
                    seed[0] = 0x99;
                    let k = ed25519_dalek::SigningKey::from_bytes(&seed);
                    crate::server::federation::vote_hex_sig(&k, &payload)
                };
                let real_recovery = crate::server::federation::vote_hex_sig(
                    &mesh.recovery_keys[&victim_id], &payload,
                );
                crate::server::federation::KeyRegisterAuthorization::Operator {
                    current_signature: wrong_current,
                    recovery_signature: real_recovery,
                }
            };
            assert!(!rotate(&mesh, forged, &new_vk), "recovery alone — refused");

            // 3. Operator path (current + recovery) accepted.
            let valid = mesh.operator_authorization(&victim_id, &new_vk);
            assert!(rotate(&mesh, valid, &new_vk), "operator authorization — accepted");

            // Rotate BACK via social recovery (quorum of others), so
            // path B is also exercised: sign with 3 other members.
            let final_vk = "ef".repeat(32);
            let payload_b = crate::server::federation::KeyRegisterAuthorization::payload_for(
                &victim_id, &final_vk,
            );
            let authorizations: Vec<_> = mesh
                .nodes
                .iter()
                .filter(|n| n.id != victim_id)
                .take(3)
                .map(|n| crate::server::federation::MemberSignature {
                    member_id: n.id.clone(),
                    signature: crate::server::federation::vote_hex_sig(
                        &n.state.server.with_server_ref(|srv| srv.server_signing_key_test()),
                        &payload_b,
                    ),
                })
                .collect();
            let social = crate::server::federation::KeyRegisterAuthorization::Social { authorizations };
            assert!(rotate(&mesh, social, &final_vk), "social recovery — accepted");
        }

        /// FR-75 test 6: a thief holding ONLY the current key can
        /// neither rotate nor survive epoch expiry — locked out.
        #[test]
        fn stolen_current_key_cannot_take_over() {
            let mut mesh = Mesh::new(4);
            let leader = mesh.leader_for_view(0);
            mesh.propose_from(leader, None);
            let victim = (0..4).find(|i| *i != leader).unwrap();
            let victim_id = mesh.nodes[victim].id.clone();

            // The thief possesses the current key (the server signing
            // key) but NOT the recovery key. Every rotation they craft
            // fails the operator path; None fails outright; social
            // recovery needs a quorum of honest others they lack.
            let thief_vk = "99".repeat(32);
            let payload = crate::server::federation::KeyRegisterAuthorization::payload_for(
                &victim_id, &thief_vk,
            );
            let thief_sig = mesh.nodes[victim]
                .state
                .server
                .with_server_ref(|srv| {
                    crate::server::federation::vote_hex_sig(&srv.server_signing_key_test(), &payload)
                });
            let garbage_recovery = "00".repeat(64);
            let attempt = crate::server::federation::KeyRegisterAuthorization::Operator {
                current_signature: thief_sig,
                recovery_signature: garbage_recovery,
            };
            for node in &mesh.nodes {
                node.state.server.with_server(|srv| {
                    srv.governance_execute_tx_at(
                        &crate::server::federation::GovernanceTx::KeyRegister {
                            server_id: victim_id.clone(),
                            key_id: 0,
                            verifying_key_hex: thief_vk.clone(),
                            kex_public_hex: "00".to_string(),
                            authorization: attempt.clone(),
                        },
                        1,
                    );
                });
            }
            let vk_now = mesh.nodes[leader]
                .state
                .server
                .with_server_ref(|srv| srv.find_member_public(&victim_id).unwrap().verifying_key_hex);
            assert_ne!(vk_now, thief_vk, "thief's key never registered");

            // And when the stolen key's epoch ends, its votes die
            // (step-2 semantics): locked out at expiry.
            let expired = crate::server::federation::KeyEpoch {
                valid_from_seq: 1,
                valid_until_seq: 1,
            };
            for node in &mesh.nodes {
                node.state.server.with_server(|srv| {
                    srv.membership_set_epoch_for_tests(&victim_id, expired.clone())
                });
            }
            let mut thief_vote = crate::server::federation::PbftVote {
                view_number: 0,
                sequence_number: 2,
                voter_id: victim_id.clone(),
                phase: crate::server::federation::PbftPhase::Prepare,
                digest: "ab".repeat(32),
                signature: String::new(),
            };
            let k = mesh.nodes[victim]
                .state
                .server
                .with_server_ref(|srv| srv.server_signing_key_test());
            crate::server::federation::sign_vote(&mut thief_vote, &k);
            let phase = mesh.nodes[leader]
                .state
                .server
                .with_server(|srv| srv.governance_receive_prepare(thief_vote));
            assert_eq!(format!("{phase:?}"), "PrePrepare", "expired stolen key cannot vote");
        }

        /// Randomized delivery-order fuzz: 25 seeds, every message
        /// delivered but in shuffled order. Properties: (liveness) the
        /// round ALWAYS seals on every node; (safety) every node
        /// seals the identical digest — no fork under reordering.
        /// This is the ordering class that hid three real bugs
        /// (early-prepare loss, commit self-count, assembler
        /// self-apply); shuttle-style thread randomization doesn't
        /// apply to the single-threaded event mesh — event-order
        /// randomization is the correct tool here.
        #[test]
        fn randomized_delivery_order_fuzz() {
            for seed in 0..25u64 {
                let mut mesh = Mesh::new(4).with_shuffle_seed(seed);
                let leader = mesh.leader_for_view(0);
                mesh.propose_from(leader, None);
                let digests: Vec<Vec<String>> =
                    (0..4).map(|i| mesh.seal_digests(i)).collect();
                assert_eq!(
                    digests[0].len(),
                    1,
                    "seed {seed}: round sealed everywhere"
                );
                assert!(
                    digests.windows(2).all(|w| w[0] == w[1]),
                    "seed {seed}: NO FORK — identical digests under reordering"
                );
                for i in 0..4 {
                    assert_eq!(mesh.log_len(i), 1, "seed {seed}: node {i} sealed");
                }
            }
        }

        /// FR-75 follow-up (state transfer): a replica that missed
        /// sealed batches catches up via GovernanceLogRequest/Result —
        /// certificates verified, executed in order, and a pruned-
        /// past gap is detected and refused loudly.
        #[test]
        fn state_transfer_catches_up_lagging_replica() {
            let mut mesh = Mesh::new(4);
            let leader = mesh.leader_for_view(0);

            // A fresh replica with the same membership but NO history.
            let replica = {
                let mut srv = crate::server::Server::new();
                let config = crate::server::federation::FederationConfig::closed(vec![]);
                srv.set_federation_config(config);
                srv.membership_bootstrap_init();
                crate::server::transport::shared::AppState::new(srv).shared()
            };
            // Register the same validator membership on the replica
            // (it would arrive via join + governance in production).
            for node in &mesh.nodes {
                let e = node
                    .state
                    .server
                    .with_server_ref(|srv| srv.membership_self_entry().unwrap());
                let recovery = mesh.recovery_keys[&e.server_id]
                    .verifying_key()
                    .to_bytes()
                    .iter()
                    .map(|b| format!("{b:02x}"))
                    .collect::<String>();
                replica.server.with_server(|srv| {
                    srv.governance_execute_tx(
                        &crate::server::federation::GovernanceTx::Admit {
                            server_id: e.server_id.clone(),
                            verifying_key_hex: e.verifying_key_hex.clone(),
                            kex_public_hex: "00".to_string(),
                            recovery_key_hex: recovery,
                        },
                    );
                });
            }

            // Seal two rounds on the mesh.
            mesh.propose_from(leader, None);
            mesh.propose_from(leader, None);
            for i in 0..4 {
                assert_eq!(mesh.log_len(i), 2, "mesh sealed two rounds");
            }

            // The replica requests everything from sequence 1.
            let replies = {
                let peer_id = "replica".to_string();
                handle_governance_frame(
                    &FederationFrame::GovernanceLogRequest { from_seq: 1 },
                    &mesh.nodes[leader].state,
                    &peer_id,
                )
            };
            assert_eq!(replies.len(), 1, "one log result");
            match &replies[0] {
                FederationFrame::GovernanceLogResult {
                    batches,
                    pruned_below,
                } => {
                    assert_eq!(batches.len(), 2, "full tail returned");
                    assert_eq!(*pruned_below, 0, "nothing pruned yet");
                }
                other => panic!("expected log result, got {other:?}"),
            }

            // Deliver to the replica: catches up (certificates
            // verified against its identical validator membership).
            let peer_id = mesh.nodes[leader].id.clone();
            for reply in replies {
                let _ = handle_governance_frame(&reply, &replica, &peer_id);
            }
            let caught_up = replica
                .server
                .with_server_ref(|srv| (srv.governance_log().len(), srv.governance_current_sequence()));
            assert_eq!(caught_up, (2, 2), "replica caught up in order");

            // Same digests as the mesh — no fork via transfer.
            let mesh_digests = mesh.seal_digests(leader);
            let replica_digests: Vec<String> = replica
                .server
                .with_server_ref(|srv| srv.governance_log().iter().map(|b| b.digest.clone()).collect());
            assert_eq!(mesh_digests, replica_digests);

            // Gap refusal: a peer pruned past our position returns a
            // loud no-op instead of a partial history.
            let pruned_past = FederationFrame::GovernanceLogResult {
                batches: vec![],
                pruned_below: 50,
            };
            replica.server.with_server(|srv| {
                srv.governance_ingest_log_tail(vec![], 50);
            });
            let still = replica
                .server
                .with_server_ref(|srv| srv.governance_log().len());
            assert_eq!(still, 2, "gap refused — history unchanged");
            let _ = pruned_past;
        }

        /// FR-75 follow-up: the lifecycle snapshot is the alerting
        /// surface — margin drops to zero with one expiry at n=4 and
        /// negative (halted) with two.
        #[test]
        fn lifecycle_snapshot_tracks_margin_and_expiry() {
            let mut mesh = Mesh::new(4);
            let leader = mesh.leader_for_view(0);
            let snap = mesh.nodes[leader]
                .state
                .server
                .with_server_ref(|srv| srv.governance_lifecycle_snapshot());
            assert_eq!(snap.validators, 4);
            assert_eq!(snap.pool, 4);
            assert_eq!(snap.quorum, 3);
            assert_eq!(snap.margin, 1, "healthy n=4: one loss tolerable");
            assert!(snap.expired_members.is_empty());

            // One expiry: pool 3, quorum 3 → margin 0 (zero fault
            // tolerance — the operational canary).
            let victim = (0..4).find(|i| *i != leader).unwrap();
            let expired = crate::server::federation::KeyEpoch {
                valid_from_seq: 1,
                valid_until_seq: 1,
            };
            let victim_id = mesh.nodes[victim].id.clone();
            for node in &mesh.nodes {
                node.state.server.with_server(|srv| {
                    srv.membership_set_epoch_for_tests(&victim_id, expired.clone())
                });
            }
            let snap = mesh.nodes[leader]
                .state
                .server
                .with_server_ref(|srv| srv.governance_lifecycle_snapshot());
            assert_eq!(snap.pool, 3);
            assert_eq!(snap.quorum, 3, "expired member still counts toward n/f");
            assert_eq!(snap.margin, 0);
            assert_eq!(snap.expired_members, vec![victim_id.clone()]);

            // Expiring-soon detection: an epoch ending within the
            // warning window surfaces BEFORE it bites.
            let other = (0..4)
                .find(|i| *i != leader && *i != victim)
                .unwrap();
            let soon = crate::server::federation::KeyEpoch {
                valid_from_seq: 1,
                valid_until_seq: 900, // within 1000 of next seq 1
            };
            let other_id = mesh.nodes[other].id.clone();
            for node in &mesh.nodes {
                node.state.server.with_server(|srv| {
                    srv.membership_set_epoch_for_tests(&other_id, soon.clone())
                });
            }
            let snap = mesh.nodes[leader]
                .state
                .server
                .with_server_ref(|srv| srv.governance_lifecycle_snapshot());
            assert!(
                snap.expiring_soon.iter().any(|(id, _)| *id == other_id),
                "expiring member surfaces for rotation"
            );
        }

        /// FR-75 follow-up: genesis pinning — strict peer admission
        /// (only pinned keys pass) and bootstrap seeding of the pinned
        /// set with recovery keys.
        #[test]
        fn genesis_pining_restricts_peers_and_seeds_membership() {
            use crate::server::transport::shared::AppState;
            use crate::server::Server;

            let make_key = |seed: u8| {
                let mut s = [0u8; 32];
                s[0] = seed;
                ed25519_dalek::SigningKey::from_bytes(&s)
            };
            let a = make_key(1);
            let b = make_key(2);
            let vk = |k: &ed25519_dalek::SigningKey| -> String {
                k.verifying_key()
                    .to_bytes()
                    .iter()
                    .map(|x| format!("{x:02x}"))
                    .collect()
            };

            // A pinned config with two members.
            let config = crate::server::federation::FederationConfig::pinned(
                vec![],
                vec![
                    crate::server::federation::PinnedMember {
                        server_id: "srv-a".to_string(),
                        verifying_key_hex: vk(&a),
                        recovery_key_hex: "aa".repeat(32),
                    },
                    crate::server::federation::PinnedMember {
                        server_id: "srv-b".to_string(),
                        verifying_key_hex: vk(&b),
                        recovery_key_hex: "bb".repeat(32),
                    },
                ],
            );
            let mut server = Server::new();
            server.set_federation_config(config);

            // Strict admission: pinned keys pass, anything else fails
            // (even if the accumulated registry would have accepted it).
            let state = AppState::new(server).shared();
            assert!(state.server.with_server_ref(|srv| srv.federation_is_peer_known(&vk(&a))));
            assert!(state.server.with_server_ref(|srv| srv.federation_is_peer_known(&vk(&b))));
            let stranger = vk(&make_key(0xEE));
            assert!(
                !state.server.with_server_ref(|srv| srv.federation_is_peer_known(&stranger)),
                "unpinned key refused under genesis pinning"
            );

            // Bootstrap seeds the pinned members (with recovery keys,
            // governance-admitted) alongside self.
            state.server.with_server(|srv| {
                srv.membership_bootstrap_init();
            });
            let (a_entry, b_entry) = state.server.with_server_ref(|srv| {
                (
                    srv.find_member_public("srv-a"),
                    srv.find_member_public("srv-b"),
                )
            });
            let a_entry = a_entry.expect("pinned member seeded");
            let b_entry = b_entry.expect("pinned member seeded");
            assert!(a_entry.admitted_by_governance, "pinned members are validators");
            assert_eq!(a_entry.recovery_key_hex, "aa".repeat(32));
            assert_eq!(b_entry.recovery_key_hex, "bb".repeat(32));
        }

        /// FR-75 test 8: epoch decisions are functions of (sequence)
        /// alone — no wall clock participates. Two states with entries
        /// created at different times agree on pool membership per
        /// sequence, and expiry bites purely by sequence arithmetic.
        #[test]
        fn key_epoch_decisions_are_sequence_pure() {
            let e = crate::server::federation::KeyEpoch {
                valid_from_seq: 2,
                valid_until_seq: 5,
            };
            assert!(!e.covers(1), "before valid_from");
            assert!(e.covers(2), "inclusive lower bound");
            assert!(e.covers(4));
            assert!(!e.covers(5), "exclusive upper bound");
            assert!(e.admitted_by(7), "expired members remain admitted (count toward f)");
            // The default (migration) epoch never expires.
            assert!(crate::server::federation::KeyEpoch::default().covers(u64::MAX - 1));
        }

        #[test]
        fn view_change_escalation_targets_advance_only_when_stale() {
            let mut gov = crate::server::federation::GovernanceState::new(4);
            assert_eq!(gov.next_view(0, 100), 1, "fresh state targets view 1");
            gov.note_view_change_emission(1);
            assert_eq!(
                gov.next_view(0, 100),
                1,
                "collecting for view 1 while fresh — same target"
            );
            assert_eq!(
                gov.next_with_stale_started(),
                2,
                "stale collection escalates to view 2"
            );
        }

        impl crate::server::federation::GovernanceState {
            #[doc(hidden)]
            fn next_with_stale_started(&self) -> u64 {
                let now = std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_secs();
                self.next_view(now, 0) // timeout 0 = instantly stale
            }
        }
    }

    #[tokio::test]
    async fn process_heartbeat_returns_ack() {
        let state = fresh_state();
        let replies = process_federation_frame(FederationFrame::Heartbeat, &state, "peer").await;
        assert_eq!(replies.len(), 1);
        assert!(matches!(replies[0], FederationFrame::Ack));
    }

    #[tokio::test]
    async fn process_ack_returns_no_replies() {
        let state = fresh_state();
        let replies = process_federation_frame(FederationFrame::Ack, &state, "peer").await;
        assert!(replies.is_empty());
    }

    #[tokio::test]
    async fn process_hello_after_handshake_ignored() {
        let state = fresh_state();
        let hello = FederationFrame::Hello(FederationHello {
            protocol_version: 1,
            min_compat_version: 1,
            ephemeral_public_key: vec![0u8; 32],
            server_id: "s".to_string(),
        });
        let replies = process_federation_frame(hello, &state, "peer").await;
        assert!(replies.is_empty());
    }

    #[tokio::test]
    async fn process_signature_after_handshake_ignored() {
        let state = fresh_state();
        let sig = FederationFrame::Signature(FederationSignature {
            signature: vec![0u8; 64],
            verifying_key: vec![0u8; 32],
            kex_key: vec![0u8; 32],
        });
        let replies = process_federation_frame(sig, &state, "peer").await;
        assert!(replies.is_empty());
    }

    #[tokio::test]
    async fn process_sync_result_returns_no_replies() {
        let state = fresh_state();
        let frame = FederationFrame::SyncResult(crate::server::federation::ContentSyncResult {
            works_received: 0,
            editions_received: 0,
            blobs_received: 0,
            works_already_known: 0,
            editions_already_known: 0,
            blobs_already_known: 0,
        });
        let replies = process_federation_frame(frame, &state, "peer").await;
        assert!(replies.is_empty());
    }

    #[tokio::test]
    async fn process_sync_pull_returns_sync_push() {
        let state = fresh_state();
        let pull = FederationFrame::SyncPull(crate::server::federation::SyncPull {
            server_id: "peer".to_string(),
            known_fingerprints: vec![],
            max_entries: 100,
        });
        let replies = process_federation_frame(pull, &state, "peer").await;
        assert_eq!(replies.len(), 1);
        match &replies[0] {
            FederationFrame::SyncPush(p) => {
                assert!(p.works.is_empty());
                assert!(p.editions.is_empty());
                assert!(p.blobs.is_empty());
            }
            other => panic!("expected SyncPush, got {:?}", other),
        }
    }

    #[tokio::test]
    async fn process_content_get_missing_returns_not_found() {
        let state = fresh_state();
        let replies =
            process_federation_frame(FederationFrame::ContentGet { work_id: 999 }, &state, "peer")
                .await;
        assert_eq!(replies.len(), 1);
        match &replies[0] {
            FederationFrame::ContentResponse {
                found,
                edition_payload,
            } => {
                assert!(!found);
                assert!(edition_payload.is_none());
            }
            _ => panic!("expected ContentResponse"),
        }
    }

    #[tokio::test]
    async fn process_blob_get_missing_returns_not_found() {
        let state = fresh_state();
        let replies = process_federation_frame(
            FederationFrame::BlobGet {
                content_hash_hex: "ab".repeat(32),
            },
            &state,
            "peer",
        )
        .await;
        assert_eq!(replies.len(), 1);
        match &replies[0] {
            FederationFrame::BlobResponse {
                found,
                data,
                mime_type,
            } => {
                assert!(!found);
                assert!(data.is_none());
                assert!(mime_type.is_none());
            }
            _ => panic!("expected BlobResponse"),
        }
    }

    #[tokio::test]
    async fn process_transclude_query_returns_empty_response() {
        let state = fresh_state();
        let replies = process_federation_frame(
            FederationFrame::TranscludeQuery {
                content_fingerprint_hex: "cd".repeat(32),
                direct_only: false,
            },
            &state,
            "peer",
        )
        .await;
        assert_eq!(replies.len(), 1);
        match &replies[0] {
            FederationFrame::TranscludeResponse { results } => assert!(results.is_empty()),
            _ => panic!("expected TranscludeResponse"),
        }
    }

    #[tokio::test]
    async fn process_content_fetch_missing_returns_not_found() {
        let state = fresh_state();
        let replies = process_federation_frame(
            FederationFrame::ContentFetch {
                content_fingerprint_hex: "ef".repeat(32),
            },
            &state,
            "peer",
        )
        .await;
        assert_eq!(replies.len(), 1);
        match &replies[0] {
            FederationFrame::ContentFetchResponse {
                found,
                edition_payload,
                blob_data,
                blob_mime_type,
            } => {
                assert!(!found);
                assert!(edition_payload.is_none());
                assert!(blob_data.is_none());
                assert!(blob_mime_type.is_none());
            }
            _ => panic!("expected ContentFetchResponse"),
        }
    }

    #[tokio::test]
    async fn process_membership_leave_mismatched_id_is_rejected() {
        let state = fresh_state();
        let frame = FederationFrame::MembershipLeave {
            server_id: "someone-else".to_string(),
        };
        let replies = process_federation_frame(frame, &state, "peer").await;
        assert!(replies.is_empty());
    }

    #[tokio::test]
    async fn process_crdt_sync_pull_mismatched_id_returns_empty() {
        let state = fresh_state();
        let frame = FederationFrame::CrdtSyncPull {
            server_id: "impostor".to_string(),
            work_ids: vec![1, 2],
        };
        let replies = process_federation_frame(frame, &state, "peer").await;
        assert!(replies.is_empty());
    }

    #[tokio::test]
    async fn process_governance_prepare_vote_mismatched_is_rejected() {
        let state = fresh_state();
        let frame = FederationFrame::GovernancePrepareVote {
            vote: crate::server::federation::PbftVote {
                view_number: 1,
                sequence_number: 1,
                voter_id: "impostor".to_string(),
                phase: crate::server::federation::PbftPhase::Prepare,
                digest: String::new(),
                signature: String::new(),
            },
        };
        let replies = process_federation_frame(frame, &state, "peer").await;
        assert!(replies.is_empty());
    }
}
