#!/usr/bin/env node
// examples/llm-context-experiment.mjs
//
// Tests different context strategies for FR-86 LLM connection
// proposals. Runs each strategy against the same contested work,
// captures proposals, and prints them side-by-side for comparison.
//
// Strategies tested:
//   A: bare          — just the contested work's text
//   B: connected     — + directly connected works' texts
//   C: rich          — + existing link summaries + library titles
//   D: guided        — rich + explicit "explore these specific passages" hints
//
// Usage:
//   OLLAMA_URL=http://localhost:11434 OLLAMA_MODEL=qwen2.5:1.5b \
//   node examples/llm-context-experiment.mjs [work-id-hex]
//
import WebSocket from "../web/app/node_modules/ws/index.js";

const OLLAMA_URL = process.env.OLLAMA_URL ?? "http://localhost:11434";
const OLLAMA_MODEL = process.env.OLLAMA_MODEL ?? "qwen2.5:1.5b";
const WORK_ID = parseInt(process.argv[2] ?? "0", 16) || null;

const WS_URL_BASE = "ws://127.0.0.1:8080/xudanu?format=json";
let WS_URL = WS_URL_BASE;
try {
  const r = await fetch("http://127.0.0.1:8080/csrf-token");
  const j = await r.json();
  if (j.csrf_token) WS_URL += `&csrf_token=${encodeURIComponent(j.csrf_token)}`;
} catch {}

const ws = new WebSocket(WS_URL, { headers: { origin: "http://localhost:5173" } });
let nextId = 1;
const pending = new Map();
const opened = new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
function request(op, payload) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    const t = setTimeout(() => reject(new Error(`timeout: ${op}`)), 30000);
    pending.set(id, { resolve, reject, timeout: t });
    ws.send(JSON.stringify({ v: 2, type: "request", id, op, payload: payload ?? {} }));
  });
}
ws.on("message", (data) => {
  const f = JSON.parse(data.toString());
  if (f.type === "response" || f.type === "error") {
    const p = pending.get(f.id);
    if (p) { pending.delete(f.id); clearTimeout(p.timeout);
      f.type === "error" ? p.reject(new Error(f.message)) : p.resolve(f.value); }
  }
});
const v = (x) => (x && typeof x === "object" && "value" in x ? x.value : x);

// ── Ollama direct call ─────────────────────────────────────────────
async function ollama(prompt, maxTokens = 500) {
  const resp = await fetch(`${OLLAMA_URL}/api/generate`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ model: OLLAMA_MODEL, prompt, stream: false,
      options: { temperature: 0.3, num_predict: maxTokens } }),
  });
  const j = await resp.json();
  return j.response ?? "";
}

