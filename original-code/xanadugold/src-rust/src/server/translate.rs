//! FR-155: cross-language transclusion — translation as a PROV edge.
//!
//! A machine translation is a derivation edge, never a write-side
//! mutation: `(span content, source lang, target lang, provider,
//! model)` → content-addressed rendition. The edge tuple IS the
//! cache key. Nothing here runs at authoring time; renditions exist
//! only because a reader asked (`?lang=` on the public read path).
//!
//! Zero-behavior-change guarantee: with `XUDANU_TRANSLATE_PROVIDER_URL`
//! unset (the default) every public entry point below reports
//! disabled and the read path serves byte-identical responses.
//!
//! Lock discipline (FR-86 lesson): provider I/O is reqwest::blocking
//! and MUST run outside any server state lock. The HTTP handler
//! gathers state under short locks, then assembles inside
//! `spawn_blocking`.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

pub const PROVIDER_URL_ENV: &str = "XUDANU_TRANSLATE_PROVIDER_URL";
pub const PROVIDER_NAME_ENV: &str = "XUDANU_TRANSLATE_PROVIDER";
pub const PROVIDER_MODEL_ENV: &str = "XUDANU_TRANSLATE_MODEL";
pub const PROVIDER_KEY_ENV: &str = "XUDANU_TRANSLATE_API_KEY";

/// Annotation kind that declares a run's language (FR-155 direction:
/// declared, never detected — detection output is version-dependent
/// and must never touch a stable key).
pub const LANGUAGE_ANNOTATION_KIND: &str = "language";

static TRANSLATE_CLIENT: OnceLock<Option<TranslateClient>> = OnceLock::new();

pub fn translate_enabled() -> bool {
    get_client().is_some()
}

pub fn get_client() -> Option<&'static TranslateClient> {
    TRANSLATE_CLIENT
        .get_or_init(|| {
            let Ok(base_url) = std::env::var(PROVIDER_URL_ENV) else {
                tracing::info!(
                    "translate: {} unset, machine renditions disabled",
                    PROVIDER_URL_ENV
                );
                return None;
            };
            let provider = std::env::var(PROVIDER_NAME_ENV).unwrap_or_else(|_| "argos".to_string());
            let model = std::env::var(PROVIDER_MODEL_ENV)
                .unwrap_or_else(|_| format!("{provider}/unspecified"));
            if model.ends_with("/unspecified") {
                tracing::warn!(
                    "translate: {} not set — model identity rides provenance edges as \"{}\"; \
                     set it to the real model/version",
                    PROVIDER_MODEL_ENV,
                    model
                );
            }
            let api_key = std::env::var(PROVIDER_KEY_ENV)
                .ok()
                .filter(|k| !k.is_empty());
            tracing::info!(
                "translate: enabled (provider={} model={} at {})",
                provider,
                model,
                base_url
            );
            Some(TranslateClient {
                base_url,
                provider,
                model,
                api_key,
            })
        })
        .as_ref()
}

#[derive(Debug, Clone)]
pub struct TranslateClient {
    base_url: String,
    provider: String,
    model: String,
    api_key: Option<String>,
}

#[derive(Debug)]
pub enum TranslateError {
    Http(String),
    Status(u16),
    Unexpected(String),
}

impl std::fmt::Display for TranslateError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            TranslateError::Http(e) => write!(f, "provider unreachable: {e}"),
            TranslateError::Status(s) => write!(f, "provider returned status {s}"),
            TranslateError::Unexpected(m) => write!(f, "unexpected provider response: {m}"),
        }
    }
}

/// What a provider must name to participate: its identity and its
/// model. The model string rides every cache key and provenance edge
/// (spike invariant: the provider must name its model).
pub trait RenditionProvider {
    fn provider_name(&self) -> &str;
    fn model_name(&self) -> &str;
    fn translate_batch(
        &self,
        texts: &[&str],
        source_lang: &str,
        target_lang: &str,
    ) -> Result<Vec<String>, TranslateError>;
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ProviderLanguage {
    pub code: String,
    pub name: String,
    #[serde(default)]
    pub targets: Vec<String>,
}

#[derive(Serialize)]
struct LtTranslateRequest<'a> {
    q: &'a [&'a str],
    source: &'a str,
    target: &'a str,
    format: &'a str,
    #[serde(skip_serializing_if = "Option::is_none")]
    api_key: Option<&'a str>,
}

#[derive(Deserialize)]
struct LtTranslateResponse {
    #[serde(default, rename = "translatedText")]
    translated_text: serde_json::Value,
}

