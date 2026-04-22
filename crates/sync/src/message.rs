use serde::{Deserialize, Serialize};
use xudanu_types::{AuthorId, Change, ChangeHash, SiteId};
use xudanu_core::state_vector::StateVector;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncMessage {
    pub message_type: SyncMessageType,
    pub sender_site: SiteId,
    pub sender_author: AuthorId,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum SyncMessageType {
    StateVector(StateVectorMessage),
    Changes(ChangesMessage),
    Ack(AckMessage),
    Awareness(AwarenessMessage),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StateVectorMessage {
    pub state_vector: Vec<(SiteId, u64)>,
    pub heads: Vec<ChangeHash>,
}

impl StateVectorMessage {
    pub fn from_state_vector(sv: &StateVector, heads: &[ChangeHash]) -> Self {
        Self {
            state_vector: sv.iter().map(|(s, &c)| (*s, c)).collect(),
            heads: heads.to_vec(),
        }
    }

    pub fn to_state_vector(&self) -> StateVector {
        let mut sv = StateVector::new();
        for &(ref site, clock) in &self.state_vector {
            sv.set(*site, clock);
        }
        sv
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChangesMessage {
    pub changes: Vec<Change>,
    pub requires_ack: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AckMessage {
    pub acknowledged_hashes: Vec<ChangeHash>,
    pub current_state_vector: Vec<(SiteId, u64)>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AwarenessMessage {
    pub updates: Vec<AwarenessUpdate>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AwarenessUpdate {
    pub client_id: u64,
    pub state: Vec<u8>,
    pub timestamp: u64,
}
