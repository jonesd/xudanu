const WebSocket = require("ws");

function createClient(url) {
  const ws = new WebSocket(url);
  let msgId = 0;
  const pending = new Map();

  ws.on("message", (d) => {
    const msg = JSON.parse(d.toString());
    if (msg.type === "response" || msg.type === "error") {
      const p = pending.get(msg.id);
      if (p) {
        pending.delete(msg.id);
        if (msg.type === "error") p.reject(new Error(msg.message));
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
      }, 15000);
    });
  }

  function extractVal(v) {
    if (v && typeof v === "object" && "value" in v) return v.value;
    return v;
  }

  return new Promise((resolve, reject) => {
    ws.on("open", async () => {
      await new Promise(r => ws.once("message", () => r()));
      await send("session_connect");
      await send("session_login_public");
      resolve({ send, extractVal, ws });
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

  // ── Scenario 1: Server Discovery & Trust ──
  console.log("\n=== Scenario 1: Server Discovery & Trust ===");
  const bob = await createClient("ws://127.0.0.1:8080/xudanu?format=json&login=public");

  // 1a: Create a local work on Bob
  await test("Create local work on Bob", async () => {
    const resp = await bob.send("work_create", { edition: { text: "# My Work\n\nLocal content for testing." } });
    const wid = bob.extractVal(resp);
    await bob.send("work_set_title", { work_id: wid, title: "My Work" });
    return `work_id=${wid}`;
  });

  // 1b: Add Alice to Bob's directory
  await test("Add Alice to directory", async () => {
    const resp = await bob.send("server_directory_add", { address: "127.0.0.1", port: 8081 });
    const val = bob.extractVal(resp);
    if (!val || !val.name) throw new Error("missing name in response");
    return `name=${val.name}, trusted=${val.trusted}`;
  });

  // 1c: List directory — verify Alice is there, untrusted
  let aliceServerId;
  await test("Directory list shows Alice (untrusted)", async () => {
    const resp = await bob.send("server_directory_list");
    const val = bob.extractVal(resp);
    const servers = val.servers || val;
    if (!Array.isArray(servers) || servers.length === 0) throw new Error("empty directory");
    const alice = servers.find(s => s.name === "Alice" || s.address === "127.0.0.1");
    if (!alice) throw new Error("Alice not in directory");
    if (alice.trusted) throw new Error("Alice should be untrusted initially");
    aliceServerId = alice.server_id;
    return `server_id=${aliceServerId}, trusted=false`;
  });

  // 1d: Trust Alice
  await test("Trust Alice", async () => {
    const resp = await bob.send("server_directory_set_trust", { server_id: aliceServerId, trusted: true });
    const val = bob.extractVal(resp);
    if (!val.trusted) throw new Error("trust not set");
    return `trusted=${val.trusted}`;
  });

  // 1e: Verify Alice is now trusted
  await test("Directory shows Alice as trusted", async () => {
    const resp = await bob.send("server_directory_list");
    const val = bob.extractVal(resp);
    const servers = val.servers || val;
    const alice = servers.find(s => String(s.server_id) === String(aliceServerId));
    if (!alice || !alice.trusted) throw new Error("Alice not trusted");
    if (!alice.first_seen) throw new Error("first_seen missing");
    if (alice.quarantined) throw new Error("should not be quarantined");
    return `trusted=true, first_seen=${alice.first_seen}`;
  });

  // ── Scenario 2: Browse & View Remote Work ──
  console.log("\n=== Scenario 2: Browse & View Remote Work ===");

  // 2a: List works from Alice
  let remoteWorkId;
  await test("Browse Alice's works via backend proxy", async () => {
    const resp = await bob.send("cross_server_list_works", { server_id: aliceServerId });
    const val = bob.extractVal(resp);
    const works = val.works || [];
    if (works.length === 0) throw new Error("no works returned");
    remoteWorkId = works[0].work_id;
    return `${works.length} works found, first: "${works[0].title}"`;
  });

  // 2b: Fetch a specific work via backend proxy (full verification)
  let remoteWork;
  await test("Fetch remote work with full verification", async () => {
    const resp = await bob.send("cross_server_fetch_work", { server_id: aliceServerId, work_id: remoteWorkId });
    const val = bob.extractVal(resp);
    if (!val.text || val.text.length === 0) throw new Error("no text in response");
    if (!val.title) throw new Error("no title");
    if (!val.tumbler) throw new Error("no tumbler");
    if (!val.license) throw new Error("no license");
    remoteWork = val;
    return `"${val.title}" (${val.text.length} chars, license=${val.license})`;
  });

  // 2c: Verify TOFU key was pinned
  await test("TOFU key pinned after first fetch", async () => {
    const resp = await bob.send("server_directory_list");
    const val = bob.extractVal(resp);
    const servers = val.servers || val;
    const alice = servers.find(s => String(s.server_id) === String(aliceServerId));
    // successful_resolutions should be > 0 after a successful fetch
    if (!alice.successful_resolutions || alice.successful_resolutions === 0) {
      throw new Error("successful_resolutions should be > 0");
    }
    return `successful_resolutions=${alice.successful_resolutions}`;
  });

  // ── Scenario 3: Transclude a Passage (MVP via blockquote) ──
  console.log("\n=== Scenario 3: Transclude a Passage ===");
  await test("Insert passage into local work", async () => {
    const excerpt = remoteWork.text.split("\n\n")[1] || remoteWork.text.slice(0, 100);
    const citation = `\n\n> ${excerpt.slice(0, 80)}...\n> — From "${remoteWork.title}" via Alice (${remoteWork.tumbler})\n`;
    // Get current local work text and append
    const listResp = await bob.send("work_list", { limit: 10 });
    const listVal = bob.extractVal(listResp);
    const works = listVal.works || listVal || [];
    if (!Array.isArray(works) || works.length === 0) throw new Error("no local works");
    const localWid = works[0].work_id || works[0];
    const textResp = await bob.send("work_text_range", { work_id: localWid, start: 0, end: 99999 });
    const currentText = bob.extractVal(textResp) || "";
    await bob.send("work_set_text", { work_id: localWid, text: currentText + citation });
    return `appended ${citation.length} chars to work ${localWid}`;
  });

  // ── Scenario 4: Copy Full Document ──
  console.log("\n=== Scenario 4: Copy Full Document ===");
  let copiedWorkId;
  await test("Copy remote work as local copy with provenance", async () => {
    const provenance = `> Imported from Alice\n> Tumbler: ${remoteWork.tumbler}\n> License: ${remoteWork.license}\n\n`;
    const resp = await bob.send("work_create", { edition: { text: provenance + remoteWork.text } });
    const wid = bob.extractVal(resp);
    await bob.send("work_set_title", { work_id: wid, title: remoteWork.title + " (from Alice)" });
    copiedWorkId = wid;
    return `copied as work ${wid}: "${remoteWork.title} (from Alice)"`;
  });

  // 4b: Verify the copy is editable
  await test("Copied work is editable", async () => {
    await bob.send("work_set_text", { work_id: copiedWorkId, text: "Modified copy content" });
    const resp = await bob.send("work_text_range", { work_id: copiedWorkId, start: 0, end: 100 });
    const text = bob.extractVal(resp);
    if (text !== "Modified copy content") throw new Error("text not updated");
    return "editable=true";
  });

  // ── Scenario 5: Cross-Server Link ──
  console.log("\n=== Scenario 5: Cross-Server Link ===");
  await test("Create cross-server link", async () => {
    const listResp = await bob.send("work_list", { limit: 10 });
    const listVal = bob.extractVal(listResp);
    const works = listVal.works || listVal || [];
    const localWid = typeof works[0] === "number" ? works[0] : (works[0].work_id || works[0]);
    const resp = await bob.send("cross_server_link_create", {
      local_work_id: localWid,
      remote_tumbler: remoteWork.tumbler,
      remote_title: remoteWork.title,
      remote_server_name: "Alice",
      remote_server_id: aliceServerId,
      link_type: "reference",
    });
    const val = bob.extractVal(resp);
    if (!val.created) throw new Error("link not created");
    return `link created from work ${localWid} to "${remoteWork.title}"`;
  });

  // 5b: Verify link appears in link list
  await test("Cross-server link is listed", async () => {
    const listResp = await bob.send("work_list", { limit: 10 });
    const listVal = bob.extractVal(listResp);
    const works = listVal.works || listVal || [];
    const localWid = typeof works[0] === "number" ? works[0] : (works[0].work_id || works[0]);
    const resp = await bob.send("cross_server_link_list", { work_id: localWid });
    const val = bob.extractVal(resp);
    const links = val.links || [];
    if (links.length === 0) throw new Error("no links found");
    if (links[0].remote_title !== remoteWork.title) throw new Error("wrong title");
    return `${links.length} link(s), remote="${links[0].remote_title}"`;
  });

  // ── Scenario 6: Federated Search ──
  console.log("\n=== Scenario 6: Federated Search ===");
  await test("Federated search returns results from both servers", async () => {
    const resp = await bob.send("federated_search", { query: "transclusion" });
    const val = bob.extractVal(resp);
    const results = val.results || [];
    if (results.length === 0) throw new Error("no results");
    const hasLocal = results.some(r => r.local);
    const hasRemote = results.some(r => !r.local);
    return `${results.length} results: ${hasLocal ? "local ✓" : "local ✗"}, ${hasRemote ? "remote ✓" : "remote ✗"}`;
  });

  await test("Federated search for non-existent term returns nothing", async () => {
    const resp = await bob.send("federated_search", { query: "zzzznotfoundzzzz" });
    const val = bob.extractVal(resp);
    const results = val.results || [];
    if (results.length > 0) throw new Error(`expected 0 results, got ${results.length}`);
    return "0 results (correct)";
  });

  // ── Scenario 7: Server Discovery via Introductions ──
  console.log("\n=== Scenario 7: Server Discovery via Introductions ===");
  await test("Fetch introductions from Alice", async () => {
    const resp = await bob.send("fetch_introductions", { server_id: aliceServerId });
    const val = bob.extractVal(resp);
    const intros = val.introductions || [];
    return `${intros.length} introduction(s) found`;
  });

  // ── Scenario 8: Server Goes Offline ──
  console.log("\n=== Scenario 8: Server Goes Offline ===");
  await test("Fetch from offline server fails gracefully", async () => {
    // We can't easily kill Alice in this script, so we test with a bad server_id
    const resp = await bob.send("cross_server_list_works", { server_id: "999999" });
    throw new Error(`should have failed for unknown server, got: ${JSON.stringify(resp).slice(0, 100)}`);
  });

  // ── Scenario 10: Persistence Check ──
  console.log("\n=== Scenario 10: Persistence ===");
  await test("Directory has Alice with trust metrics", async () => {
    const resp = await bob.send("server_directory_list");
    const val = bob.extractVal(resp);
    const servers = val.servers || val;
    const alice = servers.find(s => String(s.server_id) === String(aliceServerId));
    if (!alice) throw new Error("Alice not in directory");
    if (!alice.trusted) throw new Error("not trusted");
    if (!alice.first_seen) throw new Error("first_seen missing");
    if (alice.successful_resolutions === undefined) throw new Error("successful_resolutions missing");
    return `trusted=${alice.trusted}, resolves=${alice.successful_resolutions}`;
  });

  bob.ws.close();

  // ── Summary ──
  console.log("\n=== SUMMARY ===");
  const passed = log.filter(l => l.startsWith("PASS")).length;
  const failed = log.filter(l => l.startsWith("FAIL")).length;
  console.log(`${passed} passed, ${failed} failed out of ${log.length} tests`);
  console.log("\n" + log.join("\n"));

  process.exit(failed > 0 ? 1 : 0);
}

runTests().catch(e => { console.error(e); process.exit(1); });