fn json_strings(value: serde_json::Value) -> Result<Vec<String>, TranslateError> {
    match value {
        serde_json::Value::Array(items) => {
            let mut out = Vec::with_capacity(items.len());
            for item in items {
                match item {
                    serde_json::Value::String(s) => out.push(s),
                    serde_json::Value::Object(o) => {
                        // Some LibreTranslate builds wrap array items as
                        // {"translatedText": "..."} when alternatives are on.
                        let s = o
                            .get("translatedText")
                            .and_then(|v| v.as_str())
                            .ok_or_else(|| {
                                TranslateError::Unexpected("array item without text".into())
                            })?;
                        out.push(s.to_string());
                    }
                    _ => {
                        return Err(TranslateError::Unexpected(
                            "non-string entry in translatedText".into(),
                        ))
                    }
                }
            }
            Ok(out)
        }
        serde_json::Value::String(s) => Ok(vec![s]),
        _ => Err(TranslateError::Unexpected("translatedText missing".into())),
    }
}

impl RenditionProvider for TranslateClient {
    fn provider_name(&self) -> &str {
        &self.provider
    }

    fn model_name(&self) -> &str {
        &self.model
    }

    fn translate_batch(
        &self,
        texts: &[&str],
        source_lang: &str,
        target_lang: &str,
    ) -> Result<Vec<String>, TranslateError> {
        let body = serde_json::to_value(LtTranslateRequest {
            q: texts,
            source: source_lang,
            target: target_lang,
            format: "text",
            api_key: self.api_key.as_deref(),
        })
        .map_err(|e| TranslateError::Unexpected(e.to_string()))?;
        let url = format!("{}/translate", self.base_url);
        let client = reqwest::blocking::Client::builder()
            .timeout(Duration::from_secs(30))
            .build()
            .map_err(|e| TranslateError::Http(e.to_string()))?;
        let resp = client
            .post(&url)
            .json(&body)
            .send()
            .map_err(|e| TranslateError::Http(e.to_string()))?;
        let status = resp.status();
        if !status.is_success() {
            return Err(TranslateError::Status(status.as_u16()));
        }
        let parsed: LtTranslateResponse = resp
            .json()
            .map_err(|e| TranslateError::Unexpected(e.to_string()))?;
        let out = json_strings(parsed.translated_text)?;
        if out.len() != texts.len() {
            return Err(TranslateError::Unexpected(format!(
                "provider returned {} renditions for {} spans",
                out.len(),
                texts.len()
            )));
        }
        Ok(out)
    }
}

impl TranslateClient {
    pub fn provider(&self) -> &str {
        &self.provider
    }

    pub fn model(&self) -> &str {
        &self.model
    }

    /// Capability discovery against the provider's `/languages`
    /// endpoint (LibreTranslate shape). Cached for an hour; failures
    /// are not cached.
    pub fn languages(&self) -> Result<Vec<ProviderLanguage>, TranslateError> {
        {
            let cache = languages_cache();
            let guard = cache.lock().expect("languages cache lock");
            if let Some((at, langs)) = guard.as_ref() {
                if at.elapsed() < Duration::from_secs(3600) {
                    return Ok(langs.clone());
                }
            }
        }
        let url = format!("{}/languages", self.base_url);
        let client = reqwest::blocking::Client::builder()
            .timeout(Duration::from_secs(10))
            .build()
            .map_err(|e| TranslateError::Http(e.to_string()))?;
        let resp = client
            .get(&url)
            .send()
            .map_err(|e| TranslateError::Http(e.to_string()))?;
        let status = resp.status();
        if !status.is_success() {
            return Err(TranslateError::Status(status.as_u16()));
        }
        let langs: Vec<ProviderLanguage> = resp
            .json()
            .map_err(|e| TranslateError::Unexpected(e.to_string()))?;
        let mut guard = languages_cache().lock().expect("languages cache lock");
        *guard = Some((Instant::now(), langs.clone()));
        Ok(langs)
    }
}

/// Cached `/languages` result with fetch time (1h TTL; failures are
/// not cached).
type LanguagesCache = Mutex<Option<(Instant, Vec<ProviderLanguage>)>>;

fn languages_cache() -> &'static LanguagesCache {
    static CACHE: OnceLock<LanguagesCache> = OnceLock::new();
    CACHE.get_or_init(|| Mutex::new(None))
}

// === Content-addressed rendition cache ===
//
// The edge tuple is the cache key. Memory is the hot layer; the
// durable layer below survives restarts (Stage 3).

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TranslationEntry {
    pub source_hash: String,
    pub source_lang: String,
    pub target_lang: String,
    pub provider: String,
    pub model: String,
    pub rendition: String,
    pub rendition_hash: String,
    pub created_at: u64,
}

impl TranslationEntry {
    /// PROV rendering: the rendition was derived from the source
    /// span by a named translation activity (engine identity rides
    /// the edge — per-instance compliance is auditable from the
    /// graph).
    pub fn to_prov_json(&self) -> serde_json::Value {
        serde_json::json!({
            "source_hash": self.source_hash,
            "rendition_hash": self.rendition_hash,
            "source_lang": self.source_lang,
            "target_lang": self.target_lang,
            "provider": self.provider,
            "model": self.model,
            "created_at": self.created_at,
            "prov": {
                "entity": self.rendition_hash,
                "wasDerivedFrom": self.source_hash,
                "wasGeneratedBy": "xudanu:Translation",
                "quality_grade": "machine-gisting",
            },
        })
    }
}

