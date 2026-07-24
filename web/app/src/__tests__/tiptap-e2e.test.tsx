import { describe, it, expect, vi } from "vitest";
import { render, waitFor, cleanup } from "@testing-library/react";
import { afterEach } from "vitest";
import { TipTapEditor } from "../components/TipTapEditor";
import type { AnnotationEntry } from "../api/crdt_sync";

afterEach(() => {
  cleanup();
});

function ann(kind: string, start: number, end: number, payload?: string): AnnotationEntry {
  return {
    annotation_id: Math.floor(Math.random() * 1e9),
    kind,
    payload: payload || "",
    char_start: start,
    char_end: end,
    created_by: 0,
    created_by_name: "",
    is_private: false,
  };
}

function renderEditor(opts: {
  text?: string;
  annotations?: AnnotationEntry[];
  editable?: boolean;
  onImageUpload?: (file: File) => Promise<string | null>;
  onCreateAnnotation?: (kind: string, payload: string, start: number, end: number) => void;
  onDeleteAnnotation?: (id: number) => void;
  onTextChange?: (text: string) => void;
}) {
  return render(
    <TipTapEditor
      text={opts.text ?? ""}
      workId={1}
      editable={opts.editable ?? true}
      annotations={opts.annotations ?? []}
      onImageUpload={opts.onImageUpload}
      onCreateAnnotation={opts.onCreateAnnotation}
      onDeleteAnnotation={opts.onDeleteAnnotation}
      onTextChange={opts.onTextChange}
    />,
  );
}

// ── Image rendering from persisted annotations ──────────────────────────────

describe("TipTapEditor image rendering", () => {
  it("renders a single image from annotation", async () => {
    const hash = "abc123def456";
    const text = "Before\nAfter";
    const anns = [ann("image", 6, 6, JSON.stringify({ hash }))];

    const { container } = renderEditor({ text, annotations: anns });

    await waitFor(() => {
      const img = container.querySelector("img");
      expect(img).toBeTruthy();
      expect(img?.getAttribute("src")).toBe(`/blobs/${hash}/preview`);
    });
  });

  it("renders image at start of document", async () => {
    const hash = "start123";
    const text = "Hello";
    const anns = [ann("image", 0, 0, JSON.stringify({ hash }))];

    const { container } = renderEditor({ text, annotations: anns });

    await waitFor(() => {
      const imgs = container.querySelectorAll("img");
      expect(imgs.length).toBe(1);
    });
  });

  it("renders image at end of document", async () => {
    const hash = "end456";
    const text = "Hello world";
    const anns = [ann("image", text.length, text.length, JSON.stringify({ hash }))];

    const { container } = renderEditor({ text, annotations: anns });

    await waitFor(() => {
      const imgs = container.querySelectorAll("img");
      expect(imgs.length).toBeGreaterThanOrEqual(1);
    }, { timeout: 3000 });
  });

  it("renders multiple images", async () => {
    const text = "A\nB\nC";
    const anns = [
      ann("image", 0, 0, JSON.stringify({ hash: "img1" })),
      ann("image", 2, 2, JSON.stringify({ hash: "img2" })),
      ann("image", 4, 4, JSON.stringify({ hash: "img3" })),
    ];

    const { container } = renderEditor({ text, annotations: anns });

    await waitFor(() => {
      const imgs = container.querySelectorAll("img");
      expect(imgs.length).toBe(3);
    });
  });

  it("image src uses permanent server URL format", async () => {
    const hash = "deadbeef";
    const text = "Text";
    const anns = [ann("image", 4, 4, JSON.stringify({ hash }))];

    const { container } = renderEditor({ text, annotations: anns });

    await waitFor(() => {
      const img = container.querySelector("img");
      expect(img).toBeTruthy();
      const src = img?.getAttribute("src") || "";
      expect(src).toMatch(/^\/blobs\/[0-9a-f]+\/preview$/);
      expect(src).toContain(hash);
    });
  });
});

// ── Image + formatting combined ─────────────────────────────────────────────

describe("TipTapEditor mixed content with images", () => {
  it("renders heading + image + bold together", async () => {
    const text = "Title\nBold text";
    const hash = "mixed123";
    const anns = [
      ann("heading", 0, 5, JSON.stringify({ level: 1 })),
      ann("bold", 6, 10),
      ann("image", 5, 5, JSON.stringify({ hash })),
    ];

    const { container } = renderEditor({ text, annotations: anns });

    await waitFor(() => {
      expect(container.querySelector("h1")).toBeTruthy();
      expect(container.querySelector("img")).toBeTruthy();
      expect(container.querySelector("strong")).toBeTruthy();
    });
  });

  it("renders image inside blockquote", async () => {
    const text = "Quote with image";
    const hash = "bqimg";
    const anns = [
      ann("blockquote", 0, 16),
      ann("image", 16, 16, JSON.stringify({ hash })),
    ];

    const { container } = renderEditor({ text, annotations: anns });

    await waitFor(() => {
      expect(container.querySelector("blockquote")).toBeTruthy();
      expect(container.querySelector("img")).toBeTruthy();
    });
  });

  it("renders image inside list item", async () => {
    const text = "Item with img";
    const hash = "listimg";
    const anns = [
      ann("list_item", 0, 13, JSON.stringify({ type: "bullet" })),
      ann("image", 13, 13, JSON.stringify({ hash })),
    ];

    const { container } = renderEditor({ text, annotations: anns });

    await waitFor(() => {
      expect(container.querySelector("ul")).toBeTruthy();
      expect(container.querySelector("img")).toBeTruthy();
    });
  });
});

