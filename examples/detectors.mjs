#!/usr/bin/env node
// examples/detectors.mjs — FR-80 detectors, as a running walkthrough.
//
// Detectors are persistent watches on works (Miller's fourth
// fundamental feature, 1994): a link detector collects new links
// landing on a work — optionally filtered by a SET of link types —
// and a revision detector collects new revisions. This script plants
// both kinds, triggers each the way a developer would, and reads back
// the collection.
//
// Run against any server (default: a local dev server):
//
//   node examples/detectors.mjs [ws-url]
//   e.g. node examples/detectors.mjs ws://127.0.0.1:8080/xudanu?format=json
//
// No admin passphrase needed: it works as the public session on any
// server whose edit policy allows public writing (public-sandbox), or
// as the signed-in session on a strict server after login (extend
// `connect()` below). Cleans up its scratch works' links' detectors at
// the end (detector_delete) so re-runs are quiet.
import WebSocket from "../web/app/node_modules/ws/index.js";

const URL_ = process.argv[2] ?? "ws://127.0.0.1:8080/xudanu?format=json";
const ws = new WebSocket(URL_, { headers: { origin: "http://localhost:5173" } });

let nextId = 1;
const pending = new Map();
const wsOpened = new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
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
    if (p) {
      pending.delete(frame.id); clearTimeout(p.timeout);
      frame.type === "error" ? p.reject(new Error(`${p.op}: ${frame.message}`)) : p.resolve(frame.value);
    }
  }
});
const valueOf = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);
const say = (msg) => console.log(msg);

async function main() {
  await wsOpened;
  await request("session_connect");
  await request("session_login_public");
  say("◆ connected as the public session\n");

  // ── 1. Scratch works to watch ────────────────────────────────────
  const plan = valueOf(await request("work_create", {
    edition: { text: "Technical Plan\n\nThe funculator is duralum. The coupler is thermoplastic.\n" },
  }));
  const reqDoc = valueOf(await request("work_create", {
    edition: { text: "Marketing Requirement\n\nSwitch the funculator to titanalum.\n" },
  }));
  await request("work_set_title", { work_id: plan, title: "Example — Technical Plan" });
  await request("work_set_title", { work_id: reqDoc, title: "Example — Requirement" });
  await request("work_publish", { work_id: plan });
  await request("work_publish", { work_id: reqDoc });
  say(`◆ scratch works: plan=0x${plan.toString(16)} requirement=0x${reqDoc.toString(16)}\n`);

  // ── 2. Plant the detectors ───────────────────────────────────────
  // A link detector on the plan, collecting ONLY "requirement"-type
  // links (type id is per-server: look yours up with link_type_list;
  // we register our own so the example is self-contained).
  const typeDef = valueOf(await request("work_create", {
    edition: { text: "A requirement: something the plan must satisfy.\n" },
  }));
  await request("work_set_title", { work_id: typeDef, title: "Example — Link Type: Requirement" });
  await request("work_publish", { work_id: typeDef });
  await request("link_type_register", {
    type_id: typeDef, name: "requirement",
    definition_work_id: typeDef,
  }).catch((e) => say(`  (type register needs admin on strict servers: ${e.message.slice(0, 50)})`));

  const linkDet = valueOf(await request("detector_create", {
    work_id: plan,
    kind: "links",
    match: { link_types: [typeDef], direction: "in" },
  }));
  say(`◆ link detector #${linkDet.detector_id} planted on the plan`);
  say(`  match: ${JSON.stringify(linkDet.match)}\n`);

  const revDet = valueOf(await request("detector_create", {
    work_id: plan,
    kind: "revisions",
  }));
  say(`◆ revision detector #${revDet.detector_id} planted on the plan\n`);

  // ── 3. Trigger the link detector (the WidgetPerfect step) ───────
  // Dan links his requirement to the passage in Ruth's plan.
  const reqText = valueOf(await request("work_get_edition", { work_id: reqDoc }));
  const planText = valueOf(await request("work_get_edition", { work_id: plan }));
  const link = valueOf(await request("link_create", {
    origin: reqDoc, destination: plan,
    origin_ref: { kind: "single", work_context: reqDoc, excerpt: "the requirement", start_position: 0, end_position: 12 },
    destination_ref: { kind: "single", work_context: plan, excerpt: "the funculator passage", start_position: 17, end_position: 40 },
  }));
  const linkId = typeof link === "number" ? link : link?.link_id;
  await request("link_set_types", { link_id: linkId, link_types: [typeDef] });
  say(`◆ requirement link 0x${linkId.toString(16)} attached — detector fired silently\n`);

  // A Comment link (type 1) should NOT collect: the match is a set
  // filter, and 1 is not in it.
  const noise = valueOf(await request("link_create", {
    origin: reqDoc, destination: plan,
    origin_ref: { kind: "single", work_context: reqDoc, excerpt: "a note", start_position: 0, end_position: 6 },
    destination_ref: { kind: "single", work_context: plan, excerpt: "elsewhere", start_position: 40, end_position: 49 },
  }));
  const noiseId = typeof noise === "number" ? noise : noise?.link_id;
  await request("link_set_types", { link_id: noiseId, link_types: [1] });
  say(`◆ a Comment link also landed — filtered OUT by the type set\n`);

  // ── 4. Trigger the revision detector ────────────────────────────
  await request("work_set_text", {
    work_id: plan,
    text: "Technical Plan\n\nThe funculator is TITANALUM. The coupler is thermoplastic.\n",
  });
  say("◆ plan revised (duralum → titanalum) — revision detector fired\n");

  // ── 5. Read the collection ──────────────────────────────────────
  const list = valueOf(await request("detector_list"));
  const dets = list?.detectors ?? list ?? [];
  say("\n◆ the collection:");
  for (const d of dets) {
    const kinds = d.hits.map((h) => h.link_id ? `link 0x${h.link_id.toString(16)}` : `revision ${h.revision}`).join(", ");
    say(`  #${d.detector_id} ${d.kind} on 0x${d.work_id.toString(16)} — unread ${d.unread}: ${kinds || "(nothing yet)"}`);
  }

  // ── 6. Ack: mark read, keep the record ──────────────────────────
  for (const d of dets) {
    const acked = valueOf(await request("detector_ack", { detector_id: d.detector_id }));
    say(`  acked #${d.detector_id}: ${acked} hits marked read (kept, not deleted)`);
  }  const after = valueOf(await request("detector_list"));
  const afterDets = after?.detectors ?? [];
  const totalUnread = afterDets.reduce((s, d) => s + (d.unread ?? 0), 0);
  say(`  unread after ack: ${totalUnread} (hits retained)\n`);

  // ── 7. Cleanup: delete the detectors (works remain for inspection)
  for (const d of afterDets) {
    await request("detector_delete", { detector_id: d.detector_id });
  }
  say("◆ detectors deleted (scratch works left in the library for inspection)");
  say("\nDONE — this is the whole surface: create, match, fire, list, ack, delete.");
  ws.close();
  process.exit(0);
}

main().catch((e) => { console.error(`FAILED: ${e.message}`); process.exit(1); });
