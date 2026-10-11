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
let stackRev: Partial<Record<Col, number | null>> = {};
let stackTextCache = new Map<string, string>(); // "workId:rev" -> text

/** Fetch a revision's text, cached. */
async function stackText(workId: number, rev: number): Promise<string> {
  const key = `${workId}:${rev}`;
  const hit = stackTextCache.get(key);
  if (hit !== undefined) return hit;
  const text = await client?.fetchRevision(workId, rev) ?? "";
  stackTextCache.set(key, text);
  return text;
}
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
  revisionCount?: number;
  _stackOldText?: string;
}

async function fetchPane(client: ClassicClient, workId: number): Promise<Pane> {
  const [raw, links, inline, attribution, revisionCount] = await Promise.all([
    client.readWork(workId),
    client.linksFor(workId),
    client.resolveInline(workId).catch((): InlineTransclusions => ({ text: "", spanRanges: [], sourceTitles: {} })),
    client.attribution(workId).catch((): AttributionSpan[] => []),
    client.revisionCount(workId).catch(() => 0),
  ]);
  // A transcluding work displays its RESOLVED text: the reader sees the
  // live window's content inline (Nelson's window, not a placeholder),
  // with identity boxes over the shared ranges.
  const text = inline.spanRanges.length > 0 && inline.text ? inline.text : raw;
  return { workId, title: firstLine(text, workId), text, links, inline, attribution, revisionCount };
}

let stackA: Pane[] = [];
let stackB: Pane[] = [];
let stackC: Pane[] = [];
const COLS = ["a", "b", "c"] as const;
type Col = (typeof COLS)[number];

const STACK_CAP = 8;

function stackAt(tag: Col): Pane[] {
  return tag === "a" ? stackA : tag === "b" ? stackB : stackC;
}

/** The active work in a column: the one last interacted with (or
 *  the most recently added). Receives beams, lens, boxes. */
function paneAt(tag: Col): Pane | null {
  const stack = stackAt(tag);
  return stack.length > 0 ? stack[0] : null;
}

/** Replace the active work in a column. */
function setPane(tag: Col, p: Pane | null): void {
  const stack = stackAt(tag);
  if (p === null) {
    stack.length = 0;
  } else if (stack.length > 0) {
    stack[0] = p;
  } else {
    stack.push(p);
  }
}

/** Append a work to a column's stack — the reading stream gesture.
 *  If the work is already in the stack, activate it instead. */
function appendToStack(tag: Col, p: Pane): void {
  const stack = stackAt(tag);
  const existing = stack.findIndex((w) => w.workId === p.workId);
  if (existing !== -1) {
    // already in the stack: move it to the top (re-activate)
    stack.splice(existing, 1);
    stack.unshift(p);
    return;
  }
  stack.unshift(p);
  if (stack.length > STACK_CAP) stack.pop();
}

/** Activate a specific work within a stack (by index). */
let activeLink: LinkEntryClassic | null = null;
let inspectLink: number | null = null;

interface LinkEnd {
  workId: number;
  title: string;
  excerpt: string;
}

/** All ends of a link: origin, destination, and every attachment in
 *  end_sets (gathered passages + multi-ended connections). */
function allEndsOf(l: LinkEntryClassic): LinkEnd[] {
  const ends: LinkEnd[] = [];
  const seen = new Set<string>();
  const push = (workId: number | null, title: string | undefined, excerpt: string | null | undefined) => {
    if (workId === null || workId === 0) return;
    const key = `${workId}:${excerpt ?? ""}`;
    if (seen.has(key)) return;
    seen.add(key);
    ends.push({ workId, title: title ?? `work ${workId}`, excerpt: (excerpt ?? "").trim() });
  };

  // origin and destination with their primary refs
  push(l.origin, l.origin_title, l.origin_ref?.excerpt);
  push(l.destination, l.destination_title, l.destination_ref?.excerpt);

  // every attachment in end_sets (gathered members, extra ends)
  for (const [, refs] of l.end_sets ?? []) {
    for (const ref of refs) {
      push(ref.work_context ?? null, undefined, ref.excerpt);
    }
  }

  return ends;
}

