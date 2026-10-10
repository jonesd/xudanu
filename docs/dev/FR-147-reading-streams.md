# FR-147 — Reading streams: vertical stacks, browse-and-connect

> **Status:** Proposed (2026-10-10). Follows FR-146 (the completeness
> matrix — now closed). Builds on FR-144 (the classic client).
>
> **Trigger:** real-use feedback — "the demo is neat, but I'm not sure
> it's usable for actual work." The reading posture is the design, but
> browsing loops and three visible pages isn't enough density for
> sustained engagement. The answer isn't to redesign the posture; it's
> to give the columns depth.

## Motivation

The '72 figure shows a row of pages. Our three-column panes mode
renders that figure faithfully — but a single page per column means
browsing is a chain of replacements, and following links can loop
you back to where you started with no visible trail. The fix is not
more columns (that breaks the posture) or a workspace shell (that
breaks the classic client's reason for existing). The fix is
**vertical depth within each column**: a scrolling stack of documents
that shows where you've been and lets you keep going.

While browsing, you should be able to make connections — select a
passage in any visible document, connect it to a passage in another
column. Reading IS connecting; the docuverse thickens as you walk.

## Design

### The reading stream

Each column holds an ordered stack of works, not one. The stack is
the column's browsing history: opening a work adds it to the top of
its column's stack; following a link from column A appends the far
end to column B's stack. Scrolling down moves forward through the
stack; scrolling up retraces. No replacement, no lost context.

### The active work

Each column has one "active" work — the one last touched (scrolled
to, selected in, clicked). The active work receives beams, marks,
identity boxes, and lens hover. Other works in the stack are visible
context: rendered at reduced opacity, still readable, but not
beam-anchored.

### Browse-and-connect

The connect button (⧉) and the gather chip operate on whichever
work in the stack contains the current selection. The origin draft
remembers both the column and the position within the stack. This
means you can:
- read doc 1 in column A, follow a link to doc 2 in column B
- scroll back to doc 1 in column A, select a passage
- press ⧉, select a passage in doc 2 in column B
- connected — without ever closing or replacing either doc

### Follow = append

Clicking an underline in any work in any column's stack appends the
far-end work to the next column's stack (scroll it into view).
Nothing is replaced. At a stack depth cap (configurable, default 8),
the oldest entry slides out.

### Visual

- Active work: full opacity, beams anchored, identity boxes drawn
- Stack neighbours: ~60% opacity, a thin separator line between works
- Each work in the stack carries a compact header: title + connection
  count, clickable to activate
- Scroll position per-work preserved when switching active works

## Wire ops

No new ops needed: the existing `work_get_edition`,
`link_list_for_work`, `link_create`, `resolve_inline_transclusions`,
`attribution_query` suffice. The stack is a client-side composition
of independently fetched works.

## Acceptance sketch

- Open doc A → follow a link → doc B opens below (not replacing) in
  column A or B; scroll down to see it
- Scroll back up → doc A is still there, position preserved
- Select a passage in any visible work → ⧉ → far end in another
  column → link created
- Browsing for 10 minutes leaves a visible trail in each column
- Beams anchor to the active work; switching active works re-anchors
