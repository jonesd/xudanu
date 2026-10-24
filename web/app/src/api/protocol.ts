/** Wire protocol surface: every frame/DTO type shared by the client,
 * the sync engine, and (eventually, FR-88) the wasm engine bridge.
 * Types only — no transport, no state, no React. */

export const PROTOCOL_VERSION = 2;

export interface AwarenessState {
  session_id: number;
  user_name: string;
  cursor: { index: number } | null;
  selection: { start: number; end: number } | null;
  is_typing: boolean;
}

export interface OutlineEntry {
  level: number;
  text: string;
  line: number;
  char_offset: number;
}

export interface SearchMatchItem {
  char_offset: number;
  line: number;
  context: string;
}

export interface SearchResult {
  matches: SearchMatchItem[];
  totalMatches: number;
}

export interface GlobalSearchResultItem {
  work_id: number;
  title?: string;
  owner?: number;
  revision_count: number;
  matches: SearchMatchItem[];
}

// FR-41 S1: federated search fan-out results. All remote text is
// untrusted — render as text only, never as HTML.
export interface FederatedSearchResultEntry {
  work_id: number;
  title: string;
  revision: number;
  char_count: number;
  server_name: string;
  server_id: number;
  local: boolean;
  // FR-91a trust ladder: true when the origin's response carried a
  // valid, pin-anchored signature; false = legacy unsigned peer.
  verified?: boolean;
  // FR-91a: the origin's tumbler for this work (linkable).
  tumbler?: string;
  // Present only for peers that didn't answer (honesty entries).
  unreachable?: boolean;
  reason?: string;
}

export interface GlobalSearchResults {
  results: GlobalSearchResultItem[];
  totalWorksMatched: number;
}

export interface GotoResult {
  line: number;
  charOffset: number;
  context: string;
  contextStartLine: number;
}

export interface ContentMatch {
  fossil_id: number;
  edition_be_id: number;
  is_direct: boolean;
  work_be_id?: number;
  title?: string;
}

export interface AttributionSpan {
  start: number;
  end: number;
  author_public_key: number[];
  author_display_name: string | null;
  author_club_id: number | null;
  signature_valid: boolean;
  verification_state?: string | null;
  timestamp: number;
  server_id: number[];
  author_type: string | null;
  llm_model: string | null;
  historical_author_id: number | null;
  source_work_id?: number | null;
  source_work_title?: string | null;
  transcluded_by_name?: string | null;
  transcluded_by_club_id?: number | null;
  provenance_chain?: ProvenanceHop[] | null;
}

export interface AttributionLogStatus {
  entry_count: number;
  chain_valid: boolean;
  last_sequence: number;
  has_log: boolean;
}

export interface HistoricalAuthor {
  be_id: number;
  name: string;
  display_name: string;
  birth_year: number | null;
  death_year: number | null;
  external_ids: Record<string, string>;
  source_bibliography: string;
}

export interface HistoricalAuthorEntry {
  be_id: number;
  name: string;
  display_name: string;
  birth_year: number | null;
  death_year: number | null;
}

export interface SourceDetectResult {
  source_type: string;
  detected: boolean;
  content_start_line: number;
  content_end_line: number;
  total_lines: number;
  metadata: Record<string, string>;
}

export interface SourcePatternEntry {
  source_type: string;
  display_name: string;
}

export interface WhoAmIEntry {
  club_id: number;
  display_name: string;
  verifying_key?: string;
  clubs?: [number, string][];
}

export interface LlmUsageSummary {
  total_requests: number;
  total_prompt_chars: number;
  total_response_chars: number;
  by_feature: Record<string, { count: number; prompt_chars: number; response_chars: number }>;
}

export interface LinkEndorser {
  club_id: number;
  name?: string | null;
  /** "vouch" | "author" | "type" */
  kind: string;
  timestamp: number;
}

