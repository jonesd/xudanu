# Outreach emails — HT '26 authors
# DRAFTS — send AFTER arXiv is live (each links to the preprint)
# All three follow the same rule: lead with THEIR finding, not our
# system. 3 sentences max before the link.

---

## Email 1: Adamski & Błocki (H(G) profile)

**To:** [adamski / blocki at their Polish universities]
**Subject:** H(G) profile on a transclusion-bearing corpus — first nonzero θ measurement

Dear Professors Adamski and Błocki,

We read your HT '26 paper on H(G) with interest, particularly the
invitation in §5.4 to "validate the profile against real corpora."
We have implemented the ten-coordinate profile as a subcommand in
an open-source hypertext system (Xudanu) whose document model
includes character-level transclusion, typed multi-ended links,
and per-passage cryptographic provenance. Running it on our corpus
produced what we believe is the first nonzero θ (transclusion)
measurement: θ = 0.041, ρrt = 1.0, η = 0.603, with full methodology
and JSON at [arXiv link, §4].

Our system also carries author-type labels (human / LLM / machine)
on every content element, which may be relevant to your open
question Q4 (H(G_AI) vs H(G_human)) — we would be happy to compute
additional profiles or share corpus data if useful for calibration.

With regards,
[name]

---

## Email 2: Millard (hypertextual friction)

**To:** D.E.Millard at soton.ac.uk
**Subject:** Your §7.3 design consideration — implemented

Dear Professor Millard,

Your HT '26 paper on hypertextual friction describes a system in
which "AI-generated proposals demand human curation before entering
the knowledge network," and notes in §7.3 that "systems for
scholarly knowledge work should encode provenance at finer
granularity than 'AI-generated' versus 'human-written'." We have
implemented exactly that granularity: per-span Ed25519 signatures
with a four-way author-type classification (human, LLM, machine,
historical), anchored to Bitcoin via OpenTimestamps, in an
open-source hypertext system descended from the Udanax Gold
codebase [arXiv link].

Our reference-over-copy suggestion loop — where the system detects
retyping of existing content and offers it as a live transclusion
— embodies your suggest-only pattern at the content-model level:
the curatorial accept/reject decision creates a signed, attributed
inclusion rather than a copy, and the decision itself is recorded
in the anchored provenance chain. We would value your read on
where the friction should live in such a system.

Best wishes,
[name]

---

## Email 3: Beaumont & Anderson (Seed Hypermedia)

**To:** [beaumont / anderson — check their preferred addresses]
**Subject:** Your "points of authority for provenance" — we built the anchor

Dear Gabo and Mark,

We read your Seed Hypermedia paper at HT '26 with close attention,
particularly §2.5: "hypermedia servers are not centres of control,
but points of authority for provenance, where authorship and
licensing are persistently maintained." We have built such a
provenance authority: per-passage Ed25519 authorship signatures,
a hash-chained attribution log, and Bitcoin-anchored chain heads
(OpenTimestamps) that give a trust-minimized existence floor for
the entire attribution history — all in an open-source system
implementing the Udanax Gold lineage [arXiv link].

Your conference experiment raises questions we are also working
through: how distributed nodes verify each other's provenance
claims, and how transclusion across federation boundaries carries
attribution. We would welcome the opportunity to compare notes,
or to explore whether Xudanu's anchoring layer could complement
Seed's federated document network.

Best regards,
[name]

---

## Notes on sending

- **Do not send until arXiv is live** — each email links to the
  preprint; a dead link kills credibility
- **Check institutional addresses** — verify email formats before
  sending (Anderson is likely at a UK institution; Adamski/Błocki
  at Polish universities per the paper affiliations)
- **The H(G) email is the fastest to send** — it responds to an
  explicit invitation (§5.4) and offers data, not a demo
- **The Millard email is the most strategic** — steering chair;
  his reply shapes whether the community sees us as contributor
  or outsider
- **The Seed email is the most collaborative** — positions us as
  a complementary layer, not a competing system; potential joint
  HT '27 submission
- **Anderson is the most approachable** — independent researcher,
  unfunded, used Claude for drafting; a technical email from a
  fellow builder will get a reply
