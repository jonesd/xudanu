use std::collections::HashMap;
use std::sync::Arc;
use std::sync::Mutex;

use ed25519_dalek::{Signature, SigningKey, VerifyingKey};
use serde::{Deserialize, Serialize};

use super::session::SessionId;
use crate::crypto::sign::{sign_bytes, verify_signature};
use crate::edition::provenance::{sign_span, ElementProvenance, SpanProvenance};
use crate::edition::three_way::{three_way_merge, MergeStrategy};
use crate::edition::{BeId, Carrier, Edition, Mapping, RangeElement, XnRegion};
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
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub club_id: Option<BeId>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub author_public_key: Option<Vec<u8>>,
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

impl OtreeAuthorIdentity {
    pub fn new(public_key: [u8; 32], display_name: String, club_be_id: BeId) -> Self {
        Self {
            public_key,
            display_name,
            club_be_id,
        }
    }
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

/// A single annotation on a work.
///
/// Serialized to a JSON chunk via serde and persisted in the chunk store
/// (see `Server::restore_annotations` in server.rs and the annotations
/// checkpoint path). The chunk hash is recorded in the manifest's
/// `annotations_hash` field.
///
/// SCHEMA EVOLUTION RULES:
///
/// 1. Adding a new field: ALWAYS use `#[serde(default)]`. Old annotation
///    chunks on disk won't have the field; serde fills the default.
///    This is sufficient — no migration needed.
///
/// 2. Renaming/removing/restructuring a field (breaking change): you MUST
///    add a migration step in `persist/migrations.rs` that transforms the
///    annotation chunk JSON from the old format to the new format before
///    deserialization. Bump `CURRENT_MANIFEST_VERSION` and add a step in
///    `migrate_manifest_to_latest`. Without this, old annotation chunks
///    will fail to deserialize and the server will silently lose data.
///
/// 3. Safety: the restore path in server.rs (line ~5155) must NEVER
///    overwrite a chunk that failed to deserialize. If deserialization
///    fails, preserve the old chunk on disk so it can be migrated later.
///    A failed deserialization that leads to 0 in-memory annotations +
///    auto-checkpoint = permanent data loss.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OtreeAnnotation {
    pub annotation_id: u64,
    pub kind: String,
    pub payload: String,
    pub char_start: usize,
    pub char_end: usize,
    pub created_by: Option<BeId>,
    #[serde(default)]
    pub created_at: u64,
    #[serde(default)]
    pub is_private: bool,
}

