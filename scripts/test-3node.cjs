const WebSocket = require("ws");

function createClient(port) {
  const ws = new WebSocket(`ws://127.0.0.1:${port}/xudanu?format=json&login=public`);
  let msgId = 0;
  const pending = new Map();

  ws.on("message", (d) => {
    const msg = JSON.parse(d.toString());
    if (msg.type === "response" || msg.type === "error") {
      const p = pending.get(msg.id);
      if (p) {
        pending.delete(msg.id);
        if (msg.type === "error") p.reject(new Error(msg.message || "unknown error"));
        else p.resolve(msg.value);
      }
    }
  });

  function send(op, payload) {
    const id = ++msgId;
    return new Promise((res, rej) => {
      pending.set(id, { resolve: res, reject: rej });
      const f = { v: 2, type: "request", id, op };
      if (payload) f.payload = payload;
      ws.send(JSON.stringify(f));
      setTimeout(() => {
        if (pending.has(id)) { pending.delete(id); rej(new Error(op + " timeout")); }
      }, 30000);
    });
  }

  function ev(v) {
    if (v && typeof v === "object" && "value" in v) return v.value;
    if (v && typeof v === "object" && "type" in v && v.type === "id") return v.value;
    return v;
  }

  return new Promise((resolve, reject) => {
    ws.on("open", async () => {
      await new Promise(r => ws.once("message", () => r()));
      await send("session_connect");
      await send("session_login_public");
      resolve({ send, ev, ws });
    });
    ws.on("error", reject);
  });
}

