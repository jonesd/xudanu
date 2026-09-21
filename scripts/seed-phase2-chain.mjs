#!/usr/bin/node
// seed-phase2-chain.mjs — the downstream decision: "Phase 2 Rollout
// Plan" consumes the deliberation's result. Demonstrates decision
// chaining: a live transclusion of the Recommendation's claim (the
// result flows in BY REFERENCE), a Reference link marking the
// dependency, and a See Also from the risk note to the still-open
// dissent — the graph reaches through the result to the argument.
//
// Usage: node scripts/seed-phase2-chain.mjs [ws-url]
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

const W1_REVISED = `Release Cadence Proposal

The claim. A six-week cadence reduces burnout; the learning cost is real but is covered by the handoff checklist in the outage report. The reasoning is set out below and the evidence section gathers the passages that support it.

Context. We have run four-week cycles for two years. The team survey and the outage report bracket the trade-off from both sides.

Survey voices. The following passage is included live from the user survey.`;

const W2_REVISED = `Why Four Weeks Still Works

Concession scope. The burnout evidence is real; my dispute is only about the learning cost.`;

const PHASE2 = `Phase 2 Rollout Plan

The basis. The cadence question was settled by the working group; the passage below is their outcome, included live from the recommendation.

The plan. We adopt the six-week cadence for the platform team starting next quarter, with the handoff checklist as a launch gate.

Risk note. If the standing dispute about the learning cost is resolved against the checklist, this plan must be revisited.`;

const span = (text, needle) => {
  const i = text.indexOf(needle);
  if (i < 0) throw new Error("marker not found: " + needle.slice(0, 40));
  return { start: i, end: i + needle.length };
};

async function main() {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await req("session_connect");
  await req("session_login_public");

  const existing = val(await req("work_list", {}));
  const entries = Array.isArray(existing) ? existing : (existing?.works ?? existing?.entries ?? []);
  const find = (p) => entries.find(w => (w.title || "").startsWith(p))?.work_id;
  if (find("Phase 2 Rollout Plan")) { console.log("already seeded — skipping"); ws.close(); return; }
  const W6 = find("Release Cadence Recommendation");
  const W2 = find("Why Four Weeks Still Works");
  if (!W6 || !W2) { console.log("deliberation works missing — run demo-deliberation.mjs first"); ws.close(); return; }

  await req("session_login_public").catch(() => {});
  try {
    await req("club_create_personal", { display_name: "Quinn Planner", password: PASS });
    console.log("identity created: Quinn Planner");
  } catch { console.log("identity exists: Quinn Planner"); }
  await req("session_login_by_name", { club_name: "Quinn Planner" });
  await req("session_authenticate", { credential: { password: PASS } });

  const w = val(await req("work_create", { edition: { text: PHASE2 } }));
  const W8 = typeof w === "number" ? w : w?.work_id;
  await req("work_publish", { work_id: W8 });
  console.log(`Phase 2 Rollout Plan = ${W8}`);

  // 1. The result flows in BY REFERENCE: transclude the Recommendation's
  //    claim sentence (W6 text mirrors W1_REVISED, same offsets).
  const claim = span(W1_REVISED, "A six-week cadence reduces burnout; the learning cost is real but is covered by the handoff checklist in the outage report.");
  const anchor = span(PHASE2, "included live from the recommendation.");
  await req("element_insert", {
    work_id: W8, position: anchor.end,
    element: { type: "transclusion", transclusion_source: W6, transclusion_start: claim.start, transclusion_end: claim.end },
  });
  console.log("transclusion: Recommendation claim -> Phase 2 (live)");

  // 2. The dependency, explicit: plan sentence -> Recommendation claim.
  const plan = span(PHASE2, "We adopt the six-week cadence for the platform team");
  let r = val(await req("link_create", {
    origin: W8, destination: W6,
    origin_ref: { kind: "single", work_context: W8, excerpt: "the plan", start_position: plan.start, end_position: plan.end },
    destination_ref: { kind: "single", work_context: W6, excerpt: "the settled claim", start_position: claim.start, end_position: claim.end },
  }));
  await req("link_set_types", { link_id: typeof r === "number" ? r : r?.link_id, link_types: [2] });
  console.log("Reference: plan -> Recommendation claim");

  // 3. The graph reaches THROUGH the result to the open dissent:
  //    risk note -> Ken's standing point.
  const risk = span(PHASE2, "this plan must be revisited");
  const kenPoint = span(W2_REVISED, "my dispute is only about the learning cost");
  r = val(await req("link_create", {
    origin: W8, destination: W2,
    origin_ref: { kind: "single", work_context: W8, excerpt: "risk note", start_position: risk.start, end_position: risk.end },
    destination_ref: { kind: "single", work_context: W2, excerpt: "the standing dispute", start_position: kenPoint.start, end_position: kenPoint.end },
  }));
  await req("link_set_types", { link_id: typeof r === "number" ? r : r?.link_id, link_types: [5] });
  console.log("See Also: risk note -> standing dispute");

  console.log(`Phase 2 chain ready: W8=${W8} -> W6=${W6} (transclusion + reference), risk -> W2=${W2}`);
  ws.close();
}

main().catch(e => { console.error(e.message); process.exit(1); });
