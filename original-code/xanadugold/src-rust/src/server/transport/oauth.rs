use std::collections::HashMap;
use std::sync::Mutex;
use std::time::{SystemTime, UNIX_EPOCH};

use axum::extract::{Query, State};
use axum::response::{Html, IntoResponse, Redirect};
use axum::Json;
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
            .insert(
                (link.provider.clone(), link.provider_user_id.clone()),
                link,
            );
    }

    pub fn create_session(
        &self,
        provider: String,
        provider_user_id: String,
        club_id: u64,
        display_name: String,
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
        };
        self.sessions
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .insert(token.clone(), session);
        token
    }

    pub fn validate_session(&self, token: &str) -> Option<(u64, String)> {
        let sessions = self.sessions.lock().unwrap_or_else(|e| e.into_inner());
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        sessions.get(token).and_then(|s| {
            if s.expires_at > now {
                Some((s.club_id, s.display_name.clone()))
            } else {
                None
            }
        })
    }

    pub fn restore_links(&self, links: Vec<OAuthLink>) {
        let mut map = self.links.lock().unwrap_or_else(|e| e.into_inner());
        for link in links {
            map.insert(
                (link.provider.clone(), link.provider_user_id.clone()),
                link,
            );
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
        return Html::<String>("<html><body><h1>GitHub sign-in is not configured</h1></body></html>".into())
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
    let provider_username = user_info.name.clone().unwrap_or_else(|| user_info.login.clone());

    handle_oauth_success(&state, "github", &provider_id, &display_name, &provider_username).await
}

pub async fn google_redirect_handler(State(state): State<SharedState>) -> axum::response::Response {
    let config = &state.oauth_config;
    if !config.google_enabled() {
        return Html::<String>("<html><body><h1>Google sign-in is not configured</h1></body></html>".into())
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
    let provider_username = user_info.email.clone().unwrap_or_else(|| user_info.name.clone());

    handle_oauth_success(&state, "google", &provider_id, &display_name, &provider_username).await
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
                srv.create_personal_club_from_oauth(
                    session_id,
                    display_name.to_string(),
                )
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
        name: json.get("name").and_then(|v| v.as_str()).map(|s| s.to_string()),
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
        email: json.get("email").and_then(|v| v.as_str()).map(|s| s.to_string()),
    })
}
