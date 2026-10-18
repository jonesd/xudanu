import type { SpanRangePayload } from "./api/crdt_sync";

export interface ExportMeta {
  title: string;
  serverDomain: string;
  workId: number;
  exportedAt?: Date;
}

const escapeHtml = (s: string) =>
  s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

/**
 * Professional HTML export of a (possibly compound) document.
 * Transcluded passages render as quotations carrying their source
 * citation and xan:// address — the provenance survives the export.
 */
export function buildExportHtml(
  meta: ExportMeta,
  resolved: { text: string; spanRanges: SpanRangePayload[]; sourceTitles: Record<number, string> },
): string {
  const { text, spanRanges, sourceTitles } = resolved;
  const spans = [...spanRanges].sort((a, b) => a.flat_start - b.flat_start);

  type Part = { type: "text"; content: string } | { type: "quote"; html: string };
  const parts: Part[] = [];
  let pos = 0;
  const cite = (span: SpanRangePayload) => {
    const title = sourceTitles[span.source_work_id] || `Work 0x${span.source_work_id.toString(16)}`;
    const addr = `xan://${meta.serverDomain}.${span.source_work_id.toString(16)}.${span.char_start}.${span.char_end}`;
    return `${escapeHtml(title)} · <code class="x-addr">${escapeHtml(addr)}</code>`;
  };

  for (const span of spans) {
    if (span.flat_start > pos) parts.push({ type: "text", content: text.slice(pos, span.flat_start) });
    const quoted = span.resolved_content || text.slice(span.flat_start, span.flat_end);
    parts.push({
      type: "quote",
      html: `<blockquote class="x-transclusion"><p>${escapeHtml(quoted.trim())}</p><cite>${cite(span)}</cite></blockquote>`,
    });
    pos = Math.max(pos, span.flat_end);
  }
  if (pos < text.length) parts.push({ type: "text", content: text.slice(pos) });

  // Paragraphs: each blank-line-separated run of plain text becomes
  // its own <p>; quotations are structural block elements and never
  // nest inside a paragraph.
  const body = parts
    .map((p) =>
      p.type === "quote"
        ? p.html
        : p.content
            .split(/\n{2,}/)
            .filter((s) => s.trim().length > 0)
            .map((para) => `<p>${escapeHtml(para.trim()).replace(/\n/g, "<br/>")}</p>`)
            .join("\n"),
    )
    .filter((s) => s.length > 0)
    .join("\n");

  const date = (meta.exportedAt ?? new Date()).toISOString().slice(0, 10);
  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8"/>
<title>${escapeHtml(meta.title)}</title>
<style>
  :root { color-scheme: light; }
  body { font: 11.5pt/1.65 Georgia, "Times New Roman", serif; color: #1a1a1a; background: #fff;
         max-width: 46rem; margin: 3rem auto; padding: 0 2rem; }
  header.x-doc { border-bottom: 2px solid #1a1a1a; margin-bottom: 2.5rem; padding-bottom: 1rem; }
  header.x-doc h1 { font-size: 19pt; margin: 0 0 .4rem; }
  header.x-doc .x-meta { font: 9pt/1.4 "Helvetica Neue", sans-serif; color: #666; letter-spacing: .02em; }
  p { margin: 0 0 .9rem; text-align: justify; hyphens: auto; }
  blockquote.x-transclusion { margin: 1.1rem 0 1.3rem; padding: .55rem 1rem; border-left: 3px solid #b48a2f;
    background: #faf7ef; }
  blockquote.x-transclusion p { margin: 0 0 .35rem; font-style: italic; }
  blockquote.x-transclusion cite { font: 8.5pt/1.3 "Helvetica Neue", sans-serif; color: #7a6a45; font-style: normal; }
  code.x-addr { font: 8.5pt "SF Mono", Menlo, monospace; color: #8a8a8a; }
  footer.x-doc { margin-top: 3rem; padding-top: .8rem; border-top: 1px solid #ddd;
    font: 8.5pt/1.5 "Helvetica Neue", sans-serif; color: #999; }
  @media print { body { margin: 1.5rem auto; } blockquote.x-transclusion { background: none; } }
</style></head>
<body>
<header class="x-doc">
  <h1>${escapeHtml(meta.title)}</h1>
  <div class="x-meta">Xudanu document 0x${meta.workId.toString(16)} · exported ${date} · quotations are live transclusions in the source system</div>
</header>
${body}
<footer class="x-doc">
  ${spans.length} transcluded passage${spans.length === 1 ? "" : "s"} from ${new Set(spans.map((s) => s.source_work_id)).size} source document${new Set(spans.map((s) => s.source_work_id)).size === 1 ? "" : "s"} — every quotation above carries its origin address.
</footer>
</body></html>`;
}

export function downloadHtml(html: string, filename: string): void {
  const blob = new Blob([html], { type: "text/html;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