/// BLAKE3 over the length-prefixed edge tuple, domain-separated so
/// field boundaries cannot be smeared across components.
pub fn cache_key(
    text: &str,
    source_lang: &str,
    target_lang: &str,
    provider: &str,
    model: &str,
) -> blake3::Hash {
    let mut hasher = blake3::Hasher::new();
    hasher.update(b"xudanu:translation-edge:1");
    for part in [
        text.as_bytes(),
        source_lang.as_bytes(),
        target_lang.as_bytes(),
        provider.as_bytes(),
        model.as_bytes(),
    ] {
        hasher.update(&(part.len() as u64).to_le_bytes());
        hasher.update(part);
    }
    hasher.finalize()
}

fn translation_cache() -> &'static Mutex<HashMap<blake3::Hash, TranslationEntry>> {
    static CACHE: OnceLock<Mutex<HashMap<blake3::Hash, TranslationEntry>>> = OnceLock::new();
    CACHE.get_or_init(|| Mutex::new(HashMap::new()))
}

pub fn cache_get(key: &blake3::Hash) -> Option<TranslationEntry> {
    translation_cache()
        .lock()
        .expect("translation cache lock")
        .get(key)
        .cloned()
}

pub fn cache_len() -> usize {
    translation_cache()
        .lock()
        .expect("translation cache lock")
        .len()
}

/// Insert an entry under an externally computed key. The caller owns
/// the source text; the entry itself does not carry it, so the key
/// cannot be re-derived from the entry alone.
pub fn cache_put_entry(key: blake3::Hash, entry: TranslationEntry) {
    translation_cache()
        .lock()
        .expect("translation cache lock")
        .insert(key, entry);
}

#[cfg(test)]
pub fn cache_clear_for_tests() {
    translation_cache()
        .lock()
        .expect("translation cache lock")
        .clear();
}

// === Durable content-addressed rendition store (Stage 3) ===
//
// One JSON file per rendition under `<data>/renditions/<xx>/<key>.json`,
// named by the cache key (BLAKE3 of the edge tuple) — the blob
// store's sharding convention. A restarted server finds every
// warmed rendition on disk, so a read that would have been an engine
// call becomes a small file read. A corrupt or future-format file is
// treated as a miss (retranslate, overwrite): format evolution
// self-heals instead of failing reads. Writes are temp-file + rename
// (atomic visibility); a crashed `.tmp` leftover is never read.

/// Stateless handle: a base path and nothing else — cheap to clone
/// and share. Attached to `AppState` only when the server runs with
/// a data directory; `None` keeps Stage 2's memory-only behavior.
#[derive(Debug, Clone)]
pub struct RenditionStore {
    base: std::path::PathBuf,
}

impl RenditionStore {
    pub fn open(base: impl Into<std::path::PathBuf>) -> std::io::Result<Self> {
        let base = base.into();
        std::fs::create_dir_all(&base)?;
        tracing::info!("translate: durable rendition store at {}", base.display());
        Ok(RenditionStore { base })
    }

    fn entry_path(&self, key: &blake3::Hash) -> std::path::PathBuf {
        let hex = key.to_hex().to_string();
        self.base.join(&hex[..2]).join(format!("{hex}.json"))
    }

    pub fn get(&self, key: &blake3::Hash) -> Option<TranslationEntry> {
        let path = self.entry_path(key);
        let data = std::fs::read_to_string(&path).ok()?;
        let entry: TranslationEntry = match serde_json::from_str(&data) {
            Ok(entry) => entry,
            Err(err) => {
                tracing::warn!(
                    "translate: unreadable rendition {} ({}): treated as a miss",
                    path.display(),
                    err
                );
                return None;
            }
        };
        // Content check: the file is named by the INPUT tuple key, so
        // unlike chunks the name proves nothing about the payload.
        // A rendition that does not hash to its own rendition_hash
        // (corruption or tampering) is a miss — retranslated and
        // overwritten on the next read. Self-heals, never serves.
        if blake3::hash(entry.rendition.as_bytes())
            .to_hex()
            .to_string()
            != entry.rendition_hash
        {
            tracing::warn!(
                "translate: rendition {} failed its content hash — treated as a miss",
                path.display()
            );
            return None;
        }
        Some(entry)
    }

    pub fn put(&self, key: &blake3::Hash, entry: &TranslationEntry) {
        let path = self.entry_path(key);
        let write = || -> std::io::Result<()> {
            if let Some(dir) = path.parent() {
                std::fs::create_dir_all(dir)?;
            }
            let json = serde_json::to_string_pretty(entry)
                .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
            let tmp = path.with_extension("tmp");
            std::fs::write(&tmp, json.as_bytes())?;
            std::fs::rename(&tmp, &path)?;
            Ok(())
        };
        if let Err(err) = write() {
            tracing::warn!(
                "translate: rendition persist failed at {}: {} (memory cache still serves)",
                path.display(),
                err
            );
        }
    }

