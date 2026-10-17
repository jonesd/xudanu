// Video environment prep — builds the demo corpus for the Xudanu
// video (VIDEO-SCRIPT.md) over the production wire ops.
//
// Creates ONLY "QA-VIDEO-*" titled works (archivable with --reset).
// Robin's identity + paragraphs are authored properly (authenticated
// session) so attribution bands read as a second person.
//
// Usage:
//   node scripts/video-prep.mjs            # build the scene
//   node scripts/video-prep.mjs --reset    # archive previous scene works
//
// On-camera checklist after running (the parts that must be live):
//   1. Window A (you) + Window B (incognito, login as Robin / password below)
//   2. You type a paragraph in The Garden Essay → your colour
//   3. Robin types a paragraph → blue bands live in both windows
//   4. Gather→Place a transclusion of Robin's paragraph into Reading Notes
//   5. Paste-as-transclusion from Garden Essay → Reading Notes
//   6. The stacked links (Reference + Disagreement) are already on
//      "persistent address" in the Garden Essay — hover, ⌘-click through

import WebSocket from "ws";

const args = process.argv.slice(2);
const HOST = "127.0.0.1:8080";
const ORIGIN = `http://${HOST}`;
const STAMP = Date.now().toString(36);
const ROBIN_PASSWORD = "robin-demo-pass-1";

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

class Session {
  constructor(name) { this.name = name; this.id = 0; }
  async connect() {
    const tok = await fetch(`http://${HOST}/csrf-token`).then((r) => r.json()).then((d) => d.csrf_token);
    this.ws = new WebSocket(`ws://${HOST}/xudanu?format=json&login=public&csrf_token=${tok}`, {
      headers: { Origin: ORIGIN },
    });
    await new Promise((res, rej) => { this.ws.on("open", res); this.ws.on("error", rej); });
    await this.call("session_connect", {}).catch(() => {});
    return this;
  }
  async loginAs(name, password) {
    const pw = Array.from(new TextEncoder().encode(password));
    await this.call("club_create_personal", { display_name: name, password: pw }).catch((e) => {
      if (!String(e).includes("exist")) throw e; // idempotent
    });
    await this.call("session_login_by_name", { club_name: name });
    await this.call("session_authenticate", { credential: { password: pw } });
    return this;
  }
  call(op, payload) {
    return new Promise((resolve, reject) => {
      const rid = ++this.id + 200;
      const on = (data) => {
        try {
          const m = JSON.parse(data.toString());
          if (m.id === rid || m.type === "error") {
            this.ws.off("message", on);
            m.type === "error" ? reject(new Error(m.message || "error")) : resolve(m.value?.value ?? m.value);
          }
        } catch {}
      };
      this.ws.on("message", on);
      this.ws.send(JSON.stringify({ v: 2, type: "request", id: rid, op, payload }));
      setTimeout(() => { this.ws.off("message", on); reject(new Error("timeout")); }, 8000);
    });
  }
  close() { try { this.ws.close(); } catch {} }
}

const GARDEN_TEXT = `The Garden Essay

A garden is not a photograph. It is a performance that repeats daily, and no two performances are the same.

The greenhouse kept the same plants for forty years, but the garden was never the same garden twice. What makes it hold together is not the plants — it is the paths. The paths decide what you will see, and in what order, and what you will see things beside.

Every path through a garden is an argument about the garden.

This is the sentence worth quoting: content with one home, visible in many places, is a garden and not a warehouse.`;

const NOTES_TEXT = `Reading Notes

Working notes on the garden essay. The placed quotation will appear below.

TODO-YOU: type your own paragraph here on camera (Window A).

TODO-ROBIN: Robin types here on camera (Window B).`;

