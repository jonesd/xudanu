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
    doc: LatticeDoc,
    views: std::collections::HashMap<u64, LatticeDoc>,
    counters: std::collections::HashMap<u64, u64>,
    /// Session ids are opaque (often random u64s); dots and address
    /// ordering need small dense author ids — assigned in join order.
    authors: std::collections::HashMap<u64, u64>,
    next_author: u64,
    ops_applied: usize,
}

impl MultiWriter {
    pub fn new(base: &str) -> Self {
        let mut doc = LatticeDoc::new(0);
        doc.seed_shared_unit(Sequence::from_numbers(vec![1, 9, 1]), base, 9, (9, 1));
        MultiWriter {
            doc,
            views: std::collections::HashMap::new(),
            counters: std::collections::HashMap::new(),
            authors: std::collections::HashMap::new(),
            next_author: 0,
            ops_applied: 0,
        }
    }

    /// Dense author id for a session (join order).
    fn dense(&mut self, session: u64) -> u64 {
        if let Some(d) = self.authors.get(&session) {
            return *d;
        }
        self.next_author += 1;
        let d = self.next_author;
        self.authors.insert(session, d);
        d
    }

    /// Debug: the shared doc's in-order (address numbers, dot, len).
    pub fn debug_state(&mut self) -> Vec<(Vec<i64>, Dot, usize)> {
        self.doc.debug_index()
    }

    /// Deltas applied since construction (shadow telemetry).
    pub fn ops_applied(&self) -> usize {
        self.ops_applied
    }

    pub fn open_session(&mut self, author: u64) {
        self.dense(author);
        self.views.insert(author, self.doc.clone());
        self.counters.entry(author).or_insert(0);
    }

    /// Apply a delta computed against the session's view.
    pub fn apply(&mut self, author: u64, ops: &[LatOp]) {
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
                    let counter = self.counters.get_mut(&author).unwrap();
                    *counter += 1;
                    let dot = (dense, *counter);
                    let (prev, next) = b.prev_next();
                    self.doc.insert_at_with_dot(
                        prev.cloned().as_ref(),
                        next.cloned().as_ref(),
                        text.clone(),
                        author,
                        b.anchor,
                        dot,
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
