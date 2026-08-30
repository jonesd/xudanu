// FR-50 Phase 1 v0: micro-harness — empirical complexity curves for
// core operations against an in-process server. Hand-rolled timing on
// purpose (criterion fights the server's checkpointing); see the FR
// for the plan and the expected-complexity table this measures against.
//
// FIXTURE SPEC (like-for-like contract — changes to any of these
// invalidate comparisons with earlier runs and must bump HARNESS_REV):
//   - Document: repeating ASCII sentence "alpha bravo charlie delta
//     echo foxtrot golf hotel " (48 chars, 8 words, no newlines),
//     truncated to exactly N chars.
//   - Single author (one public-login session), no links, no
//     transclusions, no annotations — mechanisms are added one at a
//     time in later phases so each curve measures one thing.
//   - Sizes N = 1k, 4k, 16k, 64k, 256k (4x steps).
//   - Edits: single-char insert then single-char delete at the exact
//     middle position, 20 alternating pairs, doc returned to original
//     after each pair.
//   - Attribution: plain query (no range), 10 reps, full span set.
//
// RESULTS LEDGER (FR-50/FR-51 registry): every `run` appends one
// JSONL record per scenario to docs/bench/results.jsonl (committed;
// `--ledger PATH` overrides, `--no-emit` skips). Record schema:
// ts/git/env(dev-mac|aws-official)/harness_rev/engine/variant/
// scenario/ref_n/points/steps/max_exp/us_at_ref/proj_1m.
//
// XPI (blended index, computed by `report`): per engine+variant,
// the geometric mean across scenarios of the PROJECTED 1M-CHAR COST
//   proj_1m = mean(ins_us, del_us)@ref_n * (1e6/ref_n)^max(0, max_exp)
// Flat curves project unchanged; non-flat ones extrapolate their
// measured exponent — the complexity penalty is explicit. Lower is
// better. Per-scenario numbers remain the regression surface; XPI
// is the headline, never a substitute.
//
// Governance: official comparisons come from env=aws-official
// records; dev-mac records are directional.

use std::time::Instant;
use xudanu::edition::Edition;
use xudanu::server::transport::protocol::TextDeltaOp;
use xudanu::server::{Server, SessionId};

const HARNESS_REV: &str = "2";
const SEED_SENTENCE: &str = "alpha bravo charlie delta echo foxtrot golf hotel ";
const SIZES: [usize; 5] = [1_000, 4_000, 16_000, 64_000, 256_000];
const EDIT_PAIRS: usize = 20;
const EDIT_MAX_N: usize = 256_000;
const LINKED_EDIT_MAX_N: usize = 16_000; // link migration still quadratic (finding 5)
const ATTR_REPS: usize = 10;

fn mean_us(samples: &[f64]) -> f64 {
    if samples.is_empty() {
        return 0.0;
    }
    samples.iter().sum::<f64>() / samples.len() as f64
}

fn exponent(n1: usize, t1: f64, n2: usize, t2: f64) -> f64 {
    if t1 <= 0.0 || t2 <= 0.0 {
        return 0.0;
    }
    (t2 / t1).ln() / (n2 as f64 / n1 as f64).ln()
}

struct Fixture {
    server: Server,
    sid: SessionId,
    work: u64,
    text: String,
}

fn build(n: usize) -> Fixture {
    let mut server = Server::new();
    let sid = server.connect();
    let _ = server.login_public(sid);
    let text: String = SEED_SENTENCE.repeat(n / SEED_SENTENCE.len() + 1);
    let text: String = text.chars().take(n).collect();
    let work = server
        .create_work(sid, Edition::from_text(&text))
        .expect("create work");
    let _ = server.crdt_open_session(sid, work);
    let _ = server.crdt_current_text(work);
    Fixture {
        server,
        sid,
        work,
        text,
    }
}

