#!/usr/bin/node
// seed-deliberation-round2.mjs — round 2 of the four-party deliberation:
// Ken's standing dispute (L6, learning cost) prompts a second revision
// from Marta, an explicit responds-to link (comment attached to L6),
// and Ken's full concession — L6 retires to history. Resume-safe.
//
// Also demonstrates round-boundary mechanics: the page stays one page,
// the record deepens (W1 gains a revision, W2 loses the dispute text).
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

const W5_TEXT = `User Survey

Question 7. I can hold context across a four-week gap but start losing it at five; a written handoff would restore most of it.`;

const span = (text, needle) => {
  const i = text.indexOf(needle);
  if (i < 0) throw new Error("marker not found: " + needle.slice(0, 40));
  return { start: i, end: i + needle.length };
};

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
  const W1 = find("Release Cadence Proposal");
  const W2 = find("Why Four Weeks Still Works");
  const W5 = find("User Survey");
  if (!W1 || !W2 || !W5) { console.log("deliberation works missing — run demo-deliberation.mjs first"); ws.close(); return; }

  // Resume-safe: skip if round 2 already landed.
  const cur = val(await req("work_get_edition", { work_id: W1 }));
  if (JSON.stringify(cur).includes("re-onboarding rotation")) {
    console.log("round 2 already seeded — skipping");
    ws.close(); return;
  }

  // Find the standing dispute (L6): type 3, origin W2.
  const raw = val(await req("link_list_for_work", { work_id: W1 }));
  const links = Array.isArray(raw) ? raw : (raw?.links ?? raw?.entries ?? []);
  const l6 = links.find(l => (l.link_types ?? []).includes(3) && l.origin === W2);
  if (!l6) { console.log("standing dispute not found — already conceded?"); ws.close(); return; }
  console.log("standing dispute link:", l6.link_id);

  // T11 — Marta revises in response (round 2) + restores the live
  // transclusion that full-text revise drops.
  await become("Marta Proposer");
  await req("work_grab", { work_id: W1 });
  await req("work_revise", { work_id: W1, edition: { text: W1_ROUND2 } });
  await req("work_release", { work_id: W1 }).catch(() => {});
  const q7 = span(W5_TEXT, "I can hold context across a four-week gap but start losing it at five; a written handoff would restore most of it.");
  const anchor = span(W1_ROUND2, "The following passage is included live from the user survey.");
  await req("element_insert", {
    work_id: W1, position: anchor.end,
    element: { type: "transclusion", transclusion_source: W5, transclusion_start: q7.start, transclusion_end: q7.end },
  });
  console.log("W1 revised to round 2; transclusion restored");

  // T12 — the causality record: the new clause responds to L6
  // (comment attached to the dispute itself — the round-2 convention).
  const clause = span(W1_ROUND2, "plus a two-week re-onboarding rotation for returning contributors");
  const r = val(await req("link_create", {
    origin: W1, destination: W1,
    origin_ref: { kind: "single", work_context: W1, excerpt: "round two response", start_position: clause.start, end_position: clause.end },
  }));
  const respId = typeof r === "number" ? r : r?.link_id;
  await req("link_set_types", { link_id: respId, link_types: [1] });
  await req("link_end_add_attachment", {
    link_id: respId, end_name: "Connection",
    attachment: { kind: "link_attachment", work_context: W1, link_attachment: l6.link_id, excerpt: null, start_position: null, end_position: null },
  });
  console.log(`responds-to link ${respId} attached to dispute ${l6.link_id}`);

  // T13 — Ken concedes: the dispute sentence leaves W2, L6 retires
  // to history (its origin span no longer has live text).
  await become("Ken Skeptic");
  await req("work_grab", { work_id: W2 });
  await req("work_revise", { work_id: W2, edition: { text: W2_ROUND2 } });
  await req("work_release", { work_id: W2 }).catch(() => {});
  console.log("W2 conceded; dispute retires to history");

  console.log(`\nRound 2 ready: W1=${W1} revised, responds-to=${respId}, L6=${l6.link_id} retired.`);
  ws.close();
}

main().catch(e => { console.error(e.message); process.exit(1); });
