# Transclusion Test Plan

Manual and automated test scenarios covering every transclusion path through the system.

---

## Prerequisites

1. Fresh server with test data: `pkill xudanu-server; rm -rf data/live/*; xudanu-server run 8080 data/live`
2. Run `scripts/create-test-data.js` to create:
   - 3 historical authors (Mary Shelley, Bram Stoker, Jane Austen)
   - 3 source works (Frankenstein, Dracula, Pride and Prejudice)
   - 1 composite document (0x03f0)
3. Create a user identity (e.g. "test-author" / "password1") and sign in
4. Open `localhost:5173`

---

## Test Group A: Source Work → Document (Primary Path)

### A1. Basic transclusion from source work

**Steps:**
1. Open source work (e.g. Frankenstein 0x03ed) — verify "SRC" badge in header
2. Select a passage (e.g. "I am by birth a Genevese")
3. Click "Transclude" button — verify TransclusionBadge appears
4. Navigate to composite document (0x03f0)
5. Click in editor to place
6. Wait 1s for markers to load

**Verify:**
- [ ] Text appears at click position in target document
- [ ] Colored sidebar bar appears next to transcluded text
- [ ] Hovering bar shows tooltip with source work title
- [ ] Clicking bar navigates to source work
- [ ] Attribution panel shows correct historical author (Mary Shelley)
- [ ] Server logs: `[apply_transclusion_attribution] stored pending attribution` OR provenance stamped
- [ ] Sidebar Links section shows outgoing link with excerpt preview

### A2. Multiple transclusions from same source

**Steps:**
1. Open Frankenstein, select passage A, transclude into doc
2. Open Frankenstein again, select passage B, transclude into same doc

**Verify:**
- [ ] Both passages appear in target document
- [ ] Two distinct colored bars (same color, same source work)
- [ ] Attribution panel shows both spans
- [ ] Two link entries in sidebar

### A3. Transclusion from different source works

**Steps:**
1. Transclude passage from Frankenstein (0x03ed) into doc
2. Transclude passage from Dracula (0x03ee) into same doc
3. Transclude passage from Pride and Prejudice (0x03ef) into same doc

**Verify:**
- [ ] Three different-colored bars appear
- [ ] Attribution panel shows 3 different historical authors
- [ ] Attribution bar (proportional chart) shows 3 segments

### A4. Transclusion survives server restart

**Steps:**
1. Create transclusion from source work to document
2. `pkill -f xudanu-server` (SIGTERM — should checkpoint)
3. Restart server
4. Open target document

**Verify:**
- [ ] Server logs: "Received SIGTERM" + "Checkpoint saved"
- [ ] Server logs on restart: `rebuild_pending_attributions` ran (if links exist)
- [ ] Transcluded text still present in document
- [ ] Colored bar still visible
- [ ] Attribution panel still shows correct historical author
- [ ] Sidebar still shows link

---

## Test Group B: Document → Document

### B1. User document to user document

**Steps:**
1. Create two new documents (Doc A and Doc B)
2. Write some text in Doc A
3. Select text in Doc A, click Transclude
4. Navigate to Doc B, click to place

**Verify:**
- [ ] Text appears in Doc B
- [ ] Colored bar visible in Doc B
- [ ] Attribution panel shows the user's identity as author (not historical)
- [ ] Sidebar shows link in both Doc A (outgoing) and Doc B (incoming)

### B2. Edit source after transclusion

**Steps:**
1. Create transclusion from Doc A to Doc B
2. Edit the source text in Doc A (change the transcluded passage)

**Verify:**
- [ ] Doc B still shows the ORIGINAL transcluded text (snapshot semantics)
- [ ] Link marker still present in Doc B
- [ ] No crash or error

### B3. Delete transcluded text in destination

**Steps:**
1. Create transclusion into a document
2. Select and delete the transcluded text in the destination

