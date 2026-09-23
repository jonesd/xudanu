#!/usr/bin/env node
// seed-two-drafts.mjs — FR-78 Phase 1: "The Two Drafts" gallery room.
//
// One essay in two versions: the room holds the final; the annex
// holds the abandoned first draft (paragraphs reordered, one passage
// abandoned, one passage new). Shared paragraphs are IDENTICAL text —
// the compare view's shared-passage highlighting is identity
// (content-match), not similarity: the ledger read aloud.
//
// The link carries a third "Gloss" end so its row shows the ⇄
// compare button (multi-ended convention), and the lobby gains an
// append-only line + gathers link so the room joins the exhibition.
//
// Idempotent: keyed by work titles; skips existing pieces.
import WebSocket from "ws";

const url = process.argv[2] ?? "ws://127.0.0.1:8080/xudanu?format=json";
const pass = process.env.XUDANU_ADMIN_PASSPHRASE;
const ws = new WebSocket(url, { headers: { origin: process.env.SEED_ORIGIN ?? "http://localhost:5173" } });

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
const valueOf = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);
const span = (text, marker) => {
  const i = text.indexOf(marker);
  if (i < 0) throw new Error(`marker not found: ${marker.slice(0, 40)}`);
  return { start: i, end: i + marker.length };
};

// The shared spine: IDENTICAL paragraphs in both works.
const S1 = "The first draft is not a smaller version of the finished thing. It is a different object that happens to share some of its parts.";
const S2 = "Every rewrite is an argument about order. The words mostly stay; what changes is what the reader meets first, and what they are made to wait for.";
const S3 = "A passage cut is not a passage killed. It waits in the draft like a stone in a pocket, weightless until you need it again.";
const D1 = "Some writers plan. The rest of us excavate, and pretend afterward that we knew the shape all along.";
const F1 = "Open the comparison and read the beams: what is beamed is the SAME text carried across, not two texts that happen to resemble each other.";

const ROOM_TITLE = "Gallery — Wing II · Room 10: The Two Drafts";
const DRAFT_TITLE = "Gallery Annex — The First Draft (abandoned)";
const GLOSS_TITLE = "Gallery Annex — The Drafts Gloss";
const LOBBY_TITLE = "Gallery — Lobby: The Gallery of Unusual Connections";
const LOBBY_APPENDIX = "\n\nAND ONE EXPERIMENT — beyond the wings.\nRoom 10: The Two Drafts — one essay, its abandoned first draft, and the beams between.";

const roomText = `The Two Drafts

This room is an experiment in reading rewriting the Xanadu way. The essay below exists in two versions: this one, and an abandoned first draft in the annex. Open the Links panel (right) and press the compare button on the Quotation connection — the two drafts appear side by side, and the passages they share are highlighted because they are the SAME text carried across, not similar text.

${S1}

${F1}

${S2}

${S3}`;

const draftText = `The First Draft (abandoned)

The order this essay started in — before the argument about order was won.

${S2}

${S1}

${D1}

${S3}`;

const glossText = `The Drafts Gloss

Three kinds of kinship live in this room: the beamed paragraphs (same text, two places), the abandoned passage (draft only — never used), and the new paragraph (final only). Rewriting is all three at once.`;

