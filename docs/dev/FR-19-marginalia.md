# FR-19: Marginalia — Typed Review and Feedback

> A review and feedback system that uses Xudanu's Xanadu features
> (typed links, transclusion, per-character attribution, stable
> paragraph IDs) to deliver a richer experience than flat-comment
> tools. Targeted at academic peer review, fiction beta reading,
> technical document review, and editorial workflows.

## Decision Question

How does Xudanu reach writers and reviewers who aren't ready to
switch from their existing writing tool, but could be exposed to
Xanadu-grade features through a specific high-value workflow?

The answer shapes:
- Whether Xudanu has a viral adoption path
- Which Xanadu features get amplified as differentiators
- What we build next after the workspace foundation (FR-18)
- The product positioning against Notion, Roam, Obsidian, Google Docs

## Decision

**Build a review and feedback system ("Marginalia") as Xudanu's
adoption wedge.** Authors share a work via magic link; reviewers
leave typed feedback without committing to a Xudanu account. Every
review exposes new users to the Xanadu feature set in a context
where it's genuinely useful.

The name signals "more than comments" and evokes the scholarly
manuscript tradition. Reviewers get a real reason to engage (their
feedback becomes a first-class work with stable address); authors
get richer feedback than any flat-comment tool provides.

## Motivation

### The adoption problem

Xudanu as a "writing tool" competes with Notion, Roam, Obsidian,
Google Docs — all entrenched, all well-funded, all alluring. Asking
a writer to switch their daily tool is a heavy lift. Most won't,
even if Xudanu is technically superior for hypertext.

Xudanu as a "review tool" competes with weaker offerings. Google
Docs comments are flat and untyped. Notion is even thinner.
Hypothes.is is web-wide but disconnected from authoring. The bar
to clear is lower, and the use case is episodic (you don't switch
tools to review one document).

### Why Xanadu features shine in review

Xudanu's distinguishing features are not gimmicks in a review
context — they're genuinely better:

| Xudanu feature | Review use |
|---|---|
| **Typed links** | Reviewer picks: Comment, Disagreement, Quotation, See Also, Reference. Captures intent, not just text. |
| **Transclusion** | Reviewer includes a passage from another work as evidence ("compare to this passage in Borges"). |
| **Per-character attribution** | Author sees exactly which passages each reviewer engaged with. Heat map of attention. |
| **Stable paragraph IDs** | "See ¶17" remains valid across revisions. Review threads survive edits. |
| **Cross-server links** | Reviewer can cite works on a different Xudanu server. |
| **Private annotations** | Reviewer's own notes; public ones for the author. |
| **Versioning** | Review rounds map to revisions. Author sees what changed between round 1 and round 2. |

No competing tool has all of these. Most don't have any.

## Use Cases

### Primary (must support)

1. **Academic peer review.** Researcher submits a paper; 2–3
   reviewers leave typed feedback; author revises; reviewers see
   the diff.

2. **Fiction beta reading.** Author shares a draft; beta readers
   comment on specific passages; author curates which scenes need
   most attention.

3. **Technical document review.** Engineering team reviews a spec
   or RFC; comments are typed (concern, alternative, blocker).

4. **Editorial workflow.** Author + editor collaborate; editor's
   suggestions are first-class links; author accepts/rejects.

### Secondary (nice to support)

5. **Workshop / writing group.** Multiple reviewers commenting on
   shared drafts each week.

6. **Legal/contract review.** Adversarial review with typed
   disagreement and precedent citation.

7. **Classroom peer review.** Students review each other's work;
   instructor sees all feedback.

### Non-use cases (explicitly out of scope)

- **Real-time collaborative editing.** That's the workspace's job
  (FR-18). Marginalia is asynchronous feedback, not concurrent
  editing.
- **Issue tracking.** Review comments are not tickets. Don't try
  to compete with Linear/Jira.
- **General-purpose commenting on the web.** That's Hypothes.is.
  Xudanu Marginalia is for Xudanu works.

## Feature Design

### Author side

**Share for review:**

1. Author opens a work in the workspace
2. Clicks "Share for review" in the action bar
3. Configures:
   - Scope: full document or selected passages (focus blocks)
   - Reviewer identity required: anonymous OK / must log in / must be invited
   - Expiration: 7 days / 30 days / no expiry
   - Max reviewers: 1 / 5 / unlimited
