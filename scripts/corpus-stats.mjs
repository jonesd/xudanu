// corpus-stats.mjs — doc count, total text chars, avg size over the wire
import WebSocket from "ws";

const URL = process.argv[2] || "ws://127.0.0.1:8099/xudanu?format=json";
const ws = new WebSocket(URL, { headers: { origin: process.env.ORIGIN || "http://localhost:5173" } });
let nextId = 1;
const pending = new Map();

function request(op, payload) {
  const id = nextId++;
  return new Promise((resolve, reject) => {
    const t = setTimeout(() => { pending.delete(id); reject(new Error(`timeout: ${op}`)); }, 30000);
    pending.set(id, { resolve, reject, timeout: t });
    ws.send(JSON.stringify({ v: 2, type: "request", id, op, payload: payload ?? {} }));
  });
}
function value(resp) {
  let v = resp && typeof resp === "object" && "value" in resp ? resp.value : resp;
  while (v && typeof v === "object" && typeof v.type === "string" && "value" in v) v = v.value;
  return v;
}
function collectText(node, acc) {
  if (Array.isArray(node)) { for (const n of node) collectText(n, acc); return; }
  if (node && typeof node === "object") {
    for (const [k, v] of Object.entries(node)) {
      if ((k === "text" || k === "content") && typeof v === "string") acc.chars += v.length;
      else collectText(v, acc);
    }
  }
}

ws.on("message", (raw) => {
  const m = JSON.parse(raw.toString());
  if (m.type === "response" && pending.has(m.id)) {
    const p = pending.get(m.id);
    clearTimeout(p.timeout);
    pending.delete(m.id);
    m.error || m.ok === false ? p.reject(new Error(JSON.stringify(m.error ?? m))) : p.resolve(m);
  }
});
ws.on("error", (e) => { console.error("ws error:", e.message); process.exit(1); });

ws.on("open", async () => {
  try {
    const list = value(await request("work_list"));
    const works = Array.isArray(list) ? list : (list.entries ?? []);
    console.log("total_count:", list.total_count ?? works.length);
    let total = 0, n = 0, sizes = [];
    for (const w of works) {
      if (!w || typeof w !== "object") continue;
      const chars = w.char_count ?? 0;
      sizes.push([w.title ?? w.work_id, chars]);
      total += chars; n++;
    }
    const strangers = works.filter(w => w && typeof w === "object" && w.owner !== 1001 && w.owner !== 1000);
    console.log("STRANGER-CREATED DOCS (owner not 1000/1001):", strangers.length);
    for (const w of strangers.slice(0, 8)) console.log(`   [${w.owner}] "${(w.title || "(untitled)")}": ${w.char_count} chars, rev ${w.revision_count}`);
    console.log("DOCS:", n);
    console.log("TOTAL TEXT CHARS:", total);
    console.log("AVG CHARS/DOC:", n ? Math.round(total / n) : 0);
    console.log("NOT ADMIN-OWNED (incl. system 1000):", works.filter(w => w && typeof w === "object" && w.owner !== 1001).length);
    sizes.sort((a, b) => b[1] - a[1]);
    console.log("Largest:", sizes.slice(0, 5).map(s => `${s[0]} (${s[1]})`).join(" | "));
    console.log("Smallest:", sizes.slice(-3).map(s => `${s[0]} (${s[1]})`).join(" | "));
    process.exit(0);
  } catch (e) { console.error("failed:", e.message); process.exit(1); }
});
