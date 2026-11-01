# FR-158: The enterprise knowledge fabric — Gold-lineage trust for the workplace

**Status:** sketched 2026-10-31; **Stage A (skills claims
backend) built same day** — see the as-built section at the end.
Prompted by the FR-157 exploration: asked whether any of the
endorsement fabric is an enhancement over tools like MS Teams, the
answer turned out to be a specific layer, not a replacement — and
the enterprise is arguably the natural first habitat for the design.

**One line:** a business already has the population Gold's trust
fabric died waiting for; skills and expertise claims, done the
FR-157 way (evidence-anchored, work-weighted, retractable,
visibility-scoped), are the application.

## The problem

- Directory tools (Teams/Entra) model relationships as one bit:
  in-group or out. Skills are self-declared profile fields, or
  imported from LinkedIn.
- "Who actually knows X?" — expertise location — is the perennial
  unsolved enterprise search problem. Frequency-based suggestions
  (who you message most) optimize for social proximity, not
  competence.
- LinkedIn skill endorsements are the cautionary tale: zero cost,
  reciprocal back-scratching, no evidence, no decay, no weighting —
  inflated to noise within years of launch.

## The insight: a business is a captive population

Gold's shipped image contains zero human endorsements —
infrastructure mature, sociology absent (see FR-157's census). The
mechanism never got its population. An enterprise is the opposite
starting condition: n=500 on day one, participation not optional,
work already digital. The recorder-at-n=1 becomes a recorder at
n=500 immediately, and trust accrues from work already flowing
through the system. The cold-start problem that killed the feature
in the wild does not exist inside an org chart.

## Mechanism mapping

| Today (Teams-era) | Gold-lineage fabric |
| --- | --- |
| Group membership: one bit | Typed, directional edges — read/edit/history distinguish *what you may do with someone's content* |
| Self-declared skills | Grade ladder: a self-claim is a draft; evidence-backed peer vouches make it reviewed |
| Suggestions = chat frequency | Suggestions = work-weighted endorsement graph (whose vouches hold up) |
| No memory of vouching | Retraction, timestamps, PROV records, scoped visibility (`visibleEndorsements`) |

## Skills endorsement — the FR-157 way, not the LinkedIn way

1. **Vouches anchor to artifacts.** Not "endorse Maria for Rust"
   but "endorse Maria for Rust *on the evidence of these documents
   and reviews she produced*." The claim and its evidence are PROV
   in the same system.
2. **Weight is the endorser's verified history in that domain.**
   A vouch from someone whose own endorsed work in the area keeps
   holding up counts; from anyone else it records but prices near
   zero. Zero-cost vouches are worth zero — LinkedIn's failure,
   solved by construction.
3. **One vouch per identity per claim, retractable.** No piling;
   skills decay honestly when the work moves on.
4. **Grade ladder for skills:** claimed → verified. The org view
   distinguishes the two — HR-clean and politics-safe.
5. **Existence ≠ visibility.** Team-scoped vouches stay
   team-visible; org-wide reputation is deliberate. Trust facts
   are politically sensitive; visibility is a first-class
   permission.

## What it buys

- **Expertise location with receipts** — the flagship query.
- **Reviewer/approver routing** by endorsement quality rather than
  manager of record.
- **Onboarding inherits the graph** — "who do I ask about X"
  becomes a query, not two years of social archaeology.
- **Audit trail** — who vouched for what, when, on what evidence;
  PROV for regulated industries.
- **FR-155 synergy** — multilingual orgs get canonical-per-language
  documents with human-reviewed grades instead of an untrusted
  translate button on compliance text.

## Honest caveats

- This is the **knowledge layer beneath** the communication tool,
  not a chat replacement. Nobody switches messaging for this.
- Work-weighting needs work artifacts in-system. If documents live
  in SharePoint, the anchoring breaks — hence either a standalone
  knowledge layer or an integration pitch, not a widget.
- Skill decay touches labor law and works councils in some
  jurisdictions; visibility rules must be designed before roll-out,
  not after.

## Relationship to existing FRs

- **FR-157** supplies the mechanisms: work-weighting, reputation
  computed from history, endorsement-is-not-annotation, the
  census lesson about populations.
- **FR-155 Stage A** supplies the wire shape: submit/endorse/
  unendorse/list over content-anchored claims with a grade ladder.
  A skills vouch is the same shape pointed at a (person, skill)
  claim instead of a rendition span.

## Open questions (deliberately unanswered)

- Identity import: Entra ID → clubs mapping, per-org IdP, SCIM?
- What counts as evidence: documents only, links, reviews,
  projects?
- Skill vocabulary: free-form tags vs curated ontology.
- Deployment: standalone product, Teams app, or middleware.
- Sequencing within the enterprise story: does sponsorship (teams
  vouching for work products) come before individual skills?
- The labor-law/works-council question above.

## Stage A — skills claims, the FR-157 way (BUILT 2026-10-31, branch fr158/skills-endorsement)

The sketch's first rung is real: a person files an evidence-anchored
skill claim, peers endorse it, the grade is derived. Self-claims only
in this stage; work-weighting stays future (the n>100 problem,
FR-157).

**Data model** (`server/skills.rs`): a `SkillClaim` is a person
saying "I have this skill, on the evidence of these works" —
`subject_club`, `skill` (normalized tag), `summary` (≤280 chars),
`evidence` (1..=8 refs: `work_id` hex + a `note` saying what about
it demonstrates the skill), `submitter_club`, `created_at`, and
riding `endorsements` (`club_id`, `timestamp` — unweighted by
design). The claim's **id is its content** (blake3 over everything
except endorsements): endorsements mutate the record, never the
identity, exactly the FR-155 Stage A pattern. `grade()` is derived,
not stored: no endorsements → `claimed`, any → `verified`.

