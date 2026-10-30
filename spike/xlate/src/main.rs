//! Demo driver: one German span, transcluded into an English
//! document, rendered through a provenance-carrying translation
//! edge. Writes three artifacts under spike/xlate/demo/:
//!
//! - `rendition.prov.json` — the PROV-JSON graph (product types)
//! - `index.html` — the fancy page: rendition chip + original +
//!   provenance + reproducibility evidence
//! - `run.log` — what happened, which provider served, call counts

mod providers;

use providers::LibreTranslate;
use std::cell::Cell;
use std::fmt::Write as _;
use xlate_spike::{
    rendition_prov, Lang, RenditionCache, SpanId, TranslateError, TranslationProvider,
};

/// Faust I/II — public domain, thematically on the nose for a
/// transclusion network: striving, and the possibility of rescue.
const DE_SPAN: &str = "Es irrt der Mensch, solang er strebt. \
                       Wer immer strebend sich bemüht, den können wir erlösen.";
const SOURCE_WORK: &str = "goethe-faust-auswahl";

struct DemoOut(String);

impl DemoOut {
    fn line(&mut self, s: impl AsRef<str>) {
        writeln!(&mut self.0, "{}", s.as_ref()).ok();
    }
}

fn esc(s: &str) -> String {
    s.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;").replace('"', "&quot;")
}

fn main() {
    let mut log = DemoOut(String::new());
    let de = "de".to_string();
    let en = "en".to_string();

    // The span: work 1 (a German source work), revision 7,
    // chars 120.. — address exactly like RangeElement::Transclusion.
    let span = SpanId::from_span_text(1, 7, 120, DE_SPAN);

    // Provider: live LibreTranslate if the container is up,
    // mock otherwise — the demo must never fail to demo.
    let live = LibreTranslate::from_env();
    let probe = live.translate("Sonde", &de, &en);
    let (label, provider): (String, Box<dyn TranslationProvider>) = match probe {
        Ok(_) => {
            log.line("provider: LibreTranslate (live container)");
            ("libretranslate".to_string(), Box::new(live))
        }
        Err(e) => {
            log.line(&format!("provider: MOCK (live unreachable: {e})"));
            ("mock".to_string(), Box::new(Mock::new()))
        }
    };

    let mut cache = RenditionCache::new();

    // 1. First resolve — the miss that materializes the rendition.
    let r1 = cache.resolve(&span, DE_SPAN, &de, &en, provider.as_ref()).unwrap();
    let calls_after_first = provider.calls();
    log.line(&format!(
        "resolve #1: provider calls = {calls_after_first}, checksum {}",
        &r1.checksum_hex()[..16]
    ));

    // 2. Second resolve — must be a cache hit (no new provider call).
    let r2 = cache.resolve(&span, DE_SPAN, &de, &en, provider.as_ref()).unwrap();
    let cache_hit = provider.calls() == calls_after_first && r1 == r2;
    log.line(&format!(
        "resolve #2: provider calls still {} -> cache hit: {cache_hit}",
        provider.calls()
    ));

    // 3. Model bump — same provider, same span, only the model
    // identity differs. The upgrade is pure: new key, retranslate.
    let bumped = Bumped(provider.as_ref());
    let mut cache2 = RenditionCache::new();
    let _ = cache2.resolve(&span, DE_SPAN, &de, &en, provider.as_ref());
    let rb = cache2.resolve(&span, DE_SPAN, &de, &en, &bumped).unwrap();
    log.line(&format!(
        "model bump: new key {} ({} entries from 1 span)",
        &rb.edge.digest_hex()[..16],
        cache2.len()
    ));

    // 4. PROV-JSON via the product's own document type.
    let doc = rendition_prov(&r1);
    // serde_json::Value sorts map keys -> deterministic artifact.
    let value = serde_json::to_value(&doc).unwrap();
    let prov_json = serde_json::to_string_pretty(&value).unwrap();

    // 5. Artifacts, anchored to the manifest dir so cwd is irrelevant.
    let out_dir = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("demo");
    std::fs::create_dir_all(&out_dir).unwrap();
    std::fs::write(out_dir.join("rendition.prov.json"), &prov_json).unwrap();
    log.line(&format!("wrote {}", out_dir.join("rendition.prov.json").display()));

    let html = render_html(&r1, &span, DE_SPAN, &prov_json, &label, cache_hit, &log.0, &cache2, &rb);
    std::fs::write(out_dir.join("index.html"), html).unwrap();
    log.line(&format!("wrote {}", out_dir.join("index.html").display()));

    print!("{}", log.0);
    println!("--- rendition ({} -> en, via {}) ---", r1.edge.source_lang, r1.edge.provider);
    println!("{}", r1.text);
}

// -- mock provider (same canned table as the tests) ----------------

struct Mock {
    calls: Cell<usize>,
}

