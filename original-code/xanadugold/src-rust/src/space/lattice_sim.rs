//! FR-51 Phase 1: the lattice simulator — the editor adapter and the
//! acceptance harness.
//!
//! The adapter translates positional text deltas (retain/insert/
//! delete over char offsets) into substrate operations: inserts land
//! on unit boundaries (`split_at` splits a straddling unit — units
//! are immutable, so a split is tombstone + re-insert of the parts);
//! deletes split their boundaries then tombstone the enclosed range.
//! Two replicas apply their session's ops to independent docs; merge
//! is delivery-order independent, so shuffling cannot change the
//! render. Op streams serialize to JSONL for replay and comparison
//! against the O-tree oracle.

use super::lattice::LatticeDoc;
use super::lattice_multi::split_at;
pub use super::lattice_multi::LatOp;

#[derive(Debug, Clone)]
pub struct OpEvent {
    pub session: u64,
    pub ops: Vec<LatOp>,
}

impl OpEvent {
    pub fn to_jsonl(&self) -> String {
        let mut s = String::from("{\"session\":");
        s.push_str(&self.session.to_string());
        s.push_str(",\"ops\":[");
        for (i, op) in self.ops.iter().enumerate() {
            if i > 0 {
                s.push(',');
            }
            match op {
                LatOp::Retain { count } => {
                    s.push_str(&format!("{{\"retain\":{}}}", count));
                }
                LatOp::Insert { text } => {
                    s.push_str(&format!("{{\"insert\":{}}}", json_escape(text)));
                }
                LatOp::Delete { count } => {
                    s.push_str(&format!("{{\"delete\":{}}}", count));
                }
            }
        }
        s.push_str("]}\n");
        s
    }
}

fn json_escape(s: &str) -> String {
    let mut out = String::from("\"");
    for c in s.chars() {
        match c {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\t' => out.push_str("\\t"),
            c if (c as u32) < 0x20 => out.push_str(&format!("\\u{:04x}", c as u32)),
            c => out.push(c),
        }
    }
    out.push('"');
    out
}

/// Apply a positional delta to a lattice doc on behalf of one author.
pub fn apply_delta(doc: &mut LatticeDoc, author: u64, ops: &[LatOp]) {
    let mut offset: u64 = 0;
    for op in ops {
        match op {
            LatOp::Retain { count } => offset += count,
            LatOp::Insert { text } => {
                let b = split_at(doc, offset);
                let (prev, next) = b.prev_next();
                doc.insert_at(prev, next, text.clone(), author, b.anchor);
                offset += text.chars().count() as u64;
            }
            LatOp::Delete { count } => {
                // The deleted chars [o, o+n) map to the region bounded
                // by the addresses of the first unit INSIDE the range
                // and the first unit AFTER it — split_at's NEXT on
                // both ends (prev/next mixing was the bug: the region
                // must never contain the unit before the boundary).
                // End boundary FIRST: splitting it re-allocates the
                // tail unit's address, and the start bound must
                // reference the post-split live unit.
                let end = split_at(doc, offset + count);
                let start = split_at(doc, offset);
                match (start.next.clone(), end.next.clone()) {
                    (Some(a), Some(b)) => doc.delete_range_public(&a, &b),
                    (Some(a), None) => doc.delete_to_end(&a),
                    _ => {}
                }
            }
        }
    }
}