    /// Entries on disk. Walks the shards — admin-frequency use, not
    /// for the read path.
    pub fn count(&self) -> usize {
        let Ok(shards) = std::fs::read_dir(&self.base) else {
            return 0;
        };
        let mut n = 0usize;
        for shard in shards.flatten() {
            let Ok(files) = std::fs::read_dir(shard.path()) else {
                continue;
            };
            n += files
                .flatten()
                .filter(|f| {
                    f.file_name()
                        .to_str()
                        .is_some_and(|name| name.ends_with(".json"))
                })
                .count();
        }
        n
    }

    pub fn base(&self) -> &std::path::Path {
        &self.base
    }
}

// === Language declaration resolution ===
//
// Language is a declared fact riding the open-typed annotation
// system: `kind: "language"`, payload `{"lang": "<BCP-47 tag>"}`.
// An empty char range (start == end) declares the document default;
// a real range overrides for that run. Narrowest covering override
// wins. Undeclared runs are never guessed — pin, never detect.

#[derive(Debug, Clone, PartialEq)]
pub struct LanguageOverride {
    pub lang: String,
    pub char_start: usize,
    pub char_end: usize,
}

pub fn valid_language_tag(tag: &str) -> bool {
    let mut parts = tag.split('-');
    let primary = parts.next().unwrap_or("");
    let primary_ok =
        (2..=8).contains(&primary.len()) && primary.chars().all(|c| c.is_ascii_alphabetic());
    if !primary_ok {
        return false;
    }
    let mut subtags = 0usize;
    for part in parts {
        if !(1..=8).contains(&part.len()) || !part.chars().all(|c| c.is_ascii_alphanumeric()) {
            return false;
        }
        subtags += 1;
        if subtags > 3 {
            return false;
        }
    }
    true
}

/// Parse `(kind, payload_json, char_start, char_end)` annotation
/// tuples (public annotations only, filtered upstream) into a
/// document default plus run overrides. Malformed payloads and
/// invalid tags are skipped, never guessed.
pub fn parse_language_annotations(
    raw: &[(String, String, usize, usize)],
) -> (Option<String>, Vec<LanguageOverride>) {
    let mut doc_default: Option<String> = None;
    let mut overrides = Vec::new();
    for (kind, payload, char_start, char_end) in raw {
        if kind != LANGUAGE_ANNOTATION_KIND {
            continue;
        }
        let Ok(value) = serde_json::from_str::<serde_json::Value>(payload) else {
            continue;
        };
        let Some(lang) = value.get("lang").and_then(|l| l.as_str()) else {
            continue;
        };
        if !valid_language_tag(lang) {
            continue;
        }
        if char_start == char_end {
            if doc_default.is_none() {
                doc_default = Some(lang.to_string());
            }
        } else if char_end > char_start {
            overrides.push(LanguageOverride {
                lang: lang.to_string(),
                char_start: *char_start,
                char_end: *char_end,
            });
        }
    }
    (doc_default, overrides)
}

/// The declared source language for a run `[start, end)`, or None
/// when nothing covers it. Narrowest covering override wins; absent
/// an override the document default applies.
pub fn span_source_language(
    doc_default: Option<&str>,
    overrides: &[LanguageOverride],
    start: usize,
    end: usize,
) -> Option<String> {
    if end <= start {
        return doc_default.map(str::to_string);
    }
    let mut best: Option<&LanguageOverride> = None;
    for o in overrides {
        if o.char_start <= start && end <= o.char_end {
            let better =
                best.is_none_or(|b| (o.char_end - o.char_start) < (b.char_end - b.char_start));
            if better {
                best = Some(o);
            }
        }
    }
    match best {
        Some(o) => Some(o.lang.clone()),
        None => doc_default.map(str::to_string),
    }
}

// === Read-path assembly ===

#[derive(Debug, Clone)]
pub struct TextSpanView {
    pub char_start: usize,
    pub char_end: usize,
    pub text: String,
}

#[derive(Debug)]
pub struct TranslatedRead {
    pub text: String,
    pub provider_calls: usize,
    pub block: serde_json::Value,
}