export interface LinkEntry {
  link_id: number;
  origin: number;
  /** FR-71: null while the link is open-ended (no RightEnd yet). */
  destination: number | null;
  /** FR-71: true while open — render the distinct not-yet-connected
   *  state (dashed marker, invitation), never a broken link. */
  is_open?: boolean;
  origin_ref: HyperRefPayload | null;
  destination_ref: HyperRefPayload | null;
  // Ghost metadata (server-side archive state + title + owner per endpoint).
  origin_archived?: boolean;
  origin_title?: string | null;
  origin_owner?: number | null;
  destination_archived?: boolean;
  destination_title?: string | null;
  destination_owner?: number | null;
  // Who created this connection (the asserter). None = legacy link
  // created before authorship stamping.
  author_club?: number | null;
  author_name?: string | null;
  /** FR-85 Phase 3: the link this link responds to — exact
   *  argument-chain semantics. Absent on legacy links (heuristic
   *  fallback applies). */
  responds_to?: number | null;
  /** Reputation surfacing (Miller 1994): named endorsers ride on the
   *  link row — names first, counts secondary (sybils can mint
   *  identities but can't become someone the viewer already trusts). */
  endorsements?: LinkEndorser[];
  /** Gold trust chain: 1 = author only; 2+ = third-party vouches. */
  endorsement_count?: number;
  /** True when endorsements have been withdrawn (contested). */
  link_contested?: boolean;
  link_types?: number[];
  // FR-40: named ends beyond the two-ended fast path.
  named_ends?: [string, HyperRefPayload][];
  /** Server-derived navigation view (link_list_for_work only): the
   * far main end's work + span from THIS work's perspective, as one
   * unit. Absent when no complete target exists (open links,
   * spanless refs, perspectives without a far end — link_get/link_query
   * never carry it). Clients should prefer this over assembling the
   * pair from separate refs. */
  jump_target?: { work_id: number; start: number; end: number } | null;
  // FR-40 S6: complete attachment lists for any end with more than
  // one attachment (server end names: LeftEnd/RightEnd + custom).
  end_sets?: [string, HyperRefPayload[]][];
  // FR-40: derived type ends — one per registered type with a
  // definition work (Green's three-set, materialized on read).
  type_ends?: [number, number][];
  // FR-40: home document; absent = server-global.
  home_document?: number | null;
  home_archived?: boolean;
  // FR-40: cross-server notify outcome, when one was attempted.
  cross_server_notify_accepted?: boolean | null;
  cross_server_notify_error?: string | null;
}

export interface ProvenanceHop {
  source_work_id: number;
  link_id: number;
  source_work_title?: string | null;
  source_author_name?: string | null;
  dest_work_id?: number;
}

export interface CompoundSpanPayload {
  source_work_id: number;
  char_start: number;
  char_end: number;
}

export interface SpanRangePayload {
  source_work_id: number;
  char_start: number;
  char_end: number;
  flat_start: number;
  flat_end: number;
  content_len: number;
  otree_position?: number;
  resolved_content?: string;
  placed_at?: number;
  placed_by?: number | null;
  source_changed?: boolean;
}

export type RangeElementPayload =
  | { type: "text"; text: string }
  | { type: "transclusion"; transclusion_source: number; transclusion_start: number; transclusion_end: number }
  | { type: "virtual"; virtual_source: number; virtual_revision: number; transclusion_start: number; transclusion_end: number }
  | { type: "blob"; blob_hash: string; blob_mime: string; blob_size: number; blob_width?: number; blob_height?: number; blob_caption?: string };

export interface RevisionHunkPayload {
  start: number;
  end: number;
  text: string;
  author_pk_hex: string;
  timestamp: number;
}

export interface RevisionComparePayload {
  inserted: RevisionHunkPayload[];
  deleted: RevisionHunkPayload[];
  unchanged_ratio: number;
  source: string;
}

