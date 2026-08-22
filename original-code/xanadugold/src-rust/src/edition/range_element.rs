use super::blob_store::ImageOverlay;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct RangeElementId(pub u64);

impl RangeElementId {
    pub fn new(id: u64) -> Self {
        RangeElementId(id)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub enum RangeElement {
    Data {
        bytes: Vec<u8>,
    },
    Text {
        text: String,
    },
    Edition {
        edition_id: RangeElementId,
    },
    Label {
        label_id: RangeElementId,
        inner: Box<RangeElement>,
    },
    PlaceHolder {
        id: RangeElementId,
    },
    IDHolder {
        id: u64,
    },
    Work {
        work_id: RangeElementId,
    },
    Blob {
        content_hash: u64,
        mime_type: String,
        byte_size: u64,
        #[cfg_attr(feature = "serde", serde(default))]
        width: Option<u32>,
        #[cfg_attr(feature = "serde", serde(default))]
        height: Option<u32>,
        #[cfg_attr(feature = "serde", serde(default))]
        caption: Option<String>,
    },
    Overlay {
        overlay: ImageOverlay,
    },
    Transclusion {
        source_work_id: u64,
        char_start: usize,
        char_end: usize,
        placed_at: u64,
        placed_by: Option<u64>,
        #[cfg_attr(
            feature = "serde",
            serde(default, skip_serializing_if = "Option::is_none")
        )]
        content_hash: Option<[u8; 32]>,
        #[cfg_attr(
            feature = "serde",
            serde(default, skip_serializing_if = "Option::is_none")
        )]
        source_revision: Option<u64>,
    },
    StructuralTransclusion {
        source_work_id: u64,
        entry_start: i64,
        entry_end: i64,
        source_crum: [u8; 32],
        placed_at: u64,
        placed_by: Option<u64>,
        #[cfg_attr(
            feature = "serde",
            serde(default, skip_serializing_if = "Option::is_none")
        )]
        source_revision: Option<u64>,
        #[cfg_attr(
            feature = "serde",
            serde(default, skip_serializing_if = "Option::is_none")
        )]
        cached_content: Option<String>,
        /// Generation of the source work at cache time (FR-37 Phase 2).
        /// Monotonic per source, bumped on every revise; the cheap
        /// in-memory staleness check. Mismatch -> re-resolve at read
        /// time. `source_crum` remains the cross-restart authority.
        #[cfg_attr(
            feature = "serde",
            serde(default, skip_serializing_if = "Option::is_none")
        )]
        source_generation: Option<u64>,
    },
    /// Content computed on demand from another work (FR-37 Phase 3) —
    /// the Rust analogue of Gold's virtual range elements
    /// (loavesx.hxx: fetch "makes a virtual range element using the
    /// edition and globalKey"). The spec PINS the source revision at
    /// placement time (edit-time pinning), so resolution is a pure
    /// function of the spec — replicas converge without communicating,
    /// and the cache never goes stale (pinned revisions are
    /// immutable). Unmaterialized, the element contributes zero chars
    /// (same reader semantics as an unstamped StructuralTransclusion).
    Virtual {
        spec: VirtualSpec,
        #[cfg_attr(
            feature = "serde",
            serde(default, skip_serializing_if = "Option::is_none")
        )]
        cached_content: Option<String>,
    },
}

/// Deterministic identity of a virtual element (FR-37 Phase 3): what
/// to resolve, pinned to an immutable revision. Two replicas holding
/// the same spec hold the same content by construction.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct VirtualSpec {
    pub source_work_id: u64,
    pub char_start: usize,
    pub char_end: usize,
    /// Source revision at placement. Always pinned; resolution goes
    /// through revision history, never "latest".
    pub revision: u64,
    pub placed_at: u64,
    pub placed_by: Option<u64>,
}

impl RangeElement {
    pub fn data(bytes: Vec<u8>) -> Self {
        RangeElement::Data { bytes }
    }

    pub fn text(s: impl Into<String>) -> Self {
        RangeElement::Text { text: s.into() }
    }

