#!/usr/bin/env node
// examples/widgetperfect-argument.mjs — FR-85 Scenario A
//
// Recreates the WidgetPerfect saga from Miller/Stiegler's "The Open
// Society and its Media" (1995) as a live argument chain:
//
//   Ruth's Technical Plan (the contested work)
//     ← Dan's Requirement: titanalum funculator (Disagreement, 3 endorsements)
//       ← Ruth's Rebuttal: cost analysis (Reference, 2 endorsements)
//         ← Dan's Counter: market sectors justify cost (Reference, 1 endorsement)
//   John's Budget Note (Reference to Ruth's plan — the chain continues)
//   Ruth's link detector fires — the chain is visible end-to-end
//
// Run against a dev server (sandbox policy, loopback fetches):
//
//   xudanu-server run 127.0.0.1:8080 data --allow-loopback
//   node examples/widgetperfect-argument.mjs [ws-url]
//
import WebSocket from "../web/app/node_modules/ws/index.js";

const WS_URL_BASE = process.argv[2] ?? "ws://127.0.0.1:8080/xudanu?format=json";

// The dev server runs --csrf-token: fetch one first.
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

// ── Create everything ──────────────────────────────────────────────

await opened;
await request("session_connect");
await request("session_login_public");
say("◆ connected as the public session\n");

// 1. Ruth's Technical Plan (the contested work)
const plan = v(await request("work_create", { edition: { text: PLAN_TEXT } }));
await request("work_set_title", { work_id: plan, title: "WidgetPerfect — Ruth's Technical Plan" });
await request("work_publish", { work_id: plan });
say(`◆ Ruth's Technical Plan: 0x${plan.toString(16)}`);

// 2. Dan's Requirement (the Disagreement)
const req = v(await request("work_create", { edition: { text: REQUIREMENT_TEXT } }));
await request("work_set_title", { work_id: req, title: "WidgetPerfect — Dan's Requirement (Titanshift)" });
await request("work_publish", { work_id: req });
say(`◆ Dan's Requirement: 0x${req.toString(16)}`);

// Find the disputed passage in the plan
const planEd = v(await request("work_get_edition", { work_id: plan }));
const planText = typeof planEd === "string" ? planEd : planEd?.text ?? "";
const duralumAt = planText.indexOf("duralum funculator because duralum");
if (duralumAt < 0) throw new Error("disputed passage not found in plan text");

const reqEd = v(await request("work_get_edition", { work_id: req }));
const reqText = typeof reqEd === "string" ? reqEd : reqEd?.text ?? "";
const titanalumAt = reqText.indexOf("titanalum funculator");

// Create the Disagreement: Dan → Ruth's plan passage
const disagreement = v(await request("link_create", {
  origin: req, destination: plan,
  origin_ref: { kind: "single", work_context: req,
    excerpt: "titanalum funculator", start_position: titanalumAt, end_position: titanalumAt + 21 },
  destination_ref: { kind: "single", work_context: plan,
    excerpt: "duralum funculator because duralum provides",
    start_position: duralumAt, end_position: duralumAt + 42 },
}));
const disId = typeof disagreement === "number" ? disagreement : disagreement?.link_id;
await request("link_set_types", { link_id: disId, link_types: [3] }); // Disagreement
say(`◆ Disagreement link 0x${disId.toString(16)}: Dan's requirement → plan's duralum passage`);

// 3. Ruth's Rebuttal (Reference to Dan's criticism)
const rebuttal = v(await request("work_create", { edition: { text: REBUTTAL_TEXT } }));
await request("work_set_title", { work_id: rebuttal, title: "WidgetPerfect — Ruth's Rebuttal (Cost Analysis)" });
await request("work_publish", { work_id: rebuttal });
say(`◆ Ruth's Rebuttal: 0x${rebuttal.toString(16)}`);

const rebuttalEd = v(await request("work_get_edition", { work_id: rebuttal }));
const rebuttalText = typeof rebuttalEd === "string" ? rebuttalEd : rebuttalEd?.text ?? "";
const costAt = rebuttalText.indexOf("$815,000");

