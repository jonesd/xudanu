#!/usr/bin/env node
// demo-links-gallery.mjs — seed the two works the screenshot gallery
// depends on: "One Clean Link" (frame 1) and "Multi-Link Showcase"
// (frames 4/4b). Usage: node demo-links-gallery.mjs [ws-url]
import WebSocket from "ws";
const url = process.argv[2] ?? "ws://127.0.0.1:8081/xudanu?format=json";
const ws = new WebSocket(url, { headers: { origin: "http://127.0.0.1:8081" } });
let nextId = 1;
const pending = new Map();
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
    if (p) { pending.delete(frame.id); clearTimeout(p.timeout);
      frame.type === "error" ? p.reject(new Error(`${p.op}: ${frame.message}`)) : p.resolve(frame.value); }
  }
});
const valueOf = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);
const mk = async (text) => {
  const w = valueOf(await request("work_create", { edition: { text } }));
  return typeof w === "number" ? w : w?.work_id;
};
const at = (text, m) => { const i = text.indexOf(m); if (i < 0) throw new Error("nf " + m.slice(0, 20)); return [i, i + m.length]; };
const linkCreate = async (o) => { const l = valueOf(await request("link_create", o)); return typeof l === "number" ? l : l?.link_id; };

async function main() {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await request("session_connect");
  await request("session_login_public");

  // Frame 1: One Clean Link — the whole primitive, nothing else.
  const l1text = "One Clean Link\n\nEverything on this page is ordinary text except one sentence, which is connected to another document. That is a link: an underlined passage, a small label naming the kind of connection, and a click that jumps across.";
  const l1 = await mk(l1text);
  const far = await mk("The Far End\n\nThe other side of the one clean link.");
  const [s1, e1] = at(l1text, "which is connected to another document");
  const l = await linkCreate({ origin: l1, destination: far,
    origin_ref: { kind: "single", work_context: l1, excerpt: "the one connected sentence", start_position: s1, end_position: e1 },
    destination_ref: { kind: "single", work_context: far, excerpt: "the other side", start_position: 14, end_position: 32 } });
  await request("link_set_types", { link_id: l, link_types: [2] });
  console.log(`one-clean-link = ${l1}`);

  // Frames 4/4b: Multi-Link Showcase — overlapping labels + gathered end.
  const text = "Multi-Link Showcase\n\nThe whole of this sentence carries one connection, and a phrase inside it carries another, so two labels must stack beside this single line in an orderly way.\n\nThese three opening sentences of the showcase each hold one passage of one gathered end; the margin chips count the set.\n\nThe performance repeats daily, and regulars greet the plants like staff, and nobody dares own the schedule.\n\nA final line links across to the reviewer so the panel lists more than one kind of row.";
  const work = await mk(text);
  const reviewer = await mk("Reviewer Notes\n\nThe counterposition lives here, one hop away from every sentence that disputes it.");
  const mkL = async (m, type, excerpt) => {
    const [s, e] = at(text, m);
    const lid = await linkCreate({ origin: work, destination: reviewer,
      origin_ref: { kind: "single", work_context: work, excerpt, start_position: s, end_position: e } });
    await request("link_set_types", { link_id: lid, link_types: [type] });
    return lid;
  };
  await mkL("The whole of this sentence carries one connection, and a phrase inside it carries another, so two labels must stack beside this single line in an orderly way.", 3, "the whole sentence, disputed");
  await mkL("a phrase inside it carries another", 4, "the inner phrase, quoted");
  await mkL("A final line links across to the reviewer so the panel lists more than one kind of row.", 1, "the closing line, commented");
  const g = await mkL("These three opening sentences of the showcase each hold one passage of one gathered end; the margin chips count the set.", 3, "passage one of the gathered end");
  const [s2, e2] = at(text, "The performance repeats daily, and regulars greet the plants like staff, and nobody dares own the schedule.");
  await request("link_end_add_attachment", { link_id: g, end_name: "LeftEnd",
    attachment: { kind: "single", work_context: work, excerpt: "passage two", start_position: s2, end_position: s2 + "The performance repeats daily,".length } });
  const third = s2 + text.substring(s2).indexOf("nobody dares own");
  await request("link_end_add_attachment", { link_id: g, end_name: "LeftEnd",
    attachment: { kind: "single", work_context: work, excerpt: "passage three", start_position: third, end_position: e2 } });
  console.log(`multi-link-showcase = ${work}`);
  console.log("GALLERY WORKS READY");
  ws.close();
  process.exit(0);
}
main().catch((e) => { console.error(e); process.exit(1); });
