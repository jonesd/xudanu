//! FR-158 Stage A: the enterprise knowledge fabric — skills and
//! expertise claims, endorsed the FR-157 way.
//!
//! A skill claim is a person saying "I have this skill," anchored to
//! evidence artifacts (work ids), with peer endorsements riding the
//! record. The design deliberately re-inhabits the FR-155 human
//! renditions pattern (and, behind it, Gold's endorsement model):
//!
//! - The claim's id is its content (blake3 over everything except
//!   endorsements): endorsements mutate the record, never the
//!   identity, so a grade can rise and fall without orphaning
//!   references.
//! - Grade is derived, not stored: no endorsements = `claimed`, any
//!   endorsement = `verified`.
//! - Endorsements anchor to evidence, are one per identity, are
//!   retractable, and obey the two-person rule (the subject cannot
//!   endorse their own claim).
//! - Claims are still not content: not addressable, not
//!   transcludable — trust facts about people, riding their own
//!   structures, never the annotation system.
//!
//! Storage mirrors the FR-155 Stage 3 durable layout under
//! `<data>/skills/`: `claims/<xx>/<hash>.json` plus `by-club/` and
//! `by-skill/` indexes. Corrupt or tampered files degrade to misses,
//! never crashes.

use serde::{Deserialize, Serialize};

pub const SKILL_GRADE_CLAIMED: &str = "claimed";
pub const SKILL_GRADE_VERIFIED: &str = "verified";

