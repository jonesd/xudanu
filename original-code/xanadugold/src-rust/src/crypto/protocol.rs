use serde::{Serialize, Deserialize};

pub const CURRENT_VERSION: EnvelopeVersion = EnvelopeVersion::V1;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(Serialize, Deserialize))]
pub enum EnvelopeVersion {
    V1 = 1,
}

impl EnvelopeVersion {
    pub fn from_u8(v: u8) -> Option<Self> {
        match v {
            1 => Some(EnvelopeVersion::V1),
            _ => None,
        }
    }

    pub fn to_u8(self) -> u8 {
        self as u8
    }
}

#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(Serialize, Deserialize))]
pub struct VersionedEnvelope<T> {
    pub version: EnvelopeVersion,
    pub key_id: u64,
    pub payload: T,
}

impl<T> VersionedEnvelope<T> {
    pub fn new(key_id: u64, payload: T) -> Self {
        VersionedEnvelope {
            version: CURRENT_VERSION,
            key_id,
            payload,
        }
    }
}

#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(Serialize, Deserialize))]
pub struct AuthenticatedMessage {
    pub version: EnvelopeVersion,
    pub key_id: u64,
    pub message_type: String,
    pub payload: Vec<u8>,
    pub signature: Vec<u8>,
}

impl AuthenticatedMessage {
    pub fn new(key_id: u64, message_type: &str, payload: &[u8], signature: &[u8]) -> Self {
        AuthenticatedMessage {
            version: CURRENT_VERSION,
            key_id,
            message_type: message_type.to_string(),
            payload: payload.to_vec(),
            signature: signature.to_vec(),
        }
    }

    pub fn signing_input(&self) -> Vec<u8> {
        let mut buf = Vec::with_capacity(
            1 + 8 + self.message_type.len() + self.payload.len()
        );
        buf.push(self.version.to_u8());
        buf.extend_from_slice(&self.key_id.to_be_bytes());
        buf.extend_from_slice(self.message_type.as_bytes());
        buf.extend_from_slice(&self.payload);
        buf
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn envelope_version_roundtrip() {
        assert_eq!(EnvelopeVersion::from_u8(1), Some(EnvelopeVersion::V1));
        assert_eq!(EnvelopeVersion::from_u8(0), None);
        assert_eq!(EnvelopeVersion::from_u8(99), None);
    }

    #[test]
    fn versioned_envelope_new() {
        let env: VersionedEnvelope<&str> = VersionedEnvelope::new(42, "hello");
        assert_eq!(env.version, EnvelopeVersion::V1);
        assert_eq!(env.key_id, 42);
        assert_eq!(env.payload, "hello");
    }

    #[test]
    fn authenticated_message_signing_input_stable() {
        let msg = AuthenticatedMessage::new(1, "handshake", b"payload", b"sig");
        let input1 = msg.signing_input();
        let input2 = msg.signing_input();
        assert_eq!(input1, input2);
    }

    #[test]
    fn authenticated_message_signing_input_includes_version() {
        let msg = AuthenticatedMessage::new(1, "test", b"data", b"sig");
        let input = msg.signing_input();
        assert_eq!(input[0], 1u8);
    }

    #[test]
    fn different_messages_have_different_signing_inputs() {
        let msg_a = AuthenticatedMessage::new(1, "type-a", b"data", b"sig");
        let msg_b = AuthenticatedMessage::new(1, "type-b", b"data", b"sig");
        assert_ne!(msg_a.signing_input(), msg_b.signing_input());
    }

    #[test]
    fn serde_roundtrip_envelope() {
        let env = VersionedEnvelope::new(42, "test-payload");
        let json = serde_json::to_string(&env).unwrap();
        let restored: VersionedEnvelope<String> = serde_json::from_str(&json).unwrap();
        assert_eq!(restored.key_id, 42);
        assert_eq!(restored.payload, "test-payload");
    }
}
