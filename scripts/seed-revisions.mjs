#!/usr/bin/env node
// seed-revisions.mjs — one document, four revisions (r0..r3) with
// distinct edits, for trying FR-59 revision compare (Summary panel →
// Version Timeline → pick two revisions → compare).
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

const R0 = `The Harbor Log

Morning. The ferry left the dock at six with fourteen passengers and returned with eleven; nobody asked where the three had gone, because the harbor never asks.

Midday. A container ship anchored outside the breakwater to wait out the tide, and the gulls settled on its railings like punctuation.

Evening. The lamp was lit at dusk, and the keeper recorded the wind from the northwest, rising.`;

const R1 = `The Harbor Log

Morning. The ferry left the dock at six with fourteen passengers and returned with eleven; nobody asked where the three had gone, because the harbor never asks.

Midday. A container ship anchored outside the breakwater to wait out the tide, and the gulls settled on its railings like punctuation. Two pilots argued about the tide tables in the wheelhouse.

Evening. The lamp was lit at dusk, and the keeper recorded the wind from the northwest, rising.`;

const R2 = `The Harbor Log

Morning. The ferry left the dock at six with fourteen passengers and returned with eleven; nobody asked where the three had gone, because the harbor never asks.

Midday. A container ship anchored outside the breakwater to wait out the tide, and the gulls settled on its railings like punctuation. Two pilots argued about the tide tables in the wheelhouse.

Evening. The lamp was lit at dusk, and the keeper recorded the wind from the northwest, falling.`;

const R3 = `The Harbor Log

Morning. The ferry left the dock at six with fourteen passengers and returned with eleven; nobody asked where the three had gone, because the harbor never asks.

Midday. A container ship anchored outside the breakwater to wait out the tide, and the gulls settled on its railings like punctuation. Two pilots argued about the tide tables in the wheelhouse.

Evening. The lamp was lit at dusk, and the keeper recorded the wind from the northwest, falling.

Night. The fog came in without ceremony and erased the harbor one mast at a time; only the bell remained, and it said what bells say.`;

async function main() {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await request("session_connect");
  await request("session_login_public");
  console.log("connected + logged in");

  const w = value(await request("work_create", { edition: { text: R0 } }));
  const workId = typeof w === "number" ? w : w?.work_id;
  console.log(`work "The Harbor Log" = ${workId} (r0 created)`);

  await request("work_grab", { work_id: workId });
  console.log("work grabbed");

  for (const [i, text] of [[1, R1], [2, R2], [3, R3]]) {
    await request("work_revise", { work_id: workId, edition: { text } });
    console.log(`r${i} committed`);
  }
  console.log(`READY: ${workId} has revisions r0..r3`);
  console.log("open the work → summary/info panel → Version Timeline → pick two revisions → compare");
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
  } catch { /* ignore */ }
});
ws.on("close", () => { for (const p of pending.values()) { clearTimeout(p.timeout); p.reject(new Error("socket closed")); } pending.clear(); });

main().catch((e) => { console.error(e); process.exit(1); });
