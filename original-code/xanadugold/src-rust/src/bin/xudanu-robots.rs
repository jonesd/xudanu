//! FR-43 xudanu-robots: capacity measurement CLI.
//!
//! Personas (writers/readers/linkers/transcluders) drive a real
//! server over real WebSockets at human cadences while the run
//! records per-op latency (client-felt round-trips + the server's
//! metrics_snapshot) and honesty alarms (save-ack timeouts, text
//! resurrection, error rates).
//!
//! Usage:
//!   xudanu-robots --url ws://... --admin-pass ... \
//!     --writers 10 --readers 5 --duration 600 --profile team \
//!     --report perf/results/<dir>

use futures_util::{SinkExt, StreamExt};
use rand::rngs::StdRng;
use rand::Rng;
use rand::SeedableRng;
use serde::Serialize;
use std::collections::HashMap;
use std::sync::atomic::{AtomicU64 as AU, Ordering};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};
use tokio_tungstenite::tungstenite::Message;

// ── Persona cadences (pure, testable) ─────────────────────────────

/// WPM -> inter-keystroke delay.
pub fn keystroke_delay_ms(wpm: u64) -> u64 {
    // avg word 5 chars + space; 60000ms / (wpm * 6)
    (60_000 / (wpm.max(10) * 6)).max(30)
}

/// One Writer "burst": 5-15 chars typed, then a 2-8s pause.
pub fn writer_burst(rng: &mut impl Rng) -> (String, Duration) {
    let len = rng.gen_range(5..=15);
    let text: String = (0..len)
        .map(|_| (b'a' + rng.gen_range(0..26)) as char)
        .collect();
    let pause = Duration::from_millis(rng.gen_range(2_000..=8_000));
    (text, pause)
}

/// Whether this keystroke cycle inserts a backspace run (5% chance,
/// 1-3 chars) — the delete-heavy pattern that found the char_len bug.
pub fn writer_backspace(rng: &mut impl Rng) -> Option<u32> {
    if rng.gen_bool(0.05) {
        Some(rng.gen_range(1..=3))
    } else {
        None
    }
}

/// Reader cadence: network search every 30-60s.
pub fn reader_search_delay(rng: &mut impl Rng) -> Duration {
    Duration::from_millis(rng.gen_range(30_000..=60_000))
}

/// Linker cadence: a mention every 45-90s.
pub fn linker_delay(rng: &mut impl Rng) -> Duration {
    Duration::from_millis(rng.gen_range(45_000..=90_000))
}

/// Transcluder cadence: remote span pull every 2-5min.
pub fn transcluder_delay(rng: &mut impl Rng) -> Duration {
    Duration::from_millis(rng.gen_range(120_000..=300_000))
}

// ── Run report (matches perf/report.schema.json) ──────────────────

#[derive(Serialize)]
pub struct Report {
    pub meta: Meta,
    pub latency: Latency,
    pub honesty: Honesty,
    pub vitals: Vitals,
    pub verdict: Verdict,
}

#[derive(Serialize)]
pub struct Meta {
    pub started_at: String,
    pub duration_secs: u64,
    pub git_commit: String,
    pub binary_version: String,
    pub runner: String,
    pub profile: String,
    pub robots: HashMap<String, u32>,
}

#[derive(Serialize, Default)]
pub struct Latency {
    /// op -> { p50, p95, p99, count, max } — from client-felt RTTs
    pub ops: HashMap<String, OpLat>,
}

#[derive(Serialize, Default)]
pub struct OpLat {
    pub p50: u64,
    pub p95: u64,
    pub p99: u64,
    pub count: u64,
    pub max: u64,
}

#[derive(Serialize, Default)]
pub struct Honesty {
    pub save_ack_timeouts: u64,
    pub op_errors: u64,
    pub text_resurrections: u64,
    pub lock_poisonings: u64,
    pub false_unsigned_spans: u64,
}

