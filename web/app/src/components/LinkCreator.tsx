import { useState, useMemo, useEffect } from "react";
import type { CrdtSyncClient, WorkListEntry, CrossServerRefPayload, LinkTypeInfo } from "../api/crdt_sync";
import { DEFAULT_LINK_TYPES } from "../hooks/useTransclusion";
import { planEndSetOperations } from "../link-ends";

const LINK_TYPE_DESCRIPTIONS: Record<number, string> = {
  1: "Annotate a passage or add a scholarly note",
  2: "Cross-reference, citation, or 'see this'",
  3: "Mark a contested claim or counter-argument",
  4: "This passage quotes another source",
  5: "Related reading path or similar work",
  6: "External web link",
  7: "This passage is part of a curated trail",
};

export interface LinkCreatorSource {
  workId: number;
  workTitle: string;
  start: number;
  end: number;
  text: string;
}

interface LinkCreatorProps {
  open: boolean;
  onClose: () => void;
  source: LinkCreatorSource | null;
  works: WorkListEntry[];
  currentWorkId: number | null;
  clientRef: React.MutableRefObject<CrdtSyncClient | null>;
  onLinkCreated: () => void;
  onSelectTextInOtherDoc: () => void;
}

type Step = "target" | "type" | "extra-ends" | "remote" | "web" | "done";
type TargetMode = "whole-work" | "other-doc-text" | "same-doc" | "remote" | "web" | null;

interface ExtraEnd {
  name: string;
  workId: number;
}

