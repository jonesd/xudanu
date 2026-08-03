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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_store_is_empty() {
        let store = VerificationTokenStore::new();
        assert_eq!(store.len(), 0);
    }

    #[test]
    fn default_matches_new() {
        assert_eq!(
            VerificationTokenStore::new().len(),
            VerificationTokenStore::default().len()
        );
    }

    #[test]
    fn issue_returns_nonempty_hex_and_increments_len() {
        let mut store = VerificationTokenStore::new();
        let tok = store.issue(1, "a@b.com");
        assert!(!tok.is_empty());
        assert_eq!(tok.len(), 64);
        assert!(tok.chars().all(|c| c.is_ascii_hexdigit()));
        assert_eq!(store.len(), 1);
    }

    #[test]
    fn issue_multiple_tokens_are_distinct() {
        let mut store = VerificationTokenStore::new();
        let t1 = store.issue(1, "a@b.com");
        let t2 = store.issue(2, "c@d.com");
        assert_ne!(t1, t2);
        assert_eq!(store.len(), 2);
    }

    #[test]
    fn redeem_success_returns_club_and_email() {
        let mut store = VerificationTokenStore::new();
        let tok = store.issue(42, "user@example.com");
        let redeemed = store.redeem(&tok).expect("should redeem valid token");
        assert_eq!(redeemed.0, 42);
        assert_eq!(redeemed.1, "user@example.com");
        assert_eq!(store.len(), 0);
    }

    #[test]
    fn redeem_is_single_use() {
        let mut store = VerificationTokenStore::new();
        let tok = store.issue(7, "x@y.com");
        assert!(store.redeem(&tok).is_some());
        assert!(store.redeem(&tok).is_none());
    }

    #[test]
    fn redeem_unknown_token_returns_none() {
        let mut store = VerificationTokenStore::new();
        assert!(store.redeem("deadbeef").is_none());
        assert_eq!(store.len(), 0);
    }

    #[test]
    fn redeem_garbage_on_empty_store_returns_none() {
        let mut store = VerificationTokenStore::new();
        assert!(store.redeem("").is_none());
    }

    #[test]
    fn sweep_expired_retains_fresh_tokens() {
        let mut store = VerificationTokenStore::new();
        let _ = store.issue(1, "a@b.com");
        let _ = store.issue(2, "c@d.com");
        assert_eq!(store.len(), 2);
        store.sweep_expired();
        assert_eq!(store.len(), 2);
    }

    #[test]
    fn sweep_expired_on_empty_store_is_noop() {
        let mut store = VerificationTokenStore::new();
        store.sweep_expired();
        assert_eq!(store.len(), 0);
    }

    #[test]
    fn sweep_expired_does_not_invalidate_live_redeem() {
        let mut store = VerificationTokenStore::new();
        let tok = store.issue(5, "z@z.com");
        store.sweep_expired();
        assert_eq!(store.len(), 1);
        let redeemed = store.redeem(&tok).expect("fresh token should still redeem");
        assert_eq!(redeemed.0, 5);
    }
}
