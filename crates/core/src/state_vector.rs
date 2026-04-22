use std::collections::BTreeMap;

use xudanu_types::SiteId;

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct StateVector(BTreeMap<SiteId, u64>);

impl StateVector {
    pub fn new() -> Self {
        Self(BTreeMap::new())
    }

    pub fn get(&self, site: &SiteId) -> u64 {
        self.0.get(site).copied().unwrap_or(0)
    }

    pub fn set(&mut self, site: SiteId, clock: u64) {
        self.0.insert(site, clock);
    }

    pub fn increment(&mut self, site: SiteId) -> u64 {
        let clock = self.get(&site) + 1;
        self.0.insert(site, clock);
        clock
    }

    pub fn merge(&mut self, other: &StateVector) {
        for (site, clock) in &other.0 {
            let current = self.get(site);
            if *clock > current {
                self.0.insert(*site, *clock);
            }
        }
    }

    pub fn knows(&self, site: &SiteId, clock: u64) -> bool {
        self.get(site) >= clock
    }

    pub fn dominates(&self, other: &StateVector) -> bool {
        for (site, clock) in &other.0 {
            if self.get(site) < *clock {
                return false;
            }
        }
        true
    }

    pub fn sites(&self) -> impl Iterator<Item = &SiteId> {
        self.0.keys()
    }

    pub fn iter(&self) -> impl Iterator<Item = (&SiteId, &u64)> {
        self.0.iter()
    }
}

use serde::{Deserialize, Serialize};
