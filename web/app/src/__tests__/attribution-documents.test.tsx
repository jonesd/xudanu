import { describe, it, expect, vi } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import { AttributionSection } from "../components/panels/AttributionSection";
import type { AttributionSpan } from "../api/crdt_sync";

function mkSpan(overrides: Partial<AttributionSpan> = {}): AttributionSpan {
  return {
    start: 0,
    end: 5,
    author_public_key: [1, 2, 3],
    author_display_name: "Alice",
    author_club_id: null,
    signature_valid: true,
    verification_state: "verified",
    timestamp: 1700000000,
    server_id: [],
    author_type: null,
    llm_model: null,
    historical_author_id: null,
    source_work_id: null,
    source_work_title: null,
    transcluded_by_name: null,
    transcluded_by_club_id: null,
    provenance_chain: null,
    ...overrides,
  };
}

describe("AttributionSection — contributing documents (FR-72)", () => {
  it("renders the ordered author → document list for transcluded spans", () => {
    const spans = [
      mkSpan({ start: 0, end: 6 }),
      mkSpan({
        start: 6,
        end: 16,
        author_display_name: "Bob",
        source_work_id: 42,
        source_work_title: "Garden Notes",
      }),
      mkSpan({
        start: 16,
        end: 30,
        author_display_name: "Carol",
        source_work_id: 7,
        source_work_title: "Ferry Schedules",
      }),
    ];
    render(
      <AttributionSection
        attributionSpans={spans}
        attributionLogStatus={null}
        documentLength={30}
      />,
    );
    fireEvent.click(screen.getByText("Attribution"));

    expect(screen.getByText(/CONTRIBUTING DOCUMENTS/)).toBeTruthy();
    const garden = screen.getByText("Garden Notes");
    const ferry = screen.getByText("Ferry Schedules");
    expect(garden).toBeTruthy();
    expect(ferry).toBeTruthy();
    expect(screen.getByText("This document")).toBeTruthy();
    expect(screen.getByText(/10 chars/)).toBeTruthy();
    expect(screen.getByText(/14 chars/)).toBeTruthy();
  });

  it("span rows name the source document instead of a dead 'via work' label", () => {
    const spans = [
      mkSpan({ source_work_id: 99, source_work_title: "Quoted Source" }),
    ];
    render(
      <AttributionSection
        attributionSpans={spans}
        attributionLogStatus={null}
        documentLength={5}
      />,
    );
    fireEvent.click(screen.getByText("Attribution"));
    expect(screen.getByText(/via “Quoted Source”/)).toBeTruthy();
    expect(screen.queryByText("via work")).toBeNull();
  });

  it("clicking a document row or via-chip opens the work", () => {
    const onOpenWork = vi.fn();
    const spans = [
      mkSpan({ source_work_id: 42, source_work_title: "Garden Notes" }),
    ];
    render(
      <AttributionSection
        attributionSpans={spans}
        attributionLogStatus={null}
        onOpenWork={onOpenWork}
        documentLength={5}
      />,
    );
    fireEvent.click(screen.getByText("Attribution"));
    fireEvent.click(screen.getByText("Garden Notes"));
    expect(onOpenWork).toHaveBeenCalledWith(42);
  });
});
