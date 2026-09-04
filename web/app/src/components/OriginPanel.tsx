import { useEffect, useMemo, useState } from "react";
import type { LinkEntry, TransclusionMarker } from "../api/crdt_sync";
import { linkEnds } from "../link-ends";

interface SyncClient {
  sendRequest: (op: string, params: Record<string, unknown>) => Promise<unknown>;
}

export interface OriginPanelProps {
  client: SyncClient | null;
  marker: TransclusionMarker;
  links: LinkEntry[];
  onClose: () => void;
  onOpenFull: (workId: number) => void;
  /** FR-55 T4: the compound this marker lives in, if any — enables
   *  walk-first exact resolution via compound_follow_back. */
  compoundWorkId?: number | null;
}

/** Context window (chars) shown around the highlighted origin span. */
const CONTEXT = 340;

function extractText(resp: unknown): string {
  const val =
    resp && typeof resp === "object" && "value" in (resp as Record<string, unknown>)
      ? (resp as Record<string, unknown>).value
      : resp;
  if (typeof val === "string") return val;
  if (val && typeof val === "object") {
    const o = val as Record<string, unknown>;
    return (o.Text as string) || (o.text as string) || "";
  }
  return "";
}

/**
 * Design C — the transclusion origin panel. Shows the OTHER side of a
 * quote: the origin document with the exact span highlighted, provenance
 * hops, and the other ends of the same link (n-way context).
 */
