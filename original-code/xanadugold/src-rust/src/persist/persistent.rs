use std::fmt;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Ord, PartialOrd)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct FlockId {
    pub hash: u64,
    pub token: u32,
}

impl FlockId {
    pub fn new(hash: u64, token: u32) -> Self {
        FlockId { hash, token }
    }
}

impl fmt::Display for FlockId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "FlockId({}:{})", self.hash, self.token)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FlockState {
    New,
    Clean,
    Dirty,
    Forgotten,
    Destroyed,
}

#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct FlockLocation {
    pub snarf_id: u32,
    pub index: u32,
}

impl FlockLocation {
    pub fn new(snarf_id: u32, index: u32) -> Self {
        FlockLocation { snarf_id, index }
    }
}

bitflags::bitflags! {
    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
    pub struct FlockFlags: u32 {
        const IS_NEW = 1;
        const CONTENTS_DIRTY = 1 << 1;
        const FORGOTTEN_STATE_DIRTY = 1 << 2;
        const FORGOTTEN = 1 << 3;
        const DESTROYED = 1 << 4;
        const FORWARDED = 1 << 5;
    }
}

#[derive(Debug, Clone)]
pub struct FlockInfo {
    pub flock_id: FlockId,
    pub location: Option<FlockLocation>,
    pub flags: FlockFlags,
    pub old_size: u32,
}

impl FlockInfo {
    pub fn new(flock_id: FlockId) -> Self {
        FlockInfo {
            flock_id,
            location: None,
            flags: FlockFlags::IS_NEW | FlockFlags::CONTENTS_DIRTY | FlockFlags::FORGOTTEN_STATE_DIRTY,
            old_size: 0,
        }
    }

    pub fn on_disk(flock_id: FlockId, location: FlockLocation, forgotten: bool) -> Self {
        FlockInfo {
            flock_id,
            location: Some(location),
            flags: if forgotten { FlockFlags::FORGOTTEN } else { FlockFlags::empty() },
            old_size: 0,
        }
    }

    pub fn is_new(&self) -> bool {
        self.flags.contains(FlockFlags::IS_NEW)
    }

    pub fn is_dirty(&self) -> bool {
        self.flags.contains(FlockFlags::CONTENTS_DIRTY)
    }

    pub fn is_forgotten(&self) -> bool {
        self.flags.contains(FlockFlags::FORGOTTEN)
    }

    pub fn is_destroyed(&self) -> bool {
        self.flags.contains(FlockFlags::DESTROYED)
    }

    pub fn is_forwarded(&self) -> bool {
        self.flags.contains(FlockFlags::FORWARDED)
    }

    pub fn mark_dirty(&mut self) -> bool {
        let was_clean = !self.flags.contains(FlockFlags::CONTENTS_DIRTY);
        self.flags.insert(FlockFlags::CONTENTS_DIRTY);
        was_clean
    }

    pub fn mark_forgotten(&mut self) {
        self.flags.insert(FlockFlags::FORGOTTEN | FlockFlags::FORGOTTEN_STATE_DIRTY);
    }

    pub fn mark_remembered(&mut self) {
        self.flags.remove(FlockFlags::FORGOTTEN);
        self.flags.insert(FlockFlags::FORGOTTEN_STATE_DIRTY);
    }

    pub fn mark_destroyed(&mut self) {
        self.flags.insert(FlockFlags::DESTROYED | FlockFlags::FORGOTTEN);
    }

    pub fn commit_flags(&mut self) {
        self.flags.remove(FlockFlags::IS_NEW | FlockFlags::CONTENTS_DIRTY | FlockFlags::FORGOTTEN_STATE_DIRTY);
    }

    pub fn forward_to(&mut self, new_location: FlockLocation) {
        self.location = Some(new_location);
        self.flags.insert(FlockFlags::FORWARDED);
    }

    pub fn state(&self) -> FlockState {
        if self.flags.contains(FlockFlags::DESTROYED) {
            FlockState::Destroyed
        } else if self.flags.contains(FlockFlags::FORGOTTEN) {
            FlockState::Forgotten
        } else if self.flags.contains(FlockFlags::CONTENTS_DIRTY) || self.flags.contains(FlockFlags::IS_NEW) {
            FlockState::Dirty
        } else {
            FlockState::Clean
        }
    }
}

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
