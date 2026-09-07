# The Five-Minute Demo

A script for showing Xudanu to a practice lead / technical
stakeholder. Assumption: you are not selling — you are asking
whether this rhymes with anything they hear from clients. The demo
does the talking.

Setup (before the meeting):

```sh
./scripts/demo-links-reset.sh        # fresh demo on :8081, ~30s
# plus: scripts/seed-compare-pair.mjs (essay/critique pair)
# plus: scripts/seed-revisions.mjs   (The Harbor Log, r0..r3)
open http://127.0.0.1:8081
```

Two browser windows side by side, both open. Warm everything up
once (links panel, provenance panel) so nothing loads cold.

---

## 0. The frame (20 seconds — say, don't show)

> "This is an open-source document system I build. Everything you're
> about to see is live — no slides. The one thing to hold onto:
> **every passage in every document carries a cryptographic
> signature of who wrote it, and quotations are references, not
> copies.** Watch for those two things."

## 1. Two people, one document (60 seconds)

- Both windows open the same work, click into the text
- Type in one window — watch it appear in the other in real time;
  the other person's cursor is visible
- Both type in the SAME paragraph simultaneously — text merges, no
> "Two authors, one document, no locking, no 'who has this checked
> out.' Under the hood every edit is attributed — we'll come back
> to that."

**Why this matters to them:** real-time collaboration is table
stakes they know; this says "modern" fast.

## 2. The quote that is not a copy (90 seconds — the differentiator)

- Window A: open "Black Swan — The Essay" (the seeded corpus)
- Window B: open "Black Swan — The Critique"
- In the critique, point at a quoted paragraph — hover shows it is
  a transclusion: included by reference
- **Edit the quoted sentence in the Essay** — watch the Critique
  update live
- Reverse: the connection panel shows the Disagreement link between
  thesis passages; click ⇄ to open the compare — verbatim shared
  passages struck grey, each work's own argument in green

> "That passage exists ONCE. The critique includes it by reference —
> when the source corrects itself, every quotation updates. Links
> between documents are typed and unbreakable: this one is a
> Disagreement, and the compare view shows exactly what the two
> documents share."

**Why this matters:** nobody's tool does this. Word copies; wikis
link loosely; this is reference with identity.

## 3. Who wrote what — the crypto (90 seconds — the claim)

- Open "The Harbor Log" in one window, turn on provenance colors:
  the document is underlined in author colors
- Hover any passage: author, verified state, timestamp
- Right panel → History tab → compare r0 → r3: every difference
  lists WITH its author and timestamp — point at one hunk:

> "This sentence was deleted in revision 3, by this key, at this
> time — that's an Ed25519 signature over the content's hash,
> verified against the text as it stands. Not track-changes:
> track-changes is forgeable. This is tamper-evident — the
> attribution log is hash-chained, and any retroactive edit breaks
> the chain."

If asked how strong: use the honest form — *"tamper-evident,
per-passage attribution; the server vouches for identity bindings;
timestamps are server-signed — external anchoring is on the
roadmap."* (Full claim-strength table: docs/dev/provenance-flow-and-claims.md)

## 4. The receipt (30 seconds — leave this as the hook)

- Notarize a range (or show the notarization JSON on screen)

> "Given any quote, the server issues a receipt proving that exact
> text existed in that document, at that state, at that time —
> verifiable by anyone with the public key, WITHOUT access to the
> document. Think audit citations, AI answers citing sources,
> regulatory submissions."

## 5. The hand-back (20 seconds)

> "That's the engine. What I don't know is the market — you're the
> ones who hear what clients ask for. Does any of this rhyme:
> proving authorship when it's disputed? AI-generated content
> governance? Citations that can be verified? If yes, I can package
> a pilot; if no, tell me why not — that's equally useful."

Then stop talking. Let them ask.

---

## If there is only ONE minute

Do section 2 (the live-updating quote) and the last 15 seconds of
section 3 (a hunk with an author). That's the whole story: content
that knows what it is, and who wrote it.

## Anticipated questions

- **"Is this a product?"** — "It's my open-source project; I'm
  exploring whether it solves client problems. Apache 2.0 — the
  firm can use it like any tool."
- **"Can it be tampered with?"** — "Retroactive edits are
  detectable (hash chain, signatures). A fully compromised server
  can re-mint identity bindings — that's the known boundary, and
  key receipts + external anchoring are the mitigations."
- **"Who else has this?"** — "Per-passage signatures over
  collaboratively edited text, traveling across documents — I
  haven't found it anywhere. Asset-level provenance exists (C2PA,
  Adobe's Content Credentials); span-level text is the gap."
- **"Does it scale / who runs it?"** — "Single binary, runs
  headless, Docker; 3,400 tests. Today it's a demo-grade
  deployment, not a hardened service — that's what a pilot would
  be for."
