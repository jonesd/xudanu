/**
 * FR-84 split authoring: the pane registry.
 *
 * Pure logic (no React) so pane lifecycle is unit-testable: N works
 * open as panes beside the primary document, each remembering its
 * scroll position (long-doc positioning) and its held selection
 * (connection end). The registry never caps pane count — layout is
 * the user's call; soft guidance happens at the view layer.
 *
 * The EDITING focus is deliberately NOT registry state: exactly one
 * work is the CRDT-coupled primary at a time (the engine tracks a
 * single editing buffer). Promotion = the existing work-switch; the
 * registry just keeps the panes visible.
 */

import type { WorkPaneSelection } from "./components/WorkPane";

export interface PaneState {
  /** Stable identity for layout keys across renders. */
  key: string;
  workId: number;
  /** Long-doc positioning: last scroll offset, restored on reopen. */
  scrollTop: number;
  /** Held connection end from this pane (slice 2). */
  held: WorkPaneSelection | null;
}

let paneSeq = 0;
function nextKey(): string {
  paneSeq += 1;
  return `pane-${Date.now().toString(36)}-${paneSeq}`;
}

export function addPane(panes: PaneState[], workId: number): PaneState[] {
  // Dedupe: a work already pinned focuses its existing pane rather
  // than stacking a second view of the same document.
  if (panes.some((p) => p.workId === workId)) return panes;
  return [...panes, { key: nextKey(), workId, scrollTop: 0, held: null }];
}

export function removePane(panes: PaneState[], key: string): PaneState[] {
  return panes.filter((p) => p.key !== key);
}

export function setPaneScroll(panes: PaneState[], key: string, scrollTop: number): PaneState[] {
  return panes.map((p) => (p.key === key ? { ...p, scrollTop } : p));
}

export function setPaneHeld(
  panes: PaneState[],
  key: string,
  held: WorkPaneSelection | null,
): PaneState[] {
  return panes.map((p) => (p.key === key ? { ...p, held } : p));
}

/** All held ends across panes, oldest-first, with work ids attached. */
export function heldEnds(panes: PaneState[]): Array<{
  workId: number;
  key: string;
  start: number;
  end: number;
  text: string;
}> {
  return panes
    .filter((p) => p.held != null && p.held.start < p.held.end)
    .map((p) => ({ workId: p.workId, key: p.key, ...p.held! }));
}

/** Closing a pane releases its held end (kept in the others). */
export function paneForWork(panes: PaneState[], workId: number): PaneState | undefined {
  return panes.find((p) => p.workId === workId);
}
