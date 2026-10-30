//! Cross-language transclusion — spike.
//!
//! The question: can a machine translation ride the existing PROV
//! provenance model as a first-class **derivation edge**, with the
//! same invariants the product already enforces for transclusions?
//!
//! Invariants under test:
//!
//! 1. **Content addressing.** A rendition is keyed by everything
//!    needed to reproduce it: source span (at a pinned revision, with
//!    its content hash), source and target language, provider, and
//!    model version. Same key must yield byte-identical output.
//! 2. **Links resolve to originals.** The rendition *derives from*
//!    the source span (`prov:wasDerivedFrom` through a translation
//!    activity). A rendition is never a link target; it is a
//!    rendition. Both ends stay visible.
//! 3. **No silent invalidation.** If the source text changes, the
//!    span's revision *and* hash change, so stale renditions become
//!    unreachable by key. If the model is upgraded, the model version
//!    changes, and a fresh rendition is computed under a new key.
//!    Nothing is "invalidated"; the old key simply stops being asked
//!    for.
//!
//! Design finding already: **source language is pinned on the edge,
//! not detected at call time.** If detection drifted, a stable key
//! would silently start producing different output — the exact rot
//! the content addressing exists to prevent.

use sha2::{Digest, Sha256};
use std::collections::HashMap;
use xudanu::edition::provenance::{
    generate_prov_id, ProvActivity, ProvDerivation, ProvEntity, ProvGeneration, ProvJsonDocument,
    ProvUsage, ProvValue,
};

/// Local ISO-8601 formatter — the product's `unix_to_iso8601` is
/// `pub(crate)`, which is itself a spike finding: emitting rendition
/// provenance from outside the crate would need it public (the
/// production emitter would live inside the crate, so no change).

/// BCP-47-ish language code ("de", "en"). Kept as a newtype-free
/// alias; the spike has no interest in validation.
pub type Lang = String;

fn sha256_hex(bytes: &[u8]) -> String {
    let mut h = Sha256::new();
    h.update(bytes);
    h.finalize()
        .iter()
        .map(|b| format!("{:02x}", b))
        .collect()
}

fn unix_to_iso8601(timestamp: u64) -> Option<String> {
    // Days since epoch -> civil date (Howard Hinnant's algorithm),
    // then a fixed UTC clock. Good enough for a spike; the product's
    // version does this properly.
    let days = (timestamp / 86_400) as i64;
    let secs = timestamp % 86_400;
    let z = days + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z.rem_euclid(146_097);
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365;
    let y = yoe + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = if m <= 2 { y + 1 } else { y };
    Some(format!(
        "{y:04}-{m:02}-{d:02}T{:02}:{:02}:{:02}Z",
        secs / 3600,
        (secs % 3600) / 60,
        secs % 60
    ))
}

/// Immutable address of a source span. Mirrors the fields
/// [`RangeElement::Transclusion`] already carries — `source_work_id`,
/// `char_start`/`char_end`, `source_revision`, `content_hash` — so
/// the translation edge keys off exactly what a transclusion pins.
///
/// The hash makes the address content-derived: the same work/range
/// at a different revision (or with different bytes) is a *different*
/// span, and therefore a different edge.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct SpanId {
    pub work_id: u64,
    pub revision: u64,
    pub char_start: usize,
    /// Exclusive char offset into the source work.
    pub char_end: usize,
    /// sha256 of the span text at this revision.
    pub content_hash: [u8; 32],
}

impl SpanId {
    pub fn from_span_text(
        work_id: u64,
        revision: u64,
        char_start: usize,
        text: &str,
    ) -> Self {
        let mut h = Sha256::new();
        h.update(text.as_bytes());
        let content_hash: [u8; 32] = h.finalize().into();
        SpanId {
            work_id,
            revision,
            char_start,
            char_end: char_start + text.chars().count(),
            content_hash,
        }
    }

    pub fn hash_hex(&self) -> String {
        self.content_hash.iter().map(|b| format!("{:02x}", b)).collect()
    }

