#!/usr/bin/env node
// links-workshop.mjs — build "The Links Workshop" on a live server:
// one readable document in which EVERY link structure exists live,
// with its explanation beside it. Ladder: same-doc simple → typed
// two-ended → several independents → multi-ended → gathered end-set
// → comment-on-link. Each section ends with a YOUR TURN task.
//
// Usage: node links-workshop.mjs [ws-url] [admin-passphrase]
//   default ws://127.0.0.1:8080/xudanu?format=json
import WebSocket from "ws";

const url = process.argv[2] ?? "ws://127.0.0.1:8080/xudanu?format=json";
const passphrase = process.argv[3] ?? process.env.XUDANU_ADMIN_PASSPHRASE;
if (!passphrase) { console.error("usage: node links-workshop.mjs <ws-url> <passphrase>  (or set XUDANU_ADMIN_PASSPHRASE)"); process.exit(1); }
const originUrl = "http://localhost:5173";
const ws = new WebSocket(url, { headers: { origin: originUrl } });

let nextId = 1;
const pending = new Map();
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
    if (p) {
      pending.delete(frame.id);
      clearTimeout(p.timeout);
      if (frame.type === "error") p.reject(new Error(`${p.op}: ${frame.message}`));
      else p.resolve(frame.value);
    }
  }
});
const value = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);

const WORKSHOP = `The Links Workshop

Every structure below is LIVE. Hover the underlined text to see the connection type; click it to jump to the far end; open the Links panel on the right to see each connection as a row. Read every link as a sentence with blanks: the type is the verb, each end fills a blank.

1. The simplest link — one document, two places
This sentence points back at the workshop's own title. It is one link, two ends, both on this page. Click it and you jump; come back with the browser back arrow.
YOUR TURN: select any sentence on this page and use Link to point it at the title line, just like this.

2. Two-ended and typed — the connection gets a verb
This sentence comments on a single line in Companion A. One link, type Comment: hover the underline and the tooltip names the verb.
YOUR TURN: select this sentence and make a Reference instead, pointing at any line of Companion A.

3. Several independent links
Not every underline belongs to one web. This page now carries three separate connections: this one cites a line of Companion A. This one disagrees with a claim in Companion B. And this one simply relates a Companion B line to the page. Three links, three rows in the panel, nothing to do with each other.
YOUR TURN: add a fourth of your own — any type, any target.

4. Multi-ended — one claim, three places
This sentence is one end of a THREE-ended link whose other ends live in Companion A and Companion B. It is not a chain and not a list: one comparison claim involving three places. Find its row in the panel (it shows three ends) and press the compare button — two arrows — to see all three passages side by side.
YOUR TURN: select a sentence, start a link, and on the final step use Additional ends to add a second target.

5. Gathered end-set — several passages, one blank
The subtle one. These three sentences are not three links and not three ends. The greenhouse kept the same plants for six years. Regulars began greeting the plants like staff. A garden is a performance that repeats daily. Together they form ONE end — the left side of a single Disagreement whose right end lives in Companion B. Hover each: the chip reads 1 of 3, 2 of 3, 3 of 3 — passages of one end, jointly filling one blank.
YOUR TURN: select a sentence, press the green Gather button, then select a second sentence and gather it into the same end.

6. Comment on a connection
Links are addressable too. The margin note attached to this page's Section 5 disagreement is a link ABOUT a link — a Comment whose end attaches to the connection itself, not to any passage. Look for the row with the attached-to-connection chip in the panel.
YOUR TURN: press the green comment symbol on any row of the Links panel.

The ladder you just climbed: simple, typed, several, multi-ended, gathered, meta. That is every kind of link there is. Everything else is these, arranged with intent.`;

const COMPANION_A = `Workshop Companion A

A garden is not a photograph; it is a performance that repeats daily.
The greenhouse kept the same plants for six years, and the tomato vine outgrew its trellis twice.
Anyone who says a map is the territory has never maintained either.
The schedule nobody dared own was pinned behind the door, softening at the corners.`;

