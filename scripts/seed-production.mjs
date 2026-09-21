#!/usr/bin/env node
// seed-production.mjs — rebuild the "Welcome to Xudanu" demo document on a
// production server: markdown headings (H1/H2), bold annotations, five typed
// links with span anchors + tooltip descriptions, and a hero image blob.
//
// Usage: node scripts/seed-production.mjs https://xudanu.com [--fresh]
//
// Auth: seeded personal identity ("Xudanu Demo") — the same path the web
// UI uses. NO CREDENTIALS LIVE IN THIS REPO. Resolution order:
//   1. XUDANU_DEMO_PASSWORD env var
//   2. scripts/.seed-credentials (gitignored, 0600) — created on first
//      run with a generated password if absent
// If the identity exists and the password no longer matches, the script
// fails: rotate it out-of-band (sign in with the current password, use
// club_set_password), then update the credentials file.
// Idempotent: reuses source works by title; recreates the Welcome doc only
// with --fresh.

import { randomBytes } from "node:crypto";
import { existsSync, readFileSync, writeFileSync, chmodSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const BASE = process.argv[2] || "https://xudanu.com";
const FRESH = process.argv.includes("--fresh");

const DEMO_IDENTITY = "Xudanu Demo";

function resolveDemoPassword() {
  if (process.env.XUDANU_DEMO_PASSWORD) {
    return process.env.XUDANU_DEMO_PASSWORD;
  }
  const credFile = join(dirname(fileURLToPath(import.meta.url)), ".seed-credentials");
  if (existsSync(credFile)) {
    const pw = readFileSync(credFile, "utf8").trim();
    if (pw) return pw;
  }
  const generated = randomBytes(24).toString("base64url");
  try {
    writeFileSync(credFile, generated + "\n", { mode: 0o600, flag: "wx" });
  } catch (e) {
    if (e.code === "EEXIST") {
      const existing = readFileSync(credFile, "utf8").trim();
      if (existing) return existing;
    }
    throw e;
  }
  try { chmodSync(credFile, 0o600); } catch { /* fs perm best-effort */ }
  console.log(`first run: generated demo credential -> ${credFile} (gitignored, 0600)`);
  return generated;
}

const DEMO_PASSWORD = resolveDemoPassword();

const WELCOME_TITLE = "Welcome to Xudanu";

const SOURCE_WORKS = [
  { title: "Privacy Statute", text: "All persons shall have the right to privacy in their personal communications. This right shall not be infringed without due process of law. The protection of privacy extends to digital communications, including but not limited to electronic mail, messaging, and online transactions. Any surveillance of private communications must be authorized by a warrant, supported by probable cause, and narrowly tailored to achieve a legitimate government interest." },
  { title: "Case Law: Digital Privacy", text: "The court held that privacy extends to digital communications. In a landmark decision, the justices ruled that government surveillance of electronic communications requires a warrant. The decision established that citizens have a reasonable expectation of privacy in their digital data. This expectation covers not only the content of communications but also metadata, location data, and browsing history." },
  { title: "Dissenting Opinion", text: "I dissent. The majority's expansion of the privacy right goes beyond what the constitution provides. While digital communications deserve protection, the majority's blanket approach fails to balance legitimate law enforcement needs. We should require warrants only for content, not for metadata, which has long been held to carry no reasonable expectation of privacy. The majority opinion, however well-intentioned, will hamper legitimate investigations." },
  { title: "Legal Brief: Privacy Now", text: "Our client's communications were seized without a warrant, in violation of the established right to privacy. We move to suppress all evidence obtained through this unconstitutional surveillance. The precedents are clear: content, metadata, and location data alike are protected when the seizure is warrantless and suspicionless.\n\nConclusion\n\nWe maintain that privacy is a human right that must be protected against any backdoor." },
];

const WELCOME_TEXT = [
  "# Welcome to Xudanu",
  "",
  "A connected literature where every quotation maintains its bond to the original.",
  "",
  "This document contains live examples you can interact with right now. Try hovering the coloured underlines below, then try the features described.",
  "",
  "## Links you can hover now",
  "",
  "The five lines below each have a different typed link. Hover each one to see the tooltip:",
  "",
  "Line 1 has a Comment link (blue dashed).",
  "Line 2 has a Reference link (green solid).",
  "Line 3 has a Disagreement link (red long dash).",
  "Line 4 has a Quotation link (purple dotted).",
  "Line 5 has a See Also link (amber dash-dot).",
  "",
  "Each link connects this passage to one of the source documents in the library. Click a link to navigate. Double-click to see connections.",
  "",
  "## Trace provenance",
  "",
  "If you open the Legal Brief document, you will see coloured transclusion markers (bars on the left margin). Hover any marker and click Trace provenance to see the recursive chain back to the original author. This is Gold's signature feature.",
  "",
  "## Attribution",
  "",
  "Click Show Prov in the top toolbar. You will see colour-coded backgrounds showing who wrote each section. Green means human-authored. This is court-grade attribution with Ed25519 signatures.",
  "",
  "## Getting started",
  "",
  "1. Click Browse Library to see all documents",
  "2. Open any document to explore",
  "3. Toggle Write in the top bar to start editing",
  "4. Select text and click Link to create your own connections",
  "5. Select text and click Transclude to quote from another document",
  "",
  "Xudanu implements Ted Nelson's 1960 vision: a docuverse where content is connected, not copied. Where every quotation traces back to its source. Where links are bidirectional and permanent.",
].join("\n");

// 1=Comment 2=Reference 3=Disagreement 4=Quotation 5=SeeAlso
const TYPED_LINKS = [
  { phrase: "Line 1 has a Comment link", destTitle: "Privacy Statute", type: 1, desc: "Comment: the statute is the anchor for the privacy discussion" },
  { phrase: "Line 2 has a Reference link", destTitle: "Case Law: Digital Privacy", type: 2, desc: "Reference: the case law interprets the statute" },
  { phrase: "Line 3 has a Disagreement link", destTitle: "Dissenting Opinion", type: 3, desc: "Disagreement: the dissent rejects the majority's reading" },
  { phrase: "Line 4 has a Quotation link", destTitle: "Legal Brief: Privacy Now", type: 4, desc: "Quotation: the brief quotes the constitutional principle" },
  { phrase: "Line 5 has a See Also link", destTitle: "Privacy Statute", type: 5, desc: "See Also: related primary source" },
];

const BOLD_PHRASES = [
  "A connected literature where every quotation maintains its bond to the original.",
  "Trace provenance",
  "Show Prov",
  "court-grade attribution with Ed25519 signatures",
  "content is connected, not copied",
];

class Client {
  constructor() { this.ws = null; this.reqId = 0; this.pending = new Map(); this.rawSessionId = null; }
  async connect(url) {
    const WebSocketMod = (await import("ws")).default;
    this.ws = new WebSocketMod(url, { headers: { Origin: BASE } });
    this.ws.binaryType = "arraybuffer";
    this.ws.addEventListener("message", (ev) => this.onMsg(ev.data));
    await new Promise((res, rej) => {
      this.ws.addEventListener("open", res, { once: true });
      this.ws.addEventListener("error", () => rej(new Error("ws connect failed")), { once: true });
    });
  }
  onMsg(data) {
    const text = typeof data === "string" ? data : new TextDecoder().decode(data);
    // u64 ids exceed JS safe integers: capture the session id verbatim
    // from the raw text before lossy JSON.parse rounds it.
    const m = text.match(/"op":"session_connect"|"type":"id","value":(\d{16,})/);
    if (m && m[1]) this.rawSessionId = m[1];
    const frame = JSON.parse(text);
    if (frame.type === "response" || frame.type === "error") {
      const h = this.pending.get(frame.id);
      if (h) {
        this.pending.delete(frame.id);
        frame.type === "error" ? h.reject(new Error(frame.message || "error")) : h.resolve(frame.value);
      }
    }
  }
  send(op, payload) {
    const id = ++this.reqId;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.ws.send(JSON.stringify({ v: 2, type: "request", id, op, ...(payload !== undefined ? { payload } : {}) }));
      setTimeout(() => { if (this.pending.has(id)) { this.pending.delete(id); reject(new Error(op + " timed out")); } }, 15000);
    });
  }
  async val(op, payload) {
    const r = await this.send(op, payload);
    let v = r;
    while (v && typeof v === "object" && !Array.isArray(v) && "value" in v && Object.keys(v).length <= 2) v = v.value;
    return v;
  }
}

