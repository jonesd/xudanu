import { describe, it, expect } from "vitest";
import { buildArgumentMap, layoutMap } from "../argument-map";
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
const dis = (over: Partial<LinkEntry>) => mkLink({ link_types: [3], ...over });

describe("buildArgumentMap", () => {
  it("renders the root contention alone when no links touch it", () => {
    const { root } = buildArgumentMap(200, [mkLink({ origin: 300, destination: 400 })], "The Plan");
    expect(root.kind).toBe("contention");
    expect(root.label).toBe("The Plan");
    expect(root.number).toBe("1");
    expect(root.children).toHaveLength(0);
  });

  it("incoming Disagreements become objection children", () => {
    const { root } = buildArgumentMap(200, [
      dis({ link_id: 1, origin: 100, destination: 200, origin_title: "Dan's Requirement" }),
    ]);
    expect(root.children).toHaveLength(1);
    const obj = root.children[0];
    expect(obj.kind).toBe("objection");
    expect(obj.label).toBe("Dan's Requirement");
    expect(obj.number).toBe("1.1");
    expect(obj.workId).toBe(100);
  });

  it("responds_to nests responses under their objection, arbitrary depth", () => {
    const links = [
      dis({ link_id: 10, origin: 100, destination: 200, origin_title: "Objection" }),
      mkLink({ link_id: 11, origin: 300, destination: 100, link_types: [2],
        origin_title: "Rebuttal", responds_to: 10 }),
      mkLink({ link_id: 12, origin: 400, destination: 300, link_types: [2],
        origin_title: "Counter", responds_to: 11 }),
    ];
    const { root } = buildArgumentMap(200, links);
    expect(root.children).toHaveLength(1);
    const obj = root.children[0];
    expect(obj.kind).toBe("objection");
    expect(obj.children).toHaveLength(1);
    expect(obj.children[0].kind).toBe("reason");
    expect(obj.children[0].label).toBe("Rebuttal");
    expect(obj.children[0].number).toBe("1.1.1");
    expect(obj.children[0].children).toHaveLength(1);
    expect(obj.children[0].children[0].label).toBe("Counter");
    expect(obj.children[0].children[0].number).toBe("1.1.1.1");
  });

  it("a Disagreement response is an objection (counter-dispute)", () => {
    const links = [
      dis({ link_id: 10, origin: 100, destination: 200 }),
      dis({ link_id: 11, origin: 300, destination: 100, responds_to: 10, origin_title: "Counter-dispute" }),
    ];
    const { root } = buildArgumentMap(200, links);
    expect(root.children[0].children[0].kind).toBe("objection");
  });

  it("legacy responses attach via the heuristic when no responds_to exists", () => {
    const links = [
      dis({ link_id: 1, origin: 100, destination: 200, origin_title: "Critic" }),
      // Heuristic shape: reference from a third work to the criticism
      mkLink({ link_id: 2, origin: 300, destination: 100, link_types: [2], origin_title: "Rebuttal" }),
    ];
    const { root } = buildArgumentMap(200, links);
    expect(root.children[0].label).toBe("Critic");
    expect(root.children[0].children).toHaveLength(1);
    expect(root.children[0].children[0].label).toBe("Rebuttal");
  });

  it("unclaimed touching links become grey other children", () => {
    const links = [
      mkLink({ link_id: 5, origin: 500, destination: 200, link_types: [2], origin_title: "Budget Note" }),
      mkLink({ link_id: 6, origin: 200, destination: 600, link_types: [5], destination_title: "See Also Target" }),
    ];
    const { root } = buildArgumentMap(200, links);
    expect(root.children).toHaveLength(2);
    expect(root.children.every((c) => c.kind === "other")).toBe(true);
    const labels = root.children.map((c) => c.label).sort();
    expect(labels).toEqual(["Budget Note", "See Also Target"]);
  });

  it("a work appearing twice renders as a ghost at the second site", () => {
    const links = [
      dis({ link_id: 1, origin: 100, destination: 200, origin_title: "Critic A" }),
      dis({ link_id: 2, origin: 300, destination: 200, origin_title: "Critic B" }),
      // Same responder work answers both objections via two links
      mkLink({ link_id: 3, origin: 400, destination: 100, link_types: [2], responds_to: 1, origin_title: "Shared Rebuttal" }),
      mkLink({ link_id: 4, origin: 400, destination: 300, link_types: [2], responds_to: 2, origin_title: "Shared Rebuttal" }),
    ];
    const { root } = buildArgumentMap(200, links);
    const real = root.children.flatMap((c) => c.children).find((n) => n.kind === "reason");
    const ghost = root.children.flatMap((c) => c.children).find((n) => n.kind === "ghost");
    expect(real).toBeTruthy();
    expect(ghost).toBeTruthy();
    expect(ghost!.label).toBe("Shared Rebuttal");
    expect(ghost!.workId).toBeNull();
  });

  it("cycles terminate: A objects to root, C responds, A responds back", () => {
    const links = [
      dis({ link_id: 1, origin: 100, destination: 200 }),
      mkLink({ link_id: 2, origin: 300, destination: 100, link_types: [2], responds_to: 1 }),
      // Cycle: A (already shown as the objection) responds to C
      mkLink({ link_id: 3, origin: 100, destination: 300, link_types: [2], responds_to: 2 }),
    ];
    const { root } = buildArgumentMap(200, links);
    expect(root.children).toHaveLength(1);
    const child = root.children[0].children[0];
    expect(child.entryLinkId).toBe(2);
    // A returns as a ghost reference, not a second copy — the cycle
    // is closed visually without infinite descent.
    expect(child.children).toHaveLength(1);
    expect(child.children[0].kind).toBe("ghost");
    expect(child.children[0].label).toBe(root.children[0].label);
  });

  it("objection weight carries its endorsements", () => {
    const links = [
      dis({ link_id: 1, origin: 100, destination: 200, endorsement_count: 3 }),
    ];
    const { root } = buildArgumentMap(200, links);
    expect(root.children[0].weight).toBe(3);
  });

  it("numbers argdown-style across branches", () => {
    const links = [
      dis({ link_id: 1, origin: 100, destination: 200 }),
      dis({ link_id: 2, origin: 300, destination: 200 }),
      mkLink({ link_id: 3, origin: 400, destination: 100, link_types: [2], responds_to: 1 }),
    ];
    const { root } = buildArgumentMap(200, links);
    expect(root.children.map((c) => c.number)).toEqual(["1.1", "1.2"]);
    expect(root.children[0].children[0].number).toBe("1.1.1");
  });
});

