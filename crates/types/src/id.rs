use serde::{Deserialize, Serialize};

use crate::author::SiteId;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, PartialOrd, Ord)]
pub struct ItemId {
    pub site: SiteId,
    pub clock: u64,
}

impl ItemId {
    pub fn new(site: SiteId, clock: u64) -> Self {
        Self { site, clock }
    }

    pub fn sentinel_start(site: SiteId) -> Self {
        Self { site, clock: 0 }
    }

    pub fn is_sentinel(&self) -> bool {
        self.clock == 0
    }
}

impl std::fmt::Display for ItemId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}:{}", self.site.short(), self.clock)
    }
}
