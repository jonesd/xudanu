import type { LinkEntry, HyperRefPayload } from "./api/crdt_sync";

export interface LinkEnd {
  name: string;
  workId: number | null;
  excerpt: string;
  ref: HyperRefPayload;
  /** FR-40 S6: all attachments when this end is a gathered
   * end-set (undefined = singleton end, ref is the attachment). */
  attachments?: HyperRefPayload[];
}

/** Server end names on the wire vs the local render names. */
function wireNameToLocal(name: string): string {
  if (name === "LeftEnd") return "origin";
  if (name === "RightEnd") return "destination";
  return name;
}

function endSetMap(link: LinkEntry): Map<string, HyperRefPayload[]> {
  const map = new Map<string, HyperRefPayload[]>();
  for (const [name, attachments] of link.end_sets ?? []) {
    if (attachments && attachments.length > 1) {
      map.set(name, attachments);
    }
  }
  return map;
}

/**
 * FR-40: flatten a link's ends into an ordered list. Left/Right keep
 * their historical names; custom named ends follow in payload order.
 * Cross-server ends (no local work) carry workId: null.
 *
 * FR-40 S6: an end present in `end_sets` (more than one attachment)
 * carries the COMPLETE attachment list; workId/excerpt reflect the
 * first attachment (the compat view).
 */
export function linkEnds(link: LinkEntry): LinkEnd[] {
  const sets = endSetMap(link);
  const ends: LinkEnd[] = [];
  if (link.origin_ref) {
    const gathered = sets.get("LeftEnd");
    ends.push({
      name: "origin",
      workId: link.origin_ref.work_context ?? link.origin,
      excerpt: link.origin_ref.excerpt ?? "",
      ref: link.origin_ref,
      ...(gathered ? { attachments: gathered } : {}),
    });
  } else {
    const gathered = sets.get("LeftEnd");
    ends.push({
      name: "origin",
      workId: gathered?.[0]?.work_context ?? link.origin,
      excerpt: gathered?.[0]?.excerpt ?? "",
      ref: gathered?.[0] ?? (null as unknown as HyperRefPayload),
      ...(gathered ? { attachments: gathered } : {}),
    });
  }
  if (link.destination_ref) {
    const gathered = sets.get("RightEnd");
    ends.push({
      name: "destination",
      workId: link.destination_ref.work_context ?? link.destination,
      excerpt: link.destination_ref.excerpt ?? "",
      ref: link.destination_ref,
      ...(gathered ? { attachments: gathered } : {}),
    });
  } else {
    const gathered = sets.get("RightEnd");
    ends.push({
      name: "destination",
      workId: gathered?.[0]?.work_context ?? link.destination,
      excerpt: gathered?.[0]?.excerpt ?? "",
      ref: gathered?.[0] ?? (null as unknown as HyperRefPayload),
      ...(gathered ? { attachments: gathered } : {}),
    });
  }
  for (const [name, ref] of link.named_ends ?? []) {
    const gathered = sets.get(name);
    ends.push({
      name,
      workId: ref.work_context ?? null,
      excerpt: ref.excerpt ?? "",
      ref,
      ...(gathered ? { attachments: gathered } : {}),
    });
  }
  // end_sets entries that are NOT origin/destination/named (possible
  // after partial payload evolution) still surface.
  const seen = new Set(ends.map((e) => e.name));
  for (const [wireName, attachments] of sets) {
    const local = wireNameToLocal(wireName);
    if (!seen.has(local) && attachments && attachments.length > 0) {
      ends.push({
        name: local,
        workId: attachments[0]?.work_context ?? null,
        excerpt: attachments[0]?.excerpt ?? "",
        ref: attachments[0],
        attachments,
      });
    }
  }
  return ends;
}

export function isMultiEnded(link: LinkEntry): boolean {
  return (link.named_ends?.length ?? 0) > 0;
}

/** FR-40 S6: an end with more than one attachment. */
export function isGatheredEnd(end: LinkEnd): boolean {
  return (end.attachments?.length ?? 0) > 1;
}

/** FR-40 S6: number of passages in an end (1 for singletons). */
export function endSetCount(end: LinkEnd): number {
  return end.attachments?.length ?? 1;
}

/** FR-40 S7: the targeted link id when this ref attaches to a
 * link (kind == "link_attachment"), else null. */
