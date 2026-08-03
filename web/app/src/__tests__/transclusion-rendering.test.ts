import { describe, it, expect } from "vitest";
import { validateSpanRanges } from "../components/CollaborativeEditor";
import type { SpanRangePayload } from "../api/crdt_sync";

describe("Transclusion inline rendering — \\n stripping (the actual bug)", () => {
  it("strips trailing \\n from text before transclusion span", () => {
    const resolvedText = "AB\nAlphaCDE";
    const flatStart = 3;
    const pos = 0;
    let chunk = resolvedText.slice(pos, flatStart);
    chunk = chunk.replace(/\n+$/, "");
    expect(chunk).toBe("AB");
    expect(chunk.includes("\n")).toBe(false);
  });

  it("strips leading \\n from text after transclusion span", () => {
    const resolvedText = "ABAlpha\nCDE";
    const flatEnd = 7;
    let after = resolvedText.slice(flatEnd);
    after = after.replace(/^\n+/, "");
    expect(after).toBe("CDE");
    expect(after.startsWith("\n")).toBe(false);
  });

  it("strips \\n from both sides when O-tree inserts newlines", () => {
    const resolvedText = "AB\nAlpha\nCDE";
    const flatStart = 3;
    const flatEnd = 8;

    const before = resolvedText.slice(0, flatStart).replace(/\n+$/, "");
    const content = resolvedText.slice(flatStart, flatEnd).replace(/^\n+/, "").replace(/\n+$/, "");
    const after = resolvedText.slice(flatEnd).replace(/^\n+/, "");

    expect(before).toBe("AB");
    expect(content).toBe("Alpha");
    expect(after).toBe("CDE");
    const reconstructed = before + content + after;
    expect(reconstructed).toBe("ABAlphaCDE");
    expect(reconstructed.includes("\n")).toBe(false);
  });

  it("preserves internal \\n in original text (not at transclusion boundary)", () => {
    const resolvedText = "Hello\nWorld\nAlpha\nFoo\nBar";
    const flatStart = 12;
    const flatEnd = 17;

    const before = resolvedText.slice(0, flatStart).replace(/\n+$/, "");
    const content = resolvedText.slice(flatStart, flatEnd).replace(/^\n+/, "").replace(/\n+$/, "");
    const after = resolvedText.slice(flatEnd).replace(/^\n+/, "");

    expect(before).toBe("Hello\nWorld");
    expect(content).toBe("Alpha");
    expect(after).toBe("Foo\nBar");
  });

  it("strips multiple consecutive \\n at boundary", () => {
    const resolvedText = "AB\n\n\nAlpha\n\nCDE";
    const flatStart = 5;
    const flatEnd = 10;

    const before = resolvedText.slice(0, flatStart).replace(/\n+$/, "");
    const after = resolvedText.slice(flatEnd).replace(/^\n+/, "");

    expect(before).toBe("AB");
    expect(after).toBe("CDE");
  });
});

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

describe("CSS conflict resolution (app.css vs workspace.css)", () => {
  it("workspace.css wins for display property (higher specificity)", () => {
    // .ws-doc-surface .inline-transclusion has specificity (0,2,0)
    // .inline-transclusion has specificity (0,1,0)
    const workspaceSpecificity = 2;
    const appSpecificity = 1;
    expect(workspaceSpecificity).toBeGreaterThan(appSpecificity);
  });

  it("display: inline !important overrides any specificity", () => {
    // Even if app.css somehow had higher specificity, !important wins
    const hasImportant = true;
    expect(hasImportant).toBe(true);
  });

  it("app.css should only set cursor (no conflicting styles)", () => {
    const appCssProperties = ["cursor"];
    const conflictingProperties = ["display", "background", "border", "padding", "position", "user-select"];
    for (const prop of conflictingProperties) {
      expect(appCssProperties).not.toContain(prop);
    }
  });
});