/// A6 fixture: chain of D nested structural transclusions over
/// sources of size C chars; measure resolve_inline_transclusions.
fn bench_nested_transclusion() {
    use xudanu::edition::range_element::RangeElement;
    let depths: [usize; 4] = [1, 4, 16, 32];
    let src_len = 2048usize;
    println!(
        "\nA6: nested transclusion resolution (sources {} chars)",
        src_len
    );
    println!("{:>8} {:>14} {:>12}", "depth", "resolve µs", "text len");
    let mut prev: Option<(usize, f64)> = None;
    for &d in &depths {
        let mut server = Server::new();
        let sid = server.connect();
        let _ = server.login_public(sid);
        // Source at the bottom of the chain.
        let text: String = SEED_SENTENCE.repeat(src_len / SEED_SENTENCE.len() + 1);
        let text: String = text.chars().take(src_len).collect();
        let bottom = server.create_work(sid, Edition::from_text(&text)).unwrap();
        // Chain upward: each level transcludes the level below, full span.
        let mut below = bottom;
        for _ in 1..d {
            let above_text = "wrapper ".repeat(4);
            let above = server
                .create_work(sid, Edition::from_text(&above_text))
                .unwrap();
            let elem = RangeElement::Transclusion {
                source_work_id: below,
                char_start: 0,
                char_end: src_len,
                placed_at: 0,
                placed_by: None,
                content_hash: None,
                source_revision: None,
            };
            server.element_insert(sid, above, 0, elem).unwrap();
            below = above;
        }
        let t0 = Instant::now();
        let result = server.resolve_inline_transclusions(below).unwrap();
        let us = t0.elapsed().as_secs_f64() * 1e6;
        let n = result.text.chars().count();
        let label = match prev {
            Some((pd, pt)) => format!(
                "   d-exp {:.2}",
                (us / pt).ln() / ((d as f64) / (pd as f64)).ln()
            ),
            None => "   (base)".to_string(),
        };
        println!(
            "{:>8} {:>14.1} {:>12}{}  (finding 9: nested levels collapse to raw slices)",
            d, us, n, label
        );
        prev = Some((d, us));
    }
}

/// FR-51 Phase 2 gate: keystroke curve on the lattice substrate.
/// Fixture contract (bump HARNESS_REV on change): same seed
/// sentence; the document is TYPED as sequential 48-char chunk
/// inserts (unit count scales with N — a one-block document would
/// hide the live-set scan); 20 alternating single-char insert/delete
/// pairs at the exact middle, doc restored after each pair.
pub struct LatticeRow {
    pub n: usize,
    pub ins_us: f64,
    pub del_us: f64,
    pub ins_exp: f64,
    pub del_exp: f64,
}

fn bench_lattice() -> Vec<LatticeRow> {
    use xudanu::space::lattice::LatticeDoc;
    use xudanu::space::lattice_sim::{apply_delta, LatOp};

    let mut rows: Vec<LatticeRow> = Vec::new();
    println!("\nFR-51: lattice keystroke curve (typed-chunk fixture)");
    println!(
        "{:>9} {:>12} {:>12}   exp ins/del",
        "N", "ins-mid µs", "del-mid µs"
    );
    let mut prev: Option<(usize, [f64; 2])> = None;
    for &n in SIZES.iter() {
        let mut doc = LatticeDoc::new(1);
        let chunks = n / SEED_SENTENCE.len();
        let tail: String = SEED_SENTENCE
            .chars()
            .take(n % SEED_SENTENCE.len())
            .collect();
        for c in 0..chunks {
            let ops = vec![
                LatOp::Retain {
                    count: (c * SEED_SENTENCE.len()) as u64,
                },
                LatOp::Insert {
                    text: SEED_SENTENCE.to_string(),
                },
            ];
            apply_delta(&mut doc, 1, &ops);
        }
        if !tail.is_empty() {
            let ops = vec![
                LatOp::Retain {
                    count: (chunks * SEED_SENTENCE.len()) as u64,
                },
                LatOp::Insert { text: tail },
            ];
            apply_delta(&mut doc, 1, &ops);
        }

        let mid = n / 2;
        let mut ins_samples = Vec::new();
        let mut del_samples = Vec::new();
        for _ in 0..EDIT_PAIRS {
            let ops = vec![
                LatOp::Retain { count: mid as u64 },
                LatOp::Insert {
                    text: "Z".to_string(),
                },
            ];
            let t = Instant::now();
            apply_delta(&mut doc, 1, &ops);
            ins_samples.push(t.elapsed().as_secs_f64() * 1e6);

            let ops = vec![
                LatOp::Retain { count: mid as u64 },
                LatOp::Delete { count: 1 },
            ];
            let t = Instant::now();
            apply_delta(&mut doc, 1, &ops);
            del_samples.push(t.elapsed().as_secs_f64() * 1e6);
        }

        let row = [mean_us(&ins_samples), mean_us(&del_samples)];
        let label = match prev {
            Some((pn, p)) => format!(
                "   {:.2}/{:.2}",
                exponent(pn, p[0], n, row[0]),
                exponent(pn, p[1], n, row[1])
            ),
            None => "   (base)".to_string(),
        };
        println!("{:>9} {:>12.1} {:>12.1}{}", n, row[0], row[1], label);
        rows.push(LatticeRow {
            n,
            ins_us: row[0],
            del_us: row[1],
            ins_exp: match prev {
                Some((pn, p)) => exponent(pn, p[0], n, row[0]),
                None => 0.0,
            },
            del_exp: match prev {
                Some((pn, p)) => exponent(pn, p[1], n, row[1]),
                None => 0.0,
            },
        });
        prev = Some((n, row));
    }
    rows
}

