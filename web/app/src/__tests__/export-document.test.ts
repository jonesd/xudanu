import { describe, it, expect } from "vitest";
import { buildExportHtml } from "../export-document";
import type { SpanRangePayload } from "../api/crdt_sync";

const META = {
  title: "Memorandum — Data Retention Obligations",
  serverDomain: "localhost",
  workId: 0x6e8,
  exportedAt: new Date("2026-10-18T12:00:00Z"),
};

const span = (over: Partial<SpanRangePayload>): SpanRangePayload =>
  ({
    flat_start: 0,
    flat_end: 0,
    source_work_id: 1,
    char_start: 0,
    char_end: 0,
    resolved_content: "",
    ...over,
  }) as SpanRangePayload;

describe("buildExportHtml", () => {
  it("renders a plain document: title header, paragraphs, no transclusion blocks", () => {
    const html = buildExportHtml(META, { text: "First paragraph.\n\nSecond paragraph.", spanRanges: [], sourceTitles: {} });
    expect(html).toContain("<h1>Memorandum — Data Retention Obligations</h1>");
    expect(html).toContain("<p>First paragraph.</p>");
    expect(html).toContain("<p>Second paragraph.</p>");
    expect(html).toContain("0 transcluded passages"); // footer counts zero honestly? singular/plural
    expect(html).not.toContain("<blockquote ");
  });

  it("renders a transclusion as a cited blockquote with source title and xan:// address", () => {
    const html = buildExportHtml(META, {
      text: "Intro text.\nQUOTE\nConclusion text.",
      spanRanges: [
        span({
          flat_start: 13,
          flat_end: 18,
          source_work_id: 0x6e5,
          char_start: 95,
          char_end: 180,
          resolved_content: "a controller shall erase all personal data",
        }),
      ],
      sourceTitles: { [0x6e5]: "State Privacy Act (Excerpts)" },
    });
    expect(html).toContain("<blockquote");
    expect(html).toContain("a controller shall erase all personal data");
    expect(html).toContain("State Privacy Act (Excerpts)");
    expect(html).toContain("xan://localhost.6e5.95.180");
    expect(html).toContain("<p>Intro text.</p>");
    expect(html).toContain("<p>Conclusion text.</p>");
    expect(html).toContain("1 transcluded passage from 1 source document");
  });

  it("interleaves multiple quotations from multiple sources in document order", () => {
    const html = buildExportHtml(META, {
      text: "AAAAQQQQBBBBRRRRCCCC",
      spanRanges: [
        // deliberately unsorted: RRRR first in array
        span({ flat_start: 12, flat_end: 16, source_work_id: 0x6e6, resolved_content: "precedent holding", char_start: 40, char_end: 58 }),
        span({ flat_start: 4, flat_end: 8, source_work_id: 0x6e5, resolved_content: "statute clause", char_start: 10, char_end: 23 }),
      ],
      sourceTitles: { [0x6e5]: "Statute", [0x6e6]: "Precedent" },
    });
    const q1 = html.indexOf("statute clause");
    const q2 = html.indexOf("precedent holding");
    expect(q1).toBeGreaterThan(-1);
    expect(q2).toBeGreaterThan(q1); // sorted by flat_start despite array order
    expect(html).toContain("<p>AAAA</p>");
    expect(html).toContain("<p>BBBB</p>");
    expect(html).toContain("<p>CCCC</p>");
    expect(html).toContain("2 transcluded passages from 2 source documents");
  });

  it("falls back to the flat text when a span has no resolved content", () => {
    const html = buildExportHtml(META, {
      text: "xxQUOTED_CONTENTyy",
      spanRanges: [span({ flat_start: 2, flat_end: 16, source_work_id: 7, resolved_content: "" })],
      sourceTitles: { 7: "Source" },
    });
    expect(html).toContain("QUOTED_CONTENT");
  });

  it("escapes HTML in titles, body text, and quoted content", () => {
    const html = buildExportHtml(
      { ...META, title: 'Brief <I>"Danger"</I>' },
      {
        text: "analysis with <script>alert(1)</script> and & symbols",
        spanRanges: [span({ flat_start: 0, flat_end: 0, source_work_id: 1, resolved_content: "<b>quoted</b>" })],
        sourceTitles: { 1: "S <script>" },
      },
    );
    expect(html).not.toContain("<script>alert(1)");
    expect(html).not.toContain("<b>quoted</b>");
    expect(html).toContain("&lt;script&gt;alert(1)");
    expect(html).toContain("&lt;b&gt;quoted&lt;/b&gt;");
  });

  it("carries the export date and document id in the header", () => {
    const html = buildExportHtml(META, { text: "x", spanRanges: [], sourceTitles: {} });
    expect(html).toContain("0x6e8");
    expect(html).toContain("2026-10-18");
    expect(html).toContain("exported");
  });
});
