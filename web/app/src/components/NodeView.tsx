import type { ApiNode, ApiText } from "../types/api";
import { SpanView } from "./SpanView";
import { EditableSpan } from "./EditableSpan";

interface NodeViewProps {
  node: ApiNode;
  workspaceId?: string;
  onContentChanged?: () => void;
}

export function NodeView({ node, workspaceId, onContentChanged }: NodeViewProps) {
  const editable = workspaceId && onContentChanged;

  return (
    <div className={`node node-${node.kind}`} data-node-id={node.nodeId}>
      {node.spans && node.spans.length > 0 && (
        <div className="node-spans">
          {node.spans.map((span) =>
            editable ? (
              <EditableSpan
                key={span.spanId}
                text={span.text}
                spanId={span.spanId}
                workspaceId={workspaceId}
                onUpdated={onContentChanged!}
              />
            ) : (
              <SpanView key={span.spanId} text={span.text} />
            ),
          )}
        </div>
      )}
      {node.children && node.children.length > 0 && (
        <div className="node-children">
          {node.children.map((child) => (
            <NodeView
              key={child.nodeId}
              node={child}
              workspaceId={workspaceId}
              onContentChanged={onContentChanged}
            />
          ))}
        </div>
      )}
    </div>
  );
}