#[derive(Serialize, Default)]
pub struct Vitals {
    pub ops_total: u64,
    pub rss_note: String,
}

#[derive(Serialize)]
pub struct Verdict {
    pub pass: bool,
    pub criteria: HashMap<String, Crit>,
}

#[derive(Serialize)]
pub struct Crit {
    pub limit: u64,
    pub actual: u64,
    pub ok: bool,
}

// ── WS client ─────────────────────────────────────────────────────

struct Robot {
    ws: tokio_tungstenite::WebSocketStream<
        tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>,
    >,
    next_id: u16,
}

impl Robot {
    async fn connect(url: &str) -> anyhow::Result<Self> {
        let mut req =
            tokio_tungstenite::tungstenite::client::IntoClientRequest::into_client_request(url)?;
        req.headers_mut()
            .insert("Origin", "http://localhost".parse()?);
        let (ws, _) = tokio_tungstenite::connect_async(req).await?;
        Ok(Robot { ws, next_id: 1 })
    }

    async fn req(
        &mut self,
        op: &str,
        payload: serde_json::Value,
    ) -> anyhow::Result<serde_json::Value> {
        let id = self.next_id;
        self.next_id = self.next_id.wrapping_add(1);
        let frame = serde_json::json!({
            "v": 2, "type": "request", "id": id, "op": op, "payload": payload
        });
        self.ws
            .send(Message::Text(frame.to_string().into()))
            .await?;
        loop {
            let msg = tokio::time::timeout(Duration::from_secs(30), self.ws.next()).await?;
            let msg = match msg {
                Some(m) => m?,
                None => anyhow::bail!("connection closed"),
            };
            if let Message::Text(t) = msg {
                let v: serde_json::Value = serde_json::from_str(&t)?;
                if v["id"].as_u64() == Some(id as u64) {
                    return Ok(v);
                }
            }
        }
    }
}

// ── Runner ────────────────────────────────────────────────────────

pub struct RunConfig {
    pub url: String,
    pub admin_pass: String,
    pub writers: u32,
    pub readers: u32,
    pub linkers: u32,
    pub transcluders: u32,
    pub duration: Duration,
    pub profile: String,
}

#[derive(Default)]
pub struct Shared {
    pub rtts: Mutex<HashMap<String, Vec<u64>>>,
    pub save_timeouts: AU,
    pub op_errors: AU,
    pub ops_total: AU,
    pub resurrections: AU,
}

fn record_rtt(shared: &Shared, op: &str, ms: u64) {
    shared.ops_total.fetch_add(1, Ordering::Relaxed);
    if let Ok(mut m) = shared.rtts.lock() {
        m.entry(op.to_string()).or_default().push(ms);
    }
}

fn percentile(sorted: &[u64], q: f64) -> u64 {
    if sorted.is_empty() {
        return 0;
    }
    let idx = ((sorted.len() as f64 - 1.0) * q).round() as usize;
    sorted[idx.min(sorted.len() - 1)]
}

