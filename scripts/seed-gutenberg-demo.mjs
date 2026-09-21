#!/usr/bin/env node
// seed-gutenberg-demo.mjs — import 3 connected books + create cross-references
//
// Books:
//   1. Pride and Prejudice (Austen, 1813) — the anchor text
//   2. The Yellow Wallpaper (Gilman, 1892) — women's autonomy, mental health
//   3. Herland (Gilman, 1915) — utopian women's society
//
// The demo shows: typed links between books, shared theme passages,
// reader annotations with endorsements, and a reading trail.
//
// Usage: node scripts/seed-gutenberg-demo.mjs <ws-url> <admin-pass>

import { readFileSync } from "fs";
import WebSocket from "ws";

const [url, password] = process.argv.slice(2);
if (!url || !password) {
  console.error("usage: node seed-gutenberg-demo.mjs <ws-url> <admin-pass>");
  process.exit(1);
}

const ws = new WebSocket(url, { headers: { origin: "http://localhost:5173" } });
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
  const rid = nextId++;
  return new Promise((res, rej) => {
    const t = setTimeout(() => { pending.delete(rid); rej(new Error(`${op}: timeout`)); }, 30000);
    pending.set(rid, { resolve: res, reject: rej, timeout: t, op });
    ws.send(JSON.stringify({ v: 2, type: "request", id: rid, op, payload }));
  });
}

const val = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);

// ── Gutenberg text parsing ────────────────────────────────────────

function stripGutenberg(raw) {
  // Remove Project Gutenberg header and footer
  const startMarker = /\*\*\* START OF (THE|THIS) PROJECT GUTENBERG EBOOK.*\*\*\*/i;
  const endMarker = /\*\*\* END OF (THE|THIS) PROJECT GUTENBERG EBOOK.*\*\*\*/i;
  let text = raw;
  const startMatch = text.match(startMarker);
  if (startMatch) text = text.slice(startMatch.index + startMatch[0].length);
  const endMatch = text.match(endMarker);
  if (endMatch) text = text.slice(0, endMatch.index);
  return text.trim();
}

function extractOpening(text, chars = 500) {
  // Get the first meaningful paragraph after any chapter heading
  const lines = text.split("\n");
  let started = false;
  let result = [];
  for (const line of lines) {
    const trimmed = line.trim();
    if (!started && trimmed.length > 50) started = true;
    if (started) {
      result.push(trimmed);
      if (result.join(" ").length > chars) break;
    }
  }
  return result.join(" ").slice(0, chars);
}

// ── Main ──────────────────────────────────────────────────────────

