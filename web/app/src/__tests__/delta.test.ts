import { describe, it, expect } from "vitest";

function commonPrefix(a: string, b: string): number {
  let i = 0;
  const len = Math.min(a.length, b.length);
  while (i < len && a.charCodeAt(i) === b.charCodeAt(i)) i++;
  return i;
}

function commonSuffix(a: string, b: string): number {
  let i = 0;
  const aLen = a.length;
  const bLen = b.length;
  while (i < aLen && i < bLen && a.charCodeAt(aLen - 1 - i) === b.charCodeAt(bLen - 1 - i)) i++;
  return i;
}

function computeDeltaOps(
  oldText: string,
  newText: string,
): Array<{ type: string; count?: number; text?: string }> {
  if (oldText === newText) return [];
  const prefix = commonPrefix(oldText, newText);
  const oldRemaining = oldText.slice(prefix);
  const newRemaining = newText.slice(prefix);
  const suffix = commonSuffix(oldRemaining, newRemaining);
  const deleteLen = oldText.length - prefix - suffix;
  const insertText = newText.slice(prefix, newText.length - suffix);

  const ops: Array<{ type: string; count?: number; text?: string }> = [];
  if (prefix > 0) ops.push({ type: "retain", count: prefix });
  if (deleteLen > 0) ops.push({ type: "delete", count: deleteLen });
  if (insertText.length > 0) ops.push({ type: "insert", text: insertText });
  if (suffix > 0) ops.push({ type: "retain", count: suffix });
  return ops;
}

function applyDeltaOps(
  text: string,
  ops: Array<{ type: string; count?: number; text?: string }>,
): string {
  let result = "";
  let pos = 0;
  for (const op of ops) {
    switch (op.type) {
      case "retain": {
        const count = op.count ?? 0;
        result += text.slice(pos, pos + count);
        pos += count;
        break;
      }
      case "delete": {
        pos += op.count ?? 0;
        break;
      }
      case "insert": {
        result += op.text ?? "";
        break;
      }
    }
  }
  return result;
}

describe("text delta ops", () => {
  it("preserves spaces in insert", () => {
    const oldText = "hereandkill times";
    const newText = "here and kill times";
    const ops = computeDeltaOps(oldText, newText);
    const result = applyDeltaOps(oldText, ops);
    expect(result).toBe(newText);
  });

  it("handles single space insert", () => {
    const oldText = "hello world";
    const newText = "hello  world";
    const ops = computeDeltaOps(oldText, newText);
    const result = applyDeltaOps(oldText, ops);
    expect(result).toBe(newText);
  });

  it("handles insert at beginning", () => {
    const oldText = "world";
    const newText = " hello world";
    const ops = computeDeltaOps(oldText, newText);
    const result = applyDeltaOps(oldText, ops);
    expect(result).toBe(newText);
  });

  it("handles insert at end", () => {
    const oldText = "hello";
    const newText = "hello ";
    const ops = computeDeltaOps(oldText, newText);
    const result = applyDeltaOps(oldText, ops);
    expect(result).toBe(newText);
  });

  it("handles multiple inserts", () => {
    const oldText = "abcd";
    const newText = "a b c d";
    const ops = computeDeltaOps(oldText, newText);
    const result = applyDeltaOps(oldText, ops);
    expect(result).toBe(newText);
  });

  it("roundtrip: delete + insert", () => {
    const oldText = "hello cruel world";
    const newText = "hello beautiful world";
    const ops = computeDeltaOps(oldText, newText);
    const result = applyDeltaOps(oldText, ops);
    expect(result).toBe(newText);
  });

  it("roundtrip: append text", () => {
    const oldText = "line one";
    const newText = "line one\nline two\nline three";
    const ops = computeDeltaOps(oldText, newText);
    const result = applyDeltaOps(oldText, ops);
    expect(result).toBe(newText);
  });

  it("simulates two-session sync: session A inserts space, session B receives", () => {
    // Session A's local text
    const textA_before = "hereandkill times";
    const textA_after = "here and kill times";

    // Compute delta from A's perspective
    const ops = computeDeltaOps(textA_before, textA_after);

    // Session B receives and applies the delta to its copy of the text
    const textB = "hereandkill times";
    const textB_after = applyDeltaOps(textB, ops);

    expect(textB_after).toBe("here and kill times");
    expect(textB_after).toBe(textA_after);
  });
});
