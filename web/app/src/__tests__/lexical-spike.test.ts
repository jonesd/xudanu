import { describe, it, expect } from "vitest";
import { createEditor, $getRoot, $isTextNode, type ElementNode } from "lexical";
import { buildContent, selectionOffsets, serializeRoot } from "../components/LexicalSpikeEditor";
import type { AttributionSpan } from "../api/crdt_sync";

function span(start: number, end: number, author: number): AttributionSpan {
  return {
    start,
    end,
    author_public_key: [],
    author_display_name: null,
    author_club_id: author,
    signature_valid: true,
    verification_state: null,
    timestamp: 0,
    server_id: [],
    author_type: null,
    llm_model: null,
    historical_author_id: null,
  };
}

describe("FR-150 lexical spike — model-offset arithmetic", () => {
  it("round-trips text through buildContent", () => {
    const editor = createEditor({ namespace: "t" });
    editor.update(
      () => {
        buildContent("hello\nworld\nagain", []);
      },
      { discrete: true },
    );
    expect(editor.getEditorState().read(() => serializeRoot())).toBe(
      "hello\nworld\nagain",
    );
  });

  it("maps selection points to plain-text offsets across paragraphs", () => {
    const editor = createEditor({ namespace: "t" });
    editor.update(
      () => {
        buildContent("hello\nworld", []);
        const paras = $getRoot().getChildren() as ElementNode[];
        const world = paras[1].getChildren()[0];
        if ($isTextNode(world)) world.select(1, 3); // "orl" → model 7..9
      },
      { discrete: true },
    );
    const sel = editor.getEditorState().read(() => selectionOffsets());
    expect(sel).toEqual([7, 9]);
  });

  it("maps a caret in the first paragraph to offset 0..5", () => {
    const editor = createEditor({ namespace: "t" });
    editor.update(
      () => {
        buildContent("hello\nworld", []);
        const hello = ($getRoot().getChildren() as ElementNode[])[0].getChildren()[0];
        if ($isTextNode(hello)) hello.select(2, 2);
      },
      { discrete: true },
    );
    const sel = editor.getEditorState().read(() => selectionOffsets());
    expect(sel).toEqual([2, 2]);
  });

  it("styles attribution spans and preserves text", () => {
    const editor = createEditor({ namespace: "t" });
    editor.update(
      () => {
        buildContent("abcdef", [span(1, 4, 77)]);
      },
      { discrete: true },
    );
    const styled = editor.getEditorState().read(() => {
      const nodes: string[] = [];
      for (const para of $getRoot().getChildren() as ElementNode[]) {
        for (const child of para.getChildren()) {
          if ($isTextNode(child)) nodes.push(child.getTextContent());
        }
      }
      return nodes;
    });
    expect(styled.join("")).toBe("abcdef");
    expect(styled).toEqual(["a", "bcd", "ef"]); // split at span boundaries
  });

  it("clamps spans beyond text bounds without losing content", () => {
    const editor = createEditor({ namespace: "t" });
    editor.update(
      () => {
        buildContent("abc", [span(2, 99, 5), span(-5, 1, 6)]);
      },
      { discrete: true },
    );
    expect(editor.getEditorState().read(() => serializeRoot())).toBe("abc");
  });
});