function beamPanelHtml(): string {
  const id = inspectLink;
  const l = [paneAt('a'), paneAt('b'), paneAt('c')].flatMap((p) => (p ? p.links : [])).find((x) => x.link_id === id);
  if (!l) return "";
  const t = typeOf(l);
  const ends = allEndsOf(l);

  const rows = ends
    .map((e) => {
      const open = [paneAt('a'), paneAt('b'), paneAt('c')].some((p) => p?.workId === e.workId);
      return `<button class="bp-end" data-end-work="${e.workId}" ${open ? 'disabled' : ""} style="border-left:3px solid ${t.color}">
        <span class="bp-end-title">${esc(e.title.slice(0, 44))}</span>
        ${e.excerpt ? `<span class="bp-excerpt">“${esc(e.excerpt.slice(0, 60))}”</span>` : ""}
      </button>`;
    })
    .join("");

  const arity = ends.length > 2 ? ` · ${ends.length} ends` : "";
  const notes = annotationsOf(l.link_id);
  const notesHtml = notes.length > 0
    ? `<div class="bp-notes"><h4>${notes.length} annotation${notes.length > 1 ? "s" : ""} on this connection</h4>${notes.map((n) => {
        const nex = n.origin_ref?.excerpt?.trim() ?? n.destination_ref?.excerpt?.trim() ?? "";
        const nWork = n.origin_title ?? n.destination_title ?? `work ${n.origin}`;
        return `<button class="bp-end" data-note-link="${n.link_id}" style="border-left:3px solid ${typeOf(n).color}">
          <span class="bp-end-title">${esc(nWork.slice(0, 40))}</span>
          ${nex ? `<span class="bp-excerpt">“${esc(nex.slice(0, 60))}”</span>` : ""}
        </button>`;
      }).join("")}</div>`
    : "";
  return `<div class="beam-panel" id="beam-panel">
    <div class="bp-type" style="color:${t.color}">${esc(t.name)}${arity} · link ${l.link_id}</div>
    <div class="bp-ends">${rows}</div>
    ${notesHtml}
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

async function openWork(workId: number, pane: "A" | "B" | "C", push = true): Promise<void> {
  if (!client) return;
  if (editing) {
    await editor?.cancel(editing.workId);
    editor = null;
    editing = null;
  }
  const p = await fetchPane(client, workId);
  if (pane === "A") {
    appendToStack("a", p);
    if (push) history.pushState({ w: workId }, "", `#w${workId}`);
  } else if (pane === "B") {
    appendToStack("b", p);
  } else {
    appendToStack("c", p);
  }
  render();
}


