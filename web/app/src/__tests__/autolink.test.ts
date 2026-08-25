import { describe, it, expect } from "vitest";
import { findUrls, autolinkEscaped } from "../styled-text";
import { escapeHtml } from "../utils/escape";

describe("findUrls", () => {
  it("finds a bare http URL", () => {
    expect(findUrls("see http://example.com now")).toEqual([
      { start: 4, end: 22, url: "http://example.com" },
    ]);
  });

  it("finds https and leaves plain domains alone", () => {
    expect(findUrls("https://xudanu.com and example.com")).toHaveLength(1);
  });

  it("trims trailing punctuation", () => {
    const [u] = findUrls("go to https://example.com/a?b=1.");
    expect(u.url).toBe("https://example.com/a?b=1");
  });

  it("no urls in plain text", () => {
    expect(findUrls("just words here")).toEqual([]);
  });
});

describe("autolinkEscaped", () => {
  it("wraps a URL in an anchor", () => {
    const out = autolinkEscaped(escapeHtml("see https://example.com/x"));
    expect(out).toContain('<a href="https://example.com/x"');
    expect(out).toContain('target="_blank"');
  });

  it("handles & in query strings (escaped as &amp;)", () => {
    const out = autolinkEscaped(escapeHtml("https://example.com/?a=1&b=2"));
    expect(out).toContain('href="https://example.com/?a=1&amp;b=2"');
  });

  it("leaves non-URL text untouched", () => {
    expect(autolinkEscaped("plain &amp; text")).toBe("plain &amp; text");
  });
});
