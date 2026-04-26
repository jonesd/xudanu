import { useState, useRef, useEffect } from "react";
import type { ApiText } from "../types/api";

interface EditableSpanProps {
  text: ApiText;
  spanId: string;
  workspaceId: string;
  onUpdated: () => void;
}

export function EditableSpan({
  text,
  spanId,
  workspaceId,
  onUpdated,
}: EditableSpanProps) {
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState("");
  const [saving, setSaving] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (editing && inputRef.current) {
      inputRef.current.focus();
      inputRef.current.select();
    }
  }, [editing]);

  const currentValue =
    text.type === "single" ? text.value : text.values.join(" | ");

  function startEditing() {
    setDraft(currentValue);
    setEditing(true);
  }

  async function commit() {
    setEditing(false);
    if (draft === currentValue) return;
    setSaving(true);
    try {
      const id = parseInt(spanId.replace("span-", ""), 10);
      const { setSpanText } = await import("../api/client");
      await setSpanText(workspaceId, id, draft);
      onUpdated();
    } catch (e) {
      console.error("Failed to update span:", e);
    } finally {
      setSaving(false);
    }
  }

  function handleKeyDown(e: React.KeyboardEvent) {
    if (e.key === "Enter") {
      e.preventDefault();
      commit();
    } else if (e.key === "Escape") {
      setEditing(false);
    }
  }

  if (editing) {
    return (
      <input
        ref={inputRef}
        className="span-edit-input"
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        onBlur={commit}
        onKeyDown={handleKeyDown}
        disabled={saving}
      />
    );
  }

  return (
    <span
      className="span-editable"
      onClick={startEditing}
      role="button"
      tabIndex={0}
      onKeyDown={(e) => e.key === "Enter" && startEditing()}
    >
      {text.type === "single" ? (
        <span className="span-text">{text.value}</span>
      ) : (
        <span className="span-alternatives">
          {text.values.map((v, i) => (
            <span key={i} className="alternative">
              {i > 0 && <span className="alternative-divider"> | </span>}
              {v}
            </span>
          ))}
        </span>
      )}
      {saving && <span className="saving-indicator">...</span>}
    </span>
  );
}