/// FR-51 P4 slice 2: the dual-engine capstone — ONE process, ONE
/// traffic stream, BOTH engines. A server is created with the
/// lattice shadow enabled and enrolled; scripted multi-session
/// traffic runs through crdt_apply_text_delta (O-tree timed around
/// the call, lattice timed inside the mirror hook). Per-op means
/// for both engines land in the ledger under scenario "dual-engine".
fn bench_dual_engine() -> Option<(f64, f64, bool, usize)> {
    use xudanu::server::transport::protocol::TextDeltaOp as Op;

    let base_len = SEED_SENTENCE.len();
    let chunks = 16_000usize / base_len; // 16k-char document
    let mut server = Server::new();
    let s1 = server.connect();
    let s2 = server.connect();
    let _ = server.login_public(s1);
    let _ = server.login_public(s2);
    let text: String = SEED_SENTENCE.repeat(chunks);
    let work = server
        .create_work(s1, Edition::from_text(&text))
        .expect("create work");
    server.crdt_open_session(s1, work).unwrap();
    server.crdt_open_session(s2, work).unwrap();

    server.enable_lattice_shadow();
    server.enroll_lattice_shadow(s1, work).expect("enroll");

    let n = text.chars().count();
    let mid = n / 2;
    let mut otree_ns: u128 = 0;
    // Interleaved two-session traffic: inserts at varied offsets and
    // range deletes, each delta positioned against its own session's
    // view (the server's session_bases model).
    let script: Vec<(xudanu::server::SessionId, Vec<Op>)> = {
        let mut v: Vec<(xudanu::server::SessionId, Vec<Op>)> = Vec::new();
        let d = |o: u64, ins: Option<&str>, del: u64| -> Vec<Op> {
            let mut ops = vec![Op::Retain { count: o }];
            if let Some(t) = ins {
                ops.push(Op::Insert {
                    text: t.to_string(),
                });
            }
            if del > 0 {
                ops.push(Op::Delete { count: del });
            }
            ops
        };
        // 120 alternating ops. Before the FR-50 finding-10 fix this
        // exploded (14.8s/op at op 52, doubling); span-provenance
        // coalescing keeps per-op cost flat — this script IS the
        // finding's regression guard.
        for k in 0..40u64 {
            let at = (mid as u64 + k * 37) % (n as u64 - 40);
            v.push((s1, d(at, Some("A"), 0)));
            v.push((s2, d(at.saturating_sub(20), None, 2)));
            v.push((s2, d((at + 5) % (n as u64 - 10), Some("B"), 0)));
        }
        v
    };
    let ops_count = script.len();
    let mut worst_us: f64 = 0.0;
    for (i, (sid, ops)) in script.iter().enumerate() {
        let t = Instant::now();
        server
            .crdt_apply_text_delta(*sid, work, ops)
            .expect("delta");
        let us = t.elapsed().as_nanos() as f64 / 1000.0;
        otree_ns += us as u128 * 1000;
        if us > worst_us {
            worst_us = us;
        }
        if i % 10 == 0 || us > 50_000.0 {
            eprintln!("dual-engine op {} of {}: {:.1}us", i + 1, ops_count, us);
        }
    }
    eprintln!(
        "dual-engine done: {} ops, worst op {:.1}us",
        ops_count, worst_us
    );
    // Semantic telemetry: the armor scripts (5-op interleaves, the
    // F6 probe) establish equivalence classes where lattice and
    // O-tree agree; this 30-op script crosses into unprobed
    // concurrent-merge classes (and F6 — O-tree merge garbling — is
    // OPEN). Report divergence, don't assert it.
    let shadow_text = server.lattice_shadow_text(work).unwrap();
    let live_text = server.crdt_current_text(work).unwrap();
    let matches = shadow_text == live_text;
    let first_diff = shadow_text
        .chars()
        .zip(live_text.chars())
        .position(|(a, b)| a != b)
        .unwrap_or(shadow_text.chars().count().min(live_text.chars().count()));
    println!(
        "  semantics: shadow==live {} (lens {}/{}, first diff at {})",
        matches,
        shadow_text.chars().count(),
        live_text.chars().count(),
        first_diff
    );
    if !matches {
        let ctx = |t: &str| -> String {
            let cs: Vec<char> = t.chars().collect();
            let s = first_diff.saturating_sub(20);
            let e = (first_diff + 20).min(cs.len());
            cs[s..e].iter().collect()
        };
        println!("  shadow@diff: {:?}", ctx(&shadow_text));
        println!("  live  @diff: {:?}", ctx(&live_text));
        if let Some(ed_text) = server.debug_crdt_edition_text(work) {
            println!(
                "  edition-direct: len {} (cached says {})",
                ed_text.chars().count(),
                live_text.chars().count()
            );
        }
    }

    let lattice_ns = server.lattice_shadow_nanos(work).unwrap();
    let otree_us = otree_ns as f64 / ops_count as f64 / 1000.0;
    let lattice_us = lattice_ns as f64 / ops_count as f64 / 1000.0;
    println!(
        "\nFR-51: dual-engine ({} interleaved ops, {} chars, shadow enrolled)",
        ops_count, n
    );
    println!(
        "  (O-tree worst op: {:.0}µs — flat since the FR-50 F10 span-coalescing fix)",
        worst_us
    );
    println!("{:>18} {:>14} {:>14}", "engine", "mean µs/op", "ratio");
    println!("{:>18} {:>14.2} {:>14}", "otree (live)", otree_us, "1.00x");
    println!(
        "{:>18} {:>14.2} {:>14.2}x",
        "lattice (shadow)",
        lattice_us,
        lattice_us / otree_us
    );
    let _ = server.lattice_shadow_ops(work).unwrap();
    Some((otree_us, lattice_us, matches, ops_count))
}