/// Bounds enforced by `validate_skill_claim`. Small on purpose: a
/// claim is a pointer to evidence, not an essay.
pub const SKILL_TAG_MAX: usize = 64;
pub const SKILL_SUMMARY_MAX: usize = 280;
pub const SKILL_NOTE_MAX: usize = 280;
pub const SKILL_EVIDENCE_MAX: usize = 8;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct SkillEvidence {
    /// Work id as lowercase hex — the artifact the claim anchors to.
    /// Validated to exist at submit time; a later-deleted work
    /// leaves a dangling-but-visible reference, never a crash.
    pub work_id: String,
    pub note: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct SkillEndorsement {
    pub club_id: u64,
    pub timestamp: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct SkillClaim {
    /// The person the claim is about. Stage A: self-claims only —
    /// the submitter must be the subject (enforced in dispatch).
    pub subject_club: u64,
    /// Normalized tag (lowercase, trimmed) — the index key.
    pub skill: String,
    pub summary: String,
    pub evidence: Vec<SkillEvidence>,
    pub submitter_club: u64,
    pub created_at: u64,
    pub endorsements: Vec<SkillEndorsement>,
}

impl SkillClaim {
    /// Content-addressed identity over the immutable core.
    /// Endorsements are deliberately excluded: they are the trust
    /// record riding on the claim, not its identity.
    pub fn id(&self) -> blake3::Hash {
        let mut hasher = blake3::Hasher::new();
        hasher.update(b"xudanu:skill-claim:1");
        for part in [
            self.subject_club.to_le_bytes(),
            self.submitter_club.to_le_bytes(),
            self.created_at.to_le_bytes(),
        ] {
            hasher.update(&(part.len() as u64).to_le_bytes());
            hasher.update(&part);
        }
        for part in [self.skill.as_bytes(), self.summary.as_bytes()] {
            hasher.update(&(part.len() as u64).to_le_bytes());
            hasher.update(part);
        }
        for e in &self.evidence {
            hasher.update(&(e.work_id.len() as u64).to_le_bytes());
            hasher.update(e.work_id.as_bytes());
            hasher.update(&(e.note.len() as u64).to_le_bytes());
            hasher.update(e.note.as_bytes());
        }
        hasher.finalize()
    }

    pub fn grade(&self) -> &'static str {
        if self.endorsements.is_empty() {
            SKILL_GRADE_CLAIMED
        } else {
            SKILL_GRADE_VERIFIED
        }
    }
}

/// A tag is a short human phrase: trimmed, 1..=SKILL_TAG_MAX chars,
/// no control characters, no path separators (it becomes a filename
/// via `skill_slug`).
pub fn valid_skill_tag(tag: &str) -> bool {
    let t = tag.trim();
    !t.is_empty()
        && t.len() <= SKILL_TAG_MAX
        && !t.chars().any(|c| c.is_control() || c == '/' || c == '\\')
}

/// Canonical form: trimmed and lowercased. Stored, indexed, and
/// matched in this form so `Rust`, `rust`, and ` RUST ` are one
/// skill.
pub fn normalize_skill_tag(tag: &str) -> String {
    tag.trim().to_lowercase()
}

/// Filename-safe form of a normalized tag.
fn skill_slug(normalized: &str) -> String {
    normalized
        .chars()
        .map(|c| if c.is_ascii_alphanumeric() { c } else { '-' })
        .collect()
}

/// Pure bounds/shape validation; existence of evidence works is
/// checked in dispatch (which has the server). Work ids must parse
/// as lowercase-or-any-case hex.
pub fn validate_skill_claim(
    skill: &str,
    summary: &str,
    evidence: &[SkillEvidence],
) -> Result<(), String> {
    if !valid_skill_tag(skill) {
        return Err(format!(
            "skill tag must be 1..={SKILL_TAG_MAX} chars, no control characters or slashes"
        ));
    }
    if summary.chars().count() > SKILL_SUMMARY_MAX {
        return Err(format!("summary over {SKILL_SUMMARY_MAX} chars"));
    }
    if evidence.is_empty() {
        return Err("a claim anchors to evidence: at least one work reference required".into());
    }
    if evidence.len() > SKILL_EVIDENCE_MAX {
        return Err(format!("at most {SKILL_EVIDENCE_MAX} evidence references"));
    }
    for e in evidence {
        if u64::from_str_radix(&e.work_id, 16).is_err() {
            return Err(format!("evidence work_id {:?} is not hex", e.work_id));
        }
        if e.note.chars().count() > SKILL_NOTE_MAX {
            return Err(format!("evidence note over {SKILL_NOTE_MAX} chars"));
        }
    }
    Ok(())
}

/// Durable store for skill claims (see module docs for layout).
#[derive(Debug, Clone)]
pub struct SkillStore {
    base: std::path::PathBuf,
}

impl SkillStore {
    pub fn open(base: &std::path::Path) -> std::io::Result<Self> {
        std::fs::create_dir_all(base)?;
        Ok(SkillStore {
            base: base.to_path_buf(),
        })
    }

    pub fn base(&self) -> &std::path::Path {
        &self.base
    }

    fn write_atomic(&self, path: &std::path::Path, bytes: &[u8]) -> std::io::Result<()> {
        if let Some(dir) = path.parent() {
            std::fs::create_dir_all(dir)?;
        }
        let tmp = path.with_extension("tmp");
        std::fs::write(&tmp, bytes)?;
        std::fs::rename(&tmp, path)
    }

    fn claim_path(&self, id: &blake3::Hash) -> std::path::PathBuf {
        let hex = id.to_hex().to_string();
        self.base
            .join("claims")
            .join(&hex[..2])
            .join(format!("{hex}.json"))
    }

    fn club_index_path(&self, club: u64) -> std::path::PathBuf {
        self.base.join("by-club").join(format!("{club}.json"))
    }

    fn skill_index_path(&self, skill: &str) -> std::path::PathBuf {
        self.base
            .join("by-skill")
            .join(format!("{}.json", skill_slug(skill)))
    }

    fn load_index(path: &std::path::Path) -> Vec<String> {
        std::fs::read_to_string(path)
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or_default()
    }

    /// Persist a claim (atomic) and add it to both indexes. The
    /// claim's id is its content: endorsements change the file,
    /// never the id.
    pub fn put_claim(&self, claim: &SkillClaim) -> std::io::Result<blake3::Hash> {
        let id = claim.id();
        let json = serde_json::to_string_pretty(claim)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
        self.write_atomic(&self.claim_path(&id), json.as_bytes())?;
        let hex = id.to_hex().to_string();
        for idx in [
            self.club_index_path(claim.subject_club),
            self.skill_index_path(&claim.skill),
        ] {
            let mut ids = Self::load_index(&idx);
            if !ids.contains(&hex) {
                ids.push(hex.clone());
                let idx_json = serde_json::to_string_pretty(&ids)
                    .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
                self.write_atomic(&idx, idx_json.as_bytes())?;
            }
        }
        Ok(id)
    }

    pub fn get_claim(&self, id: &blake3::Hash) -> Option<SkillClaim> {
        let data = std::fs::read_to_string(self.claim_path(id)).ok()?;
        serde_json::from_str(&data).ok()
    }

    /// Best-first ordering: verified before claimed, then more
    /// endorsements, then newest. (The comparator the rendition
    /// list initially got backwards — see FR-155 Stage A.)
    fn best_first(mut claims: Vec<SkillClaim>) -> Vec<SkillClaim> {
        claims.sort_by(|a, b| {
            a.endorsements
                .is_empty()
                .cmp(&b.endorsements.is_empty())
                .then(b.endorsements.len().cmp(&a.endorsements.len()))
                .then(b.created_at.cmp(&a.created_at))
        });
        claims
    }

    fn claims_from_index(&self, ids: Vec<String>) -> Vec<SkillClaim> {
        ids.iter()
            .filter_map(|hex| {
                blake3::Hash::from_hex(hex)
                    .ok()
                    .and_then(|h| self.get_claim(&h))
            })
            .collect()
    }

    /// All claims by one person, best first.
    pub fn claims_by_club(&self, club: u64) -> Vec<SkillClaim> {
        Self::best_first(self.claims_from_index(Self::load_index(&self.club_index_path(club))))
    }

    /// All claims for one skill across people, best first — the
    /// expertise-location query.
    pub fn claims_by_skill(&self, skill: &str) -> Vec<SkillClaim> {
        let normalized = normalize_skill_tag(skill);
        Self::best_first(
            self.claims_from_index(Self::load_index(&self.skill_index_path(&normalized))),
        )
    }

    /// Endorse a claim. Two-person rule: the subject cannot endorse
    /// their own claim; one endorsement per identity, retractable
    /// via `unendorse`.
    pub fn endorse(&self, id: &blake3::Hash, club_id: u64, now: u64) -> Result<SkillClaim, String> {
        let mut claim = self
            .get_claim(id)
            .ok_or_else(|| "claim not found".to_string())?;
        if claim.subject_club == club_id {
            return Err("two-person rule: the subject cannot endorse their own claim".into());
        }
        if claim.endorsements.iter().any(|e| e.club_id == club_id) {
            return Err("this club has already endorsed this claim".into());
        }
        claim.endorsements.push(SkillEndorsement {
            club_id,
            timestamp: now,
        });
        self.persist(&claim).map_err(|e| e.to_string())?;
        Ok(claim)
    }

    /// Retract an endorsement.
    pub fn unendorse(&self, id: &blake3::Hash, club_id: u64) -> Result<SkillClaim, String> {
        let mut claim = self
            .get_claim(id)
            .ok_or_else(|| "claim not found".to_string())?;
        let before = claim.endorsements.len();
        claim.endorsements.retain(|e| e.club_id != club_id);
        if claim.endorsements.len() == before {
            return Err("no endorsement from this club to retract".into());
        }
        self.persist(&claim).map_err(|e| e.to_string())?;
        Ok(claim)
    }

    fn persist(&self, claim: &SkillClaim) -> std::io::Result<()> {
        let json = serde_json::to_string_pretty(claim)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
        self.write_atomic(&self.claim_path(&claim.id()), json.as_bytes())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn evidence(work_hex: &str, note: &str) -> SkillEvidence {
        SkillEvidence {
            work_id: work_hex.to_string(),
            note: note.to_string(),
        }
    }

    fn claim(skill: &str, subject: u64, evidence: Vec<SkillEvidence>) -> SkillClaim {
        SkillClaim {
            subject_club: subject,
            skill: normalize_skill_tag(skill),
            summary: "did the thing".into(),
            evidence,
            submitter_club: subject,
            created_at: 1_000,
            endorsements: Vec::new(),
        }
    }

    fn temp_store(tag: &str) -> SkillStore {
        let dir =
            std::env::temp_dir().join(format!("xudanu-skills-{}-{}", std::process::id(), tag));
        drop(std::fs::remove_dir_all(&dir));
        SkillStore::open(&dir).expect("temp skill store")
    }

    #[test]
    fn claim_id_stable_under_endorsement_and_grade_ladders() {
        let mut c = claim("rust", 7, vec![evidence("a1", "core")]);
        let id_before = c.id();
        assert_eq!(c.grade(), SKILL_GRADE_CLAIMED);
        c.endorsements.push(SkillEndorsement {
            club_id: 99,
            timestamp: 5_000,
        });
        assert_eq!(
            c.id(),
            id_before,
            "endorsements ride the record, not the id"
        );
        assert_eq!(c.grade(), SKILL_GRADE_VERIFIED);
    }

    #[test]
    fn tags_validate_normalize_and_slug() {
        assert!(valid_skill_tag("rust"));
        assert!(valid_skill_tag("  Derivatives Pricing "));
        assert!(!valid_skill_tag(""));
        assert!(!valid_skill_tag(&"x".repeat(SKILL_TAG_MAX + 1)));
        assert!(!valid_skill_tag("a/b"));
        assert!(!valid_skill_tag("a\\b"));
        assert!(!valid_skill_tag("a\u{1}b"));
        assert_eq!(normalize_skill_tag("  Rust "), "rust");
        assert_eq!(skill_slug("derivatives pricing"), "derivatives-pricing");
    }

    #[test]
    fn validation_rejects_shape_violations() {
        assert!(validate_skill_claim("rust", "systems", &[evidence("1a", "wrote it")]).is_ok());
        // Empty evidence: claims must anchor to artifacts.
        let err = validate_skill_claim("rust", "s", &[]).expect_err("no evidence");
        assert!(err.contains("evidence"), "{err}");
        // Non-hex work id.
        let err =
            validate_skill_claim("rust", "s", &[evidence("nothex", "x")]).expect_err("bad hex");
        assert!(err.contains("not hex"), "{err}");
        // Oversized summary and notes.
        let err = validate_skill_claim(
            "rust",
            &"s".repeat(SKILL_SUMMARY_MAX + 1),
            &[evidence("1a", "x")],
        )
        .expect_err("long summary");
        assert!(err.contains("summary"), "{err}");
        let err = validate_skill_claim(
            "rust",
            "s",
            &[evidence("1a", &"n".repeat(SKILL_NOTE_MAX + 1))],
        )
        .expect_err("long note");
        assert!(err.contains("note"), "{err}");
        // Too many evidence refs.
        let many: Vec<SkillEvidence> = (0..SKILL_EVIDENCE_MAX + 1)
            .map(|i| evidence("1a", &format!("n{i}")))
            .collect();
        let err = validate_skill_claim("rust", "s", &many).expect_err("too many refs");
        assert!(err.contains("at most"), "{err}");
    }

    #[test]
    fn store_roundtrip_endorse_rules_and_ordering() {
        let store = temp_store("roundtrip");
        let subject = 7u64;
        let mut a = claim("rust", subject, vec![evidence("1a", "core")]);
        a.created_at = 1_000;
        let mut b = claim("rust", 8, vec![evidence("2b", "cli")]);
        b.created_at = 2_000;

        let id_a = store.put_claim(&a).expect("put a");
        let id_b = store.put_claim(&b).expect("put b");
        assert_ne!(id_a, id_b);
        assert_eq!(store.get_claim(&id_a), Some(a.clone()));

        // Neither endorsed: newest first.
        let by_skill = store.claims_by_skill("RUST");
        assert_eq!(by_skill.len(), 2, "normalized tag matches any case");
        assert_eq!(by_skill[0].subject_club, 8, "newest draft first");

        // Two-person rule.
        let err = store
            .endorse(&id_a, subject, 5_000)
            .expect_err("self-endorse");
        assert!(err.contains("two-person rule"), "{err}");

        // Endorsements move claims up; more beats fewer.
        store.endorse(&id_b, 10, 5_000).expect("endorse b");
        store.endorse(&id_b, 11, 5_100).expect("endorse b again");
        store.endorse(&id_a, 10, 5_200).expect("endorse a");
        let by_skill = store.claims_by_skill("rust");
        assert_eq!(by_skill[0].subject_club, 8, "two endorsements beat one");
        assert_eq!(by_skill[0].grade(), SKILL_GRADE_VERIFIED);
        let by_club = store.claims_by_club(subject);
        assert_eq!(by_club.len(), 1);
        assert_eq!(by_club[0].grade(), SKILL_GRADE_VERIFIED);

        // One per identity; retraction drops back down.
        let err = store.endorse(&id_b, 10, 5_300).expect_err("duplicate");
        assert!(err.contains("already endorsed"), "{err}");
        store.unendorse(&id_b, 10).expect("retract");
        store.unendorse(&id_b, 11).expect("retract");
        assert_eq!(
            store.get_claim(&id_b).unwrap().grade(),
            SKILL_GRADE_CLAIMED,
            "back to claimed after full retraction"
        );
        let err = store.unendorse(&id_b, 10).expect_err("nothing to retract");
        assert!(err.contains("no endorsement"), "{err}");
    }

    #[test]
    fn corrupt_claim_file_degrades_to_miss() {
        let store = temp_store("corrupt");
        let c = claim("go", 7, vec![evidence("3c", "servers")]);
        let id = store.put_claim(&c).expect("put");
        let path = store.claim_path(&id);
        std::fs::write(&path, b"{ not json").expect("corrupt write");
        assert_eq!(
            store.get_claim(&id),
            None,
            "corrupt file is a miss, not a crash"
        );
        assert!(store.claims_by_club(7).is_empty());
    }
}
