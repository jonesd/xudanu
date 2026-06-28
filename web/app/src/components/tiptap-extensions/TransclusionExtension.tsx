import { Node, mergeAttributes } from "@tiptap/core";
import {
  ReactNodeViewRenderer,
  NodeViewWrapper,
  type NodeViewProps,
} from "@tiptap/react";

interface TransclusionAttrs {
  sourceWorkId: number;
  charStart: number;
  charEnd: number;
  resolvedContent: string;
  sourceTitle: string;
}

function TransclusionView({ node }: NodeViewProps) {
  const attrs = node.attrs as TransclusionAttrs;

  return (
    <NodeViewWrapper
      as="span"
      className="inline-transclusion"
      contentEditable={false}
      style={{
        background: "rgba(245, 158, 11, 0.12)",
        borderBottom: "1px dashed rgba(245, 158, 11, 0.5)",
        borderRadius: "2px",
        padding: "1px 0",
        cursor: "pointer",
        userSelect: "text",
      }}
      title={`Transclusion from: ${attrs.sourceTitle || `work-${attrs.sourceWorkId.toString(16)}`} (click to navigate)`}
      onClick={(e: React.MouseEvent) => {
        e.stopPropagation();
        console.log("[transclusion-click] source:", attrs.sourceWorkId);
      }}
    >
      <span style={{ fontSize: "9px", color: "#b45309", marginRight: "2px", fontWeight: 700, opacity: 0.6 }}>
        {"\u2192"}
      </span>
      {attrs.resolvedContent || "..."}
    </NodeViewWrapper>
  );
}

export const TransclusionExtension = Node.create({
  name: "transclusion",
  group: "inline",
  inline: true,
  atom: true,
  selectable: true,
  draggable: false,

  addAttributes() {
    return {
      sourceWorkId: {
        default: 0,
        parseHTML: (el) => Number(el.getAttribute("data-source-work-id") || 0),
        renderHTML: (attrs) => ({
          "data-source-work-id": attrs.sourceWorkId,
        }),
      },
      charStart: {
        default: 0,
        parseHTML: (el) => Number(el.getAttribute("data-char-start") || 0),
        renderHTML: (attrs) => ({
          "data-char-start": attrs.charStart,
        }),
      },
      charEnd: {
        default: 0,
        parseHTML: (el) => Number(el.getAttribute("data-char-end") || 0),
        renderHTML: (attrs) => ({
          "data-char-end": attrs.charEnd,
        }),
      },
      resolvedContent: {
        default: "",
        parseHTML: (el) => el.textContent || "",
      },
      sourceTitle: {
        default: "",
        parseHTML: (el) => el.getAttribute("data-source-title") || "",
        renderHTML: (attrs) => ({
          "data-source-title": attrs.sourceTitle,
        }),
      },
    };
  },

  parseHTML() {
    return [{ tag: "span[data-transclusion]" }];
  },

  renderHTML({ HTMLAttributes }) {
    return [
      "span",
      mergeAttributes(HTMLAttributes, {
        "data-transclusion": "",
        contenteditable: "false",
      }),
    ];
  },

  addNodeView() {
    return ReactNodeViewRenderer(TransclusionView);
  },

  addCommands() {
    return {
      insertTransclusion:
        (attrs: TransclusionAttrs) =>
        ({ commands }: { commands: { insertContent: (content: object) => boolean } }) => {
          return commands.insertContent({
            type: "transclusion",
            attrs,
          });
        },
    } as any;
  },
});
