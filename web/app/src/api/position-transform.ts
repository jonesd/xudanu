import type { TextDeltaOp } from "./text_buffer";

/**
 * Position transform over CRDT delta ops: rebase a char position or
 * span from the OLD document coordinates into the NEW document
 * coordinates produced by applying the ops. The pure foundation for
 * overlay rebasing (annotations, attribution, link markers — step 2)
 * and cursor rebasing (step 1) without a server round-trip.
 *
 * Ops shape is the wire shape (work_revise_delta / crdt_text_delta):
 * a sequence of retain/delete/insert that walks the old text left to
 * right. Ops need not consume the full document — the transform
 * works on any prefix and clamps defensively.
 *
 * Tie-break policy (the classic OT ambiguity): when an insertion
 * lands EXACTLY on a position, "right" shifts the position past the
 * inserted text (cursor semantics — keep pointing at the same
 * character), "left" keeps it before. Spans need one of each to OWN
 * their original characters: start edge "right" (an insert at the
 * start boundary lands outside — the span moves past it), end edge
 * "left" (an insert at the end boundary stays outside too). That
 * (right, left) default preserves quotation semantics exactly; the
 * reversed pair opts into absorbing boundary inserts.
 *
 * NOTE (step-2 integration): the server runs its own span migration
 * for links/annotations; these defaults should be aligned with the
 * server's tie-break behavior when the optimistic rebase lands.
 */

export type Side = "left" | "right";

export interface Span {
  start: number;
  end: number;
}

export interface SpanRebaseOptions {
  /** Tie-break for insertions exactly at span.start. Default "right":
   * boundary inserts stay OUTSIDE (the span owns its characters). */
  startSide?: Side;
  /** Tie-break for insertions exactly at span.end. Default "left":
   * boundary inserts stay outside. */
  endSide?: Side;
}

/**
 * Rebase a single char position across a delta. Positions that fall
 * inside a deleted region collapse to the deletion's start point in
 * new coordinates. Never throws; negative input clamps to 0, and
 * positions past the ops' consumed region extrapolate by the net
 * shift (ops may be a prefix of a full-document edit).
 */
export function rebasePosition(pos: number, ops: TextDeltaOp[], side: Side = "right"): number {
  const p = Math.max(0, pos);
  let index = 0;    // offset in the OLD document
  let shift = 0;    // net mapping delta so far: inserts minus deletes

  for (const op of ops) {
    const text = op.text ?? "";
    switch (op.type) {
      case "retain": {
        const n = Math.max(0, op.count ?? 0);
        const end = index + n;
        if (p < end) return p + shift;
        index = end;
        break;
      }
      case "delete": {
        const n = Math.max(0, op.count ?? 0);
        const end = index + n;
        if (p < end) return index + shift;
        index = end;
        shift -= n;
        break;
      }
      case "insert": {
        if (p === index) {
          return side === "right" ? p + shift + text.length : p + shift;
        }
        shift += text.length;
        break;
      }
    }
  }
  // At/after the tail: everything consumed maps by the net shift.
  return p + shift;
}

/**
 * Rebase a [start, end) span. Insertions strictly inside the span
 * grow it; deletions overlapping it shrink or collapse it (a fully
 * deleted span comes back collapsed: start === end at the deletion
 * point). Boundary insertions stay outside by default — see the
 * tie-break note above.
 */
export function rebaseSpan(span: Span, ops: TextDeltaOp[], opts: SpanRebaseOptions = {}): Span {
  const startSide = opts.startSide ?? "right";
  const endSide = opts.endSide ?? "left";
  const start = rebasePosition(span.start, ops, startSide);
  const end = rebasePosition(Math.max(span.start, span.end), ops, endSide);
  return { start, end: Math.max(start, end) };
}
