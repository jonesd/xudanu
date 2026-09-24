# Screenshot Session Plan

## What already has screenshots (may need retaking if UI has changed)

| Existing file | Shows | Retake? |
|---|---|---|
| 04-history-authors-bar.png | Provenance colors in revision timeline | Probably OK |
| 05-trails-panel.png | Trails list panel | Probably OK |
| 06-trail-follow-bar.png | Trail position bar in editor | Probably OK |
| 07-transclusion-margin-bars.png | Transclusion with margin indicators | Retake — transclusion styling improved |
| 08-learn-index.png | Learn/lessons index page | Probably OK |
| 09-12-compound-builder-*.png | Compound builder workflow (4 shots) | Probably OK |
| hero.png | Previous hero shot | Retake — home landing redesigned |
| design-a-home-first.png | Mockup only, not a live screenshot | Need live version |
| design-b-three-pane.png | Mockup only | Need live version |
| design-c-transclusion-window.png | Mockup only | Need live version |
| design-d-beams-n-way.png | Mockup only — this is the classic design | NOT achievable with current UI |

## The 10 shots: what's ready vs what needs work

### Ready now (just set up data and screenshot):

1. **Editor hero shot** — open any well-formatted doc with links,
   three-pane layout, dark theme. Ready.

2. **Typed links with colors** — create a doc with all 6 link types.
   The colored underlines + margin descriptions work. Ready.

3. **Transclusion** — place a transclusion, open both docs side by
   side. The margin bars + source attribution work. Ready.

4. **Connections panel** — after creating links, open the right
   panel → Links tab. Shows from/to links with type colors. Ready.

5. **Provenance / authorship** — edit with 2+ identities, open
   Attribution panel. The colored overlay + verified checkmarks
   work. Ready.

6. **Compound builder** — the existing screenshots 09-12 cover this.
   Retake if the builder UI changed. Ready.

7. **Trails** — create a trail, screenshot the panel + the
   following bar. Ready (existing 05-06 may suffice).

8. **Home / landing** — open in incognito to see the fresh-user
   experience. Ready.

### Needs some setup but achievable:

9. **Cross-server transclusion** — needs the 4-node federation demo
   running. Create content on one node, transclude into another.
   The cross-server indicators + origin panel work. Achievable.

### NOT ready (would need new UI work):

10. **Classic transpointing windows / beams** — the current Compare
    panel is a side-by-side diff with bezier connections between
    shared passages. It's functional but NOT the classic Nelson
    design of n parallel document columns with curves spanning
    between them. The mockup (design-d-beams-n-way.png) shows the
    vision. This would need a dedicated BeamsView component.

    **For now:** screenshot the Compare panel with two docs that
    share passages — it shows the CONCEPT even if the visual
    isn't the classic design. Label it as "comparison view" not
    "transpointing windows."

---

## Recommended session order (30–45 min)

### Setup (5 min)
1. Run `node scripts/seed-screenshots.mjs "ws://localhost:8080/xudanu?format=json&version=2" "<admin-passphrase>"`
2. Open http://localhost:5173 in Chrome, sign in as admin
3. Set window to 1440×900, dark theme

### Shots (2–3 min each)

**Shot A: Home landing** (incognito)
- Open incognito → http://localhost:5173
- Screenshot the full page (hero + feature cards + CTA)
- File: `screenshots/home-landing.png`

**Shot B: Editor with links** (the hero shot)
- Open "The Docuverse, Practically"
- Toggle ◧ for three-pane layout
- Right panel → Links tab
- Screenshot the full window
- File: `screenshots/editor-three-pane.png`

**Shot C: Link types close-up**
- Open the same doc, scroll to the linked paragraph
- Make sure colored underlines + margin descriptions are visible
- Screenshot just the editor area (crop if needed)
- File: `screenshots/link-types.png`

**Shot D: Transclusion**
- Open "Windows, Not Copies"
- Manually add a transclusion from "Transclusion: Content Has One Home"
- Open both docs in split view (if available) or show the
  transclusion with its margin bars in a single view
- File: `screenshots/transclusion.png`

**Shot E: Connections panel**
- Same doc, right panel → Links
- Make sure both "from" and "to" links are visible
- File: `screenshots/connections.png`

**Shot F: Provenance**
- Create or find a multi-author document
- Open Attribution panel / history tab
- Show the colored authorship + verified checkmark
- File: `screenshots/provenance.png`

**Shot G: Compare (bezier curves)**
- Open the compare panel with two documents that share text
- The bezier curves connecting shared passages will render
- File: `screenshots/compare-bezier.png`

**Shot H: Compound builder**
- Open the builder (Compose tab)
- Load a source, select a passage, include it
- File: `screenshots/compound-builder.png` (or reuse existing 09-12)

**Shot I: Trails**
- Open a trail from the Trails panel
- Follow it to show the position bar
- File: `screenshots/trails.png` (or reuse existing 05-06)

**Shot J: Cross-server** (requires federation demo)
- `./scripts/federation.sh start 4 /tmp/xudanu-fed-demo`
- Create content on node 2, transclude into node 1
- Show the origin panel with the remote server indicator
- File: `screenshots/cross-server.png`
