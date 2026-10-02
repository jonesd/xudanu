#!/usr/bin/env node
// examples/argument-chain-demo.mjs — the v1.16.0 demo seed
//
// A MIXED-PROVENANCE argument chain: humans dispute, the LLM
// reader-critic proposes, a human confirms — and everything meets
// in the same endorsement marketplace on one Links panel.
//
//   Titanium Debate — Technical Plan (the contested work)
//     ⚑ Chain 1 (rebutted, exact):
//       Dan's Requirement Disagreement → plan's duralum passage
//         ↳ Ruth's Rebuttal      (responds_to — EXACT, v1.16.0)
//         ↳ Dan's Counter        (responds_to — EXACT)
//     ⚑ Chain 2 (disputed · awaiting response):
//       Consumer Division's Disagreement → same passage
//     ✨ LLM-confirmed (qwen2.5:1.5b, strategy C context):
//       2 References proposed by the model, confirmed by a human
//
// Run against the dev server (new binary, OLLAMA_BASE_URL set):
//   node examples/argument-chain-demo.mjs [ws-url]
import WebSocket from "../web/app/node_modules/ws/index.js";

const WS_URL_BASE = process.argv[2] ?? "ws://127.0.0.1:8080/xudanu?format=json";

let WS_URL = WS_URL_BASE;
try {
  const csrfResp = await fetch("http://127.0.0.1:8080/csrf-token");
  const csrfJson = await csrfResp.json();
  const csrfToken = csrfJson.csrf_token ?? csrfJson.token ?? "";
  if (csrfToken) WS_URL = `${WS_URL_BASE}&csrf_token=${encodeURIComponent(csrfToken)}`;
} catch { /* no CSRF on this server */ }

const ws = new WebSocket(WS_URL, { headers: { origin: "http://localhost:5173" } });
let nextId = 1;
const pending = new Map();
const opened = new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
function request(op, payload) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    const t = setTimeout(() => { pending.delete(id); reject(new Error(`timeout: ${op}`)); }, 120000);
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
const v = (x) => (x && typeof x === "object" && "value" in x ? x.value : x);
const say = (msg) => console.log(msg);

// ── The works ──────────────────────────────────────────────────────

const PLAN_TEXT = `Technical Plan — Modular Widget Prototype

The funculator is duralum. The coupler is thermoplastic.
The modular widget uses a duralum funculator because duralum provides
adequate thermal conductivity at low cost for the prototype phase.

The thermoplastic coupler handles the thermal expansion differential
between the funculator housing and the control surface interface.

Budget note: duralum funculator cost is $12.40 per unit at prototype
volume (500 units). Titanshift to titanalum would increase this to
$28.70 per unit.`;

const REQUIREMENT_TEXT = `Marketing Requirement — Titanshift

The funculator must be titanalum before first flight.

Microwidget's partially modular widget has a titanalum funculator and
is gaining traction in the aerospace sector. Our duralum funculator
is technically adequate for the prototype but the market signal is
clear: key accounts are asking for titanalum.

This is a hard requirement for launch, not a preference.`;

const REBUTTAL_TEXT = `Cost Analysis — Titanshift Response

Titanshift to titanalum increases the funculator cost from $12.40 to
$28.70 per unit. At the projected 50,000-unit first-year volume,
that is a delta of $815,000.

However, the aerospace sector represents 60% of the projected revenue.
If the market truly demands titanalum, the cost is justified by the
revenue at stake. I recommend we prototype both variants and let the
pilot customers decide.`;

const COUNTER_TEXT = `Market Sectors — Cost Justification

The aerospace sector has already placed three preliminary orders
specifying titanalum. The cost delta is $815,000 but the aerospace
revenue projection is $4.2M annually. The ROI on the titanshift is
clear even in the first year.`;

const BUDGET_TEXT = `Budget Impact — Titanshift

The titanshift increases per-unit cost by $16.30 (duralum $12.40 →
titanshift $28.70). At 50,000 units first-year, total impact: $815,000.
Mitigation: the aerospace pricing tier can absorb $600,000; the
remaining $215,000 comes from the contingency fund.

Recommendation: proceed with titanalum for the aerospace variant,
retain duralum for the consumer variant.`;

