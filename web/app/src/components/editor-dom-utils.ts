import type { SpanRangePayload } from "../api/crdt_sync";
import { getCursorOffset, setCursorOffset } from "../styled-text";

function isHiddenMarker(node: Node | null): boolean {
  let n = node;
  while (n && n.nodeType !== Node.DOCUMENT_NODE) {
    if (n.nodeType === Node.ELEMENT_NODE) {
      const el = n as Element;
      const style = el.getAttribute && el.getAttribute("style");
      if (style && style.includes("display:none")) return true;
    }
    n = n.parentNode;
  }
  return false;
}

export function isDecorativeNode(node: Node | null): boolean {
  let n = node;
  while (n && n.nodeType !== Node.DOCUMENT_NODE) {
    if (n.nodeType === Node.ELEMENT_NODE) {
      const el = n as Element;
      if (el.classList && (el.classList.contains("inline-transclusion") || el.classList.contains("inline-image-wrapper"))) return true;
      if (el.getAttribute && el.getAttribute("contenteditable") === "false" && !isHiddenMarker(el)) return true;
    }
    n = n.parentNode;
  }
  return false;
}

export function getTextContent(el: HTMLElement): string {
  let result = "";
  const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT);
  let node: Node | null;
  while ((node = walker.nextNode())) {
    if (node.nodeType === Node.TEXT_NODE) {
      if (isDecorativeNode(node)) continue;
      result += node.textContent || "";
    } else if (node.nodeType === Node.ELEMENT_NODE) {
      const tag = (node as Element).tagName;
      if (tag === "BR") {
        result += "\n";
      } else if (tag === "DIV" || tag === "P") {
        if (result.length > 0 && !result.endsWith("\n")) {
          result += "\n";
        }
      }
    }
  }
  return result.replace(/\u200B/g, "");
}

export function isReadonlyNode(node: Node | null): boolean {
  let n = node;
  while (n && n.nodeType !== Node.DOCUMENT_NODE) {
    if (n.nodeType === Node.ELEMENT_NODE) {
      const el = n as Element;
      if (el.getAttribute && el.getAttribute("contenteditable") === "false") return true;
      if (el.classList && el.classList.contains("inline-transclusion")) return true;
      if (el.classList && el.classList.contains("inline-image-wrapper")) return true;
    }
    n = n.parentNode;
  }
  return false;
}

export function getEditableText(el: HTMLElement): string {
  let result = "";
  const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT);
  let node: Node | null;
  while ((node = walker.nextNode())) {
    if (node.nodeType === Node.TEXT_NODE) {
      if (isReadonlyNode(node)) continue;
      result += node.textContent || "";
    } else if (node.nodeType === Node.ELEMENT_NODE) {
      if (isReadonlyNode(node)) continue;
      const tag = (node as Element).tagName;
      if (tag === "BR") {
        result += "\n";
      } else if (tag === "DIV" || tag === "P") {
        if (result.length > 0 && !result.endsWith("\n")) {
          result += "\n";
        }
      }
    }
  }
  return result.replace(/\u200B/g, "");
}

export function validateSpanRanges(
  spanRanges: SpanRangePayload[],
  textLength: number,
): SpanRangePayload[] {
  return spanRanges.filter(
    (sr) =>
      sr.flat_start >= 0 &&
      sr.flat_end <= textLength &&
      sr.flat_end > sr.flat_start,
  );
}

export function buildTransclusionDom(
  el: HTMLElement,
  resolvedText: string,
  spanRanges: SpanRangePayload[],
  sourceTitles?: Record<number, string>,
) {
  if (!resolvedText || resolvedText.length === 0) {
    el.innerHTML = "<br>";
    return;
  }

  const validRanges = validateSpanRanges(spanRanges, resolvedText.length);

  if (validRanges.length === 0) {
    el.textContent = resolvedText;
    if (resolvedText.endsWith("\n")) {
      el.appendChild(document.createTextNode("\u200B"));
    }
    return;
  }

  const savedCursor = getCursorOffset(el);
  el.textContent = "";

  try {
    const sorted = [...validRanges].sort((a, b) => a.flat_start - b.flat_start);
    const breakpoints = new Set<number>();
    breakpoints.add(0);
    breakpoints.add(resolvedText.length);
    for (const sr of sorted) {
      breakpoints.add(sr.flat_start);
      breakpoints.add(sr.flat_end);
    }
    const segments = [...breakpoints].sort((a, b) => a - b);

    for (let i = 0; i < segments.length - 1; i++) {
      const segStart = segments[i];
      const segEnd = segments[i + 1];
      if (segStart >= segEnd) continue;

      const coveringRanges = sorted.filter(
        (sr) => sr.flat_start <= segStart && sr.flat_end >= segEnd,
      );

      let chunk = resolvedText.slice(segStart, segEnd);
      chunk = chunk.replace(/^\n+/, "").replace(/\n+$/, "");
      if (chunk.length === 0) continue;

      if (coveringRanges.length === 0) {
        el.appendChild(document.createTextNode(chunk));
      } else if (coveringRanges.length === 1) {
        const sr = coveringRanges[0];
        const title = sourceTitles?.[sr.source_work_id] || sr.source_work_id.toString(16);
        const span = document.createElement("span");
        span.className = "inline-transclusion";
        span.textContent = chunk;
        span.title = `Transclusion from: ${title} (click to navigate)`;
        (span as HTMLElement).dataset.sourceWorkId = String(sr.source_work_id);
        el.appendChild(span);
      } else {
        const sr = coveringRanges[0];
        const title = sourceTitles?.[sr.source_work_id] || sr.source_work_id.toString(16);
        const others = coveringRanges.slice(1).map(
          (r) => sourceTitles?.[r.source_work_id] || r.source_work_id.toString(16),
        );
        const span = document.createElement("span");
        span.className = "inline-transclusion inline-transclusion-overlap";
        span.textContent = chunk;
        span.title = `Overlapping transclusions from: ${title}, ${others.join(", ")}`;
        (span as HTMLElement).dataset.sourceWorkId = String(sr.source_work_id);
        el.appendChild(span);
      }
    }

    if (resolvedText.endsWith("\n")) {
      el.appendChild(document.createTextNode("\u200B"));
    }
  } catch (e) {
    console.error("[buildTransclusionDom] failed, falling back to plain text:", e);
    el.textContent = resolvedText;
    if (resolvedText.endsWith("\n")) {
      el.appendChild(document.createTextNode("\u200B"));
    }
  }

  setCursorOffset(el, savedCursor);
}

