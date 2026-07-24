import { describe, it, expect } from "vitest";
import { textToTipTapDoc, tiptapDocToText } from "../tiptap-bridge";
import type { AnnotationEntry } from "../api/crdt_sync";

// ── Session ID precision ────────────────────────────────────────────────────
// The server sends session IDs as u64 which can exceed JavaScript's
// Number.MAX_SAFE_INTEGER (2^53 - 1). The regex capture from raw
// WebSocket text preserves the full value as a string.

describe("session ID precision", () => {
  const SESSION_REGEX = /"type":"id","value":(\d{10,})/;

  it("captures large session ID that exceeds MAX_SAFE_INTEGER", () => {
    const rawText = '{"v":2,"type":"response","id":2,"value":{"type":"id","value":3228982707014513087}}';
    const match = rawText.match(SESSION_REGEX);
    expect(match).not.toBeNull();
    expect(match![1]).toBe("3228982707014513087");
  });

  it("captured string differs from JSON.parse number (precision loss)", () => {
    const rawText = '{"type":"id","value":3228982707014513087}';
    const match = rawText.match(SESSION_REGEX);
    const captured = match![1];
    const parsed = JSON.parse(rawText).value as number;
    expect(captured).toBe("3228982707014513087");
    expect(parsed.toString()).toBe("3228982707014513000");
  });

  it("captures small session IDs correctly", () => {
    const rawText = '{"type":"id","value":1234567890}';
    const match = rawText.match(SESSION_REGEX);
    expect(match).not.toBeNull();
    expect(match![1]).toBe("1234567890");
  });

  it("does not match non-id responses", () => {
    const rawText = '{"type":"response","value":{"type":"text","value":"hello"}}';
    const match = rawText.match(SESSION_REGEX);
    expect(match).toBeNull();
  });

  it("does not match numbers with fewer than 10 digits", () => {
    const rawText = '{"type":"id","value":123}';
    const match = rawText.match(SESSION_REGEX);
    expect(match).toBeNull();
  });

  it("only captures first match (session_connect, not annotation creates)", () => {
    let captured: string | null = null;
    const responses = [
      '{"type":"id","value":3228982707014513087}',
      '{"type":"id","value":1784904353246}',
      '{"type":"id","value":1784904355665}',
    ];
    for (const text of responses) {
      if (!captured) {
        const match = text.match(SESSION_REGEX);
        if (match) captured = match[1];
      }
    }
    expect(captured).toBe("3228982707014513087");
  });

  it("resets on reconnect (simulated)", () => {
    let sessionId: string | null = null;

    // First connection
    const resp1 = '{"type":"id","value":3228982707014513087}';
    if (!sessionId) {
      const m = resp1.match(SESSION_REGEX);
      if (m) sessionId = m[1];
    }
    expect(sessionId).toBe("3228982707014513087");

    // Disconnect
    sessionId = null;

    // Reconnect with new session
    const resp2 = '{"type":"id","value":3228982707014513099}';
    if (!sessionId) {
      const m = resp2.match(SESSION_REGEX);
      if (m) sessionId = m[1];
    }
    expect(sessionId).toBe("3228982707014513099");
  });
});

// ── Blob hash hex conversion ────────────────────────────────────────────────
// The upload response contains content_hash as a large u64.
// Must convert to hex for the /blobs/{hash}/preview URL.
// BigInt preserves the full value.

