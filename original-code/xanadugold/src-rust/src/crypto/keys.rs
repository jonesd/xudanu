use std::time::{SystemTime, UNIX_EPOCH};

use base64::{engine::general_purpose::STANDARD as BASE64, Engine as _};
use ed25519_dalek::{Signature, SigningKey, VerifyingKey};
use rand::rngs::OsRng;
use rand::RngCore;
use x25519_dalek::{PublicKey, StaticSecret};
use zeroize::Zeroize;

use super::aead::{self, SealedEnvelope};
use super::sign::{generate_signing_key, sign_bytes, verify_signature};

pub type KeyId = u64;

fn now_secs() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

#[derive(Debug, Clone)]
pub struct ServerIdentity {
    pub server_id: String,
    pub signing_key: VerifyingKey,
    pub kex_public: PublicKey,
    pub federation_domain: String,
}

impl ServerIdentity {
    pub fn from_keypair(keypair: &ServerKeyPair) -> Self {
        ServerIdentity {
            server_id: keypair.identity_id(),
            signing_key: keypair.signing_key.verifying_key(),
            kex_public: keypair.kex_public(),
            federation_domain: super::FEDERATION_DOMAIN.to_string(),
        }
    }

    pub fn signing_key_bytes(&self) -> [u8; 32] {
        self.signing_key.to_bytes()
    }

    pub fn kex_public_bytes(&self) -> [u8; 32] {
        *self.kex_public.as_bytes()
    }
}

#[derive(Clone)]
pub struct ServerKeyPair {
    pub key_id: KeyId,
    pub signing_key: SigningKey,
    pub kex_secret: StaticSecret,
    pub created_at: u64,
    pub not_before: u64,
    pub not_after: Option<u64>,
    pub is_active: bool,
}

impl ServerKeyPair {
    pub fn generate(_server_id: &str) -> Self {
        let signing_key = generate_signing_key();
        let mut kex_bytes = [0u8; 32];
        OsRng.fill_bytes(&mut kex_bytes);
        let kex_secret = StaticSecret::from(kex_bytes);
        kex_bytes.zeroize();
        let now = now_secs();
        ServerKeyPair {
            key_id: derive_key_id(&signing_key),
            signing_key,
            kex_secret,
            created_at: now,
            not_before: now,
            not_after: None,
            is_active: true,
        }
    }

    pub fn identity_id(&self) -> String {
        let vk = self.signing_key.verifying_key();
        let bytes = vk.to_bytes();
        hex_encode(&bytes[..8])
    }

    pub fn kex_public(&self) -> PublicKey {
        PublicKey::from(&self.kex_secret)
    }

    pub fn signing_verifying_key(&self) -> VerifyingKey {
        self.signing_key.verifying_key()
    }

    pub fn sign_rotation(&self, new_keypair: &ServerKeyPair) -> SignedKeyRotation {
        let rotation = KeyRotationPayload {
            old_key_id: self.key_id,
            new_key_id: new_keypair.key_id,
            new_signing_key: new_keypair.signing_key.verifying_key().to_bytes(),
            new_kex_public: *new_keypair.kex_public().as_bytes(),
            timestamp: now_secs(),
            federation_domain: super::FEDERATION_DOMAIN.to_string(),
        };
        let payload_bytes = rotation.encode();
        let signature = sign_bytes(&self.signing_key, &payload_bytes);
        SignedKeyRotation {
            payload: rotation,
            signature,
        }
    }

    pub fn expires_in(&self, secs: u64) -> Self {
        let mut kp = self.clone();
        kp.not_after = Some(now_secs() + secs);
        kp
    }
}

impl Drop for ServerKeyPair {
    fn drop(&mut self) {
        self.signing_key.to_bytes().zeroize();
        // kex_secret (StaticSecret) zeroizes via its own Drop impl in x25519-dalek
    }
}

fn derive_key_id(signing_key: &SigningKey) -> KeyId {
    let bytes = signing_key.verifying_key().to_bytes();
    let hash = blake3::hash(&bytes);
    let mut id_bytes = [0u8; 8];
    id_bytes.copy_from_slice(&hash.as_bytes()[..8]);
    u64::from_be_bytes(id_bytes)
}