fn now_unix() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

fn git_desc() -> String {
    let out = std::process::Command::new("git")
        .args(["rev-parse", "--short", "HEAD"])
        .output();
    let sha = match out {
        Ok(o) if o.status.success() => String::from_utf8_lossy(&o.stdout).trim().to_string(),
        _ => "unknown".into(),
    };
    let dirty = std::process::Command::new("git")
        .args(["status", "--porcelain"])
        .output()
        .map(|o| o.status.success() && !o.stdout.is_empty())
        .unwrap_or(false);
    if dirty {
        format!("{}-dirty", sha)
    } else {
        sha
    }
}

fn default_ledger_path() -> String {
    // Workspace docs/ (three levels above the crate root).
    concat!(
        env!("CARGO_MANIFEST_DIR"),
        "/../../../docs/bench/results.jsonl"
    )
    .to_string()
}

/// Projected per-op cost at 1M chars: flat curves project unchanged,
/// non-flat ones extrapolate their measured exponent.
fn proj_1m(us_at_ref: f64, ref_n: usize, max_exp: f64) -> f64 {
    if us_at_ref <= 0.0 || ref_n == 0 {
        return 0.0;
    }
    let scale = (1_000_000.0f64 / ref_n as f64).powf(max_exp.max(0.0));
    us_at_ref * scale
}

fn geomean(xs: &[f64]) -> f64 {
    let pos: Vec<f64> = xs.iter().copied().filter(|v| *v > 0.0).collect();
    if pos.is_empty() {
        return 0.0;
    }
    (pos.iter().map(|v| v.ln()).sum::<f64>() / pos.len() as f64).exp()
}

fn emit_record(ledger: &str, record: serde_json::Value) {
    let path = std::path::Path::new(ledger);
    if let Some(dir) = path.parent() {
        let _ = std::fs::create_dir_all(dir);
    }
    match std::fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(path)
    {
        Ok(mut f) => {
            use std::io::Write;
            let _ = writeln!(f, "{}", record);
        }
        Err(e) => eprintln!("bench: ledger not writable ({}): {}", ledger, e),
    }
}

