# FR-27: Link Context Filtering

> **Status:** In development
> **Depends on:** FR-4 (Typed Bidirectional Links), FR-21 (Graph Filtering)
> **Motivation:** Roger Gregory noted "link filtering seems lost." Currently
> all links are shown to all readers with no contextual filtering.

## Problem

Every link is visible to every reader. There is no way to:
- Show only links of a certain type (e.g., only References)
- Show only links from a specific author
- Show only links relevant to the current edition/revision
- Control link visibility based on reader context

## Solution

Add filter parameters to link queries and UI controls.

### Filter Dimensions

| Dimension | Query param | Example |
|---|---|---|
| Link type | `?type=reference` | Show only Reference links |
| Author | `?author=0x1011` | Show only links by specific user |
| Direction | `?direction=outgoing` | Show only outgoing links |
| Work | `?work=0x49c` | Show only links to/from a specific work |
| Edition | `?revision=3` | Show only links present at a specific revision |

### Backend Changes

- Add optional filter params to `build_work_graph`
- Add filter params to the link list query used by Connections panel
- Return link metadata (author, timestamp) for filtering

### Frontend Changes

- Filter dropdown in Connections panel (type, author)
- Per-link-type visibility toggles
- "Show only my links" toggle
- Saved filter presets per user

## Acceptance Criteria

- [ ] Backend accepts type/author/direction filter parameters
- [ ] Connections panel has filter controls
- [ ] User can toggle individual link types on/off
- [ ] "Show only my links" works
- [ ] Filters persist across page navigation
- [ ] Tests: filter by type, filter by author, combined filters