**Verify:**
- [ ] Text removed from document
- [ ] Colored bar disappears
- [ ] Link still exists in sidebar (link is independent of text content)
- [ ] Attribution panel no longer shows span for deleted text

---

## Test Group C: Chain Transclusion (A → B → C)

### C1. Three-hop chain

**Steps:**
1. Transclude passage from Frankenstein (source) into Doc A
2. Select the transcluded passage in Doc A, transclude into Doc B
3. Open Doc B

**Verify:**
- [ ] Text present in Doc B
- [ ] Stacked bars visible (3px base + 2px chain bar in gold)
- [ ] Provenance chain shows 2 hops: Frankenstein → Doc A → Doc B
- [ ] Attribution shows Mary Shelley as original author

### C2. Chain attribution query

**Steps:**
1. After C1, open Attribution panel in Doc B
2. Check provenance chain depth

**Verify:**
- [ ] Attribution panel shows chain hops
- [ ] Sidebar link shows provenance_chain count

---

## Test Group D: Edge Cases

### D1. Transclude into empty document

**Steps:**
1. Create a new empty document
2. Transclude passage from source work into it

**Verify:**
- [ ] Text appears (document no longer empty)
- [ ] Attribution correct

### D2. Transclude at start of document

**Steps:**
1. Write some text in a document
2. Transclude passage, click at position 0

**Verify:**
- [ ] Transcluded text appears at the very beginning
- [ ] Existing text shifted right
- [ ] Bar positioned correctly

### D3. Transclude at end of document

**Steps:**
1. Write some text in a document
2. Transclude passage, click at the very end

**Verify:**
- [ ] Text appended correctly
- [ ] Bar positioned correctly

### D4. Transclude overlapping text

**Steps:**
1. Transclude "I am by birth a Genevese" into doc
2. Then transclude "by birth" (a substring) from same source into same position

**Verify:**
- [ ] Both transclusions visible
- [ ] Attribution panel handles overlapping spans

### D5. Self-transclusion (same document)

**Steps:**
1. Open a document with text
2. Select text, click Transclude
3. Try to place in the same document

**Verify:**
- [ ] Either prevented or handled gracefully
- [ ] No infinite loop or crash

### D6. Cancel pending transclusion

**Steps:**
1. Select text, click Transclude
2. Click Cancel on the TransclusionBadge

**Verify:**
- [ ] Badge disappears
- [ ] Editor returns to normal editing mode
- [ ] No text inserted, no link created

### D7. Very long excerpt

**Steps:**
1. Select a very long passage (1000+ chars) from source work
2. Transclude into document

**Verify:**
- [ ] Full text inserted
- [ ] Attribution spans entire range
- [ ] find_excerpt_positions returns correct range

### D8. Unicode / special characters

**Steps:**
1. Select text with unicode characters (em dashes, quotes, accented chars)
2. Transclude into document

**Verify:**
- [ ] Characters preserved correctly
- [ ] Character offsets correct (no off-by-one from multi-byte)

---

## Test Group E: Persistence and Recovery

### E1. SIGTERM saves links

**Steps:**
1. Create transclusion
2. `pkill -f xudanu-server`
3. Check logs for "Received SIGTERM" + "Checkpoint saved"

**Verify:**
- [ ] SIGTERM handler fires
- [ ] Checkpoint includes links
- [ ] On restart, links restored (check `links=N` in "Restored" log line)

### E2. Kill -9 (unclean shutdown)

**Steps:**
1. Create transclusion
2. Wait for auto-checkpoint (30s) OR force one by doing another operation
3. `kill -9` the server process
4. Restart

**Verify:**
- [ ] Links restored from last successful checkpoint
- [ ] If checkpoint hadn't run, links are lost (expected — auto_checkpoint after link creation mitigates this)

### E3. Multiple restarts

**Steps:**
1. Create transclusion, restart server
2. Verify link exists
3. Create another transclusion, restart server
4. Verify BOTH links exist

**Verify:**
- [ ] Link counter increments correctly across restarts
- [ ] No link ID collisions
- [ ] Both links and their attributions survive

