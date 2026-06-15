# xudanu — Guided Walkthrough

This walkthrough introduces the stable features of xudanu, a modern implementation of Ted Nelson's transclusion model built in Rust with a real-time collaborative web editor.

**Live demo:** https://xudanu.com (username: `xanadu`, password: `transclusion4U`)

---

## 1. Create an Identity

When you first open xudanu, create an identity:

1. Click **Create Identity** in the sidebar
2. Enter a display name (e.g., "Ted") and a password
3. Your identity is your author signature — every edit you make is attributed to you

You'll see your name appear in the header. All your works and edits are cryptographically tied to this identity.

---

## 2. Create a Work

1. Click **+ New Work** in the sidebar
2. A new document opens in the editor
3. Each work has a unique ID (shown in the header, e.g., `#03fd`)

Works are the fundamental unit of content in xudanu. Everything you write lives in a work.

---

## 3. Write and Edit

The editor supports standard text editing:

- **Type** — text appears immediately and syncs to the server
- **Enter** — creates a new line
- **Tab** — inserts a tab character
- **Undo/Redo** — Cmd/Ctrl+Z to undo, Cmd/Ctrl+Shift+Z to redo
- **Paste** — paste text from anywhere
- **Paste large text** — pasting 50+ characters triggers content-match detection

Every save creates a **revision**. The sidebar shows revision count, character count, and author breakdown.

---

## 4. Transclusion — Content Connected, Not Copied

Transclusion is the core idea from Xanadu: text from one document can appear in another, with a live connection back to the source.

### Try it:

1. Create **two works** with different text
2. In the first work, **select some text**
3. Open **More → Transclude Selection**
4. A badge appears showing the pending transclusion
5. Navigate to the second work
6. **Click** where you want to place the transclusion
7. The selected text appears with a **yellow/orange background** — this is transcluded content
8. A **colored bar** on the left marks the transclusion connection

The transcluded text is linked to its source. You can continue editing around it.

---

## 5. View vs Edit Mode

Toggle between two modes with the **View/Edit button** in the header:

- **Edit mode** — full editing with the collaborative editor
- **View mode (Reading)** — clean reading layout with transclusion markers and attribution

---

## 6. Version History

Every edit creates a revision. To explore:

1. Open **More → Revisions** (requires at least 2 revisions)
2. See a timeline of every version with author and character count
3. Click any revision to view its content

---

## 7. Attribution

See who wrote what:

1. Open **More → Show Attribution**
2. Text spans are color-coded by author
3. Historical authors (from transcluded sources) appear with dashed underlines
4. An attribution legend appears at the bottom of the editor

---

## 8. Sharing and Visibility

Control who can see and edit your works:

1. Click **Share** in the header
2. **Public** — anyone can read
3. **Private** — only you
4. **Anyone can edit** — enables collaborative editing

---

## 9. Annotations

Add notes to any text selection:

1. Select text in the editor
2. Open **More → Annotate Selection**
3. Enter a note
4. Open **More → Annotations** to toggle annotation visibility

---

## 10. Document Map

Visualize connections between works:

1. Open **More → Document Map**
2. See a graph of works and their transclusion links

---

## 11. Work Summary

The sidebar shows a rich summary for each work:

- **Revisions** — total number of versions
- **Characters** — current document length
- **Authors** — number of contributors
- **Sources** — number of transclusion sources
- **Author Contributions** — percentage breakdown by author
- **Version Timeline** — chronological list of all revisions

---

## Key Concepts

| Concept | Meaning |
|---------|---------|
| **Work** | A document — the fundamental unit of content |
| **Transclusion** | Live content connection between works (not a copy) |
| **Compound Edition** | A document that combines original text with transcluded spans |
| **Provenance Chain** | The full derivation history of transcluded content |
| **Revision** | A saved snapshot of a work at a point in time |
| **Attribution** | Cryptographic tracking of who authored each span of text |

---

## Source Code

- **GitHub:** https://github.com/jonesd/xudanu
- **Architecture docs:** https://dgjones.info/xudanu/

xudanu builds on the Udanax Gold (Xanadu 92.1) source code released in 1999, reimagined in Rust with CRDT-based collaborative editing.
