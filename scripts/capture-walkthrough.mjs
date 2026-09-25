#!/usr/bin/env node
// capture-walkthrough.mjs — step-by-step walkthrough chapters for the reel:
//
//   LINK   selecting text → +Add Link → target → second document → type
//          (Comment) → create → underline + panel row → hover tooltip
//   TRANS  source passage → the placed window (bars) → hover → edit the
//          source → the window updates
//   DIAL   one editor, a second session typing live (CRDT dialogue)
//
// Each step is a SCREENSHOT (docs/videos/reel/steps/*.png); the assembler
// turns each into a ~1.3s clip — "screenshots moving through the steps".
//
// Scratch works (Reel — *) are created idempotently so the editing is
// repeatable without touching the gallery.
// Usage: node scripts/capture-walkthrough.mjs [base-url]
import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import WebSocket from "ws";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BASE = process.argv[2] || "http://localhost:5173";
const WS_URL = "ws://127.0.0.1:8080/xudanu?format=json";
const PASS = process.env.XUDANU_ADMIN_PASSPHRASE || "greetingsforalltime";
const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.resolve(HERE, "../docs/videos/reel/steps");
fs.mkdirSync(OUT, { recursive: true });

// ── API helpers (scratch works, transclusion placement) ───────────────
const ws = new WebSocket(WS_URL, { headers: { origin: BASE } });
let nextId = 1;
const pending = new Map();
function request(op, payload) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    const t = setTimeout(() => { pending.delete(id); reject(new Error(`timeout: ${op}`)); }, 30000);
    pending.set(id, { resolve, reject, timeout: t, op });
    ws.send(JSON.stringify({ v: 2, type: "request", id, op, payload: payload ?? {} }));
  });
}
ws.on("message", (data) => {
  const frame = JSON.parse(data.toString());
  if (frame.type === "response" || frame.type === "error") {
    const p = pending.get(frame.id);
    if (p) { pending.delete(frame.id); clearTimeout(p.timeout);
      frame.type === "error" ? p.reject(new Error(`${p.op}: ${frame.message}`)) : p.resolve(frame.value); }
  }
});
// Capture open at construction: 'open' can fire before api() runs
// (e.g. during chromium.launch) and a later once("open") would hang.
const wsOpened = new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
const valueOf = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
// Unbuffered progress: survives SIGTERM, visible while running.
const log = (m) => fs.writeSync(1, `[walk] ${m}\n`);

async function api() {
  log("api: connecting ws");
  await wsOpened;
  log("api: session_connect");
  await request("session_connect");
  await request("session_login_public");
  const adminId = valueOf(await request("club_id_by_name", { name: "admin" }));
  await request("session_login", { club_id: adminId });
  await request("session_authenticate", { credential: { password: Array.from(PASS).map((c) => c.charCodeAt(0)) } });
}

async function findOrCreate(title, text) {
  log(`findOrCreate: ${title} (work_list)`);
  const res = valueOf(await request("work_list", { offset: 0, limit: 2000 }));
  log(`findOrCreate: list ok (${(res?.entries ?? []).length} entries)`);
  const found = (res?.entries ?? []).find((w) => w.title === title);
  if (found) { log(`findOrCreate: found 0x${found.work_id.toString(16)}`); return { id: found.work_id, isNew: false }; }
  log(`findOrCreate: creating ${title}`);
  const w = valueOf(await request("work_create", { edition: { text } }));
  const wid = typeof w === "number" ? w : w?.work_id;
  await request("work_set_title", { work_id: wid, title });
  await request("work_publish", { work_id: wid });
  // Sandbox rule: a public browser session may only edit works whose
  // edit club IS the public club. Admin-created works default to the
  // admin club — hand them to the public so the walkthrough can type.
  const publicClub = valueOf(await request("club_id_by_name", { name: "public" }));
  await request("work_set_edit_club", { work_id: wid, club_id: publicClub }).catch((e) =>
    log(`  (edit club: ${e.message.slice(0, 40)})`));
  log(`findOrCreate: created 0x${wid.toString(16)} (public-editable)`);
  return { id: wid, isNew: true };
}

// ── UI helpers ─────────────────────────────────────────────────────────
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1 });

let shotN = 0;
async function shot(name) {
  await page.screenshot({ path: path.join(OUT, `${name}.png`) });
  shotN++;
  console.log(`  ✓ ${name}`);
}

async function openWork(title, search = null, navigate = true) {
  if (navigate) {
    await page.goto(BASE);
    await sleep(2500);
  }
  const lib = page.locator("button", { hasText: /library/i }).first();
  try { await lib.click({ timeout: 2000 }); await sleep(700); } catch {}
  await page.waitForSelector(".ws-work-item", { timeout: 10000 });
  const box = page.locator("input[placeholder*='Search'], input[type='search']").first();
  try { if (await box.isVisible()) { await box.fill(search ?? title.slice(0, 20)); await sleep(600); } } catch {}
  await page.locator(".ws-work-item", { hasText: title.slice(0, 24) }).first().click({ timeout: 8000 });
  await sleep(1800);
}

