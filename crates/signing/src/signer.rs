use ed25519_dalek::{Signer as _, SigningKey, VerifyingKey};
use rand::rngs::OsRng;
use serde::{Deserialize, Serialize};
use xanadu_types::{Author, AuthorId, Change, SignedChange};

#[derive(Debug)]
pub struct Signer {
    signing_key: SigningKey,
    author: Author,
}

impl Signer {
    pub fn generate(display_name: String) -> Self {
        let mut csprng = OsRng;
        let signing_key = SigningKey::generate(&mut csprng);
        let verifying_key = signing_key.verifying_key();
        let author = Author::new(&verifying_key, display_name, 0);
        Self { signing_key, author }
    }

    pub fn from_bytes(bytes: &[u8; 32], display_name: String, device_id: u64) -> Result<Self, ed25519_dalek::SignatureError> {
        let signing_key = SigningKey::from_bytes(bytes);
        let verifying_key = signing_key.verifying_key();
        let author = Author::new(&verifying_key, display_name, device_id);
        Ok(Self { signing_key, author })
    }

    pub fn author(&self) -> &Author {
        &self.author
    }

    pub fn author_id(&self) -> &AuthorId {
        self.author.id()
    }

    pub fn verifying_key(&self) -> VerifyingKey {
        self.signing_key.verifying_key()
    }

    pub fn sign_change(&self, change: Change) -> SignedChange {
        let payload = change.signing_payload();
        let signature = self.signing_key.sign(&payload);
        let signed = change.with_signature(signature);
        SignedChange::new(signed)
    }

    pub fn sign_bytes(&self, data: &[u8]) -> ed25519_dalek::Signature {
        self.signing_key.sign(data)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StoredKey {
    private_key_bytes: [u8; 32],
    display_name: String,
    device_id: u64,
}

impl StoredKey {
    pub fn from_signer(signer: &Signer) -> Self {
        Self {
            private_key_bytes: signer.signing_key.to_bytes(),
            display_name: signer.author.display_name().to_string(),
            device_id: signer.author.device_id(),
        }
    }

    pub fn load(&self) -> Result<Signer, ed25519_dalek::SignatureError> {
        Signer::from_bytes(&self.private_key_bytes, self.display_name.clone(), self.device_id)
    }

    pub fn serialize(&self) -> Vec<u8> {
        bincode::serialize(self).unwrap_or_default()
    }

    pub fn deserialize(data: &[u8]) -> Result<Self, Box<bincode::ErrorKind>> {
        bincode::deserialize(data)
    }
}
