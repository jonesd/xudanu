//! FR-51 Phase 3/4: the multi-writer document — production form.
//!
//! `MultiWriter` serves concurrent sessions the way the O-tree
//! server does, but with no three-way merge: per-session views,
//! author-minted dots, seen-set deletes, deterministic split
//! mirroring, convergence by construction. The simulator
//! (lattice_sim) drives the same machinery for acceptance armor;
//! the server drives it for the Phase 4 dual-write shadow.

use super::lattice::{Dot, LatticeDoc};

use super::sequence::Sequence;

#[derive(Debug, Clone, PartialEq)]
pub enum LatOp {
    Retain { count: u64 },
    Insert { text: String },
    Delete { count: u64 },
}

/// A resolved document boundary: the addresses of the units
/// immediately before and after it, the root anchor for fresh
/// inserts landing on it, and — when the boundary fell strictly
/// inside a unit and it was split — the (dot, at) of that split, so
/// callers can mirror the same deterministic split in another doc.
pub struct Boundary {
    pub prev: Option<Sequence>,
    pub next: Option<Sequence>,
    pub anchor: Option<(Dot, usize)>,
    pub split: Option<(Dot, usize)>,
}

impl Boundary {
    pub fn prev_next(&self) -> (Option<&Sequence>, Option<&Sequence>) {
        (self.prev.as_ref(), self.next.as_ref())
    }
}

pub fn split_at(doc: &mut LatticeDoc, offset: u64) -> Boundary {
    let offset = offset as usize;
    match doc.find_boundary(offset) {
        Some((addr, dot, cum, len)) => {
            if offset == cum + len {
                // Boundary exactly at the unit's end.
                let next = doc.live_succ(&addr);
                let anchor = doc.boundary_anchor_after(dot);
                Boundary {
                    prev: Some(addr),
                    next,
                    anchor,
                    split: None,
                }
            } else {
                // Strictly inside (offset == cum is a leading no-op
                // split): root-anchored lineage, deterministic part
                // dots.
                let at = offset - cum;
                let (prev, next, anchor) = doc.split_unit(dot, at);
                Boundary {
                    prev,
                    next,
                    anchor,
                    split: Some((dot, at)),
                }
            }
        }
        None => {
            // Empty doc or offset past the end.
            let last = doc.live_last();
            let anchor = last
                .as_ref()
                .and_then(|(_, d)| doc.boundary_anchor_after(*d));
            Boundary {
                prev: last.map(|(a, _)| a),
                next: None,
                anchor,
                split: None,
            }
        }
    }
}

/// FR-51 Phase 3: the multi-writer document — the lattice serving
/// concurrent sessions the way the O-tree server does, but with no
/// three-way merge: convergence by construction.
///
/// Each session owns a VIEW (its last-known state). Deltas arrive as
/// positions against that view; inserts mint dots from the session's
/// author id and counter; deletes carry the session's seen-set as
/// causal context (concurrent unseen content survives); view-side
/// splits are mirrored deterministically into the shared doc (same
/// root ranges mint the same part dots). `sync` delivers the shared
/// state to a session's view.
pub struct MultiWriter {
    /// FR-51 C-1: provenance to stamp on units created by the
    /// current apply_with_provenance call. Cleared after.
    pending_provenance: Option<super::lattice::LatticeProvenance>,
    /// 0 = single-instance (plain dense ids); non-zero = federation
    /// namespace folded into dots so cross-instance sync cannot
    /// collide.
    namespace: u64,
    doc: LatticeDoc,
    views: std::collections::HashMap<u64, LatticeDoc>,
    counters: std::collections::HashMap<u64, u64>,
    /// Session ids are opaque (often random u64s); dots and address
    /// ordering need small dense author ids — assigned in join order.
    authors: std::collections::HashMap<u64, u64>,
    next_author: u64,
    ops_applied: usize,
    apply_ns: u128,
}

impl MultiWriter {
    pub fn new(base: &str) -> Self {
        Self::with_namespace(base, 0)
    }

    /// Federation constructor: distinct namespaces keep dots unique
    /// across independent instances that will sync via crum diff.
    pub fn with_namespace(base: &str, namespace: u64) -> Self {
        let mut doc = LatticeDoc::new(0);
        doc.seed_shared_unit(Sequence::from_numbers(vec![1, 9, 1]), base, 9, (9, 1));
        MultiWriter {
            pending_provenance: None,
            namespace,
            doc,
            views: std::collections::HashMap::new(),
            counters: std::collections::HashMap::new(),
            authors: std::collections::HashMap::new(),
            next_author: 0,
            ops_applied: 0,
            apply_ns: 0,
        }
    }

