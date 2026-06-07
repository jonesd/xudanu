const PROTOCOL_VERSION = 2;

class TestClient {
  constructor() {
    this.ws = null;
    this.requestId = 0;
    this.pending = new Map();
  }

  connect(url) {
    return new Promise((resolve, reject) => {
      this.ws = new WebSocket(url);
      this.ws.addEventListener('open', () => resolve());
      this.ws.addEventListener('message', (ev) => this.onMessage(ev.data));
      this.ws.addEventListener('error', () => reject(new Error('WebSocket error')));
    });
  }

  async sendRequest(op, payload) {
    const id = ++this.requestId;
    return new Promise((resolve, reject) => {
      const frame = { v: PROTOCOL_VERSION, type: "request", id, op };
      if (payload !== undefined) frame.payload = payload;
      this.pending.set(id, { resolve, reject });
      this.ws.send(JSON.stringify(frame));
      setTimeout(() => { if (this.pending.has(id)) { this.pending.delete(id); reject(new Error(`${op} timed out`)); } }, 10000);
    });
  }

  onMessage(data) {
    const text = typeof data === 'string' ? data : new TextDecoder().decode(data);
    const frame = JSON.parse(text);
    if (frame.type === "response" || frame.type === "error") {
      const handler = this.pending.get(frame.id);
      if (handler) {
        this.pending.delete(frame.id);
        if (frame.type === "error") handler.reject(new Error(frame.message));
        else handler.resolve(frame.value);
      }
    }
  }

  val(resp) {
    if (resp && typeof resp === 'object' && 'type' in resp && 'value' in resp) return resp.value;
    return resp;
  }

  disconnect() { if (this.ws) this.ws.close(); }
}

async function main() {
  const url = "ws://localhost:8080/xudanu?format=json&version=2";
  const c = new TestClient();
  await c.connect(url);
  console.log("Connected");

  await c.sendRequest("session_connect");
  await c.sendRequest("session_login_public");

  const club1 = c.val(await c.sendRequest("club_create", { description: { text: "Test Author" } }));
  await c.sendRequest("club_set_password", { club_id: club1, password: Array.from(Buffer.from("password1")) });
  await c.sendRequest("session_login", { club_id: club1 });
  await c.sendRequest("session_authenticate", { credential: { password: Array.from(Buffer.from("password1")) } });
  console.log("Authenticated as club", club1);

  // Find source works by listing all works
  const worksRaw = c.val(await c.sendRequest("work_list", {}));
  const worksList = worksRaw?.entries || [];
  console.log("Works:", worksList.length, "total");
  if (worksList.length > 0) console.log("Sample work keys:", Object.keys(worksList[0]));
  const sourceWorks = worksList.filter(w => w.is_source);
  console.log("Source works:", sourceWorks.map(w => "0x" + w.work_id.toString(16).padStart(4, "0") + " " + w.title).join(", "));

  if (sourceWorks.length < 3) {
    console.log("Need 3 source works, only found", sourceWorks.length);
    process.exit(1);
  }

  const s1 = sourceWorks.find(w => w.work_id === 0x03ed);
  const s2 = sourceWorks.find(w => w.work_id === 0x03ee);
  const s3 = sourceWorks.find(w => w.work_id === 0x03ef);
  console.log("s1:", "0x"+s1.work_id.toString(16).padStart(4,"0"));
  console.log("s2:", "0x"+s2.work_id.toString(16).padStart(4,"0"));
  console.log("s3:", "0x"+s3.work_id.toString(16).padStart(4,"0"));

  // Create composite document with transcluded text
  const docText = "A Study in Literary Sources\n\n" +
    "I am by birth a Genevese, and my family is one of the most distinguished of that republic.\n\n" +
    "Left Munich at 8:35 P.M., on 1st May, arriving at Vienna early next morning.\n\n" +
    "It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.\n\n" +
    "These passages illustrate Gothic and Romantic literary traditions.\n";

  const doc = c.val(await c.sendRequest("work_create", { edition: { text: docText } }));
  const docHex = "0x" + doc.toString(16).padStart(4, "0");
  console.log("\n=== Created doc:", doc, docHex, "===");

  // Create transclusion links
  const frankExcerpt = "I am by birth a Genevese, and my family is one of the most distinguished of that republic.";
  const dracExcerpt = "Left Munich at 8:35 P.M., on 1st May, arriving at Vienna early next morning.";
  const prideExcerpt = "It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.";

  const link1 = c.val(await c.sendRequest("link_create", {
    origin: s1.work_id, destination: doc,
    origin_ref: { kind: "single", work_context: s1.work_id, excerpt: frankExcerpt },
    destination_ref: { kind: "single", work_context: doc },
  }));
  console.log("Link 1 (Frankenstein → doc):", link1);

  const link2 = c.val(await c.sendRequest("link_create", {
    origin: s2.work_id, destination: doc,
    origin_ref: { kind: "single", work_context: s2.work_id, excerpt: dracExcerpt },
    destination_ref: { kind: "single", work_context: doc },
  }));
  console.log("Link 2 (Dracula → doc):", link2);

  const link3 = c.val(await c.sendRequest("link_create", {
    origin: s3.work_id, destination: doc,
    origin_ref: { kind: "single", work_context: s3.work_id, excerpt: prideExcerpt },
    destination_ref: { kind: "single", work_context: doc },
  }));
  console.log("Link 3 (P&P → doc):", link3);

  // Apply attribution for each link
  try {
    await c.sendRequest("work_apply_transclusion_attribution", { link_id: link1 });
    console.log("Attribution 1 applied (Frankenstein)");
  } catch (e) { console.log("Attr 1 error:", e.message); }

  try {
    await c.sendRequest("work_apply_transclusion_attribution", { link_id: link2 });
    console.log("Attribution 2 applied (Dracula)");
  } catch (e) { console.log("Attr 2 error:", e.message); }

  try {
    await c.sendRequest("work_apply_transclusion_attribution", { link_id: link3 });
    console.log("Attribution 3 applied (P&P)");
  } catch (e) { console.log("Attr 3 error:", e.message); }

  // Wait for checkpoint
  await new Promise(r => setTimeout(r, 2000));

  // Query attribution
  const attr = c.val(await c.sendRequest("attribution_query", { work_id: doc }));
  console.log("\n=== Attribution spans:", attr?.spans?.length || 0, "===");
  if (attr?.spans) {
    for (const s of attr.spans) {
      const author = s.author_display_name || "unknown";
      const type = s.author_type || "?";
      const sw = s.source_work_id ? "from 0x" + s.source_work_id.toString(16).padStart(4, "0") : "";
      const textExcerpt = docText.substring(s.start, s.end);
      console.log(`  [${s.start}-${s.end}] ${author} (${type}) ${sw} "${textExcerpt.substring(0, 50)}..."`);
    }
  }

  // List links
  const links = c.val(await c.sendRequest("link_list_for_work", { work_id: doc }));
  const linkEntries = links?.entries || links?.links || [];
  console.log("\n=== Links:", linkEntries.length, "===");
  for (const l of linkEntries) {
    const dir = l.origin === doc ? "outgoing" : "incoming";
    const other = l.origin === doc ? l.destination : l.origin;
    const excerpt = l.origin_ref?.excerpt || l.destination_ref?.excerpt || "";
    console.log(`  link ${l.link_id} ${dir} 0x${other.toString(16).padStart(4,"0")} "${excerpt.substring(0, 40)}..."`);
  }

  console.log("\n=== DONE ===");
  console.log("Open http://localhost:5173/?work=" + docHex);
  console.log("Login: test-author / password1");
  c.disconnect();
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
