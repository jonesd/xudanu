#!/usr/bin/env node
// examples/inspect-works.mjs — print id/title pairs from work_list.
//   node examples/inspect-works.mjs [filter-hex-ids...]
import WebSocket from "../web/app/node_modules/ws/index.js";

const filter = process.argv.slice(2).map((s) => parseInt(s, s.startsWith("0x") ? 16 : 10));
const csrf = await (await fetch("http://127.0.0.1:8080/csrf-token")).json();
const ws = new WebSocket(
  `ws://127.0.0.1:8080/xudanu?format=json&csrf_token=${encodeURIComponent(csrf.csrf_token ?? csrf.token ?? "")}`,
  { headers: { origin: "http://localhost:5173" } },
);
let id = 1; const pending = new Map();
const req = (op, payload) => new Promise((res, rej) => {
  const i = id++; pending.set(i, { res, rej });
  ws.send(JSON.stringify({ v: 2, type: "request", id: i, op, payload: payload ?? {} }));
});
ws.on("message", (d) => {
  const f = JSON.parse(d); const p = pending.get(f.id);
  if (p && (f.type === "response" || f.type === "error")) { pending.delete(f.id); f.type === "error" ? p.rej(new Error(f.message)) : p.res(f.value); }
});
await new Promise((r) => ws.once("open", r));
await req("session_connect"); await req("session_login_public");
const v = await req("work_list", { limit: 1000 });
const unwrapped = v && typeof v === "object" && "value" in v ? v.value : v;
const entries = unwrapped?.entries ?? unwrapped?.work_list ?? (Array.isArray(unwrapped) ? unwrapped : []);
for (const e of entries) {
  if (filter.length === 0 || filter.includes(e.work_id)) {
    console.log(`0x${e.work_id.toString(16)}  ${JSON.stringify(e.title)}`);
  }
}
ws.close(); process.exit(0);
