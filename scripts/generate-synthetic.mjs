#!/usr/bin/env node
// generate-synthetic.mjs — parameterized docuverse synthesizer.
// Generates works/links/transclusions/revisions with controllable
// structural properties for H(G) calibration.
//
// Usage: node generate-synthetic.mjs [ws-url] [options]
//   --works N              Number of works (default: 30)
//   --density F            Fraction of possible links to create (default: 0.1)
//   --type-mix "t:p,..."   Link type distribution (default: "reference:40,quotation:30,disagreement:20,comment:10")
//   --transclusion-rate F  Fraction of works that are transclusion sources (default: 0.1)
//   --revision-depth N     Mean revisions per work (default: 2)
//   --topology T           random | hub | clustered | chain | mesh (default: random)
//   --author-mix "h,l"     Author distribution percentages (default: "100,0")
//   --region CLUB_ID       Create in a specific region (optional)
//   --seed N               Deterministic seed (default: 42)
//   --json                 Output result as JSON (parameters + summary)
//
// All content is generated original prose — no third-party material.
import WebSocket from "ws";

// ── Deterministic PRNG (mulberry32) ──────────────────────────────────
function mulberry32(seed) {
  let a = seed >>> 0;
  return function () {
    a |= 0; a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// ── Original content pool ────────────────────────────────────────────
const SUBJECTS = [
  "The lighthouse keeper's morning log", "Signal stations along the northern chain",
  "Fuel discipline at winter burn", "The lamp as a contract with the horizon",
  "Cape Verity's two-degree lean", "Gulls as instruments nobody maintains",
  "The relief boat's monthly schedule", "Duplicate logs and handwritten copies",
  "The fog that arrives without ceremony", "Eleven lights in a gentle arc",
  "The arithmetic of the last week", "Birds reading weather before instruments",
  "The keeper's argument about trim", "Letters carried between stations",
  "The tower rebuilt by hand after the storm", "Two cups poured at morning watch",
  "The chart that corrects for the lean", "Sailors taking bearings on imperfection",
  "The garden as a performance that repeats", "Tide tables as predictions wearing memories",
];
const TEMPLATES = [
  (s) => `${s}. The record begins with observation, not conclusion. What follows is a working note, amended in the margins over time, capturing what was seen and what it might mean.`,
  (s) => `${s}. This passage exists in multiple contexts by reference. The original observation carries its provenance forward; every inclusion traces back to this moment of recording.`,
  (s) => `${s}. The practice described here has been refined over many seasons. The principles hold; the techniques adapt. What matters is the relationship between intent and execution.`,
  (s) => `${s}. A counter-reading: the standard interpretation assumes conditions that don't always hold. An alternative framing reveals assumptions that deserve challenge.`,
  (s) => `${s}. The connection to broader principles is direct. This is not an isolated case but an instance of a pattern that recurs wherever structure meets practice.`,
];

function genContent(rand, idx) {
  const s = SUBJECTS[idx % SUBJECTS.length];
  const t = TEMPLATES[Math.floor(rand() * TEMPLATES.length)];
  return t(s);
}

// ── Argument parsing ──────────────────────────────────────────────────
const args = process.argv.slice(2);
const BASE = opt("url", "ws://127.0.0.1:8081/xudanu?format=json");
const ORIGIN = "http://127.0.0.1:8081";

function opt(name, def) {
  const i = args.indexOf(`--${name}`);
  return i >= 0 && args[i + 1] ? args[i + 1] : def;
}

const WORKS = parseInt(opt("works", "30"));
const DENSITY = parseFloat(opt("density", "0.1"));
const TYPE_MIX = opt("type-mix", "reference:40,quotation:30,disagreement:20,comment:10");
const TRANSCLUSION_RATE = parseFloat(opt("transclusion-rate", "0.1"));
const REVISION_DEPTH = parseInt(opt("revision-depth", "2"));
const TOPOLOGY = opt("topology", "random");
const AUTHOR_MIX = opt("author-mix", "100,0");
const REGION = opt("region", null);
const SEED = parseInt(opt("seed", "42"));

const TYPE_MAP = { comment: 1, reference: 2, disagreement: 3, quotation: 4, "see-also": 5, web: 6 };

// ── WS client ─────────────────────────────────────────────────────────
const ws = new WebSocket(BASE, { headers: { origin: ORIGIN } });
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
function value(r) {
  let v = r && typeof r === "object" && "value" in r ? r.value : r;
  while (v && typeof v === "object" && typeof v.type === "string" && "value" in v) v = v.value;
  return v;
}

ws.on("message", (data) => {
  try {
    let s = data.toString();
    const b = s.indexOf("{"); if (b > 0) s = s.slice(b);
    const f = JSON.parse(s);
    if (f.type === "response") {
      const p = pending.get(f.id);
      if (p) { clearTimeout(p.timeout); pending.delete(f.id); p.resolve(f); }
    } else if (f.type === "error") {
      const p = pending.get(f.id);
      if (p) { clearTimeout(p.timeout); pending.delete(f.id); p.reject(new Error(`${p.op}: ${f.message}`)); }
    }
  } catch {}
});

// ── Topology link placement ──────────────────────────────────────────
function generateLinks(rand, workIds) {
  const n = workIds.length;
  const maxLinks = Math.floor((n * (n - 1) / 2) * DENSITY);
  const links = [];
  const used = new Set();

  // Parse type-mix into weighted list
  const typePairs = TYPE_MIX.split(",").map((s) => {
    const [name, pct] = s.trim().split(":");
    return { type: TYPE_MAP[name.trim()] || 2, name: name.trim(), pct: parseInt(pct) || 10 };
  });
  const totalPct = typePairs.reduce((s, t) => s + t.pct, 0);

  function pickType() {
    let r = rand() * totalPct;
    for (const t of typePairs) { r -= t.pct; if (r <= 0) return t.type; }
    return typePairs[0].type;
  }

  function addLink(a, b) {
    const key = `${Math.min(a, b)}-${Math.max(a, b)}`;
    if (used.has(key) || a === b) return;
    used.add(key);
    links.push({ from: a, to: b, type: pickType() });
  }

  switch (TOPOLOGY) {
    case "chain":
      for (let i = 0; i < n - 1 && links.length < maxLinks; i++) addLink(workIds[i], workIds[i + 1]);
      break;
    case "mesh":
      for (let i = 0; i < n; i++) {
        for (let d = 1; d <= 3 && links.length < maxLinks; d++) {
          const j = (i + d) % n;
          addLink(workIds[i], workIds[j]);
        }
      }
      break;
    case "hub": {
      // Preferential attachment: early works accumulate links
      while (links.length < maxLinks) {
        const a = workIds[Math.floor(rand() * n)];
        // Weight toward low-index (hub) works
        const bias = Math.pow(rand(), 2.5);
        const b = workIds[Math.floor(bias * n)];
        addLink(a, b);
      }
      break;
    }
    case "clustered": {
      const k = Math.min(5, Math.max(3, Math.floor(n / 8)));
      const clusters = Array.from({ length: k }, () => []);
      workIds.forEach((w, i) => clusters[i % k].push(w));
      const IN_CLUSTER = 0.85; // 85% of links within clusters
      let attempts = 0;
      while (links.length < maxLinks && attempts < maxLinks * 10) {
        attempts++;
        if (rand() < IN_CLUSTER) {
          const c = clusters[Math.floor(rand() * k)];
          if (c.length < 2) continue;
          addLink(c[Math.floor(rand() * c.length)], c[Math.floor(rand() * c.length)]);
        } else {
          addLink(workIds[Math.floor(rand() * n)], workIds[Math.floor(rand() * n)]);
        }
      }
      break;
    }
    default: // random
      let attempts = 0;
      while (links.length < maxLinks && attempts < maxLinks * 10) {
        attempts++;
        addLink(workIds[Math.floor(rand() * n)], workIds[Math.floor(rand() * n)]);
      }
  }
  return links;
}

// ── Main ─────────────────────────────────────────────────────────────
(async () => {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await request("session_connect");
  await request("session_login_public");

  const rand = mulberry32(SEED);
  const params = {
    works: WORKS, density: DENSITY, type_mix: TYPE_MIX, topology: TOPOLOGY,
    transclusion_rate: TRANSCLUSION_RATE, revision_depth: REVISION_DEPTH,
    author_mix: AUTHOR_MIX, seed: SEED, region: REGION,
  };
  console.error(`Synthesizing: ${JSON.stringify(params)}`);

  // Parse author-mix and create sessions
  const [humanPct, llmPct] = AUTHOR_MIX.split(",").map((s) => parseInt(s.trim()) || 0);
  const humanCount = Math.round(WORKS * humanPct / 100);
  const llmCount = WORKS - humanCount;

  // Create sessions
  const sidH = nextId; // human session (already connected)
  await request("session_connect"); // just to advance; we use the main session

  let sidL = null;
  if (llmCount > 0) {
    // New session for LLM work
    const sidL2 = await request("session_connect");
    await request("session_login_public");
    sidL = value(sidL2) || null;
    if (sidL) {
      await request("session_set_author_type", { author_type: "llm", llm_model: "synthetic-llm" });
    }
  }

  // Set region if specified
  if (REGION) {
    await request("session_set_region", { club_id: parseInt(REGION) }).catch(() => {
      console.error(`Warning: could not set region ${REGION}`);
    });
  }

  // Create works
  const workIds = [];
  for (let i = 0; i < WORKS; i++) {
    const isLlm = i >= humanCount;
    const text = genContent(rand, i);
    const r = await request("work_create", { edition: { text } });
    const wid = value(r);
    workIds.push(wid);
  }
  console.error(`Created ${workIds.length} works (${humanCount} human, ${llmCount} llm)`);

  // Generate and create links
  const links = generateLinks(rand, workIds);
  for (const link of links) {
    const excerptA = genContent(rand, link.from).slice(0, 80);
    const excerptB = genContent(rand, link.to).slice(0, 80);
    await request("link_create", {
      origin: link.from,
      destination: link.to,
      origin_ref: { kind: "single", work_context: link.from, excerpt: excerptA, start_position: 0, end_position: 40 },
      destination_ref: { kind: "single", work_context: link.to, excerpt: excerptB, start_position: 0, end_position: 40 },
      types: [link.type],
    }).catch(() => {}); // best-effort
  }
  console.error(`Created ${links.length} links (${TOPOLOGY})`);

  // Create transclusions
  const transclusionCount = Math.max(1, Math.round(WORKS * TRANSCLUSION_RATE));
  for (let i = 0; i < transclusionCount && i < workIds.length - 1; i++) {
    const srcIdx = Math.floor(rand() * workIds.length);
    const dstIdx = (srcIdx + 1 + Math.floor(rand() * (workIds.length - 1))) % workIds.length;
    if (srcIdx === dstIdx) continue;
    await request("element_insert", {
      work_id: workIds[dstIdx],
      position: Math.floor(rand() * 50),
      element: {
        type: "transclusion",
        transclusion_source: workIds[srcIdx],
        transclusion_start: 0,
        transclusion_end: 30,
      },
    }).catch(() => {});
  }
  console.error(`Created ~${transclusionCount} transclusions`);

  // Revisions
  for (let i = 0; i < workIds.length; i++) {
    const revs = Math.max(0, REVISION_DEPTH - 1 + (rand() > 0.5 ? 1 : 0));
    for (let r = 0; r < revs; r++) {
      const text = genContent(rand, i + WORKS * (r + 1)); // different content each revision
      await request("work_grab", { work_id: workIds[i] }).catch(() => {});
      await request("work_revise", { work_id: workIds[i], edition: { text } }).catch(() => {});
    }
  }
  console.error(`Applied ~${REVISION_DEPTH} revisions per work`);

  // Output
  const result = {
    parameters: params,
    summary: {
      works: workIds.length,
      links: links.length,
      transclusions: transclusionCount,
      author_mix: { human: humanCount, llm: llmCount },
    },
    work_ids: workIds,
  };
  console.log(JSON.stringify(result, null, 2));
  ws.close();
  process.exit(0);
})().catch((e) => { console.error(e.message); process.exit(1); });