// Bounding rect of a phrase inside the editor (for drag-select / hover).
async function phraseRect(phrase) {
  return page.evaluate((p) => {
    const ed = document.querySelector(".editor-content");
    if (!ed) return null;
    const walker = document.createTreeWalker(ed, NodeFilter.SHOW_TEXT);
    let node;
    while ((node = walker.nextNode())) {
      const i = (node.textContent || "").indexOf(p);
      if (i >= 0) {
        const r = document.createRange();
        r.setStart(node, i);
        r.setEnd(node, Math.min(i + p.length, node.textContent.length));
        const b = r.getBoundingClientRect();
        return { x: b.x, y: b.y + b.height / 2, w: b.width };
      }
    }
    return null;
  }, phrase);
}

async function dragSelect(phrase) {
  const r = await phraseRect(phrase);
  if (!r) throw new Error(`phrase not found: ${phrase.slice(0, 30)}`);
  await page.mouse.move(r.x + 2, r.y);
  await page.mouse.down();
  await page.mouse.move(r.x + r.w - 4, r.y, { steps: 14 });
  await page.mouse.up();
  await sleep(400);
}

async function connectionsTab() {
  const tab = page.locator("button", { hasText: "Links" }).last();
  try { await tab.click({ timeout: 6000 }); await sleep(900); } catch {}
}

// The right panel re-renders often enough that located elements can
// detach between find and click — poll until present, then click fast.
async function clickPolled(text, ms = 12000) {
  const end = Date.now() + ms;
  let lastErr;
  while (Date.now() < end) {
    const loc = page.locator("button", { hasText: text }).first();
    try { await loc.click({ timeout: 1500 }); return; } catch (e) { lastErr = e; await sleep(400); }
  }
  throw lastErr ?? new Error(`poll timeout: ${text}`);
}

// The identity badge (top bar) opens the identity modal for any
// session; sign in as admin so canEdit is true and +Add Link appears.
// (The More▸Identities sub-tab is admin-gated and vanishes for public
// sessions mid-render — the badge is the stable path.)
async function loginAsAdmin() {
  await page.goto(BASE);
  await sleep(2500);
  await page.locator(".identity-badge").first().click({ timeout: 8000 });
  await sleep(1000);
  const signin = page.locator("button", { hasText: "Sign in" }).first();
  try { await signin.click({ timeout: 3000 }); await sleep(600); } catch {}
  await page.locator("input[placeholder=\"Identity name\"]").fill("admin");
  await page.locator("input[placeholder=\"Password\"]").fill(PASS);
  await page.locator("button.identity-submit").first().click();
  await sleep(2200);
  try { await page.locator("button.identity-form-close, button.ws-anno-cancel").first().click({ timeout: 1500 }); } catch {}
  log("login: admin signed in via identity badge");
}

const CHAPTER = process.argv[3] || "all";

// ── setup: scratch works ───────────────────────────────────────────────
log(`start (chapter=${CHAPTER})`);
await api();
log("api: authenticated");
const A_TEXT = `Margins and Marks

This page exists to make one connection. Select the words below, press Add Link, and give the sentence a second end somewhere else.

The marginal note is the smallest act of reading aloud.`;
const B_TEXT = `The Far Bank

A quiet document, waiting to be the other end of something.`;
const SRC_TEXT = `The Living Source

This paragraph is about to be borrowed whole. Words that live here will appear somewhere else, and when they change here, they change there.`;
const MIR_TEXT = `The Mirror

Below this line, a window: not a copy, not a quote — the text itself, living in another document.

`;

const docA = await findOrCreate("Reel — Margins and Marks", A_TEXT);
const docB = await findOrCreate("Reel — The Far Bank", B_TEXT);
const docSrc = await findOrCreate("Reel — The Living Source", SRC_TEXT);
const docMir = await findOrCreate("Reel — The Empty Mirror", MIR_TEXT);
console.log(`  scratch works: A=0x${docA.id.toString(16)} B=0x${docB.id.toString(16)} src=0x${docSrc.id.toString(16)} mir=0x${docMir.id.toString(16)}`);