fn lattice_record(rows: &[LatticeRow]) -> serde_json::Value {
    let ref_row = rows.last();
    let max_exp = rows
        .iter()
        .map(|r| r.ins_exp.max(r.del_exp))
        .fold(0.0f64, f64::max);
    let (ref_n, ins, del) = match ref_row {
        Some(r) => (r.n, r.ins_us, r.del_us),
        None => (0, 0.0, 0.0),
    };
    let mean_ref = (ins + del) / 2.0;
    serde_json::json!({
        "ts": now_unix(),
        "source": "run",
        "env": std::env::var("XUDANU_BENCH_ENV").unwrap_or_else(|_| "dev-mac".into()),
        "host": std::env::var("XUDANU_BENCH_HOST").unwrap_or_else(|_| "dev".into()),
        "git": git_desc(),
        "xudanu": env!("CARGO_PKG_VERSION"),
        "harness_rev": HARNESS_REV,
        "engine": "lattice",
        "variant": "liveindex",
        "scenario": "keystroke-flat",
        "ref_n": ref_n,
        "points": rows.iter().map(|r| serde_json::json!({
            "n": r.n, "ins_us": r.ins_us, "del_us": r.del_us
        })).collect::<Vec<_>>(),
        "steps": rows.iter().filter(|r| r.ins_exp != 0.0 || r.del_exp != 0.0).map(|r| serde_json::json!({
            "to": r.n, "ins_exp": r.ins_exp, "del_exp": r.del_exp
        })).collect::<Vec<_>>(),
        "max_exp": max_exp,
        "us_at_ref": {"ins": ins, "del": del},
        "proj_1m": {"mean": proj_1m(mean_ref, ref_n, max_exp)},
    })
}

/// Human time formatting: µs / ms / s.
fn fmt_us(v: f64) -> String {
    if v <= 0.0 {
        return "-".into();
    }
    if v < 1000.0 {
        format!("{:.1}µs", v)
    } else if v < 1_000_000.0 {
        format!("{:.1}ms", v / 1000.0)
    } else {
        format!("{:.2}s", v / 1_000_000.0)
    }
}

/// Civil date from unix seconds (Howard Hinnant's civil_from_days).
fn fmt_date(ts: u64) -> String {
    let days = (ts / 86_400) as i64;
    let z = days + 719_468;
    let era = if z >= 0 { z } else { z - 146_096 } / 146_097;
    let doe = z - era * 146_097;
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365;
    let y = yoe + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = if m <= 2 { y + 1 } else { y };
    format!("{:04}-{:02}-{:02}", y, m, d)
}

