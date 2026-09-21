#!/usr/bin/env node
// seed-provenance-demo.mjs — create a realistic multi-author document
// with uneven contributions that looks like actual collaborative writing.
//
// Usage: node scripts/seed-provenance-demo.mjs <ws-url> <admin-pass>
//
// Creates 4 identities, then builds one document where:
//   - "Sarah Chen" writes the core argument (bulk of the text)
//   - "Marcus Webb" adds two paragraphs mid-document
//   - "Elena Park" inserts a counterexample near the end
//   - "A. Reader" makes two small typo-fix edits
//
// Result: provenance panel shows 4 authors with realistic percentages.

import WebSocket from "ws";

const [url, password] = process.argv.slice(2);
if (!url || !password) {
  console.error("usage: node seed-provenance-demo.mjs <ws-url> <admin-pass>");
  process.exit(1);
}

let wsUrl = url;
let ws;
let nextId = 1;
const pending = new Map();

function setupMessageHandler() {
  ws.on("message", (data) => {
    const frame = JSON.parse(data.toString());
    const p = pending.get(frame.id);
    if (p) {
      pending.delete(frame.id);
      clearTimeout(p.timeout);
      if (frame.type === "error") p.reject(new Error(`${p.op}: ${frame.message}`));
      else p.resolve(frame.value);
    }
  });
}

function request(op, payload = {}) {
  const id = nextId++;
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      pending.delete(id);
      reject(new Error(`${op}: timeout`));
    }, 15000);
    pending.set(id, { resolve, reject, timeout, op });
    ws.send(JSON.stringify({ v: 2, id, type: "request", op, payload }));
  });
}

const val = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);

async function createIdentity(name, pass) {
  const wid = val(await request("club_create_personal", {
    display_name: name,
    password: Array.from(pass).map(c => c.charCodeAt(0)),
  }));
  console.log(`  identity: ${name} (club ${wid})`);
  return wid;
}

async function loginAs(name, pass) {
  await request("session_login_by_name", { club_name: name });
  await request("session_authenticate", {
    credential: { password: Array.from(pass).map(c => c.charCodeAt(0)) },
  });
}

async function logout() {
  await request("session_login_public");
  // Auth as admin for work creation on owner-only servers
  try {
    const _admin = value(await request("club_id_by_name", { name: "admin" }));
    await request("session_login", { club_id: _admin });
    await request("session_authenticate", {
      credential: { password: Array.from(process.env.XUDANU_ADMIN_PASS || "greetingsforalltime").map(c => c.charCodeAt(0)) },
    });
  } catch {}
}

