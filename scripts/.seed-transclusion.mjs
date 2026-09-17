import WebSocket from "ws";
const token = process.argv[2];
const ws = new WebSocket("ws://127.0.0.1:8080/xudanu?format=json&csrf_token=" + token, { headers: { origin: "http://localhost:5173" } });
let id = 1; const pending = new Map();
const req = (op, payload) => new Promise((res, rej) => {
  const i = id++;
  const t = setTimeout(() => rej(new Error("timeout " + op)), 30000);
  pending.set(i, { res, rej, t, op });
  ws.send(JSON.stringify({ v: 2, type: "request", id: i, op, payload: payload ?? {} }));
});
ws.on("message", d => { const f = JSON.parse(d); if (f.type === "response" || f.type === "error") { const p = pending.get(f.id); if (p) { pending.delete(f.id); clearTimeout(p.t); f.type === "error" ? p.rej(new Error(p.op + ": " + f.message)) : p.res(f.value); } } });
const val = v => v && typeof v === "object" && "value" in v ? v.value : v;

async function main() {
  await new Promise(r => ws.once("open", r));
  await req("session_connect");
  const admin = val(await req("club_id_by_name", { name: "admin" }));
  await req("session_login", { club_id: admin });
  await req("session_authenticate", { credential: { password: Array.from(new TextEncoder().encode("greetingsforalltime")) } });
  console.log("admin session open");

  // Check if already exists
  const wl = val(await req("work_list", {}));
  const entries = Array.isArray(wl) ? wl : (wl?.works ?? wl?.entries ?? []);
  if (entries.some(w => (w.title || "").startsWith("Transclusion Demo"))) {
    console.log("already seeded"); ws.close(); return;
  }

  // Create source work
  const sourceW = val(await req("work_create", { edition: { text: "Transclusion Source\n\nThe garden is not a photograph; it is a performance that repeats daily.\n\nAnyone who says a map is the territory has never maintained either.\n\nThe ferry schedule survived three administrations." } }));
  const source = typeof sourceW === "number" ? sourceW : sourceW?.work_id;
  await req("work_publish", { work_id: source });
  console.log("source =", source);

  // Create demo work with text + transclusion
  const demoW = val(await req("work_create", { edition: { text: "Transclusion Demo\n\nThis paragraph contains a live transclusion. The quoted passage below is included by reference from the Transclusion Source document. When the source is edited, this passage updates.\n\n" } }));
  const demo = typeof demoW === "number" ? demoW : demoW?.work_id;
  await req("work_publish", { work_id: demo });
  console.log("demo =", demo);

  // Insert transclusion element at end of the demo work
  // The source text "The garden is not a photograph..." is at position 24-83
  const insertPos = 174; // after the intro text
  await req("element_insert", {
    work_id: demo,
    position: insertPos,
    element: {
      type: "transclusion",
      transclusion_source: source,
      transclusion_start: 24,
      transclusion_end: 83,
    },
  });
  console.log("transclusion element inserted at position", insertPos);

  console.log("Transclusion demo ready.");
  ws.close();
}
main().catch(e => { console.error(e.message); process.exit(1); });
