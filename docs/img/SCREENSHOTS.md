# Screenshot Capture Checklist

Take screenshots with Cmd+Shift+4 (drag to select), save to this folder (`docs/img/`).

## Setup
1. Start both servers: `./scripts/restart.sh`
2. Open `http://localhost:5173`
3. Create 3-4 works with distinct content (e.g., "Original Essay", "Anthology", "Commentary")
4. Use dark theme for consistency

## Shots to capture

### t-01-select-transclude.png
- Open a work with text
- Select a passage (10+ chars)
- Show the selection action bar with "Transclude" button visible
- Capture: editor area with selection + action bar

### t-02-badge.png
- After clicking Transclude
- Navigate to another work
- The TransclusionBadge should be floating (bottom of editor area)
- Capture: badge with source title + excerpt preview

### t-03-placed.png
- Click in the editor to place the transclusion
- Show the placed text with colored margin bar on the left
- Capture: editor with transclusion marker visible

### t-04-links.png
- Open the right panel → Connections tab
- Show incoming/outgoing transclusion links
- Capture: connections panel with link entries, direction arrows, excerpts

### t-05-multihop.png
- Create a chain: Work A → Work B → Work C (transclude through the chain)
- Open Work C, show amber provenance badges
- Capture: margin bars showing stacked amber depth indicators

### t-06-tooltip.png
- Hover over a margin bar marker
- Show the dark tooltip with work title + direction + hop count
- Capture: tooltip visible over the margin bar

### t-07-attribution.png
- Enable attribution view (right panel → Provenance tab)
- Show green author markers alongside transclusion margin bars
- Capture: editor showing both attribution colors and transclusion markers

### t-08-migration.png
- Open source document, edit text BEFORE the transcluded passage
- Switch to the document with the transclusion
- Show that the transclusion has shifted to track the original passage
- Capture: the updated transclusion position (ideally show before/after)
