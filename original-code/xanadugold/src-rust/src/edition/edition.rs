use std::collections::{BTreeMap, HashSet};
use std::sync::Arc;
use std::sync::OnceLock;

use super::backend::BeId;
use super::bundle::{
    compute_storage_cost, element_byte_size, fingerprint_u64, retrieve_bundles, Bundle, CostMethod,
    RetrieveFlags, StorageCost,
};
use super::endorsement::EndorsementSet;
use super::orgl::OrglRoot;
use super::provenance::SpanProvenance;
use super::range_element::{Carrier, RangeElement};
use super::shared_mapping::{
    content_map_shared_onto, content_map_shared_to, content_shared_region, SharedMapping,
};
use super::work::License;
use super::xn_region::XnRegion;

/// Lazily-built flat view of an edition: sorted entries plus the
/// cumulative char-start of each entry (parallel arrays). Char starts
/// enable binary-search char -> entry mapping for the tree-native
/// delta path (PERF-PLAN Stage 5).
pub(crate) type EntriesCache = (Vec<(i64, Arc<Carrier>)>, Vec<usize>, Vec<[u8; 32]>, bool);

#[derive(Debug, Clone)]
pub struct Edition {
    pub(crate) orgl: OrglRoot,
    pub(crate) endorsements: EndorsementSet,
    #[allow(dead_code)]
    pub(crate) entries_cache: Arc<OnceLock<EntriesCache>>,
    pub(crate) span_provenance: Vec<SpanProvenance>,
    span_status_cache: Arc<std::sync::Mutex<Option<(u64, Arc<Vec<u8>>)>>>,
}

