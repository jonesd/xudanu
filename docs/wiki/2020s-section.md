# Wiki draft: 2020s section (history article)

> Insertion target: the decades sequence, after the most recent
> existing decade section. Every sentence needs a citable source;
> placeholders marked [src].

## 2020s

The 2019 public release of the Udanax Gold sources on GitHub [src]
did not produce sustained development outside the original Xanadu
circle; the core developers had moved on by then, and the codebase —
approximately 550,000 lines of 1988–92 C++ idioms — remained
effectively undocumented for outside readers [src].

Two developments in the 2020s changed that accessibility barrier
rather than the design itself:

- Independent re-implementations of the core mechanisms began to
  appear, notably in Rust [src: repo] and Pharo [src: Gregory,
  "Six Implementations of Xanadu", 2026], with implementations
  cross-checked against each other via shared conformance vectors —
  including recovery of a transliteration bug present in the
  original 1992 arithmetic that every faithful port had silently
  inherited [src].
- Contemporary code-generation models made the historical sources
  navigable for the first time: reading, locating, and explaining
  45-year-old subsystems became practical for developers with no
  prior exposure to the codebase [src: Jones, "the LLM accelerant",
  2026 — attributed analysis, see companion draft].

One such effort, Xudanu (2026), migrated the Gold engine to Rust and
operates a public demonstration server [src: xudanu.com]. Its
operators report the migration at product scale — one developer,
five months to a live system with a 3,700-test suite [src] — which
they attribute primarily to machine-assisted comprehension of the
original sources rather than to any change in the underlying design
[attributed].
