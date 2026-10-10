import {
  ClassicClient,
  LINK_TYPE_NAMES,
  WireError,
  type AttributionSpan,
  type InlineTransclusions,
  type LinkEntryClassic,
  type TrailEntry,
} from "./client";
import { CrdtEditor, type WorkEditor } from "./editor";
import { WindowsView } from "./windows";

const app = document.getElementById("app")!;
let client: ClassicClient | null = null;
let mode: "panes" | "windows" = localStorage.getItem("xudanu_classic_mode") === "windows" ? "windows" : "panes";
let skin: "ink" | "paper" = localStorage.getItem("xudanu_classic_skin") === "paper" ? "paper" : "ink";
let winView: WindowsView | null = null;
let focusPane: Col = "a";
let editor: WorkEditor | null = null;
let editing: { workId: number; pane: Col } | null = null;
let statusTimer: number | null = null;

type LinkDraft =
  | { stage: "origin"; from: Col; start: number; end: number; excerpt: string }
  | { stage: "far"; from: Col; start: number; end: number; excerpt: string; farWork: number; farTitle: string; farRef?: { start: number; end: number; excerpt: string } };
let draft: LinkDraft | null = null;
let lastSel: { pane: Col; start: number; end: number } | null = null;

document.addEventListener("selectionchange", () => {
  const sel = window.getSelection();
  if (!sel || sel.isCollapsed) return;
  for (const tag of COLS) {
    const pane = paneAt(tag);
    if (!pane) continue;
    const hit = selectionIn(pane, `scroll-${tag}`);
    if (hit) {
      lastSel = { pane: tag, ...hit };
      return;
    }
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
  inline?: InlineTransclusions;
  attribution?: AttributionSpan[];
}

async function fetchPane(client: ClassicClient, workId: number): Promise<Pane> {
  const [raw, links, inline, attribution] = await Promise.all([
    client.readWork(workId),
    client.linksFor(workId),
    client.resolveInline(workId).catch((): InlineTransclusions => ({ text: "", spanRanges: [], sourceTitles: {} })),
    client.attribution(workId).catch((): AttributionSpan[] => []),
  ]);
  // A transcluding work displays its RESOLVED text: the reader sees the
  // live window's content inline (Nelson's window, not a placeholder),
  // with identity boxes over the shared ranges.
  const text = inline.spanRanges.length > 0 && inline.text ? inline.text : raw;
  return { workId, title: firstLine(text, workId), text, links, inline, attribution };
}

let paneA: Pane | null = null;
let paneB: Pane | null = null;
let paneC: Pane | null = null;
const COLS = ["a", "b", "c"] as const;
type Col = (typeof COLS)[number];

function paneAt(tag: Col): Pane | null {
  return tag === "a" ? paneA : tag === "b" ? paneB : paneC;
}
function setPane(tag: Col, p: Pane | null): void {
  if (tag === "a") paneA = p;
  else if (tag === "b") paneB = p;
  else paneC = p;
}
let activeLink: LinkEntryClassic | null = null;
let inspectLink: number | null = null;

function beamPanelHtml(): string {
  const id = inspectLink;
  const l = [paneA, paneB, paneC].flatMap((p) => (p ? p.links : [])).find((x) => x.link_id === id);
  if (!l) return "";
  const t = typeOf(l);
  const oex = l.origin_ref?.excerpt?.trim();
  const dex = l.destination_ref?.excerpt?.trim();
  return `<div class="beam-panel" id="beam-panel">
    <div class="bp-type" style="color:${t.color}">${esc(t.name)} · link ${l.link_id}</div>
    <div class="bp-row"><strong>${esc(l.origin_title ?? `work ${l.origin}`)}</strong>${oex ? `<div class="bp-excerpt">“${esc(oex.slice(0, 90))}”</div>` : ""}</div>
    <div class="bp-row"><strong>${esc(l.destination_title ?? `work ${l.destination}`)}</strong>${dex ? `<div class="bp-excerpt">“${esc(dex.slice(0, 90))}”</div>` : ""}</div>
    <button id="beam-close" class="revise-btn ghosted" style="margin-top:8px">close</button>
  </div>`;
}

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
  ordinal?: { i: number; n: number };
}

function marksFor(pane: Pane): Mark[] {
  const out: Mark[] = [];
  for (const l of pane.links) {
    // Gathered ends: when the local end carries an end-set with
    // several passages, every member on this work is a mark with its
    // ordinal ("passage i of N") — the singletons are member 1 and
    // must not double-emit.
    const localEnd = l.origin === pane.workId ? "LeftEnd" : "RightEnd";
    const members = (l.end_sets ?? []).find(([name, refs]) => name === localEnd && refs.length > 1)?.[1];
    if (members) {
      members.forEach((m, i) => {
        if (m.work_context === pane.workId && m.start_position !== undefined) {
          out.push({ start: m.start_position, end: m.end_position ?? m.start_position, link: l, ordinal: { i: i + 1, n: members.length } });
        }
      });
      continue;
    }
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
    const ord = m.ordinal ? ` (gathered passage ${m.ordinal.i} of ${m.ordinal.n})` : "";
    html += `<mark data-link="${m.link.link_id}" style="border-bottom:2px solid ${t.color};background:${t.color}18;cursor:pointer" title="${esc(t.name)}${esc(ord)} → ${esc(farTitle(m.link, pane.workId))}">${esc(pane.text.slice(m.start, Math.min(m.end, pane.text.length)))}</mark>`;
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
  const p = await fetchPane(client, workId);
  if (pane === "A") {
    paneA = p;
    paneB = null;
    paneC = null;
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
    tools.push(`<button class="close-pane" id="link-start" data-link-pane="a" title="connect this selection">⧉</button>`);
    tools.push(`<button class="close-pane" data-revise-pane="a" title="revise this work">✎</button>`);
  }
  if (tag !== "a" && !isEditing) {
    tools.push(`<button class="close-pane" data-link-pane="${tag}" title="connect this selection">⧉</button>`);
  }
  if (tag !== "a" && !isEditing) {
    if (draft && draft.stage === "origin") {
      tools.push(`<button class="close-pane" id="link-far" title="use this selection (or the whole work) as the far end">⤳</button>`);
    } else {
      tools.push(`<button class="close-pane" data-revise-pane="b" title="revise this work">✎</button>`);
    }
  }
  if (closable) tools.push(`<button class="close-pane" data-close-pane="${tag}">×</button>`);
  const headBtns = tools.join("");
  const body = isEditing
    ? `<textarea id="revise-text" class="revise" spellcheck="false">${esc(p.text)}</textarea>`
    : `<pre class="prose">${renderText(p)}</pre>`;
  const bar = isEditing
    ? `<div class="revise-bar"><button id="revise-save" class="revise-btn">save</button><button id="revise-cancel" class="revise-btn ghosted">cancel</button><span class="quiet small">editing — ⌘↵ saves · esc cancels · → at the edge jumps columns</span></div>`
    : "";
  const focused = !isEditing && focusPane === tag ? " focused" : "";
  return `<section class="pane${focused}" id="pane-${tag}">
    <div class="pane-head"><h2>${esc(p.title)}</h2>${headBtns}</div>
    <div class="searchhl-layer" id="searchhl-${tag}"></div>
    <div class="tboxes" id="tboxes-${tag}"></div>
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

interface GatherableEnd {
  linkId: number;
  endName: string;
  label: string;
  count: number;
  color: string;
}

/** Ends of existing links on the left work that this work's side
 *  can absorb another passage into (any end with members). */
function gatherableEnds(): GatherableEnd[] {
  const originPane = draft && draft.stage === "origin" ? paneAt(draft.from) : paneA;
  if (!originPane) return [];
  const origin = originPane;
  const out: GatherableEnd[] = [];
  const seen = new Set<string>();
  for (const l of origin.links) {
    const localEnd = l.origin === origin.workId ? "LeftEnd" : "RightEnd";
    if (l.origin !== origin.workId && l.destination !== origin.workId) continue;
    const key = `${l.link_id}:${localEnd}`;
    if (seen.has(key)) continue;
    const members = (l.end_sets ?? []).find(([n]: [string, unknown]) => n === localEnd)?.[1]
      ?? (l.origin === origin.workId
        ? (l.origin_ref ? [l.origin_ref] : [])
        : (l.destination_ref ? [l.destination_ref] : []));
    if (!members || members.length === 0) continue;
    seen.add(key);
    const mine = members.find((m: { work_context?: number }) => m.work_context === origin.workId) ?? members[0];
    out.push({
      linkId: l.link_id,
      endName: localEnd,
      label: (mine?.excerpt || farTitle(l, origin.workId) || `link ${l.link_id}`).slice(0, 40),
      count: members.length,
      color: typeOf(l).color,
    });
  }
  return out;
}

function gatherPanelHtml(): string {
  const ends = gatherableEnds();
  if (ends.length === 0) return "";
  const chips = ends
    .map((e) => `<button class="type-pick gather-pick" data-gather-link="${e.linkId}" data-gather-end="${e.endName}" style="border-color:${e.color};color:${e.color}">+ ${esc(e.label)} <span class="quiet">(${e.count})</span></button>`)
    .join("");
  return `<div class="type-panel" id="gather-panel">
    <h3>or gather this passage into an existing end</h3>
    <div class="type-row">${chips}</div>
  </div>`;
}

async function gatherDraftSelection(linkId: number, endName: string): Promise<void> {
  if (!client || !draft || draft.stage !== "origin") return;
  const d = draft;
  const originPane = paneAt(d.from);
  if (!originPane) return;
  draft = null;
  try {
    await client.gatherInto(linkId, endName, {
      workContext: originPane.workId,
      excerpt: d.excerpt,
      start: d.start,
      end: d.end,
    });
  } catch (e) {
    setStatus((e as Error).message);
    render();
    return;
  }
  setPane(d.from, { ...originPane, links: await client.linksFor(originPane.workId) });
  render();
  setStatus("gathered — the passage joined the end");
}

function beginLinkFromSelection(from: Col = "a"): void {
  const pane = paneAt(from);
  if (!pane) return;
  const live = selectionIn(pane, `scroll-${from}`);
  const s = live ?? (lastSel?.pane === from ? { start: lastSel.start, end: lastSel.end } : null);
  if (!s) {
    setStatus("select a passage in this column first");
    return;
  }
  draft = { stage: "origin", from, start: s.start, end: s.end, excerpt: pane.text.slice(s.start, s.end) };
  render();
  setStatus("origin held — select a passage in another column and press ⤳, or click any work");
}

function farFromPaneB(): void {
  if (!draft || draft.stage !== "origin") return;
  const tags: Col[] = ["b", "c"];
  let s: { start: number; end: number } | null = null;
  let farPane: Pane | null = null;
  for (const tag of tags) {
    const pane = paneAt(tag);
    if (!pane) continue;
    const live = selectionIn(pane, `scroll-${tag}`);
    const hit = live ?? (lastSel?.pane === tag ? { start: lastSel.start, end: lastSel.end } : null);
    if (hit) {
      s = hit;
      farPane = pane;
      break;
    }
  }
  if (!farPane || !s) return;
  const paneB = farPane;
  draft = {
    stage: "far",
    from: draft.from,
    start: draft.start,
    end: draft.end,
    excerpt: draft.excerpt,
    farWork: paneB.workId,
    farTitle: paneB.title,
    farRef: s ? { start: s.start, end: s.end, excerpt: paneB.text.slice(s.start, s.end) } : undefined,
  };
  render();
  setStatus("choose the kind of connection");
}

function chooseFarWork(workId: number, title: string): void {
  if (!draft || draft.stage !== "origin") return;
  draft = { stage: "far", from: draft.from, start: draft.start, end: draft.end, excerpt: draft.excerpt, farWork: workId, farTitle: title };
  render();
  setStatus("choose the kind of connection");
}

async function commitDraft(type: number): Promise<void> {
  if (!client || !draft || draft.stage !== "far") return;
  const d = draft;
  const originPane = paneAt(d.from);
  if (!originPane) return;
  draft = null;
  try {
    await client.createLink({
      origin: originPane.workId,
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
  setPane(d.from, { ...originPane, links: await client.linksFor(originPane.workId) });
  if (d.farRef && paneB && paneB.workId === d.farWork) {
    paneB = { ...paneB, links: await client.linksFor(d.farWork) };
    render();
  } else {
    await openWork(d.farWork, "B");
  }
  setStatus("connection made");
}

function cancelDraft(): void {
  draft = null;
  render();
  setStatus("");
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
    document.getElementById("connect")!.onclick = () => void connect();
    return;
  }

  const openTrail = openTrailId !== null ? trailCache.find((t) => t.trail_id === openTrailId) : undefined;
  const windowsMode = mode === "windows" && !!paneA;
  const main = windowsMode
    ? `<div id="stage" class="stage"></div>`
    : paneA
    ? `<div class="panes" id="panes" style="grid-template-columns:repeat(3,1fr)">
        ${paneHtml(paneA!, "a", false, !!editing && editing.workId === paneA!.workId)}
        ${paneB ? paneHtml(paneB, "b", true, !!editing && editing.pane === "b" && editing.workId === paneB.workId) : `<section class="pane ghost" id="pane-b"><div class="pane-head"><h2 class="quiet">—</h2></div><div class="pane-scroll"><p class="quiet">Click an underline to open its far end here.</p></div></section>`}
        ${paneC ? paneHtml(paneC, "c", true, !!editing && editing.pane === "c" && editing.workId === paneC.workId) : `<section class="pane ghost" id="pane-c"><div class="pane-head"><h2 class="quiet">—</h2></div><div class="pane-scroll"><p class="quiet">Follow another connection and a third page opens here — the parallel-pages posture.</p></div></section>`}
        <svg id="beams"></svg>
        ${inspectLink !== null ? beamPanelHtml() : ""}
        ${draft && draft.stage === "origin" ? gatherPanelHtml() : ""}
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
          <button id="new-work" title="create a new work in the docuverse">+</button>
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
  document.getElementById("new-work")!.onclick = () => void createAndEdit();
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
  wireBeams();
  wireAllLenses();
  observeBeams();
  drawAllTBoxes();
  drawAllSearchHl();
}
}

function wireLinkDraft(): void {
  document.querySelectorAll<HTMLButtonElement>("[data-link-pane]").forEach((b) => {
    b.addEventListener("click", () => beginLinkFromSelection((b.dataset.linkPane ?? "a") as Col));
  });
  document.getElementById("link-far")?.addEventListener("click", farFromPaneB);
  document.getElementById("link-cancel")?.addEventListener("click", cancelDraft);
  document.querySelectorAll<HTMLButtonElement>("button.type-pick").forEach((b) => {
    b.onclick = () => void commitDraft(Number(b.dataset.type));
  });
  document.querySelectorAll<HTMLButtonElement>(".gather-pick").forEach((b) => {
    b.onclick = () => void gatherDraftSelection(Number(b.dataset.gatherLink), b.dataset.gatherEnd ?? "LeftEnd");
  });
}

function wireHistoryButtons(): void {
  document.getElementById("hist-back")?.addEventListener("click", () => history.back());
  document.getElementById("hist-fwd")?.addEventListener("click", () => history.forward());
}

async function createAndEdit(): Promise<void> {
  if (!client) return;
  if (mode !== "panes") {
    mode = "panes";
    localStorage.setItem("xudanu_classic_mode", mode);
  }
  setStatus("creating…");
  let workId: number;
  try {
    workId = await client.createWork("");
  } catch (e) {
    setStatus((e as Error).message);
    return;
  }
  // Born editing: the new work opens straight into the revise surface —
  // type, ⌘↵, and it exists in the shared docuverse with its title
  // derived from the first line.
  await openWork(workId, "A");
  await startEditing("a");
  setStatus("new work — write, ⌘↵ saves");
}

async function startEditing(pane: Col = "a"): Promise<void> {
  if (!client || editing) return;
  if (mode === "windows" && pane !== "a") return;
  const target = paneAt(pane);
  if (!target) return;
  setStatus("opening…");
  const ed = new CrdtEditor(client);
  try {
    await ed.begin(target.workId);
  } catch (e) {
    const we = e as WireError;
    if (we.code === "not_grabbed" || /not grabbed|is locked/i.test(we.message ?? "")) {
      setStatus("another session is editing this work — try again shortly");
    } else {
      setStatus(we.message ?? String(e));
    }
    return;
  }
  editor = ed;
  editing = { workId: target.workId, pane: mode === "windows" ? "a" : pane };
  if (mode === "windows" && winView) {
    winView.setEditing(paneA!.text);
    setStatus("editing — ⌘↵ saves · esc cancels");
  } else {
    render();
    setStatus("editing — ⌘↵ saves · esc cancels");
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
  } else if (pane !== "a" && paneAt(pane)) {
    setPane(pane, await fetchPane(client, workId));
    render();
  } else {
    paneA = await fetchPane(client, workId);
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

let searchQuery = "";

/** Connect (and reconnect): the socket can drop under us — a server
 *  restart, a laptop waking. Instead of every request timing out, we
 *  reconnect, restore the session, and re-render; an in-progress edit
 *  is abandoned (its grab died with the socket — the server released
 *  it on disconnect). */
async function connect(): Promise<void> {
  const gate = document.getElementById("gate-status");
  if (gate) gate.textContent = "connecting…";
  const c = new ClassicClient();
  c.onDrop = () => {
    setStatus("connection dropped — reconnecting…");
    void (async () => {
      for (let attempt = 0; attempt < 5; attempt++) {
        await new Promise((r) => setTimeout(r, 1000 + attempt * 1000));
        try {
          await connect();
          if (paneA) await openWork(paneA.workId, "A", false);
          setStatus("reconnected");
          return;
        } catch {
          /* retry */
        }
      }
      setStatus("connection lost — reload the page");
    })();
  };
  try {
    await c.connect();
  } catch (e) {
    if (gate) gate.textContent = String(e instanceof Error ? e.message : e);
    return;
  }
  client = c;
  if (editing) {
    editor = null;
    editing = null;
  }
  draft = null;
  render();
  const wm = /^#w(\d+)$/.exec(location.hash);
  if (wm) void openWork(Number(wm[1]), "A", false);
}

function wireSearch(): void {
  document.getElementById("search")!.onsubmit = async (ev) => {
    ev.preventDefault();
    const q = (document.getElementById("q") as HTMLInputElement).value.trim();
    if (!q || !client) return;
    searchQuery = q;
    try {
      const entries = await client.search(q);
      document.getElementById("results")!.innerHTML =
        entries.length === 0
          ? `<p class="quiet small">nothing found</p>`
          : entries
              .map((e) => {
                const ctx = e.matches?.[0]?.context;
                return `<a href="#" data-work="${e.work_id}">${esc(e.title || `work ${e.work_id}`)}${ctx ? `<span class="quiet small" style="display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">…${esc(ctx)}…</span>` : ""}</a>`;
              })
              .join("");
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
          `<a href="#" data-trail="${t.trail_id}"${open ? ` class="open"` : ""}>${open ? "&#9662; " : "&#9656; "}${esc(t.name)}</a>` +
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
}

/** Trails clicks are delegated at the document level: re-renders swap
 *  the sidebar's innerHTML wholesale, and per-anchor handlers bound in
 *  that window could vanish mid-click (a silently swallowed click). */
document.addEventListener("click", (ev) => {
  const a = (ev.target as HTMLElement).closest?.("a");
  if (!a) return;
  const trail = a.dataset.trail;
  const work = a.dataset.work;
  if (trail !== undefined) {
    ev.preventDefault();
    const tid = Number(trail);
    const opening = openTrailId !== tid;
    openTrailId = opening ? tid : null;
    if (opening && !paneA) history.pushState({ t: tid }, "", `#t${tid}`);
    if (paneA) renderTrailsNav();
    else render();
    return;
  }
  if (work !== undefined && a.closest("#trails")) {
    ev.preventDefault();
    const wid = Number(work);
    if (draft && draft.stage === "origin") {
      chooseFarWork(wid, a.textContent?.trim() ?? `work ${wid}`);
      return;
    }
    void openWork(wid, "A");
  }
});

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

async function follow(linkId: number, from: Col = "a"): Promise<void> {
  if (!client) return;
  const src = paneAt(from);
  if (!src) return;
  const l = src.links.find((x) => x.link_id === linkId);
  if (!l) return;
  const far = farId(l, src.workId);
  if (far === null) return;
  activeLink = l;
  const have = [paneA, paneB, paneC].some((q) => q?.workId === far);
  if (!have) {
    const p = await fetchPane(client, far);
    // The '72 gesture: following a connection ADDS a page — the
    // empty column fills before any column is replaced; at the cap
    // the third gives way.
    if (!paneB) paneB = p;
    else if (!paneC && mode === "panes") paneC = p;
    else paneB = p;
  }
  render();
}

function wireBeams(): void {
  const svg = document.getElementById("beams");
  svg?.addEventListener("click", (ev) => {
    const hit = (ev.target as SVGElement).closest?.("path[data-link]") as SVGPathElement | null;
    if (!hit) return;
    const id = Number(hit.dataset.link);
    const l = [paneA, paneB, paneC].flatMap((p) => (p ? p.links : [])).find((x) => x.link_id === id) ?? null;
    inspectLink = l ? id : null;
    activeLink = l;
    render();
  });
  document.getElementById("beam-close")?.addEventListener("click", () => {
    inspectLink = null;
    render();
  });
}

function wireClose(): void {
  document.querySelectorAll<HTMLButtonElement>("[data-close-pane]").forEach((b) => {
    b.addEventListener("click", () => {
      setPane((b.dataset.closePane ?? "b") as Col, null);
      activeLink = null;
      render();
    });
  });
}

function onHashNav(): void {
  if (!client) return;
  const wm = /^#w(\d+)$/.exec(location.hash);
  const tm = /^#t(\d+)$/.exec(location.hash);
  if (wm) {
    void openWork(Number(wm[1]), "A", false);
  } else {
    // Trail or home entries: leave the reading surface — back must
    // close the panes, not just re-render the sidebar. An active edit
    // is canceled (with release) exactly as any other navigation does.
    if (editing) {
      void editor?.cancel(editing.workId).finally(() => render());
      editor = null;
      editing = null;
    }
    openTrailId = tm ? Number(tm[1]) : null;
    paneA = null;
    paneB = null;
    paneC = null;
    activeLink = null;
    render();
  }
}

window.onpopstate = onHashNav;
window.addEventListener("hashchange", onHashNav);

/** Every link shared between two columns — the Pyxi view: all
 *  connections drawn at once, passage to passage, across every
 *  pair of open pages. */
function sharedLinksBetween(x: Col, y: Col): LinkEntryClassic[] {
  const px = paneAt(x);
  const py = paneAt(y);
  if (!px || !py) return [];
  const inY = new Set(py.links.map((l) => l.link_id));
  return px.links.filter((l) => inY.has(l.link_id));
}

const COLUMN_PAIRS: Array<[Col, Col]> = [
  ["a", "b"],
  ["a", "c"],
  ["b", "c"],
];

function drawBeams(): void {
  const svg = document.getElementById("beams") as SVGSVGElement | null;
  const panes = document.getElementById("panes");
  if (!svg || !panes) return;
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
  // Every pair of open pages: connections drawn across all of them —
  // the 1972 figure's criss-crossing lines between parallel pages.
  for (const [x, y] of COLUMN_PAIRS) {
    for (const l of sharedLinksBetween(x, y)) {
      const markX = document.querySelector<HTMLElement>(`#scroll-${x} mark[data-link~="${l.link_id}"]`);
      const markY = document.querySelector<HTMLElement>(`#scroll-${y} mark[data-link~="${l.link_id}"]`);
      if (!markX && !markY) continue;
      const headX = document.querySelector<HTMLElement>(`#pane-${x} .pane-head`);
      const headY = document.querySelector<HTMLElement>(`#pane-${y} .pane-head`);
      if (!headX || !headY) continue;
      const rx = markX ? lastLine(markX) : headX.getBoundingClientRect();
      const ry = markY ? firstLine(markY) : headY.getBoundingClientRect();
      const x1 = rx.right - svgR.left;
      const y1 = rx.bottom - 1 - svgR.top;
      const x2 = ry.left - svgR.left;
      const y2 = ry.bottom - 1 - svgR.top;
      const active = activeLink?.link_id === l.link_id;
      const t = typeOf(l);
      const d = paper
        ? `M ${x1.toFixed(1)} ${y1.toFixed(1)} L ${x2.toFixed(1)} ${y2.toFixed(1)}`
        : `M ${x1} ${y1} C ${(x1 + x2) / 2} ${y1}, ${(x1 + x2) / 2} ${y2}, ${x2} ${y2}`;
      const stroke = paper ? ink : t.color;
      const width = active ? (paper ? 1.2 : 1.6) : paper ? 0.8 : 1.1;
      const opacity = active ? (paper ? 0.95 : 0.85) : paper ? 0.6 : 0.4;
      paths += `<path d="${d}" fill="none" stroke="${stroke}" stroke-width="${width}"${paper ? "" : ' stroke-dasharray="5 4"'} opacity="${opacity}">${!paper && active ? '<animate attributeName="stroke-dashoffset" from="18" to="0" dur="1.2s" repeatCount="indefinite"/>' : ""}</path>`;
      // Beam-as-object: an invisible wide twin makes the line itself
      // clickable (pointer-events: stroke on the hit path only).
      paths += `<path class="beam-hit" d="${d}" fill="none" stroke="#000" stroke-opacity="0" stroke-width="12" data-link="${l.link_id}"/>`;
    }
  }
  svg.innerHTML = paths;
}

let beamObserver: ResizeObserver | null = null;

/** Transclusion identity boxes — the Nelson mark: a passage that is
 *  the same content as a passage elsewhere gets a box (not an
 *  underline: underlines are links; boxes are identity). Drawn as an
 *  overlay so text segmentation never changes. */
function drawTBoxes(tag: Col): void {
  const pane = paneAt(tag);
  const layer = document.getElementById(`tboxes-${tag}`);
  const scroll = document.getElementById(`scroll-${tag}`);
  const pre = document.querySelector<HTMLElement>(`#scroll-${tag} pre`);
  if (!layer || !scroll || !pre || !pane?.inline || pane.inline.spanRanges.length === 0) {
    if (layer) layer.innerHTML = "";
    return;
  }
  const layerR = layer.getBoundingClientRect();
  const scrollR = scroll.getBoundingClientRect();
  const walker = document.createTreeWalker(pre, NodeFilter.SHOW_TEXT);
  const nodes: Text[] = [];
  while (walker.nextNode()) nodes.push(walker.currentNode as Text);
  let html = "";
  for (const sp of pane.inline.spanRanges) {
    const start = Math.max(0, Math.min(sp.flat_start ?? sp.char_start, pane.text.length));
    const end = Math.max(start, Math.min(sp.flat_end ?? sp.char_end, pane.text.length));
    if (end === start) continue;
    const range = document.createRange();
    let pos = 0;
    let anchored = false;
    for (const node of nodes) {
      if (!anchored && pos + node.length > start) {
        range.setStart(node, start - pos);
        anchored = true;
      }
      if (anchored && pos + node.length >= end) {
        range.setEnd(node, end - pos);
        break;
      }
      pos += node.length;
    }
    if (!range.collapsed) {
      const title = pane.inline.sourceTitles[String(sp.source_work_id)] ?? `work ${sp.source_work_id.toString(16)}`;
      for (const rect of range.getClientRects()) {
        const x = rect.left - layerR.left;
        const y = rect.top - layerR.top;
        html += `<div class="tbox" style="left:${x.toFixed(1)}px;top:${y.toFixed(1)}px;width:${rect.width.toFixed(1)}px;height:${rect.height.toFixed(1)}px" title="same content — live window onto: ${esc(title)}"><span class="tbox-tab">↩ ${esc(title.slice(0, 24))}</span></div>`;
      }
    }
  }
  void scrollR;
  layer.innerHTML = html;
}

function drawAllTBoxes(): void {
  drawTBoxes("a");
  drawTBoxes("b");
  drawTBoxes("c");
}

/** The lens: hover a passage and the margin answers "who wrote
 *  this?" — author name and cryptographic validity, fading in as
 *  marginalia. The resting page stays clean; disclosure on demand
 *  is the idiom. */
function wireLens(tag: Col): void {
  const scroll = document.getElementById(`scroll-${tag}`);
  const pane = paneAt(tag);
  if (!scroll || !pane?.attribution || pane.attribution.length === 0) return;

  let note: HTMLDivElement | null = null;
  let hideTimer: number | null = null;

  const removeNote = () => {
    if (note) {
      note.remove();
      note = null;
    }
  };

  scroll.addEventListener("mousemove", (ev: MouseEvent) => {
    if (hideTimer !== null) window.clearTimeout(hideTimer);
    hideTimer = window.setTimeout(removeNote, 1200);

    // caret position from mouse — the char offset under the cursor
    const caret = (document as Document & {
      caretRangeFromPoint?: (x: number, y: number) => Range | null;
      caretPositionFromPoint?: (x: number, y: number) => { offsetNode: Node; offset: number } | null;
    });
    let offset = -1;
    if (caret.caretRangeFromPoint) {
      const r = caret.caretRangeFromPoint(ev.clientX, ev.clientY);
      if (r && r.startContainer.nodeType === Node.TEXT_NODE) {
        const pre = scroll.querySelector("pre");
        if (pre) {
          const walker = document.createTreeWalker(pre, NodeFilter.SHOW_TEXT);
          let pos = 0;
          while (walker.nextNode()) {
            const node = walker.currentNode as Text;
            if (node === r.startContainer) {
              offset = pos + r.startOffset;
              break;
            }
            pos += node.length;
          }
        }
      }
    }
    if (offset < 0) return;

    // the most specific span containing this offset (smallest)
    let best: AttributionSpan | null = null;
    for (const sp of pane.attribution ?? []) {
      if (offset >= sp.start && offset < sp.end) {
        if (!best || sp.end - sp.start < best.end - best.start) best = sp;
      }
    }
    if (!best) {
      removeNote();
      return;
    }

    const author = best.author_display_name ?? "unknown";
    const state = best.verification_state ?? (best.signature_valid ? "verified" : "unsigned");
    const mark = state === "verified" ? "✓" : state === "author_maintained" ? "◐" : "?";

    if (!note) {
      note = document.createElement("div");
      note.className = "lens-note";
      scroll.appendChild(note);
    }
    note.textContent = `${mark} ${author}`;
    note.title = `author: ${author}\nstate: ${state}`;
    const scrollR = scroll.getBoundingClientRect();
    note.style.left = `${scrollR.width - note.offsetWidth - 12}px`;
    note.style.top = `${ev.clientY - scrollR.top + scroll.scrollTop - 24}px`;
  });

  scroll.addEventListener("mouseleave", removeNote);
}

function wireAllLenses(): void {
  wireLens("a");
  wireLens("b");
  wireLens("c");
}

/** Find-the-term: translucent marker over every occurrence of the
 *  live search query in each open page. Drawn as an overlay (like
 *  the identity boxes) so text segmentation never changes. */
function drawSearchHl(tag: Col): void {
  const pane = paneAt(tag);
  const layer = document.getElementById(`searchhl-${tag}`);
  const pre = document.querySelector<HTMLElement>(`#scroll-${tag} pre`);
  if (!layer || !pre || !pane || !searchQuery) {
    if (layer) layer.innerHTML = "";
    return;
  }
  const layerR = layer.getBoundingClientRect();
  const hay = pane.text.toLowerCase();
  const needle = searchQuery.toLowerCase();
  const hits: number[] = [];
  let at = hay.indexOf(needle);
  while (at !== -1 && hits.length < 50) {
    hits.push(at);
    at = hay.indexOf(needle, at + needle.length);
  }
  if (hits.length === 0) {
    layer.innerHTML = "";
    return;
  }
  const walker = document.createTreeWalker(pre, NodeFilter.SHOW_TEXT);
  const nodes: Text[] = [];
  while (walker.nextNode()) nodes.push(walker.currentNode as Text);
  let html = "";
  for (const h of hits) {
    const range = document.createRange();
    let pos = 0;
    let anchored = false;
    for (const node of nodes) {
      if (!anchored && pos + node.length > h) {
        range.setStart(node, h - pos);
        anchored = true;
      }
      if (anchored && pos + node.length >= h + needle.length) {
        range.setEnd(node, h + needle.length - pos);
        break;
      }
      pos += node.length;
    }
    if (!range.collapsed) {
      for (const rect of range.getClientRects()) {
        html += `<div class="searchhl" style="left:${(rect.left - layerR.left).toFixed(1)}px;top:${(rect.top - layerR.top).toFixed(1)}px;width:${rect.width.toFixed(1)}px;height:${rect.height.toFixed(1)}px"></div>`;
      }
    }
  }
  layer.innerHTML = html;
}

function drawAllSearchHl(): void {
  drawSearchHl("a");
  drawSearchHl("b");
  drawSearchHl("c");
}

function observeBeams(): void {
  beamObserver?.disconnect();
  const sa = document.getElementById("scroll-a");
  const sb = document.getElementById("scroll-b");
  const sc = document.getElementById("scroll-c");
  if (!sa || !sb) return;
  const redraw = () => {
    drawBeams();
    drawAllTBoxes();
    drawAllSearchHl();
  };
  sa.addEventListener("scroll", redraw, { passive: true });
  sb.addEventListener("scroll", redraw, { passive: true });
  sc?.addEventListener("scroll", redraw, { passive: true });
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
  if (e.key === "ArrowRight") {
    // cycle focus through the open pages: a → b → c → c
    if (focusPane === "a" && paneB) focusPane = "b";
    else if (focusPane === "b" && paneC) focusPane = "c";
    render();
  } else if (e.key === "ArrowLeft") {
    if (focusPane === "c" && paneB) focusPane = "b";
    else focusPane = "a";
    render();
  } else if (e.key === "Enter") {
    e.preventDefault();
    void startEditing(focusPane);
  }
});

render();
