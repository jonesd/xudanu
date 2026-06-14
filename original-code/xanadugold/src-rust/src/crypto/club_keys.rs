use ed25519_dalek::SigningKey;
use rand::rngs::OsRng;
use rand::RngCore;
use zeroize::Zeroize;

use super::aead::{self, SealedEnvelope};
use super::sign;

#[derive(Debug)]
pub enum ClubKeyError {
    KeyGenerationFailed,
    EncryptionFailed(aead::AeadError),
    DecryptionFailed(aead::AeadError),
    InvalidKeyBytes,
}

impl std::fmt::Display for ClubKeyError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ClubKeyError::KeyGenerationFailed => write!(f, "club key generation failed"),
            ClubKeyError::EncryptionFailed(e) => write!(f, "club key encryption failed: {}", e),
            ClubKeyError::DecryptionFailed(e) => write!(f, "club key decryption failed: {}", e),
            ClubKeyError::InvalidKeyBytes => write!(f, "invalid key bytes"),
        }
    }
}

impl std::error::Error for ClubKeyError {}

#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct EncryptedSigningKey {
    pub verifying_key: [u8; 32],
    pub envelope: Vec<u8>,
    pub salt: [u8; 32],
}

pub fn generate_club_keypair(
    password: &[u8],
) -> Result<(EncryptedSigningKey, SigningKey), ClubKeyError> {
    let signing_key = sign::generate_signing_key();
    let _verifying_key = signing_key.verifying_key();
    let encrypted = encrypt_signing_key(&signing_key, password)?;
    Ok((encrypted, signing_key))
}

pub fn encrypt_signing_key(
    signing_key: &SigningKey,
    password: &[u8],
) -> Result<EncryptedSigningKey, ClubKeyError> {
    let mut salt = [0u8; 32];
    OsRng.fill_bytes(&mut salt);
    let encryption_key = derive_encryption_key(password, &salt);
    let verifying_key = signing_key.verifying_key().to_bytes();
    let mut secret_bytes = signing_key.to_bytes();
    let envelope = aead::seal_standalone(&encryption_key, &secret_bytes, b"xudanu-club-key", 0)
        .map_err(ClubKeyError::EncryptionFailed)?;
    secret_bytes.zeroize();
    Ok(EncryptedSigningKey {
        verifying_key,
        envelope: envelope.encode(),
        salt,
    })
}

pub fn decrypt_signing_key(
    encrypted: &EncryptedSigningKey,
    password: &[u8],
) -> Result<SigningKey, ClubKeyError> {
    let encryption_key = derive_encryption_key(password, &encrypted.salt);
    let envelope =
        SealedEnvelope::decode(&encrypted.envelope).map_err(ClubKeyError::DecryptionFailed)?;
    let plaintext = aead::open_standalone(&encryption_key, &envelope, b"xudanu-club-key")
        .map_err(ClubKeyError::DecryptionFailed)?;
    let mut secret_bytes: [u8; 32] = plaintext
        .try_into()
        .map_err(|_| ClubKeyError::InvalidKeyBytes)?;
    let key = SigningKey::from_bytes(&secret_bytes);
    secret_bytes.zeroize();
    Ok(key)
}

pub fn verify_club_key(encrypted: &EncryptedSigningKey, signing_key: &SigningKey) -> bool {
    encrypted.verifying_key == signing_key.verifying_key().to_bytes()
}

fn derive_encryption_key(password: &[u8], salt: &[u8; 32]) -> [u8; 32] {
    let params = argon2::Params::new(19456, 2, 1, Some(32)).expect("valid argon2 params");
    let argon2 = argon2::Argon2::new(argon2::Algorithm::Argon2id, argon2::Version::V0x13, params);
    let mut key = [0u8; 32];
    argon2
        .hash_password_into(password, salt, &mut key)
        .expect("argon2 derivation should not fail with valid params");
    key
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn generate_and_decrypt_roundtrip() {
        let (encrypted, _signing_key) = generate_club_keypair(b"password123").unwrap();
        let decrypted = decrypt_signing_key(&encrypted, b"password123").unwrap();
        assert_eq!(
            encrypted.verifying_key,
            decrypted.verifying_key().to_bytes()
        );
    }

    #[test]
    fn wrong_password_fails() {
        let (encrypted, _) = generate_club_keypair(b"correct").unwrap();
        let result = decrypt_signing_key(&encrypted, b"wrong");
        assert!(result.is_err());
    }

    #[test]
    fn can_sign_with_decrypted_key() {
        let (encrypted, _) = generate_club_keypair(b"pw").unwrap();
        let signing_key = decrypt_signing_key(&encrypted, b"pw").unwrap();
        let verifying_key = signing_key.verifying_key();
        let sig = super::sign::sign_bytes(&signing_key, b"test message");
        assert!(super::sign::verify_signature(&verifying_key, b"test message", &sig).is_ok());
    }

    #[test]
    fn different_passwords_different_keys() {
        let (enc_a, _) = generate_club_keypair(b"password-a").unwrap();
        let (enc_b, _) = generate_club_keypair(b"password-b").unwrap();
        assert_ne!(enc_a.verifying_key, enc_b.verifying_key);
    }

    #[test]
    fn same_password_different_keys() {
        let (enc_a, _) = generate_club_keypair(b"same").unwrap();
        let (enc_b, _) = generate_club_keypair(b"same").unwrap();
        assert_ne!(enc_a.verifying_key, enc_b.verifying_key);
        assert_ne!(enc_a.salt, enc_b.salt);
    }
}
