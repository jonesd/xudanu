import { useState, useEffect, useRef } from "react";

interface AnnotationDialogProps {
  open: boolean;
  charStart: number;
  charEnd: number;
  onCreate: (text: string, isPrivate: boolean) => void;
  onClose: () => void;
}

export function AnnotationDialog({ open, charStart, charEnd, onCreate, onClose }: AnnotationDialogProps) {
  const [text, setText] = useState("");
  const [isPrivate, setIsPrivate] = useState(false);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    if (open) {
      setText("");
      setIsPrivate(false);
      setTimeout(() => textareaRef.current?.focus(), 50);
    }
  }, [open]);

  if (!open) return null;

  const handleSubmit = () => {
    if (!text.trim()) return;
    onCreate(text.trim(), isPrivate);
    onClose();
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div
        className="modal-content annotation-dialog"
        onClick={(e) => e.stopPropagation()}
        style={{ maxWidth: 440 }}
      >
        <div className="link-creator-header">
          <h3>Annotate chars {charStart}{"\u2013"}{charEnd}</h3>
          <button type="button" className="link-creator-close" onClick={onClose}>
            {"\u00d7"}
          </button>
        </div>
        <div className="annotation-dialog-body">
          <textarea
            ref={textareaRef}
            className="annotation-textarea"
            placeholder="Write your annotation..."
            value={text}
            onChange={(e) => setText(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter" && (e.metaKey || e.ctrlKey)) {
                e.preventDefault();
                handleSubmit();
              }
              if (e.key === "Escape") {
                e.preventDefault();
                onClose();
              }
            }}
            rows={4}
          />
          <label className="annotation-private-label">
            <input
              type="checkbox"
              checked={isPrivate}
              onChange={(e) => setIsPrivate(e.target.checked)}
            />
            <span>Private {"\u2014"} only visible to you</span>
          </label>
          <div className="annotation-dialog-actions">
            <span className="annotation-shortcut-hint">
              {"\u2318"}+Enter to create {"\u00b7"} Esc to cancel
            </span>
            <button
              type="button"
              className="annotation-create-btn"
              disabled={!text.trim()}
              onClick={handleSubmit}
            >
              Annotate
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
