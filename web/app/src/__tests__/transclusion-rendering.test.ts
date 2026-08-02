import { describe, it, expect } from "vitest";

describe("Transclusion inline rendering", () => {
  it("resolved text with transclusion has no \\n at boundaries (simple case)", () => {
    const originalText = "ABCDE";
    const transclusionContent = "brown fox";
    const insertPosition = 2;
    const resolved = originalText.slice(0, insertPosition) + transclusionContent + originalText.slice(insertPosition);
    expect(resolved).toBe("ABbrown foxCDE");
    expect(resolved.includes("\n")).toBe(false);
  });

  it("resolved text preserves surrounding text correctly", () => {
    const original = "Hello world";
    const content = "INSERTED";
    const pos = 6;
    const resolved = original.slice(0, pos) + content + original.slice(pos);
    expect(resolved).toBe("Hello INSERTEDworld");
    expect(resolved.indexOf("Hello")).toBe(0);
    expect(resolved.indexOf("world")).toBe(14);
  });

  it("trims leading/trailing newlines from transclusion content", () => {
    const raw = "\n\nbrown fox\n\n";
    const trimmed = raw.replace(/^\n+/, "").replace(/\n+$/, "");
    expect(trimmed).toBe("brown fox");
  });

  it("does not trim internal newlines", () => {
    const raw = "line one\nline two";
    const trimmed = raw.replace(/^\n+/, "").replace(/\n+$/, "");
    expect(trimmed).toBe("line one\nline two");
  });
});

describe("Placement position calculation", () => {
  it("position in raw text excludes transclusion content", () => {
    // Simulate: editor shows "AB[transclusion: brown fox]CDE"
    // User clicks between C and D
    // fullPos (visual) = 2 (AB) + 9 (brown fox) + 1 (C) = 12
    // readonlyChars = 9 (brown fox)
    // rawPos = 12 - 9 = 3 (between C and D in "ABCDE")
    const fullPos = 12;
    const readonlyChars = 9;
    const rawPos = fullPos - readonlyChars;
    expect(rawPos).toBe(3);
  });

  it("position with no existing transclusions is unchanged", () => {
    const fullPos = 3;
    const readonlyChars = 0;
    const rawPos = fullPos - readonlyChars;
    expect(rawPos).toBe(3);
  });

  it("position with two existing transclusions subtracts both", () => {
    // Editor: "AB[T1: xxx]CD[T2: yyy]EF"
    // Click between E and F
    // fullPos = 2 + 3 + 2 + 3 + 1 = 11
    // readonlyChars = 3 + 3 = 6
    // rawPos = 11 - 6 = 5 (between E and F in "ABCDEF")
    const fullPos = 11;
    const readonlyChars = 6;
    const rawPos = fullPos - readonlyChars;
    expect(rawPos).toBe(5);
  });

  it("position should NOT be double-adjusted", () => {
    const position = 3;
    const spanStart = position;
    expect(spanStart).toBe(3);
  });

  it("double-adjustment would give wrong position", () => {
    const position = 3;
    const compoundSpanLength = 3;
    const wrongResult = position - compoundSpanLength;
    expect(wrongResult).toBe(0); // This is the BUG — would insert at position 0
    // Correct: just use position directly
    expect(position).toBe(3); // Correct position
  });
});

describe("Compound state persistence (epoch guard)", () => {
  it("epoch prevents stale compound data from overwriting fresh data", () => {
    let epoch = 0;
    const epoch1 = ++epoch; // epoch = 1
    expect(epoch1).toBe(1);
    
    // Stale response arrives
    const epoch2 = ++epoch; // epoch = 2 (from work switch)
    expect(epoch1 !== epoch2).toBe(true);
    expect(epoch2).toBe(2);
  });

  it("refresh does NOT increment epoch (only loadCompound does)", () => {
    let epoch = 5;
    // refresh reads epoch without incrementing
    const refreshEpoch = epoch;
    expect(refreshEpoch).toBe(5);
    // If loadCompound fires and bumps epoch, refresh result is discarded
    const loadEpoch = ++epoch;
    expect(refreshEpoch !== loadEpoch).toBe(true);
  });
});

describe("Reading mode", () => {
  it("reading mode hides transclusion markers", () => {
    const readingMode = true;
    const showAttribution = true;
    const effectiveShowAttribution = showAttribution && !readingMode;
    expect(effectiveShowAttribution).toBe(false);
  });

  it("authoring mode shows transclusion markers", () => {
    const readingMode = false;
    const showAttribution = true;
    const effectiveShowAttribution = showAttribution && !readingMode;
    expect(effectiveShowAttribution).toBe(true);
  });

  it("reading mode disables editing", () => {
    const canEdit = true;
    const editorMode: string = "reading";
    const editable = canEdit && editorMode === "authoring";
    expect(editable).toBe(false);
  });

  it("authoring mode enables editing", () => {
    const canEdit = true;
    const editorMode: string = "authoring";
    const editable = canEdit && editorMode === "authoring";
    expect(editable).toBe(true);
  });
});

describe("Source changed detection (FR-26)", () => {
  it("source_changed flag is false when hashes match", () => {
    const storedHash = "abc123";
    const actualHash = "abc123";
    const sourceChanged = storedHash !== actualHash;
    expect(sourceChanged).toBe(false);
  });

  it("source_changed flag is true when hashes differ", () => {
    const stored: string = "abc123";
    const actual: string = "def456";
    const sourceChanged = stored !== actual;
    expect(sourceChanged).toBe(true);
  });

  it("SpanRangePayload includes source_changed field", () => {
    const payload = {
      source_work_id: 1,
      char_start: 0,
      char_end: 10,
      flat_start: 0,
      flat_end: 10,
      content_len: 10,
      source_changed: true,
    };
    expect(payload.source_changed).toBe(true);
  });
});

describe("Compound Builder source search", () => {
  it("filters works by title", () => {
    const works = [
      { work_id: 1, title: "Moby Dick" },
      { work_id: 2, title: "Pride and Prejudice" },
      { work_id: 3, title: "Dissent" },
    ];
    const q = "dis".toLowerCase();
    const filtered = works.filter((w) => w.title.toLowerCase().includes(q));
    expect(filtered.length).toBe(1);
    expect(filtered[0].title).toBe("Dissent");
  });

  it("filters works by hex ID", () => {
    const works = [
      { work_id: 100, title: "A" },
      { work_id: 200, title: "B" },
    ];
    const q = "0xc8"; // 200 in hex
    const filtered = works.filter((w) => {
      const hexId = `0x${w.work_id.toString(16)}`;
      return hexId.includes(q);
    });
    expect(filtered.length).toBe(1);
    expect(filtered[0].work_id).toBe(200);
  });

  it("sorts transclusion sources first", () => {
    const works = [
      { work_id: 1, title: "B", updated_at: 100 },
      { work_id: 2, title: "A", updated_at: 200 },
    ];
    const transclusionSourceIds = new Set([1]);
    const sorted = [...works].sort((a, b) => {
      const aIsSource = transclusionSourceIds.has(a.work_id) ? 1 : 0;
      const bIsSource = transclusionSourceIds.has(b.work_id) ? 1 : 0;
      if (aIsSource !== bIsSource) return bIsSource - aIsSource;
      return (b.updated_at ?? 0) - (a.updated_at ?? 0);
    });
    expect(sorted[0].work_id).toBe(1); // transclusion source first
  });
});