function paneHtml(tag: Col): string {
  const stack = stackAt(tag);
  const isEditingHere = !!editing && editing.pane === tag;

  // column-level tools (only on the column header)
  const colTools: string[] = [];
  if (tag === "a" && !isEditingHere) {
    colTools.push(`<button class="close-pane" id="link-start" data-link-pane="a" title="connect this selection">⧉</button>`);
  }

  // if the stack is empty, show a ghost column
  if (stack.length === 0) {
    const hint = tag === "a"
      ? "Search or follow a trail to start reading."
      : tag === "b"
        ? "Click an underline, or search and click a result, to open a page here."
        : "Follow another connection or search for a third page.";
    return `<section class="pane ghost" id="pane-${tag}">
      <div class="pane-head"><h2 class="quiet">—</h2></div>
      <div class="pane-scroll"><p class="quiet">${hint}</p></div>
    </section>`;
  }

  // render each work in the stack
  const worksHtml = stack.map((wk, i) => {
    const isActive = i === 0;
    const dimClass = isActive ? "" : " dimmed";
    const wTools: string[] = [];
    if (!isEditingHere) {
      if (i > 0) wTools.push(`<button class="close-pane" data-reorder-pane="${tag}" data-reorder-idx="${i}" data-reorder-dir="up" title="move up">↑</button>`);
      if (i < stack.length - 1) wTools.push(`<button class="close-pane" data-reorder-pane="${tag}" data-reorder-idx="${i}" data-reorder-dir="down" title="move down">↓</button>`);
      wTools.push(`<button class="close-pane" data-similar-pane="${tag}" data-similar-idx="${i}" title="find more like this passage">⇄</button>`);
      wTools.push(`<button class="close-pane" data-link-pane="${tag}" data-work-idx="${i}" title="connect this selection">⧉</button>`);
      wTools.push(`<button class="close-pane" data-revise-pane="${tag}" data-revise-idx="${i}" title="revise this work">✎</button>`);
      wTools.push(`<button class="close-pane" data-close-pane="${tag}" data-close-idx="${i}" title="remove from stack">×</button>`);
    }
    const body = isEditingHere && isActive
      ? `<textarea id="revise-text" class="revise" spellcheck="false">${esc(wk.text)}</textarea>`
      : `<pre class="prose">${renderText(wk)}</pre>`;

    return `<div class="stack-work${dimClass}" id="work-${tag}-${i}" data-work-id="${wk.workId}">
      <div class="stack-work-head">
        <h3 class="stack-work-title">${esc(wk.title)}</h3>
        <span class="win-tools">${wTools.join("")}</span>
      </div>
      <div class="stack-work-body" id="scroll-${tag}-${i}">${body}</div>
    </div>`;
  }).join("");

  const editBar = isEditingHere
    ? `<div class="revise-bar"><button id="revise-save" class="revise-btn">save</button><button id="revise-cancel" class="revise-btn ghosted">cancel</button><span class="quiet small">editing — ⌘↵ saves · esc cancels</span></div>`
    : "";

  const focused = !isEditingHere && focusPane === tag ? " focused" : "";
  return `<section class="pane${focused}" id="pane-${tag}">
    <div class="stack-count" id="stack-count-${tag}">${stack.length > 1 ? `${stack.length} works` : ""}</div>
    <div class="pane-scroll" id="scroll-${tag}">
      ${worksHtml}
    </div>
    ${editBar}
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
  const originPane = draft && draft.stage === "origin" ? paneAt(draft.from) : paneAt("a");
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
  const stack = stackAt(from);
  if (stack.length === 0) return;

  // Find which work in the stack contains the selection
  const sel = window.getSelection();
  let targetIdx = -1; void targetIdx;
  let targetPane: Pane | null = null;
  let start = 0;
  let end = 0;

  if (sel && !sel.isCollapsed && sel.anchorNode) {
    for (let i = 0; i < stack.length; i++) {
      const bodyEl = document.getElementById(`scroll-${from}-${i}`);
      if (bodyEl && bodyEl.contains(sel.anchorNode)) {
        targetIdx = i;
        targetPane = stack[i];
        // compute offsets within this work's text
        const pre = bodyEl.querySelector("pre");
        if (pre) {
          const walker = document.createTreeWalker(pre, NodeFilter.SHOW_TEXT);
          let pos = 0;
          while (walker.nextNode()) {
            const node = walker.currentNode as Text;
            if (node === sel.anchorNode) {
              start = pos + sel.anchorOffset;
              break;
            }
            pos += node.length;
          }
          const endNode = sel.focusNode;
          if (endNode && pre.contains(endNode) && endNode.nodeType === Node.TEXT_NODE) {
            const walker2 = document.createTreeWalker(pre, NodeFilter.SHOW_TEXT);
            pos = 0;
            while (walker2.nextNode()) {
              const node = walker2.currentNode as Text;
              if (node === endNode) {
                end = pos + sel.focusOffset;
                break;
              }
              pos += node.length;
            }
          }
          if (start > end) [start, end] = [end, start];
        }
        break;
      }
    }
  }

  if (!targetPane || end <= start || start < 0) {
    setStatus("select a passage in this column first");
    return;
  }

  draft = { stage: "origin", from, start, end, excerpt: targetPane.text.slice(start, end) };
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
  const farP = farPane;
  draft = {
    stage: "far",
    from: draft.from,
    start: draft.start,
    end: draft.end,
    excerpt: draft.excerpt,
    farWork: farP.workId,
    farTitle: farP.title,
    farRef: s ? { start: s.start, end: s.end, excerpt: farP.text.slice(s.start, s.end) } : undefined,
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
  const farStackP = stackAt("b").find((w) => w.workId === d.farWork) ?? stackAt("c").find((w) => w.workId === d.farWork);
  if (d.farRef && farStackP) {
    const updated = { ...farStackP, links: await client.linksFor(d.farWork) };
    const sb = stackAt("b"); const bi = sb.findIndex((w) => w.workId === d.farWork);
    if (bi !== -1) sb[bi] = updated;
    else { const sc = stackAt("c"); const ci = sc.findIndex((w) => w.workId === d.farWork); if (ci !== -1) sc[ci] = updated; }
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
  const windowsMode = mode === "windows" && stackA.length > 0;
  const main = windowsMode
    ? `<div id="stage" class="stage"></div>`
    : stackA.length > 0
    ? `<div class="panes" id="panes" style="grid-template-columns:repeat(3,1fr)">
        ${paneHtml("a")}
        ${paneHtml("b")}
        ${paneHtml("c")}${
        "" /* close template cleanly */}
        <svg id="beams"></svg>
        ${similarResults !== null ? similarPanelHtml() : ""}
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
        ${paneAt("a") ? `<a class="head-link" href="/workspace?work=0x${paneAt("a")!.workId.toString(16)}" title="open this work in the workspace">workspace ↗</a>` : ""}
        <span id="head-status" class="quiet small"></span>
        <span class="quiet">${esc(client.serverName)} · v${esc(client.serverVersion || "?")} · api ${client.apiVersion}</span>
      </div>
    </header>
    <div class="frame">
      <nav>
        <form id="search"><input id="q" placeholder="search the docuverse" autocomplete="off"></form>
        <div id="results"></div>
        <div id="trails"></div>
        <div id="library"></div>
      </nav>
      <main>${main}</main>
    </div>`;

  ensureTrails();
  ensureWorks();
  renderTrailsNav();
  renderLibraryPanel();
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
    void winView.setCenter(paneAt("a")!.workId);
  } else {
    winView?.destroy();
    winView = null;
    wireMarks();
    wireConns();
    wireClose();
    drawBeams();
  wireBeams();
  wireSimilar();
  wireReorder();
  wireStacks();
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
    winView.setEditing(paneAt("a")!.text);
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
    setPane("a", await fetchPane(client, workId));
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
        if (editing?.pane === "a" && stackAt("b").length > 0) {
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
let capturedSelection = "";

// Find-similar: paragraph-level matches for a selected passage
let similarResults: Array<{ work_id: number; title: string; snippet: string }> | null = null;
let similarOrigin: { text: string; workId: number } | null = null;

async function findSimilarFromSelection(from: Col): Promise<void> {
  if (!client) return;
  const pane = paneAt(from);
  if (!pane) return;
  // Use the captured selection (mouse-up) — the button click clears
  // the live selection before the handler runs
  let text = capturedSelection;
  if (text.trim().length < 10) {
    setStatus("select a passage first (at least 10 characters)");
    return;
  }
  capturedSelection = "";
  setStatus("searching for similar passages…");
  try {
    const results = await client.findSimilar(pane.workId, text);
    similarResults = results;
    similarOrigin = { text, workId: pane.workId };
    render();
    setStatus(`${results.length} similar passage${results.length === 1 ? "" : "s"} found`);
  } catch (e) {
    setStatus((e as Error).message);
  }
}

function similarPanelHtml(): string {
  if (!similarResults || !similarOrigin) return "";
  const cards = similarResults
    .map((r, i) => `<button class="similar-card" data-similar-work="${r.work_id}" data-similar-idx="${i}" title="${esc(r.title)}">
      <span class="similar-title">${esc(r.title.slice(0, 36))}</span>
      <span class="similar-snippet">${esc(r.snippet.slice(0, 100))}…</span>
    </button>`)
    .join("");
  return `<div class="type-panel" id="similar-panel">
    <h3>similar passages — click to open the source work</h3>
    <div class="type-row similar-list">${cards}</div>
    <button id="similar-close" class="revise-btn ghosted" style="margin-top:6px">close</button>
  </div>`;
}
let worksList: Array<{ work_id: string; title: string; char_count?: number; revision?: number }> = [];
let worksLoaded = false;

async function ensureWorks(): Promise<void> {
  if (worksLoaded || !client) return;
  worksLoaded = true;
  try {
    worksList = await client.listWorks();
    renderLibraryPanel();
  } catch {
    worksList = [];
  }
}

/** Open a work beside the current reading — fills the first ghost
 *  column (B, then C) before falling back to replacing A. This is
 *  the "growing the row" gesture: a new page joins the parallel
 *  layout rather than blowing it away. */
async function openBeside(workId: number): Promise<void> {
  if (mode !== "panes") {
    await openWork(workId, "A");
    return;
  }
  // The reading stream: search results stack in the focused column,
  // pushing existing works down. The trail grows where you are.
  const target = focusPane;
  if (stackAt(target).length === 0 && target === "a") {
    await openWork(workId, "A");
    return;
  }
  appendToStack(target, await fetchPane(client!, workId));
  render();
}

function renderLibraryPanel(): void {
  const el = document.getElementById("library");
  if (!el) return;
  if (worksList.length === 0) {
    el.innerHTML = "";
    return;
  }
  el.innerHTML = `<h3>docuverse</h3>` +
    worksList
      .slice(0, 40)
      .map((w) => `<a href="#" data-work="${parseInt(w.work_id, 16)}">${esc(w.title || `work ${w.work_id}`)}</a>`)
      .join("");
  el.querySelectorAll<HTMLAnchorElement>("a[data-work]").forEach((a) => {
    a.onclick = (ev) => {
      ev.preventDefault();
      const wid = Number(a.dataset.work);
      if (draft && draft.stage === "origin") {
        chooseFarWork(wid, a.textContent?.trim() ?? `work ${wid}`);
        return;
      }
      void openBeside(wid);
    };
  });
}

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
          if (paneAt("a")) await openWork(paneAt("a")!.workId, "A", false);
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
          void openBeside(wid);
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
      if (stackA.length === 0 && openTrailId !== null) render();
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
    if (opening && stackA.length === 0) history.pushState({ t: tid }, "", `#t${tid}`);
    if (stackA.length > 0) renderTrailsNav();
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
    void openBeside(wid);
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
      void openBeside(wid);
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
  // The reading stream: following a connection appends to the next
  // column's stack — nothing is replaced, the trail grows.
  const p = await fetchPane(client, far);
  if (from === "a") appendToStack("b", p);
  else if (from === "b") appendToStack("c", p);
  else appendToStack("a", p);
  render();
}