export interface SuggestionCardPayload {
  work_id: number;
  title: string;
  snippet: string;
  windows: number;
  span_start: number;
  span_end: number;
}

export interface AuthorContribution {
  club_id: number;
  display_name: string;
  char_count: number;
  percentage: number;
  author_type: string | null;
}

export interface ReusedInDoc {
  work_id: number;
  title: string;
  shared_char_count: number;
}

export interface WorkSummary {
  unique_sources: number;
  unique_authors: number;
  version_count: number;
  char_count: number;
  author_contributions: AuthorContribution[];
  reused_in_count: number;
  reused_in_docs: ReusedInDoc[];
}

// Version-timeline entries (workVersionTimeline API). Named distinctly
// from RevisionMeta (workRevisionsList) — the two shapes have different
// id fields (revision vs revision_id); a duplicate "RevisionMeta" name
// made TypeScript merge them silently, which caused unkeyed <option>
// lists (key={r.revision} on revision_id data = undefined).
export interface VersionTimelineEntry {
  revision: number;
  char_count: number;
  author_club_id: number | null;
  author_display_name: string | null;
  author_type: string | null;
  timestamp?: number;
  content_crum?: string;
}

export interface WorkVersionTimeline {
  revisions: VersionTimelineEntry[];
}

export interface CompositionLayer {
  revision: number;
  author_club_id: number | null;
  author_display_name: string | null;
  text: string;
  operation: string;
}

export interface PassageComposition {
  layers: CompositionLayer[];
}

export interface CrossServerRefPayload {
  tumbler: string;
  origin_server_id?: number;
  origin_server_address?: string | null;
  content_hash: string;
  mime_type?: string;
  byte_size?: number;
  origin_author: string;
  origin_author_key: string;
  origin_server_sig?: string;
  fetched_at?: number;
  excerpt?: string;
}

export interface HyperRefPayload {
  kind: string;
  work_context: number | null;
  original_context: number | null;
  excerpt: string | null;
  provenance_chain?: ProvenanceHop[];
  start_position?: number | null;
  end_position?: number | null;
  // FR-40 S7: the targeted link id when kind == "link_attachment".
  link_attachment?: number | null;
  cross_server_ref?: CrossServerRefPayload | null;
  // Phase D (tumbler link targets): the end's permanent address in
  // wire format, stamped at creation.
  origin_tumbler?: string | null;
}

export interface SharedRegion {
  work_a: number;
  start_a: number;
  end_a: number;
  work_b: number;
  start_b: number;
  end_b: number;
  text: string;
}

export interface WorkDiffResult {
  shared: Array<{
    start_a: number;
    end_a: number;
    start_b: number;
    end_b: number;
    text: string;
  }>;
  changed_a: [number, number][];
  changed_b: [number, number][];
  text_len_a: number;
  text_len_b: number;
  coverage: number;
}

export interface BacklinkEntry {
  source_work_id: number;
  link_id: number;
  link_type: string;
  excerpt?: string;
  title?: string;
  source_archived?: boolean;
}

export interface LinkTypeInfo {
  type_id: number;
  name: string;
  // FR-39: the definition work for this type, if registered.
  definition_work?: number | null;
}

export interface LinkEndpointSpec {
  work_ids?: number[];
  author?: number | null;
}

export interface LinkQuerySpec {
  from_spec?: LinkEndpointSpec;
  to_spec?: LinkEndpointSpec;
  type_ids?: number[];
  home_spec?: LinkEndpointSpec;
}

export interface AgainHop {
  work_id: number;
  work_title: string;
  element_text: string;
  author_name: string;
  author_type: string;
  is_original: boolean;
}

export interface CrossServerBacklinkPayload {
  target_work_id: number;
  origin_server_address: string;
  origin_server_name: string;
  origin_work_id: string;
  origin_work_title: string;
  excerpt: string;
  link_type: string;
  received_at: number;
}

