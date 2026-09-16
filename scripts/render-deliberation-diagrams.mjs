#!/usr/bin/node
// render-deliberation-diagrams.mjs — hand-drawn SVG diagrams of the
// four-party deliberation, colored with the canonical link-type palette
// (matching document markers and compare views):
//   07-negotiation-sequence.png — T1-T8 as a sequence diagram
//   08-final-network.png        — final state as a network
import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import fs from "node:fs";

const OUT = "docs/screenshots/deliberation";
fs.mkdirSync(OUT, { recursive: true });

const C = {
  comment: "#58a6ff",
  reference: "#3fb950",
  disagreement: "#f85149",
  quotation: "#a371f7",
  seeAlso: "#d29922",
  ink: "#1f2328",
  faint: "#8b949e",
  note: "#fff8c5",
  noteBorder: "#d4a72c",
};

function esc(s) {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function sequenceSvg() {
  const W = 1360;
  const actors = [
    { id: "M", name: "Marta", role: "proposer", x: 190 },
    { id: "K", name: "Ken", role: "skeptic", x: 570 },
    { id: "P", name: "Priya", role: "reviewer", x: 900 },
    { id: "A", name: "Alex", role: "evidence", x: 1190 },
  ];
  const steps = [];
  let y = 96;
  const gap = 58;
  const push = (h) => { const at = y; y += h; return at; };

  const actorBox = (a) => `
    <rect x="${a.x - 80}" y="18" width="160" height="46" rx="8" fill="#f6f8fa" stroke="${C.faint}" stroke-width="1.5"/>
    <text x="${a.x}" y="38" text-anchor="middle" font-size="15" font-weight="600" fill="${C.ink}">${a.name}</text>
    <text x="${a.x}" y="55" text-anchor="middle" font-size="12" fill="${C.faint}">${a.role}</text>`;

  const lifelines = actors
    .map((a) => `<line x1="${a.x}" y1="64" x2="${a.x}" y2="${y}" stroke="${C.faint}" stroke-dasharray="5 5" stroke-width="1"/>`)
    .join("");

  const msg = (fromId, toId, label, color, dashed) => {
    const f = actors.find((a) => a.id === fromId);
    const t = actors.find((a) => a.id === toId);
    const at = push(gap);
    const dir = t.x > f.x ? 1 : -1;
    const x1 = f.x + dir * 78;
    const x2 = t.x - dir * 78;
    const mid = (x1 + x2) / 2;
    return `
      <text x="${mid}" y="${at - 8}" text-anchor="middle" font-size="13" fill="${C.ink}">${esc(label)}</text>
      <line x1="${x1}" y1="${at}" x2="${x2}" y2="${at}" stroke="${color}" stroke-width="2.5" ${dashed ? 'stroke-dasharray="7 5"' : ""} marker-end="url(#arr-${color.slice(1)})"/>
      <circle cx="${x1}" cy="${at}" r="3.5" fill="${color}"/>`;
  };

  const selfMsg = (id, label, color) => {
    const a = actors.find((x) => x.id === id);
    const at = push(gap + 8);
    return `
      <text x="${a.x + 74}" y="${at - 26}" text-anchor="middle" font-size="13" fill="${C.ink}">${esc(label)}</text>
      <path d="M ${a.x + 78} ${at - 18} h 34 v 22 h -30" fill="none" stroke="${color}" stroke-width="2.5" marker-end="url(#arr-${color.slice(1)})"/>`;
  };

  const note = (ids, label) => {
    const list = actors.filter((a) => ids.includes(a.id));
    const x1 = Math.min(...list.map((a) => a.x));
    const x2 = Math.max(...list.map((a) => a.x));
    const at = push(gap + 6);
    const lines = label.split("\n");
    const h = 24 + lines.length * 17;
    return `
      <rect x="${(x1 + x2) / 2 - 190}" y="${at - 34}" width="380" height="${h}" rx="6" fill="${C.note}" stroke="${C.noteBorder}" stroke-width="1.5"/>
      ${lines.map((l, i) => `<text x="${(x1 + x2) / 2}" y="${at - 34 + 24 + i * 17}" text-anchor="middle" font-size="13" fill="${C.ink}">${esc(l)}</text>`).join("")}`;
  };

  const body = [
    note(["M"], "T1 — claim lands in the proposal"),
    msg("K", "M", "T2 — L1 Disagreement", C.disagreement),
    msg("P", "M", "T3 — L2 Comment on L1", C.comment, true),
    msg("A", "M", "T4 — L3 gathered Reference (3 fragments, one end)", C.reference),
    selfMsg("M", "T5 — transclude survey (live quotation)", C.quotation),
    msg("K", "M", "T6 — L4 Disagreement", C.disagreement),
    msg("P", "M", "T6 — L5 Comment", C.comment, true),
    note(["M"], "density pill appears —\nfive connections on the one sentence"),
    selfMsg("M", "T7 — revise claim (links migrate)", C.faint),
    selfMsg("K", "T8 — retire L1 (resolves to history)", C.faint),
    msg("K", "M", "T8 — L6 Disagreement (narrower, standing)", C.disagreement),
    note(["M", "K"], "closes: partial agreement,\none standing dissent"),
  ].join("");

  const legend = `
    <g font-size="13" fill="#57606a">
      <rect x="0" y="${y + 16}" width="${W}" height="34" fill="#ffffff"/>
      <text x="${W / 2 - 360}" y="${y + 38}"><tspan fill="${C.disagreement}" font-weight="700">— Disagreement</tspan><tspan dx="26" fill="${C.comment}" font-weight="700">— Comment</tspan><tspan dx="26" fill="${C.reference}" font-weight="700">— Reference / gathered evidence</tspan><tspan dx="26" fill="${C.quotation}" font-weight="700">— Transclusion</tspan><tspan dx="26" fill="${C.faint}" font-weight="700">— revision</tspan></text>
    </g>`;

  const markers = Object.values(C)
    .filter((c) => c.startsWith("#") && c !== C.ink && c !== C.note && c !== C.noteBorder)
    .map(
      (c) => `<marker id="arr-${c.slice(1)}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
        <path d="M 0 0 L 10 5 L 0 10 z" fill="${c}"/>
      </marker>`,
    )
    .join("");

  const H = y + 64;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
    <defs>${markers}</defs>
    <rect width="${W}" height="${H}" fill="#ffffff"/>
    <text x="${W / 2}" y="14" text-anchor="middle" font-size="15" font-weight="700" fill="${C.ink}">The negotiation phase — four parties, one claim (sequence)</text>
    ${actors.map(actorBox).join("")}${lifelines}${body}${legend}
  </svg>`;
}

function networkSvg() {
  const W = 1360, H = 620;
  const nodes = {
    W2: { x: 170, y: 120, w: 210, h: 64, label: "Why Four Weeks\nStill Works", sub: "Ken" },
    W7: { x: 170, y: 330, w: 210, h: 64, label: "Review Notes", sub: "Priya" },
    W3: { x: 480, y: 40, w: 200, h: 60, label: "Support Ticket Log", sub: "Alex" },
    W4: { x: 480, y: 180, w: 200, h: 60, label: "Outage Report", sub: "Alex" },
    W5: { x: 480, y: 320, w: 200, h: 60, label: "User Survey", sub: "Alex" },
    W1: { x: 850, y: 175, w: 240, h: 78, label: "Release Cadence\nProposal", sub: "Marta" },
    W6: { x: 850, y: 440, w: 240, h: 74, label: "Release Cadence\nRecommendation", sub: "Alex (duplicate)" },
  };
  const box = (n) => `
    <rect x="${n.x}" y="${n.y}" width="${n.w}" height="${n.h}" rx="10" fill="#f6f8fa" stroke="${n.stroke ?? C.faint}" stroke-width="${n.strokeW ?? 1.5}"/>
    ${n.label.split("\n").map((l, i) => `<text x="${n.x + n.w / 2}" y="${n.y + (n.label.includes("\n") ? 24 : 26) + i * 17}" text-anchor="middle" font-size="14" font-weight="600" fill="${C.ink}">${esc(l)}</text>`).join("")}
    <text x="${n.x + n.w / 2}" y="${n.y + n.h - 10}" text-anchor="middle" font-size="12" fill="${C.faint}">${esc(n.sub)}</text>`;

  const edge = (a, b, color, label, dashed, bend = 0) => {
    const A = nodes[a], B = nodes[b];
    const x1 = a === "W1" ? A.x : A.x + A.w;
    const x2 = b === "W1" ? B.x + B.w : B.x;
    const y1 = A.y + A.h / 2;
    const y2 = B.y + B.h / 2;
    const mx = (x1 + x2) / 2;
    const my = (y1 + y2) / 2 + bend;
    return `
      <path d="M ${x1} ${y1} Q ${mx} ${my} ${x2} ${y2}" fill="none" stroke="${color}" stroke-width="2.5" ${dashed ? 'stroke-dasharray="7 5"' : ""} marker-end="url(#arr-${color.slice(1)})"/>
      <text x="${mx}" y="${my - 8 + bend / 2}" text-anchor="middle" font-size="12" fill="${C.ink}">${esc(label)}</text>`;
  };

  nodes.W1.stroke = C.disagreement; nodes.W1.strokeW = 2.5;
  nodes.W6.stroke = C.reference; nodes.W6.strokeW = 2;

  const body = [
    edge("W2", "W1", C.disagreement, "L1 dispute — retired to history"),
    edge("W7", "W1", C.comment, "L2 comment on L1 · L5 comment", true, -30),
    edge("W3", "W1", C.reference, "L3 gathered end — 1 of 3", false, -20),
    edge("W4", "W1", C.reference, "L3 gathered end — 2 of 3", false, 0),
    edge("W4", "W1", C.disagreement, "L4 dispute", true, 40),
    edge("W5", "W1", C.reference, "L3 gathered end — 3 of 3", false, 20),
    edge("W5", "W1", C.quotation, "transcluded live", false, 60),
    edge("W6", "W1", C.seeAlso, "L7 see also", true, 0),
    edge("W2", "W1", C.disagreement, "L6 standing dispute", false, 60),
  ].join("");

  const legend = `
    <g font-size="13">
      <text x="${W / 2 - 420}" y="${H - 18}"><tspan fill="${C.disagreement}" font-weight="700">— Disagreement</tspan><tspan dx="24" fill="${C.comment}" font-weight="700">— Comment</tspan><tspan dx="24" fill="${C.reference}" font-weight="700">— gathered Reference</tspan><tspan dx="24" fill="${C.quotation}" font-weight="700">— Transclusion</tspan><tspan dx="24" fill="${C.seeAlso}" font-weight="700">— See Also</tspan></text>
    </g>`;

  const markers = [C.disagreement, C.comment, C.reference, C.quotation, C.seeAlso, C.faint]
    .map(
      (c) => `<marker id="arr-${c.slice(1)}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
        <path d="M 0 0 L 10 5 L 0 10 z" fill="${c}"/>
      </marker>`,
    )
    .join("");

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
    <defs>${markers}</defs>
    <rect width="${W}" height="${H}" fill="#ffffff"/>
    <text x="${W / 2}" y="14" text-anchor="middle" font-size="15" font-weight="700" fill="${C.ink}">The final state — seven works, one deliberation (network)</text>
    ${Object.values(nodes).map(box).join("")}${body}${legend}
  </svg>`;
}

async function render(browser, svg, outFile) {
  const page = await browser.newPage({ viewport: { width: 1400, height: 700 }, deviceScaleFactor: 2 });
  await page.setContent(`<!doctype html><html><head><style>
    body { margin: 0; padding: 20px; background: #ffffff; }
    svg { display: block; }
  </style></head><body>${svg}</body></html>`, { waitUntil: "load" });
  await page.waitForTimeout(300);
  await page.screenshot({ path: outFile, fullPage: true });
  await page.close();
  console.log("saved", outFile.split("/").pop());
}

async function main() {
  const browser = await chromium.launch({ headless: true });
  await render(browser, sequenceSvg(), `${OUT}/07-negotiation-sequence.png`);
  await render(browser, networkSvg(), `${OUT}/08-final-network.png`);
  await browser.close();
}
main().catch((e) => { console.error(e); process.exit(1); });