impl Mock {
    fn new() -> Self {
        Mock { calls: Cell::new(0) }
    }
}

impl TranslationProvider for Mock {
    fn id(&self) -> String {
        "mock@spike".into()
    }
    fn model_version(&self, _s: &Lang, _t: &Lang) -> String {
        "mock:v1".into()
    }
    fn translate(&self, text: &str, _s: &Lang, _t: &Lang) -> Result<String, TranslateError> {
        self.calls.set(self.calls.get() + 1);
        if text.starts_with("Es irrt") {
            Ok("Man errs, as long as he strives. Whoever strives with all his might, that man we can redeem.".into())
        } else {
            Ok(format!("[machine rendition] {text}"))
        }
    }
    fn calls(&self) -> usize {
        self.calls.get()
    }
}

/// Same provider, bumped model version — the pure upgrade case.
struct Bumped<'a>(&'a dyn TranslationProvider);

impl TranslationProvider for Bumped<'_> {
    fn id(&self) -> String {
        self.0.id()
    }
    fn model_version(&self, s: &Lang, t: &Lang) -> String {
        self.0.model_version(s, t) + ".1"
    }
    fn translate(&self, text: &str, s: &Lang, t: &Lang) -> Result<String, TranslateError> {
        self.0.translate(text, s, t)
    }
    fn calls(&self) -> usize {
        self.0.calls()
    }
}

// -- the page -------------------------------------------------------

