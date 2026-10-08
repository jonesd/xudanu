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
let skin: "ink" | "paper" = localStorage.getItem("xudanu_classic_skin") === "paper" ? "paper" : "ink";
let winView: WindowsView | null = null;
let focusPane: "a" | "b" = "a";
let editor: WorkEditor | null = null;
let editing: { workId: number; pane: "a" | "b" } | null = null;
let statusTimer: number | null = null;

type LinkDraft =
  | { stage: "origin"; start: number; end: number; excerpt: string }
  | { stage: "far"; start: number; end: number; excerpt: string; farWork: number; farTitle: string; farRef?: { start: number; end: number; excerpt: string } };
let draft: LinkDraft | null = null;
let lastSel: { pane: "a" | "b"; start: number; end: number } | null = null;

document.addEventListener("selectionchange", () => {
  const sel = window.getSelection();
  if (!sel || sel.isCollapsed || !paneA) return;
  const inA = selectionIn(paneA, "scroll-a");
  if (inA) {
    lastSel = { pane: "a", ...inA };
    return;
  }
  if (paneB) {
    const inB = selectionIn(paneB, "scroll-b");
    if (inB) lastSel = { pane: "b", ...inB };
  }
});

/** Map the current DOM selection inside a pane's <pre> to character
 *  offsets in that pane's work text. */
function selectionIn(pane: Pane, scrollId: string): { start: number; end: number } | null {
  const sel = window.getSelection();
  const pre = document.querySelector(`#${scrollId} pre`);
  if (!sel || sel.isCollapsed || !pre || !sel.anchorNode || !pre.contains(sel.anchorNode)) return null;
  const range = sel.getRangeAt(0);
  if (!pre.contains(range.startContainer) || !pre.contains(range.endContainer)) return null;
  const walker = document.createTreeWalker(pre, NodeFilter.SHOW_TEXT);
  let pos = 0;
  let start = -1;
  let end = -1;
  while (walker.nextNode()) {
    const node = walker.currentNode as Text;
    if (node === range.startContainer) start = pos + range.startOffset;
    if (node === range.endContainer) end = pos + range.endOffset;
    pos += node.length;
  }
  if (start < 0 || end < 0) return null;
  if (start > end) [start, end] = [end, start];
  if (start === end || end > pane.text.length) return null;
  return { start, end };
}

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
  const tools: string[] = [];
  if (tag === "a" && !isEditing) {
    tools.push(`<button class="close-pane" id="link-start" title="connect this selection">⧉</button>`);
    tools.push(`<button class="close-pane" data-revise-pane="a" title="revise this work">✎</button>`);
  }
  if (tag === "b" && !isEditing) {
    if (draft && draft.stage === "origin") {
      tools.push(`<button class="close-pane" id="link-far" title="use this selection (or the whole work) as the far end">⤳</button>`);
    } else {
      tools.push(`<button class="close-pane" data-revise-pane="b" title="revise this work">✎</button>`);
    }
  }
  if (closable) tools.push(`<button class="close-pane" id="close-pane">×</button>`);
  const headBtns = tools.join("");
  const body = isEditing
    ? `<textarea id="revise-text" class="revise" spellcheck="false">${esc(p.text)}</textarea>`
    : `<pre class="prose">${renderText(p)}</pre>`;
  const bar = isEditing
    ? `<div class="revise-bar"><button id="revise-save" class="revise-btn">save</button><button id="revise-cancel" class="revise-btn ghosted">cancel</button><span class="quiet small">grabbed — ⌘↵ saves · esc cancels · → at the edge jumps columns</span></div>`
    : "";
  const focused = !isEditing && focusPane === tag ? " focused" : "";
  return `<section class="pane${focused}" id="pane-${tag}">
    <div class="pane-head"><h2>${esc(p.title)}</h2>${headBtns}</div>
    <div class="pane-scroll pane-editing-${isEditing ? "on" : "off"}" id="scroll-${tag}">${body}</div>
    ${bar}
    ${isEditing ? "" : `<div class="pane-conns"><h3>connections</h3>${connectionsHtml(p)}</div>`}
  </section>`;
}

