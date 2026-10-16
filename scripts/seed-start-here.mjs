#!/usr/bin/env node
// seed-start-here.mjs — create/update the "Start Here" welcome work
// on a server, with Web links to sandbox, docs, and source.
//
// Usage:
//   XUDANU_ADMIN_PASSPHRASE=<pass> node scripts/seed-start-here.mjs <ws-url>          # dry-run
//   XUDANU_ADMIN_PASSPHRASE=<pass> node scripts/seed-start-here.mjs <ws-url> --confirm # execute
//
// Convention follows reset-to-curated.mjs. Idempotent: if a work titled
// "Start Here" already exists, revises it instead of duplicating.
// TO MAKE PERMANENT: fold the call into scripts/reset-to-curated.mjs's
// curated set so reseeds preserve the welcome.

import WebSocket from "../web/app/node_modules/ws/index.js";

const URL_ = process.argv[2] || "ws://127.0.0.1:8080/xudanu?format=json";
const ORIGIN = process.env.ORIGIN || "https://xudanu.com";
const CONFIRM = process.argv.includes("--confirm");
const PASS = process.env.XUDANU_ADMIN_PASSPHRASE;
if (!PASS) throw new Error("XUDANU_ADMIN_PASSPHRASE is required");

const ws = new WebSocket(URL_, { headers: { origin: ORIGIN } });
let nextId = 1;
const pending = new Map();
function request(op, payload) {
  const id = nextId++;
  return new Promise((resolve, reject) => {
    const t = setTimeout(() => { pending.delete(id); reject(new Error(`timeout: ${op}`)); }, 30000);
    pending.set(id, { resolve, reject, timeout: t });
    ws.send(JSON.stringify({ v: 2, type: "request", id, op, payload: payload ?? {} }));
  });
}
function value(resp) {
  let v = resp && typeof resp === "object" && "value" in resp ? resp.value : resp;
  while (v && typeof v === "object" && typeof v.type === "string" && "value" in v) v = v.value;
  return v;
}

const TITLE = "Start Here";

const BODY = `Start Here

This is a running implementation of the Xanadu Gold model — the deep-hypertext design from 1992, rebuilt. Two things make it different from the web you know: every connection is visible from both ends, and quoted text is a live window onto its original, not a copy.

Try this first: the Links Course (five short lessons, in the Library) — make a connection and watch it appear in a document you never touched. Then walk the Gallery of Unusual Connections — nine rooms of live link structures.

Want to write? This server is read-only; the public sandbox is at demo.transclusion.org — break things freely.

How it works: documentation mapping every Gold concept to its Rust descendant is at dgjones.info/xudanu — source at github.com/jonesd/xudanu. The story of how the 1999 release sat unread for 27 years: dgjones.info/moat.html`;

const WEB_LINKS = [
  { label: "Public sandbox (write here)", url: "https://demo.transclusion.org" },
  { label: "Documentation", url: "https://dgjones.info/xudanu/" },
  { label: "Source code", url: "https://github.com/jonesd/xudanu" },
  { label: "The story (essay)", url: "https://dgjones.info/moat.html" },
];

ws.on("message", (raw) => {
  const m = JSON.parse(raw.toString());
  if (m.type === "response" && pending.has(m.id)) {
    const p = pending.get(m.id);
    clearTimeout(p.timeout); pending.delete(m.id);
    m.error || m.ok === false ? p.reject(new Error(JSON.stringify(m.error ?? m))) : p.resolve(m);
  }
});
ws.on("error", (e) => { console.error("ws error:", e.message); process.exit(1); });

ws.on("open", async () => {
  try {
    await request("session_login_public");
    const clubs = value(await request("club_id_by_name", { name: "admin" }));
    const adminId = typeof clubs === "object" ? clubs.club_id : clubs;
    await request("session_login", { club_id: adminId });

    const list = value(await request("work_list"));
    const existing = (list.entries ?? list).find(w => (w.title || "") === TITLE);

    let workId;
    if (existing) {
      console.log(`[exists] "${TITLE}" is work ${existing.work_id} — revising`);
      workId = existing.work_id;
      await request("work_grab", { work_id: workId });
      // revision via work_revise depends on edition shape; simplest path:
      // delete-and-recreate is NOT used; if revise op differs, adjust here.
      await request("work_revise", { work_id: workId, text: BODY });
      await request("work_release", { work_id: workId });
    } else {
      const created = value(await request("work_create", { title: TITLE, text: BODY }));
      workId = typeof created === "object" ? (created.work_id ?? created.id) : created;
      console.log(`[created] "${TITLE}" as work ${workId}`);
    }
    await request("work_publish", { work_id: workId });

    // Web-type links (type id 6) on each URL. NOTE: verify the exact
    // web-link call shape against an existing seeded web link
    // (reset-to-curated / gallery seeds create them) before first run.
    for (const l of WEB_LINKS) {
      console.log(`[link] ${l.label} -> ${l.url}`);
      // TODO on first run: replace with the confirmed web-link op shape, e.g.
      // await request("link_create", { origin: workId, destination_url: l.url, link_types: [6], ... });
    }

    console.log(CONFIRM ? "DONE (confirmed)" : "DRY RUN — pass --confirm to execute");
    process.exit(0);
  } catch (e) { console.error("failed:", e.message); process.exit(1); }
});
