#!/usr/bin/node
// seed-connection-showcase.mjs — "The Connection Atlas": a document
// staged to demonstrate each rung of the link rendering ladder
// (single lane, typed ribbons, gathered segments, composition pill,
// grouped ledger). Far ends are the deliberation scenario's works,
// so ledger rows carry real titles and authors.
//
// Usage: node scripts/seed-connection-showcase.mjs [ws-url]
// Idempotent: skips if the Atlas already exists.
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

// Far-end companion texts (deliberation scenario works, live on the server)
const W2_REVISED = `Why Four Weeks Still Works

Concession scope. The burnout evidence is real; my dispute is only about the learning cost.`;
const W7_TEXT = `Review Notes

On the dispute. This disagreement turns on what learning means here: velocity, or the ability to rejoin a codebase after time away.

On the heat. Five connections now sit on one sentence; that is the debate in miniature.`;
const W3_TEXT = `Support Ticket Log

Ticket 12. Three engineers on the release rota requested reduced hours in the same week, citing sustained overnight load during the four-week crunch.`;
const W4_TEXT = `Outage Report

Root cause. The handoff gap between releases left the checklist unowned for nine days; two of the three errors trace to that window.`;
const W5_TEXT = `User Survey

Question 7. I can hold context across a four-week gap but start losing it at five; a written handoff would restore most of it.`;

