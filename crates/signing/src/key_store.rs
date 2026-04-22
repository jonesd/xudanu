use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use xudanu_types::{Author, AuthorId, HybridTimestamp};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KeyStore {
    keys: HashMap<AuthorId, KeyEntry>,
    revocation_log: Vec<RevocationEntry>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct KeyEntry {
    author: Author,
    first_seen: HybridTimestamp,
    last_seen: HybridTimestamp,
    revoked: bool,
    revoked_at: Option<HybridTimestamp>,
    predecessor: Option<AuthorId>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct RevocationEntry {
    revoked_key: AuthorId,
    successor_key: AuthorId,
    timestamp: HybridTimestamp,
    signature_valid: bool,
}

impl KeyStore {
    pub fn new() -> Self {
        Self {
            keys: HashMap::new(),
            revocation_log: Vec::new(),
        }
    }

    pub fn register_author(&mut self, author: Author, timestamp: HybridTimestamp) {
        let entry = KeyEntry {
            author,
            first_seen: timestamp,
            last_seen: timestamp,
            revoked: false,
            revoked_at: None,
            predecessor: None,
        };
        self.keys.insert(*entry.author.id(), entry);
    }

    pub fn is_known(&self, author_id: &AuthorId) -> bool {
        self.keys.contains_key(author_id)
    }

    pub fn is_revoked(&self, author_id: &AuthorId) -> bool {
        self.keys.get(author_id).map(|e| e.revoked).unwrap_or(false)
    }

    pub fn get_author(&self, author_id: &AuthorId) -> Option<&Author> {
        self.keys.get(author_id).map(|e| &e.author)
    }

    pub fn revoke_key(
        &mut self,
        old_key: &AuthorId,
        new_key: &AuthorId,
        timestamp: HybridTimestamp,
    ) -> Result<(), String> {
        let old_entry = self.keys.get_mut(old_key).ok_or("old key not found")?;
        old_entry.revoked = true;
        old_entry.revoked_at = Some(timestamp);

        if let Some(new_entry) = self.keys.get_mut(new_key) {
            new_entry.predecessor = Some(*old_key);
        }

        self.revocation_log.push(RevocationEntry {
            revoked_key: *old_key,
            successor_key: *new_key,
            timestamp,
            signature_valid: true,
        });

        Ok(())
    }

    pub fn key_chain_for(&self, author_id: &AuthorId) -> Vec<AuthorId> {
        let mut chain = vec![*author_id];
        let mut current = author_id;

        while let Some(entry) = self.keys.get(current) {
            if let Some(pred) = &entry.predecessor {
                chain.push(*pred);
                current = pred;
            } else {
                break;
            }
        }

        chain
    }

    pub fn active_authors(&self) -> Vec<&Author> {
        self.keys
            .values()
            .filter(|e| !e.revoked)
            .map(|e| &e.author)
            .collect()
    }
}
