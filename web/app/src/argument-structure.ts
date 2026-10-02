/**
 * FR-85 argument structure: pure logic for computing dispute status
 * and building argument chains from the link graph. No React —
 * unit-testable.
 *
 * Miller's model (The Open Society and its Media, 1995):
 * - "What is the best argument against the thing I am reading?"
 * - "What is the best argument against that, in turn?" (recursion)
 * - Absence of a response is itself a signal
 * - Bidirectional visibility prevents school-division immunization
 */
import type { LinkEntry } from "./api/crdt_sync";

/** Disagreement link type ID (matches the server's builtin). */
export const DISAGREEMENT_TYPE = 3;

export type DisputeStatus =
  | "uncontested" // no Disagreement links to this work
  | "disputed" // Disagreement exists, no response
  | "rebutted" // at least one response to the disagreement
  | "standing"; // both sides have had their say (≥1 response each way)

export interface ArgumentChain {
  /** The Disagreement link that started this chain. */
  root: LinkEntry;
  /** Responses to the disagreement (links that reference the
   * disagreement's far-end work after the disagreement was made). */
  responses: LinkEntry[];
  /** Total endorsement weight across the chain. */
  weight: number;
  /** The dispute status of this specific chain. */
  status: DisputeStatus;
}

export function linkWeight(link: LinkEntry): number {
  return (link.endorsement_count ?? 0) + (link.endorsements?.length ?? 0);
}

function isDisagreement(link: LinkEntry): boolean {
  return (link.link_types ?? []).includes(DISAGREEMENT_TYPE);
}

/**
 * Heuristic: is `candidate` a response to `disagreement`?
 *
 * EXACT (FR-85 Phase 3): when the candidate carries
 * `responds_to = <disagreement link id>`, the match is exact.
 *
 * HEURISTIC fallback (legacy links without the property):
 * - is NOT itself a Disagreement (it's a rebuttal, clarification, etc.)
 * - originates from a different work than the disputed work
 * - points to the disagreement's far-end work (where the criticism lives)
 */
function isResponseTo(candidate: LinkEntry, disagreement: LinkEntry, disputedWorkId: number): boolean {
  // Exact property wins — set via link_set_responds_to.
  if (candidate.responds_to != null) {
    return candidate.responds_to === disagreement.link_id;
  }
  if (isDisagreement(candidate)) return false;
  if (candidate.link_id === disagreement.link_id) return false;
  // The response must target the work where the criticism lives
  // (the disagreement's ORIGIN work), not the disputed work itself.
  const criticismWork = disagreement.origin;
  if (candidate.destination === criticismWork || candidate.origin === criticismWork) {
    // Must not be from the disputed work (that would be a new
    // disagreement, not a response)
    if (candidate.origin !== disputedWorkId) return true;
  }
  return false;
}

/**
 * Compute the dispute status for a work from its incoming links.
 */
export function disputeStatus(
  workId: number,
  links: LinkEntry[],
): { status: DisputeStatus; chains: ArgumentChain[] } {
  const disagreements = links.filter((l) => isDisagreement(l) && l.destination === workId);
  if (disagreements.length === 0) {
    return { status: "uncontested", chains: [] };
  }

  const chains: ArgumentChain[] = disagreements.map((d) => {
    const responses = links.filter((l) => isResponseTo(l, d, workId));
    const weight = linkWeight(d) + responses.reduce((sum, r) => sum + linkWeight(r), 0);
    const status: DisputeStatus =
      responses.length === 0 ? "disputed" : "rebutted";
    return { root: d, responses, weight, status };
  });

  // Work-level status: the most severe chain state
  const anyDisputed = chains.some((c) => c.status === "disputed");
  const status: DisputeStatus = anyDisputed ? "disputed" : "rebutted";
  return { status, chains };
}

/**
 * Sort chains by endorsement weight (best-against first).
 * Ties broken by recency (higher link_id = more recent).
 */
export function sortChainsBestFirst(chains: ArgumentChain[]): ArgumentChain[] {
  return [...chains].sort((a, b) => {
    if (b.weight !== a.weight) return b.weight - a.weight;
    return b.root.link_id - a.root.link_id;
  });
}

/**
 * Check if a work has any incoming Disagreement links at all.
 * Used for the "uncontested" indicator on library rows.
 */
export function isUncontested(links: LinkEntry[], workId: number): boolean {
  return !links.some((l) => isDisagreement(l) && l.destination === workId);
}
