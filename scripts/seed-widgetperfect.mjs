#!/usr/bin/env node
// seed-widgetperfect.mjs — FR-80: "Room 12: The WidgetPerfect Saga".
//
// Miller's demo story (The Open Society and Its Media, 1994), restaged
// as live structure: Dan's requirement link (typed `requirement`)
// lands on Ruth's technical plan; Ruth's LINK detector collects it;
// Ruth revises the plan (duralum → titanalum); John's REVISION
// detector on the plan collects that; John revises the budget; the
// budget's own revision detector collects that. Three people, two
// detector kinds, one typed link — nobody picked up the phone.
//
// The detectors are planted by the PUBLIC session so every visitor's
// More ▸ Detectors panel shows the collections — the watches are part
// of the exhibit.
//
// Usage:
//   XUDANU_ADMIN_PASSPHRASE=<pass> node scripts/seed-widgetperfect.mjs
// Idempotent: keyed by work titles + detector_list inspection.
import WebSocket from "ws";

const url = process.env.SEED_WS ?? "ws://127.0.0.1:8080/xudanu?format=json";
const pass = process.env.XUDANU_ADMIN_PASSPHRASE;
if (!pass) throw new Error("XUDANU_ADMIN_PASSPHRASE is required");
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
const wsOpened = new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
const valueOf = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);
const span = (text, marker) => {
  const i = text.indexOf(marker);
  if (i < 0) throw new Error(`marker not found: ${marker.slice(0, 40)}`);
  return { start: i, end: i + marker.length };
};

const SAGA_TITLE = "Gallery — Wing III · Room 12: The WidgetPerfect Saga";
const PLAN_TITLE = "Gallery Annex — Ruth's Technical Plan";
const REQ_TITLE = "Gallery Annex — Dan's Marketing Requirement";
const BUDGET_TITLE = "Gallery Annex — John's Budget";
const TYPE_DEF_TITLE = "Gallery — Link Type: Requirement";
const LOBBY_TITLE = "Gallery — Lobby: The Gallery of Unusual Connections";
const LOBBY_APPENDIX = "\n\nAND ONE OFFICE — where nobody picked up the phone.\nRoom 12: The WidgetPerfect Saga — a requirement link, two detectors, and three people never interrupted.";

const PLAN_V1 = `Ruth's Technical Plan

The modular widget, as prototyped.

The funculator is duralum. The coupler is thermoplastic. The rotator is hypervelocity-rated.

Everything else is on schedule.`;

const PLAN_V2 = `Ruth's Technical Plan

The modular widget, as prototyped.

The funculator is TITANALUM (revised — see the marketing requirement). The coupler is thermoplastic. The rotator is hypervelocity-rated.

Everything else is on schedule.`;

const REQ_TEXT = `Dan's Marketing Requirement

Microwidget shipped first with a PARTIALLY modular widget. Ours is fully modular and better — except their funculator is titanalum, which matters to key market sectors.

Requirement: switch the funculator to titanalum.`;

const BUDGET_V1 = `John's Budget

Funculator (duralum): $40/unit.
Coupler (thermoplastic): $12/unit.
Rotator (hypervelocity): $95/unit.

Margin holds at target.`;

const BUDGET_V2 = `John's Budget

Funculator (TITANALUM): $85/unit — cost impact from the plan revision, budget updated.
Coupler (thermoplastic): $12/unit.
Rotator (hypervelocity): $95/unit.

Margin thins; procurement is negotiating. The program stays on time.`;

const SAGA_TEXT = `The WidgetPerfect Saga

This room retells Mark Miller's 1994 demo story with live structure — the watches are real detectors and their collections hold the saga's events.

The story: Dan examines the competitor's partially modular widget. It is inferior, but its funculator is titanalum, and that matters. Dan writes a marketing requirement and links it — with a requirement link — to the passage in Ruth's technical plan that specifies duralum. Then Boeing calls about a $15M order, and Dan never quite gets around to telling Ruth.

Ruth does not need telling. She had planted a link detector on her plan, filtered to requirement links. Open More, then Detectors: the detector is there, and its collection holds Dan's link. Ruth follows it, sees the change, revises the plan — duralum becomes TITANALUM.

Ruth then reaches for the phone to tell John, but smoke billows from the prototype lab, and she never quite gets around to it. John does not need telling either: his revision detector on the plan collected Ruth's revision (also in More ▸ Detectors). He compares versions, sees the cost implication, and updates the budget — which its own revision detector collected.

The result: the program ships on time, fully specified. Thousands of jobs saved. Zero phone calls.

This is what detectors are for: turning interruption into collection. Email, Miller noted, is just the special case where a canonical point has a link detector on it.`;

