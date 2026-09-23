# FR-79: The Web Overlay — Xudanu as the Connection Layer of the WWW

**Status:** Stage 1 specified, not started
**Created:** 2026-09-23
**Tradition:** Nelson's transquotation and the Little Transquoter
(2004–05, Andrew Pam): portion addresses on web pages, each excerpt
click-connected to its original context. This FR generalizes it into
a staged bridge, and accepts one permanent constraint up front.

## The permanent constraint (the pickle, accepted)

The WWW is presentation-first; Xudanu is content-first. **We never
reconcile layouts.** We anchor to content — excerpt + BLAKE3
fingerprint + context — and hang marks on other people's layouts
without importing them. Pages that resist anchoring degrade
gracefully: marks vanish, nothing breaks. We lose coverage, never
correctness.

The corollary discipline: every anchoring primitive we build must be
the same one the editor already uses (stale-offset excerpt recovery,
FR-38 span keys, content fingerprints). One anchoring contract,
exercised daily inside Xudanu, reused against the web. An anchor
that can survive a Xudanu revision can survive a page redesign.

## The strategic claim

The web will not migrate. The docuverse grows by **annotation, not
conversion**: every web page becomes a potential link end —
quotable, disputable, gatherable — while remaining a normal web
page to everyone else. The overlay is distribution; Xudanu's
semantics (typed two-way links, transclusion, cryptographic
provenance, federation) are the point. If the overlay ships only
highlights, we have re-built hypothes.is and lost; every stage
below must surface the semantics, not just marks.

---

## Stage 1 — Web shadows (server-side; no extension; ~days)

**Goal:** any fetched web page becomes a first-class work, so every
existing capability (typed links, gathered ends, compare, beams,
provenance) works on web content in our UI.

**What exists:** `web_fetch_sanitize` (SSRF-guarded, ammonia-
sanitized, 2 MB cap, `import_as_source` already creates a source
work). The gap is that imported pages are inert snapshots: no
identity across refetches, no public HTTP story, no license
provenance of their own.

### 1.1 The `web_shadow` op

```
WebShadow {
  url: String,                    // http(s), SSRF-guarded as today
  refresh: Option<bool>,          // re-fetch + re-anchor (default false)
  max_chars: Option<u64>,
}
→ WebShadowResult {
  work_id: BeId,
  content_hash: String,           // BLAKE3 of sanitized text
  final_url: String,              // post-redirect
  fetched_at: u64,
  anchor_revision: u64,           // which revision spans refer to
}
```

Semantics:
- First call creates a **shadow work** (kind: `web-shadow`) whose
  edition holds the sanitized text; the work records `source_url`,
  `content_hash`, `fetched_at` in work metadata.
- Idempotent by URL: second call returns the existing shadow.
- `refresh: true` refetches; if the text changed, a NEW revision is
  appended (never a mutation) — old spans keep `anchor_revision`,
  and the excerpt-relocation recovery re-anchors them onto the new
  revision where the text survives. Page redesign = a big edit.
- Shadow works are **readable by link**: linking into a shadow uses
  the same span machinery as any work; `jump_target` works.

### 1.2 Rendering shadows honestly

Shadow works display with a **banner**: "Live window onto
<final_url> — fetched <date>, content hash <…>. [Refetch]".
Readers must never mistake a snapshot for the live page.

### 1.3 Public HTTP surface (pairs with the content API)

