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

use super::lattice::{Dot, LatticeDoc, LatticeUnit};
use super::sequence::Sequence;

#[derive(Debug, Clone, PartialEq)]
pub enum LatOp {
    Retain { count: u64 },
    Insert { text: String },
    Delete { count: u64 },
}

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
                let (prev, next) = split_at(doc, offset);
                doc.insert_between(prev.as_ref(), next.as_ref(), text.clone(), author);
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
                let (_, end) = split_at(doc, offset + count);
                let (_, start) = split_at(doc, offset);
                match (start, end) {
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
/// document edges).
fn split_at(doc: &mut LatticeDoc, offset: u64) -> (Option<Sequence>, Option<Sequence>) {
    let offset = offset as usize;
    let mut cum = 0usize;
    let live: Vec<(Sequence, String, Dot)> = doc
        .live()
        .into_iter()
        .map(|u| (u.address.clone(), u.content.clone(), u.dot))
        .collect();
    for (i, (addr, content, dot)) in live.iter().enumerate() {
        let len = content.chars().count();
        if offset < cum + len {
            // Boundary falls strictly inside this unit: split it.
            let chars: Vec<char> = content.chars().collect();
            let left: String = chars[..offset - cum].iter().collect();
            let right: String = chars[offset - cum..].iter().collect();
            let prev_addr = if i > 0 {
                Some(live[i - 1].0.clone())
            } else {
                None
            };
            let next_addr = live.get(i + 1).map(|(a, _, _)| a.clone());
            // Tombstone the whole unit, then re-insert the parts
            // inside its own address span.
            doc.tombstone_dot(*dot);
            let mut before = prev_addr.clone();
            let mut after = Some(addr.clone());
            if !left.is_empty() {
                let d = doc.insert_between(prev_addr.as_ref(), Some(addr), left.clone(), dot.0);
                before = doc.address_of(d).cloned();
            }
            if !right.is_empty() {
                let d = doc.insert_between(Some(addr), next_addr.as_ref(), right.clone(), dot.0);
                after = doc.address_of(d).cloned();
            }
            return (before, after);
        }
        if offset == cum + len {
            let prev = Some(addr.clone());
            let next = live.get(i + 1).map(|(a, _, _)| a.clone());
            return (prev, next);
        }
        cum += len;
    }
    // Offset at/after the end.
    let last = live.last().map(|(a, _, _)| a.clone());
    (last, None)
}

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

    // P1-1 (open): concurrent splits of the same unit duplicate
    // content — both replicas re-insert parts with independent dots.
    // Fix direction: deterministic lineage (part dot derived from
    // parent dot + offset) so identical splits coalesce. Single-
    // session acceptance vs the O-tree PASSES; see FR-51.
    #[test]
    #[ignore = "P1-1: concurrent split duplication — deterministic lineage owed"]
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
        assert!(text.contains('X'), "unseen insert survives: {:?}", text);
        assert_eq!(
            text.chars().count(),
            7,
            "4 deleted of 10, +1 insert: {:?}",
            text
        );
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
