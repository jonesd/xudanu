/**
 * FR-86 pure logic: LLM connection proposals. No React — the state
 * model, far-end resolution, excerpt re-anchoring, and dedup are
 * unit-testable.
 *
 * Design principle (FR-86): the LLM is just another reader. It
 * proposes; the human confirms; confirmed proposals become ORDINARY
 * links that compete in the same endorsement marketplace as any
 * other link. Proposals are never links themselves.
 */
import type { LlmConnectionProposal, WorkListEntry } from "./api/crdt_sync";

export const LINK_TYPE_NAMES: Record<number, string> = {
  1: "Comment",
  2: "Reference",
  3: "Disagreement",
  4: "Quotation",
  5: "See Also",
};

/** Mirrors WorkPane/CollaborativeEditor's palette — proposals speak
 * the same visual language as real links. */
export const LINK_TYPE_COLORS: Record<number, string> = {
  1: "#58a6ff", // Comment — blue
  2: "#3fb950", // Reference — green
  3: "#f85149", // Disagreement — red
  4: "#a371f7", // Quotation — purple
  5: "#d29922", // See Also — amber
};

export function linkTypeName(typeId: number): string {
  return LINK_TYPE_NAMES[typeId] ?? "Type";
}

export function linkTypeColor(typeId: number): string {
  return LINK_TYPE_COLORS[typeId] ?? "#8a8a96";
}

export type ProposalStatus = "pending" | "confirming" | "confirmed" | "rejected" | "error";

/** A proposal card's full UI state. */
export interface ProposalCard {
  /** Stable identity: excerpt + far end + type. */
  key: string;
  excerpt: string;
  /** Server-resolved span (hint for client re-anchoring). */
  start: number;
  end: number;
  typeId: number;
  reasoning: string;
  farEndTitle: string | null;
  status: ProposalStatus;
  /** Set on confirm success (the created link id) or on error. */
  linkId?: number;
  error?: string;
}

export function toCard(p: LlmConnectionProposal): ProposalCard {
  return {
    key: `${p.excerpt}|${p.far_end_title ?? ""}|${p.type_id}`,
    excerpt: p.excerpt,
    start: p.start,
    end: p.end,
    typeId: p.type_id,
    reasoning: p.reasoning,
    farEndTitle: p.far_end_title,
    status: "pending",
  };
}

/**
 * Resolve a proposal's far_end_title to a work id from the library.
 * Exact case-insensitive match first, then prefix (LLMs truncate
 * titles). The current work is excluded — a self-link is never the
 * intent.
 */
export function resolveFarEndWork(
  title: string | null,
  workList: Pick<WorkListEntry, "work_id" | "title">[],
  currentWorkId: number | null,
): number | null {
  if (!title) return null;
  const wanted = title.trim().toLowerCase();
  if (!wanted) return null;
  const candidates = workList.filter((w) => w.work_id !== currentWorkId);
  const exact = candidates.find(
    (w) => (w.title || "").trim().toLowerCase() === wanted,
  );
  if (exact) return exact.work_id;
  const prefix = candidates.find((w) => {
    const t = (w.title || "").trim().toLowerCase();
    return t.startsWith(wanted) || wanted.startsWith(t);
  });
  return prefix ? prefix.work_id : null;
}

/**
 * Re-anchor an LLM excerpt in the client's copy of the work text.
 * The server resolved start/end against ITS text via exact match;
 * UTF-16 (client) vs byte (server) offsets can diverge and revisions
 * can land between proposal and confirm — so on confirm we re-anchor
 * defensively: exact match from the hint, then global exact, then
 * whitespace-tolerant. Returns null when the passage truly isn't
 * there anymore (card shows an error instead of creating a
 * misanchored link).
 */
export function anchorExcerpt(
  excerpt: string,
  text: string,
  hintStart: number,
): { start: number; end: number } | null {
  if (!excerpt) return null;
  const fromHint = text.indexOf(excerpt, Math.max(0, hintStart - 20));
  if (fromHint !== -1) return { start: fromHint, end: fromHint + excerpt.length };
  const global = text.indexOf(excerpt);
  if (global !== -1) return { start: global, end: global + excerpt.length };
  // Whitespace-tolerant final pass: collapse runs of whitespace on
  // both sides and scan by code points.
  const norm = (s: string) => s.replace(/\s+/g, " ");
  const needle = norm(excerpt).toLowerCase();
  if (!needle) return null;
  const collapsed = norm(text).toLowerCase();
  const at = collapsed.indexOf(needle);
  if (at === -1) return null;
  // Map back: walk the original text counting non-collapsed chars.
  let ci = 0;
  let start = -1;
  let end = -1;
  let i = 0;
  while (i < text.length) {
    while (i < text.length && /\s/.test(text[i]) && /\s/.test(text[i + 1] ?? "")) i++;
    if (i >= text.length) break;
    if (ci === at) start = i;
    if (ci === at + needle.length - 1) {
      end = i + 1;
      break;
    }
    ci++;
    i++;
  }
  if (start !== -1 && end !== -1) return { start, end };
  return null;
}

/** An existing link seen through the same lens as proposals — for
 * dedup against links that already exist (belt and braces; the
 * server also filters). */
export interface ExistingLinkLike {
  excerpt?: string | null;
  farTitle?: string | null;
}

/**
 * Drop proposals that duplicate each other or an existing link.
 * Duplicate = same normalized excerpt AND same far end (or both
 * same-document).
 */
export function dedupeProposals(
  cards: ProposalCard[],
  existing: ExistingLinkLike[] = [],
): ProposalCard[] {
  const seen = new Set<string>();
  for (const e of existing) {
    if (!e.excerpt) continue;
    seen.add(`${e.excerpt.replace(/\s+/g, " ").trim().toLowerCase()}|${(e.farTitle ?? "").toLowerCase()}`);
  }
  const out: ProposalCard[] = [];
  for (const c of cards) {
    const k = `${c.excerpt.replace(/\s+/g, " ").trim().toLowerCase()}|${(c.farEndTitle ?? "").toLowerCase()}`;
    if (seen.has(k)) continue;
    seen.add(k);
    out.push(c);
  }
  return out;
}