**Tags are vocabulary-lite:** trimmed, lowercased, ≤64 chars, no
control characters or slashes (they become filenames). `Rust`,
`rust`, and ` RUST ` are one skill. Bounds: summary and evidence
notes ≤280 chars, 1..=8 evidence refs — a claim is a pointer to
evidence, not an essay.

**Durable layout** (`<data>/skills/`, atomic tmp+rename writes):
`claims/<xx>/<hash>.json` per claim, `by-club/<club>.json` and
`by-skill/<slug>.json` id indexes. Corrupt or tampered files
degrade to misses, never crashes — Stage 3 semantics inherited.

**Wire ops 0x0f34–0x0f37** (`skill_claim_submit`, `skill_endorse`,
`skill_unendorse`, `skill_list`; next free op 0x0f38). Submit is
self-claims only — the payload's `subject` must equal the caller's
club, else "v1: self-claims only" — and every evidence `work_id`
must parse as hex **and** exist in the server (a dangling reference
can only arise from later deletion, which leaves it visible, never
a crash). Endorse/unendorse enforce the store's rules: two-person
rule (the subject cannot endorse their own claim), one endorsement
per identity, retractable; retraction drops the grade back to
`claimed`. List requires exactly one filter — `club` (a person's
claims, best first) or `skill` (who claims it: the
expertise-location query) — and answers any connected session:
existence ≠ visibility stays the model for later scoping.

**Ordering** (`best_first`): verified before claimed, then more
endorsements, then newest — the comparator FR-155's `list_human`
initially got backwards, written correctly here.

**Claims are not content:** not addressable, not transcludable —
trust facts about people, riding their own structures, never the
annotation system.

**Not in this stage (deliberately):** no work-weighting (FR-157), no
visibility scoping, no curated vocabulary. (The UI followed
immediately as Stage A2 below; the graph stays v2, where
endorsement edges join the existing FR-22 `person` nodes in
`DocumentMapPanel`.)

## Stage A2 — the claims panel (BUILT 2026-11-01, branch fr158/claims-panel)

The panel is real: a "Skills" tab in the right panel (desktop and
phone tab strips), list-first, no graph — exactly the v1 call.

**Component** (`web/app/src/components/SkillsPanel.tsx`): two
in-panel views. *My claims* — auto-loads `skill_list` by the logged-
in club; "Claim a skill" opens the submit form (skill tag, optional
summary, optional evidence note, "cite open work" checkbox — v1
evidence is the work you have open, which is the honest anchor: you
claim the skill *on the evidence of this thing you made*). *Find by
skill* — the expertise-location query, no login required to read.

**Claim cards** render the whole wire shape: skill tag, grade badge
(grey `claimed`, teal `verified` — the derived ladder, visually),
summary, evidence chips (`0x<hex>` + title when resolvable from the
work list; click opens the work), endorsement count and endorsers,
date. Endorse/Retract follow the two-person rule and one-per-
identity by construction: your own claims show "your claim" instead
of a button, logged-out readers see "log in to endorse", and Retract
replaces Endorse once you have vouched. Errors from the server
(self-claims-only, evidence-not-found, tag bounds) surface inline.

**Client** (`api/crdt_sync.ts`): typed wrappers `skillListByClub`,
`skillListBySkill`, `skillClaimSubmit`, `skillEndorse`,
`skillUnendorse`; types in `api/protocol.ts` mirror the wire shape
one-to-one. 12 vitest cases cover the helpers (hex round-trip,
two-person rule, endorsement tracking), rendering, both mutation
paths, search-without-identity, evidence chips, and the
no-evidence guard on submit.

Still deliberately v2: graph edges (the map's person nodes exist;
endorsement edges would be a new edge type, not a new visualization),
work-weighting, visibility scoping.

**Deferred after live-panel use (2026-11-01):** claim edit/delete.
There is no update op and no delete op in Stage A — the claim's id
is the hash of what it says, so a changed claim is a different
claim; today the fix path is filing a corrected claim alongside.
The natural next op (0x0f38 is free) is **claim retract**: the
subject may retract their own claim, but only while it has zero
endorsements — once someone vouched, it is social fact, not just
the subject's assertion (the two-person rule's symmetry). A
`supersedes` field would let a corrected claim point at the one it
replaces. Found the hard way: a user filed a claim, then asked how
to update it.
