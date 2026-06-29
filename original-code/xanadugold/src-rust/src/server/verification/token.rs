use std::collections::HashMap;
use std::time::{SystemTime, UNIX_EPOCH};

use rand::rngs::OsRng;
use rand::RngCore;

use crate::edition::BeId;

/// How long a verification link stays valid.
const TOKEN_TTL_SECS: u64 = 24 * 60 * 60;

#[derive(Clone)]
struct PendingToken {
    club_id: BeId,
    email: String,
    expires_at: u64,
}

/// In-memory store of pending verification tokens. Tokens are stored hashed
/// (blake3); the raw token is returned once at issue time and never persisted.
///
/// NOTE: in-memory for the initial implementation — a token issued just before
/// a restart is lost (the user re-requests). Manifest-hosted persistence is the
/// next step per FR-2 §8.1; the store is shaped for that (`to_repr`/`from_repr`
/// to add).
pub struct VerificationTokenStore {
    tokens: HashMap<String, PendingToken>,
}

fn now_secs() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{:02x}", b)).collect()
}

fn hash_token(raw: &str) -> String {
    blake3::hash(raw.as_bytes()).to_hex().to_string()
}

impl VerificationTokenStore {
    pub fn new() -> Self {
        Self {
            tokens: HashMap::new(),
        }
    }

    /// Issue a token for (club_id, email). Returns the raw token to deliver.
    pub fn issue(&mut self, club_id: BeId, email: &str) -> String {
        let mut bytes = [0u8; 32];
        OsRng.fill_bytes(&mut bytes);
        let raw = hex(&bytes);
        let hashed = hash_token(&raw);
        self.tokens.insert(
            hashed,
            PendingToken {
                club_id,
                email: email.to_string(),
                expires_at: now_secs().saturating_add(TOKEN_TTL_SECS),
            },
        );
        raw
    }

    /// Redeem a raw token (single-use, atomic). Returns (club_id, email) on
    /// success; None if unknown, already-used, or expired.
    pub fn redeem(&mut self, raw: &str) -> Option<(BeId, String)> {
        let hashed = hash_token(raw);
        let expired = self
            .tokens
            .get(&hashed)
            .map(|t| t.expires_at < now_secs())
            .unwrap_or(true);
        if expired {
            self.tokens.remove(&hashed);
            return None;
        }
        self.tokens.remove(&hashed).map(|t| (t.club_id, t.email))
    }

    /// Drop expired entries.
    pub fn sweep_expired(&mut self) {
        let now = now_secs();
        self.tokens.retain(|_, t| t.expires_at >= now);
    }

    pub fn len(&self) -> usize {
        self.tokens.len()
    }
}

impl Default for VerificationTokenStore {
    fn default() -> Self {
        Self::new()
    }
}
