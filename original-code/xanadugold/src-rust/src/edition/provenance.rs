use blake3::Hasher;
use ed25519_dalek::{Signature, SigningKey, VerifyingKey};

use super::backend::BeId;

const PROVENANCE_DOMAIN: &[u8] = b"xudanu/v1/provenance";
const ELEMENT_PROVENANCE_DOMAIN: &[u8] = b"xudanu/v1/element-provenance";

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum AuthorType {
    Human,
    Llm,
}

impl Default for AuthorType {
    fn default() -> Self {
        AuthorType::Human
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ElementProvenance {
    pub author_public_key: [u8; 32],
    pub author_display_name: String,
    pub author_club_id: BeId,
    pub timestamp: u64,
    pub author_type: AuthorType,
    pub llm_model: Option<String>,
}

#[cfg(feature = "serde")]
mod element_serde_impl {
    use super::*;
    use serde::{Deserialize, Deserializer, Serialize, Serializer};

    #[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
    struct ElementProvenanceData {
        author_public_key: Vec<u8>,
        author_display_name: String,
        author_club_id: u64,
        timestamp: u64,
        author_type: Option<String>,
        llm_model: Option<String>,
    }

    impl Serialize for ElementProvenance {
        fn serialize<S: Serializer>(&self, s: S) -> Result<S::Ok, S::Error> {
            ElementProvenanceData {
                author_public_key: self.author_public_key.to_vec(),
                author_display_name: self.author_display_name.clone(),
                author_club_id: self.author_club_id,
                timestamp: self.timestamp,
                author_type: Some(match self.author_type {
                    AuthorType::Human => "human".to_string(),
                    AuthorType::Llm => "llm".to_string(),
                }),
                llm_model: self.llm_model.clone(),
            }
            .serialize(s)
        }
    }

    impl<'de> Deserialize<'de> for ElementProvenance {
        fn deserialize<D: Deserializer<'de>>(d: D) -> Result<Self, D::Error> {
            let data = ElementProvenanceData::deserialize(d)?;
            let author_public_key: [u8; 32] = data
                .author_public_key
                .try_into()
                .map_err(|_| serde::de::Error::custom("author_public_key must be 32 bytes"))?;
            let author_type = match data.author_type.as_deref() {
                Some("llm") => AuthorType::Llm,
                _ => AuthorType::Human,
            };
            Ok(ElementProvenance {
                author_public_key,
                author_display_name: data.author_display_name,
                author_club_id: data.author_club_id,
                timestamp: data.timestamp,
                author_type,
                llm_model: data.llm_model,
            })
        }
    }
}

pub fn sign_element(
    signing_key: &SigningKey,
    element_fingerprint: &[u8; 32],
    timestamp: u64,
    server_id: &[u8; 32],
) -> Provenance {
    let mut hasher = Hasher::new();
    hasher.update(ELEMENT_PROVENANCE_DOMAIN);
    hasher.update(element_fingerprint);
    hasher.update(&signing_key.verifying_key().to_bytes());
    hasher.update(&timestamp.to_le_bytes());
    hasher.update(server_id);
    let payload: [u8; 32] = hasher.finalize().into();
    let signature = crate::crypto::sign::sign_bytes(signing_key, &payload);
    Provenance {
        author_public_key: signing_key.verifying_key().to_bytes(),
        signature: signature.to_bytes(),
        timestamp,
        server_id: *server_id,
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Provenance {
    pub author_public_key: [u8; 32],
    pub signature: [u8; 64],
    pub timestamp: u64,
    pub server_id: [u8; 32],
}

#[cfg(feature = "serde")]
mod serde_impl {
    use super::*;
    use serde::{Deserialize, Deserializer, Serialize, Serializer};

    #[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
    struct ProvenanceData {
        author_public_key: Vec<u8>,
        signature: Vec<u8>,
        timestamp: u64,
        server_id: Vec<u8>,
    }

    impl Serialize for Provenance {
        fn serialize<S: Serializer>(&self, s: S) -> Result<S::Ok, S::Error> {
            ProvenanceData {
                author_public_key: self.author_public_key.to_vec(),
                signature: self.signature.to_vec(),
                timestamp: self.timestamp,
                server_id: self.server_id.to_vec(),
            }
            .serialize(s)
        }
    }

    impl<'de> Deserialize<'de> for Provenance {
        fn deserialize<D: Deserializer<'de>>(d: D) -> Result<Self, D::Error> {
            let data = ProvenanceData::deserialize(d)?;
            let author_public_key: [u8; 32] = data
                .author_public_key
                .try_into()
                .map_err(|_| serde::de::Error::custom("author_public_key must be 32 bytes"))?;
            let signature: [u8; 64] = data
                .signature
                .try_into()
                .map_err(|_| serde::de::Error::custom("signature must be 64 bytes"))?;
            let server_id: [u8; 32] = data
                .server_id
                .try_into()
                .map_err(|_| serde::de::Error::custom("server_id must be 32 bytes"))?;
            Ok(Provenance {
                author_public_key,
                signature,
                timestamp: data.timestamp,
                server_id,
            })
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpanProvenance {
    pub start: i64,
    pub end: i64,
    pub provenance: Provenance,
}

#[cfg(feature = "serde")]
impl serde::Serialize for SpanProvenance {
    fn serialize<S: serde::Serializer>(&self, s: S) -> Result<S::Ok, S::Error> {
        use serde::ser::SerializeStruct;
        let mut state = s.serialize_struct("SpanProvenance", 3)?;
        state.serialize_field("start", &self.start)?;
        state.serialize_field("end", &self.end)?;
        state.serialize_field("provenance", &self.provenance)?;
        state.end()
    }
}

#[cfg(feature = "serde")]
impl<'de> serde::Deserialize<'de> for SpanProvenance {
    fn deserialize<D: serde::Deserializer<'de>>(d: D) -> Result<Self, D::Error> {
        #[derive(serde::Deserialize)]
        struct SpanProvenanceData {
            start: i64,
            end: i64,
            provenance: Provenance,
        }
        let data = SpanProvenanceData::deserialize(d)?;
        Ok(SpanProvenance {
            start: data.start,
            end: data.end,
            provenance: data.provenance,
        })
    }
}

pub fn compute_span_fingerprint_hex(fingerprints: &[[u8; 32]]) -> String {
    let fp = compute_span_fingerprint(fingerprints);
    fp.iter().map(|b| format!("{:02x}", b)).collect()
}

fn compute_span_fingerprint(fingerprints: &[[u8; 32]]) -> [u8; 32] {
    let mut hasher = Hasher::new();
    hasher.update(PROVENANCE_DOMAIN);
    for fp in fingerprints {
        hasher.update(fp);
    }
    hasher.finalize().into()
}

fn compute_signing_payload(
    span_fingerprint: &[u8; 32],
    author_public_key: &[u8; 32],
    timestamp: u64,
    server_id: &[u8; 32],
) -> [u8; 32] {
    let mut hasher = Hasher::new();
    hasher.update(PROVENANCE_DOMAIN);
    hasher.update(span_fingerprint);
    hasher.update(author_public_key);
    hasher.update(&timestamp.to_le_bytes());
    hasher.update(server_id);
    hasher.finalize().into()
}

pub fn sign_span(
    signing_key: &SigningKey,
    element_fingerprints: &[[u8; 32]],
    timestamp: u64,
    server_id: &[u8; 32],
) -> Provenance {
    let span_fp = compute_span_fingerprint(element_fingerprints);
    let payload = compute_signing_payload(
        &span_fp,
        &signing_key.verifying_key().to_bytes(),
        timestamp,
        server_id,
    );
    let signature = crate::crypto::sign::sign_bytes(signing_key, &payload);
    Provenance {
        author_public_key: signing_key.verifying_key().to_bytes(),
        signature: signature.to_bytes(),
        timestamp,
        server_id: *server_id,
    }
}

pub fn verify_span_provenance(provenance: &Provenance, element_fingerprints: &[[u8; 32]]) -> bool {
    let span_fp = compute_span_fingerprint(element_fingerprints);
    verify_span_provenance_with_span_fp(provenance, &span_fp)
}

pub fn verify_span_provenance_with_span_fp(
    provenance: &Provenance,
    span_fingerprint: &[u8; 32],
) -> bool {
    let verifying_key = match VerifyingKey::from_bytes(&provenance.author_public_key) {
        Ok(vk) => vk,
        Err(_) => return false,
    };
    let payload = compute_signing_payload(
        span_fingerprint,
        &provenance.author_public_key,
        provenance.timestamp,
        &provenance.server_id,
    );
    let signature = Signature::from_bytes(&provenance.signature);
    crate::crypto::sign::verify_signature(&verifying_key, &payload, &signature).is_ok()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::crypto::sign::generate_signing_key;
    use crate::edition::RangeElement;

    fn make_fingerprints() -> Vec<[u8; 32]> {
        vec![
            RangeElement::text("H").content_fingerprint(),
            RangeElement::text("e").content_fingerprint(),
            RangeElement::text("l").content_fingerprint(),
        ]
    }

    #[test]
    fn sign_and_verify_roundtrip() {
        let key = generate_signing_key();
        let fps = make_fingerprints();
        let mut server_id = [0u8; 32];
        server_id[..4].copy_from_slice(b"serv");
        let prov = sign_span(&key, &fps, 1000, &server_id);
        assert!(verify_span_provenance(&prov, &fps));
    }

    #[test]
    fn verify_rejects_wrong_fingerprints() {
        let key = generate_signing_key();
        let fps = make_fingerprints();
        let mut server_id = [0u8; 32];
        let prov = sign_span(&key, &fps, 1000, &server_id);
        let wrong_fps = vec![RangeElement::text("X").content_fingerprint()];
        assert!(!verify_span_provenance(&prov, &wrong_fps));
    }

    #[test]
    fn verify_rejects_wrong_key() {
        let key_a = generate_signing_key();
        let key_b = generate_signing_key();
        let fps = make_fingerprints();
        let mut server_id = [0u8; 32];
        let mut prov = sign_span(&key_a, &fps, 1000, &server_id);
        prov.author_public_key = key_b.verifying_key().to_bytes();
        assert!(!verify_span_provenance(&prov, &fps));
    }

    #[test]
    fn verify_rejects_tampered_signature() {
        let key = generate_signing_key();
        let fps = make_fingerprints();
        let mut server_id = [0u8; 32];
        let mut prov = sign_span(&key, &fps, 1000, &server_id);
        prov.signature[0] ^= 0xff;
        assert!(!verify_span_provenance(&prov, &fps));
    }

    #[test]
    fn verify_rejects_wrong_timestamp() {
        let key = generate_signing_key();
        let fps = make_fingerprints();
        let mut server_id = [0u8; 32];
        let mut prov = sign_span(&key, &fps, 1000, &server_id);
        prov.timestamp = 2000;
        assert!(!verify_span_provenance(&prov, &fps));
    }

    #[test]
    fn same_content_same_fingerprint() {
        let fps1 = vec![RangeElement::text("abc").content_fingerprint()];
        let fps2 = vec![RangeElement::text("abc").content_fingerprint()];
        assert_eq!(
            compute_span_fingerprint(&fps1),
            compute_span_fingerprint(&fps2)
        );
    }

    #[test]
    fn different_content_different_fingerprint() {
        let fps1 = vec![RangeElement::text("abc").content_fingerprint()];
        let fps2 = vec![RangeElement::text("xyz").content_fingerprint()];
        assert_ne!(
            compute_span_fingerprint(&fps1),
            compute_span_fingerprint(&fps2)
        );
    }

    #[test]
    #[cfg(feature = "serde")]
    fn provenance_serde_roundtrip() {
        let key = generate_signing_key();
        let fps = make_fingerprints();
        let mut server_id = [0u8; 32];
        server_id[..4].copy_from_slice(b"test");
        let prov = sign_span(&key, &fps, 12345, &server_id);

        let json = serde_json::to_string(&prov).unwrap();
        let restored: Provenance = serde_json::from_str(&json).unwrap();
        assert_eq!(prov, restored);
    }

    #[test]
    #[cfg(feature = "serde")]
    fn span_provenance_serde_roundtrip() {
        let key = generate_signing_key();
        let fps = make_fingerprints();
        let mut server_id = [0u8; 32];
        let prov = sign_span(&key, &fps, 99999, &server_id);
        let sp = SpanProvenance {
            start: 0,
            end: 3,
            provenance: prov,
        };

        let json = serde_json::to_string(&sp).unwrap();
        let restored: SpanProvenance = serde_json::from_str(&json).unwrap();
        assert_eq!(sp, restored);
    }
}
