# Xudanu Screenshot Guide

Purpose: populate a fresh server with compelling demo data and capture
the screens that show what Xanadu's ideas actually look like when
they work. Each shot answers a question a curious visitor would ask.

## The narrative arc (README order)

Shot 1 → "What is this?" (editor with visible structure)
Shot 2 → "Documents are connected" (colored link underlines)
Shot 3 → "Quotations are live windows" (transclusion)
Shot 4 → "Every link is two-way" (connections panel)
Shot 5 → "Compare documents visually" (beams/transpointing)
Shot 6 → "Every character is attributed" (provenance colors)
Shot 7 → "Assemble from sources" (compound builder)
Shot 8 → "Cross-server content" (federation)
Shot 9 → "Guided reading paths" (trails)
Shot 10 → "The welcome experience" (home landing)

---

## Shot 1: The Editor (hero shot)

**Shows:** A beautiful document with headings, links, formatting —
the "this is a real writing tool" credibility shot.

**Setup:**
- Create a document titled "The Docuverse, Practically"
- Content: an essay with H1 title, H2 sections, bold text, a code
  block, and 2-3 links to other documents (visible as colored
  underlines)
- Dark theme, three-pane studio layout ( ◧ toggle )
- Right panel: Connections tab

**Screen state:** Full browser window, editor focused, sidebar
showing document list, connections panel populated.

---

## Shot 2: Typed Links (the Xanadu difference)

**Shows:** The six link types as colored underlines — this is the
visual that says "not the web."

**Setup:**
- Create a source document with a paragraph of text
- Create 5-6 link destinations (short notes, comments)
- Link different phrases with different types:
  - Comment (green underline)
  - Disagreement (red underline)
  - Quotation (blue underline)
  - Reference (yellow underline)
  - See Also (purple underline)
- Make one link have a description (visible in margin)

**Screen state:** Editor with the linked paragraph centered, margin
descriptions visible, enough contrast to see all link colors clearly.

---

## Shot 3: Transclusion (the killer feature)

**Shows:** Text in one document that IS another document's content —
not a copy, a live window.

**Setup:**
- Create a source document: "Original Essay on Transclusion" with
  a clear, quotable paragraph
- Create a second document: "Response to the Essay" that transcludes
  the key paragraph
- The transcluded text should be visibly styled (margin bars,
  different background, or source attribution)

**Screen state:** Both documents side by side (split view), the
transcluded paragraph highlighted or showing its source indicator.
This is the "whoa" moment.

---

## Shot 4: Connections Panel (two-way linking)

**Shows:** Every link is visible from both ends — you always know
what connects to what.

**Setup:**
- Use the document from Shot 2 (or create one with 5+ links)
- Open the Connections panel (right side, "Links" tab)

**Screen state:** Connections panel showing:
- Links FROM this document (colored by type)
- Links TO this document (backlinks)
- At least 6-8 entries visible
- One link showing its description/annotation

---

## Shot 5: Beams / Transpointing (Xanagloss)

**Shows:** Side-by-side comparison with bezier curves connecting
shared passages between two documents.

**Setup:**
- Two documents with shared/overlapping text passages
- Open the Beams view (compare mode)

**Screen state:** Split-screen view, two documents side by side,
bezier curves or connection lines between matching passages,
shared regions highlighted. This should look distinctly different
from a diff tool — it's showing *shared content*, not *differences*.

---

## Shot 6: Provenance / Authorship

**Shows:** Every character attributed to its author with
cryptographic verification.

**Setup:**
- Create a document, edit it with 2-3 different identities
  (or use the seeded demo data that already has multi-author text)
- Open the Attribution view

**Screen state:** Text with colored authorship overlay (each author
a different color), the authorship summary bar showing percentages,
the "verified" checkmark. The author list with color swatches.

---

## Shot 7: Compound Builder

**Shows:** Assembling a document from transcluded pieces of other
documents — the "writing with quotations" workflow.

**Setup:**
- Create 3-4 source documents with distinct, interesting passages
- Open the Compound Builder (Compose tab)
- Include passages from 2-3 sources

**Screen state:** Builder panel on the right, source document open,
at least one passage included, the live preview showing the
assembled result with attribution.

---

## Shot 8: Cross-Server Federation

**Shows:** Content from a different server, living inside your
document via transclusion.

**Setup:**
- Start the 4-node federation demo (`./scripts/federation.sh start`)
- Create a document on node 2, link/transclude it into a document
  on node 1
- The cross-server link should show the server identity

**Screen state:** Editor showing transcluded content from a remote
server, the server indicator/namespace visible, origin panel showing
the cross-server source.

---

## Shot 9: Trails (guided reading)

**Shows:** A curated path through multiple documents — Nelson's
original vision for how readers navigate the docuverse.

**Setup:**
- Create a trail with 4-5 stops through interesting documents
- Each stop has a note/description

**Screen state:** The trail panel showing the path with stop numbers
and descriptions, or the trail-following bar at the top of the
editor showing current position in the trail.

---

## Shot 10: Home / Landing (the invitation)

**Shows:** The first thing a new visitor sees — clean, inviting,
communicating what this is.

**Setup:**
- Fresh browser session (or incognito)
- Navigate to the root URL

**Screen state:** The home landing page with the Xudanu title,
feature cards (Typed Links, Transclusion, Provenance, etc.),
and the "Start Writing" call to action.

---

## Technical notes

- Use a consistent window size: 1440×900 or 1920×1080
- Dark theme (default) — it photographs better
- Hide browser chrome where possible (F11 or screenshot tool)
- The vite dev server (localhost:5173) serves the latest UI
- Use the seeded demo data if available, or run seed scripts
- For multi-author shots: create 2-3 identities and edit the same doc
