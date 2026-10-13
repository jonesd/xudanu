import { describe, it, expect } from "vitest";
import type { SpanRangePayload } from "../api/crdt_sync";
import {
  getTextContent,
  getEditableText,
  isDecorativeNode,
  isReadonlyNode,
  validateSpanRanges,
  buildTransclusionDom,
  insertInlineImages,
} from "../components/editor-dom-utils";

function spanRange(start: number, end: number, source = 5): SpanRangePayload {
  return {
    source_work_id: source,
    char_start: start,
    char_end: end,
    flat_start: start,
    flat_end: end,
    resolved_content: "",
  } as unknown as SpanRangePayload;
}

function mount(html: string): HTMLElement {
  const el = document.createElement("div");
  el.innerHTML = html;
  document.body.appendChild(el);
  return el;
}

describe("editor-dom-utils — decorative/readonly classification", () => {
  it("inline transclusions and images are decorative and readonly", () => {
    const el = mount('<span class="inline-transclusion">x</span>');
    expect(isDecorativeNode(el.firstChild)).toBe(true);
    expect(isReadonlyNode(el.firstChild)).toBe(true);
    el.remove();

    const img = mount('<span class="inline-image-wrapper"></span>');
    expect(isDecorativeNode(img.firstChild)).toBe(true);
    expect(isReadonlyNode(img.firstChild)).toBe(true);
    img.remove();
  });

  it("contenteditable=false is decorative unless display:none (hidden markers)", () => {
    const el = mount('<span contenteditable="false">x</span>');
    expect(isDecorativeNode(el.firstChild)).toBe(true);
    el.remove();

    const hidden = mount('<span contenteditable="false" style="display:none">marker</span>');
    expect(isDecorativeNode(hidden.firstChild)).toBe(false);
    hidden.remove();
  });

  it("plain nodes are neither", () => {
    const el = mount("<b>bold</b>");
    expect(isDecorativeNode(el.firstChild)).toBe(false);
    expect(isReadonlyNode(el.firstChild)).toBe(false);
    el.remove();
  });
});

describe("editor-dom-utils — text extraction", () => {
  it("block elements prefix newlines (visited before their text); BR always breaks; ZWSP stripped", () => {
    // Shipped behavior: a block element adds its newline when the
    // ELEMENT node is walked (before its text), so it acts as a
    // leading separator between blocks, not a trailing one.
    const el = mount("<p>one</p><p>two</p>three<br/>four\u200B");
    expect(getTextContent(el)).toBe("one\ntwothree\nfour");
    el.remove();
  });

  it("getTextContent skips decorative nodes (inline transclusions)", () => {
    const el = mount('keep<span class="inline-transclusion" contenteditable="false">skip</span>tail');
    expect(getTextContent(el)).toBe("keeptail");
    el.remove();
  });

  it("getEditableText skips readonly spans (transclusions + images)", () => {
    const el = mount(
      'a<span class="inline-transclusion">x</span>b<span class="inline-image-wrapper"></span>c',
    );
    expect(getEditableText(el)).toBe("abc");
    el.remove();
  });
});

describe("editor-dom-utils — validateSpanRanges", () => {
  it("drops negative, overflowing, and empty spans", () => {
    const valid = validateSpanRanges(
      [spanRange(-1, 3), spanRange(2, 2), spanRange(4, 99), spanRange(2, 5)],
      10,
    );
    expect(valid).toHaveLength(1);
    expect(valid[0].flat_start).toBe(2);
  });
});

describe("editor-dom-utils — buildTransclusionDom", () => {
  it("empty text renders a lone <br>", () => {
    const el = document.createElement("div");
    buildTransclusionDom(el, "", []);
    expect(el.innerHTML).toBe("<br>");
  });

  it("plain text with no valid ranges (ZWSP guard on trailing newline)", () => {
    const el = document.createElement("div");
    buildTransclusionDom(el, "hello\n", [spanRange(0, 99)]);
    expect(el.textContent?.startsWith("hello")).toBe(true);
    expect(el.textContent?.endsWith("\u200B")).toBe(true);
  });

  it("wraps covered segments in inline-transclusion spans with titles", () => {
    const el = document.createElement("div");
    buildTransclusionDom(el, "abcdef", [spanRange(1, 4, 0x20)], { 0x20: "Source Doc" });
    const spans = el.querySelectorAll("span.inline-transclusion");
    expect(spans).toHaveLength(1);
    expect(spans[0].textContent).toBe("bcd");
    expect(spans[0].getAttribute("contenteditable")).toBe("false");
    expect(spans[0].title).toContain("Source Doc");
    expect((spans[0] as HTMLElement).dataset.sourceWorkId).toBe(String(0x20));
    // Uncovered text stays as plain text nodes around the span.
    expect(el.textContent).toBe("abcdef");
  });

  it("overlapping ranges render the overlap class naming both sources", () => {
    const el = document.createElement("div");
    buildTransclusionDom(el, "abcdef", [spanRange(0, 4, 1), spanRange(2, 6, 2)]);
    const overlap = el.querySelector(".inline-transclusion-overlap");
    expect(overlap).not.toBeNull();
    expect(overlap!.title).toContain("Overlapping");
  });

  it("source title falls back to hex work id", () => {
    const el = document.createElement("div");
    buildTransclusionDom(el, "abc", [spanRange(0, 3, 0x2a)]);
    const span = el.querySelector("span.inline-transclusion") as HTMLElement;
    expect(span.title).toContain((0x2a).toString(16));
  });
});

describe("editor-dom-utils — insertInlineImages", () => {
  it("inserts wrappers at char positions and strips prior ones on re-run", () => {
    const el = mount("hello world");
    insertInlineImages(el, [
      { charPos: 0, hash: "h1", url: "blob:h1" },
      { charPos: 5, hash: "h2" }, // no url → placeholder
      { charPos: -1, hash: "skip" }, // filtered out
    ]);
    const wrappers = el.querySelectorAll("span.inline-image-wrapper");
    expect(wrappers).toHaveLength(2);
    expect(wrappers[0].getAttribute("contenteditable")).toBe("false");
    const img = wrappers[0].querySelector("img.inline-image");
    expect(img?.src).toBe("blob:h1");
    expect(wrappers[1].textContent).toBe("[image]");
    // Idempotent re-render: old wrappers removed, same count re-added.
    insertInlineImages(el, [{ charPos: 2, hash: "h3", url: "blob:h3" }]);
    expect(el.querySelectorAll("span.inline-image-wrapper")).toHaveLength(1);
    el.remove();
  });
});