    pub fn edition(id: u64) -> Self {
        RangeElement::Edition {
            edition_id: RangeElementId::new(id),
        }
    }

    pub fn placeholder(id: u64) -> Self {
        RangeElement::PlaceHolder {
            id: RangeElementId::new(id),
        }
    }

    pub fn label(id: u64, inner: RangeElement) -> Self {
        RangeElement::Label {
            label_id: RangeElementId::new(id),
            inner: Box::new(inner),
        }
    }

    pub fn id_holder(id: u64) -> Self {
        RangeElement::IDHolder { id }
    }

    pub fn work(id: u64) -> Self {
        RangeElement::Work {
            work_id: RangeElementId::new(id),
        }
    }

    pub fn blob(content_hash: u64, mime_type: impl Into<String>, byte_size: u64) -> Self {
        RangeElement::Blob {
            content_hash,
            mime_type: mime_type.into(),
            byte_size,
            width: None,
            height: None,
            caption: None,
        }
    }

    pub fn blob_with_dims(
        content_hash: u64,
        mime_type: impl Into<String>,
        byte_size: u64,
        width: u32,
        height: u32,
    ) -> Self {
        RangeElement::Blob {
            content_hash,
            mime_type: mime_type.into(),
            byte_size,
            width: Some(width),
            height: Some(height),
            caption: None,
        }
    }

    pub fn blob_with_caption(
        content_hash: u64,
        mime_type: impl Into<String>,
        byte_size: u64,
        width: Option<u32>,
        height: Option<u32>,
        caption: Option<String>,
    ) -> Self {
        RangeElement::Blob {
            content_hash,
            mime_type: mime_type.into(),
            byte_size,
            width,
            height,
            caption,
        }
    }

    pub fn overlay(image_overlay: ImageOverlay) -> Self {
        RangeElement::Overlay {
            overlay: image_overlay,
        }
    }

    pub fn transclusion(source_work_id: u64, char_start: usize, char_end: usize) -> Self {
        Self::transclusion_with_meta(source_work_id, char_start, char_end, 0, None)
    }

    pub fn transclusion_with_meta(
        source_work_id: u64,
        char_start: usize,
        char_end: usize,
        placed_at: u64,
        placed_by: Option<u64>,
    ) -> Self {
        let (start, end) = if char_start <= char_end {
            (char_start, char_end)
        } else {
            (char_end, char_start)
        };
        RangeElement::Transclusion {
            source_work_id,
            char_start: start,
            char_end: end,
            placed_at,
            placed_by,
            content_hash: None,
            source_revision: None,
        }
    }

    /// Set the content hash and source revision on a Transclusion element.
    pub fn set_transclusion_hash(&mut self, content_hash: [u8; 32], source_revision: u64) {
        if let RangeElement::Transclusion {
            content_hash: ref mut ch,
            source_revision: ref mut sr,
            ..
        } = self
        {
            *ch = Some(content_hash);
            *sr = Some(source_revision);
        }
    }

    pub fn structural_transclusion(
        source_work_id: u64,
        entry_start: i64,
        entry_end: i64,
        source_crum: [u8; 32],
        placed_at: u64,
        placed_by: Option<u64>,
    ) -> Self {
        RangeElement::StructuralTransclusion {
            source_work_id,
            entry_start,
            entry_end,
            source_crum,
            placed_at,
            placed_by,
            source_revision: None,
            cached_content: None,
            source_generation: None,
        }
    }

    pub fn set_structural_revision(&mut self, revision: u64) {
        if let RangeElement::StructuralTransclusion {
            source_revision: ref mut sr,
            ..
        } = self
        {
            *sr = Some(revision);
        }
    }

    pub fn set_cached_content(&mut self, content: String) {
        if let RangeElement::StructuralTransclusion {
            cached_content: ref mut cc,
            ..
        } = self
        {
            *cc = Some(content);
        }
    }

    /// Stamp the generation the cache was built against (FR-37 Phase 2).
    pub fn set_source_generation(&mut self, generation: u64) {
        if let RangeElement::StructuralTransclusion {
            source_generation: ref mut g,
            ..
        } = self
        {
            *g = Some(generation);
        }
    }

