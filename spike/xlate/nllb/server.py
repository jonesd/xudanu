# NLLB-200-distilled-600M sidecar — LibreTranslate-shaped API.
#
# Speaks the same minimal /translate contract as LibreTranslate
# (q/source/target -> translatedText) so the spike's provider trait
# and bench harness work against both engines unchanged.
# FLORES-200 codes are internal; callers use ISO codes.
#
# License reality (deliberately visible in every response): the
# NLLB weights are CC-BY-NC 4.0. Bench and research use: fine.
# Shipping in a product default: never — operator opt-in only.
import time

import ctranslate2
import sentencepiece as spm
from flask import Flask, jsonify, request

MODEL_DIR = "/models/nllb-600M"
SPM_PATH = "/models/flores200-spm.model"
ENGINE_ID = "nllb-200-distilled-600M-ct2-int8"
BEAM = 4

ISO_TO_FLORES = {
    "en": "eng_Latn", "de": "deu_Latn", "es": "spa_Latn", "fr": "fra_Latn",
    "it": "ita_Latn", "pt": "por_Latn", "nl": "nld_Latn", "ru": "rus_Cyrl",
    "pl": "pol_Latn", "sv": "swe_Latn", "da": "dan_Latn", "fi": "fin_Latn",
    "cs": "ces_Latn", "uk": "ukr_Cyrl", "zh": "zho_Hans", "ja": "jpn_Jpan",
    "ko": "kor_Hang", "ar": "arb_Arab", "hi": "hin_Deva", "tr": "tur_Latn",
}

t0 = time.time()
translator = ctranslate2.Translator(MODEL_DIR, device="cpu", compute_type="int8")
LOAD_SECS = time.time() - t0
sp = spm.SentencePieceProcessor(SPM_PATH)
print(f"model loaded in {LOAD_SECS:.1f}s", flush=True)

app = Flask(__name__)


def translate(text: str, source: str, target: str) -> str:
    src = ISO_TO_FLORES.get(source)
    tgt = ISO_TO_FLORES.get(target)
    if not src or not tgt:
        raise ValueError(f"unsupported pair {source}->{target}")
    tokens = [src] + sp.encode(text, out_type=str) + ["</s>"]
    results = translator.translate_batch(
        [tokens], target_prefix=[[tgt]], beam_size=BEAM, max_decoding_length=512
    )
    out = [t for t in results[0].hypotheses[0] if t not in (tgt, "</s>")]
    return sp.decode(out)


@app.post("/translate")
def translate_route():
    d = request.get_json(force=True)
    t0 = time.time()
    try:
        text = translate(d["q"], d["source"], d["target"])
    except ValueError as e:
        return jsonify(error=str(e)), 400
    ms = round((time.time() - t0) * 1000)
    return jsonify(translatedText=text, engine=ENGINE_ID, ms=ms)


@app.get("/spec")
def spec():
    # Same shape the spike provider probes for a version string.
    return jsonify(openapi="3.0.0", info={"version": "ct2-int8-sidecar"})


@app.get("/health")
def health():
    return jsonify(status="ok", engine=ENGINE_ID, load_secs=round(LOAD_SECS, 1))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, threaded=True)
