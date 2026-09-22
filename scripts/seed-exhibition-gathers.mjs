#!/usr/bin/env node
// seed-exhibition-gathers.mjs — upgrade a seeded Gallery into a
// first-class EXHIBITION: register the "Gathers" link type (id 8),
// retype the lobby's floor-plan links from Reference to Gathers, and
// gather the annexes under the lobby via the word "annexes".
//
// The exhibition model: a COVER WORK (the lobby) + gathers-typed
// links cover -> member. Membership is a connection, not a hierarchy;
// the boundary shows as an indication (never a barrier) when a work
// switch crosses the member set.
//
// Idempotent: skips any gathers link that already exists for a
// (lobby, member) pair; the type registration is idempotent.
//
// Usage: XUDANU_ADMIN_PASSPHRASE=... node seed-exhibition-gathers.mjs
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

  // 1. Register the Gathers type. Link types are themselves works
  // (the work IS the type — Green's three-set): give Gathers a
  // definition work stating its semantics.
  const res0 = valueOf(await request("work_list", { offset: 0, limit: 1000 }));
  const defTitle = "Gallery — Link Type: Gathers";
  let def = (res0?.entries ?? []).find((w) => w.title === defTitle);
  if (!def) {
    const w = valueOf(await request("work_create", { edition: { text: `Gathers\n\nA gathers link asserts exhibition membership: the origin is the exhibition COVER, the destination is a MEMBER. The unit is referenceable from anywhere (the cover is a work), membership is bidirectional for free, and the boundary is an indication — never a barrier — when a reader crosses the member set.` } }));
    const wid = typeof w === "number" ? w : w?.work_id;
    await request("work_set_title", { work_id: wid, title: defTitle });
    await request("work_publish", { work_id: wid });
    console.log(`[ok] definition work created: 0x${wid.toString(16)}`);
    def = { work_id: wid };
  }
  try {
    await request("link_type_register", { type_id: def.work_id, name: "Gathers", definition_work: def.work_id });
    console.log(`[ok] link type ${def.work_id} "Gathers" registered (the work IS the type)`);
  } catch (e) {
    console.log(`[skip] type registration: ${e.message}`);
  }

  // The gathers type id IS the definition work id (the work IS the
  // type). Legacy note: an earlier run typed links with bare id 8
  // before this rule was known; those are retyped below.
  const GATHERS = def.work_id;

  // 2. Find the lobby and all gallery works
  const res = valueOf(await request("work_list", { offset: 0, limit: 1000 }));
  const entries = res?.entries ?? [];
  const lobby = entries.find((w) => w.title === "Gallery — Lobby: The Gallery of Unusual Connections");
  if (!lobby) throw new Error("gallery lobby not found — run seed-gallery-unusual.mjs first");
  const lobbyId = lobby.work_id;
  const lobbyText = `THE GALLERY OF UNUSUAL CONNECTIONS

Three wings, nine rooms, one tour. Every exhibit is a live structure — nothing here is a picture of a link; everything is the thing itself. The room names below are wired: click one to walk there.

WING I · FORM — the shapes a connection can take.
Room 1: The Spectrum Sentence — six kinds of connection on one sentence.
Room 2: The Junction Word — one word, five departures, two arrivals.
Room 3: The Nested Scope — a link inside a link, and one across the border.

WING II · DEPTH — connection leading to connection.
Room 4: Genealogy of a Quotation — 1965 to 1974 to 1987 to this gallery.
Room 5: A Link About a Link — commentary attached to connections, three deep.

WING III · CONTENTION — many ends, many voices.
Room 6: The Rebuttal Constellation — three passages, one end, one answer.
Room 7: The Five-Way Junction — one connection, five named ends.
Room 8: The Standing Dispute — four disagreements, both directions.

THE FABRIC — beyond links.
Room 9: The Live Window — transclusions: windows, not copies.

The Curator's Tour (in the Trails panel) threads the rooms in order. The annexes hold the far ends; every underline in every room leads somewhere real.`;

  const rooms = entries.filter((w) => /^Gallery — (Wing|The Fabric)/.test(w.title ?? ""));
  const annexes = entries.filter((w) => /^Gallery Annex/.test(w.title ?? ""));
  console.log(`lobby=0x${lobbyId.toString(16)} rooms=${rooms.length} annexes=${annexes.length}`);

  // 3. Existing lobby links
  const lres = valueOf(await request("link_list_for_work", { work_id: lobbyId }));
  const links = Array.isArray(lres) ? lres : (lres?.links ?? lres?.entries ?? []);
  const existingGathers = new Set(
    links
      .filter((l) => (l.link_types ?? []).includes(GATHERS) && l.origin === lobbyId)
      .map((l) => l.destination),
  );

  // 4. Retype floor-plan links (Reference or legacy -> Gathers) for rooms
  let retyped = 0;
  for (const l of links) {
    if (l.origin !== lobbyId) continue;
    const isRoom = rooms.some((r) => r.work_id === l.destination);
    const isLegacyAnnexGather = annexes.some((a) => a.work_id === l.destination) && (l.link_types ?? []).includes(8);
    if (!isRoom && !isLegacyAnnexGather) continue;
    if ((l.link_types ?? []).includes(GATHERS)) continue;
    await request("link_set_types", { link_id: l.link_id, link_types: [GATHERS] });
    retyped++;
  }
  console.log(`[ok] retyped ${retyped} floor-plan links to Gathers (${GATHERS})`);

  // 5. Gather the annexes under the word "annexes" in the last paragraph
  let annexLinks = 0;
  const spanIdx = lobbyText.indexOf("annexes");
  if (spanIdx < 0) throw new Error("lobby text marker 'annexes' not found");
  for (const a of annexes) {
    if (existingGathers.has(a.work_id)) continue;
    const l = valueOf(await request("link_create", {
      origin: lobbyId, destination: a.work_id,
      origin_ref: { kind: "single", work_context: lobbyId, excerpt: "the annexes, gathered", start_position: spanIdx, end_position: spanIdx + "annexes".length },
    }));
    const lid = typeof l === "number" ? l : l?.link_id;
    await request("link_set_types", { link_id: lid, link_types: [GATHERS] });
    annexLinks++;
  }
  console.log(`[ok] gathered ${annexLinks} annexes under the lobby`);

  console.log("\nEXHIBITION READY");
  console.log(`cover=0x${lobbyId.toString(16)} members=${1 + rooms.length + annexes.length} (cover + rooms + annexes)`);
  ws.close();
  process.exit(0);
};

main().catch((e) => { console.error(e.message); process.exit(1); });
