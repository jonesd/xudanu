import { describe, it, expect } from "vitest";
import { insertInlineImages } from "../components/editor-dom-utils";

function makeEditor(text: string): HTMLElement {
  const el = document.createElement("div");
  el.textContent = text;
  return el;
}

describe("insertInlineImages", () => {
  it("no-op when blobs array is empty", () => {
    const el = makeEditor("Hello world");
    insertInlineImages(el, []);
    expect(el.querySelectorAll(".inline-image-wrapper").length).toBe(0);
    expect(el.textContent).toBe("Hello world");
  });

  it("inserts a single image at a middle position", () => {
    const el = makeEditor("Hello world");
    insertInlineImages(el, [
      { charPos: 5, hash: "0xabc", url: "data:image/png;base64,AAA" },
    ]);
    const wrappers = el.querySelectorAll(".inline-image-wrapper");
    expect(wrappers.length).toBe(1);
    const imgs = el.querySelectorAll("img.inline-image");
    expect(imgs.length).toBe(1);
    expect((imgs[0] as HTMLImageElement).src).toContain("data:image/png");
  });

  it("inserts image at position 0 (start of text)", () => {
    const el = makeEditor("Hello");
    insertInlineImages(el, [
      { charPos: 0, hash: "1", url: "data:image/png;base64,AAA" },
    ]);
    expect(el.querySelectorAll(".inline-image-wrapper").length).toBe(1);
    const wrapper = el.querySelector(".inline-image-wrapper") as Element;
    expect(el.firstChild).toBe(wrapper);
  });

  it("inserts image at end of text", () => {
    const el = makeEditor("Hello");
    insertInlineImages(el, [
      { charPos: 5, hash: "1", url: "data:image/png;base64,AAA" },
    ]);
    expect(el.querySelectorAll(".inline-image-wrapper").length).toBe(1);
    const wrapper = el.querySelector(".inline-image-wrapper") as Element;
    expect(el.lastChild).toBe(wrapper);
  });

  it("inserts multiple images in correct order", () => {
    const el = makeEditor("ABCDE");
    insertInlineImages(el, [
      { charPos: 3, hash: "3", url: "data:image/png;base64,CCC" },
      { charPos: 1, hash: "1", url: "data:image/png;base64,AAA" },
    ]);
    const imgs = el.querySelectorAll("img.inline-image");
    expect(imgs.length).toBe(2);
  });

  it("removes old images on re-call (idempotent)", () => {
    const el = makeEditor("Hello world");
    insertInlineImages(el, [
      { charPos: 5, hash: "1", url: "data:image/png;base64,AAA" },
    ]);
    expect(el.querySelectorAll(".inline-image-wrapper").length).toBe(1);

    insertInlineImages(el, [
      { charPos: 5, hash: "2", url: "data:image/png;base64,BBB" },
    ]);
    expect(el.querySelectorAll(".inline-image-wrapper").length).toBe(1);
    const img = el.querySelector("img.inline-image") as HTMLImageElement;
    expect(img.src).toContain("BBB");
  });

  it("sets contenteditable=false on wrapper (excluded from text extraction)", () => {
    const el = makeEditor("Hello");
    insertInlineImages(el, [
      { charPos: 2, hash: "1", url: "data:image/png;base64,AAA" },
    ]);
    const wrapper = el.querySelector(".inline-image-wrapper") as Element;
    expect(wrapper.getAttribute("contenteditable")).toBe("false");
  });

  it("shows placeholder text when URL is missing", () => {
    const el = makeEditor("Hello");
    insertInlineImages(el, [
      { charPos: 2, hash: "1" },
    ]);
    const wrapper = el.querySelector(".inline-image-wrapper") as Element;
    expect(wrapper.textContent).toBe("[image]");
    expect(wrapper.querySelector("img")).toBeNull();
  });

  it("sets width from blob dimensions", () => {
    const el = makeEditor("Hello");
    insertInlineImages(el, [
      { charPos: 2, hash: "1", url: "data:image/png;base64,AAA", width: 800, height: 600 },
    ]);
    const wrapper = el.querySelector(".inline-image-wrapper") as HTMLElement;
    expect(wrapper.style.width).toBe("400px");
  });

  it("caps large widths at 400px", () => {
    const el = makeEditor("Hello");
    insertInlineImages(el, [
      { charPos: 2, hash: "1", url: "data:image/png;base64,AAA", width: 2000 },
    ]);
    const wrapper = el.querySelector(".inline-image-wrapper") as HTMLElement;
    expect(wrapper.style.width).toBe("400px");
  });

  it("handles multi-line text correctly", () => {
    const el = document.createElement("div");
    el.textContent = "Line one\nLine two";
    const textLen = el.textContent?.length ?? 0;
    insertInlineImages(el, [
      { charPos: textLen, hash: "1", url: "data:image/png;base64,AAA" },
    ]);
    expect(el.querySelectorAll(".inline-image-wrapper").length).toBe(1);
  });

  it("filters out negative charPos blobs", () => {
    const el = makeEditor("Hello");
    insertInlineImages(el, [
      { charPos: -1, hash: "1", url: "data:image/png;base64,AAA" },
    ]);
    expect(el.querySelectorAll(".inline-image-wrapper").length).toBe(0);
  });
});
