import { defineConfig } from "@playwright/test";
import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

// Self-contained: every run boots a fresh in-process-data server
// (temp data dir, seeded Links Course) serving the classic client's
// own dist. No backend, no build of web/app, no shared state between
// runs. Requires ../../target/release/xudanu-server (cargo build
// --release --features server --bin xudanu-server).
const PORT = 8099;
const DATA = mkdtempSync(join(tmpdir(), "xudanu-classic-e2e-"));

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: 0,
  workers: 1,
  reporter: "list",
  timeout: 30_000,
  expect: { timeout: 10_000 },
  use: {
    baseURL: `http://127.0.0.1:${PORT}`,
    trace: "on-first-retry",
    screenshot: "only-on-failure",
  },
  projects: [{ name: "chromium", use: { browserName: "chromium" } }],
  webServer: {
    command: [
      "../../target/release/xudanu-server",
      `run 127.0.0.1:${PORT} ${DATA}`,
      "--edit-policy public-sandbox",
      "--seed-links-demo",
      "--static-dir dist",
      `--allowed-origin http://127.0.0.1:${PORT}`,
      "--allowed-origin http://localhost:" + PORT,
    ].join(" "),
    url: `http://127.0.0.1:${PORT}/health`,
    reuseExistingServer: false,
    timeout: 60_000,
  },
});