async function main() {
  await new Promise((r, j) => { ws.once("open", r); ws.once("error", j); });
  console.log("Connected. Authenticating...\n");

  await request("session_connect");
  await request("session_login_public");
  const adminId = val(await request("club_id_by_name", { name: "admin" }));
  await request("session_login", { club_id: adminId });
  await request("session_authenticate", {
    credential: { password: Array.from(password).map(c => c.charCodeAt(0)) },
  });
  console.log("Authenticated as admin\n");

  // ── Import the three books ────────────────────────────────────
  const books = [
    { file: "/tmp/gutenberg/pg1342.txt", title: "Pride and Prejudice", author: "Jane Austen", year: 1813 },
    { file: "/tmp/gutenberg/pg1952.txt", title: "The Yellow Wallpaper", author: "Charlotte Perkins Gilman", year: 1892 },
    { file: "/tmp/gutenberg/pg32.txt", title: "Herland", author: "Charlotte Perkins Gilman", year: 1915 },
  ];

  const workIds = {};
  for (const book of books) {
    console.log(`Importing: ${book.title} by ${book.author} (${book.year})`);
    const raw = readFileSync(book.file, "utf-8");
    const text = stripGutenberg(raw);
    console.log(`  ${text.length.toLocaleString()} characters`);

    const wid = val(await request("work_create", { edition: { text } }));
    await request("work_set_title", { work_id: wid, title: book.title });
    await request("work_publish", { work_id: wid });
    workIds[book.title] = wid;
    console.log(`  Work ID: 0x${wid.toString(16)}\n`);
  }

  // ── Create cross-references ────────────────────────────────────
  console.log("Creating cross-references...\n");

  // 1. P&P opening line → Yellow Wallpaper opening (thematic parallel:
  //    both open with a "universal truth" that the narrative subverts)
  const ppOpening = "It is a truth universally acknowledged";
  const ywOpening = "It is very seldom that mere ordinary people";

  // Create annotation-style links between the openings
  try {
    // Get text positions
    const ppText = val(await request("crdt_sync_open", { work_id: workIds["Pride and Prejudice"] }));
    const ppContent = (val(ppText) || ppText)?.current_text || "";
    const ppPos = ppContent.indexOf(ppOpening);
    console.log(`  P&P opening at position: ${ppPos}`);

    const ywText = val(await request("crdt_sync_open", { work_id: workIds["The Yellow Wallpaper"] }));
    const ywContent = (val(ywText) || ywText)?.current_text || "";
    const ywPos = ywContent.indexOf(ywOpening);
    console.log(`  Yellow Wallpaper opening at position: ${ywPos}`);

    // Link P&P → Yellow Wallpaper (comment on the parallel)
    if (ppPos >= 0 && ywPos >= 0) {
      await request("link_create", {
        work_id: workIds["Pride and Prejudice"],
        char_start: ppPos,
        char_end: ppPos + ppOpening.length,
        to_work_id: workIds["The Yellow Wallpaper"],
        to_char_start: ywPos,
        to_char_end: ywPos + ywOpening.length,
        link_type: "reference",
        description: "Both openings state a social 'truth' that the narrative proceeds to complicate — Austen ironically, Gilman claustrophobically",
      });
      console.log("  ✓ Reference link: P&P opening ↔ Yellow Wallpaper opening");
    }
  } catch (e) {
    console.log(`  [warn] opening link: ${e.message}`);
  }

  // 2. Yellow Wallpaper → Herland (same author, contrasting treatments)
  try {
    const ywText = val(await request("crdt_sync_open", { work_id: workIds["The Yellow Wallpaper"] }));
    const ywContent = (val(ywText) || ywText)?.current_text || "";
    const hlText = val(await request("crdt_sync_open", { work_id: workIds["Herland"] }));
    const hlContent = (val(hlText) || hlText)?.current_text || "";

    // Find "the resting cure" or similar theme in Yellow Wallpaper
    const ywTheme = "I am absolutely forbidden to \"work\" until I am well again";
    const hlTheme = "This is a land of women";

    const ywThemePos = ywContent.indexOf("forbidden");
    const hlThemePos = hlContent.indexOf("land of women");

    if (ywThemePos >= 0 && hlThemePos >= 0) {
      await request("link_create", {
        work_id: workIds["The Yellow Wallpaper"],
        char_start: ywThemePos,
        char_end: ywThemePos + 30,
        to_work_id: workIds["Herland"],
        to_char_start: hlThemePos,
        to_char_end: hlThemePos + 20,
        link_type: "reference",
        description: "Gilman's two treatments of women's autonomy: the constrained narrator vs. the free women of Herland",
      });
      console.log("  ✓ Reference link: Yellow Wallpaper ↔ Herland");
    }
  } catch (e) {
    console.log(`  [warn] theme link: ${e.message}`);
  }

  // ── Create reader annotations ─────────────────────────────────
  console.log("\nCreating reader annotations...\n");

  // Create two reader identities
  const readers = [
    { name: "Dr. Elena Vasquez", pass: "feminist-scholar-pass", role: "literary scholar" },
    { name: "book_club_reader", pass: "casual-reader-pass", role: "general reader" },
  ];

  for (const reader of readers) {
    try {
      await request("club_create_personal", {
        display_name: reader.name,
        password: Array.from(reader.pass).map(c => c.charCodeAt(0)),
      });
      console.log(`  Created identity: ${reader.name} (${reader.role})`);
    } catch (e) {
      console.log(`  [skip] ${reader.name}: ${e.message}`);
    }
  }

  // Create annotations as Dr. Vasquez (scholarly, endorsed)
  try {
    await request("session_login_by_name", { club_name: "Dr. Elena Vasquez" });
    await request("session_authenticate", {
      credential: { password: Array.from("feminist-scholar-pass").map(c => c.charCodeAt(0)) },
    });

    const ppText2 = val(await request("crdt_sync_open", { work_id: workIds["Pride and Prejudice"] }));
    const ppContent2 = (val(ppText2) || ppText2)?.current_text || "";
    const ppPos2 = ppContent2.indexOf(ppOpening);

    // Annotation on P&P opening
    await request("annotation_create", {
      work_id: workIds["Pride and Prejudice"],
      kind: "note",
      payload: JSON.stringify({
        text: "The irony is structural: 'universally acknowledged' is presented as received wisdom, but the novel's entire plot demonstrates that this 'truth' is a social construction that Elizabeth Bennet will spend 300 pages dismantling. Compare with Gilman's 'forbidden to work' — both are prison sentences dressed as kindness.",
        author: "Dr. Elena Vasquez",
      }),
      char_start: ppPos2,
      char_end: ppPos2 + ppOpening.length,
      is_private: false,
    });
    console.log("  ✓ Scholar annotation on P&P opening");

    // Annotation on Yellow Wallpaper
    const ywText2 = val(await request("crdt_sync_open", { work_id: workIds["The Yellow Wallpaper"] }));
    const ywContent2 = (val(ywText2) || ywText2)?.current_text || "";
    const ywPos2 = ywContent2.indexOf("I am absolutely forbidden");

    if (ywPos2 >= 0) {
      await request("annotation_create", {
        work_id: workIds["The Yellow Wallpaper"],
        kind: "note",
        payload: JSON.stringify({
          text: "The 'rest cure' prescribed here is the same treatment Gilman herself endured. Read alongside Herland, written 23 years later, you see Gilman imagining what the world looks like when women are NOT forbidden to work.",
          author: "Dr. Elena Vasquez",
        }),
        char_start: ywPos2,
        char_end: ywPos2 + 30,
        is_private: false,
      });
      console.log("  ✓ Scholar annotation on Yellow Wallpaper");
    }
  } catch (e) {
    console.log(`  [warn] scholar annotations: ${e.message}`);
  }

  // Create annotation as book_club_reader (casual, less formal)
  try {
    await request("session_login_public");
    await request("session_login_by_name", { club_name: "book_club_reader" });
    await request("session_authenticate", {
      credential: { password: Array.from("casual-reader-pass").map(c => c.charCodeAt(0)) },
    });

    const ppText3 = val(await request("crdt_sync_open", { work_id: workIds["Pride and Prejudice"] }));
    const ppContent3 = (val(ppText3) || ppText3)?.current_text || "";
    const ppPos3 = ppContent3.indexOf(ppOpening);

    await request("annotation_create", {
      work_id: workIds["Pride and Prejudice"],
      kind: "note",
      payload: JSON.stringify({
        text: "I never noticed how the first sentence is basically the plot summary. Every time I reread this I catch something new. What does everyone think about the Bennet parents?",
        author: "book_club_reader",
      }),
      char_start: ppPos3,
      char_end: ppPos3 + ppOpening.length,
      is_private: false,
    });
    console.log("  ✓ Reader annotation on P&P opening");
  } catch (e) {
    console.log(`  [warn] reader annotation: ${e.message}`);
  }

  // ── Create a reading trail ────────────────────────────────────
  console.log("\nCreating reading trail...\n");
  try {
    await request("session_login_public");
    await request("session_login", { club_id: adminId });
    await request("session_authenticate", {
      credential: { password: Array.from(password).map(c => c.charCodeAt(0)) },
    });

    const trailId = val(await request("trail_create", {
      name: "Three Writers on Women's Lives",
      introduction: "Three books, three decades, three visions of women's autonomy. Start with Austen's ironic 'truth', see its prison in Gilman's wallpaper, then imagine its opposite in Herland.",
    }));
    console.log(`  Trail ID: ${trailId}`);

    const trailStops = [
      { work_id: workIds["Pride and Prejudice"], note: "Start with the famous opening — a 'universal truth' that isn't" },
      { work_id: workIds["The Yellow Wallpaper"], note: "Gilman shows the cost of the 'truth': a woman forbidden to work, losing her mind" },
      { work_id: workIds["Herland"], note: "Gilman imagines the opposite: a world where the 'truth' never existed" },
    ];

    for (const stop of trailStops) {
      await request("trail_add_stop", {
        trail_id: trailId,
        work_id: stop.work_id,
        note: stop.note,
      });
      console.log(`  ✓ Trail stop: ${stop.note.slice(0, 50)}...`);
    }
  } catch (e) {
    console.log(`  [warn] trail: ${e.message}`);
  }

  // ── Summary ────────────────────────────────────────────────────
  console.log("\n" + "═".repeat(60));
  console.log("  Demo corpus ready!");
  console.log("═".repeat(60));
  for (const [title, wid] of Object.entries(workIds)) {
    console.log(`  ${title}: 0x${wid.toString(16)}`);
  }
  console.log("\n  Cross-references created between books");
  console.log("  Scholar + casual reader annotations attached");
  console.log("  Reading trail: 'Three Writers on Women's Lives'");
  console.log("\n  Open http://localhost:5173 and explore!");
  console.log("═".repeat(60));

  ws.close();
}

main().catch(e => {
  console.error(`FATAL: ${e.message}`);
  process.exit(1);
});