function wireBeams(): void {
  const svg = document.getElementById("beams");
  svg?.addEventListener("click", (ev) => {
    const hit = (ev.target as SVGElement).closest?.("path[data-link]") as SVGPathElement | null;
    if (!hit) return;
    const id = Number(hit.dataset.link);
    const l = [paneAt('a'), paneAt('b'), paneAt('c')].flatMap((p) => (p ? p.links : [])).find((x) => x.link_id === id) ?? null;
    inspectLink = l ? id : null;
    activeLink = l;
    render();
  });
  document.getElementById("beam-close")?.addEventListener("click", () => {
    inspectLink = null;
    render();
  });
  document.querySelectorAll<HTMLButtonElement>(".bp-end[data-note-link]").forEach((b) => {
    b.addEventListener("click", () => {
      const noteId = Number(b.dataset.noteLink);
      const note = [paneAt('a'), paneAt('b'), paneAt('c')].flatMap((p) => (p ? p.links : [])).find((l) => l.link_id === noteId);
      inspectLink = null;
      if (note) {
        void openWork(note.origin, "B");
      }
    });
  });
  document.querySelectorAll<HTMLButtonElement>(".bp-end[data-end-work]").forEach((b) => {
    b.addEventListener("click", () => {
      const workId = Number(b.dataset.endWork);
      inspectLink = null;
      void (async () => {
        if (stackAt("b").length === 0) appendToStack("b", await fetchPane(client!, workId));
        else if (stackAt("c").length === 0) appendToStack("c", await fetchPane(client!, workId));
        else appendToStack("b", await fetchPane(client!, workId));
        render();
      })();
    });
  });
}