describe("layoutMap", () => {
  const leaf = (id: string, depth = 0): never => ({ id, depth, children: [] }) as never;

  it("a lone root occupies one unit at the origin", () => {
    const { root } = buildArgumentMap(200, [], "Solo");
    const layout = layoutMap(root);
    expect(layout.nodes).toHaveLength(1);
    expect(layout.nodes[0].x).toBe(0.5);
    expect(layout.nodes[0].y).toBe(0);
    expect(layout.width).toBe(1);
    expect(layout.height).toBe(1);
    expect(layout.edges).toHaveLength(0);
  });

  it("one child renders directly below the root", () => {
    const links = [dis({ link_id: 1, origin: 100, destination: 200 })];
    const { root } = buildArgumentMap(200, links);
    const layout = layoutMap(root);
    expect(layout.nodes).toHaveLength(2);
    const rootNode = layout.nodes.find((n) => n.node.id === "root")!;
    const child = layout.nodes.find((n) => n.node.id === "L1")!;
    expect(child.x).toBe(rootNode.x);
    expect(child.y).toBe(1);
    expect(layout.edges).toEqual([{ parentId: "root", childId: "L1" }]);
  });

  it("two children branch left and right, parent centered", () => {
    const links = [
      dis({ link_id: 1, origin: 100, destination: 200 }),
      dis({ link_id: 2, origin: 300, destination: 200 }),
    ];
    const { root } = buildArgumentMap(200, links);
    const layout = layoutMap(root);
    const rootNode = layout.nodes.find((n) => n.node.id === "root")!;
    const a = layout.nodes.find((n) => n.node.id === "L1")!;
    const b = layout.nodes.find((n) => n.node.id === "L2")!;
    expect(a.x).toBeLessThan(rootNode.x);
    expect(b.x).toBeGreaterThan(rootNode.x);
    expect(rootNode.x).toBeCloseTo((a.x + b.x) / 2, 10);
    expect(layout.width).toBe(2);
  });

  it("uneven subtrees: single-child branch keeps unit width", () => {
    const links = [
      dis({ link_id: 1, origin: 100, destination: 200 }),
      dis({ link_id: 2, origin: 300, destination: 200 }),
      mkLink({ link_id: 3, origin: 400, destination: 100, link_types: [2], responds_to: 1 }),
      mkLink({ link_id: 4, origin: 500, destination: 300, link_types: [2], responds_to: 2 }),
      mkLink({ link_id: 5, origin: 600, destination: 300, link_types: [2], responds_to: 2 }),
    ];
    const { root } = buildArgumentMap(200, links);
    const layout = layoutMap(root);
    // Left branch: 1 leaf under objection; right: 2 leaves → width 3
    expect(layout.width).toBe(3);
    expect(layout.height).toBe(3);
    // Every edge connects consecutive depths
    for (const e of layout.edges) {
      const p = layout.nodes.find((n) => n.node.id === e.parentId)!;
      const c = layout.nodes.find((n) => n.node.id === e.childId)!;
      expect(c.node.depth).toBe(p.node.depth + 1);
    }
  });
});
