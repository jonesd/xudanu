use hkdf::Hkdf;
use sha2::Sha256;
use zeroize::Zeroize;

pub struct DomainLabel(&'static str);

impl DomainLabel {
    pub const HANDSHAKE: &'static str = "xudanu/v1/handshake";
    pub const CLIENT_TO_SERVER: &'static str = "xudanu/v1/aead/client-to-server";
    pub const SERVER_TO_CLIENT: &'static str = "xudanu/v1/aead/server-to-client";
    pub const DOCUMENT_KEY: &'static str = "xudanu/v1/document-key";
    pub const CHALLENGE_KEY: &'static str = "xudanu/v1/challenge-key";
    pub const EXPORT_SECRET: &'static str = "xudanu/v1/export";
}

pub struct SessionKeys {
    pub client_to_server: [u8; 32],
    pub server_to_client: [u8; 32],
}

impl SessionKeys {
    pub fn zeroize(&mut self) {
        self.client_to_server.zeroize();
        self.server_to_client.zeroize();
    }
}

impl Drop for SessionKeys {
    fn drop(&mut self) {
        self.zeroize();
    }
}

pub fn derive_key(ikm: &[u8], salt: Option<&[u8]>, label: &str, info: &[u8]) -> [u8; 32] {
    let hk = Hkdf::<Sha256>::new(salt, ikm);
    let mut okm = [0u8; 32];
    let full_info = format!("{}|{}", label, hex::encode(info));
    hk.expand(full_info.as_bytes(), &mut okm)
        .expect("32 bytes is valid HKDF output length");
    okm
}

pub fn derive_session_keys(shared_secret: &[u8], handshake_hash: &[u8]) -> SessionKeys {
    let client_to_server = derive_key(shared_secret, Some(handshake_hash), DomainLabel::CLIENT_TO_SERVER, &[]);
    let server_to_client = derive_key(shared_secret, Some(handshake_hash), DomainLabel::SERVER_TO_CLIENT, &[]);
    SessionKeys {
        client_to_server,
        server_to_client,
    }
}

mod hex {
    pub fn encode(data: &[u8]) -> String {
        data.iter().map(|b| format!("{:02x}", b)).collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn derive_key_deterministic() {
        let k1 = derive_key(b"secret", None, DomainLabel::HANDSHAKE, b"info");
        let k2 = derive_key(b"secret", None, DomainLabel::HANDSHAKE, b"info");
        assert_eq!(k1, k2);
    }

    #[test]
    fn derive_key_differs_with_salt() {
        let k1 = derive_key(b"secret", Some(b"salt-a"), DomainLabel::HANDSHAKE, b"info");
        let k2 = derive_key(b"secret", Some(b"salt-b"), DomainLabel::HANDSHAKE, b"info");
        assert_ne!(k1, k2);
    }

    #[test]
    fn derive_key_differs_with_label() {
        let k1 = derive_key(b"secret", None, DomainLabel::CLIENT_TO_SERVER, b"info");
        let k2 = derive_key(b"secret", None, DomainLabel::SERVER_TO_CLIENT, b"info");
        assert_ne!(k1, k2);
    }

    #[test]
    fn derive_key_differs_with_info() {
        let k1 = derive_key(b"secret", None, DomainLabel::HANDSHAKE, b"info-a");
        let k2 = derive_key(b"secret", None, DomainLabel::HANDSHAKE, b"info-b");
        assert_ne!(k1, k2);
    }

    #[test]
    fn derive_session_keys_produces_separate_keys() {
        let sk = derive_session_keys(b"shared-secret-32-bytes-long-enough!", b"handshake-hash");
        assert_ne!(sk.client_to_server, sk.server_to_client);
    }

    #[test]
    fn derive_session_keys_deterministic() {
        let sk1 = derive_session_keys(b"shared-secret-32-bytes-long-enough!", b"handshake-hash");
        let sk2 = derive_session_keys(b"shared-secret-32-bytes-long-enough!", b"handshake-hash");
        assert_eq!(sk1.client_to_server, sk2.client_to_server);
        assert_eq!(sk1.server_to_client, sk2.server_to_client);
    }

    #[test]
    fn derive_session_keys_differs_with_handshake() {
        let sk1 = derive_session_keys(b"shared-secret-32-bytes-long-enough!", b"hash-a");
        let sk2 = derive_session_keys(b"shared-secret-32-bytes-long-enough!", b"hash-b");
        assert_ne!(sk1.client_to_server, sk2.client_to_server);
    }

    #[test]
    fn session_keys_zeroize_on_drop() {
        let mut sk = derive_session_keys(b"shared-secret-32-bytes-long-enough!", b"hash");
        let c2s_copy = sk.client_to_server;
        sk.zeroize();
        assert_ne!(sk.client_to_server, c2s_copy);
    }
}