const main = async () => {
  await wsOpened;
  await request("session_connect");
  await request("session_login_public");

  const list = async () => {
    const res = valueOf(await request("work_list", { offset: 0, limit: 2000 }));
    return res?.entries ?? [];
  };
  const entries = await list();
  const findBy = (t) => entries.find((w) => w.title === t);

  const mk = async (title, text) => {
    const found = findBy(title);
    if (found) { console.log(`  [skip] ${title}`); return { id: found.work_id, isNew: false }; }
    const w = valueOf(await request("work_create", { edition: { text } }));
    const wid = typeof w === "number" ? w : w?.work_id;
    await request("work_set_title", { work_id: wid, title });
    await request("work_publish", { work_id: wid });
    console.log(`  [ok] ${title} = 0x${wid.toString(16)}`);
    return { id: wid, isNew: true };
  };

  // Admin login for works/types/links/revisions
  const adminId = valueOf(await request("club_id_by_name", { name: "admin" }));
  await request("session_login", { club_id: adminId });
  await request("session_authenticate", { credential: { password: Array.from(pass).map((c) => c.charCodeAt(0)) } });

  const saga = await mk(SAGA_TITLE, SAGA_TEXT);
  const plan = await mk(PLAN_TITLE, PLAN_V1);
  const req = await mk(REQ_TITLE, REQ_TEXT);
  const budget = await mk(BUDGET_TITLE, BUDGET_V1);
  const typeDef = await mk(TYPE_DEF_TITLE, "A requirement: something the plan must satisfy. Definition work for the requirement link type.");
  await request("link_type_register", { type_id: typeDef.id, name: "requirement", definition_work: typeDef.id }).catch((e) =>
    console.log(`  (type register: ${e.message.slice(0, 60)})`));

  // Detectors planted by the PUBLIC session → every visitor sees the
  // collections (the watches are part of the exhibit).
  const plant = async (workId, kind, match) => {
    const existing = valueOf(await request("detector_list"));
    const dets = existing?.detectors ?? [];
    if (dets.some((d) => d.work_id === workId && d.kind === kind)) {
      console.log(`  [skip] ${kind} detector on 0x${workId.toString(16)}`);
      return;
    }
    const pubId = valueOf(await request("club_id_by_name", { name: "public" }));
    await request("session_login", { club_id: pubId });
    await request("detector_create", { work_id: workId, kind, ...(match ? { match } : {}) });
    await request("session_login", { club_id: adminId });
    await request("session_authenticate", { credential: { password: Array.from(pass).map((c) => c.charCodeAt(0)) } });
    console.log(`  [ok] ${kind} detector on 0x${workId.toString(16)}`);
  };

  if (saga.isNew || plan.isNew) {
    // 1. Watches first — so the story's events land in the collection.
    await plant(plan.id, "links", { link_types: [typeDef.id], direction: "in" });
    await plant(plan.id, "revisions");
    await plant(budget.id, "revisions");

    // 2. Dan's requirement link → fires Ruth's link detector.
    const dst = span(PLAN_V1, "The funculator is duralum");
    const src = span(REQ_TEXT, "switch the funculator to titanalum");
    const l = valueOf(await request("link_create", {
      origin: req.id, destination: plan.id,
      origin_ref: { kind: "single", work_context: req.id, excerpt: "the requirement", start_position: src.start, end_position: src.end },
      destination_ref: { kind: "single", work_context: plan.id, excerpt: "the duralum spec", start_position: dst.start, end_position: dst.end },
    }));
    const lid = typeof l === "number" ? l : l?.link_id;
    await request("link_set_types", { link_id: lid, link_types: [typeDef.id] });
    console.log(`  [ok] requirement link 0x${lid.toString(16)} — Ruth's detector collected it`);

    // 3. Ruth revises → fires the plan's revision detector.
    await request("work_set_text", { work_id: plan.id, text: PLAN_V2 });
    await request("work_set_title", { work_id: plan.id, title: PLAN_TITLE });
    console.log("  [ok] plan revised (duralum → TITANALUM) — John's detector collected it");

    // 4. John updates the budget → fires its detector.
    await request("work_set_text", { work_id: budget.id, text: BUDGET_V2 });
    await request("work_set_title", { work_id: budget.id, title: BUDGET_TITLE });
    console.log("  [ok] budget updated — its detector collected it");
  }

  // Lobby wiring (append-only line + gathers membership)
  const fresh = await list();
  const lobby = fresh.find((w) => w.title === LOBBY_TITLE);
  if (!lobby) throw new Error("gallery lobby not found — run seed-gallery-unusual.mjs first");
  const lobbyLinks = valueOf(await request("link_list_for_work", { work_id: lobby.work_id }));
  const larr = Array.isArray(lobbyLinks) ? lobbyLinks : (lobbyLinks?.links ?? lobbyLinks?.entries ?? []);
  if (!larr.some((l) => l.destination === saga.id && (l.link_types ?? []).length > 0)) {
    const r0 = await request("work_get_edition", { work_id: lobby.work_id });
    let ed = r0 && typeof r0 === "object" && "value" in r0 ? r0.value : r0;
    if (ed && typeof ed === "object" && "value" in ed) ed = ed.value;
    let current = typeof ed === "string" ? ed : (ed?.text ?? "");
    let newText = current;
    if (!current.includes("Room 12: The WidgetPerfect Saga")) {
      newText = current + LOBBY_APPENDIX;
      await request("work_set_text", { work_id: lobby.work_id, text: newText });
      console.log("  [ok] lobby appendix appended");
    }
    const p = span(newText, "Room 12: The WidgetPerfect Saga");
    const l = valueOf(await request("link_create", {
      origin: lobby.work_id, destination: saga.id,
      origin_ref: { kind: "single", work_context: lobby.work_id, excerpt: "Room 12 (floor plan)", start_position: p.start, end_position: p.end },
    }));
    const lid = typeof l === "number" ? l : l?.link_id;
    const gathersDef = fresh.find((w) => w.title === "Gallery — Link Type: Gathers");
    await request("link_set_types", { link_id: lid, link_types: [gathersDef?.work_id] });
    console.log("  [ok] lobby gathers link to Room 12");
  } else {
    console.log("  [skip] lobby already links Room 12");
  }

  console.log("\nWIDGETPERFECT READY — open Room 12, then More ▸ Detectors (the collections are the exhibit)");
  ws.close();
  process.exit(0);
};

main().catch((e) => { console.error(e.message); process.exit(1); });
