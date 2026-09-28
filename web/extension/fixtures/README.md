# Overlay fixtures — manual extension test pages

Three representative real-page shapes for FR-79 Stage 2 exit
criteria (marks render on an article, a docs page, and a blog;
survive a simulated edit; zero render on pages without marks).

All three contain the same target passage — *"the funculator must
be duralum before first flight"* — in different typographic
contexts (blockquote, table cell, inline em), which exercises the
resolver's whitespace tolerance differently on each page.

## Manual flow

1. Serve the fixtures (the extension only runs on http/https):

   ```
   cd web/extension/fixtures
   python3 -m http.server 8899
   ```

2. Start a dev server with loopback fetches allowed:

   ```
   xudanu-server run 127.0.0.1:8080 data --allow-loopback
   ```

3. Shadow a fixture and hang a link on the passage (script does
   the shadow + link; it defaults to its own fixture page, but
   accepts any URL — or just create the link by hand in the app
   after shadowing via the app's fetch-by-URL):

   ```
   node examples/overlay.mjs "ws://127.0.0.1:8080/xudanu?format=json"
   ```

   …or, in the app: open the fixture URL's shadow, select the
   passage, connect your note to it with a Disagreement link.

4. Load `chrome://extensions` → Developer mode → Load unpacked →
   select `web/extension/`. Open the extension's options, set the
   server to `http://127.0.0.1:8080`, Test connection, Enable.

5. Visit `http://127.0.0.1:8899/article.html` — a blue ribbon
   should stand in the right margin at the passage; hover shows
   type + far end; click opens the work at the span. Repeat for
   `docs.html` and `blog.html`.

6. Simulated edit: edit the fixture HTML (insert a paragraph above
   the passage), reload — the mark must still render at the moved
   passage. Delete the passage entirely, reload — nothing renders.

## Hostile-DOM smoke

Open the browser console on each fixture after the marks render;
there must be no errors from the content script. On pages with no
shadow (any other site), the script does nothing visible.
