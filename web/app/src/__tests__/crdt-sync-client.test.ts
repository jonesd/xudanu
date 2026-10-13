import { describe, it, expect, beforeEach } from "vitest";
import { CrdtSyncClient, LICENSES } from "../api/crdt_sync";
import type { WorkListEntry } from "../api/crdt_sync";

/**
 * coverage-plan-web.md Phase 1: the wire client. House pattern from
 * link-fr40-client.test.ts — override sendRequest so REAL method
 * bodies run; assert the op, the payload shape, and the response
 * extraction (unwrap + fallbacks) per method.
 */
function mkClient(responses: Record<string, unknown> = {}) {
  const client = new CrdtSyncClient("ws://test", 0x10);
  const requests: Array<{ op: string; payload: unknown }> = [];
  client.sendRequest = async (op: string, payload: unknown) => {
    requests.push({ op, payload });
    if (op in responses) {
      const r = responses[op];
      if (r && typeof r === "object" && "type" in (r as object)) return r;
      return { type: "response", value: r };
    }
    return { type: "response", value: null };
  };
  return { client, requests };
}

function lastReq(h: { requests: Array<{ op: string; payload: unknown }> }) {
  return h.requests[h.requests.length - 1];
}

describe("CrdtSyncClient — document & revision ops", () => {
  let h: ReturnType<typeof mkClient>;
  beforeEach(() => {
    h = mkClient();
  });

  it("workSetTitle / workSetText payloads", async () => {
    await h.client.workSetTitle(0x20, "New Title");
    expect(lastReq(h)).toEqual({ op: "work_set_title", payload: { work_id: 0x20, title: "New Title" } });
    await h.client.workSetText(0x20, "body");
    expect(lastReq(h).payload).toEqual({ work_id: 0x20, text: "body" });
  });

  it("fetchRevision uses number key and unwraps text shapes", async () => {
    const h2 = mkClient({ work_fetch_revision: "old text" });
    expect(await h2.client.fetchRevision(0x20, 3)).toBe("old text");
    expect(lastReq(h2).payload).toEqual({ work_id: 0x20, number: 3 });
    const h3 = mkClient({ work_fetch_revision: { text: "wrapped" } });
    expect(await h3.client.fetchRevision(0x20, 1)).toBe("wrapped");
    const h4 = mkClient({ work_fetch_revision: { nope: 1 } });
    expect(await h4.client.fetchRevision(0x20, 1)).toBe("");
  });

  it("revisionCount via work_revision_count", async () => {
    const h2 = mkClient({ work_revision_count: 7 });
    expect(await h2.client.revisionCount(0x20)).toBe(7);
    const h3 = mkClient({ work_revision_count: null });
    expect(await h3.client.revisionCount(0x20)).toBe(0);
  });

  it("revision metadata ops", async () => {
    await h.client.workTextAtRevision(0x20, 4);
    expect(lastReq(h).payload).toEqual({ work_id: 0x20, revision_id: 4 });
    const h2 = mkClient({ work_text_at_revision: "at rev" });
    expect(await h2.client.workTextAtRevision(0x20, 4)).toBe("at rev");
    await h.client.workRevisionDescribe(0x20, 2, "cleanup");
    expect(lastReq(h).payload).toEqual({ work_id: 0x20, revision_id: 2, description: "cleanup" });
    await h.client.workRevisionMarkNotable(0x20, 2, true);
    expect(lastReq(h).payload).toEqual({ work_id: 0x20, revision_id: 2, notable: true });
    const h3 = mkClient({ work_revision_rollback: 0x31 });
    expect(await h3.client.workRevisionRollback(0x20, 2)).toBe(0x31);
  });

  it("archive lifecycle", async () => {
    await h.client.workArchive(0x20);
    expect(lastReq(h).op).toBe("work_archive");
    await h.client.workUnarchive(0x20);
    expect(lastReq(h).op).toBe("work_unarchive");
    const h2 = mkClient({ work_list_archived: [{ work_id: 0x20 }] });
    expect(await h2.client.listArchivedWorks()).toEqual([{ work_id: 0x20 }]);
  });

  it("publish / unpublish / isPublished", async () => {
    await h.client.workPublish(0x20);
    expect(lastReq(h).op).toBe("work_publish");
    await h.client.workUnpublish(0x20);
    expect(lastReq(h).op).toBe("work_unpublish");
    const h2 = mkClient({ work_is_published: true });
    expect(await h2.client.workIsPublished(0x20)).toBe(true);
  });

  it("star / unstar / isStarred", async () => {
    await h.client.workStar(0x20);
    expect(lastReq(h).op).toBe("work_star");
    await h.client.workUnstar(0x20);
    expect(lastReq(h).op).toBe("work_unstar");
    const h2 = mkClient({ work_is_starred: true });
    expect(await h2.client.workIsStarred(0x20)).toBe(true);
  });

  it("duplicateWork unwraps nested number and {work_id} shapes", async () => {
    const h2 = mkClient({ work_duplicate: 0x50 });
    expect(await h2.client.duplicateWork(0x20)).toBe(0x50);
    const h3 = mkClient({ work_duplicate: { type: "response", value: { work_id: 0x51 } } });
    expect(await h3.client.duplicateWork(0x20)).toBe(0x51);
  });

  it("edit club set and get", async () => {
    await h.client.workSetEditClub(0x20, 0x99);
    expect(lastReq(h).payload).toEqual({ work_id: 0x20, club_id: 0x99 });
    const h2 = mkClient({ work_edit_club: 0x99 });
    expect(await h2.client.workEditClub(0x20)).toBe(0x99);
  });
});

