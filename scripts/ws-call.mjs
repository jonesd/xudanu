#!/usr/bin/env node
// ws-call.mjs — one-shot authenticated WS call for smoke scripts.
// Logs in as admin with the password from env DEMO_ADMIN_PASS
// (default "admin12345"), sends one op, prints the response value.
// Usage: node ws-call.mjs <ws-url> <op> '<json-payload>'
import WebSocket from "ws";

const [url, op, payloadRaw] = process.argv.slice(2);
if (!url || !op) {
  console.error("usage: node ws-call.mjs <ws-url> <op> [json-payload]");
  process.exit(1);
}
const password = process.env.DEMO_ADMIN_PASS ?? "admin12345";
const payload = payloadRaw ? JSON.parse(payloadRaw) : {};

const ws = new WebSocket(url, { headers: { origin: "http://localhost" } });
let id = 1;
const req = (o, p) =>
  new Promise((res, rej) => {
    const rid = id++;
    const to = setTimeout(() => rej(new Error(`timeout ${o}`)), 15000);
    ws.send(JSON.stringify({ v: 2, type: "request", id: rid, op: o, payload: p ?? {} }));
    ws.on("message", function h(d) {
      const f = JSON.parse(d);
      if (f.id === rid) {
        ws.off("message", h);
        clearTimeout(to);
        res(f);
      }
    });
  });
const val = (f) => f?.value?.value ?? f?.value;

(async () => {
  await new Promise((r, rej) => {
    ws.once("open", r);
    ws.once("error", rej);
  });
  await req("session_connect");
  await req("session_login_public");
  try {
    const adminId = val(await req("club_id_by_name", { name: "admin" }));
    await req("session_login", { club_id: adminId });
    await req("session_authenticate", {
      credential: { password: Array.from(password).map((c) => c.charCodeAt(0)) },
    });
  } catch {
    /* public-only fallback */
  }
  const resp = await req(op, payload);
  console.log(JSON.stringify(val(resp) ?? resp));
  ws.close();
  process.exit(0);
})().catch((e) => {
  console.error(`ERR: ${e.message}`);
  process.exit(1);
});
