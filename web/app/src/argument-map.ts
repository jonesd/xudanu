/**
 * FR-85 Phase 3b: the argument map — a VIEW over the link graph,
 * never a stored structure. Nodes are works; edges are the typed
 * links + responds_to properties we already have. The tree derives,
 * so it can never drift from the substrate.
 *
 * Design lineage: argument.io's visual grammar (children below,
 * branch left/right, argdown numbering) over Miller's model —
 * objections against a contention, responses to objections, counters
 * to responses, recursively. Endorsement weight rides every node
 * (Miller's "best argument against" = the heaviest branch).
 */
import type { LinkEntry } from "./api/crdt_sync";
import {
  DISAGREEMENT_TYPE,
  linkWeight,
  isResponseTo,
} from "./argument-structure";

export type MapNodeKind =
  | "contention" // the root under argument
  | "objection" // Disagreement edge — disputes its parent
  | "reason" // response/reference edge — supports or extends
  | "other" // untyped context link at the root
  | "ghost"; // reference to a node shown elsewhere (multi-parent)

export interface MapNode {
  /** Stable id: "root" or the entry link id. */
  id: string;
  /** The work this node presents (null for ghosts). */
  workId: number | null;
  /** Set on ghosts: id of the real node. */
  ghostOf?: string;
  /** The link that brought this work in (null on root). */
  entryLinkId: number | null;
  kind: MapNodeKind;
  label: string;
  /** Total endorsement weight (root + descendants carry their own). */
  weight: number;
  /** Argdown-style number: "1", "1.2", "1.2.1"… */
  number: string;
  depth: number;
  children: MapNode[];
}

export interface ArgumentMapResult {
  root: MapNode;
  /** Links that touched the root but belonged to no branch. */
  unclassified: number;
}

function isDisagreementLink(l: LinkEntry): boolean {
  return (l.link_types ?? []).includes(DISAGREEMENT_TYPE);
}

/** The far-end work of a link, from the perspective of `from`. */
function farWork(l: LinkEntry, from: number): number | null {
  if (l.origin === from) return l.destination;
  if (l.destination === from) return l.origin;
  return null;
}

function farTitle(l: LinkEntry, from: number): string {
  const originTitle = l.origin_title || (l.origin != null ? `Work 0x${l.origin.toString(16)}` : "");
  const destTitle =
    l.destination_title || (l.destination != null ? `Work 0x${l.destination.toString(16)}` : "");
  return l.origin === from ? destTitle : originTitle;
}

/**
 * Build the argument map for a root work.
 *
 * Branch semantics:
 * - Root's incoming Disagreements → objection children (red)
 * - Root's other touching links (in or out, no responds_to claim
 *   elsewhere) → other children (grey context)
 * - Any node's children: links whose responds_to names that node's
 *   entry link — exact Phase 3a semantics, arbitrary depth. Legacy
 *   links without the property fall back to the chain heuristic at
 *   the root level only (deeper levels need the property; the
 *   heuristic is not transitive).
 * - Cycles stop at the visited set; a work reached twice renders as
 *   a ghost reference at the second site.
 */
