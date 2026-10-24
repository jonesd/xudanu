import type { TextDeltaOp } from "./text_buffer";
import { rebaseSpan } from "./position-transform";
import type { AnnotationEntry, AttributionSpan, TransclusionMarker } from "./protocol";

/**
 * Optimistic span rebase (step 2): shift overlay spans through a
 * text delta the instant it applies, instead of waiting for the
 * server re-query. The server remains authoritative — its refreshed
 * lists (attributionQuery / annotationList / link events) land
 * shortly after and confirm or correct the optimistic positions.
 *
 * All helpers keep collapsed entries (start === end after a full
 * deletion): renderers already skip zero-length spans, and dropping
 * them here would make the server refresh resurrect flashes.
 * Identity/reference fields are preserved untouched.
 */

export function rebaseAttributionSpans(spans: AttributionSpan[], ops: TextDeltaOp[]): AttributionSpan[] {
  return spans.map((sp) => {
    const r = rebaseSpan({ start: sp.start, end: sp.end }, ops);
    return { ...sp, start: r.start, end: r.end };
  });
}

export function rebaseAnnotations(entries: AnnotationEntry[], ops: TextDeltaOp[]): AnnotationEntry[] {
  return entries.map((ann) => {
    const r = rebaseSpan({ start: ann.char_start, end: ann.char_end }, ops);
    return { ...ann, char_start: r.start, char_end: r.end };
  });
}

export function rebaseMarkers(markers: TransclusionMarker[], ops: TextDeltaOp[]): TransclusionMarker[] {
  return markers.map((m) => {
    const r = rebaseSpan({ start: m.start, end: m.end }, ops);
    // NOTE: target.span and endSet fields are left untouched — the
    // target span lives in ANOTHER work's coordinate space.
    return { ...m, start: r.start, end: r.end };
  });
}