describe("CrdtSyncClient — kind & license", () => {
  it("workKindGet maps numeric kinds and falls back to document", async () => {
    const h = mkClient({ work_kind_get: 2 });
    expect(await h.client.workKindGet(1)).toBe("person");
    const h2 = mkClient({ work_kind_get: 99 });
    expect(await h2.client.workKindGet(1)).toBe("document");
  });

  it("kind/license set + license index mapping", async () => {
    const h = mkClient({ work_license_get: 3 });
    await h.client.workKindSet(1, "note");
    expect(lastReq(h).payload).toEqual({ work_id: 1, kind: "note" });
    expect(await h.client.workLicenseGet(1)).toBe(LICENSES[3].value);
    const h2 = mkClient({ work_license_get: "junk" });
    expect(await h2.client.workLicenseGet(1)).toBe("all-rights-reserved");
    await h.client.workLicenseSet(1, "cc-by");
    expect(lastReq(h).payload).toEqual({ work_id: 1, license: "cc-by" });
  });
});

describe("CrdtSyncClient — search, outline, LLM", () => {
  it("workOutline unwraps {entries}", async () => {
    const outline = [{ level: 1, text: "H", line: 0, char_offset: 0 }];
    const h = mkClient({ work_outline: { entries: outline } });
    expect(await h.client.workOutline(0x20)).toEqual(outline);
  });

  it("workSearch maps snake_case and defaults max_results to null", async () => {
    const h = mkClient({ work_search: { matches: [], total_matches: 2 } });
    const res = await h.client.workSearch(0x20, "q");
    expect(res).toEqual({ matches: [], totalMatches: 2 });
    expect(lastReq(h).payload).toEqual({ work_id: 0x20, query: "q", max_results: null });
    await h.client.workSearch(0x20, "q", 10);
    expect(lastReq(h).payload).toEqual({ work_id: 0x20, query: "q", max_results: 10 });
  });

  it("globalTextSearch and federatedSearch unwrap records", async () => {
    const h = mkClient({
      global_text_search: { results: [], totalWorksMatched: 0 },
      federated_search: { results: [{ work_id: 1, local: true }] },
    });
    expect((await h.client.globalTextSearch("q", 5)).totalWorksMatched).toBe(0);
    expect(lastReq(h).payload).toEqual({ query: "q", max_results: 5 });
    expect((await h.client.federatedSearch("q")).length).toBe(1);
    expect(lastReq(h).payload).toEqual({ query: "q" });
  });

  it("workGoto sends context_lines and maps char_offset", async () => {
    const h = mkClient({
      work_goto: { line: 2, char_offset: 10, context: "ctx", context_start_line: 1 },
    });
    expect((await h.client.workGoto(1, 2)).charOffset).toBe(10);
    expect(lastReq(h).payload).toEqual({ work_id: 1, line: 2, char: null, context_lines: 10 });
  });

  it("textRange maps to camelCase", async () => {
    const h = mkClient({
      work_text_range: { text: "sliced", total_chars: 40, start_char: 0, end_char: 5 },
    });
    expect(await h.client.textRange(1, 0, 5)).toEqual({ text: "sliced", totalChars: 40, startChar: 0, endChar: 5 });
    expect(lastReq(h).payload).toEqual({ work_id: 1, start_char: 0, end_char: 5 });
  });

  it("diffNarration / writingFeedback / suggestTitle map fields", async () => {
    const h = mkClient({
      work_diff_narration: { narration: "n", llm_model: "m", updated_text: "u" },
      work_writing_feedback: { feedback: "f", llm_model: "m" },
      work_suggest_title: "A Title",
    });
    expect(await h.client.diffNarration(1)).toEqual({ text: "n", model: "m", updatedText: "u" });
    expect(await h.client.writingFeedback(1)).toEqual({ text: "f", model: "m" });
    expect(await h.client.suggestTitle(1)).toBe("A Title");
  });

  it("workAutoTag parses the JSON string payload; llmUsage reads server_stats", async () => {
    const tags = { new: [{ name: "x", id: 1 }], linked: [] };
    const h = mkClient({ work_auto_tag: JSON.stringify(tags), server_stats: null });
    expect(await h.client.workAutoTag(1)).toEqual(tags);
    expect(await h.client.llmUsage()).toBeNull();
  });
});

