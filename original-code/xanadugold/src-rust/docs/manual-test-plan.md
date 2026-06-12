# Xudanu Transclusion — Manual Test Plan

Start server: `cd original-code/xanadugold/src-rust && cargo run --features serde,server --bin xudanu-server -- run --otree-crdt --csrf-token --static-dir /Users/jonesd/code/xu-gold-2026/web/app/dist data`

Open **http://localhost:8080** in your browser.

---

## 1. Basic Document Operations

- Create a new work (click "+" or type in sidebar)
- Type text in the editor — verify it saves and syncs
- Create 3-4 works with distinct content (e.g., "Chapter 1", "Chapter 2", "Chapter 3")

## 2. Transclusion — Select → Navigate → Place

- Open **Work A**, select a passage (10+ chars)
- Click the **Transclude** button in the header
- Verify the **TransclusionBadge** appears with source info
- Navigate to **Work B** via sidebar
- Click in Work B's editor to place the transclusion
- Verify excerpt text appears at click position
- Verify a **colored margin bar** appears on the transcluded text

## 3. Transclusion — Links Sidebar

- With Work B open, click the **Links** tab in the right sidebar
- Verify the link appears under **"Transcluded from"** (incoming)
- Navigate to Work A, check Links tab — link should appear under **"Transcluded to"** (outgoing)
- Verify excerpt text and direction arrows (→ outgoing, ← incoming)

## 4. Multi-Hop Provenance Chain

- Transclude from **Work A → Work B** (creates Link 1)
- Transclude from **Work B → Work C** (creates Link 2)
- Open Work C, check Links sidebar — Link 2 should show **"1 hop"** amber badge
- Transclude from **Work C → Work D** (creates Link 3)
- Open Work D — Link 3 should show **"2 hops"**

## 5. Stacked Margin Bars (Provenance Depth)

- Open **Work D** — the transcluded passage should have:
  - A **colored bar** (primary marker, 3px)
  - **1-2 amber bars** stacked beside it (provenance chain depth)
- More hops = more amber bars visible

## 6. Hover Tooltips on Markers

- Hover over a **margin bar** in any work with transclusion markers
- A **dark tooltip** should appear showing:
  - Work title (colored)
  - Direction ("Transcluded to" / "Transcluded from")
  - Provenance hop count (if any)

## 7. Click-to-Navigate

- **Click** on a margin bar marker
- The editor should navigate to the **linked work** (switch to the other document)

## 8. Provenance Ancestry (Wire API)

Using the browser dev console or a WebSocket client:

```
Send: { "v": 2, "msg_type": "request", "id": 1, "op": "provenance_ancestry", "payload": { "work_id": <Work D id> } }
```

Expected: returns the full chain of hops (Work C → Work B → Work A)

## 9. Compound Document Resolution (Wire API)

```
Send: {
  "v": 2, "msg_type": "request", "id": 2,
  "op": "compound_resolve",
  "payload": {
    "compound": {
      "elements": [
        { "type": "text", "content": "Start: " },
        { "type": "span", "source_work_id": <Work A id>, "char_start": 0, "char_end": 20 },
        { "type": "text", "content": " ... " },
        { "type": "span", "source_work_id": <Work B id>, "char_start": 0, "char_end": 15 },
        { "type": "text", "content": " End" }
      ]
    }
  }
}
```

Expected: response contains resolved text with live content from both works spliced together.

## 10. Delete a Link

- In the Links sidebar, click the **×** button on a link
- Verify the link is removed from the sidebar
- Verify the margin bar disappears from the editor
- Verify the other work's links sidebar updates (no stale references)

## 11. Attribution Overlay

- Enable attribution view (if available)
- Verify **green** markers for human edits
- Verify margin bars still render alongside attribution

## 12. Edge Cases

- **Short excerpt** (<10 chars): should NOT create a marker (minimum length check)
- **Non-existent work in compound span**: should return an error, not crash
- **Inverted span** (start > end): should resolve correctly (auto-swapped)
- **Rapid link creation**: create multiple links quickly, verify all appear in sidebar