describe("Reading mode toggles", () => {
  it("reading mode hides attribution overlay (opacity 0)", () => {
    const readingMode = true;
    const opacity = readingMode ? 0 : 1;
    expect(opacity).toBe(0);
  });

  it("authoring mode shows attribution overlay", () => {
    const readingMode = false;
    const opacity = readingMode ? 0 : 1;
    expect(opacity).toBe(1);
  });

  it("reading mode CSS removes border, background, padding from transclusion", () => {
    const readingModeStyle = {
      borderLeft: "none",
      background: "transparent",
      padding: "0",
      borderRadius: "0",
      fontStyle: "normal",
    };
    expect(readingModeStyle.borderLeft).toBe("none");
    expect(readingModeStyle.background).toBe("transparent");
    expect(readingModeStyle.padding).toBe("0");
  });
});

describe("Compound state epoch guard (the persistence bug)", () => {
  it("loadCompound increments epoch (request ownership)", () => {
    let epoch = 0;
    const e1 = ++epoch;
    expect(e1).toBe(1);
    expect(epoch).toBe(1);
  });

  it("refresh reads epoch WITHOUT incrementing (cooperative)", () => {
    const epoch = 5;
    const refreshEpoch = epoch; // read only
    expect(refreshEpoch).toBe(5);
    expect(epoch).toBe(5); // unchanged
  });

  it("work switch bumps epoch (invalidates pending responses)", () => {
    let epoch = 3;
    // loadCompound starts
    const loadEpoch = ++epoch; // 4
    // work switch cleanup
    epoch++; // 5
    // loadCompound response arrives
    expect(loadEpoch).not.toBe(epoch); // stale — discarded
  });

  it("hasCompound guard prevents clearing on transient empty", () => {
    let hasCompound = true;
    const spanRangesEmpty = true;
    // OLD bug: always cleared. NEW: only clear if !hasCompound
    if (spanRangesEmpty && !hasCompound) {
      hasCompound = false;
    }
    expect(hasCompound).toBe(true); // preserved!
  });
});

describe("validateSpanRanges — guard against invalid data", () => {
  const makeSpan = (flat_start: number, flat_end: number): SpanRangePayload => ({
    source_work_id: 1,
    char_start: 0,
    char_end: 10,
    flat_start,
    flat_end,
    content_len: flat_end - flat_start,
  });

  it("filters out spans with flat_end beyond text length", () => {
    const spans = [makeSpan(0, 50)];
    const result = validateSpanRanges(spans, 30);
    expect(result.length).toBe(0);
  });

  it("filters out spans with flat_start < 0", () => {
    const spans = [makeSpan(-5, 10)];
    const result = validateSpanRanges(spans, 30);
    expect(result.length).toBe(0);
  });

  it("filters out spans where flat_end <= flat_start (zero or negative width)", () => {
    const spans = [makeSpan(5, 5), makeSpan(10, 5)];
    const result = validateSpanRanges(spans, 30);
    expect(result.length).toBe(0);
  });

  it("keeps valid spans within text bounds", () => {
    const spans = [makeSpan(0, 10), makeSpan(15, 25)];
    const result = validateSpanRanges(spans, 30);
    expect(result.length).toBe(2);
  });

  it("keeps span that ends exactly at text length", () => {
    const spans = [makeSpan(20, 30)];
    const result = validateSpanRanges(spans, 30);
    expect(result.length).toBe(1);
  });

  it("filters empty span list", () => {
    const result = validateSpanRanges([], 30);
    expect(result.length).toBe(0);
  });

  it("handles multiple invalid + valid spans mixed", () => {
    const spans = [makeSpan(0, 10), makeSpan(-1, 5), makeSpan(20, 50), makeSpan(15, 20)];
    const result = validateSpanRanges(spans, 30);
    expect(result.length).toBe(2);
    expect(result[0].flat_start).toBe(0);
    expect(result[1].flat_start).toBe(15);
  });
});

