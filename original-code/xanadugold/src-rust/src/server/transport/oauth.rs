use std::collections::HashMap;
use std::sync::Mutex;
use std::time::{SystemTime, UNIX_EPOCH};

use axum::extract::{Query, State};
use axum::response::{Html, IntoResponse, Redirect};
use rand::RngCore;
use serde::{Deserialize, Serialize};

use crate::server::transport::shared::SharedState;

#[derive(Debug, Clone)]
pub struct OAuthConfig {
    pub github_client_id: Option<String>,
    pub github_client_secret: Option<String>,
    pub google_client_id: Option<String>,
    pub google_client_secret: Option<String>,
    pub redirect_base: String,
}

impl Default for OAuthConfig {
    fn default() -> Self {
        OAuthConfig {
            github_client_id: None,
            github_client_secret: None,
            google_client_id: None,
            google_client_secret: None,
            redirect_base: "https://xudanu.com".to_string(),
        }
    }
}

impl OAuthConfig {
    pub fn github_enabled(&self) -> bool {
        self.github_client_id.is_some() && self.github_client_secret.is_some()
    }

    pub fn google_enabled(&self) -> bool {
        self.google_client_id.is_some() && self.google_client_secret.is_some()
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OAuthLink {
    pub provider: String,
    pub provider_user_id: String,
    pub provider_username: String,
    pub club_id: u64,
    pub created_at: u64,
}

#[derive(Debug, Clone)]
pub struct OAuthSession {
    pub provider: String,
    pub provider_user_id: String,
    pub club_id: u64,
    pub display_name: String,
    pub expires_at: u64,
    pub signing_key_bytes: Option<Vec<u8>>,
}

pub struct OAuthState {
    pub links: Mutex<HashMap<(String, String), OAuthLink>>,
    pub pending_states: Mutex<HashMap<String, u64>>,
    pub sessions: Mutex<HashMap<String, OAuthSession>>,
}

impl OAuthState {
    pub fn new() -> Self {
        OAuthState {
            links: Mutex::new(HashMap::new()),
            pending_states: Mutex::new(HashMap::new()),
            sessions: Mutex::new(HashMap::new()),
        }
    }

    pub fn generate_state(&self) -> String {
        let mut bytes = [0u8; 32];
        rand::rngs::OsRng.fill_bytes(&mut bytes);
        let token = hex::encode(&bytes);
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        self.pending_states
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .insert(token.clone(), now);
        token
    }

    pub fn validate_state(&self, state: &str) -> bool {
        let mut states = self
            .pending_states
            .lock()
            .unwrap_or_else(|e| e.into_inner());
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        states.retain(|_, ts| now.saturating_sub(*ts) < 300);
        states.remove(state).is_some()
    }

    pub fn find_link(&self, provider: &str, user_id: &str) -> Option<OAuthLink> {
        self.links
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .get(&(provider.to_string(), user_id.to_string()))
            .cloned()
    }

    pub fn store_link(&self, link: OAuthLink) {
        self.links
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .insert((link.provider.clone(), link.provider_user_id.clone()), link);
    }

    pub fn create_session(
        &self,
        provider: String,
        provider_user_id: String,
        club_id: u64,
        display_name: String,
        signing_key_bytes: Option<Vec<u8>>,
    ) -> String {
        let mut bytes = [0u8; 32];
        rand::rngs::OsRng.fill_bytes(&mut bytes);
        let token = hex::encode(&bytes);
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        let session = OAuthSession {
            provider,
            provider_user_id,
            club_id,
            display_name,
            expires_at: now + 30 * 24 * 3600,
            signing_key_bytes,
        };
        self.sessions
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .insert(token.clone(), session);
        token
    }

    pub fn validate_session(&self, token: &str) -> Option<(u64, String, Option<Vec<u8>>)> {
        let sessions = self.sessions.lock().unwrap_or_else(|e| e.into_inner());
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        sessions.get(token).and_then(|s| {
            if s.expires_at > now {
                Some((
                    s.club_id,
                    s.display_name.clone(),
                    s.signing_key_bytes.clone(),
                ))
            } else {
                None
            }
        })
    }

    pub fn destroy_session(&self, token: &str) {
        self.sessions
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .remove(token);
    }

    pub fn restore_links(&self, links: Vec<OAuthLink>) {
        let mut map = self.links.lock().unwrap_or_else(|e| e.into_inner());
        for link in links {
            map.insert((link.provider.clone(), link.provider_user_id.clone()), link);
        }
    }

    pub fn get_all_links(&self) -> Vec<OAuthLink> {
        self.links
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .values()
            .cloned()
            .collect()
    }
}

mod hex {
    pub fn encode(bytes: &[u8]) -> String {
        bytes.iter().map(|b| format!("{:02x}", b)).collect()
    }
}

#[derive(Debug, Deserialize)]
pub struct CallbackQuery {
    pub code: String,
    pub state: String,
}

pub async fn github_redirect_handler(State(state): State<SharedState>) -> axum::response::Response {
    let config = &state.oauth_config;
    if !config.github_enabled() {
        return Html::<String>(
            "<html><body><h1>GitHub sign-in is not configured</h1></body></html>".into(),
        )
        .into_response();
    }
    let state_token = state.oauth_state.generate_state();
    let client_id = config.github_client_id.as_ref().unwrap();
    let redirect_uri = format!("{}/auth/github/callback", config.redirect_base);
    let url = format!(
        "https://github.com/login/oauth/authorize?client_id={}&redirect_uri={}&state={}&scope=read:user",
        client_id,
        redirect_uri.replace(':', "%3A").replace('/', "%2F"),
        state_token,
    );
    Redirect::temporary(&url).into_response()
}

pub async fn github_callback_handler(
    Query(query): Query<CallbackQuery>,
    State(state): State<SharedState>,
) -> axum::response::Response {
    if !state.oauth_config.github_enabled() {
        return Html::<String>(
            "<html><body><h1>GitHub sign-in is not configured</h1></body></html>".into(),
        )
        .into_response();
    }

    if !state.oauth_state.validate_state(&query.state) {
        return Html::<String>(
            "<html><body><h1>Invalid or expired OAuth state. Please try again.</h1></body></html>"
                .into(),
        )
        .into_response();
    }

    let token_response = match exchange_github_code(&state, &query.code).await {
        Ok(t) => t,
        Err(e) => {
            tracing::error!("GitHub token exchange failed: {}", e);
            return Html::<String>(
                format!(
                    "<html><body><h1>GitHub authentication failed: {}</h1></body></html>",
                    e
                )
                .into(),
            )
            .into_response();
        }
    };

    let user_info = match fetch_github_user(&token_response.access_token).await {
        Ok(u) => u,
        Err(e) => {
            tracing::error!("GitHub user fetch failed: {}", e);
            return Html::<String>(
                format!(
                    "<html><body><h1>Failed to fetch GitHub profile: {}</h1></body></html>",
                    e
                )
                .into(),
            )
            .into_response();
        }
    };

    let provider_id = user_info.id.to_string();
    let display_name = user_info.login.clone();
    let provider_username = user_info
        .name
        .clone()
        .unwrap_or_else(|| user_info.login.clone());

    handle_oauth_success(
        &state,
        "github",
        &provider_id,
        &display_name,
        &provider_username,
    )
    .await
}

pub async fn google_redirect_handler(State(state): State<SharedState>) -> axum::response::Response {
    let config = &state.oauth_config;
    if !config.google_enabled() {
        return Html::<String>(
            "<html><body><h1>Google sign-in is not configured</h1></body></html>".into(),
        )
        .into_response();
    }
    let state_token = state.oauth_state.generate_state();
    let client_id = config.google_client_id.as_ref().unwrap();
    let redirect_uri = format!("{}/auth/google/callback", config.redirect_base);
    let url = format!(
        "https://accounts.google.com/o/oauth2/v2/auth?client_id={}&redirect_uri={}&response_type=code&scope=openid+profile+email&state={}",
        client_id,
        redirect_uri.replace(':', "%3A").replace('/', "%2F"),
        state_token,
    );
    Redirect::temporary(&url).into_response()
}

pub async fn google_callback_handler(
    Query(query): Query<CallbackQuery>,
    State(state): State<SharedState>,
) -> axum::response::Response {
    if !state.oauth_config.google_enabled() {
        return Html::<String>(
            "<html><body><h1>Google sign-in is not configured</h1></body></html>".into(),
        )
        .into_response();
    }

    if !state.oauth_state.validate_state(&query.state) {
        return Html::<String>(
            "<html><body><h1>Invalid or expired OAuth state. Please try again.</h1></body></html>"
                .into(),
        )
        .into_response();
    }

    let token_response = match exchange_google_code(&state, &query.code).await {
        Ok(t) => t,
        Err(e) => {
            tracing::error!("Google token exchange failed: {}", e);
            return Html::<String>(
                format!(
                    "<html><body><h1>Google authentication failed: {}</h1></body></html>",
                    e
                )
                .into(),
            )
            .into_response();
        }
    };

    let user_info = match fetch_google_user(&token_response.access_token).await {
        Ok(u) => u,
        Err(e) => {
            tracing::error!("Google user fetch failed: {}", e);
            return Html::<String>(
                format!(
                    "<html><body><h1>Failed to fetch Google profile: {}</h1></body></html>",
                    e
                )
                .into(),
            )
            .into_response();
        }
    };

    let provider_id = user_info.sub.clone();
    let display_name = user_info.name.clone();
    let provider_username = user_info
        .email
        .clone()
        .unwrap_or_else(|| user_info.name.clone());

    handle_oauth_success(
        &state,
        "google",
        &provider_id,
        &display_name,
        &provider_username,
    )
    .await
}

async fn handle_oauth_success(
    state: &SharedState,
    provider: &str,
    provider_user_id: &str,
    display_name: &str,
    provider_username: &str,
) -> axum::response::Response {
    let existing = state.oauth_state.find_link(provider, provider_user_id);

    let club_id = match existing {
        Some(link) => link.club_id,
        None => {
            let club_id = state.server.with_server(|srv| {
                let session_id = srv.connect();
                srv.create_personal_club_from_oauth(session_id, display_name.to_string())
            });
            match club_id {
                Ok(id) => {
                    let now = SystemTime::now()
                        .duration_since(UNIX_EPOCH)
                        .unwrap_or_default()
                        .as_secs();
                    state.oauth_state.store_link(OAuthLink {
                        provider: provider.to_string(),
                        provider_user_id: provider_user_id.to_string(),
                        provider_username: provider_username.to_string(),
                        club_id: id,
                        created_at: now,
                    });
                    tracing::info!(
                        target: "xudanu::security",
                        provider = provider,
                        username = provider_username,
                        club_id = id,
                        event = "OAUTH:new_account",
                        "New account via {} ({})",
                        provider,
                        provider_username,
                    );
                    id
                }
                Err(e) => {
                    tracing::error!("Failed to create OAuth club: {}", e);
                    return Html::<String>(
                        format!(
                            "<html><body><h1>Failed to create account: {}</h1></body></html>",
                            e
                        )
                        .into(),
                    )
                    .into_response();
                }
            }
        }
    };

    let session_token = state.oauth_state.create_session(
        provider.to_string(),
        provider_user_id.to_string(),
        club_id,
        display_name.to_string(),
        None,
    );

    let cookie = format!(
        "xudanu_session={}; HttpOnly; Secure; SameSite=Strict; Path=/; Max-Age=2592000",
        session_token
    );

    tracing::info!(
        target: "xudanu::security",
        provider = provider,
        club_id = club_id,
        event = "OAUTH:login",
        "OAuth login via {} as club {}",
        provider,
        club_id,
    );

    (
        axum::http::StatusCode::FOUND,
        [
            (axum::http::header::LOCATION, "/?auth=1"),
            (axum::http::header::SET_COOKIE, &cookie),
        ],
        axum::body::Body::empty(),
    )
        .into_response()
}

struct GitHubTokenResponse {
    access_token: String,
}

struct GitHubUser {
    id: u64,
    login: String,
    name: Option<String>,
}

struct GoogleUser {
    sub: String,
    name: String,
    email: Option<String>,
}

async fn exchange_github_code(
    state: &SharedState,
    code: &str,
) -> Result<GitHubTokenResponse, String> {
    let client_id = state
        .oauth_config
        .github_client_id
        .as_ref()
        .ok_or("GitHub not configured")?;
    let client_secret = state
        .oauth_config
        .github_client_secret
        .as_ref()
        .ok_or("GitHub not configured")?;

    let client = reqwest::Client::new();
    let resp = client
        .post("https://github.com/login/oauth/access_token")
        .header("Accept", "application/json")
        .json(&serde_json::json!({
            "client_id": client_id,
            "client_secret": client_secret,
            "code": code,
        }))
        .send()
        .await
        .map_err(|e| format!("HTTP request failed: {}", e))?;

    let json: serde_json::Value = resp
        .json()
        .await
        .map_err(|e| format!("JSON parse failed: {}", e))?;

    let access_token = json
        .get("access_token")
        .and_then(|v| v.as_str())
        .ok_or_else(|| {
            format!(
                "No access_token in response: {}",
                json.get("error_description")
                    .and_then(|v| v.as_str())
                    .unwrap_or("unknown error")
            )
        })?
        .to_string();

    Ok(GitHubTokenResponse { access_token })
}

async fn fetch_github_user(access_token: &str) -> Result<GitHubUser, String> {
    let client = reqwest::Client::new();
    let resp = client
        .get("https://api.github.com/user")
        .header("Authorization", format!("Bearer {}", access_token))
        .header("User-Agent", "xudanu")
        .send()
        .await
        .map_err(|e| format!("HTTP request failed: {}", e))?;

    let json: serde_json::Value = resp
        .json()
        .await
        .map_err(|e| format!("JSON parse failed: {}", e))?;

    Ok(GitHubUser {
        id: json
            .get("id")
            .and_then(|v| v.as_u64())
            .ok_or("Missing id in GitHub user response")?,
        login: json
            .get("login")
            .and_then(|v| v.as_str())
            .ok_or("Missing login in GitHub user response")?
            .to_string(),
        name: json
            .get("name")
            .and_then(|v| v.as_str())
            .map(|s| s.to_string()),
    })
}

async fn exchange_google_code(
    state: &SharedState,
    code: &str,
) -> Result<GitHubTokenResponse, String> {
    let client_id = state
        .oauth_config
        .google_client_id
        .as_ref()
        .ok_or("Google not configured")?;
    let client_secret = state
        .oauth_config
        .google_client_secret
        .as_ref()
        .ok_or("Google not configured")?;

    let redirect_uri = format!("{}/auth/google/callback", state.oauth_config.redirect_base);

    let client = reqwest::Client::new();
    let resp = client
        .post("https://oauth2.googleapis.com/token")
        .json(&serde_json::json!({
            "client_id": client_id,
            "client_secret": client_secret,
            "code": code,
            "redirect_uri": redirect_uri,
            "grant_type": "authorization_code",
        }))
        .send()
        .await
        .map_err(|e| format!("HTTP request failed: {}", e))?;

    let json: serde_json::Value = resp
        .json()
        .await
        .map_err(|e| format!("JSON parse failed: {}", e))?;

    let access_token = json
        .get("access_token")
        .and_then(|v| v.as_str())
        .ok_or_else(|| {
            format!(
                "No access_token in response: {}",
                json.get("error_description")
                    .and_then(|v| v.as_str())
                    .unwrap_or("unknown error")
            )
        })?
        .to_string();

    Ok(GitHubTokenResponse { access_token })
}

async fn fetch_google_user(access_token: &str) -> Result<GoogleUser, String> {
    let client = reqwest::Client::new();
    let resp = client
        .get("https://www.googleapis.com/oauth2/v3/userinfo")
        .header("Authorization", format!("Bearer {}", access_token))
        .send()
        .await
        .map_err(|e| format!("HTTP request failed: {}", e))?;

    let json: serde_json::Value = resp
        .json()
        .await
        .map_err(|e| format!("JSON parse failed: {}", e))?;

    Ok(GoogleUser {
        sub: json
            .get("sub")
            .and_then(|v| v.as_str())
            .ok_or("Missing sub in Google user response")?
            .to_string(),
        name: json
            .get("name")
            .and_then(|v| v.as_str())
            .unwrap_or("Unknown")
            .to_string(),
        email: json
            .get("email")
            .and_then(|v| v.as_str())
            .map(|s| s.to_string()),
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::server::transport::shared::AppState;
    use crate::server::Server;

    /// Build a SharedState with a given OAuth config, resetting the OAuth state.
    fn make_state(config: OAuthConfig) -> std::sync::Arc<AppState> {
        AppState::new(Server::new()).with_oauth(config).shared()
    }

    fn mk_link(provider: &str, uid: &str, club: u64) -> OAuthLink {
        OAuthLink {
            provider: provider.to_string(),
            provider_user_id: uid.to_string(),
            provider_username: format!("user-{}", uid),
            club_id: club,
            created_at: 1000,
        }
    }

    // ---- OAuthConfig ----

    #[test]
    fn oauth_config_default_disables_both_providers() {
        let cfg = OAuthConfig::default();
        assert!(!cfg.github_enabled());
        assert!(!cfg.google_enabled());
        assert!(cfg.github_client_id.is_none());
        assert!(cfg.github_client_secret.is_none());
        assert!(cfg.google_client_id.is_none());
        assert!(cfg.google_client_secret.is_none());
        assert_eq!(cfg.redirect_base, "https://xudanu.com");
    }

    #[test]
    fn oauth_config_github_enabled_requires_both_id_and_secret() {
        let mut cfg = OAuthConfig::default();
        assert!(!cfg.github_enabled());
        cfg.github_client_id = Some("id".into());
        assert!(!cfg.github_enabled(), "secret still missing");
        cfg.github_client_secret = Some("secret".into());
        assert!(cfg.github_enabled());
    }

    #[test]
    fn oauth_config_google_enabled_requires_both_id_and_secret() {
        let mut cfg = OAuthConfig::default();
        cfg.google_client_id = Some("id".into());
        assert!(!cfg.google_enabled());
        cfg.google_client_secret = Some("secret".into());
        assert!(cfg.google_enabled());
    }

    // ---- OAuthLink storage ----

    #[test]
    fn store_and_find_link_roundtrip() {
        let state = OAuthState::new();
        state.store_link(mk_link("github", "123", 42));
        let found = state.find_link("github", "123").expect("link present");
        assert_eq!(found.club_id, 42);
        assert_eq!(found.provider_username, "user-123");
        assert_eq!(found.provider, "github");
    }

    #[test]
    fn find_link_missing_returns_none() {
        let state = OAuthState::new();
        assert!(state.find_link("github", "nope").is_none());
    }

    #[test]
    fn find_link_distinguishes_providers() {
        let state = OAuthState::new();
        state.store_link(mk_link("github", "1", 10));
        state.store_link(mk_link("google", "1", 20));
        assert_eq!(state.find_link("github", "1").unwrap().club_id, 10);
        assert_eq!(state.find_link("google", "1").unwrap().club_id, 20);
    }

    #[test]
    fn store_link_overwrites_same_provider_and_user() {
        let state = OAuthState::new();
        state.store_link(mk_link("github", "1", 1));
        state.store_link(mk_link("github", "1", 2));
        assert_eq!(state.find_link("github", "1").unwrap().club_id, 2);
    }

    #[test]
    fn restore_links_and_get_all_roundtrip() {
        let state = OAuthState::new();
        let links = vec![mk_link("github", "1", 1), mk_link("google", "9", 2)];
        state.restore_links(links);
        let all = state.get_all_links();
        assert_eq!(all.len(), 2);
    }

    // ---- state token (CSRF) ----

    #[test]
    fn generate_state_returns_hex_token() {
        let state = OAuthState::new();
        let token = state.generate_state();
        assert_eq!(token.len(), 64, "32 bytes -> 64 hex chars");
        assert!(token.chars().all(|c| c.is_ascii_hexdigit()));
        // {:02x} always emits lowercase a-f for letters
        assert!(token
            .chars()
            .filter(|c| c.is_alphabetic())
            .all(|c| c.is_ascii_lowercase()));
    }

    #[test]
    fn validate_state_accepts_freshly_generated_token() {
        let state = OAuthState::new();
        let token = state.generate_state();
        assert!(state.validate_state(&token));
    }

    #[test]
    fn validate_state_is_single_use() {
        let state = OAuthState::new();
        let token = state.generate_state();
        assert!(state.validate_state(&token), "first use should succeed");
        assert!(!state.validate_state(&token), "second use must be rejected");
    }

    #[test]
    fn validate_state_rejects_unknown_token() {
        let state = OAuthState::new();
        assert!(!state.validate_state(
            "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
        ));
    }

    #[test]
    fn validate_state_rejects_tampered_token() {
        let state = OAuthState::new();
        let mut token = state.generate_state();
        let first = token.as_bytes()[0];
        let replacement = if first == b'0' { '1' } else { '0' };
        token.replace_range(0..1, &replacement.to_string());
        assert!(!state.validate_state(&token));
    }

    #[test]
    fn generate_state_produces_distinct_tokens() {
        let state = OAuthState::new();
        let a = state.generate_state();
        let b = state.generate_state();
        assert_ne!(a, b);
    }

    // ---- sessions ----

    #[test]
    fn create_session_returns_validatable_token() {
        let state = OAuthState::new();
        let token = state.create_session(
            "github".into(),
            "u1".into(),
            7,
            "Alice".into(),
            Some(vec![1, 2, 3]),
        );
        let (club_id, name, key) = state.validate_session(&token).expect("session valid");
        assert_eq!(club_id, 7);
        assert_eq!(name, "Alice");
        assert_eq!(key, Some(vec![1, 2, 3]));
    }

    #[test]
    fn validate_session_unknown_returns_none() {
        let state = OAuthState::new();
        assert!(state.validate_session("nope").is_none());
    }

    #[test]
    fn destroy_session_invalidates_token() {
        let state = OAuthState::new();
        let token = state.create_session("p".into(), "u".into(), 1, "n".into(), None);
        assert!(state.validate_session(&token).is_some());
        state.destroy_session(&token);
        assert!(state.validate_session(&token).is_none());
    }

    #[test]
    fn create_session_token_is_hex() {
        let state = OAuthState::new();
        let token = state.create_session("p".into(), "u".into(), 1, "n".into(), None);
        assert_eq!(token.len(), 64);
        assert!(token.chars().all(|c| c.is_ascii_hexdigit()));
    }

    // ---- local hex helper module ----

    #[test]
    fn local_hex_encode_matches_builtin_format() {
        assert_eq!(super::hex::encode(&[0x00, 0xab, 0xff]), "00abff");
        assert_eq!(super::hex::encode(&[]), "");
    }

    // ---- redirect URL building (no network I/O) ----

    #[tokio::test]
    async fn github_redirect_when_disabled_returns_html() {
        let state = make_state(OAuthConfig::default());
        let resp = github_redirect_handler(State(state)).await;
        assert_eq!(resp.status(), axum::http::StatusCode::OK);
    }

    #[tokio::test]
    async fn github_redirect_builds_authorize_url() {
        let cfg = OAuthConfig {
            github_client_id: Some("gh_client".into()),
            github_client_secret: Some("gh_secret".into()),
            redirect_base: "https://test.example.com".into(),
            ..Default::default()
        };
        let state = make_state(cfg);
        let resp = github_redirect_handler(State(state)).await;
        assert_eq!(
            resp.status(),
            axum::http::StatusCode::TEMPORARY_REDIRECT,
            "disabled provider should not redirect"
        );
        let location = resp
            .headers()
            .get(axum::http::header::LOCATION)
            .and_then(|v| v.to_str().ok())
            .expect("Location header present");
        assert!(location.starts_with("https://github.com/login/oauth/authorize?"));
        assert!(location.contains("client_id=gh_client"));
        assert!(location.contains("scope=read:user"));
        assert!(location
            .contains("redirect_uri=https%3A%2F%2Ftest.example.com%2Fauth%2Fgithub%2Fcallback"));
        // state token is the last segment before scope; must be 64 hex chars
        let state_val = location.split("state=").nth(1).unwrap();
        let token = state_val.split('&').next().unwrap();
        assert_eq!(token.len(), 64);
        assert!(token.chars().all(|c| c.is_ascii_hexdigit()));
    }

    #[tokio::test]
    async fn google_redirect_when_disabled_returns_html() {
        let state = make_state(OAuthConfig::default());
        let resp = google_redirect_handler(State(state)).await;
        assert_eq!(resp.status(), axum::http::StatusCode::OK);
    }

    #[tokio::test]
    async fn google_redirect_builds_authorize_url() {
        let cfg = OAuthConfig {
            google_client_id: Some("g_client".into()),
            google_client_secret: Some("g_secret".into()),
            redirect_base: "https://test.example.com".into(),
            ..Default::default()
        };
        let state = make_state(cfg);
        let resp = google_redirect_handler(State(state)).await;
        assert_eq!(resp.status(), axum::http::StatusCode::TEMPORARY_REDIRECT);
        let location = resp
            .headers()
            .get(axum::http::header::LOCATION)
            .and_then(|v| v.to_str().ok())
            .expect("Location header present");
        assert!(location.starts_with("https://accounts.google.com/o/oauth2/v2/auth?"));
        assert!(location.contains("client_id=g_client"));
        assert!(location.contains("response_type=code"));
        assert!(location.contains("scope=openid+profile+email"));
        assert!(location
            .contains("redirect_uri=https%3A%2F%2Ftest.example.com%2Fauth%2Fgoogle%2Fcallback"));
        assert!(location.contains("state="));
    }
}
