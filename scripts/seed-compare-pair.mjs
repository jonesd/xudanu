#!/usr/bin/env node
// seed-compare-pair.mjs — two related works for trying the compare
// view: "Black Swan — The Essay" and "Black Swan — The Critique".
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

const ESSAY = `Black Swan — The Essay

Before the discovery of Australia, every European swan sighting confirmed a universal law: all swans are white. One observation from one new continent broke the law forever. Nassim Taleb drew from this a lesson about knowledge itself: confidence built on unexamined evidence is not knowledge, it is expectation wearing the costume of proof.

The black swan has three features. First, it is an outlier, outside the range of regular expectations. Second, it carries extreme impact, either ruin or transformation. Third, and this is the cruel part, human nature fabricates explanations for it after the fact, making it seem explainable and predictable in hindsight.

History does not crawl, it jumps. The steamship, the first world war, the personal computer, the crash of nineteen twenty-nine, the rise of the internet — each sat outside the model of the day, then rearranged the day around itself. The narrative of steady progress is a story we tell ourselves by compressing the jumps into slopes.

The scandal of prediction is that we reward forecasters for being right for the wrong reasons and punish them for being wrong about the right things. Institutions aggregate these errors. A bank that survives nine years of calm is not proven safe; it is proven exposed to whatever the tenth year holds.

What the essay proposes is not pessimism but posture: place yourself where convexity lives, where surprise helps more than it hurts. Stop forecasting the floods; build the boat.

The final consolation is epistemic humility. The bird you have not seen is not therefore impossible. The catalogue of the seen is an argument about the seen, and nothing else.`;

const CRITIQUE = `Black Swan — The Critique

The essay's central image deserves its fame: one swan, one continent, and a universal law repealed in an afternoon. Taleb drew from this a lesson about knowledge itself: confidence built on unexamined evidence is not knowledge, it is expectation wearing the costume of proof. As a sentence, it is magnificent. As an epistemology, it proves too much — the same argument indicts all inference from experience, including the inference that black swans matter.

Consider the middle claim. The black swan has three features. First, it is an outlier, outside the range of regular expectations. Second, it carries extreme impact, either ruin or transformation. Third, and this is the cruel part, human nature fabricates explanations for it after the fact, making it seem explainable and predictable in hindsight. The critique: the definition is retrospective. Nothing is an outlier until it happens; after it happens, it joins the very catalogue the essay tells us not to trust.

On narrative, the essay is strongest. History does not crawl, it jumps. The steamship, the first world war, the personal computer, the crash of nineteen twenty-nine, the rise of the internet — each sat outside the model of the day, then rearranged the day around itself. Yet the jumps named are all famous, which is survivorship performing on stage. The critique would trade three named jumps for a census of the unnamed ones that failed to jump.

The posture proposed — convexity, building the boat instead of forecasting the flood — is sound engineering advice dressed as philosophy. Its weakness is the quiet assumption that surprise can be owned by positioning. Some floods rearrange what a boat is.

This critique's own confession: it, too, was written after the fact.`;

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
  const e1 = eSpan("confidence built on unexamined evidence is not knowledge, it is expectation wearing the costume of proof");
  const c1 = cSpan("it proves too much — the same argument indicts all inference from experience");
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