struct OtreeWorkDoc {
    current_edition: Edition,
    base_edition: Edition,
    session_bases: HashMap<SessionId, Edition>,
    pending_edition: Option<Edition>,
    narration_snapshot: Option<String>,
    subscribers: HashMap<SessionId, OtreeSyncSessionId>,
    author_keys: HashMap<SessionId, OtreeAuthorIdentity>,
    /// Authors who have disconnected but whose text still exists in the edition.
    /// Kept so materialization can correctly attribute their edits.
    historical_authors: HashMap<SessionId, OtreeAuthorIdentity>,
    club_signing_keys: HashMap<BeId, SigningKey>,
    last_change_timestamp: u64,
    awareness: HashMap<SessionId, OtreeAwarenessState>,
    federated_provenance: Vec<SpanProvenance>,
    last_author_mapping: Option<Mapping>,
    cached_text: Mutex<Option<String>>,
    annotations: Vec<OtreeAnnotation>,
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
            OtreeError::NotSubscribed(work, _sess) => {
                write!(f, "session not subscribed to work {:016x}", work)
            }
            OtreeError::InvalidUpdate(msg) => write!(f, "invalid update: {}", msg),
            OtreeError::AuthorNotRegistered(work, _sess) => {
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
    pub was_merged: bool,
}

pub struct TextRangeResult {
    pub text: String,
    pub total_chars: usize,
    pub start_char: usize,
    pub end_char: usize,
}

pub struct OtreeCrdtManager {
    docs: HashMap<BeId, OtreeWorkDoc>,
    orphaned_annotations: HashMap<BeId, Vec<OtreeAnnotation>>,
    session_counter: u64,
    debounce_secs: u64,
    /// Persistent signing keys per (work, club) — survives doc eviction
    persistent_signing_keys: HashMap<(BeId, BeId), SigningKey>,
}

fn find_entry_for_char(entry_char_start: &[usize], char_pos: usize) -> usize {
    let idx = entry_char_start.partition_point(|&start| start <= char_pos);
    if idx == 0 {
        return 0;
    }
    idx - 1
}

fn char_index_to_byte(s: &str, char_idx: usize) -> Option<usize> {
    for (i, (byte_offset, _)) in s.char_indices().enumerate() {
        if i == char_idx {
            return Some(byte_offset);
        }
    }
    if char_idx == s.chars().count() {
        return Some(s.len());
    }
    None
}

fn split_text_carrier(carrier: &Carrier, start: usize, end: usize) -> Option<Carrier> {
    match &carrier.element {
        RangeElement::Text { text } => {
            let start_byte = char_index_to_byte(text, start)?;
            let end_byte = char_index_to_byte(text, end)?;
            if start_byte == end_byte {
                return None;
            }
            let slice = &text[start_byte..end_byte];
            let mut c = Carrier::new(RangeElement::text(slice.to_string()));
            if let Some(prov) = &carrier.provenance {
                c = c.with_provenance(prov.clone());
            }
            Some(c)
        }
        _ => {
            if start == 0 && end >= 1 {
                Some(carrier.clone())
            } else {
                None
            }
        }
    }
}

fn push_coalesced(entries: &mut Vec<(i64, Arc<Carrier>)>, pos: &mut i64, carrier: Carrier) {
    if *pos > 0 {
        if let Some(last) = entries.last_mut() {
            if last.0 + 1 == *pos
                && last.1.provenance == carrier.provenance
                && last.1.label == carrier.label
            {
                if let (
                    RangeElement::Text { text: last_text },
                    RangeElement::Text { text: new_text },
                ) = (&last.1.element, &carrier.element)
                {
                    let combined = format!("{}{}", last_text, new_text);
                    let mut merged = Carrier::new(RangeElement::text(combined));
                    merged.label = carrier.label.clone();
                    merged.provenance = carrier.provenance.clone();
                    last.1 = Arc::new(merged);
                    return;
                }
            }
        }
    }
    entries.push((*pos, Arc::new(carrier)));
    *pos += 1;
}

fn flush_batched_insert_coalesced(
    pending: &mut String,
    prov: &Option<ElementProvenance>,
    entries: &mut Vec<(i64, Arc<Carrier>)>,
    pos: &mut i64,
) {
    if pending.is_empty() {
        return;
    }
    let text = std::mem::take(pending);
    let mut start = 0usize;
    for (i, ch) in text.char_indices() {
        if ch == '\n' {
            let line = &text[start..i + ch.len_utf8()];
            let carrier = Carrier::new(RangeElement::text(line.to_string()));
            let carrier = match prov {
                Some(p) => carrier.with_provenance(p.clone()),
                None => carrier,
            };
            push_coalesced(entries, pos, carrier);
            start = i + ch.len_utf8();
        }
    }
    if start < text.len() {
        let remaining = &text[start..];
        let carrier = Carrier::new(RangeElement::text(remaining.to_string()));
        let carrier = match prov {
            Some(p) => carrier.with_provenance(p.clone()),
            None => carrier,
        };
        push_coalesced(entries, pos, carrier);
    }
}

pub fn apply_text_delta_to_edition(
    edition: &Edition,
    ops: &[TextDeltaOp],
    author: Option<&OtreeAuthorIdentity>,
) -> Edition {
    let started = std::time::Instant::now();
    let timestamp = current_timestamp_secs();
    let prov = author.map(|a| ElementProvenance {
        author_public_key: a.public_key,
        author_display_name: a.display_name.clone(),
        author_club_id: a.club_be_id,
        timestamp,
        author_type: crate::edition::provenance::AuthorType::Human,
        llm_model: None,
        historical_author_id: None,
        source_work_id: None,
        transcluded_by: None,
        derived_by: None,
    });

    let old_entries = edition.cached_entries();

    let mut entry_char_start: Vec<usize> = Vec::with_capacity(old_entries.len());
    let mut cum = 0usize;
    for (_, carrier) in old_entries {
        entry_char_start.push(cum);
        cum += carrier.char_len();
    }
    let _total_old_chars = cum;

    let mut old_char_pos = 0usize;
    let mut current_entry_idx = 0usize;
    let mut new_entries: Vec<(i64, Arc<Carrier>)> =
        Vec::with_capacity(old_entries.len() + ops.len());
    let mut new_pos = 0i64;
    let mut pending_insert = String::new();

    for op in ops {
        match op {
            TextDeltaOp::Retain { count } => {
                flush_batched_insert_coalesced(
                    &mut pending_insert,
                    &prov,
                    &mut new_entries,
                    &mut new_pos,
                );
                let target_char_pos = old_char_pos + *count as usize;

                while old_char_pos < target_char_pos {
                    if current_entry_idx >= old_entries.len() {
                        break;
                    }
                    let entry = &old_entries[current_entry_idx];
                    let entry_start = entry_char_start[current_entry_idx];
                    let entry_len = entry.1.char_len();

                    if entry_len == 0 {
                        new_entries.push((new_pos, entry.1.clone()));
                        new_pos += 1;
                        current_entry_idx += 1;
                        continue;
                    }

                    let within = old_char_pos.saturating_sub(entry_start);
                    let available = entry_len - within;
                    let remaining = target_char_pos - old_char_pos;
                    let take = remaining.min(available);

                    if within == 0 && take == entry_len {
                        push_coalesced(&mut new_entries, &mut new_pos, (*entry.1).clone());
                    } else if let Some(carrier) =
                        split_text_carrier(&entry.1, within, within + take)
                    {
                        push_coalesced(&mut new_entries, &mut new_pos, carrier);
                    }

                    old_char_pos += take;
                    if within + take == entry_len {
                        current_entry_idx += 1;
                    }
                }
            }
            TextDeltaOp::Delete { count } => {
                flush_batched_insert_coalesced(
                    &mut pending_insert,
                    &prov,
                    &mut new_entries,
                    &mut new_pos,
                );
                let target_char_pos = old_char_pos + *count as usize;
                while old_char_pos < target_char_pos {
                    if current_entry_idx >= old_entries.len() {
                        break;
                    }
                    let entry_len = old_entries[current_entry_idx].1.char_len();
                    if entry_len == 0 {
                        current_entry_idx += 1;
                        continue;
                    }
                    let entry_start = entry_char_start[current_entry_idx];
                    let within = old_char_pos.saturating_sub(entry_start);
                    let available = entry_len - within;
                    let remaining = target_char_pos - old_char_pos;
                    let take = remaining.min(available);
                    old_char_pos += take;
                    if within + take == entry_len {
                        current_entry_idx += 1;
                    }
                }
            }
            TextDeltaOp::Insert { text } => {
                pending_insert.push_str(text);
            }
        }
    }

    flush_batched_insert_coalesced(&mut pending_insert, &prov, &mut new_entries, &mut new_pos);

    if current_entry_idx < old_entries.len() {
        let entry_start = entry_char_start[current_entry_idx];
        let within = old_char_pos.saturating_sub(entry_start);
        if within > 0 {
            if let Some(carrier) = split_text_carrier(
                &old_entries[current_entry_idx].1,
                within,
                old_entries[current_entry_idx].1.char_len(),
            ) {
                push_coalesced(&mut new_entries, &mut new_pos, carrier);
            }
            current_entry_idx += 1;
        }
    }

    while current_entry_idx < old_entries.len() {
        let entry = &old_entries[current_entry_idx];
        push_coalesced(&mut new_entries, &mut new_pos, (*entry.1).clone());
        current_entry_idx += 1;
    }

    let result = {
        let ed = Edition::from_entries(new_entries);
        tracing::debug!(
            "[apply_delta] old_entries={} result_entries={} ops={} elapsed_ms={:.3}",
            old_entries.len(),
            ed.all_entries().len(),
            ops.len(),
            started.elapsed().as_secs_f64() * 1000.0,
        );
        for (i, (p, c)) in ed.all_entries().iter().take(8).enumerate() {
            let txt_len = c.element.as_text().map(|t| t.len()).unwrap_or(0);
            tracing::debug!(
                "[apply_delta]   [{}] pos={} len={} prov={}",
                i,
                p,
                txt_len,
                c.provenance.is_some()
            );
        }
        ed
    };
    result
}

fn append_text_with_llm_provenance(
    edition: &Edition,
    text: &str,
    llm_model: &str,
    triggerer_club_id: BeId,
    server_pub_key: [u8; 32],
    attestation_json: Option<&str>,
) -> Edition {
    let mut entries = edition.all_entries().to_vec();
    let mut pos = entries.last().map(|(p, _)| *p + 1).unwrap_or(0);

    let model_label = if let Some(json) = attestation_json {
        format!("{} {}", llm_model, json)
    } else {
        llm_model.to_string()
    };

    let llm_prov = ElementProvenance {
        author_public_key: server_pub_key,
        author_display_name: llm_model.to_string(),
        author_club_id: triggerer_club_id,
        timestamp: current_timestamp_secs(),
        author_type: crate::edition::provenance::AuthorType::Llm,
        llm_model: Some(model_label),
        historical_author_id: None,
        source_work_id: None,
        transcluded_by: None,
        derived_by: None,
    };

    let mut start = 0usize;
    for (i, ch) in text.char_indices() {
        if ch == '\n' {
            let line = &text[start..i + ch.len_utf8()];
            let carrier = Carrier::new(RangeElement::text(line.to_string()))
                .with_provenance(llm_prov.clone());
            entries.push((pos, Arc::new(carrier)));
            pos += 1;
            start = i + ch.len_utf8();
        }
    }
    if start < text.len() {
        let remaining = &text[start..];
        let carrier = Carrier::new(RangeElement::text(remaining.to_string()))
            .with_provenance(llm_prov.clone());
        entries.push((pos, Arc::new(carrier)));
    }

    Edition::from_entries(entries).coalesce()
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
            orphaned_annotations: HashMap::new(),
            session_counter: 0,
            debounce_secs,
            persistent_signing_keys: HashMap::new(),
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
                .unwrap_or_else(|| Edition::from_text_batched(""));
            self.docs.insert(
                work_id,
                OtreeWorkDoc {
                    base_edition: edition.clone(),
                    current_edition: edition,
                    session_bases: HashMap::new(),
                    pending_edition: None,
                    narration_snapshot: None,
                    subscribers: HashMap::new(),
                    author_keys: HashMap::new(),
                    historical_authors: HashMap::new(),
                    club_signing_keys: HashMap::new(),
                    last_change_timestamp: 0,
                    awareness: HashMap::new(),
                    federated_provenance: Vec::new(),
                    last_author_mapping: None,
                    cached_text: Mutex::new(None),
                    annotations: Vec::new(),
                },
            );
        }

