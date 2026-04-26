import { render, screen } from "@testing-library/react";
import { describe, it, expect } from "vitest";
import { DocumentRenderer } from "../components/DocumentRenderer";
import type { DocumentResponse } from "../types/api";

describe("DocumentRenderer", () => {
  it("shows empty state when document is null", () => {
    const response: DocumentResponse = {
      workspaceId: "ws-1",
      traceId: "t-1-1",
      document: null,
    };
    render(<DocumentRenderer response={response} />);
    expect(screen.getByText("No document content")).toBeInTheDocument();
  });

  it("renders a document with nested nodes", () => {
    const response: DocumentResponse = {
      workspaceId: "ws-1",
      traceId: "t-1-1",
      document: {
        nodeId: "node-1",
        kind: "document",
        children: [
          {
            nodeId: "node-2",
            kind: "paragraph",
            spans: [
              {
                spanId: "span-1",
                text: { type: "single", value: "Hello world" },
              },
            ],
          },
        ],
      },
    };
    render(<DocumentRenderer response={response} />);
    expect(screen.getByText("Hello world")).toBeInTheDocument();
  });
});