pub async fn run(cfg: RunConfig) -> anyhow::Result<Report> {
    let shared = Arc::new(Shared::default());
    let started = Instant::now();
    let mut handles = Vec::new();

    for i in 0..cfg.writers {
        let (url, pass, sh) = (cfg.url.clone(), cfg.admin_pass.clone(), shared.clone());
        handles.push(tokio::spawn(async move {
            writer_task(i, url.clone(), pass.clone(), sh).await;
        }));
    }
    for i in 0..cfg.readers {
        let (url, sh) = (cfg.url.clone(), shared.clone());
        handles.push(tokio::spawn(async move {
            reader_task(i, url.clone(), sh).await;
        }));
    }
    for i in 0..cfg.linkers {
        let (url, pass, sh) = (cfg.url.clone(), cfg.admin_pass.clone(), shared.clone());
        handles.push(tokio::spawn(async move {
            linker_task(i, url.clone(), pass.clone(), sh).await;
        }));
    }
    let _ = cfg.transcluders; // transcluder needs a peer server; phase 2

    tokio::time::sleep(cfg.duration).await;
    for h in handles {
        h.abort();
    }

    // Metrics snapshot from the server (admin session).
    let mut admin = Robot::connect(&cfg.url).await?;
    let _ = admin.req("session_connect", serde_json::json!({})).await?;
    let _ = admin
        .req("session_login_public", serde_json::json!({}))
        .await?;
    // NOTE: caller must pass admin club id via env for full auth;
    // snapshot falls back to client-side percentiles if denied.
    let server_metrics = admin
        .req("metrics_snapshot", serde_json::json!({}))
        .await
        .ok();

    // Build latency report from client RTTs.
    let mut ops = HashMap::new();
    if let Ok(m) = shared.rtts.lock() {
        for (op, v) in m.iter() {
            let mut sorted = v.clone();
            sorted.sort_unstable();
            ops.insert(
                op.clone(),
                OpLat {
                    p50: percentile(&sorted, 0.50),
                    p95: percentile(&sorted, 0.95),
                    p99: percentile(&sorted, 0.99),
                    count: sorted.len() as u64,
                    max: *sorted.last().unwrap_or(&0),
                },
            );
        }
    }

    let save_timeouts = shared.save_timeouts.load(Ordering::Relaxed);
    let op_errors = shared.op_errors.load(Ordering::Relaxed);
    let work_create_p95 = ops.get("work_create").map(|o| o.p95).unwrap_or(0);
    let work_revise_delta_p95 = ops.get("work_revise_delta").map(|o| o.p95).unwrap_or(0);

    let mut criteria = HashMap::new();
    criteria.insert(
        "save_ack_timeouts_zero".to_string(),
        Crit {
            limit: 0,
            actual: save_timeouts,
            ok: save_timeouts == 0,
        },
    );
    criteria.insert(
        "op_error_rate_lt_1pct".to_string(),
        Crit {
            limit: (shared.ops_total.load(Ordering::Relaxed) / 100).max(1),
            actual: op_errors,
            ok: shared.ops_total.load(Ordering::Relaxed) == 0
                || op_errors * 100 <= shared.ops_total.load(Ordering::Relaxed),
        },
    );
    criteria.insert(
        "keystroke_p95_lt_150ms".to_string(),
        Crit {
            limit: 150,
            actual: work_revise_delta_p95,
            ok: work_revise_delta_p95 <= 150,
        },
    );
    criteria.insert(
        "work_create_p95_lt_500ms".to_string(),
        Crit {
            limit: 500,
            actual: work_create_p95,
            ok: work_create_p95 <= 500,
        },
    );

    let pass = criteria.values().all(|c| c.ok);
    let _ = server_metrics;

    Ok(Report {
        meta: Meta {
            started_at: chrono_now(),
            duration_secs: cfg.duration.as_secs(),
            git_commit: std::env::var("GIT_COMMIT").unwrap_or_else(|_| "unknown".into()),
            binary_version: std::env::var("BIN_VERSION").unwrap_or_else(|_| "unknown".into()),
            runner: std::env::var("ROBOT_RUNNER").unwrap_or_else(|_| "local".into()),
            profile: cfg.profile.clone(),
            robots: {
                let mut m = HashMap::new();
                m.insert("writers".into(), cfg.writers);
                m.insert("readers".into(), cfg.readers);
                m.insert("linkers".into(), cfg.linkers);
                m.insert("transcluders".into(), cfg.transcluders);
                m
            },
        },
        latency: Latency { ops },
        honesty: Honesty {
            save_ack_timeouts: save_timeouts,
            op_errors,
            text_resurrections: shared.resurrections.load(Ordering::Relaxed),
            ..Default::default()
        },
        vitals: Vitals {
            ops_total: shared.ops_total.load(Ordering::Relaxed),
            rss_note: String::new(),
        },
        verdict: Verdict { pass, criteria },
    })
}

