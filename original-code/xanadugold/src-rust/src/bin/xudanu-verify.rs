//! FR-141 Phase 4: standalone docuverse verifier. Runs without a
//! server: chunk-store integrity, chained security + attribution
//! logs, key rotation chain, and (optionally, per work) provenance
//! signature and transclusion-hash checks.
//!
//! Usage: xudanu-verify <data-dir> [--work <id>...]
//!
//! Exit 0 when every check passes, 1 otherwise. Report is printed as
//! JSON on stdout; diagnostics go to stderr.

use std::path::Path;

fn main() {
    let mut data_dir: Option<String> = None;
    let mut works: Vec<u64> = Vec::new();
    let mut args = std::env::args().skip(1);
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--work" => match args.next().and_then(|w| w.parse::<u64>().ok()) {
                Some(w) => works.push(w),
                None => {
                    eprintln!("--work requires a numeric work id");
                    std::process::exit(2);
                }
            },
            other if data_dir.is_none() => data_dir = Some(other.to_string()),
            other => {
                eprintln!("unknown argument: {}", other);
                std::process::exit(2);
            }
        }
    }
    let data_dir = match data_dir {
        Some(dir) => dir,
        None => {
            eprintln!("usage: xudanu-verify <data-dir> [--work <id>...]");
            std::process::exit(2);
        }
    };
    let report = xudanu::server::mcp::verify_data_dir(Path::new(&data_dir), &works);
    let ok = report["ok"].as_bool().unwrap_or(false);
    println!(
        "{}",
        serde_json::to_string_pretty(&report).unwrap_or_else(|_| report.to_string())
    );
    std::process::exit(if ok { 0 } else { 1 });
}