#[derive(Debug, Clone)]
pub struct KeyRotationPayload {
    pub old_key_id: KeyId,
    pub new_key_id: KeyId,
    pub new_signing_key: [u8; 32],
    pub new_kex_public: [u8; 32],
    pub timestamp: u64,
    pub federation_domain: String,
}

impl KeyRotationPayload {
    pub fn encode(&self) -> Vec<u8> {
        let mut buf = Vec::with_capacity(8 + 8 + 32 + 32 + 8 + self.federation_domain.len());
        buf.extend_from_slice(&self.old_key_id.to_be_bytes());
        buf.extend_from_slice(&self.new_key_id.to_be_bytes());
        buf.extend_from_slice(&self.new_signing_key);
        buf.extend_from_slice(&self.new_kex_public);
        buf.extend_from_slice(&self.timestamp.to_be_bytes());
        buf.extend_from_slice(self.federation_domain.as_bytes());
        buf
    }

    pub fn decode(data: &[u8]) -> Option<Self> {
        if data.len() < 8 + 8 + 32 + 32 + 8 {
            return None;
        }
        let old_key_id = KeyId::from_be_bytes(data[0..8].try_into().ok()?);
        let new_key_id = KeyId::from_be_bytes(data[8..16].try_into().ok()?);
        let new_signing_key: [u8; 32] = data[16..48].try_into().ok()?;
        let new_kex_public: [u8; 32] = data[48..80].try_into().ok()?;
        let timestamp = u64::from_be_bytes(data[80..88].try_into().ok()?);
        let federation_domain = String::from_utf8_lossy(&data[88..]).to_string();
        Some(KeyRotationPayload {
            old_key_id,
            new_key_id,
            new_signing_key,
            new_kex_public,
            timestamp,
            federation_domain,
        })
    }
}

#[derive(Debug, Clone)]
pub struct SignedKeyRotation {
    pub payload: KeyRotationPayload,
    pub signature: Signature,
}

impl SignedKeyRotation {
    pub fn verify(&self, old_signing_key: &VerifyingKey) -> Result<(), String> {
        let payload_bytes = self.payload.encode();
        verify_signature(old_signing_key, &payload_bytes, &self.signature)
            .map_err(|_| "key rotation signature verification failed".to_string())
    }
}

#[derive(Debug, Clone)]
pub struct KeyHistoryEntry {
    pub key_id: KeyId,
    pub verifying_key: VerifyingKey,
    pub kex_public: PublicKey,
    pub not_before: u64,
    pub not_after: Option<u64>,
}

#[derive(Debug, Clone)]
pub struct KeyHistory {
    pub server_id: String,
    pub entries: Vec<KeyHistoryEntry>,
    pub rotation_proofs: Vec<SignedKeyRotation>,
    pub current_key_id: KeyId,
}

impl KeyHistory {
    pub fn new(keypair: &ServerKeyPair) -> Self {
        let entry = KeyHistoryEntry {
            key_id: keypair.key_id,
            verifying_key: keypair.signing_key.verifying_key(),
            kex_public: keypair.kex_public(),
            not_before: keypair.not_before,
            not_after: keypair.not_after,
        };
        KeyHistory {
            server_id: keypair.identity_id(),
            entries: vec![entry],
            rotation_proofs: Vec::new(),
            current_key_id: keypair.key_id,
        }
    }

    pub fn rotate(
        &mut self,
        old_keypair: &ServerKeyPair,
        new_keypair: &ServerKeyPair,
    ) -> Result<KeyId, String> {
        if old_keypair.key_id != self.current_key_id {
            return Err("old keypair is not the current key".to_string());
        }
        let proof = old_keypair.sign_rotation(new_keypair);
        proof.verify(&old_keypair.signing_key.verifying_key())?;
        let entry = KeyHistoryEntry {
            key_id: new_keypair.key_id,
            verifying_key: new_keypair.signing_key.verifying_key(),
            kex_public: new_keypair.kex_public(),
            not_before: new_keypair.not_before,
            not_after: new_keypair.not_after,
        };
        self.entries.push(entry);
        self.rotation_proofs.push(proof);
        self.current_key_id = new_keypair.key_id;
        Ok(new_keypair.key_id)
    }

