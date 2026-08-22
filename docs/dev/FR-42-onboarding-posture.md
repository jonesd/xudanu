# FR-42: Onboarding, Identity Claiming, and Server Posture

Status: draft · Date: 2026-08-22
Builds on: FR-33 (identity), FR-39/40 (links as claims), FR-3
(federation), FR-6/31 (cross-server directory + sharing), FR-41
(network demo; manual ch.1).
Trigger: live user-testing session (2026-08-22) — every confusion we
hit (title vs first-line, stub duplication, private-vs-public
visibility, where mentions land) was an onboarding failure, not a
feature gap.

## Why

Xudanu servers boot into one of several very different lives — a
personal notebook, a community, a department inside an organization
— but the software treats all of them the same and asks nothing.
The consequences, observed first-hand:

- Person-pages fragment (three "David G Jones" nodes in one session:
  the bio page, the mention-created stub, the retitled manual
  attempt) because nobody tells users the title IS the identity
- Multi-user servers offer no guidance on claiming a name before
  someone else (or accident) defines it for you
- The relationship between a server and the network — island,
  member, cluster, org-hybrid — is configured through scattered
  flags and admin ops with no shared concept, though the machinery
  all exists

Onboarding is also the demo's "new user experience" beat: guiding a
fresh user live, from signup to a working home page with their first
mention, is a compelling 60-second story.

## The posture model

Two axes, decided (or deferred) once, shaping everything else.

**Axis 1 — who writes here:**

| | Personal instance | Shared instance |
|---|---|---|
| Examples | laptop server, xudanu.com-as-mine | team, class, community |
| First-run questions | server name, your identity | + signup open/invite-only, edit policy |
| Home page | valuable (canonical cross-server node) | essential (mention anchor, anti-squat) |
| Defaults | EditPolicy owner-only | explicit choice, public-sandbox warning shown |

**Axis 2 — relationship to the network:**

| Posture | Directory | Search fans out to | Content flows | Org analogy |
|---|---|---|---|---|
| Island | empty | nobody | nothing | personal notebook, air-gapped lab |
| Network member | trusted public peers | all trusted peers | published works searchable; transclusions cross servers | the open docuverse |
| Federated cluster | FR-3 peers (dial-in, PBFT sync) | cluster + selected external | replication within cluster | departments on a backbone |
| Org hybrid | cluster + curated external trust | cluster always, external opt-in | intra-org free, inter-org deliberate | dept servers + corporate gateway |

Key design fact: federation (FR-3) and directory trust (FR-6/31) are
different relationships that compose. An org wants to say once: "we
are Dept-X, in Corp-Cluster; we trust the gateway and two public
servers; nothing else" — and have signup, search, sharing, and
egress follow.

Governance honestly surfaced, not decided by the wizard: on shared
servers, who may add trusted servers, who may publish to the
network, whether home pages are org-visible-only.

## Stories

### S0 — First-run posture wizard (frontend + small server)
- Admin-first-boot flow: Axis 1 (personal/shared) → Axis 2 (island/
  member/cluster/org-hybrid, with "decide later" = island)
- Persists: EditPolicy default, signup openness, a posture record in
  server settings (new, tiny); org-hybrid composes existing
  cluster + directory config into one summary screen
- Re-runnable from Settings ("Server posture")
- Acceptance: fresh boot → wizard → correct EditPolicy + posture
  record; changing posture later re-renders the summary from real
  state

### S1 — Guided identity (frontend)
- Post-signup step: display name (the exact mentionable form),
  optional photo — reuses identity panel, surfaced first
- Acceptance: new user lands on identity step before editor; name
  matches what will title their home page

### S2 — Home page auto-creation (frontend + server assist)
- One click creates a Person-kind work: title = display name (set
  explicitly, never first-line extraction), template body (bio +
  "mentioned in" explainer), owned by the identity club
- Server assist: new op or extension — `work_create` + kind + owner
  binding done atomically; rejects duplicate Person-work with same
  title owned by a DIFFERENT club (anti-squat for the window before
  key-claims ship)