async function main() {
  const csrfResp = await fetch(`${BASE}/csrf-token`);
  const { csrf_token } = await csrfResp.json();
  const client = new Client();
  await client.connect(`${BASE.replace("https", "wss")}/xudanu?format=json&version=2&csrf_token=${csrf_token}`);
  console.log("connected");

  const sid = await client.val("session_connect");
  const safeSid = String(client.rawSessionId || sid).replace(/[^a-zA-Z0-9]/g, "");
  console.log("session", safeSid);
  await client.send("session_login_public");
  try {
    await client.val("club_create_personal", {
      display_name: DEMO_IDENTITY,
      password: Array.from(new TextEncoder().encode(DEMO_PASSWORD)),
    });
    console.log(`identity "${DEMO_IDENTITY}" created`);
  } catch (e) {
    if (!/exists/i.test(String(e.message))) throw e;
    console.log(`identity "${DEMO_IDENTITY}" already exists`);
  }
  await client.send("session_login_by_name", { club_name: DEMO_IDENTITY });
  try {
    await client.send("session_authenticate", {
      credential: { password: Array.from(new TextEncoder().encode(DEMO_PASSWORD)) },
    });
  } catch {
    console.error(
      `authentication failed for "${DEMO_IDENTITY}". The stored credential no longer matches.\n` +
      `Rotate out-of-band (sign in with the current password, call club_set_password),\n` +
      `then update scripts/.seed-credentials or export XUDANU_DEMO_PASSWORD.`
    );
    process.exit(1);
  }
  console.log("demo identity authenticated");

  const listVal = await client.val("work_list", {});
  const entries = (listVal && (listVal.entries || listVal)) || [];
  console.log(`existing works: ${entries.length}`);
  const byTitle = new Map(entries.map((e) => [e.title, e.work_id]));

  // Source works: reuse or create
  const sourceIds = {};
  for (const src of SOURCE_WORKS) {
    if (byTitle.has(src.title)) {
      sourceIds[src.title] = byTitle.get(src.title);
      console.log(`reuse  ${src.title} -> ${sourceIds[src.title]}`);
    } else {
      const id = await client.val("work_create", { edition: { text: `${src.title}\n\n${src.text}` } });
      sourceIds[src.title] = id;
      await client.send("work_publish", { work_id: id });
      console.log(`create ${src.title} -> ${id}`);
    }
  }

  // Welcome doc
  let welcomeId = byTitle.get(WELCOME_TITLE);
  if (welcomeId && FRESH) {
    await client.send("work_archive", { work_id: welcomeId });
    welcomeId = undefined;
    console.log("archived old Welcome doc");
  }
  if (!welcomeId) {
    welcomeId = await client.val("work_create", { edition: { text: WELCOME_TEXT } });
    console.log(`Welcome doc created -> ${welcomeId}`);
  } else {
    console.log(`Welcome doc exists -> ${welcomeId} (use --fresh to rebuild)`);
  }

  // Hero image: upload blob, insert as element right after the H1 line.
  // The blob occupies one character position, shifting later text by 1 —
  // spans below account for it (computed against WELCOME_TEXT locally).
  const fs = await import("node:fs");
  const heroPath = process.env.XUDANU_SEED_HERO || new URL("./seed-assets/hero.png", import.meta.url).pathname;
  const imgBytes = new Uint8Array(fs.readFileSync(heroPath));
  const h1 = "# Welcome to Xudanu";
  const insertAt = WELCOME_TEXT.indexOf(h1) + h1.length + 1; // after heading + newline
  const uploadResp = await fetch(`${BASE}/api/blob/upload`, {
    method: "POST",
    headers: { "Content-Type": "image/png", "X-Xudanu-Session": client.rawSessionId || String(sid) },
    body: imgBytes,
  });
  if (uploadResp.ok) {
    const meta = await uploadResp.json();
    await client.send("element_insert", {
      work_id: welcomeId,
      position: insertAt,
      element: { type: "blob", blob_hash: meta.content_hash, blob_mime: meta.mime_type, blob_size: meta.byte_size, blob_width: meta.width, blob_height: meta.height },
    });
    console.log(`hero image inserted at ${insertAt} (hash ${meta.content_hash})`);
  } else {
    console.warn("image upload failed:", uploadResp.status, await uploadResp.text());
  }

  // Spans computed against the known seed text; shift past the image blob.
  const shift = (span) => (span.start >= insertAt ? { start: span.start + 1, end: span.end + 1 } : span);
  const spanOf = (phrase) => {
    const start = WELCOME_TEXT.indexOf(phrase);
    return start >= 0 ? shift({ start, end: start + phrase.length }) : null;
  };

  // Typed links with span anchors + tooltip annotations
  let annId = Date.now();
  for (const tl of TYPED_LINKS) {
    const span = spanOf(tl.phrase);
    if (!span) { console.warn(`phrase not found: ${tl.phrase}`); continue; }
    const linkId = await client.val("link_create", {
      origin: welcomeId,
      destination: sourceIds[tl.destTitle],
      origin_ref: { kind: "single", work_context: welcomeId, original_context: null, path_context: null, excerpt: tl.phrase, start_position: span.start, end_position: span.end },
    });
    await client.send("link_set_types", { link_id: linkId, link_types: [tl.type] });
    await client.send("annotation_create", {
      work_id: welcomeId, annotation_id: annId++, kind: "link-description",
      payload: JSON.stringify({ link_id: linkId, text: tl.desc }),
      char_start: span.start, char_end: span.end,
    });
    console.log(`link ${linkId} type ${tl.type} [${span.start}:${span.end}] -> ${tl.destTitle}`);
  }

  // Bold annotations
  for (const phrase of BOLD_PHRASES) {
    const span = spanOf(phrase);
    if (!span) { console.warn(`bold phrase not found: ${phrase}`); continue; }
    await client.send("annotation_create", {
      work_id: welcomeId, annotation_id: annId++, kind: "bold", payload: "",
      char_start: span.start, char_end: span.end,
    });
    console.log(`bold [${span.start}:${span.end}] "${phrase.slice(0, 40)}"`);
  }

  // Links between source documents
  const interLinks = [
    ["Privacy Statute", "Case Law: Digital Privacy", 2],
    ["Legal Brief: Privacy Now", "Privacy Statute", 2],
    ["Legal Brief: Privacy Now", "Dissenting Opinion", 3],
    ["Legal Brief: Privacy Now", "Case Law: Digital Privacy", 4],
    ["Dissenting Opinion", "Case Law: Digital Privacy", 5],
  ];
  for (const [a, b, t] of interLinks) {
    const linkId = await client.val("link_create", { origin: sourceIds[a], destination: sourceIds[b] });
    await client.send("link_set_types", { link_id: linkId, link_types: [t] });
  }
  console.log(`${interLinks.length} inter-source links created`);

  await client.send("work_publish", { work_id: welcomeId });
  console.log("published. done.");
  process.exit(0);
}

main().catch((e) => { console.error("seed failed:", e.message); process.exit(1); });
