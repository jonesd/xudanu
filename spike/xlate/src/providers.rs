//! Providers for the spike.
//!
//! `LibreTranslateProvider` speaks HTTP/1.1 to a local container via
//! `std::net::TcpStream` — deliberately no HTTP client dependency;
//! localhost, plaintext, one POST and one GET.
//!
//! Spike finding: **LibreTranslate's API cannot name its model.**
//! `/translate` takes `q/source/target` and returns text; nothing in
//! the API surface identifies which Argos model version ran. The
//! deployment must supply that identity (here: server version from
//! `/spec`, combined with the language pair; in production: a pinned
//! image digest). An edge that cannot name its model cannot promise
//! reproducibility — so the provider trait makes model identity a
//! first-class part of it.

use crate::{Lang, TranslateError, TranslationProvider};
use std::cell::RefCell;
use std::io::{Read, Write};
use std::net::TcpStream;

pub struct LibreTranslate {
    host: String,
    port: u16,
    server_version: RefCell<Option<String>>,
    calls: std::cell::Cell<usize>,
}

impl LibreTranslate {
    /// `base` like `http://127.0.0.1:5050` (default if env unset).
    pub fn from_env() -> Self {
        let base = std::env::var("XLATE_URL").unwrap_or_else(|_| "http://127.0.0.1:5050".into());
        let base = base.trim_start_matches("http://").to_string();
        let (host, port) = match base.split_once(':') {
            Some((h, p)) => (h.to_string(), p.parse().unwrap_or(5050)),
            None => (base, 5050),
        };
        LibreTranslate {
            host,
            port,
            server_version: RefCell::new(None),
            calls: std::cell::Cell::new(0),
        }
    }

    fn request(&self, method: &str, path: &str, body: Option<&str>) -> Result<String, TranslateError> {
        let mut stream = TcpStream::connect((self.host.as_str(), self.port))
            .map_err(|e| TranslateError::Unreachable(e.to_string()))?;
        stream
            .set_read_timeout(Some(std::time::Duration::from_secs(120)))
            .ok();
        let mut req = format!(
            "{method} {path} HTTP/1.1\r\nHost: {}:{}\r\nConnection: close\r\n",
            self.host, self.port
        );
        if let Some(b) = body {
            req.push_str("Content-Type: application/json\r\n");
            req.push_str(&format!("Content-Length: {}\r\n", b.len()));
        }
        req.push_str("\r\n");
        if let Some(b) = body {
            req.push_str(b);
        }
        stream
            .write_all(req.as_bytes())
            .map_err(|e| TranslateError::Unreachable(e.to_string()))?;
        let mut raw = Vec::new();
        stream
            .read_to_end(&mut raw)
            .map_err(|e| TranslateError::Unreachable(e.to_string()))?;
        let text = String::from_utf8_lossy(&raw).to_string();
        let (head, body) = text
            .split_once("\r\n\r\n")
            .ok_or_else(|| TranslateError::Provider("malformed response".into()))?;
        if !head.contains("200") {
            return Err(TranslateError::Provider(format!(
                "non-200: {}",
                head.lines().next().unwrap_or(head)
            )));
        }
        if head.to_ascii_lowercase().contains("chunked") {
            Ok(dechunk(body))
        } else {
            Ok(body.to_string())
        }
    }

    /// FastAPI exposes its version at `/spec` (openapi.info.version).
    fn server_version(&self) -> String {
        if let Some(v) = self.server_version.borrow().as_ref() {
            return v.clone();
        }
        let v = self
            .request("GET", "/spec", None)
            .ok()
            .and_then(|body| {
                serde_json::from_str::<serde_json::Value>(&body)
                    .ok()?
                    .pointer("/info/version")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string())
            })
            .unwrap_or_else(|| "unknown".to_string());
        *self.server_version.borrow_mut() = Some(v.clone());
        v
    }
}

impl TranslationProvider for LibreTranslate {
    fn id(&self) -> String {
        format!("libretranslate@{}", self.server_version())
    }

    fn model_version(&self, source: &Lang, target: &Lang) -> String {
        // The API cannot name the model; the best honest identity is
        // deployment + language pair. Production would pin an image
        // digest instead of `latest`.
        format!("argos:{}->{}", source, target)
    }

    fn translate(&self, text: &str, source: &Lang, target: &Lang) -> Result<String, TranslateError> {
        self.calls.set(self.calls.get() + 1);
        let body = serde_json::json!({
            "q": text,
            "source": source,
            "target": target,
            "format": "text",
        })
        .to_string();
        let resp = self.request("POST", "/translate", Some(&body))?;
        let v: serde_json::Value =
            serde_json::from_str(&resp).map_err(|e| TranslateError::Provider(e.to_string()))?;
        v.get("translatedText")
            .and_then(|t| t.as_str())
            .map(|s| s.to_string())
            .ok_or_else(|| TranslateError::Provider("no translatedText".into()))
    }

    fn calls(&self) -> usize {
        self.calls.get()
    }
}

/// Minimal chunked-transfer decode — enough for a localhost spike.
fn dechunk(body: &str) -> String {
    let mut out = String::new();
    let mut rest = body;
    loop {
        let Some((size_line, remainder)) = rest.split_once("\r\n") else {
            break;
        };
        let Ok(size) = usize::from_str_radix(size_line.trim(), 16) else {
            break;
        };
        if size == 0 {
            break;
        }
        let bytes = remainder.as_bytes();
        if bytes.len() < size {
            break;
        }
        out.push_str(&String::from_utf8_lossy(&bytes[..size]));
        rest = &remainder[size..];
        rest = rest.trim_start_matches("\r\n");
    }
    out
}
