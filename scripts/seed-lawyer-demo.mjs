// seed-lawyer-demo.mjs — the classic Xanadu lawyer scenario, seeded
// over the wire: a memorandum assembling clauses from a statute, a
// precedent, and a client memo via live transclusion elements.
// Demonstrates: many sources, interleaved quotation + own analysis,
// follow-back, drift detection when a source is edited.
import WebSocket from "../web/app/node_modules/ws/index.js";

const ws = new WebSocket(
  `ws://127.0.0.1:8080/xudanu?format=json&login=public&csrf_token=${await fetch("http://127.0.0.1:8080/csrf-token").then((r) => r.json()).then((d) => d.csrf_token)}`,
  { headers: { Origin: "http://localhost:5173" } },
);
await new Promise((res, rej) => { ws.on("open", res); ws.on("error", rej); });
let seq = 0;
const call = (op, payload) => new Promise((resolve) => {
  const id = ++seq + 100;
  const on = (d) => { try { const m = JSON.parse(d.toString()); if (m.id === id || m.type === "error") { ws.off("message", on); resolve(m); } } catch {} };
  ws.on("message", on);
  ws.send(JSON.stringify({ v: 2, type: "request", id, op, payload: payload ?? {} }));
  setTimeout(() => { ws.off("message", on); resolve({ type: "timeout" }); }, 8000);
});
const ok = async (label, op, payload) => {
  const r = await call(op, payload);
  if (r.type === "error") { console.log(`FAIL ${label}: ${r.message}`); process.exit(1); }
  return r.value?.value;
};

const STATUTE = `State Privacy Act — Selected Sections

§3. Retention limits. A controller shall not retain personal data beyond the period reasonably necessary for the documented purpose, and in no case beyond twenty-four months absent express consent.

§4. Breach notification. Any controller experiencing a breach affecting more than five hundred residents shall notify the Attorney General within seventy-two hours of discovery.

§7. Lawful basis. Processing is lawful only where the controller identifies and records a basis enumerated in §7(a) through (e) before collection begins.

§9. Deletion on demand. Upon written request, a controller shall erase all personal data pertaining to the requester within thirty days and confirm completion in writing.`;

const PRECEDENT = `Kendall v. Whiteside, 214 F.3d 119 (Brennar Cir. 2001)

The court holds that the seventy-two hour clock in §4 begins at the moment a single employee with managerial responsibility acquires knowledge of the breach, not when the full scope is understood.

We are unpersuaded by the controller's argument that incomplete forensics should toll the statutory period. The legislature chose discovery, not comprehension.

The penalty provision applies per-breach, not per-recipient; a single incident affecting five hundred residents exposes the controller to one statutory maximum.`;

const MEMO = `Client Intake Memo — Meridian Health Partners

Facts: Meridian retained appointment records for four years under a legacy policy. No consent beyond the original intake form exists. On 3 March, an IT manager noticed an exposed database; the full scope was quantified eleven days later. The database contained records of approximately nine hundred residents.`;

// The compound: the lawyer's own words + interleaved live quotations.
// [Q1]..[Q5] are insertion points; we build text with markers, then
// insert transclusion elements at those positions back-to-front and
// strip the markers from the base text by building without them.
const P1 = "a controller shall erase all personal data pertaining to the requester within thirty days";
const P2 = "shall notify the Attorney General within seventy-two hours of discovery";
const P3 = "begins at the moment a single employee with managerial responsibility acquires knowledge of the breach";
const P4 = "The penalty provision applies per-breach, not per-recipient";
const P5 = "No consent beyond the original intake form exists";

const span = (text, phrase) => { const i = text.indexOf(phrase); return { start: i, end: i + phrase.length }; };
const s1 = span(STATUTE, P1), s2 = span(STATUTE, P2), s3 = span(PRECEDENT, P3), s4 = span(PRECEDENT, P4), s5 = span(MEMO, P5);

await ok("session", "session_connect");
const mk = async (title, text) => {
  const wid = await ok(`create ${title}`, "work_create", { edition: { text } });
  await ok("title", "work_set_title", { work_id: wid, title });
  return wid;
};
const statute = await mk("State Privacy Act (Excerpts)", STATUTE);
const precedent = await mk("Kendall v. Whiteside, 214 F.3d 119", PRECEDENT);
const memo = await mk("Client Intake Memo — Meridian Health", MEMO);

// Base text with single-char slots where transclusions will sit.
// Slots are ␡(U+2423); we record their positions then delete them
// by building segments and inserting elements between segments.
const SEGMENTS = [
  "MEMORANDUM — Data Retention Obligations, Meridian Health Partners\n\nTo: General Counsel. Re: exposure under the State Privacy Act.\n\nI. The deletion duty\n\nThe Act's operative command is unqualified: ",
  "« statute §9 »",
  "\n\nHere, Meridian retained records for four years — double the §3 ceiling — and holds no consent capable of extending it. The duty to erase matured the day the intake purpose ended.\n\nII. The notification clock\n\nSection 4 requires that ",
  "« statute §4 »",
  ". Kendall fixes when that clock starts: ",
  "« precedent »",
  ". Our IT manager's 3 March discovery therefore started a seventy-two hour clock that ran out long before scope was quantified on 14 March.\n\nIII. Exposure\n\nThe penalty structure compounds the concern: ",
  "« precedent penalties »",
  ". With nine hundred residents affected, this is a single breach at a single statutory maximum — cold comfort, but not ruin.\n\nIV. Weak point\n\nThe intake form may yet save the notification claim. ",
  "« memo »",
  " — if the form's language survives scrutiny as express consent under §3, the retention claim weakens and the memorandum's calculus changes. I recommend pulling the executed forms before responding to the Attorney General.",
];
// positions where elements go: after segments 0,2,4,6,8
const INSERTS = [
  { afterSeg: 0, src: statute, ...s1 },
  { afterSeg: 2, src: statute, ...s2 },
  { afterSeg: 4, src: precedent, ...s3 },
  { afterSeg: 6, src: precedent, ...s4 },
  { afterSeg: 8, src: memo, ...s5 },
];

// Build the base text WITHOUT slot markers; compute element positions.
let base = "";
const elemPos = [];
for (let i = 0; i < SEGMENTS.length; i++) {
  base += SEGMENTS[i];
  const ins = INSERTS.find((x) => x.afterSeg === i);
  if (ins) { elemPos.push({ pos: base.length, ...ins }); }
}
const compound = await ok("create compound", "work_create", { edition: { text: base } });
await ok("title compound", "work_set_title", { work_id: compound, title: "Memorandum — Data Retention Obligations" });

// Insert back-to-front so earlier positions stay valid.
elemPos.sort((a, b) => b.pos - a.pos);
for (const e of elemPos) {
  await ok(`element@${e.pos}`, "element_insert", {
    work_id: compound, position: e.pos,
    element: { type: "transclusion", transclusion_source: e.src, transclusion_start: e.start, transclusion_end: e.end },
  });
}

console.log("SEEDED:");
console.log(`  statute   0x${statute.toString(16)} (4 sections)`);
console.log(`  precedent 0x${precedent.toString(16)} (3 holdings)`);
console.log(`  memo      0x${memo.toString(16)} (facts)`);
console.log(`  BRIEF     0x${compound.toString(16)} — 5 live quotations from 3 sources`);
ws.close();
process.exit(0);
