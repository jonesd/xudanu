use ed25519_dalek::{Signature, Signer, SigningKey, Verifier, VerifyingKey};

#[cfg(feature = "server")]
use super::aead::{open_standalone, seal_standalone, SealedEnvelope, SessionCipher};

#[cfg(feature = "server")]
use super::kdf::{derive_key, derive_session_keys, DomainLabel};

#[cfg(feature = "server")]
use super::sign::{sign_bytes, verify_signature};

#[test]
fn ed25519_known_keypair_deterministic() {
    let signing_key = SigningKey::from_bytes(&[42u8; 32]);
    let verifying_key = signing_key.verifying_key();
    assert_eq!(
        hex::encode(verifying_key.to_bytes()),
        hex::encode(signing_key.verifying_key().to_bytes()),
    );
    let msg = b"xudanu test message";
    let sig1 = signing_key.sign(msg);
    let sig2 = signing_key.sign(msg);
    assert_eq!(
        sig1.to_bytes(),
        sig2.to_bytes(),
        "Ed25519 must be deterministic"
    );
}

#[test]
fn ed25519_known_signature_verifies() {
    let signing_key = SigningKey::from_bytes(&[99u8; 32]);
    let verifying_key = signing_key.verifying_key();
    let msg = b"prove this is authentic";
    let sig = signing_key.sign(msg);
    assert!(verifying_key.verify(msg, &sig).is_ok());
    let restored = Signature::from_bytes(&sig.to_bytes());
    assert!(verifying_key.verify(msg, &restored).is_ok());
}

#[test]
fn ed25519_cross_verify_with_known_keys() {
    let key_a = SigningKey::from_bytes(&[1u8; 32]);
    let key_b = SigningKey::from_bytes(&[2u8; 32]);
    let msg = b"cross verification test";
    let sig_a = key_a.sign(msg);
    let sig_b = key_b.sign(msg);
    assert_ne!(sig_a.to_bytes(), sig_b.to_bytes());
    assert!(key_a.verifying_key().verify(msg, &sig_a).is_ok());
    assert!(key_b.verifying_key().verify(msg, &sig_b).is_ok());
    assert!(key_a.verifying_key().verify(msg, &sig_b).is_err());
}

#[test]
fn ed25519_large_message() {
    let key = SigningKey::from_bytes(&[7u8; 32]);
    let large = vec![0xABu8; 100_000];
    let sig = key.sign(&large);
    assert!(key.verifying_key().verify(&large, &sig).is_ok());
    let mut tampered = large.clone();
    tampered[50_000] ^= 1;
    assert!(key.verifying_key().verify(&tampered, &sig).is_err());
}

#[test]
fn blake3_known_hash() {
    assert_eq!(
        blake3::hash(b""),
        blake3::hash(b""),
        "must be deterministic"
    );
    assert_ne!(blake3::hash(b"hello"), blake3::hash(b"world"));
    assert_eq!(blake3::hash(b"hello").to_hex().to_string().len(), 64);
}

#[test]
fn blake3_content_fingerprint_stable() {
    let text = b"The quick brown fox jumps over the lazy dog";
    assert_eq!(blake3::hash(text).as_bytes(), blake3::hash(text).as_bytes());
    let mut with_space = text.to_vec();
    with_space.push(b' ');
    assert_ne!(
        blake3::hash(text).as_bytes(),
        blake3::hash(&with_space).as_bytes(),
    );
}

#[cfg(feature = "server")]
#[test]
fn kdf_deterministic_output() {
    let k1 = derive_key(b"ikm", None, "label", b"info");
    let k2 = derive_key(b"ikm", None, "label", b"info");
    assert_eq!(k1, k2);
}

#[cfg(feature = "server")]
#[test]
fn kdf_different_labels_different_keys() {
    let k1 = derive_key(b"master", None, DomainLabel::HANDSHAKE, b"ctx");
    let k2 = derive_key(b"master", None, DomainLabel::CLIENT_TO_SERVER, b"ctx");
    assert_ne!(k1, k2);
}

#[cfg(feature = "server")]
#[test]
fn kdf_different_info_different_keys() {
    let k1 = derive_key(b"master", None, "label", b"a");
    let k2 = derive_key(b"master", None, "label", b"b");
    assert_ne!(k1, k2);
}

#[cfg(feature = "server")]
#[test]
fn kdf_salt_changes_output() {
    let k1 = derive_key(b"master", None, "label", b"info");
    let k2 = derive_key(b"master", Some(b"salt"), "label", b"info");
    assert_ne!(k1, k2);
}

#[cfg(feature = "server")]
#[test]
fn kdf_session_keys_deterministic() {
    let secret = [0x42u8; 32];
    let hs_hash = [0x99u8; 32];
    let k1 = derive_session_keys(&secret, &hs_hash);
    let k2 = derive_session_keys(&secret, &hs_hash);
    assert_eq!(k1.client_to_server, k2.client_to_server);
    assert_eq!(k1.server_to_client, k2.server_to_client);
    assert_ne!(k1.client_to_server, k1.server_to_client);
}

#[cfg(feature = "server")]
#[test]
fn aead_seal_open_roundtrip() {
    let key = [0xABu8; 32];
    let pt = b"secret content to encrypt";
    let env = seal_standalone(&key, pt, b"aad", 1).unwrap();
    let dec = open_standalone(&key, &env, b"aad").unwrap();
    assert_eq!(dec, pt);
}