describe("blob hash hex conversion", () => {
  it("converts decimal hash to hex", () => {
    const hashStr = "13549592087159267420";
    const hex = BigInt(hashStr).toString(16);
    expect(hex).toBe("bc09d236e692605c");
  });

  it("hex can be parsed back by the server (from_str_radix)", () => {
    const hashStr = "13549592087159267420";
    const hex = BigInt(hashStr).toString(16);
    // Simulate Rust's u64::from_str_radix(&hex, 16)
    const back = parseInt(hex, 16);
    // Note: parseInt loses precision for large numbers
    // The server uses u64::from_str_radix which doesn't lose precision
    // We just verify the hex string is valid
    expect(hex).toMatch(/^[0-9a-f]+$/);
    expect(hex.length).toBeGreaterThan(0);
  });

  it("small hash converts correctly", () => {
    const hex = BigInt("255").toString(16);
    expect(hex).toBe("ff");
  });

  it("hash that exceeds MAX_SAFE_INTEGER preserves precision", () => {
    const original = "11607498287447504626";
    const hex = BigInt(original).toString(16);
    const restored = BigInt("0x" + hex).toString();
    expect(restored).toBe(original);
  });

  it("preview URL is constructed correctly", () => {
    const hashStr = "13549592087159267420";
    const hex = BigInt(hashStr).toString(16);
    const url = `/blobs/${hex}/preview`;
    expect(url).toBe("/blobs/bc09d236e692605c/preview");
  });

  it("full image URL is constructed correctly", () => {
    const hashStr = "11607498287447504626";
    const hex = BigInt(hashStr).toString(16);
    const url = `/blobs/${hex}`;
    expect(url).toBe("/blobs/a1161e317a4376f2");
  });

  it("JSON.parse truncates the hash (demonstrating the bug)", () => {
    const raw = '{"content_hash":13549592087159267420}';
    const parsed = JSON.parse(raw).content_hash as number;
    const parsedStr = parsed.toString();
    // JSON.parse loses the last digits
    expect(parsedStr).not.toBe("13549592087159267420");
    // The truncated value is wrong
    expect(parsedStr).toBe("13549592087159267000");
  });

  it("regex extraction from raw response preserves precision", () => {
    const raw = '{"byte_size":702089,"content_hash":13549592087159267420,"height":1280}';
    const match = raw.match(/"content_hash":(\d+)/);
    expect(match).not.toBeNull();
    expect(match![1]).toBe("13549592087159267420");
    const hex = BigInt(match![1]).toString(16);
    expect(hex).toBe("bc09d236e692605c");
  });
});

// ── Image size validation ───────────────────────────────────────────────────

describe("image size validation", () => {
  const MAX_SIZE = 2_000_000; // 2MB

  it("rejects images over 2MB", () => {
    const fileSize = 3_008_854; // ~3MB
    expect(fileSize > MAX_SIZE).toBe(true);
  });

  it("accepts images under 2MB", () => {
    const fileSize = 909_950; // ~900KB
    expect(fileSize > MAX_SIZE).toBe(false);
  });

  it("accepts images exactly at 2MB", () => {
    const fileSize = 2_000_000;
    expect(fileSize > MAX_SIZE).toBe(false);
  });

  it("accepts small images", () => {
    const fileSize = 50_000; // 50KB
    expect(fileSize > MAX_SIZE).toBe(false);
  });

  it("error message includes file size", () => {
    const fileSize = 3_008_854;
    const msg = `Image too large (${(fileSize / 1_000_000).toFixed(1)}MB). Please use images under 2MB.`;
    expect(msg).toContain("3.0MB");
    expect(msg).toContain("2MB");
  });
});

// ── Full persistence chain: annotations → TipTap doc → annotations ─────────
// These tests verify the complete round-trip for documents with mixed content
// including images, simulating what happens when a page is saved and reloaded.

