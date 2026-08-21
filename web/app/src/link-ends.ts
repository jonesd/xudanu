import type { LinkEntry, HyperRefPayload } from "./api/crdt_sync";

export interface LinkEnd {
  name: string;
  workId: number | null;
  excerpt: string;
  ref: HyperRefPayload;
}

/**
 * FR-40: flatten a link's ends into an ordered list. Left/Right keep
 * their historical names; custom named ends follow in payload order.
 * Cross-server ends (no local work) carry workId: null.
 */
export function linkEnds(link: LinkEntry): LinkEnd[] {
  const ends: LinkEnd[] = [];
  if (link.origin_ref) {
    ends.push({
      name: "origin",
      workId: link.origin_ref.work_context ?? link.origin,
      excerpt: link.origin_ref.excerpt ?? "",
      ref: link.origin_ref,
    });
  } else {
    ends.push({ name: "origin", workId: link.origin, excerpt: "", ref: null as unknown as HyperRefPayload });
  }
  if (link.destination_ref) {
    ends.push({
      name: "destination",
      workId: link.destination_ref.work_context ?? link.destination,
      excerpt: link.destination_ref.excerpt ?? "",
      ref: link.destination_ref,
    });
  } else {
    ends.push({ name: "destination", workId: link.destination, excerpt: "", ref: null as unknown as HyperRefPayload });
  }
  for (const [name, ref] of link.named_ends ?? []) {
    ends.push({
      name,
      workId: ref.work_context ?? null,
      excerpt: ref.excerpt ?? "",
      ref,
    });
  }
  return ends;
}

export function isMultiEnded(link: LinkEntry): boolean {
  return (link.named_ends?.length ?? 0) > 0;
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
