#!/usr/bin/env node
// examples/archive-works.mjs — archive works by id (demo cleanup).
//   node examples/archive-works.mjs 0x65b 0x65c ...
import WebSocket from "../web/app/node_modules/ws/index.js";

const ids = process.argv.slice(2).map((s) => parseInt(s, s.startsWith("0x") ? 16 : 10));
if (ids.length === 0) { console.error("usage: archive-works.mjs <id>..."); process.exit(1); }

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
for (const wid of ids) {
  try { await req("work_archive", { work_id: wid }); console.log("archived 0x" + wid.toString(16)); }
  catch (e) { console.log("0x" + wid.toString(16) + ": " + e.message); }
}
ws.close(); process.exit(0);
