import { chromium } from "playwright";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";

const EXT_SRC = path.resolve(import.meta.dirname, "..");
const extDir = fs.mkdtempSync(path.join(os.tmpdir(), "xudanu-probe-"));
for (const f of ["content.js", "background.js"]) {
  fs.copyFileSync(path.join(EXT_SRC, f), path.join(extDir, f));
}
fs.copyFileSync(path.join(EXT_SRC, "test", "manifest.test.json"), path.join(extDir, "manifest.json"));
console.log("ext dir:", extDir);

const swPromise = new Promise((res) => {
  const t = setTimeout(() => res("(none within 8s)"), 8000);
  // no context yet — placeholder
});

const userData = fs.mkdtempSync(path.join(os.tmpdir(), "xudanu-probe-profile-"));
const context = await chromium.launchPersistentContext(userData, {
    headless: false,
  args: [`--disable-extensions-except=${extDir}`, `--load-extension=${extDir}`],
});

const sws = context.serviceWorkers();
console.log("SWs at launch:", sws.map((w) => w.url()));
const evPromise = context.waitForEvent("serviceworker", { timeout: 8000 }).then((w) => w.url()).catch(() => "(none within 8s)");

const page = await context.newPage();
await page.goto("http://127.0.0.1:8899/article.html", { waitUntil: "networkidle" }).catch((e) => console.log("goto:", e.message));
await page.waitForTimeout(2500);
console.log("SWs after wake page:", context.serviceWorkers().map((w) => w.url()));
console.log("event SW:", await evPromise);

// content script injected? Probe a global it defines.
const injected = await page.evaluate(() => typeof window.__xudanuOverlayLoaded).catch(() => "eval-failed");
console.log("content script global:", injected);
await page.screenshot({ path: "probe.png" });
await context.close();
