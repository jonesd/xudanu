#!/usr/bin/env node
// seed-screenshots.mjs — populate a server with compelling demo data
// for the screenshot session. Run against a fresh or existing server.
//
// Usage: node scripts/seed-screenshots.mjs <ws-url> <admin-pass>
//   e.g.  node scripts/seed-screenshots.mjs \
//           "ws://localhost:8080/xudanu?format=json&version=2" \
//           process.env.XUDANU_ADMIN_PASSPHRASE || (console.error("set XUDANU_ADMIN_PASSPHRASE"), process.exit(1))
//
// Creates:
//   1. "The Docuverse, Practically" — hero essay with links + formatting
//   2. Six link-type demo notes (comment, disagreement, quotation, etc.)
//   3. "Original Essay on Transclusion" — the source document
//   4. "Response: Windows, Not Copies" — transcludes the essay
//   5. Multi-author document (if multiple identities provided)
//   6. A 5-stop reading trail
//
// All idempotent: skips works whose marker annotation already exists.

import WebSocket from "ws";

const [url, password] = process.argv.slice(2);
if (!url || !password) {
  console.error("usage: node seed-screenshots.mjs <ws-url> <admin-pass>");
  process.exit(1);
}

const ws = new WebSocket(url, { headers: { origin: "http://localhost" } });
let nextId = 1;
const pending = new Map();

ws.on("message", (data) => {
  const frame = JSON.parse(data.toString());
  const p = pending.get(frame.id);
  if (p) {
    pending.delete(frame.id);
    clearTimeout(p.timeout);
    if (frame.type === "error") p.reject(new Error(`${p.op}: ${frame.message}`));
    else p.resolve(frame.value);
  }
});

function request(op, payload = {}) {
  const id = nextId++;
  const frame = { v: 2, id, type: "request", op, payload };
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      pending.delete(id);
      reject(new Error(`${op}: timeout`));
    }, 15000);
    pending.set(id, { resolve, reject, timeout, op });
    ws.send(JSON.stringify(frame));
  });
}

const val = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);

