# Xudanu Overlay — production-manifest manual walkthrough

FR-79 Stage 2's one unautomatable step: Chrome's native permission
prompt can only be dismissed by a human, so the production flow
(options UI → dynamic grant → registration → marks on a real page) is
verified by hand. Everything short of the prompt is covered by
`test/overlay.test.mjs` (which also caught and pinned the MV3
user-gesture rule that once broke this flow: `permissions.request`
must run in the options page's click handler, never in the service
worker).

Prereqs: a running Xudanu server with at least one web shadow (any
page you've fetched as a shadow and linked into — the E2E fixtures
work, but a real page is the point), and Chrome.

Serve the **current** front-end, not the embedded fallback — without
`--static-dir` the server answers with the legacy embedded pages:

```
cd web/app && npm run build     # once
cd ../original-code/xanadugold/src-rust
cargo run --features server --bin xudanu-server -- run 127.0.0.1:8080 \
  <data-dir> --edit-policy public-sandbox --csrf-token --allow-loopback \
  --static-dir ../../web/app/dist
```

Then seed a shadow to click through (`web/extension/test/seed.mjs`
does it against the fixtures; a real article needs a real fetch).

1. **Load the production extension.**
   `chrome://extensions` → Developer mode on → "Load unpacked" →
   select `web/extension/` (the directory with `manifest.json`, *not*
   the test variant). The install listener opens the options page.

2. **Save + Test connection.**
   Enter the server URL (e.g. `http://127.0.0.1:8080` or your
   deployment), Save, then Test connection. Expect the green
   "Connected — server is alive." (If not: is the server up? Does
   `/health` answer in a browser tab?)

3. **Enable — the gesture step.**
   Click "Enable overlay on sites". Chrome shows its native prompt
   ("Read and change your data on all websites"). Accept.
   Expect: "Overlay enabled. Reload any open tabs…" — the permission
   request ran in the click handler and the service worker registered
   the content script (check `chrome://extensions` → the extension →
   "service worker" console for errors; check that the registration
   exists via the worker console:
   `(await chrome.scripting.getRegisteredContentScripts()).length` → 1).

4. **See marks.**
   Open (or reload — registration only affects future loads) a page
   your shadows point at. Expect ribbons in the margin; hover shows
   type + far end; click opens the far side in Xudanu. Then visit a
   page with no shadow: no ribbons, no console errors.

5. **Disable and verify.**
   Options → Disable → reload the marked page: no ribbons.
   `chrome://extensions` → Details → "Site access": change to "On
   click" → reload: no ribbons (registration without grant correctly
   does nothing).

6. **Record.**
   Any deviation from the above is a bug against FR-79 Stage 2. A
   clean pass checks the manual box in `docs/dev/FR-79-web-overlay.md`
   (and the screenshots captured along the way feed STORE.md).