    /// Virtual element constructor (FR-37 Phase 3). The spec must
    /// carry a pinned revision — placement call sites stamp the
    /// source's current revision at creation time.
    pub fn virtual_element(spec: VirtualSpec) -> Self {
        RangeElement::Virtual {
            spec,
            cached_content: None,
        }
    }

    pub fn virtual_spec(&self) -> Option<&VirtualSpec> {
        if let RangeElement::Virtual { spec, .. } = self {
            Some(spec)
        } else {
            None
        }
    }

    pub fn set_virtual_content(&mut self, content: String) {
        if let RangeElement::Virtual {
            cached_content: ref mut cc,
            ..
        } = self
        {
            *cc = Some(content);
        }
    }

    pub fn is_virtual(&self) -> bool {
        matches!(self, RangeElement::Virtual { .. })
    }

    pub fn source_generation(&self) -> Option<u64> {
        if let RangeElement::StructuralTransclusion {
            source_generation: g,
            ..
        } = self
        {
            *g
        } else {
            None
        }
    }

    /// Is the cached content usable without re-resolution? (FR-37
    /// Phase 2.) True when a generation was stamped and the source's
    /// current generation matches it. No stamped generation -> false
    /// (legacy caches re-resolve once, then carry generations).
    pub fn cache_is_current(&self, current_generation: u64) -> bool {
        if let RangeElement::StructuralTransclusion {
            source_generation: Some(g),
            ..
        } = self
        {
            *g == current_generation
        } else {
            false
        }
    }

    pub fn cached_content(&self) -> Option<&str> {
        if let RangeElement::StructuralTransclusion {
            cached_content: Some(cc),
            ..
        } = self
        {
            Some(cc)
        } else {
            None
        }
    }

    pub fn is_structural_transclusion(&self) -> bool {
        matches!(self, RangeElement::StructuralTransclusion { .. })
    }

    pub fn is_any_transclusion(&self) -> bool {
        matches!(
            self,
            RangeElement::Transclusion { .. } | RangeElement::StructuralTransclusion { .. }
        )
    }

    /// Get the content hash from a Transclusion element, if set.
    pub fn transclusion_content_hash(&self) -> Option<[u8; 32]> {
        if let RangeElement::Transclusion { content_hash, .. } = self {
            *content_hash
        } else {
            None
        }
    }

    pub fn is_data(&self) -> bool {
        matches!(self, RangeElement::Data { .. })
    }

    pub fn is_text(&self) -> bool {
        matches!(self, RangeElement::Text { .. })
    }

    pub fn is_edition(&self) -> bool {
        matches!(self, RangeElement::Edition { .. })
    }

    pub fn as_text(&self) -> Option<&str> {
        match self {
            RangeElement::Text { text } => Some(text),
            RangeElement::StructuralTransclusion {
                cached_content: Some(cc),
                ..
            } => Some(cc),
            RangeElement::Virtual {
                cached_content: Some(cc),
                ..
            } => Some(cc),
            _ => None,
        }
    }

    pub fn as_bytes(&self) -> Option<&[u8]> {
        match self {
            RangeElement::Data { bytes } => Some(bytes),
            _ => None,
        }
    }

    pub fn as_edition_id(&self) -> Option<u64> {
        match self {
            RangeElement::Edition { edition_id } => Some(edition_id.0),
            _ => None,
        }
    }

    pub fn as_work_id(&self) -> Option<u64> {
        match self {
            RangeElement::Work { work_id } => Some(work_id.0),
            _ => None,
        }
    }

    pub fn is_blob(&self) -> bool {
        matches!(self, RangeElement::Blob { .. })
    }

    pub fn is_overlay(&self) -> bool {
        matches!(self, RangeElement::Overlay { .. })
    }

    pub fn is_transclusion(&self) -> bool {
        matches!(self, RangeElement::Transclusion { .. })
    }

