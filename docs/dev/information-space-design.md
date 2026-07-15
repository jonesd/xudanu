# Information Space Design: Making Sense of the Docuverse

> How Xudanu helps users build, navigate, and understand a complex
> interconnected document space. Synthesizes Ted Nelson's Xanadu concepts,
> information architecture research, digital gardening patterns, and our
> implementation experience.

## Core Principle

A document alone is just text. What makes it powerful is the **structure
between documents**: who references it, what it references, what type of
relationship exists, what content is shared, and where it sits in the
landscape.

Our tools must make this structure **visible, navigable, and authorable**.

## Three Layers of Navigation

### 1. Orienting: "Where am I?"

Users need to know their position in the docuverse at all times.

| Tool | Status | What it does |
|---|---|---|
| Related footer | Shipped | Shows immediate connections at bottom of document |
| Backlinks | Shipped | Shows who references this document |
| Link type markers | Shipped | Colored underlines show WHY passages are connected |
| Breadcrumb trail | **Needed** | Shows navigation history — "you came from X via Y" |
| Document metadata | **Needed** | Tags, topics, maturity (draft/published/mature) |

### 2. Overview: "What's connected?"

Users need to see the shape of the docuverse around them.

| Tool | Status | What it does |
|---|---|---|
| Perspective view | Prototype (FR-9) | Spatial layout of connected documents |
| Docuverse graph | Shipped | Mini force-directed graph in right panel |
| Link type filter | Shipped | Filter visible connections by type |
| Content fingerprint | Shipped | Find shared passages across documents |
| Clustering | **Future** | Group documents with many mutual connections |
| Landmarks | **Future** | Mark important documents (MOCs, key references) |

### 3. Wayfinding: "How do I explore?"

Users need guided paths and free exploration modes.

| Tool | Status | What it does |
|---|---|---|
| Typed links | Shipped | Comment, Reference, Disagreement, Quotation, See Also |
| Trails | Shipped | Curated reading sequences across documents |
| Full-text search | Shipped | Find passages across all works |
| Perspective panning | Prototype | Scroll through document landscape |
| Progressive disclosure | **Future** | Overview → drill down → details on demand |

## User Journeys

### Newcomer to the docuverse

1. Arrives at a **landing document** (MOC) that introduces the space
2. Sees the **Perspective view** — "here's the landscape of connected documents"
3. Follows a **trail** curated by an experienced user — guided reading path
4. Reads **link descriptions** that explain WHY documents are connected
5. Discovers **backlinks** — unexpected connections from other works

### Experienced user exploring

1. Uses **full-text search** to find relevant passages
2. Opens **Perspective view** centered on the found passage
3. Follows **content fingerprint matches** — "this text also appears in..."
4. Checks **backlinks** for documents they haven't seen
5. Saves a **custom Perspective layout** for future reference

### Author building the docuverse

1. Starts with a **MOC document** — what are the key themes?
2. Creates **typed links** between documents — the types ARE the structure
3. Uses **transclusion** for shared content — one source, many contexts
4. Writes **link descriptions** — explain WHY each connection exists
5. Creates **trails** for guided reading paths
6. Gets **proactive suggestions** — "you copied this, transclude instead?"

## Structural Concepts

### Maps of Content (MOC)

A document whose primary purpose is to organize and link to other documents.
Like a table of contents, but non-hierarchical and networked.

- MOC links are typed: "overview", "deep dive", "background", "counterpoint"
- Perspective view centered on an MOC shows the cluster of related documents
- MOCs can be nested: a top-level MOC links to sub-topic MOCs

### Same Document, Multiple Positions

Transclusion means one passage can appear in multiple documents. In the
Perspective view, the same content could appear at different positions in
different layouts. The docuverse isn't a tree — it's a graph where content
flows.

Each user might have their own Perspective layout. The documents are shared,
but the spatial arrangement is personal.

### Nesting / Compound Documents

A document can contain passages from other documents via inline transclusion.
This creates hierarchical containment:

```
Legal Brief (parent)
├── Statute Section (transcluded from criminal code)
├── Precedent Analysis (transcluded from case law)
└── Conclusion (original content)
```

The Perspective view could show this nesting visually — parent document
larger, transcluded sources smaller nearby.

### Clustering

Documents that share many connections naturally form clusters. The
Perspective view could detect these clusters (via graph analysis) and
position cluster members close together, with fewer connections between
clusters appearing as longer bridge lines.

## Proactive Structure Building

### Copy-Detection (FR-10 candidate)

When a user pastes text, check if it matches existing content via BLAKE3
fingerprint:

1. On paste: compute fingerprint of pasted text
2. Query fingerprint index for matches
3. If match found: show suggestion banner
   > "This text appears in [source document]. Transclude instead to keep
   > them connected?"
4. User can: transclude (creates inline transclusion), link (creates typed
   link), or dismiss (keeps as plain text)

This turns accidental duplication into intentional structure.

### Link Suggestions (future)

When a user writes a passage similar to an existing document:
> "This passage discusses [topic]. [Document X] covers similar themes.
> Create a link?"

### Trail Discovery (future)

When reading a document that's part of a trail:
> "This document is stop 3 of 5 in the trail '[Trail Name]'.
> [Continue trail] [See all stops]"

## Design Principles

1. **Structure is the content** — the connections between documents are
   as important as the text itself. Every tool should make connections
   more visible.

2. **Progressive disclosure** — start with overview, let users drill
   down. Don't overwhelm newcomers with the full graph.

3. **Proactive, not passive** — suggest connections, detect duplication,
   recommend trails. Don't wait for users to discover features.

4. **Multiple paths** — different users need different views. Trails for
   guided reading, Perspective for spatial exploration, search for
   targeted lookup, backlinks for serendipitous discovery.

5. **Author intent matters** — link types (Disagreement vs. Quotation)
   carry meaning that no algorithm can infer. Human-authored structure
   is the foundation; algorithmic matching is supplementary.

6. **Content has identity** — fingerprinted content can be tracked across
   documents, contexts, and servers. Duplication should be intentional,
   not accidental.

## Feature Priority

| Priority | Feature | Effort | Impact |
|---|---|---|---|
| 1 | Perspective view Phase 1.5 (FR-9) | Small | Spatial overview |
| 2 | Copy-detection suggestion (FR-10) | Medium | Proactive structure |
| 3 | Breadcrumb navigation trail | Small | Orientation |
| 4 | Document metadata (tags, topics) | Medium | Filtering/clustering |
| 5 | MOC document type | Small | Organized entry points |
| 6 | Save/share Perspective layouts | Medium | Personal organization |
| 7 | Clustering in Perspective | Large | Visual grouping |
| 8 | Trail integration in Perspective | Medium | Guided spatial paths |
| 9 | Progressive disclosure modes | Large | Scales to large docuverses |

## Related Documents

- FR-8: True Position CRDT (enables real-time collaboration on structure)
- FR-9: Perspective Document Comparison (spatial view)
- FR-10: Copy-detection and transclusion suggestion (proactive structure)
- Xanadu pattern language (Maggie Appleton): 11 patterns, we cover 9
- Shneiderman's mantra: "Overview first, zoom and filter, details on demand"
