#!/usr/bin/node
// seed-deliberation-record.mjs — the Deliberation Record: a compiled
// work whose decisive passages are TRANSCLUDED live from the parties'
// documents, so its attribution shows every party (provenance rides
// transclusion). Retired rounds are linked (their ends resolve to
// history), not copied. The record is ordinary literature.
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

const W1_ROUND2 = `Release Cadence Proposal

The claim. A six-week cadence reduces burnout; the learning cost is real but is covered by the handoff checklist plus a two-week re-onboarding rotation for returning contributors. The reasoning is set out below and the evidence section gathers the passages that support it.

Context. We have run four-week cycles for two years. The team survey and the outage report bracket the trade-off from both sides.

Survey voices. The following passage is included live from the user survey.`;

const W2_ROUND2 = `Why Four Weeks Still Works

Conceded. The re-onboarding rotation answers the learning-cost concern; the dispute is withdrawn.`;

const W7_TEXT = `Review Notes

On the dispute. This disagreement turns on what learning means here: velocity, or the ability to rejoin a codebase after time away.

On the heat. Five connections now sit on one sentence; that is the debate in miniature.`;

const W3_TEXT = `Support Ticket Log

Ticket 12. Three engineers on the release rota requested reduced hours in the same week, citing sustained overnight load during the four-week crunch.`;

const W5_TEXT = `User Survey

Question 7. I can hold context across a four-week gap but start losing it at five; a written handoff would restore most of it.`;

const RECORD = `Deliberation Record — Release Cadence

Two rounds, four parties, one claim. The decisive passages below are included live from their documents; retired rounds are linked at the foot. This record is ordinary literature: every transcluded passage keeps its original author.

Round 2, the revision under dispute:

The concession:

The crux, as the reviewer defined it:

The evidence, gathered across the documents:

And the survey voice:

Retired rounds. The round-one objection and the round-two standing dispute are withdrawn from their documents; their ends resolve against the documents' history via the links below.`;

const spans = {
  claim: (() => { const s = W1_ROUND2.indexOf("A six-week cadence reduces burnout"); return { start: s, end: s + "A six-week cadence reduces burnout; the learning cost is real but is covered by the handoff checklist plus a two-week re-onboarding rotation for returning contributors.".length }; })(),
  concede: (() => { const s = W2_ROUND2.indexOf("The re-onboarding rotation answers"); return { start: s, end: s + "The re-onboarding rotation answers the learning-cost concern; the dispute is withdrawn.".length }; })(),
  crux: (() => { const s = W7_TEXT.indexOf("This disagreement turns on what learning means"); return { start: s, end: s + "This disagreement turns on what learning means here: velocity, or the ability to rejoin a codebase after time away.".length }; })(),
  ticket: (() => { const s = W3_TEXT.indexOf("Three engineers on the release rota"); return { start: s, end: s + "Three engineers on the release rota requested reduced hours in the same week, citing sustained overnight load during the four-week crunch.".length }; })(),
  survey: (() => { const s = W5_TEXT.indexOf("I can hold context"); return { start: s, end: s + "I can hold context across a four-week gap but start losing it at five; a written handoff would restore most of it.".length }; })(),
};

// Insertion points in RECORD: end of each framing paragraph.
const insertPoints = [
  { needle: "Round 2, the revision under dispute:", src: "claim", srcText: W1_ROUND2 },
  { needle: "The concession:", src: "concede", srcText: W2_ROUND2 },
  { needle: "The crux, as the reviewer defined it:", src: "crux", srcText: W7_TEXT },
  { needle: "The evidence, gathered across the documents:", src: "ticket", srcText: W3_TEXT },
  { needle: "And the survey voice:", src: "survey", srcText: W5_TEXT },
].map(p => ({
  ...p,
  pos: RECORD.indexOf(p.needle) + p.needle.length,
}));

async function become(name) {
  await req("session_login_public").catch(() => {});
  await req("session_login_by_name", { club_name: name });
  await req("session_authenticate", { credential: { password: PASS } });
}

async function main() {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await req("session_connect");
  await req("session_login_public");

  const existing = val(await req("work_list", {}));
  const entries = Array.isArray(existing) ? existing : (existing?.works ?? existing?.entries ?? []);
  const find = (p) => entries.find(w => (w.title || "").startsWith(p))?.work_id;
  if (find("Deliberation Record")) { console.log("already seeded — skipping"); ws.close(); return; }
  const W1 = find("Release Cadence Proposal");
  const W2 = find("Why Four Weeks Still Works");
  const W3 = find("Support Ticket Log");
  const W5 = find("User Survey");
  const W7 = find("Review Notes");
  if (!W1 || !W2 || !W3 || !W5 || !W7) { console.log("deliberation works missing"); ws.close(); return; }
  const workIds = { claim: W1, concede: W2, crux: W7, ticket: W3, survey: W5 };

  // Find the retired disputes to link at the foot.
  const raw = val(await req("link_list_for_work", { work_id: W1 }));
  const links = Array.isArray(raw) ? raw : (raw?.links ?? raw?.entries ?? []);
  const retired = links.filter(l => (l.link_types ?? []).includes(3) && l.origin === W2);
  console.log(`retired disputes from W2: ${retired.map(l => l.link_id).join(", ") || "(none found)"}`);

  // Compile as Quinn (the neutral party from Phase 2; created there).
  await become("Quinn Planner");
  const w = val(await req("work_create", { edition: { text: RECORD } }));
  const REC = typeof w === "number" ? w : w?.work_id;
  await req("work_publish", { work_id: REC });
  console.log(`Deliberation Record = ${REC}`);

  // Transclusions, descending position so offsets stay valid.
  for (const p of [...insertPoints].sort((a, b) => b.pos - a.pos)) {
    const s = spans[p.src];
    await req("element_insert", {
      work_id: REC, position: p.pos,
      element: { type: "transclusion", transclusion_source: workIds[p.src], transclusion_start: s.start, transclusion_end: s.end },
    });
  }
  console.log("5 transclusions placed");

  // Links at the foot: attach the retired-round sentence to each
  // retired dispute (their far ends resolve to history).
  const foot = RECORD.indexOf("Retired rounds.");
  const footSpan = { start: foot, end: foot + "Retired rounds.".length };
  for (const l of retired) {
    const r = val(await req("link_create", {
      origin: REC, destination: W1,
      origin_ref: { kind: "single", work_context: REC, excerpt: "retired round marker", start_position: footSpan.start, end_position: footSpan.end },
    }));
    const lid = typeof r === "number" ? r : r?.link_id;
    await req("link_set_types", { link_id: lid, link_types: [5] });
    await req("link_end_add_attachment", {
      link_id: lid, end_name: "Connection",
      attachment: { kind: "link_attachment", work_context: W1, link_attachment: l.link_id, excerpt: null, start_position: null, end_position: null },
    });
    console.log(`retired-round link ${lid} -> dispute ${l.link_id}`);
  }

  // Verify attribution: the record should carry spans from multiple
  // original authors (provenance rides transclusion).
  const attr = val(await req("attribution_query_resolved", { work_id: REC }).catch(() => null));
  if (attr) {
    const authors = [...new Set((attr.entries ?? attr.spans ?? []).map(e => e.author_name ?? e.author).filter(Boolean))];
    console.log("attribution authors visible:", authors.join(", ") || "(raw parse — check panel)");
  } else {
    console.log("attribution query unavailable — check the Attribution panel in the UI");
  }

  console.log(`\nDeliberation Record ready: ${REC}`);
  ws.close();
}

main().catch(e => { console.error(e.message); process.exit(1); });
