import { render, screen } from "@testing-library/react";
import { describe, it, expect } from "vitest";
import { SpanView } from "../components/SpanView";

describe("SpanView", () => {
  it("renders single text", () => {
    render(<SpanView text={{ type: "single", value: "Hello world" }} />);
    expect(screen.getByText("Hello world")).toBeInTheDocument();
  });

  it("renders alternatives with divider", () => {
    const { container } = render(
      <SpanView
        text={{ type: "alternatives", values: ["alpha", "beta"] }}
      />,
    );
    expect(screen.getByText("alpha")).toBeInTheDocument();
    expect(screen.getByText("beta")).toBeInTheDocument();
    expect(container.querySelector(".alternative-divider")).toBeTruthy();
  });

  it("renders three alternatives", () => {
    render(
      <SpanView
        text={{ type: "alternatives", values: ["a", "b", "c"] }}
      />,
    );
    expect(screen.getByText("a")).toBeInTheDocument();
    expect(screen.getByText("b")).toBeInTheDocument();
    expect(screen.getByText("c")).toBeInTheDocument();
  });
});
