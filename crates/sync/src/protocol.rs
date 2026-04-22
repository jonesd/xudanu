use xanadu_core::state_vector::StateVector;
use xanadu_types::{Change, ChangeHash, SiteId};

use crate::message::{
    AckMessage, ChangesMessage, StateVectorMessage, SyncMessage, SyncMessageType,
};

#[derive(Debug)]
pub struct SyncProtocol {
    local_state_vector: StateVector,
    remote_state_vectors: std::collections::HashMap<SiteId, StateVector>,
    pending_changes: Vec<Change>,
    sent_changes_awaiting_ack: Vec<ChangeHash>,
}

impl SyncProtocol {
    pub fn new(local_sv: StateVector) -> Self {
        Self {
            local_state_vector: local_sv,
            remote_state_vectors: std::collections::HashMap::new(),
            pending_changes: Vec::new(),
            sent_changes_awaiting_ack: Vec::new(),
        }
    }

    pub fn create_sync_step1(&self, site: SiteId) -> SyncMessage {
        let heads: Vec<ChangeHash> = Vec::new();
        SyncMessage {
            message_type: SyncMessageType::StateVector(StateVectorMessage::from_state_vector(
                &self.local_state_vector,
                &heads,
            )),
            sender_site: site,
            sender_author: [0u8; 32],
        }
    }

    pub fn handle_sync_step1(
        &mut self,
        msg: &SyncMessage,
        local_changes: &[Change],
    ) -> SyncMessage {
        let remote_sv = match &msg.message_type {
            SyncMessageType::StateVector(sv_msg) => sv_msg.to_state_vector(),
            _ => return self.create_empty_ack(msg.sender_site, [0u8; 32]),
        };

        let missing_changes: Vec<Change> = local_changes
            .iter()
            .filter(|c| !remote_sv.knows(&c.site, c.id.iter().count() as u64))
            .cloned()
            .collect();

        self.remote_state_vectors.insert(msg.sender_site, remote_sv);

        SyncMessage {
            message_type: SyncMessageType::StateVector(
                StateVectorMessage::from_state_vector(&self.local_state_vector, &[]),
            ),
            sender_site: msg.sender_site,
            sender_author: msg.sender_author,
        }
    }

    pub fn handle_sync_step2(
        &mut self,
        msg: &SyncMessage,
        site: SiteId,
        author: [u8; 32],
        verify_fn: impl Fn(&Change) -> bool,
    ) -> Vec<Change> {
        let changes = match &msg.message_type {
            SyncMessageType::Changes(changes_msg) => &changes_msg.changes,
            _ => return Vec::new(),
        };

        let mut accepted = Vec::new();
        for change in changes {
            if !self.local_state_vector.knows(&change.site, change.lamport) {
                if verify_fn(change) {
                    self.local_state_vector.merge(
                        &{
                            let mut sv = StateVector::new();
                            sv.set(change.site, change.lamport);
                            sv
                        },
                    );
                    accepted.push(change.clone());
                }
            }
        }

        accepted
    }

    pub fn create_changes_message(
        &mut self,
        changes: Vec<Change>,
        site: SiteId,
        author: [u8; 32],
    ) -> SyncMessage {
        for c in &changes {
            self.sent_changes_awaiting_ack.push(c.id);
        }
        SyncMessage {
            message_type: SyncMessageType::Changes(ChangesMessage {
                changes,
                requires_ack: true,
            }),
            sender_site: site,
            sender_author: author,
        }
    }

    fn create_empty_ack(&self, site: SiteId, author: [u8; 32]) -> SyncMessage {
        SyncMessage {
            message_type: SyncMessageType::Ack(AckMessage {
                acknowledged_hashes: Vec::new(),
                current_state_vector: self.local_state_vector.iter().map(|(s, &c)| (*s, c)).collect(),
            }),
            sender_site: site,
            sender_author: author,
        }
    }

    pub fn local_state_vector(&self) -> &StateVector {
        &self.local_state_vector
    }

    pub fn update_local_state_vector(&mut self, sv: StateVector) {
        self.local_state_vector.merge(&sv);
    }
}
