use std::collections::HashMap;
use std::sync::Arc;

use ed25519_dalek::{Signature, SigningKey, VerifyingKey};
use serde::{Deserialize, Serialize};
use yrs::updates::decoder::Decode;
use yrs::updates::encoder::Encode;
use yrs::{Any, Doc, GetString, ReadTxn, StateVector, Text, Transact, Update};

use super::session::SessionId;
use crate::crypto::sign::{sign_bytes, verify_signature};
use crate::edition::provenance::{sign_span, SpanProvenance};
use crate::edition::{BeId, Edition};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct SyncSessionId(u64);

impl SyncSessionId {
    pub fn from(val: u64) -> Self {
        SyncSessionId(val)
    }

    pub fn as_u64(self) -> u64 {
        self.0
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AwarenessState {
    pub session_id: u64,
    pub user_name: String,
    pub cursor: Option<CursorPosition>,
    pub selection: Option<SelectionRange>,
    pub is_typing: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CursorPosition {
    pub index: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SelectionRange {
    pub start: usize,
    pub end: usize,
}

pub struct AwarenessUpdate {
    pub work_id: BeId,
    pub state: AwarenessState,
}

pub struct AwarenessRelayResult {
    pub relay_to: Vec<(SessionId, SyncSessionId)>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthorIdentity {
    pub public_key: [u8; 32],
    pub display_name: String,
    #[serde(default)]
    pub club_be_id: BeId,
}

fn encode_be_id_as_attr(be_id: BeId) -> String {
    let mut buf = Vec::new();
    super::transport::varint::encode_varint(be_id, &mut buf);
    crate::server::crdt_manager::bytes_to_hex(&buf)
}

fn decode_be_id_from_attr(s: &str) -> Option<BeId> {
    let buf = hex_to_bytes(s)?;
    let (val, _) = super::transport::varint::decode_varint(&buf).ok()?;
    Some(val)
}

fn hex_to_bytes(hex: &str) -> Option<Vec<u8>> {
    if hex.len() % 2 != 0 {
        return None;
    }
    (0..hex.len())
        .step_by(2)
        .map(|i| u8::from_str_radix(&hex[i..i + 2], 16).ok())
        .collect()
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SignedUpdate {
    pub update_bytes: Vec<u8>,
    pub signature: Vec<u8>,
    pub signer_public_key: [u8; 32],
}

#[derive(Debug)]
pub enum SigningError {
    VerificationFailed(String),
    UnknownSigner([u8; 32]),
    InvalidSignatureBytes,
}

impl std::fmt::Display for SigningError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            SigningError::VerificationFailed(msg) => {
                write!(f, "signature verification failed: {}", msg)
            }
            SigningError::UnknownSigner(key) => write!(f, "unknown signer: {:02x?}", &key[..8]),
            SigningError::InvalidSignatureBytes => {
                write!(f, "invalid signature bytes (expected 64)")
            }
        }
    }
}

struct WorkDoc {
    doc: Doc,
    text: yrs::TextRef,
    subscribers: HashMap<SessionId, SyncSessionId>,
    author_keys: HashMap<SessionId, AuthorIdentity>,
    club_signing_keys: HashMap<BeId, SigningKey>,
    last_materialized_sv: Option<StateVector>,
    pending_update: Option<Vec<u8>>,
    last_change_timestamp: u64,
    awareness: HashMap<SessionId, AwarenessState>,
    federated_provenance: Vec<crate::edition::SpanProvenance>,
}

pub struct CrdtManager {
    docs: HashMap<BeId, WorkDoc>,
    session_counter: u64,
    debounce_secs: u64,
}

#[derive(Debug)]
pub enum CrdtError {
    WorkNotFound(BeId),
    NotSubscribed(BeId, SessionId),
    InvalidUpdate(String),
    AuthorNotRegistered(BeId, SessionId),
    SigningFailed(SigningError),
}

impl std::fmt::Display for CrdtError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            CrdtError::WorkNotFound(id) => write!(f, "CRDT work not found: {:016x}", id),
            CrdtError::NotSubscribed(work, sess) => {
                write!(f, "session not subscribed to work {:016x}", work)
            }
            CrdtError::InvalidUpdate(msg) => write!(f, "invalid yrs update: {}", msg),
            CrdtError::AuthorNotRegistered(work, sess) => {
                write!(f, "author not registered for work {:016x}", work)
            }
            CrdtError::SigningFailed(err) => write!(f, "signing error: {}", err),
        }
    }
}

pub struct SyncStartResult {
    pub session_id: SyncSessionId,
    pub state_vector: Vec<u8>,
    pub current_text: String,
}

pub struct ApplyUpdateResult {
    pub relay_to: Vec<(SessionId, SyncSessionId)>,
    pub was_merged: bool,
}

impl CrdtManager {
    pub fn new(debounce_secs: u64) -> Self {
        CrdtManager {
            docs: HashMap::new(),
            session_counter: 0,
            debounce_secs,
        }
    }

    fn next_session_id(&mut self) -> SyncSessionId {
        self.session_counter += 1;
        SyncSessionId(self.session_counter)
    }

