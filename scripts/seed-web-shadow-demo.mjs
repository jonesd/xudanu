#!/usr/bin/env node
// seed-web-shadow-demo.mjs — FR-79 Iter 2: "Room 11 — The Disagreed
// Article", the web-shadow demo room.
//
// A real web article (Wikipedia's Project Xanadu page) is shadowed
// via the web_shadow op; a Room 11 work disagrees with a passage of
// it via a Disagreement link; the lobby floor plan gains the room.
// The shadow's banner shows the live window (source URL, refetch);
// the disagreement row offers ⇄ compare against the shadowed text.
//
// Usage:
//   XUDANU_ADMIN_PASSPHRASE=<pass> node scripts/seed-web-shadow-demo.mjs
//   (optional) SEED_WS=ws://host:port/xudanu?format=json  SEED_ORIGIN=...
//
// Idempotent: keyed by work titles; skips existing pieces.
import WebSocket from "ws";

const url = process.env.SEED_WS ?? "ws://127.0.0.1:8080/xudanu?format=json";
const pass = process.env.XUDANU_ADMIN_PASSPHRASE;
const SHADOW_URL = "https://en.wikipedia.org/wiki/Project_Xanadu";
const ws = new WebSocket(url, { headers: { origin: process.env.SEED_ORIGIN ?? "http://localhost:5173" } });

let nextId = 1;
const pending = new Map();
function request(op, payload) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    const t = setTimeout(() => { pending.delete(id); reject(new Error(`timeout: ${op}`)); }, 60000);
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
const valueOf = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);
const spanIn = (text, marker) => {
  const i = text.indexOf(marker);
  if (i < 0) throw new Error(`marker not found: ${marker.slice(0, 40)}`);
  return { start: i, end: i + marker.length };
};

const ROOM_TITLE = "Gallery — Wing III · Room 11: The Disagreed Article";
const GLOSS_TITLE = "Gallery Annex — The Shadow Gloss";
const LOBBY_TITLE = "Gallery — Lobby: The Gallery of Unusual Connections";
const LOBBY_APPENDIX = "\n\nAND ONE WINDOW — onto the open web.\nRoom 11: The Disagreed Article — a page from the open web, shadowed and disagreed with.";

const roomText = `The Disagreed Article

This room holds a disagreement with the open web. The barred work in this room's annex is a SHADOW: not a copy, but a window onto Wikipedia's article about Project Xanadu, fetched at a moment in time and content-hashed. The web page remains where it always was; the shadow lets us connect TO it.

The claim under dispute is the oldest one: that the project never produced anything. The article, like every retelling, frames Xanadu as a noble failure — decades of work, nothing to show. This room is the rebuttal you are standing in: a working xanalogical system, built on the ideas that article calls unfinished.

Select the underlined passage in this room's text and follow the Disagreement to the article's own words. Open the compare view: the shadow and the rebuttal, side by side, beams between the disputed claims.

The window is honest about what it is. The banner above the shadow names its source and its date. Refetch it, and if the page changed, a new revision is appended — the disagreement stays anchored where the words were, and moves only if they moved.`;

const glossText = `The Shadow Gloss

A web shadow is a fetched, sanitized, content-hashed snapshot of a public web page, stored as a work so it can be connected to. It is not a claim of ownership, and not a copy that will drift: the BLAKE3 hash IS the snapshot's identity, and a refetch either confirms it (unchanged) or appends a new revision (changed), re-anchoring spans by excerpt match.

What this room demonstrates: connection to the web without the web migrating one inch. Xudanu is the connection layer the web forgot.`;