// ── Parse JSON-lines proposals ─────────────────────────────────────
function parseProposals(response, workText) {
  const proposals = [];
  // Strip markdown code fences
  const cleaned = response.replace(/```(?:json)?\n?/g, "").trim();

  // Try parsing as a JSON array first (some models wrap in [...])
  try {
    const arr = JSON.parse(cleaned);
    if (Array.isArray(arr)) {
      for (const p of arr) {
        if (p.excerpt && p.type >= 1 && p.type <= 5 && p.reasoning) {
          let at = workText.indexOf(p.excerpt);
          if (at < 0) at = workText.indexOf(p.excerpt.trim());
          if (at < 0 && p.excerpt.length > 40) at = workText.indexOf(p.excerpt.slice(0, 40).trim());
          if (at >= 0) proposals.push({ ...p, start: at, end: at + p.excerpt.length });
        }
      }
      return proposals;
    }
  } catch {}

  // Fall back to line-by-line parsing
  for (const line of cleaned.split("\n")) {
    const t = line.trim();
    if (!t.startsWith("{")) continue;
    try {
      const p = JSON.parse(t);
      if (p.excerpt && p.type >= 1 && p.type <= 5 && p.reasoning) {
        let at = workText.indexOf(p.excerpt);
        if (at < 0) at = workText.indexOf(p.excerpt.trim());
        if (at < 0 && p.excerpt.length > 40) at = workText.indexOf(p.excerpt.slice(0, 40).trim());
        if (at >= 0) {
          proposals.push({ ...p, start: at, end: at + p.excerpt.length });
        }
      }
    } catch {}
  }
  return proposals;
}

// ── Load data from Xudanu ──────────────────────────────────────────
async function loadContext() {
  await opened;
  await request("session_connect");
  await request("session_login_public");

  // Find the contested work (or use the specified one)
  let workId = WORK_ID;
  if (!workId) {
    const works = v(await request("work_list", { limit: 100 }));
    const contested = (Array.isArray(works) ? works : works?.entries ?? [])
      .find(w => (w.title ?? "").includes("AI Safety — The Contested"));
    if (!contested) throw new Error("Contested work not found — run llm-demo.mjs first");
    workId = contested.work_id;
  }
  console.log(`Contested work: 0x${workId.toString(16)}`);

  // Load the work
  const ed = v(await request("work_get_edition", { work_id: workId }));
  const workText = typeof ed === "string" ? ed : ed?.text ?? "";
  const workTitle = (Array.isArray(v(await request("work_list", { limit: 100 })))
    ? v(await request("work_list", { limit: 100 }))
    : []).find?.(w => w.work_id === workId)?.title ?? `Work 0x${workId.toString(16)}`;

  // Load links + connected works
  const linksRaw = v(await request("link_list_for_work", { work_id: workId }));
  const links = Array.isArray(linksRaw) ? linksRaw : linksRaw?.entries ?? [];

  // Load far-end works
  const farEnds = [];
  const seen = new Set([workId]);
  for (const l of links) {
    for (const wid of [l.origin, l.destination]) {
      if (wid && !seen.has(wid)) {
        seen.add(wid);
        try {
          const fed = v(await request("work_get_edition", { work_id: wid }));
          const ftext = typeof fed === "string" ? fed : fed?.text ?? "";
          const allWorks = v(await request("work_list", { limit: 100 }));
          const ftitle = (Array.isArray(allWorks) ? allWorks : allWorks?.entries ?? [])
            .find(w => w.work_id === wid)?.title ?? `Work 0x${wid.toString(16)}`;
          farEnds.push({ id: wid, title: ftitle, text: ftext });
        } catch {}
      }
    }
  }

  // Library titles
  const allWorks = v(await request("work_list", { limit: 100 }));
  const library = (Array.isArray(allWorks) ? allWorks : allWorks?.entries ?? [])
    .map(w => w.title ?? `Work 0x${w.work_id.toString(16)}`)
    .filter(t => !t.includes("Getting Started") && !t.includes("Demo"));

  // Existing link summaries
  const TYPE_NAMES = { 1: "Comment", 2: "Reference", 3: "Disagreement", 4: "Quotation", 5: "See Also" };
  const linkSummaries = links.map(l => ({
    type_name: TYPE_NAMES[l.link_types?.[0]] ?? "link",
    origin_excerpt: l.origin_ref?.excerpt ?? "",
    dest_excerpt: l.destination_ref?.excerpt ?? "",
  }));

  return { workId, workTitle, workText, farEnds, library, linkSummaries };
}

// ── Context strategies ─────────────────────────────────────────────
const TYPE_DEFS = `  1. Comment — a note about the passage
  2. Reference — points to related content in another work
  3. Disagreement — disputes the passage's claim (MUST cite evidence from a connected work)
  4. Quotation — cites this passage in another context
  5. See Also — suggests related reading`;

const FORMAT_INSTR = `Format each proposal as JSON, one per line:
{"excerpt": "<passage verbatim from the document>", "type": <1-5>, "reasoning": "<cite a specific quote or claim from the target work>", "far_end_title": "<EXACT title of the target work>"}

Example of a GOOD cross-work Disagreement:
{"excerpt": "the funculator must be duralum before first flight", "type": 3, "reasoning": "The Response work argues this conflates two failure modes — the cost analysis in that work directly contradicts this choice", "far_end_title": "AI Safety — The Response"}

Rules:
- Only use passages that appear VERBATIM in the document
- For Disagreements and References: far_end_title MUST be the title of one of the connected works (NOT null, NOT "same document")
- Your reasoning MUST quote or paraphrase a specific claim from the target work
- Quality over quantity: at most 3 proposals
- Respond with ONLY the JSON lines, no code fences, no other text`;

function buildPromptA(ctx) {
  return `You are a critical reader in a hypertext system. Read this document and identify passages that deserve typed connections to OTHER works.

Connection types:
${TYPE_DEFS}

Document: "${ctx.workTitle}"
${ctx.workText}

${FORMAT_INSTR}`;
}

function buildPromptB(ctx) {
  const connected = ctx.farEnds.map((f, i) =>
    `--- Work ${i+1}: "${f.title}" ---\n${f.text.slice(0, 3000)}`).join("\n");
  return `You are a critical reader in a hypertext system. You are reading a document that is connected to other works. Your job is to identify passages in the main document that deserve typed connections to the CONNECTED WORKS listed below.

Connection types:
${TYPE_DEFS}

Document under review: "${ctx.workTitle}"
${ctx.workText}

Connected works (these are the works you should connect TO):
${connected}

IMPORTANT: When you propose a Disagreement or Reference, the far_end_title must be the EXACT title of one of the connected works above. Do NOT propose same-document connections.

${FORMAT_INSTR}`;
}

function buildPromptC(ctx) {
  const connected = ctx.farEnds.map((f, i) =>
    `--- Work ${i+1}: "${f.title}" ---\n${f.text.slice(0, 4000)}`).join("\n");
  const linksBlock = ctx.linkSummaries.length > 0
    ? `\nAlready-connected passages (DO NOT duplicate these):\n${ctx.linkSummaries.map(l =>
        `  [${l.type_name}] "${l.origin_excerpt.slice(0,60)}" ↔ "${l.dest_excerpt.slice(0,60)}"`).join("\n")}\n`
    : "";
  const libBlock = `\nOther works in the library (less relevant but potential See Also targets):\n${ctx.library.slice(0, 15).map(t => `  - "${t}"`).join("\n")}\n`;
  return `You are a critical reader in a hypertext system. You see a document, its connected works, and the library catalog. Identify passages in the main document that deserve typed connections to the connected works.

Connection types:
${TYPE_DEFS}

Document under review: "${ctx.workTitle}"
${ctx.workText}

Connected works:
${connected}
${linksBlock}${libBlock}
IMPORTANT: far_end_title must be a connected work's title. Cite specific evidence in your reasoning.

${FORMAT_INSTR}`;
}

function buildPromptD(ctx) {
  // Guided: rich + strong-claim hints + explicit cross-work instruction
  const hints = [];
  const sentences = ctx.workText.split(/[.!?]\s+/);
  for (const s of sentences) {
    if (/\b(must|should|cannot|is the most|will not|has been shown|poses a unique|fifty dollars|too slow)\b/i.test(s) && s.length > 30) {
      hints.push(s.trim().slice(0, 120));
    }
  }
  return buildPromptC(ctx).replace(
    "at most 3 proposals.",
    `Pay special attention to these strong claims — each is a likely connection point:
${hints.slice(0, 5).map(h => `  ⚑ "${h}"`).join("\n")}

For each strong claim, check if a connected work disputes, supports, or cross-references it. at most 3 proposals.`
  );
}

// ── Run experiments ────────────────────────────────────────────────
const ctx = await loadContext();
console.log(`\nLoaded: "${ctx.workTitle}" (${ctx.workText.length} chars, ${ctx.farEnds.length} connected works, ${ctx.library.length} library titles)`);
console.log(`Model: ${OLLAMA_MODEL} at ${OLLAMA_URL}\n`);

const strategies = [
  { name: "A: bare", build: buildPromptA },
  { name: "B: connected", build: buildPromptB },
  { name: "C: rich", build: buildPromptC },
  { name: "D: guided", build: buildPromptD },
];

for (const strat of strategies) {
  const prompt = strat.build(ctx);
  console.log(`\n${"=".repeat(70)}`);
  console.log(`Strategy ${strat.name} (prompt: ${prompt.length} chars)`);
  console.log("=".repeat(70));

  const t0 = Date.now();
  try {
    const response = await ollama(prompt);
    const elapsed = ((Date.now() - t0) / 1000).toFixed(1);
    const proposals = parseProposals(response, ctx.workText);
    console.log(`  Time: ${elapsed}s | Raw: ${response.length} chars | Parsed: ${proposals.length} proposals`);
    for (const p of proposals) {
      const typeNames = ["", "Comment", "Reference", "Disagreement", "Quotation", "See Also"];
      console.log(`\n  [${typeNames[p.type]}] "${p.excerpt.slice(0, 70)}${p.excerpt.length > 70 ? "…" : ""}"`);
      console.log(`       → ${p.far_end_title ?? "same document"}`);
      console.log(`       ${p.reasoning.slice(0, 120)}`);
    }
    if (proposals.length === 0) {
      console.log(`  (no valid proposals — raw response first 200 chars:)`);
      console.log(`  ${response.slice(0, 200)}`);
    }
  } catch (e) {
    console.log(`  ERROR: ${e.message}`);
  }
}

console.log(`\n${"=".repeat(70)}`);
console.log("Compare the proposals above: which strategy produces the");
console.log("most relevant, evidence-citing, non-duplicate connections?");
console.log(`\nTo try a different model: OLLAMA_MODEL=llama3.1 node examples/llm-context-experiment.mjs`);

ws.close();
process.exit(0);