export function OriginPanel({
  client,
  marker,
  links,
  onClose,
  onOpenFull,
  compoundWorkId,
}: OriginPanelProps) {
  const [originText, setOriginText] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  /** FR-55 T4: exact source range from the arrangement walk —
   *  preferred over excerpt search when available. */
  const [exactRange, setExactRange] = useState<{ start: number; end: number } | null>(null);
  const [exactSource, setExactSource] = useState<string | null>(null);

  useEffect(() => {
    if (!client || !compoundWorkId) return;
    let cancelled = false;
    (async () => {
      try {
        const resp = (await client.sendRequest("compound_follow_back", {
          work_id: compoundWorkId,
          local_char: marker.start,
        })) as Record<string, unknown>;
        const val =
          resp && typeof resp === "object" && "value" in resp
            ? (resp.value as Record<string, unknown>)
            : resp;
        if (cancelled || !val || val.status === "error") return;
        // Walk hit: use the exact source char + excerpt length.
        setExactSource(
          `${val.title ?? `Work 0x${Number(val.work_id).toString(16)}`} · exact (arrangement walk)`,
        );
        const start = Number(val.char);
        const len = marker.end - marker.start;
        setExactRange({ start, end: start + len });
      } catch {
        // Walk unavailable (older server / not a compound) — the
        // excerpt-search path below remains the fallback.
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [client, compoundWorkId, marker.start, marker.end]);

  const link = links.find((l) => l.link_id === marker.linkId) ?? null;
  const ends = link ? linkEnds(link) : [];

  useEffect(() => {
    let cancelled = false;
    setOriginText(null);
    setError(null);
    if (!client) {
      setError("Not connected");
      return;
    }
    client
      .sendRequest("work_get_edition", { work_id: marker.otherWorkId })
      .then((resp) => {
        if (!cancelled) setOriginText(extractText(resp));
      })
      .catch((e) => {
        if (!cancelled) setError(e instanceof Error ? e.message : String(e));
      });
    return () => {
      cancelled = true;
    };
  }, [client, marker.otherWorkId, marker.linkId]);

  /** Locate the quoted span: arrangement walk (exact) > stored
   *  positions > excerpt search. */
  const located = useMemo(() => {
    if (originText == null) return null;
    const excerpt = (marker.excerpt ?? "").trim();
    if (!excerpt) return null;
    // Walk-first: the exact range from the live arrangement.
    if (exactRange && exactRange.end > exactRange.start) {
      return exactRange;
    }
    let start = -1;
    if (marker.sourceSpanStart != null && marker.sourceSpanEnd != null) {
      const cand = originText.slice(marker.sourceSpanStart, marker.sourceSpanEnd).trim();
      if (cand.length > 0 && excerpt.length > 0 && cand.slice(0, 40) === excerpt.slice(0, 40)) {
        start = marker.sourceSpanStart;
      }
    }
    if (start < 0) start = originText.indexOf(excerpt);
    if (start < 0) return null;
    return { start, end: start + excerpt.length };
  }, [originText, marker.excerpt, marker.sourceSpanStart, marker.sourceSpanEnd, exactRange]);

  const author = marker.provenanceChain?.[0]?.source_author_name ?? null;
  const otherEnds = ends.filter((e) => e.workId !== marker.otherWorkId);
  const tumbler = marker.crossServerRef?.tumbler ?? null;

  const copyTumbler = () => {
    const text = tumbler ?? `work 0x${marker.otherWorkId.toString(16)} @ ${located?.start ?? "?"}-${located?.end ?? "?"}`;
    void navigator.clipboard?.writeText(text);
  };

  return (
    <div className="ws-origin" role="dialog" aria-label="Transclusion origin">
      <div className="ws-origin-head">
        ✂️ Origin
        <span className="ws-origin-pill">transclusion</span>
        {marker.endSetTotal != null && marker.endSetTotal > 1 && (
          <span className="ws-origin-pill">
            {marker.endSetIndex ?? "?"} of {marker.endSetTotal} ends
          </span>
        )}
        <button className="ws-origin-x" onClick={onClose} aria-label="Close">
          ✕
        </button>
      </div>

      <div className="ws-origin-src">
        <div className="ws-origin-src-t">{marker.otherWorkTitle || `Work 0x${marker.otherWorkId.toString(16)}`}</div>
        <div className="ws-origin-src-m">
          {exactSource && <span className="ws-origin-exact">{exactSource}</span>}
          {author ? ` · by ${author}` : " · author unknown"}
          {marker.provenanceChain && marker.provenanceChain.length > 0 && (
            <> · {marker.provenanceChain.length + 1} works in chain</>
          )}
        </div>
      </div>

      <div className="ws-origin-hl">
        {originText == null && !error && <p className="ws-origin-meta">Loading origin…</p>}
        {error && <p className="ws-origin-meta">Could not load origin: {error}</p>}
        {originText != null && !located && (
          <p className="ws-origin-meta">The quoted span could not be located in the current revision of the origin.</p>
        )}
        {originText != null && located && (
          <HighlightedOrigin text={originText} start={located.start} end={located.end} context={CONTEXT} />
        )}
      </div>

      {marker.provenanceChain && marker.provenanceChain.length > 1 && (
        <div className="ws-origin-chain">
          <h4>Provenance chain</h4>
          {marker.provenanceChain.map((hop, i) => (
            <div key={i} className="ws-origin-chain-hop">
              {i + 1}. {hop.source_work_title || `work 0x${hop.source_work_id.toString(16)}`}
              {hop.source_author_name ? ` — ${hop.source_author_name}` : ""}
            </div>
          ))}
        </div>
      )}

      {otherEnds.length > 0 && (
        <div className="ws-origin-ends">
          <h4>{otherEnds.length} other end{otherEnds.length > 1 ? "s" : ""} of this link</h4>
          {otherEnds.map((e, i) => (
            <button
              key={i}
              className="ws-origin-end"
              onClick={() => e.workId != null && onOpenFull(e.workId)}
            >
              <b>{e.workId != null ? (e.ref.work_context != null ? workTitle(links, e.workId) : `work 0x${e.workId.toString(16)}`) : "cross-server"}</b>
              <span>“{(e.excerpt || "").slice(0, 70)}{e.excerpt.length > 70 ? "…" : ""}”</span>
            </button>
          ))}
        </div>
      )}

      <div className="ws-origin-foot">
        <button className="ws-origin-btn primary" onClick={() => onOpenFull(marker.otherWorkId)}>
          Open full document
        </button>
        <button className="ws-origin-btn" onClick={copyTumbler}>
          Copy tumbler
        </button>
      </div>
    </div>
  );
}

function workTitle(links: LinkEntry[], workId: number): string | null {
  for (const l of links) {
    if (l.origin === workId && l.origin_title) return l.origin_title;
    if (l.destination === workId && l.destination_title) return l.destination_title;
  }
  return null;
}

/** Render a context window around [start,end) with the span highlighted. */
function HighlightedOrigin({ text, start, end, context }: { text: string; start: number; end: number; context: number }) {
  const from = Math.max(0, start - context);
  const to = Math.min(text.length, end + context);
  const before = text.slice(from, start);
  const span = text.slice(start, end);
  const after = text.slice(end, to);
  return (
    <>
      {from > 0 && <span className="ws-origin-fade">…</span>}
      {before}
      <mark className="ws-origin-mark">{span}</mark>
      {after}
      {to < text.length && <span className="ws-origin-fade">…</span>}
    </>
  );
}
