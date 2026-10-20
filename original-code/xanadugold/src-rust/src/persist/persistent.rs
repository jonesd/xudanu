// Derived from Udanax Gold (Xanadu 92.1), released 1999 under the MIT/X11
// license — see NOTICE and THIRD_PARTY_LICENSES/udanax_gold.txt.
pub use super::flock::{FlockFlags, FlockId, FlockInfo, FlockLocation, FlockState};
use std::fmt;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn flock_id_equality() {
        let a = FlockId::new(42, 1);
        let b = FlockId::new(42, 1);
        let c = FlockId::new(43, 1);
        assert_eq!(a, b);
        assert_ne!(a, c);
    }

    #[test]
    fn flock_id_hashable() {
        use std::collections::HashSet;
        let mut set = HashSet::new();
        set.insert(FlockId::new(1, 0));
        set.insert(FlockId::new(1, 0));
        set.insert(FlockId::new(2, 0));
        assert_eq!(set.len(), 2);
    }

    #[test]
    fn flock_info_new_state() {
        let id = FlockId::new(1, 0);
        let info = FlockInfo::new(id);
        assert!(info.is_new());
        assert!(info.is_dirty());
        assert!(!info.is_forgotten());
        assert!(!info.is_destroyed());
        assert!(info.location.is_none());
        assert_eq!(info.state(), FlockState::Dirty);
    }

    #[test]
    fn flock_info_on_disk_remembered() {
        let id = FlockId::new(10, 5);
        let loc = FlockLocation::new(3, 7);
        let info = FlockInfo::on_disk(id, loc.clone(), false);
        assert!(!info.is_new());
        assert!(!info.is_dirty());
        assert!(!info.is_forgotten());
        assert_eq!(info.location, Some(loc));
        assert_eq!(info.state(), FlockState::Clean);
    }

    #[test]
    fn flock_info_on_disk_forgotten() {
        let id = FlockId::new(10, 5);
        let loc = FlockLocation::new(3, 7);
        let info = FlockInfo::on_disk(id, loc, true);
        assert!(info.is_forgotten());
        assert_eq!(info.state(), FlockState::Forgotten);
    }

    #[test]
    fn flock_info_mark_dirty_from_clean() {
        let id = FlockId::new(1, 0);
        let loc = FlockLocation::new(0, 0);
        let mut info = FlockInfo::on_disk(id, loc, false);
        assert_eq!(info.state(), FlockState::Clean);
        let was_clean = info.mark_dirty();
        assert!(was_clean);
        assert!(info.is_dirty());
        assert_eq!(info.state(), FlockState::Dirty);
    }

    #[test]
    fn flock_info_mark_dirty_idempotent() {
        let id = FlockId::new(1, 0);
        let mut info = FlockInfo::new(id);
        let was_clean = info.mark_dirty();
        assert!(!was_clean);
    }

    #[test]
    fn flock_info_remember_forget_cycle() {
        let id = FlockId::new(1, 0);
        let loc = FlockLocation::new(0, 0);
        let mut info = FlockInfo::on_disk(id, loc, false);
        assert!(!info.is_forgotten());
        info.mark_forgotten();
        assert!(info.is_forgotten());
        info.mark_remembered();
        assert!(!info.is_forgotten());
    }

    #[test]
    fn flock_info_destroy_implies_forgotten() {
        let id = FlockId::new(1, 0);
        let mut info = FlockInfo::new(id);
        info.mark_destroyed();
        assert!(info.is_destroyed());
        assert!(info.is_forgotten());
        assert_eq!(info.state(), FlockState::Destroyed);
    }

    #[test]
    fn flock_info_commit_flags_clears_dirty() {
        let id = FlockId::new(1, 0);
        let mut info = FlockInfo::new(id);
        assert!(info.is_new());
        assert!(info.is_dirty());
        info.commit_flags();
        assert!(!info.is_new());
        assert!(!info.is_dirty());
        assert!(!info.is_forgotten());
    }

    #[test]
    fn flock_info_forward() {
        let id = FlockId::new(1, 0);
        let loc1 = FlockLocation::new(0, 0);
        let mut info = FlockInfo::on_disk(id, loc1, false);
        let loc2 = FlockLocation::new(5, 10);
        info.forward_to(loc2.clone());
        assert!(info.is_forwarded());
        assert_eq!(info.location, Some(loc2));
    }

    #[test]
    fn flock_state_ordering() {
        let id = FlockId::new(1, 0);
        let mut info = FlockInfo::new(id);
        assert_eq!(info.state(), FlockState::Dirty);
        info.commit_flags();
        assert_eq!(info.state(), FlockState::Clean);
        info.mark_dirty();
        assert_eq!(info.state(), FlockState::Dirty);
        info.mark_forgotten();
        assert_eq!(info.state(), FlockState::Forgotten);
        info.mark_destroyed();
        assert_eq!(info.state(), FlockState::Destroyed);
    }

    #[test]
    fn flock_location_new() {
        let loc = FlockLocation::new(3, 7);
        assert_eq!(loc.snarf_id, 3);
        assert_eq!(loc.index, 7);
    }
}
