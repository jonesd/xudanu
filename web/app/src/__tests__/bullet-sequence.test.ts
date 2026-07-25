import { describe, it, expect } from "vitest";
import { buildStyledText, extractStyleMarks, type StyleMark } from "../styled-text";
import type { AnnotationEntry } from "../api/crdt_sync";

function ann(kind: string, start: number, end: number, payload?: string): AnnotationEntry {
  return {
    annotation_id: Math.floor(Math.random() * 1e9),
    kind,
    payload: payload || "",
    char_start: start,
    char_end: end,
    created_by: 0,
    created_by_name: "",
    is_private: false,
  };
}

function mark(kind: string, start: number, end: number, payload?: string): StyleMark {
  return { annotation_id: 1, kind, char_start: start, char_end: end, ...(payload ? { payload } : {}) };
}

// Simulates the full sequence: title + 4 bullet items + exit
describe("bullet list full sequence", () => {
  // Step 1: "My Title" as heading
  // Text: "My Title"
  // Annotation: heading at [0, 8]
  const step1Text = "My Title";
  const step1Anns = [ann("heading", 0, 8, JSON.stringify({ level: 1 }))];
  const step1Marks = extractStyleMarks(step1Anns);

  it("step 1: title renders as H1", () => {
    const html = buildStyledText(step1Text, step1Marks);
    expect(html).toContain("<h1>My Title</h1>");
  });

  // Step 2: Press Enter after title
  // Text: "My Title\n"
  // Annotation: heading at [0, 8]
  const step2Text = "My Title\n";
  const step2Anns = step1Anns;
  const step2Marks = extractStyleMarks(step2Anns);

  it("step 2: title + empty line after Enter", () => {
    const html = buildStyledText(step2Text, step2Marks);
    expect(html).toContain("<h1>My Title</h1>");
  });

  // Step 3: Click bullet on empty line (line 1, offset 9)
  // Text: "My Title\n"
  // Annotations: heading [0, 8], list_item [9, 10]
  const step3Text = "My Title\n";
  const step3Anns = [
    ann("heading", 0, 8, JSON.stringify({ level: 1 })),
    ann("list_item", 9, 10, JSON.stringify({ type: "bullet" })),
  ];
  const step3Marks = extractStyleMarks(step3Anns);

  it("step 3: empty line shows as bullet after clicking •", () => {
    const html = buildStyledText(step3Text, step3Marks);
    expect(html).toContain("<ul>");
    expect(html).toContain("<li></li>");
    expect(html).toContain("</ul>");
  });

  // Step 4: Type "1" on the bullet line
  // Text: "My Title\n1"
  // Annotations: heading [0, 8], list_item [9, 10]
  // (annotation doesn't move — span migration keeps it at [9, 10])
  const step4Text = "My Title\n1";
  const step4Anns = step3Anns;
  const step4Marks = extractStyleMarks(step4Anns);

  it("step 4: bullet line with text '1'", () => {
    const html = buildStyledText(step4Text, step4Marks);
    expect(html).toContain("<li>1</li>");
  });

  // Step 5: Press Enter after "1" → new bullet should appear
  // Text: "My Title\n1\n"
  // Annotations: heading [0, 8], list_item [9, 10], list_item [11, 12]
  // (continuation creates new list_item for the new empty line)
  const step5Text = "My Title\n1\n";
  const step5Anns = [
    ann("heading", 0, 8, JSON.stringify({ level: 1 })),
    ann("list_item", 9, 10, JSON.stringify({ type: "bullet" })),
    ann("list_item", 11, 12, JSON.stringify({ type: "bullet" })),
  ];
  const step5Marks = extractStyleMarks(step5Anns);

  it("step 5: Enter after '1' → new bullet on empty line", () => {
    const html = buildStyledText(step5Text, step5Marks);
    expect(html).toContain("<li>1</li>");
    expect(html).toContain("<li></li>"); // empty bullet for next item
    // Both should be in the same <ul>
    const ulStarts = html.match(/<ul>/g);
    expect(ulStarts).toHaveLength(1);
  });

  // Step 6: Type "2"
  // Text: "My Title\n1\n2"
  // Annotations: same as step 5
  const step6Text = "My Title\n1\n2";
  const step6Anns = step5Anns;
  const step6Marks = extractStyleMarks(step6Anns);

  it("step 6: second bullet with text '2'", () => {
    const html = buildStyledText(step6Text, step6Marks);
    expect(html).toContain("<li>1</li>");
    expect(html).toContain("<li>2</li>");
  });

  // Step 7: Press Enter → new bullet
  // Text: "My Title\n1\n2\n"
  // Annotations add list_item [13, 14]
  const step7Text = "My Title\n1\n2\n";
  const step7Anns = [
    ...step5Anns,
    ann("list_item", 13, 14, JSON.stringify({ type: "bullet" })),
  ];
  const step7Marks = extractStyleMarks(step7Anns);

  it("step 7: Enter after '2' → third bullet", () => {
    const html = buildStyledText(step7Text, step7Marks);
    expect(html).toContain("<li>1</li>");
    expect(html).toContain("<li>2</li>");
    expect(html).toContain("<li></li>");
  });

  // Step 8: Type "3"
  const step8Text = "My Title\n1\n2\n3";
  const step8Marks = step7Marks;

  it("step 8: third bullet with text '3'", () => {
    const html = buildStyledText(step8Text, step8Marks);
    expect(html).toContain("<li>3</li>");
  });

  // Step 9: Press Enter → fourth bullet
  // Text: "My Title\n1\n2\n3\n"
  const step9Text = "My Title\n1\n2\n3\n";
  const step9Anns = [
    ...step7Anns,
    ann("list_item", 15, 16, JSON.stringify({ type: "bullet" })),
  ];
  const step9Marks = extractStyleMarks(step9Anns);

  it("step 9: Enter after '3' → fourth bullet", () => {
    const html = buildStyledText(step9Text, step9Marks);
    expect(html).toContain("<li>3</li>");
    expect(html).toContain("<li></li>");
  });

  // Step 10: Type "4"
  const step10Text = "My Title\n1\n2\n3\n4";
  const step10Marks = step9Marks;

  it("step 10: fourth bullet with text '4'", () => {
    const html = buildStyledText(step10Text, step10Marks);
    expect(html).toContain("<li>4</li>");
  });

  // Step 11: Press Enter → fifth bullet (empty)
  const step11Text = "My Title\n1\n2\n3\n4\n";
  const step11Anns = [
    ...step9Anns,
    ann("list_item", 17, 18, JSON.stringify({ type: "bullet" })),
  ];
  const step11Marks = extractStyleMarks(step11Anns);

  it("step 11: Enter after '4' → fifth empty bullet", () => {
    const html = buildStyledText(step11Text, step11Marks);
    const liMatches = html.match(/<li>/g);
    expect(liMatches).toHaveLength(5);
  });

  // Step 12: Press Enter on empty bullet → EXIT list
  // The empty line's list_item annotation is deleted
  const step12Text = "My Title\n1\n2\n3\n4\n\n";
  const step12Anns = step9Anns; // the empty line's list_item [17,18] is deleted
  const step12Marks = extractStyleMarks(step12Anns);

  it("step 12: Enter on empty bullet → list closes, 4 items remain", () => {
    const html = buildStyledText(step12Text, step12Marks);
    expect(html).toContain("<li>1</li>");
    expect(html).toContain("<li>2</li>");
    expect(html).toContain("<li>3</li>");
    expect(html).toContain("<li>4</li>");
    expect(html).toContain("</ul>");
    // The empty lines after list should be paragraphs, not list items
    expect(html).toContain("<p></p>");
  });

  // Also verify the list has exactly 4 items
  it("step 12: list has exactly 4 items after exit", () => {
    const html = buildStyledText(step12Text, step12Marks);
    const liCount = (html.match(/<li>/g) || []).length;
    expect(liCount).toBe(4);
  });

  // Final: complete document renders correctly
  it("final: complete document with heading + 4-item list", () => {
    const html = buildStyledText(step11Text, step11Marks);
    expect(html).toContain("<h1>My Title</h1>");
    expect(html).toContain("<ul>");
    expect(html).toContain("<li>1</li>");
    expect(html).toContain("<li>2</li>");
    expect(html).toContain("<li>3</li>");
    expect(html).toContain("<li>4</li>");
    expect(html).toContain("</ul>");
  });
});

