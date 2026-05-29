import { useState, useCallback, useRef, useEffect } from "react";
import type { CrdtSyncClient } from "../api/crdt_sync";
import type {
  HistoricalAuthor,
  HistoricalAuthorEntry,
  SourceDetectResult,
} from "../api/crdt_sync";

interface ImportWizardProps {
  clientRef: React.RefObject<CrdtSyncClient | null>;
  visible: boolean;
  onClose: () => void;
  onImported: (workId: number) => void;
}

type Step = "paste" | "detect" | "author" | "preview" | "importing" | "done";

export function ImportWizard({ clientRef, visible, onClose, onImported }: ImportWizardProps) {
  const [step, setStep] = useState<Step>("paste");
  const [rawText, setRawText] = useState("");
  const [detection, setDetection] = useState<SourceDetectResult | null>(null);
  const [authors, setAuthors] = useState<HistoricalAuthorEntry[]>([]);
  const [selectedAuthorId, setSelectedAuthorId] = useState<number | null>(null);
  const [newAuthorName, setNewAuthorName] = useState("");
  const [newAuthorDisplay, setNewAuthorDisplay] = useState("");
  const [newAuthorBirth, setNewAuthorBirth] = useState("");
  const [newAuthorDeath, setNewAuthorDeath] = useState("");
  const [newAuthorBiblio, setNewAuthorBiblio] = useState("");
  const [title, setTitle] = useState("");
  const [editionInfo, setEditionInfo] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [createdAuthor, setCreatedAuthor] = useState<HistoricalAuthor | null>(null);
  const [importedWorkId, setImportedWorkId] = useState<number | null>(null);
  const [contentText, setContentText] = useState("");
  const textAreaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    if (visible) {
      setStep("paste");
      setRawText("");
      setDetection(null);
      setSelectedAuthorId(null);
      setNewAuthorName("");
      setNewAuthorDisplay("");
      setNewAuthorBirth("");
      setNewAuthorDeath("");
      setNewAuthorBiblio("");
      setTitle("");
      setEditionInfo("");
      setError(null);
      setCreatedAuthor(null);
      setImportedWorkId(null);
      setContentText("");
    }
  }, [visible]);

  useEffect(() => {
    if (step === "paste" && textAreaRef.current) {
      textAreaRef.current.focus();
    }
  }, [step]);

  const loadAuthors = useCallback(async () => {
    const client = clientRef.current;
    if (!client) return;
    try {
      const list = await client.listHistoricalAuthors();
      setAuthors(list);
    } catch (e) {
      console.warn("Failed to load authors:", e);
    }
  }, [clientRef]);

  const handleDetect = useCallback(async () => {
    const client = clientRef.current;
    if (!client) {
      setError("Not connected to server");
      return;
    }
    if (rawText.trim().length === 0) {
      setError("Please paste some text first");
      return;
    }
    setError(null);
    try {
      const result = await client.detectSource(rawText);
      setDetection(result);

      const lines = rawText.split("\n");
      const start = result.content_start_line;
      const end = result.content_end_line;
      const content = lines.slice(start, end).join("\n");
      setContentText(content);

      const metaTitle = result.metadata["title"] || "";
      if (metaTitle) {
        const cleaned = metaTitle.replace(/^Title:\s*/i, "").trim();
        setTitle(cleaned);
      }
      setNewAuthorBirth("");
      setNewAuthorDeath("");
      setNewAuthorBiblio("");
      const metaAuthor = result.metadata["author"] || "";
      if (metaAuthor) {
        const cleaned = metaAuthor.replace(/^Author:\s*/i, "").trim();
        setNewAuthorName(cleaned);
        setNewAuthorDisplay(cleaned);
      }

      const sourceLabel = result.source_type === "gutenberg"
        ? `Project Gutenberg`
        : result.source_type === "internet_archive"
          ? "Internet Archive"
          : result.source_type;
      let info = `Imported from ${sourceLabel}`;
      const gid = result.metadata["gutenberg_id"];
      if (gid) info += ` (eBook #${gid.replace(/[^0-9]/g, "")})`;
      setEditionInfo(info);

      await loadAuthors();
      setStep("detect");
    } catch (e) {
      console.error("Source detect failed:", e);
      setError(String(e));
    }
  }, [clientRef, rawText, loadAuthors]);

  const handleCreateAuthor = useCallback(async () => {
    const client = clientRef.current;
    if (!client || !newAuthorName.trim()) return;
    setError(null);
    try {
      const author = await client.registerHistoricalAuthor(
        newAuthorName.trim(),
        newAuthorDisplay.trim() || newAuthorName.trim(),
        newAuthorBirth ? parseInt(newAuthorBirth, 10) : null,
        newAuthorDeath ? parseInt(newAuthorDeath, 10) : null,
        {},
        newAuthorBiblio.trim(),
      );
      setCreatedAuthor(author);
      setSelectedAuthorId(author.be_id);
      setStep("preview");
    } catch (e) {
      setError(String(e));
    }
  }, [clientRef, newAuthorName, newAuthorDisplay, newAuthorBirth, newAuthorDeath, newAuthorBiblio]);

  const handleSelectAuthor = useCallback(() => {
    if (selectedAuthorId === null) return;
    setStep("preview");
  }, [selectedAuthorId]);

  const handleImport = useCallback(async () => {
    const client = clientRef.current;
    if (!client || !rawText) return;
    const authorId = createdAuthor?.be_id || selectedAuthorId;
    if (!authorId) return;
    setError(null);
    setStep("importing");
    try {
      const startLine = detection?.content_start_line || 0;
      const endLine = detection?.content_end_line || rawText.split("\n").length;
      const result = await client.importSourceWork(
        authorId,
        title.trim(),
        rawText,
        editionInfo.trim(),
        startLine,
        rawText.split("\n").length - endLine,
      );
      setImportedWorkId(result.workId);
      setStep("done");
    } catch (e) {
      setError(String(e));
      setStep("preview");
    }
  }, [clientRef, rawText, detection, selectedAuthorId, createdAuthor, title, editionInfo]);

  if (!visible) return null;

  const sourceLabel = detection
    ? detection.source_type === "gutenberg"
      ? "Project Gutenberg"
      : detection.source_type === "internet_archive"
        ? "Internet Archive"
        : detection.source_type
    : "";

  return (
    <div className="wizard-overlay">
      <div className="wizard-modal">
        <div className="wizard-header">
          <h2>Import Source Work</h2>
          <button className="wizard-close" onClick={onClose}>&times;</button>
        </div>

        <div className="wizard-steps">
          <span className={step !== "paste" ? "step-done" : "step-active"}>1. Paste</span>
          <span className={["detect", "author", "preview", "importing", "done"].includes(step) ? "step-done" : step === "paste" ? "" : "step-active"}>2. Detect</span>
          <span className={["preview", "importing", "done"].includes(step) ? "step-done" : step === "author" ? "step-active" : ""}>3. Author</span>
          <span className={["importing", "done"].includes(step) ? "step-done" : step === "preview" ? "step-active" : ""}>4. Import</span>
        </div>

        {error && <div className="wizard-error">{error}</div>}

        {step === "paste" && (
          <div className="wizard-body">
            <p className="wizard-hint">Paste the full text from a published source (Project Gutenberg, Internet Archive, etc.)</p>
            <textarea
              ref={textAreaRef}
              className="wizard-textarea"
              value={rawText}
              onChange={(e) => setRawText(e.target.value)}
              placeholder="Paste text here..."
              rows={12}
            />
            <div className="wizard-actions">
              <button className="wizard-btn-secondary" onClick={onClose}>Cancel</button>
              <button className="wizard-btn-primary" onClick={handleDetect} disabled={rawText.trim().length === 0}>
                Detect Source
              </button>
            </div>
          </div>
        )}

        {step === "detect" && detection && (
          <div className="wizard-body">
            <div className="detect-result">
              <div className="detect-badge">
                <span className={`source-badge source-${detection.source_type}`}>
                  {sourceLabel}
                </span>
                {detection.detected && <span className="detect-yes">Detected</span>}
              </div>
              <div className="detect-lines">
                <span>Total: {detection.total_lines} lines</span>
                {detection.content_start_line > 0 && (
                  <span>Skipping first {detection.content_start_line} lines (header)</span>
                )}
                {detection.content_end_line < detection.total_lines && (
                  <span>Skipping last {detection.total_lines - detection.content_end_line} lines (footer)</span>
                )}
                <span>Content: {detection.content_end_line - detection.content_start_line} lines</span>
              </div>
              {Object.keys(detection.metadata).length > 0 && (
                <div className="detect-metadata">
                  {Object.entries(detection.metadata).map(([k, v]) => (
                    <div key={k} className="meta-row">
                      <span className="meta-key">{k}:</span>
                      <span className="meta-value">{v}</span>
                    </div>
                  ))}
                </div>
              )}
            </div>
            <div className="wizard-actions">
              <button className="wizard-btn-secondary" onClick={() => setStep("paste")}>Back</button>
              <button className="wizard-btn-primary" onClick={() => { setStep("author"); loadAuthors(); }}>
                Continue
              </button>
            </div>
          </div>
        )}

        {step === "author" && (
          <div className="wizard-body">
            <div className="author-section">
              <h4>Select Existing Author</h4>
              {authors.length === 0 && <p className="wizard-hint">No historical authors registered yet.</p>}
              <ul className="author-select-list">
                {authors.map((a) => (
                  <li key={a.be_id} className={`author-select-item${selectedAuthorId === a.be_id ? " selected" : ""}`}>
                    <label>
                      <input
                        type="radio"
                        name="author"
                        checked={selectedAuthorId === a.be_id}
                        onChange={() => setSelectedAuthorId(a.be_id)}
                      />
                      <span className="author-select-name">{a.display_name}</span>
                      {a.birth_year != null && <span className="author-select-years">({a.birth_year}{a.death_year != null ? `\u2013${a.death_year}` : ""})</span>}
                    </label>
                  </li>
                ))}
              </ul>
              {selectedAuthorId !== null && (
                <button className="wizard-btn-primary" onClick={handleSelectAuthor}>
                  Use Selected Author
                </button>
              )}
            </div>

            <div className="author-divider">
              <span>or create a new author</span>
            </div>

            <div className="author-section">
              <h4>New Author</h4>
              <div className="wizard-field">
                <label>Name</label>
                <input value={newAuthorName} onChange={(e) => setNewAuthorName(e.target.value)} placeholder="e.g. Vitruvius" />
              </div>
              <div className="wizard-field">
                <label>Display Name</label>
                <input value={newAuthorDisplay} onChange={(e) => setNewAuthorDisplay(e.target.value)} placeholder="e.g. Vitruvius (c. 80\u201315 BC)" />
              </div>
              <div className="wizard-field-row">
                <div className="wizard-field">
                  <label>Birth Year</label>
                  <input type="number" value={newAuthorBirth} onChange={(e) => setNewAuthorBirth(e.target.value)} placeholder="-80" />
                </div>
                <div className="wizard-field">
                  <label>Death Year</label>
                  <input type="number" value={newAuthorDeath} onChange={(e) => setNewAuthorDeath(e.target.value)} placeholder="-15" />
                </div>
              </div>
              <div className="wizard-field">
                <label>Bibliography</label>
                <input value={newAuthorBiblio} onChange={(e) => setNewAuthorBiblio(e.target.value)} placeholder="e.g. De Architectura, trans. Morgan, 1914" />
              </div>
              <button className="wizard-btn-primary" onClick={handleCreateAuthor} disabled={!newAuthorName.trim()}>
                Create Author
              </button>
            </div>

            <div className="wizard-actions">
              <button className="wizard-btn-secondary" onClick={() => setStep("detect")}>Back</button>
            </div>
          </div>
        )}

        {step === "preview" && (
          <div className="wizard-body">
            <div className="wizard-field">
              <label>Title</label>
              <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Work title" />
            </div>
            <div className="wizard-field">
              <label>Edition Info</label>
              <input value={editionInfo} onChange={(e) => setEditionInfo(e.target.value)} />
            </div>
            <div className="preview-summary">
              <span>Content: {contentText.length.toLocaleString()} chars, {detection?.content_end_line ?? 0 - (detection?.content_start_line ?? 0)} lines</span>
              <span>Author: {createdAuthor?.display_name || authors.find((a) => a.be_id === selectedAuthorId)?.display_name || "unknown"}</span>
              <span>Source: {sourceLabel}</span>
            </div>
            <div className="wizard-actions">
              <button className="wizard-btn-secondary" onClick={() => setStep("author")}>Back</button>
              <button className="wizard-btn-primary" onClick={handleImport}>
                Import as Source Work
              </button>
            </div>
          </div>
        )}

        {step === "importing" && (
          <div className="wizard-body">
            <p className="wizard-hint">Importing...</p>
          </div>
        )}

        {step === "done" && importedWorkId !== null && (
          <div className="wizard-body">
            <p className="wizard-success">Source work imported successfully!</p>
            <p className="wizard-detail">Work ID: {importedWorkId}</p>
            <div className="wizard-actions">
              <button className="wizard-btn-secondary" onClick={onClose}>Close</button>
              <button className="wizard-btn-primary" onClick={() => { onImported(importedWorkId); onClose(); }}>
                Open Work
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
