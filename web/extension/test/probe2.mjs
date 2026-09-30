// Focused probe: is the content script injected, and where does the
// marks chain stop? Collects ALL console messages (content scripts
// share the page's console sink).
import { chromium } from "playwright";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";

const EXT_SRC = path.resolve(import.meta.dirname, "..");
const extDir = fs.mkdtempSync(path.join(os.tmpdir(), "xudanu-probe2-"));
for (const f of ["content.js", "background.js"]) {
  fs.copyFileSync(path.join(EXT_SRC, f), path.join(extDir, f));
}
fs.copyFileSync(path.join(EXT_SRC, "test", "manifest.test.json"), path.join(extDir, "manifest.json"));

const userData = fs.mkdtempSync(path.join(os.tmpdir(), "xudanu-probe2-profile-"));
const context = await chromium.launchPersistentContext(userData, {
  headless: false,
  args: [`--disable-extensions-except=${extDir}`, `--load-extension=${extDir}`],
});

const sw = context.serviceWorkers().find((w) => w.url().includes("chrome-extension"));
console.log("SW:", sw ? sw.url() : "(none)");
await sw.evaluate(async () => {
  await chrome.storage.local.set({ serverUrl: "http://127.0.0.1:8080", enabled: true });
});
console.log("storage set:", JSON.stringify(await sw.evaluate(() => chrome.storage.local.get(null))));

const page = await context.newPage();
page.on("console", (m) => console.log(`[console.${m.type()}]`, m.text()));
page.on("pageerror", (e) => console.log("[pageerror]", String(e)));
page.on("requestfailed", (r) => console.log("[requestfailed]", r.url(), r.failure()?.errorText));

await page.goto("http://127.0.0.1:8899/article.html", { waitUntil: "networkidle" });
await page.waitForTimeout(4000);
const styleTag = await page.evaluate(() => !!document.getElementById("__xudanu_overlay_style"));
console.log("style tag present:", styleTag);
console.log("ribbons:", await page.locator(".xudanu-ribbon").count());
await page.screenshot({ path: "probe2.png" });
await context.close();
