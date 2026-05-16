pub mod aead;
pub mod club_keys;
pub mod kex;
pub mod kdf;
pub mod keys;
pub mod password;
pub mod protocol;
pub mod sign;

pub use aead::{seal_standalone as seal, open_standalone as open, AeadError, SealedEnvelope, SessionCipher};
pub use club_keys::{EncryptedSigningKey, generate_club_keypair, encrypt_signing_key, decrypt_signing_key, verify_club_key, ClubKeyError};
pub use kdf::{derive_key, derive_session_keys, derive_federation_session_keys, SessionKeys, FederationSessionKeys, DomainLabel};
pub use keys::{ServerKeyPair, ServerIdentity, KeyId, KeyHistory, SignedKeyRotation};
pub use kex::{key_exchange_simple as key_exchange, SharedSecret, EphemeralKeyPair};
pub use password::{hash_password, verify_password, PasswordHashError};
pub use protocol::{VersionedEnvelope, EnvelopeVersion, AuthenticatedMessage};
pub use sign::{sign_bytes, verify_signature, SignatureError};

pub const PROTOCOL_VERSION: u8 = 1;
pub const FEDERATION_DOMAIN: &str = "xudanu";