    pub fn current(&self) -> Option<&KeyHistoryEntry> {
        self.entries
            .iter()
            .find(|e| e.key_id == self.current_key_id)
    }

    pub fn get(&self, key_id: KeyId) -> Option<&KeyHistoryEntry> {
        self.entries.iter().find(|e| e.key_id == key_id)
    }

    pub fn verify_rotation_chain(&self) -> Result<(), String> {
        if self.rotation_proofs.is_empty() {
            return Ok(());
        }
        for (i, proof) in self.rotation_proofs.iter().enumerate() {
            let prev_vk = if i == 0 {
                self.entries
                    .first()
                    .ok_or("no entries in history")?
                    .verifying_key
            } else {
                VerifyingKey::from_bytes(&self.rotation_proofs[i - 1].payload.new_signing_key)
                    .map_err(|_| "invalid previous signing key bytes".to_string())?
            };
            proof.verify(&prev_vk)?;
        }
        Ok(())
    }

    pub fn entry_count(&self) -> usize {
        self.entries.len()
    }

    pub fn is_key_valid_at(&self, key_id: KeyId, timestamp: u64) -> bool {
        if let Some(entry) = self.get(key_id) {
            if timestamp < entry.not_before {
                return false;
            }
            if let Some(na) = entry.not_after {
                if timestamp > na {
                    return false;
                }
            }
            return true;
        }
        false
    }
}

pub fn hex_encode(data: &[u8]) -> String {
    data.iter().map(|b| format!("{:02x}", b)).collect()
}

pub fn hex_decode(hex_str: &str) -> Result<Vec<u8>, String> {
    if hex_str.len() % 2 != 0 {
        return Err("Hex string must have even length".to_string());
    }
    (0..hex_str.len())
        .step_by(2)
        .map(|i| u8::from_str_radix(&hex_str[i..i + 2], 16))
        .collect::<Result<Vec<u8>, _>>()
        .map_err(|e| format!("Invalid hex character: {}", e))
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct KeypairFile {
    signing_key_bytes: [u8; 32],
    kex_secret_bytes: [u8; 32],
    key_id: KeyId,
    created_at: u64,
    not_before: u64,
    not_after: Option<u64>,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct KeypairFileV2 {
    pub version: u8,
    pub salt: String,
    pub envelope: String,
    pub integrity: String,
}

#[derive(Debug)]
pub enum KeypairFileError {
    Io(std::io::Error),
    Json(serde_json::Error),
    Encryption(aead::AeadError),
    Decryption(aead::AeadError),
    WrongPassphrase,
    CorruptIntegrity,
    InvalidFormat,
}

impl std::fmt::Display for KeypairFileError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            KeypairFileError::Io(e) => write!(f, "I/O error: {}", e),
            KeypairFileError::Json(e) => write!(f, "JSON error: {}", e),
            KeypairFileError::Encryption(e) => write!(f, "encryption failed: {}", e),
            KeypairFileError::Decryption(e) => write!(f, "decryption failed: {}", e),
            KeypairFileError::WrongPassphrase => write!(f, "wrong passphrase or corrupt key file"),
            KeypairFileError::CorruptIntegrity => {
                write!(f, "key file integrity check failed (corrupt or tampered)")
            }
            KeypairFileError::InvalidFormat => write!(f, "invalid key file format"),
        }
    }
}

impl std::error::Error for KeypairFileError {}

impl From<std::io::Error> for KeypairFileError {
    fn from(e: std::io::Error) -> Self {
        KeypairFileError::Io(e)
    }
}

impl From<serde_json::Error> for KeypairFileError {
    fn from(e: serde_json::Error) -> Self {
        KeypairFileError::Json(e)
    }
}

const KEYFILE_V2: u8 = 2;

fn derive_keyfile_key(passphrase: &[u8], salt: &[u8; 32]) -> [u8; 32] {
    let params = argon2::Params::new(19456, 2, 1, Some(32)).expect("valid argon2 params");
    let argon2 = argon2::Argon2::new(argon2::Algorithm::Argon2id, argon2::Version::V0x13, params);
    let mut key = [0u8; 32];
    argon2
        .hash_password_into(passphrase, salt, &mut key)
        .expect("argon2 derivation should not fail with valid params");
    key
}