const CONSUMER_TEXT = `Consumer Division Position — Against the Titanshift

The consumer segment is price-sensitive: our own focus panels chose
the duralum variant at $12.40 in nine of ten comparisons when the
titanalium price was shown. A $16.30 per-unit increase on the shared
platform raises the consumer SKU's floor and undoes the price
positioning we committed to retailers.

The aerospace case should not set the bill of materials for the
consumer line.`;

await opened;
await request("session_connect");
await request("session_login_public");
say("◆ connected as the public session\n");

async function makeWork(title, text) {
  const id = v(await request("work_create", { edition: { text } }));
  await request("work_set_title", { work_id: id, title });
  await request("work_publish", { work_id: id });
  say(`◆ ${title}: 0x${id.toString(16)}`);
  return id;
}
async function textOf(id) {
  const ed = v(await request("work_get_edition", { work_id: id }));
  return typeof ed === "string" ? ed : ed?.text ?? "";
}

const plan = await makeWork("Titanium Debate — Technical Plan", PLAN_TEXT);
const req = await makeWork("Titanium Debate — Dan's Requirement (Titanshift)", REQUIREMENT_TEXT);
const rebuttal = await makeWork("Titanium Debate — Ruth's Rebuttal (Cost Analysis)", REBUTTAL_TEXT);
const counter = await makeWork("Titanium Debate — Dan's Counter (Market Justification)", COUNTER_TEXT);
const budget = await makeWork("Titanium Debate — John's Budget Impact", BUDGET_TEXT);
const consumer = await makeWork("Titanium Debate — Consumer Division Position", CONSUMER_TEXT);

const planText = await textOf(plan);
const reqText = await textOf(req);
const duralumAt = planText.indexOf("duralum funculator because duralum");
const titanalumAt = reqText.indexOf("titanalum funculator");
const consumerText = await textOf(consumer);
const consumerClaimAt = consumerText.indexOf("price-sensitive");

async function link(origin, destination, oRef, dRef) {
  const id = v(await request("link_create", {
    origin, destination,
    origin_ref: oRef && { kind: "single", work_context: origin,
      excerpt: oRef.excerpt, start_position: oRef.start, end_position: oRef.end },
    destination_ref: dRef && { kind: "single", work_context: destination,
      excerpt: dRef.excerpt, start_position: dRef.start, end_position: dRef.end },
  }));
  return typeof id === "number" ? id : id?.link_id;
}

// ── Chain 1: Dan's Disagreement, answered exactly ─────────────────
const disagreement = await link(req, plan,
  { excerpt: "titanalum funculator", start: titanalumAt, end: titanalumAt + "titanalum funculator".length },
  { excerpt: "duralum funculator because duralum provides", start: duralumAt, end: duralumAt + "duralum funculator because duralum provides".length });
await request("link_set_types", { link_id: disagreement, link_types: [3] });
say(`⚑ Disagreement 0x${disagreement.toString(16)}: Dan's Requirement → plan`);

const rebuttalText = await textOf(rebuttal);
const costAt = rebuttalText.indexOf("$815,000");
const rebuttalLink = await link(rebuttal, req,
  { excerpt: "$815,000", start: costAt, end: costAt + "$815,000".length },
  { excerpt: "titanalum funculator", start: titanalumAt, end: titanalumAt + "titanalum funculator".length });
await request("link_set_types", { link_id: rebuttalLink, link_types: [2] });
await request("link_set_responds_to", { link_id: rebuttalLink, responds_to: disagreement });
say(`  ↳ Rebuttal 0x${rebuttalLink.toString(16)} (responds_to set — EXACT)`);

const counterText = await textOf(counter);
const roiAt = counterText.indexOf("$4.2M annually");
const counterLink = await link(counter, rebuttal,
  { excerpt: "$4.2M annually", start: roiAt, end: roiAt + "$4.2M annually".length },
  { excerpt: "$815,000", start: costAt, end: costAt + "$815,000".length });
