use std::net::SocketAddr;
use std::time::Duration;

use axum::{
    extract::{
        ws::{Message, WebSocket, WebSocketUpgrade},
        ConnectInfo, State,
    },
    routing::get,
    response::IntoResponse,
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
    #[serde(default = "default_min_compat")]
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
#[serde(tag = "type")]
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

    let peer_server_id = peer_hello.server_id.clone();
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
                            Ok(FederationFrame::GovernancePrePrepare { proposal }) => {
                                tracing::info!(
                                    "Governance: received pre-prepare from {} view={} seq={}",
                                    proposal.proposer_id, proposal.view_number, proposal.sequence_number
                                );
                                let my_id = state.server.with_server_ref(|srv| srv.federation_server_id());
                                let prepare_vote = crate::server::federation::PbftVote {
                                    view_number: proposal.view_number,
                                    sequence_number: proposal.sequence_number,
                                    voter_id: my_id,
                                    phase: crate::server::federation::PbftPhase::Prepare,
                                };
                                let phase = state.server.with_server(|srv| {
                                    srv.governance_receive_prepare(prepare_vote.clone())
                                });

                                send_encrypted_frame(
                                    &mut ws_sender,
                                    &FederationFrame::GovernancePrepareVote { vote: prepare_vote },
                                    &mut outbound_cipher,
                                ).await;

                                if phase == crate::server::federation::RoundPhase::Commit {
                                    let commit_vote = crate::server::federation::PbftVote {
                                        view_number: proposal.view_number,
                                        sequence_number: proposal.sequence_number,
                                        voter_id: state.server.with_server_ref(|srv| srv.federation_server_id()),
                                        phase: crate::server::federation::PbftPhase::Commit,
                                    };
                                    send_encrypted_frame(
                                        &mut ws_sender,
                                        &FederationFrame::GovernanceCommitVote { vote: commit_vote },
                                        &mut outbound_cipher,
                                    ).await;
                                }
                            }
                            Ok(FederationFrame::GovernancePrepareVote { vote }) => {
                                if vote.voter_id != peer_server_id {
                                    tracing::warn!("Governance: rejected prepare vote from {} claiming to be {}", peer_server_id, vote.voter_id);
                                } else {
                                    let phase = state.server.with_server(|srv| {
                                        srv.governance_receive_prepare(vote)
                                    });
                                    tracing::debug!("Governance: prepare vote processed, phase={:?}", phase);
                                }
                            }
                            Ok(FederationFrame::GovernanceCommitVote { vote }) => {
                                if vote.voter_id != peer_server_id {
                                    tracing::warn!("Governance: rejected commit vote from {} claiming to be {}", peer_server_id, vote.voter_id);
                                } else {
                                    let phase = state.server.with_server(|srv| {
                                        srv.governance_receive_commit(vote)
                                    });
                                    if phase == crate::server::federation::RoundPhase::Sealed {
                                        if let Some(batch) = state.server.with_server(|srv| {
                                            srv.governance_seal_round()
                                        }) {
                                            tracing::info!(
                                                "Governance: sealed batch seq={} with {} txs",
                                                batch.sequence_number, batch.transactions.len()
                                            );
                                        }
                                    }
                                }
                            }
                            Ok(FederationFrame::GovernanceSealed { batch }) => {
                                tracing::info!(
                                    "Governance: received sealed batch seq={} from {}",
                                    batch.sequence_number, batch.proposer_id
                                );
                                state.server.with_server(|srv| {
                                    if batch.proposer_id != peer_server_id {
                                        tracing::warn!(
                                            "Governance: rejected sealed batch from {} — proposer is {}",
                                            peer_server_id, batch.proposer_id
                                        );
                                        return;
                                    }
                                    let expected_seq = srv.governance_current_sequence() + 1;
                                    if batch.sequence_number != expected_seq {
                                        tracing::warn!(
                                            "Governance: rejected sealed batch seq={} — expected {}",
                                            batch.sequence_number, expected_seq
                                        );
                                        return;
                                    }
                                    if srv.governance_is_applied(batch.sequence_number) {
                                        tracing::info!(
                                            "Governance: skipping already-applied batch seq={}",
                                            batch.sequence_number
                                        );
                                        return;
                                    }
                                    for tx in &batch.transactions {
                                        srv.governance_execute_tx(tx);
                                    }
                                    srv.governance_mark_applied(batch.sequence_number);
                                });
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
        FederationFrame::GovernancePrePrepare { proposal } => {
            tracing::info!(
                "Governance: received pre-prepare from {} view={} seq={}",
                proposal.proposer_id,
                proposal.view_number,
                proposal.sequence_number
            );
            let my_id = state
                .server
                .with_server_ref(|srv| srv.federation_server_id());
            let prepare_vote = crate::server::federation::PbftVote {
                view_number: proposal.view_number,
                sequence_number: proposal.sequence_number,
                voter_id: my_id,
                phase: crate::server::federation::PbftPhase::Prepare,
            };
            let phase = state
                .server
                .with_server(|srv| srv.governance_receive_prepare(prepare_vote.clone()));

            let mut replies = vec![FederationFrame::GovernancePrepareVote { vote: prepare_vote }];

            if phase == crate::server::federation::RoundPhase::Commit {
                let commit_vote = crate::server::federation::PbftVote {
                    view_number: proposal.view_number,
                    sequence_number: proposal.sequence_number,
                    voter_id: state
                        .server
                        .with_server_ref(|srv| srv.federation_server_id()),
                    phase: crate::server::federation::PbftPhase::Commit,
                };
                replies.push(FederationFrame::GovernanceCommitVote { vote: commit_vote });
            }
            replies
        }
        FederationFrame::GovernancePrepareVote { vote } => {
            if vote.voter_id != peer_server_id {
                tracing::warn!(
                    "Governance: rejected prepare vote from {} claiming to be {}",
                    peer_server_id,
                    vote.voter_id
                );
            } else {
                let phase = state
                    .server
                    .with_server(|srv| srv.governance_receive_prepare(vote));
                tracing::debug!("Governance: prepare vote processed, phase={:?}", phase);
            }
            vec![]
        }
        FederationFrame::GovernanceCommitVote { vote } => {
            if vote.voter_id != peer_server_id {
                tracing::warn!(
                    "Governance: rejected commit vote from {} claiming to be {}",
                    peer_server_id,
                    vote.voter_id
                );
            } else {
                let phase = state
                    .server
                    .with_server(|srv| srv.governance_receive_commit(vote));
                if phase == crate::server::federation::RoundPhase::Sealed {
                    if let Some(batch) = state.server.with_server(|srv| srv.governance_seal_round())
                    {
                        tracing::info!(
                            "Governance: sealed batch seq={} with {} txs",
                            batch.sequence_number,
                            batch.transactions.len()
                        );
                    }
                }
            }
            vec![]
        }
        FederationFrame::GovernanceSealed { batch } => {
            tracing::info!(
                "Governance: received sealed batch seq={} from {}",
                batch.sequence_number,
                batch.proposer_id
            );
            state.server.with_server(|srv| {
                if batch.proposer_id != peer_server_id {
                    tracing::warn!(
                        "Governance: rejected sealed batch from {} — proposer is {}",
                        peer_server_id,
                        batch.proposer_id
                    );
                    return;
                }
                let expected_seq = srv.governance_current_sequence() + 1;
                if batch.sequence_number != expected_seq {
                    tracing::warn!(
                        "Governance: rejected sealed batch seq={} — expected {}",
                        batch.sequence_number,
                        expected_seq
                    );
                    return;
                }
                if srv.governance_is_applied(batch.sequence_number) {
                    tracing::info!(
                        "Governance: skipping already-applied batch seq={}",
                        batch.sequence_number
                    );
                    return;
                }
                for tx in &batch.transactions {
                    srv.governance_execute_tx(tx);
                }
                srv.governance_mark_applied(batch.sequence_number);
            });
            vec![]
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
        FederationFrame::ProvJsonExport { work_id, include_federation } => {
            let response = state.server.with_server_ref(|srv| {
                match srv.federation_export_prov_json(work_id, include_federation) {
                    Ok(prov_json) => FederationFrame::ProvJsonExportResult { prov_json },
                    Err(e) => FederationFrame::ProvJsonExportResult { 
                        prov_json: format!("Error: {}", e) 
                    },
                }
            });
            vec![response]
        }
        FederationFrame::ProvJsonExportResult { .. } => vec![],
        FederationFrame::FederationProvBundle { bundle } => {
            state.server.with_server(|srv| {
                // Handle incoming federation provenance bundle
                tracing::info!("Received federation provenance bundle: {}", bundle.bundle_id);
            });
            vec![]
        }
        FederationFrame::FederationAttestationRequest { attestation_type, subject_server_id } => {
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
                    Err(e) => FederationFrame::FederationAttestationResponse {
                        attestation: None,
                        accepted: false,
                    },
                }
            });
            vec![response]
        }
        FederationFrame::FederationAttestationResponse { attestation, accepted } => {
            if let Some(attestation) = attestation {
                let verified = state.server.with_server_ref(|srv| {
                    srv.federation_verify_attestation(&attestation)
                });
                tracing::info!("Attestation verification result: {:?}", verified);
            }
            vec![]
        }
        FederationFrame::ClusterVerificationProv { timestamp, consensus_type } => {
            let response = state.server.with_server(|srv| {
                match srv.federation_record_cluster_verification(timestamp, consensus_type.clone(), peer_server_id.to_string()) {
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
}
