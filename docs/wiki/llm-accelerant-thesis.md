# Wiki draft: the LLM-accelerant thesis (attributed analysis)

> Target: one paragraph in the 2020s section or a "Reception /
> Modern analysis" note. Written in attributed voice — Jones (2026)
> argues — never wiki voice. Doubles as the abstract skeleton for a
> short paper or essay; keep the evidence triple and the falsifiable
> form.

## Machine-assisted accessibility of historical codebases (attributed analysis)

Jones (2026) argues that the 2020s accessibility shift for legacy
hypertext systems came not from renewed human documentation effort
but from large language models used as comprehension accelerants on
the primary sources [src]. The claim is offered as a cost-curve
argument: the Xanadu designs were complete and arguably buildable
decades earlier; what changed is that reading, locating, and
explaining an unfamiliar 45-year-old codebase — historically the
binding constraint for outside developers — fell in cost by orders
of magnitude.

Three independent measurements on the same corpus are cited:

1. **Deliberate porting** (Gregory 2026): lock-step C and Rust
   implementations, value-for-value against a Pharo oracle, in four
   days [src].
2. **Product-scale migration** (Jones 2026): the 1992 C++ engine
   migrated to Rust in weeks; a live multi-user system five months
   later — one developer, 3,700+ tests [src].
3. **Archaeology** (Jones 2026): an unrelated 1992 Borland OWL
   frontend (~130 files) understood to summary level in an
   afternoon [src].

The proposed multiplier is stated as a spectrum, not a number:
reading (~100×) > translation (~50×) > new-system construction
(~5–10×) > design judgment (unaffected). Cross-implementation
conformance vectors are offered as the verification mechanism that
keeps the accelerant honest — including the recovery of a 1992
transliteration bug that every faithful translation had silently
inherited, found by re-derivation rather than reading [src].

The general form, as posed: other finished-but-unbuilt designs may
exist in the literature, waiting on a cost curve rather than on new
ideas [src: essay].
