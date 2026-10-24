import { describe, it, expect } from "vitest";
import { rebasePosition, rebaseSpan, type Span } from "../api/position-transform";
import { TextBuffer } from "../api/text_buffer";

describe("rebasePosition — insertions", () => {
  const insertAt = (i: number, text: string) => [
    ...(i > 0 ? [{ type: "retain", count: i }] : []),
    { type: "insert", text },
    { type: "retain", count: 10 - i },
  ];

  it("insert before the position shifts right", () => {
    expect(rebasePosition(5, insertAt(2, "ab"))).toBe(7);
  });

  it("insert after the position is a no-op", () => {
    expect(rebasePosition(2, insertAt(5, "ab"))).toBe(2);
  });

  it("insert exactly at the position: right side lands after it, left side before", () => {
    expect(rebasePosition(5, insertAt(5, "ab"), "right")).toBe(7);
    expect(rebasePosition(5, insertAt(5, "ab"), "left")).toBe(5);
  });

  it("insert at position 0: right shifts, left pins", () => {
    expect(rebasePosition(0, insertAt(0, "x"), "right")).toBe(1);
    expect(rebasePosition(0, insertAt(0, "x"), "left")).toBe(0);
  });
});

describe("rebasePosition — deletions", () => {
  const deleteAt = (i: number, n: number) => [
    ...(i > 0 ? [{ type: "retain", count: i }] : []),
    { type: "delete", count: n },
    { type: "retain", count: 10 - i - n },
  ];

  it("delete before the position shifts left by n", () => {
    expect(rebasePosition(8, deleteAt(2, 3))).toBe(5);
  });

  it("delete after the position is a no-op", () => {
    expect(rebasePosition(2, deleteAt(5, 3))).toBe(2);
  });

  it("position inside a deleted region collapses to the deletion start", () => {
    expect(rebasePosition(6, deleteAt(4, 4))).toBe(4);
    expect(rebasePosition(4, deleteAt(4, 4))).toBe(4); // at the leading edge too
  });

  it("position at the trailing edge of a deletion survives at the same new offset", () => {
    expect(rebasePosition(8, deleteAt(4, 4))).toBe(4);
  });
});

describe("rebasePosition — identity and clamping", () => {
  it("empty ops and pure retain are identity", () => {
    expect(rebasePosition(7, [])).toBe(7);
    expect(rebasePosition(7, [{ type: "retain", count: 10 }])).toBe(7);
  });

  it("positions past the consumed region extrapolate by the net shift", () => {
    expect(rebasePosition(99, [{ type: "retain", count: 3 }, { type: "insert", text: "ab" }])).toBe(101);
    expect(rebasePosition(99, [{ type: "retain", count: 3 }, { type: "delete", count: 2 }])).toBe(97);
  });

  it("clamps negative positions to 0", () => {
    expect(rebasePosition(-3, [{ type: "retain", count: 10 }])).toBe(0);
  });

  it("partial op lists still work (ops need not consume the whole doc)", () => {
    expect(rebasePosition(8, [{ type: "retain", count: 4 }])).toBe(8);
    expect(rebasePosition(8, [{ type: "insert", text: "xy" }], "left")).toBe(10);
  });
});

describe("rebaseSpan — insertions", () => {
  const span: Span = { start: 4, end: 8 };
  const insertAt = (i: number, text: string) => [
    ...(i > 0 ? [{ type: "retain", count: i }] : []),
    { type: "insert", text },
    { type: "retain", count: 10 - i },
  ];

  it("insert before the span shifts it", () => {
    expect(rebaseSpan(span, insertAt(2, "ab"))).toEqual({ start: 6, end: 10 });
  });

  it("insert exactly at span.start stays OUTSIDE (start edge moves past it)", () => {
    expect(rebaseSpan(span, insertAt(4, "ab"))).toEqual({ start: 6, end: 10 });
  });

  it("insert exactly at span.end stays OUTSIDE (end edge pins before it)", () => {
    expect(rebaseSpan(span, insertAt(8, "ab"))).toEqual({ start: 4, end: 8 });
  });

  it("insert strictly inside grows the span", () => {
    expect(rebaseSpan(span, insertAt(6, "ab"))).toEqual({ start: 4, end: 10 });
  });

  it("insert after the span is a no-op", () => {
    expect(rebaseSpan(span, insertAt(9, "ab"))).toEqual({ start: 4, end: 8 });
  });

  it("boundary opts can opt into absorption at either edge", () => {
    expect(rebaseSpan(span, insertAt(4, "ab"), { startSide: "left" })).toEqual({ start: 4, end: 10 });
    expect(rebaseSpan(span, insertAt(8, "ab"), { endSide: "right" })).toEqual({ start: 4, end: 10 });
  });
});

