import { useState, useMemo } from "react";
import type { CrdtSyncClient, WorkListEntry, CrossServerRefPayload } from "../api/crdt_sync";
import { DEFAULT_LINK_TYPES } from "../hooks/useTransclusion";

const LINK_TYPE_DESCRIPTIONS: Record<number, string> = {
  1: "Annotate a passage or add a scholarly note",
  2: "Cross-reference, citation, or 'see this'",
  3: "Mark a contested claim or counter-argument",
  4: "This passage quotes another source",
  5: "Related reading path or similar work",
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

type Step = "target" | "type" | "remote" | "web" | "done";
type TargetMode = "whole-work" | "other-doc-text" | "same-doc" | "remote" | "web" | null;

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
  const [selectedTypeId, setSelectedTypeId] = useState<number | null>(null);
  const [creating, setCreating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [remoteTumbler, setRemoteTumbler] = useState("");
  const [remoteHash, setRemoteHash] = useState("");
  const [remoteAuthor, setRemoteAuthor] = useState("");
  const [remoteAuthorKey, setRemoteAuthorKey] = useState("");
  const [webUrl, setWebUrl] = useState("");
  const [description, setDescription] = useState("");

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
    setSelectedTypeId(null);
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

  const handleCreate = async () => {
    if (!clientRef.current || !source || selectedTypeId === null) return;
    const client = clientRef.current;
    setCreating(true);
    setError(null);
    try {
      if (targetMode === "whole-work" && selectedWorkId !== null) {
        const targetWork = works.find((w) => w.work_id === selectedWorkId);
        const linkId = await client.linkCreate(
          source.workId,
          selectedWorkId,
          { excerpt: source.text, start: source.start, end: source.end },
          { excerpt: "", start: 0, end: 0 },
        );
        if (selectedTypeId > 0) {
          await client.linkSetTypes(linkId, [selectedTypeId]);
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
        }
        void targetWork;
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
              <button
                type="button"
                className="link-back-btn"
                onClick={() => { setStep("target"); setSelectedTypeId(null); }}
              >
                {"\u2190"} back
              </button>
            </div>
            <div className="link-target-preview">
              Linking to:{" "}
              <strong>{works.find((w) => w.work_id === selectedWorkId)?.title || "Unknown"}</strong>
            </div>
            <div className="link-type-grid">
              {DEFAULT_LINK_TYPES.map((t) => (
                <button
                  key={t.type_id}
                  type="button"
                  className={`link-type-card ${selectedTypeId === t.type_id ? "selected" : ""}`}
                  style={{ borderColor: selectedTypeId === t.type_id ? t.color : undefined }}
                  onClick={() => setSelectedTypeId(t.type_id)}
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
                  </div>
                  <div className="link-type-card-name" style={{ color: t.color }}>{t.name}</div>
                  <div className="link-type-card-desc">{LINK_TYPE_DESCRIPTIONS[t.type_id]}</div>
                </button>
              ))}
            </div>
            {selectedTypeId !== null && (
              <label className="link-form-label" style={{ marginTop: 12 }}>
                Description
                <textarea
                  className="link-form-input"
                  placeholder="Explain why this link exists — this appears in the margin box next to the linked text"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  rows={3}
                  style={{ resize: "vertical", fontFamily: "inherit", fontSize: 13 }}
                />
              </label>
            )}
            {error && <div className="link-creator-error">{error}</div>}
            <button
              type="button"
              className="link-create-submit"
              disabled={selectedTypeId === null || creating}
              onClick={handleCreate}
            >
              {creating ? "Creating\u2026" : "Create Link"}
            </button>
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