export function buildArgumentMap(
  rootWorkId: number,
  links: LinkEntry[],
  rootLabel?: string,
): ArgumentMapResult {
  const rootTitle =
    rootLabel ??
    links.find((l) => l.destination === rootWorkId)?.destination_title ??
    `Work 0x${rootWorkId.toString(16)}`;

  const root: MapNode = {
    id: "root",
    workId: rootWorkId,
    entryLinkId: null,
    kind: "contention",
    label: rootTitle,
    weight: 0,
    number: "1",
    depth: 0,
    children: [],
  };

  // Links claimed as children via responds_to — never also "other".
  const claimed = new Set<number>();
  for (const l of links) {
    if (l.responds_to != null) claimed.add(l.responds_to);
  }

  const seenWorks = new Set<number>([rootWorkId]);
  const seenLinks = new Set<number>();
  let unclassified = 0;

  function makeNode(
    entry: LinkEntry,
    nodeWorkId: number,
    label: string,
    kind: MapNodeKind,
    depth: number,
  ): MapNode {
    return {
      id: `L${entry.link_id}`,
      workId: nodeWorkId,
      entryLinkId: entry.link_id,
      kind,
      label,
      weight: linkWeight(entry),
      number: "",
      depth,
      children: [],
    };
  }

  // Children of a node whose entry link is `entryLink`: every link
  // responding to it. The responder's work is the child.
  function attachChildren(node: MapNode, entryLink: LinkEntry | null) {
    const responders = links.filter(
      (l) =>
        l.responds_to != null &&
        l.responds_to === (entryLink?.link_id ?? -1) &&
        !seenLinks.has(l.link_id) &&
        l.origin !== rootWorkId,
    );
    for (const r of responders) {
      seenLinks.add(r.link_id);
      const workId = r.origin;
      const label = r.origin_title || `Work 0x${workId.toString(16)}`;
      const kind: MapNodeKind = isDisagreementLink(r) ? "objection" : "reason";
      if (seenWorks.has(workId)) {
        node.children.push({
          id: `G${r.link_id}`,
          workId: null,
          entryLinkId: r.link_id,
          kind: "ghost",
          label,
          weight: linkWeight(r),
          number: "",
          depth: node.depth + 1,
          children: [],
        });
        continue;
      }
      seenWorks.add(workId);
      const child = makeNode(r, workId, label, kind, node.depth + 1);
      node.children.push(child);
      attachChildren(child, r);
    }
  }

  // Level 1: objections (incoming Disagreements). Exact property
  // children first; objections with no property responders fall back
  // to the legacy heuristic. A Disagreement that itself carries
  // responds_to is a NESTED counter — it never roots here.
  const touching = links.filter(
    (l) => l.origin === rootWorkId || l.destination === rootWorkId,
  );
  const handled = new Set<number>();
  for (const l of touching) {
    if (handled.has(l.link_id) || seenLinks.has(l.link_id)) continue;
    const isObj = isDisagreementLink(l) && l.destination === rootWorkId;
    if (!isObj) continue;
    if (l.responds_to != null) continue; // nests under its parent link
    handled.add(l.link_id);
    const workId = l.origin;
    const label = l.origin_title || `Work 0x${workId.toString(16)}`;
    if (seenWorks.has(workId)) {
      root.children.push({
        id: `G${l.link_id}`,
        workId: null,
        entryLinkId: l.link_id,
        kind: "ghost",
        label,
        weight: linkWeight(l),
        number: "",
        depth: 1,
        children: [],
      });
      continue;
    }
    seenWorks.add(workId);
    const node = makeNode(l, workId, label, "objection", 1);
    root.children.push(node);
    attachChildren(node, l);
    // Legacy fallback (no property anywhere in the chain): attach
    // heuristic responses one level deep — same logic as the Links
    // panel, so both surfaces agree on legacy data.
    if (node.children.length === 0) {
      for (const r of links) {
        if (seenLinks.has(r.link_id) || r.responds_to != null) continue;
        if (r.origin === rootWorkId) continue;
        if (!isResponseTo(r, l, rootWorkId)) continue;
        seenLinks.add(r.link_id);
        const child = makeNode(
          r,
          r.origin,
          r.origin_title || `Work 0x${r.origin.toString(16)}`,
          isDisagreementLink(r) ? "objection" : "reason",
          2,
        );
        node.children.push(child);
        attachChildren(child, r);
      }
    }
  }

  // Level 1 "other": every touching link not claimed and not an
  // objection (references, see-alsos, outbound links).
  for (const l of touching) {
    if (handled.has(l.link_id) || seenLinks.has(l.link_id)) continue;
    const isObj = isDisagreementLink(l) && l.destination === rootWorkId;
    if (isObj) {
      unclassified += 1;
      continue;
    }
    if (l.responds_to != null) {
      // A response to something outside this map — skip, it belongs
      // to another branch's argument.
      continue;
    }
    handled.add(l.link_id);
    const workId = farWork(l, rootWorkId);
    if (workId == null) continue;
    const label = farTitle(l, rootWorkId) || `Work 0x${workId.toString(16)}`;
    const kind: MapNodeKind = "other";
    if (seenWorks.has(workId)) {
      root.children.push({
        id: `G${l.link_id}`,
        workId: null,
        entryLinkId: l.link_id,
        kind: "ghost",
        label,
        weight: linkWeight(l),
        number: "",
        depth: 1,
        children: [],
      });
      continue;
    }
    seenWorks.add(workId);
    const node = makeNode(l, workId, label, kind, 1);
    root.children.push(node);
    attachChildren(node, l);
  }

  numberTree(root);
  return { root, unclassified };
}

/** Argdown numbering: root "1", child i of "1.2" is "1.2.i". */
function numberTree(root: MapNode): void {
  root.number = "1";
  const walk = (node: MapNode) => {
    node.children.forEach((child, i) => {
      child.number = `${node.number}.${i + 1}`;
      walk(child);
    });
  };
  walk(root);
}

// ── Layout ─────────────────────────────────────────────────────────

export interface PositionedNode {
  node: MapNode;
  x: number; // unit-space horizontal center
  y: number; // unit-space vertical (0 at top)
  width: number; // subtree width in units
}

export interface MapLayout {
  nodes: PositionedNode[];
  edges: { parentId: string; childId: string }[];
  width: number;
  height: number;
}

export interface LayoutOptions {
  nodeWidth?: number;
  levelHeight?: number;
}

/**
 * Classic leaf-width tree layout: every leaf occupies one unit;
 * parents center over their children's span. Children render below
 * parents, branching outward left-to-right (argument.io's shape).
 */
export function layoutMap(root: MapNode, _opts: LayoutOptions = {}): MapLayout {
  const nodes: PositionedNode[] = [];
  const edges: { parentId: string; childId: string }[] = [];

  function widthOf(node: MapNode): number {
    if (node.children.length === 0) return 1;
    const w = node.children.reduce((sum, c) => sum + widthOf(c), 0);
    return Math.max(1, w);
  }

  function place(node: MapNode, left: number): number {
    const width = widthOf(node);
    const center = left + width / 2;
    if (node.children.length === 0) {
      nodes.push({ node, x: center, y: node.depth, width });
      return center;
    }
    let cursor = left + (width - node.children.reduce((s, c) => s + widthOf(c), 0)) / 2;
    for (const child of node.children) {
      place(child, cursor);
      cursor += widthOf(child);
      edges.push({ parentId: node.id, childId: child.id });
    }
    nodes.push({ node, x: center, y: node.depth, width });
    return center;
  }

  place(root, 0);
  const width = Math.max(1, widthOf(root));
  const height = nodes.reduce((m, n) => Math.max(m, n.y), 0) + 1;
  return { nodes, edges, width, height };
}
