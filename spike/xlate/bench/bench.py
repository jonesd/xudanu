#!/usr/bin/env python3
"""Two-engine bake-off: Argos (LibreTranslate) vs NLLB-600M sidecar.

Stdlib only. Runs 12 German spans de->en through both engines,
2 passes (warm), times every call, captures container RSS, and
writes results.md + results.html (the side-by-side verdict page).
"""
import html
import json
import statistics
import subprocess
import time
import urllib.request
from pathlib import Path

HERE = Path(__file__).parent
ENGINES = {
    "argos": "http://127.0.0.1:5050/translate",
    "nllb": "http://127.0.0.1:5051/translate",
}


def post(url: str, q: str, source="de", target="en"):
    body = json.dumps({"q": q, "source": source, "target": target, "format": "text"}).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"})
    t0 = time.perf_counter()
    with urllib.request.urlopen(req, timeout=300) as r:
        out = json.loads(r.read())
    ms = (time.perf_counter() - t0) * 1000
    return out.get("translatedText", "<no translatedText>"), ms


def get(url: str):
    with urllib.request.urlopen(url, timeout=10) as r:
        return json.loads(r.read())


def rss():
    """MEM USAGE of the two containers via docker stats."""
    try:
        out = subprocess.run(
            ["docker", "stats", "--no-stream", "--format", "{{.Name}}\t{{.MemUsage}}",
             "xlate-spike", "xlate-nllb"],
            capture_output=True, text=True, timeout=20,
        ).stdout.strip()
        return dict(line.split("\t") for line in out.splitlines())
    except Exception as e:  # noqa: BLE001
        return {"error": str(e)}


def pct(xs, p):
    xs = sorted(xs)
    if len(xs) == 1:
        return xs[0]
    k = max(0, min(len(xs) - 1, round((p / 100) * (len(xs) - 1) + 0.5) - 1))
    return xs[k]


def main():
    spans = json.loads((HERE / "spans.json").read_text())

    # LibreTranslate silently dedup-caches identical requests (a
    # repeat hit returns in ~3ms). Restart it so pass 1 measures
    # FIRST-translation cost, not its cache. Honest instrument or
    # nothing — the whole spike is about that lesson.
    print("restarting xlate-spike to clear its request cache...")
    subprocess.run(["docker", "restart", "xlate-spike"], capture_output=True, timeout=120)
    for _ in range(60):
        try:
            get("http://127.0.0.1:5050/languages")
            break
        except Exception:  # noqa: BLE001
            time.sleep(1)

    health = {
        "argos": get("http://127.0.0.1:5050/languages") is not None,
    }
    try:
        health["nllb"] = get("http://127.0.0.1:5051/health")
    except Exception as e:  # noqa: BLE001
        raise SystemExit(f"NLLB sidecar not healthy: {e}")

    # Warmup with a throwaway string (unique, never reused) — model
    # paging and first-token latency, not measured.
    for url in ENGINES.values():
        post(url, "Sonde.")

    results = []  # {span, label, kind, de, {engine: {text, ms1, ms2}}}
    for s in spans:
        row = {"id": s["id"], "label": s["label"], "kind": s["kind"], "de": s["de"], "engines": {}}
        for name, url in ENGINES.items():
            text1, ms1 = post(url, s["de"])
            text2, ms2 = post(url, s["de"])
            row["engines"][name] = {"text": text1, "ms1": round(ms1), "ms2": round(ms2)}
        results.append(row)
        print(f"[{s['id']}] argos {row['engines']['argos']['ms2']}ms  nllb {row['engines']['nllb']['ms2']}ms")

    mem = rss()
    # Stats are FIRST-translation cost (pass 1). Pass 2 is reported
    # per span as the engine's repeat behavior (Argos's internal
    # dedup cache vs NLLB's full re-inference).
    stats = {}
    for name in ENGINES:
        firsts = [r["engines"][name]["ms1"] for r in results]
        stats[name] = {"p50": round(pct(firsts, 50)), "p95": round(pct(firsts, 95)),
                       "min": round(min(firsts)), "max": round(max(firsts))}

    payload = {"results": results, "stats": stats, "mem": mem, "generated": time.strftime("%Y-%m-%d %H:%M:%S")}
    (HERE / "results.json").write_text(json.dumps(payload, indent=2, ensure_ascii=False))

    (HERE / "results.md").write_text(render_md(payload))
    (HERE / "results.html").write_text(render_html(payload))
    print(f"\nwrote results.md / results.html / results.json  ({HERE})")
    print("stats:", stats, "mem:", mem)


