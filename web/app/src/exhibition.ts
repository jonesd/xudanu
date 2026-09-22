// Exhibitions: a grouped set of works with a cover.
//
// Model: an exhibition is a COVER WORK plus "gathers"-typed links
// from the cover to each member (containment as connection — no new
// entity, no hierarchy). The unit is referenceable from anywhere
// (it's a work), membership is bidirectional for free (every member's
// backlinks name their exhibition), and exhibitions of exhibitions
// are just covers gathering covers.
//
// The boundary is an INDICATION, never a barrier: crossing in or out
// of the member set raises a notice so the reader always knows which
// grouped unit they are inside.

import type { CrdtSyncClient } from "./api/crdt_sync";

/** The membership link type, looked up by NAME ("Gathers") — link
 * type ids are grounded in their definition work ids (the work IS
 * the type), which vary per server. Unresolvable -> no membership ->
 * no boundary indication (safe silence). */
const GATHERS_TYPE_NAME = "Gathers";
let gathersTypeId: number | null | undefined;

async function resolveGathersTypeId(client: CrdtSyncClient): Promise<number | null> {
  if (gathersTypeId !== undefined) return gathersTypeId;
  try {
    const types = await client.linkTypeList();
    const hit = types.find((t) => t.name === GATHERS_TYPE_NAME);
    gathersTypeId = hit ? hit.type_id : null;
  } catch {
    gathersTypeId = null;
  }
  return gathersTypeId;
}

export interface Exhibition {
  coverWorkId: number;
  title: string;
  memberIds: Set<number>;
}

/** Pure boundary transition: what indication (if any) crossing from
 * one work to another deserves. Same exhibition or both outside ->
 * silence; every crossing between sets speaks once. */
export function exhibitionTransition(
  prev: Exhibition | null,
  next: Exhibition | null,
): { kind: "entering" | "leaving"; title: string } | null {
  if (prev === next) return null; // same exhibition (or both null)
  if (prev && next && prev.coverWorkId === next.coverWorkId) return null;
  if (next && !prev) return { kind: "entering", title: next.title };
  if (prev && !next) return { kind: "leaving", title: prev.title };
  if (prev && next) {
    // Crossing directly between two exhibitions: say both, leaving first.
    return { kind: "leaving", title: prev.title };
  }
  return null;
}

// ─── membership resolution (cached, lazy) ─────────────────────────
// coverByMember: memberWorkId -> Exhibition (resolved via incoming
// gathers links). Members themselves are not cached per-cover beyond
// the Exhibition object.

const coverByMember = new Map<number, Exhibition | null>();

async function resolveExhibition(
  client: CrdtSyncClient,
  workId: number,
): Promise<Exhibition | null> {
  if (coverByMember.has(workId)) return coverByMember.get(workId) ?? null;
  let result: Exhibition | null = null;
  try {
    const gathersType = await resolveGathersTypeId(client);
    if (gathersType != null) {
      const links = await client.linkListForWork(workId);
      // A work belongs to an exhibition EITHER as a member (incoming
      // gathers link) OR as the cover itself (outgoing gathers links).
      const incoming = links.find(
        (l) =>
          l.destination === workId &&
          (l.link_types ?? []).includes(gathersType),
      );
      const outgoing = links.filter(
        (l) =>
          l.origin === workId &&
          (l.link_types ?? []).includes(gathersType),
      );
      const coverWorkId = incoming ? incoming.origin : outgoing.length > 0 ? workId : null;
      if (coverWorkId != null) {
        const coverLinks = coverWorkId === workId
          ? links // already fetched: this work IS the cover
          : await client.linkListForWork(coverWorkId);
        const titleLink = coverLinks.find(
          (l) => l.origin === coverWorkId && (l.link_types ?? []).includes(gathersType),
        );
        const title = titleLink?.origin_title || `Work 0x${coverWorkId.toString(16)}`;
        const memberIds = new Set<number>([
          coverWorkId,
          ...coverLinks
            .filter(
              (l) =>
                l.origin === coverWorkId &&
                (l.link_types ?? []).includes(gathersType),
            )
            .map((l) => l.destination)
            .filter((d): d is number => d != null),
        ]);
        result = { coverWorkId, title, memberIds };
      }
    }
  } catch {
    result = null; // transient fetch failure: treat as "no exhibition"
  }
  coverByMember.set(workId, result);
  return result;
}

/** Invalidate cached membership (after exhibition edits). */
export function forgetExhibitionMembership(workId?: number): void {
  if (workId == null) coverByMember.clear();
  else coverByMember.delete(workId);
}

/** Boundary check for a work switch: runs the transition and hands
 * the indication text to the callback (never blocks navigation). */
export async function checkExhibitionCrossing(
  client: CrdtSyncClient,
  prevWorkId: number | null,
  nextWorkId: number,
): Promise<string | null> {
  if (prevWorkId == null || prevWorkId === nextWorkId) return null;
  const [prev, next] = await Promise.all([
    resolveExhibition(client, prevWorkId),
    resolveExhibition(client, nextWorkId),
  ]);
  const t = exhibitionTransition(prev, next);
  if (!t) return null;
  return t.kind === "entering"
    ? `Entering ${t.title}`
    : `Leaving ${t.title}`;
}
