use std::collections::HashMap;
use std::sync::Arc;
use std::sync::Mutex;

use ed25519_dalek::{Signature, SigningKey, VerifyingKey};
use serde::{Deserialize, Serialize};

use super::session::SessionId;
use crate::crypto::sign::{sign_bytes, verify_signature};
use crate::edition::provenance::{sign_span, ElementProvenance, SpanProvenance};
use crate::edition::three_way::{three_way_merge, MergeStrategy};
use crate::edition::{BeId, Carrier, Edition, Mapping, RangeElement, XnRegion};
use crate::server::transport::protocol::TextDeltaOp;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct OtreeSyncSessionId(u64);

impl OtreeSyncSessionId {
    pub fn as_u64(self) -> u64 {
        self.0
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OtreeAwarenessState {
    pub session_id: u64,
    pub user_name: String,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub club_id: Option<BeId>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    pub author_public_key: Option<Vec<u8>>,
    pub cursor: Option<OtreeCursorPosition>,
    pub selection: Option<OtreeSelectionRange>,
    pub is_typing: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OtreeCursorPosition {
    pub index: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OtreeSelectionRange {
    pub start: usize,
    pub end: usize,
}

pub struct OtreeAwarenessUpdate {
    pub work_id: BeId,
    pub state: OtreeAwarenessState,
}

pub struct OtreeAwarenessRelayResult {
    pub relay_to: Vec<(SessionId, OtreeSyncSessionId)>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OtreeAuthorIdentity {
    pub public_key: [u8; 32],
    pub display_name: String,
    #[cfg_attr(feature = "serde", serde(default))]
    pub club_be_id: BeId,
}

impl OtreeAuthorIdentity {
    pub fn new(public_key: [u8; 32], display_name: String, club_be_id: BeId) -> Self {
        Self {
            public_key,
            display_name,
            club_be_id,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OtreeSignedUpdate {
    pub update_text: String,
    pub signature: Vec<u8>,
    pub signer_public_key: [u8; 32],
}

#[derive(Debug)]
pub enum OtreeSigningError {
    VerificationFailed(String),
    UnknownSigner([u8; 32]),
    InvalidSignatureBytes,
}

impl std::fmt::Display for OtreeSigningError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            OtreeSigningError::VerificationFailed(msg) => {
                write!(f, "signature verification failed: {}", msg)
            }
            OtreeSigningError::UnknownSigner(key) => {
                write!(f, "unknown signer: {:02x?}", &key[..8])
            }
            OtreeSigningError::InvalidSignatureBytes => {
                write!(f, "invalid signature bytes (expected 64)")
            }
        }
    }
}

/// A single annotation on a work.
///
/// Serialized to a JSON chunk via serde and persisted in the chunk store
/// (see `Server::restore_annotations` in server.rs and the annotations
/// checkpoint path). The chunk hash is recorded in the manifest's
/// `annotations_hash` field.
///
/// SCHEMA EVOLUTION RULES:
///
/// 1. Adding a new field: ALWAYS use `#[serde(default)]`. Old annotation
///    chunks on disk won't have the field; serde fills the default.
///    This is sufficient — no migration needed.
///
/// 2. Renaming/removing/restructuring a field (breaking change): you MUST
///    add a migration step in `persist/migrations.rs` that transforms the
///    annotation chunk JSON from the old format to the new format before
///    deserialization. Bump `CURRENT_MANIFEST_VERSION` and add a step in
///    `migrate_manifest_to_latest`. Without this, old annotation chunks
///    will fail to deserialize and the server will silently lose data.
///
/// 3. Safety: the restore path in server.rs (line ~5155) must NEVER
///    overwrite a chunk that failed to deserialize. If deserialization
///    fails, preserve the old chunk on disk so it can be migrated later.
///    A failed deserialization that leads to 0 in-memory annotations +
///    auto-checkpoint = permanent data loss.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OtreeAnnotation {
    pub annotation_id: u64,
    pub kind: String,
    pub payload: String,
    pub char_start: usize,
    pub char_end: usize,
    pub created_by: Option<BeId>,
    #[cfg_attr(feature = "serde", serde(default))]
    pub created_at: u64,
    #[cfg_attr(feature = "serde", serde(default))]
    pub is_private: bool,
}

struct OtreeWorkDoc {
    current_edition: Edition,
    base_edition: Edition,
    /// The session whose last apply produced current_edition with its
    /// own session_base set to the same value. While true, that
    /// session's base IS current by construction — the O(1) fast-path
    /// guard for solo typing (FR-50 fix B). Any other write to
    /// current_edition clears it.
    current_origin: Option<SessionId>,
    session_bases: HashMap<SessionId, Edition>,
    pending_edition: Option<Edition>,
    narration_snapshot: Option<String>,
    subscribers: HashMap<SessionId, OtreeSyncSessionId>,
    author_keys: HashMap<SessionId, OtreeAuthorIdentity>,
    /// Authors who have disconnected but whose text still exists in the edition.
    /// Kept so materialization can correctly attribute their edits.
    historical_authors: HashMap<SessionId, OtreeAuthorIdentity>,
    club_signing_keys: HashMap<BeId, SigningKey>,
    last_change_timestamp: u64,
    awareness: HashMap<SessionId, OtreeAwarenessState>,
    federated_provenance: Vec<SpanProvenance>,
    last_author_mapping: Option<Mapping>,
    cached_text: Mutex<Option<String>>,
    annotations: Vec<OtreeAnnotation>,
}

#[derive(Debug)]
pub enum OtreeError {
    WorkNotFound(BeId),
    NotSubscribed(BeId, SessionId),
    InvalidUpdate(String),
    AuthorNotRegistered(BeId, SessionId),
    SigningFailed(OtreeSigningError),
    MergeFailed(String),
}

impl std::fmt::Display for OtreeError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            OtreeError::WorkNotFound(id) => write!(f, "O-tree work not found: {:016x}", id),
            OtreeError::NotSubscribed(work, _sess) => {
                write!(f, "session not subscribed to work {:016x}", work)
            }
            OtreeError::InvalidUpdate(msg) => write!(f, "invalid update: {}", msg),
            OtreeError::AuthorNotRegistered(work, _sess) => {
                write!(f, "author not registered for work {:016x}", work)
            }
            OtreeError::SigningFailed(err) => write!(f, "signing error: {}", err),
            OtreeError::MergeFailed(msg) => write!(f, "merge failed: {}", msg),
        }
    }
}

pub struct OtreeSyncStartResult {
    pub session_id: OtreeSyncSessionId,
    pub current_text: String,
}

pub struct OtreeApplyResult {
    pub relay_to: Vec<(SessionId, OtreeSyncSessionId)>,
    pub was_merged: bool,
}

pub struct TextRangeResult {
    pub text: String,
    pub total_chars: usize,
    pub start_char: usize,
    pub end_char: usize,
}

pub struct OtreeCrdtManager {
    docs: HashMap<BeId, OtreeWorkDoc>,
    orphaned_annotations: HashMap<BeId, Vec<OtreeAnnotation>>,
    session_counter: u64,
    debounce_secs: u64,
    /// Persistent signing keys per (work, club) — survives doc eviction
    persistent_signing_keys: HashMap<(BeId, BeId), SigningKey>,
}

fn find_entry_for_char(entry_char_start: &[usize], char_pos: usize) -> usize {
    let idx = entry_char_start.partition_point(|&start| start <= char_pos);
    if idx == 0 {
        return 0;
    }
    idx - 1
}

fn char_index_to_byte(s: &str, char_idx: usize) -> Option<usize> {
    for (i, (byte_offset, _)) in s.char_indices().enumerate() {
        if i == char_idx {
            return Some(byte_offset);
        }
    }
    if char_idx == s.chars().count() {
        return Some(s.len());
    }
    None
}

fn split_text_carrier(carrier: &Carrier, start: usize, end: usize) -> Option<Carrier> {
    match &carrier.element {
        RangeElement::Text { text } => {
            let start_byte = char_index_to_byte(text, start)?;
            let end_byte = char_index_to_byte(text, end)?;
            if start_byte == end_byte {
                return None;
            }
            let slice = &text[start_byte..end_byte];
            let mut c = Carrier::new(RangeElement::text(slice.to_string()));
            if let Some(prov) = &carrier.provenance {
                c = c.with_provenance(prov.clone());
            }
            Some(c)
        }
        // FR-37 Phase 3 (delta-path materialization): splitting a
        // MATERIALIZED virtual's cached span converts the piece to
        // plain text. Editing inside a quotation is the explicit act
        // that breaks the live link — the spec cannot describe a
        // partial span, so the fragment keeps its bytes and drops the
        // virtual identity. Before this, partial splits returned None
        // and the walker silently DROPPED the piece (whole-quotation
        // content loss on a 1-char edit).
        RangeElement::Virtual {
            cached_content: Some(text),
            ..
        } => {
            let start_byte = char_index_to_byte(text, start)?;
            let end_byte = char_index_to_byte(text, end)?;
            if start_byte == end_byte {
                return None;
            }
            let slice = &text[start_byte..end_byte];
            let mut c = Carrier::new(RangeElement::text(slice.to_string()));
            if let Some(prov) = &carrier.provenance {
                c = c.with_provenance(prov.clone());
            }
            Some(c)
        }
        _ => {
            if start == 0 && end >= 1 {
                Some(carrier.clone())
            } else {
                None
            }
        }
    }
}

/// Output builder for delta application. Absorption (merging an
/// insert into the preceding entry) is allowed ONLY into entries
/// CREATED by the current op — never into copied base carriers.
/// FR-50 finding 6/11: absorbing into a copied carrier when their
/// full provenance (including the wall-clock timestamp) happened to
/// match made segmentation timing-dependent — the same script
/// produced different editions per process, and the changed
/// entry's fingerprint desynchronized the merge alignment into
/// content duplication. It also rewrote the original carrier's
/// provenance to the new op's timestamp (attribution skew).
/// Within-op absorption is deterministic (one provenance per apply
/// call) and preserved.
struct OutBuilder {
    entries: Vec<(i64, Arc<Carrier>)>,
    pos: i64,
    /// Entries from this index on were created by the current op.
    created_from: usize,
}

impl OutBuilder {
    fn new() -> Self {
        OutBuilder {
            entries: Vec::new(),
            pos: 0,
            created_from: 0,
        }
    }

    fn push_copied(&mut self, carrier: Carrier) {
        self.entries.push((self.pos, Arc::new(carrier)));
        self.pos += 1;
        self.created_from = self.entries.len();
    }

