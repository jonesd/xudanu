import { useEffect, useRef } from "react";
import MDEditor from "@uiw/react-md-editor";

interface MDEditorProps {
  text: string;
  onTextChange?: (text: string) => void;
  editable: boolean;
}

export function EasyMDEEditor({ text, onTextChange, editable }: MDEditorProps) {
  const lastTextRef = useRef(text);
  const isSettingText = useRef(false);

  useEffect(() => {
    lastTextRef.current = text;
  }, [text]);

  return (
    <div data-color-mode="dark">
      <MDEditor
        value={text}
        onChange={(newText) => {
          const v = newText ?? "";
          if (isSettingText.current) return;
          if (v !== lastTextRef.current) {
            lastTextRef.current = v;
            onTextChange?.(v);
          }
        }}
        preview={editable ? "live" : "preview"}
        hideToolbar={!editable}
        readOnly={!editable}
        height={500}
      />
    </div>
  );
}
