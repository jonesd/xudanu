import { describe, it, expect, vi } from "vitest";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { createElement } from "react";
import { ArgumentMap } from "../components/ArgumentMap";
import type { LinkEntry } from "../api/crdt_sync";

function mkLink(over: Partial<LinkEntry> = {}): LinkEntry {
  return {
    link_id: 1,
    origin: 100,
    destination: 200,
    origin_ref: null,
    destination_ref: null,
    link_types: [],
    ...over,
  };
}

const LINKS: LinkEntry[] = [
  mkLink({
    link_id: 10,
    origin: 100,
    destination: 200,
    link_types: [3],
    origin_title: "Dan's Requirement",
    endorsement_count: 2,
  }),
  mkLink({
    link_id: 11,
    origin: 300,
    destination: 100,
    link_types: [2],
    origin_title: "Ruth's Rebuttal",
    responds_to: 10,
  }),
  mkLink({
    link_id: 12,
    origin: 400,
    destination: 200,
    link_types: [2],
    origin_title: "John's Budget",
  }),
];

function renderMap(over: Partial<Parameters<typeof ArgumentMap>[0]> = {}) {
  const onSelect = over.onSelect ?? vi.fn();
  const onAddChild = over.onAddChild ?? vi.fn();
  const props = {
    rootWorkId: 200,
    links: LINKS,
    rootLabel: "Titanium Plan",
    selectedId: null,
    onSelect,
    onAddChild,
    ...over,
  };
  const utils = render(createElement(ArgumentMap, props));
  return { ...utils, onSelect, onAddChild, props };
}

describe("ArgumentMap", () => {
  it("renders the contention, objections, responses, and others with numbers", async () => {
    renderMap();
    await waitFor(() => expect(screen.getByText(/Titanium Plan/)).toBeTruthy());
    expect(screen.getByText(/Dan's Requirement/)).toBeTruthy();
    expect(screen.getByText(/Ruth's Rebuttal/)).toBeTruthy();
    expect(screen.getByText(/John's Budget/)).toBeTruthy();
    expect(screen.getByText(/^1$/)).toBeTruthy();
    expect(screen.getByText(/^1\.1 ⚑/)).toBeTruthy();
    expect(screen.getByText(/^1\.1\.1$/)).toBeTruthy();
  });

  it("shows endorsement weight on nodes", async () => {
    renderMap();
    await waitFor(() => expect(screen.getByText(/2 endorses/)).toBeTruthy());
  });

  it("selects a node on click", async () => {
    const { onSelect } = renderMap();
    await waitFor(() => expect(screen.getByText(/Dan's Requirement/)).toBeTruthy());
    fireEvent.click(screen.getByText(/Dan's Requirement/));
    expect(onSelect).toHaveBeenCalledWith("L10");
  });

  it("offers the authoring bar for the selected contention and creates objections", async () => {
    const onAddChild = vi.fn();
    const { rerender } = render(createElement(ArgumentMap, {
      rootWorkId: 200,
      links: LINKS,
      rootLabel: "Titanium Plan",
      selectedId: "root",
      onSelect: vi.fn(),
      onAddChild,
    }));
    const input = await screen.findByPlaceholderText(/state the objection/i);
    fireEvent.change(input, { target: { value: "Consumer price panels disagree" } });
    fireEvent.click(screen.getByText("+ objection"));
    expect(onAddChild).toHaveBeenCalledTimes(1);
    const [parent, kind, text] = onAddChild.mock.calls[0];
    expect(parent.id).toBe("root");
    expect(kind).toBe("objection");
    expect(text).toBe("Consumer price panels disagree");
    expect(rerender).toBeTruthy();
  });

  it("selected non-root nodes offer + response", async () => {
    render(createElement(ArgumentMap, {
      rootWorkId: 200,
      links: LINKS,
      rootLabel: "Titanium Plan",
      selectedId: "L10",
      onSelect: vi.fn(),
      onAddChild: vi.fn(),
    }));
    const input = await screen.findByPlaceholderText(/state the response/i);
    expect(input).toBeTruthy();
    expect(screen.getByText("+ response")).toBeTruthy();
  });

  it("hides the authoring bar when onAddChild is absent (read-only)", async () => {
    render(createElement(ArgumentMap, {
      rootWorkId: 200,
      links: LINKS,
      rootLabel: "Titanium Plan",
      selectedId: "root",
      onSelect: vi.fn(),
    }));
    await waitFor(() => expect(screen.getByText(/Titanium Plan/)).toBeTruthy());
    expect(screen.queryByPlaceholderText(/state the/i)).toBeNull();
  });

  it("renders empty state for a link-less work without crashing", async () => {
    render(createElement(ArgumentMap, {
      rootWorkId: 999,
      links: [],
      rootLabel: "Solo",
      selectedId: null,
      onSelect: vi.fn(),
    }));
    await waitFor(() => expect(screen.getByText(/Solo/)).toBeTruthy());
    expect(screen.queryByText("1.1")).toBeNull();
  });
});