    fn push_created(&mut self, carrier: Carrier) {
        if self.entries.len() > self.created_from {
            if let Some(last) = self.entries.last_mut() {
                if last.1.provenance == carrier.provenance && last.1.label == carrier.label {
                    if let (
                        RangeElement::Text { text: last_text },
                        RangeElement::Text { text: new_text },
                    ) = (&last.1.element, &carrier.element)
                    {
                        let combined = format!("{}{}", last_text, new_text);
                        let mut merged = Carrier::new(RangeElement::text(combined));
                        merged.label = carrier.label.clone();
                        merged.provenance = carrier.provenance.clone();
                        last.1 = Arc::new(merged);
                        return;
                    }
                }
            }
        }
        self.entries.push((self.pos, Arc::new(carrier)));
        self.pos += 1;
    }
}

fn flush_batched_insert_coalesced(
    pending: &mut String,
    prov: &Option<ElementProvenance>,
    out: &mut OutBuilder,
) {
    if pending.is_empty() {
        return;
    }
    let text = std::mem::take(pending);
    let mut start = 0usize;
    for (i, ch) in text.char_indices() {
        if ch == '\n' {
            let line = &text[start..i + ch.len_utf8()];
            let carrier = Carrier::new(RangeElement::text(line.to_string()));
            let carrier = match prov {
                Some(p) => carrier.with_provenance(p.clone()),
                None => carrier,
            };
            out.push_created(carrier);
            start = i + ch.len_utf8();
        }
    }
    if start < text.len() {
        let remaining = &text[start..];
        let carrier = Carrier::new(RangeElement::text(remaining.to_string()));
        let carrier = match prov {
            Some(p) => carrier.with_provenance(p.clone()),
            None => carrier,
        };
        out.push_created(carrier);
    }
}

pub fn apply_text_delta_to_edition(
    edition: &Edition,
    ops: &[TextDeltaOp],
    author: Option<&OtreeAuthorIdentity>,
) -> Edition {
    let started = std::time::Instant::now();
    let timestamp = current_timestamp_secs();
    let prov = author.map(|a| ElementProvenance {
        author_public_key: a.public_key,
        author_display_name: a.display_name.clone(),
        author_club_id: a.club_be_id,
        timestamp,
        author_type: crate::edition::provenance::AuthorType::Human,
        llm_model: None,
        historical_author_id: None,
        source_work_id: None,
        transcluded_by: None,
        derived_by: None,
    });

    if let Some(result) = try_apply_delta_fast(edition, ops, &prov) {
        tracing::debug!(
            "[apply_delta] fast path: old_entries={} ops={} elapsed_ms={:.3}",
            edition.cached_entries().len(),
            ops.len(),
            started.elapsed().as_secs_f64() * 1000.0,
        );
        return result;
    }
    apply_text_delta_to_edition_bulk(edition, ops, &prov, started)
}

/// Shared op walker: processes `ops` against `entries` starting at
/// absolute char position `start_char` (which must equal
/// `starts[0] + within`, the position the first op applies at), running
/// the exact retain-copy/delete-skip/insert-batch semantics of the
/// historical bulk walk. Emits output carriers with DENSE LOCAL
/// positions (0..k) so `push_coalesced` behaves identically; callers
/// reassign real positions afterwards.
///
/// Returns (entries consumed, absolute char position reached, final
/// dense local output position). When ops are exhausted mid-entry, the
/// entry's remainder is emitted (mirrors the historical trailing-split
/// logic).
#[allow(clippy::too_many_arguments)]
fn walk_clamped(
    entries: &[(i64, Arc<Carrier>)],
    starts: &[usize],
    ops: &[TextDeltaOp],
    start_char: usize,
    prov: &Option<ElementProvenance>,
    out: &mut OutBuilder,
) -> (usize, usize, i64) {
    let mut old_char_pos = start_char;
    let mut current_entry_idx = 0usize;
    let mut pending_insert = String::new();

    for op in ops {
        match op {
            TextDeltaOp::Retain { count } => {
                flush_batched_insert_coalesced(&mut pending_insert, prov, out);
                let target_char_pos = old_char_pos + *count as usize;

                while old_char_pos < target_char_pos {
                    if current_entry_idx >= entries.len() {
                        break;
                    }
                    let entry = &entries[current_entry_idx];
                    let entry_start = starts[current_entry_idx];
                    let entry_len = entry.1.char_len();

                    if entry_len == 0 {
                        out.push_copied((*entry.1).clone());
                        current_entry_idx += 1;
                        continue;
                    }

                    let within = old_char_pos.saturating_sub(entry_start);
                    let available = entry_len.saturating_sub(within);
                    let remaining = target_char_pos.saturating_sub(old_char_pos);
                    let take = remaining.min(available);

                    if within == 0 && take == entry_len {
                        out.push_copied((*entry.1).clone());
                    } else if let Some(carrier) =
                        split_text_carrier(&entry.1, within, within + take)
                    {
                        out.push_copied(carrier);
                    }

                    old_char_pos += take;
                    if within + take == entry_len {
                        current_entry_idx += 1;
                    }
                }
            }
            TextDeltaOp::Delete { count } => {
                flush_batched_insert_coalesced(&mut pending_insert, prov, out);
                let target_char_pos = old_char_pos + *count as usize;
                while old_char_pos < target_char_pos {
                    if current_entry_idx >= entries.len() {
                        break;
                    }
                    let entry_len = entries[current_entry_idx].1.char_len();
                    if entry_len == 0 {
                        current_entry_idx += 1;
                        continue;
                    }
                    let entry_start = starts[current_entry_idx];
                    let within = old_char_pos.saturating_sub(entry_start);
                    let available = entry_len.saturating_sub(within);
                    let remaining = target_char_pos.saturating_sub(old_char_pos);
                    let take = remaining.min(available);
                    old_char_pos += take;
                    if within + take == entry_len {
                        current_entry_idx += 1;
                    }
                }
            }
            TextDeltaOp::Insert { text } => {
                pending_insert.push_str(text);
            }
        }
    }

    flush_batched_insert_coalesced(&mut pending_insert, prov, out);

    // Ops exhausted mid-entry: emit the remainder of the partially
    // consumed entry (historical trailing-split behavior).
    if current_entry_idx < entries.len() {
        let entry_start = starts[current_entry_idx];
        let within = old_char_pos.saturating_sub(entry_start);
        if within > 0 {
            if let Some(carrier) = split_text_carrier(
                &entries[current_entry_idx].1,
                within,
                entries[current_entry_idx].1.char_len(),
            ) {
                out.push_copied(carrier);
            }
            current_entry_idx += 1;
        }
    }

    (current_entry_idx, old_char_pos, out.pos)
}

/// The historical flatten-walk-rebuild path. Still the fallback for
/// large deltas, infinite-domain editions, and allocation failures.
fn apply_text_delta_to_edition_bulk(
    edition: &Edition,
    ops: &[TextDeltaOp],
    prov: &Option<ElementProvenance>,
    started: std::time::Instant,
) -> Edition {
    let old_entries = edition.cached_entries().clone();
    let starts = edition.cached_char_starts().to_vec();

    let mut out = OutBuilder::new();

    let (consumed, _, _) = walk_clamped(&old_entries, &starts, ops, 0, prov, &mut out);

    // Suffix: remaining entries copied verbatim, continuing the dense
    // numbering. Copied carriers never absorb (FR-50 F6/F11).
    for entry in &old_entries[consumed.min(old_entries.len())..] {
        out.push_copied((*entry.1).clone());
    }

    let result = {
        let ed = Edition::from_entries(out.entries);
        tracing::debug!(
            "[apply_delta] bulk path: old_entries={} result_entries={} ops={} elapsed_ms={:.3}",
            old_entries.len(),
            ed.all_entries().len(),
            ops.len(),
            started.elapsed().as_secs_f64() * 1000.0,
        );
        for (i, (p, c)) in ed.all_entries().iter().take(8).enumerate() {
            let txt_len = c.element.as_text().map(|t| t.len()).unwrap_or(0);
            tracing::debug!(
                "[apply_delta]   [{}] pos={} len={} prov={}",
                i,
                p,
                txt_len,
                c.provenance.is_some()
            );
        }
        ed
    };
    result
}

/// Post-edit splay toggle (PERF-PLAN S3). MEASURED NOT-JUSTIFIED:
/// after fixing the splay content-loss bug the terminal arms dropped
/// children), hot-window post-edit splay showed no improvement
/// (6.7ms vs 9.1ms per edit @100k — within noise), because fast-path
/// assembly already localizes the neighborhood. Splay remains
/// available via `Edition::splayed()` and is covered by content-
/// preservation regression tests. The S3 measurement also caught the
/// dormant splay bug above — the stage's real deliverable.
const SPLAY_AFTER_FAST_EDIT: bool = false;

/// Tree-native delta application (PERF-PLAN Stage 5 / FR-34 Phase I).
///
/// Walks only the touched entry neighborhood, assigns gap-allocated
/// stable positions (Stage 4 allocator) to the replacement entries,
/// and assembles the result structurally: untouched prefix/suffix are
/// shared via `copy()`, the neighborhood is bulk-built, and the pieces
/// combine in O(log n). Untouched entries keep their positions.
///
/// Guards fall back to the bulk path: infinite-domain editions,
/// large deltas (> 20% of entries or > 64), pathological inserts,
/// or position allocation failure (crammed i64 space).
fn try_apply_delta_fast(
    edition: &Edition,
    ops: &[TextDeltaOp],
    prov: &Option<ElementProvenance>,
) -> Option<Edition> {
    if edition.is_infinite() || ops.is_empty() {
        return None;
    }

    let entries = edition.cached_entries();
    let starts = edition.cached_char_starts();
    let n = entries.len();
    if n == 0 {
        // Empty edition: nothing structural to share; bulk is fine.
        return None;
    }

    // Locate the dirty char span in OLD coordinates.
    let mut pos = 0usize;
    let mut lo = None;
    let mut hi = 0usize;
    for op in ops {
        match op {
            TextDeltaOp::Retain { count } => {
                pos += *count as usize;
            }
            TextDeltaOp::Delete { count } => {
                if lo.is_none() {
                    lo = Some(pos);
                }
                pos += *count as usize;
                hi = hi.max(pos);
            }
            TextDeltaOp::Insert { text } => {
                let len = text.chars().count();
                if len > 0 {
                    if lo.is_none() {
                        lo = Some(pos);
                    }
                    hi = hi.max(pos + len);
                }
            }
        }
    }
    let Some(lo) = lo else {
        // Pure retain (or empty inserts): no change at all.
        return Some(edition.clone());
    };
    let hi = hi.max(lo + 1);

    // Entry range [i0, i1): every entry the walk could touch.
    // Starts are gapless cumulative sums, so:
    // - the run of entries starting exactly at lo joins the neighborhood
    //   (zero-char entries are dropped by deletes, copied by retains)
    // - otherwise the entry containing lo is at partition-1
    // - partition == n means lo is past the end (append case)
    let partition = starts.partition_point(|&s| s <= lo).min(n);
    let mut i0 = partition;
    while i0 > 0 && starts[i0 - 1] == lo {
        i0 -= 1;
    }
    let total = starts[n - 1] + entries[n - 1].1.char_len();
    if i0 == partition && partition > 0 && lo < total {
        i0 -= 1;
    }
    // i1: first entry starting at/after hi.
    let mut i1 = starts.partition_point(|&s| s < hi).min(n);
    if i1 < i0 {
        i1 = i0;
    }

    let touched = i1.saturating_sub(i0);
    if touched > 64 && touched * 5 > n {
        return None;
    }

    // Clamp ops to the neighborhood [starts[i0], walk_end) where
    // walk_end covers the whole last touched entry (its tail is
    // re-emitted by the walk). The lead retain emits the untouched
    // head of the first entry. walk_end extends to hi so trailing
    // inserts at the document end stay in the neighborhood.
    let (walk_start, mut walk_end) = if i0 < n {
        (
            starts[i0],
            starts[i1.saturating_sub(1).max(i0)]
                + entries[i1.saturating_sub(1).max(i0)].1.char_len(),
        )
    } else {
        (lo, lo)
    };
    walk_end = walk_end.max(hi);
    let lead_within = lo - walk_start;
    let span = walk_end.saturating_sub(walk_start);
    let mut clamped: Vec<TextDeltaOp> = Vec::with_capacity(ops.len() + 2);
    if lead_within > 0 {
        clamped.push(TextDeltaOp::Retain {
            count: lead_within as u64,
        });
    }
    let mut p = 0usize;
    let mut covered = 0usize;
    for op in ops {
        if covered >= span {
            break;
        }
        match op {
            TextDeltaOp::Retain { count } => {
                let c = *count as usize;
                if p + c <= lo {
                    p += c;
                    continue;
                }
                let seg_start = p.max(lo);
                let seg_end = (p + c).min(walk_end);
                let take = seg_end.saturating_sub(seg_start);
                if take > 0 {
                    clamped.push(TextDeltaOp::Retain { count: take as u64 });
                    covered += take;
                }
                p += c;
            }
            TextDeltaOp::Delete { count } => {
                let c = *count as usize;
                let seg_start = p.max(lo);
                let seg_end = (p + c).min(walk_end);
                let take = seg_end.saturating_sub(seg_start);
                if take > 0 {
                    clamped.push(TextDeltaOp::Delete { count: take as u64 });
                    covered += take;
                }
                p += c;
            }
            TextDeltaOp::Insert { text } => {
                if p >= lo && p < walk_end {
                    clamped.push(TextDeltaOp::Insert { text: text.clone() });
                }
            }
        }
    }
    // Tail retain through walk_end so the walk ends exactly at the
    // neighborhood boundary.
    let covered_total = lead_within + covered;
    if covered_total < span {
        let tail = span - covered_total;
        clamped.push(TextDeltaOp::Retain { count: tail as u64 });
    }

    // Walk the neighborhood only, starting at its first entry.
    let hood_entries = &entries[i0.min(n)..i1.max(i0).min(n)];
    let hood_starts = &starts[i0.min(n)..i1.max(i0).min(n)];
    let mut hood = OutBuilder::new();
    walk_clamped(
        hood_entries,
        hood_starts,
        &clamped,
        walk_start,
        prov,
        &mut hood,
    );
    if hood.entries.len() > touched + ops.len() * 4 + 64 {
        return None;
    }

    assemble_fast_result(edition, i0.min(n), i1.min(n), hood.entries)
}

/// Assign stable positions to the replacement neighborhood and assemble
/// the result structurally (shared prefix/suffix via copy, neighborhood
/// bulk-built, combined in O(log n)).
///
/// Gap strategy (Stage 4 allocator semantics):
/// - room in the surrounding gap: even spread
/// - append/prepend at document ends: DEFAULT_SPACING outward
/// - gap exhausted (dense layouts): re-space a window of RESPACE_WINDOW
///   untouched neighbors on each side — the only case where unrelated
///   entries move (amortized O(1) relabels, list-labeling tradeoff)
fn assemble_fast_result(
    edition: &Edition,
    i0: usize,
    i1: usize,
    hood: Vec<(i64, Arc<Carrier>)>,
) -> Option<Edition> {
    use crate::space::position_allocator::DEFAULT_SPACING;

    const RESPACE_WINDOW: usize = 16;

    let entries = edition.cached_entries();
    let starts = edition.cached_char_starts();
    let fps = edition.cached_fingerprints();
    let hood_has_t: bool = hood.iter().any(|(_, c)| c.element.is_transclusion());
    let n = entries.len();
    let m = hood.len();
    let prev = if i0 > 0 {
        Some(entries[i0 - 1].0)
    } else {
        None
    };
    let next = if i1 < n { Some(entries[i1].0) } else { None };

    if m == 0 {
        // Pure deletion of the whole neighborhood: keep prefix/suffix.
        let orgl = match (prev, next) {
            (Some(p), Some(q)) => edition
                .orgl
                .copy(&XnRegion::below(p + 1))
                .combine(&edition.orgl.copy(&XnRegion::above(q)))
                .ok()?,
            (Some(p), None) => edition.orgl.copy(&XnRegion::below(p + 1)),
            (None, Some(q)) => edition.orgl.copy(&XnRegion::above(q)),
            (None, None) => crate::edition::orgl::OrglRoot::empty(),
        };
        let mut new_entries: Vec<(i64, Arc<Carrier>)> = Vec::with_capacity(n);
        let mut new_starts: Vec<usize> = Vec::with_capacity(n);
        let mut new_fps: Vec<[u8; 32]> = Vec::with_capacity(n);
        for k in 0..i0 {
            new_entries.push(entries[k].clone());
            new_starts.push(starts[k]);
            new_fps.push(fps[k]);
        }
        let cursor = if i0 < n { starts[i0] } else { 0 };
        if i1 < n {
            let shift = cursor as i64 - starts[i1] as i64;
            for k in i1..n {
                new_entries.push(entries[k].clone());
                new_starts.push((starts[k] as i64 + shift) as usize);
                new_fps.push(fps[k]);
            }
        }
        let has_t = edition.cached_has_transclusions() || hood_has_t;
        return Some(Edition::from_parts_with_cache(
            orgl,
            edition.endorsements.clone(),
            Arc::new(std::sync::OnceLock::from((
                new_entries,
                new_starts,
                new_fps,
                has_t,
            ))),
            edition.span_provenance.clone(),
        ));
    }

    let mut positioned = hood;
    let mut w_start = i0;
    let mut w_end = i1;
    let mut rebased = false;

    match (prev, next) {
        (Some(p), Some(q)) if q - p > m as i64 => {
            let gap = q - p;
            let step = gap / (m as i64 + 1);
            for (j, e) in positioned.iter_mut().enumerate() {
                e.0 = p + (j as i64 + 1) * step;
            }
        }
        (Some(p), None) => {
            let end = p.checked_add(DEFAULT_SPACING * m as i64)?;
            let step = if m > 0 { (end - p) / m as i64 } else { 1 };
            for (j, e) in positioned.iter_mut().enumerate() {
                e.0 = p + (j as i64 + 1) * step;
            }
        }
        (None, Some(q)) => {
            let base = q.checked_sub(DEFAULT_SPACING * m as i64)?;
            for (j, e) in positioned.iter_mut().enumerate() {
                e.0 = base + j as i64 * DEFAULT_SPACING;
            }
        }
        (None, None) => {
            for (j, e) in positioned.iter_mut().enumerate() {
                e.0 = j as i64;
            }
        }
        (Some(_), Some(_)) => {
            // Gap exhausted: try re-spacing a window of untouched
            // neighbors; if even that cannot fit spacing >= 4 (fully
            // dense layout), do a one-time whole-edition rebase to a
            // spaced layout — O(n) once, after which every subsequent
            // edit finds midpoint gaps (the layout "heals").
            w_start = i0.saturating_sub(RESPACE_WINDOW);
            w_end = (i1 + RESPACE_WINDOW).min(n);
            let anchor = entries[w_start].0;
            let ceiling = if w_end < n {
                entries[w_end].0
            } else if let Some(p) = prev {
                p.checked_add(i64::MAX / 8)?
            } else {
                i64::MAX / 4
            };
            let count = (w_end - w_start) as i64 + m as i64;
            let span = ceiling.saturating_sub(anchor);
            let spacing = if span > count {
                (span / (count + 1)).max(1)
            } else {
                0
            };
            if spacing >= 4 {
                // Window re-space: relabel window-before, neighborhood,
                // window-after at uniform spacing from the anchor.
                let mut all: Vec<(i64, Arc<Carrier>)> = Vec::with_capacity(count as usize);
                let mut cursor = anchor;
                for entry in &entries[w_start..i0] {
                    cursor += spacing;
                    all.push((cursor, entry.1.clone()));
                }
                for e in positioned.drain(..) {
                    cursor += spacing;
                    all.push((cursor, e.1));
                }
                for entry in &entries[i1..w_end] {
                    cursor += spacing;
                    all.push((cursor, entry.1.clone()));
                }
                positioned = all;
            } else {
                // Whole-edition rebase.
                let mut all: Vec<(i64, Arc<Carrier>)> = Vec::with_capacity(n + m);
                for entry in &entries[..i0] {
                    all.push((0, entry.1.clone()));
                }
                for e in positioned.drain(..) {
                    all.push((0, e.1));
                }
                for entry in &entries[i1..] {
                    all.push((0, entry.1.clone()));
                }
                for (k, e) in all.iter_mut().enumerate() {
                    e.0 = k as i64 * DEFAULT_SPACING;
                }
                positioned = all;
                rebased = true;
                // Full replacement: no prefix/suffix sharing.
            }
        }
    }

    let mid = Edition::from_entries_at_positions(positioned).ok()?;

    let first_pos = mid.cached_entries().first()?.0;
    let last_pos = mid.cached_entries().last()?.0;
    let mut combined = mid.orgl.clone();
    let mut carried_cache: Option<(Vec<(i64, Arc<Carrier>)>, Vec<usize>, Vec<[u8; 32]>, bool)> =
        None;

    if !rebased {
        if w_start < i0 && w_start < n {
            // Prefix: everything before the re-spaced window.
            let bound = entries[w_start].0;
            combined = edition
                .orgl
                .copy(&XnRegion::below(bound))
                .combine(&combined)
                .ok()?;
        } else if i0 > 0 {
            let bound = if i0 < n {
                first_pos.min(entries[i0].0)
            } else {
                first_pos
            };
            combined = edition
                .orgl
                .copy(&XnRegion::below(bound))
                .combine(&combined)
                .ok()?;
        }
        if w_end > i1 && w_end < n {
            let bound = entries[w_end].0;
            combined = combined
                .combine(&edition.orgl.copy(&XnRegion::above(bound)))
                .ok()?;
        } else if i1 < n {
            let bound = if i1 > i0 {
                last_pos.max(entries[i1 - 1].0) + 1
            } else {
                last_pos + 1
            };
            combined = combined
                .combine(&edition.orgl.copy(&XnRegion::above(bound)))
                .ok()?;
        }

        // Carry the flat entries cache across the edit: splice the old
        // prefix/suffix around the new neighborhood instead of
        // re-flattening the tree (O(n) pointer memcpy vs O(n) walk).
        // Suffix char starts shift by the neighborhood's net char delta.
        let mid_entries = mid.cached_entries().clone();
        let mid_fps = mid.cached_fingerprints();
        let mut new_entries: Vec<(i64, Arc<Carrier>)> = Vec::with_capacity(n + mid_entries.len());
        let mut new_starts: Vec<usize> = Vec::with_capacity(n + mid_entries.len());
        let mut new_fps: Vec<[u8; 32]> = Vec::with_capacity(n + mid_entries.len());

        let prefix_end = if w_start < i0 { w_start } else { i0 };
        for k in 0..prefix_end {
            new_entries.push(entries[k].clone());
            new_starts.push(starts[k]);
            new_fps.push(fps[k]);
        }
        // Append-at-end edits (prefix_end == n): the cursor is the
        // TOTAL length, not 0 — starts[n] is out of bounds and the
        // old else-branch gave appended entries start 0 (FR-50 A3b,
        // exposed by the O(1) char_len tail read + matrix test).
        let mut cursor = if prefix_end < n {
            starts[prefix_end]
        } else if n > 0 {
            starts[n - 1] + entries[n - 1].1.char_len()
        } else {
            0
        };
        for (k, (pos, carrier)) in mid_entries.iter().enumerate() {
            new_entries.push((*pos, carrier.clone()));
            new_starts.push(cursor);
            new_fps.push(mid_fps[k]);
            cursor += carrier.char_len();
        }
        let suffix_start_idx = if w_end > i1 { w_end } else { i1 };
        if suffix_start_idx < n {
            let shift = cursor as i64 - starts[suffix_start_idx] as i64;
            for k in suffix_start_idx..n {
                new_entries.push(entries[k].clone());
                new_starts.push((starts[k] as i64 + shift) as usize);
                new_fps.push(fps[k]);
            }
        }
        let has_t = edition.cached_has_transclusions() || hood_has_t;
        carried_cache = Some((new_entries, new_starts, new_fps, has_t));
    }

    let entries_cache = match carried_cache {
        Some((e, s, f, t)) => Arc::new(std::sync::OnceLock::from((e, s, f, t))),
        None => Arc::new(std::sync::OnceLock::new()),
    };

    let mut result_edition = Edition::from_parts_with_cache(
        combined,
        edition.endorsements.clone(),
        entries_cache,
        edition.span_provenance.clone(),
    );

    if SPLAY_AFTER_FAST_EDIT {
        // Splay the hot region around the edit point (PERF-PLAN S3).
        // Repeated combines at nearby boundaries fragment the tree;
        // splaying the small window where the next edit likely lands
        // re-consolidates it into its own shallow subtree. Measured:
        // 200 same-region edits @100k entries, 1.47s -> ~65ms. The
        // carried entries cache survives splay (positions and content
        // are unchanged; only tree shape moves). Splaying the whole
        // neighborhood is a no-op (FullyContained prunes); the window
        // must straddle the edit point to trigger restructuring.
        let hood_pos = result_edition.cached_entries();
        let lo = first_pos;
        let hi = hood_pos
            .iter()
            .find(|(p, _)| *p > lo)
            .map(|(p, _)| *p + 1)
            .unwrap_or(last_pos + 1);
        let _ = result_edition.orgl.splay(&XnRegion::interval(lo, hi));
    }

    Some(result_edition)
}

fn append_text_with_llm_provenance(
    edition: &Edition,
    text: &str,
    llm_model: &str,
    triggerer_club_id: BeId,
    server_pub_key: [u8; 32],
    attestation_json: Option<&str>,
) -> Edition {
    let mut entries = edition.all_entries().to_vec();
    let mut pos = entries.last().map(|(p, _)| *p + 1).unwrap_or(0);

    let model_label = if let Some(json) = attestation_json {
        format!("{} {}", llm_model, json)
    } else {
        llm_model.to_string()
    };

    let llm_prov = ElementProvenance {
        author_public_key: server_pub_key,
        author_display_name: llm_model.to_string(),
        author_club_id: triggerer_club_id,
        timestamp: current_timestamp_secs(),
        author_type: crate::edition::provenance::AuthorType::Llm,
        llm_model: Some(model_label),
        historical_author_id: None,
        source_work_id: None,
        transcluded_by: None,
        derived_by: None,
    };

    let mut start = 0usize;
    for (i, ch) in text.char_indices() {
        if ch == '\n' {
            let line = &text[start..i + ch.len_utf8()];
            let carrier = Carrier::new(RangeElement::text(line.to_string()))
                .with_provenance(llm_prov.clone());
            entries.push((pos, Arc::new(carrier)));
            pos += 1;
            start = i + ch.len_utf8();
        }
    }
    if start < text.len() {
        let remaining = &text[start..];
        let carrier = Carrier::new(RangeElement::text(remaining.to_string()))
            .with_provenance(llm_prov.clone());
        entries.push((pos, Arc::new(carrier)));
    }

    Edition::from_entries(entries).coalesce()
}

fn current_timestamp_secs() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

impl OtreeCrdtManager {
    pub fn new(debounce_secs: u64) -> Self {
        OtreeCrdtManager {
            docs: HashMap::new(),
            orphaned_annotations: HashMap::new(),
            session_counter: 0,
            debounce_secs,
            persistent_signing_keys: HashMap::new(),
        }
    }

