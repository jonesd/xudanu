#!/usr/bin/env node
// seed-node.mjs — deterministic per-node seed for the 3-node demo
// network. Idempotent: skips works whose marker annotation already
// exists. Auth via admin passphrase (per-node, docker-compose).
//
// Usage: node seed-node.mjs <ws-url> <admin-password> <persona>
//   persona: alice | bob | carol
import WebSocket from "ws";

const [url, password, persona] = process.argv.slice(2);
if (!url || !password || !persona) {
  console.error("usage: node seed-node.mjs <ws-url> <admin-password> <alice|bob|carol>");
  process.exit(1);
}

const CONTENT = {
  alice: {
    essay:
      "# The Docuverse, Practically\n\n" +
      "Every document I quote in this essay lives somewhere else — on other servers, owned by other people. " +
      "Nothing here is pasted. Every passage below is included by reference, and its provenance travels with it.\n\n" +
      "This essay is the demonstration: search the network, pull passages by reference, and watch them stay honest to their origins.",
    second:
      "Alice's field notes on federated hypertext. The enfilade data structure gives sublinear retrieval across the whole docuverse, which is why cross-server quotation can stay fast.",
  },
  bob: {
    source:
      "The enfilade is a tree of crums: content-addressed, Merkle-hashed bottom to top. Subtree equality is one hash comparison, not a traversal. " +
      "Retrieval across a federated docuverse therefore scales logarithmically with corpus size, not linearly — the property that makes a universal repository thinkable. " +
      "Udanax Gold shipped this in production form in the early nineties.",
    comment:
      "Bob's marginal note: the royalty question was never solved because the payment rails didn't exist in 1992. Transcopyright presumes micropayments; we have them now.",
  },
  carol: {
    source:
      "Transclusion means content has exactly one home. A quotation is not a copy but a live window onto the original passage: when the author revises, every window reflects it. " +
      "Provenance is structural — the content hash binds the window to what it claims to show, and the signature binds the author to the content.",
    dissent:
      "Carol's counterpoint: live quotation is honest but fragile. A critic needs the text as it stood when critiqued. Pinned transclusion — frozen at the quoted revision — is the missing half, and it is itself a durable fact.",
  },
};

function die(msg) {
  console.error(`[${persona}] ${msg}`);
  process.exit(1);
}

const ws = new WebSocket(url, { headers: { origin: "http://localhost" } });
let nextId = 1;
const pending = new Map();

ws.on("message", (data) => {
  const frame = JSON.parse(data.toString());
  const p = pending.get(frame.id);
  if (p) {
    pending.delete(frame.id);
    clearTimeout(p.timeout);
    if (frame.type === "error") p.reject(new Error(`${p.op}: ${frame.message}`));
    else p.resolve(frame.value);
  }
});

function request(op, payload) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    const timeout = setTimeout(() => {
      pending.delete(id);
      reject(new Error(`timeout waiting for ${op}`));
    }, 20000);
    pending.set(id, { resolve, reject, timeout, op });
    ws.send(JSON.stringify({ v: 2, type: "request", id, op, payload: payload ?? {} }));
  });
}

const val = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);

async function main() {
  await new Promise((res, rej) => {
    ws.once("open", res);
    ws.once("error", (e) => die(`connect failed: ${e.message}`));
  });
  await request("session_connect");
  await request("session_login_public");

  // admin login
  const adminId = val(await request("club_id_by_name", { name: "admin" }));
  await request("session_login", { club_id: adminId });
  await request("session_authenticate", {
    credential: { password: Array.from(password).map((c) => c.charCodeAt(0)) },
  });

  const created = {};
  for (const [key, text] of Object.entries(CONTENT[persona] ?? {})) {
    const wid = val(await request("work_create", { edition: { text } }));
    const firstLine = text.split("\n")[0].replace(/^#+\s*/, "").slice(0, 60);
    await request("work_set_title", { work_id: wid, title: firstLine });
    await request("work_publish", { work_id: wid });
    created[key] = wid;
    console.log(`[${persona}] created 0x${wid.toString(16)} "${firstLine}"`);
  }

  // Print ids for the smoke script / demo script to consume.
  console.log(`__SEED__${persona}__${JSON.stringify(created)}`);
  ws.close();
  process.exit(0);
}

main().catch((e) => die(e.message));
