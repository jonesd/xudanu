#!/usr/bin/env node
// seed-provenance-mix.mjs — a work with MIXED authorship: three human
// authors (irregular, realistic regions) + one LLM-attributed section
// appended by an assistant session (session_set_author_type "llm").
// For the provenance demo + screenshot.
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

const TITLE = "Provenance Demo — A Note Written Together";

const humanText = `A Note Written Together

Alex opened with the question: who actually wrote this? In a document with visible provenance, that is never a mystery — every passage carries its author, and every author carries a signature.

Jordan disagreed with the framing, as Jordan does, and rewrote the middle to stress the mechanism rather than the philosophy: attribution here is per-span, cryptographic, and survives rearrangement.

Sam arrived late, fixed two typos, and added the observation that mixed authorship — human, machine, historical — is exactly where provenance stops being decoration and becomes load-bearing.`;

const llmText = `\n\nDrafted by the assistant (then left in, transparently labeled): a summary of the note above — three humans argued about why attribution matters; the assistant summarized; nothing in this document pretends to be anyone it is not.`;

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

  const res = valueOf(await request("work_list", { offset: 0, limit: 1000 }));
  const found = (res?.entries ?? []).find((w) => w.title === TITLE);
  if (found) { console.log(`[skip] ${TITLE} exists`); console.log(`work_id=${found.work_id}`); ws.close(); process.exit(0); }

  const w = valueOf(await request("work_create", { edition: { text: humanText } }));
  const wid = typeof w === "number" ? w : w?.work_id;
  await request("work_set_title", { work_id: wid, title: TITLE });
  await request("work_publish", { work_id: wid });
  console.log(`[ok] work = 0x${wid.toString(16)}`);

  // Three human authors, irregular regions, real Ed25519 keys
  await request("seed_demo_attribution", { work_id: wid, author_count: 3 });
  console.log("[ok] 3 human authors seeded (Alex, Jordan, Sam)");

  // LLM section: an assistant session appends VIA RANGE DELTA — a
  // full-text work_set_text would re-attribute the entire work to the
  // LLM session; Retain+Insert leaves the humans' spans intact.
  await request("session_set_author_type", { author_type: "llm", llm_model: "qwen2.5:14b" });
  // The delta path goes through the CRDT layer, which requires an
  // open session on the work first (crdt_sync_open).
  await request("crdt_sync_open", { work_id: wid });
  const rc = valueOf(await request("work_revision_count", { work_id: wid }));
  const base = typeof rc === "number" ? rc - 1 : 0;
  await request("work_revise_delta", {
    work_id: wid,
    base_revision: base,
    ops: [
      { type: "retain", count: humanText.length },
      { type: "insert", text: llmText },
    ],
  });
  await request("session_set_author_type", { author_type: "human" });
  console.log("[ok] assistant section appended via delta (author_type=llm, model=qwen2.5:14b)");

  console.log(`\nPROVENANCE MIX READY — work_id=${wid}`);
  ws.close();
  process.exit(0);
};

main().catch((e) => { console.error(e.message); process.exit(1); });