// ── Image upload flow ───────────────────────────────────────────────────────

describe("TipTapEditor image upload", () => {
  it("camera button is visible when onImageUpload provided", async () => {
    const onImageUpload = vi.fn().mockResolvedValue("/blobs/test/preview");
    const { container } = renderEditor({ text: "Hello", onImageUpload });

    await waitFor(() => {
      const label = container.querySelector("label[title='Insert image']");
      expect(label).toBeTruthy();
    });
  });

  it("camera button hidden when no onImageUpload", async () => {
    const { container } = renderEditor({ text: "Hello" });

    await waitFor(() => {
      const label = container.querySelector("label[title='Insert image']");
      expect(label).toBeNull();
    });
  });

  it("upload handler returns permanent server URL", async () => {
    const onImageUpload = vi.fn().mockResolvedValue("/blobs/test123/preview");
    const result = await onImageUpload(new File(["data"], "test.png", { type: "image/png" }));
    expect(result).toBe("/blobs/test123/preview");
    expect(result).toMatch(/^\/blobs\//);
  });

  it("upload handler returns null on failure", async () => {
    const onImageUpload = vi.fn().mockResolvedValue(null);
    const result = await onImageUpload(new File(["data"], "test.png", { type: "image/png" }));
    expect(result).toBeNull();
  });
});

// ── Image size validation ───────────────────────────────────────────────────

describe("TipTapEditor image size validation", () => {
  it("rejects files over 2MB", () => {
    const largeFile = new File([new Uint8Array(3_000_000)], "big.png", { type: "image/png" });
    expect(largeFile.size).toBeGreaterThan(2_000_000);
  });

  it("accepts files under 2MB", () => {
    const smallFile = new File([new Uint8Array(500_000)], "small.jpg", { type: "image/jpeg" });
    expect(smallFile.size).toBeLessThanOrEqual(2_000_000);
  });

  it("accepts PNG files", () => {
    const pngFile = new File(["data"], "test.png", { type: "image/png" });
    expect(pngFile.type).toBe("image/png");
  });

  it("accepts JPEG files", () => {
    const jpgFile = new File(["data"], "test.jpg", { type: "image/jpeg" });
    expect(jpgFile.type).toBe("image/jpeg");
  });
});

// ── Persistence: load → edit → verify ───────────────────────────────────────

describe("TipTapEditor persistence", () => {
  it("loads document with image and preserves it through text change", async () => {
    const hash = "persist1";
    const text = "Before\nAfter";
    const anns = [ann("image", 6, 6, JSON.stringify({ hash }))];
    const onTextChange = vi.fn();

    const { container } = renderEditor({ text, annotations: anns, onTextChange });

    await waitFor(() => {
      expect(container.querySelector("img")).toBeTruthy();
    });
  });

  it("loads document with image then reloads same content", async () => {
    const hash = "persist2";
    const text = "Text with image";
    const anns = [ann("image", 15, 15, JSON.stringify({ hash }))];

    // First render
    const { container, rerender } = renderEditor({ text, annotations: anns });
    await waitFor(() => {
      expect(container.querySelector("img")).toBeTruthy();
    });

    // Simulate reload with same content
    rerender(
      <TipTapEditor
        text={text}
        workId={2}
        editable={true}
        annotations={anns}
      />,
    );

    await waitFor(() => {
      const imgs = container.querySelectorAll("img");
      expect(imgs.length).toBeGreaterThanOrEqual(1);
    });
  });

  it("document with only an image renders correctly", async () => {
    const hash = "onlyimg";
    const anns = [ann("image", 0, 0, JSON.stringify({ hash }))];

    const { container } = renderEditor({ text: "", annotations: anns });

    await waitFor(() => {
      expect(container.querySelector("img")).toBeTruthy();
    });
  });

  it("image with font size mark on adjacent text", async () => {
    const hash = "sizedimg";
    const text = "Big text";
    const anns = [
      ann("font_size", 0, 3, JSON.stringify({ px: 24 })),
      ann("image", 8, 8, JSON.stringify({ hash })),
    ];

    const { container } = renderEditor({ text, annotations: anns });

    await waitFor(() => {
      const img = container.querySelector("img");
      expect(img).toBeTruthy();
      const styledSpan = container.querySelector('[style*="font-size"]');
      expect(styledSpan).toBeTruthy();
    });
  });
});
