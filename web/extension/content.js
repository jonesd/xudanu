// Xudanu Overlay content script (FR-79 Stage 2).
//
// Contract (spec 2.2): the extension NEVER matches text itself. It
// extracts the page's text spine (code-point indexed — matching the
// server's char offsets exactly), sends {url, text} to the server,
// and renders the offsets the server resolved against THAT text.
// Marks without a resolution do not render — failure is silent by
// design. Everything is best-effort: a hostile DOM means no marks,
// never errors on the page.

(() => {
  "use strict";
  if (window.__xudanuOverlayLoaded) return;
  window.__xudanuOverlayLoaded = true;

  const SKIP_TAGS = new Set([
    "SCRIPT", "STYLE", "NOSCRIPT", "TEMPLATE", "SVG", "IFRAME",
    "CANVAS", "TEXTAREA", "INPUT", "SELECT", "OPTION",
  ]);

  // ── Text spine ─────────────────────────────────────────────────
  // Walk visible text nodes in document order; index them by code
  // points (Unicode scalar values — same unit as the server's char
  // offsets; UTF-16 conversion happens only when cutting DOM Ranges).

  function nodeVisible(node) {
    let el = node.parentElement;
    while (el) {
      if (SKIP_TAGS.has(el.tagName)) return false;
      if (el.hidden || el.getAttribute("aria-hidden") === "true") return false;
      const cs = getComputedStyle(el);
      if (cs.display === "none" || cs.visibility === "hidden") return false;
      el = el.parentElement;
    }
    return true;
  }

  function extractSpine() {
    const segments = []; // {node, cpStart, cpLen}
    let spine = "";
    let spineCp = 0; // running code-point count
    const walker = document.createTreeWalker(
      document.body || document.documentElement,
      NodeFilter.SHOW_TEXT,
      {
        acceptNode(n) {
          if (!n.nodeValue || !n.nodeValue.trim()) return NodeFilter.FILTER_REJECT;
          return nodeVisible(n) ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT;
        },
      }
    );
    let n;
    while ((n = walker.nextNode())) {
      let cpLen = 0;
      for (const _ of n.nodeValue) cpLen++; // code points, not UTF-16
      if (!cpLen) continue;
      segments.push({ node: n, cpStart: spineCp, cpLen });
      spine += n.nodeValue + "\n";
      spineCp += cpLen + 1;
    }
    return { text: spine, segments };
  }

  function cpToUtf16(str, cpIndex) {
    let cps = 0;
    for (let i = 0; i < str.length; ) {
      if (cps === cpIndex) return i;
      const cp = str.codePointAt(i);
      i += cp > 0xffff ? 2 : 1;
      cps++;
    }
    return str.length; // cpIndex at/after end
  }

  // Map a code-point offset in the spine to a DOM Range.
  function rangeFor(start, end, segments) {
    if (!segments.length || start >= end) return null;
    let seg = null, localCp = 0;
    for (const s of segments) {
      if (start < s.cpStart + s.cpLen) {
        if (start >= s.cpStart) { seg = s; localCp = start - s.cpStart; }
        break;
      }
    }
    if (!seg) return null;
    let seg2 = null, localCp2 = 0;
    for (const s of segments) {
      if (end <= s.cpStart + s.cpLen) {
        seg2 = s; localCp2 = Math.max(0, end - s.cpStart); break;
      }
    }
    if (!seg2) { seg2 = segments[segments.length - 1]; localCp2 = seg2.cpLen; }
    try {
      const r = document.createRange();
      r.setStart(seg.node, cpToUtf16(seg.node.nodeValue, localCp));
      r.setEnd(seg2.node, cpToUtf16(seg2.node.nodeValue, localCp2));
      return r;
    } catch (_) {
      return null;
    }
  }

  // ── Rendering ──────────────────────────────────────────────────

  const CONTAINER_ID = "__xudanu_overlay_container";
  const HIGHLIGHT_NAME = "xudanu-overlay-mark";

  function styleOnce() {
    if (document.getElementById("__xudanu_overlay_style")) return;
    const st = document.createElement("style");
    st.id = "__xudanu_overlay_style";
    st.textContent = `
      ::highlight(${HIGHLIGHT_NAME}) {
        background-color: rgba(28, 93, 153, 0.16);
      }
      #${CONTAINER_ID} { position: absolute; top: 0; left: 0; width: 0; height: 0; z-index: 2147483646; pointer-events: none; }
      .xudanu-ribbon { position: absolute; width: 6px; border-radius: 3px; pointer-events: auto; cursor: pointer; }
      .xudanu-ribbon.incoming { background: rgba(28, 93, 153, 0.85); }
      .xudanu-ribbon.outgoing { background: rgba(196, 124, 18, 0.85); }
      .xudanu-ribbon:hover { width: 9px; }
      .xudanu-tip { position: absolute; max-width: 320px; background: #10222f; color: #eef4f9; font: 12px/1.45 system-ui, sans-serif;
        padding: 8px 10px; border-radius: 8px; box-shadow: 0 4px 14px rgba(0,0,0,.3); pointer-events: none; z-index: 2147483647; }
      .xudanu-tip .t { font-weight: 600; margin-bottom: 2px; }
      .xudanu-tip .m { color: #9fb6c8; }
    `;
    document.documentElement.appendChild(st);
  }

  function clearRender() {
    const c = document.getElementById(CONTAINER_ID);
    if (c) c.remove();
    if (CSS.highlights) CSS.highlights.delete(HIGHLIGHT_NAME);
    document.querySelectorAll(".xudanu-tip").forEach((t) => t.remove());
  }

  function render(marksResp, serverUrl, segments) {
    clearRender();
    const resolved = (marksResp.marks || []).filter((m) => m.resolution);
    if (!resolved.length) return 0; // zero render — silent by design

    styleOnce();
    const container = document.createElement("div");
    container.id = CONTAINER_ID;

    const ranges = [];
    if (CSS.highlights && typeof Highlight !== "undefined") {
      for (const m of resolved) {
        const r = rangeFor(m.resolution.start, m.resolution.end, segments);
        if (r) ranges.push(r);
      }
      if (ranges.length) {
        CSS.highlights.set(HIGHLIGHT_NAME, new Highlight(...ranges));
      }
    }

    let stack = 0;
    for (const m of resolved) {
      const r = rangeFor(m.resolution.start, m.resolution.end, segments);
      if (!r) continue;
      let rect;
      try {
        const rects = r.getClientRects();
        if (!rects.length) continue;
        rect = rects[0];
      } catch (_) {
        continue;
      }
      const ribbon = document.createElement("div");
      ribbon.className = "xudanu-ribbon " + (m.direction || "incoming");
      // Margin convention from the app: RIGHT = incoming, LEFT = outgoing.
      const right = m.direction === "outgoing";
      ribbon.style.top = window.scrollY + rect.top + "px";
      ribbon.style.height = Math.max(rect.height, 10) + "px";
      if (right) {
        ribbon.style.left = window.scrollX + document.documentElement.clientWidth - 12 + "px";
      } else {
        ribbon.style.left = "6px";
      }
      ribbon.style.marginTop = stack * 3 + "px";
      stack++;

      attachTooltip(ribbon, m);
      ribbon.addEventListener("click", (e) => {
        e.preventDefault(); e.stopPropagation();
        const far = m.far && m.far.work_id;
        const farSpan = m.far_span;
        const shadowId = marksResp.shadow && marksResp.shadow.work_id;
        let url;
        if (far && farSpan) {
          url = `${serverUrl}/?work=0x${far}#C${farSpan.start}`;
        } else if (far) {
          url = `${serverUrl}/?work=0x${far}`;
        } else if (shadowId) {
          url = `${serverUrl}/?work=0x${shadowId}#C${m.resolution.start}`;
        } else {
          url = serverUrl;
        }
        window.open(url, "_blank", "noopener");
      });
      container.appendChild(ribbon);
    }
    document.documentElement.appendChild(container);
    return resolved.length;
  }

  function attachTooltip(ribbon, m) {
    let tip = null;
    ribbon.addEventListener("mouseenter", () => {
      tip = document.createElement("div");
      tip.className = "xudanu-tip";
      const types = (m.link_type_names || []).join(", ") || "connection";
      const dir = m.direction === "outgoing" ? "page → " : "→ page";
      const far = m.far && m.far.title ? m.far.title : "a work";
      const how = m.resolution && m.resolution.how ? m.resolution.how : "?";
      const excerpt = (m.excerpt || "").slice(0, 140);
      tip.innerHTML = "";
      const t = document.createElement("div");
      t.className = "t";
      t.textContent = `${types} ${dir} "${far}"`;
      const meta = document.createElement("div");
      meta.className = "m";
      meta.textContent = `proof: ${how}${m.author ? " · by " + m.author : ""} · click to open in Xudanu`;
      tip.appendChild(t);
      tip.appendChild(meta);
      if (excerpt) {
        const ex = document.createElement("div");
        ex.textContent = "“" + excerpt + "”";
        tip.appendChild(ex);
      }
      const r = ribbon.getBoundingClientRect();
      tip.style.left = window.scrollX + Math.min(r.left - 330, 40) + "px";
      tip.style.top = window.scrollY + r.top + "px";
      document.documentElement.appendChild(tip);
    });
    ribbon.addEventListener("mouseleave", () => {
      if (tip) tip.remove();
      tip = null;
    });
  }

  // ── Query + lifecycle ──────────────────────────────────────────

  let inflight = false;

  async function run() {
    if (inflight) return;
    inflight = true;
    try {
      const { serverUrl } = await chrome.storage.local.get({ serverUrl: "" });
      if (!serverUrl || !/^https?:\/\//.test(location.href)) return;
      const spine = extractSpine();
      if (!spine.text.trim()) return;
      const resp = await chrome.runtime.sendMessage({
        type: "marks",
        url: location.href,
        text: spine.text,
      });
      if (!resp || !resp.ok) return; // silent by design
      render(resp.body, serverUrl.replace(/\/+$/, ""), spine.segments);
    } catch (_) {
      // Never surface errors to the page.
    } finally {
      inflight = false;
    }
  }

  // Reposition (not re-query) when the page shifts under us.
  let repositionTimer = null;
  new MutationObserver(() => {
    if (repositionTimer) return;
    repositionTimer = setTimeout(() => {
      repositionTimer = null;
      const c = document.getElementById(CONTAINER_ID);
      if (!c) return;
      clearRender();
      run();
    }, 1500);
  }).observe(document.documentElement, { childList: true, subtree: true, characterData: true });

  window.addEventListener("resize", () => { clearRender(); run(); });
  window.addEventListener("popstate", () => run());
  window.__xudanuOverlayRefresh = run;

  run();
})();