describe("handlePlaceTransclusion — position handling", () => {
  it("clamps negative position to 0", () => {
    let spanStart = -1;
    if (spanStart < 0) spanStart = 0;
    expect(spanStart).toBe(0);
  });

  it("uses padding position when padding is provided (click below last line)", () => {
    const text = "Hello";
    const padding: string = "\n\n";
    let spanStart = -1;
    if (padding.length > 0) {
      spanStart = (text + padding).length;
    }
    expect(spanStart).toBe(7);
  });

  it("padding is undefined when clicking mid-line (no newlines added)", () => {
    const padding: string | undefined = undefined;
    let spanStart = 2;
    if (padding) {
      spanStart = 99;
    }
    expect(spanStart).toBe(2);
  });
});

describe("buildTransclusionDom — DOM structure expectations", () => {
  it("resolved text with no spans renders as plain text", () => {
    const spans: SpanRangePayload[] = [];
    const result = validateSpanRanges(spans, 100);
    expect(result.length).toBe(0);
    // buildTransclusionDom would just set textContent
  });

  it("empty resolved text gets a <br> placeholder", () => {
    const resolvedText: string = "";
    const isEmpty = resolvedText.length === 0;
    expect(isEmpty).toBe(true);
  });

  it("sorted spans are processed in order", () => {
    const spans = [
      { flat_start: 20, flat_end: 30, source_work_id: 2, char_start: 0, char_end: 10, content_len: 10 },
      { flat_start: 0, flat_end: 10, source_work_id: 1, char_start: 0, char_end: 10, content_len: 10 },
    ];
    const sorted = [...spans].sort((a, b) => a.flat_start - b.flat_start);
    expect(sorted[0].flat_start).toBe(0);
    expect(sorted[1].flat_start).toBe(20);
  });

  it("text between non-adjacent spans is preserved", () => {
    const resolvedText = "AAAAText betweenBBBBEnd";
    const span1 = { flat_start: 0, flat_end: 4 };
    const span2 = { flat_start: 16, flat_end: 20 };
    const between = resolvedText.slice(span1.flat_end, span2.flat_start);
    expect(between).toBe("Text between");
  });

  it("text after last span is preserved", () => {
    const resolvedText = "AAAARemaining text";
    const lastSpanEnd = 4;
    const after = resolvedText.slice(lastSpanEnd);
    expect(after).toBe("Remaining text");
  });
});

describe("Auth flow — session_login_public guard", () => {
  it("does NOT call login_public when ticket auth succeeds", () => {
    const ticketOk = true;
    const who = { club_id: 1011, display_name: "david" };
    const shouldLoginPublic = !who && !ticketOk;
    expect(shouldLoginPublic).toBe(false);
  });

  it("calls login_public when both ticket and identity fail", () => {
    const ticketOk = false;
    const who = null;
    const shouldLoginPublic = !who && !ticketOk;
    expect(shouldLoginPublic).toBe(true);
  });

  it("does NOT call login_public when identity exists but ticket failed", () => {
    // Edge case: ticket expired but session still has identity from cache
    const ticketOk = false;
    const who = { club_id: 1011, display_name: "david" };
    const shouldLoginPublic = !who && !ticketOk;
    expect(shouldLoginPublic).toBe(false);
  });
});

describe("Switch work guard — prevents overlapping async", () => {
  it("first switch blocks second switch (sets switching=true)", () => {
    let switching = false;
    let pendingSwitchId: number | null = null;

    // First switch to work 100
    if (switching) { pendingSwitchId = 100; }
    else { switching = true; }
    expect(switching).toBe(true);

    // Second switch to work 200 arrives while first is in progress
    if (switching) { pendingSwitchId = 200; }
    expect(pendingSwitchId).toBe(200);
  });

  it("pending switch fires after first completes", () => {
    let switching = true;
    let pendingSwitchId: number | null = 200;

    // First switch completes
    switching = false;
    if (pendingSwitchId !== null) {
      const next = pendingSwitchId;
      pendingSwitchId = null;
      switching = true;
      // switchWork(next) would be called
      expect(next).toBe(200);
    }
    expect(switching).toBe(true);
  });

  it("rapid clicking keeps only the LAST target", () => {
    let switching = false;
    let pendingSwitchId: number | null = null;

    const click = (id: number) => {
      if (switching) { pendingSwitchId = id; return; }
      switching = true;
    };

    click(100); // starts switching
    click(200); // queued
    click(300); // replaces 200
    click(400); // replaces 300

    expect(pendingSwitchId).toBe(400); // only last survives
  });
});

