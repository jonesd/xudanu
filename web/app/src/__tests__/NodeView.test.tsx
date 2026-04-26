import { render, screen } from "@testing-library/react";
import { describe, it, expect } from "vitest";
import { NodeView } from "../components/NodeView";
import type { ApiNode } from "../types/api";

describe("NodeView", () => {
  it("renders a leaf node with span text", () => {
    const node: ApiNode = {
      nodeId: "node-1",
      kind: "paragraph",
      spans: [
        {
          spanId: "span-1",
          text: { type: "single", value: "Hello" },
        },
      ],
    };
    render(<NodeView node={node} />);
    expect(screen.getByText("Hello")).toBeInTheDocument();
  });

  it("renders nested children", () => {
    const node: ApiNode = {
      nodeId: "node-1",
      kind: "document",
      children: [
        {
          nodeId: "node-2",
          kind: "paragraph",
          spans: [
            { spanId: "span-1", text: { type: "single", value: "child text" } },
          ],
        },
      ],
    };
    render(<NodeView node={node} />);
    expect(screen.getByText("child text")).toBeInTheDocument();
    expect(screen.getByText("child text").closest(".node-paragraph")).toBeTruthy();
  });

  it("renders alternatives in spans", () => {
    const node: ApiNode = {
      nodeId: "node-1",
      kind: "paragraph",
      spans: [
        {
          spanId: "span-1",
          text: { type: "alternatives", values: ["v1", "v2"] },
        },
      ],
    };
    const { container } = render(<NodeView node={node} />);
    expect(screen.getByText("v1")).toBeInTheDocument();
    expect(screen.getByText("v2")).toBeInTheDocument();
    expect(container.querySelector(".alternative-divider")).toBeTruthy();
  });
});
