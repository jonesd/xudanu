#!/usr/bin/env node
// demo-links-course.mjs — the progressive Links course: five short
// lesson works (simple link -> three ends -> gathering -> comment on a
// connection -> the reading toolkit) plus a sandbox, each carrying a
// LIVE demonstration of its concept and one task for the reader —
// then the whole series is wired as a TRAIL, so the course teaches
// trails while teaching links.
//
// Usage: node demo-links-course.mjs [ws-url]   (default 127.0.0.1:8081)
import WebSocket from "ws";

const url = process.argv[2] ?? "ws://127.0.0.1:8081/xudanu?format=json";
const ws = new WebSocket(url, { headers: { origin: "http://127.0.0.1:8081" } });

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
      if (frame.type === "error") p.reject(new Error(`${p.op}: ${p.message}`));
      else p.resolve(frame.value);
    }
  }
});
const value = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);

const mk = async (text) => {
  const w = value(await request("work_create", { edition: { text } }));
  return typeof w === "number" ? w : w?.work_id;
};
const span = (text, marker, from = 0) => {
  const i = text.indexOf(marker, from);
  if (i < 0) throw new Error(`marker not found: ${marker.slice(0, 24)}`);
  return { start: i, end: i + marker.length };
};
const linkCreate = async (o) => {
  const l = value(await request("link_create", o));
  return typeof l === "number" ? l : l?.link_id;
};

