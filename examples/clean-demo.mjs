#!/usr/bin/env node
// examples/clean-demo.mjs — remove demo links/works by id.
//   node examples/clean-demo.mjs link 0xf0 0xf1   (delete links)
//   node examples/clean-demo.mjs work 0x661       (archive works)
import WebSocket from "../web/app/node_modules/ws/index.js";

const mode = process.argv[2];
const ids = process.argv.slice(3).map((s) => parseInt(s, s.startsWith("0x") ? 16 : 10));
if (!["link", "work"].includes(mode) || ids.length === 0) {
  console.error("usage: clean-demo.mjs <link|work> <id>...");
  process.exit(1);
}
const csrf = await (await fetch("http://127.0.0.1:8080/csrf-token")).json();
const ws = new WebSocket(
  `ws://127.0.0.1:8080/xudanu?format=json&csrf_token=${encodeURIComponent(csrf.csrf_token ?? csrf.token ?? "")}`,
  { headers: { origin: "http://localhost:5173" } },
);
let id = 1; const pending = new Map();
const req = (op, payload) => new Promise((res, rej) => {
  const i = id++; pending.set(i, { res, rej });
  setTimeout(() => { if (pending.has(i)) { pending.delete(i); rej(new Error("timeout " + op)); } }, 10000);
  ws.send(JSON.stringify({ v: 2, type: "request", id: i, op, payload: payload ?? {} }));
});
ws.on("message", (d) => {
  const f = JSON.parse(d); const p = pending.get(f.id);
  if (p && (f.type === "response" || f.type === "error")) { pending.delete(f.id); f.type === "error" ? p.rej(new Error(f.message)) : p.res(f.value); }
});
await new Promise((r) => ws.once("open", r));
await req("session_connect"); await req("session_login_public");
for (const x of ids) {
  try {
    if (mode === "link") { await req("link_delete", { link_id: x }); console.log("deleted link 0x" + x.toString(16)); }
    else { await req("work_archive", { work_id: x }); console.log("archived work 0x" + x.toString(16)); }
  } catch (e) { console.log("0x" + x.toString(16) + ": " + e.message); }
}
ws.close(); process.exit(0);
