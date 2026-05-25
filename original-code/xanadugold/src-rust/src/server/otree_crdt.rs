use std::collections::HashMap;
use std::sync::Arc;

use ed25519_dalek::{Signature, SigningKey, VerifyingKey};
use serde::{Deserialize, Serialize};

use super::session::SessionId;
use crate::crypto::sign::{sign_bytes, verify_signature};
use crate::edition::provenance::{sign_span, sign_element, ElementProvenance, SpanProvenance};
use crate::edition::three_way::{three_way_merge, MergeStrategy};
use crate::edition::{BeId, Carrier, Edition, Mapping, RangeElement};
use crate::server::transport::protocol::TextDeltaOp;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct OtreeSyncSessionId(u64);

impl OtreeSyncSessionId {
    pub fn as_u64(self) -> u64 {
        self.0
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OtreeAwarenessState {
    pub session_id: u64,
    pub user_name: String,
    pub cursor: Option<OtreeCursorPosition>,
    pub selection: Option<OtreeSelectionRange>,
    pub is_typing: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OtreeCursorPosition {
    pub index: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OtreeSelectionRange {
    pub start: usize,
    pub end: usize,
}

pub struct OtreeAwarenessUpdate {
    pub work_id: BeId,
    pub state: OtreeAwarenessState,
}

pub struct OtreeAwarenessRelayResult {
    pub relay_to: Vec<(SessionId, OtreeSyncSessionId)>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OtreeAuthorIdentity {
    pub public_key: [u8; 32],
    pub display_name: String,
    #[serde(default)]
    pub club_be_id: BeId,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OtreeSignedUpdate {
    pub update_text: String,
    pub signature: Vec<u8>,
    pub signer_public_key: [u8; 32],
}

#[derive(Debug)]
pub enum OtreeSigningError {
    VerificationFailed(String),
    UnknownSigner([u8; 32]),
    InvalidSignatureBytes,
}

impl std::fmt::Display for OtreeSigningError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            OtreeSigningError::VerificationFailed(msg) => {
                write!(f, "signature verification failed: {}", msg)
            }
            OtreeSigningError::UnknownSigner(key) => {
                write!(f, "unknown signer: {:02x?}", &key[..8])
            }
            OtreeSigningError::InvalidSignatureBytes => {
                write!(f, "invalid signature bytes (expected 64)")
            }
        }
    }
}

struct OtreeWorkDoc {
    current_edition: Edition,
    base_edition: Edition,
    pending_edition: Option<Edition>,
    narration_snapshot: Option<String>,
    subscribers: HashMap<SessionId, OtreeSyncSessionId>,
    author_keys: HashMap<SessionId, OtreeAuthorIdentity>,
    club_signing_keys: HashMap<BeId, SigningKey>,
    last_change_timestamp: u64,
    awareness: HashMap<SessionId, OtreeAwarenessState>,
    federated_provenance: Vec<SpanProvenance>,
    last_author_mapping: Option<Mapping>,
}

#[derive(Debug)]
pub enum OtreeError {
    WorkNotFound(BeId),
    NotSubscribed(BeId, SessionId),
    InvalidUpdate(String),
    AuthorNotRegistered(BeId, SessionId),
    SigningFailed(OtreeSigningError),
    MergeFailed(String),
}

impl std::fmt::Display for OtreeError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            OtreeError::WorkNotFound(id) => write!(f, "O-tree work not found: {:016x}", id),
            OtreeError::NotSubscribed(work, sess) => {
                write!(f, "session not subscribed to work {:016x}", work)
            }
            OtreeError::InvalidUpdate(msg) => write!(f, "invalid update: {}", msg),
            OtreeError::AuthorNotRegistered(work, sess) => {
                write!(f, "author not registered for work {:016x}", work)
            }
            OtreeError::SigningFailed(err) => write!(f, "signing error: {}", err),
            OtreeError::MergeFailed(msg) => write!(f, "merge failed: {}", msg),
        }
    }
}

