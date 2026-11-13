# Xudanu Overlay — Chrome Web Store listing & permissions audit

FR-79 Stage 2 store-review hygiene pass. Everything a reviewer (human
or automated) needs: single purpose, per-permission justification,
privacy statement, and listing copy.

## Single purpose

Show the user's own Xudanu marks (typed two-way links: comments,
references, disagreements, quotations) on the ordinary web pages those
marks point at. Read-only: the extension renders marks; it never
edits, collects, or forwards page content anywhere except the server
URL the user explicitly configures.

## Permissions, one by one

| Permission | Why | Reviewer note |
|---|---|---|
| `storage` | Remember two settings: the user's server URL and an enabled flag. Nothing else is stored. | Local only; not synced. |
| `scripting` | Register the content script (`chrome.scripting.registerContentScripts`) after the user clicks Enable on the options page. The script is read-only: it extracts page text and renders ribbons. | No `tabs`, no `webNavigation`, no `webRequest`, no history access. |
| `optional_host_permissions: http://*/*, https://*/*` | Marks can target any page the user has shadowed, and shadowed URLs cannot be enumerated in advance — the user chooses sites only by grant. Requested once, from the options page's Enable button, with Chrome's standard "read and change data on all websites" prompt. | The broad scope is inherent to the overlay use-case (same as similar read-only annotation extensions). The extension is inert before the grant: no content script is registered, nothing runs. The user can revoke per-site or entirely at any time; the extension degrades to doing nothing. |

What the extension deliberately does **not** use: `activeTab`
(insufficient — marks must appear on revisit without a click), `tabs`
(never needed — the content script reports its own URL), background
page (MV3 service worker, event-fired only), remote code (all code is
packaged; no `eval`, no fetched scripts).

## Privacy statement (for the store dashboard)

The extension sends exactly two things, only to the server the user
configures on the options page, only when a visited page is checked:

1. the page URL,
2. the page's extracted text (for anchor resolution, which happens
   server-side — the extension contains no anchor logic).

If no server is configured, or the overlay is disabled, nothing is
sent anywhere. The extension stores no browsing history, collects no
analytics, includes no third-party code or trackers, and does not
modify page content. Marks render on-screen only; they are never
written back to the page's site.

## Data usage disclosures (dashboard form)

- Personally identifiable information: none sold, none transferred to
  third parties, none used for creditworthiness or lending.
- Website content: the visited page's URL and text are sent to the
  user's own configured server for anchor resolution. Not sold, not
  used for unrelated purposes, not forwarded elsewhere.
- Authentication: none. The overlay is read-only against a public,
  rate-limited endpoint; no cookies, no credentials.

## Listing copy

**Name:** Xudanu Overlay

**Summary (132 chars max):**
See your Xudanu marks — comments, references, disagreements — on the
ordinary web pages they point at.

**Description:**

Xudanu is open-source hypertext with unbreakable two-way links. This
extension carries those links out to the regular web: visit a page you
(or your server's community) have marked, and your typed links appear
as colored ribbons in the margin — hover for the link type and the far
end, click to open the other side of the connection in Xudanu.

Read-only by design. Your Xudanu server resolves every anchor; a mark
that cannot prove its passage does not render. Nothing is sent
anywhere except the page URL and its text — to the server you
configure. Works with any self-hosted Xudanu server (or the public
demo at xudanu.com).

Setup: open the extension's options, enter your server URL, Test
connection, Enable. Apache-2.0. Source: github.com/jonesd/xudanu.

**Category:** Productivity

**Screenshots** (1280×800, in order): ribbons on a real article
(incoming right margin), the hover tooltip (type + far end), the
options page (server + Enable), click-through landing in Xudanu.

## Pre-submission checklist

- [ ] MANUAL-TEST.md walked end-to-end on the packaged (unpacked-dir)
      build, not the dev variant
- [ ] Version bumped; zip contains manifest.json, background.js,
      content.js, options.html, options.js, icons/
- [ ] Privacy policy URL hosted (dgjones.info/xudanu/privacy — page
      to be published with the listing) and set in the dashboard
- [ ] Screenshots captured (the harness writes shot-*.png as drafts)
- [ ] `web/extension` README linked from the repo's main README so
      reviewers can find the source of the packaged build
