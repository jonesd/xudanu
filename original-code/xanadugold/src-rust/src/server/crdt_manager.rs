use std::collections::HashMap;

use serde::{Deserialize, Serialize};
use yrs::updates::decoder::Decode;
use yrs::updates::encoder::Encode;
use yrs::{Doc, GetString, ReadTxn, StateVector, Text, Transact, Update};

use crate::edition::{BeId, Edition};
use super::session::SessionId;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct SyncSessionId(u64);

impl SyncSessionId {
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

struct WorkDoc {
    doc: Doc,
    text: yrs::TextRef,
    subscribers: HashMap<SessionId, SyncSessionId>,
    last_materialized_sv: Option<StateVector>,
    pending_update: Option<Vec<u8>>,
    last_change_timestamp: u64,
    awareness: HashMap<SessionId, AwarenessState>,
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
}

impl std::fmt::Display for CrdtError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            CrdtError::WorkNotFound(id) => write!(f, "CRDT work not found: {:016x}", id),
            CrdtError::NotSubscribed(work, sess) => write!(f, "session not subscribed to work {:016x}", work),
            CrdtError::InvalidUpdate(msg) => write!(f, "invalid yrs update: {}", msg),
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
            self.docs.insert(work_id, WorkDoc {
                doc,
                text,
                subscribers: HashMap::new(),
                last_materialized_sv: None,
                pending_update: None,
                last_change_timestamp: 0,
                awareness: HashMap::new(),
            });
        }

        let wd = self.docs.get_mut(&work_id).unwrap();
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

    pub fn close_sync_session(&mut self, work_id: BeId, session_id: SessionId) -> Result<(), CrdtError> {
        let wd = self.docs.get_mut(&work_id).ok_or(CrdtError::WorkNotFound(work_id))?;
        wd.subscribers.remove(&session_id);
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
        let wd = self.docs.get_mut(&work_id).ok_or(CrdtError::WorkNotFound(work_id))?;
        if !wd.subscribers.contains_key(&sender_session) {
            return Err(CrdtError::NotSubscribed(work_id, sender_session));
        }

        {
            let mut txn = wd.doc.transact_mut();
            let mut pos: u32 = 0;
            for op in ops {
                match op {
                    crate::server::transport::protocol::TextDeltaOp::Retain { count } => {
                        pos += *count as u32;
                    }
                    crate::server::transport::protocol::TextDeltaOp::Insert { text } => {
                        wd.text.insert(&mut txn, pos, text);
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
            let sv = wd.last_materialized_sv.as_ref()
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

        let relay_to: Vec<(SessionId, SyncSessionId)> = wd.subscribers
            .iter()
            .filter(|(sid, _)| **sid != sender_session)
            .map(|(sid, sync_id)| (*sid, *sync_id))
            .collect();

        Ok(ApplyUpdateResult { relay_to })
    }

    pub fn apply_update(
        &mut self,
        work_id: BeId,
        sender_session: SessionId,
        update_bytes: &[u8],
    ) -> Result<ApplyUpdateResult, CrdtError> {
        let wd = self.docs.get_mut(&work_id).ok_or(CrdtError::WorkNotFound(work_id))?;
        if !wd.subscribers.contains_key(&sender_session) {
            return Err(CrdtError::NotSubscribed(work_id, sender_session));
        }

        let update = Update::decode_v1(update_bytes)
            .map_err(|e| CrdtError::InvalidUpdate(e.to_string()))?;

        {
            let mut txn = wd.doc.transact_mut();
            txn.apply_update(update)
                .map_err(|e| CrdtError::InvalidUpdate(format!("update integration failed: {}", e)))?;
        }

        wd.last_change_timestamp = current_timestamp_secs();

        let pending = {
            let txn = wd.doc.transact();
            let sv = wd.last_materialized_sv.as_ref()
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

        let relay_to: Vec<(SessionId, SyncSessionId)> = wd.subscribers
            .iter()
            .filter(|(sid, _)| **sid != sender_session)
            .map(|(sid, sync_id)| (*sid, *sync_id))
            .collect();

        Ok(ApplyUpdateResult { relay_to })
    }

    pub fn get_diff_since(&self, work_id: BeId, sv: &[u8]) -> Result<Vec<u8>, CrdtError> {
        let wd = self.docs.get(&work_id).ok_or(CrdtError::WorkNotFound(work_id))?;
        let remote_sv = StateVector::decode_v1(sv)
            .map_err(|e| CrdtError::InvalidUpdate(e.to_string()))?;
        let txn = wd.doc.transact();
        Ok(txn.encode_diff_v1(&remote_sv))
    }

    pub fn current_text(&self, work_id: BeId) -> Result<String, CrdtError> {
        let wd = self.docs.get(&work_id).ok_or(CrdtError::WorkNotFound(work_id))?;
        let txn = wd.doc.transact();
        Ok(wd.text.get_string(&txn))
    }

    pub fn get_full_state(&self, work_id: BeId) -> Result<Vec<u8>, CrdtError> {
        let wd = self.docs.get(&work_id).ok_or(CrdtError::WorkNotFound(work_id))?;
        let txn = wd.doc.transact();
        Ok(txn.encode_state_as_update_v1(&StateVector::default()))
    }

    pub fn materialize_edition(&mut self, work_id: BeId) -> Result<Edition, CrdtError> {
        let wd = self.docs.get_mut(&work_id).ok_or(CrdtError::WorkNotFound(work_id))?;

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

    pub fn needs_materialization(&self, work_id: BeId) -> Result<bool, CrdtError> {
        let wd = self.docs.get(&work_id).ok_or(CrdtError::WorkNotFound(work_id))?;
        Ok(wd.pending_update.is_some())
    }

    pub fn debounce_elapsed(&self, work_id: BeId) -> Result<bool, CrdtError> {
        let wd = self.docs.get(&work_id).ok_or(CrdtError::WorkNotFound(work_id))?;
        if wd.last_change_timestamp == 0 {
            return Ok(false);
        }
        let elapsed = current_timestamp_secs().saturating_sub(wd.last_change_timestamp);
        Ok(elapsed >= self.debounce_secs)
    }

    pub fn subscriber_count(&self, work_id: BeId) -> usize {
        self.docs.get(&work_id).map(|wd| wd.subscribers.len()).unwrap_or(0)
    }

    pub fn is_active(&self, work_id: BeId) -> bool {
        self.docs.contains_key(&work_id)
    }

    pub fn is_subscriber(&self, work_id: BeId, session_id: SessionId) -> bool {
        self.docs.get(&work_id)
            .map(|wd| wd.subscribers.contains_key(&session_id))
            .unwrap_or(false)
    }

    pub fn active_works(&self) -> Vec<BeId> {
        self.docs.keys().copied().collect()
    }

    pub fn works_needing_materialization(&self) -> Vec<BeId> {
        self.docs.iter()
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

        self.docs.insert(work_id, WorkDoc {
            doc,
            text: text_ref,
            subscribers: HashMap::new(),
            last_materialized_sv: Some(sv),
            pending_update: None,
            last_change_timestamp: 0,
            awareness: HashMap::new(),
        });
    }

    pub fn extract_update_for_federation(&mut self, work_id: BeId) -> Result<Vec<u8>, CrdtError> {
        let wd = self.docs.get_mut(&work_id).ok_or(CrdtError::WorkNotFound(work_id))?;
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
        let wd = self.docs.get_mut(&work_id).ok_or(CrdtError::WorkNotFound(work_id))?;
        if !wd.subscribers.contains_key(&session_id) {
            return Err(CrdtError::NotSubscribed(work_id, session_id));
        }
        wd.awareness.insert(session_id, state);
        let relay_to: Vec<(SessionId, SyncSessionId)> = wd.subscribers
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
        let wd = self.docs.get_mut(&work_id).ok_or(CrdtError::WorkNotFound(work_id))?;
        wd.awareness.remove(&session_id);
        let relay_to: Vec<(SessionId, SyncSessionId)> = wd.subscribers
            .iter()
            .filter(|(sid, _)| **sid != session_id)
            .map(|(sid, sync_id)| (*sid, *sync_id))
            .collect();
        Ok(AwarenessRelayResult { relay_to })
    }

    pub fn get_awareness(&self, work_id: BeId) -> Result<Vec<&AwarenessState>, CrdtError> {
        let wd = self.docs.get(&work_id).ok_or(CrdtError::WorkNotFound(work_id))?;
        Ok(wd.awareness.values().collect())
    }
}

fn text_to_edition(text: &str) -> Edition {
    Edition::from_text(text)
}

fn utf16_len(s: &str) -> usize {
    s.chars().map(|c| c.len_utf16()).sum()
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
            TextDeltaOp::Insert { text: "xudanu".to_string() },
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
            TextDeltaOp::Insert { text: "there ".to_string() },
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
            TextDeltaOp::Insert { text: "🌍 world".to_string() },
        ];
        mgr.apply_text_delta(work_id, s1, &ops).unwrap();
        assert_eq!(mgr.current_text(work_id).unwrap(), "hello 🌍 world");

        mgr.open_sync_session(work_id, s2, None);

        let ops2 = vec![
            TextDeltaOp::Retain { count: 1 },
            TextDeltaOp::Delete { count: 2 },
            TextDeltaOp::Insert { text: "XX".to_string() },
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
            TextDeltaOp::Insert { text: family.to_string() },
        ];
        mgr.apply_text_delta(work_id, s1, &ops).unwrap();
        assert_eq!(mgr.current_text(work_id).unwrap(), format!("hello{}", family));
    }
}