await request("link_set_types", { link_id: counterLink, link_types: [2] });
await request("link_set_responds_to", { link_id: counterLink, responds_to: disagreement });
say(`  ↳ Counter 0x${counterLink.toString(16)} (responds_to set — EXACT)`);

// ── Chain 2: Consumer Division, unanswered ─────────────────────────
const consumerDisagreement = await link(consumer, plan,
  { excerpt: "price-sensitive", start: consumerClaimAt, end: consumerClaimAt + "price-sensitive".length },
  { excerpt: "duralum funculator because duralum provides", start: duralumAt, end: duralumAt + "duralum funculator because duralum provides".length });
await request("link_set_types", { link_id: consumerDisagreement, link_types: [3] });
say(`⚑ Disagreement 0x${consumerDisagreement.toString(16)}: Consumer Division → plan (awaiting response)`);

// John's Budget references the plan (human Reference)
const budgetText = await textOf(budget);
const budgetCostAt = budgetText.indexOf("$815,000");
const budgetLink = await link(budget, plan,
  { excerpt: "$815,000", start: budgetCostAt, end: budgetCostAt + "$815,000".length },
  { excerpt: "duralum funculator cost is $12.40",
    start: planText.indexOf("duralum funculator cost is"),
    end: planText.indexOf("duralum funculator cost is") + 32 });
await request("link_set_types", { link_id: budgetLink, link_types: [2] });
say(`◆ Budget reference 0x${budgetLink.toString(16)}: John's Budget → plan`);

// ── The LLM reader-critic: propose, human confirms ─────────────────
say("\n✨ asking the LLM to read the plan and propose connections…");
const proposals = v(await request("llm_propose_connections", { work_id: plan }));
say(`  model: ${proposals?.model ?? "?"} (${proposals?.backend ?? "?"}) — ${proposals?.proposals?.length ?? 0} proposals`);
const worksList = v(await request("work_list", { limit: 1000 }))?.entries ?? [];
const byTitle = new Map(worksList.map((w) => [w.title, w.work_id]));

let confirmed = 0;
for (const p of proposals?.proposals ?? []) {
  if (confirmed >= 2) break;
  const farId = p.far_end_title ? byTitle.get(p.far_end_title) : plan;
  if (!farId || farId === plan) {
    say(`  · skipped "${(p.excerpt ?? "").slice(0, 40)}…" → "${p.far_end_title}" (far end unresolved)`);
    continue;
  }
  const planSpan = planText.indexOf(p.excerpt);
  if (planSpan < 0) {
    say(`  · skipped (excerpt not found in plan): "${(p.excerpt ?? "").slice(0, 40)}…"`);
    continue;
  }
  const lid = await link(plan, farId,
    { excerpt: p.excerpt, start: planSpan, end: planSpan + p.excerpt.length }, null);
  await request("link_set_types", { link_id: lid, link_types: [p.type_id] });
  confirmed++;
  say(`  ✓ confirmed: "${p.excerpt.slice(0, 44)}${p.excerpt.length > 44 ? "…" : ""}" → ${p.far_end_title} (${p.type_id === 3 ? "Disagreement" : p.type_id === 2 ? "Reference" : `type ${p.type_id}`})`);
}
say(`  ${confirmed} LLM proposals confirmed by the human — ordinary links now`);

// ── Verify ─────────────────────────────────────────────────────────
say("\n── Chain verification (plan's links) ──");
const planLinks = v(await request("link_list_for_work", { work_id: plan }));
const rows = (planLinks?.entries ?? planLinks ?? []).filter((l) => l.destination === plan || l.origin === plan);
for (const l of rows) {
  say(`  · 0x${l.link_id.toString(16)} ${(l.link_types ?? []).join(",")}${l.responds_to ? ` responds_to:0x${l.responds_to.toString(16)}` : ""}`);
}

say(`\n◆ Done. Open work 0x${plan.toString(16)} — Links panel.`);
ws.close();
process.exit(0);