describe("CrdtSyncClient — attribution & historical authors", () => {
  const span = {
    start: 0, end: 4, author_club_id: 1, author_display_name: "a",
    transcluded_by_club_id: null, transcluded_by_display_name: null, is_transclusion: false,
  };

  it("attributionQuery sends explicit null span and unwraps {spans}", async () => {
    const h = mkClient({
      attribution_query: { spans: [span] },
      attribution_query_resolved: { spans: [span] },
      attribution_log_status: { entry_count: 0, chain_valid: true, last_sequence: 0, has_log: false },
    });
    expect(await h.client.attributionQuery(1)).toEqual([span]);
    expect(lastReq(h).payload).toEqual({ work_id: 1, start: null, end: null });
    expect(await h.client.attributionQueryResolved(1)).toEqual([span]);
    expect((await h.client.attributionLogStatus()).chain_valid).toBe(true);
  });

  it("historical author register / get / search / list", async () => {
    const author = { id: 5, name: "Mark", bio: null, aliases: [], is_alias: false };
    const h = mkClient({
      historical_author_register: author,
      historical_author_get: author,
      historical_author_search: { authors: [author] },
      historical_author_list: { authors: [author] },
    });
    expect(await h.client.registerHistoricalAuthor("Mark", "M. Twain", 1835, 1910, {}, "ref")).toEqual(author);
    expect(lastReq(h).payload).toEqual({
      name: "Mark", display_name: "M. Twain", birth_year: 1835, death_year: 1910,
      external_ids: {}, source_bibliography: "ref",
    });
    expect(await h.client.getHistoricalAuthor(5)).toEqual(author);
    expect(await h.client.searchHistoricalAuthors("Mar")).toEqual([author]);
    expect(await h.client.listHistoricalAuthors()).toEqual([author]);
  });
});