document.addEventListener("mouseup", () => {
  const sel = window.getSelection();
  capturedSelection = sel && !sel.isCollapsed ? sel.toString() : capturedSelection;
});

function wireSimilar(): void {
  document.querySelectorAll<HTMLButtonElement>("[data-similar-pane]").forEach((b) => {
    b.addEventListener("click", () => void findSimilarFromSelection((b.dataset.similarPane ?? "a") as Col));
  });
  document.querySelectorAll<HTMLButtonElement>(".similar-card").forEach((b) => {
    b.addEventListener("click", () => {
      const workId = Number(b.dataset.similarWork);
      similarResults = null;
      void openBeside(workId);
    });
  });
  document.getElementById("similar-close")?.addEventListener("click", () => {
    similarResults = null;
    render();
  });
}

function wireReorder(): void {
  document.querySelectorAll<HTMLButtonElement>("[data-reorder-pane]").forEach((b) => {
    b.addEventListener("click", () => {
      const tag = (b.dataset.reorderPane ?? "a") as Col;
      const idx = Number(b.dataset.reorderIdx);
      const dir = b.dataset.reorderDir === "up" ? -1 : 1;
      const stack = stackAt(tag);
      const newIdx = idx + dir;
      if (newIdx < 0 || newIdx >= stack.length) return;
      const work = stack.splice(idx, 1)[0];
      stack.splice(newIdx, 0, work);
      render();
      // feedback: scroll to the moved work and flash it
      const el = document.getElementById(`work-${tag}-${newIdx}`);
      if (el) {
        el.scrollIntoView({ behavior: "smooth", block: "center" });
        el.classList.add("flash");
        setTimeout(() => el.classList.remove("flash"), 900);
      }
    });
  });
}

