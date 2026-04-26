use crate::ent::dagwood::DagWood;
use crate::ent::trace::TracePosition;

// [Original] Ent has "NO CLASS COMMENT" in the source (entx.hxx:84).
//
// [Adapted from Original] Field mapping from Ent (entx.hxx):
//   fulltrace → fulltrace (DagWood)
//
// The original also had:
//   DESIGN_FLUID(TracePosition, CurrentTrace)  — deferred to Phase 4 (context)
//   DESIGN_FLUID(BertCrum, CurrentBertCrum)    — deferred to Phase 5 (canopy)
//
// [New Migration Comment] Ent is a thin wrapper that owns a DagWood and
// delegates new_trace() to new_position(). No persistence (newShepherd,
// remember) in this phase.
pub struct Ent {
    pub(crate) fulltrace: DagWood,
}

impl Ent {
    // [Adapted from Original] Ent::Ent()
    // Source: entx.cxx lines 96-101
    //
    // Original:
    //   CONSTRUCT(fulltrace, DagWood, ());
    //   this->newShepherd();
    //   this->remember();
    pub fn new() -> Self {
        Ent {
            fulltrace: DagWood::new(),
        }
    }

    // [Adapted from Original] Ent::newTrace()
    // Source: entx.cxx lines 88-92
    pub fn new_trace(&mut self) -> TracePosition {
        self.fulltrace.new_position()
    }

    pub fn root(&self) -> TracePosition {
        self.fulltrace.root()
    }

    // [Adapted from Original] Ent::tableSegmentMaxSize()
    // Source: entx.ixx lines 40-46
    //
    // [Original] "When we are making an orgl out of a table, we break the
    // table up into pieces which should be no larger than this, so that they
    // each fit into a snarf."
    pub const fn table_segment_max_size() -> u32 {
        16384
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // E1: ent_new_trace_returns_position_3
    #[test]
    fn ent_new_trace_returns_position_3() {
        let mut ent = Ent::new();
        let trace = ent.new_trace();
        assert_eq!(trace.position(), 3);
    }

    // E2: ent_new_trace_returns_distinct_branches
    #[test]
    fn ent_new_trace_returns_distinct_branches() {
        let mut ent = Ent::new();
        let t1 = ent.new_trace();
        let t2 = ent.new_trace();
        let t3 = ent.new_trace();

        assert_eq!(t1.position(), 3);
        assert_eq!(t2.position(), 3);
        assert_eq!(t3.position(), 3);

        assert_ne!(t1.branch(), t2.branch());
        assert_ne!(t2.branch(), t3.branch());
        assert_ne!(t1.branch(), t3.branch());
    }

    // E3: ent_table_segment_max_size
    #[test]
    fn ent_table_segment_max_size() {
        assert_eq!(Ent::table_segment_max_size(), 16384);
    }
}
