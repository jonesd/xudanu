import { ClassicClient, LINK_TYPE_NAMES, type LinkEntryClassic } from "./client";

function esc(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function firstLine(text: string): string {
  return text.split("\n")[0].slice(0, 72).trim();
}

/** Stable hue for unknown link-type ids (custom types are works). */
export function typeColor(id: number): string {
  const known = LINK_TYPE_NAMES[id];
  if (known) return known.color;
  return `hsl(${Math.round((id * 137.508) % 360)} 45% 64%)`;
}

interface WinData {
  workId: number;
  title: string;
  text: string;
  links: LinkEntryClassic[];
}

interface SatWin {
  key: string;
  link: LinkEntryClassic;
  fromKey: string;
  data: WinData;
  x: number;
  y: number;
  w: number;
  h: number;
  z: number;
  side: "out" | "in";
  pinned?: boolean;
}

const SAT_W = 296;
const SAT_H = 248;
const AUTO_UNFOLD = 6;

export interface ReviseHooks {
  start: () => void;
  save: () => void;
  cancel: () => void;
}

export class WindowsView {
  private root: HTMLElement;
  private client: ClassicClient;
  private onPromote: (workId: number) => void;
  private revise: ReviseHooks;
  private center: WinData | null = null;
  private sats: SatWin[] = [];
  private cache = new Map<number, WinData>();
  private typeNames = new Map<number, string>();
  private zTop = 10;
  private editText: string | null = null;
  private cleanupFns: (() => void)[] = [];

  constructor(root: HTMLElement, client: ClassicClient, onPromote: (workId: number) => void, revise: ReviseHooks) {
    this.root = root;
    this.client = client;
    this.onPromote = onPromote;
    this.revise = revise;
  }

  destroy(): void {
    this.cleanupFns.forEach((f) => f());
    this.cleanupFns = [];
    this.root.innerHTML = "";
  }

  private async fetch(workId: number): Promise<WinData> {
    const hit = this.cache.get(workId);
    if (hit) return hit;
    const [text, links] = await Promise.all([
      this.client.readWork(workId),
      this.client.linksFor(workId),
    ]);
    const d: WinData = { workId, title: firstLine(text) || `work ${workId}`, text, links };
    this.cache.set(workId, d);
    return d;
  }

  private async typeName(id: number): Promise<string> {
    const known = LINK_TYPE_NAMES[id];
    if (known) return known.name;
    const hit = this.typeNames.get(id);
    if (hit) return hit;
    let name = `type ${id}`;
    try {
      const d = await this.fetch(id);
      const l = firstLine(d.text).toLowerCase();
      if (l) name = l.replace(/^link type:\s*/, "").slice(0, 18);
    } catch {
      /* keep fallback */
    }
    this.typeNames.set(id, name);
    return name;
  }

  async setCenter(workId: number): Promise<void> {
    this.destroy();
    this.editText = null;
    this.center = await this.fetch(workId);
    this.sats = [];
    await this.warmTypeNames(this.center.links);
    const outbound = this.center.links.filter((l) => l.origin === workId);
    const picks = outbound.slice(0, AUTO_UNFOLD);
    for (const l of picks) await this.addSat("center", l, "out", false);
    this.build();
  }

  /** Swap the center body between reading marks and the revise
   *  textarea (Phase D editing surface). */
  setEditing(text: string | null): void {
    this.editText = text;
    this.build();
  }

  /** Refetch the center work (post-save) and rebuild in place. */
  async refreshCenter(): Promise<void> {
    if (!this.center) return;
    this.cache.delete(this.center.workId);
    this.center = await this.fetch(this.center.workId);
    this.build();
  }

  private async warmTypeNames(links: LinkEntryClassic[]): Promise<void> {
    const ids = new Set<number>();
    for (const l of links) for (const t of l.link_types ?? []) ids.add(t);
    await Promise.all([...ids].map((id) => this.typeName(id)));
  }

  private farEndOf(link: LinkEntryClassic, fromWorkId: number): number | null {
    if (link.origin === fromWorkId) return link.destination;
    return link.origin;
  }

  private async addSat(fromKey: string, link: LinkEntryClassic, side: "out" | "in", rebuild = true): Promise<void> {
    const src = fromKey === "center" ? this.center : this.sats.find((s) => s.key === fromKey)?.data;
    if (!src) return;
    const far = this.farEndOf(link, src.workId);
    if (far === null) return;
    const data = await this.fetch(far);
    this.layoutSat({ key: `L${link.link_id}`, link, fromKey, data, x: 0, y: 0, w: SAT_W, h: SAT_H, z: ++this.zTop, side });
    if (rebuild) this.build();
  }

  private layoutSat(s: SatWin): void {
    this.sats.push(s);
    this.reflow();
  }

  /** Grid the satellites into the zone right of center; choose the
   *  column count that maximizes window height; never move windows
   *  the user has dragged (pinned). */
  private reflow(): void {
    if (this.sats.length === 0) return;
    const stage = this.root.getBoundingClientRect();
    const centerW = Math.min(Math.max(stage.width * 0.44, 340), 640);
    const zoneX = centerW + 48;
    const zoneW = Math.max(stage.width - zoneX - 16, 240);
    const availH = stage.height - 32;
    const n = this.sats.length;
    const maxCols = Math.max(1, Math.min(3, Math.floor(zoneW / 216)));
    let bestCols = maxCols;
    let bestW = Math.min(SAT_W, Math.floor((zoneW - (maxCols - 1) * 16) / maxCols));
    let bestH = 0;
    for (let cols = 1; cols <= maxCols; cols++) {
      const w = Math.min(SAT_W, Math.floor((zoneW - (cols - 1) * 16) / cols));
      const rows = Math.ceil(n / cols);
      const h = Math.min(SAT_H, Math.floor((availH - (rows - 1) * 16) / rows));
      if (h > bestH) {
        bestH = h;
        bestCols = cols;
        bestW = w;
      }
    }
    const cols = bestCols;
    const w = bestW;
    const h = Math.max(96, bestH);
    const paper = this.paper();
    const pinnedBoxes = this.sats.filter((s) => s.pinned).map((s) => ({ x: s.x, y: s.y, w: s.w, h: s.h }));
    if (paper) {
      this.sats.forEach((s, i) => {
        if (s.pinned) return;
        s.w = w;
        s.h = Math.min(h, 220);
        s.x = zoneX + (i % 2) * 210 + Math.floor(i / 2) * 46;
        s.y = 16 + Math.floor(i / 2) * 156 + (i % 2) * 38;
      });
      return;
    }
    this.sats.forEach((s, i) => {
      if (s.pinned) return;
      s.w = w;
      s.h = h;
      let x = zoneX + (i % cols) * (w + 16);
      let y = 16 + Math.floor(i / cols) * (h + 16);
      for (let guard = 0; guard < 40; guard++) {
        const hit = pinnedBoxes.find((p) => x < p.x + p.w + 8 && x + w + 8 > p.x && y < p.y + p.h + 8 && y + h + 8 > p.y);
        if (!hit) break;
        x += 22;
        y += 22;
      }
      s.x = x;
      s.y = y;
    });
  }

  private marksHtml(data: WinData, key: string): string {
    type MK = { start: number; end: number; link: LinkEntryClassic };
    const marks: MK[] = [];
    for (const l of data.links) {
      if (l.origin === data.workId && l.origin_ref?.start_position !== undefined) {
        marks.push({ start: l.origin_ref.start_position, end: l.origin_ref.end_position ?? l.origin_ref.start_position, link: l });
      }
      if (l.destination === data.workId && l.destination_ref?.start_position !== undefined) {
        marks.push({ start: l.destination_ref.start_position, end: l.destination_ref.end_position ?? l.destination_ref.start_position, link: l });
      }
    }
    const clamp = (v: number) => Math.max(0, Math.min(v, data.text.length));
    const bset = new Set<number>([0, data.text.length]);
    for (const m of marks) {
      bset.add(clamp(m.start));
      bset.add(clamp(Math.max(m.end, m.start + 1)));
    }
    const bounds = [...bset].sort((a, b) => a - b);
    let html = "";
    for (let i = 0; i < bounds.length - 1; i++) {
      const a = bounds[i];
      const b = bounds[i + 1];
      if (b <= a) continue;
      const seg = data.text.slice(a, b);
      const covering = marks.filter((m) => clamp(m.start) <= a && clamp(m.end) >= b);
      if (covering.length === 0) {
        html += esc(seg);
        continue;
      }
      const lanes = covering.slice(0, 4);
      const shadows = lanes
        .map((m, li) => `inset 0 -${2 + li * 3}px 0 ${typeColor((m.link.link_types ?? [0])[0])}`)
        .join(", ");
      const tint = `${typeColor((lanes[0].link.link_types ?? [0])[0])}14`;
      const names = lanes.map((m) => this.typeNameSync(m.link)).join(", ");
      const pad = (lanes.length - 1) * 3;
      const ids = [...new Set(lanes.map((m) => m.link.link_id))].join(" ");
      html += `<mark data-link="${ids}" data-win="${key}" title="${esc(names)}" style="box-shadow:${shadows};background:${tint};cursor:pointer;padding-bottom:${pad}px">${esc(seg)}</mark>`;
    }
    return html;
  }

  private build(): void {
    if (!this.center) return;
    const activeIds = new Set(this.sats.map((s) => s.link.link_id));
    const stage = this.root.getBoundingClientRect();
    const centerW = Math.min(Math.max(stage.width * 0.44, 340), 640);

    const chips = this.center.links
      .map((l) => ({ l, side: l.origin === this.center!.workId ? "out" : "in" }))
      .map(({ l, side }) => {
        const far = this.farEndOf(l, this.center!.workId);
        const farTitle = side === "out" ? l.destination_title ?? `work ${far}` : l.origin_title ?? `work ${far}`;
        const c = typeColor((l.link_types ?? [0])[0]);
        const open = activeIds.has(l.link_id);
        return `<button class="chip${open ? " open" : ""}" data-chip-link="${l.link_id}" data-chip-side="${side}" style="border-color:${c}${open ? ";color:" + c : ""}">${side === "in" ? "← " : ""}${esc(String(this.typeNameSync(l)))} · ${esc(farTitle.slice(0, 40))}</button>`;
      })
      .join("");
    const hidden = Math.max(0, this.center.links.length - this.sats.filter((s) => s.fromKey === "center").length);
    const unfoldAll = hidden > 0 ? `<button class="chip more" id="unfold-all">unfold all (${this.center.links.length})</button>` : "";

    this.root.innerHTML = `
      <svg class="beamfield" id="beamfield"></svg>
      <section class="win center" id="win-center" style="left:24px;top:16px;width:${centerW}px;height:calc(100% - 32px)">
        <div class="win-head" data-drag="center"><h2>${esc(this.center.title)}</h2>${this.editText === null ? `<span class="win-tools"><button class="tool" id="revise-start" title="revise this work">✎</button></span>` : ""}</div>
        ${this.editText !== null
          ? `<textarea id="revise-text" class="revise" spellcheck="false">${esc(this.editText)}</textarea>
             <div class="revise-bar"><button id="revise-save" class="revise-btn">save</button><button id="revise-cancel" class="revise-btn ghosted">cancel</button><span class="quiet small">editing — ⌘↵ saves · esc cancels</span></div>`
          : `<div class="win-body" id="body-center"><pre class="prose">${this.marksHtml(this.center, "center")}</pre></div>
             <div class="win-foot"><div class="chips">${chips}${unfoldAll}</div></div>`}
      </section>
      ${this.sats
        .map((s) => {
          const c = typeColor((s.link.link_types ?? [0])[0]);
          const farTitle = s.side === "out" ? s.link.destination_title ?? s.data.title : s.link.origin_title ?? s.data.title;
          return `<section class="win sat" id="win-${s.key}" style="left:${s.x}px;top:${s.y}px;width:${s.w}px;height:${s.h}px;z-index:${s.z}${this.paper() ? `;transform:rotate(${(((s.link.link_id * 7) % 5) - 2) * 0.7}deg)` : ""}">
          <div class="win-head" data-drag="${s.key}" style="border-bottom:2px solid ${c}">
            <h3 title="${esc(farTitle)}">${esc(farTitle.slice(0, 44))}</h3>
            <span class="win-tools">
              <button class="tool" data-focus="${s.key}" title="make this the center">⌖</button>
              <button class="tool" data-close="${s.key}" title="close window">×</button>
            </span>
          </div>
          <div class="win-body" id="body-${s.key}"><pre class="prose">${this.marksHtml(s.data, s.key)}</pre></div>
        </section>`;
        })
        .join("")}`;

    this.wire();
    this.scrollSatsToSpans();
    this.drawBeams();
  }

  private typeNameSync(l: LinkEntryClassic): string {
    const id = (l.link_types ?? [0])[0];
    return LINK_TYPE_NAMES[id]?.name ?? this.typeNames.get(id) ?? "link";
  }

  private wire(): void {
    const stage = this.root;

    const startBtn = document.getElementById("revise-start");
    if (startBtn) startBtn.onclick = () => this.revise.start();
    const saveBtn = document.getElementById("revise-save");
    if (saveBtn) saveBtn.onclick = () => this.revise.save();
    const cancelBtn = document.getElementById("revise-cancel");
    if (cancelBtn) cancelBtn.onclick = () => this.revise.cancel();
    const ta = document.getElementById("revise-text") as HTMLTextAreaElement | null;
    if (ta) {
      ta.addEventListener("keydown", (e) => {
        if (e.key === "Escape") {
          e.preventDefault();
          this.revise.cancel();
        } else if ((e.metaKey || e.ctrlKey) && e.key === "Enter") {
          e.preventDefault();
          this.revise.save();
        }
      });
      ta.focus();
    }

    stage.querySelectorAll<HTMLElement>("mark[data-link]").forEach((m) => {
      m.onclick = () => {
        const fromKey = m.dataset.win ?? "center";
        void this.toggleSat(Number((m.dataset.link ?? "").split(" ")[0]), fromKey, fromKey === "center" ? "out" : "out");
      };
    });

    stage.querySelectorAll<HTMLButtonElement>("button[data-chip-link]").forEach((b) => {
      b.onclick = () => void this.toggleSat(Number(b.dataset.chipLink), "center", b.dataset.chipSide === "in" ? "in" : "out");
    });

    const all = document.getElementById("unfold-all");
    if (all) all.onclick = () => void this.unfoldAll();

    stage.querySelectorAll<HTMLButtonElement>("button[data-close]").forEach((b) => {
      b.onclick = () => {
        this.sats = this.sats.filter((s) => s.key !== b.dataset.close);
        this.build();
      };
    });

    stage.querySelectorAll<HTMLButtonElement>("button[data-focus]").forEach((b) => {
      b.onclick = () => {
        const s = this.sats.find((x) => x.key === b.dataset.focus);
        if (s) this.onPromote(s.data.workId);
      };
    });

    stage.querySelectorAll<HTMLElement>(".win-head[data-drag]").forEach((h) => {
      this.wireDrag(h, h.dataset.drag!);
    });

    stage.querySelectorAll<HTMLElement>(".win").forEach((w) => {
      w.addEventListener("pointerdown", () => {
        const key = w.id.replace("win-", "");
        const s = this.sats.find((x) => x.key === key);
        if (s && s.z !== this.zTop) {
          s.z = ++this.zTop;
          (w as HTMLElement).style.zIndex = String(s.z);
        }
      });
    });

    const redraw = () => this.drawBeams();
    this.root.querySelectorAll<HTMLElement>(".win-body").forEach((b) => b.addEventListener("scroll", redraw, { passive: true }));
    const onResize = () => redraw();
    window.addEventListener("resize", onResize);
    this.cleanupFns.push(() => window.removeEventListener("resize", onResize));
  }

  private async toggleSat(linkId: number, fromKey: string, side: "out" | "in"): Promise<void> {
    const existing = this.sats.find((s) => s.key === `L${linkId}`);
    if (existing) {
      this.flash(existing);
      return;
    }
    const src = fromKey === "center" ? this.center : this.sats.find((s) => s.key === fromKey)?.data;
    if (!src) return;
    const l = src.links.find((x) => x.link_id === linkId);
    if (!l) return;
    await this.addSat(fromKey, l, side);
  }

  private async unfoldAll(): Promise<void> {
    if (!this.center) return;
    await this.warmTypeNames(this.center.links);
    const outbound = this.center.links.filter((l) => l.origin === this.center!.workId && !this.sats.some((s) => s.link.link_id === l.link_id));
    const inbound = this.center.links.filter((l) => l.origin !== this.center!.workId && !this.sats.some((s) => s.link.link_id === l.link_id));
    for (const l of outbound) await this.addSat("center", l, "out", false);
    for (const l of inbound) await this.addSat("center", l, "in", false);
    this.build();
  }

  private flash(s: SatWin): void {
    s.z = ++this.zTop;
    const el = this.root.querySelector(`#win-${s.key}`);
    if (!el) return;
    (el as HTMLElement).style.zIndex = String(s.z);
    el.classList.add("flash");
    setTimeout(() => el.classList.remove("flash"), 900);
  }

  private wireDrag(handle: HTMLElement, key: string): void {
    let startX = 0;
    let startY = 0;
    let origX = 0;
    let origY = 0;
    let raf = 0;
    const win = handle.closest(".win") as HTMLElement | null;
    if (!win) return;
    handle.onpointerdown = (ev) => {
      if ((ev.target as HTMLElement).closest("button")) return;
      ev.preventDefault();
      handle.setPointerCapture(ev.pointerId);
      startX = ev.clientX;
      startY = ev.clientY;
      origX = win.offsetLeft;
      origY = win.offsetTop;
      handle.classList.add("dragging");
      const move = (e: PointerEvent) => {
        win.style.left = `${origX + e.clientX - startX}px`;
        win.style.top = `${origY + e.clientY - startY}px`;
        cancelAnimationFrame(raf);
        raf = requestAnimationFrame(() => this.drawBeams());
      };
      const up = () => {
        handle.releasePointerCapture(ev.pointerId);
        handle.removeEventListener("pointermove", move);
        handle.removeEventListener("pointerup", up);
        handle.classList.remove("dragging");
        const s = this.sats.find((x) => x.key === key);
        if (s) {
          s.x = win.offsetLeft;
          s.y = win.offsetTop;
          s.pinned = true;
        }
        this.drawBeams();
      };
      handle.addEventListener("pointermove", move);
      handle.addEventListener("pointerup", up);
    };
  }

  private scrollSatsToSpans(): void {
    for (const s of this.sats) {
      const body = this.root.querySelector(`#body-${s.key}`);
      if (!body) continue;
      const ref = s.side === "out" ? s.link.destination_ref : s.link.origin_ref;
      const mark = ref ? body.querySelector(`mark[data-link~="${s.link.link_id}"]`) : null;
      if (mark) {
        const mb = (mark as HTMLElement).getBoundingClientRect();
        const bb = body.getBoundingClientRect();
        body.scrollTop += mb.top - bb.top - bb.height / 2 + mb.height / 2;
      }
    }
  }

  private paper(): boolean {
    return document.body.classList.contains("paper");
  }

  /** Small zigzag "crinkle" at a beam endpoint — the mockup's mark
   *  for a connected passage. dir points along the beam. */
  private crinkle(x: number, y: number, dx: number, dy: number): string {
    const len = Math.hypot(dx, dy) || 1;
    const ux = dx / len;
    const uy = dy / len;
    const px = -uy;
    const py = ux;
    let d = `M ${x} ${y}`;
    for (let i = 1; i <= 4; i++) {
      const along = i * 3;
      const side = i % 2 === 1 ? 3 : -3;
      d += ` L ${(x + ux * along + px * side).toFixed(1)} ${(y + uy * along + py * side).toFixed(1)}`;
    }
    return d;
  }

  private drawBeams(): void {
    const svg = this.root.querySelector<SVGSVGElement>("#beamfield");
    if (!svg || !this.center) return;
    const stageR = this.root.getBoundingClientRect();
    svg.setAttribute("width", String(stageR.width));
    svg.setAttribute("height", String(stageR.height));
    let paths = "";
    for (const s of this.sats) {
      const srcKey = s.fromKey;
      const srcEl = this.root.querySelector(`#win-${srcKey === "center" ? "center" : srcKey}`);
      const dstEl = this.root.querySelector(`#win-${s.key}`);
      if (!srcEl || !dstEl) continue;
      const mark = srcEl.querySelector(`mark[data-link~="${s.link.link_id}"]`) as HTMLElement | null;
      const sr = srcEl.getBoundingClientRect();
      const dr = dstEl.getBoundingClientRect();
      let x1: number;
      let y1: number;
      if (mark) {
        const lines = mark.getClientRects();
        const mr = lines.length > 0 ? lines[lines.length - 1] : mark.getBoundingClientRect();
        x1 = mr.left + mr.width / 2 - stageR.left;
        y1 = mr.bottom - 1 - stageR.top;
      } else {
        x1 = sr.right - stageR.left;
        y1 = sr.top + 30 - stageR.top;
      }
      let x2: number;
      let y2: number;
      const dstMark = dstEl.querySelector<HTMLElement>(`mark[data-link~="${s.link.link_id}"]`);
      if (dstMark) {
        const lines = dstMark.getClientRects();
        const dmr = lines.length > 0 ? lines[0] : dstMark.getBoundingClientRect();
        x2 = dmr.left - 2 - stageR.left;
        const raw = dmr.bottom - 1 - stageR.top;
        y2 = Math.min(Math.max(raw, dr.top + 28 - stageR.top), dr.bottom - 8 - stageR.top);
      } else {
        x2 = dr.left - stageR.left;
        y2 = dr.top + 24 - stageR.top;
      }
      if (this.paper()) {
        const ink = "#1d1a15";
        paths += `<path d="M ${x1.toFixed(1)} ${y1.toFixed(1)} L ${x2.toFixed(1)} ${y2.toFixed(1)}" fill="none" stroke="${ink}" stroke-width="1"/>`;
        paths += `<path d="${this.crinkle(x1, y1, x2 - x1, y2 - y1)}" fill="none" stroke="${ink}" stroke-width="1"/>`;
        paths += `<path d="${this.crinkle(x2, y2, x1 - x2, y1 - y2)}" fill="none" stroke="${ink}" stroke-width="1"/>`;
      } else {
        const mid = (x1 + x2) / 2;
        const c = typeColor((s.link.link_types ?? [0])[0]);
        paths += `<path d="M ${x1} ${y1} C ${mid} ${y1}, ${mid} ${y2}, ${x2} ${y2}" fill="none" stroke="${c}" stroke-width="1.6" stroke-dasharray="5 4" opacity="0.85"><animate attributeName="stroke-dashoffset" from="18" to="0" dur="1.2s" repeatCount="indefinite"/></path>`;
      }
    }
    svg.innerHTML = paths;
  }
}