const COMPANION_B = `Workshop Companion B

The ferry schedule survived three administrations without a single honest revision.
The ferry schedule is merely a suggestion that the river occasionally endorses.
Maintenance is what you do so that failure has to make an appointment.`;

const MARGIN = `Workshop margin note

This disagreement turns on whether a schedule is a document or a dance.`;

async function main() {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await request("session_connect");
  const adminId = value(await request("club_id_by_name", { name: "admin" }));
  await request("session_login", { club_id: adminId });
  await request("session_authenticate", {
    credential: { password: Array.from(new TextEncoder().encode(passphrase)) },
  });
  console.log("admin session open");

  const existing = {};
  const rawList = value(await request("work_list", {}));
  const wlEntries = Array.isArray(rawList) ? rawList : (rawList?.works ?? rawList?.entries ?? []);
  for (const w of wlEntries) {
    const t = (w.title ?? "");
    if (t.startsWith("The Links Workshop")) existing.workshop = w.work_id;
    if (t.startsWith("Workshop Companion A")) existing.a = w.work_id;
    if (t.startsWith("Workshop Companion B")) existing.b = w.work_id;
    if (t.startsWith("Workshop margin note")) existing.m = w.work_id;
  }
  const mk = async (name, text) => {
    const key = { workshop: "workshop", companionA: "a", companionB: "b", margin: "m" }[name];
    if (existing[key] != null) {
      console.log(`work ${name} = ${existing[key]} (existing, reused)`);
      return existing[key];
    }
    const w = value(await request("work_create", { edition: { text } }));
    const id = typeof w === "number" ? w : w?.work_id;
    await request("work_publish", { work_id: id });
    console.log(`work ${name} = ${id} (published)`);
    return id;
  };

  const linksDone = async (workId) => {
    try {
      const r = value(await request("link_list_for_work", { work_id: workId }));
      const n = Array.isArray(r) ? r.length : (r?.links?.length ?? 0);
      return n > 0;
    } catch { return false; }
  };
  if (existing.workshop != null && await linksDone(existing.workshop)) {
    console.log("workshop links already present — nothing to do");
    ws.close(); return;
  }
  const WS_ID = await mk("workshop", WORKSHOP);
  const CA = await mk("companionA", COMPANION_A);
  const CB = await mk("companionB", COMPANION_B);
  const MN = await mk("margin", MARGIN);

  const spans = {
    title: WORKSHOP.indexOf("The Links Workshop"),
    s1: WORKSHOP.indexOf("This sentence points back at the workshop's own title."),
    s2: WORKSHOP.indexOf("This sentence comments on a single line in Companion A."),
    s3a: WORKSHOP.indexOf("this one cites a line of Companion A."),
    s3b: WORKSHOP.indexOf("This one disagrees with a claim in Companion B."),
    s3c: WORKSHOP.indexOf("this one simply relates a Companion B line to the page."),
    s4: WORKSHOP.indexOf("This sentence is one end of a THREE-ended link"),
    g1: WORKSHOP.indexOf("The greenhouse kept the same plants for six years."),
    g2: WORKSHOP.indexOf("Regulars began greeting the plants like staff."),
    g3: WORKSHOP.indexOf("A garden is a performance that repeats daily."),
    a_garden: COMPANION_A.indexOf("a performance that repeats daily"),
    a_greenhouse: COMPANION_A.indexOf("the tomato vine outgrew its trellis twice"),
    a_map: COMPANION_A.indexOf("a map is the territory"),
    a_sched: COMPANION_A.indexOf("pinned behind the door"),
    b_survived: COMPANION_B.indexOf("survived three administrations"),
    b_suggest: COMPANION_B.indexOf("merely a suggestion that the river occasionally endorses"),
    b_maint: COMPANION_B.indexOf("failure has to make an appointment"),
    margin: MARGIN.indexOf("a document or a dance"),
  };
  const titleEnd = spans.title[0] + "The Links Workshop".length;

  const ref = (work, start, len, excerpt) => ({
    kind: "single", work_context: work, excerpt,
    start_position: start, end_position: start + len,
  });
  const len = (s, key) => {
    const table = { workshop: WORKSHOP, a: COMPANION_A, b: COMPANION_B, m: MARGIN };
    const src = table[s];
    const i = spans[key];
    if (key === "title") return titleEnd - spans.title;
    let nl = src.indexOf("\n", i);
    if (nl < 0) nl = src.length;
    let dot = src.indexOf(".", i);
    if (dot < 0 || dot > nl) dot = nl;
    return dot - i;
  };

  const mkLink = async (oWork, oKey, oText, dWork, dKey, dText, types, name) => {
    const r = value(await request("link_create", {
      origin: oWork, destination: dWork,
      origin_ref: ref(oWork, spans[oKey], len(oWork === WS_ID ? "workshop" : oWork === CA ? "a" : oWork === CB ? "b" : "m", oKey), oText),
      destination_ref: ref(dWork, spans[dKey], len(dWork === WS_ID ? "workshop" : dWork === CA ? "a" : dWork === CB ? "b" : "m", dKey), dText),
    }));
    const id = typeof r === "number" ? r : r?.link_id;
    if (types) await request("link_set_types", { link_id: id, link_types: types });
    console.log(`${name} = link ${id}`);
    return id;
  };

  // S1: same-doc simple (See Also 5)
  await mkLink(WS_ID, "s1", "title-pointer", WS_ID, "title", "workshop title", [5], "S1 same-doc simple");

  // S2: typed two-ended (Comment 1) -> companion A
  await mkLink(WS_ID, "s2", "comment on A", CA, "a_garden", "garden line", [1], "S2 Comment");

  // S3: three independents
  await mkLink(WS_ID, "s3a", "cite A", CA, "a_map", "map/territory", [2], "S3a Reference");
  await mkLink(WS_ID, "s3b", "disagree B", CB, "b_survived", "ferry survived", [3], "S3b Disagreement");
  await mkLink(WS_ID, "s3c", "relate B", CB, "b_maint", "maintenance", [5], "S3c See Also");

  // S4: multi-ended See Also (workshop + A + B)
  const s4 = await mkLink(WS_ID, "s4", "tri comparison", CA, "a_greenhouse", "tomato trellis", [5], "S4 multi-ended");
  await request("link_add_end", {
    link_id: s4, end_name: "Third",
    end_ref: ref(CB, spans.b_suggest, len("b", "b_suggest"), "ferry suggestion"),
  });
  console.log(`S4 third end added`);

  // S5: gathered end-set Disagreement (3 workshop passages -> B)
  const s5 = await mkLink(WS_ID, "g1", "gathered 1", CB, "b_suggest", "ferry suggestion", [3], "S5 gathered (seed link)");
  for (const k of ["g2", "g3"]) {
    await request("link_end_add_attachment", {
      link_id: s5, end_name: "LeftEnd",
      attachment: ref(WS_ID, spans[k], len("workshop", k), `gathered ${k}`),
    });
  }
  console.log("S5 gathered end: 3 passages on the workshop side");

  // S6: comment-on-link (margin note attaches to the S5 disagreement)
  const s6 = await mkLink(MN, "margin", "margin note", WS_ID, "s4", "section 4 sentence", [1], "S6 meta comment");
  await request("link_end_add_attachment", {
    link_id: s6, end_name: "Connection",
    attachment: { kind: "link_attachment", work_context: WS_ID, link_attachment: s5, excerpt: null, start_position: null, end_position: null },
  });
  console.log(`S6 attaches to disagreement ${s5}`);

  console.log("\nWorkshop ready. Open 'The Links Workshop' and read top to bottom.");
  ws.close();
}

main().catch((e) => { console.error(e.message); process.exit(1); });
