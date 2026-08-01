import { create } from "zustand";
import type { WorkListEntry, GraphNode, GraphEdge, WorkKind, License } from "../api/crdt_sync";

type WorkMeta = WorkListEntry;

interface WorkStore {
  // Data
  works: WorkMeta[];
  graphNodes: GraphNode[];
  graphEdges: GraphEdge[];
  kindCache: Map<number, WorkKind>;
  licenseCache: Map<number, License>;
  concepts: Array<{ work_id: number; title: string; link_count: number }>;

  // Actions
  setWorks: (works: WorkMeta[]) => void;
  setGraph: (nodes: GraphNode[], edges: GraphEdge[]) => void;
  setConcepts: (concepts: Array<{ work_id: number; title: string; link_count: number }>) => void;

  // Apply a kind change — updates kindCache + graph node
  applyKindChange: (workId: number, kind: WorkKind) => void;

  // Apply a license change
  applyLicenseChange: (workId: number, license: License) => void;

  // Apply a work update (star, archive, title change, etc.)
  applyWorkUpdate: (workId: number, changes: Partial<WorkMeta>) => void;

  // Apply a new work being created
  applyWorkCreated: (work: WorkMeta) => void;

  // Merge kind/license caches from graph data
  mergeFromGraph: (nodes: GraphNode[]) => void;

  // Force a complete refresh (clears all caches)
  invalidate: () => void;
}

export const useWorkStore = create<WorkStore>((set) => ({
  works: [],
  graphNodes: [],
  graphEdges: [],
  kindCache: new Map(),
  licenseCache: new Map(),
  concepts: [],

  setWorks: (works) => set({ works }),

  setGraph: (nodes, edges) => {
    const kindCache = new Map<number, WorkKind>();
    const licenseCache = new Map<number, License>();
    for (const node of nodes) {
      if (node.kind) kindCache.set(node.work_id, node.kind);
      if (node.license) licenseCache.set(node.work_id, node.license);
    }
    set({ graphNodes: nodes, graphEdges: edges, kindCache, licenseCache });
  },

  setConcepts: (concepts) => set({ concepts }),

  applyKindChange: (workId, kind) =>
    set((state) => {
      const kindCache = new Map(state.kindCache);
      kindCache.set(workId, kind);
      const graphNodes = state.graphNodes.map((n) =>
        n.work_id === workId ? { ...n, kind } : n,
      );
      const works = state.works.map((w) =>
        w.work_id === workId ? { ...w } : w,
      );
      return { kindCache, graphNodes, works };
    }),

  applyLicenseChange: (workId, license) =>
    set((state) => {
      const licenseCache = new Map(state.licenseCache);
      licenseCache.set(workId, license);
      const graphNodes = state.graphNodes.map((n) =>
        n.work_id === workId ? { ...n, license } : n,
      );
      return { licenseCache, graphNodes };
    }),

  applyWorkUpdate: (workId, changes) =>
    set((state) => ({
      works: state.works.map((w) =>
        w.work_id === workId ? { ...w, ...changes } : w,
      ),
    })),

  applyWorkCreated: (work) =>
    set((state) => ({
      works: [...state.works, work],
    })),

  mergeFromGraph: (nodes) =>
    set((state) => {
      const kindCache = new Map(state.kindCache);
      const licenseCache = new Map(state.licenseCache);
      for (const node of nodes) {
        if (node.kind) kindCache.set(node.work_id, node.kind);
        if (node.license) licenseCache.set(node.work_id, node.license);
      }
      return { kindCache, licenseCache };
    }),

  invalidate: () =>
    set({
      works: [],
      graphNodes: [],
      graphEdges: [],
      kindCache: new Map(),
      licenseCache: new Map(),
      concepts: [],
    }),
}));
