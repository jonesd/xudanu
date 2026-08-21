# Working Across Servers — a plain guide

*For you, and eventually, for users. This explains what each network
button actually does, and which one you want when.*

Last updated: 2026-08-21 · matches the FR-41 S1/S2 UI

---

## The idea in one paragraph

Your Xudanu server (Node 1) is one member of a network of
independent servers. You can **search** every server your
administrator trusts, **read** documents that live on other servers,
and bring other people's writing into your own documents in two
fundamentally different ways: **copying** it (it becomes yours, and
stops tracking the original) or **transcluding** it (it stays
theirs — your document merely *points* at it, and if they edit
their original, your document reflects that). Knowing which of
those two you want is 90% of this guide.

---

## The three ways content can relate to another server

| | **Link** | **Copy (import)** | **Transclude (by reference)** |
|---|---|---|---|
| What travels to your server | A pointer (tumbler + content hash) | The actual text bytes | A pointer + span (chars 12–58 of *that* work) |
| Your document shows… | a clickable connection | the text, permanently | their text, live |
| If they edit the original | nothing changes for you | nothing changes for you | **your document updates** (or flags "source changed") |
| Attribution | recorded on the link | header note in the copy | cryptographically structural (hash + their key) |
| If their server disappears | link shows "unreachable" | **you still have the text** | passage shows frozen/cached version |
| Web analogy | a hyperlink | copy-paste | *nothing on the web does this* |

**Rule of thumb:**
- Citing / pointing / arguing → **link**
- You need it to survive on its own → **copy**
- Quoting while staying honest to a living original → **transclude**

---

## Where the buttons live, and what each really does

### 1. Search overlay (magnifier icon) — "⌾ The network" tab

Type a query, pick **The network**, press Enter.

- Your server searches **its own** public works *and* asks every
  **trusted** server in the directory. (Trust matters: untrusted or
  quarantined servers are never asked — that's an abuse guard, not
  an accident.)
- Results are merged. Each shows a colored badge: **"this server"**
  (green) or the origin server's name (e.g. **"Node 2 (Bob)"**).
  The badge is provenance: that result does not exist on your
  server; it was answered live by the other one.
- The line under the header tells you honestly if any server didn't
  answer ("1 server didn't answer: Node 4") rather than hiding it.
- **Clicking a local result** → opens that work normally.
- **Clicking a remote result** → opens the **Remote view** (below).
- Rate limit: 10 network searches a minute per session (fan-outs
  cost every peer real work).

### 2. Remote view (the amber "REMOTE · From Node 2 (Bob)" screen)

This is a *read-only window onto the other server's document*,
fetched live from its public API. Footer shows its **tumbler**
(global address, e.g. `"127.0.0.1".03ec`) and work ID.

Buttons in the top bar:

- **Back / close** — just closes the view. Nothing was changed.
- **Insert selected text** — copy-path. Whatever you selected in
  the document body gets pasted into **your currently open
  document** at the cursor, with a citation line (`> — From
  "…" via Node 2 (tumbler)`). The text is now yours; it will not
  track the original.
- **Copy to my server** — copy-path, whole document. Creates a
  **new work on your server** containing a provenance header
  ("> Imported from … / Tumbler: … / License: …") followed by the
  full text, then opens it. It is *your* document now — editing it
  edits your copy, never theirs.
- **Link to this work** — records a typed **link** (two-ended,
  bidirectional) between your open document and the remote work.
  Both documents will show the connection in their Connections
  panels. No text moves.
- **Transclude live / pinned** *(the S2 work in progress)* — the
  by-reference path for **selected text**: your document will
  display that exact span of *their* document. "Live" tracks the
  current revision; "pinned" freezes the revision you quoted
  (quoting revision 2 is itself a permanent fact). Currently
  functional for the whole remote document; selected-span capture
  is what we're building next.

### 3. Servers tab (right panel)

The directory of known servers, one card each:

- 🟢 **trusted** / ⚠️ **quarantined** status — trust is set by an
  admin; only trusted servers participate in network search.
- **Discover** — asks your trusted servers "who do you know?" and
  lists servers *they* vouch for, for an admin to review and add.
- **↻ Refresh** — re-reads the directory and each server's identity.
- **Browse** — lists the remote server's *public* works. Clicking a
  work opens the same Remote view as search results.
- The **search box** on this tab runs the same network fan-out as
  the main search's network scope; results here are clickable to
  the Remote view too.

### 4. LinkCreator → "Link to a remote server"

Creates a **link** whose far end is on another server: you give the
server address and work id (or paste a `tumbler|hash` reference
someone shared with you), and optionally Fetch to auto-fill the
tumbler and BLAKE3 content hash from the origin's public API. The
link's Connections entry will show whether the origin server
**acknowledged** the link (✓ remote server acknowledged) or
rejected/unreachable, with the reason.

---

## Which one do I want? (the decision, in scenarios)

**"I'm writing about Bob's experiment and want to cite it."**
→ Link (Comment or Reference type). Readers click through to his
document on his server. Nothing to maintain.

**"I'm quoting one paragraph of Bob's, and if he revises it, my
essay must stay honest to what he *now* says."**
→ Transclude that span. This is the scholarly-quotation use the
whole system exists for. (If you instead need it to never change —
quote-stability for a critique — use **pinned** transclusion, or
copy.)

**"Bob's server is flaky / the text is under a license requiring a
local copy / I'm going to rewrite most of it."**
→ Copy to my server. You keep the text regardless of his server,
and you're free to edit.

**"I just want to find things across the whole network."**
→ Network search, then click through and read. Reading costs
nothing and commits you to nothing.

**"Someone sent me a `tumbler|hash` string."**
→ LinkCreator → Paste cross-server reference. It resolves to their
server; the hash lets the system verify the content hasn't been
tampered with.

---

## Trust and safety, briefly

- Network search only ever asks **trusted** servers. Trust is an
  admin decision, informed by each server's pinned Ed25519 identity
  key (recorded when it was added to the directory).
- Remote content is always rendered as **plain text** — a malicious
  server cannot inject scripts into your view. Titles are
  truncated; result floods are capped; slow servers time out
  without stalling your search.
- Links to remote works record the origin's answer. If a remote
  server later vanishes, links degrade to "unreachable" — visible,
  not silent.

---

## Terminology card

- **Server / node** — an independent Xudanu instance with its own
  works, users, and keys.
- **Directory** — your server's list of known peers, each with a
  trust level.
- **Tumbler** — a global address like `"alice.com".03ec` (server +
  work). survives everything; it's the thing links and
  transclusions point at.
- **BLAKE3 hash** — a content fingerprint. Lets anyone verify the
  passage you quoted is byte-identical to the original.
- **Provenance** — who wrote what, signed. Cross-server, it's how
  you know a passage is really Bob's even though you're reading it
  on your server.
- **Transclusion** — including content *by reference*. The passage
  lives once, on its home server; your document displays it.
- **Pinned transclusion** — a transclusion frozen to the revision
  it quoted. "What did it say when I quoted it" is itself durable.
