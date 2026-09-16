#!/usr/bin/node
// demo-deliberation.mjs — seed the four-party deliberation scenario
// from private/four-party-simulation.md (T1-T9). Four identities
// (Marta, Ken, Priya, Alex) each create and connect their own works,
// so provenance shows four distinct authors.
//
// Usage: node scripts/demo-deliberation.mjs [ws-url]
// Idempotent: skips if "Release Cadence Proposal" already exists.
// Identity passphrase for all four (demo): Deliberation-2026
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
const W1_TEXT = `Release Cadence Proposal

The claim. A six-week cadence reduces burnout without slowing learning. The reasoning is set out below and the evidence section gathers the passages that support it.

Context. We have run four-week cycles for two years. The team survey and the outage report bracket the trade-off from both sides.

Survey voices. The following passage is included live from the user survey.`;

const W1_REVISED = `Release Cadence Proposal

The claim. A six-week cadence reduces burnout; the learning cost is real but is covered by the handoff checklist in the outage report. The reasoning is set out below and the evidence section gathers the passages that support it.

Context. We have run four-week cycles for two years. The team survey and the outage report bracket the trade-off from both sides.

Survey voices. The following passage is included live from the user survey.`;

const W2_TEXT = `Why Four Weeks Still Works

The objection. Two-week gaps already cost us context; stretching to six risks forgetting the codebase entirely. That is the core of my concern and it has not been answered.

Concession scope. The burnout evidence is real; my dispute is only about the learning cost.`;

const W2_REVISED = `Why Four Weeks Still Works

Concession scope. The burnout evidence is real; my dispute is only about the learning cost.`;

const W3_TEXT = `Support Ticket Log

Ticket 12. Three engineers on the release rota requested reduced hours in the same week, citing sustained overnight load during the four-week crunch.`;

const W4_TEXT = `Outage Report

Root cause. The handoff gap between releases left the checklist unowned for nine days; two of the three errors trace to that window.

Process note. Weekend coverage overlapped both the old and new cadence, so it is not a confounder here.`;

const W5_TEXT = `User Survey

Question 7. I can hold context across a four-week gap but start losing it at five; a written handoff would restore most of it.`;

const W7_TEXT = `Review Notes

On the dispute. This disagreement turns on what learning means here: velocity, or the ability to rejoin a codebase after time away.

On the heat. Five connections now sit on one sentence; that is the debate in miniature.`;

const span = (text, needle) => {
  const i = text.indexOf(needle);
  if (i < 0) throw new Error("marker not found: " + needle.slice(0, 40));
  return { start: i, end: i + needle.length };
};

const PARTIES = ["Marta Proposer", "Ken Skeptic", "Priya Reviewer", "Alex Evidence"];
const links = {};
let W1 = null, W2 = null, W3 = null, W4 = null, W5 = null, W6 = null, W7 = null;

async function become(name) {
  await req("session_login_public").catch(() => {});
  try {
    await req("club_create_personal", { display_name: name, password: PASS });
    console.log(`identity created: ${name}`);
  } catch (e) {
    const msg = String(e.message);
    if (msg.includes("already exists")) console.log(`identity exists: ${name}`);
    else console.log(`create ${name}: ${msg.slice(0, 80)} — continuing to login`);
  }
  await req("session_login_by_name", { club_name: name });
  await req("session_authenticate", { credential: { password: PASS } });
  console.log(`session: ${name}`);
}

const mk = async (name, text) => {
  const w = val(await req("work_create", { edition: { text } }));
  const wid = typeof w === "number" ? w : w?.work_id;
  await req("work_publish", { work_id: wid });
  console.log(`work ${name} = ${wid}`);
  return wid;
};

const link = async (name, payload, type) => {
  const r = val(await req("link_create", payload));
  const lid = typeof r === "number" ? r : r?.link_id;
  if (type) await req("link_set_types", { link_id: lid, link_types: [type] });
  links[name] = lid;
  console.log(`link ${name} = ${lid} (type ${type})`);
  return lid;
};