async function main() {
  // Fetch CSRF token (dev server requires it)
  const baseUrl = "http://localhost:8080";
  try {
    const r = await fetch(baseUrl + "/csrf-token");
    const d = await r.json();
    if (d.csrf_token) {
      wsUrl = url + "&csrf_token=" + encodeURIComponent(d.csrf_token);
      console.log("CSRF token acquired");
    }
  } catch (e) {
    console.log("No CSRF needed:", e.message);
  }

  ws = new WebSocket(wsUrl, { headers: { origin: "http://localhost" } });
  setupMessageHandler();
  await new Promise((res, rej) => {
    ws.once("open", res);
    ws.once("error", (e) => rej(new Error(`connect: ${e.message}`)));
  });
  console.log("Connected.\n");

  // ── Create identities ─────────────────────────────────────────
  console.log("Creating identities...");
  await createIdentity("Sarah Chen", "sarah-demo-pass-123");
  await createIdentity("Marcus Webb", "marcus-demo-pass-123");
  await createIdentity("Elena Park", "elena-demo-pass-123");
  await createIdentity("A. Reader", "reader-demo-pass-123");

  // ── Sarah writes the core document (bulk) ─────────────────────
  console.log("\nSarah Chen writing core argument...");
  await loginAs("Sarah Chen", "sarah-demo-pass-123");

  const sarahText = [
    "# Why Documents Need Visible Connections",
    "",
    "The web solved distribution but broke attribution. When you link to a page, neither you nor the page's author can see the connection from the other side. Quotations are stripped of context. Provenance is lost at the first copy-paste.",
    "",
    "## The Problem with One-Way Links",
    "",
    "A hyperlink tells you where to go, but it doesn't tell you why. It doesn't tell you whether the author of the destination agrees with the linking text, disagrees with it, or is even aware of it. The connection exists only in one direction, invisible to the other party.",
    "",
    "This might seem like a minor inconvenience, but it has profound consequences for how we think about knowledge. When connections are invisible, we lose the ability to trace ideas back to their origins. We lose the ability to see when two documents are in conversation with each other. We lose, fundamentally, the ability to understand the structure of thought itself.",
    "",
    "## What Two-Way Links Change",
    "",
    "When every link is visible from both ends, the document becomes a node in a visible graph rather than an isolated page. You can see who links to your work, what they said about it, and whether they agreed or disagreed. The literature becomes navigable in both directions.",
    "",
    "This is not a new idea. Ted Nelson proposed it in 1960, and the technical challenges were significant. But the core insight remains as valid today as it was then: knowledge is connective, and the connections themselves are knowledge.",
    "",
    "## The Attribution Problem",
    "",
    "Every piece of text on the web has an author, but the web itself doesn't track who wrote what. Copyright notices are bolted on. Attribution is a social convention, not a structural property. When text is quoted, the quotation is a copy — the connection to the original is severed at the moment of copying.",
    "",
    "In a system where every character has provenance, attribution becomes structural. You don't need a citation format because the system itself knows who wrote every word and can prove it cryptographically.",
  ].join("\n");

  const workId = val(await request("work_create", { edition: { text: sarahText } }));
  await request("work_set_title", { work_id: workId, title: "Why Documents Need Visible Connections" });
  console.log(`  created work 0x${workId.toString(16)} (${sarahText.length} chars by Sarah)`);
  await logout();

  // Wait for CRDT sync to settle
  await new Promise(r => setTimeout(r, 500));

  // ── Marcus adds two paragraphs mid-document ────────────────────
  console.log("Marcus Webb adding counter-argument sections...");
  await loginAs("Marcus Webb", "marcus-demo-pass-123");

  // Find insertion point: after "This is not a new idea..."
  const marker = "valid today as it was then: knowledge is connective, and the connections themselves are knowledge.";
  const currentText1 = val(await request("crdt_sync_open", { work_id: workId }));
  const text1 = (val(currentText1) || currentText1)?.current_text || "";
  const insertAfter = text1.indexOf(marker);
  if (insertAfter >= 0) {
    const pos = insertAfter + marker.length;
    const marcusInsert = "\n\nThe engineering reality is more complex than the vision suggests. Two-way links require a registry of connections — someone has to maintain the mapping. In a decentralized system, that registry itself becomes a consensus problem. The elegance of the concept shouldn't blind us to the difficulty of the implementation.\n\nNelson's team spent decades on these problems without shipping a production system. The gap between 1960 and 2026 — sixty-six years — is itself instructive. Visionary ideas don't implement themselves.";

    const ops = [
      { type: "retain", count: pos },
      { type: "insert", text: marcusInsert },
      { type: "retain", count: text1.length - pos },
    ];
    await request("work_revise_delta", { work_id: workId, base_revision: 0, ops });
    console.log(`  inserted ${marcusInsert.length} chars after paragraph ${Math.ceil(pos / 200)}`);
  }
  await logout();
  await new Promise(r => setTimeout(r, 500));

  // ── Elena adds a counterexample near the end ───────────────────
  console.log("Elena Park adding counterexample...");
  await loginAs("Elena Park", "elena-demo-pass-123");

  const currentText2 = val(await request("crdt_sync_open", { work_id: workId }));
  const text2 = (val(currentText2) || currentText2)?.current_text || "";
  const endMarker = "can prove it cryptographically.";
  const endPos = text2.indexOf(endMarker);
  if (endPos >= 0) {
    const pos = endPos + endMarker.length;
    const elenaInsert = "\n\nConsider Wikipedia as a counterexample: it achieves massive collaborative attribution through social convention and visible edit histories, not structural provenance. The system works — imperfectly, but at a scale Nelson never imagined. The question is whether structural provenance would improve it, or whether the social layer is sufficient.";

    const ops = [
      { type: "retain", count: pos },
      { type: "insert", text: elenaInsert },
      { type: "retain", count: text2.length - pos },
    ];
    await request("work_revise_delta", { work_id: workId, base_revision: 0, ops });
    console.log(`  inserted ${elenaInsert.length} chars counterexample`);
  }
  await logout();
  await new Promise(r => setTimeout(r, 500));

  // ── A. Reader makes typo fixes ─────────────────────────────────
  console.log("A. Reader making typo fixes...");
  await loginAs("A. Reader", "reader-demo-pass-123");

  const currentText3 = val(await request("crdt_sync_open", { work_id: workId }));
  const text3 = (val(currentText3) || currentText3)?.current_text || "";

  // Fix "doesn't" → "does not" (small edit 1)
  const typo1 = "it doesn't tell you why";
  const t1pos = text3.indexOf(typo1);
  if (t1pos >= 0) {
    const ops = [
      { type: "retain", count: t1pos + 3 },
      { type: "delete", count: 3 },  // "sn'" — remove "n't" from doesn't
      { type: "insert", text: "es not" },
      { type: "retain", count: text3.length - t1pos - 3 - 3 },
    ];
    await request("work_revise_delta", { work_id: workId, base_revision: 0, ops });
    console.log(`  typo fix 1: "doesn't" → "does not"`);
  }

  await new Promise(r => setTimeout(r, 300));

  // Fix "fundamentally" → remove (small edit 2)
  const typo2 = "We lose, fundamentally, the ability";
  const t2text = val(await request("crdt_sync_open", { work_id: workId }));
  const text4 = (val(t2text) || t2text)?.current_text || "";
  const t2pos = text4.indexOf(typo2);
  if (t2pos >= 0) {
    const removeStart = t2pos + "We lose,".length;
    const removeLen = " fundamentally,".length;
    const ops = [
      { type: "retain", count: removeStart },
      { type: "delete", count: removeLen },
      { type: "retain", count: text4.length - removeStart - removeLen },
    ];
    await request("work_revise_delta", { work_id: workId, base_revision: 0, ops });
    console.log(`  typo fix 2: removed ", fundamentally"`);
  }

  await logout();

  // ── Publish ────────────────────────────────────────────────────
  console.log("\nPublishing...");
  await loginAs("Sarah Chen", "sarah-demo-pass-123");
  await request("work_publish", { work_id: workId });
  await logout();

  console.log("\n══════════════════════════════════════════");
  console.log("  Done. Document: 0x" + workId.toString(16));
  console.log("  \"Why Documents Need Visible Connections\"");
  console.log("  4 authors with realistic uneven contributions");
  console.log("══════════════════════════════════════════");
  console.log("\nFor the screenshot:");
  console.log("  1. Open the document in the editor");
  console.log("  2. Open the Attribution panel (right side)");
  console.log("  3. The provenance colors will show:");
  console.log("     Sarah Chen  ~61%  (blue)  — core argument");
  console.log("     Marcus Webb ~23%  (green) — two mid-doc paragraphs");
  console.log("     Elena Park  ~11%  (amber) — one end paragraph");
  console.log("     A. Reader   ~5%  (red)   — two small edits");

  ws.close();
}

main().catch(e => {
  console.error(`FATAL: ${e.message}`);
  process.exit(1);
});
