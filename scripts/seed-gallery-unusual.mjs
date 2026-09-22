#!/usr/bin/env node
// seed-gallery-unusual.mjs — THE GALLERY OF UNUSUAL CONNECTIONS
//
// A museum of exotic link structures, seeded as real works with real
// links. Nine exhibit rooms across three wings, a lobby whose floor
// plan is itself wired with links, and a published Curator's Tour
// trail threading the whole thing.
//
//   Lobby  — the floor plan (navigation BY links)
//   Wing I · Form
//     Room 1  The Spectrum Sentence      (all six types on one sentence)
//     Room 2  The Junction Word          (one word, 5 departures + 2 arrivals)
//     Room 3  The Nested Scope           (links inside and across links)
//   Wing II · Depth
//     Room 4  Genealogy of a Quotation   (quote of a quote of a quote)
//     Room 5  A Link About a Link        (commentary recursion, depth 3)
//   Wing III · Contention
//     Room 6  The Rebuttal Constellation (3 gathered passages vs 1)
//     Room 7  The Five-Way Junction      (one connection, five named ends)
//     Room 8  The Standing Dispute       (two documents, four disagreements)
//   The Fabric
//     Room 9  The Live Window            (transclusions, not links)
//
// Usage: node seed-gallery-unusual.mjs [ws-url]
//   default: ws://127.0.0.1:8080/xudanu?format=json
//   Admin passphrase: XUDANU_ADMIN_PASSPHRASE env var (never CLI).
//
// Idempotent: works are keyed by exact title; re-running skips
// existing works and reuses their ids (links are NOT re-created for
// skipped rooms — wipe the gallery works for a clean re-seed).

import WebSocket from "ws";

const url = process.argv[2] ?? "ws://127.0.0.1:8080/xudanu?format=json";
const ws = new WebSocket(url, { headers: { origin: "http://localhost:5173" } });

let nextId = 1;
const pending = new Map();
function request(op, payload) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    const t = setTimeout(() => { pending.delete(id); reject(new Error(`timeout: ${op}`)); }, 60000);
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
      frame.type === "error"
        ? p.reject(new Error(`${p.op}: ${frame.message}`))
        : p.resolve(frame.value);
    }
  }
});
const valueOf = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);

// ---- helpers ------------------------------------------------------
// registry: title -> { id, text, isNew } — seeded text is
// authoritative for span computation; ids survive re-runs.
// Wiring (links, elements) is created ONLY for newly created works,
// so re-runs never duplicate links.
const reg = new Map();
async function galleryWork(title, text) {
  const res = valueOf(await request("work_list", {}));
  // work_list returns { entries: [...] } (also tolerate a bare array)
  const entries = res?.entries ?? (Array.isArray(res) ? res : []);
  const found = entries.find((w) => w.title === title);
  if (found) {
    reg.set(title, { id: found.work_id, text, isNew: false });
    console.log(`  [skip] ${title}`);
    return found.work_id;
  }
  const w = valueOf(await request("work_create", { edition: { text } }));
  const wid = typeof w === "number" ? w : w?.work_id;
  await request("work_set_title", { work_id: wid, title });
  await request("work_publish", { work_id: wid });
  reg.set(title, { id: wid, text, isNew: true });
  console.log(`  [ok] ${title} = 0x${wid.toString(16)}`);
  return wid;
}
const isNew = (wid) => {
  for (const v of reg.values()) if (v.id === wid) return v.isNew;
  return false;
};
const span = (text, marker) => {
  const i = text.indexOf(marker);
  if (i < 0) throw new Error(`marker not found: ${marker.slice(0, 48)}`);
  return { start: i, end: i + marker.length };
};
async function typedLink(o, type) {
  const l = valueOf(await request("link_create", o));
  const lid = typeof l === "number" ? l : l?.link_id;
  await request("link_set_types", { link_id: lid, link_types: [type] });
  return lid;
}