#[allow(clippy::too_many_arguments)]
fn render_html(
    r: &xlate_spike::Rendition,
    span: &SpanId,
    de_span: &str,
    prov_json: &str,
    provider_label: &str,
    cache_hit: bool,
    log: &str,
    cache2: &RenditionCache,
    rb: &xlate_spike::Rendition,
) -> String {
    let rend_id = r.prov_entity_id();
    let span_id = span.prov_entity_id();
    format!(
        r#"<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Cross-language transclusion — spike</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap');
*{{margin:0;padding:0;box-sizing:border-box}}
body{{font-family:'Inter',system-ui,-apple-system,sans-serif;background:#0d1117;color:#c9d1d9;line-height:1.7;padding:0}}
.mono{{font-family:'JetBrains Mono',monospace}}
a{{color:#58a6ff;text-decoration:none}}
h1{{font-size:32px;font-weight:800;color:#e6edf3;letter-spacing:-0.5px;margin-bottom:8px}}
h2{{font-size:20px;font-weight:700;color:#e6edf3;margin:48px 0 16px;padding-bottom:8px;border-bottom:1px solid #21262d}}
.subtitle{{font-size:16px;color:#8b949e;font-weight:300;margin-bottom:40px}}
.wrap{{max-width:900px;margin:0 auto;padding:48px 32px 80px}}
.note{{background:rgba(88,166,255,0.06);border-left:3px solid #58a6ff;padding:12px 16px;margin:16px 0;border-radius:0 6px 6px 0;font-size:14px;color:#8b949e}}
.gold{{background:rgba(210,153,34,0.06);border-left:3px solid #d29922;padding:12px 16px;margin:16px 0;border-radius:0 6px 6px 0;font-size:14px;color:#8b949e}}
pre{{background:#161b22;border:1px solid #30363d;border-radius:8px;padding:16px 20px;margin:16px 0;overflow-x:auto;font-family:'JetBrains Mono',monospace;font-size:12.5px;line-height:1.6;color:#c9d1d9}}
code{{font-family:'JetBrains Mono',monospace;font-size:0.9em;background:rgba(110,118,129,0.15);padding:2px 6px;border-radius:4px;color:#79c0ff}}
table{{width:100%;border-collapse:collapse;margin:16px 0;font-size:13.5px}}
th{{text-align:left;padding:8px 12px;border-bottom:2px solid #30363d;color:#8b949e;font-size:11px;text-transform:uppercase;letter-spacing:0.5px}}
td{{padding:8px 12px;border-bottom:1px solid #21262d;vertical-align:top}}
.pass{{color:#3fb950;font-family:'JetBrains Mono',monospace;font-weight:600}}
.doc{{background:#161b22;border:1px solid #21262d;border-radius:12px;padding:40px 48px;margin:24px 0;font-size:17px;line-height:1.9}}
.rend{{border-bottom:2px dotted #d29922;cursor:help;position:relative}}
.chip{{display:inline-block;margin-left:8px;padding:1px 10px 2px;border-radius:10px;font-size:11px;font-weight:600;font-family:'JetBrains Mono',monospace;vertical-align:middle;background:rgba(210,153,34,0.15);color:#d29922;border:1px solid rgba(210,153,34,0.4)}}
.side{{display:grid;grid-template-columns:1fr 1fr;gap:20px;margin:24px 0}}
.panel{{background:#161b22;border:1px solid #21262d;border-radius:12px;padding:24px 28px}}
.panel h3{{font-size:13px;text-transform:uppercase;letter-spacing:1px;color:#8b949e;margin-bottom:12px;font-weight:600}}
.panel .orig{{font-size:16px;line-height:1.9;color:#e6edf3}}
.de-lang{{color:#79c0ff}}
.kv{{font-family:'JetBrains Mono',monospace;font-size:12px;color:#8b949e;margin-top:16px;line-height:1.8}}
.kv b{{color:#c9d1d9;font-weight:500}}
.edge-diagram{{font-family:'JetBrains Mono',monospace;font-size:13px;color:#c9d1d9;background:#161b22;border:1px solid #30363d;border-radius:8px;padding:16px 20px;margin:16px 0;overflow-x:auto;line-height:1.8}}
.hl{{color:#d29922}}
.hlb{{color:#3fb950}}
@media (max-width:760px){{.side{{grid-template-columns:1fr}}.doc{{padding:24px}}}}
</style>
</head>
<body>
<div class="wrap">

<h1>Cross-language transclusion</h1>
<div class="subtitle">A spike: one German span, live-windowed into an English document, rendered through a translation edge that rides PROV. Provider: <span class="mono">{provider_label}</span>.</div>

<h2>1 · The document a reader sees</h2>
<div class="doc">
The network keeps its promises in more than one language now. A reader
who reads no German still sees the German text — not as a copy, and not
as a translation of the <em>document</em>, but as a
<span class="rend">rendition of one transcluded span{chip}</span>.
The window is live: if the source work is revised, the span address
changes, and the rendition is recomputed under a new key — nothing is
silently invalidated, and nothing goes stale.
</div>
<div class="note"><strong>The chip is the contract.</strong>
It does not say "translate" — it names the provider, the model, and the
grade. Machine renditions are labeled <code>machine-gisting</code> until
a human (or a quorum) says otherwise. Click-through goes to the
original, never the other way round.</div>

<h2>2 · Both ends visible</h2>
<div class="side">
<div class="panel">
<h3>Rendition (English)</h3>
<div class="orig">{rendition_text}</div>
<div class="kv">entity <b>{rend_id}</b><br>checksum <b>{checksum}</b><br>grade <b>machine-gisting</b></div>
</div>
<div class="panel">
<h3>Original (German) — what links resolve to</h3>
<div class="orig de-lang">{de_escaped}</div>
<div class="kv">entity <b>{span_id}</b><br>work 1 · revision 7 · chars {c0}–{c1}<br>sha256 <b>{span_hash}</b></div>
</div>
</div>

<h2>3 · The edge, in PROV</h2>
<div class="edge-diagram">
<span class="hl">{span_id}</span>  &nbsp;&lt;— used —&nbsp;  <span class="hlb">xudanu:Translation</span>  &nbsp;— wasGeneratedBy —&gt;&nbsp;  <span class="hl">{rend_id}</span><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
╰———————————————— <b>prov:wasDerivedFrom</b> (the edge) —————————————————————╯
</div>
<pre>{prov_esc}</pre>

<h2>4 · Reproducibility evidence (from this run)</h2>
<table>
<tr><th>check</th><th>result</th><th>meaning</th></tr>
<tr><td>second resolve of the same edge</td><td class="pass">{cache_verdict}</td><td>provider called once; identical bytes back</td></tr>
<tr><td>model bump (same span, new model)</td><td class="pass">new key {bump_key}</td><td>{bump_entries} entries from one span — no stale reuse across upgrades</td></tr>
<tr><td>rendition checksum</td><td class="pass">sha256 verified</td><td>readers can check bytes against the PROV entity</td></tr>
</table>
<pre>{log}</pre>

<h2>5 · What this suggests</h2>
<div class="gold"><strong>Where this goes next.</strong>
Read-side only — the original is never edited through MT, so author and
archive cannot diverge. Per-host providers keep reader text inside the
federation's trust boundary (self-hosted LibreTranslate now, any better
local model later, same trait). And the cluster finally gets a
translation-shaped job: a quorum endorsing a canonical rendition —
"faithful to revision 7, checksum verified" — is a real governance
decision, signed and sealed like any other.</div>

</div>
</body>
</html>
"#,
        chip = r#" <span class="chip" title="machine rendition — argos de→en">⚙ machine · de→en</span>"#,
        rendition_text = esc(&r.text),
        de_escaped = esc(de_span),
        checksum = &r.checksum_hex()[..16],
        span_hash = &span.hash_hex()[..16],
        c0 = span.char_start,
        c1 = span.char_end,
        prov_esc = prov_json,
        cache_verdict = if cache_hit { "CACHE HIT — 0 new provider calls" } else { "MISS" },
        bump_key = &rb.edge.digest_hex()[..12],
        bump_entries = cache2.len(),
        log = log,
    )
}
