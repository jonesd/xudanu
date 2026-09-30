// Playwright harness for the Xudanu Overlay extension (FR-79 2.4).
//
// Loads the TEST-VARIANT extension (identical content script; static
// registration scoped to the fixture server — Chrome can't grant the
// production manifest's optional host permissions without a user
// gesture), then verifies the render half of the exit criteria:
// ribbons on three page shapes, hover tooltip, edit survival,
// zero-render on unshadowed pages, and no console errors.
//
// Prereqs: dev server on :8080 (sandbox policy, --allow-loopback),
// fixture server on :8899, seed.mjs run once.
//
//   node test/overlay.test.mjs
import { chromium } from "playwright";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";

const EXT_SRC = path.resolve(import.meta.dirname, "..");
const SERVER = "http://127.0.0.1:8080";
const FX = "http://127.0.0.1:8899";

// Build the test-variant extension dir.
const extDir = fs.mkdtempSync(path.join(os.tmpdir(), "xudanu-overlay-ext-"));
fs.copyFileSync(path.join(EXT_SRC, "content.js"), path.join(extDir, "content.js"));
fs.copyFileSync(path.join(EXT_SRC, "background.js"), path.join(extDir, "background.js"));
fs.copyFileSync(path.join(EXT_SRC, "test", "manifest.test.json"), path.join(extDir, "manifest.json"));

const userData = fs.mkdtempSync(path.join(os.tmpdir(), "xudanu-overlay-profile-"));
const context = await chromium.launchPersistentContext(userData, {
  headless: false,
  args: [
    `--disable-extensions-except=${extDir}`,
    `--load-extension=${extDir}`,
  ],
});

let failures = 0;
const ok = (name, cond, extra = "") => {
  console.log(`${cond ? "PASS" : "FAIL"}  ${name}${extra ? ` — ${extra}` : ""}`);
  if (!cond) failures++;
};