// ═══════════════════════════════════════════════════════════════════
async function main() {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await request("session_connect");
  await request("session_login_public");
  const pass = process.env.XUDANU_ADMIN_PASSPHRASE;
  if (pass) {
    const adminId = valueOf(await request("club_id_by_name", { name: "admin" }));
    await request("session_login", { club_id: adminId });
    await request("session_authenticate", {
      credential: { password: Array.from(pass).map((c) => c.charCodeAt(0)) },
    });
    console.log("connected — authenticated as admin");
  } else {
    console.log("connected — public session (set XUDANU_ADMIN_PASSPHRASE if work_create is refused)");
  }
  console.log("building the gallery\n");

  // ── Annex companions (the far ends) ────────────────────────────
  console.log("Annex works:");
  const annexSpectrum = await galleryWork("Gallery Annex — Six Voices",
    `Six Voices\n\nA comment: the spectrum sentence stacks its connections in lanes, one color per kind.\n\nA reference: every color is a different KIND of connection, not a different strength.\n\nA disagreement: six at once is showing off; two well-chosen links say more.\n\nA quotation: 'The color is the type, and the type is the claim.'\n\nA see-also: lanes stack because connections overlap — text carries many relations at once.\n\nA web link: the sixth voice points outward, off the gallery grounds.`);
  const annexJunction = await galleryWork("Gallery Annex — The Convergence",
    `The Convergence\n\nEverything reaches the same place eventually. The junction word gathers roads; some arrive, some depart.`);
  const annexArrival = await galleryWork("Gallery Annex — An Arrival",
    `An Arrival\n\nOne of several roads that end at the junction word. Watch the right margin: incoming connections stack there.`);
  const annexOuter = await galleryWork("Gallery Annex — The Outer Room",
    `The Outer Room\n\nThe whole sentence is the scope of one connection. Big scopes are legal; they hold rooms, not just sentences.`);
  const annexInner = await galleryWork("Gallery Annex — The Inner Alcove",
    `The Inner Alcove\n\nA smaller scope inside the larger one. Nesting is not hierarchy — the inner link knows nothing of the outer; they merely overlap.`);
  const gene1965 = await galleryWork("Gallery Annex — The Original Pronouncement (1965)",
    `The Original Pronouncement\n\nFilms, prose, poems, news, all branching and intertwining — the literature of tomorrow will be a literature of connection, and the connections will be visible, traversable, and permanent.`);
  const gene1974 = await galleryWork("Gallery Annex — The First Echo (1974)",
    `The First Echo\n\nA literature of connection, visible, traversable, and permanent — so the pronouncement ran, and this echo quotes it faithfully, nine years on.`);
  const gene1987 = await galleryWork("Gallery Annex — The Second Echo (1987)",
    `The Second Echo\n\nThe echo of the echo: this passage quotes the First Echo, which quoted the Original. Nothing was copied; each hop is a connection you can walk backward.`);
  const annexRebuttal = await galleryWork("Gallery Annex — The Rebuttal",
    `The Rebuttal\n\nAll three claims rest on four-week windows measured in a seasonal trough. One year-over-year view would dissolve the entire constellation; the pattern is the window, not the world.`);
  const annexSource = await galleryWork("Gallery Annex — The Source",
    `The Source\n\nThe primary material: one measurement, taken carefully, reported honestly.`);
  const annexContext = await galleryWork("Gallery Annex — The Context",
    `The Context\n\nThe measurement was taken during the retiming window — signage replaced, crews rerouted, the corridor briefly a different corridor.`);
  const annexCounter = await galleryWork("Gallery Annex — The Counterpoint",
    `The Counterpoint\n\nA careful reader holds that the five-way junction overstates the case: most connections are binary, and the general form is rare on purpose.`);
  const annexGloss = await galleryWork("Gallery Annex — The Gloss",
    `The Gloss\n\nFive ends, five roles: source, context, counterpoint, gloss, and the room you stand in. The names are chosen by the linker; the roles are whatever the argument needs.`);
  const annexAgainst = await galleryWork("Gallery Annex — The Case Against Tides",
    `The Case Against Tides\n\nTide tables are predictions wearing the costume of memories.\n\nThe schedule survived three administrations because nobody dared own it — that is not permanence, that is neglect.\n\nA ferry that always runs late is not reliable; it is merely predictable.\n\nTo live by the tide is to mistake a rhythm for a promise.`);
  const annexNote1 = await galleryWork("Gallery Annex — The Margin Note",
    `The Margin Note\n\nThis note attaches to the CONNECTION itself, not to any passage: the dispute is about which window is honest, and neither document names its own.`);
  const annexNote2 = await galleryWork("Gallery Annex — The Note on the Note",
    `The Note on the Note\n\nAnd this note attaches to that note's connection — commentary all the way down. At every depth, the thing being discussed remains addressable.`);

  // text accessors for span math
  const T = (wid) => {
    for (const { id, text } of reg.values()) if (id === wid) return text;
    throw new Error(`no text for work ${wid}`);
  };

  // ── Room 1: The Spectrum Sentence ───────────────────────────────
  console.log("\nWing I:");
  const r1Title = "Gallery — Wing I · Room 1: The Spectrum Sentence";
  const r1Text = `Six kinds of connection share this one sentence, and the light that never goes out falls equally on every word of it: a comment that doubts, a reference that grounds, a disagreement that pushes back, a quotation that borrows, a see-also that gestures sideways, and a web link that leaves the gallery altogether.

How to read it: hover any underline — the tooltip names the kind and the far end. The lanes stack because the scopes overlap; the colors differ because the CLAIMS differ.

What to try: put your cursor inside the sentence and watch the bottom bar offer every connection at once.`;
  const r1 = await galleryWork(r1Title, r1Text);
  const scopes = [
    ["the light that never goes out falls equally on every word of it", 1, "the whole spectrum, commented"],
    ["a comment that doubts, a reference that grounds", 2, "comment and reference, cited"],
    ["a disagreement that pushes back", 3, "the disagreement, disputed"],
    ["a quotation that borrows", 4, "the quotation, quoted"],
    ["a see-also that gestures sideways", 5, "the see-also, sidelong"],
    ["leaves the gallery altogether", 6, "the outward web link"],
  ];
  for (const [m, t, ex] of scopes) {
    if (!isNew(r1)) break;
    const p = span(r1Text, m);
    await typedLink({
      origin: r1, destination: annexSpectrum,
      origin_ref: { kind: "single", work_context: r1, excerpt: ex, start_position: p.start, end_position: p.end },
    }, t);
  }
  console.log("  [ok] spectrum: 6 typed links on one sentence");

  // ── Room 2: The Junction Word ───────────────────────────────────
  const r2Title = "Gallery — Wing I · Room 2: The Junction Word";
  const r2Text = `One word can be a station. The word everywhere below is the meeting point of five departing connections — five colors, five destinations, one span of text — and two other documents arrive at it too, stacking the right-hand margin.

Everything connects everywhere, or so the station claims.

How to read it: the underlines stack in lanes under the single word; the margin bars on the left count the departures, and on the right the arrivals.

What to try: hover the word and step through each connection in the tooltip.`;
  const r2 = await galleryWork(r2Title, r2Text);
  const junction = span(r2Text, "everywhere");
  if (isNew(r2)) {
    for (const [t, ex] of [[1, "the junction, commented"], [2, "the junction, referenced"], [3, "the junction, disputed"], [4, "the junction, quoted"], [5, "the junction, seen also"]]) {
      await typedLink({
        origin: r2, destination: annexJunction,
        origin_ref: { kind: "single", work_context: r2, excerpt: ex, start_position: junction.start, end_position: junction.end },
      }, t);
    }
    // two arrivals: other documents link INTO the same word
    const a1 = span(T(annexArrival), "roads that end at the junction word");
    await typedLink({
      origin: annexArrival, destination: r2,
      origin_ref: { kind: "single", work_context: annexArrival, excerpt: "an arrival from the annex", start_position: a1.start, end_position: a1.end },
      destination_ref: { kind: "single", work_context: r2, excerpt: "the junction word itself", start_position: junction.start, end_position: junction.end },
    }, 2);
    const a2 = span(T(annexJunction), "The junction word gathers roads");
    await typedLink({
      origin: annexJunction, destination: r2,
      origin_ref: { kind: "single", work_context: annexJunction, excerpt: "the convergence arrives", start_position: a2.start, end_position: a2.end },
      destination_ref: { kind: "single", work_context: r2, excerpt: "the junction word, again", start_position: junction.start, end_position: junction.end },
    }, 5);
  }
  console.log("  [ok] junction: 5 departures + 2 arrivals on one word");

  // ── Room 3: The Nested Scope ────────────────────────────────────
  const r3Title = "Gallery — Wing I · Room 3: The Nested Scope";
  const r3Text = `A connection can hold a whole sentence, and another connection can live inside it, and a third can straddle the border between them, so that nesting and crossing happen in the same breath.

How to read it: the outer ribbon runs the full sentence; the inner ribbon starts partway in; the crossing ribbon begins inside the first and ends inside the second. None of them know about each other — text simply carries them all.

What to try: click each underline and notice they go to three different rooms.`;
  const r3 = await galleryWork(r3Title, r3Text);
  if (isNew(r3)) {
    const whole = span(r3Text, "A connection can hold a whole sentence, and another connection can live inside it, and a third can straddle the border between them, so that nesting and crossing happen in the same breath.");
    await typedLink({
      origin: r3, destination: annexOuter,
      origin_ref: { kind: "single", work_context: r3, excerpt: "the outer scope, whole sentence", start_position: whole.start, end_position: whole.end },
    }, 2);
    const inner = span(r3Text, "another connection can live inside it");
    await typedLink({
      origin: r3, destination: annexInner,
      origin_ref: { kind: "single", work_context: r3, excerpt: "the inner scope, one clause", start_position: inner.start, end_position: inner.end },
    }, 4);
    const cross = span(r3Text, "can live inside it, and a third can straddle");
    await typedLink({
      origin: r3, destination: annexOuter,
      origin_ref: { kind: "single", work_context: r3, excerpt: "the crossing scope, border-straddling", start_position: cross.start, end_position: cross.end },
    }, 5);
  }
  console.log("  [ok] nested scope: outer + inner + crossing");

  // ── Room 4: Genealogy of a Quotation ────────────────────────────
  console.log("\nWing II:");
  const r4Title = "Gallery — Wing II · Room 4: Genealogy of a Quotation";
  const r4Text = `The passage below was not copied from the Original; it is connected to the Second Echo, which is connected to the First Echo, which is connected to the Original Pronouncement of 1965. Walk the underlines backward — each hop is a quotation link, each hop honest about where it came from.

A literature of connection, visible, traversable, and permanent — carried here by three hops of quotation, 1965 to 1974 to 1987 to this room.

How to read it: hover the passage, follow the connection; in the far room, hover again; the chain continues until you reach the Original.

What to try: open Compare on this link — three generations side by side.`;
  const r4 = await galleryWork(r4Title, r4Text);
  const p1965 = span(T(gene1965), "a literature of connection, and the connections will be visible, traversable, and permanent");
  const p1974 = span(T(gene1974), "A literature of connection, visible, traversable, and permanent");
  const p1987 = span(T(gene1987), "quotes the First Echo, which quoted the Original");
  const pRoom4 = span(r4Text, "carried here by three hops of quotation");
  if (isNew(r4)) {
    await typedLink({
      origin: gene1974, destination: gene1965,
      origin_ref: { kind: "single", work_context: gene1974, excerpt: "the first echo quotes the original", start_position: p1974.start, end_position: p1974.end },
      destination_ref: { kind: "single", work_context: gene1965, excerpt: "the original pronouncement", start_position: p1965.start, end_position: p1965.end },
    }, 4);
    await typedLink({
      origin: gene1987, destination: gene1974,
      origin_ref: { kind: "single", work_context: gene1987, excerpt: "the second echo quotes the first", start_position: p1987.start, end_position: p1987.end },
      destination_ref: { kind: "single", work_context: gene1974, excerpt: "the first echo's passage", start_position: p1974.start, end_position: p1974.end },
    }, 4);
    await typedLink({
      origin: r4, destination: gene1987,
      origin_ref: { kind: "single", work_context: r4, excerpt: "the room quotes the second echo", start_position: pRoom4.start, end_position: pRoom4.end },
      destination_ref: { kind: "single", work_context: gene1987, excerpt: "the second echo's passage", start_position: p1987.start, end_position: p1987.end },
    }, 4);
  }
  console.log("  [ok] genealogy: 1965 → 1974 → 1987 → room");

  // ── Room 5: A Link About a Link ─────────────────────────────────
  const r5Title = "Gallery — Wing II · Room 5: A Link About a Link";
  const r5Text = `Below is an ordinary disagreement. But open the Connections panel and press the comment symbol on its row: commentary can attach to the CONNECTION itself. The Margin Note does exactly that — and the Note on the Note attaches to that commentary's connection. Three levels deep, every one addressable.

The four-week window flatters the throughput numbers, and this sentence is what the argument is about.

How to read it: in the panel, rows carrying a small arrow chip are attached-to-a-connection; follow them down.

What to try: hover the arrow-chip rows to see which connection each note discusses.`;
  const r5 = await galleryWork(r5Title, r5Text);
  if (isNew(r5)) {
    const r5pass = span(r5Text, "The four-week window flatters the throughput numbers");
    const dispute = await typedLink({
      origin: r5, destination: annexRebuttal,
      origin_ref: { kind: "single", work_context: r5, excerpt: "the disputed window claim", start_position: r5pass.start, end_position: r5pass.end },
    }, 3);
    const n1 = span(T(annexNote1), "This note attaches to the CONNECTION itself");
    const noteLink = await typedLink({
      origin: annexNote1, destination: r5,
      origin_ref: { kind: "single", work_context: annexNote1, excerpt: "the margin note on the dispute", start_position: n1.start, end_position: n1.end },
    }, 1);
    await request("link_end_add_attachment", {
      link_id: noteLink, end_name: "Connection",
      attachment: { kind: "link_attachment", work_context: r5, link_attachment: dispute, excerpt: null, start_position: null, end_position: null },
    });
    const n2 = span(T(annexNote2), "this note attaches to that note's connection");
    const noteLink2 = await typedLink({
      origin: annexNote2, destination: annexNote1,
      origin_ref: { kind: "single", work_context: annexNote2, excerpt: "the note on the note", start_position: n2.start, end_position: n2.end },
    }, 1);
    await request("link_end_add_attachment", {
      link_id: noteLink2, end_name: "Connection",
      attachment: { kind: "link_attachment", work_context: r5, link_attachment: noteLink, excerpt: null, start_position: null, end_position: null },
    });
  }
  console.log("  [ok] link-about-link: depth 3 (dispute ← note ← note)");

  // ── Room 6: The Rebuttal Constellation ──────────────────────────
  console.log("\nWing III:");
  const r6Title = "Gallery — Wing III · Room 6: The Rebuttal Constellation";
  const r6Text = `Three claims, one rebuttal. The three underlined passages below are not three connections — they are three passages of ONE end, gathered; the chips in the margin read 1 of 3, 2 of 3, 3 of 3. The far end is a single paragraph in the Rebuttal annex that answers all three at once.

First: throughput improved forty percent under the retiming, with no incident rise.

Second: escalations fell to a three-year low under the new triage rota.

Third: maintenance costs per corridor-mile dropped twelve percent.

How to read it: hover any member passage — the chip says which passage of how many; click any member to reach the same far end.

What to try: select another sentence here and Gather it into the set; the chips renumber.`;
  const r6 = await galleryWork(r6Title, r6Text);
  if (isNew(r6)) {
    const m1 = span(r6Text, "throughput improved forty percent under the retiming, with no incident rise");
    const m2 = span(r6Text, "escalations fell to a three-year low under the new triage rota");
    const m3 = span(r6Text, "maintenance costs per corridor-mile dropped twelve percent");
    const reb = span(T(annexRebuttal), "One year-over-year view would dissolve the entire constellation");
    const constellation = await typedLink({
      origin: r6, destination: annexRebuttal,
      origin_ref: { kind: "single", work_context: r6, excerpt: "member one of three", start_position: m1.start, end_position: m1.end },
      destination_ref: { kind: "single", work_context: annexRebuttal, excerpt: "the single rebuttal", start_position: reb.start, end_position: reb.end },
    }, 3);
    await request("link_end_add_attachment", {
      link_id: constellation, end_name: "LeftEnd",
      attachment: { kind: "single", work_context: r6, excerpt: "member two of three", start_position: m2.start, end_position: m2.end },
    });
    await request("link_end_add_attachment", {
      link_id: constellation, end_name: "LeftEnd",
      attachment: { kind: "single", work_context: r6, excerpt: "member three of three", start_position: m3.start, end_position: m3.end },
    });
  }
  console.log("  [ok] constellation: 3 gathered members vs 1 rebuttal");

  // ── Room 7: The Five-Way Junction ───────────────────────────────
  const r7Title = "Gallery — Wing III · Room 7: The Five-Way Junction";
  const r7Text = `One connection, five named ends. The passage below is one end; the others are the Source (what was measured), the Context (what else was happening), the Counterpoint (the objection), and the Gloss (what the shape means). The names were chosen when the link was made — ends are roles, not positions.

The measurement was taken once, carefully, and means something different in each of the four other rooms it touches.

How to read it: the Connections panel lists every end by name; Compare shows all five windows side by side.

What to try: open Compare and read the same fact from five positions.`;
  const r7 = await galleryWork(r7Title, r7Text);
  if (isNew(r7)) {
    const r7p = span(r7Text, "The measurement was taken once, carefully");
    const srcP = span(T(annexSource), "one measurement, taken carefully, reported honestly");
    const ctxP = span(T(annexContext), "the corridor briefly a different corridor");
    const cptP = span(T(annexCounter), "the general form is rare on purpose");
    const gloP = span(T(annexGloss), "the roles are whatever the argument needs");
    const junction5 = await typedLink({
      origin: r7, destination: annexSource,
      origin_ref: { kind: "single", work_context: r7, excerpt: "this room, the fifth end", start_position: r7p.start, end_position: r7p.end },
      destination_ref: { kind: "single", work_context: annexSource, excerpt: "the source end", start_position: srcP.start, end_position: srcP.end },
    }, 5);
    await request("link_add_end", {
      link_id: junction5, end_name: "Context",
      end_ref: { kind: "single", work_context: annexContext, excerpt: "the context end", start_position: ctxP.start, end_position: ctxP.end },
    });
    await request("link_add_end", {
      link_id: junction5, end_name: "Counterpoint",
      end_ref: { kind: "single", work_context: annexCounter, excerpt: "the counterpoint end", start_position: cptP.start, end_position: cptP.end },
    });
    await request("link_add_end", {
      link_id: junction5, end_name: "Gloss",
      end_ref: { kind: "single", work_context: annexGloss, excerpt: "the gloss end", start_position: gloP.start, end_position: gloP.end },
    });
  }
  console.log("  [ok] five-way junction: 5 named ends across 5 works");

  // ── Room 8: The Standing Dispute ────────────────────────────────
  const r8Title = "Gallery — Wing III · Room 8: The Standing Dispute";
  const r8Text = `Two documents, four disagreements, both directions. The underlined passages below dispute the Case Against Tides, and two of its passages dispute this room right back — so the left margin carries departures and the right margin carries arrivals, and Compare sets the whole quarrel side by side.

A rhythm kept for a century is a promise, whatever the pessimists say.

The tide has never once failed to announce itself.

How to read it: red is disagreement; both documents show both margins, because a dispute is bidirectional by nature.

What to try: press Compare on any disagreement row — the shared structure of the quarrel appears at a glance.`;
  const r8 = await galleryWork(r8Title, r8Text);
  if (isNew(r8)) {
    const tA = T(annexAgainst);
    const out1 = span(r8Text, "A rhythm kept for a century is a promise");
    const out2 = span(r8Text, "The tide has never once failed to announce itself");
    const inSelf = span(r8Text, "the left margin carries departures and the right margin carries arrivals");
    const against1 = span(tA, "Tide tables are predictions wearing the costume of memories");
    const against2 = span(tA, "A ferry that always runs late is not reliable; it is merely predictable");
    const in1 = span(tA, "that is not permanence, that is neglect");
    const in2 = span(tA, "To live by the tide is to mistake a rhythm for a promise");
    await typedLink({
      origin: r8, destination: annexAgainst,
      origin_ref: { kind: "single", work_context: r8, excerpt: "rhythm-as-promise, asserted", start_position: out1.start, end_position: out1.end },
      destination_ref: { kind: "single", work_context: annexAgainst, excerpt: "the neglect charge, disputed", start_position: in1.start, end_position: in1.end },
    }, 3);
    await typedLink({
      origin: r8, destination: annexAgainst,
      origin_ref: { kind: "single", work_context: r8, excerpt: "the tide's punctuality, asserted", start_position: out2.start, end_position: out2.end },
      destination_ref: { kind: "single", work_context: annexAgainst, excerpt: "predictable-not-reliable, disputed", start_position: against2.start, end_position: against2.end },
    }, 3);
    await typedLink({
      origin: annexAgainst, destination: r8,
      origin_ref: { kind: "single", work_context: annexAgainst, excerpt: "costume of memories, counterasserted", start_position: against1.start, end_position: against1.end },
      destination_ref: { kind: "single", work_context: r8, excerpt: "the margins sentence, disputed here", start_position: inSelf.start, end_position: inSelf.end },
    }, 3);
    await typedLink({
      origin: annexAgainst, destination: r8,
      origin_ref: { kind: "single", work_context: annexAgainst, excerpt: "rhythm-vs-promise, counterasserted", start_position: in2.start, end_position: in2.end },
      destination_ref: { kind: "single", work_context: r8, excerpt: "the promise sentence, disputed here", start_position: out1.start, end_position: out1.end },
    }, 3);
  }
  console.log("  [ok] standing dispute: 2 out + 2 in, both margins live");

  // ── Room 9: The Live Window ─────────────────────────────────────
  console.log("\nThe Fabric:");
  const r9Title = "Gallery — The Fabric · Room 9: The Live Window";
  const r9Text = `The two barred passages in this room are not quotations and not links — they are windows. Live transclusions: the text you see is the text that lives in the other document, and if its author revises, this window revises with it.

How to read it: the vertical bar marks a window; hover to see where the text actually lives.

What to try: open the Original Pronouncement and edit the passage — return here and the window will have moved with it.`;
  const r9 = await galleryWork(r9Title, r9Text);
  if (isNew(r9)) {
    const win1965 = span(T(gene1965), "a literature of connection, and the connections will be visible, traversable, and permanent");
    const winReb = span(T(annexRebuttal), "the pattern is the window, not the world");
    const pos1 = r9Text.indexOf("not quotations and not links");
    const pos2Tail = "if its author revises, this window revises with it";
    const pos2 = r9Text.indexOf(pos2Tail) + pos2Tail.length;
    await request("element_insert", {
      work_id: r9, position: pos1,
      element: { type: "transclusion", transclusion_source: gene1965, transclusion_start: win1965.start, transclusion_end: win1965.end },
    });
    await request("element_insert", {
      work_id: r9, position: pos2,
      element: { type: "transclusion", transclusion_source: annexRebuttal, transclusion_start: winReb.start, transclusion_end: winReb.end },
    });
    // element_insert clobbers the cached title (server re-derives it
    // from the revised edition — known bug); re-set it after placing.
    await request("work_set_title", { work_id: r9, title: r9Title });
  }
  console.log("  [ok] live window: 2 transclusions placed");

  // ── The Lobby ───────────────────────────────────────────────────
  console.log("\nLobby:");
  const lobbyTitle = "Gallery — Lobby: The Gallery of Unusual Connections";
  const lobbyText = `THE GALLERY OF UNUSUAL CONNECTIONS

Three wings, nine rooms, one tour. Every exhibit is a live structure — nothing here is a picture of a link; everything is the thing itself. The room names below are wired: click one to walk there.

WING I · FORM — the shapes a connection can take.
Room 1: The Spectrum Sentence — six kinds of connection on one sentence.
Room 2: The Junction Word — one word, five departures, two arrivals.
Room 3: The Nested Scope — a link inside a link, and one across the border.

WING II · DEPTH — connection leading to connection.
Room 4: Genealogy of a Quotation — 1965 to 1974 to 1987 to this gallery.
Room 5: A Link About a Link — commentary attached to connections, three deep.

WING III · CONTENTION — many ends, many voices.
Room 6: The Rebuttal Constellation — three passages, one end, one answer.
Room 7: The Five-Way Junction — one connection, five named ends.
Room 8: The Standing Dispute — four disagreements, both directions.

THE FABRIC — beyond links.
Room 9: The Live Window — transclusions: windows, not copies.

The Curator's Tour (in the Trails panel) threads the rooms in order. The annexes hold the far ends; every underline in every room leads somewhere real.`;
  const lobby = await galleryWork(lobbyTitle, lobbyText);
  const roomTargets = [
    ["Room 1: The Spectrum Sentence", r1],
    ["Room 2: The Junction Word", r2],
    ["Room 3: The Nested Scope", r3],
    ["Room 4: Genealogy of a Quotation", r4],
    ["Room 5: A Link About a Link", r5],
    ["Room 6: The Rebuttal Constellation", r6],
    ["Room 7: The Five-Way Junction", r7],
    ["Room 8: The Standing Dispute", r8],
    ["Room 9: The Live Window", r9],
  ];
  if (isNew(lobby)) {
    let wired = 0;
    for (const [label, target] of roomTargets) {
      const p = span(lobbyText, label);
      await typedLink({
        origin: lobby, destination: target,
        origin_ref: { kind: "single", work_context: lobby, excerpt: `${label} (floor plan)`, start_position: p.start, end_position: p.end },
      }, 2);
      wired++;
    }
    console.log(`  [ok] lobby: floor plan wired with ${wired} navigation links`);
  }

  // ── The Curator's Tour ──────────────────────────────────────────
  if (isNew(lobby)) {
    const trailRes = valueOf(await request("trail_create", {
      name: "The Curator's Tour",
      introduction: "Nine rooms of unusual connection, lobby to live window. Every exhibit is the thing itself.",
    }));
    const trailId = typeof trailRes === "number" ? trailRes : trailRes?.trail_id;
    const stops = [
      [lobby, "Begin in the lobby: the floor plan is wired with links"],
      [r1, "Wing I · Form — six kinds at once"],
      [r2, "one word, many connections"],
      [r3, "scopes nest and cross"],
      [r4, "Wing II · Depth — quotation genealogy"],
      [r5, "commentary on connections"],
      [r6, "Wing III · Contention — gathered passages"],
      [r7, "five named ends"],
      [r8, "the standing dispute"],
      [r9, "The Fabric — windows, not copies"],
    ];
    for (const [wid, note] of stops) {
      await request("trail_add_stop", { trail_id: trailId, work_id: wid, note });
    }
    await request("trail_publish", { trail_id: trailId });
    console.log(`  [ok] Curator's Tour published (${stops.length} stops)`);
  }

  console.log("\nGALLERY READY");
  console.log(`lobby=${lobby} rooms=${[r1, r2, r3, r4, r5, r6, r7, r8, r9].join(",")}`);
  ws.close();
  process.exit(0);
}

main().catch((e) => { console.error(e); process.exit(1); });
