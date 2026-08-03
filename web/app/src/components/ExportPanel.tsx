import { useMemo, useState, useCallback } from "react";
import type { CrdtSyncClient, WorkListEntry, AttributionSpan, AttributionLogStatus, LinkEntry } from "../api/crdt_sync";
import { extractValue } from "../api/crdt_sync";
import { useDraggable } from "../hooks/useDraggable";

interface Props {
  client: CrdtSyncClient | null;
  currentWorkId: number | null;
  currentWorkMeta: WorkListEntry | null;
  text: string;
  attributionSpans: AttributionSpan[];
  logStatus: AttributionLogStatus | null;
  links: LinkEntry[];
  works: WorkListEntry[];
  onClose: () => void;
  onWorkCreated?: (id: number) => void;
}

function download(filename: string, content: string, mime: string) {
  const blob = new Blob([content], { type: mime });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

function safeName(title: string | undefined, id: number): string {
  const base = (title || "untitled").replace(/[^a-zA-Z0-9_-]/g, "_").slice(0, 40);
  return `${base}_0x${id.toString(16)}`;
}

export function ExportPanel({
  client,
  currentWorkId,
  currentWorkMeta,
  text,
  attributionSpans,
  logStatus,
  links,
  works,
  onClose,
  onWorkCreated,
}: Props) {
  const { drag, onMouseDown, dialogRef } = useDraggable();
  const title = currentWorkMeta?.title || `work:${currentWorkId?.toString(16)}`;
  const fileBase = useMemo(
    () => safeName(currentWorkMeta?.title, currentWorkId ?? 0),
    [currentWorkMeta?.title, currentWorkId],
  );

  const [importStatus, setImportStatus] = useState<{
    state: "idle" | "reading" | "creating" | "done" | "error";
    message: string;
    importedId: number | null;
  }>({ state: "idle", message: "", importedId: null });

  const handleImport = useCallback(
    async (file: File) => {
      if (!client) return;
      setImportStatus({ state: "reading", message: `Reading ${file.name}…`, importedId: null });

      try {
        const content = await file.text();
        let workText = content;
        let importTitle: string | null = null;

        if (file.name.endsWith(".json")) {
          const bundle = JSON.parse(content);
          if (bundle.format && bundle.work) {
            workText = bundle.work.text || "";
            importTitle = bundle.work.title || null;
          } else {
            throw new Error("Not a valid xudanu JSON export");
          }
        } else {
          // Markdown: strip leading "# Title" line if present
          const mdMatch = workText.match(/^#\s+(.+)\n+/);
          if (mdMatch) {
            importTitle = mdMatch[1].trim();
            workText = workText.slice(mdMatch[0].length);
          }
        }

        if (!workText.trim()) {
          throw new Error("File is empty");
        }

        setImportStatus({ state: "creating", message: "Creating work…", importedId: null });

        const resp = await client.sendRequest("work_create", {
          edition: { text: workText },
        });
        const val = extractValue(resp);
        const newId = typeof val === "number" ? val : ((val as Record<string, unknown>)?.value as number) ?? 0;

        if (!newId) throw new Error("Server returned no work ID");

        setImportStatus({
          state: "done",
          message: `Imported${importTitle ? ` "${importTitle}"` : ""} as work 0x${newId.toString(16)}.`,
          importedId: newId,
        });

        if (onWorkCreated) {
          setTimeout(() => onWorkCreated(newId), 1500);
        }
      } catch (e) {
        setImportStatus({
          state: "error",
          message: e instanceof Error ? e.message : String(e),
          importedId: null,
        });
      }
    },
    [client, onWorkCreated],
  );

  // Build the full JSON export bundle
  const jsonBundle = useMemo(() => {
    if (!currentWorkId) return "";
    const id = currentWorkId;

    // Incoming links (other works transcluded INTO this one)
    const incoming = links
      .filter((l) => l.destination === id)
      .map((l) => {
        const src = works.find((w) => w.work_id === l.origin);
        return {
          direction: "incoming",
          source_work_id: `0x${l.origin.toString(16)}`,
          source_title: src?.title || l.origin_title || null,
          source_author: attributionSpans.find((s) => s.source_work_id === l.origin)?.author_display_name || null,
          excerpt: l.origin_ref?.excerpt || null,
          source_archived: l.origin_archived || false,
        };
      });

    // Outgoing links (this work transcluded FROM others)
    const outgoing = links
      .filter((l) => l.origin === id)
      .map((l) => {
        const dest = works.find((w) => w.work_id === l.destination);
        return {
          direction: "outgoing",
          destination_work_id: `0x${l.destination.toString(16)}`,
          destination_title: dest?.title || l.destination_title || null,
          excerpt: l.origin_ref?.excerpt || null,
          destination_archived: l.destination_archived || false,
        };
      });

    return JSON.stringify(
      {
        format: "xudanu-export-v1",
        exported_at: new Date().toISOString(),
        work: {
          id: `0x${id.toString(16)}`,
          title,
          revision_count: currentWorkMeta?.revision_count ?? 0,
          is_source: currentWorkMeta?.is_source ?? false,
          owner: currentWorkMeta?.owner ?? null,
          text,
        },
        attribution: {
          span_count: attributionSpans.length,
          log_status: logStatus
            ? {
                chain_valid: logStatus.chain_valid ?? false,
                entry_count: logStatus.entry_count ?? 0,
                has_log: logStatus.has_log ?? false,
              }
            : null,
          spans: attributionSpans.map((s) => ({
            start: s.start,
            end: s.end,
            author: s.author_display_name || null,
            author_type: s.author_type || null,
            source_work_id: s.source_work_id ? `0x${s.source_work_id.toString(16)}` : null,
            transcluded_by: s.transcluded_by_name || null,
            signature_valid: s.signature_valid ?? false,
          })),
        },
        links: {
          incoming,
          outgoing,
        },
        references: {
          // Content-level references for reconnection on import.
          // xudanu is content-addressed (BLAKE3), so another server
          // can match excerpts to existing works by fingerprint.
          note: "On import, links can be reconnected by matching excerpt text or content fingerprint to works already on the target server.",
          excerpts: [...incoming, ...outgoing]
            .map((l) => l.excerpt)
            .filter((e): e is string => !!e),
        },
      },
      null,
      2,
    );
  }, [currentWorkId, title, text, attributionSpans, logStatus, links, works, currentWorkMeta]);

  return (
    <div
      onClick={onClose}
      style={{
        position: "fixed",
        inset: 0,
        background: "rgba(0,0,0,0.4)",
        zIndex: 200,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <div
        ref={dialogRef}
        onClick={(e) => e.stopPropagation()}
        style={{
          background: "#fff",
          borderRadius: 8,
          padding: 24,
          minWidth: 360,
          maxWidth: 480,
          boxShadow: "0 4px 24px rgba(0,0,0,0.2)",
          transform: `translate(${drag.offsetX}px, ${drag.offsetY}px)`,
        }}
      >
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16, cursor: "grab", userSelect: "none" }} onMouseDown={onMouseDown}>
          <strong style={{ fontSize: 16 }}>Export</strong>
          <button type="button" onClick={onClose} style={{ border: "none", background: "none", fontSize: 18, cursor: "pointer", color: "#999" }}>
            ×
          </button>
        </div>

        <div style={{ fontSize: 12, color: "#888", marginBottom: 16 }}>
          <strong>{title}</strong> · 0x{(currentWorkId ?? 0).toString(16)} · {text.length} chars · {attributionSpans.length} attribution spans
        </div>

        {/* Level 1: Markdown */}
        <div style={{ marginBottom: 12, padding: 12, border: "1px solid #e0e0e0", borderRadius: 6 }}>
          <div style={{ fontWeight: 600, fontSize: 13, marginBottom: 4 }}>Markdown</div>
          <div style={{ fontSize: 11, color: "#888", marginBottom: 8 }}>
            Just the text — fully readable, no provenance or links. Universal format.
          </div>
          <button
            type="button"
            onClick={() => download(`${fileBase}.md`, `# ${title}\n\n${text}`, "text/markdown")}
            style={{
              padding: "4px 14px",
              fontSize: 12,
              fontWeight: 600,
              border: "1px solid #ccc",
              borderRadius: 4,
              background: "#fff",
              cursor: "pointer",
            }}
          >
            Download .md
          </button>
        </div>

        {/* Level 2: JSON bundle */}
        <div style={{ marginBottom: 12, padding: 12, border: "1px solid #e0e0e0", borderRadius: 6 }}>
          <div style={{ fontWeight: 600, fontSize: 13, marginBottom: 4 }}>JSON Archive (full fidelity)</div>
          <div style={{ fontSize: 11, color: "#888", marginBottom: 8 }}>
            Text + attribution + links + reference manifest. Includes content excerpts for link reconnection on import.
          </div>
          <button
            type="button"
            onClick={() => download(`${fileBase}.json`, jsonBundle, "application/json")}
            style={{
              padding: "4px 14px",
              fontSize: 12,
              fontWeight: 600,
              border: "1px solid #ccc",
              borderRadius: 4,
              background: "#fff",
              cursor: "pointer",
            }}
          >
            Download .json
          </button>
          <span style={{ fontSize: 10, color: "#aaa", marginLeft: 8 }}>
            {jsonBundle.length > 1024 ? `${(jsonBundle.length / 1024).toFixed(1)} KB` : `${jsonBundle.length} bytes`}
          </span>
        </div>

        {/* Level 3: preview (not yet implemented) */}
        <div style={{ marginBottom: 16, padding: 12, border: "1px dashed #ddd", borderRadius: 6, background: "#fafafa" }}>
          <div style={{ fontWeight: 600, fontSize: 13, color: "#999", marginBottom: 4 }}>Web Archive (coming soon)</div>
          <div style={{ fontSize: 11, color: "#aaa" }}>
            Multiple works + all inter-links + blob images as a .zip. Follows transclusion closure from this work.
          </div>
        </div>

        {/* Divider */}
        <div style={{ borderTop: "2px solid #e0e0e0", paddingTop: 16, marginTop: 8 }}>
          <strong style={{ fontSize: 16 }}>Import</strong>
          <div style={{ fontSize: 12, color: "#888", marginBottom: 12 }}>
            Load a Markdown or JSON file as a new work on this server.
          </div>

          {/* File upload */}
          {importStatus.state === "idle" && (
            <label
              style={{
                display: "block",
                padding: "20px 16px",
                border: "2px dashed #ccc",
                borderRadius: 6,
                textAlign: "center",
                cursor: "pointer",
                background: "#fafafa",
                fontSize: 13,
                color: "#666",
              }}
            >
              <input
                type="file"
                accept=".md,.json,.txt"
                style={{ display: "none" }}
                onChange={(e) => {
                  const f = e.target.files?.[0];
                  if (f) handleImport(f);
                }}
              />
              Choose a file to import (.md or .json)
            </label>
          )}

          {/* Import progress/result */}
          {importStatus.state !== "idle" && (
            <div
              style={{
                padding: 12,
                borderRadius: 6,
                background:
                  importStatus.state === "error" ? "#fff5f5" : importStatus.state === "done" ? "#f6fff8" : "#f8f9fa",
                border: `1px solid ${importStatus.state === "error" ? "#fcc" : importStatus.state === "done" ? "#cfc" : "#e0e0e0"}`,
                fontSize: 12,
              }}
            >
              {importStatus.state === "done" && <span style={{ color: "#1a7f37", fontWeight: 600 }}>✓ </span>}
              {importStatus.state === "error" && <span style={{ color: "#d1242f", fontWeight: 600 }}>✗ </span>}
              {importStatus.message}
              {importStatus.state === "done" && importStatus.importedId && (
                <>
                  {" "}
                  <button
                    type="button"
                    onClick={() => {
                      if (onWorkCreated) onWorkCreated(importStatus.importedId!);
                      onClose();
                    }}
                    style={{
                      border: "1px solid #2da44e",
                      borderRadius: 3,
                      background: "#2da44e",
                      color: "#fff",
                      padding: "2px 10px",
                      fontSize: 11,
                      cursor: "pointer",
                      fontWeight: 600,
                    }}
                  >
                    Open
                  </button>
                </>
              )}
              {(importStatus.state === "done" || importStatus.state === "error") && (
                <button
                  type="button"
                  onClick={() => setImportStatus({ state: "idle", message: "", importedId: null })}
                  style={{
                    border: "none",
                    background: "none",
                    color: "#888",
                    fontSize: 11,
                    cursor: "pointer",
                    marginLeft: 8,
                  }}
                >
                  Import another
                </button>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
