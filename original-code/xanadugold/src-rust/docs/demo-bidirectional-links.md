# The 90-Second Xudanu Demo: Bidirectional Links

Everything below runs from a single downloaded binary — no Node, no
build, no dependencies. Serve it to a friend or run it on a whim.

---

## 1. Run it

Download a release binary for your platform (macOS, Linux, Windows)
from the releases page, extract it, then:

```sh
./xudanu-server run 127.0.0.1:8080 demo-data \
    --edit-policy public-sandbox --seed-links-demo
```

(Windows: `xudanu-server.exe run 127.0.0.1:8080 demo-data
--edit-policy public-sandbox --seed-links-demo`)

The `--seed-links-demo` flag creates the **Links Course** — a small
corpus of lesson documents pre-connected with typed links. It is
idempotent: wipe `demo-data/` and restart to get a fresh copy.

> The `--edit-policy public-sandbox` setting lets anyone connect and
> edit. That is what you want for a local demo. Do not expose a
> public-sandbox server to the internet.

## 2. Open the browser

Go to **http://127.0.0.1:8080**. You get the built-in editor: a work
list on the left, the editor in the middle, and a connections panel
showing every link that touches the document you have open — in both
directions.

**Start with the Trails panel.** The seed includes two published
tours: **The Curator's Tour** (ten rooms of unusual connection —
every exhibit is the thing itself) and **The Links Course** (five
lessons from the simple link to gathered end-sets, each with a live
demonstration and a task you can actually do here, ending in a
sandbox). On the hosted read-only instance
([xudanu.com](https://xudanu.com)) the same tours, and the live sandbox
at [demo.transclusion.org](https://demo.transclusion.org) has them
doable are walkable but
the tasks are frozen — run locally (or on the sandbox host) to do
them.

Opening any Links Course lesson shows connections arriving from the
other lessons: those are backlinks — links other documents made *to*
this one, visible here even though Lesson 1 was never edited to
contain them.

## 3. The wow moment (do it yourself)

1. Make a work and put a claimable sentence in it — say,
   `The grip assembly must be forged titanium.`
2. Make a second work that disputes it on cost:
   `Sintered steel is plenty, and a fifth of the price.`
3. In the second work, select the dispute, click Link, aim it at the
   first work, and type it **disagreement**.
4. Reopen the claim. The objection is sitting in its connections panel,
   typed and clickable.

*(The disputed-material-claim shape of this demonstration descends from
the classic Xanadu demos — retold in "The Open Society and Its Media",
§16.10, "The WidgetPerfect saga". The sentences used here are ours.)*

Nobody edited the claim document. The critic had no write access to
it. The connection is visible from both ends anyway. Click it in
either document; delete it from either end and it vanishes from both.

**That is the difference from the web.** On the web, a link is a
one-way string stored inside the citing page — the cited page never
knows it exists. In Xudanu, a link is an edge record in a server-side
index that both documents are registered against. Readers of either
end see it; critics can attach commentary to anything they can read;
and the link type (comment / reference / disagreement / quotation /
see-also) tells the reader what kind of connection it is before they
follow it.

## 4. What is happening under the hood

- Links are **first-class server records** (`HyperLink`: named end
  sets, type, provenance chain) — never markup inside either document.
  This is what Ted Nelson's project called *extrinsic* linking.
- The server maintains an index (`work_to_links`) registering every
  link against **every work it touches** — both ends.
- When any document opens, the client asks one question over the
  WebSocket: *what touches this work?* The same query answers
  outbound links and backlinks.
- Every link creation is signed into the provenance chain, so "who
  connected this to that" is part of the record.

## 5. Going further (optional)

- **Transclusion**: quote a passage of one document *by reference*
  into another; edit the source and the quote reports its own
  staleness with the original recoverable from the pinned revision.
  (Create a link with type `quotation` between two works, then edit
  the source work and reopen the quoting one.)
- **The full web app**: the embedded editor covers this demo; the
  React app (`web/app/` in the repository) adds the docuverse graph,
  compare panels, and provenance views.
- **Agents**: the same docuverse is exposed as an MCP tool source
  (`xudanu-mcp`), so AI assistants can quote by transclusion and
  comment by link — with every action signed.

---

One command, one browser tab, and the one feature the web never
shipped: connections visible from both ends.