function wireClose(): void {
  document.querySelectorAll<HTMLButtonElement>("[data-close-pane]").forEach((b) => {
    b.addEventListener("click", () => {
      const tag = (b.dataset.closePane ?? "b") as Col;
      const idx = Number(b.dataset.closeIdx ?? "0");
      const stack = stackAt(tag);
      if (idx >= 0 && idx < stack.length) {
        stack.splice(idx, 1);
      }
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
    stackA = [];
    stackB = [];
    stackC = [];
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
      const headX = document.querySelector<HTMLElement>(`#pane-${x} .stack-work-head`);
      const headY = document.querySelector<HTMLElement>(`#pane-${y} .stack-work-head`);
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

      // The bead: annotations mark the line itself
      const notes = annotationsOf(l.link_id);
      if (notes.length > 0) {
        const mx = (x1 + x2) / 2;
        const my = (y1 + y2) / 2;
        paths += `<circle class="beam-bead" cx="${mx.toFixed(1)}" cy="${my.toFixed(1)}" r="5" fill="${stroke}" stroke="var(--paper)" stroke-width="2" data-link="${l.link_id}" title="${notes.length} annotation${notes.length > 1 ? "s" : ""} — click the line to read"/>`;
      }
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
async function stepStack(tag: Col): Promise<void> {
  const pane = paneAt(tag);
  if (!client || !pane || !pane.revisionCount || pane.revisionCount < 2) return;

  const current = stackRev[tag] ?? null;
  if (current === null) {
    // step back to the previous revision
    const rev = Math.max(0, pane.revisionCount - 2); // previous revision
    const text = await stackText(pane.workId, rev);
    stackRev[tag] = rev;
    setPane(tag, { ...pane, _stackOldText: text });
    render();
  } else {
    // return to present
    stackRev[tag] = null;
    const fresh = await fetchPane(client, pane.workId);
    setPane(tag, fresh);
    render();
  }
}

/** Annotations of a link: other links whose ends carry
 *  kind="link_attachment" pointing at this link's id. */
function annotationsOf(targetLinkId: number): LinkEntryClassic[] {
  const all = [paneAt('a'), paneAt('b'), paneAt('c')].flatMap((p) => (p ? p.links : []));
  return all.filter((l) => {
    const refs = [...(l.end_sets ?? []).flatMap(([, rs]) => rs)];
    return refs.some((r) => r.kind === "link_attachment" && r.link_attachment === targetLinkId);
  });
}

function wireStacks(): void {
  document.querySelectorAll<HTMLButtonElement>("[data-stack-pane]").forEach((b) => {
    const action = b.dataset.stackPane;
    if (b.classList.contains("stack-handle")) {
      b.addEventListener("click", () => void stepStack((action ?? "a") as Col));
    } else if (b.classList.contains("stack-now")) {
      b.addEventListener("click", () => void stepStack((action ?? "a") as Col));
    }
  });
}

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
  if (inField || editing || draft || !client || stackA.length === 0 || mode !== "panes") return;
  const sel = window.getSelection();
  if (sel && !sel.isCollapsed) return;
  if (e.key === "ArrowRight") {
    // cycle focus through the open pages: a → b → c → c
    if (focusPane === "a" && stackAt("b").length > 0) focusPane = "b";
    else if (focusPane === "b" && stackAt("c").length > 0) focusPane = "c";
    render();
  } else if (e.key === "ArrowLeft") {
    if (focusPane === "c" && stackAt("b").length > 0) focusPane = "b";
    else focusPane = "a";
    render();
  } else if (e.key === "Enter") {
    e.preventDefault();
    void startEditing(focusPane);
  }
});

render();