    pub fn open_sync_session(
        &mut self,
        work_id: BeId,
        session_id: SessionId,
        initial_text: Option<&str>,
    ) -> SyncStartResult {
        let sync_id = self.next_session_id();

        if !self.docs.contains_key(&work_id) {
            let doc = Doc::new();
            let text = doc.get_or_insert_text("main");
            if let Some(t) = initial_text {
                if !t.is_empty() {
                    let mut txn = doc.transact_mut();
                    text.insert(&mut txn, 0, t);
                }
            }
            self.docs.insert(
                work_id,
                WorkDoc {
                    doc,
                    text,
                    subscribers: HashMap::new(),
                    author_keys: HashMap::new(),
                    club_signing_keys: HashMap::new(),
                    last_materialized_sv: None,
                    pending_update: None,
                    last_change_timestamp: 0,
                    awareness: HashMap::new(),
                    federated_provenance: Vec::new(),
                },
            );
        }

        let wd = self
            .docs
            .get_mut(&work_id)
            .expect("work doc must exist after insert");
        wd.subscribers.insert(session_id, sync_id);

        let state_vector = {
            let txn = wd.doc.transact();
            txn.state_vector().encode_v1()
        };

        let current_text = {
            let txn = wd.doc.transact();
            wd.text.get_string(&txn)
        };

        SyncStartResult {
            session_id: sync_id,
            state_vector,
            current_text,
        }
    }