describe("rebaseSpan — deletions", () => {
  const span: Span = { start: 4, end: 8 };
  const deleteAt = (i: number, n: number) => [
    ...(i > 0 ? [{ type: "retain", count: i }] : []),
    { type: "delete", count: n },
    { type: "retain", count: 10 - i - n },
  ];

  it("delete before the span shifts it left", () => {
    expect(rebaseSpan(span, deleteAt(1, 3))).toEqual({ start: 1, end: 5 });
  });

  it("delete overlapping the start shrinks from the front", () => {
    expect(rebaseSpan(span, deleteAt(2, 4))).toEqual({ start: 2, end: 4 });
  });

  it("delete overlapping the end shrinks from the back", () => {
    expect(rebaseSpan(span, deleteAt(6, 4))).toEqual({ start: 4, end: 6 });
  });

  it("delete covering the whole span collapses it to the deletion point", () => {
    expect(rebaseSpan(span, deleteAt(2, 8))).toEqual({ start: 2, end: 2 });
  });

  it("delete strictly inside shortens but keeps both edges' characters", () => {
    expect(rebaseSpan(span, deleteAt(5, 2))).toEqual({ start: 4, end: 6 });
  });

  it("delete after the span is a no-op", () => {
    expect(rebaseSpan(span, deleteAt(9, 1))).toEqual({ start: 4, end: 8 });
  });
});

describe("rebaseSpan — composite edits", () => {
  it("replacement (delete+insert) of a later region shifts by the net delta", () => {
    const ops = [
      { type: "retain", count: 2 },
      { type: "delete", count: 3 },
      { type: "insert", text: "abcdef" },
      { type: "retain", count: 5 },
    ];
    expect(rebaseSpan({ start: 8, end: 10 }, ops)).toEqual({ start: 11, end: 13 });
  });

  it("replacement covering the span collapses it to the replacement start", () => {
    const ops = [
      { type: "retain", count: 2 },
      { type: "delete", count: 8 },
      { type: "insert", text: "abcdef" },
    ];
    expect(rebaseSpan({ start: 4, end: 8 }, ops)).toEqual({ start: 2, end: 2 });
  });

  it("inverted spans stay non-negative via max-clamp", () => {
    expect(rebaseSpan({ start: 8, end: 4 }, [{ type: "retain", count: 10 }])).toEqual({ start: 8, end: 8 });
  });
});

/**
 * Property tests: TextBuffer.applyDelta is the oracle for what the
 * ops actually do. Deterministic LCG so failures reproduce.
 */
