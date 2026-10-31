# FR-158: The enterprise knowledge fabric — Gold-lineage trust for the workplace

**Status:** sketched 2026-10-31. Idea capture, no build commitment.
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