export function insertInlineImages(
  el: HTMLElement,
  blobs: Array<{ charPos: number; hash: string; url?: string; mime?: string; width?: number; height?: number }>,
) {
  el.querySelectorAll(".inline-image-wrapper").forEach((n) => n.remove());
  if (blobs.length === 0) return;

  const sorted = [...blobs].filter((b) => b.charPos >= 0).sort((a, b) => a.charPos - b.charPos);
  const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
  let charCount = 0;
  let blobIdx = 0;
  const insertions: Array<{ textNode: Text; offset: number; blob: typeof sorted[0] }> = [];

  let node: Node | null;
  while ((node = walker.nextNode()) && blobIdx < sorted.length) {
    if (isReadonlyNode(node)) continue;
    const textNode = node as Text;
    const raw = textNode.textContent || "";
    const textLen = raw.replace(/\u200B/g, "").length;

    while (blobIdx < sorted.length && sorted[blobIdx].charPos <= charCount + textLen) {
      const relativeOffset = sorted[blobIdx].charPos - charCount;
      let actualOffset = 0;
      let count = 0;
      for (let i = 0; i < raw.length && count < relativeOffset; i++) {
        if (raw[i] !== "\u200B") count++;
        actualOffset++;
      }
      insertions.push({ textNode, offset: actualOffset, blob: sorted[blobIdx] });
      blobIdx++;
    }
    charCount += textLen;
  }

  for (let i = insertions.length - 1; i >= 0; i--) {
    const { textNode, offset, blob } = insertions[i];
    const wrapper = document.createElement("span");
    wrapper.className = "inline-image-wrapper";
    wrapper.setAttribute("contenteditable", "false");

    if (blob.url) {
      const img = document.createElement("img");
      img.className = "inline-image";
      img.src = blob.url;
      img.alt = `blob:${blob.hash}`;
      const displayW = blob.width ? Math.min(blob.width, 400) : 400;
      img.style.width = "100%";
      img.style.height = "auto";
      img.style.display = "block";
      wrapper.style.width = `${displayW}px`;
      wrapper.style.height = "auto";
      wrapper.style.resize = "horizontal";
      wrapper.style.overflow = "hidden";
      wrapper.style.maxWidth = "100%";
      wrapper.appendChild(img);

      const sizeLabel = document.createElement("div");
      sizeLabel.className = "inline-image-size";
      sizeLabel.textContent = `${displayW}px`;
      sizeLabel.style.cssText = "font-size:9px;color:#999;text-align:right;padding:1px 4px;background:rgba(255,255,255,0.9);";
      wrapper.appendChild(sizeLabel);

      if (typeof ResizeObserver !== "undefined") {
        const ro = new ResizeObserver(() => {
          const w = Math.round(wrapper.offsetWidth);
          sizeLabel.textContent = `${w}px`;
        });
        ro.observe(wrapper);
      }
    } else {
      wrapper.textContent = "[image]";
      wrapper.style.cssText = "display:inline-block;padding:4px 8px;background:#f0f0f0;border-radius:4px;color:#999;font-size:11px;";
    }

    try {
      if (offset === 0) {
        textNode.parentNode?.insertBefore(wrapper, textNode);
      } else if (offset >= (textNode.textContent || "").length) {
        textNode.parentNode?.insertBefore(wrapper, textNode.nextSibling);
      } else {
        const after = textNode.splitText(offset);
        textNode.parentNode?.insertBefore(wrapper, after);
      }
    } catch { /* node may have been removed by earlier split */ }
  }
}
