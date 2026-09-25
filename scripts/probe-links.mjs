// probe-links.mjs — quick reality check: links per key work + detector persistence.
import WebSocket from "../web/app/node_modules/ws/index.js";
const ws = new WebSocket("ws://127.0.0.1:8080/xudanu?format=json", { headers: { origin: "http://localhost:5173" } });
let id = 1; const pend = new Map();
const req = (op, payload) => new Promise((res, rej) => {
  const i = id++;
  pend.set(i, { res, rej });
  setTimeout(() => rej(new Error("timeout " + op)), 20000);
  ws.send(JSON.stringify({ v: 2, type: "request", id: i, op, payload: payload ?? {} }));
});
ws.on("message", (d) => {
  const f = JSON.parse(d.toString());
  const p = pend.get(f.id);
  if (p) { pend.delete(f.id); f.type === "error" ? p.rej(new Error(f.op + ": " + f.message)) : p.res(f.value); }
});
const V = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);
const main = async () => {
  await new Promise(r => ws.once("open", r));
  await req("session_connect");
  await req("session_login_public");
  const dets = V(await req("detector_list"));
  const darr = dets?.detectors ?? dets ?? [];
  console.log("PUBLIC visitor sees", darr.length, "detectors:");
  darr.forEach(d => console.log("  #" + d.detector_id, String(d.kind).padEnd(9), "unread", d.unread, "— hits:", d.hits.map(h => h.link_id ? "link 0x" + h.link_id.toString(16) : "rev " + h.revision).join(", ")));
  const list = await req("work_list", { offset: 0, limit: 3000 });
  const entries = (list.value ?? list).entries ?? [];
  for (const [k, t] of [
    ["lobby", "Gallery — Lobby: The Gallery of Unusual Connections"],
    ["saga", "Gallery — Wing III · Room 12: The WidgetPerfect Saga"],
    ["plan", "Gallery Annex — Ruth's Technical Plan"],
  ]) {
    const w = entries.find(x => x.title === t);
    if (!w) { console.log(k, ": NOT FOUND"); continue; }
    const raw = await req("link_list_for_work", { work_id: w.work_id });
    console.log(k, "raw link payload:", JSON.stringify(raw).slice(0, 260));
  }
  ws.close();
  process.exit(0);
};
main().catch(e => { console.error("FAIL:", e.message); process.exit(1); });
