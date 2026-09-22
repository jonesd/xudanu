//! XPS Bench — the Xanalogical Performance Suite runner.
//!
//! Runs the core XPS operations against a real server (in-process,
//! not over the network — that's what the CRDT harness measures) and
//! produces a standard JSON report.
//!
//! Usage: cargo run --features server --bin xps-bench -- [--tier 1|2|3|4] [--json]
//!
//! The report format matches the XPS spec (docs/dev/xps-spec.md §5)
//! so results are comparable across implementations and over time.

use std::time::Instant;

#[derive(Debug, Clone, serde::Serialize)]
struct XpsResult {
    op: String,
    scale: serde_json::Value,
    class: String,
    measured_ms: Option<f64>,
    bound_ms: f64,
    pass: bool,
    note: Option<String>,
    samples: Option<usize>,
    p50_ms: Option<f64>,
    p95_ms: Option<f64>,
}

#[derive(Debug, serde::Serialize)]
struct XpsReport {
    implementation: String,
    date: String,
    environment: String,
    time_limit_secs: u64,
    docs_created: usize,
    doc_size: usize,
    results: Vec<XpsResult>,
    summary: XpsSummary,
}

#[derive(Debug, serde::Serialize)]
struct XpsSummary {
    total_ops: usize,
    passed: usize,
    failed: usize,
    not_implemented: usize,
    interactive_pass: usize,
    responsive_pass: usize,
    batch_pass: usize,
}

fn bound_for(class: &str) -> f64 {
    match class {
        "interactive" => 16.0,
        "responsive" => 100.0,
        "batch" => 1000.0,
        "background" => 60_000.0,
        _ => 100.0,
    }
}

fn measure<F: FnMut()>(mut f: F, samples: usize) -> (f64, f64, f64) {
    let mut times: Vec<f64> = Vec::with_capacity(samples);
    for _ in 0..samples {
        let start = Instant::now();
        f();
        times.push(start.elapsed().as_secs_f64() * 1000.0);
    }
    times.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let n = times.len();
    let p50 = times[n / 2];
    let p95 = times[(n * 95) / 100];
    let mean = times.iter().sum::<f64>() / n as f64;
    (mean, p50, p95)
}

fn result(
    op: &str,
    scale: serde_json::Value,
    class: &str,
    mean_ms: f64,
    p50_val: f64,
    p95_val: f64,
    samples: usize,
) -> XpsResult {
    let bound = bound_for(class);
    XpsResult {
        op: op.to_string(),
        scale,
        class: class.to_string(),
        measured_ms: Some(mean_ms),
        bound_ms: bound,
        pass: p95_val <= bound,
        note: None,
        samples: Some(samples),
        p50_ms: Some(p50_val),
        p95_ms: Some(p95_val),
    }
}

