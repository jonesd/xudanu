use std::collections::HashMap;

use ed25519_dalek::VerifyingKey;
use xudanu_signing::Signer;
use xudanu_types::*;

use crate::Document;

#[derive(Debug, thiserror::Error)]
pub enum VerificationError {
    #[error("missing signature on change from {0:?}")]
    MissingSignature(AuthorId),
    #[error("signature verification failed for change {0:?}")]
    InvalidSignature(ChangeHash),
    #[error("unknown author {0:?} — register their public key first")]
    UnknownAuthor(AuthorId),
    #[error("author {0:?} key has been revoked")]
    AuthorRevoked(AuthorId),
}

pub struct SignedDocument {
    doc: Document,
    signer: Signer,
    known_keys: HashMap<AuthorId, VerifyingKey>,
}

impl SignedDocument {
    pub fn new(id: DocumentId, signer: Signer, site: SiteId) -> Self {
        let author = signer.author().clone();
        let verifying_key = signer.verifying_key();
        let mut known_keys = HashMap::new();
        known_keys.insert(*author.id(), verifying_key);

        let doc = Document::new(id, author, site);

        Self {
            doc,
            signer,
            known_keys,
        }
    }

    pub fn register_author(&mut self, author: &Author) {
        if let Ok(vk) = author.verifying_key() {
            self.known_keys.insert(*author.id(), vk);
        }
    }

    pub fn insert(&mut self, index: usize, text: impl Into<String>) {
        self.doc.insert(index, text)
    }

    pub fn delete(&mut self, index: usize, len: usize) {
        self.doc.delete(index, len)
    }

    pub fn to_string(&self) -> String {
        self.doc.to_string()
    }

    pub fn len(&self) -> usize {
        self.doc.len()
    }

    pub fn is_empty(&self) -> bool {
        self.doc.is_empty()
    }

    pub fn commit_signed_change(&mut self) -> Option<SignedChange> {
        let change = self.doc.commit_change()?;
        Some(self.signer.sign_change(change))
    }

    pub fn integrate_signed_change(
        &mut self,
        signed: &SignedChange,
    ) -> Result<(), VerificationError> {
        let change = &signed.change;

        let vk = self
            .known_keys
            .get(&change.actor)
            .ok_or(VerificationError::UnknownAuthor(change.actor))?;

        if change.signature.is_none() {
            return Err(VerificationError::MissingSignature(change.actor));
        }

        if !change.verify_signature(vk) {
            return Err(VerificationError::InvalidSignature(change.id));
        }

        self.doc.integrate_change(change);
        Ok(())
    }

    pub fn iter_visible(&self) -> impl Iterator<Item = (&ItemId, &ItemContent, &AuthorId)> {
        self.doc.iter_visible()
    }

    pub fn state_vector(&self) -> &crate::state_vector::StateVector {
        self.doc.state_vector()
    }

    pub fn signer(&self) -> &Signer {
        &self.signer
    }

    pub fn inner(&self) -> &Document {
        &self.doc
    }

    pub fn inner_mut(&mut self) -> &mut Document {
        &mut self.doc
    }
}
