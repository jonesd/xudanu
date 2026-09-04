# FR-56: Address Realms — Terminology and the Space Algebra

- **ID:** FR-56
- **Status:** Active — umbrella term **found in the Gold source**:
  *coordinate space* (class comment, `CoordinateSpace.st`); Roger
  confirmation still queued
- **Depends on:** none (definitional); feeds FR-55 (CrossSpace
  compounds), FR-38 (span keys), federation addressing
- **Gold reference:** the `Xu*Space` / `XuMapping` class family
  (`src/image/st.dir/` — 79 Xu-prefixed classes)

## 1. Why this FR exists

We named our position-algebra module `src/space/`. Roger, reviewing
our direction, made clear that *whatever the general concept is, our
"space" naming is not the term Gold used for it* — without (as
remembered) supplying the replacement word. Rather than guess, this
FR pins what we actually know from the Gold source, fixes our
working vocabulary, and leaves one open question explicitly for the
next Roger conversation.

## 2. What the Gold source actually shows

Gold's class-level vocabulary **does** use "Space" — heavily and
deliberately — for exactly the address-realm concept our module
implements:

| Gold class | Concept |
|---|---|
| `XuSequenceSpace` | hierarchical tumbler positions (`4.3.1.7.2`) |
| `XuIntegerSpace` / `XuRealSpace` | flat numeric realms |
| `XuIDSpace` | identity realm (work/document IDs) |
| `XuCoordinateSpace` | coordinate abstraction |
| `XuCrossSpace` | **product of two spaces** — the compound-doc key |
| `XuFilterSpace` | filtered views of realms |
| `XuMapping` family (`Cross`/`Sequence`/`Integer`Mapping) | translations between realms |
| `XuVoid`, `XuRegion`, `XuPosition`, `XuOrderSpec` | realm primitives |

So: **our class-level naming is faithful to Gold.** What remains
open is the *umbrella* term — the word for the general concept (the
way "enfilade" names the tree and "tumbler" the address). Candidates
from the literature and our own docs:

- **docuverse** — Nelson's term for the connected universe of
  documents (used in our `cross-server-demo` and network docs). Fits
  the *universe* level, maybe not the *algebra-realm* level.
- Something from Green-era discussion Roger carries — unknown to us.

**Found (FR-56 research): the team's general term is "coordinate
space."** The `CoordinateSpace` class comment says, verbatim:

> "A coordinate space represents (among other things) the domain
> space of a table. Corresponding to each coordinate space will be
> a set of objects of the following kinds: Position — the elements
> of the coordinate space. Mapping — … OrderSpec — the ways of
> specifying partial orders of this coordinate space's Positions.
> XuRegion — an XuRegion represents a set of Positions. The domain
> of a table is an XuRegion."

So the concept is not bare "space" — it is **coordinate space**, and
it arrives as a *family*: each realm co-defines its Position,
Region, Mapping, and OrderSpec kinds (the comment: "one generally
defines new corresponding subclasses of each"). This is very likely
Roger's distinction: our `Space` trait names the class level fine,
but the *concept* he knew is "coordinate space," tables' domains.
(Also note: "the domain of a table is an XuRegion" — Table is the
consumer concept; the spaces exist to be table domains.)

**Confirm with Roger next conversation:** that "coordinate space"
is the term he meant; record any nuance here.

## 3. Our working vocabulary (fixed until Roger answers)

| We say | Means | Gold anchor |
|---|---|---|
| **realm** (this FR's umbrella word) | any addressable position domain | the `Xu*Space` family collectively |
| `Space` trait/struct suffix | a concrete realm implementation | matches Gold's class naming — keep |
| `CrossSpace2<A, B>` | product realm (compound positions) | `XuCrossSpace` |
| mapping | realm → realm translation | `XuMapping` family |
| arrangement | composed mapping over a document | `Arrangement` / `ExplicitArrangement` |
| tumbler | hierarchical address within `SequenceSpace` | `XuSequence`/tumblers |
| docuverse | the universe of all documents, all realms | Nelson's term |

Rule: **no renames of existing Rust modules** until the Roger
question is answered — the current naming is defensible either way,
and churn without the real term buys nothing.

## 4. Import goals

Ported and present (`src/space/`): `CrossSpace2` + `Tuple2` +
`CrossRegion2` + `CrossDsp2` + `CrossOrder2` (cross.rs), the mapping
family — `Simple`/`Composite`/`Constant`/`Empty` (mapping.rs),
`Arrangement` (arrangement.rs), the N-dimensional generalization
(`cross_n.rs`, `DynPosition`), `Sequence` (sequence.rs), bridges
(edition/space_bridge.rs).

Remaining imports, in value order:

1. **Wire-up, not code** — the algebra exists but almost nothing
   consumes it; FR-55 (compounds) is the first real consumer
2. `XuFilterSpace` equivalent — filtered realms; pairs with canopy
   queries (FR-52) for pruning transclusion search
3. `XuCoordinateSpace` abstraction — only if a second realm
   consumer appears (avoid speculative generality until then)
4. `MappingCache` — Gold cached composed-mapping lookups; relevant
   once arrangement walks are hot (FR-55 H2 will tell us)

## 5. Use inventory (why realms earn their keep)

- **FR-55 compound documents** — cross-realm positions are the
  addressing scheme (`(doc tumbler, char pos)`)
- **FR-38 span keys** — `SequenceSpace` positions; the bridge from
  tumbler strings to allocation keys
- **Federation addressing** — cross-server refs are realm
  coordinates; clean exchange needs the vocabulary fixed first
- **Beams/Origin UI** — arrangement walks replace excerpt search
- **Overlays (issue #15 review)** — if layers key into a base,
  they're mappings; this FR's vocabulary is the review's language

## 6. Action items

- [ ] Next Roger conversation: ask the umbrella-term question
      directly; record the answer in §2 and update §3 if needed
- [ ] FR-55 H2 consumes `Arrangement` — its ergonomics report feeds
      any mapping-family gaps (§4.4)
- [ ] Keep this FR as the single terminology reference; new code
      docs link here instead of re-deriving the vocabulary
