pub mod aead;
pub mod club_keys;
pub mod kdf;
pub mod kex;
pub mod keys;
pub mod password;
pub mod protocol;
pub mod server_identity;
pub mod sign;

pub use aead::{
    open_standalone as open, seal_standalone as seal, AeadError, SealedEnvelope, SessionCipher,
};
pub use club_keys::{
    decrypt_signing_key, encrypt_signing_key, generate_club_keypair, verify_club_key, ClubKeyError,
    EncryptedSigningKey,
};
pub use kdf::{
    derive_federation_session_keys, derive_key, derive_session_keys, DomainLabel,
    FederationSessionKeys, SessionKeys,
};
pub use kex::{key_exchange_simple as key_exchange, EphemeralKeyPair, SharedSecret};
pub use keys::{KeyHistory, KeyId, ServerIdentity, ServerKeyPair, SignedKeyRotation};
pub use password::{hash_password, verify_password, PasswordHashError};
pub use protocol::{AuthenticatedMessage, EnvelopeVersion, VersionedEnvelope};
pub use server_identity::{ServerIdentity as TrustedServerIdentity, ServerRegistryFile, TrustedServerRegistry, verify_server_identity};
pub use sign::{sign_bytes, verify_signature, SignatureError};

pub const PROTOCOL_VERSION: u8 = 1;
pub const FEDERATION_DOMAIN: &str = "xudanu";
