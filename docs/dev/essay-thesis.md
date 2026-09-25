# The retry essay's core thesis (captured September 2026)

**The essay is not about Xanadu. Xanadu is the lab conditions.**
The claim is about the LLM accelerant — and this corpus is the
perfect experiment because it is maximally hostile (45 years old, a
dead paradigm, 550k lines of idioms no living team speaks) and
verifiable (conformance vectors, a running oracle, behavior you can
check).

## Three independent measurements, same corpus

1. Roger Gregory, deliberate: four days for lock-step C and Rust
   ports, value-for-value against the Pharo oracle (his "Six
   Implementations of Xanadu", Sept 2026).
2. Us, product-scale: weeks to migrate the 1992 C++ to Rust; five
   months total to a live system — one person, real domain, 3,700+
   tests.
3. Us, archaeological: winfe's 130 gzip'd 1992 Borland OWL files
   understood in an afternoon (the underwriting frontend nobody had
   opened in 30 years).

## The multiplier is a spectrum, not a number

reading (~100x) > translation (~50x) > new systems (~5-10x) >
design judgment (barely) > users (not at all). The honest essay maps
the spectrum; it does not sell one number.

## What was actually built (the three-column ledger)

- Migrated (weeks): the substrate — tumblers, region algebra, clubs.
- Built from scratch, no Gold ancestor: the entire web frontend
  (47k lines TS), CRDT real-time collaboration (which REPLACED
  Gold's grab/release model rather than porting it), cryptographic
  provenance, federation as shipped, web shadows, exhibitions,
  trails-as-UI, deployment.
- Borrowed theory (45 years, theirs): the design that makes both
  halves coherent.

## The line the piece turns on

The design was complete decades ago and provably buildable — what
it waited for was a cost curve it could afford. In 2026 the curve
crossed under it: a 45-year-old vision, paid for long ago, became a
small team's year. The question the essay leaves the reader with is
not "why did Xanadu fail" but "what else is sitting finished in the
literature, waiting for its curve."

(Draft framing note: open on the minus: bug — a 1992 transliteration
bug surviving every faithful translation, found by re-derivation,
confirmed by a third implementation over a live curl. It is the
whole thesis in one anecdote: what the accelerant changes, and what
only judgment changes.)
