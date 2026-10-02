import { describe, it, expect } from "vitest";
import {
  disputeStatus,
  sortChainsBestFirst,
  isUncontested,
  linkWeight,
  DISAGREEMENT_TYPE,
  type ArgumentChain,
} from "../argument-structure";
import type { LinkEntry } from "../api/crdt_sync";

function mkLink(over: Partial<LinkEntry> = {}): LinkEntry {
  return {
    link_id: 1,
    origin: 100,
    destination: 200,
    origin_ref: null,
    destination_ref: null,
    link_types: [],
    ...over,
  };
}

function mkDisagreement(over: Partial<LinkEntry> = {}): LinkEntry {
  return mkLink({ link_types: [DISAGREEMENT_TYPE], ...over });
}

describe("disputeStatus", () => {
  it("returns uncontested when no Disagreement links exist", () => {
    const links = [mkLink({ link_types: [1] }), mkLink({ link_types: [2] })];
    const result = disputeStatus(200, links);
    expect(result.status).toBe("uncontested");
    expect(result.chains).toHaveLength(0);
  });

  it("returns disputed when a Disagreement exists with no response", () => {
    const links = [mkDisagreement({ origin: 100, destination: 200 })];
    const result = disputeStatus(200, links);
    expect(result.status).toBe("disputed");
    expect(result.chains).toHaveLength(1);
    expect(result.chains[0].status).toBe("disputed");
  });

  it("returns rebutted when a non-Disagreement responds to the criticism work", () => {
    const links = [
      mkDisagreement({ link_id: 1, origin: 100, destination: 200 }),
      mkLink({ link_id: 2, origin: 300, destination: 100, link_types: [2] }), // Reference to the criticism
    ];
    const result = disputeStatus(200, links);
    expect(result.status).toBe("rebutted");
    expect(result.chains[0].responses).toHaveLength(1);
    expect(result.chains[0].status).toBe("rebutted");
  });

  it("exact responds_to property wins over the heuristic (FR-85 Phase 3)", () => {
    // The response doesn't match the heuristic shape (it points at
    // the disputed work, not the criticism work) — only the exact
    // property makes it a response.
    const links = [
      mkDisagreement({ link_id: 1, origin: 100, destination: 200 }),
      mkLink({ link_id: 2, origin: 300, destination: 200, link_types: [2], responds_to: 1 }),
    ];
    const result = disputeStatus(200, links);
    expect(result.status).toBe("rebutted");
    expect(result.chains[0].responses.map((r) => r.link_id)).toEqual([2]);
  });

  it("exact responds_to naming a different chain is not this chain's response", () => {
    const links = [
      mkDisagreement({ link_id: 1, origin: 100, destination: 200 }),
      mkDisagreement({ link_id: 5, origin: 400, destination: 200 }),
      // Heuristic shape matches chain 1, but the property names
      // chain 5 — exact wins, chain 1 stays disputed.
      mkLink({ link_id: 2, origin: 300, destination: 100, link_types: [2], responds_to: 5 }),
    ];
    const result = disputeStatus(200, links);
    const chain1 = result.chains.find((c) => c.root.link_id === 1)!;
    const chain5 = result.chains.find((c) => c.root.link_id === 5)!;
    expect(chain1.responses).toHaveLength(0);
    expect(chain5.responses).toHaveLength(1);
  });

  it("does not count another Disagreement as a response", () => {
    const links = [
      mkDisagreement({ link_id: 1, origin: 100, destination: 200 }),
      mkDisagreement({ link_id: 2, origin: 300, destination: 100 }),
    ];
    const result = disputeStatus(200, links);
    expect(result.status).toBe("disputed");
    expect(result.chains[0].responses).toHaveLength(0);
  });

  it("does not count a link from the disputed work as a response", () => {
    const links = [
      mkDisagreement({ link_id: 1, origin: 100, destination: 200 }),
      mkLink({ link_id: 2, origin: 200, destination: 100, link_types: [2] }), // from the disputed work
    ];
    const result = disputeStatus(200, links);
    expect(result.status).toBe("disputed");
    expect(result.chains[0].responses).toHaveLength(0);
  });

  it("builds multiple chains from multiple Disagreements", () => {
    const links = [
      mkDisagreement({ link_id: 1, origin: 100, destination: 200 }),
      mkDisagreement({ link_id: 2, origin: 300, destination: 200 }),
    ];
    const result = disputeStatus(200, links);
    expect(result.chains).toHaveLength(2);
  });

  it("chain weight sums root + responses endorsements", () => {
    const links = [
      mkDisagreement({
        link_id: 1,
        origin: 100,
        destination: 200,
        endorsement_count: 3,
      }),
      mkLink({
        link_id: 2,
        origin: 300,
        destination: 100,
        link_types: [2],
        endorsement_count: 2,
      }),
    ];
    const result = disputeStatus(200, links);
    expect(result.chains[0].weight).toBe(5);
  });
});

describe("sortChainsBestFirst", () => {
  it("sorts by weight descending (best-against first)", () => {
    const weak: ArgumentChain = {
      root: mkDisagreement({ link_id: 1 }),
      responses: [],
      weight: 1,
      status: "disputed",
    };
    const strong: ArgumentChain = {
      root: mkDisagreement({ link_id: 2 }),
      responses: [],
      weight: 10,
      status: "rebutted",
    };
    const sorted = sortChainsBestFirst([weak, strong]);
    expect(sorted[0].weight).toBe(10);
    expect(sorted[1].weight).toBe(1);
  });

  it("ties broken by recency (higher link_id first)", () => {
    const older: ArgumentChain = {
      root: mkDisagreement({ link_id: 5 }),
      responses: [],
      weight: 3,
      status: "disputed",
    };
    const newer: ArgumentChain = {
      root: mkDisagreement({ link_id: 10 }),
      responses: [],
      weight: 3,
      status: "disputed",
    };
    const sorted = sortChainsBestFirst([older, newer]);
    expect(sorted[0].root.link_id).toBe(10);
  });
});

describe("isUncontested", () => {
  it("true when no Disagreement links to this work", () => {
    expect(isUncontested([mkLink({ link_types: [1] })], 200)).toBe(true);
  });

  it("false when a Disagreement exists", () => {
    expect(isUncontested([mkDisagreement({ destination: 200 })], 200)).toBe(false);
  });

  it("ignores Disagreements to other works", () => {
    expect(isUncontested([mkDisagreement({ destination: 999 })], 200)).toBe(true);
  });
});

describe("linkWeight", () => {
  it("sums endorsement count and named endorsements", () => {
    expect(linkWeight(mkLink({ endorsement_count: 3 } as Partial<LinkEntry>))).toBe(3);
  });

  it("zero when no endorsements", () => {
    expect(linkWeight(mkLink())).toBe(0);
  });
});