    /// Dense author id for a session (join order). Federation note:
    /// dots must be globally unique — replicas in DIFFERENT
    /// MultiWriter instances (different servers) must use distinct
    /// namespaces (`with_namespace`), or their dense ids collide.
    fn dense(&mut self, session: u64) -> u64 {
        if let Some(d) = self.authors.get(&session) {
            return *d;
        }
        self.next_author += 1;
        let d = self.next_author;
        self.authors.insert(session, d);
        d
    }

    fn dense_dot(&self, dense: u64, counter: u64) -> Dot {
        if self.namespace == 0 {
            (dense, counter)
        } else {
            (self.namespace * 1_000_000_000 + dense, counter)
        }
    }

    /// Debug: the shared doc's in-order (address numbers, dot, len).
    pub fn debug_state(&mut self) -> Vec<(Vec<i64>, Dot, usize)> {
        self.doc.debug_index()
    }

    /// Deltas applied since construction (shadow telemetry).
    pub fn ops_applied(&self) -> usize {
        self.ops_applied
    }

    /// Total time spent applying deltas (dual-engine bench).
    pub fn apply_nanos(&self) -> u128 {
        self.apply_ns
    }

    /// One-directional crum diff: dots LIVE in `other` that self
    /// lacks (the anti-entropy pull list).
    pub fn diff_against(&mut self, other: &mut MultiWriter) -> Vec<Dot> {
        // Dots live in `other` that self lacks: self's diff view of
        // other (only_other).
        self.doc.diff_public(&mut other.doc)
    }

    /// Pull specific units (plus all tombstones) from `other` —
    /// the anti-entropy apply step.
    pub fn pull_units_from(&mut self, other: &MultiWriter, dots: &[Dot]) {
        self.doc.pull_from(&other.doc, dots);
    }

    /// Estimated wire bytes for the given unit dots (content +
    /// per-unit overhead) — payload accounting for anti-entropy.
    pub fn units_bytes_for(&self, dots: &[Dot]) -> usize {
        self.doc.units_bytes_for(dots)
    }

    /// Estimated bytes of the FULL state (all units + tombstones) —
    /// the proportionality baseline.
    pub fn full_state_bytes(&self) -> usize {
        self.doc.full_state_bytes()
    }

    /// Adopt another instance's entire state (test scaffolding for
    /// setting up divergent replicas sharing history).
    pub fn import_state_from(&mut self, other: &MultiWriter) {
        let all = other.doc.all_live_dots_public();
        self.doc.pull_from(&other.doc, &all);
    }

    /// FR-34 federation reconcile: bidirectional crum-diff sync —
    /// each side pulls exactly the units it lacks plus the other's
    /// tombstones. Converges both replicas (canonical crums equal).
    pub fn sync_with(&mut self, other: &mut MultiWriter) {
        let d1 = other.doc.crum_diff(&mut self.doc);
        other.doc.pull_from(&self.doc, &d1.only_other);
        let d2 = self.doc.crum_diff(&mut other.doc);
        self.doc.pull_from(&other.doc, &d2.only_other);
    }

    /// Canonical crum of the shared document (exact live-set hash).
    pub fn shared_crum(&mut self) -> Option<[u8; 32]> {
        self.doc.canonical_crum()
    }

    /// Debug: clone of the shared doc (wire tests).
    pub fn debug_doc_clone(&self) -> LatticeDoc {
        self.doc.clone()
    }

    /// Adopt a reconciled doc as the shared state (wire tests —
    /// views are dropped; sessions re-sync on next apply).
    pub fn adopt_doc(&mut self, doc: LatticeDoc) {
        self.doc = doc;
        self.views.clear();
    }

    /// Debug: the shared doc's live dot set.
    pub fn debug_live_dots(&self) -> Vec<(u64, u64)> {
        self.doc.live().iter().map(|u| u.dot).collect()
    }

