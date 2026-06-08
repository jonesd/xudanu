use serde::{Deserialize, Serialize};

pub type AuthorId = [u8; 32];

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub struct Author {
    public_key_bytes: AuthorId,
    display_name: String,
    device_id: u64,
}

impl Author {
    pub fn new(
        public_key: &ed25519_dalek::VerifyingKey,
        display_name: String,
        device_id: u64,
    ) -> Self {
        Self {
            public_key_bytes: public_key.to_bytes(),
            display_name,
            device_id,
        }
    }

    pub fn verifying_key(
        &self,
    ) -> Result<ed25519_dalek::VerifyingKey, ed25519_dalek::SignatureError> {
        ed25519_dalek::VerifyingKey::from_bytes(&self.public_key_bytes)
    }

    pub fn public_key_bytes(&self) -> &AuthorId {
        &self.public_key_bytes
    }

    pub fn id(&self) -> &AuthorId {
        &self.public_key_bytes
    }

    pub fn display_name(&self) -> &str {
        &self.display_name
    }

    pub fn device_id(&self) -> u64 {
        self.device_id
    }

    pub fn fingerprint(&self) -> String {
        use sha2::{Digest, Sha256};
        let mut hasher = Sha256::new();
        hasher.update(&self.public_key_bytes);
        let hash = hasher.finalize();
        hex::encode(&hash[..8])
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize, Deserialize)]
pub struct SiteId(AuthorId);

impl SiteId {
    pub fn from_author(author: &Author) -> Self {
        let mut id = *author.id();
        let device_bytes = author.device_id().to_le_bytes();
        for (i, b) in device_bytes.iter().enumerate() {
            id[i % 32] ^= b;
        }
        SiteId(id)
    }

    pub fn from_bytes(bytes: [u8; 32]) -> Self {
        SiteId(bytes)
    }

    pub fn as_bytes(&self) -> &[u8; 32] {
        &self.0
    }

    pub fn short(&self) -> String {
        hex::encode(&self.0[..4])
    }
}

impl std::fmt::Display for SiteId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", hex::encode(&self.0[..8]))
    }
}