const ATLAS = `The Connection Atlas

A guided tour of how connections render in a xanalogical document. Each section stages one more rung of the ladder. Everything shown is live structure, not illustration.

1. One comment. This sentence carries a single connection.
Hover it: one kind, one author, one passage behind it.

2. Two kinds. This sentence draws a dispute and a remark.
Two ribbons: the dispute sorts first, the comment sits below.

3. Four kinds. This sentence gathers a dispute, a comment, a reference, and a quotation at once.
Four ribbons, one per kind; each color is a kind, each segment an assertion.

4. The gathered argument. This sentence is supported by three passages that jointly form one end.
One green ribbon, three adjacent segments: the evidence is distributed, the assertion is single.

5. The crowded passage. This sentence is where the whole debate lands at once.
Seven connections collapse into one pill at the margin; its stripes are the composition of the debate. Hover the pill for the ledger; click it to expand the ribbons.

6. Reading the structure. Every marking in this atlas follows one rule: the document stays calm until you approach it.
Hover anywhere above to see the connection ledger; the guide line to a label appears only while you look.`;

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
  if (find("The Connection Atlas")) { console.log("already seeded — skipping"); ws.close(); return; }
  const W2 = find("Why Four Weeks Still Works");
  const W7 = find("Review Notes");
  const W3 = find("Support Ticket Log");
  const W4 = find("Outage Report");
  const W5 = find("User Survey");
  if (!W2 || !W7 || !W3 || !W4 || !W5) {
    console.log("deliberation works missing — run demo-deliberation.mjs first");
    ws.close(); return;
  }

  await become("Marta Proposer");
  const a = val(await req("work_create", { edition: { text: ATLAS } }));
  const ATLAS_ID = typeof a === "number" ? a : a?.work_id;
  await req("work_publish", { work_id: ATLAS_ID });
  console.log(`Atlas = ${ATLAS_ID}`);

  const link = async (who, origin, oSpan, oExcerpt, dest, dSpan, dExcerpt, type) => {
    await become(who);
    const r = val(await req("link_create", {
      origin, destination: ATLAS_ID,
      origin_ref: { kind: "single", work_context: origin, excerpt: oExcerpt, start_position: oSpan.start, end_position: oSpan.end },
      destination_ref: { kind: "single", work_context: ATLAS_ID, excerpt: dExcerpt, start_position: dSpan.start, end_position: dSpan.end },
    }));
    const lid = typeof r === "number" ? r : r?.link_id;
    await req("link_set_types", { link_id: lid, link_types: [type] });
    return lid;
  };

  const S1 = span(ATLAS, "This sentence carries a single connection");
  const S2 = span(ATLAS, "This sentence draws a dispute and a remark");
  const S3 = span(ATLAS, "This sentence gathers a dispute, a comment, a reference, and a quotation at once");
  const S4 = span(ATLAS, "This sentence is supported by three passages that jointly form one end");
  const S5 = span(ATLAS, "This sentence is where the whole debate lands at once");

  // 1. one comment (Priya)
  await link("Priya Reviewer", W7, span(W7_TEXT, "Five connections now sit on one sentence"), "on the heat", 0, S1, "atlas s1", 1);

  // 2. dispute + comment
  await link("Ken Skeptic", W2, span(W2_REVISED, "my dispute is only about the learning cost"), "narrower point", 0, S2, "atlas s2", 3);
  await link("Priya Reviewer", W7, span(W7_TEXT, "the ability to rejoin a codebase after time away"), "definition", 0, S2, "atlas s2", 1);

  // 3. four kinds
  await link("Ken Skeptic", W2, span(W2_REVISED, "The burnout evidence is real"), "burnout", 0, S3, "atlas s3", 3);
  await link("Priya Reviewer", W7, span(W7_TEXT, "This disagreement turns on what learning means"), "on the dispute", 0, S3, "atlas s3", 1);
  await link("Alex Evidence", W3, span(W3_TEXT, "Three engineers on the release rota"), "ticket 12", 0, S3, "atlas s3", 2);
  await link("Marta Proposer", W5, span(W5_TEXT, "a written handoff would restore most of it"), "survey voice", 0, S3, "atlas s3", 4);

  // 4. gathered end: three fragments jointly fill one end (green)
  await become("Alex Evidence");
  const g = val(await req("link_create", {
    origin: W3, destination: ATLAS_ID,
    origin_ref: { kind: "single", work_context: W3, excerpt: "ticket 12", ...(() => { const s = span(W3_TEXT, "Three engineers on the release rota"); return { start_position: s.start, end_position: s.end }; })() },
    destination_ref: { kind: "single", work_context: ATLAS_ID, excerpt: "atlas s4", start_position: S4.start, end_position: S4.end },
  }));
  const gid = typeof g === "number" ? g : g?.link_id;
  await req("link_set_types", { link_id: gid, link_types: [2] });
  for (const frag of [
    [W4, W4_TEXT, "The handoff gap between releases left the checklist unowned", "handoff gap"],
    [W5, W5_TEXT, "I can hold context across a four-week gap", "survey voice"],
  ]) {
    const s = span(frag[1], frag[2]);
    await req("link_end_add_attachment", {
      link_id: gid, end_name: "LeftEnd",
      attachment: { kind: "single", work_context: frag[0], excerpt: frag[3], start_position: s.start, end_position: s.end },
    });
  }
  console.log("gathered end on S4");

  // 5. the crowded passage: 7 links
  await link("Ken Skeptic", W2, span(W2_REVISED, "my dispute is only about the learning cost"), "narrower point", 0, S5, "atlas s5", 3);
  await link("Ken Skeptic", W4, span(W4_TEXT, "two of the three errors trace to that window"), "root cause", 0, S5, "atlas s5", 3);
  await link("Priya Reviewer", W7, span(W7_TEXT, "the debate in miniature"), "on the heat", 0, S5, "atlas s5", 1);
  await link("Priya Reviewer", W7, span(W7_TEXT, "velocity, or the ability to rejoin"), "definition", 0, S5, "atlas s5", 1);
  await link("Alex Evidence", W3, span(W3_TEXT, "sustained overnight load"), "ticket 12", 0, S5, "atlas s5", 2);
  await link("Alex Evidence", W4, span(W4_TEXT, "the checklist unowned for nine days"), "handoff gap", 0, S5, "atlas s5", 2);
  await link("Marta Proposer", W5, span(W5_TEXT, "start losing it at five"), "survey voice", 0, S5, "atlas s5", 4);

  console.log("Connection Atlas ready:", ATLAS_ID);
  ws.close();
}

main().catch(e => { console.error(e.message); process.exit(1); });