describe("CrdtSyncClient — link ops beyond FR-40", () => {
  it("linkCreate sends both refs with span payloads", async () => {
    const h = mkClient({ link_create: 0x77 });
    const id = await h.client.linkCreate(
      0x10, 0x20,
      { excerpt: "origin passage", start: 0, end: 15 },
      { excerpt: "target passage", start: 2, end: 17 },
    );
    expect(id).toBe(0x77);
    expect(lastReq(h).payload).toMatchObject({
      origin: 0x10,
      destination: 0x20,
      origin_ref: { excerpt: "origin passage", start_position: 0, end_position: 15 },
      destination_ref: { excerpt: "target passage", start_position: 2, end_position: 17 },
    });
  });

  it("linkGet / linkDelete / linkSetTypes / linkSetRespondsTo", async () => {
    const link = { link_id: 5, origin: 1, destination: 2 };
    const h = mkClient({ link_get: link });
    expect(await h.client.linkGet(5)).toEqual(link);
    await h.client.linkDelete(5);
    expect(lastReq(h).payload).toEqual({ link_id: 5 });
    await h.client.linkSetTypes(5, [3]);
    expect(lastReq(h).payload).toEqual({ link_id: 5, link_types: [3] });
    await h.client.linkSetRespondsTo(5, 9);
    expect(lastReq(h).payload).toEqual({ link_id: 5, responds_to: 9 });
    await h.client.linkSetRespondsTo(5, null);
    expect(lastReq(h).payload).toEqual({ link_id: 5, responds_to: null });
  });

  it("linkListForWork falls back across response shapes", async () => {
    const entries = [{ link_id: 1, origin: 1, destination: 2 }];
    for (const shape of [entries, { entries }, { links: entries }]) {
      const h = mkClient({ link_list_for_work: shape });
      expect(await h.client.linkListForWork(1)).toEqual(entries);
    }
  });

  it("registerLinkType and linkTypeList", async () => {
    const h = mkClient({ link_type_list: [{ type_id: 9, name: "Gathers" }] });
    await h.client.registerLinkType(9, "Gathers", 0x50);
    expect(lastReq(h).payload).toEqual({ type_id: 9, name: "Gathers", definition_work: 0x50 });
    expect(await h.client.linkTypeList()).toEqual([{ type_id: 9, name: "Gathers" }]);
  });

  it("version lineage: is_before / trace position / ancestry", async () => {
    const h = mkClient({
      version_is_before: { is_before: true },
      version_trace_position: { trace_position: { branch_id: 1, position: 2 } },
      provenance_ancestry: { chain: [] },
    });
    expect(await h.client.versionIsBefore(1, 2)).toBe(true);
    expect(await h.client.versionTracePosition(1)).toEqual({ branchId: 1, position: 2 });
    const hNull = mkClient({ version_trace_position: {} });
    expect(await hNull.client.versionTracePosition(1)).toBeNull();
    expect(await h.client.provenanceAncestry(1)).toEqual([]);
  });

  it("shared regions and diff regions", async () => {
    const shared = [{ start_a: 0, end_a: 3, start_b: 1, end_b: 4, match_len: 3, match_text: "abc" }];
    const h = mkClient({ find_shared_regions: shared, work_diff_regions: null });
    expect(await h.client.findSharedRegions(1, 2)).toEqual(shared);
    expect(lastReq(h).payload).toEqual({ work_a: 1, work_b: 2 });
    expect(await h.client.workDiffRegions(1, 2)).toBeNull();
  });

  it("findExcerptPositions returns arrays only", async () => {
    const h = mkClient({ find_excerpt_positions: [{ start: 0, end: 3 }] });
    expect(await h.client.findExcerptPositions(1, "abc")).toEqual([{ start: 0, end: 3 }]);
    const h2 = mkClient({ find_excerpt_positions: { nope: true } });
    expect(await h2.client.findExcerptPositions(1, "abc")).toEqual([]);
  });
});

describe("CrdtSyncClient — source & reuse", () => {
  it("importSourceWork maps the six-arg payload and response", async () => {
    const h = mkClient({
      import_source_work: { work_id: 0x40, author_id: 2, title: "T", text_length: 9 },
    });
    const res = await h.client.importSourceWork(2, "T", "body text", "ed", 1, 2);
    expect(res).toEqual({ workId: 0x40, authorId: 2, title: "T", textLength: 9 });
    expect(lastReq(h).payload).toEqual({
      author_id: 2, title: "T", text: "body text",
      edition_info: "ed", skip_prefix_lines: 1, skip_suffix_lines: 2,
    });
  });

  it("detectSource and matchContent pass through", async () => {
    const h = mkClient({
      source_detect: { matched: false },
      content_match: { matched: true, work_id: 3, score: 0.9 },
    });
    expect(await h.client.detectSource("some text")).toEqual({ matched: false });
    expect(await h.client.matchContent("some text")).toEqual({ matched: true, work_id: 3, score: 0.9 });
  });

  it("applySourceAttribution includes optional span fields only when given", async () => {
    const h = mkClient({ source_pattern_list: { patterns: [{ id: 1 }] } });
    await h.client.applySourceAttribution(1, 5);
    expect(lastReq(h).payload).toEqual({ work_id: 1, historical_author_id: 5 });
    await h.client.applySourceAttribution(1, 5, 9, 3, 7);
    expect(lastReq(h).payload).toEqual({
      work_id: 1, historical_author_id: 5, source_work_id: 9, paste_start: 3, paste_end: 7,
    });
    await h.client.applyTransclusionAttribution(7);
    expect(lastReq(h).payload).toEqual({ link_id: 7 });
    expect(await h.client.listSourcePatterns()).toEqual([{ id: 1 }]);
  });
});