function typePanelHtml(): string {
  const d = draft as Extract<LinkDraft, { stage: "far" }>;
  const btns = Object.entries(LINK_TYPE_NAMES)
    .map(([id, t]) => `<button class="type-pick" data-type="${id}" style="border-color:${t.color};color:${t.color}">${esc(t.name)}</button>`)
    .join("");
  return `<div class="type-panel" id="type-panel">
    <h3>connect · ${esc(d.farTitle.slice(0, 44))}</h3>
    <div class="type-row">${btns}</div>
    <button id="link-cancel" class="revise-btn ghosted">cancel</button>
  </div>`;
}

function beginLinkFromSelection(): void {
  if (!paneA) return;
  const live = selectionIn(paneA, "scroll-a");
  const s = live ?? (lastSel?.pane === "a" ? { start: lastSel.start, end: lastSel.end } : null);
  if (!s) {
    setStatus("select a passage in the left column first");
    return;
  }
  draft = { stage: "origin", start: s.start, end: s.end, excerpt: paneA.text.slice(s.start, s.end) };
  setStatus(paneB ? "origin held — select in the right column and press ⤳, or click any work" : "origin held — click a work for the far end");
  render();
}

function farFromPaneB(): void {
  if (!draft || draft.stage !== "origin" || !paneB) return;
  const live = selectionIn(paneB, "scroll-b");
  const s = live ?? (lastSel?.pane === "b" ? { start: lastSel.start, end: lastSel.end } : null);
  draft = {
    stage: "far",
    start: draft.start,
    end: draft.end,
    excerpt: draft.excerpt,
    farWork: paneB.workId,
    farTitle: paneB.title,
    farRef: s ? { start: s.start, end: s.end, excerpt: paneB.text.slice(s.start, s.end) } : undefined,
  };
  setStatus("choose the kind of connection");
  render();
}

function chooseFarWork(workId: number, title: string): void {
  if (!draft || draft.stage !== "origin") return;
  draft = { stage: "far", start: draft.start, end: draft.end, excerpt: draft.excerpt, farWork: workId, farTitle: title };
  setStatus("choose the kind of connection");
  render();
}

async function commitDraft(type: number): Promise<void> {
  if (!client || !paneA || !draft || draft.stage !== "far") return;
  const d = draft;
  draft = null;
  try {
    await client.createLink({
      origin: paneA.workId,
      destination: d.farWork,
      originRef: { excerpt: d.excerpt, start: d.start, end: d.end },
      destinationRef: d.farRef,
      linkTypes: [type],
    });
  } catch (e) {
    setStatus((e as Error).message);
    render();
    return;
  }
  setStatus("connection made");
  paneA = { ...paneA, links: await client.linksFor(paneA.workId) };
  if (d.farRef && paneB && paneB.workId === d.farWork) {
    paneB = { ...paneB, links: await client.linksFor(d.farWork) };
    render();
  } else {
    await openWork(d.farWork, "B");
  }
}

function cancelDraft(): void {
  draft = null;
  setStatus("");
  render();
}