    fn next_session_id(&mut self) -> OtreeSyncSessionId {
        self.session_counter += 1;
        OtreeSyncSessionId(self.session_counter)
    }

    pub fn open_sync_session(
        &mut self,
        work_id: BeId,
        session_id: SessionId,
        initial_edition: Option<&Edition>,
    ) -> OtreeSyncStartResult {
        let sync_id = self.next_session_id();

        if !self.docs.contains_key(&work_id) {
            let edition = initial_edition
                .cloned()
                .unwrap_or_else(|| Edition::from_text_batched(""));
            self.docs.insert(
                work_id,
                OtreeWorkDoc {
                    base_edition: edition.clone(),
                    current_edition: edition,
                    session_bases: HashMap::new(),
                    current_origin: None,
                    pending_edition: None,
                    narration_snapshot: None,
                    subscribers: HashMap::new(),
                    author_keys: HashMap::new(),
                    historical_authors: HashMap::new(),
                    club_signing_keys: HashMap::new(),
                    last_change_timestamp: 0,
                    awareness: HashMap::new(),
                    federated_provenance: Vec::new(),
                    last_author_mapping: None,
                    cached_text: Mutex::new(None),
                    annotations: Vec::new(),
                },
            );
        }

        let wd = self
            .docs
            .get_mut(&work_id)
            .expect("work doc must exist after insert");
        wd.subscribers.insert(session_id, sync_id);
        wd.session_bases
            .insert(session_id, wd.current_edition.clone());

        let current_text = {
            let cache = wd.cached_text.lock().unwrap_or_else(|e| e.into_inner());
            if cache.is_some() {
                cache.as_ref().unwrap().clone()
            } else {
                drop(cache);
                let text = wd.current_edition.to_text();
                *wd.cached_text.lock().unwrap_or_else(|e| e.into_inner()) = Some(text.clone());
                text
            }
        };

        OtreeSyncStartResult {
            session_id: sync_id,
            current_text,
        }
    }

    pub fn close_sync_session(
        &mut self,
        work_id: BeId,
        session_id: SessionId,
    ) -> Result<(), OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        wd.subscribers.remove(&session_id);
        // Preserve author identity for attribution even after disconnect
        if let Some(author) = wd.author_keys.remove(&session_id) {
            wd.historical_authors.insert(session_id, author);
        }
        wd.awareness.remove(&session_id);
        wd.session_bases.remove(&session_id);
        if wd.subscribers.is_empty() {
            // Materialize pending changes before evicting
            if wd.pending_edition.is_some() {
                wd.base_edition = wd.current_edition.clone();
                wd.pending_edition = None;
            }
            if !wd.annotations.is_empty() {
                self.orphaned_annotations
                    .insert(work_id, std::mem::take(&mut wd.annotations));
            }
            self.docs.remove(&work_id);
        }
        Ok(())
    }

    pub fn apply_text_delta(
        &mut self,
        work_id: BeId,
        sender_session: SessionId,
        ops: &[TextDeltaOp],
    ) -> Result<OtreeApplyResult, OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        if !wd.subscribers.contains_key(&sender_session) {
            return Err(OtreeError::NotSubscribed(work_id, sender_session));
        }

        let author = wd.author_keys.get(&sender_session).cloned();
        let session_base = wd
            .session_bases
            .get(&sender_session)
            .cloned()
            .unwrap_or_else(|| wd.base_edition.clone());
        let author_edition = apply_text_delta_to_edition(&session_base, ops, author.as_ref());

        let base = &session_base;
        let current = &wd.current_edition;

        let base_is_current =
            wd.current_origin == Some(sender_session) || base.same_content(current);
        let (merged, was_merged) = if base_is_current {
            // Content equality (position-tolerant): editions produced by
            // the bulk (dense) and tree-native (stable-position) delta
            // paths compare equal when content and segmentation match.
            // The delta mapping is arithmetic here — the ops state it
            // exactly — so skip the O(N) fingerprint build (FR-50 fix A).
            if !session_base.span_provenance.is_empty() {
                let delta_mapping = crate::edition::three_way::positional_delta_mapping(
                    base.orgl.count() as i64,
                    ops,
                );
                let migrated_sp = crate::edition::three_way::migrate_span_provenance_single(
                    &session_base.span_provenance,
                    &delta_mapping,
                );
                (author_edition.with_span_provenance(migrated_sp), false)
            } else {
                (author_edition, false)
            }
        } else {
            match three_way_merge(
                base,
                current,
                &author_edition,
                MergeStrategy::LastWriterWins,
            ) {
                Ok(result) => (result.merged, true),
                Err(_) => (author_edition, true),
            }
        };

