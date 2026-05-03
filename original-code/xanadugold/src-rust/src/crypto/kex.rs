use x25519_dalek::{PublicKey, StaticSecret};
use rand::rngs::OsRng;
use rand::RngCore;
use zeroize::Zeroize;

use super::sign::{sign_bytes, verify_signature};
use ed25519_dalek::{SigningKey, VerifyingKey, Signature};

#[derive(Debug)]
pub struct SharedSecret([u8; 32]);

impl SharedSecret {
    pub fn as_bytes(&self) -> &[u8; 32] {
        &self.0
    }

    pub fn to_bytes(&self) -> [u8; 32] {
        self.0
    }
}

impl Drop for SharedSecret {
    fn drop(&mut self) {
        self.0.zeroize();
    }
}

pub struct EphemeralKeyPair {
    secret: StaticSecret,
    public: PublicKey,
}

impl EphemeralKeyPair {
    pub fn generate() -> Self {
        let mut bytes = [0u8; 32];
        rand::RngCore::fill_bytes(&mut rand::rngs::OsRng, &mut bytes);
        let secret = StaticSecret::from(bytes);
        let public = PublicKey::from(&secret);
        EphemeralKeyPair { secret, public }
    }

    pub fn public_key(&self) -> &[u8; 32] {
        self.public.as_bytes()
    }

    pub fn public_dalek(&self) -> &PublicKey {
        &self.public
    }

    pub fn diffie_hellman(&self, peer_public: &PublicKey) -> x25519_dalek::SharedSecret {
        self.secret.diffie_hellman(peer_public)
    }
}

pub struct HandshakeResult {
    pub shared_secret: SharedSecret,
    pub transcript_hash: [u8; 32],
    pub my_ephemeral_public: [u8; 32],
}

pub fn key_exchange_simple(
    my_static: &StaticSecret,
    peer_ephemeral: &[u8; 32],
    my_eph: &mut Option<EphemeralKeyPair>,
) -> (SharedSecret, EphemeralKeyPair) {
    let eph = my_eph.take().unwrap_or_else(EphemeralKeyPair::generate);
    let peer_pub = PublicKey::from(*peer_ephemeral);
    let dh1 = my_static.diffie_hellman(&peer_pub);
    let dh2 = eph.secret.diffie_hellman(&peer_pub);
    let mut combined = [0u8; 64];
    combined[..32].copy_from_slice(dh1.as_bytes());
    combined[32..].copy_from_slice(dh2.as_bytes());
    let hash = blake3::hash(&combined);
    combined.zeroize();
    let new_eph = EphemeralKeyPair::generate();
    (SharedSecret(hash.into()), new_eph)
}

pub fn build_transcript(eph_a: &[u8; 32], eph_b: &[u8; 32]) -> [u8; 32] {
    let mut buf = [0u8; 64];
    buf[..32].copy_from_slice(eph_a);
    buf[32..].copy_from_slice(eph_b);
    blake3::hash(&buf).into()
}

pub fn sign_handshake(
    signing_key: &SigningKey,
    my_ephemeral: &[u8; 32],
    peer_ephemeral: &[u8; 32],
) -> Signature {
    let msg = build_signature_message(my_ephemeral, peer_ephemeral);
    sign_bytes(signing_key, &msg)
}

pub fn verify_handshake_signature(
    verifying_key: &VerifyingKey,
    my_ephemeral: &[u8; 32],
    peer_ephemeral: &[u8; 32],
    signature: &Signature,
) -> Result<(), String> {
    let msg = build_signature_message(my_ephemeral, peer_ephemeral);
    verify_signature(verifying_key, &msg, signature)
        .map_err(|_| "handshake signature verification failed".to_string())
}

fn build_signature_message(eph_a: &[u8; 32], eph_b: &[u8; 32]) -> Vec<u8> {
    let mut msg = Vec::with_capacity(8 + 32 + 32);
    msg.extend_from_slice(b"xudanu/v1/");
    msg.extend_from_slice(eph_a);
    msg.extend_from_slice(eph_b);
    msg
}

pub fn peer_key_exchange(
    my_static: &StaticSecret,
    peer_static_public: &[u8; 32],
    my_ephemeral: &EphemeralKeyPair,
    peer_ephemeral: &[u8; 32],
) -> SharedSecret {
    let peer_static = PublicKey::from(*peer_static_public);
    let peer_eph_pub = PublicKey::from(*peer_ephemeral);
    let dh_ss = my_static.diffie_hellman(&peer_static);
    let dh_ee = my_ephemeral.diffie_hellman(&peer_eph_pub);
    let transcript = canonical_transcript(my_ephemeral.public_key(), peer_ephemeral);
    let mut combined = [0u8; 96];
    combined[..32].copy_from_slice(dh_ss.as_bytes());
    combined[32..64].copy_from_slice(dh_ee.as_bytes());
    combined[64..].copy_from_slice(&transcript);
    let hash = blake3::hash(&combined);
    combined.zeroize();
    SharedSecret(hash.into())
}

