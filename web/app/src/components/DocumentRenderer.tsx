import type { DocumentResponse } from "../types/api";
import { NodeView } from "./NodeView";

interface DocumentRendererProps {
  response: DocumentResponse;
  onContentChanged?: () => void;
}

export function DocumentRenderer({ response, onContentChanged }: DocumentRendererProps) {
  if (!response.document) {
    return <div className="document-empty">No document content</div>;
  }

  return (
    <div className="document">
      <NodeView
        node={response.document}
        workspaceId={response.workspaceId}
        onContentChanged={onContentChanged}
      />
    </div>
  );
}
