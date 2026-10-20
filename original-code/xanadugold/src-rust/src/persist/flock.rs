// Pure flock metadata types — no fs. Shared by the storage-engine
// trait surface (engine builds) and the fs-backed implementation
// (server). Extracted verbatim from persistent.rs.
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
            flags: FlockFlags::IS_NEW
                | FlockFlags::CONTENTS_DIRTY
                | FlockFlags::FORGOTTEN_STATE_DIRTY,
            old_size: 0,
        }
    }

    pub fn on_disk(flock_id: FlockId, location: FlockLocation, forgotten: bool) -> Self {
        FlockInfo {
            flock_id,
            location: Some(location),
            flags: if forgotten {
                FlockFlags::FORGOTTEN
            } else {
                FlockFlags::empty()
            },
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
        self.flags
            .insert(FlockFlags::FORGOTTEN | FlockFlags::FORGOTTEN_STATE_DIRTY);
    }

    pub fn mark_remembered(&mut self) {
        self.flags.remove(FlockFlags::FORGOTTEN);
        self.flags.insert(FlockFlags::FORGOTTEN_STATE_DIRTY);
    }

    pub fn mark_destroyed(&mut self) {
        self.flags
            .insert(FlockFlags::DESTROYED | FlockFlags::FORGOTTEN);
    }

    pub fn commit_flags(&mut self) {
        self.flags.remove(
            FlockFlags::IS_NEW | FlockFlags::CONTENTS_DIRTY | FlockFlags::FORGOTTEN_STATE_DIRTY,
        );
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
        } else if self.flags.contains(FlockFlags::CONTENTS_DIRTY)
            || self.flags.contains(FlockFlags::IS_NEW)
        {
            FlockState::Dirty
        } else {
            FlockState::Clean
        }
    }
}