// Test the continuation logic itself
describe("list continuation logic", () => {
  function findLine(text: string, pos: number): { start: number; end: number; text: string } {
    const start = text.lastIndexOf("\n", pos - 1) + 1;
    const endIdx = text.indexOf("\n", pos);
    const end = endIdx === -1 ? text.length : endIdx;
    return { start, end, text: text.slice(start, end) };
  }

  function shouldCreateBullet(
    newText: string,
    prevText: string,
    annotations: Array<{ kind: string; char_start: number; char_end: number }>,
  ): { create: boolean; start?: number; end?: number; exit?: boolean; deleteId?: number } {
    if (newText.length <= prevText.length) return { create: false };

    let diffPos = 0;
    while (diffPos < prevText.length && newText[diffPos] === prevText[diffPos]) diffPos++;

    const lines: Array<{ start: number; end: number; text: string }> = [];
    let pos = 0;
    for (const line of newText.split("\n")) {
      lines.push({ start: pos, end: pos + line.length, text: line });
      pos += line.length + 1;
    }

    // Find which line the cursor is on AFTER the change
    // If a \n was inserted, the cursor is on the NEW line (after the \n)
    let curLineIdx = lines.findIndex((l) => diffPos >= l.start && diffPos <= l.end);
    // If diffPos is at end of a line and next char is \n, move to next line
    if (curLineIdx >= 0 && diffPos === lines[curLineIdx].end && newText[diffPos] === "\n") {
      curLineIdx++;
    }
    if (curLineIdx <= 0) return { create: false };

    const curLine = lines[curLineIdx];
    const prevLine = lines[curLineIdx - 1];
    const prevListAnn = annotations.find(
      (a) => a.kind === "list_item" && a.char_start <= prevLine.end && a.char_end >= prevLine.start,
    );

    if (!prevListAnn) return { create: false };

    const curHasList = annotations.some(
      (a) => a.kind === "list_item" && a.char_start >= curLine.start && a.char_start <= curLine.end,
    );
    if (curHasList) return { create: false };

    if (prevLine.text.length === 0) {
      return { create: false, exit: true, deleteId: prevListAnn.char_start };
    }

    return {
      create: true,
      start: curLine.start,
      end: Math.max(curLine.start + 1, curLine.end),
    };
  }

  it("title → Enter → no bullet yet", () => {
    const result = shouldCreateBullet("My Title\n", "My Title", []);
    expect(result.create).toBe(false);
    expect(result.exit).toBeUndefined();
  });

  it("bullet line '1' → Enter → create bullet for new line", () => {
    const text = "My Title\n1\n";
    const prev = "My Title\n1";
    const anns = [{ kind: "list_item", char_start: 9, char_end: 10 }];
    const result = shouldCreateBullet(text, prev, anns);
    expect(result.create).toBe(true);
    expect(result.start).toBe(11);
    expect(result.end).toBe(12);
  });

  it("empty bullet → Enter → exit list", () => {
    // After "1" + Enter, there should be two list_items: one for "1" and one for the empty bullet
    const text = "1\n\n";
    const prev = "1\n";
    const anns = [
      { kind: "list_item", char_start: 0, char_end: 1 }, // "1" line
      { kind: "list_item", char_start: 2, char_end: 3 }, // empty bullet line
    ];
    const result = shouldCreateBullet(text, prev, anns);
    expect(result.create).toBe(false);
    expect(result.exit).toBe(true);
  });

  it("non-list line → Enter → no action", () => {
    const result = shouldCreateBullet("hello\n", "hello", []);
    expect(result.create).toBe(false);
    expect(result.exit).toBeUndefined();
  });
});