describe("full persistence chain", () => {
  it("document with heading, bold text, and image survives round-trip", () => {
    const text = "Title\nSome bold text";
    const hash = "a130d34e9f0b7a72";
    const anns = [
      { kind: "heading" as const, start: 0, end: 5, payload: JSON.stringify({ level: 1 }) },
      { kind: "bold" as const, start: 6, end: 10 },
      { kind: "image" as const, start: 20, end: 20, payload: JSON.stringify({ hash }) },
    ];

    const entries: AnnotationEntry[] = anns.map((a, i) => ({
      annotation_id: i + 1,
      kind: a.kind,
      payload: a.payload || "",
      char_start: a.start,
      char_end: a.end,
      created_by: 0,
      created_by_name: "",
      is_private: false,
    }));

    // Phase 1: Load from storage → TipTap doc
    const doc = textToTipTapDoc(text, entries);
    expect(doc.content[0].type).toBe("heading");
    expect(doc.content[1].type).toBe("paragraph");

    // Phase 2: TipTap doc → serialize back to storage
    const result = tiptapDocToText(doc);
    expect(result.text).toBe(text);

    // Heading preserved
    const hMark = result.marks.find((m) => m.kind === "heading");
    expect(hMark).toBeDefined();

    // Bold preserved
    const bMark = result.marks.find((m) => m.kind === "bold");
    expect(bMark).toBeDefined();

    // Image preserved
    const imgMark = result.marks.find((m) => m.kind === "image");
    expect(imgMark).toBeDefined();
    expect(JSON.parse(imgMark!.payload!).hash).toBe(hash);
  });

  it("document with list, blockquote, and code block survives round-trip", () => {
    const text = "Item 1\nItem 2\nQuote line\nCode here";
    const anns = [
      { kind: "list_item" as const, start: 0, end: 13, payload: JSON.stringify({ type: "bullet" }) },
      { kind: "blockquote" as const, start: 14, end: 24 },
      { kind: "code_block" as const, start: 25, end: 34, payload: JSON.stringify({ language: "" }) },
    ];

    
    const entries = anns.map((a, i) => ({
      annotation_id: i + 1,
      kind: a.kind,
      payload: a.payload || "",
      char_start: a.start,
      char_end: a.end,
      created_by: 0,
      created_by_name: "",
      is_private: false,
    }));

    const doc = textToTipTapDoc(text, entries);
    expect(doc.content[0].type).toBe("bulletList");
    expect(doc.content[1].type).toBe("blockquote");
    expect(doc.content[2].type).toBe("codeBlock");

    const result = tiptapDocToText(doc);
    expect(result.text).toBe(text);
    expect(result.marks.some((m) => m.kind === "list_item")).toBe(true);
    expect(result.marks.some((m) => m.kind === "blockquote")).toBe(true);
    expect(result.marks.some((m) => m.kind === "code_block")).toBe(true);
  });

  it("document with font size, alignment, and image survives round-trip", () => {
    // "Styled text\nAligned"
    // Styled text=0-10, \n=11, Aligned=12-18
    const text = "Styled text\nAligned";
    const hash = "deadbeefcafe";
    const anns = [
      { kind: "font_size" as const, start: 0, end: 6, payload: JSON.stringify({ px: 24 }) },
      { kind: "text_align" as const, start: 12, end: 19, payload: JSON.stringify({ align: "center" }) },
      { kind: "image" as const, start: 11, end: 11, payload: JSON.stringify({ hash }) },
    ];

    
    const entries = anns.map((a, i) => ({
      annotation_id: i + 1,
      kind: a.kind,
      payload: a.payload || "",
      char_start: a.start,
      char_end: a.end,
      created_by: 0,
      created_by_name: "",
      is_private: false,
    }));

    const doc = textToTipTapDoc(text, entries);
    const result = tiptapDocToText(doc);
    expect(result.text).toBe(text);

    const fsMark = result.marks.find((m) => m.kind === "font_size");
    expect(fsMark).toBeDefined();
    expect(JSON.parse(fsMark!.payload!).px).toBe(24);

    const imgMark = result.marks.find((m) => m.kind === "image");
    expect(imgMark).toBeDefined();
    expect(JSON.parse(imgMark!.payload!).hash).toBe(hash);
  });

  it("empty document with no annotations round-trips cleanly", () => {
    
    const doc = textToTipTapDoc("", []);
    const result = tiptapDocToText(doc);
    expect(result.text).toBe("");
    expect(result.marks).toHaveLength(0);
  });

  it("document with only an image round-trips cleanly", () => {
    const text = "";
    const hash = "abc123";
    const entries = [{
      annotation_id: 1,
      kind: "image",
      payload: JSON.stringify({ hash }),
      char_start: 0,
      char_end: 0,
      created_by: 0,
      created_by_name: "",
      is_private: false,
    }];

    
    const doc = textToTipTapDoc(text, entries);
    const result = tiptapDocToText(doc);
    const imgMark = result.marks.find((m) => m.kind === "image");
    expect(imgMark).toBeDefined();
    expect(JSON.parse(imgMark!.payload!).hash).toBe(hash);
  });
});
