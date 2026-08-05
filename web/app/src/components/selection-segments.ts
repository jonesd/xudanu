export interface SelectionSegment {
  type: "text" | "transclusion";
  content: string;
  workId?: number;
  resolvedStart: number;
  resolvedEnd: number;
  sourceCharStart?: number;
  sourceCharEnd?: number;
}

export function computeSelectionSegments(
  _el: HTMLElement,
  startPos: number,
  endPos: number,
  spanRanges: Array<{ flat_start: number; flat_end: number; source_work_id: number; char_start: number; char_end: number }>,
): SelectionSegment[] {
  if (startPos >= endPos) return [];
  const segments: SelectionSegment[] = [];

  const overlapping = spanRanges
    .filter((sr) => sr.flat_end > startPos && sr.flat_start < endPos)
    .sort((a, b) => a.flat_start - b.flat_start);

  if (overlapping.length === 0) {
    segments.push({
      type: "text",
      content: "",
      resolvedStart: startPos,
      resolvedEnd: endPos,
    });
    return segments;
  }

  let cursor = startPos;
  for (const sr of overlapping) {
    if (sr.flat_start > cursor) {
      segments.push({
        type: "text",
        content: "",
        resolvedStart: cursor,
        resolvedEnd: Math.min(sr.flat_start, endPos),
      });
    }
    const tStart = Math.max(sr.flat_start, startPos);
    const tEnd = Math.min(sr.flat_end, endPos);
    if (tEnd > tStart) {
      segments.push({
        type: "transclusion",
        content: "",
        workId: sr.source_work_id,
        resolvedStart: tStart,
        resolvedEnd: tEnd,
        sourceCharStart: sr.char_start + (tStart - sr.flat_start),
        sourceCharEnd: sr.char_end - (sr.flat_end - tEnd),
      });
    }
    cursor = sr.flat_end;
  }

  if (cursor < endPos) {
    segments.push({
      type: "text",
      content: "",
      resolvedStart: cursor,
      resolvedEnd: endPos,
    });
  }

  return segments;
}

export function segmentsToText(segments: SelectionSegment[], sourceText: string): string {
  let result = "";
  for (const seg of segments) {
    result += sourceText.slice(seg.resolvedStart, seg.resolvedEnd);
  }
  return result;
}

export function isMultiSourceSelection(segments: SelectionSegment[]): boolean {
  const sourceIds = new Set<number | undefined>();
  for (const seg of segments) {
    sourceIds.add(seg.type === "transclusion" ? seg.workId : undefined);
  }
  return sourceIds.size > 1;
}