impl ServerKeyPair {
    pub fn save_to_file(&self, path: &std::path::Path) -> std::io::Result<()> {
        let file = KeypairFile {
            signing_key_bytes: self.signing_key.to_bytes(),
            kex_secret_bytes: self.kex_secret.to_bytes(),
            key_id: self.key_id,
            created_at: self.created_at,
            not_before: self.not_before,
            not_after: self.not_after,
        };
        let json = serde_json::to_string(&file)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
        let tmp_path = path.with_extension("keytmp");
        std::fs::write(&tmp_path, json.as_bytes())?;
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            std::fs::set_permissions(&tmp_path, std::fs::Permissions::from_mode(0o600))?;
        }
        std::fs::rename(&tmp_path, path)
    }

    pub fn save_to_file_encrypted(
        &self,
        path: &std::path::Path,
        passphrase: &[u8],
    ) -> Result<(), KeypairFileError> {
        let mut plaintext = Vec::with_capacity(32 + 32 + 8 + 8 + 8 + 1);
        plaintext.extend_from_slice(&self.signing_key.to_bytes());
        plaintext.extend_from_slice(&self.kex_secret.to_bytes());
        plaintext.extend_from_slice(&self.key_id.to_be_bytes());
        plaintext.extend_from_slice(&self.created_at.to_be_bytes());
        plaintext.extend_from_slice(&self.not_before.to_be_bytes());
        if let Some(na) = self.not_after {
            plaintext.push(1u8);
            plaintext.extend_from_slice(&na.to_be_bytes());
        } else {
            plaintext.push(0u8);
        }

        let mut salt = [0u8; 32];
        OsRng.fill_bytes(&mut salt);
        let key = derive_keyfile_key(passphrase, &salt);

        let envelope = aead::seal_standalone(&key, &plaintext, b"xudanu-server-key", 0)
            .map_err(KeypairFileError::Encryption)?;

        let envelope_bytes = envelope.encode();
        let mut integrity_input = Vec::with_capacity(32 + envelope_bytes.len());
        integrity_input.extend_from_slice(&salt);
        integrity_input.extend_from_slice(&envelope_bytes);
        let integrity = blake3::hash(&integrity_input).to_hex().to_string();

        let v2 = KeypairFileV2 {
            version: KEYFILE_V2,
            salt: BASE64.encode(salt),
            envelope: BASE64.encode(&envelope_bytes),
            integrity,
        };

        let json = serde_json::to_string(&v2)?;
        let tmp_path = path.with_extension("keytmp");
        std::fs::write(&tmp_path, json.as_bytes())?;
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            std::fs::set_permissions(&tmp_path, std::fs::Permissions::from_mode(0o600))
                .map_err(KeypairFileError::Io)?;
        }
        std::fs::rename(&tmp_path, path)?;
        Ok(())
    }

    pub fn load_from_file(path: &std::path::Path) -> std::io::Result<Self> {
        let json = std::fs::read_to_string(path)?;
        let file: KeypairFile = serde_json::from_str(&json)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
        let signing_key = SigningKey::from_bytes(&file.signing_key_bytes);
        let kex_secret = StaticSecret::from(file.kex_secret_bytes);
        Ok(ServerKeyPair {
            key_id: file.key_id,
            signing_key,
            kex_secret,
            created_at: file.created_at,
            not_before: file.not_before,
            not_after: file.not_after,
            is_active: true,
        })
    }

    pub fn load_from_file_with_passphrase(
        path: &std::path::Path,
        passphrase: &[u8],
    ) -> Result<Self, KeypairFileError> {
        let json = std::fs::read_to_string(path)?;

        if let Ok(v2) = serde_json::from_str::<KeypairFileV2>(&json) {
            if v2.version != KEYFILE_V2 {
                return Err(KeypairFileError::InvalidFormat);
            }

            let salt: [u8; 32] = BASE64
                .decode(&v2.salt)
                .map_err(|_| KeypairFileError::InvalidFormat)?
                .try_into()
                .map_err(|_| KeypairFileError::InvalidFormat)?;

            let envelope_bytes = BASE64
                .decode(&v2.envelope)
                .map_err(|_| KeypairFileError::InvalidFormat)?;

            let mut integrity_input = Vec::with_capacity(32 + envelope_bytes.len());
            integrity_input.extend_from_slice(&salt);
            integrity_input.extend_from_slice(&envelope_bytes);
            let expected = blake3::hash(&integrity_input).to_hex().to_string();
            if !constant_time_eq(&expected, &v2.integrity) {
                return Err(KeypairFileError::CorruptIntegrity);
            }

            let envelope =
                SealedEnvelope::decode(&envelope_bytes).map_err(KeypairFileError::Decryption)?;
            let key = derive_keyfile_key(passphrase, &salt);
            let plaintext = aead::open_standalone(&key, &envelope, b"xudanu-server-key")
                .map_err(|_| KeypairFileError::WrongPassphrase)?;

            if plaintext.len() < 32 + 32 + 8 + 8 + 8 + 1 {
                return Err(KeypairFileError::InvalidFormat);
            }
            let signing_key_bytes: [u8; 32] = plaintext[0..32]
                .try_into()
                .map_err(|_| KeypairFileError::InvalidFormat)?;
            let kex_secret_bytes: [u8; 32] = plaintext[32..64]
                .try_into()
                .map_err(|_| KeypairFileError::InvalidFormat)?;
            let key_id = KeyId::from_be_bytes(
                plaintext[64..72]
                    .try_into()
                    .map_err(|_| KeypairFileError::InvalidFormat)?,
            );
            let created_at = u64::from_be_bytes(
                plaintext[72..80]
                    .try_into()
                    .map_err(|_| KeypairFileError::InvalidFormat)?,
            );
            let not_before = u64::from_be_bytes(
                plaintext[80..88]
                    .try_into()
                    .map_err(|_| KeypairFileError::InvalidFormat)?,
            );
            let has_not_after = plaintext[88];
            let not_after = if has_not_after == 1 {
                if plaintext.len() < 89 + 8 {
                    return Err(KeypairFileError::InvalidFormat);
                }
                Some(u64::from_be_bytes(
                    plaintext[89..97]
                        .try_into()
                        .map_err(|_| KeypairFileError::InvalidFormat)?,
                ))
            } else {
                None
            };

            let signing_key = SigningKey::from_bytes(&signing_key_bytes);
            let kex_secret = StaticSecret::from(kex_secret_bytes);

            return Ok(ServerKeyPair {
                key_id,
                signing_key,
                kex_secret,
                created_at,
                not_before,
                not_after,
                is_active: true,
            });
        }

        if let Ok(v1) = serde_json::from_str::<KeypairFile>(&json) {
            let signing_key = SigningKey::from_bytes(&v1.signing_key_bytes);
            let kex_secret = StaticSecret::from(v1.kex_secret_bytes);
            return Ok(ServerKeyPair {
                key_id: v1.key_id,
                signing_key,
                kex_secret,
                created_at: v1.created_at,
                not_before: v1.not_before,
                not_after: v1.not_after,
                is_active: true,
            });
        }

        Err(KeypairFileError::InvalidFormat)
    }

    pub fn load_from_file_auto(
        path: &std::path::Path,
        passphrase: Option<&[u8]>,
    ) -> Result<Self, KeypairFileError> {
        let json = std::fs::read_to_string(path)?;
        if let Ok(_v2) = serde_json::from_str::<KeypairFileV2>(&json) {
            let pass = passphrase.ok_or(KeypairFileError::WrongPassphrase)?;
            return Self::load_from_file_with_passphrase(path, pass);
        }
        tracing::warn!(
            "Server key file is unencrypted (v1 format). Consider migrating with --key-passphrase."
        );
        Self::load_from_file(path).map_err(KeypairFileError::Io)
    }
}

