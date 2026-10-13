import { describe, it, expect, beforeEach } from "vitest";
import { useWorkStore } from "../store/work-store";
import type { WorkListEntry, GraphNode } from "../api/crdt_sync";

const work = (id: number, over: Partial<WorkListEntry> = {}): WorkListEntry =>
  ({ work_id: id, title: `w${id}`, revision_count: 1, owner: null, ...over }) as unknown as WorkListEntry;

const node = (id: number, over: Partial<GraphNode> = {}): GraphNode =>
  ({ work_id: id, title: `n${id}`, revision_count: 0, is_starred: false, is_source: false, ...over }) as unknown as GraphNode;

describe("work-store", () => {
  beforeEach(() => {
    useWorkStore.getState().invalidate();
  });

  it("setWorks / setGraph populate state and derive kind+license caches", () => {
    useWorkStore.getState().setWorks([work(1), work(2)]);
    expect(useWorkStore.getState().works).toHaveLength(2);

    useWorkStore.getState().setGraph(
      [node(1, { kind: "concept", license: "cc-by" }), node(2)],
      [],
    );
    const s = useWorkStore.getState();
    expect(s.kindCache.get(1)).toBe("concept");
    expect(s.licenseCache.get(1)).toBe("cc-by");
    expect(s.kindCache.has(2)).toBe(false);
  });

  it("applyKindChange updates cache and graph node", () => {
    useWorkStore.getState().setGraph([node(1, { kind: "document" })], []);
    useWorkStore.getState().applyKindChange(1, "note");
    const s = useWorkStore.getState();
    expect(s.kindCache.get(1)).toBe("note");
    expect(s.graphNodes[0].kind).toBe("note");
  });

  it("applyLicenseChange updates cache and graph node", () => {
    useWorkStore.getState().setGraph([node(1, { license: "mit" as never })], []);
    useWorkStore.getState().applyLicenseChange(1, "cc-by-sa" as never);
    const s = useWorkStore.getState();
    expect(s.licenseCache.get(1)).toBe("cc-by-sa");
    expect(s.graphNodes[0].license).toBe("cc-by-sa");
  });

  it("applyWorkUpdate merges partial changes; unknown ids untouched", () => {
    useWorkStore.getState().setWorks([work(1, { title: "old" }), work(2)]);
    useWorkStore.getState().applyWorkUpdate(1, { title: "new" });
    const works = useWorkStore.getState().works;
    expect(works[0].title).toBe("new");
    expect(works[1].title).toBe("w2");
  });

  it("applyWorkCreated appends", () => {
    useWorkStore.getState().setWorks([work(1)]);
    useWorkStore.getState().applyWorkCreated(work(9));
    expect(useWorkStore.getState().works.map((w) => w.work_id)).toEqual([1, 9]);
  });

  it("mergeFromGraph adds without clobbering existing cache entries", () => {
    useWorkStore.getState().setGraph([node(1, { kind: "note" })], []);
    useWorkStore.getState().mergeFromGraph([node(1), node(2, { kind: "concept" })]);
    const s = useWorkStore.getState();
    expect(s.kindCache.get(1)).toBe("note"); // kept: merge omits absent kinds
    expect(s.kindCache.get(2)).toBe("concept");
  });

  it("setConcepts and invalidate", () => {
    useWorkStore.getState().setConcepts([{ work_id: 3, title: "c", link_count: 4 }]);
    expect(useWorkStore.getState().concepts).toHaveLength(1);
    useWorkStore.getState().setWorks([work(1)]);
    useWorkStore.getState().setGraph([node(1)], []);
    useWorkStore.getState().invalidate();
    const s = useWorkStore.getState();
    expect(s.works).toEqual([]);
    expect(s.graphNodes).toEqual([]);
    expect(s.kindCache.size).toBe(0);
    expect(s.concepts).toEqual([]);
  });
});