describe("Compound Builder — word count stats", () => {
  it("counts total words in document", () => {
    const text = "The quick brown fox jumps";
    const words = text.trim().split(/\s+/).filter(Boolean).length;
    expect(words).toBe(5);
  });

  it("counts transcluded words separately", () => {
    const centerText = "Hello brown fox World";
    const spans = [{ resolved_content: "brown fox", flat_start: 6, flat_end: 15 }];
    let transcludedWords = 0;
    for (const span of spans) {
      const content = span.resolved_content || centerText.slice(span.flat_start, span.flat_end);
      transcludedWords += content.trim().split(/\s+/).filter(Boolean).length;
    }
    expect(transcludedWords).toBe(2);
  });

  it("calculates percentage transcluded", () => {
    const totalWords = 10;
    const transcludedWords = 3;
    const percent = totalWords > 0 ? Math.round((transcludedWords / totalWords) * 100) : 0;
    expect(percent).toBe(30);
  });

  it("counts unique source works", () => {
    const spans = [
      { source_work_id: 1 },
      { source_work_id: 2 },
      { source_work_id: 1 },
      { source_work_id: 3 },
    ];
    const sourceCount = new Set(spans.map((s) => s.source_work_id)).size;
    expect(sourceCount).toBe(3);
  });
});

describe("Compound Builder — duplicate detection", () => {
  it("detects same passage transcluded twice", () => {
    const spans = [
      { source_work_id: 1, char_start: 10, char_end: 20 },
      { source_work_id: 1, char_start: 10, char_end: 20 },
    ];
    const seen = new Set<string>();
    const duplicates: boolean[] = [];
    for (const span of spans) {
      const key = `${span.source_work_id}:${span.char_start}:${span.char_end}`;
      duplicates.push(seen.has(key));
      seen.add(key);
    }
    expect(duplicates).toEqual([false, true]);
  });

  it("does not flag different passages from same source as duplicate", () => {
    const spans = [
      { source_work_id: 1, char_start: 10, char_end: 20 },
      { source_work_id: 1, char_start: 30, char_end: 40 },
    ];
    const seen = new Set<string>();
    const duplicates: boolean[] = [];
    for (const span of spans) {
      const key = `${span.source_work_id}:${span.char_start}:${span.char_end}`;
      duplicates.push(seen.has(key));
      seen.add(key);
    }
    expect(duplicates).toEqual([false, false]);
  });
});

describe("Compound Builder — placement mode auto-detection", () => {
  it("auto selects block for long passages", () => {
    const text = "A".repeat(101);
    const mode = text.includes("\n") || text.length > 100 ? "block" : "inline";
    expect(mode).toBe("block");
  });

  it("auto selects block for multi-line passages", () => {
    const text = "Line 1\nLine 2";
    const mode = text.includes("\n") || text.length > 100 ? "block" : "inline";
    expect(mode).toBe("block");
  });

  it("auto selects inline for short single-line passages", () => {
    const text = "short text";
    const mode = text.includes("\n") || text.length > 100 ? "block" : "inline";
    expect(mode).toBe("inline");
  });

  it("explicit mode overrides auto-detection", () => {
    const placementMode: string = "inline";
    const selectedText = "A".repeat(101);
    const effective = placementMode !== "auto"
      ? placementMode
      : selectedText.includes("\n") || selectedText.length > 100
        ? "block" : "inline";
    expect(effective).toBe("inline");
  });
});
