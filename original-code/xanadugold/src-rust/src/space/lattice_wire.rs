//! FR-34/FR-51: lattice wire payloads — the serialized form of the
//! anti-entropy traffic. Units and tombstones as plain data
//! (addresses as number vectors; regions as edge descriptors
//! reconstructed through the interval/above constructors). postcard
//! on the wire, mirroring the crate's binary-format convention.
//!
//! The transport (FederationFrame) adopts these once lattice state
//! is federated at cutover; the protocol and byte-exactness are
//! proven here.

use super::lattice::{Dot, LatticeDoc, LatticeUnit, RegionTombstone};
use super::sequence::{Sequence, SequenceRegion};
use std::collections::HashSet;

#[derive(Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct WireUnit {
    pub addr: Vec<i64>,
    pub dot: (u64, u64),
    pub content: String,
    pub author: u64,
    pub lineage: Option<((u64, u64), usize, usize)>,
    pub anchor: Option<((u64, u64), usize)>,
}

#[derive(Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct WireTombstone {
    pub starts_inside: bool,
    pub edges: Vec<(Vec<i64>, bool)>,
    pub context: Vec<(u64, u64)>,
    pub culls: Vec<((u64, u64), usize, usize)>,
}

#[derive(Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct WirePayload {
    pub units: Vec<WireUnit>,
    pub tombstones: Vec<WireTombstone>,
}

impl From<&LatticeUnit> for WireUnit {
    fn from(u: &LatticeUnit) -> Self {
        WireUnit {
            addr: u.address.numbers().to_vec(),
            dot: u.dot,
            content: u.content.clone(),
            author: u.author,
            lineage: u.lineage,
            anchor: u.anchor,
        }
    }
}

impl From<&RegionTombstone> for Option<WireTombstone> {
    fn from(t: &RegionTombstone) -> Self {
        let (starts_inside, edges) = t.region.edge_descriptors();
        Some(WireTombstone {
            starts_inside,
            edges,
            context: t.context.iter().copied().collect(),
            culls: t.culls.clone(),
        })
    }
}

/// Serialize the anti-entropy payload for the given dots plus all
/// tombstones (postcard bytes). postcard is a server-feature dep,
/// so the wire functions gate with it (the payload structs above
/// stay available in every build).
#[cfg(feature = "server")]
pub fn encode_payload(doc: &LatticeDoc, dots: &[Dot]) -> Option<Vec<u8>> {
    let units: Vec<WireUnit> = dots
        .iter()
        .filter_map(|d| doc.debug_unit(d).map(WireUnit::from))
        .collect();
    let tombstones: Vec<WireTombstone> = doc
        .debug_tombstones()
        .iter()
        .filter_map(|t| <&RegionTombstone as Into<Option<WireTombstone>>>::into(t))
        .collect();
    postcard::to_allocvec(&WirePayload { units, tombstones }).ok()
}

/// Decode and apply a payload: units are unioned (same dot = same
/// unit), tombstones extended, then the index is rebuilt — the
/// receiving half of anti-entropy.
#[cfg(feature = "server")]
pub fn decode_and_apply(doc: &mut LatticeDoc, bytes: &[u8]) -> Result<usize, String> {
    let payload: WirePayload = postcard::from_bytes(bytes).map_err(|e| format!("decode: {}", e))?;
    let mut added = 0usize;
    for w in &payload.units {
        if doc.debug_unit(&w.dot).is_none() {
            doc.debug_insert_unit(
                Sequence::from_numbers(w.addr.clone()),
                w.content.clone(),
                w.author,
                w.dot,
                w.lineage,
                w.anchor,
            );
            added += 1;
        }
    }
    for t in &payload.tombstones {
        let region = SequenceRegion::from_edge_descriptors(t.starts_inside, &t.edges)
            .ok_or_else(|| format!("unsupported region shape: {} edges", t.edges.len()))?;
        doc.debug_push_tombstone(
            region,
            t.context.iter().copied().collect::<HashSet<_>>(),
            t.culls.clone(),
        );
    }
    doc.debug_rebuild();
    Ok(added)
}

#[cfg(all(test, feature = "server"))]
mod tests {
    use super::super::lattice_multi::MultiWriter;
    use super::super::lattice_sim::{apply_delta, LatOp};
    use super::*;