describe("CrdtSyncClient — compounds, elements, merges", () => {
  it("resolveInlineTransclusions maps snake_case fields", async () => {
    const h = mkClient({
      resolve_inline_transclusions: { text: "resolved", span_ranges: [], source_titles: { 3: "S" } },
    });
    expect(await h.client.resolveInlineTransclusions(1)).toEqual({
      text: "resolved", spanRanges: [], sourceTitles: { 3: "S" },
    });
  });

  it("elementInsert / elementUpdate read {revision}; remove reads {removed}", async () => {
    const h = mkClient({ element_insert: { revision: 4 }, element_update: { revision: 5 } });
    expect(await h.client.elementInsert(1, 3, { kind: "text", text: "x" })).toBe(4);
    expect(await h.client.elementUpdate(1, 3, { kind: "text", text: "y" })).toBe(5);
    const h2 = mkClient({ element_remove_transclusion: { removed: true } });
    expect(await h2.client.elementRemoveTransclusion(1, 2, 3, 4)).toBe(true);
    expect(lastReq(h2).payload).toEqual({ work_id: 1, source_work_id: 2, char_start: 3, char_end: 4 });
  });

  it("revisionCompare and suggestions", async () => {
    const cmp = { regions: [], a_len: 0, b_len: 0 };
    const h = mkClient({ revision_compare: cmp, suggestion_query: [] });
    expect(await h.client.revisionCompare(1, 1, 2)).toEqual(cmp);
    expect(lastReq(h).payload).toEqual({ work_id: 1, rev_a: 1, rev_b: 2 });
    expect(await h.client.suggestionQuery(1, "text")).toEqual([]);
    await h.client.suggestionConfigSet(true);
    expect(lastReq(h).payload).toEqual({ enabled: true });
  });
});

describe("CrdtSyncClient — work lists & graph", () => {
  it("fetchWorkList unwraps arrays, entries, work_list, and value shapes", async () => {
    const works = [{ work_id: 0x10, title: "Open Work" }] as unknown as WorkListEntry[];
    for (const shape of [works, { work_list: works }, { entries: works }, { value: works }]) {
      const h = mkClient({ work_list: shape });
      expect(await h.client.fetchWorkList()).toEqual(works);
      expect(lastReq(h).payload).toEqual({ limit: 1000 });
    }
  });

  it("workGraph omits empty params", async () => {
    const graph = { nodes: [], links: [] };
    const h = mkClient({ work_graph: graph });
    expect(await h.client.workGraph()).toEqual(graph);
    expect(lastReq(h).payload).toBeUndefined();
    await h.client.workGraph(5, 10);
    expect(lastReq(h).payload).toEqual({ center_work_id: 5, max_nodes: 10 });
  });

  it("fetchWorksByAuthor accepts arrays and {work_list}", async () => {
    const h = mkClient({ work_list_by_author: [] });
    expect(await h.client.fetchWorksByAuthor(3)).toEqual([]);
    const h2 = mkClient({ work_list_by_author: { work_list: [] } });
    expect(await h2.client.fetchWorksByAuthor(3)).toEqual([]);
    await h.client.workSetSource(1, true);
    expect(lastReq(h).payload).toEqual({ work_id: 1, is_source: true });
  });
});