fn run_report(ledger: &str) {
    let text = match std::fs::read_to_string(ledger) {
        Ok(t) => t,
        Err(e) => {
            eprintln!("bench: cannot read ledger {}: {}", ledger, e);
            return;
        }
    };
    let mut records: Vec<serde_json::Value> = text
        .lines()
        .filter(|l| !l.trim().is_empty())
        .filter_map(|l| serde_json::from_str(l).ok())
        .collect();
    records.sort_by_key(|r| r["ts"].as_u64().unwrap_or(0));
    println!(
        "xudanu-bench report — ledger {} ({} records)",
        ledger,
        records.len()
    );

    // Latest record per (engine, variant, scenario).
    let mut latest: Vec<(String, String, String, &serde_json::Value)> = Vec::new();
    for r in &records {
        let key = (
            r["engine"].as_str().unwrap_or("?").to_string(),
            r["variant"].as_str().unwrap_or("?").to_string(),
            r["scenario"].as_str().unwrap_or("?").to_string(),
        );
        match latest
            .iter_mut()
            .find(|(e, v, sc, _)| (&key.0, &key.1, &key.2) == (e, v, sc))
        {
            Some(slot) => slot.3 = r,
            None => latest.push((key.0, key.1, key.2, r)),
        }
    }

    println!("\nLATEST PER SCENARIO");
    for (e, v, sc, r) in &latest {
        let ts = r["ts"].as_u64().unwrap_or(0);
        let ref_n = r["ref_n"].as_u64().unwrap_or(0);
        let ins = r["us_at_ref"]["ins"].as_f64().unwrap_or(0.0);
        let del = r["us_at_ref"]["del"].as_f64().unwrap_or(0.0);
        let mx = r["max_exp"].as_f64().unwrap_or(0.0);
        println!(
            "  {:<18} {:<7} {:<13} ref={:<6} ins={:>10} del={:>10} max_exp={:.2}  ({} {})",
            sc,
            e,
            v,
            ref_n,
            fmt_us(ins),
            fmt_us(del),
            mx,
            fmt_date(ts),
            r["source"].as_str().unwrap_or("?"),
        );
    }

    println!("\nXPI (projected 1M-char cost, geomean across scenarios; lower is better)");
    let mut groups: Vec<(String, String, Vec<f64>)> = Vec::new();
    for (e, v, _, r) in &latest {
        let p = r["proj_1m"]["mean"].as_f64().unwrap_or(0.0);
        match groups.iter_mut().find(|(ge, gv, _)| ge == e && gv == v) {
            Some(g) => g.2.push(p),
            None => groups.push((e.clone(), v.clone(), vec![p])),
        }
    }
    groups.sort_by(|a, b| (&a.0, &a.1).cmp(&(&b.0, &b.1)));
    for (e, v, ps) in &groups {
        println!(
            "  {:<8} {:<13} XPI={:>10}  ({} scenarios)",
            e,
            v,
            fmt_us(geomean(ps)),
            ps.len()
        );
    }

    println!("\nTREND (chronological per engine/variant/scenario)");
    let mut seen: Vec<(String, String, String)> = Vec::new();
    for r in &records {
        let key = (
            r["engine"].as_str().unwrap_or("?").to_string(),
            r["variant"].as_str().unwrap_or("?").to_string(),
            r["scenario"].as_str().unwrap_or("?").to_string(),
        );
        if !seen.contains(&key) {
            seen.push(key.clone());
            let chain: Vec<String> = records
                .iter()
                .filter(|x| {
                    x["engine"].as_str() == Some(key.0.as_str())
                        && x["variant"].as_str() == Some(key.1.as_str())
                        && x["scenario"].as_str() == Some(key.2.as_str())
                })
                .map(|x| fmt_us(x["proj_1m"]["mean"].as_f64().unwrap_or(0.0)))
                .collect();
            println!(
                "  {:<8} {:<12} {:<16} {}",
                key.0,
                key.1,
                key.2,
                chain.join(" -> ")
            );
        }
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.iter().any(|a| a == "report") {
        let ledger = args
            .iter()
            .position(|a| a == "--ledger")
            .and_then(|i| args.get(i + 1))
            .cloned()
            .unwrap_or_else(default_ledger_path);
        run_report(&ledger);
        return;
    }
    let no_emit = args.iter().any(|a| a == "--no-emit");
    let ledger = args
        .iter()
        .position(|a| a == "--ledger")
        .and_then(|i| args.get(i + 1))
        .cloned()
        .unwrap_or_else(default_ledger_path);

    bench_nested_transclusion();
    let dual = bench_dual_engine();
    let lattice_rows = bench_lattice();
    println!(
        "xudanu-bench rev={} xudanu v{}",
        HARNESS_REV,
        env!("CARGO_PKG_VERSION")
    );
    println!(
        "fixture: seed={:?} single-author flat-ascii sizes={:?} edit-pairs={} attr-reps={}",
        SEED_SENTENCE, SIZES, EDIT_PAIRS, ATTR_REPS
    );
    println!(
        "{:>9} {:>12} {:>12} {:>12} {:>12}   exp build/ins/del/attr",
        "N", "build µs", "ins-mid µs", "del-mid µs", "attr-q µs"
    );

    let mut otree_rows: Vec<(usize, [f64; 4])> = Vec::new();
    let mut prev: Option<(usize, [f64; 4])> = None;
    for &n in SIZES.iter() {
        let t0 = Instant::now();
        let mut f = build(n);
        let build_us = t0.elapsed().as_secs_f64() * 1e6;

        // Links-at-scale variant (FR-50 extrapolation: the quadratic
        // class hides in dimensions the flat fixture never exercises).
        // 32 typed links spread across the document, spans around the
        // midpoints; measure the SAME single-char insert/delete.
        let linked = n <= LINKED_EDIT_MAX_N;
        let link_count = 32u64;
        for k in 0..if linked { link_count } else { 0 } {
            let a = ((n as u64) / link_count) * k + 8;
            let b = ((n as u64) / link_count) * (k + 1) - 8;
            let o = xudanu::edition::links::HyperRef::single(
                Some(xudanu::edition::Edition::from_text(
                    &f.text[a as usize..b as usize],
                )),
                Some(f.work),
                None,
                None,
            )
            .with_span(Some(a as i64), Some(b as i64));
            let d = xudanu::edition::links::HyperRef::single(
                Some(xudanu::edition::Edition::from_text(
                    &f.text[a as usize..b as usize],
                )),
                Some(f.work),
                None,
                None,
            )
            .with_span(Some(a as i64), Some(b as i64));
            let link = xudanu::edition::links::HyperLink::make(vec![(k % 5) + 1], o, d);
            let _ = f
                .server
                .create_link_with_hyperlink_homed(f.sid, link, Some(f.work));
        }
        let _ = f.server.list_links_for_work(f.work);

        let mid = n / 2;
        let mut ins_samples = Vec::new();
        let mut del_samples = Vec::new();
        for _ in 0..if n <= EDIT_MAX_N && linked {
            EDIT_PAIRS
        } else {
            0
        } {
            let ops = vec![
                TextDeltaOp::Retain { count: mid as u64 },
                TextDeltaOp::Insert {
                    text: "Z".to_string(),
                },
            ];
            let t = Instant::now();
            f.server
                .crdt_apply_text_delta(f.sid, f.work, &ops)
                .expect("insert");
            ins_samples.push(t.elapsed().as_secs_f64() * 1e6);

            let ops = vec![
                TextDeltaOp::Retain { count: mid as u64 },
                TextDeltaOp::Delete { count: 1 },
            ];
            let t = Instant::now();
            f.server
                .crdt_apply_text_delta(f.sid, f.work, &ops)
                .expect("delete");
            del_samples.push(t.elapsed().as_secs_f64() * 1e6);
        }

        let mut attr_samples = Vec::new();
        for _ in 0..ATTR_REPS {
            let t = Instant::now();
            let spans = f
                .server
                .attribution_query(f.work, None, None)
                .expect("attribution");
            attr_samples.push(t.elapsed().as_secs_f64() * 1e6);
            let _ = spans.len();
        }

        let row = [
            build_us,
            mean_us(&ins_samples),
            mean_us(&del_samples),
            mean_us(&attr_samples),
        ];
        let label = match prev {
            Some((pn, p)) => format!(
                "   {:.2}/{:.2}/{:.2}/{:.2}",
                exponent(pn, p[0], n, row[0]),
                exponent(pn, p[1], n, row[1]),
                exponent(pn, p[2], n, row[2]),
                exponent(pn, p[3], n, row[3])
            ),
            None => "   (base)".to_string(),
        };
        println!(
            "{:>9} {:>12.1} {:>12.1} {:>12.1} {:>12.1}{}",
            n, row[0], row[1], row[2], row[3], label
        );
        otree_rows.push((n, row));
        prev = Some((n, row));
    }

    if !no_emit {
        let rec = lattice_record(&lattice_rows);
        emit_record(&ledger, rec.clone());
        // O-tree records: rev-2 samples ins/del only up to
        // LINKED_EDIT_MAX_N — the keystroke record uses those sizes
        // only; attribution is its own scenario at full range.
        let ksampled: Vec<(usize, [f64; 4])> = otree_rows
            .iter()
            .copied()
            .filter(|(n, r)| *n <= LINKED_EDIT_MAX_N && r[1] > 0.0)
            .collect();
        let (kref, krow) = ksampled.last().copied().unwrap_or((0, [0.0; 4]));
        let ksteps: Vec<serde_json::Value> = ksampled
            .windows(2)
            .map(|w| {
                let (n1, r1) = w[0];
                let (n2, r2) = w[1];
                serde_json::json!({
                    "to": n2,
                    "ins_exp": exponent(n1, r1[1], n2, r2[1]),
                    "del_exp": exponent(n1, r1[2], n2, r2[2]),
                })
            })
            .collect();
        let kmax = ksteps
            .iter()
            .map(|st| {
                st["ins_exp"]
                    .as_f64()
                    .unwrap_or(0.0)
                    .max(st["del_exp"].as_f64().unwrap_or(0.0))
            })
            .fold(0.0f64, f64::max);
        let kmean = (krow[1] + krow[2]) / 2.0;
        let orec = serde_json::json!({
            "ts": now_unix(),
            "source": "run",
            "env": std::env::var("XUDANU_BENCH_ENV").unwrap_or_else(|_| "dev-mac".into()),
            "host": std::env::var("XUDANU_BENCH_HOST").unwrap_or_else(|_| "dev".into()),
            "git": git_desc(),
            "xudanu": env!("CARGO_PKG_VERSION"),
            "harness_rev": HARNESS_REV,
            "engine": "otree",
            "variant": "posmap",
            // Rev-2 samples edits only at n<=LINKED_EDIT_MAX_N with
            // 32 links present — this IS the linked scenario.
            "scenario": "keystroke-linked-32",
            "ref_n": kref,
            "points": ksampled.iter().map(|(n, r)| serde_json::json!({
                "n": n, "ins_us": r[1], "del_us": r[2]
            })).collect::<Vec<_>>(),
            "steps": ksteps,
            "max_exp": kmax,
            "us_at_ref": {"ins": krow[1], "del": krow[2]},
            "proj_1m": {"mean": proj_1m(kmean, kref, kmax)},
        });
        emit_record(&ledger, orec);

        let (aref, _arow_max, arow) = otree_rows
            .last()
            .map(|(n, r)| (*n, r[0], *r))
            .unwrap_or((0, 0.0, [0.0; 4]));
        let asteps: Vec<serde_json::Value> = otree_rows
            .windows(2)
            .map(|w| {
                let (n1, r1) = w[0];
                let (n2, r2) = w[1];
                serde_json::json!({
                    "to": n2,
                    "attr_exp": exponent(n1, r1[3], n2, r2[3]),
                })
            })
            .collect();
        let amax = asteps
            .iter()
            .filter_map(|st| st["attr_exp"].as_f64())
            .fold(0.0f64, f64::max);
        let arec = serde_json::json!({
            "ts": now_unix(),
            "source": "run",
            "env": std::env::var("XUDANU_BENCH_ENV").unwrap_or_else(|_| "dev-mac".into()),
            "host": std::env::var("XUDANU_BENCH_HOST").unwrap_or_else(|_| "dev".into()),
            "git": git_desc(),
            "xudanu": env!("CARGO_PKG_VERSION"),
            "harness_rev": HARNESS_REV,
            "engine": "otree",
            "variant": "cachefp",
            "scenario": "attr-q",
            "ref_n": aref,
            "points": otree_rows.iter().map(|(n, r)| serde_json::json!({
                "n": n, "attr_us": r[3]
            })).collect::<Vec<_>>(),
            "steps": asteps,
            "max_exp": amax,
            "us_at_ref": {"ins": arow[3], "del": 0.0, "attr": arow[3]},
            "proj_1m": {"mean": proj_1m(arow[3], aref, amax)},
        });
        emit_record(&ledger, arec);
        if let Some((otree_us, lattice_us, matches, ops)) = dual {
            let base = serde_json::json!({
                "ts": now_unix(),
                "source": "run",
                "env": std::env::var("XUDANU_BENCH_ENV").unwrap_or_else(|_| "dev-mac".into()),
                "host": std::env::var("XUDANU_BENCH_HOST").unwrap_or_else(|_| "dev".into()),
                "git": git_desc(),
                "xudanu": env!("CARGO_PKG_VERSION"),
                "harness_rev": HARNESS_REV,
                "ref_n": 16000,
                "points": [],
                "steps": [],
                "note": format!(
                    "{} interleaved 2-session ops; matches_live={}",
                    ops, matches
                ),
            });
            let mut o = base.clone();
            o["engine"] = "otree".into();
            o["variant"] = "threeway".into();
            o["scenario"] = "dual-engine-interleaved".into();
            o["max_exp"] = serde_json::json!(0.0);
            o["us_at_ref"] = serde_json::json!({"ins": otree_us, "del": 0.0});
            o["proj_1m"] = serde_json::json!({"mean": otree_us});
            emit_record(&ledger, o);
            let mut l = base;
            l["engine"] = "lattice".into();
            l["variant"] = "liveindex".into();
            l["scenario"] = "dual-engine-interleaved".into();
            l["max_exp"] = serde_json::json!(0.0);
            l["us_at_ref"] = serde_json::json!({"ins": lattice_us, "del": 0.0});
            l["proj_1m"] = serde_json::json!({"mean": lattice_us});
            emit_record(&ledger, l);
        }
        println!(
            "\nledger: 5 records appended to {} (git {})",
            ledger,
            git_desc()
        );
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn projection_flat_stays_put() {
        let p = proj_1m(2.0, 256_000, 0.1);
        assert!((p - 2.0 * (1_000_000.0f64 / 256_000.0).powf(0.1)).abs() < 1e-9);
        // Flat curves project (nearly) unchanged.
        assert!(proj_1m(2.0, 256_000, 0.0) - 2.0 < 1e-9);
    }

    #[test]
    fn projection_penalizes_exponents() {
        // exp 1.0 at 256k ref: x(1M/256k) = x3.90625
        let p = proj_1m(1000.0, 256_000, 1.0);
        assert!((p - 3906.25).abs() < 1e-6);
        // Negative exponents clamp to zero (no reward for noise).
        assert_eq!(proj_1m(5.0, 1000, -0.5), 5.0);
    }

    #[test]
    fn geomean_mixed() {
        assert!((geomean(&[1.0, 100.0]) - 10.0).abs() < 1e-9);
        assert_eq!(geomean(&[]), 0.0);
        assert_eq!(geomean(&[0.0, 4.0]), 4.0);
    }

    #[test]
    fn civil_dates() {
        // 2026-08-30 00:00:00 UTC = 1788048000
        assert_eq!(fmt_date(1788048000), "2026-08-30");
        assert_eq!(fmt_date(0), "1970-01-01");
    }

    #[test]
    fn human_units() {
        assert_eq!(fmt_us(12.5), "12.5µs");
        assert_eq!(fmt_us(2500.0), "2.5ms");
        assert_eq!(fmt_us(1_160_000.0), "1.16s");
        assert_eq!(fmt_us(0.0), "-");
    }
}