const main = async () => {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await request("session_connect");
  await request("session_login_public");
  if (!pass) throw new Error("XUDANU_ADMIN_PASSPHRASE is required (shadow + link ops need auth)");
  const adminId = valueOf(await request("club_id_by_name", { name: "admin" }));
  await request("session_login", { club_id: adminId });
  await request("session_authenticate", {
    credential: { password: Array.from(pass).map((c) => c.charCodeAt(0)) },
  });

  // 1. The shadow itself (idempotent server-side by normalized URL)
  const shadow = valueOf(await request("web_shadow", { url: SHADOW_URL }));
  console.log(`  [${shadow.created ? "ok" : "skip"}] shadow 0x${shadow.work_id.toString(16)} rev=${shadow.anchor_revision} hash=${shadow.content_hash.slice(0, 12)}…`);
  const shadowId = shadow.work_id;

  // Repair titles created before the <title>-first derivation fix.
  const wl0 = valueOf(await request("work_list", { offset: 0, limit: 1000 }));
  const shadowEntry = (wl0?.entries ?? []).find((w) => w.work_id === shadowId);
  if (shadowEntry && /="/.test(shadowEntry.title ?? "")) {
    await request("work_set_title", { work_id: shadowId, title: "Shadow — Project Xanadu (Wikipedia)" });
    console.log("  [fix] junk shadow title repaired");
  }

  // 2. Room + gloss works (idempotent by title)
  const mk = async (title, text) => {
    const res = valueOf(await request("work_list", { offset: 0, limit: 1000 }));
    const found = (res?.entries ?? []).find((w) => w.title === title);
    if (found) { console.log(`  [skip] ${title}`); return { id: found.work_id, isNew: false }; }
    const w = valueOf(await request("work_create", { edition: { text } }));
    const wid = typeof w === "number" ? w : w?.work_id;
    await request("work_set_title", { work_id: wid, title });
    await request("work_publish", { work_id: wid });
    console.log(`  [ok] ${title} = 0x${wid.toString(16)}`);
    return { id: wid, isNew: true };
  };
  const room = await mk(ROOM_TITLE, roomText);
  await mk(GLOSS_TITLE, glossText);

  // 3. The Disagreement link: our claim → the article's framing.
  //    The far-end span is found in the LIVE shadow text at seed
  //    time (resilient to article edits); markers tried in order.
  const roomLinks0 = valueOf(await request("link_list_for_work", { work_id: room.id }));
  const rl0 = Array.isArray(roomLinks0) ? roomLinks0 : (roomLinks0?.links ?? roomLinks0?.entries ?? []);
  if (!rl0.some((l) => l.destination === shadowId || l.origin === shadowId)) {
    // Shadow works are edition works (not O-tree): read via work_get_edition
    const r0 = await request("work_get_edition", { work_id: shadowId });
    let ed = r0 && typeof r0 === "object" && "value" in r0 ? r0.value : r0;
    if (ed && typeof ed === "object" && "value" in ed) ed = ed.value;
    let shadowText = typeof ed === "string" ? ed : (ed?.text ?? "");
    if (!shadowText && Array.isArray(ed?.entries)) shadowText = ed.entries.map((e) => e.text ?? "").join("");
    if (!shadowText) throw new Error("could not read shadow text via work_get_edition");
    const candidates = [
      "never finished",
      "never completed",
      "failed to complete",
      "was never released",
      "not completed",
    ];
    let far = null;
    for (const m of candidates) {
      const i = shadowText.toLowerCase().indexOf(m);
      if (i >= 0) { far = { start: i, end: i + m.length }; console.log(`  [ok] disputed passage found: "${shadowText.slice(i, i + 48).replace(/\n/g, " ")}…"`); break; }
    }
    if (!far) {
      const i = shadowText.toLowerCase().indexOf("xanadu");
      if (i < 0) throw new Error("no anchor passage found in shadow text");
      far = { start: i, end: i + 7 };
      console.log("  [warn] markers not found; anchored on first 'Xanadu' mention");
    }
    const near = spanIn(roomText, "frames Xanadu as a noble failure");
    const l = valueOf(await request("link_create", {
      origin: room.id, destination: shadowId,
      origin_ref: { kind: "single", work_context: room.id, excerpt: "the rebuttal claim", start_position: near.start, end_position: near.end },
      destination_ref: { kind: "single", work_context: shadowId, excerpt: "the article's framing", start_position: far.start, end_position: far.end },
    }));
    const lid = typeof l === "number" ? l : l?.link_id;
    await request("link_set_types", { link_id: lid, link_types: [3] });
    console.log(`  [ok] Disagreement link ${lid} (room ↔ shadow)`);
  }

  // 4. Lobby: append-only line + gathers link (exhibition membership)
  const lobbyRes = valueOf(await request("work_list", { offset: 0, limit: 1000 }));
  const lobby = (lobbyRes?.entries ?? []).find((w) => w.title === LOBBY_TITLE);
  if (!lobby) throw new Error("gallery lobby not found — run seed-gallery-unusual.mjs first");
  const lobbyLinks = valueOf(await request("link_list_for_work", { work_id: lobby.work_id }));
  const larr = Array.isArray(lobbyLinks) ? lobbyLinks : (lobbyLinks?.links ?? lobbyLinks?.entries ?? []);
  const hasRoom11 = larr.some((l) => l.destination === room.id && (l.link_types ?? []).length > 0);
  if (!hasRoom11) {
    // Lobby works are edition works too — read via work_get_edition
    const r0 = await request("work_get_edition", { work_id: lobby.work_id });
    let ed = r0 && typeof r0 === "object" && "value" in r0 ? r0.value : r0;
    if (ed && typeof ed === "object" && "value" in ed) ed = ed.value;
    let current = typeof ed === "string" ? ed : (ed?.text ?? "");
    if (!current && Array.isArray(ed?.entries)) current = ed.entries.map((e) => e.text ?? "").join("");
    if (!current) throw new Error("could not read lobby text via work_get_edition");
    let newText = current;
    if (!current.includes("Room 11: The Disagreed Article")) {
      newText = current + LOBBY_APPENDIX;
      await request("work_set_text", { work_id: lobby.work_id, text: newText });
      console.log("  [ok] lobby appendix appended (append-only — existing spans unmoved)");
    }
    const p = spanIn(newText, "Room 11: The Disagreed Article");
    const l = valueOf(await request("link_create", {
      origin: lobby.work_id, destination: room.id,
      origin_ref: { kind: "single", work_context: lobby.work_id, excerpt: "Room 11 (floor plan)", start_position: p.start, end_position: p.end },
    }));
    const lid = typeof l === "number" ? l : l?.link_id;
    const gathersDef = (lobbyRes?.entries ?? []).find((w) => w.title === "Gallery — Link Type: Gathers");
    await request("link_set_types", { link_id: lid, link_types: [gathersDef?.work_id] });
    console.log(`  [ok] lobby gathers link to Room 11`);
  } else {
    console.log("  [skip] lobby already links Room 11");
  }

  console.log("\nROOM 11 READY — open the room, follow the Disagreement, press ⇄ against the shadow");
  ws.close();
  process.exit(0);
};

main().catch((e) => { console.error(e.message); process.exit(1); });
