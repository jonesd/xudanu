use chacha20poly1305::{
    aead::{Aead, KeyInit},
    ChaCha20Poly1305, Key, Nonce,
};
use zeroize::Zeroize;

use super::kdf::DomainLabel;

pub const NONCE_SIZE: usize = 12;
pub const TAG_SIZE: usize = 16;
pub const KEY_SIZE: usize = 32;
pub const ENVELOPE_OVERHEAD: usize = 1 + 8 + NONCE_SIZE + TAG_SIZE;

#[derive(Debug)]
pub enum AeadError {
    EncryptionFailed,
    DecryptionFailed,
    InvalidKeyLength,
    NonceOverflow,
    InvalidCiphertext,
}

impl std::fmt::Display for AeadError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            AeadError::EncryptionFailed => write!(f, "AEAD encryption failed"),
            AeadError::DecryptionFailed => {
                write!(f, "AEAD decryption failed (tampered or wrong key)")
            }
            AeadError::InvalidKeyLength => write!(f, "invalid key length (expected 32 bytes)"),
            AeadError::NonceOverflow => {
                write!(f, "nonce counter overflow — session must be re-keyed")
            }
            AeadError::InvalidCiphertext => write!(f, "ciphertext too short to be valid"),
        }
    }
}

impl std::error::Error for AeadError {}

#[derive(Debug, Clone)]
pub struct SealedEnvelope {
    pub version: u8,
    pub key_id: u64,
    pub counter: u64,
    pub ciphertext: Vec<u8>,
}

impl SealedEnvelope {
    pub fn encode(&self) -> Vec<u8> {
        let mut buf = Vec::with_capacity(1 + 8 + self.ciphertext.len());
        buf.push(self.version);
        buf.extend_from_slice(&self.key_id.to_be_bytes());
        buf.extend_from_slice(&self.counter.to_be_bytes());
        buf.extend_from_slice(&self.ciphertext);
        buf
    }

    pub fn decode(data: &[u8]) -> Result<Self, AeadError> {
        if data.len() < 1 + 8 + 8 {
            return Err(AeadError::InvalidCiphertext);
        }
        let version = data[0];
        let key_id = u64::from_be_bytes(data[1..9].try_into().unwrap());
        let counter = u64::from_be_bytes(data[9..17].try_into().unwrap());
        let ciphertext = data[17..].to_vec();
        Ok(SealedEnvelope {
            version,
            key_id,
            counter,
            ciphertext,
        })
    }
}

pub struct SessionCipher {
    key: [u8; KEY_SIZE],
    key_id: u64,
    counter: u64,
    direction_label: &'static str,
}

impl SessionCipher {
    pub fn new(key: [u8; KEY_SIZE], key_id: u64, label: &'static str) -> Self {
        SessionCipher {
            key,
            key_id,
            counter: 0,
            direction_label: label,
        }
    }

    pub fn seal(&mut self, plaintext: &[u8], aad: &[u8]) -> Result<SealedEnvelope, AeadError> {
        let nonce = self.compute_nonce()?;
        let cipher = ChaCha20Poly1305::new(Key::from_slice(&self.key));
        let full_aad = self.build_aad(aad);
        let mut payload = chacha20poly1305::aead::Payload::from(plaintext);
        payload.aad = &full_aad;
        let ciphertext = cipher
            .encrypt(Nonce::from_slice(&nonce), payload)
            .map_err(|_| AeadError::EncryptionFailed)?;
        let envelope = SealedEnvelope {
            version: super::PROTOCOL_VERSION,
            key_id: self.key_id,
            counter: self.counter,
            ciphertext,
        };
        self.counter = self
            .counter
            .checked_add(1)
            .ok_or(AeadError::NonceOverflow)?;
        Ok(envelope)
    }

    pub fn open(&mut self, envelope: &SealedEnvelope, aad: &[u8]) -> Result<Vec<u8>, AeadError> {
        let nonce = counter_to_nonce(envelope.counter)?;
        let cipher = ChaCha20Poly1305::new(Key::from_slice(&self.key));
        let full_aad = self.build_aad(aad);
        let mut payload = chacha20poly1305::aead::Payload::from(envelope.ciphertext.as_slice());
        payload.aad = &full_aad;
        let plaintext = cipher
            .decrypt(Nonce::from_slice(&nonce), payload)
            .map_err(|_| AeadError::DecryptionFailed)?;
        Ok(plaintext)
    }

    pub fn key_id(&self) -> u64 {
        self.key_id
    }

    pub fn counter(&self) -> u64 {
        self.counter
    }

    fn compute_nonce(&self) -> Result<[u8; NONCE_SIZE], AeadError> {
        counter_to_nonce(self.counter)
    }

    fn build_aad(&self, base_aad: &[u8]) -> Vec<u8> {
        let mut full = Vec::with_capacity(self.direction_label.len() + 1 + base_aad.len());
        full.extend_from_slice(self.direction_label.as_bytes());
        full.push(0x00);
        full.extend_from_slice(base_aad);
        full
    }
}

impl Drop for SessionCipher {
    fn drop(&mut self) {
        self.key.zeroize();
    }
}

fn counter_to_nonce(counter: u64) -> Result<[u8; NONCE_SIZE], AeadError> {
    let mut nonce = [0u8; NONCE_SIZE];
    let counter_bytes = counter.to_be_bytes();
    nonce[NONCE_SIZE - 8..].copy_from_slice(&counter_bytes);
    Ok(nonce)
}