    pub fn as_transclusion(&self) -> Option<(u64, usize, usize)> {
        match self {
            RangeElement::Transclusion {
                source_work_id,
                char_start,
                char_end,
                ..
            } => Some((*source_work_id, *char_start, *char_end)),
            _ => None,
        }
    }

    pub fn as_transclusion_full(&self) -> Option<(u64, usize, usize, u64, Option<u64>)> {
        match self {
            RangeElement::Transclusion {
                source_work_id,
                char_start,
                char_end,
                placed_at,
                placed_by,
                content_hash: _,
                source_revision: _,
            } => Some((
                *source_work_id,
                *char_start,
                *char_end,
                *placed_at,
                *placed_by,
            )),
            _ => None,
        }
    }

    pub fn as_label_inner(&self) -> Option<&RangeElement> {
        match self {
            RangeElement::Label { inner, .. } => Some(inner),
            _ => None,
        }
    }

    pub fn label_id_value(&self) -> Option<u64> {
        match self {
            RangeElement::Label { label_id, .. } => Some(label_id.0),
            _ => None,
        }
    }

    pub fn as_blob(&self) -> Option<(u64, &str, u64, Option<u32>, Option<u32>)> {
        match self {
            RangeElement::Blob {
                content_hash,
                mime_type,
                byte_size,
                width,
                height,
                ..
            } => Some((
                *content_hash,
                mime_type.as_str(),
                *byte_size,
                *width,
                *height,
            )),
            _ => None,
        }
    }

    pub fn blob_caption(&self) -> Option<&str> {
        match self {
            RangeElement::Blob { caption, .. } => caption.as_deref(),
            _ => None,
        }
    }

    pub fn as_blob_hash(&self) -> Option<u64> {
        match self {
            RangeElement::Blob { content_hash, .. } => Some(*content_hash),
            RangeElement::Overlay { overlay } => Some(overlay.base_hash),
            _ => None,
        }
    }

    pub fn as_overlay(&self) -> Option<&ImageOverlay> {
        match self {
            RangeElement::Overlay { overlay } => Some(overlay),
            _ => None,
        }
    }

    pub fn is_image(&self) -> bool {
        match self {
            RangeElement::Blob { mime_type, .. } => mime_type.starts_with("image/"),
            _ => false,
        }
    }

