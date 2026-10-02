import { describe, it, expect } from "vitest";
import {
  toCard,
  resolveFarEndWork,
  anchorExcerpt,
  dedupeProposals,
  linkTypeName,
  linkTypeColor,
} from "../llm-proposals";
import type { LlmConnectionProposal } from "../api/crdt_sync";

function mkProposal(over: Partial<LlmConnectionProposal> = {}): LlmConnectionProposal {
  return {
    excerpt: "the fifty-dollar ratio",
    start: 10,
    end: 31,
    type_id: 2,
    reasoning: "Cross-referenced in the budget work",
    far_end_title: "Dan's Budget",
    ...over,
  };
}

describe("linkTypeName/linkTypeColor", () => {
  it("names the five builtin types", () => {
    expect(linkTypeName(1)).toBe("Comment");
    expect(linkTypeName(2)).toBe("Reference");
    expect(linkTypeName(3)).toBe("Disagreement");
    expect(linkTypeName(4)).toBe("Quotation");
    expect(linkTypeName(5)).toBe("See Also");
  });

  it("falls back for unknown ids", () => {
    expect(linkTypeName(42)).toBe("Type");
    expect(linkTypeColor(42)).toBe("#8a8a96");
  });
});

describe("toCard", () => {
  it("maps a wire proposal to a pending card", () => {
    const card = toCard(mkProposal());
    expect(card.status).toBe("pending");
    expect(card.typeId).toBe(2);
    expect(card.farEndTitle).toBe("Dan's Budget");
  });

  it("keys cards by excerpt + far end + type", () => {
    const a = toCard(mkProposal());
    const b = toCard(mkProposal());
    const c = toCard(mkProposal({ type_id: 3 }));
    expect(a.key).toBe(b.key);
    expect(a.key).not.toBe(c.key);
  });
});

describe("resolveFarEndWork", () => {
  const works = [
    { work_id: 1, title: "Ruth's Plan" },
    { work_id: 2, title: "Dan's Budget" },
    { work_id: 3, title: "AI Safety Contested Claims" },
  ];

  it("resolves an exact title case-insensitively", () => {
    expect(resolveFarEndWork("dan's budget", works, null)).toBe(2);
  });

  it("resolves a truncated title by prefix", () => {
    expect(resolveFarEndWork("AI Safety Contested", works, null)).toBe(3);
  });

  it("resolves when the proposal over-specifies the title", () => {
    expect(resolveFarEndWork("Ruth's Plan (final draft)", works, null)).toBe(1);
  });

  it("never resolves to the current work", () => {
    expect(resolveFarEndWork("Dan's Budget", works, 2)).toBeNull();
  });

  it("returns null for null title or no match", () => {
    expect(resolveFarEndWork(null, works, null)).toBeNull();
    expect(resolveFarEndWork("Nonexistent", works, null)).toBeNull();
  });
});

describe("anchorExcerpt", () => {
  const text = "RLHF has a sycophancy problem. The fifty-dollar ratio hides it. Regulators are slow.";

  it("anchors at the hint position when exact", () => {
    const span = anchorExcerpt("The fifty-dollar ratio", text, 31);
    expect(span).toEqual({ start: 31, end: 53 });
  });

  it("falls back to global exact match", () => {
    const span = anchorExcerpt("RLHF has a sycophancy problem.", text, 99);
    expect(span).toEqual({ start: 0, end: 30 });
  });

  it("tolerates whitespace drift in the final pass", () => {
    const span = anchorExcerpt("The  fifty-dollar\nratio", text, 0);
    expect(span).not.toBeNull();
    expect(span!.start).toBe(31);
  });

  it("returns null when the passage is gone", () => {
    expect(anchorExcerpt("this passage was deleted", text, 0)).toBeNull();
  });

  it("returns null for an empty excerpt", () => {
    expect(anchorExcerpt("", text, 0)).toBeNull();
  });
});

describe("dedupeProposals", () => {
  it("drops proposals duplicating each other", () => {
    const cards = [toCard(mkProposal()), toCard(mkProposal())];
    expect(dedupeProposals(cards)).toHaveLength(1);
  });

  it("keeps same excerpt with different far ends", () => {
    const cards = [
      toCard(mkProposal()),
      toCard(mkProposal({ far_end_title: "Ruth's Plan" })),
    ];
    expect(dedupeProposals(cards)).toHaveLength(2);
  });

  it("drops proposals duplicating existing links, whitespace/case tolerant", () => {
    const cards = [toCard(mkProposal({ excerpt: "The  Fifty-Dollar Ratio" }))];
    const existing = [{ excerpt: "the fifty-dollar ratio", farTitle: "Dan's Budget" }];
    expect(dedupeProposals(cards, existing)).toHaveLength(0);
  });

  it("ignores existing links without excerpts", () => {
    const cards = [toCard(mkProposal())];
    expect(dedupeProposals(cards, [{ excerpt: null, farTitle: null }])).toHaveLength(1);
  });
});