async function main() {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await req("session_connect");
  await req("session_login_public").catch(() => {});

  const listWorks = async () => {
    const existing = val(await req("work_list", {}));
    return Array.isArray(existing) ? existing : (existing?.works ?? existing?.entries ?? []);
  };
  const findWork = (entries, titlePrefix) =>
    entries.find(w => (w.title || "").startsWith(titlePrefix))?.work_id;
  const entries = await listWorks();
  if (findWork(entries, "Release Cadence Recommendation")) {
    console.log("already seeded — skipping");
    ws.close(); return;
  }
  W1 = findWork(entries, "Release Cadence Proposal") ?? null;
  W2 = findWork(entries, "Why Four Weeks Still Works") ?? null;
  W3 = findWork(entries, "Support Ticket Log") ?? null;
  W4 = findWork(entries, "Outage Report") ?? null;
  W5 = findWork(entries, "User Survey") ?? null;
  W7 = findWork(entries, "Review Notes") ?? null;

  let linksSeeded = false;
  if (W1) {
    const list = val(await req("link_list_for_work", { work_id: W1 }).catch(() => []));
    const back = val(await req("work_backlinks", { work_id: W1 }).catch(() => []));
    const count = (x) => (Array.isArray(x) ? x : (x?.links ?? x?.backlinks ?? [])).length;
    linksSeeded = count(list) + count(back) >= 5;
  }
  if (linksSeeded) console.log("T2-T6 links already present — resuming from T7");

  if (!linksSeeded) {

  // T1 — Marta states the claim
  await become(PARTIES[0]);
  if (!W1) W1 = await mk("W1 proposal", W1_TEXT);
  else console.log(`reuse W1 proposal = ${W1}`);

  // T2 — Ken disputes the exact sentence
  await become(PARTIES[1]);
  if (!W2) W2 = await mk("W2 memo", W2_TEXT);
  else console.log(`reuse W2 memo = ${W2}`);
  await link("L1 dispute", {
    origin: W2, destination: W1,
    origin_ref: { kind: "single", work_context: W2, excerpt: "objection",
      ...(() => { const s = span(W2_TEXT, "Two-week gaps already cost us context"); return { start_position: s.start, end_position: s.end }; })() },
    destination_ref: { kind: "single", work_context: W1, excerpt: "the claim",
      ...(() => { const s = span(W1_TEXT, "A six-week cadence reduces burnout without slowing learning"); return { start_position: s.start, end_position: s.end }; })() },
  }, 3);

  // T3 — Priya comments on the dispute itself
  await become(PARTIES[2]);
  if (!W7) W7 = await mk("W7 review notes", W7_TEXT);
  else console.log(`reuse W7 review notes = ${W7}`);
  await link("L2 comment-on-link", {
    origin: W7, destination: W1,
    origin_ref: { kind: "single", work_context: W7, excerpt: "turns on what learning means",
      ...(() => { const s = span(W7_TEXT, "This disagreement turns on what learning means"); return { start_position: s.start, end_position: s.end }; })() },
  }, 1);
  await req("link_end_add_attachment", {
    link_id: links["L2 comment-on-link"], end_name: "Connection",
    attachment: { kind: "link_attachment", work_context: W1, link_attachment: links["L1 dispute"], excerpt: null, start_position: null, end_position: null },
  });
  console.log("L2 attached to L1");

  // T4 — Alex gathers three fragments as one evidence end-set
  await become(PARTIES[3]);
  if (!W3) W3 = await mk("W3 ticket log", W3_TEXT);
  if (!W4) W4 = await mk("W4 outage report", W4_TEXT);
  if (!W5) W5 = await mk("W5 user survey", W5_TEXT);
  const claim0 = span(W1_TEXT, "A six-week cadence reduces burnout without slowing learning");
  await link("L3 gathered reference", {
    origin: W3, destination: W1,
    origin_ref: { kind: "single", work_context: W3, excerpt: "ticket 12",
      ...(() => { const s = span(W3_TEXT, "Three engineers on the release rota"); return { start_position: s.start, end_position: s.end }; })() },
    destination_ref: { kind: "single", work_context: W1, excerpt: "the claim", start_position: claim0.start, end_position: claim0.end },
  }, 2);
  for (const [frag, txt, work] of [
    ["handoff gap", W4_TEXT, W4],
    ["survey voice", W5_TEXT, W5],
  ]) {
    const s = span(txt, frag === "handoff gap" ? "The handoff gap between releases left the checklist unowned" : "I can hold context across a four-week gap");
    await req("link_end_add_attachment", {
      link_id: links["L3 gathered reference"], end_name: "LeftEnd",
      attachment: { kind: "single", work_context: work, excerpt: frag, start_position: s.start, end_position: s.end },
    });
  }
  console.log("L3 gathers three fragments");

  // T5 — NOTE: the live quotation is inserted after the T7 revision;
  // a full-text work_revise replaces the edition and would drop the
  // inline transclusion element. See T5b below.

  // T6 — the heat: second dispute + direct comment
  await become(PARTIES[1]);
  const root = span(W4_TEXT, "The handoff gap between releases left the checklist unowned");
  await link("L4 dispute 2", {
    origin: W4, destination: W1,
    origin_ref: { kind: "single", work_context: W4, excerpt: "root cause", start_position: root.start, end_position: root.end },
    destination_ref: { kind: "single", work_context: W1, excerpt: "the claim", start_position: claim0.start, end_position: claim0.end },
  }, 3);

  await become(PARTIES[2]);
  const heat = span(W7_TEXT, "Five connections now sit on one sentence");
  await link("L5 comment", {
    origin: W7, destination: W1,
    origin_ref: { kind: "single", work_context: W7, excerpt: "on the heat", start_position: heat.start, end_position: heat.end },
    destination_ref: { kind: "single", work_context: W1, excerpt: "the claim", start_position: claim0.start, end_position: claim0.end },
  }, 1);

  } // end T2-T6 phase

  // T7 — Marta revises; links must migrate
  await become(PARTIES[0]);
  await req("work_grab", { work_id: W1 });
  await req("work_revise", { work_id: W1, edition: { text: W1_REVISED } });
  await req("work_release", { work_id: W1 }).catch(() => {});
  console.log("W1 revised (claim rewritten; links migrate)");

  // T5b — Marta transcludes the survey answer into the revised proposal
  // (after the revision: full-text revise drops inline elements)
  const edNow = JSON.stringify(val(await req("work_get_edition", { work_id: W1 })));
  if (edNow.includes("transclusion")) {
    console.log("transclusion already present — skipping insert");
  } else {
    const q7 = span(W5_TEXT, "I can hold context across a four-week gap but start losing it at five; a written handoff would restore most of it.");
    const anchor = span(W1_REVISED, "The following passage is included live from the user survey.");
    await req("element_insert", {
      work_id: W1, position: anchor.end,
      element: { type: "transclusion", transclusion_source: W5, transclusion_start: q7.start, transclusion_end: q7.end },
    });
    console.log("transclusion W5q7 into W1 (post-revision)");
  }

  // T8 — Ken retires the original objection, stands on the narrower point
  await become(PARTIES[1]);
  await req("work_grab", { work_id: W2 });
  await req("work_revise", { work_id: W2, edition: { text: W2_REVISED } });
  await req("work_release", { work_id: W2 }).catch(() => {});
  console.log("W2 revised (objection removed; L1 resolves to history)");
  const narrow = span(W2_REVISED, "my dispute is only about the learning cost.");
  const clause = span(W1_REVISED, "the learning cost is real but is covered by the handoff checklist in the outage report");
  await link("L6 standing dispute", {
    origin: W2, destination: W1,
    origin_ref: { kind: "single", work_context: W2, excerpt: "narrower point", start_position: narrow.start, end_position: narrow.end },
    destination_ref: { kind: "single", work_context: W1, excerpt: "checklist clause", start_position: clause.start, end_position: clause.end },
  }, 3);

  // T9 — Alex duplicates the proposal as the recommendation
  await become(PARTIES[3]);
  const dup = val(await req("work_duplicate", { work_id: W1 }));
  W6 = typeof dup === "number" ? dup : dup?.work_id;
  await req("work_set_title", { work_id: W6, title: "Release Cadence Recommendation" });
  await req("work_publish", { work_id: W6 });
  console.log(`work W6 recommendation = ${W6} (duplicated from W1)`);
  const w6claim = span(W1_REVISED, "A six-week cadence reduces burnout; the learning cost is real");
  await link("L7 see-also", {
    origin: W6, destination: W1,
    origin_ref: { kind: "single", work_context: W6, excerpt: "recommendation", start_position: w6claim.start, end_position: w6claim.end },
    destination_ref: { kind: "single", work_context: W1, excerpt: "the claim", start_position: w6claim.start, end_position: w6claim.end },
  }, 5);

  console.log("\nDeliberation scenario ready.");
  console.log("works: W1=" + W1, "W2=" + W2, "W3=" + W3, "W4=" + W4, "W5=" + W5, "W6=" + W6, "W7=" + W7);
  console.log("links:", JSON.stringify(links));
  ws.close();
}

main().catch(e => { console.error(e.message); process.exit(1); });
