#!/usr/bin/node
// seed-grand-tour.mjs — the gallery's front door: one curated trail
// threading the exhibits in teaching order. Each stop carries a note
// saying what to look for. Run AFTER all other seeders.
import WebSocket from "ws";

const url = process.argv[2] || "ws://127.0.0.1:8080/xudanu?format=json";
const token = await fetch("http://127.0.0.1:8080/csrf-token").then(r => r.json()).then(j => j.csrf_token);
const ws = new WebSocket(url + "&csrf_token=" + token, { headers: { origin: "http://localhost:5173" } });

let id = 1; const pending = new Map();
const req = (op, payload) => new Promise((res, rej) => {
  const i = id++;
  const t = setTimeout(() => rej(new Error("timeout " + op)), 30000);
  pending.set(i, { res, rej, t, op });
  ws.send(JSON.stringify({ v: 2, type: "request", id: i, op, payload: payload ?? {} }));
});
ws.on("message", d => {
  const f = JSON.parse(d);
  if (f.type === "response" || f.type === "error") {
    const p = pending.get(f.id);
    if (p) { pending.delete(f.id); clearTimeout(p.t);
      f.type === "error" ? p.rej(new Error(p.op + ": " + f.message)) : p.res(f.value); }
  }
});
const val = v => v && typeof v === "object" && "value" in v ? v.value : v;
const PASS = Array.from(new TextEncoder().encode("Deliberation-2026"));

async function main() {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await req("session_connect");
  await req("session_login_public");

  const existing = val(await req("work_list", {}));
  const entries = Array.isArray(existing) ? existing : (existing?.works ?? existing?.entries ?? []);
  const find = (p) => entries.find(w => (w.title || "").startsWith(p))?.work_id;

  // Also check trails: skip if the Grand Tour already exists
  const trails = val(await req("trail_list", {}).catch(() => []));
  const trailArr = Array.isArray(trails) ? trails : (trails?.trails ?? []);
  if (trailArr.some(t => (t.name || "").startsWith("The Grand Tour"))) {
    console.log("grand tour already exists — skipping");
    ws.close(); return;
  }

  await req("session_login_by_name", { club_name: "Quinn Planner" });
  await req("session_authenticate", { credential: { password: PASS } });

  const stops = [
    ["The Connection Atlas", "Start here: one document that teaches the entire visual vocabulary — one connection, stacked kinds, gathered evidence, the density pill. Hover everything."],
    ["Release Cadence Proposal", "A four-party deliberation in two rounds. Hover the claim sentence: the ledger shows who disputed, who gathered evidence, who commented — and which disputes are retired to history."],
    ["Why Four Weeks Still Works", "The other end of the dispute. Ken's concession is visible in the attribution: his text, his name, his decision to withdraw."],
    ["Deliberation Record — Release Cadence", "The compiled record: five authors in one document, zero copies. Open the Attribution panel — every party, every passage, signed, with derivation chains back to their source documents."],
    ["Phase 2 Rollout Plan", "Decisions flow into decisions. The basis passage is transcluded live from the recommendation — edit the source, this changes. The risk note links through the result to the still-open dispute."],
    ["The Garden Passage", "Translation as connection: the same thought in three languages, one link. Open the Links panel and compare all ends side by side."],
    ["Link Density Demo", "What happens as connections accumulate: 1, 2, 4, 8 links on one sentence — individual markers, then the density pill. The document stays calm until you approach."],
    ["Transclusion Source", "The live quotation's far end. Edit this passage and every quotation of it — everywhere — updates. That is transclusion: one fact, many homes."],
  ].map(([title, note]) => ({ wid: find(title), title, note })).filter(s => s.wid);

  const missing = ["The Connection Atlas", "Release Cadence Proposal", "Why Four Weeks Still Works",
    "Deliberation Record — Release Cadence", "Phase 2 Rollover Plan", "The Garden Passage",
    "Link Density Demo", "Transclusion Source"].filter(t => !find(t));
  if (missing.length > 3) {
    console.log("too many exhibits missing — run the other seeders first:", missing.join(", "));
    ws.close(); return;
  }

  const r = val(await req("trail_create", {
    name: "The Grand Tour",
    introduction: "Eight stops through a working xanalogical system: visible connections, live quotation, multi-party deliberation, compiled records, decisions that flow into decisions, translation across languages, and density that stays calm. Everything here is live structure — hover, click, compare. Nothing is illustration.",
  }));
  const trailId = typeof r === "number" ? r : r?.trail_id;
  console.log(`Grand Tour trail = ${trailId}`);

  for (const s of stops) {
    await req("trail_add_stop", { trail_id: trailId, work_id: s.wid, note: s.note });
    console.log(`  stop: ${s.title}`);
  }

  console.log(`\nGrand Tour ready: ${stops.length} stops.`);
  ws.close();
}

main().catch(e => { console.error(e.message); process.exit(1); });
