# Xudanu demo video — narration script & production checklist

Target: 3 minutes. Product name is always **Xudanu**. "Xanadu" appears
only as history (the 1999 open-sourced Udanax Gold lineage). "xanalogical"
(lowercase, adjective) for the concept. Mute-friendly: every narration
line also appears as an on-screen caption.

---

## The script

### 0:00–0:15 — COLD OPEN (the money shot, before any branding)

**On screen:** two windows side by side — left: a source essay; right: a
document quoting it. Type one word in the source; the quotation in the
right window updates instantly; attribution bands (paired colours) show
who wrote what.

**Narration / caption:**
> "This document is quoting that one — live."

> "Let's build up to how."

### 0:15–0:45 — THE EDITOR

**On screen:** a fresh document. Type a sentence. Apply a heading. Type a
bullet list. Pause — the save dot goes green and the edit ticker reads
`+3 chars`. No menu-diving; keep it brisk.

**Narration / captions:**
> "This is Xudanu. A document." *(while typing)*

> "Every change is versioned and signed as it's saved." *(save dot + ticker)*

**Out-line (hook):**
> "But text alone is only half of what text can be."

### 0:45–1:35 — LINKS (two-way, typed, unbreakable)

**On screen:** in Doc A, select a phrase. Create a link — choose
"Reference". Then ⌘-click the link to jump to Doc B. THE KEY SHOT: switch
to Doc B BEFORE making the link; after creation, show the backlink
appearing in Doc B's connections without anyone touching it. Hold two
seconds. Then show a "Disagreement" link being typed on the same phrase
(two links, one span — the stacked chooser).

**Narration / captions:**
> "Select anything. Connect it." *(creating)*

> "Links go both ways — the connection appears in both documents.
> Neither side can unilaterally sever it." *(backlink moment — hold)*

> "And connections are typed: comment, reference, disagreement." *(typed links)*

**Out-line:**
> "A link connects two passages. But what if the words themselves
> could be shared?"

### 1:35–2:25 — TRANSCLUSIONS (the thesis)

**On screen:** in the source essay, select a passage → **Transclude**
(hold). Open the second document → **Place**. The passage appears —
same words, attribution bands flowing from the original author. Now the
callback: edit the source passage; the placed copy updates. Then
paste-as-transclusion: copy a passage from one document, paste into
another, click **Transclude** in the toast.

**Narration / captions:**
> "Not a copy. A window onto the original." *(placing)*

> "Edit the source — every window reflects it." *(live update — hold)*

> "Authorship travels with the content." *(attribution bands)*

> "Even pasting can keep the connection." *(paste-as-transclusion)*

> "Content has one home, and many windows. That's the xanalogical idea."

### 2:25–2:55 — THE SYSTEM (briefly, as promised)

**On screen:** click a work's persistent address — the tumbler
(`"domain".5a3.12.40`) — copy it. Open the revisions timeline: every edit
listed, roll back one. Open the Archived shelf: "nothing is deleted".
If the network demo is presentable: follow one cross-server link.

**Narration / captions:**
> "Every passage has a permanent address." *(tumbler)*

> "Every revision, forever. Nothing is deleted — only shelved."
> *(revisions + archived shelf)*

> "And documents can live on independent servers, linking to each
> other." *(cross-server — omit if not presentable)*

### 2:55–3:05 — CLOSE (the lineage card)

**On screen, static card, no narration, hold 8 seconds:**

> **Xudanu**
> An independent, open-source, transclusion-native hypertext system.
>
> Core machinery translated from Udanax Gold —
> Xanadu 92.1, open-sourced 1999.
>
> xudanu · your-url

---

## Video description text (wherever posted)

> Xudanu is an independent open-source project (Apache 2.0). It is not
> affiliated with, endorsed by, or sponsored by Ted Nelson, Project
> Xanadu™, the Xanadu Operating Company, Autodesk Inc., or the Udanax
> development team. Xudanu's core machinery was translated from the
> open-sourced Udanax-Gold codebase (1999, MIT/X11) and substantially
> extended. All trademarks belong to their respective owners.

---

## Prep checklist (do these before recording)

**Server & client**
- [ ] Restart the server (`./scripts/restart.sh`) — picks up the current
      binary: clickable links, live markers, thaw fix, no crashes
- [ ] Hard-refresh the browser (⌘⇧R)
- [ ] Provenance tab → enable **pair** (paired author colours — the most
      distinctive on-screen visual)
- [ ] Two browser windows positioned side by side, both logged in as
      (ideally) two different identities — attribution bands show TWO
      colours, which reads better on camera
- [ ] Edit ticker confirmed working (type a word, see `+1 chars`)

**Seed corpus (build once, rehearse twice)**
- [ ] Doc 1 "The Garden Essay" — 3–4 paragraphs of original prose (the
      source; the cold open edits a word here)
- [ ] Doc 2 "Reading Notes" — holds one placed transclusion from Doc 1
      and will receive the paste-as-transclusion
- [ ] Doc 3 — exists only to receive a link + demonstrate the backlink
      appearing
- [ ] One extra archived work, so the Archived shelf isn't empty

**Rehearsal**
- [ ] Run the full keystroke sequence end to end, timed, twice. The
      beats that need practise: backlink-appears hold, live transclusion
      update, paste-as-transclusion toast click
- [ ] Keep cursor movement slow and deliberate; pause 1s after every
      money moment (editors cut around stillness well)

**Capture**
- [ ] 2560×1440 or 1920×1080, 60fps region capture, system notifications
      off, do-not-disturb on
- [ ] Record a 10s silence bed at the start (colour reference)
- [ ] Record narration separately; captions burned in — assume muted
      first view
- [ ] No music bed, or a single very low ambient pad — the content is
      the sound

**Posting**
- [ ] Title candidates: "Show HN: Xudanu – quotes that stay connected
      to their sources" / "Live transclusions, 30 years later"
- [ ] First comment: the lineage + disclaimer text (above) + what's real
      vs seeded
