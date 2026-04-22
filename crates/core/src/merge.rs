use xanadu_types::*;

use crate::sequence::Sequence;
use crate::state_vector::StateVector;

#[derive(Debug, Clone)]
pub struct MergeResult {
    pub changes_applied: usize,
    pub conflicts_resolved: usize,
}

pub fn merge_local_into(target: &mut Sequence, source: &Sequence) -> MergeResult {
    let source_sv = source.state_vector();
    let target_sv = target.state_vector().clone();

    let applied = 0;
    let mut conflicts = 0;

    for (site, &clock) in source_sv.iter() {
        let target_clock = target_sv.get(site);
        if clock > target_clock {
            conflicts += 1;
        }
    }

    MergeResult {
        changes_applied: applied,
        conflicts_resolved: conflicts,
    }
}

pub fn compute_missing_changes(
    local: &StateVector,
    remote: &StateVector,
) -> Vec<(SiteId, u64, u64)> {
    let mut missing = Vec::new();

    for (site, &remote_clock) in remote.iter() {
        let local_clock = local.get(site);
        if remote_clock > local_clock {
            missing.push((*site, local_clock + 1, remote_clock));
        }
    }

    missing
}
