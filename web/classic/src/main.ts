import {
  ClassicClient,
  LINK_TYPE_NAMES,
  WireError,
  type LinkEntryClassic,
  type TrailEntry,
} from "./client";
import { GrabReviseEditor, type WorkEditor } from "./editor";
import { WindowsView } from "./windows";

const app = document.getElementById("app")!;
let client: ClassicClient | null = null;
let mode: "panes" | "windows" = localStorage.getItem("xudanu_classic_mode") === "windows" ? "windows" : "panes";
let winView: WindowsView | null = null;
let editor: WorkEditor | null = null;
let editing: { workId: number } | null = null;
let statusTimer: number | null = null;

function setStatus(msg: string): void {
  const el = document.getElementById("head-status");
  if (!el) return;
  el.textContent = msg;
  if (statusTimer !== null) window.clearTimeout(statusTimer);
  if (msg) statusTimer = window.setTimeout(() => { el.textContent = ""; }, 5000);
}

interface Pane {
  workId: number;
  title: string;
  text: string;
  links: LinkEntryClassic[];
}

let paneA: Pane | null = null;
let paneB: Pane | null = null;
let activeLink: LinkEntryClassic | null = null;

function esc(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function typeOf(l: LinkEntryClassic): { name: string; color: string } {
  const id = (l.link_types ?? [0])[0];
  return LINK_TYPE_NAMES[id] ?? { name: "link", color: "#8a857b" };
}

interface Mark {
  start: number;
  end: number;
  link: LinkEntryClassic;
}

function marksFor(pane: Pane): Mark[] {
  const out: Mark[] = [];
  for (const l of pane.links) {
    if (l.origin === pane.workId && l.origin_ref?.start_position !== undefined) {
      out.push({ start: l.origin_ref.start_position, end: l.origin_ref.end_position ?? l.origin_ref.start_position, link: l });
    }
    if (l.destination === pane.workId && l.destination_ref?.start_position !== undefined) {
      out.push({ start: l.destination_ref.start_position, end: l.destination_ref.end_position ?? l.destination_ref.start_position, link: l });
    }
  }
  return out.sort((a, b) => a.start - b.start);
}

function renderText(pane: Pane): string {
  const marks = marksFor(pane);
  let html = "";
  let pos = 0;
  for (const m of marks) {
    if (m.start < pos || m.start > pane.text.length) continue;
    html += esc(pane.text.slice(pos, m.start));
    const t = typeOf(m.link);
    html += `<mark data-link="${m.link.link_id}" style="border-bottom:2px solid ${t.color};background:${t.color}18;cursor:pointer" title="${esc(t.name)} → ${esc(farTitle(m.link, pane.workId))}">${esc(pane.text.slice(m.start, Math.min(m.end, pane.text.length)))}</mark>`;
    pos = Math.min(m.end, pane.text.length);
  }
  html += esc(pane.text.slice(pos));
  return html;
}

function farTitle(l: LinkEntryClassic, from: number): string {
  if (l.origin === from) return l.destination_title ?? `work ${l.destination}`;
  return l.origin_title ?? `work ${l.origin}`;
}

function farId(l: LinkEntryClassic, from: number): number | null {
  if (l.origin === from) return l.destination;
  return l.origin;
}

function firstLine(text: string, workId: number): string {
  const l = text.split("\n")[0].slice(0, 72).trim();
  return l || `work ${workId}`;
}

async function openWork(workId: number, pane: "A" | "B", push = true): Promise<void> {
  if (!client) return;
  if (editing) {
    await editor?.cancel(editing.workId);
    editor = null;
    editing = null;
  }
  const text = await client.readWork(workId);
  const links = await client.linksFor(workId);
  const p: Pane = { workId, title: firstLine(text, workId), text, links };
  if (pane === "A") {
    paneA = p;
    paneB = null;
    activeLink = null;
    if (push) history.pushState({ w: workId }, "", `#w${workId}`);
  } else {
    paneB = p;
  }
  render();
}

function connectionsHtml(pane: Pane): string {
  if (pane.links.length === 0) return `<p class="quiet small">no connections touch this work</p>`;
  return pane.links
    .map((l) => {
      const t = typeOf(l);
      return `<a href="#" class="conn" data-link="${l.link_id}" style="border-left:3px solid ${t.color};padding-left:8px">
        <span class="quiet small">${esc(t.name)}</span><br>${esc(farTitle(l, pane.workId))}</a>`;
    })
    .join("");
}

function paneHtml(p: Pane, tag: string, closable: boolean, isEditing = false): string {
  const editBtn = tag === "a" && !isEditing ? `<button class="close-pane" id="revise-start" title="revise this work">✎</button>` : closable ? `<button class="close-pane" id="close-pane">×</button>` : "";
  const body = isEditing
    ? `<textarea id="revise-text" class="revise" spellcheck="false">${esc(p.text)}</textarea>`
    : `<pre class="prose">${renderText(p)}</pre>`;
  const bar = isEditing
    ? `<div class="revise-bar"><button id="revise-save" class="revise-btn">save</button><button id="revise-cancel" class="revise-btn ghosted">cancel</button><span class="quiet small">grabbed — ⌘↵ saves · esc cancels</span></div>`
    : "";
  return `<section class="pane" id="pane-${tag}">
    <div class="pane-head"><h2>${esc(p.title)}</h2>${editBtn}</div>
    <div class="pane-scroll pane-editing-${isEditing ? "on" : "off"}" id="scroll-${tag}">${body}</div>
    ${bar}
    ${isEditing ? "" : `<div class="pane-conns"><h3>connections</h3>${connectionsHtml(p)}</div>`}
  </section>`;
}

function render(): void {
  if (!client) {
    app.innerHTML = `<div class="gate">
      <h1>Xudanu <span>classic</span></h1>
      <p class="quiet">A reading posture for the docuverse.<br>Read-only; speaks the wire contract, api_version 1.</p>
      <button id="connect">connect</button>
      <p id="gate-status" class="quiet"></p>
    </div>`;
    document.getElementById("connect")!.onclick = async () => {
      const status = document.getElementById("gate-status")!;
      status.textContent = "connecting…";
      try {
        client = new ClassicClient();
        await client.connect();
window.onpopstate = () => {
  if (!client) return;
  const wm = /^#w(\d+)$/.exec(location.hash);
  const tm = /^#t(\d+)$/.exec(location.hash);
  if (wm) {
    void openWork(Number(wm[1]), "A", false);
  } else {
    openTrailId = tm ? Number(tm[1]) : null;
    if (paneA) renderTrailsNav();
    else render();
  }
};

window.addEventListener("keydown", (e) => {
  if (!e.altKey || e.key !== "ArrowLeft" && e.key !== "ArrowRight") return;
  const inField = (document.activeElement as HTMLElement | null)?.closest?.("input, textarea");
  if (inField) return;
  e.preventDefault();
  if (e.key === "ArrowLeft") history.back();
  else history.forward();
});

render();
        const wm = /^#w(\d+)$/.exec(location.hash);
        if (wm) void openWork(Number(wm[1]), "A", false);
      } catch (e) {
        status.textContent = String(e instanceof Error ? e.message : e);
      }
    };
    return;
  }

  const openTrail = openTrailId !== null ? trailCache.find((t) => t.trail_id === openTrailId) : undefined;
  const windowsMode = mode === "windows" && !!paneA;
  const main = windowsMode
    ? `<div id="stage" class="stage"></div>`
    : paneA
    ? `<div class="panes" id="panes">
        ${paneHtml(paneA!, "a", false, !!editing && editing.workId === paneA!.workId)}
        ${paneB ? paneHtml(paneB, "b", true) : `<section class="pane ghost" id="pane-b"><div class="pane-head"><h2 class="quiet">—</h2></div><div class="pane-scroll"><p class="quiet">Click an underline or a connection to open its far end here, joined by a beam.</p></div></section>`}
        <svg id="beams"></svg>
      </div>`
    : openTrail
      ? trailArticle(openTrail)
      : `<article><p class="quiet">Search, or follow a trail. Underlines are live connections —
        click one to open the far end beside this work, joined by a beam.</p></article>`;

  app.innerHTML = `
    <header>
      <span class="mark">Xudanu <span>classic</span></span>
      <div class="head-right">
        <span class="navbtns">
          <button id="hist-back" title="back (alt-←)">‹</button>
          <button id="hist-fwd" title="forward (alt-→)">›</button>
          <button id="mode-toggle" title="switch posture">${mode === "windows" ? "⧉ windows" : "▤ panes"}</button>
        </span>
        ${paneA ? `<a class="head-link" href="/?work=0x${paneA.workId.toString(16)}" title="open this work in the workspace">workspace ↗</a>` : ""}
        <span id="head-status" class="quiet small"></span>
        <span class="quiet">${esc(client.serverName)} · v${esc(client.serverVersion || "?")} · api ${client.apiVersion}</span>
      </div>
    </header>
    <div class="frame">
      <nav>
        <form id="search"><input id="q" placeholder="search the docuverse" autocomplete="off"></form>
        <div id="results"></div>
        <div id="trails"></div>
      </nav>
      <main>${main}</main>
    </div>`;

  ensureTrails();
  renderTrailsNav();
  wireSearch();
  wireMainWorkLinks();
  wireHistoryButtons();
  wireRevise();
  document.getElementById("mode-toggle")!.onclick = async () => {
    if (editing) {
      await editor?.cancel(editing.workId);
      editor = null;
      editing = null;
    }
    mode = mode === "windows" ? "panes" : "windows";
    localStorage.setItem("xudanu_classic_mode", mode);
    render();
  };
  if (windowsMode) {
    const stage = document.getElementById("stage")!;
    winView = new WindowsView(
      stage,
      client,
      (workId) => void openWork(workId, "A"),
      { start: () => void startEditing(), save: () => void commitEditing(), cancel: () => void cancelEditing() },
    );
    void winView.setCenter(paneA!.workId);
  } else {
    winView?.destroy();
    winView = null;
    wireMarks();
    wireConns();
    wireClose();
    drawBeams();
    observeBeams();
  }
}

function wireHistoryButtons(): void {
  document.getElementById("hist-back")?.addEventListener("click", () => history.back());
  document.getElementById("hist-fwd")?.addEventListener("click", () => history.forward());
}

async function startEditing(): Promise<void> {
  if (!client || !paneA || editing) return;
  setStatus("grabbing…");
  const ed = new GrabReviseEditor(client);
  try {
    await ed.begin(paneA.workId);
  } catch (e) {
    const we = e as WireError;
    if (we.code === "not_grabbed" || /not grabbed/i.test(we.message ?? "")) {
      setStatus("held by another session — try again shortly");
    } else {
      setStatus(we.message ?? String(e));
    }
    return;
  }
  editor = ed;
  editing = { workId: paneA.workId };
  if (mode === "windows" && winView) {
    winView.setEditing(paneA.text);
    setStatus("grabbed — you hold this work");
  } else {
    render();
    setStatus("grabbed — you hold this work");
  }
}

async function commitEditing(): Promise<void> {
  if (!client || !editing || !editor) return;
  const ta = document.getElementById("revise-text") as HTMLTextAreaElement | null;
  if (!ta) return;
  setStatus("saving…");
  try {
    await editor.commit(editing.workId, ta.value);
  } catch (e) {
    setStatus((e as Error).message);
    return;
  }
  const workId = editing.workId;
  editor = null;
  editing = null;
  if (mode === "windows" && winView) {
    await winView.refreshCenter();
    winView.setEditing(null);
  } else {
    const text = await client.readWork(workId);
    const links = await client.linksFor(workId);
    paneA = { workId, title: firstLine(text, workId), text, links };
    render();
  }
  setStatus("saved");
}

async function cancelEditing(): Promise<void> {
  if (!editing) return;
  const workId = editing.workId;
  await editor?.cancel(workId);
  editor = null;
  editing = null;
  setStatus("");
  if (mode === "windows" && winView) winView.setEditing(null);
  else render();
}

function wireRevise(): void {
  document.getElementById("revise-start")?.addEventListener("click", () => void startEditing());
  document.getElementById("revise-save")?.addEventListener("click", () => void commitEditing());
  document.getElementById("revise-cancel")?.addEventListener("click", () => void cancelEditing());
  const ta = document.getElementById("revise-text") as HTMLTextAreaElement | null;
  if (ta) {
    ta.addEventListener("keydown", (e) => {
      if (e.key === "Escape") {
        e.preventDefault();
        void cancelEditing();
      } else if ((e.metaKey || e.ctrlKey) && e.key === "Enter") {
        e.preventDefault();
        void commitEditing();
      }
    });
    ta.focus();
  }
}

function wireSearch(): void {
  document.getElementById("search")!.onsubmit = async (ev) => {
    ev.preventDefault();
    const q = (document.getElementById("q") as HTMLInputElement).value.trim();
    if (!q || !client) return;
    try {
      const entries = await client.search(q);
      document.getElementById("results")!.innerHTML =
        entries.length === 0
          ? `<p class="quiet small">nothing found</p>`
          : entries.map((e) => `<a href="#" data-work="${e.work_id}">${esc(e.title || `work ${e.work_id}`)}</a>`).join("");
      document.querySelectorAll<HTMLAnchorElement>("#results a[data-work]").forEach((a) => {
        a.onclick = (ev2) => {
          ev2.preventDefault();
          void openWork(Number(a.dataset.work), "A");
        };
      });
    } catch (e) {
      document.getElementById("results")!.innerHTML = `<p class="quiet small">${esc(String(e))}</p>`;
    }
  };
}

let trailCache: TrailEntry[] = [];
let trailsLoaded = false;
let openTrailId: number | null = null;

function trailArticle(t: TrailEntry): string {
  const stops = t.stops
    .map((s) => `<li><a href="#" data-work="${s.work_id}">${esc(s.title || `work ${s.work_id}`)}</a>${s.note ? `<span class="quiet"> — ${esc(s.note)}</span>` : ""}</li>`)
    .join("");
  return `<article><h2>${esc(t.name)}</h2>${t.introduction ? `<p class="quiet">${esc(t.introduction)}</p>` : ""}<ol class="stops">${stops}</ol></article>`;
}

function ensureTrails(): void {
  if (trailsLoaded || !client) return;
  trailsLoaded = true;
  client
    .trails()
    .then((ts) => {
      trailCache = ts;
      renderTrailsNav();
      if (!paneA && openTrailId !== null) render();
    })
    .catch(() => {});
}

function renderTrailsNav(): void {
  const el = document.getElementById("trails");
  if (!el) return;
  el.innerHTML =
    `<h3>trails</h3>` +
    trailCache
      .map((t) => {
        const open = openTrailId === t.trail_id;
        return (
          `<a href="#" data-trail="${t.trail_id}"${open ? ` class="open"` : ""}>${esc(t.name)}</a>` +
          (open
            ? `<div class="trail-stops">` +
              t.stops
                .map((s) => `<a href="#" data-work="${s.work_id}" title="${esc(s.note ?? "")}">${esc(s.title || `work ${s.work_id}`)}</a>`)
                .join("") +
              `</div>`
            : "")
        );
      })
      .join("");
  el.querySelectorAll<HTMLAnchorElement>("a[data-trail]").forEach((a) => {
    a.onclick = (ev) => {
      ev.preventDefault();
      const tid = Number(a.dataset.trail);
      const opening = openTrailId !== tid;
      openTrailId = opening ? tid : null;
      if (opening && !paneA) history.pushState({ t: tid }, "", `#t${tid}`);
      if (paneA) renderTrailsNav();
      else render();
    };
  });
  el.querySelectorAll<HTMLAnchorElement>("a[data-work]").forEach((a) => {
    a.onclick = (ev) => {
      ev.preventDefault();
      void openWork(Number(a.dataset.work), "A");
    };
  });
}

function wireMainWorkLinks(): void {
  document.querySelectorAll<HTMLAnchorElement>("main a[data-work]").forEach((a) => {
    a.onclick = (ev) => {
      ev.preventDefault();
      void openWork(Number(a.dataset.work), "A");
    };
  });
}

function wireMarks(): void {
  document.querySelectorAll<HTMLElement>("mark[data-link]").forEach((m) => {
    m.onclick = () => {
      const from = m.closest("#pane-b") ? "b" : "a";
      void follow(Number(m.dataset.link), from);
    };
  });
}

function wireConns(): void {
  document.querySelectorAll<HTMLAnchorElement>("a.conn").forEach((a) => {
    a.onclick = (ev) => {
      ev.preventDefault();
      const from = a.closest("#pane-b") ? "b" : "a";
      void follow(Number(a.dataset.link), from);
    };
  });
}

async function follow(linkId: number, from: "a" | "b" = "a"): Promise<void> {
  if (!client) return;
  const src = from === "a" ? paneA : paneB;
  if (!src) return;
  const l = src.links.find((x) => x.link_id === linkId);
  if (!l) return;
  const far = farId(l, src.workId);
  if (far === null) return;
  activeLink = l;
  const other = from === "a" ? paneB : paneA;
  if (!other || other.workId !== far) {
    const text = await client.readWork(far);
    const links = await client.linksFor(far);
    const p: Pane = { workId: far, title: firstLine(text, far), text, links };
    if (from === "a") paneB = p;
    else paneA = p;
  }
  render();
}

function wireClose(): void {
  document.getElementById("close-pane")?.addEventListener("click", () => {
    paneB = null;
    activeLink = null;
    render();
  });
}

function drawBeams(): void {
  const svg = document.getElementById("beams") as SVGSVGElement | null;
  if (!svg || !paneA || !paneB || !activeLink) {
    if (svg) svg.innerHTML = "";
    return;
  }
  const panes = document.getElementById("panes")!;
  const svgR = panes.getBoundingClientRect();
  svg.setAttribute("width", String(svgR.width));
  svg.setAttribute("height", String(svgR.height));

  const t = typeOf(activeLink);
  const markA = document.querySelector<HTMLElement>(`#scroll-a mark[data-link="${activeLink.link_id}"]`);
  const markB = document.querySelector<HTMLElement>(`#scroll-b mark[data-link="${activeLink.link_id}"]`);
  const headB = document.querySelector<HTMLElement>("#pane-b .pane-head");

  const anchorA = markA ?? document.querySelector<HTMLElement>("#pane-a .pane-head");
  const anchorB = markB ?? headB;
  if (!anchorA || !anchorB) return;

  const lastLine = (el: HTMLElement): DOMRect => {
    const lines = el.getClientRects();
    return lines.length > 0 ? lines[lines.length - 1] : el.getBoundingClientRect();
  };
  const ra = markA ? lastLine(markA) : anchorA.getBoundingClientRect();
  const rb = anchorB.getBoundingClientRect();
  const x1 = ra.right - svgR.left;
  const y1 = ra.bottom - 1 - svgR.top;
  const x2 = rb.left - svgR.left;
  const y2 = rb.top + rb.height / 2 - svgR.top;

  const mid = (x1 + x2) / 2;
  svg.innerHTML = `<path d="M ${x1} ${y1} C ${mid} ${y1}, ${mid} ${y2}, ${x2} ${y2}"
    fill="none" stroke="${t.color}" stroke-width="1.6" stroke-dasharray="5 4" opacity="0.85">
    <animate attributeName="stroke-dashoffset" from="18" to="0" dur="1.2s" repeatCount="indefinite"/>
  </path>`;
}

let beamObserver: ResizeObserver | null = null;
function observeBeams(): void {
  beamObserver?.disconnect();
  const sa = document.getElementById("scroll-a");
  const sb = document.getElementById("scroll-b");
  if (!sa || !sb) return;
  const redraw = () => drawBeams();
  sa.addEventListener("scroll", redraw);
  sb.addEventListener("scroll", redraw);
  window.addEventListener("resize", redraw);
  beamObserver = new ResizeObserver(redraw);
  beamObserver.observe(sa);
  beamObserver.observe(sb);
}

render();