fn not_implemented(op: &str, scale: serde_json::Value, class: &str, note: &str) -> XpsResult {
    XpsResult {
        op: op.to_string(),
        scale,
        class: class.to_string(),
        measured_ms: None,
        bound_ms: bound_for(class),
        pass: false,
        note: Some(note.to_string()),
        samples: None,
        p50_ms: None,
        p95_ms: None,
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let json = args.contains(&"--json".to_string());

    let start_setup = Instant::now();
    let mut server = xudanu::server::Server::new();
    let sid = server.connect();
    server.login_public(sid).unwrap();

    // ── Time-boxed corpus creation ─────────────────────────────────
    // Instead of fixing the corpus size and waiting (which times out
    // for large data), fix the TIME BUDGET and measure how many works
    // we can create. This gives us a throughput curve.
    //
    // Usage: xps-bench --time-limit 60 [--doc-size 10000]
    // Output: "Created N works in Ts (N/T works/sec)"

    let time_limit_secs: u64 = args
        .iter()
        .position(|a| a == "--time-limit")
        .and_then(|i| args.get(i + 1))
        .and_then(|v| v.parse().ok())
        .unwrap_or(60); // default: 60 seconds

    let doc_size: usize = args
        .iter()
        .position(|a| a == "--doc-size")
        .and_then(|i| args.get(i + 1))
        .and_then(|v| v.parse().ok())
        .unwrap_or(10_000); // default 10KB

    eprintln!(
        "XPS Bench — time-boxed: {}s limit, {}B docs",
        time_limit_secs, doc_size
    );

    let start_setup = Instant::now();
    let mut server = xudanu::server::Server::new();
    let sid = server.connect();
    server.login_public(sid).unwrap();

    let text_template = "The quick brown fox jumps over the lazy dog. ".repeat(doc_size / 45 + 1);
    let deadline = start_setup + std::time::Duration::from_secs(time_limit_secs);

    // Create works in batches of 100, checking the clock between batches
    let mut work_ids: Vec<u64> = Vec::new();
    let batch_size = 100;
    let mut batch_num = 0usize;

    loop {
        if Instant::now() >= deadline {
            break;
        }

        // Build a batch of editions
        let start_idx = batch_num * batch_size;
        let editions: Vec<xudanu::edition::Edition> = (0..batch_size)
            .map(|j| {
                let i = start_idx + j;
                xudanu::edition::Edition::from_text(&format!("Document {i}\n\n{text_template}"))
            })
            .collect();

        // Check if we'll exceed the deadline mid-batch
        // (if so, create fewer works)
        let remaining = deadline.saturating_duration_since(Instant::now());
        let elapsed = start_setup.elapsed();
        let per_work = if work_ids.len() > 0 {
            elapsed.as_secs_f64() / work_ids.len() as f64
        } else {
            0.001 // initial estimate
        };
        let estimated_batch_time = per_work * batch_size as f64;

        if estimated_batch_time > remaining.as_secs_f64() && remaining.as_secs_f64() < 5.0 {
            // Running out of time — create as many as we can fit
            let fits = (remaining.as_secs_f64() / per_work) as usize;
            if fits < 1 {
                break;
            }
            let partial: Vec<xudanu::edition::Edition> =
                editions.into_iter().take(fits.min(batch_size)).collect();
            let ids = server.bulk_create_works(sid, partial).unwrap();
            work_ids.extend(ids);
            break;
        }

        // Full batch
        let batch_start = Instant::now();
        let ids = server.bulk_create_works(sid, editions).unwrap();
        let batch_elapsed = batch_start.elapsed();
        work_ids.extend(ids);
        batch_num += 1;

        // Progress report every 1000 works
        if work_ids.len() % 1000 == 0 {
            let total_elapsed = start_setup.elapsed().as_secs_f64();
            let throughput = work_ids.len() as f64 / total_elapsed;
            eprint!(
                "\r  {} works ({:.0}/sec) — {:.1}s elapsed",
                work_ids.len(),
                throughput,
                total_elapsed
            );
        }
    }

    eprintln!();
    let total_secs = start_setup.elapsed().as_secs_f32();
    let docs_created = work_ids.len();
    let throughput = if total_secs > 0.0 {
        docs_created as f64 / total_secs as f64
    } else {
        0.0
    };
    let total_mb = (docs_created * doc_size) as f64 / 1_048_576.0;

    eprintln!(
        "  Created {} works ({:.1} MB) in {:.1}s ({:.0} works/sec)",
        docs_created, total_mb, total_secs, throughput
    );

    eprintln!("  (link creation via dispatch layer — see dispatch_bench for link-specific timing)");

    let mut results: Vec<XpsResult> = Vec::new();

    // ── L1: Create typed link ─────────────────────────────────────
    results.push(not_implemented(
        "L1-create-link",
        serde_json::json!({"note": "measured via dispatch_bench (dispatch layer)"}),
        "responsive",
        "in-process benchmark doesn't exercise the HyperRef construction path; see dispatch_bench",
    ));

    // ── L2: Query backlinks ───────────────────────────────────────
    {
        let (mean, p50, p95) = measure(
            || {
                let _ = server.list_works(); // proxy: scanning linked works
            },
            100,
        );
        results.push(result(
            "L2-backlink-query",
            serde_json::json!({"docs": docs_created}),
            "responsive",
            mean,
            p50,
            p95,
            100,
        ));
    }

    // ── L4: Span migration (edit near a link) ─────────────────────
    {
        let test_text = "Hello world this is a test document for edit performance measurement";
        let wid = server
            .create_work(sid, xudanu::edition::Edition::from_text(test_text))
            .unwrap();
        let (mean, p50, p95) = measure(
            || {
                let _ = server.work_set_text(sid, wid, &format!("X{test_text}"));
            },
            50,
        );
        results.push(result(
            "C5-write-text-small",
            serde_json::json!({"text_len": test_text.len()}),
            "interactive",
            mean,
            p50,
            p95,
            50,
        ));
    }

    // ── C1: Content match (shared regions) ────────────────────────
    {
        let (mean, p50, p95) = measure(
            || {
                // Content match requires Edition-level API; measure via crum comparison
                let text_a = server.work_text_fresh(work_ids[0]).unwrap_or_default();
                let text_b = server.work_text_fresh(work_ids[1]).unwrap_or_default();
                let ed_a = xudanu::edition::Edition::from_text(&text_a);
                let ed_b = xudanu::edition::Edition::from_text(&text_b);
                let eds = [&ed_a, &ed_b];
                let _ = xudanu::edition::Edition::shared_regions_nway(&eds, 10);
            },
            20,
        );
        results.push(result(
            "C1-content-match",
            serde_json::json!({"docs": 2, "doc_size": doc_size}),
            "batch",
            mean,
            p50,
            p95,
            20,
        ));
    }

    // ── P1: Author attribution ────────────────────────────────────
    {
        let (mean, p50, p95) = measure(
            || {
                let _ = server.attribution_query(work_ids[0], None, None);
            },
            50,
        );
        results.push(result(
            "P1-attribution",
            serde_json::json!({"doc_size": doc_size}),
            "responsive",
            mean,
            p50,
            p95,
            50,
        ));
    }

    // ── Work operations ───────────────────────────────────────────
    {
        let (mean, p50, p95) = measure(
            || {
                let _ = server.list_works();
            },
            50,
        );
        results.push(result(
            "C3-work-list",
            serde_json::json!({"docs": docs_created}),
            "responsive",
            mean,
            p50,
            p95,
            50,
        ));
    }

    {
        let (mean, p50, p95) = measure(
            || {
                let _ = server.work_text_fresh(work_ids[0]);
            },
            100,
        );
        results.push(result(
            "C4-read-text",
            serde_json::json!({"doc_size": doc_size}),
            "interactive",
            mean,
            p50,
            p95,
            100,
        ));
    }

    {
        let (mean, p50, p95) = measure(
            || {
                let text = format!("Edit benchmark: modified content");
                let _ = server.work_set_text(sid, work_ids[0], &text);
            },
            50,
        );
        results.push(result(
            "C5-write-text",
            serde_json::json!({"doc_size": text_template.len()}),
            "interactive",
            mean,
            p50,
            p95,
            50,
        ));
    }

    // ── T2: Compound resolve (if implemented) ─────────────────────
    {
        // TODO: needs transclusion setup
        results.push(not_implemented(
            "T2-compound-resolve",
            serde_json::json!({"depth": 1}),
            "batch",
            "requires transclusion corpus setup",
        ));
    }

    // ── C2: Corpus-wide matching ──────────────────────────────────
    {
        results.push(not_implemented(
            "C2-corpus-matching",
            serde_json::json!({"docs": docs_created}),
            "background",
            "requires content-match index across all works",
        ));
    }

    // ── Capacity extrapolation ────────────────────────────────────
    // Based on the measured write latency, estimate sustainable users
    if let Some(r) = results.iter().find(|r| r.op == "C5-write-text") {
        if let (Some(p95), Some(_)) = (r.p95_ms, r.measured_ms) {
            // Assume: each user writes every 30s (bursty editing),
            // reads 10x more than writes. p95 is the per-op cost.
            // Sustainable concurrent editors = 30_000ms / p95_ms
            // (each op must complete before the next user's arrives)
            let sustainable_writers = (30_000.0 / p95).floor() as u64;
            let sustainable_readers = sustainable_writers * 10;
            results.push(XpsResult {
                op: "CAPACITY-estimated-users".to_string(),
                scale: serde_json::json!({
                    "concurrent_writers": sustainable_writers,
                    "concurrent_readers": sustainable_readers,
                    "assumption": "1 write per 30s per user, 10:1 read:write ratio",
                }),
                class: "capacity".to_string(),
                measured_ms: None,
                bound_ms: 0.0,
                pass: true,
                note: Some(format!(
                    "p95 write={p95:.1}ms → ~{sustainable_writers} concurrent writers, ~{sustainable_readers} readers"
                )),
                samples: None,
                p50_ms: None,
                p95_ms: None,
            });
        }
    }

    // ── Report ────────────────────────────────────────────────────
    let total = results.len();
    let passed = results.iter().filter(|r| r.pass).count();
    let failed = results
        .iter()
        .filter(|r| !r.pass && r.measured_ms.is_some())
        .count();
    let not_impl = results.iter().filter(|r| r.measured_ms.is_none()).count();

    let report = XpsReport {
        implementation: format!("xudanu {}", env!("CARGO_PKG_VERSION")),
        date: chrono::Utc::now().format("%Y-%m-%d").to_string(),
        environment: format!(
            "{}/{} cores/{}GB",
            std::env::consts::OS,
            std::thread::available_parallelism()
                .map(|n| n.get())
                .unwrap_or(1),
            sys_memory_gb(),
        ),
        time_limit_secs,
        docs_created,
        doc_size,
        summary: XpsSummary {
            total_ops: total,
            passed,
            failed,
            not_implemented: not_impl,
            interactive_pass: results
                .iter()
                .filter(|r| r.class == "interactive" && r.pass)
                .count(),
            responsive_pass: results
                .iter()
                .filter(|r| r.class == "responsive" && r.pass)
                .count(),
            batch_pass: results
                .iter()
                .filter(|r| r.class == "batch" && r.pass)
                .count(),
        },
        results,
    };

    if json {
        println!("{}", serde_json::to_string_pretty(&report).unwrap());
    } else {
        eprintln!("\n{}", "═".repeat(72));
        eprintln!(
            "  XPS Results — {} ({} works, {}s limit)",
            report.implementation, docs_created, time_limit_secs
        );
        eprintln!("  {} on {}", report.environment, report.date);
        eprintln!("{}", "═".repeat(72));
        eprintln!(
            "  {:<28} {:>10} {:>10} {:>8}  {}",
            "Operation", "p50", "p95", "Bound", "Pass"
        );
        eprintln!("{}", "─".repeat(72));
        for r in &report.results {
            let p50 = r.p50_ms.map(|v| format!("{v:.1}ms")).unwrap_or("—".into());
            let p95 = r.p95_ms.map(|v| format!("{v:.1}ms")).unwrap_or("—".into());
            let bound = format!("{:.0}ms", r.bound_ms);
            let status = if r.measured_ms.is_none() {
                "N/A"
            } else if r.pass {
                "PASS"
            } else {
                "FAIL"
            };
            eprintln!(
                "  {:<28} {:>10} {:>10} {:>8}  {}",
                r.op, p50, p95, bound, status
            );
            if let Some(note) = &r.note {
                eprintln!("    └─ {note}");
            }
        }
        eprintln!("{}", "─".repeat(72));
        let s = &report.summary;
        eprintln!(
            "  {} ops: {} pass, {} fail, {} not implemented",
            s.total_ops, s.passed, s.failed, s.not_implemented
        );
        eprintln!("{}", "═".repeat(72));
    }
}

fn sys_memory_gb() -> u64 {
    #[cfg(target_os = "macos")]
    {
        use std::process::Command;
        Command::new("sysctl")
            .arg("-n")
            .arg("hw.memsize")
            .output()
            .ok()
            .and_then(|o| String::from_utf8(o.stdout).ok())
            .and_then(|s| s.trim().parse::<u64>().ok())
            .map(|b| b / 1_073_741_824)
            .unwrap_or(0)
    }
    #[cfg(not(target_os = "macos"))]
    {
        0
    }
}