    /// Debug: canonical live descriptors (address, dot, len) as the
    /// crum sees them, sorted by address.
    pub fn debug_live_descriptors(&mut self) -> Vec<(Vec<i64>, (u64, u64), usize)> {
        self.doc.rebuild_index();
        self.doc
            .live()
            .iter()
            .map(|u| {
                (
                    u.address.numbers().to_vec(),
                    u.dot,
                    u.content.chars().count(),
                )
            })
            .collect()
    }

    /// Memory telemetry: (units, tombstones, content bytes, live
    /// content bytes) — the shadow is a second copy of the document.
    pub fn memory_estimate(&self) -> (usize, usize, usize, usize) {
        self.doc.memory_estimate()
    }

    pub fn open_session(&mut self, author: u64) {
        self.dense(author);
        self.views.insert(author, self.doc.clone());
        self.counters.entry(author).or_insert(0);
    }

    /// Apply a delta computed against the session's view (timed for
    /// the dual-engine bench telemetry).
    pub fn apply(&mut self, author: u64, ops: &[LatOp]) {
        let t0 = std::time::Instant::now();
        self.apply_inner(author, ops);
        self.apply_ns += t0.elapsed().as_nanos();
    }

    /// FR-51 C-1: apply with provenance. Provenance stamps every
    /// unit created by this op's Insert actions. The provenance is
    /// IMMUTABLE once set — the lattice is append-only.
    pub fn apply_with_provenance(
        &mut self,
        author: u64,
        ops: &[LatOp],
        provenance: super::lattice::LatticeProvenance,
    ) {
        let t0 = std::time::Instant::now();
        self.pending_provenance = Some(provenance);
        self.apply_inner(author, ops);
        self.pending_provenance = None;
        self.apply_ns += t0.elapsed().as_nanos();
    }

    fn apply_inner(&mut self, author: u64, ops: &[LatOp]) {
        let mut view = match self.views.remove(&author) {
            Some(v) => v,
            // Unknown author: treat as a fresh session synced to the
            // shared state (server-path robustness — view materializes
            // on demand).
            None => {
                self.counters.entry(author).or_insert(0);
                self.doc.clone()
            }
        };
        let mut offset: u64 = 0;
        self.ops_applied += 1;
        for op in ops {
            match op {
                LatOp::Retain { count } => offset += count,
                LatOp::Insert { text } => {
                    let b = split_at(&mut view, offset);
                    // The shared doc may hold an unsplit straddling
                    // part (the view split its own copy): refine it
                    // so the anchored insert orders correctly.
                    if let Some((rd, o)) = b.anchor {
                        self.doc.ensure_root_boundary(rd, o);
                    }
                    let dense = self.dense(author);
                    let ns = self.namespace;
                    let counter = self.counters.get_mut(&author).unwrap();
                    *counter += 1;
                    let dot = if ns == 0 {
                        (dense, *counter)
                    } else {
                        (ns * 1_000_000_000 + dense, *counter)
                    };
                    let (prev, next) = b.prev_next();
                    self.doc.insert_at_with_dot_and_prov(
                        prev.cloned().as_ref(),
                        next.cloned().as_ref(),
                        text.clone(),
                        author,
                        b.anchor,
                        dot,
                        self.pending_provenance.clone(),
                    );
                    view.insert_at_with_dot(prev, next, text.clone(), author, b.anchor, dot);
                    offset += text.chars().count() as u64;
                }
                LatOp::Delete { count } => {
                    // End boundary first (mirrors apply_delta).
                    let end = split_at(&mut view, offset + count);
                    if let Some((d, at)) = end.split {
                        self.mirror_split(d, at);
                    }
                    let start = split_at(&mut view, offset);
                    if let Some((d, at)) = start.split {
                        self.mirror_split(d, at);
                    }
                    match (start.next.clone(), end.next.clone()) {
                        (Some(a), Some(b)) => {
                            let seen = view.live_dots_between(&a, &b);
                            self.doc.delete_seen_range(&a, &b, &seen);
                            view.delete_range_public(&a, &b);
                        }
                        (Some(a), None) => {
                            let mut seen = Vec::new();
                            let mut above = view.live_dots_above(&a);
                            seen.append(&mut above);
                            self.doc.delete_seen_range(
                                &a,
                                &Sequence::from_numbers(vec![i64::MAX - 1]),
                                &seen,
                            );
                            view.delete_to_end(&a);
                        }
                        _ => {}
                    }
                }
            }
        }
        self.views.insert(author, view);
    }