        let wd = self
            .docs
            .get_mut(&work_id)
            .expect("work doc must exist after insert");
        wd.subscribers.insert(session_id, sync_id);
        wd.session_bases
            .insert(session_id, wd.current_edition.clone());

        let current_text = {
            let cache = wd.cached_text.lock().unwrap_or_else(|e| e.into_inner());
            if cache.is_some() {
                cache.as_ref().unwrap().clone()
            } else {
                drop(cache);
                let text = wd.current_edition.to_text();
                *wd.cached_text.lock().unwrap_or_else(|e| e.into_inner()) = Some(text.clone());
                text
            }
        };

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
        // Preserve author identity for attribution even after disconnect
        if let Some(author) = wd.author_keys.remove(&session_id) {
            wd.historical_authors.insert(session_id, author);
        }
        wd.awareness.remove(&session_id);
        wd.session_bases.remove(&session_id);
        if wd.subscribers.is_empty() {
            // Materialize pending changes before evicting
            if wd.pending_edition.is_some() {
                wd.base_edition = wd.current_edition.clone();
                wd.pending_edition = None;
            }
            if !wd.annotations.is_empty() {
                self.orphaned_annotations
                    .insert(work_id, std::mem::take(&mut wd.annotations));
            }
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
        let session_base = wd
            .session_bases
            .get(&sender_session)
            .cloned()
            .unwrap_or_else(|| wd.base_edition.clone());
        let author_edition = apply_text_delta_to_edition(&session_base, ops, author.as_ref());

        let base = &session_base;
        let current = &wd.current_edition;

        let (merged, was_merged) = if base == current {
            if !session_base.span_provenance.is_empty() {
                let delta_mapping =
                    crate::edition::three_way::build_merge_mapping(&session_base, &author_edition);
                let migrated_sp = crate::edition::three_way::migrate_span_provenance_single(
                    &session_base.span_provenance,
                    &delta_mapping,
                );
                (author_edition.with_span_provenance(migrated_sp), false)
            } else {
                (author_edition, false)
            }
        } else {
            match three_way_merge(
                base,
                current,
                &author_edition,
                MergeStrategy::LastWriterWins,
            ) {
                Ok(result) => (result.merged, true),
                Err(_) => (author_edition, true),
            }
        };

        wd.last_author_mapping = Some(crate::edition::three_way::build_merge_mapping(
            &wd.current_edition,
            &merged,
        ));

        let mapping = wd.last_author_mapping.as_ref().unwrap();
        for ann in &mut wd.annotations {
            let old_region = XnRegion::interval(ann.char_start as i64, ann.char_end as i64);
            let new_region = mapping.of_region(&old_region);
            if new_region.is_empty() {
                ann.char_start = ann.char_end;
            } else {
                let intervals = new_region.intervals();
                if let Some(&(start, end)) = intervals.first() {
                    ann.char_start = start.max(0) as usize;
                    ann.char_end = end.max(0) as usize;
                }
            }
        }

        let expected_len = if was_merged {
            0
        } else {
            let insert_len: usize = ops
                .iter()
                .map(|op| match op {
                    TextDeltaOp::Insert { text } => text.chars().count(),
                    _ => 0,
                })
                .sum();
            let delete_sum: u64 = ops
                .iter()
                .map(|op| match op {
                    TextDeltaOp::Delete { count } => *count,
                    _ => 0,
                })
                .sum();
            let old_len = wd.current_edition.char_len() as u64;
            (old_len + insert_len as u64).saturating_sub(delete_sum) as usize
        };

        wd.current_edition = merged.clone();
        wd.session_bases.insert(sender_session, merged);
        if !was_merged && expected_len > 0 {
            let actual_len = wd.current_edition.char_len();
            if actual_len > expected_len * 2
                || (expected_len > 100 && actual_len > expected_len + expected_len / 2)
            {
                tracing::error!(
                    "[crdt] possible duplication: expected ~{} chars, got {}",
                    expected_len,
                    actual_len
                );
            }
        }
        *wd.cached_text.lock().unwrap_or_else(|e| e.into_inner()) = None;
        wd.last_change_timestamp = current_timestamp_secs();
        wd.pending_edition = Some(wd.current_edition.clone());

        let relay_to: Vec<(SessionId, OtreeSyncSessionId)> = wd
            .subscribers
            .iter()
            .filter(|(sid, _)| **sid != sender_session)
            .map(|(sid, sync_id)| (*sid, *sync_id))
            .collect();

        Ok(OtreeApplyResult {
            relay_to,
            was_merged,
        })
    }