4. Generates a magic link: `https://server/review/<token>`
5. Author can list active review links, revoke, or extend

**Focus blocks (the EDL-style idea):**

Author marks specific passages as "focus for review." Reviewers see
these highlighted with a colored margin band. Useful when:

- Author wants feedback on a specific scene, not the whole work
- Author has revised sections and wants re-review only on those
- Author wants different reviewers focused on different sections

A focus block is a span with metadata: `(start, end, label?,
reviewer_assignment?)`. Stored as a list on the work. Authors can
add/remove focus blocks at any time.

**Author dashboard:**

Aggregated view of all feedback on the work:

- Comments grouped by type (Disagreement first, then Comment, etc.)
- Comments grouped by reviewer
- Heat map of which passages got most engagement
- Per-comment actions: resolve, respond, convert to inline edit
- Diff view: what changed since the review was left

### Reviewer side

**Open the link:**

1. Reviewer visits `https://server/review/<token>`
2. Server validates token, checks expiry/usage limits
3. Reviewer sees the document in a focused reader view (no edit affordances)
4. Reviewer may optionally log in (to attribute feedback, transclude
   from their own works, etc.)
5. If author set focus blocks, those are highlighted with a brief
   explainer

**Leave feedback:**

Reviewer selects text → popover offers 5 typed actions:

| Action | Becomes link type | Example |
|---|---|---|
| Comment | Comment | "This paragraph is unclear." |
| Disagree | Disagreement | "I disagree with this claim because…" |
| Quote | Quotation | "This echoes Smith 2018, which should be cited." |
| Related | See Also | "Compare to ¶12 of Nelson's Literary Machines." |
| Reference | Reference | "For background, see this work." |

Each action creates a typed link from the reviewer's annotation to
the selected span. The link is unbreakable (migrates with edits).
The annotation is itself a work (with a tumbler, addressable).

**Optional: include evidence:**

Reviewer can transclude a passage from their own works (if logged
in) or from public works on the server. The transclusion appears
inline in the comment with full provenance.

**See other reviews:**

If the author allowed multiple reviewers, each reviewer sees others'
comments inline (with reviewer name and timestamp). They can respond
to each other's comments, creating a thread.

### Comment lifecycle

Each comment is a first-class entity:

- Created by a reviewer at time T on span S
- Has its own tumbler: `xan://server.work.paragraph.comment_id`
- Survives document edits (span migration updates S)
- Can be: resolved (by author), responded to (by anyone), converted
  to inline edit (by author), promoted to a standalone work

When the author revises the document, comments stay attached to
their migrated spans. If a span is deleted, the comment becomes
"orphaned" — still visible, marked as "passage deleted on
<date>."

### Comment as work

Each comment is itself a work with a tumbler. This means:

