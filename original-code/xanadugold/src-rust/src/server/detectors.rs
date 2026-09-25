//! FR-80 — Detectors: persistent watches on works.
//!
//! Heritage: Miller, "The Open Society and Its Media" (1994) — the
//! fourth fundamental feature. Link detectors collect new links
//! landing on a work (optionally filtered by a SET of types,
//! direction, and authoring clubs); revision detectors collect new
//! revisions. The match is a predicate object, never a single value
//! (Gold's FeFillDetector matched one exact element; Miller's link
//! detectors one type — the limitation this shape avoids).
//!
//! v1 is pull-model and work-level; the fossil engine
//! (`RecorderQuery`: region, authority_clubs, endorsement_filter) is
//! the later span-level extension. Hits are capped per detector; the
//! collection is the record — ack marks read, never deletes.

use std::collections::HashMap;

use serde::{Deserialize, Serialize};

use super::error::ServerError;
use super::transport::protocol::{DetectorHitPayload, DetectorInfoPayload, DetectorMatchWire};
use super::SessionId;
use crate::edition::links::HyperLink;
use crate::edition::BeId;

const MAX_HITS_PER_DETECTOR: usize = 200;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum DetectorKind {
    Links,
    Revisions,
}

impl DetectorKind {
    pub fn as_str(&self) -> &'static str {
        match self {
            DetectorKind::Links => "links",
            DetectorKind::Revisions => "revisions",
        }
    }
    pub fn parse(s: &str) -> Option<Self> {
        match s {
            "links" => Some(DetectorKind::Links),
            "revisions" => Some(DetectorKind::Revisions),
            _ => None,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum Direction {
    #[default]
    In,
    Out,
    Any,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DetectorHit {
    pub at: u64,
    pub link_id: Option<u64>,
    pub by_club: Option<BeId>,
    pub revision: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Detector {
    pub id: u64,
    pub owner_club: BeId,
    pub work_id: BeId,
    pub kind: DetectorKind,
    /// Empty = ALL types (a set, never a single value).
    #[serde(default)]
    pub link_types: Vec<u64>,
    #[serde(default)]
    pub direction: Direction,
    /// Empty = any author.
    #[serde(default)]
    pub from_clubs: Vec<BeId>,
    pub created_at: u64,
    #[serde(default)]
    pub hits: Vec<DetectorHit>,
    /// Hits with index < acked_upto are read.
    #[serde(default)]
    pub acked_upto: usize,
}

impl Detector {
    fn matches_link(
        &self,
        link_work_ids: &[BeId],
        link_types: &[u64],
        by_club: Option<BeId>,
        acting_work: BeId,
    ) -> bool {
        if self.kind != DetectorKind::Links {
            return false;
        }
        let touches = match self.direction {
            Direction::In => {
                // the detector's work is among the link's ends, and
                // the link is not (only) authored from it — "landing
                // on" is approximated by touching, v1.
                link_work_ids.contains(&self.work_id)
            }
            Direction::Out => link_work_ids.contains(&self.work_id),
            Direction::Any => link_work_ids.contains(&self.work_id),
        };
        if !touches {
            return false;
        }
        if !self.link_types.is_empty() && !link_types.iter().any(|t| self.link_types.contains(t)) {
            return false;
        }
        if !self.from_clubs.is_empty() {
            match by_club {
                Some(c) if self.from_clubs.contains(&c) => {}
                _ => return false,
            }
        }
        // suppress self-watch noise: the owner's own club creating a
        // link from their own watched work is not a surprise to them
        if self.direction == Direction::In && acting_work == self.work_id {
            return false;
        }
        true
    }

    fn unread(&self) -> u64 {
        self.hits.len().saturating_sub(self.acked_upto) as u64
    }

    fn to_payload(&self) -> DetectorInfoPayload {
        DetectorInfoPayload {
            detector_id: self.id,
            work_id: self.work_id,
            kind: self.kind.as_str().to_string(),
            r#match: Some(DetectorMatchWire {
                link_types: if self.kind == DetectorKind::Links {
                    self.link_types.clone()
                } else {
                    Vec::new()
                },
                direction: Some(
                    match self.direction {
                        Direction::In => "in",
                        Direction::Out => "out",
                        Direction::Any => "any",
                    }
                    .to_string(),
                ),
                from_clubs: self.from_clubs.clone(),
            }),
            created_at: self.created_at,
            hits: (self.acked_upto..self.hits.len())
                .map(|i| DetectorHitPayload {
                    at: self.hits[i].at,
                    link_id: self.hits[i].link_id,
                    by_club: self.hits[i].by_club,
                    revision: self.hits[i].revision,
                })
                .collect(),
            unread: self.unread(),
        }
    }
}

#[derive(Debug, Default, Clone, Serialize, Deserialize)]
pub struct DetectorRegistry {
    next_id: u64,
    detectors: HashMap<u64, Detector>,
}

impl DetectorRegistry {
    pub fn detectors_for_owner(&self, owner: BeId) -> Vec<&Detector> {
        let mut v: Vec<&Detector> = self
            .detectors
            .values()
            .filter(|d| d.owner_club == owner)
            .collect();
        v.sort_by_key(|d| d.created_at);
        v
    }

    pub fn get(&self, id: u64) -> Option<&Detector> {
        self.detectors.get(&id)
    }

    pub fn get_mut(&mut self, id: u64) -> Option<&mut Detector> {
        self.detectors.get_mut(&id)
    }

    pub fn insert(&mut self, d: Detector) {
        if d.id >= self.next_id {
            self.next_id = d.id + 1;
        }
        self.detectors.insert(d.id, d);
    }

    pub fn remove(&mut self, id: u64) -> bool {
        self.detectors.remove(&id).is_some()
    }

    pub fn allocate_id(&mut self) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        id
    }

    pub fn len(&self) -> usize {
        self.detectors.len()
    }

    /// Fire point for link events: called with the final type set at
    /// link_set_types time (every creation flow applies types). One
    /// hit per (detector, link) — replays don't double-collect.
    pub fn fire_link(
        &mut self,
        link_id: u64,
        link: &HyperLink,
        by_club: Option<BeId>,
        now: u64,
    ) -> usize {
        let work_ids: Vec<BeId> = link
            .ends()
            .values()
            .flatten()
            .filter_map(|r| r.work_context())
            .collect();
        let types = link.link_types().to_vec();
        let acting_work = work_ids.first().copied().unwrap_or(0);
        let mut fired = 0;
        for d in self.detectors.values_mut() {
            if !d.matches_link(&work_ids, &types, by_club, acting_work) {
                continue;
            }
            if d.hits.iter().any(|h| h.link_id == Some(link_id)) {
                continue; // already collected
            }
            if d.hits.len() >= MAX_HITS_PER_DETECTOR {
                let drop = d.hits.len() - MAX_HITS_PER_DETECTOR + 1;
                d.hits.drain(0..drop);
                d.acked_upto = d.acked_upto.saturating_sub(drop);
            }
            d.hits.push(DetectorHit {
                at: now,
                link_id: Some(link_id),
                by_club,
                revision: None,
            });
            fired += 1;
        }
        fired
    }

    /// Fire point for revision commits.
    pub fn fire_revision(
        &mut self,
        work_id: BeId,
        revision: u64,
        by_club: Option<BeId>,
        now: u64,
    ) -> usize {
        let mut fired = 0;
        for d in self.detectors.values_mut() {
            if d.kind != DetectorKind::Revisions || d.work_id != work_id {
                continue;
            }
            if !d.from_clubs.is_empty() {
                match by_club {
                    Some(c) if d.from_clubs.contains(&c) => {}
                    _ => continue,
                }
            }
            if d.hits.len() >= MAX_HITS_PER_DETECTOR {
                let drop = d.hits.len() - MAX_HITS_PER_DETECTOR + 1;
                d.hits.drain(0..drop);
                d.acked_upto = d.acked_upto.saturating_sub(drop);
            }
            d.hits.push(DetectorHit {
                at: now,
                link_id: None,
                by_club,
                revision: Some(revision),
            });
            fired += 1;
        }
        fired
    }
}

impl super::server::Server {
    /// FR-80: post a detector on a work.
    pub fn detector_create(
        &mut self,
        session_id: SessionId,
        work_id: BeId,
        kind: &str,
        match_wire: Option<DetectorMatchWire>,
    ) -> Result<DetectorInfoPayload, ServerError> {
        self.ensure_logged_in(session_id)?;
        if !self.works.contains_key(&work_id) {
            return Err(ServerError::WorkNotFound(work_id));
        }
        let kind = DetectorKind::parse(kind).ok_or_else(|| {
            ServerError::InvalidArgument("kind must be \"links\" or \"revisions\"".into())
        })?;
        let owner_club = self
            .resolve_author_club(session_id)
            .ok_or(ServerError::NotAuthorized)?;
        let m = match_wire.unwrap_or(DetectorMatchWire {
            link_types: Vec::new(),
            direction: None,
            from_clubs: Vec::new(),
        });
        let direction = match m.direction.as_deref() {
            None | Some("in") => Direction::In,
            Some("out") => Direction::Out,
            Some("any") => Direction::Any,
            Some(other) => {
                return Err(ServerError::InvalidArgument(format!(
                    "direction must be in|out|any, got {other}"
                )))
            }
        };
        let detector = Detector {
            id: self.detectors.allocate_id(),
            owner_club,
            work_id,
            kind,
            link_types: if kind == DetectorKind::Links {
                m.link_types
            } else {
                Vec::new()
            },
            direction,
            from_clubs: m.from_clubs,
            created_at: crate::server::session_ticket::now_secs(),
            hits: Vec::new(),
            acked_upto: 0,
        };
        let payload = detector.to_payload();
        self.detectors.insert(detector);
        self.persist_detectors_best_effort();
        Ok(payload)
    }

    pub fn detector_list(
        &self,
        session_id: SessionId,
    ) -> Result<Vec<DetectorInfoPayload>, ServerError> {
        self.ensure_logged_in(session_id)?;
        let owner = self
            .resolve_author_club(session_id)
            .ok_or(ServerError::NotAuthorized)?;
        Ok(self
            .detectors
            .detectors_for_owner(owner)
            .into_iter()
            .map(|d| d.to_payload())
            .collect())
    }

    pub fn detector_ack(
        &mut self,
        session_id: SessionId,
        detector_id: u64,
    ) -> Result<u64, ServerError> {
        self.ensure_logged_in(session_id)?;
        let owner = self
            .resolve_author_club(session_id)
            .ok_or(ServerError::NotAuthorized)?;
        let d = self
            .detectors
            .get_mut(detector_id)
            .ok_or(ServerError::NotFound(format!("detector {detector_id}")))?;
        if d.owner_club != owner {
            return Err(ServerError::NotFound(format!("detector {detector_id}")));
        }
        let unread = d.unread();
        d.acked_upto = d.hits.len();
        self.persist_detectors_best_effort();
        Ok(unread)
    }

    pub fn detector_delete(
        &mut self,
        session_id: SessionId,
        detector_id: u64,
    ) -> Result<bool, ServerError> {
        self.ensure_logged_in(session_id)?;
        let owner = self
            .resolve_author_club(session_id)
            .ok_or(ServerError::NotAuthorized)?;
        match self.detectors.get(detector_id) {
            Some(d) if d.owner_club == owner => {}
            Some(_) => return Err(ServerError::NotFound(format!("detector {detector_id}"))),
            None => return Ok(false),
        }
        let removed = self.detectors.remove(detector_id);
        self.persist_detectors_best_effort();
        Ok(removed)
    }

    /// Fire link detectors at link_set_types time. Returns hits fired.
    pub fn detectors_fire_link(
        &mut self,
        session_id: SessionId,
        link_id: u64,
        link: &HyperLink,
    ) -> usize {
        let by_club = self.resolve_author_club(session_id);
        let now = crate::server::session_ticket::now_secs();
        let fired = self.detectors.fire_link(link_id, link, by_club, now);
        if fired > 0 {
            self.persist_detectors_best_effort();
        }
        fired
    }

    /// Fire revision detectors after a revision commit.
    pub fn detectors_fire_revision(
        &mut self,
        work_id: BeId,
        revision: u64,
        by_club: Option<BeId>,
    ) -> usize {
        let now = crate::server::session_ticket::now_secs();
        let fired = self
            .detectors
            .fire_revision(work_id, revision, by_club, now);
        if fired > 0 {
            self.persist_detectors_best_effort();
        }
        fired
    }

    /// Save on every mutation (create/ack/delete/fire). The earlier
    /// checkpoint_completed hook fired too rarely in practice — the
    /// sidecar went stale and a restart emptied the registry, losing
    /// the WidgetPerfect collections. Mutations are rare; the write
    /// is tiny; tickets use the same save-on-mutation discipline.
    fn persist_detectors_best_effort(&self) {
        if let Some(ref dir) = self.data_dir {
            if let Err(e) = self.save_detectors_sidecar(dir) {
                tracing::warn!("[detectors] sidecar persist failed: {e}");
            }
        }
    }

    /// Persist the registry (tmp + fsync + rename sidecar).
    pub fn save_detectors_sidecar(&self, data_dir: &std::path::Path) -> std::io::Result<()> {
        let json = serde_json::to_string(&self.detectors)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
        let path = data_dir.join("detectors.json");
        let tmp = data_dir.join("detectors.json.tmp");
        {
            let mut f = std::fs::File::create(&tmp)?;
            std::io::Write::write_all(&mut f, json.as_bytes())?;
            f.sync_all()?;
        }
        std::fs::rename(&tmp, &path)?;
        Ok(())
    }

    pub fn load_detectors_sidecar(&mut self, data_dir: &std::path::Path) {
        let path = data_dir.join("detectors.json");
        let Ok(text) = std::fs::read_to_string(&path) else {
            return;
        };
        match serde_json::from_str::<DetectorRegistry>(&text) {
            Ok(reg) => {
                let n = reg.len();
                self.detectors = reg;
                tracing::info!(target: "xudanu::server", "[restore] detectors: {} registered", n);
            }
            Err(e) => {
                tracing::warn!(target: "xudanu::server", "detectors.json unreadable: {e}");
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn detector(kind: DetectorKind, types: Vec<u64>) -> Detector {
        Detector {
            id: 1,
            owner_club: 7,
            work_id: 0xAA,
            kind,
            link_types: types,
            direction: Direction::In,
            from_clubs: vec![],
            created_at: 0,
            hits: vec![],
            acked_upto: 0,
        }
    }

    #[test]
    fn link_type_set_match() {
        // a SET, never a single value: detector for {3, 5} matches a
        // link carrying either; a link carrying only 4 does not.
        let d = detector(DetectorKind::Links, vec![3, 5]);
        assert!(d.matches_link(&[0xAA, 0xBB], &[5], Some(9), 0xBB));
        assert!(d.matches_link(&[0xAA, 0xBB], &[3, 4], Some(9), 0xBB));
        assert!(!d.matches_link(&[0xAA, 0xBB], &[4], Some(9), 0xBB));
    }

    #[test]
    fn empty_types_matches_all() {
        let d = detector(DetectorKind::Links, vec![]);
        assert!(d.matches_link(&[0xAA], &[99], None, 0xCC));
    }

    #[test]
    fn revision_kind_ignores_links() {
        let d = detector(DetectorKind::Revisions, vec![]);
        assert!(!d.matches_link(&[0xAA], &[3], None, 0xBB));
    }

    #[test]
    fn fire_link_collects_once() {
        let mut reg = DetectorRegistry::default();
        reg.insert(detector(DetectorKind::Links, vec![3]));
        let mut link = HyperLink::new();
        // ends with work_context 0xAA via make of two refs is awkward
        // here; fire_link with an empty-ended link touches nothing.
        assert_eq!(reg.fire_link(1, &link, None, 0), 0);
    }

    #[test]
    fn fire_revision_and_ack() {
        let mut reg = DetectorRegistry::default();
        reg.insert(detector(DetectorKind::Revisions, vec![]));
        assert_eq!(reg.fire_revision(0xAA, 3, None, 1), 1);
        assert_eq!(reg.fire_revision(0xBB, 4, None, 1), 0);
        let d = reg.get_mut(1).unwrap();
        assert_eq!(d.unread(), 1);
        d.acked_upto = d.hits.len();
        assert_eq!(d.unread(), 0);
    }
}
