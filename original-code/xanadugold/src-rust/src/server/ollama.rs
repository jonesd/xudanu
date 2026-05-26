use serde::{Deserialize, Serialize};
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum LlmFeature {
    Narration,
    AutoTitle,
    WritingFeedback,
    FindRelated,
    LinkSuggestion,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LlmUsageEntry {
    pub feature: LlmFeature,
    pub prompt_chars: u64,
    pub response_chars: u64,
    pub timestamp_secs: u64,
}

#[derive(Debug, Default, Clone, Serialize, Deserialize)]
pub struct LlmUsageSummary {
    pub total_requests: u64,
    pub total_prompt_chars: u64,
    pub total_response_chars: u64,
    pub by_feature: std::collections::HashMap<String, LlmFeatureStats>,
    pub recent: Vec<LlmUsageEntry>,
}

#[derive(Debug, Default, Clone, Serialize, Deserialize)]
pub struct LlmFeatureStats {
    pub requests: u64,
    pub prompt_chars: u64,
    pub response_chars: u64,
}

const MAX_RECENT: usize = 50;

#[derive(Debug, Default)]
pub struct LlmUsageTracker {
    total_requests: AtomicU64,
    total_prompt_chars: AtomicU64,
    total_response_chars: AtomicU64,
    inner: std::sync::Mutex<LlmUsageTrackerInner>,
}

#[derive(Debug, Default)]
struct LlmUsageTrackerInner {
    by_feature: std::collections::HashMap<LlmFeature, LlmFeatureStats>,
    recent: Vec<LlmUsageEntry>,
}

impl LlmUsageTracker {
    pub fn record(&self, feature: LlmFeature, prompt_chars: u64, response_chars: u64) {
        self.total_requests.fetch_add(1, Ordering::Relaxed);
        self.total_prompt_chars.fetch_add(prompt_chars, Ordering::Relaxed);
        self.total_response_chars.fetch_add(response_chars, Ordering::Relaxed);

        let entry = LlmUsageEntry {
            feature,
            prompt_chars,
            response_chars,
            timestamp_secs: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs(),
        };

        if let Ok(mut inner) = self.inner.lock() {
            let stats = inner.by_feature.entry(feature).or_default();
            stats.requests += 1;
            stats.prompt_chars += prompt_chars;
            stats.response_chars += response_chars;
            inner.recent.push(entry);
            if inner.recent.len() > MAX_RECENT {
                inner.recent.remove(0);
            }
        }
    }

    pub fn summary(&self) -> LlmUsageSummary {
        let total_requests = self.total_requests.load(Ordering::Relaxed);
        let total_prompt_chars = self.total_prompt_chars.load(Ordering::Relaxed);
        let total_response_chars = self.total_response_chars.load(Ordering::Relaxed);

        let (by_feature, recent) = if let Ok(inner) = self.inner.lock() {
            let by_feature = inner
                .by_feature
                .iter()
                .map(|(k, v)| {
                    let key = match k {
                        LlmFeature::Narration => "narration",
                        LlmFeature::AutoTitle => "auto_title",
                        LlmFeature::WritingFeedback => "writing_feedback",
                        LlmFeature::FindRelated => "find_related",
                        LlmFeature::LinkSuggestion => "link_suggestion",
                    };
                    (key.to_string(), v.clone())
                })
                .collect();
            (by_feature, inner.recent.clone())
        } else {
            (std::collections::HashMap::new(), Vec::new())
        };

        LlmUsageSummary {
            total_requests,
            total_prompt_chars,
            total_response_chars,
            by_feature,
            recent,
        }
    }
}

static USAGE_TRACKER: std::sync::OnceLock<LlmUsageTracker> = std::sync::OnceLock::new();

pub fn usage_tracker() -> &'static LlmUsageTracker {
    USAGE_TRACKER.get_or_init(LlmUsageTracker::default)
}

static LLM_CLIENT: std::sync::OnceLock<Option<LlmClient>> = std::sync::OnceLock::new();

pub fn llm_enabled() -> bool {
    get_client().is_some()
}

pub fn get_client() -> Option<&'static LlmClient> {
    LLM_CLIENT
        .get_or_init(|| {
            if let Ok(api_key) = std::env::var("OPENROUTER_API_KEY") {
                let model = std::env::var("OPENROUTER_MODEL")
                    .unwrap_or_else(|_| "openrouter/free".to_string());
                tracing::info!("llm: OpenRouter enabled (model={})", model);
                Some(LlmClient {
                    backend: LlmBackend::OpenRouter {
                        api_key,
                        model,
                    },
                })
            } else if let Ok(api_key) = std::env::var("GITHUB_TOKEN") {
                tracing::info!("llm: GitHub Models enabled (gpt-4o-mini)");
                Some(LlmClient {
                    backend: LlmBackend::GitHub {
                        api_key,
                        model: "gpt-4o-mini".to_string(),
                    },
                })
            } else if let Ok(base_url) = std::env::var("OLLAMA_BASE_URL") {
                let model = std::env::var("OLLAMA_MODEL")
                    .unwrap_or_else(|_| "llama3.1".to_string());
                tracing::info!("llm: Ollama enabled (model={} at {})", model, base_url);
                Some(LlmClient {
                    backend: LlmBackend::Ollama {
                        base_url,
                        model,
                    },
                })
            } else {
                tracing::info!("llm: no API key set (OPENROUTER_API_KEY, GITHUB_TOKEN, or OLLAMA_BASE_URL), LLM features disabled");
                None
            }
        })
        .as_ref()
}

