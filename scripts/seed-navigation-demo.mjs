#!/usr/bin/env node
// seed-navigation-demo.mjs — a small docuverse designed for CLICKING:
// four works of varied length, linked with ends of varied span
// length (phrase / sentence / paragraph), a three-ended link, a
// gathered end-set, and real inline transclusions. Original content.
// Usage: node seed-navigation-demo.mjs [ws-url]
import WebSocket from "ws";

const URL = process.argv[2] || "ws://127.0.0.1:8081/xudanu?format=json";
const ws = new WebSocket(URL, { headers: { origin: "http://127.0.0.1:8081" } });
let nextId = 1;
const pending = new Map();

function request(op, payload) {
  const id = nextId++;
  return new Promise((resolve, reject) => {
    const t = setTimeout(() => { pending.delete(id); reject(new Error(`timeout: ${op}`)); }, 30000);
    pending.set(id, { resolve, reject, timeout: t, op });
    ws.send(JSON.stringify({ v: 2, type: "request", id, op, payload: payload ?? {} }));
  });
}
function value(resp) {
  let v = resp && typeof resp === "object" && "value" in resp ? resp.value : resp;
  while (v && typeof v === "object" && typeof v.type === "string" && "value" in v) v = v.value;
  return v;
}

// ── Work 1: LONG — the hub ──────────────────────────────────────────
const GUIDE = `Field Guide to Signal Stations

The northern chain runs from the sandbar light to the broken tower at Cape Verity, eleven stations in all, manned in rotation by a crew that has learned to read weather in the behavior of birds. The guide that follows is their working document, amended in the margins over nine winters, and it begins where every shift begins: with the lamp itself.

The lamp is a contract with the horizon. Trimmed high, it promises a fixed point to anything afloat; trimmed low in fog, it becomes a rumor of itself, visible at three cables and no more. Keepers argue about the correct trim the way other trades argue about tools, and the argument is the point — the lamp is never a solved problem, only a kept one.

Fuel discipline governs everything else. A station holds forty days of oil at winter burn, and the logbook is a ledger of small decisions: half-light on clear nights, full burn when the barometer falls, and the terrible arithmetic of the last week, when the keeper must choose between visibility and endurance. Every story the crew tells about running dark ends with the relief boat arriving on day forty-one.

The signal tower at Cape Verity deserves its own entry. Struck twice by weather and rebuilt once by hand, it leans two degrees to the east, which the chart corrects for and the birds do not. From its gallery, on the four clear days of a northern February, you can see the whole chain at once: eleven lights in a gentle arc, each one a different keeper's judgment of the same night.

Birds are the instrument nobody maintains. Gulls loafing on the gallery rail mean wind within six hours; their absence in fair weather means it has already shifted offshore. The old keepers wrote this down as superstition and followed it as doctrine, and thirty years of logs have not yet contradicted them.

The chain survives on letters. Each station keeps a duplicate log, and the relief boat carries the copies, so that the history of every night exists twice, on different shelves, in different handwriting. When a log is lost to weather, the duplicate is transcribed back by hand — a week of copying, done gladly, because the alternative is a night that nobody remembers.

Relief day is the first Tuesday of the month, weather permitting, and weather has not permitted since the spring of the great ice, when the boat could not pass for six weeks and the northern stations kept their own counsel. The stations that endured those weeks still pour two cups at morning watch, one drunk and one set on the sill, and no keeper has ever asked why.

This guide is amended in the margins because the sea is amended at the center. What follows in the station appendices is the crew's own commentary, added year over year, and where the commentary contradicts the text, believe the commentary: it is newer, and it was written colder.`;

// ── Work 2: MEDIUM — links outward with varied end lengths ──────────
const NOTEBOOK = `Keeper's Notebook, Week 34

Monday. The barometer fell all night and I burned full from midnight, against the discipline, because the gulls left the rail at dusk and came back with a wind behind them that smelled of ice. The guide says to trust the birds, and I trusted them.

Wednesday. Re-read the entry on fuel discipline and the arithmetic of the last week. I have never run the tank to day thirty-eight; this week I came close, and the relief boat was late, and I understand now why the older entries grow so quiet toward the end.

Friday. A visitor from the southern chain, first in two years. She says the Cape Verity lean has become a landmark in its own right — sailors take a bearing on the lean itself. Two degrees of imperfection, kept faithfully for thirty years, is now a navigational truth.

Sunday. Calm. Wrote the duplicate log by lamplight and thought about the stations that endured the great ice, pouring the second cup. I have started doing it too, without deciding to.`;

