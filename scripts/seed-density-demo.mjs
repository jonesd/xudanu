#!/usr/bin/node
// seed-density-demo.mjs — create a work with increasing link density
// (1, 2, 4, 8 links on the same passage) plus a transclusion pair.
// This demonstrates the visual progression: clean → stacked → density pill.
//
// Usage: node scripts/seed-density-demo.mjs [ws-url] [csrf-token]
import WebSocket from "ws";

const url = process.argv[2] || "ws://127.0.0.1:8080/xudanu?format=json";
const token = process.argv[3] || "";
const wsUrl = token ? url + "&csrf_token=" + token : url;
const ws = new WebSocket(wsUrl, { headers: { origin: "http://localhost:5173" } });

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

const DENSITY_DEMO = `Link Density Demo

This document shows what happens as more connections target the same passage.

1 link. This sentence has exactly one link — a single clean underline.
The reader sees one connection and its type.

2 links. This sentence has two links stacked — each at a 2px vertical offset.
Two underlines, both readable.

4 links. This sentence has four links stacked at increasing offsets.
Still readable, but the density is visible.

8 links. This sentence has eight links — the density pill appears (count ≥ 5).
The individual links collapse into a single pill. Click to expand.

Same document, three views. The passage above shows the mechanism: individual links are readable up to a point, then the system aggregates. Popular passages say "many connections here" without filling the screen.

Transclusion demo. The following passage is a live transclusion — included by reference, not copied. When the source document changes, this quotation updates automatically.
`;


const TRANSCLUSION_SOURCE = `Transclusion Source

This is the source document. The transclusion in the density demo quotes this passage.

The garden is not a photograph; it is a performance that repeats daily.

Edit this sentence and the transclusion in the demo document updates.
`;


async function main() {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await req("session_connect");
  const admin = val(await req("club_id_by_name", { name: "admin" }));
  await req("session_login", { club_id: admin });
  await req("session_authenticate", { credential: { password: Array.from(new TextEncoder().encode("greetingsforalltime")) } });
  console.log("admin session open");

  const existing = val(await req("work_list", {}));
  const entries = Array.isArray(existing) ? existing : (existing?.works ?? existing?.entries ?? []);
  if (entries.some(w => (w.title || "").startsWith("Link Density Demo"))) {
    console.log("already seeded — skipping");
    ws.close(); return;
  }

  const mk = async (name, text) => {
    const w = val(await req("work_create", { edition: { text } }));
    const wid = typeof w === "number" ? w : w?.work_id;
    await req("work_publish", { work_id: wid });
    console.log(`work ${name} = ${wid}`);
    return wid;
  };

  const demo = await mk("density-demo", DENSITY_DEMO);
  const source = await mk("transclusion-source", TRANSCLUSION_SOURCE);

  // Find the positions of the target sentences in the demo text
  const text = (txt, needle) => { const i = txt.indexOf(needle); return i < 0 ? null : i; };

  const one = text(DENSITY_DEMO, "This sentence has exactly one link");
  const two = text(DENSITY_DEMO, "This sentence has two links stacked");
  const four = text(DENSITY_DEMO, "This sentence has four links stacked");
  const eight = text(DENSITY_DEMO, "This sentence has eight links");

  const len = 40; // passage length for each

  const createLink = async (start, workId, type) => {
    const r = val(await req("link_create", {
      origin: demo, destination: workId,
      origin_ref: { kind: "single", work_context: demo, excerpt: "density demo",
        start_position: start, end_position: start + len },
      destination_ref: { kind: "single", work_context: workId, excerpt: "", start_position: 0, end_position: 0 },
    }));
    const linkId = typeof r === "number" ? r : r?.link_id;
    if (type) await req("link_set_types", { link_id: linkId, link_types: [type] });
    return linkId;
  };

  // 1 link on the "one" sentence (Comment)
  await createLink(one, source, 1);
  console.log("1 link on sentence 1");

  // 2 links on the "two" sentence (Comment + Reference)
  await createLink(two, source, 1);
  await createLink(two, source, 2);
  console.log("2 links on sentence 2");

  // 4 links on the "four" sentence (Comment + Reference + Disagreement + See Also)
  await createLink(four, source, 1);
  await createLink(four, source, 2);
  await createLink(four, source, 3);
  await createLink(four, source, 5);
  console.log("4 links on sentence 3");

  // 8 links on the "eight" sentence — triggers density pill (≥5)
  for (let i = 0; i < 8; i++) {
    await createLink(eight, source, (i % 5) + 1);
  }
  console.log("8 links on sentence 4 (density pill expected)");

  // Create a transclusion: the last paragraph of the demo includes a passage from source
  // Find the "Transclusion demo" paragraph position
  const transDemo = text(DENSITY_DEMO, "Transclusion demo.");
  if (transDemo !== null) {
    // Use element_insert to place a transclusion element
    await req("element_insert", {
      session_id: 0, work_id: demo, position: transDemo + 20,
      element: { type: "transclusion", source_work_id: source, char_start: 0, char_end: 132 },
    }).catch(e => console.log("transclusion insert: " + e.message.substring(0, 60)));
  }

  console.log("\nDensity demo ready. Open 'Link Density Demo' and scroll.");
  ws.close();
}

main().catch(e => { console.error(e.message); process.exit(1); });