// ── CHAPTER: LINK ──────────────────────────────────────────────────────
if (CHAPTER === "all" || CHAPTER === "link") {
  console.log("\nLINK walkthrough");
  await loginAsAdmin();
  await openWork("Reel — Margins and Marks", null, false);
  await connectionsTab();
  await shot("link-00-open");
  await dragSelect("The marginal note is the smallest act of reading aloud");
  await shot("link-01-selected");

  await clickPolled("+ Add Link");
  await sleep(900);
  await shot("link-02-target-step");

  await page.locator(".link-target-name", { hasText: "specific text in another document" }).first().click({ timeout: 5000 });
  await sleep(900);
  await shot("link-03-chose-text-target");

  // Navigate to the far bank and select there — the two-part flow:
  // the creator closes and arms an action bar ("select target text");
  // the selection in doc B reveals inline type buttons.
  await openWork("Reel — The Far Bank", null, false);
  await sleep(1200);
  await shot("link-04a-target-hint");
  await dragSelect("A quiet document, waiting to be the other end");
  await sleep(800);
  await shot("link-04-second-end-selected");

  const comment = page.locator(".link-type-btn", { hasText: "Comment" }).first();
  try {
    await comment.waitFor({ timeout: 8000 });
    await shot("link-05-type-choice");
    await comment.click();
    await sleep(1600);
    await shot("link-06-created");
  } catch (e) {
    console.log(`  (type bar: ${String(e.message).slice(0, 60)})`);
  }

  // Close any creator/done overlay, show the result + tooltip
  try { await page.locator(".link-creator-close").first().click({ timeout: 2000 }); await sleep(600); } catch {}
  await shot("link-07-result");
  try {
    await dragSelect("The marginal note is the smallest act of reading aloud");
    const r = await phraseRect("The marginal note is the smallest act");
    if (r) { await page.mouse.move(r.x + r.w / 2, r.y + 14); await sleep(1400); await shot("link-08-tooltip"); }
  } catch {}
}

// ── CHAPTER: TRANSCLUSION LIFECYCLE ────────────────────────────────────
if (CHAPTER === "all" || CHAPTER === "trans") {
  console.log("\nTRANSCLUSION lifecycle");
  await openWork("Reel — The Living Source");
  await dragSelect("Words that live here will appear somewhere else");
  await shot("trans-01-source-passage");

  await openWork("Reel — The Mirror");
  await sleep(1200);
  await shot("trans-02-window-placed");
  try {
    const r = await phraseRect("will appear somewhere else");
    if (r) { await page.mouse.move(r.x + r.w / 2, r.y + 14); await sleep(1500); await shot("trans-03-window-hover"); }
  } catch {}

  // Edit the source; the window must follow.
  await openWork("Reel — The Living Source");
  try {
    const r = await phraseRect("and when they change here");
    if (r) {
      await page.mouse.click(r.x + r.w + 6, r.y);
      await sleep(300);
      await page.keyboard.type(" — slowly, but visibly —", { delay: 60 });
      await sleep(2600); // let CRDT autosave settle into a revision
      await shot("trans-04-source-edited");
    }
  } catch (e) { console.log(`  (edit: ${String(e.message).slice(0, 60)})`); }

  await openWork("Reel — The Mirror");
  await sleep(1500);
  await shot("trans-05-window-updated");
}

// ── CHAPTER: DIALOGUE (two sessions, one document) ─────────────────────
if (CHAPTER === "all" || CHAPTER === "dial") {
  console.log("\nDIALOGUE scene");
  await openWork("Reel — Margins and Marks");
  await shot("dial-01-open");

  // Second session: a public user types into the same work while we film.
  const ws2 = new WebSocket(WS_URL, { headers: { origin: BASE } });
  let id2 = 1;
  const pend2 = new Map();
  const req2 = (op, payload) => new Promise((res, rej) => {
    const i = id2++;
    pend2.set(i, { res, rej });
    ws2.send(JSON.stringify({ v: 2, type: "request", id: i, op, payload: payload ?? {} }));
  });
  ws2.on("message", (d) => {
    const f = JSON.parse(d);
    const p = pend2.get(f.id);
    if (p) { pend2.delete(f.id); f.type === "error" ? p.rej(new Error(f.message)) : p.res(f.value); }
  });
  await new Promise((res) => ws2.once("open", res));
  await req2("session_connect");
  await req2("session_login_public");
  // subscribe to the same work so our page receives the live deltas
  await req2("work_subscribe", { work_id: docA.id }).catch(() => {});
  await shot("dial-02-second-cursor");

  try {
    const pos = A_TEXT.length;
    await req2("work_revise_delta", {
      work_id: docA.id,
      ops: [
        { type: "retain", count: pos },
        { type: "insert", text: "\n\nAnd a second voice arrives from another window, uninvited and welcome." },
      ],
    });
    await sleep(2200);
    await shot("dial-03-second-voice");
  } catch (e) { console.log(`  (dialogue delta: ${String(e.message).slice(0, 60)})`); }
  try { ws2.close(); } catch {}
}

await browser.close();
ws.close();
console.log(`\nDONE — ${shotN} step screenshots in ${OUT}`);
process.exit(0);
