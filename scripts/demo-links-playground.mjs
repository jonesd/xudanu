#!/usr/bin/env node
// demo-links-playground.mjs — seed an INTERACTIVE tutorial work: the
// document's own text walks the reader through performing each FR-40
// link action on the real editor, and carries demonstration links so
// every concept is visible while reading.
//
// Usage: node demo-links-playground.mjs [ws-url]   (default 127.0.0.1:8081)
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
      if (frame.type === "error") p.reject(new Error(`${p.op}: ${frame.message}`));
      else p.resolve(frame.value);
    }
  }
});
const value = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);

// The marker sentences the tutorial asks the reader to act on. Each is
// unique in the text so offsets resolve by search.
const MARK = {
  gather1: "Select this exact sentence with your mouse, then click the green Gather button in the toolbar above, and choose Playground End.",
  gather2: "Now select this sentence too and Gather it into the same Playground End, and watch the passage count on the badge go up.",
  link1: "Select this sentence and click Link to make a new typed connection from it.",
  disagree: "This sentence already belongs to a three-passage gathered disagreement with another document.",
  quoted: "This sentence is quoted, and its connection carries a human-written descriptor.",
};

const text = `Links Playground — try it yourself

Everything below happens in this document. No setup, nothing to install; the buttons live in the toolbar that appears when you select text.

Part one — one connection, many passages

A gathered end is ONE end of ONE link that collects several passages. While you read this, ${MARK.disagree}

Do it yourself: ${MARK.gather1}

Then: ${MARK.gather2}

Now put your text cursor anywhere inside either sentence you just gathered. The bottom bar shows which gathered end you are in and offers numbered jump buttons to each passage. Hover either underline: the tooltip says passage 1 of 2 (or more). The small green chips beside the left margin are the same information while you scroll.

Part two — ordinary links, the fast path

${MARK.link1} Choose any type you like in the wizard; the two-ended fast path is deliberately the shortest route, and extra ends are always optional steps.

Part three — a quotation with a descriptor

${MARK.quoted} Open the Links panel on the right: the quotation row carries its description from a Descriptor end — a small document attached to the link itself, so the label travels with the connection.

Part four — comment on a connection

Connections can be commented on like passages can. In the Links panel, press the green comment symbol on any link row and write a remark: your remark becomes a link about the link.

Part five — compare every end

Any multi-ended link row has a compare button. Press it: every end opens side by side with shared passages highlighted. This is the closest thing to transpointing windows the web affords today.

That is the whole vocabulary: link, gather, describe, comment, compare.`;

async function main() {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await request("session_connect");
  await request("session_login_public");

  const w = value(await request("work_create", { edition: { text } }));
  const work = typeof w === "number" ? w : w?.work_id;
  console.log(`playground work = ${work}`);

  // Partner works the demo links point at.
  const mk = async (t) => {
    const x = value(await request("work_create", { edition: { text: t } }));
    return typeof x === "number" ? x : x?.work_id;
  };
  const other = await mk(`Contrarian Margin Notes

Three methods were changed mid-measurement, so the four-week windows compare different instruments. The honest form publishes both baselines side by side and lets the reader see the join.`);
  const desc = await mk(`Descriptor: the playground quotation

Written as a demonstration of the descriptor end: a small work attached to the link, carrying its human-readable label.`);

  const span = (marker) => {
    const i = text.indexOf(marker);
    if (i < 0) throw new Error(`marker not found: ${marker.slice(0, 24)}`);
    return { start: i, end: i + marker.length };
  };

  // Demo 1: the three-passage gathered disagreement ON the playground.
  const d = span(MARK.disagree);
  const o1 = text.indexOf("Everything below happens");
  const o2 = text.indexOf("A gathered end is ONE end");
  const link = value(await request("link_create", {
    origin: work, destination: other,
    origin_ref: { kind: "single", work_context: work, excerpt: "gathered disagreement sentence", start_position: d.start, end_position: d.end },
    destination_ref: { kind: "single", work_context: other, excerpt: "different instruments", start_position: 63, end_position: 63 + "Three methods were changed mid-measurement".length },
  }));
  const lid = typeof link === "number" ? link : link?.link_id;
  await request("link_set_types", { link_id: lid, link_types: [3] });
  await request("link_end_add_attachment", {
    link_id: lid, end_name: "LeftEnd",
    attachment: { kind: "single", work_context: work, excerpt: "the intro sentence", start_position: o1, end_position: o1 + "Everything below happens in this document.".length },
  });
  await request("link_end_add_attachment", {
    link_id: lid, end_name: "LeftEnd",
    attachment: { kind: "single", work_context: work, excerpt: "the definition sentence", start_position: o2, end_position: o2 + "A gathered end is ONE end of ONE link that collects several passages.".length },
  });
  console.log(`gathered disagreement = ${lid} (3 passages here)`);

  // Demo 2: the quoted sentence with a descriptor end.
  const q = span(MARK.quoted);
  const ql = value(await request("link_create", {
    origin: work, destination: other,
    origin_ref: { kind: "single", work_context: work, excerpt: "human-written descriptor", start_position: q.start, end_position: q.end },
  }));
  const qid = typeof ql === "number" ? ql : ql?.link_id;
  await request("link_set_types", { link_id: qid, link_types: [4] });
  await request("link_add_end", {
    link_id: qid, end_name: "Descriptor",
    end_ref: { kind: "single", work_context: desc, excerpt: "demonstration of the descriptor end" },
  });
  console.log(`quotation with descriptor = ${qid}`);

  // One end ready for the reader to GATHER into: a See-Also seeded on
  // the link1 sentence so the Gather picker is never empty.
  const l1 = span(MARK.link1);
  const sl = value(await request("link_create", {
    origin: work, destination: other,
    origin_ref: { kind: "single", work_context: work, excerpt: "the Link-button sentence", start_position: l1.start, end_position: l1.end },
  }));
  const sid = typeof sl === "number" ? sl : sl?.link_id;
  await request("link_set_types", { link_id: sid, link_types: [5] });
  await request("link_end_add_attachment", {
    link_id: sid, end_name: "Playground End",
    attachment: { kind: "single", work_context: work, excerpt: "first passage of the playground end", start_position: o2, end_position: o2 + "A gathered end is ONE end of ONE link".length },
  });
  console.log(`see-also with Playground End = ${sid} (gather target ready)`);

  console.log("\nPLAYGROUND READY");
  ws.close();
  process.exit(0);
}

main().catch((e) => { console.error(e); process.exit(1); });
