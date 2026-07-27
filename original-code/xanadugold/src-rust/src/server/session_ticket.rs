use crate::edition::BeId;

pub const TICKET_TTL_SECS: u64 = 7 * 24 * 3600;
pub const MAX_TICKET_LEN: usize = 256;

const CLAIMS_LEN: usize = 8 + 8 + 8 + 8 + 16;
const SIG_LEN: usize = 64;
pub const TICKET_LEN: usize = CLAIMS_LEN + SIG_LEN;

#[derive(Debug, Clone)]
pub struct SessionTicketClaims {
    pub club_id: BeId,
    pub key_id: u64,
    pub issued_at: u64,
    pub expires_at: u64,
    pub nonce: [u8; 16],
}

#[derive(Debug, Clone)]
pub struct SessionTicket {
    pub claims: SessionTicketClaims,
    pub signature: Vec<u8>,
}

impl SessionTicketClaims {
    pub fn canonical_bytes(&self) -> Vec<u8> {
        let mut buf = Vec::with_capacity(CLAIMS_LEN);
        buf.extend_from_slice(&self.club_id.to_be_bytes());
        buf.extend_from_slice(&self.key_id.to_be_bytes());
        buf.extend_from_slice(&self.issued_at.to_be_bytes());
        buf.extend_from_slice(&self.expires_at.to_be_bytes());
        buf.extend_from_slice(&self.nonce);
        buf
    }
}

impl SessionTicket {
    pub fn encode(&self) -> Vec<u8> {
        let mut buf = self.claims.canonical_bytes();
        buf.extend_from_slice(&self.signature);
        buf
    }

    pub fn decode(data: &[u8]) -> Option<Self> {
        if data.len() != TICKET_LEN {
            return None;
        }
        let club_id = u64::from_be_bytes(data[0..8].try_into().ok()?);
        let key_id = u64::from_be_bytes(data[8..16].try_into().ok()?);
        let issued_at = u64::from_be_bytes(data[16..24].try_into().ok()?);
        let expires_at = u64::from_be_bytes(data[24..32].try_into().ok()?);
        let nonce: [u8; 16] = data[32..48].try_into().ok()?;
        let signature = data[48..TICKET_LEN].to_vec();
        Some(Self {
            claims: SessionTicketClaims {
                club_id,
                key_id,
                issued_at,
                expires_at,
                nonce,
            },
            signature,
        })
    }

    pub fn is_expired(&self, now: u64) -> bool {
        self.claims.expires_at < now
    }
}

pub fn now_secs() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}