export function linkAttachmentTarget(ref: HyperRefPayload | null | undefined): number | null {
  if (!ref || ref.kind !== "link_attachment") return null;
  return ref.link_attachment ?? null;
}

/**
 * FR-40 B.1: the stable identity key for a link's rendering
 * (colour = link). Derived from the link id only — stable within
 * a session, independent of span positions and end order.
 */
export function linkIdentityKey(linkId: number): string {
  return `link-${linkId}`;
}

/**
 * FR-40 L2 (B.2 tier-1): the gathered ends whose members cover a
 * position on this work — the bottom-bar strip's data. Pure;
 * driven from link data, never marker DOM.
 */
export interface EndSetTouch {
  linkId: number;
  /** Local end name (origin/destination/custom). */
  endName: string;
  /** 1-based index of the covering member. */
  index: number;
  total: number;
  /** This work's member spans of the end (jump targets). */
  memberSpans: Array<{ start: number; end: number }>;
}

export function endSetsTouchingPosition(
  links: LinkEntry[],
  workId: number,
  pos: number | null | undefined,
): EndSetTouch[] {
  if (pos == null) return [];
  const touches: EndSetTouch[] = [];
  for (const link of links) {
    for (const end of linkEnds(link)) {
      if (!isGatheredEnd(end)) continue;
      const memberSpans: Array<{ start: number; end: number }> = [];
      let covering: number | null = null;
      (end.attachments ?? []).forEach((ref, i) => {
        if (ref.work_context !== workId) return;
        if (
          typeof ref.start_position === "number" &&
          typeof ref.end_position === "number" &&
          ref.end_position > ref.start_position
        ) {
          memberSpans.push({ start: ref.start_position, end: ref.end_position });
          if (pos >= ref.start_position && pos < ref.end_position) {
            covering = i + 1;
          }
        }
      });
      if (covering !== null && memberSpans.length > 0) {
        touches.push({
          linkId: link.link_id,
          endName: end.name,
          index: covering as number,
          total: end.attachments?.length ?? memberSpans.length,
          memberSpans,
        });
      }
    }
  }
  return touches;
}

export interface GatheredSpan {
  endName: string;
  workContext: number;
  excerpt?: string;
  start?: number | null;
  end?: number | null;
  linkAttachment?: number | null;
}

export type EndSetOperation =
  | { op: "add-end"; endName: string; span: GatheredSpan }
  | { op: "add-attachment"; endName: string; span: GatheredSpan };

/**
 * FR-40 S6 gather planning: given the user's gathered rows, plan
 * the wire ops — the FIRST span of each end name creates the end
 * (link_add_end), subsequent spans attach to it
 * (link_end_add_attachment). Pure; the LinkCreator wiring is thin.
 */
export function planEndSetOperations(spans: GatheredSpan[]): EndSetOperation[] {
  const seen = new Set<string>();
  const ops: EndSetOperation[] = [];
  for (const span of spans) {
    if (!span.endName) continue;
    if (seen.has(span.endName)) {
      ops.push({ op: "add-attachment", endName: span.endName, span });
    } else {
      seen.add(span.endName);
      ops.push({ op: "add-end", endName: span.endName, span });
    }
  }
  return ops;
}

export function multiEndWorkIds(link: LinkEntry): number[] {
  const ids = new Set<number>();
  for (const end of linkEnds(link)) {
    if (end.workId !== null) ids.add(end.workId);
  }
  return Array.from(ids);
}

export type NotifyStatus =
  | { kind: "none" }
  | { kind: "accepted" }
  | { kind: "rejected"; reason: string }
  | { kind: "error"; reason: string };

/**
 * FR-40 sender feedback: classify a link's cross-server notify
 * outcome for display. "rejected" = the receiving server answered
 * and refused; "error" = we could not reach it.
 */
export function notifyStatus(link: LinkEntry): NotifyStatus {
  if (link.cross_server_notify_accepted === null || link.cross_server_notify_accepted === undefined) {
    return { kind: "none" };
  }
  if (link.cross_server_notify_accepted) {
    return { kind: "accepted" };
  }
  const reason = link.cross_server_notify_error ?? "unknown reason";
  if (/reach|connect|timeout|refus|DNS/i.test(reason)) {
    return { kind: "error", reason };
  }
  return { kind: "rejected", reason };
}