    pub fn content_fingerprint(&self) -> [u8; 32] {
        match self {
            RangeElement::Text { text } => {
                let mut hasher = blake3::Hasher::new();
                hasher.update(b"text:");
                hasher.update(text.as_bytes());
                *hasher.finalize().as_bytes()
            }
            // FR-37 Phase 3 determinism rule: the fingerprint covers
            // the SPEC, never the cache — two replicas holding the
            // same VirtualSpec hash identically without resolution,
            // so CRDT alignment/diff never needs to materialize
            // untouched virtual content.
            RangeElement::Virtual { spec, .. } => {
                let mut hasher = blake3::Hasher::new();
                hasher.update(b"virtual:");
                hasher.update(&spec.source_work_id.to_le_bytes());
                hasher.update(&spec.char_start.to_le_bytes());
                hasher.update(&spec.char_end.to_le_bytes());
                hasher.update(&spec.revision.to_le_bytes());
                *hasher.finalize().as_bytes()
            }
            RangeElement::Data { bytes } => {
                let mut hasher = blake3::Hasher::new();
                hasher.update(b"data:");
                hasher.update(bytes);
                *hasher.finalize().as_bytes()
            }
            RangeElement::Edition { edition_id } => {
                let mut buf = b"edition:".to_vec();
                buf.extend_from_slice(&edition_id.0.to_le_bytes());
                blake3::hash(&buf).into()
            }
            RangeElement::Label { label_id, inner } => {
                let mut hasher = blake3::Hasher::new();
                hasher.update(b"label:");
                hasher.update(&label_id.0.to_le_bytes());
                hasher.update(&inner.content_fingerprint());
                *hasher.finalize().as_bytes()
            }
            RangeElement::PlaceHolder { id } => {
                let mut buf = b"placeholder:".to_vec();
                buf.extend_from_slice(&id.0.to_le_bytes());
                blake3::hash(&buf).into()
            }
            RangeElement::IDHolder { id } => {
                let mut buf = b"idholder:".to_vec();
                buf.extend_from_slice(&id.to_le_bytes());
                blake3::hash(&buf).into()
            }
            RangeElement::Work { work_id } => {
                let mut buf = b"work:".to_vec();
                buf.extend_from_slice(&work_id.0.to_le_bytes());
                blake3::hash(&buf).into()
            }
            RangeElement::Blob { content_hash, .. } => {
                let mut buf = b"blob:".to_vec();
                buf.extend_from_slice(&content_hash.to_le_bytes());
                blake3::hash(&buf).into()
            }
            RangeElement::Overlay { overlay } => {
                let mut hasher = blake3::Hasher::new();
                hasher.update(b"overlay:");
                hasher.update(&overlay.base_hash.to_le_bytes());
                for op in &overlay.operations {
                    hasher.update(format!("{:?}", op).as_bytes());
                }
                *hasher.finalize().as_bytes()
            }
            RangeElement::Transclusion {
                source_work_id,
                char_start,
                char_end,
                ..
            } => {
                let mut hasher = blake3::Hasher::new();
                hasher.update(b"transclusion:");
                hasher.update(&source_work_id.to_le_bytes());
                hasher.update(&(*char_start as u64).to_le_bytes());
                hasher.update(&(*char_end as u64).to_le_bytes());
                *hasher.finalize().as_bytes()
            }
            RangeElement::StructuralTransclusion {
                source_work_id,
                entry_start,
                entry_end,
                source_crum,
                ..
            } => {
                let mut hasher = blake3::Hasher::new();
                hasher.update(b"structural_transclusion:");
                hasher.update(&source_work_id.to_le_bytes());
                hasher.update(&entry_start.to_le_bytes());
                hasher.update(&entry_end.to_le_bytes());
                hasher.update(source_crum);
                *hasher.finalize().as_bytes()
            }
        }
    }

    pub fn is_content_addressable(&self) -> bool {
        matches!(self, RangeElement::Text { .. } | RangeElement::Data { .. })
    }

    pub fn char_len(&self) -> usize {
        match self {
            RangeElement::Text { text } => text.chars().count(),
            RangeElement::StructuralTransclusion {
                cached_content: Some(cc),
                ..
            } => cc.chars().count(),
            // Unmaterialized Virtual: zero chars (readers see it the
            // moment resolution runs — FR-37 Phase 3 reader contract).
            RangeElement::Virtual {
                cached_content: Some(cc),
                ..
            } => cc.chars().count(),
            _ => 0,
        }
    }
}

#[derive(Debug)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct Carrier {
    pub label: Option<RangeElementId>,
    pub element: RangeElement,
    #[cfg_attr(feature = "serde", serde(skip))]
    char_len_memo: std::sync::atomic::AtomicU32,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub provenance: Option<super::provenance::ElementProvenance>,
}

impl Clone for Carrier {
    fn clone(&self) -> Self {
        Carrier {
            label: self.label.clone(),
            element: self.element.clone(),
            provenance: self.provenance.clone(),
            char_len_memo: std::sync::atomic::AtomicU32::new(
                self.char_len_memo
                    .load(std::sync::atomic::Ordering::Relaxed),
            ),
        }
    }
}

impl PartialEq for Carrier {
    fn eq(&self, other: &Self) -> bool {
        // Memo excluded: identity is label + element + provenance.
        self.label == other.label
            && self.element == other.element
            && self.provenance == other.provenance
    }
}

impl Carrier {
    pub fn new(element: RangeElement) -> Self {
        Carrier {
            label: None,
            element,
            provenance: None,
            char_len_memo: std::sync::atomic::AtomicU32::new(0),
        }
    }

    pub fn labelled(label_id: RangeElementId, element: RangeElement) -> Self {
        Carrier {
            label: Some(label_id),
            element,
            provenance: None,
            char_len_memo: std::sync::atomic::AtomicU32::new(0),
        }
    }

