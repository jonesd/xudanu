import { useEffect, useRef } from "react";
import EasyMDE from "easymde";
import "easymde/dist/easymde.min.css";

interface EasyMDEEditorProps {
  text: string;
  onTextChange?: (text: string) => void;
  editable: boolean;
}

export function EasyMDEEditor({ text, onTextChange, editable }: EasyMDEEditorProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mdeRef = useRef<EasyMDE | null>(null);
  const lastTextRef = useRef(text);
  const isSettingText = useRef(false);

  useEffect(() => {
    if (!containerRef.current) return;

    const mde = new EasyMDE({
      element: containerRef.current,
      initialValue: text,
      spellChecker: false,
      autofocus: false,
      status: false,
      toolbar: editable ? [
        "bold", "italic", "heading", "|",
        "unordered-list", "ordered-list", "blockquote", "code", "|",
        "link", "|",
        "preview", "side-by-side", "fullscreen", "|",
        "guide",
      ] : false,
      renderingConfig: {
        codeSyntaxHighlighting: false,
      },
    });
    mdeRef.current = mde;
    lastTextRef.current = text;

    mde.codemirror.on("change", () => {
      if (isSettingText.current) return;
      const newText = mde.value();
      if (newText !== lastTextRef.current) {
        lastTextRef.current = newText;
        onTextChange?.(newText);
      }
    });

    return () => {
      mde.toTextArea();
      mdeRef.current = null;
    };
  }, []);

  // Sync text from CRDT to editor (remote changes)
  useEffect(() => {
    if (!mdeRef.current) return;
    if (text === lastTextRef.current) return;
    lastTextRef.current = text;
    isSettingText.current = true;
    const cursor = mdeRef.current.codemirror.getCursor();
    mdeRef.current.value(text);
    mdeRef.current.codemirror.setCursor(cursor);
    isSettingText.current = false;
  }, [text]);

  // Toggle editability
  useEffect(() => {
    if (!mdeRef.current) return;
    mdeRef.current.codemirror.setOption("readOnly", !editable);
  }, [editable]);

  return (
    <div className="easymde-wrap">
      <textarea ref={containerRef} />
    </div>
  );
}
