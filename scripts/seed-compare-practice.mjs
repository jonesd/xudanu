#!/usr/bin/env node
// seed-compare-practice.mjs — a pair of documents engineered for the
// compare view: substantial shared passages (some edited INSIDE, so
// the aligned word-diff has real work to show), one passage cut, one
// added, one reordered. Linked See-Also so ⇄ opens the comparison.
//
// Idempotent: keyed by titles.
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

// Shared passage, EDITED INSIDE between the versions (word-level diff):
const P1a = "We are opening the doors. Xudanu is a connected literature where every quotation maintains its bond to the original, and every reuse carries its full provenance.";
const P1b = "We are opening the doors early. Xudanu is a connected literature where every quotation keeps its bond to the original, and every reuse carries its full provenance.";
// Shared VERBATIM (the big beam):
const P2 = "Unlike the web's one-way links, connections here are visible from both ends. A reader sees what points to a passage as easily as they see what the passage points to, and the two views are one view.";
// Draft-only (cut before final):
const P3 = "The gallery contains nine rooms of unusual connection, each one a live structure rather than a picture of a structure, and every room is connected to the others.";
// Final-only (new):
const P4 = "Start in the lobby, follow the Curator's Tour, and press the compare arrows on any connection to see its ends side by side — shared passages are the same text carried across, not two texts that resemble each other.";
// Shared verbatim, REORDERED (moved up in the final):
const P5 = "Nothing is pasted. Every quoted passage is a live window onto its source, and when the source is revised, every window revises with it.";

const DRAFT_TITLE = "Compare Practice — The Draft (opening note, first pass)";
const FINAL_TITLE = "Compare Practice — The Final (opening note, as sent)";

const draftText = `The Opening Note — first pass

${P1a}

${P2}

${P5}

${P3}`;

const finalText = `The Opening Note — as sent

${P5}

${P1b}

${P2}

${P4}`;

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
    const found = (res?.entries ?? []).find((w) => w.title === title);
    if (found) { console.log(`  [skip] ${title}`); return { id: found.work_id, isNew: false }; }
    const w = valueOf(await request("work_create", { edition: { text } }));
    const wid = typeof w === "number" ? w : w?.work_id;
    await request("work_set_title", { work_id: wid, title });
    await request("work_publish", { work_id: wid });
    console.log(`  [ok] ${title} = 0x${wid.toString(16)}`);
    return { id: wid, isNew: true };
  };

  const draft = await mk(DRAFT_TITLE, draftText);
  const final_ = await mk(FINAL_TITLE, finalText);

  if (draft.isNew && final_.isNew) {
    const d = span(draftText, P2.slice(0, 50));
    const f = span(finalText, P2.slice(0, 50));
    const l = valueOf(await request("link_create", {
      origin: draft.id, destination: final_.id,
      origin_ref: { kind: "single", work_context: draft.id, excerpt: "the first pass", start_position: d.start, end_position: d.end },
      destination_ref: { kind: "single", work_context: final_.id, excerpt: "as sent", start_position: f.start, end_position: f.end },
    }));
    const lid = typeof l === "number" ? l : l?.link_id;
    await request("link_set_types", { link_id: lid, link_types: [5] });
    console.log(`  [ok] See-Also link ${lid} (⇄ compares them)`);
  }

  console.log("\nCOMPARE PRACTICE READY — open either, Links tab, press ⇄");
  ws.close();
  process.exit(0);
};

main().catch((e) => { console.error(e.message); process.exit(1); });