- Comments can be cited: `xan://server.work.p17.c42`
- Comments can be linked from other works
- Comments can be transcluded (e.g., in a meta-review that
  references multiple reviewers' points)
- Reviewer's body of feedback becomes their own addressable body of
  work — they own it, can take it with them, can build reputation
  on it

This is a genuine differentiator. No review tool treats comments
this way.

## Architecture

### Data model

```rust
pub struct ReviewLink {
    pub token: String,              // opaque, URL-safe, ~32 bytes
    pub work_id: WorkId,
    pub author_id: IdentityId,
    pub created_at: DateTime<Utc>,
    pub expires_at: Option<DateTime<Utc>>,
    pub max_uses: Option<u32>,      // None = unlimited
    pub uses_so_far: u32,
    pub require_identity: RequireIdentity,
    pub focus_blocks: Vec<FocusBlock>,
    pub revoked: bool,
}

pub enum RequireIdentity {
    Anonymous,    // anyone with the link
    AnyIdentity,  // must log in, any identity OK
    InvitedOnly,  // must be on the invite list
}

pub struct FocusBlock {
    pub start_char: u64,
    pub end_char: u64,
    pub label: Option<String>,
    pub assigned_reviewer: Option<IdentityId>,
}

pub struct ReviewComment {
    pub id: CommentId,
    pub work_id: WorkId,
    pub reviewer_id: Option<IdentityId>,  // None = anonymous
    pub reviewer_display_name: String,
    pub span_start: u64,                  // migrated on edit
    pub span_end: u64,                    // migrated on edit
    pub link_type: LinkType,              // Comment, Disagreement, etc.
    pub body: String,
    pub transclusion_refs: Vec<CrossServerRef>,  // optional evidence
    pub created_at: DateTime<Utc>,
    pub resolved: bool,
    pub resolved_at: Option<DateTime<Utc>>,
    pub resolved_by: Option<IdentityId>,
    pub parent_comment_id: Option<CommentId>,    // for threading
}
```

### Storage

ReviewLink and ReviewComment are stored in a new manifest section
alongside `SocialSection`:

```rust
pub struct ReviewsSection {
    pub review_links: Vec<ReviewLink>,
    pub comments: HashMap<WorkId, Vec<ReviewComment>>,
}
```

Comments piggyback on existing annotation infrastructure but are
distinct from private annotations. Both can coexist on the same
span.

### Wire protocol

New ops (additive, no existing ops change):

```
0x0A01  ReviewLinkCreate(work_id, expires_at?, max_uses?, require_identity) -> ReviewLink
0x0A02  ReviewLinkList(work_id) -> Vec<ReviewLink>
0x0A03  ReviewLinkRevoke(token) -> Void
0x0A04  ReviewLinkOpen(token) -> ReviewLinkPayload (validates token, returns work + focus blocks)
0x0A05  ReviewCommentCreate(token, span_start, span_end, link_type, body, transclusion_refs?) -> CommentId
0x0A06  ReviewCommentList(work_id) -> Vec<ReviewComment>
0x0A07  ReviewCommentResolve(comment_id) -> Void
0x0A08  ReviewCommentRespond(comment_id, body) -> CommentId  (creates child)
0x0A09  FocusBlockSet(work_id, blocks) -> Void
0x0A0A  FocusBlockList(work_id) -> Vec<FocusBlock>
```

`ReviewLinkOpen` is the only op callable without authentication
(via the public token). It returns enough to render the reader view
without exposing other works on the server.

### Magic-link auth

Reviewer opens `https://server/review/<token>`. The frontend:

1. Calls `ReviewLinkOpen(token)` — no auth required
2. Gets back: work content, focus blocks, existing comments,
   allowed actions
3. Establishes a session-scoped WebSocket connection with the token
   as the credential
4. Server tracks the session as a "reviewer session" with limited
   permissions (can comment on this work, nothing else)

### Reader UI

A new `ReviewReader` component, distinct from the workspace:

- Document surface (read-only)
- Margin shows paragraph IDs and focus block highlights
- Selection popover with 5 typed actions
- Inline comment markers (colored by type)
- Right panel: comment list (filter by type, by reviewer, by
  status)
- Top bar: work title, reviewer identity badge, "leave review"
  button

The reader UI is intentionally simpler than the workspace. No graph,
no lens row, no editing affordances. Pure reading + commenting.

### Author review dashboard

A new view in the workspace (right panel tab or dedicated lens):

- All comments on the current work
- Filter by type, reviewer, status
- Heat map overlay on the document showing engagement density
- Bulk actions: resolve all from reviewer X, convert all
  disagreements to inline edits
- Diff view: revisions vs. comments (which comments were addressed
  by which revision)

## Engineering Work Breakdown

| Component | Status | Effort |
|---|---|---|
| Typed links | Shipped | — |
| Annotations (public + private) | Shipped | Extend for review comments |
| Per-character attribution | Shipped | Use for heat map |
| Magic-link auth | Not built | 3–4 days |
| `ReviewLink` data model + ops | Not built | 2 days |
| `ReviewComment` data model + ops | Not built | 2 days |
| Focus blocks | Not built | 1 day |
| ReviewReader component | Not built | 3–4 days |
| Author review dashboard | Not built | 2–3 days |
| Heat map visualization | Not built | 1–2 days |
| Reviewer identity (anonymous → optional login) | Not built | 1 day |
| Comment threading | Not built | 1 day |
| Documentation + onboarding | Not built | 1 day |

**Total: ~3 weeks for MVP.** Uses existing Xanadu infrastructure
throughout; new work is mostly UX layer + auth.

## Implementation Phases

### Phase 1: Magic-link auth + read-only access (1 week)

- `ReviewLink` data model
- `ReviewLinkCreate` / `ReviewLinkOpen` ops
- Public read endpoint scoped to the token
- Reader UI: render the work (no commenting yet)

**Exit criteria:** Author can generate a link; reviewer can open
the work read-only without logging in.

### Phase 2: Typed comments (1 week)

- `ReviewComment` data model
- 5 typed actions (Comment / Disagreement / Quotation / See Also /
  Reference)
- Selection → typed comment popover
- Inline comment markers in the reader
- Comment list in right panel

**Exit criteria:** Reviewer can leave typed feedback; author can
see it in their workspace.

### Phase 3: Author dashboard (1 week)

- Aggregated comment view in workspace
- Heat map overlay
- Resolve / respond actions
- Diff view (which revisions addressed which comments)

**Exit criteria:** Author can manage review feedback and revise in
response.

### Phase 4: Focus blocks (3–4 days)

- Author marks spans as focus
- Reviewer sees highlights
- Optional reviewer assignment

**Exit criteria:** Author can scope review to specific passages.

### Phase 5: Polish (1 week)

- Threading (responses to comments)
- Reviewer consensus view (multiple reviewers flagged same passage)
- Reviewer identity (log in to attribute feedback, build reputation)
- Email notifications on new comments (optional)
- Onboarding docs for authors and reviewers

**Exit criteria:** Production-ready.

Each phase is independently shippable. Phases 1 and 2 give a
minimum-viable product.

## Alternatives Considered

### Alternative A: Anonymous comments only (no magic links)

Skip the link-based auth; allow anyone with the work ID to comment
if the work is "open for review."

- **Pro:** Simpler. No token management.
- **Con:** No access control. Spam risk. Author can't scope review
  to invited reviewers. Loses the "exclusive invite" feel that
  drives engagement.
- **Verdict:** Rejected. Magic links are worth the small
  implementation cost.

### Alternative B: Reviewer must log in

Require reviewers to create a Xudanu identity before commenting.

- **Pro:** Stronger attribution; reviewer can build reputation;
  enables transclusion from their own works.
- **Con:** High friction; many reviewers bounce at the signup wall.
  Loses the viral exposure benefit.
- **Verdict:** Rejected as default. Log in is **optional** —
  reviewers can comment anonymously, but logged-in reviewers get
  more capability (transclusion, persistent identity).

### Alternative C: Comments as flat annotations

Reuse existing annotation infrastructure, no typed links.

- **Pro:** Minimal new code.
- **Con:** Loses the main differentiator. Becomes a worse Google
  Docs.
- **Verdict:** Rejected. Typed comments are the point.

### Alternative D: External review tool integration

Build Xudanu as a backend for an existing review tool (e.g.,
Hypothes.is adapter).

- **Pro:** Don't have to build a UI.
- **Con:** Loses control of the experience. Hypothes.is doesn't
  support typed links or transclusion. We'd be back to flat
  comments.
- **Verdict:** Rejected. The UI is where the differentiation
  happens.

## Naming

Recommend **Marginalia** as the public-facing name.

| Option | Pros | Cons |
|---|---|---|
| **Marginalia** | Evocative, scholarly, "more than comments" | Slightly obscure word |
| Peer Review | Clear, academic | Implies academic-only use |
| Critical Reading | Literary feel | Slightly stuffy |
| Reader Response | Literary theory term | Jargon |
| Margin | Short, clean | Generic, hard to search for |
| Comments | Universal | Boring, sets wrong expectation |

Marginalia positions the feature against flat comment systems and
signals scholarly seriousness. The literary manuscript tradition
(notes in margins) is exactly the mental model.

If user testing reveals "marginalia" is too obscure, fallback to
**Review** as the public name with Marginalia as the internal code
name.

## Trust Model and Abuse Prevention

### Link leakage

If a review link leaks publicly, anyone can comment. Mitigations:

- Author can revoke at any time
- Author can set max uses (e.g., 5 reviewers max)
- Author can set expiration (7 days default)
- Author can require identity (logged-in only)
- Server rate-limits comments per IP/session

### Spam

If a reviewer spams comments:

- Author can delete or hide comments
- Author can block reviewer identity
- Author can require identity for future review links

### Identity fraud

A reviewer could log in with a fake name claiming to be someone
else. Mitigations:

- Display name is not verified; only the cryptographic identity is
- Authors should verify reviewer identity out-of-band (e.g., the
  invite email goes to a known address)
- Future: optional identity verification (link to ORCID, GitHub,
  etc.)

### Privacy

Reviewers' comments are visible to:

- The author (always)
- Other reviewers (if author allowed multi-reviewer)
- The server operator (always — server-side data)

Reviewers should be warned their feedback is not private from the
author. Private annotations are a separate feature (for the
reviewer's own notes).

## Success Criteria

- An author can generate a review link in under 5 clicks.
- A reviewer can leave their first typed comment within 30 seconds
  of opening the link, without signing up.
- An author can see all feedback aggregated by type, reviewer, and
  engagement heat.
- A reviewer's comment remains attached to its span across author
  revisions.
- Each comment has a stable tumbler that can be cited from other
  works.
- At least one real academic peer review cycle completes using
  Marginalia within 3 months of release.
- At least one fiction beta-reading cycle completes within 3
  months.

## Metrics to Track

- Number of review links created per week
- Number of reviewers per link (avg, distribution)
- Comment type distribution (Comment vs. Disagreement vs.
  Quotation etc.)
- Reviewer→author conversion (what % of reviewers later create a
  Xudanu identity for their own work?)
- Comment resolution rate
- Time from share to first comment
- Time from comment to resolution

These metrics tell us whether the viral loop is working and which
use cases are gaining traction.

## Ties to Other Designs

| Feature | Dependency |
|---|---|
| **FR-18 Workspace** | Author generates review links from workspace; dashboard lives there |
| **`versioning-design.md`** | Diff view (revision vs. comments) depends on revisions |
| **`cross-server-resolution.md`** | Stable paragraph IDs enable `xan://…¶17` citations in comments |
| **FR-6 Linked independent servers** | Reviewer can cite cross-server works as evidence |
| **FR-14 Space algebra** | Span migration keeps comments attached across edits |
| **Typed links (existing)** | Five review actions map to existing link types |

## Open Questions

1. **Comment editing.** Can reviewers edit their own comments after
   posting? If yes, do we keep edit history? **Recommendation: yes,
   keep history — comments are works, they version too.**

2. **Comment deletion.** Can reviewers delete their comments? Can
   authors? **Recommendation: reviewers can soft-delete their own;
   authors can hide but not delete (preserves scholarly record).**

3. **Multi-work review.** Can a single review link cover multiple
   works (e.g., a paper + supplementary materials)? **Recommendation:
   no for v1; one link per work. Add later if needed.**

4. **Export review.** Can an author export the full review (comments
   + responses) as a standalone document? **Recommendation: yes —
   it's a body of feedback, should be portable.**

5. **Public reviews.** Can an author choose to make a review public
   (visible to anyone, not just invited reviewers)? Useful for
   open peer review. **Recommendation: yes, as a per-link
   visibility setting.**

6. **Anonymous vs. pseudonymous.** "Anonymous" = no identity at
   all. "Pseudonymous" = stable identity that's not linked to a
   real person. **Recommendation: support both; default to
   pseudonymous (stable display name) for non-logged-in reviewers.**

7. **Notifications.** How does the author know a review landed?
   Email? In-app? WebSocket push? **Recommendation: in-app +
   optional email digest. Don't ship email notification in v1 —
   it's a separate service.**

## References

- `docs/dev/FR-18.md` — Workspace (host for review features)
- `docs/dev/versioning-design.md` — Revisions for diff views
- `docs/dev/cross-server-resolution.md` — Stable paragraph IDs
- `src/edition/links.rs` — Typed link infrastructure
- `src/server/transport/protocol.rs` — Existing wire ops (review
  ops will be additive)
- Ted Nelson, *The Future of Information* (1997) — Original
  vision of interconnected critical commentary
- Vannevar Bush, *As We May Think* (1945) — Trails through
  associated material
- Hypothes.is — Web annotation reference (what we differentiate
  from)