`GET /api/public/shadow/{work_id}` — the text + metadata, so
external consumers (Stage 2's extension) can resolve marks without
a WS session. Standard caching headers keyed on content_hash
(ETag = hash; immutable within a revision).

### 1.4 Demo & exit criteria

One seeded gallery room: "Room 11 — The Disagreed Article": a real
web article as a shadow, one gathered Disagreement end on a passage,
opened in Compare. Exit criteria:
- [ ] shadow of a real article created, refetched after the source
      edits (or simulated), spans survive via re-anchoring
- [ ] link from a normal work into the shadow lands at the span
- [ ] public shadow endpoint serves the text with hash ETag
- [ ] integration tests: create/idempotent/refresh/re-anchor

### 1.5 Deliberately out of scope for Stage 1

Auto-refresh scheduling, robots.txt policy engine (manual fetch
only; the fetcher already identifies itself), paywalled content,
archival snapshots.

---

## Stage 2 — Read-only overlay extension (the real project)

**Goal:** see Xudanu marks on ordinary web pages. Breaks the
chicken-egg: one reader linking their own reading gets value with
zero network effect.

### 2.1 Architecture

- Browser extension (MV3; Chromium first, Firefox close behind)
- On page load, content script extracts the page's text spine
  (a readability pass in the extension, mirroring the server's)
- Asks a configured Xudanu server: `POST /api/overlay/marks` with
  `{ url, content_fingerprint }` → the marks whose target excerpts
  fingerprint-match this page (server does excerpt matching, never
  the extension — one anchoring implementation)
- Renders ribbons/margin bars in our visual language over their
  layout; hover shows type + far end; click-through opens Xudanu at
  the span

### 2.2 Anchoring contract (the heart)

Each mark carries: excerpt (≤ 200 chars), before/after context
(≤ 100 chars each), BLAKE3 fingerprints, link type, far-end tumbler.
Resolution order: exact fingerprint match → excerpt+context search →
excerpt search → unresolved (hidden, logged for the author). This is
the editor's stale-offset recovery, formalized for a page we don't
control. Failure is silent-by-design; a mark that cannot prove its
passage does not render.

### 2.3 Server side (small)

`/api/overlay/marks` (public, cached per fingerprint) over existing
link data: for each link whose destination is a shadow of this URL,
return the mark descriptors. Rate-limited; no session needed.

### 2.4 Exit criteria

- [ ] marks render on 3 representative real pages (article, docs,
      blog) and survive a simulated edit of the page text
- [ ] zero render on pages with no marks; no errors on hostile DOMs
- [ ] click-through lands at the exact span in Xudanu
- [ ] extension passes store review hygiene (permissions minimal:
      activeTab + host permissions optional per-server)

---

## Stage 3 — Overlay authoring (selection → link)

Select text on any page → type picker → the extension ensures a
shadow exists (Stage 1 op through the public API with an auth token),
computes the anchor, creates the link. Authoring needs identity —
session tokens via the existing `/auth` surface. Gathered ends from
multiple pages; the overlay becomes a research instrument.

Exit criteria: a link made on a real page in the extension is
visible in the Xudanu UI within one round-trip, and on re-visiting
the page after minor edits, still renders.

---

## Stage 4 — Transpublishing (deferred, unchanged)

Reuse with provenance and Transcopyright micropayment hooks. Only
after a corpus worth reusing exists. See the transcopyright notes in
the lineage docs; nothing in Stages 1–3 forecloses it.

---

## Risks & standing answers

| Risk | Answer |
|---|---|
| Anchoring coverage < 100% | Accepted by design; graceful degradation, marks vanish not break |
| SPAs / canvas pages | Out of coverage initially; the contract fails closed |
| hypothes.is comparison | Semantics or death: typed links, two-way, transclusion, provenance — every stage ships them |
| Extension review / permissions | Read-only first; activeTab; per-server opt-in |
| Server load from overlay queries | Public endpoint, fingerprint-keyed cache, rate limits |
| Etiquette toward target sites | We fetch once and serve from our infra; marks are about pages, served from our servers; identify honestly |
| Legal (framing/rights) | Marks are commentary, not republication; transclusion of web text stays inside Xudanu views with source banners; Stage 4 exists for the licensed-reuse future |

## Iteration cadence

- **Iter 1 (Stage 1.1–1.2):** web_shadow op + banner + tests — the
  server can shadow.
- **Iter 2 (Stage 1.3–1.4):** public endpoint + demo room — the
  story is screenshotable ("a live window onto a real article, with
  my dispute hanging on it").
- **Iter 3 (Stage 2.1–2.2):** extension skeleton + anchoring
  resolver against staged fixtures — marks render on saved pages.
- **Iter 4 (Stage 2.3–2.4):** live server integration, three real
  pages, click-through.
- **Iter 5+ (Stage 3):** authoring; then reassess.
