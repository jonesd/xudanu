#!/usr/bin/env node
// gov-drive.mjs — governance test driver: admin-login on a node's WS
// and drive/inspect PBFT state. Used by federation-governance-tests.sh.
//
// Usage: node gov-drive.mjs <ws-url> <admin-pass> <command> [args]
// Commands:
//   propose <origin-tag>       propose a RoyaltyRecord; prints "PROPOSED seq=<n>" or "REFUSED"
//   sequence                   print current governance sequence
//   view                       print current view
//   digests                    print sealed-batch digests, comma-joined
//   leader-check               print "LEADER" if this node is the view-0 leader, else "NOT-LEADER"
import WebSocket from "ws";

const [url, password, cmd, ...args] = process.argv.slice(2);
if (!url || !password || !cmd) {
  console.error("usage: node gov-drive.mjs <ws-url> <admin-pass> <command> [args]");
  process.exit(2);
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
    if (frame.type === "error") p.reject(new Error(`${frame.op ?? p.op}: ${frame.message}`));
    else p.resolve(frame.value);
  }
});

function request(op, payload = {}) {
  const id = nextId++;
  const frame = { v: 2, id, type: "request", op, payload };
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      pending.delete(id);
      reject(new Error(`${op}: timeout`));
    }, 15000);
    pending.set(id, { resolve, reject, timeout, op });
    ws.send(JSON.stringify(frame));
  });
}

const val = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);

async function adminSession() {
  await request("session_connect");
  await request("session_login_public");
  const adminId = val(await request("club_id_by_name", { name: "admin" }));
  await request("session_login", { club_id: adminId });
  await request("session_authenticate", {
    credential: { password: Array.from(password).map((c) => c.charCodeAt(0)) },
  });
}

async function main() {
  await new Promise((res, rej) => {
    ws.once("open", res);
    ws.once("error", (e) => rej(new Error(`connect failed: ${e.message}`)));
  });
  try {
    await adminSession();
    switch (cmd) {
      case "propose": {
        const tag = args[0] ?? "gov-test";
        const r = val(
          await request("governance_propose", {
            transactions: [
              {
                type: "royalty_record",
                origin_server_id: tag,
                target_server_id: tag,
                content_fingerprint_hex: "ab".repeat(32),
                royalty_type: "transclusion",
                amount: 1,
              },
            ],
          }),
        );
        if (r && typeof r === "object" && r.proposal) {
          console.log(`PROPOSED seq=${r.proposal.sequence_number}`);
        } else {
          console.log("REFUSED");
        }
        break;
      }
      case "sequence": {
        const s = val(await request("governance_status"));
        console.log(val(s)?.sequence ?? s);
        break;
      }
      case "view": {
        const s = val(await request("governance_status"));
        console.log(val(s)?.view ?? s);
        break;
      }
      case "leader": {
        const s = val(await request("governance_status"));
        const st = val(s) ?? {};
        console.log(st.is_leader ? "LEADER" : "NOT-LEADER");
        break;
      }
      case "digests": {
        const log = val(await request("governance_log"));
        const batches = Array.isArray(log) ? log : (val(log)?.log ?? []);
        console.log(batches.map((b) => b.digest).join(","));
        break;
      }
      default:
        console.error(`unknown command: ${cmd}`);
        process.exit(2);
    }
  } finally {
    ws.close();
  }
}

main().catch((e) => {
  console.error(`ERR ${e.message}`);
  process.exit(1);
});