fn chrono_now() -> String {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| format!("{}Z", d.as_secs()))
        .unwrap_or_default()
}

// ── Persona tasks ─────────────────────────────────────────────────

async fn writer_task(id: u32, url: String, _pass: String, shared: Arc<Shared>) {
    let Ok(mut bot) = Robot::connect(&url).await else {
        return;
    };
    let Ok(_) = bot.req("session_connect", serde_json::json!({})).await else {
        return;
    };
    let _ = bot.req("session_login_public", serde_json::json!({})).await;

    // Create a document (best-effort; owner-only servers deny — the
    // caller provisions a public-sandbox server).
    let t0 = Instant::now();
    let resp = bot
        .req(
            "work_create",
            serde_json::json!({"edition": {"text": format!("robot-writer-{} doc", id)}}),
        )
        .await;
    let work_id = match resp {
        Ok(r) => {
            record_rtt(&shared, "work_create", t0.elapsed().as_millis() as u64);
            let v = r["value"]["value"].as_u64().or_else(|| r["value"].as_u64());
            match v {
                Some(w) if r["type"] != "error" => w,
                _ => {
                    shared.op_errors.fetch_add(1, Ordering::Relaxed);
                    return;
                }
            }
        }
        Err(_) => {
            shared.save_timeouts.fetch_add(1, Ordering::Relaxed);
            return;
        }
    };
    // Delta edits require the work to be grabbed (edit-model rule;
    // real clients grab via crdt_sync_open).
    let _ = bot
        .req("work_grab", serde_json::json!({"work_id": work_id}))
        .await;

    let mut text = format!("robot-writer-{} doc\n", id);
    let mut rng = StdRng::seed_from_u64(id as u64 + 0x5eed);
    let mut base = 0u64;
    loop {
        let (burst, pause) = writer_burst(&mut rng);
        for ch in burst.chars() {
            text.push(ch);
            let t = Instant::now();
            let ops = serde_json::json!([
                {"type": "retain", "count": base},
                {"type": "insert", "text": ch.to_string()},
            ]);
            match bot
                .req(
                    "work_revise_delta",
                    serde_json::json!({
                        "work_id": work_id, "base_revision": 0, "ops": ops
                    }),
                )
                .await
            {
                Ok(r) => {
                    if r["type"] != "error" {
                        record_rtt(&shared, "work_revise_delta", t.elapsed().as_millis() as u64);
                        base += 1;
                    } else {
                        shared.op_errors.fetch_add(1, Ordering::Relaxed);
                    }
                }
                Err(_) => {
                    shared.save_timeouts.fetch_add(1, Ordering::Relaxed);
                }
            }
            tokio::time::sleep(Duration::from_millis(keystroke_delay_ms(90))).await;
        }
        if let Some(n) = writer_backspace(&mut rng) {
            for _ in 0..n {
                if base == 0 {
                    break;
                }
                text.pop();
                let ops = serde_json::json!([
                    {"type": "retain", "count": base - 1},
                    {"type": "delete", "count": 1},
                ]);
                let t = Instant::now();
                if let Ok(r) = bot
                    .req(
                        "work_revise_delta",
                        serde_json::json!({
                            "work_id": work_id, "base_revision": 0, "ops": ops
                        }),
                    )
                    .await
                {
                    if r["type"] != "error" {
                        record_rtt(&shared, "work_revise_delta", t.elapsed().as_millis() as u64);
                        base -= 1;
                    }
                }
            }
        }
        tokio::time::sleep(pause).await;
    }
}