async function main() {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await request("session_connect");
  await request("session_login_public");

  // ---------------- Companion works (link targets) ----------------
  const companionText = `Lesson Companion

A garden is not a photograph; it is a performance that repeats daily.

The greenhouse kept the same plants for six years, and regulars began greeting them like staff.

Anyone who says a map is the territory has never maintained either.`;
  const companionBText = `Second Companion

Tide tables are predictions wearing the costume of memories.

The ferry schedule survived three administrations because nobody dared own it.`;
  const companion = await mk(companionText);
  const companionB = await mk(companionBText);

  // ---------------- Lesson 1: the simple link ----------------
  const l1Task = "Select this sentence and click the Link button, choose any type, and pick Lesson Companion as the target.";
  const l1Text = `Links Lesson 1 — The Simple Link

A link is a typed connection between two passages. This sentence is a live one: its underline connects to a line in the Lesson Companion. Single-click the underline to jump there; hover it to see what kind of connection it is.

Your task: ${l1Task}

When your own underline appears, you have made a link. That is the whole primitive — everything fancier is more of these, arranged with intent.`;
  const l1 = await mk(l1Text);
  const l1Demo = span(l1Text, "its underline connects to a line in the Lesson Companion");
  const l1DemoLink = await linkCreate({
    origin: l1, destination: companion,
    origin_ref: { kind: "single", work_context: l1, excerpt: "a live one", start_position: l1Demo.start, end_position: l1Demo.end },
    destination_ref: { kind: "single", work_context: companion, excerpt: "a garden is not a photograph", start_position: span(companionText, "A garden is not a photograph").start, end_position: span(companionText, "like staff.").end },
  });
  await request("link_set_types", { link_id: l1DemoLink, link_types: [2] });
  console.log(`lesson1 = ${l1} (demo link ${l1DemoLink})`);

  // ---------------- Lesson 2: three ends ----------------
  const l2Task = "Select this sentence, click Link, and on the final step use Additional ends to add a second target — you will have made a three-ended connection.";
  const l2Text = `Links Lesson 2 — Three Ends on One Connection

The link you made had two ends. A link can have any number: this sentence is one end of a THREE-ended connection whose other ends live in both companions. One connection, three places.

Your task: ${l2Task}

Three ends is not a chain and not a list — it is one claim involving several places at once, like a comparison.`;
  const l2 = await mk(l2Text);
  const l2Demo = span(l2Text, "this sentence is one end of a THREE-ended connection");
  const l2Link = await linkCreate({
    origin: l2, destination: companion,
    origin_ref: { kind: "single", work_context: l2, excerpt: "one end of a THREE-ended connection", start_position: l2Demo.start, end_position: l2Demo.end },
    destination_ref: { kind: "single", work_context: companion, excerpt: "greeting them like staff", start_position: span(companionText, "regulars began greeting").start, end_position: span(companionText, "greeting them like staff").end },
  });
  await request("link_set_types", { link_id: l2Link, link_types: [5] });
  await request("link_add_end", {
    link_id: l2Link, end_name: "Context",
    end_ref: { kind: "single", work_context: companionB, excerpt: "predictions wearing the costume of memories", start_position: span(companionBText, "Tide tables").start, end_position: span(companionBText, "costume of memories.").end },
  });
  console.log(`lesson2 = ${l2} (three-ended ${l2Link})`);

  // ---------------- Lesson 3: gathering passages ----------------
  const l3Task1 = "Select this sentence and click the green Gather button, then choose Your First End.";
  const l3Task2 = "Now select this sentence as well and Gather it into the same end.";
  const l3Text = `Links Lesson 3 — Gathering Passages into One End

The step change: one END can itself hold several passages. The three underlined sentences below are not three links — they are THREE PASSAGES OF ONE END. The green chips by the margin read, for example, 2 of 3: passage two of three, nothing more sequential than that. A gathered end is a set, like three quotes supporting one argument.

One performance that repeats daily, and the schedule nobody dared own.

Hover any of the three: gathered passage 1 of 3.

Your task, twice: ${l3Task1} ${l3Task2}

Watch the chips appear the moment your second passage lands: your two sentences and this marked one become a set of three.`;
  const l3 = await mk(l3Text);
  const l3m1 = span(l3Text, "One performance that repeats daily, and the schedule nobody dared own.");
  const l3m2 = span(l3Text, "Hover any of the three: gathered passage 1 of 3.");
  const l3m3 = span(l3Text, "A gathered end is a set, like three quotes supporting one argument.");
  const l3Link = await linkCreate({
    origin: l3, destination: companion,
    origin_ref: { kind: "single", work_context: l3, excerpt: "one performance", start_position: l3m1.start, end_position: l3m1.end },
  });
  await request("link_set_types", { link_id: l3Link, link_types: [3] });
  await request("link_end_add_attachment", {
    link_id: l3Link, end_name: "LeftEnd",
    attachment: { kind: "single", work_context: l3, excerpt: "the hover sentence", start_position: l3m2.start, end_position: l3m2.end },
  });
  await request("link_end_add_attachment", {
    link_id: l3Link, end_name: "LeftEnd",
    attachment: { kind: "single", work_context: l3, excerpt: "the definition sentence", start_position: l3m3.start, end_position: l3m3.end },
  });
  // The gather target for the reader's task.
  const l3Target = await linkCreate({
    origin: l3, destination: companionB,
    origin_ref: { kind: "single", work_context: l3, excerpt: "first passage of Your First End", start_position: l3m3.start, end_position: l3m3.end },
  });
  await request("link_set_types", { link_id: l3Target, link_types: [4] });
  await request("link_end_add_attachment", {
    link_id: l3Target, end_name: "Your First End",
    attachment: { kind: "single", work_context: l3, excerpt: "seed passage", start_position: l3m2.start, end_position: l3m2.end },
  });
  console.log(`lesson3 = ${l3} (gathered demo ${l3Link}, target ${l3Target})`);

  // ---------------- Lesson 4: comment on a connection ----------------
  const l4Text = `Links Lesson 4 — Commenting on a Connection

Passages can be commented on; so can connections. Open the Links panel on the right and find the row for this lesson's demonstration link — the row lists its type (See Also) and its ends. Press the green comment symbol on that row and write a sentence about the CONNECTION itself.

Your remark becomes a link whose end attaches to the link — a link about a link. It will show in the Links panel as a row carrying a small arrow chip meaning attached-to-a-connection.

Nobody expects you to remember the machinery; remember only that anything on the page — passage or connection — can be argued with, and the argument is itself addressable.`;
  const l4 = await mk(l4Text);
  const l4Demo = span(l4Text, "this lesson's demonstration link");
  const l4Link = await linkCreate({
    origin: l4, destination: companion,
    origin_ref: { kind: "single", work_context: l4, excerpt: "the demonstration link", start_position: l4Demo.start, end_position: l4Demo.end },
  });
  await request("link_set_types", { link_id: l4Link, link_types: [5] });
  console.log(`lesson4 = ${l4} (comment target ${l4Link})`);

  // ---------------- Lesson 5: the reading toolkit ----------------
  const l5Text = `Links Lesson 5 — Reading the Connected Document

You now make links; here is how to read one. On this very page: single-click an underline to jump to its far end; hover for the type and, on gathered ends, which passage of how many; put your cursor inside an underlined passage and the bottom bar offers numbered jumps to its siblings; scroll and the green margin chips keep your place (2 of 3 and so on).

In the Links panel, the two-arrows button on any multi-ended row opens COMPARE: every end side by side, shared passages highlighted — the nearest thing to transpointing windows the web affords.

Your task: press compare on this page's demonstration row, and spend one minute reading both documents at once.`;
  const l5 = await mk(l5Text);
  const l5Demo = span(l5Text, "single-click an underline to jump to its far end");
  const l5Link = await linkCreate({
    origin: l5, destination: companion,
    origin_ref: { kind: "single", work_context: l5, excerpt: "jump to its far end", start_position: l5Demo.start, end_position: l5Demo.end },
    destination_ref: { kind: "single", work_context: companion, excerpt: "the map is the territory", start_position: span(companionText, "Anyone who says").start, end_position: span(companionText, "maintained either.").end },
  });
  await request("link_set_types", { link_id: l5Link, link_types: [2] });
  await request("link_end_add_attachment", {
    link_id: l5Link, end_name: "Context",
    attachment: { kind: "single", work_context: companionB, excerpt: "the ferry schedule", start_position: span(companionBText, "The ferry schedule").start, end_position: span(companionBText, "dared own it.").end },
  });
  console.log(`lesson5 = ${l5} (compare row ${l5Link})`);

  // ---------------- Sandbox ----------------
  const sandbox = await mk(`Links Sandbox — Make Your Own

No tasks here, only recipes in order of ambition.

One. Select a sentence, press Link, pick a type. The fast path.

Two. Same, but use Additional ends for a three-way comparison.

Three. Link once, then select other sentences and press Gather to grow that end into a set. Aim for 4 of 4.

Four. In the Links panel, comment on one of your connections.

Five. Compare everything you made. Then delete something and watch what survives.

When the shapes feel natural, you have the whole vocabulary: link, gather, describe, comment, compare.`);
  console.log(`sandbox = ${sandbox}`);

  // ---------------- The trail ----------------
  const trail = value(await request("trail_create", {
    name: "The Links Course",
    introduction: "Five short lessons from the simple link to gathered end-sets, then a sandbox. Each lesson carries a live demonstration and one task.",
  }));
  const trailId = typeof trail === "number" ? trail : trail?.trail_id;
  for (const [i, w] of [l1, l2, l3, l4, l5, sandbox].entries()) {
    await request("trail_add_stop", { trail_id: trailId, work_id: w, note: ["The simple link", "Three ends", "Gathering passages", "Comment on a connection", "The reading toolkit", "Sandbox"][i] });
  }
  // Publish: the Trails panel merges own + PUBLISHED trails; an
  // unpublished trail is private to its creator's club, so a fresh
  // reader would see "No trails yet" forever.
  await request("trail_publish", { trail_id: trailId });
  console.log(`trail = ${trailId} (published)`);

  console.log("\nCOURSE READY");
  console.log(`lessons=${l1},${l2},${l3},${l4},${l5} sandbox=${sandbox} companions=${companion},${companionB} trail=${trailId}`);
  ws.close();
  process.exit(0);
}

main().catch((e) => { console.error(e); process.exit(1); });
