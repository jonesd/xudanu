use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct HybridTimestamp {
    pub lamport: u64,
    pub wall_secs: u64,
    pub wall_nanos: u32,
}

impl HybridTimestamp {
    pub fn now(lamport: u64) -> Self {
        use std::time::{SystemTime, UNIX_EPOCH};
        let duration = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default();
        Self {
            lamport,
            wall_secs: duration.as_secs(),
            wall_nanos: duration.subsec_nanos(),
        }
    }

    pub fn merge(&self, other: &HybridTimestamp) -> HybridTimestamp {
        Self {
            lamport: self.lamport.max(other.lamport) + 1,
            wall_secs: self.wall_secs.max(other.wall_secs),
            wall_nanos: self.wall_nanos,
        }
    }
}

impl Ord for HybridTimestamp {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        self.lamport
            .cmp(&other.lamport)
            .then_with(|| self.wall_secs.cmp(&other.wall_secs))
            .then_with(|| self.wall_nanos.cmp(&other.wall_nanos))
    }
}

impl PartialOrd for HybridTimestamp {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}
