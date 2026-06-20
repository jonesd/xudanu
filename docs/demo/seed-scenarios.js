// Drives a running xudanu server to seed real provenance scenarios and captures
// the actual attribution_query + provenance_ancestry responses for rendering.
//
//   node docs/demo/seed-scenarios.js [port]   (default 8090)
const PORT = process.argv[2] || "8090";
const V = 2;

class Client {
  constructor() { this.ws = null; this.id = 0; this.pending = new Map(); }
  connect(url) {
    return new Promise((res, rej) => {
      this.ws = new WebSocket(url);
      this.ws.addEventListener("open", () => res());
      this.ws.addEventListener("message", (e) => this.onMsg(e.data));
      this.ws.addEventListener("error", () => rej(new Error("ws error")));
    });
  }
  send(op, payload) {
    const id = ++this.id;
    return new Promise((res, rej) => {
      const frame = { v: V, type: "request", id, op };
      if (payload !== undefined) frame.payload = payload;
      this.pending.set(id, { res, rej });
      this.ws.send(JSON.stringify(frame));
      setTimeout(() => { if (this.pending.has(id)) { this.pending.delete(id); rej(new Error(op + " timeout")); } }, 10000);
    });
  }
  onMsg(d) {
    const t = typeof d === "string" ? d : new TextDecoder().decode(d);
    const f = JSON.parse(t);
    if (f.type === "response" || f.type === "error") {
      const h = this.pending.get(f.id);
      if (h) { this.pending.delete(f.id); f.type === "error" ? h.rej(new Error(f.message)) : h.res(f.value); }
    }
  }
  val(r) { return r && typeof r === "object" && "type" in r && "value" in r ? r.value : r; }
  close() { if (this.ws) this.ws.close(); }
}
const pw = (s) => Array.from(Buffer.from(s));
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function attrQuery(c, workId) {
  // retry a few times — attribution may lag CRDT materialization
  for (let i = 0; i < 8; i++) {
    const a = c.val(await c.send("attribution_query", { work_id: workId }));
    if (a && a.spans && a.spans.length) return a;
    await sleep(500);
  }
  return c.val(await c.send("attribution_query", { work_id: workId }));
}

async function ancestry(c, workId) {
  try { return c.val(await c.send("provenance_ancestry", { work_id: workId })); }
  catch (e) { return { chain: [] }; }
}

async function linkAndApply(c, originWorkId, destWorkId, excerpt) {
  const linkId = c.val(await c.send("link_create", {
    origin: originWorkId, destination: destWorkId,
    origin_ref: { kind: "single", work_context: originWorkId, excerpt },
    destination_ref: { kind: "single", work_context: destWorkId },
  }));
  try { await c.send("work_apply_transclusion_attribution", { link_id: linkId }); } catch (e) { console.log("  apply err:", e.message); }
  return linkId;
}

