#!/usr/bin/env node
// loadtest-seed.mjs — seed N documents to find scale cliffs.
//
// Measures: creation throughput, memory pressure indicators, query
// latency, listing latency at increasing document counts.
//
// Usage: XUDANU_ADMIN_PASSPHRASE=<pass> node scripts/loadtest-seed.mjs [count] [ws-url]
//   default: 1000 docs, ws://127.0.0.1:8080
import WebSocket from "../web/app/node_modules/ws/index.js";

const COUNT = parseInt(process.argv[2] ?? "1000", 10);
const URL_ = process.argv[3] ?? "ws://127.0.0.1:8080/xudanu?format=json";
const PASS = process.env.XUDANU_ADMIN_PASSPHRASE;
if (!PASS) throw new Error("XUDANU_ADMIN_PASSPHRASE is required");

const ws = new WebSocket(URL_, { headers: { origin: "http://localhost:5173" } });
let nextId = 1;
const pending = new Map();
const wsOpened = new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });

function request(op, payload) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    const t = setTimeout(() => { pending.delete(id); reject(new Error(`timeout: ${op}`)); }, 60000);
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
const V = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);

// Realistic enterprise text: varied lengths, some with structure
const SAMPLES = [
  // ~2KB note
  "Meeting notes\n\nAttendees: " + "A".repeat(50) + "\n\n" +
  "Discussion items:\n" + Array.from({length: 20}, (_, i) =>
    `${i + 1}. ${"Discussion point with some detail. ".repeat(3)}`).join("\n"),
  // ~20KB document
  "Project Plan\n\n" + Array.from({length: 100}, (_, i) =>
    `Section ${i + 1}\n\n${"This section covers the approach, timeline, and dependencies. ".repeat(5)}\n`).join("\n"),
  // ~200KB report (10% of docs)
  "Annual Report\n\n" + Array.from({length: 200}, (_, i) =>
    `Chapter ${i + 1}: ${"C".repeat(30)}\n\n${"Detailed analysis with supporting data and methodology. ".repeat(20)}\n`).join("\n"),
];

function makeText(i) {
  if (i % 10 === 0) return SAMPLES[2];      // 10% large
  if (i % 3 === 0) return SAMPLES[1];       // 30% medium
  return SAMPLES[0];                         // 60% small
}

const main = async () => {
  await wsOpened;
  await request("session_connect");
  await request("session_login_public");
  const adminId = V(await request("club_id_by_name", { name: "admin" }));
  await request("session_login", { club_id: adminId });
  await request("session_authenticate", { credential: { password: Array.from(PASS).map(c => c.charCodeAt(0)) } });

  console.log(`seeding ${COUNT} documents...`);
  const t0 = Date.now();
  let created = 0, errors = 0;
  const checkpoints = new Map(); // count → elapsed ms

  // Check existing count
  const existing = V(await request("work_list", { offset: 0, limit: 1 }));
  const baseCount = existing?.total_count ?? existing?.entries?.length ?? 0;
  console.log(`existing works: ${baseCount}`);

  const BATCH = 100;
  for (let batch = 0; batch < COUNT / BATCH; batch++) {
    const bt = Date.now();
    const promises = [];
    for (let i = 0; i < BATCH; i++) {
      const idx = baseCount + batch * BATCH + i;
      const text = makeText(idx);
      promises.push(
        request("work_create", { edition: { text } })
          .then((w) => {
            const wid = typeof w === "number" ? w : w?.work_id;
            return request("work_set_title", { work_id: wid, title: `LoadTest-${String(idx).padStart(6, "0")}` });
          })
          .then(() => { created++; })
          .catch((e) => { errors++; if (errors <= 3) console.error(`  [err] ${e.message.slice(0, 60)}`); })
      );
    }
    await Promise.all(promises);

    const total = baseCount + (batch + 1) * BATCH;
    const elapsed = Date.now() - t0;
    if (total % 500 === 0 || batch === Math.floor(COUNT / BATCH) - 1) {
      // Measure listing latency at this scale
      const listStart = performance.now();
      const listRes = V(await request("work_list", { offset: 0, limit: 100 }));
      const listMs = (performance.now() - listStart).toFixed(0);
      const entries = listRes?.entries ?? [];
      const listCount = listRes?.total_count ?? entries.length;

      // Measure text search latency
      const searchStart = performance.now();
      await request("work_search", { query: "Section 1", limit: 10 }).catch(() => {});
      const searchMs = (performance.now() - searchStart).toFixed(0);

      // Measure link listing (on one work)
      const linkStart = performance.now();
      const probeWork = entries[0]?.work_id;
      if (probeWork) await request("link_list_for_work", { work_id: probeWork }).catch(() => {});
      const linkMs = (performance.now() - linkStart).toFixed(0);

      const rate = created / (elapsed / 1000);
      console.log(
        `  ${total.toLocaleString()} works | create: ${rate.toFixed(0)}/s | ` +
        `list: ${listMs}ms | search: ${searchMs}ms | links: ${linkMs}ms | ` +
        `errors: ${errors}`
      );
      checkpoints.set(total, { elapsed, listMs, searchMs, linkMs, rate });
    }
  }

  const totalTime = (Date.now() - t0) / 1000;
  console.log(`\ndone: ${created} created, ${errors} errors, ${totalTime.toFixed(1)}s`);
  console.log(`throughput: ${(created / totalTime).toFixed(0)} docs/s`);

  // Final health check
  const stats = V(await request("server_stats", {}));
  if (stats) {
    console.log(`server stats:`, JSON.stringify(stats).slice(0, 200));
  }

  ws.close();
  process.exit(0);
};

main().catch((e) => { console.error(`FAILED: ${e.message}`); process.exit(1); });
