const WebSocket = require("ws");

const PORT = 8081;

const WORKS = [
  { title: "On the Nature of Transclusion", text: "Transclusion is the act of including a portion of one document within another, not by copying, but by reference. The original content lives in exactly one place. All other appearances are live pointers — windows into the source.\n\nThis means that when the original author edits their text, every transclusion updates automatically. No stale copies. No version drift. The link is unbreakable.\n\nTed Nelson coined the term in 1980, distinguishing it from mere quotation. A quotation is a copy frozen in time. A transclusion is a living connection." },
  { title: "The Xanadu Dream", text: "Project Xanadu was conceived in 1960 as a global hypertext system where all documents would be interconnected through bilateral links. Unlike the World Wide Web's unidirectional one-way links, Xanadu links are two-way: you always know who is linking to you, and from where.\n\nThe system was designed around three core principles:\n\n1. Deep addressing — every byte of every document has a permanent, unique address\n2. Bilateral links — connections are visible from both ends\n3. Version management — every revision is preserved, nothing is ever lost\n\nThe web we have today implements none of these. Xudanu attempts to restore the dream." },
  { title: "O-Tree CRDT Algebra", text: "The O-tree is a position-based CRDT that uses the space algebra (regions and displacements) rather than operation-based or state-based approaches.\n\nEach character position is defined as a point in an abstract space. Insertions create new positions relative to existing ones. Deletions mark positions as removed but never actually delete them — this ensures convergence across all replicas.\n\nThe key insight is that positions are immutable once created. Two editors inserting at the same position will create different positions, and both will be visible in the merged result. No conflict resolution needed." },
  { title: "Cross-Server Content Verification", text: "When Server B fetches content from Server A, it verifies the content using a cryptographic hash. The BLAKE3 hash of the fetched text must match the hash embedded in the tumbler reference.\n\nThis ensures that even if Server A is compromised, it cannot serve different content than what was originally linked. The hash is a permanent commitment to the exact bytes.\n\nIf the content changes on Server A, the hash no longer matches, and the transclusion shows a stale warning. The old content can still be read from the cache." },
  { title: "Compound Documents and Recursive Transclusion", text: "A compound document is built from spans of other documents. Each span references a source work and a character range. When the compound is rendered, the spans are resolved recursively.\n\nTransclusions can nest up to 32 levels deep. Cycle detection prevents infinite loops — if document A transcludes B which transcludes A, the cycle is detected and broken gracefully.\n\nThis enables powerful patterns: a review document that transcludes the original text alongside commentary, or a reader document that assembles passages from multiple sources into a curated narrative." },
];

function extractValue(v) {
  if (v && typeof v === "object" && "value" in v) return v.value;
  return v;
}

async function main() {
  const ws = new WebSocket(`ws://127.0.0.1:${PORT}/xudanu?format=json&login=public`);
  let msgId = 0;
  const pending = new Map();

  function sendRequest(op, payload) {
    const id = ++msgId;
    return new Promise((resolve, reject) => {
      pending.set(id, { resolve, reject });
      const frame = { v: 2, type: "request", id, op };
      if (payload !== undefined) frame.payload = payload;
      ws.send(JSON.stringify(frame));
      setTimeout(() => {
        if (pending.has(id)) {
          pending.delete(id);
          reject(new Error(`${op} timed out`));
        }
      }, 5000);
    });
  }

  ws.on("message", (data) => {
    const msg = JSON.parse(data.toString());
    if (msg.type === "response" || msg.type === "error") {
      const p = pending.get(msg.id);
      if (p) {
        pending.delete(msg.id);
        if (msg.type === "error") p.reject(new Error(msg.message));
        else p.resolve(msg.value);
      }
    }
  });

  await new Promise((r, e) => { ws.on("open", r); ws.on("error", e); });
  await new Promise((r) => ws.once("message", () => r()));

  console.log("Connected, establishing session...");
  await sendRequest("session_connect");
  console.log("Session established");

  await sendRequest("session_login_public");
  console.log("Logged in as public\n");

  const created = [];
  for (const w of WORKS) {
    try {
      const resp = await sendRequest("work_create", {
        edition: { text: `# ${w.title}\n\n${w.text}` },
      });
      const workId = extractValue(resp);
      console.log(`Created [${workId}] "${w.title}"`);

      await sendRequest("work_set_title", { work_id: workId, title: w.title });
      await sendRequest("work_publish", { work_id: workId });
      console.log(`  Published`);
      created.push({ id: workId, title: w.title });
    } catch (e) {
      console.error(`  Error: ${e.message}`);
    }
  }

  ws.close();

  console.log(`\n=== ${created.length} works published on Alice (port ${PORT}) ===`);
  created.forEach((w) => console.log(`  [${w.id}] ${w.title}`));

  console.log("\nVerifying via public API...");
  const resp = await fetch(`http://127.0.0.1:${PORT}/api/public/works`);
  const data = await resp.json();
  console.log(JSON.stringify(data, null, 2));
  process.exit(0);
}

main().catch((e) => { console.error(e); process.exit(1); });
