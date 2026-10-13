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

1. **Deliberate porting** (Gregory 2026) — PRIVATE, DO NOT PUBLISH:
   lock-step implementations verified against an oracle. Source of
   the "conformance vectors" concept AND the "1992 transliteration
   bug recovered by re-derivation" anecdote — both are his result,
   learned in the private 2026 contact. Excluded from all public
   material per the xanadu-contact-history rule (2026-10-12).
2. **Product-scale migration** (Jones 2026): the 1992 C++ engine
   migrated to Rust in weeks; a live multi-user system five months
   later — one developer, 3,700+ tests [src].
3. **REMOVED (2026-10-12) — unusable:** the "unrelated Borland OWL
   frontend" archaeology item was likely a garbled winfe reference;
   David cannot source the session (confirmed 2026-10-12:
   "not sure where the Borland or winfe came from — skip it").
   Permanently excluded from public material.

**Replacement evidence (Jones 2026, repo-documented):** the splay
terminal-arms latent content-loss bug — IN OUR OWN FR-34 splay
implementation (design descended from Gold's access assumptions;
NOT a Gold-source bug — confirmed 2026-10-13 when David
challenged the provenance). Caught by measurement against the
model's guarantees, fixed, regression-tested; the same
measurement showed the splay unnecessary for our access pattern
(docs/dev/GOLD-VS-XUDANU.md S3). Plus the dual-write shadow
oracle catching merge-garbling defects F6/F10 (paper
skeleton §3). These carry the verification argument with
checkable provenance.

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