// Reference from Ruth's rebuttal to Dan's requirement work
const rebuttalLink = v(await request("link_create", {
  origin: rebuttal, destination: req,
  origin_ref: { kind: "single", work_context: rebuttal,
    excerpt: "$815,000", start_position: costAt, end_position: costAt + 9 },
  destination_ref: { kind: "single", work_context: req,
    excerpt: "titanalum funculator", start_position: titanalumAt, end_position: titanalumAt + 21 },
}));
const rebuttalLinkId = typeof rebuttalLink === "number" ? rebuttalLink : rebuttalLink?.link_id;
await request("link_set_types", { link_id: rebuttalLinkId, link_types: [2] }); // Reference
say(`◆ Rebuttal link 0x${rebuttalLinkId.toString(16)}: Ruth's cost analysis → Dan's requirement`);

// 4. Dan's Counter (Reference to Ruth's rebuttal)
const counter = v(await request("work_create", { edition: { text: COUNTER_TEXT } }));
await request("work_set_title", { work_id: counter, title: "WidgetPerfect — Dan's Counter (Market Justification)" });
await request("work_publish", { work_id: counter });
say(`◆ Dan's Counter: 0x${counter.toString(16)}`);

const counterEd = v(await request("work_get_edition", { work_id: counter }));
const counterText = typeof counterEd === "string" ? counterEd : counterEd?.text ?? "";
const roiAt = counterText.indexOf("$4.2M annually");

const counterLink = v(await request("link_create", {
  origin: counter, destination: rebuttal,
  origin_ref: { kind: "single", work_context: counter,
    excerpt: "$4.2M annually", start_position: roiAt, end_position: roiAt + 14 },
  destination_ref: { kind: "single", work_context: rebuttal,
    excerpt: "$815,000", start_position: costAt, end_position: costAt + 9 },
}));
const counterLinkId = typeof counterLink === "number" ? counterLink : counterLink?.link_id;
await request("link_set_types", { link_id: counterLinkId, link_types: [2] }); // Reference
say(`◆ Counter link 0x${counterLinkId.toString(16)}: Dan's market data → Ruth's cost analysis`);

// 5. John's Budget Note (Reference to the plan — chain continues)
const budget = v(await request("work_create", { edition: { text: BUDGET_TEXT } }));
await request("work_set_title", { work_id: budget, title: "WidgetPerfect — John's Budget Impact" });
await request("work_publish", { work_id: budget });
say(`◆ John's Budget Note: 0x${budget.toString(16)}`);

const budgetEd = v(await request("work_get_edition", { work_id: budget }));
const budgetText = typeof budgetEd === "string" ? budgetEd : budgetEd?.text ?? "";
const budgetCostAt = budgetText.indexOf("$815,000");

const budgetLink = v(await request("link_create", {
  origin: budget, destination: plan,
  origin_ref: { kind: "single", work_context: budget,
    excerpt: "$815,000", start_position: budgetCostAt, end_position: budgetCostAt + 9 },
  destination_ref: { kind: "single", work_context: plan,
    excerpt: "duralum funculator cost is $12.40",
    start_position: planText.indexOf("duralum funculator cost is"),
    end_position: planText.indexOf("duralum funculator cost is") + 32 },
}));
const budgetLinkId = typeof budgetLink === "number" ? budgetLink : budgetLink?.link_id;
await request("link_set_types", { link_id: budgetLinkId, link_types: [2] }); // Reference
say(`◆ Budget link 0x${budgetLinkId.toString(16)}: John's budget → plan's cost passage`);

// 6. Ruth's link detector (the WidgetPerfect mechanism)
const detector = v(await request("detector_create", {
  work_id: plan,
  kind: "links",
  match: { link_types: [3], direction: "in" }, // Disagreements incoming
}));
say(`◆ Link detector #${detector.detector_id} on the plan (Disagreements, incoming)`);
say(`  Ruth's detector is now watching — the next Disagreement will fire silently\n`);

// ── Verify the chain ───────────────────────────────────────────────
say("── Chain verification ──");
const links = v(await request("link_list_for_work", { work_id: plan }));
const planLinks = (links?.entries ?? links ?? []).filter((l) => l.destination === plan);
say(`  Links into the plan: ${planLinks.length}`);
for (const l of planLinks) {
  const types = (l.link_types ?? []).join(",");
  say(`    · link 0x${l.link_id.toString(16)} from 0x${l.origin.toString(16)} (types: ${types})`);
}

say("\n◆ WidgetPerfect argument chain seeded.");
say("  Open Ruth's Technical Plan and check the Connections panel —");
say("  the Arguments section shows the dispute chain with status.");
say("  The detector is live: create another Disagreement and it fires.");

ws.close();
process.exit(0);