pub fn canonical_transcript(eph_a: &[u8; 32], eph_b: &[u8; 32]) -> [u8; 32] {
    if eph_a <= eph_b {
        build_transcript(eph_a, eph_b)
    } else {
        build_transcript(eph_b, eph_a)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn generate_static() -> StaticSecret {
        let mut bytes = [0u8; 32];
        OsRng.fill_bytes(&mut bytes);
        StaticSecret::from(bytes)
    }

    #[test]
    fn key_exchange_simple_produces_same_secret() {
        let server_static = generate_static();
        let client_static = generate_static();
        let server_public = PublicKey::from(&server_static);
        let client_public = PublicKey::from(&client_static);
        let server_dh = server_static.diffie_hellman(&client_public);
        let client_dh = client_static.diffie_hellman(&server_public);
        assert_eq!(server_dh.as_bytes(), client_dh.as_bytes());
    }

    #[test]
    fn key_exchange_differs_for_different_peers() {
        let a = generate_static();
        let b = generate_static();
        let c = generate_static();
        let pub_b = PublicKey::from(&b);
        let pub_c = PublicKey::from(&c);
        let ab = a.diffie_hellman(&pub_b);
        let ac = a.diffie_hellman(&pub_c);
        assert_ne!(ab.as_bytes(), ac.as_bytes());
    }

    #[test]
    fn handshake_signing_and_verification() {
        let signing_key = super::super::sign::generate_signing_key();
        let my_eph = EphemeralKeyPair::generate();
        let peer_eph = EphemeralKeyPair::generate();
        let sig = sign_handshake(&signing_key, my_eph.public_key(), peer_eph.public_key());
        assert!(verify_handshake_signature(
            &signing_key.verifying_key(),
            my_eph.public_key(),
            peer_eph.public_key(),
            &sig,
        ).is_ok());
    }

    #[test]
    fn handshake_rejects_wrong_peer_ephemeral() {
        let signing_key = super::super::sign::generate_signing_key();
        let my_eph = EphemeralKeyPair::generate();
        let peer_eph = EphemeralKeyPair::generate();
        let other_eph = EphemeralKeyPair::generate();
        let sig = sign_handshake(&signing_key, my_eph.public_key(), peer_eph.public_key());
        assert!(verify_handshake_signature(
            &signing_key.verifying_key(),
            my_eph.public_key(),
            other_eph.public_key(),
            &sig,
        ).is_err());
    }

    #[test]
    fn build_transcript_deterministic() {
        let a = [1u8; 32];
        let b = [2u8; 32];
        let t1 = build_transcript(&a, &b);
        let t2 = build_transcript(&a, &b);
        assert_eq!(t1, t2);
    }

    #[test]
    fn build_transcript_order_matters() {
        let a = [1u8; 32];
        let b = [2u8; 32];
        let t1 = build_transcript(&a, &b);
        let t2 = build_transcript(&b, &a);
        assert_ne!(t1, t2);
    }

    #[test]
    fn ephemeral_keys_differ() {
        let a = EphemeralKeyPair::generate();
        let b = EphemeralKeyPair::generate();
        assert_ne!(a.public_key(), b.public_key());
    }

    #[test]
    fn peer_key_exchange_symmetric() {
        let a_static = generate_static();
        let b_static = generate_static();
        let b_pub = PublicKey::from(&b_static);
        let a_pub = PublicKey::from(&a_static);
        let a_eph = EphemeralKeyPair::generate();
        let b_eph = EphemeralKeyPair::generate();

        let secret_a = peer_key_exchange(
            &a_static, b_pub.as_bytes(), &a_eph, b_eph.public_key(),
        );
        let secret_b = peer_key_exchange(
            &b_static, a_pub.as_bytes(), &b_eph, a_eph.public_key(),
        );
        assert_eq!(secret_a.as_bytes(), secret_b.as_bytes());
    }

    #[test]
    fn peer_key_exchange_differs_for_different_peers() {
        let a_static = generate_static();
        let b_static = generate_static();
        let c_static = generate_static();
        let b_pub = PublicKey::from(&b_static);
        let c_pub = PublicKey::from(&c_static);
        let a_eph = EphemeralKeyPair::generate();
        let b_eph = EphemeralKeyPair::generate();
        let c_eph = EphemeralKeyPair::generate();

        let secret_ab = peer_key_exchange(
            &a_static, b_pub.as_bytes(), &a_eph, b_eph.public_key(),
        );
        let secret_ac = peer_key_exchange(
            &a_static, c_pub.as_bytes(), &a_eph, c_eph.public_key(),
        );
        assert_ne!(secret_ab.as_bytes(), secret_ac.as_bytes());
    }
}