    pub fn close_sync_session(
        &mut self,
        work_id: BeId,
        session_id: SessionId,
    ) -> Result<(), CrdtError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(CrdtError::WorkNotFound(work_id))?;
        wd.subscribers.remove(&session_id);
        wd.author_keys.remove(&session_id);
        wd.awareness.remove(&session_id);
        if wd.subscribers.is_empty() {
            self.docs.remove(&work_id);
        }
        Ok(())
    }

    pub fn apply_text_delta(
        &mut self,
        work_id: BeId,
        sender_session: SessionId,
        ops: &[crate::server::transport::protocol::TextDeltaOp],
    ) -> Result<ApplyUpdateResult, CrdtError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(CrdtError::WorkNotFound(work_id))?;
        if !wd.subscribers.contains_key(&sender_session) {
            return Err(CrdtError::NotSubscribed(work_id, sender_session));
        }

        let author_attr = wd
            .author_keys
            .get(&sender_session)
            .map(|a| encode_be_id_as_attr(a.club_be_id));

        {
            let mut txn = wd.doc.transact_mut();
            let mut pos: u32 = 0;
            for op in ops {
                match op {
                    crate::server::transport::protocol::TextDeltaOp::Retain { count } => {
                        pos += *count as u32;
                    }
                    crate::server::transport::protocol::TextDeltaOp::Insert { text } => {
                        if let Some(ref attr) = author_attr {
                            let attrs = yrs::types::Attrs::from([(
                                Arc::from("__author"),
                                Any::String(Arc::from(attr.as_str())),
                            )]);
                            wd.text.insert_with_attributes(&mut txn, pos, text, attrs);
                        } else {
                            wd.text.insert(&mut txn, pos, text);
                        }
                        pos += utf16_len(text) as u32;
                    }
                    crate::server::transport::protocol::TextDeltaOp::Delete { count } => {
                        let end = pos + *count as u32;
                        wd.text.remove_range(&mut txn, pos, end - pos);
                    }
                }
            }
        }

        wd.last_change_timestamp = current_timestamp_secs();

        let pending = {
            let txn = wd.doc.transact();
            let sv = wd
                .last_materialized_sv
                .as_ref()
                .cloned()
                .unwrap_or_else(|| StateVector::default());
            let diff = txn.encode_diff_v1(&sv);
            if diff.len() > 2 {
                Some(diff)
            } else {
                None
            }
        };
        wd.pending_update = pending;

        let relay_to: Vec<(SessionId, SyncSessionId)> = wd
            .subscribers
            .iter()
            .filter(|(sid, _)| **sid != sender_session)
            .map(|(sid, sync_id)| (*sid, *sync_id))
            .collect();

        Ok(ApplyUpdateResult { relay_to, was_merged: false })
    }

    pub fn apply_update(
        &mut self,
        work_id: BeId,
        sender_session: SessionId,
        update_bytes: &[u8],
    ) -> Result<ApplyUpdateResult, CrdtError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(CrdtError::WorkNotFound(work_id))?;
        if !wd.subscribers.contains_key(&sender_session) {
            return Err(CrdtError::NotSubscribed(work_id, sender_session));
        }

        let update =
            Update::decode_v1(update_bytes).map_err(|e| CrdtError::InvalidUpdate(e.to_string()))?;

        {
            let mut txn = wd.doc.transact_mut();
            txn.apply_update(update).map_err(|e| {
                CrdtError::InvalidUpdate(format!("update integration failed: {}", e))
            })?;
        }

        wd.last_change_timestamp = current_timestamp_secs();

        let pending = {
            let txn = wd.doc.transact();
            let sv = wd
                .last_materialized_sv
                .as_ref()
                .cloned()
                .unwrap_or_else(|| StateVector::default());
            let diff = txn.encode_diff_v1(&sv);
            if diff.len() > 2 {
                Some(diff)
            } else {
                None
            }
        };
        wd.pending_update = pending;

        let relay_to: Vec<(SessionId, SyncSessionId)> = wd
            .subscribers
            .iter()
            .filter(|(sid, _)| **sid != sender_session)
            .map(|(sid, sync_id)| (*sid, *sync_id))
            .collect();

        Ok(ApplyUpdateResult { relay_to, was_merged: false })
    }

    pub fn get_diff_since(&self, work_id: BeId, sv: &[u8]) -> Result<Vec<u8>, CrdtError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(CrdtError::WorkNotFound(work_id))?;
        let remote_sv =
            StateVector::decode_v1(sv).map_err(|e| CrdtError::InvalidUpdate(e.to_string()))?;
        let txn = wd.doc.transact();
        Ok(txn.encode_diff_v1(&remote_sv))
    }

    pub fn current_text(&self, work_id: BeId) -> Result<String, CrdtError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(CrdtError::WorkNotFound(work_id))?;
        let txn = wd.doc.transact();
        Ok(wd.text.get_string(&txn))
    }

    pub fn get_full_state(&self, work_id: BeId) -> Result<Vec<u8>, CrdtError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(CrdtError::WorkNotFound(work_id))?;
        let txn = wd.doc.transact();
        Ok(txn.encode_state_as_update_v1(&StateVector::default()))
    }

    pub fn materialize_edition(&mut self, work_id: BeId) -> Result<Edition, CrdtError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(CrdtError::WorkNotFound(work_id))?;

        let text: String = {
            let txn = wd.doc.transact();
            wd.text.get_string(&txn)
        };

        let current_sv = {
            let txn = wd.doc.transact();
            txn.state_vector()
        };

        wd.last_materialized_sv = Some(current_sv);
        wd.pending_update = None;

        let edition = text_to_edition(&text);
        Ok(edition)
    }

    pub fn base_edition(&self, work_id: BeId) -> Result<Edition, CrdtError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(CrdtError::WorkNotFound(work_id))?;
        let text: String = {
            let txn = wd.doc.transact();
            wd.text.get_string(&txn)
        };
        Ok(text_to_edition(&text))
    }

    pub fn materialize_edition_with_provenance(
        &mut self,
        work_id: BeId,
        signing_key: &SigningKey,
        server_id_bytes: &[u8; 32],
        timestamp: u64,
        author_signing_keys: &std::collections::HashMap<BeId, SigningKey>,
    ) -> Result<Edition, CrdtError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(CrdtError::WorkNotFound(work_id))?;

        let federated_prov: Vec<crate::edition::SpanProvenance> = wd.federated_provenance.clone();

        let text: String = {
            let txn = wd.doc.transact();
            wd.text.get_string(&txn)
        };

        let diffs: Vec<yrs::types::text::Diff<yrs::types::text::YChange>> = {
            let txn = wd.doc.transact();
            wd.text.diff(&txn, yrs::types::text::YChange::identity)
        };

        let author_spans = Self::extract_author_spans(&diffs);

        let current_sv = {
            let txn = wd.doc.transact();
            txn.state_vector()
        };

        wd.last_materialized_sv = Some(current_sv);
        wd.pending_update = None;

        let edition = text_to_edition(&text);

        let span_provenance = if !federated_prov.is_empty() {
            federated_prov
        } else {
            Self::build_span_provenance_from_authors(
                &edition,
                &author_spans,
                signing_key,
                server_id_bytes,
                timestamp,
                author_signing_keys,
            )
        };

        let mut edition = edition;
        edition.span_provenance = span_provenance;
        Ok(edition)
    }

    fn extract_author_spans(
        diffs: &[yrs::types::text::Diff<yrs::types::text::YChange>],
    ) -> Vec<(Option<BeId>, usize, usize)> {
        let mut spans: Vec<(Option<BeId>, usize, usize)> = Vec::new();
        let mut pos = 0usize;

        for d in diffs {
            let chunk_text = match &d.insert {
                yrs::Out::Any(Any::String(s)) => s.as_ref().to_string(),
                _ => String::new(),
            };
            if chunk_text.is_empty() {
                continue;
            }

            let author_be_id = d.attributes.as_ref().and_then(|attrs| {
                attrs.get(&Arc::from("__author")).and_then(|v| {
                    if let Any::String(s) = v {
                        decode_be_id_from_attr(s.as_ref())
                    } else {
                        None
                    }
                })
            });

            let start = pos;
            pos += chunk_text.chars().count();
            let end = pos;

            let last_author = spans.last().and_then(|(a, _, _)| *a);
            if last_author == author_be_id {
                if let Some((_, _, ref mut span_end)) = spans.last_mut() {
                    *span_end = end;
                }
            } else {
                spans.push((author_be_id, start, end));
            }
        }

        spans
    }

    fn build_span_provenance_from_authors(
        edition: &Edition,
        author_spans: &[(Option<BeId>, usize, usize)],
        fallback_signing_key: &SigningKey,
        server_id_bytes: &[u8; 32],
        timestamp: u64,
        author_signing_keys: &std::collections::HashMap<BeId, SigningKey>,
    ) -> Vec<SpanProvenance> {
        let entries = edition.all_entries();
        if entries.is_empty() {
            return Vec::new();
        }

        let first_pos = entries.first().map(|(p, _)| *p).unwrap_or(0);
        let last_pos = entries.last().map(|(p, _)| *p).unwrap_or(0);

        if author_spans.is_empty() || author_spans.len() == 1 && author_spans[0].0.is_none() {
            let fingerprints: Vec<[u8; 32]> = entries
                .iter()
                .map(|(_, c)| c.element.content_fingerprint())
                .collect();
            if fingerprints.is_empty() {
                return Vec::new();
            }
            return vec![SpanProvenance {
                start: first_pos,
                end: last_pos + 1,
                provenance: sign_span(
                    fallback_signing_key,
                    &fingerprints,
                    timestamp,
                    server_id_bytes,
                ),
            }];
        }

        let mut results = Vec::new();
        for (author_be_id, text_start, text_end) in author_spans {
            let start_pos = first_pos + *text_start as i64;
            let end_pos = first_pos + *text_end as i64;

            let mut fingerprints = Vec::new();
            for (pos, carrier) in &entries {
                if *pos >= start_pos && *pos < end_pos {
                    fingerprints.push(carrier.element.content_fingerprint());
                }
            }

            if fingerprints.is_empty() {
                continue;
            }

            let key = author_be_id
                .and_then(|id| author_signing_keys.get(&id))
                .unwrap_or(fallback_signing_key);

            results.push(SpanProvenance {
                start: start_pos,
                end: end_pos,
                provenance: sign_span(key, &fingerprints, timestamp, server_id_bytes),
            });
        }

        if results.is_empty() {
            let fingerprints: Vec<[u8; 32]> = entries
                .iter()
                .map(|(_, c)| c.element.content_fingerprint())
                .collect();
            if fingerprints.is_empty() {
                return Vec::new();
            }
            return vec![SpanProvenance {
                start: first_pos,
                end: last_pos + 1,
                provenance: sign_span(
                    fallback_signing_key,
                    &fingerprints,
                    timestamp,
                    server_id_bytes,
                ),
            }];
        }

        results
    }

    pub fn needs_materialization(&self, work_id: BeId) -> Result<bool, CrdtError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(CrdtError::WorkNotFound(work_id))?;
        Ok(wd.pending_update.is_some())
    }

    pub fn debounce_elapsed(&self, work_id: BeId) -> Result<bool, CrdtError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(CrdtError::WorkNotFound(work_id))?;
        if wd.last_change_timestamp == 0 {
            return Ok(false);
        }
        let elapsed = current_timestamp_secs().saturating_sub(wd.last_change_timestamp);
        Ok(elapsed >= self.debounce_secs)
    }

    pub fn subscriber_count(&self, work_id: BeId) -> usize {
        self.docs
            .get(&work_id)
            .map(|wd| wd.subscribers.len())
            .unwrap_or(0)
    }

    pub fn is_active(&self, work_id: BeId) -> bool {
        self.docs.contains_key(&work_id)
    }

    pub fn pending_work_ids(&self) -> Vec<BeId> {
        self.docs
            .iter()
            .filter(|(_, wd)| wd.pending_update.is_some())
            .map(|(id, _)| *id)
            .collect()
    }

    pub fn works_for_session(&self, session_id: SessionId) -> Vec<BeId> {
        self.docs
            .iter()
            .filter(|(_, wd)| wd.subscribers.contains_key(&session_id))
            .map(|(id, _)| *id)
            .collect()
    }

    pub fn close_session(&mut self, work_id: BeId, session_id: SessionId) {
        if let Some(wd) = self.docs.get_mut(&work_id) {
            wd.subscribers.remove(&session_id);
            wd.awareness.remove(&session_id);
        }
    }

    pub fn is_subscriber(&self, work_id: BeId, session_id: SessionId) -> bool {
        self.docs
            .get(&work_id)
            .map(|wd| wd.subscribers.contains_key(&session_id))
            .unwrap_or(false)
    }

    pub fn active_works(&self) -> Vec<BeId> {
        self.docs.keys().copied().collect()
    }

    pub fn store_federated_provenance(
        &mut self,
        work_id: BeId,
        provenance: Vec<crate::edition::SpanProvenance>,
    ) {
        if let Some(wd) = self.docs.get_mut(&work_id) {
            wd.federated_provenance = provenance;
        }
    }

    pub fn get_federated_provenance(
        &self,
        work_id: BeId,
    ) -> Option<&[crate::edition::SpanProvenance]> {
        self.docs
            .get(&work_id)
            .map(|wd| wd.federated_provenance.as_slice())
    }

    pub fn works_needing_materialization(&self) -> Vec<BeId> {
        self.docs
            .iter()
            .filter(|(_, wd)| wd.pending_update.is_some())
            .map(|(id, _)| *id)
            .collect()
    }

    pub fn initialize_from_edition(&mut self, work_id: BeId, edition: &Edition) {
        if self.docs.contains_key(&work_id) {
            return;
        }

        let text: String = edition
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.as_text().unwrap_or(""))
            .collect();

        let doc = Doc::new();
        let text_ref = doc.get_or_insert_text("main");
        if !text.is_empty() {
            let mut txn = doc.transact_mut();
            text_ref.insert(&mut txn, 0, &text);
        }

        let sv = {
            let txn = doc.transact();
            txn.state_vector()
        };

        self.docs.insert(
            work_id,
            WorkDoc {
                doc,
                text: text_ref,
                subscribers: HashMap::new(),
                author_keys: HashMap::new(),
                club_signing_keys: HashMap::new(),
                last_materialized_sv: Some(sv),
                pending_update: None,
                last_change_timestamp: 0,
                awareness: HashMap::new(),
                federated_provenance: Vec::new(),
            },
        );
    }

    pub fn extract_update_for_federation(&mut self, work_id: BeId) -> Result<Vec<u8>, CrdtError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(CrdtError::WorkNotFound(work_id))?;
        let sv = wd.last_materialized_sv.clone().unwrap_or_default();
        let diff = {
            let txn = wd.doc.transact();
            txn.encode_diff_v1(&sv)
        };
        wd.last_materialized_sv = {
            let txn = wd.doc.transact();
            Some(txn.state_vector())
        };
        wd.pending_update = None;
        Ok(diff)
    }

    pub fn apply_federation_update(
        &mut self,
        work_id: BeId,
        update_bytes: &[u8],
        initial_text: Option<&str>,
    ) -> Result<ApplyUpdateResult, CrdtError> {
        let federation_session = SessionId::new(u64::MAX);
        if !self.docs.contains_key(&work_id) {
            self.open_sync_session(work_id, federation_session, initial_text);
        }
        self.apply_update(work_id, federation_session, update_bytes)
    }

    pub fn update_awareness(
        &mut self,
        work_id: BeId,
        session_id: SessionId,
        state: AwarenessState,
    ) -> Result<AwarenessRelayResult, CrdtError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(CrdtError::WorkNotFound(work_id))?;
        if !wd.subscribers.contains_key(&session_id) {
            return Err(CrdtError::NotSubscribed(work_id, session_id));
        }
        wd.awareness.insert(session_id, state);
        let relay_to: Vec<(SessionId, SyncSessionId)> = wd
            .subscribers
            .iter()
            .filter(|(sid, _)| **sid != session_id)
            .map(|(sid, sync_id)| (*sid, *sync_id))
            .collect();
        Ok(AwarenessRelayResult { relay_to })
    }

    pub fn remove_awareness(
        &mut self,
        work_id: BeId,
        session_id: SessionId,
    ) -> Result<AwarenessRelayResult, CrdtError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(CrdtError::WorkNotFound(work_id))?;
        wd.awareness.remove(&session_id);
        let relay_to: Vec<(SessionId, SyncSessionId)> = wd
            .subscribers
            .iter()
            .filter(|(sid, _)| **sid != session_id)
            .map(|(sid, sync_id)| (*sid, *sync_id))
            .collect();
        Ok(AwarenessRelayResult { relay_to })
    }

    pub fn get_awareness(&self, work_id: BeId) -> Result<Vec<&AwarenessState>, CrdtError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(CrdtError::WorkNotFound(work_id))?;
        Ok(wd.awareness.values().collect())
    }

    pub fn register_author(
        &mut self,
        work_id: BeId,
        session_id: SessionId,
        author: AuthorIdentity,
    ) -> Result<(), CrdtError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(CrdtError::WorkNotFound(work_id))?;
        if !wd.subscribers.contains_key(&session_id) {
            return Err(CrdtError::NotSubscribed(work_id, session_id));
        }
        wd.author_keys.insert(session_id, author);
        Ok(())
    }

    pub fn store_club_signing_key(
        &mut self,
        work_id: BeId,
        club_be_id: BeId,
        signing_key: SigningKey,
    ) {
        if let Some(wd) = self.docs.get_mut(&work_id) {
            wd.club_signing_keys.insert(club_be_id, signing_key);
        }
    }

    pub fn get_club_signing_key(&self, work_id: BeId, club_be_id: BeId) -> Option<SigningKey> {
        self.docs
            .get(&work_id)?
            .club_signing_keys
            .get(&club_be_id)
            .cloned()
    }

    pub fn get_author(
        &self,
        work_id: BeId,
        session_id: SessionId,
    ) -> Result<Option<AuthorIdentity>, CrdtError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(CrdtError::WorkNotFound(work_id))?;
        Ok(wd.author_keys.get(&session_id).cloned())
    }

    pub fn get_author_sessions(
        &self,
        work_id: BeId,
    ) -> Result<Vec<(SessionId, AuthorIdentity)>, CrdtError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(CrdtError::WorkNotFound(work_id))?;
        Ok(wd
            .author_keys
            .iter()
            .map(|(sid, ai)| (*sid, ai.clone()))
            .collect())
    }

    pub fn get_subscribed_sessions(&self, work_id: BeId) -> Result<Vec<SessionId>, CrdtError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(CrdtError::WorkNotFound(work_id))?;
        Ok(wd.subscribers.keys().copied().collect())
    }

    pub fn sign_update(&self, update_bytes: &[u8], signing_key: &SigningKey) -> SignedUpdate {
        let signature = sign_bytes(signing_key, update_bytes);
        let verifying_key = signing_key.verifying_key();
        SignedUpdate {
            update_bytes: update_bytes.to_vec(),
            signature: signature.to_bytes().to_vec(),
            signer_public_key: verifying_key.to_bytes(),
        }
    }

    pub fn verify_signed_update(
        &self,
        signed: &SignedUpdate,
        known_keys: &HashMap<[u8; 32], VerifyingKey>,
    ) -> Result<(), SigningError> {
        let vk = known_keys
            .get(&signed.signer_public_key)
            .ok_or_else(|| SigningError::UnknownSigner(signed.signer_public_key))?;

        let sig_bytes: [u8; 64] = signed
            .signature
            .clone()
            .try_into()
            .map_err(|_| SigningError::InvalidSignatureBytes)?;
        let signature = Signature::from_bytes(&sig_bytes);

        verify_signature(vk, &signed.update_bytes, &signature)
            .map_err(|_| SigningError::VerificationFailed("signature does not verify".into()))
    }

    pub fn extract_signed_update_for_federation(
        &mut self,
        work_id: BeId,
        signing_key: &SigningKey,
    ) -> Result<SignedUpdate, CrdtError> {
        let update_bytes = self.extract_update_for_federation(work_id)?;
        Ok(self.sign_update(&update_bytes, signing_key))
    }

    pub fn apply_signed_federation_update(
        &mut self,
        work_id: BeId,
        signed: &SignedUpdate,
        known_keys: &HashMap<[u8; 32], VerifyingKey>,
        initial_text: Option<&str>,
    ) -> Result<ApplyUpdateResult, CrdtError> {
        self.verify_signed_update(signed, known_keys)
            .map_err(CrdtError::SigningFailed)?;

        let federation_session = SessionId::new(u64::MAX);
        if !self.docs.contains_key(&work_id) {
            self.open_sync_session(work_id, federation_session, initial_text);
        }
        self.apply_update(work_id, federation_session, &signed.update_bytes)
    }
}