async function buildScene() {
  // Robin authors the scene content (real second identity → real attribution)
  const robin = await new Session("robin").connect();
  try {
    await robin.loginAs("Robin", ROBIN_PASSWORD);
    console.log("✓ Robin identity ready (password below — needed for Window B login)");
  } catch (e) {
    console.log("! Robin login failed:", e.message, "— continuing as anonymous (attribution will not show a second author)");
  }

  const t = `QA-VIDEO-${STAMP}`;
  const mk = async (title, text, n) => {
    const wid = await robin.call("work_create", { edition: { text } });
    await robin.call("work_set_title", { work_id: wid, title: `${title} (${t})` });
    console.log(`✓ ${title} → 0x${wid.toString(16)}`);
    return wid;
  };

  // 1. The Garden Essay — with a few revisions so the timeline is rich
  const garden = await mk("The Garden Essay", GARDEN_TEXT);
  await sleep(200);
  await robin.call("work_set_text", { work_id: garden, text: GARDEN_TEXT + "\n\nA late addition: the gardener signs every change." });
  await sleep(200);
  await robin.call("work_set_text", { work_id: garden, text: GARDEN_TEXT + "\n\nA late addition: the gardener signs every change. Even this one." });

  // share it so both identities can edit live on camera
  const pub = await robin.call("club_id_by_name", { name: "public" });
  await robin.call("work_set_read_club", { work_id: garden, club_id: pub });
  await robin.call("work_set_edit_club", { work_id: garden, club_id: pub });

  // 2. Reading Notes — the quoting document (transclusion lands here on camera)
  const notes = await mk("Reading Notes", NOTES_TEXT);
  await robin.call("work_set_read_club", { work_id: notes, club_id: pub });
  await robin.call("work_set_edit_club", { work_id: notes, club_id: pub });

  // 3. Third doc — receives the link; backlink appears here on camera
  const third = await mk("On Paths", `On Paths\n\nA short note about arguments disguised as walkways.\n\nReceives a link live on camera — watch the backlink arrive.`);
  await robin.call("work_set_read_club", { work_id: third, club_id: pub });

  // 4. Stacked links on the quotable sentence (Reference + Disagreement
  //    on one span — the ×2 stacked chooser, pre-made)
  const anchor = GARDEN_TEXT.indexOf("content with one home");
  const anchorEnd = anchor + "content with one home, visible in many places".length;
  const mkLink = async (dest, types) => {
    const lid = await robin.call("link_create", {
      origin: garden, destination: dest,
      origin_ref: { kind: "single", work_context: garden, original_context: null, path_context: null,
        excerpt: "content with one home, visible in many places", start_position: anchor, end_position: anchorEnd },
      destination_ref: { kind: "single", work_context: dest, original_context: null, path_context: null,
        excerpt: "", start_position: 0, end_position: 0 },
    });
    if (types?.length) await robin.call("link_set_types", { link_id: lid, link_types: types });
    console.log(`✓ link ${lid} (types ${types ?? []}) on the quotable sentence`);
  };
  await mkLink(third, [2]);      // Reference → On Paths
  await mkLink(notes, [3]);      // Disagreement → Reading Notes (stack on same span)

  // 5. One archived work so the shelf isn't empty
  const old = await mk("An Older Draft", "An older draft of the garden essay. Archived, not deleted — restore any time.");
  await robin.call("work_archive", { work_id: old });
  console.log("✓ one archived work on the shelf");

  console.log("\n─ scene ready ─");
  console.log(`  Garden Essay 0x${garden.toString(16)} · Reading Notes 0x${notes.toString(16)} · On Paths 0x${third.toString(16)}`);
  console.log(`  Window B (incognito): login as "Robin" / ${ROBIN_PASSWORD}`);
  console.log("  On camera: you type in Garden Essay, Robin types in Reading Notes,");
  console.log("  then Gather→Place Robin's paragraph, then paste-as-transclusion.");
  robin.close();
}

async function reset() {
  const s = await new Session("reset").connect();
  const list = await s.call("work_list", {});
  const entries = list?.entries ?? list ?? [];
  const mine = entries.filter((w) => (w.title || "").includes("QA-VIDEO-"));
  for (const w of mine) await s.call("work_archive", { work_id: w.work_id }).catch(() => {});
  console.log(`archived ${mine.length} previous scene works`);
  s.close();
}

if (args.includes("--reset")) {
  await reset();
} else {
  await buildScene();
}
process.exit(0);
