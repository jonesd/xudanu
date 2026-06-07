use serde::{Deserialize, Serialize};

use super::session::SessionId;
use crate::edition::BeId;

pub struct SyncStartResult {
    pub session_id: SyncSessionId,
    pub state_vector: Vec<u8>,
    pub current_text: String,
}

pub struct ApplyUpdateResult {
    pub relay_to: Vec<(SessionId, SyncSessionId)>,
    pub was_merged: bool,
}

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
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub club_id: Option<BeId>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub author_public_key: Option<Vec<u8>>,
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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SignedUpdate {
    pub update_bytes: Vec<u8>,
    pub signature: Vec<u8>,
    pub signer_public_key: [u8; 32],
}

pub fn bytes_to_hex(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{:02x}", b)).collect()
}

pub struct CrdtManager;

impl CrdtManager {
    pub fn new(_debounce_secs: u64) -> Self {
        CrdtManager
    }
}