pub fn seal_standalone(
    key: &[u8; KEY_SIZE],
    plaintext: &[u8],
    aad: &[u8],
    key_id: u64,
) -> Result<SealedEnvelope, AeadError> {
    let mut cipher = SessionCipher::new(*key, key_id, DomainLabel::DOCUMENT_KEY);
    cipher.seal(plaintext, aad)
}

pub fn open_standalone(
    key: &[u8; KEY_SIZE],
    envelope: &SealedEnvelope,
    aad: &[u8],
) -> Result<Vec<u8>, AeadError> {
    let mut cipher = SessionCipher::new(*key, envelope.key_id, DomainLabel::DOCUMENT_KEY);
    cipher.open(envelope, aad)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_key() -> [u8; 32] {
        [42u8; 32]
    }

    #[test]
    fn session_cipher_roundtrip() {
        let key = test_key();
        let mut enc = SessionCipher::new(key, 1, DomainLabel::CLIENT_TO_SERVER);
        let mut dec = SessionCipher::new(key, 1, DomainLabel::CLIENT_TO_SERVER);
        let envelope = enc.seal(b"hello xudanu", b"ctx").unwrap();
        let plaintext = dec.open(&envelope, b"ctx").unwrap();
        assert_eq!(plaintext, b"hello xudanu");
    }

    #[test]
    fn session_cipher_monotonic_counters() {
        let key = test_key();
        let mut cipher = SessionCipher::new(key, 1, DomainLabel::CLIENT_TO_SERVER);
        let e1 = cipher.seal(b"a", b"").unwrap();
        let e2 = cipher.seal(b"b", b"").unwrap();
        let e3 = cipher.seal(b"c", b"").unwrap();
        assert!(e1.counter < e2.counter);
        assert!(e2.counter < e3.counter);
        assert_eq!(cipher.counter(), 3);
    }

    #[test]
    fn session_cipher_rejects_wrong_key() {
        let key_a = test_key();
        let key_b = [99u8; 32];
        let mut enc = SessionCipher::new(key_a, 1, DomainLabel::CLIENT_TO_SERVER);
        let mut dec = SessionCipher::new(key_b, 1, DomainLabel::CLIENT_TO_SERVER);
        let envelope = enc.seal(b"secret", b"ctx").unwrap();
        assert!(dec.open(&envelope, b"ctx").is_err());
    }

    #[test]
    fn session_cipher_rejects_wrong_aad() {
        let key = test_key();
        let mut enc = SessionCipher::new(key, 1, DomainLabel::CLIENT_TO_SERVER);
        let mut dec = SessionCipher::new(key, 1, DomainLabel::CLIENT_TO_SERVER);
        let envelope = enc.seal(b"secret", b"ctx-a").unwrap();
        assert!(dec.open(&envelope, b"ctx-b").is_err());
    }

    #[test]
    fn session_cipher_detects_tampering() {
        let key = test_key();
        let mut enc = SessionCipher::new(key, 1, DomainLabel::CLIENT_TO_SERVER);
        let mut dec = SessionCipher::new(key, 1, DomainLabel::CLIENT_TO_SERVER);
        let mut envelope = enc.seal(b"secret", b"ctx").unwrap();
        if !envelope.ciphertext.is_empty() {
            envelope.ciphertext[0] ^= 0xff;
        }
        assert!(dec.open(&envelope, b"ctx").is_err());
    }

    #[test]
    fn envelope_encode_decode_roundtrip() {
        let key = test_key();
        let mut cipher = SessionCipher::new(key, 42, DomainLabel::DOCUMENT_KEY);
        let envelope = cipher.seal(b"data", b"aad").unwrap();
        let encoded = envelope.encode();
        let decoded = SealedEnvelope::decode(&encoded).unwrap();
        assert_eq!(decoded.version, envelope.version);
        assert_eq!(decoded.key_id, envelope.key_id);
        assert_eq!(decoded.counter, envelope.counter);
        assert_eq!(decoded.ciphertext, envelope.ciphertext);
    }

    #[test]
    fn envelope_rejects_truncated() {
        assert!(SealedEnvelope::decode(&[1, 2, 3]).is_err());
    }

    #[test]
    fn standalone_seal_open_roundtrip() {
        let key = test_key();
        let envelope = seal_standalone(&key, b"doc content", b"doc-id", 7).unwrap();
        let plaintext = open_standalone(&key, &envelope, b"doc-id").unwrap();
        assert_eq!(plaintext, b"doc content");
        assert_eq!(envelope.key_id, 7);
    }

    #[test]
    fn direction_labels_in_aad() {
        let key = test_key();
        let mut enc = SessionCipher::new(key, 1, DomainLabel::CLIENT_TO_SERVER);
        let mut dec_wrong = SessionCipher::new(key, 1, DomainLabel::SERVER_TO_CLIENT);
        let envelope = enc.seal(b"secret", b"").unwrap();
        assert!(dec_wrong.open(&envelope, b"").is_err());
    }

    #[test]
    fn empty_plaintext() {
        let key = test_key();
        let mut cipher = SessionCipher::new(key, 1, DomainLabel::DOCUMENT_KEY);
        let envelope = cipher.seal(b"", b"").unwrap();
        let mut dec = SessionCipher::new(key, 1, DomainLabel::DOCUMENT_KEY);
        let pt = dec.open(&envelope, b"").unwrap();
        assert!(pt.is_empty());
    }
}
