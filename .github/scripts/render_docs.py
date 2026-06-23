#!/usr/bin/env python3
"""Render Markdown documentation to themed HTML for GitHub Pages.

Walks docs/**/*.md, converts each to <name>.html wrapped in the xudanu dark
docs theme, rewrites local .md links to .html, then removes the .md sources
from the deployed tree (so they are served as rendered pages, not plain text).
Existing hand-crafted .html docs are left untouched (only their .md links are
rewritten). Run from the repository root.
"""
import re
import sys
from pathlib import Path

import markdown

DOCS = Path("docs")
REPO_URL = "https://github.com/jonesd/xudanu"
BRANCH = "main"

BASE_CSS = """
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap');
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Inter',system-ui,-apple-system,sans-serif;background:#0d1117;color:#c9d1d9;line-height:1.7}
a{color:#58a6ff;text-decoration:none}
a:hover{text-decoration:underline}
.content-wrap{max-width:920px;margin:0 auto;padding:32px 32px 80px}
.topbar{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:4px;flex-wrap:wrap;gap:8px}
.breadcrumb{font-size:13px;color:#8b949e}
.breadcrumb a{color:#8b949e}
.breadcrumb a:hover{color:#58a6ff}
.edit-link{font-size:13px;color:#484f58}
.md-doc h1{font-size:32px;font-weight:800;color:#e6edf3;margin:8px 0 24px;letter-spacing:-0.5px;padding-bottom:12px;border-bottom:1px solid #21262d}
.md-doc h2{font-size:24px;font-weight:700;color:#e6edf3;margin:40px 0 16px;padding-bottom:8px;border-bottom:1px solid #21262d}
.md-doc h3{font-size:20px;font-weight:600;color:#e6edf3;margin:32px 0 12px}
.md-doc h4{font-size:16px;font-weight:600;color:#e6edf3;margin:24px 0 8px}
.md-doc h5,.md-doc h6{font-size:14px;font-weight:600;color:#c9d1d9;margin:20px 0 8px}
.md-doc p{margin:12px 0}
.md-doc ul,.md-doc ol{margin:12px 0;padding-left:28px}
.md-doc li{margin:6px 0}
.md-doc code{font-family:'JetBrains Mono',monospace;background:#161b22;padding:2px 6px;border-radius:4px;font-size:0.9em;color:#f0883e}
.md-doc pre{background:#161b22;border:1px solid #21262d;border-radius:8px;padding:16px;overflow:auto;margin:16px 0}
.md-doc pre code{background:none;padding:0;color:#c9d1d9}
.md-doc blockquote{border-left:3px solid #30363d;padding:4px 16px;color:#8b949e;margin:16px 0}
.md-doc table{border-collapse:collapse;margin:16px 0;width:100%;display:block;overflow-x:auto}
.md-doc th,.md-doc td{border:1px solid #21262d;padding:8px 12px;text-align:left}
.md-doc th{background:#161b22;color:#e6edf3;font-weight:600}
.md-doc tr:nth-child(2n) td{background:#0d1117}
.md-doc hr{border:none;border-top:1px solid #21262d;margin:32px 0}
.md-doc img{max-width:100%;border-radius:8px}
.md-doc a code{color:#58a6ff}
.codehilite{background:#0d1117;border:1px solid #21262d;border-radius:8px;margin:16px 0;overflow:auto}
.codehilite pre{border:none;background:none;margin:0}
.footer{margin-top:64px;padding-top:20px;border-top:1px solid #21262d;font-size:12px;color:#484f58;text-align:center}
.footer a{color:#484f58}
@media(max-width:640px){.content-wrap{padding:24px 16px 60px}.md-doc h1{font-size:26px}}
"""


def get_pygments_css() -> str:
    try:
        from pygments.formatters import HtmlFormatter

        return HtmlFormatter(style="github-dark").get_style_defs(".codehilite")
    except Exception:
        return ""


def rewrite_md_links(text: str) -> str:
    """Rewrite relative .md hrefs to .html (leave external http(s) links alone)."""
    pattern = re.compile(r'(href=")(?!https?:)(?!//)([^"]+?)\.md(#[^"]*)?(")')

    def repl(m: re.Match) -> str:
        return m.group(1) + m.group(2) + ".html" + (m.group(3) or "") + m.group(4)

    return pattern.sub(repl, text)


def derive_title(text: str, fallback: str) -> str:
    m = re.search(r"^\s*#\s+(.+)$", text, re.MULTILINE)
    if m:
        return m.group(1).strip()
    return fallback.replace("-", " ").replace("_", " ").title()


def render_markdown(md_path: Path) -> str:
    text = md_path.read_text(encoding="utf-8")
    title = derive_title(text, md_path.stem)

    md = markdown.Markdown(
        extensions=[
            "extra",
            "tables",
            "fenced_code",
            "codehilite",
            "toc",
            "sane_lists",
            "admonition",
        ],
        extension_configs={
            "codehilite": {"guess_lang": False, "css_class": "codehilite"}
        },
    )
    body = md.convert(text)
    body = rewrite_md_links(body)

    rel = md_path.relative_to(DOCS)
    depth = len(rel.parts) - 1
    index_link = ("../" * depth) + "index.html"
    source_link = f"{REPO_URL}/blob/{BRANCH}/docs/{rel.as_posix()}"

    return TEMPLATE.format(
        title=title,
        base_css=BASE_CSS,
        pygments_css=get_pygments_css(),
        index_link=index_link,
        source_link=source_link,
        body=body,
    )


TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title} &mdash; Xudanu Docs</title>
<style>
{base_css}
{pygments_css}
</style>
</head>
<body>
<div class="content-wrap">
  <div class="topbar">
    <div class="breadcrumb"><a href="{index_link}">&larr; Xudanu Docs</a></div>
    <div class="edit-link"><a href="{source_link}">Edit on GitHub</a></div>
  </div>
  <article class="md-doc">
{body}
  </article>
  <div class="footer">Xudanu Documentation &mdash; generated from Markdown</div>
</div>
</body>
</html>
"""


def main() -> int:
    if not DOCS.is_dir():
        print(f"error: {DOCS} directory not found", file=sys.stderr)
        return 1

    md_files = sorted(DOCS.rglob("*.md"))
    if not md_files:
        print("no markdown files to render")
        return 0

    for md_path in md_files:
        html_doc = render_markdown(md_path)
        out_path = md_path.with_suffix(".html")
        out_path.write_text(html_doc, encoding="utf-8")
        print(f"rendered {md_path.relative_to(DOCS)} -> {out_path.relative_to(DOCS)}")

    for html_path in DOCS.rglob("*.html"):
        original = html_path.read_text(encoding="utf-8")
        updated = rewrite_md_links(original)
        if updated != original:
            html_path.write_text(updated, encoding="utf-8")
            print(f"rewrote .md links in {html_path.relative_to(DOCS)}")

    for md_path in md_files:
        md_path.unlink()

    print(f"done: rendered {len(md_files)} markdown document(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