- Shows the exact-match caveat inline: "Mentions of this exact form
  link here. Variants create separate pages."
- Acceptance: signup → home page exists, correctly titled, kind
  Person, owned; second user attempting same title as their own home
  page gets a collision explanation, not a silent stub

### S3 — Mention walkthrough (frontend)
- Interactive 30-second step: type your name in a scratch doc →
  select → Mention → toast explains found-vs-created → backlink
  visible on the home page
- Acceptance: completing onboarding leaves the user having
  experienced the mention round-trip once, guided

### S4 — Network posture screens (frontend)
- Island: nothing (default)
- Member: directory intro, trust guidance, link to manual ch.1
- Cluster: status of peers, sync health
- Org-hybrid: combined view — cluster + external trust + egress
  summary; admin controls for "who may add trusted servers / publish
  externally"
- Acceptance: each posture renders a truthful summary from live
  state; admins can change trust/publish policy from it

### S5 — Mention notifications (server + frontend)
- Local push first: backlink lands on a work you own/follow → WS
  event or backlink-diff poll → toast/unread badge on Connections
- Cross-server later (companion to FR-41's network layer): a
  mention on a peer server notifies the subject's home server via
  the hardened backlink-notify path, filed as a remote backlink
- Acceptance: mention from a second account produces a visible
  notification without the subject opening the page

### S6 — Key-claimed person pages (server + frontend)
- A person-work may declare "I represent the holder of key K" with
  a signed claim; accounts claim their own pages; mention-time key
  verification marks mismatches (visible, not blocking)
- Cross-server resolution: origin's signed identity validates remote
  claims (FR-39 metalink lineage)
- Acceptance: impostor page with same title shows a key-mismatch
  marker; claimed page shows a verified badge; claims survive
  checkpoint


## Server-setup integration (operator onboarding)

The same wizard doubles as **server setup** for non-personal
instances — triggered server-side, not just in the app:

- **First boot of a fresh data dir** (the `Initializing new data
  directory` path in xudanu-server): server records
  `posture_pending = true` in settings; the next admin-capable
  browser session lands on the wizard automatically
- **CLI parity**: `xudanu-server setup` subcommand runs the same
  questions in the terminal (personal/shared, island/member/cluster/
  org-hybrid, admin identity) — writes the posture record so
  headless/VPS deployments get the same defaults without a browser;
  flags like `--posture personal-island` skip it entirely for
  scripted installs
- **Deployment presets** map to the table: docker-compose examples
  gain `POSTURE=org-hybrid`-style env vars composing cluster +
  directory + signup policy in one declaration
- The existing `init | verify | preflight` subcommands sit beside
  `setup` naturally; no new lifecycle concepts

Why it matters: an organization standing up a department server
should never meet a generic default that silently publishes or
opens signup; the posture question is asked exactly once, at the
moment with the most context (setup), and everything else —
EditPolicy, directory openness, egress guidance — follows from the
answer. Personal instances can dismiss in one click ("just me,
keep it private"), which is the honest fast path.

## Sequencing

S0+S1+S2+S3 are the onboarding core (one wizard, reuses existing
ops; S2's anti-squat check is the only new server rule). S4 composes
existing network state into screens. S5/S6 are follow-ons — S5
local-push is an afternoon; S6 is the crypto layer from the
identity-claiming discussion.

## Non-goals

- Global name resolution / a naming authority — key-claims (S6) are
  the mechanism, world agreement is out of scope
- Moderation tooling (rename/merge of squatted pages stays an admin
  manual action; note for a future FR)
- Cluster creation UX beyond summary (FR-3's CLI flow stands; the
  wizard links to docs)

## Heritage note

Person-as-page is LM 93.1's entity model; key-claims are its Author
metalink with modern crypto; the org-hybrid posture is Xanadu's
original "system of systems" shape (front-end/back-end hierarchies)
reborn as federated departments.