    /// PROV entity id for the span: stable, QName-safe, derived from
    /// the address itself.
    pub fn prov_entity_id(&self) -> String {
        generate_prov_id(
            "xudanu:span",
            &format!(
                "{}_{}_{}_{}_{}",
                self.work_id,
                self.revision,
                self.char_start,
                self.char_end,
                self.hash_hex()
            ),
        )
    }
}

/// The translation edge: the complete reproduction tuple. This IS
/// the cache key — same tuple must yield byte-identical output.
///
/// Note `source_lang` is part of the key (see module doc): pinned,
/// never detected at resolve time.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct TranslationEdge {
    pub span: SpanId,
    pub source_lang: Lang,
    pub target_lang: Lang,
    /// Deployment identity, e.g. "libretranslate@1.7.1" — where the
    /// model runs, so two hosts running different builds never share
    /// a cache stream.
    pub provider: String,
    /// Model identity, e.g. "argos:de->en" — what did the translating.
    pub model_version: String,
}

impl TranslationEdge {
    /// Digest over the canonical serialization of the edge — the
    /// identity of the rendition stream it addresses.
    pub fn digest_hex(&self) -> String {
        let canonical = format!(
            "{}|{}|{}|{}|{}",
            self.span.prov_entity_id(),
            self.source_lang,
            self.target_lang,
            self.provider,
            self.model_version,
        );
        sha256_hex(canonical.as_bytes())
    }
}

/// A materialized rendition — content-addressed by its own checksum,
/// which the PROV entity carries so a reader can verify the bytes
/// they are reading against the bytes the edge produced.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Rendition {
    pub edge: TranslationEdge,
    pub text: String,
    /// sha256 of `text` — the rendition's own content address.
    pub checksum: [u8; 32],
    pub translated_at: u64,
}

impl Rendition {
    pub fn checksum_hex(&self) -> String {
        self.checksum.iter().map(|b| format!("{:02x}", b)).collect()
    }

    pub fn prov_entity_id(&self) -> String {
        generate_prov_id("xudanu:rendition", &self.edge.digest_hex())
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TranslateError {
    Unreachable(String),
    Provider(String),
}

impl std::fmt::Display for TranslateError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            TranslateError::Unreachable(m) => write!(f, "provider unreachable: {m}"),
            TranslateError::Provider(m) => write!(f, "provider error: {m}"),
        }
    }
}

/// What does the translating. One instance = one deployment of one
/// model; `id()` + `model_version()` are exactly the two parts of
/// edge identity the cache discriminates on.
pub trait TranslationProvider {
    fn id(&self) -> String;
    fn model_version(&self, source: &Lang, target: &Lang) -> String;
    fn translate(&self, text: &str, source: &Lang, target: &Lang) -> Result<String, TranslateError>;
    /// Number of translate calls served — the cache-hit proof.
    fn calls(&self) -> usize;
}

/// Content-addressed rendition store. Keyed by the full edge tuple;
/// the provider is consulted at most once per key.
pub struct RenditionCache {
    entries: HashMap<TranslationEdge, Rendition>,
    pub misses: usize,
}

impl Default for RenditionCache {
    fn default() -> Self {
        Self::new()
    }
}

impl RenditionCache {
    pub fn new() -> Self {
        RenditionCache { entries: HashMap::new(), misses: 0 }
    }

    pub fn len(&self) -> usize {
        self.entries.len()
    }

    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }

    /// Resolve an edge to a rendition. Cache hit: provider untouched,
    /// checksum re-verified (a cache that returns different bytes
    /// than it stored is a bug, not a mystery).
    pub fn resolve(
        &mut self,
        span: &SpanId,
        span_text: &str,
        source_lang: &Lang,
        target_lang: &Lang,
        provider: &dyn TranslationProvider,
    ) -> Result<Rendition, TranslateError> {
        let edge = TranslationEdge {
            span: span.clone(),
            source_lang: source_lang.clone(),
            target_lang: target_lang.clone(),
            provider: provider.id(),
            model_version: provider.model_version(source_lang, target_lang),
        };
        if let Some(hit) = self.entries.get(&edge) {
            debug_assert_eq!(sha256_hex(hit.text.as_bytes()), hit.checksum_hex());
            return Ok(hit.clone());
        }
        self.misses += 1;
        let text = provider.translate(span_text, source_lang, target_lang)?;
        let mut h = Sha256::new();
        h.update(text.as_bytes());
        let rendition = Rendition {
            edge,
            text,
            checksum: h.finalize().into(),
            translated_at: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .map(|d| d.as_secs())
                .unwrap_or(0),
        };
        self.entries.insert(rendition.edge.clone(), rendition.clone());
        Ok(rendition)
    }
}

