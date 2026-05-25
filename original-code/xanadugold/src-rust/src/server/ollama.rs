use serde::{Deserialize, Serialize};

#[derive(Debug, Clone)]
pub enum LlmBackend {
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
    pub fn github_default() -> Self {
        let api_key = std::env::var("GITHUB_TOKEN")
            .expect("GITHUB_TOKEN environment variable must be set");
        LlmClient {
            backend: LlmBackend::GitHub {
                api_key,
                model: "gpt-4o-mini".to_string(),
            },
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

    pub fn default_client() -> Self {
        Self::github_default()
    }

    pub async fn generate(&self, prompt: &str) -> Result<String, LlmError> {
        match &self.backend {
            LlmBackend::GitHub { api_key, model } => {
                let url = "https://models.inference.ai.azure.com/chat/completions";
                let body = ChatRequest {
                    model: model.clone(),
                    messages: vec![ChatMessage {
                        role: "user".to_string(),
                        content: prompt.to_string(),
                    }],
                };

                tracing::info!(
                    "github-models request model={} prompt_len={}",
                    model,
                    prompt.len()
                );

                let client = reqwest::Client::new();
                let resp: reqwest::Response = client
                    .post(url)
                    .header("Authorization", format!("Bearer {}", api_key))
                    .json(&body)
                    .timeout(std::time::Duration::from_secs(30))
                    .send()
                    .await
                    .map_err(|e| LlmError::Connection(e.to_string()))?;

                if !resp.status().is_success() {
                    let status = resp.status();
                    let text = resp.text().await.unwrap_or_default();
                    tracing::warn!("github-models error status={} body_len={}", status, text.len());
                    return Err(LlmError::Api(format!("{}: {}", status, text)));
                }

                let raw = resp.text().await
                    .map_err(|e| LlmError::Parse(e.to_string()))?;
                tracing::info!("github-models response body_len={}", raw.len());

                let chat: ChatResponse = serde_json::from_str(&raw)
                    .map_err(|e| LlmError::Parse(format!("{}: {}", e, &raw[..raw.len().min(200)])))?;

                chat.choices
                    .first()
                    .map(|c| {
                        tracing::info!("github-models reply len={}", c.message.content.len());
                        c.message.content.trim().to_string()
                    })
                    .ok_or_else(|| LlmError::Parse("no choices in response".to_string()))
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

    #[allow(dead_code)]
    pub async fn is_available(&self) -> bool {
        match &self.backend {
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
}