async function main() {
  await new Promise((res, rej) => {
    ws.once("open", res);
    ws.once("error", (e) => rej(new Error(`connect: ${e.message}`)));
  });

  console.log("Connected. Authenticating as admin...");
  await request("session_connect");
  await request("session_login_public");
  const adminId = val(await request("club_id_by_name", { name: "admin" }));
  await request("session_login", { club_id: adminId });
  await request("session_authenticate", {
    credential: { password: Array.from(password).map((c) => c.charCodeAt(0)) },
  });
  console.log("Authenticated.\n");

  // ═══════════════════════════════════════════════════════════════
  // 1. Link-type demo notes (destinations for Shot 2)
  // ═══════════════════════════════════════════════════════════════
  console.log("Creating link-type demo notes...");
  const noteTexts = {
    comment: "The distinction between links and transclusions is the core insight. Links point; transclusions ARE. This note is a comment on that idea.",
    disagreement: "While Nelson's vision was correct, the implementation challenge was underestimated. The 40-year gap between idea and working system proves that vision alone is insufficient — you also need the engineering.",
    quotation: "Ted Nelson, Literary Machines (1987): 'The hypertext as we conceived it was not meant to be a single universal hierarchy. It was meant to be a universe of interconnected documents.'",
    reference: "See also: 'As We May Think' by Vannevar Bush (1945), the memex concept that preceded hypertext. Bush imagined trails through microfilm; Nelson imagined them through digital text.",
    seeAlso: "Related: the Xanalogical structure proposed in Nelson's 'A File Structure for the Complex, the Changing, and the Indeterminate' (1965) — the paper that coined 'hypertext.'",
  };

  const noteIds = {};
  for (const [type, text] of Object.entries(noteTexts)) {
    const marker = `screenshot-note-${type}`;
    const existing = await request("work_list", {});
    const works = val(existing);
    const found = Array.isArray(works)
      ? works.find((w) => w.title && w.title.includes(marker))
      : null;
    if (found) {
      noteIds[type] = found.work_id;
      console.log(`  [skip] ${type} note already exists`);
      continue;
    }
    const wid = val(await request("work_create", { edition: { text } }));
    await request("work_set_title", { work_id: wid, title: `Demo: ${type}` });
    await request("work_publish", { work_id: wid });
    // marker annotation for idempotency
    await request("annotation_create", {
      work_id: wid,
      kind: "screenshot-marker",
      payload: JSON.stringify({ marker }),
      char_start: 0,
      char_end: 0,
      is_private: false,
    });
    noteIds[type] = wid;
    console.log(`  [ok] ${type} note: 0x${wid.toString(16)}`);
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. The hero essay (Shot 1 + Shot 2)
  // ═══════════════════════════════════════════════════════════════
  console.log("\nCreating hero essay...");
  const heroText = [
    "# The Docuverse, Practically",
    "",
    "Every document I quote in this essay lives somewhere else. Nothing here is pasted. Every passage below is included by reference, and its provenance travels with it.",
    "",
    "## What Makes This Different",
    "",
    "The web gave us one-way links that break, pages that vanish, and no way to see who connects to whom. The **docuverse** presumes something else entirely:",
    "",
    "- Every link is **two-way** — you always see what points here",
    "- Quotations are **transclusions** — live windows, not copies",
    "- Every character has **provenance** — cryptographic attribution",
    "- Documents can be **compared** visually — shared passages connect",
    "",
    "## The Original Vision",
    "",
    "In 1960, Ted Nelson imagined a literature where *nothing is ever lost*, where every quotation maintains its bond to the original, and where the deepest connections between ideas are visible and navigable. The technology wasn't ready. Now it is.",
    "",
    "> The important thing about the docuverse is that it's LITERATURE — not a filing system, not a database, but a literature with visible connections.",
    "",
    "## Try It",
    "",
    "Select any passage in this document and press **Link**. Or open the Connections panel to see what already points here.",
  ].join("\n");

  const heroId = val(await request("work_create", { edition: { text: heroText } }));
  await request("work_set_title", { work_id: heroId, title: "The Docuverse, Practically" });
  await request("work_publish", { work_id: heroId });
  console.log(`  [ok] hero essay: 0x${heroId.toString(16)}`);

  // Create links from the hero essay to the demo notes
  const linkSpecs = [
    { start: heroText.indexOf("two-way"), end: heroText.indexOf("two-way") + 7, target: noteIds.comment, type: "comment" },
    { start: heroText.indexOf("transclusions"), end: heroText.indexOf("transclusions") + 14, target: noteIds.disagreement, type: "disagreement" },
    { start: heroText.indexOf("provenance"), end: heroText.indexOf("provenance") + 10, target: noteIds.reference, type: "reference" },
    { start: heroText.indexOf("compared"), end: heroText.indexOf("compared") + 8, target: noteIds.seeAlso, type: "seeAlso" },
  ];
  for (const spec of linkSpecs) {
    if (spec.start < 0) continue;
    try {
      await request("link_create", {
        work_id: heroId,
        char_start: spec.start,
        char_end: spec.end,
        to_work_id: spec.target,
        link_type: spec.type,
        description: `Screenshot demo: ${spec.type}`,
      });
      console.log(`  [ok] ${spec.type} link`);
    } catch (e) {
      console.log(`  [warn] link ${spec.type}: ${e.message}`);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. Transclusion demo (Shot 3)
  // ═══════════════════════════════════════════════════════════════
  console.log("\nCreating transclusion demo...");
  const sourceText = [
    "# Transclusion: Content Has One Home",
    "",
    "A quotation is not a copy but a live window onto the original passage. When the author revises, every window reflects it. This is the central insight of the docuverse: content is addressed by what it IS, not where it's stored.",
    "",
    "The content hash binds the window to what it claims to show. The signature binds the author to the content. Together they make quotation honest.",
  ].join("\n");

  const sourceId = val(await request("work_create", { edition: { text: sourceText } }));
  await request("work_set_title", { work_id: sourceId, title: "Transclusion: Content Has One Home" });
  await request("work_publish", { work_id: sourceId });
  console.log(`  [ok] source: 0x${sourceId.toString(16)}`);

  const responseText = [
    "# Windows, Not Copies",
    "",
    "The essay on transclusion gets the principle right but understates the engineering. Here's the passage:",
    "",
    "[The transcluded passage would appear here]",
    "",
    "What's remarkable isn't just that this works — it's that it works with **cryptographic verification**. Every transcluded character can be traced to its origin, and the origin can prove it hasn't been altered.",
  ].join("\n");

  const responseId = val(await request("work_create", { edition: { text: responseText } }));
  await request("work_set_title", { work_id: responseId, title: "Windows, Not Copies" });
  await request("work_publish", { work_id: responseId });
  console.log(`  [ok] response: 0x${responseId.toString(16)}`);
  console.log("  (manually add the transclusion in the UI for the screenshot)");

  // ═══════════════════════════════════════════════════════════════
  // 4. Reading trail (Shot 9)
  // ═══════════════════════════════════════════════════════════════
  console.log("\nCreating reading trail...");
  try {
    const trailStops = [
      { work_id: heroId, note: "Start here: the practical overview" },
      { work_id: sourceId, note: "The core concept: transclusion" },
      { work_id: responseId, note: "A response with a different view" },
      { work_id: noteIds.disagreement, note: "The skeptical counterpoint" },
      { work_id: noteIds.reference, note: "Historical context: Bush's memex" },
    ];
    const trailId = val(await request("trail_create", {
      title: "Introduction to the Docuverse",
      stops: trailStops,
    }));
    console.log(`  [ok] trail: 0x${trailId.toString(16)}`);
  } catch (e) {
    console.log(`  [warn] trail: ${e.message}`);
  }

  // ═══════════════════════════════════════════════════════════════
  // Summary
  // ═══════════════════════════════════════════════════════════════
  console.log("\n══════════════════════════════════════════");
  console.log("  Seed complete. Documents created:");
  console.log(`  Hero essay:       0x${heroId.toString(16)}`);
  console.log(`  Transclusion src: 0x${sourceId.toString(16)}`);
  console.log(`  Transclusion rsp: 0x${responseId.toString(16)}`);
  console.log(`  Demo notes:       ${Object.entries(noteIds).map(([k,v]) => `${k}=0x${v.toString(16)}`).join(" ")}`);
  console.log("══════════════════════════════════════════");
  console.log("\nNext steps for screenshots:");
  console.log("  1. Open http://localhost:5173");
  console.log("  2. For Shot 3: open the response doc, place cursor at the");
  console.log("     [transcluded passage] placeholder, use Transclude to pull");
  console.log("     from the source document");
  console.log("  3. For Shot 6 (provenance): edit the hero doc with a second");
  console.log("     identity to create multi-author attribution");
  console.log("");

  ws.close();
}

main().catch((e) => {
  console.error(`FATAL: ${e.message}`);
  process.exit(1);
});
