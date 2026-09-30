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
  // Diagnostic marker, readable from the page world (isolated-world
  // variables are not): proves the content script injected.
  document.documentElement.dataset.xudanuLoaded = "1";

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
      let rects;
      try {
        rects = Array.from(r.getClientRects());
        if (!rects.length) continue;
      } catch (_) {
        continue;
      }
      // Multi-line spans: the ribbon stands beside the WHOLE passage
      // (first line's top → last line's bottom), not just line one.
      const top = Math.min(...rects.map((x) => x.top));
      const bottom = Math.max(...rects.map((x) => x.bottom));
      const first = rects[0];

      const ribbon = document.createElement("div");
      ribbon.className = "xudanu-ribbon " + (m.direction || "incoming");
      // Margin convention from the app: RIGHT = incoming (links into
      // this page's content), LEFT = outgoing (this page's links out).
      const incoming = m.direction !== "outgoing";
      const pageTop = window.scrollY + top;
      const height = Math.max(bottom - top, first.height);
      ribbon.style.top = pageTop + "px";
      ribbon.style.height = height + "px";
      if (incoming) {
        ribbon.style.left =
          window.scrollX + document.documentElement.clientWidth - 12 + "px";
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

  // Debug mode: append ?xudanu-debug=1 to the page URL and the
  // script's state renders as a fixed pill bottom-right — no
  // console needed.
  const DEBUG = /[?&]xudanu-debug/.test(location.search);
  function statusPill(text, color) {
    if (!DEBUG) return;
    let el = document.getElementById("__xudanu_status");
    if (!el) {
      el = document.createElement("div");
      el.id = "__xudanu_status";
      el.style.cssText =
        "position:fixed;bottom:8px;right:8px;z-index:2147483647;background:#10222f;color:#fff;" +
        "font:12px system-ui;padding:6px 10px;border-radius:6px;max-width:340px;pointer-events:none;";
      document.documentElement.appendChild(el);
    }
    el.textContent = "Xudanu: " + text;
    el.style.borderLeft = "4px solid " + (color || "#9fb6c8");
  }

  async function run() {
    if (inflight) return;
    inflight = true;
    try {
      // NOTE: do NOT clear before a successful re-query — a failed
      // background re-render must never blank an existing render.
      // clearRender() runs only after new marks are in hand.
      const { serverUrl } = await chrome.storage.local.get({ serverUrl: "" });
      if (!serverUrl || !/^https?:\/\//.test(location.href)) {
        statusPill(serverUrl ? "page not http(s)" : "no server configured", "#c47c12");
        return;
      }
      const spine = extractSpine();
      if (!spine.text.trim()) {
        statusPill("no visible text found", "#c47c12");
        return;
      }
      console.debug("[xudanu] querying", serverUrl, "spine", spine.text.length, "chars,", spine.segments.length, "segments");
      statusPill("querying server…");
      const resp = await chrome.runtime.sendMessage({
        type: "marks",
        url: location.href,
        text: spine.text,
      });
      if (!resp || !resp.ok) {
        statusPill("marks query failed: " + (resp && resp.error), "#c0392b");
        console.debug("[xudanu] marks response not ok:", resp && resp.error);
        return; // silent by design — prior render (if any) stands
      }
      // Atomic swap: build fresh, remove old only once new marks
      // are in hand.
      clearRender();
      const n = render(resp.body, serverUrl.replace(/\/+$/, ""), spine.segments);
      statusPill(
        n > 0 ? `${n} mark(s) rendered` : "no marks for this page",
        n > 0 ? "#3fb950" : "#7d8590"
      );
      console.debug("[xudanu] rendered", n, "marks");
    } catch (e) {
      // Never surface errors to the page.
      statusPill("error: " + String(e).slice(0, 120), "#c0392b");
      console.debug("[xudanu] run failed:", String(e));
    } finally {
      inflight = false;
    }
  }

  // Reposition (not re-query) when the page shifts under us.
  // SELF-MUTATION GUARD: our own container, tooltips, and style
  // element must not retrigger the observer — otherwise render →
  // mutation → clear → render loops forever and ribbons never
  // stabilize (found by the Playwright hover-stability check).
  let repositionTimer = null;
  const isOwnMutation = (m) => {
    const t = m.target;
    if (!(t instanceof Node)) return false;
    if (t === document.documentElement || t === document.body) {
      // Only "ours" if the added/removed nodes are our elements.
      return [...m.addedNodes, ...m.removedNodes].every(
        (n) =>
          n instanceof Element &&
          (n.id === CONTAINER_ID ||
            n.id === "__xudanu_overlay_style" ||
            n.classList?.contains("xudanu-tip"))
      );
    }
    const el = t instanceof Element ? t : t.parentElement;
    return !!el && (el.id === CONTAINER_ID || el.closest?.(`#${CONTAINER_ID}, .xudanu-tip`) != null);
  };
  new MutationObserver((muts) => {
    if (muts.every(isOwnMutation)) return;
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