def render_md(p):
    lines = [
        "# Engine bake-off: Argos vs NLLB-600M (de→en)",
        f"_generated {p['generated']} — 12 spans; stats are FIRST-translation",
        "cost (Argos restarted to clear its request cache; its repeat",
        "hits return in ~3ms from dedup cache — noted per span)_",
        "",
        "| engine | p50 | p95 | min | max |",
        "|---|---|---|---|---|",
    ]
    for name, s in p["stats"].items():
        lines.append(f"| {name} | {s['p50']}ms | {s['p95']}ms | {s['min']}ms | {s['max']}ms |")
    lines += ["", f"Container RSS: {p['mem']}", ""]
    for r in p["results"]:
        a, n = r["engines"]["argos"], r["engines"]["nllb"]
        lines += [f"### {r['label']}  `{r['id']}` ({r['kind']})", f"**DE:** {r['de']}", "",
                  f"**Argos** ({a['ms1']}/{a['ms2']}ms): {a['text']}", "",
                  f"**NLLB** ({n['ms1']}/{n['ms2']}ms): {n['text']}", ""]
    return "\n".join(lines) + "\n"


def render_html(p):
    esc = html.escape
    rows = []
    for r in p["results"]:
        a, n = r["engines"]["argos"], r["engines"]["nllb"]
        tag = "synthetic" if r["kind"] == "synthetic" else "public-domain"
        rows.append(f"""
<tr><td class="src"><div class="lbl">{esc(r['label'])} <span class="tag {tag}">{tag}</span></div>{esc(r['de'])}</td>
<td><div class="ms">{a['ms1']}/{a['ms2']} ms</div>{esc(a['text'])}</td>
<td><div class="ms">{n['ms1']}/{n['ms2']} ms</div>{esc(n['text'])}</td>
<td class="verdict"></td></tr>""")
    stat_rows = "".join(
        f"<tr><td>{esc(k)}</td><td>{v['p50']}ms</td><td>{v['p95']}ms</td><td>{v['min']}ms</td><td>{v['max']}ms</td></tr>"
        for k, v in p["stats"].items())
    mem = " · ".join(f"{esc(k)}: {esc(v)}" for k, v in p["mem"].items())
    return f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><title>Engine bake-off — Argos vs NLLB-600M</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');
*{{margin:0;padding:0;box-sizing:border-box}}
body{{font-family:'Inter',system-ui,sans-serif;background:#0d1117;color:#c9d1d9;line-height:1.7;padding:48px 32px 80px}}
.wrap{{max-width:1200px;margin:0 auto}}
h1{{font-size:28px;font-weight:800;color:#e6edf3;margin-bottom:6px}}
.sub{{color:#8b949e;font-size:14px;margin-bottom:32px}}
table{{width:100%;border-collapse:collapse;margin:16px 0;font-size:14px}}
th{{text-align:left;padding:10px 12px;border-bottom:2px solid #30363d;color:#8b949e;font-size:11px;text-transform:uppercase;letter-spacing:0.5px}}
td{{padding:12px;border-bottom:1px solid #21262d;vertical-align:top}}
td.src{{color:#79c0ff;width:30%}}
.lbl{{font-size:11px;color:#8b949e;margin-bottom:6px;text-transform:none}}
.tag{{font-family:'JetBrains Mono',monospace;font-size:10px;padding:1px 7px;border-radius:8px;margin-left:4px}}
.tag.synthetic{{background:rgba(210,153,34,.15);color:#d29922;border:1px solid rgba(210,153,34,.4)}}
.tag.public-domain{{background:rgba(88,166,255,.1);color:#58a6ff;border:1px solid rgba(88,166,255,.3)}}
.ms{{font-family:'JetBrains Mono',monospace;font-size:11px;color:#484f58;margin-bottom:6px}}
.verdict{{width:12%;border-left:2px dashed #30363d}}
.note{{background:rgba(210,153,34,.06);border-left:3px solid #d29922;padding:12px 16px;margin:24px 0;font-size:13px;color:#8b949e;border-radius:0 6px 6px 0}}
pre.mem{{font-family:'JetBrains Mono',monospace;font-size:12px;color:#8b949e}}
</style></head><body><div class="wrap">
<h1>Engine bake-off — Argos vs NLLB-200-600M</h1>
<div class="sub">de→en · 12 spans · 2 measured passes each (after warmup) · generated {esc(p['generated'])}</div>
<table><tr><th>engine</th><th>p50</th><th>p95</th><th>min</th><th>max</th></tr>{stat_rows}</table>
<pre class="mem">RSS: {esc(mem)}</pre>
<div class="note"><strong>Your call.</strong> Right column is for gists / misleads / fails — judge each row.
The ms pairs are <em>first translation</em> / repeat. Argos repeats hit its internal dedup cache (~3ms);
NLLB repeats are full re-inference — in the product, OUR edge cache sits in front, so first-translation
cost is the number that matters. NLLB weights are CC-BY-NC: bench fine, product default never.</div>
<table>
<tr><th>German source</th><th>Argos (LibreTranslate)</th><th>NLLB-600M (ct2 int8)</th><th>verdict</th></tr>
{''.join(rows)}
</table>
</div></body></html>"""


if __name__ == "__main__":
    main()
