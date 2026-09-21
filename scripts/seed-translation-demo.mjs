#!/usr/bin/node
// seed-translation-demo.mjs — translation as a first-class link type.
// One passage, two translations (French, German), a multi-ended
// Translation link, and a gathered mapping (two original sentences
// jointly -> one French sentence — languages don't align
// sentence-to-sentence). Then the original is EDITED so the German
// translation goes visibly stale: the link end migrates with the
// text while the translation stays put. Resume-safe.
//
// The demo proves: translation is a CONNECTION, not a transclusion —
// the translated words are the translator's own authored content,
// and the link records the correspondence permanently, both ways.
import WebSocket from "ws";

const url = process.argv[2] || "ws://127.0.0.1:8080/xudanu?format=json";
const token = await fetch("http://127.0.0.1:8080/csrf-token").then(r => r.json()).then(j => j.csrf_token);
const ws = new WebSocket(url + "&csrf_token=" + token, { headers: { origin: "http://localhost:5173" } });

let id = 1; const pending = new Map();
const req = (op, payload) => new Promise((res, rej) => {
  const i = id++;
  const t = setTimeout(() => rej(new Error("timeout " + op)), 30000);
  pending.set(i, { res, rej, t, op });
  ws.send(JSON.stringify({ v: 2, type: "request", id: i, op, payload: payload ?? {} }));
});
ws.on("message", d => {
  const f = JSON.parse(d);
  if (f.type === "response" || f.type === "error") {
    const p = pending.get(f.id);
    if (p) { pending.delete(f.id); clearTimeout(p.t);
      f.type === "error" ? p.rej(new Error(p.op + ": " + f.message)) : p.res(f.value); }
  }
});
const val = v => v && typeof v === "object" && "value" in v ? v.value : v;
const PASS = Array.from(new TextEncoder().encode("Deliberation-2026"));

const ORIGINAL_V1 = `The Garden Passage

Morning light. The garden does not explain itself; it simply opens. Anyone who walks in becomes part of its argument, whether they meant to or not.

Late frost. What survived the night is not the strongest plant, but the one that bent.`;

const ORIGINAL_V2 = `The Garden Passage

Morning light. The garden does not explain itself; it simply opens, without apology. Anyone who walks in becomes part of its argument, whether they meant to or not.

Late frost. What survived the night is not the strongest plant, but the one that bent.`;

const FRENCH = `Le Passage du Jardin

Lumière du matin. Le jardin ne s'explique pas; il s'ouvre, sans excuse. Quiconque y entre devient partie de son argument, qu'il l'ait voulu ou non.

Gel tardif. Ce qui a survécu à la nuit n'est pas la plante la plus forte, mais celle qui s'est pliée.`;

const GERMAN = `Der Garten-Passus

Morgenlicht. Der Garten erklärt sich nicht; er öffnet sich einfach. Wer eintritt, wird Teil seiner Argumentation, ob er will oder nicht.

Spätfrost. Was die Nacht überstand, ist nicht die stärkste Pflanze, sondern die sich gebogen hat.`;

const span = (text, needle) => {
  const i = text.indexOf(needle);
  if (i < 0) throw new Error("marker not found: " + needle.slice(0, 40));
  return { start: i, end: i + needle.length };
};

async function become(name) {
  await req("session_login_public").catch(() => {});
  await req("session_login_by_name", { club_name: name });
  await req("session_authenticate", { credential: { password: PASS } });
}

const mk = async (text) => {
  const w = val(await req("work_create", { edition: { text } }));
  const wid = typeof w === "number" ? w : w?.work_id;
  await req("work_publish", { work_id: wid });
  return wid;
};

