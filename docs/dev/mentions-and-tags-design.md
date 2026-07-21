# Mentions and Tags: Associating People and Concepts with Documents

> How Xudanu models relationships between a document and the people,
> concepts, collections, and other entities it references. Extends
> the existing WorkKind system (FR-22) and typed-link infrastructure
> with a streamlined "lookup-or-create-and-link" UX pattern.

## Problem

When reading or writing a document, you encounter names ("Ted
Nelson"), concepts ("hypertext"), collections ("Xanadu Collection"),
and other entities. You want to:

1. **Mark** that this passage references that entity
2. **Navigate** to the entity's page (bio, definition, contents)
3. **Discover** all other documents that reference the same entity
4. **Visualize** these relationships in the graph

Today, you'd have to manually create a Person/Concept work, then
create a typed link from the document to it. That's 5+ steps. This
design makes it one click.

## Prior Art

### Wikipedia
- Everything is an article (people, concepts, places)
- `[[Ted Nelson]]` auto-creates the page if it doesn't exist
- The link is untyped (just a wiki-link)
- Categories group articles by type
- **Lesson: auto-creation is essential. Don't make users pre-create.**

### Roam Research / Logseq
- Everything is a page (including people)
- `[[Person Name]]` creates the page inline
- Pages have no type — they're just pages
- Backlinks show all references to a person
- **Lesson: bidirectional backlinks are the discovery mechanism.**

### Obsidian
- Markdown files with optional frontmatter `type: person`
- Tags group by type: `#person`, `#concept`
- Dataview plugin enables queries: "all works mentioning Ted Nelson"
- **Lesson: types enable filtering and graph coloring.**

### Notion
- Databases with typed relations
- "Person" database ↔ "Document" database with explicit relation
- Each relation has a name ("author", "mentioned in", "reviewed by")
- **Lesson: named relations add semantic clarity.**

### Semantic Web / RDF / Wikidata
- `foaf:Person` is a class; works have `dc:creator` pointing to it
- Properties: name, birthDate, occupation
- SPARQL queries: "all works by people born before 1950"
- **Lesson: structured properties enable powerful queries — but
  complexity should be optional, not required.**

### Ted Nelson's Xanadu
- Everything is a tumbler-addressed document
- Links are typed and bidirectional
- A person's "page" is just another document
- Transclusion enables reuse of biographical content
- **Lesson: this is exactly our model. We just need the UX.**

## Design: Lookup-or-Create-and-Link

### Core operation

```
Given: selected text "Ted Nelson" in document D
Do:
  1. Normalize: "Ted Nelson" → lookup key "ted nelson"
  2. Search: find existing Person-kind work with title matching key
  3. If found → use existing work_id
  4. If not found → create new work:
     - title: "Ted Nelson"
     - kind: Person
     - body: empty (user fills in later)
  5. Create typed link: D.selection → person_work
     - link type: "See Also" (or new "Mentions" type)
  6. Visual feedback: text gets a link marker in the document
```

### The same pattern for all entity kinds

| Select text | Button | Kind | Link type |
|---|---|---|---|
| "Ted Nelson" | 👤 Mention | Person | See Also |
| "hypertext" | 💡 Tag | Concept | See Also |
| "Chapter 3 of..." | ✂ Reference | Fragment | Reference |
| "Xanadu Collection" | 📚 Collection | Collection | See Also |
| "Bush argues that..." | 💬 Cite | Commentary | Quotation |

All use the same lookup-or-create-and-link mechanism. Only the kind
and link type differ.

### Normalization rules

To match existing works when creating links:

1. **Case-insensitive**: "Ted Nelson" matches "ted nelson" and "TED NELSON"
2. **Whitespace-collapsed**: "Ted  Nelson" matches "Ted Nelson"
3. **No prefix/suffix trimming changes the match**: "Ted Nelson." matches "Ted Nelson" (trailing punctuation stripped)
4. **Exact match only** (no fuzzy matching): "Ted Nelson" does NOT match "Theodore Nelson" — the user can create both and link them with a See Also link if needed

Rationale: fuzzy matching creates false positives (linking to the
wrong person). Exact normalized matching is predictable. The user
can always manually link if the names differ.

### What happens on the server

No new wire ops needed. The flow uses existing APIs:

```
1. Client: search for matching works
   → GET workList (filtered by title + kind)
   
2. If no match:
   → workCreate (empty edition)
   → workKindSet (kind = Person)
   → workSetText ("Ted Nelson\n\n(biographical info to be added)")
   
3. Create link:
   → linkCreate (
       origin: current_work_id,
       destination: person_work_id,
       origin_ref: { start, end, excerpt: "Ted Nelson" },
       destination_ref: { excerpt: "Ted Nelson" }
     )
   → linkSetTypes (link_id, [5])  // 5 = See Also
```

All of these wire ops already exist. This is purely a frontend
convenience that batches 3-4 API calls into one user action.

### What happens in the UI

**Selection popover gains two new buttons:**

```
[B] [I] | [Transclude] [Link] [Note] [+ Trail] [👤 Mention] [💡 Tag]
```

- **👤 Mention**: lookup-or-create Person work + link
- **💡 Tag**: lookup-or-create Concept work + link

Both appear for all users (even anonymous can read; only authenticated
users can create). If anonymous, show the amber warning.

**After clicking Mention:**

1. If exactly one match exists → link created immediately, brief
   "Linked to Ted Nelson ✓" toast notification
2. If multiple matches exist → small picker: "Did you mean:
   Ted Nelson (Person) / Ted Nelson Jr. (Person)?"
3. If no match → creates new Person work, brief "Created Person:
   Ted Nelson ✓" toast

**Visual feedback in the document:**

The linked text gets a subtle underline + colored marker (similar to
existing link markers in CollaborativeEditor). Hovering shows the
entity name and kind. Clicking navigates to the entity's work.

### Graph implications

Once mentions/tags are created:

- The graph shows edges from the document to Person/Concept nodes
- Person nodes (👤 grey) appear near documents that mention them
- Concept nodes (💡 green) appear near documents that tag them
- The relevance scoring (FR-21) automatically weights these connections

### Provenance implications

Mentions and tags are typed links — they have provenance:
- `created_by`: the identity that created the mention
- `created_at`: when the mention was added
- The link itself is tumbler-addressable

This means you can answer: "who first identified this passage as
referencing Ted Nelson?" — the link's provenance tells you.

## The Person Work

### What goes in a Person work

```
Ted Nelson

Born: 1937
Occupation: Sociologist, philosopher, pioneer of hypertext
Known for: Coinining "hypertext" and "hypermedia"; Project Xanadu

[biographical text written by users]

---
Works by Ted Nelson:
[automatically populated from backlinks — all documents that
mention Ted Nelson via a typed link]
```

The "Works by" section is derived from backlinks — no manual
maintenance needed. When someone mentions Ted Nelson in a new
document, the Person work's backlinks update automatically.

### Person vs. Author attribution

There are two separate concepts that should not be conflated:

| | Person work | Author attribution |
|---|---|---|
| **What it is** | A document about a person | Per-character provenance |
| **Addressable?** | Yes (tumbler) | No (metadata) |
| **Created by** | Any user | Server (automatically) |
| **Example** | "Ted Nelson was born in..." | "These 47 characters were written by key abc123" |
| **Purpose** | Navigation, discovery | Proof of authorship |

A Person work is NOT the same as the author's cryptographic identity.
The Person work is a document ABOUT the person; the attribution is
cryptographic proof of who typed each character.

They complement each other: the Person work answers "who is this
person?" while attribution answers "did this person actually write
this passage?"

## Integration with Existing Features

### FR-22 (Concepts and Categorization)

The "Tag" button is the frontend for the concept-as-work pattern
described in FR-22. When you tag "hypertext":
- If a Concept work named "Hypertext" exists → link to it
- If not → create it + link

The "Related Concepts" panel (in the left rail) already shows
Concept-kind works sorted by inbound link count. Tagging increases
the count automatically.

### FR-20 (Trails)

A trail through "key figures in hypertext" could stop at multiple
Person works. Each stop shows the person's bio + backlinks.

### FR-19 (Marginalia)

When a reviewer mentions a person in their comment, the mention
creates the same Person work + link. The author sees who the
reviewer referenced.

### FR-18 (Workspace)

Mentions appear in:
- The document surface (link markers on mentioned text)
- The Connections tab (typed links to Person/Concept works)
- The graph (Person/Concept nodes near the document)
- The right panel Provenance tab (if the Person is an author)

### Historical author import

When importing a source document by "Vannevar Bush":
1. The import creates the source work
2. The import metadata includes author name
3. A Person work for "Vannevar Bush" is auto-created (or linked if
   it exists)
4. A typed link connects the source work to the Person work

This is the same lookup-or-create-and-link pattern, triggered by
the import workflow rather than text selection.

## New Link Types (Optional)

The existing link types are: Comment, Reference, Disagreement,
Quotation, See Also, Web. For mentions, we could:

**Option A: Use existing "See Also"**
- Simplest. No backend changes.
- "See Also" is generic enough for "this passage references Ted Nelson."

**Option B: Add "Mentions" type (type 7)**
- More semantic: "Mentions Ted Nelson" vs "See Also Ted Nelson"
- Requires: register type in `link_type_register`, update
  `DEFAULT_LINK_TYPES`, update graph coloring
- Enables: filter the Connections tab by "Mentions only"

**Option C: Add "Mentions Person" (7) + "Tags Concept" (8)**
- Most specific. Distinguishes person-mentions from concept-tags.
- More complex, but enables different visual treatment.

**Recommendation: Option A for v1 (no backend changes), Option B
for v2 when we want filtering.**

## API Sequence (Frontend Implementation)

```typescript
async function mentionEntity(
  client: CrdtSyncClient,
  sourceWorkId: number,
  selectionStart: number,
  selectionEnd: number,
  selectedText: string,
  kind: WorkKind,  // "person" or "concept"
): Promise<{ workId: number; created: boolean }> {
  const normalized = selectedText.trim().replace(/\s+/g, ' ');
  
  // 1. Search for existing work with matching title + kind
  const works = await client.fetchWorkList();
  const graph = await client.workGraph();
  const kindCache = new Map(graph.nodes.map(n => [n.work_id, n.kind]));
  
  const match = works.find(w => 
    (w.title || '').toLowerCase() === normalized.toLowerCase() &&
    kindCache.get(w.work_id) === kind
  );
  
  if (match) {
    // 2a. Link to existing work
    const linkId = await client.linkCreate(
      sourceWorkId, match.work_id,
      { excerpt: selectedText, start: selectionStart, end: selectionEnd },
      { excerpt: normalized, start: 0, end: 0 },
    );
    await client.linkSetTypes(linkId, [5]); // See Also
    return { workId: match.work_id, created: false };
  }
  
  // 2b. Create new work
  const newWorkId = await client.workCreate();
  await client.workKindSet(newWorkId, kind);
  await client.workSetText(
    newWorkId,
    `${normalized}\n\n` +
    (kind === 'person' 
      ? '(Add biographical information here)' 
      : '(Add description here)'),
  );
  
  // 3. Create link
  const linkId = await client.linkCreate(
    sourceWorkId, newWorkId,
    { excerpt: selectedText, start: selectionStart, end: selectionEnd },
    { excerpt: normalized, start: 0, end: 0 },
  );
  await client.linkSetTypes(linkId, [5]); // See Also
  
  return { workId: newWorkId, created: true };
}
```

## Edge Cases

### Name collisions
Two different people named "John Smith":
- First mention creates Person work "John Smith"
- Second mention links to the SAME "John Smith"
- User notices the collision, renames one to "John Smith (astronomer)"
- Links survive the rename (they're by work_id, not title)

### Concept vs. Person with the same name
"Ford" could be a person (Gerald Ford) or a concept (ford motor company):
- The kind filter prevents cross-matching
- "Ford" as Person only matches Person-kind works
- "Ford" as Concept only matches Concept-kind works

### Long selections
Selecting an entire paragraph and clicking "Mention":
- Creates a Person work with a very long name
- Probably not what the user wants
- Mitigation: if selection > 100 chars, show a prompt:
  "Enter the person's name:" with the selected text pre-filled

### Updating mentions
If the user edits the text after mentioning, the link span migrates
via the existing Mapping (FR-14). The mention survives edits.

### Deleting mentions
Click × on the link in the Connections tab → link is deleted
→ the Person work still exists (other documents may reference it)
→ the Person work's backlink count decreases

## Visual Design

### In the document

| Entity kind | Marker color | Hover text |
|---|---|---|
| Person | Blue underline | "👤 Ted Nelson" |
| Concept | Green underline | "💡 Hypertext" |
| Collection | Purple underline | "📚 Xanadu Collection" |

These are subtle — just colored underlines on the mentioned text.
Existing link markers in CollaborativeEditor already support this
via margin descriptions.

### Toast notifications

```
┌──────────────────────────────────────┐
│ ✓ Linked to Ted Nelson               │
│ Click to open · Click × to undo      │
└──────────────────────────────────────┘
```

or:

```
┌──────────────────────────────────────┐
│ ✓ Created Person: Vannevar Bush      │
│ Click to open · Click × to undo      │
└──────────────────────────────────────┘
```

Toast auto-dismisses after 4 seconds. × button deletes the link
(but not the Person work).

## Implementation Phases

### Phase 1: Mention + Tag buttons (1-2 days)
- Add 👤 Mention and 💡 Tag buttons to selection popover
- Implement `mentionEntity()` function (lookup-or-create-and-link)
- Toast notifications
- No new backend ops — uses existing APIs

### Phase 2: Visual markers in document (1 day)
- Colored underlines on mentioned/tagged text
- Hover cards showing entity name + kind
- Click to navigate to entity work

### Phase 3: Disambiguation picker (half day)
- When multiple matches exist, show a small picker
- "Did you mean: Ted Nelson (Person, 1937) / Ted Nelson Jr. (Person)?"

### Phase 4: Import integration (1 day)
- When importing a source work, auto-create Person work for the author
- Link the source work to the Person work
- Show in import dialog: "Created Person: Vannevar Bush"

### Phase 5: Optional "Mentions" link type (half day)
- Register link type 7 = "Mentions"
- Update DEFAULT_LINK_TYPES
- Update graph coloring for mentions edges
- Add filter in Connections tab: "Show only mentions"

## Summary

The design is simple: **everything is a work, relationships are typed
links, creation is automatic.** This matches Wikipedia, Roam, and
Obsidian while adding Xudanu's unique typed-link and transclusion
capabilities.

The key insight: don't build a separate "entity" system. Reuse the
existing WorkKind + typed-link infrastructure. The only new code is
a frontend shortcut that batches workCreate + workKindSet + linkCreate
into one user action.