describe("position-transform — properties vs TextBuffer oracle", () => {
  function lcg(seed: number) {
    let s = seed >>> 0;
    return () => {
      s = (1103515245 * s + 12345) >>> 0;
      return s / 0x100000000;
    };
  }

  const ALPHA = "abcdefghij";
  function randText(rnd: () => number, maxLen = 24): string {
    const len = 1 + Math.floor(rnd() * maxLen);
    let t = "";
    for (let i = 0; i < len; i++) t += ALPHA[Math.floor(rnd() * ALPHA.length)];
    return t;
  }

  /** One random full-consuming edit: replace [c0,c1) with random text. */
  function randEdit(rnd: () => number, old: string) {
    const c0 = Math.floor(rnd() * (old.length + 1));
    const c1 = c0 + Math.floor(rnd() * (old.length + 1 - c0));
    const rep = randText(rnd, 6);
    const ops: Array<{ type: string; count?: number; text?: string }> = [];
    if (c0 > 0) ops.push({ type: "retain", count: c0 });
    if (c1 > c0) ops.push({ type: "delete", count: c1 - c0 });
    if (rep.length > 0) ops.push({ type: "insert", text: rep });
    if (old.length - c1 > 0) ops.push({ type: "retain", count: old.length - c1 });
    return { ops, cutStart: c0, cutEnd: c1, rep };
  }

  it("untouched spans keep their exact characters after the edit", () => {
    const rnd = lcg(0x5eed01);
    let exercised = 0;
    for (let iter = 0; iter < 400; iter++) {
      const old = randText(rnd);
      // Pick the span first, then force the cut strictly outside it
      // (boundary-touching allowed — the left policy keeps those
      // inserts outside the span).
      const s = Math.floor(rnd() * old.length);
      const e = s + 1 + Math.floor(rnd() * (old.length - s));
      const before = rnd() < 0.5;
      let c0: number, c1: number;
      if (before) {
        c1 = Math.floor(rnd() * (s + 1));
        c0 = Math.floor(rnd() * (c1 + 1));
      } else {
        c0 = e + Math.floor(rnd() * (old.length - e + 1));
        c1 = c0 + Math.floor(rnd() * (old.length + 1 - c0));
      }
      const rep = randText(rnd, 6);
      const ops: Array<{ type: string; count?: number; text?: string }> = [];
      if (c0 > 0) ops.push({ type: "retain", count: c0 });
      if (c1 > c0) ops.push({ type: "delete", count: c1 - c0 });
      if (rep.length > 0) ops.push({ type: "insert", text: rep });
      if (old.length - c1 > 0) ops.push({ type: "retain", count: old.length - c1 });

      const buf = new TextBuffer(old);
      buf.applyDelta(ops);
      const r = rebaseSpan({ start: s, end: e }, ops);

      expect(buf.getTextRange(r.start, r.end)).toBe(old.slice(s, e));
      exercised++;
    }
    expect(exercised).toBe(400);
  });

  it("general edits: results stay in bounds, ordered, and monotonic", () => {
    const rnd = lcg(0x5eed02);
    for (let iter = 0; iter < 400; iter++) {
      const old = randText(rnd);
      const { ops } = randEdit(rnd, old);
      const buf = new TextBuffer(old);
      buf.applyDelta(ops);
      const newLen = buf.charCount();

      const p1 = Math.floor(rnd() * (old.length + 1));
      const p2 = p1 + Math.floor(rnd() * (old.length + 1 - p1));
      const r1 = rebasePosition(p1, ops);
      const r2 = rebasePosition(p2, ops);
      expect(r1).toBeGreaterThanOrEqual(0);
      expect(r1).toBeLessThanOrEqual(newLen);
      expect(r2).toBeLessThanOrEqual(newLen);
      expect(r1).toBeLessThanOrEqual(r2);

      const span = { start: p1, end: Math.max(p1, p2) };
      const rs = rebaseSpan(span, ops);
      expect(rs.start).toBeGreaterThanOrEqual(0);
      expect(rs.end).toBeLessThanOrEqual(newLen);
      expect(rs.start).toBeLessThanOrEqual(rs.end);
    }
  });

  it("endpoints map to endpoints", () => {
    const rnd = lcg(0x5eed03);
    for (let iter = 0; iter < 100; iter++) {
      const old = randText(rnd);
      const { ops } = randEdit(rnd, old);
      const buf = new TextBuffer(old);
      buf.applyDelta(ops);
      const newLen = buf.charCount();
      expect(rebasePosition(0, ops, "left")).toBe(0);
      // Doc-end position with "right" follows trailing inserts
      expect(rebasePosition(old.length, ops, "right")).toBe(newLen);
    }
  });
});
