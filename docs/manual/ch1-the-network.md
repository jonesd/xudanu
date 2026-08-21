# The Xudanu Network Manual — Chapter 1: Your Server and the Network

*The start of a comprehensive user manual. This chapter covers how a
user first encounters the network: what a server is, what the
network can see of you, how to search across servers, how to read
and bring in remote content, and — throughout — what is safe, what
is risky, and how the system protects you. Written 2026-08-21;
matches FR-41 S1/S2-era software.*

---

## 1. What you're standing on: one server in a network

When you use Xudanu, you're always using **one server** — yours.
Maybe you run it (a laptop process, a VPS at `xudanu.com`), maybe
an organization runs it for you. Everything you write lives there,
encrypted at rest if the operator enabled it, backed up by them.

Your server is **sovereign**: its document store, its user accounts,
its cryptographic identity (an Ed25519 keypair — its "face" to the
network). No other server can write to it. Federation means your
server *talks* to other servers; it never means they get admin
powers over you.

The **network** is simply: other people's Xudanu servers, which
yours can discover, be introduced to, and — if an administrator
decides to — **trust**.

**Safety fact #1:** nothing you write is visible to other servers
unless it is (a) explicitly **published** (public read), or (b)
explicitly sent (a link pointing at a remote work notifies that
remote server). Private drafts are private, full stop.

---

## 2. The directory: who your server knows

Open the **Servers** tab. That's the **directory**: the list of
servers yours knows about. Each card shows:

- **Name & address** — e.g. `Node 2 (Bob) · 127.0.0.1:8090`
- **Trust state** — the single most important field:
  - **Trusted** (🟢): participates in network search; its identity
    key is pinned (recorded when it was added — key changes are
    *visible events*, a strong sign of compromise or re-provisioning)
  - **Untrusted**: known but not asked anything. Results from it
    are never auto-fetched.
  - **Quarantined** (⚠️): it misbehaved (bad signatures, hostile
    payloads) and the system fenced it off until an admin
    intervenes.
- **Resolves / last seen** — operational history.

**Who can change trust?** Administrators, deliberately. Not you,
not the remote server. Adding a server records its identity key
from its `/.well-known/xudanu-server.json` — the network equivalent
of TOFU (trust-on-first-use) with later verification.

**Discover** asks your trusted servers who *they* know — you get
candidates to review, nothing is auto-trusted. This is how the
network grows: friend-of-friend introductions, human decisions.

**Safety fact #2:** network search only ever queries trusted,
non-quarantined servers. A stranger cannot get your server to make
requests to arbitrary targets by existing; being *asked* requires
an admin to have said yes first.

---

## 3. Reading across the network

### Network search

The search overlay has three scopes: **All works** (yours), **This
document**, and **⌾ The network**. The network scope sends your
query to your server, which:

1. searches its own public works,
2. asks every trusted peer in parallel (3-second timeout each, an
   overall budget — a dead server slows you a little, never a lot),
3. merges and returns results tagged with origin.

Each result carries a badge — **this server** (green) or the
origin's name (colored per server). The summary line is honest
about failures: *"1 server didn't answer: Node 4"*.

**Safety fact #3:** remote titles are truncated and always rendered
as plain text; a hostile server cannot flood your results (20 per
peer cap) or inject scripts into your UI. And search is
rate-limited (10/min) so no one session can use your server to
hammer peers.

### The Remote view

Clicking a remote result opens the **Remote view** — an amber-badged,
read-only window onto the other server's document, fetched live
from *its* public API. The footer shows its **tumbler** (global
address, e.g. `"127.0.0.1".03ec`) and work id. Reading commits you
to nothing.

**What the Remote view proves:** the passage you're reading came
from that server, over TLS, with its content hash. What it doesn't
prove: that the *author* wrote it — for that, check provenance
(higher-tier works carry signed span provenance; look for the
verification badge).

**Safety fact #4:** reading remote content cannot modify anything
on your server. The fetch goes out, bytes come back, they render as
text. That's the whole interaction.

---

## 4. Bringing remote content in: the three doors

This is where users most often get confused, so here is the
complete map. Every button that moves content between servers is
one of exactly three things:

### Door 1 — LINK (pointer, no content)

**Where:** LinkCreator → "Link to a remote server", or the "Link to
this work" button in the Remote view.

A link records a typed, bidirectional connection between a passage
of *your* work and the remote work. No text is copied. Both sides'
Connections panels show it (the remote server is notified and holds
a receipt). Types (Comment, Reference, Disagreement, Quotation, See
Also — or community-defined types) say what the connection *means*.

