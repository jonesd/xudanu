#!/usr/bin/node
// stress-connection.mjs — FR-69 connection resilience harness.
// Runs failure-injection scenarios against a SCRATCH server (own
// port, throwaway data dir) and asserts recovery criteria.
//
// Usage: node scripts/stress-connection.mjs [scenario]
//   scenarios: S1 (backend bounce + stale page heal), more to come
// Exit code 0 = all pass; 1 = any failure. Report on stdout.
import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import { spawn, execSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const PORT = 8090;
const BASE = `http://127.0.0.1:${PORT}`;
const DIST = "/Users/jonesd/code/xu-gold-2026/web/app/dist";
const SRC = "/Users/jonesd/code/xu-gold-2026/original-code/xanadugold/src-rust";

const results = [];
const log = (s) => console.log(s);

function mkScratchDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), "xudanu-stress-"));
}

let serverProc = null;
async function startServer(dataDir) {
  killServer(); // never inherit an orphan on the port
  serverProc = spawn(
    "cargo",
    ["run", "--features", "server", "--bin", "xudanu-server", "--",
     "run", `127.0.0.1:${PORT}`, dataDir, "--static-dir", DIST],
    { cwd: SRC, detached: true, stdio: ["ignore", "pipe", "pipe"] },
  );
  serverProc.stderr.on("data", () => {});
  serverProc.stdout.on("data", () => {});
  const t0 = Date.now();
  for (let i = 0; i < 60; i++) {
    await sleep(1000);
    try {
      const r = await fetch(`${BASE}/health`, { signal: AbortSignal.timeout(1500) });
      if (r.ok) return Date.now() - t0;
    } catch {}
    if (serverProc.exitCode != null) throw new Error(`server exited rc=${serverProc.exitCode}`);
  }
  throw new Error("server did not become healthy in 60s");
}

function killServer(sig = "SIGKILL") {
  // Kill by PORT — the only robust truth on macOS where cargo run
  // wraps the binary in a process tree; orphaned servers from a
  // failed prior kill would otherwise keep serving the port.
  try { execSync(`lsof -ti :${PORT} | xargs kill -9 2>/dev/null; true`, { shell: "/bin/zsh" }); } catch {}
  if (serverProc && serverProc.exitCode == null) {
    try { serverProc.kill(sig); } catch {}
  }
  serverProc = null;
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function bannerState(page) {
  return page.evaluate(() => {
    const t = document.body.innerText;
    if (/connection lost/i.test(t)) return "lost";
    if (/reconnect/i.test(t)) return "reconnecting";
    return "ok";
  });
}

async function openClient(browser) {
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  const wsOpens = [];
  const wsCloses = [];
  page.on("websocket", (ws) => {
    wsOpens.push(Date.now());
    ws.on("close", () => wsCloses.push(Date.now()));
  });
  await page.goto(BASE, { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(4000);
  return { page, wsOpens, wsCloses };
}

async function healthUp() {
  try {
    const r = await fetch(`${BASE}/health`, { signal: AbortSignal.timeout(1500) });
    return r.ok;
  } catch { return false; }
}

async function waitFor(page, pred, timeoutMs, label) {
  const t0 = Date.now();
  let last;
  while (Date.now() - t0 < timeoutMs) {
    last = await pred();
    if (last === true) return Date.now() - t0;
    await sleep(1000);
  }
  throw new Error(`timeout waiting for ${label} (last=${JSON.stringify(last)}) after ${timeoutMs}ms`);
}

async function scenarioS1() {
  const dataDir = mkScratchDir();
  log(`\n=== S1: backend bounce — client must heal without user action ===`);
  log(`scratch dir: ${dataDir}`);
  const bootMs = await startServer(dataDir);
  log(`server up in ${bootMs}ms`);

  const browser = await chromium.launch({ headless: true });
  try {
    const { page, wsOpens, wsCloses } = await openClient(browser);
    const initialBanner = await bannerState(page);
    log(`client loaded; banner=${initialBanner}; ws opens=${wsOpens.length}`);
    if (initialBanner !== "ok") throw new Error(`banner not ok at start: ${initialBanner}`);
    if (wsOpens.length < 1) throw new Error("no websocket opened at startup");

    // INJECT: kill the server hard — and PROVE it died
    log("inject: SIGKILL server");
    killServer("SIGKILL");
    const downMs = await (async () => {
      const t0 = Date.now();
      while (Date.now() - t0 < 10000) {
        if (!(await healthUp())) return Date.now() - t0;
        await sleep(500);
      }
      throw new Error("INJECTION FAILED: server still healthy after SIGKILL");
    })();
    log(`injection verified: health down after ${downMs}ms`);

    // The browser's own sockets must notice (TCP truth, UI-independent)
    const closesBefore = wsCloses.length;
    const noticeMs = await waitFor(page, async () => wsCloses.length > closesBefore, 15000, "browser ws to close");
    const bannerDuring = await bannerState(page);
    log(`browser noticed in ${noticeMs}ms (ws closes: ${closesBefore} -> ${wsCloses.length}); banner=${bannerDuring}`);

    // Dead for 10 seconds
    await sleep(10000);

    // RECOVER
    log("recover: restarting server");
    const rebootMs = await startServer(dataDir);
    log(`server back in ${rebootMs}ms`);

    // ASSERT: banner clears, a NEW ws opens, no reload — the attempt-105 case
    const opensBefore = wsOpens.length;
    const healMs = await waitFor(page, async () => {
      const b = await bannerState(page);
      return b === "ok" && wsOpens.length > opensBefore;
    }, 90000, "stale page to heal (banner ok + new ws)");
    log(`HEALED in ${healMs}ms after recovery, without reload (ws opens: ${opensBefore} -> ${wsOpens.length})`);

    // Functional check: the healed page can do live work again —
    // same-origin op + the app's own socket traffic. (The welcome
    // landing can block nav clicks on an empty server; not a
    // recovery failure.)
    const functional = await page.evaluate(async () => {
      try {
        const r = await fetch("/health");
        return r.ok;
      } catch { return false; }
    });
    const finalBanner = await bannerState(page);
    log(`post-heal op: fetch ${functional ? "ok" : "FAILED"}; banner=${finalBanner}`);
    if (!functional) throw new Error("client did not recover functionally");
    if (finalBanner !== "ok") throw new Error(`banner did not clear after heal: ${finalBanner}`);

    const notes = [];
    if (bannerDuring === "ok") notes.push("welcome view showed no outage banner (hardening item)");
    results.push(["S1", "PASS", `heal ${healMs}ms no reload; ${notes.join("; ") || "clean"}`]);
    await page.close();
  } catch (e) {
    results.push(["S1", "FAIL", e.message]);
  } finally {
    await browser.close().catch(() => {});
    killServer();
    execSync(`rm -rf ${dataDir}`);
  }
}

async function main() {
  const which = process.argv[2] ?? "S1";
  await scenarioS1();
  log("\n=== REPORT ===");
  for (const [id, status, detail] of results) log(`${status}  ${id}: ${detail}`);
  process.exit(results.every(([, s]) => s === "PASS") ? 0 : 1);
}

main().catch((e) => { console.error(e); process.exit(1); });