export function LinkCreator({
  open,
  onClose,
  source,
  works,
  currentWorkId,
  clientRef,
  onLinkCreated,
  onSelectTextInOtherDoc,
}: LinkCreatorProps) {
  const [step, setStep] = useState<Step>("target");
  const [targetMode, setTargetMode] = useState<TargetMode>(null);
  const [selectedWorkId, setSelectedWorkId] = useState<number | null>(null);
  const [selectedTypeIds, setSelectedTypeIds] = useState<Set<number>>(new Set());
  const [serverTypes, setServerTypes] = useState<LinkTypeInfo[]>([]);
  const [extraEnds, setExtraEnds] = useState<ExtraEnd[]>([]);
  // FR-40 S6: the end name currently being gathered into.
  const [gatherFor, setGatherFor] = useState<string | null>(null);
  const [homeDocument, setHomeDocument] = useState<number | "">("");
  const [creating, setCreating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [remoteTumbler, setRemoteTumbler] = useState("");
  const [remoteHash, setRemoteHash] = useState("");
  const [remoteAuthor, setRemoteAuthor] = useState("");
  const [remoteAuthorKey, setRemoteAuthorKey] = useState("");
  const [fetchUrl, setFetchUrl] = useState("");
  const [fetchWorkId, setFetchWorkId] = useState("");
  const [fetching, setFetching] = useState(false);
  const [webUrl, setWebUrl] = useState("");
  const [description, setDescription] = useState("");

  // Merge server-registered types with built-ins (server wins on
  // name/definition; built-ins fill gaps). Custom types get a
  // fallback description pointing at their definition work.
  const allTypes = useMemo(() => {
    const byId = new Map<number, { type_id: number; name: string; color: string; lineStyle: string; custom: boolean }>();
    for (const t of DEFAULT_LINK_TYPES) {
      byId.set(t.type_id, { ...t, custom: false });
    }
    for (const t of serverTypes) {
      const builtin = byId.get(t.type_id);
      byId.set(t.type_id, {
        type_id: t.type_id,
        name: t.name,
        color: builtin?.color ?? "#8b949e",
        lineStyle: builtin?.lineStyle ?? "dashed",
        custom: !builtin,
      });
    }
    return Array.from(byId.values()).sort((a, b) => (a.custom === b.custom ? a.type_id - b.type_id : a.custom ? 1 : -1));
  }, [serverTypes]);

  useEffect(() => {
    if (open && clientRef.current) {
      clientRef.current
        .linkTypeList()
        .then((types) => setServerTypes(types))
        .catch(() => setServerTypes([]));
    }
  }, [open, clientRef]);

  const typeDesc = (typeId: number): string => {
    if (LINK_TYPE_DESCRIPTIONS[typeId]) return LINK_TYPE_DESCRIPTIONS[typeId];
    const st = serverTypes.find((t) => t.type_id === typeId);
    return st ? `Custom type defined by a work on this server` : "";
  };

  const handlePasteReference = async () => {
    try {
      const text = await navigator.clipboard.readText();
      const parts = text.split("|");
      if (parts.length === 2 && parts[0].includes('"')) {
        setRemoteTumbler(parts[0].trim());
        setRemoteHash(parts[1].trim());
        setStep("remote");
      } else {
        setError("Clipboard doesn't contain a valid reference (expected: tumbler|hash)");
      }
    } catch {
      setError("Could not read clipboard");
    }
  };

  const otherWorks = useMemo(
    () => works.filter((w) => w.work_id !== source?.workId),
    [works, source],
  );

  if (!open || !source) return null;

  const reset = () => {
    setStep("target");
    setTargetMode(null);
    setSelectedWorkId(null);
    setSelectedTypeIds(new Set());
    setExtraEnds([]);
    setHomeDocument("");
    setError(null);
    setCreating(false);
    setRemoteTumbler("");
    setRemoteHash("");
    setRemoteAuthor("");
    setRemoteAuthorKey("");
    setWebUrl("");
    setDescription("");
  };

  const handleClose = () => {
    reset();
    onClose();
  };

  const handleChooseTarget = (mode: TargetMode) => {
    setTargetMode(mode);
    if (mode === "other-doc-text") {
      handleClose();
      onSelectTextInOtherDoc();
    } else if (mode === "same-doc") {
      handleClose();
      onSelectTextInOtherDoc();
    } else if (mode === "remote") {
      setStep("remote");
    } else if (mode === "web") {
      setStep("web");
    }
  };

  const handlePickWork = (workId: number) => {
    setSelectedWorkId(workId);
    setStep("type");
  };

  const toggleType = (typeId: number) => {
    setSelectedTypeIds((prev) => {
      const next = new Set(prev);
      if (next.has(typeId)) {
        next.delete(typeId);
      } else {
        next.add(typeId);
      }
      return next;
    });
  };

  const handleCreate = async () => {
    const client = clientRef.current;
    if (!client || !source || selectedTypeIds.size === 0) return;
    setCreating(true);
    setError(null);
    try {
      if (targetMode === "whole-work" && selectedWorkId !== null) {
        const linkId = await client.linkCreate(
          source.workId,
          selectedWorkId,
          { excerpt: source.text, start: source.start, end: source.end },
          { excerpt: "", start: 0, end: 0 },
          homeDocument === "" ? undefined : Number(homeDocument),
        );
        if (selectedTypeIds.size > 0) {
          await client.linkSetTypes(linkId, Array.from(selectedTypeIds));
        }
        // FR-40 S6: rows sharing an end name GATHER — first row
        // creates the end, the rest attach to it (end-sets).
        const ops = planEndSetOperations(
          extraEnds.map((e) => ({
            endName: e.name,
            workContext: e.workId,
            excerpt: "",
          })),
        );
        for (const op of ops) {
          if (op.op === "add-end") {
            await client.linkAddEnd(linkId, op.endName, {
              workContext: op.span.workContext,
              excerpt: op.span.excerpt ?? "",
            });
          } else {
            await client.linkEndAddAttachment(linkId, op.endName, {
              workContext: op.span.workContext,
              excerpt: op.span.excerpt ?? "",
            });
          }
        }
        if (description.trim()) {
          await client.annotationCreate(
            source.workId,
            Date.now(),
            "link-description",
            JSON.stringify({ link_id: linkId, text: description.trim() }),
            source.start,
            source.end,
          );
          // FR-40 L4 (winfe FELink:Descriptor): the description is
          // ALSO a named end holding a fresh note work — Gold's
          // descriptor-end pattern, portable with the link.
          try {
            const resp = await client.sendRequest("work_create", {
              edition: { text: description.trim() },
            });
            const r = resp as Record<string, unknown>;
            const val = (r && typeof r === "object" && "value" in r) ? r.value : resp;
            const noteWorkId = typeof val === "number"
              ? val
              : (val && typeof val === "object" && "work_id" in val) ? (val as Record<string, unknown>).work_id as number : null;
            if (noteWorkId !== null) {
              await client.linkAddEnd(linkId, "Descriptor", {
                workContext: noteWorkId,
                excerpt: description.trim().slice(0, 120),
              });
            }
          } catch {
            // The annotation above already carries the description;
            // the descriptor end is additive and best-effort here.
          }
        }
        setStep("done");
        setTimeout(() => {
          onLinkCreated();
          handleClose();
        }, 800);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to create link");
      setCreating(false);
    }
  };

  const handleFetchRemote = async () => {
    if (!fetchUrl.trim() || !fetchWorkId.trim()) return;
    setFetching(true);
    setError(null);
    try {
      const baseUrl = fetchUrl.trim().replace(/\/$/, "");
      const workId = fetchWorkId.trim().replace(/^0x/i, "");
      const resp = await fetch(`${baseUrl}/api/public/work/${workId}`);
      if (!resp.ok) {
        const body = await resp.text();
        setError(`Server returned ${resp.status}: ${body.slice(0, 100)}`);
        setFetching(false);
        return;
      }
      const data = await resp.json();
      if (data.tumbler) setRemoteTumbler(data.tumbler);
      if (data.content_hash_blake3) setRemoteHash(data.content_hash_blake3);
      if (data.span_provenance && data.span_provenance.length > 0) {
        const prov = data.span_provenance[0];
        if (prov.author_public_key) setRemoteAuthorKey(prov.author_public_key);
      }
      if (data.server_public_key) setRemoteAuthorKey(data.server_public_key);
      if (data.title) setRemoteAuthor(data.title);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to fetch from server");
    }
    setFetching(false);
  };

  const handleCreateRemote = async () => {
    if (!clientRef.current || !source) return;
    const client = clientRef.current;
    if (!remoteTumbler.trim()) {
      setError("Tumbler is required");
      return;
    }
    if (!remoteHash.trim() || remoteHash.trim().length !== 64) {
      setError("Content hash must be 64 hex characters (BLAKE3)");
      return;
    }
    setCreating(true);
    setError(null);
    try {
      const csr: CrossServerRefPayload = {
        tumbler: remoteTumbler.trim(),
        content_hash: remoteHash.trim(),
        origin_author: remoteAuthor.trim() || "unknown",
        origin_author_key: remoteAuthorKey.trim() || "00".repeat(32),
        excerpt: source.text.slice(0, 200),
      };
      await client.linkCreateCrossServer(source.workId, {
        excerpt: source.text,
        start: source.start,
        end: source.end,
      }, csr);
      setStep("done");
      setTimeout(() => {
        onLinkCreated();
        handleClose();
      }, 800);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to create cross-server link");
      setCreating(false);
    }
  };

  const handleCreateWebLink = async () => {
    if (!clientRef.current || !source) return;
    const url = webUrl.trim();
    if (!url || !/^https?:\/\//.test(url)) {
      setError("Enter a valid URL (starting with http:// or https://)");
      return;
    }
    setCreating(true);
    setError(null);
    try {
      const linkId = await clientRef.current.linkCreate(
        source.workId,
        source.workId,
        { excerpt: source.text, start: source.start, end: source.end },
        { excerpt: url, start: 0, end: 0 },
      );
      await clientRef.current.linkSetTypes(linkId, [6]);
      setStep("done");
      setTimeout(() => {
        onLinkCreated();
        handleClose();
      }, 800);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to create web link");
      setCreating(false);
    }
  };

  const sourcePreview = source.text.length > 120 ? source.text.slice(0, 120) + "\u2026" : source.text;

  return (
    <div className="modal-overlay" onClick={handleClose}>
      <div
        className="modal-content link-creator-modal"
        onClick={(e) => e.stopPropagation()}
        style={{ maxWidth: 760 }}
      >
        <div className="link-creator-header">
          <h3>Create Link</h3>
          <button type="button" className="link-creator-close" onClick={handleClose}>
            {"\u00d7"}
          </button>
        </div>

        <div className="link-creator-source">
          <div className="link-creator-source-label">From: {source.workTitle}</div>
          <div className="link-creator-source-text">&ldquo;{sourcePreview}&rdquo;</div>
        </div>

        {step === "target" && (
          <div className="link-creator-body">
            <div className="link-creator-step-title">What do you want to link this to?</div>
            <div className="link-target-options">
              <button
                type="button"
                className="link-target-option"
                onClick={() => handleChooseTarget("whole-work")}
              >
                <div className="link-target-icon">{"\u2192"}</div>
                <div className="link-target-text">
                  <div className="link-target-name">Link to an entire document</div>
                  <div className="link-target-desc">Pick a document from your library</div>
                </div>
              </button>
              <button
                type="button"
                className="link-target-option"
                onClick={() => handleChooseTarget("other-doc-text")}
              >
                <div className="link-target-icon">{"\u201c\u201d"}</div>
                <div className="link-target-text">
                  <div className="link-target-name">Link to specific text in another document</div>
                  <div className="link-target-desc">Navigate to another document and select a passage</div>
                </div>
              </button>
              {currentWorkId === source.workId && (
                <button
                  type="button"
                  className="link-target-option"
                  onClick={() => handleChooseTarget("same-doc")}
                >
                  <div className="link-target-icon">{"\u21bb"}</div>
                  <div className="link-target-text">
                    <div className="link-target-name">Link to another part of this document</div>
                    <div className="link-target-desc">Select different text in the same document</div>
                  </div>
                </button>
              )}
              <button
                type="button"
                className="link-target-option"
                onClick={() => handleChooseTarget("remote")}
              >
                <div className="link-target-icon">{"\u2302"}</div>
                <div className="link-target-text">
                  <div className="link-target-name">Link to a remote server</div>
                  <div className="link-target-desc">Connect to content on another Xudanu server</div>
                </div>
              </button>
              <button
                type="button"
                className="link-target-option"
                onClick={() => handleChooseTarget("web")}
              >
                <div className="link-target-icon">{"\u2197"}</div>
                <div className="link-target-text">
                  <div className="link-target-name">Link to a website</div>
                  <div className="link-target-desc">One-way web link to an external URL</div>
                </div>
              </button>
              <button
                type="button"
                className="link-target-option"
                onClick={handlePasteReference}
              >
                <div className="link-target-icon">{"\u2398"}</div>
                <div className="link-target-text">
                  <div className="link-target-name">Paste cross-server reference</div>
                  <div className="link-target-desc">Auto-fill from clipboard (use Copy Ref on published works)</div>
                </div>
              </button>
            </div>

            {targetMode === "whole-work" && (
              <div className="link-work-picker">
                <div className="link-work-picker-label">Select a document:</div>
                <div className="link-work-list">
                  {otherWorks.length === 0 ? (
                    <div className="link-work-empty">No other documents available</div>
                  ) : (
                    otherWorks.map((w) => (
                      <button
                        key={w.work_id}
                        type="button"
                        className={`link-work-item ${selectedWorkId === w.work_id ? "selected" : ""}`}
                        onClick={() => handlePickWork(w.work_id)}
                      >
                        <span className="link-work-title">{w.title || "Untitled"}</span>
                        <span className="link-work-id">{w.work_id.toString(16).padStart(4, "0")}</span>
                      </button>
                    ))
                  )}
                </div>
              </div>
            )}
          </div>
        )}

        {step === "type" && targetMode === "whole-work" && selectedWorkId !== null && (
          <div className="link-creator-body">
            <div className="link-creator-step-title">
              Link type
              <span style={{ fontSize: 11, color: "#8b949e", marginLeft: 8 }}>
                toggle one or more
              </span>
              <button
                type="button"
                className="link-back-btn"
                onClick={() => { setStep("target"); setSelectedTypeIds(new Set()); }}
              >
                {"\u2190"} back
              </button>
            </div>
            <div className="link-target-preview">
              Linking to:{" "}
              <strong>{works.find((w) => w.work_id === selectedWorkId)?.title || "Unknown"}</strong>
            </div>
            <div className="link-type-grid">
              {allTypes.map((t) => {
                const selected = selectedTypeIds.has(t.type_id);
                return (
                  <button
                    key={t.type_id}
                    type="button"
                    className={`link-type-card ${selected ? "selected" : ""}`}
                    style={{ borderColor: selected ? t.color : undefined }}
                    onClick={() => toggleType(t.type_id)}
                  >
                    <div className="link-type-preview-line">
                      <svg width="60" height="8">
                        <line
                          x1="0" y1="4" x2="60" y2="4"
                          stroke={t.color}
                          strokeWidth="2"
                          strokeDasharray={t.lineStyle === "solid" ? undefined : t.lineStyle === "dashed" ? "4,3" : t.lineStyle === "dotted" ? "1,3" : t.lineStyle === "underline" ? "8,3" : "6,2,1,2"}
                        />
                      </svg>
                      {t.custom && (
                        <span style={{ fontSize: 9, color: "#8b949e", marginLeft: 4 }}>custom</span>
                      )}
                    </div>
                    <div className="link-type-card-name" style={{ color: t.color }}>{t.name}</div>
                    <div className="link-type-card-desc">{typeDesc(t.type_id)}</div>
                  </button>
                );
              })}
            </div>
            {selectedTypeIds.size > 0 && (
              <>
                <div className="link-form-label" style={{ marginTop: 12 }}>
                  Description
                  <textarea
                    className="link-form-input"
                    placeholder="Explain why this link exists — this appears in the margin box next to the linked text"
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    rows={3}
                    style={{ resize: "vertical", fontFamily: "inherit", fontSize: 13 }}
                  />
                </div>
                <div className="link-form-label" style={{ marginTop: 8 }}>
                  Home document (optional — the link lives in this work)
                  <select
                    className="link-form-input"
                    value={homeDocument}
                    onChange={(e) => setHomeDocument(e.target.value === "" ? "" : Number(e.target.value))}
                  >
                    <option value="">Server-wide (no home)</option>
                    {works.map((w) => (
                      <option key={w.work_id} value={w.work_id}>
                        {w.title || "Untitled"}
                      </option>
                    ))}
                  </select>
                </div>
                <div style={{ marginTop: 8 }}>
                  <button
                    type="button"
                    className="link-create-submit"
                    style={{ background: "transparent", border: "1px solid #30363d", color: "#8b949e", width: "100%", marginBottom: extraEnds.length > 0 ? 8 : 0 }}
                    disabled={creating}
                    onClick={() => setStep("extra-ends")}
                  >
                    + Add another end (multi-ended link)
                    {extraEnds.length > 0 && ` — ${extraEnds.length} added`}
                  </button>
                </div>
                <button
                  type="button"
                  className="link-create-submit"
                  disabled={creating}
                  onClick={handleCreate}
                >
                  {creating ? "Creating\u2026" : `Create Link${selectedTypeIds.size > 1 ? ` (${selectedTypeIds.size} types)` : ""}`}
                </button>
              </>
            )}
            {error && <div className="link-creator-error">{error}</div>}
          </div>
        )}

        {step === "extra-ends" && (
          <div className="link-creator-body">
            <div className="link-creator-step-title">
              Additional ends
              <button
                type="button"
                className="link-back-btn"
                onClick={() => setStep("type")}
              >
                {"\u2190"} back
              </button>
            </div>
            <div className="link-form-hint">
              A multi-ended link is ONE connection between several places — "A, B and C form a
              comparison." Each extra end is clickable in Connections and joinable from every
              end's work.
            </div>
            {extraEnds.length > 0 && (
              <div style={{ margin: "8px 0" }}>
                {extraEnds.map((e, i) => {
                  const memberCount = extraEnds.filter((x) => x.name === e.name).length;
                  const gathering = gatherFor === e.name;
                  return (
                    <div key={i} style={{ marginBottom: 4 }}>
                      <div
                        style={{
                          display: "flex",
                          justifyContent: "space-between",
                          alignItems: "center",
                          padding: "4px 8px",
                          border: "1px solid #30363d",
                          borderRadius: 4,
                          fontSize: 12,
                        }}
                      >
                        <span>
                          <strong>{e.name}</strong>
                          {memberCount > 1 && (
                            <em style={{ color: "#7ee787", marginLeft: 6 }}>
                              {memberCount} passages
                            </em>
                          )}{" "}
                          → {works.find((w) => w.work_id === e.workId)?.title || `0x${e.workId.toString(16)}`}
                        </span>
                        <span>
                          <button
                            type="button"
                            title="Gather another passage into this end"
                            onClick={() => setGatherFor(gathering ? null : e.name)}
                            style={{ background: "none", border: "none", color: "#7ee787", cursor: "pointer", marginRight: 6 }}
                          >
                            {"\uFF0B"}
                          </button>
                          <button
                            type="button"
                            onClick={() => setExtraEnds((prev) => prev.filter((_, j) => j !== i))}
                            style={{ background: "none", border: "none", color: "#f85149", cursor: "pointer" }}
                          >
                            ×
                          </button>
                        </span>
                      </div>
                      {gathering && (
                        <div style={{ padding: "4px 8px", borderLeft: "2px solid #7ee787", margin: "2px 0 4px 8px" }}>
                          <div style={{ fontSize: 11, color: "#8b949e", marginBottom: 4 }}>
                            Add passages to <strong>{e.name}</strong> — they become ONE gathered end:
                          </div>
                          <div className="link-work-list">
                            {otherWorks
                              .filter(
                                (w) =>
                                  w.work_id !== selectedWorkId &&
                                  !extraEnds.some((x) => x.name === e.name && x.workId === w.work_id),
                              )
                              .map((w) => (
                                <button
                                  key={w.work_id}
                                  type="button"
                                  className="link-work-item"
                                  onClick={() =>
                                    setExtraEnds((prev) => [
                                      ...prev,
                                      { name: e.name, workId: w.work_id },
                                    ])
                                  }
                                >
                                  <span className="link-work-title">{w.title || "Untitled"}</span>
                                  <span className="link-work-id">{w.work_id.toString(16).padStart(4, "0")}</span>
                                </button>
                              ))}
                          </div>
                          <button
                            type="button"
                            onClick={() => setGatherFor(null)}
                            style={{ background: "none", border: "1px solid #30363d", color: "#8b949e", borderRadius: 4, fontSize: 11, marginTop: 4, cursor: "pointer" }}
                          >
                            done gathering
                          </button>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
            <div className="link-work-picker">
              <div className="link-work-picker-label">Pick a work to add as an end:</div>
              <div className="link-work-list">
                {otherWorks
                  .filter((w) => w.work_id !== selectedWorkId && !extraEnds.some((e) => e.workId === w.work_id))
                  .map((w) => (
                    <button
                      key={w.work_id}
                      type="button"
                      className="link-work-item"
                      onClick={() =>
                        setExtraEnds((prev) => [
                          ...prev,
                          { name: `End${prev.length + 1}`, workId: w.work_id },
                        ])
                      }
                    >
                      <span className="link-work-title">{w.title || "Untitled"}</span>
                      <span className="link-work-id">{w.work_id.toString(16).padStart(4, "0")}</span>
                    </button>
                  ))}
              </div>
            </div>
            <button
              type="button"
              className="link-create-submit"
              disabled={creating || selectedTypeIds.size === 0}
              onClick={handleCreate}
            >
              {creating ? "Creating\u2026" : `Create Link (${2 + new Set(extraEnds.map((e) => e.name)).size} ends)`}
            </button>
            {error && <div className="link-creator-error">{error}</div>}
          </div>
        )}

        {step === "remote" && (
          <div className="link-creator-body">
            <div className="link-creator-step-title">
              Remote server link
              <button
                type="button"
                className="link-back-btn"
                onClick={() => { setStep("target"); }}
              >
                {"\u2190"} back
              </button>
            </div>
            <div className="link-remote-form">
              <div className="link-form-hint" style={{ marginBottom: 12, padding: 8, background: "rgba(88,166,255,0.08)", borderRadius: 4, border: "1px solid rgba(88,166,255,0.2)" }}>
                Auto-fill from remote server:
              </div>
              <div style={{ display: "flex", gap: 6, marginBottom: 12 }}>
                <input
                  type="text"
                  className="link-form-input"
                  placeholder="http://localhost:8081"
                  value={fetchUrl}
                  onChange={(e) => setFetchUrl(e.target.value)}
                  style={{ flex: 2 }}
                />
                <input
                  type="text"
                  className="link-form-input"
                  placeholder="0x5b3"
                  value={fetchWorkId}
                  onChange={(e) => setFetchWorkId(e.target.value)}
                  style={{ flex: 1 }}
                />
                <button
                  type="button"
                  className="link-create-submit"
                  disabled={fetching || !fetchUrl.trim() || !fetchWorkId.trim()}
                  onClick={handleFetchRemote}
                  style={{ flex: 0, padding: "0 12px", whiteSpace: "nowrap" }}
                >
                  {fetching ? "..." : "Fetch"}
                </button>
              </div>
              <label className="link-form-label">
                Tumbler
                <input
                  type="text"
                  className="link-form-input"
                  placeholder={"\"alice.example.com\".5.3.10.7"}
                  value={remoteTumbler}
                  onChange={(e) => setRemoteTumbler(e.target.value)}
                />
              </label>
              <div className="link-form-hint">
                The Xanadu-style global identifier for the remote content.
                Domain format: <code>{'"server.domain".work_id.v.revision.edition'}</code>
              </div>
              <label className="link-form-label">
                Content hash (BLAKE3, hex)
                <input
                  type="text"
                  className="link-form-input mono"
                  placeholder="e.g. a1b2c3d4..."
                  value={remoteHash}
                  onChange={(e) => setRemoteHash(e.target.value)}
                />
              </label>
              <div className="link-form-hint">
                64-character hex hash from the remote server. Used to verify content integrity.
              </div>
              <label className="link-form-label">
                Author name (optional)
                <input
                  type="text"
                  className="link-form-input"
                  placeholder="remote author"
                  value={remoteAuthor}
                  onChange={(e) => setRemoteAuthor(e.target.value)}
                />
              </label>
              <label className="link-form-label">
                Author public key (hex, optional)
                <input
                  type="text"
                  className="link-form-input mono"
                  placeholder="64 hex chars..."
                  value={remoteAuthorKey}
                  onChange={(e) => setRemoteAuthorKey(e.target.value)}
                />
              </label>
              {error && <div className="link-creator-error">{error}</div>}
              <button
                type="button"
                className="link-create-submit"
                disabled={creating}
                onClick={handleCreateRemote}
              >
                {creating ? "Creating\u2026" : "Create Remote Link"}
              </button>
            </div>
          </div>
        )}

        {step === "web" && (
          <div className="link-creator-body">
            <div className="link-creator-step-title">
              Web link
              <button
                type="button"
                className="link-back-btn"
                onClick={() => { setStep("target"); }}
              >
                {"\u2190"} back
              </button>
            </div>
            <div className="link-remote-form">
              <label className="link-form-label">
                URL
                <input
                  type="url"
                  className="link-form-input"
                  placeholder="https://example.com/article"
                  value={webUrl}
                  onChange={(e) => setWebUrl(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") { e.preventDefault(); handleCreateWebLink(); }
                  }}
                />
              </label>
              <div className="link-form-hint">
                One-way link to an external website. Opens in a new tab when clicked.
              </div>
              {error && <div className="link-creator-error">{error}</div>}
              <button
                type="button"
                className="link-create-submit"
                disabled={creating || !webUrl.trim()}
                onClick={handleCreateWebLink}
              >
                {creating ? "Creating\u2026" : "Create Web Link"}
              </button>
            </div>
          </div>
        )}

        {step === "done" && (
          <div className="link-creator-done">
            <div className="link-creator-done-icon">{"\u2713"}</div>
            <div className="link-creator-done-text">Link created</div>
          </div>
        )}
      </div>
    </div>
  );
}