- Use when: citing, referencing, arguing, "see also".
- Tracks the original? No — it's a pointer; the far side may move
  or vanish (then: "unreachable", visible, reversible).
- Safety: the notification reveals to the remote server that your
  server linked them (that's inherent — backlinks are the point).
  If your document is private, only the *link's existence toward
  their work* is communicated, with your server's name. Not the
  document's contents.

### Door 2 — COPY (import; content becomes yours)

**Where:** "Copy to my server" (whole document) or "Insert selected
text" (passage into your current document), both in the Remote view.

Bytes are duplicated onto your server with a provenance note. From
then on it is your text: your edits, your license responsibility
(check the source's license badge — ARR means all rights reserved;
the guide will show the compliance marker), no tracking.

- Use when: you need independence from the source server, you'll
  rewrite heavily, or licensing requires a local copy.
- Safety: you imported it — you're now responsible for what it says
  under your flag. A malicious server can feed you text (that's
  inherent to copying); it renders as text, can't execute, but
  *you* vouch for it by republishing it.

### Door 3 — TRANSCLUDE (by reference; content stays theirs)

**Where:** the Transclude buttons in the Remote view (selected-span
capture is S2, landing now).

Your document records an address — *that span, of that work, on
that server* — and displays the content, live or pinned:

- **Live**: tracks the source's current revision. Author edits, your
  document reflects it. The scholarly-honest quotation.
- **Pinned**: frozen at the revision you quoted (FR-37 virtual
  transclusion). "What it said when I quoted it" is durable and
  hash-verified — the critique-proof citation.

Only the pointer travels to your server (tiny: tumbler, span,
BLAKE3 hash). The content's home stays singular — that's the
Xanadu principle: **no duplication**.

- Use when: quoting into a living conversation; when royalties
  (Transcopyright) matter — the reference is the accounting record.
- Safety: your document *displays* their content. If their server
  turns hostile and rewrites the passage, a live transclusion shows
  the rewrite (that's the contract!) — but the hash chain proves
  what changed, and pinned transclusions are immune. If their
  server vanishes, cached content shows, marked stale.

---

## 5. Which door? — the decision procedure

Ask, in order:

1. **Do I need their words in my document?**
   - No → **Link**. Done.
2. **Must it keep tracking their original?**
   - Yes → **Transclude** (pinned if the quote must never move).
   - No → 3
3. **Do I need it to survive their server disappearing / will I
   rewrite it / does the license require a local copy?**
   - Yes → **Copy**
   - No → **Link** usually suffices; reconsider.

---

## 6. Safety summary — the honest threat model

**The system protects you from:**
- Malicious servers injecting code (plain-text rendering, CSP, no
  HTML execution path for remote content)
- Result flooding and oversized payloads (caps and truncation)
- Being used as an attack proxy (trusted-only fan-out, SSRF guards,
  rate limits, bounded timeouts)
- Silent tampering (BLAKE3 content hashes on every cross-server
  reference; signed identity keys pinned per server; tamper-evident
  security logs on your server)
- Traffic interception (TLS with system roots; redirect-following
  restricted to same-host)

**The system cannot protect you from:**
- A trusted server serving **false content** (it can lie about
  facts; hash-verification proves *it* said that, not that it's
  true). Mitigation: provenance shows *who* claims what.
- Your administrator trusting badly (trust is a human decision;
  the directory makes its consequences visible).
- Content you **copy** being wrong (once copied, it's yours).
- The existence of a link being visible to its target (bidirectional
  links are the design; anonymous citation isn't offered).
- A live transclusion showing the author's *current* text, even if
  it changed since you read it (use **pinned** when you need
  stability).

**Good habits:**
- Prefer links until you're sure you need more.
- Check the license badge before copying (ARR content shouldn't be
  republished).
- Pin quotations you critique; live-quote only when currency is
  the point.
- Watch trust states; treat key-change events on pinned servers
  with suspicion.
- If a result looks too good, open it in the Remote view and check
  provenance before importing.

---

## 7. Coming in this manual (roadmap)

- Ch. 2 — Publishing: what "public" means, licenses, Transcopyright
- Ch. 3 — Transclusion deep dive: placement, live vs pinned, the
  money question (royalties)
- Ch. 4 — Links: types, communities defining their own, comparison
  view for multi-ended links
- Ch. 5 — Running your own server: setup, keys, backups, TLS
- Ch. 6 — For administrators: the directory, trust decisions,
  quarantine, the security log

*Source of truth for behavior: the software. When this manual and
the software disagree, file a bug — either the doc or the code is
wrong, and both are ours.*