fn constant_time_eq(a: &str, b: &str) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let a_bytes = a.as_bytes();
    let b_bytes = b.as_bytes();
    let mut result = 0u8;
    for i in 0..a_bytes.len() {
        result |= a_bytes[i] ^ b_bytes[i];
    }
    result == 0
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct KeyHistoryEntryFile {
    key_id: KeyId,
    verifying_key_bytes: [u8; 32],
    kex_public_bytes: [u8; 32],
    not_before: u64,
    not_after: Option<u64>,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SignedKeyRotationFile {
    payload_bytes: Vec<u8>,
    signature_bytes: Vec<u8>,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct KeyHistoryFile {
    pub server_id: String,
    pub entries: Vec<KeyHistoryEntryFile>,
    pub rotation_proofs: Vec<SignedKeyRotationFile>,
    pub current_key_id: KeyId,
}

impl KeyHistory {
    pub fn to_file_repr(&self) -> KeyHistoryFile {
        KeyHistoryFile {
            server_id: self.server_id.clone(),
            entries: self
                .entries
                .iter()
                .map(|e| KeyHistoryEntryFile {
                    key_id: e.key_id,
                    verifying_key_bytes: e.verifying_key.to_bytes(),
                    kex_public_bytes: *e.kex_public.as_bytes(),
                    not_before: e.not_before,
                    not_after: e.not_after,
                })
                .collect(),
            rotation_proofs: self
                .rotation_proofs
                .iter()
                .map(|r| SignedKeyRotationFile {
                    payload_bytes: r.payload.encode(),
                    signature_bytes: r.signature.to_bytes().to_vec(),
                })
                .collect(),
            current_key_id: self.current_key_id,
        }
    }

    pub fn from_file_repr(file: &KeyHistoryFile) -> Result<Self, String> {
        let entries: Result<Vec<_>, String> = file
            .entries
            .iter()
            .map(|e| {
                let verifying_key = VerifyingKey::from_bytes(&e.verifying_key_bytes)
                    .map_err(|_| "invalid verifying key bytes in key history".to_string())?;
                let kex_public = PublicKey::from(e.kex_public_bytes);
                Ok(KeyHistoryEntry {
                    key_id: e.key_id,
                    verifying_key,
                    kex_public,
                    not_before: e.not_before,
                    not_after: e.not_after,
                })
            })
            .collect();
        let rotation_proofs: Result<Vec<_>, String> = file
            .rotation_proofs
            .iter()
            .map(|r| {
                let payload = KeyRotationPayload::decode(&r.payload_bytes)
                    .ok_or("invalid key rotation payload in key history".to_string())?;
                let sig_bytes: [u8; 64] = r
                    .signature_bytes
                    .clone()
                    .try_into()
                    .map_err(|_| "invalid signature length in key history".to_string())?;
                let signature = Signature::from_bytes(&sig_bytes);
                Ok(SignedKeyRotation { payload, signature })
            })
            .collect();
        Ok(KeyHistory {
            server_id: file.server_id.clone(),
            entries: entries?,
            rotation_proofs: rotation_proofs?,
            current_key_id: file.current_key_id,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn generate_keypair() {
        let kp = ServerKeyPair::generate("test-server");
        assert!(kp.key_id > 0);
        assert!(!kp.identity_id().is_empty());
        assert!(kp.is_active);
    }

    #[test]
    fn identity_id_is_stable() {
        let kp = ServerKeyPair::generate("test-server");
        let id1 = kp.identity_id();
        let id2 = kp.identity_id();
        assert_eq!(id1, id2);
    }

    #[test]
    fn different_keys_have_different_ids() {
        let a = ServerKeyPair::generate("test-server");
        let b = ServerKeyPair::generate("test-server");
        assert_ne!(a.key_id, b.key_id);
        assert_ne!(a.identity_id(), b.identity_id());
    }

    #[test]
    fn key_rotation_signs_and_verifies() {
        let old = ServerKeyPair::generate("test-server");
        let new = ServerKeyPair::generate("test-server");
        let proof = old.sign_rotation(&new);
        assert!(proof.verify(&old.signing_verifying_key()).is_ok());
    }

    #[test]
    fn key_rotation_rejects_wrong_key() {
        let old = ServerKeyPair::generate("test-server");
        let new = ServerKeyPair::generate("test-server");
        let other = ServerKeyPair::generate("test-server");
        let proof = old.sign_rotation(&new);
        assert!(proof.verify(&other.signing_verifying_key()).is_err());
    }

    #[test]
    fn key_history_new() {
        let kp = ServerKeyPair::generate("test-server");
        let history = KeyHistory::new(&kp);
        assert_eq!(history.entry_count(), 1);
        assert_eq!(history.current_key_id, kp.key_id);
        assert!(history.current().is_some());
    }

    #[test]
    fn key_history_rotate() {
        let old = ServerKeyPair::generate("test-server");
        let mut history = KeyHistory::new(&old);
        let new = ServerKeyPair::generate("test-server");
        let new_id = history.rotate(&old, &new).unwrap();
        assert_eq!(new_id, new.key_id);
        assert_eq!(history.current_key_id, new.key_id);
        assert_eq!(history.entry_count(), 2);
        assert_eq!(history.rotation_proofs.len(), 1);
    }

    #[test]
    fn key_history_rejects_wrong_old_key() {
        let kp1 = ServerKeyPair::generate("test-server");
        let kp2 = ServerKeyPair::generate("test-server");
        let kp3 = ServerKeyPair::generate("test-server");
        let mut history = KeyHistory::new(&kp1);
        let result = history.rotate(&kp2, &kp3);
        assert!(result.is_err());
    }

    #[test]
    fn key_history_verify_chain() {
        let kp1 = ServerKeyPair::generate("test-server");
        let kp2 = ServerKeyPair::generate("test-server");
        let kp3 = ServerKeyPair::generate("test-server");
        let mut history = KeyHistory::new(&kp1);
        history.rotate(&kp1, &kp2).unwrap();
        history.rotate(&kp2, &kp3).unwrap();
        assert!(history.verify_rotation_chain().is_ok());
    }

    #[test]
    fn key_history_tampered_chain_fails() {
        let kp1 = ServerKeyPair::generate("test-server");
        let kp2 = ServerKeyPair::generate("test-server");
        let mut history = KeyHistory::new(&kp1);
        let proof = kp1.sign_rotation(&kp2);
        let mut tampered = proof.clone();
        tampered.payload.new_key_id ^= 0xff;
        history.rotation_proofs.push(tampered);
        history.entries.push(KeyHistoryEntry {
            key_id: 999,
            verifying_key: kp2.signing_verifying_key(),
            kex_public: kp2.kex_public(),
            not_before: 0,
            not_after: None,
        });
        assert!(history.verify_rotation_chain().is_err());
    }

    #[test]
    fn key_history_is_key_valid_at() {
        let kp = ServerKeyPair::generate("test-server");
        let now = now_secs();
        let history = KeyHistory::new(&kp);
        assert!(history.is_key_valid_at(kp.key_id, now));
        assert!(!history.is_key_valid_at(kp.key_id, 0));
        assert!(!history.is_key_valid_at(99999, now));
    }

    #[test]
    fn key_rotation_payload_encode_decode() {
        let old = ServerKeyPair::generate("test-server");
        let new = ServerKeyPair::generate("test-server");
        let proof = old.sign_rotation(&new);
        let encoded = proof.payload.encode();
        let decoded = KeyRotationPayload::decode(&encoded).unwrap();
        assert_eq!(decoded.old_key_id, proof.payload.old_key_id);
        assert_eq!(decoded.new_key_id, proof.payload.new_key_id);
        assert_eq!(decoded.new_signing_key, proof.payload.new_signing_key);
        assert_eq!(decoded.new_kex_public, proof.payload.new_kex_public);
    }

    #[test]
    fn expires_in_sets_not_after() {
        let kp = ServerKeyPair::generate("test-server");
        let expiring = kp.expires_in(3600);
        assert!(expiring.not_after.is_some());
        let na = expiring.not_after.unwrap();
        assert!(na > kp.created_at);
    }

    #[test]
    fn server_identity_from_keypair() {
        let kp = ServerKeyPair::generate("test-server");
        let identity = ServerIdentity::from_keypair(&kp);
        assert_eq!(identity.server_id, kp.identity_id());
        assert_eq!(identity.signing_key_bytes().len(), 32);
        assert_eq!(identity.kex_public_bytes().len(), 32);
        assert_eq!(identity.federation_domain, "xudanu");
    }

    #[test]
    fn encrypted_keyfile_roundtrip() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("server.key");
        let kp = ServerKeyPair::generate("test-server");
        let original_id = kp.identity_id();
        let original_key_id = kp.key_id;

        kp.save_to_file_encrypted(&path, b"correct-password")
            .unwrap();

        let loaded =
            ServerKeyPair::load_from_file_with_passphrase(&path, b"correct-password").unwrap();
        assert_eq!(loaded.identity_id(), original_id);
        assert_eq!(loaded.key_id, original_key_id);
        assert_eq!(loaded.created_at, kp.created_at);
    }

    #[test]
    fn encrypted_keyfile_wrong_password() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("server.key");
        let kp = ServerKeyPair::generate("test-server");
        kp.save_to_file_encrypted(&path, b"correct").unwrap();

        let result = ServerKeyPair::load_from_file_with_passphrase(&path, b"wrong");
        assert!(matches!(result, Err(KeypairFileError::WrongPassphrase)));
    }

    #[test]
    fn encrypted_keyfile_with_not_after() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("server.key");
        let kp = ServerKeyPair::generate("test-server").expires_in(3600);
        let original_not_after = kp.not_after;

        kp.save_to_file_encrypted(&path, b"pw").unwrap();
        let loaded = ServerKeyPair::load_from_file_with_passphrase(&path, b"pw").unwrap();
        assert_eq!(loaded.not_after, original_not_after);
    }

    #[test]
    fn v1_keyfile_loads_with_passphrase_method() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("server.key");
        let kp = ServerKeyPair::generate("test-server");
        kp.save_to_file(&path).unwrap();

        let loaded = ServerKeyPair::load_from_file_with_passphrase(&path, b"any").unwrap();
        assert_eq!(loaded.identity_id(), kp.identity_id());
    }

    #[test]
    fn auto_load_v1_without_passphrase() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("server.key");
        let kp = ServerKeyPair::generate("test-server");
        kp.save_to_file(&path).unwrap();

        let loaded = ServerKeyPair::load_from_file_auto(&path, None).unwrap();
        assert_eq!(loaded.identity_id(), kp.identity_id());
    }

    #[test]
    fn auto_load_v2_with_passphrase() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("server.key");
        let kp = ServerKeyPair::generate("test-server");
        kp.save_to_file_encrypted(&path, b"secret").unwrap();

        let loaded = ServerKeyPair::load_from_file_auto(&path, Some(b"secret")).unwrap();
        assert_eq!(loaded.identity_id(), kp.identity_id());
    }

    #[test]
    fn auto_load_v2_without_passphrase_fails() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("server.key");
        let kp = ServerKeyPair::generate("test-server");
        kp.save_to_file_encrypted(&path, b"secret").unwrap();

        let result = ServerKeyPair::load_from_file_auto(&path, None);
        assert!(matches!(result, Err(KeypairFileError::WrongPassphrase)));
    }

    #[test]
    fn encrypted_keyfile_integrity_check() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("server.key");
        let kp = ServerKeyPair::generate("test-server");
        kp.save_to_file_encrypted(&path, b"pw").unwrap();

        let json = std::fs::read_to_string(&path).unwrap();
        let mut v: serde_json::Value = serde_json::from_str(&json).unwrap();
        v["integrity"] = serde_json::Value::String("deadbeef".to_string());
        std::fs::write(&path, serde_json::to_string(&v).unwrap().as_bytes()).unwrap();

        let result = ServerKeyPair::load_from_file_with_passphrase(&path, b"pw");
        assert!(result.is_err());
    }

    #[test]
    fn encrypted_keyfile_file_permissions() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("server.key");
        let kp = ServerKeyPair::generate("test-server");
        kp.save_to_file_encrypted(&path, b"pw").unwrap();

        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            let mode = std::fs::metadata(&path).unwrap().permissions().mode();
            assert_eq!(mode & 0o777, 0o600);
        }
    }

    #[test]
    fn encrypted_keyfile_is_valid_json() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("server.key");
        let kp = ServerKeyPair::generate("test-server");
        kp.save_to_file_encrypted(&path, b"pw").unwrap();

        let json = std::fs::read_to_string(&path).unwrap();
        let v: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert_eq!(v["version"], 2);
        assert!(v["salt"].is_string());
        assert!(v["envelope"].is_string());
        assert!(v["integrity"].is_string());
    }
}