const main = async () => {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await request("session_connect");
  await request("session_login_public");
  if (pass) {
    const adminId = valueOf(await request("club_id_by_name", { name: "admin" }));
    await request("session_login", { club_id: adminId });
    await request("session_authenticate", {
      credential: { password: Array.from(pass).map((c) => c.charCodeAt(0)) },
    });
  }

  const mk = async (title, text) => {
    const res = valueOf(await request("work_list", { offset: 0, limit: 1000 }));
    const entries = res?.entries ?? [];
    const found = entries.find((w) => w.title === title);
    if (found) { console.log(`  [skip] ${title}`); return { id: found.work_id, isNew: false }; }
    const w = valueOf(await request("work_create", { edition: { text } }));
    const wid = typeof w === "number" ? w : w?.work_id;
    await request("work_set_title", { work_id: wid, title });
    await request("work_publish", { work_id: wid });
    console.log(`  [ok] ${title} = 0x${wid.toString(16)}`);
    return { id: wid, isNew: true };
  };

  const room = await mk(ROOM_TITLE, roomText);
  const draft = await mk(DRAFT_TITLE, draftText);
  const gloss = await mk(GLOSS_TITLE, glossText);

  if (room.isNew) {
    // The kinship link: origin on the final's opening paragraph,
    // destination on the SAME paragraph inside the reordered draft
    // (different position — that is the point), plus a Gloss end so
    // the row offers the multi-ended compare button.
    const o = span(roomText, S1.slice(0, 60));
    const d = span(draftText, S1.slice(0, 60));
    const g = span(glossText, "Three kinds of kinship");
    const l = valueOf(await request("link_create", {
      origin: room.id, destination: draft.id,
      origin_ref: { kind: "single", work_context: room.id, excerpt: "the final's opening paragraph", start_position: o.start, end_position: o.end },
      destination_ref: { kind: "single", work_context: draft.id, excerpt: "the same paragraph, elsewhere in the draft", start_position: d.start, end_position: d.end },
    }));
    const lid = typeof l === "number" ? l : l?.link_id;
    await request("link_set_types", { link_id: lid, link_types: [4] });
    await request("link_add_end", {
      link_id: lid, end_name: "Gloss",
      end_ref: { kind: "single", work_context: gloss.id, excerpt: "the gloss end", start_position: g.start, end_position: g.end },
    });
    console.log(`  [ok] kinship link ${lid} (final ↔ draft ↔ gloss)`);
  }

  // Lobby: append-only line + gathers link (exhibition membership)
  const lobbyRes = valueOf(await request("work_list", { offset: 0, limit: 1000 }));
  const lobby = (lobbyRes?.entries ?? []).find((w) => w.title === LOBBY_TITLE);
  if (!lobby) throw new Error("gallery lobby not found — run seed-gallery-unusual.mjs first");
  const lobbyLinks = valueOf(await request("link_list_for_work", { work_id: lobby.work_id }));
  const larr = Array.isArray(lobbyLinks) ? lobbyLinks : (lobbyLinks?.links ?? lobbyLinks?.entries ?? []);
  const hasRoom10 = larr.some((l) => l.destination === room.id && (l.link_types ?? []).length > 0);
  if (!hasRoom10) {
    // Current lobby text (from the live work) + appendix
    const txt = valueOf(await request("work_text_range", { work_id: lobby.work_id, start_char: 0, end_char: 100000 }));
    const current = typeof txt === "string" ? txt : (txt?.text ?? "");
    if (!current.includes("Room 10: The Two Drafts")) {
      await request("work_set_text", { work_id: lobby.work_id, text: current + LOBBY_APPENDIX });
      console.log("  [ok] lobby appendix appended (append-only — existing spans unmoved)");
    }
    // Gathers type id = the definition work id (the work IS the type)
    const gathersDef = (lobbyRes?.entries ?? []).find((w) => w.title === "Gallery — Link Type: Gathers");
    const gt = gathersDef?.work_id;
    const newLobbyText = (typeof txt === "string" ? txt : (txt?.text ?? "")) + LOBBY_APPENDIX;
    const p = span(newLobbyText, "Room 10: The Two Drafts");
    const l = valueOf(await request("link_create", {
      origin: lobby.work_id, destination: room.id,
      origin_ref: { kind: "single", work_context: lobby.work_id, excerpt: "Room 10 (floor plan)", start_position: p.start, end_position: p.end },
    }));
    const lid = typeof l === "number" ? l : l?.link_id;
    await request("link_set_types", { link_id: lid, link_types: [gt] });
    console.log(`  [ok] lobby gathers link to Room 10 (type ${gt})`);
  } else {
    console.log("  [skip] lobby already links Room 10");
  }

  console.log("\nTWO DRAFTS READY — open the room, Links panel, press ⇄");
  ws.close();
  process.exit(0);
};

main().catch((e) => { console.error(e.message); process.exit(1); });