async function main() {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await req("session_connect");
  await req("session_login_public");

  const existing = val(await req("work_list", {}));
  const entries = Array.isArray(existing) ? existing : (existing?.works ?? existing?.entries ?? []);
  if (entries.some(w => (w.title || "").startsWith("The Garden Passage"))) {
    console.log("already seeded — skipping");
    ws.close(); return;
  }

  // Register the Translation type (8) with a definition work.
  await become("Quinn Planner");
  const defW = await mk(`Link type: Translation\n\nA rendering of the target passage in another language. The connection says: these different words carry the same meaning. The translated text is the translator's own authored content; the link records the correspondence, permanently, in both directions.\n\nUnlike a quotation (which preserves the same words), a translation preserves the meaning in new words — and gets the same permanence, attribution, and drift-detection.`);
  await req("link_type_register", { type_id: 8, name: "Translation", definition_work: defW })
    .then(() => console.log("Translation type registered (8)"))
    .catch(e => console.log("register (continuing):", e.message.slice(0, 60)));

  // The original — Marta authors.
  await become("Marta Proposer");
  const ORIG = await mk(ORIGINAL_V1);
  console.log(`Garden Passage (original) = ${ORIG}`);

  // Translations — each translator authors their own words.
  await become("Priya Reviewer");
  const FR = await mk(FRENCH);
  await become("Ken Skeptic");
  const DE = await mk(GERMAN);
  console.log(`French = ${FR}, German = ${DE}`);

  // Multi-ended Translation link: original passage <-> FR <-> DE.
  // The passage = both paragraphs (the whole garden argument).
  const p1 = span(ORIGINAL_V1, "The garden does not explain itself");
  const p2f = span(FRENCH, "Le jardin ne s'explique pas");
  const p2d = span(GERMAN, "Der Garten erklärt sich nicht");
  const r = val(await req("link_create", {
    origin: ORIG, destination: FR,
    origin_ref: { kind: "single", work_context: ORIG, excerpt: "the garden passage", start_position: p1.start, end_position: p1.end },
    destination_ref: { kind: "single", work_context: FR, excerpt: "le passage du jardin", start_position: p2f.start, end_position: p2f.end },
  }));
  const T1 = typeof r === "number" ? r : r?.link_id;
  await req("link_set_types", { link_id: T1, link_types: [8] });
  await req("link_add_end", {
    link_id: T1, end_name: "German",
    end_ref: { kind: "single", work_context: DE, excerpt: "der garten-passus", start_position: p2d.start, end_position: p2d.end },
  });
  console.log(`multi-ended Translation link = ${T1} (original + fr + de)`);

  // Gathered mapping: TWO original sentences jointly -> ONE French
  // sentence (the frost couplet compresses in French).
  const f1 = span(ORIGINAL_V1, "What survived the night is not the strongest plant");
  const f2 = span(ORIGINAL_V1, "the one that bent");
  const frFrost = span(FRENCH, "Ce qui a survécu à la nuit n'est pas la plante la plus forte");
  const r2 = val(await req("link_create", {
    origin: ORIG, destination: FR,
    origin_ref: { kind: "single", work_context: ORIG, excerpt: "frost line 1", start_position: f1.start, end_position: f1.end },
    destination_ref: { kind: "single", work_context: FR, excerpt: "gel tardif", start_position: frFrost.start, end_position: frFrost.end },
  }));
  const T2 = typeof r2 === "number" ? r2 : r2?.link_id;
  await req("link_set_types", { link_id: T2, link_types: [8] });
  await req("link_end_add_attachment", {
    link_id: T2, end_name: "LeftEnd",
    attachment: { kind: "single", work_context: ORIG, excerpt: "frost line 2", start_position: f2.start, end_position: f2.end },
  });
  console.log(`gathered Translation link = ${T2} (two EN sentences jointly -> one FR)`);

  // The edit that makes the German stale: Marta revises the original.
  // The link ends migrate with the text; the translations don't move.
  await become("Marta Proposer");
  await req("work_grab", { work_id: ORIG });
  await req("work_revise", { work_id: ORIG, edition: { text: ORIGINAL_V2 } });
  await req("work_release", { work_id: ORIG }).catch(() => {});
  console.log("original revised (v2: 'without apology' added) — translations now stale by construction");

  console.log(`\nTranslation demo ready: original=${ORIG} fr=${FR} de=${DE} links=${T1},${T2}`);
  ws.close();
}

main().catch(e => { console.error(e.message); process.exit(1); });
