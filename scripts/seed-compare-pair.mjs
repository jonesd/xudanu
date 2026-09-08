#!/usr/bin/env node
// seed-compare-pair.mjs — two related ORIGINAL works for trying the
// compare view: "The Docuverse Idea — A Short History" and its
// Counter-Reading (which quotes it verbatim). No third-party content.
// The critique quotes three paragraphs of the essay VERBATIM (large
// shared regions) and adds its own rebuttal + evidence paragraphs
// (unique green blocks on both sides). Usage:
//   node scripts/seed-compare-pair.mjs [ws-url]
import WebSocket from "ws";

const URL = process.argv[2] || "ws://127.0.0.1:8081/xudanu?format=json";
const ws = new WebSocket(URL, { headers: { origin: "http://127.0.0.1:8081" } });
let nextId = 1;
const pending = new Map();

function request(op, payload) {
  const id = nextId++;
  return new Promise((resolve, reject) => {
    const t = setTimeout(() => { pending.delete(id); reject(new Error(`timeout: ${op}`)); }, 30000);
    pending.set(id, { resolve, reject, timeout: t, op });
    ws.send(JSON.stringify({ v: 2, type: "request", id, op, payload: payload ?? {} }));
  });
}

function value(resp) {
  let v = resp && typeof resp === "object" && "value" in resp ? resp.value : resp;
  while (v && typeof v === "object" && typeof v.type === "string" && "value" in v) v = v.value;
  return v;
}

const ESSAY = `The Docuverse Idea — A Short History

In 1960 Ted Nelson named a problem nobody else had noticed: literature is a tangle of quotations, allusions, and rebuttals that paper flattens into copies. His proposed remedy, hypertext, is the half everyone adopted. The other half, the one he considered the actual invention, was transclusion: content included by reference, so a passage quoted anywhere remains the passage, traceable to its origin, updating when the origin changes.

The design took three decades to reach implementation. From 1988, a small team funded by Autodesk — Roger Gregory, Mark Miller, Stuart Greene, and others working with Nelson — built two systems now known as Green and Gold. Their core data structure, the enfilade, is a tree that serves simultaneously as an index and as a container: it can find content by fingerprint and apply structural transforms to it, in the same traversal. Addresses called tumblers give every span of every document a location in one universal coordinate space, so a quotation on one server can point precisely at its source on another.

Gold reached a partial release in 1992 and was open-sourced in 1999. It ran, which is more than most decades-long software projects achieve, but it never reached the public. The web, arriving at the same moment with simpler promises, took the world's attention: links that break, copies that drift, and page addresses that rot.

The lesson the docuverse idea keeps teaching is that connection is a commitment, not a convenience. A link that can break was never really a link; a quotation that drifts from its source was never really a quotation. The machinery to keep them whole is heavier than the machinery that does not care, and every generation rediscovers why the difference matters.

Whether the idea gets its second implementation is an open question. What is not open is the direction it points: toward literature that knows where its parts came from, and keeps knowing.`;

const CRITIQUE = `The Docuverse Idea — A Counter-Reading

The essay's framing deserves its clarity: content included by reference, so a passage quoted anywhere remains the passage, traceable to its origin, updating when the origin changes. As a definition it is impeccable. As history, it assigns the web the role of vulgar rival, which flatters the docuverse and misreads the web.

On the enfilade, the essay is right to marvel. The claim that it can find content by fingerprint and apply structural transforms in the same traversal is not marketing; it is the actual property, and nothing in mainstream document technology matches it. The critique begins at the next step: elegance of substrate has never once been sufficient for adoption, and Gold is the case study.

The strongest passage is the quietest one. The lesson the docuverse idea keeps teaching is that connection is a commitment, not a convenience. A link that can break was never really a link; a quotation that drifts from its source was never really a quotation. Turned around, that is also an indictment: thirty years of insisting the world is wrong about what it wants from documents is thirty years of not shipping.

This counter-reading's own confession: it is written inside a system that implements the essay's idea, quoting it by reference. The critique is transcluded.`;

async function main() {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await request("session_connect");
  await request("session_login_public");
  console.log("connected + logged in");

  const mk = async (name, text) => {
    const w = value(await request("work_create", { edition: { text } }));
    const id = typeof w === "number" ? w : w?.work_id;
    console.log(`work ${name} = ${id}`);
    return id;
  };
  const essayW = await mk("essay", ESSAY);
  const critiqueW = await mk("critique", CRITIQUE);

  // A Disagreement link between them: the critique's thesis passage
  // against the essay's thesis passage.
  const eSpan = (t) => {
    const i = ESSAY.indexOf(t);
    if (i < 0) throw new Error(`essay marker not found: ${t.slice(0, 30)}`);
    return { start: i, end: i + t.length, excerpt: t.slice(0, 80) };
  };
  const cSpan = (t) => {
    const i = CRITIQUE.indexOf(t);
    if (i < 0) throw new Error(`critique marker not found: ${t.slice(0, 30)}`);
    return { start: i, end: i + t.length, excerpt: t.slice(0, 80) };
  };
  const e1 = eSpan("content included by reference, so a passage quoted anywhere remains the passage");
  const c1 = cSpan("As history, it assigns the web the role of vulgar rival");
  const link = value(await request("link_create", {
    origin: essayW,
    destination: critiqueW,
    origin_ref: { kind: "single", work_context: essayW, excerpt: e1.excerpt, start_position: e1.start, end_position: e1.end },
    destination_ref: { kind: "single", work_context: critiqueW, excerpt: c1.excerpt, start_position: c1.start, end_position: c1.end },
    types: [3],
  }));
  console.log(`disagreement link = ${typeof link === "number" ? link : link?.link_id}`);
  console.log("READY: open both works and click ⇄ on the link row (or add them in Compare)");
  ws.close();
  process.exit(0);
}

ws.on("message", (data) => {
  try {
    let s = data.toString();
    const brace = s.indexOf("{");
    if (brace > 0) s = s.slice(brace);
    const frame = JSON.parse(s);
    if (frame.type === "response") {
      const p = pending.get(frame.id);
      if (p) { clearTimeout(p.timeout); pending.delete(frame.id); p.resolve(frame); }
    } else if (frame.type === "error") {
      const p = pending.get(frame.id);
      if (p) { clearTimeout(p.timeout); pending.delete(frame.id); p.reject(new Error(`${p.op}: ${frame.message}`)); }
    }
  } catch { /* ignore frames we do not track */ }
});

ws.on("close", () => { for (const p of pending.values()) { clearTimeout(p.timeout); p.reject(new Error("socket closed")); } pending.clear(); });

main().catch((e) => { console.error(e); process.exit(1); });