pub struct OtreeSyncStartResult {
    pub session_id: OtreeSyncSessionId,
    pub current_text: String,
}

pub struct OtreeApplyResult {
    pub relay_to: Vec<(SessionId, OtreeSyncSessionId)>,
}

pub struct OtreeCrdtManager {
    docs: HashMap<BeId, OtreeWorkDoc>,
    session_counter: u64,
    debounce_secs: u64,
}

fn apply_text_delta_to_edition(
    edition: &Edition,
    ops: &[TextDeltaOp],
    author: Option<&OtreeAuthorIdentity>,
) -> Edition {
    let old_text = edition.to_text();
    let new_text = crate::server::transport::protocol::apply_text_delta(&old_text, ops);

    let timestamp = current_timestamp_secs();
    let prov = author.map(|a| ElementProvenance {
        author_public_key: a.public_key,
        author_display_name: a.display_name.clone(),
        author_club_id: a.club_be_id,
        timestamp,
    });

    let old_entries = edition.all_entries();
    let mut old_pos = 0i64;
    let mut old_idx = 0usize;

    let mut new_entries: Vec<(i64, Arc<Carrier>)> = Vec::with_capacity(new_text.len().max(old_entries.len()));
    let mut new_pos = 0i64;

    for op in ops {
        match op {
            TextDeltaOp::Retain { count } => {
                for _ in 0..*count {
                    if old_idx < old_entries.len() && old_entries[old_idx].0 == old_pos {
                        new_entries.push((new_pos, old_entries[old_idx].1.clone()));
                        old_idx += 1;
                    }
                    old_pos += 1;
                    new_pos += 1;
                }
            }
            TextDeltaOp::Delete { count } => {
                for _ in 0..*count {
                    if old_idx < old_entries.len() && old_entries[old_idx].0 == old_pos {
                        old_idx += 1;
                    }
                    old_pos += 1;
                }
            }
            TextDeltaOp::Insert { text } => {
                for ch in text.chars() {
                    let carrier = Carrier::new(RangeElement::text(ch.to_string()));
                    let carrier = match &prov {
                        Some(p) => carrier.with_provenance(p.clone()),
                        None => carrier,
                    };
                    new_entries.push((new_pos, Arc::new(carrier)));
                    new_pos += 1;
                }
            }
        }
    }

    while old_idx < old_entries.len() {
        new_entries.push((new_pos, old_entries[old_idx].1.clone()));
        old_idx += 1;
        new_pos += 1;
    }

    Edition::from_entries(new_entries)
}

fn current_timestamp_secs() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

impl OtreeCrdtManager {
    pub fn new(debounce_secs: u64) -> Self {
        OtreeCrdtManager {
            docs: HashMap::new(),
            session_counter: 0,
            debounce_secs,
        }
    }

    fn next_session_id(&mut self) -> OtreeSyncSessionId {
        self.session_counter += 1;
        OtreeSyncSessionId(self.session_counter)
    }

    pub fn open_sync_session(
        &mut self,
        work_id: BeId,
        session_id: SessionId,
        initial_edition: Option<&Edition>,
    ) -> OtreeSyncStartResult {
        let sync_id = self.next_session_id();

        if !self.docs.contains_key(&work_id) {
            let edition = initial_edition
                .cloned()
                .unwrap_or_else(|| Edition::from_text(""));
            self.docs.insert(
                work_id,
                OtreeWorkDoc {
                    base_edition: edition.clone(),
                    current_edition: edition,
                    pending_edition: None,
                    narration_snapshot: None,
                    subscribers: HashMap::new(),
                    author_keys: HashMap::new(),
                    club_signing_keys: HashMap::new(),
                    last_change_timestamp: 0,
                    awareness: HashMap::new(),
                    federated_provenance: Vec::new(),
                    last_author_mapping: None,
                },
            );
        }

        let wd = self
            .docs
            .get_mut(&work_id)
            .expect("work doc must exist after insert");
        wd.subscribers.insert(session_id, sync_id);

        let current_text = wd.current_edition.to_text();

        OtreeSyncStartResult {
            session_id: sync_id,
            current_text,
        }
    }

