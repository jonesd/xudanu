#!/usr/bin/env node
// ws-link-probe.mjs — drive one cross-server link_create against a node
// and report the notify outcome + wall-clock timing as JSON.
//
// Usage:
//   node ws-link-probe.mjs <sender-ws-url> <receiver-address> <receiver-work-hex> [label]
//
// Steps: session_connect + login_public, work_create (origin),
// link_create with a cross-server destination_ref pointing at the
// receiver, then link_get to read cross_server_notify_accepted /
// cross_server_notify_error. Exits 0 on a well-formed probe (the
// orchestrator asserts on the outcome JSON).
import WebSocket from "ws";

const [senderUrl, receiverAddr, receiverWorkHex, label = "probe"] = process.argv.slice(2);

// Node's ws sends no Origin by default; servers with an origin
// allowlist reject bare clients. Derive one from the URL unless
// WS_ORIGIN is set.
const wsHeaders = {};
try {
  const o = process.env.WS_ORIGIN ?? new URL(senderUrl).origin;
  wsHeaders.origin = o;
} catch {}

function die(msg) {
  console.error(JSON.stringify({ label, ok: false, error: msg }));
  process.exit(1);
}

let ws;
try {
  ws = new WebSocket(senderUrl, { headers: wsHeaders });
} catch (e) {
  die(`connect failed: ${e.message}`);
}

let nextId = 1;
const pending = new Map();

function request(op, payload) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    const timeout = setTimeout(() => {
      pending.delete(id);
      reject(new Error(`timeout waiting for ${op}`));
    }, 30000);
    pending.set(id, { resolve, reject, timeout, op });
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
ws.on("error", (e) => die(`ws error: ${e.message}`));

const value = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);

async function main() {
  await new Promise((res, rej) => {
    ws.once("open", res);
    ws.once("error", rej);
  });
  await request("session_connect");
  await request("session_login_public");

  const work = value(await request("work_create", { edition: { text: `probe ${label} ${Date.now()}` } }));
  const origin = typeof work === "number" ? work : work?.work_id;
  if (typeof origin !== "number") die(`unexpected work_create result: ${JSON.stringify(work)}`);

  const csr = {
    tumbler: `9.${receiverWorkHex}.1.0`,
    origin_server_id: 9,
    origin_server_address: receiverAddr,
    content_hash: "00".repeat(32),
    origin_author: "docker probe",
    origin_author_key: "00".repeat(32),
    excerpt: "docker probe passage",
  };

  const t0 = Date.now();
  let linkId;
  try {
    linkId = value(await request("link_create", {
      origin,
      destination: origin,
      origin_ref: {
        kind: "single",
        work_context: origin,
        excerpt: "docker probe passage",
        start_position: 0,
        end_position: 20,
      },
      destination_ref: {
        kind: "single",
        work_context: null,
        original_context: null,
        excerpt: "docker probe passage",
        start_position: null,
        end_position: null,
        cross_server_ref: csr,
      },
    }));
  } catch (e) {
    die(`link_create failed: ${e.message}`);
  }
  const createMs = Date.now() - t0;

  const link = value(await request("link_get", { link_id: linkId }));
  console.log(JSON.stringify({
    label,
    ok: true,
    link_id: linkId,
    create_ms: createMs,
    accepted: link.cross_server_notify_accepted ?? null,
    error: link.cross_server_notify_error ?? null,
  }));
  ws.close();
  process.exit(0);
}

main().catch((e) => die(e.message));
