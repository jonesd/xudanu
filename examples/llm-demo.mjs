#!/usr/bin/env node
// examples/llm-demo.mjs — FR-86 + existing LLM features, demonstrated.
//
// Creates a "contested" document about AI safety with clear
// claimable passages, plus a companion critique. Then the user can:
//   1. Click "Suggest connections" (FR-86) on the contested work
//   2. See the LLM propose Disagreements/References
//   3. Confirm them into the argument chain
//   4. Try the existing features (narration, auto-tag)
//
// Prereqs: Ollama running + OLLAMA_BASE_URL set on the server.
//
//   node examples/llm-demo.mjs [ws-url]
//
import WebSocket from "../web/app/node_modules/ws/index.js";

const WS_URL_BASE = process.argv[2] ?? "ws://127.0.0.1:8080/xudanu?format=json";

let WS_URL = WS_URL_BASE;
try {
  const csrfResp = await fetch("http://127.0.0.1:8080/csrf-token");
  const csrfJson = await csrfResp.json();
  const csrfToken = csrfJson.csrf_token ?? csrfJson.token ?? "";
  if (csrfToken) WS_URL = `${WS_URL_BASE}&csrf_token=${encodeURIComponent(csrfToken)}`;
} catch { /* no CSRF */ }

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
  const frame = JSON.parse(data.toString());
  if (frame.type === "response" || frame.type === "error") {
    const p = pending.get(frame.id);
    if (p) { pending.delete(frame.id); clearTimeout(p.timeout);
      frame.type === "error" ? p.reject(new Error(frame.message)) : p.resolve(frame.value); }
  }
});
const v = (x) => (x && typeof x === "object" && "value" in x ? x.value : x);
const say = (m) => console.log(m);

// ── The contested document ─────────────────────────────────────────

const CLAIMS_TEXT = `AI Safety Claims — A Contested Analysis

The alignment problem is the most important challenge facing humanity in the 21st century. Without robust alignment techniques, advanced AI systems could cause catastrophic harm through goal misgeneralization, power-seeking behavior, or deceptive alignment.

Current alignment techniques are insufficient. RLHF (Reinforcement Learning from Human Feedback) has been shown to produce models that are sycophantic rather than genuinely aligned. Constitutional AI addresses some issues but relies on the constitution being correct, which is itself an unaligned input.

Interpretability research has not kept pace with capability gains. We cannot yet reliably inspect the internal reasoning of large language models. Mechanistic interpretability shows promise but has only been demonstrated on small models with known architectures.

The compute overhang means that safety research is chronically underfunded relative to capability research. For every dollar spent on alignment, approximately fifty dollars are spent on capability improvements. This ratio should terrify anyone who takes existential risk seriously.

Regulatory approaches have been too slow. The EU AI Act, while well-intentioned, will not address the core technical challenges. We need empirical safety standards, not paperwork compliance.

Open-source models pose a unique risk because they cannot be recalled or constrained once released. The democratization of AI capabilities, while beneficial for research transparency, also democratizes the ability to cause harm.`;

const CRITIQUE_TEXT = `A Response to the AI Safety Claims

The claim that RLHF produces sycophancy rather than genuine alignment conflates two different failure modes. Sycophancy is a form of reward hacking — the model learns to please evaluators rather than solve the task. This is a training pipeline issue, not a fundamental alignment limitation. More sophisticated reward models and better evaluation methodologies can address it.

The compute overhang statistic of fifty-to-one capability versus safety spending is misleading. It ignores that much safety research happens within capability teams — the same researchers who build models also study their failure modes. The ratio is closer to five-to-one when you count embedded safety work.

The regulatory pessimism about the EU AI Act underestimates the signaling effect of regulation. Even imperfect rules shift industry norms and create market pressure for safety. The act's risk-tiered approach is a reasonable first draft of what empirical safety standards could look like.`;

// ── Create everything ──────────────────────────────────────────────

await opened;
await request("session_connect");
await request("session_login_public");
say("◆ connected\n");

// 1. The contested work
const claims = v(await request("work_create", { edition: { text: CLAIMS_TEXT } }));
await request("work_set_title", { work_id: claims, title: "AI Safety — The Contested Claims" });
await request("work_publish", { work_id: claims });
say(`◆ Contested work: 0x${claims.toString(16)} — "AI Safety — The Contested Claims"`);

// 2. The critique (has specific disagreements with the claims)
const critique = v(await request("work_create", { edition: { text: CRITIQUE_TEXT } }));
await request("work_set_title", { work_id: critique, title: "AI Safety — The Response" });
await request("work_publish", { work_id: critique });
say(`◆ Critique: 0x${critique.toString(16)} — "AI Safety — The Response"`);

// 3. Create one human Disagreement (so the argument chain has a seed)
const claimsEd = v(await request("work_get_edition", { work_id: claims }));
const claimsText = typeof claimsEd === "string" ? claimsEd : claimsEd?.text ?? "";
const rlhfAt = claimsText.indexOf("RLHF (Reinforcement Learning from Human Feedback)");

const critiqueEd = v(await request("work_get_edition", { work_id: critique }));
const critiqueText = typeof critiqueEd === "string" ? critiqueEd : critiqueEd?.text ?? "";
const sycophAt = critiqueText.indexOf("sycophancy rather than genuine alignment");

if (rlhfAt >= 0 && sycophAt >= 0) {
  const link = v(await request("link_create", {
    origin: critique, destination: claims,
    origin_ref: { kind: "single", work_context: critique,
      excerpt: "sycophancy rather than genuine alignment", start_position: sycophAt, end_position: sycophAt + 40 },
    destination_ref: { kind: "single", work_context: claims,
      excerpt: "RLHF (Reinforcement Learning from Human Feedback)", start_position: rlhfAt, end_position: rlhfAt + 45 },
  }));
  const linkId = typeof link === "number" ? link : link?.link_id;
  await request("link_set_types", { link_id: linkId, link_types: [3] });
  say(`◆ Human Disagreement seeded: "The Response" → the RLHF passage`);
}

say(`\n◆ Seeded. Now try the LLM features:`);
say(`\n  1. Open "AI Safety — The Contested Claims" (0x${claims.toString(16)})`);
say(`  2. The LLM "Suggest connections" button will appear in the UI`);
say(`     (it calls the llm_propose_connections op — needs Ollama running)`);
say(`  3. The LLM reads the contested work + the connected critique`);
say(`     and proposes additional typed connections`);
say(`  4. You confirm/edit/reject each proposal`);
say(`  5. Confirmed links enter the argument chain with the LLM's provenance`);
say(`\n  Server must be started with:`);
say(`     OLLAMA_BASE_URL=http://localhost:11434 \\`);
say(`     OLLAMA_MODEL=qwen2.5:1.5b \\`);
say(`     xudanu-server run 127.0.0.1:8080 data --allow-loopback \\`);
say(`       --allowed-origin http://localhost:5173 --csrf-token`);
say(`\n  The claimable passages are:`);
say(`     · "RLHF has been shown to produce sycophantic..."`);
say(`     · "compute overhang... fifty dollars"`);
say(`     · "regulatory approaches have been too slow"`);
say(`     · "open-source models pose a unique risk"`);

ws.close();
process.exit(0);
