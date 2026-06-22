# Comparison & Merge Tools

xudanu provides three complementary tools for comparing and reconciling document content. This guide walks through each with examples.

---

## 1. Side-by-Side Compare (2-Way)

**When to use:** Comparing two documents to see what they share and where they differ.

**How to open:** Open any document → **More ▾ → Compare** → select another document (or a past revision).

### Split View

Shows both documents side-by-side with:
- **Coloured bridge curves** connecting shared passages between the two columns
- **Light blue background** on text unique to the left document
- **Light orange background** on text unique to the right document
- Paragraphs are matched by position; shared paragraphs get the same colour

### Fuzzy vs Exact Matching

A toggle in the compare header controls how paragraphs are matched:

- **Fuzzy** (default): paragraphs sharing ≥20% of their words are linked. Use this when comparing documents on the same topic that have been reworded.
- **Exact**: only identical paragraphs (character-for-character) are linked. Use this when comparing revisions of the same document where only specific passages changed.

**Example:** Comparing two essays about Gothic literature that quote the same passages but use different surrounding analysis — Fuzzy links the shared quotes; Exact only links paragraphs that haven't been touched.

### Inline Diff View

Toggle from "Split" to "Diff" to see a word-level comparison:
- **Soft green** background: text added in the right document
- **Soft red** background with strikethrough: text removed from the left document
- Black text: common to both

This is useful for seeing exactly which words changed, rather than which paragraphs are shared.

---

## 2. Three-Way Merge Tool

**When to use:** Reconciling two independent revisions of a common source into a single merged document.

**How to open:** Open the base/original document → **More ▾ → 3-Way Diff** → select Document A and Document B.

### The Three Roles

| Role | What it is | Example |
|---|---|---|
| **Base** | The original document (the current work when you open the panel) | A first draft of an essay |
| **Document A** | One revised version | Editor A's tightening of the prose |
| **Document B** | A different revised version | Editor B's expansion with new examples |

### How It Works

The tool splits all three documents into paragraphs and classifies each:

| Segment type | Visual | What happened | Resolution |
|---|---|---|---|
| **Common** (grey) | Grey border | Same in all three | Keep as-is |
| **A only** (green) | Green border | Only A changed this paragraph | Auto-accept A's version |
| **B only** (blue) | Blue border | Only B changed this paragraph | Auto-accept B's version |
| **Auto-merged** (purple) | Purple border | Both A and B changed this paragraph, but different sentences | Auto-combine both changes |
| **Conflict** (red) | Red border | Both A and B changed the same sentence differently | **You decide**: click A, B, or Base |

### Conflict Resolution

For each red conflict segment, you see three boxes side by side:
- **A (green)** — accept A's version of this paragraph
- **B (blue)** — accept B's version
- **Base (grey)** — keep the original

Click the one you want. A ✓ appears on your choice.

**Bulk actions:**
- **"Accept all A"** — resolve every conflict in favour of A
- **"Accept all B"** — resolve every conflict in favour of B

### Auto-Merge (Purple)

When both A and B changed the same paragraph but touched **different sentences**, the tool automatically combines both changes. For example:
- A changed sentence 1 ("temperatures have risen" → "temperatures have climbed")
- B changed sentence 2 ("ice is melting" → "sea ice is disappearing")

These don't conflict — both changes are kept. The merged paragraph includes A's wording for sentence 1 and B's wording for sentence 2.

### Creating the Merged Document

Once all conflicts are resolved (or if there are none), click **"Create Merged Document"**:
- A new work is created with the merged text
- The curator (you) is stamped as the signed author
- Attribution panel shows your identity at 100% coverage
- A success screen with a link to open the new document

---

## 3. Version Genealogy

**When to use:** Understanding the ancestry of a document — what it was derived from and what derives from it.

**How to open:** Open any document → **More ▾ → Version Genealogy**

Shows:
- **Ancestors**: documents this work was derived from (via transclusion)
- **Descendants**: documents derived from this work
- Click any node to navigate to that document

---

## Choosing the Right Tool

| Scenario | Tool |
|---|---|
| "How do these two documents differ?" | Compare → Split or Diff |
| "Two editors revised my draft — combine the best of both" | 3-Way Merge |
| "What did this paragraph look like in revision 3?" | Compare → vs Revision → Diff |
| "Where did this content come from?" | Version Genealogy |
| "Which paragraphs are shared between these documents?" | Compare → Split → Fuzzy |

---

## Worked Example: Editorial Merge

### Setup
An author writes a draft essay about climate change. Two editors review it independently:

- **Editor A** tightens sentence 1 and adds a paragraph about wind power
- **Editor B** rewrites sentence 2 and adds a paragraph about battery storage
- Both editors rewrite sentence 5 of paragraph 3 differently

### Steps

1. Open the original draft (Base)
2. More ▾ → 3-Way Diff
3. Select Editor A's version as A
4. Select Editor B's version as B
5. The tool shows:
   - Paragraph 1: **Auto-merged** (purple) — A changed sentence 1, B changed sentence 2 → both kept
   - Paragraph 2: **Conflict** (red) — both rewrote the same sentence → you pick A's tighter wording
   - Paragraph 3: **A only** (green) — only A added the wind power sentence → auto-accepted
   - Paragraph 4: **B only** (blue) — only B added the battery storage sentence → auto-accepted
6. Resolve the conflict in paragraph 2 (click A)
7. Click "Create Merged Document"
8. The result has: A's tightened sentence 1, B's rewritten sentence 2, A's chosen version of the conflict, plus both new paragraphs

The merged document credits you (the curator) as the signed author.

---

## Tips

- **Create test documents first.** Before merging important documents, practice with copies so you understand how the tool classifies changes.
- **Fuzzy matching is topic-aware.** Two paragraphs about the same subject will link even if the wording is quite different. Switch to Exact for strict matching.
- **Auto-merge is sentence-level.** Changes within the same sentence by both sides will conflict; changes in different sentences of the same paragraph will auto-merge.
- **The merged document is a new work.** It doesn't modify the originals. You can re-merge with different choices.
- **Check attribution after merging.** More ▾ → Show Attribution to see the curator's signed provenance on the merged document.