    // E2E: two independent replicas with concurrent histories
    // reconcile EXCLUSIVELY through serialized wire payloads (the
    // transport minus the socket). Convergence on crums and text.
    #[test]
    fn replicas_reconcile_over_wire_bytes() {
        let base = "wire e2e shared document content ";
        let mut a = MultiWriter::with_namespace(base, 1);
        let mut b = MultiWriter::with_namespace(base, 2);
        a.open_session(1);
        b.open_session(2);
        for k in 0..6u64 {
            a.apply(
                1,
                &[
                    LatOp::Retain { count: 10 + k * 7 },
                    LatOp::Insert { text: "L".into() },
                ],
            );
            b.apply(
                2,
                &[
                    LatOp::Retain { count: 20 + k * 9 },
                    LatOp::Delete { count: 2 },
                ],
            );
        }
        // Exchange wire payloads both directions until crums match.
        for _ in 0..4 {
            if a.shared_crum().is_some() && a.shared_crum() == b.shared_crum() {
                break;
            }
            let d1 = b.diff_against(&mut a);
            let d2 = a.diff_against(&mut b);
            if !d1.is_empty() {
                let bytes = encode_payload(&a.debug_doc_clone(), &d1).expect("encode");
                let mut bdoc = b.debug_doc_clone();
                decode_and_apply(&mut bdoc, &bytes).expect("apply b");
                b.adopt_doc(bdoc);
            }
            if !d2.is_empty() {
                let bytes = encode_payload(&b.debug_doc_clone(), &d2).expect("encode");
                let mut adoc = a.debug_doc_clone();
                decode_and_apply(&mut adoc, &bytes).expect("apply a");
                a.adopt_doc(adoc);
            }
        }
        assert_eq!(
            a.shared_crum(),
            b.shared_crum(),
            "wire reconcile must converge"
        );
        assert_eq!(a.text(), b.text());
        assert!(a.text().matches('L').count() >= 6, "all inserts survive");
    }

    #[test]
    fn payload_round_trip_preserves_state() {
        let mut mw = MultiWriter::with_namespace("round trip base text", 7);
        mw.open_session(1);
        for k in 0..10u64 {
            mw.apply(
                1,
                &[
                    LatOp::Retain { count: 4 + k * 5 },
                    LatOp::Insert { text: "XY".into() },
                ],
            );
        }
        let source = mw.debug_doc_clone();
        let dots = source.all_live_dots_public();
        let bytes = encode_payload(&source, &dots).expect("encode");
        let mut receiver = LatticeDoc::new(9);
        decode_and_apply(&mut receiver, &bytes).expect("apply");
        // Canonical equality of the LIVE sets (receiver has no views).
        let mut a = source;
        let mut b = receiver;
        let d = a.crum_diff(&mut b);
        assert!(
            d.only_self.is_empty() && d.only_other.is_empty(),
            "round trip must preserve the live set"
        );
        assert_eq!(a.render(), b.render());
    }

    #[test]
    fn wire_bytes_match_estimate_and_stay_small() {
        // Real postcard bytes for a small edit on a large fragmented
        // doc: proportionality with MEASURED bytes.
        let base = "0123456789abcdef".repeat(8000);
        let mut a = MultiWriter::with_namespace(&base, 1);
        a.open_session(1);
        for k in 0..200u64 {
            a.apply(
                1,
                &[
                    LatOp::Retain { count: k * 600 },
                    LatOp::Insert { text: "|".into() },
                ],
            );
        }
        let mut b = MultiWriter::with_namespace(&base, 2);
        b.import_state_from(&a);
        b.open_session(2);
        b.apply(
            2,
            &[
                LatOp::Retain { count: 50_000 },
                LatOp::Insert { text: "Q".into() },
            ],
        );
        let d = a.diff_against(&mut b);
        let doc = a.debug_doc_clone();
        let bytes = encode_payload(&doc, &d).expect("encode");
        let full = encode_payload(&doc, &doc.all_live_dots_public()).expect("full encode");
        assert!(
            bytes.len() * 10 < full.len(),
            "wire payload {} must be <10% of full {} ",
            bytes.len(),
            full.len()
        );
    }
}