    fn mirror_split(&mut self, dot: Dot, at: usize) {
        if self.doc.is_live(dot) {
            self.doc.split_unit(dot, at);
        }
    }

    /// Deliver the shared state to a session's view.
    pub fn sync(&mut self, author: u64) {
        if let Some(v) = self.views.get_mut(&author) {
            *v = self.doc.clone();
        }
    }

    /// The shared document's rendered text.
    pub fn text(&mut self) -> String {
        self.doc.render()
    }

    /// A session's current view text (what its next delta positions
    /// against).
    pub fn view_text(&mut self, author: u64) -> String {
        match self.views.get_mut(&author) {
            Some(v) => v.render(),
            None => String::new(),
        }
    }
}

#[cfg(test)]
mod c1_provenance_tests {
    use super::*;

    fn prov(name: &str, club: u64) -> super::super::lattice::LatticeProvenance {
        super::super::lattice::LatticeProvenance {
            author_public_key: [7u8; 32],
            author_display_name: name.to_string(),
            author_club_id: club,
            timestamp: 1000,
            author_type: crate::edition::provenance::AuthorType::Human,
            llm_model: None,
            signature: None,
        }
    }

    /// C-1 armor: provenance stamped at insert survives read-back
    /// and is immutable (concurrent merges don't overwrite it).
    #[test]
    fn c1_provenance_survives_insert_and_merge() {
        let mut a = MultiWriter::with_namespace("base text for provenance test", 1);
        a.open_session(1);
        let p = prov("alice", 42);
        a.apply_with_provenance(
            1,
            &[
                LatOp::Retain { count: 5 },
                LatOp::Insert {
                    text: "HELLO".into(),
                },
            ],
            p.clone(),
        );

        // Read back: every unit containing "HELLO" has the provenance.
        let text = a.text();
        assert!(text.contains("HELLO"));
        let doc = a.debug_doc_clone();
        let provenance_count = doc.live().iter().filter(|u| u.provenance.is_some()).count();
        assert!(provenance_count > 0, "at least one unit carries provenance");

        // Every provenance-carrying unit has the right author.
        for u in doc.live() {
            if let Some(p) = &u.provenance {
                assert_eq!(p.author_display_name, "alice");
                assert_eq!(p.author_club_id, 42);
            }
        }

        // Doc-level pull: provenance rides with the unit (C-1 core).
        let mut b = LatticeDoc::new(99);
        b.seed_shared_unit(
            crate::space::sequence::Sequence::from_numbers(vec![1, 9, 1]),
            "base text for provenance test",
            9,
            (9, 1),
        );
        let prov_dots: Vec<_> = a
            .debug_doc_clone()
            .live()
            .iter()
            .filter(|u| u.provenance.is_some())
            .map(|u| u.dot)
            .collect();
        assert!(!prov_dots.is_empty());
        b.pull_from(&a.debug_doc_clone(), &prov_dots);
        let bdoc = b;
        let merged_prov = bdoc
            .live()
            .iter()
            .filter(|u| u.provenance.is_some())
            .count();
        assert_eq!(
            provenance_count, merged_prov,
            "provenance count survives the pull"
        );
    }

    /// C-1 armor: unsigned edits (plain apply) carry no provenance.
    #[test]
    fn c1_unsigned_edits_have_no_provenance() {
        let mut a = MultiWriter::with_namespace("plain base", 1);
        a.open_session(1);
        a.apply(
            1,
            &[
                LatOp::Retain { count: 5 },
                LatOp::Insert { text: "X".into() },
            ],
        );
        let doc = a.debug_doc_clone();
        let count = doc.live().iter().filter(|u| u.provenance.is_some()).count();
        assert_eq!(count, 0, "plain apply does not stamp provenance");
    }

    /// C-1 armor: the signing payload is deterministic.
    #[test]
    fn c1_signing_payload_deterministic() {
        let addr = crate::space::sequence::Sequence::from_numbers(vec![1, 2, 3]);
        let a = super::super::lattice::LatticeProvenance::signing_payload("hello", &addr);
        let b = super::super::lattice::LatticeProvenance::signing_payload("hello", &addr);
        assert_eq!(a, b, "same content + address = same payload");
        let c = super::super::lattice::LatticeProvenance::signing_payload("world", &addr);
        assert_ne!(a, c, "different content = different payload");
    }
}