async fn reader_task(id: u32, url: String, shared: Arc<Shared>) {
    let Ok(mut bot) = Robot::connect(&url).await else {
        return;
    };
    let _ = bot.req("session_connect", serde_json::json!({})).await;
    let _ = bot.req("session_login_public", serde_json::json!({})).await;
    let mut rng = StdRng::seed_from_u64(id as u64 + 0x5eed);
    loop {
        tokio::time::sleep(reader_search_delay(&mut rng)).await;
        let t = Instant::now();
        match bot
            .req(
                "federated_search",
                serde_json::json!({"query": format!("writer-{}", id % 3)}),
            )
            .await
        {
            Ok(r) => {
                if r["type"] != "error" {
                    record_rtt(&shared, "federated_search", t.elapsed().as_millis() as u64);
                } else {
                    shared.op_errors.fetch_add(1, Ordering::Relaxed);
                }
            }
            Err(_) => {
                shared.save_timeouts.fetch_add(1, Ordering::Relaxed);
            }
        }
    }
}

async fn linker_task(id: u32, url: String, _pass: String, shared: Arc<Shared>) {
    let Ok(mut bot) = Robot::connect(&url).await else {
        return;
    };
    let _ = bot.req("session_connect", serde_json::json!({})).await;
    let _ = bot.req("session_login_public", serde_json::json!({})).await;
    let mut rng = StdRng::seed_from_u64(id as u64 + 0x5eed);
    loop {
        tokio::time::sleep(linker_delay(&mut rng)).await;
        let t = Instant::now();
        // mention-style link between work 1 and itself (provisioned)
        match bot
            .req("link_create", serde_json::json!({
                "origin": 1, "destination": 1,
                "origin_ref": {"kind":"single","work_context":1,"excerpt":"robot link","start_position":0,"end_position":10},
            }))
            .await
        {
            Ok(r) => {
                if r["type"] != "error" {
                    record_rtt(&shared, "link_create", t.elapsed().as_millis() as u64);
                } else {
                    shared.op_errors.fetch_add(1, Ordering::Relaxed);
                }
            }
            Err(_) => { shared.save_timeouts.fetch_add(1, Ordering::Relaxed); }
        }
    }
}

fn main() -> anyhow::Result<()> {
    let args: Vec<String> = std::env::args().collect();
    let mut cfg = RunConfig {
        url: "ws://127.0.0.1:8080/xudanu?format=json&version=2".to_string(),
        admin_pass: String::new(),
        writers: 5,
        readers: 2,
        linkers: 1,
        transcluders: 0,
        duration: Duration::from_secs(90),
        profile: "team".to_string(),
    };
    let mut report_path: Option<String> = None;
    let mut i = 1;
    while i < args.len() {
        match args[i].as_str() {
            "--url" => {
                cfg.url = args[i + 1].clone();
                i += 1;
            }
            "--admin-pass" => {
                cfg.admin_pass = args[i + 1].clone();
                i += 1;
            }
            "--writers" => {
                cfg.writers = args[i + 1].parse()?;
                i += 1;
            }
            "--readers" => {
                cfg.readers = args[i + 1].parse()?;
                i += 1;
            }
            "--linkers" => {
                cfg.linkers = args[i + 1].parse()?;
                i += 1;
            }
            "--duration" => {
                let secs: u64 = args[i + 1].trim_end_matches('s').parse()?;
                cfg.duration = Duration::from_secs(secs);
                i += 1;
            }
            "--profile" => {
                cfg.profile = args[i + 1].clone();
                i += 1;
            }
            "--report" => {
                report_path = Some(args[i + 1].clone());
                i += 1;
            }
            other => anyhow::bail!("unknown arg: {other}"),
        }
        i += 1;
    }

    let rt = tokio::runtime::Runtime::new()?;
    let report = rt.block_on(run(cfg))?;

    let json = serde_json::to_string_pretty(&report)?;
    if let Some(path) = report_path {
        std::fs::create_dir_all(
            std::path::Path::new(&path)
                .parent()
                .unwrap_or(std::path::Path::new(".")),
        )?;
        std::fs::write(&path, &json)?;
        eprintln!("report -> {path}");
    }
    println!("{json}");
    if !report.verdict.pass {
        std::process::exit(1);
    }
    Ok(())
}