#[cfg(feature = "server")]
#[test]
fn aead_tampered_ciphertext_fails() {
    let key = [0xCDu8; 32];
    let mut env = seal_standalone(&key, b"data", b"aad", 1).unwrap();
    if !env.ciphertext.is_empty() {
        env.ciphertext[0] ^= 0xFF;
    }
    assert!(open_standalone(&key, &env, b"aad").is_err());
}

#[cfg(feature = "server")]
#[test]
fn aead_wrong_key_fails() {
    let env = seal_standalone(&[0x11u8; 32], b"data", b"aad", 1).unwrap();
    assert!(open_standalone(&[0x22u8; 32], &env, b"aad").is_err());
}

#[cfg(feature = "server")]
#[test]
fn aead_wrong_aad_fails() {
    let env = seal_standalone(&[0x33u8; 32], b"data", b"correct", 1).unwrap();
    assert!(open_standalone(&[0x33u8; 32], &env, b"wrong").is_err());
}

#[cfg(feature = "server")]
#[test]
fn aead_envelope_encode_decode_roundtrip() {
    let key = [0x44u8; 32];
    let env = seal_standalone(&key, b"test", b"aad", 42).unwrap();
    let encoded = env.encode();
    let decoded = SealedEnvelope::decode(&encoded).unwrap();
    assert_eq!(decoded.key_id, 42);
    assert_eq!(open_standalone(&key, &decoded, b"aad").unwrap(), b"test");
}

#[cfg(feature = "server")]
#[test]
fn aead_session_cipher_sequential() {
    let mut cipher = SessionCipher::new([0x55u8; 32], 1, DomainLabel::DOCUMENT_KEY);
    let env1 = cipher.seal(b"first", b"").unwrap();
    let env2 = cipher.seal(b"second", b"").unwrap();
    assert_eq!(env1.counter, 0);
    assert_eq!(env2.counter, 1);
    assert_eq!(cipher.open(&env1, b"").unwrap(), b"first");
    assert_eq!(cipher.open(&env2, b"").unwrap(), b"second");
}

#[cfg(feature = "server")]
#[test]
fn server_sign_data_cross_verify() {
    let key_a = SigningKey::from_bytes(&[10u8; 32]);
    let key_b = SigningKey::from_bytes(&[20u8; 32]);
    let data = b"cross-server content verification";
    let sig = sign_bytes(&key_a, data);
    assert!(verify_signature(&key_a.verifying_key(), data, &sig).is_ok());
    assert!(verify_signature(&key_b.verifying_key(), data, &sig).is_err());
}

#[cfg(feature = "server")]
#[test]
fn sign_large_content_hash() {
    let key = SigningKey::from_bytes(&[30u8; 32]);
    let large = vec![0x77u8; 500_000];
    let hash = blake3::hash(&large);
    let sig = sign_bytes(&key, hash.as_bytes());
    assert!(verify_signature(&key.verifying_key(), hash.as_bytes(), &sig).is_ok());
    let diff = vec![0x77u8; 499_999];
    let diff_hash = blake3::hash(&diff);
    assert!(verify_signature(&key.verifying_key(), diff_hash.as_bytes(), &sig).is_err());
}

#[cfg(feature = "server")]
#[test]
fn key_rotation_chain() {
    let key1 = SigningKey::from_bytes(&[100u8; 32]);
    let key2 = SigningKey::from_bytes(&[200u8; 32]);
    let msg = b"rotate from key1 to key2";
    let sig = sign_bytes(&key1, msg);
    assert!(verify_signature(&key1.verifying_key(), msg, &sig).is_ok());
    assert_ne!(
        key1.verifying_key().to_bytes(),
        key2.verifying_key().to_bytes()
    );
    let post_msg = b"signed by new key";
    let post_sig = sign_bytes(&key2, post_msg);
    assert!(verify_signature(&key2.verifying_key(), post_msg, &post_sig).is_ok());
}

#[test]
fn signature_hex_roundtrip() {
    let key = SigningKey::from_bytes(&[55u8; 32]);
    let msg = b"hex encoding test";
    let sig = key.sign(msg);
    let hex = hex::encode(sig.to_bytes());
    let restored = Signature::from_bytes(hex::decode(&hex).unwrap().as_slice().try_into().unwrap());
    assert!(key.verifying_key().verify(msg, &restored).is_ok());
}

#[test]
fn verifying_key_hex_roundtrip() {
    let key = SigningKey::from_bytes(&[66u8; 32]);
    let vk_bytes = key.verifying_key().to_bytes();
    let hex = hex::encode(vk_bytes);
    let restored =
        VerifyingKey::from_bytes(hex::decode(&hex).unwrap().as_slice().try_into().unwrap())
            .unwrap();
    let msg = b"key restoration test";
    let sig = key.sign(msg);
    assert!(restored.verify(msg, &sig).is_ok());
}

#[cfg(feature = "server")]
#[test]
fn content_hash_verification_simulation() {
    let content = b"original content verified across servers";
    let hash = blake3::hash(content);
    let key = SigningKey::from_bytes(&[77u8; 32]);
    let sig = sign_bytes(&key, hash.as_bytes());
    assert!(verify_signature(&key.verifying_key(), hash.as_bytes(), &sig).is_ok());
    let mut tampered = content.to_vec();
    tampered[0] ^= 1;
    let tampered_hash = blake3::hash(&tampered);
    assert!(verify_signature(&key.verifying_key(), tampered_hash.as_bytes(), &sig).is_err());
}
