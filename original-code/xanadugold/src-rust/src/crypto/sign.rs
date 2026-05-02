use ed25519_dalek::{SigningKey, VerifyingKey, Signer, Verifier, Signature};
use rand::rngs::OsRng;
use zeroize::Zeroize;

#[derive(Debug)]
pub enum SignatureError {
    InvalidSignature,
    InvalidKeyBytes,
    SigningFailed,
}

impl std::fmt::Display for SignatureError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            SignatureError::InvalidSignature => write!(f, "signature verification failed"),
            SignatureError::InvalidKeyBytes => write!(f, "invalid key bytes (expected 32 bytes)"),
            SignatureError::SigningFailed => write!(f, "signing failed"),
        }
    }
}

impl std::error::Error for SignatureError {}

pub fn sign_bytes(signing_key: &SigningKey, message: &[u8]) -> Signature {
    signing_key.sign(message)
}

pub fn verify_signature(
    verifying_key: &VerifyingKey,
    message: &[u8],
    signature: &Signature,
) -> Result<(), SignatureError> {
    verifying_key
        .verify(message, signature)
        .map_err(|_| SignatureError::InvalidSignature)
}

pub fn generate_signing_key() -> SigningKey {
    let mut bytes = [0u8; 32];
    rand::RngCore::fill_bytes(&mut OsRng, &mut bytes);
    let key = SigningKey::from_bytes(&bytes);
    bytes.zeroize();
    key
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sign_and_verify_roundtrip() {
        let signing_key = generate_signing_key();
        let verifying_key = signing_key.verifying_key();
        let message = b"xudanu federation v1";
        let sig = sign_bytes(&signing_key, message);
        assert!(verify_signature(&verifying_key, message, &sig).is_ok());
    }

    #[test]
    fn sign_rejects_tampered_message() {
        let signing_key = generate_signing_key();
        let verifying_key = signing_key.verifying_key();
        let sig = sign_bytes(&signing_key, b"original");
        let result = verify_signature(&verifying_key, b"tampered", &sig);
        assert!(result.is_err());
    }

    #[test]
    fn sign_rejects_wrong_key() {
        let key_a = generate_signing_key();
        let key_b = generate_signing_key();
        let sig = sign_bytes(&key_a, b"message");
        let result = verify_signature(&key_b.verifying_key(), b"message", &sig);
        assert!(result.is_err());
    }

    #[test]
    fn sign_empty_message() {
        let signing_key = generate_signing_key();
        let sig = sign_bytes(&signing_key, b"");
        assert!(verify_signature(&signing_key.verifying_key(), b"", &sig).is_ok());
    }

    #[test]
    fn different_keys_produce_different_signatures() {
        let key = generate_signing_key();
        let sig1 = sign_bytes(&key, b"same");
        let sig2 = sign_bytes(&generate_signing_key(), b"same");
        assert_ne!(sig1.to_bytes(), sig2.to_bytes());
    }

    #[test]
    fn signing_key_serialization_roundtrip() {
        let key = generate_signing_key();
        let bytes = key.to_bytes();
        let restored = SigningKey::from_bytes(&bytes);
        let msg = b"test roundtrip";
        let sig_a = sign_bytes(&key, msg);
        let sig_b = sign_bytes(&restored, msg);
        assert_eq!(sig_a.to_bytes(), sig_b.to_bytes());
    }
}