function render(): void {
  document.body.classList.toggle("paper", skin === "paper");
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
        ${paneB ? paneHtml(paneB, "b", true, !!editing && editing.pane === "b" && editing.workId === paneB.workId) : `<section class="pane ghost" id="pane-b"><div class="pane-head"><h2 class="quiet">—</h2></div><div class="pane-scroll"><p class="quiet">Click an underline or a connection to open its far end here, joined by a beam.</p></div></section>`}
        <svg id="beams"></svg>
        ${draft && draft.stage === "far" ? typePanelHtml() : ""}
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
          <button id="skin-toggle" title="switch skin — ink or the mockup paper look">${skin === "paper" ? "paper" : "ink"}</button>
        </span>
        ${paneA ? `<a class="head-link" href="/workspace?work=0x${paneA.workId.toString(16)}" title="open this work in the workspace">workspace ↗</a>` : ""}
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
  wireLinkDraft();
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
  document.getElementById("skin-toggle")!.onclick = () => {
    skin = skin === "paper" ? "ink" : "paper";
    localStorage.setItem("xudanu_classic_skin", skin);
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

function wireLinkDraft(): void {
  document.getElementById("link-start")?.addEventListener("click", beginLinkFromSelection);
  document.getElementById("link-far")?.addEventListener("click", farFromPaneB);
  document.getElementById("link-cancel")?.addEventListener("click", cancelDraft);
  document.querySelectorAll<HTMLButtonElement>("button.type-pick").forEach((b) => {
    b.onclick = () => void commitDraft(Number(b.dataset.type));
  });
}

function wireHistoryButtons(): void {
  document.getElementById("hist-back")?.addEventListener("click", () => history.back());
  document.getElementById("hist-fwd")?.addEventListener("click", () => history.forward());
}

async function startEditing(pane: "a" | "b" = "a"): Promise<void> {
  if (!client || editing) return;
  if (mode === "windows" && pane !== "a") return;
  const target = pane === "a" ? paneA : paneB;
  if (!target) return;
  setStatus("grabbing…");
  const ed = new GrabReviseEditor(client);
  try {
    await ed.begin(target.workId);
  } catch (e) {
    const we = e as WireError;
    if (we.code === "not_grabbed" || /not grabbed|is locked/i.test(we.message ?? "")) {
      setStatus("held by another session — try again shortly");
    } else {
      setStatus(we.message ?? String(e));
    }
    return;
  }
  editor = ed;
  editing = { workId: target.workId, pane: mode === "windows" ? "a" : pane };
  if (mode === "windows" && winView) {
    winView.setEditing(paneA!.text);
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
  const { workId, pane } = editing;
  editor = null;
  editing = null;
  if (mode === "windows" && winView) {
    await winView.refreshCenter();
    winView.setEditing(null);
  } else if (pane === "b" && paneB) {
    const text = await client.readWork(workId);
    const links = await client.linksFor(workId);
    paneB = { workId, title: firstLine(text, workId), text, links };
    render();
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
  document.querySelectorAll<HTMLButtonElement>("[data-revise-pane]").forEach((b) => {
    b.addEventListener("click", () => void startEditing(b.dataset.revisePane === "b" ? "b" : "a"));
  });
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
      } else if (
        e.key === "ArrowRight" && !e.shiftKey &&
        ta.selectionStart === ta.value.length && ta.selectionEnd === ta.value.length
      ) {
        if (editing?.pane === "a" && paneB) {
          e.preventDefault();
          void (async () => {
            await commitEditing();
            await startEditing("b");
          })();
        }
      } else if (
        e.key === "ArrowLeft" && !e.shiftKey &&
        ta.selectionStart === 0 && ta.selectionEnd === 0
      ) {
        if (editing?.pane === "b") {
          e.preventDefault();
          void (async () => {
            await commitEditing();
            await startEditing("a");
          })();
        }
      }
    });
    ta.focus();
    ta.setSelectionRange(ta.value.length, ta.value.length);
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
          const wid = Number(a.dataset.work);
          if (draft && draft.stage === "origin") {
            chooseFarWork(wid, a.textContent?.trim() ?? `work ${wid}`);
            return;
          }
          void openWork(wid, "A");
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
      const wid = Number(a.dataset.work);
      if (draft && draft.stage === "origin") {
        chooseFarWork(wid, a.textContent?.trim() ?? `work ${wid}`);
        return;
      }
      void openWork(wid, "A");
    };
  });
}

