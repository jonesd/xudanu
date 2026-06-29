use std::sync::Mutex;

use crate::edition::BeId;

pub mod provider;
pub mod token;

pub use provider::{DevProvider, EmailProvider};
pub use token::VerificationTokenStore;

/// Shared verification state: the pending-token store and the email transport.
/// Lives in `AppState`; the club-level `verified`/`email` data lives on `Club`
/// (and is persisted via `ClubSnapshot`).
pub struct VerificationState {
    tokens: Mutex<VerificationTokenStore>,
    provider: Box<dyn EmailProvider>,
    verify_base_url: String,
}

impl VerificationState {
    pub fn new(verify_base_url: String) -> Self {
        Self {
            tokens: Mutex::new(VerificationTokenStore::new()),
            provider: Box::new(DevProvider),
            verify_base_url,
        }
    }

    /// Issue a verification token for a club/email; returns the raw token.
    pub fn issue(&self, club_id: BeId, email: &str) -> String {
        self.tokens
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .issue(club_id, email)
    }

    /// Redeem a raw token (single-use). Returns (club_id, email) on success.
    pub fn redeem(&self, raw: &str) -> Option<(BeId, String)> {
        self.tokens
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .redeem(raw)
    }

    /// Build the verification URL and hand it to the provider.
    pub fn send_verification(&self, email: &str, token: &str) {
        let base = self.verify_base_url.trim_end_matches('/');
        let url = format!("{base}/verify?token={token}");
        self.provider.send_verification(email, &url);
    }
}