#[derive(Debug, Clone)]
pub enum LlmBackend {
    OpenRouter {
        api_key: String,
        model: String,
    },
    GitHub {
        api_key: String,
        model: String,
    },
    Ollama {
        base_url: String,
        model: String,
    },
}

#[derive(Debug, Clone)]
pub struct LlmClient {
    backend: LlmBackend,
}

#[derive(Serialize)]
struct OllamaRequest {
    model: String,
    prompt: String,
    stream: bool,
}

#[derive(Deserialize)]
struct OllamaResponse {
    response: String,
    #[allow(dead_code)]
    done: bool,
}

#[derive(Serialize)]
struct ChatRequest {
    model: String,
    messages: Vec<ChatMessage>,
}

#[derive(Serialize, Deserialize)]
struct ChatMessage {
    role: String,
    content: String,
}

#[derive(Deserialize)]
struct ChatResponse {
    choices: Vec<ChatChoice>,
}

#[derive(Deserialize)]
struct ChatChoice {
    message: ChatMessage,
}

impl LlmClient {
    pub fn model_name(&self) -> &str {
        match &self.backend {
            LlmBackend::OpenRouter { model, .. } => model,
            LlmBackend::GitHub { model, .. } => model,
            LlmBackend::Ollama { model, .. } => model,
        }
    }

    pub fn backend_label(&self) -> &str {
        match &self.backend {
            LlmBackend::OpenRouter { .. } => "openrouter",
            LlmBackend::GitHub { .. } => "github-models",
            LlmBackend::Ollama { .. } => "ollama",
        }
    }

    pub fn ollama_default() -> Self {
        LlmClient {
            backend: LlmBackend::Ollama {
                base_url: "http://localhost:11434".to_string(),
                model: "llama3.1".to_string(),
            },
        }
    }

    pub async fn generate(&self, prompt: &str) -> Result<String, LlmError> {
        match &self.backend {
            LlmBackend::OpenRouter { api_key, model } => {
                self.chat_completions(
                    "https://openrouter.ai/api/v1/chat/completions",
                    api_key,
                    model,
                    prompt,
                    "openrouter",
                    30,
                ).await
            }
            LlmBackend::GitHub { api_key, model } => {
                self.chat_completions(
                    "https://models.inference.ai.azure.com/chat/completions",
                    api_key,
                    model,
                    prompt,
                    "github-models",
                    30,
                ).await
            }
            LlmBackend::Ollama { base_url, model } => {
                let url = format!("{}/api/generate", base_url.trim_end_matches('/'));
                let body = OllamaRequest {
                    model: model.clone(),
                    prompt: prompt.to_string(),
                    stream: false,
                };

                let client = reqwest::Client::new();
                let resp: reqwest::Response = client
                    .post(&url)
                    .json(&body)
                    .timeout(std::time::Duration::from_secs(120))
                    .send()
                    .await
                    .map_err(|e| LlmError::Connection(e.to_string()))?;

                if !resp.status().is_success() {
                    let status = resp.status();
                    let text = resp.text().await.unwrap_or_default();
                    return Err(LlmError::Api(format!("{}: {}", status, text)));
                }

                let gen: OllamaResponse = resp
                    .json()
                    .await
                    .map_err(|e| LlmError::Parse(e.to_string()))?;

                Ok(gen.response.trim().to_string())
            }
        }
    }

    async fn chat_completions(
        &self,
        url: &str,
        api_key: &str,
        model: &str,
        prompt: &str,
        label: &str,
        timeout_secs: u64,
    ) -> Result<String, LlmError> {
        let body = ChatRequest {
            model: model.to_string(),
            messages: vec![ChatMessage {
                role: "user".to_string(),
                content: prompt.to_string(),
            }],
        };

        tracing::info!(
            "{} request model={} prompt_len={}",
            label, model, prompt.len()
        );

        let client = reqwest::Client::new();
        let resp: reqwest::Response = client
            .post(url)
            .header("Authorization", format!("Bearer {}", api_key))
            .json(&body)
            .timeout(std::time::Duration::from_secs(timeout_secs))
            .send()
            .await
            .map_err(|e| LlmError::Connection(e.to_string()))?;

        if !resp.status().is_success() {
            let status = resp.status();
            let text = resp.text().await.unwrap_or_default();
            tracing::warn!("{} error status={} body_len={}", label, status, text.len());
            return Err(LlmError::Api(format!("{}: {}", status, text)));
        }

        let raw = resp.text().await
            .map_err(|e| LlmError::Parse(e.to_string()))?;
        tracing::info!("{} response body_len={}", label, raw.len());

        let chat: ChatResponse = serde_json::from_str(&raw)
            .map_err(|e| LlmError::Parse(format!("{}: {}", e, &raw[..raw.len().min(200)])))?;

        chat.choices
            .first()
            .map(|c| {
                tracing::info!("{} reply len={}", label, c.message.content.len());
                c.message.content.trim().to_string()
            })
            .ok_or_else(|| LlmError::Parse("no choices in response".to_string()))
    }

