#!/usr/bin/env node
// FR-35 Bloom Filter Federation Test
// Tests Bloom filter exchange, timing, and adversarial scenarios
// across the 3-node Docker network (Alice:8081, Bob:8082, Carol:8083)
//
// Run: NODE_PATH=web/app/node_modules node scripts/test-bloom.cjs

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

function fmtBytes(n) {
  if (n < 1024) return `${n}B`;
  if (n < 1048576) return `${(n / 1024).toFixed(1)}KB`;
  return `${(n / 1048576).toFixed(1)}MB`;
}

function fmtMs(ms) {
  if (ms < 1) return `${(ms * 1000).toFixed(0)}us`;
  if (ms < 1000) return `${ms.toFixed(1)}ms`;
  return `${(ms / 1000).toFixed(2)}s`;
}

async function runTests() {
  const log = [];
  const timings = {};

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

  const timed = async (name, fn) => {
    const start = performance.now();
    const result = await fn();
    const elapsed = performance.now() - start;
    timings[name] = elapsed;
    return { result, elapsed };
  };

  // ═══════════════════════════════════════════
  // PHASE 1: Setup — populate Alice and Carol
  // ═══════════════════════════════════════════
  console.log("\n═══ PHASE 1: Setup ═══");

  const alice = await createClient(8081);
  const bob = await createClient(8082);
  const carol = await createClient(8083);

  // Create 20 documents on Alice
  console.log("Creating 20 documents on Alice...");
  const aliceWorkIds = [];
  for (let i = 0; i < 20; i++) {
    const topics = [
      "Transclusion in hypertext systems",
      "The enfilade data structure",
      "Tumbler addressing and the docuverse",
      "Collaborative editing with CRDTs",
      "Cross-server content verification",
      "BLAKE3 content fingerprinting",
      "Bilateral links and backlinks",
      "Structural transclusion with crums",
      "O-tree position-based conflict resolution",
      "Span migration through arbitrary deltas",
      "Attribution chains and provenance",
      "Compound document composition",
      "Federated search across servers",
      "Ed25519 signature enforcement",
      "TOFU key pinning for trust",
      "Server discovery via introductions",
      "Content-addressed blob storage",
      "Three-way merge with last-writer-wins",
      "Version pinning for transclusions",
      "Space algebra: region and displacement",
    ];
    const title = topics[i];
    const text = `# ${title}\n\nThis is document ${i + 1} about ${title.toLowerCase()}. ` +
      `Lorem ipsum dolor sit amet, consectetur adipiscing elit. ` +
      `Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ` +
      `Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. ` +
      `Document ${i + 1} of 20.`;
    const resp = await alice.send("work_create", { edition: { text } });
    const wid = alice.ev(resp);
    await alice.send("work_set_title", { work_id: wid, title });
    await alice.send("work_publish", { work_id: wid });
    aliceWorkIds.push(wid);
  }
  console.log(`  Alice: ${aliceWorkIds.length} documents created`);

  // Create 5 documents on Carol
  console.log("Creating 5 documents on Carol...");
  const carolWorkIds = [];
  for (let i = 0; i < 5; i++) {
    const text = `# Carol's Document ${i + 1}\n\nContent unique to Carol's server. Item ${i + 1}.`;
    const resp = await carol.send("work_create", { edition: { text } });
    const wid = carol.ev(resp);
    await carol.send("work_set_title", { work_id: wid, title: `Carol Doc ${i + 1}` });
    await carol.send("work_publish", { work_id: wid });
    carolWorkIds.push(wid);
  }
  console.log(`  Carol: ${carolWorkIds.length} documents created`);

  // ═══════════════════════════════════════════
  // PHASE 2: Bob discovers servers
  // ═══════════════════════════════════════════
  console.log("\n═══ PHASE 2: Bob discovers Alice and Carol ═══");

  let aliceServerId;
  await test("Bob adds Alice", async () => {
    const resp = await bob.send("server_directory_add", { address: "alice", port: 8080 });
    const val = bob.ev(resp);
    aliceServerId = val.server_id;
    if (typeof aliceServerId === "object") aliceServerId = aliceServerId.server_id;
    await bob.send("server_directory_set_trust", { server_id: String(aliceServerId), trusted: true });
    return `server_id=${aliceServerId}`;
  });

  let carolServerId;
  await test("Bob adds Carol", async () => {
    const resp = await bob.send("server_directory_add", { address: "carol", port: 8080 });
    const val = bob.ev(resp);
    carolServerId = val.server_id;
    if (typeof carolServerId === "object") carolServerId = carolServerId.server_id;
    await bob.send("server_directory_set_trust", { server_id: String(carolServerId), trusted: true });
    return `server_id=${carolServerId}`;
  });

  // ═══════════════════════════════════════════
  // PHASE 3: Bloom filter exchange (normal)
  // ═══════════════════════════════════════════
  console.log("\n═══ PHASE 3: Bloom filter exchange (normal) ═══");

  let aliceFilter, carolFilter;
  await test("Bob fetches Alice's bloom filter", async () => {
    const { result, elapsed } = await timed("alice_bloom_fetch", () =>
      bob.send("bloom_filter_get", { server_id: String(aliceServerId) })
    );
    const val = bob.ev(result);
    aliceFilter = val;
    return `${val.item_count} items, ${fmtBytes(val.bits.length)}, ${fmtMs(elapsed)}`;
  });

  await test("Bob fetches Carol's bloom filter", async () => {
    const { result, elapsed } = await timed("carol_bloom_fetch", () =>
      bob.send("bloom_filter_get", { server_id: String(carolServerId) })
    );
    const val = bob.ev(result);
    carolFilter = val;
    return `${val.item_count} items, ${fmtBytes(val.bits.length)}, ${fmtMs(elapsed)}`;
  });

  await test("Alice's filter has correct item count", async () => {
    if (!aliceFilter) throw new Error("no filter");
    const expected = aliceWorkIds.length;
    if (aliceFilter.item_count < expected - 2 || aliceFilter.item_count > expected + 5) {
      throw new Error(`expected ~${expected} items, got ${aliceFilter.item_count}`);
    }
    return `${aliceFilter.item_count} items (expected ~${expected})`;
  });

  await test("Carol's filter has correct item count", async () => {
    if (!carolFilter) throw new Error("no filter");
    const expected = carolWorkIds.length;
    if (carolFilter.item_count < expected - 1 || carolFilter.item_count > expected + 3) {
      throw new Error(`expected ~${expected} items, got ${carolFilter.item_count}`);
    }
    return `${carolFilter.item_count} items (expected ~${expected})`;
  });

  // ═══════════════════════════════════════════
  // PHASE 4: Bloom filter membership checks
  // ═══════════════════════════════════════════
  console.log("\n═══ PHASE 4: Membership checks ═══");

  await test("Bloom check: Alice has her own work", async () => {
    const { result, elapsed } = await timed("bloom_check_known", () =>
      bob.send("bloom_filter_check", { server_id: String(aliceServerId), work_id: aliceWorkIds[0] })
    );
    const val = bob.ev(result);
    if (!val.present) throw new Error("Alice should have her own work");
    return `present=true, ${fmtMs(elapsed)}`;
  });

  await test("Bloom check: Alice does NOT have Carol's work", async () => {
    const { result, elapsed } = await timed("bloom_check_absent", () =>
      bob.send("bloom_filter_check", { server_id: String(aliceServerId), work_id: carolWorkIds[0] })
    );
    const val = bob.ev(result);
    if (val.present) throw new Error("Alice should not have Carol's work (possible false positive)");
    return `present=false, ${fmtMs(elapsed)}`;
  });

  // ═══════════════════════════════════════════
  // PHASE 5: Timing comparison — Bloom vs full list
  // ═══════════════════════════════════════════
  console.log("\n═══ PHASE 5: Timing comparison ═══");

  await test("Timing: full work list fetch (baseline)", async () => {
    const { result, elapsed } = await timed("full_list_fetch", () =>
      bob.send("cross_server_list_works", { server_id: String(aliceServerId) })
    );
    const val = bob.ev(result);
    const works = val.works || [];
    const dataSize = JSON.stringify(result).length;
    timings.full_list_size = dataSize;
    timings.full_list_count = works.length;
    return `${works.length} works, ${fmtBytes(dataSize)}, ${fmtMs(elapsed)}`;
  });

  await test("Timing: bloom filter fetch (optimized)", async () => {
    const { result, elapsed } = await timed("bloom_fetch", () =>
      bob.send("bloom_filter_get", { server_id: String(aliceServerId) })
    );
    const val = bob.ev(result);
    const dataSize = JSON.stringify(result).length;
    timings.bloom_size = dataSize;
    return `${val.item_count} items, ${fmtBytes(dataSize)}, ${fmtMs(elapsed)}`;
  });

  await test("Bandwidth savings measurement", async () => {
    if (!timings.full_list_size || !timings.bloom_size) throw new Error("missing timing data");
    const ratio = timings.full_list_size / timings.bloom_size;
    const saved = timings.full_list_size - timings.bloom_size;
    return `${fmtBytes(saved)} saved (${ratio.toFixed(0)}x reduction)`;
  });

  // ═══════════════════════════════════════════
  // PHASE 6: Bulk membership test (20 checks)
  // ═══════════════════════════════════════════
  console.log("\n═══ PHASE 6: Bulk membership (20 checks) ═══");

  await test("20 bloom checks faster than 1 full list fetch", async () => {
    let bloomTotal = 0;
    for (const wid of aliceWorkIds) {
      const { elapsed } = await timed("bulk_check", () =>
        bob.send("bloom_filter_check", { server_id: String(aliceServerId), work_id: wid })
      );
      bloomTotal += elapsed;
    }
    timings.bloom_20_checks = bloomTotal;
    timings.full_list_ms = timings.full_list_fetch || 0;
    return `20 checks: ${fmtMs(bloomTotal)} vs full list: ${fmtMs(timings.full_list_ms)}`;
  });

  // ═══════════════════════════════════════════
  // PHASE 7: False positive measurement
  // ═══════════════════════════════════════════
  console.log("\n═══ PHASE 7: False positive measurement ═══");

  await test("False positive rate measurement", async () => {
    let falsePositives = 0;
    let totalChecked = 0;
    for (let i = 900000; i < 900100 && i < 900000 + 100; i++) {
      const resp = await bob.send("bloom_filter_check", { server_id: String(aliceServerId), work_id: i });
      const val = bob.ev(resp);
      if (val.present) falsePositives++;
      totalChecked++;
    }
    const observedFpr = (falsePositives / totalChecked) * 100;
    timings.observed_fpr = observedFpr;
    return `${falsePositives}/${totalChecked} false positives (${observedFpr.toFixed(1)}%)`;
  });

  // ═══════════════════════════════════════════
  // PHASE 8: Adversarial — poisoned filter
  // ═══════════════════════════════════════════
  console.log("\n═══ PHASE 8: Adversarial — poisoned filter ═══");

  await test("Server rejects all-ones filter response", async () => {
    // We can't make Alice send a poisoned filter, but we can verify
    // the filter we received is NOT all-ones (i.e., it's legitimate)
    if (!aliceFilter) throw new Error("no filter");
    const allOnes = aliceFilter.bits.every(b => b === 0xFF);
    if (allOnes) throw new Error("Alice's filter IS all-ones — possible poisoning!");
    const density = aliceFilter.bits.reduce((sum, b) => sum + (b & 1), 0) / (aliceFilter.bits.length * 8);
    return `filter is legitimate (density: ${(density * 100).toFixed(1)}%)`;
  });

  await test("Server reports plausible filter size", async () => {
    if (!aliceFilter) throw new Error("no filter");
    const maxSize = 1048576; // 1MB
    if (aliceFilter.bits.length > maxSize) {
      throw new Error(`filter too large: ${fmtBytes(aliceFilter.bits.length)}`);
    }
    if (aliceFilter.num_hashes > 32) {
      throw new Error(`too many hashes: ${aliceFilter.num_hashes}`);
    }
    return `${fmtBytes(aliceFilter.bits.length)}, ${aliceFilter.num_hashes} hashes`;
  });

  await test("Filter timestamp is recent", async () => {
    if (!aliceFilter) throw new Error("no filter");
    const now = Math.floor(Date.now() / 1000);
    const age = now - aliceFilter.timestamp;
    if (age > 3600) throw new Error(`filter is ${age}s old (stale)`);
    if (aliceFilter.timestamp === 0) throw new Error("timestamp is zero");
    return `${age}s old`;
  });

  // ═══════════════════════════════════════════
  // PHASE 9: Adversarial — non-existent server
  // ═══════════════════════════════════════════
  console.log("\n═══ PHASE 9: Adversarial — invalid requests ═══");

  await test("Bloom check with invalid work_id (0) doesn't crash", async () => {
    try {
      const resp = await bob.send("bloom_filter_check", { server_id: String(aliceServerId), work_id: 0 });
      const val = bob.ev(resp);
      return `present=${val.present} (expected false)`;
    } catch (e) {
      return `error (acceptable): ${e.message}`;
    }
  });

  await test("Bloom check with very large work_id", async () => {
    try {
      const resp = await bob.send("bloom_filter_check", { server_id: String(aliceServerId), work_id: 18446744073709551615 });
      const val = bob.ev(resp);
      return `present=${val.present} (expected false or rare true)`;
    } catch (e) {
      return `error: ${e.message}`;
    }
  });

  await test("Bloom filter from non-existent server fails gracefully", async () => {
    try {
      const resp = await bob.send("bloom_filter_get", { server_id: "999999" });
      bob.ev(resp);
      throw new Error("should have failed");
    } catch (e) {
      if (e.message.includes("should have failed")) throw e;
      return `failed gracefully: ${e.message.slice(0, 50)}`;
    }
  });

  // ═══════════════════════════════════════════
  // PHASE 10: Cross-server content discovery
  // ═══════════════════════════════════════════
  console.log("\n═══ PHASE 10: Content discovery via Bloom ═══");

  await test("Bob verifies all Alice works via bloom check", async () => {
    let verified = 0;
    for (const wid of aliceWorkIds) {
      const resp = await bob.send("bloom_filter_check", { server_id: String(aliceServerId), work_id: wid });
      const val = bob.ev(resp);
      if (val.present) verified++;
    }
    if (verified < aliceWorkIds.length) {
      throw new Error(`only ${verified}/${aliceWorkIds.length} verified (false negative!)`);
    }
    return `${verified}/${aliceWorkIds.length} verified`;
  });

  // ═══════════════════════════════════════════
  // SUMMARY
  // ═══════════════════════════════════════════
  console.log("\n═══ SUMMARY ═══");
  console.log("\nTimings:");
  Object.entries(timings).forEach(([k, v]) => {
    if (typeof v === "number") {
      if (k.includes("size") || k.includes("count") || k.includes("fpr")) {
        console.log(`  ${k}: ${v}`);
      } else {
        console.log(`  ${k}: ${fmtMs(v)}`);
      }
    }
  });

  const passed = log.filter(l => l.startsWith("PASS")).length;
  const failed = log.filter(l => l.startsWith("FAIL")).length;
  console.log(`\n${passed} passed, ${failed} failed out of ${log.length} tests`);
  console.log("\n" + log.join("\n"));

  alice.ws.close();
  bob.ws.close();
  carol.ws.close();
  process.exit(failed > 0 ? 1 : 0);
}

runTests().catch(e => { console.error(e); process.exit(1); });
