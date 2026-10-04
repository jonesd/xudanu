# Xudanu — Quick Start

Xudanu is a hypertext document store in the Xanadu lineage: documents
connected by **typed, bidirectional links** (visible from both ends),
quotation by **transclusion** (live windows onto sources, not copies),
and per-span cryptographic **provenance**. One binary, no
dependencies.

## Run it (60 seconds)

```bash
./xudanu-server run 127.0.0.1:8080 demo-data \
    --edit-policy public-sandbox --seed-links-demo
```

Then open **http://127.0.0.1:8080** in your browser.

The seed flag creates two guided tours (Trails panel):
**The Curator's Tour** — ten rooms of unusual connections, every
exhibit the thing itself — and **The Links Course** — five lessons
from the simple link to gathered end-sets, each with a task you can
do right there.

## The one demo that matters

1. Create a new work. Write a claim: `The funculator must be titanalum.`
2. Create a second work. Write a criticism: `Titanalum is too expensive.`
3. In the criticism, select text → create a link → target the claim → type: **disagreement**.
4. Open the claim. The criticism is already there — nobody edited it.

Connections visible from both ends: the thing the web never shipped.

## Also included

- `xudanu-cli` — WebSocket client for scripting the server
- `xudanu-mcp` — MCP server (agents read, quote by transclusion, and
  link into the docuverse with signed LLM authorship):
  `xudanu-mcp --server ws://127.0.0.1:8080 --enable-agent-writes`
- `xudanu-verify` — offline integrity checker for a data directory:
  `xudanu-verify demo-data`
- `dist/` — the web frontend (serve with `--static-dir dist`)

## Notes

- `--edit-policy public-sandbox` lets anyone connect and edit — for
  local demos. Use `owner-only` (default) on anything exposed.
- Data lives in the directory you name (`demo-data`). Wipe it and
  re-run with the seed flag to reset the demo.
- Docker: `docker compose -f docker-compose.demo.yml up` from the
  repository.

## More

- Hosted read-only showcase: https://xudanu.com
- Live public sandbox: https://demo.transclusion.org
- Documentation: https://dgjones.info/xudanu/
- Source and releases: https://github.com/jonesd/xudanu

License: Apache 2.0, with portions derived from Udanax Gold (MIT/X11)
— see LICENSE and NOTICE in this archive.