describe("CrdtSyncClient — trails", () => {
  it("trailCreate includes only provided optional fields", async () => {
    const h = mkClient({ trail_create: 0x60 });
    expect(await h.client.trailCreate("Tour")).toBe(0x60);
    expect(lastReq(h).payload).toEqual({ name: "Tour" });
    await h.client.trailCreate("Tour", "intro", ["a"]);
    expect(lastReq(h).payload).toEqual({ name: "Tour", introduction: "intro", categories: ["a"] });
  });

  it("trail mutation ops send their payloads", async () => {
    const h = mkClient();
    await h.client.trailDelete(1);
    expect(lastReq(h).payload).toEqual({ trail_id: 1 });
    await h.client.trailRename(1, "n");
    expect(lastReq(h).payload).toEqual({ trail_id: 1, name: "n" });
    await h.client.trailUpdate(1, "intro", ["c"]);
    expect(lastReq(h).payload).toEqual({ trail_id: 1, introduction: "intro", categories: ["c"] });
    await h.client.trailPublish(1);
    expect(lastReq(h).op).toBe("trail_publish");
    await h.client.trailUnpublish(1);
    expect(lastReq(h).op).toBe("trail_unpublish");
  });

  it("trail stop ops: add (optional span/note/domain), remove, reorder", async () => {
    const h = mkClient();
    await h.client.trailAddStop(1, 2);
    expect(lastReq(h).payload).toEqual({ trail_id: 1, work_id: 2 });
    await h.client.trailAddStop(1, 2, 3, 9, "note", "xudanu.com");
    expect(lastReq(h).payload).toEqual({
      trail_id: 1, work_id: 2, char_start: 3, char_end: 9, note: "note", server_domain: "xudanu.com",
    });
    await h.client.trailRemoveStop(1, 2);
    expect(lastReq(h).payload).toEqual({ trail_id: 1, stop_index: 2 });
    await h.client.trailReorderStops(1, [2, 0, 1]);
    expect(lastReq(h).payload).toEqual({ trail_id: 1, stop_order: [2, 0, 1] });
  });
});

describe("CrdtSyncClient — identity, session, endorsements, pins", () => {
  it("FR-87: work endorsement ops send (work_id, endorsements) pairs", async () => {
    const h = mkClient();
    await h.client.workEndorse(1, [[5, 1]]);
    expect(lastReq(h)).toEqual({ op: "work_endorse", payload: { work_id: 1, endorsements: [[5, 1]] } });
    await h.client.workRetractEndorsement(1, [[5, 1]]);
    expect(lastReq(h).op).toBe("work_retract");
    const h2 = mkClient({ work_endorsements: { endorsements: [[5, 1]] } });
    expect(await h2.client.workEndorsements(1)).toEqual([[5, 1]]);
  });

  it("connection pins set/unset/get", async () => {
    const h = mkClient();
    await h.client.connectionPinSet("link-1");
    expect(lastReq(h).payload).toEqual({ key: "link-1" });
    await h.client.connectionPinUnset("link-1");
    expect(lastReq(h).payload).toEqual({ key: "link-1" });
    const h2 = mkClient({ connection_pins_get: ["link-1"] });
    expect(await h2.client.connectionPinsGet()).toEqual(["link-1"]);
  });

  it("cross-server backlinks", async () => {
    const h2 = mkClient({ cross_server_backlinks_get: [] });
    expect(await h2.client.crossServerBacklinksGet(1)).toEqual([]);
  });

  it("provenance exports", async () => {
    const h2 = mkClient({
      attestation_report: { report_json: "REPORT" },
      prov_json_export: { prov_json: "{\"prov\":1}" },
    });
    expect(await h2.client.generateAttestationReport(1)).toBe("REPORT");
    expect(await h2.client.exportProvJson(1, true)).toBe("{\"prov\":1}");
    expect(lastReq(h2).payload).toEqual({ work_id: 1, include_federation: true });
  });

  it("local text buffer: getText/setText and subscription teardown", () => {
    const h2 = mkClient();
    h2.client.setText("hello");
    expect(h2.client.getText()).toBe("hello");
    let seen = "";
    const off = h2.client.onTextChange((t) => {
      seen = t;
    });
    h2.client.setText("world");
    expect(seen).toBe("world");
    off();
    h2.client.setText("again");
    expect(seen).toBe("world");
  });

  it("accessors before connect", () => {
    const h2 = mkClient();
    expect(h2.client.getSessionId()).toBeNull();
    expect(h2.client.isConnected()).toBe(false);
    expect(h2.client.getReconnectAttempt()).toBe(0);
    const off = h2.client.onConnectionChange(() => {});
    off();
  });
});
