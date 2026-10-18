// make-brief-pdf.mjs — one-off: render the lawyer brief to PDF via
// the export renderer (TS module loaded through esbuild-register-free
// path: we transpile with esbuild if present, else inline port).
// Uses Playwright page.pdf on the generated HTML.
import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import fs from "node:fs";
import { execSync } from "node:child_process";

const resolved = JSON.parse(fs.readFileSync("/tmp/resolve.json", "utf8"));
// Server domain: same chain the app uses — advertised public address,
// else the globally unique server ID. Never "localhost".
const wellKnown = await fetch("http://127.0.0.1:8080/.well-known/xudanu-server.json")
  .then((r) => r.json()).catch(() => ({}));
const serverDomain = wellKnown.public_address || wellKnown.server_id?.slice(0, 16) || "unconfigured";
// normalize snake_case → the renderer's camelCase contract
const data = {
  text: resolved.text,
  spanRanges: (resolved.span_ranges ?? []).map((s) => ({
    flat_start: s.flat_start, flat_end: s.flat_end,
    source_work_id: s.source_work_id, char_start: s.char_start, char_end: s.char_end,
    resolved_content: s.resolved_content,
  })),
  sourceTitles: Object.fromEntries(Object.entries(resolved.source_titles ?? {}).map(([k, v]) => [Number(k), v])),
};

// transpile the TS renderer once with esbuild (devDependency of vite)
const OUT = "/tmp/export-document.mjs";
execSync(`npx esbuild web/app/src/export-document.ts --format=esm --outfile=${OUT}`, { stdio: "pipe" });
const { buildExportHtml } = await import(OUT);

const html = buildExportHtml(
  { title: "Memorandum — Data Retention Obligations", serverDomain, workId: 0x6e8 },
  data,
);
fs.writeFileSync("/tmp/brief-export.html", html);

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();
await page.setContent(html, { waitUntil: "load" });
await page.pdf({
  path: "/tmp/xudanu-brief.pdf",
  format: "Letter",
  margin: { top: "0.9in", bottom: "0.9in", left: "0.9in", right: "0.9in" },
  printBackground: true,
});
await browser.close();
console.log("✓ /tmp/xudanu-brief.pdf (" + Math.round(fs.statSync("/tmp/xudanu-brief.pdf").size / 1024) + "KB)");
