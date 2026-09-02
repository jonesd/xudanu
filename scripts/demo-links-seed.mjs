#!/usr/bin/env node
// demo-links-seed.mjs — seed a live Xudanu server with a corpus that
// exercises the FR-40 link features: gathered end-sets (multi-passage
// disagreement), three-ended comparison links, comment-on-link (a link
// about a link), and descriptor ends.
//
// Usage: node demo-links-seed.mjs [ws-url]   (default 127.0.0.1:8081)
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
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const report = `Q3 Claims Report

Claim one. The western corridor throughput improved by forty percent following the signal retiming, and no incident metrics rose during the period.

Methodology note. We measured consecutive four-week windows and excluded the holiday gap, which we believe overstates the baseline.

Claim two. Customer escalations fell to their lowest level in three years, which we attribute to the new triage rota introduced in June.

Caveat. The escalation window overlaps the marketing pause, so attribution is uncertain.

Claim three. Maintenance costs per corridor-mile dropped twelve percent under the revised vendor contracts.`;

const analysis = `Reviewer Analysis

Rebuttal to claim one. The retiming coincided with the seasonal traffic trough; a year-over-year comparison, not four-week windows, is the honest measure. The incident metric also stopped being collected mid-window.

On claim two. Escalations fell during a period when the intake form was broken — the funnel was narrower, not the sentiment better.`;

const notes = `Field Notes Q3

Site visit, week 31. Corridor signage was replaced during the retiming window — a confounder nobody has mentioned in either document.

Site visit, week 35. The vendor contract handover was smooth; two of three crews kept their routes.`;

async function main() {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await request("session_connect");
  await request("session_login_public");
  console.log("connected + logged in");

  const mk = async (name, text) => {
    const w = value(await request("work_create", { edition: { text } }));
    const id = typeof w === "number" ? w : w?.work_id;
    console.log(`work ${name} = ${id}`);
    return id;
  };
  const reportW = await mk("report", report);
  const analysisW = await mk("analysis", analysis);
  const notesW = await mk("notes", notes);

  const span = (work, text, pad = 0) => {
    const i = reportOr(work) ? report.indexOf(text) : work === analysisW ? analysis.indexOf(text) : notes.indexOf(text);
    if (i < 0) throw new Error(`marker text not found: ${text.slice(0, 30)}`);
    return { start: i + pad, end: i + text.length };
  };
  function reportOr(w) { return w === reportW; }

  // ---- 1. GATHERED DISAGREEMENT (the centerpiece) ----
  // LeftEnd gathers THREE passages from the report; RightEnd is the
  // rebuttal in the analysis.
  const c1 = span(reportW, "The western corridor throughput improved by forty percent");
  const c1b = span(reportW, "no incident metrics rose during the period");
  const c1c = span(reportW, "Maintenance costs per corridor-mile dropped twelve percent");
  const r1 = span(analysisW, "a year-over-year comparison, not four-week windows, is the honest measure");
  const disagreement = value(await request("link_create", {
    origin: reportW,
    destination: analysisW,
    origin_ref: {
      kind: "single", work_context: reportW, excerpt: c1.text ?? "claim one",
      start_position: c1.start, end_position: c1.end,
    },
    destination_ref: {
      kind: "single", work_context: analysisW, excerpt: "the honest measure",
      start_position: r1.start, end_position: r1.end,
    },
  }));
  const dId = typeof disagreement === "number" ? disagreement : disagreement?.link_id;
  await request("link_set_types", { link_id: dId, link_types: [3] });
  await request("link_end_add_attachment", {
    link_id: dId, end_name: "LeftEnd",
    attachment: { kind: "single", work_context: reportW, excerpt: "no incident metrics rose", start_position: c1b.start, end_position: c1b.end },
  });
  await request("link_end_add_attachment", {
    link_id: dId, end_name: "LeftEnd",
    attachment: { kind: "single", work_context: reportW, excerpt: "costs dropped twelve percent", start_position: c1c.start, end_position: c1c.end },
  });
  console.log(`gathered disagreement link = ${dId} (3 passages on the report)`);

  // ---- 2. THREE-ENDED SEE-ALSO (comparison) ----
  const c2 = span(reportW, "Customer escalations fell to their lowest level in three years");
  const seeAlso = value(await request("link_create", {
    origin: reportW, destination: analysisW,
    origin_ref: { kind: "single", work_context: reportW, excerpt: "escalations lowest in three years", start_position: c2.start, end_position: c2.end },
  }));
  const sId = typeof seeAlso === "number" ? seeAlso : seeAlso?.link_id;
  await request("link_set_types", { link_id: sId, link_types: [5] });
  const n1 = span(notesW, "Corridor signage was replaced during the retiming window");
  await request("link_add_end", {
    link_id: sId, end_name: "Context",
    end_ref: { kind: "single", work_context: notesW, excerpt: "signage confounder", start_position: n1.start, end_position: n1.end },
  });
  console.log(`three-ended see-also link = ${sId} (report + analysis + field notes)`);

  // ---- 3. COMMENT-ON-LINK (a link about the disagreement) ----
  const commentW = await mk("comment", `Marginal note

This disagreement turns on measurement windows, not on the data itself. If the four-week and year-over-year views were published side by side, the dispute would likely dissolve.`);
  const cpos = `This disagreement turns on measurement windows`.length;
  const comment = value(await request("link_create", {
    origin: commentW, destination: reportW,
    origin_ref: { kind: "single", work_context: commentW, excerpt: "turns on measurement windows", start_position: 14, end: undefined, end_position: 14 + cpos.length },
  }));
  const mId = typeof comment === "number" ? comment : comment?.link_id;
  await request("link_set_types", { link_id: mId, link_types: [1] });
  await request("link_end_add_attachment", {
    link_id: mId, end_name: "Connection",
    attachment: { kind: "link_attachment", work_context: reportW, link_attachment: dId, excerpt: null, start_position: null, end_position: null },
  });
  console.log(`comment-on-link = ${mId} (attaches to disagreement ${dId})`);

  // ---- 4. QUOTATION WITH DESCRIPTOR END ----
  const q = span(reportW, "The escalation window overlaps the marketing pause, so attribution is uncertain.");
  const quotation = value(await request("link_create", {
    origin: reportW, destination: analysisW,
    origin_ref: { kind: "single", work_context: reportW, excerpt: "attribution is uncertain", start_position: q.start, end_position: q.end },
  }));
  const qId = typeof quotation === "number" ? quotation : quotation?.link_id;
  await request("link_set_types", { link_id: qId, link_types: [4] });
  const descW = await mk("descriptor", `The report's own caveat, quoted against the reviewer's funnel objection — the honest pairing.`);
  await request("link_add_end", {
    link_id: qId, end_name: "Descriptor",
    end_ref: { kind: "single", work_context: descW, excerpt: "the honest pairing" },
  });
  console.log(`quotation with descriptor = ${qId}`);

  console.log("\nSEED COMPLETE");
  console.log(`report=${reportW} analysis=${analysisW} notes=${notesW} comment=${commentW} descriptor=${descW}`);
  ws.close();
  process.exit(0);
}

main().catch((e) => { console.error(e); process.exit(1); });