        // In the fast path the mapping current→merged is exactly the
        // positional delta mapping (current content == base); composing
        // it costs O(ops) instead of another whole-document build.
        let fast_mapping = if was_merged {
            None
        } else {
            Some(crate::edition::three_way::positional_delta_mapping(
                base.orgl.count() as i64,
                ops,
            ))
        };
        wd.last_author_mapping = Some(match fast_mapping {
            Some(m) => m,
            None => crate::edition::three_way::build_merge_mapping(&wd.current_edition, &merged),
        });

        let mapping = wd.last_author_mapping.as_ref().unwrap();
        for ann in &mut wd.annotations {
            let old_region = XnRegion::interval(ann.char_start as i64, ann.char_end as i64);
            let new_region = mapping.of_region(&old_region);
            if new_region.is_empty() {
                ann.char_start = ann.char_end;
            } else {
                // The exact mapping can split a span's image at
                // interior edits (inserts inside the annotation grow
                // it; deletes punch holes). Taking only the first
                // fragment dropped the rest — annotations must cover
                // the full hull of surviving content (FR-50 A1,
                // caught by armor).
                let intervals = new_region.intervals();
                let start = intervals.first().map(|&(s, _)| s).unwrap_or(0);
                let end = intervals.last().map(|&(_, e)| e).unwrap_or(0);
                ann.char_start = start.max(0) as usize;
                ann.char_end = end.max(0) as usize;
            }
        }

        let expected_len = if was_merged {
            0
        } else {
            let insert_len: usize = ops
                .iter()
                .map(|op| match op {
                    TextDeltaOp::Insert { text } => text.chars().count(),
                    _ => 0,
                })
                .sum();
            let delete_sum: u64 = ops
                .iter()
                .map(|op| match op {
                    TextDeltaOp::Delete { count } => *count,
                    _ => 0,
                })
                .sum();
            let old_len = wd.current_edition.char_len() as u64;
            (old_len + insert_len as u64).saturating_sub(delete_sum) as usize
        };

        wd.current_edition = merged.clone();
        wd.current_origin = Some(sender_session);
        wd.session_bases.insert(sender_session, merged);
        if !was_merged && expected_len > 0 {
            let actual_len = wd.current_edition.char_len();
            if actual_len > expected_len * 2
                || (expected_len > 100 && actual_len > expected_len + expected_len / 2)
            {
                tracing::error!(
                    "[crdt] possible duplication: expected ~{} chars, got {}",
                    expected_len,
                    actual_len
                );
            }
        }
        *wd.cached_text.lock().unwrap_or_else(|e| e.into_inner()) = None;
        wd.last_change_timestamp = current_timestamp_secs();
        wd.pending_edition = Some(wd.current_edition.clone());

        let relay_to: Vec<(SessionId, OtreeSyncSessionId)> = wd
            .subscribers
            .iter()
            .filter(|(sid, _)| **sid != sender_session)
            .map(|(sid, sync_id)| (*sid, *sync_id))
            .collect();