async function main() {
  const c = new Client();
  await c.connect(`ws://localhost:${PORT}/xudanu?format=json&version=2`);
  await c.send("session_connect");
  await c.send("session_login_public");
  const NAME = "demo", PASS = "demonstration1";
  const club = c.val(await c.send("club_create_personal", { display_name: NAME, password: pw(PASS) }));
  await c.send("session_login_by_name", { club_name: NAME });
  await c.send("session_authenticate", { credential: { password: pw(PASS) } });
  console.log("authenticated as", NAME, "club", club);
  const PUBLIC_CLUB = 1000;
  const makePublic = (id) => c.send("work_set_read_club", { work_id: id, club_id: PUBLIC_CLUB }).catch(() => {});

  const mk = async (name, disp, b, d, bib) => {
    try {
      return c.val(await c.send("historical_author_register", {
        name, display_name: disp, birth_year: b, death_year: d, external_ids: {}, source_bibliography: bib }));
    } catch (e) {
      const list = c.val(await c.send("historical_author_list")) || {};
      const arr = list.authors || list.entries || list || [];
      const found = arr.find((a) => a.name === name || a.display_name === name);
      if (found) return { be_id: found.be_id ?? found.id };
      throw e;
    }
  };

  const shelley = await mk("Mary Shelley", "Mary Shelley", 1797, 1851, "Frankenstein (1818)");
  const stoker = await mk("Bram Stoker", "Bram Stoker", 1847, 1912, "Dracula (1897)");
  console.log("authors:", shelley.be_id, stoker.be_id);

  const frankText = "I am by birth a Genevese, and my family is one of the most distinguished of that republic.";
  const dracText = "Left Munich at 8:35 P.M., on 1st May, arriving at Vienna early next morning.";

  const frank = c.val(await c.send("import_source_work", {
    author_id: shelley.be_id, title: "Frankenstein Ch.1", text: frankText + " My ancestors had been for many years counsellors and syndics.",
    edition_info: "1818", skip_prefix_lines: 0, skip_suffix_lines: 0 }));
  const drac = c.val(await c.send("import_source_work", {
    author_id: stoker.be_id, title: "Dracula Ch.1", text: dracText + " Buda-Pesth seems a wonderful place.",
    edition_info: "1897", skip_prefix_lines: 0, skip_suffix_lines: 0 }));
  console.log("sources: frank", frank.work_id, "drac", drac.work_id);

  const scenarios = [];

  // ---- Scenario 1: single source transclusion ----
  {
    const text = `On Origins\n\n${frankText}\n\nThis passage grounds the essay in Romantic tradition.\n`;
    const doc = c.val(await c.send("work_create", { edition: { text } }));
    await makePublic(doc);
    await linkAndApply(c, frank.work_id, doc, frankText);
    await sleep(1500);
    const a = await attrQuery(c, doc);
    const ch = await ancestry(c, doc);
    scenarios.push({ id: "s1", title: "1. Single source transclusion",
      blurb: "One passage transcluded from Frankenstein. Historical author Mary Shelley; derivation chain Frankenstein → this document.",
      docText: text, workId: doc, spans: a.spans || [], chain: ch.chain || [] });
    console.log("s1 spans:", (a.spans || []).length);
  }

  // ---- Scenario 2: mixed provenance ----
  {
    const text = `A Study in Sources\n\nI wrote this introduction myself.\n\n${frankText}\n\nAn interlude of my own commentary.\n\n${dracText}\n\nAnd my conclusion.\n`;
    const doc = c.val(await c.send("work_create", { edition: { text } }));
    await makePublic(doc);
    await linkAndApply(c, frank.work_id, doc, frankText);
    await linkAndApply(c, drac.work_id, doc, dracText);
    await sleep(1500);
    const a = await attrQuery(c, doc);
    const ch = await ancestry(c, doc);
    scenarios.push({ id: "s2", title: "2. Mixed provenance",
      blurb: "Author's own words interleaved with passages from Frankenstein and Dracula. Coverage is below 100% (own text carries no attribution).",
      docText: text, workId: doc, spans: a.spans || [], chain: ch.chain || [] });
    console.log("s2 spans:", (a.spans || []).length);
  }

  // ---- Scenario 3: multi-hop chain Frankenstein → Doc A → Doc B ----
  {
    const textA = `Notes A\n\n${frankText}\n\nMy notes on the passage.\n`;
    const docA = c.val(await c.send("work_create", { edition: { text: textA } }));
    await makePublic(docA);
    await linkAndApply(c, frank.work_id, docA, frankText);
    await sleep(1500);

    const textB = `Notes B\n\n${frankText}\n\nFurther borrowed into a second document.\n`;
    const docB = c.val(await c.send("work_create", { edition: { text: textB } }));
    await makePublic(docB);
    await linkAndApply(c, docA, docB, frankText); // chain hop through docA
    await sleep(1500);
    const a = await attrQuery(c, docB);
    const ch = await ancestry(c, docB);
    scenarios.push({ id: "s3", title: "3. Multi-hop derivation chain",
      blurb: "Frankenstein → Doc A → Doc B. The derivation chain should show two hops; Mary Shelley remains the original author.",
      docText: textB, workId: docB, spans: a.spans || [], chain: ch.chain || [] });
    console.log("s3 spans:", (a.spans || []).length, "chain:", (ch.chain || []).length);
  }

  c.close();
  const out = { generated: new Date().toISOString(), port: PORT, clubId: club, scenarios };
  require("fs").writeFileSync(__dirname + "/scenarios.json", JSON.stringify(out, null, 2));
  console.log("\nWROTE docs/demo/scenarios.json  (" + scenarios.length + " scenarios)");
  // quick console preview
  for (const s of scenarios) {
    console.log("\n=== " + s.title + " ===");
    console.log("  chain:", (s.chain || []).map((h) => (h.source_work_title || "work") + "(" + (h.source_author_name || "?") + ")").join(" -> ") || "(none)");
    for (const sp of s.spans) {
      const who = sp.author_display_name || sp.author_type || "?";
      console.log(`  [${sp.start}..${sp.end}] ${who} type=${sp.author_type} src=${sp.source_work_id} tby=${sp.transcluded_by_name || "-"} sig=${sp.signature_valid}`);
    }
  }
  process.exit(0);
}
main().catch((e) => { console.error(e); process.exit(1); });