/// Ensure a unit boundary exists at `offset` in the live view,
/// splitting the straddling unit if any. Returns the addresses of
/// the units immediately before and after the boundary (None at the
/// document edges) and the boundary's ROOT ANCHOR (root dot, root
/// offset) when it falls within a root unit's extent — fresh inserts
/// use it for position-derived addressing (P1-2).
/// Run two sessions' streams on two independent replicas, then merge
/// both delivery orders and render — the acceptance primitive.
pub fn run_two_replica(
    server_a: u64,
    stream_a: &[LatOp],
    server_b: u64,
    stream_b: &[LatOp],
) -> (String, String) {
    let mut doc_a = LatticeDoc::new(server_a);
    apply_delta(&mut doc_a, server_a, stream_a);
    let mut doc_b = LatticeDoc::new(server_b);
    apply_delta(&mut doc_b, server_b, stream_b);

    let mut ab = doc_a.clone();
    ab.merge(&doc_b);
    let mut ba = doc_b.clone();
    ba.merge(&doc_a);
    (ab.render(), ba.render())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::space::lattice_multi::MultiWriter;
    use crate::space::sequence::Sequence;

    fn ops(list: &[LatOp]) -> Vec<LatOp> {
        list.to_vec()
    }

    #[test]
    fn sim_single_writer_matches_expected_text() {
        let mut doc = LatticeDoc::new(1);
        apply_delta(
            &mut doc,
            1,
            &ops(&[LatOp::Insert {
                text: "hello world".into(),
            }]),
        );
        apply_delta(
            &mut doc,
            1,
            &ops(&[
                LatOp::Retain { count: 5 },
                LatOp::Insert {
                    text: " glorious".into(),
                },
                LatOp::Retain { count: 6 },
            ]),
        );
        apply_delta(
            &mut doc,
            1,
            &ops(&[
                LatOp::Retain { count: 14 },
                LatOp::Delete { count: 5 },
                LatOp::Retain { count: 1 },
            ]),
        );
        assert_eq!(doc.render(), "hello gloriousd"); // delete " worl" of " world"
    }

    #[test]
    fn sim_split_and_partial_delete() {
        let mut doc = LatticeDoc::new(1);
        apply_delta(
            &mut doc,
            1,
            &ops(&[LatOp::Insert {
                text: "abcdef".into(),
            }]),
        );
        // Delete chars 2..5 ("cde") — a partial-unit delete.
        apply_delta(
            &mut doc,
            1,
            &ops(&[
                LatOp::Retain { count: 2 },
                LatOp::Delete { count: 3 },
                LatOp::Retain { count: 1 },
            ]),
        );
        assert_eq!(doc.render(), "abf");
        // Insert mid-unit: split + place.
        apply_delta(
            &mut doc,
            1,
            &ops(&[
                LatOp::Retain { count: 1 },
                LatOp::Insert { text: "XY".into() },
                LatOp::Retain { count: 2 },
            ]),
        );
        assert_eq!(doc.render(), "aXYbf");
    }

    #[test]
    fn sim_two_replica_shuffled_delivery_agrees() {
        let stream_a = ops(&[LatOp::Insert {
            text: "base ".into(),
        }]);
        // Both start from "base " (pre-shared), then diverge:
        let mut doc_base = LatticeDoc::new(9);
        apply_delta(&mut doc_base, 9, &stream_a);
        let mut a = doc_base.clone();
        a.set_counter_hint(100);
        apply_delta(
            &mut a,
            1,
            &ops(&[
                LatOp::Retain { count: 5 },
                LatOp::Insert {
                    text: "from-A".into(),
                },
            ]),
        );
        let mut b = doc_base;
        apply_delta(
            &mut b,
            2,
            &ops(&[
                LatOp::Retain { count: 5 },
                LatOp::Insert {
                    text: "from-B".into(),
                },
            ]),
        );
        let mut ab = a.clone();
        ab.merge(&b);
        let mut ba = b.clone();
        ba.merge(&a);
        assert_eq!(ab.render(), ba.render());
        let r = ab.render();
        assert!(r.starts_with("base "), "{}", r);
        assert!(r.contains("from-A") && r.contains("from-B"), "{}", r);
    }

    // P1-1 (CLOSED): concurrent splits of the same unit used to
    // duplicate content — parts carried replica-local lineage. Fix:
    // ROOT-ANCHORED lineage (part dot derived from the root unit's
    // dot + root-coordinate char range), so identical sub-ranges
    // coalesce and deleter culls trim concurrently-derived parts.
    #[test]
    fn sim_concurrent_delete_vs_insert_range_semantics() {
        // Shared base on a neutral server (dot (9,1)); replicas are
        // DISTINCT servers — dot uniqueness requires it (a clone with
        // the same server id would collide counters in merge).
        let base_addr = Sequence::from_numbers(vec![1, 9, 1]);
        let mut doc_a = LatticeDoc::new(1);
        let mut doc_b = LatticeDoc::new(2);
        doc_a.seed_shared_unit(base_addr.clone(), "0123456789", 9, (9, 1));
        doc_b.seed_shared_unit(base_addr.clone(), "0123456789", 9, (9, 1));
        apply_delta(
            &mut doc_a,
            1,
            &ops(&[
                LatOp::Retain { count: 3 },
                LatOp::Delete { count: 4 },
                LatOp::Retain { count: 3 },
            ]),
        );
        apply_delta(
            &mut doc_b,
            2,
            &ops(&[
                LatOp::Retain { count: 5 },
                LatOp::Insert { text: "X".into() },
                LatOp::Delete { count: 1 },
                LatOp::Retain { count: 3 },
            ]),
        );
        let mut m = doc_a.clone();
        m.merge(&doc_b);
        let mut m2 = doc_b.clone();
        m2.merge(&doc_a);
        assert_eq!(m.render(), m2.render(), "order independence");
        let text = m.render();
        // Exact expectation: root-relative addressing makes the
        // merged interleaving deterministic ("012" + X + "789").
        assert_eq!(text, "012X789", "concurrent delete + insert");
        assert_eq!(
            text.chars().count(),
            7,
            "4 deleted of 10, +1 insert: {:?}",
            text
        );
    }

    // F5/F8-class structural armor (FR-51 Phase 2): a live unit's
    // address, dot, and content are IMMUTABLE under edits elsewhere.
    // Spans anchored to addresses never need migration code — the
    // quadratic link-span-migration finding class cannot exist on
    // this substrate by construction.
    #[test]
    fn edits_elsewhere_never_move_addresses() {
        let mut doc = LatticeDoc::new(1);
        let chunks = 40;
        for c in 0..chunks {
            let ops = vec![
                LatOp::Retain {
                    count: (c * 5) as u64,
                },
                LatOp::Insert {
                    text: "01234".into(),
                },
            ];
            apply_delta(&mut doc, 1, &ops);
        }
        // 200 chars; marker unit = the one containing offset 100.
        let (m_addr, m_dot, _, _) = doc.find_boundary(100).unwrap();
        let before = doc.address_of(m_dot).map(|a| a.numbers().to_vec()).unwrap();
        let content_before = doc.debug_units();
        let m_content = content_before
            .iter()
            .find(|(_, _, d, ..)| *d == m_dot)
            .map(|(_, c, ..)| c.clone())
            .unwrap();

        // Edit storm strictly outside the marker unit: inserts and
        // deletes before offset 100 and after its end.
        for k in 0..10u64 {
            apply_delta(
                &mut doc,
                1,
                &ops(&[
                    LatOp::Retain { count: k * 3 },
                    LatOp::Insert { text: "XY".into() },
                ]),
            );
            apply_delta(
                &mut doc,
                1,
                &ops(&[LatOp::Retain { count: 190 }, LatOp::Delete { count: 1 }]),
            );
        }
        apply_delta(
            &mut doc,
            1,
            &ops(&[
                LatOp::Retain { count: 250 },
                LatOp::Insert { text: "Z".into() },
            ]),
        );

        // The marker unit is untouched: same dot, same address, same
        // content — no migration ran because none is needed.
        let after = doc.debug_units();
        let m = after.iter().find(|(_, _, d, ..)| *d == m_dot);
        assert!(m.is_some(), "marker unit must survive");
        let (_, c, ..) = m.unwrap();
        assert_eq!(*c, m_content, "marker content unchanged");
        let a_now = doc.address_of(m_dot).map(|a| a.numbers().to_vec()).unwrap();
        assert_eq!(a_now, before, "marker address unchanged: {:?}", m_addr);
        let still_live = doc.debug_index().iter().any(|(_, d, _)| *d == m_dot);
        assert!(still_live, "marker unit still in the live index");
    }

    #[test]
    fn multi_writer_interleaved_matches_otree() {
        use crate::edition::Edition;
        use crate::server::transport::protocol::TextDeltaOp;
        use crate::server::Server;

        let base = "0123456789";
        // O-tree oracle: two sessions, deltas vs their own views.
        let mut server = Server::new();
        let s1 = server.connect();
        let s2 = server.connect();
        let _ = server.login_public(s1);
        let _ = server.login_public(s2);
        let work = server.create_work(s1, Edition::from_text(base)).unwrap();
        server.crdt_open_session(s1, work).unwrap();
        server.crdt_open_session(s2, work).unwrap();

        let op1 = [
            TextDeltaOp::Retain { count: 3 },
            TextDeltaOp::Insert { text: "ONE".into() },
            TextDeltaOp::Retain { count: 7 },
        ];
        let op2 = [
            TextDeltaOp::Retain { count: 7 },
            TextDeltaOp::Insert { text: "TWO".into() },
            TextDeltaOp::Retain { count: 3 },
        ];
        // vs s1's view "012ONE3456789": delete "NE"
        let op3 = [
            TextDeltaOp::Retain { count: 4 },
            TextDeltaOp::Delete { count: 2 },
            TextDeltaOp::Retain { count: 7 },
        ];
        // vs the synced view: "!" at the front
        let op4 = [
            TextDeltaOp::Insert { text: "!".into() },
            TextDeltaOp::Retain { count: 14 },
        ];

        server.crdt_apply_text_delta(s1, work, &op1).unwrap();
        server.crdt_apply_text_delta(s2, work, &op2).unwrap();
        server.crdt_apply_text_delta(s1, work, &op3).unwrap();
        server.crdt_apply_text_delta(s2, work, &op4).unwrap();
        let otree_text = server.crdt_current_text(work).unwrap();

        // Lattice multi-writer, same script.
        let lat = |ops: &[TextDeltaOp]| -> Vec<LatOp> {
            ops.iter()
                .map(|o| match o {
                    TextDeltaOp::Retain { count } => LatOp::Retain { count: *count },
                    TextDeltaOp::Insert { text } => LatOp::Insert { text: text.clone() },
                    TextDeltaOp::Delete { count } => LatOp::Delete { count: *count },
                })
                .collect()
        };
        let mut mw = MultiWriter::new(base);
        mw.open_session(1);
        mw.open_session(2);
        mw.apply(1, &lat(&op1));
        mw.apply(2, &lat(&op2));
        mw.apply(1, &lat(&op3));
        mw.sync(2);
        mw.apply(2, &lat(&op4));
        let text = mw.text();
        assert_eq!(text, otree_text, "multi-writer vs O-tree");
    }

    #[test]
    fn multi_writer_three_sessions_delivery_order_independent() {
        let script = |order: &[(u64, &str, u64)]| -> String {
            let mut mw = MultiWriter::new("0123456789");
            for a in 1..=3u64 {
                mw.open_session(a);
            }
            for &(author, text, at) in order {
                mw.apply(
                    author,
                    &vec![
                        LatOp::Retain { count: at },
                        LatOp::Insert { text: text.into() },
                        LatOp::Retain { count: 10 - at },
                    ],
                );
            }
            // Sync everyone, then a second round vs synced views.
            for a in 1..=3u64 {
                mw.sync(a);
            }
            for &(author, text, at) in order {
                mw.apply(
                    author,
                    &vec![
                        LatOp::Retain { count: at },
                        LatOp::Insert {
                            text: text.to_lowercase(),
                        },
                        LatOp::Retain { count: 13 - at },
                    ],
                );
            }
            mw.text()
        };
        let round1 = vec![(1u64, "A", 2u64), (2, "B", 5), (3, "C", 8)];
        let mut reversed = round1.clone();
        reversed.reverse();
        let a = script(&round1);
        let b = script(&reversed);
        assert_eq!(a, b, "delivery order must not matter");
        assert_eq!(
            a.chars().count(),
            10 + 6,
            "all six inserts survive: {:?}",
            a
        );
        for ch in ["a", "b", "c", "A", "B", "C"] {
            assert!(a.contains(ch), "missing {:?} in {:?}", ch, a);
        }
    }

    #[test]
    fn multi_writer_concurrent_delete_vs_insert_semantics() {
        // A deletes [3,7) vs base; B inserts X at 5 vs base. The
        // insert is concurrent and unseen by the deleter: it
        // survives, positioned inside the deleted span's gap. The
        // O-tree agrees in both delivery orders (probed), so this is
        // armor on AGREED semantics, not lattice-only behavior.
        use crate::edition::Edition;
        use crate::server::transport::protocol::TextDeltaOp;
        use crate::server::Server;

        let base = "0123456789";
        let del = [
            TextDeltaOp::Retain { count: 3 },
            TextDeltaOp::Delete { count: 4 },
            TextDeltaOp::Retain { count: 3 },
        ];
        let ins = [
            TextDeltaOp::Retain { count: 5 },
            TextDeltaOp::Insert { text: "X".into() },
            TextDeltaOp::Retain { count: 5 },
        ];

        let otree = |first_del: bool| -> String {
            let mut server = Server::new();
            let s1 = server.connect();
            let s2 = server.connect();
            let _ = server.login_public(s1);
            let _ = server.login_public(s2);
            let work = server.create_work(s1, Edition::from_text(base)).unwrap();
            server.crdt_open_session(s1, work).unwrap();
            server.crdt_open_session(s2, work).unwrap();
            if first_del {
                server.crdt_apply_text_delta(s1, work, &del).unwrap();
                server.crdt_apply_text_delta(s2, work, &ins).unwrap();
            } else {
                server.crdt_apply_text_delta(s2, work, &ins).unwrap();
                server.crdt_apply_text_delta(s1, work, &del).unwrap();
            }
            server.crdt_current_text(work).unwrap()
        };

        let mut mw = MultiWriter::new(base);
        mw.open_session(1);
        mw.open_session(2);
        mw.apply(
            1,
            &vec![
                LatOp::Retain { count: 3 },
                LatOp::Delete { count: 4 },
                LatOp::Retain { count: 3 },
            ],
        );
        mw.apply(
            2,
            &vec![
                LatOp::Retain { count: 5 },
                LatOp::Insert { text: "X".into() },
                LatOp::Retain { count: 5 },
            ],
        );
        let text = mw.text();
        assert_eq!(text, "012X789", "unseen insert survives the delete");
        assert_eq!(otree(true), "012X789", "O-tree agrees (delete first)");
        assert_eq!(otree(false), "012X789", "O-tree agrees (insert first)");
    }

    // Deterministic chaos armor (Phase 3): a fixed-seed pseudo-random
    // script of inserts/deletes/syncs across three writers, executed
    // under two different delivery orders, must converge to the same
    // text. LCG keeps it reproducible without a rand dependency.
    #[test]
    fn multi_writer_chaos_converges_across_delivery_orders() {
        struct Lcg(u64);
        impl Lcg {
            fn next(&mut self) -> u64 {
                self.0 = self
                    .0
                    .wrapping_mul(6364136223846793005)
                    .wrapping_add(1442695040888963407);
                self.0 >> 33
            }
        }
        // The logical script: (author, op, view-generation marker).
        // Ops are computed against the author's CURRENT view at
        // execution time, so the script must be replay-dependent —
        // instead we precompute per-round batches: within a round no
        // syncs happen (all ops concurrent), between rounds everyone
        // syncs (positions well-defined against the shared state).
        let mut rng = Lcg(0x5EED_51);
        let rounds = 6;
        let mut batch_a: Vec<Vec<(u64, LatOp)>> = Vec::new();
        let mut batch_b: Vec<Vec<(u64, LatOp)>> = Vec::new();
        for _ in 0..rounds {
            let mut round: Vec<(u64, LatOp)> = Vec::new();
            let mut round_rev: Vec<(u64, LatOp)> = Vec::new();
            for author in 1..=3u64 {
                let n = 3 + (rng.next() % 3) as u64;
                match rng.next() % 3 {
                    0 => round.push((author, LatOp::Retain { count: n })),
                    1 => round.push((
                        author,
                        LatOp::Insert {
                            text: format!("w{}-", author),
                        },
                    )),
                    _ => round.push((author, LatOp::Delete { count: n })),
                }
                round_rev = round.clone();
            }
            round_rev.reverse();
            batch_a.push(round);
            batch_b.push(round_rev);
        }

        let run = |batches: &Vec<Vec<(u64, LatOp)>>| -> String {
            let mut mw = MultiWriter::new("abcdefghij");
            for a in 1..=3u64 {
                mw.open_session(a);
            }
            for round in batches {
                for (author, op) in round {
                    mw.apply(*author, &[op.clone()]);
                }
                for a in 1..=3u64 {
                    mw.sync(a);
                }
            }
            mw.text()
        };

        let a = run(&batch_a);
        let b = run(&batch_b);
        assert_eq!(
            a, b,
            "chaos delivery orders must converge: {:?} vs {:?}",
            a, b
        );
        // Deletion-heavy chaos can empty the doc; assert only
        // convergence plus length coherence here.
        assert!(a.chars().count() <= 10 + 3 * rounds * 3);
    }

    #[test]
    fn opstream_jsonl_roundtrip_shape() {
        let ev = OpEvent {
            session: 3,
            ops: ops(&[
                LatOp::Retain { count: 4 },
                LatOp::Insert {
                    text: "a\"b\nc".into(),
                },
                LatOp::Delete { count: 2 },
            ]),
        };
        let line = ev.to_jsonl();
        assert!(line.contains("\"retain\":4"));
        assert!(line.contains("\\\""));
        assert!(line.contains("\\n"));
        assert!(line.ends_with("]}\n"));
    }

    #[cfg(feature = "server")]
    #[test]
    fn acceptance_multi_session_matches_otree() {
        use crate::edition::Edition;
        use crate::server::transport::protocol::TextDeltaOp;
        use crate::server::{Server, SessionId};
        use crate::space::sequence::Sequence;

        // Two sessions edit concurrently; each delta is computed
        // against that session's OWN view (the server tracks
        // per-session bases). The O-tree's merged text is the oracle;
        // the lattice must reproduce it from the per-session streams
        // replayed on independent replicas, in both delivery orders.
        let base = "0123456789";
        let mut server = Server::new();
        let s1 = server.connect();
        let s2 = server.connect();
        let _ = server.login_public(s1);
        let _ = server.login_public(s2);
        let work = server.create_work(s1, Edition::from_text(base)).unwrap();
        server.crdt_open_session(s1, work).unwrap();
        server.crdt_open_session(s2, work).unwrap();

        let d = |ops: &[TextDeltaOp]| ops.to_vec();
        let stream1: Vec<Vec<TextDeltaOp>> = vec![
            d(&[
                TextDeltaOp::Retain { count: 3 },
                TextDeltaOp::Insert { text: "ONE".into() },
                TextDeltaOp::Retain { count: 7 },
            ]),
            // vs s1's view "012ONE3456789"
            d(&[
                TextDeltaOp::Insert { text: "!".into() },
                TextDeltaOp::Retain { count: 13 },
            ]),
        ];
        let stream2: Vec<Vec<TextDeltaOp>> = vec![
            // vs the untouched base
            d(&[
                TextDeltaOp::Retain { count: 7 },
                TextDeltaOp::Insert { text: "TWO".into() },
                TextDeltaOp::Retain { count: 3 },
            ]),
        ];

        for ops in &stream1 {
            server.crdt_apply_text_delta(s1, work, ops).unwrap();
        }
        for ops in &stream2 {
            server.crdt_apply_text_delta(s2, work, ops).unwrap();
        }
        let otree_text = server.crdt_current_text(work).unwrap();

        let to_lat = |ops: &TextDeltaOp| match ops {
            TextDeltaOp::Retain { count } => LatOp::Retain { count: *count },
            TextDeltaOp::Insert { text } => LatOp::Insert { text: text.clone() },
            TextDeltaOp::Delete { count } => LatOp::Delete { count: *count },
        };

        let root_addr = Sequence::from_numbers(vec![1, 9, 1]);
        let mut doc1 = LatticeDoc::new(1);
        doc1.seed_shared_unit(root_addr.clone(), base, 9, (9, 1));
        for ops in &stream1 {
            let lat: Vec<LatOp> = ops.iter().map(to_lat).collect();
            apply_delta(&mut doc1, 1, &lat);
        }
        let mut doc2 = LatticeDoc::new(2);
        doc2.seed_shared_unit(root_addr.clone(), base, 9, (9, 1));
        for ops in &stream2 {
            let lat: Vec<LatOp> = ops.iter().map(to_lat).collect();
            apply_delta(&mut doc2, 2, &lat);
        }

        let mut ab = doc1.clone();
        ab.merge(&doc2);
        let mut ba = doc2.clone();
        ba.merge(&doc1);
        let (text_ab, text_ba) = (ab.render(), ba.render());
        assert_eq!(text_ab, text_ba, "delivery order must not matter");
        assert_eq!(
            text_ab, otree_text,
            "multi-session acceptance: lattice must match the O-tree"
        );
    }

    #[cfg(feature = "server")]
    #[test]
    fn acceptance_single_session_matches_otree() {
        use crate::edition::Edition;
        use crate::server::transport::protocol::TextDeltaOp;
        use crate::server::{Server, SessionId};

        let text = "the quick brown fox jumps over the lazy dog";
        let mut server = Server::new();
        let sid = server.connect();
        server.login_public(sid).unwrap();
        let work = server.create_work(sid, Edition::from_text(text)).unwrap();
        server.crdt_open_session(sid, work).unwrap();

        let to_lat = |ops: &[TextDeltaOp]| -> Vec<LatOp> {
            ops.iter()
                .map(|o| match o {
                    TextDeltaOp::Retain { count } => LatOp::Retain { count: *count },
                    TextDeltaOp::Insert { text } => LatOp::Insert { text: text.clone() },
                    TextDeltaOp::Delete { count } => LatOp::Delete { count: *count },
                })
                .collect()
        };

        let edits: Vec<Vec<TextDeltaOp>> = vec![
            vec![
                TextDeltaOp::Retain { count: 4 },
                TextDeltaOp::Insert {
                    text: "VERY ".into(),
                },
                TextDeltaOp::Retain { count: 36 },
            ],
            vec![
                TextDeltaOp::Retain { count: 0 },
                TextDeltaOp::Insert { text: "++ ".into() },
                TextDeltaOp::Retain { count: 45 },
            ],
            vec![
                TextDeltaOp::Retain { count: 48 },
                TextDeltaOp::Delete { count: 4 },
                TextDeltaOp::Retain { count: 1 },
            ],
            vec![
                TextDeltaOp::Retain { count: 10 },
                TextDeltaOp::Delete { count: 6 },
                TextDeltaOp::Retain { count: 30 },
            ],
        ];

        for e in &edits {
            server.crdt_apply_text_delta(sid, work, e).unwrap();
        }
        let otree_text = server.crdt_current_text(work).unwrap();

        let mut doc = LatticeDoc::new(1);
        apply_delta(&mut doc, 1, &ops(&[LatOp::Insert { text: text.into() }]));
        for e in &edits {
            apply_delta(&mut doc, 1, &to_lat(e));
        }
        assert_eq!(
            doc.render(),
            otree_text,
            "single-session acceptance: lattice must match the O-tree exactly"
        );
    }
}