export interface AnnotationEntry {
  annotation_id: number;
  kind: string;
  payload: string;
  char_start: number;
  char_end: number;
  created_by: number | null;
  created_by_name: string | null;
  created_at?: number;
  is_private?: boolean;
}

export interface TransclusionMarker {
  start: number;
  end: number;
  linkId: number;
  direction: "outgoing" | "incoming";
  otherWorkId: number;
  otherWorkTitle: string;
  color: string;
  excerpt?: string;
  provenanceChain?: ProvenanceHop[];
  linkTypeId?: number;
  otherWorkIsArchived?: boolean;
  otherWorkOwner?: number | null;
  /** Who asserted this connection (the link creator's display
   * name) — None on legacy links created before authorship
   * stamping. Attribution matters most where multiple parties
   * contend on one passage. */
  linkAuthorName?: string | null;
  linkAuthorClub?: number | null;
  crossServerRef?: { tumbler: string; contentHash: string } | null;
  /** Navigation target as ONE unit: the span lives IN target.workId.
   * Built from the server's jump_target view when present (the far
   * main end's work + span, paired server-side), else from the
   * matching ref. Structural on purpose: work and span travel
   * together or not at all — the Room-6 bug class (work id from one
   * end, span from another) cannot be constructed. */
  target?: { workId: number; span: { start: number; end: number } };
  /** FR-40 S6/L1 (B.1): when this marker is one member of a
   * gathered end-set, its 1-based position and the end's total —
   * "passage i of N". Present only for gathered members. */
  endSetIndex?: number;
  endSetTotal?: number;
  /** FR-40 L4: the link's descriptor end excerpt (winfe's
   * FELink:Descriptor pattern) — the human-readable label, used
   * when no link-description annotation exists. */
  descriptorExcerpt?: string;
  /** Links sharing this exact span — the ×N chip above the margin
   * bar; set on the hover clone so the tooltip can explain it. */
  sameSpanCount?: number;
  /** FR-40: how many ends the link has (3+ = multi-ended; the
   * in-document view only shows the LOCAL end — this count tells
   * the reader the connection reaches further). */
  totalEnds?: number;
  /** FR-40 seat letters: which END of the link this marker is
   * ("A", "B", ... — the committee-seat identity, stable across
   * tooltip, panel, and compare; derived from linkEnds order). */
  endLabel?: string;
  /** The other seats' document titles, for the tooltip. */
  otherEndTitles?: string[];
}

// ── FR-80: detectors (persistent watches on works) ────────────────
export interface DetectorHit {
  at: number;
  link_id?: number;
  by_club?: number;
  revision?: number;
}

export interface GlobalSearchMatch {
  char_offset: number;
  line: number;
  context: string;
}

export interface GlobalSearchResult {
  work_id: number;
  title?: string | null;
  owner?: number | null;
  revision_count?: number;
  matches: GlobalSearchMatch[];
}

export interface DetectorMatch {
  /** A SET of link type ids — empty/absent = all types. */
  link_types?: number[];
  direction?: "in" | "out" | "any";
  from_clubs?: number[];
}

export interface DetectorInfo {
  detector_id: number;
  work_id: number;
  kind: "links" | "revisions";
  match?: DetectorMatch;
  created_at: number;
  hits: DetectorHit[];
  unread: number;
}

export interface WorkListEntry {  work_id: number;
  owner: number | null;
  revision_count: number;
  is_grabbed: boolean;
  char_count?: number;
  title: string;
  read_club: number | null;
  is_source?: boolean;
  kind?: WorkKind;
  content_start_line?: number;
  content_end_line?: number;
  source_author_id?: number;
  source_edition_info?: string;
  is_starred?: boolean;
  updated_at?: number;
  content_crum?: string;
  /** Abstract rung: first ~140 chars, whitespace-collapsed. */
  preview?: string;
}

export type WorkKind = "document" | "note" | "person" | "concept" | "collection" | "commentary" | "book" | "web-shadow";