try {
  // MV3 service workers sleep until first use — load a fixture page
  // first; its content-script "marks" message wakes the worker (it
  // will answer "no server configured"; rendering happens after the
  // reload below).
  const wake = await context.newPage();
  await wake.goto(`${FX}/article.html`, { waitUntil: "networkidle" });
  await wake.waitForTimeout(1500);

  let sw = context.serviceWorkers().find((w) => w.url().includes("chrome-extension"));
  if (!sw) sw = await context.waitForEvent("serviceworker", { timeout: 10000 });
  await sw.evaluate(async (server) => {
    await chrome.storage.local.set({ serverUrl: server, enabled: true });
  }, SERVER);
  await wake.close();

  const consoleErrors = [];
  context.on("page", (p) => {
    p.on("pageerror", (e) => consoleErrors.push(String(e)));
    // URL-aware 404 tracking: browser noise (favicon etc.) is fine;
    // extension or marks-endpoint 404s are not.
    p.on("response", (r) => {
      if (r.status() === 404 && /chrome-extension|overlay\/marks/.test(r.url())) {
        consoleErrors.push(`404: ${r.url()}`);
      }
    });
  });

  // ── 1. Article page: ribbons render ──────────────────────────
  const page = await context.newPage();
  await page.goto(`${FX}/article.html`, { waitUntil: "networkidle" });
  await page.waitForSelector(".xudanu-ribbon", { timeout: 10000 });
  const ribbons = await page.locator(".xudanu-ribbon").count();
  ok("article: ribbon renders", ribbons >= 1, `${ribbons} ribbon(s)`);
  const cls = await page.locator(".xudanu-ribbon").first().getAttribute("class");
  ok("article: direction styling (incoming → right)", cls?.includes("incoming") ?? false, cls ?? "");
  // Position truth: incoming must sit at the RIGHT edge and span the
  // multi-line passage (height > one line ≈ >30px).
  const pos = await page.evaluate(() => {
    const r = document.querySelector(".xudanu-ribbon")?.getBoundingClientRect();
    return r ? { x: Math.round(r.x), w: Math.round(r.width), h: Math.round(r.height), vw: window.innerWidth } : null;
  });
  ok("article: ribbon at RIGHT edge", !!pos && pos.x > pos.vw - 40, JSON.stringify(pos));
  ok("article: ribbon spans multi-line passage", !!pos && pos.h > 30, pos ? `h=${pos.h}px` : "none");

  await page.screenshot({ path: "shot-article.png", fullPage: false });

  // ── 2. Hover tooltip: type + far end ─────────────────────────
  // Load-settle mutations re-render ribbons under a stationary
  // cursor (Chrome synthesizes no fresh mouseenter), so drive the
  // handler deterministically: dispatch enter on the top ribbon.
  await page.waitForTimeout(3200); // two observer debounce cycles
  await page.evaluate(() => {
    document
      .querySelector(".xudanu-ribbon")
      .dispatchEvent(new MouseEvent("mouseenter", { bubbles: false }));
  });
  await page.waitForSelector(".xudanu-tip", { timeout: 5000 });
  const tip = await page.locator(".xudanu-tip").textContent();
  ok("hover: tooltip shows type + far end",
    /Disagreement/i.test(tip ?? "") && /Dispute/i.test(tip ?? ""),
    (tip ?? "").slice(0, 80));
  await page.screenshot({ path: "shot-tooltip.png" });

  // ── 3. Click-through opens Xudanu at the far work ────────────
  const popupPromise = context.waitForEvent("page", { timeout: 10000 });
  await page.locator(".xudanu-ribbon").first().click({ force: true, timeout: 8000 });
  const target = await popupPromise;
  await target.waitForLoadState("domcontentloaded");
  const url = target.url();
  ok("click: opens Xudanu deep link",
    url.startsWith(SERVER) && /work=0x[0-9a-f]+/.test(url) && /#C\d+/.test(url), url);

  // ── 4. Edit survival: insert a paragraph ABOVE the passage ───
  const moved = await page.evaluate(() => {
    const p = document.createElement("p");
    p.textContent = "A late-breaking editorial insert above the disputed passage. ";
    const host = document.querySelector("blockquote")?.parentElement ?? document.body;
    host.insertBefore(p, document.querySelector("blockquote"));
    return window.__xudanuOverlayRefresh?.();
  });
  await page.waitForTimeout(2500); // mutation-triggered re-render
  const ribbonsAfter = await page.locator(".xudanu-ribbon").count();
  ok("edit survival: ribbon persists after upstream insert", ribbonsAfter >= 1, `${ribbonsAfter} ribbon(s)`);

  // ── 5. docs + blog page shapes ───────────────────────────────
  for (const name of ["docs.html", "blog.html"]) {
    const p2 = await context.newPage();
    await p2.goto(`${FX}/${name}`, { waitUntil: "networkidle" });
    try {
      await p2.waitForSelector(".xudanu-ribbon", { timeout: 8000 });
      ok(`${name}: ribbon renders`, true);
      await p2.screenshot({ path: `shot-${name.replace(".html", "")}.png` });
    } catch {
      ok(`${name}: ribbon renders`, false, "no ribbon within 8s");
    }
    await p2.close();
  }

  // ── 6. Zero render: no shadow for this path ──────────────────
  const p3 = await context.newPage();
  await p3.goto(`${FX}/README.md`, { waitUntil: "networkidle" });
  await p3.waitForTimeout(2000);
  const stray = await p3.locator(".xudanu-ribbon").count();
  ok("unshadowed page: zero render", stray === 0);

  // ── 7. Console hygiene ───────────────────────────────────────
  const relevant = consoleErrors.filter((e) => !/favicon|net::ERR/i.test(e));
  ok("no console/page errors from the content script", relevant.length === 0,
    relevant.slice(0, 2).join(" | "));
} finally {
  await context.close();
  fs.rmSync(userData, { recursive: true, force: true });
}

console.log(failures === 0 ? "\nALL GREEN" : `\n${failures} FAILURE(S)`);
process.exit(failures === 0 ? 0 : 1);