    pub fn with_provenance(mut self, prov: super::provenance::ElementProvenance) -> Self {
        self.provenance = Some(prov);
        self
    }

    /// Replace the element, invalidating the char-length memo.
    pub fn set_element(&mut self, element: RangeElement) {
        self.char_len_memo
            .store(0, std::sync::atomic::Ordering::Relaxed);
        self.element = element;
    }

    pub fn char_len(&self) -> usize {
        // Memoized (FR-43 perf): chars().count() is O(text); this is
        // called O(entries) times per delta op — quadratic on long
        // docs. Memo invalidates naturally: clones copy the memo,
        // and any element replacement builds fresh carriers. A stale
        // memo is impossible via public API (element is only set at
        // construction or via with_* builders that create new
        // carriers through Clone + field update — clone copies memo
        // AND element together).
        let m = self
            .char_len_memo
            .load(std::sync::atomic::Ordering::Relaxed);
        if m != 0 {
            return (m - 1) as usize;
        }
        let n = self.element.char_len();
        self.char_len_memo
            .store((n + 1) as u32, std::sync::atomic::Ordering::Relaxed);
        n
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn text_element() {
        let e = RangeElement::text("hello");
        assert!(e.is_text());
        assert_eq!(e.as_text(), Some("hello"));
        assert!(!e.is_data());
    }

    #[test]
    fn data_element() {
        let e = RangeElement::data(vec![1, 2, 3]);
        assert!(e.is_data());
        assert_eq!(e.as_bytes(), Some(&[1u8, 2, 3][..]));
    }

    #[test]
    fn edition_element() {
        let e = RangeElement::edition(42);
        assert!(e.is_edition());
    }

    #[test]
    fn label_wraps_inner() {
        let inner = RangeElement::text("hi");
        let labelled = RangeElement::label(7, inner.clone());
        match &labelled {
            RangeElement::Label {
                label_id,
                inner: boxed,
            } => {
                assert_eq!(label_id.0, 7);
                assert_eq!(**boxed, inner);
            }
            _ => panic!("expected Label"),
        }
    }

    #[test]
    fn serde_round_trip_text() {
        #[cfg(feature = "serde")]
        {
            let e = RangeElement::text("hello world");
            let json = serde_json::to_string(&e).unwrap();
            let e2: RangeElement = serde_json::from_str(&json).unwrap();
            assert_eq!(e, e2);
        }
    }

    #[test]
    fn serde_round_trip_label() {
        #[cfg(feature = "serde")]
        {
            let e = RangeElement::label(7, RangeElement::text("hi"));
            let json = serde_json::to_string(&e).unwrap();
            let e2: RangeElement = serde_json::from_str(&json).unwrap();
            assert_eq!(e, e2);
        }
    }

    #[test]
    fn carrier_unlabelled() {
        let c = Carrier::new(RangeElement::text("x"));
        assert!(c.label.is_none());
    }

    #[test]
    fn carrier_labelled() {
        let c = Carrier::labelled(RangeElementId::new(1), RangeElement::text("x"));
        assert!(c.label.is_some());
    }

    #[test]
    fn fingerprint_text_deterministic() {
        let e1 = RangeElement::text("hello");
        let e2 = RangeElement::text("hello");
        assert_eq!(e1.content_fingerprint(), e2.content_fingerprint());
    }

    #[test]
    fn fingerprint_text_different() {
        let e1 = RangeElement::text("hello");
        let e2 = RangeElement::text("world");
        assert_ne!(e1.content_fingerprint(), e2.content_fingerprint());
    }

    #[test]
    fn fingerprint_data_deterministic() {
        let e1 = RangeElement::data(vec![1, 2, 3]);
        let e2 = RangeElement::data(vec![1, 2, 3]);
        assert_eq!(e1.content_fingerprint(), e2.content_fingerprint());
    }

    #[test]
    fn fingerprint_data_different() {
        let e1 = RangeElement::data(vec![1, 2, 3]);
        let e2 = RangeElement::data(vec![4, 5, 6]);
        assert_ne!(e1.content_fingerprint(), e2.content_fingerprint());
    }

    #[test]
    fn fingerprint_edition_by_id() {
        let e1 = RangeElement::edition(42);
        let e2 = RangeElement::edition(42);
        assert_eq!(e1.content_fingerprint(), e2.content_fingerprint());
    }

    #[test]
    fn fingerprint_edition_different() {
        let e1 = RangeElement::edition(42);
        let e2 = RangeElement::edition(99);
        assert_ne!(e1.content_fingerprint(), e2.content_fingerprint());
    }

    #[test]
    fn fingerprint_placeholder_unique_per_id() {
        let e1 = RangeElement::placeholder(1);
        let e2 = RangeElement::placeholder(2);
        assert_ne!(e1.content_fingerprint(), e2.content_fingerprint());
    }

    #[test]
    fn fingerprint_blob_by_hash() {
        let e1 = RangeElement::blob(0xabcd, "image/png", 100);
        let e2 = RangeElement::blob(0xabcd, "image/jpeg", 200);
        assert_eq!(
            e1.content_fingerprint(),
            e2.content_fingerprint(),
            "blob fingerprint should be by content_hash only"
        );
    }

    #[test]
    fn fingerprint_text_not_equal_data() {
        let e1 = RangeElement::text("hello");
        let e2 = RangeElement::data(b"hello".to_vec());
        assert_ne!(
            e1.content_fingerprint(),
            e2.content_fingerprint(),
            "Text and Data with same bytes should have different fingerprints due to type prefix"
        );
    }

    #[test]
    fn is_content_addressable() {
        assert!(RangeElement::text("x").is_content_addressable());
        assert!(RangeElement::data(vec![1]).is_content_addressable());
        assert!(!RangeElement::edition(1).is_content_addressable());
        assert!(!RangeElement::placeholder(1).is_content_addressable());
        assert!(!RangeElement::work(1).is_content_addressable());
    }

    #[test]
    fn transclusion_constructor() {
        let e = RangeElement::transclusion(42, 10, 20);
        assert!(e.is_transclusion());
        assert_eq!(e.as_transclusion(), Some((42, 10, 20)));
    }

    #[test]
    fn transclusion_swaps_reversed_offsets() {
        let e = RangeElement::transclusion(42, 20, 10);
        assert_eq!(e.as_transclusion(), Some((42, 10, 20)));
    }

    #[test]
    fn transclusion_char_len_zero() {
        let e = RangeElement::transclusion(42, 10, 20);
        assert_eq!(e.char_len(), 0);
    }

    #[test]
    fn transclusion_fingerprint_deterministic() {
        let e1 = RangeElement::transclusion(42, 10, 20);
        let e2 = RangeElement::transclusion(42, 10, 20);
        assert_eq!(e1.content_fingerprint(), e2.content_fingerprint());
    }

    #[test]
    fn transclusion_fingerprint_different_source() {
        let e1 = RangeElement::transclusion(42, 10, 20);
        let e2 = RangeElement::transclusion(99, 10, 20);
        assert_ne!(e1.content_fingerprint(), e2.content_fingerprint());
    }

    #[test]
    fn transclusion_fingerprint_different_offsets() {
        let e1 = RangeElement::transclusion(42, 10, 20);
        let e2 = RangeElement::transclusion(42, 10, 21);
        assert_ne!(e1.content_fingerprint(), e2.content_fingerprint());
    }

    #[test]
    fn transclusion_not_text() {
        let e = RangeElement::transclusion(42, 0, 5);
        assert!(!e.is_text());
        assert_eq!(e.as_text(), None);
    }

    #[test]
    #[cfg(feature = "serde")]
    fn transclusion_serde_roundtrip() {
        let e = RangeElement::transclusion(42, 10, 20);
        let json = serde_json::to_string(&e).unwrap();
        let e2: RangeElement = serde_json::from_str(&json).unwrap();
        assert_eq!(e, e2);
    }
}
