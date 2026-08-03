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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn state_issue_redeem_round_trip() {
        let state = VerificationState::new("https://example.com".into());
        let tok = state.issue(99, "round@example.com");
        assert!(!tok.is_empty());
        let (club, email) = state.redeem(&tok).expect("should redeem issued token");
        assert_eq!(club, 99);
        assert_eq!(email, "round@example.com");
        assert!(state.redeem(&tok).is_none());
    }

    #[test]
    fn state_redeem_unknown_returns_none() {
        let state = VerificationState::new("https://example.com".into());
        assert!(state.redeem("not-a-real-token").is_none());
    }

    #[test]
    fn state_send_verification_does_not_panic() {
        let state = VerificationState::new("https://example.com".into());
        let tok = state.issue(1, "a@b.com");
        state.send_verification("a@b.com", &tok);
    }

    #[test]
    fn state_send_verification_strips_trailing_slash() {
        let state = VerificationState::new("https://example.com/".into());
        let tok = state.issue(1, "a@b.com");
        state.send_verification("a@b.com", &tok);
    }
}
