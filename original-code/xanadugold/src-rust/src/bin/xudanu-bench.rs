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

use std::time::Instant;
use xudanu::edition::Edition;
use xudanu::server::transport::protocol::TextDeltaOp;
use xudanu::server::{Server, SessionId};

const HARNESS_REV: &str = "0";
const SEED_SENTENCE: &str = "alpha bravo charlie delta echo foxtrot golf hotel ";
const SIZES: [usize; 5] = [1_000, 4_000, 16_000, 64_000, 256_000];
const EDIT_PAIRS: usize = 20;
const EDIT_MAX_N: usize = 16_000; // ins/del measured quadratic; larger sizes never finish
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
    Fixture { server, sid, work }
}

fn main() {
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

    let mut prev: Option<(usize, [f64; 4])> = None;
    for &n in SIZES.iter() {
        let t0 = Instant::now();
        let mut f = build(n);
        let build_us = t0.elapsed().as_secs_f64() * 1e6;

        let mid = n / 2;
        let mut ins_samples = Vec::new();
        let mut del_samples = Vec::new();
        for _ in 0..if n <= EDIT_MAX_N { EDIT_PAIRS } else { 0 } {
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
        prev = Some((n, row));
    }
}