/// Emit the rendition's provenance as real PROV-JSON, using the
/// product's own document type. Six records:
///
/// - entity: the source span (`xudanu:TextSpan`)
/// - entity: the rendition (`xudanu:Rendition`), carrying its
///   checksum so readers can verify bytes against endorsement
/// - activity: `xudanu:Translation` (provider, model, langs, time)
/// - used: the activity used the span
/// - wasGeneratedBy: the activity generated the rendition
/// - wasDerivedFrom: **the edge** — rendition ← span, via activity
pub fn rendition_prov(rendition: &Rendition) -> ProvJsonDocument {
    let mut doc = ProvJsonDocument::new();
    let span = &rendition.edge.span;
    let span_id = span.prov_entity_id();
    let rend_id = rendition.prov_entity_id();

    // -- entity: source span --------------------------------------
    let mut span_attrs = HashMap::new();
    span_attrs.insert(
        "prov:type".to_string(),
        ProvValue::qname("xudanu:TextSpan"),
    );
    span_attrs.insert(
        "xudanu:workId".to_string(),
        ProvValue::typed(&span.work_id.to_string(), "xsd:integer"),
    );
    span_attrs.insert(
        "xudanu:revision".to_string(),
        ProvValue::typed(&span.revision.to_string(), "xsd:integer"),
    );
    span_attrs.insert(
        "xudanu:charStart".to_string(),
        ProvValue::typed(&span.char_start.to_string(), "xsd:integer"),
    );
    span_attrs.insert(
        "xudanu:charEnd".to_string(),
        ProvValue::typed(&span.char_end.to_string(), "xsd:integer"),
    );
    span_attrs.insert(
        "xudanu:contentHash".to_string(),
        ProvValue::typed(&span.hash_hex(), "xsd:hexBinary"),
    );
    doc.entity.insert(span_id.clone(), ProvEntity { attributes: span_attrs });

    // -- entity: rendition ----------------------------------------
    let mut rend_attrs = HashMap::new();
    rend_attrs.insert(
        "prov:type".to_string(),
        ProvValue::qname("xudanu:Rendition"),
    );
    rend_attrs.insert(
        "xudanu:sourceLang".to_string(),
        ProvValue::string(&rendition.edge.source_lang),
    );
    rend_attrs.insert(
        "xudanu:targetLang".to_string(),
        ProvValue::string(&rendition.edge.target_lang),
    );
    rend_attrs.insert(
        "xudanu:provider".to_string(),
        ProvValue::string(&rendition.edge.provider),
    );
    rend_attrs.insert(
        "xudanu:modelVersion".to_string(),
        ProvValue::string(&rendition.edge.model_version),
    );
    rend_attrs.insert(
        "xudanu:checksum".to_string(),
        ProvValue::typed(&rendition.checksum_hex(), "xsd:hexBinary"),
    );
    rend_attrs.insert(
        "xudanu:qualityGrade".to_string(),
        // Honest labeling: gisting-grade until a human (or a
        // quorum) says otherwise.
        ProvValue::string("machine-gisting"),
    );
    doc.entity.insert(rend_id.clone(), ProvEntity { attributes: rend_attrs });

    // -- activity: translation ------------------------------------
    let act_id = generate_prov_id("xudanu:translation", &rendition.edge.digest_hex());
    let mut act_attrs = HashMap::new();
    act_attrs.insert(
        "prov:type".to_string(),
        ProvValue::qname("xudanu:Translation"),
    );
    act_attrs.insert(
        "xudanu:provider".to_string(),
        ProvValue::string(&rendition.edge.provider),
    );
    act_attrs.insert(
        "xudanu:modelVersion".to_string(),
        ProvValue::string(&rendition.edge.model_version),
    );
    let time = unix_to_iso8601(rendition.translated_at);
    doc.activity.insert(
        act_id.clone(),
        ProvActivity {
            start_time: time.clone(),
            end_time: time,
            attributes: act_attrs,
        },
    );

    // -- used: activity ← span ------------------------------------
    doc.used.insert(
        generate_prov_id(&format!("{act_id}:used"), "span"),
        ProvUsage {
            activity: act_id.clone(),
            entity: span_id.clone(),
            time: None,
            attributes: HashMap::new(),
        },
    );

    // -- wasGeneratedBy: rendition ← activity ---------------------
    doc.wasGeneratedBy.insert(
        generate_prov_id(&format!("{act_id}:gen"), "rendition"),
        ProvGeneration {
            entity: rend_id.clone(),
            activity: Some(act_id.clone()),
            time: None,
            attributes: HashMap::new(),
        },
    );

    // -- wasDerivedFrom: THE EDGE ---------------------------------
    doc.wasDerivedFrom.insert(
        generate_prov_id(&format!("{act_id}:derivation"), "edge"),
        ProvDerivation {
            generated_entity: rend_id,
            activity: Some(act_id),
            usage: None,
            generation: None,
            used_entity: span_id,
            attributes: HashMap::new(),
        },
    );

    doc
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Deterministic mock with a canned table — visibly
    /// gisting-grade output, no network.
    pub struct MockProvider {
        canned: Vec<(&'static str, &'static str)>,
        calls: std::cell::Cell<usize>,
    }

    impl MockProvider {
        pub fn new() -> Self {
            MockProvider {
                canned: vec![(
                    "Es irrt der Mensch, solang er strebt. Wer immer strebend sich bemüht, den können wir erlösen.",
                    "Man errs, as long as he strives. Whoever strives with all his might, that man we can redeem.",
                )],
                calls: std::cell::Cell::new(0),
            }
        }
    }

    impl Default for MockProvider {
        fn default() -> Self {
            Self::new()
        }
    }

    impl TranslationProvider for MockProvider {
        fn id(&self) -> String {
            "mock@spike".to_string()
        }
        fn model_version(&self, _s: &Lang, _t: &Lang) -> String {
            "mock:v1".to_string()
        }
        fn translate(&self, text: &str, _s: &Lang, _t: &Lang) -> Result<String, TranslateError> {
            self.calls.set(self.calls.get() + 1);
            for (k, v) in &self.canned {
                if *k == text {
                    return Ok(v.to_string());
                }
            }
            Ok(format!("[machine rendition] {text}"))
        }
        fn calls(&self) -> usize {
            self.calls.get()
        }
    }

    /// Same provider, bumped model version — simulates an upgrade.
    struct BumpedProvider(MockProvider);

    impl TranslationProvider for BumpedProvider {
        fn id(&self) -> String {
            self.0.id()
        }
        fn model_version(&self, s: &Lang, t: &Lang) -> String {
            self.0.model_version(s, t) + ".1"
        }
        fn translate(&self, text: &str, s: &Lang, t: &Lang) -> Result<String, TranslateError> {
            self.0.translate(text, s, t)
        }
        fn calls(&self) -> usize {
            self.0.calls()
        }
    }

    const DE: &str = "Es irrt der Mensch, solang er strebt. Wer immer strebend sich bemüht, den können wir erlösen.";

    fn span() -> SpanId {
        SpanId::from_span_text(1, 7, 120, DE)
    }

    #[test]
    fn resolve_hits_provider_once_per_edge() {
        let mut cache = RenditionCache::new();
        let p = MockProvider::new();
        let de = "de".to_string();
        let en = "en".to_string();
        let r1 = cache.resolve(&span(), DE, &de, &en, &p).unwrap();
        let r2 = cache.resolve(&span(), DE, &de, &en, &p).unwrap();
        assert_eq!(p.calls(), 1, "second resolve must be a cache hit");
        assert_eq!(r1, r2, "same edge must yield the identical rendition");
    }

    #[test]
    fn model_bump_is_a_new_edge_not_a_stale_hit() {
        let mut cache = RenditionCache::new();
        let de = "de".to_string();
        let en = "en".to_string();
        let v1 = MockProvider::new();
        cache.resolve(&span(), DE, &de, &en, &v1).unwrap();
        let bumped = BumpedProvider(MockProvider::new());
        cache.resolve(&span(), DE, &de, &en, &bumped).unwrap();
        assert_eq!(cache.len(), 2, "model upgrade must not reuse the v1 rendition");
        assert_eq!(bumped.calls(), 1);
    }

    #[test]
    fn source_edit_changes_the_key() {
        let de = "de".to_string();
        let en = "en".to_string();
        let s1 = SpanId::from_span_text(1, 7, 120, DE);
        let s2 = SpanId::from_span_text(1, 8, 120, DE); // revised work
        assert_ne!(s1, s2, "revision bump is a different span");
        let mut cache = RenditionCache::new();
        let p = MockProvider::new();
        cache.resolve(&s1, DE, &de, &en, &p).unwrap();
        cache.resolve(&s2, DE, &de, &en, &p).unwrap();
        assert_eq!(cache.len(), 2, "stale renditions are unreachable by key, not invalidated");
    }

    #[test]
    fn renditions_are_content_addressed() {
        let mut cache = RenditionCache::new();
        let de = "de".to_string();
        let en = "en".to_string();
        let p = MockProvider::new();
        let r = cache.resolve(&span(), DE, &de, &en, &p).unwrap();
        assert_eq!(r.checksum_hex(), sha256_hex(r.text.as_bytes()));
    }

    /// The product invariant: a rendition is never a link target —
    /// it derives from the original, and the PROV graph says so in
    /// a machine-checkable way.
    #[test]
    fn prov_links_resolve_to_original() {
        let mut cache = RenditionCache::new();
        let de = "de".to_string();
        let en = "en".to_string();
        let p = MockProvider::new();
        let r = cache.resolve(&span(), DE, &de, &en, &p).unwrap();
        let doc = rendition_prov(&r);

        let rend_id = r.prov_entity_id();
        let span_id = r.edge.span.prov_entity_id();
        assert!(doc.entity.contains_key(&rend_id), "rendition entity present");
        assert!(doc.entity.contains_key(&span_id), "source span entity present");

        let deriv = doc
            .wasDerivedFrom
            .values()
            .find(|d| d.generated_entity == rend_id)
            .expect("rendition has a wasDerivedFrom record");
        assert_eq!(deriv.used_entity, span_id, "derivation points at the ORIGINAL span");
        assert!(deriv.activity.is_some(), "derivation names the translation activity");

        // The activity is in the graph, and the used/wasGeneratedBy
        // pair closes the chain: span <- used <- activity -> generated -> rendition.
        let act = deriv.activity.clone().unwrap();
        assert!(doc.activity.contains_key(&act));
        assert!(doc.used.values().any(|u| u.activity == act && u.entity == span_id));
        assert!(doc
            .wasGeneratedBy
            .values()
            .any(|g| g.activity.as_deref() == Some(act.as_str()) && g.entity == rend_id));
    }

    /// Real PROV-JSON, not a lookalike: the document round-trips
    /// through serde with the product's serde derives.
    #[test]
    fn prov_json_roundtrips() {
        let mut cache = RenditionCache::new();
        let de = "de".to_string();
        let en = "en".to_string();
        let p = MockProvider::new();
        let r = cache.resolve(&span(), DE, &de, &en, &p).unwrap();
        let doc = rendition_prov(&r);
        let json = serde_json::to_string(&doc).unwrap();
        let back: ProvJsonDocument = serde_json::from_str(&json).unwrap();
        assert_eq!(doc, back);
        assert!(json.contains("wasDerivedFrom"), "serializes under the PROV-JSON key");
    }
}
