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
        if (frame.type === "error") {
          handler.reject(new Error(frame.message));
        } else {
          handler.resolve(frame.value);
        }
      }
    }
  }

  val(resp) {
    if (resp && typeof resp === 'object' && 'type' in resp && 'value' in resp) return resp.value;
    return resp;
  }
}

async function main() {
  const url = "ws://localhost:8080/xudanu?format=json&version=2";
  const c = new TestClient();
  await c.connect(url);
  console.log("Connected");

  const r1 = await c.sendRequest("session_connect");
  console.log("Session:", c.val(r1));

  await c.sendRequest("session_login_public");
  console.log("Public login");

  // Create a club for editing
  const club1 = c.val(await c.sendRequest("club_create", { description: { text: "Author One" } }));
  console.log("Club:", club1);

  await c.sendRequest("club_set_password", { club_id: club1, password: Array.from(Buffer.from("password1")) });
  await c.sendRequest("session_login", { club_id: club1 });
  await c.sendRequest("session_authenticate", { credential: { password: Array.from(Buffer.from("password1")) } });
  console.log("Authenticated");

  // Register 3 historical authors
  const a1 = c.val(await c.sendRequest("historical_author_register", {
    name: "Mary Shelley", display_name: "Mary Shelley",
    birth_year: 1797, death_year: 1851,
    external_ids: {}, source_bibliography: "Frankenstein (1818)",
  }));
  console.log("Author Mary Shelley:", a1.be_id);

  const a2 = c.val(await c.sendRequest("historical_author_register", {
    name: "Bram Stoker", display_name: "Bram Stoker",
    birth_year: 1847, death_year: 1912,
    external_ids: {}, source_bibliography: "Dracula (1897)",
  }));
  console.log("Author Bram Stoker:", a2.be_id);

  const a3 = c.val(await c.sendRequest("historical_author_register", {
    name: "Jane Austen", display_name: "Jane Austen",
    birth_year: 1775, death_year: 1817,
    external_ids: {}, source_bibliography: "Pride and Prejudice (1813)",
  }));
  console.log("Author Jane Austen:", a3.be_id);

  // Import 3 source works
  const s1 = c.val(await c.sendRequest("import_source_work", {
    author_id: a1.be_id, title: "Frankenstein Ch.1",
    text: "I am by birth a Genevese, and my family is one of the most distinguished of that republic. My ancestors had been for many years counsellors and syndics, and my father had filled several public situations with honour and reputation. He was respected by all who knew him for his integrity and indefatigable attention to public business.",
    edition_info: "1818 edition", skip_prefix_lines: 0, skip_suffix_lines: 0,
  }));
  console.log("Source Frankenstein:", s1.work_id);

  const s2 = c.val(await c.sendRequest("import_source_work", {
    author_id: a2.be_id, title: "Dracula Ch.1",
    text: "Left Munich at 8:35 P.M., on 1st May, arriving at Vienna early next morning; should have arrived at 6:46, but train was an hour late. Buda-Pesth seems a wonderful place, from the glimpse I got of it from the train and the little I could walk through the streets.",
    edition_info: "1897 edition", skip_prefix_lines: 0, skip_suffix_lines: 0,
  }));
  console.log("Source Dracula:", s2.work_id);

  const s3 = c.val(await c.sendRequest("import_source_work", {
    author_id: a3.be_id, title: "Pride and Prejudice Ch.1",
    text: "It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife. However little known the feelings or views of such a man may be on his first entering a neighbourhood, this truth is so well fixed in the minds of the surrounding families.",
    edition_info: "1813 edition", skip_prefix_lines: 0, skip_suffix_lines: 0,
  }));
  console.log("Source P&P:", s3.work_id);

  // Create main composite document
  const doc = c.val(await c.sendRequest("work_create", {
    edition: { text: "A Study in Literary Sources\n\nThis document draws from multiple literary works.\n\nSection 1: The Creature's Origin\n\nI am by birth a Genevese, and my family is one of the most distinguished of that republic.\n\nSection 2: The Journey East\n\nLeft Munich at 8:35 P.M., on 1st May, arriving at Vienna early next morning.\n\nSection 3: Universal Truths\n\nIt is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.\n\nThese passages illustrate Gothic and Romantic literary traditions.\n" },
  }));
  console.log("\n=== Main doc:", doc, "(0x" + doc.toString(16).padStart(4, "0") + ") ===");

  // Apply source attribution for each section
  // The document text has known offsets. Let's compute them.
  const fullText = "A Study in Literary Sources\n\nThis document draws from multiple literary works.\n\nSection 1: The Creature's Origin\n\nI am by birth a Genevese, and my family is one of the most distinguished of that republic.\n\nSection 2: The Journey East\n\nLeft Munich at 8:35 P.M., on 1st May, arriving at Vienna early next morning.\n\nSection 3: Universal Truths\n\nIt is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.\n\nThese passages illustrate Gothic and Romantic literary traditions.\n";

  // Find offsets for each pasted section
  const frankStart = fullText.indexOf("I am by birth a Genevese");
  const frankEnd = fullText.indexOf("republic.") + "republic.".length;
  const dracStart = fullText.indexOf("Left Munich at 8:35");
  const dracEnd = fullText.indexOf("morning.") + "morning.".length;
  const prideStart = fullText.indexOf("It is a truth universally");
  const prideEnd = fullText.indexOf("wife.") + "wife.".length;

  console.log("Frankenstein range:", frankStart, "-", frankEnd);
  console.log("Dracula range:", dracStart, "-", dracEnd);
  console.log("P&P range:", prideStart, "-", prideEnd);

  try {
    await c.sendRequest("work_apply_source_attribution", {
      work_id: doc, historical_author_id: a1.be_id, source_work_id: s1.work_id,
      paste_start: frankStart, paste_end: frankEnd,
    });
    console.log("Applied Frankenstein attribution");
  } catch (e) { console.log("Attr 1:", e.message); }

  try {
    await c.sendRequest("work_apply_source_attribution", {
      work_id: doc, historical_author_id: a2.be_id, source_work_id: s2.work_id,
      paste_start: dracStart, paste_end: dracEnd,
    });
    console.log("Applied Dracula attribution");
  } catch (e) { console.log("Attr 2:", e.message); }

  try {
    await c.sendRequest("work_apply_source_attribution", {
      work_id: doc, historical_author_id: a3.be_id, source_work_id: s3.work_id,
      paste_start: prideStart, paste_end: prideEnd,
    });
    console.log("Applied P&P attribution");
  } catch (e) { console.log("Attr 3:", e.message); }

  console.log("\n=== DONE ===");
  console.log("Open doc 0x" + doc.toString(16).padStart(4, "0") + " in the browser");
  console.log("Click 'Editing' button to switch to Reading view");
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