async function runTests() {
  const log = [];
  const test = async (name, fn) => {
    try {
      const result = await fn();
      log.push(`PASS: ${name}${result ? " — " + result : ""}`);
      console.log(`PASS: ${name}${result ? " — " + result : ""}`);
    } catch (e) {
      log.push(`FAIL: ${name} — ${e.message}`);
      console.log(`FAIL: ${name} — ${e.message}`);
    }
  };

  // ── Setup: Create test data on Alice ──
  console.log("\n=== Setting up test data on Alice ===");
  const alice = await createClient(8081);
  const works = [
    { t: "On Transclusion", d: "Transclusion is the act of including content by reference, not by copying. The original lives in exactly one place." },
    { t: "The Xanadu Dream", d: "Project Xanadu was conceived in 1960 as a global hypertext system with bilateral links." },
    { t: "O-Tree CRDT", d: "The O-tree is a position-based CRDT using space algebra for conflict-free merging." },
  ];
  for (const w of works) {
    const resp = await alice.send("work_create", { edition: { text: `# ${w.t}\n\n${w.d}` } });
    const wid = alice.ev(resp);
    await alice.send("work_set_title", { work_id: wid, title: w.t });
    await alice.send("work_publish", { work_id: wid });
    console.log(`  Alice: [${wid}] ${w.t}`);
  }

  // Create one work on Carol too
  const carol = await createClient(8083);
  const cResp = await carol.send("work_create", { edition: { text: "# Carol's Document\n\nThis is content only on Carol's server." } });
  const cWid = carol.ev(cResp);
  await carol.send("work_set_title", { work_id: cWid, title: "Carol's Document" });
  await carol.send("work_publish", { work_id: cWid });
  console.log(`  Carol: [${cWid}] Carol's Document`);

  // ── Phase 1: Bob adds Alice, trusts her ──
  console.log("\n=== Phase 1: Bob discovers Alice ===");
  const bob = await createClient(8082);

  let aliceServerId;
  await test("Bob adds Alice to directory", async () => {
    const resp = await bob.send("server_directory_add", { address: "alice", port: 8080 });
    const val = bob.ev(resp);
    if (!val || !val.name) throw new Error("missing name");
    aliceServerId = val.server_id || (val.value && val.value.server_id);
    // server_id might be a string from the new format
    if (typeof aliceServerId === "object") aliceServerId = aliceServerId.server_id;
    return `name=${val.name}, server_id=${aliceServerId}`;
  });

  await test("Bob trusts Alice", async () => {
    const resp = await bob.send("server_directory_set_trust", { server_id: String(aliceServerId), trusted: true });
    const val = bob.ev(resp);
    if (!val.trusted) throw new Error("trust not set");
    return "trusted";
  });

  // ── Phase 2: Bob browses Alice's works ──
  console.log("\n=== Phase 2: Bob browses Alice's works ===");
  await test("Bob browses Alice's published works", async () => {
    const resp = await bob.send("cross_server_list_works", { server_id: String(aliceServerId) });
    const val = bob.ev(resp);
    const works = val.works || [];
    if (works.length < 3) throw new Error(`expected 3+ works, got ${works.length}`);
    return `${works.length} works: ${works.map(w => w.title).join(", ")}`;
  });

  let remoteWorkId, remoteWorkTitle, remoteTumbler;
  await test("Bob fetches a specific work from Alice", async () => {
    const listResp = await bob.send("cross_server_list_works", { server_id: String(aliceServerId) });
    const listVal = bob.ev(listResp);
    remoteWorkId = listVal.works[0].work_id;
    remoteWorkTitle = listVal.works[0].title;
    const resp = await bob.send("cross_server_fetch_work", { server_id: String(aliceServerId), work_id: remoteWorkId });
    const val = bob.ev(resp);
    if (!val.text || val.text.length === 0) throw new Error("no text");
    remoteTumbler = val.tumbler;
    return `"${val.title}" (${val.text.length} chars, license=${val.license})`;
  });

  // ── Phase 3: Bob copies a document from Alice ──
  console.log("\n=== Phase 3: Bob copies document from Alice ===");
  let copiedWorkId;
  await test("Bob copies Alice's work to his server", async () => {
    const fetchResp = await bob.send("cross_server_fetch_work", { server_id: String(aliceServerId), work_id: remoteWorkId });
    const fetchVal = bob.ev(fetchResp);
    const provenance = `> Imported from Alice\n> Tumbler: ${fetchVal.tumbler}\n> License: ${fetchVal.license}\n\n`;
    const resp = await bob.send("work_create", { edition: { text: provenance + fetchVal.text } });
    copiedWorkId = bob.ev(resp);
    await bob.send("work_set_title", { work_id: copiedWorkId, title: `${fetchVal.title} (from Alice)` });
    return `copied as work ${copiedWorkId}`;
  });

  // ── Phase 4: Bob creates a cross-server link ──
  console.log("\n=== Phase 4: Cross-server link ===");
  await test("Bob creates a link to Alice's work", async () => {
    const resp = await bob.send("cross_server_link_create", {
      local_work_id: copiedWorkId,
      remote_tumbler: remoteTumbler,
      remote_title: remoteWorkTitle,
      remote_server_name: "Alice",
      remote_server_id: aliceServerId,
      link_type: "reference",
    });
    const val = bob.ev(resp);
    if (!val.created) throw new Error("link not created");
    return "link created";
  });

  await test("Cross-server link appears in link list", async () => {
    const resp = await bob.send("cross_server_link_list", { work_id: copiedWorkId });
    const val = bob.ev(resp);
    const links = val.links || [];
    if (links.length === 0) throw new Error("no links");
    return `${links.length} link(s): ${links[0].remote_title}`;
  });

  // ── Phase 5: Federated search ──
  console.log("\n=== Phase 5: Federated search ===");
  await test("Federated search finds Alice's content from Bob", async () => {
    const resp = await bob.send("federated_search", { query: "transclusion" });
    const val = bob.ev(resp);
    const results = val.results || [];
    if (results.length === 0) throw new Error("no results");
    return `${results.length} result(s) from ${new Set(results.map(r => r.server_name)).size} server(s)`;
  });

  // ── Phase 6: Carol adds Bob (not Alice directly) ──
  console.log("\n=== Phase 6: Introduction cascade (Bob → Carol) ===");
  let bobServerIdOnCarol;
  await test("Carol adds Bob to directory", async () => {
    const resp = await carol.send("server_directory_add", { address: "bob", port: 8080 });
    const val = carol.ev(resp);
    bobServerIdOnCarol = val.server_id;
    if (typeof bobServerIdOnCarol === "object") bobServerIdOnCarol = bobServerIdOnCarol.server_id;
    return `server_id=${bobServerIdOnCarol}`;
  });

  await test("Carol trusts Bob", async () => {
    const resp = await carol.send("server_directory_set_trust", { server_id: String(bobServerIdOnCarol), trusted: true });
    const val = carol.ev(resp);
    if (!val.trusted) throw new Error("trust not set");
    return "trusted";
  });

  // ── Phase 7: Carol discovers Alice through Bob ──
  console.log("\n=== Phase 7: Carol discovers Alice via Bob's introductions ===");
  await test("Carol fetches Bob's introductions", async () => {
    const resp = await carol.send("fetch_introductions", { server_id: String(bobServerIdOnCarol) });
    const val = carol.ev(resp);
    const intros = val.introductions || [];
    return `${intros.length} introduction(s) found${intros.length > 0 ? ": " + intros.map(i => i.name).join(", ") : ""}`;
  });

  await test("Carol browses Bob's works (which include copied Alice content)", async () => {
    const resp = await carol.send("cross_server_list_works", { server_id: String(bobServerIdOnCarol) });
    const val = carol.ev(resp);
    const works = val.works || [];
    return `${works.length} works on Bob`;
  });

  // ── Phase 8: Carol adds Alice directly (after discovery) ──
  console.log("\n=== Phase 8: Carol adds Alice directly ===");
  await test("Carol adds Alice to directory", async () => {
    const resp = await carol.send("server_directory_add", { address: "alice", port: 8080 });
    const val = carol.ev(resp);
    return `name=${val.name}`;
  });

  let aliceServerIdOnCarol;
  await test("Carol trusts Alice", async () => {
    const listResp = await carol.send("server_directory_list");
    const listVal = carol.ev(listResp);
    const servers = listVal.servers || listVal || [];
    const aliceEntry = servers.find(s => s.name === "Alice");
    if (!aliceEntry) throw new Error("Alice not in Carol's directory");
    aliceServerIdOnCarol = aliceEntry.server_id;
    await carol.send("server_directory_set_trust", { server_id: String(aliceServerIdOnCarol), trusted: true });
    return "trusted";
  });

  // ── Phase 9: Federated search from Carol (should hit both Alice and Bob) ──
  console.log("\n=== Phase 9: Federated search from Carol ===");
  await test("Carol's federated search hits multiple servers", async () => {
    const resp = await carol.send("federated_search", { query: "document" });
    const val = carol.ev(resp);
    const results = val.results || [];
    const servers = new Set(results.map(r => r.server_name));
    return `${results.length} results from ${servers.size} server(s): ${[...servers].join(", ")}`;
  });

  // ── Cleanup ──
  alice.ws.close();
  bob.ws.close();
  carol.ws.close();

  // ── Summary ──
  console.log("\n=== SUMMARY ===");
  const passed = log.filter(l => l.startsWith("PASS")).length;
  const failed = log.filter(l => l.startsWith("FAIL")).length;
  console.log(`${passed} passed, ${failed} failed out of ${log.length} tests`);
  console.log("\n" + log.join("\n"));

  process.exit(failed > 0 ? 1 : 0);
}

runTests().catch(e => { console.error(e); process.exit(1); });