    pub fn close_sync_session(
        &mut self,
        work_id: BeId,
        session_id: SessionId,
    ) -> Result<(), OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
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
        ops: &[TextDeltaOp],
    ) -> Result<OtreeApplyResult, OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        if !wd.subscribers.contains_key(&sender_session) {
            return Err(OtreeError::NotSubscribed(work_id, sender_session));
        }

        let author = wd.author_keys.get(&sender_session).cloned();
        let author_edition = apply_text_delta_to_edition(&wd.current_edition, ops, author.as_ref());

        let base = &wd.base_edition;
        let current = &wd.current_edition;

        let merged = if base == current {
            author_edition
        } else {
            match three_way_merge(base, current, &author_edition, MergeStrategy::LastWriterWins) {
                Ok(result) => result.merged,
                Err(_) => author_edition,
            }
        };

        wd.last_author_mapping = Some(
            crate::edition::three_way::build_merge_mapping(&wd.current_edition, &merged),
        );
        wd.current_edition = merged;
        wd.last_change_timestamp = current_timestamp_secs();
        wd.pending_edition = Some(wd.current_edition.clone());

        let relay_to: Vec<(SessionId, OtreeSyncSessionId)> = wd
            .subscribers
            .iter()
            .filter(|(sid, _)| **sid != sender_session)
            .map(|(sid, sync_id)| (*sid, *sync_id))
            .collect();

        Ok(OtreeApplyResult { relay_to })
    }

    pub fn current_text(&self, work_id: BeId) -> Result<String, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd.current_edition.to_text())
    }

    pub fn current_edition(&self, work_id: BeId) -> Result<Edition, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd.current_edition.clone())
    }

    pub fn materialize_edition(&mut self, work_id: BeId) -> Result<Edition, OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        wd.base_edition = wd.current_edition.clone();
        wd.pending_edition = None;
        Ok(wd.current_edition.clone())
    }

    pub fn base_edition(&self, work_id: BeId) -> Result<Edition, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd.base_edition.clone())
    }

    pub fn narration_snapshot(&self, work_id: BeId) -> Result<Option<String>, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd.narration_snapshot.clone())
    }

    pub fn set_narration_snapshot(&mut self, work_id: BeId) -> Result<String, OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        let current = wd.current_edition.to_text();
        wd.narration_snapshot = Some(current.clone());
        Ok(current)
    }

    pub fn materialize_edition_with_provenance(
        &mut self,
        work_id: BeId,
        signing_key: &SigningKey,
        server_id_bytes: &[u8; 32],
        timestamp: u64,
        author_signing_keys: &std::collections::HashMap<BeId, SigningKey>,
    ) -> Result<Edition, OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;

        let federated_prov: Vec<SpanProvenance> = wd.federated_provenance.clone();
        let edition = wd.current_edition.clone();

        let span_provenance = if !federated_prov.is_empty() {
            federated_prov
        } else {
            Self::build_edition_provenance(
                &edition,
                signing_key,
                server_id_bytes,
                timestamp,
                author_signing_keys,
            )
        };

        wd.base_edition = edition.clone();
        wd.pending_edition = None;

        let mut edition = edition;
        edition.span_provenance = span_provenance;
        Ok(edition)
    }

    fn build_edition_provenance(
        edition: &Edition,
        fallback_signing_key: &SigningKey,
        server_id_bytes: &[u8; 32],
        timestamp: u64,
        _author_signing_keys: &std::collections::HashMap<BeId, SigningKey>,
    ) -> Vec<SpanProvenance> {
        let entries = edition.all_entries();
        if entries.is_empty() {
            return Vec::new();
        }

        let has_element_prov = entries.iter().any(|(_, c)| c.provenance.is_some());
        if !has_element_prov {
            let first_pos = entries.first().map(|(p, _)| *p).unwrap_or(0);
            let last_pos = entries.last().map(|(p, _)| *p).unwrap_or(0);
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
                provenance: sign_span(fallback_signing_key, &fingerprints, timestamp, server_id_bytes),
            }];
        }

        let mut spans: Vec<SpanProvenance> = Vec::new();
        let mut i = 0;
        while i < entries.len() {
            let (start_pos, carrier) = &entries[i];
            let ep = match &carrier.provenance {
                Some(p) => p,
                None => {
                    i += 1;
                    continue;
                }
            };

            let author_key = ep.author_club_id;
            let signing_key = _author_signing_keys
                .get(&author_key)
                .unwrap_or(fallback_signing_key);

            let mut fingerprints = Vec::new();
            let mut end_pos = *start_pos;
            let mut last_ts = ep.timestamp;
            let mut j = i;

            while j < entries.len() {
                let (pos, c) = &entries[j];
                match &c.provenance {
                    Some(p) if p.author_club_id == author_key => {
                        fingerprints.push(c.element.content_fingerprint());
                        end_pos = *pos + 1;
                        last_ts = p.timestamp;
                        j += 1;
                    }
                    Some(_) => break,
                    None => {
                        fingerprints.push(c.element.content_fingerprint());
                        end_pos = *pos + 1;
                        j += 1;
                    }
                }
            }

            if !fingerprints.is_empty() {
                spans.push(SpanProvenance {
                    start: *start_pos,
                    end: end_pos,
                    provenance: sign_span(signing_key, &fingerprints, last_ts, server_id_bytes),
                });
            }

            i = j;
        }

        spans
    }

    pub fn needs_materialization(&self, work_id: BeId) -> Result<bool, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd.pending_edition.is_some())
    }

    pub fn debounce_elapsed(&self, work_id: BeId) -> Result<bool, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
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

    pub fn is_subscriber(&self, work_id: BeId, session_id: SessionId) -> bool {
        self.docs
            .get(&work_id)
            .map(|wd| wd.subscribers.contains_key(&session_id))
            .unwrap_or(false)
    }

    pub fn active_works(&self) -> Vec<BeId> {
        self.docs.keys().copied().collect()
    }

    pub fn works_needing_materialization(&self) -> Vec<BeId> {
        self.docs
            .iter()
            .filter(|(_, wd)| wd.pending_edition.is_some())
            .map(|(id, _)| *id)
            .collect()
    }

    pub fn initialize_from_edition(&mut self, work_id: BeId, edition: &Edition) {
        if self.docs.contains_key(&work_id) {
            return;
        }
        self.docs.insert(
            work_id,
            OtreeWorkDoc {
                base_edition: edition.clone(),
                current_edition: edition.clone(),
                pending_edition: None,
                narration_snapshot: None,
                subscribers: HashMap::new(),
                author_keys: HashMap::new(),
                club_signing_keys: HashMap::new(),
                last_change_timestamp: 0,
                awareness: HashMap::new(),
                federated_provenance: Vec::new(),
                last_author_mapping: None,
            },
        );
    }

    pub fn get_author_mapping(&self, work_id: BeId) -> Option<Mapping> {
        self.docs
            .get(&work_id)
            .and_then(|wd| wd.last_author_mapping.clone())
    }

    pub fn register_author(
        &mut self,
        work_id: BeId,
        session_id: SessionId,
        author: OtreeAuthorIdentity,
    ) -> Result<(), OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        if !wd.subscribers.contains_key(&session_id) {
            return Err(OtreeError::NotSubscribed(work_id, session_id));
        }
        wd.author_keys.insert(session_id, author);
        Ok(())
    }

    pub fn get_author(
        &self,
        work_id: BeId,
        session_id: SessionId,
    ) -> Result<Option<OtreeAuthorIdentity>, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd.author_keys.get(&session_id).cloned())
    }

    pub fn get_author_sessions(
        &self,
        work_id: BeId,
    ) -> Result<Vec<(SessionId, OtreeAuthorIdentity)>, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd
            .author_keys
            .iter()
            .map(|(sid, ai)| (*sid, ai.clone()))
            .collect())
    }

    pub fn get_subscribed_sessions(&self, work_id: BeId) -> Result<Vec<SessionId>, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd.subscribers.keys().copied().collect())
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

    pub fn update_awareness(
        &mut self,
        work_id: BeId,
        session_id: SessionId,
        state: OtreeAwarenessState,
    ) -> Result<OtreeAwarenessRelayResult, OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        if !wd.subscribers.contains_key(&session_id) {
            return Err(OtreeError::NotSubscribed(work_id, session_id));
        }
        wd.awareness.insert(session_id, state);
        let relay_to: Vec<(SessionId, OtreeSyncSessionId)> = wd
            .subscribers
            .iter()
            .filter(|(sid, _)| **sid != session_id)
            .map(|(sid, sync_id)| (*sid, *sync_id))
            .collect();
        Ok(OtreeAwarenessRelayResult { relay_to })
    }

    pub fn remove_awareness(
        &mut self,
        work_id: BeId,
        session_id: SessionId,
    ) -> Result<OtreeAwarenessRelayResult, OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        wd.awareness.remove(&session_id);
        let relay_to: Vec<(SessionId, OtreeSyncSessionId)> = wd
            .subscribers
            .iter()
            .filter(|(sid, _)| **sid != session_id)
            .map(|(sid, sync_id)| (*sid, *sync_id))
            .collect();
        Ok(OtreeAwarenessRelayResult { relay_to })
    }

    pub fn get_awareness(&self, work_id: BeId) -> Result<Vec<&OtreeAwarenessState>, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd.awareness.values().collect())
    }

    pub fn store_federated_provenance(
        &mut self,
        work_id: BeId,
        provenance: Vec<SpanProvenance>,
    ) {
        if let Some(wd) = self.docs.get_mut(&work_id) {
            wd.federated_provenance = provenance;
        }
    }

    pub fn get_federated_provenance(
        &self,
        work_id: BeId,
    ) -> Option<&[SpanProvenance]> {
        self.docs
            .get(&work_id)
            .map(|wd| wd.federated_provenance.as_slice())
    }

    pub fn extract_update_for_federation(
        &mut self,
        work_id: BeId,
    ) -> Result<String, OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;

        let text = wd.current_edition.to_text();

        wd.base_edition = wd.current_edition.clone();
        wd.pending_edition = None;

        Ok(text)
    }

    pub fn apply_federation_update(
        &mut self,
        work_id: BeId,
        update_text: &str,
        initial_edition: Option<&Edition>,
    ) -> Result<OtreeApplyResult, OtreeError> {
        let incoming_edition = Edition::from_text(update_text);

        if !self.docs.contains_key(&work_id) {
            let edition = initial_edition.cloned().unwrap_or_else(|| incoming_edition.clone());
            self.initialize_from_edition(work_id, &edition);
        }

        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;

        let base = &wd.base_edition;
        let current = &wd.current_edition;

        let merged = if base == current {
            incoming_edition
        } else {
            match three_way_merge(base, current, &incoming_edition, MergeStrategy::LastWriterWins)
            {
                Ok(result) => result.merged,
                Err(_) => incoming_edition,
            }
        };

        wd.current_edition = merged;
        wd.last_change_timestamp = current_timestamp_secs();

        let relay_to: Vec<(SessionId, OtreeSyncSessionId)> = wd
            .subscribers
            .iter()
            .map(|(sid, sync_id)| (*sid, *sync_id))
            .collect();

        Ok(OtreeApplyResult { relay_to })
    }

    pub fn sign_update(
        &self,
        update_text: &str,
        signing_key: &SigningKey,
    ) -> OtreeSignedUpdate {
        let signature = sign_bytes(signing_key, update_text.as_bytes());
        let verifying_key = signing_key.verifying_key();
        OtreeSignedUpdate {
            update_text: update_text.to_string(),
            signature: signature.to_bytes().to_vec(),
            signer_public_key: verifying_key.to_bytes(),
        }
    }

    pub fn verify_signed_update(
        &self,
        signed: &OtreeSignedUpdate,
        known_keys: &HashMap<[u8; 32], VerifyingKey>,
    ) -> Result<(), OtreeSigningError> {
        let vk = known_keys
            .get(&signed.signer_public_key)
            .ok_or_else(|| OtreeSigningError::UnknownSigner(signed.signer_public_key))?;

        let sig_bytes: [u8; 64] = signed
            .signature
            .clone()
            .try_into()
            .map_err(|_| OtreeSigningError::InvalidSignatureBytes)?;
        let signature = Signature::from_bytes(&sig_bytes);

        verify_signature(vk, signed.update_text.as_bytes(), &signature)
            .map_err(|_| OtreeSigningError::VerificationFailed("signature does not verify".into()))
    }

    pub fn extract_signed_update_for_federation(
        &mut self,
        work_id: BeId,
        signing_key: &SigningKey,
    ) -> Result<OtreeSignedUpdate, OtreeError> {
        let update_text = self.extract_update_for_federation(work_id)?;
        Ok(self.sign_update(&update_text, signing_key))
    }

    pub fn apply_signed_federation_update(
        &mut self,
        work_id: BeId,
        signed: &OtreeSignedUpdate,
        known_keys: &HashMap<[u8; 32], VerifyingKey>,
        initial_edition: Option<&Edition>,
    ) -> Result<OtreeApplyResult, OtreeError> {
        self.verify_signed_update(signed, known_keys)
            .map_err(OtreeError::SigningFailed)?;

        self.apply_federation_update(work_id, &signed.update_text, initial_edition)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_session(id: u64) -> SessionId {
        SessionId::new(id)
    }

    #[test]
    fn test_open_close_session() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        let edition = Edition::from_text("hello");
        let result = mgr.open_sync_session(work_id, sid, Some(&edition));
        assert!(mgr.is_active(work_id));
        assert_eq!(mgr.subscriber_count(work_id), 1);
        assert_eq!(result.current_text, "hello");

        mgr.close_sync_session(work_id, sid).unwrap();
        assert!(!mgr.is_active(work_id));
    }

    #[test]
    fn test_apply_text_delta_single_author() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr.open_sync_session(work_id, sid, Some(&Edition::from_text("hello")));

        let ops = vec![
            TextDeltaOp::Retain { count: 5 },
            TextDeltaOp::Insert {
                text: " world".to_string(),
            },
        ];
        let result = mgr.apply_text_delta(work_id, sid, &ops).unwrap();
        assert!(result.relay_to.is_empty());

        let text = mgr.current_text(work_id).unwrap();
        assert_eq!(text, "hello world");
    }

    #[test]
    fn test_apply_text_delta_relays_to_other_subscribers() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text("")));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text("")));

        let ops = vec![TextDeltaOp::Insert {
            text: "hi".to_string(),
        }];
        let result = mgr.apply_text_delta(work_id, s1, &ops).unwrap();
        assert_eq!(result.relay_to.len(), 1);
        assert_eq!(result.relay_to[0].0, s2);
    }

    #[test]
    fn test_materialize_edition() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr.open_sync_session(work_id, sid, Some(&Edition::from_text("hello")));

        let ops = vec![TextDeltaOp::Insert {
            text: " world".to_string(),
        }];
        mgr.apply_text_delta(work_id, sid, &ops).unwrap();

        let edition = mgr.materialize_edition(work_id).unwrap();
        let text: String = edition
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.as_text().unwrap_or(""))
            .collect();
        assert_eq!(text, " worldhello");
    }

    #[test]
    fn test_needs_materialization() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr.open_sync_session(work_id, sid, Some(&Edition::from_text("hello")));
        assert!(!mgr.needs_materialization(work_id).unwrap());

        let ops = vec![TextDeltaOp::Insert {
            text: "!".to_string(),
        }];
        mgr.apply_text_delta(work_id, sid, &ops).unwrap();
        assert!(mgr.needs_materialization(work_id).unwrap());

        mgr.materialize_edition(work_id).unwrap();
        assert!(!mgr.needs_materialization(work_id).unwrap());
    }

    #[test]
    fn test_concurrent_edits_merge() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        let base = Edition::from_text("abc");
        mgr.open_sync_session(work_id, s1, Some(&base));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text("abc")));

        let ops1 = vec![
            TextDeltaOp::Retain { count: 1 },
            TextDeltaOp::Insert {
                text: "X".to_string(),
            },
            TextDeltaOp::Retain { count: 2 },
        ];
        mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

        let ops2 = vec![
            TextDeltaOp::Retain { count: 2 },
            TextDeltaOp::Insert {
                text: "Y".to_string(),
            },
            TextDeltaOp::Retain { count: 1 },
        ];
        mgr.apply_text_delta(work_id, s2, &ops2).unwrap();

        let text = mgr.current_text(work_id).unwrap();
        assert!(text.contains('X'), "merged should contain X from s1");
        assert!(text.contains('Y'), "merged should contain Y from s2");
        assert!(text.starts_with('a'), "should start with 'a'");
        assert!(text.ends_with('c'), "should end with 'c'");
    }

    #[test]
    fn test_delete_in_delta() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr.open_sync_session(work_id, sid, Some(&Edition::from_text("abcde")));

        let ops = vec![
            TextDeltaOp::Retain { count: 1 },
            TextDeltaOp::Delete { count: 3 },
            TextDeltaOp::Retain { count: 1 },
        ];
        mgr.apply_text_delta(work_id, sid, &ops).unwrap();

        let text = mgr.current_text(work_id).unwrap();
        assert_eq!(text, "ae");
    }

    #[test]
    fn test_initialize_from_edition() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let edition = Edition::from_text("existing content");

        mgr.initialize_from_edition(work_id, &edition);
        assert!(mgr.is_active(work_id));

        let sid = make_session(1);
        let result = mgr.open_sync_session(work_id, sid, None);
        assert_eq!(result.current_text, "existing content");
    }

    #[test]
    fn test_awareness() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text("")));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text("")));

        let state = OtreeAwarenessState {
            session_id: 1,
            user_name: "Alice".to_string(),
            cursor: Some(OtreeCursorPosition { index: 5 }),
            selection: None,
            is_typing: true,
        };
        let result = mgr.update_awareness(work_id, s1, state).unwrap();
        assert_eq!(result.relay_to.len(), 1);

        let awareness = mgr.get_awareness(work_id).unwrap();
        assert_eq!(awareness.len(), 1);
    }

    #[test]
    fn test_federation_roundtrip() {
        let mut mgr1 = OtreeCrdtManager::new(3);
        let mut mgr2 = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr1.open_sync_session(work_id, sid, Some(&Edition::from_text("hello")));

        let ops = vec![
            TextDeltaOp::Retain { count: 5 },
            TextDeltaOp::Insert {
                text: " world".to_string(),
            },
        ];
        mgr1.apply_text_delta(work_id, sid, &ops).unwrap();

        let update_text = mgr1.extract_update_for_federation(work_id).unwrap();

        mgr2.apply_federation_update(work_id, &update_text, None).unwrap();

        let text = mgr2.current_text(work_id).unwrap();
        assert_eq!(text, "hello world");
    }
}
