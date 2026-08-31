//! FR-34 crum-path notarization: provable quotation with compact
//! commitments. A `RangeNotarization` binds three hashes — the
//! range crum (the ordered subtree crums covering [start, end)),
//! the edition's root crum, and the excerpt text hash — to a
//! server Ed25519 signature. Anyone can verify WHAT was quoted
//! (excerpt hash; no document needed) and THAT it was in the work
//! at notarization time (range crum recomputed against the edition,
//! or trust the signature). The privacy property: proving content
//! never requires shipping the document.

use crate::edition::Edition;

/// BLAKE3 domain separators (never cross-wired with other crum uses).
const RANGE_CRUM_DOMAIN: &[u8] = b"xudanu-range-crum-v1";
const EXCERPT_DOMAIN: &[u8] = b"xudanu-excerpt-v1";
const NOTARIZATION_DOMAIN: &[u8] = b"xudanu-notarization-v1";

#[derive(Debug, Clone, PartialEq)]
pub struct RangeNotarization {
    pub work_id: u64,
    pub char_start: usize,
    pub char_end: usize,
    /// Ordered fold of the crums of every entry overlapping the
    /// range (structural identity of the covered content).
    pub range_crum: [u8; 32],
    /// The edition's root crum at notarization time — the state the
    /// range was quoted from.
    pub root_crum: [u8; 32],
    /// BLAKE3 of the excerpt text (what the reader saw).
    pub excerpt_hash: [u8; 32],
    /// Server signature over all of the above.
    pub signature: [u8; 64],
    /// Unix seconds at notarization.
    pub timestamp: u64,
}

/// Compute the range crum over an edition: every entry whose char
/// extent overlaps [start, end), folded in document order.
pub fn range_crum(edition: &Edition, start: usize, end: usize) -> Option<[u8; 32]> {
    if start >= end {
        return None;
    }
    let mut hasher = blake3::Hasher::new();
    hasher.update(RANGE_CRUM_DOMAIN);
    hasher.update(&(start as u64).to_le_bytes());
    hasher.update(&(end as u64).to_le_bytes());
    let entries = edition.cached_entries();
    let starts = edition.cached_char_starts();
    let mut cum = 0usize;
    for (_, carrier) in entries {
        let len = carrier.char_len();
        if len == 0 {
            continue;
        }
        let entry_start = cum;
        let entry_end = cum + len;
        cum = entry_end;
        if entry_end <= start || entry_start >= end {
            continue;
        }
        // Entry crum: element fingerprint + provenance identity.
        let mut eh = blake3::Hasher::new();
        eh.update(b"xn-entry");
        eh.update(&carrier.element.content_fingerprint());
        if let Some(p) = &carrier.provenance {
            eh.update(&p.author_public_key);
            eh.update(&p.timestamp.to_le_bytes());
        }
        hasher.update(eh.finalize().as_bytes());
        let _ = starts;
    }
    Some(*hasher.finalize().as_bytes())
}

/// BLAKE3 of the excerpt text (the reader-visible content).
pub fn excerpt_hash(text: &str) -> [u8; 32] {
    let mut h = blake3::Hasher::new();
    h.update(EXCERPT_DOMAIN);
    h.update(text.as_bytes());
    *h.finalize().as_bytes()
}

/// The bytes a notarization signature commits to.
pub fn notarization_payload(n: &RangeNotarization) -> Vec<u8> {
    let mut v = Vec::with_capacity(160);
    v.extend_from_slice(NOTARIZATION_DOMAIN);
    v.extend_from_slice(&n.work_id.to_le_bytes());
    v.extend_from_slice(&(n.char_start as u64).to_le_bytes());
    v.extend_from_slice(&(n.char_end as u64).to_le_bytes());
    v.extend_from_slice(&n.range_crum);
    v.extend_from_slice(&n.root_crum);
    v.extend_from_slice(&n.excerpt_hash);
    v.extend_from_slice(&n.timestamp.to_le_bytes());
    v
}

impl RangeNotarization {
    /// Verify the quoted text matches the notarization (WHAT was
    /// quoted) — no document required.
    pub fn verify_excerpt(&self, text: &str) -> bool {
        excerpt_hash(text) == self.excerpt_hash
    }

    /// Verify the signature (THAT the server attested it).
    #[cfg(feature = "server")]
    pub fn verify_signature(&self, verifying_key: &ed25519_dalek::VerifyingKey) -> bool {
        let sig = ed25519_dalek::Signature::from_bytes(&self.signature);
        use ed25519_dalek::Verifier;
        verifying_key
            .verify(&notarization_payload(self), &sig)
            .is_ok()
    }

    /// Verify against a live edition: the range crum must
    /// recompute exactly (the content is still there, unchanged).
    pub fn verify_against_edition(&self, edition: &Edition) -> bool {
        match range_crum(edition, self.char_start, self.char_end) {
            Some(rc) => rc == self.range_crum,
            None => false,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn range_crum_covers_only_the_range() {
        let ed = Edition::from_text("hello world");
        let full = range_crum(&ed, 0, 11).expect("full range");
        let part = range_crum(&ed, 0, 5).expect("partial");
        assert_ne!(full, part);
        assert_eq!(range_crum(&ed, 3, 3), None, "empty range");
        // Same range on identical content: deterministic.
        let ed2 = Edition::from_text("hello world");
        assert_eq!(part, range_crum(&ed2, 0, 5).unwrap());
        // Different covered content: different crum. ([0,5) is
        // "hello" in both — only the tail differs, so quote the
        // tail.)
        let ed3 = Edition::from_text("hello worlds");
        let tail = range_crum(&ed, 9, 11).unwrap();
        assert_ne!(tail, range_crum(&ed3, 10, 12).unwrap());
        // Equal covered content in different-length docs: equal.
        assert_eq!(part, range_crum(&ed3, 0, 5).unwrap());
    }

    #[test]
    fn excerpt_hash_is_domain_separated() {
        assert_eq!(excerpt_hash("text"), excerpt_hash("text"));
        assert_ne!(excerpt_hash("text"), excerpt_hash("texu"));
        // Not equal to a raw blake3 of the same bytes.
        assert_ne!(excerpt_hash("text"), *blake3::hash(b"text").as_bytes());
    }

    #[test]
    fn payload_commits_to_every_field() {
        let base = RangeNotarization {
            work_id: 1,
            char_start: 0,
            char_end: 5,
            range_crum: [1; 32],
            root_crum: [2; 32],
            excerpt_hash: [3; 32],
            signature: [0; 64],
            timestamp: 42,
        };
        let p0 = notarization_payload(&base);
        let mut m = base.clone();
        m.work_id = 2;
        assert_ne!(p0, notarization_payload(&m));
        let mut m = base.clone();
        m.char_start = 1;
        assert_ne!(p0, notarization_payload(&m));
        let mut m = base.clone();
        m.range_crum = [9; 32];
        assert_ne!(p0, notarization_payload(&m));
        let mut m = base.clone();
        m.timestamp = 43;
        assert_ne!(p0, notarization_payload(&m));
    }
}
