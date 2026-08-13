#!/usr/bin/env node
// Creates overlapping transclusions for UI testing
// Run: NODE_PATH=web/app/node_modules node scripts/test-overlap.cjs

const WebSocket = require("ws");

const WS_URL = "ws://localhost:8080/xudanu?format=json";
let msgId = 1;
const pending = new Map();

function send(ws, op, payload) {
  const id = msgId++;
  return new Promise((resolve, reject) => {
    pending.set(id, { resolve, reject });
    ws.send(JSON.stringify({ id, op, payload }));
    setTimeout(() => {
      if (pending.has(id)) {
        pending.delete(id);
        reject(new Error("timeout: " + op));
      }
    }, 5000);
  });
}

async function main() {
  const ws = new WebSocket(WS_URL);
  await new Promise((resolve, reject) => {
    ws.on("open", resolve);
    ws.on("error", reject);
    setTimeout(() => reject(new Error("connect timeout")), 3000);
  });

  await new Promise((resolve) => {
    ws.once("message", () => resolve());
  });
  console.log("Handshake received");

  ws.on("message", (data) => {
    try {
      const msg = JSON.parse(data.toString());
      const id = msg.id || msg.request_id;
      if (id && pending.has(id)) {
        const { resolve, reject } = pending.get(id);
        pending.delete(id);
        if (msg.error) reject(new Error(msg.error));
        else resolve(msg);
      }
    } catch {}
  });

  console.log("Connected");

  const sidResp = await send(ws, "session_connect", {});
  const sessionId = sidResp.value?.session_id || sidResp.session_id || sidResp.value;
  console.log("Session:", sessionId);

  await send(ws, "login_public", { session_id: sessionId });
  console.log("Logged in");

  const srcResp = await send(ws, "work_create", {
    session_id: sessionId,
    edition: { text: "AAAAABBBBBCCCCC" },
  });
  const srcId = srcResp.value?.work_id;
  console.log("Source work: 0x" + srcId.toString(16));

  const dstResp = await send(ws, "work_create", {
    session_id: sessionId,
    edition: { text: "before after" },
  });
  const dstId = dstResp.value?.work_id;
  console.log("Consumer work: 0x" + dstId.toString(16));

  await send(ws, "work_grab", { session_id: sessionId, work_id: dstId });

  console.log("Insert transclusion 1: [0,10] = 'AAAAABBBBB'");
  await send(ws, "element_insert", {
    session_id: sessionId,
    work_id: dstId,
    position: 6,
    element: {
      type: "transclusion",
      transclusion_source: srcId,
      transclusion_start: 0,
      transclusion_end: 10,
    },
  });

  console.log("Insert transclusion 2: [5,15] = 'BBBBBCCCCC' (overlap!)");
  await send(ws, "element_insert", {
    session_id: sessionId,
    work_id: dstId,
    position: 6,
    element: {
      type: "transclusion",
      transclusion_source: srcId,
      transclusion_start: 5,
      transclusion_end: 15,
    },
  });

  console.log("Migrating to inline...");
  await send(ws, "migrate_compound_to_inline", {
    session_id: sessionId,
    work_id: dstId,
  });

  const resolved = await send(ws, "resolve_inline_transclusions", {
    session_id: sessionId,
    work_id: dstId,
  });
  console.log("\nResolved:", JSON.stringify(resolved.value?.text));
  const ranges = resolved.value?.span_ranges || [];
  console.log("Ranges:", ranges.length);
  ranges.forEach((r, i) => {
    console.log(`  [${i}] flat [${r.flat_start}:${r.flat_end}] = "${r.resolved_content?.slice(0,30)}" from 0x${r.source_work_id.toString(16)}`);
  });

  console.log("\n=== DONE ===");
  console.log(`Open: http://localhost:5173/?work=0x${dstId.toString(16)}`);

  ws.close();
  process.exit(0);
}

main().catch((e) => { console.error(e); process.exit(1); });