### E4. PendingAttribution survives restart

**Steps:**
1. Create a transclusion where attribution will be pending (e.g., race condition scenario)
2. Restart server before attribution resolves
3. Open target document

**Verify:**
- [ ] `rebuild_pending_attributions` logs that it rebuilt PAs
- [ ] Attribution overlay in `attribution_query` shows correct historical author
- [ ] After next CRDT materialization, `process_pending_attributions` stamps provenance

---

## Test Group F: Attribution Correctness

### F1. Historical author attribution

**Steps:**
1. Transclude from Frankenstein (source, author: Mary Shelley)
2. Open Attribution panel in target document

**Verify:**
- [ ] Author shows as "Mary Shelley" with "historical" badge
- [ ] Type: "historical"
- [ ] Source work ID shown as 0x03ed

### F2. User author attribution

**Steps:**
1. Transclude from user-created Doc A (not a source work)
2. Open Attribution panel in target document

**Verify:**
- [ ] Author shows as the user's identity name
- [ ] Type: "human"
- [ ] Signature valid

### F3. Mixed provenance

**Steps:**
1. Type some original text in a document
2. Transclude from Frankenstein
3. Type more original text
4. Transclude from Dracula

**Verify:**
- [ ] Attribution panel shows 3 distinct authorship regions:
  - User's own text (unsigned or signed by session)
  - Mary Shelley passage
  - Bram Stoker passage
- [ ] Attribution bar chart shows proportional segments
- [ ] Coverage percentage < 100% (own text has no attribution)

### F4. Reading view provenance

**Steps:**
1. Create document with mixed provenance (as F3)
2. Switch to Reading View
3. Press P to cycle through provenance levels (0→1→2→3)

**Verify:**
- [ ] Level 0: Plain text
- [ ] Level 1: Underlines on transcluded passages with source count badges
- [ ] Level 2: Underlines + hover highlighting
- [ ] Level 3: Full ProvenanceOverlay with widget selection

---

## Test Group G: Provenance Chain Visualization

### G1. Chain depth display

**Steps:**
1. Create A→B→C chain (source→doc→doc)
2. Open Doc C
3. Hover over the transclusion marker

**Verify:**
- [ ] Tooltip shows chain hop count
- [ ] Sidebar link shows provenance_chain with multiple hops

### G2. compare panel with transclusions

**Steps:**
1. Create transclusion in a document
2. Open Compare panel (⋯ More → Compare)
3. Compare against source work

**Verify:**
- [ ] Bridge curves show the transcluded passage
- [ ] No crash when comparing works with links

---

## Test Group H: Error Handling

### H1. Transclude from non-existent work

**Verify:**
- [ ] Server returns appropriate error
- [ ] Client shows error message
- [ ] No crash

### H2. Transclude to work without edit permission

**Verify:**
- [ ] Server rejects link creation
- [ ] Client shows permission error

### H3. Apply attribution for non-existent link

**Verify:**
- [ ] Server returns link not found error
- [ ] No crash

### H4. Attribution query on source work

**Steps:**
1. Open source work (read-only)
2. Open Attribution panel

**Verify:**
- [ ] Panel shows historical author spans
- [ ] No "unsigned" warnings for source content
- [ ] Does not crash on read-only work

---

## Test Group I: Performance

### I1. Many transclusions in one document

**Steps:**
1. Create 20+ transclusions from various sources into one document
2. Scroll through the document
3. Open Attribution panel

**Verify:**
- [ ] Editor remains responsive
- [ ] All bars render correctly
- [ ] Attribution panel loads within 2s

### I2. Large document with transclusions

**Steps:**
1. Create a document with 50,000+ characters
2. Place several transclusions throughout
3. Verify VirtualizedEditor handles markers

**Verify:**
- [ ] VirtualizedEditor renders markers at correct viewport positions
- [ ] Scrolling doesn't lose marker positions