        Ok(OtreeApplyResult {
            relay_to,
            was_merged,
        })
    }

    pub fn current_text(&self, work_id: BeId) -> Result<String, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        {
            let cache = wd.cached_text.lock().unwrap_or_else(|e| e.into_inner());
            if cache.is_some() {
                return Ok(cache.as_ref().unwrap().clone());
            }
        }
        let text = wd.current_edition.to_text();
        *wd.cached_text.lock().unwrap_or_else(|e| e.into_inner()) = Some(text.clone());
        Ok(text)
    }

    /// Debug: a session's current base edition (F6 bracket).
    pub fn debug_session_base(&self, work_id: BeId, session_id: SessionId) -> Option<Edition> {
        self.docs
            .get(&work_id)
            .and_then(|wd| wd.session_bases.get(&session_id).cloned())
    }

    /// Debug: a session's registered author identity (F6 bracket).
    pub fn debug_author_key(
        &self,
        work_id: BeId,
        session_id: SessionId,
    ) -> Option<OtreeAuthorIdentity> {
        self.docs
            .get(&work_id)
            .and_then(|wd| wd.author_keys.get(&session_id).cloned())
    }

    pub fn current_edition(&self, work_id: BeId) -> Result<Edition, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd.current_edition.clone())
    }

    pub fn text_range(
        &self,
        work_id: BeId,
        start_char: usize,
        end_char: usize,
    ) -> Result<TextRangeResult, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        let total_chars = wd.current_edition.char_len();
        let clamped_end = end_char.min(total_chars);
        let clamped_start = start_char.min(clamped_end);
        let text = wd.current_edition.to_text_range(clamped_start, clamped_end);
        Ok(TextRangeResult {
            text,
            total_chars,
            start_char: clamped_start,
            end_char: clamped_end,
        })
    }

    pub fn materialize_edition(&mut self, work_id: BeId) -> Result<Edition, OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        wd.base_edition = wd.current_edition.clone();
        wd.pending_edition = None;
        Ok(wd.current_edition.clone())
    }

    pub fn base_edition(&self, work_id: BeId) -> Result<Edition, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd.base_edition.clone())
    }

    pub fn narration_snapshot(&self, work_id: BeId) -> Result<Option<String>, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd.narration_snapshot.clone())
    }

    pub fn set_narration_snapshot(&mut self, work_id: BeId) -> Result<String, OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        let current = wd.current_edition.to_text();
        wd.narration_snapshot = Some(current.clone());
        Ok(current)
    }

    pub fn append_llm_text(
        &mut self,
        work_id: BeId,
        text: &str,
        llm_model: &str,
        triggerer_club_id: BeId,
        server_pub_key: [u8; 32],
        attestation_json: Option<&str>,
    ) -> Result<(), OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        wd.current_origin = None;
        wd.current_edition = append_text_with_llm_provenance(
            &wd.current_edition,
            text,
            llm_model,
            triggerer_club_id,
            server_pub_key,
            attestation_json,
        );
        wd.cached_text
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .take();
        Ok(())
    }

    pub fn materialize_edition_with_provenance(
        &mut self,
        work_id: BeId,
        signing_key: &SigningKey,
        server_id_bytes: &[u8; 32],
        timestamp: u64,
        author_signing_keys: &std::collections::HashMap<BeId, SigningKey>,
    ) -> Result<Edition, OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;

        let federated_prov: Vec<SpanProvenance> = wd.federated_provenance.clone();
        let edition = wd.current_edition.clone();

        let span_provenance = if !federated_prov.is_empty() {
            federated_prov
        } else {
            Self::build_edition_provenance(
                &edition,
                signing_key,
                server_id_bytes,
                timestamp,
                author_signing_keys,
            )
        };

        wd.base_edition = edition.clone();
        wd.pending_edition = None;

        let mut edition = edition;
        edition.span_provenance = span_provenance;
        Ok(edition)
    }

    #[cfg(test)]
    pub fn test_build_provenance(
        edition: &Edition,
        fallback_signing_key: &SigningKey,
        server_id_bytes: &[u8; 32],
        timestamp: u64,
        author_signing_keys: &std::collections::HashMap<BeId, SigningKey>,
    ) -> Vec<crate::edition::SpanProvenance> {
        Self::build_edition_provenance(
            edition,
            fallback_signing_key,
            server_id_bytes,
            timestamp,
            author_signing_keys,
        )
    }

    fn build_edition_provenance(
        edition: &Edition,
        fallback_signing_key: &SigningKey,
        server_id_bytes: &[u8; 32],
        timestamp: u64,
        _author_signing_keys: &std::collections::HashMap<BeId, SigningKey>,
    ) -> Vec<SpanProvenance> {
        let entries = edition.all_entries();
        if entries.is_empty() {
            return Vec::new();
        }

        let has_element_prov = entries.iter().any(|(_, c)| c.provenance.is_some());
        if !has_element_prov {
            let first_pos = entries.first().map(|(p, _)| *p).unwrap_or(0);
            let last_pos = entries.last().map(|(p, _)| *p).unwrap_or(0);
            let fingerprints: Vec<[u8; 32]> = entries
                .iter()
                .map(|(_, c)| c.element.content_fingerprint())
                .collect();
            if fingerprints.is_empty() {
                return Vec::new();
            }
            return vec![SpanProvenance {
                start: first_pos,
                end: last_pos + 1,
                provenance: sign_span(
                    fallback_signing_key,
                    &fingerprints,
                    timestamp,
                    server_id_bytes,
                ),
            }];
        }

        let mut spans: Vec<SpanProvenance> = Vec::new();
        let mut i = 0;
        while i < entries.len() {
            let (start_pos, carrier) = &entries[i];

            // Handle entries without provenance: group consecutive ones into
            // a fallback span (attributed to the server, not any specific author)
            if carrier.provenance.is_none() {
                let mut fingerprints = Vec::new();
                let mut end_pos = *start_pos + 1;
                let mut j = i;
                while j < entries.len() {
                    if entries[j].1.provenance.is_some() {
                        break;
                    }
                    fingerprints.push(entries[j].1.element.content_fingerprint());
                    end_pos = entries[j].0 + 1;
                    j += 1;
                }
                if !fingerprints.is_empty() {
                    spans.push(SpanProvenance {
                        start: *start_pos,
                        end: end_pos,
                        provenance: sign_span(
                            fallback_signing_key,
                            &fingerprints,
                            timestamp,
                            server_id_bytes,
                        ),
                    });
                }
                i = j;
                continue;
            }

            let ep = carrier.provenance.as_ref().unwrap();

            let author_key = ep.author_club_id;
            let author_type = ep.author_type.clone();
            let signing_key =
                if matches!(ep.author_type, crate::edition::provenance::AuthorType::Llm) {
                    fallback_signing_key
                } else {
                    _author_signing_keys
                        .get(&author_key)
                        .unwrap_or(fallback_signing_key)
                };

            let mut fingerprints = Vec::new();
            let mut end_pos = *start_pos;
            let mut last_ts = ep.timestamp;
            let mut j = i;

            while j < entries.len() {
                let (pos, c) = &entries[j];
                match &c.provenance {
                    Some(p) if p.author_club_id == author_key && p.author_type == author_type => {
                        fingerprints.push(c.element.content_fingerprint());
                        end_pos = *pos + 1;
                        last_ts = p.timestamp;
                        j += 1;
                    }
                    Some(_) => break,
                    None => {
                        // Do NOT absorb unattributed entries into this author's span.
                        // They will get their own span (signed by fallback) below.
                        break;
                    }
                }
            }

            if !fingerprints.is_empty() {
                tracing::debug!(
                    "[build_prov] span {}..{} author_type={:?} author_key={:04x} fps={}",
                    start_pos,
                    end_pos,
                    author_type,
                    author_key,
                    fingerprints.len()
                );
                spans.push(SpanProvenance {
                    start: *start_pos,
                    end: end_pos,
                    provenance: sign_span(signing_key, &fingerprints, last_ts, server_id_bytes),
                });
            }

            i = j;
        }

        spans
    }

    pub fn needs_materialization(&self, work_id: BeId) -> Result<bool, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd.pending_edition.is_some())
    }

    pub fn debounce_elapsed(&self, work_id: BeId) -> Result<bool, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        if wd.last_change_timestamp == 0 {
            return Ok(false);
        }
        let elapsed = current_timestamp_secs().saturating_sub(wd.last_change_timestamp);
        Ok(elapsed >= self.debounce_secs)
    }

    pub fn subscriber_count(&self, work_id: BeId) -> usize {
        self.docs
            .get(&work_id)
            .map(|wd| wd.subscribers.len())
            .unwrap_or(0)
    }

    pub fn is_active(&self, work_id: BeId) -> bool {
        self.docs.contains_key(&work_id)
    }

    pub fn pending_work_ids(&self) -> Vec<BeId> {
        self.docs
            .iter()
            .filter(|(_, wd)| wd.pending_edition.is_some())
            .map(|(id, _)| *id)
            .collect()
    }

    pub fn works_for_session(&self, session_id: SessionId) -> Vec<BeId> {
        self.docs
            .iter()
            .filter(|(_, wd)| wd.subscribers.contains_key(&session_id))
            .map(|(id, _)| *id)
            .collect()
    }

    pub fn close_session(&mut self, work_id: BeId, session_id: SessionId) {
        if let Some(wd) = self.docs.get_mut(&work_id) {
            wd.subscribers.remove(&session_id);
            wd.awareness.remove(&session_id);
            if wd.subscribers.is_empty() {
                *wd.cached_text.lock().unwrap_or_else(|e| e.into_inner()) = None;
            }
        }
    }

    pub fn is_subscriber(&self, work_id: BeId, session_id: SessionId) -> bool {
        self.docs
            .get(&work_id)
            .map(|wd| wd.subscribers.contains_key(&session_id))
            .unwrap_or(false)
    }

    pub fn active_works(&self) -> Vec<BeId> {
        self.docs.keys().copied().collect()
    }

    pub fn works_needing_materialization(&self) -> Vec<BeId> {
        self.docs
            .iter()
            .filter(|(_, wd)| wd.pending_edition.is_some())
            .map(|(id, _)| *id)
            .collect()
    }

    pub fn initialize_from_edition(&mut self, work_id: BeId, edition: &Edition) {
        if self.docs.contains_key(&work_id) {
            return;
        }
        let annotations = self
            .orphaned_annotations
            .remove(&work_id)
            .unwrap_or_default();
        self.docs.insert(
            work_id,
            OtreeWorkDoc {
                base_edition: edition.clone(),
                current_edition: edition.clone(),
                session_bases: HashMap::new(),
                current_origin: None,
                pending_edition: None,
                narration_snapshot: None,
                subscribers: HashMap::new(),
                author_keys: HashMap::new(),
                historical_authors: HashMap::new(),
                club_signing_keys: HashMap::new(),
                last_change_timestamp: 0,
                awareness: HashMap::new(),
                federated_provenance: Vec::new(),
                last_author_mapping: None,
                cached_text: Mutex::new(None),
                annotations,
            },
        );
    }

    pub fn ensure_doc_for_annotations(&mut self, work_id: BeId, edition: &Edition) {
        if self.docs.contains_key(&work_id) {
            return;
        }
        self.initialize_from_edition(work_id, edition);
    }

    pub fn get_author_mapping(&self, work_id: BeId) -> Option<Mapping> {
        self.docs
            .get(&work_id)
            .and_then(|wd| wd.last_author_mapping.clone())
    }

    pub fn register_author(
        &mut self,
        work_id: BeId,
        session_id: SessionId,
        author: OtreeAuthorIdentity,
    ) -> Result<(), OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        if !wd.subscribers.contains_key(&session_id) {
            return Err(OtreeError::NotSubscribed(work_id, session_id));
        }
        wd.author_keys.insert(session_id, author);
        Ok(())
    }

    pub fn get_author(
        &self,
        work_id: BeId,
        session_id: SessionId,
    ) -> Result<Option<OtreeAuthorIdentity>, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd.author_keys.get(&session_id).cloned())
    }

    pub fn get_author_sessions(
        &self,
        work_id: BeId,
    ) -> Result<Vec<(SessionId, OtreeAuthorIdentity)>, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        let mut result: Vec<(SessionId, OtreeAuthorIdentity)> = wd
            .author_keys
            .iter()
            .map(|(sid, ai)| (*sid, ai.clone()))
            .collect();
        // Include historical authors (disconnected but their text persists)
        for (sid, ai) in &wd.historical_authors {
            if !wd.author_keys.contains_key(sid) {
                result.push((*sid, ai.clone()));
            }
        }
        Ok(result)
    }

    pub fn get_subscribed_sessions(&self, work_id: BeId) -> Result<Vec<SessionId>, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd.subscribers.keys().copied().collect())
    }

    pub fn store_club_signing_key(
        &mut self,
        work_id: BeId,
        club_be_id: BeId,
        signing_key: SigningKey,
    ) {
        self.persistent_signing_keys
            .insert((work_id, club_be_id), signing_key.clone());
        if let Some(wd) = self.docs.get_mut(&work_id) {
            wd.club_signing_keys.insert(club_be_id, signing_key);
        }
    }

    pub fn get_club_signing_key(&self, work_id: BeId, club_be_id: BeId) -> Option<SigningKey> {
        if let Some(wd) = self.docs.get(&work_id) {
            if let Some(sk) = wd.club_signing_keys.get(&club_be_id) {
                return Some(sk.clone());
            }
        }
        self.persistent_signing_keys
            .get(&(work_id, club_be_id))
            .cloned()
    }

    pub fn update_awareness(
        &mut self,
        work_id: BeId,
        session_id: SessionId,
        state: OtreeAwarenessState,
    ) -> Result<OtreeAwarenessRelayResult, OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        if !wd.subscribers.contains_key(&session_id) {
            return Err(OtreeError::NotSubscribed(work_id, session_id));
        }
        wd.awareness.insert(session_id, state);
        let relay_to: Vec<(SessionId, OtreeSyncSessionId)> = wd
            .subscribers
            .iter()
            .filter(|(sid, _)| **sid != session_id)
            .map(|(sid, sync_id)| (*sid, *sync_id))
            .collect();
        Ok(OtreeAwarenessRelayResult { relay_to })
    }

    pub fn remove_awareness(
        &mut self,
        work_id: BeId,
        session_id: SessionId,
    ) -> Result<OtreeAwarenessRelayResult, OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        wd.awareness.remove(&session_id);
        let relay_to: Vec<(SessionId, OtreeSyncSessionId)> = wd
            .subscribers
            .iter()
            .filter(|(sid, _)| **sid != session_id)
            .map(|(sid, sync_id)| (*sid, *sync_id))
            .collect();
        Ok(OtreeAwarenessRelayResult { relay_to })
    }

    pub fn get_awareness(&self, work_id: BeId) -> Result<Vec<&OtreeAwarenessState>, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd.awareness.values().collect())
    }

    pub fn store_federated_provenance(&mut self, work_id: BeId, provenance: Vec<SpanProvenance>) {
        if let Some(wd) = self.docs.get_mut(&work_id) {
            let existing = std::mem::take(&mut wd.federated_provenance);
            let mut merged: Vec<SpanProvenance> = existing
                .iter()
                .filter(|old| {
                    !provenance
                        .iter()
                        .any(|new| new.start < old.end && old.start < new.end)
                })
                .cloned()
                .collect();
            merged.extend(provenance);
            merged.sort_by_key(|s| s.start);
            wd.federated_provenance = merged;
        }
    }

    pub fn get_federated_provenance(&self, work_id: BeId) -> Option<&[SpanProvenance]> {
        self.docs
            .get(&work_id)
            .map(|wd| wd.federated_provenance.as_slice())
    }

    pub fn sync_to_edition(&mut self, work_id: BeId, edition: Edition) -> Result<(), OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        wd.current_origin = None;
        wd.current_edition = edition;
        wd.base_edition = wd.current_edition.clone();
        wd.pending_edition = None;
        *wd.cached_text.lock().unwrap_or_else(|e| e.into_inner()) = None;
        Ok(())
    }

    pub fn extract_update_for_federation(&mut self, work_id: BeId) -> Result<String, OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;

        let text = wd.current_edition.to_text();

        wd.base_edition = wd.current_edition.clone();
        wd.pending_edition = None;

        Ok(text)
    }

    pub fn apply_federation_update(
        &mut self,
        work_id: BeId,
        update_text: &str,
        initial_edition: Option<&Edition>,
    ) -> Result<OtreeApplyResult, OtreeError> {
        let incoming_edition = Edition::from_text_batched(update_text);

        if !self.docs.contains_key(&work_id) {
            let edition = initial_edition
                .cloned()
                .unwrap_or_else(|| incoming_edition.clone());
            self.initialize_from_edition(work_id, &edition);
        }

        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;

        let base = &wd.base_edition;
        let current = &wd.current_edition;

        let merged = if base == current {
            incoming_edition
        } else {
            match three_way_merge(
                base,
                current,
                &incoming_edition,
                MergeStrategy::LastWriterWins,
            ) {
                Ok(result) => result.merged,
                Err(_) => incoming_edition,
            }
        };

        wd.current_origin = None;
        wd.current_edition = merged;
        *wd.cached_text.lock().unwrap_or_else(|e| e.into_inner()) = None;
        wd.last_change_timestamp = current_timestamp_secs();

        let relay_to: Vec<(SessionId, OtreeSyncSessionId)> = wd
            .subscribers
            .iter()
            .map(|(sid, sync_id)| (*sid, *sync_id))
            .collect();

        Ok(OtreeApplyResult {
            relay_to,
            was_merged: false,
        })
    }

    pub fn sign_update(&self, update_text: &str, signing_key: &SigningKey) -> OtreeSignedUpdate {
        let signature = sign_bytes(signing_key, update_text.as_bytes());
        let verifying_key = signing_key.verifying_key();
        OtreeSignedUpdate {
            update_text: update_text.to_string(),
            signature: signature.to_bytes().to_vec(),
            signer_public_key: verifying_key.to_bytes(),
        }
    }

    pub fn verify_signed_update(
        &self,
        signed: &OtreeSignedUpdate,
        known_keys: &HashMap<[u8; 32], VerifyingKey>,
    ) -> Result<(), OtreeSigningError> {
        let vk = known_keys
            .get(&signed.signer_public_key)
            .ok_or_else(|| OtreeSigningError::UnknownSigner(signed.signer_public_key))?;

        let sig_bytes: [u8; 64] = signed
            .signature
            .clone()
            .try_into()
            .map_err(|_| OtreeSigningError::InvalidSignatureBytes)?;
        let signature = Signature::from_bytes(&sig_bytes);

        verify_signature(vk, signed.update_text.as_bytes(), &signature)
            .map_err(|_| OtreeSigningError::VerificationFailed("signature does not verify".into()))
    }

    pub fn extract_signed_update_for_federation(
        &mut self,
        work_id: BeId,
        signing_key: &SigningKey,
    ) -> Result<OtreeSignedUpdate, OtreeError> {
        let update_text = self.extract_update_for_federation(work_id)?;
        Ok(self.sign_update(&update_text, signing_key))
    }

    pub fn apply_signed_federation_update(
        &mut self,
        work_id: BeId,
        signed: &OtreeSignedUpdate,
        known_keys: &HashMap<[u8; 32], VerifyingKey>,
        initial_edition: Option<&Edition>,
    ) -> Result<OtreeApplyResult, OtreeError> {
        self.verify_signed_update(signed, known_keys)
            .map_err(OtreeError::SigningFailed)?;

        self.apply_federation_update(work_id, &signed.update_text, initial_edition)
    }

    pub fn annotation_create(
        &mut self,
        work_id: BeId,
        annotation_id: u64,
        kind: String,
        payload: String,
        char_start: usize,
        char_end: usize,
        created_by: Option<BeId>,
        is_private: bool,
    ) -> Result<(), OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        wd.annotations.push(OtreeAnnotation {
            annotation_id,
            kind,
            payload,
            char_start,
            char_end,
            created_by,
            created_at: current_timestamp_secs(),
            is_private,
        });
        Ok(())
    }

    pub fn annotation_delete(
        &mut self,
        work_id: BeId,
        annotation_id: u64,
    ) -> Result<(), OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        wd.annotations.retain(|a| a.annotation_id != annotation_id);
        Ok(())
    }

    pub fn annotation_get(
        &self,
        work_id: BeId,
        annotation_id: u64,
    ) -> Result<Option<&OtreeAnnotation>, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd
            .annotations
            .iter()
            .find(|a| a.annotation_id == annotation_id))
    }

    pub fn annotation_list(&self, work_id: BeId) -> Result<Vec<&OtreeAnnotation>, OtreeError> {
        let wd = self
            .docs
            .get(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        Ok(wd.annotations.iter().collect())
    }

    pub fn annotation_update_range(
        &mut self,
        work_id: BeId,
        annotation_id: u64,
        char_start: usize,
        char_end: usize,
    ) -> Result<(), OtreeError> {
        let wd = self
            .docs
            .get_mut(&work_id)
            .ok_or(OtreeError::WorkNotFound(work_id))?;
        if let Some(ann) = wd
            .annotations
            .iter_mut()
            .find(|a| a.annotation_id == annotation_id)
        {
            ann.char_start = char_start;
            ann.char_end = char_end;
        }
        Ok(())
    }

    pub fn all_annotations(&self) -> Vec<(BeId, Vec<OtreeAnnotation>)> {
        let mut result: Vec<(BeId, Vec<OtreeAnnotation>)> = self
            .docs
            .iter()
            .filter(|(_, wd)| !wd.annotations.is_empty())
            .map(|(work_id, wd)| (*work_id, wd.annotations.clone()))
            .collect();
        for (work_id, anns) in &self.orphaned_annotations {
            if !anns.is_empty() {
                result.push((*work_id, anns.clone()));
            }
        }
        result
    }

    pub fn restore_annotations(&mut self, data: &[(BeId, Vec<OtreeAnnotation>)]) {
        for (work_id, annotations) in data {
            if let Some(wd) = self.docs.get_mut(work_id) {
                let existing_ids: std::collections::HashSet<u64> =
                    wd.annotations.iter().map(|a| a.annotation_id).collect();
                for ann in annotations {
                    if !existing_ids.contains(&ann.annotation_id) {
                        wd.annotations.push(ann.clone());
                    }
                }
            } else {
                let existing = self.orphaned_annotations.entry(*work_id).or_default();
                let existing_ids: std::collections::HashSet<u64> =
                    existing.iter().map(|a| a.annotation_id).collect();
                for ann in annotations {
                    if !existing_ids.contains(&ann.annotation_id) {
                        existing.push(ann.clone());
                    }
                }
            }
        }
    }

    pub fn filter_annotations(
        &mut self,
        work_id: BeId,
        deleted_ids: &std::collections::HashSet<u64>,
    ) {
        if let Some(wd) = self.docs.get_mut(&work_id) {
            wd.annotations
                .retain(|a| !deleted_ids.contains(&a.annotation_id));
        }
    }

    pub fn replace_edition(&mut self, work_id: BeId, edition: crate::edition::Edition) {
        if let Some(wd) = self.docs.get_mut(&work_id) {
            wd.current_edition = edition;
            wd.current_origin = None;
            wd.cached_text
                .lock()
                .unwrap_or_else(|e| e.into_inner())
                .take();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use proptest::prelude::*;

    /// Stage 5: fast path must produce text identical to the bulk path
    /// across doc shapes and op patterns.
    #[test]
    fn fast_path_text_equivalence_matrix() {
        fn data_entry(bytes: Vec<u8>) -> Arc<Carrier> {
            Arc::new(Carrier::new(RangeElement::Data { bytes }))
        }

        let mut docs: Vec<(&str, Edition)> = vec![
            ("batched", Edition::from_text_batched("hello\nworld\nfoo")),
            ("fragmented", Edition::from_text("hello world")),
            (
                "unicode",
                Edition::from_text_batched("héllo wörld\n日本語テキスト"),
            ),
            ("single", Edition::from_text("x")),
        ];
        {
            let mut entries = vec![
                (
                    0i64,
                    Arc::new(Carrier::new(RangeElement::text("ab".to_string()))),
                ),
                (1i64, data_entry(vec![])),
                (
                    2i64,
                    Arc::new(Carrier::new(RangeElement::text("cd".to_string()))),
                ),
                (3i64, data_entry(vec![1, 2])),
                (
                    4i64,
                    Arc::new(Carrier::new(RangeElement::text("ef".to_string()))),
                ),
            ];
            entries.sort_by_key(|(p, _)| *p);
            docs.push(("zero-char-mixed", Edition::from_entries(entries)));
        }

        for (name, doc) in &docs {
            let total = doc.char_len();
            let mid = total / 2;
            let tail3 = 3.min(total - mid);
            let op_sets: Vec<Vec<TextDeltaOp>> = vec![
                vec![TextDeltaOp::Insert {
                    text: "NEW\n".into(),
                }],
                vec![
                    TextDeltaOp::Retain { count: mid as u64 },
                    TextDeltaOp::Insert { text: "X".into() },
                    TextDeltaOp::Retain {
                        count: (total - mid) as u64,
                    },
                ],
                vec![
                    TextDeltaOp::Retain { count: mid as u64 },
                    TextDeltaOp::Delete {
                        count: tail3 as u64,
                    },
                    TextDeltaOp::Retain {
                        count: (total - mid - tail3) as u64,
                    },
                ],
                vec![
                    TextDeltaOp::Retain {
                        count: total as u64,
                    },
                    TextDeltaOp::Insert { text: "END".into() },
                ],
                vec![TextDeltaOp::Delete {
                    count: total as u64,
                }],
                vec![
                    TextDeltaOp::Retain {
                        count: total as u64 + 10,
                    },
                    TextDeltaOp::Insert { text: "?".into() },
                ],
                vec![
                    TextDeltaOp::Retain { count: mid as u64 },
                    TextDeltaOp::Insert { text: "A".into() },
                    TextDeltaOp::Retain {
                        count: 1.min(total - mid) as u64,
                    },
                    TextDeltaOp::Insert { text: "B".into() },
                    TextDeltaOp::Retain {
                        count: total.saturating_sub(mid + 1) as u64,
                    },
                ],
            ];

            for (i, ops) in op_sets.iter().enumerate() {
                let fast = apply_text_delta_to_edition(doc, ops, None);
                let bulk =
                    apply_text_delta_to_edition_bulk(doc, ops, &None, std::time::Instant::now());
                assert_eq!(
                    fast.to_text(),
                    bulk.to_text(),
                    "doc={} ops#{}: fast text must equal bulk text",
                    name,
                    i
                );
                assert_eq!(fast.char_len(), bulk.char_len(), "doc={} ops#{}", name, i);
            }
        }
    }

    /// Stage 5: property test — random docs and valid delta sequences,
    /// fast path text must always equal bulk path text, and positions
    /// must stay strictly increasing.
    proptest! {
        #[test]
        fn prop_fast_path_matches_bulk(
            doc in "[a-z \n]{0,120}",
            batched in proptest::bool::ANY,
            seed_ops in proptest::collection::vec((0u8..100, 0u8..3, "[a-z]{0,6}"), 0..12),
        ) {
            let edition = if batched {
                Edition::from_text_batched(&doc)
            } else {
                Edition::from_text(&doc)
            };
            let total = edition.char_len();

            let mut pos = 0usize;
            let mut ops: Vec<TextDeltaOp> = Vec::new();
            for (r, kind, ins) in &seed_ops {
                let r = (*r as usize) % 8;
                if pos + r > total {
                    break;
                }
                if r > 0 {
                    ops.push(TextDeltaOp::Retain { count: r as u64 });
                    pos += r;
                }
                match kind % 3 {
                    0 => {
                        if !ins.is_empty() {
                            ops.push(TextDeltaOp::Insert { text: ins.clone() });
                        }
                    }
                    1 => {
                        if pos < total {
                            let d = (1 + pos % 3).min(total - pos);
                            if d > 0 {
                                ops.push(TextDeltaOp::Delete { count: d as u64 });
                                pos += d;
                            }
                        }
                    }
                    _ => {}
                }
            }
            if pos < total {
                ops.push(TextDeltaOp::Retain { count: (total - pos) as u64 });
            }

            let fast = apply_text_delta_to_edition(&edition, &ops, None);
            let bulk = apply_text_delta_to_edition_bulk(&edition, &ops, &None, std::time::Instant::now());
            prop_assert_eq!(fast.to_text(), bulk.to_text());

            let positions: Vec<i64> = fast.cached_entries().iter().map(|(p, _)| *p).collect();
            for w in positions.windows(2) {
                prop_assert!(w[0] < w[1], "positions must strictly increase");
            }
        }
    }

    /// Stage 5: after a fast-path edit on a spaced layout, untouched
    /// entries keep their positions.
    #[test]
    fn fast_path_preserves_untouched_positions() {
        use crate::space::position_allocator::{spaced_layout, DEFAULT_SPACING};

        let ps = spaced_layout(8, DEFAULT_SPACING);
        let entries: Vec<(i64, Arc<Carrier>)> = ps
            .iter()
            .enumerate()
            .map(|(i, p)| {
                (
                    *p,
                    Arc::new(Carrier::new(RangeElement::text(format!("e{}.", i)))),
                )
            })
            .collect();
        let ed = Edition::from_entries_at_positions(entries).unwrap();
        let original_positions = ed.positions();

        let mid_char = ed.char_len() / 2;
        let ops = vec![
            TextDeltaOp::Retain {
                count: mid_char as u64,
            },
            TextDeltaOp::Insert {
                text: "INSERT.".to_string(),
            },
            TextDeltaOp::Retain {
                count: (ed.char_len() - mid_char) as u64,
            },
        ];
        let result = apply_text_delta_to_edition(&ed, &ops, None);

        let new_positions = result.positions();
        let kept = original_positions
            .iter()
            .filter(|p| new_positions.contains(p))
            .count();
        assert!(
            kept >= original_positions.len() - 4,
            "most untouched positions preserved (kept {}/{}): {:?} -> {:?}",
            kept,
            original_positions.len(),
            original_positions,
            new_positions
        );
        for w in new_positions.windows(2) {
            assert!(w[0] < w[1]);
        }
        let text = result.to_text();
        assert!(text.contains("INSERT."));
        assert!(text.starts_with("e0."));
        assert!(text.ends_with("e7."));
    }

    fn make_session(id: u64) -> SessionId {
        SessionId::new(id)
    }

    #[test]
    fn test_open_close_session() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        let edition = Edition::from_text("hello");
        let result = mgr.open_sync_session(work_id, sid, Some(&edition));
        assert!(mgr.is_active(work_id));
        assert_eq!(mgr.subscriber_count(work_id), 1);
        assert_eq!(result.current_text, "hello");

        mgr.close_sync_session(work_id, sid).unwrap();
        assert!(!mgr.is_active(work_id));
    }

    #[test]
    fn test_apply_text_delta_single_author() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr.open_sync_session(work_id, sid, Some(&Edition::from_text("hello")));

        let ops = vec![
            TextDeltaOp::Retain { count: 5 as u64 },
            TextDeltaOp::Insert {
                text: " world".to_string(),
            },
        ];
        let result = mgr.apply_text_delta(work_id, sid, &ops).unwrap();
        assert!(result.relay_to.is_empty());

        let text = mgr.current_text(work_id).unwrap();
        assert_eq!(text, "hello world");
    }

    #[test]
    fn test_apply_text_delta_relays_to_other_subscribers() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text("")));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text("")));

        let ops = vec![TextDeltaOp::Insert {
            text: "hi".to_string(),
        }];
        let result = mgr.apply_text_delta(work_id, s1, &ops).unwrap();
        assert_eq!(result.relay_to.len(), 1);
        assert_eq!(result.relay_to[0].0, s2);
    }

    #[test]
    fn test_materialize_edition() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr.open_sync_session(work_id, sid, Some(&Edition::from_text("hello")));

        let ops = vec![TextDeltaOp::Insert {
            text: " world".to_string(),
        }];
        mgr.apply_text_delta(work_id, sid, &ops).unwrap();

        let edition = mgr.materialize_edition(work_id).unwrap();
        let text: String = edition
            .all_entries()
            .iter()
            .map(|(_, c)| c.element.as_text().unwrap_or(""))
            .collect();
        assert_eq!(text, " worldhello");
    }

    #[test]
    fn test_needs_materialization() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr.open_sync_session(work_id, sid, Some(&Edition::from_text("hello")));
        assert!(!mgr.needs_materialization(work_id).unwrap());

        let ops = vec![TextDeltaOp::Insert {
            text: "!".to_string(),
        }];
        mgr.apply_text_delta(work_id, sid, &ops).unwrap();
        assert!(mgr.needs_materialization(work_id).unwrap());

        mgr.materialize_edition(work_id).unwrap();
        assert!(!mgr.needs_materialization(work_id).unwrap());
    }

    #[test]
    #[test]
    fn test_delete_in_delta() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr.open_sync_session(work_id, sid, Some(&Edition::from_text("abcde")));

        let ops = vec![
            TextDeltaOp::Retain { count: 1 },
            TextDeltaOp::Delete { count: 3 },
            TextDeltaOp::Retain { count: 1 },
        ];
        mgr.apply_text_delta(work_id, sid, &ops).unwrap();

        let text = mgr.current_text(work_id).unwrap();
        assert_eq!(text, "ae");
    }

    #[test]
    fn test_initialize_from_edition() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let edition = Edition::from_text("existing content");

        mgr.initialize_from_edition(work_id, &edition);
        assert!(mgr.is_active(work_id));

        let sid = make_session(1);
        let result = mgr.open_sync_session(work_id, sid, None);
        assert_eq!(result.current_text, "existing content");
    }

    #[test]
    fn test_awareness() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text("")));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text("")));

        let state = OtreeAwarenessState {
            session_id: 1,
            user_name: "Alice".to_string(),
            club_id: None,
            author_public_key: None,
            cursor: Some(OtreeCursorPosition { index: 5 }),
            selection: None,
            is_typing: true,
        };
        let result = mgr.update_awareness(work_id, s1, state).unwrap();
        assert_eq!(result.relay_to.len(), 1);

        let awareness = mgr.get_awareness(work_id).unwrap();
        assert_eq!(awareness.len(), 1);
    }

    #[test]
    fn test_federation_roundtrip() {
        let mut mgr1 = OtreeCrdtManager::new(3);
        let mut mgr2 = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr1.open_sync_session(work_id, sid, Some(&Edition::from_text("hello")));

        let ops = vec![
            TextDeltaOp::Retain { count: 5 as u64 },
            TextDeltaOp::Insert {
                text: " world".to_string(),
            },
        ];
        mgr1.apply_text_delta(work_id, sid, &ops).unwrap();

        let update_text = mgr1.extract_update_for_federation(work_id).unwrap();

        mgr2.apply_federation_update(work_id, &update_text, None)
            .unwrap();

        let text = mgr2.current_text(work_id).unwrap();
        assert_eq!(text, "hello world");
    }

    /// Benchmark: single-character delta at increasing scale, for both
    /// batched (per-line entries) and fragmented (per-char entries)
    /// editions. Reports first-edit cost (includes the one-time dense
    /// -> spaced layout rebase) and steady-state cost (second edit,
    /// the tree-native fast path on a healed layout) — the target of
    /// PERF-PLAN Stage 5. A flat steady-state curve means per-edit cost
    /// no longer scales with document size.
    #[test]
    fn benchmark_apply_delta_at_scale() {
        for size in [1_000usize, 10_000, 100_000] {
            let text: String = "abcdefghij\n".repeat(size / 11);
            let chars = text.chars().count();
            let mid = chars / 2;
            let ops = vec![
                TextDeltaOp::Retain { count: mid as u64 },
                TextDeltaOp::Insert {
                    text: "X".to_string(),
                },
            ];

            let batched = Edition::from_text_batched(&text);
            let start = std::time::Instant::now();
            let result = apply_text_delta_to_edition(&batched, &ops, None);
            let first = start.elapsed();
            let start = std::time::Instant::now();
            let result = apply_text_delta_to_edition(&result, &ops, None);
            let steady = start.elapsed();
            assert_eq!(result.char_len(), chars + 2);
            println!(
                "apply_delta batched ({} chars, {} entries): first={:?} steady={:?}",
                size,
                batched.count(),
                first,
                steady
            );
        }

        for size in [1_000usize, 10_000, 100_000] {
            let text: String = "ab".repeat(size / 2);
            let mid = size / 2;
            let ops = vec![
                TextDeltaOp::Retain { count: mid as u64 },
                TextDeltaOp::Insert {
                    text: "X".to_string(),
                },
            ];

            let fragmented = Edition::from_text(&text);
            let start = std::time::Instant::now();
            let result = apply_text_delta_to_edition(&fragmented, &ops, None);
            let first = start.elapsed();
            let start = std::time::Instant::now();
            let result = apply_text_delta_to_edition(&result, &ops, None);
            let steady = start.elapsed();
            assert_eq!(result.char_len(), size + 2);
            println!(
                "apply_delta fragmented ({} chars, {} entries): first={:?} steady={:?}",
                size,
                fragmented.count(),
                first,
                steady
            );
        }
    }

    /// S3 verification: repeated edits to the same region through the
    /// production path (post-edit splay active). Before splay
    /// activation: 200 edits @100k = 1.47s (tree fragmentation from
    /// repeated combines); after: measured below.
    #[test]
    fn benchmark_repeated_same_region_edits() {
        const EDITS: usize = 200;
        for size in [1_000usize, 10_000, 100_000] {
            let text: String = "ab".repeat(size / 2);
            let mid = size / 2;

            let mut ed = Edition::from_text(&text);
            let start = std::time::Instant::now();
            for i in 0..EDITS {
                let ops = vec![
                    TextDeltaOp::Retain {
                        count: (mid + i) as u64,
                    },
                    TextDeltaOp::Insert {
                        text: "x".to_string(),
                    },
                ];
                ed = apply_text_delta_to_edition(&ed, &ops, None);
            }
            let elapsed = start.elapsed();
            println!(
                "same-region {} edits ({} entries): {:?} ({:.1}?/edit)",
                EDITS,
                size,
                elapsed,
                elapsed.as_secs_f64() * 1000.0 / EDITS as f64
            );
        }
    }

    #[test]

    /// FR-37 Phase 3 (delta-path materialization): edits INSIDE a
    /// materialized virtual's cached span split it like text — the
    /// fragment keeps its bytes, drops the (now-unrepresentable) spec.
    /// Before the fix, a partial split returned None and the walker
    /// silently dropped the piece: whole-quotation content loss on a
    /// 1-char edit ("AAxyzBB" deleting 'x' yielded "AABB").
    #[test]
    fn virtual_inside_edit_splits_like_text() {
        use crate::edition::range_element::{RangeElement, VirtualSpec};
        let mk = |mat: Option<&str>| {
            let mut vm = RangeElement::virtual_element(VirtualSpec {
                source_work_id: 1,
                char_start: 0,
                char_end: 3,
                revision: 1,
                placed_at: 0,
                placed_by: None,
            });
            if let Some(m) = mat {
                vm.set_virtual_content(m.to_string());
            }
            Edition::from_entries(vec![
                (
                    0i64,
                    Arc::new(Carrier::new(RangeElement::text("AA".to_string()))),
                ),
                (1i64, Arc::new(Carrier::new(vm))),
                (
                    2i64,
                    Arc::new(Carrier::new(RangeElement::text("BB".to_string()))),
                ),
            ])
        };

        // Delete one char inside the virtual ("xyz" -> "yz").
        let ed = mk(Some("xyz"));
        let ops = vec![
            TextDeltaOp::Retain { count: 2 },
            TextDeltaOp::Delete { count: 1 },
            TextDeltaOp::Retain { count: 4 },
        ];
        let r = apply_text_delta_to_edition(&ed, &ops, None);
        assert_eq!(r.to_text(), "AAyzBB");
        assert_eq!(
            r.cached_entries()
                .iter()
                .filter(|(_, c)| c.element.is_virtual())
                .count(),
            0
        );

        // Insert inside the virtual.
        let ed = mk(Some("xyz"));
        let ops = vec![
            TextDeltaOp::Retain { count: 3 },
            TextDeltaOp::Insert {
                text: "-".to_string(),
            },
            TextDeltaOp::Retain { count: 4 },
        ];
        let r = apply_text_delta_to_edition(&ed, &ops, None);
        assert_eq!(r.to_text(), "AAx-yzBB");

        // Retain THROUGH a materialized virtual: spec survives intact.
        let ed = mk(Some("xyz"));
        let ops = vec![TextDeltaOp::Retain { count: 7 }];
        let r = apply_text_delta_to_edition(&ed, &ops, None);
        assert_eq!(
            r.cached_entries()
                .iter()
                .filter(|(_, c)| c.element.is_virtual())
                .count(),
            1,
            "unedit virtual keeps its spec"
        );
        assert_eq!(r.to_text(), "AAxyzBB");

        // Delete covering exactly the whole virtual: it is removed.
        let ed = mk(Some("xyz"));
        let ops = vec![
            TextDeltaOp::Retain { count: 2 },
            TextDeltaOp::Delete { count: 3 },
            TextDeltaOp::Retain { count: 2 },
        ];
        let r = apply_text_delta_to_edition(&ed, &ops, None);
        assert_eq!(r.to_text(), "AABB");
        assert_eq!(
            r.cached_entries()
                .iter()
                .filter(|(_, c)| c.element.is_virtual())
                .count(),
            0
        );

        // Unmaterialized virtual in the neighborhood: passes through
        // untouched (zero-char semantics).
        let ed = mk(None);
        let ops = vec![
            TextDeltaOp::Retain { count: 2 },
            TextDeltaOp::Insert {
                text: "X".to_string(),
            },
        ];
        let r = apply_text_delta_to_edition(&ed, &ops, None);
        assert_eq!(
            r.cached_entries()
                .iter()
                .filter(|(_, c)| c.element.is_virtual())
                .count(),
            1,
            "unmaterialized virtual survives nearby edits"
        );
    }

    fn test_batched_insert_creates_fewer_elements() {
        let edition = Edition::from_text_batched("hello\nworld");
        let ops = vec![TextDeltaOp::Insert {
            text: "new line\n".to_string(),
        }];
        let result = apply_text_delta_to_edition(&edition, &ops, None);
        assert_eq!(result.to_text(), "new line\nhello\nworld");
        assert!(
            result.count() <= 4,
            "batched insert should create few elements, got {}",
            result.count()
        );
    }

    #[test]
    fn test_delta_on_batched_edition_retain() {
        let edition = Edition::from_text_batched("hello\nworld");
        assert_eq!(edition.count(), 2);
        let ops = vec![
            TextDeltaOp::Retain { count: 5 as u64 },
            TextDeltaOp::Insert {
                text: "!\n".to_string(),
            },
            TextDeltaOp::Retain { count: 6 },
        ];
        let result = apply_text_delta_to_edition(&edition, &ops, None);
        assert_eq!(result.to_text(), "hello!\n\nworld");
    }

    #[test]
    fn test_delta_on_batched_edition_delete() {
        let edition = Edition::from_text_batched("hello\nworld\n");
        let ops = vec![
            TextDeltaOp::Retain { count: 5 as u64 },
            TextDeltaOp::Delete { count: 1 },
            TextDeltaOp::Retain { count: 6 },
        ];
        let result = apply_text_delta_to_edition(&edition, &ops, None);
        assert_eq!(result.to_text(), "helloworld\n");
    }

    #[test]
    fn test_delta_on_batched_edition_mid_element_split() {
        let edition = Edition::from_text_batched("abcdef");
        assert_eq!(edition.count(), 1);
        let ops = vec![
            TextDeltaOp::Retain { count: 3 },
            TextDeltaOp::Delete { count: 2 },
            TextDeltaOp::Retain { count: 1 },
        ];
        let result = apply_text_delta_to_edition(&edition, &ops, None);
        assert_eq!(result.to_text(), "abcf");
    }

    #[test]
    fn test_delta_on_batched_edition_mid_element_insert() {
        let edition = Edition::from_text_batched("abcdef");
        let ops = vec![
            TextDeltaOp::Retain { count: 3 },
            TextDeltaOp::Insert {
                text: "XY".to_string(),
            },
            TextDeltaOp::Retain { count: 3 },
        ];
        let result = apply_text_delta_to_edition(&edition, &ops, None);
        assert_eq!(result.to_text(), "abcXYdef");
    }

    #[test]
    fn test_batched_insert_multiline() {
        let edition = Edition::from_text("");
        let ops = vec![TextDeltaOp::Insert {
            text: "line1\nline2\nline3".to_string(),
        }];
        let result = apply_text_delta_to_edition(&edition, &ops, None);
        assert_eq!(result.to_text(), "line1\nline2\nline3");
        assert_eq!(
            result.count(),
            1,
            "coalesce merges uniform-provenance inserts into 1 element"
        );
    }

    #[test]
    fn test_batched_edition_delete_across_elements() {
        let edition = Edition::from_text_batched("aa\nbb\ncc");
        assert_eq!(edition.count(), 3);
        let ops = vec![
            TextDeltaOp::Retain { count: 2 },
            TextDeltaOp::Delete { count: 4 },
            TextDeltaOp::Retain { count: 2 },
        ];
        let result = apply_text_delta_to_edition(&edition, &ops, None);
        assert_eq!(result.to_text(), "aacc");
    }

    #[test]
    fn test_batched_edition_with_author_provenance() {
        let edition = Edition::from_text_batched("hello\nworld");
        let author = OtreeAuthorIdentity {
            public_key: [1u8; 32],
            display_name: "test".to_string(),
            club_be_id: 0,
        };
        let ops = vec![TextDeltaOp::Insert {
            text: "new\n".to_string(),
        }];
        let result = apply_text_delta_to_edition(&edition, &ops, Some(&author));
        assert_eq!(result.to_text(), "new\nhello\nworld");
        let entries = result.all_entries();
        let has_prov = entries.iter().any(|(_, c)| c.provenance.is_some());
        assert!(has_prov, "inserted elements should have provenance");
    }

    #[test]
    fn test_batched_append_llm_provenance() {
        let edition = Edition::from_text_batched("hello\n");
        let result = append_text_with_llm_provenance(
            &edition,
            "world\nfoo",
            "test-model",
            0,
            [0u8; 32],
            None,
        );
        assert_eq!(result.to_text(), "hello\nworld\nfoo");
        let entries = result.all_entries();
        let llm_entries: Vec<_> = entries
            .iter()
            .filter(|(_, c)| {
                c.provenance.as_ref().map_or(false, |p| {
                    matches!(p.author_type, crate::edition::provenance::AuthorType::Llm)
                })
            })
            .collect();
        assert_eq!(
            llm_entries.len(),
            1,
            "coalesce merges uniform-provenance LLM elements into 1"
        );
    }

    #[test]
    fn test_split_text_carrier_basic() {
        let carrier = Carrier::new(RangeElement::text("hello".to_string()));
        let left = split_text_carrier(&carrier, 0, 3).unwrap();
        assert_eq!(left.element.as_text(), Some("hel"));
        let right = split_text_carrier(&carrier, 3, 5).unwrap();
        assert_eq!(right.element.as_text(), Some("lo"));
    }

    #[test]
    fn test_split_text_carrier_empty_returns_none() {
        let carrier = Carrier::new(RangeElement::text("hello".to_string()));
        assert!(split_text_carrier(&carrier, 3, 3).is_none());
    }

    #[test]
    fn test_delta_with_zero_char_elements_retain() {
        let mut entries = vec![];
        let mut pos = 0i64;
        entries.push((
            pos,
            Arc::new(Carrier::new(RangeElement::text("ab".to_string()))),
        ));
        pos += 1;
        entries.push((
            pos,
            Arc::new(Carrier::new(RangeElement::Data { bytes: vec![] })),
        ));
        pos += 1;
        entries.push((
            pos,
            Arc::new(Carrier::new(RangeElement::text("cd".to_string()))),
        ));
        pos += 1;
        let edition = Edition::from_entries(entries);

        let ops = vec![TextDeltaOp::Retain { count: 4 }];
        let result = apply_text_delta_to_edition(&edition, &ops, None);
        assert_eq!(result.to_text(), "abcd");
        assert_eq!(result.count(), 3, "placeholder should be preserved");
    }

    #[test]
    fn test_delta_with_zero_char_elements_delete() {
        let mut entries = vec![];
        let mut pos = 0i64;
        entries.push((
            pos,
            Arc::new(Carrier::new(RangeElement::text("ab".to_string()))),
        ));
        pos += 1;
        entries.push((
            pos,
            Arc::new(Carrier::new(RangeElement::Data { bytes: vec![] })),
        ));
        pos += 1;
        entries.push((
            pos,
            Arc::new(Carrier::new(RangeElement::text("cd".to_string()))),
        ));
        pos += 1;
        let edition = Edition::from_entries(entries);

        let ops = vec![
            TextDeltaOp::Retain { count: 1 },
            TextDeltaOp::Delete { count: 2 },
            TextDeltaOp::Retain { count: 1 },
        ];
        let result = apply_text_delta_to_edition(&edition, &ops, None);
        assert_eq!(result.to_text(), "ad");
    }

    #[test]
    fn test_delta_trailing_zero_char_preserved() {
        let mut entries = vec![];
        let mut pos = 0i64;
        entries.push((
            pos,
            Arc::new(Carrier::new(RangeElement::text("hello".to_string()))),
        ));
        pos += 1;
        entries.push((
            pos,
            Arc::new(Carrier::new(RangeElement::Data { bytes: vec![] })),
        ));
        pos += 1;
        let edition = Edition::from_entries(entries);

        let ops = vec![TextDeltaOp::Retain { count: 5 }];
        let result = apply_text_delta_to_edition(&edition, &ops, None);
        assert_eq!(result.to_text(), "hello");
        assert_eq!(result.count(), 2, "trailing placeholder preserved");
    }

    #[test]
    fn test_batched_mgr_full_workflow() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr.open_sync_session(
            work_id,
            sid,
            Some(&Edition::from_text_batched("line1\nline2\n")),
        );

        let ops = vec![
            TextDeltaOp::Retain { count: 6 },
            TextDeltaOp::Insert {
                text: "inserted\n".to_string(),
            },
            TextDeltaOp::Retain { count: 6 },
        ];
        mgr.apply_text_delta(work_id, sid, &ops).unwrap();

        let text = mgr.current_text(work_id).unwrap();
        assert_eq!(text, "line1\ninserted\nline2\n");
    }

    #[test]
    fn test_annotation_crud() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;

        let edition = Edition::from_text("hello world");
        mgr.initialize_from_edition(work_id, &edition);

        mgr.annotation_create(
            work_id,
            1,
            "note".into(),
            "my note".into(),
            0,
            5,
            None,
            false,
        )
        .unwrap();

        let anns = mgr.annotation_list(work_id).unwrap();
        assert_eq!(anns.len(), 1);
        assert_eq!(anns[0].annotation_id, 1);
        assert_eq!(anns[0].kind, "note");
        assert_eq!(anns[0].payload, "my note");
        assert_eq!(anns[0].char_start, 0);
        assert_eq!(anns[0].char_end, 5);
        assert_eq!(anns[0].created_by, None);

        mgr.annotation_delete(work_id, 1).unwrap();
        let anns = mgr.annotation_list(work_id).unwrap();
        assert!(anns.is_empty());
    }

    #[test]
    fn test_annotation_get() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;

        mgr.initialize_from_edition(work_id, &Edition::from_text("hello"));
        mgr.annotation_create(
            work_id,
            10,
            "highlight".into(),
            "important".into(),
            2,
            4,
            Some(99),
            false,
        )
        .unwrap();

        let ann = mgr.annotation_get(work_id, 10).unwrap().unwrap();
        assert_eq!(ann.annotation_id, 10);
        assert_eq!(ann.kind, "highlight");
        assert_eq!(ann.created_by, Some(99));

        assert!(mgr.annotation_get(work_id, 999).unwrap().is_none());
    }

    #[test]
    fn test_annotation_update_range() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;

        mgr.initialize_from_edition(work_id, &Edition::from_text("hello world"));
        mgr.annotation_create(work_id, 1, "note".into(), "x".into(), 0, 5, None, false)
            .unwrap();

        mgr.annotation_update_range(work_id, 1, 3, 8).unwrap();

        let ann = mgr.annotation_get(work_id, 1).unwrap().unwrap();
        assert_eq!(ann.char_start, 3);
        assert_eq!(ann.char_end, 8);
    }

    #[test]
    fn test_annotation_fails_without_doc() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 99;

        let result =
            mgr.annotation_create(work_id, 1, "note".into(), "x".into(), 0, 5, None, false);
        assert!(result.is_err());
    }

    #[test]
    fn test_ensure_doc_for_annotations() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;

        assert!(!mgr.docs.contains_key(&work_id));

        let edition = Edition::from_text("source text");
        mgr.ensure_doc_for_annotations(work_id, &edition);

        assert!(mgr.docs.contains_key(&work_id));

        mgr.annotation_create(work_id, 1, "note".into(), "ok".into(), 0, 5, None, false)
            .unwrap();
        let anns = mgr.annotation_list(work_id).unwrap();
        assert_eq!(anns.len(), 1);
    }

    #[test]
    fn test_ensure_doc_idempotent() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;

        mgr.open_sync_session(work_id, make_session(1), Some(&Edition::from_text("hello")));

        let text_before = mgr.current_text(work_id).unwrap();

        let edition = Edition::from_text("different");
        mgr.ensure_doc_for_annotations(work_id, &edition);

        let text_after = mgr.current_text(work_id).unwrap();
        assert_eq!(text_before, text_after);
    }

    #[test]
    fn test_all_annotations_empty() {
        let mgr = OtreeCrdtManager::new(3);
        let result = mgr.all_annotations();
        assert!(result.is_empty());
    }

    #[test]
    fn test_all_annotations_multiple_works() {
        let mut mgr = OtreeCrdtManager::new(3);

        let w1: BeId = 1;
        let w2: BeId = 2;

        mgr.initialize_from_edition(w1, &Edition::from_text("aaa"));
        mgr.initialize_from_edition(w2, &Edition::from_text("bbb"));

        mgr.annotation_create(w1, 1, "note".into(), "n1".into(), 0, 1, None, false)
            .unwrap();
        mgr.annotation_create(w1, 2, "note".into(), "n2".into(), 1, 2, None, false)
            .unwrap();
        mgr.annotation_create(w2, 3, "note".into(), "n3".into(), 0, 1, None, false)
            .unwrap();

        let all = mgr.all_annotations();
        assert_eq!(all.len(), 2);

        let w1_anns: Vec<_> = all.iter().filter(|(id, _)| *id == w1).collect();
        let w2_anns: Vec<_> = all.iter().filter(|(id, _)| *id == w2).collect();
        assert_eq!(w1_anns[0].1.len(), 2);
        assert_eq!(w2_anns[0].1.len(), 1);
    }

    #[test]
    fn test_restore_annotations() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;

        mgr.initialize_from_edition(work_id, &Edition::from_text("hello"));

        let data = vec![(
            work_id,
            vec![OtreeAnnotation {
                annotation_id: 99,
                kind: "restored".into(),
                payload: "from disk".into(),
                char_start: 0,
                char_end: 5,
                created_by: Some(7),
                created_at: 0,
                is_private: false,
            }],
        )];

        mgr.restore_annotations(&data);
        let anns = mgr.annotation_list(work_id).unwrap();
        assert_eq!(anns.len(), 1);
        assert_eq!(anns[0].annotation_id, 99);
        assert_eq!(anns[0].kind, "restored");
        assert_eq!(anns[0].created_by, Some(7));
    }

    #[test]
    fn test_concurrent_insert_at_same_position() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text("hello")));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text("hello")));

        let ops1 = vec![
            TextDeltaOp::Retain { count: 2 },
            TextDeltaOp::Insert {
                text: "A".to_string(),
            },
            TextDeltaOp::Retain { count: 3 },
        ];
        mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

        let ops2 = vec![
            TextDeltaOp::Retain { count: 2 },
            TextDeltaOp::Insert {
                text: "B".to_string(),
            },
            TextDeltaOp::Retain { count: 3 },
        ];
        mgr.apply_text_delta(work_id, s2, &ops2).unwrap();

        let text = mgr.current_text(work_id).unwrap();
        assert!(text.contains('A'), "must contain A from s1");
        assert!(text.contains('B'), "must contain B from s2");
        assert!(text.starts_with("he"), "prefix preserved");
        assert!(text.ends_with("llo"), "suffix preserved");
    }

    #[test]
    fn test_concurrent_insert_at_different_positions() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        let base = "The document text";
        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text(base)));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text(base)));

        let ops1 = vec![
            TextDeltaOp::Insert {
                text: "[START] ".to_string(),
            },
            TextDeltaOp::Retain {
                count: base.len() as u64,
            },
        ];
        mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

        let ops2 = vec![
            TextDeltaOp::Retain {
                count: base.len() as u64,
            },
            TextDeltaOp::Insert {
                text: " [END]".to_string(),
            },
        ];
        mgr.apply_text_delta(work_id, s2, &ops2).unwrap();

        let text = mgr.current_text(work_id).unwrap();
        assert!(
            text.contains("The document text"),
            "original text preserved"
        );
    }

    #[test]
    fn test_concurrent_delete_different_regions() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        let base = "abcdefghij";
        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text(base)));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text(base)));

        let ops1 = vec![
            TextDeltaOp::Retain { count: 2 },
            TextDeltaOp::Delete { count: 2 },
            TextDeltaOp::Retain { count: 6 },
        ];
        mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

        let ops2 = vec![
            TextDeltaOp::Retain { count: 6 },
            TextDeltaOp::Delete { count: 2 },
            TextDeltaOp::Retain { count: 2 },
        ];
        mgr.apply_text_delta(work_id, s2, &ops2).unwrap();

        let text = mgr.current_text(work_id).unwrap();
        assert!(
            !text.is_empty(),
            "concurrent deletes must not empty the document"
        );
        assert!(text.contains('a'), "undeleted prefix preserved");
    }

    #[test]
    fn test_concurrent_replace_vs_insert() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        let base = "old text";
        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text(base)));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text(base)));

        let ops1 = vec![
            TextDeltaOp::Delete { count: 3 },
            TextDeltaOp::Insert {
                text: "new".to_string(),
            },
            TextDeltaOp::Retain { count: 5 as u64 },
        ];
        mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

        let ops2 = vec![
            TextDeltaOp::Retain { count: 8 },
            TextDeltaOp::Insert {
                text: " appended".to_string(),
            },
        ];
        mgr.apply_text_delta(work_id, s2, &ops2).unwrap();

        let text = mgr.current_text(work_id).unwrap();
        assert!(text.contains("new"), "replacement from s1 preserved");
        assert!(text.contains("appended"), "insert from s2 preserved");
    }

    #[test]
    fn test_three_users_concurrent_edits() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);
        let s3 = make_session(3);

        let base = "Line one.\nLine two.\nLine three.";
        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text(base)));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text(base)));
        mgr.open_sync_session(work_id, s3, Some(&Edition::from_text(base)));

        let ops1 = vec![
            TextDeltaOp::Retain { count: 9 },
            TextDeltaOp::Insert {
                text: " [edited by A]".to_string(),
            },
            TextDeltaOp::Retain {
                count: (base.len() - 9) as u64,
            },
        ];
        mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

        let line2_start = "Line one.\n".len();
        let ops2 = vec![
            TextDeltaOp::Retain {
                count: (line2_start + 8) as u64,
            },
            TextDeltaOp::Insert {
                text: " [edited by B]".to_string(),
            },
            TextDeltaOp::Retain {
                count: (base.len() - line2_start - 8) as u64,
            },
        ];
        mgr.apply_text_delta(work_id, s2, &ops2).unwrap();

        let line3_start = "Line one.\nLine two.\n".len();
        let ops3 = vec![
            TextDeltaOp::Retain {
                count: (line3_start + 10) as u64,
            },
            TextDeltaOp::Insert {
                text: " [edited by C]".to_string(),
            },
        ];
        mgr.apply_text_delta(work_id, s3, &ops3).unwrap();

        let text = mgr.current_text(work_id).unwrap();
        assert!(text.contains("[edited by A]"), "A's edit must survive");
        assert!(text.contains("[edited by B]"), "B's edit must survive");
        assert!(text.contains("[edited by C]"), "C's edit must survive");
        // B retains (line2_start + 8) — exactly between "Line two"
        // and its period; C likewise on line three. The merged
        // placement now honors the op offsets exactly (previously
        // the merge approximated past the period).
        assert!(text.contains("Line one."), "line 1 preserved");
        assert!(
            text.contains("Line two [edited by B]."),
            "line 2 at op offset: {:?}",
            text
        );
        assert!(
            text.contains("Line three [edited by C]."),
            "line 3 at op offset: {:?}",
            text
        );
    }

    #[test]
    fn test_rapid_sequential_edits_same_author() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let sid = make_session(1);

        mgr.open_sync_session(work_id, sid, Some(&Edition::from_text("")));

        for i in 0..50 {
            let cur = mgr.current_text(work_id).unwrap();
            let ops = vec![
                TextDeltaOp::Retain {
                    count: cur.len() as u64,
                },
                TextDeltaOp::Insert {
                    text: format!("line{}\n", i),
                },
            ];
            mgr.apply_text_delta(work_id, sid, &ops).unwrap();
        }

        let text = mgr.current_text(work_id).unwrap();
        let lines: Vec<&str> = text.lines().collect();
        assert_eq!(lines.len(), 50, "must have 50 lines");
        assert_eq!(lines[0], "line0");
        assert_eq!(lines[49], "line49");
    }

    #[test]
    fn test_interleaved_edits_two_authors() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text("base")));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text("base")));

        for round in 0..10 {
            let ops1 = vec![
                TextDeltaOp::Retain {
                    count: (4 + round * 2) as u64,
                },
                TextDeltaOp::Insert {
                    text: format!("A{}", round),
                },
            ];
            mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

            let ops2 = vec![
                TextDeltaOp::Retain {
                    count: (4 + round * 2 + 2) as u64,
                },
                TextDeltaOp::Insert {
                    text: format!("B{}", round),
                },
            ];
            mgr.apply_text_delta(work_id, s2, &ops2).unwrap();
        }

        let text = mgr.current_text(work_id).unwrap();
        assert!(text.starts_with("base"), "original text preserved");
        for round in 0..10 {
            assert!(
                text.contains(&format!("A{}", round)),
                "A{} must be in merged text",
                round
            );
            assert!(
                text.contains(&format!("B{}", round)),
                "B{} must be in merged text",
                round
            );
        }
    }

    #[test]
    fn test_annotation_migrates_through_concurrent_edit() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text("hello world")));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text("hello world")));

        mgr.annotation_create(
            work_id,
            100,
            "note".to_string(),
            "annotated".to_string(),
            6,
            11,
            None,
            false,
        )
        .unwrap();

        let anns_before = mgr.annotation_list(work_id).unwrap();
        assert_eq!(anns_before[0].char_start, 6);
        assert_eq!(anns_before[0].char_end, 11);

        let ops1 = vec![
            TextDeltaOp::Retain { count: 5 as u64 },
            TextDeltaOp::Insert {
                text: " beautiful".to_string(),
            },
            TextDeltaOp::Retain { count: 6 },
        ];
        mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

        let anns_after = mgr.annotation_list(work_id).unwrap();
        assert_eq!(anns_after.len(), 1, "annotation must survive edit");
    }

    #[test]
    fn test_concurrent_edit_large_document() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        let base = (0..500)
            .map(|i| format!("Line {} of content.\n", i))
            .collect::<String>();
        let base_len = base.len();
        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text(&base)));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text(&base)));

        let quarter = base_len / 4;
        let half = base_len / 2;
        let three_q = base_len * 3 / 4;

        let ops1 = vec![
            TextDeltaOp::Retain {
                count: quarter as u64,
            },
            TextDeltaOp::Insert {
                text: "[INSERT_A]".to_string(),
            },
            TextDeltaOp::Retain {
                count: (base_len - quarter) as u64,
            },
        ];
        mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

        let ops2 = vec![
            TextDeltaOp::Retain {
                count: three_q as u64,
            },
            TextDeltaOp::Insert {
                text: "[INSERT_B]".to_string(),
            },
            TextDeltaOp::Retain {
                count: (base_len - three_q) as u64,
            },
        ];
        mgr.apply_text_delta(work_id, s2, &ops2).unwrap();

        let text = mgr.current_text(work_id).unwrap();
        assert!(
            text.contains("[INSERT_A]"),
            "A's insert at 1/4 must survive"
        );
        assert!(
            text.contains("[INSERT_B]"),
            "B's insert at 3/4 must survive"
        );
        assert!(
            text.len() > base_len,
            "merged must be longer than base (inserts preserved)"
        );
    }

    #[test]
    fn test_concurrent_delete_same_region() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        let base = "keep1 DELETE_ME keep2";
        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text(base)));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text(base)));

        let ops1 = vec![
            TextDeltaOp::Retain { count: 6 },
            TextDeltaOp::Delete { count: 10 },
            TextDeltaOp::Retain { count: 6 },
        ];
        mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

        let ops2 = vec![
            TextDeltaOp::Retain { count: 6 },
            TextDeltaOp::Delete { count: 10 },
            TextDeltaOp::Retain { count: 6 },
        ];
        mgr.apply_text_delta(work_id, s2, &ops2).unwrap();

        let text = mgr.current_text(work_id).unwrap();
        assert!(
            !text.contains("DELETE_ME"),
            "deleted text must not reappear after concurrent delete"
        );
        assert!(text.contains("keep1"), "prefix preserved");
        assert!(text.contains("keep2"), "suffix preserved");
    }

    #[test]
    fn test_relay_notification_on_concurrent_edit() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);
        let s3 = make_session(3);

        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text("base")));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text("base")));
        mgr.open_sync_session(work_id, s3, Some(&Edition::from_text("base")));

        let ops = vec![
            TextDeltaOp::Insert {
                text: "X".to_string(),
            },
            TextDeltaOp::Retain { count: 4 },
        ];
        let result = mgr.apply_text_delta(work_id, s1, &ops).unwrap();

        assert_eq!(result.relay_to.len(), 2, "must relay to s2 and s3");
        let relay_targets: Vec<u64> = result.relay_to.iter().map(|(s, _)| s.as_u64()).collect();
        assert!(relay_targets.contains(&2), "must relay to s2");
        assert!(relay_targets.contains(&3), "must relay to s3");
    }

    #[test]
    fn test_materialize_after_concurrent_edits() {
        let mut mgr = OtreeCrdtManager::new(3);
        let work_id: BeId = 42;
        let s1 = make_session(1);
        let s2 = make_session(2);

        mgr.open_sync_session(work_id, s1, Some(&Edition::from_text("hello")));
        mgr.open_sync_session(work_id, s2, Some(&Edition::from_text("hello")));

        let ops1 = vec![
            TextDeltaOp::Retain { count: 5 },
            TextDeltaOp::Insert {
                text: " world".to_string(),
            },
        ];
        mgr.apply_text_delta(work_id, s1, &ops1).unwrap();

        let ops2 = vec![
            TextDeltaOp::Insert {
                text: "Greeting: ".to_string(),
            },
            TextDeltaOp::Retain { count: 5 },
        ];
        mgr.apply_text_delta(work_id, s2, &ops2).unwrap();

        mgr.materialize_edition(work_id).unwrap();
        let text = mgr.current_text(work_id).unwrap();
        assert!(
            text.contains("Greeting:"),
            "s2 prefix must survive materialization"
        );
        assert!(
            text.contains("world"),
            "s1 suffix must survive materialization"
        );
    }
}
