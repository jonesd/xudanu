//! FR-34/FR-51: crum anti-entropy — the wire-agnostic sync
//! protocol between lattice replicas. The transport (FederationFrame
//! over the peer mesh) adopts this module; the semantics are proven
//! here in-process:
//!
//! 1. Exchange canonical root crums (tiny). Equal -> done: no
//!    payload moves. This makes idle/idempotent rounds free.
//! 2. On mismatch: both directions compute crum diffs; each side
//!    sends ONLY the units the other lacks, plus tombstones (the
//!    delete intent — small, and required for cull correctness).
//! 3. Apply (targeted union), re-exchange crums; repeat to a bound.
//!
//! Payload proportionality (the federation claim): a small edit on a
//! large document moves a small payload — measured by `bytes` in
//! AntiEntropyStats, asserted by armor.

use super::lattice::Dot;
use super::lattice_multi::MultiWriter;

/// Estimated on-wire size of one unit (content + address/dot/lineage
/// overhead) or tombstone (region + context + culls) — the honest
/// accounting basis for payload proportionality. Real serialization
/// (postcard) is a transport follow-up; the estimate is deliberately
/// conservative (over-counts small units).
pub const UNIT_OVERHEAD_BYTES: usize = 96;
pub const TOMBSTONE_OVERHEAD_BYTES: usize = 64;

#[derive(Debug, Default, Clone, Copy)]
pub struct AntiEntropyStats {
    /// Crum-exchange messages sent (2 per round: one each way).
    pub crum_messages: usize,
    /// Payload-bearing messages sent (0 when crums already matched).
    pub payload_messages: usize,
    /// Estimated payload bytes moved both directions combined.
    pub bytes: usize,
    /// Protocol rounds executed.
    pub rounds: usize,
    /// True when the replicas converged within the round bound.
    pub converged: bool,
}

fn doc_bytes(mw: &MultiWriter, dots: &[Dot]) -> usize {
    mw.units_bytes_for(dots)
}

/// Run crum anti-entropy between two replicas until their canonical
/// crums match (or MAX_ROUNDS). Returns the traffic accounting.
pub fn crum_anti_entropy(a: &mut MultiWriter, b: &mut MultiWriter) -> AntiEntropyStats {
    const MAX_ROUNDS: usize = 4;
    let mut stats = AntiEntropyStats::default();
    for _ in 0..MAX_ROUNDS {
        stats.rounds += 1;
        stats.crum_messages += 2;
        let ca = a.shared_crum();
        let cb = b.shared_crum();
        if ca.is_some() && ca == cb {
            stats.converged = true;
            return stats;
        }
        // Both directions diff; each pulls exactly what it lacks.
        let d1 = b.diff_against(a);
        let d2 = a.diff_against(b);
        let bytes_ab = doc_bytes(a, &d1);
        let bytes_ba = doc_bytes(b, &d2);
        b.pull_units_from(a, &d1);
        a.pull_units_from(b, &d2);
        stats.payload_messages += 2;
        stats.bytes += bytes_ab + bytes_ba;
    }
    // Final verification round.
    stats.crum_messages += 2;
    stats.converged = a.shared_crum().is_some() && a.shared_crum() == b.shared_crum();
    stats
}

#[cfg(test)]
mod tests {
    use super::super::lattice_sim::LatOp;
    use super::*;

    fn instance(ns: u64, base: &str) -> MultiWriter {
        MultiWriter::with_namespace(base, ns)
    }

    fn edit(mw: &mut MultiWriter, session: u64, at: u64, text: &str) {
        mw.apply(
            session,
            &[
                LatOp::Retain { count: at },
                LatOp::Insert { text: text.into() },
            ],
        );
    }

    #[test]
    fn idle_round_moves_nothing() {
        let mut a = instance(1, "same base text for both");
        let mut b = instance(2, "same base text for both");
        let stats = crum_anti_entropy(&mut a, &mut b);
        assert!(stats.converged);
        assert_eq!(
            stats.payload_messages, 0,
            "equal crums must move no payload"
        );
        assert_eq!(stats.bytes, 0);
        assert_eq!(stats.rounds, 1, "one idle round");
    }

    #[test]
    fn concurrent_edits_converge_both_directions() {
        let mut a = instance(1, "the quick brown fox jumps over the lazy dog");
        let mut b = instance(2, "the quick brown fox jumps over the lazy dog");
        a.open_session(1);
        b.open_session(2);
        for k in 0..8u64 {
            edit(&mut a, 1, 5 + k, "A");
            edit(&mut b, 2, 30 + k, "B");
        }
        let stats = crum_anti_entropy(&mut a, &mut b);
        assert!(stats.converged, "replicas must converge");
        assert_eq!(a.text(), b.text());
        let text = a.text();
        assert_eq!(text.matches('A').count(), 8);
        assert_eq!(text.matches('B').count(), 8);
    }

    #[test]
    fn payload_proportional_to_difference() {
        // A large shared document (many units after fragmentation),
        // then ONE small edit on one replica: the moved payload must
        // be a small fraction of the full state.
        let base = "0123456789abcdef".repeat(12000); // ~192k chars
        let mut a = instance(1, &base);
        let mut b = instance(2, &base);
        // Fragment into units so the state is substantial.
        a.open_session(1);
        for k in 0..200u64 {
            edit(&mut a, 1, k * 900, "|");
        }
        b.import_state_from(&a);
        // One small edit on b.
        b.open_session(2);
        edit(&mut b, 2, 100_000, "X");
        let full = a.full_state_bytes();
        let stats = crum_anti_entropy(&mut a, &mut b);
        assert!(stats.converged);
        assert!(
            stats.bytes < full / 10,
            "payload {} must be < 10% of full state {} (proportionality)",
            stats.bytes,
            full
        );
    }

    #[test]
    fn repeated_round_after_convergence_is_free() {
        let mut a = instance(1, "some shared document");
        let mut b = instance(2, "some shared document");
        a.open_session(1);
        edit(&mut a, 1, 5, "X");
        let s1 = crum_anti_entropy(&mut a, &mut b);
        assert!(s1.converged);
        assert!(s1.bytes > 0, "first round moved the edit");
        let s2 = crum_anti_entropy(&mut a, &mut b);
        assert!(s2.converged);
        assert_eq!(s2.bytes, 0, "second round must be free");
        assert_eq!(s2.payload_messages, 0);
    }
}