fn text_to_edition(text: &str) -> Edition {
    Edition::from_text_batched(text)
}

fn utf16_len(s: &str) -> usize {
    s.chars().map(|c| c.len_utf16()).sum()
}

pub fn bytes_to_hex(bytes: &[u8]) -> String {
    let mut s = String::with_capacity(bytes.len() * 2);
    for &b in bytes {
        s.push_str(&format!("{:02x}", b));
    }
    s
}

fn current_timestamp_secs() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::server::transport::protocol::TextDeltaOp;

    fn make_session(id: u64) -> SessionId {
        SessionId::new(id)
    }

    #[test]
    fn test_open_close_session() {
        let mut mgr = CrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        let result = mgr.open_sync_session(work_id, sid, Some("hello"));
        assert!(mgr.is_active(work_id));
        assert_eq!(mgr.subscriber_count(work_id), 1);
        assert_eq!(result.current_text, "hello");

        mgr.close_sync_session(work_id, sid).unwrap();
        assert!(!mgr.is_active(work_id));
    }

    #[test]
    fn test_apply_update_relays() {
        let mut mgr = CrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        mgr.open_sync_session(work_id, s1, Some(""));
        mgr.open_sync_session(work_id, s2, Some(""));

        let doc = Doc::new();
        let text = doc.get_or_insert_text("main");
        {
            let mut txn = doc.transact_mut();
            text.insert(&mut txn, 0, "hi");
        }
        let sv = StateVector::default();
        let update_bytes = {
            let txn = doc.transact();
            txn.encode_diff_v1(&sv)
        };

        let result = mgr.apply_update(work_id, s1, &update_bytes).unwrap();
        assert_eq!(result.relay_to.len(), 1);
        assert_eq!(result.relay_to[0].0, s2);
    }

    #[test]
    fn test_materialize_edition() {
        let mut mgr = CrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr.open_sync_session(work_id, sid, Some("hello world"));

        let edition = mgr.materialize_edition(work_id).unwrap();
        let text: String = edition
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.as_text().unwrap_or(""))
            .collect();
        assert_eq!(text, "hello world");
    }

    #[test]
    fn test_needs_materialization() {
        let mut mgr = CrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr.open_sync_session(work_id, sid, Some("initial"));
        assert!(!mgr.needs_materialization(work_id).unwrap());

        let doc = Doc::new();
        let text = doc.get_or_insert_text("main");
        {
            let mut txn = doc.transact_mut();
            text.insert(&mut txn, 0, "x");
        }
        let update_bytes = {
            let txn = doc.transact();
            txn.encode_diff_v1(&StateVector::default())
        };
        mgr.apply_update(work_id, sid, &update_bytes).unwrap();

        assert!(mgr.needs_materialization(work_id).unwrap());

        mgr.materialize_edition(work_id).unwrap();
        assert!(!mgr.needs_materialization(work_id).unwrap());
    }

    #[test]
    fn test_initialize_from_edition() {
        let mut mgr = CrdtManager::new(3);
        let work_id: BeId = 42;
        let edition = Edition::from_text("from edition");

        mgr.initialize_from_edition(work_id, &edition);
        assert!(mgr.is_active(work_id));

        let sid = make_session(1);
        let result = mgr.open_sync_session(work_id, sid, None);
        assert_eq!(result.current_text, "from edition");
    }

    #[test]
    fn test_text_to_edition_roundtrip() {
        let text = "Hello, Xanadu!";
        let edition = text_to_edition(text);
        let roundtrip: String = edition
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.as_text().unwrap_or(""))
            .collect();
        assert_eq!(roundtrip, text);
    }

    #[test]
    fn test_apply_text_delta_basic() {
        let mut mgr = CrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);

        mgr.open_sync_session(work_id, s1, Some("hello world"));

        let ops = vec![
            TextDeltaOp::Retain { count: 6 },
            TextDeltaOp::Delete { count: 5 },
            TextDeltaOp::Insert {
                text: "xudanu".to_string(),
            },
        ];

        let result = mgr.apply_text_delta(work_id, s1, &ops).unwrap();
        assert_eq!(result.relay_to.len(), 0);

        let text = mgr.current_text(work_id).unwrap();
        assert_eq!(text, "hello xudanu");
    }

    #[test]
    fn test_apply_text_delta_emoji() {
        let mut mgr = CrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);

        mgr.open_sync_session(work_id, s1, Some("hi 🌍 world"));

        let ops = vec![
            TextDeltaOp::Retain { count: 3 },
            TextDeltaOp::Insert {
                text: "there ".to_string(),
            },
        ];

        mgr.apply_text_delta(work_id, s1, &ops).unwrap();

        let text = mgr.current_text(work_id).unwrap();
        assert_eq!(text, "hi there 🌍 world");
    }

    #[test]
    fn test_utf16_len() {
        assert_eq!(utf16_len("hello"), 5);
        assert_eq!(utf16_len("🌍"), 2);
        assert_eq!(utf16_len("hi 🌍"), 5);
        assert_eq!(utf16_len("日本語"), 3);
    }

    #[test]
    fn test_apply_text_delta_complex_emoji() {
        let mut mgr = CrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        mgr.open_sync_session(work_id, s1, Some("hello world"));

        let ops = vec![
            TextDeltaOp::Retain { count: 6 },
            TextDeltaOp::Delete { count: 5 },
            TextDeltaOp::Insert {
                text: "🌍 world".to_string(),
            },
        ];
        mgr.apply_text_delta(work_id, s1, &ops).unwrap();
        assert_eq!(mgr.current_text(work_id).unwrap(), "hello 🌍 world");

        mgr.open_sync_session(work_id, s2, None);

        let ops2 = vec![
            TextDeltaOp::Retain { count: 1 },
            TextDeltaOp::Delete { count: 2 },
            TextDeltaOp::Insert {
                text: "XX".to_string(),
            },
            TextDeltaOp::Retain { count: 1 },
        ];
        mgr.apply_text_delta(work_id, s2, &ops2).unwrap();
        assert_eq!(mgr.current_text(work_id).unwrap(), "hXXlo 🌍 world");
    }

    #[test]
    fn test_apply_text_delta_zwj_emoji() {
        let mut mgr = CrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);

        mgr.open_sync_session(work_id, s1, Some("hello"));

        let family = "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}";
        let ops = vec![
            TextDeltaOp::Retain { count: 5 },
            TextDeltaOp::Insert {
                text: family.to_string(),
            },
        ];
        mgr.apply_text_delta(work_id, s1, &ops).unwrap();
        assert_eq!(
            mgr.current_text(work_id).unwrap(),
            format!("hello{}", family)
        );
    }

    #[test]
    fn test_register_author() {
        let mut mgr = CrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr.open_sync_session(work_id, sid, Some("hello"));

        let author = AuthorIdentity {
            public_key: [1u8; 32],
            display_name: "Alice".to_string(),
            club_be_id: 42,
        };
        mgr.register_author(work_id, sid, author.clone()).unwrap();

        let retrieved = mgr.get_author(work_id, sid).unwrap().unwrap();
        assert_eq!(retrieved.public_key, [1u8; 32]);
        assert_eq!(retrieved.display_name, "Alice");
        assert_eq!(retrieved.club_be_id, 42);
    }

    #[test]
    fn test_register_author_not_subscriber() {
        let mut mgr = CrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);
        let other_sid = make_session(2);

        mgr.open_sync_session(work_id, sid, Some("hello"));

        let author = AuthorIdentity {
            public_key: [1u8; 32],
            display_name: "Eve".to_string(),
            club_be_id: 99,
        };
        let result = mgr.register_author(work_id, other_sid, author);
        assert!(result.is_err());
    }

    #[test]
    fn test_close_session_removes_author() {
        let mut mgr = CrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr.open_sync_session(work_id, sid, Some("hello"));
        mgr.register_author(
            work_id,
            sid,
            AuthorIdentity {
                public_key: [1u8; 32],
                display_name: "Alice".to_string(),
                club_be_id: 10,
            },
        )
        .unwrap();

        mgr.close_sync_session(work_id, sid).unwrap();
        assert!(!mgr.is_active(work_id));
    }

    #[test]
    fn test_author_attribute_on_insert() {
        let mut mgr = CrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        mgr.open_sync_session(work_id, s1, Some(""));

        let alice_key = [0xABu8; 32];
        mgr.register_author(
            work_id,
            s1,
            AuthorIdentity {
                public_key: alice_key,
                display_name: "Alice".to_string(),
                club_be_id: 100,
            },
        )
        .unwrap();

        let ops = vec![TextDeltaOp::Insert {
            text: "hello".to_string(),
        }];
        mgr.apply_text_delta(work_id, s1, &ops).unwrap();

        assert_eq!(mgr.current_text(work_id).unwrap(), "hello");

        mgr.open_sync_session(work_id, s2, None);

        let bob_key = [0xCDu8; 32];
        mgr.register_author(
            work_id,
            s2,
            AuthorIdentity {
                public_key: bob_key,
                display_name: "Bob".to_string(),
                club_be_id: 200,
            },
        )
        .unwrap();

        let ops2 = vec![
            TextDeltaOp::Retain { count: 5 },
            TextDeltaOp::Insert {
                text: " world".to_string(),
            },
        ];
        mgr.apply_text_delta(work_id, s2, &ops2).unwrap();

        assert_eq!(mgr.current_text(work_id).unwrap(), "hello world");
    }

    #[test]
    fn test_insert_without_author_still_works() {
        let mut mgr = CrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr.open_sync_session(work_id, sid, Some(""));

        let ops = vec![TextDeltaOp::Insert {
            text: "no author".to_string(),
        }];
        mgr.apply_text_delta(work_id, sid, &ops).unwrap();

        assert_eq!(mgr.current_text(work_id).unwrap(), "no author");
    }

    #[test]
    fn test_sign_and_verify_update() {
        use crate::crypto::sign::generate_signing_key;
        use std::collections::HashMap;

        let mut mgr = CrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr.open_sync_session(work_id, sid, Some("hello"));

        let signing_key = generate_signing_key();
        let verifying_key = signing_key.verifying_key();

        let update_bytes = {
            let txn = {
                let wd = mgr.docs.get(&work_id).unwrap();
                wd.doc.transact()
            };
            txn.encode_diff_v1(&StateVector::default())
        };

        let signed = mgr.sign_update(&update_bytes, &signing_key);

        assert_eq!(signed.update_bytes, update_bytes);
        assert_eq!(signed.signer_public_key, verifying_key.to_bytes());
        assert_eq!(signed.signature.len(), 64);

        let mut known_keys = HashMap::new();
        known_keys.insert(verifying_key.to_bytes(), verifying_key);

        let result = mgr.verify_signed_update(&signed, &known_keys);
        assert!(result.is_ok());
    }

    #[test]
    fn test_sign_rejects_tampered_update() {
        use crate::crypto::sign::generate_signing_key;
        use std::collections::HashMap;

        let mgr = CrdtManager::new(3);
        let signing_key = generate_signing_key();
        let verifying_key = signing_key.verifying_key();

        let mut signed = mgr.sign_update(b"original payload", &signing_key);
        signed.update_bytes.push(0xFF);

        let mut known_keys = HashMap::new();
        known_keys.insert(verifying_key.to_bytes(), verifying_key);

        let result = mgr.verify_signed_update(&signed, &known_keys);
        assert!(result.is_err());
    }

    #[test]
    fn test_sign_rejects_unknown_signer() {
        use crate::crypto::sign::generate_signing_key;
        use std::collections::HashMap;

        let mgr = CrdtManager::new(3);
        let signing_key = generate_signing_key();

        let signed = mgr.sign_update(b"some data", &signing_key);

        let known_keys: HashMap<[u8; 32], ed25519_dalek::VerifyingKey> = HashMap::new();
        let result = mgr.verify_signed_update(&signed, &known_keys);
        assert!(matches!(result, Err(SigningError::UnknownSigner(_))));
    }

    #[test]
    fn test_sign_rejects_wrong_key() {
        use crate::crypto::sign::generate_signing_key;
        use std::collections::HashMap;

        let mgr = CrdtManager::new(3);
        let signing_key = generate_signing_key();
        let wrong_key = generate_signing_key();
        let wrong_vk = wrong_key.verifying_key();

        let signed = mgr.sign_update(b"some data", &signing_key);

        let mut known_keys = HashMap::new();
        known_keys.insert(wrong_vk.to_bytes(), wrong_vk);

        let result = mgr.verify_signed_update(&signed, &known_keys);
        assert!(matches!(result, Err(SigningError::UnknownSigner(_))));
    }

    #[test]
    fn test_signed_federation_update_roundtrip() {
        use crate::crypto::sign::generate_signing_key;
        use std::collections::HashMap;

        let mut mgr = CrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);

        mgr.open_sync_session(work_id, s1, Some(""));
        let ops = vec![TextDeltaOp::Insert {
            text: "hello world".to_string(),
        }];
        mgr.apply_text_delta(work_id, s1, &ops).unwrap();
        mgr.materialize_edition(work_id).unwrap();

        let ops2 = vec![
            TextDeltaOp::Retain { count: 6 },
            TextDeltaOp::Delete { count: 5 },
            TextDeltaOp::Insert {
                text: "xudanu".to_string(),
            },
        ];
        mgr.apply_text_delta(work_id, s1, &ops2).unwrap();

        let signing_key = generate_signing_key();
        let verifying_key = signing_key.verifying_key();

        let full_state = mgr.get_full_state(work_id).unwrap();
        let signed = mgr.sign_update(&full_state, &signing_key);

        let mut known_keys = HashMap::new();
        known_keys.insert(verifying_key.to_bytes(), verifying_key);

        let mut mgr2 = CrdtManager::new(3);
        let result = mgr2.apply_signed_federation_update(work_id, &signed, &known_keys, None);
        assert!(result.is_ok());
        assert_eq!(mgr2.current_text(work_id).unwrap(), "hello xudanu");
    }

    #[test]
    fn test_signed_federation_rejects_tampered() {
        use crate::crypto::sign::generate_signing_key;
        use std::collections::HashMap;

        let mut mgr = CrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr.open_sync_session(work_id, sid, Some("hello"));

        let signing_key = generate_signing_key();
        let verifying_key = signing_key.verifying_key();

        let mut signed = mgr
            .extract_signed_update_for_federation(work_id, &signing_key)
            .unwrap();
        signed.update_bytes.push(0xFF);

        let mut known_keys = HashMap::new();
        known_keys.insert(verifying_key.to_bytes(), verifying_key);

        let mut mgr2 = CrdtManager::new(3);
        let result =
            mgr2.apply_signed_federation_update(work_id, &signed, &known_keys, Some("fallback"));
        assert!(result.is_err());
    }
}
