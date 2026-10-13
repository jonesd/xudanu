import type { LinkEndorser } from "./api/crdt_sync";

/** FR-87 (Miller §16.12 "Reputation-based filtering"): readers
 * filter their view of links both by who endorsed and by link-type.
 * Pure functions shared by the outgoing-links list and the backlinks
 * list — the incoming swamp filters exactly like the outgoing one. */

/** The minimal shape both LinkEntry and BacklinkEntry share once
 * FR-87 payloads land: the trust chain, its count, contest state. */
export interface EndorseableLink {
  endorsements?: LinkEndorser[];
  endorsement_count?: number;
  link_contested?: boolean;
}

/** "any" = no filter; "vouched" = at least one third-party vouch;
 * number = a specific endorser's club id. */
export type EndorserFilter = "any" | "vouched" | number;

/** Third-party vouchers only — the author's auto-endorsement is
 * provenance, not reputation (the movie-reviewer distinction). */
export function vouchersOf(link: EndorseableLink): LinkEndorser[] {
  return (link.endorsements ?? []).filter((e) => e.kind !== "author");
}

/** True when the link carries at least one third-party vouch.
 * Falls back to endorsement_count (author + n vouches) when the
 * payload carries counts but not the named list. */
export function hasVouch(link: EndorseableLink): boolean {
  const vouchers = vouchersOf(link);
  if (vouchers.length > 0) return true;
  return (link.endorsement_count ?? 0) > 1;
}

/** One distinct endorser option for the filter dropdown, vouch
 * counts across the given links. */
export interface EndorserOption {
  club_id: number;
  /** Display name; null renders as the club id. */
  name: string | null;
  count: number;
}

/** Distinct third-party endorsers across a link list, sorted by
 * vouch count (named-first within a tie — the trust claim is WHO
 * vouched; sybils can mint identities but can't become someone the
 * viewer already trusts). */
export function endorserOptions(links: EndorseableLink[]): EndorserOption[] {
  const byClub = new Map<number, EndorserOption>();
  for (const link of links) {
    const seen = new Set<number>();
    for (const v of vouchersOf(link)) {
      if (seen.has(v.club_id)) continue;
      seen.add(v.club_id);
      const existing = byClub.get(v.club_id);
      if (existing) {
        existing.count += 1;
        if (!existing.name && v.name) existing.name = v.name;
      } else {
        byClub.set(v.club_id, { club_id: v.club_id, name: v.name ?? null, count: 1 });
      }
    }
  }
  return [...byClub.values()].sort((a, b) => {
    if (b.count !== a.count) return b.count - a.count;
    const an = a.name ?? "";
    const bn = b.name ?? "";
    if (an !== bn) {
      // Named endorsers first; then lexicographic for stability.
      if (!an) return 1;
      if (!bn) return -1;
      return an.localeCompare(bn);
    }
    return a.club_id - b.club_id;
  });
}

/** The §16.12 predicate: does this link pass the endorser filter?
 * Intersect with the type filter at the call site. */
export function passesEndorserFilter(
  link: EndorseableLink,
  filter: EndorserFilter,
): boolean {
  if (filter === "any") return true;
  if (filter === "vouched") return hasVouch(link);
  return vouchersOf(link).some((v) => v.club_id === filter);
}

/** Apply the endorser filter to a link list. */
export function applyEndorserFilter<T extends EndorseableLink>(
  links: T[],
  filter: EndorserFilter,
): T[] {
  if (filter === "any") return links;
  return links.filter((l) => passesEndorserFilter(l, filter));
}