function wireMainWorkLinks(): void {
  document.querySelectorAll<HTMLAnchorElement>("main a[data-work]").forEach((a) => {
    a.onclick = (ev) => {
      ev.preventDefault();
      const wid = Number(a.dataset.work);
      if (draft && draft.stage === "origin") {
        chooseFarWork(wid, a.textContent?.trim() ?? `work ${wid}`);
        return;
      }
      void openWork(wid, "A");
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

/** Every link that touches both open works — the Pyxi view: all
 *  connections drawn at once, passage to passage. */
function sharedLinks(): LinkEntryClassic[] {
  if (!paneA || !paneB) return [];
  const inB = new Set(paneB.links.map((l) => l.link_id));
  return paneA.links.filter((l) => inB.has(l.link_id));
}

function drawBeams(): void {
  const svg = document.getElementById("beams") as SVGSVGElement | null;
  if (!svg || !paneA || !paneB) {
    if (svg) svg.innerHTML = "";
    return;
  }
  const panes = document.getElementById("panes");
  if (!panes) return;
  const svgR = panes.getBoundingClientRect();
  svg.setAttribute("width", String(svgR.width));
  svg.setAttribute("height", String(svgR.height));

  const paper = document.body.classList.contains("paper");
  const ink = "#1d1a15";
  const lastLine = (el: HTMLElement): DOMRect => {
    const lines = el.getClientRects();
    return lines.length > 0 ? lines[lines.length - 1] : el.getBoundingClientRect();
  };
  const firstLine = (el: HTMLElement): DOMRect => {
    const lines = el.getClientRects();
    return lines.length > 0 ? lines[0] : el.getBoundingClientRect();
  };

  let paths = "";
  for (const l of sharedLinks()) {
    const markA = document.querySelector<HTMLElement>(`#scroll-a mark[data-link~="${l.link_id}"]`);
    const markB = document.querySelector<HTMLElement>(`#scroll-b mark[data-link~="${l.link_id}"]`);
    if (!markA && !markB) continue;
    const headA = document.querySelector<HTMLElement>("#pane-a .pane-head");
    const headB = document.querySelector<HTMLElement>("#pane-b .pane-head");
    if (!headA || !headB) continue;
    const ra = markA ? lastLine(markA) : headA.getBoundingClientRect();
    const rb = markB ? firstLine(markB) : headB.getBoundingClientRect();
    const x1 = ra.right - svgR.left;
    const y1 = ra.bottom - 1 - svgR.top;
    const x2 = rb.left - svgR.left;
    const y2 = rb.bottom - 1 - svgR.top;
    const active = activeLink?.link_id === l.link_id;
    const t = typeOf(l);
    if (paper) {
      paths += `<path d="M ${x1.toFixed(1)} ${y1.toFixed(1)} L ${x2.toFixed(1)} ${y2.toFixed(1)}"
        fill="none" stroke="${ink}" stroke-width="${active ? 1.2 : 0.8}" opacity="${active ? 0.95 : 0.6}"/>`;
    } else {
      const mid = (x1 + x2) / 2;
      paths += `<path d="M ${x1} ${y1} C ${mid} ${y1}, ${mid} ${y2}, ${x2} ${y2}"
        fill="none" stroke="${t.color}" stroke-width="${active ? 1.6 : 1.1}" stroke-dasharray="5 4" opacity="${active ? 0.85 : 0.4}">${active ? '<animate attributeName="stroke-dashoffset" from="18" to="0" dur="1.2s" repeatCount="indefinite"/>' : ""}</path>`;
    }
  }
  svg.innerHTML = paths;
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

window.addEventListener("keydown", (e) => {
  const inField = (document.activeElement as HTMLElement | null)?.closest?.("input, textarea");
  if (e.key === "Escape" && draft && !editing) {
    cancelDraft();
    return;
  }
  if (inField || editing || draft || !client || !paneA || mode !== "panes") return;
  const sel = window.getSelection();
  if (sel && !sel.isCollapsed) return;
  if (e.key === "ArrowRight" && paneB) {
    focusPane = "b";
    render();
  } else if (e.key === "ArrowLeft") {
    focusPane = "a";
    render();
  } else if (e.key === "Enter") {
    e.preventDefault();
    void startEditing(focusPane);
  }
});

render();