/** FR-86: one LLM-proposed connection. Proposals are NOT links —
 * the human confirms, edits, or rejects; confirmed proposals become
 * ordinary links via link_create. */
export interface LlmConnectionProposal {
  /** Passage text, verbatim from the work under review. */
  excerpt: string;
  /** Span in the work text (server-resolved; re-anchored client-side on confirm). */
  start: number;
  end: number;
  /** Link type (1=Comment, 2=Reference, 3=Disagreement, 4=Quotation, 5=See Also). */
  type_id: number;
  /** The model's stated reason — shown on the card. */
  reasoning: string;
  /** Target work title, or null for same-document. */
  far_end_title: string | null;
}

export interface LlmProposalResult {
  proposals: LlmConnectionProposal[];
  model: string;
  backend: string;
}

export type SaveState = "idle" | "saving" | "saved" | "error";

export type License = "all-rights-reserved" | "transcopyright" | "cc-by" | "cc-by-sa" | "public-domain";

export const LICENSES: { value: License; label: string; short: string; url: string | null }[] = [
  { value: "all-rights-reserved", label: "All Rights Reserved", short: "\u00A9", url: null },
  { value: "transcopyright", label: "Transcopyright", short: "TCo", url: "https://xanadu.com/xuTco.html" },
  { value: "cc-by", label: "CC-BY (Attribution)", short: "CC-BY", url: "https://creativecommons.org/licenses/by/4.0/" },
  { value: "cc-by-sa", label: "CC-BY-SA (Share-Alike)", short: "CC-BY-SA", url: "https://creativecommons.org/licenses/by-sa/4.0/" },
  { value: "public-domain", label: "Public Domain (CC0)", short: "CC0", url: "https://creativecommons.org/publicdomain/zero/1.0/" },
];

export interface RevisionMeta {
  revision_id: number;
  parent?: number;
  created_at: number;
  created_by?: number;
  description?: string;
  is_notable: boolean;
  char_count: number;
  change_summary?: string;
}

export interface BlobMeta {
  content_hash: number[] | number;
  byte_size: number;
  mime_type: string;
  preview_hash?: number[] | number | null;
  width?: number | null;
  height?: number | null;
}

export interface BlobEntry {
  char_position: number;
  content_hash: string;
  mime_type: string;
  byte_size: number;
  width?: number | null;
  height?: number | null;
  caption?: string | null;
}

export function blobHashToU64(hash: number[] | number): number {
  if (typeof hash === "number") return hash;
  if (Array.isArray(hash) && hash.length >= 8) {
    let result = 0;
    for (let i = 0; i < 8; i++) {
      result = result * 256 + (hash[i] || 0);
    }
    return result;
  }
  return 0;
}

export interface GraphNode {
  work_id: number;
  title: string;
  is_starred: boolean;
  is_source: boolean;
  revision_count: number;
  author_type?: string;
  kind?: WorkKind;
  license?: License;
}

export interface GraphEdge {
  source: number;
  target: number;
  edge_type: string;
  weight: number;
}

export interface WorkGraphPayload {
  nodes: GraphNode[];
  edges: GraphEdge[];
}

export interface TrailStop {
  work_id: number;
  char_start?: number;
  char_end?: number;
  note?: string;
  title: string;
  server_domain?: string;
}

export interface TrailPayload {
  trail_id: number;
  name: string;
  introduction?: string;
  categories?: string[];
  published?: boolean;
  owner_club: number;
  stops: TrailStop[];
  created_at: number;
  updated_at: number;
}

export interface ChangeHighlight {
  start: number;
  end: number;
  timestamp: number;
  author: string;
}

export function extractValue(resp: unknown): unknown {
  const r = resp as Record<string, unknown>;
  if (r && typeof r === "object" && "type" in r && "value" in r) {
    return r.value;
  }
  return resp;
}