impl Edition {
    pub(crate) fn new_inner(orgl: OrglRoot, endorsements: EndorsementSet) -> Self {
        Edition {
            orgl,
            endorsements,
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    /// Rebuild with a PRE-BUILT entries cache (the CRDT fast path
    /// carries its cache across edits — rebuilding would be O(N)).
    pub(crate) fn from_parts_with_cache(
        orgl: OrglRoot,
        endorsements: EndorsementSet,
        entries_cache: Arc<OnceLock<EntriesCache>>,
        span_provenance: Vec<SpanProvenance>,
    ) -> Self {
        Edition {
            orgl,
            endorsements,
            entries_cache,
            span_provenance,
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    pub(crate) fn new_inner_with_provenance(
        orgl: OrglRoot,
        endorsements: EndorsementSet,
        span_provenance: Vec<SpanProvenance>,
    ) -> Self {
        Edition {
            orgl,
            endorsements,
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance,
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }
}

pub struct OutlineEntry {
    pub level: u32,
    pub text: String,
    pub line: u64,
    pub char_offset: u64,
}

/// Ground-truth result of a per-span license query (FR-38 Phase 1).
/// `total_class` is the OR of every entry's license class in the span;
/// `boundaries` lists the ownership runs crossed with their per-run
/// classes. This structure is what the FR-38 overlay answers in
/// O(log n + b); here it is computed by scan (O(span entries)) — the
/// authoritative fallback and the overlay's seed/regression source.
#[derive(Debug, Clone, Default, PartialEq)]
pub struct SpanLicenseSummary {
    pub total_class: super::work::LicenseClass,
    pub pending_class: super::work::LicenseClass,
    /// (char_start, char_end, owner_club, run_class) per ownership run.
    pub boundaries: Vec<(usize, usize, Option<BeId>, super::work::LicenseClass)>,
    pub distinct_owners: usize,
    pub unresolved_entries: usize,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct EntryIdentity {
    pub position: i64,
    pub content_fingerprint: [u8; 32],
    pub has_provenance: bool,
    pub is_text: bool,
}

/// Entry-level edit operation for `Edition::apply_edits()`.
#[derive(Debug, Clone)]
pub enum EditionEdit {
    Insert(i64, RangeElement),
    Delete(i64),
    Replace(i64, RangeElement),
}

/// A blob (image) element found in an edition, with its character position.
#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct BlobEntry {
    pub char_position: usize,
    /// Serialized as a string: u64 hashes exceed JavaScript's safe
    /// integer range, and browsers silently round them (wrong hash) or
    /// reject the frame (protocol error killing the response stream).
    #[cfg_attr(feature = "serde", serde(serialize_with = "ser_u64_string"))]
    #[cfg_attr(feature = "serde", serde(deserialize_with = "de_u64_string_or_int"))]
    pub content_hash: u64,
    pub mime_type: String,
    pub byte_size: u64,
    pub width: Option<u32>,
    pub height: Option<u32>,
    #[cfg_attr(feature = "serde", serde(default))]
    pub caption: Option<String>,
}

pub struct SearchMatch {
    pub char_offset: u64,
    pub line: u64,
    pub context: String,
}

impl PartialEq for Edition {
    fn eq(&self, other: &Self) -> bool {
        if self.orgl.count() != other.orgl.count() {
            return false;
        }
        let my_entries = self.orgl.all_entries();
        let other_entries = other.orgl.all_entries();
        if my_entries.len() != other_entries.len() {
            return false;
        }
        for (a, b) in my_entries.iter().zip(other_entries.iter()) {
            if a.0 != b.0 {
                return false;
            }
            if a.1.element.as_text() != b.1.element.as_text() {
                return false;
            }
        }
        true
    }
}
impl Edition {
    fn build_entries_cache(&self) -> EntriesCache {
        let entries = self.orgl.all_entries();
        let mut starts = Vec::with_capacity(entries.len());
        let mut fingerprints = Vec::with_capacity(entries.len());
        let mut has_transclusions = false;
        let mut cum = 0usize;
        for (_, carrier) in &entries {
            starts.push(cum);
            cum += carrier.char_len();
            fingerprints.push(carrier.element.content_fingerprint());
            if carrier.element.is_transclusion()
                || matches!(
                    carrier.element,
                    super::range_element::RangeElement::StructuralTransclusion { .. }
                )
            {
                has_transclusions = true;
            }
        }
        (entries, starts, fingerprints, has_transclusions)
    }

    pub fn cached_entries(&self) -> &Vec<(i64, Arc<Carrier>)> {
        &self
            .entries_cache
            .get_or_init(|| self.build_entries_cache())
            .0
    }

    /// Cumulative char start of each cached entry (parallel to
    /// `cached_entries`). Built once per edition.
    pub fn cached_char_starts(&self) -> &[usize] {
        &self
            .entries_cache
            .get_or_init(|| self.build_entries_cache())
            .1
    }

    /// Content fingerprint of each cached entry (parallel to
    /// `cached_entries`). Each element hashes once per edition state —
    /// hot paths (attribution verification) read instead of re-hashing
    /// whole spans per query (FR-50 finding 2).
    pub fn cached_fingerprints(&self) -> &[[u8; 32]] {
        &self
            .entries_cache
            .get_or_init(|| self.build_entries_cache())
            .2
    }

    /// Whether this edition contains any inline transclusion element.
    /// Computed in the same pass as the entry cache — lets hot paths
    /// (per-keystroke transclusion migration) skip transclusion-free
    /// works in O(1) instead of walking every entry (FR-50 fix C).
    pub fn cached_has_transclusions(&self) -> bool {
        self.entries_cache
            .get_or_init(|| self.build_entries_cache())
            .3
    }

    /// Content equality ignoring entry positions: same number of
    /// entries and same text per entry. A position-tolerant superset of
    /// `PartialEq` — editions produced by the bulk (dense renumbering)
    /// and tree-native (stable position) delta paths compare equal when
    /// their content and segmentation match.
    pub fn same_content(&self, other: &Edition) -> bool {
        if self.orgl.count() != other.orgl.count() {
            return false;
        }
        let a = self.cached_entries();
        let b = other.cached_entries();
        if a.len() != b.len() {
            return false;
        }
        a.iter()
            .zip(b.iter())
            .all(|(x, y)| x.1.element.as_text() == y.1.element.as_text())
    }

    pub fn empty() -> Self {
        Edition {
            orgl: OrglRoot::empty(),
            endorsements: EndorsementSet::new(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    /// Per-span signature status, memoized: true when the stored
    /// signature verifies against current fingerprints, OR any
    /// element in the span's entry range carries the same author
    /// key (own-author maintained — FR-140 tier 2). Verification
    /// hashes the span's whole fingerprint set (a full-document
    /// span at 256k is ~8MB per query) and the fallback scans the
    /// entry range — both depend only on this immutable edition, so
    /// they compute once (FR-50 #4: repeated attribution queries
    /// were O(N)-per-call with identical inputs).
    pub fn cached_span_signature_status(&self) -> Arc<Vec<u8>> {
        let mut key: u64 = 1469598103934665603;
        for sp in &self.span_provenance {
            for b in sp
                .provenance
                .author_public_key
                .iter()
                .chain(sp.provenance.signature.iter())
                .chain(sp.provenance.server_id.iter())
                .chain(sp.start.to_le_bytes().iter())
                .chain(sp.end.to_le_bytes().iter())
                .chain(sp.provenance.timestamp.to_le_bytes().iter())
            {
                key ^= *b as u64;
                key = key.wrapping_mul(1099511628211);
            }
        }
        {
            let guard = self
                .span_status_cache
                .lock()
                .unwrap_or_else(|e| e.into_inner());
            if let Some((k, v)) = guard.as_ref() {
                if *k == key {
                    return v.clone();
                }
            }
        }
        let statuses = Arc::new(self.compute_span_signature_statuses());
        {
            let mut guard = self
                .span_status_cache
                .lock()
                .unwrap_or_else(|e| e.into_inner());
            *guard = Some((key, statuses.clone()));
        }
        statuses
    }

    fn compute_span_signature_statuses(&self) -> Vec<u8> {
        {
            const STORE_VERIFIED: u8 = 0;
            const AUTHOR_MAINTAINED: u8 = 1;
            const UNSIGNED: u8 = 2;
            let entries = self.cached_entries();
            let fingerprints = self.cached_fingerprints();
            self.span_provenance
                .iter()
                .map(|sp| {
                    let i_start = entries.partition_point(|(p, _)| *p < sp.start);
                    let i_end = entries.partition_point(|(p, _)| *p < sp.end);
                    let fps: &[[u8; 32]] = fingerprints
                        .get(i_start..i_end)
                        .map(|s| s as &[[u8; 32]])
                        .unwrap_or(&[]);
                    if crate::edition::provenance::verify_span_provenance(&sp.provenance, fps) {
                        return STORE_VERIFIED;
                    }
                    let same_author = entries
                        .get(i_start..i_end)
                        .map(|slice| {
                            slice.iter().any(|(_, c)| {
                                c.provenance.as_ref().is_some_and(|ep| {
                                    ep.author_public_key == sp.provenance.author_public_key
                                })
                            })
                        })
                        .unwrap_or(false);
                    if same_author {
                        AUTHOR_MAINTAINED
                    } else {
                        UNSIGNED
                    }
                })
                .collect()
        }
    }

    pub fn from_one(position: i64, value: RangeElement) -> Self {
        let orgl = OrglRoot::empty().with(position, Arc::new(Carrier::new(value)));
        Edition {
            orgl,
            endorsements: EndorsementSet::new(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    pub fn from_all(region: &XnRegion, value: RangeElement) -> Self {
        if !region.is_finite() {
            let orgl = OrglRoot::with_default(region.clone(), Arc::new(Carrier::new(value)));
            return Edition {
                orgl,
                endorsements: EndorsementSet::new(),
                entries_cache: Arc::new(OnceLock::new()),
                span_provenance: Vec::new(),
                span_status_cache: Arc::new(std::sync::Mutex::new(None)),
            };
        }
        let mut orgl = OrglRoot::empty();
        for (start, stop) in region.intervals() {
            for pos in start..stop {
                orgl = orgl.with(pos, Arc::new(Carrier::new(value.clone())));
            }
        }
        Edition {
            orgl,
            endorsements: EndorsementSet::new(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    pub fn from_text(text: &str) -> Self {
        let entries: Vec<(i64, Arc<Carrier>)> = text
            .chars()
            .enumerate()
            .map(|(i, ch)| {
                let mut buf = [0u8; 4];
                let s = ch.encode_utf8(&mut buf);
                (
                    i as i64,
                    Arc::new(Carrier::new(RangeElement::text(s.to_string()))),
                )
            })
            .collect();
        let n = entries.len();
        let region = if n > 0 {
            XnRegion::interval(0, n as i64)
        } else {
            XnRegion::empty()
        };
        Edition {
            orgl: OrglRoot::from_bulk_entries(entries, None, region),
            endorsements: EndorsementSet::new(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    pub fn from_text_batched(text: &str) -> Self {
        if text.is_empty() {
            return Edition::empty();
        }

        let mut entries = Vec::new();
        let mut pos = 0i64;
        let mut start = 0usize;

        for (i, ch) in text.char_indices() {
            if ch == '\n' {
                let line = &text[start..i + ch.len_utf8()];
                entries.push((
                    pos,
                    Arc::new(Carrier::new(RangeElement::text(line.to_string()))),
                ));
                pos += 1;
                start = i + ch.len_utf8();
            }
        }

        if start < text.len() {
            let remaining = &text[start..];
            entries.push((
                pos,
                Arc::new(Carrier::new(RangeElement::text(remaining.to_string()))),
            ));
        }

        if entries.is_empty() {
            return Edition::empty();
        }

        let n = entries.len();
        let region = XnRegion::interval(0, n as i64);
        Edition {
            orgl: OrglRoot::from_bulk_entries(entries, None, region),
            endorsements: EndorsementSet::new(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    pub fn from_entries(entries: Vec<(i64, Arc<Carrier>)>) -> Self {
        let n = entries.len();
        let region = if n > 0 {
            XnRegion::interval(0, n as i64)
        } else {
            XnRegion::empty()
        };
        Edition {
            orgl: OrglRoot::from_bulk_entries(entries, None, region),
            endorsements: EndorsementSet::new(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    /// Build an Edition that PRESERVES the given (possibly sparse)
    /// positions (PERF-PLAN Stage 4). Entries must be strictly
    /// increasing; they are sorted defensively and rejected otherwise.
    ///
    /// Unlike `from_entries` (dense 0..n) and `coalesce` (renumbers),
    /// this is the constructor for gap-allocated layouts where an edit
    /// never renumbers unrelated entries. Do NOT call `.coalesce()` on
    /// the result — it would renumber.
    pub fn from_entries_at_positions(entries: Vec<(i64, Arc<Carrier>)>) -> Result<Self, String> {
        let mut sorted = entries;
        sorted.sort_by_key(|(p, _)| *p);
        for w in sorted.windows(2) {
            if w[0].0 >= w[1].0 {
                return Err(format!(
                    "positions must be strictly increasing, got {} then {}",
                    w[0].0, w[1].0
                ));
            }
        }
        let region = match (sorted.first(), sorted.last()) {
            (Some(f), Some(l)) => XnRegion::interval(f.0, l.0 + 1),
            _ => XnRegion::empty(),
        };
        Ok(Edition {
            orgl: OrglRoot::from_bulk_entries(sorted, None, region),
            endorsements: EndorsementSet::new(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        })
    }

    /// Sorted entry positions (increasing). For locating allocation
    /// neighbors in the tree-native delta path (Stage 5).
    pub fn positions(&self) -> Vec<i64> {
        self.cached_entries().iter().map(|(p, _)| *p).collect()
    }

    pub fn from_text_elements(elements: &[RangeElement]) -> Self {
        let entries: Vec<(i64, Arc<Carrier>)> = elements
            .iter()
            .enumerate()
            .map(|(i, e)| (i as i64, Arc::new(Carrier::new(e.clone()))))
            .collect();
        let n = entries.len();
        let region = if n > 0 {
            XnRegion::interval(0, n as i64)
        } else {
            XnRegion::empty()
        };
        Edition {
            orgl: OrglRoot::from_bulk_entries(entries, None, region),
            endorsements: EndorsementSet::new(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    pub fn place_holders(region: &XnRegion) -> Self {
        let mut next_id = 0u64;
        let mut entries = Vec::new();
        for (start, stop) in region.intervals() {
            for pos in start..stop {
                entries.push((
                    pos,
                    Arc::new(Carrier::new(RangeElement::placeholder(next_id))),
                ));
                next_id += 1;
            }
        }
        Edition {
            orgl: OrglRoot::from_bulk_entries(entries, None, region.clone()),
            endorsements: EndorsementSet::new(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    pub fn with_default(region: XnRegion, value: RangeElement) -> Self {
        let orgl = OrglRoot::with_default(region, Arc::new(Carrier::new(value)));
        Edition {
            orgl,
            endorsements: EndorsementSet::new(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    pub fn is_empty(&self) -> bool {
        self.orgl.is_empty()
    }

    pub fn is_infinite(&self) -> bool {
        self.orgl.is_infinite()
    }

    pub fn default_value(&self) -> Option<RangeElement> {
        self.orgl.default_value()
    }

    pub fn count(&self) -> u64 {
        self.orgl.count()
    }

    pub fn is_finite(&self) -> bool {
        !self.orgl.is_infinite() && !self.orgl.is_empty()
    }

    pub fn domain(&self) -> XnRegion {
        self.orgl.domain()
    }

    pub fn fetch(&self, position: i64) -> Option<RangeElement> {
        self.orgl.fetch(position).map(|c| c.element.clone())
    }

    pub fn fetch_owned(&self, position: i64) -> Option<Arc<Carrier>> {
        self.orgl.fetch(position)
    }

    pub fn get(&self, position: i64) -> RangeElement {
        self.orgl
            .fetch(position)
            .expect("position not in edition")
            .element
            .clone()
    }

    pub fn get_owned(&self, position: i64) -> Arc<Carrier> {
        self.orgl.fetch(position).expect("position not in edition")
    }

    pub fn has_position(&self, position: i64) -> bool {
        self.orgl.has_position(position)
    }

    pub fn all_entries(&self) -> Vec<(i64, Arc<Carrier>)> {
        self.cached_entries().clone()
    }

    pub fn endorsements(&self) -> &EndorsementSet {
        &self.endorsements
    }

    pub fn endorse(&mut self, additional: &EndorsementSet) {
        self.endorsements = self.endorsements.union(additional);
    }

    pub fn retract(&mut self, removed: &EndorsementSet) {
        self.endorsements = self.endorsements.difference(removed);
    }

    pub fn with_endorsements(mut self, endorsements: EndorsementSet) -> Self {
        self.endorsements = endorsements;
        self
    }

    pub fn with_span_provenance(mut self, sp: Vec<SpanProvenance>) -> Self {
        self.span_provenance = sp;
        self
    }

    pub fn span_provenance(&self) -> &[SpanProvenance] {
        &self.span_provenance
    }

    pub fn fetch_all(&self) -> Vec<(i64, Arc<Carrier>)> {
        self.orgl.all_entries()
    }

    pub fn fetch_range(&self, region: &XnRegion) -> Vec<(i64, Arc<Carrier>)> {
        self.orgl
            .all_entries()
            .into_iter()
            .filter(|(pos, _)| region.contains(*pos))
            .collect()
    }

    pub fn carrier_at(&self, position: i64) -> Option<Arc<Carrier>> {
        self.orgl.fetch(position)
    }

    pub fn with(&self, position: i64, value: RangeElement) -> Self {
        Edition {
            orgl: self.orgl.with(position, Arc::new(Carrier::new(value))),
            endorsements: self.endorsements.clone(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    pub fn with_all(&self, region: &XnRegion, value: RangeElement) -> Self {
        let mut orgl = self.orgl.clone();
        for (start, stop) in region.intervals() {
            for pos in start..stop {
                orgl = orgl.with(pos, Arc::new(Carrier::new(value.clone())));
            }
        }
        Edition {
            orgl,
            endorsements: EndorsementSet::new(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    pub fn without(&self, position: i64) -> Self {
        Edition {
            orgl: self.orgl.without(position),
            endorsements: self.endorsements.clone(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    pub fn without_all(&self, region: &XnRegion) -> Self {
        let keep_region = self.domain().minus(region);
        Edition {
            orgl: self.orgl.copy(&keep_region),
            endorsements: self.endorsements.clone(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    pub fn combine(&self, other: &Edition) -> Result<Edition, CombineConflict> {
        let my_entries = self.orgl.all_entries();
        let other_entries = other.orgl.all_entries();
        for (pos, carrier) in &my_entries {
            if let Some(idx) = other_entries.binary_search_by_key(pos, |(p, _)| *p).ok() {
                if *carrier != other_entries[idx].1 {
                    return Err(CombineConflict {
                        position: *pos,
                        left: carrier.element.clone(),
                        right: other_entries[idx].1.element.clone(),
                    });
                }
            }
        }
        match self.orgl.combine(&other.orgl) {
            Ok(combined) => Ok(Edition {
                orgl: combined,
                endorsements: EndorsementSet::new(),
                entries_cache: Arc::new(OnceLock::new()),
                span_provenance: Vec::new(),
                span_status_cache: Arc::new(std::sync::Mutex::new(None)),
            }),
            Err(_) => {
                let mut orgl = self.orgl.clone();
                for (pos, carrier) in other_entries {
                    if !orgl.has_position(pos) {
                        orgl = orgl.with(pos, carrier);
                    }
                }
                Ok(Edition {
                    orgl,
                    endorsements: EndorsementSet::new(),
                    entries_cache: Arc::new(OnceLock::new()),
                    span_provenance: Vec::new(),
                    span_status_cache: Arc::new(std::sync::Mutex::new(None)),
                })
            }
        }
    }

    pub fn replace(&self, other: &Edition) -> Edition {
        Edition {
            orgl: self.orgl.replace(&other.orgl),
            endorsements: self.endorsements.clone(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    pub fn copy(&self, region: &XnRegion) -> Edition {
        Edition {
            orgl: self.orgl.copy(region),
            endorsements: self.endorsements.clone(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    pub fn transformed_by(&self, offset: i64) -> Edition {
        Edition {
            orgl: self.orgl.transformed_by(offset),
            endorsements: self.endorsements.clone(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    pub fn transformed_by_mapping(&self, mapping: &super::mapping::Mapping) -> Edition {
        if mapping.is_empty() {
            return Edition::empty();
        }
        if mapping.is_identity() {
            return self.clone();
        }
        let entries = self.orgl.all_entries();
        let mut new_entries: Vec<(i64, Arc<Carrier>)> = Vec::with_capacity(entries.len());
        for (pos, carrier) in &entries {
            if let Some(new_pos) = mapping.of(*pos) {
                new_entries.push((new_pos, carrier.clone()));
            }
        }
        new_entries.sort_by_key(|(p, _)| *p);
        let domain = self.domain();
        let new_domain = mapping.of_region(&domain);
        if new_entries.is_empty() {
            return Edition::empty();
        }
        Edition {
            orgl: OrglRoot::from_bulk_entries(new_entries, None, new_domain),
            endorsements: self.endorsements.clone(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    pub fn iter(&self) -> impl Iterator<Item = (i64, Arc<Carrier>)> {
        self.orgl.all_entries().into_iter()
    }

    pub fn entries_btreemap(&self) -> BTreeMap<i64, Carrier> {
        self.orgl
            .all_entries()
            .into_iter()
            .map(|(p, c)| (p, (*c).clone()))
            .collect()
    }

    pub fn to_text(&self) -> String {
        let entries = self.cached_entries();
        let mut result =
            String::with_capacity(entries.iter().map(|(_, c)| c.char_len()).sum::<usize>());
        for (_, carrier) in entries {
            if let Some(s) = carrier.element.as_text() {
                result.push_str(s);
            }
        }
        result
    }

    /// Scan edition for RangeElement::Blob entries and return their
    /// character position + metadata. Character position is the offset
    /// in the rendered text string where the image should appear.
    pub fn blob_entries(&self) -> Vec<BlobEntry> {
        let mut result = Vec::new();
        let mut char_pos = 0usize;
        for (_, carrier) in self.all_entries().iter() {
            match &carrier.element {
                crate::edition::range_element::RangeElement::Blob {
                    content_hash,
                    mime_type,
                    byte_size,
                    width,
                    height,
                    caption,
                } => {
                    result.push(BlobEntry {
                        char_position: char_pos,
                        content_hash: *content_hash,
                        mime_type: mime_type.clone(),
                        byte_size: *byte_size,
                        width: *width,
                        height: *height,
                        caption: caption.clone(),
                    });
                }
                crate::edition::range_element::RangeElement::Text { text } => {
                    char_pos += text.chars().count();
                }
                crate::edition::range_element::RangeElement::Transclusion { .. } => {
                    // Transclusion elements don't contribute to text length
                    // in the flat representation
                }
                _ => {}
            }
        }
        result
    }

    pub fn to_text_range(&self, start_char: usize, end_char: usize) -> String {
        let entries = self.cached_entries();
        if entries.is_empty() || start_char >= end_char {
            return String::new();
        }
        let mut cum = 0usize;
        let mut result = String::new();
        for (_, carrier) in entries.iter() {
            let entry_char_len = carrier.char_len();
            if cum >= end_char {
                break;
            }
            if cum + entry_char_len <= start_char {
                cum += entry_char_len;
                continue;
            }
            if let Some(s) = carrier.element.as_text() {
                let local_start = start_char.saturating_sub(cum);
                let local_end = if cum + entry_char_len >= end_char {
                    end_char.saturating_sub(cum)
                } else {
                    entry_char_len
                };
                let byte_start = s
                    .char_indices()
                    .nth(local_start)
                    .map(|(i, _)| i)
                    .unwrap_or(s.len());
                let byte_end = s
                    .char_indices()
                    .nth(local_end)
                    .map(|(i, _)| i)
                    .unwrap_or(s.len());
                result.push_str(&s[byte_start..byte_end]);
            }
            cum += entry_char_len;
        }
        result
    }

    pub fn char_len(&self) -> usize {
        // O(1) from the cache tail: last cumulative start + last
        // entry's length (FR-50 A3 — was O(entries) per call, and
        // this is called per keystroke and per query).
        let starts = self.cached_char_starts();
        let entries = self.cached_entries();
        match (starts.last(), entries.last()) {
            (Some(&s), Some((_, c))) => s + c.char_len(),
            _ => 0,
        }
    }

    /// License classes covering a char span, computed from ground truth
    /// (FR-38 Phase 1): each entry in the span resolves to (provenance
    /// owner -> owner's license). This is the authoritative per-span
    /// query the FR-38 overlay accelerates; owner resolution is the
    /// caller's concern (the server maps club ids to works/licenses),
    /// passed as a resolver closure.
    ///
    /// Zero-char entries adopt the ongoing run's class (they don't
    /// fragment ownership). Entries with unresolvable owners contribute
    /// UNKNOWN — the safe default; licenses are display-only per FR-24.
    pub fn span_license_classes<F>(
        &self,
        char_start: usize,
        char_end: usize,
        owner_license: F,
    ) -> SpanLicenseSummary
    where
        F: Fn(BeId) -> Option<License>,
    {
        let entries = self.cached_entries();
        let starts = self.cached_char_starts();
        let mut summary = SpanLicenseSummary::default();

        // Zero-width spans cover nothing (harmonized with the FR-38
        // overlay; previously the entry containing the start leaked in).
        if char_start >= char_end {
            return summary;
        }

        let mut current_owner: Option<BeId> = None;
        let mut run_started = false;
        let mut run_start = char_start;

        for (idx, (_, carrier)) in entries.iter().enumerate() {
            let entry_start = starts[idx];
            let entry_len = carrier.char_len();
            let entry_end = entry_start + entry_len;

            if entry_len == 0 {
                continue;
            }
            if entry_end <= char_start {
                continue;
            }
            if entry_start >= char_end {
                break;
            }

            let overlap_start = entry_start.max(char_start);
            let (class, owner) = match &carrier.provenance {
                Some(p) => match owner_license(p.author_club_id) {
                    Some(l) => (l.license_class(), Some(p.author_club_id)),
                    None => (super::work::LicenseClass::UNKNOWN, Some(p.author_club_id)),
                },
                None => (super::work::LicenseClass::UNKNOWN, None),
            };

            if !run_started || owner != current_owner {
                if run_started {
                    summary.boundaries.push((
                        run_start,
                        overlap_start,
                        current_owner,
                        summary.pending_class,
                    ));
                }
                run_start = overlap_start;
                run_started = true;
                current_owner = owner;
                summary.pending_class = super::work::LicenseClass::default();
                summary.distinct_owners += 1;
            }
            summary.pending_class = summary.pending_class.combine(class);
            if class.contains(super::work::LicenseClass::UNKNOWN) {
                summary.unresolved_entries += 1;
            }
            summary.total_class = summary.total_class.combine(class);
        }
        if run_started {
            summary
                .boundaries
                .push((run_start, char_end, current_owner, summary.pending_class));
        }
        summary
    }

    /// Build the ownership overlay for this edition (FR-38 Phase 2).
    /// O(n) over the cached entries; callers on the server side cache
    /// the result keyed by content generation.
    pub fn license_overlay(&self) -> super::license_overlay::LicenseOverlay {
        super::license_overlay::LicenseOverlay::build(
            self.cached_entries(),
            self.cached_char_starts(),
        )
    }

    pub fn crum(&self) -> Option<crate::edition::orgl::Crum> {
        self.orgl.crum()
    }

    /// Apply a batch of entry-level edits via tree operations.
    ///
    /// Each edit is applied via `OrglRoot::with()` / `without()` — O(log n)
    /// per edit. After all edits, positions are renumbered to sequential
    /// integers (O(n)).
    ///
    /// For small edit batches (k << n), this is O(k log n + n) — faster than
    /// the text-delta path which is O(n) for every edit.
    ///
    /// When tumbler positions arrive (Phase I), the renumbering step
    /// is eliminated, making this O(k log n).
    pub fn apply_edits(&self, edits: &[EditionEdit]) -> Edition {
        let mut orgl = self.orgl.clone();
        for edit in edits {
            match edit {
                EditionEdit::Insert(pos, element) => {
                    orgl = orgl.with(*pos, Arc::new(Carrier::new(element.clone())));
                }
                EditionEdit::Delete(pos) => {
                    orgl = orgl.without(*pos);
                }
                EditionEdit::Replace(pos, element) => {
                    orgl = orgl.with(*pos, Arc::new(Carrier::new(element.clone())));
                }
            }
        }
        let entries = orgl.all_entries();
        let renumbered: Vec<(i64, Arc<Carrier>)> = entries
            .into_iter()
            .enumerate()
            .map(|(i, (_, c))| (i as i64, c))
            .collect();
        Edition::from_entries(renumbered)
    }

    /// Splay the tree around a region for locality optimization.
    /// Returns a new Edition with the tree restructured so that entries
    /// in the given region are co-located under a single subtree.
    ///
    /// After splaying, subsequent operations on the same region
    /// (fetch, diff, copy) descend into only one branch — O(log k)
    /// instead of O(log n) where k = region size.
    pub fn splayed(&self, region: &XnRegion) -> (Edition, crate::edition::orgl::SplayResult) {
        let mut orgl = self.orgl.clone();
        let result = orgl.splay(region);
        let edition = Edition {
            orgl,
            endorsements: self.endorsements.clone(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: self.span_provenance.clone(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        };
        (edition, result)
    }

    pub fn entry_identities(&self) -> Vec<EntryIdentity> {
        self.cached_entries()
            .iter()
            .map(|(pos, carrier)| EntryIdentity {
                position: *pos,
                content_fingerprint: carrier.element.content_fingerprint(),
                has_provenance: carrier.provenance.is_some(),
                is_text: matches!(carrier.element, RangeElement::Text { .. }),
            })
            .collect()
    }

    /// Compute a crum for a range of entries within the edition.
    /// Enables section-level comparison: two editions can be compared
    /// section-by-section by computing range crums.
    pub fn range_crum(&self, start_pos: i64, end_pos: i64) -> Option<crate::edition::orgl::Crum> {
        let entries = self.cached_entries();
        let filtered: Vec<_> = entries
            .iter()
            .filter(|(pos, _)| *pos >= start_pos && *pos < end_pos)
            .cloned()
            .collect();
        if filtered.is_empty() {
            return None;
        }
        let region = XnRegion::interval(start_pos, end_pos);
        Some(crate::edition::orgl::compute_leaf_crum(
            &filtered, &region, &None,
        ))
    }

    /// Get entries within a position range.
    pub fn entries_in_range(&self, start_pos: i64, end_pos: i64) -> Vec<(i64, Arc<Carrier>)> {
        self.cached_entries()
            .iter()
            .filter(|(pos, _)| *pos >= start_pos && *pos < end_pos)
            .cloned()
            .collect()
    }

    /// Partition entries into fixed-size chunks and compute a crum per chunk.
    /// Enables block-level comparison: "first 64 entries are identical" → skip.
    pub fn chunk_crums(&self, chunk_size: usize) -> Vec<(i64, i64, crate::edition::orgl::Crum)> {
        if chunk_size == 0 {
            return Vec::new();
        }
        let entries = self.cached_entries();
        let mut result = Vec::new();
        let mut i = 0;
        while i < entries.len() {
            let chunk_end = (i + chunk_size).min(entries.len());
            let start_pos = entries[i].0;
            let end_pos = if chunk_end < entries.len() {
                entries[chunk_end].0
            } else {
                entries[chunk_end - 1].0 + 1
            };
            let chunk: Vec<_> = entries[i..chunk_end].to_vec();
            let region = XnRegion::interval(start_pos, end_pos);
            let crum = crate::edition::orgl::compute_leaf_crum(&chunk, &region, &None);
            result.push((start_pos, end_pos, crum));
            i = chunk_end;
        }
        result
    }

    /// Compare two editions at the block level using chunk crums.
    /// Returns (matching_blocks, differing_blocks) as position ranges.
    pub fn chunk_diff(
        &self,
        other: &Edition,
        chunk_size: usize,
    ) -> (Vec<(i64, i64)>, Vec<(i64, i64)>) {
        let my_crums = self.chunk_crums(chunk_size);
        let other_crums = other.chunk_crums(chunk_size);
        let mut matching = Vec::new();
        let mut differing = Vec::new();

        let other_map: std::collections::HashMap<&crate::edition::orgl::Crum, (i64, i64)> =
            other_crums.iter().map(|(s, e, c)| (c, (*s, *e))).collect();

        for (start, end, crum) in &my_crums {
            if other_map.contains_key(crum) {
                matching.push((*start, *end));
            } else {
                differing.push((*start, *end));
            }
        }
        (matching, differing)
    }

    pub fn extract_outline(&self) -> Vec<OutlineEntry> {
        let text = self.to_text();
        let mut results = Vec::new();
        let mut line = 0u64;
        let mut char_offset = 0usize;
        for text_line in text.split('\n') {
            let trimmed = text_line.trim_start();
            if !trimmed.is_empty() {
                if let Some(entry) = Self::parse_heading(trimmed, line, char_offset) {
                    results.push(entry);
                }
            }
            char_offset += text_line.len() + 1;
            line += 1;
        }
        results
    }

    fn parse_heading(line: &str, line_num: u64, char_offset: usize) -> Option<OutlineEntry> {
        let trimmed = line.trim_start();
        if let Some(rest) = trimmed.strip_prefix('#') {
            let level = 1 + rest.chars().take_while(|c| *c == '#').count();
            let text = rest[level - 1..].trim();
            if !text.is_empty() && level <= 6 {
                return Some(OutlineEntry {
                    level: level as u32,
                    text: text.to_string(),
                    line: line_num,
                    char_offset: char_offset as u64,
                });
            }
        }
        let lower = trimmed.to_ascii_lowercase();
        for (prefix, level) in [("part ", 1u32), ("chapter ", 2), ("section ", 3)] {
            if lower.starts_with(prefix) {
                return Some(OutlineEntry {
                    level,
                    text: trimmed.to_string(),
                    line: line_num,
                    char_offset: char_offset as u64,
                });
            }
        }
        None
    }

    pub fn search_text(&self, query: &str, max_results: usize) -> Vec<SearchMatch> {
        let full_text = self.to_text();
        let lower_text = full_text.to_ascii_lowercase();
        let lower_query = query.to_ascii_lowercase();
        let mut results = Vec::new();
        let mut pos = 0;
        while pos < lower_text.len() && results.len() < max_results {
            if let Some(idx) = lower_text[pos..].find(&lower_query) {
                let abs_idx = pos + idx;
                let line = full_text[..abs_idx].matches('\n').count() as u64;
                let mut ctx_start = abs_idx.saturating_sub(40);
                while ctx_start < abs_idx && !full_text.is_char_boundary(ctx_start) {
                    ctx_start += 1;
                }
                let mut ctx_end = (abs_idx + lower_query.len() + 40).min(full_text.len());
                while ctx_end > ctx_start && !full_text.is_char_boundary(ctx_end) {
                    ctx_end -= 1;
                }
                let context = full_text[ctx_start..ctx_end].to_string();
                results.push(SearchMatch {
                    char_offset: abs_idx as u64,
                    line,
                    context,
                });
                pos = abs_idx + lower_query.len();
            } else {
                break;
            }
        }
        results
    }

    pub fn get_context(&self, target_line: u64, context_lines: u64) -> (u64, u64, String) {
        let entries = self.cached_entries();
        let mut cum = 0usize;
        let mut line = 0u64;
        let mut target_char = 0u64;
        let mut found = false;
        for (_, carrier) in entries.iter() {
            if let Some(text) = carrier.element.as_text() {
                for (i, _nl) in text.match_indices('\n') {
                    if !found && line == target_line {
                        target_char = (cum + i) as u64;
                        found = true;
                    }
                    line += 1;
                }
                if !found && line == target_line {
                    target_char = (cum + text.len()) as u64;
                    found = true;
                }
            }
            cum += carrier.char_len();
        }
        let start_line = target_line.saturating_sub(context_lines);
        let text = self.to_text();
        let mut lines_iter = text.lines().enumerate();
        let mut result_lines = Vec::new();
        let mut actual_start = start_line;
        for (i, l) in lines_iter.by_ref() {
            if i as u64 >= start_line {
                actual_start = i as u64;
                result_lines.push(l);
                break;
            }
        }
        let mut count = 1u64;
        for (_, l) in lines_iter {
            if count >= context_lines * 2 + 1 {
                break;
            }
            result_lines.push(l);
            count += 1;
        }
        (actual_start, target_char, result_lines.join("\n"))
    }

    pub fn coalesce(&self) -> Edition {
        let entries = self.orgl.all_entries();
        if entries.len() <= 1 {
            return self.clone();
        }

        let mut merged: Vec<(i64, Arc<Carrier>)> = Vec::with_capacity(entries.len());
        let mut pos = 0i64;
        let mut i = 0usize;

        while i < entries.len() {
            let (_, carrier) = &entries[i];
            let text = match &carrier.element {
                RangeElement::Text { text } => text.clone(),
                _ => {
                    merged.push((pos, carrier.clone()));
                    pos += 1;
                    i += 1;
                    continue;
                }
            };

            let prov = carrier.provenance.clone();
            let label = carrier.label.clone();
            let mut combined = text;
            let mut end = i + 1;

            while end < entries.len() {
                let (_, next) = &entries[end];
                if next.provenance != prov || next.label != label {
                    break;
                }
                match &next.element {
                    RangeElement::Text { text: t } => {
                        combined.push_str(t);
                        end += 1;
                    }
                    _ => break,
                }
            }

            let mut c = Carrier::new(RangeElement::text(combined));
            c.label = label;
            c.provenance = prov;
            merged.push((pos, Arc::new(c)));
            pos += 1;
            i = end;
        }

        Edition::from_entries(merged)
    }

    pub fn word_set(&self) -> HashSet<String> {
        let text = self.to_text();
        text.split_whitespace()
            .map(|w| w.to_lowercase())
            .filter(|w| !is_stop_word(w))
            .collect()
    }

    pub fn shared_region(&self, other: &Edition) -> XnRegion {
        self.orgl.shared_region(&other.orgl)
    }

    pub fn identity_shared_region<F>(&self, other: &Edition, id_eq: F) -> XnRegion
    where
        F: Fn(&Carrier, &Carrier) -> bool,
    {
        let my_entries = self.orgl.all_entries();
        let other_entries = other.orgl.all_entries();
        let mut region = XnRegion::empty();
        for (pos, carrier) in &my_entries {
            if let Some(idx) = other_entries.binary_search_by_key(pos, |(p, _)| *p).ok() {
                if id_eq(carrier, &other_entries[idx].1) {
                    region = region.with(*pos);
                }
            }
        }
        region
    }

    pub fn shared_with(&self, other: &Edition) -> Edition {
        let my_entries = self.orgl.all_entries();
        let other_entries = other.orgl.all_entries();
        let mut orgl = OrglRoot::empty();
        for (pos, carrier) in &my_entries {
            if let Some(idx) = other_entries.binary_search_by_key(pos, |(p, _)| *p).ok() {
                if *carrier == other_entries[idx].1 {
                    orgl = orgl.with(*pos, carrier.clone());
                }
            }
        }
        Edition {
            orgl,
            endorsements: EndorsementSet::new(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    pub fn not_shared_with(&self, other: &Edition) -> Edition {
        let my_entries = self.orgl.all_entries();
        let other_entries = other.orgl.all_entries();
        let mut orgl = OrglRoot::empty();
        for (pos, carrier) in &my_entries {
            let differs = match other_entries.binary_search_by_key(pos, |(p, _)| *p) {
                Ok(idx) => *carrier != other_entries[idx].1,
                Err(_) => true,
            };
            if differs {
                orgl = orgl.with(*pos, carrier.clone());
            }
        }
        Edition {
            orgl,
            endorsements: EndorsementSet::new(),
            entries_cache: Arc::new(OnceLock::new()),
            span_provenance: Vec::new(),
            span_status_cache: Arc::new(std::sync::Mutex::new(None)),
        }
    }

    pub fn map_shared_to(&self, other: &Edition) -> BTreeMap<i64, i64> {
        let my_entries = self.orgl.all_entries();
        let other_entries = other.orgl.all_entries();
        let mut mapping = BTreeMap::new();
        for (pos, carrier) in &my_entries {
            for (other_pos, other_carrier) in &other_entries {
                if *carrier == *other_carrier {
                    mapping.insert(*pos, *other_pos);
                }
            }
        }
        mapping
    }

    pub fn content_shared_region(&self, other: &Edition) -> XnRegion {
        content_shared_region(&self.orgl.all_entries(), &other.orgl.all_entries())
    }

    pub fn content_map_shared_to(&self, other: &Edition) -> SharedMapping {
        content_map_shared_to(&self.orgl.all_entries(), &other.orgl.all_entries())
    }

    pub fn content_map_shared_onto(&self, other: &Edition) -> SharedMapping {
        content_map_shared_onto(&self.orgl.all_entries(), &other.orgl.all_entries())
    }

    pub fn positions_of(&self, value: &RangeElement) -> XnRegion {
        self.orgl.positions_of(&Carrier::new(value.clone()))
    }

    pub fn is_range_identical(&self, other: &Edition, region: Option<&XnRegion>) -> bool {
        let dom = match region {
            Some(r) => r.clone(),
            None => self.domain().union(&other.domain()),
        };
        for (start, stop) in dom.intervals() {
            for pos in start..stop {
                let a = self.orgl.fetch(pos);
                let b = other.orgl.fetch(pos);
                if a != b {
                    return false;
                }
            }
        }
        true
    }

    pub fn positions_labelled(&self, label_id: u64) -> XnRegion {
        let entries = self.orgl.all_entries();
        let mut region = XnRegion::empty();
        for (pos, carrier) in &entries {
            if carrier.element.label_id_value() == Some(label_id) {
                region = region.with(*pos);
            }
        }
        region
    }

    pub fn fetch_labelled(&self, label_id: u64) -> Option<(i64, RangeElement)> {
        let entries = self.orgl.all_entries();
        for (pos, carrier) in &entries {
            if carrier.element.label_id_value() == Some(label_id) {
                if let Some(inner) = carrier.element.as_label_inner() {
                    return Some((*pos, inner.clone()));
                }
                return Some((*pos, carrier.element.clone()));
            }
        }
        None
    }

    pub fn retrieve(&self, region: Option<&XnRegion>, flags: RetrieveFlags) -> Vec<Bundle> {
        let entries = self.orgl.all_entries();
        retrieve_bundles(&entries, region, flags)
    }

    pub fn cost(&self, method: CostMethod) -> StorageCost {
        let entries = self.orgl.all_entries();
        compute_storage_cost(&entries, &std::collections::HashMap::new(), method)
    }

    pub fn cost_with_shares(
        &self,
        content_share_counts: &std::collections::HashMap<u64, u64>,
        method: CostMethod,
    ) -> StorageCost {
        let entries = self.orgl.all_entries();
        compute_storage_cost(&entries, content_share_counts, method)
    }

    pub fn ordered_bundles(&self, region: Option<&XnRegion>) -> Vec<Bundle> {
        let search_region = region.cloned().unwrap_or_else(|| self.domain());
        super::bundle_stepper::loaf_bundle_stepper(self.orgl.loaf(), &search_region).collect_all()
    }

    pub fn ordered_merge_bundles(&self, region: Option<&XnRegion>) -> Vec<Bundle> {
        let search_region = region.cloned().unwrap_or_else(|| self.domain());
        super::bundle_stepper::loaf_merge_stepper(self.orgl.loaf(), &search_region).collect_all()
    }

    pub fn range_transcluders(
        &self,
        region: Option<&XnRegion>,
        direct_only: bool,
        index: &super::transclusion::TransclusionIndex,
    ) -> Vec<u64> {
        let query =
            super::range_transclusion::RangeTransclusionQuery::new().direct_only(direct_only);
        let query = match region {
            Some(r) => query.with_region(r.clone()),
            None => query,
        };
        let tq = super::transclusion::TransclusionQuery::all();
        let result = super::range_transclusion::range_transcluders(self, &query, index, &tq);
        result.edition_ids
    }

    pub fn range_works(
        &self,
        region: Option<&XnRegion>,
        index: &super::transclusion::TransclusionIndex,
    ) -> Vec<u64> {
        let query = super::range_transclusion::RangeTransclusionQuery::new();
        let query = match region {
            Some(r) => query.with_region(r.clone()),
            None => query,
        };
        let wq = super::transclusion::WorkQuery::all();
        let result = super::range_transclusion::range_works(self, &query, index, &wq);
        result.work_ids
    }

    pub fn transclusion_depth(
        &self,
        position: i64,
        index: &super::transclusion::TransclusionIndex,
        max_depth: usize,
    ) -> usize {
        match self.fetch(position) {
            Some(element) => {
                super::range_transclusion::count_transclusion_depth(&element, index, max_depth)
            }
            None => 0,
        }
    }

    pub fn deeply_transcluded_elements(
        &self,
        region: &XnRegion,
        index: &super::transclusion::TransclusionIndex,
        min_depth: usize,
    ) -> Vec<(i64, RangeElement, usize)> {
        super::range_transclusion::find_deeply_transcluded(self, region, index, min_depth)
    }

    pub fn content_fingerprint_counts(&self) -> std::collections::HashMap<u64, u64> {
        let entries = self.orgl.all_entries();
        let mut counts = std::collections::HashMap::new();
        for (_, carrier) in &entries {
            let fp = fingerprint_u64(&carrier.element);
            *counts.entry(fp).or_insert(0) += 1;
        }
        counts
    }

    pub fn total_byte_size(&self) -> u64 {
        let entries = self.orgl.all_entries();
        entries
            .iter()
            .map(|(_, c)| element_byte_size(&c.element))
            .sum()
    }

    pub fn find_content_shared_regions(
        &self,
        other: &Edition,
        min_run: usize,
    ) -> Vec<(i64, i64, i64, i64, String)> {
        let entries_a = self.cached_entries();
        let entries_b = other.cached_entries();
        if entries_a.is_empty() || entries_b.is_empty() || min_run == 0 {
            return Vec::new();
        }

        let fps_a: Vec<[u8; 32]> = entries_a
            .iter()
            .map(|(_, c)| c.element.content_fingerprint())
            .collect();
        let fps_b: Vec<[u8; 32]> = entries_b
            .iter()
            .map(|(_, c)| c.element.content_fingerprint())
            .collect();

        let mut fp_to_b: std::collections::HashMap<[u8; 32], Vec<usize>> =
            std::collections::HashMap::new();
        for (j, fp) in fps_b.iter().enumerate() {
            fp_to_b.entry(*fp).or_default().push(j);
        }

        let mut run_at_a: Vec<Option<(usize, usize)>> = vec![None; entries_a.len()];

        for i in 0..entries_a.len() {
            if run_at_a[i].is_some() {
                continue;
            }
            let b_cands = match fp_to_b.get(&fps_a[i]) {
                Some(v) => v,
                None => continue,
            };
            for &j in b_cands {
                let mut len = 1usize;
                while i + len < fps_a.len()
                    && j + len < fps_b.len()
                    && fps_a[i + len] == fps_b[j + len]
                {
                    len += 1;
                }
                if len >= min_run {
                    run_at_a[i] = Some((j, len));
                    break;
                }
            }
        }

        let mut seeds: Vec<(usize, usize, usize)> = Vec::new();
        for i in 0..entries_a.len() {
            if let Some((j, len)) = run_at_a[i] {
                seeds.push((i, j, len));
            }
        }

        seeds.sort_by(|a, b| b.2.cmp(&a.2));

        let mut results = Vec::new();
        let mut claimed_a = vec![false; entries_a.len()];
        let mut claimed_b = vec![false; entries_b.len()];

        for (i, j, len) in &seeds {
            let mut conflict = false;
            for k in 0..*len {
                if claimed_a[i + k] || claimed_b[j + k] {
                    conflict = true;
                    break;
                }
            }
            if conflict {
                continue;
            }
            for k in 0..*len {
                claimed_a[i + k] = true;
                claimed_b[j + k] = true;
            }
            // Convert element indices to character offsets
            let pos_a_start: i64 = entries_a[..*i]
                .iter()
                .map(|(_, c)| c.char_len() as i64)
                .sum();
            let pos_a_end: i64 = pos_a_start
                + entries_a[*i..*i + *len]
                    .iter()
                    .map(|(_, c)| c.char_len() as i64)
                    .sum::<i64>();
            let pos_b_start: i64 = entries_b[..*j]
                .iter()
                .map(|(_, c)| c.char_len() as i64)
                .sum();
            let pos_b_end: i64 = pos_b_start
                + entries_b[*j..*j + *len]
                    .iter()
                    .map(|(_, c)| c.char_len() as i64)
                    .sum::<i64>();
            let text: String = entries_a[*i..*i + *len]
                .iter()
                .filter_map(|(_, c)| c.element.as_text())
                .collect();
            results.push((pos_a_start, pos_a_end, pos_b_start, pos_b_end, text));
        }

        results
    }
}

pub fn is_stop_word(word: &str) -> bool {
    matches!(
        word,
        "a" | "about"
            | "above"
            | "after"
            | "again"
            | "against"
            | "ain"
            | "all"
            | "am"
            | "an"
            | "and"
            | "any"
            | "are"
            | "aren"
            | "aren't"
            | "as"
            | "at"
            | "be"
            | "because"
            | "been"
            | "before"
            | "being"
            | "below"
            | "between"
            | "both"
            | "but"
            | "by"
            | "can"
            | "couldn"
            | "couldn't"
            | "d"
            | "did"
            | "didn"
            | "didn't"
            | "do"
            | "does"
            | "doesn"
            | "doesn't"
            | "doing"
            | "don"
            | "don't"
            | "down"
            | "during"
            | "each"
            | "few"
            | "for"
            | "from"
            | "further"
            | "had"
            | "hadn"
            | "hadn't"
            | "has"
            | "hasn"
            | "hasn't"
            | "have"
            | "haven"
            | "haven't"
            | "having"
            | "he"
            | "her"
            | "here"
            | "hers"
            | "herself"
            | "him"
            | "himself"
            | "his"
            | "how"
            | "i"
            | "if"
            | "in"
            | "into"
            | "is"
            | "isn"
            | "isn't"
            | "it"
            | "it's"
            | "its"
            | "itself"
            | "just"
            | "ll"
            | "m"
            | "ma"
            | "me"
            | "mightn"
            | "mightn't"
            | "more"
            | "most"
            | "mustn"
            | "mustn't"
            | "my"
            | "myself"
            | "needn"
            | "needn't"
            | "no"
            | "nor"
            | "not"
            | "now"
            | "o"
            | "of"
            | "off"
            | "on"
            | "once"
            | "only"
            | "or"
            | "other"
            | "our"
            | "ours"
            | "ourselves"
            | "out"
            | "over"
            | "own"
            | "re"
            | "s"
            | "same"
            | "shan"
            | "shan't"
            | "she"
            | "she's"
            | "should"
            | "should've"
            | "shouldn"
            | "shouldn't"
            | "so"
            | "some"
            | "such"
            | "t"
            | "than"
            | "that"
            | "that'll"
            | "the"
            | "their"
            | "theirs"
            | "them"
            | "themselves"
            | "then"
            | "there"
            | "these"
            | "they"
            | "this"
            | "those"
            | "through"
            | "to"
            | "too"
            | "under"
            | "until"
            | "up"
            | "ve"
            | "very"
            | "was"
            | "wasn"
            | "wasn't"
            | "we"
            | "were"
            | "weren"
            | "weren't"
            | "what"
            | "when"
            | "where"
            | "which"
            | "while"
            | "who"
            | "whom"
            | "why"
            | "will"
            | "with"
            | "won"
            | "won't"
            | "would"
            | "wouldn"
            | "wouldn't"
            | "y"
            | "you"
            | "you'd"
            | "you'll"
            | "you're"
            | "you've"
            | "your"
            | "yours"
            | "yourself"
            | "yourselves"
    )
}

pub fn jaccard_similarity(a: &HashSet<String>, b: &HashSet<String>) -> f64 {
    if a.is_empty() && b.is_empty() {
        return 0.0;
    }
    let intersection = a.intersection(b).count() as f64;
    let union = a.union(b).count() as f64;
    if union == 0.0 {
        return 0.0;
    }
    intersection / union
}

#[derive(Debug, Clone, PartialEq)]
pub struct CombineConflict {
    pub position: i64,
    pub left: RangeElement,
    pub right: RangeElement,
}

impl std::fmt::Display for CombineConflict {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "combine conflict at position {}", self.position)
    }
}

impl std::error::Error for CombineConflict {}

#[cfg(feature = "serde")]
mod serde_u64_helpers {
    pub fn ser_u64_string<S: serde::Serializer>(v: &u64, s: S) -> Result<S::Ok, S::Error> {
        s.serialize_str(&v.to_string())
    }

    pub fn de_u64_string_or_int<'de, D: serde::Deserializer<'de>>(d: D) -> Result<u64, D::Error> {
        struct V;
        impl serde::de::Visitor<'_> for V {
            type Value = u64;
            fn expecting(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
                f.write_str("u64 as string or integer")
            }
            fn visit_str<E: serde::de::Error>(self, v: &str) -> Result<u64, E> {
                v.parse().map_err(E::custom)
            }
            fn visit_u64<E: serde::de::Error>(self, v: u64) -> Result<u64, E> {
                Ok(v)
            }
        }
        d.deserialize_any(V)
    }
}

#[cfg(feature = "serde")]
use serde_u64_helpers::{de_u64_string_or_int, ser_u64_string};

#[cfg(test)]
mod tests {
    use super::*;

    fn fetch_text(edition: &Edition, pos: i64) -> Option<String> {
        edition
            .fetch(pos)
            .and_then(|e| e.as_text().map(|s| s.to_string()))
    }

    #[test]
    fn empty_edition() {
        let e = Edition::empty();
        assert!(e.is_empty());
        assert_eq!(e.count(), 0);
        assert!(e.domain().is_empty());
        assert!(e.fetch_owned(0).is_none());
    }

    #[test]
    fn from_one() {
        let e = Edition::from_one(5, RangeElement::text("x"));
        assert!(!e.is_empty());
        assert_eq!(e.count(), 1);
        assert!(e.has_position(5));
        assert!(!e.has_position(4));
        assert_eq!(fetch_text(&e, 5), Some("x".to_string()));
    }

    #[test]
    fn from_text() {
        let e = Edition::from_text("abc");
        assert_eq!(e.count(), 3);
        assert_eq!(e.to_text(), "abc");
    }

    #[test]
    fn from_text_elements() {
        let elems = vec![
            RangeElement::text("H"),
            RangeElement::text("i"),
            RangeElement::text("!"),
        ];
        let e = Edition::from_text_elements(&elems);
        assert_eq!(e.count(), 3);
        assert_eq!(e.to_text(), "Hi!");
    }

    #[test]
    fn with_adds_position() {
        let e = Edition::empty()
            .with(0, RangeElement::text("a"))
            .with(1, RangeElement::text("b"));
        assert_eq!(e.count(), 2);
        assert_eq!(fetch_text(&e, 0), Some("a".to_string()));
        assert_eq!(fetch_text(&e, 1), Some("b".to_string()));
    }

    #[test]
    fn without_removes_position() {
        let e = Edition::from_text("abc");
        let e2 = e.without(1);
        assert_eq!(e2.count(), 2);
        assert!(e2.has_position(0));
        assert!(!e2.has_position(1));
        assert!(e2.has_position(2));
    }

    #[test]
    fn with_all_fills_region() {
        let region = XnRegion::interval(0, 5);
        let e = Edition::empty().with_all(&region, RangeElement::text("x"));
        assert_eq!(e.count(), 5);
        for i in 0..5 {
            assert_eq!(fetch_text(&e, i), Some("x".to_string()));
        }
    }

    #[test]
    fn without_all_clears_region() {
        let e = Edition::from_text("abcde");
        let region = XnRegion::interval(1, 4);
        let e2 = e.without_all(&region);
        assert_eq!(e2.count(), 2);
        assert!(e2.has_position(0));
        assert!(!e2.has_position(1));
        assert!(!e2.has_position(2));
        assert!(!e2.has_position(3));
        assert!(e2.has_position(4));
    }

    #[test]
    fn combine_disjoint() {
        let a = Edition::from_one(0, RangeElement::text("a"));
        let b = Edition::from_one(1, RangeElement::text("b"));
        let c = a.combine(&b).unwrap();
        assert_eq!(c.count(), 2);
        assert_eq!(fetch_text(&c, 0), Some("a".to_string()));
        assert_eq!(fetch_text(&c, 1), Some("b".to_string()));
    }

    #[test]
    fn combine_conflict() {
        let a = Edition::from_one(0, RangeElement::text("a"));
        let b = Edition::from_one(0, RangeElement::text("b"));
        let err = a.combine(&b).unwrap_err();
        assert_eq!(err.position, 0);
    }

    #[test]
    fn combine_same_value_succeeds() {
        let a = Edition::from_one(0, RangeElement::text("x"));
        let b = Edition::from_one(0, RangeElement::text("x"));
        let c = a.combine(&b).unwrap();
        assert_eq!(c.count(), 1);
    }

    #[test]
    fn replace_overwrites() {
        let a = Edition::from_text("abc");
        let b = Edition::from_one(1, RangeElement::text("X"));
        let c = a.replace(&b);
        assert_eq!(c.to_text(), "aXc");
    }

    #[test]
    fn copy_subset() {
        let e = Edition::from_text("abcde");
        let region = XnRegion::interval(1, 4);
        let sub = e.copy(&region);
        assert_eq!(sub.count(), 3);
        assert!(!sub.has_position(0));
        assert!(sub.has_position(1));
        assert!(sub.has_position(2));
        assert!(sub.has_position(3));
        assert!(!sub.has_position(4));
    }

    #[test]
    fn transformed_by_shifts() {
        let e = Edition::from_text("abc");
        let e2 = e.transformed_by(10);
        assert_eq!(e2.count(), 3);
        assert!(!e2.has_position(0));
        assert!(e2.has_position(10));
        assert!(e2.has_position(11));
        assert!(e2.has_position(12));
    }

    #[test]
    fn shared_region_finds_common() {
        let a = Edition::from_text("abc");
        let b = Edition::from_text("xbc");
        let shared = a.shared_region(&b);
        assert!(shared.contains(1));
        assert!(shared.contains(2));
        assert!(!shared.contains(0));
    }

    #[test]
    fn shared_with_returns_common_entries() {
        let a = Edition::from_text("abc");
        let b = Edition::from_text("xbc");
        let shared = a.shared_with(&b);
        assert_eq!(shared.count(), 2);
        assert_eq!(fetch_text(&shared, 1), Some("b".to_string()));
        assert_eq!(fetch_text(&shared, 2), Some("c".to_string()));
    }

    #[test]
    fn not_shared_with_returns_differences() {
        let a = Edition::from_text("abc");
        let b = Edition::from_text("xbc");
        let diff = a.not_shared_with(&b);
        assert_eq!(diff.count(), 1);
        assert_eq!(fetch_text(&diff, 0), Some("a".to_string()));
    }

    #[test]
    fn map_shared_to() {
        let a = Edition::from_text("abc");
        let b = a.transformed_by(5);
        let mapping = a.map_shared_to(&b);
        assert_eq!(mapping.get(&0), Some(&5));
        assert_eq!(mapping.get(&1), Some(&6));
        assert_eq!(mapping.get(&2), Some(&7));
    }

    #[test]
    fn positions_of() {
        let e = Edition::empty()
            .with(0, RangeElement::text("x"))
            .with(1, RangeElement::text("y"))
            .with(2, RangeElement::text("x"));
        let pos = e.positions_of(&RangeElement::text("x"));
        assert!(pos.contains(0));
        assert!(!pos.contains(1));
        assert!(pos.contains(2));
    }

    #[test]
    fn is_range_identical() {
        let a = Edition::from_text("abc");
        let b = Edition::from_text("abc");
        assert!(a.is_range_identical(&b, None));

        let c = Edition::from_text("axc");
        assert!(!a.is_range_identical(&c, None));

        let region = XnRegion::interval(0, 1);
        assert!(a.is_range_identical(&c, Some(&region)));
    }

    #[test]
    fn find_content_shared_regions_basic() {
        let a = Edition::from_text("hello world");
        let b = Edition::from_text("say hello world now");
        let regions = a.find_content_shared_regions(&b, 2);
        assert!(!regions.is_empty());
        let (sa, ea, _sb, _eb, text) = &regions[0];
        assert_eq!(text, "hello world");
        assert_eq!(*sa, 0);
        assert_eq!(*ea, 11);
    }

    #[test]
    fn find_content_shared_regions_partial() {
        let a = Edition::from_text("the quick brown fox");
        let b = Edition::from_text("a quick blue fox");
        let regions = a.find_content_shared_regions(&b, 4);
        assert!(regions.len() >= 1);
        let texts: Vec<&str> = regions.iter().map(|r| r.4.as_str()).collect();
        assert!(
            texts
                .iter()
                .any(|t| t.contains("quick") || t.contains("fox")),
            "expected 'quick' or 'fox' in {:?}, find_content_shared_regions_partial):",
            texts
        );
    }

    #[test]
    fn find_content_shared_regions_min_run() {
        let a = Edition::from_text("abcdef");
        let b = Edition::from_text("abcxyz");
        let regions3 = a.find_content_shared_regions(&b, 4);
        assert!(
            regions3.is_empty(),
            "3-char match should not meet min_run=4"
        );
        let regions2 = a.find_content_shared_regions(&b, 2);
        assert!(!regions2.is_empty());
        assert!(regions2[0].4.contains("abc"));
    }

    #[test]
    fn find_content_shared_regions_empty() {
        let a = Edition::from_text("");
        let b = Edition::from_text("hello");
        assert!(a.find_content_shared_regions(&b, 4).is_empty());
        assert!(b.find_content_shared_regions(&a, 4).is_empty());
    }

    #[test]
    fn find_content_shared_regions_identical() {
        let a = Edition::from_text("same text");
        let b = Edition::from_text("same text");
        let regions = a.find_content_shared_regions(&b, 2);
        assert_eq!(regions.len(), 1);
        assert_eq!(regions[0].4, "same text");
        assert_eq!(regions[0].0, 0);
        assert_eq!(regions[0].1, 9);
        assert_eq!(regions[0].2, 0);
        assert_eq!(regions[0].3, 9);
    }

    #[test]
    fn find_content_shared_regions_shifted() {
        let a = Edition::from_text("hello");
        let b = Edition::from_text("xxhello");
        let regions = a.find_content_shared_regions(&b, 2);
        assert_eq!(regions.len(), 1);
        assert_eq!(regions[0].4, "hello");
        assert_eq!(regions[0].0, 0);
        assert_eq!(regions[0].1, 5);
        assert_eq!(regions[0].2, 2);
        assert_eq!(regions[0].3, 7);
    }

    #[test]
    fn find_content_shared_regions_multiple_runs() {
        let a = Edition::from_text("cat dog bird cat dog");
        let b = Edition::from_text("cat dog fish cat dog");
        let regions = a.find_content_shared_regions(&b, 3);
        assert!(
            regions.len() >= 2,
            "expected at least 2 shared runs, got {}: {:?}",
            regions.len(),
            regions
        );
    }

    #[test]
    fn find_content_shared_regions_with_blob() {
        let a = Edition::from_text_elements(&[
            RangeElement::text("a"),
            RangeElement::text("b"),
            RangeElement::Blob {
                content_hash: 42,
                mime_type: "image/png".into(),
                byte_size: 100,
                width: Some(10),
                height: Some(10),
                caption: None,
            },
            RangeElement::text("c"),
        ]);
        let b = Edition::from_text_elements(&[
            RangeElement::text("x"),
            RangeElement::text("b"),
            RangeElement::Blob {
                content_hash: 42,
                mime_type: "image/png".into(),
                byte_size: 100,
                width: Some(10),
                height: Some(10),
                caption: None,
            },
            RangeElement::text("c"),
        ]);
        let regions = a.find_content_shared_regions(&b, 2);
        assert!(!regions.is_empty(), "should find shared blob+text run");
    }

    #[test]
    fn place_holders_creates_identity() {
        let region = XnRegion::interval(0, 3);
        let e = Edition::place_holders(&region);
        assert_eq!(e.count(), 3);
        for i in 0..3 {
            let elem = e.fetch(i).unwrap();
            assert!(matches!(elem, RangeElement::PlaceHolder { .. }));
        }
    }

    #[test]
    fn domain_returns_all_keys() {
        let e = Edition::empty()
            .with(3, RangeElement::text("a"))
            .with(7, RangeElement::text("b"))
            .with(10, RangeElement::text("c"));
        let dom = e.domain();
        assert!(dom.contains(3));
        assert!(dom.contains(7));
        assert!(dom.contains(10));
        assert!(!dom.contains(0));
        assert_eq!(dom.count(), Some(3));
    }

    #[test]
    fn immutability_original_unchanged() {
        let e = Edition::from_text("abc");
        let _e2 = e.with(0, RangeElement::text("X"));
        assert_eq!(fetch_text(&e, 0), Some("a".to_string()));
    }

    #[test]
    fn from_all_creates_uniform() {
        let region = XnRegion::interval(0, 4);
        let e = Edition::from_all(&region, RangeElement::text("z"));
        for i in 0..4 {
            assert_eq!(fetch_text(&e, i), Some("z".to_string()));
        }
    }

    #[test]
    fn gold_placeholders_over_empty_region() {
        let e = Edition::place_holders(&XnRegion::empty());
        assert!(e.is_empty());
    }

    #[test]
    fn gold_from_one_with_data() {
        let e = Edition::from_one(2, RangeElement::data(vec![3]));
        assert_eq!(e.count(), 1);
        assert!(e.has_position(2));
    }

    #[test]
    fn gold_from_all_over_empty() {
        let e = Edition::from_all(&XnRegion::empty(), RangeElement::placeholder(0));
        assert!(e.is_empty());
    }

    #[test]
    fn gold_from_text_empty_string() {
        let e = Edition::from_text("");
        assert!(e.is_empty());
        assert_eq!(e.count(), 0);
    }

    #[test]
    fn gold_from_text_hello_world() {
        let e = Edition::from_text("hello world");
        assert_eq!(e.count(), 11);
        assert_eq!(e.to_text(), "hello world");
    }

    #[test]
    fn gold_from_text_shifted_domain() {
        let shifted = Edition::from_text("hello world!").transformed_by(10);
        assert_eq!(shifted.count(), 12);
        assert!(shifted.has_position(10));
        assert!(!shifted.has_position(0));
    }

    #[test]
    fn gold_with_all_then_without() {
        let e = Edition::empty()
            .with_all(&XnRegion::interval(0, 10), RangeElement::placeholder(0))
            .without(3);
        assert_eq!(e.count(), 9);
        assert!(!e.has_position(3));
        assert!(e.has_position(2));
        assert!(e.has_position(4));
    }

    #[test]
    fn gold_without_all_removes_above() {
        let e = Edition::empty()
            .with_all(&XnRegion::interval(0, 10), RangeElement::placeholder(0))
            .without_all(&XnRegion::above(2));
        assert_eq!(e.count(), 2);
        assert!(e.has_position(0));
        assert!(e.has_position(1));
        assert!(!e.has_position(2));
    }

    #[test]
    fn gold_combine_then_replace() {
        let edition = Edition::empty()
            .with(0, RangeElement::placeholder(0))
            .with(1, RangeElement::data(vec![65]));
        let other = Edition::from_one(5, RangeElement::placeholder(1));
        let combined = edition.combine(&other).unwrap();
        assert_eq!(combined.count(), 3);
        assert!(combined.has_position(0));
        assert!(combined.has_position(1));
        assert!(combined.has_position(5));

        let replacement = Edition::from_one(1, RangeElement::placeholder(1));
        let replaced = edition.replace(&replacement);
        assert_eq!(replaced.count(), 2);
    }

    #[test]
    fn gold_shared_region_with_subset_copy() {
        let a = Edition::from_text("abcdefghijklmnopqrstuvwxyz");
        let b = a.clone();
        let b_sub = b.copy(&XnRegion::interval(0, 5));
        assert_eq!(a.shared_region(&b_sub), XnRegion::interval(0, 5));
    }

    #[test]
    fn gold_shared_region_is_symmetric() {
        let a = Edition::from_text("hello");
        let b = Edition::from_text("hxllo");
        assert_eq!(a.shared_region(&b), b.shared_region(&a));
        assert_eq!(a.shared_with(&b), b.shared_with(&a));
    }

    #[test]
    fn gold_map_shared_to_shifted_edition() {
        let a = Edition::from_text("abc");
        let b = a.transformed_by(10);
        let mapping = a.map_shared_to(&b);
        assert_eq!(mapping.get(&0), Some(&10));
        assert_eq!(mapping.get(&1), Some(&11));
        assert_eq!(mapping.get(&2), Some(&12));
    }

    #[test]
    fn stress_large_edition_otree() {
        let mut e = Edition::empty();
        for i in 0..50_000 {
            e = e.with(i, RangeElement::text(format!("{i}")));
        }
        assert_eq!(e.count(), 50_000);
        assert!(e.has_position(25_000));
        assert_eq!(fetch_text(&e, 25_000), Some("25000".to_string()));
    }

    #[test]
    fn stress_splay_on_large_edition() {
        let mut e = Edition::empty();
        for i in 0..10_000 {
            e = e.with(i, RangeElement::text(format!("{i}")));
        }
        use crate::edition::orgl::SplayResult;
        let mut orgl = e.orgl.clone();
        let result = orgl.splay(&XnRegion::interval(1000, 2000));
        assert_eq!(result, SplayResult::Partial);
    }

    // === Infinite domain tests ===

    #[test]
    fn infinite_edition_from_all() {
        let e = Edition::from_all(&XnRegion::above(0), RangeElement::text("."));
        assert!(e.is_infinite());
        assert!(!e.is_finite());
        assert!(e.has_position(0));
        assert!(e.has_position(1000000));
        assert_eq!(fetch_text(&e, 42), Some(".".to_string()));
    }

    #[test]
    fn infinite_edition_override() {
        let e = Edition::from_all(&XnRegion::above(0), RangeElement::text("."))
            .with(5, RangeElement::text("X"));
        assert_eq!(fetch_text(&e, 5), Some("X".to_string()));
        assert_eq!(fetch_text(&e, 6), Some(".".to_string()));
    }

    #[test]
    fn infinite_edition_without() {
        let e = Edition::from_all(&XnRegion::above(0), RangeElement::text(".")).without(5);
        assert!(!e.has_position(5));
        assert!(e.has_position(4));
        assert!(e.has_position(6));
    }

    #[test]
    fn infinite_edition_with_default() {
        let e = Edition::with_default(XnRegion::interval(0, 100), RangeElement::text("?"));
        assert!(!e.is_infinite());
        assert!(e.has_position(50));
        assert_eq!(fetch_text(&e, 50), Some("?".to_string()));
    }

    #[test]
    fn infinite_edition_transformed() {
        let e = Edition::from_all(&XnRegion::above(0), RangeElement::text(".")).transformed_by(100);
        assert!(e.has_position(100));
        assert!(!e.has_position(0));
        assert_eq!(fetch_text(&e, 150), Some(".".to_string()));
    }

    #[test]
    fn infinite_edition_copy() {
        let e = Edition::from_all(&XnRegion::above(0), RangeElement::text("."));
        let sub = e.copy(&XnRegion::interval(0, 10));
        assert!(sub.has_position(5));
        assert!(!sub.has_position(10));
    }

    // === DspLoaf through Edition ===

    #[test]
    fn transformed_by_is_lazy_dsp() {
        let e = Edition::from_text("abc");
        let shifted = e.transformed_by(10);
        assert_eq!(shifted.count(), 3);
        assert!(shifted.has_position(10));
        assert_eq!(fetch_text(&shifted, 10), Some("a".to_string()));
    }

    #[test]
    fn transformed_chain_is_efficient() {
        let e = Edition::from_text("hello");
        let result = e.transformed_by(10).transformed_by(10).transformed_by(10);
        assert_eq!(fetch_text(&result, 30), Some("h".to_string()));
        assert_eq!(fetch_text(&result, 34), Some("o".to_string()));
    }

    #[test]
    fn identity_shared_region_by_be_id() {
        let e1 = Edition::from_one(0, RangeElement::edition(1))
            .with(1, RangeElement::edition(2))
            .with(2, RangeElement::edition(3));
        let e2 = Edition::from_one(0, RangeElement::edition(1))
            .with(1, RangeElement::edition(99))
            .with(2, RangeElement::edition(3));
        let id_eq = |a: &Carrier, b: &Carrier| match (&a.element, &b.element) {
            (
                RangeElement::Edition { edition_id: id_a },
                RangeElement::Edition { edition_id: id_b },
            ) => id_a == id_b,
            _ => false,
        };
        let region = e1.identity_shared_region(&e2, id_eq);
        assert!(region.contains(0));
        assert!(!region.contains(1));
        assert!(region.contains(2));
    }

    #[test]
    fn identity_shared_region_empty_on_no_match() {
        let e1 = Edition::from_one(0, RangeElement::edition(1));
        let e2 = Edition::from_one(0, RangeElement::edition(2));
        let id_eq = |a: &Carrier, b: &Carrier| match (&a.element, &b.element) {
            (
                RangeElement::Edition { edition_id: id_a },
                RangeElement::Edition { edition_id: id_b },
            ) => id_a == id_b,
            _ => false,
        };
        let region = e1.identity_shared_region(&e2, id_eq);
        assert!(region.is_empty());
    }

    #[test]
    fn positions_labelled_finds_single_label() {
        let e = Edition::from_text_elements(&[
            RangeElement::text("before"),
            RangeElement::label(1, RangeElement::text("target")),
            RangeElement::text("after"),
        ]);
        let region = e.positions_labelled(1);
        assert!(region.contains(1));
        assert!(!region.contains(0));
        assert!(!region.contains(2));
    }

    #[test]
    fn positions_labelled_multiple_labels() {
        let e = Edition::from_text_elements(&[
            RangeElement::label(1, RangeElement::text("a")),
            RangeElement::label(2, RangeElement::text("b")),
            RangeElement::label(1, RangeElement::text("c")),
        ]);
        let region = e.positions_labelled(1);
        assert!(region.contains(0));
        assert!(!region.contains(1));
        assert!(region.contains(2));
    }

    #[test]
    fn positions_labelled_no_match() {
        let e = Edition::from_text("hello");
        let region = e.positions_labelled(99);
        assert!(region.is_empty());
    }

    #[test]
    fn fetch_labelled_returns_position_and_inner() {
        let e = Edition::from_text_elements(&[
            RangeElement::text("before"),
            RangeElement::label(42, RangeElement::text("found")),
            RangeElement::text("after"),
        ]);
        let (pos, elem) = e.fetch_labelled(42).unwrap();
        assert_eq!(pos, 1);
        assert_eq!(elem.as_text(), Some("found"));
    }

    #[test]
    fn fetch_labelled_no_match() {
        let e = Edition::from_text("hello");
        assert!(e.fetch_labelled(99).is_none());
    }

    #[test]
    #[ignore]
    fn bench_old_vs_bulk_construction() {
        use crate::edition::orgl::OrglRoot;
        use crate::edition::range_element::Carrier;
        use std::sync::Arc;
        use std::time::Instant;

        let sizes = [1_000, 10_000, 50_000, 100_000];

        println!(
            "\n{:>10} | {:>12} | {:>12} | {:>8} | {}",
            "Size", "Old (ms)", "Bulk (ms)", "Speedup", "Count OK"
        );
        println!(
            "{:-<10}-+-{:-<12}-+-{:-<12}-+-{:-<8}-+-{:-<10}",
            "", "", "", "", ""
        );

        for &n in &sizes {
            let entries: Vec<(i64, RangeElement)> = (0..n)
                .map(|i| (i as i64, RangeElement::text(format!("v{}", i))))
                .collect();

            let carriers: Vec<(i64, Arc<Carrier>)> = entries
                .iter()
                .map(|(pos, elem)| (*pos, Arc::new(Carrier::new(elem.clone()))))
                .collect();

            let start = Instant::now();
            let mut old_edition = Edition::empty();
            for (pos, elem) in &entries {
                old_edition = old_edition.with(*pos, elem.clone());
            }
            let old_dur = start.elapsed();
            let old_count = old_edition.count();

            let start = Instant::now();
            let region = XnRegion::interval(0, n as i64);
            let orgl = OrglRoot::from_bulk_entries(carriers.clone(), None, region);
            let bulk_edition = Edition {
                orgl,
                endorsements: EndorsementSet::new(),
                entries_cache: Arc::new(OnceLock::new()),
                span_provenance: Vec::new(),
                span_status_cache: Arc::new(std::sync::Mutex::new(None)),
            };
            let bulk_dur = start.elapsed();
            let bulk_count = bulk_edition.count();

            let old_ms = old_dur.as_secs_f64() * 1000.0;
            let bulk_ms = bulk_dur.as_secs_f64() * 1000.0;
            let speedup = old_ms / bulk_ms.max(0.001);

            assert_eq!(old_count, bulk_count);
            assert_eq!(old_count, n as u64);

            println!(
                "{:>10} | {:>12.2} | {:>12.2} | {:>7.1}x | old={} bulk={}",
                n, old_ms, bulk_ms, speedup, old_count, bulk_count
            );

            for i in (0..n).step_by(n / 10.max(1)) {
                let old_val = old_edition.fetch(i as i64);
                let bulk_val = bulk_edition.fetch(i as i64);
                assert!(old_val.is_some(), "old missing at {}", i);
                assert!(bulk_val.is_some(), "bulk missing at {}", i);
                assert_eq!(old_val, bulk_val, "mismatch at position {}", i);
            }
        }
    }

    #[test]
    fn from_text_batched_empty() {
        let e = Edition::from_text_batched("");
        assert!(e.is_empty());
        assert_eq!(e.count(), 0);
        assert_eq!(e.char_len(), 0);
    }

    #[test]
    fn from_text_batched_single_line() {
        let e = Edition::from_text_batched("hello");
        assert_eq!(e.count(), 1);
        assert_eq!(e.to_text(), "hello");
        assert_eq!(e.char_len(), 5);
    }

    #[test]
    fn from_text_batched_two_lines() {
        let e = Edition::from_text_batched("hello\nworld");
        assert_eq!(e.count(), 2);
        assert_eq!(e.to_text(), "hello\nworld");
        assert_eq!(e.char_len(), 11);
    }

    #[test]
    fn from_text_batched_trailing_newline() {
        let e = Edition::from_text_batched("hello\nworld\n");
        assert_eq!(e.count(), 2);
        assert_eq!(e.to_text(), "hello\nworld\n");
        assert_eq!(e.char_len(), 12);
    }

    #[test]
    fn from_text_batched_just_newline() {
        let e = Edition::from_text_batched("\n");
        assert_eq!(e.count(), 1);
        assert_eq!(e.to_text(), "\n");
        assert_eq!(e.char_len(), 1);
    }

    #[test]
    fn from_text_batched_multiple_newlines() {
        let e = Edition::from_text_batched("\n\n\n");
        assert_eq!(e.count(), 3);
        assert_eq!(e.to_text(), "\n\n\n");
    }

    #[test]
    fn from_text_batched_empty_lines() {
        let e = Edition::from_text_batched("a\n\nb");
        assert_eq!(e.count(), 3);
        assert_eq!(e.to_text(), "a\n\nb");
    }

    #[test]
    fn char_len_matches_to_text_length() {
        let texts = ["", "hello", "hello\nworld", "a\nb\nc\nd\ne", "\n\n\n", "x"];
        for t in &texts {
            let batched = Edition::from_text_batched(t);
            assert_eq!(
                batched.char_len(),
                t.chars().count(),
                "char_len mismatch for batched {:?}",
                t
            );
            assert_eq!(
                batched.to_text(),
                *t,
                "to_text mismatch for batched {:?}",
                t
            );
        }
        for t in &texts {
            let per_char = Edition::from_text(t);
            assert_eq!(
                per_char.char_len(),
                t.chars().count(),
                "char_len mismatch for per-char {:?}",
                t
            );
        }
    }

    #[test]
    fn from_text_batched_element_count_vs_from_text() {
        let text = "line one\nline two\nline three\n";
        let batched = Edition::from_text_batched(text);
        let per_char = Edition::from_text(text);
        assert_eq!(batched.to_text(), per_char.to_text());
        assert!(batched.count() < per_char.count());
        assert_eq!(batched.count(), 3);
        assert_eq!(per_char.count(), text.len() as u64);
    }

    #[test]
    fn range_element_char_len() {
        assert_eq!(RangeElement::text("hello").char_len(), 5);
        assert_eq!(RangeElement::text("").char_len(), 0);
        assert_eq!(RangeElement::text("a\nb").char_len(), 3);
        assert_eq!(RangeElement::data(vec![1, 2, 3]).char_len(), 0);
        assert_eq!(RangeElement::edition(1).char_len(), 0);
        assert_eq!(RangeElement::placeholder(1).char_len(), 0);
        assert_eq!(RangeElement::blob(1, "image/png", 100).char_len(), 0);
    }

    // FR-50 #4 armor: the memoized span signature statuses must
    // equal direct computation (stored-verified / author-maintained
    // / unsigned), and stay stable across repeated calls.
    #[test]
    fn span_status_memo_matches_direct() {
        let ed = Edition::from_text("shared text appears twice: shared text appears twice")
            .with_span_provenance(vec![crate::edition::provenance::SpanProvenance {
                start: 0,
                end: 10,
                provenance: crate::edition::provenance::Provenance {
                    author_public_key: [7u8; 32],
                    signature: [0u8; 64],
                    timestamp: 1000,
                    server_id: [0u8; 32],
                },
            }]);
        let memo = ed.cached_span_signature_status().to_vec();
        let memo2 = ed.cached_span_signature_status().to_vec();
        assert_eq!(memo, memo2, "memo stable");
        let entries = ed.cached_entries();
        let fps_all = ed.cached_fingerprints();
        let sp = &ed.span_provenance[0];
        let i_start = entries.partition_point(|(p, _)| *p < sp.start);
        let i_end = entries.partition_point(|(p, _)| *p < sp.end);
        let fps: &[[u8; 32]] = fps_all
            .get(i_start..i_end)
            .map(|s| s as &[[u8; 32]])
            .unwrap_or(&[]);
        let direct_stored = crate::edition::provenance::verify_span_provenance(&sp.provenance, fps);
        let direct_author = entries
            .get(i_start..i_end)
            .map(|sl| {
                sl.iter().any(|(_, c)| {
                    c.provenance
                        .as_ref()
                        .is_some_and(|ep| ep.author_public_key == sp.provenance.author_public_key)
                })
            })
            .unwrap_or(false);
        let expected = if direct_stored {
            0
        } else if direct_author {
            1
        } else {
            2
        };
        assert_eq!(memo[0], expected, "memo equals direct computation");
    }

    #[test]
    fn coalesce_empty_edition() {
        let ed = Edition::empty();
        let coalesced = ed.coalesce();
        assert_eq!(coalesced.count(), 0);
        assert_eq!(coalesced.to_text(), "");
    }

    #[test]
    fn coalesce_single_element() {
        let ed = Edition::from_text_batched("hello\nworld\n");
        assert_eq!(ed.count(), 2);
        let coalesced = ed.coalesce();
        assert_eq!(coalesced.count(), 1);
        assert_eq!(coalesced.to_text(), "hello\nworld\n");
    }

    #[test]
    fn coalesce_per_char_to_lines() {
        let ed = Edition::from_text("hello\nworld\n");
        assert_eq!(ed.count(), 12);
        let coalesced = ed.coalesce();
        assert_eq!(coalesced.to_text(), "hello\nworld\n");
        assert_eq!(coalesced.count(), 1);
    }

    #[test]
    fn coalesce_preserves_mismatched_provenance() {
        use crate::edition::provenance::{AuthorType, ElementProvenance};

        let prov_a = ElementProvenance {
            author_public_key: [1u8; 32],
            author_display_name: "alice".to_string(),
            author_club_id: 1,
            timestamp: 100,
            author_type: AuthorType::Human,
            llm_model: None,
            historical_author_id: None,
            source_work_id: None,
            transcluded_by: None,
            derived_by: None,
        };
        let prov_b = ElementProvenance {
            author_public_key: [2u8; 32],
            author_display_name: "bob".to_string(),
            author_club_id: 2,
            timestamp: 200,
            author_type: AuthorType::Human,
            llm_model: None,
            historical_author_id: None,
            source_work_id: None,
            transcluded_by: None,
            derived_by: None,
        };

        let mut entries = Vec::new();
        let mut c1 = Carrier::new(RangeElement::text("hello ".to_string()));
        c1.provenance = Some(prov_a.clone());
        entries.push((0i64, Arc::new(c1)));

        let mut c2 = Carrier::new(RangeElement::text("world".to_string()));
        c2.provenance = Some(prov_b.clone());
        entries.push((1i64, Arc::new(c2)));

        let mut c3 = Carrier::new(RangeElement::text("!".to_string()));
        c3.provenance = Some(prov_b.clone());
        entries.push((2i64, Arc::new(c3)));

        let ed = Edition::from_entries(entries);
        assert_eq!(ed.count(), 3);

        let coalesced = ed.coalesce();
        assert_eq!(coalesced.to_text(), "hello world!");
        assert_eq!(coalesced.count(), 2);

        let entries = coalesced.all_entries();
        assert_eq!(entries[0].1.provenance, Some(prov_a));
        assert_eq!(entries[1].1.provenance, Some(prov_b));
        assert_eq!(entries[0].1.element.as_text().unwrap(), "hello ");
        assert_eq!(entries[1].1.element.as_text().unwrap(), "world!");
    }

    #[test]
    fn coalesce_merges_matching_provenance() {
        use crate::edition::provenance::{AuthorType, ElementProvenance};

        let prov = ElementProvenance {
            author_public_key: [1u8; 32],
            author_display_name: "alice".to_string(),
            author_club_id: 1,
            timestamp: 100,
            author_type: AuthorType::Human,
            llm_model: None,
            historical_author_id: None,
            source_work_id: None,
            transcluded_by: None,
            derived_by: None,
        };

        let mut entries = Vec::new();
        for (i, text) in ["abc", "def", "ghi"].iter().enumerate() {
            let mut c = Carrier::new(RangeElement::text(text.to_string()));
            c.provenance = Some(prov.clone());
            entries.push((i as i64, Arc::new(c)));
        }

        let ed = Edition::from_entries(entries);
        assert_eq!(ed.count(), 3);

        let coalesced = ed.coalesce();
        assert_eq!(coalesced.to_text(), "abcdefghi");
        assert_eq!(coalesced.count(), 1);
    }

    #[test]
    fn coalesce_after_split_preserves_text() {
        let ed = Edition::from_text_batched("hello world\nline two\n");
        assert_eq!(ed.count(), 2);

        let mut rebuilt_entries = Vec::new();
        rebuilt_entries.push((
            0i64,
            Arc::new(Carrier::new(RangeElement::text("hello".to_string()))),
        ));
        rebuilt_entries.push((
            1i64,
            Arc::new(Carrier::new(RangeElement::text(" ".to_string()))),
        ));
        rebuilt_entries.push((
            2i64,
            Arc::new(Carrier::new(RangeElement::text("world\n".to_string()))),
        ));
        rebuilt_entries.push((
            3i64,
            Arc::new(Carrier::new(RangeElement::text("line two\n".to_string()))),
        ));

        let rebuilt_ed = Edition::from_entries(rebuilt_entries);
        assert_eq!(rebuilt_ed.to_text(), "hello world\nline two\n");
        assert_eq!(rebuilt_ed.count(), 4);

        let coalesced = rebuilt_ed.coalesce();
        assert_eq!(coalesced.to_text(), "hello world\nline two\n");
        assert_eq!(coalesced.count(), 1);
    }

    #[test]
    fn coalesce_idempotent() {
        let ed = Edition::from_text_batched("line one\nline two\nline three\n");
        let c1 = ed.coalesce();
        let c2 = c1.coalesce();
        assert_eq!(c1.count(), c2.count());
        assert_eq!(c1.to_text(), c2.to_text());
    }

    #[test]
    fn coalesce_preserves_labels() {
        use crate::edition::range_element::RangeElementId;

        let mut entries = Vec::new();
        let c1 = Carrier::labelled(
            RangeElementId::new(42),
            RangeElement::text("abc".to_string()),
        );
        let c2 = Carrier::new(RangeElement::text("def".to_string()));
        entries.push((0i64, Arc::new(c1)));
        entries.push((1i64, Arc::new(c2)));

        let ed = Edition::from_entries(entries);
        let coalesced = ed.coalesce();
        assert_eq!(coalesced.to_text(), "abcdef");
        assert_eq!(coalesced.count(), 2);

        let coalesced_entries = coalesced.all_entries();
        assert_eq!(coalesced_entries[0].1.label, Some(RangeElementId::new(42)));
        assert!(coalesced_entries[1].1.label.is_none());
    }

    /// Benchmark: single tree op (`Edition::with`) on progressively larger
    /// editions. Documents the cost of path-clone + eager full-tree crum
    /// recomputation in `from_loaf` — the target of the incremental-crum
    /// stage (PERF-PLAN Stage 2). A flat curve means the tree op no longer
    /// scales with document size.
    #[test]
    fn benchmark_tree_op_on_large_editions() {
        for size in [1_000usize, 10_000, 100_000] {
            let text: String = "ab".repeat(size / 2);
            let ed = Edition::from_text(&text);
            let mid = (size / 2) as i64;

            let start = std::time::Instant::now();
            let edited = ed.with(mid, RangeElement::text("X"));
            let elapsed = start.elapsed();

            assert_eq!(edited.count(), size as u64);
            assert_eq!(
                edited
                    .fetch(mid)
                    .and_then(|e| e.as_text().map(|s| s.to_string())),
                Some("X".to_string())
            );
            println!("tree_op_with ({} entries): {:?}", size, elapsed);
        }
    }

    /// Benchmark: Run-length Carrier vs Per-char Element Storage
    ///
    /// Measures the performance and memory impact of `from_text_batched()` (per-line
    /// elements) versus `from_text()` (per-character elements).
    ///
    /// Background:
    ///   Before the run-length carrier work, `Edition::from_text()` created one
    ///   `Carrier` per character. Each Carrier is a 184-byte struct wrapping a
    ///   `RangeElement::Text { text: String }` that holds a single character.
    ///   For a book-sized text (~854 KB), that meant hundreds of thousands
    ///   elements — each with its own Arc, heap-allocated String, and optional
    ///   ElementProvenance for attribution.
    ///
    ///   `from_text_batched()` splits on newlines instead, creating one element per
    ///   line. This preserves full edit fidelity (delta ops still work on character
    ///   boundaries via `split_text_carrier`) while reducing element count by ~100x.
    ///
    /// Run with:
    ///   cargo test --features serde,server --lib -- edition::edition::tests::benchmark_batched_vs_per_char --ignored --nocapture
    ///
    #[test]
    #[ignore]
    fn benchmark_batched_vs_per_char() {
        use std::time::Instant;

        struct BenchmarkInput {
            label: String,
            text: String,
        }

        impl BenchmarkInput {
            fn synthetic(label: &str, target_bytes: usize) -> Self {
                let line = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\n";
                let mut text = String::new();
                while text.len() < target_bytes {
                    text.push_str(line);
                }
                text.truncate(target_bytes);
                BenchmarkInput {
                    label: label.to_string(),
                    text,
                }
            }

            fn book(target_bytes: usize) -> Self {
                let paragraphs = [
                    "It was a dark and stormy night; the rain fell in torrents, except at occasional intervals, when it was checked by a violent gust of wind which swept up the streets.\n",
                    "The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs. How vexingly quick daft zebras jump.\n",
                    "All happy families are alike; each unhappy family is unhappy in its own way. He stepped down, trying not to look long at her, as if she were the sun, yet he saw her, like the sun, even without looking.\n",
                    "It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife. However little known the feelings or views of such a man may be on his first entering a neighbourhood.\n",
                    "In my younger and more vulnerable years my father gave me some advice that I have been turning over in my mind ever since. Whenever you feel like criticizing anyone, he told me, just remember that all the people in this world haven't had the advantages that you've had.\n",
                    "Call me Ishmael. Some years ago—never mind how long precisely—having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world.\n",
                    "It was a bright cold day in April, and the clocks were striking thirteen. Winston Smith, his chin nuzzled into his breast in an effort to escape the vile wind, slipped quickly through the glass doors of Victory Mansions.\n",
                    "Many years later, as he faced the firing squad, Colonel Aureliano Buendia was to remember that distant afternoon when his father took him to discover ice.\n",
                    "Someone must have slandered Josef K., for one morning, without having done anything truly wrong, he was arrested. Like a dog! he said, it was as if the shame of it should outlive him.\n",
                    "Mrs. Dalloway said she would buy the flowers herself. For Lucy had her work cut out for her. The doors would be taken off their hinges; Rumpelmayer's men were coming.\n",
                ];
                let mut text = String::new();
                let mut i = 0;
                while text.len() < target_bytes {
                    text.push_str(paragraphs[i % paragraphs.len()]);
                    i += 1;
                }
                text.truncate(target_bytes);
                BenchmarkInput {
                    label: format!("Book {}KB", target_bytes / 1024),
                    text,
                }
            }
        }

        fn carrier_heap_size(c: &Carrier) -> usize {
            let element_size = match &c.element {
                RangeElement::Text { text } => text.capacity(),
                RangeElement::Data { bytes } => bytes.capacity(),
                RangeElement::Blob { mime_type, .. } => mime_type.capacity(),
                _ => 0,
            };
            let label_size = c.label.as_ref().map(|_| 8).unwrap_or(0);
            let prov_size = c
                .provenance
                .as_ref()
                .map(|p| {
                    32 + p.author_display_name.capacity()
                        + 8
                        + 8
                        + p.llm_model.as_ref().map(|m| m.capacity()).unwrap_or(0)
                        + 4
                })
                .unwrap_or(0);
            std::mem::size_of::<Carrier>() + element_size + label_size + prov_size
        }

        struct BenchResult {
            label: String,
            text_bytes: usize,
            text_chars: usize,
            line_count: usize,
            per_char_us: u64,
            batched_us: u64,
            per_char_elements: u64,
            batched_elements: u64,
            per_char_heap_kb: f64,
            batched_heap_kb: f64,
        }

        fn run_bench(input: &BenchmarkInput) -> BenchResult {
            let runs = if input.text.len() <= 10_000 {
                20
            } else if input.text.len() <= 100_000 {
                10
            } else {
                3
            };

            let mut per_char_us: u64 = 0;
            let mut batched_us: u64 = 0;
            let mut per_char_elements: u64 = 0;
            let mut batched_elements: u64 = 0;
            let mut per_char_heap: usize = 0;
            let mut batched_heap: usize = 0;

            for _ in 0..runs {
                let t0 = Instant::now();
                let ed = Edition::from_text(&input.text);
                per_char_us += t0.elapsed().as_micros() as u64;
                per_char_elements = ed.count();
                per_char_heap = ed
                    .all_entries()
                    .iter()
                    .map(|(_, c)| carrier_heap_size(c))
                    .sum();
            }

            for _ in 0..runs {
                let t0 = Instant::now();
                let ed = Edition::from_text_batched(&input.text);
                batched_us += t0.elapsed().as_micros() as u64;
                batched_elements = ed.count();
                batched_heap = ed
                    .all_entries()
                    .iter()
                    .map(|(_, c)| carrier_heap_size(c))
                    .sum();
            }

            per_char_us /= runs;
            batched_us /= runs;

            BenchResult {
                label: input.label.clone(),
                text_bytes: input.text.len(),
                text_chars: input.text.chars().count(),
                line_count: input.text.lines().count(),
                per_char_us,
                batched_us,
                per_char_elements,
                batched_elements,
                per_char_heap_kb: per_char_heap as f64 / 1024.0,
                batched_heap_kb: batched_heap as f64 / 1024.0,
            }
        }

        let inputs: Vec<BenchmarkInput> = vec![
            BenchmarkInput::synthetic("1 KB", 1_000),
            BenchmarkInput::synthetic("10 KB", 10_000),
            BenchmarkInput::synthetic("100 KB", 100_000),
            BenchmarkInput::synthetic("500 KB", 500_000),
            BenchmarkInput::book(874_496),
            BenchmarkInput::synthetic("1 MB", 1_000_000),
        ];

        let provenance_bytes: usize = 63;

        eprintln!();
        eprintln!("╔════════════════════════════════════════════════════════════════════════════════════════════════════════════╗");
        eprintln!("║                     Run-length Carrier Benchmark: Per-char vs Batched (per-line)                        ║");
        eprintln!("╚════════════════════════════════════════════════════════════════════════════════════════════════════════════╝");
        eprintln!();
        eprintln!("  Edition::from_text()          — one Carrier per character (old)");
        eprintln!("  Edition::from_text_batched()   — one Carrier per line (run-length, new)");
        let carrier_sz = std::mem::size_of::<Carrier>();
        let arc_sz = std::mem::size_of::<Arc<Carrier>>();
        let tuple_sz = std::mem::size_of::<(i64, Arc<Carrier>)>();
        eprintln!(
            "  Carrier struct: {} bytes   Arc<Carrier>: {} bytes   (i64, Arc<Carrier>): {} bytes",
            carrier_sz, arc_sz, tuple_sz
        );
        eprintln!("  ElementProvenance: ~{} bytes (32-byte key + display name + club_id + timestamp + type)", provenance_bytes);
        eprintln!();
        eprintln!(
            "{:<10} {:>8} {:>7} {:>5} {:>10} {:>10} {:>8} {:>10} {:>10} {:>10} {:>8}",
            "Input",
            "Bytes",
            "Chars",
            "Lines",
            "Per-char μs",
            "Batched μs",
            "Speedup",
            "PC elems",
            "BT elems",
            "Elem ratio",
            "Heap↓"
        );
        eprintln!("{}", "─".repeat(112));

        for input in &inputs {
            let r = run_bench(input);
            let speedup = r.per_char_us as f64 / r.batched_us as f64;
            let elem_ratio = r.per_char_elements as f64 / r.batched_elements as f64;
            let heap_saved_pct = (1.0 - r.batched_heap_kb / r.per_char_heap_kb) * 100.0;

            eprintln!(
                "{:<10} {:>8} {:>7} {:>5} {:>10} {:>10} {:>7.1}x {:>10} {:>10} {:>9.0}x {:>7.1}%",
                r.label,
                r.text_bytes,
                r.text_chars,
                r.line_count,
                r.per_char_us,
                r.batched_us,
                speedup,
                r.per_char_elements,
                r.batched_elements,
                elem_ratio,
                heap_saved_pct,
            );
        }

        eprintln!();
        eprintln!("─── Detailed Memory Breakdown ───────────────────────────────────────────────────────────────────────────");
        eprintln!();

        let all_results: Vec<BenchResult> = inputs.iter().map(|i| run_bench(i)).collect();

        eprintln!(
            "{:<10} {:>10} {:>10} {:>12} {:>12} {:>10} {:>10} {:>12} {:>12} {:>10}",
            "Input",
            "Text KB",
            "Lines",
            "PC heap KB",
            "BT heap KB",
            "Heap↓",
            "PC×text",
            "PC+attr KB",
            "BT+attr KB",
            "Attr↓"
        );
        eprintln!("{}", "─".repeat(120));

        for r in &all_results {
            let text_kb = r.text_bytes as f64 / 1024.0;
            let pc_inflation = r.per_char_heap_kb / text_kb;
            let bt_inflation = r.batched_heap_kb / text_kb;
            let heap_saved_pct = (1.0 - r.batched_heap_kb / r.per_char_heap_kb) * 100.0;

            let pc_attr_kb = r.per_char_heap_kb
                + (r.per_char_elements as usize * provenance_bytes) as f64 / 1024.0;
            let bt_attr_kb = r.batched_heap_kb
                + (r.batched_elements as usize * provenance_bytes) as f64 / 1024.0;
            let attr_saved_pct = (1.0 - bt_attr_kb / pc_attr_kb) * 100.0;

            eprintln!("{:<10} {:>10.1} {:>10} {:>12.1} {:>12.1} {:>9.1}% {:>9.1}x {:>12.1} {:>12.1} {:>9.1}%",
                r.label,
                text_kb,
                r.line_count,
                r.per_char_heap_kb,
                r.batched_heap_kb,
                heap_saved_pct,
                bt_inflation,
                pc_attr_kb,
                bt_attr_kb,
                attr_saved_pct,
            );
        }

        eprintln!();
        eprintln!("─── Book-sized Text Deep Dive (~854 KB, prose paragraphs) ────────────────────────────────────────────────");
        eprintln!();

        let book_result = all_results
            .iter()
            .find(|r| r.label.starts_with("Book"))
            .unwrap();

        eprintln!(
            "  Raw text:             {:>8.1} KB  ({} bytes, {} chars, {} lines)",
            book_result.text_bytes as f64 / 1024.0,
            book_result.text_bytes,
            book_result.text_chars,
            book_result.line_count
        );
        eprintln!();
        eprintln!(
            "  Per-char elements:    {:>8}    Batched: {:>8}    Reduction: {:.0}x fewer elements",
            book_result.per_char_elements,
            book_result.batched_elements,
            book_result.per_char_elements as f64 / book_result.batched_elements as f64
        );
        eprintln!();
        eprintln!(
            "  Per-char heap:        {:>8.1} KB  ({:.1}x text size)",
            book_result.per_char_heap_kb,
            book_result.per_char_heap_kb / (book_result.text_bytes as f64 / 1024.0)
        );
        eprintln!(
            "  Batched heap:         {:>8.1} KB  ({:.1}x text size)",
            book_result.batched_heap_kb,
            book_result.batched_heap_kb / (book_result.text_bytes as f64 / 1024.0)
        );
        eprintln!(
            "  Heap saved:           {:>8.1} KB  ({:.1}%)",
            book_result.per_char_heap_kb - book_result.batched_heap_kb,
            (1.0 - book_result.batched_heap_kb / book_result.per_char_heap_kb) * 100.0
        );
        eprintln!();
        let pc_provenance_kb =
            (book_result.per_char_elements as usize * provenance_bytes) as f64 / 1024.0;
        let bt_provenance_kb =
            (book_result.batched_elements as usize * provenance_bytes) as f64 / 1024.0;
        eprintln!(
            "  Per-char provenance:  {:>8.1} KB  ({} elements × {} bytes)",
            pc_provenance_kb, book_result.per_char_elements, provenance_bytes
        );
        eprintln!(
            "  Batched provenance:   {:>8.1} KB  ({} elements × {} bytes)",
            bt_provenance_kb, book_result.batched_elements, provenance_bytes
        );
        eprintln!(
            "  Provenance saved:     {:>8.1} KB  ({:.1}%)",
            pc_provenance_kb - bt_provenance_kb,
            (1.0 - bt_provenance_kb / pc_provenance_kb) * 100.0
        );
        eprintln!();
        let pc_total = book_result.per_char_heap_kb + pc_provenance_kb;
        let bt_total = book_result.batched_heap_kb + bt_provenance_kb;
        eprintln!(
            "  Per-char total:       {:>8.1} KB  (heap + attribution)",
            pc_total
        );
        eprintln!(
            "  Batched total:        {:>8.1} KB  (heap + attribution)",
            bt_total
        );
        eprintln!(
            "  Total saved:          {:>8.1} KB  ({:.1}%)",
            pc_total - bt_total,
            (1.0 - bt_total / pc_total) * 100.0
        );
        eprintln!();
        eprintln!("  Per-char build time:  {:>8} μs", book_result.per_char_us);
        eprintln!("  Batched build time:   {:>8} μs", book_result.batched_us);
        eprintln!(
            "  Speedup:              {:>8.1}x",
            book_result.per_char_us as f64 / book_result.batched_us as f64
        );
        eprintln!();

        eprintln!("─── Coalesce After Simulated Edits ────────────────────────────────────────────────────────────────────");
        eprintln!();
        eprintln!("  Simulates element fragmentation from character-level edits, then measures recovery via coalesce.");
        eprintln!();

        let book_text = inputs
            .iter()
            .find(|i| i.label.starts_with("Book"))
            .unwrap()
            .text
            .clone();
        let ed = Edition::from_text_batched(&book_text);
        let initial_count = ed.count();

        let entries = ed.all_entries();

        let mut fragmented_entries: Vec<(i64, Arc<Carrier>)> = Vec::new();
        let mut pos = 0i64;
        let mut frag_count = 0usize;
        let mut next_split = 100usize;
        let split_interval = 500usize;

        for (_, carrier) in &entries {
            match &carrier.element {
                RangeElement::Text { text } => {
                    let char_len = text.chars().count();
                    let mut char_pos = 0usize;

                    for (byte_idx, ch) in text.char_indices() {
                        let global_char = next_split.saturating_sub(split_interval) + char_pos;

                        if char_pos > 0 && global_char >= next_split {
                            let left = &text[..byte_idx];
                            let right = &text[byte_idx..];
                            if !left.is_empty() {
                                let mut c = Carrier::new(RangeElement::text(left.to_string()));
                                c.provenance = carrier.provenance.clone();
                                c.label = carrier.label.clone();
                                fragmented_entries.push((pos, Arc::new(c)));
                                pos += 1;
                                frag_count += 1;
                            }
                            let mut c = Carrier::new(RangeElement::text(right.to_string()));
                            c.provenance = carrier.provenance.clone();
                            c.label = carrier.label.clone();
                            fragmented_entries.push((pos, Arc::new(c)));
                            pos += 1;
                            frag_count += 1;
                            next_split += split_interval;
                            break;
                        }

                        char_pos += 1;

                        if char_pos == char_len && global_char < next_split {
                            fragmented_entries.push((pos, carrier.clone()));
                            pos += 1;
                        }
                    }
                    if char_len == 0 {
                        fragmented_entries.push((pos, carrier.clone()));
                        pos += 1;
                    }
                }
                _ => {
                    fragmented_entries.push((pos, carrier.clone()));
                    pos += 1;
                }
            }
        }

        let fragmented = Edition::from_entries(fragmented_entries);

        let t0 = Instant::now();
        let coalesced = fragmented.coalesce();
        let coalesce_us = t0.elapsed().as_micros();

        let fragmented_heap: usize = fragmented
            .all_entries()
            .iter()
            .map(|(_, c)| {
                let el = match &c.element {
                    RangeElement::Text { text } => text.capacity(),
                    _ => 0,
                };
                std::mem::size_of::<Carrier>() + el
            })
            .sum();
        let coalesced_heap: usize = coalesced
            .all_entries()
            .iter()
            .map(|(_, c)| {
                let el = match &c.element {
                    RangeElement::Text { text } => text.capacity(),
                    _ => 0,
                };
                std::mem::size_of::<Carrier>() + el
            })
            .sum();

        eprintln!("  Initial (batched):   {:>8} elements", initial_count);
        eprintln!(
            "  After fragmentation: {:>8} elements  (split every {} chars)",
            fragmented.count(),
            split_interval
        );
        eprintln!(
            "  After coalesce:      {:>8} elements  (recovered)",
            coalesced.count()
        );
        eprintln!("  Coalesce time:       {:>8} μs", coalesce_us);
        eprintln!();
        eprintln!(
            "  Fragmented heap:     {:>8.1} KB",
            fragmented_heap as f64 / 1024.0
        );
        eprintln!(
            "  Coalesced heap:      {:>8.1} KB",
            coalesced_heap as f64 / 1024.0
        );
        eprintln!(
            "  Heap recovered:      {:>8.1} KB  ({:.1}%)",
            (fragmented_heap - coalesced_heap) as f64 / 1024.0,
            (1.0 - coalesced_heap as f64 / fragmented_heap as f64) * 100.0
        );
        eprintln!();

        assert_eq!(
            coalesced.to_text(),
            fragmented.to_text(),
            "coalesce must preserve text content"
        );
        let recovered_ratio = coalesced.count() as f64 / fragmented.count() as f64;
        eprintln!(
            "  Element recovery:    {:.1}% of fragmented count (ideal: back to {})",
            (1.0 - recovered_ratio) * 100.0,
            initial_count
        );
        eprintln!();
    }

    #[test]
    fn to_text_range_basic() {
        let ed = Edition::from_text("Hello, world!");
        assert_eq!(ed.to_text_range(0, 5), "Hello");
        assert_eq!(ed.to_text_range(7, 12), "world");
        assert_eq!(ed.to_text_range(7, 13), "world!");
        assert_eq!(ed.to_text_range(0, 13), "Hello, world!");
    }

    #[test]
    fn to_text_range_batched() {
        let text = "line one\nline two\nline three\n";
        let ed = Edition::from_text_batched(text);
        assert_eq!(ed.to_text_range(0, 8), "line one");
        assert_eq!(ed.to_text_range(9, 13), "line");
        assert_eq!(ed.to_text_range(10, 19), "ine two\nl");
        assert_eq!(ed.to_text_range(0, text.len()), text);
    }

    #[test]
    fn to_text_range_edge_cases() {
        let ed = Edition::from_text("abc");
        assert_eq!(ed.to_text_range(0, 0), "");
        assert_eq!(ed.to_text_range(3, 3), "");
        assert_eq!(ed.to_text_range(5, 10), "");
    }

    #[test]
    fn to_text_range_empty() {
        let ed = Edition::empty();
        assert_eq!(ed.to_text_range(0, 10), "");
    }

    #[test]
    fn to_text_range_unicode() {
        let ed = Edition::from_text("Héllo wörld");
        assert_eq!(ed.to_text_range(0, 5), "Héllo");
        assert_eq!(ed.to_text_range(6, 11), "wörld");
        assert_eq!(ed.to_text_range(2, 4), "ll");
    }

    #[test]
    fn extract_outline_markdown() {
        let text = "# Title\nSome text\n## Section 1\nMore text\n### Subsection\n## Section 2\n";
        let ed = Edition::from_text_batched(text);
        let outline = ed.extract_outline();
        assert_eq!(outline.len(), 4);
        assert_eq!(outline[0].level, 1);
        assert_eq!(outline[0].text, "Title");
        assert_eq!(outline[1].level, 2);
        assert_eq!(outline[1].text, "Section 1");
        assert_eq!(outline[2].level, 3);
        assert_eq!(outline[2].text, "Subsection");
        assert_eq!(outline[3].level, 2);
        assert_eq!(outline[3].text, "Section 2");
    }

    #[test]
    fn extract_outline_chapters() {
        let text = "Chapter 1: Begin\nSome text\nPart One\nMore\nSection 2.1\n";
        let ed = Edition::from_text(text);
        let outline = ed.extract_outline();
        assert_eq!(outline.len(), 3);
        assert_eq!(outline[0].level, 2);
        assert_eq!(outline[1].level, 1);
        assert_eq!(outline[2].level, 3);
    }

    #[test]
    fn extract_outline_empty() {
        let ed = Edition::empty();
        assert!(ed.extract_outline().is_empty());
    }

    #[test]
    fn search_text_basic() {
        let text = "hello world hello again";
        let ed = Edition::from_text(text);
        let results = ed.search_text("hello", 10);
        assert_eq!(results.len(), 2);
        assert_eq!(results[0].char_offset, 0);
        assert_eq!(results[1].char_offset, 12);
    }

    #[test]
    fn search_text_case_insensitive() {
        let text = "Hello World";
        let ed = Edition::from_text(text);
        let results = ed.search_text("hello", 10);
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].char_offset, 0);
    }

    #[test]
    fn search_text_max_results() {
        let text = "aaa aaa aaa aaa aaa";
        let ed = Edition::from_text(text);
        let results = ed.search_text("aaa", 2);
        assert_eq!(results.len(), 2);
    }

    #[test]
    fn search_text_no_match() {
        let ed = Edition::from_text("hello world");
        let results = ed.search_text("xyz", 10);
        assert!(results.is_empty());
    }

    #[test]
    fn get_context_middle() {
        let text = "line0\nline1\nline2\nline3\nline4\nline5\nline6";
        let ed = Edition::from_text(text);
        let (start, _char, ctx) = ed.get_context(3, 2);
        assert_eq!(start, 1);
        let lines: Vec<&str> = ctx.split('\n').collect();
        assert_eq!(lines.len(), 5);
        assert_eq!(lines[0], "line1");
        assert_eq!(lines[2], "line3");
        assert_eq!(lines[4], "line5");
    }

    #[test]
    fn get_context_near_top() {
        let text = "line0\nline1\nline2\nline3\nline4";
        let ed = Edition::from_text(text);
        let (start, _char, ctx) = ed.get_context(1, 2);
        assert_eq!(start, 0);
        let lines: Vec<&str> = ctx.split('\n').collect();
        assert!(lines.len() <= 5);
        assert_eq!(lines[0], "line0");
        assert_eq!(lines[1], "line1");
    }

    #[test]
    fn get_context_near_bottom() {
        let text = "line0\nline1\nline2\nline3\nline4";
        let ed = Edition::from_text(text);
        let (start, _char, ctx) = ed.get_context(4, 2);
        assert_eq!(start, 2);
        let lines: Vec<&str> = ctx.split('\n').collect();
        assert_eq!(lines[0], "line2");
        assert_eq!(lines[2], "line4");
    }

    #[test]
    fn get_context_single_line() {
        let text = "only line";
        let ed = Edition::from_text(text);
        let (start, _char, ctx) = ed.get_context(0, 3);
        assert_eq!(start, 0);
        assert_eq!(ctx, "only line");
    }

    #[test]
    fn get_context_empty() {
        let ed = Edition::from_text("");
        let (start, _char, ctx) = ed.get_context(0, 3);
        assert_eq!(start, 0);
        assert_eq!(ctx, "");
    }

    #[test]
    fn get_context_zero_context_lines() {
        let text = "line0\nline1\nline2";
        let ed = Edition::from_text(text);
        let (start, _char, ctx) = ed.get_context(1, 0);
        assert_eq!(start, 1);
        assert_eq!(ctx, "line1");
    }

    #[test]
    fn chunk_crums_identical_editions() {
        let e1 = Edition::from_text("hello world this is a test");
        let e2 = Edition::from_text("hello world this is a test");
        let c1 = e1.chunk_crums(4);
        let c2 = e2.chunk_crums(4);
        assert_eq!(c1.len(), c2.len());
        for (a, b) in c1.iter().zip(c2.iter()) {
            assert_eq!(a.2, b.2, "crums should match for identical content");
        }
    }

    #[test]
    fn chunk_crums_different_editions() {
        let e1 = Edition::from_text("hello world this is a test");
        let e2 = Edition::from_text("hello earth this is a test");
        let c1 = e1.chunk_crums(4);
        let c2 = e2.chunk_crums(4);
        let any_diff = c1.iter().zip(c2.iter()).any(|(a, b)| a.2 != b.2);
        assert!(any_diff, "at least one chunk should differ");
    }

    #[test]
    fn chunk_diff_finds_matching_blocks() {
        let e1 = Edition::from_text("abcdefghij");
        let e2 = Edition::from_text("abcdefghij");
        let (matching, differing) = e1.chunk_diff(&e2, 3);
        assert!(
            differing.is_empty(),
            "identical editions should have no differing blocks"
        );
        assert!(!matching.is_empty());
    }

    #[test]
    fn chunk_diff_finds_changed_blocks() {
        let e1 = Edition::from_text("abcdefghij");
        let e2 = Edition::from_text("abXdefghij");
        let (matching, differing) = e1.chunk_diff(&e2, 3);
        assert!(
            !differing.is_empty(),
            "different editions should have differing blocks"
        );
    }

    #[test]
    fn range_crum_consistency() {
        let ed = Edition::from_text("hello world");
        let crum1 = ed.range_crum(0, 5);
        let crum2 = ed.range_crum(0, 5);
        assert_eq!(crum1, crum2);
    }

    #[test]
    fn entries_in_range_boundaries() {
        let ed = Edition::from_text("abc");
        let all = ed.entries_in_range(0, 3);
        assert_eq!(all.len(), 3);
        let none = ed.entries_in_range(10, 20);
        assert!(none.is_empty());
    }

    #[test]
    fn splayed_preserves_content() {
        let ed = Edition::from_text("hello world");
        let region = XnRegion::interval(2, 6);
        let (splayed, result) = ed.splayed(&region);
        assert_eq!(
            splayed.to_text(),
            "hello world",
            "splay must not change content"
        );
        assert_ne!(
            result,
            crate::edition::orgl::SplayResult::Outside,
            "splay should find the region"
        );
    }

    /// Stage 4: sparse positions are preserved verbatim by the
    /// position-preserving constructor.
    #[test]
    fn from_entries_at_positions_preserves_sparse_layout() {
        let entries: Vec<(i64, Arc<Carrier>)> =
            [(0i64, "alpha"), (65536, "beta"), (131072, "gamma")]
                .iter()
                .map(|(p, t)| {
                    (
                        *p,
                        Arc::new(Carrier::new(RangeElement::text(t.to_string()))),
                    )
                })
                .collect();
        let ed = Edition::from_entries_at_positions(entries).unwrap();
        assert_eq!(ed.positions(), vec![0, 65536, 131072]);
        assert_eq!(ed.domain(), XnRegion::interval(0, 131073));
        assert_eq!(ed.to_text(), "alphabetagamma");
    }

    /// Stage 4: rejects duplicate/decreasing positions.
    #[test]
    fn from_entries_at_positions_rejects_non_increasing() {
        let mk = |ps: &[i64]| -> Vec<(i64, Arc<Carrier>)> {
            ps.iter()
                .map(|p| (*p, Arc::new(Carrier::new(RangeElement::text("x")))))
                .collect()
        };
        assert!(Edition::from_entries_at_positions(mk(&[0, 0])).is_err());
        // Out-of-order input is sorted defensively: [5, 3] -> [3, 5].
        assert!(Edition::from_entries_at_positions(mk(&[5, 3])).is_ok());
        assert!(Edition::from_entries_at_positions(mk(&[0, 1, 1])).is_err());
        assert!(Edition::from_entries_at_positions(mk(&[])).is_ok());
        assert!(Edition::from_entries_at_positions(mk(&[7])).is_ok());
    }

    /// Stage 4 core invariant: tree ops (with/without) never move
    /// unrelated entries; an edit lands exactly at the allocated
    /// position (gap midpoint).
    #[test]
    fn tree_ops_preserve_unrelated_positions() {
        use crate::space::position_allocator::{allocate_between, spaced_layout, DEFAULT_SPACING};

        let ps = spaced_layout(6, DEFAULT_SPACING);
        let entries: Vec<(i64, Arc<Carrier>)> = ps
            .iter()
            .enumerate()
            .map(|(i, p)| {
                (
                    *p,
                    Arc::new(Carrier::new(RangeElement::text(format!("e{}", i)))),
                )
            })
            .collect();
        let ed = Edition::from_entries_at_positions(entries).unwrap();

        // Insert between entries 2 and 3 at the gap midpoint.
        let mid = allocate_between(ps[2], ps[3]).unwrap();
        let ed2 = ed.with(mid, RangeElement::text("INSERTED"));

        let mut got = ed2.positions();
        assert!(got.contains(&mid), "allocated position present");
        // Every original position survives untouched.
        for p in &ps {
            assert!(got.contains(p), "original position {} preserved", p);
        }
        got.sort_unstable();
        assert_eq!(
            got.windows(2).filter(|w| w[0] >= w[1]).count(),
            0,
            "strictly increasing"
        );

        // Delete an unrelated entry; the rest keep positions.
        let ed3 = ed2.without(ps[4]);
        let ps3 = ed3.positions();
        assert!(!ps3.contains(&ps[4]));
        assert!(ps3.contains(&mid));
        for p in &ps[0..4] {
            assert!(ps3.contains(p));
        }
        assert!(ps3.contains(&ps[5]));
    }

    /// Stage 4: sparse editions survive the persistence round-trip
    /// (EditionSnapshot stores raw positions).
    #[test]
    fn sparse_positions_survive_snapshot_round_trip() {
        let entries: Vec<(i64, Arc<Carrier>)> = [(0i64, "a"), (10, "b"), (20, "c"), (3000, "d")]
            .iter()
            .map(|(p, t)| {
                (
                    *p,
                    Arc::new(Carrier::new(RangeElement::text(t.to_string()))),
                )
            })
            .collect();
        let ed = Edition::from_entries_at_positions(entries).unwrap();

        let snap = crate::edition::persistent::EditionSnapshot::from_edition(&ed);
        let restored = snap.to_edition();
        assert_eq!(restored.positions(), vec![0, 10, 20, 3000]);
        assert_eq!(restored.to_text(), "abcd");
    }

    /// Stage 4: three-way diff/merge operate correctly on sparse inputs —
    /// the audit found they are interval+fingerprint based, and this test
    /// pins that behavior for gap-allocated layouts.
    #[test]
    fn three_way_merge_on_sparse_positions() {
        let mk = |pairs: &[(i64, &str)]| -> Edition {
            let entries: Vec<(i64, Arc<Carrier>)> = pairs
                .iter()
                .map(|(p, t)| {
                    (
                        *p,
                        Arc::new(Carrier::new(RangeElement::text(t.to_string()))),
                    )
                })
                .collect();
            Edition::from_entries_at_positions(entries).unwrap()
        };

        let base = mk(&[(0, "hello"), (100, "world")]);
        let a = mk(&[(0, "hello"), (50, "brave"), (100, "world")]);
        let b = mk(&[(0, "HELLO"), (100, "world")]);

        let result = crate::edition::three_way::three_way_merge(
            &base,
            &a,
            &b,
            crate::edition::three_way::MergeStrategy::LastWriterWins,
        )
        .unwrap();
        let text = result.merged.to_text();
        assert!(text.contains("HELLO"), "b's edit applied: {}", text);
        assert!(text.contains("brave"), "a's insert applied: {}", text);
        assert!(text.contains("world"));
    }

    /// Stage 4: DocumentArrangement names sparse positions as tumblers
    /// (Phase D bridge works on gap-allocated layouts).
    #[test]
    fn sparse_positions_tumbler_bridge() {
        let entries: Vec<(i64, Arc<Carrier>)> = [(0i64, "a"), (65536, "b"), (131072, "c")]
            .iter()
            .map(|(p, t)| {
                (
                    *p,
                    Arc::new(Carrier::new(RangeElement::text(t.to_string()))),
                )
            })
            .collect();
        let ed = Edition::from_entries_at_positions(entries).unwrap();
        let arr = crate::edition::tumbler::DocumentArrangement::new("alice.com", 5);
        for p in ed.positions() {
            let t = arr.to_tumbler(p);
            assert_eq!(arr.from_tumbler(&t), Some(p), "round trip for {}", p);
        }
    }

    /// Regression (Aug 2026): repeated small-region splays at moving
    /// positions on a real edition must never lose content — the
    /// failure mode the S3 probe exposed (half the document vanished).
    #[test]
    fn splayed_repeated_moving_regions_preserve_content() {
        let text: String = (0..500)
            .map(|i| char::from_u32(97 + i % 26).unwrap())
            .collect();
        let ed = Edition::from_text(&text);
        let mut cur = ed;
        for i in 0..40usize {
            let positions = cur.positions();
            let idx = (i * 7 + 3).min(positions.len() - 2);
            let lo = positions[idx];
            let hi = positions[idx + 1] + 1;
            let (splayed, _) = cur.splayed(&XnRegion::interval(lo, hi));
            assert_eq!(
                splayed.char_len(),
                text.chars().count(),
                "content lost at splay {} (idx {}, [{},{}))",
                i,
                idx,
                lo,
                hi
            );
            cur = splayed;
        }
        assert_eq!(cur.to_text(), text);
    }

    /// FR-38 Phase 1: ground-truth span license query.
    #[test]
    fn span_license_classes_mixed_ownership() {
        use crate::edition::provenance::ElementProvenance;
        use crate::edition::work::{License, LicenseClass};

        let alice = ElementProvenance {
            author_public_key: [1; 32],
            author_display_name: "Alice".to_string(),
            author_club_id: 10,
            timestamp: 1,
            author_type: crate::edition::provenance::AuthorType::Human,
            llm_model: None,
            historical_author_id: None,
            source_work_id: None,
            transcluded_by: None,
            derived_by: None,
        };
        let bob = ElementProvenance {
            author_club_id: 20,
            ..alice.clone()
        };

        // Alice (TCo) owns chars 0-5; Bob (ARR) owns 5-10.
        let entries = vec![
            (
                0i64,
                Arc::new(
                    Carrier::new(RangeElement::text("aaaaa".to_string()))
                        .with_provenance(alice.clone()),
                ),
            ),
            (
                1i64,
                Arc::new(
                    Carrier::new(RangeElement::text("bbbbb".to_string()))
                        .with_provenance(bob.clone()),
                ),
            ),
        ];
        let ed = Edition::from_entries(entries);

        let licenses = |owner: BeId| -> Option<License> {
            match owner {
                10 => Some(License::Transcopyright),
                20 => Some(License::AllRightsReserved),
                _ => None,
            }
        };

        let s = ed.span_license_classes(0, 10, licenses);
        assert!(s.total_class.contains(LicenseClass::TRANSCLUSION_OK));
        assert!(s.total_class.contains(LicenseClass::RESTRICTED));
        assert_eq!(s.distinct_owners, 2);
        assert_eq!(s.boundaries.len(), 2);
        assert_eq!(s.boundaries[0].0, 0);
        assert_eq!(s.boundaries[0].1, 5);
        assert_eq!(s.boundaries[0].2, Some(10));
        assert!(s.boundaries[0].3.contains(LicenseClass::TRANSCLUSION_OK));
        assert!(s.boundaries[1].3.contains(LicenseClass::RESTRICTED));

        // Partial span inside one owner: single boundary, one class.
        let s2 = ed.span_license_classes(0, 5, licenses);
        assert!(s2.total_class.contains(LicenseClass::TRANSCLUSION_OK));
        assert!(!s2.total_class.contains(LicenseClass::RESTRICTED));
        assert_eq!(s2.distinct_owners, 1);
    }

    /// FR-38 Phase 1: unresolvable owners and provenance-less entries
    /// contribute UNKNOWN (the safe default), never a wrong class.
    #[test]
    fn span_license_classes_unknown_fallbacks() {
        use crate::edition::work::{License, LicenseClass};

        let ed = Edition::from_text("hello world");
        let nothing = |_: BeId| -> Option<License> { None };
        let s = ed.span_license_classes(0, 11, nothing);
        assert!(s.total_class.contains(LicenseClass::UNKNOWN));
        assert_eq!(s.unresolved_entries, 11, "per-char entries all unresolved");
        assert_eq!(s.distinct_owners, 1);
        assert!(s.boundaries[0].2.is_none(), "no owner attributable");
    }

    /// FR-38 Phase 1: LicenseClass monoid + License derivation.
    #[test]
    fn license_class_bits() {
        use crate::edition::work::{License, LicenseClass};

        assert!(License::PublicDomain
            .license_class()
            .contains(LicenseClass::FREE));
        assert!(License::Transcopyright
            .license_class()
            .contains(LicenseClass::TRANSCLUSION_OK));
        assert!(License::CreativeCommonsBy
            .license_class()
            .contains(LicenseClass::ATTRIBUTION));
        assert!(License::AllRightsReserved
            .license_class()
            .contains(LicenseClass::RESTRICTED));

        let combined = LicenseClass::FREE.combine(LicenseClass::RESTRICTED);
        assert!(combined.contains(LicenseClass::FREE));
        assert!(combined.contains(LicenseClass::RESTRICTED));
        assert!(!combined.contains(LicenseClass::ATTRIBUTION));
        assert_eq!(LicenseClass::default().bits(), 0);
        let s = format!("{}", combined);
        assert!(s.contains("free") && s.contains("restricted"));
    }

    #[test]
    fn splayed_preserves_entries() {
        let ed = Edition::from_text_batched("line1\nline2\nline3");
        let original_entries = ed.all_entries();
        let region = XnRegion::interval(0, 2);
        let (splayed, _) = ed.splayed(&region);
        let splayed_entries = splayed.all_entries();
        assert_eq!(
            original_entries.len(),
            splayed_entries.len(),
            "splay must preserve entry count"
        );
        for (a, b) in original_entries.iter().zip(splayed_entries.iter()) {
            assert_eq!(a.0, b.0, "positions must match");
            assert_eq!(a.1.element, b.1.element, "elements must match");
        }
    }

    #[test]
    fn splayed_crum_differs() {
        // Needs enough entries to force a multi-level tree (Split nodes);
        // a single-leaf edition has no structure for splay to restructure.
        let text: String = (0..600).map(|i| format!("line{}\n", i)).collect();
        let ed = Edition::from_text_batched(&text);
        let region = XnRegion::interval(100, 300);
        let (splayed, _) = ed.splayed(&region);
        assert_ne!(
            ed.crum(),
            splayed.crum(),
            "splay restructures the tree, so crum should change"
        );
    }

    #[test]
    fn splayed_outside_region_unchanged() {
        let ed = Edition::from_text("abc");
        let region = XnRegion::interval(100, 200);
        let (splayed, result) = ed.splayed(&region);
        assert_eq!(
            result,
            crate::edition::orgl::SplayResult::Outside,
            "splay on non-overlapping region should return Outside"
        );
        assert_eq!(
            ed.crum(),
            splayed.crum(),
            "splay Outside should not modify the tree"
        );
    }

    #[test]
    fn splayed_fully_contained() {
        let ed = Edition::from_text_batched("hello\nworld");
        let region = ed.domain();
        let (_splayed, result) = ed.splayed(&region);
        assert_eq!(
            result,
            crate::edition::orgl::SplayResult::FullyContained,
            "splay on entire domain should return FullyContained"
        );
    }

    #[test]
    fn apply_edits_insert() {
        let ed = Edition::from_text("ac");
        let result = ed.apply_edits(&[EditionEdit::Insert(5, RangeElement::text("b".to_string()))]);
        let entries = result.all_entries();
        assert_eq!(entries.len(), 3, "should have 3 entries after insert");
        let text = result.to_text();
        assert!(text.contains('a'));
        assert!(text.contains('b'));
        assert!(text.contains('c'));
    }

    #[test]
    fn apply_edits_delete() {
        let ed = Edition::from_text("abc");
        let result = ed.apply_edits(&[EditionEdit::Delete(1)]);
        let entries = result.all_entries();
        assert_eq!(entries.len(), 2);
        assert_eq!(entries[0].0, 0);
        assert_eq!(entries[1].0, 1);
    }

    #[test]
    fn apply_edits_replace() {
        let ed = Edition::from_text("abc");
        let result =
            ed.apply_edits(&[EditionEdit::Replace(1, RangeElement::text("X".to_string()))]);
        assert_eq!(result.to_text(), "aXc");
    }

    #[test]
    fn apply_edits_batch() {
        let ed = Edition::from_text("abc");
        let result = ed.apply_edits(&[
            EditionEdit::Delete(0),
            EditionEdit::Insert(3, RangeElement::text("d".to_string())),
        ]);
        let text = result.to_text();
        assert!(text.contains('b'));
        assert!(text.contains('c'));
        assert!(text.contains('d'));
        assert!(!text.contains('a'));
    }

    #[test]
    fn apply_edits_noop() {
        let ed = Edition::from_text("abc");
        let result = ed.apply_edits(&[]);
        assert_eq!(ed.to_text(), result.to_text());
    }

    #[test]
    fn apply_edits_renumbers_sequential() {
        let ed = Edition::from_text("abc");
        let result = ed.apply_edits(&[EditionEdit::Delete(1)]);
        let positions: Vec<i64> = result.all_entries().iter().map(|(p, _)| *p).collect();
        assert_eq!(
            positions,
            vec![0, 1],
            "positions should be sequential after renumber"
        );
    }
}