/// Build the translated document text plus its provenance block.
/// Pure with respect to the server: the original rendered text,
/// spans, annotations, and the provider are handed in; the only
/// side effects are the rendition caches and the provider call.
/// Runs under `spawn_blocking`. Gaps between spans (newlines and
/// other layout) are copied verbatim from the original so the
/// translated document keeps its shape. `store`, when present, is
/// consulted after the memory cache and written on every fresh
/// rendition (Stage 3 durability: renditions survive restarts).
pub fn assemble_translated_read<P: RenditionProvider>(
    original_text: &str,
    spans: &[TextSpanView],
    annotations: &[(String, String, usize, usize)],
    target_lang: &str,
    provider: &P,
    store: Option<&RenditionStore>,
) -> TranslatedRead {
    let (doc_default, overrides) = parse_language_annotations(annotations);
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);

    let mut renditions: Vec<Option<TranslationEntry>> = Vec::with_capacity(spans.len());
    let mut same_language = 0usize;
    let mut undeclared = 0usize;
    let mut cache_hits = 0usize;
    let mut disk_hits = 0usize;
    // (span index, source lang) for cache misses, grouped per source
    // language below so each provider batch is one (source, target)
    // pair.
    let mut misses: Vec<(usize, String)> = Vec::new();

    for (idx, span) in spans.iter().enumerate() {
        let source_lang = span_source_language(
            doc_default.as_deref(),
            &overrides,
            span.char_start,
            span.char_end,
        );
        let Some(source_lang) = source_lang else {
            undeclared += 1;
            renditions.push(None);
            continue;
        };
        if source_lang == target_lang {
            same_language += 1;
            renditions.push(None);
            continue;
        }
        let key = cache_key(
            &span.text,
            &source_lang,
            target_lang,
            provider.provider_name(),
            provider.model_name(),
        );
        if let Some(hit) = cache_get(&key) {
            cache_hits += 1;
            renditions.push(Some(hit));
        } else if let Some(entry) = store.and_then(|s| s.get(&key)) {
            // Disk hit after a restart: promote to memory so this is
            // the only file read for this key.
            disk_hits += 1;
            cache_put_entry(key, entry.clone());
            renditions.push(Some(entry));
        } else {
            misses.push((idx, source_lang));
            renditions.push(None);
        }
    }

    let mut provider_calls = 0usize;
    let mut errors: Vec<String> = Vec::new();
    let mut by_source: HashMap<&str, Vec<usize>> = HashMap::new();
    for (span_idx, source_lang) in &misses {
        by_source
            .entry(source_lang.as_str())
            .or_default()
            .push(*span_idx);
    }

    for (source_lang, span_idxs) in &by_source {
        let texts: Vec<&str> = span_idxs.iter().map(|&i| spans[i].text.as_str()).collect();
        provider_calls += 1;
        match provider.translate_batch(&texts, source_lang, target_lang) {
            Ok(out) => {
                for (pos, &span_idx) in span_idxs.iter().enumerate() {
                    let rendition = out[pos].clone();
                    let entry = TranslationEntry {
                        source_hash: blake3::hash(spans[span_idx].text.as_bytes())
                            .to_hex()
                            .to_string(),
                        source_lang: source_lang.to_string(),
                        target_lang: target_lang.to_string(),
                        provider: provider.provider_name().to_string(),
                        model: provider.model_name().to_string(),
                        rendition_hash: blake3::hash(rendition.as_bytes()).to_hex().to_string(),
                        rendition,
                        created_at: now,
                    };
                    renditions[span_idx] = Some(entry.clone());
                    let key = cache_key(
                        &spans[span_idx].text,
                        source_lang,
                        target_lang,
                        provider.provider_name(),
                        provider.model_name(),
                    );
                    if let Some(s) = store {
                        s.put(&key, &entry);
                    }
                    cache_put_entry(key, entry);
                }
            }
            Err(e) => errors.push(format!("{source_lang} → {target_lang}: {e}")),
        }
    }

    let original_chars: Vec<char> = original_text.chars().collect();
    let mut text = String::with_capacity(original_text.len());
    let mut rendition_json = Vec::new();
    let mut translated = 0usize;
    let mut last_end = 0usize;
    for (span, entry) in spans.iter().zip(renditions.iter()) {
        let gap_end = span.char_start.min(original_chars.len());
        if last_end < gap_end {
            text.extend(&original_chars[last_end..gap_end]);
        }
        match entry {
            Some(e) => {
                translated += 1;
                text.push_str(&e.rendition);
                rendition_json.push(serde_json::json!({
                    "start": span.char_start,
                    "end": span.char_end,
                    "source_hash": e.source_hash,
                    "rendition_hash": e.rendition_hash,
                    "source_lang": e.source_lang,
                    "target_lang": e.target_lang,
                    "provider": e.provider,
                    "model": e.model,
                    "created_at": e.created_at,
                    "prov": {
                        "entity": e.rendition_hash,
                        "wasDerivedFrom": e.source_hash,
                        "wasGeneratedBy": "xudanu:Translation",
                        "quality_grade": "machine-gisting",
                    },
                }));
            }
            None => text.push_str(&span.text),
        }
        last_end = span.char_end.min(original_chars.len());
    }
    if last_end < original_chars.len() {
        text.extend(&original_chars[last_end..]);
    }

    let mut block = serde_json::json!({
        "target_lang": target_lang,
        "provider": provider.provider_name(),
        "model": provider.model_name(),
        "quality_grade": "machine-gisting",
        "spans_total": spans.len(),
        "spans_translated": translated,
        "spans_same_language": same_language,
        "spans_undeclared": undeclared,
        "cache_hits": cache_hits,
        "disk_hits": disk_hits,
        "renditions_durable": store.is_some(),
        "provider_calls": provider_calls,
        "renditions": rendition_json,
    });
    if !errors.is_empty() {
        block["errors"] = serde_json::json!(errors);
    }
    TranslatedRead {
        text,
        provider_calls,
        block,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::atomic::{AtomicUsize, Ordering};

    struct FakeProvider {
        calls: AtomicUsize,
        fail: bool,
    }

    impl RenditionProvider for FakeProvider {
        fn provider_name(&self) -> &str {
            "fake"
        }
        fn model_name(&self) -> &str {
            "fake/1"
        }
        fn translate_batch(
            &self,
            texts: &[&str],
            source_lang: &str,
            target_lang: &str,
        ) -> Result<Vec<String>, TranslateError> {
            self.calls.fetch_add(1, Ordering::SeqCst);
            if self.fail {
                return Err(TranslateError::Status(503));
            }
            Ok(texts
                .iter()
                .map(|t| format!("[{source_lang}->{target_lang}] {t}"))
                .collect())
        }
    }

    fn ann(kind: &str, lang: &str, s: usize, e: usize) -> (String, String, usize, usize) {
        (
            kind.to_string(),
            serde_json::json!({ "lang": lang }).to_string(),
            s,
            e,
        )
    }

    #[test]
    fn cache_key_is_deterministic_and_component_sensitive() {
        let a = cache_key("text", "de", "en", "argos", "m1");
        let b = cache_key("text", "de", "en", "argos", "m1");
        assert_eq!(a, b, "same tuple must yield the same key");
        assert_ne!(a, cache_key("text", "de", "fr", "argos", "m1"));
        assert_ne!(a, cache_key("Text", "de", "en", "argos", "m1"));
        assert_ne!(a, cache_key("text", "de", "en", "nllb", "m1"));
        assert_ne!(a, cache_key("text", "de", "en", "argos", "m2"));
        // Field boundaries must not smear: (ab, c) != (a, bc).
        assert_ne!(
            cache_key("ab", "c", "en", "p", "m"),
            cache_key("a", "bc", "en", "p", "m")
        );
    }

    #[test]
    fn language_tags_follow_bcp47_shape() {
        for good in ["en", "de", "la", "grc", "zh-Hant", "en-US", "sr-Latn"] {
            assert!(valid_language_tag(good), "{good} should be valid");
        }
        for bad in [
            "",
            "e",
            "englishlanguage",
            "1n",
            "en-",
            "-en",
            "en--us",
            "en-US-x-too-many-subtags-a",
        ] {
            assert!(!valid_language_tag(bad), "{bad} should be invalid");
        }
    }

    #[test]
    fn language_annotations_parse_doc_default_and_overrides() {
        let raw = vec![
            ann("language", "de", 0, 0),
            ann("language", "la", 10, 24),
            ann("bold", "true", 0, 5),
            ("language".into(), "not json".into(), 0, 0),
            ann("language", "toolongtag8x", 0, 0),
            ann("language", "fr", 30, 40),
        ];
        let (doc, overrides) = parse_language_annotations(&raw);
        assert_eq!(doc.as_deref(), Some("de"));
        assert_eq!(overrides.len(), 2);
        assert_eq!(overrides[0].lang, "la");
        assert_eq!(overrides[0].char_start, 10);
    }

    #[test]
    fn span_language_narrowest_override_wins() {
        let overrides = vec![
            LanguageOverride {
                lang: "de".into(),
                char_start: 0,
                char_end: 100,
            },
            LanguageOverride {
                lang: "la".into(),
                char_start: 40,
                char_end: 60,
            },
        ];
        assert_eq!(
            span_source_language(Some("en"), &overrides, 45, 55),
            Some("la".into()),
            "narrowest covering override wins"
        );
        assert_eq!(
            span_source_language(Some("en"), &overrides, 0, 30),
            Some("de".into())
        );
        assert_eq!(
            span_source_language(Some("en"), &overrides, 70, 120),
            Some("en".into()),
            "partial overlap is not coverage — the document default applies"
        );
        assert_eq!(
            span_source_language(None, &[], 0, 10),
            None,
            "undeclared is never guessed"
        );
    }

    #[test]
    fn translated_read_translates_misses_and_reuses_cache() {
        cache_clear_for_tests();
        let spans = vec![
            TextSpanView {
                char_start: 0,
                char_end: 5,
                text: "eins ".into(),
            },
            TextSpanView {
                char_start: 5,
                char_end: 10,
                text: "zwei ".into(),
            },
        ];
        let annotations = vec![ann("language", "de", 0, 0)];
        let provider = FakeProvider {
            calls: AtomicUsize::new(0),
            fail: false,
        };

        let original = "eins zwei ";
        let first = assemble_translated_read(original, &spans, &annotations, "en", &provider, None);
        assert_eq!(first.provider_calls, 1, "one batch, one call");
        assert_eq!(
            first.text, "[de->en] eins [de->en] zwei ",
            "both spans translated in order"
        );
        assert_eq!(first.block["spans_translated"], 2);
        assert_eq!(first.block["cache_hits"], 0);

        let second =
            assemble_translated_read(original, &spans, &annotations, "en", &provider, None);
        assert_eq!(second.provider_calls, 0, "second read is all cache hit");
        assert_eq!(second.block["cache_hits"], 2);
        assert_eq!(
            second.text, first.text,
            "same tuple yields byte-identical renditions"
        );
    }

    #[test]
    fn translated_read_preserves_layout_gaps() {
        cache_clear_for_tests();
        // Two line-spans separated by a blank line; the gap must
        // survive translation verbatim.
        let original = "Es irrt der Mensch.\n\nDurch die Gasse.";
        let spans = vec![
            TextSpanView {
                char_start: 0,
                char_end: 19,
                text: "Es irrt der Mensch.".into(),
            },
            TextSpanView {
                char_start: 21,
                char_end: 37,
                text: "Durch die Gasse.".into(),
            },
        ];
        let annotations = vec![ann("language", "de", 0, 0)];
        let provider = FakeProvider {
            calls: AtomicUsize::new(0),
            fail: false,
        };
        let out = assemble_translated_read(original, &spans, &annotations, "en", &provider, None);
        assert_eq!(
            out.text, "[de->en] Es irrt der Mensch.\n\n[de->en] Durch die Gasse.",
            "separators between spans pass through unchanged"
        );
    }

    #[test]
    fn translated_read_skips_same_language_and_undeclared() {
        cache_clear_for_tests();
        let spans = vec![
            TextSpanView {
                char_start: 0,
                char_end: 4,
                text: "eins".into(),
            },
            TextSpanView {
                char_start: 4,
                char_end: 8,
                text: "????".into(),
            },
        ];
        let annotations = vec![ann("language", "de", 0, 0), ann("language", "en", 4, 8)];
        let provider = FakeProvider {
            calls: AtomicUsize::new(0),
            fail: false,
        };
        let out = assemble_translated_read("eins????", &spans, &annotations, "en", &provider, None);
        assert_eq!(out.provider_calls, 1, "only the German span is fetched");
        assert_eq!(out.block["spans_same_language"], 1);
        assert_eq!(out.block["spans_undeclared"], 0);
        assert_eq!(out.text, "[de->en] eins????");
    }

    #[test]
    fn translated_read_degrades_to_original_on_provider_error() {
        cache_clear_for_tests();
        let spans = vec![TextSpanView {
            char_start: 0,
            char_end: 4,
            text: "eins".into(),
        }];
        let annotations = vec![ann("language", "de", 0, 0)];
        let provider = FakeProvider {
            calls: AtomicUsize::new(0),
            fail: true,
        };
        let out = assemble_translated_read("eins", &spans, &annotations, "en", &provider, None);
        assert_eq!(out.text, "eins", "read serves the original, never fails");
        assert!(out.block["errors"].is_array());
    }

    #[test]
    fn libretranslate_response_shapes_parse() {
        let array: LtTranslateResponse =
            serde_json::from_str(r#"{"translatedText":["a","b"]}"#).unwrap();
        assert_eq!(
            json_strings(array.translated_text).unwrap(),
            vec!["a".to_string(), "b".to_string()]
        );
        let single: LtTranslateResponse =
            serde_json::from_str(r#"{"translatedText":"a"}"#).unwrap();
        assert_eq!(
            json_strings(single.translated_text).unwrap(),
            vec!["a".to_string()]
        );
        let wrapped: LtTranslateResponse = serde_json::from_str(
            r#"{"translatedText":[{"translatedText":"a"},{"translatedText":"b"}]}"#,
        )
        .unwrap();
        assert_eq!(json_strings(wrapped.translated_text).unwrap().len(), 2);
    }

    fn temp_rendition_store(tag: &str) -> RenditionStore {
        let dir = std::env::temp_dir().join(format!("xudanu-rend-{}-{}", std::process::id(), tag));
        let _ = std::fs::remove_dir_all(&dir);
        RenditionStore::open(&dir).expect("temp rendition store")
    }

    #[test]
    fn renditions_survive_memory_wipe_via_disk_store() {
        cache_clear_for_tests();
        let store = temp_rendition_store("survive");
        // Unique texts: parallel tests share the global memory cache,
        // so these keys must not collide with any other test's.
        let spans = vec![
            TextSpanView {
                char_start: 0,
                char_end: 6,
                text: "drei ".into(),
            },
            TextSpanView {
                char_start: 6,
                char_end: 11,
                text: "vier ".into(),
            },
        ];
        let annotations = vec![ann("language", "de", 0, 0)];
        let provider = FakeProvider {
            calls: AtomicUsize::new(0),
            fail: false,
        };

        let first = assemble_translated_read(
            "drei vier ",
            &spans,
            &annotations,
            "en",
            &provider,
            Some(&store),
        );
        assert_eq!(first.provider_calls, 1);
        assert_eq!(first.block["cache_hits"], 0);
        assert_eq!(store.count(), 2, "fresh renditions persisted to disk");

        // A restart wipes memory, not disk.
        cache_clear_for_tests();
        let second = assemble_translated_read(
            "drei vier ",
            &spans,
            &annotations,
            "en",
            &provider,
            Some(&store),
        );
        assert_eq!(second.provider_calls, 0, "disk hits replace engine calls");
        assert_eq!(second.block["disk_hits"], 2);
        assert_eq!(
            second.text, first.text,
            "identical renditions after the simulated restart"
        );
    }

    #[test]
    fn corrupt_rendition_file_degrades_to_miss_and_self_heals() {
        cache_clear_for_tests();
        let store = temp_rendition_store("corrupt");
        let spans = vec![TextSpanView {
            char_start: 0,
            char_end: 7,
            text: "sieben".into(),
        }];
        let annotations = vec![ann("language", "de", 0, 0)];
        let provider = FakeProvider {
            calls: AtomicUsize::new(0),
            fail: false,
        };
        let first = assemble_translated_read(
            "sieben",
            &spans,
            &annotations,
            "en",
            &provider,
            Some(&store),
        );
        assert_eq!(first.provider_calls, 1);

        // Corrupt the persisted entry: the next read treats it as a
        // miss, retranslates, and overwrites the file.
        let key = cache_key("sieben", "de", "en", "fake", "fake/1");
        let path = store.entry_path(&key);
        std::fs::write(&path, b"{ not json").expect("corrupt write");
        cache_clear_for_tests();
        let second = assemble_translated_read(
            "sieben",
            &spans,
            &annotations,
            "en",
            &provider,
            Some(&store),
        );
        assert_eq!(second.provider_calls, 1, "corrupt entry retranslates");
        assert_eq!(second.text, first.text);
        assert!(
            store.get(&key).is_some(),
            "the corrupt file was overwritten with a good entry"
        );
    }

    #[test]
    fn tampered_rendition_text_fails_content_hash_and_self_heals() {
        cache_clear_for_tests();
        let store = temp_rendition_store("tamper");
        let spans = vec![TextSpanView {
            char_start: 0,
            char_end: 4,
            text: "neun".into(),
        }];
        let annotations = vec![ann("language", "de", 0, 0)];
        let provider = FakeProvider {
            calls: AtomicUsize::new(0),
            fail: false,
        };
        let first =
            assemble_translated_read("neun", &spans, &annotations, "en", &provider, Some(&store));
        assert_eq!(first.provider_calls, 1);

        // Rewrite the file with altered rendition text but the
        // original hash: parses fine, fails the content check.
        let key = cache_key("neun", "de", "en", "fake", "fake/1");
        let path = store.entry_path(&key);
        let mut value: serde_json::Value =
            serde_json::from_str(&std::fs::read_to_string(&path).unwrap()).unwrap();
        value["rendition"] = serde_json::json!("[tampered] neun");
        std::fs::write(&path, value.to_string()).expect("tampered rewrite");

        let tampered: TranslationEntry =
            serde_json::from_str(&std::fs::read_to_string(&path).unwrap()).unwrap();
        assert!(
            store.get(&key).is_none(),
            "well-formed but hash-mismatched entry must be refused"
        );
        assert_eq!(tampered.rendition, "[tampered] neun");

        // The read path self-heals: retranslate, overwrite, serve.
        cache_clear_for_tests();
        let second =
            assemble_translated_read("neun", &spans, &annotations, "en", &provider, Some(&store));
        assert_eq!(second.provider_calls, 1, "tampered entry retranslates");
        assert_eq!(second.text, first.text, "the tampered text never served");
        let healed = store.get(&key).expect("overwritten with a good entry");
        assert_eq!(healed.rendition, "[de->en] neun");
    }

    #[test]
    fn rendition_store_without_disk_hits_reports_memory_only() {
        cache_clear_for_tests();
        let spans = vec![TextSpanView {
            char_start: 0,
            char_end: 4,
            text: "acht".into(),
        }];
        let annotations = vec![ann("language", "de", 0, 0)];
        let provider = FakeProvider {
            calls: AtomicUsize::new(0),
            fail: false,
        };
        // No store: exactly Stage 2 behavior, durable flag false.
        let out = assemble_translated_read("acht", &spans, &annotations, "en", &provider, None);
        assert_eq!(out.provider_calls, 1);
        assert_eq!(out.block["disk_hits"], 0);
        assert_eq!(out.block["renditions_durable"], false);
    }
}