// ── Work 3: SHORT — a disagreement ──────────────────────────────────
const DISPUTE = `The Meridian Dispute

The notebook for week 34 records a keeper burning full against the fuel discipline on the strength of bird behavior. This note disagrees, on the record.

Discipline exists precisely for the nights when every instinct says otherwise. The arithmetic of the last week is not a suggestion; it is the difference between a station that endures and a light that gutters. Bird lore has never once been tested against a tank at day thirty-five.

That said: the entry about the second cup on the sill is beyond dispute, and anyone who has stood a winter watch knows it.`;

// ── Work 4: VERY SHORT — transclusions live here ────────────────────
const ALMANAC = `Harbor Almanac Fragment, March

Copied by reference from the Field Guide (edits there will appear here):

Included from the Keeper's Notebook (the disputed entry):

— end of fragment —`;

async function main() {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await request("session_connect");
  await request("session_login_public");

  const mk = async (name, text) => {
    const w = value(await request("work_create", { edition: { text } }));
    console.log(`work ${name} = ${w}`);
    return w;
  };
  const guide = await mk("guide", GUIDE);
  const notebook = await mk("notebook", NOTEBOOK);
  const dispute = await mk("dispute", DISPUTE);
  const almanac = await mk("almanac", ALMANAC);

  const spanIn = (text, needle) => {
    const i = text.indexOf(needle);
    if (i < 0) throw new Error(`marker not found: ${needle.slice(0, 40)}`);
    return { start: i, end: i + needle.length };
  };

  // helper to create a link with a typed end on arbitrary spans
  const link = async (type, ends) => {
    const [o, ...rest] = ends;
    const r = value(await request("link_create", {
      origin: o.work,
      destination: rest[0].work,
      origin_ref: {
        kind: "single", work_context: o.work,
        excerpt: o.text.slice(0, 80),
        start_position: o.start, end_position: o.end,
      },
      destination_ref: {
        kind: "single", work_context: rest[0].work,
        excerpt: rest[0].text.slice(0, 80),
        start_position: rest[0].start, end_position: rest[0].end,
      },
      types: [type],
    }));
    for (const e of rest.slice(1)) {
      await request("link_add_end", {
        link_id: r,
        end_name: `end${e.work}`,
        end_ref: {
          kind: "single", work_context: e.work,
          excerpt: e.text.slice(0, 80),
          start_position: e.start, end_position: e.end,
        },
      });
    }
    return r;
  };
  const E = (work, text, needle) => {
    const s = spanIn(text, needle);
    return { work, start: s.start, end: s.end, text: needle };
  };

  // 1. SHORT-PHRASE Reference end (5 words) — notebook → guide
  await link(2, [
    E(notebook, NOTEBOOK, "because the gulls left the rail at dusk"),
    E(guide, GUIDE, "Gulls loafing on the gallery rail mean wind within six hours"),
  ]);
  console.log("link 1: phrase-length Reference (notebook → guide)");

  // 2. SENTENCE-length Quotation — notebook → guide
  await link(4, [
    E(notebook, NOTEBOOK, "The guide says to trust the birds, and I trusted them."),
    E(guide, GUIDE, "The old keepers wrote this down as superstition and followed it as doctrine, and thirty years of logs have not yet contradicted them."),
  ]);
  console.log("link 2: sentence-length Quotation (notebook → guide)");

  // 3. PARAGRAPH-length Disagreement — dispute → notebook (long ends both sides)
  await link(3, [
    E(dispute, DISPUTE, "Discipline exists precisely for the nights when every instinct says otherwise. The arithmetic of the last week is not a suggestion; it is the difference between a station that endures and a light that gutters. Bird lore has never once been tested against a tank at day thirty-five."),
    E(notebook, NOTEBOOK, "Monday. The barometer fell all night and I burned full from midnight, against the discipline, because the gulls left the rail at dusk and came back with a wind behind them that smelled of ice. The guide says to trust the birds, and I trusted them."),
  ]);
  console.log("link 3: paragraph-length Disagreement (dispute ↔ notebook)");

  // 4. THREE-ENDED Comment — guide → notebook → dispute
  await link(1, [
    E(guide, GUIDE, "A station holds forty days of oil at winter burn"),
    E(notebook, NOTEBOOK, "I have never run the tank to day thirty-eight; this week I came close"),
    E(dispute, DISPUTE, "The arithmetic of the last week is not a suggestion"),
  ]);
  console.log("link 4: three-ended Comment across all three");

  // 5. GATHERED end-set — See Also: two guide passages gathered into one end, → almanac
  const g1 = E(guide, GUIDE, "Each station keeps a duplicate log, and the relief boat carries the copies");
  const g2 = E(guide, GUIDE, "When a log is lost to weather, the duplicate is transcribed back by hand");
  const lk = value(await request("link_create", {
    origin: guide, destination: almanac,
    origin_ref: { kind: "single", work_context: guide, excerpt: g1.text.slice(0, 80), start_position: g1.start, end_position: g1.end },
    destination_ref: { kind: "single", work_context: almanac, excerpt: "almanac fragment", start_position: 0, end_position: 20 },
    types: [5],
  }));
  // gather the second passage into the origin end
  await request("link_end_add_attachment", {
    link_id: lk, end_name: "origin",
    attachment: {
      kind: "single", work_context: guide,
      excerpt: g2.text.slice(0, 80),
      start_position: g2.start, end_position: g2.end,
    },
  });
  console.log("link 5: gathered end-set (2 guide passages → almanac), See Also");

  // 6. REAL inline transclusions in the almanac — paragraph-length ends
  const paraGuide = spanIn(GUIDE, "The signal tower at Cape Verity deserves its own entry.");
  const pgEnd = GUIDE.indexOf("\n\n", paraGuide.start);
  const posGuide = ALMANAC.indexOf("(edits there will appear here):") + 31;
  await request("element_insert", {
    work_id: almanac, position: posGuide + 2,
    element: { type: "transclusion", transclusion_source: guide, transclusion_start: paraGuide.start, transclusion_end: pgEnd },
  });
  const paraNote = spanIn(NOTEBOOK, "Monday. The barometer fell all night");
  const pnEnd = NOTEBOOK.indexOf("\n\n", paraNote.start);
  const posNote = ALMANAC.indexOf("the disputed entry):") + 21;
  await request("element_insert", {
    work_id: almanac, position: posNote + 2,
    element: { type: "transclusion", transclusion_source: notebook, transclusion_start: paraNote.start, transclusion_end: pnEnd },
  });
  console.log("almanac: 2 inline transclusions (guide paragraph + disputed notebook entry)");

  console.log("\nREADY — navigation tour on :8081:");
  console.log("  Field Guide (long)   — hover underlines, thick descriptor boxes");
  console.log("  Keeper's Notebook    — hover boxes: phrase vs sentence vs paragraph ends");
  console.log("  The Meridian Dispute — click a Disagreement end → lands on the notebook passage");
  console.log("  Harbor Almanac       — live transclusions; edit sources, watch them update");
  ws.close();
  process.exit(0);
}

ws.on("message", (data) => {
  try {
    let s = data.toString();
    const brace = s.indexOf("{");
    if (brace > 0) s = s.slice(brace);
    const frame = JSON.parse(s);
    if (frame.type === "response") {
      const p = pending.get(frame.id);
      if (p) { clearTimeout(p.timeout); pending.delete(frame.id); p.resolve(frame); }
    } else if (frame.type === "error") {
      const p = pending.get(frame.id);
      if (p) { clearTimeout(p.timeout); pending.delete(frame.id); p.reject(new Error(`${p.op}: ${frame.message}`)); }
    }
  } catch { /* ignore */ }
});
ws.on("close", () => { for (const p of pending.values()) { clearTimeout(p.timeout); p.reject(new Error("socket closed")); } pending.clear(); });
main().catch((e) => { console.error(e); process.exit(1); });
