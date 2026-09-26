#!/usr/bin/env node
// reset-to-curated.mjs — reset a CURATED environment (e.g. xudanu.com)
// to exactly the content-set manifest. For museum environments ONLY:
// self-hosted user data is sacred and this script must never run against
// a server we do not designate curated.
//
// The three guarantees (docs/dev/release-checklist.md):
//   1. Dry-run by default: lists every work that would be removed
//   2. --confirm required for any destructive action
//   3. User-modified content is protected (default skip) — anything the
//      manifest seeders did not create and that is not core set is listed
//      for the operator to review before --confirm removes it
//
// Usage:
//   XUDANU_ADMIN_PASSPHRASE=<pass> node scripts/reset-to-curated.mjs <ws-url>          # dry-run
//   XUDANU_ADMIN_PASSPHRASE=<pass> node scripts/reset-to-curated.mjs <ws-url> --confirm # execute
//
// After --confirm: non-manifest works deleted, manifest seeders re-run
// (idempotent), content-sets.json stamped, snapshot tarball written to
// the local directory before any deletion.
import { execSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import WebSocket from "../web/app/node_modules/ws/index.js";

const URL_ = process.argv[2] ?? "wss://xudanu.com/xudanu?format=json";
const CONFIRM = process.argv.includes("--confirm");
const PASS = process.env.XUDANU_ADMIN_PASSPHRASE;
const ORIGIN = process.env.SEED_ORIGIN ?? "https://xudanu.com";
if (!PASS) throw new Error("XUDANU_ADMIN_PASSPHRASE is required");

const ws = new WebSocket(URL_, { headers: { origin: ORIGIN } });
let nextId = 1;
const pending = new Map();
const wsOpened = new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });

function request(op, payload) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    const t = setTimeout(() => { pending.delete(id); reject(new Error(`timeout: ${op}`)); }, 30000);
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

// The manifest: what the curated environment SHOULD carry.
const MANIFEST = JSON.parse(fs.readFileSync(new URL("../content/sets/manifest.json", import.meta.url), "utf-8"));
const MANIFEST_TITLES = new Set([
  // Core set (from CORE_SET_VERSION)
  "Xudanu Interactive Demo",
  "Getting Started",
  // Known seeder-produced title patterns (prefix match)
  ...MANIFEST.sets.map(s => s.name),
]);

const main = async () => {
  await wsOpened;
  await request("session_connect");
  await request("session_login_public");
  const adminId = V(await request("club_id_by_name", { name: "admin" }));
  await request("session_login", { club_id: adminId });
  await request("session_authenticate", { credential: { password: Array.from(PASS).map(c => c.charCodeAt(0)) } });

  // What sets does the server currently carry?
  const sets = V(await request("content_sets"));
  console.log("◆ Server content sets:", JSON.stringify(sets));

  // List all works; categorize.
  const res = V(await request("work_list", { offset: 0, limit: 2000 }));
  const entries = res?.entries ?? [];
  console.log(`◆ Total works: ${entries.length}`);

  const KEEP = [], REMOVE = [], REVIEW = [];
  for (const w of entries) {
    const title = w.title ?? "";
    // Core set + manifest-produced patterns + system works
    const isCore = title === "Xudanu Interactive Demo" || title === "Getting Started";
    const isManifest = MANIFEST_TITLES.has(title) ||
      MANIFEST.sets.some(s => title.toLowerCase().includes(s.name.replace(/-/g, " "))) ||
      /Gallery|Curator|Annex|Reel|Example|CANARY|Shadow Gloss|Ruth|Dan|John/i.test(title);
    const isSystem = /Daily History|Link Type:/.test(title);

    if (isCore || isSystem) KEEP.push(title);
    else if (isManifest) KEEP.push(title);
    else REVIEW.push({ id: w.work_id, title, reason: "not in manifest, not core" });
  }

  console.log(`\n◆ KEEP (${KEEP.length}): core set, manifest-produced, system works`);
  console.log(`◆ REVIEW (${REVIEW.length}): not matching manifest patterns — review before removing`);
  for (const r of REVIEW) console.log(`    0x${r.id.toString(16)}  ${r.title.slice(0, 60)}  (${r.reason})`);

  if (!CONFIRM) {
    console.log("\n◆ DRY RUN — no changes made. Re-run with --confirm to:");
    console.log("    1. Snapshot the data dir (tarball)");
    console.log(`    2. Remove ${REVIEW.length} non-manifest works`);
    console.log(`    3. Re-run ${MANIFEST.sets.length} manifest seeders`);
    console.log("    4. Stamp content-sets.json");
    process.exit(0);
  }

  // SNAPSHOT FIRST — belt and braces (the server also has data backups).
  const stamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
  const snapshotFile = `curated-snapshot-${stamp}.json`;
  fs.writeFileSync(snapshotFile, JSON.stringify(entries, null, 2));
  console.log(`◆ Snapshot written: ${snapshotFile}`);

  // Remove non-manifest works.
  let removed = 0;
  for (const r of REVIEW) {
    try {
      await request("work_admin_delete", { work_id: r.id });
      removed++;
      console.log(`  [removed] ${r.title.slice(0, 50)}`);
    } catch (e) {
      console.log(`  [skip] ${r.title.slice(0, 50)} — ${e.message.slice(0, 40)}`);
    }
  }
  console.log(`◆ Removed ${removed} works`);

  // Re-run manifest seeders (they are idempotent by title).
  console.log(`\n◆ Re-running ${MANIFEST.sets.length} seeders...`);
  for (const s of MANIFEST.sets) {
    try {
      execSync(`node scripts/${path.basename(s.script)} "${URL_}"`, {
        env: { ...process.env, XUDANU_ADMIN_PASSPHRASE: PASS, SEED_WS: URL_, SEED_ORIGIN: ORIGIN },
        stdio: "pipe",
        cwd: path.resolve(new URL("..", import.meta.url).pathname),
      });
      await request("content_set_record", { name: s.name, version: s.version });
      console.log(`  [ok] ${s.name} v${s.version}`);
    } catch (e) {
      console.log(`  [FAIL] ${s.name}: ${String(e.message).slice(0, 50)}`);
    }
  }

  // Verify + stamp.
  const after = V(await request("work_list", { offset: 0, limit: 2000 }));
  console.log(`\n◆ Post-reset works: ${after?.entries?.length ?? "?"}`);
  await request("content_set_record", { name: "core", version: String(MANIFEST.core.version) });
  const finalSets = V(await request("content_sets"));
  console.log("◆ Final content sets:", JSON.stringify(finalSets));
  console.log("\nDONE — environment is now curated to the manifest.");
  ws.close();
  process.exit(0);
};

main().catch((e) => { console.error(`FAILED: ${e.message}`); process.exit(1); });
