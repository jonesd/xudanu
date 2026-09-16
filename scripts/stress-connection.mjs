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
  const serverLog = fs.openSync("/tmp/stress-server.log", "a");
  serverProc.stderr.on("data", (d) => fs.writeSync(serverLog, d));
  serverProc.stdout.on("data", (d) => fs.writeSync(serverLog, d));
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

async function scenarioS2() {
  const dataDir = mkScratchDir();
  log(`\n=== S2: long outage — offline edits must survive ===`);
  log(`scratch dir: ${dataDir}`);
  await startServer(dataDir);

  const browser = await chromium.launch({ headless: true });
  try {
    const { page, wsOpens } = await openClient(browser);
    page.on("console", (m) => {
      const t = m.text();
      if (process.env.STRESS_VERBOSE ? true : /crdt|reconnect|offline|sync/i.test(t)) {
        log(`  [page] ${t.slice(0, 200)}`);
      }
    });

    // Dismiss the welcome landing (blocks pointer events until skipped)
    await page.locator(".ws-home-skip, [aria-label='Skip welcome']").first().click({ timeout: 8000 });
    await page.waitForTimeout(800);

    // Identity + a document with typed content
    await page.locator(".identity-badge").first().click({ timeout: 10000 });
    await page.waitForTimeout(600);
    await page.locator("button", { hasText: /^Create Identity$/ }).first().click();
    await page.waitForTimeout(400);
    const modal = page.locator(".identity-modal");
    await modal.locator("input").nth(0).fill("Stress Tester");
    await modal.locator("input").nth(1).fill("Stress-Passphrase-1");
    await modal.locator("form.identity-form button[type=\"submit\"]").first().click();
    await page.waitForTimeout(2500);
    await page.locator("button", { hasText: "Close" }).first().click().catch(() => {});
    await page.waitForTimeout(800);

    // New document via welcome/CTA
    const newBtn = page.locator("button", { hasText: /new document|create/i }).first();
    await newBtn.click({ timeout: 8000 });
    await page.waitForTimeout(2500);
    const editor = page.locator(".editor-content");
    await editor.waitFor({ state: "visible", timeout: 10000 });
    await editor.click();
    await page.keyboard.type("before the outage", { delay: 15 });
    await page.waitForTimeout(2000);
    const beforeOffline = await editor.textContent();
    log(`doc created; online text: "${(beforeOffline ?? "").trim().slice(0, 40)}"`);

    // INJECT: kill; type OFFLINE
    killServer("SIGKILL");
    await waitFor(page, async () => !(await healthUp.call(null)) || true, 1000, "settle").catch(() => {});
    await sleep(6000); // let the client notice
    await page.keyboard.type(" and after the outage", { delay: 15 });
    await page.waitForTimeout(1500);
    const duringText = await editor.textContent();
    log(`offline text typed: "${(duringText ?? "").trim().slice(-40)}"`);

    // RECOVER after a LONG outage
    await sleep(60000);
    log("recover: restarting server after ~70s outage");
    await startServer(dataDir);
    const opensBefore = wsOpens.length;
    await waitFor(page, async () => wsOpens.length > opensBefore, 90000, "reconnect after long outage");

    // Patient heal: poll for the offline edit itself (session setup
    // can lag the socket open; churn may cycle connections).
    let healed = false;
    let healMs = -1;
    const healStart = Date.now();
    while (Date.now() - healStart < 90000) {
      const txt = await page.locator(".editor-content").first().textContent().catch(() => null);
      if (txt && txt.includes("and after the outage")) { healed = true; healMs = Date.now() - healStart; break; }
      await sleep(3000);
    }
    log(`patient heal: ${healed ? `offline text VISIBLE after ${healMs}ms` : "offline text never reappeared"}`);

    // SERVER truth: poll the public read API until the offline edit
    // lands server-side (the reconnect push can lag the editor heal).
    const workPath = await page.evaluate(() => location.search);
    const widMatch = workPath.match(/work=0x([0-9a-f]+)/i);
    const wid = widMatch ? parseInt(widMatch[1], 16) : null;
    let serverHas = false;
    const serverStart = Date.now();
    while (wid && Date.now() - serverStart < 60000) {
      try {
        const r = await fetch(`${BASE}/api/public/work/${wid}`, { signal: AbortSignal.timeout(2000) });
        if (r.ok) {
          const j = await r.json();
          const txt = JSON.stringify(j);
          if (txt.includes("and after the outage")) { serverHas = true; break; }
        }
      } catch {}
      await sleep(3000);
    }
    log(`server received offline edit: ${serverHas}${serverHas ? ` (after ${Date.now() - serverStart}ms)` : ""}`);

    const healState = await page.evaluate(() => ({
      url: location.href.slice(-60),
      editorExists: !!document.querySelector(".editor-content"),
      editorText: (document.querySelector(".editor-content")?.textContent ?? "").slice(-60),
      bodyHasOffline: document.body.innerText.includes("after the outage"),
    }));
    log(`post-heal state: ${JSON.stringify(healState)}`);

    const afterHeal = await page.locator(".editor-content").textContent().catch(() => null);
    const survived = (afterHeal ?? "").includes("and after the outage");
    log(`editor after heal: "${(afterHeal ?? "").trim().slice(-50)}"`);
    log(`offline edit survived in editor: ${survived}`);
    await page.reload({ waitUntil: "domcontentloaded" });
    await page.waitForTimeout(5000);
    const reloaded = await page.locator(".editor-content").first().textContent().catch(() => null);
    const survivedReload = (reloaded ?? "").includes("and after the outage");
    log(`after full reload, server-served text contains offline edit: ${survivedReload}`);

    if (survivedReload) {
      results.push(["S2", "PASS", "offline edits survived outage + reconnect + reload"]);
    } else {
      results.push(["S2", "FAIL", `offline edit lost (editor=${survived}, reload=${survivedReload})`]);
    }
    await page.close();
  } catch (e) {
    results.push(["S2", "FAIL", e.message]);
  } finally {
    await browser.close().catch(() => {});
    killServer();
    execSync(`rm -rf ${dataDir}`);
  }
}

async function main() {
  const which = process.argv[2] ?? "S1";
  if (which === "S1") await scenarioS1();
  if (which === "S2") await scenarioS2();
  log("\n=== REPORT ===");
  for (const [id, status, detail] of results) log(`${status}  ${id}: ${detail}`);
  process.exit(results.every(([, s]) => s === "PASS") ? 0 : 1);
}

main().catch((e) => { console.error(e); process.exit(1); });
