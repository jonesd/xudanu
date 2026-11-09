# Xudanu as an infrastructure-agnostic hypertext

> This page maps Jakob Voß's formal model of hypertext (*Infrastructure-Agnostic
> Hypertext*, 2019) onto Xudanu's running implementation — element by element,
> including the four things his model deliberately excludes and why we
> implement three of them anyway. It is written for readers arriving from his
> paper who want to know: *does the model run?*
>
> Xudanu is an independent, open-source (Apache-2.0) system standing on the
> Udanax Gold code released openly in 1999 (MIT/X11). It is not affiliated
> with or endorsed by Project Xanadu, Udanax, or the author of the paper
> discussed here.

## The claim, briefly

Voß's paper strips hypertext to four content elements — **documents,
document identifiers, content locators, edit lists** — plus four functions
(retrieval, transclusion, assemble, segments-usage). His conclusion calls
for "an ecosystem of content locators and edit lists."

Xudanu is that ecosystem, running: every element and every function in his
model has a concrete, tested mechanism. The mapping is close enough to be
remarkable, given the implementation began from the Gold sources rather
than from his paper.

## The model in one table

| Voß's model | His requirement | Xudanu's mechanism |
|---|---|---|
| Documents (D) | finite digital objects | Works and editions in the O-tree, content-addressed by BLAKE3 fingerprint |
| Document identifiers (I) | reference documents; must not break | Domain-based tumblers — `"server.example".work.rev.edition` — self-routing via DNS, immutable once allocated |
| Content locators | reference segments; survive change | O-tree positions: immutable allocate-between addresses plus **span migration** through arbitrary edit deltas (excerpt search is a fallback, not the mechanism) |
| Edit lists | combine parts of documents into new ones | Inline `RangeElement::Transclusion` in the CRDT itself; a document *is* its edit list — Nelson's inversion (documents built from links, not links between documents) |
| Retrieval R: I→D | get a document | `work_fetch_edition` wire op; public HTTP read API; cross-server fetch with BLAKE3 verification |
| Transclusion T: S→D | get a segment | Recursive resolution, 32 levels, cycle detection; version-pinned with recorded content hashes |
| Assemble A: E→D | execute an edit list | Compound resolution with generation-stamped caches; trails materialize as real derived editions, generation-checked against their sources |
| Segments-usage U: E→P(S) | backlinks | Bidirectional links tracked at both ends; BackfollowEngine answers "which works contain this passage" in O(log n); signed cross-server backlink notifications |

## The part his model says is hardest

Two challenges his paper names explicitly:

**"OpenXanadu uses plain URLs … but these links may break."** Xudanu's
answer is structural rather than probabilistic. Identifiers are tumblers
allocated by the never-renumber rule (new addresses are always minted
*between* existing ones); locators are O-tree positions that migrate with
edits instead of being re-resolved after them. The behaviour is held in
place by the backend test suite (3,883 tests as of this writing), including
migration through arbitrary deltas to both ends of a connection. A related
detail: all text is NFC-normalised on entry, so the same visible passage
produces the same BLAKE3 fingerprint on every platform — content identity
does not depend on the author's operating system.

**"Support of edit lists in editing tools."** In Xudanu the edit list is
not a format an editor must be taught to read; it *is* the document model.
Placing a transclusion inserts an inline element into the same CRDT the
editor types into; editing, persistence, replication, and resolution all
operate on one structure. The editing-surface problem his paper defers is
solved by never leaving the model.

## The four exclusions, answered

His model deliberately brackets out four things Project Xanadu promised.
Here is where Xudanu stands on each, and why:

| Exclusion | Xudanu | Reasoning |
|---|---|---|
| (a) Identified servers as canonical sources | **Implemented** | Server-anchored tumblers plus BLAKE3 content verification plus Ed25519 server identity. His paper suggests "blockchain or other trusted logfiles" for canonical sources; we use signature chains and content hashes — no ledger needed. Agnosticism here would trade verifiability for generality, and verification is the property cross-server reuse cannot give up. |
| (b) Identified users, access control | **Implemented** | Sessions, clubs (the Gold permission model, translated), per-user annotations with server-side privacy enforcement, per-span cryptographic authorship. Provenance without authors is decoration. |
| (c) Royalties via micropayment | **Declined, deliberately** | The server records usage — byte counts on every cross-server fetch (`record_royalty`), the accounting Nelson's scheme needs — but never handles money, by hard design rule. Licensing is honoured as metadata (per-work licenses including Transcopyright, FR-24). His exclusion is our design constraint. |
| (d) User interfaces | **Implemented — twice, plus a browser overlay** | The wire protocol is pinned (`api_version` 1, frozen additive-only op table), which is infrastructure-agnosticism taken literally: any client may be built against it. Two first-class clients exist (the workspace; a read-only parallel-documents client in the '72 reading posture), plus a browser extension that renders a document's marks on ordinary web pages. |

## Where we are less agnostic — honestly

His model permits an edit list to live anywhere, including as a plain file;
Nelson's current zanadoo line ships exactly that shape. Xudanu's documents
live on servers. That is a real reduction in agnosticism, and it buys
specific properties: live resolution against the current corpus, span
migration computed against the real edit history, backlinks across every
work on the server, and cross-server reuse verified at fetch time. The
file-shaped and corpus-shaped versions share one content model; the
difference is where the resolution happens. We consider that a fair trade
for now, and the wire contract keeps the door open: a file-resident client
of the frozen protocol could exist.

## For research use

The system is self-hostable (one container), scriptable over WebSocket or
MCP, and its claims are testable rather than aspirational. For anyone
working with Voß's model, the interesting experiments are direct: seed a
corpus, break links on purpose, watch migration hold or not. A companion
design probe — seven renderings of the parallel-document reading posture,
from the 1972 figure to a dimension rail — is at
[transpointing-variants](https://dgjones.info/xudanu/transpointing-variants.html)
(once deployed; also in the repository under `docs/`).

## References

- Voß, Jakob. *Infrastructure-Agnostic Hypertext.* arXiv:1907.00259, 2019.
- Voß, Jakob. *An Infrastructure-Agnostic Model of Hypertext.* Poster,
  ACM Hypertext and Social Media (HT '19), 2019. DOI 10.1145/3342220.3344922.
- Udanax Gold (Xanadu 92.1) source release, 1999. MIT/X11. The lineage of
  translated modules is recorded per-file in the Xudanu repository (NOTICE).
- The Xudanu documentation set: <https://dgjones.info/xudanu/>