    pub fn current_text(&self, work_id: BeId) -> Result<String, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        {
            let cache = wd.cached_text.lock().unwrap_or_else(|e| e.into_inner());
            if cache.is_some() {
                return Ok(cache.as_ref().unwrap().clone());
            }
        }
        let text = wd.current_edition.to_text();
        *wd.cached_text.lock().unwrap_or_else(|e| e.into_inner()) = Some(text.clone());
        Ok(text)
    }

    pub fn current_edition(&self, work_id: BeId) -> Result<Edition, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd.current_edition.clone())
    }

    pub fn text_range(
        &self,
        work_id: BeId,
        start_char: usize,
        end_char: usize,
    ) -> Result<TextRangeResult, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        let total_chars = wd.current_edition.char_len();
        let clamped_end = end_char.min(total_chars);
        let clamped_start = start_char.min(clamped_end);
        let text = wd.current_edition.to_text_range(clamped_start, clamped_end);
        Ok(TextRangeResult {
            text,
            total_chars,
            start_char: clamped_start,
            end_char: clamped_end,
        })
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

    pub fn append_llm_text(
        &mut self,
        work_id: BeId,
        text: &str,
        llm_model: &str,
        triggerer_club_id: BeId,
        server_pub_key: [u8; 32],
        attestation_json: Option<&str>,
    ) -> Result<(), OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        wd.current_edition = append_text_with_llm_provenance(
            &wd.current_edition,
            text,
            llm_model,
            triggerer_club_id,
            server_pub_key,
            attestation_json,
        );
        wd.cached_text
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .take();
        Ok(())
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

    #[cfg(test)]
    pub fn test_build_provenance(
        edition: &Edition,
        fallback_signing_key: &SigningKey,
        server_id_bytes: &[u8; 32],
        timestamp: u64,
        author_signing_keys: &std::collections::HashMap<BeId, SigningKey>,
    ) -> Vec<crate::edition::SpanProvenance> {
        Self::build_edition_provenance(
            edition,
            fallback_signing_key,
            server_id_bytes,
            timestamp,
            author_signing_keys,
        )
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
                provenance: sign_span(
                    fallback_signing_key,
                    &fingerprints,
                    timestamp,
                    server_id_bytes,
                ),
            }];
        }

        let mut spans: Vec<SpanProvenance> = Vec::new();
        let mut i = 0;
        while i < entries.len() {
            let (start_pos, carrier) = &entries[i];

            // Handle entries without provenance: group consecutive ones into
            // a fallback span (attributed to the server, not any specific author)
            if carrier.provenance.is_none() {
                let mut fingerprints = Vec::new();
                let mut end_pos = *start_pos + 1;
                let mut j = i;
                while j < entries.len() {
                    if entries[j].1.provenance.is_some() {
                        break;
                    }
                    fingerprints.push(entries[j].1.element.content_fingerprint());
                    end_pos = entries[j].0 + 1;
                    j += 1;
                }
                if !fingerprints.is_empty() {
                    spans.push(SpanProvenance {
                        start: *start_pos,
                        end: end_pos,
                        provenance: sign_span(
                            fallback_signing_key,
                            &fingerprints,
                            timestamp,
                            server_id_bytes,
                        ),
                    });
                }
                i = j;
                continue;
            }

            let ep = carrier.provenance.as_ref().unwrap();

            let author_key = ep.author_club_id;
            let author_type = ep.author_type.clone();
            let signing_key =
                if matches!(ep.author_type, crate::edition::provenance::AuthorType::Llm) {
                    fallback_signing_key
                } else {
                    _author_signing_keys
                        .get(&author_key)
                        .unwrap_or(fallback_signing_key)
                };

            let mut fingerprints = Vec::new();
            let mut end_pos = *start_pos;
            let mut last_ts = ep.timestamp;
            let mut j = i;

            while j < entries.len() {
                let (pos, c) = &entries[j];
                match &c.provenance {
                    Some(p) if p.author_club_id == author_key && p.author_type == author_type => {
                        fingerprints.push(c.element.content_fingerprint());
                        end_pos = *pos + 1;
                        last_ts = p.timestamp;
                        j += 1;
                    }
                    Some(_) => break,
                    None => {
                        // Do NOT absorb unattributed entries into this author's span.
                        // They will get their own span (signed by fallback) below.
                        break;
                    }
                }
            }

            if !fingerprints.is_empty() {
                tracing::debug!(
                    "[build_prov] span {}..{} author_type={:?} author_key={:04x} fps={}",
                    start_pos,
                    end_pos,
                    author_type,
                    author_key,
                    fingerprints.len()
                );
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

    pub fn pending_work_ids(&self) -> Vec<BeId> {
        self.docs
            .iter()
            .filter(|(_, wd)| wd.pending_edition.is_some())
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
            if wd.subscribers.is_empty() {
                *wd.cached_text.lock().unwrap_or_else(|e| e.into_inner()) = None;
            }
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
        let annotations = self
            .orphaned_annotations
            .remove(&work_id)
            .unwrap_or_default();
        self.docs.insert(
            work_id,
            OtreeWorkDoc {
                base_edition: edition.clone(),
                current_edition: edition.clone(),
                session_bases: HashMap::new(),
                pending_edition: None,
                narration_snapshot: None,
                subscribers: HashMap::new(),
                author_keys: HashMap::new(),
                historical_authors: HashMap::new(),
                club_signing_keys: HashMap::new(),
                last_change_timestamp: 0,
                awareness: HashMap::new(),
                federated_provenance: Vec::new(),
                last_author_mapping: None,
                cached_text: Mutex::new(None),
                annotations,
            },
        );
    }

    pub fn ensure_doc_for_annotations(&mut self, work_id: BeId, edition: &Edition) {
        if self.docs.contains_key(&work_id) {
            return;
        }
        self.initialize_from_edition(work_id, edition);
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
        let mut result: Vec<(SessionId, OtreeAuthorIdentity)> = wd
            .author_keys
            .iter()
            .map(|(sid, ai)| (*sid, ai.clone()))
            .collect();
        // Include historical authors (disconnected but their text persists)
        for (sid, ai) in &wd.historical_authors {
            if !wd.author_keys.contains_key(sid) {
                result.push((*sid, ai.clone()));
            }
        }
        Ok(result)
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
        self.persistent_signing_keys
            .insert((work_id, club_be_id), signing_key.clone());
        if let Some(wd) = self.docs.get_mut(&work_id) {
            wd.club_signing_keys.insert(club_be_id, signing_key);
        }
    }

    pub fn get_club_signing_key(&self, work_id: BeId, club_be_id: BeId) -> Option<SigningKey> {
        if let Some(wd) = self.docs.get(&work_id) {
            if let Some(sk) = wd.club_signing_keys.get(&club_be_id) {
                return Some(sk.clone());
            }
        }
        self.persistent_signing_keys
            .get(&(work_id, club_be_id))
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

    pub fn store_federated_provenance(&mut self, work_id: BeId, provenance: Vec<SpanProvenance>) {
        if let Some(wd) = self.docs.get_mut(&work_id) {
            let existing = std::mem::take(&mut wd.federated_provenance);
            let mut merged: Vec<SpanProvenance> = existing
                .iter()
                .filter(|old| {
                    !provenance
                        .iter()
                        .any(|new| new.start < old.end && old.start < new.end)
                })
                .cloned()
                .collect();
            merged.extend(provenance);
            merged.sort_by_key(|s| s.start);
            wd.federated_provenance = merged;
        }
    }

    pub fn get_federated_provenance(&self, work_id: BeId) -> Option<&[SpanProvenance]> {
        self.docs
            .get(&work_id)
            .map(|wd| wd.federated_provenance.as_slice())
    }

    pub fn sync_to_edition(&mut self, work_id: BeId, edition: Edition) -> Result<(), OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        wd.current_edition = edition;
        wd.base_edition = wd.current_edition.clone();
        wd.pending_edition = None;
        *wd.cached_text.lock().unwrap_or_else(|e| e.into_inner()) = None;
        Ok(())
    }

    pub fn extract_update_for_federation(&mut self, work_id: BeId) -> Result<String, OtreeError> {
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
        let incoming_edition = Edition::from_text_batched(update_text);

        if !self.docs.contains_key(&work_id) {
            let edition = initial_edition
                .cloned()
                .unwrap_or_else(|| incoming_edition.clone());
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
            match three_way_merge(
                base,
                current,
                &incoming_edition,
                MergeStrategy::LastWriterWins,
            ) {
                Ok(result) => result.merged,
                Err(_) => incoming_edition,
            }
        };

        wd.current_edition = merged;
        *wd.cached_text.lock().unwrap_or_else(|e| e.into_inner()) = None;
        wd.last_change_timestamp = current_timestamp_secs();

        let relay_to: Vec<(SessionId, OtreeSyncSessionId)> = wd
            .subscribers
            .iter()
            .map(|(sid, sync_id)| (*sid, *sync_id))
            .collect();

        Ok(OtreeApplyResult {
            relay_to,
            was_merged: false,
        })
    }

    pub fn sign_update(&self, update_text: &str, signing_key: &SigningKey) -> OtreeSignedUpdate {
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

    pub fn annotation_create(
        &mut self,
        work_id: BeId,
        annotation_id: u64,
        kind: String,
        payload: String,
        char_start: usize,
        char_end: usize,
        created_by: Option<BeId>,
        is_private: bool,
    ) -> Result<(), OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        wd.annotations.push(OtreeAnnotation {
            annotation_id,
            kind,
            payload,
            char_start,
            char_end,
            created_by,
            created_at: current_timestamp_secs(),
            is_private,
        });
        Ok(())
    }

    pub fn annotation_delete(
        &mut self,
        work_id: BeId,
        annotation_id: u64,
    ) -> Result<(), OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        wd.annotations.retain(|a| a.annotation_id != annotation_id);
        Ok(())
    }

    pub fn annotation_get(
        &self,
        work_id: BeId,
        annotation_id: u64,
    ) -> Result<Option<&OtreeAnnotation>, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd
            .annotations
            .iter()
            .find(|a| a.annotation_id == annotation_id))
    }

    pub fn annotation_list(&self, work_id: BeId) -> Result<Vec<&OtreeAnnotation>, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd.annotations.iter().collect())
    }

    pub fn annotation_update_range(
        &mut self,
        work_id: BeId,
        annotation_id: u64,
        char_start: usize,
        char_end: usize,
    ) -> Result<(), OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        if let Some(ann) = wd
            .annotations
            .iter_mut()
            .find(|a| a.annotation_id == annotation_id)
        {
            ann.char_start = char_start;
            ann.char_end = char_end;
        }
        Ok(())
    }

    pub fn all_annotations(&self) -> Vec<(BeId, Vec<OtreeAnnotation>)> {
        let mut result: Vec<(BeId, Vec<OtreeAnnotation>)> = self
            .docs
            .iter()
            .filter(|(_, wd)| !wd.annotations.is_empty())
            .map(|(work_id, wd)| (*work_id, wd.annotations.clone()))
            .collect();
        for (work_id, anns) in &self.orphaned_annotations {
            if !anns.is_empty() {
                result.push((*work_id, anns.clone()));
            }
        }
        result
    }

    pub fn restore_annotations(&mut self, data: &[(BeId, Vec<OtreeAnnotation>)]) {
        for (work_id, annotations) in data {
            if let Some(wd) = self.docs.get_mut(work_id) {
                let existing_ids: std::collections::HashSet<u64> =
                    wd.annotations.iter().map(|a| a.annotation_id).collect();
                for ann in annotations {
                    if !existing_ids.contains(&ann.annotation_id) {
                        wd.annotations.push(ann.clone());
                    }
                }
            } else {
                let existing = self.orphaned_annotations.entry(*work_id).or_default();
                let existing_ids: std::collections::HashSet<u64> =
                    existing.iter().map(|a| a.annotation_id).collect();
                for ann in annotations {
                    if !existing_ids.contains(&ann.annotation_id) {
                        existing.push(ann.clone());
                    }
                }
            }
        }
    }

    pub fn filter_annotations(
        &mut self,
        work_id: BeId,
        deleted_ids: &std::collections::HashSet<u64>,
    ) {
        if let Some(wd) = self.docs.get_mut(&work_id) {
            wd.annotations
                .retain(|a| !deleted_ids.contains(&a.annotation_id));
        }
    }

    pub fn replace_edition(&mut self, work_id: BeId, edition: crate::edition::Edition) {
        if let Some(wd) = self.docs.get_mut(&work_id) {
            wd.current_edition = edition;
            wd.cached_text
                .lock()
                .unwrap_or_else(|e| e.into_inner())
                .take();
        }
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
            TextDeltaOp::Retain { count: 5 as u64 },
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
            club_id: None,
            author_public_key: None,
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
            TextDeltaOp::Retain { count: 5 as u64 },
            TextDeltaOp::Insert {
                text: " world".to_string(),
            },
        ];
        mgr1.apply_text_delta(work_id, sid, &ops).unwrap();

        let update_text = mgr1.extract_update_for_federation(work_id).unwrap();

        mgr2.apply_federation_update(work_id, &update_text, None)
            .unwrap();

        let text = mgr2.current_text(work_id).unwrap();
        assert_eq!(text, "hello world");
    }

    /// Benchmark: single-character delta at increasing scale, for both
    /// batched (per-line entries) and fragmented (per-char entries)
    /// editions. Documents the flatten-walk-rebuild O(n) cost of the
    /// delta path — the target of tree-native delta application
    /// (PERF-PLAN Stage 5). A flat curve means per-edit cost no longer
    /// scales with document size.
    ///
    /// NOTE: fragmented sizes are capped small because incremental text
    /// coalescing concatenates into a growing String (quadratic bytes);
    /// batched sizes exercise the same walk at full scale.
    #[test]
    fn benchmark_apply_delta_at_scale() {
        for size in [1_000usize, 10_000, 100_000] {
            let text: String = "abcdefghij\n".repeat(size / 11);
            let chars = text.chars().count();
            let mid = chars / 2;
            let ops = vec![
                TextDeltaOp::Retain { count: mid as u64 },
                TextDeltaOp::Insert {
                    text: "X".to_string(),
                },
            ];

            let batched = Edition::from_text_batched(&text);
            let start = std::time::Instant::now();
            let result = apply_text_delta_to_edition(&batched, &ops, None);
            let elapsed = start.elapsed();
            assert_eq!(result.char_len(), chars + 1);
            println!(
                "apply_delta batched ({} chars, {} entries): {:?}",
                size,
                batched.count(),
                elapsed
            );
        }

        for size in [1_000usize, 5_000, 20_000] {
            let text: String = "ab".repeat(size / 2);
            let mid = size / 2;
            let ops = vec![
                TextDeltaOp::Retain { count: mid as u64 },
                TextDeltaOp::Insert {
                    text: "X".to_string(),
                },
            ];

            let fragmented = Edition::from_text(&text);
            let start = std::time::Instant::now();
            let result = apply_text_delta_to_edition(&fragmented, &ops, None);
            let elapsed = start.elapsed();
            assert_eq!(result.char_len(), size + 1);
            println!(
                "apply_delta fragmented ({} chars, {} entries): {:?}",
                size,
                fragmented.count(),
                elapsed
            );
        }
    }

    #[test]
    fn test_batched_insert_creates_fewer_elements() {
        let edition = Edition::from_text_batched("hello\nworld");
        let ops = vec![TextDeltaOp::Insert {
            text: "new line\n".to_string(),
        }];
        let result = apply_text_delta_to_edition(&edition, &ops, None);
        assert_eq!(result.to_text(), "new line\nhello\nworld");
        assert!(
            result.count() <= 4,
            "batched insert should create few elements, got {}",
            result.count()
        );
    }

    #[test]
    fn test_delta_on_batched_edition_retain() {
        let edition = Edition::from_text_batched("hello\nworld");
        assert_eq!(edition.count(), 2);
        let ops = vec![
            TextDeltaOp::Retain { count: 5 as u64 },
            TextDeltaOp::Insert {
                text: "!\n".to_string(),
            },
            TextDeltaOp::Retain { count: 6 },
        ];
        let result = apply_text_delta_to_edition(&edition, &ops, None);
        assert_eq!(result.to_text(), "hello!\n\nworld");
    }

    #[test]
    fn test_delta_on_batched_edition_delete() {
        let edition = Edition::from_text_batched("hello\nworld\n");
        let ops = vec![
            TextDeltaOp::Retain { count: 5 as u64 },
            TextDeltaOp::Delete { count: 1 },
            TextDeltaOp::Retain { count: 6 },
        ];
        let result = apply_text_delta_to_edition(&edition, &ops, None);
        assert_eq!(result.to_text(), "helloworld\n");
    }

    #[test]
    fn test_delta_on_batched_edition_mid_element_split() {
        let edition = Edition::from_text_batched("abcdef");
        assert_eq!(edition.count(), 1);
        let ops = vec![
            TextDeltaOp::Retain { count: 3 },
            TextDeltaOp::Delete { count: 2 },
            TextDeltaOp::Retain { count: 1 },
        ];
        let result = apply_text_delta_to_edition(&edition, &ops, None);
        assert_eq!(result.to_text(), "abcf");
    }

    #[test]
    fn test_delta_on_batched_edition_mid_element_insert() {
        let edition = Edition::from_text_batched("abcdef");
        let ops = vec![
            TextDeltaOp::Retain { count: 3 },
            TextDeltaOp::Insert {
                text: "XY".to_string(),
            },
            TextDeltaOp::Retain { count: 3 },
        ];
        let result = apply_text_delta_to_edition(&edition, &ops, None);
        assert_eq!(result.to_text(), "abcXYdef");
    }

    #[test]
    fn test_batched_insert_multiline() {
        let edition = Edition::from_text("");
        let ops = vec![TextDeltaOp::Insert {
            text: "line1\nline2\nline3".to_string(),
        }];
        let result = apply_text_delta_to_edition(&edition, &ops, None);
        assert_eq!(result.to_text(), "line1\nline2\nline3");
        assert_eq!(
            result.count(),
            1,
            "coalesce merges uniform-provenance inserts into 1 element"
        );
    }

    #[test]
    fn test_batched_edition_delete_across_elements() {
        let edition = Edition::from_text_batched("aa\nbb\ncc");
        assert_eq!(edition.count(), 3);
        let ops = vec![
            TextDeltaOp::Retain { count: 2 },
            TextDeltaOp::Delete { count: 4 },
            TextDeltaOp::Retain { count: 2 },
        ];
        let result = apply_text_delta_to_edition(&edition, &ops, None);
        assert_eq!(result.to_text(), "aacc");
    }

    #[test]
    fn test_batched_edition_with_author_provenance() {
        let edition = Edition::from_text_batched("hello\nworld");
        let author = OtreeAuthorIdentity {
            public_key: [1u8; 32],
            display_name: "test".to_string(),
            club_be_id: 0,
        };
        let ops = vec![TextDeltaOp::Insert {
            text: "new\n".to_string(),
        }];
        let result = apply_text_delta_to_edition(&edition, &ops, Some(&author));
        assert_eq!(result.to_text(), "new\nhello\nworld");
        let entries = result.all_entries();
        let has_prov = entries.iter().any(|(_, c)| c.provenance.is_some());
        assert!(has_prov, "inserted elements should have provenance");
    }

    #[test]
    fn test_batched_append_llm_provenance() {
        let edition = Edition::from_text_batched("hello\n");
        let result = append_text_with_llm_provenance(
            &edition,
            "world\nfoo",
            "test-model",
            0,
            [0u8; 32],
            None,
        );
        assert_eq!(result.to_text(), "hello\nworld\nfoo");
        let entries = result.all_entries();
        let llm_entries: Vec<_> = entries
            .iter()
            .filter(|(_, c)| {
                c.provenance.as_ref().map_or(false, |p| {
                    matches!(p.author_type, crate::edition::provenance::AuthorType::Llm)
                })
            })
            .collect();
        assert_eq!(
            llm_entries.len(),
            1,
            "coalesce merges uniform-provenance LLM elements into 1"
        );
    }

    #[test]
    fn test_split_text_carrier_basic() {
        let carrier = Carrier::new(RangeElement::text("hello".to_string()));
        let left = split_text_carrier(&carrier, 0, 3).unwrap();
        assert_eq!(left.element.as_text(), Some("hel"));
        let right = split_text_carrier(&carrier, 3, 5).unwrap();
        assert_eq!(right.element.as_text(), Some("lo"));
    }

    #[test]
    fn test_split_text_carrier_empty_returns_none() {
        let carrier = Carrier::new(RangeElement::text("hello".to_string()));
        assert!(split_text_carrier(&carrier, 3, 3).is_none());
    }

    #[test]
    fn test_delta_with_zero_char_elements_retain() {
        let mut entries = vec![];
        let mut pos = 0i64;
        entries.push((
            pos,
            Arc::new(Carrier::new(RangeElement::text("ab".to_string()))),
        ));
        pos += 1;
        entries.push((
            pos,
            Arc::new(Carrier::new(RangeElement::Data { bytes: vec![] })),
        ));
        pos += 1;
        entries.push((
            pos,
            Arc::new(Carrier::new(RangeElement::text("cd".to_string()))),
        ));
        pos += 1;
        let edition = Edition::from_entries(entries);

        let ops = vec![TextDeltaOp::Retain { count: 4 }];
        let result = apply_text_delta_to_edition(&edition, &ops, None);
        assert_eq!(result.to_text(), "abcd");
        assert_eq!(result.count(), 3, "placeholder should be preserved");
    }

    #[test]
    fn test_delta_with_zero_char_elements_delete() {
        let mut entries = vec![];
        let mut pos = 0i64;
        entries.push((
            pos,
            Arc::new(Carrier::new(RangeElement::text("ab".to_string()))),
        ));
        pos += 1;
        entries.push((
            pos,
            Arc::new(Carrier::new(RangeElement::Data { bytes: vec![] })),
        ));
        pos += 1;
        entries.push((
            pos,
            Arc::new(Carrier::new(RangeElement::text("cd".to_string()))),
        ));
        pos += 1;
        let edition = Edition::from_entries(entries);

        let ops = vec![
            TextDeltaOp::Retain { count: 1 },
            TextDeltaOp::Delete { count: 2 },
            TextDeltaOp::Retain { count: 1 },
        ];
        let result = apply_text_delta_to_edition(&edition, &ops, None);
        assert_eq!(result.to_text(), "ad");
    }

    #[test]
    fn test_delta_trailing_zero_char_preserved() {
        let mut entries = vec![];
        let mut pos = 0i64;
        entries.push((
            pos,
            Arc::new(Carrier::new(RangeElement::text("hello".to_string()))),
        ));
        pos += 1;
        entries.push((
            pos,
            Arc::new(Carrier::new(RangeElement::Data { bytes: vec![] })),
        ));
        pos += 1;
        let edition = Edition::from_entries(entries);

        let ops = vec![TextDeltaOp::Retain { count: 5 }];
        let result = apply_text_delta_to_edition(&edition, &ops, None);
        assert_eq!(result.to_text(), "hello");
        assert_eq!(result.count(), 2, "trailing placeholder preserved");
    }

    #[test]
    fn test_batched_mgr_full_workflow() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr.open_sync_session(
            work_id,
            sid,
            Some(&Edition::from_text_batched("line1\nline2\n")),
        );

        let ops = vec![
            TextDeltaOp::Retain { count: 6 },
            TextDeltaOp::Insert {
                text: "inserted\n".to_string(),
            },
            TextDeltaOp::Retain { count: 6 },
        ];
        mgr.apply_text_delta(work_id, sid, &ops).unwrap();

        let text = mgr.current_text(work_id).unwrap();
        assert_eq!(text, "line1\ninserted\nline2\n");
    }

    #[test]
    fn test_annotation_crud() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;

        let edition = Edition::from_text("hello world");
        mgr.initialize_from_edition(work_id, &edition);

        mgr.annotation_create(
            work_id,
            1,
            "note".into(),
            "my note".into(),
            0,
            5,
            None,
            false,
        )
        .unwrap();

        let anns = mgr.annotation_list(work_id).unwrap();
        assert_eq!(anns.len(), 1);
        assert_eq!(anns[0].annotation_id, 1);
        assert_eq!(anns[0].kind, "note");
        assert_eq!(anns[0].payload, "my note");
        assert_eq!(anns[0].char_start, 0);
        assert_eq!(anns[0].char_end, 5);
        assert_eq!(anns[0].created_by, None);

        mgr.annotation_delete(work_id, 1).unwrap();
        let anns = mgr.annotation_list(work_id).unwrap();
        assert!(anns.is_empty());
    }

    #[test]
    fn test_annotation_get() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;

        mgr.initialize_from_edition(work_id, &Edition::from_text("hello"));
        mgr.annotation_create(
            work_id,
            10,
            "highlight".into(),
            "important".into(),
            2,
            4,
            Some(99),
            false,
        )
        .unwrap();

        let ann = mgr.annotation_get(work_id, 10).unwrap().unwrap();
        assert_eq!(ann.annotation_id, 10);
        assert_eq!(ann.kind, "highlight");
        assert_eq!(ann.created_by, Some(99));

        assert!(mgr.annotation_get(work_id, 999).unwrap().is_none());
    }

    #[test]
    fn test_annotation_update_range() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;

        mgr.initialize_from_edition(work_id, &Edition::from_text("hello world"));
        mgr.annotation_create(work_id, 1, "note".into(), "x".into(), 0, 5, None, false)
            .unwrap();

        mgr.annotation_update_range(work_id, 1, 3, 8).unwrap();

        let ann = mgr.annotation_get(work_id, 1).unwrap().unwrap();
        assert_eq!(ann.char_start, 3);
        assert_eq!(ann.char_end, 8);
    }

    #[test]
    fn test_annotation_fails_without_doc() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 99;

        let result =
            mgr.annotation_create(work_id, 1, "note".into(), "x".into(), 0, 5, None, false);
        assert!(result.is_err());
    }

    #[test]
    fn test_ensure_doc_for_annotations() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;

        assert!(!mgr.docs.contains_key(&work_id));

        let edition = Edition::from_text("source text");
        mgr.ensure_doc_for_annotations(work_id, &edition);

        assert!(mgr.docs.contains_key(&work_id));

        mgr.annotation_create(work_id, 1, "note".into(), "ok".into(), 0, 5, None, false)
            .unwrap();
        let anns = mgr.annotation_list(work_id).unwrap();
        assert_eq!(anns.len(), 1);
    }

    #[test]
    fn test_ensure_doc_idempotent() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;

        mgr.open_sync_session(work_id, make_session(1), Some(&Edition::from_text("hello")));

        let text_before = mgr.current_text(work_id).unwrap();

        let edition = Edition::from_text("different");
        mgr.ensure_doc_for_annotations(work_id, &edition);

        let text_after = mgr.current_text(work_id).unwrap();
        assert_eq!(text_before, text_after);
    }

    #[test]
    fn test_all_annotations_empty() {
        let mgr = OtreeCrdtManager::new(3);
        let result = mgr.all_annotations();
        assert!(result.is_empty());
    }

    #[test]
    fn test_all_annotations_multiple_works() {
        let mut mgr = OtreeCrdtManager::new(3);

        let w1: BeId = 1;
        let w2: BeId = 2;

        mgr.initialize_from_edition(w1, &Edition::from_text("aaa"));
        mgr.initialize_from_edition(w2, &Edition::from_text("bbb"));

        mgr.annotation_create(w1, 1, "note".into(), "n1".into(), 0, 1, None, false)
            .unwrap();
        mgr.annotation_create(w1, 2, "note".into(), "n2".into(), 1, 2, None, false)
            .unwrap();
        mgr.annotation_create(w2, 3, "note".into(), "n3".into(), 0, 1, None, false)
            .unwrap();

        let all = mgr.all_annotations();
        assert_eq!(all.len(), 2);

        let w1_anns: Vec<_> = all.iter().filter(|(id, _)| *id == w1).collect();
        let w2_anns: Vec<_> = all.iter().filter(|(id, _)| *id == w2).collect();
        assert_eq!(w1_anns[0].1.len(), 2);
        assert_eq!(w2_anns[0].1.len(), 1);
    }

    #[test]
    fn test_restore_annotations() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;

        mgr.initialize_from_edition(work_id, &Edition::from_text("hello"));

        let data = vec![(
            work_id,
            vec![OtreeAnnotation {
                annotation_id: 99,
                kind: "restored".into(),
                payload: "from disk".into(),
                char_start: 0,
                char_end: 5,
                created_by: Some(7),
                created_at: 0,
                is_private: false,
            }],
        )];

        mgr.restore_annotations(&data);
        let anns = mgr.annotation_list(work_id).unwrap();
        assert_eq!(anns.len(), 1);
        assert_eq!(anns[0].annotation_id, 99);
        assert_eq!(anns[0].kind, "restored");
        assert_eq!(anns[0].created_by, Some(7));
    }

    #[test]
    fn test_concurrent_insert_at_same_position() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text("hello")));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text("hello")));

        let ops1 = vec![
            TextDeltaOp::Retain { count: 2 },
            TextDeltaOp::Insert {
                text: "A".to_string(),
            },
            TextDeltaOp::Retain { count: 3 },
        ];
        mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

        let ops2 = vec![
            TextDeltaOp::Retain { count: 2 },
            TextDeltaOp::Insert {
                text: "B".to_string(),
            },
            TextDeltaOp::Retain { count: 3 },
        ];
        mgr.apply_text_delta(work_id, s2, &ops2).unwrap();

        let text = mgr.current_text(work_id).unwrap();
        assert!(text.contains('A'), "must contain A from s1");
        assert!(text.contains('B'), "must contain B from s2");
        assert!(text.starts_with("he"), "prefix preserved");
        assert!(text.ends_with("llo"), "suffix preserved");
    }

    #[test]
    fn test_concurrent_insert_at_different_positions() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        let base = "The document text";
        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text(base)));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text(base)));

        let ops1 = vec![
            TextDeltaOp::Insert {
                text: "[START] ".to_string(),
            },
            TextDeltaOp::Retain {
                count: base.len() as u64,
            },
        ];
        mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

        let ops2 = vec![
            TextDeltaOp::Retain {
                count: base.len() as u64,
            },
            TextDeltaOp::Insert {
                text: " [END]".to_string(),
            },
        ];
        mgr.apply_text_delta(work_id, s2, &ops2).unwrap();

        let text = mgr.current_text(work_id).unwrap();
        assert!(
            text.contains("The document text"),
            "original text preserved"
        );
    }

    #[test]
    fn test_concurrent_delete_different_regions() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        let base = "abcdefghij";
        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text(base)));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text(base)));

        let ops1 = vec![
            TextDeltaOp::Retain { count: 2 },
            TextDeltaOp::Delete { count: 2 },
            TextDeltaOp::Retain { count: 6 },
        ];
        mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

        let ops2 = vec![
            TextDeltaOp::Retain { count: 6 },
            TextDeltaOp::Delete { count: 2 },
            TextDeltaOp::Retain { count: 2 },
        ];
        mgr.apply_text_delta(work_id, s2, &ops2).unwrap();

        let text = mgr.current_text(work_id).unwrap();
        assert!(
            !text.is_empty(),
            "concurrent deletes must not empty the document"
        );
        assert!(text.contains('a'), "undeleted prefix preserved");
    }

    #[test]
    fn test_concurrent_replace_vs_insert() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        let base = "old text";
        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text(base)));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text(base)));

        let ops1 = vec![
            TextDeltaOp::Delete { count: 3 },
            TextDeltaOp::Insert {
                text: "new".to_string(),
            },
            TextDeltaOp::Retain { count: 5 as u64 },
        ];
        mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

        let ops2 = vec![
            TextDeltaOp::Retain { count: 8 },
            TextDeltaOp::Insert {
                text: " appended".to_string(),
            },
        ];
        mgr.apply_text_delta(work_id, s2, &ops2).unwrap();

        let text = mgr.current_text(work_id).unwrap();
        assert!(text.contains("new"), "replacement from s1 preserved");
        assert!(text.contains("appended"), "insert from s2 preserved");
    }

    #[test]
    fn test_three_users_concurrent_edits() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);
        let s3 = make_session(3);

        let base = "Line one.\nLine two.\nLine three.";
        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text(base)));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text(base)));
        mgr.open_sync_session(work_id, s3, Some(&Edition::from_text(base)));

        let ops1 = vec![
            TextDeltaOp::Retain { count: 9 },
            TextDeltaOp::Insert {
                text: " [edited by A]".to_string(),
            },
            TextDeltaOp::Retain {
                count: (base.len() - 9) as u64,
            },
        ];
        mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

        let line2_start = "Line one.\n".len();
        let ops2 = vec![
            TextDeltaOp::Retain {
                count: (line2_start + 8) as u64,
            },
            TextDeltaOp::Insert {
                text: " [edited by B]".to_string(),
            },
            TextDeltaOp::Retain {
                count: (base.len() - line2_start - 8) as u64,
            },
        ];
        mgr.apply_text_delta(work_id, s2, &ops2).unwrap();

        let line3_start = "Line one.\nLine two.\n".len();
        let ops3 = vec![
            TextDeltaOp::Retain {
                count: (line3_start + 10) as u64,
            },
            TextDeltaOp::Insert {
                text: " [edited by C]".to_string(),
            },
        ];
        mgr.apply_text_delta(work_id, s3, &ops3).unwrap();

        let text = mgr.current_text(work_id).unwrap();
        assert!(text.contains("[edited by A]"), "A's edit must survive");
        assert!(text.contains("[edited by B]"), "B's edit must survive");
        assert!(text.contains("[edited by C]"), "C's edit must survive");
        assert!(text.contains("Line one."), "line 1 preserved");
        assert!(text.contains("Line two."), "line 2 preserved");
        assert!(text.contains("Line three."), "line 3 preserved");
    }

    #[test]
    fn test_rapid_sequential_edits_same_author() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr.open_sync_session(work_id, sid, Some(&Edition::from_text("")));

        for i in 0..50 {
            let cur = mgr.current_text(work_id).unwrap();
            let ops = vec![
                TextDeltaOp::Retain {
                    count: cur.len() as u64,
                },
                TextDeltaOp::Insert {
                    text: format!("line{}\n", i),
                },
            ];
            mgr.apply_text_delta(work_id, sid, &ops).unwrap();
        }

        let text = mgr.current_text(work_id).unwrap();
        let lines: Vec<&str> = text.lines().collect();
        assert_eq!(lines.len(), 50, "must have 50 lines");
        assert_eq!(lines[0], "line0");
        assert_eq!(lines[49], "line49");
    }

    #[test]
    fn test_interleaved_edits_two_authors() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text("base")));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text("base")));

        for round in 0..10 {
            let ops1 = vec![
                TextDeltaOp::Retain {
                    count: (4 + round * 2) as u64,
                },
                TextDeltaOp::Insert {
                    text: format!("A{}", round),
                },
            ];
            mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

            let ops2 = vec![
                TextDeltaOp::Retain {
                    count: (4 + round * 2 + 2) as u64,
                },
                TextDeltaOp::Insert {
                    text: format!("B{}", round),
                },
            ];
            mgr.apply_text_delta(work_id, s2, &ops2).unwrap();
        }

        let text = mgr.current_text(work_id).unwrap();
        assert!(text.starts_with("base"), "original text preserved");
        for round in 0..10 {
            assert!(
                text.contains(&format!("A{}", round)),
                "A{} must be in merged text",
                round
            );
            assert!(
                text.contains(&format!("B{}", round)),
                "B{} must be in merged text",
                round
            );
        }
    }

    #[test]
    fn test_annotation_migrates_through_concurrent_edit() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text("hello world")));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text("hello world")));

        mgr.annotation_create(
            work_id,
            100,
            "note".to_string(),
            "annotated".to_string(),
            6,
            11,
            None,
            false,
        )
        .unwrap();

        let anns_before = mgr.annotation_list(work_id).unwrap();
        assert_eq!(anns_before[0].char_start, 6);
        assert_eq!(anns_before[0].char_end, 11);

        let ops1 = vec![
            TextDeltaOp::Retain { count: 5 as u64 },
            TextDeltaOp::Insert {
                text: " beautiful".to_string(),
            },
            TextDeltaOp::Retain { count: 6 },
        ];
        mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

        let anns_after = mgr.annotation_list(work_id).unwrap();
        assert_eq!(anns_after.len(), 1, "annotation must survive edit");
    }

    #[test]
    fn test_concurrent_edit_large_document() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        let base = (0..500)
            .map(|i| format!("Line {} of content.\n", i))
            .collect::<String>();
        let base_len = base.len();
        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text(&base)));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text(&base)));

        let quarter = base_len / 4;
        let half = base_len / 2;
        let three_q = base_len * 3 / 4;

        let ops1 = vec![
            TextDeltaOp::Retain {
                count: quarter as u64,
            },
            TextDeltaOp::Insert {
                text: "[INSERT_A]".to_string(),
            },
            TextDeltaOp::Retain {
                count: (base_len - quarter) as u64,
            },
        ];
        mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

        let ops2 = vec![
            TextDeltaOp::Retain {
                count: three_q as u64,
            },
            TextDeltaOp::Insert {
                text: "[INSERT_B]".to_string(),
            },
            TextDeltaOp::Retain {
                count: (base_len - three_q) as u64,
            },
        ];
        mgr.apply_text_delta(work_id, s2, &ops2).unwrap();

        let text = mgr.current_text(work_id).unwrap();
        assert!(
            text.contains("[INSERT_A]"),
            "A's insert at 1/4 must survive"
        );
        assert!(
            text.contains("[INSERT_B]"),
            "B's insert at 3/4 must survive"
        );
        assert!(
            text.len() > base_len,
            "merged must be longer than base (inserts preserved)"
        );
    }

    #[test]
    fn test_concurrent_delete_same_region() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        let base = "keep1 DELETE_ME keep2";
        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text(base)));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text(base)));

        let ops1 = vec![
            TextDeltaOp::Retain { count: 6 },
            TextDeltaOp::Delete { count: 10 },
            TextDeltaOp::Retain { count: 6 },
        ];
        mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

        let ops2 = vec![
            TextDeltaOp::Retain { count: 6 },
            TextDeltaOp::Delete { count: 10 },
            TextDeltaOp::Retain { count: 6 },
        ];
        mgr.apply_text_delta(work_id, s2, &ops2).unwrap();

        let text = mgr.current_text(work_id).unwrap();
        assert!(
            !text.contains("DELETE_ME"),
            "deleted text must not reappear after concurrent delete"
        );
        assert!(text.contains("keep1"), "prefix preserved");
        assert!(text.contains("keep2"), "suffix preserved");
    }

    #[test]
    fn test_relay_notification_on_concurrent_edit() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);
        let s3 = make_session(3);

        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text("base")));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text("base")));
        mgr.open_sync_session(work_id, s3, Some(&Edition::from_text("base")));

        let ops = vec![
            TextDeltaOp::Insert {
                text: "X".to_string(),
            },
            TextDeltaOp::Retain { count: 4 },
        ];
        let result = mgr.apply_text_delta(work_id, s1, &ops).unwrap();

        assert_eq!(result.relay_to.len(), 2, "must relay to s2 and s3");
        let relay_targets: Vec<u64> = result.relay_to.iter().map(|(s, _)| s.as_u64()).collect();
        assert!(relay_targets.contains(&2), "must relay to s2");
        assert!(relay_targets.contains(&3), "must relay to s3");
    }

    #[test]
    fn test_materialize_after_concurrent_edits() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text("hello")));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text("hello")));

        let ops1 = vec![
            TextDeltaOp::Retain { count: 5 },
            TextDeltaOp::Insert {
                text: " world".to_string(),
            },
        ];
        mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

        let ops2 = vec![
            TextDeltaOp::Insert {
                text: "Greeting: ".to_string(),
            },
            TextDeltaOp::Retain { count: 5 },
        ];
        mgr.apply_text_delta(work_id, s2, &ops2).unwrap();

        mgr.materialize_edition(work_id).unwrap();
        let text = mgr.current_text(work_id).unwrap();
        assert!(
            text.contains("Greeting:"),
            "s2 prefix must survive materialization"
        );
        assert!(
            text.contains("world"),
            "s1 suffix must survive materialization"
        );
    }
}