    pub async fn generate_tracked(&self, feature: LlmFeature, prompt: &str) -> Result<String, LlmError> {
        let prompt_len = prompt.len() as u64;
        let result = self.generate(prompt).await;
        let response_len = result.as_ref().map(|r| r.len() as u64).unwrap_or(0);
        usage_tracker().record(feature, prompt_len, response_len);
        result
    }

    #[allow(dead_code)]
    pub async fn is_available(&self) -> bool {
        match &self.backend {
            LlmBackend::OpenRouter { .. } => true,
            LlmBackend::GitHub { .. } => true,
            LlmBackend::Ollama { base_url, .. } => {
                let url = format!("{}/api/tags", base_url);
                let client = reqwest::Client::new();
                client
                    .get(&url)
                    .timeout(std::time::Duration::from_secs(3))
                    .send()
                    .await
                    .map(|r| r.status().is_success())
                    .unwrap_or(false)
            }
        }
    }
}

#[derive(Debug)]
pub enum LlmError {
    Connection(String),
    Api(String),
    Parse(String),
}

impl std::fmt::Display for LlmError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            LlmError::Connection(msg) => write!(f, "llm connection: {}", msg),
            LlmError::Api(msg) => write!(f, "llm api: {}", msg),
            LlmError::Parse(msg) => write!(f, "llm parse: {}", msg),
        }
    }
}

pub fn build_narration_prompt(
    old_text: &str,
    new_text: &str,
    author_name: Option<&str>,
) -> String {
    let author_line = author_name
        .map(|n| format!("The last author was {}.", n))
        .unwrap_or_default();

    format!(
        r#"You are a document change narrator. Compare the old and new versions of a document and describe what changed in 1-3 concise sentences. Focus on content changes, not formatting.

{author_line}

OLD VERSION:
---
{old_text}
---

NEW VERSION:
---
{new_text}
---

What changed?"#
    )
}

pub fn build_writing_feedback_prompt(content: &str) -> String {
    let truncated = &content[..content.len().min(4000)];
    format!(
        r#"You are a writing coach reviewing a document. Provide constructive feedback in 3-5 bullet points. Focus on clarity, structure, and persuasiveness. Be specific — quote passages that could be improved. If the writing is strong, say so and explain why.

Do not comment on formatting, only content and prose quality.

DOCUMENT:
---
{truncated}
---

Provide your feedback:"#
    )
}

pub fn build_title_prompt(content: &str) -> String {
    let truncated = &content[..content.len().min(2000)];
    format!(
        r#"Generate a short document title (max 8 words) for the following content. Return ONLY the title, nothing else.

{truncated}"#
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn build_prompt_basic() {
        let prompt = build_narration_prompt("hello world", "hello brave new world", None);
        assert!(prompt.contains("OLD VERSION"));
        assert!(prompt.contains("NEW VERSION"));
        assert!(prompt.contains("hello world"));
        assert!(prompt.contains("hello brave new world"));
    }

    #[test]
    fn build_prompt_with_author() {
        let prompt = build_narration_prompt("foo", "bar", Some("david"));
        assert!(prompt.contains("david"));
    }

    #[test]
    fn build_feedback_prompt_contains_content() {
        let prompt = build_writing_feedback_prompt("The quick brown fox jumps over the lazy dog.");
        assert!(prompt.contains("quick brown fox"));
        assert!(prompt.contains("writing coach"));
    }

    #[test]
    fn usage_tracker_records_and_summarizes() {
        let tracker = LlmUsageTracker::default();
        tracker.record(LlmFeature::Narration, 100, 50);
        tracker.record(LlmFeature::Narration, 200, 80);
        tracker.record(LlmFeature::AutoTitle, 50, 20);

        let summary = tracker.summary();
        assert_eq!(summary.total_requests, 3);
        assert_eq!(summary.total_prompt_chars, 350);
        assert_eq!(summary.total_response_chars, 150);
        assert_eq!(summary.recent.len(), 3);

        let narration = summary.by_feature.get("narration").unwrap();
        assert_eq!(narration.requests, 2);
        assert_eq!(narration.prompt_chars, 300);

        let auto_title = summary.by_feature.get("auto_title").unwrap();
        assert_eq!(auto_title.requests, 1);
    }
}
