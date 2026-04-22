use serde::{Deserialize, Serialize};

use crate::author::SiteId;
use crate::span::ChangeHash;
use crate::{AuthorId, HybridTimestamp, Op};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Change {
    pub id: ChangeHash,
    pub actor: AuthorId,
    pub site: SiteId,
    pub deps: Vec<ChangeHash>,
    pub operations: Vec<Op>,
    pub timestamp: HybridTimestamp,
    pub lamport: u64,
    pub signature: Option<ed25519_dalek::Signature>,
}

impl Change {
    pub fn unsigned(
        actor: AuthorId,
        site: SiteId,
        deps: Vec<ChangeHash>,
        operations: Vec<Op>,
        timestamp: HybridTimestamp,
        lamport: u64,
    ) -> Self {
        let mut change = Self {
            id: [0u8; 32],
            actor,
            site,
            deps,
            operations,
            timestamp,
            lamport,
            signature: None,
        };
        change.id = change.compute_hash();
        change
    }

    pub fn signing_payload(&self) -> Vec<u8> {
        bincode::serialize(&(
            &self.id,
            &self.actor,
            &self.site,
            &self.deps,
            &self.operations,
            &self.timestamp,
            &self.lamport,
        ))
        .unwrap_or_default()
    }

    fn compute_hash(&self) -> ChangeHash {
        use sha2::{Sha256, Digest};
        let mut hasher = Sha256::new();
        hasher.update(&self.actor);
        hasher.update(self.site.as_bytes());
        for dep in &self.deps {
            hasher.update(dep);
        }
        for op in &self.operations {
            hasher.update(bincode::serialize(op).unwrap_or_default());
        }
        hasher.update(self.timestamp.lamport.to_le_bytes());
        hasher.update(self.timestamp.wall_secs.to_le_bytes());
        hasher.update(self.timestamp.wall_nanos.to_le_bytes());
        let result = hasher.finalize();
        let mut hash = [0u8; 32];
        hash.copy_from_slice(&result);
        hash
    }

    pub fn with_signature(mut self, sig: ed25519_dalek::Signature) -> Self {
        self.signature = Some(sig);
        self
    }

    pub fn verify_signature(&self, public_key: &ed25519_dalek::VerifyingKey) -> bool {
        match &self.signature {
            Some(sig) => public_key
                .verify_strict(&self.signing_payload(), sig)
                .is_ok(),
            None => false,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SignedChange {
    pub change: Change,
    pub verified: bool,
}

impl SignedChange {
    pub fn new(change: Change) -> Self {
        Self {
            change,
            verified: false,
        }
    }

    pub fn verify(&mut self, public_key: &ed25519_dalek::VerifyingKey) -> bool {
        self.verified = self.change.verify_signature(public_key);
        self.verified
    }
}
